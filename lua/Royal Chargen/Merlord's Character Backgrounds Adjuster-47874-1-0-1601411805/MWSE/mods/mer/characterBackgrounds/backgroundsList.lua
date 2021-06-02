
local this = {}

local function getConfig()
    return mwse.loadConfig("character_backgrounds") or {}
end

local function saveConfig(newConfig)
    mwse.saveConfig("character_backgrounds", newConfig)
end

--BLACKSMITH
this.blacksmith = {
    id = "blacksmith",
    name = "Apprenticed to a Blacksmith",
    description = (
        "You went to the court blacksmith to learn his skills. You gain a bonus to Strength (+5) " ..
        "and a bonus to your Armorer skill (+15), but you suffer a penalty " ..
        "to Agility (-10) due to the strenuous and repetitive hard labor."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.armorer, 
            value = 15
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 5
        })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -10
        })

    end,
}

--SHOPKEEPER
this.shopKeeper = {
    id = "shopKeeper",
    name = "Shopkeeper",
    description = (
        "By spending a lot of time in your own store, you gain an exceptional " ..
        "bonus to Mercantile (+20), but your shrewd business practices makes you " .. 
        "rather unlikeable (-10 Personality)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.mercantile, 
            value = 20
        })

        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end
}

this.bully = {
    id = "bully", 
    name = "Bully", 
    description = (
        "You are a bully, big and dumb. Extortion and intimidation have afforded you a bonus to Strength (+10), " ..
        "but leaves you with a deficiency in Intelligence (-10). "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence, 
            value = -10
        })
    end
}

this.brute = {
    id = "brute",
    name = "Brute",
    description = (
        "You must have giant's blood in you! You tower over your peers, " ..
        "and have increased Strength (+10), but your massive size makes your rather clumsy (-10 Agility). "
    ),
    doOnce = function()
        tes3.player.scale = tes3.player.scale * 1.05
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = -10
        })
    end
}

this.smallFrame = {
    id = "smallFrame",
    name = "Small Frame",
    description = (
        "You were the runt of the litter. This makes you rather " ..
        "weak (-10 Strength), but your small stature does make you harder to hit (+10 Agility). "
    ),
    doOnce = function()
        tes3.player.scale = tes3.player.scale * 0.95
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength, 
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.agility, 
            value = 10
        })
    end
}

this.inheritance = {
    id = "inheritance",
    name = "Inheritance",
    description = function()
        return string.format(
            "You have inherited a lot of money (+%s gold). The easy life has cost you a penalty to Willpower (-10).", 
            getConfig().inheritanceAmount
        )
    end,
    doOnce = function()
        --debuff willpower
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower, 
            value = -10
        })
        --Add gold
        local amount = tonumber(getConfig().inheritanceAmount)

        --[[mwscript.addItem{
            reference = tes3.player,
            item = "Gold_100",
            count = getConfig().inheritanceAmount
        }]]--

        mwscript.addItem{
            reference = tes3.player,
            item = "Gold_001",
            count = amount
        }
        tes3.playSound{ sound = "Item Gold Up" }
    end
}


this.hyperactive = {
    id = "hyperactive",
    name = "Hyperactive",
    description = (
        "You are constantly busy. Your Speed is higher than normal (+10), but most " ..
        "people find you annoying, and your Personality suffers (-10). "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.speed, 
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -10
        })
    end
}

this.nightMage = {
    id = "nightMage",
    name = "Night Mage",
    description = ( 
        "You were born with a magickal aptitude that has affinity for the night. " ..
        "At night (between the hours of 6 PM and 6 AM), you possess a 20% bonus to your Intelligence, " ..
        "but during the day you suffer a 20% penalty to your Intelligence."
    ),
    callback = function()

        local function getData()
            local data = tes3.player.data.merBackgrounds
            data.nightMage = data.nightMage or {}
            return data
        end

        local function nightMageCheckTime()
            if tes3.menuMode() then return end

            local data = getData()
            if not data.currentBackground == "nightMage" then return end

            local hour = tes3.worldController.hour.value
            local pINT = tes3.mobilePlayer.intelligence
            
            if hour >= 18 or hour < 6 then
                if data.nightMage.nightBuff ~= true then
                    data.nightMage.nightActive = true


                    --Remove debuff
                    if data.nightMage.multiplier then
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.intelligence, 
                            value = -(data.nightMage.multiplier)
                        })
                    end

                    --add buff
                    data.nightMage.multiplier = pINT.base * 0.2
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.intelligence, 
                        value = data.nightMage.multiplier
                    })
                end
            else
                if data.nightMage.nightActive ~= false then

                    data.nightMage.nightActive = false

                    --Remove buff
                    
                    if data.nightMage.multiplier then
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.intelligence, 
                            value = -(data.nightMage.multiplier)
                        })
                    end
                    
                    --add debuff
                    data.nightMage.multiplier = -(pINT.base * 0.2)
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.intelligence, 
                        value = data.nightMage.multiplier
                    })
                end
            end
        end
        timer.start{type = timer.real, iterations = -1, duration = 1, callback = nightMageCheckTime }
    end
}

