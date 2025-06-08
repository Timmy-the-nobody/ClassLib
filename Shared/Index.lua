--[[
    ClassLib
    GNU General Public License v3.0
    Copyright © Timmy-the-nobody, 2023, https://github.com/Timmy-the-nobody
]]--

ClassLib = {}

Package.Require("classlib_utils.lua")
Package.Require("classlib_core.lua")
Package.Require("classlib_instance.lua")
Package.Require("classlib_events.lua")
Package.Require("classlib_sync.lua")

Package.Require("classes/baseclass.lua")
Package.Require("classes/baseclassex.lua")

Package.Export("ClassLib", ClassLib)
Package.Export("BaseClass", BaseClass)
Package.Export("BaseClassEx", BaseClassEx)