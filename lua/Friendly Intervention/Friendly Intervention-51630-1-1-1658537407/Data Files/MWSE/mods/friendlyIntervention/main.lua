----Initialize-------------------------------------------------------------------------------------------------------------------
local function initialized()
    print("[Friendly Intervention]: Initialized.")
end
event.register("initialized", initialized)

local config = require("friendlyIntervention.config")

local logger = require("logging.logger")
local log = logger.new{
    name = "Friendly Intervention",
    logLevel = "TRACE",
}
log:setLogLevel(config.logLevel)


local companionTable = {}
local portFlag = 0
local teleType = 0
local scrollType = {
    [0] = "sc_almsiviintervention",
    [1] = "sc_divineintervention",
    [2] = "sc_leaguestep"
}





----Companion Check-------------------------------------------------------------------------------------------------------------
local function validCompanionCheck(mobileActor)
    local name = mobileActor.object.name
    log:trace("Checking " .. name .. "...")
	if (mobileActor == tes3.mobilePlayer) then
		return false
	end
	if (tes3.getCurrentAIPackageId(mobileActor) ~= tes3.aiPackage.follow) then
		return false
	end
	local animState = mobileActor.actionData.animationAttackState
	if (mobileActor.health.current <= 0 or animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
		return false
	end
    local fishCheck = string.endswith(name, "Slaughterfish")
    if fishCheck == true then
        log:debug("" .. name .. " ends with Slaughterfish, invalid companion!")
        return false
    end
	return true
end



----Teleportation-----------------------------------------------------------------------------------------------------------------
local function companionTeleport(companionsT)
	for i = #companionsT, 1, -1 do
		local companionRef = companionsT[i]
        local name = companionRef.object.name
        local modSkill = config.skillLimit
        local modMagic = config.magickaReq
        local modMessage = config.msgEnabled
        local modTrain = config.trainMyst
		local cellPosition = tes3.getPlayerCell()
		local cameraPosition = tes3.getCameraPosition()
        local pitchMod = math.random()
		local pitchMod2 = math.random()
		local pitchMod3 = (pitchMod + pitchMod2)
        local mgkFlag = 1
        local selectionRef = 0
        local portSummary = {
            [0] = "You transported " .. name .. ".",
            [1] = "" .. name .. " transported themselves."
        }
        local mgkChoice = {
            [0] = tes3.player,
            [1] = companionRef
        }
		if pitchMod3 < 0.80 then
			pitchMod3 = 0.80
		end
		if pitchMod3 > 1.20 then
			pitchMod3 = 1.20
		end
        ----Summoned Creature Check----------------------------------------------------------------------------------------------------------------------------
        if config.smnFree == true then
            local smnCheck = string.startswith(name, "Summoned")
            if smnCheck == true then
                modSkill = false
                modMagic = false
                modMessage = false
                modTrain = false
                log:info("" .. name .. " is a summoned creature. Free teleport!")
            end
        end
        ----Skill Requirement----------------------------------------------------------------------------------------------------------------------------------
        if modSkill == true then
            local skillFlag = 0
            ----Player Skill Check-----------------------------------------------------------------------------------------------------------------------------
            if config.playerSkill == true then
                local pMyst = tes3.mobilePlayer.mysticism.current
                log:debug("Checking " .. pMyst .. " vs " .. config.playerSkillReq .. "...")
                ----Player Skill Check Passed------------------------------------------------------------------------------------------------------------------
                if pMyst >= config.playerSkillReq then
                    skillFlag = 1
                    log:debug("Player's Mysticism skill check passed for " .. name .. ".")
                else
                    ----Player Skill Check Failed--------------------------------------------------------------------------------------------------------------
                    log:debug("Player's Mysticism skill check failed for " .. name .. ".")
                end
            end
            ----Companion Skill Check---------------------------------------------------------------------------------------------------------------------------
            if config.npcSkill == true then
                local npcMyst = companionRef.mobile:getSkillValue(14)
                if npcMyst == nil then
                    npcMyst = 0
                    log:warn("" .. name .."'s Mysticism skill returned nil. Changed to 0.")
                end
                ----Creature Check--------------------------------------------------------------------------------------------------------------------
                local creatCheck = companionRef.object.class
                if creatCheck == nil then
                    local typeCheck = companionRef.object.type
                    npcMyst = 0
                    log:info("" .. name .. " is a Creature. Will not count toward companion skill unless they are Daedra.")
                    ----Daedra Check------------------------------------------------------------------------------------------------------------------
                    if typeCheck == 1 then
                        npcMyst = config.npcSkillReq
                        log:info("" .. name .. " is a Daedra. Will teleport themselves.")
                    end
                end
                ----Companion Check Passed------------------------------------------------------------------------------------------------------------
                log:debug("Checking " .. npcMyst .. " vs " .. config.npcSkillReq .. "...")
                if npcMyst >= config.npcSkillReq then
                    skillFlag = 1
                    selectionRef = 1
                    log:debug("" .. name .. "'s Mysticism check passed.")
                else
                    ----Companion Check Failed--------------------------------------------------------------------------------------------------------
                    log:debug("" .. name .. "'s Mysticism check failed.")
                end
            end
            ----Skill Check PASSED-------------------------------------------------------------------------------------------------------------------------------
            if skillFlag == 1 then
                ----Magicka Check--------------------------------------------------------------------------------------------------------------------------------
                if modMagic == true then
                    local currentMgk = mgkChoice[selectionRef].mobile.magicka.current
                    local currentMyst = mgkChoice[selectionRef].mobile:getSkillValue(14)
                    if currentMyst == nil then
                        currentMyst = 1
                        log:warn("" .. mgkChoice[selectionRef].object.name .."'s Mysticism skill returned nil. Changed to 1.")
                    end
                    ----Mysticism Cost Reduction-----------------------------------------------------------------------------------------------------------------
                    local mystMod = (currentMyst / 200)
                    local cost = (config.magickaMod * (1 - mystMod))
                    local costRound = math.round(cost)
                    if costRound < 1 then
                        costRound = 1
                        log:warn("" .. mgkChoice[selectionRef].object.name .. "'s Magicka cost below 1. Changed to 1.")
                    end
                    ----Low Magicka------------------------------------------------------------------------------------------------------------------------------
                    if currentMgk < costRound then
                        mgkFlag = 0
                        log:info("" .. mgkChoice[selectionRef].object.name .." has low magicka.")
                        ----Player Covers for low Companion Magicka if Skill req is met--------------------------------------------------------------------------
                        local mgkSave = tes3.player.mobile.magicka.current
                        local mystSave = tes3.player.mobile.mysticism.current
                        local saved = 0
                        if config.playerSkill == true then
                            if mystSave >= config.playerSkillReq then
                                if mgkSave >= costRound then
                                    mgkFlag = 1
                                    selectionRef = 0
                                    saved = 1
                                    log:info("" .. mgkChoice[selectionRef].object.name .." had low magicka. Player will cover cost.")
                                end
                            end
                        end
                        ----Scroll Check-------------------------------------------------------------------------------------------------------------------------
                        if config.useScroll == true then
                            if saved == 0 then
                                local removedCount = tes3.removeItem({ reference = tes3.mobilePlayer, item = scrollType[teleType] })
                                if removedCount == 1 then
                                    tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                                    if config.playEffect == true then
                                        tes3.createVisualEffect({ object = "VFX_MysticismArea", lifespan = 2, verticalOffset = 70, scale = 4, reference = companionRef })
                                    end
                                    if modMessage == true then
                                        tes3.messageBox("" .. portSummary[selectionRef] .. " Low magicka. Scroll used.")
                                    end
                                    log:info("" .. name .. " teleported. Skill check passed. Low magicka. Scroll used.")
                                    if config.playSound == true then
                                        tes3.playSound({ sound = "mysticism area", volume = 0.7, pitch = pitchMod3  })
                                    end
                                else
                                    if modMessage == true then
                                        tes3.messageBox("" .. name .. " was left behind. Low magicka. No scroll.")
                                    end
                                    log:info("" .. name .. " was left behind. Skill check passed. Low magicka. No scroll.")
                                end
                            end
                        else
                            if saved == 0 then
                                if modMessage == true then
                                    tes3.messageBox("" .. name .. " was left behind. Low magicka.")
                                end
                                log:info("" .. name .. " was left behind. Skill check passed. Low magicka.")
                            end
                        end
                    end
                    ----Enough Magicka-------------------------------------------------------------------------------------------------------------------------------
                    if mgkFlag == 1 then
                        local currentMgk2 = mgkChoice[selectionRef].mobile.magicka.current
                        if selectionRef == 0 then
                            if modTrain == true then
                                tes3.player.mobile:exerciseSkill(14, 1)
                                log:info("Player Mysticism skill exercised when transporting " .. name .. ".")
                            end
                        end
                        tes3.setStatistic({ name = "magicka", current = (currentMgk2 - costRound), reference = mgkChoice[selectionRef] })
                        tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                        if config.playEffect == true then
                            if selectionRef == 0 then
                                tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 3, reference = companionRef })
                            end
                            if selectionRef == 1 then
                                tes3.createVisualEffect({ object = "VFX_MysticismCast", lifespan = 2, verticalOffset = 0, scale = 0.6, reference = companionRef })
                            end
                        end
                        if modMessage == true then
                            tes3.messageBox("" .. portSummary[selectionRef] .. " " .. costRound .. " magicka spent.")
                        end
                        log:info("" .. name .. " teleported. " .. costRound .. " Magicka spent. Skill check passed. Player Mysticism: " .. tes3.mobilePlayer.mysticism.current .. ", Companion Mysticism: " .. companionRef.mobile:getSkillValue(14) .. "")
                        if config.playSound == true then
                            if selectionRef == 0 then
                                tes3.playSound({ sound = "mysticism hit", volume = 0.7, pitch = pitchMod3  })
                            end
                            if selectionRef == 1 then
                                tes3.playSound({ sound = "mysticism cast", volume = 0.7, pitch = pitchMod3  })
                            end
                        end
                    end
                else
                    ----No Magicka Check, Skill Check Passed----------------------------------------------------------------------------------------------------------
                    tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                    if config.playEffect == true then
                        if selectionRef == 0 then
                            tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 3, reference = companionRef })
                        end
                        if selectionRef == 1 then
                            tes3.createVisualEffect({ object = "VFX_MysticismCast", lifespan = 2, verticalOffset = 0, scale = 0.6, reference = companionRef })
                        end
                    end
                    if selectionRef == 0 then
                        if modTrain == true then
                            tes3.player.mobile:exerciseSkill(14, 1)
                            log:info("Player Mysticism skill exercised when transporting " .. name .. ".")
                        end
                    end
                    if modMessage == true then
                        tes3.messageBox("" .. portSummary[selectionRef] .. "")
                    end
                    log:info("" .. name .. " teleported. No magicka check. Skill check passed. Player Mysticism: " .. tes3.mobilePlayer.mysticism.current .. ", Companion Mysticism: " .. companionRef.mobile:getSkillValue(14) .. "")
                    if config.playSound == true then
                        if selectionRef == 0 then
                            tes3.playSound({ sound = "mysticism hit", volume = 0.7, pitch = pitchMod3  })
                        end
                        if selectionRef == 1 then
                            tes3.playSound({ sound = "mysticism cast", volume = 0.7, pitch = pitchMod3  })
                        end
                    end
                end
            end
            ----Skill Check FAILED-------------------------------------------------------------------------------------------------------------------------------------
            if skillFlag == 0 then
                ----Scroll Check---------------------------------------------------------------------------------------------------------------------------------------
                if config.useScroll == true then
                    local removedCount = tes3.removeItem({ reference = tes3.mobilePlayer, item = scrollType[teleType] })
                    if removedCount == 1 then
                        tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                        if config.playEffect == true then
                            tes3.createVisualEffect({ object = "VFX_MysticismArea", lifespan = 2, verticalOffset = 70, scale = 4, reference = companionRef })
                        end
                        if modMessage == true then
                            tes3.messageBox("" .. portSummary[selectionRef] .. " Scroll used.")
                        end
                        log:info("" .. name .. " teleported. Skill check failed. Scroll used.")
                        if config.playSound == true then
                            tes3.playSound({ sound = "mysticism area", volume = 0.7, pitch = pitchMod3  })
                        end
                    else
                        if modMessage == true then
                            tes3.messageBox("" .. name .. " was left behind. No scroll.")
                        end
                        log:info("" .. name .. " was left behind. Skill check failed. No scroll.")
                    end
                else
                    if modMessage == true then
                        tes3.messageBox("" .. name .. " was left behind.")
                    end
                    log:info("" .. name .. " was left behind. Skill check failed. Player Mysticism: " .. tes3.mobilePlayer.mysticism.current .. ", Companion Mysticism: " .. companionRef.mobile:getSkillValue(14) .. "")
                end
            end
        else
            ----No Skill Check Required-------------------------------------------------------------------------------------------------------------------------------
            ----Magicka Check-----------------------------------------------------------------------------------------------------------------------------------------
            if modMagic == true then
                local currentMgk = mgkChoice[selectionRef].mobile.magicka.current
                local currentMyst = mgkChoice[selectionRef].mobile:getSkillValue(14)
                if currentMyst == nil then
                    currentMyst = 1
                end
                local mystMod = (currentMyst / 200)
                local cost = (config.magickaMod * (1 - mystMod))
                local costRound = math.round(cost)
                if costRound < 1 then
                    costRound = 1
                end
                ----Low Magicka---------------------------------------------------------------------------------------------------------------------------------------
                if currentMgk < costRound then
                    mgkFlag = 0
                    ----Scroll Check----------------------------------------------------------------------------------------------------------------------------------
                    if config.useScroll == true then
                        local removedCount = tes3.removeItem({ reference = tes3.mobilePlayer, item = scrollType[teleType] })
                        if removedCount == 1 then
                            tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                            if config.playEffect == true then
                                tes3.createVisualEffect({ object = "VFX_MysticismArea", lifespan = 2, verticalOffset = 70, scale = 4, reference = companionRef })
                            end
                            if modMessage == true then
                                tes3.messageBox("" .. portSummary[selectionRef] .. " Low magicka. Scroll used.")
                            end
                            log:info("" .. name .. " teleported. Mysticism skill not required. Low magicka. Scroll used.")
                            if config.playSound == true then
                                tes3.playSound({ sound = "mysticism area", volume = 0.7, pitch = pitchMod3  })
                            end
                        else
                            if modMessage == true then
                                tes3.messageBox("" .. name .. " was left behind. Low magicka. No scroll.")
                            end
                            log:info("" .. name .. " was left behind. Mysticism skill not required. Low magicka. No scroll.")
                        end
                    else
                        if modMessage == true then
                            tes3.messageBox("" .. name .. " was left behind. Low magicka.")
                        end
                        log:info("" .. name .. " was left behind. Mysticism skill not required. Low magicka.")
                    end
                end
                ----Enough Magicka------------------------------------------------------------------------------------------------------------------------------------
                if mgkFlag == 1 then
                    tes3.setStatistic({ name = "magicka", current = (currentMgk - costRound), reference = mgkChoice[selectionRef] })
                    tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                    if config.playEffect == true then
                        if selectionRef == 0 then
                            tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 3, reference = companionRef })
                        end
                        if selectionRef == 1 then
                            tes3.createVisualEffect({ object = "VFX_MysticismCast", lifespan = 2, verticalOffset = 0, scale = 0.6, reference = companionRef })
                        end
                    end
                    if selectionRef == 0 then
                        if modTrain == true then
                            tes3.player.mobile:exerciseSkill(14, 1)
                            log:info("Player Mysticism skill exercised when transporting " .. name .. ".")
                        end
                    end
                    if modMessage == true then
                        tes3.messageBox("" .. portSummary[selectionRef] .. " " .. costRound .. " magicka spent.")
                    end
                    log:info("" .. name .. " teleported. Mysticism skill not required. " .. costRound .. " magicka spent.")
                    if config.playSound == true then
                        if selectionRef == 0 then
                            tes3.playSound({ sound = "mysticism hit", volume = 0.7, pitch = pitchMod3  })
                        end
                        if selectionRef == 1 then
                            tes3.playSound({ sound = "mysticism cast", volume = 0.7, pitch = pitchMod3  })
                        end
                    end
                end
            else
                ----No Skill Check, no Magicka Check------------------------------------------------------------------------------------------------------------------
                tes3.positionCell({ reference = companionRef, cell = cellPosition, position = cameraPosition })
                if config.playEffect == true then
                    tes3.createVisualEffect({ object = "VFX_MysticismHit", lifespan = 3, reference = companionRef })
                end
                if selectionRef == 0 then
                    if modTrain == true then
                        tes3.player.mobile:exerciseSkill(14, 1)
                        log:info("Player Mysticism skill exercised when transporting " .. name .. ".")
                    end
                end
                if modMessage == true then
                    tes3.messageBox("" .. portSummary[selectionRef] .. "")
                end
                log:info("" .. name .. " teleported. Mysticism skill not required. No magicka spent.")
                if config.playSound == true then
                    tes3.playSound({ sound = "mysticism hit", volume = 0.7, pitch = pitchMod3  })
                end
            end
        end
	end
    table.clear(companionTable)
