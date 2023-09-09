--[[часть системы скриптов для самонаводящихся ракет
получает событие от локального скрипта rw_cosmo_target_PLA.lua, после которого генерирует квадратную рамку
если цель меняется, то старая рамкаудаляется, и генериуется новая
новая рамка генерируется даже если снова выбрать ту же цель
также здесь функция движения рамки за целью
удаление рамки при гибели цели
И по событию от  rw_cosmo_target_PLA.lua генерирутеся ракета Векса

--]]

local world = require('openmw.world')
local core = require('openmw.core')
local Actor = require('openmw.types').Actor
--local player = require('openmw.types').Player

local enemyG --переменная для использования данных о враге, полученным скриптом игрока
local TargetPlane --квадратная рамка прицела
local WEXRocket --ракета WEX

--функция генерации рамки вокруг врага по событию из скрипта игрока
local function GenerateTargetPlane(data)
	enemyG = data.enemy
	if TargetPlane then
	TargetPlane:remove(1)
	--TargetPlane = nil
	--else
	TargetPlane = world.createObject('rw_targplane_act_cosm_l')   --rw_targetplane_cosm_lua --квадртаная рамка креатура, появляется, но исчезает при отдалении, как и ари. Пришлось сделать активатор
	TargetPlane:teleport(data.enemy.cell, data.enemy.position)
	world.players[1]:sendEvent('TargetPlaneGenerated', {TargetPlane=TargetPlane})
	else
	TargetPlane = world.createObject('rw_targplane_act_cosm_l')   --rw_targetplane_cosm_lua --квадртаная рамка креатура, появляется, но исчезает при отдалении, как и ари. Пришлось сделать активатор
	TargetPlane:teleport(data.enemy.cell, data.enemy.position)
	world.players[1]:sendEvent('TargetPlaneGenerated', {TargetPlane=TargetPlane})
	end
    -- apply `data.damage` to stats / run custom animation / etc
end

--функция появления ракеты по событию из скрипта игрока
local function RocketWEXLaunched(data)
--нужны данные точки появления WEX ракеты, на 150 единиц перед взглядом игрока просчитываются скриптом игрока
--пока упрощенный вариант, ракета оказывается в точке игрока
WEXRocket = world.createObject('RW_self-guided_rocket_Wex')
WEXRocket:teleport(world.players[1].cell, data.WEXStartPos)  --ракета в 150 перед лицом
end --конец функции появления ракеты


return {
    eventHandlers = { TargLocked = GenerateTargetPlane,
					  RocketWEXLaunched = RocketWEXLaunched},
	
	engineHandlers = {	
	
	onUpdate = function(dt)
	
	--[[if enemyG then
	print(string.format(enemyG.id))
	else 
	print ('nil')
	end --]]
	
	--функция движения рамки за целью
	if TargetPlane and enemyG then
	TargetPlane:teleport(enemyG.cell, enemyG.position) --поискать другие способы, в чатике zackhasacat сказал, что это единственный метод 
	end --конец функции движения рамки	
	
	
	--функция присвоения цели nil, если цель убита, для дальнейшего убирания рамки
	if enemyG then
		if Actor.stats.dynamic.health(enemyG).current < 1 then
		enemyG = nil
		end
	end
	
	--если врага нет (не было или убит), но рамка существует, то удаление рамки
	if not enemyG then --:isValid(false)
		if TargetPlane then
		TargetPlane:remove(1)
		TargetPlane = nil
		world.players[1]:sendEvent('TargetPlaneDestroy')  --передача в локальный скрипт разрушения рамки
		--enemyG = nil
		end
	end --конец удаления рамки

	end, --конец onUpdate

	}
}

