-- I Can't Breathe in This Thing
-- NPCs unequip closed helmets out of combat, equip them in combat

local config = mwse.loadConfig("icantbreathe", { fightThreshold = 70, excludeGuards = true, harshWeather = false })

local function isClosedHelmet(item)
    -- Check if item is armor, and if it is a closed helmet
    if item.objectType ~= tes3.objectType.armor then return false end
    return item.isClosedHelmet
end

local function findClosedHelmetInInventory(actor)
    -- Iterate through the actor's inventory to find a closed helmet
    for _, stack in ipairs(actor.inventory) do
        if isClosedHelmet(stack.object) then
            return stack.object
        end
    end
    return nil
end

local function isGuard(mobile, ref)
    -- Guards are identified by respawn flag and alarm 100
    return ref.object.isRespawn and mobile.alarm == 100
end

local function isAggressive(mobile)
    -- NPCs with high fight value keep their helmet on at all times
    return mobile.fight >= tonumber(config.fightThreshold)
end

local function unequipClosedHelmet(actor)
    -- Unequip closed helmet only if the equipped helmet is a closed helmet
    local equippedHelmet = tes3.getEquippedItem({ actor = actor, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet })
    if equippedHelmet and isClosedHelmet(equippedHelmet.object) then
        actor:unequip({ item = equippedHelmet.object })
    end
end

local function isHarshWeather(weather)
    -- Only ash and blight justify wearing a closed helmet
    return weather.index == tes3.weather.ash or weather.index == tes3.weather.blight
end

local function processCell()
    -- Iterate all NPCs in the current cell and unequip/equip closed helmets
    local cell = tes3.getPlayerCell()
    if not cell then return end
    -- Check current weather
    local weatherController = tes3.worldController.weatherController
    local currentWeather = weatherController and weatherController.currentWeather
    local isHarsh = config.harshWeather and currentWeather and isHarshWeather(currentWeather)
    for ref in cell:iterateReferences(tes3.objectType.npc) do
        local mobile = ref.mobile
        if mobile then
            if mobile == tes3.mobilePlayer then goto continue end
            if mobile.actorType ~= tes3.actorType.npc then goto continue end
            -- Guards logic
            if isGuard(mobile, ref) then
                if config.excludeGuards or isHarsh then
                    local helmet = findClosedHelmetInInventory(mobile)
                    if helmet then
                        tes3.equip({ reference = ref, item = helmet, selectBestCondition = true })
                    end
                else
                    unequipClosedHelmet(mobile)
                end
                goto continue
            end
            -- Aggressive NPCs and harsh weather logic
            if isAggressive(mobile) or isHarsh then
                local helmet = findClosedHelmetInInventory(mobile)
                if helmet then
                    tes3.equip({ reference = ref, item = helmet, selectBestCondition = true })
                end
            else
                unequipClosedHelmet(mobile)
            end
        end
        ::continue::
    end
end

local function onCombatStarted(eCombat)
    local actor = eCombat.actor
    -- Exclude player
    if actor == tes3.mobilePlayer then return end
    -- Only NPCs, no creatures
    if actor.actorType ~= tes3.actorType.npc then return end
    -- Exclude guards
    if config.excludeGuards and isGuard(actor, actor.reference) then return end
    -- Exclude aggressive NPCs
    if isAggressive(actor) then return end

    local helmet = findClosedHelmetInInventory(actor)
    if helmet then
        tes3.equip({ reference = actor.reference, item = helmet, selectBestCondition = true })
    end
end

local function onCombatStopped(eCombat)
    local actor = eCombat.actor
    -- Exclude player
    if actor == tes3.mobilePlayer then return end
    -- Only NPCs, no creatures
    if actor.actorType ~= tes3.actorType.npc then return end
    -- Exclude guards
    if config.excludeGuards and isGuard(actor, actor.reference) then return end
    -- Exclude aggressive NPCs
    if isAggressive(actor) then return end

    unequipClosedHelmet(actor)
end

local function onWeatherTransitionStarted(eWeather)
    if not config.harshWeather then return end
    processCell()
end

local function onWeatherTransitionFinished(eWeather)
    if not config.harshWeather then return end
    processCell()
end

local function onWeatherChangedImmediate(eWeather)
    if not config.harshWeather then return end
    processCell()
end

local function onCellChanged()
    processCell()
end

local function onLoaded()
    processCell()
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate{
        name = "I Can't Breathe in This Thing",
        headerImagePath = "MWSE/mods/evrex/icantbreathe/icantbreathe.tga",
    }

    template:saveOnClose("icantbreathe", config)
    template:register()

    local page = template:createSideBarPage({ label = "Settings" })
    page.sidebar:createInfo({ text = "I Can't Breathe in This Thing makes NPCs remove their closed helmets when out of combat, and put them back on when fighting." })
    local category = page:createCategory({ label = "Helmet Settings" })
    category:createTextField({
        label = "Fight Threshold",
        description = "NPCs with a fight value equal or higher than this will always wear their closed helmet (default: 70).",
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable({ id = "fightThreshold", table = config }),
        callback = function()
            tes3.messageBox("New value submitted: %d", tonumber(config.fightThreshold))
            processCell()
        end,
    })
    category:createOnOffButton({
        label = "Exclude Generic Guards",
        description = "Generic guards (respawn + alarm 100) will always wear their closed helmet.",
        variable = mwse.mcm.createTableVariable({ id = "excludeGuards", table = config }),
        callback = function() processCell() end,
    })
    category:createOnOffButton({
        label = "Harsh Weather",
        description = "NPCs wear closed helmets during ash and blight storms. Disable if using mods that manage NPC helmets during weather events.",
        variable = mwse.mcm.createTableVariable({ id = "harshWeather", table = config }),
        callback = function() processCell() end,
    })
end

local function onInitialized()
    mwse.log("[I Can't Breathe in This Thing] Initialized")
    event.register(tes3.event.combatStarted, onCombatStarted)
    event.register(tes3.event.combatStopped, onCombatStopped)
    event.register(tes3.event.cellChanged, onCellChanged)
    event.register(tes3.event.loaded, onLoaded)
    event.register(tes3.event.weatherTransitionStarted, onWeatherTransitionStarted)
    event.register(tes3.event.weatherTransitionFinished, onWeatherTransitionFinished)
    event.register(tes3.event.weatherChangedImmediate, onWeatherChangedImmediate)
end

event.register("modConfigReady", registerModConfig)
event.register(tes3.event.initialized, onInitialized)