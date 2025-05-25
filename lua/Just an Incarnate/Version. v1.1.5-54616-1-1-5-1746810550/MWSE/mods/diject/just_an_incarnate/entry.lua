local log = include("diject.just_an_incarnate.utils.log")
local config = include("diject.just_an_incarnate.config")
local playerLib = include("diject.just_an_incarnate.player")
local localStorage = include("diject.just_an_incarnate.storage.localStorage")
local logger = include("diject.just_an_incarnate.storage.playerDataLogger")
local npc = include("diject.just_an_incarnate.libs.npc")
local customClassLib = include("diject.just_an_incarnate.libs.customClass")
local advTable = include("diject.just_an_incarnate.utils.table")
local cellLib = include("diject.just_an_incarnate.libs.cell")
local dataStorage = include("diject.just_an_incarnate.storage.dataStorage")
local mapSpawner = include("diject.just_an_incarnate.mapSpawner")

local ashfall = include("mer.ashfall.interop")


local onDamagePriority = 1749
local onDamageLowPriority = -1749
local disableSavePriority = 1749
local calcRestInterruptPriority = -1749

local isDead = false

--- @param e loadedEventData
local function loadedCallback(e)
    isDead = false
    localStorage.initPlayerStorage()
    config.initLocalData()
    playerLib.reset()

    if config.getValueByPath("spawn.addSummonSpell") then
        playerLib.addSummonSpell()
    else
        playerLib.removeSummonSpell()
    end

    local statMenu = tes3ui.findMenu("MenuStat")
    if statMenu and config.localConfig.count > 0 then
        local nameZone = statMenu:findChild("PartDragMenu_title")
        nameZone.text = tes3.player.object.name.." The "..tostring(config.localConfig.count + 1).."th"
        statMenu:getTopLevelMenu():updateLayout()
    end

    if e.newGame then return end
    if customClassLib.isGameCustomClass() then
        customClassLib.saveClassData(tes3.player.object.class)
    end
end
event.register(tes3.event.loaded, loadedCallback)

--- @param e loadEventData
local function loadCallback(e)
    config.resetLocalToDefault()
    localStorage.reset()
    local class = customClassLib.getCustomClassRecord()
    if not class then return end
    class.modified = false
end
event.register(tes3.event.load, loadCallback, {priority = -9999})

--- @param e saveEventData
local function saveCallback(e)
    config.updateVersionInPlayerStorage()
    local class = customClassLib.getCustomClassRecord()
    if not class then return end
    class.modified = true
end
event.register(tes3.event.save, saveCallback)

--- @param e saveEventData
local function disableSaveCallback(e)
    tes3.messageBox("You are not allowed to save now")
    e.block = true
    e.claim = true
end

--- @param e saveEventData
local function disableLoadCallback(e)
    tes3.messageBox("You are not allowed to load now")
    e.block = true
    e.claim = true
end

local function disableSaves()
    event.register(tes3.event.save, disableSaveCallback, { priority = disableSavePriority })
    event.register(tes3.event.load, disableLoadCallback, { priority = disableSavePriority })
end

local function enableSaves()
    event.unregister(tes3.event.save, disableSaveCallback, { priority = disableSavePriority })
    event.unregister(tes3.event.load, disableLoadCallback, { priority = disableSavePriority })
end

---@param e damageEventData
local function preventDamageCallback(e)
    if not isDead then
        event.unregister(tes3.event.damage, preventDamageCallback, { priority = onDamagePriority })
        return
    end

    e.block = true
    e.damage = 0
    return false
end

local function disableDamageToPlayer()
    event.register(tes3.event.damage, preventDamageCallback, { priority = onDamagePriority })
end

local function enableDamageToPlayer()
    event.unregister(tes3.event.damage, preventDamageCallback, { priority = onDamagePriority })
end



