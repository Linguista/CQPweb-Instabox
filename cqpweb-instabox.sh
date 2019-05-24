#!/bin/bash

SCRIPTNAME="cqpweb-instabox.sh"
# AUTHOR:   Scott Sadowsky
# WEBSITE:  www.sadowsky.cl
# DATE:     2019-05-23
# VERSION:  61
# LICENSE:  GNU GPL v3

# DESCRIPTION: This script takes a bare-bones install of Ubuntu 18.04 LTS and sets up Open Corpus
#              Workbench (OCWB) and CQPweb on it. It can also, optionally, install software and
#              configure the system for use as a headless server on bare metal, a headless server
#              in a virtual machine or a desktop with GUI for linguistic work.
#
#              It has been tested on Ubuntu 18.04 Live Server (the default download, aimed at cloud-
#              based servers), Ubuntu 18.04 Alternative Server (the traditional server), Ubuntu
#              18.04 Desktop, and Lubuntu 18.04 Desktop in virtual machines, and on Ubuntu Live Server
#              and Alternative Server on bare metal.
#
#              While I've made every effort to make it work properly, it comes with no guarantees and
#              no warranties. Bug reports are most welcome!

# CHANGE LOG:
#
# v61
# - Added: CQPweb:          Installation of php-json module.
#                           Upload of favicon.ico.
# - Added: Server Software: Installation of 'ripgrep' and 'fd'.
# - Added: Bash config:     Aliases for viewing various logs.
#
# v60
# - Initial release.
#
# v59 and below
# - Pre-release development.

# TODO:
# - Properly configure PHP mail server. As it stands, it fails to send e-mails. Can it be made to use Postfix?



################################################################################
# SCRIPT CONFIGURATION
# 0 disables, 1 enables, 2 (or anything else) disables and can mean what you want (e.g. "already run")
################################################################################

# SYSTEM CONFIGURATION
     UPGRADEOS=1    # Upgrade the OS and all its software packages to the latest versions.
   CONFIGSHELL=1    # Change default shell from dash to bash. Prevents certain errors.
    CONFIGBASH=1    # Configure .bashrc with some useful things.
      CONFIGTZ=1    # Set up time zone.
 CONFIGCONSOLE=1    # Configure the console's encoding, fonts, etc.
CONFIGKEYBOARD=1    # Configure the console's keyboard
CONFIGUBUCLOUD=0    # UBUNTU LIVE SERVER 18.04 ONLY: Remove certain cloud-specific components.
    CONFIGHOST=0    # UBUNTU LIVE SERVER 18.04 ONLY: Configure host information to fix bug.

# SSH CONFIGURATION
SSHGENNEWKEYS=1     # Generate new SSH keys and moduli. The latter will take around an hour.
     SSHPWDSW=1     # Install and configure SSH WITH PASSWORD ACCESS on the server, to allow remote administration.
# WARNING: Do not run SSHPWDSW and SSHKEYSW together! You must copy your SSH public key to the server in between!
     SSHKEYSW=0     # Reconfigure the SSH server for access using a PUBLIC KEY instead of a PASSWORD. A true MUST for security!
                    #    Do this only AFTER installing the SSH server with password access and uploading your pubic key to the server!

# MAIN SOFTWARE SETS
NECESSARYSW=1       # Install software necessary for the server to work.
   USEFULSW=1       # Install software considered useful (though optional).
   SERVERSW=1       # Install server software (monitoring, security and such).

# CWB+CQPWEB+CORPORA
     SHORTSWDIR="software"                  # The directory in $HOME in which to download/install most software.
COMMONCQPWEBDIR="/usr/local/share/cqpweb"   # Common base dir for CQPweb. No trailing slash, please!
  CQPCWBRELEASE=0                           # Install a specific SubVersion release of CWB and CQPweb. "0" downloads latest version.
    NUKECORPORA=0                           # Delete ALL installed corpora. Not normally needed!

# CWB
CWB=1                    # Install CORPUS WORKBENCH (CWB)
  CWBVER="latest"        # Version of CWB to install: 'latest' or 'stable' (WARNING: Currently, only 'latest' is supported).
  CWBPLATFORM="linux-64" # Platform to compile CWPweb for. OPTIONS: cygwin, darwin, darwin-64, darwin-brew, darwin-port-core2,
                         #   darwin-universal, linux, linux-64, linux-opteron, mingw-cross, mingw-native, solaris, unix
  CWBSITE="standard"     # Location for binary installation. 'standard'=/usr/local tree; 'beta-install'=/usr/local/cwb-<VERSION>.
  CWBNUKEOLD=0           # Delete previously downloaded CWB files before downloading and installing again? Not normally needed!

# CQPWEB
CQPWEBSW=1                  # Install CQPWEB SERVER.
ADMINUSER="YOUR_INFO_HERE"  # CQPweb administrator usernames. Separate multiple entries with | .
  DBUSER="cqpweb"           # Username for MYSQL database and webuser
  DBPWD="cqpweb"            # Password for MYSQL database and webuser
  CQPMAKENEWDB=1            # Delete existing database and make a new one? (NECESSARY for new installs; normally undesirable otherwise).
  CQPWEBNUKEOLD=0           # Delete previously downloaded CQPweb files before downloading and installing again? Not normally needed!
  FAVICONUPLD=1             # Upload favicon.ico to root of website?
   FAVICONURL="YOUR_INFO_HERE" # Source URL of favicon.ico.

# CORPORA
CORPDICKENS=1       # Install the Dickens SAMPLE CORPUS. Requires CWB already be installed.

# ADDITIONAL SYSTEM SOFTWARE
    MAILSW=1        # Install and configure a mail server.
SECURITYSW=1        # Install security software. Highly recommended for server install.
     UFWSW=1        # Install and configure Universal FireWall (UFW). Important for security!
     UPSSW=0        # Install and configure software for APC BackUPS Pro 900 UPS (051d:0002)
FAIL2BANSW=0        # Install and configure fail2ban. Important for security! But install this last, after you've confirmed everything works.
WHITELISTEDIPS="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16" # IP addresses to whitelist (never ban) in fail2ban. Separate with space.

# ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
     FREELINGSW=0           # Install FreeLing tagger.
       FREELINGESCLMODS=0   # Modify FreeLing's Chilean Spanish install.
       FREELINGNUKEOLD=0    # Delete all downloaded FreeLing files before installing again.
PRAATHEADLESSSW=0           # Install headless Praat phonetic analysis software.
     VISIDATASW=0           # Install Visidata, an amazing TUI tool to manipulate and process CSV files.

# ADDITIONAL LINGUISTIC SOFTWARE: OS WITH GUI ONLY
   RSTUDIOSW=0      # Install RStudio.
  RLINGPKGSW=0      # Install R linguistics and GIS packages.
 SPYDERIDESW=0      # Spyder Python IDE.
       NLPSW=0      # Install NLP software from Stefan Evert's Comp CorpLing course.
UCSTOOLKITSW=0      # UCS Toolkit collocations software.
     PRAATSW=0      # Praat phonetic analysis software (GUI version).

################################################################################
# VARIABLES YOU MUST SET
################################################################################

# MAIL SERVER VARIABLES
# This is mostly independent of CQPweb's mail sending facilites - it's used to alert
# to you system issues like hacking attempts (via fail2ban), failing drives, etc.
   SERVERNAME="YOUR_INFO_HERE"    # CQPWEB SERVER'S FULL DOMAIN NAME (e.g. 'www.mydomain.com')
  SERVERALIAS="YOUR_INFO_HERE"    # CQPWEB SERVER'S SHORT DOMAIN NAME (e.g. 'mydomain.com')
ADMINMAILADDR="YOUR_INFO_HERE"    # ADMINISTRATOR'S E-MAIL ADDRESS.
OUTMAILSERVER="YOUR_INFO_HERE"    # OUTGOING MAIL SERVER URL
MAILSERVERURL="YOUR_INFO_HERE"    # GENERAL URL OF MAIL SERVER.
MAILSERVERPWD="YOUR_INFO_HERE"    # PASSWORD FOR E-MAIL SERVER. YOU CAN DELETE THIS
                                                 #   AFTER INSTALLING THE MAIL SERVER, OR YOU CAN LEAVE IT
                                                 #   EMPTY AND BE PROMPTED FOR A PASSWORD DURING INSTALLATION.
PERSONALMAILADDR="YOUR_INFO_HERE"      # YOUR PERSONAL E-MAIL ADDRESS. IF YOU WANT, YOU CAN USE
                                       #   THE SAME ADDRESS AS FOR ADMIN, OR VICE VERSA.

# PORTS
# Comment out a port to disable it and automatically close it with UFW.
# If you add a port other than with these variables, make sure to open it in UFW!
 SMTPPORT=465
#RSYNCPORT=873
#IMAPSPORT=943
 IMAPPORT=993
 POP3PORT=995
  SSHPORT=YOUR_INFO_HERE # CHOOSE A RANDOM HIGH PORT FOR THIS (10000-60000 IS A GOOD RANGE)


################################################################################
# TIP: ENABLE VMWARE SHARED FOLDERS ON HEADLESS UBUNTU SERVER
# Convenient if you're running the server in a VM.
################################################################################
#
# 1. Create shared folder in VMware GUI
# 2. Inside the VM, run...
#    sudo apt install --install-recommends vmfs-tools
#    sudo mkdir /mnt/hgfs
#    echo ".host:/   /mnt/hgfs   fuse.vmhgfs-fuse   defaults,allow_other  0   0" | sudo tee -a /etc/fstab
# 3. Reboot the VM
# 4. Link this script to home folder: sudo ln -s /mnt/hgfs/cqptransfer/cqpweb-install.sh /usr/local/bin/cqpweb-install


####################################
# VARIABLES YOU SHOULD *NOT* MODIFY
####################################
DATE="$(date +'%Y/%m/%d')"                              # Date in YYYY/MM/DD format.
TIME="$(date +'%H:%M:%S')"                              # Time in HH:MM:SS format.
USER="$(whoami)"                                        # Username of person installing software on local system.
USERGROUPS="$(groups ${USER})"                          # The groups that the user belongs to.
LOCALHOSTNAME="$(hostname)"                             # Local system's host name.
OS="$(cat /etc/lsb-release | grep DISTRIB_ID | sed -r 's/DISTRIB_ID=//')" # Distro name
ETHERNET="$(ip link show | grep '[0-9]: e[a-z0-9]*:' | sed -r 's/^.+ (e[a-z0-9]+):.+$/\1/')" # Ethernet adapter. This is NOT infallible!
#ETHERNET=$(ifconfig | grep '^e' | sed -r 's/:.+$//')   # Ethernet adapter (older method). This is NOT infallible!
EXTERNALIP="$(wget -qO - http://checkip.amazonaws.com)" # Server's external IP.
# EXTERNALIP=$(wget -qO - http://wtfismyip.com/text)    # Server's external IP (alternative method).
INTERNALIP="$(ip route get 1.2.3.4 | awk '{print $7}')" # Server's internal IP.
INTERNALIP2="$(ip addr show ${ETHERNET} | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')" # Server's internal IP (Method 2).
SWDIR="${HOME}/${SHORTSWDIR}"                           # Full software installation directory.

# MAKE BASIC REQUIRED DIRECTORIES
mkdir -p "${SWDIR}"


################################################################################
# FUNCTION FOR CHANGING CONFIG FILE VALUES
# https://stackoverflow.com/questions/11245144/replace-whole-line-containing-a-string-using-sed
################################################################################
function configLine {
    local OLD_LINE_PATTERN=$1; shift
    local NEW_LINE=$1; shift
    local FILE=$1
    local NEW=$(echo "${NEW_LINE}" | sed 's/\//\\\//g')
    sudo touch "${FILE}"
    sudo sed -i '/'"${OLD_LINE_PATTERN}"'/{s/.*/'"${NEW}"'/;h};${x;/./{x;q100};x}' "${FILE}"
    if [[ $? -ne 100 ]] && [[ ${NEW_LINE} != '' ]]; then
        echo "${NEW_LINE}" | sudo tee -a "${FILE}"
    fi
}


################################################################################
# SET TEXT FORMATTING CODES
################################################################################
CWHT="$(tput setaf 7)"   # WHITE
CRED="$(tput setaf 1)"   # RED FOR ERROR MESSAGES
CGRN="$(tput setaf 2)"   # GREEN
CORG="$(tput setaf 3)"   # YELLOW-ORANGE
CMBL="$(tput setaf 4)"   # MEDIUM BLUE
CPUR="$(tput setaf 5)"   # DARK PURPLE
CLBL="$(tput setaf 6)"   # LIGHT BLUE

BLD="$(tput bold)"      # BOLD
NBLD="$(tput rmso)"     # NO-BOLD
UL="$(tput smul)"       # UNDERLINE
NUL="$(tput rmul)"      # NO-UNDERLINE
RST="$(tput sgr0)"      # RESET ALL FORMATTING


################################################################################
# SCRIPT USAGE INFO
################################################################################

echo ""
echo "${CLBL}${BLD}==========> WELCOME TO CQPWEB-INSTABOX <==========${RST}"
echo ""
echo "${CWHT}${BLD}            This script takes a fresh Ubuntu 18.04 LTS installation and sets it up with${RST}"
echo "${CWHT}${BLD}            Open Corpus Workbench (CWB), CQPweb and other software.${RST}"
echo ""
echo "${CWHT}${BLD}            You ${CORG}must${CWHT} configure this script before running it, by editing its ${CLBL}SCRIPT${CWHT}${RST}"
echo "${CLBL}${BLD}            CONFIGURATION${CWHT} and ${CLBL}VARIABLES YOU MUST SET${CWHT} sections.${RST}"
echo ""
echo "${CWHT}${BLD}            Note that you ${CORG}cannot${CWHT} run both the ${CLBL}SSH VIA PASSWORD${CWHT} and the ${CLBL}SSH VIA PUBLIC KEY${CWHT}${RST}"
echo "${CWHT}${BLD}            routines in the same pass -- you must copy your public key to the server in between.${RST}"
echo ""

read -r -p "${CORG}${BLD}            Do you want to proceed? (y/n) ${RST}" ANSWER
if [[ "$ANSWER" = [yY] || "$ANSWER" = [yY][eE][sS] ]]; then
    echo "${CGRN}${BLD}==========> Running CQPWEB-INSTABOX...${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Exiting CQPWEB-INSTABOX.${RST}"
    exit
fi


################################################################################
# UDPATE & UPGRADE THE ENTIRE OS INSTALLATION
################################################################################
if [[ "$UPGRADEOS" = 1 ]]; then
    echo ""
    echo "${CLBL}${BLD}==========> UPDATING & UPGRADING the OS...${RST}"

    # UPDATE AND UPGRADE SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y

    # INSTALL SOFTWARE THAT IS REQUIRED FOR EARLY OPERATIONS.
    sudo apt install -y --install-recommends gnupg software-properties-common

    # CLEAN UP
    sudo apt -y autoremove
    sudo apt -y autoclean

    echo "${CGRN}${BLD}==========> UPDATING & UPGRADING the OS completed (or not needed).${RST}"
    echo "${CRED}${BLD}            Rebooting now would not be a bad idea.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping UPDATING & UPGRADING the OS...${RST}"
fi


