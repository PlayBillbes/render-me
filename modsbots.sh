#!/bin/bash

relay login -k 7af1e38b-1a65-42ed-a5bf-b982c14764ea -s oClcgeTXIDZo
echo "ttyd serving at port 80 with username:pass as kali:kali"
./vless.sh bash
nohup relay connect --region eu --name webig & ls
chmod +x /usr/local/bin/ttyd_linux
/usr/local/bin/ttyd_linux -p 8080 -c modsbots:modsbots bash 
