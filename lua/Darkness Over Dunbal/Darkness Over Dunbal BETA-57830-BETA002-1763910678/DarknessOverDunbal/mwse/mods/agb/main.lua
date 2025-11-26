local defaultConfig = {
    enabled = true
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
        variable = mwse.mcm.createTableVariable({
            id = "enabled",
            table = config
        }),
    })
end

local radiusMult = 3
local minResist = 50
local NAMIRAENCHANTMENT = "agb_handofnamira_en"
local MERIDIAOPALCHARM = "agb_amulet_meridia"
local OPALCHARMSPELL = "AGB_Opal_Charm_Cheat_Spell"
local CAZADORID = "cazador"

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

        if not string.find(target.baseObject.id, CAZADORID) and target.baseObject.id ~= "AGB_Boss4" then return end

        local magnitude = math.random(effect.min, effect.max) * effect.duration
	    local power = magnitude * (1 - e.resistedPercent/100)
        local minPower = (10 + target.object.level) * minResist
        local radius = magnitude * radiusMult
	    if power > minPower then
            mobile.actionData.aiBehaviorState = tes3.aiBehaviorState.attack
		    for _, cell in pairs(tes3.getActiveCells()) do
                for ref in iterReferenceList(cell.actors) do
                    if ref.mobile and not ref.mobile.isDead and (string.find(ref.baseObject.id, CAZADORID) or ref.baseObject.id == "AGB_Boss4" ) and ref ~= target and radius > target.position:distance(ref.position) then
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
    mwse.log("[AGB] initialized")
end
event.register("initialized", onInitialized)
event.register("modConfigReady", registerModConfig)