local function processDead()

    if config.data.misc.sendDeathEvent then
        local currentHealth = tes3.mobilePlayer.health.current
        tes3.mobilePlayer.health.current = 0
        event.trigger(tes3.event.death, {reference = tes3.player, mobile = tes3.mobilePlayer})
        event.trigger(tes3.event.damaged, {reference = tes3.player, mobile = tes3.mobilePlayer, damage = 0, killingBlow = true, source = tes3.damageSource.script})
        tes3.mobilePlayer.health.current = currentHealth
    end

    local isWerewolf = tes3.mobilePlayer.werewolf
    if isWerewolf then
        tes3.runLegacyScript{command = "set PCWerewolf to 0", reference = tes3.player} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = "UndoWerewolf", reference = tes3.player} ---@diagnostic disable-line: missing-fields
    end

    dataStorage.savePlayerDeathInfo(config.localConfig.id)
    if not config.data.misc.sendDeathEvent then
        event.trigger("rotf_register_death")
    end

    if config.data.misc.bounty.reset then
        tes3.mobilePlayer.bounty = 0
        if config.data.misc.bounty.removeStolen then
            tes3.runLegacyScript{command = "PayFine"} ---@diagnostic disable-line: missing-fields
        else
            tes3.runLegacyScript{command = "PayFineThief"} ---@diagnostic disable-line: missing-fields
        end
    end

    if config.data.misc.resetActorsToDefault then
        for _, cell in pairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
                local mobile = ref.mobile
                if mobile and mobile.health.current > 0 and mobile ~= tes3.mobilePlayer then
                    local baseObject = mobile.object.baseObject
                    if not baseObject.id:find("jai_dpl_") and not baseObject.id:find("rotf_dpl_") then
                        mobile.fight = baseObject.aiConfig.fight
                    end
                    if mobile.object.baseDisposition then
                        mobile.object.baseDisposition = baseObject.baseDisposition
                    end
                    mobile:stopCombat(true)
                    tes3.modStatistic{reference = mobile, name = "health", current = 99999, limitToBase = true,}
                    tes3.modStatistic{reference = mobile, name = "magicka", current = 99999, limitToBase = true,}
                    tes3.modStatistic{reference = mobile, name = "fatigue", current = 99999, limitToBase = true,}
                end
            end
        end
    end

    playerLib.createDuplicate()

    if not tes3.worldController.flagTeleportingDisabled then
        local markers = {}
        local shouldTeleportAnyway = false

        local configTable = tes3.player.cell.isOrBehavesAsExterior and config.data.revive.exterior or config.data.revive.interior

        if configTable.divineMarker then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("DivineMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.templeMarker then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("TempleMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.prisonMarker then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("PrisonMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.exteriorDoorMarker then
            local marker = cellLib.getRandomExteriorDoorMarker()
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.interiorDoorMarker and tes3.player.cell.isInterior then
            local marker = cellLib.getRandomDoorMarker(tes3.player.cell)
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.recall and tes3.mobilePlayer.markLocation then
            table.insert(markers, {position = tes3.mobilePlayer.markLocation.position, cell = tes3.mobilePlayer.markLocation.cell,
                orientation = tes3vector3.new(0, 0, tes3.mobilePlayer.markLocation.rotation)})
        end
        if configTable.exitFromInterior and tes3.player.cell.isInterior then
            local marker = cellLib.getExitExteriorMarker(tes3.player.cell)
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.lastRest.enabled then
            local dataArr = {}
            if localStorage.data["lastRest"] then
                table.insert(dataArr, localStorage.data["lastRest"])
            end
            if configTable.lastRest.includeWait and localStorage.data["lastWait"] then
                table.insert(dataArr, localStorage.data["lastWait"])
            end
            if #dataArr > 1 then
                table.sort(dataArr, function (a, b) return a.time > b.time end)
            end
            if #dataArr > 0 then
                local markerData = dataArr[1]
                if markerData then
                    local position = tes3vector3.new(markerData.position.x, markerData.position.y, markerData.position.z)
                    local orientation = tes3vector3.new(markerData.orientation.x, markerData.orientation.y, markerData.orientation.z)
                    local cell = tes3.getCell(markerData.cell)
                    if cell then
                        table.insert(markers, {position = position, orientation = orientation, cell = cell})
                    end
                end
            end
            shouldTeleportAnyway = true
        end

        if shouldTeleportAnyway and #markers == 0 then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("PrisonMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end

        if #markers > 0 then
            local posData = markers[math.random(#markers)]

            tes3.positionCell{position = posData.position, orientation = posData.orientation, cell = posData.cell, forceCellChange = true}
            tes3.fadeOut{duration = 0.0001}
        end
    end

    if config.data.revive.removeEffects then
        tes3.cast{ reference = tes3.player, target = tes3.player, spell = "jai_dispel", instant = true, alwaysSucceeds = true, bypassResistances = true }
    end
    if config.data.revive.removeDiseases then
        tes3.removeEffects{reference = tes3.player, castType = tes3.spellType.disease, removeSpell = false}
        tes3.removeEffects{reference = tes3.player, castType = tes3.spellType.blight, removeSpell = false}
    end
    playerLib.addRestoreSpells(math.max(1, config.data.revive.safeTime))

    local ashfallConfig = config.data.misc.ashfall
    if ashfall and ashfallConfig.changeBy ~= 0 then
        local hunger = ashfall.getHunger()
        local thirst = ashfall.getThirst()
        local tiredness = ashfall.getTiredness()
        local temp = ashfall.getTemp()

        local changeBy = ashfallConfig.changeBy
        if ashfallConfig.randomize then
            ashfall.setHunger(math.clamp(hunger + 2 * changeBy * math.random() - changeBy, 0, ashfallConfig.limit))
            ashfall.setThirst(math.clamp(thirst + 2 * changeBy * math.random() - changeBy, 0, ashfallConfig.limit))
            ashfall.setTiredness(math.clamp(tiredness + 2 * changeBy * math.random() - changeBy, 0, ashfallConfig.limit))
            ashfall.setTemp(math.clamp(temp + 2 * changeBy * math.random() - changeBy, -ashfallConfig.limit, ashfallConfig.limit))
        else
            ashfall.setHunger(math.clamp(hunger + changeBy, 0, ashfallConfig.limit))
            ashfall.setThirst(math.clamp(thirst + changeBy, 0, ashfallConfig.limit))
            ashfall.setTiredness(math.clamp(tiredness + changeBy, 0, ashfallConfig.limit))
            ashfall.setTemp(math.clamp(temp > 0 and temp + changeBy or temp - changeBy, -ashfallConfig.limit, ashfallConfig.limit))
        end
    end

    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "health",
        current = 999999,
        limitToBase = true,
    })

    config.localConfig.count = config.localConfig.count + 1 ---@diagnostic disable-line: inject-field

    local statDecreaseMessage = ""
    local decreasedStats = {attributes = {}, skills = {}}
    local decreaseExecuted = false
    if config.data.decrease.level.count > 0 and config.localConfig.count % config.data.decrease.level.interval == 0 then
        local data = playerLib.levelDown(config.data.decrease.level.count)
        if data.level ~= 0 then
            statDecreaseMessage = statDecreaseMessage.."\nYour level has been "..(data.level < 0 and "decreased" or "increased").." by "..tostring(math.abs(data.level)).."."
        end
        if data.health ~= 0 then
            statDecreaseMessage = statDecreaseMessage.."\nYour health has been "..(data.health < 0 and "decreased" or "increased").." by "..tostring(math.abs(data.health)).."."
        end
        for attrId, val in pairs(data.attributes) do
            if val ~= 0 then
                decreasedStats.attributes[attrId] = (decreasedStats.attributes[attrId] or 0) + val
            end
        end
        for skillId, val in pairs(data.skills) do
            if val ~= 0 then
                decreasedStats.skills[skillId] = (decreasedStats.skills[skillId] or 0) + val
            end
        end
        decreaseExecuted = true
    end
    if config.data.decrease.skill.count > 0 and config.localConfig.count % config.data.decrease.skill.interval == 0 and
            (config.data.decrease.combine or not decreaseExecuted) then
        local data = playerLib.skillDown(config.data.decrease.skill.count)
        for skillId, val in pairs(data) do
            if val ~= 0 then
                decreasedStats.skills[skillId] = (decreasedStats.skills[skillId] or 0) + val
            end
        end
        decreaseExecuted = true
    end
    local forgettedSpellsStr = ""
    if config.data.decrease.spell.count > 0 and config.localConfig.count % config.data.decrease.spell.interval == 0 and
            (config.data.decrease.combine or not decreaseExecuted) then
        local data = playerLib.removeSpells(config.data.decrease.spell.count, config.data.decrease.spell.random)
        for _, spellId in pairs(data) do
            local spell = tes3.getObject(spellId)
            if spell then
                if forgettedSpellsStr ~= "" then
                    forgettedSpellsStr = forgettedSpellsStr..", "
                end
                forgettedSpellsStr = forgettedSpellsStr.."\""..spell.name.."\""
            end
        end
        decreaseExecuted = true
    end
    for attrId, val in pairs(decreasedStats.attributes) do
        statDecreaseMessage = statDecreaseMessage.."\nYour "..tes3.attributeName[attrId].." has been "..(val < 0 and "decreased" or "increased").." by "..tostring(math.abs(val)).."."
    end
    for skillId, val in pairs(decreasedStats.skills) do
        statDecreaseMessage = statDecreaseMessage.."\nYour "..tes3.skillName[skillId].." has been "..(val < 0 and "decreased" or "increased").." by "..tostring(math.abs(val)).."."
    end
    if forgettedSpellsStr ~= "" then
        statDecreaseMessage = statDecreaseMessage.."\nYou forgot "..forgettedSpellsStr.."."
    end

    if config.data.misc.rechargePower then
        for _, spell in pairs(tes3.player.object.spells) do
            if spell.castType == tes3.spellType.power then
                tes3.mobilePlayer:rechargePower(spell)
            end
        end
    end

    playerLib.reevaluateMissedPlayerEquipment()
    if config.data.spawn.transfer.replace.enabled then
        local level = tes3.player.object.level
        timer.delayOneFrame(function()
            playerLib.giveEquipmentFromRandomNPC(config.data.spawn.transfer.replace.regionSize / 100, level)
        end)
    else
        timer.delayOneFrame(function()
            playerLib.giveDefaultEquipment()
        end)
    end

    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "health",
        current = 999999,
        limitToBase = true,
    })
    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "magicka",
        current = 999999,
        limitToBase = true,
    })
    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "fatigue",
        current = 999999,
        limitToBase = true,
    })

    local statMenu = tes3ui.findMenu("MenuStat")
    if statMenu then
        event.trigger(tes3.event.uiActivated, {element = statMenu, newlyCreated = false}, {filter = "MenuStat"})
        statMenu:updateLayout()
    end

    playerLib.changePlayer()

    timer.start{duration = 2, callback = function()
        playerLib.menuMode = false
        if isWerewolf then
            tes3.runLegacyScript{command = "set PCWerewolf to 1", reference = tes3.player} ---@diagnostic disable-line: missing-fields
        end
        timer.start{duration = config.data.revive.safeTime, callback = function()
            enableDamageToPlayer()
            isDead = false
        end}
        timer.delayOneFrame(function() tes3.fadeIn{duration = config.data.revive.delay} end)
        playerLib.addDynamicStatsRestoreSpells(math.max(1, config.data.revive.safeTime))
        tes3.setPlayerControlState{enabled = true,}
        tes3.mobilePlayer.paralyze = 0
        tes3.cancelAnimationLoop{reference = tes3.player}
        enableSaves()
        if statDecreaseMessage ~= "" then
            tes3.messageBox{message = config.data.text.statDecreaseMessage.."\n"..statDecreaseMessage, duration = 20}
        end
        if config.data.misc.sendLoadedEvent then
            local lastLoadedFile = tes3.dataHandler.nonDynamicData.lastLoadedFile
            event.trigger(tes3.event.loaded, {
                filename = lastLoadedFile and lastLoadedFile.filename or nil,
                newGame = false,
                quickload = false
            })
        end
    end}
