--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local assert = assert
local error = error
local pairs = pairs
local ipairs = ipairs
local getmetatable = getmetatable
local setmetatable = setmetatable

-- List of keys to copy from the parent class on new instance
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

---Internally used to allocate an ID for an instance
local function allocateID(oClass, __iSyncID)
    if Client and __iSyncID then
        return __iSyncID
    end

    local tMT = getmetatable(oClass)
    if Server or tMT.__use_global_pool then
        tMT.__last_id = (tMT.__last_id + 1)
        return tMT.__last_id
    end

    tMT.__last_client_id = (tMT.__last_client_id - 1)
    return tMT.__last_client_id
end

-- Instance lifecycle
----------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new instance of the passed class
---@param oClass table @The class to create an instance of
---@param __iSyncID? number @The forced ID of the instance, used for syncing the instance on the client from the server, you should NEVER use this
---@param ... any @The arguments to pass to the constructor
---@return table @The new instance
function ClassLib.NewInstance(oClass, __iSyncID, ...)
    assert((type(oClass) == "table"), "[ClassLib] Attempt to create a new instance from a nil class value")

    local tClassMT = getmetatable(oClass)
    assert(not ClassLib.HasFlag(tClassMT.__flags, ClassLib.FL.Abstract), ("[ClassLib] Attempt to instantiate abstract class '%s'"):format(tClassMT.__classname))

    local bIsSingleton = ClassLib.HasFlag(tClassMT.__flags, ClassLib.FL.Singleton)

    if bIsSingleton then
        local oSingleton = tClassMT.__singleton_instance
        if oSingleton and ClassLib.IsValid(oSingleton) then
            return tClassMT.__singleton_instance
        end
    end

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
    tNewMT.__sync_values = {}
    tNewMT.__replicated_players = {}
    tNewMT.__destroy_for_unsynced = true
    tNewMT.__classlib_instance = true

    local oInstance = setmetatable({}, tNewMT)
    tClassMT.__instances[#tClassMT.__instances + 1] = oInstance

    local iAllocatedID = allocateID(oClass, __iSyncID)
    ClassLib.SetValue(oInstance, "id", iAllocatedID)

    local tSyncInitValues
    if Client and __iSyncID then
        tSyncInitValues = ClassLib.__cl_sync_init_values
        ClassLib.__cl_sync_init_values = nil
    end

    if rawget(oClass, "Constructor") then
        rawget(oClass, "Constructor")(oInstance, ...)
    end

    if tSyncInitValues then
        for sKey, xValue in pairs(tSyncInitValues) do
            ClassLib.SetValue(oInstance, sKey, xValue, true)
        end
    end

    ClassLib.Call(oClass, "Spawn", oInstance)

    if tClassMT.__replicate_to_all and Server then
        ClassLib.AddReplicatedPlayer(oInstance, "*")
    end

    if bIsSingleton then
        tClassMT.__singleton_instance = oInstance
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

    local iID = oInstance:GetID()
    local tMT = getmetatable(oInstance)

    -- Call class destructor
    if rawget(oClass, "Destructor") then
        -- If the destructor returns false, don't destroy the instance
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
    tClassMT.__instances_map[iID] = nil

    -- Clear singleton
    if ClassLib.HasFlag(tClassMT.__flags, ClassLib.FL.Singleton) then
        if tClassMT.__singleton_instance == oInstance then
            tClassMT.__singleton_instance = nil
        end
    end

    tMT.__is_being_destroyed = true

    -- Destroy events
    ClassLib.Call(oClass, "Destroy", oInstance)
    ClassLib.Call(oInstance, "Destroy", oInstance)

    -- Network destroy (external observers)
    if Server then
        if tMT.__replicate_to_all then
            ClassLib.SyncInstanceDestroy(oInstance)
        else
            for pPly in pairs(tMT.__replicated_players) do
                ClassLib.SyncInstanceDestroy(oInstance, pPly)
            end
        end
    end

    tMT.__is_valid = nil

    -- Override newindex to prevent further changes
    function tMT:__newindex()
        error("[ClassLib] Attempt to set a value on a destroyed object")
    end
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
    assert((type(oClass) == "table"), "[ClassLib] The object passed has no valid class")

    local oClone = ClassLib.NewInstance(oClass, nil, ...)

    local tIgnoredKeysMap
    if (type(tIgnoredKeys) == "table") then
        tIgnoredKeysMap = {}
        for _, sKey in ipairs(tIgnoredKeys) do
            tIgnoredKeysMap[sKey] = true
        end
    end

    -- Copy instance properties
    for sKey, xVal in pairs(oInstance) do
        if (sKey == "id") then goto continue end
        if tIgnoredKeysMap and tIgnoredKeysMap[sKey] then goto continue end
        oClone[sKey] = xVal
        ::continue::
    end

    -- Copy classlib values
    local tSyncValues = ClassLib.GetAllValuesKeys(oInstance, true)
    for sKey, xVal in pairs(ClassLib.GetAllValuesKeys(oInstance, false)) do
        if (sKey == "id") then goto continue end
        if tIgnoredKeysMap and tIgnoredKeysMap[sKey] then goto continue end
        ClassLib.SetValue(oClone, sKey, xVal, (tSyncValues[sKey] and Server))
        ::continue::
    end

    return oClone
end

-- Instance values
----------------------------------------------------------------------

---Internally used by `SetValue` to handle instances ID changes
local function handleIDChange(oInstance, tClass, iNewID)
    assert((type(iNewID) == "number"), "[ClassLib] The ID passed to ClassLib.SetValue is not a number")
    assert((math.floor(iNewID) == iNewID), "[ClassLib] The ID passed to ClassLib.SetValue is not an integer")

    local tClassMT = getmetatable(tClass)
    if tClassMT and tClassMT.__instances_map then
        local iOldID = ClassLib.GetValue(oInstance, "id")
        if iOldID then
            tClassMT.__instances_map[iOldID] = nil
        end
        tClassMT.__instances_map[iNewID] = oInstance
    end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets a value on an instance
---@param oInstance table @The instance to set the value on
---@param sKey string @The key to set the value on
---@param xValue any @The value to set
---@param bSync? boolean @Server: Whether to sync the value change, Client: Mark the value as broadcasted
---@return boolean? @Return true if the value was set, nil otherwise
function ClassLib.SetValue(oInstance, sKey, xValue, bSync)
    assert(ClassLib.IsClassLibInstance(oInstance) and oInstance:IsValid(), "[ClassLib] Attempt to set a value on an invalid object")
    assert((type(sKey) == "string"), "[ClassLib] The key passed to ClassLib.SetValue is not a string")
    assert((type(xValue) ~= "function"), "[ClassLib] Attempt to set a function as a value")

    local tMT = getmetatable(oInstance)
    if not tMT then return end

    local xOldValue = tMT.__values[sKey]

    local tClass = ClassLib.GetClass(oInstance)
    if not tClass then return end

    if (sKey == "id") then
        handleIDChange(oInstance, tClass, xValue)
    end

    oInstance[sKey] = xValue
    tMT.__values[sKey] = xValue

    ClassLib.Call(tClass, "ValueChange", oInstance, sKey, xValue, xOldValue)
    ClassLib.Call(oInstance, "ValueChange", oInstance, sKey, xValue, xOldValue)

    if bSync and Server then
        local xSerialized = ClassLib.SerializeValue(xValue)
        local sClassName = tClass.GetClassName()
        local iID = oInstance:GetID()

        tMT.__sync_values[sKey] = xValue

        if tMT.__replicate_to_all then
            Events.BroadcastRemote(ClassLib.EventMap.SetValue, sClassName, iID, sKey, xSerialized)
        else
            for pPly, tInfo in pairs(tMT.__replicated_players) do
                if pPly:IsValid() then
                    Events.CallRemote(ClassLib.EventMap.SetValue, pPly, sClassName, iID, sKey, xSerialized)
                end
            end
        end
    end

    return true
end

if Client then
    Events.SubscribeRemote(ClassLib.EventMap.SetValue, function(sClassName, iID, sKey, xValue)
        local tClass = ClassLib.GetClassByName(sClassName)
        if not tClass then return end

        local oInstance = tClass.GetByID(iID)
        if not oInstance then return end

        ClassLib.SetValue(oInstance, sKey, ClassLib.ParseValue(xValue), true)
    end)
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
---@param bSyncedOnly? boolean @Whether to only get broadcasted values
---@return table @Table with the key as key and the value as value
function ClassLib.GetAllValuesKeys(oInstance, bSyncedOnly)
    assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to get all values from an invalid object")

    local tMT = getmetatable(oInstance)
    if not tMT then return {} end

    if bSyncedOnly then return tMT.__sync_values end
    return tMT.__values
end

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
        return tMT.__sync_values[sKey] ~= nil
    end
end

-- Instance identification
----------------------------------------------------------------------

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
---Checks if the passed object is a valid instance
---@param oInstance table @The instance to check
---@return boolean @True if the instance is valid, false otherwise
function ClassLib.IsValid(oInstance)
    if not ClassLib.IsClassLibInstance(oInstance) then return false end

    local tMT = getmetatable(oInstance)
    return tMT and tMT.__is_valid
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
---Checks if the passed object is being destroyed
---@param oInstance table @The instance to check
---@return boolean @True if the instance is being destroyed, false otherwise
function ClassLib.IsBeingDestroyed(oInstance)
    local tMT = getmetatable(oInstance)
    return tMT and (tMT.__is_being_destroyed ~= nil) or false
end

if Client then
    ---`🔸 Client`<br>
    ---Checks if the instance was spawned on the client side
    ---@param oInstance table @The instance to check
    ---@return boolean @false if it was spawned by the server, true if it was spawned by the client
    function ClassLib.HasAuthority(oInstance)
        return (ClassLib.GetID(oInstance) < 0)
    end
end

-- Instance binding
----------------------------------------------------------------------

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
        tMT.__bind.target:Unsubscribe("Destroy", tMT.__bind.target_destroy_ev)
    end

    oInstance:Unsubscribe("Destroy", tMT.__bind.self_destroy_ev)
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