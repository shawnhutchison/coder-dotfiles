---
name: verify-ui
description: Verify a ticket or change end to end in this Coder workspace by driving the running Tilt apps (coyote, lyra-coyote, falco, driver-app / falco-web-lite, lyra-customer-portal) in headless Chromium with Playwright, logged in as the dev test user. Checks the ticket's acceptance criteria, the frontend/backend API contract, resulting database state, conformance to a design (Claude artifact, artifact export or screenshot), screenshots, console errors, failed requests and server logs. Use this after implementing or fixing anything a user or API client would see, before reporting the work as done, and whenever asked to verify, QA, test, reproduce, or screenshot a ticket, PR or behavior in one of these apps, even if the request doesn't say "Playwright" or "browser".
---

# Verify UI

Unit tests prove the code does what you think. This skill proves the running system does what the ticket asked: the real frontend, talking to the real backend, writing to the real dev database. Every app runs under Tilt in this workspace, so you can log in and exercise it yourself, headless, without the user.

The loop is:

1. Turn the request into numbered criteria.
2. Find the app in Tilt.
3. Write a short Playwright script that checks each criterion.
4. Run it and read the evidence.
5. Check database state where the criteria imply a write.
6. Compare against the design, if there is one.
7. Report per criterion.

## Two modes

- **Verifying your own change.** If something fails, fix the code, let Tilt reload, and rerun the same script until every criterion passes.
- **Verification only.** The user asked you to check a ticket, PR or behavior. Do not change code. Report what you found, including bugs, with enough detail for someone else to fix them.

## 1. Turn the request into criteria

Every check needs a list of things that must be true. Write it down before you script anything, and number it. The report refers back to these numbers.

- **From a Jira ticket.** The workspace name is the ticket key: `echo $CODER_WORKSPACE_NAME`. Fetch the ticket with the Atlassian MCP's `getJiraIssue`. Request the `summary`, `description`, `comment` and `issuelinks` fields in markdown format. If you need the `cloudId`, call `getAccessibleAtlassianResources`.
  - Tickets have no dedicated acceptance-criteria field. Criteria live in the description's ask, validation and expected-behavior sections.
  - Read every comment. Later comments often de-scope items or answer open questions, and the latest decision wins. Leave out criteria that a comment removed, and say so.
  - Some items are still open questions in the ticket. List them as "not verifiable: undecided" instead of guessing an answer.
- **From a Claude artifact.** Tickets often link a design or QA-plan artifact at `claude.ai/artifact/...` or `claude.ai/code/artifact/...`. Read it with the Artifact tool. A QA plan's test cases are criteria as written. A design's visible labels, columns, fields, states and messages are criteria too: see "Compare against the design".
- **From a PR or diff.** Derive the criteria from what the change claims to do: the PR description, the commit messages and the changed endpoints and components.
- **From a plain request.** Restate it as criteria.

If the criteria are ambiguous enough that different readings lead to different checks, ask the user before scripting.

## 2. Find the app in Tilt

Tilt is the source of truth for resource names, URLs and whether a service is up. Call it by full path: `tilt` on `PATH` resolves to an unrelated Ruby gem.

```bash
/usr/local/bin/tilt get uiresources -o json \
  | jq -r '.items[] | select(.status.endpointLinks) | [.metadata.name, .status.runtimeStatus, .status.endpointLinks[0].url] | @tsv'
```

App URLs follow `$VSCODE_PROXY_URI` with `{{port}}` replaced by the app's port, the same rule the Tiltfile uses. Ports are shared publicly, so no Coder login is involved. Only the app's own login is.

If a resource you need is not `ok`, stop and say so. A check against a down app tells you nothing.

## 3. Log in

Credentials live in the repos' `.env` files, which every Coder workspace already has. The script reads them at run time. Never print, log or copy their values, and never write them into any file.

