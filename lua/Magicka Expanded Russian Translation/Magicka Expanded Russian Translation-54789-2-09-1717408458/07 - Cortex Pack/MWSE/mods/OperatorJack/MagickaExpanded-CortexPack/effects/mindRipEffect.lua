local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("mindRip", 331)

local menu
local GUI_ID = nil
local function registerUi()
    GUI_ID = {}
    GUI_ID.menu = tes3ui.registerID("OJ_ME_MR_Menu")
    GUI_ID.menuList = tes3ui.registerID("OJ_ME_MR_MenuList")
    GUI_ID.container = tes3ui.registerID("OJ_ME_MR_Container")
    GUI_ID.listPane = tes3ui.registerID("OJ_ME_MR_ListPane")
    GUI_ID.cancelBtn = tes3ui.registerID("OJ_ME_MR_CancelBtn")
end

local function onCancel()
    menu = tes3ui.findMenu(GUI_ID.menu)
    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

local function showCheckFailedTooltip(e)
    local tooltip = tes3ui.createTooltipMenu()
    local label = tooltip:createLabel({
        text = "Вы недостаточно умны, чтобы понять это заклинание."
    })
    label.color = tes3ui.getPalette("header_color")
end

local function showCheckPassedTooltip(e)
    local spell = e.source:getPropertyObject("OJ_ME_MR:Spell")
    local tooltip = tes3ui.createTooltipMenu()
    tooltip.autoWidth = true
    tooltip.autoHeight = true

    local label = tooltip:createLabel({
        text = spell.name
    })
    label.color = tes3ui.getPalette("header_color")

    local effectsContainer = tooltip:createBlock()
    effectsContainer.flowDirection = "top_to_bottom"
    effectsContainer.childAlignX = 0
    effectsContainer.autoWidth = true
    effectsContainer.autoHeight = true
    effectsContainer.widthProportional = 1.0

    for i=1, spell:getActiveEffectCount() do
        local effect = tes3.getMagicEffect(spell.effects[i].id)

        if (effect == nil) then
            return
        end
        

        local effectContainer = effectsContainer:createBlock()
        effectContainer.flowDirection = "left_to_right"
        effectContainer.childAlignX = 0
        effectContainer.autoWidth = true
        effectContainer.autoHeight = true
        effectContainer.borderAllSides = 3

        local image = effectContainer:createImage({
            path=("icons\\" .. effect.icon)
        })
        image.wrapText = false
        image.borderLeft = 4

        local label = effectContainer:createLabel({
            text = effect.name
        })
        label.wrapText = false
        label.borderLeft = 6
    end

    local divider = tooltip:createDivider()
    local label = tooltip:createLabel({
        text = string.format("Стоимость обучения: %sп", spell.magickaCost * 2)
    })
    label.borderLeft = 4
    label.borderBottom = 4
    label.borderRight = 4
    label.borderTop = 4
end

local function onSpellSelected(e)
    menu = tes3ui.findMenu(GUI_ID.menu)

    -- Process selected spell.
    local spell = e.source:getPropertyObject("OJ_ME_MR:Spell")
    local learnCost = spell.magickaCost * 2
    local newMagicka = tes3.mobilePlayer.magicka.current - learnCost

    if (newMagicka >= 0) then
        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            name = "magicka",
            current = newMagicka * -1
        })

        mwscript.addSpell({
            reference = tes3.player,
            spell = spell
        })

        tes3.messageBox("Вы успешно выучили заклинание.")
    else
        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            name = "magicka",
            current = tes3.mobilePlayer.magicka.current * -1
        })

        tes3.messageBox("Вам не удалось выучить заклинание.")
    end
    
    tes3ui.forcePlayerInventoryUpdate()
    tes3ui.leaveMenuMode()
    menu:destroy()
end

local function showUi(reference)
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
        tes3.messageBox("У цели нет заклинаний, которые вы могли бы взять.")
        return
    end

    table.sort(spells, function(a, b) return a.name < b.name end)

    if (tes3ui.findMenu(GUI_ID.menu) ~= nil) then
        return
    end

    menu = tes3ui.createMenu({
        id = GUI_ID.menu,
        dragFrame = true
    })
    menu.text = "Разрыв разума"
    menu.alpha = 0.75
    menu.width = 400
    menu.height = 500
    menu.minWidth = 400
    menu.minHeight = 500
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2

    local listPane = menu:createVerticalScrollPane({
        id = GUI_ID.listPane
    })
    for _, spell in pairs(spells) do
        local parent = listPane:createBlock()     
        parent.flowDirection = "left_to_right"
        parent.childAlignX = 0
        parent.autoHeight = true
        parent.borderAllSides = 3
        parent.widthProportional = 1.0
        parent:setPropertyObject("OJ_ME_MR:Spell", spell)
 
        if (spell.magickaCost / tes3.mobilePlayer.intelligence.current > 2.0) then
            local label = parent:createLabel({
                text = string.format("%s", spell.name)
            })
            label.font = 2
            label.wrapText = true

            parent:register("help", showCheckFailedTooltip)
        else
            local label = parent:createLabel({
                text = string.format("%s - %sп", spell.name, spell.magickaCost)
            })
            label.wrapText = true
    
            parent:register("mouseClick", onSpellSelected)
            parent:register("help", showCheckPassedTooltip)
        end
    end

    local buttons = menu:createBlock()
    buttons.widthProportional = 1.0
    buttons.autoHeight = true
    buttons.childAlignX = 1.0

    local cancelButton = buttons:createButton({
        id = GUI_ID.cancelBtn,
        text = tes3.findGMST("sCancel").value
    })
    cancelButton:register("mouseClick", onCancel)

    menu:updateLayout()
    tes3ui.enterMenuMode(GUI_ID.menu)
end


local function onMindRipTick(e)
    if (not e:trigger()) then
        return
    end

    showUi(e.effectInstance.target)

    e.sourceInstance.state = tes3.spellState.retired
end

local function addMindRipEffect()
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.mindRip,
		name = "Разрыв разума",
		description = "Позволяет заклинателю просмотреть заклинания цели и украсть одно из них, если он может.",

		-- Basic dials.
		baseCost = 60.0,

		-- Various flags.
        canCastTouch = true,
        hasNoMagnitude = true,
        isHarmful = true,
        appliedOnce = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_crt_mindrip.dds",
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onMindRipTick,
	})
end

event.register("magicEffectsResolved", addMindRipEffect)