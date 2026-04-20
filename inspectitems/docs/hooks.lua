
--- Called when an entity is inspected; if the entity class is ix_item and the item table has its own sound, that will be used instead.
-- @realm client
-- @entity ent The entity being inspected.
-- @bool state Whether the inspection is starting (true) or ending (false).
-- @treturn string Path to the desired sound file.
-- @usage
-- function PLUGIN:GetInspectSound(ent, state)
--     if ent:GetClass() == "ix_inspectable" and !state then
--         return "foley/eli_hand_pat.wav"
--     end
-- end
function GetInspectSound(ent, state)
end

--- Called when a player picks up an item from the from the inspection panel.
-- @realm server
-- @player ply The player picking up the entity.
-- @entity ent The entity being picked up.
-- @treturn bool Return "true" to block the normal behavior of just teleporting the entity to the player (which is how Source items are picked up, generally)
-- @usage
-- function PLUGIN:PlayerPickupItem(ply, ent)
--     if ent:GetClass() == "ix_example_entity" then
--         ent:Remove()
--         return true
--     end
-- end
function PlayerPickupItem(ply, ent)
end