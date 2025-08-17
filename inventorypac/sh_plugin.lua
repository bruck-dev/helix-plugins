PLUGIN.name = "Inventory PAC Items"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds support for PAC data on items based on inventory presence, in addition to equip status."

if (!pace) then return end

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

ix.pac = ix.pac or {}
ix.pac.pacInv = true