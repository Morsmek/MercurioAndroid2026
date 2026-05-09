import * as Clipboard from "expo-clipboard";
import { useState } from "react";
import { Share, Text, TouchableOpacity, View } from "react-native";

import { OnboardingCard } from "@/components/mercurio/onboarding-card";
import { QrCard } from "@/components/mercurio/qr-card";
import { ScreenContainer } from "@/components/screen-container";
import { IconSymbol } from "@/components/ui/icon-symbol";
import { useMercurio } from "@/lib/mercurio-store";

export default function ShareScreen() {
  const { identity } = useMercurio();
  const [copied, setCopied] = useState(false);

  if (!identity) {
    return (
      <ScreenContainer className="px-6">
        <OnboardingCard />
      </ScreenContainer>
    );
  }

  const copyId = async () => {
    await Clipboard.setStringAsync(identity.mercurioId);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  const shareId = async () => {
    await Share.share({ message: `Add me on Mercurio: ${identity.mercurioId}` });
  };

  return (
    <ScreenContainer className="px-5 pt-2">
      <View className="flex-1 gap-6">
        <View className="gap-1">
          <Text className="text-3xl font-bold text-foreground">Share ID</Text>
          <Text className="text-base text-muted">Let another Mercurio user add you securely.</Text>
        </View>
        <View className="items-center rounded-[34px] border border-border bg-surface p-6 gap-5">
          <QrCard value={identity.mercurioId} />
          <View className="gap-2">
            <Text className="text-center text-sm font-semibold uppercase tracking-widest text-muted">Mercurio ID</Text>
            <Text selectable className="text-center text-xl font-bold text-foreground">{identity.mercurioId}</Text>
          </View>
          <View className="flex-row gap-3">
            <TouchableOpacity onPress={copyId} className="flex-1 flex-row items-center justify-center gap-2 rounded-2xl bg-primary px-4 py-4 active:opacity-80">
              <IconSymbol name="doc.on.doc" size={18} color="#FFFFFF" />
              <Text className="font-semibold text-white">{copied ? "Copied" : "Copy"}</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={shareId} className="flex-1 flex-row items-center justify-center gap-2 rounded-2xl border border-border bg-background px-4 py-4 active:opacity-80">
              <IconSymbol name="paperplane.fill" size={18} color="#243B8F" />
              <Text className="font-semibold text-primary">Share</Text>
            </TouchableOpacity>
          </View>
        </View>
        <View className="rounded-3xl border border-border bg-surface p-5 gap-2">
          <View className="flex-row items-center gap-2">
            <IconSymbol name="shield.fill" size={20} color="#16A34A" />
            <Text className="font-semibold text-foreground">Privacy note</Text>
          </View>
          <Text className="text-sm leading-5 text-muted">
            Your recovery phrase is never shown on this screen. Share only your Mercurio ID with people you want to contact.
          </Text>
        </View>
      </View>
    </ScreenContainer>
  );
}
