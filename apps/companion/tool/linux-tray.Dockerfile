# G42.17: what the system tray adds to rgcompanion-linux-build:trixie (after linux-webview.Dockerfile):
# Ayatana AppIndicator for tray_manager (the app stays in the tray when its window closes).
# Layered on the image already there:
#   docker build -t rgcompanion-linux-build:trixie -f tool/linux-tray.Dockerfile tool
FROM rgcompanion-linux-build:trixie
RUN apt-get update && apt-get install -y --no-install-recommends libayatana-appindicator3-dev \
  && rm -rf /var/lib/apt/lists/*