local fencerDoOnce
this.fencer = {
    id = "fencer",
    name = "Fencing Master",
    description = ( 
        "You have dedicated your life to the art of fencing. " ..
        "When wielding a one-handed long blade with nothing in your off-hand, " ..
        "your Long Blade skill increases by 20 points."
    ),

    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds
            data.fencer = data.fencer or {
                offhandEquipped = false,
                swordEquipped = false,
                buffed = false
            }
            return data
        end
        --Register once per gameLoad


        local function updateFencing()
            local data = getData()
            local isFencing = (
                data.fencer.swordEquipped and
                not data.fencer.offHandEquipped
            )

            if isFencing then
                if not data.fencer.buffed then
                    data.fencer.buffed = true
                    tes3.modStatistic({
                        reference = tes3.player,
                        skill = tes3.skill.longBlade, 
                        value = 20
                    })
                end
            else
                if data.fencer.buffed then
                    data.fencer.buffed = false
                    tes3.modStatistic({
                        reference = tes3.player,
                        skill = tes3.skill.longBlade, 
                        value = -20
                    })
                end
            end
        end

        local function onEquip(e)
            local data = getData()
            if data.currentBackground == "fencer" then
                timer.delayOneFrame( 
                    function()
                        if e.item.objectType == tes3.objectType.weapon then
                            data.fencer.swordEquipped = ( e.item.type == tes3.weaponType.longBladeOneHand )
                        end

                        local function isOffhand(item)
                            return (
                                item.slot == tes3.armorSlot.shield or
                                item.objectType == tes3.objectType.light
                            )
                        end
                        if isOffhand(e.item) then
                            data.fencer.offHandEquipped = true
                        end
                        updateFencing()
                    end,
                    timer.real
                )
            end
        end
        
        local function onUnequip(e)
            local data = getData()
            if data.currentBackground == "fencer" then

                if e.item.objectType == tes3.objectType.weapon then
                    data.fencer.swordEquipped = false
                end

                local function isOffhand(item)
                    return (
                        item.slot == tes3.armorSlot.shield or
                        item.objectType == tes3.objectType.light
                    )
                end
                if isOffhand(e.item) then
                    data.fencer.offHandEquipped = false
                end
                updateFencing()
            end
        end
       
        local equippedItem = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
        if equippedItem then
            onEquip({ item = equippedItem.object })
        end

        if fencerDoOnce == true then return end
        fencerDoOnce = true

        event.register("equip", onEquip)
        event.register("unequipped", onUnequip)
    end
}

local ratKingDoOnce
this.ratKing = {
    id = "ratKing",
    name = "Rat King",
    description = (
        "Discarded in the Mournhold sewers as an infant, you were raised by rats before you were found and brought to the palace. " ..
        "You now have an affinity for the furry beasts, and any you encounter will follow " ..
        "you wherever you go. Additionally, when fighting in the " ..
        "wilderness, a horde of rats may be summoned to aid you in battle (max once per day). " ..
        "Your time spent in close proximity with your rodent friends has given you a " ..
        "potent odor (-20 Personality)"
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality, 
            value = -20
        })
    end,
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.ratKing = data.ratKing or {
                lastSummonHour = 0
            }
            return data
        end

        local function calmRat(ref)
            local id = string.lower(ref.object.id)
            if string.sub(id, 1, 3) == "rat" then
                local objType
                if (ref.object.isInstance) then
                    objType = ref.object.baseObject.objectType
                else
                    objType = ref.object.objectType
                end
                if objType == tes3.objectType.creature then
                    --Calm straight away
                    ref.mobile.fight = 0
                    --Follow when it gets close
                    if ref.position:distance(tes3.player.position) < 600 then
                        if not ref.data.ratFollower then
                            ref.data.ratFollower = true
                            tes3.setAIFollow{ reference = ref, target = tes3.player}
                        end
                    end
                end
            end
        end

        local function mobileActivated(e)
            local data = getData()
            if data.currentBackground == "ratKing" then
                calmRat(e.reference)
            end
        end

        local function checkForRats()
            local data = getData()
            if data.currentBackground == "ratKing" then
                for _, cell in pairs( tes3.getActiveCells() ) do
                    for creature in cell:iterateReferences(tes3.objectType.creature) do
                        calmRat(creature)
                    end
                end
            end
        end

        local function combatStarted(e)
            local data = getData()
            if data.currentBackground == "ratKing" then
                --Rats only summoned in the wilderness
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal or cell.isInterior then return end

                --avoid infinite loops
                local isRat = (
                    string.sub(string.lower(e.target.object.id), 1, 3) == "rat" or
                    string.sub(string.lower(e.actor.object.id), 1, 3) == "rat"
                )
                if isRat then
                    return
                end

                local currentHours = ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value

                data.ratKing.lastSummonHour = data.ratKing.lastSummonHour or 0
                if currentHours >= ( data.ratKing.lastSummonHour + getConfig().ratKingInterval ) then
                    if math.random() < ( getConfig().ratKingChance / 100 ) then
                        tes3.messageBox("A horde of rats comes to your aid!")
                        local ratCount = math.random(3, 5)
                        local command = string.format("PlaceAtPC rat %d 100 1", ratCount)
                        tes3.runLegacyScript{ command = command }
                        data.ratKing.lastSummonHour = currentHours
                    end
                end
            end
        end

        checkForRats()
        timer.start{
            type = timer.simulate, 
            duration = 0.5,
            iterations = -1,
            callback = checkForRats
        }
        if ratKingDoOnce then return end

        ratKingDoOnce = true
        --event.register("cellChanged", cellChanged)
        event.register("mobileActivated", mobileActivated)
        event.register("combatStarted", combatStarted)
    end
}

