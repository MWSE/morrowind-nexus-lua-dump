types = require('openmw.types')
NPC = require('openmw.types').NPC
core = require('openmw.core')
storage = require('openmw.storage')
MODNAME = "BetterBars"
playerSettings = storage.playerSection('SettingsPlayer'..MODNAME)
I = require("openmw.interfaces")
self = require("openmw.self")
nearby = require('openmw.nearby')
camera = require('openmw.camera')
util = require('openmw.util')
ui = require('openmw.ui')
auxUi = require('openmw_aux.ui')
async = require('openmw.async')
vfs = require('openmw.vfs')
KEY = require('openmw.input').KEY
input = require('openmw.input')
v2 = util.vector2
v3 = util.vector3
resources = types.Actor.stats.dynamic
local makeBorder = require("scripts.BetterBars.bb_makeborder")
local settings = require("scripts.BetterBars.bb_settings")
local helpers = require("scripts.BetterBars.bb_helpers")
rgbToHsv,hsvToRgb = unpack(helpers)
local foreground = ui.texture { path = "textures/BetterBars_Bar.dds" }
local flashing = ui.texture { path = "textures/BetterBars_lowWarning.dds" }
local background = ui.texture { path = 'black' }
local screenres = ui.screenSize()
local averageLength = 0
local widgets = {"magicka","fatigue", "health"}