################################################################################
# CONFIGURE DEFAULT SHELL AS BASH
################################################################################
if [[ "$CONFIGSHELL" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Reconfiguring DEFAULT SHELL...${RST}"
    echo "${CWHT}${BLD}            We will now set the DEFAULT SHELL to 'bash' instead of 'dash'. Please enter your${RST}"
    echo "${CWHT}${BLD}            password if prompted and then answer ${CORG}No${CWHT} to the question that will appear...${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    sudo dpkg-reconfigure dash

    echo "${CGRN}${BLD}==========> DEFAULT SHELL reconfiguration finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping DEFAULT SHELL reconfiguration...${RST}"
fi


################################################################################
# CONFIGURE BASH (~/.bashrc)
################################################################################
if [[ "$CONFIGBASH" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Configuring BASH...${RST}"

    # IF NO BACKUP EXISTS, MAKE ONE
    if ! [[ -f "${HOME}/.bashrc.BAK" ]]; then
        cp "${HOME}/.bashrc" "${HOME}/.bashrc.BAK"
    fi

    # REMOVE ORIGINAL FILE
    rm "${HOME}/.bashrc"

    # WRITE NEW FILE
    tee "${HOME}/.bashrc" <<- EOF >/dev/null 2>&1
	##### Created by ${SCRIPTNAME} on ${DATE}

	# UNALTERED ITEMS FROM ORIGINAL FILE

	# ~/.bashrc: executed by bash(1) for non-login shells.
	# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
	# for examples

	# IF NOT RUNNING INTERACTIVELY, DON'T DO ANYTHING
	case \$- in
	    *i*) ;;
	      *) return;;
	esac

	# IF SET, THE PATTERN "**" USED IN A PATHNAME EXPANSION CONTEXT WILL
	# MATCH ALL FILES AND ZERO OR MORE DIRECTORIES AND SUBDIRECTORIES.
	#shopt -s globstar

	# MAKE LESS MORE FRIENDLY FOR NON-TEXT INPUT FILES, SEE LESSPIPE(1)
	[ -x /usr/bin/lesspipe ] && eval "\$(SHELL=/bin/sh lesspipe)"

	# ENABLE COLOR SUPPORT OF LS
	if [ -x /usr/bin/dircolors ]; then
	    test -r ~/.dircolors && eval "\$(dircolors -b ~/.dircolors)" || eval "\$(dircolors -b)"
	fi

	# COLORED GCC WARNINGS AND ERRORS
	export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

	# LOAD ALIASES FILE IF IT EXISTS
	if [ -f ~/.bash_aliases ]; then
	    . ~/.bash_aliases
	fi

	# enable programmable completion features (you don't need to enable
	# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
	# sources /etc/bash.bashrc).
	if ! shopt -oq posix; then
	  if [ -f /usr/share/bash-completion/bash_completion ]; then
	    . /usr/share/bash-completion/bash_completion
	  elif [ -f /etc/bash_completion ]; then
	    . /etc/bash_completion
	  fi
	fi

	# MISC SETTINGS
	export LESS='FiX'
	export CHEATCOLORS=true

	# SAFETY NETS
	alias rm='rm -I --preserve-root'
	alias chown='chown --preserve-root'
	alias chmod='chmod --preserve-root'
	alias chgrp='chgrp --preserve-root'

	# TERMINAL CONFIGURATION
	HISTCONTROL=ignoredups:ignorespace
	shopt -s histappend
	HISTSIZE=2000
	HISTFILESIZE=5000
	shopt -s checkwinsize

	# COLORIZE MANPAGES
	export LESS_TERMCAP_mb=$'\\E[01;31m'      # begin blinking
	export LESS_TERMCAP_md=$'\\E[01;31m'      # begin bold
	export LESS_TERMCAP_me=$'\\E[0m'          # end mode
	export LESS_TERMCAP_so=$'\\E[01;44;33m'   # begin standout-mode - info box
	export LESS_TERMCAP_se=$'\\E[0m'          # end standout-mode
	export LESS_TERMCAP_us=$'\\E[01;32m'      # begin underline
	export LESS_TERMCAP_ue=$'\\E[0m'          # end underline

	# ALIASES
	alias ...='cd ../../../'
	alias ..='cd ..'
	alias audit='sudo lynis audit system --quick'
	alias cd..='cd ..'
	alias df='df -h'
	alias dm='dmesg -H'
	alias egrep='egrep --color=auto -i'
	alias fgrep='fgrep --color=auto -i'
	alias getip='wget -qO - http://wtfismyip.com/text'
	alias grep='grep --color=auto -i'
	alias j='jobs -l'
	alias l='ls -CF'
	alias la='ls -A'
	alias lc.='ls -d .*'
	alias lc='ls -CF'
	alias ll.='ls -ohF -d .*'
	alias ll='ls -alF'
	alias lla='ls -ohFa'
	alias llg='ls -lhFA'
	alias lnp='sudo netstat -tulpn'
	alias lnpp='sudo nmap -sT -O localhost'
	alias loc='lo | column'
	alias ls='ls --group-directories-first --color=auto -x'
	alias netsrv='sudo netstat -tulpn'
	alias ports='netstat -tulanp'
	alias sagac='sudo apt autoclean'
	alias sagar='sudo apt autoremove'
	alias sagi='sudo apt install'
	alias sagp='sudo apt purge'
	alias sagr='sudo apt remove'
	alias sagu='sudo apt update'
	alias sagug='sudo apt upgrade'
	alias sas='sudo apt search'
	alias sn='sudo nano'
	alias ugr='sudo apt list --upgradable'

	# ALIASES FOR VIEWING LOGFILES
	alias alog='tail -f -n 25 /var/log/auth.log'
	alias apalog='tail -f -n 25 /var/log/apache2/access.log'
	alias apelog='tail -f -n 25 /var/log/apache2/error.log'
	alias flog='tail -f -n 25 /var/log/fail2ban.log'
	alias klog='tail -f -n 25 /var/log/kern.log'
	alias mlog='tail -f /var/log/mail.log'
	alias mylog='tail -f /var/log/mysql/error.log'
	alias slog='tail -f -n 25 /var/log/syslog'
	alias ulog='tail -f -n 15 /var/log/ufw.log'
	alias upslog='tail -f -n 15 /var/log/apcupsd.events'

	# LINGUISTIC THINGS
	alias cqp='cqp -eC'

	######################
	# PROMPT CONFIGURATION
	######################

	# SET VARIABLE IDENTIFYING SSH USERS
	SSH=0
	if [[ -n \$SSH_CLIENT ]]; then
        SSH=1
	fi

	# SET VARIABLE IDENTIFYING THE CHROOT YOU WORK IN (USED IN THE PROMPT BELOW)
	if [ -z "\$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
        debian_chroot=\$(cat /etc/debian_chroot)
	fi

	# SET A FANCY PROMPT (NON-COLOR, UNLESS WE KNOW WE "WANT" COLOR)
	case "\$TERM" in
	    xterm-color) color_prompt=yes;;
	esac

	force_color_prompt=yes

	if [ -n "\$force_color_prompt" ]; then
	    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	        color_prompt=yes
	    else
            color_prompt=
	    fi
	fi

	if [ "\$color_prompt"=yes ]; then
	    # SET USER'S COLOR TO BLUE FOR USERNAME IN PROMPT. IF USER IS ROOT, SET THIS COLOR TO RED.
	    UC="35m"                       # LOCAL user's color for username
	    [ \$SSH -eq "1" ] && UC="35m"   # SSH user's color for username
	    [ \$UID -eq "0" ] && UC="31m"   # root's color for username

	    # SET USER'S TYPED TEXT COLOR TO WHITE. IF USER IS ROOT, SET THIS COLOR TO YELLOW.
	    UCT="37m"                       # user's color for username
	    [ \$UID -eq "0" ] && UCT="33m"  # root's color for username

	    PS1='\[\e[01;\${UC}\]\u\[\e[00;37m\]@\[\e[00;\${UC}\]\h \[\e[01;34m\]{ \[\e[01;34m\]\w \[\e[01;34m\]}\[\e[01;\${UC}\] $ \[\e[01;\${UCT}\]'

	    # PREVIOUS LINE LEAVES TEXT AS BRILLIANT WHITE, AND CONSOLE COLOR
	    # INHERITS THIS. THE FOLLOWING 'TRAP' RESETS THE TEXT COLOR.
	    trap 'echo -ne "\e[0m"' DEBUG
	else
	    PS1='\${debian_chroot:+(\$debian_chroot)}\u@\h:\w\$ '
	fi

	unset color_prompt force_color_prompt

	# IF THIS IS AN XTERM SET THE TITLE TO user@host:dir
	case "\$TERM" in
	xterm*|rxvt*)
	    PS1="\[\e]0;\${debian_chroot:+(\$debian_chroot)}\u@\h: \w\a\]\$PS1"
	    ;;
	*)
	    ;;
	esac

EOF

    # LOAD NEW CONTENTS OF .bashrc SO THEY'RE IMMEDIATELY AVAILABLE
    source "${HOME}/.bashrc"

    echo "${CGRN}${BLD}==========> BASH configuration finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping BASH configuration...${RST}"
fi


