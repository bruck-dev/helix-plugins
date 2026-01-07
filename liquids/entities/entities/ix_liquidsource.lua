
ENT.Type = "anim"
ENT.PrintName = "Liquid Source"
ENT.Category = "Helix - Liquids"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "DisplayName")
    self:NetworkVar("String", 1, "StoredModel") -- applied as the base model if the duplicator is used to clone the entity
    self:NetworkVar("String", 2, "Liquid")

    self:NetworkVar("Int", 0, "MaxVolume")
    self:NetworkVar("Int", 1, "CurVolume")

    self:NetworkVar("Bool", 0, "IsInfinite")
    self:NetworkVar("Bool", 1, "ShouldShowTooltip")
end

if SERVER then
    local PLUGIN = PLUGIN

    function ENT:Initialize()
        -- if duplicated, use the copied model text instead of the default
        self:SetModel(self:GetStoredModel())

        if self:GetModel() == "models/error.mdl" then
            self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
            self:SetStoredModel("models/hunter/blocks/cube025x025x025.mdl")
        end

        self:SetUseType(SIMPLE_USE)
        self:SetMoveType(MOVETYPE_NONE)
        self:DrawShadow(true)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)

        if !self:GetDisplayName() or self:GetDisplayName() == "" then
            self:SetDisplayName("Liquid Source")
        end

        if !self:GetMaxVolume() or self:GetMaxVolume() == 0 then
            self:SetMaxVolume(1)
        end

        if !self:GetCurVolume() then
            self:SetCurVolume(0)
        end
        
        self:SetIsInfinite(self:GetIsInfinite() or false)
        self:SetShouldShowTooltip(self:GetShouldShowTooltip() or true)

        self.receivers = {}

        local physObj = self:GetPhysicsObject()

        if (IsValid(physObj)) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end

        timer.Simple(1, function()
            if (IsValid(self)) then
                self:SetAnim()
            end
        end)
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end

    function ENT:SpawnFunction(client, trace)
        local angles = (trace.HitPos - client:GetPos()):Angle()
        angles.r = 0
        angles.p = 0
        angles.y = angles.y + 180

        local entity = ents.Create("ix_liquidsource")
        entity:SetPos(trace.HitPos)
        entity:SetAngles(angles)
        entity:Spawn()

        PLUGIN:SaveData()

        return entity
    end

    function ENT:OnRemove()
        if !ix.shuttingDown then
            PLUGIN:SaveData()
        end
    end

    function ENT:Use(activator)
    end
else
    function ENT:Think()
        if ((self.nextAnimCheck or 0) < CurTime()) then
            self:SetAnim()
            self.nextAnimCheck = CurTime() + 60
        end

        self:SetNextClientThink(CurTime() + 0.25)

        return true
    end

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:OnRemove()
    end

    ENT.PopulateEntityInfo = true

    function ENT:OnPopulateEntityInfo(container)
        if self:GetShouldShowTooltip() then
            local name = container:AddRow("name")
            name:SetImportant()
            name:SetText(self:GetDisplayName())
            name:SizeToContents()

            local liquid = ix.liquids.Get(self:GetLiquid())
            if liquid then
                local data = container:AddRow("data")
                local vol = self:GetCurVolume()
            
                if self:GetIsInfinite() then
                    data:SetText("Contains " .. liquid:GetName())
                else
                    if(vol <= 0) then
                        data:SetText("Capacity: " .. ix.liquids.ConvertUnit(self:GetMaxVolume()) .. "\nEmpty")
                    else 
                        data:SetText("Capacity: " .. ix.liquids.ConvertUnit(self:GetMaxVolume()) .. "\n" ..
                        "Current Amount: " .. ix.liquids.ConvertUnit(self:GetCurVolume()) .. "\n" ..
                        "Contains " .. liquid:GetName())
                    end
                end
                data:SetFont("ixGenericFont")
                data:SizeToContents()
            end
        end
    end
end

function ENT:CanAccess(client)
    return client:IsAdmin()
end

function ENT:SetAnim()
    for k, v in ipairs(self:GetSequenceList()) do
        if (v:lower():find("idle") and v != "idlenoise") then
            return self:ResetSequence(k)
        end
    end

    if (self:GetSequenceCount() > 1) then
        self:ResetSequence(4)
    end
end

function ENT:TakeVolume(vol)
    local newVol = self:GetCurVolume() - vol
    if newVol < 0 then
        newVol = 0
    end
    self:SetCurVolume(newVol)
end

function ENT:AddVolume(vol)
    local newVol = self:GetCurVolume() + vol
    if newVol > self:GetMaxVolume() then
        newVol = self:GetMaxVolume()
    end
    self:SetCurVolume(self:GetMaxVolume())
end