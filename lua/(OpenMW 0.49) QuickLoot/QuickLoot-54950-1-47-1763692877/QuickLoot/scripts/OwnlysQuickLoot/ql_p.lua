types = require('openmw.types')
NPC = require('openmw.types').NPC
core = require('openmw.core')
storage = require('openmw.storage')
MODNAME = "OwnlysQuickLoot"
playerSection = storage.playerSection('SettingsPlayer'..MODNAME)
I = require("openmw.interfaces")
self = require("openmw.self")
nearby = require('openmw.nearby')
camera = require('openmw.camera')
Camera = require('openmw.interfaces').Camera
util = require('openmw.util')
ui = require('openmw.ui')
auxUi = require('openmw_aux.ui')
async = require('openmw.async')
vfs = require('openmw.vfs')
KEY = require('openmw.input').KEY
input = require('openmw.input')
v2 = util.vector2
v3 = util.vector3
local animation = require('openmw.animation')
local Controls = require('openmw.interfaces').Controls
local settings = require("scripts.OwnlysQuickLoot.ql_settings")
makeBorder = require("scripts.OwnlysQuickLoot.ql_makeborder")
local helpers = require("scripts.OwnlysQuickLoot.ql_helpers")
readFont, texText, rgbToHsv, hsvToRgb,fromutf8,toutf8,hextoutf8,formatNumber,tableContains = unpack(helpers)
background = ui.texture { path = 'black' }
white = ui.texture { path = 'white' }
valueTex = ui.texture { path = 'textures\\QuickLoot_coins.dds' }
valueByWeightTex = ui.texture { path = 'textures\\QuickLoot_scale.dds' }
backpackTex = ui.texture { path = 'textures\\QuickLoot_backpack.dds' }
weightTex = ui.texture { path = 'textures\\QuickLoot_weight.dds' }
pickpocketTex =   ui.texture { path = 'textures\\QuickLoot_pickpocket.dds' }
pickpocketTex2 =   ui.texture { path = 'textures\\QuickLoot_pickpocket_halo1.dds' }
pickpocketTex3 =   ui.texture { path = 'textures\\QuickLoot_pickpocket_halo2.dds' }
fSymbolicTex =   ui.texture { path = 'textures\\QuickLoot_F_symbolic.dds' }
rSymbolicTex =   ui.texture { path = 'textures\\QuickLoot_R_symbolic.dds' }
fKeyTex =   ui.texture { path = 'textures\\QuickLoot_F.dds' }
rKeyTex =   ui.texture { path = 'textures\\QuickLoot_R.dds' }
local handTex = ui.texture { path = 'textures\\QuickLoot_hand.dds' }
inspectedContainer = nil
crimesVersion = 0
local selectedIndex = 1
local backupSelectedIndex = 1
local scrollPos = 1
local backupSelectedContainer = nil
local depositSelectedIndex = 1
local depositBackupSelectedIndex = 1
local depositScrollPos = 1
local containerItems = {}
TAKEALL_KEYBINDING = KEY.F
uiLoc = v2(playerSection:get("X")/100,playerSection:get("Y")/100)
uiSize = v2(playerSection:get("WIDTH")/100,playerSection:get("HEIGHT")/100)
local textureCache = {}
local bookSection = storage.playerSection('ReadBooks3'..MODNAME)
local bookTimer = 0
local currentBook = nil
local encumbranceCurrent = 0
local organicContainers = {
	barrel_01_ahnassi_drink=true,
	barrel_01_ahnassi_food =true,
	com_chest_02_fg_supply =true,
	com_chest_02_mg_supply =true,
	flora_treestump_unique =true,
}
modEnabled = true
modDisableFlags = {}
local shiftPressed = false
local layerId = ui.layers.indexOf("HUD")
uiWidth = ui.layers[layerId].size.x 
uiHeight = ui.layers[layerId].size.y
local screenres = ui.screenSize()
local uiScale = screenres.x / uiWidth
local makeTooltip = require("scripts.OwnlysQuickLoot.tooltip")
local containerHash = 0
local ambient = require('openmw.ambient')
local pickpocket 
if vfs.fileExists("scripts/OwnlysQuickLoot/ql_pickpocket_overhaul.lua") then
	pickpocket = require("scripts.OwnlysQuickLoot.ql_pickpocket_overhaul")
else
	pickpocket = require("scripts.OwnlysQuickLoot.ql_pickpocket")
end
local printThrottle = 0
local lastPrint = {}
local currentScript = nil
local mwScriptCalled = 0
vanillaActivate = 0
local deposit = false
local questItems = require("scripts.OwnlysQuickLoot.ql_questItems")
local redStealingWindow = true
local showVanillaInventory = 0


local function log(...)
	local newPrint = {...}
	local sameMessage = true
	for a,b in pairs(newPrint) do
		if lastPrint[a] ~=b then
			sameMessage = false
			break
		end
	end
	lastPrint = newPrint
	if not sameMessage or printThrottle <=0 then
		printThrottle = 1
		print(...)
	end
end

local groups = {
	["death1"] = true,
	["death2"] = true,
	["death3"] = true,
	["death4"] = true,
	["death5"] = true,
	["deathknockdown"] = true,
	["seathknockout"] = true,
	["swimdeath"] = true,
	["swimdeath2"] = true,
	["swimdeath3"] = true,
	["swimdeathknockdown"] = true,
	["swimdeathknockout"] = true,
}

function updateModEnabled()
	local tempState = true
	for a,b in pairs(modDisableFlags) do
		if not b then
			tempState = false
		end
	end
	
	modEnabled=playerSection:get("ENABLED") and tempState
	closeHud()
	core.sendGlobalEvent("OwnlysQuickLoot_playerToggledMod",{self,modEnabled})
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' or orig_type == 'userdata' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


quickLootText = {
	props = {
			textColor = playerSection:get("FONT_TINT"),--util.color.rgba(1, 1, 1, 1),
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.75),
			--textAlignV = ui.ALIGNMENT.Center,
			--textAlignH = ui.ALIGNMENT.Center,
	}
}


itemFontSize = 20



function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

input.registerTriggerHandler("ToggleSpell", async:callback(function(dt, use, sneak, run)
	if inspectedContainer then
		if playerSection:get("R_DEPOSIT") and not input.isShiftPressed() then
			local isPickpocketing = pickpocket.validateTarget(self, inspectedContainer, input)
			if not isPickpocketing or pickpocket.version then
				deposit = not deposit
				selectedIndex, depositSelectedIndex = depositSelectedIndex, selectedIndex
				backupSelectedIndex, depositBackupSelectedIndex = depositBackupSelectedIndex, backupSelectedIndex
				scrollPos, depositScrollPos = depositScrollPos, scrollPos
				drawUI()
			end
		else
			--vanillaActivate = core.getRealTime()
			--core.sendGlobalEvent("OwnlysQuickLoot_vanillaActivate",{self, inspectedContainer, true})
			--no activation anymore
			
			----inspectedContainer:activateBy(self)
			local now = core.getRealTime()
			showVanillaInventory = now
			I.UI.setMode("Container",{target = inspectedContainer})
			----types.Actor.setStance(self, types.Actor.STANCE.Nothing)
		end
	end
end))

input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	if inspectedContainer and (not types.Actor.objectIsInstance(inspectedContainer) or types.Actor.isDead(inspectedContainer)) then
		if deposit then
			core.sendGlobalEvent("OwnlysQuickLoot_depositAll",{self, inspectedContainer, input.isShiftPressed() and playerSection:get("SELECTIVE_DEPOSIT"), playerSection:get("EXPERIMENTAL_LOOTING")})
		else
			core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer, playerSection:get("DISPOSE_CORPSE") == "Shift + F" and input.isShiftPressed(), playerSection:get("EXPERIMENTAL_LOOTING")})
		end
		if types.Container.objectIsInstance(inspectedContainer) and playerSection:get("CONTAINER_ANIMATION") == "on take" then
			inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
		end
	end
end))

input.registerTriggerHandler("Jump", async:callback(function(dt, use, sneak, run)
	if inspectedContainer and playerSection:get("DISPOSE_CORPSE") == "Jump" and types.Actor.objectIsInstance(inspectedContainer) then
		core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer, true, playerSection:get("EXPERIMENTAL_LOOTING")})
	end
end)) 

input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing and use then
		closeHud()
	end
	
	return use
end), {  })

