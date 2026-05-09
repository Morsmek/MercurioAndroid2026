import { useState } from "react";
import { ActivityIndicator, Text, TouchableOpacity, View } from "react-native";

import { IconSymbol } from "@/components/ui/icon-symbol";
import { useMercurio } from "@/lib/mercurio-store";

export function OnboardingCard() {
  const { createIdentity } = useMercurio();
  const [loading, setLoading] = useState(false);

  const handleCreate = async () => {
    setLoading(true);
    try {
      await createIdentity();
    } finally {
      setLoading(false);
    }
  };

  return (
    <View className="flex-1 justify-between gap-8 py-4">
      <View className="gap-5">
        <View className="h-20 w-20 items-center justify-center rounded-3xl bg-primary self-center shadow-sm">
          <IconSymbol name="lock.fill" size={38} color="#FFFFFF" />
        </View>
        <View className="gap-2">
          <Text className="text-center text-4xl font-bold text-foreground">Mercurio</Text>
          <Text className="text-center text-base leading-6 text-muted">
            Create a local private identity, add contacts by Mercurio ID, and preview the secure chat flow from the GitHub project.
          </Text>
        </View>
      </View>

      <View className="rounded-[28px] border border-border bg-surface p-5 gap-4">
        <Text className="text-xl font-semibold text-foreground">Create private identity</Text>
        <Text className="text-sm leading-5 text-muted">
          For security, Mercurio generates your first identity label automatically. You can share only your Mercurio ID, not a self-entered onboarding name.
        </Text>
        <View className="rounded-2xl border border-border bg-background p-4 gap-2">
          <Text className="text-sm font-medium text-foreground">Secure generated identity</Text>
          <Text className="text-sm leading-5 text-muted">
            No name field is shown during setup, so the first identity cannot be customized by the user at creation time.
          </Text>
        </View>
        <TouchableOpacity onPress={handleCreate} disabled={loading} className="items-center rounded-2xl bg-primary px-5 py-4 active:opacity-80">
          {loading ? <ActivityIndicator color="#FFFFFF" /> : <Text className="text-base font-semibold text-white">Create Private Identity</Text>}
        </TouchableOpacity>
      </View>
    </View>
  );
}
