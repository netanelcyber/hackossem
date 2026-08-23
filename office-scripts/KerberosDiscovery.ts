/**
 * Kerberos Discovery — Office Script for Excel (TypeScript)
 *
 * Finds GitHub repositories and Reddit subreddits/posts about Kerberos
 * and writes them into two worksheets: "GitHub Repos" and "Subreddits".
 *
 * How to use:
 *   Excel on the web -> Automate -> New Script -> paste this file -> Run.
 *
 * Notes:
 *   - External calls (fetch) work in Office Scripts, but the domains must be
 *     allowed by your tenant admin (api.github.com, www.reddit.com, oauth.reddit.com).
 *   - GitHub anonymous search is limited to ~10 requests/minute. To raise that,
 *     paste a personal access token into GITHUB_TOKEN below (read-only scope is enough).
 *     Do not commit a real token into a shared workbook.
 */

const GITHUB_TOKEN = ""; // optional: "ghp_..." for a higher rate limit
const QUERIES = ["kerberos", "kerberoasting", "krb5", "spnego", "active directory kerberos"];
const MAX_ROWS_PER_QUERY = 30;

interface GitHubRepo {
  full_name: string;
  html_url: string;
  description: string | null;
  language: string | null;
  stargazers_count: number;
  forks_count: number;
  open_issues_count: number;
  pushed_at: string;
  topics?: string[];
}

interface GitHubSearchResult {
  total_count: number;
  items: GitHubRepo[];
}

interface RedditThing<T> {
  kind: string;
  data: T;
}

interface RedditSubreddit {
  display_name_prefixed: string;
  title: string;
  public_description: string;
  subscribers: number;
  over18: boolean;
  url: string;
}

interface RedditPost {
  subreddit_name_prefixed: string;
  title: string;
  permalink: string;
  score: number;
  num_comments: number;
  created_utc: number;
  author: string;
}

interface RedditListing<T> {
  data: { children: RedditThing<T>[] };
}

async function main(workbook: ExcelScript.Workbook): Promise<void> {
  const repos = await collectRepos();
  const subs = await collectSubreddits();
  const posts = await collectPosts();

  writeTable(
    workbook,
    "GitHub Repos",
    ["Query", "Repository", "Stars", "Forks", "Open issues", "Language", "Last push", "Topics", "Description", "URL"],
    repos
  );

  writeTable(
    workbook,
    "Subreddits",
    ["Query", "Subreddit", "Subscribers", "Title", "Description", "URL"],
    subs
  );

  writeTable(
    workbook,
    "Reddit Posts",
    ["Query", "Subreddit", "Score", "Comments", "Posted (UTC)", "Author", "Title", "URL"],
    posts
  );
}

/* ---------------------------------------------------------------- GitHub */

async function collectRepos(): Promise<(string | number)[][]> {
  const rows: (string | number)[][] = [];
  const seen = new Set<string>();

  for (const query of QUERIES) {
    const url =
      "https://api.github.com/search/repositories?q=" +
      encodeURIComponent(query) +
      "&sort=stars&order=desc&per_page=" +
      MAX_ROWS_PER_QUERY;

    const headers: { [key: string]: string } = {
      "Accept": "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28"
    };
    if (GITHUB_TOKEN) {
      headers["Authorization"] = "Bearer " + GITHUB_TOKEN;
    }

    const result = await getJson<GitHubSearchResult>(url, headers);
    if (!result || !result.items) {
      continue;
    }

    for (const repo of result.items) {
      if (seen.has(repo.full_name)) {
        continue;
      }
      seen.add(repo.full_name);
      rows.push([
        query,
        repo.full_name,
        repo.stargazers_count,
        repo.forks_count,
        repo.open_issues_count,
        repo.language || "",
        (repo.pushed_at || "").substring(0, 10),
        (repo.topics || []).join(", "),
        truncate(repo.description || "", 300),
        repo.html_url
      ]);
    }
  }

  // Most-starred first across all queries.
  rows.sort((a, b) => (b[2] as number) - (a[2] as number));
  return rows;
}

