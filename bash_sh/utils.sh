#!/bin/bash

enable_file(){
	# Check if exactly one argument is provided
	if [ $# -ne 1 ]; then
			echo "Error: Please provide exactly one file path."
			return 1
	fi

	# Check if the file exists
	if [ -f "$1" ]; then
			chmod +x "$1"
			echo "File '$1' is now executable."
	else
			echo "Error: File '$1' does not exist."
			return 1
	fi
}

goto(){
	local target_dir="$1"
	# Base directory containing user folders
	local users_base_dir="/mnt/c/Users"
	local ignore_file="$HOME/config/.bash_find_ignore"

	# Check if the target directory is a key in the associative array
	if [[ -n "${gotoPaths[$target_dir]}" ]]; then
		cd "${gotoPaths[$target_dir]}" || return
		return
	fi

	if ! command -v fd &> /dev/null; then
			echo "fd is not installed. Please install fd first."
			return 1
	fi


	# Initialize an array to store the paths of all 'Documents' directories
	local documents_dirs=()

	# Iterate over each directory in /mnt/c/Users to find 'Documents' folders
	for user_dir in "$users_base_dir"/*/; do
			if [ -d "${user_dir}Documents" ]; then
					documents_dirs+=("${user_dir}Documents")
			fi
	done

	# Check if no 'Documents' directories were found
	if [ ${#documents_dirs[@]} -eq 0 ]; then
			echo "No 'Documents' directories found under /mnt/c/Users."
			return 1
	fi

	# Initialize an array to hold the search results
	local search_results=()

	# Search for the target directory within each 'Documents' directory
	for doc_dir in "${documents_dirs[@]}"; do
			while IFS= read -r line; do
					search_results+=("$line")
			done < <(fd --type d --ignore-file "$ignore_file" --fixed-strings "$target_dir" "$doc_dir" 2>/dev/null)
	done

	# Use fzf to select from the search results
	local dir=$(printf "%s\n" "${search_results[@]}" | fzf --query="$target_dir" --select-1 --exit-0)

	if [ -z "$dir" ]; then
			echo "No directory found or selected."
			return 1
	fi

	# Change to the selected directory
	cd "$dir" || return
}

