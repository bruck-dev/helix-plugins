
local PLUGIN = PLUGIN

function PLUGIN:InitializedPlugins()
    local SWEP = weapons.GetStored("mg_base")

    -- shared sh_attach.lua overrides
    do
        function SWEP:CanCustomize()
            if ix.config.Get("useWeaponBenches(MWB)", true) then
                if !hook.Run("NearWeaponBench", self:GetOwner()) then
                    return false
                end
            end

            return true
        end

        function SWEP:Attach(slot, attIndex, bInit)
            if (self.Customization[slot] == nil) then
                return
            end

            local client = self:GetOwner()
            local char = client:GetCharacter()
            if !char then return end

            local freeAtts = ix.config.Get("freeAttachments(MWB)", false)
            local attachmentClass = self.Customization[slot][attIndex]
            
            -- check if we need to refund the old one
            local oldID = self:GetAllAttachmentsInUse()[slot].ClassName
            local newID
            if !bInit and (freeAtts or oldID == self.Customization[slot][1]) then
                oldID = nil
            end

            -- this takes some explaining: this is checked on both server and client, but the server does first; if the item is removed, the client won't ever see it by the time it runs
            -- attIndex 1 is the 'default' empty attachment state, so it should be free
            if (attIndex != 1) and !bInit and !ix.mwb.IsFreeAttachment(attachmentClass) and !freeAtts then
                local inv = char:GetInventory()
                if !inv then return end

                local item
                local id = ix.mwb.GetItemForAttachment(attachmentClass)
                if !id then return end

                for _, v in pairs(inv:GetItems(false)) do
                    if v.uniqueID == id then
                        newID = v.id
                        break
                    end
                end
                if !newID then return end

                local itemTable = ix.item.Get(id)
                if itemTable and !itemTable:HasTool(client) then return end
            end

            self:CreateAttachmentForUse(attachmentClass)

            --BUILD:
            local inspectAnim = self.Animations["Inspect"].Sequences[1]

            self:BuildCustomizedGun()

            --reset inspect animation
            if (CLIENT) then
                local inspectDelta = self.FreezeInspectDelta || 0.15

                if (self:Clip1() <= 0 && self.EmptyFreezeInspectDelta) then
                    inspectDelta = self.EmptyFreezeInspectDelta
                end

                if (self.Animations["Inspect"].Sequences[1] != inspectAnim || self:HasFlag("Drawing")) then
                    self:GetViewModel():UpdateAnimation()
                end
                
                self:GetViewModel():SetCycle(inspectDelta)

                -- tell the server to add the attachment to the weapon item's data, and remove the linked att item if needed
                if !bInit then
                    net.Start("ixMWBAttachmentAdded")
                        net.WriteUInt(client:GetCharacter():GetID(), 32)
                        net.WriteUInt(self:EntIndex(), 32)
                        net.WriteUInt(slot, 8)
                        if newID then
                            net.WriteString(ix.item.instances[newID]:GetAttachment())
                        else
                            net.WriteString(attachmentClass)
                        end
                        net.WriteBool(newID != nil)
                        if newID then
                            net.WriteUInt(newID, 32)
                        end
                    net.SendToServer()

                    -- refund old attachment if needed
                    if oldID then
                        local oldItem = ix.mwb.GetItemForAttachment(oldID)
                        if oldItem then
                            net.Start("ixMWBAttachmentRemoved")
                                net.WriteUInt(client:GetCharacter():GetID(), 32)
                                net.WriteString(oldItem)
                            net.SendToServer()
                        end
                    end
                end
            end
        end

        -- this one is great, if the first time you open the customization window by pressing E on a workbench, it throws a clientside error because the base uses 'c' uninitialized lol
        if CLIENT then
            local maxStats = 10
            local blurMaterial = Material("mg/blur")
            local function getOriginalStat(original, table)
                for i, v in pairs(table) do
                    if !original[v] then return nil end
                    original = original[v]
                end

                return original
            end
            local function lengthCalculate(curAnim)
                if curAnim then
                    return curAnim.Length / (curAnim.Fps / 30)
                end

                return nil
            end

            local function StatPageAdvanced(panel, self)
                local scale = ScrH() / 1080
                local spacing = 30 * scale
                local x,y = ScrW() * 0.79, ScrH() * 0.3
                local linespace = spacing*1.75

                local original = weapons.Get(self:GetClass()) --inheritance gotta copy
                local xLeftOffset = getLanguageCoord("xLeftOffset")
                local xOffset = x + 150 - (xLeftOffset/2) * scale
                local statBeforeLineY = y - (maxStats * 17.5) * scale + 20

                if LocalPlayer():KeyDown(IN_USE) then
                    surface.SetMaterial(blurMaterial)
                    surface.SetDrawColor(255,255,255,255)
                    for i = 1, 10, 1 do
                        render.UpdateScreenEffectTexture()
                        surface.DrawTexturedRect(x - 30 * scale, statBeforeLineY - 20, 325 * scale, 32*(c or 1)) -- feel like i should PR this or something
                    end
                end

                c = 1

                surface.SetDrawColor(255, 255, 255, 255)
                
                -- DAMAGE

                draw.SimpleTextOutlined(MWBLTL.Get("CuzMenu_Nom_Text11"), "mgbase_firemode", xOffset, statBeforeLineY, whiteColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 20))

                if self.Bullet.Damage then
                    statBeforeLineY = self:DrawStat("Damage", "", c, original.Bullet.Damage[1] * (original.Bullet.HeadshotMultiplier || 1), self.Bullet.Damage[1] * (self.Bullet.HeadshotMultiplier || 1))
                    c = c + 1

                    statBeforeLineY = self:DrawStat("HeadshotDamage", "", c, original.Bullet.HeadshotMultiplier || 1, self.Bullet.HeadshotMultiplier || 1, self.Bullet.Damage[1] * 2)
                    c = c + 1
                end

                if self.Bullet.DropOffStartRange then
                    statBeforeLineY = self:DrawStat("EffectiveRange", MWBLTL.Get("CuzMenu_Nom_Text9"), c, original.Bullet.DropOffStartRange, self.Bullet.DropOffStartRange)
                    c = c + 1
                end

                if self.Bullet.EffectiveRange then
                    statBeforeLineY = self:DrawStat("Range", MWBLTL.Get("CuzMenu_Nom_Text9"), c, original.Bullet.EffectiveRange, self.Bullet.EffectiveRange)
                    c = c + 1
                end

                if self.Primary.RPM then
                    statBeforeLineY = self:DrawStat("RPM", "", c, original.Primary.RPM, self.Primary.RPM)
                    c = c + 1
                end

                if self.Bullet.Penetration then
                    statBeforeLineY = self:DrawStat("PenetrationThickness", "", c, getOriginalStat(original.Bullet, {"Penetration", "Thickness"}), self.Bullet.Penetration.Thickness)
                    c = c + 1
                end

                if self.Projectile then
                    statBeforeLineY = self:DrawStat("ProjectileSpeed", "", c, getOriginalStat(original, {"Projectile", "Speed"}), self.Projectile.Speed)
                    c = c + 1
                end
                
                -- ACCURACY

                draw.SimpleTextOutlined(MWBLTL.Get("CuzMenu_Nom_Text12"), "mgbase_firemode", xOffset, statBeforeLineY + linespace, whiteColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 20))
                c = c + 2

                if self.Cone.Hip then
                    statBeforeLineY = self:DrawStat("Accuracy", "", c, original.Cone.Hip, self.Cone.Hip, 100)
                    c = c + 1
                end
                
                if self.Cone.Ads then
                    statBeforeLineY = self:DrawStat("AimAccuracy", "", c, original.Cone.Ads, self.Cone.Ads, 100)
                    c = c + 1
                end

                if self.Cone.TacStance then
                    statBeforeLineY = self:DrawStat("TacAccuracy", "", c, original.Cone.TacStance, self.Cone.TacStance, 100)
                    c = c + 1
                end

                if self.Cone.Increase then
                    statBeforeLineY = self:DrawStat("ConeIncrease", "", c, original.Cone.Increase, self.Cone.Increase, 100)
                    c = c + 1
                end

                if self.Zoom.IdleSway then
                    statBeforeLineY = self:DrawStat("IdleSway", "", c, original.Zoom.IdleSway, self.Zoom.IdleSway, 100)
                    c = c + 1
                end

                -- CONTROL
                draw.SimpleTextOutlined(MWBLTL.Get("CuzMenu_Nom_Text13"), "mgbase_firemode", xOffset, statBeforeLineY + linespace, whiteColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 20))
                c = c + 2

                if self.Recoil.Vertical then
                    statBeforeLineY = self:DrawStat("VerticalRecoil", "", c, original.Recoil.Vertical[2], self.Recoil.Vertical[2], 10)
                    c = c + 1
                end

                if self.Recoil.Horizontal then
                    statBeforeLineY = self:DrawStat("HorizontalRecoil", "", c, original.Recoil.Horizontal[2], self.Recoil.Horizontal[2], 10)
                    c = c + 1
                end

                if self.Recoil.AdsMultiplier then
                    statBeforeLineY = self:DrawStat("ADSRecoil", "%", c, original.Recoil.AdsMultiplier, self.Recoil.AdsMultiplier, 100)
                    c = c + 1
                end
                
                -- HANDLING
                draw.SimpleTextOutlined(MWBLTL.Get("CuzMenu_Nom_Text14"), "mgbase_firemode", xOffset, statBeforeLineY + linespace, whiteColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 20))
                c = c + 2
                
                local reloadAnimIndex
                local oldAnim
                local curAnim
                if self:GetAnimation("Reload_Loop") then
                    reloadAnimIndex = self:ChooseReloadLoopAnim()
                    oldAnim = lengthCalculate(original.Animations.Reload_Loop)
                    curAnim = self:GetAnimation(reloadAnimIndex)
                elseif self:GetAnimation("Reload") then
                    reloadAnimIndex = self:ChooseReloadAnim()
                    oldAnim = lengthCalculate(original.Animations.Reload)
                    curAnim = self:GetAnimation(reloadAnimIndex)
                end

                if curAnim then
                    self:DrawStat("ReloadLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, oldAnim, self:GetAnimLength(reloadAnimIndex))
                    c = c + 1
                end
                
                if self:GetAnimation("Ads_In") then
                    self:DrawStat("AimLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, lengthCalculate(original.Animations.Ads_In), self:GetAnimLength("Ads_In"))
                    c = c + 1
                end

                if self:GetAnimation("Sprint_Out") then
                    self:DrawStat("SprintLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, lengthCalculate(original.Animations.Sprint_Out), self:GetAnimLength("Sprint_Out"))
                    c = c + 1
                end

                if self:GetAnimation("Draw") then
                    self:DrawStat("DrawLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, lengthCalculate(original.Animations.Draw), self:GetAnimLength("Draw"))
                    c = c + 1
                end

                surface.SetAlphaMultiplier(1)
            end
            local function StatPageSimple(panel, self)
                if !self:GetOwner():KeyDown(IN_USE) then
                    return
                end
                local scale = ScrH() / 1080
                local spacing = 30 * scale
                local x,y = ScrW() * 0.05, ScrH() * 0.325

                local original = weapons.Get(self:GetClass()) --inheritance gotta copy
                local c = 1
                
                if self.Bullet.Damage then
                    self:DrawStat("DamageClose", "", c, original.Bullet.Damage[1], self.Bullet.Damage[1])
                    c = c + 1
                end

                if self.Bullet.DropOffStartRange then
                    statBeforeLineY = self:DrawStat("EffectiveRange", MWBLTL.Get("CuzMenu_Nom_Text9"), c, original.Bullet.DropOffStartRange, self.Bullet.DropOffStartRange)
                    c = c + 1
                end

                if self.Bullet.EffectiveRange then
                    statBeforeLineY = self:DrawStat("Range", MWBLTL.Get("CuzMenu_Nom_Text9"), c, original.Bullet.EffectiveRange, self.Bullet.EffectiveRange)
                    c = c + 1
                end

                if self.Primary.RPM then
                    statBeforeLineY = self:DrawStat("RPM", "", c, original.Primary.RPM, self.Primary.RPM)
                    c = c + 1
                end
                
                c = c + 1

                if self.Cone.Hip then
                    statBeforeLineY = self:DrawStat("Accuracy", "", c, original.Cone.Hip, self.Cone.Hip, 100)
                    c = c + 1
                end
                
                if self.Cone.Ads then
                    statBeforeLineY = self:DrawStat("AimAccuracy", "", c, original.Cone.Ads, self.Cone.Ads, 100)
                    c = c + 1
                end
                
                if self.Recoil.Vertical then
                    statBeforeLineY = self:DrawStat("VerticalRecoil", "", c, original.Recoil.Vertical[2], self.Recoil.Vertical[2])
                    c = c + 1
                end

                if self.Recoil.Horizontal then
                    statBeforeLineY = self:DrawStat("HorizontalRecoil", "", c, original.Recoil.Horizontal[2], self.Recoil.Horizontal[2])
                    c = c + 1
                end
                
                c = c + 1
                
                local reloadAnimIndex
                local oldAnim
                local curAnim
                if self:GetAnimation("Reload_Loop") then
                    reloadAnimIndex = self:ChooseReloadLoopAnim()
                    oldAnim = lengthCalculate(original.Animations.Reload_Loop)
                    curAnim = self:GetAnimation(reloadAnimIndex)
                elseif self:GetAnimation("Reload") then
                    reloadAnimIndex = self:ChooseReloadAnim()
                    oldAnim = lengthCalculate(original.Animations.Reload)
                    curAnim = self:GetAnimation(reloadAnimIndex)
                end

                if curAnim then
                    self:DrawStat("ReloadLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, oldAnim, self:GetAnimLength(reloadAnimIndex))
                    c = c + 1
                end
                
                if self:GetAnimation("Ads_In") then
                    self:DrawStat("AimLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, lengthCalculate(original.Animations.Ads_In), self:GetAnimLength("Ads_In"))
                    c = c + 1
                end

                if self:GetAnimation("Sprint_Out") then
                    self:DrawStat("SprintLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, lengthCalculate(original.Animations.Sprint_Out), self:GetAnimLength("Sprint_Out"))
                    c = c + 1
                end

                if self:GetAnimation("Draw") then
                    self:DrawStat("DrawLength", MWBLTL.Get("CuzMenu_Nom_Text10"), c, lengthCalculate(original.Animations.Draw), self:GetAnimLength("Draw"))
                    c = c + 1
                end

                surface.SetAlphaMultiplier(1)
            end

            function SWEP:DrawStats(panel)
                if ScrH() > 875 then
                    StatPageAdvanced(panel, self)
                else
                    StatPageSimple(panel, self)
                end
            end
        end
    end
end

function PLUGIN:InitializedConfig()
    if ix.config.Get("generateWeaponItems(MWB)", false) then
        ix.mwb.GenerateWeapons()
    end
    if ix.config.Get("generateAttachmentItems(MWB)", false) then
        ix.mwb.GenerateAttachments()
    end

    -- go through the list again to cover manually created items. sorta inefficient, but necessary
    for k, v in pairs(ix.item.list) do
        if v.isMWBAttachment and !v.isGenerated then
            ix.mwb.attachments[v:GetAttachment()] = k
        elseif v.isMWBWeapon and v.isGrenade and !v.isGenerated then
            ix.mwb.grenades[v.class] = true
        end
    end
end

-- CUSTOMIZATION CHECK HOOKS
do
    function PLUGIN:NearWeaponBench(client)
        for _, bench in ipairs(ents.FindByClass("ix_mwb_weapon_bench")) do
            if (client:GetPos():DistToSqr(bench:GetPos()) < 100 * 100) then
                return true
            end
        end
    end

    function PLUGIN:IsCustomizing(client, weapon)
        if weapons.IsBasedOn(weapon:GetClass(), "mg_base") then
            return weapon:HasFlag("Customizing")
        end
    end

    function PLUGIN:StartCustomizing(client, weapon)
        if weapons.IsBasedOn(weapon:GetClass(), "mg_base") and !weapon:HasFlag("Customizing") then
            if SERVER then
                weapon:TrySetTask("Customize")

                -- dont ask me why this wrapper is necessary, i have no idea
                if !game.SinglePlayer() then
                    net.Start("ixMWBSetCustomize")
                        net.WriteUInt(weapon:EntIndex(), 32)
                        net.WriteBool(true)
                    net.Send(client)
                end
            else
                net.Start("ixMWBSetCustomize")
                    net.WriteUInt(client:GetCharacter():GetID(), 32)
                    net.WriteUInt(weapon:EntIndex(), 32)
                    net.WriteBool(true)
                net.SendToServer()
            end
            return true
        end
    end

    function PLUGIN:StopCustomizing(client, weapon)
        if weapons.IsBasedOn(weapon:GetClass(), "mg_base") and weapon:HasFlag("Customizing") then
            if SERVER then
                weapon:RemoveFlag("Customizing")
                weapon:TrySetTask("Customize")

                if !game.SinglePlayer() then
                    net.Start("ixMWBSetCustomize")
                        net.WriteUInt(weapon:EntIndex(), 32)
                        net.WriteBool(false)
                    net.Send(client)
                end
            else
                weapon:RemoveFlag("Customizing")
                net.Start("ixMWBSetCustomize")
                    net.WriteUInt(client:GetCharacter():GetID(), 32)
                    net.WriteUInt(weapon:EntIndex(), 32)
                    net.WriteBool(false)
                net.SendToServer()
            end
            return true
        end
    end
end

hook.Add("EntityRemoved", "MWBRemoveGrenade", function(entity)
    if (ix.mwb.grenades[entity:GetClass()]) then
        local client = entity:GetOwner()
        if (IsValid(client) and client:IsPlayer() and client:GetCharacter()) then
            local ammoName = game.GetAmmoName(entity:GetPrimaryAmmoType())
            if (isstring(ammoName) and client:GetAmmoCount(ammoName) < 1 and entity:Clip1() < 1 and entity.ixItem and entity.ixItem.Unequip) then
                entity.ixItem:Unequip(client, false, true)
            end
        end
    end
end)