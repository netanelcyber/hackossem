/**
 * Office Script: a self-contained language model — no API, no external model.
 *
 * Everything runs inside Excel. The script trains an n-gram language model
 * (with stupid-backoff smoothing) on text taken from a worksheet, then
 * generates new text from it and reports held-out perplexity so you can see
 * how well it actually learned.
 *
 * This is a real language model, just a small classical one: it learns
 * P(next token | previous N-1 tokens) by counting, backs off to shorter
 * contexts when a context is unseen, and samples with temperature / top-k.
 * It is not a neural transformer and will not reason — it reproduces the
 * style and vocabulary of your sheet. That is the price of zero dependencies.
 *
 * How to use:
 *   1. Excel -> Automate -> New Script, paste this file.
 *   2. Point CONFIG.textColumn at a column of text (or leave "" to use every
 *      cell of the used range).
 *   3. Run. Results land in a "Local LLM" sheet and in the console.
 *
 * No network calls, so no Automate -> Settings API permission is needed.
 */

// ---------------------------------------------------------------------------
// CONFIG
// ---------------------------------------------------------------------------

interface Config {
  /** Sheet holding the training text. "" = active sheet. */
  sourceSheet: string;
  /** Sheet the results are written to (created if missing). */
  outputSheet: string;
  /** Header name of the text column. "" = use all cells in the used range. */
  textColumn: string;
  /** true = first row of the sheet is a header row. */
  hasHeader: boolean;
  /** Model order: 3 = trigram (2 tokens of context). 2-5 is sensible. */
  order: number;
  /** "word" learns word sequences; "char" learns spelling, needs less data. */
  tokenizer: string;
  /** Fraction of documents held out to measure perplexity. 0 = train on all. */
  validationFraction: number;
  /** How many samples to generate. */
  sampleCount: number;
  /** Max tokens per generated sample. */
  sampleLength: number;
  /** <1 sharpens (more repetitive), >1 flattens (more random). */
  temperature: number;
  /** Sample only from the k most likely next tokens. 0 = no cutoff. */
  topK: number;
  /** Optional text to continue. "" = generate from the start-of-text state. */
  prompt: string;
  /** Fixed seed keeps runs reproducible; change it for different samples. */
  seed: number;
}

const CONFIG: Config = {
  sourceSheet: "",
  outputSheet: "Local LLM",
  textColumn: "",
  hasHeader: true,
  order: 3,
  tokenizer: "word",
  validationFraction: 0.1,
  sampleCount: 5,
  sampleLength: 60,
  temperature: 0.9,
  topK: 0,
  prompt: "",
  seed: 12345,
};

/** Sentinels and the context-key separator: control chars, so no real token
 *  read out of a worksheet can ever collide with them. */
const BOS = "\u0002";
const EOS = "\u0003";
const SEP = "\u0001";

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

  const documents = readDocuments(sheet);
  if (documents.length === 0) {
    throw new Error(
      `No text found in "${sheet.getName()}" — check CONFIG.textColumn.`
    );
  }

  const split = splitDocuments(documents, CONFIG.validationFraction);
  const model = trainModel(split.train, CONFIG.order, CONFIG.tokenizer);
  const rng = makeRng(CONFIG.seed);

  const samples: string[] = [];
  for (let i = 0; i < CONFIG.sampleCount; i++) {
    samples.push(generate(model, CONFIG.prompt, CONFIG.sampleLength, rng));
  }

  const trainPpl = perplexity(model, split.train);
  const valPpl =
    split.validation.length > 0 ? perplexity(model, split.validation) : -1;

  const report: string[] = [
    `Local n-gram LLM — order ${model.order}, ${model.tokenizer} tokens`,
    `Trained on ${split.train.length} documents / ${model.trainedTokens} tokens`,
    `Vocabulary: ${model.vocabSize} distinct tokens, ${model.contextCount} contexts`,
    `Train perplexity: ${trainPpl.toFixed(2)}`,
    valPpl >= 0
      ? `Validation perplexity: ${valPpl.toFixed(2)} (${split.validation.length} held-out docs)`
      : "Validation perplexity: not measured (validationFraction = 0)",
    "",
  ];
  for (let i = 0; i < samples.length; i++) {
    report.push(`--- sample ${i + 1} ---`);
    report.push(samples[i]);
    report.push("");
  }

  console.log(report.join("\n"));
  writeReport(workbook, report);
}

// ---------------------------------------------------------------------------
// Reading text out of the sheet
// ---------------------------------------------------------------------------

