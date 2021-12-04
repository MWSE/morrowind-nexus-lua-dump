--[[ framework for adding new skills to a new "Other Skills" section ]]--

--When the game loads, check if there are any skills in the json file. 
--if so, create our "Other Skills" block and insert skills
--we also want to do this whenever a skill is added to the json file
--so wrap that up in a function which calls the updateBlock function
local this = {}
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[SkillsModule: DEBUG] " .. string)
	end
end

--[[
	Method to print human readable tree of elements to the log file
]]--
local tabCount = tabCount or 0
local function printElementTree(e)
	tabCount = tabCount + 1
	for i=1, #e.children do
		local child = e.children[i]
		local printString = ""
		for i=1, tabCount do
			printString = "  " .. printString
		end
		printString = printString .. "- " .. child.name .. ", ID: " .. child.id
		mwse.log(printString)
		printElementTree(child)
		tabCount = tabCount - 1
	end
end

local function createSkillTooltip(skill) 
	--debugMessage("Creating skills list")
	local tooltip = tes3ui.createTooltipMenu()
	
	local outerBlock = tooltip:createBlock({ id=tes3ui.registerID("OtherSkills:outerBlock") })
	outerBlock.flowDirection = "top_to_bottom"
	outerBlock.paddingTop = 6
	outerBlock.paddingBottom = 12
	outerBlock.paddingLeft = 6
	outerBlock.paddingRight = 6
	
	outerBlock.autoWidth = true
	outerBlock.autoHeight = true

	---\
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local topBlock = outerBlock:createBlock({ id=tes3ui.registerID("OtherSkills:ttTopBlock") })																		--
		topBlock.autoHeight = true																																		--
		topBlock.autoWidth = true																																		--
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local iconBlock = topBlock:createBlock({})																														--
			iconBlock.height = 32																																			--
			iconBlock.width = 32																																			--
			iconBlock.flowDirection = "left_to_right"																														--
			iconBlock.borderTop = 2																																			--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			---\
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				local iconBackgroundImagePath = "Icons/OtherSkills/default_blank.dds"																							--
				if skill.specialization == tes3.specialization.combat then																										--
					iconBackgroundImagePath = "Icons/OtherSkills/combat_blank.dds"																								--
				elseif skill.specialization == tes3.specialization.magic then																									--
					iconBackgroundImagePath = "Icons/OtherSkills/magic_blank.dds"																								--
				elseif skill.specialization == tes3.specialization.stealth then																									--
					iconBackgroundImagePath = "Icons/OtherSkills/stealth_blank.dds"																								--
				end																																								--
				local iconBackground = iconBlock:createImage({ id=tes3ui.registerID("OtherSkills:ttIconBackground"), path=iconBackgroundImagePath })							--
				iconBackground.layoutOriginFractionX = 0																														--
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
			---\
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				local icon = iconBlock:createImage({ id=tes3ui.registerID("OtherSkills:ttIconImage"), path=skill.icon})															--
				icon.autoHeight = true																																			--
				icon.autoWidth = true																																			--
				icon.layoutOriginFractionX = 0																																	--
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local topRightBlock = topBlock:createBlock({ id=tes3ui.registerID("OtherSkills:ttTopRightBlock") })																--
			topRightBlock.autoHeight = true																																	--
			topRightBlock.autoWidth = true																																	--
			topRightBlock.paddingLeft = 10																																	--
			topRightBlock.flowDirection = "top_to_bottom"																													--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			---\
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				local skillLabel = topRightBlock:createLabel({ id=tes3ui.registerID("OtherSkills:ttSkillLabel"), text = skill.name })											--
				skillLabel.autoHeight = true																																	--
				skillLabel.autoWidth = true																																		--
				skillLabel.color = tes3ui.getPalette("header_color")																											--
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
			---\
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				--e.g. "Governing Attribute: Strength"																															--
				local attributeText = ""																																		--
				if skill.attribute then																																			--
					local attributeGMST_ID = tes3.gmst.sAttributeStrength + skill.attribute																						--
					attributeText = tes3.findGMST( tes3.gmst.sGoverningAttribute ).value .. ": " .. tes3.findGMST( attributeGMST_ID ).value										--
				end																																								--
				local attributeLabel = topRightBlock:createLabel({ id=tes3ui.registerID("OtherSkills:ttAttributeLabel"), text = attributeText })								--
				------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
	---\	
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local midBlock = outerBlock:createBlock({ id=tes3ui.registerID("OtherSkills:ttMidBlock") })																		--
		midBlock.paddingTop = 10																																		--
		midBlock.paddingBottom = 10																																		--
		midBlock.autoHeight = true																																		--
		midBlock.width = 430																																			--
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local descriptionLabel = midBlock:createLabel({ id=tes3ui.registerID("OtherSkills:ttDescriptionLabel"), text=skill.description})								--
			descriptionLabel.wrapText = true																																--
			descriptionLabel.width = 445																																	--
			descriptionLabel.autoHeight = true																																--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
	---\		
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		local bottomBlock = outerBlock:createBlock({ id=tes3ui.registerID("OtherSkills:ttBottomBlock") })																--
		bottomBlock.autoHeight = true																																	--
		bottomBlock.widthProportional = 1.0																																--
		bottomBlock.flowDirection = "top_to_bottom"																														--
		bottomBlock.childAlignX = 0.5																																	--
		------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local progressLabel = bottomBlock:createLabel({ id=tes3ui.registerID("OtherSkills:ttProgressLabel"), text = tes3.findGMST(tes3.gmst.sSkillProgress).value })		--
			progressLabel.color = tes3ui.getPalette("header_color")																											--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
		---\
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			local progressBar = bottomBlock:createFillBar({ id=tes3ui.registerID("OtherSkills:ttProgressFillBar"), current=skill.progress, max = 100 })						--
			progressBar.borderTop = 4																																		--
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
end


