#!/bin/bash

# --- Configuration ---
# This is the file containing your list of repositories.
# Each line can be a full GitHub URL (e.g., https://github.com/owner/repo)
# or in the format "owner/repo".
REPO_LIST_FILE="repos.txt"

# This is the name of the CSV file that will be created with the issue data.
OUTPUT_CSV_FILE="issues_export.csv"

# --- Script Logic ---

# Start with a clean slate by removing the old CSV if it exists.
rm -f "$OUTPUT_CSV_FILE"

# Create the new CSV file and write the header row with all the new fields.
echo "Repository,Number,Title,State,StateReason,Author,Assignees,Labels,Milestone,Body,URL,ID,CreatedAt,UpdatedAt,ClosedAt,IsPinned,Closed,CommentsCount,ReactionsCount" > "$OUTPUT_CSV_FILE"

# Check if the repository list file actually exists before trying to read it.
if [ ! -f "$REPO_LIST_FILE" ]; then
    echo "Error: Repository list file not found at '$REPO_LIST_FILE'"
    echo "Please create it and add repositories."
    exit 1
fi

# Read the repo list file line by line.
while IFS= read -r repo_line || [[ -n "$repo_line" ]]; do
  # Skip any empty lines or lines that start with # (comments).
  if [[ -z "$repo_line" || "$repo_line" == \#* ]]; then
    continue
  fi

  # Extract 'owner/repo' from full URLs.
  repo_slug=$(echo "$repo_line" | sed -E 's|^(https?://)?(www\.)?github\.com/||' | sed 's|/$||' | sed 's/\.git$//')

  echo "Fetching open issues for '$repo_slug'..."

  # Use 'gh issue list' to fetch all specified fields.
  # We pipe the output to 'jq' to format it into a CSV row.
  # --arg passes the repository name as a variable into the jq command.
  gh issue list \
    --repo "$repo_slug" \
    --state open \
    --limit 500 \
    --json "number,title,state,stateReason,author,assignees,labels,milestone,body,url,id,createdAt,updatedAt,closedAt,isPinned,closed,comments,reactionGroups" | \
    jq --arg repo_name "$repo_slug" -r '.[] | [
        $repo_name,
        .number,
        .title,
        .state,
        .stateReason // "",
        .author.login // "ghost",
        (.assignees | map(.login) | join("; ")),
        (.labels | map(.name) | join("; ")),
        .milestone.title // "",
        (.body | gsub("\r\n|\n|\r"; " ")),
        .url,
        .id,
        .createdAt,
        .updatedAt,
        .closedAt,
        .isPinned,
        .closed,
        (.comments | length),
        (.reactionGroups | map(.users.totalCount) | add)
    ] | @csv' \
    >> "$OUTPUT_CSV_FILE"

done < "$REPO_LIST_FILE"

echo "✅ Success! All data has been exported to '$OUTPUT_CSV_FILE'"
