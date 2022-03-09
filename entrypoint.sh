#!/bin/bash
set -e pipefail

DO_METADATA_API="${DO_METADATA_API:-http://169.254.169.254}"
DO_API="${DO_API:-https://api.digitalocean.com}"
UPDATE_FREQUENCY=$(printf "%d" "${UPDATE_FREQUENCY:-600}") # Default 10 minutes
SED="$(which sed)"
CURL="$(which curl)"

# Helper to fail with message
_fatal() {
  printf "Fatal: %s\n" "$@" >&2
  exit 1
}

# Get droplet metadata
_metadata() {
    $CURL -LSsf "${DO_METADATA_API}/metadata/v1/${1}"
}

_do_api() {
  local ACTION="${1}"
  local PATH="${2}"
  shift 2

  local ARGS
  ARGS=$(echo "$@" | $SED 's/\([^ ][^=]*\)=\([^ ]*\)/"\1": "\2",/g;s/,$//')

  $CURL -LSsf -X "${ACTION}" "${DO_API}/${PATH}" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer ${DO_TOKEN}" \
    -d "{ $ARGS }" 2>&1 # If curl suceeds, output is only stdout. If fails, only stderr
}

_main() {
  # Get DO_TOKEN from a readable secret file
  [ -z "${DO_TOKEN}" ] && [ -r "${DO_TOKEN_FILE}" ] && DO_TOKEN=$(cat "${DO_TOKEN_FILE}")

  # Ensure variables are set
  [ -z "${DO_TOKEN}" ] && _fatal "'DO_TOKEN' or 'DO_TOKEN_FILE' environment variable needs to be set"
  [ -z "${DO_FLOATING_IP}" ] && _fatal "'DO_FLOATING_IP' environment variable not set"

  # Get IP address from hostname
  if [[ ! "$DO_FLOATING_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    DO_FLOATING_IP="$(getent hosts "${DO_FLOATING_IP}" | $SED 's/ .*$//')"
  fi

  # Get droplet metadata
  DROPLET_ID=$(_metadata "id")
  DROPLET_REGION=$(_metadata "region")

  # Update the floating IP via the API
  while true; do
    IP_DATA=$(_do_api GET "v2/floating_ips/${DO_FLOATING_IP}")
    ASSIGNED_DROPLET_ID=$(printf "%s" "${IP_DATA}" | jq -r ".floating_ip.droplet.id")

    if [ "${ASSIGNED_DROPLET_ID}" != "${DROPLET_ID}" ]; then
      printf "%s assigned to %s, reassigning to %s...\n" "${DO_FLOATING_IP}" "${ASSIGNED_DROPLET_ID}" "${DROPLET_ID}"

      _do_api POST "v2/floating_ips/${DO_FLOATING_IP}/actions" \
        "type=assign" "droplet_id=${DROPLET_ID}" > /dev/null \
        || _fatal "Couldn't assign floating ip to myself"
    fi

    # Every 10 minutes
    sleep "${UPDATE_FREQUENCY}"
  done
}

_main "$@"
