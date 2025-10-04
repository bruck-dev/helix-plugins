
ITEM.name = "Padlock"
ITEM.description = "A metal padlock, used to secure doors and gates."
ITEM.model = "models/props_wasteland/prison_padlock001a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Security"

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

function ITEM:GetDescription()
    local desc = self.description
    if !self:GetData("persistentID", nil) then
        desc = desc .. " Will grant the corresponding key when placed."
    end
    return desc
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
        local lock = scripted_ents.Get("ix_padlock"):SpawnFunction(client, util.TraceLine(data), item:GetData("persistentID", nil))
        local name = item:GetData("padlockName", "Padlock")

        if IsValid(lock) then
            local snd = {"physics/metal/weapon_impact_soft1.wav", "physics/metal/weapon_impact_soft2.wav", "physics/metal/weapon_impact_soft3.wav"}
            lock:EmitSound(snd[math.random(1, #snd)], 75, 80)

            -- if the PID already exists, we know this lock was picked up. do not make a new key
            if !item:GetData("persistentID", nil) then
                if !client:GetCharacter():GetInventory():Add("padlock_key", 1, {persistentID = lock:GetPersistentID(), padlockName = name}) then
                    ix.item.Spawn("padlock_key", client, nil, nil, {persistentID = lock:GetPersistentID(), padlockName = name})
                end
            end

            lock:SetDisplayName(name)

            return true
        else
            return false
        end
    end
}
