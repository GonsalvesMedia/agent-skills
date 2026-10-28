---
name: eval-skills
description: Blind-test and improve an agent skill against realistic golden cases. Use when the user asks to evaluate, harden, or improve a skill; reports that a skill repeatedly misses an outcome; or provides a skill with concrete input and quality-bar examples.
---

# Evaluate Skills

Treat a skill as a function under test. A valid evaluation isolates the runner from the expected answer, grades the artifact against a stated quality bar, and uses failures to make the smallest targeted skill edit.

## Required inputs

Before spending an independent agent run, establish all three:

- A target skill that resolves to a real `SKILL.md`.
- At least one realistic input the skill will receive.
- A quality bar: the outcome a competent artifact should achieve and the smells that make it unacceptable. Choose judgment criteria or exact conformance deliberately.

If any is missing, state what is needed; do not invent cases or a fuzzy bar.

## Workflow

1. Read the target skill's purpose, trigger description, workflow, and current resources. State its first principles in one sentence.
2. Run one fresh, context-isolated agent per case. Give the runner only the user-like input and the instruction to use the target skill—never the bar, expected result, prior diagnosis, or other cases. Keep writes in a disposable sandbox when the output cannot stay in the final response.
3. Sweep the real workspace after each run. Isolation is best-effort; confirm no artifacts leaked.
4. Give a separate fresh judge the artifact, the quality bar, and the target skill's first principles. Require evidence-backed findings, not a numeric vibe score.
5. Re-run important or borderline cases two or three times and report pass rate; one green run is not proof against nondeterminism.
6. Classify each miss: skill defect, bad case, insufficient input, or an outcome the skill should not promise. Do not encode a bad bar merely to make a case pass.
7. Edit only the instruction or resource that addresses the diagnosed failure, then re-evaluate all relevant cases. Use `$skill-creator` when available for the edit itself.

## Compound promotion gate

When evaluating guidance intended for `$promote-learning` (if installed; cross-project or agent-system promotion into a shared skill system), require a realistic golden case: concrete input, stated quality bar, and evidence the lesson generalizes. Do not approve promotion on anecdote alone. This skill remains the evaluation owner; it does not embed promotion workflow—report whether the case supports promotion and hand off to `$promote-learning`.

## Rules

- Blindness is non-negotiable: the runner never sees the bar; the judge never sees the expected answer or a request to make the result pass.
- Use an independent-agent mechanism only when the user invoked this skill or otherwise authorized the evaluation cost. If no fresh isolated agent is available, produce the evaluation protocol and state that no blind result was run.
- Grade judgment skills against the bar, not a prescribed answer; grade conformance skills against explicit criteria.
- Stop when the skill cannot responsibly express the desired behavior and report that limit.
- Do not automatically fan out external models beyond the authorized evaluation runs for this skill.

## Done

Report each case's pass rate and evidence, diagnosed defect or bad-bar finding, edits made, re-evaluation result, leaked-artifact sweep, and remaining limitations.
