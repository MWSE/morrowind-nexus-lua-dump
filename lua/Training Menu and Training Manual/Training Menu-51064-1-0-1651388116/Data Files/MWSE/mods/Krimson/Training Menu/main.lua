local config = mwse.loadConfig("Training Menu", {
    limitMajor = true,
    limitMinor = true,
    limitMisc = true,
    majorLimit = 100,
    minorLimit = 100,
    miscLimit = 100,
    advTime = true,
    keyBind = {keyCode = tes3.scanCode.rCtrl, isShiftDown = false, isAltDown = false, isControlDown = false},
})

local trainedSkill
local cost
local attr
local skill
local trainer = {}
local combat
local magic
local stealth
local armo
local athl
local axe
local block
local blunt
local heavy
local long
local medi
local spear
local alch
local alte
local conj
local dest
local ench
local illu
local myst
local rest
local unar
local acro
local hand
local light
local mark
local merc
local secu
local short
local sneak
local spee

local function combatMenu()
    return combat()
end

local function magicMenu()
    return magic()
end

local function stealthMenu()
    return stealth()
end

local function armoMenu()
    return armo()
end

local function athlMenu()
    return athl()
end

local function axeMenu()
    return axe()
end

local function blockMenu()
    return block()
end

local function bluntMenu()
    return blunt()
end

local function heavyMenu()
    return heavy()
end

local function longMenu()
    return long()
end

local function mediMenu()
    return medi()
end

local function spearMenu()
    return spear()
end

local function alchMenu()
    return alch()
end

local function alteMenu()
    return alte()
end

local function conjMenu()
    return conj()
end

local function destMenu()
    return dest()
end

local function enchMenu()
    return ench()
end

local function illuMenu()
    return illu()
end

local function mystMenu()
    return myst()
end

local function restMenu()
    return rest()
end

local function unarMenu()
    return unar()
end

local function acroMenu()
    return acro()
end

local function handMenu()
    return hand()
end

local function lightMenu()
    return light()
end

local function markMenu()
    return mark()
end

local function mercMenu()
    return merc()
end

local function secuMenu()
    return secu()
end

local function shortMenu()
    return short()
end

local function sneakMenu()
    return sneak()
end

local function speeMenu()
    return spee()
end

function trainer.spear(button)

    if button == 0 then
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.spear)
        attr = tes3.mobilePlayer.endurance.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.spear)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.spear)
        spearMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerSpear()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.spear.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Spear", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.spear(e.button)
        end)
    end})
end

function trainer.medi(button)

    if button == 0 then
        attr = tes3.mobilePlayer.endurance.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.mediumArmor)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.mediumArmor)
        mediMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerMedi()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.mediumArmor.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Medium Armor", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.medi(e.button)
        end)
    end})
end

function trainer.long(button)

    if button == 0 then
        attr = tes3.mobilePlayer.strength.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.longBlade)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.longBlade)
        longMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerLong()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.longBlade.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Long Blade", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.long(e.button)
        end)
    end})
end

function trainer.heavy(button)

    if button == 0 then
        attr = tes3.mobilePlayer.endurance.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.heavyArmor)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.heavyArmor)
        heavyMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerHeavy()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.heavyArmor.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Heavy Armor", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.heavy(e.button)
        end)
    end})
end

function trainer.blunt(button)

    if button == 0 then
        attr = tes3.mobilePlayer.strength.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.bluntWeapon)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.bluntWeapon)
        bluntMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerBlunt()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.bluntWeapon.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Blunt Weapon", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.blunt(e.button)
        end)
    end})
end

function trainer.block(button)

    if button == 0 then
        attr = tes3.mobilePlayer.agility.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.block)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.block)
        blockMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerBlock()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.block.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Block", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.block(e.button)
        end)
    end})
end

function trainer.axe(button)

    if button == 0 then
        attr = tes3.mobilePlayer.strength.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.axe)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.axe)
        axeMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerAxe()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.axe.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Axe", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.axe(e.button)
        end)
    end})
end

function trainer.athl(button)

    if button == 0 then
        attr = tes3.mobilePlayer.speed.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.athletics)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.athletics)
        athlMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerAthl()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.athletics.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Athletics", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.athl(e.button)
        end)
    end})
end

function trainer.armo(button)

    if button == 0 then
        attr = tes3.mobilePlayer.strength.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.armorer)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.armorer)
        armoMenu()
    elseif button == 1 then
        combatMenu()
    elseif button == 2 then
        magicMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerArmo()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.armorer.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Armorer", "Other Combat Skills", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.armo(e.button)
        end)
    end})
end