end



----Bridges-----------------------------------------------------------------------------------------------------------
local function companionTeleportBS(e)
	companionTeleport(companionTable)
end


local function companionCheckT(e)
    for mobileActor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if (validCompanionCheck(mobileActor)) then
            companionTable[#companionTable +1] = mobileActor.reference
            log:debug("" .. mobileActor.reference.object.name .. " added to teleport list.")
        end
		timer.start({ duration = 1, callback = companionTeleportBS })
	end
end


local function companionCheckTBridge(e)
	if e.caster ~= tes3.player then return end
	local source = e.source
    local effect = source.effects
    if effect[1].id == 63 then
        portFlag = 1
        teleType = 0
    end
    if effect[1].id == 62 then
        portFlag = 1
        teleType = 1
    end
    if effect[1].id == 61 then
        portFlag = 1
        teleType = 2
    end
    if config.mExpanded == true then
        if (effect[1].id == 241 or effect[1].id == 242 or effect[1].id == 243 or effect[1].id == 244 or effect[1].id == 245 or effect[1].id == 246 or effect[1].id == 247 or effect[1].id == 248 or effect[1].id == 249 or effect[1].id == 250 or effect[1].id == 251 or effect[1].id == 310) then
            portFlag = 1
            teleType = 2
        end
    end
	if config.modEnabled == true then
		if portFlag ~= 1 then return end
        log:debug("Effect " .. effect[1].id .. " detected. (63 = Almsivi, 62 = Divine, 61 or 241-242/310 = Recall) Initializing companion check.")
		companionCheckT(e)
	end
    portFlag = 0
end
event.register(tes3.event.magicCasted, companionCheckTBridge)


----PF----------------
--1.1 added support for magicka expanded teleportation effects, updated debug, updated MCM. magicka expanded teleportation already transports companions but with this turned on they will consume magicka/scrolls as well




--Config Stuff------------------------------------------------------------------------------------------------------------------------------
event.register("modConfigReady", function()
    require("friendlyIntervention.mcm")
	config = require("friendlyIntervention.config")
end)