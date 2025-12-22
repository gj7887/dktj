FROM node:alpine3.20

ENV DEBIAN_FRONTEND=noninteractive \
    FILE_PATH=/data

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Xray core
RUN XRAY_TMP="/tmp/xray" \
    && mkdir -p "${XRAY_TMP}" /usr/local/share/xray \
    && curl -fsSL https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -o "${XRAY_TMP}/xray.zip" \
    && unzip -q "${XRAY_TMP}/xray.zip" -d "${XRAY_TMP}" \
    && install -m 755 "${XRAY_TMP}/xray" /usr/local/bin/xray \
    && install -m 644 "${XRAY_TMP}/geoip.dat" /usr/local/share/xray/geoip.dat \
    && install -m 644 "${XRAY_TMP}/geosite.dat" /usr/local/share/xray/geosite.dat \
    && rm -rf "${XRAY_TMP}"

# Install cloudflared
RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY src ./src

VOLUME ["/data"]
EXPOSE 3000 8001

CMD ["node", "src/index.js"]
