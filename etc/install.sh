#!/usr/bin/env bash
# coding: utf-8
#
# Interactive QCHECK installer script. Run this script to download
# and install qcheck, a TST CUSTOM COMMAND tool. Be sure that TST is
# already installed in your environment.
# This script can be invoked with these options:
#
# --pre-release
#       Download the latest pre-release version available.
#
# --installation-dir <dir>
#       Install the new version into <dir>.

# constants
INSTALL_DIR=~/.tst/qcheck.install
TST_DIR=~/.tst
CONFIG_FILE=~/.tst/config.json
UPDATE="false"

# URL
CC_URL=https://raw.githubusercontent.com/mattjmorrison/Python-Cyclomatic-Complexity/master/cc.py
PYCODESTYLE_URL= https://raw.githubusercontent.com/PyCQA/pycodestyle/master/pycodestyle.py
RADON_URL=

# colors
RESET="\033[0m"
BLACK="\033[0;30m"
BLUE="\033[0;34m"
BROWN="\033[0;33m"
CYAN="\033[0;36m"
DGRAY="\033[1;30m"
GREEN="\033[0;32m"
LBLUE="\033[1;34m"
LCYAN="\033[1;36m"
LGRAY="\033[0;37m"
LGREEN="\033[1;32m"
LPURPLE="\033[1;35m"
LRED="\033[1;31m"
PURPLE="\033[0;35m"
RED="\033[0;31m"
WHITE="\033[1;37m"
YELLOW="\033[1;33m"

# semantic colors
NORMAL=$LGRAY
WARNING=$LRED
IMPORTANT=$LBLUE
QUESTION=$LGREEN

# read either 'y' or 'n' from keyboard
function get_yes_or_no {
    while true; do 
        read -s -n 1 answer
        [[ "$answer" == "y" ]] && break
        [[ "$answer" == "n" ]] && break
    done
    echo $answer
}

# print with color
function print {
    COLOR=$2
    if [ "$COLOR" == "" ]; then
        COLOR=$NORMAL
    fi

    echo -n -e $COLOR"$1"$RESET
}


# MAIN
if [[ "$EUID" == "0" ]]; then
   print "This script cannot be run as root\n" $WARNING
   exit 1
fi

# process options
while (( $# > 0 )); do
    case "$1" in
        --pre-release)
            DOWNLOAD_DEV_VERSION="true"
            ;;
        --installation-dir)
            INSTALLATION_DIR="true"
            TST_DIR=$2
            shift
            ;;
        --*)
            print "invalid option $1\n" $WARNING
            exit 1
            ;;
    esac
    shift
done

# require curl or abort
CURL=$(command -v curl)
if [ $? != 0 ]; then
    print "The installation script requires the curl command" $WARNING
    print "Aborting installation"
    exit 1
fi

# require pip or abort
PIP=$(command -v curl)
if [ $? != 0 ]; then
    print "The installation script requires the pip command" $WARNING
    print "Aborting installation"
    exit 1
fi

# require unzip or abort
UNZIP=$(command -v unzip)
if [ $? != 0 ]; then
    print "The installation script requires the unzip command" $WARNING
    print "Aborting installation";
    exit 1
fi

# identify releases url
if [ "$DOWNLOAD_DEV_VERSION" == "true" ]; then
    RELEASES_URL='https://api.github.com/repos/elianearaujo/tst-qcheck/releases'
    print "* fetching development pre-release information\n"
else
    #Checar qual é essa URL
    #Corrigir aqui!!
    RELEASES_URL='https://api.github.com/repos/elianearaujo/tst-qcheck/releases/latest'
    print "* fetching latest release information\n"
    
fi

# download releases info: identify tag_name and zipball_url
RELEASES=$(curl -q $RELEASES_URL 2> /dev/null)
if [ $? != 0 ]; then
    print "Couldn't download release information\n" $WARNING
    print "Installation aborted\n"
    exit 1
fi
TAG_NAME=$(echo -e "$RELEASES" | grep "tag_name" | cut -f 4 -d '"' | head -1)
ZIPBALL_URL=$(echo -e "$RELEASES" | grep "zipball_url" | cut -f 4 -d '"' | head -1)


# cancel installation if there's no release available
if [ "$TAG_NAME" == "" ]; then
    print "No release available\n" $WARNING
    print "Installation canceled\n" $IMPORTANT
    exit 1
fi

# create new installation dir
if [ -d "$INSTALL_DIR" ]; then
    if [ "$UPDATE" == "false" ]; then
        print "* deleting failed attempt to install" $WARNING 
    fi
    rm -rf $INSTALL_DIR
fi
mkdir -p $INSTALL_DIR

# download latest release into INSTALL_DIR
cd $INSTALL_DIR

curl -q -Lko qcheck.zip $ZIPBALL_URL 2> /dev/null
if [ $? != 0 ]; then
    rm -rf $INSTALL_DIR
    echo $ZIPBALL_URL
    print "Couldn't download release zip\n" $WARNING
    print "Installation aborted\n"
    print "Temporary files deleted\n"
    exit 1
fi

# unzip and install tst scripts within INSTALL_DIR
print "* unzipping and installing qcheck scripts\n"
unzip -q qcheck.zip
rm qcheck.zip

# move files to TST_DIR
mv tst-qcheck*/bin/* $TST_DIR/bin/
mv tst-qcheck*/commands/* $TST_DIR/commands/
mv tst-qcheck*/etc/* $TST_DIR/etc/

# download third party dependencies
# pycodestyle
curl -o pycodestyle.py $PYCODESTYLE_URL 2> /dev/null
if [ $? != 0 ]; then
    print "Couldn't download dependendy\n" $WARNING
    print "Installation aborted\n"
    exit 1
fi
mv pycodestyle.py $TST_DIR/bin/

# cc
curl -o CC.py $CC_URL 2> /dev/null
if [ $? != 0 ]; then
    print "Couldn't download dependendy\n" $WARNING
    print "Installation aborted\n"
    exit 1
fi
mv cc.py $TST_DIR/bin/

# Radon
#pip install radon
#if [ $? != 0 ]; then
#    print "Couldn't install radon dependendy\n" $WARNING
#    print "Installation aborted\n"
#    exit 1
#fi

mkdir -p $TST_DIR/qcheck
mv tst-qcheck*/CHANGELOG.md $TST_DIR/qcheck
mv tst-qcheck*/README.md $TST_DIR/qcheck
mv tst-qcheck*/LICENSE $TST_DIR/qcheck

# end installation
rm -rf $INSTALL_DIR
print "Installation finished\n" $IMPORTANT

# configure environment variable TST_CUSTOM_COMMAND
print "\nConfigure environment? (y/n) " $QUESTION
get_yes_or_no
if [[ "$answer" == "y" ]]; then
    cp tst.paths.inc tst.paths.inc.ori
    cat qcheck.inc >> tst.paths.inc
    $TST_DIR/etc/setenv.sh
    cp tst.paths.inc.ori tst.paths.inc
    rm tst.paths.inc.or
    print "Finished environment configuration\n" $IMPORTANT
    print "\nTo make configuration take effect immediately, type the command:\n"
    print "*$IMPORTANT source ~/.bashrc$NORMAL\n"
else
    print "Environment was$WARNING not$NORMAL configured.\n"
    print "Remember to add $IMPORTANT$TST_DIR/bin$NORMAL to PATH and PYTHONPATH\n"
fi
