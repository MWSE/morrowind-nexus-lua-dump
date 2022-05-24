--[[ Trainers lists for Morrowind Crafting
        2020 Drac and Toccatta ]]

        local mc = require("Morrowind_Crafting_3.mc_common")
        local configPath = "Morrowind_Crafting_3"
        local skillList = {}
        local id_menu, trainer, tClass, id_listPane, menuX, menuD
        id_menu = "CraftingTrainMenu"
        id_menu = tes3ui.registerID(id_menu)
        id_cancel = "buttonCancel"
        id_cancel = tes3ui.registerID(id_cancel)
        id_listPane = "skillPane"
        id_listPane = tes3ui.registerID(id_listPane)

        local config = mwse.loadConfig(configPath)
        if (config == nil) then
    	    config = { 
            skillcaps = false,
    	    learningcurve = 5,
    	    casualmode = false,
    	    feedback = "Simple"
            }
        end

       local function init()
            --[[ skillList = {
                {id = "mc_Cooking", name = "Cooking", altSkill = 16, trainerSkill = 0, trainCost = 0}, -- Alchemy
                {id = "mc_Masonry", name = "Masonry", altSkill = 0, trainerSkill = 0, trainCost = 0}, -- Block
                {id = "mc_Crafting", name = "Crafting", altSkill = 26, trainerSkill = 0, trainCost = 0}, -- Hand to Hand
                {id = "mc_Mining", name = "Mining", altSkill = 10, trainerSkill = 0, trainCost = 0}, -- Destruction
                {id = "mc_Smithing", name = "Smithing", altSkill = 1, trainerSkill = 0, trainCost = 0}, -- Armorer
                {id = "mc_Fletching", name = "Fletching", altSkill = 23, trainerSkill = 0, trainCost = 0}, -- Marksman
                {id = "mc_Woodworking", name = "Woodworking", altSkill = 6, trainerSkill = 0, trainCost = 0}, -- Axe
                {id = "mc_Sewing", name = "Sewing", altSkill = 11, trainerSkill = 0, trainCost = 0}, -- Alteration
                {id = "mc_Metalworking", name= "Metalworking", altSkill = 3, trainerSkill = 0, trainCost = 0} -- Heavy Armor
            } ]]
            skillList = mc.skillList
            mwse.log("MC Trainer startup initialized")
        end 
        
        local function byebye()
            ok = menuD:findChild("MenuDialog_button_bye")
            ok:triggerEvent("rightClick") 
        end

         --Cancel button
        local function onCancel(e)
            local menu = tes3ui.findMenu(id_menu)
            if (menu) then
                tes3ui.leaveMenuMode()
                menu:destroy()
                --return false
            end
            local menu = tes3ui.findMenu("MenuServiceTraining")
            local button = menu and menu:findChild("MenuServiceTraining_Okbutton")
            if button then
                button:triggerEvent("mouseClick")
            end
        end

        local function sortBySkill(a, b) -- Sort by trainerSkill, highest first
            if a.trainerSkill < b.trainerSkill then
                return false
            elseif a.trainerSkill > b.trainerSkill then
                return true
            else
                return a.trainerSkill > b.trainerSkill
            end
        end

        local function showTrainingTooltip(e)
            local idx = e.source:getPropertyInt("CraftingTrainMenu:Index")
	        local tooltip = tes3ui.createTooltipMenu()
            local outerBlock = tooltip:createBlock({ id=tes3ui.registerID("CraftOuterBlock") })
	        outerBlock.flowDirection = "top_to_bottom"
	        outerBlock.paddingTop = 6
	        outerBlock.paddingBottom = 12
	        outerBlock.paddingLeft = 6
	        outerBlock.paddingRight = 6
	        outerBlock.autoWidth = true
	        outerBlock.autoHeight = true
            local topBlock = outerBlock:createBlock({ id=tes3ui.registerID("CraftTopBlock") })																		--
            topBlock.autoHeight = true																																		--
            topBlock.autoWidth = true
            local iconBlock = topBlock:createBlock({})																														--
			iconBlock.height = 32																																			--
			iconBlock.width = 32																																			--
			iconBlock.flowDirection = "left_to_right"																														--
			iconBlock.borderTop = 2
            --
            local iconBackgroundImagePath = "Icons/OtherSkills/default_blank.dds"																							--
				if skillList[idx].specialization == tes3.specialization.combat then																										--
					iconBackgroundImagePath = "Icons/OtherSkills/combat_blank.dds"																								--
				elseif skillList[idx].specialization == tes3.specialization.magic then																									--
					iconBackgroundImagePath = "Icons/OtherSkills/magic_blank.dds"																								--
				elseif skillList[idx].specialization == tes3.specialization.stealth then																									--
					iconBackgroundImagePath = "Icons/OtherSkills/stealth_blank.dds"																								--
				end																																								--
			local iconBackground = iconBlock:createImage({ id=tes3ui.registerID("CraftIconBackground"), path=iconBackgroundImagePath })							--
			iconBackground.layoutOriginFractionX = 0
            local icon = iconBlock:createImage({ id=tes3ui.registerID("OtherSkills:ttIconImage"), path=skillList[idx].icon})															--
			icon.autoHeight = true																																			--
			icon.autoWidth = true																																			--
			icon.layoutOriginFractionX = 0
            local topRightBlock = topBlock:createBlock({ id=tes3ui.registerID("CraftTopRightBlock") })																--
			topRightBlock.autoHeight = true																																	--
			topRightBlock.autoWidth = true																																	--
			topRightBlock.paddingLeft = 10																																	--
			topRightBlock.flowDirection = "top_to_bottom"
            local skillLabel = topRightBlock:createLabel({ id=tes3ui.registerID("CraftSkillLabel"), text = skillList[idx].name })											--
			skillLabel.autoHeight = true																																	--
			skillLabel.autoWidth = true																																		--
			skillLabel.color = tes3ui.getPalette("header_color")
            local attributeText = ""																																		--
			if skillList[idx].attribute then																																			--
				local attributeGMST_ID = tes3.gmst.sAttributeStrength + skillList[idx].attribute																						--
				attributeText = tes3.findGMST( tes3.gmst.sGoverningAttribute ).value .. ": " .. tes3.findGMST( attributeGMST_ID ).value										--
			end																																								--
			local attributeLabel = topRightBlock:createLabel({ id=tes3ui.registerID("CraftAttributeLabel"), text = attributeText })
            local bottomBlock = outerBlock:createBlock({ id=tes3ui.registerID("CraftbottomBlock") })																		--
	    	bottomBlock.paddingTop = 10																																		--
	    	bottomBlock.paddingBottom = 10																																		--
	    	bottomBlock.autoHeight = true																																		--
	    	bottomBlock.width = 430
            local descriptionLabel = bottomBlock:createLabel({ id=tes3ui.registerID("CraftDescriptionLabel"), text=skillList[idx].description})								--
			descriptionLabel.wrapText = true																																--
			descriptionLabel.width = 445																																	--
			descriptionLabel.autoHeight = true	
        end

        local function doTraining(e)
            if trainer ~= nil then
                local idx = e.source:getPropertyInt("CraftingTrainMenu:Index")
		        local plrSkill = mc.fetchSkill(skillList[idx].id)
                if plrSkill >= skillList[idx].trainerSkill then
                    tes3.messageBox("I can teach nothing more about that skill "..idx)
                else
                    -- do training
                    mc.skillIncrement(skillList[idx].id, plrSkill)
                    tes3.removeItem({ reference = tes3.player, item = "gold_001", count = skillList[idx].trainCost , playSound = false })
                    tes3.advanceTime({ hours = 1 })
                    local fader = 1
                    tes3.runLegacyScript({command = "DisablePlayerControls"})
                    tes3.fadeOut({duration = 1})
                    tes3.fadeIn({duration = 1})
                    timer.start({type = timer.real, iterations = 1, duration = 1, callback = (function()
                        tes3.runLegacyScript({command = "EnablePlayerControls"})
                    end)})
                    local menu = tes3ui.findMenu("MenuServiceTraining")
                    local button = menu and menu:findChild("MenuServiceTraining_Okbutton")
                    if button then
                        button:triggerEvent("mouseClick")
                    end
                    local menu = tes3ui.findMenu("MenuDialog")
                    local button = menu and menu:findChild("MenuDialog_button_bye")
                    if button then
                        button:triggerEvent("mouseClick")
                    end
                    local menu = tes3ui.findMenu(id_menu)
                    if (menu) then
                        tes3ui.leaveMenuMode()
                        menu:destroy()
                        return false
                    end
                end
            end
        end
        
        local function getTrainer(e)
            trainer = e.mobile
        end

        local function createWindow()
            -- skillList holds output of skillID, skillName, skillCost (3 rows)
            if (tes3ui.findMenu(id_menu) ~= nil) then
                return
            end
            tes3ui.enterMenuMode()
            local menu = tes3ui.createMenu{ id = id_menu, fixedFrame = true }
            menu.width = 320
            menu.height = 200
            menu.autoHeight = true
            menu.minWidth = 320
            menu.minHeight = 200
            --menu.minHeight = 60
            menu.positionX = menu.width / -2
            menu.positionY = menu.height / 2
            menu.flowDirection = "top_to_bottom"
            menu.widthProportional = 1.0
            local filterBlock = menu:createBlock({})
		    filterBlock.widthProportional = 1.0
		    filterBlock.flowDirection = "left_to_right"
		    filterBlock.autoHeight = true
		    filterBlock.childAlignX = 0.5
            local filterLabel = filterBlock:createLabel({ text = tes3.findGMST("sTraining").value})
            filterLabel.color = tes3ui.getPalette("header_color")
            local menuBlock = menu:createBlock({})
            menuBlock.widthProportional = 1.0
		    menuBlock.flowDirection = "left_to_right"
		    menuBlock.autoHeight = true
		    menuBlock.childAlignX = 0.0
            local filterLabel = menuBlock:createLabel({ text = tes3.findGMST("sTrainingServiceTitle").value})
            local listBlock = menu:createVerticalScrollPane({})
            listBlock.flowDirection = "left_to_right"
            listBlock.autoHeight = true
            listBlock.childAlignX = 0
            local playerGold = tes3.getPlayerGold()
            -- get skill rows 1-3
            for index = 1, 3 do
                local skillBlock = listBlock:createBlock({})
                skillBlock.widthProportional = 1.0
                skillBlock.flowDirection = "left_to_right"
                skillBlock.autoHeight = true
                skillBlock.childAlignX = 0
                local skill1 = skillBlock:createLabel({ text = skillList[index].name.."  - "..skillList[index].trainCost..tes3.findGMST("sgp").value })
                skillBlock:setPropertyInt("CraftingTrainMenu:Index", index)
                if skillList[index].trainCost > playerGold then
                    skill1.color = tes3ui.getPalette("disabled_color")
                    skillBlock:register("help", showTrainingTooltip)
                else
                    skillBlock:register("mouseClick", doTraining)
                    skillBlock:register("help", showTrainingTooltip)
                end
            end

            local okBlock = menu:createBlock{}
            okBlock.widthProportional = 1.0
            okBlock.flowDirection = "left_to_right"
            okBlock.autoHeight = true
            okBlock.childAlignX =-1.0
            local goldLabel = okBlock:createLabel({ text = tes3.findGMST("sGold").value..": "..playerGold})
            local buttonCancel = okBlock:createButton{ id = id_cancel, text = tes3.findGMST("sOK").value }
            menu:updateLayout()
            buttonCancel:register("mouseClick", onCancel)
        end

        local function grabSkills(e) -- Pass in trainer-reference, need 3 rows of 3 items each; mc_SkillID, skillName, trainerLevel, trainingCost)
            menuX = e.element
            tClass = tes3ui.getServiceActor().object.class
            if (tClass.name == "Craftsman") or (tClass.name == "MC_Agent") then
                if (menuX) then
                    menuX.visible = false
                end
                local pMerc, tMerc, tDisp, cost, skillLvl, playerSkill
                pMerc = tes3.mobilePlayer.mercantile.current
                --trainer = tes3.getPlayerTarget()
                tMerc = trainer:getSkillStatistic(24).current -- 24 = mercantile
                tDisp = tes3ui.getServiceActor().object.disposition
                for i, x in ipairs(skillList) do -- Fetch trainer's skill, then calc cost for a new level
                    x.trainerSkill = trainer:getSkillStatistic(x.altSkill).current
                    -- Now get player's skill in the current Crafting skill, run through calcs to determine cost for *next* level (current + 1)
                    playerSkill = mc.fetchSkill(x.id)
                    x.trainCost = math.floor(0.93 + (0.062 * (200 - pMerc + tMerc - tDisp) * (playerSkill + 1)))
                end
                -- Now sort skillList, highest trainerSkill downward
                --table.sort(skillList, sortBySkills)
                table.sort(skillList, function(k1, k2) return k1.trainerSkill > k2.trainerSkill end )
                local menu= tes3ui.findMenu("MenuDialog")
                menu.visible=false
                --menu:destroy()
                createWindow()
            else
                menuX.visible = true
                if (menu) then
                    menu.visible = true
                end
            end
        end

        local function storeDialogID(e)
            menuD = e.element
        end
    
        event.register("initialized", init)
        event.register("uiActivated", grabSkills, { filter = "MenuServiceTraining" })
        event.register("calcTrainingPrice", getTrainer)
        event.register("uiActivated", storeDialogID, { filter = "MenuDialog"})