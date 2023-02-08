--[[ mc_common.lua - common functions (skill-based)
	part of Morrowind Crafting 3, Toccatta and Drac ]]--

	
local this = {}	
local skillModule = require("OtherSkills.skillModule")
local configPath = "Morrowind_Crafting_3"
local passValue
local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { 
        skillcaps = false,
		learningcurve = 5,
		casualmode = false,
		feedback = "Simple"
    }
end

this.skillList = {
	{	id = 				"mc_Smithing",
		name = 				"Smithing",
		altSkill = 			1,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Smithing.dds",
		attribute = 		tes3.attribute.strength,
		description = 		"Skill allows you to create and salvage weapons and armor from various materials.",
		specialization =	tes3.specialization.combat
	}, -- Armorer
	
	{	id = 				"mc_Fletching",
		name = 				"Fletching",
		altSkill = 			23,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Fletching.dds",
		attribute = 		tes3.attribute.willpower,
		description = 		"Skill allows you to create weapons that involve fletching such as arrows, crossbow bolts, and thrown darts.",
		specialization =	tes3.specialization.stealth
	}, -- Marksman
	
	{	id = 				"mc_Sewing",
		name = 				"Sewing",
		altSkill = 			11,
		trainerSkill= 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Sewing.dds",
		attribute = 		tes3.attribute.personality,
		description = 		"Skill allows you to weave bolts of cloth, rugs and tapestries; sew clothing of cloth, animal hides and furs; create items such as pillows, sparring mats, bedrolls, bags and sacks.",
		specialization =	tes3.specialization.stealth
	}, -- Alteration
						
	{	id = 				"mc_Crafting",
		name = 				"Crafting",
		altSkill = 			26,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Crafting.dds",
		attribute = 		tes3.attribute.agility,
		description = 		"Skill allows the creation of jewelry, glass, wickerware, lighting and even alchemical equipment.",
		specialization =	tes3.specialization.stealth
	}, -- Hand to Hand
	
	{	id = 				"mc_Metalworking",
		name= 				"Metalworking",
		altSkill = 			3,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Metalworking.dds",
		attribute = 		tes3.attribute.intelligence,
		description = 		"Skill allows the making of metal-based lights, furniture, chests, barrels and other metallic items.",
		specialization =	tes3.specialization.magic	
	}, -- Heavy Armor
					
	{	id = 				"mc_Masonry", 
		name = 				"Masonry",
		altSkill = 			0,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Masonry.dds",
		attribute = 		tes3.attribute.strength,
		description = 		"Skill gives you the ability to use clay, stone and other materials to create urns, culdems, bowls and other clay items.",
		specialization =	tes3.specialization.combat
	}, -- Block
	
	{	id = 				"mc_Mining",
		name = 				"Mining",
		altSkill = 			10,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Mining.dds",
		attribute = 		tes3.attribute.endurance,
		description = 		"Skill gives you the ability to mine ores and minerals from particular rocks and crystals, mostly found underground.",
		specialization =	tes3.specialization.combat
	}, -- Destruction
	
	{	id = 				"mc_Woodworking",
		name = 				"Woodworking",
		altSkill = 			6,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Woodworking.dds",
		attribute = 		tes3.attribute.intelligence,
		description = 		"Skill gives you the ability to build or carve various types of wooden furniture, containers, or decorations.",
		specialization =	tes3.specialization.magic	
	}, -- Axe
	
	{	id = 				"mc_Cooking",
		name = 				"Cooking",
		altSkill = 			16,
		trainerSkill = 		0,
		trainCost = 		0,
		icon = 				"Icons/mc/Skill_Cooking.dds",
		attribute = 		tes3.attribute.personality,
		description = 		"Skill gives you the ability to turn raw materials into delicious dishes, soups, breads and desserts, brew beverages, and prepare various medicines and toxins.",
		specialization =	tes3.specialization.magic
	} -- Alchemy
}

function this.traverse_dfs(root)
    local stack = {root}
    return function()
        local node = table.remove(stack)
        if node and node.children then
            for i=#node.children, 1, -1 do
                table.insert(stack, node.children[i])
            end
        end
        return node
    end
