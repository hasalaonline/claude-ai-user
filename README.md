# claude-ai-user

Let Claude use your product every night like a real user, instead of scripting
more E2E flows.

Tasklet (this repo's app) is a tiny project tracker with a few realistic bugs
planted in it. A scripted Playwright test covers the happy path and passes.
Every night, a GitHub Actions workflow also runs `claude -p` with the Playwright
MCP server, once per **persona**. Each persona describes a person and a goal,
not a list of steps. Claude uses the app as that person, then returns a bug
report as JSON, which the workflow turns into GitHub issues and a run summary.

## Layout

```text
server.js, public/            the demo app (no dependencies)
tests/happy-path.spec.js      the scripted E2E test
qa/personas/*.md              who the AI user pretends to be
qa/explore.md                 shared instructions for every persona
qa/report-schema.json         the JSON shape of a bug report
qa/run-persona.sh             runs claude -p for one persona
qa/file-issues.sh             reports -> GitHub issues + run summary
.github/workflows/ai-user.yml nightly schedule
```

## Run it locally

You need Node 22, Google Chrome and Claude Code signed in.

```bash
npm start &
bash qa/run-persona.sh qa/personas/impatient-clicker.md
cat reports/impatient-clicker.report.json
```

## Run it nightly in GitHub Actions

1. Run `claude setup-token` and save the token as a repository secret named
   `CLAUDE_CODE_OAUTH_TOKEN` (or use `ANTHROPIC_API_KEY` with a Console key).
2. Push. The workflow runs at 1:00 AM Sri Lanka time, or start it by hand from
   the Actions tab with **Run workflow**.

<details>
<summary>Spoiler: the planted bugs</summary>

1. The form says "At least 8 characters", but an 8-character password is rejected.
2. Double-clicking "Create account" creates the account, then shows
   "This email is already registered" and never leaves the page.
3. Saving a project with an empty name creates a blank project.
4. Deleting a project fails (the request uses the name instead of the id);
   the row stays and an error appears in the console.
5. On a phone-sized screen, the "+ New project" button is pushed off-screen.

</details>