local artificerDoOnce
this.artificer = {
    id = "artificer",
    name = "Artificer",
    description = ( 
        "You can sense the inner most magical properties within any object, " ..
        "giving you an innate aptitude for enchanting (+50 Enchanting). " ..
        "However, this seems to be your only outlet for magic, as you are utterly " ..
        "incapable of casting spells. "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 50
        })
    end,
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            return data
        end

        local function spellCast(e)
            local data = getData()
            if data.currentBackground == "artificer" then
                if e.caster == tes3.player then
                    local allowedSpells = getConfig().exclusions
                    if not allowedSpells[e.source.name] then
                        e.castChance = 0
                    end
                end
            end
        end

        if artificerDoOnce then return end
        artificerDoOnce = true
        event.register("spellCast", spellCast)
    end
}

local minBounty = 20
local maxBounty = 120
local minInterval = 24
local maxInterval = ( 24 * 4 )

this.framed = {
    id = "framed", 
    name = "Framed",
    description = (
        "You got on the wrong side of some people in very powerful positions. " ..
        "Every once in a while, you will get a price on your head for a crime you did not commit. Your life on " ..
        "the run has given you a talent for guile and stealth (+10 to all Stealth Skills)."
    ),
    doOnce = function()
        local stealthSkills = {
            "acrobatics",
            "security",
            "sneak",
            "lightArmor",
            "marksman",
            "shortBlade",
            "handToHand",
            "mercantile",
            "speechcraft",
        }
        for _, skill in ipairs(stealthSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = tes3.skill[skill], 
                value = 10
            })
        end

    end,
    callback = function()         

        local function calcCrimeInterval()
            return math.random(minInterval, maxInterval)
        end
        local function calcCrimeValue()
            return math.random(minBounty, maxBounty)
        end

        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.framed = data.framed or {
                timeToNextCrime = calcCrimeInterval()
            }
            return data
        end
        



        local checkCrime
        local timerInterval = 1
        local function startTimer()
            timer.start{
                type = timer.game, 
                duration =  timerInterval,
                callback = checkCrime,
                iterations = -1
            }
        end

        
        checkCrime = function()
            local data = getData()
            if not tes3.mobilePlayer.inCombat then
                if data.framed.timeToNextCrime <= 0 and tes3.mobilePlayer.bounty <= 300 then
                    --Add bounty
                    local crimeVal = calcCrimeValue()
                    tes3.mobilePlayer.bounty = crimeVal
                    tes3.messageBox("A %s gold bounty has been placed on your head.", crimeVal)

                    --Set time to next bounty
                    local newInterval = calcCrimeInterval()
                    data.framed.timeToNextCrime = newInterval
                    return
                end
            end
            data.framed.timeToNextCrime = data.framed.timeToNextCrime - timerInterval
        end

        startTimer()
    end
}

local natureDoOnce
this.childOfNature = {
    id = "childOfNature",
    name = "Child of Nature",
    description = (
        "You feel most at home out in the wilderness, as far from other people as possible. " ..
        "You get +5 to all skills while outdoors in the wild, and -5 to all skills while " ..
        "in civilisation (towns, settlements etc). "
    ),
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.childOfNature = data.childOfNature or {
                buffed = false,
                debuffed = false
             }
            return data
        end
        

        local function modSkills(value)
            for _, skill in pairs(tes3.skill) do
                tes3.modStatistic({
                    reference = tes3.player,
                    skill = skill, 
                    value = value
                })
            end
        end

        local function cellChanged(e)
            local data = getData()
            if data.currentBackground == "childOfNature" then
                --In town
                if e.cell.restingIsIllegal then
                    --remove buff
                    if data.childOfNature.buffed then
                        data.childOfNature.buffed = false
                        modSkills(-5)
                    end
                    --add debuff
                    if not data.childOfNature.debuffed then
                        data.childOfNature.debuffed = true
                        modSkills(-5)
                    end
                else
                --Not in town
                    --remove debuff
                    if data.childOfNature.debuffed then
                        data.childOfNature.debuffed = false
                        modSkills(5)
                    end

                    --outside
                    if not e.cell.isInterior then
                        --add buff
                        if not data.childOfNature.buffed then
                            data.childOfNature.buffed = true
                            modSkills(5)
                        end
                    else
                        if data.childOfNature.buffed then
                            data.childOfNature.buffed = false
                            modSkills(-5)
                        end
                    end
                end
            else
            --Background not selected, remove any effects
                --remove debuff
                if data.childOfNature.debuffed then
                    data.childOfNature.debuffed = false
                    modSkills(5)
                end
                --remove buff
                if data.childOfNature.buffed then
                    data.childOfNature.buffed = false
                    modSkills(-5)
                end
            end
        end

        cellChanged{ cell = tes3.getPlayerCell()}

        if natureDoOnce then return end
        natureDoOnce = true

        event.register("cellChanged", cellChanged)

    end
}

