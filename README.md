Zabbix API Manager (Bash CLI)

A lightweight Bash script for interacting with the Zabbix API.
Easily manage hosts, items, triggers, and events directly from your terminal.
Features

    ✅ Create, update, delete, find Zabbix hosts

    ✅ List hosts, host groups, items, triggers, and events

    ✅ Send custom JSON API requests

    ✅ Simple interactive CLI menu

    ✅ Supports authentication via API token


Configuration

Before running the script, edit the following variables inside the script file (zabbix_api_manager.sh) based on your Zabbix server settings:

    HOST_DOMAIN="http://localhost/api_jsonrpc.php"   # Your Zabbix API URL
    DEFAULT_IP="127.0.0.1"                           # Default IP address for hosts
    USERNAME="Admin"                                 # Zabbix username
    PASSWORD="zabbix"                                # Zabbix password

    ⚠️ Make sure to set these values correctly, otherwise the API calls will fail.


Usage

Clone the repository:

git clone https://github.com/vahid6889/zabbix_api.git AND => cd zabbix_api

Make the script executable:

chmod +x zabbix_api_manager.sh

Run the script:

./zabbix_api_manager.sh

Requirements

    curl

    jq

    Access to Zabbix API

    Valid Zabbix credentials

Disclaimer

This tool is designed for learning, automation, and administration tasks.
Use at your own risk in production environments
