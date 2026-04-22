
ix.inspect = ix.inspect or {}

-- list of entities that can be inspected
ix.inspect.whitelist = ix.inspect.whitelist or {
    ix_item = true,
    ix_inspectable = true,
    item_healthkit = true,
    item_healthvial = true,
    item_battery = true,
    item_ammo_357 = true,
    item_ammo_357_large = true,
    item_ammo_ar2 = true,
    item_ammo_ar2_altfire = true,
    item_ammo_ar2_large = true,
    item_ammo_crossbow = true,
    item_ammo_pistol = true,
    item_ammo_pistol_large = true,
    item_ammo_smg1 = true,
    item_ammo_smg1_large = true,
    item_ammo_smg1_grenade = true,
    item_box_buckshot = true,
    item_rpg_round = true,
}

function ix.inspect.IsInspectable(classOrEnt)
    if isentity(classOrEnt) then
        if !IsValid(classOrEnt) then
            return false
        end
        return (ix.inspect.whitelist[classOrEnt:GetClass()] == true) or classOrEnt:IsWeapon()
    elseif isstring(classOrEnt) then
        return ix.inspect.whitelist[classOrEnt:lower()] == true
    else
        return false
    end
end

function ix.inspect.SetWhitelisted(classOrEnt, state)
    local class
    if isentity(classOrEnt) and IsValid(classOrEnt) then
        class = class:GetClass()
    elseif isstring(class) then
        class = classOrEnt:lower()
    else
        return
    end

    if state then
        ix.inspect.whitelist[class] = true
    else
        ix.inspect.whitelist[class] = nil
    end
end

