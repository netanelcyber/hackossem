# Kerberos Discovery — Office Script

`KerberosDiscovery.ts` is an Office Script (Excel on the web → Automate → New Script).
It searches GitHub and Reddit for Kerberos-related material and fills three sheets:

| Sheet | Contents |
|---|---|
| GitHub Repos | repo, stars, forks, open issues, language, last push, topics, description, URL |
| Subreddits | subreddit, subscribers, title, description, URL |
| Reddit Posts | subreddit, score, comments, date, author, title, URL |

## Setup
1. Open the workbook in Excel on the web → **Automate → New Script**.
2. Paste the contents of `KerberosDiscovery.ts` and press **Run**.
3. Edit `QUERIES` at the top to change the search terms, `MAX_ROWS_PER_QUERY` for depth.
4. Optional: set `GITHUB_TOKEN` to a read-only PAT to lift the ~10 req/min anonymous limit.

## Requirements
External calls need these domains allowed by the tenant admin
(Microsoft 365 admin center → Settings → Office Scripts → allowed external domains):
`api.github.com`, `www.reddit.com`.
Existing sheets with those names are deleted and rebuilt on each run.
