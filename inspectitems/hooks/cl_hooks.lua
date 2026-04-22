
local PLUGIN = PLUGIN

-- tracks when the client hits E on an ix_item WITHOUT holding it down, so that they can still pick it up as usual. this is ignored for other inspectable ent classes
local pressTime = nil
local pressEnt = nil

function PLUGIN:KeyRelease(ply, key)
    if key != IN_USE then return end
    if !pressTime then return end
    if ix.inspect.IsInspecting() then return end
    if !ix.config.Get("enableEntityInspection", true) then return end
    
    if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end
    
    if IsValid(pressEnt) and ((CurTime() - pressTime) < ix.config.Get("itemPickupTime", 0.5)) then
        net.Start("InspectEnt_Start")
            net.WriteEntity(pressEnt)
        net.SendToServer()
    else
        pressEnt = nil
    end

    pressTime = nil
end

function PLUGIN:KeyPress(ply, key)
    if key != IN_USE then return end
    if ix.inspect.IsInspecting() then return end
    if !ix.config.Get("enableEntityInspection", true) then return end

    if !IsValid(ply) or !ply:Alive() or ply:InVehicle() then return end
    
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * ix.config.Get("interactRange", 96), -- merge my pr, alex >:(
        filter = ply
    })
    
    local ent = tr.Entity
    if IsValid(ent) and ix.inspect.IsInspectable(ent) then
        if ent:GetClass() == "ix_item" then
            pressEnt = ent
            pressTime = CurTime()
            return
        else
            net.Start("InspectEnt_Start")
                net.WriteEntity(ent)
            net.SendToServer()
        end
    end

    pressEnt = nil
    pressTime = nil
end

function PLUGIN:OnItemTransferred(item, oldInv, newInv)
    local inspecting, inspectItem = ix.inspect.IsInspecting()
    if inspecting and inspectItem.id == item.id then
        ix.inspect.EndInspect()
    end
end

function PLUGIN:ShowEntityMenu(ent)
    if ix.inspect.IsInspectable(ent) then
        return false
    end
end