-- Provincial Reputation for Tamriel_Data
-- by Rakanishu and Kynesifnar

-- Needs optimization
-- Reputation's impact on persuasion calc.: https://wiki.openmw.org/index.php/Research:Disposition_and_Persuasion

local this = {}

local common = require("tamrielData.common")

local baseReputation

-- Project information must be in alphabetical order.
-- Info is based on T_D and project variables so don't change these unless they are changed in T_D
local projectTable = {
    {
        province = "Cyrodiil",
        name = common.i18n("reputation.Cyrodiil"),
        installVar = "T_Glob_Installed_PC",
        repVar = "T_Glob_Rep_Cyr"
    },
    {
        province = "Hammerfell",
        name = common.i18n("reputation.Hammerfell"),
        installVar = "T_Glob_Installed_Ham",
        repVar = "T_Glob_Rep_Ham"
    },
    {
        province = "High Rock",
        name = common.i18n("reputation.HighRock"),
        installVar = "T_Glob_Installed_HR427",
        repVar = "T_Glob_Rep_Hr"
    },
    {
        province = "Morrowind",
        name = common.i18n("reputation.Morrowind"),
        installVar = "",
        repVar = ""
    },
    {
        province = "Padomaic Isles",
        name = common.i18n("reputation.PadomaicIsles"),
        installVar = "T_Glob_Installed_PI",
        repVar = "T_Glob_Rep_PI"
    },
    {
        province = "Skyrim",
        name = common.i18n("reputation.Skyrim"),
        installVar = "T_Glob_Installed_SHotN",
        repVar = "T_Glob_Rep_Sky"
    }
}

-- Create a tooltip for each new reputation entry.
-- Get the source reputation block's info to identify project name.
---@param e tes3uiEventData
local function createTooltip(e)
    local statMenu = tes3ui.findMenu("MenuStat")
    local nameLabel = statMenu:findChild(e.source)
    local name = nameLabel.text

    local tooltip = tes3ui.createTooltipMenu()

    local tooltipLayout = tooltip:createBlock()
    tooltipLayout.positionX = 16
    tooltipLayout.positionY = -12
    tooltipLayout.width = 432
    tooltipLayout.height = 18
    tooltipLayout.maxWidth = 432
    tooltipLayout.autoHeight = true
    tooltipLayout.borderAllSides = 6
    tooltipLayout.childAlignX = 0.5
    tooltipLayout.childAlignY = 0.5
    tooltipLayout.flowDirection = top_to_bottom
    tooltipLayout:updateLayout()
    local tooltipLabel = tooltipLayout:createLabel{}
    tooltipLabel.text = common.i18n("reputation.tooltip", { name })
    tooltipLabel.positionX = 49
    tooltipLabel.width = 333
    tooltipLabel.height = 18
    tooltipLabel:updateLayout()
end

