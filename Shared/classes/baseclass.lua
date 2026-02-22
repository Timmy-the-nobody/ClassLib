--[[
    ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

---`🔸 Client`<br>`🔹 Server`<br>
---Base class for all classes
---@class BaseClass
---@overload fun(): BaseClass
BaseClass = {}

setmetatable(BaseClass, {
    __classname = "BaseClass",
    __call = function(self, ...)
        return self:NewInstance(...)
    end
})

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new instance of the class
---@param ... any? @Arguments to pass to the constructor
---@return table @The new instance
function BaseClass:NewInstance(...)
    return ClassLib.NewInstance(self, nil, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys the instance
---@param ... any? @Arguments to pass to the destructor
function BaseClass:Destroy(...)
    return ClassLib.Destroy(self, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Called after the instance is created
function BaseClass:Constructor()
end

---`🔸 Client`<br>`🔹 Server`<br>
---Called when the instance is about to be destroyed, return `false` to cancel the destruction
---@return boolean? @Return `false` to cancel the destruction
function BaseClass:Destructor()
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which this instance inherits
---@return table? @The super class
function BaseClass:Super()
    return ClassLib.Super(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which this instance inherits
---@return table<integer, table> @The super classes
function BaseClass:SuperAll()
    return ClassLib.SuperAll(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class table of the instance
---@return table? @The class
function BaseClass:GetClass()
    return ClassLib.GetClass(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the ID of the instance, unique to the class
---@return integer? @Instance ID
function BaseClass:GetID()
    return ClassLib.GetID(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Clones the instance, and return a new instance with the same values (except it's ID)
---@param tIgnoredKeys? table @The properties to ignore (sequential table)
---@param ... any @The arguments to pass to the constructor
---@return table @The new instance
function BaseClass:Clone(tIgnoredKeys, ...)
    return ClassLib.Clone(self, tIgnoredKeys, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is valid
---@return boolean @Whether the instance is valid
function BaseClass:IsValid()
    return ClassLib.IsValid(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is from a passed class, or from a class that inherits from the passed class
---@param oClass table @The class to check
---@param bRecursive boolean @Whether to check recursively
---@return boolean @Whether the value is an object from the class
function BaseClass:IsA(oClass, bRecursive)
    return ClassLib.IsA(self, oClass, bRecursive)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is being destroyed
---@return boolean @Whether the instance is being destroyed
function BaseClass:IsBeingDestroyed()
    return ClassLib.IsBeingDestroyed(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class name of the instance
---@return string? @The class name
function BaseClass:GetClassName()
    return ClassLib.GetClassName(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Binds this instance to another instance (the bound instance will be destroyed when the "bound to" instance is destroyed)
---@param oBoundTo table @The instance to bind to
function BaseClass:Bind(oBoundTo)
    return ClassLib.Bind(self, oBoundTo)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unbinds this instance from any binding it has
function BaseClass:Unbind()
    return ClassLib.Unbind(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the instance to which this instance is bound
---@return table? @The bound instance
function BaseClass:GetBoundTo()
    return ClassLib.GetBoundTo(self)
end

-- Static functions, These just serves for LuaLS annotations
-- The overrides are in `ClassLib.Inherit`
----------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a copy of the table containing all instances of this class (safe to iterate while destroying)
---@return table<integer, table> @Table of all instances of the class
function BaseClass.GetAll()
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns all instances of this class and all of its inherited classes (recursive)
---@return table<integer, table> @All instances including child classes
function BaseClass.GetAllInherited()
    return ClassLib.GetAllInherited(BaseClass)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns how many instances of this class exists
---@return integer @Amount of instance of the class
function BaseClass.GetCount()
    return 0
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the instance of this class from the instance unique ID
---@param iID integer @The ID of the instance
---@return table? @The instance, or nil if it doesn't exist
function BaseClass.GetByID(iID)
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which this class inherits
---@return table? @The super class
function BaseClass.GetParentClass()
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which this class inherits
---@return table<integer, table> @The super classes
function BaseClass.GetAllParentClasses()
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes that inherit from this class
---@return table<integer, table> @The inherited classes
function BaseClass.GetInheritedClasses()
    return ClassLib.GetInheritedClasses(BaseClass)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from this class
---@param sClassName string @The name of the new class
---@param iFlags? ClassLib.FL @The class flags to use, defaults to `nil`
---@return table @The newly created class
---@see ClassLib.FL
function BaseClass.Inherit(sClassName, iFlags)
    return ClassLib.Inherit(BaseClass, sClassName, iFlags)
end

-- Events
----------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event on the Class
---@param sEvent string @The name of the event to call
---@param ... any @The arguments to pass to the event
function BaseClass.ClassCall(sEvent, ...)
    return ClassLib.Call(BaseClass, sEvent, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event on the Class
---@param sEvent string @The name of the event to listen to
---@param callback function @The callback to call when the event is triggered, return false to unsubscribe from the event
---@overload fun(self: BaseClass, sEvent: "Spawn", callback: fun(self: BaseClass))
---@overload fun(self: BaseClass, sEvent: "Destroy", callback: fun(self: BaseClass))
---@overload fun(self: BaseClass, sEvent: "ValueChange", callback: fun(self: BaseClass, sKey: string, xValue: any))
---@overload fun(self: BaseClass, sEvent: "ClassRegister", callback: fun(oInheritedClass: table))
---@overload fun(self: BaseClass, sEvent: "ReplicatedPlayerChange", callback: fun(oInheritedClass: table, oPlayer: Player, bAdded: boolean))
---@return function? @The callback
function BaseClass.ClassSubscribe(sEvent, callback)
    return ClassLib.Subscribe(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events on this Class, optionally passing the function to unsubscribe only that callback
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
function BaseClass.ClassUnsubscribe(sEvent, callback)
    return ClassLib.Unsubscribe(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event on the instance
---@param sEvent string @The name of the event to call
---@param ... any @The arguments to pass to the event
function BaseClass:Call(sEvent, ...)
    return ClassLib.Call(self, sEvent, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event on the instance
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
---@overload fun(self: BaseClass, sEvent: "Spawn", callback: fun(self: BaseClass))
---@overload fun(self: BaseClass, sEvent: "Destroy", callback: fun(self: BaseClass))
---@overload fun(self: BaseClass, sEvent: "ValueChange", callback: fun(self: BaseClass, sKey: string, xValue: any))
---@overload fun(self: BaseClass, sEvent: "ClassRegister", callback: fun(oInheritedClass: table))
---@return function? @The callback
function BaseClass:Subscribe(sEvent, callback)
    return ClassLib.Subscribe(self, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events in this instance, optionally passing the function to unsubscribe only that callback
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
function BaseClass:Unsubscribe(sEvent, callback)
    return ClassLib.Unsubscribe(self, sEvent, callback)
end

-- Networking
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to a remote event
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
---@return function? @The callback
function BaseClass.SubscribeRemote(sEvent, callback)
    return ClassLib.SubscribeRemote(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from a remote event
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
function BaseClass.UnsubscribeRemote(sEvent, callback)
    return ClassLib.UnsubscribeRemote(BaseClass, sEvent, callback)
end

if Client then
    ---`🔸 Client`<br>
    ---Returns wether the instance was spawned on the client side
    ---@return boolean @false if it was spawned by the server, true if it was spawned by the client
    function BaseClass:HasAuthority()
        return ClassLib.HasAuthority(self)
    end

    ---`🔸 Client`<br>
    ---Calls a remote event from the client to the server
    ---@param sEvent string @The name of the event to call
    ---@param ... any @The arguments to pass to the event
    function BaseClass:CallRemote(sEvent, ...)
        return ClassLib.CallRemote_Client(self, sEvent, ...)
    end
elseif Server then
    ---`🔹 Server`<br>
    ---Calls a remote event from the server to the client
    ---@param sEvent string @The name of the event to call
    ---@param xPlayer Player|table<number, Player> @The player (or table of players) to which to send the event
    ---@param ... any @The arguments to pass to the event
    function BaseClass:CallRemote(sEvent, xPlayer, ...)
        ClassLib.CallRemote_Server(self, sEvent, xPlayer, ...)
    end

    ---`🔹 Server`<br>
    ---Broadcast a remote event from the server to all players
    ---@param sEvent string @The name of the event to broadcast
    ---@param ... any @The arguments to pass to the event
    function BaseClass:BroadcastRemote(sEvent, ...)
        ClassLib.BroadcastRemote(self, sEvent, ...)
    end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets a key/value on the instance
---@param sKey string @Key
---@param xValue any @Value
---@param bSync? boolean @Whether to broadcast the key/value to all replicated players (server only)
function BaseClass:SetValue(sKey, xValue, bSync)
    return ClassLib.SetValue(self, sKey, xValue, bSync)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets multiple key/values on the instance in one call; on the server, syncs all in a
---single network event instead of one per key
---@param tKeyValues table<string, any> @Key/value pairs to set
---@param bSync? boolean @Whether to broadcast all changes to replicated players (server only)
function BaseClass:SetValues(tKeyValues, bSync)
    return ClassLib.SetValues(self, tKeyValues, bSync)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets a key/value from the instance
---@param sKey string @Key
---@param xFallback? any @Fallback value (if the key doesn't exist)
---@return any @Value
function BaseClass:GetValue(sKey, xFallback)
    return ClassLib.GetValue(self, sKey, xFallback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns all values of the instance set by `SetValue`
---@param bSyncedOnly? boolean @Whether to only return broadcasted values
---@return table<string, any> @All values
function BaseClass:GetAllValuesKeys(bSyncedOnly)
    return ClassLib.GetAllValuesKeys(self, bSyncedOnly)
end

if Server then
    ---`🔹 Server`<br>
    ---Returns wether a key has it's value is broadcasted
    ---@param sKey string @Key
    ---@return boolean @Whether the key is broadcasted
    function BaseClass:IsValueBroadcasted(sKey)
        return ClassLib.IsValueBroadcasted(self, sKey)
    end

    ---`🔹 Server`<br>
    ---Gets the players to replicate the instance to
    ---@return table<Player> @The players to replicate the instance to
    ---@return boolean @Whether the instance is replicated to **everyone**
    function BaseClass:GetReplicatedPlayers()
        return ClassLib.GetReplicatedPlayers(self)
    end

    ---`🔹 Server`<br>
    ---Sets the players to replicate the instance to
    ---@param tPlayers table<Player>|nil @The players to replicate the instance to
    function BaseClass:SetReplicatedPlayers(tPlayers)
        return ClassLib.SetReplicatedPlayers(self, tPlayers)
    end

    ---`🔹 Server`<br>
    ---Adds a player to replicate the instance to
    ---@param pPly Player @The player to replicate the instance to
    ---@return boolean @Whether the player was added
    function BaseClass:AddReplicatedPlayer(pPly)
        return ClassLib.AddReplicatedPlayer(self, pPly)
    end

    ---`🔹 Server`<br>
    ---Removes a player from replicating the instance to
    ---@param pPly Player @The player to remove
    ---@return boolean @Whether the player was removed
    function BaseClass:RemoveReplicatedPlayer(pPly)
        return ClassLib.RemoveReplicatedPlayer(self, pPly)
    end

    ---`🔹 Server`<br>
    ---Returns wether a player is replicating the instance
    ---@param pPly Player @The player to check
    ---@return boolean @Whether the player is replicating the instance
    function BaseClass:IsReplicatedTo(pPly)
        return ClassLib.IsReplicatedTo(self, pPly)
    end
end
