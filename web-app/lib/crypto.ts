import * as bip39 from 'bip39';

export interface RSAPublicKey {
  modulus: string;
  exponent: string;
}

export interface EncryptedMessage {
  encryptedContent: string;
  // AES key encrypted for the recipient (they can decrypt the content)
  encryptedAesKeyForRecipient: string;
  // AES key encrypted for the sender (so sender can re-read their own messages)
  encryptedAesKeyForSender: string;
  nonce: string;
  mac: string;
}

class CryptoService {
  private ed25519PrivateKey: CryptoKey | null = null;
  private ed25519PublicKey: CryptoKey | null = null;
  private rsaPrivateKey: CryptoKey | null = null;
  private rsaPublicKey: CryptoKey | null = null;
  private mercurioId: string | null = null;
  private recoveryPhrase: string | null = null;

  async generateIdentity(): Promise<string> {
    console.log('🔐 Starting identity generation...');

    const ed25519KeyPair = await crypto.subtle.generateKey(
      { name: 'Ed25519' },
      true,
      ['sign', 'verify']
    );

    this.ed25519PrivateKey = ed25519KeyPair.privateKey;
    this.ed25519PublicKey = ed25519KeyPair.publicKey;

    const publicKeyBuffer = await crypto.subtle.exportKey('raw', ed25519KeyPair.publicKey);
    const publicKeyHex = this.bufferToHex(new Uint8Array(publicKeyBuffer));
    this.mercurioId = '05' + publicKeyHex;

    console.log('✅ Session ID generated:', this.mercurioId.substring(0, 20) + '...');

    this.recoveryPhrase = bip39.generateMnemonic();
    console.log('✅ Recovery phrase generated (12 words)');

    const rsaKeyPair = await crypto.subtle.generateKey(
      {
        name: 'RSA-OAEP',
        modulusLength: 2048,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: 'SHA-256',
      },
      true,
      ['encrypt', 'decrypt']
    );

    this.rsaPrivateKey = rsaKeyPair.privateKey;
    this.rsaPublicKey = rsaKeyPair.publicKey;
    console.log('✅ RSA keypair generated');

    await this.saveToStorage();

    return this.mercurioId;
  }

  async restoreFromPhrase(phrase: string): Promise<string> {
    if (!bip39.validateMnemonic(phrase)) {
      throw new Error('Invalid recovery phrase');
    }

    // Try to load existing identity for this phrase from storage
    const stored = localStorage.getItem('mercurio_identity');
    if (stored) {
      try {
        const identity = JSON.parse(stored);
        // If the stored phrase matches, just reload it
        if (identity.recoveryPhrase === phrase) {
          await this.loadFromStorage();
          if (this.mercurioId) return this.mercurioId;
        }
      } catch {}
    }

    // Otherwise generate a new identity and store the phrase with it
    // NOTE: True deterministic key derivation from BIP39 requires more crypto primitives
    // than Web Crypto API provides for Ed25519. We generate fresh keys, tie them to phrase.
    this.recoveryPhrase = phrase;

    const ed25519KeyPair = await crypto.subtle.generateKey(
      { name: 'Ed25519' },
      true,
      ['sign', 'verify']
    );

    this.ed25519PrivateKey = ed25519KeyPair.privateKey;
    this.ed25519PublicKey = ed25519KeyPair.publicKey;

    const publicKeyBuffer = await crypto.subtle.exportKey('raw', ed25519KeyPair.publicKey);
    const publicKeyHex = this.bufferToHex(new Uint8Array(publicKeyBuffer));
    this.mercurioId = '05' + publicKeyHex;

    const rsaKeyPair = await crypto.subtle.generateKey(
      {
        name: 'RSA-OAEP',
        modulusLength: 2048,
        publicExponent: new Uint8Array([1, 0, 1]),
        hash: 'SHA-256',
      },
      true,
      ['encrypt', 'decrypt']
    );

    this.rsaPrivateKey = rsaKeyPair.privateKey;
    this.rsaPublicKey = rsaKeyPair.publicKey;

    await this.saveToStorage();

    return this.mercurioId;
  }

