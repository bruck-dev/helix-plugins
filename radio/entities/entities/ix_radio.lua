
local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Stationary Radio"
ENT.Description = "Basic framework for stationary radios, yippee."
ENT.Category = "Helix - Radio"
ENT.Spawnable = false
ENT.bNoPersist = true

ENT.PhysicsSounds = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Frequency")
    self:NetworkVar("Bool", 0, "Enabled")

    if SERVER then
        self:NetworkVarNotify("Frequency", self.OnVarChanged)
        self:NetworkVarNotify("Enabled", self.OnVarChanged)
    end
end

function ENT:OnVarChanged(var, old, new)
    if SERVER then
        local radioTable = self:GetRadioTable()

        if var == "Enabled" then
            if !new then
                if self.EnableStations then
                    self:StopPlaying()
                end

                local snd = radioTable:GetDisableSound(self)
                if snd then
                    self:EmitSound(snd)
                end
            else
                local snd = radioTable:GetEnableSound(self)
                if snd then
                    self:EmitSound(snd)
                end
            end
        elseif var == "Frequency" then
            if self.EnableStations then
                if ix.radio.stations.Get(old) then
                    self:StopPlaying()
                end

                self.station = ix.radio.stations.Get(new)
            end

            local snd = self:GetReceiveSound()
            if snd then
                self:EmitSound(snd)
            end
        end
    else
        if var == "Enabled" then
            if !new then
                if self.canHear and self:GetFrequency() then
                    self:UpdateCanHearFrequency(false)
                end
            end
        elseif var == "Frequency" then
            if self.canHear and self:GetEnabled() and old then
                self:UpdateCanHearFrequency(false, old)
            end
        end
    end
end

if SERVER then
    function ENT:Initialize()
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)

        self:SetFrequency(string.format("%.1f", 0))

        self:SetEnabled(false)

        self.listeners = {}

        local physObj = self:GetPhysicsObject()
        if (IsValid(physObj)) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end

        PLUGIN:SaveData()
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end

    function ENT:OnOptionSelected(client, option, data)
        local ent = self
    
        if option == "Enable" then
            self:SetEnabled(true)
            return
        elseif option == "Disable" then
            self:SetEnabled(false)
            return
        end
    
        if option == "Set Frequency" then
            if self.isHost then
                client:Notify("This radio is the host for a radio station and cannot have its frequency changed.")
                return
            end

            local defaultFreq = tonumber(self:GetFrequency())
            if !defaultFreq or defaultFreq <= 0 then
                defaultFreq = "100.0"
            end

            client:RequestString("Frequency (MHz)", "What would you like to set the frequency to?", function(frequency)
                if tonumber(frequency) then
                    frequency = string.format("%.1f", tonumber(frequency))
                    client:Notify(ent:UpdateFrequency(frequency))
                else
                    client:Notify(string.format("%s is an invalid frequency.", frequency))
                end
            end, defaultFreq)
        end
    end

    function ENT:Think()
        if self.EnableStations and self:GetEnabled() then
            self.listeners = self.listeners or {}
            local station = self.station or ix.radio.stations.Get(self:GetFrequency())
            local path = station and station:GetPlayingTrack()
            if path then
                self.station = station

                local listeners = {}
                local radius = ix.config.Get("radioStationListenRange", 384)

                for _, v in ipairs(ents.FindInSphere(self:GetPos(), radius)) do
                    if v:IsPlayer() then
                        listeners[v] = true
                        if !self.listeners[v] then
                            net.Start("ixRadioStationJoin")
                                net.WriteUInt(self:EntIndex(), 16)
                                net.WriteString(path)
                                net.WriteBool(!file.Exists("sound/" .. path, "GAME")) -- check if the path is a file or a remote url
                                net.WriteVector(self:GetPos())
                                if station.audio.isStream then
                                    net.WriteFloat(-1)
                                else
                                    net.WriteFloat(CurTime() - (station:GetInstance().audio.startTime or CurTime()))
                                end
                            net.Send(v)
                        end
                    end
                end
            
                for client, _ in pairs(self.listeners or {}) do
                    if !listeners[client] and IsValid(client) then
                        net.Start("ixRadioStationLeave")
                            net.WriteUInt(self:EntIndex(), 16)
                        net.Send(client)
                    end
                end

                self.listeners = listeners
            else
                self:StopPlaying()
            end
        end

        self:NextThink(CurTime() + 0.10)

        return true
    end

    function ENT:StopPlaying()
        for client, _ in pairs(self.listeners or {}) do
            if IsValid(client) then
                net.Start("ixRadioStationLeave")
                    net.WriteUInt(self:EntIndex(), 16)
                net.Send(client)
            end
        end

        self.listeners = {}
    end

    function ENT:OnRemove()
        self:StopPlaying()

        if !ix.shuttingDown then
            PLUGIN:SaveData()
        end
    end
