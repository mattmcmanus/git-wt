#!/usr/bin/env bats

load test_helper/setup

@test "worktree_directories returns nothing when only main worktree exists" {
    create_test_repo
    cd "$MAIN_WORKTREE"

    run bash -c "source '$GIT_WT' 2>/dev/null; worktree_directories" 2>/dev/null || \
        run bash -c ". '$GIT_WT'; worktree_directories"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "worktree_directories returns feature worktrees excluding main" {
    create_test_repo
    add_test_worktree "feature-one"
    add_test_worktree "feature-two"
    cd "$MAIN_WORKTREE"

    run bash -c "set +x; source <(grep -v '^set ' '$GIT_WT'); worktree_directories"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "feature-one" ]]
    [[ "$output" =~ "feature-two" ]]
    [[ ! "$output" =~ "$MAIN_WORKTREE" ]]
}
