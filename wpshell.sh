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
# Prefix WPSHELL_ to variables to prevent issues
WPSKIP="wp --skip-plugins --skip-themes"

WPSHELL_WPCLI_CHECK() { ${WPSKIP} core version 2>/dev/null | wc -l; }
WPSHELL_SITE_URL() { ${WPSKIP} option get siteurl; }
WPSHELL_CHECKSUMS() { ${WPSKIP} core verify-checksums 2>&1 | wc -l; }

# General Site Configuration
WPSHELL_WP_VERSION() { ${WPSKIP} core version; }
WPSHELL_HOME_URL() { ${WPSKIP} option get home; }
WPSHELL_STYLESHEET() { ${WPSKIP} option get stylesheet; }
WPSHELL_TEMPLATE() { ${WPSKIP} option get template; }
WPSHELL_WP_MEMORY_LIMIT() { ${WPSKIP} eval 'echo WP_MEMORY_LIMIT;' 2>/dev/null; }
WPSHELL_WP_MAX_MEMORY_LIMIT() { ${WPSKIP} eval 'echo WP_MAX_MEMORY_LIMIT;' 2>/dev/null; }

# Update Counts
WPSHELL_COUNT_PLUGIN_UPDATES() { ${WPSKIP} plugin list | grep -c available; }
WPSHELL_COUNT_THEME_UPDATES() { ${WPSKIP} theme list | grep -c available; }
WPSHELL_COUNT_CORE_UPDATES() { ${WPSKIP} core check-update | grep -c wordpress; }
WPSHELL_COUNT_PLUGIN_TOTAL() { ${WPSKIP} plugin list --field=name | wc -l; }
WPSHELL_COUNT_THEME_TOTAL() { ${WPSKIP} theme list --field=name | wc -l; }

# PHP Environment
WPSHELL_PHP_VERSION() { php -r 'echo PHP_VERSION;' 2>/dev/null; }
WPSHELL_PHP_MEMORY_LIMIT() { php -r 'echo ini_get("memory_limit");' 2>/dev/null; }
WPSHELL_PHP_MAX_INPUT_VARS() { php -r 'echo ini_get("max_input_vars");' 2>/dev/null; }

# Database Connection 
DB_CONNECTION_DETAILS() {
  # Get WordPress DB credentials using WP constants via WP-CLI
  WPSHELL_DBNAME=$(${WPSKIP} eval 'echo DB_NAME;')
  WPSHELL_DBUSER=$(${WPSKIP} eval 'echo DB_USER;')
  WPSHELL_DBPASS=$(${WPSKIP} eval 'echo DB_PASSWORD;')
  WPSHELL_DBHOST=$(${WPSKIP} eval 'echo DB_HOST;')
  WPSHELL_DBPREFIX=$(${WPSKIP} eval 'global $wpdb; echo $wpdb->prefix;')

  # Test MySQL connection using retrieved credentials and store result in global var
  if [ -n "${WPSHELL_DBPASS}" ]; then
    mysql -u "${WPSHELL_DBUSER}" -p"${WPSHELL_DBPASS}" -h "${WPSHELL_DBHOST}" -e ";" >/dev/null 2>&1
  else
    mysql -u "${WPSHELL_DBUSER}" -h "${WPSHELL_DBHOST}" -e ";" >/dev/null 2>&1
  fi && WPSHELL_DB_CONNECTION_STATUS="Success" || WPSHELL_DB_CONNECTION_STATUS="Failure"
}


########## GLOBAL FUNCTIONS END ##########

########## EMPHASIS AND COLORS START ##########
WPSHELL_TEXT_BOLD="\033[1m"
#TEXT_UNDERLINE="\033[4m"
WPSHELL_TEXT_RESET="\033[0m"
########## EMPHASIS AND COLORS END ##########

##### SAFETY CHECKS START #####
# Function names begin with CheckFunction
function CheckWPCLI() {
# Use WP-CLI to check the core version. A successful check returns one line. If not, prompt to install WP-CLI as the command likely failed. 
  if [ -f wp-config.php ]; then
    local result=$(WPSHELL_WPCLI_CHECK | tr -d '\n\r ')
    if [ "${result}" != "1" ]; then
      echo -e "${WPSHELL_TEXT_BOLD}WP-CLI CHECK: [FAILED]${WPSHELL_TEXT_RESET}"
      echo -e "Is WP-CLI installed? Try running: ${WPSHELL_TEXT_BOLD}wpcliinstall${WPSHELL_TEXT_RESET}"
    else
      echo -e "${WPSHELL_TEXT_BOLD}WP-CLI CHECK: [OK]${WPSHELL_TEXT_RESET}"
    fi
  fi
}


function CheckDirectory(){
# Check for the existence of the wp-config.php file. Return warning if not found.
if [ ! -f wp-config.php ]; then
echo -e "${WPSHELL_TEXT_BOLD}
WARNING:
No wp-config.php file found. Most commands are designed to work from the WordPress directory!${WPSHELL_TEXT_RESET}"
fi
}

function CheckMaintenanceMode(){
# Curl homepage checking for coming soon or maintenance mode
curl -s "${WPSHELL_SITE_URL}" | grep -qi 'coming soon\|maintenance' && echo -e "${WPSHELL_TEXT_BOLD}
MAINT CHECK: [FAILED] ${WPSHELL_TEXT_RESET}
Keywords found on site that indicate it may have a coming soon page. Not all WP-CLI functions will work properly."
}
##### SAFETY CHECKS END #####

#################### SETUP END ####################


