// Conventional Commits, enforced by the husky commit-msg hook and again in CI.
// Scopes are unrestricted, but `js`, `rust`, `csharp`, `spec` and `profile-fr`
// are the natural ones in a repo that carries a format and three ports.
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [2, 'always', 100],
  },
};
