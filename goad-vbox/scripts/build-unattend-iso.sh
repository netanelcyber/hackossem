#!/usr/bin/env bash
# Build one small ISO per VM containing autounattend.xml + bootstrap.ps1.
#
# Windows Setup scans the root of every attached volume for autounattend.xml,
# so attaching this as a second optical drive is enough to drive a completely
# unattended install — no modification of the Windows ISO required.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""

usage() {
    cat <<'EOF'
usage: build-unattend-iso.sh [--variant full|light] [--config FILE]

Writes build/<vm>/{autounattend.xml,bootstrap.ps1,unattend.iso}.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --variant) VARIANT="$2"; shift 2 ;;
        --config)  CONF="$2";    shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"

# --- pick an ISO writer ----------------------------------------------------
# Preference order is native tools first, then the bundled pure-python writer
# so the pipeline still works on a machine with no cdrtools installed.
iso_writer=""
if   command -v xorriso     >/dev/null 2>&1; then iso_writer="xorriso"
elif command -v genisoimage >/dev/null 2>&1; then iso_writer="genisoimage"
elif command -v mkisofs     >/dev/null 2>&1; then iso_writer="mkisofs"
elif command -v hdiutil     >/dev/null 2>&1; then iso_writer="hdiutil"
elif command -v python3     >/dev/null 2>&1; then iso_writer="python"
else
    die "no ISO writer available (install xorriso, genisoimage or python3)"
fi
log_dim "iso writer: $iso_writer"

make_iso() {
    local out="$1" label="$2" dir="$3"
    case "$iso_writer" in
        xorriso)
            xorriso -as mkisofs -quiet -V "$label" -J -r -o "$out" "$dir" ;;
        genisoimage|mkisofs)
            "$iso_writer" -quiet -V "$label" -J -r -o "$out" "$dir" ;;
        hdiutil)
            rm -f "$out"
            hdiutil makehybrid -quiet -iso -joliet -default-volume-name "$label" \
                -o "$out" "$dir" >/dev/null ;;
        python)
            python3 "$SCRIPTS_DIR/lib/mkiso.py" -o "$out" -V "$label" \
                "$dir/autounattend.xml" "$dir/bootstrap.ps1" 2>/dev/null ;;
    esac
}

root_dc_ip="$(lab_root_dc_ip "$VARIANT")"
built=0

log_step "Building unattend media for GOAD-$VARIANT"

while IFS= read -r record; do
    [ -n "$record" ] || continue

    name="$(vm_name  "$record")"
    oskey="$(vm_field "$record" 2)"
    octet="$(vm_field "$record" 6)"
    role="$(vm_field  "$record" 7)"
    ip="$GOAD_SUBNET.$octet"

    # The forest root resolves against itself; everything else resolves
    # against the forest root. Getting this wrong is why manual AD builds
    # fail at the domain-join step.
    if [ "$role" = "dc_root" ]; then
        dns="'127.0.0.1'"
    else
        dns="'$root_dc_ip'"
    fi

    # Edition selector: accept either a bare name or an explicit
    # /IMAGE/NAME=... / /IMAGE/INDEX=... override from lab.conf.
    image_var="IMAGE_$oskey"
    image_spec="${!image_var:-}"
    [ -n "$image_spec" ] || die "no $image_var defined in lab.conf"
    case "$image_spec" in
        /IMAGE/*=*) image_key="${image_spec%%=*}"; image_value="${image_spec#*=}" ;;
        *)          image_key="/IMAGE/NAME";       image_value="$image_spec" ;;
    esac

    out_dir="$LAB_BUILD_DIR/$name"
    mkdir -p "$out_dir"

    render_template "$REPO_DIR/templates/autounattend.xml.tmpl" \
        "$out_dir/autounattend.xml" \
        "HOSTNAME=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]')" \
        "IMAGE_KEY=$image_key" \
        "IMAGE_VALUE=$image_value" \
        "ADMIN_PASSWORD=$GOAD_ADMIN_PASSWORD"

    render_template "$REPO_DIR/templates/bootstrap.ps1.tmpl" \
        "$out_dir/bootstrap.ps1" \
        "HOSTNAME=$name" \
        "IP=$ip" \
        "PREFIX=$GOAD_PREFIX" \
        "DNS=$dns" \
        "ROLE=$role"

    # Windows Setup reads XML as UTF-8; a BOM or CRLF is tolerated but plain
    # LF UTF-8 is what the templates already produce.
    python3 - "$out_dir/autounattend.xml" <<'PY' || die "generated XML for $name is malformed"
import sys, xml.etree.ElementTree as ET
ET.parse(sys.argv[1])
PY

    make_iso "$out_dir/unattend.iso" "UNATTEND" "$out_dir"
    [ -s "$out_dir/unattend.iso" ] || die "ISO build produced nothing for $name"

    log_ok "$(printf '%-6s' "$name") $ip  role=$role  dns=${dns//\'/}  $(basename "$out_dir/unattend.iso") ($(wc -c < "$out_dir/unattend.iso") bytes)"
    built=$((built + 1))

done <<EOF
$(lab_vms "$VARIANT")
EOF

log_info ""
log_ok "$built unattend image(s) under $LAB_BUILD_DIR"
