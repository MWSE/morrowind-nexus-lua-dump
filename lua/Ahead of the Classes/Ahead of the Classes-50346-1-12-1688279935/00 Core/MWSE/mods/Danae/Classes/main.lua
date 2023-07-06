local skillModule = include("OtherSkills.skillModule")
local presetClasses = require("Danae.Classes.presetClasses")
local customClasses = require("Danae.Classes.customClasses")


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
        mwscript.addSpell{ reference = tes3.player, spell = spell }
    end
end

local function addGear(gearList)
    for _, gear in ipairs(gearList) do
        if tes3.getObject(gear.item) then
            tes3.addItem{
                reference = tes3.player,
                item = gear.item,
                count = gear.count,
                updateGUI = false,
                playSound = false
            }
        else
            mwse.log("%s does not exist", gear.item)
        end
    end
    tes3ui.forcePlayerInventoryUpdate()

    --Equip everything in inventory
    timer.delayOneFrame(function()
        for _, stack in pairs(tes3.player.object.inventory) do
            local itemObject = stack.object
            if (
                itemObject.objectType == tes3.objectType.armor or
                itemObject.objectType == tes3.objectType.weapon or
                itemObject.objectType == tes3.objectType.clothing
            ) then
                tes3.mobilePlayer:equip{ item = itemObject, playSound = false }
            end
        end
        tes3.messageBox("Class based equipment and spells added.")
    end)
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
    addGear(starters.gearList)
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

local function loaded()
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