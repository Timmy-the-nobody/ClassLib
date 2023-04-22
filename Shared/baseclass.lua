---`🔸 Client`<br>`🔹 Server`<br>
---Base class for all classes
---@class BaseClass
---
BaseClass = {}
BaseClass.id = 0

setmetatable(BaseClass, {
    __call = function(self, ...)
        return ClassLib.NewInstance(self, ...)
    end
})

---`🔸 Client`<br>`🔹 Server`<br>
---Destroys the instance
---@param ... any @Arguments to pass to the destructor
---
function BaseClass:Destroy(...)
	return ClassLib.Destroy(self, ...)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class from which this instance inherits
---@return table @The super class
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
---Clones the instance, and return a new instance with the same values (except it's ID)
---@return table @The new instance
---
function BaseClass:Clone()
    return ClassLib.Clone(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the class table of the instance
---@return table @The class
---
function BaseClass:GetClass()
    return ClassLib.GetClass(self)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the ID of the instance, unique to the class
---@return integer @Instance ID
---
function BaseClass:GetID()
    return self.id
end

------------------------------------------------------------------------------------------
-- Static functions
-- The functions bellow are duplicated from `BaseClass:OnInherit`, to add EmmyLua support
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
---@return table @The super class
---
BaseClass.GetParentClass = function() return BaseClass end

---`🔸 Client`<br>`🔹 Server`<br>
---Returns a sequential table of all classes from which this class inherits
---@param bRecursive boolean @Whether to check recursively
---@return table<integer, table> @The super classes
---
BaseClass.GetParentClasses = function(bRecursive) return {} end

------------------------------------------------------------------------------------------
-- Base Class Methods
------------------------------------------------------------------------------------------

-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Returns the class table of the instance
-- ---@return table @Class table
-- ---
-- function BaseClass:GetClassTable()
--     return BaseClass
-- end


-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Returns the name of the instance
-- ---@return string @Instance name
-- ---
-- function BaseClass:GetName()
--     return self.name
-- end

-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Sets the name of the instance
-- ---@param sName string @New name
-- ---
-- function BaseClass:SetName(sName)
--     self.name = tostring(sName or "")
-- end

-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Returns the description of the instance
-- ---@return string @Instance description
-- ---
-- function BaseClass:GetDescription()
--     return self.description
-- end

-- ---`🔸 Client`<br>`🔹 Server`<br>
-- ---Sets the description of the instance
-- ---@param sDescription string @New description
-- ---
-- function BaseClass:SetDescription(sDescription)
--     self.description = tostring(sDescription or "")
-- end

