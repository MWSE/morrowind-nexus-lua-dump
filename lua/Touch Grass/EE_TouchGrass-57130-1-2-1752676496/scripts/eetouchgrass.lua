local async = require('openmw.async')
local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')

local unitsPerFoot = 21.33
local activationDistance = core.getGMST('iMaxActivateDist')
local activationDistance2 = activationDistance * activationDistance
local collisionFlags = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Camera + nearby.COLLISION_TYPE.VisualOnly
local l10n = core.l10n('eetouchgrass')
local grass = { 'ex_mh_pav_land_e', 'ex_mh_pav_land_w' }

local function castRay()
	local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
	local start = camera.getPosition()
	local distance = activationDistance
	local magnitude = self.type.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis).magnitude
	distance = distance + math.ceil(magnitude * unitsPerFoot)
	local destination = start + direction * distance
	return start, nearby.castRay(start, destination, { ignore = self, collisionType = collisionFlags })
end

local function touchedGrass(result)
	if result.hit then
		if result.hitObject ~= nil then
			local recordId = result.hitObject.recordId
			for _, id in pairs(grass) do
				if recordId == id then
					return true
				end
			end
			return recordId:find('grass') ~= nil
		elseif core.API_REVISION < 78 then
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
	local start, result = castRay()
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
