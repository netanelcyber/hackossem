/**
 * Kerberos LLM Train — Node.js + TypeScript
 *
 * Companion to the Office Script `KerberosDiscovery.ts`. That script collects the
 * source code of (non-malicious) Kerberos/AD repositories into an Excel "Source
 * Code" sheet; export that sheet to CSV or JSONL and train on it here.
 *
 * Two things this file does:
 *   1. buildDataset()  — turn collected source files into training examples.
 *   2. trainCharModel() — train a small char-level next-token model (TensorFlow.js),
 *                         OR export the data as chat-style JSONL for API fine-tuning.
 *
 * Run:
 *   npm i typescript ts-node @tensorflow/tfjs-node
 *   npx ts-node ml/KerberosLLMTrain.ts --input data/source.jsonl --mode local
 *   npx ts-node ml/KerberosLLMTrain.ts --input data/source.jsonl --mode export
 *
 * Input format (one JSON object per line — matches an exported "Source Code" row):
 *   {"repo":"owner/name","file":"path/to/file.py","source":"...file text..."}
 *
 * NOTE: only train on code you are licensed to use. Skipping malicious repos happens
 * upstream in the Office Script; this file assumes the input is already vetted.
 */

import * as fs from "fs";
import * as path from "path";

/* --------------------------------------------------------------- Types */

interface SourceRecord {
  repo: string;
  file: string;
  source: string;
}

interface TrainExample {
  /** Prompt/context shown to the model. */
  prompt: string;
  /** Target continuation the model should learn to produce. */
  completion: string;
}

interface CliOptions {
  input: string;
  mode: "local" | "export";
  output: string;
  seqLength: number;
  epochs: number;
  batchSize: number;
  maxRecords: number;
}

/* ----------------------------------------------------------------- CLI */

function parseArgs(argv: string[]): CliOptions {
  const opts: CliOptions = {
    input: "data/source.jsonl",
    mode: "local",
    output: "data/out",
    seqLength: 128,
    epochs: 5,
    batchSize: 64,
    maxRecords: 5000
  };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];
    switch (arg) {
      case "--input": opts.input = next; i++; break;
      case "--mode": opts.mode = next === "export" ? "export" : "local"; i++; break;
      case "--output": opts.output = next; i++; break;
      case "--seq": opts.seqLength = parseInt(next, 10); i++; break;
      case "--epochs": opts.epochs = parseInt(next, 10); i++; break;
      case "--batch": opts.batchSize = parseInt(next, 10); i++; break;
      case "--max": opts.maxRecords = parseInt(next, 10); i++; break;
      default: break;
    }
  }
  return opts;
}

/* ------------------------------------------------------------ Dataset */

/** Reads a JSONL file of source rows into memory (one JSON object per line). */
function readRecords(inputPath: string, maxRecords: number): SourceRecord[] {
  const records: SourceRecord[] = [];
  const lines = fs.readFileSync(inputPath, "utf8").split("\n");

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) {
      continue;
    }
    try {
      const obj = JSON.parse(trimmed) as Partial<SourceRecord>;
      if (obj.source && obj.source.length > 0) {
        records.push({
          repo: obj.repo || "unknown",
          file: obj.file || "unknown",
          source: obj.source
        });
      }
    } catch {
      // Not JSON — ignore (e.g. a stray CSV header line).
    }
    if (records.length >= maxRecords) {
      break;
    }
  }
  return records;
}

/**
 * Turns raw source files into prompt/completion examples.
 * Strategy: an instruction-style prompt naming the repo/file/language, and the
 * file body (capped) as the completion. Good for both fine-tuning and local training.
 */
function buildDataset(records: SourceRecord[], maxCompletionChars: number): TrainExample[] {
  const examples: TrainExample[] = [];
  for (const rec of records) {
    const language = languageFromPath(rec.file);
    const body = rec.source.replace(/\r\n/g, "\n").trim();
    if (body.length < 40) {
      continue; // too short to learn anything
    }
    examples.push({
      prompt:
        "Write the " + language + " source file `" + rec.file +
        "` from the Kerberos/AD project " + rec.repo + ".",
      completion: body.slice(0, maxCompletionChars)
    });
  }
  return examples;
}

function languageFromPath(file: string): string {
  const ext = path.extname(file).toLowerCase();
  const map: { [key: string]: string } = {
    ".py": "Python", ".ts": "TypeScript", ".js": "JavaScript", ".go": "Go",
    ".java": "Java", ".cs": "C#", ".c": "C", ".h": "C", ".cc": "C++",
    ".cpp": "C++", ".rb": "Ruby", ".rs": "Rust", ".sh": "Shell",
    ".ps1": "PowerShell", ".php": "PHP", ".pl": "Perl", ".md": "Markdown"
  };
  return map[ext] || "source";
}

/* --------------------------------------------------- Export for fine-tuning */

/**
 * Writes chat-format JSONL suitable for hosted fine-tuning APIs, e.g.:
 *   {"messages":[{"role":"user","content":"..."},{"role":"assistant","content":"..."}]}
 */
