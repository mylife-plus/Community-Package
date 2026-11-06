# community_package

Community feedback screens for the My-life Plus apps (SpaceTime, Inventory, money): feedback list, new feedback, comments, progress, costs and tips. The package talks to a Cloudflare Worker in `backend/`.

Work in progress. Setup and configuration steps for host apps will be added here as the screens land.

## Repository layout

| Path | Contents |
|---|---|
| `lib/` | The Flutter package |
| `test/` | Package tests |
| `backend/` | Cloudflare Worker (Hono, TypeScript), D1 database |

## Package

```bash
flutter pub get
flutter analyze lib test
flutter test
```

Requires Dart `>=3.7.0`.

## Backend

Requires Node.js and a Cloudflare account with `wrangler login` done.

```bash
cd backend
npm install
npm run typecheck   # TypeScript, src and tests
npm test            # Vitest in the Workers runtime
npm run dev         # local Worker on http://localhost:8787
npm run deploy      # deploy to Cloudflare
```

Run `npm run cf-typegen` after changing `wrangler.jsonc`, and commit the updated `worker-configuration.d.ts`.

### Endpoints

| Method | Path | Result |
|---|---|---|
| GET | `/v1/health` | `{"status":"ok","db":"ok"}` when the Worker can reach D1 |

Errors always use this shape:

```json
{ "error": { "code": "not_found", "message": "Not found" } }
```
