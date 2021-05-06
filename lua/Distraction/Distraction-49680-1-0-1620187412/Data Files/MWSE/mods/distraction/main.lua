--[[
	Distraction
	Author: mort
	v1.0
]] --

local config = require("distraction.config")

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20210412) then
	mwse.log("[Distraction] Build date of %s does not meet minimum build date of 2021-04-12.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("Distraction requires a newer version of MWSE. Please run MWSE-Update.exe.")
		end
	)
	return
end

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("distraction.mcm")
end)

local GUI_Distraction_multi = nil
local GUI_Distraction_sneak = nil

local function validNPCCheck(actor)
	-- The player shouldn't count as his own companion.
	if (actor.mobile == tes3.getMobilePlayer()) then
		return false
	end

	-- Make sure we don't teleport dead actors.
	if (actor.mobile.health.current <= 0) then
		return false
	end
	
	-- NPCs in combat don't care
	if (actor.mobile.inCombat == true ) then
		return false
	end
	
	if actor.data.distractCount then
		if actor.data.distractCount >= config.distractCountLimit then
			return false
		end
	end
	
	if actor.mobile.aiPlanner:getActivePackage() == nil then --no package
		return true
	elseif actor.mobile.aiPlanner:getActivePackage().type == 0 then --wander
		return true
	elseif actor.mobile.aiPlanner:getActivePackage().type == 1 and actor.data.distractCount then --ai travel, but a valid target
		return true
	end
end

local function turnToFace(npc,thing)
	local dir = (thing.position - npc.position)
	local angle = math.atan2(dir.x, dir.y)
	local matrix = tes3matrix33.new()
	matrix:toRotation(angle, 0, 0, 1)
	npc.orientation = matrix
end

