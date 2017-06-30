#!/bin/bash

#Stable, beta, or dev branch
toolbranch="Developer"
#Version information
toolversion="0.0"

f_setup(){
  #Create working directories
  clear
  maindirectory=~/Android-Utility
  commondirectory=$maindirectory/all
  tooldirectory=$commondirectory/tools
  mkdir -p $commondir/gapps
  cd $maindirectory
  clear

  #Determine the platform. This will be used of OSX support later.
  unamestring=`uname`
  case $unamestring in
    Darwin)
      clear
      echo "OSX is not supported at this time. Check back later."
      Exit;;
    *)
      if [ -d $tooldirectory ]; then
        clear
      else
        clear
        echo "Installing wget (Password may be required)"
        echo ""
        sudo apt-get -qq update && sudo apt-get -qq -y install wget
        clear
        echo "Downloading ADB and Fastboot"
        echo ""
        mkdir -p $tooldirectory
        cd $tooldirectory
        wget "https://dl.google.com/android/repository/platform-tools-latest-linux.zip"
        clear
        unzip platform-tools-latest-linux.zip
        mv ./platform-tools/adb ./adb
        mv ./platform-tools/fastboot ./fastboot
        rm -rf ./platform-tools-latest-linux.zip
        rm -rf ./platform-tools
        cd $maindirectory
        clear
      fi
      adb=$tooldirectory/adb
      fastboot=$tooldirectory/fastboot;;
    esac

  chmod 755 $adb
  chmod 755 $fastboot
  clear
}

f_autodevice(){
  clear
  $adb start-server
  cd $maindirectory
  clear
  echo "Connect your device now."
  echo ""
  echo "Start up your device like normal and open the settings menu and scroll down to"
  echo "'About Device' Tap on 'Build Number' 7 times and return to the main settings"
  echo "menu. Open 'Developer Options' and enable the box that says 'USB debugging'. In"
  echo "the RSA Autorization box that pops up, check the box that says 'Always allow"
  echo "from this computer' and tap 'OK'."
  echo ""
  echo "Waiting for device... If you get stuck here, something went wrong."
  $adb wait-for-device
  clear

  echo "Connecting to device and reading device information"
  devicemake=`$adb shell getprop ro.product.manufacturer`
  devicemodel=`$adb shell getprop ro.product.model`
  currentdevice=`$adb shell getprop ro.product.name`
  androidver=`$adb shell getprop ro.build.version.release`
  androidbuild=`$adb shell getprop ro.build.id`
  serialno=`$adb shell getprop ro.serialno`
  twrprecovery=`$adb shell ls /sdcard/ | grep "TWRP"`
  rootedrom=`$adb shell which su`

  androidver=$(echo $androidver|tr -d '\r\n')
  androidbuild=$(echo $androidbuild|tr -d '\r\n')
  devicemake=$(echo $devicemake|tr -d '\r\n')
  devicemodel=$(echo $devicemodel|tr -d '\r\n')
  currentdevice=$(echo $currentdevice|tr -d '\r\n')
  serialno=$(echo $serialno|tr -d '\r\n')
  twrprecovery=$(echo $twrprecovery|tr -d '\r\n')
  rootedrom=$(echo $rootedrom|tr -d '\r\n')

  if [ "$twrprecovery" == "TWRP" ]; then
    twrprecovery="Detected"
  else
    twrprecovery="Not Detected"
  fi

  if [ "$rootedrom" == "/system/xbin/su" ]||[ "$rootedrom" == "/system/sbin/su" ]||[ "$rootedrom" == "/system/bin/su" ]; then
    rootedrom="Rooted"
  else
    rootedrom="Not Rooted"
  fi

  clear
  #case $currentdevice in
  #  sojus|sojuk|sojua|soju|mysidspr|mysid|yakju|takju|occam|hammerhead|shamu|nakasi|nakasig|razor|razorg|mantaray|volantis|tungsten|fugu)
  #    clear;;
  #  *)
  #    echo "This is not a Nexus device and is being recognized as a '$currentdevice'."
  #    echo "This utility only supports Nexus devices. Sometimes custome ROMs can"
  #    echo "cause this to not recognize the device. If this is an error, please report it!"
  #    echo ""
  #    read -p "Press [Enter] to exit the script."
  #    clear
  #    exit;;
  #esac

  devicedirectory=$maindirectory/$currentdevice
  scriptdirectory=$maindirectory/scripts
  mkdir -p $devicedirectory
  mkdir -p $scriptdirectory

}

