#!/bin/bash
source ~/.config/.bash_aliases
echo $1
echo "Test"
command="msedge '$1'"
eval "$command"
