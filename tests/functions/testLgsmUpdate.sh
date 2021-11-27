#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

OLD_VERSION="v21.3.3"
VERSION="$1"
GAMESERVER="$2"
VOLUME="$3"

(
    cd "$(dirname "$0")/../.."
    ./tests/quick.sh --version "$VERSION" --volume "$VOLUME" "$GAMESERVER"

    log_downgrade="downgrade.log"
    log_update="upgrade.log"
    function log() {
        if [ -n "${2:-}" ]; then
            echo "[error][testLgsmUpdate] $1"
            tail "$log_downgrade" || true
            tail "$log_update" || true
            rm "$log_downgrade" "$log_update" > /dev/null 2>&1 || true
            exit "$2"
        else
            echo "[testLgsmUpdate] $1"
        fi
    }

    # old versions are allowed to fail, as long as log contains the expected entry
    ./tests/quick.sh --logs --version "$OLD_VERSION" --volume "$VOLUME" "$GAMESERVER" > "$log_downgrade" || true 
    if ! grep -qF '[lgsm-init] force uninstall lgsm' "$log_downgrade"; then
        log "downgrading from \"$VERSION\" to \"$OLD_VERSION\" successful but container didn't forcefully uninstalled lgsm" 21 

    elif ! ./tests/quick.sh --logs --version "$VERSION" --volume "$VOLUME" "$GAMESERVER" > "$log_update"; then
        log "upgrading from \"$OLD_VERSION\" to \"$VERSION\" failed" 22

    elif ! grep -qF '[lgsm-init] force uninstall lgsm' "$log_update"; then
        log "upgrading successful but container didn't forcefully uninstalled lgsm" 23

    else
        log "successfully downgraded and upgraded lgsm"
    fi
)
