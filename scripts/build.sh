#!/usr/bin/env bash
# build.sh — regenerate blocklist.txt from the upstream sources.
# Usage: ./scripts/build.sh   (fetches the feeds and rewrites blocklist.txt)
#
# Sources:
#   1. StevenBlack/hosts + fakenews     -> hosts format, parsed
#   2. HaGeZi Multi LIGHT onlydomains   -> plain domains
# Output: blocklist.txt (union, deduped, lowercased, sorted, allowlist-subtracted)
set -euo pipefail
cd "$(dirname "$0")/.."

SB_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
HZ_URL="https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/light-onlydomains.txt"

mkdir -p cache
curl -sL --retry 3 -o cache/src-stevenblack.txt "$SB_URL"
curl -sL --retry 3 -o cache/src-hagezi-light.txt "$HZ_URL"

# --- Extract domains from both sources, validate, union, dedupe ---
{
  # StevenBlack hosts format: <ip> <domain>; skip comments, localhost-ish, IPv6, scoped IPs
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      sub(/[[:space:]]#.*$/, "")
      if (NF >= 2 && $1 !~ /%/ && $1 != "::1") {
        d = tolower($2); sub(/\.$/, "", d)
        if (d !~ /^(localhost|local|broadcasthost|ip6-)/) print d
      }
    }' cache/src-stevenblack.txt

  # HaGeZi onlydomains: one domain per line
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { sub(/[[:space:]]#.*$/, ""); d = tolower($1); sub(/\.$/, "", d); if (d != "") print d }
  ' cache/src-hagezi-light.txt
} \
| awk '/^[a-z0-9]([a-z0-9_-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9_-]*[a-z0-9])?)+$/ && length($0) <= 253' \
| sort -u > cache/union.txt

# --- Subtract allowlist entries ---
grep -vE '^[[:space:]]*(#|$)' allowlist.txt | tr '[:upper:]' '[:lower:]' | sort -u > cache/allow.txt
comm -23 cache/union.txt cache/allow.txt > cache/final.txt

COUNT=$(wc -l < cache/final.txt | tr -d ' ')
DATE=$(date -u +%Y-%m-%d)

{
  echo "# ============================================================"
  echo "# blocklist.txt — DNS domain blocklist (base list)"
  echo "# Format: one domain per line. Lines starting with # are ignored."
  echo "#"
  echo "# Built from two curated sources:"
  echo "#   1. StevenBlack/hosts + fakenews extension"
  echo "#      $SB_URL"
  echo "#   2. HaGeZi Multi LIGHT (onlydomains)"
  echo "#      $HZ_URL"
  echo "#"
  echo "# Build date: $DATE (UTC)"
  echo "# Unique domains: $COUNT  (union, deduped, allowlist-subtracted)"
  echo "# Regenerate: scripts/build.sh"
  echo "# ============================================================"
  echo ""
  cat cache/final.txt
} > blocklist.txt

echo "blocklist.txt rebuilt: $COUNT domains"
