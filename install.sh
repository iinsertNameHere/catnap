#!/bin/bash

curl -version
if [ $? -ne 0 ]; then
    echo "Couldn't fin curl command. Make sure it is installed and available in your PATH!"
fi

# Make sure script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root!"
  exit
fi

###### Function Definitions ######

# Function to ask user for permissions
function yn {
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) echo 0; return 0 ;;  
            [Nn]*) echo 1; return 1;;
        esac
    done
}

function install {
    local src=$1 dst=$2
    local st=0
    
    if [ -f "$dst" ]; then
	echo ""
	echo "File $dst already exists." 
        st=$(yn "Want to Overwrite it?")
	echo ""
    fi
    
    if [ $st -eq 0 ]; then
        echo -n -e "[\033[32minstall\033[0m] Creating $dst ... "
        
        mv -f "$src" "$dst" >/dev/null 2>&1
        
        if [ -f "$dst" ]; then
            echo -e "\033[32mOK\033[0m"
        else
            echo -e "\033[31mFAILED\033[0m"
            exit 1
        fi
    fi
}

function uninstall {
    local target=$1
    if [ -e "$target" ]; then
	echo -n -e "[\033[31muninstall\033[0m] Removing $target ... "
	
	if [ -d "$target" ]; then
	    rm -rf "$target" >/dev/null 2>&1
	elif [ -f "$target" ]; then 
	    rm -f "$target" >/dev/null 2>&1
	fi

	if [ ! -e "$target" ]; then
	    echo -e "\033[32mOK\033[0m"
	else
	    echo -e "\033[31mFAILED\033[0m"
	    exit 1
	fi
    fi
}

MODE=0
function run {
    local msg=$1 cmd=$2 
    local -n reply=$3

    local prefix="[\033[32minstall\033[0m]"
    if [ $MODE -ne 0 ]; then 
	prefix="[\033[31muninstall\033[0m]"
    fi

    echo -n -e "$prefix $msg ... "

    reply=$(eval "$cmd")

    if [ $? -eq 0 ]; then
	echo -e "\033[32mOK\033[0m"
    else
	echo -e "\033[31mFAILED\033[0m"
	exit 1
    fi
}

###### Mode Setup ######

# Set mode (0 = Install, 1 = Uninstall)
ARG=$1
MODE=0

if [ "$ARG" == "uninstall" ]; then
    MODE=1
elif [ "$ARG" == "" ]; then
    MODE=0
else
    echo "Unknown argument: $ARG"
    exit 1
fi

###### Home Fix ######

# Update home
HOME="/home/$SUDO_USER"

###### Display logo ######
echo -e "\033[33m"
echo "             █▄                  "             
echo "            ▄██▄▄                "             
echo " ▄███▀ ▄▀▀█▄ ██ ████▄ ▄▀▀█▄ ████▄"             
echo " ██    ▄█▀██ ██ ██ ██ ▄█▀██ ██ ██"             
echo "▄▀███▄▄▀█▄██▄██▄██ ▀█▄▀█▄██▄████▀"             
echo "       _________________    ██   "             
echo -e "      |\033[97mRelease installer\033[33m|    ▀  "                                  
echo "       ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾         "
echo -e -n "\033[0m"


############### Install Mode ###############

if [ $MODE -eq 0 ]; then
   
    ###### Detect system arch ######

    run "Detecting system architecture" "uname -m" ARCH
	
    # Check that system arch is valid
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "i686" ] && [ "$ARCH" != "armv7l" ] && [ "$ARCH" != "aarch64" ]; then 
	echo "There is no binary build for $ARCH"
	exit 1
    fi

    ###### Detecting latest catnap version ######
    
    # Get latest actual release url from redirect url of '/releases/latest'
    run "Detecting latest version" \
	"curl -Ls -o /dev/null -w %{url_effective} 'https://github.com/iinsertNameHere/catnap/releases/latest/'" \
	RAW_URL

    # Build download url from RAW_URL
    BASE_URL=$(echo $RAW_URL | sed 's/tag/download/')
    
    # Extract version number
    VERSION=$(echo $BASE_URL | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    
    BIN_NAME="catnap-$VERSION-$ARCH"
    CFG_SRC_NAME="catnap-$VERSION-config.tar.gz"
    
    echo ""

    ###### Start installation ######

    echo "Architecture: $ARCH"
    echo "Latest Version: $VERSION"
   
    echo ""

    if [ $(yn "Start installation?") -eq 1 ]; then
        exit 0
    fi

    echo ""
    
    # Create temp dir and cd into it
    WORK_DIR=$(mktemp -d)
    cd $WORK_DIR
    
    ###### Download files ######
    
    # Download bin file
    run "Downloading $BIN_NAME" \
	"curl -LO '$BASE_URL/$BIN_NAME' >/dev/null 2>&1" \
	NULL
    
    
    # Download config source files
    run "Downloading $CFG_SRC_NAME" \
	"curl -LO '$BASE_URL/$CFG_SRC_NAME' >/dev/null 2>&1" \
	NULL 
    
    ###### Extract source ######
    
    CONF_TMP_PATH="config"
    CONF_INSTALL_PATH="$HOME/.config/catnap"
    
    # Extract config files 
    run "Extracting source files" \
	"tar -czf $SRC_NAME $CONF_TMP_PATH config/ >/dev/null 2>&1" \
	NULL  

    ###### Install bin file ###### 
    
    chmod +x "$BIN_NAME"
    install "$BIN_NAME" "/usr/local/bin/catnap"
    
    ###### Install Config files ######
    
    # Create config dir 
    mkdir -p "$CONF_INSTALL_PATH/themes"
    
    # Install config.cat
    install "$CONF_TMP_PATH/config.cat" "$CONF_INSTALL_PATH/config.cat"
    
    # Install distros.cat
    install "$CONF_TMP_PATH/distros.cat" "$CONF_INSTALL_PATH/distros.cat"
    
    # Install theme
    install "$CONF_TMP_PATH/themes/catppuccin-mocha.cat" "$CONF_INSTALL_PATH/themes/catppuccin-mocha.cat"
    
    ###### Clean up ######
    
    cd 
    rm -rf "$WORK_DIR"
    
    ###### Installed catnap successfully ######
    
    echo ""
    echo "Successfully installed catnap $VERSION!"



############### Uninstall Mode ###############

else

    if [ $(yn "Continue uninstalling catnap?") -eq 1 ]; then
        exit 0
    fi

    echo ""

    ###### Uninstall bin file ###### 
    uninstall "/usr/local/bin/catnap"
   
    echo ""

    ###### Uninstall Config files ######
    if [ $(yn "Remove config files?") -eq 1 ]; then	
	echo ""
	echo "Successfully uninstalled catnap"
	exit 0
    fi

    echo ""
    
    CONF_INSTALL_PATH="$HOME/.config/catnap"

    # Uninstall config.cat 
    uninstall "$CONF_INSTALL_PATH/config.cat"
    
    # Uninstall distros.cat
    uninstall "$CONF_INSTALL_PATH/distros.cat"
    
    # Uninstall theme
    uninstall "$CONF_INSTALL_PATH/themes/catppuccin-mocha.cat"
    
    ###### Uninstalled catnap successfully ######
    echo ""
    echo "Successfully uninstalled catnap"
fi
