
local GUI_ID_TooltipIconBar				= tes3ui.registerID("UIEXP_Tooltip_IconBar")
local GUI_ID_TooltipIconGoldBlock		= tes3ui.registerID("UIEXP_Tooltip_IconGoldBlock")
local GUI_ID_TooltipIconWeightBlock		= tes3ui.registerID("UIEXP_Tooltip_IconWeightBlock")
local GUI_ID_TooltipExtraDivider		= tes3ui.registerID("UIEXP_Tooltip_ExtraDivider")
local GUI_ID_TooltipIconGoldWeightBlock	= tes3ui.registerID("UIEXP_Tooltip_IconGoldWeightBlock")
local GUI_ID_TooltipStackCountBlock		= tes3ui.registerID("UIEXP_Tooltip_StackCountBlock")
local GUI_ID_MenuBarter 				= tes3ui.registerID("MenuBarter")
local GUI_ID_MenuContents 				= tes3ui.registerID("MenuContents")
local GUI_ID_MenuBarter_count			= tes3ui.registerID("MenuBarter_count")

local common = require("Units and Vagueness.common")

----------------------------------------------------------------------------------------------------
-- Tooltip: Item Units and Vagueness, Gold Display, and Gold/Weight Ratio
----------------------------------------------------------------------------------------------------

local function tryHideID(tooltip, uiid)
	local element = tooltip:findChild(tes3ui.registerID(uiid))
	if element ~= nil then
		element.visible = false
		return true
	end
	return false
end


