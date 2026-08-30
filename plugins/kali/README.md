# Kali

Kali Linux workload with an integrated [wetty](https://github.com/butlerx/wetty) web terminal and
[tmux](https://github.com/tmux/tmux) session persistence.

Launch a Kali Linux container and open a browser-based terminal. tmux keeps the session alive across
disconnects, so your work persists if you close the tab or the network drops.

## Type

Workload template (`cluster-level` + `workload`). Launched from the Genesis workload catalog, not
installed as a running service.

## Configuration

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `registry` | string | `kalilinux` | Container image registry |
| `repo` | string | `kali-rolling` | Image repository |
| `tag` | string | `latest` | Image tag |
| `packages` | string | `vim` | Space-separated apt packages to install at launch |

### Custom Environment Variables

| Variable | Description |
|----------|-------------|
| `http_proxy` | Squid proxy for outbound HTTP, e.g. `http://<squid-name>-squid:3128` |
| `https_proxy` | Squid proxy for outbound HTTPS, e.g. `http://<squid-name>-squid:3128` |
| `no_proxy` | Comma-separated hosts to bypass the proxy, e.g. `localhost,127.0.0.1` |

Set these via custom env at launch to route Kali terminal traffic (curl, wget, apt, git, python) through a
Squid Proxy workload in the same namespace. `<squid-name>` is the squid workload instance name — its
proxy port is `<squid-name>-squid:3128`.

## How it works

- The workload is a StatefulSet with two containers:
  - **wetty** — the Kali container running the wetty web terminal + tmux session.
  - **nginx** — reverse proxy that forwards the prefixed ingress path to wetty and upgrades websockets.
- An `init-script` ConfigMap mounts `start.sh` / `shutdown.sh` at `/opt/init/`, executed by the
  wetty container on start and shut down via a `preStop` hook.
- tmux is configured for truecolor, mouse support, and a large scrollback. The session name is
  derived from the workstation name (`juno-kali-<name>`); it is not user-configurable.
- Setting the `SUDO` environment variable (via custom env at launch) grants the remapped user
  passwordless sudo and runs the shell as that user instead of root. Only applies when the workload
  is launched with `PUID > 0` (a real user is created); with `PUID=0` the shell stays root.
  `SUDO` is presence-based — any value (even `false` or empty) activates it.

## Ingress

- Path: `/{{ .Release.Namespace }}/kali/{{ .Values.name }}/`
- Auth: Hubble mesh-auth via `nginx.ingress.kubernetes.io/auth-url`
- Timeouts: proxy connect/read/send set to `600`s so long-lived terminal sessions are not cut off.

## Development

Any change to `scripts/chart/` must be followed by `make package NAME=kali`, which regenerates
`templates/packaged-scripts.yaml` and `templates/packaged-scripts-cleanup.yaml`.
