# SOLID in depth

Examples use pseudo-TypeScript/Python; translate to the target language's idioms.

## Contents
- Single Responsibility
- Open/Closed
- Liskov Substitution
- Interface Segregation
- Dependency Inversion
- When NOT to apply

---

## Single Responsibility Principle

"A module should have one, and only one, reason to change" — i.e., it serves one actor/concern.

**Smells**
- Class or function names containing "And", "Manager", "Processor", "Helper", "Util" with mixed contents.
- One unit does validation, business rules, persistence, and notification/formatting.
- Methods that use disjoint subsets of the class's fields (low cohesion).
- Changes for unrelated reasons (a tax rule change and an email template change) touch the same file.

**Before**
```python
class OrderService:
    def place_order(self, order):
        if not order.items: raise ValueError("empty")
        total = sum(i.price * i.qty for i in order.items) * 1.2
        db = psycopg2.connect(os.environ["DB_URL"])
        db.cursor().execute("INSERT INTO orders ...", (...))
        smtplib.SMTP("smtp.x.com").sendmail(..., f"Total: {total}")
```

**After**
```python
class OrderService:
    def __init__(self, repo: OrderRepository, notifier: Notifier, pricing: PricingPolicy):
        ...
    def place_order(self, order: Order) -> OrderId:
        order.validate()
        total = self.pricing.total(order)
        order_id = self.repo.save(order, total)
        self.notifier.order_placed(order, total)
        return order_id
```
Pricing, persistence, and notification can now change and be tested independently.

---

## Open/Closed Principle

Open for extension, closed for modification: adding a variant should mean adding code, not editing a central conditional.

**Smells**
- `switch (type)` / `if kind == ...` chains on a type tag, especially repeated in multiple places.
- Every new provider/format requires edits across several files.

**Before**
```ts
function exportReport(r: Report, format: string) {
  if (format === "csv") { ... }
  else if (format === "pdf") { ... }
  else if (format === "xlsx") { ... }
}
```

**After**
```ts
interface ReportExporter { export(r: Report): Buffer }
const exporters: Record<string, ReportExporter> = {
  csv: new CsvExporter(), pdf: new PdfExporter(), xlsx: new XlsxExporter(),
};
function exportReport(r: Report, format: string) {
  const exporter = exporters[format];
  if (!exporter) throw new UnsupportedFormatError(format);
  return exporter.export(r);
}
```
In Python/JS, a dict of plain functions is often enough — no class hierarchy required.

**Caveat:** a single `if/else` with two stable branches is fine. Apply OCP where variation is real.

---

## Liskov Substitution Principle

Anywhere a base type is used, any subtype must work without the caller knowing.

**Smells**
- Overrides that throw `NotImplementedError` / `UnsupportedOperationException`.
- Subclass narrows accepted inputs, widens thrown errors, or returns a different shape.
- Callers do `isinstance`/`instanceof` checks to special-case a subtype.
- Classic: `Square extends Rectangle` where setting width also changes height.

**Before**
```python
class Bird:
    def fly(self): ...
class Penguin(Bird):
    def fly(self): raise NotImplementedError
```

**After**
```python
class Bird: ...
class FlyingBird(Bird):
    def fly(self): ...
class Penguin(Bird): ...
```
Or model capability via composition/protocols instead of inheritance.

---

## Interface Segregation Principle

Clients shouldn't be forced to depend on methods they don't use.

**Smells**
- Large interfaces where implementers leave methods empty or throwing.
- A consumer takes a huge dependency but calls one method of it.

**Before**
```ts
interface Worker { work(): void; eat(): void; sleep(): void; }
class Robot implements Worker { eat() { throw ... } sleep() { throw ... } work() {...} }
```

**After**
```ts
interface Workable { work(): void }
interface Feedable { eat(): void }
class Robot implements Workable { work() {...} }
```
Also: functions should accept the narrowest type they need (e.g., `Iterable` rather than `List`, a `Readable` rather than the whole `FileSystem`).

---

## Dependency Inversion Principle

High-level policy should not depend on low-level details; both depend on abstractions, and the abstraction is owned by the high-level side.

**Smells**
- Constructing concrete infrastructure inside business logic (`new StripeClient()`, `requests.get`, `open(...)`).
- Hidden dependencies on globals, singletons, env vars, or the system clock.
- Tests require monkey-patching modules to run.

**Before**
```ts
class InvoiceService {
  async send(id: string) {
    const inv = await new PostgresInvoiceRepo().find(id);
    if (new Date() > inv.dueDate) inv.markOverdue();
    await new SendgridMailer().send(inv);
  }
}
```

**After**
```ts
class InvoiceService {
  constructor(private repo: InvoiceRepo, private mailer: Mailer, private clock: Clock) {}
  async send(id: string) {
    const inv = await this.repo.find(id);
    if (this.clock.now() > inv.dueDate) inv.markOverdue();
    await this.mailer.send(inv);
  }
}
```
Wire concrete implementations at the composition root (main, app factory, DI container). Constructor injection of plain parameters is usually enough — a DI framework is optional.

---

## When NOT to apply

- One implementation and no realistic second → no interface needed (most languages let you extract one later cheaply).
- Throwaway scripts, prototypes, small CLIs → readability beats layering.
- Splitting a cohesive 80-line class into five classes to "satisfy SRP" harms navigation.
- Patterns should remove pain you can name (hard to test, hard to extend, repeated switches). If you can't name the pain, don't add the pattern.
