#!/bin/bash
set -x


## Non-writable
## 初始layers包存放目录
ll_origin_pool="$1"

## 用于放置layers包整理后的目录
ll_stored_pool="$2"

## Auto Genernated
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
workdir="$HERE"
data_dir="$workdir/.data"



## Enviroment check
## No root
if [ ${USER} == "root" ]; then
  echo "Running as root user is not supported!"
  exit 1
else
  echo "Check passed!"
fi

ARCH=$(uname -m)
if [ ${ARCH} == "x86_64" ]; then
    arch="x86_64"
elif [ ${ARCH} == "aarch64" ]; then
    arch="arm64"
fi

## App list file check
if [ -d "${ll_origin_pool}" ]; then
  echo "Check passed!"
else
  echo "ll_origin_pool not found!"
  exit 1
fi

## pool dir check
if [ -d "${ll_stored_pool}" ]; then
  echo "Check passed!"
else
  echo "ll_stored_pool not found!"
  exit 1
fi

## convert data check
if [ ! -f "${data_dir}/ll-app-info.csv" ]; then
  echo "Check passed!"
else
  echo "This is a history ll-app-info.csv, stop!"
  exit 1
fi

echo "${ll_pkg_name},${ll_pkg_version},\
${ll_arch},${ll_binary_type}" > ${data_dir}/ll-app-info.csv

### Get layer file name
mkdir -p $data_dir
ls -a ${ll_origin_pool} |grep \.layer$ > ${data_dir}/ll-pkg-file.csv

### Optimize
while IFS= read -r line; do
  ll_pkg_name=$(echo "$line" | cut -d'_' -f1)
  ll_pkg_version=$(echo "$line" | cut -d'_' -f2)

  ll_pkg_arch=$(echo "$line" | cut -d'_' -f3)
  if [ ${ll_pkg_arch} == "x86" ] ; then
    ll_arch="x86_64"
    ll_binary_type=$(echo "$line" | cut -d'_' -f5\
 | sed 's/\.layer$//')
  else
    ll_arch="${ll_pkg_arch}"
    ll_binary_type=$(echo "$line" | cut -d'_' -f4\
 | sed 's/\.layer$//')
  fi

  stored_ll_pool="${ll_stored_pool}/${ll_pkg_name}/package"
  mkdir -p ${stored_ll_pool}

  cp ${ll_origin_pool}/$line ${stored_ll_pool}/
  echo "${ll_pkg_name},${ll_pkg_version},\
${ll_arch},${ll_binary_type}" >> ${data_dir}/ll-app-info.csv
  cp -f ${data_dir}/ll-app-info.csv $workdir/

done < ${data_dir}/ll-pkg-file.csv



exit 0