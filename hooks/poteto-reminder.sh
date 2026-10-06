#!/bin/bash
# Claude Code stand-in for Cursor's Custom Mode. poteto-mode is
# disable-model-invocation and Claude Code has no Custom Mode, so this keeps
# its playbook rule in front of the agent, but only in sessions that opted in.
#   main:     silent until a message mentions poteto-mode, then reminds on
#             every message for the rest of that session ("stop/exit
#             poteto-mode" turns it off).
#   subagent: fires whenever a poteto-agent starts (only spawned on purpose).
root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
skill="$root/skills/poteto-mode/SKILL.md"
books="$root/skills/poteto-mode/playbooks"
fio="$root/skills/figure-it-out/SKILL.md"

emit() {
  local esc=${2//\\/\\\\}; esc=${esc//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$1" "$esc"
}

if [ "$1" = subagent ]; then
  emit SubagentStart "pstack poteto-agent. Before any work: (1) Read $skill in full with the Read tool. (2) Use the playbook named in your prompt; if none is named, match the task to one in the SKILL.md Playbooks section (or $fio if none fits). Read $books/<name>.md and copy its steps verbatim as your first todos; a skipped step stays with 'skip: <reason>'. (3) Your final report must start with 'Playbook: <name>' and list each step's status."
  exit 0
fi

input=$(cat)
sid=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -n "$sid" ] || exit 0
state="${TMPDIR:-/tmp}/pstack-poteto-mode"
flag="$state/${sid//[^A-Za-z0-9_-]/_}"

if printf '%s' "$input" | grep -qiE '(stop|exit|leave|turn off|disable)[^"]{0,20}poteto[ -]mode'; then
  rm -f "$flag"; exit 0
fi
if printf '%s' "$input" | grep -qiE 'poteto[ -]mode'; then
  mkdir -p "$state" && : > "$flag"
fi
[ -f "$flag" ] || exit 0

emit UserPromptSubmit "pstack poteto-mode is on for this session (Claude Code stand-in for Cursor's Custom Mode; say 'stop poteto-mode' to turn it off). Apply when this message starts or redirects a task that needs rigor (code change, bug, investigation, PR work); ignore on casual turns. If you have not already this session: (1) Read $skill in full with the Read tool (the Skill tool refuses it: disable-model-invocation). (2) Match the task to one playbook in its Playbooks section (or $fio if none fits), Read $books/<name>.md, and copy its steps verbatim as your first todos; a skipped step stays with 'skip: <reason>'. (3) Your final report must name the playbook and each step's status."
exit 0
