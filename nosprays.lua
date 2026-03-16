
local PLUGIN = PLUGIN

PLUGIN.name = "No Sprays"
PLUGIN.author = "bruck"
PLUGIN.description = "Disables Source sprays."

if SERVER then
    function PLUGIN:PlayerSpray(client)
        return true
    end
end