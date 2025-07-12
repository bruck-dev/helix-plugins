
local PLUGIN = PLUGIN

-- overwrite the base PlayerBindPress function to not allow using 'c' to open the customize menu when benches is enabled
hook.Remove("PlayerBindPress", "ArcCW_PlayerBindPress")

local function SendNet(string, bool)
    net.Start(string)
    if bool != nil then net.WriteBool(bool) end
    net.SendToServer()
end
local function ArcCW_TranslateBindToEffect(bind)
    local alt = ArcCW.ConVars["altbindsonly"]:GetBool()
    if alt then
        return ArcCW.BindToEffect_Unique[bind], true
    else
        return ArcCW.BindToEffect_Unique[bind] or ArcCW.BindToEffect[bind] or bind, ArcCW.BindToEffect_Unique[bind] != nil
    end
end
local function ArcCW_PlayerBindPress(client, bind, pressed)
    if !(client:IsValid() and pressed) then return end

    local wep = client:GetActiveWeapon()

    if !wep.ArcCW then return end

    local block = false

    if GetConVar("arccw_nohl2flash"):GetBool() and bind == "impulse 100" then
        ToggleAtts(wep)

        if client:FlashlightIsOn() then return false end -- if hl2 flahslight is on we will turn it off as expected

        return true -- we dont want hl2 flashlight
     end

    local alt
    bind, alt = ArcCW_TranslateBindToEffect(bind)

    if bind == "firemode" and (alt or true) and !client:KeyDown(IN_USE) then
		SendNet("arccw_firemode")
		wep:ChangeFiremode()

        block = true
    elseif bind == "inv" and !client:KeyDown(IN_USE) and ArcCW.ConVars["enable_customization"]:GetInt() > -1 then

        local state = wep:GetState() != ArcCW.STATE_CUSTOMIZE

        if ix.config.Get("useWeaponBenches(ArcCW)", false) and state then
            if hook.Run("NearWeaponBench", client) then
                SendNet("arccw_togglecustomize", state)
                wep:ToggleCustomizeHUD(state)
            end
        else
            SendNet("arccw_togglecustomize", state)
            wep:ToggleCustomizeHUD(state)
        end

        block = true
    elseif bind == "ubgl" then
        DoUbgl(wep)
    elseif bind == "toggleatt" then
        ToggleAtts(wep)
    end

    if wep:GetState() == ArcCW.STATE_SIGHTS then
        if bind == "zoomin" then
            wep:Scroll(1)
            block = true
        elseif bind == "zoomout" then
            wep:Scroll(-1)
            block = true
        elseif bind == "switchscope_dtap" then
            if lastpressE >= CurTime() - 0.25 then
                wep:SwitchActiveSights()
                lastpressE = 0
            else
                lastpressE = CurTime()
            end
        elseif bind == "switchscope" then
            wep:SwitchActiveSights()
            block = true
        end
    end

    if bind == "melee" and wep:GetState() != ArcCW.STATE_SIGHTS then
        wep:Bash()
    end

    if block then return true end
end

hook.Add("PlayerBindPress", "ixArcCW_PlayerBindPress", ArcCW_PlayerBindPress)

-- we want the ui to close when the player moves too far away from a workbench
function PLUGIN:Think()
    if ix.config.Get("useWeaponBenches(ArcCW)", true) then
        local client = LocalPlayer()
        if IsValid(client) and client:GetCharacter() then
            local weapon = client:GetActiveWeapon()

            if weapon and IsValid(weapon) and weapons.IsBasedOn(weapon:GetClass(), "arccw_base") then
                if weapon:GetState() == ArcCW.STATE_CUSTOMIZE then
                    if !hook.Run("NearWeaponBench", client) then
                        SendNet("arccw_togglecustomize", false)
                        weapon:ToggleCustomizeHUD(false)
                    end
                end
            end
        end
    end
end