import MaterialIcons from "@expo/vector-icons/MaterialIcons";
import { type ComponentProps } from "react";
import { OpaqueColorValue, type StyleProp, type TextStyle } from "react-native";
import { SymbolWeight } from "expo-symbols";

type MaterialIconName = ComponentProps<typeof MaterialIcons>["name"];
export type IconSymbolName =
  | "house.fill"
  | "message.fill"
  | "person.2.fill"
  | "qrcode"
  | "gearshape.fill"
  | "lock.fill"
  | "shield.fill"
  | "plus"
  | "paperplane.fill"
  | "doc.on.doc"
  | "trash"
  | "key.fill"
  | "chevron.right"
  | "magnifyingglass"
  | "checkmark.seal.fill"
  | "person.crop.circle.fill.badge.plus"
  | "xmark";

const MAPPING: Record<IconSymbolName, MaterialIconName> = {
  "house.fill": "home",
  "message.fill": "chat",
  "person.2.fill": "groups",
  qrcode: "qr-code-2",
  "gearshape.fill": "settings",
  "lock.fill": "lock",
  "shield.fill": "shield",
  plus: "add",
  "paperplane.fill": "send",
  "doc.on.doc": "content-copy",
  trash: "delete",
  "key.fill": "vpn-key",
  "chevron.right": "chevron-right",
  magnifyingglass: "search",
  "checkmark.seal.fill": "verified",
  "person.crop.circle.fill.badge.plus": "person-add",
  xmark: "close",
};

export function IconSymbol({
  name,
  size = 24,
  color,
  style,
}: {
  name: IconSymbolName;
  size?: number;
  color: string | OpaqueColorValue;
  style?: StyleProp<TextStyle>;
  weight?: SymbolWeight | string;
}) {
  return <MaterialIcons color={color} size={size} name={MAPPING[name]} style={style} />;
}
