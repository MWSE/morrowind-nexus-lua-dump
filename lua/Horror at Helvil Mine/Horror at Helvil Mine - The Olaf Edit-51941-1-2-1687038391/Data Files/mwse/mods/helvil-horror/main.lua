-- Variables
local mineDataDefault = {
    cofferBalance = 0,
    days = 0,
    previousDay = {
        theftAmount = 0,
        grossIncome = 0,
        netIncome = 0,
        expenses = 0,
        miningOutput = 0
    },
    base = {
        eggPrice = 2,
        salary = 10,
        theftChance = 50
    },
    upgrades = {
        ashStatues = false,
        rails = false,
        laboratory = false,
        pheromones = false,
        ebonyChitin = false,
        steroids = false,
        cloning = false,
        pickaxes = {
            level = 1,
            levelNames = {
                "Chitin",
                "Iron",
                "Steel",
                "Ebony"
            },
            levelCosts = {0, 500, 5000, 50000}
        }
    },
    employees = {
        miners = {
            miner1 = {
                id = 'Miner 1',
                hired = false,
                trainingLevel = 1
            },
            miner2 = {
                id = 'Miner 2',
                hired = false,
                trainingLevel = 1
            },
            miner3 = {
                id = 'Miner 3',
                hired = false,
                trainingLevel = 1
            },
            miner4 = {
                id = 'Miner 4',
                hired = false,
                trainingLevel = 1
            },
            miner5 = {
                id = 'Miner 5',
                hired = false,
                trainingLevel = 1
            },
        },
        guards = {
            guard1 = {
                id = 'Helvil Mine Guard 1',
                hired = false,
                trainingLevel = 1
            },
            guard2 = {
                id = 'Helvil Mine Guard 2',
                hired = false,
                trainingLevel = 1
            },
            guard3 = {
                id = 'Helvil Mine Guard 3',
                hired = false,
                trainingLevel = 1
            },
            guard4 = {
                id = 'Helvil Mine Guard 4',
                hired = false,
                trainingLevel = 1
            },
        },
        foreman = {
            trainingLevel = 1,
            id = 'HH_Foreman'
        },
        total = 1
    }
}

-- Crafting framework
local craftingFramework = include("CraftingFramework")
if not craftingFramework then return end

-- Functions
local function checkMineOwned()
    if tes3.getJournalIndex({id = 'TDM_KWAMA_1'}) == 5 then
        mwse.log("===HH: Mine is now owned by player")
        return true
    else
        mwse.log("===HH: Mine not yet owned by player")
        return false
    end
end

local function refreshCofferInventory()
    mwse.log("===HH: Refreshing coffer gold")
    local count = tes3.player.data.helvilMine.mineData.cofferBalance - tes3.getItemCount({reference = "HH_Coffer", item = "Gold_001"})
    if count == 0 then return end
    if count > 0 then
        tes3.addItem({
            reference = tes3.getReference("HH_Coffer"),
            item = 'Gold_001',
            count = count
        })
    else
        tes3.removeItem({
            reference = tes3.getReference("HH_Coffer"),
            item = 'Gold_001',
            count = count
        })
    end
    
    mwse.log("===HH: Added "..tes3.player.data.helvilMine.mineData.cofferBalance.." gold to the coffers.")
end

local function checkPurchase(amount)
    mwse.log("===HH: Attempting a purchase for "..amount.." with "..tes3.player.data.helvilMine.mineData.cofferBalance.." in coffers")
    if amount > tes3.player.data.helvilMine.mineData.cofferBalance then
        mwse.log("===HH: Not enough to purchase!")
        tes3.messageBox({
            message = "Your mine coffers do not have enough gold!"
        })
        return false
    else
        tes3.player.data.helvilMine.mineData.cofferBalance = tes3.player.data.helvilMine.mineData.cofferBalance - amount
        mwse.log("===HH: Successful purchase! Remaining balance: "..tes3.player.data.helvilMine.mineData.cofferBalance)
        refreshCofferInventory()
        return true
    end
end

