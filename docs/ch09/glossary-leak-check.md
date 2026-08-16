# Chapter 9 — Run-Pack Vocabulary Leak Check

**Answer key. Never placed in a run pack.**

The protocol requires that the run pack not contain the answers the run is meant
to measure. This file records the check and its result.

Re-run this check whenever a run-pack file changes, and record the result before
the next execution.

---

## Command

Executed from `docs/ch09/run-pack/`:

```bash
grep -rniE "ProductStock|StockReservation|ReserveStock|ReleaseStockReservation|ExpireStockReservation|StockReserved|StockReservationFailed|StockReleased|StockReservationExpired|OrderSubmitted|OrderCancelled|OrderExpired" .
```

```bash
grep -rniE "\breserv|\baggregate|\bdomain event|\bbounded context|BC-0|AR-0" .
```

```bash
grep -rniE "fifteen|15 min|minutes|hours|retry|partial" .
```

## Result — 2026-08-16, run pack at first freeze

**A. Carrier owned concepts and external inputs** — no matches.

No aggregate, command, event, or external input named in the carrier appears
anywhere in the run pack. The Coverage axis is therefore measuring naming and
recognition, not recall of a supplied list.

**B. Loose modeling stems** — four matches, all in `constitution-excerpt.md`:

```text
constitution-excerpt.md:4   ...nothing about any particular bounded context.
constitution-excerpt.md:9   ...aggregates, entities, value objects, domain events...
constitution-excerpt.md:12  State changes must be expressed as domain events...
constitution-excerpt.md:16  Each bounded context must speak its own ubiquitous language...
```

Accepted. These are general DDD vocabulary in a document whose purpose is to
state modeling discipline. None of them names a Stock Management concept, a
context, or a policy. `stock-walkthrough.md` and `glossary.md` contain no match,
which is the result that matters: the evidence itself carries no modeling
vocabulary, so any structure in a specialist's output is the specialist's own.

**C. Policy giveaways** — no matches.

No duration, retry count, or partial-fulfilment term appears in the run pack.
The four open questions are raised by the evidence and answered nowhere in it.

---

## Judgment

The run pack is clean. The three unwanted outcomes it was designed to prevent —
recall made tautological by a supplied glossary, boundary discipline made trivial
by named rules, and restraint made trivial by absent pressure — are all excluded.
