
-- scales received damage based on the hitgroup and the player's worn armor
function PLUGIN:EntityTakeDamage(client, dmgInfo)
    if client:IsPlayer() then
        local armor = client:GetCharacter():GetHitArmor(client:LastHitGroup())
        if armor and armor:GetDurability() > 0 then
            local dmgType = dmgInfo:GetDamageType()
            local resist = armor:GetResistances()

            resist = resist[dmgType]
            if resist then
                dmgInfo:ScaleDamage(resist)
            end

            if !armor.noDurabilityDecrease[dmgType] then
                armor:ReduceDurability(dmgInfo:GetDamage() * 0.8)
            end
        end
    end
end

-- this hook is called to check if a player can repair their armor or not. by default, it's not very restrictive
function PLUGIN:CanPlayerRepairArmor(client, item)
    if !(item.invID == client:GetCharacter():GetInventory():GetID()) then return false end
    if client:IsRestricted() then return false end
end

local function resetArmorGiven(client)
    local char = client:GetCharacter()
    if !char then return end

    for k, _ in char:GetInventory():Iter() do
		if k.isArmor and k:GetData("equip") then
            k.armorGiven = nil
		end
	end

    if ix.charPanel then
        for slot, item in pairs(char:GetCharPanel():GetItems() or {}) do
            if item.isArmor then
                item.armorGiven = nil
            end
        end
    end
end

function PLUGIN:PlayerLoadedCharacter(client, char, prevChar)
    resetArmorGiven(client)
end

function PLUGIN:PlayerSpawn(client)
    resetArmorGiven(client)
end