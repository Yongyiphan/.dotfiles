#!/bin/bash


guideline(){
	echo "Select a category to display useful Git commands:"
	echo "1) Repository Setup"
	echo "2) Branching"
	echo "3) Staging and Committing"
	echo "4) Remote Repositories"
	echo "5) Inspection and Logs"
	echo "6) Stashing"
	echo "7) Rebasing and Merging"
	echo "8) Undoing Changes"
	echo "9) Submodules"

	read -p "Enter the number corresponding to the category: " category

	case $category in
		1)
			echo -e "\n== Repository Setup Commands =="
			echo "git init                            # Initialize a new Git repository"
			echo "git clone <url>                     # Clone a repository from a remote URL"
			echo "git remote add origin <url>         # Add a new remote repository"
			;;
		2)
			echo -e "\n== Branching Commands =="
			echo "git branch                          # List all branches"
			echo "git branch <branch_name>            # Create a new branch"
			echo "git checkout <branch_name>          # Switch to a specific branch"
			echo "git checkout -b <branch_name>       # Create and switch to a new branch"
			echo "git branch -d <branch_name>         # Delete a local branch"
			;;
		3)
			echo -e "\n== Staging and Committing Commands =="
			echo "git add <file>                      # Stage a specific file"
			echo "git add .                           # Stage all changes"
			echo "git commit -m \"<message>\"          # Commit staged changes with a message"
			echo "git commit --amend                  # Amend the previous commit"
			;;
		4)
			echo -e "\n== Remote Repository Commands =="
			echo "git fetch                           # Fetch changes from the remote"
			echo "git pull                            # Pull changes from the remote"
			echo "git push                            # Push local changes to the remote"
			echo "git remote -v                       # Show the list of remote repositories"
			;;
		5)
			echo -e "\n== Inspection and Log Commands =="
			echo "git status                          # Show the current status of the working directory"
			echo "git log                             # Show the commit history"
			echo "git diff                            # Show changes between working directory and index"
			echo "git show <commit>                   # Show details of a specific commit"
			;;
		6)
			echo -e "\n== Stashing Commands =="
			echo "git stash                           # Save changes temporarily (stash)"
			echo "git stash pop                       # Apply stashed changes and remove the stash"
			echo "git stash list                      # List all stashed changes"
			echo "git stash drop                      # Drop a specific stash"
			;;
		7)
			echo -e "\n== Rebasing and Merging Commands =="
			echo "git merge <branch_name>             # Merge a branch into the current branch"
			echo "git rebase <branch_name>            # Rebase the current branch onto another branch"
			echo "git rebase --continue               # Continue rebasing after resolving conflicts"
			echo "git merge --abort                   # Abort a merge in case of conflicts"
			;;
		8)
			echo -e "\n== Undoing Changes Commands =="
			echo "git reset <file>                    # Unstage a file"
			echo "git checkout <file>                 # Discard changes in the working directory"
			echo "git reset --hard                    # Reset the index and working directory to the last commit"
			echo "git revert <commit>                 # Create a new commit that undoes the changes of a previous commit"
			;;
		9)
			echo -e "\n== Git Submodule Commands =="
			echo "git submodule add <url>             # Add a new submodule"
			echo "git submodule update --init --recursive   # Initialize and update submodules"
			echo "git submodule foreach git pull origin main # Pull the latest changes for all submodules"
			echo "git submodule status                # Check the status of submodules"
			echo "git submodule deinit <path>         # Deinitialize a submodule"
			echo "git submodule sync                  # Synchronize submodules with the remote repository"
			;;
		*)
			echo "Invalid option. Please select a valid category."
			;;
	esac
}

# Function to switch Git remote between SSH and HTTPS with custom SSH configurations
git_remote_old() {
    # Usage: git_remote [personal|school|https]
    local account_type="$1"

    # Validate input
    if [[ -z "$account_type" ]]; then
        echo "Usage: git_remote [personal|school|https]"
        return 1
    fi

    # Get current origin URL
    local current_url
    current_url=$(git remote get-url origin 2>/dev/null)

    if [[ -z "$current_url" ]]; then
        echo "Error: Unable to determine current remote origin URL."
        return 1
    fi

    # Extract repository user and project name
    local repo_user repo_name
    if [[ "$current_url" =~ github.*[:/](.+)/(.+)\.git ]]; then
        repo_user="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]}"
    else
        echo "Error: Could not parse current origin URL."
        return 1
    fi

    # Construct new URL based on account type
    local new_url=""
    if [[ "$account_type" == "personal" ]]; then
        new_url="git@github-personal-wsl:${repo_user}/${repo_name}.git"
    elif [[ "$account_type" == "school" ]]; then
        new_url="git@github-school-sit-wsl:${repo_user}/${repo_name}.git"
    elif [[ "$account_type" == "https" ]]; then
        new_url="https://github.com/${repo_user}/${repo_name}.git"
    else
        echo "Invalid option. Use 'personal', 'school', or 'https'."
        return 1
    fi

    # Update the remote URL
    git remote set-url origin "$new_url"
    echo "Git remote origin updated to: $new_url"
}

