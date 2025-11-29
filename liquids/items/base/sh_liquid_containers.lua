
ITEM.name = "Liquid Container"
ITEM.model = "models/props_junk/garbage_glassbottle001a.mdl"
ITEM.width	= 1
ITEM.height	= 1
ITEM.description = "Liquid Container base."
ITEM.category = "Containers"
ITEM.liquid = nil                               -- default to being empty
ITEM.capacity = 500                             -- max capacity of the container, in mL
ITEM.startingVolume = nil                       -- starting volume of the specified liquid. can be an int, or a table of the two forms {["min"] = x, ["max"] = y} or {x, y, z}. ignored if empty, defaults to ITEM.capacity if nil
ITEM.emptyContainer = nil                       -- item uniqueID that the container should become upon being empty. generally, only use this for bottles of things you want to start filled - say, beer you want to become a beer bottle.

if (CLIENT) then
    function ITEM:PaintOver(item, w, h)
        local amount = item:GetVolume()

        if amount >= 0 then
            local liquid = ix.liquids.Get(item:GetLiquid())
            surface.SetDrawColor(35, 35, 35, 225)
            surface.DrawRect(2, h-9, w-4, 7)

            local filledWidth = (w-5) * (amount / item.capacity)
            
            local color = ix.config.Get("color")
            if liquid and ix.option.Get("useLiquidColor", true) then
                color = liquid:GetColor()
            end

            surface.SetDrawColor(color)
            surface.DrawRect(3, h-8, filledWidth, 5)
        end
    end
end

function ITEM:PopulateTooltip(tooltip)
    local data = tooltip:AddRow("data")
    local vol = self:GetVolume()

    if(vol <= 0) then
        data:SetText("\nCapacity: " .. ix.liquids.ConvertUnit(self.capacity) .. "\nEmpty")
    else 
        data:SetText("\nCapacity: " .. ix.liquids.ConvertUnit(self.capacity) .. "\n" ..
        "Current Amount: " .. ix.liquids.ConvertUnit(vol) .. "\n" ..
        "Contains " .. ix.liquids.Get(self:GetLiquid()):GetName())
    end

    data:SetFont("ixGenericFont")
    data:SizeToContents()
end

