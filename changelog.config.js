// The conventionalcommits preset ships only feat, fix, perf and breaking
// changes by default, which hides documentation, CI and chore work entirely.
// This repo carries a format spec and three ports, where a `docs:` commit can
// matter more than a `feat:` one, so every type gets a section.
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
