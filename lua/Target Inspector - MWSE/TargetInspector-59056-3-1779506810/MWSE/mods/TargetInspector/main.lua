local modName = "Target Inspector"

local configModule = require("TargetInspector.config")
local config = configModule.current

require("TargetInspector.mcm")

local inspectorKeyHeld = false
local currentTarget = nil

local UI_ID_InspectorMenu = tes3ui.registerID("TargetInspector:Menu")

local inspectorWidth = 420
local inspectorHeight = 620

-- Move these if needed.
local inspectorX = 760
local inspectorY = 220

local function safeGet(object, key)
    if not object then
        return nil
    end

    local ok, value = pcall(function()
        return object[key]
    end)

    if ok then
        return value
    end

    return nil
end

local function getStatisticCurrent(stat)
    if not stat then
        return 0
    end

    return safeGet(stat, "current")
        or safeGet(stat, "value")
        or safeGet(stat, "base")
        or 0
end

local function getStatisticBase(stat)
    if not stat then
        return 0
    end

    return safeGet(stat, "base")
        or safeGet(stat, "current")
        or safeGet(stat, "value")
        or 0
end

local function getReference(e)
    if e and e.reference then
        return e.reference
    end

    -- Fallback for actors/creatures that do not pass cleanly through tooltip.
    return tes3.getPlayerTarget()
end

local function getMobile(reference)
    if not reference then
        return nil
    end

    if reference == tes3.player then
        return tes3.mobilePlayer
    end

    return reference.mobile
end

local function getObjectTypeName(reference)
    if not reference or not reference.object then
        return "Unknown"
    end

    if reference.object.objectType == tes3.objectType.npc then
        return "NPC"
    end

    if reference.object.objectType == tes3.objectType.creature then
        return "Creature"
    end

    return tostring(reference.object.objectType)
end

local function destroyInspector()
    local menu = tes3ui.findMenu(UI_ID_InspectorMenu)

    if menu then
        menu:destroy()
    end

    currentTarget = nil
end

local function addLine(parent, text)
    local label = parent:createLabel({
        text = text,
    })

    label.wrapText = true
    label.width = inspectorWidth - 40

    return label
end

local function addDivider(parent)
    addLine(parent, "------------------------------")
end

local function addVitals(parent, reference, mobile)
    local object = reference.object

    addLine(parent, string.format("Type: %s", getObjectTypeName(reference)))

	if object and object.class then
		addLine(parent, string.format(
			"Class: %s",
			object.class.name or object.class.id or "Unknown"
		))
	end

    if object and object.level then
        addLine(parent, string.format("Level: %s", tostring(object.level)))
    end

    if mobile.health then
        addLine(parent, string.format(
            "Health: %.0f / %.0f",
            getStatisticCurrent(mobile.health),
            getStatisticBase(mobile.health)
        ))
    end

    if mobile.magicka then
        addLine(parent, string.format(
            "Magicka: %.0f / %.0f",
            getStatisticCurrent(mobile.magicka),
            getStatisticBase(mobile.magicka)
        ))
    end

    if mobile.fatigue then
        addLine(parent, string.format(
            "Fatigue: %.0f / %.0f",
            getStatisticCurrent(mobile.fatigue),
            getStatisticBase(mobile.fatigue)
        ))
    end
end

local function addAttributes(parent, mobile)
    local attributes = {
        { "STR", "strength" },
        { "INT", "intelligence" },
        { "WIL", "willpower" },
        { "AGI", "agility" },
        { "SPD", "speed" },
        { "END", "endurance" },
        { "PER", "personality" },
        { "LUC", "luck" },
    }

    addLine(parent, "Attributes:")

    for _, pair in ipairs(attributes) do
        local label = pair[1]
        local key = pair[2]
        local stat = mobile[key]

        addLine(parent, string.format(
            "%s: %.0f",
            label,
            getStatisticCurrent(stat)
        ))
    end
end

local function addSkills(parent, mobile)
    if not mobile.skills then
        addLine(parent, "Skills: unavailable")
        return
    end

    addLine(parent, "Skills:")

    for skillId = 0, 26 do
        local skillData = mobile.skills[skillId + 1]

        if skillData then
            local skillName = tes3.skillName[skillId] or tostring(skillId)
            local skillValue = getStatisticCurrent(skillData)

            addLine(parent, string.format(
                "%s: %.0f",
                skillName,
                skillValue
            ))
        end
    end
end

local function showInspector(reference)
    if not reference or not reference.object then
        destroyInspector()
        return
    end

    local objectType = reference.object.objectType

    if objectType ~= tes3.objectType.npc and objectType ~= tes3.objectType.creature then
        destroyInspector()
        return
    end

    local mobile = getMobile(reference)

    if not mobile then
        destroyInspector()
        return
    end

    -- Don't rebuild constantly for the same target.
    if currentTarget == reference and tes3ui.findMenu(UI_ID_InspectorMenu) then
        return
    end

    destroyInspector()
    currentTarget = reference

    local menu = tes3ui.createMenu({
        id = UI_ID_InspectorMenu,
        fixedFrame = true,
    })

    menu.width = inspectorWidth
    menu.height = inspectorHeight
    menu.flowDirection = tes3.flowDirection.topToBottom

    menu.paddingTop = 12
    menu.paddingBottom = 12
    menu.paddingLeft = 12
    menu.paddingRight = 12

    menu.positionX = inspectorX
    menu.positionY = inspectorY

    local title = menu:createLabel({
        text = reference.object.name or reference.object.id or "Unknown",
    })

    title.wrapText = true
    title.width = inspectorWidth - 40

    addDivider(menu)
    addLine(menu, "Target Inspector")

    if config.showVitals then
        addDivider(menu)
        addVitals(menu, reference, mobile)
    end

    if config.showAttributes then
        addDivider(menu)
        addAttributes(menu, mobile)
    end

    if config.showSkills and objectType == tes3.objectType.npc then
        addDivider(menu)
        addSkills(menu, mobile)
    end

    menu:updateLayout()
end

local function onObjectTooltip(e)
    if not config.enabled or not inspectorKeyHeld then
        return
    end

    showInspector(getReference(e))
end

event.register(tes3.event.uiObjectTooltip, onObjectTooltip)

-- Fallback check while holding the configured key.
-- This helps with creatures or actors that do not provide e.reference in tooltip events.
event.register(tes3.event.simulate, function()
    if not config.enabled or not inspectorKeyHeld then
        return
    end

    local target = tes3.getPlayerTarget()

    if target then
        showInspector(target)
    else
        destroyInspector()
    end
end)

event.register(tes3.event.keyDown, function(e)
    if tes3.isKeyEqual({ expected = config.inspectKey, actual = e }) then
        inspectorKeyHeld = true
    end
end)

event.register(tes3.event.keyUp, function(e)
    if tes3.isKeyEqual({ expected = config.inspectKey, actual = e }) then
        inspectorKeyHeld = false
        destroyInspector()
    end
end)

mwse.log("[%s] Initialized.", modName)