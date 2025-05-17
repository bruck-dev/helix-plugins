
ITEM.base = "base_outfit"               -- basically all normal outfit parameters will work the exact same, as this is an inherited base

ITEM.name = "Wearable Armor Base"
ITEM.description = "An armor base, allowing for conditional damage reduction and durability."
ITEM.category = "Armor"
ITEM.model = "models/props_junk/cardboard_box001a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "armor"           -- arbitrary value that determines what other clothing items this one is incompatible with

ITEM.armor = 0                          -- the amount of hl2 armor points given to the player on equip. i actually recommend keeping it at 0 as resistances still apply even without literal armor points
ITEM.hitgroups = {}                     -- the hitgroups this armor applies to. format like {[HITGROUP_NAME] = true}, following the HITGROUP enum
                                        -- this allows armor to only apply to certain areas; if you get shot in the chest, your helmet won't do anything, for instance
ITEM.resistances = {}                   -- the damage types this armor protects against. format like {[DMG_BULLET] = multiplier}, following the DMG enum
                                        -- a multiplier of 0.8 means damage from that type does 80% of what it normally would do. in theory you can use this to make damage INCREASES too
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

-- shamelessly taken from the old armor base, for backwards compatibility
local function armorPlayer(client, target, amount)
    hook.Run("OnPlayerArmor", client, target, amount)

    if client:Alive() and target:Alive() then
        target:SetArmor(amount)
    end
end

local function ResetSubMaterials(client)
    for k, _ in ipairs(client:GetMaterials()) do
        if (client:GetSubMaterial(k - 1) != "") then
            client:SetSubMaterial(k - 1)
        end
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

                local filledWidth = (w-5) * (amount / 100)
                
                surface.SetDrawColor(142, 142, 142, 255)
                surface.DrawRect(3, h-8, filledWidth, 5) 
            end
        end
    end

    function ITEM:PopulateTooltip(tooltip)
        if !self.unbreakable then
            local data = tooltip:AddRow("data")
            data:SetBackgroundColor(Color(142, 142, 142, 255))
            data:SetText("Durability: " .. tostring(math.ceil(self:GetDurability())) .. "%")
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

function ITEM:GetDurability()
    return self:GetData("durability", 100)
end

function ITEM:ReduceDurability(dmg)
    if self.unbreakable then return end

    local dur = self:GetDurability()
    if dur - dmg <= 0 then
        self:SetData("durability", 0)
    else
        self:SetData("durability", dur - dmg)
    end
end

function ITEM:RestoreDurability(val)
    local dur = self:GetDurability()
    if dur + val > 100 then
        self:SetData("durability", 100)
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

