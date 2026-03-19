
PLUGIN.name = "NPC Drop Removal"
PLUGIN.author = "bruck"
PLUGIN.description = "Removes NPC weapon and item drops on death."

ix.config.Add("removeNpcDrops", true, "Whether or not NPCs should have their weapons and item drops removed on death.", nil, {
    category = "Utility",
    type = ix.type.bool
})

if SERVER then
    function PLUGIN:PlayerDroppedWeapon(entity, weapon)
        if (entity:IsNPC() or entity:IsNextBot()) and (ix.config.Get("removeNpcDrops", true) or hook.Run("ShouldRemoveNPCDrop", entity, weapon)) then
            weapon:Remove()
        end
    end

    function PLUGIN:OnNPCDropItem(npc, item)
        if ix.config.Get("removeNpcDrops", true) or hook.Run("ShouldRemoveNPCDrop", npc, item) then
            item:Remove()
        end
    end
end