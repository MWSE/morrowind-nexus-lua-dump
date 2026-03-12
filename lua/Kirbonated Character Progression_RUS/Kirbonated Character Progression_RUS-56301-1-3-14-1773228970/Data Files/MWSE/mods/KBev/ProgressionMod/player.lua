common = require("KBev.ProgressionMod.common")
mcm = require("KBev.ProgressionMod.mcm")

local public

local levelPointName = {
 atr = "Очки характеристик",
 prk = "Очки талантов",
 mjr = "Очки главных навыков",
 mnr = "Очки важных навыков",
 msc = "Очки маловажных навыков"
}
local perksListBlock
local outerPerksBlock

local function onLoaded(e)
	if not tes3.player.data.KCP then 
		tes3.player.data.KCP = table.copy(common.defaultPlayerData)
	end
	common.playerData = tes3.player.data.KCP
end
event.register("loaded", onLoaded)

local function calcPntIncrease(typ)
	if (tes3.player.object.level + 1) % mcm[typ .. "LvlInterval"] > 0 then
		return 0 
	end
	return common.playerData.levelPoints[typ] + common.playerData.incPoints[typ] + (mcm[typ .. "LvlMult"] * common.playerData.pntMult[typ])
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
		children[2].widget.current = common.playerData.xp
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
    for k, v in pairs(common.playerData.levelPoints) do

        local pointsBlock = layout:createBlock({})
        pointsBlock.flowDirection = "left_to_right"
        pointsBlock.autoHeight = true
        pointsBlock.autoWidth = true
        pointsBlock.widthProportional = 1.0
        pointsBlock.childAlignX = 0.5
		
        pointsBlock:createLabel({ text = levelPointName[k] .. ": " .. calcPntIncrease(k) })
    end
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


local function onLevelUp(e)
	if common.playerData.xp < public.calcXPReq(e.level - 1) then common.playerData.xp = 0
	else common.playerData.xp = common.playerData.xp - public.calcXPReq(e.level - 1)
	end
end
event.register("preLevelUp", onLevelUp)

public = {
	
	giveXP = function(i) 
		if mcm.xpEnabled then
			common.playerData.xp = common.playerData.xp + i 
			event.trigger("KCP:XPGained", {added = i, total = common.playerData.xp})
		end
	end,
	
	modLevelPoints = function(params) common.playerData.levelPoints[params.typ] = common.playerData.levelPoints[params.typ] + params.mod end,
	
	modPntMult = function(params) common.playerData.pntMult[params.typ] = common.playerData.pntMult[params.typ] + params.mod end,
	
	modIncPoints = function(params) common.playerData.incPoints[params.typ] = common.playerData.incPoints[params.typ] + params.mod end,
	
	getCellVisited = function(id)
		return common.playerData.wrldCellsVisited[id] or false
	end,
	
	setCellVisited = function(id)
		common.playerData.wrldCellsVisited[id] = true
	end,
	
	calcXPReq = function(level)
		return (mcm.xpLvlBase + (mcm.xpLvlMult * level))
	end,
	
}
return public