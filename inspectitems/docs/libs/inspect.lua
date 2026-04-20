
--- Checks whether or not the given entity can be inspected, relative to the whitelist table.
-- @realm shared
-- @entity ent The entity being checked.
-- @treturn bool Whether or not the entity can be inspected.
function ix.inspect.IsInspectable(ent)
end

--- Adds or removes the given entity class from the inspection whitelist table.
-- @realm shared
-- @entity/string classOrEnt The entity class (or entity the class should be taken from) to change the whitelist for.
-- @bool state Whether the entity should be added or removed from the whitelist.
function ix.inspect.SetWhitelisted(classOrEnt, state)
end

--- Checks whether or not the given player is actively inspecting something.
-- @realm server
-- @player ply The player to be checked.
-- @treturn bool Whether or not the player is inspecting something.
-- @treturn entity/item The entity or item that is currently being inspected.
function ix.inspect.IsInspecting(ply)
end

--- Starts an inspection on the given item table.
-- @realm server
-- @player ply The player to start the inspection for.
-- @item item The item to be inspected.
-- @treturn bool Whether or not the inspection was started successfully.
function ix.inspect.InspectItem(ply, item)
end

--- Ends an inspection on the given item table.
-- @realm server
-- @player ply The player (if any) that was inspecting the item.
-- @item item The item that was being inspected.
function ix.inspect.ReleaseItem(ply, item)
end

--- Starts an inspection on the given entity, if possible.
-- @realm server
-- @player ply The player to start the inspection for.
-- @entity ent The entity to be inspected.
-- @treturn bool Whether or not the inspection was started successfully.
function ix.inspect.InspectEntity(ply, ent)
end

--- Ends an inspection on the given entity, if needed.
-- @realm server
-- @player ply The player (if any) that was inspecting the entity.
-- @entity ent The entity that was being inspected.
function ix.inspect.ReleaseEntity(ply, ent)
end

--- Checks whether or not the given inspectable entity can be picked up from the inspection panel.
-- @realm server
-- @player ply The player that is inspecting the entity.
-- @entity ent The entity that is being inspected.
-- @treturn bool Whether or not the player can pick up the item.
function ix.inspect.CanPickupEntity(ply, ent)
end

--- Checks whether or not the local player is actively inspecting something.
-- @realm client
-- @treturn bool Whether or not the local player is inspecting something.
-- @treturn entity/item The entity or item that is currently being inspected.
function ix.inspect.IsInspecting()
end

--- Ends the current inspection and removes the inspection panel.
-- @realm client
function ix.inspect.EndInspect()
end

--- (INTERNAL) Copy of ix.item.PerformInventoryAction that bypasses the GetUseEntity check, as the player may not be looking directly at the inspected item entity. Hardcoded to the "take" action.
-- @realm server
-- @player client The player performing the action.
-- @item entity/item The entity or item table the action is being performed on.
function ix.inspect.PickupItemEntity(client, item)
end