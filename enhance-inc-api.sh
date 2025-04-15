# =============================================================================
# -- enhance-bash-cli - Enhance API Library
# =============================================================================

# =============================================================================
# -- Variables
# =============================================================================
# API_URL="" # Set in .enhance file"
# API_TOKEN="" # Set in .enhance file"

# =============================================================================
# -- API Functions
# =============================================================================

# =====================================
# -- _enhance_api <$REQUEST> <$API_PATH> [--paginate] [--all-pages] $EXTRA
# -- Run cf_api request and return output via $API_OUTPUT
# -- Run cf_api request and return exit code via $CURL_EXIT_CODE
# =====================================
ebc_functions[_enhance_api]="Run enhance api request"
function _enhance_api() {
    # -- Run cf_api with tokens
    _debug "function:${FUNCNAME[0]} - ${*}"
    _debug "Running _enhance_api() with ${*}"

    # -- Pagination
    local PAGINATE=0
    local ALL_PAGES=0
    local PAGE=1
    local PER_PAGE=50
    local HAS_MORE=false
    local COMBINED_RESULTS=""
    local API_PATH=""
    local REQUEST=""
    local CURL_HEADERS=()
    local args=()

    # Parse arguments for pagination options
    for arg in "$@"; do
        case "$arg" in
            --paginate)
                PAGINATE=1
                ;;
            --all-pages)
                PAGINATE=1
                ALL_PAGES=1
                ;;
            --page=*)
                PAGE="${arg#*=}"
                PAGINATE=1
                ;;
            --per-page=*)
                PER_PAGE="${arg#*=}"
                PAGINATE=1
                ;;
            *)
                args+=("$arg")
                ;;
        esac
    done
    _debug "ARG: ${args[*]}"

    # Set pagination parameters
    REQUEST="${args[0]}"
    API_PATH="${args[1]}"
    EXTRA=("${args[@]:2}")

    # Add pagination parameters if needed
    if [[ $PAGINATE -eq 1 ]]; then
        # Check if API_PATH already has query parameters
        if [[ "$API_PATH" == *\?* ]]; then            
            API_PATH="${API_PATH}&page=${PAGE}&per_page=${PER_PAGE}"
        else
            API_PATH="${API_PATH}?page=${PAGE}&per_page=${PER_PAGE}"
        fi
    fi
    _debug "API_PATH: $API_PATH"

    if [[ -n $API_TOKEN ]]; then
        CURL_HEADERS=("-H" "Authorization: Bearer ${API_TOKEN}")
        _debug "Using \$API_TOKEN as 'Authorization: Bearer'. \$CURL_HEADERS: ${CURL_HEADERS[*]}"        
    elif [[ -n $API_ACCOUNT ]]; then
        CURL_HEADERS=("-H" "X-Auth-Key: ${API_APIKEY}" -H "X-Auth-Email: ${API_ACCOUNT}")
        _debug "Using \$API_APIKEY as X-Auth-Key. \$CURL_HEADERS: ${CURL_HEADERS[*]}"        
    else
        _error "No API Token or API Key found...major error...exiting"
        exit 1
    fi

    CURL_OUTPUT=$(mktemp)

    # -- Start API Call
    _debug "Running curl -s --request $REQUEST --url "${API_URL}${API_PATH}" "${CURL_HEADERS[*]}" --output $CURL_OUTPUT ${EXTRA[*]}"
    [[ $DEBUG == "1" ]] && set -x
    CURL_EXIT_CODE=$(curl -s -w "%{http_code}" --request "$REQUEST" \
        --url "${API_URL}${API_PATH}" \
        "${CURL_HEADERS[@]}" \
        --output "$CURL_OUTPUT" "${EXTRA[@]}")
    [[ $DEBUG == "1" ]] && set +x
    API_OUTPUT=$(<"$CURL_OUTPUT")
    _debug_json_file "$API_OUTPUT"
    rm "$CURL_OUTPUT"

	if [[ $CURL_EXIT_CODE == "200" ]]; then
	    MESG="Success from API: $CURL_EXIT_CODE"
        _debug "$MESG"
        _debug "$API_OUTPUT"
    elif [[ $CURL_EXIT_CODE == "201" ]]; then
        MESG="Created from API: $CURL_EXIT_CODE"
        _debug "$MESG"
        _debug "$API_OUTPUT"
	else
        MESG="Error from API: $CURL_EXIT_CODE"
        _error "$MESG"
        _parse_api_error "$API_OUTPUT"
        exit 1
    fi
}

