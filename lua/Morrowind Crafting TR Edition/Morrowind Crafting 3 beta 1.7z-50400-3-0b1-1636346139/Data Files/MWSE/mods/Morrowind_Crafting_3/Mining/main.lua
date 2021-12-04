--[[ Script for mining materials from particular rocks/crystals
	Includes adamantium, iron and silver ores, raw glass, raw ebony, stahlrim
	part of Morrowind Crafting 3
	Toccatta and Drac  c/r 2019 ]]--
	
local mc = require("Morrowind_Crafting_3.mc_common")
local skillModule = require("OtherSkills.skillModule")
local recipes = require("Morrowind_Crafting_3.Mining.recipes")
local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

local this = {}
local thing, itemID, skillID, itemObject, skillValue, numberMaterial, menu, recipeNum, hasPick, hasNordPick
local difficulty, oreType, taskTime, labelText, skipActivate
local isCollectingOre = false
skillID = "mc_Mining"

-- initializations
function this.init()
	this.id_menu = tes3ui.registerID("mining_menu")
	this.button_1 = tes3ui.registerID("mining_collect_button")
	this.button_2 = tes3ui.registerID("mining_fast_collect_button")
	this.button_3 = tes3ui.registerID("mining_cancel_button")
	this.miningBlock = tes3ui.registerID("MiningBlock")
end

local function tryDestroyID(tooltip, uiid)
	local element = tooltip:findChild(tes3ui.registerID(uiid))
	if element ~= nil then
		element:destroy()
		return true
	end
	return false
end

local function forceInstance(reference)
    local object = reference.object
    if (object.isInstance == false) then
        --tes3.messageBox("Cloning object!!!")
        object:clone(reference)
        reference.modified = true 
    end 
    return reference --.object
end

function this.onCancel(e)
	menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
		menu = nil
	end
end

local function checkPickCondition()
	local weapon = tes3.mobilePlayer.readiedWeapon
	if weapon.variables.condition <= 0 then
		weapon.variables.condition = 0
		tes3.mobilePlayer:unequip({ item = weapon.object })
	end
end

local function extraTooltip(e)
	local label, miningBlock, miningDesc
	if e.object.objectType == tes3.objectType.container then
		if e.tooltip then 
			e.tooltip.flowDirection = "top_to_bottom"
			e.tooltip.autoHeight = true
		end
		if e.reference.data.mcMaterial then
			if e.reference.data.mcShattered == 0 then
				miningDesc = nil
				if e.reference.data.mcMaterial == 1 then
					miningDesc = "This deposit has been mined once."
				elseif e.reference.data.mcMaterial > 1 then
					miningDesc = "This deposit has been mined "..e.reference.data.mcMaterial.." times."
				end
			else
				miningDesc = "This deposit has been completely mined out."
			end
			if miningDesc ~= nil then
				miningBlock = e.tooltip:createBlock{id = this.miningBlock}
				miningBlock.autoHeight = true
				miningBlock.autoWidth = true
				miningBlock.paddingAllSides = 4
				label = miningBlock:createLabel{text = miningDesc}
			end
		end
	end
end

function this.onGather()
	local weapon
	local materialCap = math.floor((260/difficulty) + 1 )
	config = mwse.loadConfig(configPath)
	skillValue = mc.fetchSkill(skillID)
	if config.casualmode == true then
		materialCap = math.floor(100/difficulty)
	end
	numberMaterial = thing.data.mcMaterial
	if (mc.skillCheck(skillID, numberMaterial * difficulty) == true) and (numberMaterial < materialCap) then
		thing.data.mcMaterial = thing.data.mcMaterial + 1
		tes3.addItem{reference = thing, item = oreType, count = 1, playSound = false}
		tes3.playSound{ sound = "Repair", volume = 1.0, pitch = 1.0 }
		if config.casualmode ~= true then
			mc.skillReward(skillID, skillValue, numberMaterial * difficulty)
		end
		if config.animatedMining == true then
			weapon = tes3.mobilePlayer.readiedWeapon
			if weapon then 
				weapon.variables.condition = weapon.variables.condition - math.random(4)
				checkPickCondition()
			end
		end
		if (menu ~= nil) then
			menu:destroy()
			this.createWindow()
		end
	else -- failed skillcheck! Deposit is done!
		tes3.playSound{ sound = "critical damage", volume = 1.0, pitch = 1.0 }
		thing.data.mcShattered = 1
		timer.delayOneFrame(function()
			tes3.setGlobal("mc_skill_results", -1)
		end)
		if (menu) then
			menu:destroy()
			tes3ui.leaveMenuMode()
		end
		menu = nil
		return false
	end
	tes3ui.refreshTooltip()
