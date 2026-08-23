# Kerberos Discovery — Office Script

`KerberosDiscovery.ts` is an Office Script (Excel on the web → Automate → New Script).
It searches GitHub and Reddit for Kerberos-related material and fills three sheets:

| Sheet | Contents |
|---|---|
| GitHub Repos | repo, stars, forks, open issues, language, last push, topics, description, URL |
| Subreddits | subreddit, subscribers, title, description, URL |
| Reddit Posts | subreddit, score, comments, date, author, title, URL |
| Source Code | repo, file path, size, line count, truncated flag, raw URL, file contents |
| URL Scan | each scanned URL, resolved repo, OK/MALICIOUS verdict, reason, stars, language, archived, last push, description |

## Scanning a fixed list of URLs
`SCAN_URLS` (top of the script) holds ~140 curated Kerberos/AD repo URLs. Each is fetched
via the GitHub API, run through the same `classifyRepo()` malicious filter, and listed on the
**URL Scan** sheet with an `OK` / `MALICIOUS` verdict. Safe repos from this list are added to the
source-download pool, so they can appear in the **Source Code** sheet too. Add or remove URLs
freely; unparseable, missing, or rate-limited entries are marked `SKIPPED`.

## Source-code download and the malicious filter
For the top `SOURCE_REPO_LIMIT` (default 5) most-starred results, the script pulls up to
`SOURCE_FILE_LIMIT` source files (default 15, max `SOURCE_MAX_BYTES` each) via the git tree API
and `raw.githubusercontent.com`, and writes their text into the **Source Code** sheet.

A repo is **skipped, not downloaded**, when `classifyRepo()` says it is unsafe:
* GitHub itself has `disabled` it (abuse / DMCA takedown), or
* its name, description or topics match `MALICIOUS_MARKERS` (malware, ransomware, stealer,
  botnet, RAT, keylogger, EDR bypass, live sample, …).

The reason appears in the **Safety** column of the GitHub Repos sheet and in the script console.
Cells are capped at 32,000 characters — longer files are truncated and flagged in the
**Truncated** column; the raw URL is always kept so the full file stays reachable.
Set `FETCH_SOURCE = false` to skip this stage entirely.

## Setup
1. Open the workbook in Excel on the web → **Automate → New Script**.
2. Paste the contents of `KerberosDiscovery.ts` and press **Run**.
3. Edit `QUERIES` at the top to change the search terms, `MAX_ROWS_PER_QUERY` for depth.
4. Optional: set `GITHUB_TOKEN` to a read-only PAT to lift the ~10 req/min anonymous limit.

## Requirements
External calls need these domains allowed by the tenant admin
(Microsoft 365 admin center → Settings → Office Scripts → allowed external domains):
`api.github.com`, `raw.githubusercontent.com`, `www.reddit.com`.
Existing sheets with those names are deleted and rebuilt on each run.
