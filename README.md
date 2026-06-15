# mails.com workspace

Local dev workspace for [mails.com](https://mails.com). Two independent repos live side by side here — commit and push changes to the correct GitHub repo for each project.

## Repositories

| Folder | GitHub | Deploy | Local port |
| --- | --- | --- | --- |
| `mails-backend/` | [mails-com/back](https://github.com/mails-com/back) | Fly.io (`mails-back.fly.dev`) | `:3000` |
| `mails-frontend/` | [mails-com/front](https://github.com/mails-com/front) | Cloudflare Workers (`front.aitor.workers.dev`) | `:3001` |

This folder (`mails.com/`) is a docs-only meta-repo. It does not track the child repos — each subfolder has its own `.git`, hooks, CI, and deploy pipeline.

## First-time setup

```bash
mkdir mails.com && cd mails.com
git clone git@github.com:mails-com/workspace.git .
git clone git@github.com:mails-com/back.git mails-backend
git clone git@github.com:mails-com/front.git mails-frontend
```

## Where to read docs

| Topic | Backend | Frontend |
| --- | --- | --- |
| Full README | [`mails-backend/README.md`](mails-backend/README.md) | [`mails-frontend/README.md`](mails-frontend/README.md) |
| Contributing / hooks | Lefthook — see backend README | [`mails-frontend/CONTRIBUTING.md`](mails-frontend/CONTRIBUTING.md) |
| Cursor rules | [`mails-backend/.cursor/rules/project-stack.mdc`](mails-backend/.cursor/rules/project-stack.mdc) | — |
| Env template | `mails-backend/.env.example` | `mails-frontend/.env.example` → copy to `.env.local` |

## Run both locally

**Prerequisites:** Go 1.26+, Node 20+, PostgreSQL, Google OAuth credentials.

### Backend (terminal 1)

```bash
cd mails-backend
createdb mails                    # once
cp .env.example .env              # fill DATABASE_URL + Google OAuth
lefthook install                  # git hooks
sqlc generate                     # after clone or SQL query changes
air                               # → http://localhost:3000
```

Install dev tools once — see [`mails-backend/README.md`](mails-backend/README.md) (Air, sqlc, golangci-lint v2, Lefthook, goose).

### Frontend (terminal 2)

```bash
cd mails-frontend
npm install                       # husky hooks via prepare script
cp .env.example .env.local        # VITE_API_URL=http://localhost:3000
npm run dev                       # → http://localhost:3001
```

### Verify

Open `http://localhost:3001`, sign in with Google → lands on `/dashboard`. Backend CORS expects the frontend on `:3001`; session cookies are same-site in dev.

```bash
curl localhost:3000/ping          # → {"status":"ok"}
curl localhost:3000/health        # → {"status":"ok","db":"ok"}
```

## Auth / integration

- **Login:** full browser redirect to `{API_URL}/auth/google` (not `fetch`)
- **API calls:** `fetch("{API_URL}/...", { credentials: "include" })`
- **Prod:** frontend (Workers) and API (Fly) are cross-site → backend uses `SameSite=None; Secure` cookies

## Quality gates before PR

- **Backend:** Lefthook on commit; CI on `main` (sqlc → build → vet → lint → deploy)
- **Frontend:** `npm run validate` (format, lint, i18n, seo, typecheck, test, build)
