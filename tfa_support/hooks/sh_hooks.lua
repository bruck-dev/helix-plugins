
local PLUGIN = PLUGIN

function PLUGIN:InitializedConfig()

    if ix.config.Get("generateWeaponItems(Tfa)", false) then
        ix.tfa.GenerateWeapons()
    end
    if ix.config.Get("generateAttachmentItems(Tfa)", false) then
        ix.tfa.GenerateAttachments()
    end

    -- go through the list again to cover manually created items. sorta inefficient, but necessary
    for k, v in pairs(ix.item.list) do
        if v.isTFAAttachment and !v.isGenerated then
            ix.tfa.attachments[v:GetAttachment()] = k
        elseif v.isTFAWeapon and v.isGrenade and !v.isGenerated then
            ix.tfa.grenades[v.class] = true
        end
    end

end

-- all this does is ensure the grenades are removed from invs when thrown; it normally results in a null entity when called normally so i modified it to predict the player instead of mandating the use of getowner
function PLUGIN:InitializedPlugins()
    local SWEP = weapons.GetStored("tfa_ins2_nade_base")
    if SWEP then
        function SWEP:DoAmmoCheck()
            if self:Clip1() <= 0 then
                if self:Ammo1() <= 0 then
                    self.removeOwner = self:GetOwner()
                    timer.Simple(0, function()
                        if IsValid(self) and self:OwnerIsValid() and SERVER then
                            self.removeOwner:StripWeapon(self:GetClass())
                        end
                    end)
                else
                    self:TakePrimaryAmmo(1, true)
                    self:SetClip1(1)
                end
            end
        end
    end

    SWEP = weapons.GetStored("tfa_nade_base")
    if SWEP then
        function SWEP:Deploy()
            if self:Clip1() <= 0 then
                if self:Ammo1() <= 0 then
                    if self:GetOwner():IsPlayer() then
                        if CLIENT and not sp then
                            self:SwitchToPreviousWeapon()
                        elseif SERVER and not nzombies then
                            self.removeOwner = self:GetOwner()
                            if sp then
                                self:CallOnClient("SwitchToPreviousWeapon", "")
                                local ply = removeOwner
                                local classname = self:GetClass()
                                local wep = self
                                timer.Simple(0, function() ply:StripWeapon(classname) end)
                            else
                                self:GetOwner():StripWeapon(self:GetClass())
                                return
                            end
                        end
                    end
                else
                    self:TakePrimaryAmmo(1, true)
                    self:SetClip1(1)
                end
            end

            self:SetNW2Bool("Underhanded", false)

            self.oldang = self:GetOwner():EyeAngles()
            self.anga = Angle()
            self.angb = Angle()
            self.angc = Angle()

            self:CleanParticles()

            return BaseClass.Deploy(self)
        end
    end
end

-- CUSTOMIZATION CHECK HOOKS
do
    function PLUGIN:NearWeaponBench(client)
        for _, bench in ipairs(ents.FindByClass("ix_tfa_weapon_bench")) do
            if (client:GetPos():DistToSqr(bench:GetPos()) < 100 * 100) then
                return true
            end
        end
    end

    function PLUGIN:IsCustomizing(client, weapon)
        if weapon and IsValid(weapon) and (weapon.Base and string.find(weapon.Base, "tfa_")) then
            return weapon:GetCustomizing()
        end
    end

    function PLUGIN:StartCustomizing(client, weapon)
        if weapon and IsValid(weapon) and (weapon.Base and string.find(weapon.Base, "tfa_")) then
            weapon:SetCustomizing(true)
        end
    end
end