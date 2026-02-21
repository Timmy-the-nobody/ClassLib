--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local pairs = pairs
local ipairs = ipairs
local getmetatable = getmetatable

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
    if not tEvents or not tEvents[sEvent] then return end

    local tSnapshot = {}
    local tSource = tEvents[sEvent]
    for i = 1, #tSource do tSnapshot[i] = tSource[i] end

    for _, fnCallback in ipairs(tSnapshot) do
        if (fnCallback(...) == false) then
            ClassLib.Unsubscribe(oInput, sEvent, fnCallback)
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

        local tArgs = ClassLib.SerializeArgs(...)
        Events.CallRemote(ClassLib.EventMap.CLToSV, sClass, oInstance:GetID(), sEvent, table.unpack(tArgs))
    end

    local tPendingRemoteWaiters = {}
    Events.SubscribeRemote(ClassLib.EventMap.SVToCL, function(sClassName, iID, sEvent, ...)
        local tClass = ClassLib.__classmap[sClassName]
        if not tClass then return end

        local tClassMT = getmetatable(tClass)
        local tRemoteEvents = tClassMT.__remote_events
        if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

        local oInstance = tClassMT.__instances_map[iID]
        local tArgs = ClassLib.ParseArgs(...)
        if oInstance then
            for _, fnCallback in ipairs(tRemoteEvents[sEvent]) do
                fnCallback(oInstance, table.unpack(tArgs))
            end
            return
        end

        local tByID = tPendingRemoteWaiters[sClassName]
        if not tByID then
            tByID = {}
            tPendingRemoteWaiters[sClassName] = tByID
        end
        tByID[iID] = tByID[iID] or {}

        local fnWaiter
        fnWaiter = tClass.ClassSubscribe("Spawn", function(self)
            if (self:GetID() ~= iID) then return end

            local tList = tPendingRemoteWaiters[sClassName]
            if tList and tList[iID] then
                local tNew = {}
                for _, fn in ipairs(tList[iID]) do
                    if (fn ~= fnWaiter) then
                        tNew[#tNew + 1] = fn
                    end
                end
                tList[iID] = (#tNew > 0) and tNew or nil
            end

            for _, fnCallback in ipairs(tRemoteEvents[sEvent]) do
                fnCallback(self, table.unpack(tArgs))
            end

            return false
        end)

        tByID[iID][#tByID[iID] + 1] = fnWaiter
    end)

    Events.SubscribeRemote(ClassLib.EventMap.Destructor, function(sClassName, iID)
        local tByID = tPendingRemoteWaiters[sClassName]
        if not tByID or not tByID[iID] then return end

        local tClass = ClassLib.__classmap[sClassName]
        if tClass then
            for _, fnWaiter in ipairs(tByID[iID]) do
                tClass.ClassUnsubscribe("Spawn", fnWaiter)
            end
        end
        tByID[iID] = nil
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
            local tArgs = ClassLib.SerializeArgs(...)
            Events.CallRemote(ClassLib.EventMap.SVToCL, xPlayer, sClass, oInstance:GetID(), sEvent, table.unpack(tArgs))
            return
        end

        if (type(xPlayer) ~= "table") then return end

        local iID = oInstance:GetID()
        local tArgs = ClassLib.SerializeArgs(...)
        for _, pPly in ipairs(xPlayer) do
            if (getmetatable(pPly) == Player) then
                Events.CallRemote(ClassLib.EventMap.SVToCL, pPly, sClass, iID, sEvent, table.unpack(tArgs))
            end
        end
    end

    ---`🔹 Server`<br>
    ---Broadcasts a remote event from the server to all players
    ---@param oInstance table @The object to broadcast the event on
    ---@param sEvent string @The name of the event to broadcast
    ---@param ... any @The arguments to pass to the event
    function ClassLib.BroadcastRemote(oInstance, sEvent, ...)
        if (type(sEvent) ~= "string") then return end

        local sClass = ClassLib.GetClassName(oInstance)
        if not sClass then return end

        local tArgs = ClassLib.SerializeArgs(...)
        Events.BroadcastRemote(ClassLib.EventMap.SVToCL, sClass, oInstance:GetID(), sEvent, table.unpack(tArgs))
    end

    Events.SubscribeRemote(ClassLib.EventMap.CLToSV, function(pPly, sClassName, iID, sEvent, ...)
        local tClass = ClassLib.__classmap[sClassName]
        if not tClass then return end

        local oInstance = getmetatable(tClass).__instances_map[iID]
        if not oInstance then return end

        local tRemoteEvents = getmetatable(tClass).__remote_events
        if not tRemoteEvents or not tRemoteEvents[sEvent] then return end

        local tArgs = ClassLib.ParseArgs(...)
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