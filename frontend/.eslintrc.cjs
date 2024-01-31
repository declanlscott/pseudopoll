/** @type {import("eslint").Linter.Config} */
const config = {
  root: true,
  env: {
    browser: true,
    node: true,
  },
  extends: [
    "@nuxtjs/eslint-config-typescript",
    "plugin:@tanstack/eslint-plugin-query/recommended",
    "prettier",
  ],
  rules: {
    "import/order": "off",
    "import/named": "off",
  },
  ignorePatterns: [".eslintrc.cjs"],
  parser: "vue-eslint-parser",
  parserOptions: {
    parser: "@typescript-eslint/parser",
  },
};

module.exports = config;
