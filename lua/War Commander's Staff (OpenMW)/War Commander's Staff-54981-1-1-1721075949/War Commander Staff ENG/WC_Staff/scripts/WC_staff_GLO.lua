--часть системы скриптов для управляемого огненного шара
local world = require('openmw.world')
local core = require('openmw.core')
local Actor = require('openmw.types').Actor
local util = require("openmw.util")
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local FlyingBall
local EndBallPos
local ExplodeON = false
local ExplosionPos --позиция появления взрыва
local CurrentBallPos
local Explosion = nil
local VisualFire = nil
local AggressivePlayer
local saveBall
local saveLight
local saveExplosion
------------------------------
--секция настроек. прописать лучше в глобале, чтобы любой скрипт мог смотреть эти настройки; и для возможности менять настройки только на сервере
local settings = storage.globalSection('SettingsWCStaff') 	
--------
local function boolSetting(key, default)
    return {
        key = key,
        renderer = 'checkbox',
        name = key,
        description = key..'Description',
        default = default,
    }
end
-------------
local function floatSetting(key, default, min, max)
    return {
        key = key,
        renderer = 'number',
        name = key,
        description = key..'Description',
        default = default,
		argument = {
            integer = true,
            min = min,
            max = max,
         }
    }
end
------------

I.Settings.registerGroup({
    key = 'SettingsWCStaff',
    page = 'WC Staff',
    l10n = 'WC_Staff',
    name = 'Settings',
    permanentStorage = true,
    settings = {
        boolSetting('Mod ON', true),
        boolSetting('Need Fire Salt', true),
        boolSetting('PlayerDamaged', true),  --игрок поражается своим же огненным шаром
		floatSetting('ManaCost', 5, 0, 30), --стоимость маны в секунду на полет шара
		floatSetting('ExplDiam', 25, 1, 50), --масштаб расширения взрыва
		floatSetting('MaxDistance', 8000, 500, 15000), --максимальная дальность полета файрболла
		floatSetting('RequiredDestruction', 50, 0, 100), --необходимый уровень разрушения для использоавния посоха
		boolSetting('DependDestruction', true),--урон по врагам зависит от прокачанности Разрушения
		floatSetting('BaseDamage', 100, 5, 500), --базовый урон - если у цели нет модификаторов на сопротивление/уязвимость к огню и огненный щит, и у игрока Разрушение = 100
		floatSetting('stepPerSecond', 1000, 100, 10000), --расстояние, на которое шар смещается на 1 секунду
		boolSetting('TestMessage', false)  --вывод тестовых сообщений в лог F10
    },
})

--функция появления шара-активатора
local function BallLaunched(data)
AggressivePlayer = data.AggressivePlayer
FlyingBall = world.createObject('WCS_ball')
FlyingBall:teleport(AggressivePlayer.cell, data.BallStartPos)

end --конец функции появления шара
---------------------------------------
--функция удаления соли
local function SaltRemove(data)
Salt = data.Salt
Salt:remove(1)
end
---------------------------------------
--функция взрыва и удаления шара
local function BallExplode(data)
	if FlyingBall then
	CurrentBallPos = FlyingBall.position
	FlyingBall:remove(1)
	FlyingBall = nil
	ExplosionPos = CurrentBallPos --для координаты появления взрыва
	EndBallPos = nil	
	ExplodeON = true --для подрыва шара в воздухе
	end
end --конец функции удаления и взрыва шара
------------------------------------------
--функция управления летащим шаром
local function BallTeleported(data) --получение данных о конечной точке шара из скрипта игрока через событие
EndBallPos = data.BallEndPos
end

local function BallMoved(dt)
if EndBallPos then
    if FlyingBall then CurrentBallPos = FlyingBall.position end
    local direction, distance = (EndBallPos - CurrentBallPos):normalize()
    --print (string.format('ball-to-target distance, %s', distance))
	local stepPerSecond =  settings:get('stepPerSecond') --900 (15 * 60)было в оригинале от 100 до 10000, 1000 по-умолчанию, значение из настроек
    local step = stepPerSecond * dt  
	--print (string.format('step, %s', step))
    if distance > step then
        local NewBallPos = CurrentBallPos + direction * step
        if FlyingBall then  FlyingBall:teleport(AggressivePlayer.cell, NewBallPos) end  --Урм предложил FlyingBall:teleport(FlyingBall.cell, NewBallPos)
    else
        AggressivePlayer:sendEvent('BallDeleted')
        ExplosionPos = EndBallPos 
		EndBallPos = nil
		ExplodeON = true --генерация сферы взрыва, раидусом 50 от исходного шара
		if TestMessage then print('the fireball reached its target and exploded') end 
		if FlyingBall then FlyingBall:remove(1) end
		FlyingBall = nil
    end
