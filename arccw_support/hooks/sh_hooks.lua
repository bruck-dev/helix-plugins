
local PLUGIN = PLUGIN

function PLUGIN:InitializedPlugins()
    local SWEP = weapons.GetStored("arccw_base")

    -- shared sh_attach.lua overrides
    do
        function SWEP:Attach(slot, attname, silent, noadjust, bypass)
            silent = silent or false
            local attslot = self.Attachments[slot]
            if !attslot then return end
            if attslot.Installed == attname then return end
            if attslot.Internal then return end

            -- Make an additional check to see if we can detach the current attachment
            if attslot.Installed and !ArcCW:PlayerCanAttach(self:GetOwner(), self, attslot.Installed, slot, attname) then
                if CLIENT and !silent then
                    surface.PlaySound("items/medshotno1.wav")
                end
                return
            end

            if !bypass and !ArcCW:PlayerCanAttach(self:GetOwner(), self, attname, slot, false) then
                if CLIENT and !silent then
                    surface.PlaySound("items/medshotno1.wav")
                end
                return
            end

            local pick = self:GetPickX()

            if pick > 0 and self:CountAttachments() >= pick and !attslot.FreeSlot
                    and !attslot.Installed then
                if CLIENT and !silent then
                    surface.PlaySound("items/medshotno1.wav")
                end
                return
            end

            local atttbl = ArcCW.AttachmentTable[attname]

            if !atttbl then return end
            if !ArcCW:SlotAcceptsAtt(attslot.Slot, self, attname) then return end
            if !self:CheckFlags(atttbl.ExcludeFlags, atttbl.RequireFlags) then return end
            if !bypass and !self:PlayerOwnsAtt(attname) then return end

            local max = atttbl.Max

            if max then
                local amt = 0

                for i, k in pairs(self.Attachments) do
                    if k.Installed == attname then amt = amt + 1 end
                end

                if amt >= max then return end
            end

            if attslot.SlideAmount then
                attslot.SlidePos = 0.5
            end

            if atttbl.MountPositionOverride then
                attslot.SlidePos = atttbl.MountPositionOverride
            end

            if atttbl.AdditionalSights then
                self.SightMagnifications = {}
            end

            if atttbl.ToggleStats then
                attslot.ToggleNum = 1
            end

            attslot.ToggleLock = atttbl.ToggleLockDefault or false

            if CLIENT then
                -- we are asking to attach something

                self:SendAllDetails()

                net.Start("arccw_asktoattach")
                net.WriteUInt(slot, 8)
                net.WriteUInt(atttbl.ID, 24)
                net.SendToServer()

                if !silent then
                    surface.PlaySound(atttbl.AttachSound or "weapons/arccw/install.wav")
                end
            else
                self:DetachAllMergeSlots(slot)

                for i, k in pairs(self.Attachments) do
                    if table.HasValue(k.MergeSlots or {}, slot) then
                        self:DetachAllMergeSlots(i)
                    end
                end
            end

            attslot.Installed = attname

            if atttbl.Health then
                attslot.HP = self:GetAttachmentMaxHP(slot)
            end

            if atttbl.ColorOptionsTable then
                attslot.ColorOptionIndex = 1
            end

            ArcCW:PlayerTakeAtt(self:GetOwner(), attname)

            if SERVER then
                self:NetworkWeapon()
                self:SetupModel(false)
                self:SetupModel(true)
                ArcCW:PlayerSendAttInv(self:GetOwner())

                if engine.ActiveGamemode() == "terrortown" then
                    self:TTT_PostAttachments()
                end
            else
                self:SetupActiveSights()

                self.LHIKAnimation = 0
                self.LHIKAnimationStart = 0
                self.LHIKAnimationTime = 0

                self.LHIKDelta = {}
                self.LHIKDeltaAng = {}

                self.ViewModel_Hit = Vector(0, 0, 0)

                if !silent then
                    self:SavePreset("autosave")
                end
            end

            for s, i in pairs(self.Attachments) do
                if !self:CheckFlags(i.ExcludeFlags, i.RequireFlags) then
                    self:Detach(s, true, true)
                end
            end

            if !noadjust then
                self:AdjustAtts()
            end

            if atttbl.UBGL then
                local ubgl_ammo = self:GetBuff_Override("UBGL_Ammo")
                local ubgl_clip = self:GetBuff_Override("UBGL_Capacity")
                if self:GetOwner():IsPlayer() and ArcCW.ConVars["atts_ubglautoload"]:GetBool() and ubgl_ammo then
                    local amt = math.min(ubgl_clip - self:Clip2(), self:GetOwner():GetAmmoCount(ubgl_ammo))
                    self:SetClip2(self:Clip2() + amt)
                    self:GetOwner():RemoveAmmo(amt, ubgl_ammo)
                end
            end

            self:RefreshBGs()

            if SERVER then
                if self.ixItem then
                    self.ixItem:AddAttachment(slot, attname)
                end
            end

            return true
        end
        function SWEP:Detach(slot, silent, noadjust, nocheck, noadd)
            if !slot then return end
            if !self.Attachments[slot] then return end

            if !self.Attachments[slot].Installed then return end

            if self.Attachments[slot].Internal then return end

            if !nocheck and !ArcCW:PlayerCanAttach(self:GetOwner(), self, self.Attachments[slot].Installed, slot, true) then
                if CLIENT and !silent then
                    surface.PlaySound("items/medshotno1.wav")
                end
                return
            end

            if self.Attachments[slot].Installed == self.Attachments[slot].EmptyFallback then
                return
            end

            local previnstall = self.Attachments[slot].Installed

            local atttbl = ArcCW.AttachmentTable[previnstall]

            if atttbl.UBGL then
                local clip = self:Clip2()

                local ammo = atttbl.UBGL_Ammo or "smg1_grenade"

                if SERVER and IsValid(self:GetOwner()) then
                    self:GetOwner():GiveAmmo(clip, ammo, true)
                end

                self:SetClip2(0)
                self:DeselectUBGL()
            end

            if self.Attachments[slot].EmptyFallback then -- is this a good name
                self.Attachments[slot].Installed = self.Attachments[slot].EmptyFallback
            else
                self.Attachments[slot].Installed = nil
            end

            if self.Attachments[slot].SubAtts then
                for i, k in pairs(self.Attachments[slot].SubAtts) do
                    self:Detach(k, true, true)
                end
            end

            if self:GetAttachmentHP(slot) >= self:GetAttachmentMaxHP(slot) and !noadd then
                ArcCW:PlayerGiveAtt(self:GetOwner(), previnstall)
            end

            if CLIENT then
                self:SendAllDetails()

                -- we are asking to detach something
                net.Start("arccw_asktodetach")
                net.WriteUInt(slot, 8)
                net.SendToServer()

                if !silent then
                    surface.PlaySound(atttbl.DetachSound or "weapons/arccw/uninstall.wav")
                end

                self:SetupActiveSights()

                self.LHIKAnimation = 0
                self.LHIKAnimationStart = 0
                self.LHIKAnimationTime = 0

                if !silent then
                    self:SavePreset("autosave")
                end
            else
                self:NetworkWeapon()
                self:SetupModel(false)
                self:SetupModel(true)
                ArcCW:PlayerSendAttInv(self:GetOwner())

                if engine.ActiveGamemode() == "terrortown" then
                    self:TTT_PostAttachments()
                end
            end

            self:RefreshBGs()

            if !noadjust then
                self:AdjustAtts()
            end

            if SERVER then
                if self.ixItem then
                    self.ixItem:RemoveAttachment(slot)
                end
            end

            return true
        end
    end
