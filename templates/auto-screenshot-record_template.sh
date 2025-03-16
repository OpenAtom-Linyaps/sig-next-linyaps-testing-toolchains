#!/bin/bash
PROJECT_VERSION=$project_version
tmp_dir="$tmp_dir"

if [ "$env_codename" == "eagle" ]; then
  echo "Now working on deepin 20"
elif [ "$env_codename" == "beige" ]; then
  echo "Now working on deepin 23"
else
  echo "Unsupported OS: "$env_codename"!"
fi

## Auto Screenshot
### Set 1
timeout 5 deepin-screen-recorder -f
mv /home/$USER/Pictures/Screenshots/*.png "$res_dir/screenshots/1.png"
#deepin-screen-recorder -f --save-path $LL_WORK_DIR	##无法生效

### Set 2

sleep 3

### Launch the Launcher
if [ "$env_codename" == "eagle" ]; then
  dde-launcher -s &
  sleep 3
  timeout 5 deepin-screen-recorder -f
  pkill dde-launcher
  pkill deepin-screen-recorder
  pkill deepin-screen-r
elif [ "$env_codename" == "beige" ]; then
  dde-launchpad -s &
  sleep 3
  timeout 5 deepin-screen-recorder -f
  pkill dde-launchpad
  pkill deepin-screen-recorder
  pkill deepin-screen-r
fi

  mv /home/$USER/Pictures/Screenshots/*.png "$res_dir/screenshots/2.png"

  sleep 3


## Get pics files names
mkdir -p /tmp/app-test/
ls $res_dir/screenshots/ |grep .png > /tmp/app-test/pics_name.txt
while IFS=, read pics_name; do
    if [ -z "$PICS_NAME" ]; then
        echo "There is no picture file!"
    else
        ## Auto convert pics size
        convert -resize 1440x960! $res_dir/screenshots/$PICS_NAME\
 $res_dir/screenshots/$PICS_NAME
    fi

### Set 3
    cp $deb_workdir/templates/3.png $res_dir/screenshots/
    wmctrl -ic $app_wm_id
done < "/$tmp_dir/pics_name.txt"


exit 0
