# Claude Skills by Harry Kapoor

Agent skills for deep research and creative ideation. Works with [Claude Code](https://claude.ai/code) and any tool supporting the [Agent Skills](https://agentskills.io) standard (Cursor, VS Code Copilot, Gemini CLI, and others).

## Skills included

### `/hk-skills:deep-research`

Multi-source, multi-pass iterative research on any topic. Uses a Planner-Executor-Critic-Validator loop architecture — searches across 15+ platforms in parallel, converges on signal, and produces adversarially-synthesized findings.

- 6-phase architecture: Decompose → Broad Sweep → Critic → Deep-Dives → Validate → Adversarial Synthesis
- Searches Twitter, Reddit, HN, LinkedIn, YouTube, TikTok, GitHub, Google Trends, and more
- Convergence-based stopping (not budget-based)
- Outputs styled HTML report with collapsible sections and source links

### `/hk-skills:creative-ideation`

Generate non-obvious, high-surprise creative ideas using trisociation (3-concept fusion), worst-idea inversion, and cultural intelligence sweeps.

- Cultural intelligence sweep across 7 social platforms before ideating
- Trisociation engine: forces collisions between 3 unrelated concepts
- Worst-idea inversion: start with the worst idea, flip it
- Scoring rubric: Surprise, Cultural Precision, Forwardability, Simplicity, Feasibility, Risk
- India-specific market addendum with cultural territories and virality triggers

## Install

In Claude Code:

```
/plugin marketplace add harrykapoor19/claude-skills
/plugin install hk-skills@hk-marketplace
```

Then use:

```
/hk-skills:deep-research AI agents for Indian consumers
/hk-skills:creative-ideation launch campaign for a dating app
```

## Requirements

Some features use external APIs (Apify for social media scraping, etc.). API keys are referenced by environment variable name — you'll need your own keys for full functionality.

## License

MIT