end

function PLUGIN:InitializedConfig()
    -- generation kinda sucks because of arc9's largely arbitrary nature, dont really recommend it
    if ix.config.Get("generateWeaponItems(ArcCW)", false) then
        ix.arccw.GenerateWeapons()
    end
    if ix.config.Get("generateAttachmentItems(ArcCW)", false) then
        ix.arccw.GenerateAttachments()
    end

    -- go through the list again to cover manually created items. sorta inefficient, but necessary
    for k, v in pairs(ix.item.list) do
        if v.isArcCWAttachment and !v.isGenerated then
            ix.arccw.attachments[v:GetAttachment()] = k
        elseif v.isArcCWWeapon and v.isGrenade and !v.isGenerated then
            ix.arccw.grenades[v.class] = true
        end
    end
end

-- ATTACHMENT INVENTORY HOOKS
do
    function PLUGIN:ArcCW_PlayerCanAttach(client, weapon, att, slot, bDetach)
        if ix.config.Get("useWeaponBenches(ArcCW)", true) then
            if !hook.Run("NearWeaponBench", client) then
                client:Notify("You are not near a weapon workbench.")
                return false
            end
        end

        local itemID = ix.arccw.GetItemForAttachment(att)

        if itemID then
            local item = ix.item.Get(itemID)
            if item and !item:HasTool(client) then
                client:Notify("You don't have the necessary tool to apply this attachment.")
                return false
            end
        end
    end

    -- in addition to normal inv stuff, iterate through and check if the player has attachment items for the needed type
    function ArcCW:PlayerGetAtts(client, att)
        if !IsValid(client) then return 0 end
        if ix.config.Get("freeAttachments(ArcCW)", false) then return 999 end
        if ix.arccw.IsFreeAttachment(att) then return 999 end
        if att == "" then return 999 end

        local atttbl = ArcCW.AttachmentTable[att]
        if !atttbl then return 0 end

        if !IsValid(client) then return 0 end

        if !client:IsAdmin() and atttbl.AdminOnly then
            return 0
        end

        if atttbl.InvAtt then att = atttbl.InvAtt end

        local amount = (client.ArcCW_AttInv and client.ArcCW_AttInv[att]) or 0
            for _, v in ipairs(client:GetCharacter():GetInventory():GetItemsByBase("base_arccw_attachments", false)) do
            if v:GetAttachment() == att then
                amount = amount + 1
            end
        end

        return amount
    end

    -- give the player the needed attachment item, or increment the AttInv if no item exists
    function ArcCW:PlayerGiveAtt(client, att, amt, noItem)
        amt = amt or 1

        if !IsValid(client) then return end

        if !client.ArcCW_AttInv then
            client.ArcCW_AttInv = {}
        end

        local atttbl = ArcCW.AttachmentTable[att]

        if !atttbl then print("Invalid att " .. att) return end
        if ix.arccw.IsFreeAttachment(att) then return end
        if ix.config.Get("freeAttachments(ArcCW)", false) then return end
        if atttbl.AdminOnly and !(client:IsPlayer() and client:IsAdmin()) then return false end
        if atttbl.InvAtt then att = atttbl.InvAtt end

        local itemID = ix.arccw.GetItemForAttachment(att)

        if noItem or !itemID then
            if ArcCW.ConVars["attinv_lockmode"]:GetBool() then
                if client.ArcCW_AttInv[att] == 1 then return end
                client.ArcCW_AttInv[att] = 1
            else
                client.ArcCW_AttInv[att] = (client.ArcCW_AttInv[att] or 0) + amt
            end
        else
            if SERVER then
                if (!client:GetCharacter():GetInventory():Add(itemID)) then
                    ix.item.Spawn(itemID, client)
                end
            end
        end
    end

    -- remove the attachment item from the player, or from the AttInv if no item exists
    function ArcCW:PlayerTakeAtt(client, att, amt, noItem)
        amt = amt or 1

        if ArcCW.ConVars["attinv_lockmode"]:GetBool() then return end

        if !IsValid(client) then return end

        if !client.ArcCW_AttInv then
            client.ArcCW_AttInv = {}
        end

        local atttbl = ArcCW.AttachmentTable[att]
        if !atttbl or ix.arccw.IsFreeAttachment(att) then return end
        if ix.config.Get("freeAttachments(ArcCW)", false) then return end

        if atttbl.InvAtt then att = atttbl.InvAtt end

        local itemID = ix.arccw.GetItemForAttachment(att)
        local attItems = client:GetCharacter():GetInventory():GetItemsByUniqueID(itemID)

        client.ArcCW_AttInv[att] = client.ArcCW_AttInv[att] or 0

        local total = client.ArcCW_AttInv[att]
        if itemID then
            total = total + #attItems
        end
        if total < amt then
            return false
        end

        if noItem or !itemID or #attItems < 1  then
            client.ArcCW_AttInv[att] = client.ArcCW_AttInv[att] - amt
            if client.ArcCW_AttInv[att] <= 0 then
                client.ArcCW_AttInv[att] = nil
            end
        else
            local removed = 0
            while removed < amt do
                if client.ArcCW_AttInv[att] > 0 then
                    client.ArcCW_AttInv[att] = client.ArcCW_AttInv[att] - 1
                    removed = removed + 1
                else
                local head = table.remove(attItems)
                if SERVER then
                    head:Remove()
                end
                removed = removed + 1
                end  
            end
        end

        return true
    end
