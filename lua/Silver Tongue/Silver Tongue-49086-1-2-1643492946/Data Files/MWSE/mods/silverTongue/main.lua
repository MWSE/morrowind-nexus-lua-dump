local npcRef
local npcClass
local initialBribe10
local initialBribe100
local initialBribe1000
local config

local bribeSuccesss = {
	["1458830178786919518"] = true,
	["67111699173578209"] = true,
	["21738128693152413504"] = true,
	["7541093121030463"] = true,
	["37328664268803964"] = true,
	["1489730480321272"] = true,
	["218997615188231249"] = true,
	["224091285626087204"] = true,
	["114485459956223146"] = true,
	["2990915352848125483"] = true,
	["29136216602360511543"] = true,
	["11847247013115832744"] = true,
	["236181368916747631"] = true,
	["6758312831477724060"] = true,
	["65085023117216087"] = true,
	["1377786412062913359"] = true,
	["22990147762465313017"] = true,
	["15242252713016251"] = true,
	["193433556247591009"] = true,
	["264901265198521487"] = true
}

local bribeFail = {
	["2973515306664820887"] = true,
	["19803096897931412"] = true,
	["83313102841915546"] = true,
	["137221081449632499"] = true,
	["1438312068186193282"] = true,
	["2571427924141062089"] = true,
	["229211216524119819"] = true,
	["231649628224483582"] = true,
	["349218719711716611"] = true,
	["322092365511261688"] = true,
	["1648820782154061085"] = true,
	["30783118681683731223"] = true,
	["3208213005304216290"] = true,
}

local speechcraft = 5

local function setDefault()
	tes3.findGMST("fBribe10Mod").value = initialBribe10
	tes3.findGMST("fBribe100Mod").value = initialBribe100
	tes3.findGMST("fBribe1000Mod").value = initialBribe1000
end

local function addPauperBonus()
	tes3.findGMST("fBribe10Mod").value = tes3.findGMST("fBribe10Mod").value + config.pauperBonus
	tes3.findGMST("fBribe100Mod").value = tes3.findGMST("fBribe100Mod").value + config.pauperBonus * 2
	tes3.findGMST("fBribe1000Mod").value = tes3.findGMST("fBribe1000Mod").value + config.pauperBonus * 4
end

local function addGuardPenalty()
	tes3.findGMST("fBribe10Mod").value = tes3.findGMST("fBribe10Mod").value - config.guardPenalty
	tes3.findGMST("fBribe100Mod").value = tes3.findGMST("fBribe100Mod").value - config.guardPenalty * 2
	tes3.findGMST("fBribe1000Mod").value = tes3.findGMST("fBribe1000Mod").value - config.guardPenalty * 4
end

local function onExerciseSkill(e)
	if e.skill ~= tes3.skill.speechcraft then return end
	e.progress = e.progress * 0.5
end

local function onMenuExit(e)
	event.unregister("menuExit", onMenuExit)
	event.unregister("exerciseSkill", onExerciseSkill)
	setDefault()
	npcRef = nil
	npcClass = nil
end

local function checkClass()
	if not npcRef then return end
	npcClass = npcRef.object.class.id
	if npcClass == "Pauper" then
		addPauperBonus()
		event.unregister("exerciseSkill", onExerciseSkill)
		event.register("exerciseSkill", onExerciseSkill)
	elseif npcClass == "Guard" then
		addGuardPenalty()
	else
		npcClass = nil
	end
	event.unregister("menuExit", onMenuExit)
	event.register("menuExit", onMenuExit)
end