local function calcMiningOutput()
    mwse.log("===HH: Calculating Mining Output")
    local totalOutput = 0
    for i=1,5 do
        local currentMiner = tes3.player.data.helvilMine.mineData.employees.miners["miner"..i]
        if currentMiner.hired then
            mwse.log("===HH:   Miner "..i)
            local miningSpeed = 6 - currentMiner.trainingLevel
            if tes3.player.data.helvilMine.mineData.upgrades.ashStatues then miningSpeed = miningSpeed - 1 end
            mwse.log("===HH:     Mining Speed: "..miningSpeed)
            local miningOutput = (5 * currentMiner.trainingLevel) + (5 * (tes3.player.data.helvilMine.mineData.upgrades.pickaxes.level + 1))
            mwse.log("===HH:     Mining Output: "..miningOutput)
            totalOutput = totalOutput + math.floor(8/miningSpeed) * miningOutput
        end
    end
    if tes3.player.data.helvilMine.mineData.upgrades.rails then totalOutput = totalOutput + 200 end
    if tes3.player.data.helvilMine.mineData.upgrades.pheromones then totalOutput = totalOutput * 2 end
    if tes3.player.data.helvilMine.mineData.upgrades.cloning then totalOutput = totalOutput * 2 end
    mwse.log("===HH: Total output egg for today: "..totalOutput)
    return totalOutput
end

local function calcExpenses()
    local expenses = tes3.player.data.helvilMine.mineData.employees.total * tes3.player.data.helvilMine.mineData.base.salary
    mwse.log("===HH: Calculating Expenses: "..expenses)
    return expenses
end

local function calcProfits()
    local miningOutput = calcMiningOutput()
    local expenses = calcExpenses()
    local profit = (miningOutput * tes3.player.data.helvilMine.mineData.base.eggPrice) - expenses
    mwse.log("===HH: Calculating Profits: "..profit)
    return profit
end

local function calcTheftChance()
    mwse.log("===HH: Calculating Theft Chance")
    local theftChance = tes3.player.data.helvilMine.mineData.base.theftChance
    mwse.log("===HH:     Base: "..theftChance)
    for i = 1, 4, 1 do
        local currentGuard = tes3.player.data.helvilMine.mineData.employees.guards['guard'..i]
        if currentGuard.hired then
            theftChance = theftChance - (currentGuard.trainingLevel*2)
            mwse.log("===HH:     Guard "..i..": -"..currentGuard.trainingLevel*2)
        end
    end
    if tes3.player.data.helvilMine.mineData.upgrades.ebonyChitin then theftChance = theftChance - 15 end
    mwse.log("===HH:   Total theft chance: "..theftChance)
    return theftChance
end

local function checkHire()
    local hirableIDs = {
        guards = {
            "Guard1hh",
            "Guard2hh",
            'Guard3hh',
            'Guard4hh'
        },
        miners = {
            'Miner1hh',
            'Miner2hh',
            'Miner3hh',
            'Miner4hh',
            'Miner5hh'
        }
    }
    for key, value in ipairs(hirableIDs.guards) do
        if tes3.getGlobal(value) == 1 and not tes3.player.data.helvilMine.mineData.employees.guards["guard"..key].hired then
            mwse.log("===HH: Hired Guard "..key)
            tes3.player.data.helvilMine.mineData.employees.guards["guard"..key].hired = true
            tes3.player.data.helvilMine.mineData.employees.total = tes3.player.data.helvilMine.mineData.employees.total + 1
            tes3.getReference("Helvil Mine Guard "..key.." Hir"):enable()
        end
    end
    for key, value in ipairs(hirableIDs.miners) do
        if tes3.getGlobal(value) == 1 and not tes3.player.data.helvilMine.mineData.employees.miners["miner"..key].hired then
            mwse.log("===HH: Hired Miner "..key)
            tes3.player.data.helvilMine.mineData.employees.miners["miner"..key].hired = true
            tes3.player.data.helvilMine.mineData.employees.total = tes3.player.data.helvilMine.mineData.employees.total + 1
            tes3.getReference("Miner "..key.."Hired"):enable()
        end
    end
end

