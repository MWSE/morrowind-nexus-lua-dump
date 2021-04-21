local config = require("OEA.OEA10 Fresh.config")
local pay = require("OEA.OEA10 Fresh.paymentEnter")
local health = require("OEA.OEA10 Fresh.health")
local tables = require("OEA.OEA10 Fresh.tables")

--as you might expect from the name, these are messageBox button callbacks. so I'd advise reading what's below first
local function DeathButtons(e, data)
	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	if (e.button == 0) then
		if (data.Ref.data.OEA10 == nil) then
			data.Ref.data.OEA10 = {}
		end

		if (data.Ref.data.OEA10.deathCount == nil) then
			data.Ref.data.OEA10.deathCount = 0
			data.Ref.modified = true
		end

		data.Ref.data.OEA10.deathCount = data.Ref.data.OEA10.deathCount + 1
		local cost = data.Ref.baseObject.level * data.Ref.baseObject.factionRank * 100 * (1 + data.Ref.data.OEA10.deathCount)
		local randTerm = math.floor(cost * 19 / 100)
		cost = cost + math.random((0 - randTerm), randTerm)
		local giving = true
		pay.CreateMenu(giving, cost)
	else
		tes3.messageBox("No? You won't pay? Looks like it's over then. May the gods have mercy...")
		tes3.player.data.OEA10.companionRef = nil
		tes3.player.data.OEA10.messageTime = 0
		tes3.player.data.OEA10.menuNumber = 0
	end
end

local function OnDeath(e)
	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end


	if (tes3.player.data.OEA10.companionRef == nil) then
		return
	end

	if  (e.reference ~= tes3.player.data.OEA10.companionRef) then
		return
	end

	tes3.player.data.OEA10.messageTime = 1
	local data = { Ref = e.reference }
	tes3.messageBox({
		message = "Looks like it's the end for me. Unless, of course, you'd be willing to pay me to get these injuries taken care of?",
		buttons = { "Yes", "No" },
		callback = function(e) DeathButtons(e, data) end
	})
end
		
local function Object(e)
	if (tes3.menuMode() == true) then
		return
	end

	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	if (e.reference == nil) then
		return
	end

	if (tes3.player.data.OEA10.menuNumber ~= nil) and (tes3.player.data.OEA10.menuNumber ~= 0) then
		if (tes3.player.data.OEA10.doorFirstTime ~= nil) and (e.reference.data.OEA10 ~= nil) and (e.reference.data.OEA10.currentCost ~= nil) then
			tes3.player.data.OEA10.doorFirstTime = nil
			e.reference.data.OEA10.amountPaid = e.reference.data.OEA10.amountPaid + tes3.player.data.OEA10.menuNumber
			e.reference.data.OEA10.currentCost = e.reference.data.OEA10.currentCost - tes3.player.data.OEA10.menuNumber
			tes3.player.data.OEA10.menuNumber = 0

			if (e.reference.data.OEA10.currentCost <= 0) then
				tes3.messageBox("You feel a great exhalation, coming from everywhere at once. It appears the force has left this entrance, "..
				"and you are now free to proceed.")

				tes3.playSound({ soundPath = ("Cr\\%s\\scrm.wav"):format(tables.doorTable[e.reference.destination.cell.id][2]) })
			end
		end
		return
	end

	if (tes3.player.data.OEA10.menuNumber ~= nil) and (tes3.player.data.OEA10.menuNumber ~= 0) then
		if (tes3.player.data.OEA10.messageTime ~= nil) and (tes3.player.data.OEA10.messageTime == 1) then
			tes3.player.data.OEA10.menuNumber = 0
			tes3.player.data.messageTime = 0
			if (tes3.player.data.OEA10.companionRef ~= nil) then
				tes3.runLegacyScript({ reference = tes3.player.data.OEA10.companionRef, command = "Resurrect" })
				tes3.setAIFollow({ reference = tes3.player.data.OEA10.companionRef.mobile, target = tes3.mobilePlayer, reset = false })
			else
				tes3.player.data.OEA10.companionRef = e.reference
				tes3.setAIFollow({ reference = e.reference.mobile, target = tes3.mobilePlayer, reset = false })
			end
		end
	end
end

local function MercButton(e, data)
	if (e.button == 0) then
		if (mwscript.getItemCount({ reference = tes3.player, item = "Gold_001" }) <= 10) then
			tes3.messageBox("It looks like you cannot even pay the initial fee. How unfortunate.")
			tes3.player:activate(data.Ref)
			return
		end

		tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = 10 })
		tes3.playSound({ sound = "Item Gold Up" })
		tes3.messageBox("Thanks to this small token of generosity, you can keep your next failed offer. Now, how much are you willing to pay?")

		local cost = data.Ref.baseObject.level * data.Ref.baseObject.factionRank * 100
		local randTerm = math.floor(cost * 19 / 100)
		cost = cost + math.random((0 - randTerm), randTerm)
	
		if (config.Money == true) then
			health.updateMenuMulti()
		end

		local giving = true
		pay.CreateMenu(giving, cost)
	elseif (e.button == 1) then
		tes3.player:activate(data.Ref)
	end
end

