---
description: Deep planning session for loaded issue
---

Comprehensive planning session after `/appa:work-issue`. Use extended thinking, explore thoroughly, ask questions until the plan is bulletproof.

**Prerequisites:**
- Run `/appa:work-issue <number>` first to load issue context
- Enter plan mode before running this command

**Usage:**
```
/appa:plan-issue
```

**Execution flow:**

1. **Activate extended thinking**
   - Ultrathink about the problem before acting
   - Reason through edge cases, dependencies, risks
   - Don't rush - thoroughness is the goal

2. **Synthesize loaded context**
   - Issue objective + done-when criteria
   - Any scope/context from issue body
   - Current branch and codebase state

3. **Identify unknowns**
   - What information is missing to build a solid plan?
   - What assumptions need validation?
   - What could go wrong?

4. **Deep codebase exploration** (the `scout` agent — model sonnet, read-only, returns file paths and call chains — is the right tool for the fan-out)
   - Trace all relevant code paths
   - Find existing patterns to follow
   - Identify all files that need modification
   - Check for tests, types, related components
   - Understand dependencies and side effects
   - Be EXHAUSTIVE - explore more than you think necessary

5. **API documentation lookup** (if external APIs involved)
   - Use Context7 MCP to fetch relevant API docs
   - Understand request/response shapes
   - Note authentication, rate limits, error handling

6. **Ask clarifying questions**
   - Don't batch questions - ask as they arise
   - Validate assumptions with user
   - Clarify ambiguous requirements
   - Discuss tradeoffs and get user preference
   - This is interactive spec crafting - take your time
   - Ask until there are ZERO ambiguities

7. **Draft implementation plan**
   - Step-by-step implementation sequence
   - Files to create/modify (with specific changes)
   - Test strategy
   - Risks and mitigations
   - Dependencies between steps

8. **Write to plan file** (plan mode handles this)
   - Clear, actionable steps
   - Specific file paths
   - Acceptance criteria from issue

9. **Final review with user**
   - Walk through plan
   - Confirm nothing is missing
   - Get explicit approval before implementation

**Key requirements:**
- Use extended thinking - don't shortcut reasoning
- Fresh exploration every time (don't assume prior research)
- Heavy user interaction - questions are good
- Exhaustive codebase exploration
- No ambiguity left unresolved
- Plan must be specific enough that implementation is mechanical

**Mindset:**
This is the last chance to get the spec right. An hour of planning saves days of rework. Ask every question. Explore every file. Leave nothing to chance.
