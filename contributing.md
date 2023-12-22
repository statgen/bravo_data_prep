# Contributing

## Contributing Code/Features/Bug Fixes
The work on this project roughly follows [git flow](https://datasift.github.io/gitflow/IntroducingGitFlow.html), but without a bugfix or release branch.
In short, work is laid out in an issue, done in a feature branch, tested in the develop branch, and finally added to the main branch.

1. Make an issue
    - Describe the feature or change
    - Explain the rationale
    - Watch the thread for replies and discussion
1. Make a branch
    - Do work on this branch
    - Add tests that demonstrate/exercise the expected code use
    - Add tests that illustrate expected/known edge cases
1. Create pull request (PR) against develop branch
    - Squash commits into single or few related chunks of work.
    - Watch the PR thread for replies and discussion
    - Watch the PR for continuous integration results

### Commits
Commit messages: 

- Written in present tense.
- Answers the question "why?" the code

### Formatting and Linting
For c++ code, use clang-lint and clang-format from LLVM. Configuration will be included in project files.
[](https://github.com/llvm/llvm-project/releases/tag/llvmorg-17.0.5)

For python code, use flake8.
