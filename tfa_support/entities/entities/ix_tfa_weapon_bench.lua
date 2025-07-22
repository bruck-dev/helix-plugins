
if !TFA then return end

ENT.Type = "anim"
ENT.PrintName = "Weapon Workbench"
ENT.Category = "Helix - TFA"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.bNoPersist = true

if (SERVER) then
    local PLUGIN = PLUGIN

    function ENT:Initialize()

        self:SetModel("models/props_wasteland/controlroom_desk001b.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)

        local physObj = self:GetPhysicsObject()

        if (IsValid(physObj)) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end

        PLUGIN:SaveData()
    end

    function ENT:Use(activator)
        if IsValid(activator) and (activator:GetPos():DistToSqr(self:GetPos()) < 100 * 100) and activator:GetCharacter() then
            local weapon = activator:GetActiveWeapon()

            if weapon and IsValid(weapon) then
                hook.Run("StartCustomizing", activator, weapon)
            end
        end
    end
else
    ENT.PopulateEntityInfo = true

    function ENT:OnPopulateEntityInfo(tooltip)

        if ix.option.Get("showWeaponBenchTooltip(Tfa)", true) then
            local name = tooltip:AddRow("name")
            name:SetImportant()
            name:SetText(self.PrintName)
            name:SizeToContents()

            local description = tooltip:AddRow("description")
            description:SetText("A workbench where you can customize your weapons with attachments.")
            description:SizeToContents()
        end
    end

    function ENT:Draw()
        self:DrawModel()
    end
end