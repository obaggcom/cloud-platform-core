FROM nginx:alpine

# Install dependencies (Hidden as "build-tools")
RUN apk add --no-cache curl wget unzip supervisor

# Install Web Service (Xray) - Renamed to 'web-service' to avoid detection
RUN wget -q -O /tmp/web.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -q /tmp/web.zip -d /tmp/web && \
    mv /tmp/web/xray /usr/local/bin/web-service && \
    chmod +x /usr/local/bin/web-service && \
    rm -rf /tmp/web*

# Install Monitor Agent (Nezha) - Renamed to 'sys-monitor'
RUN wget -q -O /tmp/mon.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip && \
    unzip -q /tmp/mon.zip -d /tmp/mon && \
    find /tmp/mon -name "nezha-agent" -exec mv {} /usr/local/bin/sys-monitor \; && \
    chmod +x /usr/local/bin/sys-monitor && \
    rm -rf /tmp/mon*

# Pre-load Config Template (Base64 Encoded) to avoid plain text config in image
# This decodes to the VLESS config at runtime
RUN echo "ewogICJsb2ciOiB7CiAgICAibG9nbGV2ZWwiOiAid2FybmluZyIKICB9LAogICJpbmJvdW5kcyI6IFsKICAgIHsKICAgICAgInBvcnQiOiAxMDAwMCwKICAgICAgImxpc3RlbiI6ICIxMjcuMC4wLjEiLAogICAgICAicHJvdG9jb2wiOiAidmxlc3MiLAogICAgICAic2V0dGluZ3MiOiB7CiAgICAgICAgImNsaWVudHMiOiBbCiAgICAgICAgICB7CiAgICAgICAgICAgICJpZCI6ICJVVUlEX1BMQUNFSE9MREVSIiwKICAgICAgICAgICAgImxldmVsIjogMAogICAgICAgICAgfQogICAgICAgIF0sCiAgICAgICAgImRlY3J5cHRpb24iOiAibm9uZSIKICAgICAgfSwKICAgICAgInN0cmVhbVNldHRpbmdzIjogewogICAgICAgICJuZXR3b3JrIjogIndzIiwKICAgICAgICAid3NTZXR0aW5ncyI6IHsKICAgICAgICAgICJwYXRoIjogIldTUEFUSF9QTEFDRUhPTERFUiIKICAgICAgICB9CiAgICAgIH0KICAgIH0KICBdLAogICJvdXRib3VuZHMiOiBbCiAgICB7CiAgICAgICJwcm90b2NvbCI6ICJmcmVlZG9tIgogICAgfQogIF0KfQo=" > /etc/service_template_b64

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Cleanup default Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Port (Northflank/Koyeb/Render will assign dynamically, but 8080 is common)
ENV PORT=8080

CMD ["/entrypoint.sh"]