| Tilt resource | Port | Repo `.env` | Login path | Username | Password |
|---|---|---|---|---|---|
| `coyote` | 9000 | coyote | `/users/sign_in` | `E2E_USER_EMAIL` | `E2E_USER_PASSWORD` |
| `lyra-coyote` | 4301 | lyra | `/` | `E2E_USER_EMAIL` | `E2E_USER_PASSWORD` |
| `falco` | 7000 | falco | `/users/sign_in` | first seeded email in `falco/db/seeds.rb` | `DEV_USER_PASSWORD` |
| `driver-app` (falco-web-lite) | 8000 | falco | `/login` | first seeded email in `falco/db/seeds.rb` | `DEV_USER_PASSWORD` |
| `lyra-customer-portal` | 4302 | lyra | `/`, redirects to Auth0 | `CUSTOMER_PORTAL_E2E_TEST_USER` | `CUSTOMER_PORTAL_E2E_USER_PASS` |

- Falco's `/login` page shows an SSO button. Go straight to `/users/sign_in` instead.
- Do not reuse the repos' own e2e `login()` helpers. They target staging SSO and fail against these dev logins.
- lyra-coyote's API is coyote on port 9000. Its session works for coyote's `/api/...` calls too.
- For an app not in the table, open its URL, read the form, and find a dev user in that repo's `.env` or `db/seeds.rb`.

## 4. Write and run the check

Write the script in `/tmp/verify-ui/`, even if your session has a scratchpad directory. The user looks for evidence there, and the folder is outside every repo, so nothing ends up in a commit. Copy the template, set `APP`, and write `steps()`. Use lyra's Playwright install for every app; it works against all of them.

`steps()` receives:

- `page`: the logged-in page.
- `shot(name)`: saves a full-page screenshot.
- `note(key, value)`: records evidence such as row counts, headers or IDs in the report.
- `BASE`: the app's URL.
- `context`: the browser context, for opening a second page such as a design.
- `OUT`: the run's output folder.
- `apiHeaders()`: auth headers for calling the API directly. See "Backend-only tickets".

Use `expect()` for each criterion so a failure stops the run with a clear message, and name the criterion in the message.

