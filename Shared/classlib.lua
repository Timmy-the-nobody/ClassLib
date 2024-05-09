--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

ClassLib = {}
local tClassesMap = {}
local tEventsMap = {
	["ClassLib:Constructor"] = "C0",
	["ClassLib:Destructor"] = "C1",
	["ClassLib:SetValue"] = "C2",
	["ClassLib:CLToSV"] = "C3",
	["ClassLib:SVToCL"] = "C4",
	["ClassLib:SyncAllClassInstances"] = "C5",
}

local tCopyFromParentClassOnInherit = {
	"__newindex",
	"__call",
	"__len",
	"__unm",
	"__add",
	"__sub",
	"__mul",
	"__div",
	"__pow",
	"__concat",
	"__tostring"
}

local tCopyFromClassOnNewInstance = {
	"__newindex",
	"__call",
	"__unm",
	"__add",
	"__sub",
	"__mul",
	"__div",
	"__pow",
	"__concat",
	"__tostring"
}

-- Cache some globals
local type = type
local setmetatable = setmetatable
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local error = error
local assert = assert
local rawget = rawget

-- Utils
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which an object inherits
---@param oInput table @The object
---@return table|nil @The super class
---
function ClassLib.Super(oInput)
	local tMT = getmetatable(oInput)
	if not tMT then return end

	return tMT.__super
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which an object inherits
---@param oInput table @The object
---@return table<integer, table> @The super classes
---
function ClassLib.SuperAll(oInput)
	local tSuper = {}
	local oSuper = ClassLib.Super(oInput) or {}

	while oSuper do
		tSuper[#tSuper + 1] = oSuper

		local oNextSuper = ClassLib.Super(oSuper)
		if not oNextSuper or (oNextSuper == oSuper) then break end

		oSuper = oNextSuper
	end

	return tSuper
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes that inherit from the passed class
---@param oClass table @The class
---@return table<integer, table> @The inherited classes
---
function ClassLib.GetInheritedClasses(oClass)
    local tMT = getmetatable(oClass)
    if not tMT then return {} end

    return tMT.__inherited_classes or {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if a value is an object from a class, or from a class that inherits from the passed class
---@param xVal any @The value to check
---@param oClass table @The class to check against
---@param bRecursive boolean @Whether to check recursively
---@return boolean @Whether the value is an object from the class
---
function ClassLib.IsA(xVal, oClass, bRecursive)
	if (type(xVal) ~= "table") then return false end
	if (ClassLib.GetClass(xVal) == oClass) then return true end
	if not bRecursive then return false end

	for _, oSuper in ipairs(ClassLib.SuperAll(xVal)) do
		if (oSuper == oClass) then
			return true
		end
	end

	return false
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the passed object is a valid instance
---@param oInstance table @The instance to check
---@return boolean @True if the instance is valid, false otherwise
---
function ClassLib.IsValid(oInstance)
	if (type(oInstance) ~= "table") then return false end

	local oClass = ClassLib.GetClass(oInstance)
	if (type(oClass) ~= "table") then return false end

	local tMT = getmetatable(oInstance)
	return (tMT.__is_valid ~= nil)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the passed object is being destroyed
---@param oInstance table @The instance to check
---@return boolean @True if the instance is being destroyed, false otherwise
---
function ClassLib.IsBeingDestroyed(oInstance)
	if (type(oInstance) ~= "table") then return false end

	local oClass = ClassLib.GetClass(oInstance)
	if (type(oClass) ~= "table") then return false end

	local tMT = getmetatable(oInstance)
	return (tMT.__is_being_destroyed ~= nil)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class of an object
---@param oInstance table @The object
---@return table|nil @The class
---
function ClassLib.GetClass(oInstance)
	if (type(oInstance) ~= "table") then return end

	local tMT = getmetatable(oInstance)
	if not tMT then return end

	return tMT.__index
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the ID of the instance, unique to the class
---@return integer|nil @Instance ID
---
function ClassLib.GetID(oInstance)
	if (type(oInstance) ~= "table") or not oInstance.GetValue then return end
	return oInstance:GetValue("id")
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a class object by its name
---@param sClassName string @The name of the class
---@return table|nil @The class
---
function ClassLib.GetClassByName(sClassName)
	return tClassesMap[sClassName]
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the name of a class
---@param oClass table @The class
---@return string|nil @The name of the class
---
function ClassLib.GetClassName(oClass)
	local tMT = getmetatable(oClass)
	if not tMT then return end

	return tMT.__classname
end

-- Local Events
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event
---@param oInput table @The object to call the event on
---@param sEvent string @The name of the event to call
---@param ... any @The arguments to pass to the event
---
function ClassLib.Call(oInput, sEvent, ...)
	local tMT = getmetatable(oInput)
	local tEvents = tMT.__events

	if tEvents and tEvents[sEvent] then
		for _, callback in ipairs(tEvents[sEvent]) do
			if (callback(...) == false) then
				ClassLib.Unsubscribe(oInput, sEvent, callback)
			end
		end
	end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event
---@param oInput table @The object that will subscribe to the event
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered, return false to unsubscribe from the event
---@return function|nil @The callback
---
function ClassLib.Subscribe(oInput, sEvent, callback)
	local tEvents = getmetatable(oInput).__events
	if not tEvents then return end

	tEvents[sEvent] = tEvents[sEvent] or {}
	tEvents[sEvent][#tEvents[sEvent] + 1] = callback

	return callback
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events in this Class, optionally passing the function to unsubscribe only that callback
---@param oInput table @The object to unsubscribe from
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
---
function ClassLib.Unsubscribe(oInput, sEvent, callback)
	local tEvents = getmetatable(oInput).__events
	if not tEvents[sEvent] then return end

	if (type(callback) ~= "function") then
		tEvents[sEvent] = nil
		return
	end

	local tNew = {}
	for i, v in ipairs(tEvents[sEvent]) do
		if (v ~= callback) then
			tNew[#tNew + 1] = v
		end
	end

	tEvents[sEvent] = tNew
end

-- Remote Events
------------------------------------------------------------------------------------------

if Client then
	---`🔸 Client`<br>
	---Calls a remote event from the client to the server
	---@param oInput table @The object to call the event from
	---@param sEvent string @The name of the event to call
	---@param ... any @The arguments to pass to the event
	---
	function ClassLib.CallRemote_Client(oInstance, sEvent, ...)
		if (type(sEvent) ~= "string") then return end

		local sClass = ClassLib.GetClassName(oInstance)
		if not sClass then return end

		Events.CallRemote(tEventsMap["ClassLib:CLToSV"], sClass, oInstance:GetID(), sEvent, ...)
	end

	Events.SubscribeRemote(tEventsMap["ClassLib:SVToCL"], function(sClassName, iID, sEvent, ...)
		local tClass = tClassesMap[sClassName]
		if not tClass then return end

		local tClassMT = getmetatable(tClass)
		local tRemoteEvents = tClassMT.__remote_events
		if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

		local oInstance = tClassMT.__instances_map[iID]
		if oInstance then
			for _, callback in ipairs(tRemoteEvents[sEvent]) do
				callback(oInstance, ...)
			end
			return
		end

		-- Wait for the instance to spawn if it hasn't already
		local varArgs = {...}
		tClass.ClassSubscribe("Spawn", function(self)
			if (self:GetID() ~= iID) then return end

			for _, callback in ipairs(tRemoteEvents[sEvent]) do
				callback(self, table.unpack(varArgs))
			end
			return false
		end)
	end)

elseif Server then
	---`🔹 Server`<br>
	---Calls a remote event from the server to the client
	---@param oInput table @The object to call the event on
	---@param sEvent string @The name of the event to call
	---@param xPlayer Player|table<number, Player> @The player (or table of players) to send the event to
	---@param ... any @The arguments to pass to the event
	---
	function ClassLib.CallRemote_Server(oInstance, sEvent, xPlayer, ...)
		if (type(sEvent) ~= "string") then return end

		local sClass = ClassLib.GetClassName(oInstance)
		if not sClass then return end

		if (getmetatable(xPlayer) == Player) then
			Events.CallRemote(tEventsMap["ClassLib:SVToCL"], xPlayer, sClass, oInstance:GetID(), sEvent, ...)
			return
		end

		if (type(xPlayer) ~= "table") then return end

		local iID = oInstance:GetID()
		for _, pPlayer in ipairs(xPlayer) do
			if (getmetatable(pPlayer) == Player) then
				Events.CallRemote(tEventsMap["ClassLib:SVToCL"], pPlayer, sClass, iID, sEvent, ...)
			end
		end
	end

	---`🔹 Server`<br>
	---Broadcasts a remote event from the server to all connected clients
	---@param oInput table @The object to broadcast the event on
	---@param sEvent string @The name of the event to broadcast
	---@param ... any @The arguments to pass to the event
	---
	function ClassLib.BroadcastRemote(oInstance, sEvent, ...)
		if (type(sEvent) ~= "string") then return end

		local sClass = ClassLib.GetClassName(oInstance)
		if not sClass then return end

		Events.BroadcastRemote(tEventsMap["ClassLib:SVToCL"], sClass, oInstance:GetID(), sEvent, ...)
	end

	Events.SubscribeRemote(tEventsMap["ClassLib:CLToSV"], function(pPlayer, sClassName, iID, sEvent, ...)
		local tClass = tClassesMap[sClassName]
		if not tClass then return end

		local oInstance = getmetatable(tClass).__instances_map[iID]
		if not oInstance then return end

		local tRemoteEvents = getmetatable(tClass).__remote_events
		if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

		for _, callback in ipairs(tRemoteEvents[sEvent]) do
			callback(oInstance, pPlayer, ...)
		end
	end)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to a remote event
---@param oInput table @The object that will subscribe to the event
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
---@return function|nil @The callback
---
function ClassLib.SubscribeRemote(oInstance, sEvent, callback)
	if (type(sEvent) ~= "string") then return end

	local tRemoteEvents = getmetatable(oInstance).__remote_events
	if not tRemoteEvents then return end

	tRemoteEvents[sEvent] = tRemoteEvents[sEvent] or {}
	tRemoteEvents[sEvent][#tRemoteEvents[sEvent] + 1] = callback

	return callback
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from a remote event
---@param oInput table @The object to unsubscribe from
---@param sEvent string @The name of the event to unsubscribe from+
---@param callback? function @The callback to unsubscribe
---
function ClassLib.UnsubscribeRemote(oInstance, sEvent, callback)
	if (type(sEvent) ~= "string") then return end

	local tRemoteEvents = getmetatable(oInstance).__remote_events
	if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

	if (type(callback) ~= "function") then
		tRemoteEvents[sEvent] = nil
		return
	end

	local tNewCallbacks = {}
	for _, v in ipairs(tRemoteEvents[sEvent]) do
		if (v ~= callback) then
			tNewCallbacks[#tNewCallbacks + 1] = v
		end
	end

	tRemoteEvents[sEvent] = tNewCallbacks
end

-- ClassLib
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from the passed class
---@param oInheritFrom table @The class to inherit from
---@param sClassName string @The name of the class
---@param bSync boolean @Whether to broadcast the creation of a new instance of the class
---@return table @The new class
---
function ClassLib.Inherit(oInheritFrom, sClassName, bSync)
	if (type(sClassName) ~= "string") then error("[ClassLib] Attempt to create a class with a nil name") end
	if tClassesMap[sClassName] then
		Console.Warn("[ClassLib] Attempt to create a class with a name that already exists")
		return tClassesMap[sClassName]
	end

	assert((type(oInheritFrom) == "table"), "[ClassLib] Attempt to extend from a nil class value")

	bSync = (bSync and true or false)

	local tFromMT = getmetatable(oInheritFrom)

	local tNewMT = {}
	for _, sKey in ipairs(tCopyFromParentClassOnInherit) do
		tNewMT[sKey] = tFromMT[sKey]
	end

	tNewMT.__index = oInheritFrom
	tNewMT.__super = oInheritFrom
	tNewMT.__name = ("%s Class"):format(sClassName)
	tNewMT.__classname = sClassName
	tNewMT.__events = {}
	tNewMT.__remote_events = {}
	tNewMT.__instances = {}
	tNewMT.__instances_map = {}
	tNewMT.__next_id = 1
	tNewMT.__broadcast_creation = bSync
	tNewMT.__inherited_classes = {}

	local oNewClass = setmetatable({}, tNewMT)
	local tClassMT = getmetatable(oNewClass)

	-- Add static functions to the new class
    function oNewClass.GetAll() return tClassMT.__instances end
	function oNewClass.GetCount() return #tClassMT.__instances end
	function oNewClass.GetByID(iID) return tClassMT.__instances_map[iID] end
	function oNewClass.GetParentClass() return ClassLib.Super(oNewClass) end
	function oNewClass.GetAllParentClasses() return ClassLib.SuperAll(oNewClass) end
	function oNewClass.IsChildOf(oClass) return ClassLib.IsA(oNewClass, oClass, true) end
	function oNewClass.Inherit(...) return ClassLib.Inherit(oNewClass, ...) end
	function oNewClass.GetInheritedClasses() return ClassLib.GetInheritedClasses(oNewClass) end

	-- Adds static functions related to local events to the new class
	function oNewClass.ClassCall(sEvent, ...) return ClassLib.Call(oNewClass, sEvent, ...) end
	function oNewClass.ClassSubscribe(...) return ClassLib.Subscribe(oNewClass, ...) end
	function oNewClass.ClassUnsubscribe(...) return ClassLib.Unsubscribe(oNewClass, ...) end

	-- Adds static functions related to remote events to the new class
	function oNewClass.SubscribeRemote(...) return ClassLib.SubscribeRemote(oNewClass, ...) end
	function oNewClass.UnsubscribeRemote(...) return ClassLib.UnsubscribeRemote(oNewClass, ...) end

	tClassesMap[sClassName] = oNewClass

	tFromMT.__inherited_classes = tFromMT.__inherited_classes or {}
	tFromMT.__inherited_classes[#tFromMT.__inherited_classes + 1] = oNewClass

	ClassLib.Call(oInheritFrom, "ClassRegister", oNewClass)

	return oNewClass
end

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new instance of the passed class
---@param oClass table @The class to create an instance of
---@param iForcedID? number @The forced ID of the instance, used for syncing
---@param ... any @The arguments to pass to the constructor
---@return table @The new instance
---
function ClassLib.NewInstance(oClass, iForcedID, ...)
	assert((type(oClass) == "table"), "[ClassLib] Attempt to create a new instance from a nil class value")

	local tClassMT = getmetatable(oClass)

	local tNewMT = {}
	for _, sKey in ipairs(tCopyFromClassOnNewInstance) do
		tNewMT[sKey] = tClassMT[sKey]
	end

	tNewMT.__index = oClass
	tNewMT.__super = ClassLib.Super(oClass)
	tNewMT.__name = tClassMT.__classname
	tNewMT.__classname = tClassMT.__classname
	tNewMT.__is_valid = true
	tNewMT.__events = {}
	tNewMT.__values = {}
	tNewMT.__broadcasted_values = {}

	local oInstance = setmetatable({}, tNewMT)

	-- Add instance to the class instance table
	ClassLib.SetValue(oInstance, "id", iForcedID or tClassMT.__next_id)

	tClassMT.__next_id = (tClassMT.__next_id + 1)
	tClassMT.__instances[#tClassMT.__instances + 1] = oInstance

	-- Call constructor
	if rawget(oClass, "Constructor") then
		rawget(oClass, "Constructor")(oInstance, ...)
	end

	ClassLib.Call(oClass, "Spawn", oInstance)

	if tClassMT.__broadcast_creation and Server then
		ClassLib.SyncInstanceConstruct(oInstance)
	end

	return oInstance
end

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys an instance of a class
---@param oInstance table @The instance to destroy
---
function ClassLib.Destroy(oInstance, ...)
	assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to destroy an invalid object")

	local oClass = ClassLib.GetClass(oInstance)
	assert((type(oClass) == "table"), "[ClassLib] Called ClassLib.Delete without a valid class instance")

	-- Call class destructor
	if rawget(oClass, "Destructor") then
		-- If the destructor returns false, don't destroy the instance
		local bShouldDestroy = rawget(oClass, "Destructor")(oInstance, ...)
		if (bShouldDestroy == false) then return end
	end

	local tMT = getmetatable(oInstance)
	tMT.__is_being_destroyed = true

	ClassLib.Call(oClass, "Destroy", oInstance)
	ClassLib.Call(oInstance, "Destroy", oInstance)

	-- Clears the instance from it's class instance table
	local tClassMT = getmetatable(oClass)
	local tNewList = {}
	for _, v in ipairs(tClassMT.__instances) do
        if (v ~= oInstance) then
            tNewList[#tNewList + 1] = v
        end
    end
	tClassMT.__instances = tNewList
	tClassMT.__instances_map[oInstance:GetID()] = nil

	if tClassMT.__broadcast_creation and Server then
		ClassLib.SyncInstanceDestroy(oInstance)
	end

	-- Prevent access to the instance
	tMT.__is_valid = nil
	tMT.__is_being_destroyed = nil

	-- function tMT:__call() error("[ClassLib] Attempt to access a destroyed object") end
	-- function tMT:__index() error("[ClassLib] Attempt to access a destroyed object") end
	function tMT:__newindex() error("[ClassLib] Attempt to set a value on a destroyed object") end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Clones an instance, and return a new instance with the same values (except it's ID)
---@param oInstance table @The instance to clone
---@param tIgnoredKeys? table @The properties to ignore (sequential table)
---@param ... any @The arguments to pass to the constructor
---@return table @The new instance
---
function ClassLib.Clone(oInstance, tIgnoredKeys, ...)
	assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to clone an invalid object")

	local oClass = ClassLib.GetClass(oInstance)
	assert((type(oClass) == "table"), "[ClassLib] The object passed to ClassLib.Clone has no valid class")

	local oClone = ClassLib.NewInstance(oClass, nil, ...)
	local bCheckIgnoredKeys = (type(tIgnoredKeys) == "table")

	-- Copy classic values
	for sKey, xVal in pairs(oInstance) do
		if (sKey == "id") then goto continue end
		if bCheckIgnoredKeys then
			for _, sIgnoredKey in ipairs(tIgnoredKeys) do
				if (sKey == sIgnoredKey) then goto continue end
			end
		end

		oClone[sKey] = xVal
		::continue::
	end

	-- Copy classlib values
	local tBroadcastedValues = ClassLib.GetAllValuesKeys(oInstance, true)

	for sKey, xVal in pairs(ClassLib.GetAllValuesKeys(oInstance, false)) do
		if (sKey == "id") then goto continue end
		if bCheckIgnoredKeys then
			for _, sIgnoredKey in ipairs(tIgnoredKeys) do
				if (sKey == sIgnoredKey) then goto continue end
			end
		end

		local bBroadcast = (tBroadcastedValues[sKey] and Server)
		ClassLib.SetValue(oClone, sKey, xVal, bBroadcast)
		::continue::
	end

	return oClone
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets a value on an instance
---@param oInstance table @The instance to set the value on
---@param sKey string @The key to set the value on
---@param xValue any @The value to set
---@param bBroadcast? boolean @Server: Whether to broadcast the value change, Client: Mark the value as broadcasted
---@return boolean|nil @Return true if the value was set, nil otherwise
---
function ClassLib.SetValue(oInstance, sKey, xValue, bBroadcast)
	assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to set a value on an invalid object")
	assert((type(sKey) == "string"), "[ClassLib] The key passed to ClassLib.SetValue is not a string")
	assert((type(xValue) ~= "function"), "[ClassLib] Attempt to set a function as a value")

	local tMT = getmetatable(oInstance)
	if not tMT then return end

	-- Handle ID change
	if (sKey == "id") then
		assert((type(xValue) == "number"), "[ClassLib] The ID passed to ClassLib.SetValue is not a number")
		assert((math.floor(xValue) == xValue), "[ClassLib] The ID passed to ClassLib.SetValue is not an integer")

		local tClass = oInstance:GetClass()
		if tClass then
			local tClassMT = getmetatable(tClass)
			if tClassMT and tClassMT.__instances_map then
				local iOldID = ClassLib.GetValue(oInstance, "id")
				-- Remove `[old ID] = instance` from the instance map
				if iOldID then
					tClassMT.__instances_map[iOldID] = nil
				end
				-- Store `[new ID] = instance in the instance map
				tClassMT.__instances_map[xValue] = oInstance
			end
		end
	end

	oInstance[sKey] = xValue
	tMT.__values[sKey] = xValue

	ClassLib.Call(ClassLib.GetClass(oInstance), "ValueChange", oInstance, sKey, xValue)
	ClassLib.Call(oInstance, "ValueChange", oInstance, sKey, xValue)

	if bBroadcast then
		tMT.__broadcasted_values[sKey] = xValue

		if Server then
			Events.BroadcastRemote(
				tEventsMap["ClassLib:SetValue"],
				oInstance:GetClassName(),
				oInstance:GetID(),
				sKey,
				xValue
			)
		end
	end

	return true
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets a value from an instance
---@param oInstance table @The instance to get the value from
---@param sKey string @The key to get the value from
---@param xFallback? any @Fallback value (if the instance or the key doesn't exist)
---@return any @Value
---
function ClassLib.GetValue(oInstance, sKey, xFallback)
	assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to get a value from an invalid object")

	local tMT = getmetatable(oInstance)
	if not tMT then return xFallback end

	if (tMT.__values[sKey] ~= nil) then
		return tMT.__values[sKey]
	end

	if (oInstance[sKey] ~= nil) then
		return oInstance[sKey]
	end

	return xFallback
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets all values from an instance
---@param oInstance table @The instance to get the values from
---@param bBroadcastedOnly? boolean @Whether to only get broadcasted values
---@return table @Table with the key as key and the value as value
---
function ClassLib.GetAllValuesKeys(oInstance, bBroadcastedOnly)
	assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to get all values from an invalid object")

	local tMT = getmetatable(oInstance)
	if not tMT then return {} end

	if bBroadcastedOnly then
		return tMT.__broadcasted_values
	end

	return tMT.__values
end

-- Sync
----------------------------------------------------------------------

if Server then
	---`🔹 Server`<br>
	---Checks if a key is broadcasted
	---@param oInstance table @The instance to check
	---@param sKey string @The key to check
	---@return boolean @Whether the key is broadcasted
	---
	function ClassLib.IsValueBroadcasted(oInstance, sKey)
		assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to check if a value is broadcasted from an invalid object")

		local tMT = getmetatable(oInstance)
		if not tMT then return false end
		return tMT.__broadcasted_values[sKey] ~= nil
	end

	---`🔹 Server`<br>
	---Internal function to sync the creation of an instance, you shouldn't call this directly
	---@param oInstance table @The instance to sync
	---@param pPlayer Player|nil @The player to send the sync to, nil to broadcast to all players
	---
	function ClassLib.SyncInstanceConstruct(oInstance, pPlayer)
		assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to sync the construction of an invalid object")

		if (getmetatable(pPlayer) == Player) then
			Events.CallRemote(
				tEventsMap["ClassLib:Constructor"],
				pPlayer,
				oInstance:GetClassName(),
				oInstance:GetID(),
				getmetatable(oInstance).__broadcasted_values
			)
			return
		end

		Events.BroadcastRemote(
			tEventsMap["ClassLib:Constructor"],
			oInstance:GetClassName(),
			oInstance:GetID(),
			getmetatable(oInstance).__broadcasted_values
		)
	end

	---`🔹 Server`<br>
	---Internal function to sync all instances of a class, you shouldn't call this directly
	---@param sClass string @The class to sync
	---@param pPlayer Player @The player to send the sync to
	---
	function ClassLib.SyncAllClassInstances(sClass, pPlayer)
		assert((tClassesMap[sClass] ~= nil), "[ClassLib] Attempt to sync all instances of an invalid class")
		assert((getmetatable(pPlayer) == Player), "[ClassLib] Attempt to sync all instances to an invalid player")

		local tClass = tClassesMap[sClass]
		local tClassMT = getmetatable(tClass)

		if not tClassMT.__broadcast_creation then return end
		if (#tClassMT.__instances == 0) then return end

		local tSyncInstances = {}
		for _, oInstance in ipairs(tClassMT.__instances) do
			if not oInstance:IsValid() then goto continue end
			if oInstance:IsBeingDestroyed() then goto continue end

			tSyncInstances[#tSyncInstances + 1] = {
				oInstance:GetID(),
				getmetatable(oInstance).__broadcasted_values
			}

			::continue::
		end

		Events.CallRemote(
			tEventsMap["ClassLib:SyncAllClassInstances"],
			pPlayer,
			sClass,
			tSyncInstances
		)
	end

	---`🔹 Server`<br>
	---Internal function to sync the destruction of an instance (to all players), you shouldn't call this directly
	---@param oInstance table @The instance to sync
	---
	function ClassLib.SyncInstanceDestroy(oInstance)
		assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to sync the destruction of an invalid object")

		Events.BroadcastRemote(
			tEventsMap["ClassLib:Destructor"],
			oInstance:GetClassName(),
			oInstance:GetID()
		)
	end

	-- Old "SyncAll" event
	Player.Subscribe("Ready", function(pPlayer)
		for sClass, oClass in pairs(tClassesMap) do
			local tClassMT = getmetatable(oClass)
			if not tClassMT.__broadcast_creation then goto continue end
			if (#tClassMT.__instances == 0) then goto continue end

			for _, oInstance in ipairs(tClassMT.__instances) do
				ClassLib.SyncInstanceConstruct(oInstance, pPlayer)
			end

			::continue::
			ClassLib.SyncAllClassInstances(sClass, pPlayer)
		end
	end)

	-- New "SyncAll" event
	-- Player.Subscribe("Ready", function(pPlayer)
	-- 	for sClass, oClass in pairs(tClassesMap) do
	-- 		ClassLib.SyncAllClassInstances(sClass, pPlayer)
	-- 	end
	-- end)
end

if Client then
	-- Net Event: "ClassLib:Constructor"
	Events.SubscribeRemote(tEventsMap["ClassLib:Constructor"], function(sClassName, iID, tBroadcastedValues)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		local oInstance = ClassLib.NewInstance(tClass, iID)

		for sKey, xValue in pairs(tBroadcastedValues) do
			ClassLib.SetValue(oInstance, sKey, xValue, true)
		end
	end)

	-- Net Event: "ClassLib:Destructor"
	Events.SubscribeRemote(tEventsMap["ClassLib:Destructor"], function(sClassName, iID)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		ClassLib.Destroy(tClass.GetByID(iID))
	end)

	-- Net Event: "ClassLib:SetValue"
	Events.SubscribeRemote(tEventsMap["ClassLib:SetValue"], function(sClassName, iID, sKey, xValue)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		local oInstance = tClass.GetByID(iID)
		if not oInstance then return end

		ClassLib.SetValue(oInstance, sKey, xValue, true)
	end)

	-- Net Event: "ClassLib:SyncAllClassInstances"
	Events.SubscribeRemote(tEventsMap["ClassLib:SyncAllClassInstances"], function(sClassName, tInstances)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		for _, tInstance in ipairs(tInstances) do
			local oInstance = ClassLib.NewInstance(tClass, tInstance[1])

			for sKey, xValue in pairs(tInstance[2]) do
				ClassLib.SetValue(oInstance, sKey, xValue, true)
			end
		end
	end)
end