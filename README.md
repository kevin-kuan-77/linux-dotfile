# Dotfiles (bare git repo)

Track your home-directory config files with a **bare git repository** — no symlinks,
no extra tooling, no copying files into a separate folder. Your `$HOME` *is* the
working tree; a hidden bare repo just records the history.

This template contains an example tmux config and a `bootstrap.sh` for new machines.

---

## Quick start

On the machine that has your configs:

```sh
git init --bare $HOME/.cfg
alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no

config add ~/.gitignore ~/.config/tmux/tmux.conf ~/.bashrc
config commit -m "Initial dotfiles"
config remote add origin git@github.com:<you>/dotfiles.git
config branch -M main
config push -u origin main
```

On a **new** machine: edit `DOTFILES_REMOTE` in `bootstrap.sh` and run it (details below).

The rest of this README explains each piece.

---

## How it works

A normal git repo keeps its database in a `.git/` folder *inside* the working tree.
The bare-repo trick separates the two:

- The git database lives in `~/.cfg` (a **bare** repo — no working tree of its own).
- The **work tree** is set to `$HOME`.

You drive it with one git invocation that points both knobs at the right place:

```sh
git --git-dir=$HOME/.cfg/ --work-tree=$HOME <command>
```

Typing that every time is painful, so you wrap it in an alias called `config`.
After that, `config` behaves exactly like `git`, except its repo is `~/.cfg`
and its files are your home directory:

```sh
config status
config add ~/.config/tmux/tmux.conf
config commit -m "Add tmux config"
config push
```

Because the work tree is `$HOME`, you only ever track the files you explicitly
`add`. Everything else in your home directory stays untouched and unlisted.

---

## First-time setup (the machine that has your configs)

```sh
# 1. Create the bare repo
git init --bare $HOME/.cfg

# 2. Define the alias (also added to your shell rc below so it persists)
alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# 3. Don't show every file in $HOME as "untracked" when you run status
config config --local status.showUntrackedFiles no
```

Step 3 is important: without it, `config status` would list your *entire* home
directory as untracked. With it set, status only shows files you actually track.

### Commit your `.gitignore` early

The `.gitignore` only takes effect once it lives at `~/.gitignore` **and** is tracked
by the repo, so add it before anything else:

```sh
config add ~/.gitignore
config commit -m "Add .gitignore"
```

### Make the alias permanent

Add the alias to your shell rc so it's available in every session **and on every
new machine** (this is also why you track your `.bashrc`/`.zshrc` — see below):

```sh
echo "alias config='git --git-dir=\$HOME/.cfg/ --work-tree=\$HOME'" >> ~/.bashrc
echo "alias config='git --git-dir=\$HOME/.cfg/ --work-tree=\$HOME'" >> ~/.zshrc
```

---

## Committing your first file (the tmux example)

Suppose your tmux config lives at `~/.config/tmux/tmux.conf`:

```sh
config add ~/.config/tmux/tmux.conf
config commit -m "Add tmux config"
```

> **Note on the filename:** tmux loads `~/.config/tmux/tmux.conf` by default, and the
> reload binding in the file (`source-file ~/.config/tmux/tmux.conf`) refers to that
> name. So use **`tmux.conf`**, not `tmux.config` — otherwise tmux won't pick it up
> automatically. This template stores it at
> [`.config/tmux/tmux.conf`](.config/tmux/tmux.conf).

Then connect a remote and push:

```sh
config remote add origin git@github.com:<you>/config.git
config branch -M main
config push -u origin main
```

---

## Tracking `.bashrc` and `.zshrc`

They're just files in `$HOME`, so it's the same workflow as anything else:

```sh
config add ~/.bashrc ~/.zshrc
config commit -m "Add bash and zsh configs"
config push
```

Two things worth knowing:

1. **Put the `config` alias inside `.bashrc`/`.zshrc`.** That solves the
   chicken-and-egg problem on a new machine: once you check the repo out, the alias
   ships with your shell config and is ready the next time you open a terminal.

2. **`config add` requires the file to already exist and be tracked-on-purpose.**
   Since `status.showUntrackedFiles` is `no`, new files won't show up in `status`
   until you `add` them. Just add them by path explicitly, as above.

### Daily workflow after a change

```sh
vim ~/.zshrc          # edit as normal
config status       # shows only tracked files that changed
config add ~/.zshrc
config commit -m "zsh: add alias for ..."
config push
```

---

## Setting up on a NEW machine

You can't `git clone` straight into `$HOME` (it isn't empty), so you clone the bare
repo and *check out* into your home directory. The included `bootstrap.sh` automates
this, including backing up any files that would be overwritten.

