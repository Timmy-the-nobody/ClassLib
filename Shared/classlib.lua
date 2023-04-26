--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

ClassLib = {}
local tSerializedClasses = {}

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
	if (type(xVal) ~= "table") then
		return false
	end

	if (ClassLib.GetClass(xVal) == oClass) then
		return true
	end

	if not bRecursive then
		return false
	end

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
	if (type(oInstance) ~= "table") then
		return false
	end

	local oClass = ClassLib.GetClass(oInstance)
	if (type(oClass) ~= "table") then
		return false
	end

	local tMT = getmetatable(oInstance)
	return (tMT.__is_valid ~= nil)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class of an object
---@param oInstance table @The object
---@return table|nil @The class
---
function ClassLib.GetClass(oInstance)
	if (type(oInstance) ~= "table") then return end
	return getmetatable(oInstance).__index
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
	return tSerializedClasses[sClassName]
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
-- Events related
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event
---@param oInput table @The object to call the event on
---@param sEvent string @The name of the event to call
---@vararg any @The arguments to pass to the event
---
function ClassLib.CallEvent(oInput, sEvent, ...)
	local tMT = getmetatable(oInput)
	local tEvents = tMT.__events

	if not tEvents or not tEvents[sEvent] then return end

	for _, callback in ipairs(tEvents[sEvent]) do
		callback(...)
	end

	-- If the object is a class, call the event on all instances of it's instances
	if tMT.__instances then
		for _, oInstance in ipairs(tMT.__instances) do
			ClassLib.CallEvent(oInstance, sEvent, ...)
		end
	end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event
---@param oInput table @The object that will subscribe to the event
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
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

	if type(callback) ~= "function" then
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
-- ClassLib
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from the passed class
---@param oInheritFrom table @The class to inherit from
---@return table @The new class
---
function ClassLib.Inherit(oInheritFrom, sClassName)
	if (type(sClassName) ~= "string") then error("[ClassLib] Attempt to create a class with a nil name") end
	if tSerializedClasses[sClassName] then error("[ClassLib] Attempt to create a class with a name that already exists") end

	assert((type(oInheritFrom) == "table"), "[ClassLib] Attempt to extend from a nil class value")

	local tFromMT = getmetatable(oInheritFrom)
	local oNewClass = setmetatable({}, {
		__index = oInheritFrom,
		__super = oInheritFrom,
		__newindex = tFromMT.__newindex,
		__call = tFromMT.__call,
		__len = tFromMT.__len,
		__unm = tFromMT.__unm,
		__add = tFromMT.__add,
		__sub = tFromMT.__sub,
		__mul = tFromMT.__mul,
		__div = tFromMT.__div,
		__pow = tFromMT.__pow,
		__concat = tFromMT.__concat,
		__tostring = tFromMT.__tostring,

		__classname = sClassName,
		__events = {},
		__instances = {},
		__next_id = 1,
	})

	local tClassMT = getmetatable(oNewClass)

	-- Add static functions to the new class
    function oNewClass.GetAll() return tClassMT.__instances end
	function oNewClass.GetCount() return #tClassMT.__instances end
	function oNewClass.GetByID(iID) return __getInstanceByID(tClassMT, iID) end
	function oNewClass.GetParentClass() return ClassLib.Super(oNewClass) end
	function oNewClass.GetAllParentClasses() return ClassLib.SuperAll(oNewClass) end
	function oNewClass.IsChildOf(oClass) return ClassLib.IsA(oNewClass, oClass, true) end
	function oNewClass.Inherit(sName) return ClassLib.Inherit(oNewClass, sName) end
	-- function oNewClass.GetClassName() return ClassLib.GetClassName(oNewClass) end

	function oNewClass.CallEvent(sName, ...) return ClassLib.CallEvent(oNewClass, sName, ...) end
	function oNewClass.Subscribe(sName, callback) return ClassLib.Subscribe(oNewClass, sName, callback) end
	function oNewClass.Unsubscribe(sName, callback) return ClassLib.Unsubscribe(oNewClass, sName, callback) end

	tSerializedClasses[sClassName] = oNewClass

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
	local oInstance = setmetatable({}, {
		__index = oClass,
		__super = ClassLib.Super(oClass),
		__newindex = oClass.__newindex,
		__call = oClass.__call,
		__len = oClass.__len,
		__unm = oClass.__unm,
		__add = oClass.__add,
		__sub = oClass.__sub,
		__mul = oClass.__mul,
		__div = oClass.__div,
		__pow = oClass.__pow,
		__concat = oClass.__concat,
		__tostring = oClass.__tostring,

		__classname = tClassMT.__classname,
		__is_valid = true,
		-- __nw_values = {}
		__events = {}
	})

	-- Add instance to the class instance table
    oInstance.id = tClassMT.__next_id

	tClassMT.__next_id = (tClassMT.__next_id + 1)
	tClassMT.__instances[#tClassMT.__instances + 1] = oInstance

	-- Add events methods to the instance
	function oInstance:CallEvent(sName, ...) return ClassLib.CallEvent(self, sName, ...) end
	function oInstance:Subscribe(sName, callback) return ClassLib.Subscribe(self, sName, callback) end
	function oInstance:Unsubscribe(sName, callback) return ClassLib.Unsubscribe(self, sName, callback) end

	-- Call constructor
	if rawget(oClass, "Constructor") then
		rawget(oClass, "Constructor")(oInstance, ...)
	end

	ClassLib.CallEvent(oClass, "Spawn", oInstance)

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

	ClassLib.CallEvent(oClass, "Destroy", oInstance)

	-- Call class destructor
	if rawget(oClass, "Destructor") then
		local bShouldDestroy = rawget(oClass, "Destructor")(oInstance, ...)
		if (bShouldDestroy == false) then return end
	end

	-- Clears the instance from it's class instance table
	local tClassMT = getmetatable(oClass)
	local tNewList = {}
	for _, v in ipairs(tClassMT.__instances) do
        if (v ~= oInstance) then
            tNewList[#tNewList + 1] = v
        end
    end
	tClassMT.__instances = tNewList

	-- Prevent access to the instance
	local tMT = getmetatable(oInstance)
	tMT.__is_valid = nil

	-- function tMT:__call() error("[ClassLib] Attempt to access a destroyed object") end
	-- function tMT:__index() error("[ClassLib] Attempt to access a destroyed object") end
	function tMT:__newindex() error("[ClassLib] Attempt to set a value on a destroyed object") end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Clones an instance, and return a new instance with the same values (except it's ID)
---@param oInstance table @The instance to clone
---@return table @The new instance
---
function ClassLib.Clone(oInstance)
	assert((type(oInstance) == "table"), "[ClassLib] The object passed to ClassLib.Clone is not a table")

	local oClass = ClassLib.GetClass(oInstance)
	assert((type(oClass) == "table"), "[ClassLib] The object passed to ClassLib.Clone has no valid class")

	local oClone = ClassLib.NewInstance(oClass)

	for sKey, xVal in pairs(oInstance) do
		if (sKey ~= "id") then
			oClone[sKey] = xVal
		end
	end

	return oClone
end