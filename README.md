# git-wt

A fast, interactive git worktree manager. Switch, create, remove, and clean up git worktrees with ease.

Works as a git subcommand: `git wt`

## Requirements

- [git](https://git-scm.com/)
- [fzf](https://github.com/junegunn/fzf)
- bash

## Installation

### Homebrew

```bash
brew install mattmcmanus/tap/git-wt
```

### Manual

```bash
git clone https://github.com/mattmcmanus/git-wt.git
cd git-wt
make install
```

To customize the install location:

```bash
make install PREFIX=~/.local
```

To also install the short `wt` alias:

```bash
make install-alias
```

To uninstall:

```bash
make uninstall
```

## Usage

### Switch worktrees

```bash
git wt              # fuzzy-select from all worktrees
git wt feature      # fuzzy-select with "feature" as initial query
```

When switching, your relative path is preserved. If you're in `worktree-a/src/components`, you'll land in `worktree-b/src/components` if it exists.

### Add a new worktree

```bash
git wt add my-feature
```

Creates a new worktree (and branch if needed) and switches to it. If a branch named `my-feature` already exists, the worktree checks it out. Otherwise, a new tracking branch is created.

### Remove a worktree

```bash
git wt remove              # fuzzy-select which to remove
git wt remove my-feature   # remove with initial query
```

Prompts for confirmation before removing.

### Clean up merged worktrees

```bash
git wt clean
```

Removes all worktrees whose branches have been merged into the main branch or no longer exist.

### List worktrees

```bash
git wt list
```

### Other

```bash
git wt help       # show help
git wt version    # show version
```

## Hooks

git-wt supports a `post-add-worktree` hook that runs after creating a new worktree. This is useful for setup tasks like installing dependencies or copying environment files.

### Hook lookup order

After creating a worktree, git-wt looks for `.wt/post-add-worktree` by walking up the directory tree from the new worktree root, stopping at `$HOME`:

1. `<new-worktree>/.wt/post-add-worktree`
2. `<parent-dir>/.wt/post-add-worktree`
3. `<grandparent-dir>/.wt/post-add-worktree`
4. ... up to `$HOME/.wt/post-add-worktree`

The first match wins. The hook must be executable.

### Example hook

```bash
#!/usr/bin/env bash
# .wt/post-add-worktree — run after creating a new worktree
npm install
cp .env.example .env
```

A hook at `~/.wt/post-add-worktree` serves as a global default for all projects.

## Contributing

```bash
# Install bats-core (test framework)
brew install bats-core  # or see https://bats-core.readthedocs.io

# Run tests
bats test/
```

## Origin

Extracted from [mattmcmanus/dotfiles](https://github.com/mattmcmanus/dotfiles). See the [commit history](https://github.com/mattmcmanus/dotfiles/commits/master/bin/wt) for the original development.

## License

MIT