  /**
   * Encrypt a message for the recipient AND for the sender (so both can read it).
   */
  async encryptMessage(
    plaintext: string,
    recipientRSAPublicKey: RSAPublicKey
  ): Promise<EncryptedMessage> {
    if (!this.rsaPublicKey) {
      await this.loadFromStorage();
      if (!this.rsaPublicKey) throw new Error('No RSA public key found');
    }

    // Generate a single AES key for the message content
    const aesKey = await crypto.subtle.generateKey(
      { name: 'AES-GCM', length: 256 },
      true,
      ['encrypt', 'decrypt']
    );

    const nonce = crypto.getRandomValues(new Uint8Array(12));

    const encoder = new TextEncoder();
    const encrypted = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: nonce },
      aesKey,
      encoder.encode(plaintext)
    );

    const encryptedArray = new Uint8Array(encrypted);
    const ciphertext = encryptedArray.slice(0, encryptedArray.length - 16);
    const mac = encryptedArray.slice(encryptedArray.length - 16);

    const aesKeyBuffer = await crypto.subtle.exportKey('raw', aesKey);

    // Encrypt AES key for recipient
    const recipientKey = await this.importRSAPublicKey(recipientRSAPublicKey);
    const encryptedAesKeyForRecipient = await crypto.subtle.encrypt(
      { name: 'RSA-OAEP' },
      recipientKey,
      aesKeyBuffer
    );

    // Encrypt AES key for sender (so sender can also read message later)
    const encryptedAesKeyForSender = await crypto.subtle.encrypt(
      { name: 'RSA-OAEP' },
      this.rsaPublicKey,
      aesKeyBuffer
    );

    return {
      encryptedContent: this.bufferToBase64(ciphertext),
      encryptedAesKeyForRecipient: this.bufferToBase64(new Uint8Array(encryptedAesKeyForRecipient)),
      encryptedAesKeyForSender: this.bufferToBase64(new Uint8Array(encryptedAesKeyForSender)),
      nonce: this.bufferToBase64(nonce),
      mac: this.bufferToBase64(mac),
    };
  }

  /**
   * Decrypt a message using the appropriate encrypted AES key.
   * Pass encryptedAesKey - either the recipient's or sender's version.
   */
  async decryptMessage(params: {
    encryptedContent: string;
    encryptedAesKey: string;
    nonce: string;
    mac: string;
  }): Promise<string> {
    if (!this.rsaPrivateKey) {
      await this.loadFromStorage();
      if (!this.rsaPrivateKey) throw new Error('No RSA private key found');
    }

    const encryptedAesKeyBuffer = this.base64ToBuffer(params.encryptedAesKey);
    const aesKeyBuffer = await crypto.subtle.decrypt(
      { name: 'RSA-OAEP' },
      this.rsaPrivateKey,
      encryptedAesKeyBuffer
    );

    const aesKey = await crypto.subtle.importKey(
      'raw',
      aesKeyBuffer,
      { name: 'AES-GCM' },
      false,
      ['decrypt']
    );

    const ciphertext = this.base64ToBuffer(params.encryptedContent);
    const nonce = this.base64ToBuffer(params.nonce);
    const mac = this.base64ToBuffer(params.mac);

    const combined = new Uint8Array(ciphertext.byteLength + mac.byteLength);
    combined.set(new Uint8Array(ciphertext), 0);
    combined.set(new Uint8Array(mac), ciphertext.byteLength);

    const decrypted = await crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: new Uint8Array(nonce) },
      aesKey,
      combined
    );

    const decoder = new TextDecoder();
    return decoder.decode(decrypted);
  }

  async getPublicKeys(): Promise<{ ed25519: string; rsa: RSAPublicKey }> {
    if (!this.ed25519PublicKey || !this.rsaPublicKey) {
      await this.loadFromStorage();
      if (!this.ed25519PublicKey || !this.rsaPublicKey) {
        throw new Error('Keys not found');
      }
    }

    const ed25519Buffer = await crypto.subtle.exportKey('raw', this.ed25519PublicKey);
    const ed25519Base64 = this.bufferToBase64(new Uint8Array(ed25519Buffer));

    const rsaKey = await crypto.subtle.exportKey('jwk', this.rsaPublicKey);
    const rsa: RSAPublicKey = {
      modulus: rsaKey.n!,
      exponent: rsaKey.e!,
    };

    return { ed25519: ed25519Base64, rsa };
  }

  async hasIdentity(): Promise<boolean> {
    if (this.mercurioId) return true;
    await this.loadFromStorage();
    return this.mercurioId !== null;
  }

  getMercurioId(): string | null {
    return this.mercurioId;
  }

  getRecoveryPhrase(): string | null {
    return this.recoveryPhrase;
  }

  async ensureLoaded(): Promise<void> {
    if (!this.mercurioId) {
      await this.loadFromStorage();
    }
  }

  async clearAllKeys(): Promise<void> {
    this.ed25519PrivateKey = null;
    this.ed25519PublicKey = null;
    this.rsaPrivateKey = null;
    this.rsaPublicKey = null;
    this.mercurioId = null;
    this.recoveryPhrase = null;

    localStorage.removeItem('mercurio_identity');
  }

  private async saveToStorage(): Promise<void> {
    if (!this.ed25519PrivateKey || !this.ed25519PublicKey || !this.rsaPrivateKey || !this.rsaPublicKey) {
      throw new Error('Cannot save: keys not initialized');
    }

    const ed25519Private = await crypto.subtle.exportKey('pkcs8', this.ed25519PrivateKey);
    const ed25519Public = await crypto.subtle.exportKey('raw', this.ed25519PublicKey);
    const rsaPrivate = await crypto.subtle.exportKey('pkcs8', this.rsaPrivateKey);
    const rsaPublic = await crypto.subtle.exportKey('jwk', this.rsaPublicKey);

    const identity = {
      mercurioId: this.mercurioId,
      recoveryPhrase: this.recoveryPhrase,
      ed25519Private: this.bufferToBase64(new Uint8Array(ed25519Private)),
      ed25519Public: this.bufferToBase64(new Uint8Array(ed25519Public)),
      rsaPrivate: this.bufferToBase64(new Uint8Array(rsaPrivate)),
      rsaPublic: rsaPublic,
    };

    localStorage.setItem('mercurio_identity', JSON.stringify(identity));
  }

  async loadFromStorage(): Promise<void> {
    const stored = localStorage.getItem('mercurio_identity');
    if (!stored) return;

    try {
      const identity = JSON.parse(stored);
      this.mercurioId = identity.mercurioId;
      this.recoveryPhrase = identity.recoveryPhrase;

      const ed25519PrivateBuffer = this.base64ToBuffer(identity.ed25519Private);
      this.ed25519PrivateKey = await crypto.subtle.importKey(
        'pkcs8',
        ed25519PrivateBuffer,
        { name: 'Ed25519' },
        true,
        ['sign']
      );

      const ed25519PublicBuffer = this.base64ToBuffer(identity.ed25519Public);
      this.ed25519PublicKey = await crypto.subtle.importKey(
        'raw',
        ed25519PublicBuffer,
        { name: 'Ed25519' },
        true,
        ['verify']
      );

      const rsaPrivateBuffer = this.base64ToBuffer(identity.rsaPrivate);
      this.rsaPrivateKey = await crypto.subtle.importKey(
        'pkcs8',
        rsaPrivateBuffer,
        { name: 'RSA-OAEP', hash: 'SHA-256' },
        true,
        ['decrypt']
      );

      this.rsaPublicKey = await crypto.subtle.importKey(
        'jwk',
        identity.rsaPublic,
        { name: 'RSA-OAEP', hash: 'SHA-256' },
        true,
        ['encrypt']
      );
    } catch (error) {
      console.error('Failed to load identity:', error);
      await this.clearAllKeys();
    }
  }

  private async importRSAPublicKey(publicKey: RSAPublicKey): Promise<CryptoKey> {
    const jwk = {
      kty: 'RSA',
      n: publicKey.modulus,
      e: publicKey.exponent,
      alg: 'RSA-OAEP-256',
      ext: true,
    };

    return await crypto.subtle.importKey(
      'jwk',
      jwk,
      { name: 'RSA-OAEP', hash: 'SHA-256' },
      false,
      ['encrypt']
    );
  }

  private bufferToHex(buffer: Uint8Array): string {
    return Array.from(buffer)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }

  bufferToBase64(buffer: Uint8Array): string {
    return btoa(String.fromCharCode.apply(null, Array.from(buffer)));
  }

  base64ToBuffer(base64: string): ArrayBuffer {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }
}

export const cryptoService = new CryptoService();
