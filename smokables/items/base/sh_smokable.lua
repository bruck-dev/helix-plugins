
local PLUGIN = PLUGIN

if (!pace) then return end

ITEM.name = "Smokable Base"
ITEM.model = "models/phycinnew.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.description = "Smokable base item, for basic cigarette functionality."
ITEM.category = "Smokable"
ITEM.time = 300                                         -- Max amount of time the cigarette can be smoked in seconds.
ITEM.effectInterval = 30                                -- ITEM:DoSmokingEffects is called every ITEM.effectInterval seconds. Must exist, be a number, and be a positive non-zero integer.

ITEM.lightSound = "ambient/fire/mtov_flame2.wav"        -- Sound played when the cigarette is lit, can be a numbered index table or a single string.
ITEM.equipSound = "foley/eli_hand_pat.wav"              -- Sound played when the cigarette is put in the player's mouth. can be a string or a numbered index table.

if (CLIENT) then
    function ITEM:PaintOver(item, w, h)
        if (item:GetData("equip")) then
            surface.SetDrawColor(110, 255, 110, 100)
            surface.DrawRect(w - 14, h - 20, 8, 8)
        end

        local time = item:GetTime()
        if (time) then
            surface.SetDrawColor(35, 35, 35, 225)
            surface.DrawRect(2, h-9, w-4, 7)

            local filledWidth = (w-5) * (time / item.time)
            local barColor = Color(255, 255, 255, 160)

            if item:IsLit() then
                barColor = Color(235, 85, 52, 255)
            end

            surface.SetDrawColor(barColor)
            surface.DrawRect(3, h-8, filledWidth, 5)
        end
    end
end

-- Sets the Lit data and adjusts the PAC parts.
function ITEM:Light()
    if(!self:GetData("equip", false)) then
        return "You must equip this item first before lighting it."
    end

    if !self:IsLit() then
        local client = self:GetOwner()
        self:SetData("lit", true)

        PLUGIN:StartSmoking(client:GetCharacter(), self)
    else
        return "This item is already lit!"
    end
end

-- Returns if the cigarette is lit.
function ITEM:IsLit()
    return self:GetData("lit", false)
end

-- Runs whenever the cigarette is lit. Customize effects here per item.
function ITEM:OnStartSmoke(client)
end

-- Called every ITEM.effectInterval seconds. Customize if you want smoking something to have effects over time.
function ITEM:DoSmokingEffects(client)
end

-- Runs whenever the cigarette is extinguished or fully consumed. Customize effects here per item.
function ITEM:OnStopSmoke(client, timeSmoked)
end

-- Returns if a cigarette has time left.
function ITEM:GetTime()
    return self:GetData("time", self.time)
end

