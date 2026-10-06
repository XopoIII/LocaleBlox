#!/usr/bin/env sh
# The type gate: `luau-lsp analyze` over every Luau file we own, in strict mode (.luaurc).
#
# `src/` is analysed against the Roblox API definitions, since it runs in Roblox. `tests/` runs on
# LuneBlox and sees both: the `@lune` typedefs through the .luaurc alias, and the Roblox definitions
# for the types the library itself names.
#
# The Roblox definitions are downloaded once per luau-lsp pin and kept out of git; `luneblox setup`
# writes the `@lune` typedefs that .luaurc aliases, so CI has them too.
#
# Usage: type-check.sh   (no arguments)
set -e
export PATH="$HOME/.rokit/bin:$PATH"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

for arg in "$@"; do
	echo "type-check: unknown argument '$arg' (it takes none; the whole tree is checked)" >&2
	exit 2
done

# The definitions come from the tag of the luau-lsp that rokit.toml pins, so the gate reads the same
# Roblox API on every machine and every day. A bump of that pin downloads them again.
lsp_version="$(sed -n 's/.*JohnnyMorganz\/luau-lsp@\([0-9.]*\)".*/\1/p' rokit.toml)"
if [ -z "$lsp_version" ]; then
	echo "type-check: no luau-lsp pin found in rokit.toml" >&2
	exit 1
fi
if [ ! -f globalTypes.d.luau ] || [ "$(cat globalTypes.d.luau.version 2>/dev/null)" != "$lsp_version" ]; then
	curl -fsSL -o globalTypes.d.luau \
		"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$lsp_version/scripts/globalTypes.d.luau"
	echo "$lsp_version" >globalTypes.d.luau.version
fi
luneblox setup >/dev/null

# The new type solver, as Roblox Studio runs it.
luau-lsp analyze --flag:LuauSolverV2=true --defs globalTypes.d.luau src tests

# A game may still be checked with the old solver: the public types must read the same to it.
# tests/consumer/Game.luau is a game's use of the whole public API and must be clean there too; the
# library's own files are the new solver's business, so they are ignored in this run.
luau-lsp analyze --flag:LuauSolverV2=false --defs globalTypes.d.luau --ignore "src/**" tests/consumer/Game.luau

echo "type-check: clean"
