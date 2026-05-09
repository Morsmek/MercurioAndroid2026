import AsyncStorage from "@react-native-async-storage/async-storage";
import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";

export type Identity = {
  displayName: string;
  mercurioId: string;
  recoveryPhrase: string[];
  createdAt: string;
};

export type Contact = {
  id: string;
  displayName: string;
  mercurioId: string;
  verified: boolean;
  notes?: string;
  createdAt: string;
};

export type Message = {
  id: string;
  contactId: string;
  body: string;
  sender: "me" | "contact";
  createdAt: string;
  status: "sent" | "delivered" | "read";
};

type PersistedState = {
  identity: Identity | null;
  contacts: Contact[];
  messages: Message[];
};

type MercurioContextValue = PersistedState & {
  hydrated: boolean;
  createIdentity: () => Promise<Identity>;
  addContact: (displayName: string, mercurioId: string) => Promise<Contact>;
  sendMessage: (contactId: string, body: string) => Promise<Message>;
  resetLocalData: () => Promise<void>;
  getMessagesForContact: (contactId: string) => Message[];
  getContact: (contactId: string) => Contact | undefined;
};

const STORAGE_KEY = "mercurio.mobile.state.v1";

const RECOVERY_WORDS = [
  "amber", "signal", "orbit", "cipher", "velvet", "harbor", "mercury", "anchor",
  "lunar", "token", "silent", "matrix", "silver", "pulse", "atlas", "nova",
  "summit", "raven", "cobalt", "shield", "ember", "prairie", "zenith", "river",
];

const demoContacts: Contact[] = [
  {
    id: "contact-alice",
    displayName: "Alice Rivera",
    mercurioId: "MER-ALICE-7K2P-Q9X4",
    verified: true,
    notes: "Cross-platform test contact from the original Mercurio flow.",
    createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
  },
  {
    id: "contact-bob",
    displayName: "Bob Chen",
    mercurioId: "MER-BOB-4N8V-C2M1",
    verified: false,
    notes: "Pending safety number confirmation.",
    createdAt: new Date(Date.now() - 86400000).toISOString(),
  },
];

const demoMessages: Message[] = [
  {
    id: "msg-1",
    contactId: "contact-alice",
    body: "I added your Mercurio ID. Messages are shown locally in this preview.",
    sender: "contact",
    createdAt: new Date(Date.now() - 1000 * 60 * 45).toISOString(),
    status: "read",
  },
  {
    id: "msg-2",
    contactId: "contact-alice",
    body: "Great. I can see the encrypted-chat flow on mobile now.",
    sender: "me",
    createdAt: new Date(Date.now() - 1000 * 60 * 39).toISOString(),
    status: "read",
  },
  {
    id: "msg-3",
    contactId: "contact-bob",
    body: "Share your QR card when you are ready.",
    sender: "contact",
    createdAt: new Date(Date.now() - 1000 * 60 * 12).toISOString(),
    status: "delivered",
  },
];

const MercurioContext = createContext<MercurioContextValue | null>(null);

function randomSegment(length: number) {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  return Array.from({ length }, () => alphabet[Math.floor(Math.random() * alphabet.length)]).join("");
}

function buildRecoveryPhrase() {
  const words = [...RECOVERY_WORDS].sort(() => Math.random() - 0.5);
  return words.slice(0, 12);
}

function normalizeMercurioId(value: string) {
  return value.trim().toUpperCase().replace(/\s+/g, "-");
}