```js
// /tmp/verify-ui/check.cjs   run: node /tmp/verify-ui/check.cjs
const W = '/home/coder/workspace';
const { chromium, expect } = require(`${W}/lyra/node_modules/@playwright/test`);
const dotenv = require(`${W}/lyra/node_modules/dotenv`);
const fs = require('fs');

const APP = 'coyote'; // Tilt resource name from the login table
const PORTS = { coyote: 9000, 'lyra-coyote': 4301, falco: 7000, 'driver-app': 8000, 'lyra-customer-portal': 4302 };
const url = port => process.env.VSCODE_PROXY_URI.replace('{{port}}', port);
const BASE = url(PORTS[APP]);
const OUT = `/tmp/verify-ui/${APP}-${Date.now()}`;
// API paths whose request and response bodies are recorded, for contract checks.
const WATCH = /^\/api\/|\/graphql$/;

const env = repo => dotenv.parse(fs.readFileSync(`${W}/${repo}/.env`));
const falcoUser = () => fs.readFileSync(`${W}/falco/db/seeds.rb`, 'utf8').match(/email: '([^']+)'/)[1];

async function login(page) {
  if (APP === 'coyote') {
    const e = env('coyote');
    await page.goto(`${BASE}/users/sign_in`);
    await page.fill('input[name="user[email]"]', e.E2E_USER_EMAIL);
    await page.fill('input[name="user[password]"]', e.E2E_USER_PASSWORD);
    await page.click('input[type=submit]');
    await page.waitForURL(u => !u.pathname.includes('sign_in'));
  } else if (APP === 'lyra-coyote') {
    const e = env('lyra');
    await page.goto(BASE);
    await page.fill('input[name=email]', e.E2E_USER_EMAIL);
    await page.fill('input[name=password]', e.E2E_USER_PASSWORD);
    await page.click('button[type=submit]');
    await page.locator('input[name=password]').waitFor({ state: 'detached' });
  } else if (APP === 'falco' || APP === 'driver-app') {
    await page.goto(`${BASE}${APP === 'falco' ? '/users/sign_in' : '/login'}`);
    await page.fill('input[name=email]', falcoUser());
    await page.fill('input[name=password]', env('falco').DEV_USER_PASSWORD);
    await page.click('input[type=submit]');
    await page.waitForURL(u => !/sign_in|login/.test(u.pathname));
  } else if (APP === 'lyra-customer-portal') {
    const e = env('lyra');
    await page.goto(BASE);
    await page.getByLabel('Email').fill(e.CUSTOMER_PORTAL_E2E_TEST_USER);
    await page.getByLabel('Password').fill(e.CUSTOMER_PORTAL_E2E_USER_PASS);
    await page.click('button[type=submit]');
    await page.waitForURL(u => u.href.startsWith(BASE));
  }
  await page.waitForLoadState('networkidle');
}

async function steps({ page, context, shot, note, BASE, OUT, apiHeaders }) {
  await shot('after-login');
}

(async () => {
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  await context.tracing.start({ screenshots: true, snapshots: true });
  const page = await context.newPage();
  const report = { app: APP, notes: {}, api: [], consoleErrors: [], pageErrors: [], failedRequests: [], screenshots: [] };
  const cut = (s, n) => (s && s.length > n ? `${s.slice(0, n)}...` : s);
  page.on('console', m => m.type() === 'error' && report.consoleErrors.push(cut(m.text(), 300)));
  page.on('pageerror', e => report.pageErrors.push(cut(e.message, 300)));
  page.on('requestfailed', r => report.failedRequests.push(`FAILED ${r.method()} ${cut(r.url(), 200)} ${r.failure()?.errorText}`));
  let bearer; // the app's own API token, reused by apiHeaders(); never written to the report
  page.on('response', async r => {
    if (r.status() >= 400) report.failedRequests.push(`${r.status()} ${r.request().method()} ${cut(r.url(), 200)}`);
    const u = new URL(r.url());
    if (!WATCH.test(u.pathname)) return;
    const auth = r.request().headers().authorization;
    if (auth?.startsWith('Bearer ')) bearer = auth;
    const call = { method: r.request().method(), path: cut(u.pathname + u.search, 200), status: r.status() };
    if (r.request().postData()) call.requestBody = cut(r.request().postData(), 1000);
    try { call.responseBody = cut(await r.text(), 1500); } catch {}
    report.api.push(call);
  });
  let n = 0;
  const shot = async name => {
    const path = `${OUT}/${String(++n).padStart(2, '0')}-${name}.png`;
    await page.screenshot({ path, fullPage: true });
    report.screenshots.push(path);
  };
  const note = (key, value) => { report.notes[key] = value; };
  // lyra apps send a Bearer token; Rails-rendered pages need the CSRF token for writes.
  const apiHeaders = async () => {
    if (bearer) return { Authorization: bearer };
    const csrf = await page.locator('meta[name="csrf-token"]').getAttribute('content', { timeout: 2000 }).catch(() => null);
    return csrf ? { 'X-CSRF-Token': csrf } : {};
  };
  try {
    await login(page);
    await steps({ page, context, shot, note, BASE, OUT, apiHeaders });
    report.result = 'assertions passed';
  } catch (err) {
    report.result = 'assertion failed';
    report.error = err.message.split('\n').slice(0, 8).join('\n');
    await shot('failure').catch(() => {});
  }
  report.finalUrl = page.url();
  await context.tracing.stop({ path: `${OUT}/trace.zip` });
  report.trace = `${OUT}/trace.zip`;
  await browser.close();
  fs.writeFileSync(`${OUT}/report.json`, JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ ...report, api: report.api.map(c => `${c.status} ${c.method} ${c.path}`) }, null, 2));
  process.exit(report.result === 'assertions passed' ? 0 : 1);
})();
```

The console output lists API calls as one line each. The full request and response bodies are in `report.json` in the output folder.

