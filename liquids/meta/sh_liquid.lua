
ix.meta = ix.meta or {}

local LIQUID = ix.meta.liquid or {}
LIQUID.__index = LIQUID
LIQUID.name = "undefined"
LIQUID.uniqueID = "undefined"
LIQUID.edible = true
LIQUID.consumeSound = {"ambient/levels/canals/toxic_slime_gurgle2.wav", "ambient/levels/canals/toxic_slime_gurgle4.wav"}
LIQUID.transferSound = {"ambient/water/water_spray1.wav", "ambient/water/water_spray2.wav", "ambient/water/water_spray3.wav"}
LIQUID.color = nil -- color of the bar to show how full the holding container is
LIQUID.weight = 0.001 -- water density is 1g/mL, ---> 0.001kG/mL since the weight addon is based on kilograms

function LIQUID:GetName()
	return self.name
end

function LIQUID:GetDescription()
	return self.description
end

function LIQUID:GetConsumeSound()
	if istable(self.consumeSound) then
		return self.consumeSound[math.random(1, #self.consumeSound)]
	else
		return self.consumeSound
	end
end

function LIQUID:GetTransferSound()
	if istable(self.transferSound) then
		return self.transferSound[math.random(1, #self.transferSound)]
	else
		return self.transferSound
	end
end

function LIQUID:GetColor()
	return self.color or ix.config.Get("color", Color(255, 255, 255, 255))
end

function LIQUID:OnConsume(client, volume)
	return -- overwrite this in your liquid declaration
end

function LIQUID:CanConsume()
	return self.edible
end

function LIQUID:GetWeight()
	return self.weight
end

function LIQUID:Register()
	return -- reserved
end

ix.meta.liquid = LIQUID
