/**
 * Kerberos Discovery — Office Script for Excel (TypeScript)
 *
 * Finds GitHub repositories and Reddit subreddits/posts about Kerberos,
 * writes them into worksheets, and downloads the source code of the top
 * repositories — skipping any repo that looks malicious or was flagged/
 * disabled by GitHub.
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

// Source-code download settings.
const FETCH_SOURCE = true;          // set false to skip the "Source Code" sheet
const SOURCE_REPO_LIMIT = 5;        // how many top-starred safe repos to download from
const SOURCE_FILE_LIMIT = 15;       // max files per repo
const SOURCE_MAX_BYTES = 60000;     // skip files larger than this
const CELL_CHAR_LIMIT = 32000;      // Excel hard limit is 32767 characters per cell

// Extensions worth pulling as "source".
const SOURCE_EXTENSIONS = [
  ".c", ".h", ".cc", ".cpp", ".cs", ".go", ".java", ".js", ".ts", ".py",
  ".rb", ".rs", ".sh", ".ps1", ".pl", ".php", ".md", ".conf", ".yaml", ".yml"
];

// A repo whose metadata matches any of these is treated as malicious and is
// NOT downloaded. GitHub's own flags (archived / disabled / DMCA takedown)
// are checked separately in classifyRepo().
const MALICIOUS_MARKERS = [
  "malware", "ransomware", "botnet", "stealer", "infostealer", "trojan",
  "rootkit", "keylogger", "backdoor", "worm", "virus", "cryptolocker",
  "c2 framework", "command and control", "rat builder", "remote access trojan",
  "crypter", "obfuscator for av", "av evasion", "edr bypass", "exploit kit",
  "0day dump", "malicious sample", "live sample", "do not run"
];

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
  archived?: boolean;
  disabled?: boolean;
  fork?: boolean;
  license?: { spdx_id: string } | null;
  default_branch?: string;
}

interface GitHubContentEntry {
  path: string;
  type: string;
  size: number;
  download_url: string | null;
}

interface GitHubTreeEntry {
  path: string;
  type: string;
  size?: number;
}

interface GitHubTree {
  tree: GitHubTreeEntry[];
  truncated: boolean;
}

interface RepoVerdict {
  safe: boolean;
  reason: string;
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

// Filled by collectRepos(), consumed by collectSource().
let discoveredRepos: GitHubRepo[] = [];

async function main(workbook: ExcelScript.Workbook): Promise<void> {
  const repos = await collectRepos();
  const subs = await collectSubreddits();
  const posts = await collectPosts();

  writeTable(
    workbook,
    "GitHub Repos",
    ["Query", "Repository", "Stars", "Forks", "Open issues", "Language", "Last push", "Safety", "Topics", "Description", "URL"],
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

  if (FETCH_SOURCE) {
    const source = await collectSource();
    writeTable(
      workbook,
      "Source Code",
      ["Repository", "File", "Size (bytes)", "Lines", "Truncated", "Raw URL", "Source"],
      source
    );
  }
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

    const result = await getJson<GitHubSearchResult>(url, githubHeaders());
    if (!result || !result.items) {
      continue;
    }

    for (const repo of result.items) {
      if (seen.has(repo.full_name)) {
        continue;
      }
      seen.add(repo.full_name);
      discoveredRepos.push(repo);
      const verdict = classifyRepo(repo);
      rows.push([
        query,
        repo.full_name,
        repo.stargazers_count,
        repo.forks_count,
        repo.open_issues_count,
        repo.language || "",
        (repo.pushed_at || "").substring(0, 10),
        verdict.safe ? "OK" : "SKIPPED — " + verdict.reason,
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

/* ----------------------------------------------------------- Source code */

/**
 * Decides whether a repository's source may be downloaded.
 * Anything GitHub itself flagged (disabled / DMCA takedown) and anything whose
 * name, description or topics advertise malware is refused.
 */
function classifyRepo(repo: GitHubRepo): RepoVerdict {
  if (repo.disabled) {
    return { safe: false, reason: "disabled by GitHub" };
  }

  const haystack = (
    repo.full_name + " " + (repo.description || "") + " " + (repo.topics || []).join(" ")
  ).toLowerCase();

  for (const marker of MALICIOUS_MARKERS) {
    if (haystack.indexOf(marker) >= 0) {
      return { safe: false, reason: "marked as malicious (\"" + marker + "\")" };
    }
  }

  return { safe: true, reason: "" };
}

async function collectSource(): Promise<(string | number)[][]> {
  const rows: (string | number)[][] = [];

  const candidates = discoveredRepos
    .slice()
    .sort((a, b) => b.stargazers_count - a.stargazers_count)
    .filter((repo) => {
      const verdict = classifyRepo(repo);
      if (!verdict.safe) {
        console.log("Skipping source for " + repo.full_name + ": " + verdict.reason);
      }
      return verdict.safe;
    })
    .slice(0, SOURCE_REPO_LIMIT);

  for (const repo of candidates) {
    const files = await listSourceFiles(repo);
    for (const file of files) {
      if (!file.download_url) {
        continue;
      }
      const text = await getText(file.download_url);
      if (text === null) {
        continue;
      }
      const truncated = text.length > CELL_CHAR_LIMIT;
      rows.push([
        repo.full_name,
        file.path,
        file.size,
        text.split("\n").length,
        truncated ? "yes" : "no",
        file.download_url,
        truncated ? text.substring(0, CELL_CHAR_LIMIT) : text
      ]);
    }
  }

  return rows;
}

/** Lists downloadable source files for a repo, newest tree first, root files preferred. */
async function listSourceFiles(repo: GitHubRepo): Promise<GitHubContentEntry[]> {
  const branch = repo.default_branch || "main";
  const treeUrl =
    "https://api.github.com/repos/" + repo.full_name + "/git/trees/" +
    encodeURIComponent(branch) + "?recursive=1";

  const tree = await getJson<GitHubTree>(treeUrl, githubHeaders());
  if (!tree || !tree.tree) {
    return [];
  }

  const picked: GitHubContentEntry[] = [];
  for (const entry of tree.tree) {
    if (entry.type !== "blob" || !hasSourceExtension(entry.path)) {
      continue;
    }
    const size = entry.size || 0;
    if (size === 0 || size > SOURCE_MAX_BYTES) {
      continue;
    }
    picked.push({
      path: entry.path,
      type: entry.type,
      size: size,
      download_url:
        "https://raw.githubusercontent.com/" + repo.full_name + "/" +
        branch + "/" + entry.path.split("/").map(encodeURIComponent).join("/")
    });
    if (picked.length >= SOURCE_FILE_LIMIT) {
      break;
    }
  }

  return picked;
}

function hasSourceExtension(path: string): boolean {
  const lower = path.toLowerCase();
  for (const ext of SOURCE_EXTENSIONS) {
    if (lower.length > ext.length && lower.substring(lower.length - ext.length) === ext) {
      return true;
    }
  }
  return false;
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

function githubHeaders(): { [key: string]: string } {
  const headers: { [key: string]: string } = {
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28"
  };
  if (GITHUB_TOKEN) {
    headers["Authorization"] = "Bearer " + GITHUB_TOKEN;
  }
  return headers;
}

async function getText(url: string): Promise<string | null> {
  try {
    const response = await fetch(url, { method: "GET" });
    if (!response.ok) {
      console.log("Download failed (" + response.status + "): " + url);
      return null;
    }
    return await response.text();
  } catch (error) {
    console.log("Download error for " + url + ": " + error);
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
