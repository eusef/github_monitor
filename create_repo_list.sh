#!/bin/bash

# --- Configuration ---
# The name of the output CSV file that will contain the list of repositories.
OUTPUT_FILE="repos.csv"
# The file containing repositories to ignore.
IGNORE_FILE="ignored_repos_list.txt"

# --- Helper Functions ---
display_help() {
    echo "Usage: $0 <GitHub_URL>"
    echo
    echo "Fetches public, non-forked repositories from a GitHub user or organization."
    echo "Outputs a CSV file with: Repo Name, Link, Description, Stars, Open Issues, Open PRs"
    echo
    echo "Arguments:"
    echo "  <GitHub_URL>    The full URL of the user or organization (e.g., https://github.com/1Password)."
    echo
    echo "Options:"
    echo "  -i, --ignore <file>   Specify a file containing repository URLs to ignore (default: ignored_repos_list.txt)."
    echo "  -h, --help            Display this help message and exit."
    echo
    echo "Note: The script makes additional API calls to fetch detailed repository information,"
    echo "      which may take longer and is subject to GitHub API rate limits."
    exit 0
}

# Function to generate CSV header
generate_csv_header() {
    echo "Name,URL,Description,Stars,Open Issues,Open PRs"
}

# Function to generate CSV row for a repository
generate_csv_row() {
    local repo_name="$1"
    local repo_url="$2"
    local description="$3"
    local stars="$4"
    local issues_count="$5"
    local pr_count="$6"
    
    # Escape CSV special characters (quotes, commas, newlines)
    repo_name=$(echo "$repo_name" | sed 's/"/""/g' | tr -d '\n\r')
    if [[ "$repo_name" == *","* || "$repo_name" == *"\""* ]]; then
        repo_name="\"$repo_name\""
    fi
    
    description=$(echo "$description" | sed 's/"/""/g' | tr -d '\n\r')
    if [[ "$description" == *","* || "$description" == *"\""* ]]; then
        description="\"$description\""
    fi
    
    echo "$repo_name,$repo_url,$description,$stars,$issues_count,$pr_count"
}

# Function to get repository details (description and stars)
get_repo_details() {
    local repo_url="$1"
    local repo_owner=$(echo "$repo_url" | sed -E 's|https://github\.com/([^/]+)/[^/]+|\1|')
    local repo_name=$(echo "$repo_url" | sed -E 's|https://github\.com/[^/]+/([^/]+)|\1|')
    
    # Get repository details using the repo API endpoint
    local repo_data=$(gh api repos/$repo_owner/$repo_name 2>/dev/null)
    if [ $? -eq 0 ]; then
        local description=$(echo "$repo_data" | jq -r '.description // ""')
        local stars=$(echo "$repo_data" | jq -r '.stargazers_count // 0')
        echo "$description|$stars"
    else
        echo "|0"
    fi
}

# Function to get issue count for a repository
get_issue_count() {
    local repo_url="$1"
    local repo_owner=$(echo "$repo_url" | sed -E 's|https://github\.com/([^/]+)/[^/]+|\1|')
    local repo_name=$(echo "$repo_url" | sed -E 's|https://github\.com/[^/]+/([^/]+)|\1|')
    
    # Get open issues count with pagination (excludes PRs by filtering out items with pull_request field)
    local issues_count=$(gh api --paginate "repos/$repo_owner/$repo_name/issues?state=open&per_page=100" --jq '.[] | select(.pull_request == null)' 2>/dev/null | jq -s 'length' 2>/dev/null || echo "0")
    
    echo "$issues_count"
}

