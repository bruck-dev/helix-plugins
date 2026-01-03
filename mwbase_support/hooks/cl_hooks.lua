
local PLUGIN = PLUGIN

-- we want the ui to close when the player moves too far away from a workbench
function PLUGIN:Think()
    if ix.config.Get("useWeaponBenches(MWB)", true) then
        local client = LocalPlayer()
        if IsValid(client) and client:GetCharacter() then
            local weapon = client:GetActiveWeapon()
            if weapon and IsValid(weapon) and weapons.IsBasedOn(weapon:GetClass(), "mg_base") then
                if hook.Run("IsCustomizing", client, weapon) and !hook.Run("NearWeaponBench", client) then
                    hook.Run("StopCustomizing", client, weapon)
                end
            end
        end
    end
end