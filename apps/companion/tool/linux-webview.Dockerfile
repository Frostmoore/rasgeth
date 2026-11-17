# G42.0: what the web view adds to rgcompanion-linux-build:trixie (after linux-audio.Dockerfile):
# WebKitGTK 4.1 for webview_all_linux (the Canvas's editors, widgets, artifacts and «All settings»
# inside the window), GStreamer's libav and bad plugins for H.264 in <video>, Mesa for WebGL under
# Xvfb (software), and fonts so the pages draw as on a desktop. Layered on the image already there:
#   docker build -t rgcompanion-linux-build:trixie -f tool/linux-webview.Dockerfile tool
FROM rgcompanion-linux-build:trixie
RUN apt-get update && apt-get install -y --no-install-recommends \
    libwebkit2gtk-4.1-dev gstreamer1.0-libav gstreamer1.0-plugins-bad gstreamer1.0-gl \
    libgl1-mesa-dri mesa-utils fonts-dejavu-core fonts-noto-core \
  && rm -rf /var/lib/apt/lists/*