local function dailyUpdate() -- Function to update data and progress day
    mwse.log("===HH: Running Daily Update")
    tes3.player.data.helvilMine.mineData.days = tes3.player.data.helvilMine.mineData.days + 1
    checkHire()
    local netIncome = calcProfits()
    local theftAmount
    if (math.floor((math.random() * 100)+1) < calcTheftChance()) then
        theftAmount = (math.floor(math.random() * (calcMiningOutput()/2)+1))*tes3.player.data.helvilMine.mineData.base.eggPrice
        netIncome = netIncome - theftAmount
    end
    tes3.player.data.helvilMine.mineData.cofferBalance = tes3.player.data.helvilMine.mineData.cofferBalance + netIncome
    refreshCofferInventory()
    local theftText
    if theftAmount then
        theftText = theftAmount.." eggs were stolen by poachers."
    else
        theftText = "The guards managed to fend off the poachers!"
    end
    tes3.messageBox("Helvil Mine reports a daily income of "..netIncome..". "..theftText)
end

local function employeeMenu(job,index)
    mwse.log("===HH: Opening Employee menu")
    if index == nil or index == 0 then index = 1 end
    local messageBoxContent

    if job == 'foreman' then
        local currentEmployee = tes3.player.data.helvilMine.mineData.employees.foreman
        messageBoxContent = {
            message = "Foreman\n\nName: "..tes3.getReference(currentEmployee.id).object.name..
                      "\nLevel: "..currentEmployee.trainingLevel..
                      "\nSalary: "..tes3.player.data.helvilMine.mineData.base.salary,
            buttons = {
                "Train \n("..(currentEmployee.trainingLevel*1000).."gp)",
                "Close"
            },
            callback = function (e)
                if e.button == 0 then
                    if currentEmployee.trainingLevel == 4 then
                        tes3.messageBox("You cannot train employees past Level 5.")
                        return
                    end
                    if checkPurchase(currentEmployee.trainingLevel*1000) then
                        currentEmployee.trainingLevel = currentEmployee.trainingLevel+1
                        tes3.messageBox("You have trained "..tes3.getReference(currentEmployee.id).object.name.." to Level "..currentEmployee.trainingLevel)
                    end
                end
            end
        }
    elseif job == 'miners' then
        if index == 6 then index = 5 end
        local currentEmployee = tes3.player.data.helvilMine.mineData.employees.miners["miner"..index]
        if currentEmployee.hired then
            messageBoxContent = {
                message = "Miner "..index.."\n\nName: "..tes3.getReference(currentEmployee.id).object.name..
                        "\nLevel: "..currentEmployee.trainingLevel..
                        "\nSalary: "..tes3.player.data.helvilMine.mineData.base.salary,
                buttons = {
                    "Previous",
                    "Train \n("..(currentEmployee.trainingLevel*1000).."gp)",
                    "Next",
                    "Close"
                },
                callback = function (e)
                    if e.button == 3 then return end
                    if e.button == 0 then
                        employeeMenu('miners',index-1)
                    elseif e.button == 1 then
                        if currentEmployee.trainingLevel == 4 then
                            tes3.messageBox("You cannot train employees past Level 5.")
                            return
                        end
                        if checkPurchase(currentEmployee.trainingLevel*1000) then
                            currentEmployee.trainingLevel = currentEmployee.trainingLevel+1
                            tes3.messageBox("You have trained "..tes3.getReference(currentEmployee.id).object.name.." to Level "..currentEmployee.trainingLevel)
                        end
                    elseif e.button == 2 then
                        employeeMenu('miners',index+1)
                    end
                end
            }
        else
            messageBoxContent = {
                message = "Miner "..index.." has not been hired.",
                buttons = {
                    "Previous",
                    "Next",
                    "Close"
                },
                callback = function (e)
                    if e.button == 2 then return end
                    if e.button == 0 then
                        employeeMenu('miners',index-1)
                    elseif e.button == 1 then
                        employeeMenu('miners',index+1)
                    end
                end
            }
        end
    elseif job == 'guards' then
        if index == 5 then index = 4 end
        local currentEmployee = tes3.player.data.helvilMine.mineData.employees.guards["guard"..index]
        if currentEmployee.hired then
            messageBoxContent = {
                message = "Guard "..index.."\n\nName: "..tes3.getReference(currentEmployee.id).object.name..
                        "\nLevel: "..currentEmployee.trainingLevel..
                        "\nSalary: "..tes3.player.data.helvilMine.mineData.base.salary,
                buttons = {
                    "Previous",
                    "Train \n("..(currentEmployee.trainingLevel*1000).."gp)",
                    "Next",
                    "Close"
                },
                callback = function (e)
                    if e.button == 3 then return end
                    if e.button == 0 then
                        employeeMenu('guards',index-1)
                    elseif e.button == 1 then
                        if currentEmployee.trainingLevel == 4 then
                            tes3.messageBox("You cannot train employees past Level 5.")
                            return
                        end
                        if checkPurchase(currentEmployee.trainingLevel*1000) then
                            currentEmployee.trainingLevel = currentEmployee.trainingLevel+1
                            tes3.messageBox("You have trained "..tes3.getReference(currentEmployee.id).object.name.." to Level "..currentEmployee.trainingLevel)
                        end
                    elseif e.button == 2 then
                        employeeMenu('guards',index+1)
                    end
                end
            }
        else
            messageBoxContent = {
                message = "Guard "..index.." has not been hired.",
                buttons = {
                    "Previous",
                    "Next",
                    "Close"
                },
                callback = function (e)
                    if e.button == 2 then return end
                    if e.button == 0 then
                        employeeMenu('guards',index-1)
                    elseif e.button == 1 then
                        employeeMenu('guards',index+1)
                    end
                end
            }
        end
    end

    tes3.messageBox(messageBoxContent)
