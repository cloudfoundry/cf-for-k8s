#!/bin/bash

function write_uptimer_deploy_config {
password="$1"
manifest="$2"
cat <<EOF > /tmp/uptimer-config.json
 {
    "while": [
        {
            "command": "kapp",
            "command_args": ["deploy", "-a", "cf", "-f", "${manifest}", "-y"]
        }
    ],
    "cf": {
        "api": "api.${DNS_DOMAIN}",
        "app_domain": "apps.${DNS_DOMAIN}",
        "admin_user": "admin",
        "admin_password": "${password}",
        "tcp_domain": "tcp.${DNS_DOMAIN}",
        "use_single_app_instance": false,
        "available_port": 1025
    },
    "optional_tests": {
      "run_app_syslog_availability": false
    },
    "allowed_failures": {
        "app_pushability": 100,
        "http_availability": 0,
        "recent_logs": 100,
        "streaming_logs": 100,
        "app_syslog_availability": 100
    }
}
EOF
}
