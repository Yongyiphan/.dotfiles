#!/bin/bash

#Sudo update
#sudo apt-get update -y
##Sudo upgrade
#sudo apt-get upgrade -y

path="$HOME/.config/bash_sh"
for file in "$path"/*.sh; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        echo "Running script: $file"
				chmod +x $file
				$file
        echo "Script completed: $file"
    fi
done

path="$HOME/.config/tar"
for file in "$path"/*.sh; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        echo "Running script: $file"
				chmod +x $file
        echo "Script completed: $file"
    fi
done