end

local function getDamageMul()
    local fDifficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value
    local difficultyTerm = tes3.worldController.difficulty
    local res = 0
    if difficultyTerm > 0 then
        res = 1 + fDifficultyMult * difficultyTerm
    else
        res = 1 + difficultyTerm / fDifficultyMult
    end
    return res
end

local function onDamage(e)
    if e.reference ~= tes3.player or not config.data.revive.enabled then
        return
    end

    local damageValue = math.abs(e.damage) * getDamageMul()
    if isDead then
        if e.damage < 0 then
            tes3.mobilePlayer.health.current = 2 + damageValue
        end
        e.damage = 0
        e.claim = true
        e.block = true
        return false
    end

    if tes3.mobilePlayer.health.current - math.abs(damageValue) <= 1 then
        e.damage = 0
        e.claim = true
        e.block = true
        if isDead then return false end
        isDead = true
        disableDamageToPlayer()
        log("triggered", "h",tes3.mobilePlayer.health.current)
        tes3.removeEffects{reference = tes3.player, castType = tes3.spellType.power, removeSpell = false}
        tes3.setPlayerControlState{enabled = false,}
        disableSaves()
        if config.data.text.death then
            tes3.messageBox{message = config.data.text.death, duration = 10}
        end
        tes3.setStatistic({
            reference = tes3.mobilePlayer,
            name = "health",
            current = 2,
            limitToBase = false,
        })
        if tes3.mobilePlayer.isSwimming then
            tes3.playAnimation{reference = tes3.player, group = tes3.animationGroup.swimKnockOut,}
            tes3.playAnimation{reference = tes3.player1stPerson, group = tes3.animationGroup.swimKnockOut,}
        else
            tes3.playAnimation{reference = tes3.player, group = tes3.animationGroup.knockOut,}
            tes3.playAnimation{reference = tes3.player1stPerson, group = tes3.animationGroup.knockOut,}
        end
        tes3.mobilePlayer.paralyze = 1
        tes3.fadeOut{duration = config.data.revive.delay}
        timer.start{duration = config.data.revive.delay, callback = processDead}
    end
    -- log("damage", e.damage, "value", damageValue, "health", tes3.mobilePlayer.health.current, "new health", tes3.mobilePlayer.health.current - damageValue)
