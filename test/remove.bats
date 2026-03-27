#!/usr/bin/env bats

load test_helper/setup

# Remove uses fzf (interactive) and read (confirmation prompt).
# Without a real TTY we can only test the cancel/empty-selection path
# by providing a fake fzf that exits non-zero (simulating Escape).

@test "remove preserves worktree when selection is cancelled" {
    create_test_repo
    add_test_worktree "to-remove"
    cd "$MAIN_WORKTREE"

    # Create a fake fzf that exits 1 (user cancelled)
    mkdir -p "$TEST_DIR/bin"
    printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_DIR/bin/fzf"
    chmod +x "$TEST_DIR/bin/fzf"

    # fzf returning non-zero causes set -e to exit the script,
    # so the worktree should be left intact
    run env PATH="$TEST_DIR/bin:$PATH" "$GIT_WT" remove "to-remove"
    [ "$status" -ne 0 ]
    [ -d "$CONTAINER_DIR/to-remove" ]
}