end
end
------------------------------------------------------------
--функция расширяющегося взрыва до 50 масштабов за 2 секунды, с нанесением урона
local StepScale = 25 --переменная для шага масштаба, в настройки не вынесена

local function ExpandingExplosion(dt)

	if not Explosion then  --если взрыва нет, то его сгенерировать
	Explosion = world.createObject('WCS_expl_ball')
	Explosion:teleport(AggressivePlayer.cell, ExplosionPos)	
	Explosion:addScript('scripts/WC_staff_EXPL.lua', {AggressivePlayer = AggressivePlayer})
	else -- если взрыв существует, то начать расширение

		local ExplDiam = settings:get('ExplDiam') --получение максимального диаметра из настроек
		if Explosion.scale <= ExplDiam then --если масштаб меньше или равен заданному, то расширяем взрыв
		local currentScale = Explosion.scale +  StepScale * dt
		--print (string.format('Scale, %s', currentScale))
		Explosion:setScale(currentScale) 	
		else --если масштаб больше заданного, то удаляем взрыв
		ExplodeON = false
		Explosion:remove(1)
		Explosion = nil		
		end
	end --конец функции генерации либо расширения взрыва
end --конец функции взрыва
----------------
--функция добавления визуального взрыва к актеру по событию из скрипта WC_staff_PLA.lua
local function AddVisualFire(data)
	VisualFire = world.createObject('wcs_explode_visactiv'):teleport(AggressivePlayer.cell, data.VisualFirePos)
end --конец функции генерации визуального взрыва
------------------------------
--функция добавления скрипта к актеру, который будет поврежден
local function AddDamagingScript(data)
local enemy = data.theActor
enemy:addScript('scripts/WC_staff_ACTOR.lua', {AggressivePlayer = AggressivePlayer})
end
----------------------------
--функция удаления скрипта с актера после нанесения урона, иначе урон повторно не пройдет, и вообще там будет висеть скрипт
local function RemoveActorScript(data)
local ActorFRS = data.ActorForRemoveScript   
	if ActorFRS then 
	ActorFRS:removeScript('scripts/WC_staff_ACTOR.lua')
	if TestMessage then print (string.format('the script has been removed from - %s', ActorFRS)) end 
	end
end
----------------------------
--функция удаления активаторов взрыва и файрболла при загрузке при наличии сохраненных данных
local function RemoveActivatorOnLoad()
	if savedBall then
	savedBall:remove(1)
	print('saved fireball deleted')
	saveBall = nil
	savedBall = nil
	saveLight = nil
	end
	
	if savedExplosion then
	savedExplosion:remove(1)
	print('saved explosion deleted')
	saveExplosion = nil
	savedExplosion = nil
	end	
	
	--[[if savedLight then
	savedLight:remove(1)
	print('saved light deleted')
	saveLight = nil
	savedLight = nil
	end	--]]
	
end
---------------------------
return {
    eventHandlers = { BallLaunched = BallLaunched, --генерация летящего шара-активатора
					  BallExplode = BallExplode,  --событие взрыва шара по взмаху посоха из скрипта игрока или по окнчанию маны
					  BallMoveCoordinates = BallTeleported,
					  BallDeleted = BallDeleted, --события взрыва шара глобальным скриптом, когда он долетает до цели
					  AddVisualFire = AddVisualFire, --событие добавления визуального эффекта огня к актерам
					  AddDamagingScript = AddDamagingScript,  --событие в глобальный скрипт, добавляющее локальный скрипт для уменьшения здоровья актера
					  SaltRemove = SaltRemove, --событие для удаления огненной соли из глобального скрипта
					  RemoveActorScript = RemoveActorScript, --события от скрипта актера для удаления с него скрипта, чтобы можно было повторить урон, и вообще там скрипт не висел
					  },  

	engineHandlers = {

	onSave = function(data)
		
		if FlyingBall then
			saveBall = FlyingBall
			--print (string.format('saved fireball, %s', saveBall))
		end
		
		if Explosion then
			saveExplosion = Explosion
		end
		return {saveBall = saveBall, saveExplosion = saveExplosion}
	end, --конец onSave
	
	
	onLoad = function(data)
		if data.saveBall then
			savedBall = data.saveBall
		end
		
		if data.saveExplosion then
			savedExplosion = data.saveExplosion
		end
		
	end, --конец onLoad
	
	onUpdate = function(dt)
	
	RemoveActivatorOnLoad() --удаление файрболла и взрыва при загрузке
	
	TestMessage = settings:get('TestMessage')
	
	--функция движения шара от Урма
	BallMoved(dt)

	if ExplodeON == true then ExpandingExplosion(dt) end -- --print('EXPLOSION')

	end, --конец onUpdate
	}
}