end

event.register(tes3.event.damage, onDamage, {priority = config.data.misc.highPriority and onDamagePriority or onDamageLowPriority})

local randomizerConfig = include("Morrowind_World_Randomizer.storage")
if randomizerConfig and (not randomizerConfig.version or randomizerConfig.version <= 6) then

    local randomizer = include("Morrowind_World_Randomizer.Randomizer")
    --- @param e mobileActivatedEventData
    local function mobileActivatedCallback(e)
        if e.reference.baseObject.id:find(playerLib.npcTemplate) then
            randomizer.StopRandomization(e.reference)
        end
    end
    event.register(tes3.event.mobileActivated, mobileActivatedCallback, {priority = 10})
end

--- @param e mobileActivatedEventData
local function mobileActivatedCallback(e)
    if e.mobile.actorType == tes3.actorType.npc and e.mobile.chameleon > 0 then
        e.mobile:updateOpacity()
    end
end
event.register(tes3.event.mobileActivated, mobileActivatedCallback)

--- @param e spellCastedEventData
local function spellCastedCallback(e)
    if e.caster ~= tes3.player or e.source.id ~= playerLib.summonSpellId then
        return
    end
    local playerCell = tes3.player.cell
    local function checkCell(cell)
        local playerPos = tes3.player.position
        for _, ref in pairs(cell.actors) do
            if localStorage.isExists(ref) and localStorage.getStorage(ref).isPlayerCopy then
                local newPos = tes3vector3.new(playerPos.x + math.random(-50, 50), playerPos.y + math.random(-50, 50), playerPos.z)
                tes3.positionCell{reference = ref, position = newPos, orientation = tes3.player.orientation,
                    cell = tes3.player.cell, forceCellChange = true}
                tes3.createVisualEffect{object = "VFX_RestorationHit", repeatCount = 1, lifespan = 4, position = newPos}
                tes3.playSound{sound = "restoration hit", reference = ref, mixChannel = tes3.soundMix.effects}
            end
        end
    end
    if playerCell.isInterior then
        checkCell(playerCell)
    else
        for _, cellData in pairs(tes3.dataHandler.exteriorCells) do
            local cell = cellData.cell
            checkCell(cell)
        end
    end
