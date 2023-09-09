--[[скрипт для захвата целей в космосе
при нажатии на V проверяет self.object.id цели
вокруг цели появляется квадратная рамка
и сообщение "Цель захвачена: recordId.name"
если рамка есть, то она двигается скриптом в координаты object.id
при уничтожении цели рамка удаляется
рамка должна быть креатурой с огромным запасом здоровья, чтобы с ней работал метод GetLOS ванильного скрипта
в дальнейшем уже ванильным скриптом стреляется по квадратной рамке векс ракетой
при выборе новой цели рамка либо удаляется, либо меняются её координаты, скорее всего меняются координаты
----------
нажатие кнопок и сообщения доступны только из скрипта типа PLAYER
создание новых рамок только из скрипта типа GLOBAL
нужно 2 скрипта и сделать обмен данными, возможно даже 3, третий повесить на рамку для отслеживания координат цели
core.sendGlobalEvent(eventName, eventData) Send an event to global scripts.
GameObject:sendEvent(eventName, eventData)  Send local event to the object.
----
добавить условие, что для работы скрипта должен быть одет шлем корабль rw_sinek_space_ship на игроке 
--]]

local ui = require('openmw.ui') --вывод сообщений
local self = require('openmw.self')
local types = require('openmw.types')
local nearby = require('openmw.nearby')
local input = require('openmw.input')
local util = require('openmw.util')
local camera = require('openmw.camera')
local core = require('openmw.core')

local Actor = types.Actor

local RightTarget = {    --таблица с ID правильных врагов как целей, с новой строки через запятую
	"rw_ari",
	"rw_turel_01",
	"rw_turel_02",
}
local target  --объект, по которому попали лучом локатора
local enemy --враг, т.е. объект в локаторе, подтвержденный в списке врагов
local TargPlane --переменная для objectID рамки, переданной из глобального скрипта
local doOnceRocket --счетчик для запуска WEX ракет, иначе их вылетит 60 штук за секунду, даже при длительности заклинания 0
local doOnceMess1 --переменная-ограничитель, чтобы сообщение о слишком далекой цели выдавалось только 1 раз

--функция поиска ID объекта-цели
local function findTargetID()
--ui.showMessage('Find target')
local startPoint = camera.getPosition() --начальная точка луча, координаты камеры
local endPoint = startPoint + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 30000  --точка на расстоянии 30000 от игрока
--ui.showMessage(string.format("startPoint %s", startPoint))  --сообщение координат начальной точки
--ui.showMessage(string.format("endPoint %s", endPoint)) --сообщение координат конечной точки

target = nearby.castRay(startPoint, endPoint, {collisionType=nearby.COLLISION_TYPE.Actor, ignore=self}) -- первоначально castRenderingRay  --collisionType=nearby.COLLISION_TYPE.Actor
--но castRenderingRay не имеет дополнительных параметров - нельзя  игнорировать игрока и задавать тип коллизий
	if not target.hitObject then ui.showMessage('Target not locked') end --если никакая цель не найдена
	
	if target.hitObject then SortTable() end -- если попал по Актору, то сравнение ID Актора с листом нужных целей

end --конец функции поиска цели

--функция сравнения ID полученной цели с листом целей
function SortTable()
--ui.showMessage(string.format("Target locked: %s", target.hitObject.recordId))
	for _, val in ipairs(RightTarget) do
	--ui.showMessage(string.format("%s", val))
		if val == string.format(target.hitObject.recordId) then
		enemy = target.hitObject --уточнние конкретного врага по objectID
			if target.hitObject.type == types.NPC then   --начало вывода имени верной цели
			local targetName = types.NPC.record(target.hitObject.recordId).name --types.Weapon.record(preferredSnipID).name
			ui.showMessage(string.format("Target locked: %s", targetName))
			elseif target.hitObject.type == types.Creature then
			local targetName = types.Creature.record(target.hitObject.recordId).name
			ui.showMessage(string.format("Target locked: %s", targetName)) 
			end --конец вывода имени верной цели
		--сообщение глобальному скрипту, что нужно сгенерировать квадратную метку
		core.sendGlobalEvent('TargLocked', {enemy = enemy})  --передача данных в глобальный скрипт, enemy - это objectID захваченного врага
		end			
	end -- конец for
