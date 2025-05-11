AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
 
include("shared.lua")

local PLUGIN = PLUGIN

function ENT:Initialize()

	self:SetModel("models/props_phx2/garbage_metalcan001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:StartMotionController()
	-- self:SetUseType(SIMPLE_USE)
	
	local phys = self:GetPhysicsObject()
	
	if phys:IsValid() then
		phys:SetMass(200)
		phys:SetDamping(0,100)
		phys:Wake()
	end

	self.ixInArea = false
	self.ixAreas = {}

	if ix.area then
		self.useBiomes = ix.config.Get("useBiomeZones", false)
	else
		self.useBiomes = false
	end
	
	self.canCatch = math.random() < (ix.config.Get("catchChance", 80) / 100) -- if this is false, the cast will never catch anything
	self.passedFrames = 0

	if self.canCatch then
		self.fishCaught = false
		self.soundPlayed = false
		self.minFramesToCatch = math.random(5, 120) -- 5/6 frames per second
		self.minFramesToEscape = self.minFramesToCatch + math.random(20, 30)
	end

	self.WaterChecker = 0
end

function ENT:Think()

	if (self.WaterChecker >= 100) then
		self.rod:ResetStage()
	end

	if (!self:GetOwner()) or (!IsValid(self:GetOwner())) then
		self:Remove()
	end

	if (self:GetOwner()) and (IsValid(self:GetOwner())) and (self:GetOwner():GetActiveWeapon():GetClass() != "weapon_fishingrod") then
		self:Remove()
	end

	-- runs the wait calculation
	if self.canCatch and (!self.useBiomes or (self.useBiomes and self:IsInArea())) then
		if self.passedFrames == self.minFramesToCatch then
			self.fishCaught = true

			if !self.soundPlayed then
				self:GetOwner():EmitSound("ambient/water/water_splash1.wav", 75, 100, 1)
				self.soundPlayed = true

				local data = EffectData()
				data:SetOrigin(self:GetPos())
				data:SetScale(4)
				util.Effect("WaterSplash", data)
			end

		elseif self.passedFrames == self.minFramesToEscape then
			self:GetOwner():Notify("The hooked fish escaped!")
			self.rod:ResetStage()
		end

	else
		if self.passedFrames == 120 then
			self:GetOwner():Notify("No fish took the bait.")
			self.rod:ResetStage()
		end
	end

	if (math.random() > 0.99) then
		if (self:GetOwner()) and (IsValid(self:GetOwner())) and (self:GetOwner():GetActiveWeapon():GetClass() == "weapon_fishingrod") then
			if (self.fishCaught) then
				self:GetOwner():GetActiveWeapon():SetRStr(math.random(5,15) * 10)
			else
				self:GetOwner():GetActiveWeapon():SetRStr(50)
			end
		end
	end

	self.passedFrames = self.passedFrames + 1

end

function ENT:Catch()

	if (!self:GetOwner()) or (!IsValid(self:GetOwner())) or (self:GetOwner():GetActiveWeapon():GetClass() != "weapon_fishingrod") then
		return false
	end

	local CatchChance = math.random()
	local PossibleFishes = {}

	local ValidFish = {}

	if self.useBiomes then
		if self:IsInArea() then -- in theory a catch should never fire outside of a zone, but better to check anyways
			for _, biome in ipairs(self:GetAreas()) do
				local biomeFish = PLUGIN:GetFishByBiome(biome)
				for k, v in ipairs(biomeFish) do
					table.insert(ValidFish, v)
				end
			end
		end
	else
		ValidFish = PLUGIN.fish
	end

	for k,v in ipairs(ValidFish) do
		if (v.FChance >= CatchChance) then
			PossibleFishes[#PossibleFishes+1] = "fish_" .. v.FId
		end
	end
	
	if (table.IsEmpty(PossibleFishes)) then
		self:GetOwner():Notify("The hooked fish escaped!") -- weightings can still make it so no fish is caught so uhhh just lie to the player i guess
	else
		local randomFish = PossibleFishes[ math.random( #PossibleFishes ) ]
		self:GetOwner():Notify("You've caught something!")

		local char = self:GetOwner():GetCharacter()
		local inv = char:GetInventory()

		if (!inv:Add(randomFish)) then
	        ix.item.Spawn(randomFish, self:GetOwner())
	    end
	end
end

function ENT:Yank( force )
	force = force or math.random( 50, 100 )
	self:GetPhysicsObject():AddVelocity( Vector( 0, 0, -force ) )
	self:EmitSound( "ambient/water/water_splash"..math.random(1,3)..".wav", 100, 255 )
	local data = EffectData()
	data:SetOrigin(self:GetPos())
	data:SetScale(force*0.01)
	util.Effect("WaterSplash", data)
end

function ENT:PhysicsSimulate(phys)
	local data = {}
	
	data.start = self:GetPos()
	data.endpos = self:GetPos()+Vector(0,0,((self.Fish and 0) or 5))
	data.filter = self
	data.mask = CONTENTS_WATER
	
	local trace = util.TraceLine(data)
	
	local invert_fraction = (trace.Fraction * -1 + 1)
	
	phys:SetDamping(invert_fraction*20, 100)
	phys:AddVelocity(Vector(0,0,20) * invert_fraction)
	-- self:AlignAngles(self:GetAngles(),Angle(0,0,0))
	if (trace.Hit) then
		if (math.abs(self:GetAngles().p) > 5) or (math.abs(self:GetAngles().r) > 5) then
			self:SetAngles(Angle(0,0,0))
		end
		self.WaterChecker = 0
	else
		self.WaterChecker = self.WaterChecker + 1
	end
	
	if (trace.Hit) and (math.random() > 0.99) then
		self:SetAngles(Angle(0,0,0))
		local data = EffectData()
		data:SetOrigin(trace.HitPos)
		data:SetScale(2)
		util.Effect("WaterRipple", data)
	end
end

function ENT:SetRod(weapon)
	self.rod = weapon
end

function ENT:GetAreas()
	return self.ixAreas
end

function ENT:IsInArea()
	return self.ixInArea
end

function ENT:HasArea(area)
	for _, v in ipairs(self.ixAreas) do
		if v == area then
			return true
		end
	end
	return false
end