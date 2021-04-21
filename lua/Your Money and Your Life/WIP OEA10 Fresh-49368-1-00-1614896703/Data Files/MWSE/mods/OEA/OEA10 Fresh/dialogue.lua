local config = require("OEA.OEA10 Fresh.config")
local pay = require("OEA.OEA10 Fresh.paymentEnter")
local tables = require("OEA.OEA10 Fresh.tables")

local function PreEvent(e)
	local fakeBlock

	if (e.property ~= tes3.uiProperty.mouseClick) then
		return
	end

	if (e.block.name == nil) then
		return
	end

	if (e.block.name ~= "MenuDialog_a_topic") and (e.block.name ~= "PartHyperText_link") then
		return
	end

	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	local giving = true
	local cost
	local randTerm

	local GUI_ID_MenuDialog = tes3ui.registerID("MenuDialog")
	local menuDialogue = tes3ui.findMenu(GUI_ID_MenuDialog)
	local mobileActor = menuDialogue:getPropertyObject("PartHyperText_actor")
	local actor = mobileActor.reference.object.baseObject

	local dialogue = e.block:getPropertyObject("PartHyperText_dialog")
	local info = dialogue:getInfo({ actor = mobileActor })

	if (tables.rewardTable[info.id] ~= nil) then
		return
	end

	if (e.block.name == "PartHyperText_link") then
		local GUI_ID_MenuDialog_topics_pane = tes3ui.registerID("MenuDialog_topics_pane")
		local GUI_ID_PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")
		local topicsPane = menuDialogue:findChild(GUI_ID_MenuDialog_topics_pane):findChild(GUI_ID_PartScrollPane_pane)
		for _, element in pairs(topicsPane.children) do
			if (element.name ~= nil) and (element.name == "MenuDialog_a_topic") then
				if (element:getPropertyObject("PartHyperText_dialog") == dialogue) then
					fakeBlock = element
					break
				end
			end
		end
	else
		fakeBlock = nil
	end

	if (tables.dialogueTable[info.id] ~= nil) then
		cost = tables.dialogueTable[info.id][1]
		randTerm = math.random((0 - tables.dialogueTable[info.id][2]), tables.dialogueTable[info.id][2])
		cost = cost + randTerm
		tes3ui.showDialogueMessage({ text = " " })
		tes3ui.showDialogueMessage({ text = ("Talk may be cheap, but all information comes at a price. So what will it be? *Rating = %s*"):format(tables.dialogueTable[info.id][3]) })
		pay.forwardBlock((fakeBlock or e.block))
		pay.CreateMenu(giving, cost)
	elseif (tables.dialogueTable[dialogue.id] ~= nil) then
		cost = tables.dialogueTable[dialogue.id][1]
		randTerm = math.random((0 - tables.dialogueTable[dialogue.id][2]), tables.dialogueTable[dialogue.id][2])
		cost = cost + randTerm
		tes3ui.showDialogueMessage({ text = " " })
		tes3ui.showDialogueMessage({ text = ("Talk may be cheap, but all information comes at a price. So what will it be? *Rating = %s*"):format(tables.dialogueTable[dialogue.id][3]) })
		pay.forwardBlock((fakeBlock or e.block))
		pay.CreateMenu(giving, cost)
	else
		cost = 250
		randTerm = math.random(-27, 27)
		cost = cost + randTerm
		tes3ui.showDialogueMessage({ text = " " })
		tes3ui.showDialogueMessage({ text = "Talk may be cheap, but all information comes at a price. So what will it be? *Rating = Unknown*" })
		pay.forwardBlock((fakeBlock or e.block))
		pay.CreateMenu(giving, cost)
	end
	tes3.player.data.OEA10.reClick = 1
	return false
end

local GoldAmount

local function PreTalk(e)
	GoldAmount = tes3.getPlayerGold()
end

local function PostTalk(e)
	if (tables.rewardTable[e.info.id] == nil) then
		return
	end

	local NewGoldAmount = tes3.getPlayerGold()
	local GoldDifference = NewGoldAmount - GoldAmount
	tes3.removeItem({ reference = tes3.player, item = "Gold_001", amount = GoldDifference })

	tes3ui.showDialogueMessage({ text = " " })
	tes3ui.showDialogueMessage({ text = "It looks like my trust in you was not misplaced. As such, I know that you will be fair and honest with me when it comes to your payment." })

	local giving = false
	local cost = tables.rewardTable[e.info.id][1]
	pay.CreateMenu(giving, cost)

--i wanted rewards to only be Caveat Nerevar'd after you pick them, to make guessing easier. See paymentEnter for that implementation
end

local function Loaded(e)
	event.unregister("uiPreEvent", PreEvent)
	event.unregister("infoResponse", PreTalk)
	event.unregister("postInfoResponse", PostTalk, { priority = 1000 })

	if (config.Mech == true) then
		event.register("uiPreEvent", PreEvent)
		event.register("infoResponse", PreTalk)
		event.register("postInfoResponse", PostTalk, { priority = 1000 })
	end
end
event.register("loaded", Loaded)