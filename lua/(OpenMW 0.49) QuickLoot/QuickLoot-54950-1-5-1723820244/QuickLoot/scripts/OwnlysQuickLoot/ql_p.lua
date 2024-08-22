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
local makeBorder = require("scripts.OwnlysQuickLoot.ql_makeborder")
local settings = require("scripts.OwnlysQuickLoot.ql_settings")
local helpers = require("scripts.OwnlysQuickLoot.ql_helpers")
readFont, texText, rgbToHsv, hsvToRgb,fromutf8,toutf8,hextoutf8 = unpack(helpers)
local background = ui.texture { path = 'black' }
local white = ui.texture { path = 'white' }
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
local lastItemCount = 99999999
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

local itemFontSize = 21



local function getTexture(path)
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
		core.sendGlobalEvent("OwnlysQuickLoot_takeAll",{self, inspectedContainer})
	end
end)) 

function drawUI()
	
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
	if hud then 
		hud:destroy()
	end
	local localizedName = inspectedContainer.type.records[inspectedContainer.recordId].name
	
	hud = ui.create({	--root
		type = ui.TYPE.Widget,
		layer = 'HUD',
		name = 'QuickLootBox',
		props = {
			--position = playerSection:get("POSITION") == "Bottom Left" and v2(94,-startOffset) or v2(startOffset,startOffset),
			--size = v2(0.2,0.2),
			anchor = v2(0.5,0.5), --playerSection:get("POSITION") == "Bottom Left" and v2(0,1) or v2(0,0),
			relativePosition = uiLoc, --playerSection:get("POSITION") == "Bottom Left" and v2(0,1) or v2(0,0),
			relativeSize =  uiSize,
		},
		content = ui.content {
			--{ --background
			--	type = ui.TYPE.Image,
			--	props = {
			--		resource = background,
			--		tileH = false,
			--		tileV = false,
			--		relativeSize  = v2(1,1),
			--		relativePosition = v2(0,0),
			--		--position = v2(1,1),
			--		--size = v2(-2,-2),
			--		alpha = 0.3,
			--	}
			--}
		}
	})
	local screenAspectRatio = ui.screenSize()
	local textSizeMult = screenAspectRatio.y /1200*(uiSize.y/0.4)
	local headerFooterScale = (textSizeMult^0.5)/textSizeMult
	textSizeMult = textSizeMult^0.5
	textSizeMult=textSizeMult*playerSection:get("textSizeMult")/100
	headerFooterScale = headerFooterScale*playerSection:get("textSizeMult")/100
	screenAspectRatio = screenAspectRatio.x/screenAspectRatio.y
	uiSize= v2(uiSize.x*screenAspectRatio, uiSize.y)
	local hudAspectRatio = uiSize.x/uiSize.y
	local hudLayerSize = ui.layers[ui.layers.indexOf("HUD")].size
	
	local headerFooterMargin = 0.005
	local headerFooterHeight = 0.06*headerFooterScale
	local captionOffset = 0

	

	local stealCol = nil
	if inspectedContainer.owner.recordId
	or inspectedContainer.owner.factionId and types.NPC.getFactionRank(self, inspectedContainer.owner.factionId) == 0
	or inspectedContainer.owner.factionId and types.NPC.getFactionRank(self, inspectedContainer.owner.factionId) < inspectedContainer.owner.factionRank then
		--stealCol = util.color.rgba(1,0.714, 0.706, 1)
		stealCol = util.color.rgba(1,0.05, 0.05, 1)
		--STEALING ICON
		--captionOffset = headerFooterHeight/hudAspectRatio
		
	end
	--Caption: CONTAINER NAME
	local headline ={
		type = ui.TYPE.Flex,
		props = {
			position = v2(0, 0),
			relativeSize  = v2(1,headerFooterHeight),
			relativePosition = v2(0 + captionOffset, 0),
			anchor = v2(0,0),
			horizontal = true,
		},
		content = ui.content({})
	}
	table.insert(hud.layout.content,headline)
	
	table.insert(headline.content,{
		type = ui.TYPE.Text,
		template = quickLootText,
		props = {
			text = localizedName.." ",
			textSize= 25*textSizeMult,
			position = v2(0, 0),
			relativeSize  = v2(1,headerFooterHeight),
			relativePosition = v2(0.015 + captionOffset, headerFooterHeight/2),
			anchor = v2(0,0.5),
			textColor = stealCol or playerSection:get("ICON_TINT"),
		}
	})
	
	

	if stealCol then
		table.insert(headline.content,{
			type = ui.TYPE.Image,
			props = {
				resource = handTex,
				tileH = false,
				tileV = false,
				position = v2(0, 0),
				--relativeSize  = v2(1,1),
				size = v2(hudLayerSize.y*uiSize.y*headerFooterHeight*0.9,hudLayerSize.y*uiSize.y*headerFooterHeight*0.9),
				alpha = 0.8,
			}
		})
	end


	--itemHUD
	local itemHud = { -- r.1.7
		type = ui.TYPE.Widget,
		props = {
			relativeSize  = v2(1,1-2*(headerFooterHeight+headerFooterMargin)),
			relativePosition = v2(0,headerFooterHeight+headerFooterMargin),
		},
		content = ui.content {}
	}
	table.insert(hud.layout.content, itemHud)
	
	--itemHUD BACKGROUND
	table.insert(itemHud.content, {
		type = ui.TYPE.Image,
		props = {
			resource = background,
			tileH = false,
			tileV = false,
			relativeSize  = v2(1,1),
			relativePosition = v2(0,0),
			alpha = 0.3,
		}
	})
	--itemHUD BORDER
	table.insert(itemHud.content, {
		template = borderTemplate,
		props = {
			relativeSize  = v2(1,1),
			alpha = 0.5,
		}
	})
	local boxDimensions = v2(uiSize.x,uiSize.y*(1-2*(headerFooterHeight+headerFooterMargin)))
	local entryWidth = 0.7--1-(1.5*lineHeight + 0.01)
	local itemBoxHeaderFooterHeight = 0.08*headerFooterScale
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
	--local textDimensions = v2(uiSize.x*entryWidth,uiSize.y*(1-2*(headerFooterHeight+headerFooterMargin)))
	
	local localListDimensions = v2(1,1-(#widgets>0 and 2 or 1)*(itemBoxHeaderFooterHeight+0.001))
	--local listBoxDimensions = v2(boxDimensions.x,#widgets >1 and boxDimensions.y*(1-2*(itemBoxHeaderFooterHeight+0.003)+margin) or boxDimensions.y*(1-itemBoxHeaderFooterHeight-0.003+margin))
	local realListBoxDimensions = v2(boxDimensions.x,boxDimensions.y*localListDimensions.y) --only for line max items
	local absoluteRealListBoxDimensions = realListBoxDimensions:emul(v2(hudLayerSize.x/screenAspectRatio,hudLayerSize.y))
	local margin = 0.01 --0.001 margin before and after list
	local maxItems = math.floor(absoluteRealListBoxDimensions.y / (itemFontSize*textSizeMult*1.5+margin*absoluteRealListBoxDimensions.y))--pctOfListHeightPerEntry / realListBoxDimensions.y --math.floor(realListBoxDimensions.y/(0.021))--math.floor(14*(boxDimensions.y/0.4))
	local pctOfListHeightPerEntry = localListDimensions.y / maxItems --absoluteRealListBoxDimensions.y / (itemFontSize*textSizeMult+margin)
	local itemHudAspectRatio = boxDimensions.x/boxDimensions.y 
	local lineHeight = localListDimensions.y/maxItems
	lineHeight = lineHeight - margin +1/maxItems*margin--/2
	local relativePosition = 0
	local itemNameX = lineHeight/itemHudAspectRatio + 0.02
	
	
	--itemList HEADER
	if #widgets > 0 then
		--itemList HEADER Background
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,itemBoxHeaderFooterHeight),
				size = v2(-borderOffset*2,-borderOffset),
				position = v2(borderOffset,borderOffset),
				relativePosition = v2(0, 0),
				alpha = 0.4,
			}
		})
		--itemList HEADER Line
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/menu_thin_border_bottom.dds"),
				tileH = false,
				tileV = false,
				relativeSize  = v2(1,0),
				size = v2(-borderOffset*2,1),
				position = v2(borderOffset,-1),
				relativePosition = v2(0, itemBoxHeaderFooterHeight),
				alpha = 0.4,
			}
		})
		relativePosition = relativePosition + itemBoxHeaderFooterHeight+0.001
		local widgetOffset = 0.05 -- for scrollbar
		--itemList HEADER ICONS
		for _, widget in pairs(widgets) do
			table.insert(itemHud.content,{
				type = ui.TYPE.Image,
				props = {
					resource = _G[widget.."Tex"],
					tileH = false,
					tileV = false,
					relativeSize  = v2(0.85*itemBoxHeaderFooterHeight/itemHudAspectRatio,0.85*itemBoxHeaderFooterHeight),
					relativePosition = v2(1-widgetOffset, itemBoxHeaderFooterHeight),
					position = v2(0,-2),
					anchor = v2(1,1),
					alpha = 0.8,
					color = playerSection:get("ICON_TINT"),
				}
			})
			widgetOffset =widgetOffset+ math.max(0.12,0.105*textSizeMult)--itemBoxHeaderFooterHeight*headerFooterScale
		end
	else
		relativePosition = relativePosition+borderOffset/absoluteRealListBoxDimensions.y
	end
	
	
	--SORTING
	containerItems = types.Container.inventory(inspectedContainer):getAll()
	local sortedItems = {
		{}, --cash = {},
		{}, --keys = {},
		{}, --lockpicks = {},
		{}, --soulgems = {},
		{}, --ingredients= {},
		{}, --repair = {},
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
		else
			table.insert(sortedItems[7], {item, itemRecord.value, itemRecord.weight})
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
					return a[2]/a[3] > b[2]/b[3]
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
	
	--SCROLLBAR
	local highlightWidth = 1
	local highlightWidthAbs = -borderOffset*2
	--local listLimit = 1-itemBoxHeaderFooterHeight
	local scrollBarRange = localListDimensions.y --listLimit-relativePosition
	selectedIndex = math.min(selectedIndex,#containerItems)
	--print(selectedIndex)
	--if 
	if selectedIndex >= scrollPos+maxItems-1 then
		scrollPos = math.min(#containerItems-maxItems+1, selectedIndex - maxItems+2)
	elseif selectedIndex <= scrollPos then
		scrollPos = math.max(1,selectedIndex-1)
	end
	scrollPos = math.min(scrollPos, math.max(1,#containerItems+2-maxItems))
	local visibleItems = math.min(maxItems,#containerItems-scrollPos+1)
	--if #containerItems > maxItems then
	if scrollPos > 1 or #containerItems > maxItems then
		highlightWidth = 0.96
		highlightWidthAbs = -borderOffset
		--SCROLLBAR BACKGROUND
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = background,
				tileH = false,
				tileV = false,
				relativePosition = v2(0.96,relativePosition),
				relativeSize  = v2(0.04,scrollBarRange),
				size = v2(-borderOffset,0),
				alpha = 0.2,
				color = playerSection:get("FONT_TINT"),
			}
		})
		--SCROLLBAR VISIBLE RANGE
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = white,
				tileH = false,
				tileV = false,
				relativePosition = v2(0.96,(scrollPos-1)/#containerItems*scrollBarRange+relativePosition),
				relativeSize  = v2(0.04,visibleItems/#containerItems*scrollBarRange),
				size = v2(-borderOffset,0),
				alpha = 0.15,
				color = playerSection:get("ICON_TINT"),
				
			}
		})
		--SCROLLBAR SELECTED
		table.insert(itemHud.content,
		{
			type = ui.TYPE.Image,
			props = {
				resource = white,
				tileH = false,
				tileV = false,
				relativePosition = v2(0.96,(selectedIndex-1)/#containerItems*scrollBarRange+relativePosition),
				relativeSize  = v2(0.04,1/#containerItems*scrollBarRange),
				size = v2(-borderOffset,0),
				alpha = 0.5,
				color = playerSection:get("ICON_TINT"),
			}
		})
	end
	encumbranceCurrent = types.Actor.getEncumbrance(self)
	local encumbranceMax = types.Actor.stats.attributes.strength(self).modified*core.getGMST("fEncumbranceStrMult")
	
	--for _, thing in pairs(types.Container.inventory(inspectedContainer):getAll()) do
	-- ITEMS
	local renderedEntries = 0
	for i, thing in pairs(containerItems) do
		local thingRecord = thing.type.records[thing.recordId]
		if not thingRecord then
			ui.showMessage("ERROR: no record for "..thing.id.." (please report this bug)")
		elseif i >=scrollPos and renderedEntries < maxItems then
			renderedEntries = renderedEntries + 1
			local thingName =  thingRecord.name or thing.id
			--thingName= fromutf8(thingName)
			--print(thingName)
			local icon = thingRecord.icon
			local thingCount = thing.count or 1
			local countText = thingCount > 1 and " ("..thing.count..")" or ""
			if i == selectedIndex then
				-- SELECTION HIGHLIGHT
				table.insert(itemHud.content, {
					type = ui.TYPE.Image,
					props = {
						resource = white,
						tileH = false,
						tileV = false,
						relativeSize  = v2(highlightWidth,lineHeight),--+margin/2),
						relativePosition = v2(0,relativePosition),
						position = v2(borderOffset,0),
						--size = v2(-2,-2),
						size = v2(highlightWidthAbs,0),
						alpha = 0.3,
						color = playerSection:get("ICON_TINT"),
					}
				})
			end
			local ench = thing and (thing.enchant or thingRecord.enchant ~= "" and thingRecord.enchant )
			if icon then
				if ench then 
					--ENCHANT ICON
					table.insert(itemHud.content, {
						type = ui.TYPE.Image,
						props = {
							resource = getTexture("textures\\menu_icon_magic_mini.dds"),
							tileH = false,
							tileV = false,
							relativeSize  = v2(lineHeight/itemHudAspectRatio,lineHeight),
							relativePosition = v2(0.01,relativePosition),
							--position = v2(1,1),
							--size = v2(-2,-2),
							alpha = 0.7,
						}
					})			
				end
				-- ITEM ICON
				table.insert(itemHud.content, {
					type = ui.TYPE.Image,
					props = {
						resource = getTexture(icon),
						tileH = false,
						tileV = false,
						relativeSize  = v2(lineHeight/itemHudAspectRatio,lineHeight),
						relativePosition = v2(0.01,relativePosition+lineHeight),
						anchor = v2(0,1),
						alpha = 0.7,
					}
				})
			end
			
			local readItem = ""
			if not ench and thing.itemRecordId ~="sc_paper plain" and playerSection:get("READ_BOOKS") ~= "off" and thing.type == types.Book then
				if playerSection:get("READ_BOOKS") == "read" then
					readItem = bookSection:get(thing.recordId) and " "..(not playerSection:get("FONT_FIX") and hextoutf8(0xd83d) or "") or ""
				else
					readItem = not bookSection:get(thing.recordId) and " "..(not playerSection:get("FONT_FIX") and hextoutf8(0xd83d) or "") or ""
				end
			end
			-- ITEM NAME + COUNT
			table.insert(itemHud.content, { 
				type = ui.TYPE.Text,
				template = quickLootText,
				props = {
					text = ""..thingName..countText..readItem,--..hextoutf8(0xd83d)..hextoutf8(0xd83e),--thingName..countText,
					textSize = itemFontSize*textSizeMult,--itemFontSize*textSizeMult,
					
					relativeSize  = v2(entryWidth,lineHeight),
					relativePosition = v2(itemNameX, relativePosition+lineHeight/2),
					anchor = v2(0,0.5),
				},
				})
			local widgetOffset = 0.05 --scrollbar
			local thingValue = thingRecord.value
			local thingWeight = thingRecord.weight
			for _, widget in pairs(widgets) do
				local text = math.floor(thingValue*10)/10
				local textColor = nil
				if widget == "valueByWeight" then
					text = (math.floor(thingValue/thingWeight*10+0.5)/10)
				elseif widget == "weight" then
					text = math.floor(thingWeight*10+0.5)/10
					if thingWeight+encumbranceCurrent > encumbranceMax then
						textColor = util.color.rgb(0.85,0, 0)
					end
				end
				if text >99 or text > 1.2 and (text%1 <=0.1 or text%1 >=0.9) then
					text = math.floor(text)
				end
				
				if text == 1/0 then
					if not playerSection:get("FONT_FIX") then
						text = hextoutf8(0x221e)
					end
				elseif text >= 10^6-100 then --1m
					text = text/1000--*1.005/1000
					local e = math.floor(math.log10(text))
					text = text + 10^e*1.005-10^e
					local suffixes = {"K","M","G","T","P","E","Z"}
					local i = 1
					while text >= 1000 do
						text = text/1000
						i=i+1
					end
					--text = string.format("%.2f",text)
					text = math.floor(text*100)/100 -- control rounding instead of string format
					text = string.format("%.2f",text)
					if #text == 6 then
						text=text:sub(1,3)
					else
						text = text:sub(1,4)
					end
					text = text.." "..suffixes[i]
				elseif text >= 1000 then
					text = math.floor(text/1000)..(playerSection:get("FONT_FIX") and hextoutf8(0x200a)..hextoutf8(0x200a) or "")..string.format("%.3f",math.floor((text%1000)/1000)):sub(3)
				end
				text = ""..text
				
				local tempSize = v2(1.1*itemBoxHeaderFooterHeight,lineHeight)
				table.insert(itemHud.content, {
					type = ui.TYPE.Text,
					template = quickLootText,
					props = {
						text = text,
						textSize = itemFontSize*textSizeMult,
						relativeSize  = tempSize,
						relativePosition = v2(1-widgetOffset, relativePosition+lineHeight/2),
						anchor = v2(1,0.5),
						textColor = textColor,
					},
				})
				widgetOffset =widgetOffset+ math.max(0.12,0.105*textSizeMult)
			end
			relativePosition = relativePosition + lineHeight+margin
		end
		
	end
	--itemList FOOTER Line
	table.insert(itemHud.content,
	{
		type = ui.TYPE.Image,
		props = {
			resource = getTexture("textures/menu_thin_border_bottom.dds"),
			tileH = false,
			tileV = false,
			relativeSize  = v2(1,0),
			size = v2(-borderOffset*2,1),
			position = v2(borderOffset,0),
			relativePosition = v2(0, 1-itemBoxHeaderFooterHeight),
			alpha = 0.4,
		}
	})
	--itemList FOOTER Background
	table.insert(itemHud.content,
	{
		type = ui.TYPE.Image,
		props = {
			resource = background,
			tileH = false,
			tileV = false,
			relativeSize  = v2(1,itemBoxHeaderFooterHeight),
			size = v2(-borderOffset*2,-borderOffset-1),
			position = v2(borderOffset,1),
			relativePosition = v2(0, 1-itemBoxHeaderFooterHeight),
			alpha = 0.4,
		}
	})
	
	local encumbranceColor = playerSection:get("FONT_TINT")
	local encumbranceIconColor = playerSection:get("ICON_TINT")
	if encumbranceCurrent > encumbranceMax then
		encumbranceColor = util.color.rgb(0.85,0, 0)
		encumbranceIconColor = util.color.rgb(1,0, 0)
	end
	--itemList Footer ENCUMBRANCE ICON
	table.insert(itemHud.content,{
		type = ui.TYPE.Image,
		props = {
			resource = backpackTex,
			tileH = false,
			tileV = false,
			relativeSize  = v2(itemBoxHeaderFooterHeight*1.05/itemHudAspectRatio,itemBoxHeaderFooterHeight*1.0), --1.05 stretch
			relativePosition = v2(1-0.005, 1-itemBoxHeaderFooterHeight/2),
			position = v2(0,0),
			anchor = v2(0,0),
			alpha = 0.5,
			anchor = v2(1,0.5),
			color = encumbranceIconColor,
		}
	})
	
	--itemList Footer ENCUMBRANCE TEXT
	table.insert(itemHud.content,{
		type = ui.TYPE.Text,
		template = quickLootText,
		props = {
			text = ""..math.floor(encumbranceCurrent+0.5).. "/"..math.floor(encumbranceMax+0.5),
			textSize= 20*textSizeMult,
			position = v2(0, 0),
			relativeSize  = v2(1,itemBoxHeaderFooterHeight),
			relativePosition = v2(0.985-itemBoxHeaderFooterHeight*1.05/itemHudAspectRatio, 1-itemBoxHeaderFooterHeight/2),
			anchor = v2(1,0.5),
			textColor = encumbranceColor,
		},
	})
	
	
	if playerSection:get("FOOTER_HINTS") ~= "Disabled" then
		local fTex = fKeyTex
		local rTex = rKeyTex
		if playerSection:get("FOOTER_HINTS") == "Symbolic" then
			fTex = fSymbolicTex
		    rTex = rSymbolicTex
		end	
			
		--SUB-FOOTER ICON Right
		table.insert(hud.layout.content,{
			type = ui.TYPE.Image,
			props = {
				resource = fTex,
				tileH = false,
				tileV = false,
				relativeSize  = v2(headerFooterHeight*0.8/(uiSize.x/uiSize.y),headerFooterHeight*0.8),
				relativePosition = v2(0.505,1-headerFooterHeight/2),
				anchor = v2(0,0.5),
				alpha = 0.6,
				color = playerSection:get("ICON_TINT"),
				
			}
		})
		--SUB-FOOTER TEXT Right
		table.insert(hud.layout.content,{
			type = ui.TYPE.Text,
			template = quickLootText,
			props = {
				text = "Take All",
				textSize= 20*textSizeMult,
				position = v2(0, 0),
				relativeSize  = v2(1,headerFooterHeight),
				relativePosition = v2(0.508+headerFooterHeight*0.8/(uiSize.x/uiSize.y),1-headerFooterHeight/2+0.0015),
				textColor = playerSection:get("ICON_TINT"),
				anchor = v2(0,0.5),
			},	})
		
		--SUB-FOOTER ICON Left
		table.insert(hud.layout.content,{
			type = ui.TYPE.Image,
			props = {
				resource = rTex,
				tileH = false,
				tileV = false,
				relativeSize  = v2(headerFooterHeight*0.8/(uiSize.x/uiSize.y),headerFooterHeight*0.8),
				relativePosition = v2(0.495,1-headerFooterHeight/2),
				anchor = v2(1,0.5),
				alpha = 0.6,
				color = playerSection:get("ICON_TINT"),
			}
		})
		--SUB-FOOTER TEXT Left
		table.insert(hud.layout.content,{
			type = ui.TYPE.Text,
			template = quickLootText,
			props = {
				text = "Search",
				textSize= 20*textSizeMult,
				textAlignH = ui.ALIGNMENT.End,
				relativeSize  = v2(1,headerFooterHeight),
				relativePosition = v2(0.493-headerFooterHeight*0.8/(uiSize.x/uiSize.y),1-headerFooterHeight/2+0.0015),
				anchor = v2(1,0.5),
				textColor = playerSection:get("ICON_TINT"),
			},})
	end
	--hud:update()
	
end

function closeHud()
	if inspectedContainer then
		inspectedContainer:sendEvent("OwnlysQuickLoot_closeAnimation",self)
		inspectedContainer = nil
		Controls.overrideCombatControls(false)
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, true) 
		types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, true)
		Camera.enableZoom("quickloot")
		lastItemCount = 99999999
		if hud then 
			hud:destroy() 
		end
	end
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
	then
		if not types.Container.inventory(res.hitObject):isResolved() then
			core.sendGlobalEvent("OwnlysQuickLoot_resolve",res.hitObject)
		else
			inspectedContainer = res.hitObject
			Controls.overrideCombatControls(true)
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, false) 
			types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, false)
			Camera.disableZoom("quickloot")
			if playerSection:get("CONTAINER_ANIMATION") == "immediately" or playerSection:get("CONTAINER_ANIMATION") == "disabled by shift" and not input.isShiftPressed() then
				inspectedContainer:sendEvent("OwnlysQuickLoot_openAnimation",self)
			end
			selectedIndex = 1
		end
	end
	if inspectedContainer then
		local itemCount = 0
		local entryCount = 0
		for _, thing in pairs(types.Container.inventory(inspectedContainer):getAll()) do
			itemCount = itemCount + thing.count
			entryCount = entryCount + 1
		end
		if entryCount < selectedIndex then
			selectedIndex = entryCount
		end
		
		
		if lastItemCount ~= itemCount then
			drawUI()
		end
		
		lastItemCount = itemCount
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