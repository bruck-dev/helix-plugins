
ITEM.name = "Flashlight"
ITEM.model = "models/raviool/flashlight.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A flashlight, to illuminate the dark."
ITEM.category = "Equipment"

ITEM.isFlashlight = true

ITEM:Hook("drop", function(item)
    if !ix.config.Get("freeFlashlights", false) then
        item.player:Flashlight(false)
    end
end)
