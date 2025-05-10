AddCSLuaFile()

local PLUGIN = PLUGIN

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Loot Container"
ENT.Author = "bruck, Riggs"
ENT.Category = "Helix - Loot Containers"

ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ContainerClass")
end

if SERVER then
    function ENT:Initialize()
        self:SetModel("models/hunter/blocks/cube075x1x075.mdl")
        self:PhysicsInit(SOLID_VPHYSICS) 
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    
        local phys = self:GetPhysicsObject()
        if ( phys:IsValid() ) then
            phys:Wake()
            phys:EnableMotion(false)
        end
    end

    function ENT:SpawnFunction(client, trace)
        local angles = client:GetAngles()

        local entity = ents.Create("ix_loot_container")
        entity:SetPos(trace.HitPos)
        entity:SetAngles(Angle(0, (entity:GetPos() - client:GetPos()):Angle().y - 180, 0))
        entity:Spawn()
        entity:Activate()
        
        PLUGIN:SaveData()

        return entity
    end

    function ENT:OnRemove()
        if timer.Exists("ixLootSearch."..self:EntIndex()) then
            timer.Remove("ixLootSearch."..self:EntIndex())
        end

        if timer.Exists("ixLootSound."..self:EntIndex()) then
            timer.Remove("ixLootSound."..self:EntIndex())
        end
    end

    function ENT:GetLootActionSound()
        local loot = ix.loot.containers[self:GetContainerClass()]

        if loot.lootActionSound then
            if istable(loot.lootActionSound) then
                return loot.lootActionSound[math.random(1, #loot.lootActionSound)]
            else
                return loot.lootActionSound
            end
        else
            return nil
        end
    end
    function ENT:GetLootFinishSound()
        local loot = ix.loot.containers[self:GetContainerClass()]

        if loot.lootFinishSound then
            if istable(loot.lootFinishSound) then
                return loot.lootFinishSound[math.random(1, #loot.lootFinishSound)]
            else
                return loot.lootFinishSound
            end
        else
            return nil
        end
    end

    -- replace the entity with an identical prop
    function ENT:ReplaceWithProp()
        local newProp = ents.Create("prop_physics")
        newProp:SetPos(self:GetPos())
        newProp:SetAngles(self:GetAngles())
        newProp:SetModel(self:GetModel())
        newProp:SetSkin(self:GetSkin())

        -- just useful to check these in case it's decoratively placed or something
        local isFrozen = !self:GetPhysicsObject():IsMotionEnabled()
        local isNoCollided = !self:GetPhysicsObject():IsCollisionEnabled()

        self:Remove()
        newProp:Spawn()

        if isFrozen then
            newProp:GetPhysicsObject():EnableMotion(false)
        end
        if isNoCollided then
            newProp:GetPhysicsObject():EnableCollisions(false)
        end
    end
    
    function ENT:Use(client, call)
        local char = client:GetCharacter()
        local inv = char:GetInventory()
        local loot = ix.loot.containers[self:GetContainerClass()]

        if !loot then return end

        if loot.tool and !inv:HasItem(loot.tool) then
            local tool = ix.item.Get(loot.tool)
            if tool then
                tool = tool:GetName()
            else
                tool = loot.tool
            end

            client:Notify("You do not have the " .. tool .. " needed to open this container!")
            return
        end

        local playersWhoHaveLooted = self.lootedBy or {}
        if loot.oncePerCharacter and !table.IsEmpty(playersWhoHaveLooted) then
            if playersWhoHaveLooted[char:GetID()] then
                client:Notify("You have already looted this " .. loot.name .. "!")
                return
            end
        end

        if !timer.Exists("ixLootSearch."..self:EntIndex()) then
            local lootTime = loot.lootTime

            if istable(lootTime) then
                if lootTime["min"] then
                    lootTime = math.random(lootTime["min"], lootTime["max"])
                else
                    lootTime = lootTime[math.random(1, #lootTime)]
                end
            end
            lootTime = math.Round(lootTime)

            if loot.onStart then
                loot.onStart(client, self)
            end

            -- play the progress sound once per second if needed
            if loot.lootActionSound and lootTime > 1 then
                local repeats = lootTime
                if loot.lootFinishSound then -- ensures no overlap with the finisher sound
                    repeats = repeats - 1
                end

                -- play once at start
                client:EmitSound(self:GetLootActionSound())
                timer.Create("ixLootSound."..self:EntIndex(), 1, repeats, function()
                    client:EmitSound(self:GetLootActionSound())
                end)
            end

            local actionText = loot.actionText or "Looting..."
            client:SetAction(actionText, lootTime)
            client:DoStaredAction(self, function()
                if !(IsValid(client) or client:Alive()) then return end

                -- creates a list of possible item IDs for the container
                local possibleItems = {}
                for uniqueID, lootTable in pairs(loot.items) do
                    if lootTable.chance and (math.random() < lootTable.chance) then
                        table.insert(possibleItems, uniqueID)
                    elseif !lootTable.chance then
                        table.insert(possibleItems, uniqueID)
                    end
                end

                -- determines how many items should be spawned on this search
                local lootCount = loot.lootCount
                if istable(lootCount) then
                    if lootCount["min"] then
                        lootCount = math.random(lootCount["min"], lootCount["max"])
                    else
                        lootCount = lootCount[math.random(1, #lootCount)]
                    end
                end

                -- if any items are possible, spawn them for the player with the necessary data and quantity. otherwise, tell them they found nothing
                if !table.IsEmpty(possibleItems) then
                    local looted = {}
                    for i = 1, lootCount do
                        -- in case there are no more lootable items due to maxLooted checks
                        if #possibleItems == 0 then
                            break
                        end

                        local id = possibleItems[math.random(1, #possibleItems)]
                        if id then
                            local amount = loot.items[id].amount
                            local data = loot.items[id].data or {}

                            if istable(amount) then
                                if amount["min"] then
                                    amount = math.random(amount["min"], amount["max"])
                                else
                                    amount = amount[math.random(1, #amount)]
                                end
                            end

                            if id == "money" then
                                target:GiveMoney(amount)

                                local currencyName
                                if amount == 1 then
                                    currencyName = ix.currency.singular
                                else
                                    currencyName = ix.currency.plural
                                end

                                client:Notify("You have found: " .. amount .. " " .. currencyName .. ".")
                            else
                                local item = ix.item.Get(id)
                                if item.stackable or string.find(item.base, "stackable") then
                                    data["stacks"] = amount
                                    if (!inv:Add(id, 1, data)) then
                                        ix.item.Spawn(id, client, nil, nil, data)
                                    end
                                elseif item.base == "base_currency" then
                                    data["money"] = amount
                                    if (!inv:Add(id, 1, data)) then
                                        ix.item.Spawn(id, client, nil, nil, data)
                                    end
                                else
                                    if !inv:Add(id, amount, data) then
                                        ix.item.Spawn(id, client, nil, nil, data)
                                    end
                                end

                                client:Notify("You have found: " .. amount .. " " .. item.name .. ".")

                                -- check if the last looted item has a maxLooted parameter, and remove it from the possible offerings if it does and we've reached it
                                looted[id] = (looted[id] or 0) + 1
                                if loot.items[id].maxLooted and loot.items[id].maxLooted == looted[id] then
                                    for j, v in ipairs(possibleItems) do
                                        if v == id then
                                            table.remove(possibleItems, j)
                                            break
                                        end
                                    end
                                end

                            end
                        end
                    end
                else
                    client:Notify("You have found nothing inside of the " .. loot.name .. ".")
                end

                if loot.onEnd then
                    loot.onEnd(client, self)
                end

                if loot.lootFinishSound then
                    client:EmitSound(self:GetLootFinishSound())
                end

                if loot.oncePerCharacter then
                    playersWhoHaveLooted[char:GetID()] = true
                    self.lootedBy = playersWhoHaveLooted
                end

                if loot.maxUses and loot.maxUses > 0 then
                    local timesUsed = (self.timesUsed or 0) + 1
                    if timesUsed == loot.maxUses then
                        self:ReplaceWithProp()
                    end
                end

            end, lootTime, function()
                if ( IsValid(client) ) then
                    client:SetAction()

                    if ( IsValid(self) ) then
                        timer.Remove("ixLootSearch."..self:EntIndex())

                        if timer.Exists("ixLootSound."..self:EntIndex()) then
                            timer.Remove("ixLootSound."..self:EntIndex())
                        end

                        if loot.onCancel then
                            loot.onCancel(client, self)
                        end
                    end
                end
            end)

            if !loot.oncePerCharacter then
                timer.Create("ixLootSearch."..self:EntIndex(), loot.delay, 1, function()
                end)
            end
        else
            client:Notify("You must wait ".. string.NiceTime(timer.TimeLeft("ixLootSearch."..self:EntIndex())) .." before you can search this " .. loot.name .. " again.")
        end
    end
else
    ENT.PopulateEntityInfo = true

    function ENT:OnPopulateEntityInfo(tooltip)
        local loot = ix.loot.containers[self:GetContainerClass()]

        if loot and !loot.hideTooltip then
            local name = tooltip:AddRow("name")
            name:SetImportant()
            name:SetText(loot.name)
            name:SizeToContents()

            local description = tooltip:AddRow("description")
            description:SetText(loot.description)
            description:SizeToContents()
        end
    end
end