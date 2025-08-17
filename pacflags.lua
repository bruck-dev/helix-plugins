local PLUGIN = PLUGIN

PLUGIN.name = "PAC3 Flags"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds the 'P' flag, which allows use of the PAC3 editor. Also forces a restart on character load to force fix any PAC issues."

-- i left this in here as a reminder for you to make sure you update the CAMI privilege registered by the integration plugin to allow users!
-- CAMI.RegisterPrivilege({
--     Name = "Helix - Manage PAC",
--     MinAccess = "user"
-- })

-- check if they have the flag on open
ix.flag.Add("P", "Access to the PAC3 editor.")
if CLIENT then
   function PLUGIN:PrePACEditorOpen(client)
        if client and client:GetCharacter() then
            return client:IsAdmin() or (client:GetCharacter():HasFlags("P") and CAMI.PlayerHasAccess(client, "Helix - Manage PAC", nil))
        else
            return false
        end
    end
end

function PLUGIN:PrePACConfigApply(client, data)
    if client and client:GetCharacter() then
        return client:IsAdmin() or (client:GetCharacter():HasFlags("P") and CAMI.PlayerHasAccess(client, "Helix - Manage PAC", nil))
    else
        return false
    end
end

function PLUGIN:pac_CanWearParts(client)
    if client and client:GetCharacter() then
        return client:IsAdmin() or (client:GetCharacter():HasFlags("P") and CAMI.PlayerHasAccess(client, "Helix - Manage PAC", nil)), "You do not have the proper flags and/or permissions to use PAC."
    else
        return false
    end
end

-- edited from pK/millie's pac fix code. forces a PAC restart when a character is loaded
function PLUGIN:PlayerLoadedCharacter(client, curChar, prevChar)
    if !(client:IsValid() or client:Alive() or curChar) then
        return
    end

    client:ConCommand("pac_restart")

    -- after restart, re-initialize all PAC items (including my inv ones, if needed)
    timer.Simple(0.1, function()
        if ix.pac then
            local curParts = client:GetParts()
            if (curParts) then
                client:ResetParts()
            end

            if ix.pac.pacInv then
                curParts = client:GetPartsInv()
                if (curParts) then
                    client:ResetPartsInv()
                end
            end

            if (curChar) then
                local inv = curChar:GetInventory()

                for k, _ in inv:Iter() do
                    if (k:GetData("equip", false) == true and k.pacData) then
                        client:AddPart(k.uniqueID, k)
                    elseif ix.pac.pacInv then
                        if k.pacDataInv and !k.pacData then
                            client:AddPartInv(k.uniqueID, k)
                        end
                    end
                end
            end
        end
    end)
end

-- credit to vinyl for these, i just added the IsBanned checks
ix.command.Add("PACBan", {
    description = "Bans a player from using PAC in all cases.",
    adminOnly = true,
    arguments = {
        ix.type.player
    },
    OnRun = function (self, client, target)
        if !pace.IsBanned(target) then
            pace.Ban(target)
            client:Notify("Player ".. target:Name() .." has been banned from using PAC3.")
        else
            client:Notify("Player " .. target:Name() .. " is already banned from using PAC3.")
        end
    end
})

ix.command.Add("PACUnban", {
    description = "Removes the PAC3 ban restriction from a player.",
    adminOnly = true,
    arguments = {
        ix.type.player
    },
    OnRun = function (self, client, target)
        if pace.IsBanned(target) then
            pace.Unban(target)
            client:Notify("Player ".. target:Name() .." has been unbanned from using PAC3.")
        else
            client:Notify("Player " .. target:Name() .. " is not currently banned from using PAC3.")
        end
    end
})