end

local function ledgerMenu()
    local railStatus
    local labStatus
    mwse.log("------------Init---------------")
    if tes3.player.data.helvilMine.mineData.upgrades.rails then
        railStatus = "Operational"
    else
        railStatus = "Out of order ("..tes3.player.data.helvilMine.debrisRemaining.." debris remaining)"
    end

    if tes3.player.data.helvilMine.mineData.upgrades.laboratory then
        labStatus = "Activated"
    else
        labStatus = "Out of order (50000gp to repair)"
    end

    tes3.messageBox({
        message =   "Helvil Mine Ledger\n\n"..
                    "Egg Output: "..calcMiningOutput().."/day\n"..
                    "Egg Price: "..tes3.player.data.helvilMine.mineData.base.eggPrice..
                    "\nExpenses: "..calcExpenses().."/day\n"..
                    "Projected Income: "..calcProfits().."/day\n"..
                    "Theft Chance: %"..calcTheftChance().."/day\n"..
                    "Days Operational: "..tes3.player.data.helvilMine.mineData.days..
                    "\nCoffer Gold: "..tes3.player.data.helvilMine.mineData.cofferBalance..
                    "\nRail Status: "..railStatus..
                    "\nLaboratory Status: "..labStatus,
        buttons = {
            "Employees",
            "Pickaxes",
            "Close"
        },
        callback = function (e)
            if e.button == 0 then
                tes3.messageBox({
                    message = "Please select an employee:",
                    buttons = {
                        "Foreman",
                        "Miners",
                        "Guards",
                        "Close"
                    },
                    callback = function (e)
                        if e.button == 0 then
                            employeeMenu("foreman")
                        elseif e.button == 1 then
                            employeeMenu("miners")
                        elseif e.button == 2 then
                            employeeMenu("guards")
                        end
                    end
                })
            elseif e.button == 1 then
                local pickLevel = tes3.player.data.helvilMine.mineData.upgrades.pickaxes.level
                if pickLevel == 4 then
                    tes3.messageBox({
                        message = "Current Pickaxe Quality: "..tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelNames[pickLevel].."(MAX)",
                        buttons = {"OK"}
                    })
                    return
                end
                tes3.messageBox({
                    message = "Current Pickaxe Quality: "..tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelNames[pickLevel]..
                              "\nNext level: "..tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelNames[pickLevel+1]..
                              " ("..tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelCosts[pickLevel+1].."gp)",
                    buttons = {"Upgrade","Close"},
                    callback = function (e)
                        if e.button == 1 then return end
                        if tes3.player.data.helvilMine.mineData.upgrades.pickaxes.level == 4 then
                            tes3.messageBox("Your pickaxes are fully upgraded!")
                            return
                        end
                        if tes3.player.data.helvilMine.mineData.employees.foreman.trainingLevel < 2 then
                            tes3.messageBox("Only mines with a level 2 Foreman can upgrade pickaxes!")
                            return
                        end
                        local nextPickLevel = tes3.player.data.helvilMine.mineData.upgrades.pickaxes.level+1
                        tes3.messageBox({
                            message = "Upgrade pickaxes to " .. tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelNames[nextPickLevel] .. " for " .. tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelCosts[nextPickLevel] .. "gp? Upgraded pickaxes increase mining output.",
                            buttons = {'Yes','No'},
                            callback = function (e2)
                                if e2.button == 0 and checkPurchase(tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelCosts[nextPickLevel]) then
                                    tes3.player.data.helvilMine.mineData.upgrades.pickaxes.level = tes3.player.data.helvilMine.mineData.upgrades.pickaxes.level + 1
                                    tes3ui.getMenuOnTop():destroy()
                                    tes3ui.leaveMenuMode()
                                    tes3.messageBox("Pickaxes upgraded to "..tes3.player.data.helvilMine.mineData.upgrades.pickaxes.levelNames[nextPickLevel])
                                end
                            end
                        })
                    end

                })
            end
        end
    })
