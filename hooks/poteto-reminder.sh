#!/bin/bash
# Injects poteto-mode's playbook rule as additionalContext.
# Claude Code has no Custom Mode, and poteto-mode is disable-model-invocation,
# so without this a prose "use poteto-mode" never loads the skill.
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
skill="$root/skills/poteto-mode/SKILL.md"
books="$root/skills/poteto-mode/playbooks"
fio="$root/skills/figure-it-out/SKILL.md"

if [ "$1" = subagent ]; then
  event=SubagentStart
  text="pstack poteto-agent. Before any work: (1) Read $skill in full with the Read tool. (2) Use the playbook named in your prompt; if none is named, match the task to one in the SKILL.md Playbooks section (or $fio if none fits). Read $books/<name>.md and copy its steps verbatim as your first todos; a skipped step stays with 'skip: <reason>'. (3) Your final report must start with 'Playbook: <name>' and list each step's status."
else
  event=UserPromptSubmit
  text="pstack poteto-mode (Claude Code stand-in for Cursor's Custom Mode). Apply when this message starts or redirects a task that needs rigor (code change, bug, investigation, PR work) or mentions poteto-mode/pstack; ignore on casual turns or if the user opts out. Before acting: (1) Read $skill in full with the Read tool (the Skill tool refuses it: disable-model-invocation). (2) Match the task to one playbook in its Playbooks section (or $fio if none fits), Read $books/<name>.md, and copy its steps verbatim as your first todos; a skipped step stays with 'skip: <reason>'. (3) If you delegate to pstack:poteto-agent, name the playbook and step in its prompt. (4) Your final report must name the playbook and each step's status."
fi

esc=${text//\\/\\\\}; esc=${esc//\"/\\\"}
printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$event" "$esc"
exit 0