/* ---------------------------------------------------------------- Reddit */

async function collectSubreddits(): Promise<(string | number)[][]> {
  const rows: (string | number)[][] = [];
  const seen = new Set<string>();

  for (const query of QUERIES) {
    const url =
      "https://www.reddit.com/subreddits/search.json?q=" +
      encodeURIComponent(query) +
      "&limit=" +
      MAX_ROWS_PER_QUERY;

    const listing = await getJson<RedditListing<RedditSubreddit>>(url, { "Accept": "application/json" });
    if (!listing || !listing.data) {
      continue;
    }

    for (const child of listing.data.children) {
      const sub = child.data;
      if (sub.over18 || seen.has(sub.display_name_prefixed)) {
        continue;
      }
      seen.add(sub.display_name_prefixed);
      rows.push([
        query,
        sub.display_name_prefixed,
        sub.subscribers || 0,
        truncate(sub.title || "", 150),
        truncate(sub.public_description || "", 300),
        "https://www.reddit.com" + sub.url
      ]);
    }
  }

  rows.sort((a, b) => (b[2] as number) - (a[2] as number));
  return rows;
}

async function collectPosts(): Promise<(string | number)[][]> {
  const rows: (string | number)[][] = [];
  const seen = new Set<string>();

  for (const query of QUERIES) {
    const url =
      "https://www.reddit.com/search.json?q=" +
      encodeURIComponent(query) +
      "&sort=relevance&t=year&limit=" +
      MAX_ROWS_PER_QUERY;

    const listing = await getJson<RedditListing<RedditPost>>(url, { "Accept": "application/json" });
    if (!listing || !listing.data) {
      continue;
    }

    for (const child of listing.data.children) {
      const post = child.data;
      if (seen.has(post.permalink)) {
        continue;
      }
      seen.add(post.permalink);
      rows.push([
        query,
        post.subreddit_name_prefixed,
        post.score,
        post.num_comments,
        new Date(post.created_utc * 1000).toISOString().substring(0, 10),
        post.author,
        truncate(post.title, 250),
        "https://www.reddit.com" + post.permalink
      ]);
    }
  }

  rows.sort((a, b) => (b[2] as number) - (a[2] as number));
  return rows;
}

/* ---------------------------------------------------------------- Helpers */

async function getJson<T>(url: string, headers: { [key: string]: string }): Promise<T | null> {
  try {
    const response = await fetch(url, { method: "GET", headers: headers });
    if (!response.ok) {
      console.log("Request failed (" + response.status + "): " + url);
      return null;
    }
    return (await response.json()) as T;
  } catch (error) {
    console.log("Request error for " + url + ": " + error);
    return null;
  }
}

function truncate(text: string, max: number): string {
  const clean = text.replace(/\s+/g, " ").trim();
  return clean.length > max ? clean.substring(0, max - 1) + "…" : clean;
}

function writeTable(
  workbook: ExcelScript.Workbook,
  sheetName: string,
  headers: string[],
  rows: (string | number)[][]
): void {
  const existing = workbook.getWorksheet(sheetName);
  if (existing) {
    existing.delete();
  }
  const sheet = workbook.addWorksheet(sheetName);

  sheet.getRangeByIndexes(0, 0, 1, headers.length).setValues([headers]);
  const headerRange = sheet.getRangeByIndexes(0, 0, 1, headers.length);
  headerRange.getFormat().getFont().setBold(true);
  headerRange.getFormat().getFill().setColor("#D9E1F2");

  if (rows.length > 0) {
    sheet.getRangeByIndexes(1, 0, rows.length, headers.length).setValues(rows);
  } else {
    sheet.getRangeByIndexes(1, 0, 1, 1).setValue("No results — check that the API domains are allowed for your tenant.");
  }

  sheet.getRangeByIndexes(0, 0, rows.length + 1, headers.length).getFormat().autofitColumns();
  sheet.getFreezePanes().freezeRows(1);

  console.log(sheetName + ": " + rows.length + " rows");
}