function readDocuments(sheet: ExcelScript.Worksheet): string[] {
  const used = sheet.getUsedRange();
  if (!used) {
    return [];
  }
  const grid: string[][] = used.getTexts();
  const startRow = CONFIG.hasHeader ? 1 : 0;
  const documents: string[] = [];

  if (CONFIG.textColumn) {
    const header = grid[0].map((h) => (h || "").trim());
    const idx = header.indexOf(CONFIG.textColumn);
    if (idx < 0) {
      throw new Error(
        `Column "${CONFIG.textColumn}" not found. Header row is: ${header.join(", ")}`
      );
    }
    for (let r = startRow; r < grid.length; r++) {
      const text = (grid[r][idx] || "").trim();
      if (text) {
        documents.push(text);
      }
    }
    return documents;
  }

  // No column named: treat every non-empty cell as its own document.
  for (let r = startRow; r < grid.length; r++) {
    for (let c = 0; c < grid[r].length; c++) {
      const text = (grid[r][c] || "").trim();
      if (text) {
        documents.push(text);
      }
    }
  }
  return documents;
}

interface DocumentSplit {
  train: string[];
  validation: string[];
}

function splitDocuments(documents: string[], fraction: number): DocumentSplit {
  if (fraction <= 0 || documents.length < 10) {
    return { train: documents, validation: [] };
  }
  // Deterministic: every Nth document is held out, so re-running on unchanged
  // data gives the same split.
  const stride = Math.max(2, Math.round(1 / fraction));
  const train: string[] = [];
  const validation: string[] = [];
  for (let i = 0; i < documents.length; i++) {
    if ((i + 1) % stride === 0) {
      validation.push(documents[i]);
    } else {
      train.push(documents[i]);
    }
  }
  return { train: train, validation: validation };
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

function tokenize(text: string, mode: string): string[] {
  if (mode === "char") {
    return text.split("");
  }
  // Word mode: words in any script (so Hebrew works) plus punctuation as
  // separate tokens; whitespace is dropped.
  const matches = text.match(/[^\s\p{P}\p{S}]+|[\p{P}\p{S}]/gu);
  return matches ? matches : [];
}

function detokenize(tokens: string[], mode: string): string {
  if (mode === "char") {
    return tokens.join("");
  }
  let out = "";
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    const isClosing = /^[\p{Pe}\p{Pf},.;:!?%]$/u.test(token);
    if (i > 0 && !isClosing) {
      out += " ";
    }
    out += token;
  }
  return out;
}

// ---------------------------------------------------------------------------
// The model
// ---------------------------------------------------------------------------

interface Model {
  order: number;
  tokenizer: string;
  /** One map per context length: context key -> (next token -> count). */
  counts: { [context: string]: { [token: string]: number } }[];
  /** One map per context length: context key -> total count. */
  totals: { [context: string]: number }[];
  vocab: { [token: string]: number };
  vocabSize: number;
  contextCount: number;
  trainedTokens: number;
}

/** Stupid-backoff discount applied per dropped context token. */
const BACKOFF = 0.4;

function trainModel(documents: string[], order: number, tokenizer: string): Model {
  if (order < 2) {
    throw new Error("CONFIG.order must be at least 2.");
  }

  const counts: { [context: string]: { [token: string]: number } }[] = [];
  const totals: { [context: string]: number }[] = [];
  for (let n = 0; n < order; n++) {
    counts.push({});
    totals.push({});
  }

  const vocab: { [token: string]: number } = {};
  let vocabSize = 0;
  let trainedTokens = 0;

  for (const doc of documents) {
    const tokens = tokenize(doc, tokenizer);
    if (tokens.length === 0) {
      continue;
    }
    // Pad so the first real token is predictable from a start-of-text context,
    // and terminate so the model learns where documents end.
    const padded: string[] = [];
    for (let i = 0; i < order - 1; i++) {
      padded.push(BOS);
    }
    for (const t of tokens) {
      padded.push(t);
    }
    padded.push(EOS);

    for (let i = order - 1; i < padded.length; i++) {
      const next = padded[i];
      if (vocab[next] === undefined) {
        vocab[next] = 0;
        vocabSize++;
      }
      vocab[next] = vocab[next] + 1;
      trainedTokens++;

      // Record this token under every context length, so backoff has
      // somewhere to land when the full context is unseen.
      for (let n = 0; n < order; n++) {
        const context = padded.slice(i - n, i).join(SEP);
        let bucket = counts[n][context];
        if (bucket === undefined) {
          bucket = {};
          counts[n][context] = bucket;
          totals[n][context] = 0;
        }
        bucket[next] = (bucket[next] || 0) + 1;
        totals[n][context] = totals[n][context] + 1;
      }
    }
  }

  let contextCount = 0;
  for (const key of Object.keys(counts[order - 1])) {
    contextCount++;
  }

  return {
    order: order,
    tokenizer: tokenizer,
    counts: counts,
    totals: totals,
    vocab: vocab,
    vocabSize: vocabSize,
    contextCount: contextCount,
    trainedTokens: trainedTokens,
  };
}

interface Distribution {
  tokens: string[];
  weights: number[];
  /** Context length actually used; order-1 means the full context matched. */
  usedOrder: number;
}

/** Stupid backoff: the longest matching context wins, shorter ones are
 *  discounted by BACKOFF per dropped token. */