git_remote() {
    local mode="$1"

    # Validate the mode input
    if [[ "$mode" != "ssh" && "$mode" != "https" ]]; then
        echo "Usage: git_remote [ssh|https]"
        return 1
    fi

    # Function to convert URLs inline
    convert_url() {
        local url="$1"
        local mode="$2"

        # Extract owner and repo from the current URL
        if [[ "$url" =~ ^(git@[^:]+:|https://[^/]+/)([^/]+)/([^/]+)\.git$ ]]; then
            local owner="${BASH_REMATCH[2]}"
            local repo="${BASH_REMATCH[3]}"

            if [[ "$mode" == "ssh" ]]; then
                echo "git@github.com:${owner}/${repo}.git"
            elif [[ "$mode" == "https" ]]; then
                echo "https://github.com/${owner}/${repo}.git"
            fi
        else
            # Invalid URL format
            echo ""
        fi
    }

    # 1) Update main repository URL
    local old_main_url
    old_main_url="$(git remote get-url origin 2>/dev/null)"
    if [[ -z "$old_main_url" ]]; then
        echo "Error: Could not get the current 'origin' remote URL."
        return 1
    fi

    local new_main_url
    new_main_url="$(convert_url "$old_main_url" "$mode")"
    if [[ -z "$new_main_url" ]]; then
        echo "Error: Could not parse or convert main repository URL: $old_main_url"
        return 1
    fi

    echo "Updating main repository remote from:"
    echo "  $old_main_url"
    echo "to:"
    echo "  $new_main_url"
    git remote set-url origin "$new_main_url"

    # 2) Update submodule URLs if .gitmodules exists
    if [[ ! -f .gitmodules ]]; then
        echo "No .gitmodules file found; skipping submodule updates."
        return 0
    fi

    echo "Updating submodule URLs in .gitmodules..."
    git config --file .gitmodules --get-regexp "submodule\..*\.url" | while read -r key old_submodule_url; do
        local new_submodule_url
        new_submodule_url="$(convert_url "$old_submodule_url" "$mode")"

        if [[ -n "$new_submodule_url" ]]; then
            git config --file .gitmodules "$key" "$new_submodule_url"
            echo "  Updated $old_submodule_url -> $new_submodule_url"
        else
            echo "  Skipping (unrecognized URL pattern): $old_submodule_url"
        fi
    done

    # 3) Sync submodule changes
    echo "Synchronizing submodule URLs to local config..."
    git submodule sync --recursive

    # 4) Re-initialize and update submodules
    echo "Re-initializing submodules..."
    git submodule update --init --recursive

    echo "Done."
}


refresh_gitignore(){

	local CMDID="$1"
	# Ensure we're in a git repository
	if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
			echo "Not a git repository. Please run this function from within a git repo."
			return 1
	fi

	# Update the git index by removing all cached files
	git rm -r --cached .

	# Re-add all files, respecting the updated .gitignore
	git add .

	if [ $CMDID = 'commit' ]; then
		# Commit the changes
		git commit -m "Refresh .gitignore changes"
		echo ".gitignore changes have been refreshed and committed."
	fi

}


remove_lock() {
    # Check if the current directory is a Git repository
    if [ -d ".git" ]; then
        # Check if the lock file exists
        if [ -f ".git/index.lock" ]; then
            echo "Index.lock Found"
            # Try to remove the lock file (no sudo)
            rm -f .git/index.lock 2>/dev/null

            # Check if removal was successful
            if [ ! -f ".git/index.lock" ]; then
                echo "Index.lock removed successfully"
            else
                echo "Failed to remove Index.lock. Check permissions or running processes."
            fi
        else
            echo "Cannot find Index.lock"
        fi
    else
        echo "Not a Git repository"
    fi
}
