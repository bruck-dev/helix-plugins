
ix.meta = ix.meta or {}

local RADIO = ix.meta.stationaryRadio or {}
RADIO.__index = RADIO
RADIO.name = "undefined"
RADIO.description = "undefined"
RADIO.model = "models/props/cs_office/radio.mdl"
RADIO.uniqueID = "undefined"

RADIO.twoWay = false            -- whether or not the radio can receive AND send messages. if false, can only receive
RADIO.canGarble = true          -- whether or not the radio's transmitted messages can ever be garbled. useful if you want broadcast-style radios that cannot garble, ever
RADIO.transmitPower = 1.0       -- if it can garble, transmitPower is a multiplier after normal range math is done. 1.0 implies no modification, whereas 1.2 would be a 20% boost and 0.8 would be a 20% malus
RADIO.enableStations = true     -- whether or not this radio will play music when tuned to a radio station frequency

RADIO.enableSound = nil         -- can be a string or a list of strings
RADIO.disableSound = nil
RADIO.receiveSound = nil

-- standard american FM band. determines frequency bounds.
RADIO.frequencyBand = {
    ["min"] = 88.0,
    ["max"] = 108.0,
}

function RADIO:GetName()
	return self.name
end

function RADIO:GetModel()
	return self.model
end

function RADIO:GetEnableSound()
    if self.enableSound then
        if istable(self.enableSound) then
            return self.enableSound[math.random(1, #self.enableSound)]
        else
            return self.enableSound
        end
    end
end

function RADIO:GetDisableSound()
    if self.disableSound then
        if istable(self.disableSound) then
            return self.disableSound[math.random(1, #self.disableSound)]
        else
            return self.disableSound
        end
    end
end

function RADIO:GetReceiveSound()
    if self.receiveSound then
        if istable(self.receiveSound) then
            return self.receiveSound[math.random(1, #self.receiveSound)]
        else
            return self.receiveSound
        end
    end
end

if CLIENT then
    -- determines extra drawn features on the model, i.e setting a sprite to red or green when the radio is on/off. see the examples
    function RADIO:Paint(entity)
    end
end

ix.meta.stationaryRadio = RADIO
