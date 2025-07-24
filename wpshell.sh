#!/bin/bash
##############################################################################################################
# Name:        WP Shell                                                                                      #
# Author:      RowdyTheArchivist                                                                             #
# Description: WP-CLI wrapper and other bash WordPress tools to alleviate frustration and get the job done   #
##############################################################################################################
#################### HEADING ####################
########## SUB HEADING ##########
##### NOTE #####
### COMMENT
# Description

#################### SETUP START ####################
# Don't keep a command history
unset HISTFILE
# Allows alias usage in scripts
shopt -s expand_aliases

########## GLOBAL FUNCTIONS START ##########

WPSKIP="wp --skip-plugins --skip-themes"

WPCLI_CHECK() { ${WPSKIP} core version 2>/dev/null | wc -l; }
SITE_URL() { ${WPSKIP} option get siteurl; }
CHECKSUMS() { ${WPSKIP} core verify-checksums 2>&1 | wc -l; }

# General Site Configuration
WP_VERSION() { ${WPSKIP} core version; }
HOME_URL() { ${WPSKIP} option get home; }
STYLESHEET() { ${WPSKIP} option get stylesheet; }
TEMPLATE() { ${WPSKIP} option get template; }

# Update Counts
COUNT_PLUGIN_UPDATES() { ${WPSKIP} plugin list | grep -c available; }
COUNT_THEME_UPDATES() { ${WPSKIP} theme list | grep -c available; }
COUNT_CORE_UPDATES() { ${WPSKIP} core check-update | grep -c wordpress; }
COUNT_PLUGIN_TOTAL() { ${WPSKIP} plugin list --field=name | wc -l; }
COUNT_THEME_TOTAL() { ${WPSKIP} theme list --field=name | wc -l; }

# PHP Environment
PHP_VERSION() { php -r 'echo PHP_VERSION;' 2>/dev/null; }
PHP_MEMORY_LIMIT() { php -r 'echo ini_get("memory_limit");' 2>/dev/null; }