end

local function onCofferActivate(e)
    if tes3.player.data.helvilMine == nil then return end
    if tes3.player.data.helvilMine.cofferActivateDoOnce then
        tes3ui.leaveMenuMode()
        tes3.messageBox({
            message = "This is your mine's coffer! Any expenses for the mine will be paid from here. Be sure to keep it topped up with gold if you aren't quite making a profit yet, otherwise your employees will not be paid. They will only tolerate this for so long before taking your mine... by force if needed.",
            buttons = {"OK"}
        })
        tes3.player.data.helvilMine.cofferActivateDoOnce = false
    end
end

local function railRepairMenu(e)
    if checkMineOwned() == false then return end
    if tes3.player.data.helvilMine.mineData.employees.foreman.trainingLevel < 3 then
        tes3.messageBox({message = "You need a Level 3 Foreman to repair the rails. Current Foreman level: " .. tostring(tes3.player.data.helvilMine.mineData.employees.foreman.trainingLevel)}) end
    tes3.messageBox({
        message = "Remove debris for 2000gp? Working rails can increase your egg output by 200 eggs a day! Remove all debris to repair the rails\nCurrent balance in Mine Coffers: "..tostring(tes3.player.data.helvilMine.mineData.cofferBalance),
        buttons = {'Yes','No'},
        callback = function (e2)
            if e2.button == 0 then
                if checkPurchase(2000) then
                    e.target:disable()
                    tes3.player.data.helvilMine.debrisRemaining = tes3.player.data.helvilMine.debrisRemaining - 1
                    if tes3.player.data.helvilMine.debrisRemaining == 0 then
                        tes3.messageBox({
                            message = "You have removed all of the debris on Helvil Mine's rail system! Egg ouput increased by 200 eggs/day.",
                            buttons = {"OK"}
                        })
                        tes3.player.data.helvilMine.mineData.upgrades.rails = true
                    end
                end
            end
        end
    })
end

local corprusMaterial = {
    {
        id = "corprus",
        name = "Corprus Meat",
        ids = {
            "ingred_6th_corprusmeat_01",
            "ingred_6th_corprusmeat_02",
            "ingred_6th_corprusmeat_03",
            "ingred_6th_corprusmeat_04",
            "ingred_6th_corprusmeat_05",
            "ingred_6th_corprusmeat_06",
            "ingred_6th_corprusmeat_07"
        }
    }
}

craftingFramework.Material:registerMaterials(corprusMaterial)

