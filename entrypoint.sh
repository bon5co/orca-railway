#!/bin/bash
# Orca headless server on $PORT. Runs as root only long enough to fix the volume's ownership.
set -euo pipefail

HOME_DIR=/home/orca
LISTEN_PORT="${PORT:-8080}"
PAIR_FILE="$HOME_DIR/pairing-url.txt"

mkdir -p "$HOME_DIR"
echo "[boot] home owner before=$(stat -c %u:%g "$HOME_DIR") listen=0.0.0.0:$LISTEN_PORT"
chown -R orca:orca "$HOME_DIR"
echo "[boot] home owner after=$(stat -c %u:%g "$HOME_DIR")"

if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  ADVERTISE="wss://${RAILWAY_PUBLIC_DOMAIN}"
else
  ADVERTISE="ws://localhost:${LISTEN_PORT}"
fi
echo "[boot] advertised endpoint $ADVERTISE"

# Copy the pairing URL out of the server's own output into a file: it is the credential an agent
# needs, and it is otherwise only in the log stream. (A bash read loop, not awk: Ubuntu's mawk
# buffers piped input in blocks, so the log would stall until the buffer filled.)
export HOME="$HOME_DIR" USER=orca LOGNAME=orca
tee_pairing() {
  local line
  while IFS= read -r line; do
    printf '%s\n' "$line"
    case "$line" in
      "Pairing URL: "*)
        printf '%s\n' "${line#Pairing URL: }" > "$PAIR_FILE"
        chown orca:orca "$PAIR_FILE"
        chmod 600 "$PAIR_FILE"
        ;;
    esac
  done
}
setpriv --reuid=orca --regid=orca --init-groups \
  /opt/orca/AppRun --no-sandbox serve --port "$LISTEN_PORT" --bind 0.0.0.0 \
    --pairing-address "$ADVERTISE" \
  > >(tee_pairing) 2>&1 &
SERVER=$!
trap 'kill -TERM "$SERVER" 2>/dev/null || true' TERM INT
wait "$SERVER"
