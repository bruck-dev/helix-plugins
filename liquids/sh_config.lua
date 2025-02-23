
local PLUGIN = PLUGIN

ix.config.Add("allowSourceSpawning", true, "Whether or not props are automatically converted to sources on spawn, if registered as a valid source.", nil, {
	category = "Liquids"
})
ix.config.Add("allowMapRefills", true, "Whether or not players should be allowed to fill containers from water brushes on the map. By default, this uses the liquid linked to the 'water' uniqueID, so update the item base accordingly.", nil, {
    category = "Liquids"
})
ix.config.Add("maxDrinkingVolume", 150, "The maximum volume of liquid (in milliliters) that can be consumed per drink. Any container with a volume greater than 5x this value cannot be sipped from.", nil, {
    data = {min = 1, max = 150},
	category = "Liquids"
})

if (CLIENT) then
    ix.option.Add("useLiquidColor", ix.type.bool, true, {
        category = "Liquids"
    })
end