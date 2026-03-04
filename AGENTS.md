# AGENTS.md - AI Agent Guidelines

This file provides guidance for AI agents working in this repository.

## Commit Message Prefixes

**Always** use the appropriate prefix based on the AI agent being used:

| Agent             | Prefix                |
|-------------------|-----------------------|
| Claude (Code)     | `[CLAUDE_AI]`         |
| Gemini-CLI        | `[GEMINI_AI]`         |
| Cursor            | `[CURSOR_AI]`         |
| GitHub Copilot    | `[GITHUB_COPILOT_AI]` |
| OpenAI Codex      | `[OPENAI_CODEX_AI]`   |
| Windsurf/Cascade  | `[WINDSURF_AI]`       |
| Opencode          | `[OPENCODE_AI]`       |
| Antigravity       | `[ANTIGRAVITY_AI]`    |
| AMP               | `[AMP_AI]`            |
| Ollama            | `[OLLAMA_AI]`         |
| Openclaw          | `[OPENCLAW_AI]`       |

**Fallback Patterns:**
- **Recognized but unmapped agents**: Use `[AGENT_NAME_AI]` where AGENT_NAME is the uppercase version of the agent name
- **Completely unrecognized agents**: Use generic `[AI]` prefix

**Required Model Information:**
Agents must include the LLM model name in the commit message body for traceability.

For OpenAI Codex, use this model naming pattern in commit bodies:
- `GPT-5.x-Codex (Medium)`
- Replace `Medium` with the active mode when applicable (for example `Low` or `High`).

**Common Model Examples:**
- SWE-1.5, Gemini Flash 2.5, Gemini Pro
- Claude Sonnet-4.5, Claude Opus-4.6
- DeepseekR1

**Format Examples:**
```
[WINDSURF_AI] Fix nginx configuration template

Optional details.

Co-authored-by: Windsurf <noreply@windsurf.ai>
Model: Claude Sonnet-4.5 (Cascade)
```

```
[OPENAI_CODEX_AI] Optimize Docker layer caching

Optional details.

Co-authored-by: Codex <codex@openai.com>
Model: GPT-5.3-Codex (Medium)
```

**Required Co-Author Trailer:** Add the agent identity using a `Co-authored-by:` trailer in every AI-generated commit message.

## Rationale

- **Traceability**: Identify which AI agent made specific changes
- **Accountability**: Track performance and patterns of different agents
- **Debugging**: Understand context and capabilities behind changes
- **Documentation**: Maintain clear history of automated contributions
