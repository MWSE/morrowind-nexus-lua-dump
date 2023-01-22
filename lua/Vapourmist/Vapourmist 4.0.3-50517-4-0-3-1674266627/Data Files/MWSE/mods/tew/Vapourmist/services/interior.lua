-- Interior fog module
-->>>---------------------------------------------------------------------------------------------<<<--

-- Imports
local interior = {}
local util = require("tew.Vapourmist.components.util")
local debugLog = util.debugLog

-->>>---------------------------------------------------------------------------------------------<<<--
-- Constants

local MIN_STAT_COUNT = 5
local MESH = tes3.loadMesh("tew\\Vapourmist\\vapourint.nif")
local HEIGHT = -1300
local SIZES = { 300, 400, 450, 500, 510, 550 }

local NAME_MAIN = "tew_InteriorFog"
local NAME_PARTICLE_SYSTEM = "tew_InteriorFog_ParticleSystem"


-->>>---------------------------------------------------------------------------------------------<<<--
-- Structures

local interiorStatics = {
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
	"bm_ka"
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

	return { x = pos.x / denom, y = pos.y / denom, z = pos.z / denom }
end

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

		local originalInteriorFogColor = cell.fogColor
		local interiorFogColor = {
			r = math.clamp(math.lerp(originalInteriorFogColor.r, 1.0, 0.5), 0.3, 0.85),
			g = math.clamp(math.lerp(originalInteriorFogColor.r, 1.0, 0.46), 0.3, 0.85),
			b = math.clamp(math.lerp(originalInteriorFogColor.r, 1.0, 0.42), 0.3, 0.85)
		}

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