
local PLUGIN = PLUGIN

PLUGIN.name = "Filtered Bags"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds support for bag content filtering based on item ID and category."

function PLUGIN:CanTransferItem(item, oldInv, newInv)
    -- only run if we are transferring to a valid owned bag inventory
    if newInv and newInv.owner and newInv.vars.isBag then
        local bag = ix.item.Get(newInv.vars.isBag)
        
        -- if either an item ID or item category whitelist exist, check if the transferee qualifies
        if bag.itemWhitelist or bag.categoryWhitelist then
            local fits = (bag.itemWhitelist and bag.itemWhitelist[item.uniqueID]) or (bag.categoryWhitelist and bag.categoryWhitelist[item.category])
            if !fits then
                newInv:GetOwner():Notify(string.format("This %s cannot be placed into a %s.", item:GetName(), bag:GetName()))
                return false
            end
        end
    end
end