function isQuestItem(item)
	local record = item.type.record(item)
	local script = record.mwscript
	-- works, but goes too deep maybe
	if types.Player.quests(self)["TR_m3_AT_RatFriend"] and types.Player.quests(self)["TR_m3_AT_RatFriend"].stage>=10 and not types.Player.quests(self)["TR_m3_AT_RatFriend"].finished then
		local requirements = {
			p_restore_magicka_q          =true,
			ingred_bread_01              =true,
			ingred_red_lichen_01         =true,
			potion_cyro_brandy_01        =true,
			tr_m3_at_ratfriend_journal   =true,
		}
		if requirements[item.recordId] then
			return true
		end
	end
	if scriptName then
		local scriptName = record.mwscript
		if scriptName:find("cursed") 
		or scriptName:sub(-6,-1) == "dae_01"
		or scriptName == "tr_m3_aar_clo_dubious"
		or scriptName == "tr_m1_ench_shield_i62"
		or scriptName == "t_de_goldcoinghost_05"
		or scriptName == "tr_m1_soulgem_curse_i62"
		or scriptName == "t_ingmine_emeralddetomb_01"
		or scriptName == "tr_m7_armiger_note_gh"
		or scriptName == "t_com_goldcoindae_05"
		or scriptName == "t_ingmine_rubydetomb_01"
		or scriptName == "t_ingmine_pearldetomb_01"
		or scriptName == "t_ingmine_diamonddetomb_01"
		then
			return false
		end
		
		local script = core.mwscripts and core.mwscripts.records[record.mwscript]
		if script then
			if script:lower():find("setjournal") or script:lower():find("startscript") or script:lower():find("addtopic") or script:lower():find("journal ") then
				return true
			end
		end
	end
	if not questItems[item.recordId] then 
		return false 
	end 
	
	local itemType = item.type
	if itemType == types.Ingredient then
		return false
	elseif itemType == types.Miscellaneous or itemType == types.Book then
		return true
	end
	return true --?
end

