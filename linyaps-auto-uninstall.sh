#!/bin/bash

set -x

SELF=$(readlink -f "$0")
HERE=${SELF%/*}
workdir=${HERE}

## Auto Genernated
data_dir="$workdir/.data"
ll_info_list="${data_dir}/ll-app-info.csv"


## Get file name
{
while IFS=, read ll_pkg_name ll_pkg_version ll_arch ll_binary_type ; do
  ll-cli uninstall "${ll_pkg_name}"/"${ll_pkg_version}" --prune
done < "${ll_info_list}"
}

exit 0
