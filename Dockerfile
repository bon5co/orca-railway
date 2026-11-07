# Orca headless server for Railway: the official stablyai/orca Linux release (MIT), extracted from
# the AppImage, with an entrypoint that
# (1) listens on Railway's injected $PORT,
# (2) advertises the service's public wss:// address so a paired client connects to the right place,
# (3) chowns the root-owned volume mounted at /home/orca and drops to the unprivileged orca user,
# (4) publishes the pairing URL (the credential) to the deploy log and to /home/orca/pairing-url.txt.
FROM ubuntu:24.04
ARG ORCA_VERSION=v1.4.252
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
LABEL org.opencontainers.image.source="https://github.com/bon5co/orca-railway"
LABEL org.opencontainers.image.description="Orca (stablyai/orca) headless runtime server with Railway defaults"
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl file git jq openssh-client procps \
      xvfb zlib1g-dev libgtk-3-0t64 libpango-1.0-0 libcairo2 \
      libnss3 libgbm1 libdrm2 libasound2t64 libcups2t64 libxkbcommon0 \
      libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 \
      libx11-xcb1 libxcb-dri3-0 libxcomposite1 libxdamage1 libxfixes3 \
      libxrandr2 libxrender1 libxss1 libxtst6 \
    && rm -rf /var/lib/apt/lists/*
RUN if [ "$TARGETARCH" = arm64 ]; then asset=orca-linux-arm64.AppImage; else asset=orca-linux.AppImage; fi \
    && curl -fL --retry 3 -o /tmp/orca.AppImage "https://github.com/stablyai/orca/releases/download/$ORCA_VERSION/$asset" \
    && chmod +x /tmp/orca.AppImage && cd /opt && /tmp/orca.AppImage --appimage-extract >/dev/null \
    && mv /opt/squashfs-root /opt/orca && chmod -R a+rX /opt/orca && rm /tmp/orca.AppImage
RUN useradd --create-home --shell /bin/bash orca
ENV PATH=/opt/orca/resources/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LIBGL_ALWAYS_SOFTWARE=1
COPY entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh
WORKDIR /home/orca
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
