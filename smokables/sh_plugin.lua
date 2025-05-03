
local PLUGIN = PLUGIN

PLUGIN.name = "Smokable Items"
PLUGIN.description = "Adds smokable cigarettes. Requires PAC and PAC Integration to work."
PLUGIN.author = "bruck, based on work by Adolphus"

if (!pace) then return end

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)