function exportChatJsonl(examples: TrainExample[], outputPath: string): void {
  ensureDir(outputPath);
  const out = fs.createWriteStream(outputPath, { encoding: "utf8" });
  for (const ex of examples) {
    const row = {
      messages: [
        { role: "user", content: ex.prompt },
        { role: "assistant", content: ex.completion }
      ]
    };
    out.write(JSON.stringify(row) + "\n");
  }
  out.end();
  console.log("Wrote " + examples.length + " fine-tuning examples -> " + outputPath);
}

/* ----------------------------------------- Local char-level model (TF.js) */

interface Vocab {
  charToId: { [key: string]: number };
  idToChar: string[];
}

function buildVocab(text: string): Vocab {
  const charToId: { [key: string]: number } = {};
  const idToChar: string[] = [];
  for (const ch of text) {
    if (charToId[ch] === undefined) {
      charToId[ch] = idToChar.length;
      idToChar.push(ch);
    }
  }
  return { charToId, idToChar };
}

/**
 * Trains a small GRU char-level model on the concatenated corpus.
 * Kept intentionally tiny so it runs on CPU; scale up units/layers as needed.
 */
async function trainCharModel(examples: TrainExample[], opts: CliOptions): Promise<void> {
  // Lazy import so the file still type-checks / runs in export mode without TF installed.
  let tf: typeof import("@tensorflow/tfjs-node");
  try {
    tf = await import("@tensorflow/tfjs-node");
  } catch {
    console.error("@tensorflow/tfjs-node is not installed. Run: npm i @tensorflow/tfjs-node");
    console.error("Or use --mode export to produce fine-tuning JSONL instead.");
    return;
  }

  const corpus = examples
    .map((ex) => ex.prompt + "\n" + ex.completion + "\n\n")
    .join("");
  const vocab = buildVocab(corpus);
  const vocabSize = vocab.idToChar.length;
  const seq = opts.seqLength;
  console.log("Corpus chars: " + corpus.length + ", vocab: " + vocabSize);

  if (corpus.length <= seq + 1) {
    console.error("Corpus too small for seqLength=" + seq);
    return;
  }

  // Build (X, y) windows: predict the next char from the previous `seq` chars.
  const inputs: number[][] = [];
  const labels: number[] = [];
  const stride = Math.max(1, Math.floor(seq / 2));
  for (let i = 0; i + seq < corpus.length; i += stride) {
    const window: number[] = [];
    for (let j = 0; j < seq; j++) {
      window.push(vocab.charToId[corpus[i + j]]);
    }
    inputs.push(window);
    labels.push(vocab.charToId[corpus[i + seq]]);
  }
  console.log("Training windows: " + inputs.length);

  const xs = tf.tensor2d(inputs, [inputs.length, seq], "int32");
  const ys = tf.oneHot(tf.tensor1d(labels, "int32"), vocabSize);

  const model = tf.sequential();
  model.add(tf.layers.embedding({ inputDim: vocabSize, outputDim: 64, inputLength: seq }));
  model.add(tf.layers.gru({ units: 128, returnSequences: false }));
  model.add(tf.layers.dense({ units: vocabSize, activation: "softmax" }));
  model.compile({ optimizer: tf.train.adam(0.005), loss: "categoricalCrossentropy", metrics: ["accuracy"] });
  model.summary();

  await model.fit(xs, ys, {
    epochs: opts.epochs,
    batchSize: opts.batchSize,
    validationSplit: 0.1,
    callbacks: {
      onEpochEnd: (epoch, logs) => {
        const l = logs || {};
        console.log(
          "epoch " + (epoch + 1) + "/" + opts.epochs +
          "  loss=" + fmt(l.loss) + "  acc=" + fmt(l.acc) + "  val_loss=" + fmt(l.val_loss)
        );
      }
    }
  });

  const modelDir = path.join(opts.output, "char-model");
  ensureDir(path.join(modelDir, "x"));
  await model.save("file://" + modelDir);
  fs.writeFileSync(path.join(modelDir, "vocab.json"), JSON.stringify(vocab));
  console.log("Saved model + vocab -> " + modelDir);

  xs.dispose();
  ys.dispose();
}

/* ------------------------------------------------------------- Helpers */

function fmt(v: number | undefined): string {
  return typeof v === "number" ? v.toFixed(4) : "n/a";
}

function ensureDir(filePath: string): void {
  const dir = path.dirname(filePath);
  if (dir && !fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

/* ---------------------------------------------------------------- Main */

async function main(): Promise<void> {
  const opts = parseArgs(process.argv.slice(2));
  console.log("Options: " + JSON.stringify(opts));

  if (!fs.existsSync(opts.input)) {
    console.error("Input not found: " + opts.input);
    console.error("Export the Office Script's 'Source Code' sheet to JSONL first.");
    process.exit(1);
  }

  const records = readRecords(opts.input, opts.maxRecords);
  console.log("Loaded " + records.length + " source records");

  const examples = buildDataset(records, 4000);
  console.log("Built " + examples.length + " training examples");

  if (opts.mode === "export") {
    exportChatJsonl(examples, path.join(opts.output, "finetune.jsonl"));
  } else {
    await trainCharModel(examples, opts);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
