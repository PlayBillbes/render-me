#!/bin/bash
rm -rf *
# This script performs the following steps:
# 1. Downloads and sets up Webhook Relay.
# 2. Logs into Webhook Relay using user-provided credentials.
# 3. Creates a Webhook Relay tunnel and captures its public URL.
# 4. Downloads, unzips, and renames V2Ray.
# 5. Creates a 'config.json' file with user-defined UUID and port.
# 6. Starts the V2Ray 'web' executable in the background.
# 7. Optionally stops the started 'web' and 'relay' processes.

echo "--- Starting Setup Process ---"

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

# --- Webhook Relay Tunnel Creation and URL Capture ---
echo "Creating Webhook Relay tunnel 'modsbots' and capturing public URL..."
# Execute the relay command and capture its output
RELAY_OUTPUT=$(./relay tunnel create modsbots -d 127.0.0.1:8008)

# Check if the tunnel creation command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create Webhook Relay tunnel 'modsbots'. Exiting."
    echo "Output: $RELAY_OUTPUT"
    exit 1
fi

# Extract the part before '<---->' using awk
PUBLIC_URL=$(echo "$RELAY_OUTPUT" | awk -F'<---->' '{print $1}')

# Print the extracted URL (for verification)
echo "The public URL for 'modsbots' tunnel is: $PUBLIC_URL"
echo "" # Add a blank line for better readability


# --- V2Ray Setup ---
echo "Downloading and setting up V2Ray..."

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
V2RAY_PID=$! # Capture the PID of the V2Ray process

echo "V2Ray is now running in the background (PID: $V2RAY_PID)."
echo "You can check running processes with 'ps aux | grep web' or 'jobs'."
echo "" # Add a blank line for better readability

# --- Start Webhook Relay Tunnel in background ---
# The tunnel is already created and implicitly started by 'relay tunnel create'.
# We just need to ensure the process keeps running in the background.
# The 'relay tunnel create' command itself typically runs in the foreground until terminated.
# To keep it running, we would normally use nohup and & with the 'connect' command.
# However, since 'relay tunnel create' is used, it might manage the connection.
# For simplicity and to ensure it runs in the background, we will assume
# the 'relay tunnel create' command itself needs to be backgrounded if it's blocking.
# If 'relay tunnel create' is a one-shot command that sets up a persistent tunnel,
# then no further action is needed here to keep it running.
# For now, we'll rely on the 'relay tunnel create' command to manage the connection.
# If you need to explicitly run 'relay connect' in the background after creation,
# please let me know.

# We don't capture a RELAY_PID here directly from 'relay tunnel create'
# because it's assumed to be a setup command. If you need to manage
# the tunnel process directly for termination, you might need to
# use 'relay connect' in a nohup & fashion and capture its PID.

# For now, the script will assume the tunnel is active after the 'create' command.

echo "--- Setup Complete ---"

# --- Optional: Stop processes ---
read -p "Do you want to stop the started V2Ray (web) process now? (yes/no): " STOP_CHOICE
STOP_CHOICE_LOWER=$(echo "$STOP_CHOICE" | tr '[:upper:]' '[:lower:]')

if [[ "$STOP_CHOICE_LOWER" == "yes" ]]; then
    echo "Attempting to stop processes..."

    # Kill V2Ray process if it's still running
    if ps -p $V2RAY_PID > /dev/null; then
        echo "Stopping V2Ray (PID: $V2RAY_PID)..."
        kill "$V2RAY_PID"
        if [ $? -eq 0 ]; then
            echo "V2Ray stopped."
        else
            echo "Failed to stop V2Ray (PID: $V2RAY_PID)."
        fi
    else
        echo "V2Ray process (PID: $V2RAY_PID) not found or already stopped."
    fi

    # Note: 'relay tunnel create' typically runs and establishes the tunnel.
    # If it's a long-running process that needs to be explicitly killed,
    # you might need to capture its PID or use 'pkill relay'.
    # For now, we assume 'relay tunnel create' completes and sets up the tunnel.
    echo "No explicit 'relay' process to stop from 'relay tunnel create' command."
    echo "If you need to stop all 'relay' processes, you can use 'pkill relay'."

    echo "Process stopping attempt complete."
else
    echo "V2Ray process will continue running in the background."
    echo "You can stop it manually later using 'kill $V2RAY_PID' or 'pkill web'."
    echo "For Webhook Relay, if it's still running, you might need 'pkill relay'."
fi

echo "--- Script Finished ---"
