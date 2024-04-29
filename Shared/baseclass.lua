--[[
    ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

---`🔸 Client`<br>`🔹 Server`<br>
---Base class for all classes
---@class BaseClass
---@overload fun(): BaseClass
---
BaseClass = {}

setmetatable(BaseClass, {
    __classname = "BaseClass",
    __call = function(self, ...)
        return self:NewInstance(...)
    end
})

------------------------------------------------------------------------------------------
-- Instance functions
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new instance of the class
---@param ... any? @Arguments to pass to the constructor
---@return table @The new instance
---
function BaseClass:NewInstance(...)
    return ClassLib.NewInstance(self, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys the instance
---@param ... any? @Arguments to pass to the destructor
---
function BaseClass:Destroy(...)
	return ClassLib.Destroy(self, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Called after an instance is created
---
function BaseClass:Constructor()
end

---`🔸 Client`<br>`🔹 Server`<br>
---Called when an instance is about to be destroyed, return `false` to cancel the destruction
---
function BaseClass:Destructor()
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which this instance inherits
---@return table|nil @The super class
---
function BaseClass:Super()
    return ClassLib.Super(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which this instance inherits
---@return table<integer, table> @The super classes
---
function BaseClass:SuperAll()
    return ClassLib.SuperAll(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class table of the instance
---@return table|nil @The class
---
function BaseClass:GetClass()
    return ClassLib.GetClass(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the ID of the instance, unique to the class
---@return integer|nil @Instance ID
---
function BaseClass:GetID()
    return ClassLib.GetID(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Clones the instance, and return a new instance with the same values (except it's ID)
---@param tIgnoredKeys? table @The properties to ignore (sequential table)
---@return table @The new instance
---
function BaseClass:Clone(tIgnoredKeys)
    return ClassLib.Clone(self, tIgnoredKeys)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is valid
---@return boolean @Whether the instance is valid
---
function BaseClass:IsValid()
    return ClassLib.IsValid(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is from a passed class, or from a class that inherits from the passed class
---@param oClass table @The class to check
---@param bRecursive boolean @Whether to check recursively
---@return boolean @Whether the value is an object from the class
---
function BaseClass:IsA(oClass, bRecursive)
    return ClassLib.IsA(self, oClass, bRecursive)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is being destroyed
---@return boolean @Whether the instance is being destroyed
---
function BaseClass:IsBeingDestroyed()
    return ClassLib.IsBeingDestroyed(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class name of the instance
---@return string|nil @The class name
---
function BaseClass:GetClassName()
    return ClassLib.GetClassName(self)
end

------------------------------------------------------------------------------------------
-- Static functions
-- These just serves for EmmyLua annotations, the real functions are in `ClassLib.Inherit`
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Returns all instances of this class
---@return table<integer, table> @Table of all instances of the class
---
function BaseClass.GetAll()
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns how many instances of this class exists
---@return integer @Amount of instance of the class
---
function BaseClass.GetCount()
    return 0
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns an instance of this class from the instance unique ID
---@param iID integer @The ID of the instance
---@return table|nil @The instance, or nil if it doesn't exist
---
function BaseClass.GetByID(iID)
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which this class inherits
---@return table|nil @The super class
---
function BaseClass.GetParentClass()
    return BaseClass
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which this class inherits
---@return table<integer, table> @The super classes
---
function BaseClass.GetAllParentClasses()
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes that inherit from this class
---@return table<integer, table> @The inherited classes
---
function BaseClass.GetInheritedClasses()
    return ClassLib.GetInheritedClasses(BaseClass)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Creates a new class that inherits from this class
---@param sClassName string @The name of the new class
---@param bSync? boolean @Whether to sync the creation/destruction of an instance of the class and it's broadcasted values to all players
---@return table @The new class
---
function BaseClass.Inherit(sClassName, bSync)
    return ClassLib.Inherit(BaseClass, sClassName, bSync)
end

------------------------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event on the Class
---@param sEvent string @The name of the event to call
---@param ... any @The arguments to pass to the event
---
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
---@return function|nil @The callback
---
function BaseClass.ClassSubscribe(sEvent, callback)
    return ClassLib.Subscribe(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events on this Class, optionally passing the function to unsubscribe only that callback
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
---
function BaseClass.ClassUnsubscribe(sEvent, callback)
    return ClassLib.Unsubscribe(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event on the instance
---@param sEvent string @The name of the event to call
---@param ... any @The arguments to pass to the event
---
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
---@return function|nil @The callback
---
function BaseClass:Subscribe(sEvent, callback)
    return ClassLib.Subscribe(self, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events in this instance, optionally passing the function to unsubscribe only that callback
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
---
function BaseClass:Unsubscribe(sEvent, callback)
    return ClassLib.Unsubscribe(self, sEvent, callback)
end

------------------------------------------------------------------------------------------
-- Networking
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to a remote event
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
---@return function|nil @The callback
---
function BaseClass.SubscribeRemote(sEvent, callback)
    return ClassLib.SubscribeRemote(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from a remote event
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
---
function BaseClass.UnsubscribeRemote(sEvent, callback)
    return ClassLib.UnsubscribeRemote(BaseClass, sEvent, callback)
end

if Client then
    ---`🔸 Client`<br>
    ---Calls a remote event from the client to the server
    ---@param sEvent string @The name of the event to call
    ---@param ... any @The arguments to pass to the event
    ---
    function BaseClass:CallRemote(sEvent, ...)
        return ClassLib.CallRemote_Client(self, sEvent, ...)
    end

elseif Server then
    ---`🔹 Server`<br>
    ---Calls a remote event from the server to the client
    ---@param sEvent string @The name of the event to call
    ---@param xPlayer Player|table<number, Player> @The player (or table of players) to which to send the event
    ---@param ... any @The arguments to pass to the event
    ---
    function BaseClass:CallRemote(sEvent, xPlayer, ...)
        ClassLib.CallRemote_Server(self, sEvent, xPlayer, ...)
    end

    ---`🔹 Server`<br>
    ---Broadcast a remote event from the server to all clients
    ---@param sEvent string @The name of the event to broadcast
    ---@param ... any @The arguments to pass to the event
    ---
    function BaseClass:BroadcastRemote(sEvent, ...)
        ClassLib.BroadcastRemote(self, sEvent, ...)
    end
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets a key/value on the instance
---@param sKey string @Key
---@param xValue any @Value
---@param bBroadcast? boolean @Whether to broadcast the key/value to all clients (server only)
---
function BaseClass:SetValue(sKey, xValue, bBroadcast)
    return ClassLib.SetValue(self, sKey, xValue, bBroadcast)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets a key/value from the instance
---@param sKey string @Key
---@param xFallback? any @Fallback value (if the key doesn't exist)
---@return any @Value
---
function BaseClass:GetValue(sKey, xFallback)
    return ClassLib.GetValue(self, sKey, xFallback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns all values of the instance set by `SetValue`
---@param bBroadcastedOnly? boolean @Whether to only return broadcasted values
---@return table<string, any> @All values
---
function BaseClass:GetAllValuesKeys(bBroadcastedOnly)
    return ClassLib.GetAllValuesKeys(self, bBroadcastedOnly)
end

if Server then
    ---`🔹 Server`<br>
    ---Returns wether a key has it's value is broadcasted
    ---@param sKey string @Key
    ---@return boolean @Whether the key is broadcasted
    ---
    function BaseClass:IsValueBroadcasted(sKey)
        return ClassLib.IsValueBroadcasted(self, sKey)
    end
end
