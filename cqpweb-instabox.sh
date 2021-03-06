#!/bin/bash

SCRIPTNAME="cqpweb-instabox.sh"
# AUTHOR:   Scott Sadowsky
# WEBSITE:  www.sadowsky.cl
# DATE:     2019-11-25
# VERSION:  87
# LICENSE:  GNU GPL v3

# DESCRIPTION: This script takes an install of certain versions of Ubuntu or Debian and sets up Open
#              Corpus Workbench (OCWB) and CQPweb on it. It can also, optionally, install software and
#              configure the system for use as a headless server on bare metal, a headless server in
#              a virtual machine or a desktop with GUI for linguistic work.
#
#              It has been tested on:
#                - Ubuntu 18.04 LTS Live Server (the default download, aimed at cloud-based servers)
#                - Ubuntu 18.04 LTS Alternative Server (the traditional server)
#                - Ubuntu 18.04 LTS Desktop
#                - Lubuntu 18.04 Desktop
#                - Debian 9.9 Stable (note that newer versions of this script have not been tested on Debian yet).
#
#              While I've made every effort to make it work properly, it comes with no guarantees and
#              no warranties. Bug reports are most welcome!


# CHANGE LOG:
#
# v87
# - Added more exceptions to /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf to
#   prevent false positives when using CQPweb. Seems mod_security flags a lot of what CQPweb does as SQL exploits.
# - Added option to customize the titles of CQPweb pages. Set with CUSTPPGTITLES=1.
# - Extended the customizations done to the CQPweb signup page. Set with CUSTPGSIGNUP=1.
# - Added option to use a custom URL for user's own CQP syntax tutorial page. Set with CUSTCQPSYNTUTURL=1.
#
# v86
# - Added option to harden MySQL. Run script with `HARDENMYSQL=1` to use it.
# - Refined mod_evasive configuration.
# - Added a series of rule exceptions to mod_security to prevent false positives (and thus
#   breakages and bans) when using various CQPweb functions at paranoia level 2.
# - Added whitelisted IPs to mod_security configuration
# - Increased value of SecPcreMatchLimit and SecPcreMatchLimitRecursion to 500000 each in
#   /etc/modsecurity/modsecurity.conf to avoid "Execution error - PCRE limits exceeded (-8)" errors.
#
# v85
# - Added SSL to the server config, using certificates from Let's Encrypt. Set with SSLSW=1.
# - Further improved fail2ban configuration.
# - Vastly increased number of bad bots detected by apache-badbots module.
# - Fixed regression that disabled detection of $ETHERNET.
# - Fixed permissions and ownership of /var/log/apache2/modsec_audit.log
# - Added "Sensible Bash" settings to .bashrc (see <https://github.com/mrzool/bash-sensible>)
# - Configured `nano` using `.nanorc`.
#
# v84
# - Added script to find world-writable files.
# - Added `bat` to server install.
# - Log monitoring aliases and `byobu` screens now use `lnav` instead of `tail`.
# - Added install of `bashmarks`.
# - Implemented a fix for fail2ban's use of Debian paths on Ubuntu.
# - Configured `fail2ban` to ban port scanners logged by UFW and connection attempts over UDP.
#
# v83
# - Modernized and further hardened SSH configuration.
# - Fixed the ancient (2013) apache_badbots version that comes with Ubuntu's fail2ban version. New config
#   file is now taken from github, modified and installed.
# - Hardened a good number of sysctl.conf settings.
# - Added GRUB method of disabling ipv6.
# - Modified some php.ini settings. Among other things, errors are now logged to /var/log/php_errors.log
# - Removed MOSH. Great idea, unreliable implementation.
#
# v82
# - Added two new installation options, `vserver` and `vserverdeluxe`, for virtual servers (VPS).
# - Added support for MOSH (MObile SHell), a faster way of doing SSH.
# - Added several monitoring tools to server installs, such as `goaccess`.
# - Fixed error in CIDR notation converter for mod_evasive whitelist.
#
# v81
# - CQPweb: Added installation and configuration of the mod_security and mod_evasive Apache modules (server install).
# - CQPweb: Added installation and configuration of the OWASP mod_security core rule set.
# - OS: Added option to completely disable ipv6 support in host OS. This is set with `DISABLEIPV6=1`.
# - NETWORK: Overhauled the entire installation and configuration of fail2ban to take into account changes
#   that have appeared over time. More suggested software for it is also installed now.
# - OS: Removed a few settings in sysctl.conf that have been deprecated.
# - NETWORK: Hardened several SSH configuration options.
# - OS: Added installation of `sysstat` to server install.
# - CQPweb: Fixed three harmless but annoying errors in php.ini (loading gd2 and mysqli extensions improperly).
#
# v80
# - CQPweb: Added URL for CQPweb changelog to version-reporting script.
# - CQPweb: Set all log-monitoring aliases to display the last 25 lines.
# - NETWORK: Lengthened fail2ban bantime and findtime.
# - OS: Added installation of `debsums`, `apt-show-versions` packages.
#
# v79
# - Very minor fixes.
#
# v78
# - INTERNAL: Changed URL for my personal corpora.
# - OS: Added timezone info to test e-mail scripts.
#
# v77
# - CQPweb: Fixed permission issue with /css and /css/img directories.
# - CQPweb:  Now creates a script in ~/bin to test the CQPweb/PHP mail server.
# - OS: Midnight commander (mc) is now installed as part of Necessary Software.
#
# v76
# - Changed SourceForce URL to point to the new branch
# - Added autoremove to most package installation commands.
#
# v75
# - Fixed some folder and file ownership/permissions issues.
#
# v74
# - CQP+CWB:     Enchanced the version-check script that is created in ~/bin.
#
# v73
# - CQPweb:      Removed setting up Postfix mail server from installation presets. While this code does
#                  indeed install a working mail server, CQPweb does NOT use it, and can't send e-mails
#                  once it's installed! Downside: server utils like fail2ban now can't send e-mails.
# - CQPweb:      Added a confirmation dialog with warning when installing Postfix.
#
# v72
# - CQPweb:      Database update script now reloadgs and restarts apache2 after updating.
# - CQPweb:      Added option to replace the "Menu" text in the T/L corner of most pages with a custom graphic and a
#                  user-specified URL (on user home, query and admin pages).
#
# v71
# - CQPweb:      The fonts used in concordances are now customizable. A monospace font looks very nice there!
# - All:         Added a script to report versions of CQPweb, CWB, etc. (~/bin/version-report.sh).
# - CQPweb:      User can now choose to install MySQL 8 rather than the default version. WARNING: CQPweb does
#                  NOT currently work with MySQL 8.
#
# v70
# - All:         Made this script compatible with Debian (tested on Debian 9.9.0 stable). This
#                  involved more changes than can reasonably be documented here.
# - CQPweb:      Modified all code which had a specific PHP version hard-coded. It will now
#                  detect the current PHP version and do what must be done regardless of the version.
#
#
# v69
# - CQPweb:      Refactored code so that favicon and TL/TR image can be uploaded independently.
#
# v68
# - CQPweb:      Added ability to customize the font used by modifying all CSS files.
# - CQPweb:      Modified upd-all.sh script so it now automatically updates the CQPweb database.
# - CQPweb:      Refactored code that creates scripts in ~/bin so it can be run independently of
#                the rest of cqpweb-instabox.sh.
#
# v67
# - CQPweb:      Added creation of script to upgrade databases.
#
# v66
# - SSH PubKey:  SSH Public Key installation routine now installs certain software that would
#                otherwise only be installed if user chooses the "server" installation options.
#
# v65
# - CQPweb:      Fixed another bug in the offline frequency counting script.
#
# v64
# - CQPweb:      Fixed bug in creation of offline frequency counting script (in ~/bin).
#
# v63
# - All:         Added metaconfigurations and ability to select them from CLI.
# - CWB+CQPweb   Added script to facilitate off-line calculation of frequencies (in ~/bin).
# - CQPweb:      Bugfix: Lack of 'sudo' prevented /var/www/html/cqpweb from being created in certain conditions.
# - CWB+CQPweb:  Added text telling user what revision is being installed.
# - CQPweb:      Added variable to select whether or not to upload top left/right logo, along with variables for
#                  image source and destination.
#
# v62
# - CQPweb:      Adjusted syntax of empty strings in config.inc.php.
# - CQPweb:      Added creation of script for sending test e-mails via Postfix (in ~/bin).
# - CQPweb:      Added option to modify certain web pages (set CUSTPGSIGNUP=1).
# - CQPweb:      Added message to user telling them what IP address to open in browser to use CQPweb.
#
# v61
# - CQPweb:      Added install of php-json module.
#                Added code to upload favicon.ico to server.
# - Server SW:   Added install of 'ripgrep' and 'fd'.
# - Bash config: Added aliases for viewing various logs.
#
# v60
# - Initial release.
#
# v59 and below
# - Pre-release development.


# NOTE:
# - To get the mail server working, the following may be necessary:
#   · Replace the entry in /etc/hosts with the following:
#     127.0.0.1       localhost.localdomain localhost other_hostname fully_qualified-domain_name.com
#   · Uninstall postfix, and install sendmail and mailutils.
#   · Uninstall sendmail and then reinstall it.

################################################################################
# SCRIPT CONFIGURATION
# 0 disables, 1 enables, 2 (or anything else) disables and can mean whatever you
# want (e.g. 2 = "already run", so you can keep track of what you've done).
################################################################################

# SYSTEM CONFIGURATION
     UPGRADEOS=0    # Upgrade the OS and all its software packages to the latest versions.
   CONFIGSHELL=0    # Change default shell from dash to bash. Prevents certain errors.
    CONFIGBASH=0    # Configure .bashrc with some useful things.
      CONFIGTZ=0    # Set up time zone.
 CONFIGCONSOLE=0    # Configure the console's encoding, fonts, etc.
CONFIGKEYBOARD=0    # Configure the console's keyboard
CONFIGUBUCLOUD=0    # UBUNTU LIVE SERVER 18.04 ONLY: Remove certain cloud-specific components.
    CONFIGHOST=0    # UBUNTU LIVE SERVER 18.04 ONLY: Configure host information to fix bug.

# SSH CONFIGURATION
SSHGENNEWKEYS=0     # Generate new SSH keys and moduli. The latter will take around an hour.
     SSHPWDSW=0     # Install and configure SSH WITH PASSWORD ACCESS on the server, to allow remote administration.
# WARNING: Do not run SSHPWDSW and SSHKEYSW together! You must copy your SSH public key to the server in between!
     SSHKEYSW=0     # Reconfigure the SSH server for access using a PUBLIC KEY instead of a PASSWORD. A true MUST for security!
                    #    Do this only AFTER installing the SSH server with password access and uploading your pubic key to the server!

# MAIN SOFTWARE SETS
NECESSARYSW=0       # Install software necessary for the server to work.
   USEFULSW=0       # Install software considered useful (though optional).
   SERVERSW=0       # Install server software (monitoring, security and such).
 VIRTUALSRV=0       # Set to 1 for virtual servers (VPS). This uninstalls certain hardware-related software.

# CWB+CQPWEB+CORPORA
  CQPCWBRELEASE=0                           # Install a specific SubVersion release of CWB and CQPweb. "0" downloads latest version.
     SHORTSWDIR="software"                  # The directory in $HOME in which to download/install most software.
COMMONCQPWEBDIR="/usr/local/share/cqpweb"   # Common base dir for CQPweb. No trailing slash, please!
    NUKECORPORA=0                           # Delete ALL installed corpora. Not normally needed!

# CWB
CWB=0                    # Install CORPUS WORKBENCH (CWB)
  CWBVER="latest"        # Version of CWB to install: 'latest' or 'stable' (WARNING: Currently, only 'latest' is supported).
  CWBPLATFORM="linux-64" # Platform to compile CWPweb for. OPTIONS: cygwin, darwin, darwin-64, darwin-brew, darwin-port-core2,
                         #   darwin-universal, linux, linux-64, linux-opteron, mingw-cross, mingw-native, solaris, unix.
                         #   Keep in mind that this script has not been tested on many of these systems.
  CWBSITE="standard"     # Location for binary installation. 'standard'=/usr/local tree; 'beta-install'=/usr/local/cwb-<VERSION>.
  CWBNUKEOLD=0           # Delete previously downloaded CWB files before downloading and installing again? Not normally needed!

# CQPWEB
CQPWEBSW=0                  # Install CQPWEB SERVER.
ADMINUSER="YOUR_INFO_HERE"  # CQPweb administrator usernames. Separate multiple entries with | .
  MYSQL8=0                  # Install MySQL v. 8
  MYSQLDLURL="https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb" # URL for downloading the mysql .deb package. You may
                            # want to manually update this as new versions come out.
  DBUSER="cqpweb"           # Username for MYSQL database and webuser
  DBPWD="cqpweb"            # Password for MYSQL database and webuser
  CQPMAKENEWDB=0            # Delete existing database and make a new one? (NECESSARY for new installs; normally undesirable otherwise).
  CQPWEBNUKEOLD=0           # Delete previously downloaded CQPweb files before downloading and installing again? Not normally needed!

# CQPWEB OPTIONS AND CUSTOMIZATIONS.
# THESE CAN BE RUN INDEPENDENTLY OF THE INSTALLATION OF CQPWEB ITSELF!
IMAGEUPLD=0                  # Upload specified image to use as top left/right graphic in CQPweb. Set location and URL below.
  IMAGESOURCE1DIR="YOUR_INFO_HERE"  # URL of top left/right logo image source file PATH. No trailing slash!
  IMAGESOURCE1FILE="YOUR_INFO_HERE" # URL of top left/right logo image source file.
  IMAGESOURCE2DIR="YOUR_INFO_HERE"  # URL of an additional image source file PATH. No trailing slash!
  IMAGESOURCE2FILE="YOUR_INFO_HERE" # URL of an additional image source file.
  IMAGETARGET="/var/www/html/cqpweb/css/img"            # Destination path of top left/right logo image file.
FAVICONUPLD=0                # Upload favicon.ico to root of website?
  FAVICONSOURCE="YOUR_INFO_HERE" # Source URL of favicon.ico.
  FAVICONTARGET="/var/www/html/cqpweb/" # Destination directory of favicon.ico.
CREATECQPWEBSCRIPTS=0        # Create a series of useful scripts in ~/bin.
CUSTPGSIGNUP=0               # Customize CQPweb signup page. Users will definitely want to customize this customization.
CUSTPPGTITLES=0              # Customize the titles on CQPweb web pages.
  NEWPAGETITLE="Corpora.pro" # New page title. Will be processed by Perl, so escape what needs escaped.
CUSTCQPSYNTUTURL=0           # Change the CQP Syntax tutorial link, for using your own tutorial.
  CQPSYNTUTURL="https://www.corpora.pro/userpages/cqp-syntax-tutorial.html" # URL for your own CQP syntax tutorial. Will be processed by Perl, so escape as needed.
CUSTPGMENUGRAPHIC=1          # Replaces the word "Menu" in the T/L cell of most pages with a graphic ('IMAGESOURCE2', above) and optional URL.
  MENUURLUSER="YOUR_INFO_HERE"  # URL to assign to T/L graphic on user home pages.
  MENUURLQUERY="YOUR_INFO_HERE" # URL to assign to T/L graphic on query pages.
  MENUURLADMIN="YOUR_INFO_HERE" # URL to assign to T/L graphic on admin pages.
CUSTOMIZEFONTS=0             # Modify CSS files in order to use a user-specified Google web font for most of the interface and/or
                             #   for concordances. To customize one but not the other, set the font to emtpy ("") or "YOUR_INFO_HERE".
  MAINFONT="Open Sans"       # Name of Google web font for ALMOST EVERYTHING.
  CONCFONT="Overpass Mono"   # Name of Google web font for CONCORDANCE.
                             # Check out https://fonts.google.com/ for more web fonts. NOTE: Not all fonts seem to work in all browsers.
                             # CONFIRMED WORKING FONTS:
                             # [SANS]: Arimo, Fira Sans, Lato, Noto Sans, Open Sans, PT Sans, Raleway, Roboto, Roboto Condensed
                             # [MONO-SMALL]: Inconsolata, Ubuntu Mono
                             # [MONO-MID]: Oxygen Mono, Space Mono, Overpass Mono, Fira Mono, IBM Plex Mono, Source Code Pro
                             # [MONO-UGLY]test Anonymous Pro, B612 Mono, Cousine, PT Mono
TURNDEBUGON=0                # Set CQPweb to print debug messages.

# CORPORA
CORPDICKENS=0       # Install the Dickens SAMPLE CORPUS. Requires CWB already be installed.

# ADDITIONAL SERVER SOFTWARE AND CONFIGURATION
     MAILSW=0       # Install and configure the Postfix mail server.
      UPSSW=0       # Install and configure software for APC BackUPS Pro 900 UPS (051d:0002)
DISABLEIPV6=0       # Completely disable ipv6 support in the host OS.


# SECURITY SOFTWARE AND SYSTEM HARDENING
 SECURITYSW=0       # Install general security software. Highly recommended for server install.
      UFWSW=0       # Install and configure Universal FireWall (UFW). Important for security!
 FAIL2BANSW=0       # Install and configure fail2ban. Important for security! But install this last, after you've confirmed everything works.
WHITELISTEDIPS="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16" # IP addresses to whitelist (never ban) in fail2ban. Separate with space.
APACHESECSW=0       # Install the Apache mod_security and mod_evasive security modules.
      SSLSW=0       # Configure server to use SSL (HTTPS) with a certificate from Let's Encrypt.
HARDENMYSQL=0       # Harden the MySQL database. CPQweb must already be installed to use this.

# ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
FREELINGSW=0             # Install FreeLing tagger.
    FREELINGESCLMODS=0   # Modify FreeLing's Chilean Spanish install.
    FREELINGNUKEOLD=0    # Delete all downloaded FreeLing files before installing again.
PRAATHEADLESSSW=0        # Install headless Praat phonetic analysis software.
     VISIDATASW=0        # Install Visidata, an amazing TUI tool to manipulate and process CSV files.

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
#OS="$(cat /etc/lsb-release | grep DISTRIB_ID | sed -r 's/DISTRIB_ID=//')" # Distro name
OS="$(lsb_release -i -s)" # Distro name
RELEASE="$(lsb_release -r -s)"
ETHERNET="$(ip link show | grep '[0-9]: e[a-z0-9]*:' | sed -r 's/^.+ (e[a-z0-9]+):.+$/\1/')" # Ethernet adapter. NOT infallible! PROBABLY FAILS WITH 2+ ADAPTERS.
#ETHERNET=$(ifconfig | grep '^e' | sed -r 's/:.+$//')   # Ethernet adapter (older method). NOT infallible! PROBABLY FAILS WITH 2+ ADAPTERS.
EXTERNALIP="$(wget -qO - http://checkip.amazonaws.com)" # Server's external IP.
INTERNALIP="$(ip route get 1.2.3.4 | awk '{print $7}')" # Server's internal IP.
INTERNALIP2="$(ip addr show ${ETHERNET} | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')" # Server's internal IP (Method 2).
SWDIR="${HOME}/${SHORTSWDIR}"                           # Full software installation directory.
USERARG="$1"

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


# SET INFORMATIONAL TEXT ABOUT CWB+CQPweb RELEASE BEING INSTALLED
if [[ "$CQPCWBRELEASE" = 0 ]]; then
    CQPCWBRELEASETEXT="the ${CORG}most recent revision"
else
    CQPCWBRELEASETEXT="${CORG}revision ${CQPCWBRELEASE}"
fi

################################################################################
# SET VARIABLES FOR DIFFERENT TYPES OF INSTALL.
# PROVIDE INFO TO USER IF THEY SPECIFY NO ARGUMENT, TOO MANY ARGUMENTS, OR '-h'
################################################################################

