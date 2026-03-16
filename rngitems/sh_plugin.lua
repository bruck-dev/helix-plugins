
local PLUGIN = PLUGIN

PLUGIN.name = "RNG Item Models"
PLUGIN.description = "Adds a simple way to randomize item models. Put as high in your load order as possible."
PLUGIN.author = "bruck"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)