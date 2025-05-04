
local PLUGIN = PLUGIN
ix.meta = ix.meta or {}

local RESNODE = ix.meta.resnode or {}
RESNODE.__index = RESNODE
RESNODE.plugin = PLUGIN
RESNODE.name = "undefined" 				-- name used in the entity spawn list
RESNODE.fullName = "undefined" 			-- the tooltip name used when the node has a harvest
RESNODE.emptyName = "undefined" 		-- the tooltip name used when the node is depleted
RESNODE.harvestText = "Harvesting..."	-- text that appears above the action bar while harvesting
RESNODE.description = "undefined"		-- description text shown on tooltip
RESNODE.uniqueID = "undefined"			-- automatically set when read from directory

RESNODE.profession = nil				-- (OPTIONAL) required profession to harvest the node. see CHAR:HasNodeProfession() to update the call as needed for whatever profession/trait system you use
RESNODE.requiredTool = nil 				-- (OPTIONAL) the item uniqueID a player needs to have in their inventory to harvest from the node

RESNODE.output = {}						-- should be a table of the form: {[uniqueID] = quantity, [uniqueID2] = quantity}, etc.
                                        -- note that quantity can also be a table; {["min"] = x, ["max"] = y}, and {x, y, z} are all valid entries for the amount.

RESNODE.harvestTime = 1 				-- how long it takes to harvest the node, in seconds
RESNODE.replenishTime = 60 				-- how many seconds it takes for a node to replenish after being harvested. can be a constant or a table of the form {["min"] = x, ["max"] = y}

RESNODE.harvestFinishedSound = nil 		-- (OPTIONAL) sound played after harvest has completed. can be a string path or an array of paths
RESNODE.harvestProgressSound = nil		-- (OPTIONAL) sound played as the node is harvested, once per second. can be a string path or an array of paths.


function RESNODE:GetName()
    return self.name
end

function RESNODE:GetModel()
    return self.model
end

-- picks a random item from the output table and then picks the needed quantity based on the item selected
function RESNODE:GetOutput()
    if table.IsEmpty(self.output) then return nil, 0 end

    local ids = {}
    for item, quantity in pairs(self.output) do
        table.insert(ids, item)
    end
    local outputItem = ids[math.random(1, #ids)]

    local quantity = self.output[outputItem]
    if quantity then
        if istable(quantity) then
            if quantity["min"] then
                return outputItem, math.random(quantity["min"], quantity["max"])
            else
                return outputItem, quantity[math.random(1, #quantity)]
            end
        else
            return outputItem, tonumber(quantity)
        end
    else
        return nil, 0
    end
end

-- called when the node is harvested, customizable
function RESNODE:OnSuccessfulHarvest(client)
end

-- allows the yield amount to be customized based on different parameters
function RESNODE:ModifyHarvestAmount(client, amount)
    return amount
end

-- do stuff like change the model when full or empty, etc
function RESNODE:OnFilled()
end
function RESNODE:OnEmptied()
end

-- called every second
function RESNODE:Think()
end

-- allows custom tool conditions, i.e. ANY axe instead of just 1 type
function RESNODE:HasTool(inv)
    if self.requiredTool then
        return inv:HasItem(self.requiredTool)
    else
        return true
    end
end

function RESNODE:GetHarvestFinishedSound()
    if self.harvestFinishedSound then
        if istable(self.harvestFinishedSound) then
            return self.harvestFinishedSound[math.random(1, #self.harvestFinishedSound)]
        else
            return self.harvestFinishedSound
        end
    end
    return nil
end

function RESNODE:GetHarvestProgressSound()
    if self.harvestProgressSound then
        if istable(self.harvestProgressSound) then
            return self.harvestProgressSound[math.random(1, #self.harvestProgressSound)]
        else
            return self.harvestProgressSound
        end
    end
    return nil
end

ix.meta.resnode = RESNODE