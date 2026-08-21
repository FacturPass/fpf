// The conventionalcommits preset ships only feat, fix, perf and breaking
// changes by default, which hides documentation, CI and chore work entirely.
// This repo carries a format spec and three ports, where a `docs:` commit can
// matter more than a `feat:` one, so every type gets a section.
//
// The workflow's own regeneration commits are then dropped, so the changelog
// does not narrate its own upkeep. Two mechanisms, because two shapes exist:
// current commits carry a `changelog` scope, which a scoped type entry hides;
// the two written before that scope existed do not, and are matched on their
// subject in the writer transform. Returning false there discards a commit.
import createPreset from 'conventional-changelog-conventionalcommits';

const preset = await createPreset({
  types: [
    { type: 'feat', section: 'Features' },
    { type: 'fix', section: 'Bug Fixes' },
    { type: 'perf', section: 'Performance' },
    { type: 'refactor', section: 'Refactoring' },
    { type: 'docs', scope: 'changelog', hidden: true },
    { type: 'docs', section: 'Documentation' },
    { type: 'test', section: 'Tests' },
    { type: 'build', section: 'Build' },
    { type: 'ci', section: 'Continuous Integration' },
    { type: 'chore', section: 'Chores' },
  ],
});

const presetTransform = preset.writer.transform;
preset.writer.transform = (commit, context) => {
  if (/^regenerate CHANGELOG/.test(commit.subject ?? '')) return false;
  return presetTransform(commit, context);
};

export default preset;
