// Minimal signalling server with TURN credential issuance
// Node 16+
// Install: npm i ws express crypto

const fs = require('fs');
const http = require('http');
const crypto = require('crypto');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8443;
const STATIC_AUTH_SECRET = process.env.STATIC_AUTH_SECRET || 'replace_with_strong_secret';
const TURN_REALM = process.env.TURN_REALM || 'example.com';
const TURN_URLS = process.env.TURN_URLS || 'turn:turn.example.com:3478'; // comma separated

// In-memory map: pubkey -> ws
const peers = new Map();

function generateTurnCredentials(sharedSecret, ttlSeconds = 600) {
  const expiry = Math.floor(Date.now() / 1000) + ttlSeconds;
  const username = `${expiry}:${crypto.randomBytes(6).toString('hex')}`;
  const hmac = crypto.createHmac('sha1', sharedSecret).update(username).digest('base64');
  return { username, credential: hmac, ttl: ttlSeconds, urls: TURN_URLS.split(',') };
}

const server = http.createServer((req, res) => {
  res.writeHead(200);
  res.end('Signalling server\n');
});

const wss = new WebSocket.Server({ server });

wss.on('connection', (ws, req) => {
  ws.isAlive = true;
  ws.on('pong', () => ws.isAlive = true);

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch (e) { return; }

    // Register: { type: 'register', pubkey: '<hex-or-base64>' }
    if (msg.type === 'register' && msg.pubkey) {
      peers.set(msg.pubkey, ws);
      ws.pubkey = msg.pubkey;
      return;
    }

    // Request TURN creds: { type: 'get_turn_credentials' }
    if (msg.type === 'get_turn_credentials') {
      if (!ws.pubkey) {
        ws.send(JSON.stringify({ type: 'error', reason: 'not_registered' }));
        return;
      }
      const creds = generateTurnCredentials(STATIC_AUTH_SECRET, 600);
      ws.send(JSON.stringify({ type: 'turn_credentials', realm: TURN_REALM, urls: creds.urls, username: creds.username, credential: creds.credential, ttl: creds.ttl }));
      return;
    }

    // Forwarding messages: offer/answer/ice
    // Expected shape: { type: 'offer'|'answer'|'ice', from: '<pubkey>', to: '<pubkey>', sdp?, candidate? }
    if (msg.type === 'offer' || msg.type === 'answer' || msg.type === 'ice') {
      const dest = peers.get(msg.to);
      if (dest && dest.readyState === WebSocket.OPEN) {
        dest.send(JSON.stringify(msg));
      } else {
        ws.send(JSON.stringify({ type: 'peer_offline', to: msg.to }));
      }
      return;
    }

    // Other message types can be added as needed
  });

  ws.on('close', () => {
    if (ws.pubkey) peers.delete(ws.pubkey);
  });
});

// Simple ping to detect dead connections
setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

server.listen(PORT, () => console.log(`Signalling server listening on ${PORT}`));
