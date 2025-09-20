PLUGIN.name = "Inventory PAC Items"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds support for PAC data on items based on inventory presence, in addition to equip status."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

if (!pace) then return end

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

ix.pac = ix.pac or {}
ix.pac.pacInv = true