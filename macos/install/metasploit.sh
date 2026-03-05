#!/bin/bash

if [ -d "/opt/metasploit-framework" ]; then
    exit 0
fi

curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod +x msfinstall
sudo ./msfinstall
printf "\n# Add Metasploit Framework to PATH\n%s\n" 'export PATH="/opt/metasploit-framework/bin:$PATH"' >> "$RC_FILE"