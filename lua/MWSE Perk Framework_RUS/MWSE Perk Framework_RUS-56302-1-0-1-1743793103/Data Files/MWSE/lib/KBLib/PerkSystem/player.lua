local common = require("KBLib.PerkSystem.common")
local public

local function onLoaded(e)
	if not tes3.player.data.mwsePerks then 
		tes3.player.data.mwsePerks = table.copy( common.playerData)
	end
	common.playerData = tes3.player.data.mwsePerks
	
	--Remove perks without valid IDs
	for perk, active in pairs( common.playerData.perks) do
		if not common.perkList[perk] then
			active = nil
		end
	end
	
	for perk, active in pairs( common.playerData.activatedPerks) do
		if active then common.perkList[perk].activated = true end
	end
	
	public.updatePerksList()
end
event.register("loaded", onLoaded)

--constructor for statMenu perk tooltips, based on skills module by Merlord
local function createPerkTooltip(perkID)
	local tooltip = tes3ui.createTooltipMenu()
	
	local outerBlock = tooltip:createBlock({ id=tes3ui.registerID("KCP:perkTTOuterBlock") })
	outerBlock.flowDirection = "top_to_bottom"
	outerBlock.paddingTop = 6
	outerBlock.paddingBottom = 12
	outerBlock.paddingLeft = 6
	outerBlock.paddingRight = 6
	
	outerBlock.autoWidth = true
	outerBlock.autoHeight = true

	---\
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local topBlock = outerBlock:createBlock()																		--
		topBlock.autoHeight = true																																		--
		topBlock.autoWidth = true																																		--
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local topRightBlock = topBlock:createBlock()																--
			topRightBlock.autoHeight = true																																	--
			topRightBlock.autoWidth = true																																	--
			topRightBlock.paddingLeft = 10																																	--
			topRightBlock.flowDirection = "top_to_bottom"																													--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			---\
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				local perkLabel = topRightBlock:createLabel({ text = common.perkList[perkID].name })											--
				perkLabel.autoHeight = true																																	--
				perkLabel.autoWidth = true																																		--
				perkLabel.color = tes3ui.getPalette("header_color")																											--
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
	---\	
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local bottomBlock = outerBlock:createBlock()																		--
		bottomBlock.paddingTop = 10																																		--																																		--
		bottomBlock.autoHeight = true																																		--
		bottomBlock.width = 430																																			--
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local descriptionLabel = bottomBlock:createLabel({text=common.perkList[perkID].description})								--
			descriptionLabel.wrapText = true																																--
			descriptionLabel.width = 445																																	--
			descriptionLabel.autoHeight = true																																--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
end

--Adds perk display to stats menu based on the UI implementation from Merlord's Skills Module
local function createOuterPerksBlock(e)
	if not e.element then return end
	
	--Navigate to the Skills block
	local miscBlock = e.element:findChild( tes3ui.registerID("MenuStat_misc_layout") )
		local parentSkillBlock = miscBlock.parent
	
			outerPerksBlock = parentSkillBlock:createBlock({ id = tes3ui.registerID("KCP:outerPerksBlock") })
			outerPerksBlock.autoHeight = true
			outerPerksBlock.layoutWidthFraction = 1.0
			outerPerksBlock.flowDirection = "top_to_bottom"
	
				local divider = outerPerksBlock:createDivider({ id=tes3ui.registerID("KCP:perksDivider") })
			
				local headerBlock = outerPerksBlock:createBlock({ id=tes3ui.registerID("KCP:perksHeaderBlock") })
				headerBlock.layoutWidthFraction = 1.0
				headerBlock.autoHeight = true

					local perksHeader = headerBlock:createLabel({ id=tes3ui.registerID("KCP:perksHeadingLabel") , text = "Таланты"})
					perksHeader.color = tes3ui.getPalette("header_color")
				
				perksListBlock = outerPerksBlock:createBlock({id=tes3ui.registerID("KCP:perksListBlock") })
				perksListBlock.flowDirection = "top_to_bottom"
				perksListBlock.layoutWidthFraction = 1.0
				perksListBlock.autoHeight = true

	--move Perks section to right after Misc Skills
	parentSkillBlock:reorderChildren(32, outerPerksBlock, -1)
	public.updatePerksList()
end
--event is registered at priority 1 so that the mod displays correctly with Merlord's Custom Skills module
event.register("uiRefreshed", createOuterPerksBlock, {filter = "MenuStat_scroll_pane", priority = 1 } )

public = {
	hasPerk = function(perkID) return  common.playerData.perks[perkID] or false end,
	
	grantPerk = function(id) 
		if not common.perkList[id] then common.err("attempted to grant nonexistent perk \"" .. id .. "\" to the player") return false end
		if not  common.playerData.perks[id] then 
			 common.playerData.perks[id] = true
			if not (common.perkList[id].delayActivation) then 
				event.trigger("KBPerks:activatePerk", {id = id}) --omegalul
			end
		end
		return true
	end,
	
	removePerk = function(id)
		 common.playerData.perks[id] = nil
		event.trigger("KBPerks:deactivatePerk", {id = id})
	end,
	
	updatePerksList = function()
		local menuStat = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
		if not menuStat then return end
		if (not common.playerData.perks) then return end
		--make perk list invisible until we have at least one perk

	
		if perksListBlock and outerPerksBlock then
			outerPerksBlock.autoHeight = false
			outerPerksBlock.height = 0
	
			perksListBlock:destroyChildren()
			for perkID, active in pairs( common.playerData.perks) do
				if active then
					outerPerksBlock.autoHeight = true
					local perkBlock = perksListBlock:createBlock({id=tes3ui.registerID("KBPerks:perkBlock_" .. perkID) })
					if not perkBlock then return end
					perkBlock.layoutWidthFraction = 1.0
					perkBlock.flowDirection = "left_to_right"
					perkBlock.borderLeft = 10
					perkBlock.borderRight = 5
					perkBlock.autoHeight = true
				
					local perkLabel = perkBlock:createLabel({ id=tes3ui.registerID("KBPerks:perkLabel_" .. perkID), text = common.perkList[perkID].name })
					perkLabel.layoutOriginFractionX = 0.0
				
				
					--Create perk Tooltip
					perkBlock:register("help", function() createPerkTooltip(perkID) end)
				end
			end	
		end
		menuStat:updateLayout()
	end,
}
return public