If `chromium.launch()` fails with `Executable doesn't exist`, the browser for lyra's Playwright version has not been downloaded in this workspace yet. Download it once, then rerun:

```bash
cd /home/coder/workspace/lyra && pnpm exec playwright install chromium
```

Skip that step when the launch works. The download is about 110 MB and persists across workspace restarts.

### Checking the frontend/backend contract

A page can render fine while sending the wrong payload, or while ignoring a field the backend renamed. When a criterion involves data moving between frontend and backend, assert on the call itself, not only on what the page shows. Wait for the response in the same breath as the action that triggers it:

```js
const [resp] = await Promise.all([
  page.waitForResponse(r => r.url().includes('/api/camera_routes/') && r.request().method() === 'PATCH'),
  page.getByRole('button', { name: 'Save' }).click(),
]);
expect(resp.status(), 'criterion 2: update succeeds').toBe(200);
expect(resp.request().postDataJSON(), 'criterion 2: UI sends the new due date').toMatchObject({ due_date: '2026-10-20' });
expect(await resp.json(), 'criterion 2: response echoes the change').toMatchObject({ due_date: '2026-10-20' });
```

Check the error paths too. Trigger a validation the ticket describes and assert the status code, the error body, and that the page shows the message to the user.

### Backend-only tickets

When the ticket has no UI yet, call the API directly with the logged-in session. `page.request` shares the page's cookies, and `apiHeaders()` adds the auth the app itself uses: the Bearer token lyra apps send, or the CSRF token on Rails-rendered pages. In lyra-coyote, open any page that calls the API first, so the token has been seen:

```js
const resp = await page.request.patch(`${url(9000)}/api/...`, {
  headers: await apiHeaders(),
  data: { /* payload from the ticket */ },
});
note('update response', { status: resp.status(), body: await resp.json() });
```

This is a contract check in its own right: it proves the endpoint accepts what the future frontend will send and returns what it will need.

## 5. Check database state

When a criterion says something is saved, changed or rejected, confirm it in the database. The UI can show success while the write went somewhere else, or not at all. Query through the Rails models, read-only. `while_preventing_writes` makes any accidental write raise `ActiveRecord::ReadOnlyError` instead of changing data.

```bash
# coyote (also the backend for lyra-coyote)
cd /home/coder/workspace/coyote && dotenvx run -q -f .env -- bin/rails runner \
  'ActiveRecord::Base.while_preventing_writes { r = CameraRoute.find(123); puts r.slice(:state, :due_date).to_json }'

# falco (driver-app logs in with falco's users; check its data here)
cd /home/coder/workspace/falco && bundle exec rails runner \
  'ActiveRecord::Base.while_preventing_writes { puts Profile.count }'
```

Each run takes about 10 seconds. Print only the fields the criterion needs. Never print user records wholesale, because they include personal data and password digests.

The lyra-customer-portal backend is the Cetus `cp-*` GraphQL services. Check its state through their GraphQL responses in `report.api` instead.

Your checks write to the shared dev database. Prefer records you created during the run, and list in the report anything you changed.

## 6. Read the evidence

- **Look at the screenshots** with the Read tool. A passing assertion does not mean the page looks right. Layout breaks, wrong data and empty states only show up visually.
- **Separate noise from signal.** Every app is noisy at baseline, so a nonzero error count means nothing by itself. Run the template once with `steps()` navigating to the same page but asserting nothing, ideally on `main`, to see that page's normal noise. Seen at baseline in these apps:
  - React dev builds log `Warning: ...` messages as console errors.
  - Google Tag Manager and Google Analytics requests fail with `ERR_BLOCKED_BY_ORB` or `ERR_ABORTED`.
  - A 401 on the current-user or auth-refresh endpoint fires before login completes.
  - falco's home page throws page errors and a 500 on `/routes/live`.
