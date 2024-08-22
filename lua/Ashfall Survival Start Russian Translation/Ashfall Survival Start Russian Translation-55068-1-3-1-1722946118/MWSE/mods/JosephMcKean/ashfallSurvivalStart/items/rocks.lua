local common = require("JosephMcKean.ashfallSurvivalStart.common")
local log = common.createLogger("rocks")

local minLookDistance = 230 
local rockId = "jsmk_ass_ac_rock"
local maxSwings = 18

---@return tes3reference? rock
local function detectRockAhead()
	local result = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = { tes3.player } })
	if not result then return end
	if not (result.reference and result.reference.id:startswith(rockId)) then return end
	local rock = result.reference
	local distance = tes3.player.position:distance(result.intersection)
	if distance > minLookDistance then return end
	return rock
end

---@return tes3equipmentStack? pick
local function holdingPick()
	local readiedWeapon = tes3.mobilePlayer.readiedWeapon
	if not readiedWeapon then return end
	if not readiedWeapon.object.id:lower():find("pick") then return end
	return readiedWeapon
end

---@param pick tes3equipmentStack 
local function breakPickaxe(pick)
	pick.itemData.condition = pick.itemData.condition - 7
	-- Unequip if broken
	if pick.itemData.condition <= 0 then
		pick.itemData.condition = 0
		tes3.mobilePlayer:unequip({ item = pick.object })
	end
end

local function giveRocks()
	timer.start({
		duration = 0.1,
		callback = function()
			local item = math.random() < 0.16 and "ashfall_flint" or "ashfall_stone"
			tes3.addItem({ reference = tes3.player, item = item, showMessage = true })
			tes3.playSound({ reference = tes3.player, sound = "Item Misc Up" })
		end,
	})
end

---@param rock tes3reference
local function breakRock(rock)
	rock.data.miningSwings = rock.data.miningSwings or 0
	rock.data.miningSwings = rock.data.miningSwings + 1
	tes3.playSound({ sound = "Medium Armor Hit" })
	local offset = rock.cell.id == "Masartus, Egg Mine" and tes3vector3.new(16, 0, 0) or tes3vector3.new(0, 0, -16)
	rock.position = rock.position + offset
	rock.modified = true

	-- Mine the ore after enough swings
	if rock.data.miningSwings >= maxSwings then
		rock:disable()
		rock:delete()
	end
end

---@param e attackEventData
local function swing(e)
	if e.reference ~= tes3.player then return end
	timer.start({
		duration = 0.35,
		callback = function()
			local rock = detectRockAhead()
			if not rock then return end
			local pick = holdingPick()
			if not pick then return end
			breakPickaxe(pick)
			giveRocks()
			breakRock(rock)
		end,
	})
end
event.register("attack", swing, { priority = 10 })

---@param e activateEventData
local function message(e)
	if not e.target then return end
	if not e.target.object.id:startswith(rockId) then return end
	local readiedWeapon = tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object
	if readiedWeapon and readiedWeapon.id:lower():find("pick") then
		tes3.messageBox("Я могу использовать кирку, чтобы добывать камни.")
	else
		tes3.messageBox("Мне нужна кирка, чтобы добывать камни.")
	end
end
event.register("activate", message)

local function checkUpdateJournal()
	if tes3.player.data.ass.rockJournalUpdated then return end
	if not tes3.player.cell.id:startswith("Masartus") then return end

	local rock1Ref = tes3.getReference("jsmk_ass_ac_rock01")
	if rock1Ref then
		if tes3.player.position:distance(rock1Ref.position) < 256 then
			tes3.updateJournal({ id = "jsmk_ass", index = 15, showMessage = true })
			tes3.player.data.ass.rockJournalUpdated = true
			return
		end
	end

	local rock3Ref = tes3.getReference("jsmk_ass_ac_rock03")
	if rock3Ref then
		if tes3.player.position:distance(rock3Ref.position) < 256 then
			tes3.updateJournal({ id = "jsmk_ass", index = 16, showMessage = true })
			tes3.player.data.ass.rockJournalUpdated = true
			return
		end
	end

	timer.start({ duration = 1, callback = checkUpdateJournal })
end

event.register("loaded", function()
	if tes3.player.data.ass.rockJournalUpdated then return end
	timer.start({ duration = 1, callback = checkUpdateJournal })
end)