# Database Connection (requires DBUSER and DBPASS to be set)
DB_CONNECTION_STATUS() {
  local DBUSER DBPASS DBHOST

  DBUSER=$(awk '
    BEGIN { in_comment=0 }
    /^\s*\/\*/ { in_comment=1 }
    /\*\// { in_comment=0; next }
    in_comment == 1 { next }
    /^\s*\/\// { next }
    /^\s*#/ { next }
    /^\s*define\s*\(\s*'\''DB_USER'\''/ {
      match($0, /'\''DB_USER'\''\s*,\s*'\''([^'\'']+)'\''/, m)
      if (m[1]) print m[1]
    }' wp-config.php)

  DBPASS=$(awk '
    BEGIN { in_comment=0 }
    /^\s*\/\*/ { in_comment=1 }
    /\*\// { in_comment=0; next }
    in_comment == 1 { next }
    /^\s*\/\// { next }
    /^\s*#/ { next }
    /^\s*define\s*\(\s*'\''DB_PASSWORD'\''/ {
      match($0, /'\''DB_PASSWORD'\''\s*,\s*'\''([^'\'']+)'\''/, m)
      if (m[1]) print m[1]
    }' wp-config.php)

  DBHOST=$(awk '
    BEGIN { in_comment=0 }
    /^\s*\/\*/ { in_comment=1 }
    /\*\// { in_comment=0; next }
    in_comment == 1 { next }
    /^\s*\/\// { next }
    /^\s*#/ { next }
    /^\s*define\s*\(\s*'\''DB_HOST'\''/ {
      match($0, /'\''DB_HOST'\''\s*,\s*'\''([^'\'']+)'\''/, m)
      if (m[1]) print m[1]
    }' wp-config.php)

  mysql -u "${DBUSER}" -p"${DBPASS}" -h "${DBHOST}" -e ";" >/dev/null 2>&1 && echo "Success" || echo "Failure"
}
########## GLOBAL FUNCTIONS END ##########

########## EMPHASIS AND COLORS START ##########
TEXT_BOLD="\033[1m"
#TEXT_UNDERLINE="\033[4m"
TEXT_RESET="\033[0m"
########## EMPHASIS AND COLORS END ##########

##### SAFETY CHECKS START #####
# Function names begin with CheckFunction
function CheckWPCLI() {
# Use WP-CLI to check the core version. A successful check returns one line. If not, prompt to install WP-CLI as the command likely failed. 
  if [ -f wp-config.php ]; then
    if [ "${WPCLI_CHECK}" != "1" ]; then
      echo -e "${TEXT_BOLD}WP-CLI CHECK: [FAILED]${TEXT_RESET}"
      echo -e "Is WP-CLI installed? Try running: ${TEXT_BOLD}wpcliinstall${TEXT_RESET}"
    fi
  fi
}

function CheckDirectory(){
# Check for the existence of the wp-config.php file. Return warning if not found.
if [ ! -f wp-config.php ]; then
echo -e "${TEXT_BOLD}
WARNING:
No wp-config.php file found. Most commands are designed to work from the WordPress directory!${TEXT_RESET}"
fi
}

function CheckMaintenanceMode(){
# Curl homepage checking for coming soon or maintenance mode
curl -s "${SITE_URL}" | grep -qi 'coming soon\|maintenance' && echo -e "${TEXT_BOLD}
MAINT CHECK: [FAILED] ${TEXT_RESET}
Keywords found on site that indicate it may have a coming soon page. Not all WP-CLI functions will work properly."
}
##### SAFETY CHECKS END #####

#################### SETUP END ####################


#################### MENU START ####################
function wpshell(){
clear
echo -e "${TEXT_BOLD}
  _      _____    ______       ____
 | | /| / / _ \  / __/ /  ___ / / /
 | |/ |/ / ___/ _\ \/ _ \/ -_) / / 
 |__/|__/_/    /___/_//_/\__/_/_/
${TEXT_RESET}
Type ${TEXT_BOLD}wpshell${TEXT_RESET} to return to this list of options:
  ${TEXT_BOLD} wpstats ${TEXT_RESET}  - Show Version, URL, DB Info, Number of Available Updates

WordPress Specific:
  
Helpful Functions:
  ${TEXT_BOLD} fcount ${TEXT_RESET}   - Lists Number of Files in Current Directory
  ${TEXT_BOLD} dirsize ${TEXT_RESET}  - Sorts Directory Contents by Size
  ${TEXT_BOLD} ext ${TEXT_RESET}      - Handy Extraction Program (ext file.ext)
  
Troubleshooting:
 
${TEXT_RESET}"
# Perform SAFETY CHECKS
CheckWPCLI
CheckDirectory
CheckMaintenanceMode
}
#################### MENU END ####################

function wpstats() {
  echo -e "### SITE TESTS ###"

  # WPCLI functional check
${TEXT_BOLD}WPCLI Check:${TEXT_RESET}      $([ "$(WPCLI_CHECK)" -eq 1 ] && echo '[OK]' || echo '[FAILED]')
  # Core file checksum validation
${TEXT_BOLD}Checksums:${TEXT_RESET}        $([ "$(CHECKSUMS)" -eq 1 ] && echo '[OK]' || echo "[FAILED] - $(CHECKSUMS) files differ")

echo -e "
### GENERAL INFO ###
${TEXT_BOLD}WP Version:${TEXT_RESET}       $(WP_VERSION)
${TEXT_BOLD}Site URL:${TEXT_RESET}         $(SITE_URL)
${TEXT_BOLD}Home URL:${TEXT_RESET}         $(HOME_URL)
${TEXT_BOLD}Stylesheet:${TEXT_RESET}       $(STYLESHEET)
${TEXT_BOLD}Template:${TEXT_RESET}         $(TEMPLATE)

### DATABASE INFO ###
${TEXT_BOLD}Database Conn:${TEXT_RESET}    $(DB_CONNECTION_STATUS)
${TEXT_BOLD}Database Name:${TEXT_RESET}    $(DBNAME)
${TEXT_BOLD}Database User:${TEXT_RESET}    $(DBUSER)
${TEXT_BOLD}Database Pass:${TEXT_RESET}    $(DBPASS)
${TEXT_BOLD}Database Host:${TEXT_RESET}    $(DBHOST)
${TEXT_BOLD}Database Prefix:${TEXT_RESET}  $(DBPREFIX)

### PHP & UPDATES ###
${TEXT_BOLD}PHP Version:${TEXT_RESET}      $(PHP_VERSION)
${TEXT_BOLD}Memory Limit:${TEXT_RESET}     $(PHP_MEMORY_LIMIT)
${TEXT_BOLD}Core Updates:${TEXT_RESET}     $(COUNT_CORE_UPDATES)
${TEXT_BOLD}Plugin Updates:${TEXT_RESET}   $(COUNT_PLUGIN_UPDATES) of $(COUNT_PLUGIN_TOTAL)
${TEXT_BOLD}Theme Updates:${TEXT_RESET}    $(COUNT_THEME_UPDATES) of $(COUNT_THEME_TOTAL)
"
}

#################### WP-CLI FUNCTIONS START ####################
########## GENERAL ##########
########## SPECIFIC ##########
#################### WP-CLI FUNCTIONS END ####################

#################### HYBRID FUNCTIONS START ####################
########## GENERAL ##########
########## SPECIFIC ##########
#################### HYBRID FUNCTIONS END ####################

#################### BASH FUNCTIONS START ####################
########## GENERAL ##########
function fcount() {
# Count files in current directory 
find . -type f | wc -l
}

function dirsize() {
# List the size of items in current directory 
du -ah --max-depth=1 | sort -h
}

function ext() {
# Extract common formats
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)    tar xvjf "$1"     ;;
            *.tar.gz)     tar xvzf "$1"     ;;
            *.tar.xz)     tar xvJf "$1"     ;;
            *.tar.zst)    tar --zstd -xvf "$1" ;;
            *.tar.lz)     tar --lzip -xvf "$1" ;;
            *.tbz2)       tar xvjf "$1"     ;;
            *.tgz)        tar xvzf "$1"     ;;
            *.txz)        tar xvJf "$1"     ;;
            *.tlz)        tar --lzip -xvf "$1" ;;
            *.tar)        tar xvf "$1"      ;;
            *.bz2)        bunzip2 "$1"      ;;
            *.gz)         gunzip "$1"       ;;
            *.xz)         unxz "$1"         ;;
            *.lz)         lzip -d "$1"      ;;
            *.zst)        unzstd "$1"       ;;  
            *.Z)          uncompress "$1"   ;;
            *.zip)        unzip "$1"        ;;
            *.rar)        unrar x "$1"      ;;
            *.7z)         7z x "$1"         ;;
            *) echo -e "${COL_BOLD}\nWarning:${TEXT_RESET} '$1' Unsupported Format!" ;;
        esac
    else
        echo -e "${COL_BOLD}'$1' is not a valid file.${TEXT_RESET} Syntax:\n  ext archive.tar.gz"
    fi
}

########## SPECIFIC ##########
#################### BASH FUNCTIONS END ####################

# Show Menu on Launch
wpshell
