#!/usr/bin/env bats

load test_helper/setup

# add requires get_main_worktree_dir to return the actual main worktree,
# not a bare repo. Use a non-bare setup so "../$dir_name" lands in CONTAINER_DIR.
create_non_bare_repo() {
    CONTAINER_DIR="$TEST_DIR/worktrees"
    mkdir -p "$CONTAINER_DIR"

    MAIN_WORKTREE="$CONTAINER_DIR/main"
    git init "$MAIN_WORKTREE"
    cd "$MAIN_WORKTREE"
    echo "initial" > README.md
    git add README.md
    git commit -m "Initial commit"
}

@test "add creates a new worktree for a new branch" {
    create_non_bare_repo
    cd "$MAIN_WORKTREE"

    "$GIT_WT" add test-branch </dev/null &
    BGPID=$!
    sleep 2
    kill $BGPID 2>/dev/null || true
    wait $BGPID 2>/dev/null || true

    [ -d "$CONTAINER_DIR/test-branch" ]
    cd "$CONTAINER_DIR/test-branch"
    [ "$(git rev-parse --abbrev-ref HEAD)" = "test-branch" ]
}

@test "add checks out existing branch if it exists" {
    create_non_bare_repo
    cd "$MAIN_WORKTREE"
    git branch existing-branch

    "$GIT_WT" add existing-branch </dev/null &
    BGPID=$!
    sleep 2
    kill $BGPID 2>/dev/null || true
    wait $BGPID 2>/dev/null || true

    [ -d "$CONTAINER_DIR/existing-branch" ]
    cd "$CONTAINER_DIR/existing-branch"
    [ "$(git rev-parse --abbrev-ref HEAD)" = "existing-branch" ]
}

@test "add converts slashes in branch name to dashes for directory" {
    create_non_bare_repo
    cd "$MAIN_WORKTREE"

    "$GIT_WT" add feature/my-thing </dev/null &
    BGPID=$!
    sleep 2
    kill $BGPID 2>/dev/null || true
    wait $BGPID 2>/dev/null || true

    [ -d "$CONTAINER_DIR/feature-my-thing" ]
}

@test "add errors when no name provided" {
    create_non_bare_repo
    cd "$MAIN_WORKTREE"

    run "$GIT_WT" add
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error" ]]
}
