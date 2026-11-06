# blocklist

Simple TXT files holding DNS domain lists for network-level ad, tracker, and malware blocking. No fancy formats — just plain text, one domain per line, `#` comments welcome.

## Files

| File | Purpose |
|------|---------|
| [`blocklist.txt`](blocklist.txt) | Domains to **block** (telemetry, ad networks, tracking, malware/phishing, spam) |
| [`allowlist.txt`](allowlist.txt) | Domains to **never block** — overrides block rules (whitelist) |

## Usage

Point your DNS blocker at the raw URLs:

```
https://raw.githubusercontent.com/wickedyoda/blocklist/main/blocklist.txt
https://raw.githubusercontent.com/wickedyoda/blocklist/main/allowlist.txt
```

### Pi-hole
- **Settings → Blocklist → Add**: paste the `blocklist.txt` URL.
- **Whitelist (allowlist)**: add each domain from `allowlist.txt` under *Domains allowlisting*, or bulk-import via `pihole addlist`.

### AdGuard Home
- **Filters → DNS blocklists → Add a blocklist**: paste the `blocklist.txt` URL.
- **Settings → DNS rewrites / Allowlist**: paste `allowlist.txt` entries.

### dnsmasq
```bash
# /etc/dnsmasq.d/blocklist.conf
address=/doubleclick.net/0.0.0.0    # one line per domain, or generate from the file:
conf-file=/etc/dnsmasq.d/generated-blocklist.txt
```
Generate: `awk '{print "address=/" $1 "/0.0.0.0"}' blocklist.txt > generated-blocklist.txt`

### Unbound
```yaml
# /etc/unbound/unbound.conf.d/blocklist.conf
local-zone: "doubleclick.net" always_refuse   # one entry per domain
```

## Format rules

- One domain per line — **no** `0.0.0.0` prefixes, **no** wildcards, **no** URLs/paths.
- `#` starts a comment.
- Subdomains inherit the parent block in most resolvers when the parent is listed as a zone.

## Contributing

Changes to `main` require a pull request (branch protection is enforced). Keep edits minimal: one domain per line, grouped under a section comment.

## Caveat emptor

The malware/phishing/spam entries are illustrative samples. Treat this as a starter list — curate it against your own traffic, and expect the odd false positive (hence the allowlist).
