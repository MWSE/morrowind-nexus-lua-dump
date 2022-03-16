common = require("KBev.ProgressionMod.common")
mcm = require("KBev.ProgressionMod.mcm")

local levelPointName = {
 atr = "Attribute Points",
 prk = "Perk Points",
 mjr = "Major Skill Points",
 mnr = "Minor Skill Points",
 msc = "Misc Skill Points"
}
local perksListBlock
local outerPerksBlock

local playerData = {
	xp = 0,
	levelPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0},
	perks = {},
	activatedPerks = {},
	incPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0}, --controls flat bonuses to level points
	pntMult = {atr = 1, prk = 1, mjr = 1, mnr = 1, msc = 1}, --controls multipliers to level points
	wrldCellsVisited = {}, --stores worldspace cells for the exploration XP tracker
	questsCompleted = {} --stores questIDs after they've been completed
}


local function onLoaded(e)
	if not tes3.player.data.KBProgression then 
		tes3.player.data.KBProgression = {
			xp = 0,
			levelPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0},
			perks = {},
			activatedPerks = {},
			incPoints = {atr = 0, prk = 0, mjr = 0, mnr = 0, msc = 0}, --controls flat bonuses to level points
			pntMult = {atr = 1, prk = 1, mjr = 1, mnr = 1, msc = 1}, --controls multipliers to level points
			wrldCellsVisited = {}, --stores worldspace cells for the exploration XP tracker
			questsCompleted = {} --stores questIDs after they've been completed
		}
	end
	--debug code
	for k, v in pairs(tes3.mobilePlayer.attributes) do
		common.info("Attribute Key = " .. k)
	end
	
	playerData = tes3.player.data.KBProgression
	
	--Remove perks without valid IDs
	for perk, active in pairs(playerData.perks) do
		if not common.perkList[perk] then
			active = nil
		end
	end
	
	for perk, active in pairs(playerData.activatedPerks) do
		if active then common.perkList[perk].activated = true end
	end
	public.updatePerksList()
end
event.register("loaded", onLoaded)

local function calcPntIncrease(typ)
	if (tes3.player.object.level + 1) % mcm[typ .. "LvlInterval"] > 0 then
		return 0 
	end
	return playerData.levelPoints[typ] + playerData.incPoints[typ] + (mcm[typ .. "LvlMult"] * playerData.pntMult[typ])
end

--[[
Stat Menu Changes
	level tooltip was adapted from Class-Conscious Character Progression, credit goes to Necrolesian

]]
-- Runs each time the player hovers over the level display in the stat menu, but only if the MCP feature expanding this
-- tooltip is active.
local function levelUpProgressTooltip(e)

    -- Allows the vanilla tooltip to be created. Otherwise we can't modify it, because it doesn't exist.
    e.source:forwardEvent(e)

    -- Find the block that contains the attribute list. Doing it this way is necessary because none of these elements
    -- have names, so can't be referenced directly.
    local tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
    local layout = tooltip.children[1].children[1]
    local children = layout.children
    children[2].borderBottom = 6
	
	if mcm.xpEnabled then
		children[2].widget.max = public.calcXPReq(tes3.player.object.level)
		children[2].widget.current = playerData.xp
	end

	--[[
		hides MCP attribute level text since this mod completely replaces the way attributes are leveled
	]]
	if tes3.hasCodePatchFeature(tes3.codePatchFeature.levelupSkillsTooltip) then
		for i = 3, #children do
			children[i].visible = false
		end
	end

    --[[ Adds displays for Attribute Points, Skill Points, and Perk Points 
	example:
		Attribute Points: 7
		Perk Points: 1
		Major Skill Points: 10
		Minor Skill Points: 5
		Misc Skill Points: 5
	]]
    for k, v in pairs(playerData.levelPoints) do

        local pointsBlock = layout:createBlock({})
        pointsBlock.flowDirection = "left_to_right"
        pointsBlock.autoHeight = true
        pointsBlock.autoWidth = true
        pointsBlock.widthProportional = 1.0
        pointsBlock.childAlignX = 0.5
		
        pointsBlock:createLabel({ text = levelPointName[k] .. ": " .. calcPntIncrease(k) })
    end
