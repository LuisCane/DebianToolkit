#!/bin/bash

#Author: d4t4s3c
#Email:  d4t4s3c@protonmail.com
#GitHub: www.github.com/d4t4s3c

#colors
b="\033[1;37m"
r="\033[1;31m"
v="\033[1;32m"
a="\033[1;33m"
nc="\e[0m"

#var
si=✔
no=✘

# This is a general-purpose function to ask Yes/No questions in Bash, either
# with or without a default answer. It keeps repeating the question until it
# gets a valid answer.
ask() {
  #printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
  # https://djm.me/ask
  local prompt default reply

  while true; do

    if [[ "${2:-}" == "Y" ]]; then
      prompt="[Y/n]"
      default=Y
    elif [[ "${2:-}" == "N" ]]; then
      prompt="[y/N]"
      default=N
    else
      prompt="[y/n]"
      default=
    fi

    # Ask the question (not using "read -p" as it uses stderr not stdout)
    printf '\n'
    printf '%s ' $1 $prompt

    read reply

    # Default?
    if [[ -z "$reply" ]]; then
      reply=${default}
    fi

    # Check if the reply is valid
    case "$reply" in
    Y* | y*) return 0 ;;
    N* | n*) return 1 ;;
    esac

  done
}

#Check if User is Root.
IsRoot() {
    if [[ $EUID = 0 ]]; then
      return 0
      else
      return 1
    fi
}

function checkroot(){
	     printf "\n$a check root user $nc"
	     sleep 1
    if [ IsRoot ]; then
	     printf "\n $b[$v$si$b] root $nc\n"
	     sleep 1
    else
             printf "\n $b[$r$no$b] root $nc"
	     sleep 1
	     printf "\n$r EXITING $nc\n"
	     sleep 1
	     exit
    fi	
}