function drawUI()
	local isPickpocketing = pickpocket.validateTarget(self, inspectedContainer, input)
	--if isPickpocketing and not startedPickpocketing then
	--	pickpocket.messageShown = false
	--end
	
	local transparency = playerSection:get("TRANSPARENCY")
	local hudLayerSize = ui.layers[ui.layers.indexOf("HUD")].size
	local rootWidth = hudLayerSize.x * uiSize.x
	local rootHeight = hudLayerSize.y * uiSize.y
	local header_footer_setting = playerSection:get("HEADER_FOOTER")
	core.sendGlobalEvent("OwnlysQuickLoot_freshLoot",{self, inspectedContainer})
	if backupSelectedContainer == inspectedContainer then
		selectedIndex = backupSelectedIndex
	else
		scrollPos = 1
		depositSelectedIndex = 1
		depositBackupSelectedIndex = 1
		depositScrollPos = 1
		deposit = false
	end
	backupSelectedIndex = selectedIndex
	backupSelectedContainer = inspectedContainer 
	local uiSize = uiSize
	
	if root then 
		root:destroy()
	end
	if tooltip then
		tooltip:destroy()
	end
	local localizedName = inspectedContainer.type.records[inspectedContainer.recordId].name
	local absPos = v2(hudLayerSize.x * uiLoc.x, hudLayerSize.y * uiLoc.y)
	root = ui.create({	--root
		type = ui.TYPE.Widget,
		layer = 'HUD',
		name = 'QuickLootBox',
		props = {
			anchor = v2(0.5,0.5), 
			position = absPos,
			size = v2(rootWidth, rootHeight),
		},
		content = ui.content {
		}
	})
	
	textSizeMult = ui.screenSize().y /1200*(uiSize.y/0.4)
	local outerHeaderFooterScale = (textSizeMult^0.5)/textSizeMult*uiScale
	textSizeMult = textSizeMult^0.5
	textSizeMult=textSizeMult*playerSection:get("textSizeMult")/100
	outerHeaderFooterScale = outerHeaderFooterScale*playerSection:get("textSizeMult")/100

	local outerHeaderFooterMargin = 0.005 *rootHeight
	outerHeaderFooterHeight = 0.06*outerHeaderFooterScale*rootHeight
	local captionOffset = 0

	

	local stealCol = nil
	if isPickpocketing
	or inspectedContainer.owner.recordId
	or inspectedContainer.owner.factionId and not types.NPC.getFactionRank(self, inspectedContainer.owner.factionId)
	or inspectedContainer.owner.factionId and types.NPC.getFactionRank(self, inspectedContainer.owner.factionId) < (inspectedContainer.owner.factionRank or 999) then
		--stealCol = util.color.rgba(1,0.714, 0.706, 1)
		stealCol = util.color.rgba(1,0.05, 0.05, 1)
		--STEALING ICON
		--captionOffset = outerHeaderFooterHeight/hudAspectRatio
		
	end
	

	--Caption: CONTAINER NAME
	local headline ={
		type = ui.TYPE.Flex,
		props = {
			position = v2(0, 0),
			size  = v2(1,outerHeaderFooterHeight),
			position = v2(0 + captionOffset, 0.011*rootHeight),
			anchor = v2(0,0),
			horizontal = true,
		},
		content = ui.content({})
	}
	table.insert(root.layout.content,headline)
	local titleText = ""..localizedName.." "
	if deposit then
		titleText = "->> "..localizedName.." "
	end
	table.insert(headline.content,{
		type = ui.TYPE.Text,
		template = quickLootText,
		props = {
			text = titleText,
			textSize= 25*textSizeMult,
			position = v2(0, 0),
			size  = v2(rootWidth,outerHeaderFooterHeight),
			position = v2(0.015*rootWidth + captionOffset, outerHeaderFooterHeight/2),
			anchor = v2(0,0.5),
			textColor = stealCol or playerSection:get("ICON_TINT"),
		}
	})
	
	if stealCol and playerSection:get("HAND_SYMBOL") then
		table.insert(headline.content,{
			type = ui.TYPE.Image,
			props = {
				resource = handTex,
				tileH = false,
				tileV = false,
				position = v2(0, 0),
				--relativeSize  = v2(1,1),
				size = v2(outerHeaderFooterHeight*0.8,outerHeaderFooterHeight*0.8),
				alpha = 0.8,
			}
		})
	end
	stealCol = stealCol and util.color.rgba(1,0.4, 0.4, 1)
	borderFile = "thin"
	local BORDER_STYLE = playerSection:get("BORDER_STYLE")
	if BORDER_STYLE == "verythick" or BORDER_STYLE == "thick" then
		borderFile = "thick"
	end
	borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or 1
	borderTemplate =  makeBorder(borderFile, stealCol or borderColor or nil, borderOffset).borders
	
	-- BOX
	boxHeight = rootHeight - 2 * (outerHeaderFooterHeight + outerHeaderFooterMargin)
	local box = { -- r.1.7
		type = ui.TYPE.Widget,
		props = {
			size = v2(rootWidth, boxHeight),
			position = v2(0, outerHeaderFooterHeight + outerHeaderFooterMargin),
		},
		content = ui.content {}
	}
	table.insert(root.layout.content, box)
	
	--box BACKGROUND
	table.insert(box.content, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			tileH = false,
			tileV = false,
			relativeSize  = v2(1,1),
			relativePosition = v2(0,0),
			alpha = transparency,
		}
	})
	--box BORDER
	table.insert(box.content, {
		template = BORDER_STYLE ~= "none" and borderTemplate or nil,
		props = {
			relativeSize  = v2(1,1),
			alpha = 0.5,
		}
	})
	
	local widgets = {} --inverse sorting
	if isPickpocketing and playerSection:get("COLUMN_WV_PICKPOCKETING") or not isPickpocketing and playerSection:get("COLUMN_WV") then
		table.insert(widgets,"valueByWeight")
	end
	if isPickpocketing and playerSection:get("COLUMN_VALUE_PICKPOCKETING") or not isPickpocketing and playerSection:get("COLUMN_VALUE") then
		table.insert(widgets,"value")
	end
	if isPickpocketing and playerSection:get("COLUMN_WEIGHT_PICKPOCKETING") or not isPickpocketing and playerSection:get("COLUMN_WEIGHT") then
		table.insert(widgets,"weight")
	end
	if isPickpocketing and playerSection:get("COLUMN_PICKPOCKET") then
		table.insert(widgets,"pickpocket")
	end
	
	encumbranceCurrent = types.Actor.getEncumbrance(self)
	local encumbranceMax = types.Actor.stats.attributes.strength(self).modified*core.getGMST("fEncumbranceStrMult")
	
	local headerFooterHeight = math.floor(itemFontSize*textSizeMult*1.25)
	local listHeight = boxHeight-2*borderOffset
	local listY = borderOffset
	--if header_footer_setting == "only top" or header_footer_setting == "all top" or header_footer_setting == "hide both" then -- WHY?
	--	listHeight = listHeight-2
	--end
	if header_footer_setting == "show both" then
		listHeight = listHeight - 2*(headerFooterHeight)
	elseif header_footer_setting ~= "hide both" then
		listHeight = listHeight - (headerFooterHeight)
	end
	
	if header_footer_setting == "show both" or header_footer_setting == "all top" or header_footer_setting == "only top" then
		listY = listY + headerFooterHeight
	end
	
	local function filterItems(t)
		local ret = {}
		for i, item in pairs(t) do
			if item.recordId:sub(1,9) ~= "_mca_mask" and item.recordId:sub(1,8) ~= "_mca_wig" then
				table.insert(ret,item)
			end
		end
		return ret
	end
	--GET CONTENTS
	if deposit then
		containerItems = types.Container.inventory(self):getAll()
		containerItems = filterItems(containerItems)
	else
		containerItems = types.Container.inventory(inspectedContainer):getAll()
		containerItems = filterItems(containerItems)
		if isPickpocketing then
			containerItems = pickpocket.filterItems(self, inspectedContainer, containerItems)
		end
	
	end
	
	-- HEADER
	if header_footer_setting == "show both" or header_footer_setting == "all top" or header_footer_setting ==  "only top" then
		local header = { -- r.1.7
			type = ui.TYPE.Widget,
			props = {
				size = v2(rootWidth-2*borderOffset, headerFooterHeight),
				position = v2(borderOffset, borderOffset),
			},
			content = ui.content {}
		}
		table.insert(box.content, header)
		--list HEADER Background
		table.insert(header.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,1),
				size = v2(0,0),
				--size = v2(-borderOffset*2,itemBoxHeaderFooterHeight-borderOffset),
				position = v2(0,0),
				relativePosition = v2(0, 0),
				alpha = transparency*0.75,
			}
		})
		--list HEADER Line
		if BORDER_STYLE ~= "none" then
			table.insert(header.content,
			{
				type = ui.TYPE.Image,
				props = {
					resource = playerSection:get("BORDER_FIX") and getTexture("textures/ql_makeborder/menu_thin_border_bottom.dds") or getTexture("textures/menu_thin_border_bottom.dds"),
					tileH = false,
					tileV = false,
					relativeSize  = v2(1,0),
					size = v2(0,1),
					position = v2(0,-1),
					relativePosition = v2(0, 1),
					alpha = 0.4,
					color = stealCol
				}
			})
		end
		if (header_footer_setting == "all top" or header_footer_setting ==  "only top") and isPickpocketing and pickpocket.footerText then

			header.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = pickpocketTex,
					tileH = false,
					tileV = false,
					size  = v2(0.85*headerFooterHeight,0.85*headerFooterHeight),
					position = v2(6,0),
					alpha = 0.7,
					anchor = v2(0,0),
					color = pickpocket.footerColor or playerSection:get("FONT_TINT")
				}
			}
			header.content:add{
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = ""..pickpocket.footerText.." ",
					textSize= headerFooterHeight*0.82,----20*textSizeMult,
					position = v2(0.85*headerFooterHeight+8, headerFooterHeight/2+1),
					size  = v2(55+0.85*headerFooterHeight,0.85*headerFooterHeight),
					anchor = v2(0,0.5),
					textColor = pickpocket.footerColor or playerSection:get("FONT_TINT")
				},
			}
		elseif header_footer_setting == "all top" then
			local encumbranceColor = playerSection:get("FONT_TINT")
			local encumbranceIconColor = playerSection:get("ICON_TINT")
			if encumbranceCurrent > encumbranceMax then
				encumbranceColor = util.color.rgb(0.85,0, 0)
				encumbranceIconColor = util.color.rgb(1,0, 0)
			end
			--list HEADER ENCUMBRANCE ICON
			table.insert(header.content,{
				type = ui.TYPE.Image,
				props = {
					resource = backpackTex,
					tileH = false,
					tileV = false,
					size  = v2(0.85*headerFooterHeight,0.85*headerFooterHeight),
					position = v2(8,2),
					alpha = 0.5,
					anchor = v2(0,0),
					color = encumbranceIconColor,
				}
			})
			
			--list HEADER ENCUMBRANCE TEXT
			table.insert(header.content,{
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = ""..math.floor(encumbranceCurrent+0.5).. "/"..math.floor(encumbranceMax+0.5),
					textSize= headerFooterHeight*0.82,----20*textSizeMult,
					position = v2(0.85*headerFooterHeight+8, headerFooterHeight/2+1),
					size  = v2(55+0.85*headerFooterHeight,0.85*headerFooterHeight),
					anchor = v2(0,0.5),
					textColor = encumbranceColor,
				},
			})
		end

		local widgetOffset = 0.05 -- for scrollbar
		--list HEADER ICONS
		for _, widget in pairs(widgets) do
			table.insert(header.content,{
				type = ui.TYPE.Image,
				props = {
					resource = _G[widget.."Tex"],
					tileH = false,
					tileV = false,
					size  = v2(0.95*headerFooterHeight,0.95*headerFooterHeight),
					relativePosition = v2(1-widgetOffset, -0.05),--itemBoxHeaderFooterHeight),
					position = v2(0,-1.5),
					anchor = v2(1,0),
					alpha = 0.8,
					color = playerSection:get("ICON_TINT"),
				}
			})
			widgetOffset =widgetOffset+ math.max(0.12,0.105*textSizeMult)--itemBoxHeaderFooterHeight*headerFooterScale
		end
	end
	-- /HEADER
	
	local entryWidth = 0.7*rootWidth

	local maxItems = math.floor(listHeight / (itemFontSize*textSizeMult*1.39+1))

	local relLineHeight = 1/maxItems
	local absLineHeight = relLineHeight * listHeight
	local position = 0
	
	

	

	
	local sortedItems = {
		{}, --cash = {}, --1
		{}, --keys = {}, --2
		{}, --lockpicks = {}, --3
		{}, --soulgems = {}, --4
		{}, --ingredients= {}, --5
		{}, --repair = {}, --6
		{}, --questItems = {}, --7
		{}, --other = {} --8
	}
	for _,item in pairs(containerItems) do
		local itemType = item.type
		local itemRecordId =item.recordId
		local itemRecord = item.type.record(itemRecordId)
		
		if not itemRecord.name 
		or itemRecord.name == "" 
		or not types.Item.isCarriable(item) 
		then
			-- ignore
		elseif playerSection:get("CONTAINER_SORTING_QUEST") and isQuestItem(item) then
			table.insert(sortedItems[1], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Miscellaneous and itemRecordId == "gold_001" and playerSection:get("CONTAINER_SORTING_CASH") then
			table.insert(sortedItems[2], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Miscellaneous and itemRecord.isKey and playerSection:get("CONTAINER_SORTING_KEYS") then
			table.insert(sortedItems[3], {item, itemRecord.value, itemRecord.weight})
		elseif (itemType == types.Lockpick or itemType == types.Probe) and playerSection:get("CONTAINER_SORTING_LOCKPICKS") then
			table.insert(sortedItems[4], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Miscellaneous and itemRecordId:sub(1,12) == "misc_soulgem" and playerSection:get("CONTAINER_SORTING_SOULGEMS") then
			table.insert(sortedItems[5], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Ingredient and playerSection:get("CONTAINER_SORTING_INGREDIENTS") > 0 then
			if itemRecord.weight <= playerSection:get("CONTAINER_SORTING_INGREDIENTS") then
				table.insert(sortedItems[6], {item, itemRecord.value, itemRecord.weight})
			else
				table.insert(sortedItems[7], {item, itemRecord.value, itemRecord.weight})
			end
		elseif itemType == types.Repair and playerSection:get("CONTAINER_SORTING_REPAIR") then
			table.insert(sortedItems[6], {item, itemRecord.value, itemRecord.weight})
		else
			table.insert(sortedItems[8], {item, itemRecord.value, itemRecord.weight})
		end
	end
	containerItems = {}
	for cat, tbl in pairs(sortedItems) do
		if playerSection:get("CONTAINER_SORTING_STATS") ~= "Vanilla" then
			table.sort(tbl, function(a, b)
				if playerSection:get("CONTAINER_SORTING_STATS") == "Lowest Weight" then
					return a[3] < b[3] or (a[3] == b[3] and a[1].type.record(a[1]).name:lower() < b[1].type.record(b[1]).name:lower())
				elseif playerSection:get("CONTAINER_SORTING_STATS") == "Highest Value" then
					return a[2] > b[2] or (a[2] == b[2] and a[1].type.record(a[1]).name:lower() < b[1].type.record(b[1]).name:lower())
				else -- "Best W/V"
					local a_WV = a[2] / math.max(0.1, a[3])
					local b_WV = b[2] / math.max(0.1, b[3])
					return a_WV > b_WV or (a_WV == b_WV and a[1].type.record(a[1]).name:lower() < b[1].type.record(b[1]).name:lower())
				end
			end)
		else
			local prio={
				Weapon = 20,
				Armor = 18,
				Clothing = 16,
				Potion = 14,
				Ingredient = 12,
				Apparatus = 10,
				Book = 8,
				Light = 6,
				Miscellaneous = 4,
				Lockpick = 2,
				Repair = 0,
				Probe = -2,
			}
			table.sort(tbl, function(a,b)
				if (prio[tostring(a[1].type)] or -99) == (prio[tostring(b[1].type)] or -99) then
					return string.upper(a[1].type.record(a[1]).name) < string.upper(b[1].type.record(b[1]).name)
				else
					return (prio[tostring(a[1].type)] or -99) > (prio[tostring(b[1].type)] or -99)
				end
			end)
			--print(tostring(tbl[1].type))
			
		end
		for _, itemData in pairs(tbl) do
			table.insert(containerItems,itemData[1])
		end
	end
	-- /SORTING
	
	-- LIST
	local list = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(rootWidth-borderOffset*2, listHeight),
			position = v2(borderOffset, listY),
		},
		content = ui.content {}
	}
	table.insert(box.content, list)
	
	local containerItemCount = #containerItems
	if pickpocket.message then
		containerItemCount = containerItemCount + 1
	end
	
	--SCROLLBAR
	local highlightWidth = 1
	selectedIndex = math.min(selectedIndex,#containerItems)
	if selectedIndex >= scrollPos+maxItems-1 then
		scrollPos = math.min(containerItemCount-maxItems+1, selectedIndex - maxItems+2)
	elseif selectedIndex <= scrollPos then
		scrollPos = math.max(1,selectedIndex-1)
	end
	scrollPos = math.min(scrollPos, math.max(1,containerItemCount+2-maxItems))
	local visibleItems = math.min(maxItems,containerItemCount-scrollPos+1)
	if scrollPos > 1 or containerItemCount > maxItems then -- show scrollbar?
		highlightWidth = 0.96
		
		-- rounding fix:
		local visibleStart = math.floor((scrollPos-1)/containerItemCount*listHeight+0.5)
		local visibleEnd = math.ceil((scrollPos-1+visibleItems)/containerItemCount*listHeight)
		local visibleLength = math.min(listHeight, visibleEnd - visibleStart)
		
		local selectedStart = math.floor((selectedIndex-1)/containerItemCount*listHeight+0.5)
		local selectedEnd = math.ceil((selectedIndex-1+1)/containerItemCount*listHeight)
		local selectedLength = math.min(listHeight, selectedEnd - selectedStart)

		--SCROLLBAR BACKGROUND
		table.insert(list.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				anchor=v2(1,0),
				relativePosition = v2(1,0),
				relativeSize = v2(0.04,1),
				alpha = math.min(1,transparency*1.25),
				color = playerSection:get("FONT_TINT"),
			}
		})
		--SCROLLBAR VISIBLE RANGE
		table.insert(list.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = white,
				relativePosition = v2(1,0),
				relativeSize  = v2(0.04,0),
				position = v2(0,visibleStart),
				size = v2(0,visibleLength),
				alpha = 0.15,
				anchor= v2(1,0),
				color = playerSection:get("ICON_TINT"),
				
			}
		})
		--SCROLLBAR SELECTED
		table.insert(list.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = white,
				relativePosition = v2(1,0),
				relativeSize  = v2(0.04,0),
				position = v2(0,selectedStart),
				size = v2(0,    selectedLength),
				alpha = 0.5,
				anchor=v2(1,0),
				color = playerSection:get("ICON_TINT"),
			}
		})
	end

	-- ITEMS
	local relativePosition = 0
	local renderedEntries = 0
	
	if not isPickpocketing or pickpocket.showContents or deposit then			
		for i, thing in pairs(containerItems) do
			local thingRecord = thing.type.records[thing.recordId]
			if not thingRecord then
				ui.showMessage("ERROR: no record for "..thing.id.." (please report this bug)")
			elseif i >=scrollPos and renderedEntries < maxItems then
				renderedEntries = renderedEntries + 1
				local thingName =  thingRecord.name or thing.id
				--thingName= fromutf8(thingName)
				local icon = thingRecord.icon
				local thingCount = thing.count or 1
				local countText = thingCount > 1 and " ("..thing.count..")" or ""
				if i == selectedIndex then
					-- SELECTION HIGHLIGHT
					local stealCol = stealCol
					if stealCol then
						stealCol = util.color.rgba(stealCol.r*1.4,stealCol.g*1.4,stealCol.b*1.4,stealCol.a)
					end
					table.insert(list.content, {
						type = ui.TYPE.Image,
						props = {
							resource = white,
							tileH = false,
							tileV = false,
							relativeSize  = v2(highlightWidth,0),
							size = v2(1,math.ceil(relLineHeight*listHeight)),
							relativePosition = v2(0,relativePosition),
							position = v2(0,0),
							alpha = 0.3,
							color = stealCol or playerSection:get("ICON_TINT"),
						}
					})
					tooltip = makeTooltip(
						thing
						,
						-- box position
						outerHeaderFooterHeight + outerHeaderFooterMargin
						-- list position
						+listY
						-- highlight position * list height
						+relativePosition*listHeight
						,
						isPickpocketing,
						stealCol,
						deposit
					)
				end
				local ench = thing and (thing.enchant or thingRecord.enchant ~= "" and thingRecord.enchant or types.Item.itemData(thing).soul)
				local tempTemplate = nil
				if deposit and types.Actor.hasEquipped(self,thing) or types.Actor.hasEquipped(inspectedContainer,thing) then
					tempTemplate = borderTemplate
				end
				local iconBox ={
						template = tempTemplate,
						props = {
							relativePosition = v2(0,relativePosition),
							size = v2(absLineHeight-1,absLineHeight-1),
							position = v2(1,1),
							alpha = 0.85,
						},
						content = ui.content{}
					}
				table.insert(list.content, iconBox)
				if icon then
					if ench then 
						--ENCHANT ICON
						table.insert(iconBox.content, {
							type = ui.TYPE.Image,
							props = {
								resource = getTexture("textures\\menu_icon_magic_mini.dds"),
								tileH = false,
								tileV = false,
								--relativePosition = v2(0,relativePosition),
								--size = v2(absLineHeight-2,absLineHeight-2),
								relativeSize = v2(1,1),
								--position = v2(-1,-1),
								--size = v2(1,1),
								alpha = 0.7,
							}
						})			
					end
					-- ITEM ICON
					table.insert(iconBox.content, {
						type = ui.TYPE.Image,
						props = {
							resource = getTexture(icon),
							tileH = false,
							tileV = false,
							--relativePosition = v2(0,relativePosition),
							--size = v2(absLineHeight-2,absLineHeight-2),
							--anchor = v2(0,0),
							--position = v2(1,1),
							relativeSize = v2(1,1),
							alpha = 0.9,
						}
					})
				end
				local readItem = "" --(not playerSection:get("FONT_FIX") and hextoutf8(0xd83d) or "(R)")
				local readElement = {
						type = ui.TYPE.Image,
						props = {
							resource = getTexture("textures/read_indicator.dds"),
							tileH = false,
							tileV = false,
							--relativePosition = v2(0,relativePosition),
							--size = v2(absLineHeight*0.7,absLineHeight*0.7),
							--relativePosition = v2(0,relativePosition),
							--size = v2(absLineHeight-2,absLineHeight-2),
							relativePosition = v2(0,0),
							relativeSize = v2(1,1),
							anchor = v2(0,0),
							alpha = 0.7,
							--position = v2(3,1),
							color = playerSection:get("FONT_TINT"),
						}
					}
				if ench or thing.itemRecordId =="sc_paper plain" or playerSection:get("READ_BOOKS") == "off" or thing.type ~= types.Book then
					readElement = nil
				else
					if playerSection:get("READ_BOOKS") == "bookworm unread" then
						local DBentry = bookSection:get(thing.recordId)
						if savegameData.bookSection[thing.recordId] then
							readElement.props.resource = getTexture("textures/hearteye3.dds")
						end
						if DBentry and DBentry >= 20 then
							readElement = nil
						end
					elseif playerSection:get("READ_BOOKS") == "bookworm" then
						local DBentry = bookSection:get(thing.recordId)
						if not savegameData.bookSection[thing.recordId] then
							readElement = nil
						elseif DBentry and DBentry >= 20 then
							readElement.props.resource = getTexture("textures/hearteye3.dds")
						end
					elseif playerSection:get("READ_BOOKS") == "read" then
						local DBentry = bookSection:get(thing.recordId)
						if not savegameData.bookSection[thing.recordId] then
							readElement = nil
						elseif DBentry and DBentry >= 20 then
							readElement.props.resource = getTexture("textures/hearteye.dds")
						end
					else
						if savegameData.bookSection[thing.recordId] then
							readElement = nil
						end
					end
				end
				if readElement then
					table.insert(iconBox.content, readElement)
				end
				if isQuestItem(thing) then
					iconBox.content:add{
						type = ui.TYPE.Image,
						props = {
							resource = getTexture("textures/questItem2.dds"),
							tileH = false,
							tileV = false,
							--relativePosition = v2(0,relativePosition),
							--size = v2(absLineHeight*0.7,absLineHeight*0.7),
							--relativePosition = v2(0,relativePosition),
							--size = v2(absLineHeight-2,absLineHeight-2),
							relativePosition = v2(0,0),
							relativeSize = v2(1,1),
							anchor = v2(0,0),
							alpha = 1,
							--position = v2(3,1),
							--color = playerSection:get("FONT_TINT"),
						}
					}
				end
				-- ITEM NAME + COUNT
				table.insert(list.content, { 
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = ""..thingName..countText..readItem,--..hextoutf8(0xd83d)..hextoutf8(0xd83e),--thingName..countText,
						textSize = itemFontSize*textSizeMult,--itemFontSize*textSizeMult,
						
						relativeSize  = v2(entryWidth,relLineHeight),
						relativePosition = v2(0, relativePosition+relLineHeight/2),
						position = v2(absLineHeight+3,0), --icon shift
						anchor = v2(0,0.5),
					},
					})
				
				local widgetOffset = 0.05 --scrollbar
				local thingValue = thingRecord.value
				local thingWeight = thingRecord.weight
				if thingRecord.isKey then
					thingValue = 0
				end
				for _, widget in pairs(widgets) do
					local textColor = nil
					local text = ""
					if widget == "valueByWeight" then
						if thingValue == 0 and thingWeight == 0 then
							text = "-"
						else
							text = formatNumber(thingValue/thingWeight, "v/w")
						end
					elseif widget == "weight" then
						text = formatNumber(thingWeight, "weight")
						
						if thingWeight+encumbranceCurrent > encumbranceMax then
							textColor = util.color.rgb(0.85,0, 0)
						end
					elseif widget == "pickpocket" then
						text = pickpocket.getColumnText(self, inspectedContainer, thing, deposit)
					else
						text = formatNumber(thingValue, "value")
					end
					
					local tempSize = v2(1.1*headerFooterHeight,relLineHeight)
					if infSymbol then
						table.insert(list.content, {
							type = ui.TYPE.Image,
							--template = quickLootText,
							props = {
								resource = getTexture("textures/inf.dds"),
								tileH = false,
								tileV = false,
								--text = text,
								textSize = itemFontSize*textSizeMult,
								--relativeSize  = tempSize,
								relativePosition = v2(1-widgetOffset, relativePosition+relLineHeight/2),
								anchor = v2(1,0.5),
								size = v2(itemFontSize*0.65,itemFontSize*0.65),
								color = playerSection:get("FONT_TINT"),
								--textColor = textColor,
								--alpha = 0.4,
							},
						})
					else
						table.insert(list.content, {
							type = ui.TYPE.Text,
							template = quickLootText,
							props = {
								text = text,
								textSize = itemFontSize*textSizeMult,
								relativeSize  = tempSize,
								relativePosition = v2(1-widgetOffset, relativePosition+relLineHeight/2),
								anchor = v2(1,0.5),
								textColor = textColor,
							},
						})
					end
					widgetOffset = widgetOffset + math.max(0.12,0.105*textSizeMult)
				end
				relativePosition = relativePosition + relLineHeight--
			end
		end
	end
	if pickpocket.message then
		table.insert(list.content, { 
			type = ui.TYPE.Text,
			template = quickLootText,
			props = {
				text = pickpocket.message,--..hextoutf8(0xd83d)..hextoutf8(0xd83e),--thingName..countText,
				textSize = itemFontSize*textSizeMult,--itemFontSize*textSizeMult,
				
				relativeSize  = v2(entryWidth,relLineHeight),
				relativePosition = v2(0, relativePosition+relLineHeight/2),
				position = v2(absLineHeight+3,0), --icon shift
				anchor = v2(0,0.5),
			},
		})
	end
	-- FOOTER
	if header_footer_setting == "show both" or header_footer_setting == "all bottom" or header_footer_setting ==  "only bottom" then
		local footer = { -- r.1.7
			type = ui.TYPE.Widget,
			props = {
				size = v2(rootWidth-2*borderOffset, headerFooterHeight),
				position = v2(borderOffset, boxHeight-headerFooterHeight-borderOffset),
			},
			content = ui.content {}
		}
		table.insert(box.content, footer)
		--list FOOTER Background
		table.insert(footer.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,1),
				size = v2(0,0),
				--size = v2(-borderOffset*2,itemBoxHeaderFooterHeight-borderOffset),
				position = v2(0,0),
				relativePosition = v2(0, 0),
				alpha = 0.3,
			}
		})
		--list FOOTER Line
		if BORDER_STYLE ~= "none" then
			table.insert(footer.content,
			{
				type = ui.TYPE.Image,
				props = {
					resource = playerSection:get("BORDER_FIX") and getTexture("textures/ql_makeborder/menu_thin_border_bottom.dds") or getTexture("textures/menu_thin_border_bottom.dds"),
					tileH = false,
					tileV = false,
					relativeSize  = v2(1,0),
					size = v2(0,1),
					position = v2(0,0),
					relativePosition = v2(0, 0),
					alpha = 0.4,
					color = stealCol
				}
			})
		end
		local encumbranceColor = playerSection:get("FONT_TINT")
		local encumbranceIconColor = playerSection:get("ICON_TINT")
		if encumbranceCurrent > encumbranceMax then
			encumbranceColor = util.color.rgb(0.85,0, 0)
			encumbranceIconColor = util.color.rgb(1,0, 0)
		end
		if isPickpocketing and pickpocket.footerText and (header_footer_setting ==  "all bottom") then

			footer.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = pickpocketTex,
					tileH = false,
					tileV = false,
					size  = v2(0.8*headerFooterHeight,0.8*headerFooterHeight),
					position = v2(8,1),
					color = pickpocket.footerColor or playerSection:get("FONT_TINT"),
					alpha = 0.7,
				}
			}
			footer.content:add{
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = ""..pickpocket.footerText.." ",
					textSize= headerFooterHeight*0.82,----20*textSizeMult,
					position = v2(0.85*headerFooterHeight+10, headerFooterHeight/2+1),
					size  = v2(55+0.85*headerFooterHeight,0.85*headerFooterHeight),
					anchor = v2(0,0.5),
					textColor = pickpocket.footerColor or playerSection:get("FONT_TINT"),
				},
			}
		else
			--list FOOTER ENCUMBRANCE ICON
			table.insert(footer.content,{
				type = ui.TYPE.Image,
				props = {
					resource = backpackTex,
					tileH = false,
					tileV = false,
					size  = v2(0.85*headerFooterHeight,0.85*headerFooterHeight),
					position = v2(8,2),
					alpha = 0.5,
					anchor = v2(0,0),
					color = encumbranceIconColor,
				}
			})
			
			--list FOOTER ENCUMBRANCE TEXT
			table.insert(footer.content,{
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = ""..math.floor(encumbranceCurrent+0.5).. "/"..math.floor(encumbranceMax+0.5),
					textSize= headerFooterHeight*0.82,----20*textSizeMult,
					position = v2(0.85*headerFooterHeight+8, headerFooterHeight/2+1),
					size  = v2(55+0.85*headerFooterHeight,0.85*headerFooterHeight),
					anchor = v2(0,0.5),
					textColor = encumbranceColor,
				},
			})
		end
		if isPickpocketing and pickpocket.footerText and (header_footer_setting == "show both" or header_footer_setting == "only bottom") then
			local flex = {
				type = ui.TYPE.Flex,
				props = {
					--size  = v2(0.85*headerFooterHeight,0.85*headerFooterHeight),
					anchor = v2(1,0),
					relativePosition = v2(1,0),
					horizontal = true,
					position = v2(0,1)
					--color = encumbranceIconColor,
				},
				content = ui.content{}
			}
			table.insert(footer.content,flex)
			
			flex.content:add{
				type = ui.TYPE.Image,
				props = {
					resource = pickpocketTex,
					tileH = false,
					tileV = false,
					size  = v2(0.85*headerFooterHeight,0.85*headerFooterHeight),
					--position = v2(8,2),
					--alpha = 0.5,
					--anchor = v2(0,0),
					color = pickpocket.footerColor or playerSection:get("FONT_TINT"),
					alpha = 0.7,
				}
			}
			flex.content:add{ props = { size = v2(1, 1) * 2 } }
			flex.content:add{
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = ""..pickpocket.footerText.." ",
					textSize= headerFooterHeight*0.82,----20*textSizeMult,
					--position = v2(0.85*headerFooterHeight+8, headerFooterHeight/2+1),
					--size  = v2(55+0.85*headerFooterHeight,0.85*headerFooterHeight),
					--anchor = v2(0,0.5),
					textColor = pickpocket.footerColor or playerSection:get("FONT_TINT"),
				},
			}
		end
		if header_footer_setting == "all bottom" then
			local widgetOffset = 0.05 -- for scrollbar
			--list FOOTER ICONS
			for _, widget in pairs(widgets) do
				table.insert(footer.content,{
					type = ui.TYPE.Image,
					props = {
						resource = _G[widget.."Tex"],
						tileH = false,
						tileV = false,
						size  = v2(0.95*headerFooterHeight,0.95*headerFooterHeight),
						relativePosition = v2(1-widgetOffset, -0.05),--itemBoxHeaderFooterHeight),
						position = v2(0,0),
						anchor = v2(1,0),
						alpha = 0.8,
						color = playerSection:get("ICON_TINT"),
					}
				})
				widgetOffset =widgetOffset+ math.max(0.12,0.105*textSizeMult)--itemBoxHeaderFooterHeight*headerFooterScale
			end
		end
	end
	-- /FOOTER
	
	
	-- SUB-FOOTER
	if playerSection:get("FOOTER_HINTS") ~= "Disabled" then
		local fTex = fKeyTex
		local rTex = rKeyTex
		--if playerSection:get("FOOTER_HINTS") == "Symbolic" then
			fTex = fSymbolicTex
		    rTex = rSymbolicTex
		--end	
			
		--SUB-FOOTER ICON Right
		table.insert(root.layout.content,{
			type = ui.TYPE.Image,
			props = {
				resource = fTex,
				tileH = false,
				tileV = false,
				size  = v2(outerHeaderFooterHeight*0.8,outerHeaderFooterHeight*0.8),
				position = v2(rootWidth*0.505,rootHeight-outerHeaderFooterHeight/2),
				anchor = v2(0,0.5),
				alpha = 0.6,
				color = playerSection:get("ICON_TINT"),
				
			}
		})
		--SUB-FOOTER TEXT Right
		table.insert(root.layout.content,{
			type = ui.TYPE.Text,
			template = quickLootText,
			props = {
				text = deposit and "Deposit All" or "Take All",
				textSize= 20*textSizeMult,
				position = v2(rootWidth*0.508+outerHeaderFooterHeight*0.8,rootHeight-outerHeaderFooterHeight/2+1),
				textColor = playerSection:get("ICON_TINT"),
				anchor = v2(0,0.5),
			},	})
		--SUB-FOOTER ICON Left
		table.insert(root.layout.content,{
			type = ui.TYPE.Image,
			props = {
				resource = rTex,
				tileH = false,
				tileV = false,
				
				size = v2(outerHeaderFooterHeight*0.8,outerHeaderFooterHeight*0.8),
				position = v2(rootWidth*0.495,rootHeight-outerHeaderFooterHeight/2),
				anchor = v2(1,0.5),
				alpha = 0.6,
				color = playerSection:get("ICON_TINT"),
			}
		})
		--SUB-FOOTER TEXT Left
		local searchText = "Search"
		if playerSection:get("R_DEPOSIT") then
			if deposit then
				searchText = "Withdraw"
			else
				searchText = "Deposit"
			end
		end
		table.insert(root.layout.content,{
			type = ui.TYPE.Text,
			template = quickLootText,
			props = {
				text = searchText,
				textSize= 20*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				position = v2(rootWidth*0.493-outerHeaderFooterHeight*0.8,rootHeight-outerHeaderFooterHeight/2+1),
				anchor = v2(1,0.5),
				textColor = playerSection:get("ICON_TINT"),
			},
		})
	end
	-- /SUB-FOOTER
