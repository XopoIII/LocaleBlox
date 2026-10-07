--!strict
--- The mutants of src/Label.luau, src/Localize.luau and the names lint: each a small slip, and the
--- rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Label.luau",
		from = "\t\tif instance:GetAttribute(attribute) == encoded then\n\t\t\treturn\n\t\tend\n",
		to = "",
		breaks = "setting the same sentence again does nothing",
	},
	{
		file = "src/Label.luau",
		from = "instance[property] = self.english(key, args)",
		to = "instance[property] = key",
		breaks = "the property gets the English",
	},
	{
		file = "src/Label.luau",
		from = "\t\tinstance:SetAttribute(attribute, encoded)\n",
		to = "",
		breaks = "the sentence rides an attribute",
	},
	{
		file = "src/Label.luau",
		from = "\t\tinstance:AddTag(tag)\n",
		to = "",
		breaks = "a labelled instance is tagged",
	},
	{
		file = "src/Label.luau",
		from = "const attribute = prefix .. property",
		to = "const attribute = Label.PREFIX .. property",
		breaks = "a game's own prefix names the attribute",
	},
	{
		file = "src/Label.luau",
		from = "const tag = options.tag or Label.TAG",
		to = "const tag = Label.TAG",
		breaks = "a game's own tag is used",
	},
	{
		file = "src/Label.luau",
		from = "return if ok then text else reader.get(key)",
		to = "return if ok then text else key",
		breaks = "a sentence that does not fit reads as its template",
	},
	{
		file = "src/Label.luau",
		from = "const ok, text = pcall(reader.get, key, table.unpack(args))",
		to = "const ok, text = true, reader.get(key, table.unpack(args))",
		breaks = "a sentence that does not fit raises nothing",
	},
	{
		file = "src/Label.luau",
		from = "\t\tinstance:SetAttribute(prefix .. property, nil)\n",
		to = "",
		breaks = "plain text drops the sentence",
	},
	{
		file = "src/Label.luau",
		from = "\t\tinstance:SetAttribute(prefix .. property, nil)\n\t\tinstance[property] = text\n",
		to = "\t\tinstance:SetAttribute(prefix .. property, nil)\n",
		breaks = "plain text is written",
	},
	{
		file = "src/Localize.luau",
		from = "\tfor _, instance in options.collection:GetTagged(tag) do\n\t\twatch(instance)\n\tend\n",
		to = "",
		breaks = "an instance tagged before the client ran is rewritten",
	},
	{
		file = "src/Localize.luau",
		from = "\toptions.collection:GetInstanceAddedSignal(tag):Connect(watch)\n",
		to = "",
		breaks = "an instance tagged later is rewritten",
	},
	{
		file = "src/Localize.luau",
		from = "\t\tinstance.AttributeChanged:Connect(saw)\n",
		to = "",
		breaks = "the server saying something new is drawn anew",
	},
	{
		file = "src/Localize.luau",
		from = "\t\t\tsignal:Connect(function()\n\t\t\t\tapply(instance, attribute)\n\t\t\tend)\n",
		to = "",
		breaks = "English landing after its attribute is put back",
	},
	{
		file = "src/Localize.luau",
		from = "\t\tif value == nil then\n\t\t\treturn\n\t\tend\n",
		to = '\t\tif value == nil then\n\t\t\tinstance[string.sub(attribute, #prefix + 1)] = ""\n\t\t\treturn\n\t\tend\n',
		breaks = "plain text is left alone by the client",
	},
	{
		file = "src/Localize.luau",
		from = 'if words ~= "" then',
		to = "if true then",
		breaks = "an attribute that is no sentence writes nothing",
	},
	{
		file = "src/Localize.luau",
		from = "if string.sub(attribute, 1, #prefix) == prefix then",
		to = "if true then",
		breaks = "only a sentence's attribute is followed",
	},
	{
		file = "src/Localize.luau",
		from = "\t\tif watched[instance] ~= nil then\n\t\t\treturn\n\t\tend\n",
		to = "",
		breaks = "an instance is watched once",
	},
	{
		file = "src/Localize.luau",
		from = "\t\tif properties == nil or properties[attribute] then\n\t\t\treturn\n\t\tend\n",
		to = "\t\tif properties == nil then\n\t\t\treturn\n\t\tend\n",
		breaks = "a property is followed once",
	},
	{
		file = "src/Localize.luau",
		from = "const tag = options.tag or Label.TAG",
		to = "const tag = Label.TAG",
		breaks = "the client reads the game's own tag",
	},
	{
		file = "src/Localize.luau",
		from = "const prefix = options.prefix or Label.PREFIX",
		to = "const prefix = Label.PREFIX",
		breaks = "the client reads the game's own prefix",
	},
	{
		file = "src/Lint.luau",
		from = 'if name == nil or name == "" then',
		to = "if name == nil then",
		breaks = "an empty name is missing",
	},
	{
		file = "src/Lint.luau",
		from = "\t\t\ttaken[name] = id\n",
		to = "",
		breaks = "two ids with one name are told",
	},
	{
		file = "src/Lint.luau",
		from = "const word = uiWords[string.lower(name)]",
		to = "const word = uiWords[name]",
		breaks = "a name is a UI word whatever its case",
	},
	{
		file = "src/Lint.luau",
		from = "const ownWords = ui[code]",
		to = "const ownWords = ui.en",
		breaks = "a name is compared with its own locale's words",
	},
	{
		file = "src/Lint.luau",
		from = "\t\t\tif not known[id] then\n",
		to = "\t\t\tif false then\n",
		breaks = "a table entry that is no id is told",
	},
	{
		file = "src/Lint.luau",
		from = "\t\tif names[code] == nil then\n",
		to = "\t\tif false then\n",
		breaks = "a locale with no table is told",
	},
	{
		file = "src/Lint.luau",
		from = 'const place = where or "names"',
		to = 'const place = "names"',
		breaks = "a problem says where the game keeps its names",
	},
}

return MUTANTS
