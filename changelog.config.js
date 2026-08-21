// The conventionalcommits preset ships only feat, fix, perf and breaking
// changes by default, which hides documentation, CI and chore work entirely.
// This repo carries a format spec and three ports, where a `docs:` commit can
// matter more than a `feat:` one, so every type gets a section.
import createPreset from 'conventional-changelog-conventionalcommits';

export default createPreset({
  // The workflow commits its own regeneration as `docs(changelog): …`. Without
  // this, that commit lands in the changelog, the next regeneration therefore
  // produces a diff, and the workflow opens a fresh pull request for it — a
  // loop that only stopped before because the GITHUB_TOKEN could not trigger
  // workflows. The PAT can, so the guard has to be explicit.
  // The scope is optional in the pattern so the unscoped commits already on
  // main, written before this guard existed, are filtered out too.
  ignoreCommits: [/^docs(\(changelog\))?: regenerate CHANGELOG/],
  types: [
    { type: 'feat', section: 'Features' },
    { type: 'fix', section: 'Bug Fixes' },
    { type: 'perf', section: 'Performance' },
    { type: 'refactor', section: 'Refactoring' },
    { type: 'docs', section: 'Documentation' },
    { type: 'test', section: 'Tests' },
    { type: 'build', section: 'Build' },
    { type: 'ci', section: 'Continuous Integration' },
    { type: 'chore', section: 'Chores' },
  ],
});
