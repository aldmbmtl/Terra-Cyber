# Terra Cyber

A series of Terra plugins optimized for cyber operations tools — Kali containers with web terminals, VPN proxies, and Squid proxies for traffic routing.

This repository is a Terra plugin **Source** — add it in the Terra UI like any other source, alongside or instead of the [official plugin catalog](https://github.com/juno-fx/Terra-Official-Plugins).

---

## Plugin Catalog

| Plugin | Type | Category | Description | Docs |
|--------|------|----------|-------------|------|
| [kali](plugins/kali/README.md) | Workload template | Development | Kali Linux container with wetty web terminal + tmux session persistence | [README](plugins/kali/README.md) |
| [squid](plugins/squid/README.md) | Workload template | Networking | VPN-routed Squid HTTP proxy for routing outbound traffic through a tunnel | [README](plugins/squid/README.md) |

---

## Development

```bash
# 1. Enter the dev environment (required for all make targets)
devbox shell

# 2. Create a new plugin (interactive — prompts for type)
make new-plugin

# 3. Edit your plugin files

# 4. If your plugin has a scripts/ directory, package it
make package <plugin-name>

# 5. Verify nothing is stale
make verify
make lint
```

---

## Key Commands

| Command | Description |
|---------|-------------|
| `make new-plugin` | Interactive scaffolding — creates correct boilerplate for your plugin type |
| `make package <name>` | **Required** after any `scripts/` change — bundles scripts into a ConfigMap |
| `make verify` | Checks all plugins have up-to-date packages (runs in CI on every push) |
| `make check-size <name>` | Checks packaged size against the 1MiB Kubernetes ConfigMap limit |
| `make lint` | Helm lint all plugins |

---

## The Packaging Rule

> **If you change anything in `scripts/` or `scripts/chart/`, you MUST run `make package <plugin-name>`.**
> If you skip repackaging, the old version deploys silently with no error. `make verify` catches this.

See [AGENTS.md](AGENTS.md) for the full rules. For authoritative upstream guidance, read the
[Terra-Official-Plugins AGENTS.md](https://github.com/juno-fx/Terra-Official-Plugins/blob/main/AGENTS.md).

---

## License

MIT — see [LICENSE](LICENSE).