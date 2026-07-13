ITEM.name = "Radio Base"
ITEM.model = "models/props_lab/citizenradio.mdl"
ITEM.description = "A base for radio items."
ITEM.category = "Communication"
ITEM.width = 1
ITEM.height = 1

ITEM.isRadio = true         -- always keep true; this allows the radio to be used with /radio commands
ITEM.twoWay = true          -- whether or not the radio can receive AND send messages. if false, can only receive
ITEM.canGarble = true       -- whether or not the radio's transmitted messages can ever be garbled. useful if you want broadcast-style radios that cannot garble, ever
ITEM.transmitPower = 1.0    -- if it can garble, transmitPower is a multiplier after normal range math is done. 1.0 implies no modification, whereas 1.2 would be a 20% boost and 0.8 would be a 20% malus

ITEM.enableSound = nil      -- can be a string or a list of strings
ITEM.disableSound = nil
ITEM.receiveSound = nil

-- in MHz; unit conversions are done only on display, it's all calculated in MHz internally
ITEM.frequencyBand = {
    ["min"] = 30.0,
    ["max"] = 300.0,
}

-- Inventory drawing
if (CLIENT) then
    function ITEM:PaintOver(item, w, h)
        if (item:GetData("enabled")) then
            surface.SetDrawColor(110, 255, 110, 100)
            surface.DrawRect(w - 14, h - 14, 8, 8)
        end

        -- might want to make a custom font and make this a bit smaller
        local freq, unit = item:GetDisplayFrequency()
        if freq and freq != "0.0" and unit then
            draw.SimpleText(
                freq .. " " .. unit, 'ixGenericFont', w / 2, h - 1,
                color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black
            )
        end
    end

    function ITEM:PopulateTooltip(tooltip)
        local font = "ixSmallFont"

        local gap = tooltip:AddRowAfter("description", "gap")
        gap:SetText(" ")
        gap:SizeToContents()

        local panel = tooltip:AddRowAfter("description", "band")
        
        local min, max, minUnit, maxUnit = self:GetFrequencyBand()
        panel:SetText(string.format("Frequency Band: %s %s to %s %s", min, minUnit, max, maxUnit))
        panel:SetFont(font)
        panel:SizeToContents()

        local freq, unit = self:GetDisplayFrequency()
        if freq and freq != "0.0" and unit then
            panel = tooltip:AddRowAfter("description", "freq")
            panel:SetText("Tuned Frequency: " .. string.format("%.1f", freq) .. " " .. unit)
            panel:SetFont(font)
            panel:SizeToContents()
        end
    end
end

function ITEM:GetFrequency()
    return self:GetData("frequency", nil)
end

function ITEM:GetDisplayFrequency()
    return ix.radio.ConvertUnit(self:GetFrequency())
end

function ITEM:IsEnabled()
    return self:GetData("enabled", false)
end

function ITEM:GetFrequencyBand()
    local min, minUnit = ix.radio.ConvertUnit(self.frequencyBand["min"])
    local max, maxUnit = ix.radio.ConvertUnit(self.frequencyBand["max"])
    return min, max, minUnit, maxUnit
end

-- update frequency + frequency unit on change
function ITEM:SetFrequency(frequency)
    local min, max, minUnit, maxUnit = self:GetFrequencyBand()
    local frequency, unit = ix.radio.ConvertUnit(frequency)

    -- block frequencies for radio stations; this is NOT blocked for stationary radios, as somebody may be a DJ for their station or something
    if ix.radio.stations.FindByFrequency(frequency) then
        return string.format("%s %s is reserved by a radio station!", frequency, unit)
    end

    local compareFreq = tonumber(frequency)

    if compareFreq > tonumber(max) or compareFreq < tonumber(min) then
        return string.format("%s %s is outside of the device's operating frequency band of %s %s to %s %s.", frequency, unit, min, minUnit, max, maxUnit)
    else
        self:SetData("frequency", frequency)
        return string.format("You have set your radio frequency to %s %s.", frequency, unit)
    end
end

function ITEM:GetEnableSound()
    if self.enableSound then
        if istable(self.enableSound) then
            return self.enableSound[math.random(1, #self.enableSound)]
        else
            return self.enableSound
        end
    end
end

function ITEM:GetDisableSound()
    if self.disableSound then
        if istable(self.disableSound) then
            return self.disableSound[math.random(1, #self.disableSound)]
        else
            return self.disableSound
        end
    end
end

function ITEM:GetReceiveSound()
    if self.receiveSound then
        if istable(self.receiveSound) then
            return self.receiveSound[math.random(1, #self.receiveSound)]
        else
            return self.receiveSound
        end
    end
end

function ITEM:GetTransmitPower()
    return self.transmitPower or 1.0
end

function ITEM:OnTransferred(curInv, newInv)
    self:SetData("enabled", false)
end

ITEM:Hook("drop", function(item)
    item:SetData("enabled", false)
end)

ITEM.functions.Frequency = {
    name = "Set Frequency",
    icon = "icon16/cog_edit.png",
    OnRun = function(item)
        local client = item.player
        local default = item:GetFrequency() or item.frequencyBand["min"]
        local en = item:IsEnabled()
        
        client:RequestString("Frequency (MHz)", "What would you like to set the frequency to?", function(frequency)
            if tonumber(frequency) then
                client.frequencies[default] = nil
                
                frequency = string.format("%.1f", tonumber(frequency))
                client:Notify(item:SetFrequency(frequency))

                if en then
                    client.frequencies[frequency] = item
                end

                ix.radio.FrequencySync(client)
            else
                client:Notify(string.format("%s is an invalid frequency.", frequency))
            end
        end, item:GetData("frequency", string.format("%.1f", tonumber(default))))

        return false
    end
}

ITEM.functions.Toggle = {
    name = "Toggle",
    icon = "icon16/ipod_cast.png",
    OnRun = function(item)
        local client = item.player
        local character = client:GetCharacter()
        local bState = item:IsEnabled()
        local bCanToggle = true

        for _, v in pairs(character:GetInventory():GetItems()) do
            if v.isRadio then
                if !bState and v:IsEnabled() then
                    bCanToggle = false
                    break
                end
            end
        end

        if (bCanToggle) then
            local freq = item:GetFrequency()
            item:SetData("enabled", !item:GetData("enabled", false))
            if bState then
                local snd = item:GetDisableSound()
                if snd then
                    client:EmitSound(snd)
                end

                if freq then
                    client.frequencies[freq] = nil
                end
            else
                local snd = item:GetEnableSound()
                if snd then
                    client:EmitSound(snd)
                end

                if freq then
                    client.frequencies[freq] = item
                end
            end

            ix.radio.FrequencySync(client)
        else
            client:NotifyLocalized("radioAlreadyOn")
        end

        return false
    end,
    OnCanRun = function(item)
        local client = item.player
        return !IsValid(item.entity) and IsValid(client) and hook.Run("CanPlayerEquipItem", client, item) != false
    end
}
