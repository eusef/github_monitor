# GitHub Repository Monitor

A collection of bash scripts to monitor GitHub repositories, issues, and pull requests.

## Scripts

### `create_repo_list.sh`

Fetches repositories from a GitHub user or organization and outputs them in either plain text or CSV format.

#### Features

- **Flexible Output Formats**: Choose between plain text (default) or CSV output
- **Configurable Columns**: Define CSV columns in a separate configuration file
- **Repository Filtering**: Filter by fork status and visibility (public/private/all)
- **Ignore List**: Exclude specific repositories using an ignore file
- **Comprehensive Data**: Extract repository names, URLs, and metadata

#### Usage

```bash
./create_repo_list.sh [OPTIONS] <GitHub_URL>
```

#### Options

- `-f, --forks-only`: Only list repositories that are forks
- `-v, --visibility`: Filter by repository visibility: `public`, `private`, or `all` (default: `all`)
- `-i, --ignore <file>`: Specify a file containing repository URLs to ignore (default: `ignored_repos_list.txt`)
- `-c, --columns <file>`: Specify a file containing CSV column definitions (default: `columns.conf`)
- `--csv`: Output in CSV format instead of plain text
- `-h, --help`: Display help message and exit

#### Examples

**Basic usage (plain text output):**
```bash
./create_repo_list.sh https://github.com/1Password
```

**CSV output with custom columns:**
```bash
./create_repo_list.sh --csv -c my_columns.conf https://github.com/1Password
```

**Forked repositories only:**
```bash
./create_repo_list.sh -f https://github.com/1Password
```

**Public repositories only:**
```bash
./create_repo_list.sh -v public https://github.com/1Password
```

#### CSV Column Configuration

The script supports configurable CSV columns defined in a separate file (default: `columns.conf`). Each line defines a column in the format:

```
column_name=default_value
```

**Default columns:**
- `name`: Repository name
- `url`: Repository URL
- `issues`: Number of issues (currently set to 0)
- `pullRequests`: Number of pull requests (currently set to 0)

**Custom column configuration example:**
```
# Custom columns.conf
name=
url=
description=
language=
stars=0
forks=0
```

**Notes:**
- Column names are case-sensitive
- The script automatically maps known column names (`name`, `url`, `issues`, `pullRequests`) to actual repository data
- `issues` and `pullRequests` columns now fetch real counts from the GitHub API
- Issues count excludes pull requests for accurate issue-only counting
- Pull request count uses the dedicated PRs API endpoint
- Other columns will use their default values
- Columns appear in the CSV in the order they are defined in the configuration file
- **Note**: CSV output with issue/PR counts makes additional API calls and may take longer

#### Output Files

- **Plain text mode**: Creates `repos.txt` with one repository URL per line
- **CSV mode**: Creates `repos.csv` with configurable columns and repository data

#### Requirements

- `gh` CLI tool (GitHub CLI) installed and authenticated
- `jq` for JSON processing
- `bash` shell

#### Performance Considerations

When using CSV output with issue and PR counts:
- The script makes additional API calls for each repository
- Processing time increases with the number of repositories
- Progress indicators show current status during processing
- GitHub API rate limits may apply for large repositories
- Consider using the ignore file to exclude repositories you don't need

### `issues.sh`

Monitors issues in GitHub repositories.

### `prs.sh`

Monitors pull requests in GitHub repositories.

## Installation

1. Clone this repository
2. Ensure you have the required dependencies installed
3. Authenticate with GitHub CLI: `gh auth login`
4. Make scripts executable: `chmod +x *.sh`

## Configuration

### Column Configuration File

Create a `columns.conf` file to customize CSV output columns:

```bash
# Example columns.conf
name=
url=
description=
language=
stars=0
forks=0
issues=0
pullRequests=0
```

### Ignore File

Create an `ignored_repos_list.txt` file to exclude specific repositories:

```bash
# Example ignored_repos_list.txt
https://github.com/user/repo1
https://github.com/user/repo2
```

## Examples

**Generate a CSV report of all non-forked repositories:**
```bash
./create_repo_list.sh --csv https://github.com/1Password
```

**Generate a CSV report of only forked repositories:**
```bash
./create_repo_list.sh --csv -f https://github.com/1Password
```

**Use custom column configuration:**
```bash
./create_repo_list.sh --csv -c my_columns.conf https://github.com/1Password
```

## License

See [LICENSE](LICENSE) file for details.
