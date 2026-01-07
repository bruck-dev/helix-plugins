
local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Stationary Radio"
ENT.Description = "Basic framework for stationary radios, yippee."
ENT.Category = "Helix - Radio"
ENT.Spawnable = false
ENT.bNoPersist = true

ENT.PhysicsSounds = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "RadioID")
    self:NetworkVar("String", 1, "Frequency")
    self:NetworkVar("String", 2, "FrequencyUnit")
    self:NetworkVar("Bool", 0, "Enabled")

    self:NetworkVarNotify("Enabled", self.OnVarChanged)
    self:NetworkVarNotify("Frequency", self.OnVarChanged)

    if SERVER then
        self:NetworkVarNotify("RadioID", self.OnVarChanged)
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

                local snd = radioTable:GetDisableSound()
                if snd then
                    self:EmitSound(snd)
                end
            else
                local snd = radioTable:GetEnableSound()
                if snd then
                    self:EmitSound(snd)
                end
            end
        elseif var == "Frequency" then
            if self.EnableStations then
                if ix.radio.stations.Get(old) then
                    self:StopPlaying()
                end

                local newStation = ix.radio.stations.Get(new)
                if newStation and !newStation.isStream then
                    self.station = newStation
                    self.startTime = ix.radio.stations.instances[newStation.uniqueID].startTime
                    self.path = ix.radio.stations.instances[newStation.uniqueID].track
                end
            end

            local snd = self:GetReceiveSound()
            if snd then
                self:EmitSound(snd)
            end
        elseif var == "RadioID" then
            local radioTable = ix.radio.stationaryRadios.stored[new]

            if radioTable then
                self:SetModel(radioTable:GetModel())
            end
        end
    else
        if var == "Enabled" then
            if !new then
                if self.canCurrentlyHear and self:GetFrequency() then
                    self:UpdateCanHearFrequency(false)
                end
            end
        elseif var == "Frequency" then
            if self.canCurrentlyHear and self:GetEnabled() and old then
                self:UpdateCanHearFrequency(false, old)
            end
        end
    end
end

if SERVER then
    function ENT:Initialize()
        self:SetRadioID(self.uniqueID)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)

        self:SetFrequency(string.format("%.1f", 0))
        self:SetFrequencyUnit("MHz")

        self:SetEnabled(false)

        self.listeners = {}

        local physObj = self:GetPhysicsObject()
        if (IsValid(physObj)) then
            physObj:EnableMotion(false)
            physObj:Sleep()
        end

        PLUGIN:SaveData()
    end

    function ENT:OnRemove()
        if !ix.shuttingDown then
            PLUGIN:SaveData()
        end
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end

    function ENT:OnOptionSelected(client, option, data)
        local ent = self
    
        if option == "Enable" then
            self:SetEnabled(true)
        elseif option == "Disable" then
            self:SetEnabled(false)
        end
    
        if option == "Set Frequency" then
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
            local station = self.station or ix.radio.stations.Get(self:GetFrequency())
            if station and station:CanPlay() then
                self.station = station

                if !self.startTime then
                    self.startTime = CurTime()
                end

                local listeners = {}
                local radius = ix.config.Get("radioListenRange", 92) * 4

                for _, v in ipairs(ents.FindInSphere(self:GetPos(), radius)) do
                    if v:IsPlayer() and v:Alive() then
                        listeners[v] = true

                        if !(self.listeners and self.listeners[v]) then
                            local path = self.path
                            if !path then
                                if istable(station.trackList) then
                                    path = station.trackList[1]
                                else
                                    path = station.trackList
                                end

                                self.path = path
                            end

                            net.Start("ixRadioStationJoin")
                                net.WriteEntity(self)
                                net.WriteString(path)
                                net.WriteBool(!file.Exists("sound/" .. path, "GAME")) -- check if the path is a file or a remote url
                                if station.isStream then
                                    net.WriteFloat(-1)
                                else
                                    net.WriteFloat(CurTime() - self.startTime)
                                end
                            net.Send(v)
                        end
                    end
                end
            
                for client, _ in pairs(self.listeners or {}) do
                    if !listeners[client] and IsValid(client) then
                        net.Start("ixRadioStationLeave")
                            net.WriteEntity(self)
                        net.Send(client)
                    end
                end

                self.listeners = listeners
            end
        end

        self:NextThink(CurTime() + 0.25)

        return true
    end

    function ENT:StopPlaying()
        for client, _ in pairs(self.listeners or {}) do
            if IsValid(client) then
                net.Start("ixRadioStationLeave")
                    net.WriteEntity(self)
                net.Send(client)
            end
        end

        self.startTime = nil
        self.station = nil
        self.path = nil
        self.listeners = {}
    end

    function ENT:OnRemove()
        self:StopPlaying()
    end
