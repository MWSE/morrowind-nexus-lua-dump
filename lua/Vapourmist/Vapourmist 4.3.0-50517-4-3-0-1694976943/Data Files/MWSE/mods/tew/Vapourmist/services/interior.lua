-- Interior fog module
-->>>---------------------------------------------------------------------------------------------<<<--

-- Imports
local interior = {}
local util = require("tew.Vapourmist.components.util")
local config = require("tew.Vapourmist.config")
local debugLog = util.debugLog
local shader = require("tew.Vapourmist.components.shader")

-->>>---------------------------------------------------------------------------------------------<<<--
-- Constants

local MIN_STAT_COUNT = 5
local MESH = tes3.loadMesh("tew\\Vapourmist\\vapourint.nif")
local HEIGHTS = { -900, -850, -800, -750 }
local SIZES = { 150, 170, 185, 190, 250, 280, 300 }

local MAX_DISTANCE = 8192 * 3
local BASE_DEPTH = 8192 / 32
local DENSITY = 4
local BASE_COLOUR = {
	r = 0.3,
	g = 0.2,
	b = 0.08
}

local NAME_MAIN = "tew_InteriorFog"
local NAME_EMITTER = "tew_InteriorFog_Emitter"
local NAME_PARTICLE_SYSTEMS = {
	"tew_InteriorFog_ParticleSystem_1",
	"tew_InteriorFog_ParticleSystem_2",
	"tew_InteriorFog_ParticleSystem_3"
}


-->>>---------------------------------------------------------------------------------------------<<<--
-- Structures

local interiorStatics = {
	"in_bm_cave",
	"in_moldcave",
	"in_mudcave",
	"in_lavacave",
	"in_pycave",
	"in_bonecave",
	"in_bc_cave",
	"in_m_sewer",
	"in_sewer",
	"ab_in_cave",
	"ab_in_kwama",
	"ab_in_lava",
	"ab_in_mvcave",
	"t_cyr_cavegc",
	"t_cyr_cavech",
	"t_cyr_caveww",
	"t_glb_cave",
	"t_mw_cave",
	"t_sky_cave",
	"bm_ic_",
	"bm_ka",
	"in_dae",
	"t_dae_dngruin",
	"in_dwrv_",
	"in_dwe_",
	"t_dwe_dngruin",
	"in_stronghold",
	"in_strong",
	"in_strongruin",
	"dngruin",
	"t_de_dngrtrongh",
	"t_imp_dngsewers",
	"in_om_",
	"dngdirenni"
}

local interiorNames = {
	"barrow",
	"burial",
	"catacomb",
	"cave",
	"cavern",
	"crypt",
	"tomb"
}

local tracker = {}

-->>>---------------------------------------------------------------------------------------------<<<--
-- Functions

local function isAvailable(cell)

	if cell.name then
		if config.blockedInteriors[cell.name] then
			return false
		end
	end

	for _, namePattern in ipairs(interiorNames) do
		if string.find(cell.name:lower(), namePattern) then
			return true
		end
	end

	local count = 0
	for stat in cell:iterateReferences(tes3.objectType.static) do
		for _, statName in ipairs(interiorStatics) do
			if string.startswith(stat.object.id:lower(), statName) then
				count = count + 1
				if count >= MIN_STAT_COUNT then
					return true
				end
			end
		end
	end

	return false
end

local function switchAppCull(node, bool)
	if (node.appCulled ~= bool) then
		node.appCulled = bool
		node:update()
	end
end

function interior.hideAll()
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			switchAppCull(node, true)
		end
	end
	shader.disableFog()
end

function interior.unhideAll()
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			-- local emitter = node:getObjectByName(NAME_EMITTER)
			switchAppCull(node, false)
		end
	end
	shader.enableFog()
end


local function isCellFogged(cell)
	return table.find(tracker, cell)
end

local function updateTracker(fogMesh, cell)
	tracker[fogMesh] = cell
end

function interior.removeAllFog()
	if not tracker or table.empty(tracker) then return end

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			vfxRoot:detachChild(node)
		end
	end

	tracker = {}

	shader.deleteFog(NAME_MAIN)
end

-- Determine fog position for interiors --
local function getFogLocation(cell)
	local pos = { x = 0, y = 0, z = 0 }
	local denom = 0
	local xs, ys, zs = {}, {}, {}

	for stat in cell:iterateReferences() do
		pos.x = pos.x + stat.position.x
		pos.y = pos.y + stat.position.y
		pos.z = pos.z + stat.position.z
		table.insert(xs, stat.position.x)
		table.insert(ys, stat.position.y)
		table.insert(zs, stat.position.z)
		denom = denom + 1
	end

	local calcZPos
	if cell.hasWater then
		calcZPos = cell.waterLevel - (table.choice(HEIGHTS) * math.random(1,3))
	else
		calcZPos = math.lerp((pos.z / denom), math.min(table.unpack(zs)), 0.05)
	end

	return
		{ x = pos.x / denom, y = pos.y / denom, z = calcZPos },
		{
			width = math.abs(math.max(table.unpack(xs)) - math.min(table.unpack(xs))),
			height = math.abs(math.max(table.unpack(ys)) - math.min(table.unpack(ys))),
			depth =  math.abs(math.max(table.unpack(zs)) - math.min(table.unpack(zs))),
		}
