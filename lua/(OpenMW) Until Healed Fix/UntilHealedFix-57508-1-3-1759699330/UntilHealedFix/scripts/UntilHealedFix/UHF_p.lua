local ui = require('openmw.ui')
local util = require('openmw.util')
local core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local v2 = util.vector2
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local self = require('openmw.self')
local types = require("openmw.types")
async = require('openmw.async')

local sleepMode = "Hours" -- Hours or untilRested
MODNAME = "UntilHealedFix"

settingsSection = storage.playerSection('Settings'..MODNAME)
require('scripts.UntilHealedFix.UHF_settings')

--calc ui scale
local layerId = ui.layers.indexOf("HUD")
local width = ui.layers[layerId].size.x
local screenres = ui.screenSize()
local uiScale = screenres.x / width

local readFont = require('scripts.UntilHealedFix.readFont')
glyphs,lineHeight = readFont("scripts\\UntilHealedFix\\MysticCards.fnt")


--for debugging button detection:
local templateGreen = {
	content = ui.content{
		{
			type = ui.TYPE.Image,
			name = "timeHudBackground",
			props = {
				resource = ui.texture { path = 'white' },
				relativeSize = v2(1,1),  -- Fill entire container
				alpha = 0.07,
				color = util.color.rgb(0,1,0),
			}
		}
	}
}
local templateYellow = {
	content = ui.content{
		{
			type = ui.TYPE.Image,
			name = "timeHudBackground",
			props = {
				resource = ui.texture { path = 'white' },
				relativeSize = v2(1,1),  -- Fill entire container
				alpha = 0.07,
				color = util.color.rgb(1,1,0),
			}
		}
	}
}

local templateRed = {
	content = ui.content{
		{
			type = ui.TYPE.Image,
			name = "timeHudBackground",
			props = {
				resource = ui.texture { path = 'white' },
				relativeSize = v2(1,1),  -- Fill entire container
				alpha = 0.07,
				color = util.color.rgb(1,0,0),
			}
		}
	}
}


local localizedText = {
	untilRested = core.getGMST("sUntilHealed"),
	rest = core.getGMST("sRest"),
	cancel = core.getGMST("sCancel"),
}

local function estimateTextWidth(text, fontSize)
	local gapMult = 1
	local stretchGlyph = 1
	local totalWidth = 0
	for i=1, #text do
		local symbol = text:sub(i,i)
		if glyphs[symbol] and glyphs[symbol].width then
			local glyphHeight = lineHeight
			--local glyphHeight = glyphs[symbol].height
			local spaceLeft = glyphs[symbol].xoffset*gapMult
			local spaceRight = (glyphs[symbol].xadvance- glyphs[symbol].xoffset- glyphs[symbol].width)*gapMult
			local glyphWidth =  glyphs[symbol].width*stretchGlyph
			if symbol == " " then
				glyphWidth = glyphWidth+8
			end
			local total = spaceLeft+spaceRight+glyphWidth
			totalWidth = totalWidth+total
		end
	end
	return totalWidth*0.12
end

local function calculateButtonSize(text, minWidth, padding)
	minWidth = minWidth or 30
	padding = padding or 32 -- Total (left+right)
	
	local textWidth = estimateTextWidth(text)
	local buttonWidth = math.max(minWidth, textWidth + padding)
	
	return v2(buttonWidth, 30) -- Height remains constant
end

local function getButtonSizesAndPositions()
	local sizes = {
		untilRested = calculateButtonSize(localizedText.untilRested, 15),
		rest = calculateButtonSize(localizedText.rest, 15),
		cancel= calculateButtonSize(localizedText.cancel, 15),
	}
	sizes.untilRested = v2(math.ceil(sizes.untilRested.x), sizes.untilRested.y)
	
	local spacing = 0
	
	local totalWidth = sizes.untilRested.x + sizes.rest.x + sizes.cancel.x + (spacing * 2)

	local groupLeftEdge = -totalWidth / 2 + 2 
	local untilRestedX = groupLeftEdge
	local restX = untilRestedX + sizes.untilRested.x + spacing
	local cancelX = restX + sizes.rest.x + spacing
	
	local positions = {
		untilRested = v2(untilRestedX, 52),
		rest = v2(restX, 52),
		cancel = v2(cancelX, 52)
	}

	return sizes, positions
end

