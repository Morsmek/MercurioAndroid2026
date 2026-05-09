import { router, useLocalSearchParams } from "expo-router";
import { useMemo, useState } from "react";
import { FlatList, KeyboardAvoidingView, Platform, Text, TextInput, TouchableOpacity, View } from "react-native";

import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { initials, useMercurio, type Message } from "@/lib/mercurio-store";

export default function ChatDetailScreen() {
  const { contactId } = useLocalSearchParams<{ contactId: string }>();
  const { getContact, getMessagesForContact, sendMessage } = useMercurio();
  const [draft, setDraft] = useState("");
  const contact = contactId ? getContact(contactId) : undefined;
  const chatMessages = useMemo(() => (contactId ? getMessagesForContact(contactId) : []), [contactId, getMessagesForContact]);

  if (!contact || !contactId) {
    return (
      <ScreenContainer className="items-center justify-center px-6">
        <Text className="text-center text-lg font-semibold text-foreground">Contact not found</Text>
        <TouchableOpacity onPress={() => router.back()} className="mt-4 rounded-2xl bg-primary px-5 py-3">
          <Text className="font-semibold text-white">Go Back</Text>
        </TouchableOpacity>
      </ScreenContainer>
    );
  }

  const handleSend = async () => {
    if (!draft.trim()) return;
    await sendMessage(contactId, draft);
    setDraft("");
  };

  const renderMessage = ({ item }: { item: Message }) => {
    const mine = item.sender === "me";
    return (
      <View className={`max-w-[82%] rounded-[24px] px-4 py-3 ${mine ? "self-end bg-primary" : "self-start bg-surface border border-border"}`}>
        <Text className={`text-base leading-6 ${mine ? "text-white" : "text-foreground"}`}>{item.body}</Text>
        <Text className={`mt-1 text-xs ${mine ? "text-cyan-100" : "text-muted"}`}>{mine ? item.status : "encrypted"}</Text>
      </View>
    );
  };

  return (
    <ScreenContainer className="px-4 pt-1" edges={["top", "left", "right", "bottom"]}>
      <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} className="flex-1">
        <View className="flex-row items-center gap-3 border-b border-border pb-3">
          <TouchableOpacity onPress={() => router.back()} className="h-10 w-10 items-center justify-center rounded-full bg-surface">
            <IconSymbol name="chevron.right" size={24} color="#243B8F" style={{ transform: [{ rotate: "180deg" }] }} />
          </TouchableOpacity>
          <View className="h-11 w-11 items-center justify-center rounded-full bg-primary">
            <Text className="font-bold text-white">{initials(contact.displayName)}</Text>
          </View>
          <View className="flex-1">
            <Text className="text-lg font-bold text-foreground">{contact.displayName}</Text>
            <Text className="text-xs text-muted">{contact.verified ? "Safety number verified" : "Safety number pending"}</Text>
          </View>
        </View>
        <FlatList
          data={chatMessages}
          keyExtractor={(item) => item.id}
          renderItem={renderMessage}
          ItemSeparatorComponent={() => <View className="h-3" />}
          contentContainerStyle={{ paddingVertical: 16 }}
        />
        <View className="flex-row items-end gap-2 border-t border-border pt-3">
          <TextInput
            value={draft}
            onChangeText={setDraft}
            multiline
            placeholder="Message"
            placeholderTextColor="#8A94A6"
            className="max-h-28 flex-1 rounded-3xl border border-border bg-surface px-4 py-3 text-base text-foreground"
          />
          <TouchableOpacity onPress={handleSend} className="h-12 w-12 items-center justify-center rounded-full bg-primary active:opacity-80">
            <IconSymbol name="paperplane.fill" size={22} color="#FFFFFF" />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </ScreenContainer>
  );
}
