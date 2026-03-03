# Claude Code Docker Container

Run persistent Claude Code sessions on a home server using Docker and tmux.

## Workflow

```
laptop  --[Tailscale SSH]-->  lilstinker  --[docker exec + tmux]-->  claude-code container
```

tmux runs inside the container, so Claude Code keeps running when you disconnect from SSH.

## Setup

### 1. Copy files to lilstinker

```bash
scp -r /home/tom/Documents/Projects/dev-container tom@lilstinker:~/dev-container
```

Or clone from git if you push this repo.

### 2. Create your .env file

```bash
cd ~/dev-container
cp .env.example .env
nano .env  # add your ANTHROPIC_API_KEY
```

### 3. Add the shell alias

Add to `~/.bashrc` on lilstinker:

```bash
alias claude-attach='docker exec -it claude-code tmux new-session -A -s main'
```

Then reload:

```bash
source ~/.bashrc
```

### 4. Build and start the container

```bash
cd ~/dev-container
docker compose up -d --build
```

## Connecting

```bash
# Attach to (or create) the main tmux session
claude-attach

# Detach and leave Claude Code running: Ctrl+B, D

# Reconnect later — re-attaches to the same session
claude-attach
```

## Verification

```bash
# Check the container is running
docker ps

# Verify Claude Code is installed and user is correct
docker exec -it claude-code bash -c 'whoami && claude --version'

# Check the API key is available inside a session
docker exec -it claude-code bash -c 'source ~/.env_secrets && echo $ANTHROPIC_API_KEY'
```

## Project files

Host projects at `/home/tom/Documents/Projects` are bind-mounted into the container at `/home/claude/projects`. The `claude` user inside the container has UID 1000, matching Tom's UID on lilstinker, so there are no permission issues.

## Persistence

| What | How |
|---|---|
| Claude Code config, history, auth tokens | Named Docker volume `claude-code_home` — survives rebuilds |
| Project files | Bind-mounted from host — edits are reflected immediately |
| tmux session | Lives in the container — survives SSH disconnects |
| Container across reboots | `restart: unless-stopped` — starts automatically with Docker |

## Updating Claude Code

```bash
cd ~/dev-container
docker compose build --no-cache
docker compose up -d
```

Your home directory (config, history) is preserved in the named volume.

## Stopping

```bash
docker compose down      # stop container, keep volumes
docker compose down -v   # stop container and delete home volume (destructive)
```