end

function closeHud()
	if inspectedContainer then
		inspectedContainer:sendEvent("OwnlysQuickLoot_closeAnimation",self)
		inspectedContainer = nil
		Controls.overrideCombatControls(false)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true) 
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping, true)
		core.sendGlobalEvent("OwnlysQuickLoot_closeGUI", self.object)
		Camera.enableZoom("quickloot")
		containerHash = 99999999
		pickpocket.closeHud(self)
		currentScript = nil
		mwScriptCalled = 0
		if root then 
			root:destroy() 
		end
		if tooltip then
			tooltip:destroy()
		end
	end
end

if not core.mwscripts then
	scriptDB = require("scripts.OwnlysQuickLoot.ql_script_db")
end

function scriptAllows(cont)

	--if (cont.recordId:find("contain_bm_stalhrim")) then
	--	playerItems = types.Container.inventory(self):getAll()
	--	for a,b in pairs(playerItems) do
	--		if b.recordId == "bm nordic pick" then
	--			return true
	--		end
	--	end
	--	return false
	--end
	if types.Actor.objectIsInstance(cont) and not types.Actor.isDead(cont) then
		return true
	end
	if types.Lockable.getTrapSpell(cont) then
		return false
	end
	local script = cont.type.record(cont).mwscript
	if script then
		if core.mwscripts then
			local scriptRecord = core.mwscripts.records[script]
			if scriptRecord and not scriptRecord.text:lower():find("onactivate") then
				log(script.." ok")
				return true
			else
				log(script.." not ok")
				return false
			end
		else
			if scriptDB[script] == false then
				log(script.." ok")
				return true
			elseif scriptDB[script] then
				log(script.." not ok (blacklist)")
				return false
			else
				log(script.." ok (unknown)")
				return true
			end
		end
	else
		return true
	end
	---------------------------------------------------------------------------------------------
	if script == currentScript then
		return true
	end
	if not script then
		return true 
	elseif scriptDB[script] == false then
		log("quickloot: target has script '"..script.."' (whitelist)")
		return true 
	end
	if playerSection:get("RUN_SCRIPT_ONCE") and savegameData.openedScriptedContainers[cont.id] then
		return true
	end
	if scriptDB[script] then
		log("quickloot: target has script '"..script.."' (blacklist)")
		local now = core.getRealTime()
		if now - mwScriptCalled >=1 then
			--core.sendGlobalEvent("OwnlysQuickLoot_tryScript",{self,cont}) --new
			cont:activateBy(self)--new--new
			mwScriptCalled = now
			scriptContainer = cont
		end
		return false
	else
		log("quickloot: target has script '"..script.."' (unknown)")
		local now = core.getRealTime()
		if now - mwScriptCalled >=1 then
			--core.sendGlobalEvent("OwnlysQuickLoot_tryScript",{self,cont}) --new
			cont:activateBy(self)--new--new
			mwScriptCalled = now
			scriptContainer = cont
		end
		return false
	end
	
	--if not types.Container.objectIsInstance(cont) then --is Creature or NPC
	--	if playerSection:get("DISABLE_SCRIPTED_ACTORS") then
	--		log("quickloot: actor has script '"..script.."'")
	--		return false
	--	else
	--		local now = core.getRealTime()
	--		if now - mwScriptCalled >=1 then
	--			core.sendGlobalEvent("OwnlysQuickLoot_tryScript",{self,cont}) --new
	--			mwScriptCalled = now
	--		end
	--		return false --new
	--		--return true --new
	--	end
	--end
	--if playerSection:get("DISABLE_SCRIPTED_CONTAINERS") then
	--	log("quickloot: container has script '"..script.."'")
	--	return false
	--else --new
	--	local now = core.getRealTime()
	--	if now - mwScriptCalled >=1 then
	--		core.sendGlobalEvent("OwnlysQuickLoot_tryScript",{self,cont}) --new
	--		mwScriptCalled = now
	--	end
	--	return false --new
	--end
