---
name: review-contributor-pr
description: Review and manage pull requests from external contributors. Use when checking out, reviewing, editing, or merging a PR from a fork.
---

# Review Contributor PR

End-to-end workflow for reviewing a PR opened from a contributor's fork: check it out locally, review it, optionally amend it, and merge with a clean history.

## 1. Checkout

Contributors submit PRs from their forks. To push changes back (commit message fixes, minor tweaks), add their fork as a remote. Derive the repo slug from `gh repo view --json nameWithOwner -q .nameWithOwner` instead of hardcoding it.

```bash
# Fork owner and branch are visible in `gh pr view <pr>` or the PR URL.
REPO=$(gh repo view --json name -q .name)
git remote add <owner> git@github.com:<owner>/$REPO.git
git fetch <owner>
git checkout <owner>/<branch> -b <branch>
```

This works when the contributor has "Allow edits from maintainers" enabled (GitHub default).

To push amended commits back:

```bash
git push <owner> <local-branch>:<remote-branch> --force-with-lease
```

## 2. Review Checklist

### Relevance and conflicts
- Verify the PR targets the correct base branch and is rebased on it (no merge conflicts).
- Confirm the fix/feature is still relevant and not already addressed.

### Code correctness
- Read the changed files and verify the code does what the PR description claims.
- Check edge cases, error handling, and unintended side effects.
- Look for security concerns and changes to privilege or trust boundaries.

### Commit format
If this repo uses conventional commits, every commit must match:

```
<type>(<scope>): <description>
```

Common types: `feat`, `fix`, `chore`, `perf`, `refactor`, `docs`, `test`. Scopes usually match the area or directory touched. Confirm the project's exact convention with `git log --oneline -20` before judging.

If commits don't follow the format, amend them — keep the original author, set yourself as committer.

### CI checks
Run the project's checks locally before merging. Detect them from the repo rather than assuming a stack:
- Read `package.json` scripts, `Makefile`, `justfile`, or the CI workflow under `.github/workflows/`.
- Run the lint, typecheck, and test commands the project actually defines.

All checks must pass before merge.

## 3. Merge

Prefer fast-forward merge to keep linear history:

```bash
git checkout <base-branch>
git merge <branch> --ff-only
git push origin <base-branch>
```

If fast-forward fails, rebase the branch on the base branch first, then retry.

After merge, clean up the local branch:

```bash
git branch -d <branch>
```
