
local PLUGIN = PLUGIN

PLUGIN.name = "Better Flashlights"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds support for multiple flashlight items and a configuration option to eliminate the need entirely."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


if SERVER then
    -- hook in to allow players to use a flashlight if they meet the requirements, or if freeFlashlights is disabled and it's currently on (to allow it to automatically be turned off in the config callback)
    function PLUGIN:MeetsFlashlightRequirements(client)
        -- freeFlashlights overrides all other settings and checks
        if ix.config.Get("freeFlashlights", false) then
            return true
        end

        local character = client:GetCharacter()
        local inventory = character and character:GetInventory()
        if inventory then
            for k, _ in inventory:Iter() do
                if k.isFlashlight then
                    return true
                end
            end
        end
    end

    -- allow the player to toggle their light if they meet the requirements hook OR they are turning it off and freeFlashlights is disabled, such that its not stuck on
    function PLUGIN:PlayerSwitchFlashlight(client, bEnabled)
        return hook.Run("MeetsFlashlightRequirements", client) or (!ix.config.Get("freeFlashlights", false) and !bEnabled)
    end
end

-- allow flashlights for free. automatically turns off flashlights for players who can't use them when it is set back to false from true.
ix.config.Add("freeFlashlights", false, "Whether or not a flashlight item is required for a player to toggle their flashlight.", function(oldValue, newValue)
    if (SERVER) then
        if !newValue then
            for _, v in player.Iterator()	do
                if v:FlashlightIsOn() and !hook.Run("MeetsFlashlightRequirements", v) then
                    v:Flashlight(false)
                end
            end
        end
    end
end,
{
    category = "Utility"
})