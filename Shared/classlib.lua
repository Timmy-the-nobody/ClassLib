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
	return (not tMT.__invalid)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class of an object
---@param oInstance table @The object
---@return table|nil @The class
---
function ClassLib.GetClass(oInstance)
	if not oInstance then return end
	return getmetatable(oInstance).__index
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
	return tMT.__class_name
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
-- ClassLib
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from the passed class
---@param oInheritFrom table @The class to inherit from
---@return table @The new class
---
function ClassLib.Inherit(oInheritFrom, sClassName)
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
	})

	-- Add instance table to the new class
	local tClassMT = getmetatable(oNewClass)
    tClassMT.__next_id = 1
    tClassMT.__instances = {}

	-- Register class name if available (used for network serialization)
	if sClassName then
		tClassMT.__class_name = sClassName
		tSerializedClasses[sClassName] = oNewClass
	end

	-- Add static functions to the new class
    function oNewClass.GetAll() return tClassMT.__instances end
	function oNewClass.GetCount() return #tClassMT.__instances end
	function oNewClass.GetByID(iID) return __getInstanceByID(tClassMT, iID) end
	function oNewClass.GetParentClass() return ClassLib.Super(oNewClass) end
	function oNewClass.GetAllParentClasses() return ClassLib.SuperAll(oNewClass) end
	function oNewClass.IsChildOf(oClass) return ClassLib.IsA(oNewClass, oClass, true) end
	function oNewClass.Inherit(sName) return ClassLib.Inherit(oNewClass, sName) end
	-- function oNewClass.GetClassName() return ClassLib.GetClassName(oNewClass) end

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
		__class_name = tClassMT.__class_name
	})

	-- Add instance to the class instance table
    oInstance.id = tClassMT.__next_id

	tClassMT.__next_id = (tClassMT.__next_id + 1)
	tClassMT.__instances[#tClassMT.__instances + 1] = oInstance

	-- Call constructor
	if rawget(oClass, "Constructor") then
		rawget(oClass, "Constructor")(oInstance, ...)
	end

	return oInstance
end

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys an instance of a class
---@param oInstance table @The instance to destroy
---
function ClassLib.Destroy(oInstance, ...)
	assert((type(oInstance) == "table"), "[ClassLib] Called delete without object")

	local oClass = ClassLib.GetClass(oInstance)
	assert((type(oClass) == "table"), "[ClassLib] Called ClassLib.Delete without a valid class instance")

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
	tMT.__invalid = true
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