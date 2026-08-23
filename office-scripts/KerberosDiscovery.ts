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

// Optional GitHub token for a higher rate limit (5,000/hr vs ~60/hr).
// Paste your token at run time only — do NOT commit a real token to this repo.
const GITHUB_TOKEN = "YOUR_GITHUB_TOKEN_HERE"; // e.g. a fine-grained, read-only, public-repos token
// Fixed list of repository URLs to scan directly (in addition to the search
// queries above). Each is fetched, classified for malicious markers, and — when
// safe — has its source downloaded into the "Source Code" sheet.
const SCAN_URLS: string[] = [
  "https://github.com/fortra/impacket",
  "https://github.com/Hackplayers/evil-winrm",
  "https://github.com/GhostPack/Rubeus",
  "https://github.com/ropnop/kerbrute",
  "https://github.com/odedshimon/BruteShark",
  "https://github.com/lgandx/PCredz",
  "https://github.com/lefayjey/linWinPwn",
  "https://github.com/dromara/MaxKey",
  "https://github.com/dirkjanm/krbrelayx",
  "https://github.com/gentilkiwi/kekeo",
  "https://github.com/jupyter-incubator/sparkmagic",
  "https://github.com/Qianlitp/WatchAD",
  "https://github.com/freeipa/freeipa",
  "https://github.com/NotMedic/NetNTLMtoSilverTicket",
  "https://github.com/cube0x0/KrbRelay",
  "https://github.com/dirkjanm/PKINITtools",
  "https://github.com/realguoshuai/hadoop_study",
  "https://github.com/OpenIdentityPlatform/OpenAM",
  "https://github.com/MorDavid/NetworkHound",
  "https://github.com/trustedsec/Titanis",
  "https://github.com/jcmturner/gokrb5",
  "https://github.com/ShutdownRepo/targetedKerberoast",
  "https://github.com/tothi/rbcd-attack",
  "https://github.com/CICADA8-Research/RemoteKrbRelay",
  "https://github.com/drak3hft7/Cheat-Sheet---Active-Directory",
  "https://github.com/RalfHacker/Kerbeus-BOF",
  "https://github.com/marcosValle/awesome-windows-red-team",
  "https://github.com/ADScanPro/adscan",
  "https://github.com/krb5/krb5",
  "https://github.com/dotnet/Kerberos.NET",
  "https://github.com/wh0amitz/KRBUACBypass",
  "https://github.com/Waffle/waffle",
  "https://github.com/optiv/Talon",
  "https://github.com/skelsec/kerberoast",
  "https://github.com/trustedsec/orpheus",
  "https://github.com/heimdal/heimdal",
  "https://github.com/zszszszsz/.config",
  "https://github.com/capture0x/AdStrike",
  "https://github.com/stnoonan/spnego-http-auth-nginx-module",
  "https://github.com/Tw1sm/RITM",
  "https://github.com/GhostPack/SharpRoast",
  "https://github.com/TheManticoreProject/manticore-delegations",
  "https://github.com/tranquilit/OpenRSAT",
  "https://github.com/HarmJ0y/ASREPRoast",
  "https://github.com/Luct0r/KerberOPSEC",
  "https://github.com/curtishoughton/Penetration-Testing-Cheat-Sheet",
  "https://github.com/oiweiwei/go-msrpc",
  "https://github.com/salyh/elasticsearch-security-plugin",
  "https://github.com/emrekybs/AD-AssessmentKit",
  "https://github.com/Don-No7/Hack-SQL",
  "https://github.com/aws/credentials-fetcher",
  "https://github.com/pythongssapi/python-gssapi",
  "https://github.com/CNTRUN/Termux-command",
  "https://github.com/jalvarezz13/Krb5RoastParser",
  "https://github.com/gssapi/mod_auth_gssapi",
  "https://github.com/NetSPI/AD-PathFinder",
  "https://github.com/icedracon/adhammer",
  "https://github.com/salyh/elastic-defender",
  "https://github.com/Dr4ks/PJPT_CheatSheet",
  "https://github.com/Lexus89/SharpPack",
  "https://github.com/JVBotelho/skewrun",
  "https://github.com/skelsec/PyKerberoast",
  "https://github.com/jfjallid/kerbtool",
  "https://github.com/zorn96/ms_active_directory",
  "https://github.com/jborean93/pyspnego",
  "https://github.com/latchset/kdcproxy",
  "https://github.com/msktutil/msktutil",
  "https://github.com/OneBitSoftware/Microsoft.AspNetCore.Authentication.ActiveDirectory",
  "https://github.com/gssapi/gssproxy",
  "https://github.com/NeosIT/active-directory-integration2",
  "https://github.com/gcavalcante8808/docker-krb5-server",
  "https://github.com/p0dalirius/GhostSPN",
  "https://github.com/BabyJ723/blast-ON",
  "https://github.com/Retrospected/kerbmon",
  "https://github.com/h4rithd/PrecompiledBinaries",
  "https://github.com/wolfSSL/osp",
  "https://github.com/its-a-feature/KeytabParser",
  "https://github.com/adaltas/node-krb5",
  "https://github.com/jonaslejon/ad-autopwn",
  "https://github.com/bringhurst/nginx-mod-auth-kerb",
  "https://github.com/edseymour/kinit-sidecar",
  "https://github.com/blacklanternsecurity/Convert-Invoke-Kerberoast",
  "https://github.com/quasoft/websspi",
  "https://github.com/garvitv14/snowcorp-lab",
  "https://github.com/Blumira/Kerberoast-Detection",
  "https://github.com/slyd0g/SharpRoast-Parser",
  "https://github.com/dpotapov/go-spnego",
  "https://github.com/Kili69/TierLevelIsolation",
  "https://github.com/Get-ADPen/thc-Kerbhuntr",
  "https://github.com/thehackersbrain/certificate-of-compromise",
  "https://github.com/froschi/chef-cookbook-libgssapi-krb5",
  "https://github.com/BetaHydri/RC4-ADAssessment",
  "https://github.com/latchset/libverto",
  "https://github.com/kwart/spnego-demo",
  "https://github.com/ricardojoserf/SSSD-creds",
  "https://github.com/mr-r3b00t/kerberoast_audit",
  "https://github.com/jborean93/pykrb5",
  "https://github.com/Get-ADPen/CrackMapKeros",
  "https://github.com/vpxuser/centralized-system-pentest-cheat-sheet",
  "https://github.com/rra/pam-krb5",
  "https://github.com/whoamins/SPN-Honeypot",
  "https://github.com/mikma/egssapi",
  "https://github.com/sleeper/rack-auth-krb",
  "https://github.com/tresata/akka-http-spnego",
  "https://github.com/krb5/krb5-anonsvn",
  "https://github.com/atomic-penguin/cookbook-krb5",
  "https://github.com/phihos/docker-sssd-krb5-ldap",
  "https://github.com/codecentric/elasticsearch-shield-kerberos-realm",
  "https://github.com/froz42/kerbernetes",
  "https://github.com/BroadbentT/ROGUE-AGENT",
  "https://github.com/estokes/cross-krb5",
  "https://github.com/timfel/krb5-auth",
  "https://github.com/codelibs/spnego",
  "https://github.com/Get-ADPen/ExchangeBeros",
  "https://github.com/php/pecl-authentication-krb5",
  "https://github.com/square/pam_krb5_ccache",
  "https://github.com/chapeltech/krb5_admin",
  "https://github.com/EleotleCram/jetty-spnego-demo",
  "https://github.com/novakov-alexey-zz/http4s-spnego",
  "https://github.com/PwnDexter/Rubeus-to-Hashcat",
  "https://github.com/veldrane/krb5proxy",
  "https://github.com/Gembal77/script-hack",
  "https://github.com/csandker/spnegoDown",
  "https://github.com/ypb/ngx_http_auth_sso_module",
  "https://github.com/cumakurt/adar",
  "https://github.com/tmenochet/PowerSpray",
  "https://github.com/theSaarco/krb5-helm",
  "https://github.com/go-krb5/krb5",
  "https://github.com/mermehr/ad-reaper",
  "https://github.com/tresata/spray-spnego",
  "https://github.com/m4dc4p/rubysspi",
  "https://github.com/cbev0x/SteadFAST",
  "https://github.com/montag451/spnego-proxy",
  "https://github.com/snyk/go-httpauth",
  "https://github.com/EleotleCram/spnego.sf.net-fork",
  "https://github.com/plur1bu5/TrustFull",
  "https://github.com/fclmman/alpine-nginx-spnego",
  "https://github.com/bodaay/SimpleAuth",
  "https://github.com/michael-o/tomcatspnegoad",
  "https://github.com/k4sth4/Kerberos",
  "https://github.com/bloomberg/Catalyst-Authentication-Credential-GSSAPI"
];

