# React: avoid unnecessary useEffect

Rule: use `useEffect` only to sync with third-party / external data or systems, such as fetching from an API (when the project has no data library), subscribing to a WebSocket or browser API, or driving a non-React widget (maps, charts, video players). Everything else has a better tool.

Why: an Effect runs after render, so deriving state in one causes an extra render, flashes stale UI, and adds bugs from missing or stale dependencies. Most Effects people write aren't syncing with anything external.

## Replace these with something else

| Instead of an Effect that... | Do this |
|---|---|
| Computes a value from props/state (`setFullName(first + ' ' + last)`) | Compute it during render: `const fullName = first + ' ' + last` |
| Caches an expensive computation | `useMemo` (only if it's actually expensive) |
| Resets all state when a prop changes | Pass a `key`: `<Profile key={userId} />` |
| Adjusts part of the state when a prop changes | Derive it during render, or store an ID and look up the item |
| Reacts to a user event (submit, click, POST request) | Put the logic in the event handler |
| Notifies the parent of a state change (`onChange`) | Call the callback in the same handler that sets state, or lift the state up |
| Chains Effects that each set state for the next | Compute everything in the event handler |
| Runs one-time app init (`checkAuth()`) | Module-level code or a top-level guard, not a component Effect |
| Subscribes to an external store | `useSyncExternalStore` |
| Fetches data where the project uses a data library | Use the library (TanStack Query, SWR, RTK Query, or router loaders) |

## When an Effect is right

When syncing with third-party data or an external system:
- Include every dependency; don't silence the exhaustive-deps lint rule.
- Return a cleanup (unsubscribe, disconnect, `AbortController.abort()`).
- When fetching, guard against race conditions (ignore stale responses via a flag or abort).
- Pull the Effect out into a named custom hook (`useChatConnection`, `useWeather`) so components stay declarative.

```tsx
function useWeather(city: string) {
  const [weather, setWeather] = useState<Weather | null>(null);
  useEffect(() => {
    const controller = new AbortController();
    fetchWeather(city, controller.signal).then(setWeather).catch(ignoreAbort);
    return () => controller.abort();
  }, [city]);
  return weather;
}
```

## In review mode

Flag any `useEffect` that isn't syncing with external/third-party data or a system outside React. Rate it Medium; rate it High if it causes visible bugs (stale UI, render loops, duplicate requests). Show the replacement from the table above.

---

# React: follow the SPA pattern

Build React apps as client-rendered single-page applications: one HTML shell, client-side routing, and data from APIs. This keeps deployment simple (static hosting plus an API) and keeps one clear line between the frontend and the backend.

## Structure
- **Build tool:** Vite, or whatever SPA setup the project already has. Don't add Next.js, Remix/React Router framework mode, or other SSR frameworks.
- **No server-only React:** no Server Components, `"use server"` actions, `getServerSideProps`, or SSR/streaming. All server work sits behind an API the SPA calls.
- **One entry point:** one `createRoot(...).render(<App />)` with app-wide providers (router, query client, theme, auth) set up there.
- **Folders by feature:** `src/features/<feature>/` (components, hooks, api, types), with shared pieces in `src/components`, `src/hooks`, `src/lib`. Routes stay thin and compose feature components.

## Routing
- Use a client router (React Router in data/library mode, or TanStack Router) with nested layout routes (`<Outlet />`) for shared shells.
- Navigate with `<Link>` / `navigate()`, never `<a href>` to internal pages or `window.location`, which reload the whole app.
- Lazy-load each route (`lazy()` / route `lazy`) so the first bundle stays small. Wrap them in `<Suspense>` with a fallback.
- Include a catch-all 404 route and an error boundary per route.
- Put shareable UI state in the URL (filters, tabs, pagination, selected IDs) with search params instead of component state.
- Hosting must rewrite unknown paths to `index.html` so deep links work. Mention it when setting up deployment.

## Data & state
- Fetch on the client through a data layer (TanStack Query/SWR or router loaders), wrapped in per-feature API modules (`features/orders/api.ts`). Components never call `fetch` directly. This is the "third-party data" case from the useEffect rule above.
- Server state lives in the query cache. Global client state (auth user, theme) lives in context or a small store. Everything else stays local to the component.
- Handle loading, error, and empty states for every data view.

## Security & config
- The bundle is public: only `VITE_*`-style public config goes into the client, never secrets or private API keys.
- Protect routes with an auth guard / layout route, but treat it as UX only. The API enforces authorization.
- Prefer httpOnly cookies for sessions. If tokens must live in JS, keep them in memory rather than `localStorage`.

## Existing projects
If the codebase already uses an SSR framework (e.g., Next.js App Router), don't rewrite it uninvited. Follow its conventions and point out that it isn't an SPA so the user can decide.

## In review mode
Flag full-page navigation for internal links, routes that aren't lazy-loaded, fetches inside components, secrets in client code, shareable state missing from the URL, and SSR/server-only APIs in an SPA codebase.
