--!strict
--- The suite: every spec file, in order. A spec file runs its specs as it loads.
---
--- The whole library is plain Luau and runs here: nothing in it needs Roblox.
---
--- Run from the repository root: `luneblox run tests/Run --yes` (or `sh scripts/run-tests.sh`).
local Runtime = require("./Runtime")
local Spec = require("./Spec")

Runtime.notice()

require("./unit/Locale")
require("./unit/Plural")
require("./unit/Keys")
require("./unit/Text")
require("./unit/Misfit")
require("./unit/Names")
require("./unit/Said")
require("./unit/Label")
require("./unit/Parse")
require("./unit/Lint")
require("./unit/Written")
require("./unit/Usage")
require("./unit/Frozen")

Spec.finish()
