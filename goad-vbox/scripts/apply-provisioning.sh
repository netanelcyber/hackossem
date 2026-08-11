#!/usr/bin/env bash
# Run the Ansible provisioning against an already-reachable lab.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

VARIANT="full"
CONF=""
INVENTORY=""
PLAYBOOK=""
EXTRA=()

usage() {
    cat <<'EOF'
usage: apply-provisioning.sh [options] [-- <extra ansible-playbook args>]
  --variant full|light|nested   regenerate inventory for this variant first
  --inventory FILE              use an existing inventory instead of generating
  --playbook FILE               run one playbook (default: playbooks/site.yml)
  --check                       ansible dry run
Anything after -- is passed straight through to ansible-playbook.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --variant)   VARIANT="$2";   shift 2 ;;
        --inventory) INVENTORY="$2"; shift 2 ;;
        --playbook)  PLAYBOOK="$2";  shift 2 ;;
        --config)    CONF="$2";      shift 2 ;;
        --check)     EXTRA+=(--check); shift ;;
        --)          shift; EXTRA+=("$@"); break ;;
        -h|--help)   usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

load_config "${CONF:-}"
require_cmd ansible-playbook "install Ansible"

PLAYBOOK="${PLAYBOOK:-$REPO_DIR/playbooks/site.yml}"
[ -f "$PLAYBOOK" ] || die "playbook not found: $PLAYBOOK"

if [ -z "$INVENTORY" ]; then
    INVENTORY="$REPO_DIR/inventory/hosts.ini"
    log_step "Regenerating inventory for GOAD-$VARIANT"
    bash "$SCRIPTS_DIR/generate-inventory.sh" --variant "$VARIANT" --output "$INVENTORY" \
        ${CONF:+--config "$CONF"}
fi
[ -f "$INVENTORY" ] || die "inventory not found: $INVENTORY"

log_step "Connectivity check"
if ! ansible -i "$INVENTORY" windows -m ansible.windows.win_ping >/dev/null 2>&1; then
    log_err "not all hosts answer win_ping"
    log_dim "run scripts/wait-for-winrm.sh --variant $VARIANT first, or debug with:"
    log_dim "  ansible -i $INVENTORY windows -m ansible.windows.win_ping -vvv"
    die "aborting before provisioning"
fi
log_ok "all hosts answer win_ping"

log_step "Running $(basename "$PLAYBOOK")"
run_log="$LOG_DIR/provision-$(date +%Y%m%d-%H%M%S).log"
log_dim "logging to $run_log"

# ANSIBLE_CONFIG so the run uses our ansible.cfg regardless of cwd.
if ANSIBLE_CONFIG="$REPO_DIR/ansible.cfg" \
   ansible-playbook -i "$INVENTORY" "$PLAYBOOK" "${EXTRA[@]}" 2>&1 | tee "$run_log"; then
    log_info ""
    log_ok "provisioning finished — see scripts/health-check.sh to verify"
else
    rc=${PIPESTATUS[0]}
    log_info ""
    log_err "ansible-playbook exited $rc (playbooks are idempotent; fix the cause and re-run)"
    exit "$rc"
fi
