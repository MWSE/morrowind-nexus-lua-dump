local types = require("openmw.types")
local core = require("openmw.core")
local util = require("openmw.util")
local world = require("openmw.world")
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")

local v3 = util.vector3		local previousCell	local debug = false
local player = world.players[1]

local dwemer = false
local addEffect = { ex_dwrv_steamstack00 = v3(-128, 0, 1536) }
local noCheck = true
local lightning = {}


local vectors = require("scripts.CandleSmoke.modelLookup")


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
         l10n = "LocalizationContext", 
         items = { "30", "45", "60", "90" }
         },
      },
   },
})

local settings = storage.globalSection("Settings_candlesmoke")
local options, noSmoke = {}	-- noSmoke, noCarry

local function updateSettings()
	noSmoke = not settings:get("enable")
	options.noCarry = settings:get("disable_carried")
	options.glow = settings:get("glow_level")
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


local function addSmoke(o, candle, phase)
	local origin, position = o.position
	local multi = candle.mV		local offset = v3(0, 0, -2)	local g = options.glow
	if not multi then
		position = o.rotation:apply(candle.V + offset) + origin
		world.vfx.spawn("meshes/e/taitech/candlesmoke"..g.."_"..phase..".nif", position)
--		if debug then print(o.recordId.." "..g)		end
		if debug then player:sendEvent("showMessage", o.recordId.." "..g)		end
		return
	end
	phase = 1	local count = 0
	for i = 1, #multi do
		position = o.rotation:apply(multi[i] + offset) + origin
		world.vfx.spawn("meshes/e/taitech/candlesmoke"..g.."_"..phase..".nif", position)
		count = count + 1	phase = phase + 1	if phase > 3 then phase = 1	end
	end
--	if debug then print(o.recordId.." "..g.." "..count)		end
	if debug then player:sendEvent("showMessage", o.recordId.." "..g.." "..count)		end
end

local light, activator, static = types.Light, types.Activator, types.Static
local phase = 1

local function onObjectActive(o)
	local type = o.type
	if dwemer and type == static and addEffect[o.recordId] then
		lightning[#lightning + 1] = o	noCheck = false
		player:sendEvent("showMessage", o.recordId.." "..#lightning)
	end
	if noSmoke or type ~= light then return		end
	local r = type.records[o.recordId]
	if r.isOffByDefault or (options.noCarry and r.isCarriable) then return		end
	local model = r.model or ""		model = model:lower()
	-- bugfix for OMW versions before Nov 19 2024
	model = string.gsub(model, "\\", "/")

	local v = vectors[model]
	if not v then
		local i, j
		i, j = string.find(model, "/[^/]*$")
		if i then model = string.sub(model, i+1, j)	v = vectors[model]	end
	end
	if v then
		addSmoke(o, v, phase)	phase = phase + 1	if phase > 3 then phase = 1	end
	end
end

local timer = 0

local function onUpdate(dt)
	if noCheck then return		end
	if #lightning == 0 then noCheck = true	print("VFX CLEARED")		return		end
	timer = timer + dt
	for k, v in ipairs(lightning) do
		local inactive = false
		if v.cell.isExterior then
			if not player.cell.isExterior then inactive = true
			else
				local x = v.position.x - player.position.x
				local y = v.position.y - player.position.y
				if (x^2 + y^2) ^ 0.5 > 15000 then inactive = true	end
			end
		elseif v.cell ~= player.cell then inactive = true
		end
		if inactive then
			table.remove(lightning, k) player:sendEvent("showMessage", "REMOVED")
		elseif timer > 5 then
			local pos = v.rotation:apply(addEffect[v.recordId]) + v.position
			world.vfx.spawn("meshes/e/taitech/lightning.nif", pos)
			player:sendEvent("showMessage", "KERR-RASSH"..#lightning)
		end
	end
	if timer > 5 then timer = 0	end
end


return {
	engineHandlers = {
		onUpdate = onUpdate,
		onObjectActive = onObjectActive,
		onPlayerAdded = function(e) player = e	end
	},
	eventHandlers = { doCandleSmoke = function(e) for i = 1, #e do onObjectActive(e[i]) end  end},
}