# Function to get pull request count for a repository
get_pr_count() {
    local repo_url="$1"
    local repo_owner=$(echo "$repo_url" | sed -E 's|https://github\.com/([^/]+)/[^/]+|\1|')
    local repo_name=$(echo "$repo_url" | sed -E 's|https://github\.com/[^/]+/([^/]+)|\1|')
    
    # Get open pull requests count with pagination
    local pr_count=$(gh api --paginate "repos/$repo_owner/$repo_name/pulls?state=open&per_page=100" --jq '.[]' 2>/dev/null | jq -s 'length' 2>/dev/null || echo "0")
    
    echo "$pr_count"
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
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

# Hardcoded filter for public, non-forked repositories
jq_filter='.[] | select(.isFork == false and .isPrivate == false) | {name: .name, url: .url, isFork: .isFork, isPrivate: .isPrivate}'
repo_type_desc="public non-forked"

echo "🔍 Fetching $repo_type_desc repositories for '$TARGET_ENTITY'..."

# Use 'gh repo list' with the determined jq filter and include necessary fields.
repo_list=$(gh repo list "$TARGET_ENTITY" --limit 1000 --json "name,url,isFork,isPrivate" --jq "$jq_filter")

# Check if any repositories were found before filtering.
if [ -z "$repo_list" ]; then
    echo "⚠️ No $repo_type_desc repositories found for '$TARGET_ENTITY'."
    echo "This might be because:"
    echo "  - The user/organization has no public repositories"
    echo "  - All repositories are forks"
    echo "  - You don't have access to the repositories"
    rm -f "$OUTPUT_FILE"
    exit 1
fi

# Store the filtered list for CSV processing
filtered_repos="$repo_list"

# Check if the ignore file exists
if [ -f "$IGNORE_FILE" ]; then
    echo "ℹ️ Using ignore list: '$IGNORE_FILE'. Filtering out specified repositories..."
fi

# Generate CSV output
echo "📊 Generating CSV output with columns: Name, URL, Description, Stars, Open Issues, Open PRs"

# Start with CSV header
generate_csv_header > "$OUTPUT_FILE"

# Count total repositories for progress tracking
total_repos=$(echo "$filtered_repos" | jq -c '.' | wc -l)
current_repo=0

# Process each repository and add CSV rows
while IFS= read -r repo_json; do
    if [ -n "$repo_json" ]; then
        current_repo=$((current_repo + 1))
        
        # Extract repository information
        repo_name=$(echo "$repo_json" | jq -r '.name')
        repo_url=$(echo "$repo_json" | jq -r '.url')
        
        # Check if this repo should be ignored
        if [ -f "$IGNORE_FILE" ]; then
            if grep -q -F "$repo_url" "$IGNORE_FILE"; then
                echo "  ⏭️  Skipping ignored repository: $repo_name"
                continue
            fi
        fi
        
        echo "📊 Processing repository $current_repo/$total_repos: $repo_name"
        
        # Fetch repository details (description and stars)
        repo_details=$(get_repo_details "$repo_url")
        description=$(echo "$repo_details" | cut -d'|' -f1)
        stars=$(echo "$repo_details" | cut -d'|' -f2)
        
        # Fetch actual issue and PR counts
        issues_count=$(get_issue_count "$repo_url")
        pr_count=$(get_pr_count "$repo_url")
        
        # Generate CSV row and append to file
        generate_csv_row "$repo_name" "$repo_url" "$description" "$stars" "$issues_count" "$pr_count" >> "$OUTPUT_FILE"
    fi
done < <(echo "$filtered_repos" | jq -c '.')

# Check if any repositories were found and written to the file.
if [ -s "$OUTPUT_FILE" ]; then
    repo_count=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    # Subtract 1 from count for CSV (header row)
    repo_count=$((repo_count - 1))
    echo "✅ Success! Found and saved $repo_count $repo_type_desc repositories."
    echo "CSV file saved to '$OUTPUT_FILE'."
else
    echo "⚠️ No $repo_type_desc repositories found for '$TARGET_ENTITY' after applying ignore list."
    echo "All matching repositories were filtered out by the ignore list."
    rm -f "$OUTPUT_FILE" # Clean up empty file on failure.
fi