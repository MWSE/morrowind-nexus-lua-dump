local this = {}


--[[ Возврат предметов из временного контейнера
*
*	@param id_prim  	- id контейнера 
*	@param id_temp		- id временного контейнера
*
--]]
this.resetSort = function(id_prim, id_temp)
	local crate_tmp = tes3.getReference(id_temp)
	
	for i, eim in pairs(crate_tmp.object.inventory) do
		if (eim.object) then
			tes3.transferItem{from=crate_tmp.id, to=id_prim, item=eim.object, count=eim.count, playSound=false}
		end
	end
end

--[[ Сортировка элементов по магическим эффектам
*
*	@param e  			- id контейнера 
*	@param id_temp		- id временного контейнера
*	@param effect		- название эффекта
*	@param objType		- тип предмета
*	@param enchantOff 	- есть ли зачарование на предмете
*
--]]
this.itemSort = function(e, id_temp, effect, objType, enchantOff)

	enchantOff = enchantOff or nil
	local effects
	local effectN

	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			if (eim.object.enchantment or enchantOff) then
				if eim.object.objectType == objType then
					if eim.object.enchantment then
						effects = eim.object.enchantment.effects
					else
						effects = eim.object.effects
					end
					local test = false
					for i = 1,#effects do
						if objType == 1380404809 then  
							effectN = effects[i]
						else
							effectN = effects[i].id
						end
						if effectN == effect then test = true end
					end
					if (not test) then
						tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
					end
				end
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

