# Rejected ideas

Ideas the user already turned down, or that conflict with how this framework works. Reflect reads this file before it proposes anything, and lists a match under "Dropped".

| Idea | Why not |
|---|---|
| Chrome DevTools MCP, or a tunnel to Chrome on the Mac | The org manages MCP access through mintmcp, which does not offer it. Headless Chromium in the workspace is enough. |
| Figma comparison, or image-diff parity checks | Designs come as Claude artifacts, design export zips and screenshots. |
| Moving these skills to the private rr-skills marketplace | The dotfiles repo must stay public: Coder loads it into a workspace before anyone logs in. |
| A watcher mod that pings the orchestrator about workers | Worker callbacks plus a background `herdr agent wait` replaced it. |
| `--disallowedTools` deny rules on workers | Rules in briefs replaced them. |
| Multi-model review panels | Only Claude runs here. |
| Ready-for-review PRs, auto-merge, bottom-up landing | PRs stay in draft for the user. |
| Posting PR replies or comments | Replies are drafted, never posted, unless the user asks. |
| A fresh agent for every round | Workers idle under an hour are reused while their prompt cache is warm. |
| A worktree or VM per worker | Tilt serves only the `~/workspace/<repo>` checkout, so Verify cannot see a worktree. |
| Vertical slices with red-green tests on every slice | The contract split works, and extra tests conflict with the test-quality rule. |
| Blocking a ticket on missing acceptance criteria | Most past tickets had none. Planalysis writes them as the verification recipe. |
| Asking the user about every screen detail | Most late changes were presentation details. `reference/sufficiency.md` defaults them and sends them to product in one comment. |
| One stop for the user per change request | Requesters usually left the call to the developer. `reference/change-requests.md` decides by class. |
| Datadog in Verify or Review | No past ticket showed it helping in the dev loop. It pays in Planalysis and after deploy. |
| A full regression pass every round | It conflicts with converging on showstoppers. Verify's probes target the defect classes instead. |
| Organization-specific rules in Engage | Engage is public. They belong in the private `engage-org` overlay. |
