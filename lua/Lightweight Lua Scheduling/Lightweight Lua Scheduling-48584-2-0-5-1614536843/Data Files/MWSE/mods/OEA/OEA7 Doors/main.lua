local config = require("OEA.OEA7 Doors.config")

local Timer

local function Mobile(e)
	if (tes3.getGlobal("CharGenState") == nil) or (tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	local npc = e.reference
	local mobile = e.mobile

	if (e.reference == nil) or (e.reference.baseObject.objectType ~= tes3.objectType.npc) then
		return
	end

	if (tes3.player.cell.isInterior == true) and (tes3.player.cell.behavesAsExterior == false) then
		if (config.Crime == true) and not (config.IsBlocked[tes3.player.cell.id:lower()]) and not (table.find(tes3.mobilePlayer.friendlyActors, mobile)) and not (table.find(tes3.mobilePlayer.hostileActors, mobile)) then
			if ((tes3.worldController.hour.value > config.Start) or (tes3.worldController.hour.value < config.End)) and (npc ~= nil) then
				if not (config.IsBlocked[npc.baseObject.sourceMod:lower()]) and not (config.IsBlocked[npc.baseObject.id:lower()]) then
					if (npc.baseObject.class.id ~= "Publican") and (tes3.isAffectedBy({ reference = npc, effect = tes3.effect.vampirism }) == false) then
						if (mwscript.getSpellEffects({ reference = npc, spell = "werewolf vision" }) == false) and (mobile.health.current > 0) then
							npc.data.OEA7 = { [2] = mobile.hello }
							mobile.hello = 0
							npc.modified = true
							--mwse.log("[OEA7] The new Hello for %s is %s", npc.baseObject.name, mobile.hello)
						end
					end
				end
			end
		end

		if ((tes3.worldController.hour.value <= config.Start) and (tes3.worldController.hour.value >= config.End)) then
			if (npc == nil) then
				for NPC in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
					if (NPC.data.OEA7 ~= nil) and (NPC.data.OEA7[2] ~= nil) and (NPC.data.OEA7[2] < 500) then
						NPC.mobile.hello = NPC.data.OEA7[2]
						NPC.data.OEA7[2] = 500
						--mwse.log("[OEA7] The old Hello for %s is %s", NPC.baseObject.name, NPC.mobile.hello)
					end
				end
			else
				if (npc.data.OEA7 ~= nil) and (npc.data.OEA7[2] ~= nil) and (npc.data.OEA7[2] < 500) then
					mobile.hello = npc.data.OEA7[2]
					npc.data.OEA7[2] = 500
					--mwse.log("[OEA7] The old Hello for %s is %s", npc.baseObject.name, mobile.hello)
				end
			end
		end
	end
end

local function Changed(e)
	local Check

	if (tes3.getGlobal("CharGenState") == nil) or (tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	if (e.cell == nil) then
		e.cell = tes3.player.cell
	end

	if (e.cell.isInterior == true) and (e.cell.behavesAsExterior == false) then
		if (config.Crime == true) then
			if ((tes3.worldController.hour.value > config.Start) or (tes3.worldController.hour.value < config.End)) then
				tes3.player.data.OEA7 = { [1] = 1 }
			else
				tes3.player.data.OEA7 = { [1] = 0 }
			end
		else
			tes3.player.data.OEA7 = { [1] = 0 }
		end
		Mobile(e)
		return
	end
	tes3.player.data.OEA7 = { [1] = 0 }

	if (config.IsBlocked[e.cell.id:lower()]) then
		return
	end

	--mwse.log("[OEA7] The hour is: %s", tes3.worldController.hour.value)
	for npc in e.cell:iterateReferences(tes3.objectType.npc) do
		if (config.Person == true) and not (config.IsBlocked[npc.baseObject.id:lower()]) and (tes3.isAffectedBy({ reference = npc, effect = tes3.effect.vampirism }) == false) then
			if (npc.baseObject.class.id ~= "Dreamers") and (npc.baseObject.isGuard == false) and (npc.mobile ~= nil) and (npc.mobile.health.current > 0) and not (table.find(tes3.mobilePlayer.friendlyActors, npc.mobile)) then
				if (mwscript.getSpellEffects({ reference = npc, spell = "werewolf vision" }) == false) and not (config.IsBlocked[npc.baseObject.sourceMod:lower()]) and not (table.find(tes3.mobilePlayer.hostileActors, npc.mobile)) then
					--mwse.log("[OEA7] People change")
					if (tes3.worldController.hour.value > config.Start) or (tes3.worldController.hour.value < config.End) then
						if (npc.data.OEA7 == nil) then
							npc.data.OEA7 = {}
						end

						if (mwscript.getDisabled({ reference = npc }) == false) then
							npc.data.OEA7[1] = 1
							npc.modified = true
							mwscript.disable({ reference = npc })
							--mwse.log("[OEA7] Disabling works on %s", npc.baseObject.name)
						end
					end
					if (config.Rain == true) then
						if (e.cell.region.weather.index >= config.worstWeather) then
							if (npc.data.OEA7 == nil) then
								npc.data.OEA7 = {}
							end

							if (mwscript.getDisabled({ reference = npc }) == false) then
								npc.data.OEA7[2] = 1
								npc.modified = true
								mwscript.disable({ reference = npc })
								--mwse.log("[OEA7] Rain disabling works on %s", npc.baseObject.name)
							end
						end
					end
				end
			end
		end

		if ((tes3.worldController.hour.value <= config.Start) and (tes3.worldController.hour.value >= config.End)) then
			if (npc.data.OEA7 == nil) then
				npc.data.OEA7 = {}
			end

			if (npc.data.OEA7[1] ~= nil) and (npc.data.OEA7[1] == 1) then
				npc.data.OEA7[1] = 0
				mwscript.enable({ reference = npc })
				--mwse.log("[OEA7] Enabling works on %s", npc.baseObject.name)
			end
		end

		if (e.cell.region.weather.index < config.worstWeather) then
			if (npc.data.OEA7 == nil) then
				npc.data.OEA7 = {}
			end

			if (npc.data.OEA7[2] ~= nil) and (npc.data.OEA7[2] == 1) then
				npc.data.OEA7[2] = 0
				mwscript.enable({ reference = npc })
				--mwse.log("[OEA7] Rain enabling works on %s", npc.baseObject.name)
			end
		end
	end

	for door in e.cell:iterateReferences(tes3.objectType.door) do
		--mwse.log("[OEA7] Travel: %s", door.destination ~= nil)
		if (config.Lock == true) and (door.destination ~= nil) and (door.id ~= "PrisonMarker") and (string.sub (e.cell.id:lower(), 1, 4) == string.sub (door.destination.cell.id:lower(), 1, 4)) then
			--mwse.log("[OEA7] It knows there's a door")
			for npc in door.destination.cell:iterateReferences(tes3.objectType.npc) do
				if (npc.baseObject.class.id == "Publican") then
					if (Check == nil) then
						Check = 1
					else
						Check = Check + 1
					end
				end
			end
			--mwse.log("[OEA7] Tables kinda work")

			--mwse.log("[OEA7] Locked Status: %s", tes3.getLocked({ reference = door }))
			if ((tes3.worldController.hour.value > config.Start) or (tes3.worldController.hour.value < config.End)) and not (config.IsBlocked[door.destination.cell.id:lower()]) then
				if (tes3.getLocked({ reference = door }) == false) and ((Check == nil) or (Check == 0)) then
					if (door.data.OEA7 == nil) or (door.data.OEA7[1] == 0) then
						--mwse.log("[OEA7] It should lock now")
						--mwse.log("[OEA7] What door is this anyway: %s to %s", door.baseObject.name, door.destination.cell.id)
						local Random = math.random(25, 100)
						tes3.lock({ reference = door, level = Random })
						door.data.OEA7 = { [1] = 1 }
						door.modified = true
					end
				end
			end
		end
		Check = 0
		
		if ((tes3.worldController.hour.value <= config.Start) and (tes3.worldController.hour.value >= config.End)) then
			if (door.data.OEA7 ~= nil) and (door.data.OEA7[1] == 1) then
				door.data.OEA7[1] = 0
				tes3.setLockLevel({ reference = door, level = 0 })
				tes3.unlock({ reference = door })
				--mwse.log("[OEA7] It should unlock now")
				--mwse.log("[OEA7] What unlocked door is this anyway: %s to %s", door.baseObject.name, door.destination.cell.id)
			end
		end
	end
end

local function Activated(e)
	if (e.activator ~= tes3.player) then
		return
	end

	if (tes3.getGlobal("CharGenState") == nil) or (tes3.getGlobal("CharGenState") ~= -1) then
		return
	end

	if (e.target.baseObject.objectType == tes3.objectType.npc) and (tes3.player.data.OEA7[1] == 1) and not (config.IsBlocked[e.target.baseObject.sourceMod:lower()]) then
		if (e.target.baseObject.class.id ~= "Publican") and (tes3.isAffectedBy({ reference = e.target, effect = tes3.effect.vampirism }) == false) and (e.target.mobile.health.current > 0) then
			if (mwscript.getSpellEffects({ reference = e.target, spell = "werewolf vision" }) == false) and not (config.IsBlocked[e.target.baseObject.id:lower()]) then
				if not (config.IsBlocked[tes3.player.cell.id:lower()]) and not (table.find(tes3.mobilePlayer.friendlyActors, e.target.mobile)) and not (table.find(tes3.mobilePlayer.hostileActors, e.target.mobile)) then
					tes3.messageBox("You cannot talk to this person right now, they are sleeping (use your imagination).")
					return false
				end
			end
		end
	end
end

local function KeyDown(e)
	if e.keyCode == config.Button.keyCode and not tes3.menuMode() then
		if (config.Message == true) then
			tes3.messageBox("[Lightweight Lua Scheduling] The cellChange button has been pressed.")
		end
		Changed(e)
	end
end

local function Frame(e)
	if (Timer == nil) then
		Timer = 0
	else
		Timer = Timer + e.delta
		if (Timer >= 5) then
			Timer = 0
			Changed(e)
		end
	end
end

local function Load(e)
	event.register("cellChanged", Changed, {priority = -100000})
	event.register("activate", Activated)
	event.register("keyDown", KeyDown)
	if (config.Timing == true) then
		event.register("simulate", Frame)
	end
	event.register("mobileActivated", Mobile)
	mwse.log("[Lightweight Lua Scheduling] Initialized.")
end

event.register("initialized", Load)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
	require("OEA.OEA7 Doors.mcm")
end)