# DEAL WITH VIRTUAL SERVERS FIRST
if [[ "$USERARG" = "vserver" ]]; then
    echo "virtual"
    USERARG="server"
    VIRTUALSRV=1
elif [[ "$USERARG" = "vserverdeluxe" ]]; then
    echo "virtual"
    USERARG="serverdeluxe"
    VIRTUALSRV=1
fi

# NOW PROCESS THE MAIN INSTALL TYPES
if [[ "$USERARG" = "default" ]]; then
    # USE VARIABLES AS SET ABOVE.
    echo ""
elif [[ "$USERARG" = "vm" ]]; then
    # SYSTEM CONFIGURATION
    UPGRADEOS=1
    CONFIGSHELL=0
    CONFIGBASH=1
    CONFIGTZ=0
    CONFIGCONSOLE=0
    CONFIGKEYBOARD=0
    CONFIGUBUCLOUD=0
    CONFIGHOST=0
    # SSH CONFIGURATION
    SSHGENNEWKEYS=0
    SSHPWDSW=0
    SSHKEYSW=0
    # MAIN SOFTWARE SETS
    NECESSARYSW=1
    USEFULSW=1
    SERVERSW=0
    # CWB+CQPWEB+CORPORA
#     CQPCWBRELEASE=0
    # CWB
    CWB=1
    CWBVER="latest"
    CWBPLATFORM="linux-64"
    CWBSITE="standard"
    # CQPWEB
    CQPWEBSW=1
    CQPMAKENEWDB=1
    IMAGEUPLD=0
    FAVICONUPLD=0
    # CORPORA
    CORPDICKENS=1
    # ADDITIONAL SYSTEM SOFTWARE
    MAILSW=0
    SECURITYSW=0
    UFWSW=0
    UPSSW=0
    FAIL2BANSW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
    FREELINGSW=0
    FREELINGESCLMODS=0
    FREELINGNUKEOLD=0
    PRAATHEADLESSSW=0
    VISIDATASW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: OS WITH GUI ONLY
    RSTUDIOSW=0
    RLINGPKGSW=0
    SPYDERIDESW=0
    NLPSW=0
    UCSTOOLKITSW=0
    PRAATSW=0
elif [[ "$USERARG" = "vmdeluxe" ]]; then
    echo "vmdeluxe"
    # SYSTEM CONFIGURATION
    UPGRADEOS=1
    CONFIGSHELL=0
    CONFIGBASH=1
    CONFIGTZ=0
    CONFIGCONSOLE=0
    CONFIGKEYBOARD=0
    CONFIGUBUCLOUD=0
    CONFIGHOST=0
    # SSH CONFIGURATION
    SSHGENNEWKEYS=0
    SSHPWDSW=0
    SSHKEYSW=0
    # MAIN SOFTWARE SETS
    NECESSARYSW=1
    USEFULSW=1
    SERVERSW=0
    # CWB+CQPWEB+CORPORA
#     CQPCWBRELEASE=0
    # CWB
    CWB=1
    CWBVER="latest"
    CWBPLATFORM="linux-64"
    CWBSITE="standard"
    # CQPWEB
    CQPWEBSW=1
    CQPMAKENEWDB=1
    IMAGEUPLD=0
    FAVICONUPLD=0
    # CORPORA
    CORPDICKENS=1
    # ADDITIONAL SYSTEM SOFTWARE
    MAILSW=0
    SECURITYSW=0
    UFWSW=0
    UPSSW=0
    FAIL2BANSW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
    FREELINGSW=0
    FREELINGESCLMODS=0
    FREELINGNUKEOLD=0
    PRAATHEADLESSSW=0
    VISIDATASW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: OS WITH GUI ONLY
    RSTUDIOSW=1
    RLINGPKGSW=1
    SPYDERIDESW=1
    NLPSW=1
    UCSTOOLKITSW=1
    PRAATSW=1
elif [[ "$USERARG" = "server" ]]; then
    echo "server"
    # SYSTEM CONFIGURATION
    UPGRADEOS=1
    CONFIGSHELL=1
    CONFIGBASH=1
    CONFIGTZ=1
    CONFIGCONSOLE=1
    CONFIGKEYBOARD=1
    CONFIGUBUCLOUD=0
    CONFIGHOST=0
    # SSH CONFIGURATION
    SSHGENNEWKEYS=1
    SSHPWDSW=1
    SSHKEYSW=0
    # MAIN SOFTWARE SETS
    NECESSARYSW=1
    USEFULSW=1
    SERVERSW=1
    # CWB+CQPWEB+CORPORA
#     CQPCWBRELEASE=0
    # CWB
    CWB=1
    CWBVER="latest"
    CWBPLATFORM="linux-64"
    CWBSITE="standard"
    # CQPWEB
    CQPWEBSW=1
    CQPMAKENEWDB=1
    IMAGEUPLD=0
    FAVICONUPLD=0
    # CORPORA
    CORPDICKENS=1
    # ADDITIONAL SYSTEM SOFTWARE
    MAILSW=0
    SECURITYSW=1
    UFWSW=1
    UPSSW=0
    FAIL2BANSW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
    FREELINGSW=0
    FREELINGESCLMODS=0
    FREELINGNUKEOLD=0
    PRAATHEADLESSSW=0
    VISIDATASW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: OS WITH GUI ONLY
    RSTUDIOSW=0
    RLINGPKGSW=0
    SPYDERIDESW=0
    NLPSW=0
    UCSTOOLKITSW=0
    PRAATSW=0
elif [[ "$USERARG" = "serverdeluxe" ]]; then
    echo "serverdeluxe"
    # SYSTEM CONFIGURATION
    UPGRADEOS=1
    CONFIGSHELL=1
    CONFIGBASH=1
    CONFIGTZ=1
    CONFIGCONSOLE=1
    CONFIGKEYBOARD=1
    CONFIGUBUCLOUD=0
    CONFIGHOST=0
    # SSH CONFIGURATION
    SSHGENNEWKEYS=1
    SSHPWDSW=1
    SSHKEYSW=0
    # MAIN SOFTWARE SETS
    NECESSARYSW=1
    USEFULSW=1
    SERVERSW=1
    # CWB+CQPWEB+CORPORA
#     CQPCWBRELEASE=0
    # CWB
    CWB=1
    CWBVER="latest"
    CWBPLATFORM="linux-64"
    CWBSITE="standard"
    # CQPWEB
    CQPWEBSW=1
    CQPMAKENEWDB=1
    IMAGEUPLD=0
    FAVICONUPLD=0
    # CORPORA
    CORPDICKENS=1
    # ADDITIONAL SYSTEM SOFTWARE
    MAILSW=0
    SECURITYSW=1
    UFWSW=1
    UPSSW=0
    FAIL2BANSW=1
    # ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
    FREELINGSW=0
    FREELINGESCLMODS=0
    FREELINGNUKEOLD=0
    PRAATHEADLESSSW=0
    VISIDATASW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: OS WITH GUI ONLY
    RSTUDIOSW=0
    RLINGPKGSW=0
    SPYDERIDESW=0
    NLPSW=0
    UCSTOOLKITSW=0
    PRAATSW=0
elif [[ "$USERARG" = "ssh" ]]; then
    echo "ssh"
    # SYSTEM CONFIGURATION
    UPGRADEOS=0
    CONFIGSHELL=0
    CONFIGBASH=0
    CONFIGTZ=0
    CONFIGCONSOLE=0
    CONFIGKEYBOARD=0
    CONFIGUBUCLOUD=0
    CONFIGHOST=0
    # SSH CONFIGURATION
    SSHGENNEWKEYS=0
    SSHPWDSW=0
    SSHKEYSW=1
    # MAIN SOFTWARE SETS
    NECESSARYSW=0
    USEFULSW=0
    SERVERSW=0
    # CWB+CQPWEB+CORPORA
#     CQPCWBRELEASE=0
    # CWB
    CWB=0
    CWBVER="latest"
    CWBPLATFORM="linux-64"
    CWBSITE="standard"
    # CQPWEB
    CQPWEBSW=0
    CQPMAKENEWDB=0
    IMAGEUPLD=0
    FAVICONUPLD=0
    # CORPORA
    CORPDICKENS=0
    # ADDITIONAL SYSTEM SOFTWARE
    MAILSW=0
    SECURITYSW=0
    UFWSW=0
    UPSSW=0
    FAIL2BANSW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: HEADLESS SERVER OR GUI
    FREELINGSW=0
    FREELINGESCLMODS=0
    FREELINGNUKEOLD=0
    PRAATHEADLESSSW=0
    VISIDATASW=0
    # ADDITIONAL LINGUISTIC SOFTWARE: OS WITH GUI ONLY
    RSTUDIOSW=0
    RLINGPKGSW=0
    SPYDERIDESW=0
    NLPSW=0
    UCSTOOLKITSW=0
    PRAATSW=0
else
    # PRINT INFORMATION IF -h IS SELECTED OR NO VALID ARGUMENT IS PROVIDED.
    echo ""
    echo "${CLBL}${BLD}===========================> WELCOME TO CQPWEB-INSTABOX <===========================${RST}"
    echo ""
    echo "${CWHT}${BLD}This script takes a Ubuntu install (ideally 18.04 LTS) and sets it up with${RST}"
    echo "${CWHT}${BLD}Open Corpus Workbench (CWB), CQPweb and other software of your choosing, making${RST}"
    echo "${CWHT}${BLD}a customized CQPwebInABox in just a few minutes.${RST}"
    echo ""
    echo "${CWHT}${BLD}Using CQPWEB-INSTABOX is a two-step process.${RST}"
    echo ""
    echo "${CWHT}${BLD}First, you must ${CGRN}edit this script${CWHT}, fill in all the fields marked ${CORG}YOUR_INFO_HERE${CWHT} with${RST}"
    echo "${CWHT}${BLD}appropriate values, save it, and run it again with the appropriate argument.${RST}"
    echo ""
    echo "${CWHT}${BLD}Second, you must ${CGRN}run this script with one of the following arguments${CWHT}:${RST}"
    echo "${CWHT}${BLD}  ${CORG}default${CWHT}       : Use the options that are configured in the script. This lets${RST}"
    echo "${CWHT}${BLD}                  you set up a customized install and deploy it.${RST}"
    echo "${CWHT}${BLD}  ${CORG}vm${CWHT}            : Set up a basic CWB and CQPweb install in a virtual machine.${RST}"
    echo "${CWHT}${BLD}  ${CORG}vmdeluxe${CWHT}      : Set up CWB, CQPweb and a series of other linguistics and NLP${RST}"
    echo "${CWHT}${BLD}                  software in a virtual machine.${RST}"
    echo "${CWHT}${BLD}  ${CORG}server${CWHT}        : Set up CWB, CQPweb and basic server software on a bare metal server${RST}"
    echo "${CWHT}${BLD}                  (headless or GUI).${RST}"
    echo "${CWHT}${BLD}  ${CORG}serverdeluxe${CWHT}  : Set up CWB, CQPweb and a suite of server-related software on${RST}"
    echo "${CWHT}${BLD}                  a bare metal server (headless or GUI).${RST}"
    echo "${CWHT}${BLD}  ${CORG}vserver${CWHT}       : Set up CWB, CQPweb and basic server software on a virtual server${RST}"
    echo "${CWHT}${BLD}                  aka VPS (headless or GUI).${RST}"
    echo "${CWHT}${BLD}  ${CORG}vserverdeluxe${CWHT} : Set up CWB, CQPweb and a suite of server-related software on${RST}"
    echo "${CWHT}${BLD}                  a virtual server aka VPS (headless or GUI).${RST}"
    echo "${CWHT}${BLD}  ${CORG}ssh${CWHT}           : Finish SSH setup after doing a server install.${RST}"
    echo "${CWHT}${BLD}  ${CORG}-h${CWHT}            : See this help message.${RST}"
    echo ""
    echo "${CWHT}${BLD}Note that the four server options install and configure SSH public key access. This${RST}"
    echo "${CWHT}${BLD}requires an additional step -- after the main install, you must upload your public${RST}"
    echo "${CWHT}${BLD}SSH key to the server and run this script again, this time with the ${CORG}ssh${CWHT} argument.${RST}"
    echo ""

    exit
fi


