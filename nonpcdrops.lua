
PLUGIN.name = "NPC Drop Removal"
PLUGIN.author = "bruck"
PLUGIN.description = "Removes NPC weapon and item drops on death."

ix.config.Add("removeNpcDrops", true, "Whether or not NPCs should have their weapons and item drops removed on death.", nil, {
    category = "Utility",
    type = ix.type.bool
})

if SERVER then
    -- overwrite OR use the ShouldRemoveNPCDrop() hook if you want to do more than just use the boolean config setting. this will probably take priority, so keep the bool off if you want to customize it
    function PLUGIN:ShouldRemoveNPCDrop(npc, drop)
        if ix.config.Get("removeNpcDrops", true) then
            return true
        end
    end

    function PLUGIN:PlayerDroppedWeapon(entity, weapon)
        if (entity:IsNPC() or entity:IsNextBot()) and hook.Run("ShouldRemoveNPCDrop", entity, weapon) then
            weapon:Remove()
        end
    end

    function PLUGIN:OnNPCDropItem(npc, item)
        if hook.Run("ShouldRemoveNPCDrop", npc, item) then
            item:Remove()
        end
    end
end