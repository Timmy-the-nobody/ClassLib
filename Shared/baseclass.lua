---`🔸 Client`<br>`🔹 Server`<br>
---Base class for all classes
---@class BaseClass
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
---@param ... any @Arguments to pass to the constructor
---@return table @The new instance
---
function BaseClass:NewInstance(...)
    return ClassLib.NewInstance(self, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys the instance
---@param ... any @Arguments to pass to the destructor
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
---@return table @The new instance
---
function BaseClass:Clone()
    return ClassLib.Clone(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Checks if the instance is valid
---@return boolean @Whether the instance is valid
---
function BaseClass:IsValid()
    return ClassLib.IsValid(self)
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
---Gets all instances of the class
---@return table<integer, table> @Table of all instances of the class
---
function BaseClass.GetAll()
    return {}
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets the number of instances of the class
---@return integer @The number of instances
---
function BaseClass.GetCount()
    return 0
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets an instance of this class by its unique ID
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
---Creates a new class that inherits from this class
---@param sClassName string @The name of the new class
---@return table @The new class
---
function BaseClass.Inherit(sClassName)
    return ClassLib.Inherit(BaseClass, sClassName)
end

------------------------------------------------------------------------------------------
-- Events methods
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event
---@param sEvent string @The name of the event to call
---@vararg any @The arguments to pass to the event
---
function BaseClass.ClassCall(sEvent, ...)
    return ClassLib.Call(BaseClass, sEvent, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event
---@param sEvent string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
---@return function|nil @The callback
---
function BaseClass.ClassSubscribe(sEvent, callback)
    return ClassLib.Subscribe(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events in this Class, optionally passing the function to unsubscribe only that callback
---@param sEvent string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
---
function BaseClass.ClassUnsubscribe(sEvent, callback)
    return ClassLib.Unsubscribe(BaseClass, sEvent, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Calls an Event on the instance
---@param sName string @The name of the event to call
---@vararg any @The arguments to pass to the event
---
function BaseClass:Call(sName, ...)
    return ClassLib.Call(self, sName, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Subscribes to an Event on the instance
---@param sName string @The name of the event to subscribe to
---@param callback function @The callback to call when the event is triggered
---@return function|nil @The callback
---
function BaseClass:Subscribe(sName, callback)
    return ClassLib.Subscribe(self, sName, callback)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Unsubscribes from all subscribed Events in this instance, optionally passing the function to unsubscribe only that callback
---@param sName string @The name of the event to unsubscribe from
---@param callback? function @The callback to unsubscribe
---
function BaseClass:Unsubscribe(sName, callback)
    return ClassLib.Unsubscribe(self, sName, callback)
end

------------------------------------------------------------------------------------------
-- Networking
------------------------------------------------------------------------------------------

-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Returns the value of a key
-- ---@param sKey string @Key
-- ---@param xFallback any @Fallback value
-- ---@return any @Value
-- ---
-- function BaseClass:GetNWValue(sKey, xFallback)
--     return getmetatable(self).__nw_values[sKey]
-- end

-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Sets the value of a key
-- ---@param sKey string @Key
-- ---@param xValue any @Value
-- ---
-- function BaseClass:SetNWValue(sKey, xValue)
--     if (sKey == nil) then return end

--     getmetatable(self).__nw_values[sKey] = xValue

--     if Server then
--         local sClassName = self:GetClassName()
--         if not sClassName then return end

--         Events.BroadcastRemote("CLib:SetKV", self:GetClassName(), self:GetID(), sKey, xValue)
--     end
-- end