#Check if Package is installed
CheckForPackage() {
    return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

#Install specified Package
InstallPKG() {
    $PKGMGR install -y $1
    check_exit_status;
}
#Remove specified Package
RemovePKG() {
    $PKGMGR remove -y $1
    check_exit_status;
}

UpdateSoftware() {
    if IsRoot; then
        printf '\nUpdating Software.\nNote: To Update Flatpak software, run this script without root or sudo.\n'
        UpdateApt
        UpdateSnap;
    elif ! CheckForPackage flatpak; then
      UpdateFlatpak;
    else   
      printf '\nSkipping Updates.\n'
    fi
}


#Update and upgrade apt packages repos
UpdateApt () {
    if ask "Would you like to update the apt repositories?" Y; then
        $PKGMGR update;
        check_exit_status
    else
        printf '\nSkipping repository updates.\n'
    fi
    if ask "Would you like to install the apt software updates?" Y; then
        if [ $PKGMGR=nala ]; then
            $PKGMGR upgrade -y;
            check_exit_status
            $PKGMGR autoremove -y;
            check_exit_status
        else
            $PKGMGR dist-upgrade --allow-downgrades -y;
            check_exit_status
            $PKGMGR autoremove -y;
            check_exit_status
            $PKGMGR autoclean -y;
            check_exit_status
        fi
    else
        printf '\nSkipping package upgrades.\n'
    fi
}

#Update Snap packages
UpdateSnap() {
    if ! CheckForPackage snapd; then
        if ask "Would you like to update snap packages?" Y; then
            snap refresh
            check_exit_status
        else
            printf '\nSkipping Snap Update.\n'
        fi
    else
        printf "Snapd is not installed, skipping snap updates.\n"
    fi
}

#Update Flatpak packages
UpdateFlatpak() {
    if ! CheckForPackage flatpak; then
        if ask "Would you like to update the Flatpak Packages?" Y; then
            flatpak update
            check_exit_status
        else
            printf '\nSkipping Flatpak Update.\n'
        fi
    else
        printf "Flatpak is not installed, skipping Flatpak updates.\n"
    fi
}

#SetupZSH
SetupZSH() {
    if IsRoot; then
        if CheckForPackage zsh; then
            if ask "Would you like to setup ZSH?" Y; then
                $PKGMGR install -y zsh zsh-syntax-highlighting zsh-autosuggestions
                check_exit_status
                DefinedSHELL=/bin/zsh
                usermod --shell $DefinedSHELL root
                CopyZshrcFile
            else
                printf '\nSkipping ZSH Setup.\n'
            fi
        fi
    fi
    if ask "Would you like to set ZSH as your shell?" Y; then
        DefinedSHELL=/bin/zsh
        chsh -s $DefinedSHELL
        CopyZshrcFile
    else
        printf '\nSkipping zsh Setup.\n'
    fi
}

#CopyZshrcFile
CopyZshrcFile() {
    if IsRoot; then
        if ask "Would you like to copy the zshrc file included with this script to your home directory?" Y; then
            rcfile=./rcfiles/zshrc
            if [[ -f "$rcfile" ]]; then
                cp ./rcfiles/zshrc /root/.zshrc
                cp ./rcfiles/zshrc /etc/skel/.zshrc
            else
                printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."
            fi
        else
            printf "\nSkipping zshrc file.\n"
        fi
    elif ! CheckForPackage zsh; then
        if ask "Would you like to copy the zshrc file included with this script to your home directory?" Y; then
            rcfile=./rcfiles/zshrc
            if [[ -f "$rcfile" ]]; then
                cp ./rcfiles/zshrc /home/$USER/.zshrc
            else
                printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."                
            fi
        else
            printf "\nSkipping zshrc file.\n"
        fi
    fi
}

function banner (){
        echo ""
        echo -e "$b ┌═════════════════════════════════════════════════════════════════════┐"
        echo -e "$b ║$v ·▄▄▄▄  ▄▄▄ .▄▄▄▄· ▪   ▄▄▄·  ▐ ▄ ▄▄▄▄▄            ▄▄▌  ▄ •▄ ▪  ▄▄▄▄▄ $b║"
        echo -e "$b ║$v ██▪ ██ ▀▄.▀·▐█ ▀█▪██ ▐█ ▀█ •█▌▐█•██  ▪     ▪     ██•  █▌▄▌▪██ •██   $b║"
        echo -e "$b ║$v ▐█· ▐█▌▐▀▀▪▄▐█▀▀█▄▐█·▄█▀▀█ ▐█▐▐▌ ▐█.▪ ▄█▀▄  ▄█▀▄ ██▪  ▐▀▀▄·▐█· ▐█.▪ $b║"
        echo -e "$b ║$v ██. ██ ▐█▄▄▌██▄▪▐█▐█▌▐█ ▪▐▌██▐█▌ ▐█▌·▐█▌.▐▌▐█▌.▐▌▐█▌▐▌▐█.█▌▐█▌ ▐█▌· $b║"
        echo -e "$b ║$v ▀▀▀▀▀•  ▀▀▀ ·▀▀▀▀ ▀▀▀ ▀  ▀ ▀▀ █▪ ▀▀▀  ▀█▄▀▪ ▀█▄▀▪.▀▀▀ ·▀  ▀▀▀▀ ▀▀▀  $b║"
        echo -e "$b ║$r                  Author  $b: $a d4t4s3c                                 $b║"
        echo -e "$b ║$r                  Email   $b: $a d4t4s3c@protonmail.com                  $b║"
        echo -e "$b ║$r                  GitHub  $b: $a www.github.com/d4t4s3c                  $b║"
        echo -e "$b └═════════════════════════════════════════════════════════════════════┘$nc"
        echo ""
        sleep 1
}

#Functions ---> ^ ^ ^ ^ ^ ^ ^ ^ <-----
#Script ------> V V V V V V V V <----- 

tput civis
clear
checkroot
clear
banner
APTAPPS=
PKGMGR=apt
DefinedSHELL=/bin/bash
if IsRoot; then
    echo 'export LC_ALL=C.UTF-8' >> /etc/profile
    echo 'export LANG=C.UTF-8' >> /etc/profile
fi
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

#Setup Nala
if ! CheckForPackage nala; then
    PKGMGR=nala
elif ! CheckForPackage nala-legacy; then
    PKGMGR=nala
else
    if IsRoot; then
        printf "Nala is a front-end for libapt-pkg with a variety of features such as parallel downloads, clear display of what is happening, and the ability to fetch faster mirrors."
        if ask "Would you like to install Nala?" N; then
            SetupNala
        else
            printf '\nSkipping Nala Setup.\n'
        fi
    else
        PKGMGR=apt
    fi
fi

#update system
UpdateSoftware

if IsRoot; then
    if CheckForPackage vim; then
        if ask "Would you like to install VIM?" Y; then
            InstallPKG vim
        else
            printf '\nSkipping VIM install.\n'
        fi
    fi
fi

if IsRoot; then
    if CheckForPackage sudo; then 
        if ask "Would you like to install sudo?" Y; then
            InstallPKG sudo
        else
            printf '\nSkipping sudo setup.\n'
        fi
    fi
fi

printf "\n$a Installing tools in Debian $nc\n"
sleep 1
printf "\n  [$v$si$b] nerd fonts\n"
sleep 1
cd /usr/local/share/fonts
mv /root/DebianToolkit/box/Hack.zip .
unzip Hack.zip
rm -rf Hack.zip
cd /root/DebianToolkit/
printf "\n  [$v$si$b] hash-id\n"
sleep 1
cd box
git clone https://github.com/blackploit/hash-identifier.git
cd hash-identifier
chmod +x hash-id.py
cd ..
cd ..
printf "\n  [$v$si$b] exploitdb\n"
exploitdb
exploitdb-bin-sploits
exploitdb-papers
git clone https://github.com/offensive-security/exploitdb.git /opt/exploitdb
sed 's|path_array+=(.*)|path_array+=("/opt/exploitdb")|g' /opt/exploitdb/.searchsploit_rc > ~/.searchsploit_rc
ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit
echo ""     
echo -e "  [$v$si$b] metasploit\n"
sleep 1
wget https://downloads.metasploit.com/data/releases/metasploit-latest-linux-x64-installer.run
chmod +x metasploit-latest-linux-x64-installer.run
xterm -hold -e "./metasploit-latest-linux-x64-installer.run" &
cd ..
printf "\n  [$v$si$b] wordlist rockyou\n"
sleep 1
cd wordlist
wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
cd ..
echo ""             
echo -e "  [$v$si$b] wine\n"
sleep 1
InstallPKG wine
dpkg --add-architecture i386 && $PKGMGR install -y wine32
$PKGMGR install -y wine32
echo ""                      
echo -e "  [$v$si$b] angry ip scanner\n"
sleep 1
cd box
dpkg -i ipscan_3.6.2_amd64.deb
cd ..
printf "\n  [$v$si$b] lsd\n"
sleep 1
cd box
dpkg -i lsd_0.14.0_amd64.deb
cd ..
tput cnorm
exit
