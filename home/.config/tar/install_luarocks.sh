#!/bin/bash

VERSION='3.9.2'
FILE="luarocks-$VERSION"
if ! [ -f "$FILE" ]; then
	echo "$FILE tar not found. Curling Online"
	site_link="https://luarocks.org/releases/$FILE.tar.gz"
	wget site_link
fi

if ! [ -d "$FILE" ]; then
	tar zxpf $FILE
	cd $dir
	./configure && make && sudo make install
 	sudo luarocks install luasocket
fi
