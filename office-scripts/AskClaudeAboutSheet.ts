/**
 * Office Script: ask Claude about the data in an Excel worksheet.
 *
 * Reads the used range of a worksheet, sends it to the Claude Messages API
 * (https://docs.claude.com/en/api/messages) as markdown, and writes the answer
 * back into the workbook (an "Claude Output" sheet) plus the script console.
 *
 * How to use:
 *   1. Excel -> Automate -> New Script, paste this file.
 *   2. Fill in CONFIG below (endpoint + key, or your own proxy).
 *   3. Excel -> Automate -> Settings -> allow external API calls, and add the
 *      endpoint host to the allowed domains list for your tenant.
 *
 * Security note: an Office Script is stored in OneDrive/SharePoint and is
 * readable by anyone the file is shared with. Do NOT paste a raw Anthropic API
 * key here for anything but personal experiments — point ENDPOINT at your own
 * proxy (Azure Function / Power Automate / API Management) that holds the key
 * server-side. See PROXY MODE below.
 */

// ---------------------------------------------------------------------------
// CONFIG
// ---------------------------------------------------------------------------

interface Config {
  /** Direct Anthropic endpoint, or your own proxy URL. */
  endpoint: string;
  /** API key for direct mode. Leave "" when using a proxy that injects it. */
  apiKey: string;
  /** true = talking straight to api.anthropic.com; false = your proxy. */
  directToAnthropic: boolean;
  model: string;
  maxTokens: number;
  /** Worksheet to read. "" = the active sheet. */
  sourceSheet: string;
  /** Worksheet the answer is written to (created if missing). */
  outputSheet: string;
  /** Safety cap so a huge sheet does not blow up the request. */
  maxRows: number;
  maxCols: number;
}

const CONFIG: Config = {
  endpoint: "https://api.anthropic.com/v1/messages",
  apiKey: "",                       // <-- direct mode only
  directToAnthropic: true,
  model: "claude-opus-5",
  maxTokens: 4000,
  sourceSheet: "",
  outputSheet: "Claude Output",
  maxRows: 500,
  maxCols: 40,
};

/** The question asked about the sheet. Edit freely. */
const QUESTION = `Analyse this worksheet data and give me:
1. A one-paragraph summary of what the data represents.
2. The three most notable patterns, outliers or data-quality problems.
3. Any concrete follow-up analysis you would recommend.
Answer in plain text, no markdown headings.`;

const SYSTEM_PROMPT =
  "You are a careful data analyst embedded in Excel. You are given the contents " +
  "of a worksheet as a markdown table. Ground every claim in the data given; if " +
  "the data is insufficient to answer, say so explicitly rather than guessing.";

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

async function main(workbook: ExcelScript.Workbook): Promise<void> {
  const sheet = CONFIG.sourceSheet
    ? workbook.getWorksheet(CONFIG.sourceSheet)
    : workbook.getActiveWorksheet();
  if (!sheet) {
    throw new Error(`Worksheet "${CONFIG.sourceSheet}" not found.`);
  }

  const table = readSheetAsMarkdown(sheet);
  if (!table) {
    throw new Error(`Worksheet "${sheet.getName()}" has no data.`);
  }

  const answer = await askClaude(
    `Worksheet: ${sheet.getName()}\n\n${table}\n\n${QUESTION}`
  );

  console.log(answer);
  writeAnswer(workbook, sheet.getName(), answer);
}

// ---------------------------------------------------------------------------
// Worksheet -> markdown
// ---------------------------------------------------------------------------

function readSheetAsMarkdown(sheet: ExcelScript.Worksheet): string {
  const used = sheet.getUsedRange();
  if (!used) {
    return "";
  }

  // getTexts() gives the displayed strings, so dates and currency arrive
  // formatted the way the user sees them rather than as serial numbers.
  const values: string[][] = used.getTexts();
  const rows = Math.min(values.length, CONFIG.maxRows);
  const cols = Math.min(values[0].length, CONFIG.maxCols);

  const lines: string[] = [];
  for (let r = 0; r < rows; r++) {
    const cells: string[] = [];
    for (let c = 0; c < cols; c++) {
      cells.push(escapeCell(values[r][c]));
    }
    lines.push(`| ${cells.join(" | ")} |`);
    if (r === 0) {
      lines.push(`| ${cells.map(() => "---").join(" | ")} |`);
    }
  }

  if (values.length > rows || values[0].length > cols) {
    lines.push(
      `\n(Truncated: showing ${rows} of ${values.length} rows and ` +
        `${cols} of ${values[0].length} columns.)`
    );
  }
  return lines.join("\n");
}

