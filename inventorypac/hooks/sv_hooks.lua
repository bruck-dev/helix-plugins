
local PLUGIN = PLUGIN

util.AddNetworkString("ixPartWearInv")
util.AddNetworkString("ixPartRemoveInv")
util.AddNetworkString("ixPartResetInv")

-- controls pacDataInv applications on item creation, transfer, and removal events. items will not show up when inside of bags, regardless of their assigned pacInvData
do
    function PLUGIN:PlayerLoadedCharacter(client, curChar, prevChar)
        local curParts = client:GetPartsInv()
        if (curParts) then
            client:ResetPartsInv()
        end

        if (curChar) then
            local inv = curChar:GetInventory()
            for k, _ in inv:Iter() do
                if k.pacDataInv and !k.pacData then
                    client:AddPartInv(k.uniqueID, k)
                end
            end
        end
    end

    -- transferred between 2 players (or self between a bag)
    function PLUGIN:OnItemTransferred(item, oldInv, newInv)
        if item.pacDataInv and !item.pacData then
            if newInv.owner and (oldInv and oldInv.owner) then
                if !oldInv.vars.isBag then
                    oldInv:GetOwner():RemovePartInv(item.uniqueID, item)
                end
                if !newInv.vars.isBag then
                    newInv:GetOwner():AddPartInv(item.uniqueID, item)
                end
            end
        end
    end

    -- picked up from the world or directly added
    function PLUGIN:InventoryItemAdded(oldInv, newInv, item)
        if item.pacDataInv and !item.pacData then
            if ((!oldInv or (oldInv and !oldInv.owner)) and newInv.owner and !newInv.vars.isBag) then
                newInv:GetOwner():AddPartInv(item.uniqueID, item)
            end
        end
    end

    -- directly removed or dropped
    function PLUGIN:InventoryItemRemoved(oldInv, item)
        if item.pacDataInv and !item.pacData then
            if oldInv and oldInv.owner then
                oldInv:GetOwner():RemovePartInv(item.uniqueID, item)
            end
        end
    end
end

-- controls pacDataInv applications when used in conjunction with weapons
do
    function PLUGIN:WeaponEquip(weapon, client)
        timer.Simple(0.05, function() -- slight delay to network the weapon back to the server from the client when equipped
            local cur = client:GetActiveWeapon()
            if IsValid(client) and IsValid(cur) and IsValid(weapon) and cur:GetClass() == weapon:GetClass() then
                local item = IsValid(weapon) and weapon.ixItem

                if item and item.isWeapon and item.pacDataInv and !item.pacData then
                    client:RemovePartInv(item.uniqueID, item)
                end
            end
        end)
    end

    function PLUGIN:PlayerDroppedWeapon(client, weapon)
        if client:IsPlayer() then
            local item
            local inv = client:GetCharacter():GetInventory()

            -- this is, unfortunately, rather inefficient, but weapon.ixItem is already invalid by the time this hook is called :(
            for k, _ in inv:Iter() do
                if k.isWeapon and k.pacDataInv and !k.pacData and k.class == weapon:GetClass() then
                    item = k
                    break
                end
            end

            if item and item:GetOwner() and item:GetOwner() == client and item.pacDataInv and !item.pacData then
                if !client:GetPartsInv()[item.uniqueID] then
                    client:AddPartInv(item.uniqueID, item)
                end
            end
        end
    end

    function PLUGIN:PlayerSwitchWeapon(client, old, new)
        local oldItem = IsValid(old) and old.ixItem
        local newItem = IsValid(new) and new.ixItem

        if (oldItem and oldItem.isWeapon and oldItem.pacDataInv and !oldItem.pacData) then
            client:AddPartInv(oldItem.uniqueID, oldItem)
        end

        if (newItem and newItem.isWeapon and newItem.pacDataInv and !newItem.pacData) then
            client:RemovePartInv(newItem.uniqueID, newItem)
        end
    end
end

-- hides the player's pacDataInv parts when they go into observer and then shows them again when they come out of it, provided it is not their held weapon
function PLUGIN:OnPlayerObserve(client, state)
    local curParts = client:GetPartsInv()
    if (curParts) then
        client:ResetPartsInv()
    end

    if (!state) then
        local character = client:GetCharacter()
        local inventory = character:GetInventory()

        for k, _ in inventory:Iter() do
            if k.pacDataInv and !k.pacData then
                if !k.isWeapon or (k.isWeapon and client:GetActiveWeapon():GetClass() != k.class) then
                    client:AddPartInv(k.uniqueID, k)
                end
            end
        end
    end
end

-- this hook can be placed in your own plugins to block the appearance of certain pacDataInv items. in this example, "example_item" will never show up even if it has pacDataInv configured
-- i'd recommend this for more complex systems, like making sure two backpacks don't show up on the player at once
function PLUGIN:ShouldShowInvPart(client, item)
    -- if item.uniqueID == "example_item" then
    --     return false
    -- end
end