end

function this.onFastGather()
	local doneFlag, weapon
	local materialCap = math.floor((260/difficulty) + 1)
	config = mwse.loadConfig(configPath)
	skillValue = mc.fetchSkill(skillID)
	if config.casualmode == true then
		materialCap = math.floor(100/difficulty)
	end
	tes3.playSound{ sound = "Repair", volume = 1.0, pitch = 1.0 }
	repeat
		numberMaterial = thing.data.mcMaterial
		if (mc.skillCheck(skillID, numberMaterial * difficulty) == true) and (numberMaterial < materialCap) then
			thing.data.mcMaterial = thing.data.mcMaterial + 1
			tes3.addItem{reference = thing, item = oreType, count = 1, playSound = false}
			if config.casualmode ~= true then
				mc.skillReward(skillID, skillValue, numberMaterial * difficulty)
			end
			if config.animatedMining == true then
				weapon = tes3.mobilePlayer.readiedWeapon
				if weapon then
					weapon.variables.condition = weapon.variables.condition - math.random(4)
					checkPickCondition()
					weapon = tes3.mobilePlayer.readiedWeapon
					if not weapon then
						doneFlag = true
					end
				end
			end
		else
			doneFlag = true
		end
	until(doneFlag == true)
	tes3.playSound{ sound = "critical damage", volume = 1.0, pitch = 1.0 }
	thing.data.mcShattered = 1
	timer.delayOneFrame(function()
		tes3.setGlobal("mc_skill_results", -1)
	end)
	if (menu) then
		menu:destroy()
		tes3ui.leaveMenuMode()
	end
	menu = nil
	tes3ui.refreshTooltip()
	return false
end

local function checkPick()
	local inventory = tes3.player.object.inventory
	if config.animatedMining ~= true then
		hasNordPick = inventory:contains("BM Nordic Pick")
	elseif tes3.mobilePlayer.readiedweapon ~= nil then
		if tes3.mobilePlayer.readiedWeapon.object.id == "BM Nordic Pick" then
			hasNordPick = true
		end
	else
		hasNordPick = false
	end
    local x = (
        hasNordPick
        or inventory:contains("miner's pick")
        or inventory:contains("TR_m1_q_DeliveryPick")
        or inventory:contains("TR_m1_q_DeliveryPickEx1")
        or inventory:contains("TR_m1_q_DeliveryPickEx2")
	)
	return x
end

