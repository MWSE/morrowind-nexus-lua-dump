local mod = {
    name = "Robe-n-Hood",
    ver = 1.0
}

local staticConfig = require("RobenHood.staticConfig")

local cf = mwse.loadConfig(mod.name, staticConfig.defaultConfig)

local logger = require("logging.logger").new{
    name = "Robe-n-Hood",
    logLevel = cf.logLevel
}

local function removeHelm(ref)
    local helmet = tes3.getEquippedItem{actor = ref, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet}
    if helmet and ref.sceneNode and ref.mobile then
        tes3.removeItem{reference = ref, item = helmet.object, itemData = helmet.itemData, playSound = false, reevaluateEquipment = true}
    end
end

---@param npc tes3reference
local function isNPCValid(npc)
    local npcIsValid = npc
        and npc.mobile
        and npc.baseObject.objectType == tes3.objectType.npc
        and (not npc.mobile.isDead)
        and (npc.object and not npc.object.isGuard)
        and (npc.object.class.id ~= "Slave")
        and (npc.object.class.id ~= "Dreamers")
    logger:trace("%s is %svalid", npc, npcIsValid and "" or "not ")
    return npcIsValid
end

local function rollForHood()
    local roll = math.random(100)
    logger:trace("Roll: %d", roll)
    return roll <= cf.slider
end

local function isBadWeather(weather)
    weather = weather or tes3.getCurrentWeather()
    local weatherIsBad = staticConfig.itemWeatherMap[weather.index] ~= nil
    logger:trace("%s is %sbad weather", weather, weatherIsBad and "" or "not ")
    return weatherIsBad
end

local function isOutdoors(npc)
    local npcOutdoors = (not npc.cell.isInterior) and (not npc.cell.behavesAsExterior)
    logger:trace("%s is %soutdoors", npc, npcOutdoors and "" or "not ")
    return npcOutdoors
end

local function getHoodForRobedNPC(npc)
    local robe = tes3.getEquippedItem{actor = npc, objectType = tes3.objectType.clothing, slot = tes3.clothingSlot.robe}
    local robeHood = robe and staticConfig.robeHoodMap[robe.object.id]
    logger:trace("%s's hood is %s", npc, robeHood)
    return robeHood
end

local function isRobedNPC(npc)
    local isRobed = getHoodForRobedNPC(npc) ~= nil
    logger:trace("%s is %srobed", npc, isRobed and "" or "not ")
    return isRobed
end

local function getHatFromWeather(npc, weather)
    logger:trace("Getting hat from weather")
    local item
    local itemConf = staticConfig.itemWeatherMap[weather.index]
    if itemConf  then
        local leveledItemId = itemConf.item
        if itemConf.femaleItem and npc.object.female then
            leveledItemId = itemConf.femaleItem
        end
        logger:debug("findHat: Found leveled item %s for weather %s for npc %s", leveledItemId, weather.name, npc)
        ---@type tes3leveledItem
        local leveledItem = tes3.getObject(leveledItemId)
        local pick = leveledItem:pickFrom()
        if pick then
            item = pick.id
            logger:debug("findHat: Picked %s", item)
        else
            logger:debug("findHat: leveledItem.pick returned nil")
        end
        return item
    end
end


local function alreadyHasHelm(npc)
    if npc.data.jett_permanentHelm == nil then
        local hasHelmet = tes3.getEquippedItem{actor = npc, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet} ~= nil
        npc.data.jett_permanentHelm = hasHelmet
        return hasHelmet
    else
        return npc.data.jett_permanentHelm
    end
end



---@param npc tes3reference
---@param weather tes3weather
---@return string|nil item The id of the chosen headgear, or nil if no headgear was chosen
local function findHat(npc, weather)
    logger:debug("findHat: finding hat for %s in weather %s", npc, weather.name)
    local item = getHoodForRobedNPC(npc)
    if item == nil and not alreadyHasHelm(npc) then
        item = getHatFromWeather(npc, weather)
    end
    return item
end



local function checkDoAddHelm(npc, weather)
    if isRobedNPC(npc) then
        if rollForHood() then
            return true
        elseif isBadWeather(weather) and isOutdoors(npc) then
            return true
        end
    elseif not alreadyHasHelm(npc) then
        if isBadWeather(weather) and isOutdoors(npc) then
            return true
        end
    end
    return false
end

---@param npc tes3reference
---@param weather tes3weather|nil
local function updateNPCHeadgear(npc, weather)
    weather = weather or tes3.getCurrentWeather()
    logger:debug("updating headgear for %s in weather %s", npc, weather and weather.name)
    --Check the NPC is really an fully initialised NPC
    if isNPCValid(npc) then
        logger:debug("%s is valid", npc)
        if not alreadyHasHelm(npc) then
            logger:debug("Removing current helm")
            removeHelm(npc)
        end
        if checkDoAddHelm(npc, weather) then
            logger:debug("Do add helm")
            local hat = findHat(npc, weather)
            if hat then
                logger:debug("equipping %s to %s", hat, npc)
                npc.mobile:equip{item = hat, addItem = true}
            end
        end
    end
end

---@param e weatherTransitionFinishedEventData
local function updateHeadGearOnWeatherTransition(e)
    logger:debug("updateHeadGearOnWeatherTransition: Weather is %s, setting NPC hats", e.to.name)
    for _,cell in pairs(tes3.getActiveCells()) do
        for npc in cell:iterateReferences(tes3.objectType.npc) do
            updateNPCHeadgear(npc, e.to)
        end
    end
end

---@param e mobileActivatedEventData
local function updateHeadGearOnMobileActivated(e)
    updateNPCHeadgear(e.reference)
end

local function checkESPsActive()
    for _, esp in ipairs(staticConfig.esps) do
        if not tes3.isModActive(esp) then
            return false
        end
    end
    return true
end

local function registerModConfig()
    if checkESPsActive() then
        local template = mwse.mcm.createTemplate(mod.name)
        template:saveOnClose(mod.name, cf)
        template:register()
        local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
        local category = page:createCategory(" ")
        category:createSlider{label = "Hood Density: %s%%", description = "Set the chance of an OAAB hood appearing on an NPC wearing a robe regardless of the weather.", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}
        page:createDropdown{
            label = "Log Level",
            description = "Set the logging level for mwse.log: Keep on INFO unless you are debugging.",
            options = {
                { label = "TRACE", value = "TRACE"},
                { label = "DEBUG", value = "DEBUG"},
                { label = "INFO", value = "INFO"},
                { label = "ERROR", value = "ERROR"},
                { label = "NONE", value = "NONE"},
            },
            variable = mwse.mcm.createTableVariable{ id = "logLevel", table = cf },
            callback = function(self)
                logger:setLogLevel(self.variable.value)
            end
        }
    end
end
event.register("modConfigReady", registerModConfig)

local function initialized()
    if checkESPsActive() then
        event.register("weatherTransitionFinished", updateHeadGearOnWeatherTransition)
        event.register("weatherChangedImmediate", updateHeadGearOnWeatherTransition)
        event.register("mobileActivated", updateHeadGearOnMobileActivated, { priority = -10 })
        print(mod.name.." "..mod.ver.." Initialized!")
    else
        logger:warn("Required ESPs/ESMs are not active, not initializing.")
    end
end
event.register("initialized", initialized)
