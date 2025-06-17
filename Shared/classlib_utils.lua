--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local pairs = pairs
local getmetatable = getmetatable

---@enum ClassLib.FL
---Flags used to define the behavior of a class<br>
---- `Replicated` (1) - Replicate the instance to all players by default<br>
---- `GlobalPool` (2) - Use a shared ID space (usefull for instances created on the shared-side without any sync, keeps consistent IDs between server/client)
---- `Singleton` (3) - Only allow one instance of the class to exist at a time
ClassLib.FL = {
    Replicated = 1,
    GlobalPool = 2,
    Singleton = 4,
    ServerAuthority = 8
    -- 16, 32, 64, 128, 256, 512, etc..
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
function ClassLib.SerializeValue(xVal, tSeen)
    tSeen = tSeen or {}
    local sType = type(xVal)

    -- Prevent infinite recursion on circular references
    if (sType == "table") and tSeen[xVal] then return end

    if ClassLib.IsClassLibInstance(xVal) then
        if Client and ClassLib.HasAuthority(xVal) then return end
        return {__clib = true, c = xVal:GetClassName(), i = xVal:GetID()}

    elseif (type(xVal) == "table") then
        tSeen[xVal] = true

        local tRes = {}
        for k, v in pairs(xVal) do
            local xK = ClassLib.SerializeValue(k, tSeen)
            if (xK ~= nil) then
                tRes[xK] = ClassLib.SerializeValue(v, tSeen)
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
    if (type(xVal) == "table") then
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