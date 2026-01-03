
local PLUGIN = PLUGIN

if SERVER then
    util.AddNetworkString("ixMWBSetCustomize")
    util.AddNetworkString("ixMWBAttachmentAdded")
    util.AddNetworkString("ixMWBAttachmentRemoved")
    util.AddNetworkString("ixMWBNetworkAttachment")

    net.Receive("ixMWBSetCustomize", function(length, client)
        local id = net.ReadUInt(32)
        local character = client:GetCharacter()

        if (character and character:GetID() == id) then
            local weapon = ents.GetByIndex(net.ReadUInt(32))
            local state = net.ReadBool()

            if !state and (weapon:HasFlag("Customizing")) then
                weapon:RemoveFlag("Customizing")
            end 
            weapon:TrySetTask("Customize")
        end
    end)

    net.Receive("ixMWBAttachmentAdded", function(length, client)
        local id = net.ReadUInt(32)
        local character = client:GetCharacter()

        if (character and character:GetID() == id) then
            local weapon = ents.GetByIndex(net.ReadUInt(32))
            local slot = net.ReadUInt(8)
            local attID = net.ReadString()
            local removeItem = net.ReadBool()
            if removeItem then
                local itemID = net.ReadUInt(32)
                local item = ix.item.instances[itemID]
                item:Remove()
            end

            if weapon.ixItem then
                weapon.ixItem:AddAttachment(slot, attID)
            end
        end
    end)

    net.Receive("ixMWBAttachmentRemoved", function(length, client)
        local id = net.ReadUInt(32)
        local character = client:GetCharacter()

        if (character and character:GetID() == id) then
            local itemID = net.ReadString()

            if (!client:GetCharacter():GetInventory():Add(itemID)) then
                ix.item.Spawn(itemID, client)
            end
        end
    end)
else
    net.Receive("ixMWBNetworkAttachment", function()
        local weapon = net.ReadEntity()
        local slot = net.ReadUInt(8)
        local index = net.ReadUInt(8)

        weapon:Attach(slot, index, true)
    end)

    net.Receive("ixMWBSetCustomize", function()
        local weapon = net.ReadEntity()
        local state = net.ReadBool()

        if !state and (weapon:HasFlag("Customizing")) then
            weapon:RemoveFlag("Customizing")
        end 
        
        weapon:TrySetTask("Customize")
        weapon:CustomizationMenu()
    end)
end