# Mercurio Messenger Mobile Design Plan

Mercurio Messenger Mobile is designed as a portrait-first, one-handed private messaging experience inspired by the MercurioAndroid2026 repository. The interface should feel like a mainstream first-party iOS app: calm, clear, tactile, and direct. The app will prioritize local-first identity creation, contact management, simulated encrypted chats, QR-style identity sharing, and transparent privacy settings without adding cloud account requirements unless the user later requests them.

## Screen List

| Screen | Primary Content And Functionality | Layout Notes |
|---|---|---|
| Onboarding | Brand mark, privacy promise, create identity action, recovery phrase preview, continue action. | Full-height vertical flow with the main call to action in thumb reach near the bottom. |
| Home | Identity status card, recent chats, security summary, quick actions for adding contacts and opening settings. | Large title, stacked cards, one-handed controls, and compact recent conversation rows. |
| Contacts | Search field, saved contacts, add contact form, Mercurio ID validation, empty state. | Native iOS grouped list style with rounded cards and clear primary action. |
| Chat Detail | Contact header, message timeline, encrypted-state notice, composer, send action. | Conversation interface with bottom composer above safe area and readable message bubbles. |
| Share ID | Mercurio ID, QR-style visual card, copy/share actions, recovery reminder. | Centered identity card with clear buttons and non-sensitive privacy copy. |
| Settings | Profile label, local identity information, security controls, recovery phrase viewer, reset demo data. | Grouped settings sections similar to iOS Settings, using destructive styling only for reset. |

## Primary Content And Functionality

The onboarding screen introduces Mercurio as a private messenger and creates a local identity represented by a Mercurio ID and recovery phrase. The home screen summarizes that identity, displays recent conversations, and provides quick access to common actions. Contacts are saved locally so the app works immediately in the preview without requiring a backend. Chat detail screens provide a functional message composer and deterministic demo messaging to show the intended private messaging flow. The share screen presents a QR-inspired identity card and copy/share actions. Settings provides local privacy controls and the ability to inspect or reset locally stored data.

## Key User Flows

| Flow | Steps | Expected Outcome |
|---|---|---|
| Create Identity | User opens app → taps Create Private Identity → reviews recovery phrase → enters Home. | The user has a local Mercurio ID and can begin using the app. |
| Add Contact | User opens Contacts → enters display name and Mercurio ID → taps Add Contact. | Contact appears in the contacts list and can be opened for chat. |
| Send Message | User opens a contact → types a message → taps Send. | Message appears in the timeline with encrypted-flow visual feedback. |
| Share Identity | User opens Share ID → copies or shares Mercurio ID. | User can provide their ID to another person through system sharing. |
| Manage Privacy | User opens Settings → views security state or recovery phrase → optionally resets local data. | User understands what is stored locally and can clear demo data. |

## Color Choices

The brand uses a deep privacy-focused indigo and a mercury-like cyan accent. The primary interface color is **#243B8F** for trust and depth. The secondary accent is **#22D3EE** for secure communication highlights. The light background is **#F7F9FC**, while elevated cards use **#FFFFFF**. Important success states use **#16A34A**, warnings use **#F59E0B**, and destructive actions use **#DC2626**. Dark mode will use **#07111F** for the app background and **#111C2E** for card surfaces.

## Interaction Principles

Every primary action should provide immediate feedback through press opacity or light haptics where available. Forms should validate inline with readable error messages rather than blocking the user silently. Navigation should remain shallow and predictable using bottom tabs for Home, Contacts, Share ID, and Settings, while chat detail can be opened as a dedicated route from contact and recent-chat rows. The visual density should be moderate so that the app remains comfortable on a 9:16 phone display.