################################################################################
# CONFIGURE TIME ZONE
################################################################################
if [[ "$CONFIGTZ" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Configuring the TIME ZONE...${RST}"

    sudo dpkg-reconfigure tzdata

    echo "${CGRN}${BLD}==========> TIME ZONE configuration finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping TIME ZONE configuration...${RST}"
fi


################################################################################
# CONFIGURE CONSOLE
################################################################################
if [[ "$CONFIGCONSOLE" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Configuring the CONSOLE...${RST}"
    echo "${CWHT}${BLD}            We will now configure the CONSOLE (encoding, charset, font, etc). For most Indo-European${RST}"
    echo "${CWHT}${BLD}            languages you will want the ${CORG}Latin 1 and Latin 5${CWHT} character set option...${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    sudo dpkg-reconfigure console-setup

    echo "${CGRN}${BLD}==========> CONSOLE configuration finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping CONSOLE configuration...${RST}"
fi


################################################################################
# CONFIGURE KEYBOARD
################################################################################
if [[ "$CONFIGKEYBOARD" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Configuring the KEYBOARD.${RST}"
    echo ""

    sudo dpkg-reconfigure keyboard-configuration

    echo "${CGRN}${BLD}==========> KEYBOARD configuration finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping KEYBOARD configuration...${RST}"
fi


################################################################################
# CONFIGURE UBUNTU SERVER 18.04 CLOUD SETTINGS
################################################################################
if [[ "$CONFIGUBUCLOUD" = 1 ]]; then
        echo ""
        echo "${CLBL}${BLD}==========> Reconfiguring UBUNTU CLOUD settings...${RST}"

        # RECONFIGURE UBUNTU CLOUD SETTINGS

        # DISABLE CLOUD-INIT
        sudo echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfgg >/dev/null 2>&1

        # REMOVE CLOUD-INIT
        sudo apt update -y              >/dev/null 2>&1
        sudo apt purge -y cloud-init
        sudo apt autoremove -y          >/dev/null 2>&1
        sudo rm -rf /etc/cloud/
        sudo rm -rf /var/lib/cloud/

        echo "${CGRN}${BLD}==========> UBUNTU CLOUD settings reconfigured.${RST}"
        echo ""
    else
        echo "${CORG}${BLD}==========> Skipping UBUNTU CLOUD settings reconfiguration...${RST}"
fi


################################################################################
# CONFIGURE HOSTNAME
################################################################################
if [[ "$CONFIGHOST" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Reconfiguring HOSTNAME...${RST}"

    # IF BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP
    if [[ -f "/etc/hosts.BAK" ]]; then
        # RESTORE BACKUP
        sudo rm /etc/hosts
        sudo cp /etc/hosts.BAK /etc/hosts
    else
        # MAKE BACKUP
        sudo cp /etc/hosts /etc/hosts.BAK
    fi

    # MODIFY THE HOSTS FILE
    echo ""                                    | sudo tee -a /etc/hosts >/dev/null 2>&1
    echo "# Added by ${SCRIPTNAME} on ${DATE}" | sudo tee -a /etc/hosts >/dev/null 2>&1
    echo "127.0.0.1   ${LOCALHOSTNAME}"        | sudo tee -a /etc/hosts

    echo "${CGRN}${BLD}==========> HOSTNAME reconfiguration finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping HOSTNAME reconfiguration...${RST}"
fi


########################################
# GENERATE NEW SSH KEYS AND MODULI
########################################
if [[ "$SSHGENNEWKEYS" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Generating STRONG NEW SSH KEYS...${RST}"

    # UPDATE SOFTWARE
    sudo apt update -y
    sudo apt install -y --install-recommends figlet openssh-sftp-server ssh-askpass ssh-audit sshfs landscape-common lolcat toilet toilet-fonts

    # ELIMINATE EXISTING KEYS AND GENERATE STRONG NEW ONES
    echo "${CWHT}${BLD}            Generating strong new keys. This will take a minute!...${RST}"
    echo "${CORG}${BLD}            Respond to any and all questions by hitting ENTER...${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    # MOVE INTO DIRECTORY
    cd /etc/ssh || exit

    # MAKE BACKUP DIRECTORY
    sudo mkdir -p "backups"

    # BACKUP ALL EXISTING KEYS INTO BACKUP DIRECTORY
    for FILE in ssh_host_*key*; do
        sudo cp -- "$FILE" "./backups/${FILE}.BAK"
    done

    # REMOVE EXISTING KEYS
    sudo rm ssh_host_*key*

    # GENERATE NEW KEYS
    sudo ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N "" < /dev/null
    sudo ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N "" < /dev/null
    sudo ssh-keygen -t ed25519 -o -a 100
    sudo ssh-keygen -t rsa -b 4096 -o -a 100

    # RESTORE BACKUP MODULI FILE IF IT EXISTS, ELSE MAKE BACKUP
    if [[ -f /etc/ssh/moduli.BAK ]]; then
        sudo rm /etc/ssh/moduli
        sudo cp /etc/ssh/moduli.BAK /etc/ssh/backup/moduli
    else
        sudo cp /etc/ssh/moduli /etc/ssh/moduli.BAK
    fi

    # REMOVE WEAK MODULI OF LESS THAN 2048 BITS
    sudo awk '$5 >= 2047' /etc/ssh/moduli | sudo tee /etc/ssh/moduli.tmp
    sudo mv /etc/ssh/moduli.tmp /etc/ssh/moduli
    MODULICOUNT=$(wc -l "/etc/ssh/moduli" | sed -r 's/ .+$//')

    echo ""
    echo "${CORG}${BLD}            You now have ${MODULICOUNT} moduli of 2048 bits or better.${RST}"
    echo ""
    echo "${CGRN}${BLD}==========> STRONG NEW SSH KEY generation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping STRONG NEW SSH KEY generation...${RST}"
fi


########################################
# INSTALL AND CONFIGURE SSH ACCESS VIA *PASSWORD*
########################################
if [[ "$SSHPWDSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Configuring SSH VIA PASSWORD ==========${RST}"

    # PROVIDE STERN WARNING AND ASK FOR CONFIRMATION.
    echo "${CWHT}${BLD}            This will set up the SSHD service on your server and allow login with a ${BLD}${CRED}PASSWORD${BLD}${CWHT}.${RST}"
    echo "${CWHT}${BLD}            This is an ${CRED}${BLD}awful security practice${RST}${CWHT}${BLD}! It ${UL}will${NUL} lead to you being ${CRED}${BLD}PWNED${CWHT}${BLD}!${RST}"
    echo ""
    echo "${CWHT}${BLD}            The sole purpose of doing this is to allow you to immediately connect to the server,${RST}"
    echo "${CWHT}${BLD}            copy over your SSH public key from your own computer, and then reconfigure the server to${RST}"
    echo "${CWHT}${BLD}            allow access ${CGRN}only with the public key${CWHT}.${RST}"
    echo ""
    read -r -p "            ${CORG}${BLD}Do you understand you need to switch to public key authentication ASAP? (y/n) ${RST}" ANSWER

    if [[ "$ANSWER" = [yY] || "$ANSWER" = [yY][eE][sS] ]]; then

        # RESTORE BACKUP SSH_CONFIG IF IT EXISTS, ELSE MAKE BACKUP
        if [[ -f /etc/ssh/ssh_config.BAK ]]; then
            sudo rm /etc/ssh/ssh_config
            sudo cp /etc/ssh/ssh_config.BAK /etc/ssh/ssh_config
            sudo chmod ug+rw /etc/ssh/ssh_config
        else
            sudo cp /etc/ssh/ssh_config /etc/ssh/ssh_config.BAK
        fi

        # RESTORE BACKUP SSHD_CONFIG IF IT EXISTS, ELSE MAKE BACKUP
        if [[ -f /etc/ssh/sshd_config.BAK ]]; then
            sudo rm /etc/ssh/sshd_config
            sudo cp /etc/ssh/sshd_config.BAK /etc/ssh/sshd_config
            sudo chmod ug+rw /etc/ssh/sshd_config
        else
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BAK
        fi

        # RECONFIGURE SSHD_CONFIG FILE
        # Much taken from here: https://stribika.github.io/2015/01/04/secure-secure-shell.html
        configLine "^[# ]*AllowTcpForwarding.*$"              "AllowTcpForwarding yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*AllowUsers.*$"                      "AllowUsers ${USER}" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*AuthorizedKeysFile.*$"              "AuthorizedKeysFile %h/.ssh/authorized_keys" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ChallengeResponseAuthentication.*$" "ChallengeResponseAuthentication no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Ciphers.*$"                         "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ClientAliveCountMax.*$"             "ClientAliveCountMax 3" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ClientAliveInterval.*$"             "ClientAliveInterval 900" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Compression.*$"                     "Compression DELAYED" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*DenyGroups.*$"                      "DenyGroups root" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*DenyUsers.*$"                       "DenyUsers root" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*HostbasedAuthentication.*$"         "HostbasedAuthentication no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*IgnoreRhosts.*$"                    "IgnoreRhosts yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*KexAlgorithms.*$"                   "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*LogLevel.*$"                        "LogLevel VERBOSE" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*LoginGraceTime.*$"                  "LoginGraceTime 20" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*MaxAuthTries.*$"                    "MaxAuthTries 5" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PasswordAuthentication.*$"          "PasswordAuthentication yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PermitEmptyPasswords.*$"            "PermitEmptyPasswords no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PermitRootLogin.*$"                 "PermitRootLogin no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Port [0-9]*$"                       "Port ${SSHPORT}" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PrintLastLog.*$"                    "PrintLastLog yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PrintMotd.*$"                       "PrintMotd yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Protocol.*$"                        "Protocol 2" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*StrictModes.*$"                     "StrictModes yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*TCPKeepAlive.*$"                    "TCPKeepAlive yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*UsePAM.*$"                          "UsePAM no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*X11Forwarding.*$"                   "X11Forwarding no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Protocol.*$"                        "Protocol 2" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*MACs.*$"                            "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" /etc/ssh/sshd_config >/dev/null 2>&1
        # DON'T SORT THESE NEXT THREE ENTRIES
        configLine "^[# ]*HostKey.*$"                         "" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*HostKey \/etc\/ssh\/ssh_host_ed25519.*$" "HostKey /etc/ssh/ssh_host_ed25519_key" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*HostKey \/etc\/ssh\/ssh_host_rsa.*$" "HostKey /etc/ssh/ssh_host_rsa_key" /etc/ssh/sshd_config >/dev/null 2>&1

        # RECONFIGURE SSH_CONFIG FILE
        configLine "^[# ]*KexAlgorithms.*$"                   "    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" /etc/ssh/ssh_config >/dev/null 2>&1
        configLine "^[# ]*ChallengeResponseAuthentication.*$" "    ChallengeResponseAuthentication no" /etc/ssh/ssh_config >/dev/null 2>&1
        configLine "^[# ]*Ciphers.*$"                         "    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" /etc/ssh/ssh_config        >/dev/null 2>&1
        configLine "^[# ]*MACs.*$"                            "    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" /etc/ssh/ssh_config  >/dev/null 2>&1
        configLine "^[# ]*UseRoaming.*$"                      "    UseRoaming no" /etc/ssh/ssh_config >/dev/null 2>&1

        # RESTORE BACKUP OF /etc/profile IF IT EXISTS, ELSE MAKE A BACKUP
        if [[ -f /etc/profile.BAK ]]; then
            sudo rm /etc/profile
            sudo cp /etc/profile.BAK /etc/profile
        else
            sudo cp /etc/profile /etc/profile.BAK
        fi

        # ADD MESSAGE TO /ETC/PROFILE
        sudo tee -a /etc/profile <<- EOF >/dev/null 2>&1
		# LOGIN MESSAGE
		BOLDWHITE='\033[1;37m'
		NC='\033[0m'
		MYUSER=\$(whoami)
		MYHOST=\$(hostname)
		MYIP=\$(wget -qO - http://wtfismyip.com/text)
		toilet -f ivrit -t -F border:crop \$MYHOST | lolcat -p 1
		landscape-sysinfo
		echo ""
		echo -e "You are \${BOLDWHITE}\$MYUSER@\$MYHOST\${NC} on \${BOLDWHITE}\$MYIP\${NC}."
		echo ""

EOF

        # RESTART SSH SERVICE
        sudo systemctl restart ssh

        # GIVE USER INFORMATION NEEDED FOR SSH VIA PASSWORD
        echo "${CGRN}${BLD}==========> SSH ACCESS WITH PASSWORD configuration finished.${RST}"
        echo "${CWHT}${BLD}            You can now access this server by SSH as ${CORG}${USER}${CWHT} using your password on ${CORG}port ${SSHPORT}${CWHT}.${RST}"
        echo "${CWHT}${BLD}            My best guesses as to the exact commands you need to connect are the following:${RST}"
        echo "${CORG}${BLD}               ssh ${USER}@${INTERNALIP} -p ${SSHPORT} ${CWHT}(local network)${RST}"
        echo "${CORG}${BLD}               ssh ${USER}@${EXTERNALIP} -p ${SSHPORT} ${CWHT}(remote connection)${RST}"
        echo "${CWHT}${BLD}            Remember to configure your router to forward port ${SSHPORT} to the server's local IP address ${RST}"
        echo "${CWHT}${BLD}            (probably ${CORG}${INTERNALIP}${CWHT}). Note that root access and empty passwords have been disabled.${RST}"
        echo ""
        echo "${CRED}${BLD}            Your server is now easy to hack! To fix this, switch to Public Key Encryption and disable passwords: ${RST}"
        echo "${CWHT}${BLD}            1. Go to your ${CLBL}personal computer${CWHT} and generate SSH keys if you don't have any.${RST}"
        echo "${CWHT}${BLD}            2. Send your public key to the server: ${CORG}ssh-copy-id -p ${SSHPORT} ${USER}@${INTERNALIP}${CWHT}.${RST}"
        echo "${CWHT}${BLD}            3. Run this script on the server with ${CORG}SSHPWDSW=0${CWHT} and ${CORG}SSHKEYSW=1${CWHT}.${RST}"
        echo "${CWHT}${BLD}            4. Test that it works: From your ${CLBL}personal computer${CWHT}, run: ${CORG}ssh ${USER}@${EXTERNALIP} -p ${SSHPORT} -i ~/.ssh/id_rsa${CWHT}.${RST}"
        echo "${CWHT}${BLD}               This should log you in without a password being requested.${RST}"
        echo ""

        # GET USER CONFIRMATION TO CONTINUE
        read -r -p "${CORG}${BLD}            Press any key to continue (or wait 20 seconds)... ${RST}" -n 1 -t 20 -s
        echo ""

        if [[ "${SSHKEYSW}" = 1 ]]; then
            echo "${CRED}${BLD}            DANGER! You ${UL}MUST NOT${NUL} run the SSH ACCESS VIA PUBLIC KEY routine without first copying your public key to the${RST}"
            echo "${CRED}${BLD}            server, as detailed in step 2, above -- otherwise you will lock yourself out of your server!${RST}"
            echo "${CRED}${BLD}            You have set ${CORG}SSHKEYSW=1${CRED}, which would do just this, so the script will exit now for your protection.${RST}"
            echo ""

            # QUIT THE SCRIPT HERE TO PROTECT THE USER
            exit
        fi

        echo "${CGRN}${BLD}==========> SSH ACCESS WITH PASSWORD configuration finished.${RST}"
        echo ""
    else
        echo ""
        echo "${CORG}${BLD}==========> Skipping SSH ACCESS WITH PASSWORD configuration...${RST}"
    fi
fi


########################################
# INSTALL AND CONFIGURE SSH ACCESS VIA *PUBLIC KEY*
########################################
if [[ "$SSHKEYSW" = 1 ]]; then

    echo ""
    echo "${CRED}${BLD}==========> Configuring SSH VIA PUBLIC KEY ==========${RST}"

    # RECONFIGURE SSHD_CONFIG FILE
    configLine "^[# ]*PubkeyAuthentication.*$"                "PubkeyAuthentication yes" /etc/ssh/sshd_config
    configLine "^[# ]*PasswordAuthentication.*$"              "PasswordAuthentication no" /etc/ssh/sshd_config

    # RECONFIGURE SSH_CONFIG FILE
    configLine "^[# ]*PasswordAuthentication.*$"          "    PasswordAuthentication no" /etc/ssh/ssh_config
    configLine "^[# ]*ChallengeResponseAuthentication.*$" "    ChallengeResponseAuthentication no" /etc/ssh/ssh_config
    configLine "^[# ]*PubkeyAuthentication.*$"            "    PubkeyAuthentication yes" /etc/ssh/ssh_config
    configLine "^[# ]*HostKeyAlgorithms.*$"               "    HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa" /etc/ssh/ssh_config

    # RESTART SSH SERVICE
    sudo systemctl restart ssh

    # GIVE USER INFORMATION NEEDED FOR SSH VIA PUBLIC KEY
    echo "${CGRN}${BLD}==========> SSH VIA PUBLIC KEY configuration finished.${RST}"
    echo "${CWHT}${BLD}            You can now access this server by SSH with no password on ${CLBL}port ${SSHPORT}${CWHT}. My best ${RST}"
    echo "${CWHT}${BLD}            guesses as to the exact commands you need to connect are the following:${RST}"
    echo "${CORG}${BLD}               ssh ${USER}@${INTERNALIP} -p ${SSHPORT} -i ~/.ssh/id_rsa ${CWHT}(local network)${RST}"
    echo "${CORG}${BLD}               ssh ${USER}@${EXTERNALIP} -p ${SSHPORT} -i ~/.ssh/id_rsa ${CWHT}(remote connection)${RST}"
    echo ""
    echo "${CWHT}${BLD}            If this throws errors about permissions, run the following commands ${CLBL}on your personal computer${CWHT}:${RST}"
    echo "${CORG}${BLD}               chmod 0700 ~/.ssh${RST}"
    echo "${CORG}${BLD}               chmod 0600 ~/.ssh/id_rsa${RST}"
    echo "${CORG}${BLD}               chmod 0600 ~/.ssh/id_rsa.pub${RST}"
    echo "${CORG}${BLD}               chmod 0644 ~/.ssh/authorized_keys${RST}"
    echo ""
    echo "${CWHT}${BLD}            For maximum convenience, add the following to ${CORG}~/.ssh/config${CWHT} ${CLBL}on your personal computer${CWHT}:${RST}"
    echo "${CORG}${BLD}               Host ${LOCALHOSTNAME}${RST}"
    echo "${CORG}${BLD}                   User ${USER}${RST}"
    echo "${CORG}${BLD}                   HostName ${EXTERNALIP}${RST}"
    echo "${CORG}${BLD}                   Port ${SSHPORT}${RST}"
    echo "${CORG}${BLD}                   IdentityFile ~/.ssh/id_rsa${RST}"
    echo "${CWHT}${BLD}            Once you've done this, you can connect with nothing more than ${CORG}ssh ${LOCALHOSTNAME}${CWHT}!${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds), or press ${CWHT}CTRL+C${CORG} to exit the script... ${RST}" -n 1 -t 10 -s
    echo ""
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping SSH VIA PUBLIC KEY configuration...${RST}"
fi


########################################
# INSTALL NECESSARY SOFTWARE
########################################
if [[ "$NECESSARYSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing NECESSARY SOFTWARE...${RST}"

    ####################
    # ADD MOST UP-TO-DATE R REPOSITORY IF IT'S NOT ALREADY INSTALLED
    ####################

    # ADD CRAN35 KEY
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

    # ADD CRAN35 REPOSITORY
    if ! grep -q "^deb .*cran35" /etc/apt/sources.list /etc/apt/sources.list.d/* 2> /dev/null; then
        sudo apt-add-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu/ bionic-cran35/'
    else
        echo "${CWHT}${BLD}            The cran35 respository is already installed.${RST}"
        echo ""
    fi

    # UPDATE AND INSTALL SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends aria2 autoconf automake build-essential curl dos2unix gcc git linux-headers-generic locales-all make members mercurial openssh-server openssl pkg-config recode subversion unicode wget

    echo "${CGRN}${BLD}==========> NECESSARY SOFTWARE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping NECESSARY SOFTWARE installation...${RST}"
fi


########################################
# INSTALL USEFUL SOFTWARE
########################################
if [[ "$USEFULSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing USEFUL SOFTWARE...${RST}"

    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends bzip2 exfat-fuse exfat-utils lbzip2 mc moreutils most neofetch p7zip p7zip-full p7zip-rar pbzip2 python3-pip rename unrar unzip w3m zip

    echo "${CGRN}${BLD}==========> USEFUL SOFTWARE installation finished).${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping USEFUL SOFTWARE installation...${RST}"
fi


########################################
# INSTALL SERVER SOFTWARE
########################################
if [[ "$SERVERSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing SERVER SOFTWARE...${RST}"
    echo "${CRED}${BLD}            If you are prompted to configure a mail server, just hit ENTER as much as necessary.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    # INSTALL MAIN DISTRO SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends acct apachetop apt-listchanges apticron byobu ccze cpulimit discus fancontrol figlet hddtemp htop hwinfo iftop iotop iptraf iptstate iselect lm-sensors lolcat mytop net-tools nethogs nload nmap nmon powertop rng-tools screen screenie smartmontools speedometer speedtest-cli tmux traceroute unattended-upgrades vnstat w3m whowatch

    # INSTALL MONITORING SOFTWARE
    sudo -H pip3 install --system glances
    sudo -H pip3 install --system s-tui

    # INSTALL RIPGREP (https://github.com/BurntSushi/ripgrep/)
    sudo mkdir -p /tmp/rg               # MAKE TEMP DIR
    sudo chmod -R ugo+rwx /tmp/rg       # CHANGE PERMISSIONS OF TEMP DIR
    cd /tmp/rg || exit                  # MOVE INTO TEMP DIR
    # DOWNLOAD THE GITHUB "LATEST" PAGE, WHICH REDIRECTS TO A PAGE WITH THE LATEST VERSION NUMBER IN ITS URL, AND EXTRACT THAT LINE
    RGLATESTVER=$(aria2c https://github.com/BurntSushi/ripgrep/releases/latest | grep 'Redirecting to')
    RGLATESTVER="$(sed -r 's/^.+\/tag\///' <<< $RGLATESTVER)"   # STRIP EVERYTHING BUT VERSION NUMBER FROM EXTRACTED LINE
    # ASSEMBLE THE DEB FILE NAME
    RGPATH="https://github.com/BurntSushi/ripgrep/releases/download/${RGLATESTVER}"
    RGFILENAME="ripgrep_${RGLATESTVER}_amd64.deb"
    curl -LO "${RGPATH}/${RGFILENAME}"  # DOWNLOAD THE DEB FILE
    sudo dpkg -i "${RGFILENAME}"        # INSTALL THE DEB FILE
    sudo rm -rf /tmp/rg                 # DELETE THE TMP DIRECTORY AND ITS CONTENTS

    # INSTALL FD
    sudo mkdir -p /tmp/fd               # MAKE TEMP DIR
    sudo chmod -R ugo+rwx /tmp/fd       # CHANGE PERMISSIONS OF TEMP DIR
    cd /tmp/fd || exit                  # MOVE INTO TEMP DIR
    # DOWNLOAD THE GITHUB "LATEST" PAGE, WHICH REDIRECTS TO A PAGE WITH THE LATEST VERSION NUMBER IN ITS URL, AND EXTRACT THAT LINE
    FDLATESTVER=$(aria2c https://github.com/sharkdp/fd/releases/latest | grep 'Redirecting to')
    FDLATESTVER="$(sed -r 's/^.+\/tag\/v//' <<< $FDLATESTVER)"   # STRIP EVERYTHING BUT VERSION NUMBER FROM EXTRACTED LINE
    # ASSEMBLE THE DEB FILE NAME
    FDPATH="https://github.com/sharkdp/fd/releases/download/v${FDLATESTVER}"
    FDFILENAME="fd_${FDLATESTVER}_amd64.deb"
    curl -LO "${FDPATH}/${FDFILENAME}"  # DOWNLOAD THE DEB FILE
    sudo dpkg -i "${FDFILENAME}"        # INSTALL THE DEB FILE
    sudo rm -rf /tmp/fd                 # DELETE THE TMP DIRECTORY AND ITS CONTENTS

    echo "${CGRN}${BLD}==========> SERVER SOFTWARE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping SERVER SOFTWARE installation...${RST}"
fi


########################################
# NUKE ALL PREVIOUSLY INSTALLED CORPORA
########################################
if [[ "$NUKECORPORA" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> NUKING PREVIOUSLY-INSTALLED CORPORA...${RST}"
    echo "${CRED}${BLD}            This will delete ${CORG}all${CRED} your installed corpora!${RST}"
    read -r -p "${CWHT}${BLD}            Are you sure you want to proceed? (y/n) ${RST}" ANSWER

    if [[ "$ANSWER" = [yY] || "$ANSWER" = [yY][eE][sS] ]]; then

        sudo rm -rf /usr/local/share/cqpweb

    echo "${CGRN}${BLD}==========> PREVIOUSLY-INSTALLED CORPORA NUKING completed.${RST}"
        echo ""
    else
        echo "${CORG}${BLD}==========> Skipping NUKING OF PREVIOUSLY-INSTALLED CORPORA...${RST}"
    fi
fi

########################################
# INSTALL CORPUS WORKBENCH (CWB)
########################################
if [[ "$CWB" = 1 ]] && [[ "$CWBVER" = "latest" || "$CWBVER" = "stable" ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing the ${CORG}${CWBVER}${CLBL} version of CORPUS WORKBENCH (CWB)...${RST}"

    ##############################
    # COMMON TASKS
    ##############################

    # NUKE OLD CWB DIRECTORIES
    if [[ "$CWBNUKEOLD" = 1 ]]; then
        sudo rm -rf "${SWDIR}/cwb"
        sudo rm -rf "${SWDIR}/cwb-doc"
        sudo rm -rf "${SWDIR}/cwb-perl"
        sudo rm -rf "${CWBPATH}"
    fi

    # INSTALL DEPENDENCIES
    echo ""
    echo "${CLBL}==========> Installing dependencies...${RST}"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends autoconf bison flex gcc make pkg-config libc6-dev libncurses5-dev libpcre3-dev libglib2.0-dev libreadline-dev subversion cpanminus

    # INSTALL REQUIRED PERL MODULES
    echo ""
    echo "${CLBL}==========> Installing required Perl modules...${RST}"
    sudo cpanm install HTML::Entities

    ##############################
    # INSTALL *LATEST* VERSION OF CWB
    ##############################
    if [[ "$CWBVER" = "latest" ]]; then

        echo ""
        echo "${CLBL}==========> Downloading CWB, CWB-DOC and CWB-PERL files...${RST}"

        # ADD USER TO WWW-DATA GROUP IF HE ISN'T ALREADY A MEMBER
        if ! [[ "${USERGROUPS}" =~ "www-data" ]]; then
            sudo usermod -G www-data -a "${USER}"
        fi

        # MOVE TO SOFTWARE DIRECTORY
        cd "${SWDIR}" || exit

        #########################
        # CORPUS WORKBENCH (CWB)
        #########################
        if [[ -d "${SWDIR}/cwb" ]]; then
            # CLEAN AND UPDATE IF DIRECTORY ALREADY EXISTS
            svn cleanup cwb
            if [[ "$CQPCWBRELEASE" = 0 ]]; then
                # UPDATE TO LATEST RELEASE
                svn update cwb
            else
                # UPDATE TO SPECIFIC RELEASE
                svn update -r ${CQPCWBRELEASE} cwb
            fi
        else
            # Download everything anew if directory doesn't exist
            mkdir -p "${SWDIR}/cwb"
            if [[ "$CQPCWBRELEASE" = 0 ]]; then
                # DOWNLOAD LATEST RELEASE
                svn checkout http://svn.code.sf.net/p/cwb/code/cwb/trunk cwb
            else
                # DOWNLOAD SPECIFIC RELEASE
                svn checkout -r ${CQPCWBRELEASE} http://svn.code.sf.net/p/cwb/code/cwb/trunk cwb
            fi
        fi

        #########################
        # CWB TUTORIALS AND OTHER DOCUMENTATION
        #########################
        if [[ -d "${SWDIR}/cwb-doc" ]]; then
            # CLEAN AND UPDATE IF DIRECTORY ALREADY EXISTS
            svn cleanup cwb-doc
            if [[ "$CQPCWBRELEASE" = 0 ]]; then
                # UPDATE TO LATEST RELEASE
                svn update cwb-doc
            else
                # UPDATE TO SPECIFIC RELEASE
                svn update -r ${CQPCWBRELEASE} cwb-doc
            fi
        else
            # Download everything anew if directory doesn't exist
            mkdir -p "${SWDIR}/cwb-doc"
            if [[ "$CQPCWBRELEASE" = 0 ]]; then
                # DOWNLOAD LATEST RELEASE
                svn checkout http://svn.code.sf.net/p/cwb/code/doc cwb-doc
            else
                # DOWNLOAD SPECIFIC RELEASE
                svn checkout -r ${CQPCWBRELEASE} http://svn.code.sf.net/p/cwb/code/doc cwb-doc
            fi
        fi

        #########################
        # CQP PERL API (MULTIPLE PACKAGES)
        #########################
        if [[ -d "${SWDIR}/cwb-perl" ]]; then
            # CLEAN AND UPDATE IF DIRECTORY ALREADY EXISTS
            svn cleanup cwb-perl
            if [[ "$CQPCWBRELEASE" = 0 ]]; then
                # UPDATE TO LATEST RELEASE
                svn update cwb-perl
            else
                # UPDATE TO SPECIFIC RELEASE
                svn update -r ${CQPCWBRELEASE} cwb-perl
            fi
        else
            # Download everything anew if directory doesn't exist
            mkdir -p "${SWDIR}/cwb-perl"
            if [[ "$CQPCWBRELEASE" = 0 ]]; then
                # DOWNLOAD LATEST RELEASE
                svn checkout http://svn.code.sf.net/p/cwb/code/perl/trunk cwb-perl
            else
                # DOWNLOAD SPECIFIC RELEASE
                svn checkout -r ${CQPCWBRELEASE} http://svn.code.sf.net/p/cwb/code/perl/trunk cwb-perl
            fi
        fi

        #########################
        # COMPILE CWB PROGRAMS
        #########################
        echo ""
        echo "${CLBL}==========> Compiling CWB program files...${RST}"

        cd "${SWDIR}/cwb" || exit

        # RESTORE BACKUP OF CONFIG.MK IF IT EXISTS, ELSE MAKE A BACKUP.
        if [[ -f "${SWDIR}/cwb/config.mk.BAK" ]]; then
            sudo rm "${SWDIR}/cwb/config.mk"
            sudo cp "${SWDIR}/cwb/config.mk.BAK" "${SWDIR}/cwb/config.mk"
        else
            sudo cp "${SWDIR}/cwb/config.mk" "${SWDIR}/cwb/config.mk.BAK"
        fi

        # MODIFY config.mk. SHOULDN'T BE NECESSARY DUE TO THE ARGS PASSED TO INSTALL SCRIPT, BUT JUST IN CASE.
        configLine "^PLATFORM[ =].*" "PLATFORM=${CWBPLATFORM}"  "${SWDIR}/cwb/config.mk"
        configLine "^SITE[ =].*"     "SITE=${CWBSITE}"          "${SWDIR}/cwb/config.mk"

        # RUN THE CWB INSTALLER SCRIPT
        sudo ./install-scripts/install-linux PLATFORM="${CWBPLATFORM}" SITE="${CWBSITE}"

        # RESTORE BACKUP OF /ETC/PROFILE IF IT EXISTS, ELSE MAKE A BACKUP.
        # An earlier part of the script made a backup called .BAK, so this part uses .BAK2.
        if [[ -f /etc/profile.BAK2 ]]; then
            sudo rm /etc/profile
            sudo cp /etc/profile.BAK2 /etc/profile
        else
            sudo cp /etc/profile /etc/profile.BAK2
        fi

        # ADD PATHS TO ~/.profile
        echo ""                                                         | tee -a "${HOME}/.profile"
        echo "# Added by ${SCRIPTNAME} on ${DATE} at ${TIME}."          | tee -a "${HOME}/.profile"
        echo "export PATH=\"\$PATH:${HOME}/bin\""                       | tee -a "${HOME}/.profile"
        echo "export CORPUS_REGISTRY=${COMMONCQPWEBDIR}/registry"       | tee -a "${HOME}/.profile"

        # IDENTIFY THE /USR/LOCAL/CWB-* DIRECTORY IF IT EXISTS.
        # THIS ONLY SEEMS TO BE CREATED WHEN INSTALLING USING SITE="beta-install".
        # WARNING: This code is fragile! It WILL fail if more than one 'cwb-*' directory exists here.
        CWBDIR=$(find /usr/local/ -type d -name "cwb-*[0-9]")
        if ! [[ "$CWBDIR" = "" ]]; then
            CWBPATH="${CWBDIR}/bin"
            echo "export PATH=\"\$PATH:${CWBPATH}\""  | tee -a "${HOME}/.profile"
        fi

        # LOAD .PROFILE SO NEW PATHS BECOME AVAILABLE IMMEDIATELY
        source "${HOME}/.profile"

        # MAKE CWB REGISTRY AND DATA DIRECTORIES AND CHANGE OWNER AND PERMISSIONS
        sudo mkdir -p "${COMMONCQPWEBDIR}/data"
        sudo mkdir -p "${COMMONCQPWEBDIR}/registry"
        sudo chgrp www-data ${COMMONCQPWEBDIR}/*
        sudo chmod g+rwx,o-rwx,+s ${COMMONCQPWEBDIR}/*

        #########################
        # COMPILE PERL MODULES
        #########################
        echo ""
        echo "${CLBL}==========> Compiling CWB Perl modules...${RST}"
        export PATH=$PATH:${CWBPATH}    # Needed to let Perl modules install without a reboot

        cd "${SWDIR}/cwb-perl" || exit

        cd CWB || exit
        perl Makefile.PL
        make
        make test
        sudo make install

        cd ../CWB-CL || exit
        perl Makefile.PL
        make
        make test
        sudo make install

        cd ../CWB-CQI || exit
        perl Makefile.PL
        make
        make test
        sudo make install

        cd ../CWB-Web || exit
        perl Makefile.PL
        make
        make test
        sudo make install

#         Note that IN THEORY you now have to include the appropriate subdirectories of
#         "~/perl/lib/perl5/" in your Perl search path in order to use the CWB modules.
#         In practice this doesn't seem to be needed.

        echo "${CGRN}${BLD}==========> CORPUS WORKBENCH (CWB) installation finished.${RST}"
        echo       "${CRED}            Kindly reboot before using CWB!${RST}"
        echo ""

    ##############################
    # INSTALL *STABLE* VERSION  OF CWB
    ##############################
    elif [[ "$CWBVER" = "stable" ]]; then

    echo ""
    echo "${CRED}${BLD}==========> Sorry, but the installation of the ${CORG}stable${CRED} version of CORPUS WORKBENCH (CWB) hasn't been implemented yet.${RST}"
    echo ""

    else
        echo "${CRED}${BLD}==========> Could not install CORPUS WORKBENCH (CWB)!${RST}"
        echo "${CORG}${BLD}            Please specify a valid version of Corpus Workbench (CWB) to install (${CRED}latest${RST} / ${CRED}stable${RST}).${RST}"
    fi

else
    # NO INSTALL - USER CHOSE NOT TO INSTALL CQP
    echo "${CORG}${BLD}==========> Skipping CORPUS WORKBENCH (CWB) installation...${RST}"
fi


########################################
# INSTALL CQP WEB
########################################
if [[ "$CQPWEBSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing CQPWEB...${RST}"

    ####################
    # NUKE PREVIOUSLY INSTALLED CQPWEB FILES IF DESIRED
    ####################
    if [[ "$CQPWEBNUKEOLD" = 1 ]]; then
        sudo rm -rf /var/www/html/cqpweb
    fi

    ####################
    # UPDATE AND INSTALL DISTRO SOFTWARE
    ####################
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends apache2 byobu libapache2-mod-php libjpeg-dev libpng-dev libwebp-dev mysql-client mysql-common mysql-server mysql-utilities php-bz2 php-db php-gd php-json php-mbstring php-mysql php-soap php-xml php-zip r-base ttf-ubuntu-font-family

    ####################
    # USER AND GROUP MANAGEMENT &
    # FOLDER OWNERSHIP AND PERMISSIONS
    ####################

    # ADD USER TO WWW-DATA GROUP IF HE ISN'T ALREADY A MEMBER
    if ! [[ "${USERGROUPS}" =~ "www-data" ]]; then
        sudo usermod -G www-data -a "${USER}"
    fi

    # SET CERTAIN FOLDER PERMISSIONS AND GROUPS
    sudo chmod -R g+rws /var/www             # Make new files in these dirs inherit the dir's group permissions
    sudo chmod -R g+rws /usr/lib/cgi-bin     # Make new files in these dirs inherit the dir's group permissions
    sudo chgrp -R www-data /var/www
    sudo chgrp -R www-data /usr/lib/cgi-bin

    ####################
    # CQPWEB
    ####################
    cd /var/www/html || exit

    # DOWNLOAD CQPWEB FILES FROM REPOSITORY
    if [[ -d cqpweb ]]; then
        # CLEAN AND UPDATE IF DIRECTORY ALREADY EXISTS
        sudo svn cleanup cqpweb
        if [[ "$CQPCWBRELEASE" = 0 ]]; then
            # UPDATE TO LATEST RELEASE
            sudo svn update cqpweb
        else
            # UPDATE TO SPECIFIC RELEASE
            sudo svn update -r ${CQPCWBRELEASE} cqpweb
        fi
    else
        # DOWNLOAD EVERYTHING ANEW IF DIRECTORY DOESN'T EXIST
        mkdir -p cqpweb
        if [[ "$CQPCWBRELEASE" = 0 ]]; then
            # DOWNLOAD LATEST RELEASE
            sudo svn checkout http://svn.code.sf.net/p/cwb/code/gui/cqpweb/trunk cqpweb
        else
            # DOWNLOAD SPECIFIC RELEASE
            sudo svn checkout -r ${CQPCWBRELEASE} http://svn.code.sf.net/p/cwb/code/gui/cqpweb/trunk cqpweb
        fi
    fi

    # CHANGE PERMISSIONS ON WEB SERVER DIRECTORY
    sudo chgrp -R www-data /var/www/html/cqpweb
    sudo chmod -R g+rwX /var/www/html/cqpweb

    # CREATE CQPWEB SUBDIRECTORIES AND SET GROUP AND PERMISSIONS
    sudo mkdir -p ${COMMONCQPWEBDIR}/{data,registry,cache,upload}
    sudo chgrp www-data ${COMMONCQPWEBDIR}/*
    sudo chmod g+rwx,o-rwx,+s ${COMMONCQPWEBDIR}/*

    # MAKE UPLOAD DIRECTORY VERY PERMISSIVE
    sudo chmod ugo+rwX,+s "${COMMONCQPWEBDIR}/upload"

    ####################
    # PHP APACHE CONFIGURATION
    ####################

    # IF APACHE PHP.INI BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP.
    if [[ -f /etc/php/7.2/apache2/php.ini.BAK ]]; then
        # RESTORE BACKUP
        sudo rm /etc/php/7.2/apache2/php.ini
        sudo cp /etc/php/7.2/apache2/php.ini.BAK /etc/php/7.2/apache2/php.ini
    else
        # MAKE BACKUP
        sudo cp /etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini.BAK
    fi

    # PHP: MODIFY CONFIG FILE
    configLine "^[; \t]*memory_limit[ =].*"                  "memory_limit = 512M"             /etc/php/7.2/apache2/php.ini
    configLine "^[; \t]*max_execution_time[ =].*"            "max_execution_time = 600"        /etc/php/7.2/apache2/php.ini
    configLine "^[; \t]*upload_max_filesize[ =].*"           "upload_max_filesize = 128M"      /etc/php/7.2/apache2/php.ini
    configLine "^[; \t]*post_max_size[ =].*"                 "post_max_size = 128M"            /etc/php/7.2/apache2/php.ini
    configLine "^[; \t]*mysqli.allow_local_infile[ =].*"     "mysqli.allow_local_infile = On"  /etc/php/7.2/apache2/php.ini
    configLine "^[; \t]*extension=mysqli.*$"                 "extension=mysqli"                /etc/php/7.2/apache2/php.ini
    configLine "^[; \t]*extension=gd2.*$"                    "extension=gd2"                   /etc/php/7.2/apache2/php.ini

    ####################
    # PHP CLI CONFIGURATION
    ####################

    # IF CLI PHP.INI BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP.
    if [[ -f /etc/php/7.2/cli/php.ini.BAK ]]; then
        # RESTORE BACKUP
        sudo rm /etc/php/7.2/cli/php.ini
        sudo cp /etc/php/7.2/cli/php.ini.BAK /etc/php/7.2/cli/php.ini
    else
        # MAKE BACKUP
        sudo cp /etc/php/7.2/cli/php.ini /etc/php/7.2/cli/php.ini.BAK
    fi

    # PHP CLI: MODIFY CONFIG FILE
    configLine "^[; \t]*mysqli.allow_local_infile[ =].*"     "mysqli.allow_local_infile = On"  /etc/php/7.2/cli/php.ini

    ####################
    # APACHE
    ####################

    # IF APACHE CQPWEB.CONF FILE EXISTS, DELETE IT
    if [[ -f /etc/apache2/sites-available/cqpweb.conf ]]; then
        sudo rm /etc/apache2/sites-available/cqpweb.conf
    fi

    # CREATE NEW APACHE CQPWEB.CONF FILE
    sudo touch /etc/apache2/sites-available/cqpweb.conf
    sudo tee /etc/apache2/sites-available/cqpweb.conf <<- EOF >/dev/null 2>&1
	<Directory "/var/www/html/cqpweb">
	    AllowOverride None
	    Require all granted
	    Options FollowSymlinks
	</Directory>

EOF

    # IF 000-DEFAULT-CONFIG.CONF BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP.
    if [[ -f /etc/apache2/sites-available/000-default.conf.BAK ]]; then
        # RESTORE BACKUP
        sudo rm /etc/apache2/sites-available/000-default.conf
        sudo cp /etc/apache2/sites-available/000-default.conf.BAK /etc/apache2/sites-available/000-default.conf
    else
        # MAKE BACKUP
        sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.BAK
    fi

    # MODIFY THE APACHE 000-default-config.conf FILE FOR CQPWEB
    configLine "^[ \\t]*ServerAdmin[ \\t].*"    "\\tServerAdmin ${ADMINMAILADDR}"        /etc/apache2/sites-available/000-default.conf
    configLine "^[ \\t]*DocumentRoot[ \\t]*"    "\\tDocumentRoot /var/www/html/cqpweb"   /etc/apache2/sites-available/000-default.conf
    configLine "^[ \\t#]*LogLevel[ \\t]*"       "\\t#LogLevel info ssl:warn\n\tServerName ${SERVERNAME}\\n\\tServerAlias ${SERVERALIAS}" /etc/apache2/sites-available/000-default.conf

    # UPDATE APACHE CONFIG AND RESTART SERVICE
    sudo a2ensite cqpweb
    sudo systemctl reload apache2
    sudo systemctl restart apache2

    ####################
    # MYSQL DATABASE CONFIGURATION
    ####################

    if [[ "${CQPMAKENEWDB}" = 1 ]]; then

        # GET USER CONFIRMATION ANYWAY
        echo ""
        echo "${CLBL}${BLD}==========> DELETE EXISTING MYSQL DATABASE AND CREATE A NEW ONE?${RST}"
        echo "${CRED}${BLD}            This will delete your MySQL database${CWHT} (if it exists) and then create a new one.${RST}"
        echo "${CWHT}${BLD}            If you're doing a brand-new install of CQPweb, you ${CORG}must${CWHT} do this. Otherwise, you${RST}"
        echo "${CWHT}${BLD}            almost certainly ${CORG}should not${CWHT}, as it will require you to recreate all your corpora.${RST}"
        echo ""
        read -r -p "${CORG}${BLD}            Are you sure you want to proceed? (y/n) ${RST}" ANSWER

        if [[ "$ANSWER" = [yY] || "$ANSWER" = [yY][eE][sS] ]]; then

            # DELETE THE DATABASE AND USER IF IT ALREADY EXISTS.
            sudo mysql -u root -Bse "DROP DATABASE IF EXISTS cqpweb;"
            sudo mysql -u root -Bse "DROP USER IF EXISTS '${DBUSER}'@'%';"
            #sudo mysql -u root -Bse "UNINSTALL PLUGIN validate_password;"  # NOT NEEDED ANYMORE, IT SEEMS.

            # CREATE THE DATABASE
            sudo mysql -u root -Bse "create database cqpweb default charset utf8;"
            sudo mysql -u root -Bse "create user ${DBUSER} identified by '${DBPWD}';"
            sudo mysql -u root -Bse "grant all on cqpweb.* to ${DBUSER};"
            sudo mysql -u root -Bse "grant file on *.* to ${DBUSER};"
            echo "CHOSE TO RECREATE MYSQL DB!"
            echo "${CGRN}==========> MySQL database deleted and recreated.${RST}"
        else
            echo "${CORG}==========> MySQL database NOT deleted...${RST}"
        fi
    fi

    ###### USEFUL MYSQL COMMANDS
    # SHOW DATABASES;                                   # LIST DATABASES
    # SELECT user FROM mysql.user GROUP BY user;        # LIST USERS
    # SHOW TABLES;                                      # LIST TABLES
    # USE <dbname>;                                     # SELECT DATABASE
    # DESCRIBE <dbname>;                                # DESCRIBE DATABASE
    # DROP DATABASE <dbname>;                           # DELETE DATABASE
    # DELETE FROM mysql.user WHERE user = '<user>';     # DELETE USER
    # DROP TABLE <tablename>;                           # DELETE TABLE

    ####################
    # CQPWEB CONFIGURATION
    ####################
    # This section programmatically creates the /var/www/html/cqpweb/lib/config.inc.php
    # config file, avoiding the messiness of an interactive configuration script.

    # BACKUP AND DELETE CQPWEB CONFIG FILE IF IT ALREADY EXISTS
    sudo rm -f /var/www/html/cqpweb/lib/config.inc.php
    sudo touch /var/www/html/cqpweb/lib/config.inc.php

    # IF CONFIG FILE EXISTS, BACK IT UP
    if [[ -f /var/www/html/cqpweb/lib/config.inc.php ]]; then
        # MAKE BACKUP OF CONFIG FILE
        sudo cp /var/www/html/cqpweb/lib/config.inc.php /var/www/html/cqpweb/lib/config.inc.php.BAK
        # DELETE ORIGINAL CONFIG FILE
        sudo rm -f /var/www/html/cqpweb/lib/config.inc.php
    fi

    # CREATE CONFIG.INC.PHP FILE
    sudo tee /var/www/html/cqpweb/lib/config.inc.php <<- EOF >/dev/null 2>&1
	<?php

	/* ---------------------------------------------------------------------- *
	 * MOST OF THESE VALUES ARE THE DEFAULTS GIVEN IN THE CQPWEB ADMIN MANUAL.*
	 * Note that at least as of May 2019, when set to the default value of "" *
	 * (empty), some variables seem not to trigger the use of default values  *
	 * but are treated literally (as an empty string), causing problems (e.g. *
	 * CSS directories and program locations). Therefore, any variables       *
	 * without non-default values are commented out here.                     *
	 * ---------------------------------------------------------------------- */

	/* ---------------------------------------------------------------------- *
	 * ADMINSTRATORS' USERNAMES, SEPARATED BY | WITH NO STRAY WHITESPACE.     *
	 * ---------------------------------------------------------------------- */
	\$superuser_username = '${ADMINUSER}';

	/* ---------------------------------------------------------------------- *
	 * DATABASE CONNECTION CONFIG                                             *
	 * ---------------------------------------------------------------------- */
	\$mysql_webuser = '${DBUSER}';
	\$mysql_webpass = '${DBPWD}';
	\$mysql_schema  = 'cqpweb';
	\$mysql_server  = 'localhost';

	/* ---------------------------------------------------------------------- *
	 * SERVER DIRECTORY PATHS                                                 *
	 * ---------------------------------------------------------------------- */
	\$cqpweb_tempdir   = '${COMMONCQPWEBDIR}/cache';
	\$cqpweb_uploaddir = '${COMMONCQPWEBDIR}/upload';
	\$cwb_datadir      = '${COMMONCQPWEBDIR}/data';
	\$cwb_registry     = '${COMMONCQPWEBDIR}/registry';

	/* ---------------------------------------------------------------------- *
	 * PROGRAM LOCATIONS                                                      *
	 * ---------------------------------------------------------------------- */
	/* \$path_to_cwb                   = "";                                  */
	/* \$path_to_gnu                   = "";                                  */
	/* \$path_to_perl                  = "";                                  */
	/* \$path_to_r                     = "";                                  */
	/* \$perl_extra_directories        = "";                                  */

	/* ---------------------------------------------------------------------- *
	 * MYSQL FEATURES                                                         *
	 * ---------------------------------------------------------------------- */
	\$mysql_big_process_limit       = 5;
	\$mysql_utf8_set_required       = true;
	\$mysql_has_file_access         = false;
	\$mysql_local_infile_disabled   = false;

	/* ---------------------------------------------------------------------- *
	 * MEMORY, DISK CACHE, HARDWARE                                           *
	 * ---------------------------------------------------------------------- */
	\$cwb_max_ram_usage             = 64;
	\$cwb_max_ram_usage_cli         = 1024;
	\$query_cache_size_limit        = 6442450944;
	\$db_cache_size_limit           = 6442450944;
	\$restriction_cache_size_limit  = 6442450944;
	\$freqtable_cache_size_limit    = 6442450944;

	/* ---------------------------------------------------------------------- *
	 * USER INTERFACE                                                         *
	 * ---------------------------------------------------------------------- */
	 \$default_per_page             = 50;
	 \$default_history_per_page     = 100;
	 \$show_match_strategy_switcher = true;
	 \$dist_graph_img_path          = "../css/img/blue.bmp";
	 \$dist_num_files_to_list       = 100;
	 \$uploaded_file_bytes_to_show  = 102400;
	 \$hide_experimental_features   = false;

	/* ---------------------------------------------------------------------- *
	 * LOOK AND FEEL TWEAKS                                                   *
	 * ---------------------------------------------------------------------- */
	 /*\$css_path_for_homepage           = "";                                */
	 /*\$css_path_for_adminpage          = "";                                */
	 /*\$css_path_for_userpage           = "";                                */
	 \$homepage_use_corpus_categories  = false;
	 \$homepage_welcome_message        = "YOUR_INFO_HERE";
	 \$homepage_logo_left              = "";
	 \$homepage_logo_right             = "css/img/ocwb-logo.transparent.gif";
	 \$searchpage_corpus_name_suffix   = " · Powered by CQPweb";

	/* ---------------------------------------------------------------------- *
	 * USER ACCOUNT CREATION                                                  *
	 * ---------------------------------------------------------------------- */
	 \$allow_account_self_registration = true;
	 \$account_create_contact          = "";
	 \$account_create_captcha          = false;
	 \$account_create_one_per_email    = true;
	 \$blowfish_cost                   = 13;
	 \$create_password_function        = "password_insert_internal";

	/* ---------------------------------------------------------------------- *
	 * USER CORPUS SYSTEM                                                     *
	 * ---------------------------------------------------------------------- */
	 \$user_corpora_enabled         = false;

	/* ---------------------------------------------------------------------- *
	 * RSS FEED CONTROL                                                       *
	 * ---------------------------------------------------------------------- */
	 \$rss_feed_available           = false;
	 \$rss_link                     = "${COMMONCQPWEBDIR}";
	 \$rss_feed_title               = "CQPweb System Messages";
	 \$rss_description              = "Messages from the CQPweb server's administrator";

	/* ---------------------------------------------------------------------- *
	 * ERROR REPORTING                                                        *
	 * ---------------------------------------------------------------------- */
	 \$print_debug_messages         = false;
	 \$debug_messages_textonly      = false;
	 \$all_users_see_backtrace      = false;

	/* ---------------------------------------------------------------------- *
	 * MISCELLANEOUS                                                          *
	 * ---------------------------------------------------------------------- */
	 \$cqpweb_switched_off          = false;
	 \$cqpweb_switched_off_extra_message = "Sorry! We're temporarily down for maintenance. Check back soon.";
	/*\$cqpweb_root_url              = "";                                    */
	/*\$cqpweb_no_internet           = "";                                    */
	 \$cqpweb_email_from_address    = "${ADMINMAILADDR}";
	 \$server_admin_email_address   = "${ADMINMAILADDR}";
	 \$cqpweb_cookie_name           = "CQPwebLogonToken";
	 \$cqpweb_cookie_max_persist    = 5184000;
	 \$cqpweb_running_on_windows    = false;

	?>

EOF

    # RUN CQPWEB'S AUTOSETUP TO FINALIZE THE INSTALLATION
    cd /var/www/html/cqpweb/bin/ || exit
    sudo php autosetup.php

    ########################################
    # CREATE MAINTENANCE SCRIPTS ON SERVER
    ########################################
    # This creates several scripts that the user can use to perform maintenance tasks.

    # Make the ~/bin directory in case it doesn't already exist
    sudo mkdir -p "${HOME}/bin"

    ####################
    # CREATE SCRIPT TO UPDATE CWB
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/upd-cwb.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/upd-cwb.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# UPDATE CWB INSTALLATION
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	# IF YOU WANT TO INSTALL A SPECIFIC RELEASE, SET IT IN THE FOLLOWING VARIABLE. 0 = LATEST.
	CQPCWBRELEASE=0

	echo ""
	echo "${CLBL}${BLD}==========> UPDATING CWB...${RST}"

	# FUNCTION FOR CHANGING CONFIG FILE VALUES
	function configLine {
	    local OLD_LINE_PATTERN=\$1; shift
	    local NEW_LINE=\$1; shift
	    local FILE=\$1
	    local NEW=\$(echo "\${NEW_LINE}" | sed 's/\//\\\\\//g')
	    sudo touch "\${FILE}"
	    sudo sed -i '/'"\${OLD_LINE_PATTERN}"'/{s/.*/'"\${NEW}"'/;h};\${x;/./{x;q100};x}' "\${FILE}"
	    if [[ \$? -ne 100 ]] && [[ \${NEW_LINE} != '' ]]; then
	        echo "\${NEW_LINE}" | sudo tee -a "\${FILE}"
	    fi
	}

	# MOVE TO CWB DIRECTORY
	cd ${SWDIR} || exit

	# CLEAN THE INSTALL JUST IN CASE
	svn cleanup cwb

	# UPDATE THE INSTALL
	if [[ "\$CQPCWBRELEASE" -eq 0 ]]; then
	    # UPDATE TO LATEST RELEASE
	    svn update cwb
	else
	    # UPDATE TO SPECIFIC RELEASE
	    svn update -r \${CQPCWBRELEASE} cwb
	fi

	# EDIT THE CONFIG FILE. PROBABLY NOT NECESSARY, BUT JUST IN CASE
	configLine "^PLATFORM[ =].*" "PLATFORM=${CWBPLATFORM}" ${SWDIR}/cwb/config.mk
	configLine "^SITE[ =].*" "SITE=${CWBSITE}" ${SWDIR}/cwb/config.mk

	# MOVE TO CWB DIRECTORY AND EXECUTE INSTALL SCRIPT
	cd "${SWDIR}/cwb" || exit

	sudo ./install-scripts/install-linux PLATFORM=${CWBPLATFORM} SITE=${CWBSITE}

	echo "${CGRN}${BLD}==========> CWB HAS BEEN UPDATED${RST}"
	echo ""

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/upd-cwb.sh"
    sudo chmod ug+rwx "${HOME}/bin/upd-cwb.sh"


    ####################
    # CREATE SCRIPT TO UPDATE CWB-DOC
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/upd-cwbdoc.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/upd-cwbdoc.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# UPDATE CWB-DOC INSTALLATION
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	# IF YOU WANT TO INSTALL A SPECIFIC RELEASE, SET IT IN THE FOLLOWING VARIABLE. 0 = LATEST.
	CQPCWBRELEASE=0

	echo ""
	echo "${CLBL}${BLD}==========> UPDATING CWB-DOC...${RST}"

	# MOVE TO SOFTWARE INSTALL DIRECTORY
	cd ${SWDIR} || exit

	# CLEAN THE INSTALL JUST IN CASE
	svn cleanup cwb-doc

	# UPDATE THE INSTALL
	if [[ "\$CQPCWBRELEASE" -eq 0 ]]; then
	    # UPDATE TO LATEST RELEASE
	    svn update cwb-doc
	else
	    # UPDATE TO SPECIFIC RELEASE
	    svn update -r \${CQPCWBRELEASE} cwb-doc
	fi

	echo "${CGRN}${BLD}==========> CWB-DOC HAS BEEN UPDATED${RST}"
	echo ""

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/upd-cwbdoc.sh"
    sudo chmod ug+rwx "${HOME}/bin/upd-cwbdoc.sh"


    ####################
    # CREATE SCRIPT TO UPDATE CWB-PERL
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/upd-cwbperl.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/upd-cwbperl.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# UPDATE CWB-PERL INSTALLATION
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	# IF YOU WANT TO INSTALL A SPECIFIC RELEASE, SET IT IN THE FOLLOWING VARIABLE. 0 = LATEST.
	CQPCWBRELEASE=0

	echo ""
	echo "${CLBL}${BLD}==========> UPDATING CWB-PERL...${RST}"

	# MOVE TO SOFTWARE INSTALL DIRECTORY
	cd ${SWDIR} || exit

	# CLEAN THE INSTALL JUST IN CASE
	svn cleanup cwb-perl

	# UPDATE THE INSTALL
	if [[ "\$CQPCWBRELEASE" -eq 0 ]]; then
	    # UPDATE TO LATEST RELEASE
	    svn update cwb-perl
	else
	    # UPDATE TO SPECIFIC RELEASE
	    svn update -r \${CQPCWBRELEASE} cwb-perl
	fi

	# COMPILE PERL MODULES

	echo ""
	echo "${CLBL}==========> Compiling CWB Perl modules...${RST}"

	# MOVE INTO CWB-PERL DIRECTORY
	cd "${SWDIR}/cwb-perl" || exit

	cd CWB || exit
	perl Makefile.PL
	make
	make test
	sudo make install

	cd ../CWB-CL || exit
	perl Makefile.PL
	make
	make test
	sudo make install

	cd ../CWB-CQI || exit
	perl Makefile.PL
	make
	make test
	sudo make install

	cd ../CWB-Web || exit
	perl Makefile.PL
	make
	make test
	sudo make install

	echo "${CGRN}${BLD}==========> CWB-PERL HAS BEEN UPDATED${RST}"
	echo ""

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/upd-cwbperl.sh"
    sudo chmod ug+rwx "${HOME}/bin/upd-cwbperl.sh"


    ####################
    # CREATE SCRIPT TO UPDATE CQPWEB
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/upd-cqpweb.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/upd-cqpweb.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# UPDATE CQPWEB INSTALLATION
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	# IF YOU WANT TO INSTALL A SPECIFIC RELEASE, SET IT IN THE FOLLOWING VARIABLE. 0 = LATEST.
	CQPCWBRELEASE=0

	echo ""
	echo "${CLBL}${BLD}==========> UPDATING CQPWEB...${RST}"

	# MOVE TO CQPWEB INSTALL DIRECTORY
	cd /var/www/html || exit

	# CLEAN THE INSTALL JUST IN CASE
	sudo svn cleanup cqpweb

	# UPDATE THE INSTALL
	if [[ "\$CQPCWBRELEASE" -eq 0 ]]; then
	    # UPDATE TO LATEST RELEASE
	    sudo svn update cqpweb
	else
	    # UPDATE TO SPECIFIC RELEASE
	    sudo svn update -r \${CQPCWBRELEASE} cqpweb
	fi

	# CHANGE PERMISSIONS ON WEB SERVER DIRECTORY
	sudo chgrp -R www-data /var/www/html/cqpweb
	sudo chmod -R g+rwX /var/www/html/cqpweb

	# RESTART APACHE WEB SERVER
	sudo systemctl reload apache2
	sudo systemctl restart apache2

	echo "${CGRN}${BLD}==========> CQPWEB HAS BEEN UPDATED${RST}"
	echo ""

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/upd-cqpweb.sh"
    sudo chmod ug+rwx "${HOME}/bin/upd-cqpweb.sh"


    ####################
    # CREATE SCRIPT TO UPDATE ALL COMPONENTS AT ONCE (BY RUNNING THE ABOVE SCRIPTS)
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/upd-all.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/upd-all.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# UPDATE ALL CQP AND CWB COMPONENTS
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	echo ""
	echo "${CLBL}${BLD}==========> UPDATING ALL CWP AND CWB COMPONENTS...${RST}"

	# MOVE TO SOFTWARE INSTALL DIRECTORY
	cd ${SWDIR} || exit

	upd-cwb.sh
	upd-cwbdoc.sh
	upd-cwbperl.sh
	upd-cqpweb.sh

	echo "${CGRN}${BLD}==========> ALL CQP AND CWB COMPONENTS HAVE BEEN UPDATED${RST}"
	echo ""

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/upd-all.sh"
    sudo chmod ug+rwx "${HOME}/bin/upd-all.sh"


    ####################
    # CREATE SCRIPT TO MANUALLY CALCULATE STTR
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/calculate-sttr.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/calculate-sttr.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# CALCULATE STTR MANUALLY
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	echo ""
	echo "${CLBL}${BLD}==========> CALCULATING STTR FOR ALL CORPORA MANUALLY...${RST}"

	# MOVE TO SOFTWARE INSTALL DIRECTORY
	cd /var/www/html/cqpweb/bin || exit

	sudo php execute-cli.php update_all_missing_sttr

	echo "${CGRN}${BLD}==========> STTR FOR ALL CORPORA HAS BEEN CALCULATED${RST}"
	echo ""

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/calculate-sttr.sh"
    sudo chmod ug+rwx "${HOME}/bin/calculate-sttr.sh"


    ####################
    # CREATE BYMON MONITORING SCRIPT
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/bymon.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/bymon.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# Script to start byobu with a standard set of monitoring tools
	# running in different screens and panes

	MYHOST=$(hostname)

	# WINDOW 0: CLI
	byobu new-session -d -s $USER
	byobu rename-window -t $USER:0 'CLI'

	# WINDOW 1: GLANCES
	byobu new-window -t $USER:1 -n 'GLANCES'
	byobu send-keys "glances -t 5 --process-short-name --fs-free-space -6" C-m

	# WINDOW 2: OTHER MONITORING TOOLS
	byobu new-window -t $USER:2 -n 'MONITOR'
	byobu send-keys "htop" C-m
	byobu split-window -v
	byobu send-keys "speedometer -i 2 -r ${ETHERNET} -t ${ETHERNET}" C-m

	# WINDOW 3: S-TUI
	byobu new-window -t $USER:3 -n 'S-TUI'
	byobu send-keys "s-tui" C-m

	# WINDOW 4: MC
	byobu new-window -t $USER:4 -n 'MC'
	byobu send-keys "mc" C-m

	# START BYOBU
	byobu

EOF

    # SET OWNER, GROUP AND PERMISSIONS OF SCRIPT FILE
    sudo chown "${USER}:${USER}" "${HOME}/bin/bymon.sh"
    sudo chmod ug+rwx "${HOME}/bin/bymon.sh"







    # UPLOAD FAVICON TO SERVER
    if ! [[ "${FAVICONUPLD}" = 0 ]] || [[ "${FAVICONURL}" = "YOUR_INFO_HERE" ]]; then
        IMAGETARGET="/var/www/html/cqpweb/"
        wget -P "${IMAGETARGET}" "${FAVICONURL}"
    fi

    echo "${CGRN}${BLD}==========> CQPWEB installation finished.${RST}"
    echo "${CWHT}${BLD}            You will find useful scripts in ${HOME}/bin.${RST}"
    echo ""
    echo "${CRED}${BLD}            Kindly reboot now.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping CQPWEB installation...${RST}"
fi


########################################
# INSTALL THE DICKENS SAMPLE CORPUS
########################################
if [[ "$CORPDICKENS" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing DICKENS CORPUS...${RST}"

    # CREATE DATA AND REGISTRY DIRECTORIES, SET GROUP AND PERMISSIONS, AND COPY FILES TO THEM
    # NOTE use of 'cp -a' plus "." after the path -- 'cp -r' does NOT copy hidden files!
    sudo mkdir -p "${COMMONCQPWEBDIR}/data/Dickens"
    sudo mkdir -p "${COMMONCQPWEBDIR}/registry"

    sudo chgrp www-data ${COMMONCQPWEBDIR}/*
    sudo chmod g+rwx,o-rwx,+s ${COMMONCQPWEBDIR}/*

    sudo cp -a "${SWDIR}/cwb-doc/corpora/dickens/release/Dickens-1.0/data/." "${COMMONCQPWEBDIR}/data/Dickens/"
    sudo cp "${SWDIR}/cwb-doc/corpora/dickens/release/Dickens-1.0/registry/dickens" "${COMMONCQPWEBDIR}/registry/dickens"

    # CHANGE CONTENTS OF REGISTRY FILE TO POINT TO ACTUAL DATA AND REGISTRY LOCATIONS
    configLine "^HOME.*" "HOME ${COMMONCQPWEBDIR}/data/Dickens"       ${COMMONCQPWEBDIR}/registry/dickens
    configLine "^INFO.*" "INFO ${COMMONCQPWEBDIR}/data/Dickens/.info" ${COMMONCQPWEBDIR}/registry/dickens

    echo "${CGRN}${BLD}==========> DICKENS CORPUS installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping DICKENS CORPUS installation...${RST}"
fi


########################################
# INSTALL AND CONFIGURE MAIL SOFTWARE
########################################
if [[ "$MAILSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing MAIL SERVER...${RST}"

    # INSTALL MAIL SERVER SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y

    echo ""
    echo "${CORG}${BLD}We will now install the Postfix mail server. If asked, choose the following options...${RST}"
    echo        "${CWHT} - Type of Mail Configuration:${RST} ${CORG}${BLD}Internet${RST}"
    echo        "${CWHT} - System mail name:          ${RST} ${CORG}${BLD}${MAILSERVERURL}${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    sudo apt install -y --install-recommends mailutils mailutils-mh libsasl2-2 libsasl2-modules ca-certificates secure-delete

    # IF BACKUP OF CONFIG FILE EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP
    if [[ -f "/etc/postfix/main.cf.BAK" ]]; then
        # RESTORE BACKUP
        sudo rm /etc/postfix/main.cf
        sudo cp /etc/postfix/main.cf.BAK /etc/postfix/main.cf
    else
        # MAKE BACKUP
        sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.BAK
    fi

    # CONFIGURE THE POSTFIX MTA SERVER
    configLine "^myhostname[ =].*"      "myhostname = ${OUTMAILSERVER}" /etc/postfix/main.cf              >/dev/null 2>&1
    configLine "^inet_interfaces[ =].*" "inet_interfaces = loopback-only" /etc/postfix/main.cf            >/dev/null 2>&1
    configLine "^relayhost[ =].*"       "relayhost = [${OUTMAILSERVER}]:${SMTPPORT}" /etc/postfix/main.cf >/dev/null 2>&1

    # NOTE: If you run this script more than one, you will end up with multiple copies of the following
    #       config entries, possibly with multiple values. PRUNE IT MANUALLY IF THIS HAPPENS!
    echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"              | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_sasl_auth_enable = yes"                                          | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_sasl_security_options = noplaintext noanonymous"                 | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_sender_dependent_authentication = yes"                           | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_connection_cache_on_demand = no"                                 | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "sender_dependent_relayhost_maps = hash:/etc/postfix/sender_dependent" | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "sender_canonical_maps = hash:/etc/postfix/sender_canonical"           | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_sasl_tls_security_options = noanonymous"                         | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_tls_note_starttls_offer = yes"                                   | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_tls_security_level = encrypt"                                    | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"                 | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_tls_wrappermode = yes"                                           | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1
    echo "smtp_use_tls = yes"                                                   | sudo tee -a /etc/postfix/main.cf  >/dev/null 2>&1

    # REMOVE OLD USERNAME/PASSWORD FILES
    sudo rm -f /etc/postfix/sasl_passwd
    sudo rm -f /etc/postfix/sender_dependent
    sudo rm -f /etc/postfix/sender_canonical

    # CREATE USERNAME/PASSWORD FILES
    sudo touch /etc/postfix/sasl_passwd
    sudo touch /etc/postfix/sender_dependent
    sudo touch /etc/postfix/sender_canonical

    # IF NO E-MAIL PASSWORD WAS SET ABOVE IN THE CONFIGURATION SECTION, PROMPT FOR ONE NOW
    if [[ "$MAILSERVERPWD" = "" ]] || [[ "$MAILSERVERPWD" = "YOUR_INFO_HERE" ]]; then

        # ASK FOR PASSWORD AND CONFIRMATION, COMPARE THEM, AND ACT ACCORDINGLY
        while true; do

            # UNSET VARIABLES TO START AFRESH
            unset MAILSERVERPWD
            unset MAILSERVERPWD2

            echo ""

            # GET PASSWORD: FIRST ATTEMPT
            prompt="${CWHT}${BLD}Enter the password for your e-mail server: ${RST}"
            while IFS= read -r -p "$prompt" -r -s -n 1 char; do
                if [[ $char == $'\0' ]]; then
                    break
                fi
                prompt='*'
                MAILSERVERPWD+="$char"
            done

            echo ""

            # GET PASSWORD: SECOND ATTEMPT
            prompt="${CWHT}${BLD}Confirm the password for your e-mail server: ${RST}"
            while IFS= read -r -p "$prompt" -r -s -n 1 char; do
                if [[ $char == $'\0' ]]; then
                    break
                fi
                prompt='*'
                MAILSERVERPWD2+="$char"
            done

            echo ""

            # COMPARE PASSWORDS TO SEE IF THEY'RE THE SAME
            [[ "$MAILSERVERPWD" = "$MAILSERVERPWD2" ]] && break || echo -e "\\n${CRED}${BLD}Sorry, the passwords do not match! Please try again...${RST}"
        done

        # PASSWORDS MATCH! CONTINUE ON WITH SCRIPT.
        echo ""
        echo "${CGRN}${BLD}PASSWORDS MATCH!${RST}"
        echo ""
    fi

    # ADD INFO TO USERNAME/PASSWORD FILES
    echo "${OUTMAILSERVER}:${SMTPPORT} ${ADMINMAILADDR}:${MAILSERVERPWD}" | sudo tee -a /etc/postfix/sasl_passwd  >/dev/null 2>&1
    echo "${ADMINMAILADDR} ${OUTMAILSERVER}:${SMTPPORT}" | sudo tee -a /etc/postfix/sender_dependent        >/dev/null 2>&1

    # REMOVE ANY OLD USERNAME/PASSWORD FILES
    sudo rm -f /etc/postfix/sasl_passwd.db
    sudo rm -f /etc/postfix/sender_dependent.db
    sudo rm -f /etc/postfix/sender_canonical.db

    # HASH THE USERNAME/PASSWORD FILES
    sudo postmap /etc/postfix/sasl_passwd
    sudo postmap /etc/postfix/sender_dependent
    sudo postmap /etc/postfix/sender_canonical

    # SECURELY DELETE THE PLAINTEXT USERNAME/PASSWORD FILES
    sudo srm -l /etc/postfix/sasl_passwd
    sudo srm -l /etc/postfix/sender_dependent
    sudo srm -l /etc/postfix/sender_canonical

    # SECURE THE HASHED USERNAME/PASSWORD FILES
    sudo chown root:root /etc/postfix/sasl_passwd.db /etc/postfix/sender_dependent.db /etc/postfix/sender_canonical.db
    sudo chmod 0600 /etc/postfix/sasl_passwd.db /etc/postfix/sender_dependent.db /etc/postfix/sender_canonical.db

    # RESTART MAIL SERVER
    sudo systemctl restart postfix

    # SEND A TEST MESSAGE
    echo ""
    echo "${CORG}${BLD}We will now send a test e-mail to ${CWHT}${PERSONALMAILADDR}${CORG} via ${CWHT}${OUTMAILSERVER}:${SMTPPORT}${CORG}.${RST}"
    echo "${CORG}${BLD}If things don't work, look at 'sudo tail -f /var/log/mail.log'.${RST}"
    echo ""

    echo -e "Hi!\\n\\nThis is the Postfix send-only mail server on ${LOCALHOSTNAME} (${INTERNALIP} / ${EXTERNALIP}). I'm sending this test e-mail to ${PERSONALMAILADDR} via ${OUTMAILSERVER}:${SMTPPORT}.\\n\\nIt's currently ${TIME} on ${DATE}.\\n\\nHave a nice day!" | mail -s "Test mail from Postfix on $LOCALHOSTNAME" -a "From: ${ADMINMAILADDR}" "${PERSONALMAILADDR}"

    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    echo "${CGRN}${BLD}==========> MAIL SERVER installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping MAIL SERVER installation...${RST}"
fi


########################################
# INSTALL SECURITY SOFTWARE AND HARDEN SERVER
# https://github.com/imthenachoman/How-To-Secure-A-Linux-Server
########################################
if [[ "$SECURITYSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing SECURITY SOFTWARE...${RST}"
    echo "${CRED}${BLD}            If you are prompted to configure a mail server, just hit ENTER as much as necessary.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    ####################
    # INSTALL LYNIS SECURITY MONITORING SOFTWARE
    ####################
    echo ""
    echo "${CLBL}==========> Installing Lynis security auditing software...${RST}"

    if ! grep -q "^deb .*lynis" /etc/apt/sources.list /etc/apt/sources.list.d/* 2> /dev/null; then
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F
        echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
    else
        echo ""
        echo "${CWHT}${BLD}            The Lynis respository is already installed.${RST}"
    fi

    # UPDATE AND INSTALL SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends chkrootkit logwatch lynis

    echo ""
    echo "${CWHT}${BLD}            To audit your system, run ${CORG}sudo lynis audit system --quick${CWHT} or simply ${CORG}audit${CWHT}.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    ####################
    # REMOVE INSECURE SOFTWARE
    ####################
    echo ""
    echo "${CLBL}==========> Removing insecure software...${RST}"

    sudo apt-get --purge remove xinetd nis yp-tools tftpd atftpd tftpd-hpa telnetd rsh-server rsh-redone-server

    ####################
    # HARDEN SYSCTL SETTINGS
    ####################
    echo ""
    echo "${CLBL}==========> Hardening sysctl.conf settings...${RST}"
    configLine "^[# ]*kernel.exec-shield.*$"                     "kernel.exec-shield=1"                     /etc/sysctl.conf
    configLine "^[# ]*kernel.randomize_va_space.*$"              "kernel.randomize_va_space=1"              /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.accept_redirects.*$"     "net.ipv4.conf.all.accept_redirects=0"     /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.accept_source_route.*$"  "net.ipv4.conf.all.accept_source_route=0"  /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.log_martians.*$"         "net.ipv4.conf.all.log_martians=1"         /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.log_martians.*$"         "net.ipv4.conf.all.log_martians=1"         /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.rp_filter.*$"            "net.ipv4.conf.all.rp_filter=1"            /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.rp_filter.*$"            "net.ipv4.conf.all.rp_filter=1"            /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.all.send_redirects.*$"       "net.ipv4.conf.all.send_redirects=0"       /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.default.accept_redirects.*$" "net.ipv4.conf.default.accept_redirects=0" /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.default.rp_filter.*$"        "net.ipv4.conf.default.rp_filter=1"        /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.conf.default.send_redirects.*$"   "net.ipv4.conf.default.send_redirects=0"   /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.icmp_echo_ignore_broadcasts.*$"   "net.ipv4.icmp_echo_ignore_broadcasts=1"   /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.icmp_ignore_bogus_error_messages.*$" "net.ipv4.icmp_ignore_bogus_error_messages=1=1" /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.icmp_ignore_bogus_error_responses.*$" "net.ipv4.icmp_ignore_bogus_error_responses=1" /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.icmp_ignore_bogus_error_responses.*$" "net.ipv4.icmp_ignore_bogus_error_responses=1" /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.ip_forward.*$"                    "net.ipv4.ip_forward=0"                    /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.tcp_max_syn_backlog.*$"           "net.ipv4.tcp_max_syn_backlog=2048"        /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.tcp_syn_retries.*$"               "net.ipv4.tcp_syn_retries=5"               /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.tcp_synack_retries.*$"            "net.ipv4.tcp_synack_retries=2"            /etc/sysctl.conf
    configLine "^[# ]*net.ipv4.tcp_syncookies.*$"                "net.ipv4.tcp_syncookies=1"                /etc/sysctl.conf

    # RELOAD sysctl
    sudo sysctl -p

    ####################
    # DISABLE USB, THUNDERBOLT, FIREWIRE PORTS. GOOD SECURITY PRACTICE FOR SERVERS
    ####################
    echo ""
    echo "${CLBL}==========> Disabling Firewire and Thunderbolt ports...${RST}"
    echo "blacklist firewire-core"          | sudo tee /etc/modprobe.d/firewire.conf
    echo "blacklist thunderbolt"            | sudo tee /etc/modprobe.d/thunderbolt.conf
    # echo "install usb-storage /bin/true"    | sudo tee /etc/modprobe.d/block_usb.conf # THIS WOULD BLOCK UPS USB CONNECTIONS, KEYBOARD, ETC.

    ####################
    # HARDEN APACHE SERVER
    ####################
    echo ""
    echo "${CLBL}==========> Hardening Apache server a wee bit...${RST}"
    configLine "^[# ]*ServerTokens[ ].*"        "ServerTokens Prod"     /etc/apache2/apache2.conf
    configLine "^[# ]*ServerSignature[ ].*"     "ServerSignature Off"   /etc/apache2/apache2.conf
    configLine "^[# ]*TraceEnable[ ].*"         "TraceEnable Off"       /etc/apache2/apache2.conf

    ####################
    # SECURE SHARED MEMORY
    # You may or may not want to modify the 'size=512m' parameter.
    ####################
    echo -e "tmpfs   /run/shm   tmpfs   rw,noexec,nosuid,nodev,size=512m   0   0\\n" | sudo tee -a /etc/fstab >/dev/null 2>&1

    echo "${CGRN}${BLD}==========> SECURITY SOFTWARE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping SECURITY SOFTWARE installation...${RST}"
fi


################################################################################
# INSTALL AND CONFIGURE UFW (FIREWALL)
#
# This sets up the Uncomplicated FireWall (UFW). It allows full traffic on ports
# 80 (HTTP) and 443 (HTTPS), allows limited traffic on other ports the user
# defines, and blocks everything else. Limited traffic means that after 6 attempts
# to connect in 30 seconds, the user is temporarily blocked.
################################################################################
if [[ "$UFWSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing UNCOMPLICATED FIREWALL (UFW)...${RST}"
    echo "${CORG}${BLD}            NOTE: This overwrites any currently-existing configuration.${RST}"
    echo "${CORG}${BLD}            To completely reset UFW, run ${CWHT}sudo ufw reset${CORG} and then run this script again.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    # Install and update software
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends ufw

    # First, deny all incoming connections by default and allow all outgoing ones
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Next, allow free access for HTTP (port 80) and HTTPS (port 443)
    sudo ufw allow http   comment 'HTTP port'
    sudo ufw allow https  comment 'HTTPS port'

    # Finally, configure various other ports. Feel free to comment out the ones
    # you don't need. Values: allow (allow), limit (block after 6 failed attempts
    # in 30 seconds), reject (block with notification), deny (block silently).
    if [[ ! -z "${SSHPORT}" ]];   then sudo ufw limit "${SSHPORT}"   comment 'SSH port'; fi
    if [[ ! -z "${SMTPPORT}" ]];  then sudo ufw limit "${SMTPPORT}"  comment 'SMTP port'; fi
    if [[ ! -z "${RSYNCPORT}" ]]; then sudo ufw limit "${RSYNCPORT}" comment 'RSYNC port'; fi
    if [[ ! -z "${IMAPSPORT}" ]]; then sudo ufw limit "${IMAPSPORT}" comment 'IMAPS port'; fi
    if [[ ! -z "${POP3PORT}" ]];  then sudo ufw limit "${POP3PORT}"  comment 'POP3 port'; fi
    if [[ ! -z "${IMAPPORT}" ]];  then sudo ufw limit "${IMAPPORT}"  comment 'IMAP port'; fi

    # Turn on logging, reload and enable UFW
    sudo ufw logging on
    sudo ufw reload
    sudo ufw enable

    # Report on status
    echo ""
    echo "${CORG}${BLD}==========> Your Uncomplicated FireWall (UFW) configuration is now as follows...${RST}"

    sudo ufw status verbose

    echo ""
    echo "${CRED}${BLD}            NOTE: Your SSH port is ${CWHT}${SSHPORT}${CRED}. If you haven't done so already, running this script ${RST}"
    echo "${CRED}${BLD}                  again, but with ${CWHT}SSHPWDSW=1${CRED}, will configure the server for SSH using this port.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    echo "${CGRN}${BLD}==========> UNCOMPLICATED FIREWALL (UFW) installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping UNCOMPLICATED FIREWALL (UFW) installation...${RST}"
fi


########################################
# INSTALL UPS SOFTWARE
# THIS IS ONLY FOR THE APC BackUPS Pro 900 UPS (051d:0002).
# IT WILL NOT WORK WITH OTHER MODELS, BUT YOU CAN LIKELY ADAPT THE SCRIPT.
# INFO: http://www.apcupsd.com/manual/manual.html#process-status-test
########################################
if [[ "$UPSSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing UPS SOFTWARE...${RST}"

    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends apcupsd

    # UPS CONFIG SETTINGS
    configLine "^[# ]*UPSCABLE.*"       "UPSCABLE usb"      /etc/apcupsd/apcupsd.conf
    configLine "^[# ]*UPSTYPE.*"        "UPSTYPE usb"       /etc/apcupsd/apcupsd.conf
    configLine "^[# ]*DEVICE.*"         "DEVICE"            /etc/apcupsd/apcupsd.conf
    configLine "^[# ]*MINUTES.*"        "MINUTES 5"         /etc/apcupsd/apcupsd.conf
    configLine "^[# ]*BATTERYLEVEL.*"   "BATTERYLEVEL 10"   /etc/apcupsd/apcupsd.conf
    configLine "^[# ]*LOCKFILE.*"       "LOCKFILE /tmp"     /etc/apcupsd/apcupsd.conf

    # RESTART APC UPS DAEMON
    sudo systemctl restart apcupsd.service

    echo "${CGRN}${BLD}==========> UPS SOFTWARE installation finished.${RST}"
    echo "${CWHT}${BLD}            To see UPS status, run ${CORG}apcaccess status${CWHT}.${RST}"
    echo "${CWHT}${BLD}            To test UPS, run ${CORG}sudo systemctl stop apcupds.service && sudo apctest${CWHT}.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping UPS SOFTWARE installation...${RST}"
fi


########################################
# INSTALL AND CONFIGURE FAIL2BAN
########################################
if [[ "$FAIL2BANSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing FAIL2BAN...${RST}"
    echo "${CORG}${BLD}            NOTE: You can easily lock yourself out of your server with fail2ban! The safe thing${RST}"
    echo "${CORG}${BLD}                  to do is install it while you have physical access to the server.${RST}"
    echo ""
    read -r -p "${CRED}${BLD}            Are you sure you want to proceed? (y/n) ${RST}" ANSWER

    if [[ "$ANSWER" = [yY] || "$ANSWER" = [yY][eE][sS] ]]; then

        # Install the software
        sudo apt update -y
        sudo apt install -y --install-recommends fail2ban iptables-persistent denyhosts logcheck

        # Delete any pre-existing local config file and create a new one
        sudo rm -f /etc/fail2ban/jail.local
        sudo touch /etc/fail2ban/jail.local

        # Create config file
        sudo tee -a /etc/fail2ban/jail.local <<- EOF >/dev/null 2>&1
		[default]
		bantime = 30m
		findtime = 30m
		banaction = iptables-allports
		backend = auto ; pyinotify, gamin, polling, systemd, auto
		destemail = ${PERSONALMAILADDR}
		sender = ${ADMINMAILADDR}
		sendername = Fail2Ban.${LOCALHOSTNAME}
		mta = sendmail
		action = %(action_mwl)s
		ignoreip = ${WHITELISTEDIPS}
		maxretry = 3

		[ssh]
		enabled = true
		port = ssh,${SSHPORT}
		filter = sshd
		logpath = /var/log/auth.log
		action = %(action_mwl)s

		[postfix]
		enabled = true
		port = smtp,ssmtp,${SMTPPORT},${POP3PORT},${IMAPPORT}
		filter = postfix
		logpath = /var/log/mail.log
		action = %(action_mwl)s

		[postfix-sasl]
		enabled = true
		port = smtp,465,submission,imap,imaps,pop3,pop3s,${SMTPPORT},${POP3PORT},${IMAPPORT}
		filter = postfix[mode=auth]
		logpath = /var/log/mail.log
		backend = %(postfix_backend)s
		action = %(action_mwl)s

		# Block failed Apache login attempts
		[apache]
		enabled = true
		port = http,https
		filter = apache-auth
		logpath = /var/log/apache2/*error.log
		#logpath = %(apache_error_log)s

		# Block remote hosts that try to request malicious bots
		[apache-badbots]
		enabled = true
		port = http,https
		filter = apache-badbots
		bantime = 48h
		maxretry = 1
		logpath = /var/log/apache2/*error.log
		#logpath = %(apache_access_log)s

		# Block remote hosts that try to search for scripts on the website to execute
		[apache-noscript]
		enabled = true
		port = http,https
		filter = apache-noscript
		logpath = /var/log/apache2/*error.log
		#logpath = %(apache_error_log)s

		# Block remote hosts that try to request suspicious URLs
		[apache-overflows]
		enabled = true
		port = http,https
		filter = apache-overflows
		logpath = /var/log/apache2/*error.log
		#logpath = %(apache_error_log)s
		maxretry = 2

		[apache-nohome]
		enabled = true
		port = http,https
		logpath = %(apache_error_log)s
		maxretry = 2

		[apache-botsearch]
		enabled = true
		port = http,https
		logpath = %(apache_error_log)s
		maxretry = 2

		[apache-fakegooglebot]
		enabled = true
		port = http,https
		logpath = %(apache_access_log)s
		maxretry = 1
		ignorecommand = %(ignorecommands_dir)s/apache-fakegooglebot <ip>

		[apache-modsecurity]
		enabled = true
		port = http,https
		logpath = %(apache_error_log)s
		maxretry = 2

		[apache-shellshock]
		enabled = true
		port = http,https
		logpath = %(apache_error_log)s
		maxretry = 1

EOF

        # (RE)START FAIL2BAN AND RELOAD CONFIG (ODDLY, IT'S NECESSARY)
        sudo fail2ban-client reload
        sudo systemctl restart fail2ban

        # Enable fail2ban on startup
        sudo systemctl enable fail2ban

        echo "${CGRN}${BLD}==========> FAIL2BAN installation finished.${RST}"
        echo "${CWHT}${BLD}            To unban someone (probably yourself): ${CORG}sudo fail2ban-client set sshd unbanip <IP-ADDRESS>${RST}"
        echo "${CWHT}${BLD}            To check status: ${CORG}sudo fail2ban-client status [SERVICE]${RST}"
        echo "${CWHT}${BLD}            To see the actual configuration: ${CORG}fail2ban-client -[v]d${RST}"
        echo "${CWHT}${BLD}            To read logs: ${CORG}sudo tail -f /var/log/fail2ban.log${RST}"
        echo ""
        read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds), or ${CWHT}CTRL+C${CORG} to exit script... ${RST}" -n 1 -t 10 -s
        echo ""
    else
        echo "${CORG}${BLD}==========> Skipping FAIL2BAN installation...${RST}"
    fi
fi

########################################
# INSTALL THE FREELING TAGGER
########################################
if [[ "$FREELINGSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing FREELING...${RST}"

    # INSTALL REQUIRED DISTRO PACKAGES
    sudo apt update -y

    sudo apt upgrade -y

    sudo apt install -y --install-recommends icu-devtools libicu-dev libboost-regex-dev libboost-system-dev libboost-thread-dev libboost-program-options-dev libboost-locale-dev zlib1g-dev build-essential automake autoconf libtool git cmake libboost-filesystem-dev libboost-iostreams-dev

    # DEFINE INSTALL DIRECTORY
    INSTALLBASEDIR="${SWDIR}/freeling"

    # NUKE FREELING DOWNLOAD DIRECTORY IF SO DESIRED
    if [[ "$FREELINGNUKEOLD" = 1 ]]; then
        sudo rm -rf "${INSTALLBASEDIR}"
    fi

    # MAKE INSTALL DIRECTORY AND SET OWNER
    sudo mkdir -p "${INSTALLBASEDIR}"
    sudo chown "${USER}":"${USER}" "${INSTALLBASEDIR}"

    # CHANGE INTO INSTALL DIRECTORY
    cd "${INSTALLBASEDIR}" || exit

    # CLONE GITHUB REPO IF IT DOESN'T EXIST. OTHERWISE, UPDATE IT.
    if [[ -d "${INSTALLBASEDIR}/FreeLing" ]]; then
        cd "${INSTALLBASEDIR}/FreeLing" || exit
        git pull
    else
        mkdir -p "${INSTALLBASEDIR}/FreeLing"
        git clone https://github.com/TALP-UPC/FreeLing.git FreeLing
    fi

    # MAKE CHILEAN SPANISH MODIFICATIONS IF DESIRED
    if [[ "$FREELINGESCLMODS" = 1 ]]; then

        # REMOVE UNNEEDED LANGUAGE DIRECTORIES
        cd "${INSTALLBASEDIR}/FreeLing/data" || exit
        rm -rf ./as
        rm -rf ./ca
        rm -rf ./cs
        rm -rf ./cy
        rm -rf ./de
        rm -rf ./en
        rm -rf ./fr
        rm -rf ./gl
        rm -rf ./hr
        rm -rf ./it
        rm -rf ./nb
        rm -rf ./pt
        rm -rf ./ru
        rm -rf ./sl

        # REMOVE UNNEEDED LANGUAGE CONFIG FILES
        cd "${INSTALLBASEDIR}/FreeLing/data/config" || exit
        rm -f as.cfg
        rm -f ca-balear.cfg
        rm -f ca-valencia.cfg
        rm -f ca.cfg
        rm -f cs.cfg
        rm -f cy.cfg
        rm -f de.cfg
        rm -f en.cfg
        rm -f es-ar.cfg
        rm -f es-old.cfg
        rm -f fr.cfg
        rm -f gl.cfg
        rm -f it.cfg
        rm -f nb.cfg
        rm -f pt.cfg
        rm -f ru.cfg
        rm -f sl.cfg

        # CHANGE OPTIONS IN es-cl.cfg
        configLine "^[# ]*AlwaysFlush.*"         "AlwaysFlush=yes" "${INSTALLBASEDIR}/FreeLing/data/config/es-cl.cfg"
        configLine "^[# ]*NERecognition.*"       "NERecognition=yes" "${INSTALLBASEDIR}/FreeLing/data/config/es-cl.cfg"
        configLine "^[# ]*MultiwordsDetection.*" "MultiwordsDetection=no" "${INSTALLBASEDIR}/FreeLing/data/config/es-cl.cfg"

        # CHANGE OPTIONS IN np.dat
        perl -i -p0e 's/<TitleLimit>.*\d.*<\/TitleLimit>/<TitleLimit>\n3\n<\/TitleLimit>/gms' "${INSTALLBASEDIR}/FreeLing/data/es/np.dat"

        # INSTALL DICTIONARIES WITH SPECIAL CHILEAN VOSEO TAGS
        cd "${INSTALLBASEDIR}/FreeLing" || exit

        rm -f "${INSTALLBASEDIR}/FreeLing/data/es/es-cl/dictionary/entries/CL.vaux"
        rm -f "${INSTALLBASEDIR}/FreeLing/data/es/es-cl/dictionary/entries/CL.verb"

        aria2c http://www.sadowsky.cl/files/freeling/CL.vaux.Vos-V.zip >/dev/null 2>&1
        aria2c http://www.sadowsky.cl/files/freeling/CL.verb.Vos-V.zip >/dev/null 2>&1

        yes | unzip CL.vaux.Vos-V.zip -d "${INSTALLBASEDIR}/FreeLing/data/es/es-cl/dictionary/entries/" >/dev/null 2>&1
        yes | unzip CL.verb.Vos-V.zip -d "${INSTALLBASEDIR}/FreeLing/data/es/es-cl/dictionary/entries/" >/dev/null 2>&1

        rm -f CL.vaux.Vos-V.zip
        rm -f CL.verb.Vos-V.zip
    fi

    # BUILD FREELING
    cd "${INSTALLBASEDIR}/FreeLing" || exit
    mkdir build
    cd build || exit
    cmake ..
    sudo make -j 6 install

    echo "${CGRN}${BLD}==========> FREELING installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping FREELING installation...${RST}"
fi


########################################
# INSTALL PRAAT HEADLESS VERSION
########################################
if [[ "$PRAATHEADLESSSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing HEADLESS PRAAT...${RST}"

    # SET INSTALL DIRECTORY, MAKE IT AND MOVE THERE
    INSTALLBASEDIR="${SWDIR}/praatheadless"
    mkdir -p "${INSTALLBASEDIR}"
    cd "${INSTALLBASEDIR}" || exit

    # INSTALL DISTRO DEPENDENCIES
    sudo apt install -y --install-recommends libpangocairo*

    ##########
    # DOWNLOAD LATEST HEADLESS VERSION OF PRAAT HEADLESS
    ##########

    # DELETE THE PRAATHEADLESS DOWNLOAD WEB PAGE, IF IT EXISTS
    if [[ -f "download_linux.html" ]]; then
        rm download_linux.html
    fi

    # DOWNLOAD THE WEB PAGE THAT HAS THE LATEST HEADLESS PRAATHEADLESS DOWNLOAD LINKS
    wget http://www.fon.hum.uva.nl/praat/download_linux.html

    # EXTRACT THE FILENAME OF THE LATEST HEADLESS PRAATHEADLESS VERSION FROM THE WEBPAGE
    PRAATFILENAME=$(cat download_linux.html | grep linux64nogui | sed -r 's/^.+<a href=(.+\.tar.gz)>.+$/\1/')

    # DOWNLOAD THE LATEST HEADLESS PRAATHEADLESS VERSION
    wget "http://www.fon.hum.uva.nl/praat/$PRAATFILENAME"

    # UNCOMPRESS THE FILE AND DELETE THE .tar.gz AND .html FILES
    tar zxvf "${PRAATFILENAME}"
    rm -f "${PRAATFILENAME}"
    rm -f download_linux.html

    # MAKE THE FILE EXECUTABLE
    sudo chmod +x praat_nogui

    # DELETE ANY EXISTING SYMLINK TO /usr/local/bin AND MAKE A NEW ONE
    sudo rm -f /usr/local/bin/praat_nogui
    sudo ln -s "${INSTALLBASEDIR}/praat_nogui" /usr/local/bin/

    echo "${CGRN}${BLD}==========> HEADLESS PRAAT installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping HEADLESS PRAAT installation...${RST}"
fi


########################################
# INSTALL VISIDATA
########################################
if [[ "$VISIDATASW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing VISIDATA...${RST}"

    # INSTALL DISTRO DEPENDENCIES
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends libpq-dev

    # INSTALL VISIDATA ITSELF
    sudo -H pip3 install --system --upgrade visidata

    # INSTALL ADDITIONAL VISIDATA REQUIREMENTS
    wget https://raw.githubusercontent.com/saulpw/visidata/stable/requirements.txt
    sudo -H pip3 install --system --upgrade -r requirements.txt

    # CLEANUP REQUIREMENTS FILE
    sudo rm requirements.txt

    echo "${CGRN}${BLD}==========> VISIDATA installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping VISIDATA installation...${RST}"
fi


########################################
# INSTALL RSTUDIO
########################################
if [[ "$RSTUDIOSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing RSTUDIO...${RST}"
    echo "${CWHT}${BLD}            NOTE: The Rstudio people do ${UL}not${NUL} make it easy to download the latest version without visiting${RST}"
    echo "${CWHT}${BLD}            their web page and doing it manually. Thus, this part of the script could break at any time.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
    echo ""

    # GET CURRENT VERSION OF RSTUDIO
    LATESTVER="$(curl -s http://download1.rstudio.org/current.ver)"

    # ELIMINATE -NUMBER from end of version
    LATESTVER="$(sed -r 's/-([0-9]+)$//' <<< $LATESTVER)"

    # FIND OUT VERSION OF CURRENTLY-INSTALLED RSTUDIO
    INSTALLEDVER="$(apt-cache show rstudio | grep Version)"

    # REMOVE TEXT FROM VERSION STRING
    INSTALLEDVER="$(sed 's/Version: //' <<< ${INSTALLEDVER})"

    # PROCEED ONLY IF LATEST VERSION > INSTALLED VERSION
    if [[ "$LATESTVER" > "$INSTALLEDVER" ]]; then

        # CREATE FILENAME
        FILE="rstudio-${LATESTVER}-amd64.deb"

        # CREATE DOWNLOAD URL INCLUDING FILENAME
        URL="https://download1.rstudio.org/desktop/bionic/amd64/${FILE}"

        echo "${CWHT}${BLD}==========> Attempting to download ${URL}.${RST}"

        # DOWNLOAD FILE
        cd /tmp || exit
        aria2c --dir=/tmp/ "${URL}"

        # INSTALL RSTUDIO
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y --install-recommends "/tmp/${FILE}"

        # CLEAN UP TEMPORARY .DEB FILE
        rm "/tmp/${FILE}"

        echo "${CGRN}${BLD}==========> Installed RSTUDIO v. $LATESTVER (previous: $INSTALLEDVER).${RST}"
        echo ""

    else
        echo "${CWHT}${BLD}==========> RSTUDIO is already up to date...${RST}"
        echo ""
    fi

else
    echo "${CORG}${BLD}==========> Skipping RSTUDIO installation...${RST}"
fi


########################################
# INSTALL R LINGUISTICS AND GIS PACKAGES
########################################
if [[ "$RLINGPKGSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing R LINGUISTICS AND GIS PACKAGES...${RST}"
    echo "${CRED}${BLD}            CAUTION: ${CORG}Compiling and installing R packages is often an error-prone process. Failure may occur for${RST}"
    echo "${CORG}${BLD}            any number of reasons, but most commonly it's due to missing ${UL}system${NUL} dependencies (rather than${RST}"
    echo "${CORG}${BLD}            ${UL}R package${NUL} dependencies). If this happens, you must comb the script output for error messages, try${RST}"
    echo "${CORG}${BLD}            to decipher them, and then install the missing software (with ${CWHT}sudo apt install${CORG}). Sorry!${RST}"
    echo ""
    echo "${CORG}${BLD}            Also, note that this process may take an hour or more.${RST}"
    echo ""
    read -r -p "${CORG}${BLD}            Press any key to continue (or wait 20 seconds)... ${RST}" -n 1 -t 20 -s
    echo ""

    # ADD KEY: GIS REPOSITORY 'ubuntugis'
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 314DF160

    # ADD REPOSITORY: GIS REPOSITORY 'ubuntugis'
    if ! grep -q "^deb .*ubuntugis" /etc/apt/sources.list /etc/apt/sources.list.d/* 2> /dev/null; then
        sudo apt-add-repository 'deb http://ppa.launchpad.net/ubuntugis/ubuntugis-unstable/ubuntu bionic main'
    else
        echo "${CWHT}${BLD}            The 'ubuntugis' respository is already installed.${RST}"
    fi


    # ADD PPA: GIS REPOSITORY 'marutter'
    if ! grep -q "^deb .*marutter" /etc/apt/sources.list /etc/apt/sources.list.d/* 2> /dev/null; then
        sudo apt-add-repository ppa:marutter/c2d4u3.5
    else
        echo "${CWHT}${BLD}            The 'marutter' respository is already installed.${RST}"
    fi


    # UPDATE AND UPGRADE SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y

    # INSTALL DISTRO SOFTWARE DEPENDENCIES (PART 1 OF 2)
    sudo apt install -y --install-recommends build-essential default-jdk default-jre libcurl4-openssl-dev libssl-dev r-base r-base-core r-recommended

    # INSTALL DISTRO SOFTWARE DEPENDENCIES (PART 2 OF 2)
    sudo apt install -y --install-recommends bwidget default-jre dos2unix fftw-dev freeglut3-dev jags jq libcairo2-dev libfreetype6-dev libgdal-dev libgeos-dev libgsl0-dev libgtk-3-dev libgtk2.0-dev libjpeg-dev libmagick++-dev libnetcdf-dev libopenblas-dev libpoppler-cpp-dev libpoppler-glib-dev libpq-dev libproj-dev libtiff-dev libudunits2-dev libv8-dev libxml2-dev libxml2-utils locales-all mesa-common-dev r-cran-fftwtools r-cran-maxent r-cran-rggobi r-cran-rmpi r-cran-rweka r-cran-rwekajars r-cran-stem r-cran-tkrplot tcl-dev tk-dev weka

    # RECONFIGURE R TO RECOGNIZE JAVA'S PATH
    sudo R CMD javareconf >/dev/null 2>&1

    # INSTALL R PACKAGES FROM INSIDE R.
    sudo R --vanilla -e 'install.packages(c("FactoMineR", "Hmisc", "MASS", "RCurl", "RKEA", "RKEAjars", "RQGIS", "RWeka", "SnowballC", "XML", "alineR", "ape", "beanplot", "boilerpipeR", "car", "catspec", "childesr", "cluster", "coin", "corpora", "curl", "devtools", "downloader", "dplyr", "epitools", "exactLoglinTest", "geoR", "ggmap", "ggplot2", "gplots", "gstat", "gsubfn", "gtools", "gutenbergr", "hms", "hunspell", "igraph", "kernlab", "koRpus", "languageR", "lda", "leaflet", "lingtypology", "linguisticsdown", "lme4", "lmtest", "lsa", "mapdata", "maptools", "monkeylearn", "movMF", "ncdf4", "nlme", "nloptr", "nnet", "openNLP", "ore", "phonR", "phonTools", "phonics", "maps", "pkgKitten", "pkgconfig", "plyr", "prettyR", "pscl", "qdap", "quanteda", "rJava", "raster", "rel", "reshape", "reshape2", "rgdal", "rgeos", "rgl", "rjags", "rosm", "roxygen2", "sf", "skmeans", "snow", "sp", "stm", "stringdist", "stringi", "stringr", "survival", "tau", "text2vec", "textcat", "textir", "textrank", "textreuse", "tidyr", "tidytext", "tidyverse", "tm", "tm.plugin.mail", "tm.plugin.webmining", "tokenizers", "topicmodels", "trotter", "udpipe", "utf8", "vcd", "venneuler", "vowels", "wordcloud", "wordnet", "xlsx", "xlsxjars", "xml2", "xtable", "yaml", "zipfR"), dependencies=TRUE, repos="http://cran.us.r-project.org")'

    echo "${CGRN}${BLD}==========> R LINGUISTICS AND GIS PACKAGE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping R LINGUISTICS AND GIS PACKAGE installation...${RST}"
fi


########################################
# INSTALL SPYDER IDE
########################################
if [[ "$SPYDERIDESW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing SPYDER IDE...${RST}"

    sudo -H pip3 install --system spyder

    echo "${CGRN}${BLD}==========> SPYDER IDE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping SPYDER IDE installation...${RST}"
fi


########################################
# INSTALL NLP SOFTWARE FROM STEFAN EVERT'S COURSE
########################################
if [[ "$NLPSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing NLP SOFTWARE...${RST}"

    # UPDATE DISTRO SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y

    # INSTALL DISTRO SOFTWARE
    sudo apt install -y --install-recommends csvkit csvkit-doc dos2unix ipython3 jupyter libopenblas-dev libxml2-dev libxml2-utils locales-all python-numpy-doc python-pandas-doc python-scipy-doc python-scrapy-doc python-sklearn-doc python-tweepy-doc python3-nltk python3-numpy python3-pandas python3-pip python3-regex python3-scipy python3-scrapy python3-sklearn python3-tweepy r-base-dev recode virtualenv

    # INSTALL PYTHON SOFTWARE
    sudo -H pip3 install --system cwb-python
    sudo -H pip3 install --system http://www.collocations.de/temp/PyCQP_interface-1.0.1.tar.gz


    echo "${CGRN}${BLD}==========> NLP SOFTWARE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping NLP SOFTWARE installation...${RST}"
fi


########################################
# INSTALL PRAAT GUI VERSION
########################################
if [[ "$PRAATSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing PRAAT GUI VERSION...${RST}"

    # SET INSTALL DIRECTORY, MAKE IT AND MOVE THERE
    INSTALLBASEDIR="${SWDIR}/praat"
    mkdir -p "${INSTALLBASEDIR}"
    cd "${INSTALLBASEDIR}" || exit

    # INSTALL DISTRO DEPENDENCIES
    sudo apt install -y --install-recommends fonts-sil-charis fonts-sil-charis-compact fonts-sil-doulos fonts-sil-doulos-compact

    ##########
    # DOWNLOAD LATEST GUI VERSION OF PRAAT
    ##########

    # DELETE THE PRAATHEADLESS DOWNLOAD WEB PAGE, IF IT EXISTS
    if [[ -f "download_linux.html" ]]; then
        rm download_linux.html
    fi

    # DOWNLOAD THE WEB PAGE THAT HAS THE DOWNLOAD LINKS FOR THE LATEST GUI VERSION OF PRAAT
    wget http://www.fon.hum.uva.nl/praat/download_linux.html

    # EXTRACT THE FILENAME FROM THE WEBPAGE
    PRAATFILENAME=$(cat download_linux.html | grep linux64.tar.gz | sed -r 's/^.+<a href=(.+\.tar.gz)>.+$/\1/')

    # DOWNLOAD THE LATEST GUI VERSION OF PRAAT
    wget "http://www.fon.hum.uva.nl/praat/$PRAATFILENAME"

    # UNCOMPRESS THE FILE AND DELETE THE .tar.gz AND .html FILES
    tar zxvf "${PRAATFILENAME}"
    rm -f "${PRAATFILENAME}"
    rm -f download_linux.html

    # MAKE THE FILE EXECUTABLE
    sudo chmod +x praat

    # DELETE ANY EXISTING SYMLINK TO /usr/local/bin AND MAKE A NEW ONE
    sudo rm -f /usr/local/bin/praat
    sudo ln -s "${INSTALLBASEDIR}/praat" /usr/local/bin/

    echo "${CGRN}${BLD}==========> PRAAT GUI VERSION installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping PRAAT GUI VERSION installation...${RST}"
fi


########################################
# INSTALL UCSTOOLKIT SOFTWARE
# INFO: http://www.collocations.de/software.html
########################################
if [[ "$UCSTOOLKITSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing UCS TOOLKIT...${RST}"

    # UPDATE DISTRO SOFTWARE
    sudo apt update -y
    sudo apt upgrade -y

    # INSTALL DISTRO DEPENDENCIES
    sudo apt install -y --install-recommends a2ps libexpect-perl libterm-readkey-perl libterm-readline-gnu-perl libtk-pod-perl

    # INSTALL PERL DEPENDENCIES
    sudo cpanm Expect Term::ReadKey Tk::Pod

    # MOVE TO INSTALL DIRECTORY
    cd /usr/local/share || exit

    # DOWNLOAD SOFTWARE
    sudo svn checkout svn://svn.code.sf.net/p/multiword/code/software/UCS/trunk UCS

    # CONFIGURE UCS INSTALLATION
    cd UCS/System || exit
    sudo perl Install.perl

    # CLEAN UP FILES
    sudo rm bin/*~

    # LINK CLI TOOLS TO PATH
    cd /usr/local/bin || exit
    sudo ln -s ../share/UCS/System/bin/ucs* .

    echo "${CGRN}${BLD}==========> UCS TOOLKIT installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping UCS TOOLKIT installation...${RST}"
fi


cwb_max_ram_usage_cli         = 1024
