// RedGiant OS's temporary network (G40.3): RedGiant-Setup-XXXX, opened by the machine at a first
// start (always, for 30 minutes from power on) and, later, as maintenance when the home network
// is missing. What the server says about it to the page and to the app.

/** off, open for a first start, or open for maintenance (never a new owner). */
export type SetupNetworkMode = "off" | "setup" | "maintenance";

/** Why a machine has no temporary network: a container, no Wi-Fi card, a card that cannot. */
export type SetupNetworkCapable = "ok" | "container" | "no_wifi" | "no_ap" | "unknown";

/** A network the machine saw around it before opening the temporary one. */
export interface SetupWifiNetwork {
  ssid: string;
  /** iwd's kind: psk, open, 8021x… */
  security: string;
  /** dBm. */
  signal: number;
}

/** The last home network tried from the temporary network. */
export interface SetupHomeTry {
  state: "connected" | "failed";
  ssid: string;
  /** The helper's code (connect_failed, not_found, wifi_off…) when it failed. */
  error?: string;
  /** Seconds since 1970. */
  at: number;
}

export interface SetupNetworkStatus {
  active: boolean;
  mode: SetupNetworkMode;
  capable: SetupNetworkCapable;
  /** The first start is not completed (the machine's own marker). */
  pending: boolean;
  ssid: string;
  /** The network's public password (iwd's access point needs one; security is the channel's). */
  passphrase: string;
  /** RedGiant's address on it (10.42.0.1). */
  address: string;
  subnet: string;
  since: number | null;
  /** When the first start's window closes (seconds since 1970). */
  windowEnds: number;
  /** A home network is being tried now (the temporary network is closed meanwhile). */
  trying: boolean;
  networks: SetupWifiNetwork[];
  lastTry: SetupHomeTry | null;
}

/** Where a request comes from, as the temporary network sees it. */
export type SetupNetworkHere = "home" | "setup" | "maintenance";

/** `GET /api/setup-network/here` (open: nothing secret in it). */
export interface SetupNetworkHereInfo {
  here: SetupNetworkHere;
  ssid?: string;
}

/** `GET /api/setup-network` (signed in). */
export interface SetupNetworkInfo extends SetupNetworkHereInfo {
  /** null when this installation has no temporary network (no OS helper, or an old system). */
  status: SetupNetworkStatus | null;
}

/** `POST /api/setup-network/home`: the cable, or a Wi-Fi network. */
export type SetupHomeChoice =
  | { cable: true }
  | { ssid: string; password?: string; hidden?: boolean };

/** Its answer: with the cable the address on the home network; with Wi-Fi the attempt started. */
export interface SetupHomeResult {
  state: "connected" | "trying";
  address?: string;
}

/** The setup channel's path (a WebSocket, the nodes' handshake in "setup" mode). */
export const SETUP_CHANNEL_PATH = "/api/setup-channel";
