
local PLUGIN = PLUGIN

-- we want the ui to close when the player moves too far away from a workbench
-- theres probably a better way to do this, but it seems like SWEP:ThinkCustomize() is used as a VARIABLE instead of a direct call so it doesnt really override nicely
function PLUGIN:Think()
    if ix.config.Get("useWeaponBenches", true) then
        local client = LocalPlayer()
        if IsValid(client) and client:GetCharacter() then
            local weapon = client:GetActiveWeapon()

            if weapon and IsValid(weapon) and weapons.IsBasedOn(weapon:GetClass(), "arc9_base") then
                if weapon:GetCustomize() then
                    local nearBench = false
                    for _, bench in ipairs(ents.FindByClass("ix_arc9_weapon_bench")) do
                        if (client:GetPos():DistToSqr(bench:GetPos()) < 100 * 100) then
                            nearBench = true
                            break
                        end
                    end

                    if !nearBench then
                        weapon:SetCustomize(false)
                        net.Start("ARC9_togglecustomize")
                            net.WriteBool(false)
                        net.SendToServer()
                    end
                end
            end

        end

    end
end