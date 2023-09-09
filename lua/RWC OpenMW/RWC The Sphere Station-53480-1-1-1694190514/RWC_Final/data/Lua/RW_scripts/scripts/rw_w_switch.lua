local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local Weapon = require('openmw.types').Weapon
--local ui = require('openmw.ui')  --временно, потом закоккментить

--------------------------
local RGauntletSlot = Actor.EQUIPMENT_SLOT.RightGauntlet
local usedWeapon = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
local weaponRecord = usedWeapon and usedWeapon.type == Weapon and Weapon.record(usedWeapon)
local RGauntlet = Actor.equipment(self, Actor.EQUIPMENT_SLOT.RightGauntlet)
---------------------------
--функция проверки, одета ли униперчатка, и её снимания; 
--вынесено в отдельную функцию, чтобы каждый раз не вставлять один и тот же кусок
function TakeoffSwitchUni()
if RGauntlet and RGauntlet.recordId:find('rw_w_switch_uni') then
	if currentRGauntlet then --если была одета какая-то перчатка
	--ui.showMessage('Equiped currentRGauntlet')
		if   currentRGauntlet.count  > 0 then -- проверка, что перчаток больше 0 в инвентаре, на случай, если её выложили
		local putRGauntlet = Actor.equipment(self)
		putRGauntlet[Actor.EQUIPMENT_SLOT.RightGauntlet] = currentRGauntlet
		Actor.setEquipment(self, putRGauntlet)
		else -- если перчаток 0 (была выложена из инвентаря), то появится рука без перчатки
		local NoGauntlet = Actor.equipment(self)
		NoGauntlet[Actor.EQUIPMENT_SLOT.RightGauntlet] = nil
		Actor.setEquipment(self, NoGauntlet)
		end --конец проверки количетсва перчаток в инвентаре
	else --если currentRGauntlet == nil, то есть перчатка не была надета
	--ui.showMessage('Unequiped RGauntlet')
	local NoGauntlet = Actor.equipment(self)
	NoGauntlet[Actor.EQUIPMENT_SLOT.RightGauntlet] = nil
	Actor.setEquipment(self, NoGauntlet)
	end
end
end --конец функции TakeoffSwitchUni

return {
    engineHandlers = {
-- покадровая проверка
	onFrame = function(dt)
	usedWeapon = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
	weaponRecord = usedWeapon and usedWeapon.type == Weapon and Weapon.record(usedWeapon)
	RGauntlet = Actor.equipment(self, Actor.EQUIPMENT_SLOT.RightGauntlet)
	--проверка на снятие оружия (кулаки)
	if not weaponRecord then
		if RGauntlet and RGauntlet.recordId:find('rw_w_switch_uni') then --если при кулаках одета униперчатка, то снять её 
		TakeoffSwitchUni()
		else 
		return false--если никакого оружия не одето, и не одета униперчатка то скрипт прерывается
		end
	end --конец проверки кулаков
	
	if usedWeapon then
	local returnType = (weaponRecord.type == Weapon.TYPE.MarksmanBow or weaponRecord.type == Weapon.TYPE.MarksmanCrossbow)
		if returnType then  -- проверка, что одет арбалет или лук; рабочая
		--ui.showMessage('You equiped bow/crossbow')  --проверочное сообщение, что одел лук или арбалет
			if Actor.stance(self) == Actor.STANCE.Weapon then  -- проверка, вытащено ли оружие
					if RGauntlet and not RGauntlet.recordId:find('rw_w_switch_uni') then --проверка, что униперчатка не одета, но одета другая перчатка
					currentRGauntlet = RGauntlet  -- запомнить ID надетой перчатки
					--ui.showMessage('You not equiped uni_switch')  --проверочное сообщение, что именно униперчатка не одета
					local uniswitch = Actor.equipment(self)
					uniswitch[Actor.EQUIPMENT_SLOT.RightGauntlet] = 'rw_w_switch_uni'
					Actor.setEquipment(self, uniswitch)
					elseif not RGauntlet then --проверка, что перчатка вообще не одета
					currentRGauntlet = nil --присвоение nil запомненной перчатке, если перчатки не было на руке
					--ui.showMessage('You not equiped any RGauntlet') --проверочное собщение, что никакая перчатка не одета
					local uniswitch = Actor.equipment(self)
					uniswitch[Actor.EQUIPMENT_SLOT.RightGauntlet] = 'rw_w_switch_uni'
					Actor.setEquipment(self, uniswitch)
					end --конец проверки неодетости униперчатки
			else --если оружие не вытащено
			--проверка и снятие униперчатки
			TakeoffSwitchUni()
			end
		else --	если одеты не лук/арбалет
		--проверка и снятие униперчатки
			TakeoffSwitchUni()
		end --конец returnType, проверки, что одет лук/арбалет
	end
	
	end,  -- конец onFrame
    }
}