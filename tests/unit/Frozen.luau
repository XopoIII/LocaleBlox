--!strict
--- No module table can be written: a game that requires the package cannot change it for the
--- other scripts that do.
local LocaleBlox = require("@localeblox")
local Spec = require("../Spec")

local MODULES: { [string]: any } = {
	Keys = require("@localeblox/Keys"),
	Label = require("@localeblox/Label"),
	Lint = require("@localeblox/Lint"),
	Locale = require("@localeblox/Locale"),
	Localize = require("@localeblox/Localize"),
	Names = require("@localeblox/Names"),
	Parse = require("@localeblox/Parse"),
	Plural = require("@localeblox/Plural"),
	Said = require("@localeblox/Said"),
	Text = require("@localeblox/Text"),
	Usage = require("@localeblox/Usage"),
	Written = require("@localeblox/Written"),
}

-- The package as plain fields: its type lets nothing be written, and these specs try to.
local function fields(package: any): { [string]: any }
	return package
end

Spec.test("the package holds exactly its twelve modules, the same tables a module path gives", function()
	local package = fields(LocaleBlox)
	local names: { string } = {}
	for name, module in package do
		table.insert(names, name)
		Spec.truthy(rawequal(module, MODULES[name]), name)
	end
	table.sort(names)
	Spec.equal(names, {
		"Keys",
		"Label",
		"Lint",
		"Locale",
		"Localize",
		"Names",
		"Parse",
		"Plural",
		"Said",
		"Text",
		"Usage",
		"Written",
	})
end)

Spec.test("every module table is frozen", function()
	for name, module in MODULES do
		Spec.equal(table.isfrozen(module), true, name)
		Spec.throws(function()
			module.added = true
		end, "attempt to modify a readonly table")
		Spec.equal(module.added, nil, name)
	end
end)

Spec.test("the package itself is frozen", function()
	local package = fields(LocaleBlox)
	Spec.equal(table.isfrozen(package), true)
	Spec.throws(function()
		package.Text = nil
	end, "attempt to modify a readonly table")
	Spec.truthy(rawequal(package.Text, MODULES.Text))
end)

Spec.test("a reader is the caller's own table, and is not frozen", function()
	local reader = LocaleBlox.Text.new({ tables = { en = { feed = "Feed" } }, localeId = "en" })
	Spec.equal(table.isfrozen(reader), false)
end)

return nil
