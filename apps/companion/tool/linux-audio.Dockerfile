# G40.10: what the voice adds to rgcompanion-linux-build:trixie (Debian trixie with clang, cmake,
# ninja, GTK 3, libsecret, Xvfb and D-Bus): GStreamer for audioplayers_linux (reading answers
# aloud) and parecord for record_linux («press and talk»). Layered on the image already there:
#   docker build -t rgcompanion-linux-build:trixie -f tool/linux-audio.Dockerfile tool
FROM rgcompanion-linux-build:trixie
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-good \
    pulseaudio-utils \
  && rm -rf /var/lib/apt/lists/*
