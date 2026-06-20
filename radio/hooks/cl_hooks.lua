
local PLUGIN = PLUGIN

-- wipes all frequency tracking from stationary radio ents when the player loads a new character
function PLUGIN:CharacterLoaded(character)
	for _, radio in ipairs(ents.FindByClass("ix_radio_*")) do
        radio.canCurrentlyHear = nil
    end
end

-- integration with my ambient music plugin to block ambient tracks when listening to the radio
function PLUGIN:CanPlayAmbientMusic(client)
    if client.radioStations and next(client.radioStations) != nil then
        return false
    end
end