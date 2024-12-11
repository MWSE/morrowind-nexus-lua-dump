local skillModule = include("SkillModule")
local presetClasses = require("Danae.Classes.presetClasses")
local customClasses = require("Danae.Classes.customClasses")
local ChargenScenarios = include("mer.chargenScenarios")

local function modifyCustomSkills(customSkillList)
    if not customSkillList then
        return
    end
    if not skillModule then
        return
    end
    for _, customSkill in pairs(customSkillList) do
        local skill = skillModule.getSkill(customSkill.skillId)
        if skill then
            skill:levelUpSkill(customSkill.value)
        end
    end
end

local function addSpells(spellList)
    for _, spell in ipairs(spellList) do
        tes3.addSpell{ reference = tes3.player, spell = spell }
    end
end

local function raceCanEquip(itemObject)
    local isBeast = tes3.player.object.race.isBeast
    local canEquip = true
    if isBeast then
        canEquip = itemObject.isUsableByBeasts ~= false
    end
    return canEquip
end


local function getStarters()
    local class = tes3.player.object.class.id:lower()
    local starters
    if presetClasses.pickStarters[class] then
        starters = presetClasses.pickStarters[class]()
    else
        starters = customClasses.pickStarters()
    end
    return starters
end

---@return table<string, number>
local function getGear()
    local starters = getStarters()
    local gearList = starters.gearList
    ---@type table<string, number>
    local classGear = {}
    for _, gear in ipairs(gearList) do
        local count = gear.count or 1
        local itemObject = tes3.getObject(gear.item)
        if itemObject then
            if raceCanEquip(itemObject) then
                mwse.log("Adding %s to gear list", gear.item)
                classGear[gear.item] = classGear[gear.item] and (classGear[gear.item] + count) or count
            else
                mwse.log("beast, cannot equip %s, giving gold instead", gear.item)
                local gold= "gold_001"
                local amount = count * itemObject.value
                classGear[gold] = classGear[gold] and (classGear[gold] + amount) or amount
            end
        else
            mwse.log("%s does not exist", gear.item)
        end
    end
    return classGear
end

local function addGear()
    if ChargenScenarios then
        mwse.log("ChargenScenarios detected, skipping gear")
        return
    end

    for id, count in pairs(getGear()) do
        tes3.addItem{
            reference = tes3.player,
            item = id,
            count = count,
            playSound = false,
        }
    end
    --Equip everything in inventory
    for _, stack in pairs(tes3.player.object.inventory) do
        local itemObject = stack.object
        if (
            itemObject.objectType == tes3.objectType.armor or
            itemObject.objectType == tes3.objectType.weapon or
            itemObject.objectType == tes3.objectType.clothing
        ) then
            if raceCanEquip(itemObject) then
                mwse.log("Equipping %s", itemObject)
                tes3.equip{
                    item = itemObject,
                    reference = tes3.player,
                    playSound = false,
                }
            else
                mwse.log("Beast - cannot equip %s", itemObject)
            end
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
    tes3.messageBox("Class based equipment and spells added.")
end


local function startClass()
    local class = tes3.player.object.class.id:lower()
    local starters
    if presetClasses.pickStarters[class] then
        starters = presetClasses.pickStarters[class]()
    else
        starters = customClasses.pickStarters()
    end
    addSpells(starters.spellList)
    addGear()
    modifyCustomSkills(starters.customSkillList)
end

local charGen
local newGame
local checkingChargen
local function checkCharGen()
    if charGen.value == 10 then
        newGame = true
    elseif newGame and charGen.value == -1 then
        checkingChargen = false
        event.unregister("simulate", checkCharGen)
        timer.start{
            type = timer.simulate,
            duration = 0.7, --If clashes with char backgrounds, mess with this
            callback = startClass
        }
    end
end

local classItemListCache = {}


if ChargenScenarios then
    ChargenScenarios.registerLoadout{
        id = "aheadOfTheClasses",
        callback = function()
            local class = tes3.player.object.class.id:lower()
            if classItemListCache[class] then
                return classItemListCache[class]
            end

            mwse.log("Getting Class based loadout")
            local gear = getGear()

            ---@type ChargenScenarios.ItemListInput
            local itemList = {
                name = "Class: " .. tes3.player.object.class.name,
                items = {}
            }
            for id, count in pairs(gear) do
                ---@type ChargenScenariosItemPickInput
                local itemPick = {
                    id = id,
                    count = count,
                    noSlotDuplicates = true,
                }
                table.insert(itemList.items, itemPick)
            end
            itemList = ChargenScenarios.ItemList:new(itemList)
            classItemListCache[class] = itemList
            return itemList
        end
    }
end


local function loaded()
    if ChargenScenarios then return end
    newGame = nil --reset so we can check chargen state again
    charGen = tes3.findGlobal("CharGenState")
    --Only reregister if necessary. If new game was started during
    --  chargen of previous game, this will already be running
    if not checkingChargen then
        event.register("simulate", checkCharGen)
        checkingChargen = true
    end
end

event.register("loaded", loaded )

event.register("ChargenScenarios:ScenarioStarted", function(e)
    startClass()
end)