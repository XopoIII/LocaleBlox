--!strict
--- A world the label specs can hold: instances with properties, attributes, tags and the signals
--- of each, and the collection service that knows which instance wears which tag. As much of the
--- engine as `Label` and `Localize` call, behaving as the engine does where it matters to them: a
--- property that is set to what it already holds fires nothing, and an instance has only the
--- properties it was made with.
local World = {}

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, listener: (...any) -> ()) -> Connection,
	Once: (self: Signal, listener: (...any) -> ()) -> Connection,
	--> Calls every listener. A spec's own lever; the engine has no such thing.
	fire: (...any) -> (),
	--> How many listeners are connected.
	count: () -> number,
}

export type World = {
	--> The collection service: `GetInstanceAddedSignal(tag)` and `GetTagged(tag)`.
	collection: any,
	--> A new instance with these properties. Typed loosely, as the library takes it.
	instance: (properties: { [string]: any }) -> any,
	--> Destroys an instance: its `Destroying` fires.
	destroy: (instance: any) -> (),
}

type Listener = { call: (...any) -> (), once: boolean }

function World.signal(): Signal
	local listeners: { Listener } = {}
	local signal = {} :: Signal

	local function connect(listener: (...any) -> (), once: boolean): Connection
		local entry: Listener = { call = listener, once = once }
		table.insert(listeners, entry)
		local connection = {} :: Connection
		function connection:Disconnect()
			local index = table.find(listeners, entry)
			if index ~= nil then
				table.remove(listeners, index)
			end
		end
		return connection
	end

	function signal:Connect(listener: (...any) -> ()): Connection
		return connect(listener, false)
	end

	function signal:Once(listener: (...any) -> ()): Connection
		return connect(listener, true)
	end

	function signal.fire(...: any)
		local now = listeners
		local kept: { Listener } = {}
		for _, listener in now do
			if not listener.once then
				table.insert(kept, listener)
			end
		end
		listeners = kept
		for _, listener in now do
			listener.call(...)
		end
	end

	function signal.count(): number
		return #listeners
	end

	return signal
end

function World.new(): World
	local added: { [string]: Signal } = {}
	local tagged: { [string]: { any } } = {}

	local function addedSignal(tag: string): Signal
		local signal = added[tag]
		if signal == nil then
			signal = World.signal()
			added[tag] = signal
		end
		return signal
	end

	local collection = {}
	function collection:GetInstanceAddedSignal(tag: string): Signal
		return addedSignal(tag)
	end
	function collection:GetTagged(tag: string): { any }
		return table.clone(tagged[tag] or {})
	end

	local world = {} :: World
	world.collection = collection

	function world.instance(properties: { [string]: any }): any
		local held: { [string]: any } = table.clone(properties)
		local attributes: { [string]: any } = {}
		local tags: { [string]: boolean } = {}
		local changed: { [string]: Signal } = {}

		local methods = {}
		methods.AttributeChanged = World.signal()
		methods.Destroying = World.signal()

		function methods:GetAttribute(name: string): any
			return attributes[name]
		end
		function methods:SetAttribute(name: string, value: any)
			if attributes[name] == value then
				return
			end
			attributes[name] = value
			methods.AttributeChanged.fire(name)
		end
		function methods:GetAttributes(): { [string]: any }
			return table.clone(attributes)
		end
		function methods:HasTag(tag: string): boolean
			return tags[tag] == true
		end
		function methods:GetPropertyChangedSignal(name: string): Signal
			if held[name] == nil then
				error(`{name} is not a valid property name.`, 2)
			end
			local signal = changed[name]
			if signal == nil then
				signal = World.signal()
				changed[name] = signal
			end
			return signal
		end

		local instance: any = setmetatable({}, {
			__index = function(_: any, name: string): any
				if methods[name] ~= nil then
					return methods[name]
				end
				return held[name]
			end,
			__newindex = function(_: any, name: string, value: any)
				if held[name] == nil then
					error(`{name} is not a valid member`, 2)
				end
				if held[name] == value then
					return
				end
				held[name] = value
				local signal = changed[name]
				if signal ~= nil then
					signal.fire()
				end
			end,
		})

		function methods:AddTag(tag: string)
			if tags[tag] then
				return
			end
			tags[tag] = true
			tagged[tag] = tagged[tag] or {}
			table.insert(tagged[tag], instance)
			addedSignal(tag).fire(instance)
		end

		return instance
	end

	function world.destroy(instance: any)
		instance.Destroying.fire()
	end

	return world
end

return World
