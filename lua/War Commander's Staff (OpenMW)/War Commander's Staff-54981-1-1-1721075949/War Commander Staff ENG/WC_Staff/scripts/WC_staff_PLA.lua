--[[скрипт для проверки взмахов посохом, и отправки контролируемого огненного шара
GetLOS не нужен
----------
нажатие кнопок и сообщения доступны только из скрипта типа PLAYER - не нужно
создание новых шаровых молний только из скрипта типа GLOBAL
нужно 4 скрипта и сделать обмен данными, 
управление движением шара из глобального скрипта, скрипт на шаре не нужен, шар будет один

----
добавлено условие, что для работы скрипта должен быть надеты посох - перед необходимыми действиями запрашивается функция checkStaff

--известная ошибка - при подъеме огненной соли шар может запуститься не сразу, а только со второго взмаха, но я перенес т строки выше
--]]

local ui = require('openmw.ui') --вывод сообщений -- а оно нужно, как минимум для тестов
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
--local input = require('openmw.input') --не нужен
local util = require('openmw.util')
local camera = require('openmw.camera')
local core = require('openmw.core')

local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local Actor = types.Actor

local Shot = 0 --для проверки момента взмаха посохом
local Ball = false -- для проверки состояния шара, он может быть взорван глобальным скриптом при достижении цели, а локальный скрипт продолжит передавать данные
local BallEndPos
local timer = 0  --для задержки удаления шара, если нет маны
--------------------------------------------------------
--раздел настроек
local settings = storage.globalSection('SettingsWCStaff') -- storage.globalSection(sectionName)
--страница регистрации скрипта только в скрипте игрока, сами настройки в глобальном
I.Settings.registerPage {
    key = 'WC Staff',
    l10n = 'WC_Staff',
    name = 'War Commander`s Staff',
    description = 'WC Staff Description',
	}

--------------------------------------------------------
--функция проверки надетого посоха
local function checkStaff()
local equip = types.Actor.getEquipment(self)
	if equip[types.Actor.EQUIPMENT_SLOT.CarriedRight] and equip[types.Actor.EQUIPMENT_SLOT.CarriedRight].recordId == 'wcs_war_staff' then  --wcs_staff
	return true
	else --если посох не надет
	return false
	end
end
---------------------------------------------
--функция проверки наличия огненной соли в инвентаре 
local function checkFSalt()
	if settings:get('Need Fire Salt') == true then --проверка 
		local Salt = Actor.inventory(self):find('ingred_fire_salts_01')
		if Salt then		
		if TestMessage then print ('fire salt in inventory') end
		core.sendGlobalEvent('SaltRemove', {Salt = Salt}) -- событие в глобальный скрипт для удаления огнесоли
		return true
		else
		if TestMessage then print ('not fire salt in inventory') end
		return false
		end
	else
	if TestMessage then print ('fire salt is not needed') end
	return true
	end
end
---------------------------------------------
--функция добавления шара при взмахе
local function AddBall()
	--проверка на тип камеры
	if camera.getMode() == camera.MODE.FirstPerson then  --если от 1го лица
	local BallStartPos = camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5))*150 --стартовая позиция шара в 150 ед перед лицом игрока
	--print (string.format("%s", BallStartPos))
	core.sendGlobalEvent('BallLaunched', {BallStartPos=BallStartPos, AggressivePlayer = self})
	elseif camera.getMode() == camera.MODE.ThirdPerson or camera.getMode() == camera.MODE.Preview then --если 3 лицо или
	
	--local playerPos = self.position + util.vector3(0, 0, self:getBoundingBox().halfSize.z)
	local playerAngleZ = self.rotation:getYaw() --в радианах
	local BallPosX = self.position.x + 150 * math.sin (playerAngleZ)
	local BallPosY = self.position.y + 150 * math.cos(playerAngleZ)
	local BallPosZ = self.position.z + self:getBoundingBox().halfSize.z
	local BallStartPos = util.vector3(BallPosX, BallPosY, BallPosZ)
	if TestMessage then print(string.format("3rd person starting ball position, %s", BallStartPos)) end 
	core.sendGlobalEvent('BallLaunched', {BallStartPos=BallStartPos, AggressivePlayer = self})
	else
	return false
	end --конец проверки типа камеры
end --конец функции добавления шара
----------------------------------------------
--функция взрыва шара при втором взмахе
local function ExplodeBall()
	if TestMessage then print('the fireball is exploded by the swing of the staff') end 
	core.sendGlobalEvent('BallExplode', {})  
