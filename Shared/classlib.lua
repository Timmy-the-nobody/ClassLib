--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

ClassLib = {}

local REPLICATE_TO_ALL = "*"

local tClassesMap = {}
local tClassesList = {}

local tEvMap = {
    ["Constructor"] = "%0",
    ["Destructor"] = "%1",
    ["SetValue"] = "%2",
    ["CLToSV"] = "%3",
    ["SVToCL"] = "%4",
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

local type = type
local setmetatable = setmetatable
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local error = error
local assert = assert
local rawget = rawget

local function serializeValue(v)
    if ClassLib.IsClassLibInstance(v) then
        if Client and ClassLib.HasAuthority(v) then return end
        return {__classlib = true, c = v:GetClassName(), i = v:GetID()}
    elseif (type(v) == "table") then
        local tRes = {}
        for i, j in pairs(v) do tRes[i] = serializeValue(j) end
        return tRes
    else
        return v
    end
end

local function serializeArgs(...)
    local tArgs, tSerialized = {...}, {}
    for i = 1, #tArgs do
        tSerialized[i] = serializeValue(tArgs[i])
    end
    return tSerialized
end

local function parseValue(v)
    if (type(v) == "table") then
        if v.__classlib then
            local tClass = tClassesMap[v.c]
            if not tClass then return end
            return getmetatable(tClass).__instances_map[v.i]
        else
            local tRes = {}
            for i, j in pairs(v) do tRes[i] = parseValue(j) end
            return tRes
        end
    else
        return v
    end
end

local function parseArgs(...)
    local tArgs, tParsed = {...}, {}
    for i = 1, #tArgs do
        tParsed[i] = parseValue(tArgs[i])
    end
    return tParsed
end

-- Utils
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
---Returns a sequential table of all classes that inherit from the passed class
---@param oClass table @The class
---@return table<integer, table> @The inherited classes
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
function ClassLib.IsValid(oInstance)
    if not ClassLib.IsClassLibInstance(oInstance) then return false end

    local tMT = getmetatable(oInstance)
    return (tMT.__is_valid ~= nil)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the passed object is being destroyed
---@param oInstance table @The instance to check
---@return boolean @True if the instance is being destroyed, false otherwise
function ClassLib.IsBeingDestroyed(oInstance)
    local tMT = getmetatable(oInstance)
    return tMT and (tMT.__is_being_destroyed ~= nil) or false
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class of an object
---@param oInstance table @The object
---@return table? @The class
function ClassLib.GetClass(oInstance)
    local tMT = getmetatable(oInstance)
    return tMT and tMT.__index
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the ID of the instance, unique to the class
---@return integer? @Instance ID
function ClassLib.GetID(oInstance)
    if (type(oInstance) ~= "table") or not oInstance.GetValue then return end
    return oInstance:GetValue("id")
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a class object by its name
---@param sClassName string @The name of the class
---@return table? @The class
function ClassLib.GetClassByName(sClassName)
    return tClassesMap[sClassName]
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the name of a class
---@param oClass table @The class
---@return string? @The name of the class
function ClassLib.GetClassName(oClass)
    local tMT = getmetatable(oClass)
    if not tMT then return end

    return tMT.__classname
end

-- Local Events
---------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event
---@param oInput table @The object to call the event on
---@param sEvent string @The name of the event to call
---@param ... any @The arguments to pass to the event
function ClassLib.Call(oInput, sEvent, ...)
    local tMT = getmetatable(oInput)
    local tEvents = tMT.__events

    if tEvents and tEvents[sEvent] then
        for _, fnCallback in ipairs(tEvents[sEvent]) do
            if (fnCallback(...) == false) then
                ClassLib.Unsubscribe(oInput, sEvent, fnCallback)
            end
        end
    end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event
---@param oInput table @The object that will subscribe to the event
---@param sEvent string @The name of the event to subscribe to
---@param fnCallback function @The callback to call when the event is triggered, return false to unsubscribe from the event
---@return function? @The callback
function ClassLib.Subscribe(oInput, sEvent, fnCallback)
    local tEvents = getmetatable(oInput).__events
    if not tEvents then return end

    tEvents[sEvent] = tEvents[sEvent] or {}
    tEvents[sEvent][#tEvents[sEvent] + 1] = fnCallback

    return fnCallback
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events in this Class, optionally passing the function to unsubscribe only that callback
---@param oInput table @The object to unsubscribe from
---@param sEvent string @The name of the event to unsubscribe from
---@param fnCallback? function @The callback to unsubscribe
function ClassLib.Unsubscribe(oInput, sEvent, fnCallback)
    local tEvents = getmetatable(oInput).__events
    if not tEvents[sEvent] then return end

    if (type(fnCallback) ~= "function") then
        tEvents[sEvent] = nil
        return
    end

    local tNew = {}
    for i, v in ipairs(tEvents[sEvent]) do
        if (v ~= fnCallback) then
            tNew[#tNew + 1] = v
        end
    end

    tEvents[sEvent] = tNew
end

-- Remote Events
----------------------------------------------------------------------

if Client then
    ---`🔸 Client`<br>
    ---Calls a remote event from the client to the server
    ---@param oInstance table @The object to call the event from
    ---@param sEvent string @The name of the event to call
    ---@param ... any @The arguments to pass to the event
    function ClassLib.CallRemote_Client(oInstance, sEvent, ...)
        if (type(sEvent) ~= "string") then return end

        local sClass = ClassLib.GetClassName(oInstance)
        if not sClass then return end

        local tArgs = serializeArgs(...)
        Events.CallRemote(tEvMap.CLToSV, sClass, oInstance:GetID(), sEvent, table.unpack(tArgs))
    end

    Events.SubscribeRemote(tEvMap.SVToCL, function(sClassName, iID, sEvent, ...)
        local tClass = tClassesMap[sClassName]
        if not tClass then return end

        local tClassMT = getmetatable(tClass)
        local tRemoteEvents = tClassMT.__remote_events
        if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

        local oInstance = tClassMT.__instances_map[iID]
        local tArgs = parseArgs(...)
        if oInstance then
            for _, fnCallback in ipairs(tRemoteEvents[sEvent]) do
                fnCallback(oInstance, table.unpack(tArgs))
            end
            return
        end

        -- Wait for the instance to spawn if it hasn't already
        tClass.ClassSubscribe("Spawn", function(self)
            if (self:GetID() == iID) then
                for _, fnCallback in ipairs(tRemoteEvents[sEvent]) do
                    fnCallback(self, table.unpack(tArgs))
                end
                return false
            end
        end)
    end)
elseif Server then
    ---`🔹 Server`<br>
    ---Calls a remote event from the server to the client
    ---@param oInstance table @The object to call the event on
    ---@param sEvent string @The name of the event to call
    ---@param xPlayer Player|table<number, Player> @The player (or table of players) to send the event to
    ---@param ... any @The arguments to pass to the event
    function ClassLib.CallRemote_Server(oInstance, sEvent, xPlayer, ...)
        if (type(sEvent) ~= "string") then return end

        local sClass = ClassLib.GetClassName(oInstance)
        if not sClass then return end

        if (getmetatable(xPlayer) == Player) then
            local tArgs = serializeArgs(...)
            Events.CallRemote(tEvMap.SVToCL, xPlayer, sClass, oInstance:GetID(), sEvent, table.unpack(tArgs))
            return
        end

        if (type(xPlayer) ~= "table") then return end

        local iID = oInstance:GetID()
        local tArgs = serializeArgs(...)
        for _, pPly in ipairs(xPlayer) do
            if (getmetatable(pPly) == Player) then
                Events.CallRemote(tEvMap.SVToCL, pPly, sClass, iID, sEvent, table.unpack(tArgs))
            end
        end
    end

    ---`🔹 Server`<br>
    ---Broadcasts a remote event from the server to all connected clients
    ---@param oInstance table @The object to broadcast the event on
    ---@param sEvent string @The name of the event to broadcast
    ---@param ... any @The arguments to pass to the event
    function ClassLib.BroadcastRemote(oInstance, sEvent, ...)
        if (type(sEvent) ~= "string") then return end

        local sClass = ClassLib.GetClassName(oInstance)
        if not sClass then return end

        local tArgs = serializeArgs(...)
        Events.BroadcastRemote(tEvMap.SVToCL, sClass, oInstance:GetID(), sEvent, table.unpack(tArgs))
    end

    Events.SubscribeRemote(tEvMap.CLToSV, function(pPly, sClassName, iID, sEvent, ...)
        local tClass = tClassesMap[sClassName]
        if not tClass then return end

        local oInstance = getmetatable(tClass).__instances_map[iID]
        if not oInstance then return end

        local tRemoteEvents = getmetatable(tClass).__remote_events
        if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

        local tArgs = parseArgs(...)
        for _, fnCallback in ipairs(tRemoteEvents[sEvent]) do
            fnCallback(oInstance, pPly, table.unpack(tArgs))
        end
    end)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to a remote event
---@param oInstance table @The object that will subscribe to the event
---@param sEvent string @The name of the event to subscribe to
---@param fnCallback function @The callback to call when the event is triggered
---@return function? @The callback
function ClassLib.SubscribeRemote(oInstance, sEvent, fnCallback)
    if (type(sEvent) ~= "string") then return end

    local tRemoteEvents = getmetatable(oInstance).__remote_events
    if not tRemoteEvents then return end

    tRemoteEvents[sEvent] = tRemoteEvents[sEvent] or {}
    tRemoteEvents[sEvent][#tRemoteEvents[sEvent] + 1] = fnCallback

    return fnCallback
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from a remote event
---@param oInstance table @The object to unsubscribe from
---@param sEvent string @The name of the event to unsubscribe from+
---@param fnCallback? function @The callback to unsubscribe
function ClassLib.UnsubscribeRemote(oInstance, sEvent, fnCallback)
    if (type(sEvent) ~= "string") then return end

    local tRemoteEvents = getmetatable(oInstance).__remote_events
    if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

    if (type(fnCallback) ~= "function") then
        tRemoteEvents[sEvent] = nil
        return
    end

    local tNewCallbacks = {}
    for _, v in ipairs(tRemoteEvents[sEvent]) do
        if (v ~= fnCallback) then
            tNewCallbacks[#tNewCallbacks + 1] = v
        end
    end

    tRemoteEvents[sEvent] = tNewCallbacks
end

-- ClassLib
----------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from the passed class
---@param oInheritFrom table @The class to inherit from
---@param sClassName string @The name of the class
---@param bSync boolean @Whether to broadcast the creation of a new instance of the class
---@return table @The new class
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
    tNewMT.__classlib_class = true

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
    tClassesList[#tClassesList + 1] = oNewClass

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
    tNewMT.__replicated_players = {}
    tNewMT.__destroy_for_unsynced = true
    tNewMT.__classlib_instance = true

    local oInstance = setmetatable({}, tNewMT)
    ClassLib.SetValue(oInstance, "id", iForcedID or tClassMT.__next_id)

    tClassMT.__next_id = (tClassMT.__next_id + 1)
    tClassMT.__instances[#tClassMT.__instances + 1] = oInstance

    if rawget(oClass, "Constructor") then
        rawget(oClass, "Constructor")(oInstance, ...)
    end

    ClassLib.Call(oClass, "Spawn", oInstance)

    if tClassMT.__broadcast_creation and Server then
        ClassLib.AddReplicatedPlayer(oInstance, REPLICATE_TO_ALL)
    end

    return oInstance
end

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys an instance of a class
---@param oInstance table @The instance to destroy
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

    if Server then
        if tClassMT.__broadcast_destruction then
            ClassLib.SyncInstanceDestroy(oInstance)
        else
            for pPly in pairs(tMT.__replicated_players) do
                ClassLib.SyncInstanceDestroy(oInstance, pPly)
            end
        end
    end

    -- Prevent access to the instance
    tMT.__is_valid = nil
    tMT.__is_being_destroyed = nil

    function tMT:__newindex() error("[ClassLib] Attempt to set a value on a destroyed object") end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Clones an instance, and return a new instance with the same values (except it's ID)
---@param oInstance table @The instance to clone
---@param tIgnoredKeys? table @The properties to ignore (sequential table)
---@param ... any @The arguments to pass to the constructor
---@return table @The new instance
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
---@return boolean? @Return true if the value was set, nil otherwise
function ClassLib.SetValue(oInstance, sKey, xValue, bBroadcast)
    assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to set a value on an invalid object")
    assert((type(sKey) == "string"), "[ClassLib] The key passed to ClassLib.SetValue is not a string")
    assert((type(xValue) ~= "function"), "[ClassLib] Attempt to set a function as a value")

    local tMT = getmetatable(oInstance)
    if not tMT then return end

    xValue = serializeValue(xValue)
    local xOldValue = tMT.__values[sKey]

    -- Handle ID change
    if (sKey == "id") then
        assert((type(xValue) == "number"), "[ClassLib] The ID passed to ClassLib.SetValue is not a number")
        assert((math.floor(xValue) == xValue), "[ClassLib] The ID passed to ClassLib.SetValue is not an integer")

        local tClass = oInstance:GetClass()
        if tClass then
            local tClassMT = getmetatable(tClass)
            if tClassMT and tClassMT.__instances_map then
                local iOldID = ClassLib.GetValue(oInstance, "id")
                if iOldID then
                    tClassMT.__instances_map[iOldID] = nil
                end
                tClassMT.__instances_map[xValue] = oInstance
            end
        end
    end

    oInstance[sKey] = xValue
    tMT.__values[sKey] = xValue

    ClassLib.Call(ClassLib.GetClass(oInstance), "ValueChange", oInstance, sKey, xValue, xOldValue)
    ClassLib.Call(oInstance, "ValueChange", oInstance, sKey, xValue, xOldValue)

    if bBroadcast and Server then
        tMT.__broadcasted_values[sKey] = xValue

        if tMT.__replicate_to_all then
            Events.BroadcastRemote(tEvMap.SetValue, oInstance:GetClassName(), oInstance:GetID(), sKey, xValue)
        else
            for pPly, tInfo in pairs(tMT.__replicated_players) do
                if pPly:IsValid() then
                    Events.CallRemote(tEvMap.SetValue, pPly, oInstance:GetClassName(), oInstance:GetID(), sKey, xValue)
                end
            end
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
function ClassLib.GetValue(oInstance, sKey, xFallback)
    assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to get a value from an invalid object")

    local tMT = getmetatable(oInstance)
    if not tMT then return xFallback end

    if (tMT.__values[sKey] ~= nil) then return tMT.__values[sKey] end
    if (oInstance[sKey] ~= nil) then return oInstance[sKey] end
    return xFallback
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets all values from an instance
---@param oInstance table @The instance to get the values from
---@param bBroadcastedOnly? boolean @Whether to only get broadcasted values
---@return table @Table with the key as key and the value as value
function ClassLib.GetAllValuesKeys(oInstance, bBroadcastedOnly)
    assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to get all values from an invalid object")

    local tMT = getmetatable(oInstance)
    if not tMT then return {} end

    if bBroadcastedOnly then return tMT.__broadcasted_values end
    return tMT.__values
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

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if a value is a ClassLib instance
---@param xInstance any @The value to check
---@return boolean @Whether the value is a ClassLib instance
---@see ClassLib.IsClassLibClass
function ClassLib.IsClassLibInstance(xInstance)
    local tMT = getmetatable(xInstance)
    return (tMT and tMT.__classlib_instance) and true or false
end

---`🔸 Client`<br>`🔹 Server`<br>
---Binds an instance to another instance (the bound instance will be destroyed when the "bound to" instance is destroyed)
---@param oInstance table @The instance to bind
---@param oTarget table @The instance to bind to
function ClassLib.Bind(oInstance, oTarget)
    if not oInstance or not oInstance:IsValid() then return false end
    if not oTarget or not oTarget:IsValid() then return false end
    if not oInstance.Subscribe or not oTarget.Subscribe then return false end

    ClassLib.Unbind(oInstance)

    local tMT = getmetatable(oInstance)
    tMT.__bind = {}
    tMT.__bind.target = oTarget
    tMT.__bind.target_destroy_ev = oTarget:Subscribe("Destroy", function()
        if not oInstance:IsValid() then return end

        oInstance:Destroy()
        ClassLib.Unbind(oInstance)
    end)
    tMT.__bind.self_destroy_ev = oInstance:Subscribe("Destroy", function()
        ClassLib.Unbind(oInstance)
    end)

    return true
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unbinds an instance from another instance
---@param oInstance table @The instance to unbind
---@return boolean @Whether the instance was successfully unbound
function ClassLib.Unbind(oInstance)
    if not oInstance or not oInstance:IsValid() then return false end

    local tMT = getmetatable(oInstance)
    if not tMT or not tMT.__bind then return false end

    if tMT.__bind.target and tMT.__bind.target:IsValid() then
        tMT.__bind.target:Unsubscribe(tMT.__bind.target_destroy_ev)
    end

    oInstance:Unsubscribe(tMT.__bind.self_destroy_ev)
    tMT.__bind = nil
    return true
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets the bound instance of an instance
---@param oInstance table @The instance to get the bound instance of
---@return table @The bound instance
function ClassLib.GetBoundTo(oInstance)
    local tMT = getmetatable(oInstance)
    return tMT.__bind and tMT.__bind.target
end

-- Sync
----------------------------------------------------------------------

if Server then
    ---`🔹 Server`<br>
    ---Checks if a key is broadcasted
    ---@param oInstance table @The instance to check
    ---@param sKey string @The key to check
    ---@return boolean @Whether the key is broadcasted
    function ClassLib.IsValueBroadcasted(oInstance, sKey)
        assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to check if a value is broadcasted from an invalid object")

        local tMT = getmetatable(oInstance)
        if not tMT then return false end
        return tMT.__broadcasted_values[sKey] ~= nil
    end

    ---`🔹 Server`<br>
    ---Internal function to sync the creation of an instance, you shouldn't call this directly
    ---@param oInstance table @The instance to sync
    ---@param pPly Player? @The player to send the sync to, nil to broadcast to all players
    function ClassLib.SyncInstanceConstruct(oInstance, pPly)
        assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to sync the construction of an invalid object")

        local sClass = oInstance:GetClassName()
        local iID = oInstance:GetID()
        local tValues = getmetatable(oInstance).__broadcasted_values

        if (getmetatable(pPly) == Player) then
            Events.CallRemote(tEvMap.Constructor, pPly, sClass, iID, tValues)
        else
            Events.BroadcastRemote(tEvMap.Constructor, sClass, iID, tValues)
        end
    end

    ---`🔹 Server`<br>
    ---Internal function to sync the destruction of an instance (to all players), you shouldn't call this directly
    ---@param oInstance table @The instance to sync
    ---@param pPly Player? @The player to send the sync to, nil to broadcast to all players
    function ClassLib.SyncInstanceDestroy(oInstance, pPly)
        assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to sync the destruction of an invalid object")

        local sClass = oInstance:GetClassName()
        local iID = oInstance:GetID()

        if (getmetatable(pPly) == Player) then
            Events.CallRemote(tEvMap.Destructor, pPly, sClass, iID)
        else
            Events.BroadcastRemote(tEvMap.Destructor, sClass, iID)
        end
    end

    ---`🔹 Server`<br>
    ---Gets the players to replicate an instance to
    ---@param oInstance table @The instance to get
    ---@return table<Player> @The players to replicate the instance to
    function ClassLib.GetReplicatedPlayers(oInstance)
        local tMT = getmetatable(oInstance)
        if not tMT then return {} end

        if tMT.__replicate_to_all then
            return Player.GetAll()
        end

        local tList = {}
        for pPly, _ in pairs(tMT.__replicated_players or {}) do
            tList[#tList + 1] = pPly
        end

        return tList
    end

    ---`🔹 Server`<br>
    ---Sets the players to replicate an instance to
    ---@param oInstance table @The instance to set
    ---@param xPlayers table|"*"|false @The players to replicate the instance to, can be:<br>
    ---- `table` ➜ replicate to **selection**: e.g. `{p1, p2, ...}`, must be an array of players<br>
    ---- `"*"` ➜ replicate to **everyone**<br>
    ---- `false` ➜ replicate to **nobody**: Faster performance than passing an empty table, but same result
    ---@return boolean @Whether the players were set successfully
    function ClassLib.SetReplicatedPlayers(oInstance, xPlayers)
        if not ClassLib.IsClassLibInstance(oInstance) then return false end

        if (xPlayers == REPLICATE_TO_ALL) then
            ClassLib.AddReplicatedPlayer(oInstance, REPLICATE_TO_ALL)
            return true
        end

        local tMT = getmetatable(oInstance)
        tMT.__replicate_to_all = false

        if (type(xPlayers) ~= "table") then
            if (xPlayers == false) then
                if tMT.__replicate_to_all then
                    ClassLib.RemoveReplicatedPlayer(oInstance, REPLICATE_TO_ALL)
                else
                    for pPly in pairs(tMT.__replicated_players) do
                        ClassLib.RemoveReplicatedPlayer(oInstance, pPly)
                    end
                end
                return true
            end
            return false
        end

        local bHasChanges = false
        local tOldMap = tMT.__replicated_players
        local tNewMap = {}

        for _, pPly in ipairs(xPlayers) do
            if (getmetatable(pPly) == Player) and pPly:IsValid() then
                tNewMap[pPly] = true
                if not tOldMap[pPly] then
                    ClassLib.AddReplicatedPlayer(oInstance, pPly)
                    bHasChanges = true
                end
            end
        end

        for pPly in pairs(tOldMap) do
            if not tNewMap[pPly] then
                ClassLib.RemoveReplicatedPlayer(oInstance, pPly)
                bHasChanges = true
            end
        end

        return bHasChanges
    end

    ---`🔹 Server`<br>
    ---Adds a player to replicate an instance to
    ---@param oInstance table @The instance to add the player to
    ---@param xPly Player|"*" @The player to add, or "*" for all
    ---@return boolean @Whether the player was added (false if the player wasn't added, or if "*" was passed on an already replicated to all instance)
    function ClassLib.AddReplicatedPlayer(oInstance, xPly)
        if not ClassLib.IsClassLibInstance(oInstance) then return false end

        local tMT = getmetatable(oInstance)

        -- Replicate to all
        if (xPly == REPLICATE_TO_ALL) then
            if tMT.__replicate_to_all then return false end

            tMT.__replicate_to_all = true
            tMT.__replicated_players = {}

            ClassLib.SyncInstanceConstruct(oInstance)
            return true
        end

        -- Replicate to single player
        if ClassLib.IsReplicatedTo(oInstance, xPly) then return false end
        if (getmetatable(xPly) ~= Player) then return false end

        tMT.__replicate_to_all = false
        tMT.__replicated_players[xPly] = true

        ClassLib.SyncInstanceConstruct(oInstance, xPly)
        ClassLib.Call(ClassLib.GetClass(oInstance), "ReplicatedPlayerChange", oInstance, xPly, true)
        ClassLib.Call(oInstance, "ReplicatedPlayerChange", oInstance, xPly, true)
        return true
    end

    ---`🔹 Server`<br>
    ---Removes a player from replicating an instance to
    ---@param oInstance table @The instance to remove the player from
    ---@param pPly Player|"*" @The player to remove, or "*" for all
    ---@return boolean @Whether the player was removed (false if the player wasn't removed or "*" was passed on an instance already replicated to everyone)
    function ClassLib.RemoveReplicatedPlayer(oInstance, pPly)
        if not ClassLib.IsClassLibInstance(oInstance) then return false end

        local tMT = getmetatable(oInstance)

        -- Desync all
        if (pPly == REPLICATE_TO_ALL) then
            if tMT.__replicate_to_all then
                tMT.__replicate_to_all = false
                tMT.__replicated_players = {}

                ClassLib.SyncInstanceDestroy(oInstance)
                return true
            else
                local bHadPlayers = false
                for p in pairs(tMT.__replicated_players) do
                    ClassLib.RemoveReplicatedPlayer(oInstance, p)
                    bHadPlayers = true
                end
                return bHadPlayers
            end
        end

        -- Desync single player
        if not ClassLib.IsReplicatedTo(oInstance, pPly) then return false end

        tMT.__replicated_players[pPly] = nil

        ClassLib.Call(ClassLib.GetClass(oInstance), "ReplicatedPlayerChange", oInstance, pPly, false)
        ClassLib.Call(oInstance, "ReplicatedPlayerChange", oInstance, pPly, false)

        if pPly:IsValid() then
            ClassLib.SyncInstanceDestroy(oInstance, pPly)
        end
        return true
    end

    ---`🔹 Server`<br>
    ---Returns true if the instance is replicated to the player, or to all players via "*"
    ---@param oInstance table @The instance to check
    ---@param pPly Player @The player to check
    ---@return boolean @Whether the player is replicating the instance
    function ClassLib.IsReplicatedTo(oInstance, pPly)
        local tMT = getmetatable(oInstance)
        if not tMT then return false end
        return tMT.__replicate_to_all or tMT.__replicated_players[pPly] or false
    end

    ---Helper function to iterate over all replicated instances, used to sync/destroy instances on player connect/disconnect
    local function forAllReplicatedInstances(pPly, fnCallback)
        for _, oClass in ipairs(tClassesList) do
            local tClassMT = getmetatable(oClass)
            if not tClassMT then goto continue end

            local tInstances = tClassMT.__instances
            if not tInstances or (#tInstances == 0) then goto continue end

            for i = 1, #tInstances do
                if ClassLib.IsReplicatedTo(tInstances[i], pPly) then
                    fnCallback(tInstances[i])
                end
            end
            ::continue::
        end
    end

    Player.Subscribe("Ready", function(pPly)
        forAllReplicatedInstances(pPly, function(oInstance)
            ClassLib.SyncInstanceConstruct(oInstance, pPly)
        end)
    end)

    Player.Subscribe("Destroy", function(pPly)
        forAllReplicatedInstances(pPly, function(oInstance)
            ClassLib.RemoveReplicatedPlayer(oInstance, pPly)
        end)
    end)
end

if Client then
    ---`🔸 Client`<br>
    ---Checks if the instance was spawned on the client side
    ---@param oInstance table @The instance to check
    ---@return boolean @false if it was spawned by the server, true if it was spawned by the client
    function ClassLib.HasAuthority(oInstance)
        return not getmetatable(oInstance).__server_authority
    end

    Events.SubscribeRemote(tEvMap.Constructor, function(sClassName, iID, tBroadcastedValues)
        local tClass = ClassLib.GetClassByName(sClassName)
        if not tClass then return end

        local oInstance = ClassLib.NewInstance(tClass, iID)
        getmetatable(oInstance).__server_authority = true

        for sKey, xValue in pairs(tBroadcastedValues) do
            ClassLib.SetValue(oInstance, sKey, xValue, true)
        end
    end)

    Events.SubscribeRemote(tEvMap.Destructor, function(sClassName, iID)
        local tClass = ClassLib.GetClassByName(sClassName)
        if not tClass then return end

        ClassLib.Destroy(tClass.GetByID(iID))
    end)

    Events.SubscribeRemote(tEvMap.SetValue, function(sClassName, iID, sKey, xValue)
        local tClass = ClassLib.GetClassByName(sClassName)
        if not tClass then return end

        local oInstance = tClass.GetByID(iID)
        if not oInstance then return end

        ClassLib.SetValue(oInstance, sKey, parseValue(xValue), true)
    end)
end