import { router } from "expo-router";
import { useMemo, useState } from "react";
import { Alert, FlatList, Text, TextInput, TouchableOpacity, View } from "react-native";

import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { initials, useMercurio, type Contact } from "@/lib/mercurio-store";

export default function ContactsScreen() {
  const { contacts, addContact, identity } = useMercurio();
  const [query, setQuery] = useState("");
  const [name, setName] = useState("");
  const [mercurioId, setMercurioId] = useState("");
  const [error, setError] = useState("");

  const filtered = useMemo(
    () => contacts.filter((contact) => `${contact.displayName} ${contact.mercurioId}`.toLowerCase().includes(query.toLowerCase())),
    [contacts, query],
  );

  const handleAdd = async () => {
    try {
      setError("");
      const contact = await addContact(name, mercurioId);
      setName("");
      setMercurioId("");
      router.push({ pathname: "/chat/[contactId]" as never, params: { contactId: contact.id } });
    } catch (err) {
      const message = err instanceof Error ? err.message : "Could not add contact.";
      setError(message);
      Alert.alert("Check contact details", message);
    }
  };

  const renderContact = ({ item }: { item: Contact }) => (
    <TouchableOpacity onPress={() => router.push({ pathname: "/chat/[contactId]" as never, params: { contactId: item.id } })} className="flex-row items-center gap-3 rounded-3xl border border-border bg-surface p-4 active:opacity-75">
      <View className="h-12 w-12 items-center justify-center rounded-full bg-primary">
        <Text className="font-bold text-white">{initials(item.displayName)}</Text>
      </View>
      <View className="flex-1 gap-1">
        <Text className="text-base font-semibold text-foreground">{item.displayName}</Text>
        <Text numberOfLines={1} className="text-sm text-muted">{item.mercurioId}</Text>
      </View>
      <IconSymbol name="chevron.right" size={22} color="#8A94A6" />
    </TouchableOpacity>
  );

  return (
    <ScreenContainer className="px-5 pt-2">
      <FlatList
        data={filtered}
        keyExtractor={(item) => item.id}
        renderItem={renderContact}
        ItemSeparatorComponent={() => <View className="h-3" />}
        ListHeaderComponent={
          <View className="gap-5 pb-5">
            <View className="gap-1">
              <Text className="text-3xl font-bold text-foreground">Contacts</Text>
              <Text className="text-base text-muted">Add people with their Mercurio ID.</Text>
            </View>
            {!identity ? (
              <View className="rounded-3xl border border-warning bg-surface p-4">
                <Text className="font-semibold text-foreground">Create an identity first</Text>
                <Text className="mt-1 text-sm text-muted">Go to Home to create your local Mercurio ID before chatting.</Text>
              </View>
            ) : null}
            <View className="flex-row items-center gap-2 rounded-2xl border border-border bg-surface px-4 py-3">
              <IconSymbol name="magnifyingglass" size={20} color="#8A94A6" />
              <TextInput value={query} onChangeText={setQuery} placeholder="Search contacts" placeholderTextColor="#8A94A6" className="flex-1 text-base text-foreground" returnKeyType="search" />
            </View>
            <View className="rounded-[28px] border border-border bg-surface p-5 gap-3">
              <View className="flex-row items-center gap-2">
                <IconSymbol name="person.crop.circle.fill.badge.plus" size={22} color="#243B8F" />
                <Text className="text-xl font-semibold text-foreground">Add contact</Text>
              </View>
              <TextInput value={name} onChangeText={setName} placeholder="Display name" placeholderTextColor="#8A94A6" className="rounded-2xl border border-border bg-background px-4 py-3 text-base text-foreground" returnKeyType="next" />
              <TextInput value={mercurioId} onChangeText={setMercurioId} autoCapitalize="characters" placeholder="MER-ABCD-1234-WXYZ" placeholderTextColor="#8A94A6" className="rounded-2xl border border-border bg-background px-4 py-3 text-base text-foreground" returnKeyType="done" />
              {error ? <Text className="text-sm text-error">{error}</Text> : null}
              <TouchableOpacity onPress={handleAdd} disabled={!identity} className="items-center rounded-2xl bg-primary px-5 py-4 active:opacity-80 disabled:opacity-40">
                <Text className="font-semibold text-white">Add Contact</Text>
              </TouchableOpacity>
            </View>
            <Text className="text-xl font-bold text-foreground">Saved contacts</Text>
          </View>
        }
        ListEmptyComponent={
          <View className="rounded-3xl border border-border bg-surface p-6">
            <Text className="text-center text-base font-semibold text-foreground">No contacts found</Text>
            <Text className="mt-2 text-center text-sm text-muted">Add a Mercurio ID to begin.</Text>
          </View>
        }
        contentContainerStyle={{ paddingBottom: 120 }}
      />
    </ScreenContainer>
  );
}