function this.onAttack()
	config = mwse.loadConfig(configPath)
	if config.animatedMining == true then
		local viewThing = tes3.getPlayerTarget()
		if not ( viewThing) then
			return
		end
		hasPick = checkPick()
		if tes3.mobilePlayer then
			local rockID = viewThing.baseObject.id
			if tes3.mobilePlayer.readiedWeapon 
	        and (string.find(string.lower(tes3.mobilePlayer.readiedWeapon.object.id), " pick"))
	        and tes3.mobilePlayer.weaponReady
			and (config.animatedMining == true) then -- Okay, if we got this far, then time to check to see if a valid ore-source
				recipeNum = 0
				itemID = viewThing.baseObject.id
				for i, x in ipairs(recipes) do
					if itemID == recipes[i].id then
						recipeNum = i
						break
					end
				end
				if recipeNum and recipeNum ~= 0 then -- Valid mining ID!
					if recipes[recipeNum].oreType == "ingred_raw_stalhrim_01" and tes3.mobilePlayer.readiedWeapon.object.id ~= "BM Nordic Pick" then
					--if recipes[recipeNum].oreType == "ingred_raw_stalhrim_01" and hasNordPick ~= true then
						tes3.messageBox("You cannot mine stalhrim without a special form of pick.")
						return false
					end
					if not viewThing.data.bonusUsed then
						if recipes[recipeNum].bonus == true then
							tes3.addItem{reference = tes3.player, item = recipes[recipeNum].oreType, count = 1, playSound = false}
							tes3.playSound{ sound = "Repair", volume = 1.0, pitch = 1.0 }
							viewThing.data.bonusUsed = true
							tes3.messageBox(recipes[recipeNum].bonusMessage)
								if recipes[recipeNum].oreType == "ingred_raw_stalhrim_01" then
									if tes3.getJournalIndex{id="CO_8a"} == 30 then
										tes3.updateJournal{id="CO_8a", index=40}
									elseif tes3.getJournalIndex{id="CO_8"} == 30 then
										tes3.updateJournal{id="CO_8", index=40}
									end
								end															
							return false
						end
					end
					difficulty = recipes[recipeNum].difficulty
					oreType = recipes[recipeNum].oreType
					if not tes3.menuMode() then
						itemObject = forceInstance(viewThing)
						itemObject.modified = true
					end
					thing = viewThing -- .reference
					if not itemObject.data.mcMaterial then itemObject.data.mcMaterial = 0 end
					if not itemObject.data.mcShattered then itemObject.data.mcShattered = 0 end
					if mc.getShift() == true then
						this.onFastGather()
					else
						this.onGather()

					end
				end
			end
		end
	end
end

-- Create window & menu buttons
function this.createWindow()
	-- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	skillID = "mc_Mining"
	skillValue = mc.fetchSkill(skillID)
	numberMaterial = thing.data.mcMaterial
	if not numberMaterial then
		mwse.log("Mining error; no 'material' variable in script, or no script ("..thing.object.id..")")
	end
	if numberMaterial == 0 then
		labelText = "You see an undisturbed deposit."
	elseif numberMaterial == 1 then
		labelText = "You see a deposit that has been mined once."
	elseif numberMaterial > 1 then
		labelText = "You see a deposit wthat has been mined "..numberMaterial.." times."
	else
		mwse.log("Quantity error in mining script. ("..thing.object.id..")")
	end
	labelText = labelText.." Would you like to:"
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.width = 320
	menu.height = 300
	menu.minWidth = 320
	menu.minHeight = 70
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
	menu.widthProportional = true
	menu.flowDirection = "top_to_bottom"
	local label = menu:createLabel{ text = labelText }
	label.autoHeight = true
	label.wrapText = true
	label.justifyText = "center"
	local buttonBlock = menu:createBlock{}
	buttonBlock.widthProportional = 1.0
	buttonBlock.autoHeight = true
	buttonBlock.childAlignX = 0.5
	local button_2 = buttonBlock:createButton{ id = this.id_button2, text = "Fast Mine" }
	local button_1 = buttonBlock:createButton{ id = this.id_button1, text = "Mine" }
	local button_3 = buttonBlock:createButton{ id = this.id_button3, text = tes3.findGMST("sCancel").value  }
	-- Events
	button_3:register("mouseClick", this.onCancel)
	button_2:register("mouseClick", this.onFastGather)
	button_1:register("mouseClick", this.onGather)
	
	menu:updateLayout()
	tes3ui.enterMenuMode(this.id_menu)
end
event.register("initialized", this.init)

