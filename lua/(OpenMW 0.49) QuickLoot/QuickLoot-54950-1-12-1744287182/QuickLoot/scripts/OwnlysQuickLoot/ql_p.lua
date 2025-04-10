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
local Controls = require('openmw.interfaces').Controls
makeBorder = require("scripts.OwnlysQuickLoot.ql_makeborder")
local settings = require("scripts.OwnlysQuickLoot.ql_settings")
local helpers = require("scripts.OwnlysQuickLoot.ql_helpers")
readFont, texText, rgbToHsv, hsvToRgb,fromutf8,toutf8,hextoutf8,formatNumber = unpack(helpers)
background = ui.texture { path = 'black' }
white = ui.texture { path = 'white' }
valueTex = ui.texture { path = 'textures\\QuickLoot_coins.dds' }
valueByWeightTex = ui.texture { path = 'textures\\QuickLoot_scale.dds' }
backpackTex = ui.texture { path = 'textures\\QuickLoot_backpack.dds' }
weightTex = ui.texture { path = 'textures\\QuickLoot_weight.dds' }
fSymbolicTex =   ui.texture { path = 'textures\\QuickLoot_F_symbolic.dds' }
rSymbolicTex =   ui.texture { path = 'textures\\QuickLoot_R_symbolic.dds' }
fKeyTex =   ui.texture { path = 'textures\\QuickLoot_F.dds' }
rKeyTex =   ui.texture { path = 'textures\\QuickLoot_R.dds' }
local handTex = ui.texture { path = 'textures\\QuickLoot_hand.dds' }
local inspectedContainer = nil
local selectedIndex = 1
local backupSelectedIndex = 1
local backupSelectedContainer = nil
local scrollPos = 1
local containerItems = {}
TAKEALL_KEYBINDING = KEY.F
uiLoc = v2(playerSection:get("X")/100,playerSection:get("Y")/100)
uiSize = v2(playerSection:get("WIDTH")/100,playerSection:get("HEIGHT")/100)
local textureCache = {}
local bookSection = storage.playerSection('ReadBooks'..MODNAME)
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
		core.sendGlobalEvent("OwnlysQuickLoot_actuallyActivate",{self, inspectedContainer})
		I.UI.setMode("Container",{target = inspectedContainer})
		types.Actor.setStance(self, types.Actor.STANCE.Nothing)
	end
end))

input.registerTriggerHandler("ToggleWeapon", async:callback(function(dt, use, sneak, run)
	if inspectedContainer then
		core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer, playerSection:get("DISPOSE_CORPSE") == "Shift + F" and input.isShiftPressed()})
	end
end))

input.registerTriggerHandler("Jump", async:callback(function(dt, use, sneak, run)
	if inspectedContainer and playerSection:get("DISPOSE_CORPSE") == "Jump" and types.Actor.objectIsInstance(inspectedContainer) then
		core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer, true})
	end
end)) 





