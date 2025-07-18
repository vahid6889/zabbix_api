#!/bin/bash

HOST_DOMAIN="http://localhost/api_jsonrpc.php"
DEFAULT_IP="127.0.0.1"
USERNAME="Admin"
PASSWORD="zabbix"


# === Function to retrieve the Zabbix API authentication token ===
get_token() {
  curl -s -X POST -H 'Content-Type: application/json' -d '{
    "jsonrpc":"2.0",
    "method":"user.login",
    "params":{
      "username":"'$USERNAME'",
      "password":"'$PASSWORD'"
    },
    "id":1
  }' $HOST_DOMAIN | jq -r .result
}

# === Store the retrieved token ===
TOKEN=$(get_token)


# === Generic function to make an API call and pretty-print the result using jq ===
api_call() {
 curl -s -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" -d"$1" $HOST_DOMAIN | jq -r $2
}

# === Retrieve host ID by name ===
get_host_with_id() {
  JSON='{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
      "filter": {
        "host": ["'$1'"]
      }
    },
    "id": 1
  }'
  api_call "$JSON" "$2"
}

# === Retrieve all hostTemplates===
get_host_templates() {
  local HOSTID="$1"
  JSON='{
    "jsonrpc": "2.0",
    "method": "template.get",
    "params": {
      "output": ["templateid", "host"],
        "sortfield": "host"
    },
    "id": 1
  }'
  RESULT=$(api_call "$JSON")
  

  LINE=""
  while read -r line; do
    HOST=$(echo "$line" | jq -r '.host')
    TEMPLATE_ID=$(echo "$line" | jq -r '.templateid')
    LINE+="$HOST($TEMPLATE_ID) - "
  done <<< "$(echo "$RESULT" | jq -c '.result[]')"

  echo "${LINE% - }"
}

# === Retrieve templates related of host by host ID ===
get_host_templates_related() {
  local HOSTID="$1"
  JSON='{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
      "hostids": "'$HOSTID'",
      "output": ["host"],
      "selectParentTemplates": ["templateid", "host"]
    },
    "id": 1
  }'

  api_call "$JSON"
}

# === Retrieve all hostGroups ===
get_host_groups() {
  JSON='{
    "jsonrpc": "2.0",
    "method": "hostgroup.get",
    "params": {
        "output": ["groupid", "name"],
        "sortfield": "name"
    },
    "id": 1
  }'
  RESULT=$(api_call "$JSON")
  

  LINE=""
  while read -r line; do
    NAME=$(echo "$line" | jq -r '.name')
    GROUP_ID=$(echo "$line" | jq -r '.groupid')
    LINE+="$NAME($GROUP_ID) - "
  done <<< "$(echo "$RESULT" | jq -c '.result[]')"

  echo "${LINE% - }"

}

# === Retrieve groups related of host by host ID ===
get_host_groups_related() {
  local HOSTID="$1"
  JSON='{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
      "hostids": "'$HOSTID'",
      "output": ["host"],
      "selectHostGroups": ["groupid", "name"]
    },
    "id": 1
  }'

  api_call "$JSON"
}


# === Function to find a host from Zabbix by name ===
function find_host() {
  read -p "Host name OR 'b' to go back: " HOSTNAME
    if [[ "$HOSTNAME" == "b" ]]; then
    	return
    fi
  read -p "IP address OR press Enter to use default OR 'b' back to menu: " NEXT
    if [[ "$NEXT" == "b" ]]; then
     	return
    elif [[ -n "$NEXT" ]]; then
        DEFAULT_IP=$NEXT
    fi
    
  get_host_with_id "$HOSTNAME"
}