# =====================================
# -- _parse_api_output $API_OUTPUT
# =====================================
ebc_functions[_parse_api_output]="Parse API Output"
_parse_api_output () {
    API_OUTPUT=$@    
    _debug "function:${FUNCNAME[0]} - ${*}"

    # -- Check if API_OUTPUT is JSON
    if [[ $API_OUTPUT == "{"* ]]; then
        _debug "API_OUTPUT is JSON"
        echo "$API_OUTPUT" | jq
    else
        _debug "API_OUTPUT is not JSON"
        echo "$API_OUTPUT"
    fi
}

# =====================================
# -- _parse_api_error $API_OUTPUT
# =====================================
ebc_functions[_parse_api_error]="Parse Cloudflare API Error"
_parse_api_error () {
    API_OUTPUT=$@    
    _debug "Running parse_cf_error"

    # -- Check if API_OUTPUT is JSON
    if [[ $API_OUTPUT == "{"* ]]; then
        _debug "API_OUTPUT is JSON"
        echo "$API_OUTPUT" | jq
    else
        _debug "API_OUTPUT is not JSON"
        echo "$API_OUTPUT"
        return 1
    fi

}

# =============================================================================
# -- Functions
# =============================================================================

# =====================================
# -- _enhance_status
# -- Get status of the Enhance API
# =====================================
ebc_functions[_enhance_api]="Get status of the Enhance API"
function _enhance_status() {
    _debug "function:${FUNCNAME[0]} - ${*}"
    _enhance_api "GET" "/status"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        echo "Status: $API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
    
    _enhance_api "GET" "/version"
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        echo "Verison: $API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi

}