function nextDistribution(model: Model, context: string[]): Distribution {
  for (let n = model.order - 1; n >= 0; n--) {
    const key = context.slice(context.length - n).join(SEP);
    const bucket = model.counts[n][key];
    if (bucket === undefined) {
      continue;
    }
    const total = model.totals[n][key];
    const discount = Math.pow(BACKOFF, model.order - 1 - n);
    const tokens: string[] = [];
    const weights: number[] = [];
    for (const token of Object.keys(bucket)) {
      tokens.push(token);
      weights.push((bucket[token] / total) * discount);
    }
    return { tokens: tokens, weights: weights, usedOrder: n };
  }
  // Unreachable in a trained model — order 0 is the unconditional distribution.
  return { tokens: [EOS], weights: [1], usedOrder: -1 };
}

function probabilityOf(model: Model, context: string[], token: string): number {
  for (let n = model.order - 1; n >= 0; n--) {
    const key = context.slice(context.length - n).join(SEP);
    const bucket = model.counts[n][key];
    if (bucket === undefined || bucket[token] === undefined) {
      continue;
    }
    const discount = Math.pow(BACKOFF, model.order - 1 - n);
    return (bucket[token] / model.totals[n][key]) * discount;
  }
  // Token never seen in training: fall back to a uniform floor so perplexity
  // stays finite instead of going to infinity on one unknown word.
  return 1 / (model.trainedTokens + model.vocabSize);
}

// ---------------------------------------------------------------------------
// Sampling
// ---------------------------------------------------------------------------

/** Small deterministic PRNG (mulberry32) — Math.random() cannot be seeded. */
function makeRng(seed: number): () => number {
  let state = seed >>> 0;
  return function (): number {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t = t ^ (t + Math.imul(t ^ (t >>> 7), t | 61));
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function generate(
  model: Model,
  prompt: string,
  maxTokens: number,
  rng: () => number
): string {
  const context: string[] = [];
  for (let i = 0; i < model.order - 1; i++) {
    context.push(BOS);
  }

  const generated: string[] = [];
  const promptTokens = prompt ? tokenize(prompt, model.tokenizer) : [];
  for (const token of promptTokens) {
    context.push(token);
    generated.push(token);
  }

  for (let i = 0; i < maxTokens; i++) {
    const dist = nextDistribution(model, context);
    const next = sample(dist, CONFIG.temperature, CONFIG.topK, rng);
    if (next === EOS) {
      break;
    }
    generated.push(next);
    context.push(next);
  }

  return detokenize(generated, model.tokenizer);
}

function sample(
  dist: Distribution,
  temperature: number,
  topK: number,
  rng: () => number
): string {
  const temp = temperature > 0 ? temperature : 0.0001;

  // Rank by weight so top-k keeps the head of the distribution.
  const order: number[] = [];
  for (let i = 0; i < dist.tokens.length; i++) {
    order.push(i);
  }
  order.sort((a, b) => dist.weights[b] - dist.weights[a]);

  const limit = topK > 0 ? Math.min(topK, order.length) : order.length;
  const scaled: number[] = [];
  let sum = 0;
  for (let i = 0; i < limit; i++) {
    const w = Math.pow(dist.weights[order[i]], 1 / temp);
    scaled.push(w);
    sum += w;
  }
  if (!(sum > 0)) {
    return dist.tokens[order[0]];
  }

  let r = rng() * sum;
  for (let i = 0; i < limit; i++) {
    r -= scaled[i];
    if (r <= 0) {
      return dist.tokens[order[i]];
    }
  }
  return dist.tokens[order[limit - 1]];
}

// ---------------------------------------------------------------------------
// Evaluation
// ---------------------------------------------------------------------------

/** Perplexity = exp(mean negative log-likelihood per token). Lower is better;
 *  a validation number far above the training number means memorisation. */
function perplexity(model: Model, documents: string[]): number {
  let logProb = 0;
  let count = 0;

  for (const doc of documents) {
    const tokens = tokenize(doc, model.tokenizer);
    if (tokens.length === 0) {
      continue;
    }
    const padded: string[] = [];
    for (let i = 0; i < model.order - 1; i++) {
      padded.push(BOS);
    }
    for (const t of tokens) {
      padded.push(t);
    }
    padded.push(EOS);

    for (let i = model.order - 1; i < padded.length; i++) {
      const context = padded.slice(i - (model.order - 1), i);
      logProb += Math.log(probabilityOf(model, context, padded[i]));
      count++;
    }
  }

  return count === 0 ? 0 : Math.exp(-logProb / count);
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

function writeReport(workbook: ExcelScript.Workbook, lines: string[]): void {
  let out = workbook.getWorksheet(CONFIG.outputSheet);
  if (!out) {
    out = workbook.addWorksheet(CONFIG.outputSheet);
  } else {
    const used = out.getUsedRange();
    if (used) {
      used.clear(ExcelScript.ClearApplyTo.all);
    }
  }

  const rows: string[][] = [];
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
