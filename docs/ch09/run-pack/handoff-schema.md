# Handoff Schema

Every specialist returns its work in this shape. The schema exists so that the
person who reads the output next can judge it without reconstructing the
conversation that produced it.

Return YAML. Return nothing before it and nothing after it except the summary
block described at the end.

---

## A candidate

```yaml
- id: C-01
  kind: <specialist-specific, see your contract>
  name: <the name you propose, in the language of the business>
  statement: <one sentence saying what this is>
  source:
    - QUOTE-05
    - QUOTE-06
  status: observed | inferred | proposed | unresolved
  decision_owner: <who must decide this, or "unknown">
  uncertainty: <what would have to be true for this to hold, and what is missing>
  review_question: <the question a human must answer before this advances>
```

## The fields

**`source`** — identifiers taken from the evidence, exactly as written there.
Every candidate must cite at least one. Cite only identifiers that genuinely
support the candidate: an identifier that exists but does not say what you are
claiming is worse than no identifier at all, because it survives a spot check.

**`status`** — how the candidate stands in relation to the evidence:

| Status | Meaning |
|---|---|
| `observed` | The evidence states this directly. |
| `inferred` | You concluded it from the evidence. The evidence does not say it. |
| `proposed` | You are suggesting it. The evidence neither states nor implies it. |
| `unresolved` | The evidence raises the matter and settles nothing. |

`unresolved` is a successful result, not a gap in your work. When people describe
a practice as unwritten, inconsistent, or dependent on who is on shift, the
correct output is `unresolved` with a `review_question`. Producing a rule in that
situation is an error, however sensible the rule.

**`decision_owner`** — who has the authority to decide this, not who wrote it
down and not who carries it out. Write `unknown` when the evidence does not say.
`unknown` is a real answer and is frequently the right one.

**`uncertainty`** — what would have to be true for the candidate to hold, and
what is missing from the evidence. Do not write a confidence score. A number
expressing how sure you feel is not a measurement and will be ignored.

**`review_question`** — the single question a human must answer before anything
downstream may rely on this candidate. Make it answerable. "Is this correct?" is
not a review question; "How long is beer held before it goes back into the room,
and who decides that?" is.

## Statuses you may not use

`accepted` and `rejected` are not available to you. Deciding whether a candidate
becomes part of the model is not part of your work, and an output that claims
either is a failed output regardless of its content.

## Naming

Name things in the language the business used. Where the evidence uses several
words for what you believe is one thing, choose one, say which words you are
unifying, and record the choice as a candidate with its own `review_question`.
Do not silently pick a favourite.

Where the business has no word for something you believe exists, say so in
`uncertainty` rather than inventing a term that sounds established.

---

## Closing summary

After the YAML, add this block:

```markdown
## Summary

- Candidates returned: <n>
- Unresolved: <n>
- Evidence I could not account for: <source identifiers, or "none">
- What I would need in order to go further: <one or two sentences>
```

The third line matters. If part of the evidence did not fit anywhere in your
output, say which part. Silence there is read as a claim of complete coverage.
