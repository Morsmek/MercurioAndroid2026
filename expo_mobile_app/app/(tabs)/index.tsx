import { router } from "expo-router";
import { ActivityIndicator, FlatList, Text, TouchableOpacity, View } from "react-native";

import { OnboardingCard } from "@/components/mercurio/onboarding-card";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { formatRelativeTime, initials, useMercurio, type Contact, type Message } from "@/lib/mercurio-store";

export default function HomeScreen() {
  const { hydrated, identity, contacts, messages } = useMercurio();

  if (!hydrated) {
    return (
      <ScreenContainer className="items-center justify-center">
        <ActivityIndicator />
      </ScreenContainer>
    );
  }

  if (!identity) {
    return (
      <ScreenContainer className="px-6">
        <OnboardingCard />
      </ScreenContainer>
    );
  }

  const recentContacts = contacts
    .map((contact) => ({
      contact,
      lastMessage: messages.filter((message) => message.contactId === contact.id).sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0],
    }))
    .sort((a, b) => (b.lastMessage?.createdAt ?? b.contact.createdAt).localeCompare(a.lastMessage?.createdAt ?? a.contact.createdAt));

  const renderConversation = ({ item }: { item: { contact: Contact; lastMessage?: Message } }) => (
    <TouchableOpacity onPress={() => router.push({ pathname: "/chat/[contactId]" as never, params: { contactId: item.contact.id } })} className="flex-row items-center gap-3 rounded-3xl border border-border bg-surface p-4 active:opacity-75">
      <View className="h-12 w-12 items-center justify-center rounded-full bg-primary">
        <Text className="font-bold text-white">{initials(item.contact.displayName)}</Text>
      </View>
      <View className="flex-1 gap-1">
        <View className="flex-row items-center gap-2">
          <Text className="text-base font-semibold text-foreground">{item.contact.displayName}</Text>
          {item.contact.verified ? <IconSymbol name="checkmark.seal.fill" size={16} color="#16A34A" /> : null}
        </View>
        <Text numberOfLines={1} className="text-sm text-muted">{item.lastMessage?.body ?? "No messages yet"}</Text>
      </View>
      <Text className="text-xs text-muted">{formatRelativeTime(item.lastMessage?.createdAt)}</Text>
    </TouchableOpacity>
  );

  return (
    <ScreenContainer className="px-5 pt-2">
      <FlatList
        data={recentContacts}
        keyExtractor={(item) => item.contact.id}
        renderItem={renderConversation}
        ItemSeparatorComponent={() => <View className="h-3" />}
        ListHeaderComponent={
          <View className="gap-5 pb-5">
            <View className="gap-1">
              <Text className="text-3xl font-bold text-foreground">Mercurio</Text>
              <Text className="text-base text-muted">Private messenger preview from MercurioAndroid2026</Text>
            </View>
            <View className="rounded-[30px] bg-primary p-5 gap-4">
              <View className="flex-row items-start justify-between gap-4">
                <View className="flex-1 gap-2">
                  <Text className="text-sm font-semibold uppercase tracking-widest text-cyan-100">Your local identity</Text>
                  <Text className="text-2xl font-bold text-white">{identity.displayName}</Text>
                  <Text className="text-sm text-cyan-100">{identity.mercurioId}</Text>
                </View>
                <View className="h-12 w-12 items-center justify-center rounded-2xl bg-white/20">
                  <IconSymbol name="shield.fill" size={26} color="#FFFFFF" />
                </View>
              </View>
              <View className="flex-row gap-3">
                <TouchableOpacity onPress={() => router.push({ pathname: "/(tabs)/share" as never })} className="flex-1 rounded-2xl bg-white px-4 py-3 active:opacity-80">
                  <Text className="text-center font-semibold text-primary">Share ID</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={() => router.push({ pathname: "/(tabs)/contacts" as never })} className="flex-1 rounded-2xl bg-white/15 px-4 py-3 active:opacity-80">
                  <Text className="text-center font-semibold text-white">Add Contact</Text>
                </TouchableOpacity>
              </View>
            </View>
            <View className="flex-row gap-3">
              <View className="flex-1 rounded-3xl border border-border bg-surface p-4">
                <Text className="text-2xl font-bold text-foreground">{contacts.length}</Text>
                <Text className="text-sm text-muted">Contacts</Text>
              </View>
              <View className="flex-1 rounded-3xl border border-border bg-surface p-4">
                <Text className="text-2xl font-bold text-foreground">{messages.length}</Text>
                <Text className="text-sm text-muted">Local messages</Text>
              </View>
            </View>
            <Text className="text-xl font-bold text-foreground">Recent chats</Text>
          </View>
        }
        ListEmptyComponent={
          <View className="rounded-3xl border border-border bg-surface p-6">
            <Text className="text-center text-base font-semibold text-foreground">No conversations yet</Text>
            <Text className="mt-2 text-center text-sm text-muted">Add a contact to start a local secure-chat preview.</Text>
          </View>
        }
        contentContainerStyle={{ paddingBottom: 120 }}
      />
    </ScreenContainer>
  );
}