end
event.register(tes3.event.spellCasted, spellCastedCallback)

--- @param e uiSpellTooltipEventData
local function uiSpellTooltipCallback(e)
    if e.spell.id == playerLib.summonSpellId then
        local container = e.tooltip:findChild("PartHelpMenu_main")
        if not container then return end
        local effects = container:findChild("effect")
        if not effects then return end
        effects:destroyChildren()
        effects:createLabel{text = config.data.text.summonSpellDescription}
    end
end
event.register(tes3.event.uiSpellTooltip, uiSpellTooltipCallback)

--- @param e deathEventData
local function deathCallback(e)
    if e.reference ~= tes3.player or not config.data.revive.enabled then
        return
    end
    dataStorage.savePlayerDeathInfo(config.localConfig.id)
end
event.register(tes3.event.death, deathCallback)

--- @param e enterFrameEventData
local function firstInit(e)
    if config.firstInit then
        include("diject.just_an_incarnate.quickInit").showMessage()
    end
    event.unregister(tes3.event.enterFrame, firstInit)
end
event.register(tes3.event.enterFrame, firstInit)

--- @param e calcRestInterruptEventData
local function calcRestInterruptCallback(e)
    local player = tes3.player
    local positionData = {
        time = os.time(),
        position = {x = player.position.x, y = player.position.y, z = player.position.z},
        orientation = {x = player.orientation.x, y = player.orientation.y, z = player.orientation.z},
        cell = {id = player.cell.isInterior and player.cell.id or nil, x = player.cell.gridX, y = player.cell.gridY}
    }
    if e.resting then
        localStorage.data["lastRest"] = positionData
    elseif e.waiting then
        localStorage.data["lastWait"] = positionData
    end
end
event.register(tes3.event.calcRestInterrupt, calcRestInterruptCallback, {priority = calcRestInterruptPriority})