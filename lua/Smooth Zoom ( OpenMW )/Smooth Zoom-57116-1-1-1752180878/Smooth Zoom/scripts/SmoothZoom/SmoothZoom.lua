local camera = require('openmw.camera')
local input = require('openmw.input')
local core = require('openmw.core')

require('scripts.SmoothZoom.settings')

local storage = require('openmw.storage')
local settings = storage.playerSection('Settings_main_Key')

local DEG_TO_RAD = math.pi / 180

-- функция, возвращающая текущие настройки из storage
local function getCurrentSettings()
    local defaultDegrees = settings:get('DefaultFOV_Degrees') or 60
    local pressedDegrees = settings:get('PressedFOV_Degrees') or 30
    local transition = settings:get('TransitionDuration_Seconds') or 0.3
	local buttonCode = settings:get('InputButtonCode') or "2"
	local inputDevice = settings:get('InputDevice') or 'mouse'
	
    return {
        DEFAULT_FOV = defaultDegrees * DEG_TO_RAD,
        PRESSED_FOV = pressedDegrees * DEG_TO_RAD,
        TRANSITION_DURATION = transition,
		BUTTON_CODE = buttonCode,
		INPUT_DEVICE = inputDevice,
	}
end
-- Сразу загрузить начальные настройки
local currentSettings = getCurrentSettings()

-- Решить какой формат клавиши
local function resolveKeyCode(buttonCode)
	if tonumber(buttonCode) then
		return tonumber(buttonCode)
	elseif type(buttonCode) == "string" then
		local key = input.KEY[buttonCode]
		if key then
			return key
		--else
			--error("Unknown keyboard key: " .. buttonCode)
		end
	--else
		--error("Invalid button code: " .. tostring(buttonCode))
	end
end

-- Определить клавишу
local function setCheckButtonPressed()
	if currentSettings.INPUT_DEVICE == 'mouse' then
		checkButtonPressed = function()
			local btn = tonumber(currentSettings.BUTTON_CODE)
			if not btn then
				error("Invalid mouse button code: " .. tostring(currentSettings.BUTTON_CODE))
			end
			return input.isMouseButtonPressed(btn)
		end
	else
		checkButtonPressed = function()
			local resolved = resolveKeyCode(currentSettings.BUTTON_CODE)
			return input.isKeyPressed(resolved)
		end
	end
end
setCheckButtonPressed()

-- Нужно, что бы обновить горячуюю клавишу
local function checkApplyNow()
    if settings:get('ApplyNow') then
        --print("[DEBUG] apply now triggered")
        currentSettings = getCurrentSettings()
		--print("DEBUG: settings:get('InputDevice') =", settings:get('InputDevice'))
		--print("DEBUG: settings:get('InputButtonCode') =", settings:get('InputButtonCode'))
		setCheckButtonPressed()

        settings:set('ApplyNow', false)
    end
end

-- Переменные состояния
local isTransitioning = false
local transitionStartTime = 0
local startFov = currentSettings.DEFAULT_FOV
local targetFov = currentSettings.DEFAULT_FOV
local lastButtonState = false

local currentAppliedFov = currentSettings.DEFAULT_FOV

-- Устанавить начальный FOV
camera.setFieldOfView(currentAppliedFov)
--print("DEBUG_FOV: Скрипт FOV Changer загружен. Начальный FOV: " .. tostring(currentAppliedFov))

local function onUpdate()
	checkApplyNow()
    local buttonIsPressed = checkButtonPressed()
    local gameTime = core.getGameTime()

    -- если кнопка изменилась — старт переход
    if buttonIsPressed ~= lastButtonState then
        currentSettings = getCurrentSettings() -- обновить настройки на всякий случай
        --print("DEBUG_FOV: Состояние кнопки изменилось: с " .. tostring(lastButtonState) .. " на " .. tostring(buttonIsPressed))
        isTransitioning = true
        transitionStartTime = gameTime
        startFov = currentAppliedFov
        targetFov = buttonIsPressed and currentSettings.PRESSED_FOV or currentSettings.DEFAULT_FOV
        --print("DEBUG_FOV: Запуск перехода. FOV старт: " .. tostring(startFov) .. ", FOV цель: " .. tostring(targetFov))
    end

    if isTransitioning then
        local elapsedTime = gameTime - transitionStartTime
        local t = math.min(1, elapsedTime / (currentSettings.TRANSITION_DURATION * core.getGameTimeScale()))
        local newFov = startFov + (targetFov - startFov) * t

        if newFov ~= currentAppliedFov then
            camera.setFieldOfView(newFov)
            currentAppliedFov = newFov
            --print(string.format("DEBUG_FOV: Переход. Время прошло: %.3fс, Прогресс (t): %.3f, Текущий FOV: %.6f",elapsedTime, t, currentAppliedFov))
        end

        if t >= 1 then
            isTransitioning = false
            currentAppliedFov = targetFov
            camera.setFieldOfView(currentAppliedFov)
            --print("DEBUG_FOV: Переход завершен. Финальный FOV: " .. tostring(currentAppliedFov))
        end
    else
        -- если перехода нет, проверить, что FOV соответствует кнопке
        local desiredFov = buttonIsPressed and currentSettings.PRESSED_FOV or currentSettings.DEFAULT_FOV
        if currentAppliedFov ~= desiredFov then
            --print("DEBUG_FOV: Нет активного перехода, но FOV не совпадает. Установка на: " .. tostring(desiredFov))
            camera.setFieldOfView(desiredFov)
            currentAppliedFov = desiredFov
        end
    end

    lastButtonState = buttonIsPressed
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
