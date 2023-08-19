local servo = {}

servo.OnServerInit = function(eventStatus)

	local recordStoreBody = RecordStores["bodypart"].data.permanentRecords
	local recordStoreSpell = RecordStores["spell"].data.permanentRecords

	if not recordStoreBody["servoSkull"] then

		recordStoreBody["servoSkull"] = {
			subtype = 0,
			part = 0,
			model = "TSI\\40k\\ServoMicro.nif"
		}

		RecordStores["bodypart"]:Save()

		tes3mp.LogAppend(enumerations.log.INFO, "[SERVO]: Created servo skull head record.")
	end

	if not recordStoreSpell["servo levitate"] then

		recordStoreSpell["servo levitate"] = {
			name = "Servo Skull Levitation",
			subtype = 3,
			cost = 0,
			flags = 0,
			effects = {{
				id = enumerations.effects.LEVITATE,
				attribute = -1,
				skill = -1,
				rangeType = 0,
				duration = -1,
				area = 0,
				magnitudeMin = 75,
				magnitudeMax = 75
			}}
		}

		RecordStores["spell"]:Save()

		tes3mp.LogAppend(enumerations.log.INFO, "[SERVO]: Created servo skull levitate record.")
	end

	if not recordStoreSpell["servo regen"] then

		recordStoreSpell["servo regen"] = {
			name = "Servo Skull Blessing",
			subtype = 3,
			cost = 0,
			flags = 0,
			effects = {{
				id = enumerations.effects.RESTORE_MAGICKA,
				attribute = -1,
				skill = -1,
				rangeType = 0,
				duration = -1,
				area = 0,
				magnitudeMin = 3,
				magnitudeMax = 3
			}}
		}

		RecordStores["spell"]:Save()

		tes3mp.LogAppend(enumerations.log.INFO, "[SERVO]: Created servo skull regen record.")
	end

	if not recordStoreSpell["servo blast"] then

		recordStoreSpell["servo blast"] = {
			name = "Servo Skull Blaster",
			subtype = 0,
			cost = 15,
			flags = 4,
			effects = {{
				id = enumerations.effects.FIRE_DAMAGE,
				attribute = -1,
				skill = -1,
				rangeType = 2,
				duration = -1,
				area = 3,
				magnitudeMin = 10,
				magnitudeMax = 15
			}}
		}

		RecordStores["spell"]:Save()

		tes3mp.LogAppend(enumerations.log.INFO, "[SERVO]: Created servo skull blaster record.")
	end

	if tableHelper.containsCaseInsensitiveString(clientDataFiles, "StarwindRemasteredPatch.esm") or tableHelper.containsCaseInsensitiveString(clientDataFiles, "Starwind.omwaddon") then
		servo.race = "droid"
	else
		servo.race = "nord"
	end
end

servo.transform = function(eventstatus, pid)

    local player = Players[pid]

    if not player or not player:IsLoggedIn() then return end

    local playerBody = player.data.character

    local playerVars = player.data.customVariables

    if playerVars.isServo then return end

    tes3mp.LogAppend(enumerations.log.INFO, "Now transforming " .. tes3mp.GetName(pid) .. " into a servoSkull")

	playerVars.isServo = true

	-- Set servo skull attributes
	servo.overrideBody(pid)

	-- give flight
	table.insert(player.data.spellbook, "servo levitate")

	-- give regen
	table.insert(player.data.spellbook, "servo regen")

	-- add laser beam spell
	table.insert(player.data.spellbook, "servo blast")

	-- Load the new spells
	player:LoadSpellbook()

	-- Make it Permanent
	player:Save()

	-- deathdrop should clear your inventory, but we will if not.
	if not deathdrop then
		for index,item in pairs(player.data.equipment) do
			tes3mp.UnequipItem(pid, index) -- creates unequipItem packet
			tes3mp.SendEquipment(pid) -- sends packet to pid
		end
	end
	-- Everybody gets one
    if not SaintRevive then
        tes3mp.Resurrect(pid, 0)
	end

end

servo.overrideBody = function(pid)

    if not servo.isValidSkull(pid) then return end

    player = Players[pid]

    playerBody = player.data.character

	playerBody.modelOverride = "r\\BYagram.NIF"
	playerBody.race = servo.race
	playerBody.head = "servoSkull"
	playerBody.hair = ""

	player:LoadCharacter()
end

servo.limiter = function(eventStatus, pid)

    if not servo.isValidSkull(pid) then return end

    return customEventHooks.makeEventStatus(false, false)
end

servo.isValidSkull = function(pid)
    local player = Players[pid]

    return player and player:IsLoggedIn() and player.data.customVariables.isServo

end

customEventHooks.registerValidator("OnPlayerItemUse", servo.limiter)

customEventHooks.registerValidator("OnPlayerSkill", servo.limiter)

--customEventHooks.registerHandler("OnPlayerDeath", servo.transform)

customEventHooks.registerHandler("OnServerPostInit", servo.OnServerInit)

return servo
