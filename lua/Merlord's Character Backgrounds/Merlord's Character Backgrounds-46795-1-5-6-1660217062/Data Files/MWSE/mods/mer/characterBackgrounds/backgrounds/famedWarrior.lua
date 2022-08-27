local warriorDoOnce
local warriorInterruptChance = 0.5

local getData = function()
    return tes3.player.data.merBackgrounds or {}
end

local getFamedWarriorData = function()
    return getData().famedWarrior or {}
end

local function isActive()
    return getData().currentBackground == "famedWarrior"
end

local defaultSwordStats = {
    enchantment = {
        id = "mer_bg_blooddrinker",
        min = 1,
        max = 2
    },
    sword = {
        id = "mer_bg_famedSword",
        min = 2,
        chop = 12,
        slash = 12,
        thrust = 12
    }
}

local rivalsDefaultData = {
    { id = "mer_bg_rival_01", list = "mer_bg_rivalList_01", hasFought = false },
    { id = "mer_bg_rival_02", list = "mer_bg_rivalList_02", hasFought = false },
    { id = "mer_bg_rival_03", list = "mer_bg_rivalList_03", hasFought = false },
    { id = "mer_bg_rival_04", list = "mer_bg_rivalList_04", hasFought = false },
    { id = "mer_bg_rival_05", list = "mer_bg_rivalList_05", hasFought = false },
    { id = "mer_bg_rival_06", list = "mer_bg_rivalList_06", hasFought = false },
    { id = "mer_bg_rival_07", list = "mer_bg_rivalList_07", hasFought = false },
    { id = "mer_bg_rival_08", list = "mer_bg_rivalList_08", hasFought = false },
    { id = "mer_bg_rival_09", list = "mer_bg_rivalList_09", hasFought = false },
    { id = "mer_bg_rival_10", list = "mer_bg_rivalList_10", hasFought = false },
}

local function setSwordStats()
    local data = getFamedWarriorData()
    local enchantment = tes3.getObject(defaultSwordStats.enchantment.id)
    data.rivalsFought = data.rivalsFought or 0
    local rivalDamageEffectMin = data.rivalsFought * 2
    local rivalDamageEffectMax = data.rivalsFought * 3
    local rivalMagicEffect = data.rivalsFought * 1
    enchantment.effects[1].min = defaultSwordStats.enchantment.min + rivalMagicEffect
    enchantment.effects[1].max = defaultSwordStats.enchantment.max + rivalMagicEffect
    local sword = tes3.getObject(defaultSwordStats.sword.id)
    sword.slashMin = defaultSwordStats.sword.min + rivalDamageEffectMin
    sword.thrustMin = defaultSwordStats.sword.min + rivalDamageEffectMin
    sword.chopMin = defaultSwordStats.sword.min + rivalDamageEffectMin
    sword.slashMax = defaultSwordStats.sword.slash + rivalDamageEffectMax
    sword.thrustMax = defaultSwordStats.sword.thrust + rivalDamageEffectMax
    sword.chopMax = defaultSwordStats.sword.chop + rivalDamageEffectMax
    sword.name = data.swordName
    sword.modified = true
end


local function isValidRival(rival)
    if getData().testMode then
        return rival.hasFought ~= true
    end
    return rival.hasFought ~= true
        and tes3.getObject(rival.id).level <= tes3.player.object.level
end

local currentRival
local function calcRestInterrupt(e)
    if isActive() then
        local data = getFamedWarriorData()
        local rand = math.random()
        if getData().testMode or rand < warriorInterruptChance then
            for _, rival in ipairs(data.rivals) do
                if isValidRival(rival) then
                    currentRival = rival
                    e.count = 1
                    e.hour = math.random(1, 3)
                    break
                end
            end
        end
    end
end

local function restInterrupt(e)
    if isActive() then
        if currentRival and not currentRival.hasFought then
            currentRival.hasFought = true
            e.creature = tes3.getObject(currentRival.list)
        end
    end
end

local function onDeath(e)
    local data = getFamedWarriorData()
    if currentRival and e.reference.object.baseObject.id == currentRival.id then
        local sword = tes3.getObject(defaultSwordStats.sword.id)
        data.rivalsFought = data.rivalsFought + 1
        setSwordStats()
        tes3.messageBox({
            message = string.format("%s has grown more powerful.", sword.name),
            buttons = { "Okay" }
        })
    end
end

--Name and add Famous Sword
local function chooseSword()
    local data = getFamedWarriorData()
    tes3ui.leaveMenuMode("ChooseWeaponMenu")
    tes3ui.findMenu("ChooseWeaponMenu"):destroy()
    tes3.messageBox("Your sword has been named %s", data.swordName)
    local sword = tes3.getObject("mer_bg_famedSword")
    sword.name = data.swordName
    tes3.addItem{
        reference = tes3.player,
        item = sword
    }
    tes3.mobilePlayer:equip{ item = sword }
end

local function showSwordMenuOnChargenFinished()
    if tes3.findGlobal("CharGenState").value == -1 then
        event.unregister("simulate", showSwordMenuOnChargenFinished)
        local menu = tes3ui.createMenu{ id = "ChooseWeaponMenu", fixedFrame = true }
        menu.minWidth = 400
        menu.alignX = 0.5
        menu.alignY = 0
        menu.autoHeight = true
        mwse.mcm.createTextField(
            menu,
            {
                label = "Enter the name of your sword:",
                variable = mwse.mcm.createTableVariable{
                    id = "swordName",
                    table = getFamedWarriorData()
                },
                callback = chooseSword
            }
        )
        tes3ui.enterMenuMode("ChooseWeaponMenu")
    end
end

return {
    id = "famedWarrior",
    name = "Famed Warrior",
    description = (
        "Back in your homeland, you had a reputation as a mighty warrior. " ..
        "You start the game with 10 reputation, +10 to Long blade, and your infamous longsword. " ..
        "Renown comes with a price, however. There are many would-be heroes who would stake their claim " ..
        "as the warrior who finally defeated you in battle. As such, you will likely encounter these rivals in " ..
        "your travels. For each rival you defeat, your blade will grow in power. "
    ),
    doOnce = function(data)
        mwse.log("do once famed warrior")
        data.famedWarrior = data.famedWarrior or {
            swordName = "Blood Drinker",
            rivals = rivalsDefaultData,
            rivalsFought = 0
        }
        --Mod Reputation
        tes3.runLegacyScript{
            reference = tes3.player,
            command = "ModReputation 20"
        }
        --Longblade
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade,
            value = 10
        })
        event.unregister("simulate", showSwordMenuOnChargenFinished)
        mwse.log("registering simulate event")
        event.register("simulate", showSwordMenuOnChargenFinished)
    end,

    callback = function()
        setSwordStats()
        if warriorDoOnce then return end
        warriorDoOnce = true

        event.register("calcRestInterrupt", calcRestInterrupt)
        event.register("restInterrupt", restInterrupt)
        event.register("death", onDeath)
    end
}