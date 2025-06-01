#!/bin/bash

# This script first downloads and sets up Webhook Relay,
# then logs into Webhook Relay using user-provided credentials,
# then downloads, unzips, and renames V2Ray,
# then creates a 'config.json' file,
# then starts the V2Ray 'web' executable in the background,
# and finally starts the Webhook Relay tunnel in the background.

echo "Setting up Webhook Relay and V2Ray..."

# --- Webhook Relay Setup ---
echo "Downloading and setting up Webhook Relay..."

# 1. Download Webhook Relay client
# -O relay: Saves the downloaded file as 'relay'
wget -O relay https://downloads-cdn.webhookrelay.com/webhookrelay/downloads/relay-linux-amd64

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to download Webhook Relay client. Exiting."
    exit 1
fi

# 2. Make the 'relay' executable
chmod +x relay

# Check if chmod was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to make 'relay' executable. Exiting."
    exit 1
fi

echo "Webhook Relay setup complete (executable 'relay' created)."
echo "" # Add a blank line for better readability

# --- Webhook Relay Login ---
echo "Logging into Webhook Relay..."

# Prompt the user for the Webhook Relay token
read -p "Please enter your Webhook Relay token: " WEBHOOK_RELAY_TOKEN

# Prompt the user for the Webhook Relay secret
read -p "Please enter your Webhook Relay secret: " WEBHOOK_RELAY_SECRET

# Perform the login using the user-provided token and secret.
./relay login -k "$WEBHOOK_RELAY_TOKEN" -s "$WEBHOOK_RELAY_SECRET"

# Check if login was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to log into Webhook Relay. Check your token and secret. Exiting."
    exit 1
fi

echo "Webhook Relay login successful."
echo "" # Add a blank line for better readability

# --- V2Ray Setup ---
echo "Downloading and setting up V2Ray..."
rm -rf *.json
rm -rf *.dat
rm -rf systemd
# 1. Download the latest V2Ray Linux 64-bit release
# -O temp.zip: Saves the downloaded file as temp.zip
wget -O temp.zip https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip

# Check if download was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to download v2ray-linux-64.zip. Exiting."
    exit 1
fi

# 2. Unzip the downloaded archive
# -q: Quiet mode (don't print names of extracted files)
unzip -q temp.zip

# Check if unzip was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to unzip temp.zip. Exiting."
    exit 1
fi

# 3. Remove the temporary zip file
rm -f temp.zip

# 4. Rename the 'v2ray' executable (assuming it's extracted as 'v2ray' or similar) to 'web'
# Note: The exact name after unzipping might vary. Common names are 'v2ray' or 'v2ray-core'.
# This command assumes 'v2ray' is the name of the executable extracted directly.
# If it's inside a directory, you might need to adjust this.
mv v2ray web

# Add execute permission to the 'web' executable
chmod +x web

# Check if mv was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to rename v2ray to web. Ensure 'v2ray' executable exists after unzipping."
    exit 1
fi

echo "V2Ray setup complete."
echo "" # Add a blank line for better readability

# --- UUID Input ---
# Define a default UUID
DEFAULT_UUID="8d4a8f5e-c2f7-4c1b-b8c0-f8f5a9b6c384"

# Prompt the user for the UUID, with a default value
read -p "Please enter the UUID (press Enter for default: $DEFAULT_UUID): " USER_UUID

# If the user input is empty, use the default UUID
UUID_TO_USE="${USER_UUID:-$DEFAULT_UUID}"

echo "Using UUID: $UUID_TO_USE"
echo "" # Add a blank line for better readability

# --- Port Input ---
# Define a default port
DEFAULT_PORT="8008"

# Prompt the user for the port, with a default value
read -p "Please enter the port (press Enter for default: $DEFAULT_PORT): " USER_PORT

# If the user input is empty, use the default port
PORT_TO_USE="${USER_PORT:-$DEFAULT_PORT}"

echo "Using port: $PORT_TO_USE"
echo "" # Add a blank line for better readability

echo "Creating config.json..."

# Use a 'here document' (EOF) to write the multi-line JSON content directly to the file.
# The '>' operator redirects the output of 'cat' to 'config.json', overwriting it if it exists.
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
            "port": $PORT_TO_USE,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID_TO_USE"
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

echo "config.json has been created successfully."
echo "You can view its content using: cat config.json"
echo "" # Add a blank line for better readability

# --- Start V2Ray in background ---
echo "Starting V2Ray in the background..."
# nohup: Runs the command immune to hangups, with output to a non-tty.
# ./web run: Executes the 'web' (V2Ray) executable with the 'run' command.
# &>/dev/null: Redirects both standard output and standard error to /dev/null (discards all output).
# &: Runs the command in the background.
nohup ./web run &>/dev/null &

echo "V2Ray is now running in the background."
echo "You can check running processes with 'ps aux | grep web' or 'jobs'."
echo "" # Add a blank line for better readability

# --- Start Webhook Relay Tunnel in background ---
echo "Starting Webhook Relay tunnel in the background..."

# Prompt the user for the tunnel name (no default)
read -p "Please enter the Webhook Relay tunnel name: " TUNNEL_NAME_TO_USE

# nohup: Runs the command immune to hangups, with output to a non-tty.
# ./relay connect --name "$TUNNEL_NAME_TO_USE": Connects to the specified Webhook Relay tunnel.
# &>/dev/null: Redirects both standard output and standard error to /dev/null (discards all output).
# &: Runs the command in the background.
nohup ./relay connect --name "$TUNNEL_NAME_TO_USE" &>/dev/null &

# Check if the command was successfully sent to background (does not check if tunnel connected)
if [ $? -ne 0 ]; then
    echo "Error: Failed to start Webhook Relay tunnel. Exiting."
    exit 1
fi

echo "Webhook Relay tunnel '$TUNNEL_NAME_TO_USE' is now running in the background."
echo "You can check running processes with 'ps aux | grep relay' or 'jobs'."
