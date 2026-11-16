// Every release file the site links, in one place: change a name here and every button follows.
// Links are `releases/latest/download/<name>`, so the site stays valid at every release without
// being published again. Without JavaScript the buttons open the latest release's page.
window.RG_SITE = {
  repo: "Frostmoore/redgiant2",
  files: {
    redgiantWindows: "RedGiant-Setup.exe",
    redgiantMac: "RedGiant-mac-arm64.dmg",
    companionWindows: "RGCompanion-Setup.exe",
    companionLinux: "rgcompanion-linux-x64.tar.gz",
  },
  // RedGiant OS images are made only when the OS changes and carry the version in their name
  // (redgiant-os-<version>-<suffix>): the page looks for the latest release that has them.
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
