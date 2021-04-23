
local GUI_ID_MenuPersuasion = nil
local GUI_ID_MenuPersuasion_ServiceList = nil
local GUI_ID_MenuPersuasion_ServiceList_GiveGift = nil

local function calculateItemPersuasionModifier(item, data)
	local value = item.value

	if (data) then
		if (item.maxCondition) then
			value = value * (data.condition / item.maxCondition)
		elseif (item.time) then
			value = value * (data.timeLeft / item.time)
		end
	end

	return math.log10(value) * 25
end

local function onInventoryItemSelected(e)
	local MenuPersuasion = tes3ui.findMenu(GUI_ID_MenuPersuasion)
	local actor = MenuPersuasion:getPropertyObject("MenuPersuasion_Actor")

	-- Uzyskaj podstawowe dane umiej?tno?ci, aby m?c uzyska? ustawienia post?pu.
	local speechcraft = tes3.getSkill(tes3.skill.speechcraft)
	local mercantile = tes3.getSkill(tes3.skill.mercantile)

	-- Podejmij pr?b? perswazji.
	local dialoguePage
	local dialogueHeaderText
	if (tes3.persuade({ actor = actor, modifier = calculateItemPersuasionModifier(e.item, e.itemData) })) then
		dialoguePage = 8
		dialogueHeaderText = tes3.findGMST(tes3.gmst.sBribeSuccess).value

		-- Najed? na przedmiot, kt?ry zosta? przez ciebie dany.
		tes3.transferItem({
			from = tes3.player,
			to = actor.reference,
			item = e.item,
			itemData = e.itemData,
			count = 1,
		})

		-- ?wiczenie na drodze do og?lnego sukcesu i pr?b przekupstwa.
		tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, speechcraft.actions[1])
		tes3.mobilePlayer:exerciseSkill(tes3.skill.mercantile, mercantile.actions[2])
	else
		dialoguePage = 9
		dialogueHeaderText = tes3.findGMST(tes3.gmst.sBribeFail).value

		-- ?wiczenia na wypadek, gdy retoryka zawiedzie.
		tes3.mobilePlayer:exerciseSkill(tes3.skill.speechcraft, speechcraft.actions[2])
	end
	
	-- Poka? dialog je?li mo?esz.
	local dialogue = tes3.findDialogue({ type = 3, page = dialoguePage })
	local info = dialogue:getInfo({ actor = actor })
	if (info) then
		local text = info.text
		if (text and text ~= "") then
			tes3ui.showDialogueMessage({ text = dialogueHeaderText, style = 1 })
			tes3ui.showDialogueMessage({ text = text })
			info:runScript(actor.reference)
		end
	end

	-- Aktualizacja element?w UI.
	tes3ui.updateDialogDisposition()

	-- Zamknij menu.
	MenuPersuasion:destroy()
end

local function filterGifts(e)
	return calculateItemPersuasionModifier(e.item, e.itemData) > 0
end

local function onGiveAGiftClick(e)
	tes3ui.showInventorySelectMenu({
		title = "Daj prezent",
		noResultsText = "Brak prezent?w mo?liwych do dania.",
		filter = filterGifts,
		callback = onInventoryItemSelected,
	})
end

local function onMenuPersuasionActivated(e)
	if (not e.newlyCreated) then
		return
	end
	
	-- Stw?rz nowy skr?t.
	local MenuPersuasion_ServiceList = e.element:findChild(GUI_ID_MenuPersuasion_ServiceList)
	local MenuPersuasion_ServiceList_GiveGift = MenuPersuasion_ServiceList:createTextSelect({ id = GUI_ID_MenuPersuasion_ServiceList_GiveGift, text = "Daj prezent" })
	MenuPersuasion_ServiceList_GiveGift:register("mouseClick", onGiveAGiftClick)

	-- Wymagana dziwna aktualizacja lub menu staje si? dziwne. Dowiedz si? p?niej.
	e.element.visible = false
	e.element.visible = true
	e.element:updateLayout()
end
event.register("uiActivated", onMenuPersuasionActivated, { filter = "MenuPersuasion" } )

local function onInitialized()
	GUI_ID_MenuPersuasion = tes3ui.registerID("MenuPersuasion")
	GUI_ID_MenuPersuasion_ServiceList = tes3ui.registerID("MenuPersuasion_ServiceList")
	GUI_ID_MenuPersuasion_ServiceList_GiveGift = tes3ui.registerID("MenuPersuasion_ServiceList_GiveGift")
end
event.register("initialized", onInitialized )
