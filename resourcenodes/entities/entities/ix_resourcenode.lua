
local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Resource Node"
ENT.Category = "Helix - Resource Nodes"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "NodeID")
	self:NetworkVar("Bool", 0, "CanHarvest")

	if (SERVER) then
		self:NetworkVarNotify("NodeID", self.OnVarChanged)
	end
end

if (SERVER) then
	function ENT:Initialize()
		if (!self.uniqueID) then
			self:Remove()

			return
		end

		self:SetNodeID(self.uniqueID)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		self:SetCanHarvest(false)
		self:SetHarvestDelay()
		self.secondsPassed = 0

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	function ENT:OnVarChanged(name, oldID, newID)
		local rNode = ix.resourcenodes.stored[newID]

		if (rNode) then
			self:SetModel(rNode:GetModel())
		end
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_PVS
	end

	-- think every second
	function ENT:Think()
		if !self:GetCanHarvest() then
			if self.secondsPassed >= self.minSeconds then
				self:Fill()
			else
				self.secondsPassed = self.secondsPassed + 1
			end
		else
			self.secondsPassed = 0
		end
		self:NextThink( CurTime() + 1 )
		return true
	end
	
else
	ENT.PopulateEntityInfo = true

	function ENT:OnPopulateEntityInfo(tooltip)
		local rNode = self:GetResNode()

		if (rNode) then
			PLUGIN:PopulateResNodeTooltip(tooltip, rNode, self:GetCanHarvest())
		end
	end

	function ENT:Draw()
		self:DrawModel()
	end
end

function ENT:GetResNode()
	return ix.resourcenodes.stored[self:GetNodeID()]
end

function ENT:SetHarvestDelay()
	local rNode = self:GetResNode()
	if istable(rNode.replenishTime) then
		self.minSeconds = math.random(rNode.replenishTime["min"], rNode.replenishTime["max"])
	else
		self.minSeconds = rNode.replenishTime
	end
end

function ENT:Fill()
	self:SetCanHarvest(true)
	self:GetResNode():OnFilled()
	self:SetHarvestDelay()
	self.secondsPassed = 0
end

function ENT:Use(activator)
	local rNode = self:GetResNode()
	local inv = activator:GetCharacter():GetInventory()

	if rNode.requiredTool then
		if rNode:HasTool(inv) and self:GetCanHarvest() then
			self:Harvest(rNode, activator, inv)
		elseif !rNode:HasTool(inv) then
			local item = ix.item.Get(rNode.requiredTool)
			local toolName = (item and item.name) or "ERR: INVALID ITEM"
			activator:Notify("You need a " .. toolName .. " to harvest this resource.")
		else
			activator:Notify("This " .. rNode.name .. " currently has no resources to harvest.")
		end
	else
		if self:GetCanHarvest() then
			self:Harvest(rNode, activator, inv)
		else
			activator:Notify("This " .. rNode.name .. " currently has no resources to harvest.")
		end
	end
end

function ENT:Harvest(rNode, activator, inv)
	local char = activator:GetCharacter()
	if !rNode.profession or char:HasNodeProfession(rNode.profession) then

		-- play the progress sound once per second if needed
		if rNode.harvestProgressSound and rNode.harvestTime > 1 then
			local repeats = rNode.harvestTime
			if rNode.harvestFinishedSound then -- ensures no overlap with the harvest sound
				repeats = repeats - 1
			end

			-- play once at start
			activator:EmitSound(rNode:GetHarvestProgressSound())
			timer.Create("ixResourceNodeTimer", 1, repeats, function()
				activator:EmitSound(rNode:GetHarvestProgressSound())
			end)
		end

		-- actually run the harvest and related end effects
		activator:SetAction(rNode.harvestText, rNode.harvestTime, function()
			local harvestedItem, harvestedAmount = rNode:GetOutput()

			-- determines the amount to give and it adds it if the harvest was successful
			local item = ix.item.Get(harvestedItem)
			if item then
				harvestedAmount = rNode:ModifyHarvestAmount(activator, harvestedAmount) -- swap the amount around based on any custom conditions per node type

				if harvestedAmount > 0 then -- 0 is considered a failed harvest
					if item.stackable or string.find(item.base, "stackable") then
						if harvestedAmount < item.maxStacks then
							if (!inv:Add(harvestedItem, 1, {stacks = harvestedAmount})) then
								ix.item.Spawn(harvestedItem, activator, nil, nil, {stacks = harvestedAmount})
							end
						else
							if (!inv:Add(harvestedItem, 1, {stacks = item.maxStacks})) then
								ix.item.Spawn(harvestedItem, activator, nil, nil, {stacks = item.maxStacks})
							end
							if (!inv:Add(harvestedItem, 1, {stacks = (harvestedAmount - item.maxStacks)})) then
								ix.item.Spawn(harvestedItem, activator, nil, nil, {stacks = (harvestedAmount - item.maxStacks)})
							end
						end
					else
						if (!inv:Add(harvestedItem, harvestedAmount)) then
							for i = 1, harvestedAmount do
								ix.item.Spawn(harvestedItem, activator)
							end
						end
					end

					activator:Notify("You have harvested " .. harvestedAmount .. " " .. item.name .. ".")
					rNode:OnSuccessfulHarvest(activator)
				else
					activator:Notify("You have failed to harvest anything useful from this " .. rNode.name .. ".")
				end

				self:SetCanHarvest(false)
				activator:EmitSound(rNode:GetHarvestFinishedSound())
				rNode:OnEmptied()
			end
		end)
	elseif !char:HasNodeProfession(rNode.profession) then
		activator:Notify("You do not have the " .. rNode.profession .. " profession needed to harvest resources from this " .. rNode.name .. ".")
	end
end