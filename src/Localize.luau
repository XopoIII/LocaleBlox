--!strict
--- Puts a server's labels into the reader's language, on the client.
---
---     Localize.start({ said = said, text = text, collection = CollectionService })
---
--- The server writes a sign, a prompt or a billboard as a key and its arguments (`Label`): the
--- instance is tagged and carries one attribute a property (`Said_Text`). Each is rewritten here
--- through the reader, and again whenever the server says something new. A local write never
--- replicates, and the server's next change of the attribute replaces it, so the two never fight.
---
--- `collection` is the engine's CollectionService, handed in: this module calls
--- `GetInstanceAddedSignal` and `GetTagged` on it and the attribute and property signals of each
--- tagged instance. It reads no service itself and never touches `game`.
local Label = require("./Label")
local Said = require("./Said")
local Text = require("./Text")

local Localize = {}

export type Options = {
	--- The game's sentences (`Said.new`), the same codec the server's `Label` writes with.
	said: Said.Said,
	--- This client's reader.
	text: Text.Reader,
	--- CollectionService, or anything that answers `GetInstanceAddedSignal(tag)` and `GetTagged(tag)`.
	collection: any,
	--- The tag a labelled instance carries. "Localized" by default; the server's `Label` must agree.
	tag: string?,
	--- What a sentence's attribute is called before the property's name. "Said_" by default.
	prefix: string?,
}

--> Starts rewriting every tagged instance, those there now and those that come.
function Localize.start(options: Options)
	local said = options.said
	local text = options.text
	local tag = options.tag or Label.TAG
	local prefix = options.prefix or Label.PREFIX

	local function apply(instance: any, attribute: string)
		local value = instance:GetAttribute(attribute)
		if value == nil then
			return
		end
		local words = said.read(text, value)
		if words ~= "" then
			-- A property the instance does not have costs this label, not the others.
			pcall(function()
				instance[string.sub(attribute, #prefix + 1)] = words
			end)
		end
	end

	local watched: { [any]: { [string]: boolean } } = {}
	local connections: { [any]: { any } } = {}

	-- Every listener of an instance is held, so it can be dropped when the instance is destroyed:
	-- a label's listeners must not keep a dead sign alive. A connection that lands after the
	-- instance went is dropped at once.
	local function hold(instance: any, connection: any)
		local list = connections[instance]
		if list ~= nil then
			table.insert(list, connection)
		else
			connection:Disconnect()
		end
	end

	-- The server's English can land after its attribute, so a property that changes under a sentence
	-- is put back into the reader's language. Setting the same text again fires nothing, so this
	-- settles at once.
	local function follow(instance: any, attribute: string)
		local properties = watched[instance]
		if properties == nil or properties[attribute] then
			return
		end
		properties[attribute] = true
		local ok, signal = pcall(instance.GetPropertyChangedSignal, instance, string.sub(attribute, #prefix + 1))
		if ok then
			hold(
				instance,
				signal:Connect(function()
					apply(instance, attribute)
				end)
			)
		end
	end

	local function watch(instance: any)
		if watched[instance] ~= nil then
			return
		end
		watched[instance] = {}
		connections[instance] = {}
		instance.Destroying:Once(function()
			watched[instance] = nil
			for _, connection in connections[instance] do
				connection:Disconnect()
			end
			connections[instance] = nil
		end)
		local function saw(attribute: string)
			if string.sub(attribute, 1, #prefix) == prefix then
				follow(instance, attribute)
				apply(instance, attribute)
			end
		end
		for attribute in instance:GetAttributes() do
			saw(attribute)
		end
		hold(instance, instance.AttributeChanged:Connect(saw))
	end

	options.collection:GetInstanceAddedSignal(tag):Connect(watch)
	for _, instance in options.collection:GetTagged(tag) do
		watch(instance)
	end
end

return table.freeze(Localize)
