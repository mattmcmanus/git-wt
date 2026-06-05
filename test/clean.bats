#!/usr/bin/env bats

load test_helper/setup

# Clean requires get_main_worktree_dir to return the actual main worktree,
# not a bare repo. Override create_test_repo to use a non-bare setup.
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

# Add a worktree with a commit, using non-bare repo.
add_clean_test_worktree() {
    local branch="$1"
    local dir_name="${branch//\//-}"
    cd "$MAIN_WORKTREE"
    git worktree add "$CONTAINER_DIR/$dir_name" -b "$branch"
    cd "$CONTAINER_DIR/$dir_name"
    echo "$branch" > branch.txt
    git add branch.txt
    git commit -m "Commit on $branch"
}

@test "clean removes worktrees for merged branches" {
    create_non_bare_repo
    add_clean_test_worktree "merged-feature"

    cd "$MAIN_WORKTREE"
    git merge merged-feature

    run "$GIT_WT" clean
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Removing worktree" ]]
    [[ "$output" =~ "merged-feature" ]]
    [ ! -d "$CONTAINER_DIR/merged-feature" ]
}

@test "clean skips worktrees for unmerged branches" {
    create_non_bare_repo
    add_clean_test_worktree "unmerged-feature"

    cd "$MAIN_WORKTREE"

    run "$GIT_WT" clean
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Skipping worktree" ]]
    [ -d "$CONTAINER_DIR/unmerged-feature" ]
}

@test "clean detects worktrees with non-existent branches" {
    create_non_bare_repo
    cd "$MAIN_WORKTREE"

    # Create a worktree, then delete its branch ref to simulate
    # a branch that was deleted on the remote
    git worktree add "$CONTAINER_DIR/temp-branch" -b temp-branch
    git update-ref -d refs/heads/temp-branch

    run "$GIT_WT" clean
    [[ "$output" =~ "non-existent branch" ]]
}

@test "clean does nothing when only main worktree exists" {
    create_non_bare_repo
    cd "$MAIN_WORKTREE"

    run "$GIT_WT" clean
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Cleaned up" ]]
}

@test "clean force-deletes a dirty merged worktree when confirmed" {
    create_non_bare_repo
    add_clean_test_worktree "merged-feature"

    # Leave uncommitted changes in the worktree
    echo "dirty change" >> "$CONTAINER_DIR/merged-feature/branch.txt"

    cd "$MAIN_WORKTREE"
    git merge merged-feature

    run bash -c "echo y | '$GIT_WT' clean"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "uncommitted changes" ]]
    [[ "$output" =~ "branch.txt" ]]
    [ ! -d "$CONTAINER_DIR/merged-feature" ]
}

@test "clean indents and blank-line separates a dirty worktree's status block" {
    create_non_bare_repo
    # An unmerged worktree that will be skipped, printed before the dirty block
    add_clean_test_worktree "kept-feature"
    add_clean_test_worktree "merged-feature"

    # Leave an untracked file so the status has a "??" entry
    echo "scratch" > "$CONTAINER_DIR/merged-feature/untracked.txt"

    cd "$MAIN_WORKTREE"
    git merge merged-feature

    run bash -c "echo y | '$GIT_WT' clean"
    [ "$status" -eq 0 ]
    # Blank line separates entries
    [[ "$output" == *$'\n\n'* ]]
    # git status lines are indented under the header
    [[ "$output" == *$'\n    ?? untracked.txt'* ]]
    [ ! -d "$CONTAINER_DIR/merged-feature" ]
}

@test "clean keeps a dirty merged worktree when declined" {
    create_non_bare_repo
    add_clean_test_worktree "merged-feature"

    # Leave uncommitted changes in the worktree
    echo "dirty change" >> "$CONTAINER_DIR/merged-feature/branch.txt"

    cd "$MAIN_WORKTREE"
    git merge merged-feature

    run bash -c "echo n | '$GIT_WT' clean"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "uncommitted changes" ]]
    [[ "$output" =~ "branch.txt" ]]
    [ -d "$CONTAINER_DIR/merged-feature" ]
}
