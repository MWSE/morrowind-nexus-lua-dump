local defaultConfig = {
    enabled = true,
    enableCustomFog = true
}

local config = mwse.loadConfig("darknessoverdunbal", defaultConfig)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = "Darkness Over Dunbal" })
    template:saveOnClose("darknessoverdunbal", config)
    template:register()

    local page = template:createSideBarPage({ label = "Settings" })

    page.sidebar:createInfo({
        text = (
            "Darkness Over Dunbal v1.0.0\n"
            .. "By Team Ancestral Ghostbusters\n\n"
            .. "Various settings for lua additions to the mod\n\n"
        ),
    })

    local settings = page:createCategory("Settings")

    settings:createYesNoButton({
        label = "Enable MWSE Enhancements",
        description = "Enables custom AI frenzy behavior, weather and artifact mechanics.",
        variable = mwse.mcm.createTableVariable({
            id = "enabled",
            table = config
        }),
    })
    settings:createYesNoButton({
        label = "Enable Dynamic Fog",
        description = "Enables custom thick fog on the island. Results may vary, so you can turn it off if it looks bad.",
        variable = mwse.mcm.createTableVariable({
            id = "enableCustomFog",
            table = config
        }),
        callback = function()
            if config.enableCustomFog == true then tes3.setGlobal("AGB_EnableFog", 1) else tes3.setGlobal("AGB_EnableFog", 0) end
        end,
    })
end

local radiusMult = 3
local minResist = 50
local NAMIRAENCHANTMENT = "agb_handofnamira_en"
local MERIDIAOPALCHARM = "agb_amulet_meridia"
local OPALCHARMSPELL = "AGB_Opal_Charm_Cheat_Spell"
local CAZADORID = "skyrender"   --cazador
local dunbalFog = { landFogDayDepth = 3.0, landFogNightDepth = 3.0 }
local dunbalFogMGE = { distance = .01, offset = 80 }
local defaultFog = { landFogDayDepth = 1.0, landFogNightDepth = 1.9 }
local defaultFogMGE
if mge.enabled() then
	defaultFogMGE = mgeWeatherConfig.getDistantFog(tes3.weather.foggy)
end

local ssqn = include("SSQN.interop")

local function ssqnPatch()
    if (ssqn) then
		ssqn.registerQIcon("AGB_Mist_Dorans","\\Icons\\agb\\q\\DOD_Dorans.dds")
		ssqn.registerQIcon("AGB_Mist_Idols","\\Icons\\agb\\q\\DOD_Clav.dds")
		ssqn.registerQIcon("AGB_Mist_Justice","\\Icons\\agb\\q\\DOD_Justice.dds")
		ssqn.registerQIcon("AGB_Mist_Love","\\Icons\\agb\\q\\DOD_Love.dds")
		ssqn.registerQIcon("AGB_Mist_MQ","\\Icons\\agb\\q\\DOD.dds")
    end
end

local function iterReferenceList(list)
    local function iterator()
        local ref = list.head

        if list.size ~= 0 then
            coroutine.yield(ref)
        end

        while ref.nextNode do
            ref = ref.nextNode
            coroutine.yield(ref)
        end
    end
    return coroutine.wrap(iterator)
end

--- Taken from Tamriel Data common.lua
--- @param cell tes3cell
--- @param cellVisitTable table<tes3cell, boolean>|nil
--- @return tes3cell?
local function getExteriorCell(cell, cellVisitTable)
	if cell.isOrBehavesAsExterior then
		return cell
	end

	-- A hashset of cells that have already been checked, to prevent infinite loops and redundant checks.
	cellVisitTable = cellVisitTable or {}
	if (cellVisitTable[cell]) then
		return
	end
	cellVisitTable[cell] = true

	for ref in cell:iterateReferences(tes3.objectType.door) do
		if ref.destination and ref.destination.cell then
			local linkedExterior = getExteriorCell(ref.destination.cell, cellVisitTable)
			if (linkedExterior) then
				return linkedExterior
			end
		end
	end
end

--- Taken from Tamriel Data common.lua
-- Checks whether the player is loading into a cell with a suitable custom weather active so that particle settings are actually applied; this change is visible to the player, but is necessary and unavoidable until MWSE has proper support for custom weathers
---@param customWeather tes3weather
---@param isNext boolean
local function fixParticlesOnLoad(customWeather, isNext)
	local controller = customWeather.controller

	if not isNext then
		controller:switchImmediate(tes3.weather.clear)
		controller:updateVisuals()
		controller:switchImmediate(customWeather.index)
		controller:updateVisuals()
	else
        local ts = controller.transitionScalar
		controller:switchImmediate(controller.currentWeather.index)
		controller:updateVisuals()
        controller:switchTransition(customWeather.index)
        controller.transitionScalar = ts
	end
end

--- Taken and modified from Tamriel Data weather.lua
---@param weather tes3weather
---@param vanillaFog table
---@param mgeFog table
local function changeWeatherFog(weather, vanillaFog, mgeFog)
	weather.landFogDayDepth = vanillaFog.landFogDayDepth
	weather.landFogNightDepth = vanillaFog.landFogNightDepth

	if mge.enabled() then
		mge.weather.setDistantFog({ weather = weather.index, distance = mgeFog.distance, offset = mgeFog.offset })
	end
end

