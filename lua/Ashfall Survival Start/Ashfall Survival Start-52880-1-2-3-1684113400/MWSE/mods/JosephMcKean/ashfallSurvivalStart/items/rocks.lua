local common = require("JosephMcKean.ashfallSurvivalStart.common")
local log = common.createLogger("rocks")

local minLookDistance = 230 -- How close the rock needs to be to activate
local rockId = "jsmk_ass_ac_rock"

local lastRef
local swings
swings = swings or 0

---@param e attackEventData
local function mine(e)
	if e.reference ~= tes3.player then
		return
	end

	local result = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = { tes3.player } })
	if not result then
		return
	end
	local ref = result.reference
	if not (ref and ref.id:startswith(rockId)) then
		return
	end
	local distance = tes3.player.position:distance(result.intersection)
	if distance > minLookDistance then
		return
	end

	local readiedWeapon = tes3.mobilePlayer.readiedWeapon
	if not readiedWeapon then
		return
	end
	local readiedWeaponObj = tes3.mobilePlayer.readiedWeapon.object
	if not readiedWeaponObj.id:lower():find("pick") then
		return
	end

	-- Chopping at close distance with a pick?
	local swingsNeeded = 6
	if lastRef ~= ref then
		swings = 0
		lastRef = ref
	end
	swings = swings + 1
	local item = math.random() < 0.16 and "ashfall_flint" or "ashfall_stone"
	tes3.addItem({ reference = tes3.player, item = item, showMessage = true })
	tes3.playSound({ reference = tes3.player, sound = "Item Misc Up" })

	-- Pick degradation: Harder rock degrades pick faster
	readiedWeapon.itemData.condition = readiedWeapon.itemData.condition - 7
	-- Unequip if broken
	if readiedWeapon.itemData.condition <= 0 then
		readiedWeapon.itemData.condition = 0
		tes3.mobilePlayer:unequip({ item = readiedWeaponObj })
	end

	-- Mine the ore after enough swings
	if swings >= swingsNeeded then
		swings = 0
		ref:disable()
		ref:delete()
	end
end
event.register("attack", mine, { priority = 10 })

---@param e activateEventData
local function message(e)
	if not e.target then
		return
	end
	if not e.target.object.id:startswith(rockId) then
		return
	end
	local readiedWeapon = tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object
	if readiedWeapon and readiedWeapon.id:lower():find("pick") then
		tes3.messageBox("I can use the pick axe to mine these rocks.")
	else
		tes3.messageBox("I need a pick axe to mine these rocks.")
	end
end
event.register("activate", message)

local function checkUpdateJournal()
	if tes3.player.cell.id ~= "Masartus" then
		return
	end
	local rockRef = tes3.getReference("jsmk_ass_ac_rock01")
	if not rockRef then
		return
	end
	if tes3.player.position:distance(rockRef.position) < 256 then
		tes3.updateJournal({ id = "jsmk_ass", index = 15, showMessage = true })
		tes3.player.data.ass.rockJournalUpdated = true
		return
	end
	timer.start({ duration = 1, callback = checkUpdateJournal })
end

event.register("loaded", function()
	swings = 0
	if tes3.player.data.ass.rockJournalUpdated then
		return
	end
	timer.start({ duration = 1, callback = checkUpdateJournal })
end)
