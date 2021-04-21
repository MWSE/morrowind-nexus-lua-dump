local config = require("OEA.OEA10 Fresh.config")
local this = {}

local function nukeDefaultChargen()
	mwscript.stopScript{script="CharGen"}
	
	if (tes3.getGlobal("CharGenState") == -1) then
		return
	end

	local keyBase = tes3.getObject("key_camp")
	local miscItem = tes3misc.create({
		id = "OEA_Fargoth_Key",
		name = "Fargoth's House Key",
		mesh = keyBase.mesh,
		icon = keyBase.icon
	})
	miscItem.mesh = keyBase.mesh
	miscItem.icon = keyBase.icon
	miscItem.isKey = true

	local fargoth = tes3.getObject("fargoth")

	fargoth.class.playable = true
	tes3.player.baseObject.class = fargoth.class

	tes3.player.baseObject.head = fargoth.head
	tes3.player.baseObject.hair = fargoth.hair
	tes3.player.baseObject.race = fargoth.race

	tes3.player.baseObject.name = fargoth.name

	for sign, id in pairs(tes3.dataHandler.nonDynamicData.birthsigns) do
		--mwse.log(("[OEA10] sign %s"):format(sign))
		--mwse.log(("[OEA10] id %s"):format(id))
		if (sign == 12) then
			--mwse.log("[OEA10] Got to sign adding")
			tes3.mobilePlayer.birthsign = id
			break
		end
	end
	
	tes3.runLegacyScript({ command = "EnablePlayerControls" })
	tes3.runLegacyScript({ command = "EnableMapMenu" })
	tes3.runLegacyScript({ command = "EnableMagicMenu" })
	tes3.runLegacyScript({ command = "EnableStatsMenu" })
	tes3.runLegacyScript({ command = "EnableInventoryMenu" })
	tes3.runLegacyScript({ command = "EnableVanityMode" })
	tes3.runLegacyScript({ command = "EnablePlayerViewSwitch" })
	tes3.runLegacyScript({ command = "EnableRest" })
	tes3.runLegacyScript({ command = "EnablePlayerFighting" })
	tes3.runLegacyScript({ command = "EnablePlayerMagic" })
	tes3.setGlobal("CharGenState", -1)

	mwscript.addTopic({ topic = "Background" })
	mwscript.addTopic({ topic = "little advice" })
	mwscript.addTopic({ topic = "little secret" })
	mwscript.addTopic({ topic = "specific place" })
	mwscript.addTopic({ topic = "someone in particular" })
	mwscript.addTopic({ topic = "services" })
	mwscript.addTopic({ topic = "my trade" })
	mwscript.addTopic({ topic = "latest rumors" })
end

local function nukeDefaultJiubIntro()
	mwscript.stopScript{script="CharGenNameNPC"}
end

local function CharGenCustomsDoor()
	mwscript.stopScript{script="CharGenCustomsDoor"}
end

local function CharGenBed()
	mwscript.stopScript{script="CharGenBed"}
end

local function CharGenJournalMessage()
	mwscript.stopScript{script="CharGenJournalMessage"}
end

local function CharGenDagger()
	mwscript.stopScript{script="CharGenDagger"}
end

local function CharGenDialogueMessage()
	mwscript.stopScript{script="CharGenDialogueMessage"}
end

local function CharGenDoorEnterCaptain()
	mwscript.stopScript{script="CharGenDoorEnterCaptain"}
end

local function CharGenDoorExitCaptain()
	mwscript.stopScript{script="CharGenDoorExitCaptain"}
end

local function CharGenFatigueBarrel()
	mwscript.stopScript{script="CharGenFatigueBarrel"}
end

local function CharGen_ring_keley()
	mwscript.stopScript{script="CharGen_ring_keley"}
end

local function CharGenWalkNPC()
	mwscript.stopScript{script="CharGenWalkNPC"}
end

local function CharGenStatsSheet()
	mwscript.stopScript{script="CharGenStatsSheet"}
end

local function CharGenRaceNPC()
	mwscript.stopScript{script="CharGenRaceNPC"}
end

local function CharGenDoorGuardTalker()
	mwscript.stopScript{script="CharGenDoorGuardTalker"}
end

local function CharGenDoorExit()
	mwscript.stopScript{script="CharGenDoorExit"}
end

local function CharGenClassNPC()
	mwscript.stopScript{script="CharGenClassNPC"}
end

local function CharGenBoatWomen()
	mwscript.stopScript{script="CharGenBoatWomen"}
end

local function CharGenBoatNPC()
	mwscript.stopScript{script="CharGenBoatNPC"}
end

local function CharGenStuffRoom()
	mwscript.stopScript{script="CharGenStuffRoom"}
end

local function FargothWalking()
	mwscript.stopScript{ script="lookoutScript" }
end

local function DBAttacks()
	mwscript.stopScript{ script = "dbattackScript" }
end

local function TDM()
	mwscript.stopScript{ script = "FargothAlternateStartChargen" }
end

function this.overrideScripts()
	if (config.AltStart == false) then
		return
	end

	mwse.overrideScript("CharGen", nukeDefaultChargen)
	mwse.overrideScript("CharGenNameNPC", nukeDefaultJiubIntro)
	mwse.overrideScript("CharGen_ring_keley", CharGen_ring_keley)
	mwse.overrideScript("CharGenBoatNPC", CharGenBoatNPC)
	mwse.overrideScript("CharGenBoatWomen", CharGenBoatWomen)
	mwse.overrideScript("CharGenClassNPC", CharGenClassNPC)
	mwse.overrideScript("CharGenDoorExit", CharGenDoorExit)
	mwse.overrideScript("CharGenDoorGuardTalker", CharGenDoorGuardTalker)
	mwse.overrideScript("CharGenRaceNPC", CharGenRaceNPC)
	mwse.overrideScript("CharGenStatsSheet", CharGenStatsSheet)
	mwse.overrideScript("CharGenWalkNPC", CharGenWalkNPC)
	mwse.overrideScript("CharGenCustomsDoor", CharGenCustomsDoor)
	mwse.overrideScript("CharGenJournalMessage", CharGenJournalMessage)
	mwse.overrideScript("CharGenBed", CharGenBed)
	mwse.overrideScript("CharGenDagger", CharGenDagger)
	mwse.overrideScript("CharGenDialogueMessage", CharGenDialogueMessage)
	mwse.overrideScript("CharGenDoorEnterCaptain", CharGenDoorEnterCaptain)
	mwse.overrideScript("CharGenDoorExitCaptain", CharGenDoorExitCaptain)
	mwse.overrideScript("CharGenFatigueBarrel", CharGenFatigueBarrel)
	mwse.overrideScript("CharGenStuffRoom", CharGenStuffRoom)
	mwse.overrideScript("lookoutScript", FargothWalking)
	mwse.overrideScript("dbattackScript", DBAttacks)

	if (config.Dial == false) then
		mwse.overrideScript("FargothAlternateStartChargen", TDM)
	end
end

return this