function trainer.combat(button)

    if button == 0 then
        trainerArmo()
    elseif button == 1 then
        trainerAthl()
    elseif button == 2 then
        trainerAxe()
    elseif button == 3 then
        trainerBlock()
    elseif button == 4 then
        trainerBlunt()
    elseif button == 5 then
        trainerHeavy()
    elseif button == 6 then
        trainerLong()
    elseif button == 7 then
        trainerMedi()
    elseif button == 8 then
        trainerSpear()
    elseif button == 9 then
        magicMenu()
    elseif button == 10 then
        stealthMenu()
    elseif button == 11 then
        return
    end
end

local function trainerCombat()

    tes3.messageBox({message = "Which combat skill ?", buttons = {"Armorer", "Athletics", "Axe", "Block", "Blunt Weapon", "Heavy armor", "Long Blade", "Medium Armor", "Spear", "Magic Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.combat(e.button)
        end)
    end})
end

function trainer.unar(button)

    if button == 0 then
        attr = tes3.mobilePlayer.speed.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.unarmored)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.unarmored)
        unarMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerUnar()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.unarmored.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Unarmored", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.unar(e.button)
        end)
    end})
end

function trainer.rest(button)

    if button == 0 then
        attr = tes3.mobilePlayer.willpower.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.restoration)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.restoration)
        restMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerRest()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.restoration.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Restoration", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.rest(e.button)
        end)
    end})
end

function trainer.myst(button)

    if button == 0 then
        attr = tes3.mobilePlayer.willpower.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.mysticism)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.mysticism)
        mystMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerMyst()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.mysticism.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Mysticism", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.myst(e.button)
        end)
    end})
end

function trainer.illu(button)

    if button == 0 then
        attr = tes3.mobilePlayer.personality.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.illusion)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.illusion)
        illuMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerIllu()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.illusion.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Illusion", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.illu(e.button)
        end)
    end})
end

function trainer.ench(button)

    if button == 0 then
        attr = tes3.mobilePlayer.intelligence.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.enchant)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.enchant)
        enchMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerEnch()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.enchant.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Enchant", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.ench(e.button)
        end)
    end})
end

function trainer.dest(button)

    if button == 0 then
        attr = tes3.mobilePlayer.willpower.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.destruction)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.destruction)
        destMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerDest()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.destruction.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Destruction", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.dest(e.button)
        end)
    end})
end

function trainer.conj(button)

    if button == 0 then
        attr = tes3.mobilePlayer.intelligence.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.conjuration)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.conjuration)
        conjMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerConj()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.conjuration.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Conjuration", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.conj(e.button)
        end)
    end})
end

function trainer.alte(button)

    if button == 0 then
        attr = tes3.mobilePlayer.willpower.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.alteration)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.alteration)
        alteMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerAlte()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.alteration.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Alteration", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.alte(e.button)
        end)
    end})
end

function trainer.alch(button)

    if button == 0 then
        attr = tes3.mobilePlayer.intelligence.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.alchemy)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.alchemy)
        alchMenu()
    elseif button == 1 then
        magicMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        stealthMenu()
    elseif button == 4 then
        return
    end
end

local function trainerAlch()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.alchemy.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Alchemy", "Other Magic Skills", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.alch(e.button)
        end)
    end})
end

function trainer.magic(button)

    if button == 0 then
        trainerAlch()
    elseif button == 1 then
        trainerAlte()
    elseif button == 2 then
        trainerConj()
    elseif button == 3 then
        trainerDest()
    elseif button == 4 then
        trainerEnch()
    elseif button == 5 then
        trainerIllu()
    elseif button == 6 then
        trainerMyst()
    elseif button == 7 then
        trainerRest()
    elseif button == 8 then
        trainerUnar()
    elseif button == 9 then
        combatMenu()
    elseif button == 10 then
        stealthMenu()
    elseif button == 11 then
        return
    end
end

local function trainerMagic()

    tes3.messageBox({message = "Which magic skill ?", buttons = {"Alchemy", "Alteration", "Conjuration", "Destruction", "Enchant", "Illusion", "Mysticism", "Restoration", "Unarmored", "Combat Skills", "Stealth Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.magic(e.button)
        end)
    end})
end

function trainer.spee(button)

    if button == 0 then
        attr = tes3.mobilePlayer.personality.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.speechcraft)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.speechcraft)
        speeMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerSpee()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.speechcraft.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Speechcraft", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.spee(e.button)
        end)
    end})
end

function trainer.sneak(button)

    if button == 0 then
        attr = tes3.mobilePlayer.agility.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.sneak)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.sneak)
        sneakMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerSneak()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.sneak.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Sneak", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.sneak(e.button)
        end)
    end})
