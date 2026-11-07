# orca-railway

[Orca](https://github.com/stablyai/orca) (`stablyai/orca`, an agent-orchestration IDE) running as a headless runtime server on Railway, as a container image.

- The official Orca Linux release (v1.4.252), extracted from the AppImage and run with `orca serve`.
- Listens on Railway's `$PORT` (default 8080) and serves the Orca web client and the WebSocket on it.
- Advertises `wss://$RAILWAY_PUBLIC_DOMAIN`, so a paired client connects to the public address.
- Starts as root only to chown the volume mounted at `/home/orca`, then runs as the unprivileged `orca` user.
- Prints the pairing URL (`orca://pair?code=...`) in the deploy log and writes it to `/home/orca/pairing-url.txt`.
  The pairing URL is the credential: anyone holding it can drive this runtime. It is stable across restarts
  while the volume survives.

Environment: `PORT` (default 8080), `RAILWAY_PUBLIC_DOMAIN` (sets the advertised endpoint).

Image: `ghcr.io/bon5co/orca`. This wrapper is MIT licensed, like Orca itself.