# === Function to create a new host in Zabbix ===
function create_host() {
  read -p "Host name OR 'b' to go back: " HOSTNAME
    if [[ "$HOSTNAME" == "b" ]]; then
    	return
    fi
  read -p "IP address OR press Enter to use default OR 'b' back to menu: " NEXT
    if [[ "$NEXT" == "b" ]]; then
     	return
    elif [[ -n "$NEXT" ]]; then
        DEFAULT_IP=$NEXT
    fi
    
  JSON='{
    "jsonrpc": "2.0",
    "method": "host.create",
    "params": {
      "host": "'$HOSTNAME'",
      "interfaces": [{
        "type": 1,
        "main": 1,
        "useip": 1,
        "ip": "'$DEFAULT_IP'",
        "dns": "",
        "port": "10050"
      }],
      "groups": [{"groupid": "2"},{"groupid": "4"}],
      "templates": [{"templateid": "10343"},{"templateid": "10047"}]
    },
    "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}

# === Function to update an execist host in Zabbix by host name ===
function update_host() {
  read -p "Host name OR 'b' to go back: " HOSTNAME
    if [[ "$HOSTNAME" == "b" ]]; then
    	return
    fi
  read -p "IP address OR press Enter to use default OR 'b' back to menu: " NEXT
    if [[ "$NEXT" == "b" ]]; then
     	return
    elif [[ -n "$NEXT" ]]; then
        DEFAULT_IP=$NEXT
    fi

  HOSTID=$(get_host_with_id "$HOSTNAME" ".result[].hostid")
  HOST_GROUPS_RELATED=$(get_host_groups_related "$HOSTID")
  echo "$HOST_GROUPS_RELATED"
  read -p "Host name OR press Enter to use default OR 'b' to go back: " HOSTNAME
    if [[ "$HOSTNAME" == "b" ]]; then
    	return
    fi

  printf "=====================\n\n"
  get_host_groups "$HOSTID"
  printf "\n\n=====================\n\n"
  read -p "Choosing and enter digits home_group [Example => 19 7 4] OR press Enter OR 'b': " HOSTGROUPSID
    if [[ "$HOSTGROUPSID" == "b" ]]; then
    	return
    fi
    

  HOST_GROUP_JSON=""
  for id in $HOSTGROUPSID; do
    HOST_GROUP_JSON+='{"groupid": "'$id'"},'
  done

  HOST_GROUP_JSON="${HOST_GROUP_JSON%,}"

  JSON='{
  "jsonrpc": "2.0",
  "method": "host.update",
  "params": {
    "hostid": "'$HOSTID'",
    "interfaces": [{
      "type": 1,
      "main": 1,
      "useip": 1,
      "ip": "'$DEFAULT_IP'",
      "dns": "",
      "port": "10050"
    }],
    "host": "'$HOSTNAME'",
    "groups": ['$HOST_GROUP_JSON'],
    "templates": [{"templateid": "10343"},{"templateid": "10047"}]
  },
  "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}


# === Function to delete a host from Zabbix by host name ===
function delete_host() {
  read -p "Host name OR 'b' to go back: " HOSTNAME
    if [[ "$HOSTNAME" == "b" ]]; then
    	return
    fi
  read -p "IP address OR press Enter to use default OR 'b' back to menu: " NEXT
    if [[ "$NEXT" == "b" ]]; then
     	return
    elif [[ -n "$NEXT" ]]; then
        DEFAULT_IP=$NEXT
    fi
    
  HOSTID=$(get_host_with_id "$HOSTNAME" ".result[].hostid")
    
  JSON='{
    "jsonrpc": "2.0",
    "method": "host.delete",
    "params": ["'$HOSTID'"],
    "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}

# === Function to retrieve the list of hosts from Zabbix ===
get_host_list() {
  JSON='{
    "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
      "output": ["hostid", "host"]
    },
    "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}

# === Function to retrieve all items of a specific host using its hostid ===
function get_host_items() {
  read -p "Host ID OR 'b' to go back: " HOSTID
    if [[ "$HOSTNAME" == "b" ]]; then
    	return
    fi
  read -p "IP address OR press Enter to use default OR 'b' back to menu: " NEXT
    if [[ "$NEXT" == "b" ]]; then
     	return
    elif [[ -n "$NEXT" ]]; then
        DEFAULT_IP=$NEXT
    fi
    
  JSON='{
    "jsonrpc": "2.0",
    "method": "item.get",
    "params": {
      "output": "extend",
      "hostids": "'$HOSTID'"
    },
    "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}

# === Function to get a list of currently active triggers ===
get_active_triggers() {
  JSON='{
    "jsonrpc": "2.0",
    "method": "trigger.get",
    "params": {
      "output": "extend",
      "filter": {
        "value": 1
      },
      "expandDescription": 1
    },
    "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}

# === Function to retrieve the most recent 10 events ===
get_events() {
  JSON='{
    "jsonrpc": "2.0",
    "method": "event.get",
    "params": {
      "output": "extend",
      "sortfield": "clock",
      "sortorder": "DESC",
      "limit": 10
    },
    "id": 1
  }'
  RESULT_API_CALL=$(api_call "$JSON")
  echo "$RESULT_API_CALL"
}

# === Send custom action with JSON ===
function custom_action() {
    read -p "Enter host domain OR press Enter to use default OR 'b' back to menu: " CUSTOM_DOMAIN
    if [[ "$CUSTOM_DOMAIN" == "b" ]]; then
    	return
    elif [[ -n "$CUSTOM_DOMAIN" ]]; then
    	HOST_DOMAIN=$CUSTOM_DOMAIN
    fi
    
    read -p "IP address OR press Enter to use default OR 'b' back to menu: " NEXT
      if [[ "$NEXT" == "b" ]]; then
     	  return
      elif [[ -n "$NEXT" ]]; then
          DEFAULT_IP=$NEXT
      fi
      
    echo "Paste your JSON (end with EOF on a new line) without single or double quotation:"
    CUSTOM_JSON=""
    while IFS= read -r line; do
      [[ "$line" == "EOF" ]] && break
      CUSTOM_JSON+="$line"$'\n'
    done
      

    if [[ -z "$CUSTOM_JSON" ]]; then
        echo "Custom JSON cannot be empty!"
        return
    fi

    
    read -p "Press Enter to continue OR type 'b' back to menu: " NEXT
    if [[ "$NEXT" == "b" ]]; then
     	return
    fi

     RESULT=$(curl -s -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" -d"$CUSTOM_JSON" $HOST_DOMAIN | jq -r)
     echo "$RESULT"


}

function menu() {
    while true; do
        echo " "
        echo "======== Zabbix RESTFUL API ========"
        echo "1) Create Host"
        echo "2) Update Host"
        echo "3) Delete Host"
        echo "4) Find Host"
        echo "5) Get Host List"
        echo "6) Get Host Items"
        echo "7) Get Active Triggers"
        echo "8) Get Events"
        echo "9) Custom Action"
        echo "10) Exit"
        echo "======================================="
        read -p "Select an option: " option

        case $option in
            1) create_host ;;
            2) update_host ;;
            3) delete_host ;;
            4) find_host ;;
            5) get_host_list ;;
            6) get_host_items ;;
            7) get_active_triggers ;;
            8) get_events ;;
            9) custom_action ;;
            10) exit 0 ;;
            *) echo "Invalid option." ;;
        esac
    done
}

# Run the menu
menu

