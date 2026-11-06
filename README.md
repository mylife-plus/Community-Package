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

### Adding it to an app

```dart
// At startup
await CommunityPackage.init(const CommunityConfig(
  backendUrl: 'https://<worker>.workers.dev',
  appId: 'inventory',
  privacyPolicyUrl: 'https://example.com/privacy', // optional
));

// MaterialApp / GetMaterialApp (optional; without it the labels are English)
localizationsDelegates: [CommunityLocalizations.delegate, ...],

// Settings row
onTap: () => CommunityPackage.openCommunity(context),
```

- Without `privacyPolicyUrl` the privacy notice leaves out the "Read our full Privacy Policy" sentence.
- The anonymous ID is created only after the user agrees to the privacy notice. iOS keeps it in the Keychain; Android derives it from a SHA-256 hash of ANDROID_ID. Neither needs extra setup.
- `flutter_secure_storage` 11 (picked on Dart 3.8+) and `android_id` 0.6 (picked on Flutter 3.47+) need Android `minSdk` 24.

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