local CFRecipes = {
    {
        id = "helvilMine:pheromonesRecipe",
        name = "Pheromone Treatment",
        craftableId = "AB_IngFood_KwamaEggSpoilSmall",
        materials = {
            {
                material = "ingred_kwama_cuttle_01",
                count = 20
            },
            {
                material = "potion_t_bug_musk_01",
                count = 5
            }
        },
        category = "Experiments",
        craftCallback = function ()
            craftingFramework.Recipe.getRecipe("helvilMine:pheromonesRecipe"):unlearn()
            tes3ui.getMenuOnTop():destroy()
            tes3ui.leaveMenuMode()
            tes3.messageBox({
                message = "As you drop the cuttle into a cauldron of Telvanni Bug Musk distillate, a massive, orange cloud erupts. The cloud quickly dissipates into mist, but the air in the mine seems to be a bit thicker... You'll just have to wait and see what happens.",
                buttons = {"OK"}
            })
            timer.register("helvilMine:PheroTimer",function ()
                tes3.messageBox({
                    message = "A courier delivers a message from the Helvil Mine Foreman. Ever since that mist was released into the mine, the queen has laid twice as many eggs a day! Perhaps you should try more of those experiments...",
                    buttons = {"OK"}
                })
                tes3.player.data.helvilMine.mineData.upgrades.pheromones = true
            end)
            timer.start({
                type = timer.game,
                duration = 24,
                persist = true,
                callback = "helvilMine:PheroTimer"
            })
        end
    },
    {
        id = "helvilMine:ebonyChitinRecipe",
        craftableId = "AB_IngFood_KwamaEggSpoilSmall",
        name = "Ebony-infused Chitin",
        materials = {
            {
                material = "ingred_raw_ebony_01",
                count = 65
            },
            {
                material = "chitin cuirass",
                count = 4
            }
        },
        category = "Experiments",
        craftCallback = function ()
            craftingFramework.Recipe.getRecipe("helvilMine:ebonyChitinRecipe"):unlearn()
            tes3ui.getMenuOnTop():destroy()
            tes3ui.leaveMenuMode()
            tes3.messageBox({
                message = "You find a strange soul gem, unlike any you've ever seen. You swear you hear distant screaming when you put it up to your ear; but not from the soul gem. Suddenly you realize this is the key to the Ebony Chitin you learned about from the Laboratory. You use the soul gem to bind some ebony to a chitin chestpiece, but the combination crumbles to dust. However, you notice the kwama look a bit darker, shinier... tougher. Egg poachers will have one hell of a time raiding this mine.",
                buttons = {"OK"}
            })
            tes3.player.data.helvilMine.mineData.upgrades.ebonyChitin = true
        end
    },
    {
        id = "helvilMine:corpusSteroidsRecipe",
        craftableId = "AB_IngFood_KwamaEggSpoilSmall",
        name = "Corprus Steroids",
        materials = {
            {
                material = "corprus",
                count = 8
            },
            {
                material = "potion_local_liquor_01",
                count = 40
            }
        },
        category = "Experiments",
        craftCallback = function ()
            craftingFramework.Recipe.getRecipe("helvilMine:corpusSteroidsRecipe"):unlearn()
            tes3ui.getMenuOnTop():destroy()
            tes3ui.leaveMenuMode()
            tes3.messageBox({
                message = "You drop chunks of corprus infested meat into the bubbling sujamma, stirring as you go. As if it had a mind of its own, the cauldron leaps into the air, spilling onto the floor. Before you can curse, the spilled concoction assumes a blobby form, wandering down to the queen's chamber and dissolving into the water. The queen takes a deep sip and lays another egg with a shudder. You cannot believe your eyes. This egg is twice the size of the others! She lays another, same size. You know these eggs are going to sell for double!",
                buttons = {"OK"}
            })
            tes3.player.data.helvilMine.mineData.upgrades.steroids = true
        end
    },
    {
        id = "helvilMine:ashStatueRecipe",
        craftableId = "AB_IngFood_KwamaEggSpoilSmall",
        name = "Ash Statue Therpay",
        materials = {
            {
                material = "misc_6th_ash_statue_01",
                count = 1
            }
        },
        category = "Experiments",
        skillRequirements = {
            {
                skill = "illusion",
                requirement = 75
            }
        },
        craftCallback = function ()
            craftingFramework.Recipe.getRecipe("helvilMine:ashStatueRecipe"):unlearn()
            tes3ui.getMenuOnTop():destroy()
            tes3ui.leaveMenuMode()

            tes3.messageBox({
                message = "You enchant the ash statue with a rune you found lying on the bottom of one of the cauldrons. Immediately, the miners in your mine begin working with increased vigor, collecting even more of the unborn kwama to fuel your growing egg empire.",
                buttons = {"OK"}
            })
            tes3.player.data.helvilMine.mineData.upgrades.ashStatues = true
        end
    },
    {
        id = "helvilMine:cloningRecipe",
        craftableId = "AB_IngFood_KwamaEggSpoilSmall",
        name = "Clone Queen",
        materials = {
            {
                material = "food_kwama_egg_02",
                count = 1
            }
        },
        category = "Experiments",
        skillRequirements = {
            {
                skill = "conjuration",
                requirement = 100
            }
        },
        craftCallback = function ()
            craftingFramework.Recipe.getRecipe("helvilMine:cloningRecipe"):unlearn()
            tes3ui.getMenuOnTop():destroy()
            tes3ui.leaveMenuMode()
            tes3.messageBox({
                message = "You cast a Conjuration incantation you found inscribed under the Laboratory bench on a large Kwama egg. The egg rolls off the table, and bounces towards the queen's chambers. As it lands next to the Queen, a crack appears, and out comes a tiny Queen, growing at an egregious rate.",
                buttons = {"OK"}
            })
            tes3.player.data.helvilMine.mineData.upgrades.cloning = true
            tes3.setGlobal("RingIsAcutiePieLilGuy", 1)
        end
    }
}