end

local function chargenFinished()
	if types.Player.isCharGenFinished(self) then
		return true
	end
	playerItems = types.Container.inventory(self):getAll()
	for a,b in pairs(playerItems) do
		if b.recordId == "chargen statssheet" then
			return true
		end
	end
end

local function deathAnimCheck(actor)
	if playerSection:get("CAN_LOOT_DURING_DEATH_ANIMATION")
	or types.Actor.isDeathFinished(actor)
	then
		deathAnimationProgress = 0
		return true
	end

	local progress = 0
	for groupName in pairs(groups) do
		local time = animation.getCompletion(actor, groupName)
		if time then
			progress=time
		end
	end
	if progress > 0.55 then
		return true
	end
	return false
	
end


function onFrame(dt)

	--print("onframe", I.UI.getMode() or "I.UI.getMode() = nil")
	printThrottle = printThrottle - dt
	--if inspectedContainer then
	--	-- Get the yaw angle of the container
	--	local containerYaw = inspectedContainer.rotation:getYaw()
	--	
	--	-- Calculate the angle from container to player in the horizontal plane
	--	local deltaX = self.position.x - inspectedContainer.position.x
	--	local deltaY = self.position.y - inspectedContainer.position.y
	--	local playerAngle = math.atan2(deltaX, deltaY)
	--	
	--	-- Calculate the relative angle (how far the player is from the container's forward direction)
	--	local relativeAngle = playerAngle - containerYaw
	--	-- Normalize to -pi to pi range
	--	while relativeAngle > math.pi do relativeAngle = relativeAngle - 2*math.pi end
	--	while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2*math.pi end
	--	
	--	-- Determine the direction based on the angle
	--	local direction
	--	if math.abs(relativeAngle) < math.pi/4 then
	--		direction = "in front"
	--	elseif math.abs(relativeAngle) > 3*math.pi/4 then
	--		direction = "behind"
	--	elseif relativeAngle > 0 then
	--		direction = "right"
	--	else
	--		direction = "left"
	--	end
	--end
	if types.Actor.getStance(self) ~= types.Actor.STANCE.Nothing and input.getBooleanActionValue("Use") then
		return false
	end
	--if inspectedContainer and core.contentFiles.has("QuickSpellCast.omwscripts")  and types.Actor.getStance(self) == types.Actor.STANCE.Spell then
		--types.Actor.setStance(self, types.Actor.STANCE.Nothing)
	--end
 --self.controls.use = 0
	if not modEnabled then
		return
	end
	if not chargenFinished() then
		return
	end
	
	if I.UI.getMode() and not showInMainMenuOverride then
		return
	end
	if playerSection:get("CONTAINER_ANIMATION") == "disabled by shift" then
		local newShiftPressed = input.isShiftPressed()
		if shiftPressed ~= newShiftPressed then
			if inspectedContainer then
				if newShiftPressed then
					inspectedContainer:sendEvent("OwnlysQuickLoot_closeAnimation",self)
				else
					inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
				end
			end
		end		
		shiftPressed = newShiftPressed
	end
	local camera = require('openmw.camera')
	local cameraPos = camera.getPosition()
	local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
	local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
	local bonusDistance = 0
	if hoveredContainer then
		bonusDistance = 20
	end
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
	if (telekinesis) then
		activationDistance = activationDistance + (telekinesis.magnitude * 22);
	end
	activationDistance = activationDistance+0.1
	
	local res = nearby.castRenderingRay(
		cameraPos,
		cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * (activationDistance + bonusDistance),
		{ ignore = self }
	)
	if hoveredContainer ~= res.hitObject then
		res = nearby.castRenderingRay(
			cameraPos,
			cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * (activationDistance + 0),
			{ ignore = self }
		)
	end
	local LOOSE_AIMING = playerSection:get("LOOSE_AIMING3")
	if LOOSE_AIMING ~= "Off" and (not res.hitObject or (res.hitObject.type ~= types.Container and not types.Actor.objectIsInstance(res.hitObject))) then
		local numPoints = 8
		local radius = 0.006
		if LOOSE_AIMING == "Precise" then
			for i = 1, numPoints do
				local angle = (2 * math.pi / numPoints) * i
				local x = 0.5 + radius * math.cos(angle)
				local y = 0.5 + radius * math.sin(angle)*16/9
				res = nearby.castRenderingRay(
					cameraPos ,
					cameraPos + camera.viewportToWorldVector(v2(x,y)) * activationDistance,
					{ ignore = self }
				)
				
				if res.hitObject and res.hitObject.type == types.Container then -- and types.Container.record(res.hitObject).isOrganic and not organicContainers[res.hitObject.recordId] and (not types.Container.content(res.hitObject):isResolved() or types.Container.content(res.hitObject):getAll()[1]) then
					break
				end
			end
		end
		if (not res.hitObject or (res.hitObject.type ~= types.Container and not types.Actor.objectIsInstance(res.hitObject))) then
			numPoints = 8
			radius = 0.011
			for i = 1, numPoints do
				local angle = (2 * math.pi / numPoints) * i
				local x = 0.5 + radius * math.cos(angle)
				local y = 0.5 + radius * math.sin(angle)*16/9
				res = nearby.castRenderingRay(
					cameraPos ,
					cameraPos + camera.viewportToWorldVector(v2(x,y)) * activationDistance,
					{ ignore = self }
				)
				
				if res.hitObject and res.hitObject.type == types.Container then -- and types.Container.record(res.hitObject).isOrganic and not organicContainers[res.hitObject.recordId] and (not types.Container.content(res.hitObject):isResolved() or types.Container.content(res.hitObject):getAll()[1]) then
					break
				end
			end
		end
	end
	if (not res.hitObject or (res.hitObject.type ~= types.Container and not types.Actor.objectIsInstance(res.hitObject))) then
		res = {hitObject = nil}
	end
	hoveredContainer = res.hitObject

	if inspectedContainer and (res.hitObject == nil or res.hitObject ~= inspectedContainer) then
		closeHud()
	elseif inspectedContainer and types.Actor.getEncumbrance(self) ~= encumbranceCurrent then
		drawUI()
	end
	--if inspectedContainer then
	--	print(inspectedContainer.rotation)
	--end
	
	if inspectedContainer 
	and res.hitObject
	and res.hitObject.type == types.NPC
	and not types.Actor.isDead(res.hitObject) --opened container that is not dead
	and not (
			crimesVersion >= 2
			and playerSection:get("PICKPOCKETING")
			and pickpocket.validateTarget(self, res.hitObject, input)
		)
	
	--(
	--	types.Actor.getStance(res.hitObject) ~= types.Actor.STANCE.Nothing 
	--	or not input.getBooleanActionValue("Sneak") -- but it's also not idle or the player not sneaking (anymore)
	--)
	then
		closeHud()
	end
	if inspectedContainer and 
			(
				res.hitObject.type == types.NPC
				or res.hitObject.type == types.Creature
			)
			and types.Actor.isDead(res.hitObject)
		then
		
	end
	if inspectedContainer then
		pickpocket.onFrame(self, inspectedContainer, input, drawUI)
	elseif not inspectedContainer 
	and res.hitObject 
	and (
			res.hitObject.type == types.Container
			and (not types.Container.record(res.hitObject).isOrganic or organicContainers[res.hitObject.recordId])
		or ((
				res.hitObject.type == types.NPC
				or res.hitObject.type == types.Creature
			)
			and types.Actor.isDead(res.hitObject)
			and deathAnimCheck(res.hitObject)
		)
		or (
			crimesVersion >= 2
			and playerSection:get("PICKPOCKETING")
			and pickpocket.validateTarget(self, res.hitObject, input)
		)
		
	)	
	and not types.Lockable.isLocked(res.hitObject)
	and not types.Lockable.getTrapSpell(res.hitObject)
	and scriptAllows(res.hitObject)
	then
		if not types.Container.inventory(res.hitObject):isResolved() then
			core.sendGlobalEvent("OwnlysQuickLoot_resolve",res.hitObject)
		else
			inspectedContainer = res.hitObject
			self.controls.use = 0
			Controls.overrideCombatControls(true)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false) 
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
			core.sendGlobalEvent("OwnlysQuickLoot_openGUI",self.object)
			
			if playerSection:get("DISPOSE_CORPSE") == "Jump" and types.Actor.objectIsInstance(inspectedContainer) then
				types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping, false)
			end
			Camera.disableZoom("quickloot")
			if playerSection:get("CONTAINER_ANIMATION") == "immediately" or playerSection:get("CONTAINER_ANIMATION") == "disabled by shift" and not input.isShiftPressed() then
				inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
			end
			selectedIndex = 1
		end
	end
	if inspectedContainer then
		local newHash = ""
		local entryCount = 0
		local inv =nil
		if deposit then
			inv = types.Container.inventory(self):getAll()
		else
			inv = types.Container.inventory(inspectedContainer):getAll()
		end
		for _, thing in pairs(inv) do
			--itemCount = itemCount + thing.count
			newHash = newHash..thing.count..thing.recordId
			entryCount = entryCount + 1
		end
		if entryCount < selectedIndex then
			selectedIndex = entryCount
		end
		
		--print(newHash)
		if containerHash ~= newHash then
			drawUI()
		end
		
		containerHash = newHash
	end
