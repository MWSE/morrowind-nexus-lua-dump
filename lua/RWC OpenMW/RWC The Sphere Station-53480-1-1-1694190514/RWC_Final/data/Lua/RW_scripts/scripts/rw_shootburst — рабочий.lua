local ui = require('openmw.ui')
local self = require('openmw.self')
local A = require('openmw.types').Actor   --для проверки экипировки
--local time = require('openmw_aux.time')
local input = require('openmw.input')
--переменные
local firemode  -- переменная режима стрельбы, булева
firemode = false --исходно выключен режим очереди
local timePassed = 0  --переменная-таймер для пулемета
--local timePassed2 = 0  --переменная-таймер для экпериментов со скорострельностью у пулеметов

--начало обработчиков движка
return {
    engineHandlers = {
-- покадровая проверка, используется для определения auto оружия и патронов 
	onUpdate = function(dt)  -- function(dt)
	
		--фунция проверки оружия на auto
		if firemode == true then
		local weapon = A.equipment(self, A.EQUIPMENT_SLOT.CarriedRight)
		if weapon and not weapon.recordId:find('auto') then
		ui.showMessage('This weapon cannot fire bursts')
		firemode = false
		end
		end
		
		--фунция проверки патронов на auto
		if firemode == true then
		local ammo = A.equipment(self, A.EQUIPMENT_SLOT.Ammunition)
		if ammo and not ammo.recordId:find('auto') then
		ui.showMessage('This ammo cannot fire bursts')
		firemode = false
		end	
		end
		--функция перевода пулемета в автоогонь
		local weapon3 = A.equipment(self, A.EQUIPMENT_SLOT.CarriedRight)
		if weapon3 and weapon3.recordId:find('rw_rifle') then
			--включает всегда режим очереди
			if firemode == false then
			firemode = true
			ui.showMessage('Machinegun fires only bursts')
			end
		end --конец автоогня для пулемета
		--функция огня
		if firemode == true then
			if input.isMouseButtonPressed(1) == true then
			local weapon2 = A.equipment(self, A.EQUIPMENT_SLOT.CarriedRight)
				--блок для обычной пушки
				if weapon2 and weapon2.recordId:find('rw_gun') then
					if self.controls.use == 1 then
					self.controls.use = 0
					else
					self.controls.use = 1
					end
				end --конец блока обычной пушки
				--блок пулемета с таймером для снятия стамины за выстрел
				if weapon2 and weapon2.recordId:find('rw_rifle') then
				local cfat = A.stats.dynamic.fatigue(self).current --текущее значение стамины
				if (cfat > 5 ) then -- быстрые очереди с отъемом стамины при стамине > 5				
					--if (timePassed2 < 2 ) then --эксперимент
					if timePassed < 0.083 then --здесь частота выстрелов, интервал в секундах --не имеет смылса меньше 0.017??? (при фпс 60), либо ускорять пулмет в редакторе; 
					self.controls.use = 1
					timePassed = timePassed + dt
					--timePassed2 = timePassed2 + dt -- эскперимент
					else
					self.controls.use = 0
					--local cfat = A.stats.dynamic.fatigue(self).current --текущее значение стамины
					A.stats.dynamic.fatigue(self).current = math.max(0, cfat - 3) --отнять 3 стамины
					timePassed = 0					
					end
					--end--конец эксперимента
				end --конец блока быстрых очередей
				if (cfat <= 5 ) then -- медленные очереди, без расхода стамины с отъемом стамины при стамине <= 5	
					--[[if (timePassed < 0.5 ) then --здесь частота выстрелов 2 в секунду,
					self.controls.use = 1
					timePassed = timePassed + dt
					else
					self.controls.use = 0
					timePassed = 0
					ui.showMessage('Not enough energy to fire a burst')
					--]]
					--end
					
					--local equipment = A.equipment(self)
					--equipment[A.EQUIPMENT_SLOT.CarriedRight] = nil
					--A.setEquipment(self, equipment)
					A.setStance(self, 0) -- убирание пулеметов в инвентарь при кончившейся энергии
					ui.showMessage('Not enough energy to fire a burst')
					end --конец блока медленных очередей
				end --конец блока пулемета
			end --конец нажатия мышки		
		end --конец функции огня
	end,
--блок переключения режима огня при нажатии N
	onKeyPress = function(key)
		if key.symbol == 'n' then
			if firemode == false then
                ui.showMessage('Burst firing enabled')
			firemode = true
			RemFatOnce = 0
			else
                ui.showMessage('Burst firing disabled')
				firemode = false
			end	
	    end  -- конец символа N 
		--if key.symbol == 'b' then --сброс экспериментального таймера по нажатию B
		--timePassed2 = 0
		--end
	end,  -- конец onKeyPress
    }
}