################################################################################
# PRINT WELCOME MESSAGE
################################################################################
echo ""
echo "${CLBL}${BLD}==========> WELCOME TO CQPWEB-INSTABOX <==========${RST}"
echo ""
echo "${CWHT}${BLD}            This script installs Open Corpus Workbench (CWB), CQPweb and other software.${RST}"
echo "${CWHT}${BLD}            You have selected the ${CGRN}${USERARG}${CWHT} installation option.${RST}"
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
    sudo apt autoremove -y
    sudo apt upgrade -y

    # INSTALL SOFTWARE THAT IS REQUIRED FOR EARLY OPERATIONS.
    sudo apt install -y --install-recommends apt-show-versions debsums gnupg software-properties-common apt-transport-https dirmngr rng-tools

    # FIX RNGTOOLS MISCONFIGURATION ON DEBIAN
    if [[ "$OS" = "Debian" ]]; then
        echo "HRNGDEVICE=/dev/urandom" | sudo tee -a /etc/default/rng-tools
    fi

    # PURGE ANY EXISTING MYSQL INSTALL IF MYSQL 8 IS TO BE INSTALLED.
    if [[ "$MYSQL8" = 1 ]]; then
        sudo apt purge -y mysql*
    fi

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

	# BAT SETTINGS
	export BAT_PAGER="less"
	export BAT_THEME="OneHalfDark"

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
	alias ga='goaccess /var/log/apache2/access.log'
	alias getip='wget -qO - http://wtfismyip.com/text'
	alias grep='grep --color=auto -i'
	alias j='jobs -l'
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
	alias ssc='sudo systemctl'
	alias ugr='sudo apt list --upgradable'

	# ALIASES FOR VIEWING LOGFILES
	alias alog='lnav /var/log/auth.log'
	alias apalog='lnav /var/log/apache2/access.log'
	alias apelog='lnav /var/log/apache2/error.log'
	alias flog='lnav /var/log/fail2ban.log'
	alias klog='lnav /var/log/kern.log'
	alias mlog='lnav /var/log/mail.log'
	alias mslog='lnav /var/log/apache2/modsec_audit.log'
	alias mylog='lnav /var/log/mysql/error.log'
	alias plog='lnav /var/log/php_errors.log'
	alias slog='lnav /var/log/syslog'
	alias ulog='lnav /var/log/ufw.log'
	alias upslog='lnav /var/log/apcupsd.events'

	# LINGUISTIC THINGS
	alias cqp='cqp -eC'

	# SOURCE BASHMARKS
	source ~/.local/bin/bashmarks.sh

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

	############################################################
	# Sensible Bash - An attempt at saner Bash defaults
	# Maintainer: mrzool <http://mrzool.cc>
	# Repository: https://github.com/mrzool/bash-sensible
	# Version: 0.2.2
	############################################################

	# Unique Bash version check
	if ((BASH_VERSINFO[0] < 4))
	then
	  echo "sensible.bash: Looks like you're running an older version of Bash."
	  echo "sensible.bash: You need at least bash-4.0 or some options will not work correctly."
	  echo "sensible.bash: Keep your software up-to-date!"
	fi

	## GENERAL OPTIONS ##

	# Prevent file overwrite on stdout redirection
	# Use `>|` to force redirection to an existing file
	# DANGER: THIS OPTION BREAKS BASHMARKS!
	#set -o noclobber

	# Update window size after every command
	shopt -s checkwinsize

	# Automatically trim long paths in the prompt (requires Bash 4.x)
	PROMPT_DIRTRIM=3

	# Enable history expansion with space
	# E.g. typing !!<space> will replace the !! with your last command
	bind Space:magic-space

	# Turn on recursive globbing (enables ** to recurse all directories)
	shopt -s globstar 2> /dev/null

	# Case-insensitive globbing (used in pathname expansion)
	shopt -s nocaseglob;

	## SMARTER TAB-COMPLETION (Readline bindings) ##

	# Perform file completion in a case insensitive fashion
	bind "set completion-ignore-case on"

	# Treat hyphens and underscores as equivalent
	bind "set completion-map-case on"

	# Display matches for ambiguous patterns at first tab press
	bind "set show-all-if-ambiguous on"

	# Immediately add a trailing slash when autocompleting symlinks to directories
	bind "set mark-symlinked-directories on"

	## SANE HISTORY DEFAULTS ##

	# Append to the history file, don't overwrite it
	shopt -s histappend

	# Save multi-line commands as one command
	shopt -s cmdhist

	# Record each line as it gets issued
	PROMPT_COMMAND='history -a'

	# Huge history. Doesn't appear to slow things down, so why not?
	HISTSIZE=500000
	HISTFILESIZE=100000

	# Avoid duplicate entries
	HISTCONTROL="erasedups:ignoreboth"

	# Don't record some commands
	export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

	# Use standard ISO 8601 timestamp
	# %F equivalent to %Y-%m-%d
	# %T equivalent to %H:%M:%S (24-hours format)
	HISTTIMEFORMAT='%F %T '

	# Enable incremental history search with up/down arrows (also Readline goodness)
	# Learn more about this here: http://codeinthehole.com/writing/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/
	bind '"\e[A": history-search-backward'
	bind '"\e[B": history-search-forward'
	bind '"\e[C": forward-char'
	bind '"\e[D": backward-char'

	## BETTER DIRECTORY NAVIGATION ##

	# Prepend cd to directory names automatically
	shopt -s autocd 2> /dev/null
	# Correct spelling errors during tab-completion
	shopt -s dirspell 2> /dev/null
	# Correct spelling errors in arguments supplied to cd
	shopt -s cdspell 2> /dev/null

	# This defines where cd looks for targets
	# Add the directories you want to have fast access to, separated by colon
	# Ex: CDPATH=".:~:~/projects" will look for targets in the current working directory, in home and in the ~/projects folder
	CDPATH="."

	# This allows you to bookmark your favorite places across the file system
	# Define a variable containing a path and you will be able to cd into it regardless of the directory you're in
	shopt -s cdable_vars

	# Examples:
	# export dotfiles="$HOME/dotfiles"
	# export projects="$HOME/projects"
	# export documents="$HOME/Documents"
	# export dropbox="$HOME/Dropbox"

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
        sudo echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg >/dev/null 2>&1

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
    sudo apt autoremove -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends figlet openssh-sftp-server ssh-askpass sshfs lolcat toilet toilet-fonts

    # INSTALL ON EVERYTHING BUT DEBIAN. THERE SEEM TO BE NO DEBIAN EQUIVALENTS AVAILABLE IN 9.9.0 REPOS
    if ! [[ "$OS" = "Debian" ]]; then
        sudo apt install -y --install-recommends ssh-audit landscape-common
    fi

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

        # UPDATE AND INSTALL SOFTWARE
        sudo apt update -y
        sudo apt autoremove -y
        sudo apt upgrade -y
        sudo apt install -y --install-recommends figlet openssh-sftp-server ssh-askpass sshfs lolcat toilet toilet-fonts

        # INSTALL ON EVERYTHING BUT DEBIAN. THERE SEEMS TO BE NO DEBIAN PACKAGE AVAILABLE FOR THIS.
        if ! [[ "$OS" = "Debian" ]]; then
            sudo apt install -y --install-recommends ssh-audit landscape-common
        fi

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
        configLine "^[# ]*AllowAgentForwarding.*$"            "AllowAgentForwarding no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*AllowTcpForwarding.*$"              "AllowTcpForwarding no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*AllowUsers.*$"                      "AllowUsers ${USER}" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*AllowGroups.*$"                     "AllowGroups ${USER}" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*AuthorizedKeysFile.*$"              "AuthorizedKeysFile %h/.ssh/authorized_keys" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ChallengeResponseAuthentication.*$" "ChallengeResponseAuthentication no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Ciphers.*$"                         "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ClientAliveCountMax.*$"             "ClientAliveCountMax 2" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ClientAliveInterval.*$"             "ClientAliveInterval 60" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Compression.*$"                     "Compression no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*DenyGroups.*$"                      "DenyGroups root" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*DenyUsers.*$"                       "DenyUsers root" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*HostbasedAuthentication.*$"         "HostbasedAuthentication no" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*IgnoreRhosts.*$"                    "IgnoreRhosts yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*KexAlgorithms.*$"                   "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*LogLevel.*$"                        "LogLevel VERBOSE"       /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*LoginGraceTime.*$"                  "LoginGraceTime 20"      /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*MACs.*$"                            "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com"              /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*MaxAuthTries.*$"                    "MaxAuthTries 3"         /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*MaxSessions.*$"                     "MaxSessions 4"          /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PasswordAuthentication.*$"          "PasswordAuthentication yes" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PermitEmptyPasswords.*$"            "PermitEmptyPasswords no"    /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PermitRootLogin.*$"                 "PermitRootLogin no"    /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Port [0-9]*$"                       "Port ${SSHPORT}"       /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PrintLastLog.*$"                    "PrintLastLog yes"      /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*PrintMotd.*$"                       "PrintMotd yes"         /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Protocol.*$"                        "Protocol 2"            /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ClientAliveCountMax.*$"             "ClientAliveCountMax 3" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*ClientAliveInterval.*$"             "ClientAliveInterval 5" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*StrictModes.*$"                     "StrictModes yes"       /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*TCPKeepAlive.*$"                    "TCPKeepAlive no"       /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*UsePAM.*$"                          "UsePAM no"             /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*X11Forwarding.*$"                   "X11Forwarding no"      /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*Subsystem[ \\t]*sftp.*$"            ""                      /etc/ssh/sshd_config >/dev/null 2>&1

        # DON'T SORT THESE NEXT THREE ENTRIES
        configLine "^[# ]*HostKey.*$"                         "" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*HostKey \/etc\/ssh\/ssh_host_ed25519.*$" "HostKey /etc/ssh/ssh_host_ed25519_key" /etc/ssh/sshd_config >/dev/null 2>&1
        configLine "^[# ]*HostKey \/etc\/ssh\/ssh_host_rsa.*$" "HostKey /etc/ssh/ssh_host_rsa_key" /etc/ssh/sshd_config >/dev/null 2>&1


        # RECONFIGURE SSH_CONFIG FILE
        configLine "^[# ]*Ciphers.*$"                         "    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" /etc/ssh/ssh_config  >/dev/null 2>&1
        configLine "^[# ]*GSSAPIAuthentication.*$"            "    GSSAPIAuthentication no" /etc/ssh/ssh_config >/dev/null 2>&1
        configLine "^[# ]*KexAlgorithms.*$"                   "    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" /etc/ssh/ssh_config >/dev/null 2>&1
        configLine "^[# ]*MACs.*$"                            "    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" /etc/ssh/ssh_config  >/dev/null 2>&1


        # RESTORE BACKUP OF /etc/profile IF IT EXISTS, ELSE MAKE A BACKUP
        if [[ -f /etc/profile.BAK ]]; then
            sudo rm /etc/profile
            sudo cp /etc/profile.BAK /etc/profile
        else
            sudo cp /etc/profile /etc/profile.BAK
        fi

        # ADD LANDSCAPE-SYSINFO COMMAND TO EVERYTHING BUT DEBIAN
        if [[ "$OS" = "Debian" ]]; then
            LANDSCAPE=""
        else
            LANDSCAPE="landscape-sysinfo"
        fi


        # ADD MESSAGE TO /ETC/PROFILE
        sudo tee -a /etc/profile <<- EOF >/dev/null 2>&1
		# FOR SOME REASON, AT LEAST ON UBUNTU SERVER 18.04.3, LOCALE MUST BE NOW BE SET
		# HERE IN ORDER TO PREVENT ERRORS WITH LOLCAT AND OTHER, MORE IMPORTANT SOFTWARE.
		export LC_ALL="en_US.UTF-8"
		#
		# LOGIN MESSAGE added by ${SCRIPTNAME} on ${DATE}
		BOLDWHITE='\033[1;36m'
		NC='\033[0m'
		MYUSER=\$(whoami)
		MYHOST=\$(hostname)
		echo ""
		MYIP=\$(wget -qO - http://wtfismyip.com/text)
		toilet -f ivrit -t -F border:crop \$MYHOST | lolcat -p 1
		$LANDSCAPE
		echo ""
		echo -e "You are \${BOLDWHITE}\${MYUSER}@\${MYHOST}\${NC} on \${BOLDWHITE}\${MYIP}\${NC}."
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
        echo "${CWHT}${BLD}            Do configure your router to forward ports ${SSHPORT} and ${MOSHPORT} to the server's local IP address${RST}"
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

    sudo apt update -y
    sudo apt autoremove -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends figlet landscape-common lolcat toilet

    echo ""
    echo "${CRED}${BLD}==========> Configuring SSH VIA PUBLIC KEY ==========${RST}"

    # RECONFIGURE SSHD_CONFIG FILE
    configLine "^[# ]*PasswordAuthentication.*$"              "PasswordAuthentication no" /etc/ssh/sshd_config >/dev/null >/dev/null 2>&1
    configLine "^[# ]*PubkeyAuthentication.*$"                "PubkeyAuthentication yes" /etc/ssh/sshd_config >/dev/null >/dev/null 2>&1

    # RECONFIGURE SSH_CONFIG FILE
    configLine "^[# ]*ChallengeResponseAuthentication.*$" "    ChallengeResponseAuthentication no" /etc/ssh/ssh_config >/dev/null >/dev/null 2>&1
    configLine "^[# ]*HostKeyAlgorithms.*$"               "    HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa" /etc/ssh/ssh_config >/dev/null 2>&1
    configLine "^[# ]*PasswordAuthentication.*$"          "    PasswordAuthentication no" /etc/ssh/ssh_config >/dev/null >/dev/null 2>&1
    configLine "^[# ]*PubkeyAuthentication.*$"            "    PubkeyAuthentication yes" /etc/ssh/ssh_config >/dev/null >/dev/null 2>&1

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
    echo "${CWHT}${BLD}            Once you've done this, you can connect with nothing more than ${CORG}ssh ${LOCALHOSTNAME}${CWHT}${RST}."
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
    # ADD MOST UP-TO-DATE R REPOSITORY IF IT'S NOT ALREADY INSTALLED.
    # NOT INSTALLED ON DEBIAN 9.9.0 AS R DEPENDS ON PACKAGES THAT ARE FAR MORE RECENT THAT DEBIAN'S.
    ####################

    # ADD UP-TO-DATE R REPOSITORY ON EVERYTHING BUT DEBIAN
    if ! [[ "$OS" = "Debian" ]]; then
        # ADD CRAN35 KEY
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

        # ADD CRAN35 REPOSITORY EXCEPT ON DEBIAN
        if ! grep -q "^deb .*cran35" /etc/apt/sources.list /etc/apt/sources.list.d/* 2> /dev/null; then
            sudo apt-add-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu/ bionic-cran35/'
        else
            echo "${CWHT}${BLD}            The cran35 respository is already installed.${RST}"
            echo ""
        fi
    fi

    # UPDATE AND INSTALL SOFTWARE
    sudo apt update -y
    sudo apt autoremove -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends aria2 autoconf automake build-essential curl dos2unix gcc git locales-all make mc members mercurial openssh-server openssl pkg-config recode subversion unicode wget


    # INSTALL ON DEBIAN ONLY
    if [[ "$OS" = "Debian" ]]; then
        sudo apt install -y --install-recommends linux-headers-$(uname -r)
    else
        # INSTALL ON EVERYTHING BUT DEBIAN
        sudo apt install -y --install-recommends linux-headers-generic
    fi

    # REMOVE UNNECESSARY OR RISKY SOFTWARE
    sudo apt remove --purge -y -f telnet ftp


    # CONFIGURE NANO FOR USER
    rm -f ~/.nanorc

    tee -a ~/.nanorc <<- EOF >/dev/null 2>&1
	#set linenumbers
	set smooth
	set softwrap
	set atblanks
	set tabsize 4
	set smooth
	set smarthome
	set tabstospaces

	# Paint the interface elements of nano.  These are examples;
	# by default there are no colors, except for errorcolor.
	set titlecolor brightwhite,blue
	set statuscolor brightwhite,green
	set selectedcolor brightwhite,magenta
	set numbercolor cyan
	set keycolor brightcyan
	set functioncolor green

EOF

    # CONFIGURE NANO FOR ROOT. HAS RED HIGHLIGHTS.
    sudo rm -f /root/.nanorc

    sudo tee -a /root/.nanorc <<- EOF >/dev/null 2>&1
	#set linenumbers
	set smooth
	set softwrap
	set atblanks
	set tabsize 4
	set smooth
	set smarthome
	set tabstospaces

	# Paint the interface elements of nano.  These are examples;
	# by default there are no colors, except for errorcolor.
	set titlecolor brightwhite,red
	set statuscolor brightwhite,red
	set selectedcolor brightwhite,magenta
	set numbercolor cyan
	set keycolor brightcyan
	set functioncolor green

EOF


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
    sudo apt autoremove -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends bzip2 exfat-fuse exfat-utils lbzip2 mc moreutils most neofetch p7zip p7zip-full pbzip2 python3-pip rename tldr unzip w3m zip

    # INSTALL ON DEBIAN ONLY
    if [[ "$OS" = "Debian" ]]; then
        sudo apt install -y --install-recommends unrar-free
    else
        # INSTALL ON EVERYTHING BUT DEBIAN
        sudo apt install -y --install-recommends p7zip-rar unrar
    fi


    # INSTALL BASHMARKS
    mkdir -p ~/tmp
    cd ~/tmp
    git clone git://github.com/huyng/bashmarks.git
    cd bashmarks
    sudo make install
    cd ..
    rm -rf ~/tmp/bashmarks


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

    ####################
    # INSTALL MAIN DISTRO SOFTWARE
    ####################
    sudo apt update -y
    sudo apt upgrade -y

    # INSTALL THE FOLLOWING SOFTWARE IN ALL CASES
    sudo apt install -y --install-recommends acct apachetop apt-listchanges apticron byobu ccze cpulimit discus figlet goaccess htop hwinfo iftop iotop iptraf iptstate iselect lnav locate lolcat mytop net-tools nethogs nload nmap nmon pv rng-tools screen screenie speedometer speedtest-cli tmux traceroute unattended-upgrades vnstat w3m whowatch

    # ONLY INSTALL THE FOLLOWING SOFTWARE IF THE INSTALL IS *NOT* A VPS
    if ! [[ "$VIRTUALSRV" = 1 ]]; then
        sudo apt install -y --install-recommends fancontrol hddtemp lm-sensors powertop smartmontools
    fi

    # THIS IS INSTALLED ALONE BECAUSE --install-recommends PULLS IN FAR TO MUCH USELESS SOFTWARE
    sudo apt install -y sysstat

    # INSTALL ON EVERYTHING BUT DEBIAN
    if ! [[ "$OS" = "Debian" ]]; then
        sudo apt install -y --install-recommends mytop
    fi

    # CONFIGURE TMUX TO DISPLAY 256 COLORS
    echo "set -g default-terminal \"screen-256color\"" > ~/.tmux.conf


    ####################
    # DISABLE ROOT ACCOUNT. TO ENABLE IT AGAIN: sudo passwd -u root
    ####################
#     sudo passwd -l root


    ####################
    # ENABLE SYSSTAT
    ####################

    # RESTORE BACKUP OF /etc/default/sysstat IF IT EXISTS, ELSE MAKE A BACKUP
    if [[ -f /etc/default/sysstat.BAK ]]; then
        sudo rm /etc/default/sysstat
        sudo cp /etc/default/sysstat.BAK /etc/default/sysstat
    else
        sudo cp /etc/default/sysstat /etc/default/sysstat.BAK
    fi

    # ENABLE SYSSTAT
    configLine "^ENABLED[ =]*.*" 'ENABLED="true"'  /etc/default/sysstat


    # RESTORE BACKUP OF /etc/cron.d/sysstat IF IT EXISTS, ELSE MAKE A BACKUP
    if [[ -f /etc/cron.d/sysstat.BAK ]]; then
        sudo rm /etc/cron.d/sysstat
        sudo cp /etc/cron.d/sysstat.BAK /etc/cron.d/sysstat
    else
        sudo cp /etc/cron.d/sysstat /etc/cron.d/sysstat.BAK
    fi

    # SHORTEN REPORTING INTERVAL FROM 10 TO 2 MINUTES
    configLine "^[ ]*5-55\/10.*$"  "*/2 * * * * root command -v debian-sa1 > /dev/null \&\& debian-sa1 1 1"  /etc/cron.d/sysstat


    ####################
    # INSTALL GOACCESS
    ####################

    # INSTALL GEOIP DATABASE
    mkdir -p ~/bin/GeoIP
    cd  ~/bin/GeoIP
    wget -N https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
    tar --strip-components=1 -zxf GeoLite2-City.tar.gz

    # INSTALL GOACCESS DEPENDENCIES
    sudo apt update -y
    sudo apt install -y --install-recommends libmaxminddb0 libmaxminddb-dev mmdb-bin libncursesw5-dev libtokyocabinet-dev

    # DOWNLOAD GOACCESS SOURCE TARBALL
    mkdir -p ~/tmp
    cd ~/tmp
    wget https://tar.goaccess.io/goaccess-1.3.tar.gz
    tar -xzvf goaccess-1.3.tar.gz
    cd goaccess-1.3/
    ./configure --enable-utf8 --enable-geoip=mmdb --enable-tcb=btree --with-getline --with-openssl
    make
    sudo make install

    # CREATE GOACCESS CONFIG FILE FROM TEMPLATE
    sudo cp /usr/local/etc/goaccess/goaccess.conf /usr/local/etc/goaccess.conf

    ##### MODIFY CONFIG FILE

    # Prepare list of excluded IPs from whitelisted IPs
    EXCLUDEIPS="${WHITELISTEDIPS}"
    # Change CIDR notation to ranges separated by dashes (only works for /8, /16 and /24).
    EXCLUDEIPS=$(echo "${EXCLUDEIPS}" | sed -r 's#([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/8#\1.\2.\3.1-\1.255.255.254#gm')
    EXCLUDEIPS=$(echo "${EXCLUDEIPS}" | sed -r 's#([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/16#\1.\2.\3.1-\1.\2.255.254#gm')
    EXCLUDEIPS=$(echo "${EXCLUDEIPS}" | sed -r 's#([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/24#\1.\2.\3.1-\1.\2.\3.254#gm')
    # Insert '\n' and 'exclude-ip' before each ip
    EXCLUDEIPS=$(echo "${EXCLUDEIPS}" | sed -r 's/(^| )/\nexclude-ip /gm')

    # Modify goaccess config file values
    configLine "^[# ]*log-format COMBINED.*$"    "log-format COMBINED" /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*agent-list false.*$"       "agent-list true"     /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*exclude-ip 127.0.0.1.*$"   "$EXCLUDEIPS"         /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*log-format COMBINED.*$"    "log-format COMBINED" /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*ignore-panel REFERRERS.*$" "#ignore-panel REFERRERS" /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*ignore-panel KEYPHRASES.*$" "#ignore-panel KEYPHRASES" /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*ignore-referer \*.domain.com.*$" "ignore-referer ${SERVERNAME}\\nignore-referer ${SERVERALIAS}" /usr/local/etc/goaccess.conf >/dev/null 2>&1
    configLine "^[# ]*geoip-database \/usr\/local\/share\/GeoIP\/GeoLiteCity.dat.*$"  "geoip-database /home/corpadmin/bin/GeoIP/GeoLite2-City.mmdb" /usr/local/etc/goaccess.conf >/dev/null 2>&1


    ####################
    # INSTALL MONITORING SOFTWARE
    ####################
    sudo -H pip3 install --system glances
    sudo -H pip3 install --system s-tui

    ####################
    # INSTALL RIPGREP (https://github.com/BurntSushi/ripgrep/)
    ####################
    if [[ "$OS" = "Debian" ]]; then
        # ON DEBIAN
        curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.1/ripgrep_11.0.1_amd64.deb
        sudo dpkg -i ripgrep_11.0.1_amd64.deb
    else
        # ON EVERYTHING BUT DEBIAN
        sudo mkdir -p /tmp/rg               # MAKE TEMP DIR
        sudo chmod -R ugo=rwx /tmp/rg       # CHANGE PERMISSIONS OF TEMP DIR
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
    fi

    ####################
    # INSTALL FD
    ####################
    sudo mkdir -p /tmp/fd               # MAKE TEMP DIR
    sudo chmod -R ugo=rwx /tmp/fd       # CHANGE PERMISSIONS OF TEMP DIR
    cd /tmp/fd || exit                  # MOVE INTO TEMP DIR

    # ASSEMBLE FILENAME
    if [[ "$OS" = "Debian" ]]; then
        # DOWNLOAD THE GITHUB "LATEST" PAGE, WHICH REDIRECTS TO A PAGE WITH THE LATEST VERSION NUMBER IN ITS URL, AND EXTRACT THAT LINE
        FDLATESTVER=$(aria2c https://github.com/sharkdp/fd/releases/latest | grep 'Download complete')
        FDLATESTVER="$(perl -p0e 's/^.+\/fd\/v([0-9.]+).*$/$1/gsm' <<< $FDLATESTVER)"   # STRIP EVERYTHING EXCEPT VERSION NUMBER
        # ASSEMBLE THE DEB FILE NAME
        FDPATH="https://github.com/sharkdp/fd/releases/download/v${FDLATESTVER}"
        # ASSEMBLE FILENAME FOR DEBIAN
        FDFILENAME="fd-musl_${FDLATESTVER}_amd64.deb"
    else
        # DOWNLOAD THE GITHUB "LATEST" PAGE, WHICH REDIRECTS TO A PAGE WITH THE LATEST VERSION NUMBER IN ITS URL, AND EXTRACT THAT LINE
        FDLATESTVER=$(aria2c https://github.com/sharkdp/fd/releases/latest | grep 'Redirecting to')
        FDLATESTVER="$(sed -r 's/^.+\/tag\/v//' <<< $FDLATESTVER)"   # STRIP EVERYTHING BUT VERSION NUMBER FROM EXTRACTED LINE
        # ASSEMBLE THE DEB FILE NAME
        FDPATH="https://github.com/sharkdp/fd/releases/download/v${FDLATESTVER}"
        # ASSEMBLE FILENAME FOR EVERYTHING BUT DEBIAN
        FDFILENAME="fd_${FDLATESTVER}_amd64.deb"
    fi

    curl -LO "${FDPATH}/${FDFILENAME}"      # DOWNLOAD THE DEB FILE
    sudo dpkg -i "${FDFILENAME}"            # INSTALL THE DEB FILE
    sudo rm -rf /tmp/fd                     # DELETE THE TMP DIRECTORY AND ITS CONTENTS


    ####################
    # INSTALL bat (https://github.com/sharkdp/bat)
    # This installs 0.12.1. It will need to be manually updated.
    ####################
    mkdir -p ~/tmp
    cd ~/tmp
    wget https://github.com/sharkdp/bat/releases/download/v0.12.1/bat_0.12.1_amd64.deb
    sudo dpkg -i bat_0.12.1_amd64.deb
    rm bat_0.12.1_amd64.deb


    echo "${CGRN}${BLD}==========> SERVER SOFTWARE installation finished.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping SERVER SOFTWARE installation...${RST}"
fi



#######################################################
# MODIFY SERVERS IF THEY'RE VIRTUAL (VPS)
#######################################################
if [[ "$VIRTUALSRV" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Configuring VIRTUAL SERVER...${RST}"

    sudo apt update -y
    sudo apt upgrade -y

    # REMOVE UNNECESSARY OR RISKY SOFTWARE
    # This is done one-package-per-command because otherwise if a single program
    # is not installed, it will cause the removal of all the others to fail.
    sudo apt remove --purge -y -f fancontrol thermald smartmontools lm-sensors powertop hddtemp psensor libsensors4 exfat-fuse exfat-utils
    sudo apt autoremove -y

    echo "${CGRN}${BLD}==========> VIRTUAL SERVER configured.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping configuration of VIRTUAL SERVER...${RST}"

    fi

#######################################################
# COMPLETELY DISABLE IPV6 SUPPORT ON HOST OS IF DESIRED
#######################################################
if [[ "$DISABLEIPV6" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Disabling IPV6 SUPPORT...${RST}"

    # ADD NECESSARY VALUES TO /etc/sysctl.conf
    configLine "^[ ]*net.ipv6.conf.all.disable_ipv6.*$"     "net.ipv6.conf.all.disable_ipv6=1"     /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[ ]*net.ipv6.conf.default.disable_ipv6.*$" "net.ipv6.conf.default.disable_ipv6=1" /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[ ]*net.ipv6.conf.lo.disable_ipv6.*$"      "net.ipv6.conf.lo.disable_ipv6=1"      /etc/sysctl.conf >/dev/null 2>&1

    ##### CREATE SCRIPT TO MAKE SURE THESE KERNEL PARAMS ARE READ AT BOOT TIME

    # MAKE BACKUP OF /etc/rc.local IF THE FILE EXISTS, ELSE CREATE THE FILE
    if [[ -f /etc/rc.local ]]; then
        sudo cp /etc/rc.local /etc/rc.local.BAK
    else
        sudo touch /etc/rc.local
    fi

    # WRITE CONTENTS TO /etc/rc.local
    sudo tee -a /etc/rc.local <<- EOF >/dev/null 2>&1
	#!/bin/bash
	# /etc/rc.local

	/etc/sysctl.d
	/etc/init.d/procps restart

	exit 0

EOF

    ##### MAKE /etc/rc.local EXECUTABLE
    sudo chmod 755 /etc/rc.local

    ##### RELOAD CONFIG FILE TO MAKE CHANGES HAPPEN NOW.
    sudo sysctl -p >/dev/null 2>&1

    ##### FORCE apt TO USE IPV4

    # MAKE BACKUP OF /etc/rc.local IF THE FILE EXISTS, ELSE CREATE THE FILE
    if [[ -f /etc/apt/apt.conf.d/99force-ipv4 ]]; then
        sudo cp /etc/apt/apt.conf.d/99force-ipv4 /etc/apt/apt.conf.d/99force-ipv4.BAK
    else
        sudo touch /etc/apt/apt.conf.d/99force-ipv4
    fi

    # WRITE CONTENTS TO /etc/rc.local
    sudo tee -a /etc/apt/apt.conf.d/99force-ipv4 <<- EOF >/dev/null 2>&1
    Acquire::ForceIPv4 "true";

EOF

    #####
    # CHANGE GRUB SETTINGS TO DISABLE IPV6. THIS MAY BE UNNECESSARY DUE TO THE
    # PREVIOUS SECTIONS, BUT IT'S HERE FOR GOOD MEASURE.
    #####

    # IF BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP
    if [[ -f "/etc/default/grub.BAK" ]]; then
        # RESTORE BACKUP
        sudo rm /etc/default/grub
        sudo cp /etc/default/grub.BAK /etc/default/grub
    else
        # MAKE BACKUP
        sudo cp /etc/default/grub /etc/default/grub.BAK
    fi

    # CHANGE FILE
    configLine "^[# ]*GRUB_CMDLINE_LINUX_DEFAULT.*$"  "GRUB_CMDLINE_LINUX_DEFAULT=\"maybe-ubiquity ipv6.disable=1\"" /etc/default/grub >/dev/null 2>&1
    configLine "^[# ]*GRUB_CMDLINE_LINUX=.*$"         "GRUB_CMDLINE_LINUX=\"ipv6.disable=1\"" /etc/default/grub >/dev/null 2>&1

    # UPDATE GRUB
    sudo update-grub


    echo "${CGRN}${BLD}==========> IPV6 SUPPORT disabled.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping disabling of IPV6 SUPPORT...${RST}"
fi


########################################
# SET UP SSL (HTTPS) USING LET'S ENCRYPT CERTIFICATE.
########################################
if [[ "$SSLSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing SSL (HTTPS) with Let's Encrypt certificate...${RST}"

    # ADD CERTBOT PPA
    sudo add-apt-repository ppa:certbot/certbot

    # UPDATE DISTRO SOFTWARE
    sudo apt update -y
    sudo apt autoremove -y
    sudo apt upgrade -y

    # INSTALL SOFTWARE
    sudo apt install -y --install-recommends certbot python-certbot-apache

    # RUN CERTBOT CERTIFICATE GETTER AND INSTALLER
    sudo certbot --apache

    echo "${CGRN}${BLD}==========> Installation of SSL (HTTPS) with Let's Encrypt certificate completed.${RST}"
        echo ""
else
        echo "${CORG}${BLD}==========> Skipping installation of SSL (HTTPS) with Let's Encrypt certificate...${RST}"
fi


########################################
# HARDEN MYSQL
########################################
if [[ "$HARDENMYSQL" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Hardening MySQL...${RST}"

    # RUN HARDENING SCRIPT
    sudo mysql_secure_installation


#     # HARDEN VIA CONFIG FILE
#
#     # IF BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP
#     if [[ -f "/etc/mysql/my.cnf.BAK" ]]; then
#         # RESTORE BACKUP
#         sudo rm /etc/mysql/my.cnf
#         sudo cp /etc/mysql/my.cnf.BAK /etc/mysql/my.cnf
#     else
#         # MAKE BACKUP
#         sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.BAK
#     fi
#
#     # CHANGE CONFIG OPTIONS
#
#     # This blocks users who get more than 25 connection errors. To unblock them, run
#     # `mysqladmin flush-hosts` (see https://dev.mysql.com/doc/refman/5.7/en/mysqladmin.html).
#     configLine "^[# ]*max_connect_errors.*$"  "max_connect_errors = 25" /etc/mysql/my.cnf >/dev/null 2>&1
#     configLine "^[# ]*XXXXX.*$"  "XXXXX" /etc/mysql/my.cnf >/dev/null 2>&1
#     configLine "^[# ]*XXXXX.*$"  "XXXXX" /etc/mysql/my.cnf >/dev/null 2>&1
#     configLine "^[# ]*XXXXX.*$"  "XXXXX" /etc/mysql/my.cnf >/dev/null 2>&1
#     configLine "^[# ]*XXXXX.*$"  "XXXXX" /etc/mysql/my.cnf >/dev/null 2>&1
#
#     local-infile=0
#
#     [mysqld]
#     skip-show-database
#
#     bind-address = 127.0.0.1
#
#




    echo "${CGRN}${BLD}==========> Hardening of MySQL completed.${RST}"
    echo ""
else
        echo "${CORG}${BLD}==========> Skipping hardening of MySQL...${RST}"
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
    echo "${CLBL}${BLD}==========> Installing ${CQPCWBRELEASETEXT}${CLBL} of the ${CORG}${CWBVER}${CLBL} branch of CORPUS WORKBENCH (CWB)...${RST}"

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
    sudo apt autoremove -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends autoconf bison cpanminus flex gcc libc6-dev libglib2.0-dev libncurses5-dev libpcre3-dev libreadline-dev make pkg-config subversion

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
        sudo chown -R www-data:www-data ${COMMONCQPWEBDIR}/*
        sudo chmod -R u=rwX,g=rwXs,o=rX ${COMMONCQPWEBDIR}/*

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
    echo "${CORG}${BLD}==========> Skipping CORPUS WORKBENCH (CWB) installation...${RST}"
fi


########################################
# INSTALL CQP WEB
########################################
if [[ "$CQPWEBSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing ${CQPCWBRELEASETEXT}${CLBL} of the ${CORG}${CWBVER}${CLBL} branch of CQPweb...${RST}"

    ####################
    # NUKE PREVIOUSLY INSTALLED CQPWEB FILES IF DESIRED
    ####################
    if [[ "${CQPWEBNUKEOLD}" = 1 ]]; then
        sudo rm -rf /var/www/html/cqpweb
    fi


    ####################
    # REMOVE ANY CURRENT MYSQL AND INSTALL MYSQL 8
    ####################
    if [[ "${MYSQL8}" = 1 ]]; then

        # REMOVE OLD MYSQL VERSION(S). THIS MAY ALREADY HAVE BEEN DONE IN THE
        # UPGRADEOS SECTION, BUT IT NEVER HURTS TO BE SURE.

        sudo apt purge -y mysql*

        # DOWNLOAD NEW MYSQL VERSION
        sudo mkdir -p /tmp/mysql8
        sudo chmod ugo=rwx /tmp/mysql8
        cd /tmp/mysql8 || exit

        # NOTE: THE MYSQL.COM DOWNLOAD SITE IS SUCH A MESS OF DYNAMIC MENUS, SUBMENUS, SELECTIONS
        #       AND SO ON THAT IT ISN'T PRACTICAL TO SCRAPE IT FOR THE LATEST .DEB VERSION, SO
        #       THIS DOWNLOAD URL IS STATIC. YOU MAY OR MAY NOT WANT TO VISIT THE SITE, GET THE
        #       URL FOR ANY NEWER VERSION, AND USE IT HERE.
        aria2c "${MYSQLDLURL}"

        sudo dpkg -i mysql-apt-config_0.8.13-1_all.deb

        sudo apt update -y
        sudo apt autoremove -y
        sudo apt upgrade -y --install-recommends
        sudo apt install -y --install-recommends mysql-server

    fi

    ####################
    # UPDATE AND INSTALL DISTRO SOFTWARE
    ####################
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends apache2 byobu libapache2-mod-php libjpeg-dev libpng-dev libwebp-dev mysql-client mysql-common mysql-server mysql-utilities php-bz2 php-db php-gd php-json php-mbstring php-mysql php-soap php-xml php-zip r-base r-base-core r-recommended

    # INSTALL ON EVERYTHING BUT DEBIAN
    if ! [[ "$OS" = "Debian" ]]; then
        sudo apt install -y --install-recommends ttf-ubuntu-font-family
    fi


    ####################
    # USER AND GROUP MANAGEMENT &
    # FOLDER OWNERSHIP AND PERMISSIONS
    ####################

    # ADD USER TO WWW-DATA GROUP IF HE ISN'T ALREADY A MEMBER
    if ! [[ "${USERGROUPS}" =~ "www-data" ]]; then
        sudo usermod -G www-data -a "${USER}"
    fi

    # SET CERTAIN FOLDER PERMISSIONS AND GROUPS
    sudo chown -R www-data:www-data /var/www
    sudo chmod -R u=rwX,g=rwXs,o=rX /var/www

    sudo chown -R www-data:www-data /usr/lib/cgi-bin
    sudo chmod -R u=rwX,g=rwXs,o=rX /usr/lib/cgi-bin

    sudo chown -R www-data:www-data /var/www/html/cqpweb/css
    sudo chmod -R u=rwX,g=rwXs,o=rX /var/www/html/cqpweb/css

    sudo chown -R www-data:www-data /var/www/html/cqpweb/css/img
    sudo chmod -R u=rwX,g=rwXs,o=rX /var/www/html/cqpweb/css/img


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
        sudo mkdir -p cqpweb

        if [[ "$CQPCWBRELEASE" = 0 ]]; then
            # DOWNLOAD LATEST RELEASE
            sudo svn checkout https://svn.code.sf.net/p/cwb/code/gui/cqpweb/branches/3.2-latest cqpweb
        else
            # DOWNLOAD SPECIFIC RELEASE
            sudo svn checkout -r ${CQPCWBRELEASE} https://svn.code.sf.net/p/cwb/code/gui/cqpweb/branches/3.2-latest cqpweb
        fi
    fi

    # CHANGE PERMISSIONS ON WEB SERVER DIRECTORY
    sudo chown -R www-data:www-data /var/www/html/cqpweb
    sudo chmod -R u=rwX,g=rwXs,o=rX /var/www/html/cqpweb
#     sudo chmod -R u=rwX,g=rwXs,o=rX /var/www
    sudo chmod -R u=rwX,g=rwXs,o=rX /usr/lib/cgi-bin

    # CREATE CQPWEB SUBDIRECTORIES AND SET GROUP AND PERMISSIONS
    sudo mkdir -p ${COMMONCQPWEBDIR}/{data,registry,cache,upload}
    sudo chown www-data:www-data ${COMMONCQPWEBDIR}/*
    sudo chmod -R u=rwX,g=rwXs,o=rX ${COMMONCQPWEBDIR}/*

    # MAKE UPLOAD DIRECTORY VERY PERMISSIVE
    sudo chmod ugo=rwX,+s "${COMMONCQPWEBDIR}/upload"

    ####################
    # PHP CONFIGURATION
    ####################

    # GET PHP VERSION SO WE CAN FIGURE OUT THE RIGHT DIRECTORY TO WORK ON
    PHPVER="$(php --version | grep '^PHP ' | sed -r 's/^PHP ([0-9]\.[0-9]).+$/\1/')"

    # MOVE INTO APPROPRIATE DIRECTORY [TODO: REMOVE THIS ONCE CODE WITH ABSOLUTE PATHS HAS BEEN TESTED]
    cd "/etc/php/${PHPVER}/apache2" || exit

    # IF PHP.INI BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP.
    if [[ -f /etc/php/${PHPVER}/apache2/php.ini.BAK ]]; then
        # RESTORE BACKUP
        sudo rm /etc/php/${PHPVER}/apache2/php.ini
        sudo cp /etc/php/${PHPVER}/apache2/php.ini.BAK /etc/php/${PHPVER}/apache2/php.ini
    else
        # MAKE BACKUP
        sudo cp /etc/php/${PHPVER}/apache2/php.ini /etc/php/${PHPVER}/apache2/php.ini.BAK
    fi

    # PHP: MODIFY CONFIG FILE
    configLine "^[; \t]*memory_limit[ =]*.*"              "memory_limit = 512M"             /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1
    configLine "^[; \t]*max_execution_time[ =]*.*"        "max_execution_time = 600"        /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1
    configLine "^[; \t]*upload_max_filesize[ =]*.*"       "upload_max_filesize = 128M"      /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1
    configLine "^[; \t]*post_max_size[ =]*.*"             "post_max_size = 128M"            /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1
    configLine "^[; \t]*mysqli.allow_local_infile[ =]*.*" "mysqli.allow_local_infile = On"  /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1
    configLine "^[; \t]*expose_php[ =]*.*"                "expose_php = Off"                /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1
    configLine "^[; \t]*error_log[ =]*php_errors.log*.*"  "error_log = /var/log/php_errors.log" /etc/php/${PHPVER}/apache2/php.ini >/dev/null 2>&1
    configLine "^[; \t]*log_errors[ =]*.*"                "log_errors = 1"                  /etc/php/${PHPVER}/apache2/php.ini     >/dev/null 2>&1

    # CREATE PHP ERROR LOG FILE
    sudo touch /var/log/php_errors.log
    sudo chown www-data:adm /var/log/php_errors.log
    sudo chmod 640 /var/log/php_errors.log


    ####################
    # PHP CLI CONFIGURATION
    ####################

    # MOVE INTO APPROPRIATE DIRECTORY # TODO: REMOVE cd WHEN THE CODE HERE IS TESTED.
    cd "/etc/php/${PHPVER}/cli" || exit

    # IF CLI PHP.INI BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP.
    if [[ -f /etc/php/${PHPVER}/cli/php.ini.BAK ]]; then
        # RESTORE BACKUP
        sudo rm /etc/php/${PHPVER}/cli/php.ini
        sudo cp /etc/php/${PHPVER}/cli/php.ini.BAK /etc/php/${PHPVER}/cli/php.ini
    else
        # MAKE BACKUP
        sudo cp /etc/php/${PHPVER}/cli/php.ini /etc/php/${PHPVER}/cli/php.ini.BAK
    fi

    # PHP CLI: MODIFY CONFIG FILE TO ALLOW LOCAL INFILES. OTHERWISE, SOME THINGS DON'T WORK RIGHT.
    configLine "^[; \t]*mysqli.allow_local_infile[ =]*.*"  "mysqli.allow_local_infile = On"  /etc/php/${PHPVER}/cli/php.ini
    configLine "^[; \t]*expose_php[ =]*.*"                 "expose_php = Off"  /etc/php/${PHPVER}/cli/php.ini


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
	    Options -Indexes +FollowSymlinks
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
    # YOU WILL DEFINITELY WANT TO CUSTOMIZE THIS TO FIT YOUR NEEDS!
    sudo tee /var/www/html/cqpweb/lib/config.inc.php <<- EOF >/dev/null 2>&1
	<?php

	/* ---------------------------------------------------------------------- *
	 *                                                                        *
	 * MOST OF THESE VALUES ARE THE DEFAULTS GIVEN IN THE CQPWEB ADMIN MANUAL.*
	 *                                                                        *
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
	/* \$path_to_cwb                   =   ;                                  */
	/* \$path_to_gnu                   =   ;                                  */
	/* \$path_to_perl                  =   ;                                  */
	/* \$path_to_r                     =   ;                                  */
	/* \$perl_extra_directories        =   ;                                  */

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
	 /*\$css_path_for_homepage           =   ;                                */
	 /*\$css_path_for_adminpage          =   ;                                */
	 /*\$css_path_for_userpage           =   ;                                */
	 \$homepage_use_corpus_categories  = false;
	 \$homepage_welcome_message        = "Corpora.pro<br/>Your source for fine Chilean corpora<br/><br/>Scott Sadowsky";
	 \$homepage_logo_left              = ;
	 \$homepage_logo_right             = "css/img/ocwb-logo.transparent.gif";
	 \$searchpage_corpus_name_suffix   = " · Powered by CQPweb";

	/* ---------------------------------------------------------------------- *
	 * USER ACCOUNT CREATION                                                  *
	 * ---------------------------------------------------------------------- */
	 \$allow_account_self_registration = true;
	 \$account_create_contact          = ;
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
	/*\$cqpweb_root_url              =   ;                                    */
	/*\$cqpweb_no_internet           =   ;                                    */
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

fi

########################################
# CREATE SCRIPTS ON CQPWEB SERVER
########################################
# This creates several useful scripts in ~/bin.

if [[ ${CREATECQPWEBSCRIPTS} = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing CQPWEB SCRIPTS...${RST}"

    # MAKE THE ~/BIN DIRECTORY IN CASE IT DOESN'T ALREADY EXIST
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
	sudo chown -R www-data:www-data /var/www/html/cqpweb
	sudo chmod -R u=rwX,g=rwXs,o=rX /var/www/html/cqpweb

	# RESTART APACHE WEB SERVER
	sudo systemctl reload apache2
	sudo systemctl restart apache2

	echo "${CGRN}${BLD}==========> CQPWEB HAS BEEN UPDATED${RST}"
	echo ""

EOF


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
	upd-database.sh

	echo "${CGRN}${BLD}==========> ALL CQP AND CWB COMPONENTS, INCLUDING THE DATABASE, HAVE BEEN UPDATED${RST}"
	echo ""

EOF


    ####################
    # CREATE SCRIPT TO UPGRADE DATABASE
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/upd-database.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/upd-database.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# UPGRADE DATABASE
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	echo ""
	echo "${CLBL}${BLD}==========> UPGRADING CQPWEB DATABASE...${RST}"

	# MOVE TO CQPWEB BINARY DIRECTORY
	cd /var/www/html/cqpweb/bin || exit

	# RUN UPDATER
	sudo php upgrade-database.php

    # RESTART APACHE WEB SERVER
	sudo systemctl reload apache2
	sudo systemctl restart apache2

	echo "${CGRN}${BLD}==========> CQPWEB DATABASE HAS BEEN UPGRADED${RST}"
	echo ""

EOF


    ####################
    # CREATE SCRIPT TO SEND TEST MAIL VIA POSTFIX
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/testmail-postfix.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/testmail-postfix.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# SEND TEST E-MAIL VIA POSTFIX
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	DATE="\$(date +'%Y/%m/%d')"
	TIME="\$(date +'%H:%M:%S')"
	TZ="\$(cat /etc/timezone)"
	USER="\$(whoami)"
	LOCALHOSTNAME="\$(hostname)"
	INTERNALIP="\$(ip route get 1.2.3.4 | awk '{print \$7}')"
	EXTERNALIP="\$(wget -qO - http://checkip.amazonaws.com)"

	echo ""
	echo "${CLBL}${BLD}==========> SENDING TEST E-MAIL VIA POSTFIX...${RST}"

	echo -e "Hi!\\n\\nThis is the Postfix send-only mail server on \${LOCALHOSTNAME} (\${INTERNALIP} / \${EXTERNALIP}). I'm sending this test e-mail to ${PERSONALMAILADDR} via ${OUTMAILSERVER}:${SMTPPORT}.\\n\\nIt's currently \${TIME} on \${DATE} (\$TZ).\\n\\nHave a nice day!" | mail -s "Test mail from Postfix on \$LOCALHOSTNAME" -a "From: ${ADMINMAILADDR}" "${PERSONALMAILADDR}"

	echo "${CGRN}${BLD}==========> Test e-mail sent via Postfix.${RST}"
	echo "${CWHT}${BLD}If you don't receive it, run ${CORG}sudo tail -f /var/log/mail.log${CWHT} and read its output.${RST}"
	echo ""

EOF


    ####################
    # CREATE SCRIPT TO SEND TEST MAIL FROM CQPWEB VIA PHP
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/testmail-cqpweb.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/testmail-cqpweb.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# SEND TEST E-MAIL VIA POSTFIX
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	DATE="\$(date +'%Y/%m/%d')"
	TIME="\$(date +'%H:%M:%S')"
	TZ="\$(cat /etc/timezone)"
	USER="\$(whoami)"
	LOCALHOSTNAME="\$(hostname)"
	INTERNALIP="\$(ip route get 1.2.3.4 | awk '{print \$7}')"
	EXTERNALIP="\$(wget -qO - http://checkip.amazonaws.com)"

	echo ""
	echo "${CLBL}${BLD}==========> SENDING TEST E-MAIL VIA CQPweb/PHP...${RST}"

	echo -e "Hi!\\n\\nThis is the CQPweb/PHP send-only mail server on \${LOCALHOSTNAME} (\${INTERNALIP} / \${EXTERNALIP}). I'm sending this test e-mail to ${PERSONALMAILADDR} via ${OUTMAILSERVER}:${SMTPPORT}.\\n\\nIt's currently \${TIME} on \${DATE} (\$TZ).\\n\\nHave a nice day!" | mail -s "Test mail from CQPweb/PHP on \$LOCALHOSTNAME" -a "From: ${ADMINMAILADDR}" "${PERSONALMAILADDR}"

	echo "${CGRN}${BLD}==========> Test e-mail sent via CQPweb/PHP.${RST}"
	echo "${CWHT}${BLD}If you don't receive it, run ${CORG}sudo tail -f /var/log/mail.log${CWHT} and read its output.${RST}"
	echo ""

EOF


    ####################
    # CREATE SCRIPT TO REPORT CQPWEB AND CWB VERSIONS
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/version-report.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/version-report.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# REPORT CQPWEB AND CWB VERSIONS
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	echo ""
	echo "${CLBL}${BLD}==========> CQPWEB AND CWB VERSION REPORT...${RST}"

	echo ""
	echo "${BLD}==========> CQPWEB <==========${RST}"
	echo "INSTALLED REVISION: \$(svn info --show-item revision /var/www/html/cqpweb)"
	echo "LATEST REVISION:    \$(svn info -r HEAD /var/www/html/cqpweb | grep 'Revision:' | sed 's/Revision: //')"
	echo "LAST MODIFIED:      \$(svn info -r HEAD /var/www/html/cqpweb | grep 'Last Changed Rev:' | sed 's/Last Changed Rev: //')"

	echo ""
	echo "${BLD}==========> CWB <==========${RST}"
	echo "INSTALLED REVISION: \$(svn info --show-item revision /home/\${USER}/software/cwb)"
	echo "LATEST REVISION:    \$(svn info -r HEAD /home/\${USER}/software/cwb | grep 'Revision:' | sed 's/Revision: //')"
	echo "LAST MODIFIED:      \$(svn info -r HEAD /home/\${USER}/software/cwb | grep 'Last Changed Rev:' | sed 's/Last Changed Rev: //')"

	echo ""
	echo "${BLD}==========> CWB-DOC <==========${RST}"
	echo "INSTALLED REVISION: \$(svn info --show-item revision /home/\${USER}/software/cwb-doc)"
	echo "LATEST REVISION:    \$(svn info -r HEAD /home/\${USER}/software/cwb-doc | grep 'Revision:' | sed 's/Revision: //')"
	echo "LAST MODIFIED:      \$(svn info -r HEAD /home/\${USER}/software/cwb-doc | grep 'Last Changed Rev:' | sed 's/Last Changed Rev: //')"

	echo ""
	echo "${BLD}==========> CWB-PERL <==========${RST}"
	echo "INSTALLED REVISION: \$(svn info --show-item revision /home/\${USER}/software/cwb-perl)"
	echo "LATEST REVISION:    \$(svn info -r HEAD /home/\${USER}/software/cwb-perl | grep 'Revision:' | sed 's/Revision: //')"
	echo "LAST MODIFIED:      \$(svn info -r HEAD /home/\${USER}/software/cwb-perl | grep 'Last Changed Rev:' | sed 's/Last Changed Rev: //')"

	echo ""
	echo "You can see the CQPweb changelog at <https://sourceforge.net/p/cwb/activity/>."
	echo ""
	echo "${CGRN}${BLD}==========> CQPWEB AND CWB VERSION REPORT DONE${RST}"
	echo ""

EOF


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


    ####################
    # CREATE SCRIPT TO CALCULATE FREQUENCIES OFFLINE
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/calculate-frequencies-offline.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/calculate-frequencies-offline.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# CALCULATE FREQUENCIES OFFLINE
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	# EVALUATE USER INPUT AND MAKE SURE AN ARGUMENT (CORPUS NAME) WAS GIVEN
	if [[ \$# -ne 1 ]] || [[ \$1 = "-h" ]]; then
	    echo "SUMMARY: This script performs offline frequency calculations for a specified corpus."
	    echo "USAGE:   ${CGRN}${BLD}calculate-frequencies-offline.sh ${CORG}corpus_name${RST}"
	    echo "NOTE:    Corpus names must be lower-case."
	    echo ""
	    exit
	else
	    echo ""
	    echo "${CLBL}${BLD}==========> Calculating frequencies for the \${1} corpus...${RST}"

	    # MOVE TO CORPUS DIRECTRY
	    cd "/var/www/html/cqpweb/\${1}" || exit

	    # PERFORM THE CALCULATIONS
	    php ../bin/offline-freqlists.php

	echo "${CGRN}${BLD}==========> Frequencies for the \${1} corpus have been calculated!${RST}"
	echo ""

	fi

EOF


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

	# WINDOW 3: APACHE ACCESS LOG
	byobu new-window -t $USER:3 -n 'APA'
	byobu send-keys "apalog" C-m

	# WINDOW 4: APACHE ERROR LOG
	byobu new-window -t $USER:4 -n 'APE'
	byobu send-keys "apelog" C-m

	# WINDOW 5: UFW LOG
	byobu new-window -t $USER:5 -n 'UFW'
	byobu send-keys "ulog" C-m

	# WINDOW 6: AUTH LOG
	byobu new-window -t $USER:6 -n 'ALOG'
	byobu send-keys "alog" C-m

	# WINDOW 7: FAIL2BAN LOG
	byobu new-window -t $USER:7 -n 'FLOG'
	byobu send-keys "flog" C-m

	# WINDOW 8: CLI 2
	byobu new-window -t $USER:8 -n 'CLI2'

	# START BYOBU
	byobu

EOF


    ####################
    # CREATE SCRIPT TO FIND WORLD-WRITABLE DIRECTORIES
    ####################

    # DELETE ANY OLD VERSION OF THE SCRIPT
    sudo rm -f "${HOME}/bin/find-world-writable.sh"

    # WRITE SCRIPT TO NEW FILE
    sudo tee "${HOME}/bin/find-world-writable.sh" <<- EOF >/dev/null 2>&1
	#!/bin/bash

	# FIND WORLD-WRITABLE DIRECTORIES
	# This script was created automatically by ${SCRIPTNAME} on ${DATE}.

	sudo find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print

EOF


    ########################################
    # SET OWNER AND PERMISSIONS OF ALL SCRIPTS IN ~/bin
    #   THIS SHOULDN'T BE NECESSARY, BUT ON CERTAIN VPS-PRECONFIGURED UBUNTU
    #   OS IMAGES (AT LEAST) THE CODE ABOVE DOESN'T DO IT FOR MOST SCRIPTS.
    ########################################
    sudo chown "${USER}:${USER}" "${HOME}"/bin/*.sh
    sudo chmod 700 "${HOME}"/bin/*.sh


    echo "${CGRN}${BLD}==========> CQPWEB SCRIPTS installation finished.${RST}"
    echo "${CWHT}${BLD}            You will find useful scripts in ${CORG}${HOME}/bin${CWHT}.${RST}"
    echo ""
else
    echo "${CORG}${BLD}==========> Skipping CQPWEB SCRIPT installation...${RST}"
fi


########################################
# UPLOAD CUSTOM TL/TR IMAGE
########################################
if [[ "${IMAGEUPLD}" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Uploading CUSTOM IMAGES...${RST}"

    # CONCATENATE SOURCE DIRS AND SOURCE FILE NAMES
    IMAGESOURCE1="${IMAGESOURCE1DIR}/${IMAGESOURCE1FILE}"
    IMAGESOURCE2="${IMAGESOURCE2DIR}/${IMAGESOURCE2FILE}"

    # MAKE SURE IMAGE TARGET DIRECTORY IS NOT INVALID
    if [[ "${IMAGETARGET}" != "YOUR_INFO_HERE" ]] || [[ "${IMAGETARGET}" != "" ]]; then

        # FIX OWNERSHIP AND PERMISSIONS
        sudo chown -R www-data:www-data "${IMAGETARGET}"
        sudo chmod -R ug=rwX,o=rX "${IMAGETARGET}"

        # IMAGE 1
        if [[ "${IMAGESOURCE1FILE}" != "YOUR_INFO_HERE" ]] && [[ "${IMAGESOURCE1FILE}" != "" ]]; then
            sudo wget -P "${IMAGETARGET}" "${IMAGESOURCE1}"
        fi

        # IMAGE 2
        if [[ "${IMAGESOURCE2FILE}" != "YOUR_INFO_HERE" ]] && [[ "${IMAGESOURCE2FILE}" != "" ]]; then
            sudo wget -P "${IMAGETARGET}" "${IMAGESOURCE2}"
        fi
        echo "${CGRN}${BLD}==========> CUSTOM IMAGE upload finished.${RST}"
        echo ""
    else
        echo ""
        if [[ "${IMAGETARGET}" = "YOUR_INFO_HERE" ]] || [[ "${IMAGETARGET}" = "" ]]; then
            echo "${CRED}${BLD}            You must specify a TARGET DIRECTORY for the image(s)!${RST}"
        fi

        if [[ "${IMAGESOURCE1FILE}" = "YOUR_INFO_HERE" ]] || [[ "${IMAGESOURCE1FILE}" = "" ]]; then
            echo "${CRED}${BLD}            You must specify a source URL for image 1!${RST}"
        fi

        if [[ "${IMAGESOURCE2FILE}" = "YOUR_INFO_HERE" ]] || [[ "${IMAGESOURCE2FILE}" = "" ]]; then
            echo "${CRED}${BLD}            You must specify a source URL for image 2!${RST}"
        fi
    fi

else
    echo "${CORG}${BLD}==========> Skipping CUSTOM IMAGE upload...${RST}"
fi


########################################
# UPLOAD FAVICON
########################################
if [[ "${FAVICONUPLD}" = 1 ]]; then

    # UPLOAD IMAGE FILE(S) TO SERVER IF AN ACTUAL URL HAS BEEN SET
    if ! [[ "${FAVICONTARGET}" = "YOUR_INFO_HERE" && "${FAVICONSOURCE}" = "YOUR_INFO_HERE" ]]; then
        echo ""
        echo "${CLBL}${BLD}==========> Uploading FAVICON...${RST}"

        sudo wget -P "${FAVICONTARGET}" "${FAVICONSOURCE}"

        echo "${CGRN}${BLD}==========> FAVICON upload finished.${RST}"
        echo ""
    else
        echo ""
        echo "${CRED}${BLD}==========> You must set valid source and target paths for the FAVICON!${RST}"
    fi

else
    echo "${CORG}${BLD}==========> Skipping FAVICON upload...${RST}"
fi


##################################################
# CUSTOMIZE CERTAIN CQPWEB WEB PAGES
##################################################

##############################
# CUSTOMIZE SIGNUP PAGE
##############################
if [[ "${CUSTPGSIGNUP}" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Customizing CQPWEB SIGN UP PAGE...${RST}"

    ########################################
    # CUSTOMIZE /lib/useracct-forms.php
    ########################################
    CURRFILE="/var/www/html/cqpweb/lib/useracct-forms.php"

    # Make backup
    if ! [[ -f "${CURRFILE}.BAK" ]]; then
        sudo cp "${CURRFILE}" "${CURRFILE}.BAK"
    fi

    # CUSTOMIZE FILES
    sudo perl -i -p0e 's/you should use it to sign up<\/strong>\.[\n\t ]+?<\/p>[\n\t ]+?<p .+?>[\n\t ]+?<.+?>[\n\t ]+?This is because your access/you should use it to sign up<\/strong>. This is because your access/gms' "${CURRFILE}"

    sudo perl -i -p0e 's/We will send a verification message to this email address/<strong>We will send a verification message to this email address<\/strong>/gms' "${CURRFILE}"

    sudo perl -i -p0e 's/<strong>double-check for typing errors<\/strong>/double-check for typing errors/gms' "${CURRFILE}"

    sudo perl -i -p0e 's/in that email message\!<\/em>/in the verification email.<\/em> <strong>Make sure to check your SPAM folder for it!<\/strong>/gms' "${CURRFILE}"

    sudo perl -i -p0e 's/Prefer not to specify/SELECT COUNTRY/gms' "${CURRFILE}"

    sudo perl -i -p0e 's/<tr>[\n\t ]+?<td class="concordgrey" colspan="2">[\n\t ]+?<p class="spacer">&nbsp;<\/p>[\n\t ]+?<p>[\n\t ]+?The following three questions.+?<\/tr>/\n/gms' "${CURRFILE}"

    echo "${CGRN}${BLD}==========> CQPWEB SIGN UP PAGE customization finished.${RST}"
    echo ""

fi


##############################
# CUSTOMIZE PAGE TITLES
##############################
if [[ "${CUSTPPGTITLES}" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Customizing CQPWEB PAGE TITLES...${RST}"

    # userhome.php
    sudo perl -i -p0e "s/CQPweb User Page/${NEWPAGETITLE} User Page/gms" /var/www/html/cqpweb/lib/userhome.php

    # mainhome.php
    sudo perl -i -p0e "s/CQPweb Main Page/${NEWPAGETITLE} Main Page/gms" /var/www/html/cqpweb/lib/mainhome.php

    # adminhome.php
    sudo perl -i -p0e "s/CQPweb Admin Control Panel/${NEWPAGETITLE} Admin Control Panel/gms" /var/www/html/cqpweb/lib/adminhome.php


    echo "${CGRN}${BLD}==========> CQPWEB CQPWEB PAGE TITLE customization finished.${RST}"
    echo ""

fi


##############################
# CUSTOMIZE CQPWEB SYNTAX TUTORIAL LINK
##############################
if [[ "${CUSTCQPSYNTUTURL}" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Customizing CQPWEB SYNTAX TUTORIAL LINK...${RST}"

    sudo perl -i -p0e "s|http://cwb\.sourceforge\.net/files/CQP_Tutorial/|${CQPSYNTUTURL}|gms" /var/www/html/cqpweb/lib/query-forms.php

    echo "${CGRN}${BLD}==========> CQPWEB SYNTAX TUTORIAL LINK customization finished.${RST}"
    echo ""

fi



########################################
# REPLACE THE WORD "MENU" IN T/L OF MOST
# PAGES WITH A GRAPHIC AND OPTIONAL URL
########################################
if [[ "${CUSTPGMENUGRAPHIC}" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> MODIFYING T/L 'MENU' with a custom graphic...${RST}"

    # MOVE INTO DIRECTORY WITH WEB PAGE FILES
    cd /var/www/html/cqpweb/lib || exit

    # FILES TO MOD: userhome.php , queryhome.php , adminhome.php

    # MODIFY USERHOME.PHP
    if [[ $MENUURLUSER != "YOUR_INFO_HERE" ]] && [[ $MENUURLUSER != "" ]]; then

        CURRFILE="userhome.php"

        # BACK UP PHP FILE
        if ! [[ -f "${CURRFILE}.BAK" ]]; then
            sudo cp "${CURRFILE}" "${CURRFILE}.BAK"
        else
            sudo cp "${CURRFILE}.BAK" "${CURRFILE}"
        fi

        # CREATE CUSTOM IMAGE STRING
        if [[ "$IMAGESOURCE2FILE" != "YOUR_INFO_HERE" ]] && [[ "$IMAGESOURCE2FILE" != "" ]]; then
            IMGSTRING="<img src=\"../css/img/${IMAGESOURCE2FILE}\" width=\"200\" height=\"\">"
        else
            IMGSTRING="Menu"
        fi

        # CREATE CUSTOM URL STRING
        if [[ "$MENUURLUSER" != "YOUR_INFO_HERE" ]] && [[ "$MENUURLUSER" != "" ]]; then
            URLSTRING="\" href=\"$MENUURLUSER\">"
        else
            URLSTRING="\">"
        fi

        # PERFORM STRING REPLACEMENT
        sudo perl -i -p0e "s|<a class=\"menuHeaderItem\">Menu</a>|<a class=\"menuHeaderItem${URLSTRING}${IMGSTRING}</a>|gms" "${CURRFILE}"

        # USE AS REPLACEMENT STRING!
        #  <a class=\"menuHeaderItem${URLSTRING}${IMGSTRING}</a>
    fi

    # MODIFY QUERYHOME.PHP
    if [[ $MENUURLQUERY != "YOUR_INFO_HERE" ]] && [[ $MENUURLQUERY != "" ]]; then

        CURRFILE="queryhome.php"

        # BACK UP PHP FILE
        if ! [[ -f "${CURRFILE}.BAK" ]]; then
            sudo cp "${CURRFILE}" "${CURRFILE}.BAK"
        else
            sudo cp "${CURRFILE}.BAK" "${CURRFILE}"
        fi

        # CREATE CUSTOM IMAGE STRING
        if [[ "$IMAGESOURCE2FILE" != "YOUR_INFO_HERE" ]] && [[ "$IMAGESOURCE2FILE" != "" ]]; then
            IMGSTRING="<img src=\"../css/img/${IMAGESOURCE2FILE}\" width=\"200\" height=\"\">"
        else
            IMGSTRING="Menu"
        fi

        # CREATE CUSTOM URL STRING
        if [[ "$MENUURLQUERY" != "YOUR_INFO_HERE" ]] && [[ "$MENUURLQUERY" != "" ]]; then
            URLSTRING="\" href=\"$MENUURLQUERY\">"
        else
            URLSTRING="\">"
        fi

        # PERFORM STRING REPLACEMENT
        sudo perl -i -p0e "s|<a class=\"menuHeaderItem\">Menu</a>|<a class=\"menuHeaderItem${URLSTRING}${IMGSTRING}</a>|gms" "${CURRFILE}"

        # USE AS REPLACEMENT STRING!
        #  <a class=\"menuHeaderItem${URLSTRING}${IMGSTRING}</a>
    fi

    # MODIFY ADMINHOME.PHP
    if [[ $MENUURLADMIN != "YOUR_INFO_HERE" ]] && [[ $MENUURLADMIN != "" ]]; then

        CURRFILE="adminhome.php"

        # BACK UP PHP FILE
        if ! [[ -f "${CURRFILE}.BAK" ]]; then
            sudo cp "${CURRFILE}" "${CURRFILE}.BAK"
        else
            sudo cp "${CURRFILE}.BAK" "${CURRFILE}"
        fi

        # CREATE CUSTOM IMAGE STRING
        if [[ "$IMAGESOURCE2FILE" != "YOUR_INFO_HERE" ]] && [[ "$IMAGESOURCE2FILE" != "" ]]; then
            IMGSTRING="<img src=\"../css/img/${IMAGESOURCE2FILE}\" width=\"200\" height=\"\">"
        else
            IMGSTRING="Menu"
        fi

        # CREATE CUSTOM URL STRING
        if [[ "$MENUURLADMIN" != "YOUR_INFO_HERE" ]] && [[ "$MENUURLADMIN" != "" ]]; then
            URLSTRING="\" href=\"$MENUURLADMIN\">"
        else
            URLSTRING="\">"
        fi

        # PERFORM STRING REPLACEMENT
        sudo perl -i -p0e "s|<a class=\"menuHeaderItem\">Menu</a>|<a class=\"menuHeaderItem${URLSTRING}${IMGSTRING}</a>|gms" "${CURRFILE}"

        # USE AS REPLACEMENT STRING!
        #  <a class=\"menuHeaderItem${URLSTRING}${IMGSTRING}</a>
    fi

    echo "${CGRN}${BLD}==========> MODIFYING T/L 'MENU' with custom graphic finished.${RST}"
    echo ""
fi


########################################
# CUSTOMIZE WEB FONTS IN CQPWEB
# NOTE: This code is potentially fragile -- if the CSS files
#       being modified are changed much, it could break.
########################################
if [[ "${CUSTOMIZEFONTS}" = 1 ]]; then

    # HOMOGENIZE FONT VARIABLE VALUES
    if [[ "${MAINFONT}" = "YOUR_INFO_HERE" ]]; then MAINFONT=""; fi
    if [[ "${CONCFONT}" = "YOUR_INFO_HERE" ]]; then CONCFONT=""; fi


    # PROCEED IF AT LEAST ONE OF THE FONT VARIABLES ISN'T EMPTY.
    if [[ "${MAINFONT}" != "" || "${CONCFONT}" != "" ]]; then
        echo ""
        echo "${CLBL}${BLD}==========> Customizing CQP FONTS...${RST}"

        # SET BASE PATH OF CQPWEB. NO SLASH AT END, PLEASE.
        BASEPATH="/var/www/html/cqpweb"

        # MAKE BACKUP OF CSS DIRECTORY IF IT DOESN'T EXIST. OTHERWISE, RESTORE BACKUP BEFORE PROCEEDING.
        if ! [[ -d "${BASEPATH}/css.BAK" ]]; then
            sudo cp -r "${BASEPATH}/css" "${BASEPATH}/css.BAK"
        else
            sudo rm -rf "${BASEPATH}/css"
            sudo cp -r "${BASEPATH}/css.BAK" "${BASEPATH}/css"
        fi

        # CREATE LIST OF FONT NAMES
        IMPORTFONTLIST="${MAINFONT}|${CONCFONT}"

        # CHANGE SPACES TO PLUS SIGNS
        IMPORTFONTLIST=$(echo "${IMPORTFONTLIST}" | sed 's/ /+/g')

        # REMOVE LEADING OR TRAILING |, WHICH HAPPENS IF ONE FONT IS NOT SET.
        IMPORTFONTLIST=$(echo "$IMPORTFONTLIST" | sed -r 's/^\|//g')
        IMPORTFONTLIST=$(echo "$IMPORTFONTLIST" | sed -r 's/\|$//g')

        # CREATE STRING FOR IMPORTING FONTS VIA CSS FILES
#         WEBFONTIMPORT="\@import url('https://fonts.googleapis.com/css?family=${IMPORTFONTLIST}&display=swap');"

        # MOVE INTO CSS DIRECTORY
        cd "${BASEPATH}/css" || exit

        # SET NULLGLOB SO THAT A NON-MATCHING PATTERN EXPANDS TO AN EMPTY STRING RATHER THAN THE LITERAL STRING
        shopt -s nullglob

        # LOOP THROUGH CSS FILES IN CSS DIRECTORY
        for CURRFILE in *.css;
        do
            # BREAK IF THERE ARE NO RESULTS
            [ -f "$CURRFILE" ] || break

            # ADD CODE TO DOWNLOAD THE WEB FONT(S)
            sudo perl -i -p0e "s!/\* end of resets \*/!/* end of resets */\n\n# IMPORT WEB FONT FROM EXTERNAL URL\n\@import url('https://fonts.googleapis.com/css?family=${IMPORTFONTLIST}&display=swap');\n!gms" "${CURRFILE}"

            ##### MAIN FONT #####

            # STANDARDIZE *MAIN FONT* FAMILY LISTS (SOME ONLY HAVE VERDANA, WHILE OTHERS HAVE A FULLER LIST)
            sudo perl -i -p0e "s/Verdana,Arial,Helvetica,sans-serif;/Arial,Helvetica,Verdana,sans-serif;/gi" "${CURRFILE}"
            sudo perl -i -p0e "s/Verdana;/Arial,Helvetica,Verdana,sans-serif;/gi" "${CURRFILE}"

            # ADD USER-SELECTED WEB FONT TO *MAIN FONT* FAMILY LISTS
            sudo perl -i -p0e "s/Arial,Helvetica,Verdana,sans-serif;/'${MAINFONT}',Arial,Helvetica,Verdana,sans-serif !important;/gi" "${CURRFILE}"


            ##### CONCORDANCE FONT #####

            # ADD USER-SELECTED WEB FONT FAMILY TO *CONCORDACE FONT*

            # td.before
            sudo perl -i -p0e "s/td\.before\W*?\{\W*?\n\W*?(padding.+?)$/td.before {\n\tfont-family: '${CONCFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"

            # td.after
            sudo perl -i -p0e "s/td\.after\W*?\{\W*?\n\W*?(padding.+?)$/td.after {\n\tfont-family: '${CONCFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"

            # td.node
            sudo perl -i -p0e "s/td\.node\W*?\{\W*?\n\W*?(padding.+?)$/td.node {\n\tfont-family: '${CONCFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"

            # td.lineview
            sudo perl -i -p0e "s/td\.lineview \W*?\{\W*?\n\W*?(padding.+?)$/td.lineview  {\n\tfont-family: '${CONCFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"

            # td.parallel-line
            sudo perl -i -p0e "s/td\.parallel-line\W*?\{\W*?\n\W*?(padding.+?)$/td.parallel-line {\n\tfont-family: '${CONCFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"

            # td.parallel-kwic
            sudo perl -i -p0e "s/td\.parallel-kwic\W*?\{\W*?\n\W*?(padding.+?)$/td.parallel-kwic {\n\tfont-family: '${CONCFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"

            # td.text_id - NOTE: Uses MAIN font, not CONCORDANCE font.
            sudo perl -i -p0e "s/td\.text_id\W*?\{\W*?\n\W*?(padding.+?)$/td.text_id {\n\tfont-family: '${MAINFONT}',monospace \!important;\n\t\$1/gms" "${CURRFILE}"
        done

        echo "${CGRN}${BLD}==========> CQP FONT customization finished.${RST}"
        echo ""
    else
        echo ""
        echo "${CRED}${BLD}==========> You chose to customize the font(s) in the CQPWEB CSS files, but you did not specify at least${RST}"
        echo "${CRED}${BLD}            one font. Please edit ${SCRIPTNAME} and set the ${CORG}MAINFONT${CRED} and/or ${CORG}CONCFONT${CRED} variables.${RST}"
        echo ""
    fi

fi


########################################
# TURN CQPWEB DEBUG ON OR OFF
########################################
if [[ "${TURNDEBUGON}" = 1 ]]; then
    echo ""
    echo "${CLBL}${BLD}==========> Configuring CQPWEB DEBUG...${RST}"

    configLine "^[# ]*\$print_debug_messages.*$" "\$print_debug_messages         = true;" /var/www/html/cqpweb/lib/config.inc.php >/dev/null 2>&1

    echo "${CGRN}${BLD}==========> CQPWEB DEBUG turned ON.${RST}"
    echo ""
else
    echo ""
    echo "${CLBL}${BLD}==========> Configuring CQPWEB DEBUG...${RST}"

    configLine "^[# ]*\$print_debug_messages.*$" "\$print_debug_messages         = false;" /var/www/html/cqpweb/lib/config.inc.php >/dev/null 2>&1

    echo "${CGRN}${BLD}==========> CQPWEB DEBUG turned OFF.${RST}"
    echo ""

fi



########################################
# INSTALL THE DICKENS SAMPLE CORPUS
########################################
if [[ "$CORPDICKENS" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing DICKENS CORPUS...${RST}"

    # CREATE DATA AND REGISTRY DIRECTORIES, COPY FILES TO THEM, SET OWNERSHIP + PERMISSIONS
    # NOTE use of 'cp -a' plus "." after the path -- 'cp -r' does NOT copy hidden files!
    sudo mkdir -p "${COMMONCQPWEBDIR}/data/Dickens"
    sudo mkdir -p "${COMMONCQPWEBDIR}/registry"

    sudo cp -a "${SWDIR}/cwb-doc/corpora/dickens/release/Dickens-1.0/data/." "${COMMONCQPWEBDIR}/data/Dickens/"
    sudo cp "${SWDIR}/cwb-doc/corpora/dickens/release/Dickens-1.0/registry/dickens" "${COMMONCQPWEBDIR}/registry/dickens"

    sudo chown -R www-data:www-data ${COMMONCQPWEBDIR}/*
    sudo chmod -R u=rwX,g=rwXs,o=rX ${COMMONCQPWEBDIR}/*

#     sudo chgrp www-data ${COMMONCQPWEBDIR}/*
#     sudo chmod g+rwx,o-rwx,+s ${COMMONCQPWEBDIR}/*

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

    echo "${CRED}${BLD}            WARNING!${CORG} While this will correctly install the Postfix mail server, and system utilities${RST}"
    echo "${CORG}${BLD}            like fail2ban will work properly with it, ${CRED}CQPweb cannot use it${CORG} and will not be able to send${RST}"
    echo "${CORG}${BLD}            e-mails if you install this. So ${CRED}you almost certainly do NOT want to proceed!${RST}"
    echo ""
    read -r -p "            ${CORG}${BLD}Are you REALLY sure you want to install Postfix? (y/n) ${RST}" ANSWER

    if [[ "$ANSWER" = [yY] || "$ANSWER" = [yY][eE][sS] ]]; then

        # UPDATE SYSTEM SOFTWARE
        sudo apt update -y
        sudo apt autoremove -y
        sudo apt upgrade -y

        # REMOVE EVERY LAST VESTIGE OF SENDMAIL
        sudo apt remove --purge -y -f sendmail

        echo ""
        echo "${CORG}${BLD}We will now install the Postfix mail server. If asked, choose the following options...${RST}"
        echo        "${CWHT} - Type of Mail Configuration:${RST} ${CORG}${BLD}Internet${RST}"
        echo        "${CWHT} - System mail name:          ${RST} ${CORG}${BLD}${MAILSERVERURL}${RST}"
        echo ""
        read -r -p "${CORG}${BLD}            Press any key to continue (or wait 10 seconds)... ${RST}" -n 1 -t 10 -s
        echo ""

        sudo apt install -y --install-recommends mailutils mailutils-mh libsasl2-2 libsasl2-modules ca-certificates postfix secure-delete

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
        echo "${CRED}${BLD}==========> Aborting MAIL SERVER installation...${RST}"
    fi

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
    # To detect non-purged packages: dpkg --list | grep ^rc | awk '{ print $2; }'
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
    sudo apt autoremove -y
    sudo apt upgrade -y
    sudo apt install -y --install-recommends chkrootkit logwatch lynis rkhunter

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

    sudo apt remove --purge -y -f xinetd nis yp-tools tftpd atftpd tftpd-hpa telnetd rsh-server rsh-redone-server

    ####################
    # HARDEN SYSCTL SETTINGS
    ####################
    echo ""
    echo "${CLBL}==========> Hardening sysctl.conf settings...${RST}"
    configLine "^[# ]*kernel.randomize_va_space.*$"              "kernel.randomize_va_space=1"              /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.accept_redirects.*$"     "net.ipv4.conf.all.accept_redirects=0"     /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.accept_source_route.*$"  "net.ipv4.conf.all.accept_source_route=0"  /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.log_martians.*$"         "net.ipv4.conf.all.log_martians=1"         /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.log_martians.*$"         "net.ipv4.conf.all.log_martians=1"         /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.rp_filter.*$"            "net.ipv4.conf.all.rp_filter=1"            /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.rp_filter.*$"            "net.ipv4.conf.all.rp_filter=1"            /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.all.send_redirects.*$"       "net.ipv4.conf.all.send_redirects=0"       /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.default.accept_redirects.*$" "net.ipv4.conf.default.accept_redirects=0" /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.default.rp_filter.*$"        "net.ipv4.conf.default.rp_filter=1"        /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.default.send_redirects.*$"   "net.ipv4.conf.default.send_redirects=0"   /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.icmp_echo_ignore_broadcasts.*$"   "net.ipv4.icmp_echo_ignore_broadcasts=1"   /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.icmp_ignore_bogus_error_responses.*$" "net.ipv4.icmp_ignore_bogus_error_responses=1" /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.icmp_ignore_bogus_error_responses.*$" "net.ipv4.icmp_ignore_bogus_error_responses=1" /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.icmp_ignore_bogus_error_responses.*$" "net.ipv4.icmp_ignore_bogus_error_responses=1" /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.ip_forward.*$"            "net.ipv4.ip_forward=0"                /etc/sysctl.conf  >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.tcp_max_syn_backlog.*$"   "net.ipv4.tcp_max_syn_backlog=2048"    /etc/sysctl.conf  >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.tcp_syn_retries.*$"       "net.ipv4.tcp_syn_retries=5"           /etc/sysctl.conf  >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.tcp_synack_retries.*$"    "net.ipv4.tcp_synack_retries=2"        /etc/sysctl.conf  >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.tcp_syncookies.*$"        "net.ipv4.tcp_syncookies=1"            /etc/sysctl.conf  >/dev/null 2>&1
    configLine "^[# ]*fs.suid_dumpable.*$"               "fs.suid_dumpable=0"                   /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*kernel.core_uses_pid.*$"           "kernel.core_uses_pid=1"               /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.default.accept_source_route.*$"  "net.ipv4.conf.default.accept_source_route=0"  /etc/sysctl.conf >/dev/null 2>&1
    configLine "^[# ]*net.ipv4.conf.default.log_martians.*$"  "net.ipv4.conf.default.log_martians=1" /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*kernel.sysrq.*$"                   "kernel.sysrq=0"                       /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*kernel.dmesg_restrict.*$"          "kernel.dmesg_restrict=1"              /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*kernel.kptr_restrict.*$"           "kernel.kptr_restrict=2"               /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*kernel.randomize_va_space.*$"      "kernel.randomize_va_space=2"          /etc/sysctl.conf   >/dev/null 2>&1
    configLine "^[# ]*vm.swappiness.*$"                  "vm.swappiness=10"                     /etc/sysctl.conf   >/dev/null 2>&1



    # RELOAD sysctl
    sudo sysctl -p >/dev/null 2>&1

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

    # apache2.conf
    configLine "^[# ]*ServerTokens[ ].*"        "ServerTokens Prod"     /etc/apache2/apache2.conf  >/dev/null 2>&1
    configLine "^[# ]*ServerSignature[ ].*"     "ServerSignature Off"   /etc/apache2/apache2.conf  >/dev/null 2>&1
    configLine "^[# ]*TraceEnable[ ].*"         "TraceEnable Off"       /etc/apache2/apache2.conf  >/dev/null 2>&1

    # security.conf
    configLine "^[# ]*ServerTokens[ ].*"        "ServerTokens Prod"     /etc/apache2/conf-available/security.conf  >/dev/null 2>&1
    configLine "^[# ]*ServerSignature[ ].*"     "ServerSignature Off"   /etc/apache2/conf-available/security.conf  >/dev/null 2>&1
    configLine "^[# ]*TraceEnable[ ].*"         "TraceEnable Off"       /etc/apache2/conf-available/security.conf  >/dev/null 2>&1


    ####################
    # SECURE SHARED MEMORY
    # You may or may not want to modify the 'size=2048m' parameter.
    ####################
    # IF BACKUP EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP
    if [[ -f "/etc/fstab.BAK" ]]; then
        # RESTORE BACKUP
        sudo rm /etc/fstab
        sudo cp /etc/fstab.BAK /etc/fstab
    else
        # MAKE BACKUP
        sudo cp /etc/fstab /etc/fstab.BAK
    fi

    echo -e "tmpfs   /run/shm   tmpfs   rw,noexec,nosuid,nodev,size=2048m   0   0\\n" | sudo tee -a /etc/fstab >/dev/null 2>&1



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
    sudo apt autoremove -y
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
    if [[ ! -z "${SSHPORT}" ]];   then sudo ufw limit "${SSHPORT}"      comment 'SSH port'; fi
    if [[ ! -z "${SMTPPORT}" ]];  then sudo ufw limit "${SMTPPORT}"     comment 'SMTP port'; fi
    if [[ ! -z "${RSYNCPORT}" ]]; then sudo ufw limit "${RSYNCPORT}"    comment 'RSYNC port'; fi
    if [[ ! -z "${IMAPSPORT}" ]]; then sudo ufw limit "${IMAPSPORT}"    comment 'IMAPS port'; fi
    if [[ ! -z "${POP3PORT}" ]];  then sudo ufw limit "${POP3PORT}"     comment 'POP3 port'; fi
    if [[ ! -z "${IMAPPORT}" ]];  then sudo ufw limit "${IMAPPORT}"     comment 'IMAP port'; fi

    # DISABLE IPV6 IN UFW IF DESIRED
    DISABLEIPV6=1
    if [[ "$DISABLEIPV6" = 1 ]]; then

        if [[ -f "/etc/default/ufw.BAK" ]]; then
            # RESTORE BACKUP
            sudo rm /etc/default/ufw
            sudo cp /etc/default/ufw.BAK /etc/default/ufw
        else
            # MAKE BACKUP
            sudo cp /etc/default/ufw /etc/default/ufw.BAK
        fi

        configLine "^[# ]*IPV6.*$"            "IPV6=no" /etc/default/ufw >/dev/null 2>&1

        echo "==================> UFW RECONFIGURED (OR ATEMPTED)"
    fi


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
    sudo apt autoremove -y
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

        ############### INSTALL FAIL2BAN AND ASSOCIATED SOFTWARE ###############
        sudo apt update -y
        sudo apt autoremove -y
        sudo apt install -y --install-recommends --install-suggests fail2ban iptables-persistent netfilter-persistent logcheck python3-dnspython geoip-bin geoip-database-extra

        ############### MODIFY FAIL2BAN.CONF FILE ###############
        configLine "^[# ]*dbpurgeage.*$"         "dbpurgeage = 648000" /etc/fail2ban/fail2ban.conf >/dev/null 2>&1

        ############### CREATE JAIL.LOCAL CONFIG FILE ###############
        # Delete any pre-existing local config file and create a new one
        sudo rm -f /etc/fail2ban/jail.local
        sudo touch /etc/fail2ban/jail.local

        # Create config file
        sudo tee -a /etc/fail2ban/jail.local <<- EOF >/dev/null 2>&1
		[INCLUDES]
		before = paths-ubuntu.conf

		[DEFAULT]

		############### MISCELLANEOUS OPTIONS ###############
		ignorself   = true
		ignoreip    = ${WHITELISTEDIPS}
		bantime     = 86400
		findtime    = 86400
		maxretry    = 4
		#backend    = auto
		backend     = polling
		usedns      = warn
		logencoding = auto
		mode        = normal
		filter      = %(__name__)s[mode=%(mode)s]
		dbpurgeage  = 648000

		############### ACTIONS ###############
		destemail = ${ADMINMAILADDR}
		sender    = fail2ban@${SERVERALIAS}
		#mta       = sendmail
		mta       = mail
		#protocol  = tcp
		protocol  = all
		port      = 0:65535
		fail2ban_agent = Fail2Ban/%(fail2ban_version)s

		# ACTION SHORTCUTS. TO BE USED TO DEFINE ACTION PARAMETER
		#banaction = iptables-multiport
		banaction = iptables-allports
		banaction_allports = iptables-allports

		# THE SIMPLEST ACTION TO TAKE: BAN ONLY
		action_ = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]

		# BAN & SEND AN E-MAIL WITH WHOIS REPORT TO THE DESTEMAIL.
		action_mw = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
		            %(mta)s-whois[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]

		# BAN & SEND AN E-MAIL WITH WHOIS REPORT AND RELEVANT LOG LINES
		# TO THE DESTEMAIL.
		action_mwl = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
		             %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]


		# CHOOSE DEFAULT ACTION.  TO CHANGE, JUST OVERRIDE VALUE OF 'ACTION' WITH THE
		# INTERPOLATION TO THE CHOSEN ACTION SHORTCUT (E.G.  ACTION_MW, ACTION_MWL, ETC) IN JAIL.LOCAL
		# GLOBALLY (SECTION [DEFAULT]) OR PER SPECIFIC SECTION.
		action = %(action_)s


		############### JAILS ###############

		###### SSH servers ######

		[sshd]
		# TO USE MORE AGGRESSIVE SSHD MODES SET FILTER PARAMETER "MODE" IN JAIL.LOCAL:
		# NORMAL (DEFAULT), DDOS, EXTRA OR AGGRESSIVE (COMBINES ALL).
		# SEE "TESTS/FILES/LOGS/SSHD" OR "FILTER.D/SSHD.CONF" FOR USAGE EXAMPLE AND DETAILS.
		enabled  = true
		mode     = aggressive
		port     = ssh,${SSHPORT}
		logpath  = %(sshd_log)s
		backend  = %(sshd_backend)s
		bantime  = 86400
		findtime = 86400
		maxretry = 3

		[dropbear]
		enabled  = true
		port     = ssh,${SSHPORT}
		logpath  = %(dropbear_log)s
		backend  = %(dropbear_backend)s
		bantime  = 604800
		findtime = 86400


		##### HTTP servers ######

		[apache-auth]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = 3600
		findtime = 300
		maxretry = 6

		[apache-badbots]
		enabled  = true
		port     = http,https
		logpath  = %(apache_access_log)s
		bantime  = 604800
		findtime = 86400
		maxretry = 1

		[apache-noscript]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = -1
		findtime = 86400
		maxretry = 1

		[apache-overflows]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = -1
		findtime = 86400
		maxretry = 2

		[apache-nohome]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = 259200
		findtime = 86400
		maxretry = 2

		[apache-botsearch]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = 259200
		findtime = 86400
		maxretry = 2

		[apache-fakegooglebot]
		enabled  = true
		port     = http,https
		logpath  = %(apache_access_log)s
		bantime  = 604800
		findtime = 86400
		maxretry = 1
		ignorecommand = %(ignorecommands_dir)s/apache-fakegooglebot <ip>

		[apache-modsecurity]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = 259200
		findtime = 86400
		maxretry = 2

		[apache-shellshock]
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = 259200
		findtime = 86400
		maxretry = 1

		# BAN ATTACKERS THAT TRY TO USE PHP'S URL-FOPEN() FUNCTIONALITY
		# THROUGH GET/POST VARIABLES. - EXPERIMENTAL, WITH MORE THAN A YEAR
		# OF USAGE IN PRODUCTION ENVIRONMENTS.

		[php-url-fopen]
		enabled  = true
		port     = http,https
		logpath  = %(apache_access_log)s
		bantime  = 259200
		findtime = 86400


		###### Web Applications ######

		[monit]
		#Ban clients brute-forcing the monit gui login
		enabled = false
		port    = 2812
		logpath = /var/log/monit


		###### Mail servers ######

		[postfix]
		# To use another modes set filter parameter "mode" in jail.local:
		enabled  = true
		mode     = more
		port     = smtp,465,submission,${SMTPPORT},${POP3PORT},${IMAPPORT}
		logpath  = %(postfix_log)s
		backend  = %(postfix_backend)s
		bantime  = 259200
		findtime = 86400

		[postfix-rbl]
		enabled  = true
		filter   = postfix[mode=rbl]
		port     = smtp,465,submission,${SMTPPORT},${POP3PORT},${IMAPPORT}
		logpath  = %(postfix_log)s
		backend  = %(postfix_backend)s
		bantime  = 259200
		findtime = 86400
		maxretry = 1

		[sendmail-auth]
		enabled = true
		port    = submission,465,smtp,${SMTPPORT},${POP3PORT},${IMAPPORT}
		logpath = %(syslog_mail)s
		backend = %(syslog_backend)s

		[sendmail-reject]
		# TO USE MORE AGGRESSIVE MODES SET FILTER PARAMETER "MODE" IN JAIL.LOCAL:
		# NORMAL (DEFAULT), EXTRA OR AGGRESSIVE
		# SEE "TESTS/FILES/LOGS/SENDMAIL-REJECT" OR "FILTER.D/SENDMAIL-REJECT.CONF" FOR USAGE EXAMPLE AND DETAILS.
		enabled  = true
		#mode    = normal
		port     = smtp,465,submission,${SMTPPORT},${POP3PORT},${IMAPPORT}
		logpath  = %(syslog_mail)s
		backend  = %(syslog_backend)s


		# MAIL SERVERS AUTHENTICATORS: MIGHT BE USED FOR SMTP,FTP,IMAP SERVERS, SO
		# ALL RELEVANT PORTS GET BANNED

		[postfix-sasl]
		enabled  = true
		filter   = postfix[mode=auth]
		port     = smtp,465,submission,imap,imaps,pop3,pop3s,${SMTPPORT},${POP3PORT},${IMAPPORT}
		# YOU MIGHT CONSIDER MONITORING /VAR/LOG/MAIL.WARN INSTEAD IF YOU ARE
		# RUNNING POSTFIX SINCE IT WOULD PROVIDE THE SAME LOG LINES AT THE
		# "WARN" LEVEL BUT OVERALL AT THE SMALLER FILESIZE.
		logpath  = %(postfix_log)s
		backend  = %(postfix_backend)s
		bantime  = 259200
		findtime = 86400

		[ufw-port-scan]
		enabled   = true
		port      = all
		filter    = ufw-port-scan
		logpath   = /var/log/ufw.log
		bantime   = 604800
		findtime  = 86400
		maxretry  = 3


		###### JAIL FOR MORE EXTENDED BANNING OF PERSISTENT ABUSERS ######
		# !!! WARNINGS !!!
		# 1. Make sure that your loglevel specified in fail2ban.conf/.local
		#    is not at DEBUG level -- which might then cause fail2ban to fall into
		#    an infinite loop constantly feeding itself with non-informative lines
		# 2. Increase dbpurgeage defined in fail2ban.conf to e.g. 648000 (7.5 days)
		#    to maintain entries for failed logins for sufficient amount of time

		[recidive]
		enabled   = true
		logpath   = /var/log/fail2ban.log
		banaction = %(banaction_allports)s
		bantime   = 2419000
		findtime  = 604800


		# Generic filter for PAM. Has to be used with action which bans all
		# ports such as iptables-allports, shorewall

		[pam-generic]
		enabled   = true
		# PAM-GENERIC FILTER CAN BE CUSTOMIZED TO MONITOR SPECIFIC SUBSET OF 'TTY'S
		banaction = %(banaction_allports)s
		logpath   = %(syslog_authpriv)s
		backend   = %(syslog_backend)s
		bantime   = 259200
		findtime  = 86400

		[phpmyadmin-syslog]
		enabled  = true
		port     = http,https
		logpath  = %(syslog_authpriv)s
		backend  = %(syslog_backend)s
		bantime  = 259200
		findtime = 86400

		[zoneminder]
		# ZONEMINDER HTTP/HTTPS WEB INTERFACE AUTH
		# LOGS AUTH FAILURES TO APACHE2 ERROR LOG
		enabled  = true
		port     = http,https
		logpath  = %(apache_error_log)s
		bantime  = 259200
		findtime = 86400

EOF

        ############### CHANGE PROTOCOL FROM 'TCP' TO 'ALL' IN ACTIONS ###############
#         configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/dshield.conf >/dev/null 2>&1
#         configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/mynetwatchman.conf >/dev/null 2>&1
#         configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/nftables.conf >/dev/null 2>&1
#         configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/nftables-common.conf >/dev/null 2>&1
#         configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/pf.conf >/dev/null 2>&1
#         configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/firewallcmd-common.conf >/dev/null 2>&1
        configLine "^[# \\t]*protocol[ =\\t].*$"  "protocol = all" /etc/fail2ban/action.d/iptables-common.conf >/dev/null 2>&1


        ############### FIX REGEX FOR __bsd_syslog_verbose ###############
        # It doesn't seem to work right with auth.log's date format (mmm d).
        sudo cp /etc/fail2ban/filter.d/common.conf /etc/fail2ban/filter.d/common.local
        configLine "^[# ]*__bsd_syslog_verbose.*$"  "__bsd_syslog_verbose = (<[^.]+ [^.]+>)" /etc/fail2ban/filter.d/common.local >/dev/null 2>&1


        ############### CREATE A FILE WITH CORRECT UBUNTU PATHS ###############
        # Stunningly, even the development versions of fail2ban use Debian
        # some of which are simply wrong on Ubuntu.

        sudo rm -f /etc/fail2ban/paths-ubuntu.conf
        sudo touch /etc/fail2ban/paths-ubuntu.conf

        sudo tee -a /etc/fail2ban/paths-ubuntu.conf <<- EOF >/dev/null 2>&1
		# Ubuntu log-file locations

		[INCLUDES]
		before = paths-common.conf
		after  = paths-overrides.local

		[DEFAULT]
		syslog_local0 = /var/log/syslog
		syslog_mail = /var/log/mail.log

		# control the 'mail.warn' setting, see '/etc/rsyslog.d/50-default.conf (if commented 'mail.*' wins).
		# syslog_mail_warn = /var/log/mail.warn
		syslog_mail_warn = %(syslog_mail)s

		exim_main_log = /var/log/exim4/mainlog
		mysql_log = /var/log/mysql/error.log
		postfix_log = %(syslog_mail)s
		proftpd_log = /var/log/proftpd/proftpd.log

EOF

        ############### BLOCK PORT SCANNERS LOGGED BY UFW ###############

        # Create filter file for UFW port scan blocker
        sudo rm -f /etc/fail2ban/filter.d/ufw-port-scan.conf
        sudo touch /etc/fail2ban/filter.d/ufw-port-scan.conf

        sudo tee -a /etc/fail2ban/filter.d/ufw-port-scan.conf <<- EOF >/dev/null 2>&1
		[Definition]
		failregex = .*\[UFW BLOCK\] IN=.* SRC=<HOST>
		ignoreregex =

EOF

        ###############
        # CREATE AND INSTALL AN UPDATED apache-badbots.conf FILE. PACKAGED VERSION IS FROM 2013!
        ###############

        # Clone fail2ban github repo and generate new apache-badbots.conf file
        mkdir -p ~/tmp
        cd ~/tmp
        git clone https://github.com/fail2ban/fail2ban
        cd ~/tmp/fail2ban
        ./files/gen_badbots

        # Modify the too-strict regex in apache-badbots.conf
        # OLD: failregex = ^<HOST> -.*"(GET|POST).*HTTP.*"(?:%(badbots)s|%(badbotscustom)s)"$
        # NEW: failregex = ^<HOST> -.*"(GET|POST).*HTTP.*"(.*?:%(badbots)s|%(badbotscustom)s).*"$
        configLine "failregex = \^<HOST> -.\*\"(GET\|POST).\*HTTP.\*\"(?:%(badbots)s\|%(badbotscustom)s)\"\$"  "failregex = ^<HOST> -.*\"(GET|POST).*HTTP.*\"(.*?:%(badbots)s|%(badbotscustom)s).*\"$"  ~/tmp/fail2ban/config/filter.d/apache-badbots.conf >/dev/null 2>&1

#         # TEMPORARILY DISABLED -- SITE DOWN.
#         # Replace the list of bad bots with a better one.
#         #BADBOTLIST=$(wget -q -O- "https://raw.githubusercontent.com/mitchellkrogza/apache-ultimate-bad-bot-blocker/master/_generator_lists/bad-user-agents.list" | uniq | sed -e 's/\\ / /g' | sed -e 's/\([.\:|()+]\)/\\\1/g' | tr '\n' '|' | sed -e 's/|$//g')
#
        # VARIABLE SET MANUALLY DUE TO PROBLEMS ACCESSING URL
        BADBOTLIST="360Spider|404checker|404enemy|80legs|Abonti|Aboundex|Aboundexbot|Acunetix|ADmantX|AfD-Verbotsverfahren|AhrefsBot|AIBOT|AiHitBot|Aipbot|Alexibot|Alligator|AllSubmitter|AlphaBot|Anarchie|Apexoo|archive\\.org_bot|arquivo\\.pt|arquivo-web-crawler|ASPSeek|Asterias|Attach|autoemailspider|AwarioRssBot|AwarioSmartBot|BackDoorBot|Backlink-Ceck|backlink-check|BacklinkCrawler|BackStreet|BackWeb|Badass|Bandit|Barkrowler|BatchFTP|Battleztar Bazinga|BBBike|BDCbot|BDFetch|BetaBot|Bigfoot|Bitacle|Blackboard|Black Hole|BlackWidow|BLEXBot|Blow|BlowFish|Boardreader|Bolt|BotALot|Brandprotect|Brandwatch|Buddy|BuiltBotTough|BuiltWith|Bullseye|BunnySlippers|BuzzSumo|Calculon|CATExplorador|CazoodleBot|CCBot|Cegbfeieh|CheeseBot|CherryPicker|CheTeam|ChinaClaw|Chlooe|Claritybot|Cliqzbot|Cloud mapping|coccocbot-web|Cogentbot|cognitiveseo|Collector|com\\.plumanalytics|Copier|CopyRightCheck|Copyscape|Cosmos|Craftbot|crawler4j|crawler\\.feedback|crawl\\.sogou\\.com|CrazyWebCrawler|Crescent|CrunchBot|CSHttp|Curious|Custo|DatabaseDriverMysqli|DataCha0s|DBLBot|demandbase-bot|Demon|Deusu|Devil|Digincore|DigitalPebble|DIIbot|Dirbuster|Disco|Discobot|Discoverybot|Dispatch|DittoSpyder|DnyzBot|DomainAppender|DomainCrawler|DomainSigmaCrawler|DomainStatsBot|Dotbot|Download Wonder|Dragonfly|Drip|DSearch|DTS Agent|EasyDL|Ebingbong|eCatch|ECCP/1\\.0|Ecxi|EirGrabber|EMail Siphon|EMail Wolf|EroCrawler|evc-batch|Evil|Exabot|Express WebPictures|ExtLinksBot|Extractor|ExtractorPro|Extreme Picture Finder|EyeNetIE|Ezooms|facebookscraper|FDM|FemtosearchBot|FHscan|Fimap|Firefox/7\\.0|FlashGet|Flunky|Foobot|Freeuploader|FrontPage|FyberSpider|Fyrebot|GalaxyBot|Genieo|GermCrawler|Getintent|GetRight|GetWeb|Gigablast|Gigabot|G-i-g-a-b-o-t|Go-Ahead-Got-It|Gotit|GoZilla|Go!Zilla|Grabber|GrabNet|Grafula|GrapeFX|GrapeshotCrawler|GridBot|GT\\:\\:WWW|Haansoft|HaosouSpider|Harvest|Havij|HEADMasterSEO|heritrix|Heritrix|Hloader|HMView|HTMLparser|HTTP\\:\\:Lite|HTTrack|Humanlinks|HybridBot|Iblog|IDBot|Id-search|IlseBot|Image Fetch|Image Sucker|IndeedBot|Indy Library|InfoNaviRobot|InfoTekies|instabid|Intelliseek|InterGET|Internet Ninja|InternetSeer|internetVista monitor|ips-agent|Iria|IRLbot|Iskanie|IstellaBot|JamesBOT|Jbrofuzz|JennyBot|JetCar|Jetty|JikeSpider|JOC Web Spider|Joomla|Jorgee|JustView|Jyxobot|Kenjin Spider|Keyword Density|Kozmosbot|Lanshanbot|Larbin|LeechFTP|LeechGet|LexiBot|Lftp|LibWeb|Libwhisker|Lightspeedsystems|Likse|Linkdexbot|LinkextractorPro|LinkpadBot|LinkScan|LinksManager|LinkWalker|LinqiaMetadataDownloaderBot|LinqiaRSSBot|LinqiaScrapeBot|Lipperhey|Lipperhey Spider|Litemage_walker|Lmspider|LNSpiderguy|Ltx71|lwp-request|LWP\\:\\:Simple|lwp-trivial|Magnet|Mag-Net|magpie-crawler|Mail\\.RU_Bot|Majestic12|Majestic-SEO|Majestic SEO|MarkMonitor|MarkWatch|masscan|Mass Downloader|Mata Hari|MauiBot|meanpathbot|Meanpathbot|MeanPath Bot|Mediatoolkitbot|mediawords|MegaIndex\\.ru|Metauri|MFC_Tear_Sample|Microsoft Data Access|Microsoft URL Control|MIDown tool|MIIxpc|Mister PiX|MJ12bot|Mojeek|Mojolicious|Morfeus Fucking Scanner|Mr\\.4x3|MSFrontPage|MSIECrawler|Msrabot|muhstik-scan|Musobot|Name Intelligence|Nameprotect|Navroad|NearSite|Needle|Nessus|NetAnts|Netcraft|netEstate NE Crawler|NetLyzer|NetMechanic|NetSpider|Nettrack|Net Vampire|Netvibes|NetZIP|NextGenSearchBot|Nibbler|NICErsPRO|Niki-bot|Nikto|NimbleCrawler|Nimbostratus|Ninja|Nmap|NPbot|Nutch|oBot|Octopus|Offline Explorer|Offline Navigator|OnCrawl|Openfind|OpenLinkProfiler|Openvas|OpenVAS|OrangeBot|OrangeSpider|OutclicksBot|OutfoxBot|PageAnalyzer|Page Analyzer|PageGrabber|page scorer|PageScorer|Pandalytics|Panscient|Papa Foto|Pavuk|pcBrowser|PECL\\:\\:HTTP|PeoplePal|PHPCrawl|Picscout|Picsearch|PictureFinder|Pimonster|Pi-Monster|Pixray|PleaseCrawl|plumanalytics|Pockey|POE-Component-Client-HTTP|Probethenet|ProPowerBot|ProWebWalker|Psbot|Pump|PxBroker|PyCurl|QueryN Metasearch|Quick-Crawler|RankActive|RankActiveLinkBot|RankFlex|RankingBot|RankingBot2|Rankivabot|RankurBot|RealDownload|Reaper|RebelMouse|Recorder|RedesScrapy|ReGet|RepoMonkey|Ripper|RocketCrawler|Rogerbot|RSSingBot|s1z\\.ru|SalesIntelligent|SBIder|ScanAlert|Scanbot|scan\\.lol|ScoutJet|Scrapy|Screaming|ScreenerBot|Searchestate|SearchmetricsBot|Semrush|SemrushBot|SEOkicks|SEOkicks-Robot|SEOlyticsCrawler|Seomoz|SEOprofiler|seoscanners|SeoSiteCheckup|SEOstats|serpstatbot|sexsearcher|Shodan|Siphon|SISTRIX|Sitebeam|SiteExplorer|Siteimprove|SiteLockSpider|SiteSnagger|SiteSucker|Site Sucker|Sitevigil|SlySearch|SmartDownload|SMTBot|Snake|Snapbot|Snoopy|SocialRankIOBot|Sociscraper|sogouspider|Sogou web spider|Sosospider|Sottopop|SpaceBison|Spammen|SpankBot|Spanner|sp_auditbot|Spbot|Spinn3r|SputnikBot|spyfu|Sqlmap|Sqlworm|Sqworm|Steeler|Stripper|Sucker|Sucuri|SuperBot|SuperHTTP|Surfbot|SurveyBot|Suzuran|Swiftbot|sysscan|Szukacz|T0PHackTeam|T8Abot|tAkeOut|Teleport|TeleportPro|Telesoft|Telesphoreo|Telesphorep|The Intraformant|TheNomad|Thumbor|TightTwatBot|Titan|Toata|Toweyabot|Tracemyfile|Trendiction|Trendictionbot|trendiction\\.com|trendiction\\.de|True_Robot|Turingos|Turnitin|TurnitinBot|TwengaBot|Twice|Typhoeus|UnisterBot|Upflow|URLy\\.Warning|URLy Warning|Vacuum|Vagabondo|VB Project|VCI|VeriCiteCrawler|VidibleScraper|Virusdie|VoidEYE|Voil|Voltron|Wallpapers/3\\.0|WallpapersHD|WASALive-Bot|WBSearchBot|Webalta|WebAuto|Web Auto|WebBandit|WebCollage|Web Collage|WebCopier|WEBDAV|WebEnhancer|Web Enhancer|WebFetch|Web Fetch|WebFuck|Web Fuck|WebGo IS|WebImageCollector|WebLeacher|WebmasterWorldForumBot|webmeup-crawler|WebPix|Web Pix|WebReaper|WebSauger|Web Sauger|Webshag|WebsiteExtractor|WebsiteQuester|Website Quester|Webster|WebStripper|WebSucker|Web Sucker|WebWhacker|WebZIP|WeSEE|Whack|Whacker|Whatweb|Who\\.is Bot|Widow|WinHTTrack|WiseGuys Robot|WISENutbot|Wonderbot|Woobot|Wotbox|Wprecon|WPScan|WWW-Collector-E|WWW-Mechanize|WWW\\:\\:Mechanize|WWWOFFLE|x09Mozilla|x22Mozilla|Xaldon_WebSpider|Xaldon WebSpider|Xenu|xpymep1\\.exe|YoudaoBot|Zade|Zauba|zauba\\.io|Zermelo|Zeus|zgrab|Zitebot|ZmEu|ZumBot|ZyBorg|robertdavidgraham|NetSystemsResearch"

        configLine "^[ #]*badbots =.*$"  "badbots = ${BADBOTLIST}"  ~/tmp/fail2ban/config/filter.d/apache-badbots.conf >/dev/null 2>&1


        # BACKUP apache-badbots.conf IF THERE IS NO BACKUP
        if ! [[ -f /etc/fail2ban/filter.d/apache-badbots.conf.BAK ]]; then
            sudo mv /etc/fail2ban/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/apache-badbots.conf.BAK
        fi

        # Install the new apache-badbots.conf
        sudo cp ~/tmp/fail2ban/config/filter.d/apache-badbots.conf /etc/fail2ban/filter.d/apache-badbots.conf


        ############### CREATE FAIL2BAN MONITORING SCRIPT
        if [[ -f ~/bin/f2b-monitor.sh ]]; then
            rm ~/bin/f2b-monitor.sh
        fi

        touch ~/bin/f2b-monitor.sh

        tee -a ~/bin/f2b-monitor.sh <<- EOF >/dev/null 2>&1
		#!/bin/bash

		# Fail2Ban Log Check.
		# Adapted from script by Abhishek Ghosh at https://github.com/AbhishekGhosh/Fail2Ban-Monitoring-Bash-Script

		echo ""
		echo "----------------------------------------------------------------------------"
		echo "Bad IPs from only from /var/log/fail2ban.log alone:"
		echo "-Number-IP------------------------------------------------------------------"
		grep "Ban " /var/log/fail2ban.log | grep `date +%Y-%m-%d` | awk '{print \$NF}' | sort | awk '{print \$1,"("\$1")"}' | logresolve | uniq -c | sort
		echo ""
		echo "----------------------------------------------------------------------------"
		echo "Number of password attempts failed from all non-gzipped fail2ban.log files:"
		echo "-Number---MM--DD------------------------------------------------------------"
		cat /var/log/auth.log* | grep 'Failed password' | grep sshd | awk '{print \$1,\$2}' | sort | uniq -c
		echo ""
		echo "----------------------------------------------------------------------------"
		echo "You unbanned:"
		echo "-Number-IP------------------------------------------------------------------"
		grep "Unban " /var/log/fail2ban.log | grep `date +%Y-%m-%d` | awk '{print \$NF}' | sort | awk '{print \$1,"("\$1")"}' | logresolve | uniq -c | sort
		echo ""
		echo "----------------------------------------------------------------------------"
		echo "Countries from fail2ban.log who are Banned:"
		echo "-Number-ASN-ISP-------------------------------------------------------------"
		zgrep -h "Ban " /var/log/fail2ban.log* | awk '{print $NF}' | sort | uniq -c | xargs -n 1 geoiplookup { } | sort | uniq -c | sort | sed -r 's/ GeoIP Country Edition://g' | sed -r 's/ GeoIP ASNum Edition://g'
		echo "----------------------------------------------------------------------------"
		echo ""

EOF
        chmod ug+x ~/bin/f2b-monitor.sh


        ############### CREATE FAIL2BAN BLOCKED IP LISTING SCRIPT
        if [[ -f ~/bin/f2b-banned.sh ]]; then
            rm ~/bin/f2b-banned.sh
        fi

        touch ~/bin/f2b-banned.sh

        tee -a ~/bin/f2b-banned.sh <<- EOF >/dev/null 2>&1
		#!/bin/bash
		awk '(\$(NF-1) = /Ban/){print \$NF,"("\$NF")"}' /var/log/fail2ban.log | sort | logresolve | uniq -c | sort -n | lnav

EOF
        # Make the script executable
        sudo chmod ug+x ~/bin/f2b-banned.sh


        ############### RESTART FAIL2BAN ###############
        # (RE)START FAIL2BAN AND RELOAD CONFIG
        sudo fail2ban-client reload
        sudo systemctl restart fail2ban

        # Enable fail2ban on startup
        sudo systemctl enable fail2ban


        # REMOVE TEMP FILES
        sudo rm -rf ~/tmp/fail2ban


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
# INSTALL APACHE SECURITY MODULES
########################################
if [[ "$APACHESECSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing APACHE SECURITY MODULES...${RST}"

    #########################
    # INSTALL THE SOFTWARE
    #########################
    sudo apt update -y
    sudo apt autoremove -y
    sudo apt install -y --install-recommends apache2 apache2-dev apache2-utils libapache2-mod-evasive ca-certificates dh-autoreconf gawk git iputils-ping libapache2-mod-security2 libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev libpcre++-dev libpcre3-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales lua5.2-dev pkgconf wget zlib1g-dev zlibc

    # CREATE LOG FILE AND SET ITS OWNSERSHIP AND PERMISSIONS
    sudo touch /var/log/apache2/modsec_audit.log
    sudo chown www-data:www-data /var/log/apache2/modsec_audit.log
    sudo chmod 660 /var/log/apache2/modsec_audit.log

    #########################
    # CONFIGURE MOD_EVASIVE
    #########################

    # IF BACKUP OF CONF FILE EXISTS, RESTORE IT BEFORE PROCEEDING. OTHERWISE, MAKE BACKUP
    if [[ -f "/etc/apache2/mods-enabled/evasive.conf.BAK" ]]; then
        # RESTORE BACKUP
        sudo rm -f /etc/apache2/mods-enabled/evasive.conf
        sudo cp /etc/apache2/mods-enabled/evasive.conf.BAK /etc/apache2/mods-enabled/evasive.conf
    else
        # MAKE BACKUP AND REMOVE ORIGINAL
        sudo mv -f /etc/apache2/mods-enabled/evasive.conf /etc/apache2/mods-enabled/evasive.conf.BAK
        sudo rm -f /etc/apache2/mods-enabled/evasive.conf
    fi


    # TRANSFORM WHITELISTED IPS INTO FORMAT SUITABLE FOR MOD_EVASIVE

    # Read values into new variable
    EVASIVE_WHITELISTEDIPS="${WHITELISTEDIPS}"
    # Change CIDR notation to asterisks (only works for /8, /16 and /24.
    EVASIVE_WHITELISTEDIPS=$(echo "${EVASIVE_WHITELISTEDIPS}" | sed -r 's/([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\/8/*.*.*/gm')
    EVASIVE_WHITELISTEDIPS=$(echo "${EVASIVE_WHITELISTEDIPS}" | sed -r 's/([0-9]{1,3})\.([0-9]{1,3})\/16/*.*/gm')
    EVASIVE_WHITELISTEDIPS=$(echo "${EVASIVE_WHITELISTEDIPS}" | sed -r 's/([0-9]{1,3})\/24/*/gm')
    # INSERT 'DOSWhitelist' BEFORE EACH IP AND \n AFTER EACH ONE
    EVASIVE_WHITELISTEDIPS=$(echo "${EVASIVE_WHITELISTEDIPS}" | sed -r 's/(^| )/      DOSWhitelist        /gm')
    EVASIVE_WHITELISTEDIPS=$(echo "${EVASIVE_WHITELISTEDIPS}" | sed -r 's/([0-9*])($| )/\1\n/gm')

    # MODIFY MOD_EVASIVE CONFIG FILE
    sudo tee -a /etc/apache2/mods-enabled/evasive.conf <<- EOF >/dev/null 2>&1
	<IfModule mod_evasive20.c>
	     DOSHashTableSize    3097
	     DOSPageCount        5
	     DOSSiteCount        60
	     DOSPageInterval     2
	     DOSSiteInterval     2
	     DOSBlockingPeriod   60
	${EVASIVE_WHITELISTEDIPS}
	    DOSEmailNotify      ${ADMINMAILADDR}
	#   DOSSystemCommand    "su - someuser -c '/sbin/... %s ...'"
	    DOSLogDir           "/var/log/apache2"
	</IfModule>

EOF


    #########################
    # CONFIGURE MOD_SECURITY
    #########################

    # COPY CONFIG TEMPLATE
    sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

    # CHANGE CONFIGURATION TO TURN MOD_SECURITY ON
    configLine "^[# ]*SecRuleEngine.*$" "SecRuleEngine on" /etc/modsecurity/modsecurity.conf >/dev/null 2>&1

    # FIX MOD_SECURITY LOGFILE OWNERSHIP AND PERMISSIONS
    sudo chown www-data:www-data /var/log/apache2/modsec_audit.log
    sudo chmod 660 /var/log/apache2/modsec_audit.log


    # CREATE WHITELIST

    # Read values into new variable
    MODSEC_WHITELISTIPS="${WHITELISTEDIPS}"

    # Eliminate common reserved addresses (there are actually a ton more)
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/(^| )0\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[\/]*[0-9]{0,3}//gm')
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/(^| )10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[\/]*[0-9]{0,3}//gm')
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[\/]*[0-9]{0,3}//gm')
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}[\/]*[0-9]{0,3}//gm')

    # Remove multiple spaces and string-initial space
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/[ ]+/ /gm')
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/^ //gm')

    # Replace spaces with newlines
    MODSEC_WHITELISTIPS=$(echo "${MODSEC_WHITELISTIPS}" | sed -r 's/ /\n/gm')

    # Reset rule id counter
    COUNTER=0

    # Iterate over each IP address contained in the whitelist, create the appropriate rule
    # using a counter for the 'id', and append it to /etc/modsecurity/modsecurity.conf
    echo "$MODSEC_WHITELISTIPS" | while read IP; do

        # Increment counter
        COUNTER=$(( $COUNTER + 1 ))

        # Create rule for current IP address and counter value
        RULE="SecRule REMOTE_ADDR \"@contains $IP\" \"id:${COUNTER},phase:1,nolog,allow,ctl:ruleEngine=Off\""
        echo "${RULE}"

        # Append rul to mod_security config file.
        echo -e "${RULE}" | sudo tee -a /etc/modsecurity/modsecurity.conf >/dev/null 2>&1

    done

    # SET HIGHER VALUES FOR TWO VARIABLES IN ORDER TO PREVENT "EXECUTION ERROR - PCRE LIMITS EXCEEDED (-8)" ERRORS
    configLine "^[# ]*SecPcreMatchLimit .*$"  "SecPcreMatchLimit 500000"  /etc/modsecurity/modsecurity.conf >/dev/null 2>&1
    configLine "^[# ]*SecPcreMatchLimitRecursion.*$"  "SecPcreMatchLimitRecursion 500000"  /etc/modsecurity/modsecurity.conf >/dev/null 2>&1


    # DISABLE CERTAIN MOD_SECURITY RULES THAT TRIGGER FALSE POSITIVES WITH PARANOIA LEVEL 2
    # This is VERY important if you use modsec with paranoia level 2 -- otherwise, many CQPweb operations will fail!
    echo "SecRuleRemoveById 920230" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 920350" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 921151" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 942120" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 942130" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 942260" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 942370" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 942430" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 951120" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 951230" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 951260" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 980140" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 941340" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1
    echo "SecRuleRemoveById 942340" | sudo tee -a /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf  >/dev/null 2>&1


    # RESTART APACHE SERVER
    sudo systemctl restart apache2.service


    #########################
    # INSTALL AND CONFIGURE OWASP MODSECURITY CORE RULE SET FOR MOD_SECURITY
    #########################

    # STASH BUILT-IN MOD_SECURITY RULES WHERE THEY WON'T BE READ
    sudo mv /usr/share/modsecurity-crs /usr/share/modsecurity-crs.BAK

    # CLONE OWASP CRS GITHUB
    sudo git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs


    # CREATE PERSONAL CONFIG FILE USING TEMPLATE
    sudo cp /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf


    ##### CONFIGURE MOD_SECURITY TO USE OWASP CRS #####

    # If backup exists, restore it before proceeding. otherwise, make backup
    if [[ -f "/etc/apache2/mods-enabled/security2.conf.BAK" ]]; then
        # RESTORE BACKUP
        sudo rm /etc/apache2/mods-enabled/security2.conf
        sudo cp /etc/apache2/mods-enabled/security2.conf.BAK /etc/apache2/mods-enabled/security2.conf
    else
        # MAKE BACKUP
        sudo cp /etc/apache2/mods-enabled/security2.conf /etc/apache2/mods-enabled/security2.conf.BAK
    fi

    # Edit contents of /etc/apache2/mods-enabled/security2.conf
    configLine "^[# \\t]*IncludeOptional \/usr\/share\/modsecurity-crs\/owasp-crs.*$" "\\tIncludeOptional /usr/share/modsecurity-crs/*.conf\\n\\tIncludeOptional /usr/share/modsecurity-crs/rules/*.conf" /etc/apache2/mods-enabled/security2.conf >/dev/null 2>&1

    # Create user config files from templates
    sudo cp /usr/share/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /usr/share/modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
    sudo cp /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /usr/share/modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

    # WARNING
    # FOR NOW, /usr/share/modsecurity-crs/crs-setup.conf MUST BE HAND-CONFIGURED.


    echo "${CGRN}${BLD}==========> APACHE SECURITY MODULES installation finished.${RST}"
    echo       "${CRED}            Kindly reboot after the script finishes!${RST}"
    echo ""

else
    echo "${CORG}${BLD}==========> Skipping APACHE SECURITY MODULES...${RST}"
fi



########################################
# INSTALL THE FREELING TAGGER
########################################
if [[ "$FREELINGSW" = 1 ]]; then

    echo ""
    echo "${CLBL}${BLD}==========> Installing FREELING...${RST}"

    # INSTALL REQUIRED DISTRO PACKAGES
    sudo apt update -y
    sudo apt autoremove -y
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
    sudo apt autoremove -y
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
        sudo apt autoremove -y
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
    sudo apt autoremove -y
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
    sudo apt autoremove -y
    sudo apt upgrade -y

    # INSTALL DISTRO SOFTWARE
    sudo apt install -y --install-recommends csvkit csvkit-doc dos2unix ipython3 jupyter libopenblas-dev libxml2-dev libxml2-utils locales-all python-numpy-doc python-pandas-doc python-scipy-doc python-scrapy-doc python-sklearn-doc python-tweepy-doc python3-nltk python3-numpy python3-pandas python3-pip python3-regex python3-scipy python3-scrapy python3-sklearn python3-tweepy r-base-dev recode virtualenv

    # INSTALL SOFTWARE FOR OLD DEBIAN VERSIONS
    if [[ "$(which csvkit)" = "" ]]; then
        sudo apt install -y --install-recommends python-csvkit
    fi

    if [[ "$(which jupyter)" = "" ]]; then
        sudo apt install -y --install-recommends python3-jupyter-core
    fi

    if [[ "$(which python-scrapy)" = "" ]]; then
        sudo apt install -y --install-recommends python-scrapy
    fi


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
    sudo apt autoremove -y
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


 MOSHPORT=YOUR_INFO_HERE # CHOOSE A RANDOM HIGH PORT FOR THIS (10000-60000 IS A GOOD RANGE)
       FREELINGESCLMODS=0   # Modify FreeLing's Chilean Spanish install.
cwb_max_ram_usage_cli         = 1024
  IMAGEUPLD=0               # Upload specified image to use as top left/right graphic in CQPweb. Set location and URL below.
  IMAGESOURCE="YOUR_INFO_HERE" # URL of top left/right logo image source file.
   FAVICONUPLD=0             # Upload favicon.ico to root of website?
  FAVICONURL="YOUR_INFO_HERE" # Source URL of favicon.ico.
     WEBFONTNAME="YOUR_INFO_HERE" # Name of web font. Check out https://fonts.google.com/ for more. Firefox doesn't seem to use
