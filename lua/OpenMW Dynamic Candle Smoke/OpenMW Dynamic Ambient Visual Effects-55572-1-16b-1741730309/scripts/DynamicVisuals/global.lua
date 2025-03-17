local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local time = require("openmw_aux.time")

local devMode = false
local player, currentCell, worldSpace = world.players[1]

common = {
	devMode = devMode, player = player, viewDistance = 8192,
	hour = 12,
	sunrise = core.getGMST("Weather_Sunrise_Time"),
	night = core.getGMST("Weather_Sunset_Time") + core.getGMST("Weather_Sunset_Duration"),
	isNight = false,	weather = 1,
	glow = 60,		noCarry = false,
	doStrike = false
}

local common = common
common.openmw = { util=util, world=world, types=types, core=core }
common.oaab = core.contentFiles.has("oaab_data.esm")

if devMode then
	common.debug = function(m) player:sendEvent("showMessage", m)		end
else
	common.debug = function() end
end

local candles = require("scripts.DynamicVisuals.fxCandleSmoke")
local moths = require("scripts.DynamicVisuals.fxLanternMoths")
local mount = require("scripts.DynamicVisuals.fxRedMountain")
local dwemer = require("scripts.DynamicVisuals.fxDwemerRods")


local function onPlayerAdded(e)
	if not e then		return			end
	player = e		currentCell = e.cell
	candles.onPlayerAdded(e)	moths.onPlayerAdded(e)
	mount.onPlayerAdded(e)		dwemer.onPlayerAdded(e)
	if e.cell then worldSpace = e.cell.worldSpaceId			end
end

onPlayerAdded(player)


I.Settings.registerGroup({
   key = "Settings_DAVE_world",
   page = "dynamicVisuals",
   l10n = "DynamicVisuals",
   name = "settings_modCat1_name",
   permanentStorage = true,
   settings = {
      {
         key = "enable",
         name = "settings_modCat1_setting01_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "disable_carried",
         name = "settings_modCat1_setting02_name",
         default = false,
         renderer = "checkbox",
      },
      {
         key = "glow_level",
         name = "settings_modCat1_setting03_name",
         description = "settings_modCat1_setting03_desc",
         default = "60",
         renderer = "select",
         argument = { disabled = false,
         l10n = "DynamicVisuals", 
         items = { "30", "45", "60", "90" }
         },
      },
      {
         key = "enable_moths",
         name = "settings_modCat1_setting04_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "moth_chance",
         name = "settings_modCat1_setting05_name",
         default = 100,
         renderer = "number",
         argument = { min = 0, max = 100 },
      },
      {
         key = "moth_loddist",
         name = "settings_modCat1_setting06_name",
         default = "768",
         renderer = "select",
         argument = { disabled = false,
         l10n = "DynamicVisuals", 
         items = { "768", "1500" }
         },
      },
      {
         key = "enable_dwemer",
         name = "settings_modCat1_setting07_name",
         default = "opt_atNight",
         renderer = "select",
         argument = { disabled = false,
         l10n = "DynamicVisuals", 
         items = { "opt_atNight", "opt_inStorms", "opt_off" }
         },
      },
      {
         key = "dwem_strikeChance",
         name = "settings_modCat1_setting08_name",
         default = 25,
         renderer = "number",
         argument = { min = 0, max = 100 },
      },
      {
         key = "enable_redm_smoke",
         name = "settings_modCat1_setting09_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "enable_redm_winds",
         name = "settings_modCat1_setting10_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "enable_redm",
         name = "settings_modCat1_setting11_name",
         default = "opt_atNight",
         renderer = "select",
         argument = { disabled = false,
         l10n = "DynamicVisuals", 
         items = { "opt_atNight", "opt_inStorms", "opt_off" }
         },
      },
      {
         key = "redm_strikeChance",
         name = "settings_modCat1_setting12_name",
         default = 50,
         renderer = "number",
         argument = { min = 0, max = 100 },
      },
   },
})