local function updateDialogFillBars()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end
	speechcraft = tes3.mobilePlayer.speechcraft.current
	local disposition = menu:findChild(tes3ui.registerID("MenuDialog_disposition"))
	local parent = disposition.parent
	disposition.visible = false
	disposition = menu:findChild(tes3ui.registerID("MenuDialog_disposition2"))
	if disposition then
		disposition:destroy()
	end
	disposition = parent:createFillBar{id = tes3ui.registerID("MenuDialog_disposition2"), current = npcRef.object.disposition, max = 100}
	disposition.width = 192
	disposition.height = 19
	disposition.borderAllSides = 4
	disposition:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Disposition"
	disposition.widget.fillColor = tes3ui.getPalette("magic_color")
	disposition.visible = speechcraft >= config.showDisposition
	local fight = menu:findChild(tes3ui.registerID("MenuDialog_fight"))
	if fight then
		fight:destroy()
	end
	fight = parent:createFillBar{id = tes3ui.registerID("MenuDialog_fight"), current = npcRef.mobile.fight, max = 100}
	fight.width = 192
	fight.height = 19
	fight.borderLeft = 4
	fight.borderBottom = 4
	fight:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Fight"
	fight.widget.fillColor = tes3ui.getPalette("magic_color")
	fight.visible = speechcraft >= config.showFight
	local alarm = menu:findChild(tes3ui.registerID("MenuDialog_alarm"))
	if alarm then
		alarm:destroy()
	end
	alarm = parent:createFillBar{id = tes3ui.registerID("MenuDialog_alarm"), current = npcRef.mobile.alarm, max = 100}
	alarm.width = 192
	alarm.height = 19
	alarm:findChild(tes3ui.registerID("PartFillbar_text_ptr")).text = "Alarm"
	alarm.widget.fillColor = tes3ui.getPalette("magic_color")
	alarm.borderBottom = 4
	alarm.borderLeft = 4
	alarm.visible = speechcraft >= config.showAlarm
	parent:reorderChildren(1, -3, 3)
	local topics = menu:findChild(tes3ui.registerID("MenuDialog_topics_pane"))
	topics.minWidth = 192
	topics.maxWidth = 192
	topics.autoWidth = true
	menu:updateLayout()
end

local function onMenuDialog(e)
	npcRef = e.element:getPropertyObject("PartHyperText_actor").reference
	if npcRef.object.objectType ~= tes3.objectType.npc then
		npcRef = nil
		return
	end
	checkClass()
	timer.delayOneFrame(function()
		updateDialogFillBars()
	end)
end

local function onMenuPersuasion(e)
	speechcraft = tes3.mobilePlayer.speechcraft.current
	local serviceList = e.element:findChild(tes3ui.registerID("MenuPersuasion_ServiceList"))
	for i, option in ipairs(serviceList.children) do
		local child = option:findChild()
		if i == 1 then
			option.visible = speechcraft >= config.allowAdmire
		elseif i == 2 then
			option.visible = speechcraft >= config.allowIntimidate
		elseif i == 3 then
			option.visible = speechcraft >= config.allowTaunt
		end
	end
	e.element:updateLayout()
	e.element:updateLayout()
end

local function onDialog(e)
	local mobileActor = tes3ui.getServiceActor()
	if bribeSuccesss[e.info.id] then
		if speechcraft >= config.bribeDecreasesAlarm then
			if mobileActor.alarm >= 10 then
				mobileActor.alarm = mobileActor.alarm - 10
			else
				mobileActor.alarm = 0
			end
		end
	elseif bribeFail[e.info.id] then
		if mobileActor.reference.object.class.id == "Guard" then
			-- Direct assertment because trigger crime doesn't work in menu mode
			tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + 250
			timer.frame.delayOneFrame(function()
				mobileActor:startDialogue()
				local menu = tes3ui.findMenu(tes3ui.registerID("MenuPersuasion"))
				local button = menu:findChild(tes3ui.registerID("MenuPersuasion_Okbutton"))
				button:triggerEvent("mouseClick")
			end)
			-- For correctly triggering Guards AI
			timer.delayOneFrame(function()
				if tes3.mobilePlayer.bounty > 0 then
					tes3.triggerCrime({
						value = 0,
						type = tes3.crimeType.theft,
						criminal = tes3.mobilePlayer
					})
				end
			end)
		end
	end
	timer.start{
		duration = 0.05,
		type = timer.real,
		callback = function()
			updateDialogFillBars()
		end
	}
end

local function onActivate(e)
	if tes3.mobilePlayer.speechcraft.current < config.combatTalk then return end
	if e.activator ~= tes3.player then return end
	if e.target.object.baseObject.objectType ~= tes3.objectType.npc then return end
	if tes3.mobilePlayer.isSneaking then return end
	timer.frame.delayOneFrame(function()
		timer.frame.delayOneFrame(function()
			if not tes3.menuMode() then
				e.target.mobile:startDialogue()
			end
		end)
	end)
end

event.register("modConfigReady", function()
    require("silverTongue.mcm")
	config  = require("silverTongue.config")
	setDefault()
	checkClass()
end)


local function initialized(e)
	mwse.log("Silver Tongue: ON")
	event.register("activate", onActivate)
	event.register("infoGetText", onDialog)
	event.register("uiActivated", onMenuDialog, {filter = "MenuDialog"})
	event.register("uiActivated", onMenuPersuasion, {filter = "MenuPersuasion"})
	initialBribe10 = tes3.findGMST("fBribe10Mod").value
	initialBribe100 = tes3.findGMST("fBribe100Mod").value
	initialBribe1000 = tes3.findGMST("fBribe1000Mod").value
end

event.register("initialized", initialized)