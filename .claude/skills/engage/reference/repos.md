# Repos

Repos a default Coder workspace clones into `~/workspace`. Their README is the authority; this table is a starting point.

Tilt serves every app from `~/workspace/<repo>`, so the running apps show whatever branch that checkout has. A worktree elsewhere is invisible to Tilt and to Verify. Check the resources with `/usr/local/bin/tilt get uiresources`. The `tilt` on PATH is an unrelated Ruby gem.

| Repo | What it is | Default branch | Main languages |
|---|---|---|---|
| coyote | Rails app and API. Backend for lyra-coyote: routes, billing, the Intacct push | staging | Ruby, TypeScript |
| lyra | Nx monorepo of React frontends, including lyra-coyote and the customer portal | staging | TypeScript, Terraform |
| falco | Rails app for waste collection dispatch and the driver app backend | staging | Ruby, TypeScript |
| falco-web-lite | Rails 6.1 web client for drivers (Tilt resource `driver-app`) | staging | Ruby, TypeScript |
| beeline | Routing algorithms: schedules, TSP solving, simulations | staging | Python |
| dsl | Design System Library: the shared React components lyra uses | main | TypeScript |
| gemini | GraphQL API over coyote and falco | staging | TypeScript |
| cetus | Federated graph monorepo that serves the customer portal | staging | TypeScript, Terraform |
| pdf-render-service | PDF rendering microservice | staging | Ruby |
| platform (compology) | Compology's web and API services | main | JavaScript, TypeScript |

## Not cloned by default

Clone these when a ticket needs them: `gh repo clone RoadRunnerEngineering/<repo> ~/workspace/<repo>`.

| Repo | What it is |
|---|---|
| csdev | The Coder workspace template |
| rr-devops | Shared infrastructure and deployment |
| coyote-devops | Coyote deployment |
| falco-devops | Falco deployment |
| falco-web-lite-devops | falco-web-lite deployment |