end

function trainer.short(button)

    if button == 0 then
        attr = tes3.mobilePlayer.speed.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.shortBlade)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.shortBlade)
        shortMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerShort()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.shortBlade.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Short Blade", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.short(e.button)
        end)
    end})
end

function trainer.secu(button)

    if button == 0 then
        attr = tes3.mobilePlayer.intelligence.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.security)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.security)
        secuMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerSecu()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.security.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Security", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.secu(e.button)
        end)
    end})
end

function trainer.merc(button)

    if button == 0 then
        attr = tes3.mobilePlayer.personality.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.mercantile)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.mercantile)
        mercMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerMerc()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.mercantile.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Mercantile", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.merc(e.button)
        end)
    end})
end

function trainer.mark(button)

    if button == 0 then
        attr = tes3.mobilePlayer.agility.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.marksman)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.marksman)
        markMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerMark()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.marksman.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Marksman", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.mark(e.button)
        end)
    end})
end

function trainer.light(button)

    if button == 0 then
        attr = tes3.mobilePlayer.agility.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.lightArmor)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.lightArmor)
        lightMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerLight()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.lightArmor.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Light Armor", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.light(e.button)
        end)
    end})
end

function trainer.hand(button)

    if button == 0 then
        attr = tes3.mobilePlayer.speed.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.handToHand)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.handToHand)
        handMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerHand()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.handToHand.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Hand To Hand", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.hand(e.button)
        end)
    end})
end

function trainer.acro(button)

    if button == 0 then
        attr = tes3.mobilePlayer.strength.base
        if cost > tes3.getPlayerGold() then
            tes3.messageBox({message = "You do not have enough gold."})
            return
        end
        if skill >= attr then
            tes3.messageBox({message = "Cannot train past the skills governing attribute."})
            return
        end
        trainedSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.acrobatics)
        if trainedSkill.type == tes3.skillType.major then
            if config.limitMajor then
                if skill >= config.majorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.minor then
            if config.limitMinor then
                if skill >= config.minorLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        elseif trainedSkill.type == tes3.skillType.misc then
            if config.limitMisc then
                if skill >= config.miscLimit then
                    tes3.messageBox({message = "This skill cannot be trained any higher."})
                    return
                end
            end
        end
        tes3.removeItem({ reference = tes3.mobilePlayer, item = "gold_001", count = cost, playSound = true, updateGUI = true })
        if config.advTime then
            tes3.fadeOut({duration = 1})
            tes3.fadeIn({duration = 1})
            tes3.advanceTime({hours = 2})
        end
        tes3.mobilePlayer:progressSkillToNextLevel(tes3.skill.acrobatics)
        acroMenu()
    elseif button == 1 then
        stealthMenu()
    elseif button == 2 then
        combatMenu()
    elseif button == 3 then
        magicMenu()
    elseif button == 4 then
        return
    end
end

local function trainerAcro()

    local pcMerc = tes3.mobilePlayer.mercantile.base
    skill = tes3.mobilePlayer.acrobatics.base
    cost = 0.43 + 0.062 * (194.3 - pcMerc) * skill
    local gold = tes3.getPlayerGold()
    tes3.messageBox({message = string.format("Current skill level %d \n\nTraining cost %d \n\nYour gold %d \n", skill, cost, gold), buttons = {"Train Acrobatics", "Other Stealth Skills", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.acro(e.button)
        end)
    end})
end

function trainer.stealth(button)

    if button == 0 then
        trainerAcro()
    elseif button == 1 then
        trainerHand()
    elseif button == 2 then
        trainerLight()
    elseif button == 3 then
        trainerMark()
    elseif button == 4 then
        trainerMerc()
    elseif button == 5 then
        trainerSecu()
    elseif button == 6 then
        trainerShort()
    elseif button == 7 then
        trainerSneak()
    elseif button == 8 then
        trainerSpee()
    elseif button == 9 then
        combatMenu()
    elseif button == 10 then
        magicMenu()
    elseif button == 11 then
        return
    end
end

local function trainerStealth()

    tes3.messageBox({message = "Which stealth skill ?", buttons = {"Acrobatics", "Hand to Hand", "Light Armor", "Marksman", "Mercantile", "Security", "Short Blade", "Sneak", "Speechcraft", "Combat Skills", "Magic Skills", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.stealth(e.button)
        end)
    end})
end

function trainer.main(button)

    if button == 0 then
        trainerCombat()
    elseif button == 1 then
        trainerMagic()
    elseif button == 2 then
        trainerStealth()
    elseif button == 3 then
        return
    end
end