```sh
# Edit DOTFILES_REMOTE in bootstrap.sh first (or pass it via env), then:
DOTFILES_REMOTE=git@github.com:<you>/config.git ./bootstrap.sh
```

> If you get `Permission denied`, the script isn't executable yet (the +x bit isn't
> set when files are created on Windows). Fix it with `chmod +x bootstrap.sh`, or run
> it via the interpreter: `sh bootstrap.sh`. To store the executable bit in git so it
> survives clones: `config update-index --chmod=+x bootstrap.sh`.

Or do it manually:

```sh
git clone --bare git@github.com:<you>/config.git $HOME/.cfg
alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Try to lay the files down in $HOME
config checkout
```

If `checkout` complains that existing files (e.g. a default `.bashrc`) would be
overwritten, back them up and retry:

```sh
mkdir -p ~/.cfg-backup
config checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' \
  | xargs -I{} sh -c 'mkdir -p ~/.cfg-backup/$(dirname {}) && mv {} ~/.cfg-backup/{}'

config checkout
config config --local status.showUntrackedFiles no
```

Open a fresh shell and you're done — the `config` alias is now in your checked-out
`.bashrc`/`.zshrc`.

---

## One repo, many machines (don't split by OS)

**Recommendation: keep a single repo with a single `main` branch.** Do *not* make a
repo per machine, and don't split by OS. Separate repos kill the whole point — you
lose the shared 90% (your aliases, prompt, vim config, tmux bindings) and end up
copy-pasting fixes between repos forever.

The 10% that genuinely differs per machine (a work proxy, a `JAVA_HOME`, GUI-only
settings, secrets) is handled by **layering**, not by forking the repo:

### Pattern: shared rc + machine-local override

Track a common `.bashrc`/`.zshrc` that is identical everywhere, and have it source an
**untracked** local file at the end:

```sh
# ...end of your tracked ~/.zshrc...

# Per-machine settings that should NOT be shared. Not tracked (see .gitignore).
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

`~/.zshrc.local` is gitignored, so each machine keeps its own — the work proxy lives
only on the work laptop, and it never leaks into the public repo.

### Pattern: branch by OS/conditionals for things that must be tracked

When a difference *should* be version-controlled (e.g. macOS uses `gnu-sed` paths,
Linux doesn't), branch inside the file instead of forking the repo:

```sh
case "$(uname -s)" in
  Darwin)  export PATH="/opt/homebrew/bin:$PATH" ;;
  Linux)   export PATH="$HOME/.local/bin:$PATH" ;;
esac

# WSL-specific
grep -qi microsoft /proc/version 2>/dev/null && export BROWSER="wmctl.exe"
```

`tmux` and git support the same idea natively:

```sh
# ~/.config/tmux/tmux.conf
if-shell '[ "$(uname)" = "Darwin" ]' 'source ~/.config/tmux/macos.conf'
```
```ini
# ~/.gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work       # work email/signing only under ~/work
```

### When a separate branch *is* reasonable

If a machine is radically different (a headless Docker/server vs. a GUI Macbook), a
**branch off `main`** per host is the heaviest tool you should reach for — still one
repo, so you can `merge`/`cherry-pick` shared changes between them:

```sh
config checkout -b server          # branch for the container/server
config push -u origin server
# later, pull a shared fix from main:
config merge main
```

| Approach                          | Verdict                                              |
| --------------------------------- | ---------------------------------------------------- |
| Separate repo per machine         | ❌ Avoid — no sharing, constant copy-paste            |
| Separate repo per OS              | ❌ Avoid — same problem, coarser                      |
| One repo + `*.local` overrides    | ✅ Default. Handles secrets & per-host tweaks          |
| One repo + in-file `uname`/`if`   | ✅ For tracked differences (PATH, OS-specific config) |
| One repo + branch per host        | ⚠️ Only for radically different hosts; still mergeable |

**Bottom line:** one repo, one `main`, layer the differences. Reach for branches only
when a host truly diverges.

## Cheatsheet

| Task                        | Command                                         |
| --------------------------- | ----------------------------------------------- |
| See what changed            | `config status`                               |
| Start tracking a file       | `config add ~/path/to/file`                   |
| Commit                      | `config commit -m "message"`                  |
| Push / pull                 | `config push` / `config pull`               |
| List everything tracked     | `config ls-tree --full-tree -r HEAD`          |
| Diff                        | `config diff`                                 |

---

## Repo contents

```
.
├── README.md
├── .gitignore                   # safety net against committing secrets/junk
├── bootstrap.sh                 # new-machine installer
└── .config/
    └── tmux/
        └── tmux.conf            # example tracked config
```

> **Heads-up:** this template ships the example config under `.config/`. When you adopt
> it for real, your tracked files live in your actual `$HOME`, committed via the
> `config` command — you don't keep a separate copy here.