local agoraphobicDoOnce
this.agoraphobic = {
    id = "agoraphobic",
    name = "Agoraphobia",
    description = (
        "You are terrified of open spaces. When outdoors, you suffer a " ..
        "-5 penalty to all skills. When inside, you get +5 to all skills. "
    ),
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.agoraphobic = data.agoraphobic or {
                buffed = false,
                debuffed = false
            }
            return data
        end

        local function modSkills(value)
            for _, skill in pairs(tes3.skill) do
                tes3.modStatistic({
                    reference = tes3.player,
                    skill = skill, 
                    value = value
                })
            end
        end

        local function cellChanged(e)
            local data = getData()
            if data.currentBackground == "agoraphobic" then
                --Indoors
                if not e.cell.isInterior then
                    --remove buff
                    if data.agoraphobic.buffed then
                        data.agoraphobic.buffed = false
                        modSkills(-5)
                    end
                    --add debuff
                    if not data.agoraphobic.debuffed then
                        data.agoraphobic.debuffed = true
                        modSkills(-5)
                    end
                else
                    --remove debuff
                    if data.agoraphobic.debuffed then
                        data.agoraphobic.debuffed = false
                        modSkills(5)
                    end
                    --add buff
                    if not data.agoraphobic.buffed then
                        data.agoraphobic.buffed = true
                        modSkills(5)
                    end
                end
            else
            --Background not selected, remove any effects
                --remove debuff
                if data.agoraphobic.debuffed then
                    data.agoraphobic.debuffed = false
                    modSkills(5)
                end
                --remove buff
                if data.agoraphobic.buffed then
                    data.agoraphobic.buffed = false
                    modSkills(-5)
                end
            end
        end
        cellChanged({ cell = tes3.getPlayerCell() })

        if agoraphobicDoOnce then return end
        agoraphobicDoOnce = true
        event.register("cellChanged", cellChanged)
    end
}

local TESTMODE = false

