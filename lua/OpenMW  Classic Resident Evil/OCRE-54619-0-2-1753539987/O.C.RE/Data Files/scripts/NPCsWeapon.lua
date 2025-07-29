local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local anim = require('openmw.animation')
local AI = require('openmw.interfaces').AI
local I = require('openmw.interfaces')

local AmmoUsage={}
util.loadCode(types.Book.records["AmmoUsage"].text,{AmmoUsage=AmmoUsage})()

----- variablepour tire shotguns
Shotgun={}


local function onUpdate()

	---force Ammos.... kind of works
	if self.type~=types.Player and types.Actor.getEquipment(self, 16) and types.Weapon.records[types.Actor.getEquipment(self, 16).recordId].type==types.Weapon.TYPE.MarksmanCrossbow then
		local ammochecked=false
		--print(types.Actor.getEquipment(self, 16))
		for i, ammo in ipairs(AmmoUsage[types.Actor.getEquipment(self, 16).recordId][2]) do
			--print(AmmoUsage[types.Actor.getEquipment(self, 16).recordId][2])
			if types.Actor.getEquipment(self, 18) and types.Actor.getEquipment(self, 18).recordId==ammo then
				ammochecked=true
				break
			end
		end
		if ammochecked==false then
			--print("wrong ammo")
			for i, ammo in ipairs(AmmoUsage[types.Actor.getEquipment(self, 16).recordId][2]) do
				--print(ammo)
				if types.Actor.inventory(self):find(ammo) then
					--print(types.Actor.getEquipment(self, 16).recordId)
					--print(AmmoUsage[types.Actor.getEquipment(self, 16).recordId][2][1])
					types.Actor.setEquipment(self, { 	[types.Actor.EQUIPMENT_SLOT.Ammunition] = ammo,
														[types.Actor.EQUIPMENT_SLOT.CarriedRight] = types.Actor.getEquipment(self, 16)
													})	
					ammochecked=true
					break
				end
			end
			if ammochecked==false then	
				--print("Still wrong ammo")			
				for i, weapon in ipairs(types.Actor.inventory(self):getAll(types.Weapon)) do
					if types.Weapon.records[weapon.recordId].type~=types.Weapon.TYPE.MarksmanCrossbow and types.Weapon.records[weapon.recordId].type~=types.Weapon.TYPE.MarksmanBow and types.Weapon.records[weapon.recordId].type~=types.Weapon.TYPE.Arrow and types.Weapon.records[weapon.recordId].type~=types.Weapon.TYPE.Bolt then
						--print("equip H to H")
						print(weapon)
						types.Actor.setEquipment(self, { [types.Actor.EQUIPMENT_SLOT.CarriedRight] = weapon
													})	
						ammochecked=true
						break
					end
				end
			end
			if ammochecked==false then
				--print("equip nothing")
				types.Actor.setEquipment(self, {})	
			end
		end
	end


	

	if core.sound.isSoundPlaying("crossbowshoot",self)	 then
--		print("sound")
						-----------------------------Special Ammo-----------------------------------------------------------------
				--print(tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo")
				--------SpecialAmmo------ en cours
				if types.Actor.getEquipment(self, 18) then
					if types.Weapon.records[tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo"] then
						--print(tostring(types.Actor.getEquipment(self, 18).recordId) .. "SpecialAmmo")
						core.sendGlobalEvent('CreateSpecialAmmo',
							{ Player = self, Ammo = tostring(types.Actor.getEquipment(self, 18).recordId .. "SpecialAmmo") })
					end
				end
				----------------------------------------------------------------------------------------------
				---
				---
				---
				---
		
				local RotZ = self.rotation:getPitch()
				local RotX = self.rotation:getYaw()
								---------------------------shotshell -----------en cours
				if types.Actor.getEquipment(self, 18) then
					if types.Weapon.records[types.Actor.getEquipment(self, 18).recordId].enchant then
						if core.magic.enchantments.records[types.Weapon.records[types.Actor.getEquipment(self, 18).recordId].enchant] and string.find(core.magic.enchantments.records[types.Weapon.records[types.Actor.getEquipment(self, 18).recordId].enchant].id, "shotshell") then
							--print("self  " .. tostring(self.position))
							print("shotgun")
							local shelldistance = 1000
							local pellets = types.Weapon.records[types.Actor.getEquipment(self, 16).recordId].chopMinDamage
							local r = 10
							Shotgun.shellDamage = types.Weapon.records[types.Actor.getEquipment(self, 18).recordId].thrustMinDamage
							Shotgun.shellEnchant = core.magic.enchantments.records[types.Weapon.records[types.Actor.getEquipment(self, 18).recordId].enchant]
							for a = 1, pellets do
								--S.ShellPos=util.transform.move(0,0,70)*self.position+ util.transform.rotate(1,util.vector3(0,0,math.pi/2))self.rotation*util.vector3(0,1,0)*100
								
								Shotgun.ShellRotX = RotX + math.random(-1,1)*math.pi*types.Weapon.records[types.Actor.getEquipment(self, 16).recordId].slashMinDamage/(180*11)
								Shotgun.ShellRotZ = RotZ + math.random(-1,1)*math.pi*types.Weapon.records[types.Actor.getEquipment(self, 16).recordId].slashMinDamage/(180*11)
								local ray = nearby.castRay(util.vector3(0, 0, 80) + self.position,
									util.vector3(0, 0, 80) + self.position +
									util.vector3(math.cos(Shotgun.ShellRotZ) * math.sin(Shotgun.ShellRotX),math.cos(Shotgun.ShellRotZ) * math.cos(Shotgun.ShellRotX), -math.sin(Shotgun.ShellRotZ)) * shelldistance,{ ignore = self })
							
									
								if ray.hitObject and ray.hitObject.type == types.Creature and types.Actor.isDead(ray.hitObject)==false then
									print(ray.hitObject, Shotgun.shellDamage)
									ray.hitObject:sendEvent('DamageEffects', { damages = Shotgun.shellDamage }) --,enchant=S.shellEnchant})
								end
							end
						end
					end
				end
	end


--	if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
--		self.controls.movement=0
--	end
	

end

return {
	eventHandlers={},
	engineHandlers = {onUpdate=onUpdate}
}


