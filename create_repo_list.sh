#!/bin/bash

# --- Configuration ---
# The name of the output file that will contain the list of repositories.
# This should match the REPO_LIST_FILE in your other script.
OUTPUT_FILE="repos.txt"

# --- Script Logic ---

# Check if a GitHub user/organization URL was provided as an argument.
if [ -z "$1" ]; then
    echo "Error: No GitHub user or organization URL provided."
    echo "Usage: $0 <URL>"
    echo "Example: $0 https://github.com/1Password"
    exit 1
fi

# Extract the username or organization name from the provided URL.
# This handles various URL formats and removes trailing slashes.
TARGET_ENTITY=$(echo "$1" | sed -E 's|^(https?://)?(www\.)?github\.com/||' | sed 's|/$||')

echo "🔍 Fetching all public repositories for '$TARGET_ENTITY'..."

# Use 'gh repo list' to get all public repositories for the target entity.
# --limit sets a high limit to fetch as many repos as possible (max 1000).
# The output is formatted directly into the full URL format.
gh repo list "$TARGET_ENTITY" --limit 1000 --json "url" --jq ".[] | .url" > "$OUTPUT_FILE"

# Check if any repositories were found and written to the file.
if [ -s "$OUTPUT_FILE" ]; then
    repo_count=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    echo "✅ Success! Found $repo_count repositories."
    echo "List saved to '$OUTPUT_FILE'."
else
    echo "⚠️ No public repositories found for '$TARGET_ENTITY', or an error occurred."
    rm -f "$OUTPUT_FILE" # Clean up empty file on failure.
fi
