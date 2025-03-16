#!/bin/bash
PROJECT_VERSION="2.5.4"

#deps: wmctrl, zenity, deepin-screen-recorder

set -x

## Writable
## 延时设置, 必填
## 应用启动前等待时间
launch_wait_time="5"
## 窗口检测前等待时间
check_wait_time="30"

## 强制开关功能
## 启用重复测试功能, 启动已经被测试过的应用
enable_recheck=""

## 启用截图功能, 需要截图时设置为TRUE值, 默认空值表示不进行截图
enable_screenshot=""

## 启用gio加载desktop file, 系统gio满足要求时,可以设置为FALSE值强制不使用gio启动. 默认空值表示根据规则自动判断
gio_launch_desktop=""


## Auto Generated

SELF=$(readlink -f "$0")
HERE=${SELF%/*}
ll_workdir="$HERE"
current_date=$(date +"%Y-%m-%d_%H%M")
env_codename=$(grep "^VERSION_CODENAME" /etc/os-release | cut -d= -f2)

data_dir="$ll_workdir/.data"
ll_info_list="${data_dir}/ll-app-info.csv"
tmp_dir="/tmp/linyaps-testing-toolchain"

### Get some id
sleep 10
de_wm_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')

### install阶段生成的info文件, 用于读取包名、版本
#ll_pkgname_list="$1"
### 用于存放应用图标、兼容性检测截图
ll_res_pool="$1"


ARCH=$(uname -m)
if [ ${ARCH} == "x86_64" ]; then
  arch="x86_64"
elif [ ${ARCH} == "aarch64" ]; then
  arch="arm64"
fi


## Enviroment check
### No root
if [ ${USER} == "root" ]; then
  echo "Running as root user is not supported!"
  exit 1
fi

### Wayland check
if [ "${XDG_SESSION_TYPE}" == "wayland" ]; then
  echo "Toolchains do not support Wayland now !"
  exit 1
fi

### App list file check
if [ ! -f "${ll_info_list}" ]; then
  echo "无法检测到玲珑包名表格文件!"
  exit 1
fi

### desktop launch set
gio_version=$(gio --version)
gio_min_version="2.67.6"

if [[ "${gio_version}" > "${gio_min_version}" ]]; then
  echo "Supports gio launch!"
  if [ -z "${gio_launch_desktop}" ]; then
    gio_launch_desktop="TRUE"
  else
    gio_launch_desktop="${gio_launch_desktop}"
  fi
else
  echo "Does not support gio launch!"
  gio_launch_desktop="FALSE"
fi

## Generate compat-result csv file
### Remove history status list file
rm -rf ${ll_workdir}/${env_codename}-linyaps-compat-result-${current_date}.csv

### Generate titles
echo "pkg-name,installation-status,desktop-file-status\
,launch-status,icons-status,icons-hicolor-status,app_exit_status"\
 > ${ll_workdir}/${env_codename}-linyaps-compat-result-${current_date}.csv

rm -rf ${tmp_dir}
mkdir -p ${tmp_dir}

### pkg-name & version import
while IFS=, read ll_pkgname ll_version ll_arch binary_type; do

  #Check1
  if [ -z "$ll_pkgname" ]; then
    echo "There is no linglong apps pkgname!"
    exit 1
  elif [ -z "$ll_version" ]; then
    echo "Please specify the version of the linglong app!"
    exit 1
  elif [ ! "$ll_arch" == "$arch" ]; then
    echo "The arch of this pak does not match this machine !"
  else


## History mission check
    app_res_dir="${ll_res_pool}/${ll_pkgname}"
    #Check2
    if [ -d "${app_res_dir}" ]; then
      echo "已存在工作目录"
      #Check3
      if [ ! "$enable_recheck" == "TRUE" ]\
 || [ ! "$enable_recheck" == "true" ] ; then
        echo "跳过任务!"
        app_run="FALSE"
      else
        app_run="TRUE"
        mkdir -p $app_res_dir/screenshots $app_res_dir/icons
      fi
      ##Check3
    else
      app_run="TRUE"
      mkdir -p $app_res_dir/screenshots $app_res_dir/icons
    fi

## Install status check
    #Check2
    if [ ! "$app_run" == "TRUE" ] ; then
      installation_status="N/A"
      desktop_file_status="N/A"
      launch_status="N/A"
      icons_status="N/A"
      icons_hicolor_status="N/A"
      app_exit_status="N/A"
      echo "$ll_pkgname,$installation_status,$desktop_file_status\
,$launch_status,$icons_status,$icons_hicolor_status,$app_exit_status"\
 >> ${ll_workdir}/${env_codename}-linyaps-compat-result-${current_date}.csv
    else
      ll_app_dir="/var/lib/linglong/layers/main/$ll_pkgname/$ll_version"
      app_entries_dir="$ll_app_dir/$arch/binary/entries"
      ## app binary dir check
      #Check4
      if [ ! -d "${ll_app_dir}" ]; then
        echo "不存在程序目录,安装异常!"
        export installation_status="failed"
      else
        echo "Installing success!"
        export installation_status="passed"
        ## Pre-testing
        pushd $ll_workdir
        ## Get all desktop files name
        ls -a ${app_entries_dir}/share/applications |grep \.desktop$ > $tmp_dir/ll-desktop-name.csv
        desktop_files_num=$(ls -a ${app_entries_dir}/applications |grep \.desktop$ |wc -l)
        #Check5
        if [ "$desktop_files_num" -gt "1" ]; then
          multi_desktop_file="TRUE"
          ll_desktop_file=$(head -n 1 $tmp_dir/ll-desktop-name.csv)
        else
          multi_desktop_file="FALSE"
          ll_desktop_file=$(cat $tmp_dir/ll-desktop-name.csv)
        fi
        ##Check5
        echo "ll_desktop_file name is $ll_desktop_file"
        #Check5
        if [ -z "$ll_desktop_file" ]; then
          echo "Not existed desktop file!"
          export desktop_file_status="failed"
        else
          echo "Desktop file existed!"
          export desktop_file_status="passed"

          ## Process
          ## Screenshot module
          sleep ${launch_wait_time}

          ## Launch with different ways
          #Check6
          if [ "$gio_launch_desktop" = "TRUE" ]; then
            gio launch "${app_entries_dir}/share/applications/$ll_desktop_file"
          else
            ## Get Exec value
            awk -F'=' '/^Exec/ {print $2}'\
 "${app_entries_dir}/share/applications/$ll_desktop_file" > "$tmp_dir/ll-desktop-exec.txt"
            desktop_exec_num=$(cat "$tmp_dir/ll-desktop-exec.txt" |wc -l)
            #Check7
            if [ "$desktop_exec_num" > "1" ]; then
              multi_desktop_exec="TRUE"
              export exec_command=$(head -n 1 "$tmp_dir/ll-desktop-exec.txt")
            else
              multi_desktop_exec="FALSE"
              export exec_command=$(cat "$tmp_dir/ll-desktop-exec.txt")
            fi
            ##Check7

            ## Launch desktop file exec command
            ## Generate app launch script
            cat "$ll_workdir/templates/exec.sh" | envsubst >"$tmp_dir/ll-desktop-exec.sh"
            chmod +x "$tmp_dir/ll-desktop-exec.sh"
            "$tmp_dir/ll-desktop-exec.sh" &
          fi
          ##Check6

          sleep ${check_wait_time}
          ## Get current top window id
          app_wm_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')

          ## Check if the app window not launch
          #Check6
          if [ "${app_wm_id}" == "${de_wm_id}" ]; then
            echo "This app fialed to launch!"
            export launch_status="failed"
            ## Skip icons checking
            export icons_hicolor_status="N/A"
            export icons_status="N/A"
            icons_status="N/A"
            icons_hicolor_status="N/A"
            app_exit_status="N/A"
          else
            echo "This app succed to launch!"
            export launch_status="passed"
            echo "$ll_pkgname" > "$tmp_dir/last_window_appid.txt"
            ## Generate screenshot script
            ## Set envs for script
            export project_version=$PROJECT_VERSION
            export res_dir=$app_res_dir
            export PICS_NAME="\$pics_name"
            export app_wm_id="$app_wm_id"
            export ll_workdir="$ll_workdir"
            export env_codename="$env_codename"
            export tmp_dir=$tmp_dir
            rm "$ll_workdir/auto-screenshot-record_$PROJECT_VERSION.sh"
            #Check7
            if [ "$enable_screenshot" == "TRUE" ]\
 || [ "$enable_screenshot" == "true" ] ; then
              cat "$ll_workdir/templates/auto-screenshot-record_template.sh"\
 | envsubst > "$ll_workdir/auto-screenshot-record_$PROJECT_VERSION.sh"
              chmod +x "$ll_workdir/auto-screenshot-record_$PROJECT_VERSION".sh
              ./auto-screenshot-record_$PROJECT_VERSION.sh
              wmctrl -ic $app_wm_id
            else
              echo "Screenshot disabled !"
              wmctrl -ic $app_wm_id
            fi
            ##Check7
            ## Icons checking&getting module
            app_icons_dir="$app_entries_dir/share/icons"
            #Check7
            if [ ! -d "${app_icons_dir}" ]; then
              echo "图标目录icons检测失败!"
              export icons_status="failed"
            else
              #Check8
              if [ -d "${app_icons_dir}/hicolor" ]; then 
                echo "标准图标目录hicolor检测成功!"
                export icons_hicolor_status="passed"
                export icons_status="passed"
                cp -rf ${app_icons_dir}/hicolor/*/apps/*.png $app_res_dir/icons
                cp -rf ${app_icons_dir}/hicolor/*/apps/*.svg $app_res_dir/icons
              else
                echo "标准图标目录hicolor检测失败!"
                export icons_hicolor_status="failed"
                export icons_status="passed"
                echo "任务强制继续!"
                cp -rf ${app_icons_dir}/*/*/apps/*.svg $app_res_dir/icons
                cp -rf ${app_icons_dir}/*/*/apps/*.png $app_res_dir/icons
                cp -rf ${app_icons_dir}/*.svg $app_res_dir/icons
                cp -rf ${app_icons_dir}/*.png $app_res_dir/icons
              fi
              ##Check8
            fi

            ## History window check
            sleep 5
            top_wm_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
            #Check6
            if [ "$top_wm_id" == "$de_wm_id" ]; then
              echo "The current window is the desktop"
              rm -rf $tmp_dir
              mkdir -p $tmp_dir
              app_exit_status="passed"
            else
              echo "The current window is not the desktop, recheck for 3 times! "
              wmctrl -ic $top_wm_id
              sleep 2
              top_wm_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
              if [ "$top_wm_id" == "$de_wm_id" ]; then
                echo "The current window is the desktop"
                app_exit_status="passed"
              else
                wmctrl -ic $top_wm_id
                sleep 2
                top_wm_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
                if [ "$top_wm_id" == "$de_wm_id" ]; then
                  echo "The current window is the desktop"
                  app_exit_status="passed"
                else
                  wmctrl -ic $top_wm_id
                  sleep 2
                  top_wm_id=$(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}')
                  if [ "$top_wm_id" == "$de_wm_id" ]; then
                    echo "The current window is the desktop"
                    app_exit_status="passed"
                  else
                    echo "The current window is not the desktop!"
                    error_window_appid=$(cat "$tmp_dir/last_window_appid.txt")
                    app_exit_status="failed"
                  fi
                fi
              fi
            fi
            ##Check6
          fi
          ##Check5
          echo "$ll_pkgname,$installation_status,$desktop_file_status\
,$launch_status,$icons_status,$icons_hicolor_status,$app_exit_status"\
 >> ${ll_workdir}/${env_codename}-linyaps-compat-result-${current_date}.csv
          if [ "$app_exit_status" == "failed" ]; then
            zenity --error --text="任务中断,该应用存在窗口关闭异常的情况: $error_window_appid !" --width=100 --height=50
            exit 1
          fi
        fi
        ##Check4
      fi
      ##Check3
    fi
    ##Check2
  fi
  ##Check1

done < "$ll_info_list"

zenity --info --text="Finish!" --width=100 --height=50

exit 0