end --конец функции отбора врагов по таблице


--функции проверки состояния TargetPlane, получаемые из событий глобального скрипта. нужны для решения о генерации ракеты.
function TargetPlaneDestroy()
TargPlane = nil
--ui.showMessage('Target plane destroy') 
end

function TargetPlaneGenerated(data)
TargPlane = data.TargetPlane  --данные объекта рамки, дляподтверждения запуска WEX-ракеты; пригодятся для чего-нибудь
--ui.showMessage('Target plane activate') 
end

--функция генерации Векс-ракеты перед лицом игрока в 150 единицах, с проверкой GetLOS по рамке и врагу
--векс-ракета летит ванильным скриптом в рамку rw_targplane_act_cosm_l
function AddWEXRocket()
	if Actor.activeSpells(self):isSpellActive('RW_self-guided_rocket_spell_WEX') then --проверка наложенного заклинания
		if TargPlane then --если в ячейке есть рамка
		local distance = (self.position - enemy.position):length()	--вычисление расстояние между игроком и врагом
			if distance < 15000 then --расстояние от игрока до врага <15000
				if GetLOS() == true then
				--ui.showMessage('LOS true')
					if doOnceRocket == true then --проверка на однократный запуск ракеты
					--ui.showMessage('Spell WEX added')
					--print('Spell WEX added')
					local WEXStartPos = camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 150 --стартовая позиция ракеты в 150 ед перед лицом игрока
					core.sendGlobalEvent('RocketWEXLaunched', {WEXStartPos=WEXStartPos})
					doOnceRocket = false
					end --конец проверки на однократный запуск ракеты
				end --конец проверки GetLOS
			else
				if doOnceMess1 == true then
				ui.showMessage('Target too far')
				--print('Target too far')
				doOnceMess1 = false
				end
			end --конец проверки расстояния 15000
		end --конец проверки наличия рамки
	else
	doOnceRocket = true
	doOnceMess1 = true
	end -- конец проверки наложенного заклинания
end --конец функции генерации ракеты

--функция проверки на прямую видимость, аналог GetLOS ванилы
function GetLOS()
local startLOS = camera.getPosition() + camera.viewportToWorldVector(util.vector2(0.5, 0.5)) * 100 --стартовая точка 100 перед лицом игрока
local endLOS = enemy.position --использованы координаты врага, рамка перемещается через teleport, враг постоянно в ячейке
local objectLOS = nearby.castRay(startLOS, endLOS)  -- asyncCastRenderingRay(callback, from, to) {ignore=self}

--if objectLOS.hitObject then local objectLOSrecID = objectLOS.hitObject.recordId print(string.format("LOS: %s", objectLOSrecID)) end
--if objectLOS.hitObject then ui.showMessage(string.format("LOS: %s", objectLOS.hitObject.recordId)) end --собщение с ОбджектИД препятствия


--ui.showMessage(string.format("startLOS %s", startLOS))  --сообщение координат начальной точки
--ui.showMessage(string.format("endLOS %s", endLOS)) --сообщение координат конечной точки
--return objectLOS.hitObject == nil  --возвращает true/false --рекомендация Урма

	if not objectLOS.hitObject or (objectLOS.hitObject == enemy) or (objectLOS.hitObject == TargPlane) then  --исключает как цель луча врага, рамку или ничего.
	--if (objectLOS.hitObject == enemy) or (objectLOS.hitObject == TargPlane) then --если объект в луче - враг или рамка	
	return true
	--ui.showMessage('LOS true')
	else
	--ui.showMessage('LOS false')
	return false	
	end
end --конец функции GetLOS

return {
    engineHandlers = {
	
	onUpdate = function(dt)
	
	AddWEXRocket()
	
	end, --конец onUpdate
	
	onKeyPress = function(key)
		if key.symbol == 'v' then
		--ui.showMessage('Find target')
		findTargetID()
		end --конец нажатия V
	end, -- конец onKeyPress 
	},
	
	eventHandlers = { 
	TargetPlaneDestroy = TargetPlaneDestroy,
	TargetPlaneGenerated = TargetPlaneGenerated,	
	}
}