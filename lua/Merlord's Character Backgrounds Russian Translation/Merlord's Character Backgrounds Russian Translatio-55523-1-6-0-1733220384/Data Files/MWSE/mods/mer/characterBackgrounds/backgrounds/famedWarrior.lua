local interop = require("mer.characterBackgrounds.interop")

local INTERRUPT_CHANCE = 0.5
local DEFAULT_SWORD_STATS = {
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
local RIVALS = {
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

local showSwordMenuOnChargenFinished
local currentRival

local background = interop.addBackground{
    id = "famedWarrior",
    name = "Знаменитый воин",
    description = (
        "На родине вы были известны как могучий воин. " ..
        "Начиная игру, вы получаете 20 репутации, +10 к Длинным клинкам и свой знаменитый меч. " ..
        "Однако известность имеет цену. Многие желают прославиться " ..
        "в качестве воина, одержавшего над вами победу в бою. Вы наверняка встретите своих соперников " ..
        "во время путешествий. С каждым повергнутым соперником сила вашего меча будет возрастать. "
    ),
    defaultData = {
        swordName = "Кровопийца",
        rivals = RIVALS,
        rivalsFought = 0
    },
    doOnce = function()
        --Mod Reputation
        tes3.player.object.reputation = (tes3.player.object.reputation or 0) + 20
        tes3ui.updateStatsPane()
        --Longblade
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.longBlade,
            value = 10
        })
        event.unregister("simulate", showSwordMenuOnChargenFinished)
        event.register("simulate", showSwordMenuOnChargenFinished)
    end,
}
if not background then return end


local setSwordStats = function()
    if not background:isActive() then return end
    local enchantment = tes3.getObject(DEFAULT_SWORD_STATS.enchantment.id)
    background.data.rivalsFought = background.data.rivalsFought or 0
    local rivalDamageEffectMin = background.data.rivalsFought * 2
    local rivalDamageEffectMax = background.data.rivalsFought * 3
    local rivalMagicEffect = background.data.rivalsFought * 1
    enchantment.effects[1].min = DEFAULT_SWORD_STATS.enchantment.min + rivalMagicEffect
    enchantment.effects[1].max = DEFAULT_SWORD_STATS.enchantment.max + rivalMagicEffect
    local sword = tes3.getObject(DEFAULT_SWORD_STATS.sword.id)
    sword.slashMin = DEFAULT_SWORD_STATS.sword.min + rivalDamageEffectMin
    sword.thrustMin = DEFAULT_SWORD_STATS.sword.min + rivalDamageEffectMin
    sword.chopMin = DEFAULT_SWORD_STATS.sword.min + rivalDamageEffectMin
    sword.slashMax = DEFAULT_SWORD_STATS.sword.slash + rivalDamageEffectMax
    sword.thrustMax = DEFAULT_SWORD_STATS.sword.thrust + rivalDamageEffectMax
    sword.chopMax = DEFAULT_SWORD_STATS.sword.chop + rivalDamageEffectMax
    sword.name = background.data.swordName
    sword.modified = true
end


local function isValidRival(rival)
    if background.data.testMode then
        return rival.hasFought ~= true
    end
    return rival.hasFought ~= true
        and tes3.getObject(rival.id).level <= tes3.player.object.level
end


event.register("calcRestInterrupt", function(e)
    if not background:isActive() then return end
    local rand = math.random()
    if background.data.testMode or rand < INTERRUPT_CHANCE then
        for _, rival in ipairs(background.data.rivals) do
            if isValidRival(rival) then
                currentRival = rival
                e.count = 1
                e.hour = math.random(1, 3)
                break
            end
        end
    end
end)

event.register("restInterrupt", function(e)
    if not background:isActive() then return end
    if currentRival and not currentRival.hasFought then
        currentRival.hasFought = true
        e.creature = tes3.getObject(currentRival.list)
    end
end)

event.register("death", function(e)
    if not background:isActive() then return end
    if currentRival and e.reference.object.baseObject.id == currentRival.id then
        local sword = tes3.getObject(DEFAULT_SWORD_STATS.sword.id)
        background.data.rivalsFought = background.data.rivalsFought + 1
        setSwordStats()
        tes3.messageBox({
            message = string.format("%s стал сильнее.", sword.name),
            buttons = { "Готово" }
        })
    end
end)

--Name and add Famous Sword
local function chooseSword()
    tes3ui.leaveMenuMode()
    tes3ui.findMenu("ChooseWeaponMenu"):destroy()
    tes3.messageBox("Ваш меч получил имя %s", background.data.swordName)
    local sword = tes3.getObject("mer_bg_famedSword")
    sword.name = background.data.swordName
    tes3.addItem{
        reference = tes3.player,
        item = sword
    }
    tes3.mobilePlayer:equip{ item = sword }
end

showSwordMenuOnChargenFinished = function()
    if not background:isActive() then
        event.unregister("simulate", showSwordMenuOnChargenFinished)
        return
    end
    if tes3.findGlobal("CharGenState").value == -1 then
        event.unregister("simulate", showSwordMenuOnChargenFinished)
        local menu = tes3ui.createMenu{ id = "ChooseWeaponMenu", fixedFrame = true }
        menu.minWidth = 400
        menu.autoHeight = true
        mwse.mcm.createTextField(
            menu,
            {
                label = "Введите имя своего меча:",
                variable = mwse.mcm.createTableVariable{
                    id = "swordName",
                    table = background.data,
                },
                callback = chooseSword
            }
        )
        tes3ui.enterMenuMode("ChooseWeaponMenu")
    end
end




