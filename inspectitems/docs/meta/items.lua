
--- Item Table Global Parameters
-- @realm shared
do
    ITEM.noInspect = false      -- Blocks inspection of this item in all normal cases.
    ITEM.inspectCam = nil       -- Same format as an iconCam, but is used to calculate the initial position of inspected inventory items.
    ITEM.inspectSound = nil     -- The sound (or list of sounds) played when an item is inspected or released.
end

--- Called when a player attempts to inspect an item.
-- @realm shared
-- @treturn bool Whether or not the item can be inspected.
function ITEM:CanInspect(client)
end

--- Called when a player inspects an item from the inventory
-- @realm shared, but only called on client by default
-- @treturn table The inspectCam table to be used to set the item's initial position. Same format as an iconCam.
function ITEM:GetInspectCam()
end

--- Called when a player starts or stops inspecting an item or item entity.
-- @realm shared, but only called on client by default
-- @bool inspectState 'true' if the inspection is starting, 'false' if it is ending.
-- @treturn string The path to the sound that should be played. Return 'nil' or 'false' to not play anything.
function ITEM:GetInspectSound(inspectState)
end

--- Call to start inspecting an item.
-- @realm server
-- @player client The inspecting player.
-- @treturn bool Whether or not the inspection was successful.
function ITEM:Inspect(client)
end

--- Item function called when a player attempts to inspect an item. The weird naming is for order, since putting it at the end requires Derma overrides.
-- @realm shared
-- @item item
-- @treturn bool Always returns false, as the item should not be deleted.
ITEM.functions.ZZInspect = {}