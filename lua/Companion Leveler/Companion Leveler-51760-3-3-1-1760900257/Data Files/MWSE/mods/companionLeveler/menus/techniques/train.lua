local logger = require("logging.logger")
local config = require("companionLeveler.config")
local log = logger.getLogger("Companion Leveler")
local tables = require("companionLeveler.tables")
local func = require("companionLeveler.functions.common")


local train = {}


function train.createWindow(ref)
	--Initialize IDs
	train.id_menu = tes3ui.registerID("kl_train_menu")
	train.id_pane = tes3ui.registerID("kl_train_pane")
	train.id_pane2 = tes3ui.registerID("kl_train_pane2")
	train.id_ok = tes3ui.registerID("kl_train_ok")

	log = logger.getLogger("Companion Leveler")
	log:debug("Train menu initialized.")

	local tech = require("companionLeveler.menus.techniques.techniques")
	train.modData = func.getModData(ref)

	train.trainer = ref
	train.npc_choices = 0
	train.skill_choices = 0
	train.skills_added = {}
	train.ratio = 6
	train.amount = 1

	-- Create Menu
	local menu = tes3ui.createMenu { id = train.id_menu, fixedFrame = true }

	-- Heading Block
	local head_block = menu:createBlock{ id = "kl_header_train" }
	head_block.autoWidth = true
	head_block.autoHeight = true
	head_block.borderBottom = 5

	--Title/TP Bar Blocks
	local title_block = head_block:createBlock{}
	title_block.width = 275
	title_block.autoHeight = true

	local tp_block = head_block:createBlock{}
	tp_block.width = 275
	tp_block.autoHeight = true

	-- Title
	title_block:createLabel { text = "Train which companion?" }

	-- TP Bar
	train.tp_bar = tp_block:createFillBar({ current = train.modData.tp_current, max = train.modData.tp_max, id = train.id_tp_bar })
	func.configureBar(train.tp_bar, "small", "purple")
	train.tp_bar.borderLeft = 155

	-- Pane Block
	local pane_block = menu:createBlock { id = "pane_block_train" }
	pane_block.autoWidth = true
	pane_block.autoHeight = true

	-- train Border
	local border = pane_block:createThinBorder { id = "kl_border_train" }
	border.positionX = 4
	border.positionY = -4
	border.width = 267
	border.height = 160
	border.borderAllSides = 4
	border.paddingAllSides = 4

	-- Attribute Border
	local border2 = pane_block:createThinBorder { id = "kl_border2_train" }
	border2.positionX = 202
	border2.positionY = 0
	border2.width = 267
	border2.height = 160
	border2.paddingAllSides = 4
	border2.borderAllSides = 4


	----Populate-----------------------------------------------------------------------------------------------------

	--Panes
	local pane = border:createVerticalScrollPane { id = train.id_pane }
	pane.height = 148
	pane.width = 210
	pane.widget.scrollbarVisible = true

	train.pane2 = border2:createVerticalScrollPane { id = train.id_pane2 }
	train.pane2.height = 148
	train.pane2.width = 210
	train.pane2.widget.scrollbarVisible = true

	--Populate Panes

	--Player Choice
	train.npc_choices = train.npc_choices + 1
	local player_choice = pane:createTextSelect { text = "" .. tes3.player.object.name .. "", id = "kl_train_npc_btn_" .. train.npc_choices .. ""}
	player_choice:register("mouseClick", function(e) train.onSelectTarget(player_choice, tes3.mobilePlayer) end)

	--NPC Choices
	for mobileActor in tes3.iterate(tes3.worldController.allMobileActors) do
		if (mobileActor.cell == tes3.getPlayerCell() and func.validCompanionCheck(mobileActor) and mobileActor.reference.object.objectType ~= tes3.objectType.creature) then
			local pos = mobileActor.reference.position
			local dist = pos:distance(tes3.player.position)
			log:debug("" .. mobileActor.reference.object.name .. "'s distance: " .. dist .. "")

			if dist < 750 and mobileActor.reference.object.name ~= "" and mobileActor.reference ~= train.trainer then
				train.npc_choices = train.npc_choices + 1

				local a = pane:createTextSelect { text = "" .. mobileActor.reference.object.name .. "", id = "kl_train_npc_btn_" .. train.npc_choices .. ""}

				a:register("mouseClick", function(e) train.onSelectTarget(a, mobileActor) end)
			end
		end
	end

	--Skill Choices
	for i = 1, #tables.abTypeNPC do
		if tables.abTypeNPC[i] == "[TECHNIQUE]: TRAINING" then
			if i ~= 48 then
				train.addSkills(i)
			end
		end
	end

	--Sort Skills
	train.pane2:getContentElement():sortChildren(function(c, d)
		local cText
		local dText

		for int = 0, train.skill_choices do
			cText = ""
			local cChild = c:findChild("kl_train_skill_btn_" .. int .. "")
			if cChild ~= nil then cText = cChild.text break end
		end
		for num = 0, train.skill_choices do
			dText = ""
			local dChild = d:findChild("kl_train_skill_btn_" .. num .. "")
			if dChild ~= nil then dText = dChild.text break end
		end

		return cText < dText
	end)


	--Text Block
	local text_block = menu:createBlock { id = "text_block_train" }
	text_block.autoWidth = true
	text_block.autoHeight = true
	text_block.borderAllSides = 10
	text_block.flowDirection = "left_to_right"

	local trainer_block = text_block:createBlock {}
	trainer_block.width = 174
	trainer_block.autoHeight = true
	trainer_block.borderAllSides = 4
	trainer_block.flowDirection = "top_to_bottom"

	local cost_block = text_block:createBlock {}
	cost_block.width = 174
	cost_block.autoHeight = true
	cost_block.borderAllSides = 4
	cost_block.flowDirection = "top_to_bottom"

	local trainee_block = text_block:createBlock {}
	trainee_block.width = 157
	trainee_block.autoHeight = true
	trainee_block.borderAllSides = 4
	trainee_block.flowDirection = "top_to_bottom"

	--Trainer Skill
	local trainer_title = trainer_block:createLabel({ text = "Trainer Skill:", id = "kl_block_train" })
	trainer_title.color = tables.colors["white"]
	train.trainer_skill = trainer_block:createLabel({ text = "Skill: ", id = "kl_train_skill" })

	--TP Costs
	local cost_title = cost_block:createLabel({ text = "TP Cost:" })
	cost_title.color = tables.colors["white"]
	train.tp_cost = cost_block:createLabel { text = "", id = "kl_train_tp_cost" }
	cost_block:createLabel { text = "" }
	train.skill_req = cost_block:createLabel { text = "Skill Required: ", id = "kl_train_skill_req" }
	cost_block:createLabel { text = "Training Time: 2 hours" , id = "kl_train_time" }
	train.sessions = cost_block:createLabel { text = "Session Limit: " .. train.modData.sessions_current .. "/" .. train.modData.sessions_max .. "" }

	--Trainee Skill
	local trainee_title = trainee_block:createLabel({ text = "Trainee Skill:" })
	trainee_title.color = tables.colors["white"]
	train.trainee_skill = trainee_block:createLabel { text = "Skill:", id = "kl_train_skill_2" }


	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok.widget.state = 2
	button_ok.disabled = true
	train.ok = button_ok
	local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }

	--Events
	button_ok:register("mouseClick", function()
		local npcModData = { ["level"] = 1 }
		if train.trainee == tes3.mobilePlayer then
			npcModData.level = tes3.player.object.level
		else
			npcModData = func.getModData(train.trainee.reference)
		end
		local trainedSkill = train.trainee:getSkillStatistic(train.trainedSkill)

		if train.modData.tp_current < train.tp then
			func.clMessageBox("Not enough Technique Points!")
			return
		end

		if train.req > train.trainer.mobile:getSkillStatistic(train.trainedSkill).base or train.amount == 0 then
			func.clMessageBox("" .. tes3.findGMST(tes3.gmst.sServiceTrainingWords).value .. "")
			return
		end

		if train.modData.sessions_current >= train.modData.sessions_max then
			func.clMessageBox("" .. train.trainer.object.name .. " can't train any more pupils until their next level.")
			return
		end


		--Spend TP
		train.modData.tp_current = train.modData.tp_current - train.tp

		--Increase Sessions
		train.modData.sessions_current = train.modData.sessions_current + 1

		--Train Skill
		tes3.modStatistic{ reference = train.trainee.reference, skill = train.trainedSkill, value = 1}
		if train.trainee ~= tes3.mobilePlayer then
			npcModData.skill_gained[train.trainedSkill + 1] = npcModData.skill_gained[train.trainedSkill + 1] + 1
		end
		if train.trainee ~= tes3.mobilePlayer then
			if trainedSkill ~= 25 then
				tes3.playSound({ sound = tables.trainingSounds[train.trainedSkill], volume = 0.7 })
			end
		else
			tes3.playSound({ sound = "skillraise" })
		end
		func.clMessageBox("" .. ref.object.name .. " trained " .. train.trainee.object.name .. "'s " .. train.skillName .. " to " .. trainedSkill.base .. "!")

		--Pass Time
		local gameHour = tes3.getGlobal('GameHour')

		gameHour = gameHour + 2
		tes3.setGlobal('GameHour', gameHour)

		--Reset
		menu:destroy()
		tes3ui.leaveMenuMode()
		timer.delayOneFrame(function()
			train.createWindow(ref)
		end)
	end)
	button_cancel:register("mouseClick", function() menu:destroy() tech.createWindow(ref) end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode(train.id_menu)
end

function train.addSkills(ability)
	if train.modData.abilities[ability] == true then
		local skills

		skills = tables.trainerAbilities[ability]

		for i = 1, #skills do
			local inList = false

			for n = 1, #train.skills_added do
				if train.skills_added[n] == skills[i] then
					inList = true
					break
				end
			end

			if inList == false then
				train.skill_choices = train.skill_choices + 1
				local sk = tes3.getSkill(skills[i])
				local a = train.pane2:createTextSelect { text = "" .. sk.name .. "",  id = "kl_train_skill_btn_" .. train.skill_choices .. ""}
				a.widget.state = 2
				a.disabled = true
				a:register("mouseClick", function(e) train.onSelectSkill(a, skills[i]) end)

				train.skills_added[#train.skills_added + 1] = skills[i]
			end
		end
	end
end

function train.onSelectTarget(elem, mobileActor)
	local menu = tes3ui.findMenu(train.id_menu)

	if menu then
		for i = 1, train.npc_choices do
			local btn = menu:findChild("kl_train_npc_btn_" .. i .. "")
			if btn then
				btn.widget.state = 1
			end
		end

		elem.widget.state = 4

		local trainerSkill = false
		local traineeSkill = false
		
		local modData = { ["level"] = 1 }
		local playerButton = menu:findChild("kl_train_npc_btn_1")
		if playerButton.widget.state == 4 then
			modData.level = tes3.player.object.level
			train.trainee = tes3.mobilePlayer
		else
			modData = func.getModData(mobileActor.reference)
		end

		for i = 1, train.skill_choices do
			local btn = menu:findChild("kl_train_skill_btn_" .. i .. "")

			if btn and btn.widget.state == 4 then
				traineeSkill = mobileActor:getSkillStatistic(train.trainedSkill)
				trainerSkill = train.trainer.mobile:getSkillStatistic(train.trainedSkill)
				train.tp = math.round((traineeSkill.base / train.ratio) + (modData.level / 5))
				if train.tp < 4 then
					train.tp = 4
				end
				train.req = traineeSkill.base + 10
				train.skill_req.text = "Skill Required: " .. train.req .. ""
				train.sessions.text = "Session Limit: " .. train.modData.sessions_current .. "/" .. train.modData.sessions_max .. ""
				break
			else
				btn.widget.state = 1
				btn.disabled = false
			end
		end

		train.trainee = mobileActor


		if traineeSkill then
			--Trainer Skill
			train.trainer_skill.text = "" .. trainerSkill.base .. ""
			--Technique Point Costs
			train.tp_cost.text = "" .. train.tp .. " TP"
			--Trainee Skill
			train.trainee_skill.text = "" .. traineeSkill.base .. ""
		end


		menu:updateLayout()
	end
end

function train.onSelectSkill(elem, id)
	local menu = tes3ui.findMenu(train.id_menu)

	if menu then
		for i = 1, train.skill_choices do
			local btn = menu:findChild("kl_train_skill_btn_" .. i .. "")
			btn.widget.state = 1
		end

		elem.widget.state = 4

		local modData = { ["level"] = 1 }
		local playerButton = menu:findChild("kl_train_npc_btn_1")
		if playerButton.widget.state == 4 then
			modData.level = tes3.player.object.level
			train.trainee = tes3.mobilePlayer
		else
			modData = func.getModData(train.trainee.reference)
		end

		for i = 1, train.skill_choices do
			local btn = menu:findChild("kl_train_skill_btn_" .. i .. "")

			if btn and btn.widget.state == 4 then
				local traineeSkill = train.trainee:getSkillStatistic(id)
				local trainerSkill = train.trainer.mobile:getSkillStatistic(id)

				if config.aboveMaxSkill == false then
					if traineeSkill.base >= 100 then
						train.amount = 0
					else
						train.amount = 1
					end
				end

				train.tp = math.round((traineeSkill.base / train.ratio) + (modData.level / 5))
				if train.tp < 4 then
					train.tp = 4
				end
				train.req = traineeSkill.base + 10
				train.skillName = "" .. btn.text .. ""
				train.trainedSkill = id

				train.trainer_skill.text = "" .. trainerSkill.base .. ""
				train.trainee_skill.text = "" .. traineeSkill.base .. ""
				train.tp_cost.text = "" .. train.tp .. " TP"
				train.skill_req.text = "Skill Required: " .. train.req .. ""
				break
			end
		end


		train.ok.widget.state = 1
		train.ok.disabled = false

		menu:updateLayout()
	end
end

return train