end 
----------------------------------------------
--функция проверки типа камеры, работает от 1 и 3го лица ,не работает Static и Vanity
local function checkCamera()
	if camera.getMode() == camera.MODE.FirstPerson or camera.getMode() == camera.MODE.ThirdPerson or camera.getMode() == camera.MODE.Preview then 
	return true
	else
	return false
	end
end
--функция отслеживания взмаха посохом на 0, 1,2,3 для удаления шара
local function checkShot()
	if checkStaff() == true then --проверка на надетый посох
		if types.NPC.stats.skills.destruction(self).modified > settings:get('RequiredDestruction') then--проверка на уровень Разрушения 
			--print ('Your level of destruction is good')
			if checkCamera() then  --проверка на тип камеры игрока
				if Actor.stance(self) == 1 then  --проверка на позу
					
						if self.controls.use == 1 then
							if Shot == 0 then
							Shot = 1 
							--ui.showMessage('staff is raised')
							elseif Shot == 2 then
							Shot = 3
							end
						
						elseif self.controls.use == 0 then
							if Shot == 1 then
								if checkFSalt() == true then	  --проверка на наличие соли
								AddBall()
								--print ('ball launched')
								Ball = true
								--Shot = 2 --при переносе сюда шар запускается при подборе соли в инвентарь
								end
								Shot = 2  --??? исходно было тут, попытка перенести выше неудачна
								elseif Shot == 3 then
								if Ball == true then --если шар появился (при наличии соли)
								ExplodeBall()
								Ball = false
								--Shot = 0 --при переносе сюда шар запускается при подборе соли в инвентарь
								end
								Shot = 0  --??? исходно было тут, попытка перенести выше неудачна
							end				
						end			
						
				end --конец отслеживания позы
			end --конец проверки типа камеры
		--else --если уровень разрушения игрока меньше требуемого уровня Разрушения
		--if TestMessage then print ('Your level of destruction is too low') end --то сообщение при включенных тестовых сообщениях
		end -- конец проверки на уровнь разрушения
	end --конец провеки на надетый посох
end --конец функции отслеживания удара
--------------------------------------------------------
--функция отслеживания состояния шара, если он будет взорван из глобального скрипта
local function BallDeleted()
Ball = false
Shot = 0
end
--------------------------------------------------------
--функция движения шара, запускается через onUpdate если только Ball == true; также отнимает ману у игрока, 
--отъем маны в секунду регулируется настройками от 0 до 30
local function MoveBall(dt)

----отъем маны у игрока
local magickaCost = settings:get('ManaCost')
local magicka = types.Actor.stats.dynamic.magicka(self)
	if magicka.current > 0 or magickaCost == 0 then
	magicka.current = magicka.current - magickaCost * dt
	--расчет конечной точки движения шара
	local MaxDistance = settings:get('MaxDistance')
	local SightEndPos = camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * MaxDistance
	--print ('the fireball is flying...')
	local SightStartPos = camera.getPosition()
	local target = nearby.castRay(SightStartPos, SightEndPos, {ignore=self})
	local target = 	target.hitPos --target.hitObject

		if target then
		BallEndPos = target  
		else
		BallEndPos = SightEndPos
		end
	core.sendGlobalEvent('BallMoveCoordinates', {BallEndPos = BallEndPos})
	
	elseif  magickaCost > 0 then-- если стоимость полета шара больше 0
		if magicka.current <= 0 then --если маны нет
		--взрываем шар		
			if timer < 0.1 then
			timer = timer + dt
			else
			Ball = false
			Shot = 0
			timer = 0
			if TestMessage then print('out of mana') end 
			core.sendGlobalEvent('BallExplode', {})
			end
		end
	end --конец проверки маны и цены полета
end --конец функции движения шара
----------------------------------------------------------

return {
    engineHandlers = {

	onUpdate = function(dt)
	
	TestMessage = settings:get('TestMessage')
	if settings:get('Mod ON') == false then 
		--if TestMessage then print ('MOD wc_staff is OFF') end
	return false end
	
	checkShot()
	
	if Ball == true then --если шар существует, то включается функция движения шара
		MoveBall(dt)
	end
	
	end, --конец onUpdate
	},
	
	eventHandlers = { 
	BallLaunched = BallLaunched, --событие добавления летящего шара-активатора
	BallExplode = BallExplode, --событие взрыва и удаления летащего шара активатора по взмаху посоха
	BallDeleted = BallDeleted, --события взрыва шара глобальным скриптом
	BallMoveCoordinates = BallMoveCoordinates, --событие для передачи конечной координаты шара
	SaltRemove = SaltRemove, --событие для удаления огненной соли из глобального скрипта
	}
}