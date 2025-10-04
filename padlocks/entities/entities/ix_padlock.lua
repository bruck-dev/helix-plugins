
AddCSLuaFile()

local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Padlock"
ENT.Category = "Helix - Locks"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.PhysgunDisable = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Locked")
    self:NetworkVar("String", 0, "PersistentID")
    self:NetworkVar("String", 1, "DisplayName")

    if (SERVER) then
        self:NetworkVarNotify("Locked", self.OnLockChanged)
    end
end

if (SERVER) then
    function ENT:GetLockPosition(door, normal)
        local index = door:LookupBone("handle")
        local position = door:GetPos()
        normal = normal or door:GetForward():Angle()

        if (index and index >= 1) then
            position = door:GetBonePosition(index)
        end

        position = position + normal:Forward() * 3.25
        if door:GetClass() == "prop_door_rotating" then
            position = position + normal:Up() * -2
        end

        normal:RotateAroundAxis(normal:Forward(), 180)
        normal:RotateAroundAxis(normal:Right(), 180)

        return position, normal
    end

    function ENT:SetDoor(door, position, angles)
        if (!IsValid(door) or !door:IsDoor()) then
            return
        end

        local doorPartner = door:GetDoorPartner()

        self.door = door
        self.door:DeleteOnRemove(self)
        door.ixLock = self

        if (IsValid(doorPartner)) then
            self.doorPartner = doorPartner
            self.doorPartner:DeleteOnRemove(self)
            doorPartner.ixLock = self
        end

        self:SetPos(position)
        self:SetAngles(angles)
        self:SetParent(door)
    end

    function ENT:SpawnFunction(client, trace, persistentID)
        local door = trace.Entity

        if (!IsValid(door) or !door:IsDoor()) then
            return client:Notify("You are not looking at a door!")
        elseif IsValid(door.ixLock) then
            return client:Notify("This door already has a lock!")
        end

        local normal = client:GetEyeTrace().HitNormal:Angle()
        local position, angles = self:GetLockPosition(door, normal)

        local entity = ents.Create("ix_padlock")
        entity:SetPos(trace.HitPos)
        entity:Spawn()
        entity:Activate()
        entity:SetDoor(door, position, angles)
        entity:SetLocked(true)

        if !persistentID then
            persistentID = entity:GeneratePersistentID()
        end
        entity:SetPersistentID(persistentID)

        PLUGIN:SaveData()
        return entity
    end

    function ENT:Initialize()
        self:SetModel("models/props_wasteland/prison_padlock001a.mdl")
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetUseType(SIMPLE_USE)

        self.nextUseTime = 0
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end

    function ENT:OnRemove()
        if (IsValid(self)) then
            self:SetParent(nil)
        end

        if (IsValid(self.door)) then
            self.door:Fire("unlock")
            self.door.ixLock = nil
        end

        if (IsValid(self.doorPartner)) then
            self.doorPartner:Fire("unlock")
            self.doorPartner.ixLock = nil
        end

        if (!ix.shuttingDown) then

            if self.bShouldBreak then
                local newProp = ents.Create("prop_physics")
                newProp:SetPos(self:GetPos())
                newProp:SetAngles(self:GetAngles())
                newProp:SetModel("models/props_wasteland/prison_padlock001b.mdl")
                newProp:SetSkin(self:GetSkin())
                newProp:Spawn()

                if math.random() < 0.5 then
                    newProp:EmitSound("physics/metal/metal_box_break1.wav")
                else
                    newProp:EmitSound("physics/metal/metal_box_break2.wav")
                end

                timer.Simple(15, function()
                    if IsValid(newProp) then
                        newProp:Remove()
                    end
                end)
            end

            PLUGIN:SaveData()
        end
    end

    function ENT:OnLockChanged(name, bWasLocked, bLocked)
        if (!IsValid(self.door)) then
            return
        end

        if (bLocked) then
            self:EmitSound("doors/default_locked.wav")
            self.door:Fire("lock")
            self.door:Fire("close")

            if (IsValid(self.doorPartner)) then
                self.doorPartner:Fire("lock")
                self.doorPartner:Fire("close")
            end

            self:SetModel("models/props_wasteland/prison_padlock001a.mdl")
        else
            self:EmitSound("doors/default_locked.wav")
            self.door:Fire("unlock")

            if (IsValid(self.doorPartner)) then
                self.doorPartner:Fire("unlock")
            end

            self:SetModel("models/props_wasteland/prison_padlock001b.mdl")
        end
    end

    function ENT:Toggle(client)
        if (self.nextUseTime > CurTime()) then
            return
        end

        if self:CanUse(client) then
            local time = ix.config.Get("doorLockTime", 1)

            if self:GetLocked() then
                client:SetAction("Unlocking...", time)
            else
                client:SetAction("Locking...", time)
            end

            local lock = self
            client:SetNetVar("usingPadlock", true)
            client:DoStaredAction(lock, function()
                if IsValid(lock) then
                    lock:SetLocked(!lock:GetLocked())
                    client:SetNetVar("usingPadlock", nil)

                    lock.nextUseTime = CurTime() + 1
                end
            end, time, function()
                if (IsValid(client)) then
                    client:SetAction()
                    client:SetNetVar("usingPadlock", nil)
                end
            end)
        else
            self.door:Use(client) -- mimic opening the door instead
            self.nextUseTime = CurTime() + 1
        end
    end

    function ENT:Use(client)
        if !client:GetNetVar("usingPadlock", false) then
            if client:KeyDown(IN_SPEED) and self:CanUse(client) then
                self:PickUp(client)
            else
                self:Toggle(client)
            end
        end
    end

    -- technically these aren't unique but the odds of it generating the same password twice are basically 0 lol. call it a manufacturer's defect
    function ENT:GeneratePersistentID()
        local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
    
        local password = ""
        local ch
        for i = 1, 16 do
            ch = math.random(1, #charset)
            password = password .. charset:sub(ch, ch)
        end
        return password
    end

    function ENT:PickUp(client)
        local time = ix.config.Get("doorLockTime", 1) / 2

        -- extra unlock time for the immersion or something
        if self:GetLocked() then
            time = time * 2
        end

        local lock = self
        client:SetAction("Retrieving Lock...", time)
        client:SetNetVar("usingPadlock", true)
        client:DoStaredAction(lock, function()
            if IsValid(lock) then
                if !client:GetCharacter():GetInventory():Add("padlock", 1, {persistentID = lock:GetPersistentID(), padlockName = lock:GetDisplayName()}) then
                    ix.item.Spawn("padlock", client, nil, nil, {padlock = lock:GetPersistentID(), padlockName = lock:GetDisplayName()})
                end

                local snd = {"physics/metal/weapon_impact_soft1.wav", "physics/metal/weapon_impact_soft2.wav", "physics/metal/weapon_impact_soft3.wav"}
                lock:EmitSound(snd[math.random(1, #snd)], 75, 80)

                if lock:GetLocked() then
                    lock:EmitSound("doors/default_locked.wav")
                end

                lock:Remove()
                client:SetNetVar("usingPadlock", nil)
            end
        end, time, function()
            if (IsValid(client)) then
                client:SetAction()
                client:SetNetVar("usingPadlock", nil)
            end
        end)
    end
else
    ENT.PopulateEntityInfo = true

    function ENT:OnPopulateEntityInfo(tooltip)
        if self:CanUse(LocalPlayer()) then
            local text = tooltip:AddRow("name")
            text:SetImportant()
            text:SetText(self:GetDisplayName())
            text:SizeToContents()
        end
    end

    function ENT:Draw()
        self:DrawModel()
    end
end

function ENT:CanUse(client)
    for _, v in ipairs(client:GetCharacter():GetInventory():GetItemsByUniqueID("padlock_key")) do
        local pid = v:GetData("persistentID", nil)
        if pid and pid == self:GetPersistentID() then
            return true
        end
    end
end