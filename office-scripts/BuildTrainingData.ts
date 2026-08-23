/**
 * Office Script: turn worksheet rows into LLM training / few-shot examples.
 *
 * Companion to AskClaudeAboutSheet.ts. Where that script asks Claude about a
 * sheet, this one treats the sheet as a labelled dataset: each row becomes one
 * training example in Messages format
 * ({ system, messages: [user, assistant] }), emitted as JSONL.
 *
 * Output goes to three places:
 *   - a "Training Data" sheet, one JSONL line per row (copy/paste or export);
 *   - the script console (full JSONL, for piping into a file);
 *   - an optional held-out split marked in a Split column.
 *
 * Note on fine-tuning: the Claude API has no fine-tuning endpoint. The JSONL
 * this produces is the Messages shape, which is what you want for
 * few-shot prompting, eval sets, and prompt-caching a fixed example block —
 * and it converts cleanly if you tune a model elsewhere. EvaluateExamples()
 * below uses Claude to grade the examples rather than to train on them.
 *
 * How to use:
 *   1. Excel -> Automate -> New Script, paste this file.
 *   2. Point CONFIG at your sheet and name the input/output columns.
 *   3. Run. Review the "Training Data" sheet before shipping the dataset.
 */

// ---------------------------------------------------------------------------
// CONFIG
// ---------------------------------------------------------------------------

interface Config {
  /** Sheet holding the labelled rows. "" = active sheet. */
  sourceSheet: string;
  /** Sheet the JSONL is written to (created if missing). */
  outputSheet: string;
  /** Header names of the columns that make up the user turn. */
  inputColumns: string[];
  /** Header name of the column holding the desired assistant turn. */
  outputColumn: string;
  /** Optional header name whose value is appended as a per-row system note. */
  systemColumn: string;
  /** System prompt shared by every example. */
  systemPrompt: string;
  /** Fraction of rows tagged "validation" instead of "train" (0 = no split). */
  validationFraction: number;
  /** Rows whose input or output cell is blank are skipped when true. */
  skipIncompleteRows: boolean;
  /** Hard cap on examples produced. */
  maxExamples: number;
}

const CONFIG: Config = {
  sourceSheet: "",
  outputSheet: "Training Data",
  inputColumns: ["Question"],
  outputColumn: "Answer",
  systemColumn: "",
  systemPrompt:
    "You are a support assistant. Answer using only the product knowledge " +
    "given to you; if you do not know, say so.",
  validationFraction: 0.2,
  skipIncompleteRows: true,
  maxExamples: 5000,
};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface TrainingMessage {
  role: string;
  content: string;
}

interface TrainingExample {
  system: string;
  messages: TrainingMessage[];
}

interface BuildResult {
  examples: TrainingExample[];
  splits: string[];
  skipped: number;
  totalRows: number;
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

function main(workbook: ExcelScript.Workbook): void {
  const sheet = CONFIG.sourceSheet
    ? workbook.getWorksheet(CONFIG.sourceSheet)
    : workbook.getActiveWorksheet();
  if (!sheet) {
    throw new Error(`Worksheet "${CONFIG.sourceSheet}" not found.`);
  }

  const result = buildExamples(sheet);
  if (result.examples.length === 0) {
    throw new Error(
      `No usable rows in "${sheet.getName()}" — check inputColumns/outputColumn ` +
        `against the header row.`
    );
  }

  const jsonl = result.examples.map((e) => JSON.stringify(e));
  console.log(jsonl.join("\n"));
  console.log(
    `\n${result.examples.length} examples from ${result.totalRows} rows ` +
      `(${result.skipped} skipped).`
  );

  writeDataset(workbook, jsonl, result.splits);
}

// ---------------------------------------------------------------------------
// Rows -> examples
// ---------------------------------------------------------------------------

function buildExamples(sheet: ExcelScript.Worksheet): BuildResult {
  const used = sheet.getUsedRange();
  if (!used) {
    throw new Error(`Worksheet "${sheet.getName()}" is empty.`);
  }

  const grid: string[][] = used.getTexts();
  const header = grid[0].map((h) => (h || "").trim());

  const inputIdx = CONFIG.inputColumns.map((name) => requireColumn(header, name));
  const outputIdx = requireColumn(header, CONFIG.outputColumn);
  const systemIdx = CONFIG.systemColumn
    ? requireColumn(header, CONFIG.systemColumn)
    : -1;

  const examples: TrainingExample[] = [];
  const splits: string[] = [];
  let skipped = 0;

  // Deterministic split: every Nth row is held out, so re-running the script
  // on unchanged data yields the same train/validation partition.
  const stride =
    CONFIG.validationFraction > 0
      ? Math.max(2, Math.round(1 / CONFIG.validationFraction))
      : 0;

  for (let r = 1; r < grid.length && examples.length < CONFIG.maxExamples; r++) {
    const row = grid[r];
    const answer = (row[outputIdx] || "").trim();
    const parts: string[] = [];
    for (let i = 0; i < inputIdx.length; i++) {
      const value = (row[inputIdx[i]] || "").trim();
      if (value) {
        parts.push(
          inputIdx.length === 1 ? value : `${header[inputIdx[i]]}: ${value}`
        );
      }
    }
    const question = parts.join("\n");

    if ((!question || !answer) && CONFIG.skipIncompleteRows) {
      skipped++;
      continue;
    }

    const note = systemIdx >= 0 ? (row[systemIdx] || "").trim() : "";
    examples.push({
      system: note ? `${CONFIG.systemPrompt}\n\n${note}` : CONFIG.systemPrompt,
      messages: [
        { role: "user", content: question },
        { role: "assistant", content: answer },
      ],
    });
    splits.push(stride > 0 && examples.length % stride === 0 ? "validation" : "train");
  }

  return {
    examples: examples,
    splits: splits,
    skipped: skipped,
    totalRows: grid.length - 1,
  };
}

function requireColumn(header: string[], name: string): number {
  const idx = header.indexOf(name);
  if (idx < 0) {
    throw new Error(
      `Column "${name}" not found. Header row is: ${header.join(", ")}`
    );
  }
  return idx;
}

// ---------------------------------------------------------------------------
// Write the dataset back into the workbook
// ---------------------------------------------------------------------------

function writeDataset(
  workbook: ExcelScript.Workbook,
  jsonl: string[],
  splits: string[]
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

  const rows: string[][] = [["Split", "JSONL"]];
  for (let i = 0; i < jsonl.length; i++) {
    rows.push([splits[i], jsonl[i]]);
  }

  out.getRangeByIndexes(0, 0, rows.length, 2).setValues(rows);
  out.getRange("A1:B1").getFormat().getFont().setBold(true);
  out.getRange("A:A").getFormat().setColumnWidth(80);
  out.getRange("B:B").getFormat().setColumnWidth(700);
  out.activate();
}
