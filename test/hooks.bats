#!/usr/bin/env bats

load test_helper/setup

# Helper: create a worktree and call post_add_worktree without exec $SHELL
run_post_add_hook() {
    local name="$1"
    local dir_name="${name//\//-}"
    cd "$MAIN_WORKTREE"
    git worktree add "$CONTAINER_DIR/$dir_name" -b "$name"
    cd "$CONTAINER_DIR/$dir_name"

    # Source git-wt to get functions, but override the case statement
    # by sourcing only the function definitions
    eval "$(sed -n '1,/^case/p' "$GIT_WT" | sed '$d')"
    post_add_worktree
}

@test "hook: finds .wt/post-add-worktree in worktree root" {
    create_test_repo

    # We'll create the hook in the new worktree's location before calling post_add
    # Actually, the hook should be findable from the new worktree dir
    # Let's put it in the container dir since the new worktree will be there
    mkdir -p "$CONTAINER_DIR/.wt"
    cat > "$CONTAINER_DIR/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "container-hook-ran" > "$(pwd)/hook-output.txt"
HOOK
    chmod +x "$CONTAINER_DIR/.wt/post-add-worktree"

    run_post_add_hook "test-hook-container"

    [ -f "$CONTAINER_DIR/test-hook-container/hook-output.txt" ]
    [[ "$(cat "$CONTAINER_DIR/test-hook-container/hook-output.txt")" == "container-hook-ran" ]]
}

# get_main_worktree_dir only returns the actual main worktree (not a bare repo)
# in a non-bare layout, so use that here to assert the main worktree argument.
@test "hook: receives new worktree path and main worktree path as arguments" {
    CONTAINER_DIR="$TEST_DIR/worktrees"
    mkdir -p "$CONTAINER_DIR"
    MAIN_WORKTREE="$CONTAINER_DIR/main"
    git init "$MAIN_WORKTREE"
    cd "$MAIN_WORKTREE"
    echo "initial" > README.md
    git add README.md
    git commit -m "Initial commit"

    mkdir -p "$CONTAINER_DIR/.wt"
    cat > "$CONTAINER_DIR/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "$1" > "$(pwd)/arg-new.txt"
echo "$2" > "$(pwd)/arg-main.txt"
HOOK
    chmod +x "$CONTAINER_DIR/.wt/post-add-worktree"

    run_post_add_hook "test-hook-args"

    # Resolve symlinks (macOS /var -> /private/var) on both sides before
    # comparing: pwd reports logical paths while git reports canonical ones.
    local actual_new actual_main expected_new expected_main
    actual_new="$(cd "$(cat "$CONTAINER_DIR/test-hook-args/arg-new.txt")" && pwd -P)"
    actual_main="$(cd "$(cat "$CONTAINER_DIR/test-hook-args/arg-main.txt")" && pwd -P)"
    expected_new="$(cd "$CONTAINER_DIR/test-hook-args" && pwd -P)"
    expected_main="$(cd "$MAIN_WORKTREE" && pwd -P)"
    [[ "$actual_new" == "$expected_new" ]]
    [[ "$actual_main" == "$expected_main" ]]
}

@test "hook: walks up to find .wt/post-add-worktree in grandparent" {
    create_test_repo

    # Create hook in TEST_DIR (grandparent of worktree dirs)
    mkdir -p "$TEST_DIR/.wt"
    cat > "$TEST_DIR/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "grandparent-hook-ran" > "$(pwd)/hook-output.txt"
HOOK
    chmod +x "$TEST_DIR/.wt/post-add-worktree"

    run_post_add_hook "test-hook-grandparent"

    [ -f "$CONTAINER_DIR/test-hook-grandparent/hook-output.txt" ]
    [[ "$(cat "$CONTAINER_DIR/test-hook-grandparent/hook-output.txt")" == "grandparent-hook-ran" ]]
}

@test "hook: falls back to global ~/.wt/post-add-worktree" {
    create_test_repo

    mkdir -p "$HOME/.wt"
    cat > "$HOME/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "global-hook-ran" > "$(pwd)/hook-output.txt"
HOOK
    chmod +x "$HOME/.wt/post-add-worktree"

    run_post_add_hook "test-hook-global"

    [ -f "$CONTAINER_DIR/test-hook-global/hook-output.txt" ]
    [[ "$(cat "$CONTAINER_DIR/test-hook-global/hook-output.txt")" == "global-hook-ran" ]]
}

@test "hook: no hook found does not error" {
    create_test_repo

    run_post_add_hook "test-no-hook"

    [ -d "$CONTAINER_DIR/test-no-hook" ]
    [ ! -f "$CONTAINER_DIR/test-no-hook/hook-output.txt" ]
}

@test "hook: closest hook wins over parent" {
    create_test_repo

    # Create hook in TEST_DIR (further away)
    mkdir -p "$TEST_DIR/.wt"
    cat > "$TEST_DIR/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "far" > "$(pwd)/hook-output.txt"
HOOK
    chmod +x "$TEST_DIR/.wt/post-add-worktree"

    # Create hook in container dir (closer)
    mkdir -p "$CONTAINER_DIR/.wt"
    cat > "$CONTAINER_DIR/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "close" > "$(pwd)/hook-output.txt"
HOOK
    chmod +x "$CONTAINER_DIR/.wt/post-add-worktree"

    run_post_add_hook "test-hook-priority"

    [[ "$(cat "$CONTAINER_DIR/test-hook-priority/hook-output.txt")" == "close" ]]
}

@test "hook: stops at HOME, does not check above" {
    create_test_repo

    # HOME is $TEST_DIR/fakehome. Create hook ABOVE home.
    # The walk-up should stop at HOME and not find this.
    # Note: worktrees are under $TEST_DIR/worktrees which is NOT under HOME,
    # so the walk-up goes: worktree -> container -> TEST_DIR -> ... -> /
    # But it should stop at HOME. Since the worktree path doesn't pass through
    # HOME, the walk will go up to / without hitting HOME.
    #
    # To properly test this: put worktrees UNDER HOME so the walk-up passes through it.

    # Recreate with worktrees under HOME
    CONTAINER_DIR="$HOME/projects/worktrees"
    mkdir -p "$CONTAINER_DIR"
    BARE_REPO="$HOME/projects/repo.git"
    git init --bare "$BARE_REPO"
    MAIN_WORKTREE="$CONTAINER_DIR/main"
    git -C "$BARE_REPO" worktree add "$MAIN_WORKTREE" -b main
    cd "$MAIN_WORKTREE"
    echo "initial" > README.md
    git add README.md
    git commit -m "Initial commit"

    # Put hook above HOME — should NOT be found
    mkdir -p "$TEST_DIR/.wt"
    cat > "$TEST_DIR/.wt/post-add-worktree" << 'HOOK'
#!/usr/bin/env bash
echo "above-home" > "$(pwd)/hook-output.txt"
HOOK
    chmod +x "$TEST_DIR/.wt/post-add-worktree"

    run_post_add_hook "test-hook-boundary"

    [ ! -f "$CONTAINER_DIR/test-hook-boundary/hook-output.txt" ]
}
