local log = include("diject.just_an_incarnate.utils.log")
local advTable = include("diject.just_an_incarnate.utils.table")
local playerLogger = include("diject.just_an_incarnate.storage.playerDataLogger")
local customClassLib = include("diject.just_an_incarnate.libs.customClass")
local dataStorage = include("diject.just_an_incarnate.storage.dataStorage")
local npcLib = include("diject.just_an_incarnate.libs.npc")
local config = include("diject.just_an_incarnate.config")
local localStorage = include("diject.just_an_incarnate.storage.localStorage")
local bodypartChanger = require("diject.mwse_libs.bodypartChanger")
local tooltipChanger = require("diject.mwse_libs.tooltipChanger")

local this = {}

local priority = -9999

this.playerDefaultItems = {"common_pants_01", "common_shoes_01", "common_shirt_01"}
this.creatureTemplates = {"jai_skeleton_", "jai_ancestor_ghost_"}
this.npcTemplate = "jai_dpl_"
this.summonSpellId = "jai_summon_bodies"

this.menuMode = false
this.bodyPartsChanged = false

this.disallowedSpellIds = {}

---@enum classChoiceEnum
local classChoiceEnum = {
    ingame = 0,
    customPlayer = 1,
    customRandom = 2,
}

---@type classChoiceEnum
local classChoice = classChoiceEnum.ingame


---@param class tes3class
---@param mul number[-1, 1]
local function changePlayerStatsByClass(class, mul)
    for _, skill in pairs(tes3.dataHandler.nonDynamicData.skills) do
        if skill.specialization == class.specialization then
            tes3.modStatistic{reference = tes3.mobilePlayer, skill = tonumber(skill.id), value = 5 * mul}
        end
    end
    for _, skillId in pairs(class.majorSkills) do
        tes3.modStatistic{reference = tes3.mobilePlayer, skill = skillId, value = 25 * mul}
    end
    for _, skillId in pairs(class.minorSkills) do
        tes3.modStatistic{reference = tes3.mobilePlayer, skill = skillId, value = 10 * mul}
    end
    for _, attrId in pairs(class.attributes) do
        tes3.modStatistic{reference = tes3.mobilePlayer, attribute = attrId, value = 10 * mul}
    end
end

---@param class tes3class
---@param mul number[-1, 1]
local function applyPlayerStatsByClass(class, skillData, attrData, mul)
    for _, skill in pairs(tes3.dataHandler.nonDynamicData.skills) do
        if skill.specialization == class.specialization then
            local id = tonumber(skill.id) + 1
            skillData[id] = skillData[id] + 5 * mul
        end
    end
    for _, skillId in pairs(class.majorSkills) do
        local id = skillId + 1
        skillData[id] = skillData[id] + 25 * mul
    end
    for _, skillId in pairs(class.minorSkills) do
        local id = skillId + 1
        skillData[id] = skillData[id] + 10 * mul
    end
    for _, attrId in pairs(class.attributes) do
        local id = attrId + 1
        attrData[id] = attrData[id] + 10 * mul
    end
end

