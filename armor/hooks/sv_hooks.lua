
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