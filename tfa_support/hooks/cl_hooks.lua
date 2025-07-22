
local PLUGIN = PLUGIN

-- we want the ui to close when the player moves too far away from a workbench
function PLUGIN:Think()
    if ix.config.Get("useWeaponBenches(Tfa)", true) then
        local client = LocalPlayer()
        if IsValid(client) and client:GetCharacter() then
            local weapon = client:GetActiveWeapon()

            if weapon and IsValid(weapon) and (weapon.Base and string.find(weapon.Base, "tfa_")) then
                if weapon:GetCustomizing() then
                    if !hook.Run("NearWeaponBench", client) then
                        net.Start("ixTFAStopCustomize")
                            net.WriteUInt(client:GetCharacter():GetID(), 32)
                            net.WriteUInt(weapon:EntIndex(), 32)
                        net.SendToServer()
                    end
                end
            end
        end
    end
end

function PLUGIN:TFA_InspectVGUI_Start(weapon)
    if GetConVar("sv_tfa_attachments_enabled"):GetBool() and ix.config.Get("useWeaponBenches(Tfa)", true) and !hook.Run("NearWeaponBench", LocalPlayer()) then
        return false
    end
end

function PLUGIN:TFA_InspectVGUI_AttachmentsStart(weapon)
    if ix.config.Get("useWeaponBenches(Tfa)", true) and !hook.Run("NearWeaponBench", LocalPlayer()) then
        return false
    end
end

function PLUGIN:TFA_DrawCrosshair(weapon, x, y)
    if !ix.config.Get("enableCrosshair(Tfa)", false) then
        return false -- this allows the engine crosshair to show but blocks the TFA one
    end
end

function PLUGIN:TFA_DrawHUDAmmo(weapon, x, y, alpha)
    if !ix.config.Get("enableWeaponHud(Tfa)", false) then
        return false
    end
end