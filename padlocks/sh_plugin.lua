
local PLUGIN = PLUGIN

PLUGIN.name = "Padlocks"
PLUGIN.description = "Adds a system of placeable and breakable padlocks."
PLUGIN.author = "bruck"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

-- list of weapon classes that cannot be used to break padlocks
PLUGIN.padlockWeaponsBlacklist = {
    ["ix_hands"] = true,
}

ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)