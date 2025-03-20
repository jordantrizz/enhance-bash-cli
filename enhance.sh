# #!/usr/bin/env bash
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
VERSION=$(cat "${SCRIPT_DIR}/VERSION")
DEBUG="0"
DRYRUN="0"
QUIET="0"

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
    echo "Usage: $SCRIPT_NAME [OPTIONS] -c <command>"
    echo
    echo "Enhance API CLI"
    echo
    echo "Commands: -c, --command"
    echo
    _running "Commands:"
    echo "  create <name>                                - Create a new tenant"
    echo "  create-bulk <file>                           - Create tenants in bulk"
    echo "  create-access <tenant-id> <account_id>       - Create a new tenant with access"
    echo "  list                                         - List all tenants"
    echo "  get <id>                                     - Get tenant details"
    echo "  delete <id>,<id>                             - Delete tenant, or multiple separated by ,"
    echo
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -q, --quiet            Suppress output"
    echo "  -d, --debug            Show debug output"
    echo "  -dj, --debug-json      Write debug output as JSON to debug.log"
    echo "  --cf                   List Core function"
    echo "  -j, --json             Output as JSON"
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
[[ $CMD != "test-token" ]] && _pre_flight_checkv2 "CF_TENANT_"

# -- Command: create
# ==================================
if [[ $CMD == "create-org" ]]; then
    _running "Creating tenant"
    _create_tenant "${1}"
fi