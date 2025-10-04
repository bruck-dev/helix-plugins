
ITEM.base = "base_pacoutfit"             -- basically all normal outfit parameters will work the exact same, as this is an inherited base

ITEM.name = "Wearable Armor Base (PAC)"
ITEM.description = "An armor base, allowing for conditional damage reduction and durability."
ITEM.category = "Armor"
ITEM.model = "models/props_junk/cardboard_box001a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "armor"           -- arbitrary value that determines what other clothing items this one is incompatible with

ITEM.isArmor = true                     -- do not change, this is what allows armor items to be detected when the player is hurt. if you want to make a custom item base, make sure you include this
ITEM.armor = 0                          -- the amount of hl2 armor points given to the player on equip. i actually recommend keeping it at 0 as resistances still apply even without literal armor points
ITEM.hitgroups = {}                     -- the hitgroups this armor applies to. format like {[HITGROUP_NAME] = true}, following the HITGROUP enum
                                        -- this allows armor to only apply to certain areas; if you get shot in the chest, your helmet won't do anything, for instance
ITEM.resistances = {}                   -- the damage types this armor protects against. format like {[DMG_BULLET] = multiplier}, following the DMG enum
                                        -- a multiplier of 0.8 means damage from that type does 80% of what it normally would do. in theory you can use this to make damage INCREASES too
ITEM.maxDurability = 100                -- the maximum amount of damage (relative to player HP) the armor piece can take before breaking
ITEM.noDurabilityDecrease = {           -- these damage types do not decrease armor durability when applied to the player. this should cover most use cases, but can be customized per item
    [DMG_DROWN] = true,
    [DMG_FALL] = true,
    [DMG_POISON] = true,
    [DMG_NERVEGAS] = true,
    [DMG_PARALYZE] = true,
}
ITEM.unbreakable = false                -- if true, the item will never lose durability and the bar will not be displayed

ITEM.equipSound = nil                   -- both can either be a single string path or a list of sound paths
ITEM.unequipSound = nil

ITEM.pacData = {}                       -- custom pacData to use for the armor

-- shamelessly taken from the old armor base, for backwards compatibility
local function armorPlayer(client, target, amount)
    hook.Run("OnPlayerArmor", client, target, amount)

    if client:Alive() and target:Alive() then
        target:SetArmor(amount)
    end
end

if (CLIENT) then
    function ITEM:PaintOver(item, w, h)
        if (item:GetData("equip", false)) then
            surface.SetDrawColor(110, 255, 110, 100)
            if self.unbreakable then
                surface.DrawRect(w - 14, h - 14, 8, 8)  -- the position of the green square is not adjusted for the bar if it wont exist
            else
                surface.DrawRect(w - 14, h - 20, 8, 8)
            end
        end
        
        if !self.unbreakable then
            local amount = item:GetDurability()

            if (amount) then
                surface.SetDrawColor(35, 35, 35, 225)
                surface.DrawRect(2, h-9, w-4, 7)

                local filledWidth = (w-5) * (amount / item:GetMaxDurability())
                
                surface.SetDrawColor(142, 142, 142, 255)
                surface.DrawRect(3, h-8, filledWidth, 5) 
            end
        end
    end

    function ITEM:PopulateTooltip(tooltip)
        if !self.unbreakable then
            local data = tooltip:AddRow("data")
            data:SetBackgroundColor(Color(142, 142, 142, 255))
            data:SetText("Durability: " .. tostring(math.ceil(100 * (self:GetDurability() / self:GetMaxDurability()))) .. "%")
            data:SetExpensiveShadow(0.5)
            data:SizeToContents()
        end
    end
end

function ITEM:GetArmor()
    if self.armor == 0 then -- dont do any math if we dont have to
        return 0
    else
        local dur = self:GetDurability()
        return self.armor * (dur / 100)
    end
end

function ITEM:GetResistances()
    return self.resistances
end

function ITEM:GetMaxDurability()
    return self.maxDurability
end

function ITEM:GetDurability()
    return self:GetData("durability", self:GetMaxDurability())
end

function ITEM:ReduceDurability(dmg)
    if self.unbreakable then return end

    local dur = self:GetDurability()
    if (dur - dmg) <= 0 then
        self:SetData("durability", 0)
    else
        self:SetData("durability", dur - dmg)
    end
end

function ITEM:RestoreDurability(val)
    local dur = self:GetDurability()
    if (dur + val) > self:GetMaxDurability() then
        self:SetData("durability", self:GetMaxDurability())
    else
        self:SetData("durability", dur + val)
    end
end

-- extra conditions that are checked to determine whether or not a player can repair this armor item. dont put any notify calls in this, since its called every time the player opens the item function menu
function ITEM:CanRepair(client)
    return true
end

-- use this function per item to customize how an armor item is repaired. ive provided a basic example.
function ITEM:Repair(client)
    --[[
    if client:GetCharacter():GetInventory():HasItem("example_repair_item_id") then
        self:RestoreDurability(50)  -- this will never exceed 100% durability, so don't worry too much about the specific values
    else
        client:Notify("You do not have a repair kit to fix this piece of armor!")
    end
    ]]--
end

function ITEM:AddPart(client)
    local char = client:GetCharacter()

    self:SetData("equip", true)
    client:AddPart(self.uniqueID, self)

    if (self.attribBoosts) then
        for k, v in pairs(self.attribBoosts) do
            char:AddBoost(self.uniqueID, k, v)
        end
    end

    self:OnEquipped()

    armorPlayer(client, client, client:Armor() + self:GetArmor())
end

function ITEM:RemovePart(client)
    local char = client:GetCharacter()

    self:SetData("equip", false)
    client:RemovePart(self.uniqueID)

    if (self.attribBoosts) then
        for k, _ in pairs(self.attribBoosts) do
            char:RemoveBoost(self.uniqueID, k)
        end
    end

    self:OnUnequipped()

    armorPlayer(client, client, client:Armor() - self:GetArmor())
end

-- self.armorGiven check only exists such that OnLoadout won't constantly reapply it, because it runs like 8 times for some reason
function ITEM:OnLoadout()
    if self:GetData("equip", false) and self:GetArmor() > 0 and !self.armorGiven then
        armorPlayer(self.player, self.player, self.player:Armor() + self:GetArmor())
        self.armorGiven = true
    end
end

ITEM.functions.Equip = {
    name = "equip",
    tip = "equipTip",
    icon = "icon16/tick.png",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()

        for k, _ in char:GetInventory():Iter() do
            if (k.id != item.id) then
                local itemTable = ix.item.instances[k.id]

                if (itemTable.pacData and k.outfitCategory == item.outfitCategory and itemTable:GetData("equip")) then
                    client:NotifyLocalized(item.equippedNotify or "outfitAlreadyEquipped")

                    return false
                end
            end
        end

        item:AddPart(client)

        return false
    end,
    OnCanRun = function(item)
        local client = item.player

        return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") != true and
            hook.Run("CanPlayerEquipItem", client, item) != false
    end
}

ITEM.functions.Repair = {
    name = "Repair",
    icon = "icon16/wrench.png",
    OnRun = function(item)
        item:Repair(item.player)
        return false
    end,
    OnCanRun = function(item)
        local client = item.player

        return !IsValid(item.entity) and IsValid(client) and !item.unbreakable and (item:GetDurability() < item:GetMaxDurability()) and
            hook.Run("CanPlayerRepairArmor", client, item) != false and item:CanRepair(client)
    end
}