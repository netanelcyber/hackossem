#!/usr/bin/env bash
# Create the host-only network the lab lives on.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

CONF=""
while [ $# -gt 0 ]; do
    case "$1" in
        --config) CONF="$2"; shift 2 ;;
        --variant) shift 2 ;;              # accepted and ignored; net is shared
        -h|--help) echo "usage: network-setup.sh [--config FILE]"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
require_cmd VBoxManage "install VirtualBox"

log_step "Host-only network on $GOAD_HOSTONLY_HOST_IP/$GOAD_PREFIX"

ifname="$(hostonly_find)"

if [ -n "$ifname" ]; then
    log_ok "reusing existing interface $ifname"
else
    log_info "creating a host-only interface..."
    created="$(VBoxManage hostonlyif create 2>&1)" || {
        log_err "$created"
        die "could not create a host-only interface (on Linux check that the vboxnetadp module is loaded: sudo modprobe vboxnetadp)"
    }
    # Output looks like: Interface 'vboxnet0' was successfully created
    ifname="$(printf '%s' "$created" | grep -oE "'[^']+'" | head -1 | tr -d "'")"
    [ -n "$ifname" ] || die "could not parse interface name from: $created"

    VBoxManage hostonlyif ipconfig "$ifname" \
        --ip "$GOAD_HOSTONLY_HOST_IP" --netmask "$GOAD_NETMASK"
    log_ok "created $ifname"
fi

# Static addressing comes from autounattend, so a DHCP server on this segment
# would only be a second source of truth. Turn it off if one exists.
if VBoxManage list dhcpservers 2>/dev/null | grep -q "HostInterfaceNetworking-$ifname"; then
    VBoxManage dhcpserver modify --interface "$ifname" --disable 2>/dev/null \
        && log_ok "disabled DHCP on $ifname (addresses are static)" \
        || log_warn "could not disable DHCP on $ifname; static addressing may clash"
else
    log_dim "no DHCP server on $ifname (correct — addressing is static)"
fi

log_info ""
VBoxManage list hostonlyifs | awk -v n="$ifname" '
    /^Name:/ { show = ($2 == n) }
    show && /^(Name|IPAddress|NetworkMask|Status):/ { print "  " $0 }
'
log_info ""
log_ok "network ready — guests will use $GOAD_SUBNET.0/$GOAD_PREFIX, host is $GOAD_HOSTONLY_HOST_IP"
