// Every release file the site links, in one place: change a name here and every button follows.
// Links are `releases/latest/download/<name>`, so the site stays valid at every release without
// being published again. Without JavaScript the buttons open the latest release's page.
window.RG_SITE = {
  // The repository keeps its old address until it is renamed to Frostmoore/rasgeth (plan 3.9.0,
  // N11); GitHub then redirects the old one.
  repo: "Frostmoore/redgiant2",
  files: {
    rasgethWindows: "Rasgeth-Setup.exe",
    rasgethMac: "Rasgeth-mac-arm64.dmg",
    appWindows: "Rasgeth-App-Setup.exe",
    appLinux: "rasgeth-app-linux-x64.tar.gz",
  },
  // Rasgeth OS images are made only when the OS changes and carry the version in their name
  // (rasgeth-os-<version>-<suffix>; redgiant-os-<version>-<suffix> before 3.9.0): the page looks
  // for the latest release that has them.
  osPrefixes: ["rasgeth-os-", "redgiant-os-"],
  osImages: {
    iso: "x86_64.iso",
    qcow2: "x86_64.qcow2",
    lxc: "x86_64-lxc.tar.zst",
    vhdx: "x86_64.vhdx.zip",
    ova: "x86_64.ova",
    arm64: "arm64.qcow2",
    raspi: "arm64-raspi.img.xz",
  },
};
