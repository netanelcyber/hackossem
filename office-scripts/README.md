# Claude in Excel — Office Scripts

`AskClaudeAboutSheet.ts` reads a worksheet's used range, sends it to the Claude
Messages API as a markdown table, and writes the answer to a `Claude Output`
sheet.

## Setup

1. Excel on the web → **Automate → New Script**, paste the file contents.
2. Edit `CONFIG` (endpoint, key or proxy, model, source/output sheets) and
   `QUESTION`.
3. Excel → **Automate → Settings** → enable external API calls, and have the
   tenant admin allow the endpoint host (`api.anthropic.com`, or your proxy).

## Direct mode vs proxy mode

**Direct** (`directToAnthropic: true`) puts the API key in the script body.
Office Scripts live in OneDrive/SharePoint and are readable by anyone the file
is shared with, so use this only for personal experiments. The call is
cross-origin from the browser sandbox, hence the
`anthropic-dangerous-direct-browser-access: true` header.

**Proxy** (recommended): set `directToAnthropic: false` and point `endpoint` at
your own Azure Function / API Management / Power Automate HTTP endpoint that
holds the key server-side and forwards the body to
`https://api.anthropic.com/v1/messages` with `x-api-key` and
`anthropic-version: 2023-06-01`. The script accepts either a full Messages API
envelope or a plain text string back from the proxy.

## Notes

- Model defaults to `claude-opus-5` with adaptive thinking. Do not add
  `budget_tokens` — it is rejected with a 400 on current models.
- Cell values are read with `getTexts()` so dates and currency arrive formatted
  as the user sees them, not as serial numbers.
- `maxRows` / `maxCols` cap the payload; truncation is stated in the prompt so
  the model knows it is seeing a subset rather than silently reasoning over a
  partial sheet.
- `stop_reason` is checked for `refusal` and `max_tokens`.
