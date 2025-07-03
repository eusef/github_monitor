# GitHub Data Exporter Scripts

A collection of powerful shell scripts designed to streamline the process of fetching and exporting data about repositories, pull requests, and issues from GitHub.

These scripts leverage the GitHub CLI (`gh`) and `jq` to create clean, detailed CSV files, making it easy to analyze, report on, or migrate your GitHub data.

## Features

-   **Create Repository Lists**: Automatically generate a list of public repositories for any user or organization.
-   **Filter Repositories**: Easily include or exclude forked repositories and specify a list of repositories to ignore.
-   **Export Open Pull Requests**: Fetch a comprehensive set of data for all open PRs in your specified repositories.
-   **Export Open Issues**: Get detailed information for all open issues, ready for analysis.
-   **CSV Output**: All data is exported into well-structured CSV files with detailed headers.
-   **Flexible Configuration**: Scripts are designed to read from a simple text file, making it easy to manage multiple repositories.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured on your system:

1.  **[GitHub CLI (`gh`)](https://cli.github.com/)**: Required for authenticating with and fetching data from the GitHub API.
    -   After installation, run `gh auth login` to authenticate with your GitHub account.
2.  **[jq](https://stedolan.github.io/jq/)**: A lightweight and flexible command-line JSON processor. It is essential for parsing the API responses.
    -   You can typically install it using a package manager (e.g., `brew install jq` on macOS, `sudo apt-get install jq` on Debian/Ubuntu).
3.  **Bash**: The scripts are written in Bash and should be run in a Bash-compatible shell.

## Setup

1.  **Clone or Download**: Place the scripts (`create_repo_list.sh`, `prs.sh`, `issues.sh`) into the same directory.
2.  **Make Scripts Executable**: Open your terminal, navigate to the directory, and run the following command to make the scripts executable:
    ```bash
    chmod +x create_repo_list.sh prs.sh issues.sh
    ```

## Usage

The workflow is typically a two-step process:
1.  First, create a `repos.txt` file that lists the target repositories.
2.  Then, run the `prs.sh` or `issues.sh` scripts to export the data.

---

### 1. `create_repo_list.sh`

This script generates a file named `repos.txt` containing a list of repository URLs from a specified GitHub user or organization.

**Command:**

```bash
./create_repo_list.sh [OPTIONS] <GitHub_URL>
```

**Arguments:**

-   `<GitHub_URL>`: **(Required)** The full URL of the GitHub user or organization (e.g., `https://github.com/microsoft`).

**Options:**

-   `-f`, `--forks-only`: Only list repositories that are forks. (Default is to list non-forked repositories).
-   `-i`, `--ignore <file>`: Specify a file containing repository URLs to ignore. The default ignore file is `ignored_repos_list.txt`.
-   `-h`, `--help`: Display the help message.

**Example:**

To get all non-forked repositories from the `1Password` organization:

```bash
./create_repo_list.sh [https://github.com/1Password](https://github.com/1Password)
```

This will create a `repos.txt` file in the same directory.

---

### 2. `prs.sh`

This script reads the `repos.txt` file and exports all open pull requests from the listed repositories into a CSV file named `prs_export.csv`.

**Configuration:**

-   Ensure a `repos.txt` file exists in the same directory. Each line should contain a repository in the format `owner/repo` or a full GitHub URL.

**Command:**

```bash
./prs.sh
```

The script will iterate through each repository in `repos.txt` and append the pull request data to `prs_export.csv`.

**Output CSV Columns:**
`Repository`, `Number`, `Title`, `State`, `IsDraft`, `Author`, `Assignees`, `Labels`, `Milestone`, `BaseBranch`, `HeadBranch`, `Additions`, `Deletions`, `ChangedFiles`, `ReviewDecision`, `URL`, `ID`, `CreatedAt`, `UpdatedAt`, `ClosedAt`, `MergedAt`, `MergedBy`, `Body`

---

### 3. `issues.sh`

This script reads the `repos.txt` file and exports all open issues from the listed repositories into a CSV file named `issues_export.csv`.

**Configuration:**

-   Just like `prs.sh`, this script requires a `repos.txt` file.

**Command:**

```bash
./issues.sh
```

The script will process each repository and save the issue data to `issues_export.csv`.

**Output CSV Columns:**
`Repository`, `Number`, `Title`, `State`, `StateReason`, `Author`, `Assignees`, `Labels`, `Milestone`, `Body`, `URL`, `ID`, `CreatedAt`, `UpdatedAt`, `ClosedAt`, `IsPinned`, `Closed`, `CommentsCount`, `ReactionsCount`

## Full Workflow Example

Here is a complete example of how to use these scripts together to export all open issues from your organization's repositories.

1.  **Create an ignore file (Optional)**:
    If there are repositories you wish to exclude, create a file named `ignored_repos_list.txt` and add the full repository URLs to it, one per line.

    ```
    [https://github.com/my-org/archive-repo](https://github.com/my-org/archive-repo)
    [https://github.com/my-org/test-repo](https://github.com/my-org/test-repo)
    ```

2.  **Generate the Repository List**:
    Run `create_repo_list.sh` to fetch all repositories from your organization, respecting the ignore file.

    ```bash
    ./create_repo_list.sh --ignore ignored_repos_list.txt [https://github.com/my-org](https://github.com/my-org)
    ```
    This creates `repos.txt` with the filtered list of repositories.

3.  **Export Issues**:
    Now, run the `issues.sh` script to fetch all open issues from the repositories listed in `repos.txt`.

    ```bash
    ./issues.sh
    ```
    After the script finishes, you will have a file named `issues_export.csv` containing all the data.

## Contributing

Contributions are welcome! If you have ideas for improvements or find a bug, please open an issue or submit a pull request.

## License

This project is open source and available under the [MIT License](LICENSE).
