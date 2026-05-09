import * as Clipboard from "expo-clipboard";
import { useState } from "react";
import { Alert, Text, TouchableOpacity, View } from "react-native";

import { OnboardingCard } from "@/components/mercurio/onboarding-card";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useMercurio } from "@/lib/mercurio-store";

export default function SettingsScreen() {
  const { identity, contacts, messages, resetLocalData } = useMercurio();
  const [showPhrase, setShowPhrase] = useState(false);

  if (!identity) {
    return (
      <ScreenContainer className="px-6">
        <OnboardingCard />
      </ScreenContainer>
    );
  }

  const copyPhrase = async () => {
    await Clipboard.setStringAsync(identity.recoveryPhrase.join(" "));
    Alert.alert("Copied", "Recovery phrase copied to clipboard.");
  };

  const confirmReset = () => {
    Alert.alert("Reset local data", "This clears the local preview identity and restores demo contacts.", [
      { text: "Cancel", style: "cancel" },
      { text: "Reset", style: "destructive", onPress: resetLocalData },
    ]);
  };

  return (
    <ScreenContainer className="px-5 pt-2">
      <View className="gap-5">
        <View className="gap-1">
          <Text className="text-3xl font-bold text-foreground">Settings</Text>
          <Text className="text-base text-muted">Local identity and privacy controls.</Text>
        </View>
        <View className="rounded-[28px] border border-border bg-surface p-5 gap-3">
          <Text className="text-xl font-semibold text-foreground">{identity.displayName}</Text>
          <Text selectable className="text-sm text-muted">{identity.mercurioId}</Text>
          <View className="mt-2 flex-row gap-3">
            <View className="flex-1 rounded-2xl bg-background p-3">
              <Text className="text-xl font-bold text-foreground">{contacts.length}</Text>
              <Text className="text-xs text-muted">Contacts</Text>
            </View>
            <View className="flex-1 rounded-2xl bg-background p-3">
              <Text className="text-xl font-bold text-foreground">{messages.length}</Text>
              <Text className="text-xs text-muted">Messages</Text>
            </View>
          </View>
        </View>
        <View className="rounded-[28px] border border-border bg-surface p-5 gap-4">
          <View className="flex-row items-center gap-2">
            <IconSymbol name="key.fill" size={22} color="#F59E0B" />
            <Text className="text-xl font-semibold text-foreground">Recovery phrase</Text>
          </View>
          <Text className="text-sm leading-5 text-muted">
            Keep these words private. In the original app flow, this phrase is used to restore access to your Mercurio identity.
          </Text>
          {showPhrase ? (
            <View className="flex-row flex-wrap gap-2">
              {identity.recoveryPhrase.map((word, index) => (
                <View key={`${word}-${index}`} className="rounded-xl bg-background px-3 py-2">
                  <Text className="text-sm font-semibold text-foreground">{index + 1}. {word}</Text>
                </View>
              ))}
            </View>
          ) : null}
          <View className="flex-row gap-3">
            <TouchableOpacity onPress={() => setShowPhrase((value) => !value)} className="flex-1 rounded-2xl bg-primary px-4 py-3 active:opacity-80">
              <Text className="text-center font-semibold text-white">{showPhrase ? "Hide" : "Show"}</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={copyPhrase} className="flex-1 rounded-2xl border border-border bg-background px-4 py-3 active:opacity-80">
              <Text className="text-center font-semibold text-primary">Copy</Text>
            </TouchableOpacity>
          </View>
        </View>
        <View className="rounded-[28px] border border-border bg-surface p-5 gap-4">
          <View className="flex-row items-center gap-2">
            <IconSymbol name="shield.fill" size={22} color="#16A34A" />
            <Text className="text-xl font-semibold text-foreground">Security status</Text>
          </View>
          <Text className="text-sm leading-5 text-muted">
            Identity, contacts, and messages are persisted locally with AsyncStorage for this preview. Production encryption and backend delivery can be wired to the existing Mercurio services later.
          </Text>
        </View>
        <TouchableOpacity onPress={confirmReset} className="flex-row items-center justify-center gap-2 rounded-2xl border border-error px-5 py-4 active:opacity-80">
          <IconSymbol name="trash" size={20} color="#DC2626" />
          <Text className="font-semibold text-error">Reset Local Preview Data</Text>
        </TouchableOpacity>
      </View>
    </ScreenContainer>
  );
}
