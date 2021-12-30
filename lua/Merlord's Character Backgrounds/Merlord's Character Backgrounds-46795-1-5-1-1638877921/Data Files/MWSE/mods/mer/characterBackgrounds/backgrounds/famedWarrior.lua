local TESTMODE = false
local warriorDoOnce
local warriorInterruptChance = TESTMODE and 0.20
local warriorDoAttack
local currentRival

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

local getData = function()
    local data = tes3.player.data.merBackgrounds or {}
    return data
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
        data.famedWarrior = data.famedWarrior or {
            swordName = "Blood Drinker",
            rivals = {
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
            },
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

        --Name and add Famous Sword
        local menuID = tes3ui.registerID("ChooseWeaponMenu")
        local function chooseSword()
            tes3ui.leaveMenuMode(menuID)
            tes3ui.findMenu(menuID):destroy()
            tes3.messageBox("Your sword has been named %s", data.famedWarrior.swordName)
            local sword = tes3.getObject("mer_bg_famedSword")
            sword.name = data.famedWarrior.swordName
            tes3.addItem{
                reference = tes3.player,
                item = sword
            }
            tes3.mobilePlayer:equip{ item = sword }
        end

        local function showSwordMenuOnChargenFinished()
            if data.currentBackground ~= "famedWarrior" then
                event.unregister("simulate", showSwordMenuOnChargenFinished)
                return
            end
            if tes3.findGlobal("CharGenState").value == -1 then
                event.unregister("simulate", showSwordMenuOnChargenFinished)
                local menu = tes3ui.createMenu{ id = menuID, fixedFrame = true }
                menu.minWidth = 400
                menu.alignX = 0.5
                menu.alignY = 0
                menu.autoHeight = true
                -- menu.widthProportional = 1
                --menu.heightProportional = 1
                mwse.mcm.createTextField(
                    menu,
                    {
                        label = "Enter the name of your sword:",
                        variable = mwse.mcm.createTableVariable{
                            id = "swordName",
                            table = data.famedWarrior
                        },
                        callback = chooseSword
                    }
                )
                tes3ui.enterMenuMode(menuID)
            end
        end
        event.unregister("simulate", showSwordMenuOnChargenFinished)
        event.register("simulate", showSwordMenuOnChargenFinished)
    end,

    callback = function()
        if TESTMODE then
            tes3.messageBox("Character Backgrounds TESTMODE is ON")
        end
        local function setSwordStats()

            local data = getData()
            local enchantment = tes3.getObject(defaultSwordStats.enchantment.id)

            data.rivalsFought = data.rivalsFought or 0
            enchantment.effects[1].min = defaultSwordStats.enchantment.min + data.rivalsFought
            enchantment.effects[1].max = defaultSwordStats.enchantment.max + data.rivalsFought

            local sword = tes3.getObject(defaultSwordStats.sword.id)
            sword.slashMax = defaultSwordStats.sword.slash + data.rivalsFought
            sword.thrustMax = defaultSwordStats.sword.thrust + data.rivalsFought
            sword.chopMax = defaultSwordStats.sword.chop + data.rivalsFought

            sword.slashMin = defaultSwordStats.sword.min + data.rivalsFought
            sword.thrustMin = defaultSwordStats.sword.min + data.rivalsFought
            sword.chopMin = defaultSwordStats.sword.min + data.rivalsFought

            sword.name = data.famedWarrior.swordName
        end
        setSwordStats()

        local function calcRestInterrupt(e)
            local data = getData()
            if data.currentBackground == "famedWarrior" then
                local rand = math.random()
                if rand < warriorInterruptChance then
                    for _, val in ipairs(data.famedWarrior.rivals) do
                        local validRival = (
                            not val.hasFought and
                            ( TESTMODE or tes3.getObject(val.id).level <= tes3.player.object.level )
                        )
                        if validRival then
                            currentRival = val
                            warriorDoAttack = true
                            e.count = 1
                            e.hour = math.random(1, 3)
                            break
                        end
                    end

                end
            end
        end

        local function restInterrupt(e)
            local data = getData()
            if data.currentBackground == "famedWarrior" then
                if warriorDoAttack and currentRival then
                    warriorDoAttack = false
                    currentRival.hasFought = true
                    e.creature = tes3.getObject(currentRival.list)
                end
            end
        end

        local function onDeath(e)
            local data = getData()

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



        if warriorDoOnce then return end
        warriorDoOnce = true

        event.register("calcRestInterrupt", calcRestInterrupt)
        event.register("restInterrupt", restInterrupt)
        event.register("death", onDeath)
    end
}