local warriorDoOnce
local warriorInterruptChance = TESTMODE and 1.0 or 0.20
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
this.famedWarrior = {
    id = "famedWarrior",
    name = "Famed Warrior",
    description = (
        "You had a reputation as a mighty warrior in Mournhold. " ..
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
            mwscript.addItem{
                reference = tes3.player, 
                item = sword
            }
            tes3.mobilePlayer:equip{ item = sword }
        end

        timer.delayOneFrame(function()
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
            end)


    end,

    callback = function()  
        if TESTMODE then
            tes3.messageBox("Character Backgrounds TESTMODE is ON")
        end
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            return data
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

local dremoraBloodDoOnce
local dremoraInterruptChance = 0.30
local dremoraDoAttack
this.dremoraBlood = {
    id = "dremoraBlood",
    name = "Blood of the Dremora",
    description = ( 
        "Long ago, you performed a dark ritual to infuse your blood with that of a dremora. " ..
        "While it did increase your magical affinity, it also angered the him a great deal. " ..
        "Every once in a while, the daedra will summon himself to Nirn and hunt you down. " ..
        "Whenever he is defeated, you absorb his blood, causing all your magic skills to increase by 1."
    ),
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.dremoraBlood = data.dremoraBlood or {
                dremoraKilled = 0
            }
            return data
        end

        --calculate whether to replace interrupt creature with dremora
        local function calcRestInterrupt(e)
            local data = getData()
            if data.currentBackground == "dremoraBlood" then
                --One dremora killed every two levels, starting at lvl 2
                local readyForDremora = (
                    (tes3.player.object.level - 2) >= (  data.dremoraBlood.dremoraKilled * 2 )
                )
                if readyForDremora then
                    local rand = math.random()
                    if rand < dremoraInterruptChance then
                        dremoraDoAttack = true
                        e.count = 1
                        e.hour = math.random(1, 3)
                    end
                end
            end
        end
    
        --replace interrupt creature with dremora
        local function restInterrupt(e)
            local data = getData()
            if data.currentBackground == "dremoraBlood" then
                if dremoraDoAttack then
                    dremoraDoAttack = false
                    e.creature = tes3.getObject("mer_bg_dremList")
                    local pcName = tes3.player.object.name
                    local introPhrases = {
                        '"Give me back my blood, mortal!"',
                        string.format("\"This is the end, %s!\"", pcName),
                        string.format("\"Your soul belongs to me, %s!\"",  pcName),
                        "\"You'll rue the day you took my blood, mortal!\"",
                        string.format("\"Curse you, %s!\" I will kill you next time!", pcName)
                    }
                    tes3.playSound({ 
                        sound = "dremora scream"
                    })
                    tes3.messageBox( introPhrases[ math.random(#introPhrases)] )
                    
                end
            end
        end

        --When dremora is dead, increase all magic skills by +1
        local function onDeath(e)
            local data = getData()
            if data.currentBackground == "dremoraBlood" then
                if string.find(e.reference.baseObject.id, "mer_bg_drem") then
                    local deathPhrases = {
                        
                    }
                    tes3.messageBox( deathPhrases[math.random(#deathPhrases)] )

                    tes3.playSound({ sound = "dremora moan"})
                    mwscript.disable({ reference = e.mobile})
                    data.dremoraBlood.dremoraKilled = data.dremoraBlood.dremoraKilled + 1
                    local magicSkills = {
                        "illusion",
                        "alchemy",
                        "alteration",
                        "conjuration",
                        "destruction",
                        "enchant",
                        "mysticism",
                        "restoration"
                    }
                    for _, skill in ipairs(magicSkills) do
                        tes3.modStatistic({
                            reference = tes3.player,
                            skill = tes3.skill[skill],
                            value = 1
                        })
                    end
                    tes3.messageBox({
                        message = "Dremora blood courses through your veins. Your magic skills have increased!",
                        buttons = { "Okay" }
                    })
                end
            end
        end

        --Prevent looting dremora
        local function onActivate(e)
            if e.target and string.find(e.target.baseObject.id, "mer_bg_drem") then
                return false
            end
        end

        if dremoraBloodDoOnce then return end
        dremoraBloodDoOnce = true

        event.register("calcRestInterrupt", calcRestInterrupt)
        event.register("restInterrupt", restInterrupt)
        event.register("death", onDeath)
        event.register("activate", onActivate)
    end
}

local knifeThrowerDoOnce
this.knifeThrower = {
    id = "knifeThrower",
    name = "Knife Thrower",
    description = (
        "You spent your formative years as a knife thrower. " ..
        "Your Marksman skill increases by 10 when a throwing weapon is equipped."
    ),
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.knifeThrower = data.knifeThrower or {
                buffed = false,
            }
            return data
        end

        local function onEquip(e)
            local data = getData()
            if data.currentBackground == "knifeThrower" then
                timer.delayOneFrame( 
                    function()
                        if e.item.objectType == tes3.objectType.weapon then
                            if e.item.type == tes3.weaponType.marksmanThrown then
                                if not data.knifeThrower.buffed then
                                    data.knifeThrower.buffed = true
                                    tes3.modStatistic({
                                        reference = tes3.player,
                                        skill = tes3.skill.marksman,
                                        value = 10
                                    })
                                end
                            end
                                
                        end
                    end,
                    timer.real
                )
            end
        end
        

        local function onUnequip(e)
            local data = getData()
            if e.item.objectType == tes3.objectType.weapon then
                if e.item.type == tes3.weaponType.marksmanThrown then
                    if data.knifeThrower.buffed then
                        data.knifeThrower.buffed = false
                        tes3.modStatistic({
                            reference = tes3.player,
                            skill = tes3.skill.marksman,
                            value = -10
                        })
                    end
                end
            end
        end

        local equippedItem = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
        if equippedItem then
            onEquip({ item = equippedItem.object })
        end

        --Register once per gameLoad
        if knifeThrowerDoOnce == true then return end
        knifeThrowerDoOnce = true

        event.register("equip", onEquip)
        event.register("unequipped", onUnequip)
    end
}

local pacifistAmount = 5
this.pacifist = {
    id = "pacifist",
    name = "Pacifist",
    description = (
       "You have dedicated your life to the pursuit of peace. You have -".. pacifistAmount..
       " penalties to all combat oriented skills, and +"..pacifistAmount.." to all others." 
    ),
    doOnce = function()
        local combatSkills = {
            tes3.skill.axe,
            tes3.skill.block,
            tes3.skill.bluntWeapon,
            tes3.skill.conjuration,
            tes3.skill.destruction,
            tes3.skill.handToHand,
            tes3.skill.heavyArmor,
            tes3.skill.lightArmor,
            tes3.skill.longBlade,
            tes3.skill.marksman,
            tes3.skill.mediumArmor,
            tes3.skill.shortBlade,
            tes3.skill.spear,
        }
        local passiveSkills = {
            tes3.skill.acrobatics,
            tes3.skill.alchemy,
            tes3.skill.alteration,
            tes3.skill.armorer,
            tes3.skill.athletics,
            tes3.skill.enchant,
            tes3.skill.illusion,
            tes3.skill.mercantile,
            tes3.skill.mysticism,
            tes3.skill.restoration,
            tes3.skill.security,
            tes3.skill.sneak, 
            tes3.skill.speechcraft,
            tes3.skill.unarmored,
        }
        for _, skill in ipairs(combatSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = -pacifistAmount
            })
        end
        for _, skill in ipairs(passiveSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = pacifistAmount
            })
        end
    end
}


local trackerDoOnce
this.tracker = {
    id = "tracker",
    name = "Tracker",
    description = (
        "As a seasoned tracker, you can read signs and disturbances left by animals to find their location. " ..
        "You also know the lay of the land, and can move quickly through uneven terrain. You gain a " ..
        "100pt Detect Animal ability, and gain 10 Speed when out in the wilderness."
    ),
    doOnce = function()
        --add tracker ability
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mer_bg_tracker_a"
        }
    end,

    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.tracker = data.tracker or {
                buffed = false,
            }
            return data
        end
        

        local function modSpeed(value)
            tes3.modStatistic({
                reference = tes3.player,
                attribute = tes3.attribute.speed,
                value = value
            })
        end

        local function cellChanged(e)
            local data = getData()
            if data.currentBackground == "tracker" then
                --In town
                if e.cell.restingIsIllegal then
                    --remove buff
                    if data.tracker.buffed then
                        data.tracker.buffed = false
                        modSpeed(-10)
                    end
                else
                --Not in town

                    --outside
                    if not e.cell.isInterior then
                        --add buff
                        if not data.tracker.buffed then
                            data.tracker.buffed = true
                            modSpeed(10)
                        end
                    else
                        if data.tracker.buffed then
                            data.tracker.buffed = false
                            modSpeed(-10)
                        end
                    end
                end
            else
                --remove buff
                if data.tracker.buffed then
                    data.tracker.buffed = false
                    modSpeed(-10)
                end
            end
        end

        if trackerDoOnce then return end
        trackerDoOnce = true

        event.register("cellChanged", cellChanged)
    end
}

this.urchin = {
    id = "urchin",
    name = "Street Urchin",
    description = (
        "Before you were found and brought to the palace, you grew up on the streets of Almalexia, alone and poor. You had no one to watch over you " ..
        "or to provide for you, so you learned to lie, cheat and steal just to get by. " ..
        "You gain a +10 bonus to Sneak, Security and Speechcraft. However, years " ..
        "of poverty has left your body weak. You receive a -5 penalty to Strength and Endurance. "
    ),
    doOnce = function()
        -- stat penalties
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.endurance,
            value = -5
        })
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.strength,
            value = -5
        })

        --Skill buffs
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.sneak,
            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.security, 
            

            value = 10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 10
        })
    end
}

