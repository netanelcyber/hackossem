# Kerberos LLM Train

`KerberosLLMTrain.ts` is a **Node.js** (not Office Scripts) companion to the
`office-scripts/KerberosDiscovery.ts` Office Script. It consumes the source code that
the Office Script collected — from repositories that passed the malicious-content
filter — and either trains a small local model or exports fine-tuning data.

## Pipeline
1. Run the Office Script; it fills the **Source Code** sheet.
2. Export that sheet to JSONL, one object per row:
   ```json
   {"repo":"owner/name","file":"path/file.py","source":"...file text..."}
   ```
   (Columns *Repository*, *File*, *Source* → `repo`, `file`, `source`.)
3. Train or export:
   ```bash
   npm i typescript ts-node @tensorflow/tfjs-node @types/node
   # local char-level model (TensorFlow.js, CPU-friendly)
   npx ts-node ml/KerberosLLMTrain.ts --input data/source.jsonl --mode local --epochs 5
   # or produce chat-format JSONL for a hosted fine-tuning API
   npx ts-node ml/KerberosLLMTrain.ts --input data/source.jsonl --mode export
   ```

## Flags
| Flag | Default | Meaning |
|---|---|---|
| `--input` | `data/source.jsonl` | exported source rows |
| `--mode` | `local` | `local` = train GRU model, `export` = write `finetune.jsonl` |
| `--output` | `data/out` | output dir (model + vocab, or JSONL) |
| `--seq` | `128` | context window (chars) for local training |
| `--epochs` | `5` | training epochs |
| `--batch` | `64` | batch size |
| `--max` | `5000` | max source records to load |

`--mode local` saves a TF.js model + `vocab.json` under `data/out/char-model`.
`--mode export` writes `data/out/finetune.jsonl` in `{"messages":[user,assistant]}` form.

## Notes
- The char-level model is a **minimal demonstrator** (embedding → GRU → dense softmax);
  scale units/layers/seq for anything serious, or use `--mode export` + a real fine-tune.
- Only train on code you are **licensed** to use; respect each repo's license.
- Malicious-repo filtering happens upstream in the Office Script — this file trusts its input.
