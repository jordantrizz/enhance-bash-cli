# =============================================================================
# -- enhance-bash-cli - Core library
# =============================================================================

# =============================================================================
# -- Variables
# =============================================================================
REQUIRED_APPS=("jq" "column")
typeset -gA ebc_functions

# ==================================
# -- Colors
# ==================================
NC=$(tput sgr0)
CRED='\e[0;31m'
CRED=$(tput setaf 1)
CYELLOW=$(tput setaf 3)
CGREEN=$(tput setaf 2)
CBLUEBG=$(tput setab 4)
CCYAN=$(tput setaf 6)
CGRAY=$(tput setaf 7)
CDARKGRAY=$(tput setaf 8)

# =============================================================================
# -- Core Functions
# =============================================================================

# =====================================
# -- messages
# =====================================

_error () { [[ $QUIET == "0" ]] && echo -e "${CRED}** ERROR ** - ${*} ${NC}" >&2; } 
_warning () { [[ $QUIET == "0" ]] && echo -e "${CYELLOW}** WARNING ** - ${*} ${NC}"; }
_success () { [[ $QUIET == "0" ]] && echo -e "${CGREEN}** SUCCESS ** - ${*} ${NC}"; }
_running () { [[ $QUIET == "0" ]] && echo -e "${CBLUEBG}${*}${NC}"; }
_running2 () { [[ $QUIET == "0" ]] && echo -e " * ${CGRAY}${*}${NC}"; }
_running3 () { [[ $QUIET == "0" ]] && echo -e " ** ${CDARKGRAY}${*}${NC}"; }
_creating () { [[ $QUIET == "0" ]] && echo -e "${CGRAY}${*}${NC}"; }
_separator () { [[ $QUIET == "0" ]] && echo -e "${CYELLOWBG}****************${NC}"; }
_dryrun () { [[ $QUIET == "0" ]] && echo -e "${CCYAN}** DRYRUN: ${*$}${NC}"; }
_quiet () { [[ $QUIET == "1" ]] && echo -e "${*}"; }

# =====================================
# -- _debug $*
# -- Debug messaging
# =====================================
ebc_functions[_debug]="Debug messaging"
_debug () {
    if [[ $DEBUG == "1" ]]; then
        # Print ti stderr
        echo -e "${CCYAN}** DEBUG ** - ${*}${NC}" >&2
    fi
}

# =====================================
# -- _debug_json_file $*
# -- Debug messaging for json
# =====================================
ebc_functions[_debug_json_file]="Debug messaging for json"
_debug_json_file () {
    if [[ $DEBUG_JSON == "1" ]]; then
        echo -e "${*}" >> /tmp/debug.json
    fi
}

# =====================================
# -- _pre_flight_check
# -- Check to make sure apps and api credentials are available
# =====================================
ebc_functions[_pre_flight_check]="Check to make sure apps and api credentials are available"
function _pre_flight_check () {
    # -- Check enhance creds
    _debug "Checking for enhance credentials"
    _check_creds

    # -- Check required
    _debug "Checking for required apps"
    _check_required_apps

    # -- Check bash
    _debug "Checking for bash version"
    _check_bash

    # -- Check debug
    _debug "Checking for debug"
    _check_debug
}

# =====================================
# -- _check_api_creds
# -- Check for API credentials
# =====================================
function _check_api_creds () {
    local API_CRED_FILE="$HOME/.enhance"

    if [[ -n $API_TOKEN ]]; then
        _running "Found \$API_TOKEN via CLI using for authentication/."
    elif [[ -f "$API_CRED_FILE" ]]; then
        _debug "Found $API_CRED_FILE file."
        # shellcheck source=$API_CRED_FILE
        source "$API_CRED_FILE"
    
        if [[ ${API_TOKEN} ]]; then            
            _debug "Found \$API_TOKEN in $API_CRED_FILE using for authentication."            
        else
            _error "API_TOKEN not found in $API_CRED_FILE."
            exit 1
        fi
    fi
}

# =====================================
# -- _check_required_apps $REQUIRED_APPS
# -- Check for required apps
# =====================================
function _check_required_apps () {
    for app in "${REQUIRED_APPS[@]}"; do
        if ! command -v $app &> /dev/null; then
            _error "$app could not be found, please install it."
            exit 1
        fi
    done

    _debug "All required apps found."
}

# ===============================================
# -- _check_bash - check version of bash
# ===============================================
function _check_bash () {
	# - Check bash version and _die if not at least 4.0
	if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
		_die "Sorry, you need at least bash 4.0 to run this script." 1
	fi
}

# ===============================================
# -- _check_debug
# ===============================================
function _check_debug () {
	if [[ $DEBUG == "1" ]]; then
		echo -e "${CYAN}** DEBUG: Debugging is on${ECOL}"
	elif [[ $DEBUG_CURL_OUTPUT == "2" ]]; then
		echo -e "${CYAN}** DEBUG: Debugging is on + CURL OUTPUT${ECOL}"	
	fi
}