end

--constructor for statMenu perk tooltips, based on skills module by Merlord
local function createPerkTooltip(perkID)
	local tooltip = tes3ui.createTooltipMenu()
	
	local outerBlock = tooltip:createBlock({ id=tes3ui.registerID("KBProgression:perkTTOuterBlock") })
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

-- Runs when the stat menu is created.
local function onMenuStatActivated(e)

    local frame = e.element

    local levelBlock = frame:findChild(tes3ui.registerID("MenuStat_level_layout"))
    local levelElem = levelBlock:findChild(tes3ui.registerID("MenuStat_level"))

    -- Registers our tooltip function to occur when the player hovers the mouse over the level display.
    levelElem:register("help", levelUpProgressTooltip)

    -- Find the actual element for the "Level" label and register the event to change its tooltip as well. This for loop
    -- is necessary because the specific element in question doesn't have a name, so we have to iterate through all the
    -- children of its parent element to find it.
    for _, child in pairs(levelBlock.children) do
        if child.text == "Level" then
            child:register("help", levelUpProgressTooltip)
            break
        end
    end
end
event.register("uiActivated", onMenuStatActivated, { filter = "MenuStat" })

--generates perkList, based on Skills Module by Merlord


--Adds perk display to stats menu based on the UI implementation from Merlord's Skills Module
local function createOuterPerksBlock(e)
	if not e.element then return end
	
	--Navigate to the Skills block
	local miscBlock = e.element:findChild( tes3ui.registerID("MenuStat_misc_layout") )
	local parentSkillBlock = miscBlock.parent
	
	outerPerksBlock = parentSkillBlock:createBlock({ id = tes3ui.registerID("KBProgression:outerPerksBlock") })
	outerPerksBlock.autoHeight = true
	outerPerksBlock.layoutWidthFraction = 1.0
	outerPerksBlock.flowDirection = "top_to_bottom"
	
	local divider = outerPerksBlock:createDivider({ id=tes3ui.registerID("KBProgression:perksDivider") })
	local headerBlock = outerPerksBlock:createBlock({ id=tes3ui.registerID("KBProgression:perksHeaderBlock") })
	headerBlock.layoutWidthFraction = 1.0
	headerBlock.autoHeight = true

	local perksHeader = headerBlock:createLabel({ id=tes3ui.registerID("KBProgression:perksHeadingLabel") , text = "Perks"})
	perksHeader.color = tes3ui.getPalette("header_color")
	perksListBlock = outerPerksBlock:createBlock({id=tes3ui.registerID("KBProgression:perksListBlock") })
	perksListBlock.flowDirection = "top_to_bottom"
	perksListBlock.layoutWidthFraction = 1.0
	perksListBlock.autoHeight = true

	--move Perks section to right after Misc Skills
	parentSkillBlock:reorderChildren(32, outerPerksBlock, -1)
	public.updatePerksList()
end
--event is registered at priority 1 so that the mod displays correctly with Merlord's Custom Skills module
event.register("uiRefreshed", createOuterPerksBlock, {filter = "MenuStat_scroll_pane", priority = 1 } )

local function onLevelUp(e)
	if playerData.xp < public.calcXPReq(e.level - 1) then playerData.xp = 0
	else playerData.xp = playerData.xp - public.calcXPReq(e.level - 1)
	end
end
event.register("preLevelUp", onLevelUp)

