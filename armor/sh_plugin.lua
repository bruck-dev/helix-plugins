
local PLUGIN = PLUGIN

PLUGIN.name = "Armor Outfit System"
PLUGIN.description = "Adds support for a hitgroup-based armor system, complete with resistances and durability."
PLUGIN.author = "bruck"

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)