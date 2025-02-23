
local PANEL = {}

function PANEL:Init()
	-- this has to be empty because the entity is passed AFTER the init
end

function PANEL:OnRemove()
end

function PANEL:UpdateSource(key, value)
	net.Start("ixLiqSourceEdit")
		net.WriteString(key)
		net.WriteType(value)
	net.SendToServer()
end

function PANEL:Setup(entity)

	self:SetSize(320, 400)
	self:MakePopup()
	self:CenterVertical()
	self:SetTitle("Liquid Source Editor")
	self.lblTitle:SetTextColor(color_white)

	self.infoLabel = self:Add("DLabel")
	self.infoLabel:SetText("Key Info")
	self.infoLabel:Dock(TOP)

	self.name = self:Add("DTextEntry")
	self.name:Dock(TOP)
	self.name:SetText(entity:GetDisplayName())
	self.name:SetPlaceholderText(L"name")
	self.name.OnEnter = function(this)
		if (entity:GetDisplayName() != this:GetText()) then
			self:UpdateSource("name", this:GetText())
		end
	end

	self.model = self:Add("DTextEntry")
	self.model:Dock(TOP)
	self.model:DockMargin(0, 4, 0, 0)
	self.model:SetText(entity:GetModel())
	self.model:SetPlaceholderText(L"model")
	self.model.OnEnter = function(this)
		if (entity:GetModel():lower() != this:GetText():lower()) then
			self:UpdateSource("model", this:GetText():lower())
		end
	end

    self.liqLabel = self:Add("DLabel")
	self.liqLabel:SetText("Liquid")
	self.liqLabel:DockMargin(0, 8, 0, 2)
	self.liqLabel:Dock(TOP)
	self.liquid = self:Add("DComboBox")
	self.liquid:Dock(TOP)
	self.liquid:SetTextColor(color_white)
    self.liquid:SetPaintBackground(true)

    local defaultIndex = nil
    local liquid = entity:GetLiquid()
    if liquid then liquid = ix.liquids.Get(liquid) end

	for id, liq in pairs(ix.liquids.stored) do
		local i = self.liquid:AddChoice(liq.name, id)
        if liquid and id == entity:GetLiquid() then
            defaultIndex = i
        end
	end
	if liquid and defaultIndex then
		self.liquid:ChooseOption(liquid.name, defaultIndex)
	end

    self.liquid.OnSelect = function(this, index, name, id)
		this:SizeToContents()
		this:SetWide(this:GetWide() + 12) -- padding for arrow (nice)
        self:UpdateSource("liquid", id)
	end

	self.maxLabel = self:Add("DLabel")
	self.maxLabel:SetText("Maximum Volume")
	self.maxLabel:DockMargin(0, 8, 0, 2)
	self.maxLabel:Dock(TOP)
	self.max = self:Add("DNumberWang")
	self.max:SetMinMax(1, 2000000000) -- 1mL to 2ML
	self.max:SetDecimals(0)
	self.max:SetInterval(1)
	self.max:SetValue(entity:GetMaxVolume())
	self.max:HideWang() -- force them to type it in, to allow time for the net message
	self.max:Dock(TOP)
	self.max:DockMargin(0, 0, 0, 0)
	self.max.OnEnter = function(this)
		local vol = this:GetInt()
		if vol then
			if vol > 2000000000 then vol = 2000000000 end
			self:UpdateSource("maxvolume", vol)
		end
	end

	self.curLabel = self:Add("DLabel")
	self.curLabel:SetText("Current Volume")
	self.curLabel:DockMargin(0, 4, 0, 2)
	self.curLabel:Dock(TOP)
	self.cur = self:Add("DNumberWang")
	self.cur:SetMinMax(0, 2000000000)
	self.cur:SetDecimals(0)
	self.cur:SetInterval(1)
	self.cur:SetValue(entity:GetCurVolume())
	self.cur:HideWang()
	self.cur:Dock(TOP)
	self.cur:DockMargin(0, 0, 0, 0)
	self.cur.OnEnter = function(this)
		local vol = this:GetInt()
		if vol then
			if vol > 2000000000 then vol = 2000000000 end
			self:UpdateSource("curvolume", vol)
		end
	end

	self.infLabel = self:Add("DLabel")
	self.infLabel:SetText("Infinite Source?")
	self.infLabel:DockMargin(0, 4, 0, 2)
	self.infLabel:Dock(TOP)
	self.inf = self:Add("DCheckBox")
	self.inf:SetValue(entity:GetIsInfinite())
	self.inf:Dock(TOP)
	self.inf:DockMargin(0, 0, 0, 0)
	self.inf.OnChange = function(this, value)
		self:UpdateSource("infinite", value)
	end

	self.toolLabel = self:Add("DLabel")
	self.toolLabel:SetText("Show Tooltip?")
	self.toolLabel:DockMargin(0, 4, 0, 2)
	self.toolLabel:Dock(TOP)
	self.tool = self:Add("DCheckBox")
	self.tool:SetValue(entity:GetShouldShowTooltip())
	self.tool:Dock(TOP)
	self.tool:DockMargin(0, 0, 0, 0)
	self.tool.OnChange = function(this, value)
		self:UpdateSource("tooltip", value)
	end
end

vgui.Register("ixLiqSourceEditor", PANEL, "DFrame")