
local PLUGIN = PLUGIN

local function AttachPartInv(client, uniqueID)
    local itemTable = ix.item.list[uniqueID]
    local pacData = itemTable.pacDataInv

    if (pacData) then
        if (itemTable and itemTable.pacAdjustInv) then
            pacData = table.Copy(pacData)
            pacData = itemTable:pacAdjustInv(pacData, client)
        end

        if (isfunction(client.AttachPACPart)) then
            client:AttachPACPart(pacData)
        else
            pac.SetupENT(client)

            timer.Simple(0.1, function()
                if (IsValid(client) and isfunction(client.AttachPACPart)) then
                    client:AttachPACPart(pacData)
                end
            end)
        end
    end
end

local function RemovePartInv(client, uniqueID)
    local itemTable = ix.item.list[uniqueID]
    local pacData = itemTable.pacDataInv

    if (pacData) then
        if (itemTable and itemTable.pacAdjustInv) then
            pacData = table.Copy(pacData)
            pacData = itemTable:pacAdjustInv(pacData, client)
        end

        if (isfunction(client.RemovePACPart)) then
            client:RemovePACPart(pacData)
        else
            pac.SetupENT(client)
        end
    end
end

hook.Add("Think", "ixPacUpdateInv", function()
    if (!pac) then
        hook.Remove("Think", "ixPacUpdateInv")
        return
    end

    if (IsValid(pac.LocalPlayer)) then
        for _, v in player.Iterator() do
            local character = v:GetCharacter()

            if (character) then
                local parts = v:GetPartsInv()

                for k2, _ in pairs(parts) do
                    AttachPartInv(v, k2)
                end
            end
        end

        hook.Remove("Think", "ixPacUpdateInv")
    end
end)

net.Receive("ixPartWearInv", function(length)
    if (!pac) then return end

    local wearer = net.ReadEntity()
    local uid = net.ReadString()

    if (!wearer.pac_owner) then
        pac.SetupENT(wearer)
    end

    AttachPartInv(wearer, uid)
end)

net.Receive("ixPartRemoveInv", function(length)
    if (!pac) then return end

    local wearer = net.ReadEntity()
    local uid = net.ReadString()

    if (!wearer.pac_owner) then
        pac.SetupENT(wearer)
    end

    RemovePartInv(wearer, uid)
end)

net.Receive("ixPartResetInv", function(length)
    if (!pac) then return end

    local wearer = net.ReadEntity()
    local uidList = net.ReadTable()

    if (!wearer.pac_owner) then
        pac.SetupENT(wearer)
    end

    for k, _ in pairs(uidList) do
        RemovePartInv(wearer, k)
    end
end)