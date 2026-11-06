# blocklist

Simple TXT files holding DNS domain lists for network-level ad, tracker, and malware blocking. No fancy formats — just plain text, one domain per line, `#` comments welcome.

## Files

| File | Purpose |
|------|---------|
| [`blocklist.txt`](blocklist.txt) | **~163,000 domains to block** — base list built from curated upstream feeds (below) |
| [`allowlist.txt`](allowlist.txt) | Domains to **never block** — overrides block rules (whitelist); the build subtracts these |
| [`scripts/build.sh`](scripts/build.sh) | Regenerates `blocklist.txt` from the upstream sources |

## Where the list comes from

`blocklist.txt` is the deduplicated union of two reputable feeds:

1. **StevenBlack/hosts + fakenews extension** — ad, tracking, malware, and fakenews domains merged from vetted sources.
   https://github.com/StevenBlack/hosts
2. **HaGeZi Multi LIGHT (onlydomains)** — size-optimized basic protection covering ads, trackers, metrics, telemetry, and some badware; built only from domains appearing in the Top 1M/10M lists.
   https://github.com/hagezi/dns-blocklists

Build process: fetch both → normalize to bare lowercase domains → validate → union + `sort -u` → subtract anything on `allowlist.txt`. Reproduce anytime with `scripts/build.sh`.

## Usage

Point your DNS blocker at the raw URL:

```
https://raw.githubusercontent.com/wickedyoda/blocklist/main/blocklist.txt
```

`allowlist.txt` is consumed by `scripts/build.sh` as a subtraction list; feed its entries into your blocker's whitelist feature as well if you add custom sources later.

### Pi-hole
- **Settings → Blocklist → Add a blocklist**: paste the `blocklist.txt` URL.
- Whitelist: add `allowlist.txt` domains under *Domains allowlisting* (Pi-hole's whitelist overrides blocklists natively).

### AdGuard Home
- **Filters → DNS blocklists → Add a blocklist**: paste the `blocklist.txt` URL.
- **Filters → Custom filtering rules**: add `||domain^$important` per allowlist entry — `$important` beats block rules.

### dnsmasq
```bash
# Generate per-domain address lines from the list:
awk '!/^#/ && NF {print "address=/" $1 "/0.0.0.0"}' blocklist.txt > /etc/dnsmasq.d/blocklist.conf
```

### Unbound
```bash
# Generate local-zone entries:
awk '!/^#/ && NF {print "local-zone: \"" $1 "\" always_refuse"}' blocklist.txt > /etc/unbound/unbound.conf.d/blocklist.conf
```

## Format rules

- One domain per line — **no** `0.0.0.0` prefixes, **no** wildcards, **no** URLs/paths.
- `#` starts a comment.
- In zone-style resolvers (AdGuard, Unbound local-zone), a listed domain also catches its subdomains.

## Size note

The file is ~3.4 MB. Pi-hole, AdGuard Home, Unbound, and dnsmasq handle it fine; very small/embedded resolvers may prefer the HaGeZi LIGHT list alone.

## Contributing

Changes to `main` must go through a pull request (enforced for everyone, including admins). Edit `allowlist.txt` or the sources, run `scripts/build.sh`, and open a PR — don't hand-edit `blocklist.txt`; it is a generated artifact.

## Caveat emptor

Both upstream feeds are curated to minimize false positives, but no list is perfect — expect the odd over-block, which is exactly what the allowlist and the PR flow are for.
