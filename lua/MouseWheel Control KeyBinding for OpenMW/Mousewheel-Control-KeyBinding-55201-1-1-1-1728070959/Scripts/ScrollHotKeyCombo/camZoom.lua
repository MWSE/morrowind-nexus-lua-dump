local input = require('openmw.input')
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')
local async = require('openmw.async')
local camera = require('openmw.camera')
local I = require('openmw.interfaces')
local fp = camera.MODE.FirstPerson
local tp = camera.MODE.ThirdPerson
local curMode = 0


-- Get the keybindings from weapon and spell scroll
local storage = require("openmw.storage")
local controlsSettings = storage.playerSection("SettingsPlayer" .. "ScrollHotKeyCombo" .. "Controls")


local cam = require('openmw.interfaces').Camera

local loadMode = camera.getMode() --What does this do?

local ZOOM_IN = input.KEY.UpArrow --Key that is used to Zoom in
local ZOOM_OUT = input.KEY.DownArrow --Key used to Zoom out
local currentZoom = 35.25 -- cannot remember why I picked 35.25..

local function noKeysPressed()
	local WEAPSCROLL_HOTKEY = controlsSettings:get("nextWeaponHotKey")
	local SPELLSCROLL_HOTKEY = controlsSettings:get("nextSpellHotKey")
	if input.isKeyPressed(WEAPSCROLL_HOTKEY) or input.isKeyPressed(SPELLSCROLL_HOTKEY) then
		return false
	end
    return true
end


local function getZoom()
	local x = cam.getBaseThirdPersonDistance()
    return x
end

local function zoomIn()
	curMode = camera.getMode()
	currentZoom = getZoom()

	if currentZoom <= 35 then
		camera.setMode(fp)
		curMode = 1		--Set a flag that we are in 1st person now.
	else
		cam.setBaseThirdPersonDistance(currentZoom - 10)
		--ui.showMessage(string.format('dt = %f', dt))
		--ui.printToConsole(tostring(currentZoom), util.color.hex("ff0000"))
	end
end

local function zoomOut()
	curMode = camera.getMode()
	currentZoom = getZoom()
	--ui.printToConsole(tostring(currentZoom), util.color.hex("ff0000"))
	if curMode == 1 then 
		camera.setMode(tp)
		curMode = 0
		--currentZoom = getZoom()
		--ui.printToConsole(tostring(currentZoom), util.color.hex("00ff00"))
	else
		cam.setBaseThirdPersonDistance(currentZoom + 10)
		--ui.showMessage(string.format('dt = %f', dt))
	end
end

local function onMouseWheel(vertical, horizontal)
	local vert = vertical
	if not noKeysPressed() or I.UI.getMode() then return end -- Added conditional to handle when ui windows are open to prevent cam zoom
	if vert > 0 then
		--NextSpell is working, need to adopt it to enchanted items
		zoomIn()
	elseif vert < 0 then
		--pass reversed list of spells to NextSpell
		zoomOut()
	end
end


return {
    engineHandlers = {
		--onload = onload,
		--onUpdate = onUpdate,
		onMouseWheel = onMouseWheel,
    }
}