this.noble = {
    id = "noble",
    name = "Swag",
    description = (
        "You have lived your life in comfort and luxury, always following the fashion and did not miss a single feast or romantic interest. " ..
        "You had a formal education where you learned to read and speak with manners " ..
        "(+5 Intelligence, +10 Speechcraft). However, being waited on hand and foot has left " ..
        "you with a lack of Willpower (-10). You are provided with a set of expensive clothing. "
    ),
    doOnce = function()
        --buffs
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.speechcraft,
            value = 10
        })

        --debuffs
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.willpower,
            value = -10
        })

        --Clothing
        local clothes = {
            "expensive_shirt_03", 
            "expensive_belt_03",
            "expensive_pants_02", 
            "expensive_shoes_03", 
        }
        for _, id in ipairs(clothes) do
            mwscript.addItem{ reference = tes3.player, item = id }
        end
        timer.delayOneFrame(
            function()
                for _, id in ipairs(clothes) do
                   tes3.mobilePlayer:equip{ item = id }
                end
            end
        )


    end
}


local starChildDoOnce
local starChildLuckClear = 50
local starChildLuckCloudy = 25
this.starChild = {
    id = "starChild",
    name = "Star Child",
    description = (
        "You were born under starlight, and have gained the favor of the Celestials. " ..
        "When outdoors at night, your Luck increases by " .. 
        starChildLuckClear .. " points during clear weather and " .. 
        starChildLuckCloudy.. " points during partially cloudy weather. "

    ),
    callback = function()         
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.starChild = data.starChild or {
                luck = nil
            }
            return data
        end
        local function update()
            local data = getData()

            local hour = tes3.worldController.hour.value 
            local isNight = hour <= 6 or hour >= 20
            local isOutdoors = not tes3.getPlayerCell().isInterior

            local luckLevel
            local weather = tes3.getCurrentWeather() and tes3.getCurrentWeather().index or 0
            if weather == tes3.weather.clear then
                luckLevel = starChildLuckClear
            elseif weather == tes3.weather.cloudy then
                luckLevel = starChildLuckCloudy
            end
            
            if isNight and isOutdoors and luckLevel then

                if not data.starChild.luck or luckLevel ~= data.starChild.luck then
                    
                    local change = luckLevel - ( data.starChild.luck or 0 )
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.luck,
                        value = change
                    })
                    data.starChild.luck = luckLevel
                    tes3.messageBox("The Celestials smile upon you.")
                end
            else
                if data.starChild.luck then
                    
                    tes3.modStatistic({
                        reference = tes3.player,
                        attribute = tes3.attribute.luck,
                        value = -data.starChild.luck
                    })
                    data.starChild.luck = false
                end
            end
        end

        timer.start{
            type = timer.game,
            iterations = -1,
            duration = 0.05,
            callback = update
        }
        update()
        if starChildDoOnce then return end
        starChildDoOnce = true

        event.register("cellChanged", update)
        event.register("weatherTransitionFinished", update)
        event.register("weatherChangedImmediate ", update)
    end
}

this.fisherman = {
    id = "fisherman",
    name = "Raised in a Fishing Village",
    description = (
        "You grew up in the quiet bustle of a remote fishing village on the mainland before you were found and brought to the palace. " ..
        "You haven't had a formal education for a long time, but you " ..
        "know how to swim, harpoon and gut fish better than anybody. " ..
        "You receive a -10 penalty to Intelligence, and a +5 to Spear and Short Blade skills. " ..
        "You also gain a 25pt Swift Swim Ability."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.intelligence,
            value = -10
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.spear,
            value = 5
        })
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.shortBlade,
            value = 5
        })
        mwscript.addSpell{
            reference = tes3.player, 
            spell = "mer_bg_fisher_feet"
        }
    end
}

