FROM node:20-bookworm AS build

ENV DEBIAN_FRONTEND=noninteractive \
    FILE_PATH=/data \
    APP_DIR=/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        xz-utils \
        binutils \
    && rm -rf /var/lib/apt/lists/*

# Download and slim Xray core
RUN XRAY_TMP="/tmp/xray" \
    && install -d /opt/bin /opt/share/xray \
    && mkdir -p "${XRAY_TMP}" \
    && curl -fsSL https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o "${XRAY_TMP}/xray.zip" \
    && unzip -q "${XRAY_TMP}/xray.zip" -d "${XRAY_TMP}" \
    && install -m 755 "${XRAY_TMP}/xray" /opt/bin/xray \
    && install -m 644 "${XRAY_TMP}/geoip.dat" /opt/share/xray/geoip.dat \
    && install -m 644 "${XRAY_TMP}/geosite.dat" /opt/share/xray/geosite.dat \
    && strip --strip-unneeded /opt/bin/xray \
    && rm -rf "${XRAY_TMP}"

# Download and slim cloudflared
RUN install -d /opt/bin \
    && curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /opt/bin/cloudflared \
    && chmod +x /opt/bin/cloudflared \
    && strip --strip-unneeded /opt/bin/cloudflared || true

WORKDIR ${APP_DIR}
COPY package*.json ./
RUN npm install --package-lock-only --omit=dev \
    && npm ci --omit=dev
COPY src ./src

FROM gcr.io/distroless/nodejs20-debian12 AS runtime
ENV FILE_PATH=/data \
    NODE_ENV=production

COPY --from=build /opt/bin/xray /usr/local/bin/xray
COPY --from=build /opt/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=build /opt/share/xray /usr/local/share/xray
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /app /app

WORKDIR /app
VOLUME ["/data"]
EXPOSE 3000 8001

CMD ["src/index.js"]
