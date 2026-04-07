# Favorite Commands

Press `Ctrl+/` to bring up the fzf command selector for quick access to frequently used commands.

## Install

```bash
cd ~/favorite_cmds
./install.sh
source ~/.bashrc   # or source ~/.zshrc
```

Dependency: [fzf](https://github.com/junegunn/fzf)

## Command Categories

| Type | File Location | Description |
|------|--------------|-------------|
| **Local** | `~/favorite_cmds/local` | Directory-grouped local commands, shown only when cwd matches |
| **Global** | `~/favorite_cmds/global` | Global commands available everywhere |
| **Tools** | `~/favorite_cmds/tools/<name>` | Tool-specific commands (git, docker, etc.) |

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+/` | Open command list |
| `Enter` | Select and fill into command line |
| `Esc` | Cancel |

## File Format

### local (grouped by directory)

```
# /home/user/project-a
./build.sh
make install

# /home/user/project-b
./run.sh
./deploy.sh
```

Lines starting with `#` specify a directory path. Commands below it are only shown when your cwd matches that directory (or its subdirectories).

### global / tools files

```
# section title
command1
command2
```

Lines starting with `#` are displayed as section headers and ignored when selected.

## Helper Commands

```bash
# add commands
fc_add local "make build"
fc_add global "htop"
fc_add tool:git "git rebase -i HEAD~3"

# edit command files
fc_edit local
fc_edit global
fc_edit tool:git
```

## Directory Layout

```
~/favorite_cmds/
├── favorite_cmds.sh    # main script (sourced by shell)
├── local               # local commands (grouped by directory)
├── global              # global commands
└── tools/              # tool commands
    ├── git
    ├── docker
    └── systemd
```

## Customization

Override default path with an environment variable:

```bash
export FAVORITE_CMDS_DIR="$HOME/my_cmds"
```
