ITEM.name = "Radio Base"
ITEM.model = "models/props_lab/citizenradio.mdl"
ITEM.description = "A base for radio items."
ITEM.category = "Communication"
ITEM.width = 1
ITEM.height = 1

ITEM.isRadio = true
ITEM.twoWay = true
ITEM.canGarble = true

ITEM.enableSound = nil      -- can be a string or a list of strings
ITEM.disableSound = nil
ITEM.receiveSound = nil

local function convertUnit(freq)
    if isstring(freq) then
        freq = tonumber(freq)
    end
    freq = tonumber(string.format("%.2f", freq))

    -- no need to convert if we're already in the MHz range
    if freq >= 1 and freq < 1000 then
        return string.format("%.2f", freq), "MHz"
    end

    freq = freq * 1000000000 -- normalize to GHz; we ALWAYS divide once, so this makes room for the first division
    local units = {
        "Hz",
		"kHz",
		"MHz",
		"GHz",
		"THz",
    }

	local i = 0
	while freq >= 1000 do
		freq = freq / 1000
		i = i + 1
	end

    return string.format("%.2f", freq), (units[i] or "undefined")
end

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
        local freq, unit = item:GetFrequency()
        if freq and unit then
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
        
        local min, max, minUnit, maxUnit = self:GetValidFrequencyBand()
        panel:SetText(string.format("Frequency Band: %s %s to %s %s", min, minUnit, max, maxUnit))
        panel:SetFont(font)
        panel:SizeToContents()

        local freq, unit = self:GetFrequency()
        if freq then
            panel = tooltip:AddRowAfter("description", "freq")
            panel:SetText("Frequency Tuning: " .. string.format("%.2f", freq) .. " " .. unit)
            panel:SetFont(font)
            panel:SizeToContents()
        end
    end
end

-- set up base frequency band values, cache. these are currently constant but in the future may be able to be updated
function ITEM:OnInstanced(invID, x, y)
    local min, minUnit = convertUnit(self.frequencyBand["min"])
    local max, maxUnit = convertUnit(self.frequencyBand["max"])

    self:SetData("min", string.format("%.2f", min))
    self:SetData("max", string.format("%.2f", max))
    self:SetData("minUnit", minUnit)
    self:SetData("maxUnit", maxUnit)
end

function ITEM:GetFrequency()
    return self:GetData("frequency", nil), self:GetData("frequencyUnit", "MHz")
end

function ITEM:IsEnabled()
    return self:GetData("enabled", false)
end

function ITEM:GetValidFrequencyBand()
    return self:GetData("min", string.format("%.2f", self.frequencyBand["min"])), self:GetData("max", string.format("%.2f", self.frequencyBand["max"])), self:GetData("minUnit", "MHz"), self:GetData("maxUnit", "MHz")
end

-- update frequency + frequency unit on change
function ITEM:SetFrequency(frequency)
    local min, max, minUnit, maxUnit = self:GetValidFrequencyBand()
    local frequency, unit = convertUnit(frequency)

    -- block frequencies for radio stations; this is NOT blocked for stationary radios, as somebody may be a DJ for their station or something
    if ix.radio.stations.FindByFrequency(frequency) then
        return string.format("%s %s is reserved by a radio station!", frequency, unit)
    end

    local compareFreq = tonumber(frequency)

    if compareFreq > tonumber(max) or compareFreq < tonumber(min) then
        return string.format("%s %s is outside of the device's operating frequency band of %s %s to %s %s.", frequency, unit, min, minUnit, max, maxUnit)
    else
        self:SetData("frequency", frequency)
        self:SetData("frequencyUnit", unit)
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
                client.hearableFrequencies[default] = nil
                
                frequency = string.format("%.2f", tonumber(frequency))
                client:Notify(item:SetFrequency(frequency))

                if en then
                    client.hearableFrequencies[frequency] = true
                end
            else
                client:Notify(string.format("%s is an invalid frequency.", frequency))
            end
        end, item:GetData("frequency", string.format("%.2f", tonumber(default))))

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
                    client.hearableFrequencies[freq] = nil
                end
            else
                local snd = item:GetEnableSound()
                if snd then
                    client:EmitSound(snd)
                end

                if freq then
                    client.hearableFrequencies[freq] = true
                end
            end
        else
            client:NotifyLocalized("radioAlreadyOn")
        end

        return false
    end,
}
