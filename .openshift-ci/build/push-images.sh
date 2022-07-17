#!/usr/bin/env bash
set -eo pipefail

registry_rw_login() {
    if [[ "$#" -ne 1 ]]; then
        die "missing arg. usage: registry_rw_login <registry>"
    fi

    local registry="$1"

    case "$registry" in
        docker.io/stackrox)
            if [[ -z "$DOCKER_IO_PUSH_USERNAME" ]]; then
                echo "DOCKER_IO_PUSH_USERNAME is not defined"
                exit 1 # Change to exit 1 later
            fi
            docker login --username "$DOCKER_IO_PUSH_USERNAME" --password-stdin docker.io <<< "$DOCKER_IO_PUSH_PASSWORD"
            ;;
        quay.io/rhacs-eng)
            if [[ -z "$QUAY_RHACS_ENG_RW_USERNAME" ]]; then
                echo "QUAY_RHACS_ENG_RW_USERNAME is not defined"
                exit 1 # Change to exit 1 later
            fi
            docker login --username "$QUAY_RHACS_ENG_RW_USERNAME" --password-stdin quay.io <<< "$QUAY_RHACS_ENG_RW_PASSWORD"
            ;;
        quay.io/stackrox-io)
            if [[ -z "$QUAY_STACKROX_IO_RW_USERNAME" ]]; then
                echo "QUAY_STACKROX_IO_RW_USERNAME is not defined"
                exit 1 # Change to exit 1 later
            fi
            docker login --username "$QUAY_STACKROX_IO_RW_USERNAME" --password-stdin quay.io <<< "$QUAY_STACKROX_IO_RW_PASSWORD"
            ;;
        *)
            echo "Unsupported registry login: $registry"
            ;;
    esac
}

shopt -s nullglob
for cred in /tmp/secret/**/[A-Z]*; do
    export "$(basename "$cred")"="$(cat "$cred")"
done

oc registry login

registry_rw_login quay.io/rhacs-eng

cd /go/src/github.com/stackrox/collector
COLLECTOR_VERSION="$(make tag)"

oc image mirror "$COLLECTOR_FULL" quay.io/rhacs-eng/collector:"$COLLECTOR_VERSION"
