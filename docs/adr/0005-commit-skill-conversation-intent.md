# Commit skill uses conversation intent detection, not CLI flags

The commit skill is a conversational agent skill, not a CLI tool. Its behavior adapts based on what the user says ("commit," "commit just these files," "amend that commit") rather than flag arguments (`--no-stage`, `--reword`). This was chosen over a CLI-style flag interface because the skill is invoked through natural conversation (typically via Whisper dictation), where flags would break the user's flow. The agent reads the conversation context to infer intent: whether to auto-stage or use pre-staged files, whether to generate a commit message or use the one the user already provided. No flags, no subcommands — just talk.

## Considered Options

- **CLI flags** (`/commit --no-stage --reword`) — familiar pattern but wrong interface for a conversational skill. Rejected: flags are unnatural in voice-driven workflows.
- **Conversation intent detection** — agent reads what the user said and adapts. Chosen: natural interface, works with dictation, no memorized flags.