local function trainerMain()

    tes3.messageBox({message = "Which type of skill ?", buttons = {"Combat", "Magic", "Stealth", "Cancel"},
    callback = function(e)
        timer.delayOneFrame(function() trainer.main(e.button)
        end)
    end})
end

combat = function()
    trainerCombat()
end

magic = function()
    trainerMagic()
end

stealth = function()
    trainerStealth()
end

armo = function ()
    trainerArmo()
end

athl = function ()
    trainerAthl()
end

axe = function ()
    trainerAxe()
end

block = function ()
    trainerBlock()
end

blunt = function ()
    trainerBlunt()
end

heavy = function ()
    trainerHeavy()
end

long = function ()
    trainerLong()
end

medi = function ()
    trainerMedi()
end

spear = function ()
    trainerSpear()
end

alch = function ()
    trainerAlch()
end

alte = function ()
    trainerAlte()
end

conj = function ()
    trainerConj()
end

dest = function ()
    trainerDest()
end

ench = function ()
    trainerEnch()
end

illu = function ()
    trainerIllu()
end

myst = function ()
    trainerMyst()
end

rest = function ()
    trainerRest()
end

unar = function ()
    trainerUnar()
end

acro = function ()
    trainerAcro()
end

hand = function ()
    trainerHand()
end

light = function ()
    trainerLight()
end

mark = function ()
    trainerMark()
end

merc = function ()
    trainerMerc()
end

secu = function ()
    trainerSecu()
end

short = function ()
    trainerShort()
end

sneak = function ()
    trainerSneak()
end

spee = function ()
    trainerSpee()
end

--[[local function onEquip(e)

    if e.item.id == "Krimson_trainingManual" then
        tes3ui.leaveMenuMode()
        trainerMain()
    end
end]]

local function trainingMenu()

    if tes3ui.menuMode() then
        return
    end
    trainerMain()
end

local function registerConfig()

    local template = mwse.mcm.createTemplate("Training Menu")
    template:saveOnClose("Training Menu", config)
    template:register()

    local page = template:createSideBarPage({
        label = "Training Menu",
    })

    local settings = page:createCategory("Training Menu Settings\n\n\n\nMajor Skills")

    settings:createOnOffButton({
        label = "Enable Major skill limit",
        description = "Turns on/off a limit for training Major skills.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "limitMajor", table = config}
    })

    settings:createSlider{
        label = "Training limit for Major skills.",
        description = "Sets the limit on training your Major skills.\n\nNo effect if above button is OFF.\n\nDefault: 100\n\n",
        min = 1,
        max = 150,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "majorLimit", table = config}
    }

    local settings1 = page:createCategory("Minor Skills")

    settings1:createOnOffButton({
        label = "Enable Minor skill limit",
        description = "Turns on/off a limit for training Minor skills.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "limitMinor", table = config}
    })

    settings1:createSlider{
        label = "Training limit for Minor skills.",
        description = "Sets the limit on training your Minor skills.\n\nNo effect if above button is OFF.\n\nDefault: 100\n\n",
        min = 1,
        max = 150,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "minorLimit", table = config}
    }

    local settings2 = page:createCategory("Misc Skills")

    settings2:createOnOffButton({
        label = "Enable Misc skill limit",
        description = "Turns on/off a limit for training Misc skills.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "limitMisc", table = config}
    })

    settings2:createSlider{
        label = "Training limit for Misc skills.",
        description = "Sets the limit on training your Misc skills.\n\nNo effect if above button is OFF.\n\nDefault: 100\n\n",
        min = 1,
        max = 150,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{id = "miscLimit", table = config}
    }

    local settings3 = page:createCategory("Hotkey to open menu")

    settings3:createKeyBinder{
        label = "You will need to restart the game for the changes to apply.",
        description = "Changes the keys to open the training menu\n\nDefault: Right Control\n\n",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{id = "keyBind", table = config, defaultSetting = {keyCode = tes3.scanCode.rCtrl, isShiftDown = false, isAltDown = false, isControlDown = false}}
    }

    local settings4 = page:createCategory("Training Time")

    settings4:createOnOffButton({
        label = "Enables the passing of time while training",
        description = "Turns on/off time passing when training a skill.\n\nTime passed is 2 hours, the same as normal game.\n\nDefault: On\n\n",
        variable = mwse.mcm.createTableVariable {id = "advTime", table = config}
    })
end

event.register("modConfigReady", registerConfig)

local function onInitialized()

    event.register("keyDown", trainingMenu, {filter = config.keyBind.keyCode})
    --event.register("equipped", onEquip)
end

event.register("initialized", onInitialized)