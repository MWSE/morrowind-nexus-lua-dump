--local ui = require('openmw.ui') --сообщения были только для теста
local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local types = require("openmw.types")
--local input = require("openmw.input") --для отслеживания Альт --от системы любимых снарядов отказались
local core = require('openmw.core') --для выведения имени предпочитаемого снаряда
local camera = require('openmw.camera') --для отключение прицела на снайперке

local weapon --переменная для проверка класса оружия gun/rifle/rocketlauncher/sniper
local ammo --переменная для проверки боеприпаса gun/rif/rocket/snip
--gun = gwt   ///    rif=    rqm  ///  snip =   sgz  ///   rocket =  mkz   ///

local newAmmo --переменная для зарядки патронов
local equipment
local CrosshairOn = true

--функция выброса снаряда, если вообще нет никакого подходящего для класса, чтобы нельзя было поставить снаряд другого класса
function UnEquipAmmo()
equipment = Actor.equipment(self)
equipment[Actor.EQUIPMENT_SLOT.Ammunition] = nil
Actor.setEquipment(self, equipment)
end --конец функции  UnEquipAmmo

return {
    engineHandlers = {
-- покадровая проверка,  
	onFrame = function(dt)  -- function(dt)
	weapon = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
	ammo = Actor.equipment(self, Actor.EQUIPMENT_SLOT.Ammunition)
		--начало проверки класса rw_gun
		if weapon and weapon.recordId:find('rw_gun') then
		--если снаряд не для пушки
			if ammo and not ammo.recordId:find('gwt') then 
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('gwt') then
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						end
					else
					UnEquipAmmo()
					end				
				end --конец for
			end
			--если снаряд вообще не заряжен
			if not ammo then
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('gwt') then
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						end
					end				
				end --конец for
			end
			
		end -- конец блока rw_gun
		
		--начало проверки класса rw_rifle
		if weapon and weapon.recordId:find('rw_rifle') then
			--если снаряд не для рифла
			if ammo and not ammo.recordId:find('rqm') then 
				--ui.showMessage('Find ammo') --тестовое сообщение, что начинается поиск снаряда в инвентаре
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('rqm') then
					--ui.showMessage('You have bolt or arrow')
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						--ui.showMessage('You have riffle ammo')
						--ui.showMessage(string.format("newAmmo: %s", types.Weapon.record(newAmmo).name))
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						--else
						--ui.showMessage('bug!!')
						--UnEquipAmmo()
						--ui.showMessage('Have not ammo for this weapon')
						end
					else
					UnEquipAmmo()
					end				
				end --конец for
			end
			--если снаряд вообще не заряжен
			if not ammo then
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('rqm') then
					--ui.showMessage('You have bolt or arrow')
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						--ui.showMessage('You have riffle ammo')
						--ui.showMessage(string.format("newAmmo: %s", types.Weapon.record(newAmmo).name))
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						--else
						--ui.showMessage('bug!!')
						--UnEquipAmmo()
						--ui.showMessage('Have not ammo for this weapon')
						end
					end				
				end --конец for
			end
		
		end -- конец блока rw_rifle
		
		--начало проверки класса rw_rocketlauncher
		if weapon and weapon.recordId:find('rw_rocketlauncher') then
		--если снаряд не для ракетницы
			if ammo and not ammo.recordId:find('mkz') then 
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('mkz') then
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						end
					else
					UnEquipAmmo()
					end				
				end --конец for
			end
			--если снаряд вообще не заряжен
			if not ammo then
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('mkz') then
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						end
					end				
				end --конец for
			end
		end -- конец блока rw_rocketlauncher
		
		--начало проверки класса rw_sniper
		if weapon and weapon.recordId:find('rw_sniper') then
		CrosshairOn = false -- выключение прицела на снайперке
		--если снаряд не для снайперки
			if ammo and not ammo.recordId:find('sgz') then 
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('sgz') then
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						end
					else
					UnEquipAmmo()
					end				
				end --конец for
			end
			--если снаряд вообще не заряжен
			if not ammo then
				for _, newAmmo in ipairs(Actor.inventory(self):getAll(types.Weapon)) do
					if newAmmo.recordId:find('sgz') then
						if (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Bolt) or (types.Weapon.record(newAmmo).type == types.Weapon.TYPE.Arrow) then
						equipment = Actor.equipment(self)
						equipment[Actor.EQUIPMENT_SLOT.Ammunition] = newAmmo
						Actor.setEquipment(self, equipment)
						end
					end				
				end --конец for
			end
		else --для включения прицела
		if not CrosshairOn then CrosshairOn = true end 
		end -- конец блока rw_sniper
		
	--функция дозаряжания подобранных снарядов
	if ammo then
	local ammoID = ammo.recordId
	local ammoID_Str = string.format(types.Weapon.record(ammoID).id)
		if Actor.inventory(self):countOf(ammoID_Str) > ammo.count then --сравнение кол-ва заряженных и общих в инвентаре снарядов
		--ui.showMessage('ammo reloaded') --тестовое сообщение при дозарядке
		local reloadAmmo = Actor.equipment(self)
		reloadAmmo[Actor.EQUIPMENT_SLOT.Ammunition] = nil
		Actor.setEquipment(self, reloadAmmo)
		reloadAmmo[Actor.EQUIPMENT_SLOT.Ammunition] = ammoID
		Actor.setEquipment(self, reloadAmmo)		
		end
	end --конец функции дозарядки
	
	if CrosshairOn == false then camera.showCrosshair(false) end --постоянное отключение прицела на снайперке
	
	end,  -- конец onFrame
    }
}