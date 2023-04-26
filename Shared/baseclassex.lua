local type = type

---`🔸 Client`<br>`🔹 Server`<br>
---`BaseClassEx` is a class that represents an extended base class.<br>
---It inherits from `BaseClass` and adds some useful functions to it.
---@class BaseClassEx : BaseClass
---@overload fun(): BaseClassEx
---
BaseClassEx = BaseClass.Inherit("BaseClassEx")

---`🔸 Client`<br>`🔹 Server`<br>
---Returns the label of the instance
---@return string @Instance label
---
function BaseClassEx:GetLabel()
    return self.label or ""
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets the label of the instance
---@param sLabel string @New label
---
function BaseClassEx:SetLabel(sLabel)
    if (type(sLabel) ~= "string") then return end
    self.label = sLabel
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets the description of the instance
---@return string|nil @The description of the instance
---
function BaseClassEx:GetDescription()
    return self.description
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets the description of the instance
---@param sDesc string @The description of the instance
---
function BaseClassEx:SetDescription(sDesc)
    if (type(sDesc) ~= "string") then return end
    self.description = sDesc
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets the color of the instance
---@return Color|nil @The color of the instance
---
function BaseClassEx:GetColor()
    return self.color or Color(1, 1, 1)
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets the color of the instance
---@param oColor Color @The color of the instance
---
function BaseClassEx:SetColor(oColor)
    if (getmetatable(oColor) ~= Color) then return end
    self.color = oColor
end

---`🔸 Client`<br>`🔹 Server`<br>
---Gets the icon path of the instance
---@return string|nil @The icon of the instance
---
function BaseClassEx:GetIcon()
    return self.icon
end

---`🔸 Client`<br>`🔹 Server`<br>
---Sets the icon path of the instance
---@param sPath string @The icon of the instance
---
function BaseClassEx:SetIcon(sPath)
    if (type(sPath) ~= "string") then return end
    self.icon = sPath
end