--[[
	ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

local type = type
local assert = assert
local getmetatable = getmetatable
local pairs = pairs
local ipairs = ipairs

-- Sync
----------------------------------------------------------------------

if Server then
    ---`🔹 Server`<br>
    ---Internal function to sync instance creation, not intended to be called directly.
    ---@param oInstance table @The instance to sync
    ---@param pPly Player? @The player to send the sync to, nil to broadcast to all players
    function ClassLib.SyncInstanceConstruct(oInstance, pPly)
        assert(ClassLib.IsValid(oInstance), "[ClassLib] Attempt to sync the construction of an invalid object")

        local sClass = oInstance:GetClassName()
        local iID = oInstance:GetID()
        local tValues = getmetatable(oInstance).__sync_values
        local tSerVal = ClassLib.SerializeValue(tValues)

        if pPly and (getmetatable(pPly) == Player) then
            if not pPly:IsValid() then return end
            Events.CallRemote(ClassLib.EventMap.Constructor, pPly, sClass, iID, tSerVal)
        else
            Events.BroadcastRemote(ClassLib.EventMap.Constructor, sClass, iID, tSerVal)
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
            Events.CallRemote(ClassLib.EventMap.Destructor, pPly, sClass, iID)
        else
            Events.BroadcastRemote(ClassLib.EventMap.Destructor, sClass, iID)
        end
    end
end

if Client then
    Events.SubscribeRemote(ClassLib.EventMap.Constructor, function(sClassName, iID, tValues)
        local tClass = ClassLib.GetClassByName(sClassName)
        if not tClass then return end

        local oInstance = tClass.GetByID(iID) or ClassLib.NewInstance(tClass, iID)
        for sKey, xValue in pairs(ClassLib.ParseValue(tValues)) do
            ClassLib.SetValue(oInstance, sKey, xValue, true)
        end
    end)

    Events.SubscribeRemote(ClassLib.EventMap.Destructor, function(sClassName, iID)
        local tClass = ClassLib.GetClassByName(sClassName)
        if not tClass then return end

        ClassLib.Destroy(tClass.GetByID(iID))
    end)
end

-- Replication
----------------------------------------------------------------------

if Server then
    local tAllPlayers = {}
    Player.Subscribe("Spawn", function(pPly)
        tAllPlayers[#tAllPlayers + 1] = pPly
    end)

    Player.Subscribe("Destroy", function(pPly)
        local tNewPlayers = {}
        for i = 1, #tAllPlayers do
            if (tAllPlayers[i] ~= pPly) then
                tNewPlayers[#tNewPlayers + 1] = tAllPlayers[i]
            end
        end
        tAllPlayers = tNewPlayers
    end)

    ---`🔹 Server`<br>
    ---Gets the players to replicate an instance to
    ---@param oInstance table @The instance to get
    ---@return table<Player> @The players to replicate the instance to
    ---@return boolean @Whether the instance is replicated to **everyone**
    function ClassLib.GetReplicatedPlayers(oInstance)
        local tMT = getmetatable(oInstance)
        if not tMT then return {}, false end

        if tMT.__replicate_to_all then
            return tAllPlayers, true
        end

        local tList = {}
        for pPly, _ in pairs(tMT.__replicated_players or {}) do
            tList[#tList + 1] = pPly
        end
        return tList, false
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

        if (xPlayers == "*") then
            ClassLib.AddReplicatedPlayer(oInstance, "*")
            return true
        end

        local tMT = getmetatable(oInstance)
        tMT.__replicate_to_all = false

        if (type(xPlayers) ~= "table") then
            if (xPlayers == false) then
                if tMT.__replicate_to_all then
                    ClassLib.RemoveReplicatedPlayer(oInstance, "*")
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
    ---@param xPly Player|"*"|table<Player> @The player to add, or "*" for all, or an array of players
    ---@return boolean @Whether the player was added (false if the player wasn't added, or if "*" was passed on an already replicated to all instance)
    function ClassLib.AddReplicatedPlayer(oInstance, xPly)
        if not ClassLib.IsClassLibInstance(oInstance) then return false end

        -- Replicate to all
        if (xPly == "*") then
            local tMT = getmetatable(oInstance)
            if tMT.__replicate_to_all then return false end

            tMT.__replicate_to_all = true
            tMT.__replicated_players = {}

            ClassLib.SyncInstanceConstruct(oInstance)
            return true
        end

        -- Replicate to multiple players
        if (type(xPly) == "table") then
            for _, p in ipairs(xPly) do
                ClassLib.AddReplicatedPlayer(oInstance, p)
            end
        end

        -- Replicate to single player
        if ClassLib.IsReplicatedTo(oInstance, xPly) then return false end
        if (getmetatable(xPly) ~= Player) then return false end

        local tMT = getmetatable(oInstance)
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
    ---@param xPly Player|"*"|table<Player> @The player to remove, or "*" for all, or an array of players
    ---@return boolean @Whether the player was removed (false if the player wasn't removed or "*" was passed on an instance already replicated to everyone)
    function ClassLib.RemoveReplicatedPlayer(oInstance, xPly)
        if not ClassLib.IsClassLibInstance(oInstance) then return false end

        -- Desync all
        if (xPly == "*") then
            local tMT = getmetatable(oInstance)
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

        -- Desync multiple players
        if (type(xPly) == "table") then
            for _, p in ipairs(xPly) do
                ClassLib.RemoveReplicatedPlayer(oInstance, p)
            end
        end

        -- Desync single player
        if not ClassLib.IsReplicatedTo(oInstance, xPly) then return false end

        local tMT = getmetatable(oInstance)
        tMT.__replicated_players[xPly] = nil

        ClassLib.Call(ClassLib.GetClass(oInstance), "ReplicatedPlayerChange", oInstance, xPly, false)
        ClassLib.Call(oInstance, "ReplicatedPlayerChange", oInstance, xPly, false)

        if xPly:IsValid() then
            ClassLib.SyncInstanceDestroy(oInstance, xPly)
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
        for _, oClass in ipairs(ClassLib.__classlist) do
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