local function MercActivate(e)
	if (e.activator ~= tes3.player) then
		return
	end

	if (e.target.baseObject.objectType ~= tes3.objectType.npc) then
		return
	end

	if (e.target.mobile.health.current < 1) then
		return
	end

	if (e.target.baseObject.faction == nil) or (e.target.baseObject.faction.id ~= "Fighters Guild") then
		return
	end

	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	if (tes3.player.data.OEA10.companionRef ~= nil) then
		return
	end

	if (tes3.player.data.OEA10.messageTime ~= nil) and (tes3.player.data.OEA10.messageTime == 1) then
		tes3.player.data.OEA10.messageTime = 0
		return
	end

	local data = { Ref = e.target }
	tes3.player.data.OEA10.messageTime = 1

	tes3.messageBox({
		message = ("Would you like to hire my services? I don't come cheap, you know. *Level = %s*"):format(e.target.baseObject.level),
		buttons = { "Yes", "No" },
		callback = function(e) MercButton(e, data) end
	})

	return false
end

local function DoorButtons(e, data)
	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	if (e.button ~= 0) then
		return
	end

	if (data.Ref.data.OEA10.currentCost == nil) then
		data.Ref.data.OEA10.currentCost = tables.doorTable[data.ID][1]
		data.Ref.data.OEA10.amountPaid = 0
		tes3.player.data.OEA10.doorFirstTime = 1
		data.Ref.modified = true
		data.Ref.data.OEA10.currentCost = pay.Caveat(data.Ref.data.OEA10.currentCost)
	else
		tes3.player.data.OEA10.doorFirstTime = 0
	end
	
	local giving = true
	local cost = data.Ref.data.OEA10.currentCost
	--mwse.log("[OEA10] current cost is %s", cost)
	pay.CreateMenu(giving, cost)
end

local function OtherActivate(e)
	if (e.activator ~= tes3.player) then
		return
	end

	if (e.target.baseObject.objectType == tes3.objectType.book) then
		if (tes3.getOwner({ reference = e.target }) ~= nil) then
			if (e.target.baseObject.script == nil) then
				tes3.messageBox("Hey! Are you going to pay for that?")
				return false
			end
		end
	end

	if (e.target.baseObject.objectType ~= tes3.objectType.door) then
		return
	end

	if (e.target.destination == nil) or (e.target.destination.cell == nil) then
		return
	end

	if (tables.doorTable[e.target.destination.cell.id] == nil) then
		return
	end

	if (e.target.data.OEA10 == nil) then
		e.target.data.OEA10 = {}
	end

	if (e.target.data.OEA10.currentCost ~= nil) and (e.target.data.OEA10.currentCost <= 0) then
		return
	end

	local textCost = e.target.data.OEA10.amountPaid or 0

	local data = { Ref = e.target, ID = e.target.destination.cell.id }
	tes3.messageBox({
		message = ("You sense a powerful force emanating from the entrance. It is restless, and beckons you to grant it peace the only way possible: ".. 
		"with cold, hard septims. You realize that only such an appeasement will allow you to proceed. *Amount Paid = %s*"):format(textCost),
		buttons = { "Pay", "Leave" },
		callback = function(e) DoorButtons(e, data) end
	})

	tes3.playSound({ soundPath = ("Cr\\%s\\roar.wav"):format(tables.doorTable[e.target.destination.cell.id][2]) })
	return false
end

local function onMenuPersuasion(e)
	local serviceList = e.element:findChild(tes3ui.registerID("MenuPersuasion_ServiceList"))
	for i, option in ipairs(serviceList.children) do
		local child = option:findChild()
		if i == 1 then
			option.visible = false
		elseif i == 2 then
			option.visible = false
		elseif i == 3 then
			option.visible = false
		end
	end
	e.element:updateLayout()
end

--[[I hate, hate, hate CS dialogue. In its place, I figured I'd use a bunch of message boxes, with buttons so you could take your time. However, putting them in the
middle of the screen blocks everything, so this function would move them upward a bit at the appropriate time. I've had issues with this actually working in places,
but that's no longer my problem.]]--

local function onMenuMessage(e)
	local menu = e.element

	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	if (tes3.player.data.OEA10.messageTime == nil) then
		tes3.player.data.OEA10.messageTime = 0
	end

	if (tes3.player.data.OEA10.messageTime == 1) then
		menu.absolutePosAlignY = 0.2
	else
		menu.absolutePosAlignY = 0.5
	end
end


local function Loaded(e)
	event.unregister("uiActivated", onMenuMessage, { filter = "MenuMessage" }, { priority = -1000 })
	event.unregister("uiActivated", onMenuPersuasion, { filter = "MenuPersuasion" }, { priority = -1000 })
	event.unregister("activate", MercActivate, { priority = -1000 })
	event.unregister("activate", OtherActivate)
	event.unregister("uiObjectTooltip", Object)
	event.unregister("death", OnDeath)

	if (config.Mech == false) then
		return
	end

	event.register("uiActivated", onMenuMessage, { filter = "MenuMessage" }, { priority = -1000 })
	event.register("uiActivated", onMenuPersuasion, { filter = "MenuPersuasion" }, { priority = -1000 })
	event.register("activate", MercActivate, { priority = -1000 })
	event.register("activate", OtherActivate)
	event.register("uiObjectTooltip", Object)
	event.register("death", OnDeath)
end
event.register("loaded", Loaded)

local function Load(e)
	event.unregister("uiActivated", onMenuMessage, { filter = "MenuMessage" }, { priority = -1000 })
end
event.register("load", Load)