function this.startMining()
	itemID = itemObject.id
	thing = itemObject
	difficulty = recipes[recipeNum].difficulty
	oreType = recipes[recipeNum].oreType
	taskTime = recipes[recipeNum].taskTime
	hasPick = checkPick()
	if hasNordPick ~= true and oreType == "ingred_raw_stalhrim_01" then
		tes3.messageBox("You cannot mine stalhrim without a special form of pick.")
	elseif hasPick ~= true then
		tes3.messageBox({ message = "You cannot break deposits unless you have a pick." })
	else
		if not itemObject.data.bonusUsed then
			if recipes[recipeNum].bonus == true then
				tes3.addItem{reference = tes3.player, item = recipes[recipeNum].oreType, count = 1, playSound = false}
				itemObject.data.bonusUsed = true
				tes3.messageBox(recipes[recipeNum].bonusMessage)
				if oreType == "ingred_raw_stalhrim_01" then
					if tes3.getJournalIndex{id="CO_8a"} == 30 then
						tes3.updateJournal{id="CO_8a", index=40}
					elseif tes3.getJournalIndex{id="CO_8"} == 30 then
						tes3.updateJournal{id="CO_8", index=40}
					end
				end	
				return false
			end
		end
		this.createWindow()
	end
end

function this.swapOut()
	if isCollectingOre == true then
		local emptyID = thing.baseObject.id.."_e"
		if recipes[recipeNum].replace then emptyID = recipes[recipeNum].replace end
		if tes3.player.cell.isInterior == true then
			--mwse.log(thing.baseObject.id.."  "..emptyID)
	        permThing = tes3.createReference{ object = emptyID,
	                position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
	                orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
	                cell = tes3.player.cell,
	                scale = thing.scale
	                }
	    else
	        permThing = tes3.createReference{ object = emptyID,
	                position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
	                orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
	                scale = thing.scale
	                }
	    end
	    --permThing.sceneNode.parent:update();permThing.sceneNode.parent:updateNodeEffects()
	    tes3.setEnabled({ reference = thing, enabled = false }) -- Disable old reference
		timer.delayOneFrame(function()
			mwscript.setDelete({ reference = thing, delete = true })
		end) -- "setdelete 1"
		isCollectingOre = false
	end
end

function this.swapOreRock()
	local currentContents
	if (itemObject.data.mcShattered == 1) then
		if recipes[recipeNum].replace then
			currentContents = itemObject.object.inventory
			if ( #currentContents == 0 ) then
				isCollectingOre = true
				this.swapOut()
				isCollectingOre = false
				return false
			end
		else
			itemObject.data.mcShattered = -1
		end
	end
end

function this.onClose(e)
	itemID = e.reference.baseObject.id
	for i, x in ipairs(recipes) do
		if itemID == recipes[i].id then
			recipeNum = i
			this.swapOreRock()
			break
		end
	end
end

local function onActivate(e)
	local tempRef
	local currentContents
	if (e.activator == tes3.player) then
		config = mwse.loadConfig(configPath)
		isCollectingOre = true
		thing = e.target
		itemObject = thing
		if config.animatedMining ~= true then
			itemID = e.target.baseObject.id
			for i, x in ipairs(recipes) do
				if itemID == recipes[i].id then
					recipeNum = i
					if skipActivate then
						skipActivate = false
					else
						if not tes3.menuMode() then
							itemObject = forceInstance(e.target)
							itemObject.modified = true
						end
					end
					if recipes[recipeNum].oreType == "ingred_raw_stalhrim_01" then
						if mc.fetchSkill(skillID) < 90 then
							tes3.messageBox("The Stalhrim proves to be beyond your skill (you need to be at a skill of 90 or better).")
							return false
						end
					end
					if not itemObject.data.mcMaterial then itemObject.data.mcMaterial = 0 end
					if not itemObject.data.mcShattered then itemObject.data.mcShattered = 0 end
					if config.animatedMining ~= true then
						if itemObject.data.mcShattered == 0 then
							this.startMining()	
							return false
						elseif itemObject.data.mcShattered == 1 then
							currentContents = itemObject.object.inventory
							if ( #currentContents == 0 ) then
								isCollectingOre = true
								this.swapOut()
								isCollectingOre = false
								return false
							end
						else
							tes3.messageBox("This deposit has been mined as much as possible.")
							return false
						end
					end
				end
			end
		end
	end
end

event.register("activate", onActivate)
event.register("uiObjectTooltip", extraTooltip, {priority = -100})
event.register("attack", this.onAttack)
event.register("containerClosed", this.onClose)