local settings = storage.globalSection("Settings_DAVE_world")
local doCandles, doMoths, doRods

local function updateSettings()
	local c = common
	c.noCarry = settings:get("disable_carried")
	c.glow = settings:get("glow_level")
	doCandles = settings:get("enable")

	c.mothLod = "meshes/e/taitech/moths_lntrn" .. settings:get("moth_loddist") .. "_"
	c.mothChance = settings:get("moth_chance")
	doMoths = settings:get("enable_moths")

	local s = settings:get("enable_dwemer")
	c.dwemOption = s == "opt_inStorms" and 2 or 1
	c.dwemChance = settings:get("dwem_strikeChance")
	doRods = s ~= "opt_off"

	s = settings:get("enable_redm")
	c.rmLightning = false
	if s ~= "opt_off" then
		c.rmLightning = true		c.rmOption = s == "opt_inStorms" and 2 or 1
	end
	c.rmSmoke = settings:get("enable_redm_smoke")
	c.rmWinds = settings:get("enable_redm_winds")
	c.rmChance = settings:get("redm_strikeChance")
	c.doMount = c.rmLightning or c.rmSmoke or c.rmWinds
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


local function onObjectActive(o)
	if not o.enabled or o.count < 1 then		return		end
	local t = o.type

	local c = o.cell
	if worldSpace ~= c.worldSpaceId then 
		worldSpace = c.worldSpaceId
--		print("WORLDSPACE CHANGE")
		if doMoths then moths.refreshVfx()		end
		if doRods then dwemer.clearVfx()		end
	end

	if doRods and t == types.Static then
		dwemer.onObjectActive(o)
		return
	end

	if t ~= types.Light then	return		end
	if doCandles then candles.onObjectActive(o)		end
	if doMoths then moths.onObjectActive(o)			end

end

local function hasVfxReset()
	local p, c = player.cell, currentCell
	currentCell = player.cell		if not c then	return		end
	if not p.isExterior or not c.isExterior then		return		end
	if math.abs(p.gridX - c.gridX) < 3 and math.abs(p.gridY - c.gridY) < 3 then
		return
	end
	mount.refreshVfx()
end

local timer = 10

time.runRepeatedly(function()		local dt = 1

	if player.cell ~= currentCell then hasVfxReset()	end
	if doMoths then		moths.onUpdate(dt)		end
	mount.onUpdate(dt)
	if doRods then		dwemer.onUpdate(dt)		end
	local c = common
	if c.doStrike and c.oaab then
		world.createObject("AB_light@_Lightning"):teleport(player.cell, player.position)
		local rnd = math.floor(math.random(99) / 20)
		core.sound.playSound3d("AB_Thunderclap"..rnd, player)
	end
	c.doStrike = false

	timer = timer + dt	if timer < 10 then	return		end		timer = 0
	local hour = math.floor(core.getGameTime() / 3600)
	hour = hour - math.floor(hour / 24) * 24
	c.hour = hour		c.isNight = (hour < c.sunrise) or (hour >= c.night)

end, 1 * time.second)


return {
	engineHandlers = {
		onObjectActive = onObjectActive,
		onPlayerAdded = onPlayerAdded
	},
	eventHandlers = {
		dcsSetDistance = function(e) common.viewDistance = e		end,
		dcsRefreshVfx = function(e)
--			print("REFRESH")
			if doMoths then moths.refreshVfx(e.list)			end
			if doCandles then candles.refreshVfx(e.list)			end
			mount.refreshVfx()
		end,
		dcsUpdateNearby = function(e)
			moths.updateNearby(e.list)
		end,
		daveCandles = function(e)
			if doCandles then candles.refreshVfx(e)			end
		end,
		olhInitialized = function()
			I.luaHelper.addWeatherHandler(function(_, w)
--				print("WEATHER "..w)
				common.weather = w
			end)
		end
	},
	interfaceName = "daveDev",
	interface = {
		version = 100,
		listmoths = moths.listVfx,
		common = common,
	}
}
