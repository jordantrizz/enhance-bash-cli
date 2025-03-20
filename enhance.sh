#!/usr/bin/env bash
# =================================================================================================
# -- enhance-cli - Enhance CLI Library
# --
# -- A simple bash script to interface with the enhance API at https://apidocs.enhance.com/
# =================================================================================================

# ==================================
# -- Variables
# ==================================
SCRIPT_NAME="enhance-cli"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VERSION="$(cat "${SCRIPT_DIR}/VERSION")"
DEBUG="0"
DRYRUN="0"
QUIET="0"

# ==================================
# -- Command Help Variables
# ==================================
typeset -gA ebc_commands_type
ebc_commands_type[general]="General Actions"
ebc_commands_type[org]="Organization Actions"
ebc_commands_type[plan]="Plan Actions"
ebc_commands_type[website]="Website Actions"
ebc_commands_type[subscriptions]="Subscription Actions"
ebc_commands_type[servers]="Server Actions"

typeset -gA ebc_commands_general
ebc_commands_general[status]="Get status of the Enhance API"
ebc_commands_general[settings]="Get settings of the Enhance API"

typeset -gA ebc_commands_org
ebc_commands_org[org-info]="Get organization information"
ebc_commands_org[org-customers]="Get organization customers information"

typeset -gA ebc_commands_plan
ebc_commands_plan[plan-info]="Get plan information"

typeset -gA ebc_commands_website
ebc_commands_website[websites]="Get website information"
ebc_commands_website[website-get]="Get website information"
ebc_commands_website[website-create]="Create a website"

typeset -gA ebc_commands_subscriptions
ebc_commands_subscriptions[subscriptions]="Get subscription information"

typeset -gA ebc_commands_servers
ebc_commands_servers[servers]="Get server information"

typeset -gA ebc_commands_apps
ebc_commands_apps[apps]="Get installable apps"
ebc_commands_apps[website-apps-create]="Create a website app"



# ==================================
# -- Include cf-inc.sh and cf-api-inc.sh
# ==================================
source "$SCRIPT_DIR/enhance-inc.sh"
source "$SCRIPT_DIR/enhance-inc-api.sh"

# ==============================================================================================
# -- Functions
# ==============================================================================================
# -- Help
function _help () {
    echo "Usage: $SCRIPT_NAME [OPTIONS] -c <command> [ARGS]"
    echo
    echo "Enhance API CLI"
    echo
    _help_print_commands
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -q, --quiet            Suppress output"
    echo "  -d, --debug            Show debug output"
    echo "  -dj, --debug-json      Write debug output as JSON to debug.log"
    echo "  --cf                   List Core function"
    echo "  -j, --json             Output as JSON"
}


# =====================================
# -- _help_print_commands
# -- Print commands
# =====================================
function _help_print_commands () {
    # -- Go through each type
    for TYPE in "${!ebc_commands_type[@]}"; do
        _running "${ebc_commands_type[$TYPE]}"
        # -- Go through each command
        declare -n arr="ebc_commands_$TYPE"
        for COMMAND in "${!arr[@]}"; do
            # -- Don't pass the function to the help
            IFS='|' read -r -a CMD_DESC <<< "${arr[$COMMAND]}"
            printf "  %-20s - %s\n" "$COMMAND" "${CMD_DESC[0]}"        
        done
        echo
    done
}

# ==============================================================================================
# -- Main
# ==============================================================================================
# -- Commands
_debug "ALL_ARGS: ${*}@"

# -- Parse options
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
		-c|--command)
		CMD="$2"
		shift # past argument
		shift # past variable
		;;
        -h|--help)
        _cf_partner_help
        exit 0
        ;;
        -q|--quiet)
        QUIET="1"
        shift # past argument
        ;;
        -d|--debug)
        DEBUG="1"
        shift # past argument
        ;;
        -dj|--debug-json)
        DEBUG_JSON="1"
        shift # past argument
        ;;        
        --cf)
        _list_core_functions
        exit 0
        ;;
        -j|--json)
        JSON="1"
        shift # past argument
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
    done
set -- "${POSITIONAL[@]}" # restore positional parameters

# -- Commands
_debug "PARSE_ARGS: ${*}@"

# -- pre-flight check
_debug "Pre-flight_check"
_pre_flight_check


[[ -z $CMD ]] && { _help; _error "No command specified"; exit 1; }


# ==================================
if [[ $CMD == "status" ]]; then
    _enhance_status
elif [[ $CMD == "settings" ]]; then
    _enhance_settings
elif [[ $CMD == "org-info" ]]; then
    _enhance_org_info $@
elif [[ $CMD == "org-customers" ]]; then
    _enhance_org_customers $@
elif [[ $CMD == "plan-info" ]]; then
    _enhance_plan_info $@
elif [[ $CMD == "websites" ]]; then
    _enhance_org_websites $@
elif [[ $CMD == "website-get" ]]; then
    _enhance_org_website_get $@
elif [[ $CMD == "website-create" ]]; then
    _enhance_org_website_create $@
elif [[ $CMD == "subscriptions" ]]; then
    _enhance_org_subscriptions $@
elif [[ $CMD == "servers" ]]; then
    _enhance_org_servers $@
elif [[ $CMD == "apps" ]]; then
    _enhance_apps $@
elif [[ $CMD == "website-apps-create" ]]; then
    _enhance_website_apps_create $@
elif [[ $CMD == "help" ]]; then
    _help
    exit 0
else 
    _help
    exit 1
fi