end

---@param val number
---@param coeff string
local function amplifyColour(val, coeff)
	return math.clamp(math.lerp(BASE_COLOUR[coeff], val, 0.8), 0.2, 0.8)
end

---@param cell tes3cell
local function getAverageColour(cell)
	local colour = {r = 0, g = 0, b = 0}
	local denom = 0

	local ambient = {
		r = math.lerp(cell.ambientColor.r > 0 and cell.ambientColor.r/100 or BASE_COLOUR.r, cell.fogColor.r > 0 and cell.fogColor.r/100 or BASE_COLOUR.r, 0.5),
		g =  math.lerp(cell.ambientColor.g > 0 and cell.ambientColor.g/100 or BASE_COLOUR.g, cell.fogColor.g > 0 and cell.fogColor.g/100 or BASE_COLOUR.g, 0.5),
		b = math.lerp(cell.ambientColor.b > 0 and cell.ambientColor.b/100 or BASE_COLOUR.b, cell.fogColor.b > 0 and cell.fogColor.b/100 or BASE_COLOUR.b, 0.5),
	}

	for light in cell:iterateReferences(tes3.objectType.light) do
		local object = light.object
		if (
			object.color[1] < 0 or
			object.color[2] < 0 or
			object.color[2] < 0
		) then return end
		colour.r = (colour.r + (object.color[1] > 0 and object.color[1] or 55) / 255)
		colour.g = (colour.g + (object.color[2] > 0 and object.color[2] or 55) / 255)
		colour.b = (colour.b + (object.color[3] > 0 and object.color[3] or 55) / 255)
		denom = denom + 1
	end

	colour.r = math.lerp(colour.r/denom, ambient.r, 0.9)
	colour.g = math.lerp(colour.g/denom, ambient.g, 0.9)
	colour.b = math.lerp(colour.b/denom, ambient.b, 0.9)

	if denom == 0 then
		return BASE_COLOUR
	else
		return { r = amplifyColour(colour.r, 'r'), g = amplifyColour(colour.g, 'g'), b = amplifyColour(colour.b, 'b') }
	end
end


---@param cell tes3cell
local function addFog(cell)
	debugLog("Adding interior fog.")

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]

	if not isCellFogged(cell) then
		debugLog("Interior cell is not fogged.")
		local interiorFogColor = getAverageColour(cell)
		local pos, size = getFogLocation(cell)

		if config.interiorNIF then
			local fogMesh = MESH:clone()
			fogMesh:clearTransforms()
			fogMesh.translation = tes3vector3.new(
				pos.x,
				pos.y,
				pos.z + table.choice(HEIGHTS) * math.random(1, 2)
			)

			vfxRoot:attachChild(fogMesh, true)

			for _, name in ipairs(NAME_PARTICLE_SYSTEMS) do
				local particleSystem = fogMesh:getObjectByName(name)

				local controller = particleSystem.controller
				local colorModifier = controller.particleModifiers

				controller.emitterWidth = size.width
				controller.emitterHeight = size.height
				controller.emitterDepth = size.depth

				local initialSize = SIZES[math.random(#SIZES)]
				controller.initialSize = initialSize

				for _, key in pairs(colorModifier.colorData.keys) do
					key.color.r = interiorFogColor.r
					key.color.g = interiorFogColor.g
					key.color.b = interiorFogColor.b
				end

				local materialProperty = particleSystem.materialProperty
				materialProperty.emissive = interiorFogColor
				materialProperty.specular = interiorFogColor
				materialProperty.diffuse = interiorFogColor
				materialProperty.ambient = interiorFogColor

				particleSystem:update()
				particleSystem:updateProperties()
				particleSystem:updateEffects()
			end

			updateTracker(fogMesh, cell)

			fogMesh.appCulled = false
			fogMesh:update()
			fogMesh:updateProperties()
			fogMesh:updateEffects()
		end

		---
		if config.interiorShader then
			local calcZPos, calcZRad
			local depth = math.random(BASE_DEPTH / 1.2, BASE_DEPTH * 2)
			calcZPos = pos.z + table.choice(HEIGHTS)
			if cell.hasWater then
				calcZRad = depth * 1.5
				calcZPos = cell.waterLevel + calcZRad / 3
			else
				calcZPos = pos.z + (table.choice(HEIGHTS) / math.random(6,10))
				calcZRad = depth
			end

			local fogParams = {
				color = tes3vector3.new(
					interiorFogColor.r,
					interiorFogColor.g,
					interiorFogColor.b
				),
				center = tes3vector3.new(
					pos.x,
					pos.y,
					calcZPos
				),
				radius = tes3vector3.new(MAX_DISTANCE, MAX_DISTANCE, calcZRad),
				density = math.random(DENSITY/3, DENSITY*1.3)
			}

			shader.createOrUpdateFog(NAME_MAIN, fogParams)
		end
	end
end

function interior.onCellChanged()
	local player = tes3.player
	if not player then return end
	local cell = player.cell
	interior.removeAllFog()
	if not (cell.isOrBehavesAsExterior) then
		debugLog("Starting interior check.")

		if (isAvailable(cell)) and not (isCellFogged(cell)) then
			addFog(cell)
		end
	end
end

return interior