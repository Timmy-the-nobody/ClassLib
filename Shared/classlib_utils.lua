--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local pairs = pairs
local getmetatable = getmetatable

local ClassLib = ClassLib
local NanosUtils = NanosUtils
local Events = Events
local Server = Server
local Client = Client

---@enum ClassLib.FL
---Flags used to define the behavior of a class<br>
---- `Replicated`      (1)  - Replicate the instance to all players by default<br>
---- `GlobalPool`      (2)  - Use a shared ID space (usefull for instances created on the shared-side without any sync, keeps consistent IDs between server/client)
---- `Singleton`       (4)  - Only allow one instance of the class to exist at a time
---- `ServerAuthority` (8)  - Only allow the server to create instances of the class
---- `Abstract`        (16) - Do not allow instances of the class to be created
ClassLib.FL = {
    Replicated      = 1 << 0,
    GlobalPool      = 1 << 1,
    Singleton       = 1 << 2,
    ServerAuthority = 1 << 3,
    Abstract        = 1 << 4
}

-- Metatables that should not be traversed during (de)serialization (nanos world already does this for us)
local tSafeMetatables = {
    [Color] = true,
    [Matrix] = true,
    [Quat] = true,
    [Rotator] = true,
    [Vector] = true,
    [Vector2D] = true
}

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if a flag is set on a value
---@param iFlags number @The value to check
---@param iFlag number @The flag to check for in `ClassLib.FL`
---@see ClassLib.FL
function ClassLib.HasFlag(iFlags, iFlag)
    if not iFlags or not iFlag then return false end
    return ((iFlags % (2 * iFlag)) >= iFlag)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Serializes a value to be sent over the network
---@param xVal any @The value to serialize
---@return any @The serialized value
function ClassLib.SerializeValue(xVal, __tSeen)
    local sType = type(xVal)

    if ClassLib.IsClassLibInstance(xVal) then
        if Client and ClassLib.HasAuthority(xVal) then return end
        return {__clib = true, c = xVal:GetClassName(), i = xVal:GetID()}

    elseif NanosUtils.IsEntityValid(xVal) then
        return xVal

    elseif (sType == "table") and not tSafeMetatables[getmetatable(xVal)] then
        __tSeen = __tSeen or {}
        if __tSeen[xVal] then return end

        __tSeen[xVal] = true

        local tRes = {}
        for k, v in pairs(xVal) do
            local xK = ClassLib.SerializeValue(k, __tSeen)
            if (xK ~= nil) then
                tRes[xK] = ClassLib.SerializeValue(v, __tSeen)
            end
        end
        return tRes
    end

    return xVal
end

---`🔸 Client`<br>`🔹 Server`<br>
---Serializes multiple values to be sent over the network
---@param ... any @The values to serialize
---@return table @The serialized values
function ClassLib.SerializeArgs(...)
    local tArgs, tSerialized = {...}, {}
    for i = 1, #tArgs do
        tSerialized[i] = ClassLib.SerializeValue(tArgs[i])
    end
    return tSerialized
end

---`🔸 Client`<br>`🔹 Server`<br>
---Deserializes a value sent over the network
---@param xVal any @The value to deserialize
---@return any @The deserialized value
function ClassLib.ParseValue(xVal)
    if NanosUtils.IsEntityValid(xVal) then
        return xVal
    end

    if (type(xVal) == "table") and not tSafeMetatables[getmetatable(xVal)] then
        if xVal.__clib then
            local tClass = ClassLib.GetClassByName(xVal.c)
            if not tClass then return end
            return getmetatable(tClass).__instances_map[xVal.i]
        else
            local tRes = {}
            for i, j in pairs(xVal) do tRes[i] = ClassLib.ParseValue(j) end
            return tRes
        end
    else
        return xVal
    end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Deserializes multiple values sent over the network
---@param ... any @The values to deserialize
---@return table @The deserialized values
function ClassLib.ParseArgs(...)
    local tArgs, tParsed = {...}, {}
    for i = 1, #tArgs do
        tParsed[i] = ClassLib.ParseValue(tArgs[i])
    end
    return tParsed
end