local function getVoiceLine(ref)
	local race = ref.object.race.name
	local female = ref.object.female
	local soundpath = ""

	if race == "Argonian" and female == false then
		local idleVo = {"vo\\a\\m\\Idl_AM001.mp3","vo\\a\\m\\Hlo_AM000e.mp3","vo\\a\\m\\Hlo_AM053.mp3","vo\\a\\m\\Hlo_AM056.mp3","vo\\a\\m\\Hlo_AM059.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Argonian" and female == true then
		local idleVo = {"vo\\a\\f\\Idl_AF007.mp3","vo\\a\\f\\Idl_AF001.mp3","vo\\a\\f\\Idl_AF002.mp3","vo\\a\\f\\Idl_AF004.mp3","vo\\a\\f\\Idl_AF008.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Breton" and female == false then
		local idleVo = {"vo\\b\\m\\Idl_BM006.mp3","vo\\b\\m\\Idl_BM007.mp3","vo\\b\\m\\Idl_BM008.mp3","vo\\b\\m\\Idl_BM009.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Breton" and female == true then
		local idleVo = {"vo\\b\\f\\Idl_BF001.mp3","vo\\b\\f\\Idl_BF005.mp3","vo\\b\\f\\Idl_BF008.mp3","vo\\b\\f\\Idl_BF009.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Dark Elf" and female == false then
		--local idleVo = {"vo\\d\\m\\Idl_DM007.mp3","vo\\d\\m\\Idl_DM002.mp3","vo\\d\\m\\Idl_DM003.mp3","vo\\d\\m\\Idl_DM006.mp3"}
		--soundpath = idleVo[math.random(#idleVo)]
		soundpath = "vo\\d\\m\\Idl_DM007.mp3"
	end
	if race == "Dark Elf" and female == true then
		local idleVo = {"vo\\d\\f\\Idl_DF001.mp3","vo\\d\\f\\Idl_DF002.mp3","vo\\d\\f\\Idl_DF003.mp3","vo\\d\\f\\Idl_DF004.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "High Elf" and female == false then
		local idleVo = {"vo\\h\\m\\Idl_HM007.mp3","vo\\h\\m\\Idl_HM008.mp3","vo\\h\\m\\Idl_HM009.mp3","vo\\h\\m\\Hlo_HM056.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "High Elf" and female == true then
		local idleVo = {"vo\\h\\f\\Idl_HF007.mp3","vo\\h\\f\\Idl_HF001.mp3","vo\\h\\f\\Idl_HF002.mp3","vo\\h\\f\\Idl_HF008.mp3","vo\\h\\f\\Hlo_HF056.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Imperial" and female == false then
		local idleVo = {"vo\\i\\m\\Idl_IM008.mp3","vo\\i\\m\\Idl_IM001.mp3","vo\\i\\m\\Idl_IM002.mp3","vo\\i\\m\\Idl_IM003.mp3","vo\\i\\m\\Idl_IM005.mp3","vo\\i\\m\\Idl_IM007.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Imperial" and female == true then
		local idleVo = {"vo\\i\\f\\Idl_IF001.mp3","vo\\i\\f\\Idl_IF004.mp3","vo\\i\\f\\Idl_IF005.mp3","vo\\i\\f\\Idl_IF007.mp3","vo\\i\\f\\Idl_IF008.mp3","vo\\i\\f\\Idl_IF009.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Khajiit" and female == false then
		local idleVo = {"vo\\k\\m\\Idl_KM005.mp3","vo\\k\\m\\Idl_KM003.mp3","vo\\k\\m\\Idl_KM004.mp3","vo\\k\\m\\Idl_KM006.mp3","vo\\k\\m\\Idl_KM007.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Khajiit" and female == true then
		local idleVo = {"vo\\k\\f\\Idl_KF005.mp3","vo\\k\\f\\Idl_KF003.mp3","vo\\k\\f\\Idl_KF006.mp3","vo\\k\\f\\Idl_KF007.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Nord" and female == false then
		local idleVo = {"vo\\n\\m\\Idl_NM009.mp3","vo\\n\\m\\Idl_NM001.mp3","vo\\n\\m\\Idl_NM002.mp3","vo\\n\\m\\Idl_NM005.mp3","vo\\n\\m\\Idl_NM006.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Nord" and female == true then
		local idleVo = {"vo\\n\\f\\Idl_NF002.mp3","vo\\n\\f\\Idl_NF004.mp3","vo\\n\\f\\Idl_NF006.mp3","vo\\n\\f\\Idl_NF007.mp3","vo\\n\\f\\Hlo_NF058.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Orc" and female == false then
	local idleVo = {"vo\\o\\m\\Idl_OM001.mp3","vo\\o\\m\\Idl_OM002.mp3","vo\\o\\m\\Idl_OM004.mp3","vo\\o\\m\\Idl_OM009.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Orc" and female == true then
		local idleVo = {"vo\\o\\f\\Idl_OF009.mp3","vo\\o\\f\\Idl_OF002.mp3","vo\\o\\f\\Idl_OF005.mp3","vo\\o\\f\\Hlo_OF060.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Redguard" and female == false then
		local idleVo = {"vo\\r\\m\\Idl_RM009.mp3","vo\\r\\m\\Idl_RM008.mp3","vo\\r\\m\\Hlo_RM043.mp3","vo\\r\\m\\Hlo_RM060.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Redguard" and female == true then
		local idleVo = {"vo\\r\\f\\Idl_RF002.mp3","vo\\r\\f\\Idl_RF006.mp3","vo\\r\\f\\Idl_RF007.mp3","vo\\r\\f\\Idl_RF008.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Wood Elf" and female == false then
		local idleVo = {"vo\\w\\m\\Idl_WM009.mp3","vo\\w\\m\\Idl_WM003.mp3","vo\\w\\m\\Idl_WM006.mp3","vo\\w\\m\\Idl_WM008.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end
	if race == "Wood Elf" and female == true then
		local idleVo = {"vo\\w\\f\\Idl_WF006.mp3","vo\\w\\f\\Idl_WF002.mp3","vo\\w\\f\\Idl_WF003.mp3","vo\\w\\f\\Idl_WF007.mp3","vo\\w\\f\\Idl_WF009.mp3"}
		soundpath = idleVo[math.random(#idleVo)]
	end

	return(soundpath)
end

local function getReturnVoiceLine(ref)
	local idleVo
	
	local race = ref.object.race.name
	local female = ref.object.female
	
	if race == "Dark Elf" and female == false then
		idleVo = "vo\\d\\m\\Idl_DM008.mp3"
	end

	if race == "Dark Elf" and female == false then
		idleVo = "vo\\d\\f\\Idl_DF006.mp3"
	end	
	
	return(idleVo)
end

local function storeOriginalAI(ref)
	if ref.mobile.aiPlanner:getActivePackage() == nil then
		ref.data.distraction = {
		type = "idle",
		position = {
			ref.position.x, 
			ref.position.y,
			ref.position.z
		},
		orientation = {
			ref.orientation.x,
			ref.orientation.y,
			ref.orientation.z
		},
		cell = ref.cell.id,
		wanderTime = 0,
		wanderRange = 0,
		wanderDuration = 0,
		wanderIdles = {40,20,20,10,0,0,0,0} --best guess
		}
	elseif ref.mobile.aiPlanner:getActivePackage().type == 0 then
		local aipackage = ref.mobile.aiPlanner:getActivePackage()
		local idles = {}
		for k,v in pairs(aipackage.idles) do
			idles[k] = v.chance
		end
		ref.data.distraction = {
			type = "wander",
			position = {
				ref.position.x, 
				ref.position.y,
				ref.position.z
			},
			orientation = {
				ref.orientation.x,
				ref.orientation.y,
				ref.orientation.z
			},
			cell = ref.cell.id,
			wanderTime = aipackage.time,
			wanderRange = aipackage.distance,
			wanderDuration = aipackage.duration,
			wanderIdles = idles
		}
	end
end

local function resetAI(ref,playerInZone)
	local olddata = ref.data.distraction
	
	if config.playNPCReturnSounds then
		if playerInZone == true and ref.inCombat == false then
			local sound = getReturnVoiceLine(ref)
			if getReturnVoiceLine(ref) then
				tes3.say({reference=ref, soundPath=sound})
			end
		end
	end
	
	if olddata.type == "idle" then --if they didn't have an AI package, give them some defaults
		tes3.positionCell({reference=ref,cell=olddata.cell,orientation=olddata.orientation,position=olddata.position})
		tes3.setAIWander({reference=ref,idles=olddata.wanderIdles,range=0,duration=olddata.wanderDuration,time=0})
	else
		tes3.setAIWander({reference=ref,idles=olddata.wanderIdles,range=olddata.wanderRange,duration=olddata.wanderDuration,time=0})
	end
	
end

local function npcReaction(e,inputDistractDistance,inputDistractTime)
    local projectile = e.mobile
	local distractDistance = config.strikeDistance
	local distractTime = config.distractTime

	local inputDistractDistance = inputDistractDistance
	local inputDistractTime = inputDistractTime
	
	if inputDistractDistance then
		distractDistance = inputDistractDistance
	end
	
	if inputDistractTime then
		distractTime = inputDistractTime
	end
	
	-- If people can see you, this won't work
	if ( tes3ui.findMenu(GUI_Distraction_multi):findChild(GUI_Distraction_sneak).visible ) == false then
		return
	else
		for _, cell in pairs(tes3.getActiveCells()) do
			for ref in cell:iterateReferences(tes3.objectType.npc) do
				if validNPCCheck(ref) then
					local distance = projectile.position:distance(ref.position)
					if distance < distractDistance then
						--only store original AI once
						if ref.data.distraction == nil then
							storeOriginalAI(ref)
						end
						turnToFace(ref,projectile)

						if config.playNPCSounds then
							local sound = getVoiceLine(ref)
							tes3.say({reference=ref, soundPath=sound})
						end
						
						if ref.data.distractCount then
							ref.data.distractCount = ref.data.distractCount + 1
						else
							ref.data.distractCount = 1
						end
						
						if ref.data.distraction.type ~= "idle" then
							--NPCs without default wander states must wait until cellchanged to reset
							timer.start({duration = distractTime, callback = function() resetAI(ref,true) end})
						end
						
						tes3.setAITravel({reference=ref, destination=projectile.position})
					end
				end
			end
		end
	end
end

local function resetAICellChanged(e)
--reset AI if they have been distracted
	for _, cell in pairs(tes3.getActiveCells()) do
		for ref in cell:iterateReferences(tes3.objectType.npc) do
			if ref.data.distractCount then
				if ref.data.distractCount > 0 then
					if config.cellChangeReset == true then
						ref.data.distractCount = 0
					end
					resetAI(ref,false)
				end
			end
		end
	end
end

local function onHitObject(e)
	if config.modEnabled then
		npcReaction(e)
	end
end

local function onHitTerrain(e)
	if config.modEnabled then
		npcReaction(e)
	end
end

local function spellHit(e)
	if config.modEnabled and config.soundMagicEnabled then
		if e.mobile.spellInstance then
			for k,_ in pairs(e.mobile.spellInstance.sourceEffects) do
				if e.mobile.spellInstance.sourceEffects[k].id == 48 then
					local avg = (e.mobile.spellInstance.sourceEffects[k].max+e.mobile.spellInstance.sourceEffects[k].min)/2
					avg = math.clamp(avg*50,150,config.soundMagicDistanceMax)
					npcReaction(e,avg)
				end
			end
		end
	end
end

local function onInitialized(mod)
	GUI_Distraction_multi = tes3ui.registerID("MenuMulti")
	GUI_Distraction_sneak = tes3ui.registerID("MenuMulti_sneak_icon")
    event.register("projectileHitObject", onHitObject)
    event.register("projectileHitTerrain", onHitTerrain)
	event.register("projectileExpire", spellHit)
	event.register("cellChanged", resetAICellChanged)
	--mwse.memory.writeBytes{address=0x550F81, bytes={0x74}}
    mwse.log("[Distraction] Loaded successfully.")
end
event.register("initialized", onInitialized)