craftingFramework.MenuActivator:new{
    id = "Activate_HH_LaboratoryTable",
    type = "event",
    recipes = CFRecipes
}

local function labmenu()
    if tes3.player.data.helvilMine.mineData.upgrades.laboratory then
        event.trigger("Activate_HH_LaboratoryTable")
    else
        tes3.messageBox({
            message = "Activate Laboratory for 50000gp?",
            buttons = {"Yes","No"},
            callback = function (e)
                if checkPurchase(50000) then
                    tes3.messageBox({
                        message = "The table begins to emit an ancient, evil aura. A shudder runs down your spine as several odd experiment recipes spring to mind.\n\nActivate the table again to start experimenting.",
                        buttons = {"OK"}
                    })
                    tes3.player.data.helvilMine.mineData.upgrades.laboratory = true
                end
            end
        })
    end
end

local function activationController(e)
    if e.target.id == "HH_Ledger" then
        ledgerMenu()
    elseif e.target.id == "HH_Coffer" then
        onCofferActivate(e)
    elseif e.target.id == "HH_RailDebris_01" then
        railRepairMenu(e)
    elseif e.target.id == "HH_LaboratoryTable" then
        labmenu()
    end
end

local function onSimulate(e)
    if tes3.player.data.helvilMine == nil then return end
    if tes3.player.data.helvilMine.refreshTimer == nil then return end
    if tes3.player.data.helvilMine.refreshTimer <= e.timestamp - 24 then
        dailyUpdate()
        tes3.player.data.helvilMine.refreshTimer = e.timestamp
    end
end

local function journalUpdateHandler(e)
    if e.topic.id == "TDM_KWAMA_1" and e.index == 5 then
        mwse.log("Mine activated!")
        tes3.player.data.helvilMine = {}
        tes3.player.data.helvilMine.mineData = mineDataDefault
        tes3.player.data.helvilMine.debrisRemaining = 5
        tes3.player.data.helvilMine.cofferActivateDoOnce = true
        tes3.player.data.helvilMine.refreshTimer = tes3.getSimulationTimestamp()
    end
    if e.topic == 'TDM_Kwama_Sq_7' and e.index == 5 then
        tes3.player.data.helvilMine.mineData.base.eggPrice = tes3.player.data.helvilMine.mineData.base.eggPrice + 2
    end
end

-- Events
event.register(tes3.event.activate, activationController)
event.register(tes3.event.journal, journalUpdateHandler)
event.register(tes3.event.simulate, onSimulate)
event.register(tes3.event.containerClosed, function (e)
    mwse.log("===HH: Refreshing coffer balance")
    local count = tes3.getItemCount({reference = "HH_Coffer", item = "Gold_001"})
    mwse.log("===HH:     Amount:"..count)
    if tes3.player.data.helvilMine == nil then return end
    mwse.log("===HH:     PLAYER DATA ACTIVATED")
    tes3.player.data.helvilMine.mineData.cofferBalance = count
    mwse.log("===HH:     REFRESHED!")
end)