else
    ENT.PopulateEntityInfo = true

    function ENT:OnPopulateEntityInfo(tooltip)
        local radioTable = self:GetRadioTable()

        local name = tooltip:AddRow("name")
        name:SetImportant()
        name:SetText(radioTable:GetName(self))
        name:SizeToContents()

        local description = tooltip:AddRow("description")
        local min, max, minUnit, maxUnit = self:GetFrequencyBand()
        local text = string.format("%s\n\nFrequency Band: %s %s to %s %s", radioTable:GetDescription(self), min, minUnit, max, maxUnit)
        local freq, unit = self:GetDisplayFrequency()
        if tonumber(freq) > 0 then
            text = text .. string.format("\nTuned Frequency: %s %s", freq, unit)
        end
        description:SetText(text)
        description:SizeToContents()
    end

    function ENT:Draw()
        self:DrawModel()
        self:GetRadioTable():Paint(self)
    end

    function ENT:Think()
        local client = LocalPlayer()
        if !IsValid(client) or !client:Alive() or !client:GetCharacter() then return end

        if self:GetEnabled() then
            local radius = ix.config.Get("radioChatListenRange", 96)
            local inRadius = (LocalPlayer():GetPos():DistToSqr(self:GetPos()) < radius * radius)

            if !self.canHear and inRadius then
                self:UpdateCanHearFrequency(true)
            elseif self.canHear and !inRadius then
                self:UpdateCanHearFrequency(false)
            end
        end

        local entIndex = self:EntIndex()
        if !self.EnableStations or !client.radioStations or !client.radioStations[entIndex] or !client.radioStations[entIndex]:IsValid() then return end
        client.radioStations[entIndex]:SetPos(self:GetPos())
    end

    function ENT:OnRemove()
        if self:GetEnabled() and self.canHear then
            self:UpdateCanHearFrequency(false)
        end
    end

    function ENT:UpdateCanHearFrequency(canHear, frequency)
        local client = LocalPlayer()
        if !IsValid(client) or !client:Alive() or !client:GetCharacter() then return end
    
        client.frequencies = client.frequencies or {}
        frequency = frequency or self:GetFrequency()
        local oldRadio = client.frequencies[frequency]
        self.canHear = canHear
    
        if canHear then
            -- if we can already hear a two-way radio, don't replace it
            if oldRadio and oldRadio != self and IsValid(oldRadio) and oldRadio.TwoWay then
                return
            end
            client.frequencies[frequency] = self
        else
            -- only clear if we are the one currently registered
            if oldRadio != self then
                return
            end
    
            client.frequencies[frequency] = nil
    
            -- check if there's another radio still in range that should become the new reference point
            for _, ent in ipairs(ents.FindInSphere(client:GetPos(), ix.config.Get("radioChatListenRange", 96))) do
                if IsValid(ent) and ent != self and ent.canHear and ent.GetFrequency and ent:GetFrequency() == frequency then
                    ent:UpdateCanHearFrequency(true, frequency)
                    return
                end
            end
        end
    
        net.Start("ixRadioFrequencySync")
            net.WriteUInt(client:GetCharacter():GetID(), 32)
            net.WriteEntity(self)
            net.WriteString(frequency)
            net.WriteBool(canHear)
        net.SendToServer()
    end
end

function ENT:GetRadioTable()
    self.radioTable = self.radioTable or ix.radio.stationaryRadios.stored[self.uniqueID]
    return self.radioTable
end

function ENT:GetEntityMenu(client)
    local dist = ix.config.Get("interactRange", 96)
    if !IsValid(client) or !(client:GetPos():DistToSqr(self:GetPos()) < (dist * dist)) or !client:GetCharacter() then
        return
    end

    local options = {}

    if self:GetEnabled() then
        options["Disable"] = true
    else
        options["Enable"] = true
    end

    options["Set Frequency"] = true

    return options
end

function ENT:GetFrequencyBand()
    local min, minUnit = ix.radio.ConvertUnit(self.FrequencyBand["min"])
    local max, maxUnit = ix.radio.ConvertUnit(self.FrequencyBand["max"])
    return min, max, minUnit, maxUnit
end

function ENT:UpdateFrequency(freq)
    local min, max, minUnit, maxUnit = self:GetFrequencyBand()
    local freq, unit = ix.radio.ConvertUnit(freq)

    local compareFreq = tonumber(freq)

    if compareFreq > tonumber(max) or compareFreq < tonumber(min) then
        return string.format("%s %s is outside of the device's operating frequency band of %s %s to %s %s.", freq, unit, min, minUnit, max, maxUnit)
    else
        self:SetFrequency(freq)
        return string.format("You have set this radio's frequency to %s %s.", freq, unit)
    end
end

function ENT:GetDisplayFrequency()
    return ix.radio.ConvertUnit(self:GetFrequency())
end

function ENT:GetTransmitPower()
    return self:GetRadioTable():GetTransmitPower(self) or 1.0
end

function ENT:GetReceiveSound()
    return self:GetRadioTable():GetReceiveSound(self)
end