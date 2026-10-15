#!/bin/bash
# Minimal TCP probe used by Hadoop sshfence: nc -z HOST PORT.
if [[ $# != 3 || $1 != -z ]]; then echo 'usage: nc -z HOST PORT' >&2; exit 2; fi
exec timeout 5 bash -c 'exec 3<>/dev/tcp/$1/$2' -- "$2" "$3"
