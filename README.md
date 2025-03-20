# enhance-bash-cli
A simple bash script to interface with the enhance API at https://apidocs.enhance.com/

Enhance documentation https://enhance.com/docs/

# Accessing the Enhance API
```
curl -s -X GET https://[Enhance Controller URL]/api/servers -H "Accept: application/json" -H "Authorization: Bearer [Token]" | jq
```