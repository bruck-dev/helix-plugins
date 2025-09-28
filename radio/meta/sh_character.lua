
local CHAR = ix.meta.character

-- returns whether or not the character has an enabled radio, optionally check if the enabled radio is the on the passed frequency
function CHAR:HasRadioEnabled(frequency)
    if isnumber(frequency) then
        frequency = string.format("%.2f", frequency)
    elseif tonumber(frequency) then
        frequency = string.format("%.2f", tonumber(frequency))
    end

    for k, _ in self:GetInventory():Iter() do
        if k.isRadio and k:IsEnabled() then
            if !frequency then
                return true, k
            else
                local freq = k:GetFrequency()
                if freq and freq == frequency then
                    return true, k
                end
            end
        end
    end
end

-- checks if the player is near an active radio and, if needed, if the frequency matches the passed value
function CHAR:NearStationaryRadio(frequency, radius)
    local client = self:GetPlayer()
    radius = radius or ix.config.Get("radioListenRange", 140)

    for _, radio in ipairs(ents.FindByClass("ix_radio_*")) do
        if radio:GetEnabled() and (client:GetPos():DistToSqr(radio:GetPos()) < radius * radius) then
            local radFreq = radio:GetFrequency()
            if !frequency or (frequency and radFreq and radFreq == frequency) then
                return true, radio
            end
        end
    end

    return false
end

-- checks whether or not the target can listen on the specific passed frequency
function CHAR:CanHearFrequency(frequency)
    if !frequency then return false end
    if isnumber(frequency) then
        frequency = string.format("%.2f", frequency)
    elseif tonumber(frequency) then
        frequency = string.format("%.2f", tonumber(frequency))
    end

    local en, radio = self:HasRadioEnabled(frequency)
    if en then
        return true, radio
    end

    en, radio = self:NearStationaryRadio(frequency)
    if en then
        return true, radio
    end

    return false
end
-- checks if the player has or is near an active two way radio and is able to use it
function CHAR:CanTalkOverRadio()
    if !ix.config.Get("enableRadio", true) then
        return false, "@radioDisabled"
    end

    if !self:GetPlayer():Alive() then
        return false, "@radioAlive"
    end

    local en, radio = self:HasRadioEnabled()

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

    local statEn, statRadio = self:NearStationaryRadio()

    if statRadio and statRadio:GetFrequency() and tonumber(statRadio:GetFrequency()) > 0 then
        if !statRadio.TwoWay then
            return false, "@radioStationaryTwoWay"
        elseif !self:GetPlayer():IsRestricted() then
            if message != '' then
                return true, nil, statRadio, statRadio.CanGarble
            else
                return false, "@radioEmptyMessage"
            end
        else
            return false, "@notNow"
        end
    end

    return false, "@radioRequired"
end