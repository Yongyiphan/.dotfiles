#!/bin/bash

version="5.4.6"
dir="lua-$version"
FILE="$dir.tar.gz"
if ! [ -f "$FILE" ]; then
	echo "Lua tar not found. Curling Online"
	curl_site="http://www.lua.org/ftp/$FILE"
	curl -R -O $curl_site
fi

if ! [ -d "lua-$version" ]; then
	tar zxf $FILE
	cd $dir
	make all test
	sudo make install
fi
