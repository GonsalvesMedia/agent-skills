# GPT-6.1 Terra: routing evidence

Researched 2026-10-27; released 2026-10-26. Recheck these sources before relying on prices or benchmark rankings after this date.

## OpenAI's positioning

[The release announcement](https://openai.com/index/introducing-gpt-6-1-terra/) emphasizes visual reasoning, computer use, and natural writing. OpenAI reports much stronger terminal coding than GPT-5.6 Terra, but still recommends Sol or Astra for the most complex coding. Its reported speed and cost advantages on Agents' Last Exam describe that evaluation, not every repository task.

[The model-selection guide](https://developers.openai.com/api/docs/guides/model-selection) specifically recommends considering Terra for scoped code fixes, writing from supplied material, and computer use with a defined outcome. It recommends comparing the same inputs and reasoning effort, then checking the actual output. This supports trying Terra for bounded delegated work while retaining Sol as this skill's default.

## Cost and access

[The model page](https://developers.openai.com/api/docs/models/gpt-6.1-terra) lists standard API rates per million tokens: $1 input, $0.05 cached input, and $5 output. Those input/output rates are half Sol's and one-tenth Astra's in the [standard pricing table](https://developers.openai.com/api/docs/pricing) at launch. Cache writes, long-context adjustments, service tiers, and tools can change the bill; token prices do not guarantee the same reduction in completed-task cost.

OpenAI says Terra stretches the ChatGPT Work/Codex usage allowance further than Sol or Astra; API prices are not subscription-credit conversion rates. Availability is through Work, Codex, and the API. See the [release notes](https://help.openai.com/en/articles/9624314-model-release-notes) for availability restrictions.

## Independent evidence

- [Artificial Analysis, October 26](https://artificialanalysis.ai/articles/gpt-6-1-terra-pushes-the-cost-efficiency-frontier): Terra's Coding Agent Index score is 48 versus Sol's 54 and Luna's 31. Low and medium effort are on its general intelligence/cost frontier; low and xhigh are on its coding/cost frontier. This supports a cost-conscious middle option, not replacing Sol for every coding task. Scores depend on the evaluator's tasks and harness.
- [Thorsten Meyer AI's newsroom test, October 26](https://thorstenmeyerai.com/reality-check/gpt-6-1-terra-cost-per-task-effort-levels/): source-based article writing worked well at lower effort, while max added outside facts and performed worse. This was a small private test: 12 articles per language, English and German, one run per setting through Codex, with two AI judges. Treat it as a reason to test effort on the actual workload, not a general verdict on Terra.

## Applying this to use-codex

Start with Terra/medium for a clear, verifiable patch or supplied-material writing task when cost matters. Consider low for straightforward edits. Move to Sol when the work needs broader investigation or Terra misses acceptance criteria; use Astra for the hardest judgment calls. Keep Luna for simple extraction or transformation when it meets the quality bar. Compare finished-task cost, including retries and review, before moving recurring work.

Example for an already-authorized scoped patch:

```bash
printf '%s\n' "$PROMPT" | \
  /absolute/path/to/use-codex/scripts/run-codex.sh \
  --mode patch --model gpt-6.1-terra --reasoning medium \
  --workspace /absolute/path/to/repo
```

The wrapper's existing reasoning allowlist and sandbox rules still apply. Its default remains Sol/medium. These recommendations synthesize published evidence; they are not an in-repository model-quality evaluation.
