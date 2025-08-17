
PLUGIN.name = "No Item Entity Menu"
PLUGIN.author = "bruck"
PLUGIN.description = "Disables entity menus from appearing on dropped items."

if CLIENT then
    function PLUGIN:ShowEntityMenu(entity)
        if entity:GetClass() == "ix_item" then
            return false
        end
    end
end