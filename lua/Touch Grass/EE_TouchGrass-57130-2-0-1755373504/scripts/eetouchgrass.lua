local async = require('openmw.async')
local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')

local canQueryTextures = core.API_REVISION >= 78
local unitsPerFoot = 21.33
local activationDistance = core.getGMST('iMaxActivateDist')
local activationDistance2 = activationDistance * activationDistance
local collisionFlags = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Camera + nearby.COLLISION_TYPE.VisualOnly
local l10n = core.l10n('eetouchgrass')
local grass = { ex_mh_pav_land_e = true, ex_mh_pav_land_w = true }

local function castRay(screenPos, distance, flags)
	local direction = camera.viewportToWorldVector(screenPos):normalize()
	local start = camera.getPosition()
	local destination = start + direction * distance
	return start, nearby.castRay(start, destination, { ignore = self, collisionType = flags }), direction
end

local function reportTextureAt(x, y)
	local distance = 7168
	local start, result, direction = castRay(util.vector2(x, y), distance, nearby.COLLISION_TYPE.HeightMap)
	local fallback = false
	if not result.hit then
		-- Sometimes raycasts fail to hit terrain; idk Bullet bug or something
		for i = 1, 100 do
			local pos = start + direction * (distance / 100 * i)
			local terrainHeight = core.land.getHeightAt(pos, self.cell)
			if terrainHeight >= pos.z then
				result = { hit = true, hitPos = pos }
				fallback = true
				break
			end
		end
	end
	if result.hit and result.hitObject == nil then
		local texture, plugin = core.land.getTextureAt(result.hitPos, self.cell)
		local message = 'Found texture "' .. (texture or '[none]') .. '" set by plugin "' .. (plugin or '[none]') .. '"'
		if fallback then
			message = message .. ' using coarse ray cast'
		end
		ui.printToConsole(message, ui.CONSOLE_COLOR.Info)
	end
end

local function touchedGrass(result)
	if result.hit then
		if result.hitObject ~= nil then
			local recordId = result.hitObject.recordId
			if grass[recordId] == true then
				return true
			end
			return recordId:find('grass') ~= nil
		elseif not canQueryTextures then
			return false
		end
		local texture = core.land.getTextureAt(result.hitPos, self.cell)
		if texture ~= nil then
			return texture:find('grass') ~= nil
		end
	end
	return false
end

local function checkForGrass()
	local range = activationDistance
	local magnitude = self.type.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis).magnitude
	range = range + math.ceil(magnitude * unitsPerFoot)
	local start, result = castRay(util.vector2(0.5, 0.5), range, collisionFlags)
	local touched = touchedGrass(result)
	local telekinetically = false
	if touched then
		local distance = (result.hitPos - start):length2()
		telekinetically = distance > activationDistance2 
	end
	return touched, telekinetically
end

input.registerTriggerHandler('Activate', async:callback(function()
	local touchedGrass, telekinetically = checkForGrass()
	if touchedGrass then
		if telekinetically then
			ui.showMessage(l10n('telekineticallyTouchedGrass'))
		else
			ui.showMessage(l10n('touchedGrass'))
		end
	end
end))

local mousePosWidget = ui.create({
	type = ui.TYPE.Widget,
	layer = 'Windows',
	props = {
		relativeSize = util.vector2(1, 1),
		visible = false
	},
	events = {
		mouseRelease = async:callback(function(e)
			if not self.cell.isExterior then
				return
			end
			local screenSize = ui.screenSize()
			local x = e.position.x / screenSize.x
			local y = e.position.y / screenSize.y
			reportTextureAt(x, y)
		end)
	}
})

local mousePosWidgetEnabled = false

local function setMousePosWidgetVisible(visible)
	if mousePosWidget.layout.props.visible == visible then
		return
	end
	mousePosWidget.layout.props.visible = visible
	mousePosWidget:update()
end

return {
	eventHandlers = {
		UiModeChanged = function(data)
			setMousePosWidgetVisible(mousePosWidgetEnabled and data.newMode == nil)
		end
	},
	interfaceName = 'EE_TouchGrass',
	interface = {
		version = 1,
		--- Turns landscape texture debugging on or off
		-- @function toggle
		-- @param #boolean state Optional state to toggle to
		toggle = function(state)
			if not canQueryTextures then
				error('This feature requires API revision 78+')
			end
			if state == nil then
				mousePosWidgetEnabled = not mousePosWidgetEnabled
			elseif(type(state) == 'boolean') then
				mousePosWidgetEnabled = state
			else
				error('state must be a boolean or nil')
			end
			setMousePosWidgetVisible(mousePosWidgetEnabled)
		end,
		--- Add the given record ID to the list of grass objects.
		-- @function addGrassObject
		-- @param #string recordId The record ID
		addGrassObject = function(recordId)
			grass[recordId] = true
		end,
		--- Remove the given record ID from the list of grass objects.
		-- @function removeGrassObject
		-- @param #string recordId The record ID
		removeGrassObject = function(recordId)
			grass[recordId] = nil
		end
	}
}