-- Returns the sound to be played on light, whether the set path or a random pick from the list.
function ITEM:GetLightSound()
    if istable(self.lightSound) then
        return self.lightSound[math.random(1, #self.lightSound)]
    else
        return self.lightSound
    end
end

-- Returns the sound to be played when put in the player's mouth, whether the set path or a random pick from the list.
function ITEM:GetEquipSound()
    if istable(self.equipSound) then
        return self.equipSound[math.random(1, #self.equipSound)]
    else
        return self.equipSound
    end
end

-- Removes the PAC data, smoke timer, and unlights the cigarette. Can be called via code in other scenarios.
function ITEM:RemoveSmokable()
    local client = self:GetOwner() or self.player
    if !client then return end

    client:RemovePart(self.uniqueID)
    client:SetNetVar("smoking", nil)
    PLUGIN:DestroyTimer(client, string.format("%s%s", "SmokeTick", self.id))

    if self:IsLit() then
        self:OnStopSmoke(client, self:GetData("startTime", self.time) - self:GetTime())
        self:SetData("startTime", nil)
    end

    self:SetData("lit", nil)
    self:SetData("equip", nil)
end

-- If the character has an equipped and lit cigarette, set the pacData to be the Lit set.
function ITEM:pacAdjust(pacData, client)
    if client:GetCharacter():IsSmoking() then
        pacData = self.pacDataLit
    else
        pacData = self.pacData
    end

    return pacData
end

function ITEM:OnRemoved()
    self:RemoveSmokable()
end

ITEM:Hook("drop", function(item)
    item:RemoveSmokable()
end)

hook.Add("PlayerDeath", "ixSmokables", function(client)
    if IsValid(client) then
        local equipped, cig = client:GetCharacter():HasSmokableEquipped()
        if equipped and cig then
            cig:RemoveSmokable()
        end
    end
end)

ITEM.functions.AEquip = {
    icon = "icon16/tick.png",
    name = "Use",
    OnRun = function(item)
        local client = item.player
        local character = client:GetCharacter()

        if character:HasSmokableEquipped() then
            client:Notify("You already have a smokable equipped.")
            return false
        end 

        if(hook.Run("CanSmoke", client) == false) then
            client:Notify("You can't use a " .. item:GetName() .. " right now.")
            return false
        end

        item:SetData("equip", true)
        client:AddPart(item.uniqueID, item)

        local snd = item:GetEquipSound()
        if character.PlaySound then -- play clientside
            character:PlaySound(snd)
        else -- if not possible, play serverside
            client:EmitSound(snd, 60, 105, 1)
        end

        return false
    end,
    OnCanRun = function(item)
        return IsValid(item.player) and !item:GetData("equip", false)
    end
}

ITEM.functions.BUnequip = {
    icon = "icon16/cross.png",
    name = "Remove",
    OnRun = function(item)
        item:RemoveSmokable()
        return false
    end,
    OnCanRun = function(item)
        return IsValid(item.player) and item:GetData("equip", false)
    end
}

ITEM.functions.ALight = {
    icon = "icon16/asterisk_orange.png",
    name = "Light",
    OnRun = function(item)

        local client = item:GetOwner() or item.player

        if(hook.Run("CanSmoke", client) == false) then
            client:Notify("You can't light a " .. item:GetName() .. " right now.")
            return false
        end

        local _, lighter = client:GetCharacter():HasLighter()
        local error = item:Light()

        if(error) then
            client:Notify(error)
        else
            if lighter.OnSmokableLit then
                lighter:OnSmokableLit(item)
            end

            if lighter.GetLightSound and lighter:GetLightSound() then
                client:EmitSound(lighter:GetLightSound(), 60, 105, 1)
            else
                client:EmitSound(item:GetLightSound(), 60, 105, 1)
            end
        end

        return false
    end,
    OnCanRun = function(item)
        return IsValid(item.player) and item:GetData("equip", false) and !item:IsLit() and item.player:GetCharacter():HasLighter()
    end
}

ITEM.functions.combine = {
    OnRun = function(cigarette, data)
        local client = cigarette:GetOwner() or cigarette.player

        if(hook.Run("CanSmoke", client) == false) then
            client:Notify("You can't light a " .. cigarette:GetName() .. " right now.")
            return false
        end

        local lighter = ix.item.instances[data[1]]

        if lighter.base == "base_lighters" or lighter.canLightSmokable then
            local error = cigarette:Light()
    
            if(error) then
                client:Notify(error)
            else
                if lighter.OnSmokableLit then
                    lighter:OnSmokableLit(cigarette)
                end
                
                if lighter.GetLightSound and lighter:GetLightSound() then
                    client:EmitSound(lighter:GetLightSound(), 60, 105, 1)
                else
                    client:EmitSound(cigarette:GetLightSound(), 60, 105, 1)
                end
            end
        end

        return false
    end,
    OnCanRun = function(item, data)
        return true
    end
}

-- Unlit
ITEM.pacData = {
    [1] = {
        ["children"] = {
            [1] = {
                ["children"] = {
                },
                ["self"] = {
                    ["Skin"] = 0,
                    ["UniqueID"] = "e825fcc71a2605b5b3fea77b3e9f1f40b7a7bcb581fe1b7e16d2104e791a15f2",
                    ["NoLighting"] = false,
                    ["AimPartName"] = "",
                    ["IgnoreZ"] = false,
                    ["AimPartUID"] = "",
                    ["Materials"] = "",
                    ["Name"] = "cig",
                    ["LevelOfDetail"] = 0,
                    ["NoTextureFiltering"] = false,
                    ["PositionOffset"] = Vector(0, 0, 0),
                    ["IsDisturbing"] = false,
                    ["EyeAngles"] = false,
                    ["DrawOrder"] = 0,
                    ["TargetEntityUID"] = "",
                    ["Alpha"] = 1,
                    ["Material"] = "",
                    ["Invert"] = false,
                    ["ForceObjUrl"] = false,
                    ["Bone"] = "mouth",
                    ["Angles"] = Angle(8.6643753051758, 11.007955551147, 0.43907281756401),
                    ["AngleOffset"] = Angle(0, 0, 0),
                    ["BoneMerge"] = false,
                    ["Color"] = Vector(1, 1, 1),
                    ["Position"] = Vector(1.2998352050781, 0.56215286254883, -0.18276572227478),
                    ["ClassName"] = "model2",
                    ["Brightness"] = 1,
                    ["Hide"] = false,
                    ["NoCulling"] = false,
                    ["Scale"] = Vector(1, 1, 1),
                    ["LegacyTransform"] = false,
                    ["EditorExpand"] = true,
                    ["Size"] = 0.8,
                    ["ModelModifiers"] = "",
                    ["Translucent"] = false,
                    ["BlendMode"] = "",
                    ["EyeTargetUID"] = "",
                    ["Model"] = "models/phycinnew.mdl",
                },
            },
        },
        ["self"] = {
            ["DrawOrder"] = 0,
            ["UniqueID"] = "eeb34f00c8331b21af08c62517991785ab149e36a7c5a9a3213d8b5df0515a93",
            ["Hide"] = false,
            ["TargetEntityUID"] = "",
            ["EditorExpand"] = true,
            ["OwnerName"] = "self",
            ["IsDisturbing"] = false,
            ["Name"] = "smokable",
            ["Duplicate"] = false,
            ["ClassName"] = "group",
        },
    },
}
-- Lit
ITEM.pacDataLit = {
    [1] = {
        ["children"] = {
            [1] = {
                ["children"] = {
                    [1] = {
                        ["children"] = {
                        },
                        ["self"] = {
                            ["DrawOrder"] = 0,
                            ["UniqueID"] = "2387097255",
                            ["TargetEntityUID"] = "",
                            ["Alpha"] = 1,
                            ["SizeX"] = 0.5,
                            ["SizeY"] = 0.47499999403954,
                            ["NoTextureFiltering"] = false,
                            ["Bone"] = "head",
                            ["BlendMode"] = "",
                            ["Translucent"] = true,
                            ["IgnoreZ"] = false,
                            ["IsDisturbing"] = false,
                            ["Position"] = Vector(1.8031616210938, -0.00031280517578125, 3.814697265625e-05),
                            ["AimPartUID"] = "",
                            ["AngleOffset"] = Angle(0, 0, 0),
                            ["Hide"] = false,
                            ["Name"] = "fire",
                            ["AimPartName"] = "",
                            ["EditorExpand"] = false,
                            ["Angles"] = Angle(0, 0, 0),
                            ["Size"] = 1.2,
                            ["PositionOffset"] = Vector(0, 0, 0),
                            ["Color"] = Vector(255, 255, 255),
                            ["ClassName"] = "sprite",
                            ["EyeAngles"] = false,
                            ["SpritePath"] = "sprites/cloudglow1_nofog",
                        },
                    },
                    [2] = {
                        ["children"] = {
                        },
                        ["self"] = {
                            ["DrawOrder"] = 0,
                            ["UniqueID"] = "2869782822",
                            ["TargetEntityUID"] = "",
                            ["Alpha"] = 0.050000000745058,
                            ["SizeX"] = 6.75,
                            ["SizeY"] = 2.9500000476837,
                            ["NoTextureFiltering"] = false,
                            ["Bone"] = "head",
                            ["BlendMode"] = "",
                            ["Translucent"] = true,
                            ["IgnoreZ"] = false,
                            ["IsDisturbing"] = false,
                            ["Position"] = Vector(1.8875160217285, 0.00066089630126953, 0),
                            ["AimPartUID"] = "",
                            ["AngleOffset"] = Angle(0, 0, 0),
                            ["Hide"] = false,
                            ["Name"] = "fire_lens01",
                            ["AimPartName"] = "",
                            ["EditorExpand"] = false,
                            ["Angles"] = Angle(0, 0, 0),
                            ["Size"] = 0.5,
                            ["PositionOffset"] = Vector(0, 0, 0),
                            ["Color"] = Vector(255, 123, 0),
                            ["ClassName"] = "sprite",
                            ["EyeAngles"] = false,
                            ["SpritePath"] = "sprites/glow04_noz",
                        },
                    },
                    [3] = {
                        ["children"] = {
                        },
                        ["self"] = {
                            ["DrawOrder"] = 0,
                            ["UniqueID"] = "3048076376",
                            ["TargetEntityUID"] = "",
                            ["Alpha"] = 0.2,
                            ["SizeX"] = 2.4749999046326,
                            ["SizeY"] = 3.3499999046326,
                            ["NoTextureFiltering"] = false,
                            ["Bone"] = "head",
                            ["BlendMode"] = "",
                            ["Translucent"] = true,
                            ["IgnoreZ"] = false,
                            ["IsDisturbing"] = false,
                            ["Position"] = Vector(1.8021125793457, -0.00038337707519531, 4.57763671875e-05),
                            ["AimPartUID"] = "",
                            ["AngleOffset"] = Angle(0, 0, 0),
                            ["Hide"] = false,
                            ["Name"] = "fire_lens02",
                            ["AimPartName"] = "",
                            ["EditorExpand"] = false,
                            ["Angles"] = Angle(0, 0, 0),
                            ["Size"] = 0.5,
                            ["PositionOffset"] = Vector(0, 0, 0),
                            ["Color"] = Vector(255, 123, 0),
                            ["ClassName"] = "sprite",
                            ["EyeAngles"] = false,
                            ["SpritePath"] = "sprites/glow04_noz",
                        },
                    },
                    [4] = {
                        ["children"] = {
                            [1] = {
                                ["children"] = {
                                },
                                ["self"] = {
                                    ["DrawOrder"] = 0,
                                    ["PointCUID"] = "",
                                    ["TargetEntityUID"] = "",
                                    ["PointDUID"] = "",
                                    ["NoTextureFiltering"] = false,
                                    ["IgnoreZ"] = false,
                                    ["IsDisturbing"] = false,
                                    ["AimPartName"] = "",
                                    ["PositionOffset"] = Vector(0, 0, 0),
                                    ["Bone"] = "head",
                                    ["BlendMode"] = "",
                                    ["Angles"] = Angle(0, 0, 0),
                                    ["EditorExpand"] = true,
                                    ["PointAUID"] = "",
                                    ["Position"] = Vector(1.8298778533936, 0.0010528564453125, -3.0517578125e-05),
                                    ["AimPartUID"] = "",
                                    ["PointBUID"] = "",
                                    ["Hide"] = false,
                                    ["Name"] = "",
                                    ["UseParticleTracer"] = false,
                                    ["AngleOffset"] = Angle(0, 0, 0),
                                    ["ClassName"] = "effect",
                                    ["UniqueID"] = "391124736",
                                    ["Rate"] = 1,
                                    ["Loop"] = true,
                                    ["Effect"] = "barrel_smoke_plumeb",
                                    ["EyeAngles"] = false,
                                    ["Follow"] = true,
                                },
                            },
                            [2] = {
                                ["children"] = {
                                },
                                ["self"] = {
                                    ["DrawOrder"] = 0,
                                    ["PointCUID"] = "",
                                    ["TargetEntityUID"] = "",
                                    ["PointDUID"] = "",
                                    ["NoTextureFiltering"] = false,
                                    ["IgnoreZ"] = false,
                                    ["IsDisturbing"] = false,
                                    ["AimPartName"] = "",
                                    ["PositionOffset"] = Vector(0, 0, 0),
                                    ["Bone"] = "head",
                                    ["BlendMode"] = "",
                                    ["Angles"] = Angle(0, 0, 0),
                                    ["EditorExpand"] = false,
                                    ["PointAUID"] = "",
                                    ["Position"] = Vector(1.8029766082764, 0.017528533935547, 0.048200000077486),
                                    ["AimPartUID"] = "",
                                    ["PointBUID"] = "",
                                    ["Hide"] = false,
                                    ["Name"] = "",
                                    ["UseParticleTracer"] = false,
                                    ["AngleOffset"] = Angle(0, 0, 0),
                                    ["ClassName"] = "effect",
                                    ["UniqueID"] = "1206729052",
                                    ["Rate"] = 1,
                                    ["Loop"] = true,
                                    ["Effect"] = "barrel_smokeb",
                                    ["EyeAngles"] = false,
                                    ["Follow"] = true,
                                },
                            },
                            [3] = {
                                ["children"] = {
                                },
                                ["self"] = {
                                    ["DrawOrder"] = 0,
                                    ["PointCUID"] = "",
                                    ["TargetEntityUID"] = "",
                                    ["PointDUID"] = "",
                                    ["NoTextureFiltering"] = false,
                                    ["IgnoreZ"] = false,
                                    ["IsDisturbing"] = false,
                                    ["AimPartName"] = "",
                                    ["PositionOffset"] = Vector(0, 0, 0),
                                    ["Bone"] = "head",
                                    ["BlendMode"] = "",
                                    ["Angles"] = Angle(0, 0, 0),
                                    ["EditorExpand"] = false,
                                    ["PointAUID"] = "",
                                    ["Position"] = Vector(1.8095684051514, 0.0010108947753906, 0),
                                    ["AimPartUID"] = "",
                                    ["PointBUID"] = "",
                                    ["Hide"] = false,
                                    ["Name"] = "",
                                    ["UseParticleTracer"] = false,
                                    ["AngleOffset"] = Angle(0, 0, 0),
                                    ["ClassName"] = "effect",
                                    ["UniqueID"] = "2853340364",
                                    ["Rate"] = 1,
                                    ["Loop"] = true,
                                    ["Effect"] = "barrel_smoke",
                                    ["EyeAngles"] = false,
                                    ["Follow"] = true,
                                },
                            },
                        },
                        ["self"] = {
                            ["Skin"] = 0,
                            ["UniqueID"] = "98c8adfd3bf0ca09502f43eb45acbd248154272e79b19e59369365331d7ce779",
                            ["NoLighting"] = false,
                            ["AimPartName"] = "",
                            ["IgnoreZ"] = false,
                            ["AimPartUID"] = "",
                            ["Materials"] = "",
                            ["Name"] = "smoke_parent",
                            ["LevelOfDetail"] = 0,
                            ["NoTextureFiltering"] = false,
                            ["PositionOffset"] = Vector(0, 0, 0),
                            ["IsDisturbing"] = false,
                            ["EyeAngles"] = false,
                            ["DrawOrder"] = 0,
                            ["TargetEntityUID"] = "",
                            ["Alpha"] = 0,
                            ["Material"] = "",
                            ["Invert"] = false,
                            ["ForceObjUrl"] = false,
                            ["Bone"] = "head",
                            ["Angles"] = Angle(0, 0, 0),
                            ["AngleOffset"] = Angle(0, 0, 0),
                            ["BoneMerge"] = false,
                            ["Color"] = Vector(1, 1, 1),
                            ["Position"] = Vector(1.8562850952148, -0.00055694580078125, 6.866455078125e-05),
                            ["ClassName"] = "model2",
                            ["Brightness"] = 1,
                            ["Hide"] = false,
                            ["NoCulling"] = false,
                            ["Scale"] = Vector(1, 1, 1),
                            ["LegacyTransform"] = false,
                            ["EditorExpand"] = true,
                            ["Size"] = 1,
                            ["ModelModifiers"] = "",
                            ["Translucent"] = false,
                            ["BlendMode"] = "",
                            ["EyeTargetUID"] = "",
                            ["Model"] = "models/pac/default.mdl",
                        },
                    },
                },
                ["self"] = {
                    ["Skin"] = 0,
                    ["UniqueID"] = "e825fcc71a2605b5b3fea77b3e9f1f40b7a7bcb581fe1b7e16d2104e791a15f2",
                    ["NoLighting"] = false,
                    ["AimPartName"] = "",
                    ["IgnoreZ"] = false,
                    ["AimPartUID"] = "",
                    ["Materials"] = "",
                    ["Name"] = "cig",
                    ["LevelOfDetail"] = 0,
                    ["NoTextureFiltering"] = false,
                    ["PositionOffset"] = Vector(0, 0, 0),
                    ["IsDisturbing"] = false,
                    ["EyeAngles"] = false,
                    ["DrawOrder"] = 0,
                    ["TargetEntityUID"] = "",
                    ["Alpha"] = 1,
                    ["Material"] = "",
                    ["Invert"] = false,
                    ["ForceObjUrl"] = false,
                    ["Bone"] = "mouth",
                    ["Angles"] = Angle(8.6643753051758, 11.007955551147, 0.43907281756401),
                    ["AngleOffset"] = Angle(0, 0, 0),
                    ["BoneMerge"] = false,
                    ["Color"] = Vector(1, 1, 1),
                    ["Position"] = Vector(1.2998352050781, 0.56215286254883, -0.18276572227478),
                    ["ClassName"] = "model2",
                    ["Brightness"] = 1,
                    ["Hide"] = false,
                    ["NoCulling"] = false,
                    ["Scale"] = Vector(1, 1, 1),
                    ["LegacyTransform"] = false,
                    ["EditorExpand"] = true,
                    ["Size"] = 0.8,
                    ["ModelModifiers"] = "",
                    ["Translucent"] = false,
                    ["BlendMode"] = "",
                    ["EyeTargetUID"] = "",
                    ["Model"] = "models/phycinnew.mdl",
                },
            },
        },
        ["self"] = {
            ["DrawOrder"] = 0,
            ["UniqueID"] = "eeb34f00c8331b21af08c62517991785ab149e36a7c5a9a3213d8b5df0515a93",
            ["Hide"] = false,
            ["TargetEntityUID"] = "",
            ["EditorExpand"] = true,
            ["OwnerName"] = "self",
            ["IsDisturbing"] = false,
            ["Name"] = "smokable",
            ["Duplicate"] = false,
            ["ClassName"] = "group",
        },
    },    
}