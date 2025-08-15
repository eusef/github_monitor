#!/bin/bash

# --- Default Configuration ---
# The name of the output file that will contain the list of repositories.
OUTPUT_FILE="repos.txt"
# The default name of the file containing repositories to ignore.
IGNORE_FILE="ignored_repos_list.txt"
# Flag to determine if we are only fetching forked repos.
FORKS_ONLY=false
# Default visibility filter - all repositories
VISIBILITY="all"

# --- Helper Functions ---
display_help() {
    echo "Usage: $0 [OPTIONS] <GitHub_URL>"
    echo
    echo "Fetches repositories from a GitHub user or organization."
    echo "Default behavior is to fetch NON-FORKED (original) repositories with ALL visibility levels."
    echo
    echo "Arguments:"
    echo "  <GitHub_URL>    The full URL of the user or organization (e.g., https://github.com/1Password)."
    echo
    echo "Options:"
    echo "  -f, --forks-only      Only list repositories that are forks."
    echo "  -v, --visibility     Filter by repository visibility: public, private, or all (default: all)."
    echo "  -i, --ignore <file>   Specify a file containing repository URLs to ignore (default: ignored_repos_list.txt)."
    echo "  -h, --help            Display this help message and exit."
    exit 0
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--forks-only)
            FORKS_ONLY=true
            shift # past argument
            ;;
        -v|--visibility)
            VISIBILITY="$2"
            # Validate visibility value
            if [[ ! "$VISIBILITY" =~ ^(public|private|all)$ ]]; then
                echo "Error: Invalid visibility value '$VISIBILITY'. Must be 'public', 'private', or 'all'."
                exit 1
            fi
            shift # past argument
            shift # past value
            ;;
        -i|--ignore)
            IGNORE_FILE="$2"
            shift # past argument
            shift # past value
            ;;
        -h|--help)
            display_help
            ;;
        *)
            # Assume the last non-flag argument is the URL
            TARGET_URL="$1"
            shift
            ;;
    esac
done


# --- Script Logic ---

# Check if a GitHub user/organization URL was provided.
if [ -z "$TARGET_URL" ]; then
    echo "Error: No GitHub user or organization URL provided."
    display_help
fi

# Extract the username or organization name from the provided URL.
TARGET_ENTITY=$(echo "$TARGET_URL" | sed -E 's|^(https?://)?(www\.)?github\.com/||' | sed 's|/$||')

# Determine the jq filter and description based on the --forks-only flag and visibility.
if [ "$FORKS_ONLY" = true ]; then
    if [ "$VISIBILITY" = "all" ]; then
        jq_filter='.[] | select(.isFork == true) | .url'
        repo_type_desc="forked"
    elif [ "$VISIBILITY" = "public" ]; then
        jq_filter='.[] | select(.isFork == true and .isPrivate == false) | .url'
        repo_type_desc="public forked"
    else # private
        jq_filter='.[] | select(.isFork == true and .isPrivate == true) | .url'
        repo_type_desc="private forked"
    fi
else
    if [ "$VISIBILITY" = "all" ]; then
        jq_filter='.[] | select(.isFork == false) | .url'
        repo_type_desc="non-forked"
    elif [ "$VISIBILITY" = "public" ]; then
        jq_filter='.[] | select(.isFork == false and .isPrivate == false) | .url'
        repo_type_desc="public non-forked"
    else # private
        jq_filter='.[] | select(.isFork == false and .isPrivate == true) | .url'
        repo_type_desc="private non-forked"
    fi
fi

echo "🔍 Fetching $repo_type_desc repositories for '$TARGET_ENTITY'..."

# Debug information
echo "ℹ️ Filter settings:"
echo "  - Fork status: $([ "$FORKS_ONLY" = true ] && echo "forks only" || echo "non-forks only")"
echo "  - Visibility: $VISIBILITY"
echo "  - JQ filter: $jq_filter"

# Use 'gh repo list' with the determined jq filter and include isPrivate field.
repo_list=$(gh repo list "$TARGET_ENTITY" --limit 1000 --json "url,isFork,isPrivate" --jq "$jq_filter")

# Check if any repositories were found before filtering.
if [ -z "$repo_list" ]; then
    echo "⚠️ No $repo_type_desc repositories found for '$TARGET_ENTITY'."
    echo "This might be because:"
    echo "  - The user/organization has no repositories matching your criteria"
    echo "  - The combination of fork status and visibility filters is too restrictive"
    echo "  - You don't have access to private repositories"
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# Check if the ignore file exists and filter the list.
if [ -f "$IGNORE_FILE" ]; then
    echo "ℹ️ Using ignore list: '$IGNORE_FILE'. Filtering out specified repositories..."
    # Use grep to filter out any URLs present in the ignore file.
    final_list=$(echo "$repo_list" | grep -v -F -f "$IGNORE_FILE")
else
    # If no ignore file exists, use the full list.
    final_list="$repo_list"
fi

# Write the final, possibly filtered, list to the output file.
echo "$final_list" > "$OUTPUT_FILE"

# Check if any repositories were found and written to the file.
if [ -s "$OUTPUT_FILE" ]; then
    repo_count=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    echo "✅ Success! Found and saved $repo_count $repo_type_desc repositories."
    echo "List saved to '$OUTPUT_FILE'."
else
    echo "⚠️ No $repo_type_desc repositories found for '$TARGET_ENTITY' after applying ignore list."
    echo "All matching repositories were filtered out by the ignore list."
    rm -f "$OUTPUT_FILE" # Clean up empty file on failure.
fi