end
-- ********************************************************************************************************
function this.getAddInFiles(type, baseTable) -- baseTable comes from calling script
    local type = string.upper(type)
    local rec = {}
	local fName, fullPath
	local filePath = "Data Files\\MWSE\\mods\\Morrowind_Crafting_3\\AddIns"
	if (type ~= nil) then
	    for fName in lfs.dir(filePath) do
			if string.startswith(string.upper(fName),type) and string.endswith(string.upper(fName), ".LUA") then
				mwse.log("[MC3 Info] Found add-in file \""..fName.."\"")
				fName = string.gsub(fName, ".lua","")
				fullPath = "Morrowind_Crafting_3\\AddIns\\"..fName
 	    		rec = include(fullPath) -- get the new file
				if (rec ~= nil) then
					if (#rec > 0) then
	    	    		for idx, x in pairs(rec) do --for idx = 1, #rec do
	    	    			baseTable[#baseTable + 1] = rec[idx]
							--mwse.log("---- Adding '"..rec[idx].id.."'")
	    	   			end
					end
				end
			end
	    end
	end
	mwse.log("[MC3 Init] "..type..": "..#baseTable.." recipes")
	return baseTable
end

function this.getLowestVertex(root)
    local lowest_vertex = tes3vector3.new(0, 0, math.huge)
    for node in this.traverse_dfs(root) do
        local t = node.worldTransform
        if node.RTTI.name == "NiTriShape" then
            for i, vertex in ipairs(node.vertices) do
                vertex = t.rotation * vertex * t.scale + t.translation
                if vertex.z < lowest_vertex.z then
                    lowest_vertex = vertex
                end
            end
        end
    end
    return lowest_vertex
end

function this.dropSpot(spotTbl)
	local tPos = this.getLowestVertex(spotTbl.sceneNode)
	local rest
	rest = tes3.rayTest{ position = tPos, direction = tes3vector3.new(0, 0, -1) }
	if rest then
		return rest.intersection.z
	else
		return nil
	end
end

function this.qtySlider(maxNumber)
	local qty = -1
    this.id_SliderMenu = tes3ui.registerID("qtySlider")
    local testItem = "Slider" 
	local menu = tes3ui.createMenu{ id = this.id_SliderMenu, fixedFrame = true }
	passValue = -1
    menu.alpha = 0.75
	menu.text = "Crafting"
	menu.width = 400
	menu.height = 50
	menu.minWidth = 400
    menu.minHeight = 50

    local pBlock = menu:createBlock()
    pBlock.widthProportional = 1.0
    pBlock.heightProportional = 1.0
    pBlock.childAlignX = 0.5
    pBlock.flowDirection = "left_to_right"

	local slider = pBlock:createSlider({ current = maxNumber, min = 0, max = maxNumber, step = 1, jump = 5 })
	timer.delayOneFrame(function()
		slider:updateLayout()
	end)
    slider.widthProportional = 1.5
    pBlock.childAlignY = 0.6
    local sNumber = pBlock:createLabel({ text = "  ( "..string.format("%5.0f", 0).." )" })
    sNumber.widthProportional = 1.0
    sNumber.height = 24
    local sOK = pBlock:createButton({ text = " OK "})
    sOK.widthProportional = .5
    local sCancel = pBlock:createButton({ text = "Cancel" })
    sCancel.widthProportional = 1.0

    slider:register("PartScrollBar_changed", function(e)
        --testItem = slider:getPropertyInt("PartScrollBar_current") + 1 --params.min
        sNumber.text = string.format("  ( %5.0f", slider:getPropertyInt("PartScrollBar_current")).." )"
        passValue = slider:getPropertyInt("PartScrollBar_current")
        end) 
    sCancel:register("mouseClick",
        function()
            tes3ui.leaveMenuMode()
            menu:destroy()
			passValue = 0
			qty = -1
            return false
        end
        )
    sOK: register("mouseClick", 
        function()
            tes3ui.leaveMenuMode()
            menu:destroy()
			passValue = qty
			qty = -1
            return false
        end
        )
    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_SliderMenu)
end

function this.getSliderQty(highestNum)
	return passValue
end

function this.getVersion()
	return 3.0
end

function this.fetchAttr(attrName) -- Fetches value of a player's attribute
	local stuff = { 
			base = tes3.mobilePlayer.attributes[tes3.attribute[attrName] + 1].base,
			current = tes3.mobilePlayer.attributes[tes3.attribute[attrName] + 1].current
			}
	return stuff
end

function this.calcAttr()	-- Returns player's calculated stats & modifiers for crafting
	local stuff =  {
		baseFatigue = math.floor(tes3.mobilePlayer.fatigue.base), 
		currFatigue = math.floor(tes3.mobilePlayer.fatigue.current),
		modFatigue = math.min((tes3.mobilePlayer.fatigue.current / math.max(tes3.mobilePlayer.fatigue.base, 1) ), 1.2),
		baseHealth = tes3.mobilePlayer.health.base,
		currHealth = math.floor(tes3.mobilePlayer.health.current),
		ratioHealth = tes3.mobilePlayer.health.current / tes3.mobilePlayer.health.base,
		modLuck = math.min(((90 + ( tes3.mobilePlayer.attributes[tes3.attribute.luck + 1 ].current / 5 )) / 100) , 1.3),
		--modHealth = math.min((tes3.mobilePlayer.health.current / tes3.mobilePlayer.health.base) * 2, 1),
		modHealth = math.min((2 * (tes3.mobilePlayer.health.current / tes3.mobilePlayer.health.base)), 1.0),
		modInt = math.max((120 / (80 + tes3.mobilePlayer.attributes[tes3.attribute.intelligence + 1].current)), 1),
		modAgi = math.max((120 / (80 + tes3.mobilePlayer.attributes[tes3.attribute.agility + 1].current)), 1),
	 	}
	return stuff
end

function this.getSkill(skillName)
	if tes3.skill[skillName] then
		return tes3.mobilePlayer.skills[tes3.skill[skillName] + 1]
	else
		return { base = skillModule.getSkill(skillName).value, current = skillModule.getSkill(skillName).value }
	end
end

function this.fetchSkill(skillName)
	return this.getSkill(skillName).current
end

function this.fetchMagicka()
	return math.floor(tes3.mobilePlayer.magicka.current)
end

function this.skillReward(skillID, skillLevel, difficulty, reward)
	local skillFalloff = 50 -- the difference between skill and difficulty where the player no longer gets training
	local trainBase = config.learningcurve
	local effDifficulty = difficulty * this.calcAttr().modInt * this.calcAttr().modAgi
	local modReward = math.max(((skillFalloff - skillLevel + effDifficulty) / skillFalloff),0) ^2
	local training = (trainBase * modReward) / (skillLevel + 1 ) * 100
	if config.casualmode == false then
		if (config.skillcaps == true and skillLevel < 100) or (config.skillcaps == false) then
			if string.startswith(skillID, "mc_") then
				skillModule.incrementSkill( skillID, {progress = training} )
				tes3.runLegacyScript{ command = "set "..skillID.." to "..this.fetchSkill(skillID)}
				--[[
				if skillID == "mc_Smithing" then
					tes3.runLegacyScript{ command = "set mc_smithing to "..this.fetchSkill("mc_Smithing")}
				elseif skillID == "mc_Mining" then
					tes3.runLegacyScript{ command = "set mc_Mining to "..this.fetchSkill("mc_Mining")}
				elseif skillID == "mc_Cooking" then
					tes3.runLegacyScript{ command = "set mc_Cooking to "..this.fetchSkill("mc_Cooking")}
				elseif skillID == "mc_Crafting" then
					tes3.runLegacyScript{ command = "set mc_Crafting to "..this.fetchSkill("mc_Crafting")}
				elseif skillID == "mc_Woodworking" then
					tes3.runLegacyScript{ command = "set mc_Woodworking to "..this.fetchSkill("mc_Woodworking")}
				elseif skillID == "mc_Sewing" then
					tes3.runLegacyScript{ command = "set mc_Sewing to "..this.fetchSkill("mc_Sewing")}
				elseif skillID == "mc_Fletching" then
					tes3.runLegacyScript{ command = "set mc_Fletching to "..this.fetchSkill("mc_Fletching")}
				elseif skillID == "mc_Metalworking" then
					tes3.runLegacyScript{ command = "set mc_Metalworking to "..this.fetchSkill("mc_Metalworking")}
				elseif skillID == "mc_Masonry" then
					tes3.runLegacyScript{ command = "set mc_Masonry to "..this.fetchSkill("mc_Masonry")}
				end
				]]
			else
				if reward then
					tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, reward)
				else
					mwse.log("Error in rewardSkill - reward = "..reward)
				end
			end
		end
	end
end

function this.skillIncrement(skillID, skillLevel)
	if (config.skillcaps == true and skillLevel < 100) or (config.skillcaps == false) then
		skillModule.incrementSkill( skillID, {progress = 100})
		if skillID == "mc_Smithing" then
			tes3.runLegacyScript{ command = "set mc_smithing to "..this.fetchSkill("mc_Smithing")}
		end
	end
end

function this.skillCheck(skillID, difficulty)
	config = mwse.loadConfig(configPath)
	local fateRoll = ((math.random(1,6001)-1)/10000)+0.8
	local skillValue = this.getSkill(skillID).current
	local effDifficulty = difficulty * this.calcAttr().modInt * this.calcAttr().modAgi
	local effSkill = skillValue * this.calcAttr().modHealth * this.calcAttr().modFatigue * this.calcAttr().modLuck * fateRoll
	local skillNonRand = skillValue * this.calcAttr().modHealth * this.calcAttr().modFatigue * this.calcAttr().modLuck
	local req_fate = effDifficulty / skillNonRand
	
	if config.casualmode == true then
		return true
	end
	
	if effSkill >= effDifficulty then
		return true
	else
		return false
	end
end

function this.ttChance(skillID, difficulty)
	config = mwse.loadConfig(configPath)
	local skillValue = this.getSkill(skillID).current
	local effDifficulty = difficulty * this.calcAttr().modInt * this.calcAttr().modAgi
	local skillNonRand = skillValue * this.calcAttr().modHealth * this.calcAttr().modFatigue * this.calcAttr().modLuck
	local req_fate = effDifficulty / skillNonRand
	
	if config.casualmode == true then
		return "Casual mode"
	end	
	if difficulty < 1 then
		return "Automatic"
	end
	if config.feedback == "Off" then
		return "?"
	elseif config.feedback == "Simple" then
		if req_fate > 1.4 then
			return "Impossible"
		elseif req_fate >  1.3 then
			return "Bad"
		elseif req_fate > 1.2 then
			return "Poor"
		elseif req_fate > 1.1 then
			return "Low"
		elseif req_fate > 1.0 then
			return "Reasonable"
		elseif req_fate > 0.9 then
			return "Good"
		elseif req_fate > 0.8 then
			return "High"
		elseif req_fate <= 0.8 then
			return "Guaranteed"
		else 
			return "Error"
		end
	elseif config.feedback == "Detailed" then
		return string.format("%.0f%%", math.max(math.min((1 - (( req_fate - 0.8 ) / 0.6 )) * 100,100), 0))
	else
		return "Feedback error!"
	end
end

function this.countKindling()
	local x = mwscript.getItemCount({ reference = "player", item = "mc_straw" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_fiber" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_coarsefiber" })
	return x
end

function this.removeKindling(count)
    for idx = 1, count do
        if mwscript.getItemCount({ reference = "player", item = "mc_straw" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_straw", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "mc_coarsefiber" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "mc_coarsefiber", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_fiber" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "mc_fiber", count = 1, playSound = false })
		else
            mwse.log("Bad kindling count for fires")
            break
        end
	end
end

function this.countLogs()
	local x = mwscript.getItemCount({ reference = "player", item = "mc_log_scrap" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_ash" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_cypress" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_hickory" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_oak" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_parasol" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_pine" })
		+ mwscript.getItemCount({ reference = "player", item = "mc_log_swirlwood" })
	return x
end

function this.removeLogs(count)
    for idx = 1, count do
        if mwscript.getItemCount({ reference = "player", item = "mc_log_scrap" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_log_scrap", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "mc_log_ash" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "mc_log_ash", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_log_pine" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "mc_log_pine", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_log_parasol" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_log_parasol", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_log_hickory" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_log_hickory", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_log_oak" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_log_oak", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_log_cypress" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_log_cypress", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_log_swirlwood" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_log_swirlwood", count = 1, playSound = false })
        else
            mwse.log("Bad wood count for fires")
            break
        end
	end
end

function this.countRedMeat()
	local x = mwscript.getItemCount({ reference = "player", item = "ingred_rat_meat_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatGuar_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatKagouti_01" })
		+ mwscript.getItemCount({ reference = "player", item = "ingred_hound_meat_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatAlit_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatBoar_02" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatMutton_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatKwama_01" })
	return x
end

function this.removeRedMeat(count)
    for idx = 1, count do
        if mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatMutton_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatMutton_01", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatKwama_01" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatKwama_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatBoar_01" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatBoar_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatBoar_02" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatBoar_02", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatAlit_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatAlit_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatKagouti_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatKagouti_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFood_MeatGuar_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_MeatGuar_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "ingred_hound_meat_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "ingred_hound_meat_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "ingred_rat_meat_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "ingred_rat_meat_01", count = 1, playSound = false })
        else
            mwse.log("Bad meat count for cooking")
            break
        end
	end
end

function this.countGarlic()
	local x = mwscript.getItemCount({ reference = "player", item = "mc_garlic" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_Garlic_01" })
	return x
end

function this.removeGarlic(count)
    for idx = 1, count do
		if mwscript.getItemCount({ reference = "player", item = "T_IngFood_Garlic_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_Garlic_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_garlic" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_garlic", count = 1, playSound = false })
		else
			mwse.log("Bad garlic count for cooking")
			break
		end
	end
end

function this.countOnion()
	local x = mwscript.getItemCount({ reference = "player", item = "mc_Onion" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_Onion_01" })
	return x
end

function this.removeOnion(count)
    for idx = 1, count do
		if mwscript.getItemCount({ reference = "player", item = "T_IngFood_Onion_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_Onion_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_Onion" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_Onion", count = 1, playSound = false })
		else
			mwse.log("Bad onion count for cooking")
			break
		end
	end
end

function this.countPotato()
	local x = mwscript.getItemCount({ reference = "player", item = "mc_potato_raw" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFood_Potato_01" })
	return x
end

function this.removePotato(count)
    for idx = 1, count do
		if mwscript.getItemCount({ reference = "player", item = "T_IngFood_Potato_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFood_Potato_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "mc_potato_raw" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "mc_potato_raw", count = 1, playSound = false })
		else
			mwse.log("Bad onion count for cooking")
			break
		end
	end
end

function this.countSmallBowl()
	local x = mwscript.getItemCount({ reference = "player", item = "misc_com_wood_bowl_01" })
		+ mwscript.getItemCount({ reference = "player", item = "misc_com_wood_bowl_02" })
		+ mwscript.getItemCount({ reference = "player", item = "misc_com_wood_bowl_03" })
	return x
end

function this.removeSmallBowl(count)
    for idx = 1, count do
        if mwscript.getItemCount({ reference = "player", item = "misc_com_wood_bowl_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "misc_com_wood_bowl_01", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "Misc_com_wood_bowl_02" }) > 0 then
			tes3.removeItem({ reference = tes3.player, item = "Misc_com_wood_bowl_02", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "Misc_com_wood_bowl_03" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "Misc_com_wood_bowl_03", count = 1, playSound = false })
        else
            mwse.log("Bad bowl count for cooking")
            break
        end
	end
end

function this.countKwamaEgg()
	local x = mwscript.getItemCount({ reference = "player", item = "food_kwama_egg_01" })
		+ mwscript.getItemCount({ reference = "player", item = "food_kwama_egg_02" })
	return x
end

function this.removeKwamaEgg(count)
    for idx = 1, count do
        if mwscript.getItemCount({ reference = "player", item = "food_kwama_egg_02" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "food_kwama_egg_02", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "food_kwama_egg_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "food_kwama_egg_01", count = 1, playSound = false })
        else
            mwse.log("Bad egg count")
            break
        end
	end
end

function this.countMushroom()
	local x = mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Bluefoot_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_TempleDome_01" })
		+ mwscript.getItemCount({ reference = "player", item = "ingred_bc_bungler's_bane" })
		+ mwscript.getItemCount({ reference = "player", item = "ingred_bc_hypha_facia" })
		+ mwscript.getItemCount({ reference = "player", item = "ingred_coprinus_01" })
		+ mwscript.getItemCount({ reference = "player", item = "ingred_russula_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_AnemicTwinstipe_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_BlacksporeCap_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_BogBeacon_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CairnBolete_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CinnabarPolypore_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CinnabarPolypore_02" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CloudedFunnel_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Cupling_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_DryadSaddle_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Elfcup_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_EmeticRussula_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Greenstain_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_PyrousUracia" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_RustRussula_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Steelblue_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_SummerBolete_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_TinderPolypore_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Stinkhorn_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_UmberMorchella_01" })
		+ mwscript.getItemCount({ reference = "player", item = "T_IngFlor_VileMorchella_01" })
	return x
end

function this.removeMushroom(count)
    for idx = 1, count do
        if mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Bluefoot_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_Bluefoot_01", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_TempleDome_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_TempleDome_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_AnemicTwinstipe_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_AnemicTwinstipe_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_BlacksporeCap_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_BlacksporeCap_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_BogBeacon_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_BogBeacon_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CairnBolete_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_CairnBolete_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CinnabarPolypore_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_CinnabarPolypore_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CinnabarPolypore_02" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_CinnabarPolypore_02", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_CloudedFunnel_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_CloudedFunnel_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Cupling_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_Cupling_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_DryadSaddle_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_DryadSaddle_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Elfcup_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_Elfcup_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_EmeticRussula_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_EmeticRussula_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Greenstain_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_Greenstain_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_PyrousUracia" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_PyrousUracia", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_RustRussula_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_RustRussula_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Steelblue_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_Steelblue_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_SummerBolete_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_SummerBolete_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_TinderPolypore_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_TinderPolypore_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_Stinkhorn_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_Stinkhorn_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_UmberMorchella_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_UmberMorchella_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "T_IngFlor_VileMorchella_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "T_IngFlor_VileMorchella_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "ingred_bc_bungler's_bane" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "ingred_bc_bungler's_bane", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "ingred_bc_hypha_facia" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "ingred_bc_hypha_facia", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "ingred_coprinus_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "ingred_coprinus_01", count = 1, playSound = false })
		elseif mwscript.getItemCount({ reference = "player", item = "ingred_russula_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "ingred_russula_01", count = 1, playSound = false })
        else
            mwse.log("Bad mushroom count")
            break
        end
    end
end



function this.removeSoulGem(soul)
	local removed = false
	local inventory = tes3.player.object.inventory
	local azura = mwscript.getItemCount({ reference = "player", item = "Misc_SoulGem_Azura" })
	if (type(soul) == "string") then
		soul = assert(tes3.getObject(soul))
	end
	for _, stack in pairs(inventory) do
		if (stack.variables) then
			for i, vars in pairs(stack.variables) do
				if vars then
					if vars.soul == soul then
						tes3.removeItem({ reference = tes3.player, item = stack.object.id, itemData = vars, playSound = false })
						if mwscript.getItemCount({ reference = "player", item = "Misc_SoulGem_Azura" }) ~= azura then
							tes3.addItem({ reference = tes3.player, item = "Misc_SoulGem_Azura", count = 1, playSound = false })
							tes3ui.forcePlayerInventoryUpdate()
						end
						removed = true
						break
					end
				end
            end
        end
		if removed == true then
			break
		end
    end
	return removed
end

function this.removeFrostSoul()
	if this.removeSoulGem("atronach_frost") then
	elseif this.removeSoulGem("atronach_frost_summon") then
	end
end

function this.removeDremoraSoul()
	if this.removeSoulGem("T_Dae_Cre_DremLorCyr_01") then
	elseif this.removeSoulGem("dremora") then
	elseif this.removeSoulGem("dremora_gothren_guard1") then
	elseif this.removeSoulGem("dremora_gothren_guard2") then
	elseif this.removeSoulGem("T_Dae_Cre_DremCyr_01") then
	elseif this.removeSoulGem("T_Dae_Cre_DremKynv_01") then
	elseif this.removeSoulGem("T_Dae_Cre_DremKynr_01") then
	elseif this.removeSoulGem("T_Dae_Cre_DremCait_01") then
	elseif this.removeSoulGem("dremora_lord") then
	elseif this.removeSoulGem("dremora_summon") then
	elseif this.removeSoulGem("T_Dae_Cre_Drem_Arch_01") then
	elseif this.removeSoulGem("T_Dae_Cre_Drem_Cast_01") then
	end
end

function this.countFrostSouls()
	local ttl = this.countSoulGems(tes3.player.object.inventory, "atronach_frost") 
		+ this.countSoulGems(tes3.player.object.inventory, "atronach_frost_summon") 
	return ttl
end

function this.countDremoraSouls()
	local ttl = this.countSoulGems(tes3.player.object.inventory, "dremora")
		+ this.countSoulGems(tes3.player.object.inventory, "dremora_lord")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_DremCait_01")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_DremKynr_01")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_DremKynv_01")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_DremCyr_01")
		+ this.countSoulGems(tes3.player.object.inventory, "dremora_summon")
		+ this.countSoulGems(tes3.player.object.inventory, "dremora_gothren_guard1")
		+ this.countSoulGems(tes3.player.object.inventory, "dremora_gothren_guard2")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_DremLorCyr_01")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_Drem_Arch_01")
		+ this.countSoulGems(tes3.player.object.inventory, "T_Dae_Cre_Drem_Cast_01")
	return ttl
end

function this.countSoulGems(inventory, soul)
	if (type(soul) == "string") then
		soul = assert(tes3.getObject(soul))
	end	
    local count = 0
    for _, stack in pairs(inventory) do
        if (stack.variables) then
            for i, vars in pairs(stack.variables) do
				if vars ~= nil then
                	if vars.soul == soul then
                    	count = count + 1
                	end
				end
            end
        end
    end
    return count
end

function this.ttDifficulty(difficulty)
	config = mwse.loadConfig(configPath)
	if config.casualmode == true then
		return "Casual mode"
	end	
	if difficulty < 1 then
		return "Automatic"
	end	
	if config.feedback == "Off" then
		return "?"
	elseif config.feedback == "Simple" then
		if difficulty < 5 then
			return "Trivial"
		elseif difficulty < 15 then
			return "Junior Apprentice"
		elseif difficulty < 25 then
			return "Senior Apprentice"
		elseif difficulty < 37 then
			return "Junior Journeyman"
		elseif difficulty < 50 then
			return "Senior Journeyman"
		elseif difficulty < 62 then
			return "Junior Master"
		elseif difficulty < 75 then
			return "Senior Master"
		elseif difficulty < 87 then
			return "Junior Grandmaster"
		elseif difficulty < 100 then
			return "Senior Grandmaster"
		elseif difficulty < 125 then
			return "Secretmaster"
		elseif difficulty >= 125 then
			return "Epic"
		else
			return "Difficulty error!"
		end
	elseif config.feedback == "Detailed" then
		return string.format("%d", difficulty)
	else
		return "Feedback error!"
	end
end

function this.timePass(howLong)
	config = mwse.loadConfig(configPath)
	--local cal = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 30, 31, 31 }
	--local pday = tes3.findGlobal("Day")
	--local pmonth = tes3.findGlobal("Month")
	--local pyear = tes3.findGlobal("Year")
	--local pdaysPassed = tes3.findGlobal("DaysPassed")
	--local phour = tes3.findGlobal("GameHour")
	--local day = pday.value
	--local month = pmonth.value
	--local year = pyear.value
	--local daysPassed = pdaysPassed.value
	--local hour = phour.value
	--local fader = 1 -- math.min(math.floor(howLong), 3) -- how many seconds fadeout/fadein take... max 3 each
	--if config.tasktime == true then
	--	hour = hour + howLong -- howLong figured in hours and fractions of an hour   1-1/2 = 1.5, etc
	--	if hour > 24 then
	--		hour = hour - 24
	--		day = day + 1
	--		daysPassed = daysPassed + 1
	--		if day > cal[month + 1] then
	--			day = 1
	--			month = month + 1
	--			if month > 11 then
	--				year = year + 1
	--				month = 0
	--			end
	--		end
	--	end
	if config.tasktime == true then
		tes3.advanceTime({ hours = howLong })
		if howLong >= 0.5 then
			local fader = 1
			tes3.runLegacyScript({command = "DisablePlayerControls"})
			mc3_timeOut = 1
			tes3.fadeOut({ duration = fader })
			tes3.fadeIn({ duration = fader })
			timer.start({ 
				type = timer.real, 
				iterations = 1,
				duration = ( fader * 2 ), 
				callback = (
					function()
						tes3.runLegacyScript({command = "EnablePlayerControls"})
						mc3_timeOut = nil
					end	)
			 })
		
		end
	end
	--	phour.value = hour
	--	pday.value = day
	--	pdaysPassed.value = daysPassed
	--	pmonth.value = month
	--	pyear.value = year
	--end
end

local function isDeprecated(x) -- x = id of item to check for 'deprecated' status
    local ref = tes3.getObject(x)
	local dep = false

	if ref ~= nil then
		if string.lower(ref.name) == "<deprecated>" then
			dep = true
		end
	else
		dep = "Missing"
	end
	return dep
end

function this.cleanDeprecated(lst) -- lst = list to be cleaned of 'deprecated' items
	local out = {}
	for x,i in ipairs(lst) do
		if isDeprecated(i.id) ~= true then -- Good item, copy to output list
			out[#out + 1] = lst[x]
		elseif isDeprecated(i.id) == "Missing" then
			-- do nothing
		else
			mwse.log("Found deprecated: "..x.."  "..i.id)
		end
	end
	return out
end

function this.checkPotionTimePassed()
	if config.tasktime == true then
		this.timePass(2)
	end
end
event.register("potionBrewed", this.checkPotionTimePassed)

function this.uninstalling()
	if (mwscript.getItemCount({ reference = "player", item = "mc_carpentry_kit" }) > 0) and (tes3.findGlobal("mc_uninstall").value == 1) then
		return true
	else
		return false
	end
end

function this.getShift() 
	local inputController = tes3.worldController.inputController
    return (
        inputController:isKeyDown(tes3.scanCode.leftShift)
        or inputController:isKeyDown(tes3.scanCode.rightShift)
    )
end

function this.getAlt()
	local inputController = tes3.worldController.inputController
    return (
        inputController:isKeyDown(tes3.scanCode.leftAlt)
		or inputController:isKeyDown(tes3.scanCode.rightAlt)
	)
end

function this.getCtrl()
	local inputController = tes3.worldController.inputController
    return (
        inputController:isKeyDown(tes3.scanCode.leftCtrl)
		or inputController:isKeyDown(tes3.scanCode.rightCtrl)
	)
end

function this.playerAllowed(containerRef)
	--[[
	local owner = tes3.getOwner(containerRef)
	if (owner) then
		if (owner.playerJoined) then
			if (containerRef.attachments["variables"].requirement <= owner.playerRank) then
				return true
			end
		end
		return false
	end
	]]  -- uncomment this block if you want labelling owned objects to be disallowed
	return true
end

-- Define appropriate skills ---------------
local function onSkillReady()

	skillModule.registerSkill("mc_Smithing", 
	{	name 			=		"Smithing", 							 	--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Smithing.dds", 				--default: a circle icon
		attribute 		=		tes3.attribute.strength,					--optional
		description 	= 		this.skillList[1].description,				--optional
		specialization 	= 		tes3.specialization.combat,					--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Fletching", 
	{	name 			=		"Fletching", 							 	--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Fletching.dds", 			--default: a circle icon
		attribute 		=		tes3.attribute.willpower,					--optional
		description 	= 		this.skillList[2].description, 				--optional
		specialization 	= 		tes3.specialization.stealth,				--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Sewing", 
	{	name 			=		"Sewing", 							 		--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Sewing.dds", 				--default: a circle icon
		attribute 		=		tes3.attribute.personality,					--optional
		description 	= 		this.skillList[3].description,				--optional
		specialization 	= 		tes3.specialization.stealth,				--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Crafting", 
	{	name 			=		"Crafting", 							 	--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Crafting.dds", 				--default: a circle icon
		attribute 		=		tes3.attribute.agility,						--optional
		description 	= 		this.skillList[4].description, 				--optional
		specialization 	= 		tes3.specialization.stealth,				--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Metalworking", 
	{	name 			=		"Metalworking", 							--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Metalworking.dds", 			--default: a circle icon
		attribute 		=		tes3.attribute.intelligence,				--optional
		description 	= 		this.skillList[5].description, 				--optional
		specialization 	= 		tes3.specialization.magic,					--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Masonry", 
	{	name 			=		"Masonry", 							 		--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Masonry.dds", 				--default: a circle icon
		attribute 		=		tes3.attribute.strength,					--optional
		description 	= 		this.skillList[6].description,				--optional
		specialization 	= 		tes3.specialization.combat,					--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Mining", 
	{	name 			=		"Mining", 							 		--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Mining.dds", 				--default: a circle icon
		attribute 		=		tes3.attribute.endurance,					--optional
		description 	= 		this.skillList[7].description, 				--optional
		specialization 	= 		tes3.specialization.combat,					--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Woodworking", 
	{	name 			=		"Woodworking", 							 	--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Woodworking.dds", 			--default: a circle icon
		attribute 		=		tes3.attribute.intelligence,				--optional
		description 	= 		this.skillList[8].description, 				--optional
		specialization 	= 		tes3.specialization.magic,					--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

	skillModule.registerSkill("mc_Cooking", 
	{	name 			=		"Cooking", 							 		--default: skill id
		value			= 		5,											--default: 1
		progress		=		0, 											--default: 0
		lvlCap			=		1000, 										--default: 100	
		icon 			=		"Icons/mc/Skill_Cooking.dds", 				--default: a circle icon
		attribute 		=		tes3.attribute.personality,					--optional
		description 	= 		this.skillList[9].description, 				--optional
		specialization 	= 		tes3.specialization.magic,					--optional. Icon background is gray if none set
		active			=		"active"									--defaults to "active"
		}
	)

-- Now set a MW global to show that Lua is active.
tes3.setGlobal("mc_lua_enabled", 1)

end			
event.register("OtherSkills:Ready", onSkillReady)


--Now return the lot!
return this