else
    ENT.PopulateEntityInfo = true

    function ENT:OnPopulateEntityInfo(tooltip)
        local name = tooltip:AddRow("name")
        name:SetImportant()
        name:SetText(self.PrintName)
        name:SizeToContents()

        local description = tooltip:AddRow("description")
        local min, max, minUnit, maxUnit = self:GetValidFrequencyBand()
        local text = string.format("%s\n\nFrequency Band: %s %s to %s %s", self.Description, min, minUnit, max, maxUnit)
        if tonumber(self:GetFrequency()) > 0 and self:GetFrequencyUnit() then
            text = text .. string.format("\nFrequency Tuning: %s %s", self:GetFrequency(), self:GetFrequencyUnit())
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
            local radius = ix.config.Get("radioListenRange", 92)
            local inRadius = (LocalPlayer():GetPos():DistToSqr(self:GetPos()) < radius * radius)

            if !self.canCurrentlyHear and inRadius then
                self:UpdateCanHearFrequency(true)
            elseif self.canCurrentlyHear and !inRadius then
                self:UpdateCanHearFrequency(false)
            end
        end

        if !self.clientAudioChannel or !self.clientAudioChannel:IsValid() then return end
        self.clientAudioChannel:SetPos(self:GetPos())
    end

    function ENT:OnRemove()
        if self:GetEnabled() and self.canCurrentlyHear then
            self:UpdateCanHearFrequency(false)
        end

        if self.clientAudioChannel and self.clientAudioChannel:IsValid() then
            self.clientAudioChannel:Stop()
        end
    end

    function ENT:UpdateCanHearFrequency(canHear, frequency)
        local client = LocalPlayer()
        if !IsValid(client) or !client:Alive() or !client:GetCharacter() then return end

        net.Start("ixRadioCanHearFrequency")
            net.WriteUInt(client:GetCharacter():GetID(), 32)
            net.WriteString(frequency or self:GetFrequency())
            net.WriteBool(canHear)
        net.SendToServer()

        self.canCurrentlyHear = canHear
    end
end

function ENT:GetEntityMenu(client)
    if !IsValid(client) and !(client:GetPos():DistToSqr(self:GetPos()) < 75 * 75) or !client:GetCharacter() then
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

function ENT:ConvertUnit(freq)
    if isstring(freq) then
        freq = tonumber(freq)
    end
    freq = tonumber(string.format("%.1f", freq))

    -- no need to convert if we're already in the MHz range
    if freq >= 1 and freq < 1000 then
        return string.format("%.1f", freq), "MHz"
    end

    freq = freq * 1000000000 -- normalize to GHz; we ALWAYS divide once, so this makes room for the first division
    local units = {
        "Hz",
        "kHz",
        "MHz",
        "GHz",
        "THz",
    }

    local i = 0
    while freq >= 1000 do
        freq = freq / 1000
        i = i + 1
    end

    return string.format("%.1f", freq), (units[i] or "undefined")
end

function ENT:GetValidFrequencyBand()
    local _, minUnit = self:ConvertUnit(self.FrequencyBand["min"])
    local _, maxUnit = self:ConvertUnit(self.FrequencyBand["max"])

    return string.format("%.1f", self.FrequencyBand["min"]), string.format("%.1f", self.FrequencyBand["max"]), minUnit, maxUnit
end

function ENT:UpdateFrequency(freq)
    local min, max, minUnit, maxUnit = self:GetValidFrequencyBand()
    local freq, unit = self:ConvertUnit(freq)

    local compareFreq = tonumber(freq)

    if compareFreq > tonumber(max) or compareFreq < tonumber(min) then
        return string.format("%s %s is outside of the device's operating frequency band of %s %s to %s %s.", freq, unit, min, minUnit, max, maxUnit)
    else
        self:SetFrequency(freq)
        self:SetFrequencyUnit(unit)
        return string.format("You have set this radio's frequency to %s %s.", freq, unit)
    end
end

function ENT:GetRadioTable()
    return ix.radio.stationaryRadios.stored[self:GetRadioID()]
end

function ENT:GetReceiveSound()
    return self:GetRadioTable():GetReceiveSound()
end