local bodyBuilderDoOnce
this.bodyBuilder = {
    id = "bodyBuilder",
    name = "Bodybuilder",
    description = (
        "You have an incredible body. When you show it off, people can't help but swoon. " ..
        "When you are not wearing a shirt or chestpiece, you gain +10 to Personality. " ..
        "Unfortunately, your body is the most interesting thing about you, and when not " ..
        "mesmerized by your good looks, people quickly realize how boring you are. " .. 
        "When wearing a shirt or chest piece, you suffer a -10 penalty to Personality. "
    ),
    callback = function()
        local function getData()
            local data = tes3.player.data.merBackgrounds or {}
            data.bodyBuilder = data.bodyBuilder or {
                wearingShirt = tes3.getEquippedItem{ 
                    actor = tes3.player, 
                    objectType = tes3.objectType.clothing, 
                    slot = tes3.clothingSlot.shirt
                },
                wearingCuirass = tes3.getEquippedItem{ 
                    actor = tes3.player, 
                    objectType = tes3.objectType.armor, 
                    slot = tes3.armorSlot.cuirass
                },
                buffed = false,
                debuffed = false
            }
            return data
        end

        

        local function checkChest()
            local data = getData()
            if data.currentBackground == "bodyBuilder" then
                
                --Shirtless
                if not data.bodyBuilder.wearingShirt and not data.bodyBuilder.wearingCuirass then
                    --add buff
                    if not data.bodyBuilder.buffed then
                        data.bodyBuilder.buffed = true
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = 10
                        })
                    end

                    --remove debuff
                    if data.bodyBuilder.debuffed then
                        data.bodyBuilder.debuffed = false
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = 10
                        })
                    end

                --wearing shirt
                else
                    --add debuff
                    if not data.bodyBuilder.debuffed then
                        data.bodyBuilder.debuffed = true
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = -10
                        })
                    end

                    --remove buff
                    if data.bodyBuilder.buffed then
                        data.bodyBuilder.buffed = false
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = -10
                        })
                    end
                end
            end
        end

        local function onEquip(e)
            local data = getData()
            if data.currentBackground == "bodyBuilder" then
                timer.delayOneFrame( 
                    function()
                        local isShirt = (
                            e.item.objectType == tes3.objectType.clothing and
                            e.item.slot == tes3.clothingSlot.shirt
                        )
                        if isShirt then
                            data.bodyBuilder.wearingShirt = true
                        end

                        local isCuirass = (
                            e.item.objectType == tes3.objectType.armor and
                            e.item.slot == tes3.armorSlot.cuirass
                        )
                        if isCuirass then
                            data.bodyBuilder.wearingCuirass = true
                        end
                        if isShirt or isCuirass then
                            checkChest()
                        end
                        
                    end,
                    timer.real
                )
            end
        end
        

        local function onUnequip(e)
            local data = getData()
            if data.currentBackground == "bodyBuilder" then
                local isShirt = (
                    e.item.objectType == tes3.objectType.clothing and
                    e.item.slot == tes3.clothingSlot.shirt
                )
                if isShirt then
                    data.bodyBuilder.wearingShirt = false
                end

                local isCuirass = (
                    e.item.objectType == tes3.objectType.armor and
                    e.item.slot == tes3.armorSlot.cuirass
                )
                if isCuirass then
                    data.bodyBuilder.wearingCuirass = false
                end
                if isShirt or isCuirass then
                    checkChest()
                end
            end
        end
        checkChest()
        --Register once per gameLoad
        if bodyBuilderDoOnce == true then return end
        bodyBuilderDoOnce = true

        event.register("equip", onEquip)
        event.register("unequipped", onUnequip)
    end
}

this.greyOne = {
    id = "greyOne",
    name = "Grey Child",
    description = (
        "You were born with a pale complexion and strangely sharp teeth. " ..
        "Animals are uneasy around you, and sunlight makes your skin tingle. " ..
        "Were you cursed? Perhaps your mother was a vampire? " ..
        "Regardless, you feel most at home in the cold and dark. During the night (between the hours of 6pm and 6am), " ..
        "the following skills increase by 15: Sneak, Athletics, Acrobatics,  Mysticism, " ..
        "Illusion, and Destruction. However, during the day, your Endurance and Willpower are reduced by 10. "
    ),
    callback = function()
        
        local function getData()
            local data = tes3.player.data.merBackgrounds
            data.greyOne = data.greyOne or {
                nightBuff = false,
                dayBuff = false
            }
            return data
        end

        local function toggleNightBuff(data)

            local val = data.greyOne.nightBuff and -15 or 15
            data.greyOne.nightBuff = not data.greyOne.nightBuff
            local vampSkills = {
                tes3.skill.sneak,
                tes3.skill.athletics,
                tes3.skill.acrobatics,
                tes3.skill.mysticism,
                tes3.skill.illusion,
                tes3.skill.destruction
            }
            for _, skill in ipairs(vampSkills) do
                tes3.modStatistic({
                    reference = tes3.player,
                    skill = skill, 
                    value = val
                })
            end
        end

        local function toggleDayBuff(data)
            local val = data.greyOne.dayBuff and 10 or -10
            data.greyOne.dayBuff = not data.greyOne.dayBuff
            local vampStats = {
                tes3.attribute.endurance,
                tes3.attribute.willpower
            }
            for _, attribute in ipairs(vampStats) do
                tes3.modStatistic({
                    reference = tes3.player,
                    attribute = attribute, 
                    value = val
                })
            end
        end


        local function greyOneCheckTime()
            local data = getData()
            if not data.currentBackground == "greyOne" then return end

            local hour = tes3.worldController.hour.value
            
            if hour >= 18 or hour < 6 then

                --add buff
                if not data.greyOne.nightBuff then
                    toggleNightBuff(data)
                end

                --remove debuff
                if data.greyOne.dayBuff then
                    toggleDayBuff(data)
                end

            else
                if data.greyOne.nightBuff then 
                    toggleNightBuff(data)
                end

                if not data.greyOne.dayBuff then
                    toggleDayBuff(data)
                end
            end
        end
        timer.start{type = timer.real, iterations = -1, duration = 1, callback = greyOneCheckTime }
    end
}

