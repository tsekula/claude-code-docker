# Claude Code Docker Container with tmux Persistence

## Context

Tom wants to run long-running Claude Code sessions in a Docker container on his home server `lilstinker`. He already has Tailscale set up and can SSH into `lilstinker` from outside the network. Once on `lilstinker`, he accesses the Claude Code container via `docker exec`. tmux provides session persistence — Claude Code keeps running when he disconnects from SSH.

**No SSH server is needed inside the container.** Access is via `docker exec` from the host.

---

## Workflow

```
Tom's laptop  --[Tailscale SSH]-->  lilstinker  --[docker exec + tmux]-->  claude-code container
```

Connect/reconnect:
```bash
# On lilstinker (or via SSH):
docker exec -it claude-code tmux new-session -A -s main
# Detach: Ctrl+B, D  — Claude Code keeps running in container
# Reconnect: same command — re-attaches to existing session
```

---

## Files

```
dev-container/
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh
├── .env.example
└── .gitignore
```

---

## Implementation

### 1. `Dockerfile`

Base: `ubuntu:24.04`

1. Install: `tmux`, `curl`, `git`, `ca-certificates`, `locales`, `nano`, `procps`, `sudo`
2. Set locale to `en_US.UTF-8`
3. Install Node.js LTS via NodeSource
4. Install Claude Code: `npm install -g @anthropic-ai/claude-code`
5. Create user `claude` with UID 1000 — matches Tom's UID on `lilstinker`, avoiding permission issues on bind-mounted projects
6. Seed `.bashrc` to source `~/.env_secrets` (for `ANTHROPIC_API_KEY`)
7. `COPY entrypoint.sh /entrypoint.sh` + `chmod +x`
8. `ENTRYPOINT ["/entrypoint.sh"]`

### 2. `entrypoint.sh`

Runs as root on every container start (idempotent):

1. Write `ANTHROPIC_API_KEY` to `/home/claude/.env_secrets` (chmod 600, chown claude) — available in all tmux windows/panes
2. `chown -R claude:claude /home/claude`
3. `exec sleep infinity` — keeps container alive; access via `docker exec`

### 3. `docker-compose.yml`

- No ports exposed — access only via `docker exec`
- Named volume `claude-code_home` for `/home/claude` — persists Claude Code config, history, and auth tokens across container restarts and rebuilds
- Bind mount host projects at `/home/claude/projects` — UID 1000 match means no permission issues
- `restart: unless-stopped` — survives `lilstinker` reboots

### 4. `.env.example` and `.gitignore`

`.env.example` provides a template for the required `ANTHROPIC_API_KEY` variable. `.gitignore` excludes `.env` from version control.

---

## Convenience: Shell Alias on `lilstinker`

Add to `~/.bashrc` on `lilstinker`:
```bash
alias claude-attach='docker exec -it claude-code tmux new-session -A -s main'
```

Then just run `claude-attach` from anywhere on `lilstinker`.

---

## Gotchas Addressed

| Issue | Solution |
|---|---|
| `ANTHROPIC_API_KEY` not in `docker exec` env | Entrypoint writes key to `~/.env_secrets`; sourced from `.bashrc` |
| Named volume init ordering | Entrypoint idempotently handles setup on every start |
| File permission conflicts on bind mount | `claude` user UID 1000 = Tom's UID on `lilstinker` |
| tmux session survives SSH disconnect | tmux server runs inside container; `sleep infinity` keeps container alive |
| Container restarts (reboot, etc.) | `restart: unless-stopped`; tmux session recreated on reconnect |

---

## Verification

1. `docker compose up -d --build` on `lilstinker`
2. `docker exec -it claude-code bash` — check user is `claude`, `claude --version` works
3. `docker exec -it claude-code tmux new-session -A -s main`
4. Start a `claude` session, then detach (Ctrl+B, D)
5. `docker exec -it claude-code tmux new-session -A -s main` again — should re-attach to running session
6. `echo $ANTHROPIC_API_KEY` inside session — should show the key
7. SSH into `lilstinker` from external machine via Tailscale, run `claude-attach` — same session