local attributeValues = {}
local skillValues = {}
local spells = {}
local function finishStatChanges()
    -- restore attribute values
    for i, value in pairs(attributeValues) do
        log(i, tes3.mobilePlayer.attributes[i].base, value)
        tes3.setStatistic{reference = tes3.player, attribute = i - 1, value = tes3.mobilePlayer.attributes[i].base + value}
    end
    log("attribute values:", skillValues)
    -- restore skill values
    for skillId, value in pairs(skillValues) do
        tes3.setStatistic{reference = tes3.player, skill = skillId - 1, value = tes3.mobilePlayer.skills[skillId].base + value}
    end
    log("skill values:", skillValues)
    -- restore spells
    for _, spell in pairs(spells) do
        tes3.addSpell{reference = tes3.player, spell = spell}
    end
    local additiveVal = tes3.mobilePlayer.willpower.base / 5 + tes3.mobilePlayer.luck.base / 10
    if tes3.mobilePlayer.destruction.base * 2 + additiveVal >= 56 then
        tes3.addSpell{reference = tes3.player, spell = "fire bite"}
    end
    if tes3.mobilePlayer.illusion.base * 2 + additiveVal >= 65 then
        tes3.addSpell{reference = tes3.player, spell = "chameleon"}
        tes3.addSpell{reference = tes3.player, spell = "sanctuary"}
    end
    if tes3.mobilePlayer.alteration.base * 2 + additiveVal >= 59 then
        tes3.addSpell{reference = tes3.player, spell = "water walking"}
        if tes3.mobilePlayer.alteration.base * 2 + additiveVal >= 65 then
            tes3.addSpell{reference = tes3.player, spell = "shield"}
        end
    end
    if tes3.mobilePlayer.conjuration.base * 2 + additiveVal >= 51 then
        tes3.addSpell{reference = tes3.player, spell = "bound dagger"}
        if tes3.mobilePlayer.conjuration.base * 2 + additiveVal >= 76 then
            tes3.addSpell{reference = tes3.player, spell = "summon ancestral ghost"}
        end
    end
    if tes3.mobilePlayer.mysticism.base * 2 + additiveVal >= 69 then
        tes3.addSpell{reference = tes3.player, spell = "detect_creature"}
    end
    if tes3.mobilePlayer.restoration.base * 2 + additiveVal >= 63 then
        tes3.addSpell{reference = tes3.player, spell = "hearth heal"}
    end
    if config.data.misc.rechargePower then
        for _, spell in pairs(tes3.player.object.race.abilities) do
            if spell.castType == tes3.spellType.power then
                tes3.mobilePlayer:rechargePower(spell)
            end
        end
        for _, spell in pairs(tes3.mobilePlayer.birthsign.spells) do
            if spell.castType == tes3.spellType.power then
                tes3.mobilePlayer:rechargePower(spell)
            end
        end
        for _, spell in pairs(tes3.player.object.spells) do
            if spell.castType == tes3.spellType.power and spell.id ~= this.summonSpellId then
                tes3.mobilePlayer:rechargePower(spell)
            end
        end
    end
    tes3.mobilePlayer:setPowerUseTimestamp(tes3.getObject(this.summonSpellId), tes3.getSimulationTimestamp())

    -- destroy the menus that shows after character recreation
    local menuStat = tes3ui.findMenu("MenuStat")
    if menuStat then menuStat:destroy() end
    local menuMagic = tes3ui.findMenu("MenuMagic")
    if menuMagic then menuMagic:destroy() end

    tes3.player:updateEquipment()
    tes3.player1stPerson:updateEquipment()
    -- tes3.player:updateSceneGraph()
    tes3.mobilePlayer:updateDerivedStatistics()
    tes3.updateMagicGUI{ reference = tes3.player, updateSpells = true, updateEnchantments = true}
    tes3ui.updateInventoryCharacterImage()
    tes3ui.updateContentsMenuTiles()
end

