# Chapter 9 — Run-Pack Leak Check

**Answer key. Never placed in a run pack.**

The protocol requires that the run pack not contain the answers the run is meant
to measure. This file records the check and its result.

Re-run all four audits whenever a run-pack file changes, and record the result
before the next execution.

---

## Audits

Executed from `docs/ch09/run-pack/`.

**A — Carrier concepts.** Do the names of the carrier's aggregates, commands,
events, or external inputs appear anywhere in the run pack?

```bash
grep -rniE "ProductStock|StockReservation|ReserveStock|ReleaseStockReservation|ExpireStockReservation|StockReserved|StockReservationFailed|StockReleased|StockReservationExpired|OrderSubmitted|OrderCancelled|OrderExpired" .
```

**B — Modeling stems.** Does the run pack supply modeling structure the
specialist is supposed to propose?

```bash
grep -rniE "\breserv|\baggregate|\bdomain event|\bbounded context|BC-0|AR-0" .
```

**C — Policy giveaways.** Does anything answer, or point at an answer to, one of
the four open questions?

```bash
grep -rniE "fifteen|minutes|hours|retry|partial|how long|on shift|unwritten" .
```

**D — Anticipation.** Does any *reference* file — as opposed to the evidence
itself — tell the specialist what it is supposed to find?

```bash
grep -rniE "several words|same thing|unifying|interchangeable|contradict|inconsistent|expiry|duration|window" .
```

Audit D was added after audit A, B and C passed on a run pack that still
contained a leak. Vocabulary matching alone does not catch guidance phrased in
ordinary words.

---

## Result — 2026-08-16, second freeze

**A — no matches.** No carrier concept name appears in the run pack. Coverage
measures naming and recognition, not recall of a supplied list.

**B — four matches, all in `constitution-excerpt.md`.** General DDD vocabulary in
a document whose purpose is to state modeling discipline. None names a Stock
Management concept, a context, or a policy. The walkthrough and the glossary
contain no match, which is the result that matters: the evidence carries no
modeling vocabulary, so any structure in a specialist's output is its own.

**C — two matches, both inside the evidence.** `QUOTE-35` and `QUOTE-41` contain
the phrase "how long", spoken by the interviewer and by Piotr. That is the open
question being raised by the evidence, which is the point of the fixture. Nothing
in the reference files mentions duration.

A first freeze of `handoff-schema.md` illustrated a good review question with
*"How long is beer held before it goes back into the room, and who decides
that?"* — which handed the specialist one of the four open questions together
with the correct way to treat it. That example has been removed and replaced with
an abstract statement of what a review question must contain.

**D — five matches.** Four are inside `stock-walkthrough.md` and are the evidence
itself: `QUOTE-07`, `QUOTE-08` and `OBS-03` are where the naming variation is
raised, and line 11 is the fixture's own framing note. Evidence is allowed to
contain findings; that is what evidence is.

One is in `handoff-schema.md`, in the general instruction to unify vocabulary
rather than silently pick a favourite. Accepted: it states a discipline without
naming which words in this fixture need unifying.

### Finding closed by this freeze

The first freeze of `glossary.md` carried the entry:

```text
To set aside / to put a hold on / to earmark — Words used in the interview for
separating beer from general stock against a particular customer order. The
speakers used all three and treated them as the same action.
```

together with a preamble stating that several words for the same thing were
recorded unresolved. Between them, these resolved E-04 before the specialist saw
the evidence: the glossary asserted the three terms were one action, so unifying
them cost nothing and demonstrated nothing.

The three terms are now three separate entries, each described as it was heard,
with no claim about whether they are one thing. The evidence still supports the
unification — `QUOTE-08` has Nadia say "Same thing" — but the specialist now has
to reach it from the transcript, which is the work being measured.

`OBS-03` is retained in the walkthrough. An observer's field note recording a
noticed pattern is legitimate evidence, and the measurement is what the
specialist does with it: whether it unifies the terms, which name it chooses, and
whether it raises the choice as a review question rather than settling it.

---

## Judgment

The run pack is clean at this freeze. The four unwanted outcomes it is designed
to prevent — recall made tautological by a supplied glossary, boundary discipline
made trivial by named rules, restraint made trivial by absent pressure, and
findings handed over by reference material — are all excluded.

This audit must be re-run after the four contracts are added to
`run-pack/contracts/`.
