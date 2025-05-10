
PLUGIN.name = "Disable Business Menu"
PLUGIN.description = "Disables the business menu in all cases."
PLUGIN.author = "bruck"

function PLUGIN:BuildBusinessMenu()
    return false
end