end

-- CUSTOMIZATION CHECK HOOKS
do
    function PLUGIN:NearWeaponBench(client)
        for _, bench in ipairs(ents.FindByClass("ix_arccw_weapon_bench")) do
            if (client:GetPos():DistToSqr(bench:GetPos()) < 100 * 100) then
                return true
            end
        end
    end

    function PLUGIN:IsCustomizing(client, weapon)
        if weapons.IsBasedOn(weapon:GetClass(), "arccw_base") then
            return weapon:GetState() == ArcCW.STATE_CUSTOMIZE
        end
    end

    function PLUGIN:StartCustomizing(client, weapon)
        if weapons.IsBasedOn(weapon:GetClass(), "arccw_base") and weapon:GetState() != ArcCW.STATE_CUSTOMIZE then
            if SERVER then
                net.Start("arccw_togglecustomize")
                    net.WriteBool(true)
                net.Send(client)
            else
                net.Start("arccw_togglecustomize")
                    net.WriteBool(true)
                net.SendToServer()
            end
            weapon:ToggleCustomizeHUD(true)
            return true
        end
    end

    function PLUGIN:StopCustomizing(client, weapon)
        if weapons.IsBasedOn(weapon:GetClass(), "arccw_base") and weapon:GetState() == ArcCW.STATE_CUSTOMIZE then
            if SERVER then
                net.Start("arccw_togglecustomize")
                    net.WriteBool(false)
                net.Send(client)
            else
                net.Start("arccw_togglecustomize")
                    net.WriteBool(false)
                net.SendToServer()
            end
            weapon:ToggleCustomizeHUD(false)
            return true
        end
    end
end

hook.Add("EntityRemoved", "ArcCWRemoveGrenade", function(entity)
    if (ix.arccw.grenades[entity:GetClass()]) then
        local client = entity:GetOwner()
        if (IsValid(client) and client:IsPlayer() and client:GetCharacter()) then
            local ammoName = game.GetAmmoName(entity:GetPrimaryAmmoType())
            if entity.Singleton or (isstring(ammoName) and client:GetAmmoCount(ammoName) < 1 and entity:Clip1() < 1 and entity.ixItem and entity.ixItem.Unequip) then
                entity.ixItem:Unequip(client, false, true)
            end
        end
    end
end)