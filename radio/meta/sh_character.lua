
local CHAR = ix.meta.character

-- scrolls through the player's listened frequencies and returns the necessary radio ITEM
function CHAR:GetRadioItem(frequency)
    if frequency then
        if isnumber(frequency) then
            frequency = string.format("%.1f", frequency)
        elseif tonumber(frequency) then
            frequency = string.format("%.1f", tonumber(frequency))
        end
    end

    for freq, radio in pairs(self:GetPlayer().frequencies or {}) do
        if !isentity(radio) and (!frequency or freq == frequency) then
            return radio
        end
    end
end

-- scrolls through the player's listened frequencies and returns the necessary radio ENTITY
function CHAR:GetRadioStationary(frequency)
    if frequency then
        if isnumber(frequency) then
            frequency = string.format("%.1f", frequency)
        elseif tonumber(frequency) then
            frequency = string.format("%.1f", tonumber(frequency))
        end
    end

    for freq, radio in pairs(self:GetPlayer().frequencies or {}) do
        if isentity(radio) and (!frequency or freq == frequency) then
            return radio
        end
    end
end

-- checks whether or not the target can listen on the specific passed frequency
function CHAR:GetActiveRadio(frequency)
    if !frequency then return nil end
    if isnumber(frequency) then
        frequency = string.format("%.1f", frequency)
    elseif tonumber(frequency) then
        frequency = string.format("%.1f", tonumber(frequency))
    end

    local client = self:GetPlayer()
    return client.frequencies and client.frequencies[frequency]
end

-- checks whether or not the target can listen on the specific passed frequency
function CHAR:CanHearFrequency(frequency)
    if !frequency then return false end
    if isnumber(frequency) then
        frequency = string.format("%.1f", frequency)
    elseif tonumber(frequency) then
        frequency = string.format("%.1f", tonumber(frequency))
    end

    local client = self:GetPlayer()
    return (client.frequencies and client.frequencies[frequency]) != nil
end

-- checks if the player has or is near an active two way radio and is able to use it
function CHAR:CanTalkOverRadio(message)
    if !ix.config.Get("enableRadio", true) then
        return false, "@radioDisabled"
    end

    if !self:GetPlayer():Alive() then
        return false, "@radioAlive"
    end

    local radio = self:GetRadioItem()
    if radio and radio:GetFrequency() then
        if !radio.twoWay then
            return false, "@radioTwoWay"
        elseif !self:GetPlayer():IsRestricted() then
            if message != '' then
                return true, nil, radio, radio.canGarble
            else
                return false, "@radioEmptyMessage"
            end
        else
            return false, "@notNow"
        end
    end

    radio = self:GetRadioStationary()
    if radio and radio:GetFrequency() and tonumber(radio:GetFrequency()) > 0 then
        if !radio.TwoWay then
            return false, "@radioStationaryTwoWay"
        elseif !self:GetPlayer():IsRestricted() then
            if message != '' then
                return true, nil, radio, radio.CanGarble
            else
                return false, "@radioEmptyMessage"
            end
        else
            return false, "@notNow"
        end
    end

    return false, "@radioRequired"
end