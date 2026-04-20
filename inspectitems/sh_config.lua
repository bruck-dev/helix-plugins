
local PLUGIN = PLUGIN

ix.config.Add("enableEntityInspection", true, "Whether or not world entities can be inspected. Items in the inventory can still be inspected with the item function.", nil, {
    category = PLUGIN.name
})

ix.config.Add("enableEntityPickup", true, "Whether or not world entities can be picked up. Some entities may have additional conditions for pickup after this is checked.", nil, {
    category = PLUGIN.name
})

ix.config.Add("enableInspectableShimmer", true, "Whether or not the Helix Inspectable entity will have a faint shimmer, identifying it as an Inspectable instead of a prop.", nil, {
    category = PLUGIN.name
})

ix.config.Add("enableInspectionDSP", true, "Whether or not players should have their audio muffled while inspecting an item or entity.", nil, {
    category = PLUGIN.name
})

if CLIENT then
    -- Whether or not Inspectable entities should have a shimmer effect. This will be overruled if the server-level setting is disabled.
    ix.option.Add("enableInspectableShimmer", ix.type.bool, true, {
        category = PLUGIN.name,
        hidden = function()
            return !(ix.config.Get("enableEntityInspection", true) and ix.config.Get("enableInspectableShimmer", true))
        end
    })

    -- Whether or not previously inspected Inspectable entities should still shimmer. This does not persist between connects, and will be overruled if the server-level setting is disabled.
    ix.option.Add("enableInspectedShimmer", ix.type.bool, true, {
        category = PLUGIN.name,
        hidden = function()
            return !(ix.config.Get("enableEntityInspection", true) and ix.config.Get("enableInspectableShimmer", true))
        end
    })
end