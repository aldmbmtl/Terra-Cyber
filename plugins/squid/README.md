# Squid Proxy

VPN-routed [Squid](http://www.squid-cache.org/) HTTP proxy. Outbound HTTP/HTTPS traffic from other
workloads is forwarded through a VPN tunnel (via [gluetun](https://github.com/qdm12/gluetun)) before
leaving the cluster.

Launch a proxy instance, then point other workloads in the same namespace at it with
`http_proxy`/`https_proxy`. Common for routing cyber tooling or downloaders through a egress VPN.

## Type

Workload template (`cluster-level` + `workload`). Launched per-instance from the Genesis workload
catalog, categorized as a `Server`. Not installed as a running service.

## Configuration

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `vpnProvider` | select | *(required)* | VPN provider (e.g. `nordvpn`, `protonvpn`, `windscribe`) |
| `serverCountries` | string | *(required)* | Country(ies) to connect through (e.g. `Canada`, comma-separated for multiple) |
| `firewallSubnets` | string | `0.0.0.0/0` | Outbound subnets allowed through the VPN. Default routes all traffic through the tunnel |
| `openvpnUser` | string | *(required)* | OpenVPN service username |
| `openvpnPassword` | string | *(required)* | OpenVPN service password |

## How it works

- The workload is a stateless Deployment with two containers:
  - **gluetun** — the VPN client. Requires the `NET_ADMIN` capability and a `/dev/net/tun` hostPath
    volume. The launch-time fields wire into its environment: `VPN_SERVICE_PROVIDER`,
    `SERVER_COUNTRIES`, `FIREWALL_OUTBOUND_SUBNETS`, `OPENVPN_USER`, `OPENVPN_PASSWORD`
    (`VPN_TYPE=openvpn` and `DNS_KEEP_NAMESERVER=on` are fixed).
  - **squid** — the HTTP forward proxy listening on port `3128`, with a readiness probe.
- Runs on workstation nodes (`juno-innovations.com/workstation: "true"`), which must expose
  `/dev/net/tun`.
- The workload selects the instance via the Kuiper instance label.

## Consuming from other workloads

Other pods in the same namespace route traffic through the proxy:

```yaml
env:
  - name: http_proxy
    value: "http://<name>-squid:3128"
  - name: https_proxy
    value: "http://<name>-squid:3128"
  - name: no_proxy
    value: "localhost,127.0.0.1"   # exclude internal hosts when needed
```

Replace `<name>` with the workload instance name.

## Services

- `<name>-squid` — ClusterIP, port `3128` for in-namespace consumption.
- `<name>-squid-nodeport` — NodePort, port `3128` for external access.

There is no ingress: as a forward proxy, it is consumed via the Service, not HTTP path routing.

## Custom Environment Variables

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone for the proxy containers, e.g. `America/New_York` |

## Development

Any change to `scripts/chart/` must be followed by `make package NAME=squid`, which regenerates
`templates/packaged-scripts.yaml` and `templates/packaged-scripts-cleanup.yaml`.
