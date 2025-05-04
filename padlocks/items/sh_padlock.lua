
ITEM.name = "Padlock"
ITEM.description = "A metal padlock, used to secure doors and gates. Will grant the corresponding key when placed."
ITEM.model = "models/props_wasteland/prison_padlock001a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Utility"

if (CLIENT) then
    function ITEM:PopulateTooltip(tooltip)
        local font = "ixSmallFont"

        local info = tooltip:AddRowAfter("description", "info")
        local text = "Name: " .. self:GetData("padlockName", "Padlock")
        info:SetText(text)
        info:SetFont(font)
        info:SizeToContents()
    end
end

ITEM.functions.AName = {
    name = "Set Name",
    icon = "icon16/lock_edit.png",

    OnRun = function(item)
        local client = item.player
        client:RequestString("Set Padlock Name", "Padlock Name", function(text)
            item:SetData("padlockName", text)
            client:Notify("Padlock name set to " .. text .. ".")
        end, item:GetData("padlockName", "Padlock"))
        return false
    end
}

ITEM.functions.BPlace = {
    name = "Place",
    icon = "icon16/lock_go.png",

    OnRun = function(item)
        local client = item.player
        local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 96
            data.filter = client
        local lock = scripted_ents.Get("ix_padlock"):SpawnFunction(client, util.TraceLine(data))
        local name = item:GetData("padlockName", "Padlock")

        if IsValid(lock) then
            client:EmitSound("physics/metal/weapon_impact_soft2.wav", 75, 80)

            if !client:GetCharacter():GetInventory():Add("padlock_key", 1, {padlock = lock:GetPersistentID(), padlockName = name}) then
                ix.item.Spawn(uniqueID, client, nil, nil, {padlock = lock:GetPersistentID(), padlockName = name})
            end

            lock:SetDisplayName(name)

            return true
        else
            return false
        end
    end
}
