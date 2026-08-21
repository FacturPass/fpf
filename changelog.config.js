// The conventionalcommits preset ships only feat, fix, perf and breaking
// changes by default, which hides documentation, CI and chore work entirely.
// This repo carries a format spec and three ports, where a `docs:` commit can
// matter more than a `feat:` one, so every type gets a section.
//
// Nothing filters the workflow's own `docs(changelog):` commits out of the
// changelog: the `ignoreCommits` option that would do it takes a shape that
// differs between versions of git-raw-commits, and passing the wrong one fails
// the whole run with "ignore.test is not a function". The loop it was meant to
// prevent is already stopped in changelog.yml, which refuses to run on its own
// commit — plain YAML, with no library contract to get wrong. The cost is that
// those entries show up in the changelog.
import createPreset from 'conventional-changelog-conventionalcommits';

export default createPreset({
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
