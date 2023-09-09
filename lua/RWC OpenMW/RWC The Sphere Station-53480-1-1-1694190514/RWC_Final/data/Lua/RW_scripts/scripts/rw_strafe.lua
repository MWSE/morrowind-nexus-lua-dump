local ui = require('openmw.ui')
local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local input = require('openmw.input')
local camera = require('openmw.camera') -- для проверки вида от 3го и первого лица

local timePassedL = 0 --таймер срабатывания клавиши влево, пока 0,3 сек
local timePassedR = 0 --таймер срабатывания клавиши вправо, пока 0,3 сек
local timePassedW = 0 --таймер срабатывания клавиши вперед, пока 0,3 сек
local timeStrafe = 0 --таймер продолжительности стрейфа, 0,15 секунд
local StrafeOn = false
local StrafeCost = 10 --стоимость стрейфа по стамине
local attributes = Actor.stats.attributes --для упрощения --не нужно???
--- не работает local speed = Actor.stats.attributes.speed(self).modifier
local MODE = camera.MODE
local camMode -- переменная для возвращения нужного количества стамины, принимает значения 1 и 3 

local function strafe()
local stamina = Actor.stats.dynamic.fatigue(self).current -- текущий запас стамины (R-element)
	if ( stamina > StrafeCost ) then -- проверка запаса стамины
		if Actor.canMove(self) then --проверка на нокаут и парализацию
			if timeStrafe == 0 then
			--attributes.speed(self).modifier = attributes.speed(self).modifier + 1000
				if camera.getMode() == MODE.FirstPerson then -- разный бонус к скорости для первого и третьего лица, для третьего больше
				StrafeOn = true
				attributes.speed(self).modifier = attributes.speed(self).modifier + 1000
				Actor.stats.dynamic.fatigue(self).current = stamina - StrafeCost
				camMode = 1
				elseif camera.getMode() == MODE.ThirdPerson then
				StrafeOn = true
				attributes.speed(self).modifier = attributes.speed(self).modifier + 3000
				Actor.stats.dynamic.fatigue(self).current = stamina - StrafeCost
				camMode = 3
				end --конец блока выбора камеры
			end --конец проверки timeStrafe == 0
		else
		ui.showMessage('Player cannot move')
		end --конец поверки на нокаут и парализацию
	else
	ui.showMessage('Not enough R-element for strafe')
	end --конец проверки запаса стамины
end

return {
    engineHandlers = {
	onUpdate = function(dt)
		--function (timer)
		timePassedL = timePassedL + dt
		timePassedR = timePassedR + dt
		timePassedW = timePassedW + dt
		
		if StrafeOn == true then
		timeStrafe = timeStrafe + dt
		end
		
		if ( timeStrafe > 0.15 ) then  --должно быть 0.15
		StrafeOn = false
		timeStrafe = 0
			if camMode == 1 then
			attributes.speed(self).modifier = attributes.speed(self).modifier - 1000
			end
			if camMode == 3 then
			attributes.speed(self).modifier = attributes.speed(self).modifier - 3000
			end
		end
		
	end, --конец onUpdate
	
	onInputAction = function(action)
		--начало кнопки влево
		if action ==  input.ACTION.MoveLeft then
		--ui.showMessage('Move left')
			if ( timePassedL < 0.3 ) and ( timePassedL > 0 ) then
				if StrafeOn == false then
				--ui.showMessage('Strafe left!!')
				timeStrafe = 0
				strafe()
				end
				timePassedL = 0
			end
			--обнуление таймера кнопки влево
			if ( timePassedL > 0.3 ) then
			timePassedL = 0
			--ui.showMessage('Too slow!!')
			end
		end --конец input.ACTION.MoveLeft
		
		--начало кнопки вправо
		if action ==  input.ACTION.MoveRight then
		--ui.showMessage('Move right')
			if ( timePassedR < 0.3 ) and ( timePassedR > 0 ) then
				if StrafeOn == false then
				--ui.showMessage('Strafe right!!')
				timeStrafe = 0
				strafe()
				end
				timePassedR = 0
			end
			--обнуление таймера кнопки вправо
			if ( timePassedR > 0.3 ) then
			timePassedR = 0
			--ui.showMessage('Too slow!!')
			end			
					
		end --конец input.ACTION.MoveRight		

		--начало кнопки вперед
		if action ==  input.ACTION.MoveForward then
		--ui.showMessage('Move forward')
			if ( timePassedW < 0.3 ) and ( timePassedW > 0 ) then
				if StrafeOn == false then
				--ui.showMessage('Strafe forward!!')
				timeStrafe = 0
				strafe()
				end
				timePassedW = 0
			end
			
			--обнуление таймера кнопки вперёд
			if ( timePassedW > 0.3 ) then
			timePassedW = 0
			--ui.showMessage('Too slow!!')
			end
		end --конец input.ACTION.MoveForward			
	end, --конец onInputAction	
	    }
}