if SERVER then
    function ix.inspect.IsInspecting(ply)
        return ply.IsInspecting, (ply.InspectedEnt or ply.InspectedItem)
    end

    function ix.inspect.InspectItem(ply, item)
        if ply:IsRestricted() then return false end

        net.Start("InspectItem_Start")
            net.WriteUInt(item.id, 32)
        net.Send(ply)

        ply.InspectedItem = item
        ply.IsInspecting = true
        item.InspectingPlayer = ply

        return true
    end

    function ix.inspect.ReleaseItem(ply, item)
        if IsValid(ply) then
            ply.IsInspecting = nil
            ply.InspectedItem = nil
        end

        if item and item.InspectingPlayer then
            item.InspectingPlayer = nil
        end
    end

    function ix.inspect.InspectEntity(ply, ent)
        if ply:IsRestricted() then return false end
        if ply:GetPos():DistToSqr(ent:GetPos()) > 40000 then return false end
        if !ix.inspect.IsInspectable(ent) then return false end
        if ent:IsPlayerHolding() then return false end
        if ent:GetNWBool("IsInspected", false) then return false end
        if ply.IsInspecting then return false end
        if !ix.config.Get("enableEntityInspection", true) then return false end

        -- Mark entity as inspected
        ent:SetNWBool("IsInspected", true)
        ent.InspectingPlayer = ply
        ply.IsInspecting = true
        ply.InspectedEnt = ent

        -- Uncollide and freeze entities to prevent them from being pushed away during inspection
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            ent.RevertMotionEnabled = phys:IsMotionEnabled()
            phys:EnableMotion(false)
        end
        ent:SetNoDraw(true)
        
        ent.RevertCollisionGroup = ent:GetCollisionGroup()
        ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

        net.Start("InspectEnt_Start")
            net.WriteEntity(ent)
            net.WriteBool(ix.inspect.CanPickupEntity(ply, ent) != false)
        net.Send(ply)

        return true
    end

    function ix.inspect.ReleaseEntity(ply, ent)
        if IsValid(ply) then
            ply.IsInspecting = nil
            ply.InspectedEnt = nil
        end

        if IsValid(ent) and ent:GetNWBool("IsInspected", false) then
            ent.InspectingPlayer = nil
            ent:SetNWBool("IsInspected", false)
            ent:SetNoDraw(false)
            if ent.RevertCollisionGroup then
                ent:SetCollisionGroup(ent.RevertCollisionGroup)
                ent.RevertCollisionGroup = nil
            end
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) and ent.RevertMotionEnabled ~= nil then
                phys:EnableMotion(ent.RevertMotionEnabled)
                ent.RevertMotionEnabled = nil
                phys:Wake()
            end
        end
    end

    function ix.inspect.CanPickupEntity(ply, ent)
        if !ix.config.Get("enableEntityPickup", true) then
            return false
        end

        local class = ent:GetClass()
        if class == "ix_item" then
            return true
        end

        if class == "ix_inspectable" then
            return false
        end

        if string.find(class, "item_health") and ply:Health() >= ply:GetMaxHealth() then
            return false
        end
    
        if class == "item_battery" and ply:Armor() >= ply:GetMaxArmor() then
            return false
        end

        if string.find(class, "prop_") then
            return false
        end

        if hook.Run("PlayerCanPickupItem", ply, ent) == false then
            return false
        end

        return true
    end

    function ix.inspect.PickupItemEntity(client, item)
        local character = client:GetCharacter()
        local data = nil
        local invID = 0
        local action = "take"

        if (!character) then
            return
        end

        local inventory = ix.item.inventories[invID or 0]

        if (hook.Run("CanPlayerInteractItem", client, action, item, data) == false) then
            return
        end

        if (!inventory:OnCheckAccess(client)) then
            return
        end

        if (isentity(item)) then
            if (IsValid(item)) then
                local entity = item
                local itemID = item.ixItemID
                item = ix.item.instances[itemID]

                if (!item) then
                    return
                end

                item.entity = entity
                item.player = client
            else
                return
            end
        elseif (isnumber(item)) then
            item = ix.item.instances[item]

            if (!item) then
                return
            end

            item.player = client
        end

        if (item.entity) then
            if (client:GetShootPos():DistToSqr(item.entity:GetPos()) > 96 * 96) then
                return
            end
        elseif (!inventory:GetItemByID(item.id)) then
            return
        end

        if (!item.bAllowMultiCharacterInteraction and IsValid(client) and client:GetCharacter()) then
            local itemPlayerID = item:GetPlayerID()
            local itemCharacterID = item:GetCharacterID()
            local playerID = client:SteamID64()
            local characterID = client:GetCharacter():GetID()

            if (itemPlayerID and itemCharacterID and itemPlayerID == playerID and itemCharacterID != characterID) then
                client:NotifyLocalized("itemOwned")

                item.player = nil
                item.entity = nil
                return
            end
        end

        local callback = item.functions[action]

        if (callback) then
            if (callback.OnCanRun and callback.OnCanRun(item, data) == false) then
                item.entity = nil
                item.player = nil

                return
            end

            hook.Run("PlayerInteractItem", client, action, item)

            local entity = item.entity
            local result

            if (item.hooks[action]) then
                result = item.hooks[action](item, data)
            end

            if (result == nil) then
                result = callback.OnRun(item, data)
            end

            if (item.postHooks[action]) then
                -- Posthooks shouldn't override the result from OnRun
                item.postHooks[action](item, result, data)
            end

            if (result != false) then
                if (IsValid(entity)) then
                    entity.ixIsSafe = true
                    entity:Remove()
                else
                    item:Remove()
                end
            end

            item.entity = nil
            item.player = nil

            return result != false
        end
    end

    util.AddNetworkString("InspectEnt_Start")
    util.AddNetworkString("InspectEnt_End")
    util.AddNetworkString("InspectEnt_Pickup")
    util.AddNetworkString("InspectEnt_SetModel")
    util.AddNetworkString("InspectEnt_SetName")
    util.AddNetworkString("InspectItem_Start")
    util.AddNetworkString("InspectItem_End")
    util.AddNetworkString("InspectFallback_End")

    net.Receive("InspectEnt_Start", function(len, ply)
        local ent = net.ReadEntity()
        if !IsValid(ent) then return end

        ix.inspect.InspectEntity(ply, ent)
    end)

    net.Receive("InspectEnt_End", function(len, ply)
        local ent = net.ReadEntity()
        if !IsValid(ent) then return end

        ix.inspect.ReleaseEntity(ply, ent)
    end)

    net.Receive("InspectEnt_Pickup", function(len, ply)
        local ent = net.ReadEntity()
        if !IsValid(ent) then return end

        if ent:GetClass() == "ix_item" then
            ix.inspect.PickupItemEntity(ply, ent)
        else
            -- custom hook that just lets you determine "how" an item gets picked up, as there's no built-in way to say "pick up a health kit" other than teleporting it to the player
            if hook.Run("PlayerPickupItem", ply, ent) != true then
                ent:SetPos(ply:GetPos())
            end
        end
    end)

    net.Receive("InspectEnt_SetModel", function(len, ply)
        if !ply:IsAdmin() then return end
        local ent = net.ReadEntity()
        local model = net.ReadString()

        if !IsValid(ent) or ent:GetClass() != "ix_inspectable" then return end
        if !util.IsValidModel(model) then return end

        ent:SetModel(model)
        ent:PhysicsInit(SOLID_VPHYSICS)
        local physObj = ent:GetPhysicsObject()
        if IsValid(physObj) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end
    end)

    net.Receive("InspectEnt_SetName", function(len, ply)
        if !ply:IsAdmin() then return end
        local ent = net.ReadEntity()
        local name = net.ReadString()

        if !IsValid(ent) or ent:GetClass() != "ix_inspectable" then return end
        ent:SetDisplayName(name)
    end)

    net.Receive("InspectItem_End", function(len, ply)
        local id = net.ReadUInt(32)
        local item = ix.item.instances[id]
        if !item then return end

        ix.inspect.ReleaseItem(ply, item)
    end)

    net.Receive("InspectFallback_End", function(len, ply)
        ply.IsInspecting = nil
        ply.InspectedEnt = nil
        ply.InspectedItem = nil
    end)
