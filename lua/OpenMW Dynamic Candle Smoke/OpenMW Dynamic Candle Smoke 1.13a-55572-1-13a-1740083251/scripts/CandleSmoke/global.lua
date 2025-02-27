local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local time = require("openmw_aux.time")

local devMode = false
local player, currentCell, lastNewCell = world.players[1]

common = {
	devMode = devMode, player = player, viewDistance = 8192,
	hour = 12,
	sunrise = core.getGMST("Weather_Sunrise_Time"),
	night = core.getGMST("Weather_Sunset_Time") + core.getGMST("Weather_Sunset_Duration"),
	isNight = false,	weather = 1,
	glow = 60,		noCarry = false
}

local common = common
common.openmw = { util=util, world=world, types=types, core=core }

local candles = require("scripts.CandleSmoke.fxCandleSmoke")
local moths = require("scripts.CandleSmoke.fxLanternMoths")
local mount = require("scripts.CandleSmoke.fxRedMountain")
local dwemer
-- = require("scripts.CandleSmoke.fxDwemerRods")


local function onPlayerAdded(e)
	if not e then		return			end
	player = e		lastNewCell = e.cell		currentCell = e.cell
	candles.onPlayerAdded(e)	moths.onPlayerAdded(e)
	mount.onPlayerAdded(e)
	if dwemer then dwemer.onPlayerAdded(e)			end
end

onPlayerAdded(player)

--[[
candles.common = common		moths.common = common
if dwemer then
	dwemer.common = common
end
--]]


I.Settings.registerGroup({
   key = "Settings_candlesmoke",
   page = "candleSmoke",
   l10n = "CandleSmoke",
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
         l10n = "CandleSmoke", 
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
         l10n = "CandleSmoke", 
         items = { "768", "1500" }
         },
      },
      {
         key = "enable_redm_smoke",
         name = "settings_modCat1_setting07_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "enable_redm_winds",
         name = "settings_modCat1_setting08_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "enable_redm",
         name = "settings_modCat1_setting09_name",
         default = "redm_atNight",
         renderer = "select",
         argument = { disabled = false,
         l10n = "CandleSmoke", 
         items = { "redm_atNight", "redm_inStorms", "redm_off" }
         },
      },
      {
         key = "redm_strikeChance",
         name = "settings_modCat1_setting10_name",
         default = 50,
         renderer = "number",
         argument = { min = 0, max = 100 },
      },
   },
})

local settings = storage.globalSection("Settings_candlesmoke")
local doCandles, doMoths, doRods

local function updateSettings()
	local c = common
	doCandles = settings:get("enable")
	doMoths = settings:get("enable_moths")
	local red = settings:get("enable_redm")
	if red ~= "redm_off" then
		c.rmLightning = true		c.rmOption = red == "redm_inStorms" and 2 or 1
	end
	doRods = dwemer ~= nil
	c.noCarry = settings:get("disable_carried")
	c.glow = settings:get("glow_level")
	c.mothLod = "meshes/e/taitech/moths_lntrn" .. settings:get("moth_loddist") .. "_"
	c.mothChance = settings:get("moth_chance")
	c.rmSmoke = settings:get("enable_redm_smoke")
	c.rmWinds = settings:get("enable_redm_winds")
	c.rmChance = settings:get("redm_strikeChance")
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


local function onObjectActive(o)
	if not o.enabled or o.count < 1 then		return		end
	local t = o.type

	if doRods and t == types.Static then
		dwemer.onObjectActive(o)
		return
	end

	local c = o.cell
	if not c.isExterior and lastNewCell ~= c then
		lastNewCell = c
		if doMoths then moths.refreshVfx()		end
		-- print("CELL CHANGE")
	end
	
	if t ~= types.Light then	return		end
	if doCandles then candles.onObjectActive(o)		end
	if doMoths then moths.onObjectActive(o)			end

end

local function hasVfxReset()
	local p, c = player.cell, currentCell
	currentCell = player.cell
	if not p.isExterior or not c.isExterior then		return		end
	if math.abs(p.gridX - c.gridX) < 3 and math.abs(p.gridY - c.gridY) < 3 then
		return
	end
	mount.refreshVfx()
end

local timer = 0

time.runRepeatedly(function()		local dt = 1
	if player.cell ~= currentCell then hasVfxReset()	end
	if doMoths then		moths.onUpdate(dt)		end
	if doRods then		dwemer.onUpdate(dt)		end
	mount.onUpdate(dt)
	timer = timer + dt	if timer < 10 then	return		end		timer = 0
	local hour = math.floor(core.getGameTime() / 3600)
	hour = hour - math.floor(hour / 24) * 24
	local c = common	c.hour = hour
	c.isNight = (hour < c.sunrise) or (hour >= c.night)
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
			candles.refreshVfx(e.list)
			mount.refreshVfx()
		end,
		dcsUpdateNearby = function(e)
			moths.updateNearby(e.list)
		end,
		olhInitialized = function()
			I.luaHelper.addWeatherHandler(function(_, w)	common.weather = w	end)
		end
	},
	interfaceName = "dcsDev",
	interface = {
		version = 100,
		listmoths = moths.listVfx,
		common = common,
	}
}
