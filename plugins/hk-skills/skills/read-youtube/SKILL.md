---
name: read-youtube
description: Analyse YouTube videos and Shorts. Auto-triggers when user shares any youtube.com, youtu.be, or YouTube Shorts URL. Always produces: full verbatim transcript with timestamps + key insights + verbatim quotes per insight, rendered as a styled HTML file opened in the browser. No flags needed — this is the default output every time.
---

# Read YouTube

Produce a full analysis of any YouTube video: verbatim transcript, key insights, and supporting quotes — rendered as a styled HTML report opened in the browser.

## Arguments

$ARGUMENTS

(If $ARGUMENTS contains a YouTube URL, use it. Otherwise extract the URL from the user's message.)

---

## Pipeline

### Step 1 — Setup

```bash
source ~/.claude/.env
```

Check `GEMINI_API_KEY` is set. If missing, tell user to get one at https://aistudio.google.com/apikey and stop.

Check yt-dlp is available:
```bash
python3 -m yt_dlp --version 2>/dev/null || echo "missing"
```
If missing: `pip3 install yt-dlp --user -q`

### Step 2 — Get video metadata

```bash
python3 -m yt_dlp --print "%(title)s|%(duration_string)s|%(uploader)s|%(channel)s" "YOUTUBE_URL" 2>/dev/null | grep -v "urllib3\|NotOpenSSL\|Deprecated\|warnings"
```

Save: title, duration, uploader. Create a project slug from the title (lowercase, hyphens, max 40 chars).

Set output dir: `~/Projects/youtube-transcripts/` (create if needed).

### Step 3 — Try direct URL first (fast path for short videos)

Try Gemini 2.5 Pro with the YouTube URL directly:

```bash
curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [
        {"fileData": {"fileUri": "YOUTUBE_URL", "mimeType": "video/*"}},
        {"text": "ANALYSIS_PROMPT"}
      ]
    }],
    "generationConfig": {"thinkingConfig": {"thinkingBudget": 8000}}
  }'
```

If response contains `"The input token count exceeds"` → proceed to Step 4 (audio fallback).
If response succeeds → skip to Step 6.

### Step 4 — Audio download fallback (for long videos that exceed token limit)

Download audio only using the Android client (bypasses SABR):
```bash
python3 -m yt_dlp --extractor-args "youtube:player_client=android" \
  -x --audio-format mp3 --audio-quality 5 \
  -o "~/Projects/youtube-transcripts/SLUG.%(ext)s" \
  "YOUTUBE_URL" 2>&1 | grep -v "urllib3\|NotOpenSSL\|Deprecated\|warnings"
```

### Step 5 — Upload audio to Gemini Files API

**Start resumable upload:**
```bash
curl -s -X POST "https://generativelanguage.googleapis.com/upload/v1beta/files?key=$GEMINI_API_KEY" \
  -H "X-Goog-Upload-Protocol: resumable" \
  -H "X-Goog-Upload-Command: start" \
  -H "X-Goog-Upload-Header-Content-Length: $(wc -c < ~/Projects/youtube-transcripts/SLUG.mp3)" \
  -H "X-Goog-Upload-Header-Content-Type: audio/mp3" \
  -H "Content-Type: application/json" \
  -d "{\"file\": {\"display_name\": \"SLUG\"}}" \
  -D - | grep -i "x-goog-upload-url"
```

**Upload file:**
```bash
FILE_SIZE=$(wc -c < ~/Projects/youtube-transcripts/SLUG.mp3)
curl -s -X POST "$UPLOAD_URL" \
  -H "X-Goog-Upload-Offset: 0" \
  -H "X-Goog-Upload-Command: upload, finalize" \
  -H "Content-Length: $FILE_SIZE" \
  --data-binary @/Users/hk/Projects/youtube-transcripts/SLUG.mp3 \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('file',{}).get('uri','ERROR'))"
```

Save the returned `FILE_URI`.

Now call Gemini with the uploaded audio file using the analysis prompt below.

### Step 6 — Gemini: transcript only

Ask Gemini for **transcript only** — no insights, no analysis. This keeps the Gemini call focused and gives Claude clean raw material to work from.

```
This is a video titled "[TITLE]" by [UPLOADER], duration [DURATION].

Provide a full verbatim transcript with timestamps every 1-2 minutes.
Format: [HH:MM:SS] Speaker: text
Identify speakers by name where possible. Do not summarise — transcribe everything spoken, word for word.
```

Use model `gemini-2.5-pro` with `"thinkingConfig": {"thinkingBudget": 8000}`.

Save the transcript text to `/tmp/yt_transcript_SLUG.txt`.

### Step 7 — Claude: synthesize insights from transcript

Read the transcript file and synthesize insights yourself (as Claude, not via API). This produces sharper, more analytical output than asking Gemini to do both steps.

From the transcript, extract:

**Key Insights (10-15):**
- Non-obvious, analytical, not just "what was said"
- Each insight needs a punchy 5-8 word title
- 2-3 sentences explaining why it matters and what's surprising/useful about it
- Flag things like: misleading titles, buried insights, contradictions, second-order implications

**Verbatim quotes per insight:**
- Exact quotes that best support each insight, with timestamp and speaker
- Prefer quotes that are pithy and standalone, not just context-setting

**Also note:** if the YouTube title is clickbait or misleading vs. actual content, flag this in the HTML header.

Parse the response to extract the three parts.

### Step 8 — Render HTML and open

Save to: `~/Projects/youtube-transcripts/SLUG.html`

Use the HTML template below. Open with: `open ~/Projects/youtube-transcripts/SLUG.html`

---

## HTML Template

Use this structure exactly. Light mode, consulting-grade design. Includes tab switcher (Insights / Transcript) and inline remarks system.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[VIDEO TITLE]</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f8f8f6; color: #1a1a1a; line-height: 1.7; }
  .header { background: #fff; border-bottom: 1px solid #e8e8e4; padding: 40px 0 32px; position: sticky; top: 0; z-index: 10; box-shadow: 0 1px 8px rgba(0,0,0,0.04); }
  .header-inner { max-width: 860px; margin: 0 auto; padding: 0 40px; }
  .badge { display: inline-block; background: #f0ede8; color: #7a6a58; font-size: 11px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase; padding: 4px 10px; border-radius: 4px; margin-bottom: 12px; }
  h1 { font-size: 26px; font-weight: 700; color: #111; letter-spacing: -0.02em; line-height: 1.3; margin-bottom: 8px; }
  .meta { font-size: 13px; color: #888; display: flex; gap: 20px; align-items: center; flex-wrap: wrap; }
  .meta a { color: #888; text-decoration: none; }
  .meta a:hover { color: #333; }
  .nav-tabs { display: flex; gap: 4px; margin-top: 20px; }
  .nav-tab { font-size: 13px; font-weight: 500; padding: 6px 14px; border-radius: 6px; cursor: pointer; border: none; background: transparent; color: #888; transition: all 0.15s; }
  .nav-tab.active { background: #1a1a1a; color: #fff; }
  .nav-tab:hover:not(.active) { background: #f0ede8; color: #333; }
  .content { max-width: 860px; margin: 0 auto; padding: 40px 40px 80px; }
  .tab-panel { display: none; }
  .tab-panel.active { display: block; }
  .section-label { font-size: 11px; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; color: #bbb; margin-bottom: 20px; }
  .insight-card { background: #fff; border: 1px solid #e8e8e4; border-radius: 12px; padding: 28px 32px; margin-bottom: 20px; position: relative; transition: box-shadow 0.15s; }
  .insight-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,0.06); }
  .insight-num { font-size: 11px; font-weight: 700; letter-spacing: 0.08em; color: #bbb; text-transform: uppercase; margin-bottom: 8px; }
  .insight-title { font-size: 17px; font-weight: 700; color: #111; margin-bottom: 10px; letter-spacing: -0.01em; }
  .insight-body { font-size: 14.5px; color: #444; line-height: 1.7; margin-bottom: 20px; }
  .quote-block { background: #f8f6f2; border-left: 3px solid #d4cec6; border-radius: 0 8px 8px 0; padding: 14px 18px; margin-top: 8px; }
  .quote-ts { font-size: 11px; font-weight: 600; color: #aaa; letter-spacing: 0.05em; margin-bottom: 6px; }
  .quote-text { font-size: 13.5px; color: #555; font-style: italic; line-height: 1.65; }
  .transcript-entry { display: flex; gap: 20px; padding: 16px 0; border-bottom: 1px solid #f0ede8; }
  .ts-col { flex: 0 0 72px; font-size: 12px; font-weight: 600; color: #bbb; padding-top: 2px; font-variant-numeric: tabular-nums; }
  .speaker-col { flex: 0 0 90px; font-size: 13px; font-weight: 700; color: #7a6a58; padding-top: 2px; }
  .text-col { flex: 1; font-size: 14px; color: #333; line-height: 1.7; }
  .remark-btn { display: none; position: absolute; right: -8px; top: 24px; width: 22px; height: 22px; border-radius: 50%; background: #fff; border: 1.5px solid #d4cec6; cursor: pointer; font-size: 14px; line-height: 1; color: #999; align-items: center; justify-content: center; transition: all 0.15s; z-index: 5; }
  .insight-card:hover .remark-btn { display: flex; }
  .remark-btn:hover { background: #1a1a1a; color: #fff; border-color: #1a1a1a; }
  .remark-box { margin-top: 12px; display: none; }
  .remark-box textarea { width: 100%; border: 1.5px solid #e0dbd4; border-radius: 8px; padding: 10px 14px; font-size: 13px; font-family: inherit; color: #333; resize: none; outline: none; background: #fafaf8; }
  .remark-box textarea:focus { border-color: #aaa; }
  .copy-bar { position: fixed; bottom: 24px; right: 24px; background: #1a1a1a; color: #fff; padding: 10px 18px; border-radius: 8px; font-size: 13px; font-weight: 500; cursor: pointer; border: none; display: none; box-shadow: 0 4px 16px rgba(0,0,0,0.2); }
</style>
</head>
<body>
<div class="header">
  <div class="header-inner">
    <div class="badge">[CHANNEL / SHOW NAME]</div>
    <h1>[VIDEO TITLE]</h1>
    <div class="meta">
      <span>[SPEAKERS if known]</span>
      <span>[DURATION]</span>
      <a href="[YOUTUBE_URL]" target="_blank">↗ YouTube</a>
    </div>
    <div class="nav-tabs">
      <button class="nav-tab active" onclick="switchTab('insights',this)">Key Insights</button>
      <button class="nav-tab" onclick="switchTab('transcript',this)">Full Transcript</button>
    </div>
  </div>
</div>
<div class="content">
  <div class="tab-panel active" id="tab-insights">
    <div class="section-label">[N] Key Insights + Supporting Quotes</div>
    [INSIGHT CARDS HERE — one per insight, format below]
  </div>
  <div class="tab-panel" id="tab-transcript">
    <div class="section-label">Full Verbatim Transcript · [DURATION]</div>
    <div id="transcript-body"></div>
  </div>
</div>
<button class="copy-bar" id="copyBtn" onclick="copyAllRemarks()">Copy All Remarks</button>
<script>
const remarks = {};
function switchTab(name, btn) {
  document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
  document.getElementById('tab-' + name).classList.add('active');
  btn.classList.add('active');
}
function addRemark(id) {
  const box = document.getElementById('remark-' + id);
  if (box.style.display === 'block') return;
  box.style.display = 'block';
  box.innerHTML = '<textarea rows="3" placeholder="Add a remark..." oninput="saveRemark(' + id + ', this.value)"></textarea>';
  box.querySelector('textarea').focus();
}
function saveRemark(id, val) {
  remarks[id] = val;
  document.getElementById('copyBtn').style.display = Object.values(remarks).some(v => v && v.trim()) ? 'block' : 'none';
}
function copyAllRemarks() {
  const lines = [];
  document.querySelectorAll('.insight-card').forEach(card => {
    const id = card.dataset.id;
    const val = remarks[id];
    if (val && val.trim()) {
      const title = card.querySelector('.insight-title').textContent;
      lines.push('[' + id + '] ' + title + '\n→ ' + val.trim());
    }
  });
  if (!lines.length) return;
  navigator.clipboard.writeText(lines.join('\n\n')).then(() => {
    const btn = document.getElementById('copyBtn');
    btn.textContent = 'Copied!';
    setTimeout(() => btn.textContent = 'Copy All Remarks', 1500);
  });
}
// Build transcript from JS array
const transcriptData = [TRANSCRIPT_DATA_ARRAY];
const body = document.getElementById('transcript-body');
transcriptData.forEach(([ts, speaker, text]) => {
  const e = document.createElement('div');
  e.className = 'transcript-entry';
  e.innerHTML = '<div class="ts-col">' + ts + '</div><div class="speaker-col">' + speaker + '</div><div class="text-col">' + text + '</div>';
  body.appendChild(e);
});
</script>
</body>
</html>
```

### Insight card format (repeat for each insight):

```html
<div class="insight-card" data-id="N">
  <button class="remark-btn" onclick="addRemark(N)">+</button>
  <div class="insight-num">0N</div>
  <div class="insight-title">[INSIGHT TITLE]</div>
  <div class="insight-body">[2-3 sentence explanation]</div>
  <div class="quote-block">
    <div class="quote-ts">[HH:MM:SS] Speaker</div>
    <div class="quote-text">"[verbatim quote]"</div>
  </div>
  [additional quote-blocks if needed]
  <div id="remark-N" class="remark-box"></div>
</div>
```

### Transcript data format (JS array in template):

```js
["00:01:07", "Speaker Name", "Verbatim text of what was said."],
["00:02:30", "Speaker Name", "Next line of transcript."],
```

---

## Error handling

| Error | Action |
|-------|--------|
| Token limit exceeded on URL | Switch to audio download pipeline (Step 4) |
| yt-dlp 403 Forbidden | Retry with `--extractor-args "youtube:player_client=android"` |
| No subtitles available | Continue — Gemini transcribes from audio natively |
| Audio > 200MB | Still proceed — Gemini Files API handles up to 2GB |
| File upload fails | Retry once; if still failing, report error to user |

---

## Notes

- Always use `gemini-2.5-pro` — not 2.0-flash, not 1.5-pro (deprecated)
- Always use `rtk proxy curl` to bypass RTK token filtering when parsing JSON responses
- Audio tokens: ~25 tokens/second. 71-min video ≈ 107K tokens — well within the 1M limit
- Video tokens are much higher than audio — long videos will always hit the limit; audio fallback is the reliable path
- Delete the downloaded MP3 after successful analysis to save disk space: `rm ~/Projects/youtube-transcripts/SLUG.mp3`
- Save HTML to `~/Projects/youtube-transcripts/SLUG.html` and open with `open`
- Output dir is always `~/Projects/youtube-transcripts/` regardless of current project folder