--local hoverCount = nil
--[[local hoverTileData = nil

-- for content and barter tooltips, we need to get the size of stacks before the tooltip
local function onTileHover(e)
	--hoverCount = nil
    hoverTileData = nil

    hoverTileData = e.source:getPropertyObject("MenuContents_Thing", "tes3inventoryTile")
    if hoverTileData == nil then
    	hoverTileData = e.source:getPropertyObject("MenuBarter_Thing", "tes3inventoryTile")
	end

	-- the following is not being called consistently, because offered items are somehow not properly updated
	--[[local isOffered = e.source.contentPath:find("icon_barter") ~= nil
	if countElement ~= nil and isOffered then
		local countElement = e.source:findChild(GUI_ID_MenuBarter_count)
		hoverCount = tonumber(countElement.text)
		--tes3.messageBox({ message = "[Units and Vagueness] onTileHover ??? "..hoverCount })
		mwse.log(string.format( "??? isOffered ? -> "..hoverCount ))
	end]]
--[[
    e.source:forwardEvent(e)
end]]


--[[
event.register("itemTileUpdated", function (e)
    e.element:register("help", onTileHover)
end, { filter = "MenuContents" })

event.register("itemTileUpdated", function (e)
    e.element:register("help", onTileHover)
end, { filter = "MenuBarter" })
]]


-- doesn't work either. maybe offered item tiles are not included in barter tiles being updated?
--[[local function onInventoryTileClicked(e)
	local menuBarter = tes3ui.findMenu(GUI_ID_MenuBarter)
	if menuBarter ~= nil then
		tes3.messageBox({ message = "clicked InventoryTile, triggering menuBarter update" })
		menuBarter:triggerEvent("update")
		--tes3ui.updateBarterMenuTiles()
		--tes3.messageBox({ message = "updateBarterMenuTiles" })
	end
    e.source:forwardEvent(e)
end
event.register("itemTileUpdated", function (e)
	local menuBarter = tes3ui.findMenu(GUI_ID_MenuBarter)
	if menuBarter ~= nil then
    	e.element:register("mouseClick", onInventoryTileClicked)
    end
end, { filter = "MenuInventory" })
]]

local itemValues
local function OnLoaded()
	-- mwse.log('OnLoaded');
	if common.config.useSoldItemValues then
		if not tes3.player.data.soldItemValues then
			tes3.player.data.soldItemValues = {}
		end
		itemValues = tes3.player.data.soldItemValues
	end
end
event.register("loaded", OnLoaded);

function calcBarterPrice(e)
	if common.config.useSoldItemValues then
		-- if buying, remember the price
		-- it's not unreasonable for PC to assume a higher price after buying
		-- compared to selling, where you must assume you're getting ripped off
		if e.buying then
			if not itemValues[e.item.id] then
				itemValues[e.item.id] = e.price

			-- the prices usually get better over time
			-- if an offer isn't as good as the last one, we will skip it
			elseif itemValues[e.item.id] < e.price then
				itemValues[e.item.id] = e.price
			end
			--tes3.messageBox({ message = e.item.name })
		
		-- if selling and no known value yet
		--elseif not itemValues[e.item.id] then
			--itemValues[e.item.id] = e.price
		end
	end
end
event.register('calcBarterPrice', calcBarterPrice)






local useMCPSoulgemValueRebalance = tes3.hasCodePatchFeature(65)
-- the actual tooltip replacement
local function extraTooltipEarly(e)

	-- add padding; less padding on top looks more even
	e.tooltip:getContentElement().children[1].borderAllSides = 3
	e.tooltip:getContentElement().children[1].borderTop = 2

	-- compared to UI Expansion, this does include keys and gold: 
	-- because there is at least one key in main quest with weight of 5.0
	-- and there are mods that make gold weigh something

	tryHideID(e.tooltip, "HelpMenu_value")
	tryHideID(e.tooltip, "HelpMenu_weight")
	
	local gold = e.object.value
	local weight = e.object.weight

	--stack count for calculating added weight
	local stackCount = 1
	local stackCountString = string.format("")

	-- get stack size
	if common.config.summarizeStacks > 0 then
		-- world object (reference)
		if e.reference ~= nil then
			if e.reference.stackSize > stackCount then
				stackCount = e.reference.stackSize
			end
			
		-- content or barter tile
		-- this will only work if the tiles are updated, which isn't always the case for offered items in barterMenu
		-- also accessing the hoverTileData.item will somehow cause CTDs on some items
		-- therefore barter and contents menu tile tooltips won't be supported
		--[[elseif e.count == 0 then
			--mwse.log(string.format( ">><< "..e.object.name.." "..e.count ));

			--
			if hoverTileData ~= nil then
				if hoverTileData.item ~= nil then
					--mwse.log(string.format( "---- "..hoverTileData.item.name.." "..e.count ));

					if hoverTileData.item.id == e.object.id then
						stackCount = hoverTileData.count
					end
					--[[if hoverCount ~= nil then
						stackCount = hoverCount
						--mwse.log(string.format( "//// "..hoverTileData.item.name.." "..stackCount ));
					else
						stackCount = hoverTileData.count
						--mwse.log(string.format( "---- "..hoverTileData.item.name.." "..hoverTileData.count ));
					end]]
			--[[
				end
			end]]
		
		-- inventory tile
		elseif e.count > 1 then
			stackCount = e.count
		end

		-- apply only if more than 1
		if stackCount > 1 then
			stackCountString = string.format("(%s)", stackCount)
			weight = e.object.weight * stackCount

			if common.config.summarizeStacks == 2 then
				gold = e.object.value * stackCount
			end
		end
	end

	-- determine if gold shall be shown
	local displayGold = false
	if gold ~= nil then
		local menuBarter = tes3ui.findMenu(GUI_ID_MenuBarter)
		-- if more than 0 or 20 respectively
		if (not common.config.hidePettyItemValues and gold > 0) or (menuBarter ~= nil and gold > 0) or gold >= 20 then
			displayGold = true
		end
	end

	-- determine if weight shall be shown
	local displayWeight = false
	if weight ~= nil then
		-- if heavier than 1 grams, but not less than 200 grams when light item weights may be hidden
		if weight >= 0.01 and not (common.config.useSmallerUnits == 2 and weight <= 2.0) then
			displayWeight = true
		end
	end

	-- detect container if it exists due to UI Expansion
	local container = e.tooltip:findChild(GUI_ID_TooltipIconBar)
	if container ~= nil and (displayWeight or displayGold) then
		container:destroyChildren()
		-- align value/weight display to center
		container.childAlignX = 0.5

	elseif displayWeight or displayGold then
		-- else create a new one if needed
		container = e.tooltip:createBlock{ id = GUI_ID_TooltipIconBar }
		container.widthProportional = 1.0
		container.minHeight = 16
		container.autoHeight = true
		container.autoWidth = true
		container.paddingAllSides = 2
		container.paddingTop = 4
		container.childAlignX = 0.5

	elseif container ~= nil then
		container.visible = false
	end

	-- Add the value and weight back in.
	if displayWeight or displayGold then

		-- Value
		if displayGold then
			local block = container:createBlock{ id = GUI_ID_TooltipIconGoldBlock }
			block.autoWidth = true
			block.autoHeight = true
			block:createImage{ path = "icons/gold.dds" }
			local label

			-- value
			local value = e.object.value
			
			-- remembered values from bartering
			local knownItemPrecision = 0
			if common.config.useSoldItemValues and itemValues[e.object.id] then
				if itemValues[e.object.id] > 0 then
					knownItemPrecision = (value / itemValues[e.object.id]) * 100
				end
			end
			--mwse.log(string.format( e.object.name.." "..value ))

			-- taken from UI Expansion
			-- Fixup item value based on MCP feature state.
			if e.object.isSoulGem then
				if (e.itemData and e.itemData.soul) then
					local soulValue = e.itemData.soul.soul
					if (useMCPSoulgemValueRebalance) then
						value = (soulValue ^ 3) / 10000 + soulValue * 2
					else
						value = value * soulValue
					end

					-- if there is a soul, the price wouldn't match
					knownItemPrecision = 0
				end
			end


			-- value is known through bartering, and almost accurate
			if knownItemPrecision > 98 then
				value = itemValues[e.object.id]

				-- apply optional stackCount
				if common.config.summarizeStacks == 2 and stackCount > 1 then
					value = value * stackCount
				end

				label = block:createLabel{ text = string.format("%u", value) }


			-- do the guessing
			elseif common.config.useVagueGold > 0 then

				local player = tes3.mobilePlayer
				local playerLvl = player.object.level --player level as measure for in-world experience
				local playerMerc = player.mercantile.current

				-- main variable to define what is vague and how much
				local uncertainty = 5 / (playerLvl * playerMerc + 0.000001)
				if uncertainty < 0 then uncertainty = 1 end

				-- number of digits of the base value
				local digits = math.floor( math.log10(value) + 1 )
				-- number of digits that may be obscured
				local obscurity = math.floor( math.log10(value * uncertainty * 0.2) + 1.5 )
				if obscurity < 0 then obscurity = 0 end

				--mwse.log( e.object.value.." "..digits.." "..obscurity )

				-- define what's even measurable
				local measurableCap = 567 / uncertainty
				local capped = value > measurableCap-1


				-- keep a lid on it
				if common.config.useVagueGold > 1 and knownItemPrecision == 0 and capped then
					-- invaluable: is not measurable
					label = block:createLabel{ text = common.dictionary.roleplayGoldLabelMask }


				-- either display clearly, or convert value to a partly obscured integer
				elseif (common.config.useVagueGold == 1) 
					or (common.config.useVagueGold == 3 and digits > obscurity)
					or knownItemPrecision > 0 then

					local valueStr

					-- fully obscure: f.i. 123 will be hidden with 3+ obscure digits
					-- should only show if labels aren't enabled
					if digits <= obscurity and knownItemPrecision == 0 then
						valueStr = "?"

					-- uncertain but estimable
					else --if obscurity >= 1 then

						-- round to the number of obscure digits, f.i. 123456 with 4 obscurity = 123000
						local mult = 10^(-obscurity or 0)
						value = math.floor(value * mult) / mult -- no rounding up, to allow some devaluation

						-- value is known through bartering, but it should be taken with a grain of salt
						local known = false
						if knownItemPrecision > 0 then
							local estimatePrecision = (e.object.value / value) * 100

							mwse.log( value.." "..estimatePrecision.." vs "..itemValues[e.object.id].." "..knownItemPrecision )
							-- use the value that is closer to the truth
							if knownItemPrecision > estimatePrecision or value == 0 then
								value = itemValues[e.object.id]
							end
							known = true
						end

						-- apply optional stackCount
						-- it is being applied only at this point, as it shouldn't be influenced by the certainty on single items
						if common.config.summarizeStacks == 2 and stackCount > 1 then
							value = value * stackCount
							digits = math.floor( math.log10(value) + 1 )
						end
						
						-- value is easily assessable: most common case on most items from lvl ~5 up
						if obscurity == 0 then
							valueStr = string.format("%u", value)

						-- value is known through bartering
						elseif known then
							valueStr = string.format("%u?", value)

						-- display rounded to millions (Mega)
						elseif digits > 6 and obscurity > 3 then
							valueStr = string.format("%.1f", math.floor(value / 1000000 + 0.5)):gsub("%.?0+$", "")
							valueStr = valueStr.."M?"

						-- display rounded to thousands (Kilo)
						elseif digits > 3 and obscurity > 0 then
							valueStr = string.format("%uK?", math.floor(value / 1000 + 0.5))

						-- display every other uncertain case
						else
							valueStr = string.format("%u?", value)
						end
					end

					label = block:createLabel{ text = valueStr }
				

				-- use labels above, or instead of obscure numbers
				else--[[if (common.config.useVagueGold == 2) 
					or (common.config.useVagueGold == 3 and digits <= obscurity) then]]

					-- cheap
					if value < 10 then
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelZero }

					-- common: 10 to 33/69
					elseif value < (30 + (playerLvl + playerMerc) * 0.2) then
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelOne }

					-- prized: 34/70 to 505/1499
					elseif value < (500 + playerLvl * playerMerc * 0.2) then
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelTwo }

					-- precious: 506/1500 to 1014/5999
					elseif value < (1.000 + playerLvl * playerMerc * 0.5) then
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelThree }

					-- immense: 1015/6000 to 10029/29999
					elseif value < (10.000 + playerLvl * playerMerc * 2) then
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelFour }

					-- mythic: 10030/30000 to 110999
					elseif value < 111.000 then
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelFive }

					-- legendary: all above 111000
					else
						label = block:createLabel{ text = common.dictionary.roleplayGoldLabelSix }
					end
				end

			-- options disabled: do not apply any vagueness
			else
				label = block:createLabel{ text = string.format("%u", value) }
			end
			-- end value label
			label.borderLeft = 4
		end

		-- Weight
		if displayWeight then

			block = container:createBlock{ id = GUI_ID_TooltipIconWeightBlock }
			block.autoWidth = true
			block.autoHeight = true

			local convWeight, unit, label

			if (common.config.useUnitConversionType == 1) then
				-- Metric units

				-- Fluids
				if (common.config.potionsInMilliLitres and e.object.objectType == tes3.objectType.alchemy) then
					block:createImage{ path = "Icons/lrwd_flask.dds" }
					block.borderLeft = 8

					-- light fluids
					if (common.config.useSmallerUnits == 1 and weight < 10.0) then
						unit = string.format(" ml") -- set to milliliters
						convWeight = weight * 100.0
						label = block:createLabel{ text = string.format("%u%s", convWeight, unit) }

					-- heavy fluids
					elseif (common.config.useSmallerUnits == 0 or weight >= 10.0) then
						unit = string.format(" l") -- set to liters
						convWeight = weight / 10.0
						convWeight = common.formatStripZeros( convWeight )
						label = block:createLabel{ text = string.format("%s%s", convWeight, unit) }
					end

				-- light items
				elseif (common.config.useSmallerUnits == 1 and weight < 10.0) then
					block:createImage{ path = "icons/weight.dds" }
					block.borderLeft = 8
					unit = string.format(" g") -- set to grams
					convWeight = weight * 100.0
					label = block:createLabel{ text = string.format("%u%s", convWeight, unit) }

				-- heavy items
				elseif (common.config.useSmallerUnits == 0 or weight >= 10.0) then
					block:createImage{ path = "icons/weight.dds" }
					block.borderLeft = 8
					unit = string.format(" kg") -- set to kilograms
					convWeight = weight / 10.0
					convWeight = common.formatStripZeros( convWeight )
					label = block:createLabel{ text = string.format("%s%s", convWeight, unit) }
				end


			elseif (common.config.useUnitConversionType == 2) then
				-- Imperial units

				-- Fluids icon
				if (common.config.potionsInMilliLitres and e.object.objectType == tes3.objectType.alchemy) then
					block:createImage{ path = "Icons/lrwd_flask.dds" }
				else
					block:createImage{ path = "icons/weight.dds" }
				end
				block.borderLeft = 8

				-- light items
				if (common.config.useSmallerUnits == 1 and weight <= 4.5359) then
					unit = string.format(" oz") -- set to ounces
					convWeight = weight / 0.2835
					label = block:createLabel{ text = string.format("%.1f%s", convWeight, unit) }

				-- heavy items
				elseif (common.config.useSmallerUnits == 0 or weight > 4.5359) then
					unit = string.format(" lb") -- set to pounds
					convWeight = weight / 4.5359
					convWeight = common.formatStripZeros( convWeight )
					label = block:createLabel{ text = string.format("%s%s", convWeight, unit) }
				end


			elseif (common.config.useUnitConversionType == 3) then
				-- Vague roleplay labels
				
				-- Fluids icon
				if (common.config.potionsInMilliLitres and e.object.objectType == tes3.objectType.alchemy) then
					block:createImage{ path = "Icons/lrwd_flask.dds" }
				else
					block:createImage{ path = "icons/weight.dds" }
				end
				block.borderLeft = 8

				-- light items
				if weight <= 0.1 then
					label = block:createLabel{ text = common.dictionary.roleplayLabelZero }

				-- light items
				elseif weight <= 3.0 then
					label = block:createLabel{ text = common.dictionary.roleplayLabelOne }

				-- weighty items
				elseif weight <= 15.0 then
					label = block:createLabel{ text = common.dictionary.roleplayLabelTwo }

				-- heavier items
				elseif weight <= 45.0 then
					label = block:createLabel{ text = common.dictionary.roleplayLabelThree }

				-- very heavy items
				else --if weight > 45.0 then
					label = block:createLabel{ text = common.dictionary.roleplayLabelFour }
				end


			else
				-- Vanilla w/o units

				-- Fluids icon
				if (common.config.potionsInMilliLitres and e.object.objectType == tes3.objectType.alchemy) then
					block:createImage{ path = "Icons/lrwd_flask.dds" }
				else
					block:createImage{ path = "icons/weight.dds" }
				end
				block.borderLeft = 8

				convWeight = common.formatStripZeros( weight )
				label = block:createLabel{ text = string.format("%s", convWeight) }
			end
			-- end weight label
			--mwse.log(e.object.name.." "..string.format("%.1f", weight) )
			label.borderLeft = 4


			-- stack count
			if common.config.summarizeStacks > 0 and stackCount > 1 then
				local stackBlock = container:createBlock{ id = GUI_ID_TooltipStackCountBlock }
				stackBlock.autoWidth = true
				stackBlock.autoHeight = true
				local stackLabel = stackBlock:createLabel{ text = stackCountString }
				stackLabel.borderLeft = 8
			end


			-- enable value/weight ratio on worthless and relatively heavy items
			if common.config.useWeightGoldRatio and e.object.value < 2000 and weight > 4.0 then
				local ratioBlock = container:createBlock{ id = GUI_ID_TooltipIconGoldWeightBlock }
				ratioBlock.autoWidth = true
				ratioBlock.autoHeight = true

				local slash = ratioBlock:createLabel{ text = string.format("/") }
				slash.color = tes3ui.getPalette("negative_color")
				slash.borderLeft = 8

				local ratio = e.object.value / e.object.weight
				local ratioLabel = ratioBlock:createLabel{ text = string.format("%u", ratio) }
				ratioLabel.borderLeft = 4
			end
		end
		--end weight

		-- Update minimum width of the whole tooltip to make sure there's space for the value/weight.
		e.tooltip:getContentElement().minWidth = 220
		if common.config.useUnitConversionType == 3 or common.config.useVagueGold > 1 then
			-- exception for roleplay labels
			e.tooltip:getContentElement().minWidth = 250
		end
		e.tooltip:updateLayout()
	end

	local divide = e.tooltip:findChild(GUI_ID_TooltipExtraDivider)
	if divide ~= nil then
		divide.borderAllSides = 10
		divide.borderBottom = 5
		divide.widthProportional = 0.30
	end
end
event.register("uiObjectTooltip", extraTooltipEarly, {priority = 50} )

















