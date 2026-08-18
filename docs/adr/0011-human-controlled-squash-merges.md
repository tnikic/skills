# Human-Controlled Squash Merges

Agents stop at ready for review, and a human reviews and squash-merges each PR; neither the agent nor forge auto-merge completes the workflow. The deliberate separation preserves human approval at the irreversible merge boundary while keeping the merged history to one commit per PR.