function ITEM:AddOutfit(client)
    local character = client:GetCharacter()

    self:SetData("equip", true)

    local groups = character:GetData("groups", {})

    -- remove original bodygroups
    if (!table.IsEmpty(groups)) then
        character:SetData("oldGroups" .. self.outfitCategory, groups)
        character:SetData("groups", {})

        client:ResetBodygroups()
    end

    if (isfunction(self.OnGetReplacement)) then
        character:SetData("oldModel" .. self.outfitCategory,
            character:GetData("oldModel" .. self.outfitCategory, self.player:GetModel()))
        character:SetModel(self:OnGetReplacement())
    elseif (self.replacement or self.replacements) then
        character:SetData("oldModel" .. self.outfitCategory,
            character:GetData("oldModel" .. self.outfitCategory, self.player:GetModel()))

        if (istable(self.replacements)) then
            if (#self.replacements == 2 and isstring(self.replacements[1])) then
                character:SetModel(self.player:GetModel():gsub(self.replacements[1], self.replacements[2]))
            else
                for _, v in ipairs(self.replacements) do
                    character:SetModel(self.player:GetModel():gsub(v[1], v[2]))
                end
            end
        else
            character:SetModel(self.replacement or self.replacements)
        end
    end

    if (self.newSkin) then
        character:SetData("oldSkin" .. self.outfitCategory, self.player:GetSkin())
        self.player:SetSkin(self.newSkin)
    end

    -- get outfit saved bodygroups
    groups = self:GetData("groups", {})

    -- restore bodygroups saved to the item
    if (!table.IsEmpty(groups) and self:ShouldRestoreBodygroups()) then
        for k, v in pairs(groups) do
            client:SetBodygroup(k, v)
        end
    -- apply default item bodygroups if none are saved
    elseif (istable(self.bodyGroups)) then
        for k, v in pairs(self.bodyGroups) do
            local index = client:FindBodygroupByName(k)

            if (index > -1) then
                client:SetBodygroup(index, v)
            end
        end
    end

    local materials  = self:GetData("submaterial", {})

    if (!table.IsEmpty(materials) and self:ShouldRestoreSubMaterials()) then
        for k, v in pairs(materials) do
            if (!isnumber(k) or !isstring(v)) then
                continue
            end

            client:SetSubMaterial(k - 1, v)
        end
    end

    if (istable(self.attribBoosts)) then
        for k, v in pairs(self.attribBoosts) do
            character:AddBoost(self.uniqueID, k, v)
        end
    end

    if self.equipSound then
        local snd = self.equipSound
        if istable(snd) then
            snd = snd[math.random(1, #snd)]
        end
        client:GetCharacter():PlaySound(snd)
    end

    self:GetOwner():SetupHands()
    self:OnEquipped()

    armorPlayer(client, client, client:Armor() + self:GetArmor())
end

function ITEM:RemoveOutfit(client)
    local character = client:GetCharacter()

    self:SetData("equip", false)

    local materials = {}

    for k, _ in ipairs(client:GetMaterials()) do
        if (client:GetSubMaterial(k - 1) != "") then
            materials[k] = client:GetSubMaterial(k - 1)
        end
    end

    -- save outfit submaterials
    if (!table.IsEmpty(materials)) then
        self:SetData("submaterial", materials)
    end

    -- remove outfit submaterials
    ResetSubMaterials(client)

    local groups = {}

    for i = 0, (client:GetNumBodyGroups() - 1) do
        local bodygroup = client:GetBodygroup(i)

        if (bodygroup > 0) then
            groups[i] = bodygroup
        end
    end

    -- save outfit bodygroups
    if (!table.IsEmpty(groups)) then
        self:SetData("groups", groups)
    end

    -- remove outfit bodygroups
    client:ResetBodygroups()

    -- restore the original player model
    if (character:GetData("oldModel" .. self.outfitCategory)) then
        character:SetModel(character:GetData("oldModel" .. self.outfitCategory))
        character:SetData("oldModel" .. self.outfitCategory, nil)
    end

    -- restore the original player model skin
    if (self.newSkin) then
        if (character:GetData("oldSkin" .. self.outfitCategory)) then
            client:SetSkin(character:GetData("oldSkin" .. self.outfitCategory))
            character:SetData("oldSkin" .. self.outfitCategory, nil)
        else
            client:SetSkin(0)
        end
    end

    -- get character original bodygroups
    groups = character:GetData("oldGroups" .. self.outfitCategory, {})

    -- restore original bodygroups
    if (!table.IsEmpty(groups)) then
        for k, v in pairs(groups) do
            client:SetBodygroup(k, v)
        end

        character:SetData("groups", character:GetData("oldGroups" .. self.outfitCategory, {}))
        character:SetData("oldGroups" .. self.outfitCategory, nil)
    end

    if (istable(self.attribBoosts)) then
        for k, _ in pairs(self.attribBoosts) do
            character:RemoveBoost(self.uniqueID, k)
        end
    end

    for k, _ in pairs(self:GetData("outfitAttachments", {})) do
        self:RemoveAttachment(k, client)
    end

    if self.unequipSound then
        local snd = self.unequipSound
        if istable(snd) then
            snd = snd[math.random(1, #snd)]
        end
        client:GetCharacter():PlaySound(snd)
    end

    self:GetOwner():SetupHands()
    self:OnUnequipped()

    armorPlayer(client, client, client:Armor() - self:GetArmor())
end

-- self.armorGiven check only exists such that OnLoadout won't constantly reapply it, because it runs like 8 times for some reason
function ITEM:OnLoadout()
    if self:GetData("equip", false) and self.armor > 0 and !self.armorGiven then
        armorPlayer(self.player, self.player, self.player:Armor() + self:GetArmor())
        self.armorGiven = true
    end
end

ITEM.functions.Repair = {
    name = "Repair",
    icon = "icon16/wrench.png",
    OnRun = function(item)
        item:Repair(item.player)
        return false
    end,
    OnCanRun = function(item)
        local client = item.player

        return !IsValid(item.entity) and IsValid(client) and (item:GetDurability() < 100) and
            hook.Run("CanPlayerRepairArmor", client, item) != false and item:CanRepair(client)
    end
}