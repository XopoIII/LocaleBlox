# LocaleBlox - working notes

LocaleBlox is a locale kit for Roblox: a game's words as Luau tables looked up by key, in
twenty-five languages, with plural forms and the lint that keeps the tables whole. It was extracted
from the game Grabby Pit and is used by the owner's games as a pinned pesde package
(`xopoiii/localeblox`, target `roblox`).

## Everything here is written in English

Code, comments, identifiers, docs, commit messages, PR bodies. `scripts/check-english.sh` enforces it on
every commit. Conversation with the owner may be in another language; nothing in another language
lands in the repository. A spec that needs a letter of another script builds it from its code point
(`utf8.char(0x416)`), and the glyph lists of `src/Lint.luau` are code points for the same reason.

## The tree is at zero

- No lint warnings, no type errors, no formatting drift. A warning is a failure: one that is tolerated
  once stops being read.
- Every `.luau` file starts with `--!strict` on line 1 and never opts out (`scripts/check-strict.sh`).
- No Luau file is over 300 lines (`scripts/check-file-size.sh`). A file that reaches the cap is split
  into modules, not exempted.
- The same gates run in lefthook (pre-commit, pre-push) and in CI (`.github/workflows/checks.yaml`).

## The kit reads nothing of its host

This is the reason the package exists, and the rule a change is checked against first.

- A game's tables, its plural forms, the player's locale id, the Latin it keeps on purpose and the
  names of its data are **arguments**. No module requires anything outside `src/`, reads a player,
  an attribute or a file, or names a game's Instance.
- Nothing touches `game`, at require time or later: every module is plain Luau, so the whole
  library runs on LuneBlox and a game's lint can call it off Roblox.
- No game's content lands here: no string a player reads, no game's name in code.

## Rules are proven, not argued

- Specs are strict: exact values, the negative case beside the positive one, no vacuous passes.
- A new rule lands with its spec and with a mutant in `tests/slips/`: the spec is seen failing
  against the broken line before it is trusted. `luneblox run tests/Mutate --yes` must kill every
  mutant. A mutant that cannot be killed because the code is the same either way means the line is
  not needed: the line goes, not the mutant alone.
- A spec is never loosened to make it pass.
- A plural rule is CLDR's. It changes against CLDR, with the counts that show it in the spec.
- `tests/consumer/Game.luau` uses the whole public API and is type-checked under both solvers; it
  changes with the API, and the README's example after it.

## Dependencies

- **No runtime dependencies.** `src/` is plain Luau.
- **Latest stable versions only.** Every tool and CI action is pinned exactly to its latest stable
  release at the time it is added or bumped (check with `gh release view -R owner/repo`). Never a
  prerelease, and never a pin copied from a sibling repo without checking.
- **LuneBlox is ours** (XopoIII/LuneBlox). When LocaleBlox needs something from it, the change is made
  there and flagged to the owner, not worked around here.

## Modern Luau: the version Roblox runs

- **`const`** for every binding that is never reassigned, including requires, module tables and
  functions (`const function`). `local` only for a binding that really is reassigned.
- **String requires**: `require("./Sibling")` between modules and `require("@self/Module")` in
  `init.luau`, so the same files load in Roblox and on LuneBlox.
- **The new type solver.** `scripts/type-check.sh` runs luau-lsp with `LuauSolverV2`, as Studio
  checks games, and checks the consumer file under the old solver too.
- No cast to `any` to silence a type.

## Architecture in one breath

- `Locale`: a LocaleId to a locale, and the lookup with its fallbacks. `Plural`: the category of a
  count. `Keys`: the key of a piece of game data.
- `Text`: the reader a client draws every word through, made from tables and a LocaleId.
- `Parse`, `Lint`, `Written`, `Usage`: the lint, as functions that return their problems.
- `init.luau` exposes the modules and re-exports their types.

## Distribution

- **Package:** pesde only (`xopoiii/localeblox`, `pesde.toml` and `pesde.lock`).
  `scripts/check-package.sh` checks that the built archive carries every file of `src/`.
- **Not shipped:** a Wally package, an `.rbxm`, roblox-ts typings.
- **A release** carries one version in `pesde.toml`, `pesde.lock` and `README.md` (the status line
  and the two install lines), and its entry in `CHANGELOG.md`.

## Releasing

The version bump and the changelog entry are part of the pull request, not of this list.

1. Merge the pull request with a merge commit (`gh pr merge <n> --merge`), then check out `main` and
   pull.
2. On the merged `main`, run `sh scripts/check-package.sh`, `sh scripts/run-tests.sh` and
   `luneblox run tests/Mutate --yes`. All must pass there, not only on the branch.
3. Tag and push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.
4. Create the GitHub Release: `gh release create vX.Y.Z --title "LocaleBlox X.Y.Z" --notes-file <notes>`.
   The notes hold, in order: a summary line, the changelog entry's sections, **Evidence** (the spec
   count, the mutants killed, the gates that passed, anything run in a game, and anything that
   was not), **Known, not fixed** when there is something, and **Install** (the pesde line).
5. Publish the package: `pesde publish --yes` (after `pesde auth login` once per machine). A
   published version cannot be replaced, so it comes after the tag and the release.
6. Pin the new version in the games that use it, in each game's own repository.

## Commits

- A plain declarative English subject, no conventional-commit prefix.
- The body says what changed and why, in prose.
- A closing "Checked:" paragraph lists what was run and what it reported.
- One commit a step; never commit with the gate red, never bypass a hook.

## Commands

| Command | What it does |
|---|---|
| `rokit install` | Installs the pinned toolchain (`rokit.toml`) |
| `lefthook install` | Installs the git hooks |
| `sh scripts/run-tests.sh` | Runs the suite on LuneBlox (`tests/Run.luau`) |
| `luneblox run tests/Mutate --yes` | Mutation adequacy: every mutant must fail the suite (`-- Plural` for one file) |
| `sh scripts/type-check.sh` | `luau-lsp analyze` over `src` and `tests`, and the consumer under the old solver |
| `selene src tests` | Lint |
| `stylua --check src tests` | Format check (`stylua src tests` to fix) |
| `sh scripts/check-strict.sh` | `--!strict` gate |
| `sh scripts/check-file-size.sh` | 300-line gate |
| `sh scripts/check-english.sh` | English-only gate |
| `sh scripts/check-package.sh` | The pesde archive carries all of `src/` (`pesde publish --dry-run`) |
| `lefthook run pre-commit --all-files` | Every pre-commit gate over the whole tree |