----------------------------------------------------------------------------------------------------
local skillsListBlock
local outerSkillsBlock

--[[
	Refreshes the skills list in the stats menu whenver values change
	E.g on skill increase or adding new skills
]]--
this.updateSkillList = function ()
	debugMessage("Updating skill list")
	local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
	if not mainMenu then return end
	if not this.otherSkills then return end
	--make skills invisible until we have at least one skill

	
	if skillsListBlock and outerSkillsBlock then
		outerSkillsBlock.autoHeight = false
		outerSkillsBlock.height = 0
	
		skillsListBlock:destroyChildren()
		for i,skill in pairs(this.otherSkills) do
			if skill.active == "active" then
				outerSkillsBlock.autoHeight = true
				local skillsBlockID = "OtherSkills:skillBlock_" .. i
				local skillBlock = skillsListBlock:createBlock({id=tes3ui.registerID("OtherSkills:skillBlock") })
				if not skillBlock then return end
				skillBlock.layoutWidthFraction = 1.0
				skillBlock.flowDirection = "left_to_right"
				skillBlock.borderLeft = 10
				skillBlock.borderRight = 5
				skillBlock.autoHeight = true
				
				skillLabel = skillBlock:createLabel({ id=tes3ui.registerID("OtherSkills:skillLabel"), text = skill.name })
				skillLabel.layoutOriginFractionX = 0.0
				
				skillLevel = skillBlock:createLabel({ id=tes3ui.registerID("OtherSkills:skillValue"), text = tostring(skill.value) })
				skillLevel.layoutOriginFractionX = 1.0
				
				--Create skill Tooltip
				skillBlock:register("help", function() createSkillTooltip(skill) end )
			end
		end	
	end
	local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
	mainMenu:updateLayout()
end

--[[
	Create "Other Skills" list and place into the stats menu
	Populate it with the current list of other skills

]]--
local function createOuterSkillsBlock(e)
	debugMessage("Create outer skills block")
	if not e.element then return end
	
	--Navigate to the Skills block
	local miscBlock = e.element:findChild( tes3ui.registerID("MenuStat_misc_layout") )
	local parentSkillBlock = miscBlock.parent
	
	outerSkillsBlock = parentSkillBlock:createBlock({ id = tes3ui.registerID("OtherSkills:outerSkillsBlock") })
	outerSkillsBlock.autoHeight = true
	outerSkillsBlock.layoutWidthFraction = 1.0
	outerSkillsBlock.flowDirection = "top_to_bottom"
	
	local divider = outerSkillsBlock:createDivider({ id=tes3ui.registerID("OtherSkills:divider") })
	local headingBlock = outerSkillsBlock:createBlock({ id=tes3ui.registerID("OtherSkills:headingBlock") })
	--headingBlock.paddingTop = 4
	headingBlock.layoutWidthFraction = 1.0
	headingBlock.autoHeight = true

	local heading = headingBlock:createLabel({ id=tes3ui.registerID("OtherSkills:headingLabel") , text = "Other Skills"})
	heading.color = tes3ui.getPalette("header_color")
	skillsListBlock = outerSkillsBlock:createBlock({id=tes3ui.registerID("OtherSkills:skillsListBlock") })
	skillsListBlock.flowDirection = "top_to_bottom"
	skillsListBlock.layoutWidthFraction = 1.0
	skillsListBlock.autoHeight = true

	--move Other Skills section to right after Misc Skills
	parentSkillBlock:reorderChildren(32, outerSkillsBlock, -1)
	this.updateSkillList()
end

local function onLoaded(e)
	--Persistent data stored on player reference 
	-- ensure skills table exists
	local data = tes3.getPlayerRef().data
	data.otherSkills = data.otherSkills or {}
	-- create a public shortcut
	this.otherSkills = data.otherSkills
	
	--active mods call register skill to reactivate skills on load
	for i,val in pairs(this.otherSkills) do
		val.active = false
	end

	this.updateSkillList()
	event.trigger("OtherSkills:Ready")
	mwse.log("[SkillsModule INFO] OtherSkills.Common loaded successfully")
end

--register events
event.register("loaded", onLoaded)
event.register("uiRefreshed", function(e) createOuterSkillsBlock(e) end, {filter = "MenuStat_scroll_pane" } )


return this

