
ITEM.name = "Lighters Base"
ITEM.model = "models/props_junk/metalgascan.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "Item base for lighters. Mostly just for sorting since any item with ITEM.canLightSmokable is considered valid."
ITEM.category = "Tools" 
ITEM.canLightSmokable = true

-- Called when the item is used to light a cigarette. Can be used to make something like a fuel system or consumable matches.
-- Doesn't need to be a base_lighters item to be called - just create ITEM:OnSmokableLit().
function ITEM:OnSmokableLit(smokable)
end