-- Create new reputation section with header, divider, and new entries 
-- whenever something updates the Stat Menu and forces rebuild
--- @param e uiRefreshedEventData
function this.uiRefreshedCallback(e)
    local statMenu = tes3ui.findMenu("MenuStat")

    if not statMenu then return end

    -- Find vanilla MenuStat_misc_layout that holds vanilla "Reputation" label and destroy it
    local vanillaNameLabel = statMenu:findChild("MenuStat_reputation_name")
    local vanillaLayout = vanillaNameLabel.parent
	local repLayout = vanillaLayout.parent
    vanillaLayout:destroy()

	-- Find where the bounty's misc_layout is so that the reputation blocks can be placed accordingly for mods affecting the stat menu such as Tidy Charsheet
	local bountyLayout

	for i = #repLayout.children, 1, -1 do
		if repLayout.children[i].name == "MenuStat_misc_layout" and repLayout.children[i].children[1] and repLayout.children[i].children[1].name == "MenuStat_Bounty_name" then
			bountyLayout = repLayout.children[i]
			break
		end
	end

	if not bountyLayout then return end

    -- Count the number of added reputation blocks for later indexing/rearranging
    local isFirstBlock = true
    local firstBlock

    -- Iterate through TD mods and add reputation block for each
    for _,project in ipairs(projectTable) do
        local installVar = project.installVar
        local repVar = project.repVar

        if project.province == "Morrowind" or (tes3.getGlobal(installVar) and tes3.getGlobal(installVar) > 0) then
            local repBlockId = "MenuStat_TD_Rep_" .. project.province .. "_layout"

            local repBlock = repLayout:findChild(repBlockId)
            if repBlock then repBlock:destroy() end

            repBlock = repLayout:createBlock({ id = repBlockId })
            repBlock.width = 779
            repBlock.borderRight = bountyLayout.borderRight     -- These settings change between vanilla and Tidy Charsheet, using bountyLayout's values keeps everything consistent
            repBlock.childAlignX = bountyLayout.childAlignX
            repBlock.autoHeight = true
            repBlock.autoWidth = bountyLayout.autoWidth
            repBlock.widthProportional = 1.0

            local nameLabel = repBlock:createLabel({ id = "MenuStat_TD_Rep_" .. project.province .. "_name" })
            nameLabel.text = project.name
            nameLabel.positionX = 10
            nameLabel.width = 169
            nameLabel.borderLeft = 10

            local valueLabel = repBlock:createLabel({ id = "MenuStat_TD_Rep_" .. project.province .. "_value" })
			
            if project.province == "Morrowind" then
                valueLabel.text = tes3.player.object.reputation
            else
				local repVarGlobal = tes3.getGlobal(repVar)
				if repVarGlobal then
					valueLabel.text = tes3.getGlobal(repVar)
				else
					valueLabel.text = 0
				end
            end

            --valueLabel.positionX = 770
            --valueLabel.width = 9
            valueLabel.absolutePosAlignX = bountyLayout.children[2].absolutePosAlignX
            repBlock:reorder({ before = bountyLayout })

            if isFirstBlock then
                firstBlock = repBlock   -- The first block is needed so that the reputation title can be placed properly
                isFirstBlock = false
            end

            nameLabel:register(tes3.uiEvent.help, createTooltip)
        end
    end

    -- Create divider between the "Reputation" section and "Bounty"
    local divider = repLayout:createDivider({ id = "MenuStat_TD_Rep_Divider" })
    divider:reorder({ before = bountyLayout })

    -- Create text label for new "Reputation" section header
    local titleLabel = repLayout:createLabel({ id = "MenuStat_TD_Rep_Title" })
    titleLabel.text = common.i18n("reputation.title")
    titleLabel.color = tes3ui.getPalette("header_color")
    titleLabel:reorder({ before = firstBlock })

    repLayout:updateLayout()
end

-- Switch the player's reputation value with one of the provincial values depending on the source ESM of the actor that they are speaking with
---@param e menuEnterEventData
function this.switchReputation(e)
	local actorTarget = tes3.rayTest{			-- tes3.getPlayerTarget doesn't work in conversations
		position = tes3.getPlayerEyePosition(),
		direction = tes3.getPlayerEyeVector(),
		root = {tes3.game.worldPickRoot},
		ignore = {tes3.player}
	}
    
	if not actorTarget or not actorTarget.reference or actorTarget.reference.baseObject.objectType ~= tes3.objectType.npc then return end

	local actorSource = actorTarget.reference.sourceMod
	
	if actorSource then
		if e.menuMode and (actorSource == "Cyr_Main.esm" or actorSource == "Sky_Main.esm") then  -- menuEnter
			baseReputation = tes3.player.object.reputation
			if actorSource == "Cyr_Main.esm" then           -- As more provinces are released, these conditions will need to be expanded
				tes3.player.object.reputation = tes3.getGlobal("T_Glob_Rep_Cyr")
			elseif actorSource == "Sky_Main.esm" then
				tes3.player.object.reputation = tes3.getGlobal("T_Glob_Rep_Sky")
			end
		else    -- menuExit
			if baseReputation and (actorSource == "Cyr_Main.esm" or actorSource == "Sky_Main.esm") then	-- If the actor is (presumably) in Morrowind, then don't change the reputation because it is unnecessary at best and may overwite a recent change at worst
                tes3.player.object.reputation = baseReputation + tes3.getGlobal("T_Glob_Rep_MW")
                tes3.setGlobal("T_Glob_Rep_MW", 0)
                baseReputation = nil    -- The menuExit event does not know which menu the player is exiting from, but since baseReputation can only be set during menuEnter and must exist for menuExit, setting it to nil here will prevent menuExit from running unless exiting from the dialogue menu
                                        -- Interestingly, exiting other menus while in the dialogue menu does not trigger the menu exit event, so exiting the persuasion/travel menus does not swap the player's reputation when they are still talking.
            end
		end
	end
end

-- Travelling does not trigger the menuExit event, so this function replaces the Morrowind reputation with baseReputation if it exists on a cell change, which can only be true if the player was in the dialogue menu
---@param e cellChangedEventData
function this.travelSwitchReputation(e)
    if baseReputation then
        tes3.player.object.reputation = baseReputation  -- Should T_Glob_Rep_MW be used here too?
        baseReputation = nil
    end
end

return this