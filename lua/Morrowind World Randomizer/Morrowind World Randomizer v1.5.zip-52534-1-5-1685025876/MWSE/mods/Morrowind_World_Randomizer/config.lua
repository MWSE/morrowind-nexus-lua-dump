local log = require("Morrowind_World_Randomizer.log")
local dataSaver = include("Morrowind_World_Randomizer.dataSaver")

local this = {}

this.fullyLoaded = false;

this.defaultProfileNames = {
    ["default"] = true,
    ["extended"] = true,
}

local globalConfigName = "MWWRandomizer_Global"
local configName = "MWWRandomizer_Config"
local profileFileName = "MWWRandomizer_Profiles"

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function addMissing(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = deepcopy(val)
            else
                if type(toTable[label]) ~= "table" then toTable[label] = {} end
                addMissing(toTable[label], val)
            end
        elseif toTable[label] == nil then
            toTable[label] = val
        end
    end
end

local function applyChanges(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = deepcopy(val)
            else
                if type(toTable[label]) ~= "table" then toTable[label] = {} end
                applyChanges(toTable[label], val)
            end
        else
            toTable[label] = val
        end
    end
end

this.global = mwse.loadConfig(globalConfigName)
this.data = nil

this.globalDefault = {
    dataTables = {
        forceTRData = false,
        usePregeneratedItemData = false,
        usePregeneratedCreatureData = false,
        usePregeneratedHeadHairData = false,
        usePregeneratedSpellData = false,
        usePregeneratedHerbData = false,
    },
    globalConfig = false,
    logging = false,
    cellRandomizationCooldown = 300,
    cellRandomizationCooldown_gametime = 24,
    allowDoubleLoading = true,
    uniqueId = 0,
    landscape = {
        randomize = false,
        randomizeOnlyOnce = false,
        textureIndices = {},
    }
}

if this.global == nil then
    this.global = deepcopy(this.globalDefault)
else
    addMissing(this.global, this.globalDefault)
end

this.default = {
    enabled = false,
    trees = {
        randomize = true,
        exceptScale = 2.5,
    },
    stones = {
        randomize = true,
        exceptScale = 2.5,
    },
    flora = {
        typesPerCell = 3,
        randomize = true,
    },
    herbs = {
        randomize = true,
        doNotRandomizeInventory = true,
        herbSpeciesPerCell = 5,
    },
    containers = {
        items = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
        },
        lockTrapCooldown = 72,
        lock = {
            randomize = true,
            region = {min = 0.3, max = 0.3},
            add = {
                chance = 0.1,
                levelMultiplier = 5,
            },
        },
        trap = {
            randomize = true,
            region = {min = 1, max = 1},
            add = {
                chance = 0.3,
                levelMultiplier = 5,
                onlyDestructionSchool = false,
            },
        },
    },
    items = {
        randomize = true,
        region = {min = 0.1, max = 0.1},
    },
    soulGems = {
        maxCapacity = 400,
        soul = {
            randomize = true,
            region = {min = 0.2, max = 0.2},
        },
    },
    gold = {
        randomize = true,
        region = {min = 0.25, max = 1.75},
    },
    creatures = {
        randomizeOnlyOnce = false,
        randomize = true,
        region = {min = 0.1, max = 0.1},
        items = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
        },
        attack = {
            randomize = true,
            region = {min = 0.75, max = 1.25},
        },
        spells = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.1,
                count = 3,
                levelReference = 20,
            },
        },
        abilities = {
            randomize = false,
            region = {min = 0.5, max = 0.5},
            add = {
                chance = 0.1,
                count = 0,
            },
        },
        diseases = {
            randomize = false,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.1,
                count = 1,
            },
        },
        health = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        magicka = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        fatigue = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        skills = {
            randomize = true,
            limit = 100,
            combat = {
                region = {min = 0.2, max = 0.2},
            },
            magic = {
                region = {min = 0.2, max = 0.2},
            },
            stealth = {
                region = {min = 0.2, max = 0.2},
            },
        },
        scale = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        effects = {
            positive = {
                add = {
                    chance = 1,
                    count = 1,
                    region = {min = 0, max = 100},
                },
            },
            negative = {
                add = {
                    chance = 1,
                    count = 1,
                    region = {min = 0, max = 100},
                },
            },
        },
        ai = {
            fight = {
                randomize = true,
                region = {min = 0.1, max = 0.2},
            },
            flee = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            alarm = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            hello = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
        },
    },
    NPCs = {
        randomizeOnlyOnce = false,
        items = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
        },
        spells = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 1,
                count = 3,
                levelReference = 20,
            },
        },
        abilities = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.1,
                count = 0,
            },
        },
        diseases = {
            randomize = false,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.1,
                count = 1,
            },
        },
        health = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        magicka = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        fatigue = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        attributes = {
            randomize = true,
            limit = 255,
            region = {min = 0.5, max = 1.5},
        },
        skills = {
            randomize = true,
            limit = 100,
            combat = {
                region = {min = 0.2, max = 0.2},
            },
            magic = {
                region = {min = 0.2, max = 0.2},
            },
            stealth = {
                region = {min = 0.2, max = 0.2},
            },
        },
        head = {
            randomize = true,
            raceLimit = false,
            genderLimit = true,
        },
        hair = {
            randomize = true,
            raceLimit = false,
            genderLimit = false,
        },
        scale = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        effects = {
            positive = {
                add = {
                    chance = 1,
                    count = 1,
                    region = {min = 0, max = 100},
                },
            },
            negative = {
                add = {
                    chance = 1,
                    count = 1,
                    region = {min = 0, max = 100},
                },
            },
        },
        ai = {
            fight = {
                randomize = true,
                region = {min = 0.1, max = 0.2},
            },
            flee = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            alarm = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            hello = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
        },
    },
    barterGold = {
        randomize = true,
        region = {min = 0.5, max = 1.5},
    },
    transport = {
        randomize = true,
        unrandomizedCount = 1,
        toDoorsCount = 0,
        toRandomPointCount = 0,
    },
    doors = {
        randomize = true,
        onlyOnCellRandomization = true,
        doNotRandomizeInToIn = false,
        doNotLockBackdoor = true,
        smartInToInRandomization = {
            enabled = true,
            backDoorMode = true,
            iterations = 200,
            cellDepth = 50,
        },
        onlyNearest = true,
        nearestCellDepth = 2,
        chance = 0.2,
        cooldown = 10,
        restoreOriginal = true,
        lockTrapCooldown = 72,
        lock = {
            randomize = true,
            safeCellMode = {
                enabled = true,
                fightValue = 60,
            },
            region = {min = 0.3, max = 0.3},
            add = {
                chance = 0.1,
                levelMultiplier = 5,
            },
        },
        trap = {
            randomize = true,
            safeCellMode = {
                enabled = true,
                fightValue = 50,
            },
            region = {min = 0.3, max = 0.3},
            add = {
                chance = 0.2,
                levelMultiplier = 5,
                onlyDestructionSchool = false,
            },
        },
    },
    weather = {
        randomize = true,
    },
    cells = {
        randomizeOnlyOnce = false,
    },
    light = {
        randomize = true,
    },
    other = {
        randomizeArtifactsAsSeparateCategory = true,
        disableMGEDistantLand = false,
        disableMGEDistantStatics = false,
    },
    item = {
        stats = {
            randomize = true,
            region = {min = 0.75, max = 1.25},
            weapon = {
                region = {min = 0.75, max = 1.25},
            },
        },
        enchantment = {
            randomize = true,
            exceptScrolls = true,
            exceptAlchemy = true,
            exceptIngredient = true,
            useExisting = false,
            existing = {
                region = {min = 0.2, max = 0.2},
            },
            region = {min = 0.5, max = 1.5},
            powMul = 0.65,
            numberOfCasts = {min = 4, max = 15},
            cost = {min = 15, max = 800},
            scrollBase = 50,
            arrowPower = 0.25,
            minMaximumGroupCost = 100,
            effects = {
                tuneStepsCount = 30,
                safeMode = true,
                oneTypeChance = 0.75,
                maxCount = 6,
                alchemyCount = {min = 1, max = 3},
                ingredient = {
                    smartRandomization = true,
                    minimumIngrForOneEffect = 4,
                    count = {min = 4, max = 4},
                    region = {min = 0.4, max = 0.4},
                },
                countPowMul = 2,
                threshold = 0.2,
                chanceToNegative = 0.2,
                chanceToNegativeForTarget = 0.8,
                maxDuration = 60,
                minAppOnceDuration = 5,
                durationForConstant = 100,
                maxRadius = 30,
                maxMagnitude = 100,
                fortifyForSelfChance = 0.4,
                damageForTargetChance = 0.25,
                restoreForAlchemyChance = 0.1,
            },
            add = {
                chance = 0.5,
                exceptScrolls = true,
                region = {min = 0.5, max = 2},
            },
            remove = {
                exceptScrolls = true,
                chance = 0.25,
            },
        },
        unique = false,
        changeParts = true,
        changeMesh = false,
        linkMeshToParts = true,
        tryToFixZCoordinate = true,
    },
}

