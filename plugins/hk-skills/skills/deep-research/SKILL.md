---
name: deep-research
description: Multi-source, multi-pass iterative research on any topic using the Planner-Executor-Critic-Validator loop architecture. Decomposes questions, searches 15+ platforms in parallel, converges on signal, adversarial synthesis. Use when user says "research X", "deep dive on Y", "I need to understand Z before deciding", "market analysis", "due diligence on", or asks for in-depth research on a topic, market, or trend.
---

# Deep Research

Multi-source, multi-pass iterative research on any topic. Uses the Planner-Executor-Critic-Validator loop architecture — searches across 15+ platforms, converges on signal (not budget), and produces adversarially-synthesized findings.

This is not "search and summarize." This is structured research with question decomposition, surprise detection, convergence-based stopping, cross-platform tracing, and adversarial synthesis.

## Input

The user will provide:
- **Research question or topic** — what they want to understand
- **Depth** (optional) — quick | standard | deep (default: standard)
- **Angle** (optional) — market analysis, competitive intel, technical, trend, due diligence, growth, general

## Architecture

```
PHASE 0: DECOMPOSE
    ↓
PHASE 1: BROAD SWEEP (parallel agents)
    ↓ convergence check
PHASE 2: CRITIC
    ↓
PHASE 3: TARGETED DEEP-DIVES (parallel agents)
    ↓ convergence check → if new signal > threshold → LOOP to Phase 2
PHASE 4: VALIDATE
    ↓ if contradictions → LOOP to Phase 3
PHASE 5: ADVERSARIAL SYNTHESIS (4 passes)
    ↓
PHASE 6: OUTPUT (styled HTML → browser)
```

---

## PHASE 0: DECOMPOSE

Before any searching, break the topic into structured sub-questions. This is the most important step — it determines research quality.

### Step 0a: Generate Sub-Questions

Take the user's topic and decompose into 5-8 sub-questions using these lenses:

| Lens | Question Template | Purpose |
|------|------------------|---------|
| **Definitional** | "What exactly is [topic]? How is it defined by practitioners vs outsiders?" | Establish shared understanding |
| **Causal** | "What CAUSED [topic] to emerge/change/matter now?" | Understand drivers |
| **Mechanism** | "HOW does [topic] actually work in practice? What are the mechanics?" | Go beyond surface |
| **Evidence** | "What DATA exists on [topic]? What's measured, what's claimed?" | Separate fact from hype |
| **Contrarian** | "What's the COUNTER-argument? Who disagrees and why?" | Kill confirmation bias |
| **Failure** | "Where has [topic] FAILED? What doesn't work? What are the limits?" | Survivorship bias killer |
| **Temporal** | "WHEN did [topic] emerge? What's the timeline? What triggered inflection points?" | Pattern context |
| **Actors** | "WHO are the key people/companies? Who's amplifying this? Who benefits?" | Follow the incentives |

Not all lenses apply to every topic. Pick the 5-8 most relevant.

### Step 0b: Write Hypotheses

Before searching, write down what you EXPECT to find. 3-5 hypotheses. These are compared against findings later to detect surprises.

### Step 0c: Define Scoring Rubric

Every finding will be scored on:
- **Novelty** (1-5): How new/non-obvious is this? 1 = common knowledge, 5 = genuinely surprising
- **Evidence** (1-5): How well-sourced? 1 = anecdotal/single claim, 5 = multiple independent sources with data
- **Actionability** (1-5): Can someone act on this? 1 = interesting but abstract, 5 = executable this week
- **Confidence** (High/Med/Low): How confident are we in this finding?

### Step 0d: Select Source Channels

Based on the topic, select which sources are relevant:

