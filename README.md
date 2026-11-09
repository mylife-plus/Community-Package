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
  screens: [ // optional: the Problem form's screen picker
    ScreenNode('Inventory', children: [
      ScreenNode('Sell Items', children: [ScreenNode('Add Items')]),
    ]),
    ScreenNode('Settings'),
  ],
));

// MaterialApp / GetMaterialApp (optional; without it the labels are English)
localizationsDelegates: [CommunityLocalizations.delegate, ...],

// Settings rows
onTap: () => CommunityPackage.openCommunity(context),   // "Community app"
onTap: () => CommunityPackage.openNewFeedback(context), // "Give feedback"
```

- Labels come in English, German, Spanish, French and Portuguese (Portugal), picked by the app's language code (`de_AT` gets German, `pt_BR` Portuguese). Other languages, and apps without the delegate, get English.
- Without `privacyPolicyUrl` the privacy notice leaves out the "Read our full Privacy Policy" sentence.
- `screens` lists the app's screens, top level first, in the order they should appear. Write the names in English: they are saved with each Problem as a path (`Inventory > Sell Items > Add Items`), so everyone reads the same names in every language. Give each screen a `label` (`label: (context) => ...`) to show its title in the app's language in the picker and on Problem cards; the saved path stays in English, and screens without a label show their name. The picker adds the package's own screens under "Community", with their own labels. Without `screens` the Problem form asks no screen.
- Problems carry the OS version, the app version and the phone model, read with `device_info_plus` and `package_info_plus`. Both are kept below the versions that need Android Gradle Plugin 8.12.1.
- The anonymous ID is created only after the user agrees to the privacy notice. iOS keeps it in the Keychain; Android derives it from a SHA-256 hash of ANDROID_ID. Neither needs extra setup.
- `flutter_secure_storage` 11 (picked on Dart 3.8+) and `android_id` 0.6 (picked on Flutter 3.47+) need Android `minSdk` 24.

## Backend

Requires Node.js and a Cloudflare account with `npx wrangler login` done.

### Set up your own backend

The repository holds no account, database or Worker IDs. `backend/wrangler.example.jsonc` is a template; your own copy, `backend/wrangler.jsonc`, is git-ignored.

```bash
cd backend
npm install
cp wrangler.example.jsonc wrangler.jsonc

# Create the database. Add --jurisdiction eu to keep the data in the EU
# (it can only be set when the database is created).
npx wrangler d1 create community
```

In `wrangler.jsonc`, set `name` (your Worker's name) and put the `database_name` and `database_id` that `d1 create` printed into `d1_databases`. Then:

```bash
npx wrangler d1 migrations apply community --remote

# One row per app that uses the package. The id is the app's `appId`.
npx wrangler d1 execute community --remote \
  --command "INSERT INTO apps (id, name) VALUES ('myapp', 'My App')"

npm run deploy      # prints https://<name>.<your-subdomain>.workers.dev
```

Use that URL as `backendUrl` in the app. Check it with `GET /v1/health`.

`seed/dev.sql` fills a database with invented sample data for development. It deletes everything first, so never run it on a database in use.

Each rate limit's `namespace_id` must be unique within your Cloudflare account; change them if another Worker already uses 1001–1006.

### Develop

```bash
npm run typecheck   # TypeScript, src and tests
npm test            # Vitest in the Workers runtime, on wrangler.example.jsonc
npm run dev         # local Worker on http://localhost:8787
npm run deploy      # deploy with your wrangler.jsonc
```

Change bindings or limits in both `wrangler.example.jsonc` and your `wrangler.jsonc`: the tests stop with an error when the two differ in anything but the Worker name and the database. Run `npm run cf-typegen` after such a change and commit the updated `worker-configuration.d.ts`.

Writes are rate-limited per anonymous ID and per IP with the Workers Rate Limiting binding: posts 10 per minute per ID and 60 per IP, hearts 30 per minute per ID and 120 per IP, comments 10 per minute per ID and 60 per IP, each counted apart so hearts or comments never block a post. The limits are set in `ratelimits` in the wrangler config.

### Endpoints

Feedback routes need `X-App-Id`; writes also need `X-Anon-Id`.

| Method | Path | Result |
|---|---|---|
| GET | `/v1/health` | `{"status":"ok","db":"ok"}` when the Worker can reach D1 |
| GET | `/v1/feedback` | 20 items and a `nextCursor`. Optional: `sort` (`newest`, `oldest`, `reactions`, `comments`), `type` and `status` (comma lists), `q` (words in the text, or a number such as `21` or `#21`), `cursor` |
| POST | `/v1/feedback` | Creates feedback, returns the item |
| PUT / DELETE | `/v1/feedback/:number/reaction` | Heart on / off, returns the item |

Errors always use this shape:

```json
{ "error": { "code": "not_found", "message": "Not found" } }
```