function calculateBarPositions()
	verticalOffset = playerSettings:get("THICKNESS")+3
	barThickness = playerSettings:get("THICKNESS")
	startOffset = math.max(3, 57-verticalOffset*#widgets)
	if playerSettings:get("POSITION") == "Top Left" then
		startOffset = math.floor(verticalOffset/2)
	end
end
calculateBarPositions()

function makeUI()
	borderFile = "thin"
	if playerSettings:get("BORDER_STYLE") == "verythick" or playerSettings:get("BORDER_STYLE") == "thick" then
		borderFile = "thick"
	end
	borderOffset = playerSettings:get("BORDER_STYLE") == "verythick" and 4 or playerSettings:get("BORDER_STYLE") == "thick" and 3 or playerSettings:get("BORDER_STYLE") == "normal" and 2 or (playerSettings:get("BORDER_STYLE") == "thin" or playerSettings:get("BORDER_STYLE") == "max performance") and 1 or 0
	borderTemplate =  makeBorder(borderFile, borderColor or nil, borderOffset).borders
	container = ui.create({	--root
		type = ui.TYPE.Widget,
		layer = 'HUD',
		props = {
			position = playerSettings:get("POSITION") == "Bottom Left" and v2(94,-startOffset) or v2(startOffset,startOffset),
			size = v2(-startOffset,3*verticalOffset),
			anchor = playerSettings:get("POSITION") == "Bottom Left" and v2(0,1) or v2(0,0),
			relativePosition = playerSettings:get("POSITION") == "Bottom Left" and v2(0,1) or v2(0,0),
			relativeSize = v2(1,0)
		},
		content = ui.content {
			
		}
	})
	
	local pos =  playerSettings:get("POSITION") == "Bottom Left" and 0 or (4-#widgets) * verticalOffset - barThickness
	
	local totalLength = 0
	for _,resource in pairs(widgets) do
		totalLength = totalLength + resources[resource](self).base
	end
	averageLength = totalLength /3
	
	
	for _,resource in pairs(widgets) do
		local current = resources[resource](self).current
		local max = resources[resource](self).base
		local newMax = max * (1-playerSettings:get("LENGTH_EQUALIZER")) + averageLength * playerSettings:get("LENGTH_EQUALIZER")
		local LENGTH_MULT = _G[resource] and _G[resource].LENGTH_MULT or newMax / max * playerSettings:get("LENGTH_MULT")
		
		table.insert(container.layout.content, ui.create({ --r.1
				type = ui.TYPE.Widget,
				props = {
					size = v2(0,barThickness),
					anchor = v2(0,1),
					relativePosition = v2(0,1),
					relativeSize = v2(1,0),
					position = v2(0,-pos),
					},
				content = ui.content {
					ui.create({ --r.1
						type = ui.TYPE.Widget,
						props = {
							relativeSize  = v2(0,1),
							size = v2(max*LENGTH_MULT,0),
						},
						content = ui.content ({
							{
								type = ui.TYPE.Image,
								props = {
									resource = background,
									tileH = false,
									tileV = false,
									relativeSize  = v2(1,1),
									alpha = 0.5,
								},
							},
							playerSettings:get("BORDER_STYLE")~="none" and 
							{ -- Border
								template = borderTemplate,
								props = {
									relativeSize  = v2(1,1),
									alpha = 0.5,
								}
							} or {},
						})
					}),
					ui.create({ --r.2
						type = ui.TYPE.Widget,
						props = {
							relativeSize  = v2(1,1)
						},
						content = ui.content ({
							playerSettings:get("LAGBAR") and { -- Damage Bar r.2.lag
								name = "lag",
								type = ui.TYPE.Image,
								props = {
									resource = foreground,
									--relativePosition= v2(0,0.5),
									tileH = true,
									tileV = false,
									color =  playerSettings:get(resource:upper().."LAG_COL"),
									position = v2(borderOffset,borderOffset),
									--size = v2(-2,-3),
									size = v2(current*LENGTH_MULT-borderOffset*2,-borderOffset*2),
									relativeSize  = v2(0,1),
									alpha = 0.85,
								}
							} or {},
							{ -- HP Bar r.2.main
								name = "main",
								type = ui.TYPE.Image,
								props = {
									resource = foreground,
									tileH = false,
									tileV = false,
									color =  playerSettings:get(resource:upper().."_COL"),
									--position = v2(1, 1),
									position = v2(borderOffset,borderOffset),
									size = v2(math.min(max,current)*LENGTH_MULT-borderOffset*2,-borderOffset*2),
									relativeSize  = v2(0,1),
								},
							},
							resource == "health" and playerSettings:get("HEALBAR") and { -- Healing r.2.healing
								name = "healing",
								type = ui.TYPE.Image,
								props = {
									resource = foreground,
									tileH = true,
									tileV = false,
									color =  playerSettings:get("HEALING_COL"),
									alpha = 0.45,
									size = v2(0,0),
									position = v2(-borderOffset,0),
									relativeSize  = v2(0,1),
								}
							} or {},
							playerSettings:get("TEXT") ~= "hidden" and {
								name = 'text',
								type = ui.TYPE.Text,
								props = {
									text = playerSettings:get("TEXT") == "current" and ""..math.floor(current) or math.floor(current).."/".. math.floor(max),
									textColor = util.color.rgba(1, 1, 1, 0.85),
									position = v2(2, -math.floor(barThickness/12)),
									textShadow = true,
									anchor = v2(0, 0.5),
									relativePosition = v2(0, 0.5),
									textSize = barThickness+math.floor(barThickness/6),
									textShadowColor = util.color.rgba(0,0,0,0.75)
								}
							} or {},
						})
					}),
					playerSettings:get(resource:upper().."_FLASHING_THRESHOLD") >0 and ui.create{ -- r.3
						type = ui.TYPE.Image,
						props = {
							resource = flashing,
							tileH = false,
							tileV = false,
							color =  playerSettings:get(resource:upper().."LAG_COL"),
							--position = v2(1, 1),
							--position = v2(borderOffset,borderOffset),
							--size = v2(math.min(max,current)*LENGTH_MULT-borderOffset*2,-borderOffset*2),
							relativeSize  = v2(0,1),
							size = v2(max*LENGTH_MULT,0),
							alpha = 0,
						},
					} or {},
				}
			})
		)
		
		pos = pos+verticalOffset
		_G[resource] = { -- magicka, fatigue, health =
			bar = container.layout.content[#container.layout.content].layout.content,
			max = max*LENGTH_MULT,
			current = current,
			cached = current,
			paused = current,
			lag = current,
			lagCached = current,
			timer = 0,
			lerp = current,
			LENGTH_MULT = LENGTH_MULT,
			flashing = false
		}
		if playerSettings:get("TEXT_POS") == "right" then
			_G[resource].bar[2].layout.content["text"].props.position = v2(math.floor(max*LENGTH_MULT)-2,0)
			_G[resource].bar[2].layout.content["text"].props.anchor = v2(1,0.5)
		elseif playerSettings:get("TEXT_POS") == "right outside" then
			_G[resource].bar[2].layout.content["text"].props.position = v2(math.floor(max*LENGTH_MULT)+2,0)
			
		end
	end
	
end

makeUI()


local function lerpValues(old, new, dt)
	local mult = playerSettings:get("LERPSPEED")/8
	
	if new > old then
		old = math.min(new,old*(1-dt*mult) + new*dt*mult)
	else
		old = math.max(new,old*(1-dt*mult) + new*dt*mult)
	end
	if math.abs(new-old) <1 then
		old = new
	end
	return old
end

local function ownlysLag(current, lerped, cached, paused, lag, timer, dt, drainSpeed, timerLength, treshold, max)
	lerped = lerpValues(lerped, current, dt)
	--lerped = math.max(current,lerped - dt * drainSpeed)
	if current > max then     -- fortify health workaround
		paused = current      -- fortify health workaround
	elseif paused > max then  -- fortify health workaround
		paused = max          -- fortify health workaround
	end                       -- fortify health workaround ctrl+f: math.min(max
	if current > paused then
		paused = current
	end
	if current > lag then
		lag = math.min(lerped, lag+0.2+(lerped-lag)/15) -- lerp to fix script-based magicka cost reductions
	end
	if current < cached -treshold then 
		timer = 0
	else
		timer = timer + dt 
	end
	if timer > timerLength then
		paused = current
	end
	if lag > paused  then 
		lag = math.max(paused,lag - dt * drainSpeed - (lag-paused)/1500)
		if  math.abs(lag - lerped) < 1 then
			lag = lerped
		end
	end
	--print(current,cached,paused,lag,timer,lerped)
	return paused, lag, timer, lerped
end

function calculateHealing(actor)
	local timeBand = 3
	local incomingHealing = 0
	for a,b in pairs(types.Actor.activeSpells(actor)) do
		for c,d in pairs(b.effects) do
			if d.id == "restorehealth" then --and d.durationlLeft then -- should permanent effects count? let's say yes
				local duration = math.max(0,math.min(timeBand,d.durationLeft or timeBand))
				incomingHealing= incomingHealing +(d.maxMagnitude+d.minMagnitude)/2*duration
			end
		end
	end
	return incomingHealing
end

local function update(bar, resource, dt, treshold)
	local shouldUpdate = false
	local current = resources[resource](self).current
	local max = resources[resource](self).base
	local healing = 0
	local drainSpeed = playerSettings:get("LERPSPEED")
	local timerLength = playerSettings:get("LAGDURATION")
	bar.paused, bar.lag, bar.timer, bar.lerp = ownlysLag(current, bar.lerp, bar.cached, bar.paused, bar.lag, bar.timer, dt, drainSpeed, timerLength, treshold, max)
	
	bar.max = lerpValues(bar.max, max*bar.LENGTH_MULT, dt)
	if math.abs(bar.bar[1].layout.props.size.x- math.floor(bar.max)) >= 1 or updateAll then
		--print(bar.max,max*bar.LENGTH_MULT)
		bar.bar[1].layout.props.size = v2( math.floor(bar.max),0)
		--bar.max = max
		bar.bar[1]:update()
		--shouldUpdate = true
		if playerSettings:get("TEXT_POS") ~= "left" then
			if playerSettings:get("TEXT_POS") == "right" then
				bar.bar[2].layout.content["text"].props.position = v2(math.floor(bar.max)-2,0)
				bar.bar[2].layout.content["text"].props.anchor = v2(1,0.5)
			elseif playerSettings:get("TEXT_POS") == "right outside" then
				bar.bar[2].layout.content["text"].props.position = v2(math.floor(bar.max)+2,0)
			end
			shouldUpdate = true
		end
	end
	if playerSettings:get("TEXT") ~="hidden" and math.floor(current) ~= math.floor(bar.cached) then
		shouldUpdate = true
	end
	
	local newLag = bar.lag*bar.LENGTH_MULT-borderOffset*2
	if playerSettings:get("LAGBAR") and math.abs(math.floor(newLag) - bar.bar[2].layout.content["lag"].props.size.x) >= 1 then
		shouldUpdate = true
	end
	
	local newLerp = math.min(bar.max, bar.lerp* bar.LENGTH_MULT)  - borderOffset*2
	if math.abs(math.floor(newLerp) - bar.bar[2].layout.content["main"].props.size.x) >= 1 then
		shouldUpdate = true
	end
	--if math.abs(bar.lerp - max) < 1 and bar.lerp ~= max then
	--	shouldUpdate = true
	--end
	
	local newHealPos 
	local newHealSize
	if resource == "health" and playerSettings:get("HEALBAR") then
		healing = calculateHealing(self)
		local healingTarget = current + healing
		newHealPos = newLerp + borderOffset
		newHealSize = math.floor(healingTarget * bar.LENGTH_MULT-borderOffset) - math.floor(newHealPos)--healing*bar.LENGTH_MULT
		if math.abs(math.floor(newHealPos) - bar.bar[2].layout.content["healing"].props.position.x) >= 1 
		or math.abs(math.floor(newHealSize) - bar.bar[2].layout.content["healing"].props.size.x) >= 1 then
			shouldUpdate = true
		end
	end
	
	local newFlashing = math.max(0,current/max) < playerSettings:get(resource:upper().."_FLASHING_THRESHOLD") and (bar.flashing or 0)+dt
	local updateFlashing = false
	if bar.flashing or newFlashing then
		if not newFlashing then --turn off flashing
			bar.bar[3].layout.props.alpha = 0
			updateFlashing = true
			if playerSettings:get("TEXT") ~= "hidden" and playerSettings:get("TEXT_POS") ~= "left" then
				bar.bar[2].layout.content["text"].props.textColor = util.color.rgba(1, 1, 1, 0.85)
				shouldUpdate = true
			end
		elseif not bar.flashing or newFlashing+dt/5 > 1/60 then
			local col = playerSettings:get(resource:upper().."LAG_COL")
			local flashBrightness = (col.r+col.g+col.b)/3
			bar.bar[3].layout.props.alpha = math.min(1,math.abs(math.sin(core.getRealTime()*5))*(1.33-flashBrightness))
			bar.bar[3].layout.props.size = v2(math.floor(bar.max),0)
			updateFlashing = true
			if not bar.flashing and playerSettings:get("TEXT") ~= "hidden" and playerSettings:get("TEXT_POS") ~= "left" then -- turn on colored text if right
				local h,s,v = rgbToHsv(col.r,col.g,col.b)
				local r,g,b = hsvToRgb(h,0.95,1)
				bar.bar[2].layout.content["text"].props.textColor = util.color.rgba(r,g,b, 0.85)
				shouldUpdate = true
			end
			newFlashing = 0
		end
		bar.flashing = newFlashing
	end
	
	if shouldUpdate or updateAll then
		if playerSettings:get("LAGBAR") then
			bar.bar[2].layout.content["lag"].props.size =v2(math.floor(newLag),-borderOffset*2)
			bar.lagCached = bar.lag
		end
		bar.bar[2].layout.content["main"].props.size =v2(math.floor(newLerp),-borderOffset*2)
		if resource == "health" and playerSettings:get("HEALBAR") then
			bar.bar[2].layout.content["healing"].props.position = v2(math.floor(newHealPos)+0.99,borderOffset)
			bar.bar[2].layout.content["healing"].props.size = v2(math.floor(newHealSize),-borderOffset*2)
		end
		if playerSettings:get("TEXT") ~= "hidden" then
			bar.bar[2].layout.content["text"].props.text = playerSettings:get("TEXT") == "current" and ""..math.floor(current) or math.floor(current).."/".. math.floor(max)
		end
		bar.bar[2]:update()
		--print(resource)
	end
	if (updateFlashing or bar.shouldUpdateFlashing) and playerSettings:get(resource:upper().."_FLASHING_THRESHOLD") > 0 then
		bar.bar[3]:update()
		--print(resource.." flash")
		bar.shouldUpdateFlashing = false
	end
	if shouldUpdate and bar.flashing then
		bar.shouldUpdateFlashing = true --fixes some weird rare flicker
	end
	bar.cached = current
end

function onFrame(dt)
	dt = core.getRealFrameDuration()
	
	--updateAll = false
	if playerSettings:get("LENGTH_EQUALIZER") > 0 then
		local totalLength = 0
		for _,resource in pairs(widgets) do
			totalLength = totalLength + resources[resource](self).base
		end
		--if math.abs(averageLength -totalLength /3) > 2 then
		--	updateAll = true
		--end
		averageLength = totalLength /3
		for a,resource in pairs(widgets) do
			local max = resources[resource](self).base
			local newMax = max * (1-playerSettings:get("LENGTH_EQUALIZER")) + averageLength * playerSettings:get("LENGTH_EQUALIZER")
			_G[resource].LENGTH_MULT = newMax / max * playerSettings:get("LENGTH_MULT")
		end
	else
		for a,resource in pairs(widgets) do
			_G[resource].LENGTH_MULT =  playerSettings:get("LENGTH_MULT")
		end
	end
	local maxLength = 0
	for a,resource in pairs(widgets) do
		maxLength = math.max(maxLength, resources[resource](self).base* playerSettings:get("LENGTH_MULT"))
	end
	local lengthMult = math.min(1, playerSettings:get("MAX_LENGTH")/maxLength )
	for a,resource in pairs(widgets) do
		_G[resource].LENGTH_MULT = _G[resource].LENGTH_MULT*lengthMult
	end
	
	local newscreenres = ui.screenSize()
	if not container then
		makeUI()
		screenres=newscreenres
	elseif newscreenres.x ~=screenres.x or newscreenres.y ~=screenres.y then
		container:destroy()
		makeUI()
		screenres=newscreenres
	end
	
	
	for _,resource in pairs(widgets) do
		update(_G[resource], resource, dt, resource == "fatigue" and 1 or 0)
	end

	
end


return {    
	engineHandlers = {
		onFrame = onFrame,
		--onKeyPress = onKey
    },
	--eventHandlers = {
    --    FHB_AI_update = AI_update,
    --}
}