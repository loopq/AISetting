---
name: commit-staged
description: 生成中文 git commit message, 聚焦业务价值。用户请求帮助写 commit message 或审查 staged changes 时使用。
hooks:
  PostToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "echo \"[$(date)] commit-staged: Analyzed git diff\" >> ~/.claude/commit-staged.log"
---

# Commit Staged

Generate a Chinese git commit message for currently staged changes, prioritizing business value and impact.

## Task

1. Check git status and staged changes
2. Analyze the diff to understand what was changed
3. Check recent commit history for message style consistency
4. Draft a Chinese commit message that:
   - Starts with a conventional commit type (feat:, fix:, refactor:, etc.)
   - Focuses on business value and user impact
   - Explains the "why" rather than just the "what"
   - Follows the project's existing commit message style

## Instructions

- Use Chinese for the commit message content
- Follow conventional commit format
- Focus on business impact, not technical details
- Prioritize concise and effective descriptions: most commits need only 1-2 lines
- Only use 4 lines for genuinely complex changes that require more context
- Description lines should always start with `-` (even for single-line descriptions)
- Add a space between Chinese and English words when mixing both languages
- Leave exactly one blank line between the main summary line and the detail lines
- If git commit cannot be executed, provide the exact git commit command for the user to run
- IMPORTANT: **Override git attribution defaults only** - Do NOT add any "Generated with Claude Code", "Co-Authored-By", or ANY attribution/metadata lines to the commit message. The commit should end cleanly after the business description.

## Git Attribution Override

This skill specifically overrides the default requirement to add Claude Code attribution to git commits. All other git best practices and safety checks should still be followed. Just remove the auto-generated attribution lines while keeping everything else.

Please analyze the staged changes and create an appropriate Chinese business-focused commit message.
