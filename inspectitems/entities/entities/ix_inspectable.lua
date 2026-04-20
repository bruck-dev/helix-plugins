
ENT.Type = "anim"
ENT.PrintName = "Inspectable"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.bNoPersist = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "DisplayName")
end

if (SERVER) then
    local PLUGIN = PLUGIN

    function ENT:Initialize()

        self:SetModel("models/props_lab/frame002a.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)

        local physObj = self:GetPhysicsObject()
        if IsValid(physObj) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end

        self:SetDisplayName("Inspectable")

        PLUGIN:SaveData()
    end

    function ENT:OnRemove()
        if !ix.shuttingDown then
            PLUGIN:SaveData()
        end
    end
else
    local shimmerMat = Material("models/shiny")
    local ANIM_SPEED = 0.33             -- in cycles per second
    local DUTY_CYCLE = 0.60             -- % of the wave that is considered the "on" time; 0.6 --> 60% on, 40% off
    local SHIMMER_INTENSITY = 0.08      -- intensity multiplier or the shimmer pass, relative to the pulse strength
    local GLOW_INTENSITY = 0.40         -- additive for color modulation

    function ENT:Draw()
        self:DrawModel()

        local inspected = ix.inspect.inspected[self:EntIndex()]
        local shouldShimmer = ix.config.Get("enableInspectableShimmer", true) and ix.option.Get("enableInspectableShimmer", true) and (!inspected or (inspected and ix.option.Get("enableInspectedShimmer", false)))

        if shouldShimmer then
            -- crazy math that just creates a continuous wave, shifts it to be between 0 and 1 instead of -1 and 1, and then only takes DUTY_CYCLE % of the wave as the "on" time
            local pulse = math.sin(CurTime() * (ANIM_SPEED * (2 * math.pi))) * 0.5 + 0.5
            local anim = math.max(0, (pulse - DUTY_CYCLE) / (1 - DUTY_CYCLE))
        
            -- base shimmer effect
            render.SetBlend(SHIMMER_INTENSITY * anim)
            render.SetColorModulation(1.2 + GLOW_INTENSITY, 1.15 + GLOW_INTENSITY, 1.0 + GLOW_INTENSITY)
            render.MaterialOverride(shimmerMat)

            render.SuppressEngineLighting(true)
            render.ResetModelLighting(1, 1, 1)
            render.SetModelLighting(BOX_FRONT, 1, 1, 1)
            self:DrawModel()
            render.SuppressEngineLighting(false)

            render.MaterialOverride(nil)
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
    end

    function ENT:OnRemove()
        ix.inspect.inspected[self:EntIndex()] = nil
    end
end