---
name: solid-code
description: Apply SOLID principles and code best practices whenever writing, refactoring, or reviewing code in any language. Use this skill any time the user asks to build a feature, write a class/module/function/service, refactor or "clean up" code, review a diff or PR, or asks whether code is well-designed, maintainable, testable, or follows SOLID / clean code — even if they don't say "SOLID" explicitly. Also use it when designing module boundaries, adding a new variant to existing code (new payment type, new provider, new format), or fixing code that is hard to test or change. Includes React rules (avoiding unnecessary useEffect, SPA architecture and routing) for any React component, hook, or app work.
---

# SOLID & Code Best Practices

The goal is code that is easy to read, test, and change. SOLID and the practices below are tools for that goal, not a checklist to maximize. Over-engineered code (interfaces with one implementation, factories for a single class, five files where one would do) violates "best practices" just as much as a 600-line god class. Calibrate to the size and lifetime of the code in front of you.

## Two modes

Figure out which mode applies, then follow that section.

- **Write mode** — the user wants new code or a refactor. Design it well from the start; don't produce code and then lecture about it.
- **Review mode** — the user wants existing code assessed. Produce a structured review (format below), and offer to apply fixes.

If the user asks you to write code inside a codebase that already has violations, stay in write mode: follow the codebase's existing conventions, make *your* code clean, and mention notable nearby problems briefly rather than refactoring unrelated code uninvited.

## The principles (short form)

Read `references/solid.md` for smells, fixes, and before/after examples of each principle when you need detail or are unsure whether something is a violation.

- **S — Single Responsibility.** A module has one reason to change — one actor or concern it serves. Smells: a class that validates *and* persists *and* emails *and* formats; names with "And"/"Manager"/"Util"; methods that touch unrelated fields.
- **O — Open/Closed.** Add new behavior by adding code, not editing a growing `if/elif`/`switch` on a type tag. Smell: the same type switch repeated in several places. Fix: polymorphism, a strategy map, or a registry — once there are (or clearly will be) multiple variants.
- **L — Liskov Substitution.** Subtypes must honor the parent's contract. Smells: overrides that throw `NotImplemented`, strengthen preconditions, return different shapes, or require `isinstance` checks by callers. Fix: prefer composition or a narrower abstraction.
- **I — Interface Segregation.** Callers shouldn't depend on methods they don't use. Smell: fat interfaces where implementers stub half the methods. Fix: split by client need.
- **D — Dependency Inversion.** Business logic depends on abstractions it owns; I/O details (DB, HTTP, clock, filesystem, env) are injected. Smell: `new Database()` / `requests.get` / `datetime.now()` buried in domain logic, making it untestable without patching.

## Best practices beyond SOLID

See `references/best-practices.md` for the fuller list. The ones that matter most:

- **Naming** reveals intent; no cryptic abbreviations; booleans read as predicates (`isActive`, `has_access`).
- **Small focused functions** at one level of abstraction; early returns over deep nesting.
- **DRY with judgment** — remove duplicated *knowledge*, but tolerate small coincidental duplication over a premature abstraction (rule of three).
- **KISS / YAGNI** — the simplest design that meets current, known requirements.
- **Explicit error handling** — no swallowed exceptions, no magic return codes; fail fast on invalid input at boundaries.
- **No magic numbers/strings** — name constants.
- **Immutability and pure functions** where practical; minimize shared mutable state.
- **Composition over inheritance** unless there's a true is-a relationship with a stable contract.
- **Testability** — if a unit is hard to test, that's design feedback; usually a hidden dependency.
- **Security & robustness basics** — validate input, parameterize queries, no secrets in code.

## Framework-specific rules

- **React** — use `useEffect` only to sync with third-party/external data or systems (API data, subscriptions, non-React widgets). Derived values are computed during render, user actions go in event handlers, and state resets use a `key`. Build React apps as client-rendered SPAs: client-side routing, lazy-loaded routes, data from APIs, no SSR or Server Components. Read `references/react.md` before writing or reviewing React components, hooks, or app structure.

## Write mode

1. Before coding, identify the responsibilities and the volatile parts (things likely to vary: providers, formats, rules, I/O). Those are the seams worth abstracting; everything else stays concrete.
2. Write the code following the principles above and the idioms of the language and the existing codebase (naming conventions, file layout, error style, DI style). Idiomatic beats textbook — e.g., in Python or JS, a function or a dict of callables is often a better "strategy" than a class hierarchy.
3. Keep I/O at the edges and inject it, so core logic is testable. Include or suggest tests when appropriate.
4. After the code, add a brief **Design notes** section (3–6 bullets) explaining the key design decisions and which principle each serves — including where you deliberately *didn't* abstract and why. Keep it short; the code should speak for itself.

## Review mode

Read the code fully before judging. Prioritize by impact on change and correctness, not by how many principles you can name. Use this format:

```markdown
## Summary
One or two sentences: overall health and the single most important issue.

## Findings
### 1. [Short title] — [Principle/practice] — [High|Medium|Low]
**Where:** file:line or function/class name
**Problem:** what is wrong and the concrete consequence (what change or test becomes painful).
**Fix:** specific recommendation, with a short code sketch when it helps.

(repeat, ordered most severe first)

## What's good
Brief notes on things done well (keeps the review honest and calibrated).

## Suggested next step
Offer to apply the fixes, or name the one refactor with the best payoff.
```

Severity guide:
- **High** — causes bugs, blocks testing, or every new feature requires editing the same fragile code.
- **Medium** — real maintainability cost that will grow.
- **Low** — readability/style nits.

Don't flag something as a violation just because a pattern *could* be applied. If the code is small, stable, and clear, say so.

## Calibration

Before adding an abstraction, ask: is there more than one implementation now, or a concrete, known reason there will be? Does it make testing meaningfully easier? If neither, keep it concrete. A 30-line script does not need dependency injection; a payment service with three providers does.

When the `ponytail` skill is also active, its smallest-complete-change rule wins: add a SOLID abstraction only where the calibration above justifies it, and never add code just to satisfy a principle.