end

local function onKey(key)
	if not modEnabled then
		return
	end
	--print(key)
	--print(core.getRealTime() - OPENED_TIMESTAMP)
	--if inspectedContainer and key.code == TAKEALL_KEYBINDING then
	--	core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer,  playerSection:get("DISPOSE_CORPSE") == "Shift + F" and input.isShiftPressed(), playerSection:get("EXPERIMENTAL_LOOTING")})
	--end
	--return false
end
local function onMouseWheel(vertical)
	if not modEnabled then
		return
	end
	--print(vertical)
	if inspectedContainer then
		local shouldRefresh = pickpocket.scroll(self, inspectedContainer, input)
		--local newIndex = math.min(#containerItems,math.max(1,selectedIndex - vertical))
		local newIndex = selectedIndex - vertical
		if newIndex <= 0 then
			newIndex = math.max(1,#containerItems)
		elseif newIndex > #containerItems then
			newIndex = 1
		end
		if selectedIndex ~= newIndex or shouldRefresh then
			selectedIndex = newIndex
			backupSelectedIndex = newIndex
			drawUI()
		end
	end
end

function onControllerButtonPress(ctrl)
	if not modEnabled then
		return
	end
	if inspectedContainer then
		local shouldRefresh = pickpocket.scroll(self, inspectedContainer, input)
		local newIndex = selectedIndex
		if ctrl == input.CONTROLLER_BUTTON.DPadDown then
			newIndex = selectedIndex + 1
		elseif ctrl == input.CONTROLLER_BUTTON.DPadUp then
			newIndex = selectedIndex - 1
		end
		if newIndex <= 0 then
			newIndex = math.max(1,#containerItems)
		elseif newIndex > #containerItems then
			newIndex = 1
		end
		if selectedIndex ~= newIndex or shouldRefresh then
			selectedIndex = newIndex
			backupSelectedIndex = newIndex
			drawUI()
		end
	end
end

function lootItem()
	--local function activatedContainer(data)
	--local cont = data[1]
	local cont = inspectedContainer
	--local isAlive = data[2] --isPickpocketing (nil for containers)
	if not modEnabled or not cont then
		return
	end
	local isActor = types.Actor.objectIsInstance(cont)
	local isAlive = isActor and not types.Actor.isDead(cont)  --isPickpocketing (nil for containers)
	--print(inspectedContainer,cont)
	--if inspectedContainer == cont then
	if containerItems[selectedIndex] then
		if isAlive then
			if deposit and pickpocket.version then
				pickpocket.reversePickpocket(self, inspectedContainer, containerItems[selectedIndex])
			else
				pickpocket.stealItem(self, inspectedContainer, containerItems[selectedIndex])
			end
			drawUI()
		else
			if deposit then
				core.sendGlobalEvent("OwnlysQuickLoot_deposit",{self, cont, containerItems[selectedIndex], isAlive, playerSection:get("EXPERIMENTAL_LOOTING")})
			else
				core.sendGlobalEvent("OwnlysQuickLoot_take",{self, cont, containerItems[selectedIndex], isAlive, playerSection:get("EXPERIMENTAL_LOOTING")})
			end
		end
		if not isActor and playerSection:get("CONTAINER_ANIMATION") == "on take" then
			inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
		end
	else
		core.sendGlobalEvent("OwnlysQuickLoot_transferIfEmpty",{self, cont, containerItems[selectedIndex], isAlive, playerSection:get("EXPERIMENTAL_LOOTING")})
	end
	if pickpocket.activate(self, inspectedContainer, input) then
		drawUI()
	end
	--elseif not inspectedContainer and not scriptAllows(cont) then
	--	core.sendGlobalEvent("OwnlysQuickLoot_vanillaActivate",{self, cont, true})
	--end
end
input.registerTriggerHandler('Activate', async:callback(function()
	lootItem()
end))
--end

local function UiModeChanged(data)
	if (data.newMode == "Book" or data.newMode == "Scroll") and data.arg.recordId then
		local now = core.getRealTime()
		currentBook = data.arg.recordId
		if not bookSection:get(currentBook) then
			if data.newMode == "Book" then
				bookSection:set(currentBook, 0)
			else
				bookSection:set(currentBook, 10)
			end
		end
		bookTimer = now
		savegameData.bookSection[data.arg.recordId] = true
	elseif (data.oldMode == "Book" or data.oldMode == "Scroll") and currentBook then
		local now = core.getRealTime()
		local DBentry = bookSection:get(currentBook)
		bookSection:set(currentBook, DBentry + now - bookTimer)
		--print("read for "..(now-bookTimer).." seconds")
	end
	--for a,b in pairs(savegameData.openedScriptedContainers) do
	--	print(a,b)
	--end
	if not modEnabled then
		return
	end
	if data.newMode then
		local now = core.getRealTime()
		if now - showVanillaInventory < 0.2 then
			closeHud()
			showVanillaInventory = 0
		elseif now - mwScriptCalled < 1 then
			--print(scriptContainer.id,I.UI.getMode() == "Container" ,savegameData.openedScriptedContainers[scriptContainer.id])
			if I.UI.getMode() == "Container"  then
				I.UI.setMode()
				currentScript = scriptContainer.type.record(scriptContainer).mwscript
				savegameData.openedScriptedContainers[scriptContainer.id] = true
				core.sendGlobalEvent("OwnlysQuickLoot_openedScriptedContainer", scriptContainer.id)
				
			else
				closeHud()
			end
		else
			closeHud()
		end
	else
	--print(data.arg)
	end
	showInMainMenuOverride = false
end

local function onLoad(data)
	updateModEnabled()
	core.sendGlobalEvent("OwnlysQuickLoot_getCrimesVersion",self)
	if data then
		savegameData = data.savegameData or {}
	else
		savegameData = {}
	end
	if not savegameData.openedScriptedContainers then
		savegameData.openedScriptedContainers = {}
	end
	if not savegameData.bookSection then
		savegameData.bookSection = {}
	end
end

local function onSave()
    return {
        savegameData = savegameData
    }
end

local function receiveCrimesVersion(ver)
	if ver < 2 then
		print("OpenMW version too low, no pickpocket support")
	end
	crimesVersion = ver
end

local function fellForTrap(arg)
	if I.UI.getMode() then
		I.UI.setMode()
	end
end

local function toggle(onOff,uniqueFlag)
	modDisableFlags[uniqueFlag] = onOff
	updateModEnabled()
end

local function windowVisible()
	if inspectedContainer then
		return true
	end
	return false
end

local function playSound(sound)
	ambient.playSound(sound)
end

local function triedScript(cont)

end





return {    
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		--OwnlysQuickLoot_activatedContainer = activatedContainer,
		OwnlysQuickLoot_fellForTrap = fellForTrap,
		OwnlysQuickLoot_windowVisible = windowVisible,
		OwnlysQuickLoot_toggle = toggle, -- toggle(<true/false>, "myModName")
		OwnlysQuickLoot_receiveCrimesVersion = receiveCrimesVersion,
		OwnlysQuickLoot_playSound = playSound,
		--OwnlysQuickLoot_triedScript = triedScript,
	},
	engineHandlers = {
		onFrame = onFrame,
		onUpdate = onUpdate,
		onKeyPress = onKey,
		onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
        onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
    },
	interfaceName = "QuickLoot",
	interface = {
		version = 1,
		lootItem = lootItem,
	}
	--eventHandlers = {
    --    FHB_AI_update = AI_update,
    --}
}