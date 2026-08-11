#!/usr/bin/env bash
# Download the ISOs a variant needs (and optionally the Xubuntu L1 host ISO)
# into $LAB_ISO_DIR, so the rest of the pipeline resolves them with no flags.
#
# Idempotent: an ISO already present with a matching checksum (or with no known
# checksum) is left alone. Downloads resume (curl -C -) and retry.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
WANT_L1=false
FORCE=false

usage() {
    cat <<'EOF'
usage: fetch-isos.sh [--variant full|light|nested] [--l1] [--force]
  --variant NAME   download the Windows media this variant uses (default: full)
  --l1             also download the official Xubuntu ISO for the L1 host
  --force          re-download even if the file already exists
  --config FILE    alternate lab.conf

Windows media are 180-day evaluation ISOs from Microsoft (no key required).
Files land in $LAB_ISO_DIR (default <repo>/isos) as <oskey>.iso, exactly where
create-vms.sh / deploy-all.sh look by default.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --variant) VARIANT="$2"; shift 2 ;;
        --l1)      WANT_L1=true; shift ;;
        --force)   FORCE=true; shift ;;
        --config)  CONF="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
require_cmd curl "install curl"
mkdir -p "$LAB_ISO_DIR"

# sha256 of a file, portable across sha256sum / shasum
sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
    elif command -v shasum  >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
    else return 1; fi
}

# download URL -> DEST, resuming/retrying; verify optional SHA256.
download() {
    local url="$1" dest="$2" want_sum="${3:-}" label="$4"

    if [ -f "$dest" ] && [ "$FORCE" != true ]; then
        if [ -n "$want_sum" ]; then
            local have; have="$(sha256_of "$dest" || true)"
            if [ "$have" = "$want_sum" ]; then
                log_ok "$label already present, checksum OK"
                return 0
            fi
            log_warn "$label present but checksum differs — re-downloading"
        else
            log_ok "$label already present (no checksum to verify) — skipping"
            log_dim "  $dest"
            return 0
        fi
    fi

    log_info "downloading $label"
    log_dim "  $url"
    log_dim "  -> $dest"
    # -L follow redirects, -C - resume, --retry transient failures.
    if ! curl -fL --retry 5 --retry-delay 3 -C - -o "$dest" "$url"; then
        # -C - fails on some servers if the file is complete or unresumable;
        # one clean retry without resume.
        curl -fL --retry 5 --retry-delay 3 -o "$dest" "$url" \
            || die "download failed for $label — check connectivity or override the URL in lab.conf"
    fi

    if [ -n "$want_sum" ]; then
        local have; have="$(sha256_of "$dest" || die "no sha256 tool to verify $label")"
        [ "$have" = "$want_sum" ] || die "checksum MISMATCH for $label
  expected $want_sum
  got      $have"
        log_ok "$label downloaded, checksum verified"
    else
        log_ok "$label downloaded ($(du -h "$dest" 2>/dev/null | cut -f1)); no published checksum to verify"
    fi
}

# --- Windows media for the variant ----------------------------------------
log_step "Windows media for GOAD-$VARIANT -> $LAB_ISO_DIR"

fetched=0
while IFS= read -r oskey; do
    [ -n "$oskey" ] || continue
    url_var="ISO_URL_$oskey"; sum_var="ISO_SHA256_$oskey"
    url="${!url_var:-}"; sum="${!sum_var:-}"
    dest="$LAB_ISO_DIR/$oskey.iso"

    if [ -z "$url" ]; then
        log_warn "$oskey: no download URL configured (ISO_URL_$oskey is empty)"
        log_dim "  place the ISO manually at $dest, or set ISO_URL_$oskey in lab.conf"
        continue
    fi
    download "$url" "$dest" "$sum" "$oskey"
    fetched=$((fetched + 1))
done <<EOF
$(lab_vms "$VARIANT" | cut -d: -f2 | sort -u)
EOF

# --- Xubuntu L1 ISO (optional) --------------------------------------------
if [ "$WANT_L1" = true ]; then
    log_step "Xubuntu ISO for the L1 host"

    if [ -n "${ISO_URL_xubuntu:-}" ]; then
        # Explicit direct URL wins. Verify against a configured checksum if
        # given, else best-effort against a SHA256SUMS in the same directory.
        x_name="$(basename "${ISO_URL_xubuntu%%\?*}")"
        x_sum="${ISO_SHA256_xubuntu:-}"
        if [ -z "$x_sum" ]; then
            x_dir="$(dirname "$ISO_URL_xubuntu")"
            sums="$(curl -fsL --retry 3 "$x_dir/SHA256SUMS" 2>/dev/null || true)"
            if [ -n "$sums" ]; then
                x_sum="$(printf '%s\n' "$sums" | awk -v f="$x_name" '$2 ~ f {gsub(/\*/,"",$2); if ($2==f) print $1}' | head -1)"
                [ -n "$x_sum" ] && log_dim "checksum for $x_name found in mirror SHA256SUMS"
            fi
        fi
        download "$ISO_URL_xubuntu" "$LAB_ISO_DIR/$x_name" "$x_sum" "Xubuntu ($x_name)"
    else
        # Discover the current point-release filename + checksum from the mirror.
        base="$XUBUNTU_MIRROR/$XUBUNTU_RELEASE/release"
        sums="$(curl -fsL --retry 5 "$base/SHA256SUMS" 2>/dev/null)" \
            || die "could not fetch $base/SHA256SUMS — set ISO_URL_xubuntu or fix XUBUNTU_RELEASE/XUBUNTU_MIRROR"
        line="$(printf '%s\n' "$sums" | grep -E 'desktop-amd64\.iso' | head -1)"
        [ -n "$line" ] || die "no desktop-amd64 image listed for Xubuntu $XUBUNTU_RELEASE"
        x_sum="$(printf '%s' "$line" | awk '{print $1}')"
        x_name="$(printf '%s' "$line" | awk '{print $2}' | tr -d '*')"
        download "$base/$x_name" "$LAB_ISO_DIR/$x_name" "$x_sum" "Xubuntu ($x_name)"
    fi

    log_dim "L1: scripts/create-l1-host.sh --iso $LAB_ISO_DIR/$x_name"
fi

log_info ""
log_ok "ISO fetch complete — $fetched Windows image(s) targeted, files in $LAB_ISO_DIR"
# Note: a trailing '&& ...' here would be the script's last command, and under
# set -e a false test would make the whole script exit non-zero. Use an if.
if [ "$fetched" -gt 0 ]; then
    log_dim "create-vms.sh / deploy-all.sh will now find them automatically"
fi
exit 0
