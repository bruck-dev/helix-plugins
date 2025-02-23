
--[[
    ix.liquids.RegisterSource("models/model.mdl", {
        name = "Source Name",                       -- name displayed on tooltip
        liquid = "Liquid Type",                     -- liquid name or uniqueid from registered liquids (see: libs/sh_liquids.lua)
        infinite = true/false,                      -- determines if capacity should be used or not
        maxVolume = #,                              -- max capacity as an integer, in mL
        startingVolume = #,                         -- default fill level as an integer, in mL; CAN be larger than the max
        showTooltip = true/false,                   -- determines if the item's tooltip should show by default
    })
--]]