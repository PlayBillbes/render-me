#!/usr/bin/env bash
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'
red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

echo -e "${RED}CloudPress Version V1.0"

echo -e "${GREEN}'||    ||'  ..|''||   '||''|.    .|'''.|  '||''|.    ..|''||   |''||''|  .|'''.|  
 |||  |||  .|'    ||   ||   ||   ||..  '   ||   ||  .|'    ||     ||     ||..  '  
 |'|..'||  ||      ||  ||    ||   ''|||.   ||'''|.  ||      ||    ||      ''|||.  
 | '|' ||  '|.     ||  ||    || .     '||  ||    || '|.     ||    ||    .     '|| 
.|. | .||.  ''|...|'  .||...|'  |'....|'  .||...|'   ''|...|'    .||.   |'....|'  "

echo -e "${YELLOW}This Script Will install V2ray and Argo tunnel."
# Declare variable choice and assign value 4
choice=4
# Print to stdout
 echo "1. Yes"
 echo "2. No"
 echo -n "Please choose a word [1 or 2]? "
# Loop while the variable choice is equal 4
# bash while loop
while [ $choice == 2 ]; do
 
# read user input
read choice
# bash nested if/else
if [ $choice == 1 ] ; then
        echo -e "${RED}Downloading V2ray"
        sleep 3
        rm -f web config.json
        wget -O temp.zip https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
        unzip temp.zip
        sleep 2
        rm -f temp.zip
        sleep 2
        mv v2ray web
        sleep 2
        echo -n -e "${GREEN}Enter UUID or leave it: "
        read -r uuid
        if [[ -z $uuid ]]; then
        uuid="8d4a8f5e-c2f7-4c1b-b8c0-f8f5a9b6c384"
        fi
        cat << EOF > config.json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 8008,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF
        echo -e "${red}Downloading Cloudflare Argo: "
        sleep 2 
        wget https://github.com/eooce/choreo-2go/raw/main/files/server
        chmod +x web server
        echo -n -e "${GREEN}You Must Enter Your Argo Token: "
        read -r token
        nohup ./web run &>/dev/null &
        sleep 5
        nohup ./server tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token $token >/dev/null 2>&1 &

        echo -e "${YELLOW}V2ray is running on port 8008 and please configure on Argo"
        echo -n -e "${GREEN}Enter your Argo domain: "
        read -r domain
        echo -e "${PLAIN}"
        echo -e "${PLAIN}"
        echo -e "vless://$uuid@$domain:443?security=tls&sni=$domain&alpn=http/1.1&fp=randomized&type=ws&host=$domain&encryption=none#modsbots.com"
        echo -e "${RED}"
        echo -e "${RED}    Powered By www.modsbots.com"
        echo -e "${RED}"
        break
else                   

        if [ $choice == 2 ] ; then
                 echo -e "${RED}Ok Good Bye"
        
         
                
        fi
fi
done  