--[[ Сортировка редких предметов
*
*	@param e  			- id контейнера 
*	@param id_temp		- id временного контейнера
*
--]]
this.legendRaroSort = function(e, id_temp)--Легендарные предметы
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			for i = 0,#cosaLegenda do
				if obj_id == cosaLegenda[i] then test = true end
			end
			if (not test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

this.weaponRaroSort = function(e, id_temp)--Редкое оружие
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			if eim.object.objectType == tes3.objectType.weapon or eim.object.objectType == tes3.objectType.ammunition then
				test = true
			end
			if (not test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

this.armorRaroSort = function(e, id_temp)--Редкие доспехи
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			if eim.object.objectType == tes3.objectType.armor then
				test = true
			end
			if (not test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

this.ringRaroSort = function(e, id_temp)--Редкие кольца
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			if eim.object.objectType == tes3.objectType.clothing then
				if (string.find(obj_id,'[Rr]ing') or string.find(eim.object.mesh,'[Rr]ing') or string.find(eim.object.mesh,'RING')) then
					test = true
				end
			end
			if (not test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

this.amuletRaroSort = function(e, id_temp)--Редкие амулеты
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			if eim.object.objectType == tes3.objectType.clothing then
				if (string.find(obj_id,'[Aa]mulet') or string.find(eim.object.mesh,'[Aa]mulet') or string.find(eim.object.mesh,'AMULET') or string.find(obj_id,'Crystal_Ball') or string.find(obj_id,'Daedric_special')) then
					test = true
				end
			end
			if (not test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

this.ropaRaroSort = function(e, id_temp)--Редкая одежда
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			if eim.object.objectType == tes3.objectType.clothing then
				if (not string.find(obj_id,'[Rr]ing') and not string.find(eim.object.mesh,'[Rr]ing') and not string.find(eim.object.mesh,'RING')) then
					if (not string.find(obj_id,'[Aa]mulet') and not string.find(eim.object.mesh,'[Aa]mulet') and not string.find(eim.object.mesh,'AMULET') and not string.find(obj_id,'Crystal_Ball') and not string.find(obj_id,'Daedric_special')) then
						test = true
					end
				end
			end
			if (not test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

this.miscRaroSort = function(e, id_temp, objType)--Редкие предметы
	local objT 
	
	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			local obj_id = eim.object.id
			local test = false
			if (eim.object.objectType == tes3.objectType.weapon or eim.object.objectType == tes3.objectType.clothing or eim.object.objectType == tes3.objectType.armor or eim.object.objectType == tes3.objectType.weapon or eim.object.objectType == tes3.objectType.ammunition) then
				test = true
			end
			if (test) then
				tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

--[[ Сортировка аппаратов
*
*	@param e  			- id контейнера 
*	@param id_temp		- id временного контейнера
*	@param objType		- Уровень аппарата
*
--]]
this.appSort = function(e, id_temp, objType)

	for i, eim in pairs(e.object.inventory) do
		if (eim.object) then
			if eim.object.objectType == tes3.objectType.apparatus then
				local test = false
				if string.find(eim.object.id, objType)  then  test = true end
				if (not test) then
					tes3.transferItem{from=e.id, to=id_temp, item=eim.object, count=eim.count, playSound=false}
				end
			end
		end
	end
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(e) --открываем контейнер
	end)
end

--[[ Открываем определенный контейнер
*
*	@param ref  	- id контейнера
*
--]]
this.abrirRZZ = function(ref) --открываем определенный контейнер
	local container = tes3.getReference(ref)
	
	cerrarMenu()
	timer.delayOneFrame(function()
		RZZ_activate = true
		tes3.player:activate(container) --открываем контейнер
	end)
end

---[[ Начальные плоды цветка золотого святоши
this.FloraTimeInicio = function()
	if (not data.A_RZZ.is_flora) then
		local count_1 = tes3.getItemCount({ 
			reference = "A_RZZ_flora_gold",
			item = "A_RZZ_goldensaint"
		})
		local count_2 = tes3.getItemCount({ 
			reference = "A_RZZ_flora_gold",
			item = "A_RZZ_dagger_soultrap"
		})
		local count_3 = tes3.getItemCount({ 
			reference = "A_RZZ_flora_gold",
			item = "Gold_001"
		})
		if (count_1 <= 0 and count_2 <= 0 and count_3 <= 0) then 
			data.A_RZZ.timestamp = tes3.getSimulationTimestamp()
			data.A_RZZ.is_flora = true
			--tes3.messageBox{ message = "ok_0->Время пошло: " .. tostring(count_1) .. "-" .. tostring(count_2) .. "-" .. tostring(count_3) }
		end
	end
end

---[[ Добавление урожая цветка золотого святоши
this.FloraTimeRenovacion = function()
	if data.A_RZZ.is_flora then
		local floraTime = 0
		local timestamp = tes3.getSimulationTimestamp()--data.A_RZZ
		if data.A_RZZ.timestamp then floraTime = timestamp - data.A_RZZ.timestamp end
		local timeLimit = 0
		math.randomseed(os.time())
		for i=1,3 do
			timeLimit = math.random(240, 720)--240, 720
		end
		if (floraTime > timeLimit) then
			data.A_RZZ.timestamp = 0
			data.A_RZZ.is_flora = false
			--tes3.messageBox{ message = "Время пришло: " .. tostring(floraTime) }
			--tes3.messageBox{ message = "Время цветения: " .. tostring(timeLimit) }
			tes3.addItem({ 
				reference = "A_RZZ_flora_gold", 
				item = "A_RZZ_goldensaint", 
				count = 5, 
				playSound = false
			})
			tes3.addItem({ 
				reference = "A_RZZ_flora_gold", 
				item = "A_RZZ_dagger_soultrap", 
				count = 5, 
				playSound = false
			})
			tes3.addItem({ 
				reference = "A_RZZ_flora_gold", 
				item = "Gold_001", 
				count = 55555, 
				playSound = false
			})
		end
	end
end

---[[ Добавление заклинания RZZ
this.addRZZSpell = function()
	local hasSpell = tes3.hasSpell({ reference = tes3.player, spell = "A_RZZ_Enter" })

	if (not hasSpell) then 
		tes3.addSpell({ reference = tes3.player, spell = "A_RZZ_Enter" })
	end
end

---[[ Благословение дракона
this.Medico = function() 
	cerrarMenu()
	tes3.cast({ 
		reference = tes3.player,
		target = tes3.player,
		spell = "A_RZZ_Medico",
		instant = true 
	})
end

---[[ Сохранение позиции игрока
this.metka = function()
	if not data then
		data = tes3.player.data
		data.A_RZZ = data.A_RZZ or {}
		tes3.player.modified = true
	end
	
	if not data.A_RZZ.position then data.A_RZZ.position = {} end
	data.A_RZZ.position.x = tes3.player.position.x
	data.A_RZZ.position.y = tes3.player.position.y
	data.A_RZZ.position.z = tes3.player.position.z
	
	if not data.A_RZZ.orientation then data.A_RZZ.orientation = {} end
	data.A_RZZ.orientation.z = tes3.player.orientation.z
	
	data.A_RZZ.cell = tostring(tes3.getPlayerCell())
	
	return
end

---[[ Активация проклятия
this.Maldicion = function(activM)
	activM = activM or nil
	is_maldito = activM
	local isAffectedBy = tes3.isAffectedBy({ reference = tes3.player, object = "A_RZZ_Mal" })
	if (activM) then
		if not isAffectedBy then
			tes3.addSpell({ reference = tes3.player, spell = "A_RZZ_Mal" })
		end
	else
		if isAffectedBy then
		tes3.removeSpell({ reference = tes3.player, spell = "A_RZZ_Mal" })
		end
		return
	end
end

---[[ Активация увеличенной магии
this.MagPlus = function(activMp)
	activMp = activMp or nil
	isMagPlus = activMp
	local isAffectedBy = tes3.isAffectedBy({ reference = tes3.player, object = "A_RZZ_MagPlus" })
	if (activMp) then
		if not isAffectedBy then
			tes3.addSpell({ reference = tes3.player, spell = "A_RZZ_MagPlus" })
		end
	else
		if isAffectedBy then
		tes3.removeSpell({ reference = tes3.player, spell = "A_RZZ_MagPlus" })
		end
		return
	end
end

return this