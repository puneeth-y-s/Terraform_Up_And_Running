#!/bin/bash
cd /home/ec2-user
echo "<h1>Hello, World</h1>" > index.html
echo "<p>DB address: ${db_address}</p>" >> index.html
echo "<p>DB port: ${db_port}</p>" >> index.html
nohup python3 -m http.server ${server_port} &