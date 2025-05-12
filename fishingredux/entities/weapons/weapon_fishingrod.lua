
AddCSLuaFile()

SWEP.PrintName = "Fishing Rod" -- change the name
SWEP.Author = "sterlingpierce"

SWEP.Category = "Sterling Pierce" -- change the name

SWEP.Slot = 0
SWEP.SlotPos = 4

SWEP.Spawnable = true

SWEP.ViewModel = Model( "models/sterling/spook_c_fishingrod.mdl" ) -- just change the model 
SWEP.WorldModel = Model( "models/sterling/spook_w_fishingrod.mdl" )
SWEP.ViewModelFOV = 85
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.Base = "weapon_base"

SWEP.Secondary.Ammo = "none"

SWEP.HoldType = "normal"
function SWEP:Initialize()
	self:SetWeaponHoldType( "normal" )
    return true
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Int", 0, "Stage" )
	self:NetworkVar( "Int", 1, "CurStr" )
	self:NetworkVar( "Int", 2, "RStr" )
	self:NetworkVar( "Entity", 0, "HookEnt" )
end

function SWEP:Deploy()
	-- if SERVER then
	-- 	self:GhostProp()
	-- end

	self:SetStage(0)
	self:SetCurStr(0)
	self:SetRStr(50)
	self.NextSpinSound = CurTime()
end

function SWEP:GhostProp()
	if (IsValid(self.ghostProp)) then self.ghostProp:Remove() end
	self.ghostProp = ents.Create("j_fishing_hook")
	-- self.ghostProp = ClientsideModel("models/props_phx2/garbage_metalcan001a.mdl")
	-- self.ghostProp:SetModel( "models/props_junk/meathook001a.mdl" )
	self.ghostProp:SetPos(self.Owner:GetPos() + Angle(0, self.Owner:GetAngles().y, 0):Forward() * 100 +  Angle(0, self.Owner:GetAngles().y, 0):Up() * 150 )
	self.ghostProp:SetAngles(Angle(0, self.Owner:GetAngles().y, 0))
	self.ghostProp:Spawn()
	self.ghostProp:Activate()
	self.ghostProp:SetOwner(self.Owner)
	self.ghostProp:SetRod(self)
	-- self.ghostProp:SetParent(self.Owner)

	self:SetHookEnt(self.ghostProp)

	local phys = self.ghostProp:GetPhysicsObject()

	if (IsValid(phys)) then
		phys:AddGameFlag(FVPHYSICS_WAS_THROWN)
		phys:ApplyForceCenter(self.Owner:GetAimVector() * 150000)
	end

	self.Owner:ViewPunch( Angle( -3, 0, 0 ) )

	local rodBone = 22

end


local mouse_lmb = Material("gui/lmb.png")
local mouse_rmb = Material("gui/rmb.png")

local ropeMaterial = Material("cable/rope")


local color_semi_white = Color(200,200,200)
local color_progress = Color(39, 174, 96)
local color_black_trans = Color(0,0,0,150)