# =====================================
# -- _enhance_settings
# -- Get settings of the Enhance API
# =====================================
ebc_functions[_enhance_settings]="Get settings of the Enhance API"
function _enhance_settings() {
    _debug "function:${FUNCNAME[0]} - ${*}"
    _enhance_api "GET" "/settings"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        echo "$API_OUTPUT" | jq
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =============================================================================
# -- Organization Commands
# =============================================================================

# =====================================
# -- _enhance_org_info
# -- Get organization information
# =====================================
ebc_functions[_enhance_org_info]="Get organization information"
function _enhance_org_info() {
    _debug "function:${FUNCNAME[0]} - ${*}"
    local ORG_ID="$1"
    [[ -z $ORG_ID ]] && { _error "Organization ID required"; return 1; }
    
    _running "Getting organization information on $ORG_ID"
    _enhance_api "GET" "/orgs/$ORG_ID"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =============================================================================
# -- _enhance_org_customers $ORG_ID
# -- Get customer information
# =============================================================================
ebc_functions[_enhance_org_customers]="Get customer information"
function _enhance_org_customers () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    local ORG_ID="$1"
    [[ -z $ORG_ID ]] && { _error "Customer ID required"; return 1; }
    
    _running "Getting customer information on $ORG_ID"
    _enhance_api "GET" "/orgs/$ORG_ID/customers"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =============================================================================
# -- Plan Commands
# =============================================================================
# =====================================
# -- _enhance_plan_info
# -- Get plan information
# =====================================
function _enhance_plan_info () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    local PLAN_ID="$1"
    [[ -z $PLAN_ID ]] && { _error "Plan ID required"; return 1; }
    
    _running "Getting plan information on $PLAN_ID"
    _enhance_api "GET" "/plans/$PLAN_ID"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =============================================================================
# -- Website Commands
# =============================================================================
# =====================================
# -- _enhance_org_websites
# -- Get websites for an organization
# =====================================
function _enhance_org_websites () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    local ORG_ID="$1"
    [[ -z $ORG_ID ]] && { _error "Organization ID required"; return 1; }
    
    _running "Getting websites for organization $ORG_ID"
    _enhance_api "GET" "/orgs/$ORG_ID/websites"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =====================================
# -- _enhance_org_website_get
# -- Get website information
# =====================================
function _enhance_org_website_get () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    local ORG_ID="$1"
    local WEBSITE_ID="$2"
    [[ -z $ORG_ID ]] && { _error "Organization ID required"; return 1; }
    [[ -z $WEBSITE_ID ]] && { _error "Website ID required"; return 1; }
    
    _running "Getting website information for organization $ORG_ID and website $WEBSITE_ID"
    _enhance_api "GET" "/orgs/$ORG_ID/websites/$WEBSITE_ID"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =====================================
# -- _enhance_org_website_create
# -- Create a website
# =====================================
function _enhance_org_website_create () {
    #   "domain": "string",
    # "subscriptionId": 0,
    # "appServerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    # "backupServerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    # "dbServerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    # "emailServerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    # "serverGroupId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    # "phpVersion": "php56"
    _debug "function:${FUNCNAME[0]} - ${*}"    
    
    _enhance_org_website_create_usage () {
        _quiet "Usage: website-create 
    --orgid=<ORG_ID> 
    --name=<WEBSITE_NAME>
    --domain=<DOMAIN>
    --subscription=<SUBSCRIPTION_ID> 
    --app-server=<APP_SERVER_ID> 
    --db-server=<DB_SERVER_ID>
    --email-server=<EMAIL_SERVER_ID> 
    --server-group=<SERVER_GROUP_ID> 
    --php-version=<PHP_VERSION>"
    }

    if [[ -z $@ ]]; then
        _enhance_org_website_create_usage
        return 1
    fi

    local ORG_ID=""    
    local DOMAIN=""
    local SUBSCRIPTION_ID=""
    local APP_SERVER_ID=""
    local DB_SERVER_ID="$APP_SERVER_ID"
    local EMAIL_SERVER_ID="$APP_SERVER_ID"
    local SERVER_GROUP_ID="$APP_SERVER_ID"
    local PHP_VERSION="php80"

    # -- Parse Arguments
    for arg in "$@"; do
        case "$arg" in
            --orgid=*)
                ORG_ID="${arg#*=}"
                ;;
            --domain=*)
                DOMAIN="${arg#*=}"
                ;;
            --subscription=*)
                SUBSCRIPTION_ID="${arg#*=}"
                ;;
            --app-server=*)
                APP_SERVER_ID="${arg#*=}"
                ;;
            --db-server=*)
                DB_SERVER_ID="${arg#*=}"
                ;;
            --email-server=*)
                EMAIL_SERVER_ID="${arg#*=}"
                ;;
            --server-group=*)
                SERVER_GROUP_ID="${arg#*=}"
                ;;
            --php-version=*)
                PHP_VERSION="${arg#*=}"
                ;;
        esac
    done

    [[ -z $ORG_ID ]] && { _error "Organization ID required"; _enhance_org_website_create_usage; return 1; } 
    [[ -z $DOMAIN ]] && { _error "Domain required"; _enhance_org_website_create_usage; return 1; } || JSON_KV=("domain=$DOMAIN")
    [[ -z $SUBSCRIPTION_ID ]] && { _error "Subscription ID required"; _enhance_org_website_create_usage; return 1; } || JSON_KV+=("subscriptionId=$SUBSCRIPTION_ID")
    [[ -z $APP_SERVER_ID ]] && { _error "App Server ID required"; _enhance_org_website_create_usage; return 1; } || JSON_KV+=("appServerId=$APP_SERVER_ID")
    [[ -z $DB_SERVER_ID ]] || JSON_KV+=("dbServerId=$DB_SERVER_ID")
    [[ -z $EMAIL_SERVER_ID ]] || JSON_KV+=("emailServerId=$EMAIL_SERVER_ID")
    [[ -z $SERVER_GROUP_ID ]] || JSON_KV+=("serverGroupId=$SERVER_GROUP_ID")
    [[ -z $PHP_VERSION ]]  || JSON_KV+=("phpVersion=$PHP_VERSION")

    
    _running "Creating website for organization $ORG_ID with name $DOMAIN"
    # -- Create JSON
    JSON=$(_json_from_kv "${JSON_KV[@]}")
    _debug "JSON: $JSON"
    
    
    _enhance_api "POST" "/orgs/$ORG_ID/websites" -H "Content-Type: application/json" -d "$JSON"
    
    if [[ $CURL_EXIT_CODE == "201" ]]; then
        _success "$(_parse_api_output $API_OUTPUT)"
        _quiet "$(echo $API_OUTPUT | jq -r '.id')"
        return 0
    else
        _error "Error: $CURL_EXIT_CODE"
        _error "$(_parse_api_error $API_OUTPUT)"
        return 1
    fi
}

# =============================================================================
# -- Subscription Commands
# =============================================================================
# =====================================
# -- _enhance_org_subscriptions
# -- Get subscriptions for an organization
# =====================================
function _enhance_org_subscriptions () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    local ORG_ID="$1"
    [[ -z $ORG_ID ]] && { _error "Organization ID required"; return 1; }
    
    _running "Getting subscriptions for organization $ORG_ID"
    _enhance_api "GET" "/orgs/$ORG_ID/subscriptions"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =============================================================================
# -- Server Commands
# =============================================================================
# =====================================
# -- _enhance_org_servers
# -- Get servers for an organization
# =====================================
function _enhance_org_servers () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    
    _running "Getting servers"
    _enhance_api "GET" "/servers"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# =============================================================================