function drawUI()
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
	end
	backupSelectedIndex = selectedIndex
	backupSelectedContainer = inspectedContainer 
	local uiSize = uiSize
	borderFile = "thin"
	if playerSection:get("BORDER_STYLE") == "verythick" or playerSection:get("BORDER_STYLE") == "thick" then
		borderFile = "thick"
	end
	borderOffset = playerSection:get("BORDER_STYLE") == "verythick" and 4 or playerSection:get("BORDER_STYLE") == "thick" and 3 or playerSection:get("BORDER_STYLE") == "normal" and 2 or (playerSection:get("BORDER_STYLE") == "thin" or playerSection:get("BORDER_STYLE") == "max performance") and 1 or 0
	borderTemplate =  makeBorder(borderFile, borderColor or nil, borderOffset).borders
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
	if inspectedContainer.owner.recordId
	or inspectedContainer.owner.factionId and types.NPC.getFactionRank(self, inspectedContainer.owner.factionId) == 0
	or inspectedContainer.owner.factionId and types.NPC.getFactionRank(self, inspectedContainer.owner.factionId) < inspectedContainer.owner.factionRank then
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
	
	table.insert(headline.content,{
		type = ui.TYPE.Text,
		template = quickLootText,
		props = {
			text = ""..localizedName.." ",
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
		template = borderTemplate,
		props = {
			relativeSize  = v2(1,1),
			alpha = 0.5,
		}
	})
	
	local widgets = {} --inverse sorting
	if playerSection:get("COLUMN_WV") then
		table.insert(widgets,"valueByWeight")
	end
	if playerSection:get("COLUMN_VALUE") then
		table.insert(widgets,"value")
	end
	if playerSection:get("COLUMN_WEIGHT") then
		table.insert(widgets,"weight")
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
		table.insert(header.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/menu_thin_border_bottom.dds"),
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,0),
				size = v2(0,1),
				position = v2(0,-1),
				relativePosition = v2(0, 1),
				alpha = 0.4,
			}
		})
		if header_footer_setting == "all top" then
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
	
	

	
	--SORTING
	do
	containerItems = types.Container.inventory(inspectedContainer):getAll()
	local sortedItems = {
		{}, --cash = {},
		{}, --keys = {},
		{}, --lockpicks = {},
		{}, --soulgems = {},
		{}, --ingredients= {},
		{}, --repair = {},
		{}, --worthless = {},
		{}, --other = {}
	}
	for _,item in pairs(containerItems) do
		local itemType = item.type
		local itemRecordId =item.recordId
		local itemRecord = item.type.record(itemRecordId)
		if not itemRecord.name or itemRecord.name == "" or not types.Item.isCarriable(item) then
			-- ignore
		elseif itemType == types.Miscellaneous and itemRecordId == "gold_001" and playerSection:get("CONTAINER_SORTING_CASH") then
			table.insert(sortedItems[1], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Miscellaneous and itemRecord.isKey and playerSection:get("CONTAINER_SORTING_KEYS") then
			table.insert(sortedItems[2], {item, itemRecord.value, itemRecord.weight})
		elseif (itemType == types.Lockpick or itemType == types.Probe) and playerSection:get("CONTAINER_SORTING_LOCKPICKS") then
			table.insert(sortedItems[3], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Miscellaneous and itemRecordId:sub(1,12) == "misc_soulgem" and playerSection:get("CONTAINER_SORTING_SOULGEMS") then
			table.insert(sortedItems[4], {item, itemRecord.value, itemRecord.weight})
		elseif itemType == types.Ingredient and playerSection:get("CONTAINER_SORTING_INGREDIENTS") > 0 then
			if itemRecord.weight <= playerSection:get("CONTAINER_SORTING_INGREDIENTS") then
				table.insert(sortedItems[5], {item, itemRecord.value, itemRecord.weight})
			else
				table.insert(sortedItems[7], {item, itemRecord.value, itemRecord.weight})
			end
		elseif itemType == types.Repair and playerSection:get("CONTAINER_SORTING_REPAIR") then
			table.insert(sortedItems[6], {item, itemRecord.value, itemRecord.weight})
		elseif itemRecord.value == 0 and playerSection:get("CONTAINER_SORTING_WORTHLESS") then
			table.insert(sortedItems[7], {item, itemRecord.value, itemRecord.weight})
		else
			table.insert(sortedItems[8], {item, itemRecord.value, itemRecord.weight})
		end
	end
	containerItems = {}
	for cat, tbl in pairs(sortedItems) do
		if playerSection:get("CONTAINER_SORTING_STATS") ~= "Vanilla" then
			table.sort(tbl, function(a,b)
				if playerSection:get("CONTAINER_SORTING_STATS") == "Lowest Weight" then
					return a[3]<b[3]
				elseif playerSection:get("CONTAINER_SORTING_STATS") == "Highest Value" then
					return a[2]>b[2]
				else --"Best W/V"
					return a[2]/math.max(1,a[3]) > b[2]/math.max(1,b[3])
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
	
	--SCROLLBAR
	local highlightWidth = 1
	selectedIndex = math.min(selectedIndex,#containerItems)
	if selectedIndex >= scrollPos+maxItems-1 then
		scrollPos = math.min(#containerItems-maxItems+1, selectedIndex - maxItems+2)
	elseif selectedIndex <= scrollPos then
		scrollPos = math.max(1,selectedIndex-1)
	end
	scrollPos = math.min(scrollPos, math.max(1,#containerItems+2-maxItems))
	local visibleItems = math.min(maxItems,#containerItems-scrollPos+1)

	if scrollPos > 1 or #containerItems > maxItems then -- show scrollbar?
		highlightWidth = 0.96
		
		-- rounding fix:
		local visibleStart = math.floor((scrollPos-1)/#containerItems*listHeight+0.5)
		local visibleEnd = math.ceil((scrollPos-1+visibleItems)/#containerItems*listHeight)
		local visibleLength = math.min(listHeight, visibleEnd - visibleStart)
		
		local selectedStart = math.floor((selectedIndex-1)/#containerItems*listHeight+0.5)
		local selectedEnd = math.ceil((selectedIndex-1+1)/#containerItems*listHeight)
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
						color = playerSection:get("ICON_TINT"),
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
				)
			end
			local ench = thing and (thing.enchant or thingRecord.enchant ~= "" and thingRecord.enchant )
			if icon then
				if ench then 
					--ENCHANT ICON
					table.insert(list.content, {
						type = ui.TYPE.Image,
						props = {
							resource = getTexture("textures\\menu_icon_magic_mini.dds"),
							tileH = false,
							tileV = false,
							relativePosition = v2(0,relativePosition),
							size = v2(absLineHeight-2,absLineHeight-2),
							position = v2(1,1),
							alpha = 0.7,
						}
					})			
				end
				-- ITEM ICON
				table.insert(list.content, {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(icon),
						tileH = false,
						tileV = false,
						relativePosition = v2(0,relativePosition),
						size = v2(absLineHeight-2,absLineHeight-2),
						anchor = v2(0,0),
						alpha = 0.7,
						position = v2(1,1),
					}
				})
			end
			local readItem = ""
			if not ench and thing.itemRecordId ~="sc_paper plain" and playerSection:get("READ_BOOKS") ~= "off" and thing.type == types.Book then
				if playerSection:get("READ_BOOKS") == "read" then
					readItem = bookSection:get(thing.recordId) and " "..(not playerSection:get("FONT_FIX") and hextoutf8(0xd83d) or "(R)") or ""
				else
					readItem = not bookSection:get(thing.recordId) and " "..(not playerSection:get("FONT_FIX") and hextoutf8(0xd83d) or "(R)") or ""
				end
			end
			if readItem ~= "" then
				table.insert(list.content, {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture("textures/read_indicator.dds"),
						tileH = false,
						tileV = false,
						--relativePosition = v2(0,relativePosition),
						--size = v2(absLineHeight*0.7,absLineHeight*0.7),
						relativePosition = v2(0,relativePosition),
						size = v2(absLineHeight-2,absLineHeight-2),
						anchor = v2(0,0),
						alpha = 0.7,
						position = v2(3,1),
						color = playerSection:get("FONT_TINT"),
					}
				})
				readItem = ""
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
				widgetOffset =widgetOffset+ math.max(0.12,0.105*textSizeMult)
			end
			relativePosition = relativePosition + relLineHeight--
		end
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
		table.insert(footer.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/menu_thin_border_bottom.dds"),
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,0),
				size = v2(0,1),
				position = v2(0,0),
				relativePosition = v2(0, 0),
				alpha = 0.4,
			}
		})
		local encumbranceColor = playerSection:get("FONT_TINT")
		local encumbranceIconColor = playerSection:get("ICON_TINT")
		if encumbranceCurrent > encumbranceMax then
			encumbranceColor = util.color.rgb(0.85,0, 0)
			encumbranceIconColor = util.color.rgb(1,0, 0)
		end
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
		if playerSection:get("FOOTER_HINTS") == "Symbolic" then
			fTex = fSymbolicTex
		    rTex = rSymbolicTex
		end	
			
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
				text = "Take All",
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
		table.insert(root.layout.content,{
			type = ui.TYPE.Text,
			template = quickLootText,
			props = {
				text = "Search",
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
		Camera.enableZoom("quickloot")
		containerHash = 99999999
		if root then 
			root:destroy() 
		end
		if tooltip then
			tooltip:destroy()
		end
	end
end

function stahlrimCheck(cont)
	if not (cont.recordId:find("contain_bm_stalhrim")) then
		return true
	end
	playerItems = types.Container.inventory(self):getAll()
	for a,b in pairs(playerItems) do
		if b.recordId == "bm nordic pick" then
			return true
		end
	end
	return false
end


function onFrame(dt)
	if inspectedContainer and  core.contentFiles.has("QuickSpellCast.omwscripts")  and types.Actor.getStance(self) == types.Actor.STANCE.Spell then
		types.Actor.setStance(self, types.Actor.STANCE.Nothing)
	end
 --self.controls.use = 0
	if not modEnabled then
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
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
	if (telekinesis) then
		activationDistance = activationDistance + (telekinesis.magnitude * 22);
	end
	activationDistance = activationDistance+0.1
	local res = nearby.castRenderingRay(
		cameraPos,
		cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
		{ ignore = self }
	)
	
	if inspectedContainer and (res.hitObject == nil or res.hitObject ~= inspectedContainer) then
		closeHud()
	elseif inspectedContainer and types.Actor.getEncumbrance(self) ~= encumbranceCurrent then
		drawUI()
	end
	
	if not inspectedContainer 
	and res.hitObject 
	and (
			res.hitObject.type == types.Container
			and (not types.Container.record(res.hitObject).isOrganic or organicContainers[res.hitObject.recordId])
		or ((
				res.hitObject.type == types.NPC
				or res.hitObject.type == types.Creature
			)
			and types.Actor.isDead(res.hitObject)
		)
	)	
	and not types.Lockable.isLocked(res.hitObject)
	and not types.Lockable.getTrapSpell(res.hitObject)
	and stahlrimCheck(res.hitObject)
	then
		if not types.Container.inventory(res.hitObject):isResolved() then
			core.sendGlobalEvent("OwnlysQuickLoot_resolve",res.hitObject)
		else
			inspectedContainer = res.hitObject
			self.controls.use = 0
			Controls.overrideCombatControls(true)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false) 
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
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
		for _, thing in pairs(types.Container.inventory(inspectedContainer):getAll()) do
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
	--	core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer})
	--end
	--return false
end
local function onMouseWheel(vertical)
	if not modEnabled then
		return
	end
	--print(vertical)
	if inspectedContainer then
		--local newIndex = math.min(#containerItems,math.max(1,selectedIndex - vertical))
		local newIndex = selectedIndex - vertical
		if newIndex == 0 then
			newIndex = #containerItems
		elseif newIndex > #containerItems then
			newIndex = 1
		end
		if selectedIndex ~= newIndex then
			selectedIndex = newIndex
			backupSelectedIndex = newIndex
			drawUI()
		end
	end
end

function onControllerButtonPress (ctrl)
	if not modEnabled then
		return
	end
	if inspectedContainer then
		local newIndex = selectedIndex
		if ctrl == input.CONTROLLER_BUTTON.DPadDown then
			newIndex = selectedIndex + 1
		elseif ctrl == input.CONTROLLER_BUTTON.DPadUp then
			newIndex = selectedIndex - 1
		end
		if newIndex == 0 then
			newIndex = #containerItems
		elseif newIndex > #containerItems then
			newIndex = 1
		end
		if selectedIndex ~= newIndex then
			selectedIndex = newIndex
			backupSelectedIndex = newIndex
			drawUI()
		end
	end
end


local function activatedContainer(cont)
	if not modEnabled then
		return
	end
	--print(inspectedContainer,cont)
	if inspectedContainer == cont then
		if containerItems[selectedIndex] then
			core.sendGlobalEvent("OwnlysQuickLoot_take",{self, cont, containerItems[selectedIndex]})
			if playerSection:get("CONTAINER_ANIMATION") == "on take" then
				inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
			end
		end
	end
end

local function UiModeChanged(data)
	if data.newMode == "Book" or data.newMode == "Scroll" then
		--print(data.oldMode,data.newMode, data.arg.recordId)
		--local readBooks = bookSection:get("ReadBooks") 
		--readBooks = shallowcopy(readBooks)
		--bookSection:get("ReadBooks")
		--readBooks[data.arg.recordId] = true
		bookSection:set(data.arg.recordId, true)
	end
	if not modEnabled then
		return
	end
	if data.newMode then
		closeHud()
	else
	--print(data.arg)
	end
	showInMainMenuOverride = false
end
local function onLoad()
updateModEnabled()
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



return {    
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		OwnlysQuickLoot_activatedContainer = activatedContainer,
		OwnlysQuickLoot_fellForTrap = fellForTrap,
		OwnlysQuickLoot_windowVisible = windowVisible,
		OwnlysQuickLoot_toggle = toggle, -- toggle(<true/false>, "myModName")
	},
	engineHandlers = {
		onFrame = onFrame,
		onUpdate = onUpdate,
		onKeyPress = onKey,
		onMouseWheel = onMouseWheel,
		onLoad = onLoad,
		onControllerButtonPress = onControllerButtonPress,
    },
	--eventHandlers = {
    --    FHB_AI_update = AI_update,
    --}
}