async function persist(state: PersistedState) {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

export function MercurioProvider({ children }: { children: ReactNode }) {
  const [identity, setIdentity] = useState<Identity | null>(null);
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    let mounted = true;
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (!mounted) return;
        if (raw) {
          const parsed = JSON.parse(raw) as PersistedState;
          setIdentity(parsed.identity ?? null);
          setContacts(parsed.contacts ?? []);
          setMessages(parsed.messages ?? []);
        } else {
          setContacts(demoContacts);
          setMessages(demoMessages);
        }
      })
      .catch(() => {
        if (!mounted) return;
        setContacts(demoContacts);
        setMessages(demoMessages);
      })
      .finally(() => mounted && setHydrated(true));
    return () => {
      mounted = false;
    };
  }, []);

  const saveState = useCallback(
    async (next: Partial<PersistedState>) => {
      const updated = {
        identity: next.identity !== undefined ? next.identity : identity,
        contacts: next.contacts ?? contacts,
        messages: next.messages ?? messages,
      };
      await persist(updated);
    },
    [contacts, identity, messages],
  );

  const createIdentity = useCallback(
    async () => {
      const shortLabel = randomSegment(4);
      const nextIdentity: Identity = {
        displayName: `Mercurio Identity ${shortLabel}`,
        mercurioId: `MER-${shortLabel}-${randomSegment(4)}-${randomSegment(4)}`,
        recoveryPhrase: buildRecoveryPhrase(),
        createdAt: new Date().toISOString(),
      };
      setIdentity(nextIdentity);
      await saveState({ identity: nextIdentity });
      return nextIdentity;
    },
    [saveState],
  );

  const addContact = useCallback(
    async (displayName: string, mercurioId: string) => {
      const cleanName = displayName.trim();
      const cleanId = normalizeMercurioId(mercurioId);
      if (!cleanName) throw new Error("Enter a contact name.");
      if (!cleanId.startsWith("MER-") || cleanId.length < 12) throw new Error("Enter a valid Mercurio ID beginning with MER-.");
      const nextContact: Contact = {
        id: `contact-${Date.now()}`,
        displayName: cleanName,
        mercurioId: cleanId,
        verified: false,
        createdAt: new Date().toISOString(),
      };
      const nextContacts = [nextContact, ...contacts];
      const greeting: Message = {
        id: `msg-${Date.now()}`,
        contactId: nextContact.id,
        body: `${cleanName} was added. Send a first message to start the secure conversation.`,
        sender: "contact",
        createdAt: new Date().toISOString(),
        status: "delivered",
      };
      const nextMessages = [greeting, ...messages];
      setContacts(nextContacts);
      setMessages(nextMessages);
      await saveState({ contacts: nextContacts, messages: nextMessages });
      return nextContact;
    },
    [contacts, messages, saveState],
  );

  const sendMessage = useCallback(
    async (contactId: string, body: string) => {
      const cleanBody = body.trim();
      if (!cleanBody) throw new Error("Write a message before sending.");
      const nextMessage: Message = {
        id: `msg-${Date.now()}`,
        contactId,
        body: cleanBody,
        sender: "me",
        createdAt: new Date().toISOString(),
        status: "sent",
      };
      const autoReply: Message = {
        id: `msg-${Date.now() + 1}`,
        contactId,
        body: "Encrypted preview received. Cross-device delivery can be connected to the original backend later.",
        sender: "contact",
        createdAt: new Date(Date.now() + 1000).toISOString(),
        status: "delivered",
      };
      const nextMessages = [...messages, nextMessage, autoReply];
      setMessages(nextMessages);
      await saveState({ messages: nextMessages });
      return nextMessage;
    },
    [messages, saveState],
  );

  const resetLocalData = useCallback(async () => {
    setIdentity(null);
    setContacts(demoContacts);
    setMessages(demoMessages);
    await AsyncStorage.removeItem(STORAGE_KEY);
  }, []);

  const getMessagesForContact = useCallback(
    (contactId: string) => messages.filter((message) => message.contactId === contactId).sort((a, b) => a.createdAt.localeCompare(b.createdAt)),
    [messages],
  );

  const getContact = useCallback((contactId: string) => contacts.find((contact) => contact.id === contactId), [contacts]);

  const value = useMemo(
    () => ({
      identity,
      contacts,
      messages,
      hydrated,
      createIdentity,
      addContact,
      sendMessage,
      resetLocalData,
      getMessagesForContact,
      getContact,
    }),
    [addContact, contacts, createIdentity, getContact, getMessagesForContact, hydrated, identity, messages, resetLocalData, sendMessage],
  );

  return <MercurioContext.Provider value={value}>{children}</MercurioContext.Provider>;
}

export function useMercurio() {
  const context = useContext(MercurioContext);
  if (!context) throw new Error("useMercurio must be used within MercurioProvider");
  return context;
}

export function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("") || "M";
}

export function formatRelativeTime(value?: string) {
  if (!value) return "Now";
  const diff = Date.now() - new Date(value).getTime();
  const minutes = Math.max(1, Math.round(diff / 60000));
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h`;
  return `${Math.round(hours / 24)}d`;
}
