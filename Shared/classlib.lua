--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

ClassLib = {}
local tClassesMap = {}
local tEventsMap = {
	["ClassLib:Constructor"] = "_::0",
	["ClassLib:Destructor"] = "_::1",
	["ClassLib:SetValue"] = "_::2",
	["ClassLib:CLToSV"] = "_::3",
	["ClassLib:SVToCL"] = "_::4",
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

------------------------------------------------------------------------------------------
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
	if (type(oInstance) ~= "table") then return end
	return oInstance.id
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

-- Internal function to get an instance by its ID
local function __getInstanceByID(tMT, iID)
	for _, oInstance in ipairs(tMT.__instances) do
		if (oInstance.id == iID) then
			return oInstance
		end
	end
end

------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------
-- Remote Events
------------------------------------------------------------------------------------------

if Client then
	---`🔸 Client`<br>
	---Calls a remote event from the client to the server
	---@param oInput table @The object to call the event from
	---@param sEvent string @The name of the event to call
	---@param ... any @The arguments to pass to the event
	---
	function ClassLib.CallRemote_Client(oInput, sEvent, ...)
		if (type(sEvent) ~= "string") then return end

		local sClass = ClassLib.GetClassName(oInput)
		if not sClass then return end

		Events.CallRemote(tEventsMap["ClassLib:CLToSV"], sClass, oInput:GetID(), sEvent, ...)
	end

	Events.SubscribeRemote(tEventsMap["ClassLib:SVToCL"], function(sClassName, iID, sEvent, ...)
		local tClass = tClassesMap[sClassName]
		if not tClass then return end

		local oInstance = __getInstanceByID(getmetatable(tClass), iID)
		if not oInstance then return end

		local tRemoteEvents = getmetatable(tClass).__remote_events
		if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

		for _, callback in ipairs(tRemoteEvents[sEvent]) do
			callback(oInstance, ...)
		end
	end)

elseif Server then
	---`🔹 Server`<br>
	---Calls a remote event from the server to the client
	---@param oInput table @The object to call the event on
	---@param sEvent string @The name of the event to call
	---@param xPlayer Player|table<number, Player> @The player (or table of players) to send the event to
	---@param ... any @The arguments to pass to the event
	---
	function ClassLib.CallRemote_Server(oInput, sEvent, xPlayer, ...)
		if (type(sEvent) ~= "string") then return end

		local sClass = ClassLib.GetClassName(oInput)
		if not sClass then return end

		if (getmetatable(xPlayer) == Player) then
			Events.CallRemote(tEventsMap["ClassLib:SVToCL"], xPlayer, sClass, oInput:GetID(), sEvent, ...)
			return
		end

		if (type(xPlayer) ~= "table") then return end

		for _, pPlayer in ipairs(xPlayer) do
			if (getmetatable(pPlayer) == Player) then
				Events.CallRemote(tEventsMap["ClassLib:SVToCL"], pPlayer, sClass, oInput:GetID(), sEvent, ...)
			end
		end
	end

	function ClassLib.BroadcastRemote(oInput, sEvent, ...)
		if (type(sEvent) ~= "string") then return end

		local sClass = ClassLib.GetClassName(oInput)
		if not sClass then return end

		Events.BroadcastRemote(tEventsMap["ClassLib:SVToCL"], sClass, oInput:GetID(), sEvent, ...)
	end

	Events.SubscribeRemote(tEventsMap["ClassLib:CLToSV"], function(pPlayer, sClassName, iID, sEvent, ...)
		local tClass = tClassesMap[sClassName]
		if not tClass then return end

		local oInstance = __getInstanceByID(getmetatable(tClass), iID)
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
function ClassLib.SubscribeRemote(oInput, sEvent, callback)
	if (type(sEvent) ~= "string") then return end

	local tRemoteEvents = getmetatable(oInput).__remote_events
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
function ClassLib.UnsubscribeRemote(oInput, sEvent, callback)
	if (type(sEvent) ~= "string") then return end

	local tRemoteEvents = getmetatable(oInput).__remote_events
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

------------------------------------------------------------------------------------------
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
	tNewMT.__classname = sClassName
	tNewMT.__events = {}
	tNewMT.__remote_events = {}
	tNewMT.__instances = {}
	tNewMT.__next_id = 1
	tNewMT.__broadcast_creation = bSync

	local oNewClass = setmetatable({}, tNewMT)
	local tClassMT = getmetatable(oNewClass)

	-- Add static functions to the new class
    function oNewClass.GetAll() return tClassMT.__instances end
	function oNewClass.GetCount() return #tClassMT.__instances end
	function oNewClass.GetByID(iID) return __getInstanceByID(tClassMT, iID) end
	function oNewClass.GetParentClass() return ClassLib.Super(oNewClass) end
	function oNewClass.GetAllParentClasses() return ClassLib.SuperAll(oNewClass) end
	function oNewClass.IsChildOf(oClass) return ClassLib.IsA(oNewClass, oClass, true) end
	function oNewClass.Inherit(...) return ClassLib.Inherit(oNewClass, ...) end

	-- Adds static functions related to local events to the new class
	function oNewClass.ClassCall(sEvent, ...) return ClassLib.Call(oNewClass, sEvent, ...) end
	function oNewClass.ClassSubscribe(...) return ClassLib.Subscribe(oNewClass, ...) end
	function oNewClass.ClassUnsubscribe(...) return ClassLib.Unsubscribe(oNewClass, ...) end

	-- Adds static functions related to remote events to the new class
	function oNewClass.SubscribeRemote(...) return ClassLib.SubscribeRemote(oNewClass, ...) end
	function oNewClass.UnsubscribeRemote(...) return ClassLib.UnsubscribeRemote(oNewClass, ...) end

	tClassesMap[sClassName] = oNewClass

	ClassLib.Call(oInheritFrom, "ClassRegister", oNewClass)

	return oNewClass
end

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new instance of the passed class
---@param oClass table @The class to create an instance of
---@return table @The new instance
---
function ClassLib.NewInstance(oClass, ...)
	assert((type(oClass) == "table"), "[ClassLib] Attempt to create a new instance from a nil class value")

	local tClassMT = getmetatable(oClass)

	local tNewMT = {}
	for _, sKey in ipairs(tCopyFromClassOnNewInstance) do
		tNewMT[sKey] = oClass[sKey]
	end

	tNewMT.__index = oClass
	tNewMT.__super = ClassLib.Super(oClass)
	tNewMT.__classname = tClassMT.__classname
	tNewMT.__is_valid = true
	tNewMT.__events = {}
	tNewMT.__broadcasted_values = {}

	local oInstance = setmetatable({}, tNewMT)

	-- Add instance to the class instance table
    oInstance.id = tClassMT.__next_id

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
	if not oInstance.IsValid or not oInstance:IsValid() then
		error("[ClassLib] Attempt to delete an invalid object")
	end

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
---@return table @The new instance
---
function ClassLib.Clone(oInstance, tIgnoredKeys)
	assert((type(oInstance) == "table"), "[ClassLib] The object passed to ClassLib.Clone is not a table")

	local oClass = ClassLib.GetClass(oInstance)
	assert((type(oClass) == "table"), "[ClassLib] The object passed to ClassLib.Clone has no valid class")

	local oClone = ClassLib.NewInstance(oClass)
	local bCheckIgnoredKeys = (type(tIgnoredKeys) == "table")

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

	return oClone
end

----------------------------------------------------------------------
-- Sync
----------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Sets a value on an instance
---@param oInstance table @The instance to set the value on
---@param sKey string @The key to set the value on
---@param xValue any @The value to set
---@param bBroadcast? boolean @Whether to broadcast the value change (server only)
---@return boolean|nil @Return true if the value was set, nil otherwise
---
function ClassLib.SetValue(oInstance, sKey, xValue, bBroadcast)
	assert((type(oInstance) == "table"), "[ClassLib] The object passed to ClassLib.SetValue is not a table")
	assert((type(sKey) == "string"), "[ClassLib] The key passed to ClassLib.SetValue is not a string")
	assert((type(xValue) ~= "function"), "[ClassLib] Attempt to set a function as a value")
	assert((sKey ~= "id"), "[ClassLib] Attempt to set the ID as a value")

	local tMT = getmetatable(oInstance)
	if not tMT then return end

	oInstance[sKey] = xValue

	ClassLib.Call(ClassLib.GetClass(oInstance), "ValueChange", oInstance, sKey, xValue)
	ClassLib.Call(oInstance, "ValueChange", oInstance, sKey, xValue)

	if not Server or not bBroadcast then
		return true
	end

	tMT.__broadcasted_values[sKey] = xValue

	Events.BroadcastRemote(
		tEventsMap["ClassLib:SetValue"],
		oInstance:GetClassName(),
		oInstance.id,
		sKey,
		xValue
	)

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
	local tMT = getmetatable(oInstance)
	if not tMT then return xFallback end
	if (oInstance[sKey] == nil) then return xFallback end

	return oInstance[sKey]
end

if Server then
	---`🔹 Server`<br>
	---Checks if a key is broadcasted
	---@param oInstance table @The instance to check
	---@param sKey string @The key to check
	---@return boolean @Whether the key is broadcasted
	---
	function ClassLib.IsValueBroadcasted(oInstance, sKey)
		local tMT = getmetatable(oInstance)
		if not tMT then return false end
		return tMT.__broadcasted_values[sKey] ~= nil
	end

	---`🔹 Server`<br>
	---Internal function to sync the creation of an instance, you shouldn't call this directly
	---@param oInstance table @The instance to sync
	---@param pPlayer Player|nil @The player that created the instance, nil to broadcast to all players
	---
	function ClassLib.SyncInstanceConstruct(oInstance, pPlayer)
		if (getmetatable(pPlayer) == Player) then
			Events.CallRemote(
				tEventsMap["ClassLib:Constructor"],
				pPlayer,
				oInstance:GetClassName(),
				oInstance.id,
				getmetatable(oInstance).__broadcasted_values
			)
			return
		end

		Events.BroadcastRemote(
			tEventsMap["ClassLib:Constructor"],
			oInstance:GetClassName(),
			oInstance.id,
			getmetatable(oInstance).__broadcasted_values
		)
	end

	---`🔹 Server`<br>
	---Internal function to sync the destruction of an instance, you shouldn't call this directly
	---@param oInstance table @The instance to sync
	---
	function ClassLib.SyncInstanceDestroy(oInstance)
		Events.BroadcastRemote(
			tEventsMap["ClassLib:Destructor"],
			oInstance:GetClassName(),
			oInstance.id
		)
	end

	local function onPlayerReady(pPlayer)
		for sClass, oClass in pairs(tClassesMap) do
			local tClassMT = getmetatable(oClass)
			if not tClassMT.__broadcast_creation then goto continue end
			if (#tClassMT.__instances == 0) then goto continue end

			for _, oInstance in ipairs(tClassMT.__instances) do
				ClassLib.SyncInstanceConstruct(oInstance, pPlayer)
			end

			::continue::
		end
	end

	Player.Subscribe("Ready", onPlayerReady)
end

if Client then
	-- Net Event: "ClassLib:Constructor"
	Events.SubscribeRemote(tEventsMap["ClassLib:Constructor"], function(sClassName, nID, tSyncValues)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		local oInstance = tClass(tClass)
		oInstance.id = nID

        getmetatable(tClass).__instances[nID] = oInstance

		for sKey, xValue in pairs(tSyncValues) do
			ClassLib.SetValue(oInstance, sKey, xValue)
		end
	end)

	-- Net Event: "ClassLib:Destructor"
	Events.SubscribeRemote(tEventsMap["ClassLib:Destructor"], function(sClassName, nID)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		ClassLib.Destroy(tClass.GetByID(nID))
	end)

	-- Net Event: "ClassLib:SetValue"
	Events.SubscribeRemote(tEventsMap["ClassLib:SetValue"], function(sClassName, nID, sKey, xValue)
		local tClass = ClassLib.GetClassByName(sClassName)
		if not tClass then return end

		local oInstance = tClass.GetByID(nID)
		if not oInstance then return end

		ClassLib.SetValue(oInstance, sKey, xValue)
	end)
end