else
    -- caches inspected entities for the shimmer option
    ix.inspect.inspected = {}

    local inspecting = false
    local inspectEnt = NULL
    local inspectItem = nil
    local cModel = NULL
    
    local animState = 0 -- 0: idle, 1: coming in, 2: inspecting, 3: returning
    local animProgress = 0
    local animDuration = 0.5 -- Animation duration (seconds)
    
    local inspectPanel = nil
    
    local startPos, startAng = Vector(), Angle()
    local curRotAng = Angle()
    
    local blurMat = Material("pp/blurscreen")
    local baseZoom = 1.85
    local dspApplied = false
    local release = false

    net.Receive("InspectEnt_Start", function()
        inspectEnt = net.ReadEntity()
        if not IsValid(inspectEnt) then return end
        local canPickup = net.ReadBool()
        
        local ply = LocalPlayer()
        local item = inspectEnt.GetItemTable and inspectEnt:GetItemTable()
        if inspectEnt:GetClass() == "ix_inspectable" then
            ix.inspect.inspected[inspectEnt:EntIndex()] = true
        end
        
        inspecting = true
        animState = 1
        animProgress = 0
        
        -- Environmental auditory deprivation (muffled effect)
        local snd = (item and item:GetInspectSound(true)) or hook.Run("GetInspectSound", ent, true)
        if snd then
            surface.PlaySound(snd)
        end
        
        startPos = inspectEnt:GetPos()
        startAng = inspectEnt:GetAngles()
        curRotAng = Angle(0, 0, 0) -- The relative rotation angle of the item in the inspection interface
        
        -- Create a fake copy that is rendered only for the client
        cModel = ClientsideModel(inspectEnt:GetModel())
        if IsValid(cModel) then
            cModel:SetNoDraw(true) -- Prevent the engine from rendering directly by itself
            cModel:SetMaterial(inspectEnt:GetMaterial())
            cModel:SetSkin(inspectEnt:GetSkin() or 0)
            cModel:SetColor(inspectEnt:GetColor())
            for i = 0, inspectEnt:GetNumBodyGroups() - 1 do
                cModel:SetBodygroup(i, inspectEnt:GetBodygroup(i))
            end
        end
        
        -- Full screen ui panel: intercept input events and draw background
        inspectPanel = vgui.Create("DPanel")
        inspectPanel:SetSize(ScrW(), ScrH())
        inspectPanel:MakePopup()
        inspectPanel:SetKeyboardInputEnabled(true)
        inspectPanel:SetMouseInputEnabled(true)
        
        local isDragging = false
        local lastMouseX, lastMouseY = 0, 0
        local targetZoomOffset = 0
        local currentZoomOffset = 0
        
        inspectPanel.OnMouseWheeled = function(s, delta)
            if animState == 2 then
                targetZoomOffset = targetZoomOffset - delta * 30
            end
        end
        
        inspectPanel.OnMousePressed = function(s, mc)
            if animState == 2 and mc == MOUSE_LEFT then
                isDragging = true
                lastMouseX, lastMouseY = gui.MousePos()
            end
        end
        
        inspectPanel.OnMouseReleased = function(s, mc)
            if mc == MOUSE_LEFT then isDragging = false end
        end
        
        inspectPanel.OnKeyCodePressed = function(s, key)
            if animState == 2 then
                -- E key to return
                if key == KEY_E or key == KEY_ESCAPE then
                    animState = 3
                    animProgress = 0
                    if IsValid(inspectEnt) then
                        startPos = inspectEnt:GetPos()
                        startAng = inspectEnt:GetAngles()
                    end
                end
            end
        end

        inspectPanel.OnKeyCodeReleased = function(s, key)
            if animState == 2 then
                if key == KEY_ENTER then
                    if canPickup then
                        net.Start("InspectEnt_Pickup")
                            net.WriteEntity(inspectEnt)
                        net.SendToServer()
                    end
                end
            end
        end
        
        inspectPanel.Think = function(s)
            if isDragging and animState == 2 then
                local mx, my = gui.MousePos()
                local dx = mx - lastMouseX
                local dy = my - lastMouseY
                lastMouseX, lastMouseY = mx, my
                
                -- Modify the inversion of the axis (according to the player's intuition, sliding up corresponds to flipping up)
                curRotAng.y = curRotAng.y - dx * 0.5
                curRotAng.p = curRotAng.p - dy * 0.5
            end
        end
        
        -- local iconCam = (item and item.GetInspectCam and item:GetInspectCam()) or
        --                 (false and item and item.iconCam) or
        --                 PositionSpawnIcon(cModel, Vector(), true)
        local name = (item and item.GetName and item:GetName()) or 
                    (inspectEnt.GetDisplayName and inspectEnt:GetDisplayName()) or
                    inspectEnt.PrintName or
                    language.GetPhrase(inspectEnt:GetClass())
        inspectPanel.Paint = function(s, w, h)
            -- Compute time interpolation
            local fraction = 0
            if animState == 1 then fraction = math.ease.OutCubic(animProgress / animDuration)
            elseif animState == 2 then fraction = 1
            elseif animState == 3 then fraction = 1 - math.ease.InCubic(animProgress / animDuration) 
            elseif animState == 4 then fraction = 0 end
            
            -- Ui rendering transition: Gaussian blur mask
            if fraction > 0.01 then
                surface.SetDrawColor(255, 255, 255, 255 * fraction)
                surface.SetMaterial(blurMat)
                for i = 1, 3 do
                    blurMat:SetFloat("$blur", fraction * 10 * (i / 3))
                    blurMat:Recompute()
                    render.UpdateScreenEffectTexture()
                    surface.DrawTexturedRect(0, 0, w, h)
                end
                
                surface.SetDrawColor(0, 0, 0, 220 * fraction)
                surface.DrawRect(0, 0, w, h)
            end
            
            -- Use the 3D camera directly on the upper layer of the 2D HUD to render the items
            if IsValid(cModel) then
                local camPos = ply:EyePos()
                local camAng = ply:EyeAngles()
                
                local radius = cModel:BoundingRadius()
                -- Wheel zoom limit calculation
                local baseDist = radius * baseZoom
                
                -- Limit the target scaling value to a reasonable range
                targetZoomOffset = math.Clamp(targetZoomOffset, -baseDist * 0.8, baseDist * 4)
                
                -- Achieve silky damped scaling transitions using the Lerp algorithm
                currentZoomOffset = Lerp(FrameTime() * 12, currentZoomOffset, targetZoomOffset)
                
                local dist = math.max(baseDist + currentZoomOffset, 15)
                
                local targetPos = camPos + camAng:Forward() * dist
                
                -- The initial front angle is facing away from the player
                local targetAng = Angle(0, camAng.y - 180, 0)
                targetAng:RotateAroundAxis(camAng:Right(), curRotAng.p)
                targetAng:RotateAroundAxis(camAng:Up(), -curRotAng.y)
                
                local renderPos = LerpVector(fraction, startPos, targetPos)
                local renderAng = LerpAngle(fraction, startAng, targetAng)
                
                -- To prevent the center of gravity of the origin of the model from being unstable, force the obb center (geometric center) to be the rotation point
                local centerOffset = cModel:OBBCenter()
                local rotatedOffset = renderAng:Forward() * centerOffset.x + renderAng:Right() * centerOffset.y + renderAng:Up() * centerOffset.z
                
                -- By multiplying the fraction dynamically tween gravity center offset, the origin deviation jitter of the start and end points is perfectly eliminated.
                cModel:SetPos(renderPos - rotatedOffset * fraction)
                cModel:SetAngles(renderAng)

                cam.Start3D(camPos, camAng, ply:GetFOV(), 0, 0, w, h, 1, 4096)
                    render.ClearDepth() -- Force drawing on top of all current visual layers
                    
                    -- Film and television level lighting and flashlight mode
                    render.SuppressEngineLighting(true)
                    render.SetLightingOrigin(renderPos)
                    
                    render.ResetModelLighting(0.1, 0.1, 0.1)
                    render.SetModelLighting(BOX_FRONT, 1.5, 1.5, 1.3)
                    render.SetModelLighting(BOX_TOP, 0.9, 0.9, 0.9)
                    render.SetModelLighting(BOX_RIGHT, 0.5, 0.5, 0.5)
                    render.SetModelLighting(BOX_LEFT, 0.5, 0.5, 0.5)
                    
                    cModel:DrawModel()
                    
                    render.SuppressEngineLighting(false)
                cam.End3D()
            end
            
            -- Ui: text rendering (put it at the end to ensure it is not covered by 3D)
            if fraction > 0.01 and animState == 2 then
                if name then
                    draw.SimpleText(name, "Trebuchet24", w / 2, h * 0.88, Color(255, 255, 255, math.min(255, fraction * 255 * 2)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                draw.SimpleText(canPickup and "[Enter] Take | [E] Close" or "[E] Close", "Trebuchet24", w / 2, h * 0.9, Color(255, 255, 255, math.min(255, fraction * 255 * 2)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)

    net.Receive("InspectItem_Start", function()
        local id = net.ReadUInt(32)
        local ply = LocalPlayer()
        inspectItem = table.Copy(ix.item.instances[id] or {})
        if next(inspectItem) == nil then inspectItem = nil return end
        
        inspecting = true
        animState = 1
        animProgress = 0
        
        -- Environmental auditory deprivation (muffled effect)
        local snd = inspectItem:GetInspectSound(true)
        if snd then
            surface.PlaySound(snd)
        end
        
        startPos, startAng = Vector(), Angle()
        curRotAng = Angle(0, 0, 0) -- The relative rotation angle of the item in the inspection interface
        
        -- Create a fake copy that is rendered only for the client
        cModel = ClientsideModel(inspectItem:GetModel())
        if !IsValid(cModel) then
            cModel = NULL
            return
        end

        cModel:SetNoDraw(true) -- Prevent the engine from rendering directly by itself
        cModel:SetSkin(inspectItem:GetSkin())

        local camPos = ply:EyePos()
        local camAng = Angle(0, 0, 0)
        local lightAng = ply:EyeAngles()

        local radius = cModel:BoundingRadius()
        local baseDist = radius * baseZoom
        local targetPos = camPos + camAng:Forward() * baseDist
        startPos = targetPos + Vector(0, 0, -90)
        startAng = Angle(0, 0, 0)
        
        -- Full screen ui panel: intercept input events and draw background
        inspectPanel = vgui.Create("DPanel")
        inspectPanel:SetSize(ScrW(), ScrH())
        inspectPanel:MakePopup()
        inspectPanel:SetKeyboardInputEnabled(true)
        inspectPanel:SetMouseInputEnabled(true)
        
        local isDragging = false
        local lastMouseX, lastMouseY = 0, 0
        local targetZoomOffset = 0
        local currentZoomOffset = 0
        
        inspectPanel.OnMouseWheeled = function(s, delta)
            if animState == 2 then
                targetZoomOffset = targetZoomOffset - delta * 30
            end
        end
        
        inspectPanel.OnMousePressed = function(s, mc)
            if animState == 2 and mc == MOUSE_LEFT then
                isDragging = true
                lastMouseX, lastMouseY = gui.MousePos()
            end
        end
        
        inspectPanel.OnMouseReleased = function(s, mc)
            if mc == MOUSE_LEFT then isDragging = false end
        end
        
        inspectPanel.OnKeyCodePressed = function(s, key)
            if animState == 2 then
                -- E key to return
                if key == KEY_E or key == KEY_ESCAPE or key == KEY_TAB then
                    animState = 3
                    animProgress = 0
                end
            end
        end
        
        inspectPanel.Think = function(s)
            if isDragging and animState == 2 then
                local mx, my = gui.MousePos()
                local dx = mx - lastMouseX
                local dy = my - lastMouseY
                lastMouseX, lastMouseY = mx, my
                
                -- Modify the inversion of the axis (according to the player's intuition, sliding up corresponds to flipping up)
                curRotAng.y = curRotAng.y - dx * 0.5
                curRotAng.p = curRotAng.p - dy * 0.5
            end
        end

        -- i didnt love how the iconCams looked as the initial angles, but feel free to delete the 'false' if you disagree
        local iconCam = (inspectItem and inspectItem.GetInspectCam and inspectItem:GetInspectCam()) or
                        (false and inspectItem and inspectItem.iconCam) or
                        PositionSpawnIcon(cModel, Vector(), true)
        local name = inspectItem and inspectItem.GetName and inspectItem:GetName()
        inspectPanel.Paint = function(s, w, h)
            -- Compute time interpolation
            local fraction = 0
            if animState == 1 then fraction = math.ease.OutCubic(animProgress / animDuration)
            elseif animState == 2 then fraction = 1
            elseif animState == 3 then fraction = 1 - math.ease.InCubic(animProgress / animDuration) 
            elseif animState == 4 then fraction = 0 end
            
            -- Ui rendering transition: Gaussian blur mask
            if fraction > 0.01 then
                surface.SetDrawColor(255, 255, 255, 255 * fraction)
                surface.SetMaterial(blurMat)
                for i = 1, 3 do
                    blurMat:SetFloat("$blur", fraction * 10 * (i / 3))
                    blurMat:Recompute()
                    render.UpdateScreenEffectTexture()
                    surface.DrawTexturedRect(0, 0, w, h)
                end
                
                surface.SetDrawColor(0, 0, 0, 220 * fraction)
                surface.DrawRect(0, 0, w, h)
            end
            
            -- Use the 3D camera directly on the upper layer of the 2D HUD to render the items
            if IsValid(cModel) then
                -- Limit the target scaling value to a reasonable range
                targetZoomOffset = math.Clamp(targetZoomOffset, -baseDist * 0.8, baseDist * 4)
                
                -- Achieve silky damped scaling transitions using the Lerp algorithm
                currentZoomOffset = Lerp(FrameTime() * 12, currentZoomOffset, targetZoomOffset)
                
                local dist = math.max(baseDist + currentZoomOffset, 15)
                targetPos = camPos + camAng:Forward() * dist
                
                -- end angle is the same as the icon's orientation. not sure why 180 vs 90 is necessary. i hate spawn icons
                local targetAng
                if iconCam.ang then
                    targetAng = iconCam.ang or iconCam.angles or Angle(0, 0, 0)
                    targetAng = Angle(targetAng.p, targetAng.y - 180, targetAng.r)
                else
                    targetAng = iconCam.angles or Angle(0, 0, 0)
                    targetAng = Angle(0, targetAng.y - 90, 0)
                end

                targetAng:RotateAroundAxis(camAng:Right(), curRotAng.p)
                targetAng:RotateAroundAxis(camAng:Up(), -curRotAng.y)
                
                local renderPos = LerpVector(fraction, startPos, targetPos)
                local renderAng = LerpAngle(fraction, startAng, targetAng)

                -- since we have weird initial angles from the manual adjustments, we basically have to remap what qualifies as "forward" to depend on the player's eye angles. it's weird, i know
                local yaw = math.Round(lightAng.y / 90) % 4 -- breaks it up into discrete 90 degree increments
                local front = {
                    [0] = {BOX_FRONT, BOX_BACK, BOX_RIGHT, BOX_LEFT},
                    [1] = {BOX_RIGHT, BOX_LEFT, BOX_BACK, BOX_FRONT},
                    [2] = {BOX_BACK, BOX_FRONT, BOX_LEFT, BOX_RIGHT},
                    [3] = {BOX_LEFT, BOX_RIGHT, BOX_FRONT, BOX_BACK},
                }
                local faces = front[yaw]
                
                -- To prevent the center of gravity of the origin of the model from being unstable, force the obb center (geometric center) to be the rotation point
                local centerOffset = cModel:OBBCenter()
                local rotatedOffset = renderAng:Forward() * centerOffset.x + renderAng:Right() * centerOffset.y + renderAng:Up() * centerOffset.z
                
                -- By multiplying the fraction dynamically tween gravity center offset, the origin deviation jitter of the start and end points is perfectly eliminated.
                cModel:SetPos(renderPos - rotatedOffset * fraction)
                cModel:SetAngles(renderAng)

                cam.Start3D(camPos, camAng, ply:GetFOV(), 0, 0, w, h, 1, 4096)
                    render.ClearDepth() -- Force drawing on top of all current visual layers
                    
                    -- Film and television level lighting and flashlight mode
                    render.SuppressEngineLighting(true)
                    render.SetLightingOrigin(camPos + lightAng:Forward() * 50)
                    
                    render.ResetModelLighting(0.1, 0.1, 0.1)
                    render.SetModelLighting(faces[1], 1.5, 1.5, 1.3) -- front
                    render.SetModelLighting(faces[2], 0.2, 0.2, 0.2) -- back
                    render.SetModelLighting(faces[3], 0.5, 0.5, 0.5) -- right
                    render.SetModelLighting(faces[4], 0.5, 0.5, 0.5) -- left
                    render.SetModelLighting(BOX_TOP,  0.9, 0.9, 0.9)
                    
                    cModel:DrawModel()
                    
                    render.SuppressEngineLighting(false)
                cam.End3D()
            end
            
            -- Ui: text rendering (put it at the end to ensure it is not covered by 3D)
            if fraction > 0.01 and animState == 2 then
                if name then
                    draw.SimpleText(name, "Trebuchet24", w / 2, h * 0.88, Color(255, 255, 255, math.min(255, fraction * 255 * 2)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                draw.SimpleText("[E] Close", "Trebuchet24", w / 2, h * 0.9, Color(255, 255, 255, math.min(255, fraction * 255 * 2)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)
    
    hook.Add("Think", "Inspect_Think", function()
        if not inspecting then return end
        
        local ft = FrameTime()
        local ply = LocalPlayer()
        
        if animState == 1 then
            animProgress = math.Clamp(animProgress + ft, 0, animDuration)
            if animState == 1 and animProgress >= animDuration then
                animState = 2
                -- call this once we enter state 2 so that any GetInspectSounds from the opening still play without DSP
                if ix.config.Get("enableInspectionDSP", true) then
                    ply:SetDSP(14, false)
                    dspApplied = true
                end
            end
        elseif animState == 3 then
            animProgress = math.Clamp(animProgress + ft, 0, animDuration)
            if animState == 3 and animProgress >= animDuration then
                -- Enter network handshake state to eliminate flickering caused by delay
                animState = 4
                release = true
                
                if IsValid(inspectPanel) then
                    inspectPanel:SetMouseInputEnabled(false)
                    inspectPanel:SetKeyboardInputEnabled(false)
                end
            end
        elseif animState == 4 then
            -- Wait seamlessly on this tick until the server actually unhides the entity
            if release or !inspectItem and (not IsValid(inspectEnt) or not inspectEnt:GetNWBool("IsInspected", true)) then
                ix.inspect.EndInspect()
            end
        end
        
        -- Enhanced version of client accidental interruption protection (death, getting on the bus, items being swallowed by the world)
        if inspecting and animState ~= 4 then
            if not IsValid(ply) or not ply:Alive() or ply:InVehicle() or (not IsValid(inspectEnt) and !inspectItem) then
                ix.inspect.EndInspect()
            end
        end
    end)

    function ix.inspect.IsInspecting()
        return inspecting, (inspectItem or inspectEnt)
    end

    function ix.inspect.EndInspect()
        inspecting = false
        release = false
        animState = 0
        if IsValid(cModel) then cModel:Remove() end
        if IsValid(inspectPanel) then inspectPanel:Remove() end
        
        if dspApplied then
            LocalPlayer():SetDSP(0, false)
            dspApplied = false
        end
        
        if inspectEnt != NULL then
            net.Start("InspectEnt_End")
                net.WriteEntity(inspectEnt)
            net.SendToServer()

            local item = (inspectEnt.GetItemTable and inspectEnt:GetItemTable())
            local snd = (item and item:GetInspectSound(false)) or hook.Run("GetInspectSound", ent, false)
            if snd then
                surface.PlaySound(snd)
            end
        elseif inspectItem then
            net.Start("InspectItem_End")
                net.WriteUInt(inspectItem.id, 32)
            net.SendToServer()

            local snd = inspectItem:GetInspectSound(false)
            if snd then
                surface.PlaySound(snd)
            end
        else
            -- fallback case that just resets the player's serverside status
            net.Start("InspectFallback_End")
            net.SendToServer()
        end

        inspectItem = nil
        inspectEnt = NULL
    end
end