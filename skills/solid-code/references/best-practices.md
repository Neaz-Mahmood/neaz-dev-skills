# Code best practices

Language-agnostic guidance. Defer to the project's established conventions and the language's idioms when they conflict with generic advice.

## Naming
- Names reveal intent: `elapsedDays` not `d`, `fetchActiveUsers` not `getData`.
- Functions are verbs, classes/values are nouns, booleans are predicates (`isValid`, `hasPermission`).
- Avoid encodings, vague suffixes (`Manager`, `Data`, `Info`) and abbreviations that aren't domain-standard.
- Same concept, same word across the codebase.

## Functions
- Do one thing at one level of abstraction; extract helpers when a block needs a comment to explain *what* it does.
- Prefer few parameters (≤3); group related ones into an object/dataclass.
- Avoid boolean flag parameters that switch behavior — split into two functions.
- Use guard clauses / early returns instead of deep nesting.
- Avoid hidden side effects; a function named `checkPassword` shouldn't start a session.
- Command–query separation: either change state or return information, not both (where practical).

## Structure & design
- KISS and YAGNI: build for known requirements.
- DRY applies to knowledge (rules, formulas, constants), not to coincidentally similar lines. Wait for the third occurrence before abstracting.
- Composition over inheritance; keep inheritance hierarchies shallow.
- High cohesion, low coupling; modules expose small interfaces and hide internals.
- Law of Demeter: avoid `a.getB().getC().doThing()` chains reaching through objects.
- Keep I/O at the edges (functional core, imperative shell).
- Prefer immutable data and pure functions; minimize shared mutable/global state.

## Error handling
- Never swallow exceptions silently; handle, translate, or propagate with context.
- Use the language's error mechanism (exceptions, `Result`, error returns) consistently — no magic `-1`/`null` sentinels for errors.
- Validate input at system boundaries and fail fast with clear messages.
- Clean up resources deterministically (`with`, `using`, `try/finally`, `defer`).

## Constants & configuration
- Replace magic numbers/strings with named constants or enums.
- Configuration (URLs, credentials, limits) comes from config/env injected at startup, not scattered lookups.
- Never hard-code secrets.

## Types
- Use the type system to make invalid states unrepresentable (enums/unions over free-form strings).
- Avoid `any`/untyped escape hatches in typed languages.
- Annotate public APIs.

## Comments & docs
- Code explains *what*; comments explain *why* (constraints, trade-offs, non-obvious decisions).
- Delete commented-out code; version control remembers it.
- Document public interfaces briefly.

## Testing
- Code should be testable without patching globals — difficulty testing signals hidden dependencies.
- Test behavior via public interfaces, not implementation details.
- One reason to fail per test; descriptive test names.
- Cover edge cases: empty, null, boundaries, error paths.

## Security & robustness
- Parameterized queries; never build SQL/shell commands by string concatenation with input.
- Validate and sanitize external input; encode output for its context.
- Principle of least privilege for credentials and access.
- Don't log secrets or personal data.

## Performance (only when it matters)
- Clarity first; optimize measured hotspots.
- Watch for N+1 queries, accidental quadratic loops, and unbounded memory growth.
