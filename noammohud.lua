
PLUGIN.name = "No Ammo Hud"
PLUGIN.description = "Disables the base Helix ammo HUD."
PLUGIN.author = "bruck"

if CLIENT then
    function PLUGIN:CanDrawAmmoHUD(weapon)
        return false
    end
end