# -- Apps Commands
# =============================================================================
# =====================================
# -- _enhance_apps
# -- Get apps - /utils/installable-apps
# =====================================
function _enhance_apps () {
    _debug "function:${FUNCNAME[0]} - ${*}"
    
    _running "Getting apps"
    _enhance_api "GET" "/utils/installable-apps"
    
    if [[ $CURL_EXIT_CODE == "200" ]]; then
        _parse_api_output "$API_OUTPUT"
    else
        _error "Error: $CURL_EXIT_CODE"
        _parse_api_error "$API_OUTPUT"
    fi
}

# ====================================-
# -- _enhance_app_create $ORG_ID $WEBSITE_ID $APP $APP_VERSION
# -- Create an app /orgs/{orgId}/websites/{websiteId}/apps
# =====================================
function _enhance_app_create () {    
    # "app": "wordpress",
    # "version": "string",
    # "path": "string",
    # "adminUsername": "string",
    # "adminPassword": "string",
    # "adminEmail": "string",
    # "domainId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
    
    _debug "function:${FUNCNAME[0]} - ${*}"
    _enhance_app_create_usage () {
        _usage "Usage: website-apps-create
    --orgid=<ORG_ID>
    --website=<WEBSITE_ID>
    --app=<APP>
    --app-version=<APP_VERSION>
    --path=<PATH>
    --admin-username=<ADMIN_USERNAME>
    --admin-password=<ADMIN_PASSWORD>
    --admin-email=<ADMIN_EMAIL>
    --domain-id=<DOMAIN_ID>"
    }
    if [[ -z $@ ]]; then
        _enhance_app_create_usage
        return 1
    fi

    local ORG_ID=""
    local WEBSITE_ID=""
    local APP=""
    local APP_VERSION=""
    local APP_PATH=""
    local ADMIN_USERNAME=""
    local ADMIN_PASSWORD="$(_generate_password)"
    local ADMIN_EMAIL=""
    local DOMAIN_ID=""
    local JSON_KV=()

    # -- Parse Arguments
    for arg in "$@"; do
        case "$arg" in
            --orgid=*)
                ORG_ID="${arg#*=}"
                ;;
            --website=*)
                WEBSITE_ID="${arg#*=}"
                ;;
            --app=*)
                APP="${arg#*=}"
                ;;
            --app-version=*)
                APP_VERSION="${arg#*=}"
                ;;
            --path=*)
                APP_PATH="${arg#*=}"
                ;;
            --admin-username=*)
                ADMIN_USERNAME="${arg#*=}"
                ;;
            --admin-password=*)
                ADMIN_PASSWORD="${arg#*=}"
                ;;
            --admin-email=*)
                ADMIN_EMAIL="${arg#*=}"
                ;;
            --domain-id=*)
                DOMAIN_ID="${arg#*=}"
                ;;
        esac
    done

    [[ -z $ORG_ID ]] && { _error "Organization ID required"; _enhance_app_create_usage; return 1; }
    [[ -z $WEBSITE_ID ]] && { _error "Website ID required"; _enhance_app_create_usage; return 1; }
    [[ -z $ADMIN_USERNAME ]] && { _error "Admin Username required"; _enhance_app_create_usage; return 1; } || JSON_KV+=("adminUsername=$ADMIN_USERNAME")
    [[ -z $ADMIN_EMAIL ]] && { _error "Admin Email required"; _enhance_app_create_usage; return 1; } || JSON_KV+=("adminEmail=$ADMIN_EMAIL")
    
    [[ -z $APP ]] && { _error "App required"; _enhance_app_create_usage; return 1; } || JSON_KV+=("app=$APP")
    [[ -z $APP_VERSION ]] || JSON_KV+=("version=$APP_VERSION")
    
    [[ -z $APP_PATH ]] || JSON_KV+=("path=$APP_PATH")
    [[ -z $ADMIN_PASSWORD ]] || JSON_KV+=("adminPassword=$ADMIN_PASSWORD")    
    [[ -z $DOMAIN_ID ]] || JSON_KV+=("domainId=$DOMAIN_ID")
    
    _running "Creating application $APP version $APP_VERSION for organization $ORG_ID with website $WEBSITE_ID"
    # -- Create JSON
    JSON=$(_json_from_kv "${JSON_KV[@]}")
    _debug "JSON: $JSON"

    _running "Creating app $APP for organization $ORG_ID and website $WEBSITE_ID"
    _enhance_api "POST" "/orgs/$ORG_ID/websites/$WEBSITE_ID/apps" -H "Content-Type: application/json" -d "$JSON"
    
    if [[ $CURL_EXIT_CODE == "201" ]]; then
        _success "$(_parse_api_output $API_OUTPUT)"
        _quiet "$(echo $API_OUTPUT | jq -r '.id')"
    else
        _error "Error: $CURL_EXIT_CODE"
        _error "$(_parse_api_error $API_OUTPUT)"
    fi
}


