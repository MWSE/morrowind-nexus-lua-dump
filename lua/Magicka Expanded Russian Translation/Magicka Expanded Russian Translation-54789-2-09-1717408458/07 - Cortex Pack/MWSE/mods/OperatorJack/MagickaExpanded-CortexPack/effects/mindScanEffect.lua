local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("mindScan", 330)

local function addMindScanEffect()
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.mindScan,
		name = "Сканирование разума",
		description = "В активном состоянии позволяет заклинателю видеть заклинания в сознании других участников.",

		-- Basic dials.
		baseCost = 30.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        canCastSelf = true,
        hasNoMagnitude = true,
        hasContinuousVFX = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_crt_mindscan.dds",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = function(e) e:trigger() end,
	})
end

event.register("magicEffectsResolved", addMindScanEffect)

-- Register the GUI IDs for our custom tooltips feature.
local GUI_ID = nil
local function registerUi()
    GUI_ID = {}
    GUI_ID.container = tes3ui.registerID("OJ_ME_MS_Tooltip_Container")
end

local function createMindScanUi(reference, tooltip)
    if (GUI_ID == nil) then
        registerUi()
    end
    
    local spells = {}
    for spell in tes3.iterate(reference.object.spells.iterator) do
        if (spell.castType == tes3.spellType.power or
            spell.castType == tes3.spellType.spell) then
            table.insert(spells, spell)
        end
    end

    if (#spells == 0) then
        return
    end

    table.sort(spells, function(a, b) return a.name < b.name end)

    local container = tooltip:createBlock({id = GUI_ID.container} )    
    container.flowDirection = "top_to_bottom"
    container.childAlignX = 0
    container.autoHeight = true
    container.autoWidth = true

    local divider = container:createDivider()

    local label = container:createLabel({
        text = "Сканирование разума"
    })
    label.color = tes3ui.getPalette("header_color")
    label.wrapText = true

    for _, spell in pairs(spells) do
        local parent = container:createBlock()     
        parent.flowDirection = "left_to_right"
        parent.childAlignX = 0
        parent.autoHeight = true
        parent.autoWidth = true
 
        local label = parent:createLabel({
            text = string.format("%s - %sп", spell.name, spell.magickaCost)
        })
        label.wrapText = true
    end
end

local function onTooltipDrawn(e)
    local ref = e.reference
    local isAffectedByMindScan = tes3.isAffectedBy({
        reference = tes3.player,
        effect = tes3.effect.mindScan
    })

    -- Only show if mind scan is active.
    if (isAffectedByMindScan) then
        framework.debug("Affected by Mind Scan.")
        -- and target is valid.
        if (ref) then
            framework.debug("Target is valid.")
            -- and target is an NPC or creature.
            if (e.object.objectType == tes3.objectType.npc or
                e.object.objectType == tes3.objectType.creature) then
                    framework.debug("Target is actor.")
                -- and target is not dead.
                if (ref.mobile.isDead == false) then
                    framework.debug("Showing mind scan.")
                    createMindScanUi(ref, e.tooltip)
                end
            end
        end
    end
end

event.register("uiObjectTooltip", onTooltipDrawn, {priority=200})