--- Taken and modified from Tamriel Data weather.lua
---@param e weatherChangedImmediateEventData
local function manageWeathers(e)
    if not config.enabled then return end

	if tes3.player.cell and not tes3.player.cell.isOrBehavesAsExterior then
		return	-- Don't bother with anything below if the player is entering a normal interior cell
	end

	local weather
	local nextWeather

	if not e.to then
		weather = tes3.getCurrentWeather()
		if weather.controller.nextWeather then
			nextWeather = weather.controller.nextWeather
		end
	else
		weather = e.to
	end

	local extCell = getExteriorCell(tes3.player.cell)	-- Should be more reliable than getRegion

	if extCell and extCell.region then
		if weather.name == "Foggy" or (nextWeather and nextWeather.name == "Foggy") then
			if extCell.region.id == "AGB Dunbal Region" or extCell.region.id == "AGB_Cove Region" or extCell.region.id == "AGB_Kilhaven Region" then
				changeWeatherFog(weather, dunbalFog, dunbalFogMGE)
				if not e.to and not e.previousCell then
					fixParticlesOnLoad(nextWeather, true)
				end
			else
				if weather.name == "Foggy" then
					changeWeatherFog(weather, defaultFog, defaultFogMGE)
				else
					changeWeatherFog(nextWeather, defaultFog, defaultFogMGE)
				end
			end
		end
	end
end

--- @param e spellResistEventData
local function handOfNamira(e)
    if not config.enabled then return end

    local effect = e.effect
    local ench = e.source
    if (effect.id == tes3.effect.frenzyCreature or effect.id == tes3.effect.frenzyHumanoid) and ench.id:lower() == NAMIRAENCHANTMENT then
        local target = e.target
        local mobile = target.mobile
        local magnitude = math.random(effect.min, effect.max) * effect.duration
	    local power = magnitude * (1 - e.resistedPercent/100)
        local minPower = (10 + target.object.level) * minResist
        local radius = magnitude * radiusMult
	    if power > minPower then
            mobile.actionData.aiBehaviorState = tes3.aiBehaviorState.attack
		    for _, cell in pairs(tes3.getActiveCells()) do
                for ref in iterReferenceList(cell.actors) do
                    if ref.mobile and not ref.mobile.isDead and ref ~= target and radius > target.position:distance(ref.position) then
                        mobile:startCombat(ref.mobile)
                    end
                end
            end
	    end
    end
end

--- @param e spellResistEventData
local function cazadorFrenzy(e)
    if not config.enabled then return end

    local effect = e.effect
    if effect.id == tes3.effect.sound then
        local target = e.target
        local mobile = target.mobile

        if not string.find(target.baseObject.id:lower(), CAZADORID) and target.baseObject.id ~= "AGB_Boss_4" then return end
        if not string.find(tes3.player.cell:lower(), "glinthollow") then return end

        local magnitude = math.random(effect.min, effect.max) * effect.duration
	    local power = magnitude * (1 - e.resistedPercent/100)
        local minPower = (10 + target.object.level) * minResist
        local radius = magnitude * radiusMult
	    if power > minPower then
            mobile.actionData.aiBehaviorState = tes3.aiBehaviorState.attack
		    for _, cell in pairs(tes3.getActiveCells()) do
                for ref in iterReferenceList(cell.actors) do
                    if ref.mobile and not ref.mobile.isDead and (string.find(ref.baseObject.id:lower(), CAZADORID) or ref.baseObject.id == "AGB_Boss_4" ) and ref ~= target and radius > target.position:distance(ref.position) then
                        mobile:startCombat(ref.mobile)
                    end
                end
            end
	    end
    end
end

--- @param e damageEventData
local function cheatDeath(e)
    if not config.enabled then return end
    local damage = e.damage
    local target = e.reference
    local mobile = e.mobile
    --- @type tes3clothing
    local amulet
    local amuletData

    local inv = target.object.inventory
    if not inv then return end

    for _, stack in pairs(inv) do
        local item = stack.object
        if item and item.id:lower() == MERIDIAOPALCHARM then
            local vars = stack.variables
            if vars and #vars > 0 then
                amulet = item
                amuletData = vars[1]
            else
                amuletData = tes3.addItemData{ to = target, item = item }
                amulet = item
            end
            break
        end
    end

    if not amulet then return end
    if not target.object:hasItemEquipped(MERIDIAOPALCHARM) then return end

    local ench = amulet.enchantment
    if not ench then return end

    local currentCharge = (amuletData and amuletData.charge) or ench.maxCharge or 0
    local cost = ench.chargeCost

    if damage >= mobile.health.current and currentCharge >= cost then
        amuletData.charge = currentCharge - cost
        e.damage = 0
        tes3.playSound{ sound = "AB_Thunderclap3" }
        tes3.createVisualEffect({
			lifespan = 3,
			object = "VFX_RestorationArea",
			reference = target,
			verticalOffset = 100
		})
        tes3.cast{
            reference = target,
            spell = tes3.getObject(OPALCHARMSPELL),
            alwaysSucceeds = true,
            instant = true
        }
    end
end

local function onInitialized()
    event.register("spellResist", handOfNamira)
    event.register("spellResist", cazadorFrenzy)
    event.register("damage", cheatDeath)
    event.register(tes3.event.loaded, function ()
        event.register(tes3.event.cellChanged, manageWeathers, { unregisterOnLoad = true })
	    event.register(tes3.event.weatherChangedImmediate, manageWeathers, { unregisterOnLoad = true })
	    event.register(tes3.event.weatherTransitionStarted, manageWeathers, { unregisterOnLoad = true })
    end)
    ssqnPatch()
    mwse.log("[AGB] initialized")
end
event.register("initialized", onInitialized)
event.register("modConfigReady", registerModConfig)