
ITEM.name = "Flashlight Base"
ITEM.model = "models/maxofs2d/lamp_flashlight.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "A simple base for flashlight items to use, if they have no other intended function."

ITEM.isFlashlight = true                                -- required for all flashlight items, using the base or not

ITEM:Hook("drop", function(item)                        -- highly recommended; turns off the flashlight when dropped so you don't get in a stuck-on state
    if !ix.config.Get("freeFlashlights", false) then
        item.player:Flashlight(false)
    end
end)
