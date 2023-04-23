---`🔸 Client`<br>`🔹 Server`<br>
---Base class for all classes
---@class BaseClass
---
BaseClass = {}

setmetatable(BaseClass, {
    __class_name = "BaseClass",
    __call = function(self, ...)
        return ClassLib.NewInstance(self, ...)
    end
})

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
---Destroys the instance
---@param ... any @Arguments to pass to the destructor
---
function BaseClass:Destroy(...)
	return ClassLib.Destroy(self, ...)
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
---Returns the ID of the instance, unique to the class
---@return integer @Instance ID
---
function BaseClass:GetID()
    return self.id
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class table of the instance
---@return table|nil @The class
---
function BaseClass:GetClass()
    return ClassLib.GetClass(self)
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
-- Networking
------------------------------------------------------------------------------------------

function BaseClass:SetValue(sKey, xValue, bBroadcast)
    self[sKey] = xValue

    if Server and bBroadcast then

        -- Events.CallRemote("CLib:SetKV", )
    end
end

------------------------------------------------------------------------------------------
-- Base Class Methods
------------------------------------------------------------------------------------------

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the label of the instance
---@return string @Instance label
---
function BaseClass:GetLabel()
    return self.label or ""
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets the label of the instance
---@param sLabel string @New label
---
function BaseClass:SetLabel(sLabel)
    self.label = tostring(sLabel or "")
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the description of the instance
---@return string @Instance description
---
function BaseClass:GetDescription()
    return self.description
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets the description of the instance
---@param sDescription string @New description
---
function BaseClass:SetDescription(sDescription)
    self.description = tostring(sDescription or "")
end

