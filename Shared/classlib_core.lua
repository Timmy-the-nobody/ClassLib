--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local setmetatable = setmetatable
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local error = error
local assert = assert

---`🔸 Client`<br>`🔹 Server`<br>
---Contains all ClassLib global functions and variables
ClassLib.__classlist = ClassLib.__classlist or {}
ClassLib.__classmap = ClassLib.__classmap or {}

-- Event map/lightweight wire protocol
ClassLib.EventMap = {
    ["Constructor"] = "%0",
    ["Destructor"] = "%1",
    ["SetValue"] = "%2",
    ["CLToSV"] = "%3",
    ["SVToCL"] = "%4",
    ["SetValues"] = "%5",
}

-- List of keys to copy from the parent class on inherit
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

-- Class creation/lookup
----------------------------------------------------------------------
---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from the passed class
---@param oInheritFrom table @The class to inherit from
---@param sClassName string @The name of the class
---@param iFlags? ClassLib.FL @The class flags:<br>
---@return table @The new class
---@see ClassLib.FL
function ClassLib.Inherit(oInheritFrom, sClassName, iFlags)
    if (type(sClassName) ~= "string") then error("[ClassLib] Attempt to create a class with a nil name") end
    assert((ClassLib.__classmap[sClassName] == nil), "[ClassLib] Attempt to create a class with a name that already exists")
    assert((type(oInheritFrom) == "table"), "[ClassLib] Attempt to extend from a nil class value")

    local bGlobalClientCollision = ClassLib.HasFlag(iFlags, ClassLib.FL.GlobalPool) and ClassLib.HasFlag(iFlags, ClassLib.FL.ClientLocal)
    assert(not bGlobalClientCollision, ("[ClassLib] Flags GlobalPool and ClientLocal are mutually exclusive (class '%s')"):format(sClassName))

    local bReplicateToAll = ClassLib.HasFlag(iFlags, ClassLib.FL.Replicated)
    local bUseGlobalPool = (not bReplicateToAll) and ClassLib.HasFlag(iFlags, ClassLib.FL.GlobalPool)

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
    tNewMT.__last_id = 0
    tNewMT.__last_client_id = 0
    tNewMT.__use_global_pool = bUseGlobalPool
    tNewMT.__replicate_to_all = bReplicateToAll
    tNewMT.__inherited_classes = {}
    tNewMT.__flags = (iFlags or 0)
    tNewMT.__singleton_instance = nil
    tNewMT.__classlib_class = true

    local oNewClass = setmetatable({}, tNewMT)
    local tClassMT = getmetatable(oNewClass)

    -- Add static functions to the new class
    function oNewClass.GetAll()
        local tAll, tSource = {}, tClassMT.__instances
        for i = 1, #tSource do tAll[i] = tSource[i] end
        return tAll
    end
    function oNewClass.GetAllInherited()
        return ClassLib.GetAllInherited(oNewClass)
    end
    function oNewClass.GetCount()
        return #tClassMT.__instances
    end
    function oNewClass.GetByID(iID)
        return tClassMT.__instances_map[iID]
    end
    function oNewClass.GetParentClass()
        return ClassLib.Super(oNewClass)
    end
    function oNewClass.GetClassName()
        return ClassLib.GetClassName(oNewClass)
    end
    function oNewClass.GetAllParentClasses()
        return ClassLib.SuperAll(oNewClass)
    end
    function oNewClass.IsChildOf(oClass)
        return ClassLib.IsA(oNewClass, oClass, true)
    end
    function oNewClass.Inherit(...)
        return ClassLib.Inherit(oNewClass, ...)
    end
    function oNewClass.GetInheritedClasses()
        return ClassLib.GetInheritedClasses(oNewClass)
    end
    function oNewClass.ClassCall(sEvent, ...)
        return ClassLib.Call(oNewClass, sEvent, ...)
    end
    function oNewClass.ClassSubscribe(...)
        return ClassLib.Subscribe(oNewClass, ...)
    end
    function oNewClass.ClassUnsubscribe(...)
        return ClassLib.Unsubscribe(oNewClass, ...)
    end
    function oNewClass.SubscribeRemote(...)
        return ClassLib.SubscribeRemote(oNewClass, ...)
    end
    function oNewClass.UnsubscribeRemote(...)
        return ClassLib.UnsubscribeRemote(oNewClass, ...)
    end

    ClassLib.__classmap[sClassName] = oNewClass
    ClassLib.__classlist[#ClassLib.__classlist + 1] = oNewClass

    tFromMT.__inherited_classes = tFromMT.__inherited_classes or {}
    tFromMT.__inherited_classes[#tFromMT.__inherited_classes + 1] = oNewClass

    ClassLib.Call(oInheritFrom, "ClassRegister", oNewClass)

    return oNewClass
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns all instances of a class and all of its inherited classes (recursive)
---@param oClass table @The class
---@return table<integer, table> @All instances
function ClassLib.GetAllInherited(oClass)
    assert(ClassLib.IsClassLibClass(oClass), "[ClassLib] Attempt to get all instances of a non-class value")

    local tResult = {}
    local tClassMT = getmetatable(oClass)

    for _, oInst in ipairs(tClassMT.__instances) do
        tResult[#tResult + 1] = oInst
    end
    for _, oChild in ipairs(tClassMT.__inherited_classes or {}) do
        for _, oInst in ipairs(ClassLib.GetAllInherited(oChild)) do
            tResult[#tResult + 1] = oInst
        end
    end
    return tResult
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a class object by its name
---@param sClassName string @The name of the class
---@return table? @The class
function ClassLib.GetClassByName(sClassName)
    return ClassLib.__classmap[sClassName]
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the name of a class or of an instance
---@param oInput table @The class
---@return string? @The name of the class
function ClassLib.GetClassName(oInput)
    local tMT = getmetatable(oInput)
    if not tMT then return end

    return tMT.__classname
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the flags of a class
---@param oClass table @The class
---@return number? @The flags
---@see ClassLib.FL
function ClassLib.GetClassFlags(oClass)
    local tMT = getmetatable(oClass)
    if not tMT then return end

    return tMT.__flags
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if a value is a ClassLib class
---@param xClass any @The value to check
---@return boolean @Whether the value is a ClassLib class
---@see ClassLib.IsClassLibInstance
function ClassLib.IsClassLibClass(xClass)
    if (type(xClass) ~= "table") then return false end

    local tMT = getmetatable(xClass)
    return (tMT and tMT.__classlib_class) and true or false
end

-- Inheritance resolution
----------------------------------------------------------------------
---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which an object inherits
---@param oInput table @The object
---@return table? @The super class
function ClassLib.Super(oInput)
    local tMT = getmetatable(oInput)
    if not tMT then return end

    return tMT.__super
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which an object inherits
---@param oInput table @The object
---@return table<integer, table> @The super classes
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
---Returns a sequential table of all classes that inherit from the passed class
---@param oClass table @The class
---@return table<integer, table> @The inherited classes
function ClassLib.GetInheritedClasses(oClass)
    local tMT = getmetatable(oClass)
    if not tMT then return {} end

    return tMT.__inherited_classes or {}
end