- **Find the server-side cause of any 5xx.** Read the Tilt log for the backend, find the request by its path, and read the block that follows, which holds the exception and backtrace:

  ```bash
  /usr/local/bin/tilt logs coyote --since 10m | grep -n -A 40 'Started GET "/api/bills/dashboard' | grep -m1 -B 40 -A 15 'Completed 5'
  ```

  lyra-coyote's backend is `coyote`. driver-app's backend is `falco`. lyra-customer-portal's backend is the `cp-*` resources.

## 7. Compare against the design

When the user or the ticket provides a design, check that the built UI matches it. Designs arrive in three forms:

- **Screenshots or images.** Read them with the Read tool and compare them with your app screenshots. Take the app screenshots at a viewport close to the image's size.
- **A zip export of an artifact.** Unpack it into its own new, empty folder, such as `/tmp/verify-ui/design-<name>/`, and render the `index.html` or main `.html` file it contains. Relative paths to its CSS, scripts and images resolve from that folder.
- **A Claude artifact link.** Steps 1 and 2 below.

HTML designs are working pages, so you can render them in the same browser at the same viewport and compare the two directly.

1. Read the artifact with the Artifact tool, `action: "read"` and its `url`. For an artifact the user owns, the result names a local file holding the full HTML. If the result is only a summary, the artifact belongs to someone else. Then compare against what the summary describes, and say that you could not compare screenshots.
2. Render the HTML inside `steps()`, next to the app page:

   ```js
   const design = await context.newPage();
   // the HTML file named by the artifact read, or the one unpacked from a zip export
   await design.goto('file:///path/to/design.html', { waitUntil: 'networkidle' });
   await design.screenshot({ path: `${OUT}/design-default.png`, fullPage: true });
   ```

   Designs often show several states, such as tabs, modals, empty and error states. Click through the design to each state the ticket covers, and screenshot the app in the same state.
3. Read each design screenshot and its app screenshot together, and list the differences by area:
   - **Structure:** missing or extra sections, components and controls, and their order.
   - **Content:** labels, column headers, field names, button text, messages and copy.
   - **States:** empty, loading, error and validation states the design defines.
   - **Visual:** spacing, alignment and color, only where the difference is clear.
4. Turn exact text into assertions. The design HTML is precise for labels, headers and messages, so assert them with `expect(page.getByText(...))` instead of comparing by eye.

Design mockups use made-up data and their own fonts and colors. Ignore data values. Judge visual style only against the app's existing components, unless the ticket says the design defines new styling. Report each difference as matches, differs or missing, with both screenshot paths.

## 8. Report

Give a verdict first, using exactly one of these:

- **PASS:** every criterion passed, and no new page error or 5xx appeared on the pages you checked.
- **PASS WITH ISSUES:** every criterion passed, but you found a page error, 5xx or visual defect the criteria don't cover. Describe each issue and whether it existed before the change.
- **FAIL:** at least one criterion failed.

Then go through each numbered criterion: pass, fail, or not verifiable, plus the evidence. Evidence can be a screenshot path, an API call with its status and the relevant fields, a database value, or a log line. After that:

- Steps a person can repeat.
- Data you created or changed.
- What you did not check, such as other roles, mobile widths, or edge-case data.

Mention the trace so the user can replay the run step by step with DOM snapshots and network calls:

```bash
cd /home/coder/workspace/lyra && pnpm exec playwright show-trace --host 0.0.0.0 --port 9323 <trace.zip>
```

They open the `$VSCODE_PROXY_URI` URL for port 9323. Run the trace viewer in the background only when the user asks for it.

## When a check should become a test

The script is throwaway evidence. If the behavior deserves a permanent regression test, propose adding a spec to the repo's own suite: `falco/playwright_tests`, `coyote/playwright_tests`, `lyra/apps/coyote-e2e` or `lyra/apps/customer-portal-e2e`. Those suites show up in Tilt's `falco-playwright`, `coyote-playwright` and `lyra-coyote-playwright` UI modes, where the user can watch them run. Ask before adding one, because it changes the diff under review.
