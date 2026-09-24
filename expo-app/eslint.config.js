const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');

module.exports = defineConfig([
  expoConfig,
  {
    ignores: ['dist/*', 'db/migrations.generated.ts'],
  },
  {
    rules: {
      'react/display-name': 'off',
    },
  },
]);
