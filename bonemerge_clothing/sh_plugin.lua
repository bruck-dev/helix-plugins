
local PLUGIN = PLUGIN

PLUGIN.name = "Bonemerged Clothing System"
PLUGIN.description = "Revised PAC-based clothing system that allows for multiple outfit category entries, automatic removal of conflicting clothing, and more."
PLUGIN.author = "bruck"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


if (!pace) then return end

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)