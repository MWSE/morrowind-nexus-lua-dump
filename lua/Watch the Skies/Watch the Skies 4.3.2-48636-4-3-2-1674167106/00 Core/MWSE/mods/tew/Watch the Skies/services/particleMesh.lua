local particleMesh = {}

--------------------------------------------------------------------------------------

local common = require("tew.Watch the Skies.components.common")
local debugLog = common.debugLog
local WtC = tes3.worldController.weatherController
local newParticleMesh
local particlesPath = "Data Files\\Meshes\\tew\\Watch the Skies\\particles"

--------------------------------------------------------------------------------------

local SNOW_POINT = 0.2
local RAIN_POINT = 0.1

local particles = {
	["rain"] = {},
	["snow"] = {}
}

local weatherChecklist = {
	["Rain"] = "rain",
	["Thunderstorm"] = "rain",
	["Snow"] = "snow"
}

--------------------------------------------------------------------------------------

function particleMesh.init()
	for particleTypeFolder in lfs.dir(particlesPath) do
		if particleTypeFolder and particleTypeFolder ~= ".." and particleTypeFolder ~= "." then
			for particle in lfs.dir(particlesPath .. "\\" .. particleTypeFolder) do
				if particle and particle ~= ".." and particle ~= "." and string.endswith(particle:lower(), ".nif") then
					table.insert(particles[particleTypeFolder], particle)
				end
			end
		end
	end
end

local function getBleachedColour(comp, point)
	return math.clamp(math.lerp(comp, 1.0, point), 0.03, 0.88)
end

function particleMesh.getModifiedColour(weatherColour)
	local colours
	if (WtC.currentWeather.name) == "Snow" or (WtC.nextWeather and WtC.nextWeather.name == "Snow") then
		colours = {
			r = getBleachedColour(weatherColour.r, SNOW_POINT),
			g = getBleachedColour(weatherColour.g, SNOW_POINT),
			b = getBleachedColour(weatherColour.b, SNOW_POINT)
		}
	else
		colours = {
			r = getBleachedColour(weatherColour.r, RAIN_POINT),
			g = getBleachedColour(weatherColour.g, RAIN_POINT),
			b = getBleachedColour(weatherColour.b, RAIN_POINT)
		}
	end
	return colours
end

-- Change particle mesh colours in real-time --
function particleMesh.reColourParticleMesh()
	if not particleMesh.isValidWeather() or not newParticleMesh then
		return
	end

	local weatherColour = WtC.currentFogColor
	local colours = particleMesh.getModifiedColour(weatherColour)
	local materialProperty = newParticleMesh:getObjectByName("tew_particle").materialProperty

	materialProperty.emissive = colours
	materialProperty.specular = colours
	materialProperty.diffuse = colours
	materialProperty.ambient = colours
end

function particleMesh.isValidWeather()
	return (WtC.currentWeather.name == "Rain" or WtC.currentWeather.name == "Thunderstorm" or WtC.currentWeather.name == "Snow")
	and ((not WtC.nextWeather) or (WtC.nextWeather.name == "Rain" or WtC.nextWeather.name == "Thunderstorm" or WtC.nextWeather.name == "Snow"))
end

local function swapNode(particle)
	local old = particle.object
	particle.rainRoot:detachChild(old)

	local new = newParticleMesh:clone()
	particle.rainRoot:attachChild(new)
	new.appCulled = old.appCulled

	particle.object = new
end

-- Get a new mesh and swap nodes --
function particleMesh.changeParticleMesh(particleType)
	local randomParticleMesh = table.choice(particles[particleType])
	newParticleMesh = tes3.loadMesh("tew\\Watch the Skies\\particles\\" .. particleType .. "\\" .. randomParticleMesh):clone()

	for _, particle in pairs(WtC.particlesActive) do
		swapNode(particle)
	end
	for _, particle in pairs(WtC.particlesInactive) do
		swapNode(particle)
	end

	WtC.sceneRainRoot:updateEffects()
	debugLog("Rain mesh changed to " .. randomParticleMesh)
end

-- Check if we have the weather that warrants particle change --
function particleMesh.particleMeshChecker()
	local weatherNow
	if WtC.nextWeather then
		weatherNow = WtC.nextWeather
		local particleWeatherType = weatherChecklist[weatherNow.name]
		if particleWeatherType ~= nil then
			timer.start {
				duration = 0.2,
				callback = function()
					particleMesh.changeParticleMesh(particleWeatherType)
				end,
				type = timer.game,
			}
		end
	else
		weatherNow = WtC.currentWeather
		local particleWeatherType = weatherChecklist[weatherNow.name]
		if particleWeatherType ~= nil then
			particleMesh.changeParticleMesh(particleWeatherType)
		end
	end
end



--------------------------------------------------------------------------------------

return particleMesh