f_mainmenu(){
  f_autodevice
  clear
  echo "Android Multitool - Version $toolversion - $toolbranch"
  echo "Connected Device: $devicemake $devicemodel ($currentdevice) ($serialno)"
  echo "Android Version: $androidver ($androidbuild)"
  echo ""
  echo "[1] Unlock / Lock Bootloader (All options below require unlocking!)"
  echo "[2] Install TWRP Recovery"
  echo "[3] Root"
  echo "[4] Install custom ROM"
  echo "[5] Flash Custom Files"
  echo "[6] Restore to Stock (Nexus devices only)"
  echo "[7] Tools"
  echo ""
  echo "[S] Settings and Options."
  echo "[D] Go back and select a different device."
  echo "[Q] Quit."
  echo ""
  read -p "Selection: " menuselection

  case $menuselection in
    1) f_unlocklock; f_mainmenu;;
    2) f_twrp; f_mainmenu;;
    3) f_root; f_mainmenu;;
    4) f_customrom; f_mainmenu;;
    5) f_flash; f_mainmenu;;
    6) f_restore; f_mainmenu;;
    7) f_tools; f_mainmenu;;
    S|s) f_options;;
    D|d)
      clear
      echo "Unplug your current device, and plug in a new one."
      echo ""
      read -p "Press [Enter] to continue." null
      clear
      f_mainmenu;;
    Q|q) clear; exit;;
    *) f_mainmenu;;
  esac
}

f_options(){
  clear
  echo "Nexus Multitool - Version $toolversion - $toolbranch"
  echo "Connected Device: $devicemake $devicemodel ($currentdevice) ($serialno)"
  echo "Android Version: $androidver ($androidbuild)"
  echo ""
  echo "[1] Update Nexus Multitool"
  echo "[2] Delete All Nexus Multitool Files and Exit"
  echo ""
  echo "[R] Return to previous menu"
  echo "[Q] Quit"
  echo ""
  read -p "Selection: " selection

  case $selection in
    1) f_update; f_options;;
    2) f_delete; exit;;
    R|r) f_mainmenu;;
    Q|q) clear ; exit;;
    *) f_options;;
  esac
}

f_update(){
  unamestring=`uname`
  case $unamestring in
  Darwin)
    #self=$BASH_SOURCE
    #$wget -O /tmp/Android-Utility.sh 'https://raw.githubusercontent.com/photonicgeek/Android-Utility/master/Android-Utility.sh'
    #clear
    #rm -rf $self
    #mv /tmp/Android-Utility.sh $self
    #rm -rf /tmp/Android-Utility.sh
    #chmod 755 $self
    #exec $self;;
    ##This is just until I work on OSX support. It shouldn't take long.
    clear
    echo "OSX not supported."
    exit;;
  *)
    self=$(readlink -f $0)
    wget -O $self 'https://raw.githubusercontent.com/Pho7onic/Android-Utility/master/Android-Utility.sh'
    clear
    exec $self;;
  esac
}

f_delete(){
  clear
  echo "Are you sure you would like to delete all Android Utility files?"
  echo "This does not selete the main script."
  echo ""
  echo "[Y] Yes, delete all of the files."
  echo "[N] No, bring me back to the main menu."
  echo ""
  read -p "Selection: " selection

  case $selection in
    Y|y)
      clear
      echo "Deleting all files."
      rm -rf $maindirectory
      sleep 2
      clear
      echo "Files deleted."
      echo ""
      read -p "Press [Enter] to exit the script." null
      clear
      exit;;
    N|n)
      f_mainmenu;;
    *)
      f_delete;;
  esac
}





f_setup
f_mainmenu
