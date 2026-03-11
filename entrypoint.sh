#!/bin/sh

# Colors for logging
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting Service Initialization...${NC}"

# =========================================================
# 1. SETUP VARIABLES
# =========================================================
UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
PORT=${PORT:-8080}
WSPATH=${WSPATH:-'/vless'}

echo -e "${GREEN}Configuring Service - Port: $PORT | UUID: $UUID | Path: $WSPATH${NC}"

# =========================================================
# 2. SETUP SERVICE CONFIG (DECODE BASE64)
# =========================================================
base64 -d /etc/service_template_b64 > /etc/service_config.json

# Replace placeholders
sed -i "s#UUID_PLACEHOLDER#$UUID#g" /etc/service_config.json
sed -i "s#WSPATH_PLACEHOLDER#$WSPATH#g" /etc/service_config.json

# =========================================================
# 3. SETUP CAMOUFLAGE (NGINX)
# =========================================================
mkdir -p /usr/share/nginx/html
echo '<!DOCTYPE html><html><head><title>System Status</title><style>body { width: 35em; margin: 0 auto; font-family: Tahoma, Verdana, Arial, sans-serif; }</style></head><body><h1>Service Operational</h1><p>The system is running normally.</p></body></html>' > /usr/share/nginx/html/index.html

cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen $PORT default_server;
    listen [::]:$PORT default_server;
    
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location $WSPATH {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# =========================================================
# 4. SETUP MONITOR AGENT (NEZHA)
# =========================================================
MONITOR_ARGS=""

if [ ! -z "$NZ_SERVER" ] && [ ! -z "$NZ_CLIENT_SECRET" ]; then
    echo -e "${GREEN}Monitor V1 configuration detected.${NC}"
    
    TLS_FLAG=""
    if [ "$NZ_TLS" = "true" ] || [ "$NZ_TLS" = "1" ]; then
        TLS_FLAG="--tls"
    fi
    
    # Debug: Print args (masking secret)
    SERVER_MASKED=$(echo "$NZ_SERVER")
    echo "Debug: Server=$SERVER_MASKED TLS=$TLS_FLAG"

    # Explicitly constructing the command line for V1
    # Note: Some versions prefer -s host:port, others separate -p port
    # The safest bet for modern agent is: -s host:port -p secret [--tls]
    MONITOR_ARGS="-s $NZ_SERVER -p $NZ_CLIENT_SECRET $TLS_FLAG"
    
    # Try disabling auto-update just in case permission issues
    MONITOR_ARGS="$MONITOR_ARGS --disable-auto-update --disable-force-update --report-delay 3"

elif [ ! -z "$NEZHA_SERVER" ] && [ ! -z "$NEZHA_KEY" ]; then
    echo -e "${GREEN}Monitor Legacy configuration detected.${NC}"
    
    TLS_FLAG=""
    if [ "$NEZHA_TLS" = "1" ] || [ "$NEZHA_TLS" = "true" ]; then
        TLS_FLAG="--tls"
    fi
    MONITOR_ARGS="-s ${NEZHA_SERVER}:${NEZHA_PORT:-5555} -p ${NEZHA_KEY} $TLS_FLAG"
fi

# =========================================================
# 5. START SUPERVISOR (Dynamic Config)
# =========================================================
cat > /etc/supervisord_custom.conf <<EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=/usr/sbin/nginx -g 'daemon off;'
autostart=true
autorestart=true
stderr_logfile=/var/log/nginx.err.log
stdout_logfile=/var/log/nginx.out.log

[program:web-service]
command=/usr/local/bin/web-service run -c /etc/service_config.json
autostart=true
autorestart=true
stderr_logfile=/var/log/web.err.log
stdout_logfile=/var/log/web.out.log
EOF

if [ ! -z "$MONITOR_ARGS" ]; then
    cat >> /etc/supervisord_custom.conf <<EOF

[program:sys-monitor]
command=/usr/local/bin/sys-monitor $MONITOR_ARGS
autostart=true
autorestart=true
stderr_logfile=/var/log/monitor.err.log
stdout_logfile=/var/log/monitor.out.log
EOF
fi

echo -e "${GREEN}Starting Process Manager...${NC}"
exec supervisord -c /etc/supervisord_custom.conf