function this.changePlayer()
    this.menuMode = true
    local level = tes3.player.object.level
    -- race
    local oldRace = tes3.player.baseObject.race
    local oldGender = tes3.player.baseObject.female
    local races = {}
    for r, race in pairs(tes3.dataHandler.nonDynamicData.races) do
        if race.isPlayable then
            table.insert(races, race)
        end
    end
    if config.data.change.sex then
        tes3.player.baseObject.female = math.random() > 0.5 and true or false
        tes3.player1stPerson.baseObject.female = tes3.player.baseObject.female
        this.bodyPartsChanged = true
    end
    ---@type tes3race
    local newRace = oldRace
    if config.data.change.race then
        newRace = races[math.random(#races)] or oldRace
        tes3.player.baseObject.race = newRace
        tes3.player1stPerson.baseObject.race = newRace
        this.bodyPartsChanged = true
    end

    -- animations for new race/sex
    timer.delayOneFrame(function()
        if newRace.isBeast then
            tes3.playAnimation({
                reference = tes3.player,
                mesh = "base_animKnA.nif",
            })
            tes3.playAnimation({
                reference = tes3.player1stPerson,
                mesh = "base_animkna.1st.nif",
            })
        else
            if tes3.player.baseObject.female then
                tes3.playAnimation({
                    reference = tes3.player,
                    mesh = "base_anim_female.nif",
                })
            else
                tes3.playAnimation({
                    reference = tes3.player,
                    mesh = "base_anim.nif",
                })
            end
            tes3.playAnimation({
                reference = tes3.player1stPerson,
                mesh = "base_anim.1st.nif",
            })
        end
    end)

    -- hair & head
    timer.delayOneFrame(function()
        if config.data.change.race or config.data.change.bodyParts then
            local heads = {}
            local hairs = {}
            local playerObject = tes3.player.baseObject
            for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
                if object ~= nil and object.objectType == tes3.objectType.bodyPart and not object.deleted and
                        object.partType == tes3.activeBodyPartLayer.base and object.part <= 1 and
                        object.raceName == playerObject.race.name and object.playable and playerObject.female == object.female and
                        object.mesh and tes3.getFileSource("Meshes\\"..object.mesh) then

                    if object.part == tes3.partIndex.head then
                        table.insert(heads, object)
                    elseif object.part == tes3.partIndex.hair then
                        table.insert(hairs, object)
                    end
                end
            end
            local hair = #hairs > 0 and hairs[math.random(#hairs)] or nil
            local head
            if tes3.getGlobal("PCVampire") > 0 then
                head = playerObject.female and newRace.femaleBody.vampireHead or newRace.maleBody.vampireHead
            else
                head = #heads > 0 and heads[math.random(#heads)] or nil
            end
            if hair then
                tes3.player.baseObject.hair = hair
            end

            if head then
                tes3.player.baseObject.head = head
            end
        end
    end)
    -- attributes
    attributeValues = {}
    for i, attr in ipairs(tes3.mobilePlayer.attributes) do
        -- attributeValues[i] = attr.base
        attributeValues[i] = 0
    end
    for i, attrs in ipairs(oldRace.baseAttributes) do
        local attr = oldGender and attrs.female or attrs.male
        attributeValues[i] = attributeValues[i] - attr
    end
    for i, attrs in ipairs(newRace.baseAttributes) do
        local attr = tes3.player.baseObject.female and attrs.female or attrs.male
        attributeValues[i] = attributeValues[i] + attr
    end
    -- skills
    skillValues = {}
    for i, skill in ipairs(tes3.mobilePlayer.skills) do
        -- table.insert(skillValues, skill.base)
        table.insert(skillValues, 0)
    end
    for i, skillData in ipairs(oldRace.skillBonuses) do
        if skillData.skill ~= -1 then
            skillValues[skillData.skill + 1] = skillValues[skillData.skill + 1] - skillData.bonus
        end
    end
    for i, skillData in ipairs(newRace.skillBonuses) do
        if skillData.skill ~= -1 then
            skillValues[skillData.skill + 1] = skillValues[skillData.skill + 1] + skillData.bonus
        end
    end

    spells = {}
    for _, spell in pairs(tes3.player.object.spells) do
        if not this.disallowedSpellIds[spell.id:lower()] then
            table.insert(spells, spell)
        end
    end

    if config.data.change.class.enbled or config.data.change.sign then
        -- birthsign
        tes3.runLegacyScript{command = "EnableBirthMenu"} ---@diagnostic disable-line: missing-fields

        -- class
        if config.data.change.class.enbled then
            applyPlayerStatsByClass(tes3.player.object.class, skillValues, attributeValues, -1)
            log("old class:", tes3.player.object.class)
            local rnd = math.random() * 100
            if rnd < config.data.change.class.chanceToPlayerCustom and customClassLib.storageSize() > 0 then
                classChoice = classChoiceEnum.customPlayer
                customClassLib.loadRandomCustomClass()
            elseif rnd < config.data.change.class.chanceToCustom + config.data.change.class.chanceToPlayerCustom then
                classChoice = classChoiceEnum.customRandom
                customClassLib.createAndLoadCustomClass()
            else
                classChoice = classChoiceEnum.ingame
            end
        elseif customClassLib.isGameCustomClass() then
            local customClass = tes3.findClass("NEWCLASSID_CHARGEN")
            if customClass then
                customClassLib.deserializeClass(customClassLib.getCustomClassRecord(), customClass)
            end
        end

        tes3.runLegacyScript{command = "EnableClassMenu"} ---@diagnostic disable-line: missing-fields

    else
        finishStatChanges()
    end

    if level ~= tes3.player.object.level then
        timer.delayOneFrame(function()
            tes3.runLegacyScript{command = "setlevel "..tostring(level), reference = tes3.player} ---@diagnostic disable-line: missing-fields
        end)
    end
    timer.start{duration = 0.1, type = timer.real, iterations = -1, callback = function(e)
        if this.menuMode then
            tes3ui.leaveMenuMode()
        else
            tes3.player:updateEquipment()
            tes3.player1stPerson:updateEquipment()
            e.timer:cancel()
        end
    end}
end

local function getRandomElement(list)
	return list:getContentElement().children[math.random(#list:getContentElement().children)]
end

local function getElementForCustomClass(list)
    for n, v in pairs(list:getContentElement().children) do
        if v and tostring(v.text) == customClassLib.getCustomClassRecord().name then return v end
    end
	return list:getContentElement().children[math.random(#list:getContentElement().children)]
end

local function selectElement(list, element)
	local index
    local pos = 1
	local height = 0
	for _, children in ipairs(list:getContentElement().children) do
		if children == element then index = pos end
		height = height + children.height
		pos = pos + 1
	end
	if index then
		list.widget.positionY = ((height / #list:getContentElement().children) * index) - element.height
	end
end

--- @param e uiActivatedEventData
local function menuBirthSignCallback(e)
    if not this.menuMode then return end
    if config.data.change.sign then
        local birthsignScrollUIID = tes3ui.registerID("MenuBirthSign_BirthSignScroll")
        local pick = getRandomElement(e.element:findChild(birthsignScrollUIID))
        selectElement(e.element:findChild(birthsignScrollUIID), pick)
        pick:triggerEvent(tes3.uiEvent.mouseClick)
    end
    local elem = e.element:findChild("MenuBirthSign_Okbutton")
    elem:triggerEvent(tes3.uiEvent.mouseClick)
end
event.register(tes3.event.uiActivated, menuBirthSignCallback, {filter = "MenuBirthSign", priority = priority})

--- @param e uiActivatedEventData
local function menuChooseClassCallback(e)
    if not this.menuMode then return end

    if config.data.change.class.enbled then
        local classScrollUIID = tes3ui.registerID("MenuChooseClass_ClassScroll")
        local pick
        if classChoice == classChoiceEnum.ingame then
            pick = getRandomElement(e.element:findChild(classScrollUIID))
        elseif classChoice ~= classChoiceEnum.ingame then
            pick = getElementForCustomClass(e.element:findChild(classScrollUIID))
        end
        selectElement(e.element:findChild(classScrollUIID), pick)
        pick:triggerEvent(tes3.uiEvent.mouseClick)
    end
    -- end
    local elem = e.element:findChild("MenuChooseClass_Okbutton")
    elem:triggerEvent(tes3.uiEvent.mouseClick)

    timer.delayOneFrame(function()
        if config.data.change.class.enbled then
            log("new class:", tes3.player.object.class)
            applyPlayerStatsByClass(tes3.player.object.class, skillValues, attributeValues, 1)
        end

        finishStatChanges()
    end)
end
event.register(tes3.event.uiActivated, menuChooseClassCallback, {filter = "MenuChooseClass", priority = priority})

--- @param e uiActivatedEventData
local function menuCreateClassCallback(e)
    if not this.menuMode then return end
    local elem = e.element:findChild("MenuCreateClass_Okbutton")
    elem:triggerEvent(tes3.uiEvent.mouseClick)
end
event.register(tes3.event.uiActivated, menuCreateClassCallback, {filter = "MenuCreateClass", priority = priority})

--- @param e uiActivatedEventData
local function menuClassChoiceCallback(e)
    if not this.menuMode then return end
    local elem
    if config.data.change.class.enbled then
        -- if classChoice == classChoiceEnum.ingame then
            elem = e.element:findChild("MenuClassChoice_PickClassbutton")
        -- else
        --     elem = e.element:findChild("MenuClassChoice_CreateClassbutton")
        -- end
    else
        -- if tes3.player.baseObject.class.id == "NEWCLASSID_CHARGEN" then
        --     elem = e.element:findChild("MenuClassChoice_CreateClassbutton")
        -- else
            elem = e.element:findChild("MenuClassChoice_PickClassbutton")
        -- end
    end
    elem:triggerEvent(tes3.uiEvent.mouseClick)
end
event.register(tes3.event.uiActivated, menuClassChoiceCallback, {filter = "MenuClassChoice", priority = priority})

--- @param e uiActivatedEventData
local function menuStatReviewCallback(e)
    if not this.menuMode then return end
    local elem = e.element:findChild("MenuStatReview_Okbutton")
    elem:triggerEvent(tes3.uiEvent.mouseClick)
end
event.register(tes3.event.uiActivated, menuStatReviewCallback, {filter = "MenuStatReview", priority = priority})

--- @param e uiActivatedEventData
local function menuStatCallback(e)
    -- this.menuMode = false
    if config.localConfig.count > 0 then
        local nameZone = e.element:findChild("PartDragMenu_title")
        nameZone.text = tes3.player.object.name.." The "..tostring(config.localConfig.count + 1).."th"
        e.element:getTopLevelMenu():updateLayout()
    end
    if not this.menuMode then return end
    tes3ui.leaveMenuMode()
end
event.register(tes3.event.uiActivated, menuStatCallback, {filter = "MenuStat", priority = priority})

-- ########################

local function decreaseSkill(skillId)
    tes3.modStatistic{reference = tes3.mobilePlayer, skill = skillId, value = -1,}
    log("skill decreased: skill id", skillId)
    if config.data.decrease.skill.levelUp.progress then
        if advTable.isContains(tes3.mobilePlayer.object.class.majorSkills, skillId) or
                advTable.isContains(tes3.mobilePlayer.object.class.minorSkills, skillId) then
            tes3.mobilePlayer.levelUpProgress = math.max(tes3.mobilePlayer.levelUpProgress - 1, 0)
            log("LevelUp progress decreased: skill id", skillId, "progress", tes3.mobilePlayer.levelUpProgress)
        end
    end
    if config.data.decrease.skill.levelUp.attributes then
        if advTable.isContains(tes3.mobilePlayer.object.class.majorSkills, skillId) or
                advTable.isContains(tes3.mobilePlayer.object.class.minorSkills, skillId) then
            local skill = tes3.getSkill(skillId)
            tes3.mobilePlayer.levelupsPerAttribute[skill.attribute + 1] = math.max(tes3.mobilePlayer.levelupsPerAttribute[skill.attribute + 1] - 1, 0)
            log("LevelUp attribute gain decreased: skill id", skillId, "new value", tes3.mobilePlayer.levelupsPerAttribute[skill.attribute + 1])
        end
    end
end

function this.levelDown(decrBy)
    local player = tes3.player
    local levelTo = player.object.level - decrBy <= 1 and 1 or player.object.level - decrBy
    local playerLogData = playerLogger.playerData()
    local initialLevel = player.object.level
    local out = {level = 0, health = 0, attributes = {}, skills = {}}
    for i = #playerLogData, 1, -1 do
        ---@type dataLogger.data.struct
        local data = playerLogData[i]
        if data.event == playerLogger.eventTypes["levelUp"] then
            if data.value <= levelTo then
                tes3.runLegacyScript{command = "setlevel "..tostring(levelTo), reference = player} ---@diagnostic disable-line: missing-fields
                out.level = levelTo - initialLevel
                log("level decreased: to", levelTo)
                return out
            else
                for id, val in ipairs(data.attributes) do
                    tes3.modStatistic{reference = tes3.mobilePlayer, attribute = id - 1, value = -val,}
                    out.attributes[id - 1] = (out.attributes[id - 1] or 0) - val
                    log("attribute decreased: id", id - 1)
                end
                tes3.mobilePlayer.health.base = tes3.mobilePlayer.health.base - (data.health or 0)
                out.health = out.health - (data.health or 0)
                log("health decreased: by", data.health, "to", tes3.mobilePlayer.health.base)
            end
        elseif data.event == playerLogger.eventTypes["skillRaised"] then
            decreaseSkill(data.skillId)
            out.skills[data.skillId] = (out.skills[data.skillId] or 0) - 1
        end
        table.remove(playerLogData, i)
    end
    return out
end

function this.skillDown(decrBy)
    local playerLogData = playerLogger.playerData()
    local skills = {}
    for i = #playerLogData, 1, -1 do
        if decrBy <= 0 then return skills end
        ---@type dataLogger.data.struct
        local data = playerLogData[i]
        if data.event == playerLogger.eventTypes["skillRaised"] then
            decreaseSkill(data.skillId)
            table.remove(playerLogData, i)
            decrBy = decrBy - 1
            skills[data.skillId] = (skills[data.skillId] or 0) - 1
        end
    end
    return skills
end

function this.removeSpells(count, isRandom)
    local playerLogData = playerLogger.playerData()
    local spellData = {}
    for i = #playerLogData, 1, -1 do
        if count <= 0 then return end
        ---@type dataLogger.data.struct
        local data = playerLogData[i]
        if data.event == playerLogger.eventTypes["spellLearned"]then
            table.insert(spellData, {i, data.spellId})
        end
    end
    local removedSpells = {}
    for i = 1, count do
        if #spellData <= 0 then break end
        if not isRandom then
            tes3.removeSpell{reference = tes3.player, spell = spellData[2]}
            table.insert(removedSpells, spellData[2])
            log("spell removed: id", spellData[2])
            table.remove(playerLogData, spellData[1])
        else
            local id = math.random(#spellData)
            local data = spellData[id]
            if data then
                tes3.removeSpell{reference = tes3.player, spell = data[2]}
                table.insert(removedSpells, data[2])
                log("spell removed: id", data[2])
                table.remove(playerLogData, data[1])
                table.remove(spellData, id)
            end
        end
    end
    return removedSpells
end

function this.getLastLevel()
    local playerLogData = playerLogger.playerData()
    for i = #playerLogData, 1, -1 do
        ---@type dataLogger.data.struct
        local data = playerLogData[i]
        if data.event == playerLogger.eventTypes["levelUp"] then
            return data.value
        end
    end
    return 1
end

function this.giveDefaultEquipment()
    for _, itId in pairs(this.playerDefaultItems) do
        local obj = tes3.getObject(itId)
        if obj then
            local equippedItem = tes3.getEquippedItem{actor = tes3.mobilePlayer, objectType = obj.objectType, slot = obj.slot, type = obj.type} ---@diagnostic disable-line: assign-type-mismatch
            if not equippedItem then
                tes3.mobilePlayer:equip{item = obj, addItem = true}
            end
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
end

function this.reevaluateMissedPlayerEquipment()
    for _, stack in pairs(tes3.mobilePlayer.object.equipment) do
        local obj = stack.object
        if (obj.objectType == tes3.objectType.armor or obj.objectType == tes3.objectType.clothing or
                obj.objectType == tes3.objectType.weapon or obj.objectType == tes3.objectType.ammunition) then

            local equippedItem = tes3.getEquippedItem{actor = tes3.mobilePlayer, objectType = obj.objectType, slot = obj.slot, type = obj.type} ---@diagnostic disable-line: assign-type-mismatch
            if not equippedItem or equippedItem.object.value < obj.value then
                tes3.mobilePlayer:equip{item = obj}
            end
        end
    end
end

function this.giveEquipmentFromRandomNPC(countMul, playerLevel)
    local npcs = {}
    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        if obj.id ~= "player" and not obj.id:find("_dpl_") then
            table.insert(npcs, {object = obj, level = obj.level}) ---@diagnostic disable-line: undefined-field
        end
    end
    table.sort(npcs, function(a, b) return a.level < b.level end)

    local endLabel = 1
    for i, npcData in ipairs(npcs) do
        if npcData.level > playerLevel then
            break
        end
        endLabel = i
    end
    local startLabel = 1
    for i, npcData in ipairs(npcs) do
        if npcData.level >= playerLevel * countMul then
            break
        end
        startLabel = i
    end
    if startLabel > endLabel - 50 then startLabel = math.max(1, endLabel - 50) end

    local allowedItemTypes = {[tes3.objectType.armor] = true, [tes3.objectType.clothing] = true, [tes3.objectType.weapon] = true,
        [tes3.objectType.ammunition] = true}

    local function chooseNPC(step)
        step = step - 1
        local npc = npcs[math.random(startLabel, endLabel)].object
        if step >= 0 then
            local hasItems = false
            for _, stack in pairs(npc.inventory) do
                local item = stack.object
                if allowedItemTypes[item.objectType] then
                    hasItems = true
                    break
                end
            end
            if hasItems then
                return npc
            else
                return chooseNPC(step)
            end
        end
        return npc
    end
    local matchedNPC = chooseNPC(15)

    log("equipment from:", matchedNPC)

    local getItemTypeStr = function(item)
        return tostring(item.objectType).."s"..tostring(item.slot).."t"..tostring(item.objectType ~= tes3.objectType.weapon and item.type or "")
    end

    local itemTypesThatPlayerHave = {}
    for _, stack in pairs(tes3.mobilePlayer.inventory) do
        local item = stack.object
        if allowedItemTypes[item.objectType] then
            itemTypesThatPlayerHave[getItemTypeStr(item)] = true
        end
    end

    local itemsThatCanTransferToPlayer = {}
    for _, stack in pairs(matchedNPC.inventory) do
        local item = stack.object
        if  allowedItemTypes[item.objectType] and not itemTypesThatPlayerHave[getItemTypeStr(item)] then
            local itemTypeStr = getItemTypeStr(item)
            if not itemsThatCanTransferToPlayer[itemTypeStr] then itemsThatCanTransferToPlayer[itemTypeStr] = {} end
            table.insert(itemsThatCanTransferToPlayer[itemTypeStr], item)
        end
    end

    for _, group in pairs(itemsThatCanTransferToPlayer) do
        local item = group[math.random(#group)]
        local canEquip = item.objectType ~= tes3.objectType.armor or not tes3.player.object.race.isBeast or
            not (item.slot == tes3.armorSlot.helmet or item.slot == tes3.armorSlot.boots)
        if canEquip then
            log(item)
            tes3.addItem{reference = tes3.mobilePlayer, item = item, count = item.objectType == tes3.objectType.ammunition and 20 or 1, limit = false, updateGUI = true}
            tes3.mobilePlayer:equip{item = item}
        end
    end


    tes3ui.forcePlayerInventoryUpdate()
end

local function addRestoreSpells_timer()
    tes3.removeSpell{reference = tes3.player, spell = "jai_curespell_attributes"}
    tes3.removeSpell{reference = tes3.player, spell = "jai_curespell_skills_0"}
    tes3.removeSpell{reference = tes3.player, spell = "jai_curespell_skills_1"}
    tes3.removeSpell{reference = tes3.player, spell = "jai_curespell_skills_2"}
    tes3.removeSpell{reference = tes3.player, spell = "jai_curespell_skills_3"}
end

-- except dynamic stats like health
function this.addRestoreSpells(forTime)
    tes3.addSpell{reference = tes3.player, spell = "jai_curespell_attributes"}
    tes3.addSpell{reference = tes3.player, spell = "jai_curespell_skills_0"}
    tes3.addSpell{reference = tes3.player, spell = "jai_curespell_skills_1"}
    tes3.addSpell{reference = tes3.player, spell = "jai_curespell_skills_2"}
    tes3.addSpell{reference = tes3.player, spell = "jai_curespell_skills_3"}
    timer.start{duration = forTime, callback = "JAIByDiject_addRestoreSpells_timer"}
end

local function addDynamicStatsRestoreSpells_timer()
    tes3.removeSpell{reference = tes3.player, spell = "jai_curespell_stats"}
end

function this.addDynamicStatsRestoreSpells(forTime)
    tes3.addSpell{reference = tes3.player, spell = "jai_curespell_stats"}
    timer.start{duration = forTime, callback = "JAIByDiject_addDynamicStatsRestoreSpells_timer"}
end


function this.createDuplicate()
    local playerPos = tes3.player.position
    local playerRot = tes3.player.orientation
    local playerCell = tes3.player.cell

    do
        local objId
        local obj
        local objConfig
        local rnd = math.random() * 100
        if config.data.spawn.body.chance > rnd then
            local raceId = tostring(tes3.player.baseObject.race):lower()
            local objPrefix = this.npcTemplate..(tes3.player.baseObject.female and "f_" or "m_")
            objId = objPrefix..raceId
            obj = tes3.getObject(objId)
            if not obj then
                if tes3.player.baseObject.race.isBeast then
                    objId = objPrefix.."khajiit"
                else
                    objId = objPrefix.."dark elf"
                end
            end
            objConfig = config.data.spawn.body
        elseif config.data.spawn.body.chance + config.data.spawn.creature.chance > rnd then
            local creatureTemplate = this.creatureTemplates[math.random(#this.creatureTemplates)]
            local pickList = {creatureTemplate.."0"}
            for i = 1, 4 do
                if tes3.player.baseObject.level >= i * 5 then
                    table.insert(pickList, creatureTemplate..tostring(i))
                else
                    break
                end
            end
            objId = pickList[math.random(#pickList)]
            objConfig = config.data.spawn.creature
        end
        obj = tes3.getObject(objId or "")
        if obj and objId and objConfig then
            local newRef = tes3.createReference{object = objId, position = playerPos, orientation = playerRot, cell = playerCell}
            local randomizer = include("Morrowind_World_Randomizer.Randomizer")
            if randomizer then
                randomizer.StopRandomization(newRef)
            end

            if not newRef then return end

            npcLib.transferStats(tes3.player, newRef)
            tooltipChanger.saveTooltip(newRef, tes3.player.object.name..(config.localConfig.count > 0 and " The "..tostring(config.localConfig.count + 1).."th" or ""))
            localStorage.getStorage(newRef).isPlayerCopy = true

            local raceData = dataStorage.getRaceData(tes3.player.baseObject.race)
            bodypartChanger.saveBodyParts(newRef, raceData, {hair = tes3.player.baseObject.hair.id, head = tes3.player.baseObject.head.id})
            newRef:updateEquipment()
            for stat, mulPercent in pairs(objConfig.stats) do
                local value = mulPercent / 100 * tes3.mobilePlayer[stat].base
                tes3.setStatistic{reference = newRef, name = stat, current = value, base = value}
            end
            if objConfig.chanceToCorpse / 100 > math.random() then
                tes3.setStatistic{reference = newRef, name = "health", current = 0}
            elseif obj.objectType == tes3.objectType.npc then
                -- tes3.addSpell{reference = newRef, spell = "ghost ability"}
                newRef.mobile.fight = 100
                newRef.mobile.chameleon = 50
                newRef.mobile.resistMagicka = 9999
                newRef.mobile:updateOpacity()
            end

            local boundItems = {}
            for _, effect in pairs(tes3.mobilePlayer.activeMagicEffectList) do
                if effect.effectInstance.createdData and effect.effectInstance.createdData.object then
                    boundItems[effect.effectInstance.createdData.object.id] = true
                end
            end

            local equipped = {}
            local otherEquipnemtItems = {}
            local magicItems = {}
            local books = {}
            local miscItems = {}
            for _, stack in pairs(tes3.mobilePlayer.inventory) do
                if boundItems[stack.object.id] or not stack.object then goto continue end
                if stack.object.isGold then
                    local goldPercent = config.data.spawn.transfer.goldPercent / 100
                    if goldPercent > 0 then
                        local count = math.floor(stack.count * goldPercent)
                        tes3.transferItem{from = tes3.player, to = newRef, item = stack.object, count = count, playSound = true, limitCapacity = false, updateGUI = false}
                    end
                elseif (stack.object.objectType == tes3.objectType.armor or stack.object.objectType == tes3.objectType.clothing or
                        stack.object.objectType == tes3.objectType.weapon or stack.object.objectType == tes3.objectType.ammunition) and
                        stack.object.weight > 0 then
                    if tes3.getEquippedItem{actor = tes3.player, objectType = stack.object.objectType, slot = stack.object.slot, type = stack.object.type} then
                        table.insert(equipped, {object = stack.object, count = stack.count})
                    else
                        table.insert(otherEquipnemtItems, {object = stack.object, count = stack.count})
                    end
                elseif (stack.object.objectType == tes3.objectType.alchemy or (stack.object.objectType == tes3.objectType.book and stack.object.enchantment)) then
                    table.insert(magicItems, {object = stack.object, count = stack.count})
                elseif stack.object.objectType == tes3.objectType.book then
                    table.insert(books, {object = stack.object, count = stack.count})
                elseif stack.object.weight > 0 then
                    table.insert(miscItems, {object = stack.object, count = stack.count})
                end
                ::continue::
            end

            local function calcNumber(val, maxVal)
                return config.data.spawn.transfer.inPersent and math.ceil(val / 100 * maxVal) or val
            end

            local transferOtherEquipnemtCount = calcNumber(config.data.spawn.transfer.equipment, #otherEquipnemtItems)
            local transferEquippedCount = calcNumber(config.data.spawn.transfer.equipedItems, #equipped)
            local transferMagicItemsCount = calcNumber(config.data.spawn.transfer.magicItems, #magicItems)
            local transferBooksCount = calcNumber(config.data.spawn.transfer.books, #books)
            local transferMiscCount = calcNumber(config.data.spawn.transfer.misc, #miscItems)
            local struct = {
                {transferOtherEquipnemtCount, otherEquipnemtItems},
                {transferEquippedCount, advTable.deepcopy(equipped)},
                {transferMagicItemsCount, magicItems},
                {transferBooksCount, books},
                {transferMiscCount, miscItems},
            }
            for _, data in pairs(struct) do
                for i = 1, data[1] do
                    if #data[2] > 0 then
                        local itemId = math.random(1, #data[2])
                        local item = data[2][itemId]
                        tes3.transferItem{from = tes3.player, to = newRef, item = item.object, count = item.count, playSound = true, updateGUI = false,
                            limitCapacity = false, reevaluateEquipment = false}
                        table.remove(data[2], itemId)
                    end
                end
            end
            tes3ui.forcePlayerInventoryUpdate()

            if newRef.baseObject.objectType == tes3.objectType.npc then
                for _, item in pairs(equipped) do
                    newRef.mobile:equip{item = item.object}
                end
            end
            newRef.object.modified = true
        end
    end
end

function this.addSummonSpell()
    local spell = tes3.createObject{id = this.summonSpellId, objectType = tes3.objectType.spell, getIfExists = true,
        name = "Azura's voice",
        castType = tes3.spellType.power,
        magickaCost = 0,
    }
    spell.effects[1].id = tes3.effect.light
    spell.effects[1].max = 10
    spell.effects[1].min = 10
    spell.effects[1].duration = 10
    spell.effects[1].rangeType = tes3.effectRange.self
    if not tes3.player.object.spells:contains(spell) then
        tes3.addSpell{reference = tes3.player, spell = spell}
    end
end

function this.removeSummonSpell()
    if tes3.player.object.spells:contains(this.summonSpellId) then
        tes3.removeSpell{reference = tes3.player, spell = this.summonSpellId}
    end
end




function this.init()
    for _, race in pairs(tes3.dataHandler.nonDynamicData.races) do
        for _, spell in pairs(race.abilities) do
            this.disallowedSpellIds[spell.id:lower()] = true
        end
    end

    for _, race in pairs(tes3.dataHandler.nonDynamicData.birthsigns) do
        for _, spell in pairs(race.spells) do
            this.disallowedSpellIds[spell.id:lower()] = true
        end
    end

    this.disallowedSpellIds["fire bite"] = true
    this.disallowedSpellIds["chameleon"] = true
    this.disallowedSpellIds["sanctuary"] = true
    this.disallowedSpellIds["bound dagger"] = true
    this.disallowedSpellIds["summon ancestral ghost"] = true
    this.disallowedSpellIds["water walking"] = true
    this.disallowedSpellIds["shield"] = true
    this.disallowedSpellIds["detect_creature"] = true
    this.disallowedSpellIds["hearth heal"] = true

    timer.register("JAIByDiject_addDynamicStatsRestoreSpells_timer", addDynamicStatsRestoreSpells_timer)
    timer.register("JAIByDiject_addRestoreSpells_timer", addRestoreSpells_timer)
end

function this.reset()
    this.menuMode = false
    this.bodyPartsChanged = false
end

return this