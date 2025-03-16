#!/bin/bash

set -x

SELF=$(readlink -f "$0")
HERE=${SELF%/*}
workdir=${HERE}
ll_stored_pool="$1"

data_dir="$workdir/.data"
ll_info_list="${data_dir}/ll-app-info.csv"

## Enviroment check
## No root
if [ ${USER} == "root" ]; then
  echo "Running as root user is not supported!"
  exit 1
else
  echo "Check passed!"
fi

## test data check
if [ ! -f "${data_dir}/installation-data.csv" ]; then
  echo "Check passed!"
else
  echo "This is a history installation-data.csv, stop!"
  exit 1
fi

ARCH=$(uname -m)
if [ ${ARCH} == "x86_64" ]; then
    arch="x86_64"
elif [ ${ARCH} == "aarch64" ]; then
    arch="arm64"
fi

## Get file name
while IFS=, read ll_pkg_name ll_pkg_version ll_arch ll_binary_type ; do

  if [ ${ll_arch} == ${arch} ]; then
  ll-cli install ${ll_stored_pool}/${ll_pkg_name}/package/\
${ll_pkg_name}_${ll_pkg_version}_${ll_arch}_${ll_binary_type}.layer
  install_time=$(date +"%Y-%m-%d_%H:%M.%S")
  echo "${ll_pkg_name},${ll_pkg_version},${ll_arch}\
,${ll_binary_type},${install_time}"\
 >> ${data_dir}/installation-data.csv
  fi

done < "${ll_info_list}"


exit 0
