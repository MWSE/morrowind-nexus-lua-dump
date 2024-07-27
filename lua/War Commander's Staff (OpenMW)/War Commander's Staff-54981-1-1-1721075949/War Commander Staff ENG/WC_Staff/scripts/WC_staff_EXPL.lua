local types = require('openmw.types')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local core = require('openmw.core')
local storage = require('openmw.storage')

--local doOnce = 0
local radius = 50 --начальный радиус сферы поражения (диаметр модели шара - 100 см)
local stepRadiusPS = 1250
local DamagedActors = {} -- = { ['@0x1'] = true} ранее для игнорирования игрока
local theActor
local AggressivePlayer

--проверка настройки на урон игроку
local function damageToPlayer()
local settings = storage.globalSection('SettingsWCStaff')

local PlayerDamaged = settings:get('PlayerDamaged')
local TestMessage = settings:get('TestMessage')

	if PlayerDamaged == false then --если игрок не поражается
	--print(string.format('player not damaged, PlayerDamaged %s', PlayerDamaged))
	--в таблицу уже пораженных актеров добавляется игрок
	PlayerID = tostring(AggressivePlayer.id)
	DamagedActors[PlayerID] = true
	else
	--print(string.format('player damaged, PlayerDamaged %s', PlayerDamaged))
	DamagedActors = {} --таблица уже пораженных актеров пустая, и игрок будет поражен
	end
end

-------------
local function Damage(dt)  --DT 0,015284599736333 - FPS 66.6

currentActors = nearby.actors

	radius = radius + stepRadiusPS * dt -- + 50
	for _, theActor in ipairs(currentActors) do
	
		if types.Actor.isDead(theActor) == false then --проверка, что цель жива
		local distance = (self.position - theActor.position):length() --расстояние от центра шара до актера
		--print (string.format('distance, %s, radius %s', distance, radius))
			if distance <= radius then  --проверка на расстояние 
			--print (string.format('distance, %s, the Actor %s, radius %s', distance, theActor, radius))
			
			--проверка на непринадежность актера к уже поврежденным актерам
				if not DamagedActors[theActor.id] then
				if TestMessage then print (string.format('distance, %s, the Actor %s, radius %s', distance, theActor, radius)) end 
				IDtoStr = tostring(theActor.id)
				--чисто визуальный заклинание wcs_explode_vis, мини-активатор wcs_explode_visactiv и сразу удаляется (setdelete 1).
				core.sendGlobalEvent('AddVisualFire', {VisualFirePos = theActor.position}) --событие на появление активатора с ExplodeSpell
				core.sendGlobalEvent('AddDamagingScript', {theActor = theActor}) --событие в глобальный скрипт, добавлеющее локальный скрипт для уменьшения здоровья актера
				DamagedActors[IDtoStr] = true  --добавление в таблицу уже пораженных игроков
				end
			end --конец проверки на расстояние
		end --конец проверки жизни
	end --конец for

end
----------------
return {
    engineHandlers = {
	
	onInit = function(data) 
	AggressivePlayer = data.AggressivePlayer --получения данных об игроке, запустившем огненный шар, для его внесения в таблицу исключений поражения (в зависимости от настроек)
	doOnce = 0  --при инициации скрипта, чтобы скрипт сработал и нанес урон
	end,	

	onUpdate = function(dt)
	if doOnce == 0 then damageToPlayer() doOnce = 1 end --проверка на урон по самому себе
		
	Damage(dt)
	--print(string.format('explosion successfully added'))
	end, --конец onUpdate
	},
	
	eventHandlers = { 
	AddVisualFire = AddVisualFire, --событие для добавления активатора с заклинанием огненного взрыва на 0 для внешнего эффекта
	AddDamagingScript = AddDamagingScript --добавление скрипта урона к актеру-цели
	}
}