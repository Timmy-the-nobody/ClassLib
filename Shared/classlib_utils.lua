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
    Replicated = (2 ^ 0),
    GlobalPool = (2 ^ 1),
    Singleton = (2 ^ 2)
    -- ServerAuthority = 8,
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
function ClassLib.SerializeValue(xVal)
    if ClassLib.IsClassLibInstance(xVal) then
        if Client and ClassLib.HasAuthority(xVal) then return end
        return {__classlib = true, c = xVal:GetClassName(), i = xVal:GetID()}
    elseif (type(xVal) == "table") then
        local tRes = {}
        for i, j in pairs(xVal) do tRes[i] = ClassLib.SerializeValue(j) end
        return tRes
    else
        return xVal
    end
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
        if xVal.__classlib then
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