this.data = deepcopy(this.default)

this.profiles = mwse.loadConfig(profileFileName)
if this.profiles == nil then
    mwse.saveConfig(profileFileName, {})
    this.profiles = mwse.loadConfig(profileFileName)
end

-- if not this.profiles["default"] then
    this.profiles["default"] = deepcopy(this.default)
-- end

-- if not this.profiles["extreme"] then
if true then
    local preset = deepcopy(this.default)
    local setMinMax
    setMinMax = function(toTable)
        for label, val in pairs(toTable) do
            if type(val) == "table" then
                if label == "region" then
                    if val.min <= 0.5 and val.max <= 0.5 then
                        val.min = 1
                        val.max = 1
                    -- elseif val.min == 0.5 and val.max == 1.5 then
                    --     val.min = 0.25
                    --     val.max = 1.75
                    end
                else
                    setMinMax(val)
                end
            end
        end
    end
    setMinMax(preset)
    preset.herbs.herbSpeciesPerCell = 20
    preset.containers.lock.add.chance = 0.3
    preset.containers.trap.add.chance = 1
    preset.creatures.attack.region.min = 0.25
    preset.creatures.attack.region.min = 1.75
    preset.creatures.spells.add.count = 20
    preset.creatures.spells.add.levelReference = 1
    preset.creatures.diseases.add.count = 4
    preset.creatures.effects.positive.add.count = 2
    preset.creatures.effects.negative.add.count = 1
    preset.creatures.ai.fight.region.min = 0
    preset.creatures.ai.fight.region.max = 1

    preset.NPCs.spells.add.count = 5
    preset.NPCs.spells.add.levelReference = 1
    preset.NPCs.diseases.add.count = 4
    preset.NPCs.head.genderLimit = false
    preset.NPCs.effects.positive.add.count = 2
    preset.NPCs.effects.negative.add.count = 1
    preset.NPCs.ai.fight.region.min = 0.2
    preset.NPCs.ai.fight.region.max = 0.2

    preset.transport.unrandomizedCount = 0
    preset.transport.toDoorsCount = 1

    preset.doors.nearestCellDepth = 3
    preset.doors.chance = 0.3
    preset.doors.trap.safeCellMode.enabled = false

    preset.item.enchantment.useExisting = false
    preset.item.enchantment.add.chance = 0.75
    preset.item.enchantment.remove.chance = 0.25
    preset.item.enchantment.add.exceptScrolls = false
    preset.item.enchantment.remove.exceptScrolls = false
    preset.item.enchantment.randomize = true
    preset.item.enchantment.exceptScrolls = false
    preset.item.enchantment.exceptAlchemy = false
    preset.item.enchantment.exceptIngredient = false

    preset.item.changeMesh = true
    preset.item.linkMeshToParts = false
    preset.item.stats.region.min = 0.5
    preset.item.stats.region.max = 2

    this.profiles["extended"] = preset
