
local ITEM = ix.meta.item

ITEM.noInspect = false
ITEM.inspectCam = nil
ITEM.inspectSound = nil

function ITEM:CanInspect(client)
    return !self.noInspect and !client:IsRestricted()
end

function ITEM:GetInspectCam()
    return self.inspectCam
end

function ITEM:GetInspectSound(inspectState)
    if !self.inspectSound then return end

    if istable(self.inspectSound) then
        return self.inspectSound[math.random(1, #inspectSound)]
    else
        return self.inspectSound
    end
end

if SERVER then
    function ITEM:Inspect(client)
        if !self:CanInspect(client) then
            return false
        end

        if self.InspectingPlayer then
            return false
        end
        
        if self.entity and IsValid(self.entity) then
            ix.inspect.InspectEntity(client, self.entity)
        else
            ix.inspect.InspectItem(client, self)
        end

        return true
    end
end