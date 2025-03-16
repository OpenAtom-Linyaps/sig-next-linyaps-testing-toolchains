#!/bin/bash
set -x

SELF=$(readlink -f "$0")
HERE=${SELF%/*}
workdir="$HERE"
target_list="$1"
ll_origin_pool="$2"
ll_stored_pool="$3"

## Auto Genernated
  while IFS=, read ll_pkg_name; do
    mv ${ll_origin_pool}/${ll_pkg_name}\
 ${ll_stored_pool}/
  done < "$target_list"

exit 0