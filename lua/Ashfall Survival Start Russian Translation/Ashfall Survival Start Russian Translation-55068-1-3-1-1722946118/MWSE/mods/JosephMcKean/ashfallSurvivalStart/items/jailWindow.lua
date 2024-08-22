local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then return end

local jailWindowId = "jsmk_ass_in_jail"
local minLookDistance = 230
local maxSwings = 3

---@return tes3reference? jailWindow
local function detectJailWindowAhead()
	local result = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = { tes3.player } })
	if not result then return end
	if not (result.reference and result.reference.id:startswith(jailWindowId)) then return end
	local jailWindow = result.reference
	local distance = tes3.player.position:distance(result.intersection)
	if distance > minLookDistance then return end
	return jailWindow
end

---@return tes3equipmentStack? pick
local function holdingPick()
	local readiedWeapon = tes3.mobilePlayer.readiedWeapon
	if not readiedWeapon then return end
	if not readiedWeapon.object.id:lower():find("pick") then return end
	return readiedWeapon
end

---@param jailWindow tes3reference
---@param pick tes3equipmentStack 
local function breakPickaxe(jailWindow, pick)
	pick.itemData.condition = pick.itemData.condition - 21
	-- Break the pick axe after enough swings
	jailWindow.data.breakSwings = jailWindow.data.breakSwings or 0
	if jailWindow.data.breakSwings >= maxSwings then pick.itemData.condition = 0 end
	-- Unequip if broken
	if pick.itemData.condition <= 0 then
		pick.itemData.condition = 0
		tes3.mobilePlayer:unequip({ item = pick.object })
	end
end

---@param jailWindow tes3reference
local function breakJailWindow(jailWindow)
	jailWindow.data.breakSwings = jailWindow.data.breakSwings or 0
	jailWindow.data.breakSwings = jailWindow.data.breakSwings + 1
	tes3.playSound({ sound = "Light Armor Hit" })

	-- Break the jail window after enough swings
	if jailWindow.data.breakSwings >= maxSwings then
		tes3.fadeOut({ duration = 0.01 })
		local monastery = tes3.getCell({ id = "Masartus, Monastery" })
		if not monastery then return end
		tes3.playSound({ soundPath = "jsmk\\ass\\rubble.wav" })
		tes3.createReference({ object = "jsmk_ass_in_rubble", cell = monastery, position = tes3vector3.new(334.623, -27.819, -69.138), orientation = tes3vector3.new() })

		jailWindow:disable()
		jailWindow:delete()
		tes3.fadeIn({ duration = 2.99 })
	end
end

local function inAnchoressCell()
	local playerPos = tes3.player.position
	local jailPos = tes3.getReference(jailWindowId).position
	return playerPos.x > jailPos.x
end

---@param e attackEventData
local function swing(e)
	if e.reference ~= tes3.player then return end
	local cell = tes3.player.cell
	if cell.id ~= "Masartus, Monastery" then return end
	if not inAnchoressCell() then return end
	timer.start({
		duration = 0.3,
		callback = function()
			local jailWindow = detectJailWindowAhead()
			if not jailWindow then return end
			local pick = holdingPick()
			if not pick then return end
			breakJailWindow(jailWindow)
			breakPickaxe(jailWindow, pick)
		end,
	})
end
event.register("attack", swing, { priority = 10 })

---@param reference tes3reference
local function activateJailWindow(reference)
	if reference and reference.id ~= jailWindowId then return end
	if not inAnchoressCell() then
		if not tes3.player.data.ass.hasMap then tes3.messageBox("Там что-то есть.") end
	else
		local readiedWeapon = tes3.mobilePlayer.readiedWeapon
		if readiedWeapon and readiedWeapon.object and readiedWeapon.object.id:lower():find("pick") then
			tes3.messageBox("Я могу использовать кирку, чтобы сломать эту стену.")
		else
			tes3.messageBox("Мне нужна кирка, чтобы сломать эту стену.")
		end
	end
end

CraftingFramework.StaticActivator.register({ objectId = jailWindowId, name = "Решетка в стене", onActivate = activateJailWindow })
