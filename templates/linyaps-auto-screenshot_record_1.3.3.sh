#!/bin/bash
PROJECT_VERSION=$project_version

## Auto Screenshot
### Set 1
timeout 5 deepin-screen-recorder -f
mv /home/$USER/Pictures/Screenshots/*.png "$res_dir/screenshots/1.png"
#deepin-screen-recorder -f --save-path $LL_WORK_DIR	##无法生效

### Set 2

v23_os_tag=$(cat /etc/os-release |grep beige)
#v20_os_tag=$(cat /etc/os-release |grep eagle)

if [ -z "$v23_os_tag" ]; then
  echo "Unsupported OS!"
  echo "按回车退出程序"
  read nouse
  exit 1
else
  echo "Supported OS: "$v23_os_tag"!"
fi

sleep 3


  dde-launchpad -s &
  sleep 3

  timeout 5 deepin-screen-recorder -f
  pkill dde-launchpad
  mv /home/$USER/Pictures/Screenshots/*.png "$res_dir/screenshots/2.png"

  sleep 3


## Get pics files names
mkdir -p /tmp/app-test/
ls $res_dir/screenshots/ |grep .png > /tmp/app-test/pics_name.txt
while IFS=, read pics_name; do
    if [ -z "$PICS_NAME" ]; then
        echo "There is no picture file!"
    else
        #echo $pics_name
        ## Auto convert pics size
        convert -resize 1440x960! $res_dir/screenshots/$PICS_NAME\
 $res_dir/screenshots/$PICS_NAME
    fi
    cp $ll_workdir/templates/3.png $res_dir/screenshots/
    wmctrl -ic $top_wm_id
done < "/tmp/app-test/pics_name.txt"


exit 0