| Source | Best For | Access Method |
|--------|----------|--------------|
| **Twitter/X** | Viral content, founder takes, real-time discourse | Apify (engagement-first: `min_faves:N`) |
| **Reddit** | Community sentiment, practitioner experience, raw opinions | Reddit JSON API (free) |
| **Hacker News** | Developer/tech sentiment, product launches, technical depth | Algolia HN API (free) |
| **LinkedIn** | Operator playbooks, B2B insights, professional network | Apify |
| **TikTok** | Consumer virality, non-tech audience crossover | Apify |
| **Instagram** | Visual brands, D2C, lifestyle | Apify |
| **YouTube** | Long-form analysis, tutorials, podcasts | yt-dlp for transcripts |
| **Google Play Store** | App reviews — Android-heavy markets (India 95%+ Android); raw user voice, pain points, use cases, version-by-version sentiment | `npx google-play-scraper` (free, no API key) |
| **Apple App Store** | App reviews — higher income demographic proxy (iPhone = ₹15L+ household in India); power user feedback | `npx app-store-scraper` (free, no API key) |
| **IndieHackers** | Solo founder growth stories, revenue numbers | WebFetch |
| **Product Hunt** | Product launches, user reactions, what hooks worked | WebFetch |
| **GitHub** | Developer tools, open source virality, star velocity | GitHub API |
| **Google Trends** | Search volume spikes, temporal patterns, mainstream crossover | WebFetch |
| **AI newsletters** | Curated signal (Ben's Bites, TLDR AI, The Neuron) | WebFetch on archives |
| **Crunchbase** | Funding data, company growth signals | WebFetch |
| **Semantic Scholar** | Academic research, theoretical foundations | API (free) |
| **Wayback Machine** | How messaging/positioning evolved over time | web.archive.org API |
| **Web (general)** | Blogs, articles, reports, analysis | WebSearch + WebFetch |

### App Store / Play Store Commands

```bash
# Google Play — reviews for an app, filtered to India
node -e "
const gplay = require('google-play-scraper');
gplay.reviews({ appId: 'APP_ID', country: 'in', lang: 'en', num: 200, sort: gplay.sort.NEWEST })
  .then(r => r.data.forEach(v => console.log(JSON.stringify({score: v.score, text: v.text, date: v.date, version: v.version}))))
  .catch(console.error);
" 2>/dev/null || npx --yes google-play-scraper-cli reviews APP_ID --country in --num 200

# Apple App Store — reviews for an app, India store
node -e "
const store = require('app-store-scraper');
store.reviews({ id: 'ITUNES_APP_ID', country: 'in', page: 1 })
  .then(r => r.forEach(v => console.log(JSON.stringify({score: v.score, text: v.text, date: v.date, version: v.version}))))
  .catch(console.error);
" 2>/dev/null
```

**Install once if needed:** `npm install -g google-play-scraper app-store-scraper`

**Key app IDs for common research:**
- ChatGPT Play Store: `com.openai.chatgpt` | App Store: `6448311069`
- To find any app's ID: search on Play Store URL (`id=`) or App Store URL (last number segment)

**What to extract from reviews:**
- Use case patterns (what are people actually doing with the app?)
- Pain points by star rating (1-2 star = unmet needs)
- Language of review (Hindi/Hinglish = Tier 2-3 signal)
- Version-specific complaints (feature regression detection)
- Review volume over time (adoption curve proxy)

**Selection rule:** For any topic, use at minimum: Twitter + Reddit + HN + Web. Add others based on topic type:
- Market/growth topics → add LinkedIn, IndieHackers, Product Hunt, Google Trends, TikTok
- Technical topics → add GitHub, Semantic Scholar, YouTube
- Consumer/brand topics → add TikTok, Instagram, Google Play Store reviews, App Store reviews
- Mobile product research → always add both app stores; Play Store = mass market signal, App Store = premium segment signal
- Competitive intel → add Crunchbase, LinkedIn, Wayback Machine, Google Trends

---

## PHASE 1: BROAD SWEEP

Launch one Agent (Opus) per sub-question, in parallel. Each agent:

1. Searches across ALL selected source channels for their specific sub-question
2. Uses engagement-first mining where possible (e.g., Twitter: `min_faves:10000` + broad terms, then filter for relevance)
3. Returns a structured summary:

```markdown
## Sub-Question: [the question]
### Findings (ranked by novelty)
1. **[Finding title]** — [1-2 sentence summary]
   - Source: [URL]
   - Novelty: [1-5] | Evidence: [1-5] | Actionability: [1-5]
   - Surprise flag: [yes/no — does this contradict our hypotheses?]

2. ...

### Sources Consulted: [count]
### Gaps: [what couldn't be answered from available sources]
```

**CONVERGENCE BASELINE:** Count total net new findings across all agents. This is the baseline for convergence detection.

---

## PHASE 2: CRITIC

A single Agent (Opus) reads ALL Phase 1 summaries and produces:

1. **Theme Clusters** — group findings into 3-7 emergent themes
2. **Gap Analysis** — what sub-questions got weak answers? What's missing?
3. **Contradiction Detection** — where do sources disagree?
4. **Surprise Report** — compare findings against Phase 0 hypotheses. What was unexpected?
5. **Round 2 Queries** — specific, targeted searches to fill gaps and resolve contradictions
6. **Cross-Platform Leads** — any finding that went viral: where else did it appear?

---

## PHASE 3: TARGETED DEEP-DIVES

Launch Agents (Opus, parallel) for:

1. **Gap-filling searches** — go deeper on weak areas identified by Critic
2. **Contradiction resolution** — find additional sources to settle disagreements
3. **Cross-platform tracing** — for each viral/important finding, trace the amplification chain:
   - Original source → who shared it → which community picked it up → did it cross platforms → what was the timeline
4. **Temporal analysis** — overlay Google Trends data on top findings to see when they peaked and what triggered spikes
5. **Influence tracing** — who are the key amplifiers for this topic? What's their incentive?

Each agent returns same structured format as Phase 1.

**CONVERGENCE CHECK:** Count net new findings from this round.
- If new findings > 30% of Phase 1 baseline → LOOP BACK to Phase 2 (Critic re-evaluates with new data)
- If new findings ≤ 30% → proceed to Phase 4

This loop can run 2-4 times. Stop when diminishing returns.

---

## PHASE 4: VALIDATE

Launch Agents (Opus, parallel) to cross-check findings:

1. Every factual claim must be traceable to a source URL
2. Every number/stat must be verified — if two sources give different numbers, flag it
3. Score confidence for each finding: High (3+ independent sources), Medium (2 sources), Low (1 source or anecdotal)
4. Flag and remove anything unsourced or fabricated
5. Downgrade findings that are single-source to Low confidence

**CONVERGENCE CHECK:** If validation reveals significant contradictions (>20% of findings disputed):
→ LOOP BACK to Phase 3 with specific resolution queries

---

## PHASE 5: ADVERSARIAL SYNTHESIS

Run 4 sequential synthesis passes:

### Pass 1: Optimist
"What's genuinely new, important, and actionable here? What are the breakthrough findings?"

### Pass 2: Skeptic
"What's actually just repackaged old ideas with new labels? What's survivorship bias? What's hype with no evidence? What should be downgraded or removed?"

### Pass 3: Meta-Pattern
"Given the validated findings, what are the 3-5 underlying SHIFTS or PRINCIPLES that explain most of them? What's the second-order insight that isn't obvious from individual findings?"

### Pass 4: Actionability
"For each top finding, what's the minimum viable version someone could execute in under 2 weeks? What's the fastest path from insight to action?"

### Scoring
Apply the rubric from Phase 0 to all final findings. Sort by: Novelty × Evidence × Actionability.

---

## PHASE 6: OUTPUT

Generate as **styled HTML** and open in browser (per user preference).

### Structure

```markdown
# Research: [Topic]
**Date:** [today]
**Depth:** [quick/standard/deep]
**Sources consulted:** [count] across [count] platforms
**Research rounds:** [count] (convergence-based)

---

## TL;DR
[5 bullet points — the most important things to know]

## Hypotheses vs Reality
| Hypothesis | What We Expected | What We Found | Surprise? |
|-----------|-----------------|---------------|-----------|

## Key Findings (sorted by Novelty × Evidence × Actionability)

### [Finding 1 — headline]
- **What:** [description]
- **Evidence:** [source links]
- **Scores:** Novelty [N] | Evidence [E] | Actionability [A] | Confidence [H/M/L]
- **Cross-platform trace:** [where this appeared and how it spread]

[Repeat for each finding]

## Meta-Patterns
[The 3-5 underlying shifts/principles from Pass 3]

## By The Numbers
| Metric | Value | Source |
|--------|-------|--------|

## Novelty × Evidence Matrix
[2x2 or scatter plot description: which findings are high-novelty + high-evidence vs low]

## Timeline
[When key findings/events emerged, what triggered them]

## Contradictions & Debates
[Where sources disagree, with both sides]

## What Failed / Doesn't Work
[Explicit anti-patterns, failed attempts, limits]

## What We Still Don't Know
[Gaps that couldn't be filled, questions for future research]

## Action Items
[From Pass 4 — what can be done in < 2 weeks, ordered by impact]

## Sources
[Numbered list of all URLs, grouped by platform]
```

### HTML Output

Generate the report as a styled HTML file with:
- Clean typography (Inter + serif headings)
- Accent color based on topic (default: gold #b8860b)
- Collapsible sections for findings
- Sticky table of contents
- Print-friendly CSS

Open in browser: `open report.html`

---

## Depth Levels

| Level | Sub-Questions | Phase 1 Agents | Max Loops | Min Sources | Expected Time |
|-------|--------------|----------------|-----------|-------------|---------------|
| Quick | 3-4 | 3-4 parallel | 1 (no loop) | 15-20 | ~10 min |
| Standard | 5-6 | 5-6 parallel | 2-3 loops | 30-40 | ~30 min |
| Deep | 7-8 | 7-8 parallel | 3-4 loops | 50+ | ~60 min |

Default: **standard**

---

## Quality Rules

- **Every claim needs a hyperlinked source** — no exceptions. In HTML output, all source references must be clickable `<a href="URL" target="_blank">` links — both inline citations in tables/text and in the Sources section. Never list a source name without its URL. In markdown output, use `[Source Name](URL)` format.
- **Engagement-first mining** — on social platforms, filter by high engagement first, then assess relevance (don't keyword search)
- **Recency bias check** — flag if best data is >1 year old
- **Numbers need context** — raw numbers without comparison are meaningless
- **Separate fact from opinion** — label which is which
- **Admit gaps explicitly** — "couldn't find" > guessing
- **Surprises ARE the report** — expected findings are confirmation; surprises are the value
- **No filler** — if a section has nothing meaningful, skip it

## Arguments

$ARGUMENTS