#################### MENU START ####################
function wpshell(){
clear
echo -e "${WPSHELL_TEXT_BOLD}
  _      _____    ______       ____
 | | /| / / _ \  / __/ /  ___ / / /
 | |/ |/ / ___/ _\ \/ _ \/ -_) / / 
 |__/|__/_/    /___/_//_/\__/_/_/
${WPSHELL_TEXT_RESET}
Type ${WPSHELL_TEXT_BOLD}wpshell${WPSHELL_TEXT_RESET} to return to this list of options:
  ${WPSHELL_TEXT_BOLD} wpstats ${WPSHELL_TEXT_RESET}  - Show Version, URL, DB Info, Number of Available Updates

WordPress Specific:
  
Helpful Functions:
  ${WPSHELL_TEXT_BOLD} fcount ${WPSHELL_TEXT_RESET}   - Lists Number of Files in Current Directory
  ${WPSHELL_TEXT_BOLD} dirsize ${WPSHELL_TEXT_RESET}  - Sorts Directory Contents by Size
  ${WPSHELL_TEXT_BOLD} ext ${WPSHELL_TEXT_RESET}      - Handy Extraction Program (ext file.ext)
  
Troubleshooting:
 
${WPSHELL_TEXT_RESET}"
# Perform SAFETY CHECKS
CheckWPCLI
CheckDirectory
CheckMaintenanceMode
}
#################### MENU END ####################

function wpstats() {
# Populate DB credentials and test connection; sets globals like WPSHELL_DBNAME etc.
DB_CONNECTION_DETAILS

echo -e "
### SITE TESTS ###
${WPSHELL_TEXT_BOLD}WPCLI Check:${WPSHELL_TEXT_RESET}      $([ \"$(WPSHELL_WPCLI_CHECK)\" -eq 1 ] && echo '[OK]' || echo '[FAILED]')
${WPSHELL_TEXT_BOLD}Checksums:${WPSHELL_TEXT_RESET}        $([ \"$(WPSHELL_CHECKSUMS)\" -eq 1 ] && echo '[OK]' || echo "[FAILED] - $(WPSHELL_CHECKSUMS) files differ")

### GENERAL INFO ###
${WPSHELL_TEXT_BOLD}WP Version:${WPSHELL_TEXT_RESET}       $(WPSHELL_WP_VERSION)
${WPSHELL_TEXT_BOLD}Site URL:${WPSHELL_TEXT_RESET}         $(WPSHELL_SITE_URL)
${WPSHELL_TEXT_BOLD}Home URL:${WPSHELL_TEXT_RESET}         $(WPSHELL_HOME_URL)
${WPSHELL_TEXT_BOLD}Stylesheet:${WPSHELL_TEXT_RESET}       $(WPSHELL_STYLESHEET)
${WPSHELL_TEXT_BOLD}Template:${WPSHELL_TEXT_RESET}         $(WPSHELL_TEMPLATE)

### DATABASE INFO ###
${WPSHELL_TEXT_BOLD}Database Conn:${WPSHELL_TEXT_RESET}    ${WPSHELL_DB_CONNECTION_STATUS}
${WPSHELL_TEXT_BOLD}Database Name:${WPSHELL_TEXT_RESET}    ${WPSHELL_DBNAME}
${WPSHELL_TEXT_BOLD}Database User:${WPSHELL_TEXT_RESET}    ${WPSHELL_DBUSER}
${WPSHELL_TEXT_BOLD}Database Pass:${WPSHELL_TEXT_RESET}    ${WPSHELL_DBPASS}
${WPSHELL_TEXT_BOLD}Database Host:${WPSHELL_TEXT_RESET}    ${WPSHELL_DBHOST}
${WPSHELL_TEXT_BOLD}Database Prefix:${WPSHELL_TEXT_RESET}  ${WPSHELL_DBPREFIX}

### PHP & UPDATES ###
${WPSHELL_TEXT_BOLD}PHP Version:${WPSHELL_TEXT_RESET}      $(WPSHELL_PHP_VERSION)
${WPSHELL_TEXT_BOLD}Memory Limit:${WPSHELL_TEXT_RESET}     $(WPSHELL_PHP_MEMORY_LIMIT)
${WPSHELL_TEXT_BOLD}WP Memory Limit:${WPSHELL_TEXT_RESET}  $(WPSHELL_WP_MEMORY_LIMIT)
${WPSHELL_TEXT_BOLD}WP Max Memory:${WPSHELL_TEXT_RESET}    $(WPSHELL_WP_MAX_MEMORY_LIMIT)
${WPSHELL_TEXT_BOLD}Max Input Vars:${WPSHELL_TEXT_RESET}   $(WPSHELL_PHP_MAX_INPUT_VARS)
${WPSHELL_TEXT_BOLD}Core Updates:${WPSHELL_TEXT_RESET}     $(WPSHELL_COUNT_CORE_UPDATES)
${WPSHELL_TEXT_BOLD}Plugin Updates:${WPSHELL_TEXT_RESET}   $(WPSHELL_COUNT_PLUGIN_UPDATES) of $(WPSHELL_COUNT_PLUGIN_TOTAL)
${WPSHELL_TEXT_BOLD}Theme Updates:${WPSHELL_TEXT_RESET}    $(WPSHELL_COUNT_THEME_UPDATES) of $(WPSHELL_COUNT_THEME_TOTAL)
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
            *) echo -e "${WPSHELL_COL_BOLD}\nWarning:${WPSHELL_TEXT_RESET} '$1' Unsupported Format!" ;;
        esac
    else
        echo -e "${WPSHELL_COL_BOLD}'$1' is not a valid file.${WPSHELL_TEXT_RESET} Syntax:\n  ext archive.tar.gz"
    fi
}

########## SPECIFIC ##########
#################### BASH FUNCTIONS END ####################

# Show Menu on Launch
wpshell
