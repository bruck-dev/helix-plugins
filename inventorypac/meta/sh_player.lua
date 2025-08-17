
local PLUGIN = PLUGIN
local PLAYER = FindMetaTable("Player")

function PLAYER:GetPartsInv()
    if (!pac) then return end

    return self:GetNetVar("partsInv", {})
end

if SERVER then
    function PLAYER:AddPartInv(uniqueID, item)
        if (!pac) then return end
        if hook.Run("ShouldShowInvPart", self, item) == false then return end -- optional hook to block the showing of pacDataInv parts under desired conditions, i.e. only 1 backpack shows at once

        local curParts = self:GetPartsInv()
        if curParts[uniqueID] then return end

        -- wear the parts.
        net.Start("ixPartWearInv")
            net.WriteEntity(self)
            net.WriteString(uniqueID)
        net.Broadcast()

        curParts[uniqueID] = true

        self:SetNetVar("partsInv", curParts)
    end

    function PLAYER:RemovePartInv(uniqueID, item)
        if (!pac) then return end

        local curParts = self:GetPartsInv()
        if !curParts[uniqueID] then return end

        -- remove the parts.
        net.Start("ixPartRemoveInv")
            net.WriteEntity(self)
            net.WriteString(uniqueID)
        net.Broadcast()

        curParts[uniqueID] = nil

        self:SetNetVar("partsInv", curParts)
    end

    function PLAYER:ResetPartsInv()
        if (!pac) then return end

        net.Start("ixPartResetInv")
            net.WriteEntity(self)
            net.WriteTable(self:GetPartsInv())
        net.Broadcast()

        self:SetNetVar("partsInv", {})
    end
end