const QUERIES = ["kerberos", "kerberoasting", "krb5", "spnego", "active directory kerberos"];
const MAX_ROWS_PER_QUERY = 30;

// Source-code download settings.
const FETCH_SOURCE = true;          // set false to skip the "Source Code" sheet
const SOURCE_REPO_LIMIT = 5;        // how many top-starred safe repos to download from
const SOURCE_FILE_LIMIT = 15;       // max files per repo
const SOURCE_MAX_BYTES = 60000;     // skip files larger than this
const REQUEST_DELAY_MS = 1500;      // pause before each HTTP request to avoid GitHub rate limits
const SCAN_MAX_ORDER = 3;           // crawl depth: SCAN_URLS = order 1, README-linked repos = 2, their links = 3
const SCAN_LINKS_PER_REPO = 10;     // max new repos to follow from each repo's README
const SCAN_TOTAL_LIMIT = 400;       // hard cap on repos visited across the whole crawl
const CELL_CHAR_LIMIT = 32000;      // Excel hard limit is 32767 characters per cell
const MAX_RETRIES = 3;              // retries on thrown network errors ("Failed to fetch")
const RETRY_BACKOFF_MS = 2000;      // base backoff between retries (doubles each attempt)

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

  const scan = await collectUrlScan();
  writeTable(
    workbook,
    "URL Scan",
    ["Order", "Found via", "Repository", "Safety", "Reason", "Stars", "Language", "Archived", "Last push", "Description"],
    scan
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

/* -------------------------------------------------------------- URL scan */

/** Parses "https://github.com/owner/repo(...)" into "owner/repo". */
function parseRepoUrl(url: string): string | null {
  const match = url.match(/github\.com\/([^\/#?]+)\/([^\/#?]+)/i);
  if (!match) {
    return null;
  }
  const owner = match[1].trim();
  const repo = match[2].replace(/\.git$/i, "").replace(/\/+$/, "").trim();
  if (!owner || !repo) {
    return null;
  }
  return owner + "/" + repo;
}

/**
 * Fetches each SCAN_URLS repo, classifies it, and — when safe — adds it to the
 * pool that collectSource() downloads from. Returns rows for the "URL Scan" sheet.
 */
/**
 * Breadth-first crawl of the repository link graph up to SCAN_MAX_ORDER.
 *
 * Order 1 = the SCAN_URLS seeds. For each safe repo, github.com/owner/repo links
 * found in its README become the next order, and so on. Every visited repo is
 * classified; safe ones are added to the source-download pool. Malicious repos
 * are recorded but their links are NOT followed.
 */
async function collectUrlScan(): Promise<(string | number)[][]> {
  const rows: (string | number)[][] = [];
  const inSource = new Set<string>(discoveredRepos.map((r) => r.full_name.toLowerCase()));
  const visited = new Set<string>();

  // Queue seeded with the fixed URLs at order 1.
  let frontier: { fullName: string; via: string }[] = [];
  for (const url of SCAN_URLS) {
    const fullName = parseRepoUrl(url);
    if (fullName && !visited.has(fullName.toLowerCase())) {
      visited.add(fullName.toLowerCase());
      frontier.push({ fullName: fullName, via: "seed" });
    } else if (!fullName) {
      rows.push([1, "seed", url, "SKIPPED", "unparseable URL", "", "", "", "", ""]);
    }
  }

  for (let order = 1; order <= SCAN_MAX_ORDER && frontier.length > 0; order++) {
    const next: { fullName: string; via: string }[] = [];

    for (const item of frontier) {
      if (visited.size > SCAN_TOTAL_LIMIT) {
        break;
      }

      const repo = await getJson<GitHubRepo>(
        "https://api.github.com/repos/" + item.fullName,
        githubHeaders()
      );

      if (!repo || !repo.full_name) {
        rows.push([order, item.via, item.fullName, "SKIPPED", "not found or rate-limited", "", "", "", "", ""]);
        continue;
      }

      const verdict = classifyRepo(repo);
      rows.push([
        order,
        item.via,
        repo.full_name,
        verdict.safe ? "OK" : "MALICIOUS",
        verdict.safe ? "safe to fetch" : verdict.reason,
        repo.stargazers_count,
        repo.language || "",
        repo.archived ? "yes" : "no",
        (repo.pushed_at || "").substring(0, 10),
        truncate(repo.description || "", 300)
      ]);

      if (!verdict.safe) {
        continue; // never follow links out of a repo flagged malicious
      }

      if (!inSource.has(repo.full_name.toLowerCase())) {
        inSource.add(repo.full_name.toLowerCase());
        discoveredRepos.push(repo);
      }

      // Expand to the next order (skip when the next order would exceed the max).
      if (order < SCAN_MAX_ORDER) {
        const links = await discoverLinkedRepos(repo);
        let added = 0;
        for (const linked of links) {
          const key = linked.toLowerCase();
          if (visited.has(key) || visited.size > SCAN_TOTAL_LIMIT) {
            continue;
          }
          visited.add(key);
          next.push({ fullName: linked, via: repo.full_name });
          added++;
          if (added >= SCAN_LINKS_PER_REPO) {
            break;
          }
        }
      }
    }

    frontier = next;
  }

  return rows;
}

/** Fetches a repo's README and extracts distinct github.com/owner/repo links (self excluded). */
async function discoverLinkedRepos(repo: GitHubRepo): Promise<string[]> {
  const meta = await getJson<GitHubContentEntry>(
    "https://api.github.com/repos/" + repo.full_name + "/readme",
    githubHeaders()
  );
  if (!meta || !meta.download_url) {
    return [];
  }

  const text = await getText(meta.download_url);
  if (text === null) {
    return [];
  }

  const found: string[] = [];
  const seen = new Set<string>();
  const self = repo.full_name.toLowerCase();
  const regex = /github\.com\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)/g;

  let match = regex.exec(text);
  while (match !== null) {
    const owner = match[1];
    let name = match[2].replace(/\.git$/i, "");
    // Drop obvious non-repo owners.
    if (owner.toLowerCase() !== "sponsors" && owner.toLowerCase() !== "topics" && name) {
      const full = owner + "/" + name;
      const key = full.toLowerCase();
      if (key !== self && !seen.has(key)) {
        seen.add(key);
        found.push(full);
      }
    }
    match = regex.exec(text);
  }

  return found;
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
        branch + "/" + entry.path.split("/").map((seg) => encodeURIComponent(seg)).join("/")
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

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => setTimeout(resolve, ms));
}

async function getJson<T>(url: string, headers: { [key: string]: string }): Promise<T | null> {
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      await sleep(REQUEST_DELAY_MS);
      const response = await fetch(url, { method: "GET", headers: headers });
      if (!response.ok) {
        // HTTP status errors (404/403/…) are not retried — they won't change on a retry.
        console.log("Request failed (" + response.status + "): " + url);
        return null;
      }
      return (await response.json()) as T;
    } catch (error) {
      // Thrown errors ("Failed to fetch") are usually transient — retry with backoff.
      const last = attempt === MAX_RETRIES;
      console.log(
        "Request error for " + url + " (attempt " + (attempt + 1) + "/" + (MAX_RETRIES + 1) +
        "): " + error + (last ? " — giving up" : " — retrying")
      );
      if (last) {
        return null;
      }
      await sleep(RETRY_BACKOFF_MS * Math.pow(2, attempt));
    }
  }
  return null;
}

function githubHeaders(): { [key: string]: string } {
  const headers: { [key: string]: string } = {
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28"
  };
  if (GITHUB_TOKEN && GITHUB_TOKEN !== "YOUR_GITHUB_TOKEN_HERE") {
    headers["Authorization"] = "Bearer " + GITHUB_TOKEN;
  }
  return headers;
}

async function getText(url: string): Promise<string | null> {
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      await sleep(REQUEST_DELAY_MS);
      const response = await fetch(url, { method: "GET" });
      if (!response.ok) {
        console.log("Download failed (" + response.status + "): " + url);
        return null;
      }
      return await response.text();
    } catch (error) {
      const last = attempt === MAX_RETRIES;
      console.log(
        "Download error for " + url + " (attempt " + (attempt + 1) + "/" + (MAX_RETRIES + 1) +
        "): " + error + (last ? " — giving up" : " — retrying")
      );
      if (last) {
        return null;
      }
      await sleep(RETRY_BACKOFF_MS * Math.pow(2, attempt));
    }
  }
  return null;
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