function SWEP:ViewModelDrawn(vm)

	-- if (self:GetMenuType() != 3) then
	local Ang = vm:GetAngles()
	local Pos = vm:GetPos()

	if (!ix.option.Get("thirdpersonEnabled", false) or (GetViewEntity() == LocalPlayer())) then
		local BonePos, BoneAng = vm:GetBonePosition(22)

		if (IsValid(self:GetHookEnt())) then
			render.SetMaterial( ropeMaterial )
			-- render.DrawSprite( Pos + vm:GetForward() * 30, 17, 17, color_white)
			render.DrawBeam( BonePos,  self:GetHookEnt():GetPos() +  self:GetHookEnt():GetUp() * 2, 0.5, 1,2 )
		end
	end


	Ang:RotateAroundAxis(Ang:Up(), -90)
	Ang:RotateAroundAxis(Ang:Forward(), 86)
	Ang:RotateAroundAxis(Ang:Right(), 10)

	cam.Start3D2D( Pos + Ang:Up() * -15 + Ang:Forward() * 1.5 + Ang:Right() * 4, Ang, 0.025 )


		
		surface.SetDrawColor( color_black_trans )
		surface.DrawRect( -20, 20, 140,20 )

		surface.SetDrawColor( color_black_trans )
		surface.DrawRect( -20, -1, 140,20 )

		if (self:GetCurStr() > 0) then

			local progress = math.Clamp((self:GetCurStr() * 138) / self:GetRStr(),0,138)

			surface.SetDrawColor( color_progress )
			surface.DrawRect( -19, 0, progress,18 )

		end

		surface.SetDrawColor(color_black )
	    surface.SetMaterial( mouse_lmb )
		surface.DrawTexturedRect(-17,-1,20,20)

		surface.SetDrawColor(color_semi_white )
	    surface.SetMaterial( mouse_lmb )
		surface.DrawTexturedRect(-15, 1,16,16)
		

		surface.SetDrawColor(color_black )
	    surface.SetMaterial( mouse_rmb )
		surface.DrawTexturedRect(-17,18,20,20)

		surface.SetDrawColor(color_semi_white )
	    surface.SetMaterial( mouse_rmb )
		surface.DrawTexturedRect(-15, 20,16,16)

		if (self:GetStage() == 0) then
			draw.SimpleText( "Cast a Line", "Trebuchet24", 55,20, color_semi_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		elseif (self:GetStage() == 1) then
			draw.SimpleText( "Reel In", "Trebuchet24", 55,20, color_semi_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		elseif (self:GetStage() == 2) then
			draw.SimpleText( "Pull Up", "Trebuchet24", 55,20, color_semi_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
		end
		
		draw.SimpleText( "Cancel", "Trebuchet24", 55,41, color_semi_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )

					
	cam.End3D2D()

	-- end

end

function SWEP:Holster()
	if SERVER then
		if (IsValid(self.ghostProp)) then
			self.ghostProp:Remove()
		end
	end

	return true
end


function SWEP:OnDrop()
	self:Remove()
end

function SWEP:OnRemove()
	if SERVER then
		if (IsValid(self.ghostProp)) then
			self.ghostProp:Remove()
		end
	end
	self:Holster()
end

function SWEP:ResetStage()

	self.Weapon:SendWeaponAnim( ACT_VM_IDLE_1 )
	self:EmitSound("physics/body/body_medium_impact_soft"..math.random(6,7)..".wav")
	self:SetStage(0)
	self:SetWeaponHoldType( "normal" )
	self:SetNextPrimaryFire(self:GetNextPrimaryFire() + 1)
	self:SetNextSecondaryFire(self:GetNextSecondaryFire() + 1)
	self:SetCurStr(0)
	if SERVER then
		if (IsValid(self.ghostProp)) then
			self.ghostProp:Remove()
		end
	end

end

function SWEP:PrimaryAttack()

	if (self:GetStage() == 0) then

		local char = self.Owner:GetCharacter()
		local inv = char:GetInventory()

		if ix.config.Get("requireFishingBait", true) then
			local item = inv:HasItem("fish_bait")
			if (item) then

				self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
				self.Owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(6,7)..".wav")
				self:SetStage(1)
				self:SetWeaponHoldType( "pistol" )
				self.Owner:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND, true)

				if SERVER then
					self:GhostProp()
					if item.base == "base_stackable" then
						local stack = item:GetData("stacks", 1)
						if stack > 1 then
							item:SetData("stacks", stack - 1)
						else
							item:Remove()
						end
					else
						item:Remove()
					end
				end
			else
				if (SERVER) then
					self.Owner:Notify("You don't have any bait.")
				end
			end
		else
			self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self.Owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(6,7)..".wav")
			self:SetStage(1)
			self:SetWeaponHoldType( "pistol" )
			self.Owner:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND, true)

			if SERVER then
				self:GhostProp()
			end
		end

	elseif (self:GetStage() == 1) then
		self.Weapon:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
		-- self:EmitSound("physics/plastic/plastic_barrel_strain"..math.random(1,3)..".wav")
		self:SetStage(2)
		self:SetWeaponHoldType( "revolver" )
	elseif (self:GetStage() == 2) then
		self.Owner:EmitSound("physics/plastic/plastic_barrel_strain"..math.random(1,3)..".wav")
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		self:SetCurStr(self:GetCurStr() + 20)
		if (self:GetCurStr() >= self:GetRStr()) then
			self:CatchFish()
		end
	end

	self:SetNextPrimaryFire(self:GetNextPrimaryFire() + 1)
	self:SetNextSecondaryFire(self:GetNextSecondaryFire() + 1)

end 

function SWEP:CatchFish()

	if (self:GetHookEnt()) then
		if (self:GetHookEnt().fishCaught) then
			self:GetHookEnt():Catch()
		else
			if (SERVER) then
				self:GetOwner():Notify("You didn't catch anything.")
			end
		end
	end

	self:ResetStage()

end

function SWEP:SecondaryAttack()

	if (self:GetStage() != 0) then
		self:ResetStage()
	end

end

function SWEP:Reload()
	return true
end


function SWEP:Think()
	if SERVER then
		if (self:GetStage() == 2) then
			
			if (self.NextSpinSound < CurTime()) then
				self.Owner:EmitSound("weapons/357/357_spin1.wav")
				-- self.Owner:EmitSound("physics/plastic/plastic_barrel_strain"..math.random(1,3)..".wav")
				self.NextSpinSound = CurTime() + 0.65

			end

			if (self:GetCurStr() > 0) and (math.random() > 0.8) then
				self:SetCurStr(self:GetCurStr() - 1)
			end

		end

	end

end