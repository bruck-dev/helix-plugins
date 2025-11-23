
local PLUGIN = PLUGIN

PLUGIN.name = "Suppression"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds a simple suppression system for near misses from NPCs or players."
PLUGIN.specialThanks = "BaJlepa 6oJlbIIIou' eJlDaK, who's addons I referenced on a few occasions to optimize my networking. Defrektik, for the heartbeat sound effects."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

ix.util.Include("sh_config.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)