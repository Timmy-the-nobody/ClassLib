--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local pairs = pairs
local getmetatable = getmetatable
local select = select

local NanosUtils = NanosUtils
local Events = Events
local Server = Server
local Client = Client

---@enum ClassLib.FL
---Flags used to define the behavior of a class.<br>
ClassLib.FL = {
    --- - ClassLib.FL.Replicated (1) — Auto `AddReplicatedPlayer("*")` on spawn — all clients receive the instance.
    Replicated      = 1 << 0,
    --- - ClassLib.FL.GlobalPool (2) — Shared ID counter client/server — no negative IDs on client.
    GlobalPool      = 1 << 1,
    --- - ClassLib.FL.Singleton (4) — Only one valid instance allowed; `NewInstance` returns the existing one if still valid.
    Singleton       = 1 << 2,
    --- - ClassLib.FL.ServerAuthority (8) — Only the server can create positive-ID instances.
    ServerAuthority = 1 << 3,
    --- - ClassLib.FL.Abstract (16) — Cannot be instantiated directly; `NewInstance` asserts — child classes are unaffected.
    Abstract        = 1 << 4,
    --- - ClassLib.FL.ClientLocal (32) — Client can create local instances with negative IDs (never collide with server positive IDs).
    ClientLocal     = 1 << 5,
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
    local tSerialized = {}
    for i = 1, select('#', ...) do
        tSerialized[i] = ClassLib.SerializeValue((select(i, ...)))
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
    local tParsed = {}
    for i = 1, select('#', ...) do
        tParsed[i] = ClassLib.ParseValue((select(i, ...)))
    end
    return tParsed
end