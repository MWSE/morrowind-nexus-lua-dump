-- Interior fog module
-->>>---------------------------------------------------------------------------------------------<<<--

-- Imports
local interior = {}
local util = require("tew.Vapourmist.components.util")
local debugLog = util.debugLog
local shader = require("tew.Vapourmist.components.shader")

-->>>---------------------------------------------------------------------------------------------<<<--
-- Constants

local MIN_STAT_COUNT = 5
local MESH = tes3.loadMesh("tew\\Vapourmist\\vapourint.nif")
local HEIGHT = -1300
local SIZES = { 150, 170, 185, 190 }

local MAX_DISTANCE = 8192 * 3
local BASE_DEPTH = 8192 / 32
local DENSITY = 5
local BASE_COLOUR = {
	r = 0.278,
	g = 0.192,
	b = 0.062
}

local NAME_MAIN = "tew_InteriorFog"
local NAME_PARTICLE_SYSTEM = "tew_InteriorFog_ParticleSystem"
local NAME_EMITTER = "tew_InteriorFog_Emitter"

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
end

function interior.unhideAll()
	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			-- local emitter = node:getObjectByName(NAME_EMITTER)
			switchAppCull(node, false)
		end
	end
end


local function isCellFogged(cell)
	return table.find(tracker, cell)
end

local function updateTracker(fogMesh, cell)
	tracker[fogMesh] = cell
end

local function removeAllFog()
	if not tracker or table.empty(tracker) then return end

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]
	for _, node in pairs(vfxRoot.children) do
		if node and node.name == NAME_MAIN then
			vfxRoot:detachChild(node)
		end
	end

	---
    shader.deleteFog(NAME_MAIN)

	tracker = {}
end

-- Determine fog position for interiors --
local function getFogPosition(cell)
	local pos = { x = 0, y = 0, z = 0 }
	local denom = 0

	for stat in cell:iterateReferences() do
		pos.x = pos.x + stat.position.x
		pos.y = pos.y + stat.position.y
		pos.z = pos.z + stat.position.z
		denom = denom + 1
	end

	local calcZPos
	if cell.hasWater then
		calcZPos = cell.waterLevel - (HEIGHT * 3)
	else
		calcZPos = pos.z / denom
	end

	return { x = pos.x / denom, y = pos.y / denom, z = calcZPos }
end

---@param val number
---@param coeff string
local function amplifyColour(val, coeff)
	return math.clamp(math.lerp(BASE_COLOUR[coeff], val * 10, 0.4), 0.0, 1.0)
end

---@param cell tes3cell
local function getAverageColour(cell)
	local colour = {r = 0, g = 0, b = 0}
	local denom = 0

	for light in cell:iterateReferences(tes3.objectType.light) do
		local object = light.object
		colour.r = (object.color[1] or 126) / 255.0
		colour.g = (object.color[2] or 126) / 255.0
		colour.b = (object.color[3] or 126) / 255.0
		denom = denom + 1
	end

	if not denom then
		return BASE_COLOUR
	else
		return { r = amplifyColour(colour.r / denom, 'r'), g = amplifyColour(colour.g / denom, 'g'), b = amplifyColour(colour.b / denom, 'b') }
	end
end


---@param cell tes3cell
local function addFog(cell)
	debugLog("Adding interior fog.")

	local vfxRoot = tes3.game.worldSceneGraphRoot.children[9]

	if not isCellFogged(cell) then
		debugLog("Interior cell is not fogged.")
		local fogMesh = MESH:clone()
		local pos = getFogPosition(cell)

		fogMesh:clearTransforms()
		fogMesh.translation = tes3vector3.new(
			pos.x,
			pos.y,
			pos.z + HEIGHT
		)

		local interiorFogColor = getAverageColour(cell)

		local particleSystem = fogMesh:getObjectByName(NAME_PARTICLE_SYSTEM)
		local controller = particleSystem.controller

		controller.initialSize = table.choice(SIZES)

		local colorModifier = controller.particleModifiers
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

		particleSystem:updateEffects()
		updateTracker(fogMesh, cell)

		vfxRoot:attachChild(fogMesh, true)

		fogMesh:update()
		fogMesh:updateProperties()
		fogMesh:updateEffects()

		local calcZPos, calcZRad
		local depth = math.random(BASE_DEPTH / 1.5, BASE_DEPTH * 1.5)
		if cell.hasWater then
			calcZRad = depth * 1.5
			calcZPos = cell.waterLevel + calcZRad
		else
			calcZPos = pos.z + (HEIGHT/math.random(6,10))
			calcZRad = depth
		end

		---
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
			density = math.random(DENSITY/2, DENSITY*1.5)
		}

		shader.createOrUpdateFog(NAME_MAIN, fogParams)
	end
end

function interior.onCellChanged(e)
	local cell = e.cell
	removeAllFog()
	if not (cell.isOrBehavesAsExterior) then
		debugLog("Starting interior check.")

		if (isAvailable(cell)) and not (isCellFogged(cell)) then
			addFog(cell)
		end
	end
end

return interior