-- Called when a new instance of this item has been made.
function ITEM:OnInstanced(invID, x, y)
    if self:GetLiquid() and self:GetVolume() then
        do end
    elseif self.liquid then
        local liquid
        if ix.liquids.Get(self.liquid) then
            liquid = self.liquid
        elseif ix.liquids.FindByName(self.liquid) then
            liquid = ix.liquids.FindByName(self.liquid).uniqueID
        end

        if liquid then
            local cap = self.startingVolume or self.capacity
            if istable(cap) then
                if cap["min"] and cap["max"] then
                    cap = math.random(cap["min"], cap["max"])
                else
                    cap = cap[math.random(1, #cap)]
                end
            end

            self:SetVolume(cap)
            if cap > 0 then
                self:SetLiquid(liquid)
            end
        else
            self:SetVolume(0)
        end
    else
        self:SetVolume(0)
    end

    self:ConfigureModel()
end

-- i use this as a hook to set custom models using a random table, figured i'd throw it into the base
function ITEM:ConfigureModel()
    -- example implementation
    -- if !self:GetData("model", nil) then
    --     local models = {
    --         "models/props_junk/garbage_glassbottle003a.mdl",
    --         "models/props_junk/garbage_glassbottle001a.mdl",
    --     }

    --     self:SetData("model", models[math.random(1, #models)])
    -- end
    return
end

function ITEM:GetModel()
    return self:GetData("model", self.model)
end

function ITEM:GetVolume()
    return self:GetData("currentAmount", 0)
end

function ITEM:SetVolume(vol)
    if vol > self.capacity then
        self:SetData("currentAmount", self.capacity)
    elseif vol == 0 then
        if self.emptyContainer then
            self:SetData("replaceWithContainer", true)
            self:Remove()
        else
            self:SetData("currentAmount", 0)
            self:SetLiquid(nil)
        end
    else
        self:SetData("currentAmount", vol)
    end

    local client = self.player
    if (ix.weight and client) then
        client:GetCharacter():UpdateWeight()
    end
end

function ITEM:GetFreeVolume()
    local vol = self:GetVolume()
    if vol < self.capacity then
        return self.capacity - vol
    end

    return 0
end

function ITEM:GetLiquid()
    return self:GetData("currentLiquid", nil)
end

function ITEM:SetLiquid(liquid)
    self:SetData("currentLiquid", liquid)
end

function ITEM:HasLiquid(liquid)
    return ix.liquids.Get(liquid) and self:GetLiquid() == liquid
end

-- returns the weight of the container + weight of the held liquid (if any) in kilograms
function ITEM:GetWeight()
    local weight = self.weight or (self.capacity / 1000)
    if self:GetLiquid() then
        return weight + (self:GetVolume() * ix.liquids.Get(self:GetLiquid()):GetWeight())
    else
        return weight
    end
end

function ITEM:OnRemoved()
    if self.player and self:GetData("replaceWithContainer", false) and self.emptyContainer then
        local inv = self.player:GetCharacter():GetInventory()
        if !inv or (!inv:Add(self.emptyContainer, 1, nil, self.x, self.y)) then
            ix.item.Spawn(self.emptyContainer, client, nil, nil, nil)
        end
    end
end

ITEM.functions.ADrink = { -- consumes everything if below the max drinking volume, or the max drinking volume if greater
    name = "Drink",
    icon = "icon16/drink.png",
    OnRun = function(item)
        local client = item.player
        local vol = item:GetVolume()

        if(vol) then
            local volConsumed
            local maxDrink = ix.config.Get("maxDrinkingVolume", 150)
            if vol < maxDrink then
                volConsumed = vol
            else
                volConsumed = maxDrink
            end

            local liquid = ix.liquids.Get(item:GetLiquid())
            liquid:OnConsume(client, volConsumed)
            item:SetVolume(vol - volConsumed)

            client:EmitSound(liquid:GetConsumeSound())
        end
        
        return false
    end,
    OnCanRun = function(item)
        if item:GetVolume() <= 0 then
            return false
        end

        local liquid = ix.liquids.Get(item:GetLiquid())
        return liquid and liquid:CanConsume() and item.player
    end
}
ITEM.functions.BSip = { -- quarter of drinking volume, basically
    name = "Sip",
    icon = "icon16/cup.png",
    OnRun = function(item)
        local client = item.player
        local curVol = item:GetVolume()

        if curVol > 0 then

            local volConsumed = 0.25 * ix.config.Get("maxDrinkingVolume", 150)
            if volConsumed > curVol then
                volConsumed = curVol
            else
                volConsumed = math.ceil(volConsumed)
            end

            local liquid = ix.liquids.Get(item:GetLiquid())
            liquid:OnConsume(client, volConsumed)
            item:SetVolume(curVol - volConsumed)

            client:EmitSound(liquid:GetConsumeSound())
        end

        return false
    end,
    OnCanRun = function(item)
        if item:GetVolume() <= 0 then
            return false
        end

        local liquid = ix.liquids.Get(item:GetLiquid())
        return liquid and liquid:CanConsume() and item.player and (item.capacity <= ix.config.Get("maxDrinkingVolume", 150) * 5) -- by default, 750mL. standard wine/whiskey bottle volume
    end
}
ITEM.functions.CPour = {
    name = "Pour Out",
    icon = "icon16/paintcan.png",
    OnRun = function(item)
        local client = item.player

        local snd = ix.liquids.Get(item:GetLiquid()):GetTransferSound()
        if snd then
            client:EmitSound(snd)
        end
        item:SetVolume(0)

        return false
    end,
    OnCanRun = function(item)
        return item.player and item:GetVolume() > 0
    end
}
ITEM.functions.DFillFromSource = {
    name = "Fill from Container",
    icon = "icon16/basket_put.png",
    OnRun = function(item)
        local client = item.player

        local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 160
            data.filter = function(ent) return (ent:GetClass() == "ix_liquidsource") end
        local trace = util.TraceLine(data)

        local source = trace.Entity
        if !IsValid(source) then return false end

        local toFill = item:GetFreeVolume()
        local sourceVolume = source:GetCurVolume()

        if !item:GetLiquid() then
            item:SetLiquid(source:GetLiquid())
        end

        if source:GetIsInfinite() then
            item:SetVolume(item.capacity)
        else
            if toFill > sourceVolume then
                item:SetVolume(item:GetVolume() + sourceVolume)
                source:SetCurVolume(0)
            else
                item:SetVolume(item.capacity)
                source:SetCurVolume(sourceVolume - toFill)
            end
        end

        local snd = ix.liquids.Get(source:GetLiquid()):GetTransferSound()
        if snd then
            client:EmitSound(snd)
        end

        return false
    end,
    OnCanRun = function(item)
        if item:GetVolume() == item.capacity then
            return false
        end
        local client = item.player

        local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 160
            data.filter = function(ent) return (ent:GetClass() == "ix_liquidsource") end
        local trace = util.TraceLine(data)

        local ent = trace.Entity

        if !IsValid(ent) then return false end

        return ent:GetLiquid() and (ent:GetLiquid() == item:GetLiquid() or !item:GetLiquid()) and (ent:GetCurVolume() > 0 or ent:GetIsInfinite())
    end
}
ITEM.functions.EFillWater = {
    name = "Fill With Water",
    icon = "icon16/basket_put.png",
    OnRun = function(item)
        local snd = ix.liquids.Get("water") and ix.liquids.Get("water"):GetTransferSound()
        if snd then
            item.player:EmitSound(snd)
        end

        item:SetVolume(item.capacity)
        item:SetLiquid("water")

        return false
    end,
    OnCanRun = function(item)
        if !ix.config.Get("allowMapRefills", true) then return false end
        if !ix.liquids.Get("water") then return false end
        if !(item:GetVolume() == 0 or (item:GetLiquid() == "water" and item:GetVolume() < item.capacity)) then return false end
        return item.player and item.player:WaterLevel() >= 1
    end
}
ITEM.functions.DRefillSource = {
    name = "Refill Container",
    icon = "icon16/basket_remove.png",
    OnRun = function(item)
        local client = item.player

        local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 160
            data.filter = function(ent) return (ent:GetClass() == "ix_liquidsource") end
        local trace = util.TraceLine(data)

        local source = trace.Entity
        if !IsValid(source) then return false end

        local snd = ix.liquids.Get(item:GetLiquid()):GetTransferSound()
        if snd then
            client:EmitSound(snd)
        end

        local toGive = item:GetVolume()
        local sourceCur = source:GetCurVolume()
        local sourceMax = source:GetMaxVolume()

        local newVol = toGive + sourceCur
        if newVol > sourceMax then
            source:SetCurVolume(sourceMax)
            item:SetVolume(toGive - (sourceMax - sourceCur))
            return false
        else
            source:SetCurVolume(newVol)
            item:SetVolume(0)

            return false
        end
    end,
    OnCanRun = function(item)
        if item:GetVolume() == 0 then
            return false
        end
        local client = item.player

        local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 160
            data.filter = function(ent) return (ent:GetClass() == "ix_liquidsource") end
        local trace = util.TraceLine(data)

        local ent = trace.Entity

        if !IsValid(ent) then return false end

        return !ent:GetIsInfinite() and ent:GetLiquid() and (ent:GetLiquid() == item:GetLiquid()) and (ent:GetCurVolume() < ent:GetMaxVolume())
    end
}
ITEM.functions.combine = {
    OnRun = function(container, data)
        local client = container.player
        local char = client:GetCharacter()
        local liquidSource = ix.item.instances[data[1]]

        if(container.GetLiquid and liquidSource.GetLiquid and liquidSource:GetVolume() > 0) then
            local spaceLeft = container:GetFreeVolume()
            local liquid = container:GetLiquid()
    
            if spaceLeft > 0  then
                if !liquid or liquid == liquidSource:GetLiquid() then
                    local amountToGive

                    liquidVolume = liquidSource:GetVolume()
                    
                    if(spaceLeft >= liquidVolume) then
                        amountToGive = liquidVolume
                    else
                        amountToGive = spaceLeft
                    end
    
                    local snd = ix.liquids.Get(liquidSource:GetLiquid()):GetTransferSound()
                    
                    container:SetVolume(container:GetVolume() + amountToGive)
                    container:SetLiquid(liquidSource:GetLiquid())
                    liquidSource:SetVolume(math.Clamp(liquidVolume - amountToGive, 0, 9999))
                    
                    if snd then
                        if char.PlaySound then
                            char:PlaySound(snd)
                        else
                            client:EmitSound(snd)
                        end
                    end
                else
                    client:Notify(string.format("This %s currently is holding a different liquid! You cannot mix different liquids.", container:GetName()))
                end
            else
                client:Notify(string.format("This %s has reached its maximum capacity.", liquidSource:GetName()))
            end
        end
        return false
    end,
    OnCanRun = function(item, data)
        return true
    end
}

ITEM.suppressed = function(item, name)
    if(name == "drop") then
        return
    end
    
    if(item:GetVolume() <= 0) then
        return true, name, "This drink is empty."
    end

    return false
end