-- Create box for hovering over "until rested" button
function makeUntilRestedClickbox()
	untilRestedClickbox = ui.create({
		type = ui.TYPE.Widget,
		layer = 'Modal',
		name = "untilRestedButton",
		template = SHOW_DEBUG_BOXES and templateGreen or nil,
		props = {
			relativePosition = v2(0.5, 0.5),
			position = positions.untilRested,
			anchor = v2(0, 0.5),
			size = sizes.untilRested,
		},
		events = {
			focusGain = async:callback(function(_, elem)
				if not untilRestedClickbox then
					makeUntilRestedClickbox()
				end
				if not restClickbox then
					makeRestClickbox()
				end
				if not cancelClickbox then
					makeCancelClickbox()
				end
				untilRestedClickbox:destroy()
				untilRestedClickbox = nil
				
				--print("hover untilRestedClickbox")
			end),
		}
	})

end

-- Create box for hovering over "rest" button
function makeRestClickbox()
	restClickbox = ui.create({
		type = ui.TYPE.Widget,
		layer = 'Modal',
		name = "restButton",
		template = SHOW_DEBUG_BOXES and templateYellow or nil,
		props = {
			relativePosition = v2(0.5, 0.5),
			position = positions.rest,
			anchor = v2(0, 0.5),
			size = sizes.rest,
		},
		events = {
			focusGain = async:callback(function(_, elem)
				if not untilRestedClickbox then
					makeUntilRestedClickbox()
				end
				if not restClickbox then
					makeRestClickbox()
				end
				if not cancelClickbox then
					makeCancelClickbox()
				end
				restClickbox:destroy()
				restClickbox = nil
				
				--print("hover restClickbox")
			end),
		}
	})
end

-- Create box for hovering over "cancel" button
function makeCancelClickbox()
	cancelClickbox = ui.create({
		type = ui.TYPE.Widget,
		layer = 'Modal',
		name = "cancelButton",
		template = SHOW_DEBUG_BOXES and templateRed or nil,
		props = {
			relativePosition = v2(0.5, 0.5),
			position = positions.cancel,
			anchor = v2(0, 0.5),
			size = sizes.cancel,
		},
		events = {
			focusGain = async:callback(function(_, elem)
				if not untilRestedClickbox then
					makeUntilRestedClickbox()
				end
				if not restClickbox then
					makeRestClickbox()
				end
				if not cancelClickbox then
					makeCancelClickbox()
				end
				cancelClickbox:destroy()
				cancelClickbox = nil
				
				--print("hover cancelClickbox")
			end),
		}
	})
end



local function UiModeChanged(data)
	if data.oldMode == nil and data.newMode == "Rest" then
		sizes, positions = getButtonSizesAndPositions()
		if ENABLED 
		and (types.Actor.stats.dynamic.health(self).current < types.Actor.stats.dynamic.health(self).base or types.Actor.stats.dynamic.magicka(self).current < types.Actor.stats.dynamic.magicka(self).base) 
		and (hasActivatedBed or not self.cell:hasTag("NoSleep"))
		then
			makeRestClickbox()
			makeUntilRestedClickbox()
			makeCancelClickbox()
		else
			sleepMode = "Hours"
		end
	elseif untilRestedClickbox or restClickbox or cancelClickbox then
		if not ENABLED or not restClickbox then
			sleepMode = "Hours"
		elseif not untilRestedClickbox then
			sleepMode = "untilRested"
		end
		if untilRestedClickbox then
			untilRestedClickbox:destroy()
			untilRestedClickbox = nil
		end
		if restClickbox then
			restClickbox:destroy()
			restClickbox = nil
		end
		if cancelClickbox then
			cancelClickbox:destroy()
			cancelClickbox = nil
		end
	end
	
	-- start sleep
	if data.oldMode == "Rest" and data.newMode == "Rest" and (hasActivatedBed or not self.cell:hasTag("NoSleep")) then
		isSleeping = true
		hasActivatedBed = false
	end
	-- end sleep
	if data.oldMode == "Rest" and data.newMode == nil then --can happen when traveling (fixed for singleplayer)
		if isSleeping then
			isSleeping = false
		end
		hasActivatedBed = false
	end
end

local function onUpdate(dt)
	if isSleeping and ENABLED and sleepMode == "untilRested" then
		if  types.Actor.stats.dynamic.health(self).current >= types.Actor.stats.dynamic.health(self).base 
		and types.Actor.stats.dynamic.fatigue(self).current >= types.Actor.stats.dynamic.fatigue(self).base
		and types.Actor.stats.dynamic.magicka(self).current >= types.Actor.stats.dynamic.magicka(self).base then
			core.sendGlobalEvent("UHF_cancelSleep")
		end
	end
end

local function activatedBed(bed)
	hasActivatedBed = true
end

local function NSS_preventedSleeping(bed)
	hasActivatedBed = false
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		UHF_ActivatedBed = activatedBed,
		NSS_showMessage = NSS_preventedSleeping,
	}
}