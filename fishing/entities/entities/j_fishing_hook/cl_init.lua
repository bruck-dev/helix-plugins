include("shared.lua")


function ENT:Initialize()

end

local ropeMaterial = Material("cable/rope")

function ENT:Draw()

	local Pos = self:GetPos()

	self:DrawModel()

	if (self:GetOwner()) and (IsValid(self:GetOwner())) and (self:GetOwner():GetActiveWeapon():GetClass() == "weapon_fishingrod") then
		if (ix.option.Get("thirdpersonEnabled", false) or (GetViewEntity() != LocalPlayer())) then

			local BonePos, BoneAng = self:GetOwner():GetActiveWeapon():GetBonePosition(1)

			render.SetMaterial( ropeMaterial )
			-- render.DrawSprite( Pos + self:GetForward() * 10, 16, 16, color_white)
			render.DrawBeam( Pos,BonePos + BoneAng:Forward() * 75 + BoneAng:Right() * -30, 1, 1,2 )
		end
	end
	
end