end

function this.getValueByPath(path)
    local value = this.data
    if value ~= nil and #path > 0 then
        for valStr in (path.."."):gmatch("(.-)".."[.]") do
            value = value[valStr]
            if value == nil then
                return nil
            end
        end
    end
    return value
end

local function logTable(table, pathStr)
    for label, val in pairs(table) do
        if type(val) == "table" then
            logTable(val, pathStr..label..".")
        else
            log(pathStr..label.." = "..tostring(val))
        end
    end
end

function this.getConfig()
    if not this.fullyLoaded then
        this.load()
    end
    return this.data
end

function this.resetConfig()
    this.fullyLoaded = false
    applyChanges(this.data, this.default)
end

function this.resetToDefault()
    -- this.data = deepcopy(this.default)
    applyChanges(this.data, this.default)
    if not this.global and tes3.player then
        local playerData = dataSaver.getObjectData(tes3.player)
        if playerData then
            playerData.config = this.data
            tes3.player.modified = true
        end
    end
end

function this.save()
    mwse.saveConfig(globalConfigName, this.global)
    if this.global.globalConfig then
        mwse.saveConfig(configName, this.data)
    elseif tes3.player then
        local playerData = dataSaver.getObjectData(tes3.player)
        if playerData then
            playerData.config = this.data
            tes3.player.modified = true
        end
    end
end

function this.saveOnlyGlobal()
    mwse.saveConfig(globalConfigName, this.global)
end

function this.load()
    if this.global.globalConfig then
        local data = mwse.loadConfig(configName)
        if data == nil then
            applyChanges(this.data, this.default)
            this.fullyLoaded = true
        else
            applyChanges(this.data, data)
            this.fullyLoaded = true
        end
    elseif tes3.player then
        local playerData = dataSaver.getObjectData(tes3.player)
        if playerData then
            if playerData.config then
                applyChanges(this.data, playerData.config)
                this.fullyLoaded = true
            else
                applyChanges(this.data, this.default)
                playerData.config = this.data
                this.fullyLoaded = true
            end
        else
            log("Failed to load config")
            this.fullyLoaded = false
        end
    else
        log("Failed to load config")
        this.fullyLoaded = false
    end

    if this.fullyLoaded then
        log("Global config:")
        logTable(this.global, "")
        log("Main config:")
        logTable(this.data, "")
    end
end

function this.getProfile(profileName)
    return this.profiles[profileName]
end

function this.saveProfiles()
    mwse.saveConfig(profileFileName, this.profiles)
end

function this.saveCurrentProfile(profileName)
    this.profiles[profileName] = this.data
end

function this.deleteProfile(profileName)
    if this.profiles[profileName] then
        this.profiles[profileName] = nil
    end
end

function this.loadProfile(profileName)
    local data = this.getProfile(profileName)
    if data then
        local enabled = this.data.enabled
        addMissing(data, this.default)
        applyChanges(this.data, data)
        this.data.enabled = enabled
        return true
    end
    return false
end

if this.global.globalConfig then
    this.load()
end

return this