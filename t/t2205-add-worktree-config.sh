#!/bin/sh

test_description='directory traversal respects worktree config

This test configures the repository`s worktree to be two levels above the
`.git` directory and checks whether we are able to add to the index those files
that are in either (1) the manually configured worktree directory or (2) the
standard worktree location with respect to the `.git` directory (i.e. ensuring
that the encountered `.git` directory is not treated as belonging to a foreign
nested repository)'

. ./test-lib.sh

test_expect_success '1a: setup' '
	test_create_repo test1 &&
	git --git-dir="test1/.git" config core.worktree "$(pwd)" &&

	mkdir -p outside-tracked outside-untracked &&
	mkdir -p test1/inside-tracked test1/inside-untracked &&
	>file-tracked &&
	>file-untracked &&
	>outside-tracked/file &&
	>outside-untracked/file &&
	>test1/file-tracked &&
	>test1/file-untracked &&
	>test1/inside-tracked/file &&
	>test1/inside-untracked/file &&

	cat >expect-tracked-unsorted <<-EOF &&
	../file-tracked
	../outside-tracked/file
	file-tracked
	inside-tracked/file
	EOF

	cat >expect-untracked-unsorted <<-EOF &&
	../file-untracked
	../outside-untracked/file
	file-untracked
	inside-untracked/file
	EOF

	cat expect-tracked-unsorted expect-untracked-unsorted >expect-all-unsorted &&

	cat >.gitignore <<-EOF
	.gitignore
	actual-*
	expect-*
	EOF
'

test_expect_success '1b: pre-add all' '
	local parent_dir="$(pwd)" &&
	(
		cd test1 &&
		git ls-files -o --exclude-standard "$parent_dir" >../actual-all-unsorted
	) &&
	sort actual-all-unsorted >actual-all &&
	sort expect-all-unsorted >expect-all &&
	test_cmp expect-all actual-all
'

test_expect_success '1c: post-add tracked' '
	local parent_dir="$(pwd)" &&
	(
		cd test1 &&
		git add file-tracked &&
		git add inside-tracked &&
		git add ../outside-tracked &&
		git add "$parent_dir/file-tracked" &&
		git ls-files "$parent_dir" >../actual-tracked-unsorted
	) &&
	sort actual-tracked-unsorted >actual-tracked &&
	sort expect-tracked-unsorted >expect-tracked &&
	test_cmp expect-tracked actual-tracked
'

test_expect_success '1d: post-add untracked' '
	local parent_dir="$(pwd)" &&
	(
		cd test1 &&
		git ls-files -o --exclude-standard "$parent_dir" >../actual-untracked-unsorted
	) &&
	sort actual-untracked-unsorted >actual-untracked &&
	sort expect-untracked-unsorted >expect-untracked &&
	test_cmp expect-untracked actual-untracked
'

test_done