public = {
	getAttributePoints = function() return playerData.levelPoints.atr end,
	getPerkPoints = function() return playerData.levelPoints.prk end,
	getMajorSkillPoints = function() return playerData.levelPoints.mjr end,
	getMinorSkillPoints = function() return playerData.levelPoints.mnr end,
	getMiscSkillPoints = function() return playerData.levelPoints.msc end,
	
	hasPerk = function(perkID) return playerData.perks[perkID] or false end,
	
	giveXP = function(i) 
		if mcm.xpEnabled then
			playerData.xp = playerData.xp + i 
			event.trigger("KBProgression:XPGained", {added = i, total = playerData.xp})
		end
	end,
	advanceLevel = function() 
		tes3.mobilePlayer.levelUpProgress = tes3.findGMST(tes3.gmst.iLevelupTotal).value
		tes3.messageBox("You should rest and meditate on what you've learned")
	end,
	
	giveAttributePoints = function(i) playerData.levelPoints.atr = playerData.levelPoints.atr + i end,
	givePerkPoints = function(i) playerData.levelPoints.prk = playerData.levelPoints.prk + i end,
	giveMajorSkillPoints = function(i) 
		if not mcm.xpEnabled then 
			playerData.levelPoints.mjr = 0
		else
			playerData.levelPoints.mjr = playerData.levelPoints.mjr + i 
		end
	end,
	giveMinorSkillPoints = function(i) 
		if not mcm.xpEnabled then 
			playerData.levelPoints.mnr = 0
		else
			playerData.levelPoints.mnr = playerData.levelPoints.mnr + i 
		end
	end,
	giveMiscSkillPoints = function(i) 
		if not mcm.xpEnabled then 
			playerData.levelPoints.msc = 0
		else
			playerData.levelPoints.msc = playerData.levelPoints.msc + i 
		end
	end,
	
	modPntMult = function(params) playerData.pntMult[params.typ] = playerData.pntMult[params.typ] + params.mod end,
	
	modIncPoints = function(params) playerData.incPoints[params.typ] = playerData.incPoints[params.typ] + params.mod end,
	
	grantPerk = function(id) 
		if not common.perkList[id] then common.err("attempted to grant nonexistent perk \"" .. id .. "\" to the player") return false end
		if not playerData.perks[id] then 
			playerData.perks[id] = true
			if not (common.perkList[id].delayActivation) then 
				event.trigger("KBProgression:activatePerk", {id = id}) --omegalul
			end
		end
		return true
	end,
	
	removePerk = function(id)
		playerData.perks[id] = nil
		event.trigger("KBProgression:deactivatePerk", {id = id})
	end,
	
	getCellVisited = function(id)
		return playerData.wrldCellsVisited[id] or false
	end,
	
	setCellVisited = function(id)
		playerData.wrldCellsVisited[id] = true
	end,
	
	calcXPReq = function(level)
		return (mcm.xpLvlBase + (mcm.xpLvlMult * level))
	end,
	
	updatePerksList = function()
		local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
		if not mainMenu then return end
		if (not playerData.perks) then return end
		--make perk list invisible until we have at least one perk

	
		if perksListBlock and outerPerksBlock then
			outerPerksBlock.autoHeight = false
			outerPerksBlock.height = 0
	
			perksListBlock:destroyChildren()
			for perkID, active in pairs(playerData.perks) do
				if active then
					outerPerksBlock.autoHeight = true
					local perkBlock = perksListBlock:createBlock({id=tes3ui.registerID("KBProgression:perkBlock_" .. perkID) })
					if not perkBlock then return end
					perkBlock.layoutWidthFraction = 1.0
					perkBlock.flowDirection = "left_to_right"
					perkBlock.borderLeft = 10
					perkBlock.borderRight = 5
					perkBlock.autoHeight = true
				
					local perkLabel = perkBlock:createLabel({ id=tes3ui.registerID("KBProgression:perkLabel_" .. perkID), text = common.perkList[perkID].name })
					perkLabel.layoutOriginFractionX = 0.0
				
				
					--Create perk Tooltip
					perkBlock:register("help", function() createPerkTooltip(perkID) end)
				end
			end	
		end
		mainMenu:updateLayout()
	end,
}
return public