function escapeCell(text: string): string {
  return (text || "").replace(/\|/g, "\\|").replace(/\r?\n/g, " ");
}

// ---------------------------------------------------------------------------
// Claude Messages API
// ---------------------------------------------------------------------------

async function askClaude(prompt: string): Promise<string> {
  const body = {
    model: CONFIG.model,
    max_tokens: CONFIG.maxTokens,
    system: SYSTEM_PROMPT,
    // Adaptive thinking: Claude decides how much to reason. Do not send
    // budget_tokens — it is rejected with a 400 on Opus 5 / Sonnet 5.
    thinking: { type: "adaptive" },
    messages: [{ role: "user", content: prompt }],
  };

  const headers: { [name: string]: string } = {
    "content-type": "application/json",
  };
  if (CONFIG.directToAnthropic) {
    if (!CONFIG.apiKey) {
      throw new Error("CONFIG.apiKey is empty — set it, or point CONFIG.endpoint at a proxy.");
    }
    headers["x-api-key"] = CONFIG.apiKey;
    headers["anthropic-version"] = "2023-06-01";
    // Office Scripts runs in a browser sandbox, so the direct call is a
    // cross-origin request and needs this opt-in header.
    headers["anthropic-dangerous-direct-browser-access"] = "true";
  }

  const response = await fetch(CONFIG.endpoint, {
    method: "POST",
    headers: headers,
    body: JSON.stringify(body),
  });

  const raw = await response.text();
  if (!response.ok) {
    throw new Error(`Claude API ${response.status}: ${raw}`);
  }

  // Proxy mode may return a plain string instead of a Messages API envelope.
  let payload: ClaudeMessage;
  try {
    payload = JSON.parse(raw) as ClaudeMessage;
  } catch (e) {
    return raw;
  }
  if (!payload.content) {
    return raw;
  }

  if (payload.stop_reason === "refusal") {
    const detail = payload.stop_details ? payload.stop_details.explanation : "";
    return `Claude declined this request. ${detail || ""}`.trim();
  }

  // content is a list of blocks (thinking, text, ...). Keep only the text.
  const text = payload.content
    .filter((b) => b.type === "text" && b.text)
    .map((b) => b.text)
    .join("\n");

  if (payload.stop_reason === "max_tokens") {
    return `${text}\n\n[Truncated at max_tokens — raise CONFIG.maxTokens.]`;
  }
  return text || "(no text returned)";
}

interface ClaudeContentBlock {
  type: string;
  text?: string;
}

interface ClaudeStopDetails {
  type: string;
  category?: string;
  explanation?: string;
}

interface ClaudeMessage {
  content: ClaudeContentBlock[];
  stop_reason?: string;
  stop_details?: ClaudeStopDetails;
}

// ---------------------------------------------------------------------------
// Write the answer back into the workbook
// ---------------------------------------------------------------------------

function writeAnswer(
  workbook: ExcelScript.Workbook,
  sourceName: string,
  answer: string
): void {
  let out = workbook.getWorksheet(CONFIG.outputSheet);
  if (!out) {
    out = workbook.addWorksheet(CONFIG.outputSheet);
  } else {
    const used = out.getUsedRange();
    if (used) {
      used.clear(ExcelScript.ClearApplyTo.all);
    }
  }

  const stamp = new Date().toISOString();
  const lines = answer.split(/\r?\n/);
  const rows: string[][] = [
    [`Claude (${CONFIG.model}) on "${sourceName}" — ${stamp}`],
    [""],
  ];
  for (const line of lines) {
    rows.push([line]);
  }

  out.getRangeByIndexes(0, 0, rows.length, 1).setValues(rows);
  out.getRange("A1").getFormat().getFont().setBold(true);
  const col = out.getRange("A:A").getFormat();
  col.setColumnWidth(700);
  col.setWrapText(true);
  out.activate();
}