local escapedSlaveInterruptChance = TESTMODE and 1.0 or 0.20
local currentSlaver
local slaverDoAttack
local escapedSlaveDoOnce
this.escapedSlave = {
    id = "escapedSlave",
    name = "Ex-Slave",
    description = (
        "After the incident, the king sold you into slavery on a local plantation, where you worked hard all the time. " ..
        "Your former wealthy master hates you especially, and has sent a team of headhunters to " ..
        "track you down and kill you, despite the fact that you were officially released. \n\n" ..

        "Requirements: Khajiit or Argonian only."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        local isSlaveRace = ( race == "Argonian" or race == "Khajiit" )
        return not isSlaveRace
    end,
    doOnce = function(data)
        data.escapedSlave = data.escapedSlave or {
            slaversKilled = 0,
            slavers = {
                { id = "mer_bg_headhunter_01", list = "mer_bg_headhunterList_01", hasFought = false},
                { id = "mer_bg_headhunter_02", list = "mer_bg_headhunterList_02", hasFought = false},
                { id = "mer_bg_headhunter_03", list = "mer_bg_headhunterList_03", hasFought = false},
                { id = "mer_bg_headhunter_04", list = "mer_bg_headhunterList_04", hasFought = false},
                { id = "mer_bg_headhunter_05", list = "mer_bg_headhunterList_05", hasFought = false},
                { id = "mer_bg_slavemaster", list = "mer_bg_slavemasterList", hasFought = false},
            }
        }
        tes3.addItem{
            reference = tes3.player,
            item = "slave_bracer_left",
        }
        tes3.addItem{
            reference = tes3.player,
            item = "slave_bracer_right",
        }
        timer.delayOneFrame(function()
            tes3.mobilePlayer:equip{ item = "slave_bracer_left", playSound = false }
            tes3.mobilePlayer:equip{ item = "slave_bracer_right", playSound = false }
        end)
    end,
    callback = function()
        local function getData()
            local data = tes3.player.data.merBackgrounds or {
            }
            return data
        end

        local function calcRestInterrupt(e)
            local data = getData()
            if data.currentBackground == "escapedSlave" then
                local rand = math.random()
                if rand < escapedSlaveInterruptChance then
                    for _, slaver in ipairs(data.escapedSlave.slavers) do
                        local validSlaver = (
                            not slaver.hasFought and
                            --Player must be at least the same level as the headhunter
                            ( TESTMODE or tes3.getObject(slaver.id).level <= tes3.player.object.level )
                        )
                        if validSlaver then
                            currentSlaver = slaver
                            slaverDoAttack = true
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
            if data.currentBackground == "escapedSlave" then
                if slaverDoAttack and currentSlaver then
                    slaverDoAttack = false
                    currentSlaver.hasFought = true
                    e.creature = tes3.getObject(currentSlaver.list)
                end
            end
        end

        if not escapedSlaveDoOnce then
            escapedSlaveDoOnce = true
            event.register("calcRestInterrupt", calcRestInterrupt)
            event.register("restInterrupt", restInterrupt)
        end
    end

}



local greenPactDoOnce
this.greenPact = {
    id = "greenPact",
    name = "Green Pact",
    description = (
        "As a Bosmer, you wanted to be closer to mother culture and have sworn an oath, known as the Green Pact, to the forest deity Y'ffre. " ..
        "One of the conditions of this pact states that you may only consume meat-based products." ..
        "\n\nRequirements: Wood Elves only."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    callback = function()
        if not greenPactDoOnce then
            greenPactDoOnce = true
            local function checkIsMeat(e)
                if e.item.objectType == tes3.objectType.ingredient then
                    local config = getConfig()
                    local id = string.lower(e.item.id)
                    if not config.greenPactAllowed[id] then
                        tes3.messageBox("The Green Pact prohibits you from eating this.")
                        return false
                    end
                end
            end
            event.register("equip", checkIsMeat )
        end
    end
}

return this