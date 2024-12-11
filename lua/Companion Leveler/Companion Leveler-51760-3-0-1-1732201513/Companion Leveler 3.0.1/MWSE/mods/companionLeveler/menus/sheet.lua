--local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local abilityList = require("companionLeveler.menus.abilityList")
local spellList = require("companionLeveler.menus.spellList")
local specialList = require("companionLeveler.menus.specialList")
local growth = require("companionLeveler.menus.growthSettings")


local sheet = {}


function sheet.createWindow(reference)
    sheet.id_menu = tes3ui.registerID("kl_sheet_menu")
    sheet.id_label = tes3ui.registerID("kl_sheet_label")
    sheet.id_label2 = tes3ui.registerID("kl_sheet_label2")
    sheet.id_sheet = tes3ui.registerID("kl_sheet_sheet")
    sheet.id_title = tes3ui.registerID("kl_sheet_title")
    sheet.id_lvl = tes3ui.registerID("kl_sheet_lvl_txt")
    sheet.id_hth = tes3ui.registerID("kl_sheet_hth_bar")
    sheet.id_mgk = tes3ui.registerID("kl_sheet_mgk_bar")
    sheet.id_fat = tes3ui.registerID("kl_sheet_fat_bar")
    sheet.id_tp = tes3ui.registerID("kl_sheet_tp_bar")
    sheet.id_ok = tes3ui.registerID("kl_sheet_ok_btn")
    sheet.id_original = tes3ui.registerID("kl_sheet_orig_btn")
    sheet.id_current = tes3ui.registerID("kl_sheet_current_btn")
    sheet.id_ideal = tes3ui.registerID("kl_sheet_ideal_btn")
    sheet.id_growth = tes3ui.registerID("kl_sheet_growth_btn")
    sheet.id_ability = tes3ui.registerID("kl_sheet_ability_btn")
    sheet.id_spell = tes3ui.registerID("kl_sheet_spell_btn")
    sheet.id_special = tes3ui.registerID("kl_sheet_special_btn")

    local root = require("companionLeveler.menus.root")
    local viewportWidth, viewportHeight = tes3ui.getViewportSize()

    log = logger.getLogger("Companion Leveler")
    log:debug("Character sheet menu initialized.")

    if (reference) then
        sheet.reference = reference
    end

    local menu = tes3ui.createMenu { id = sheet.id_menu, dragFrame = true }
    menu.minWidth = 495
    menu.maxWidth = 495
    menu.minHeight = 440
    menu.maxHeight = 920
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5
    menu.width = viewportWidth * 0.95
    menu.height = viewportHeight * 0.95
    menu.text = reference.object.name

    local modData = func.getModData(reference)
    local attTable = reference.mobile.attributes
    local faction = reference.object.faction

    --Fix right click bullshit
    menu:register("unfocus", function(e)
        return false
    end)

    -- Create layout
    local label = menu:createLabel { text = "Current Statistics:", id = sheet.id_label }
    label.wrapText = true
    label.justifyText = "center"
    local label2 = menu:createLabel { text = "(current value / base value)", id = sheet.id_label2 }
    label2.wrapText = true
    label2.justifyText = "center"
    label2.borderBottom = 12


    local sheet_block = menu:createBlock { id = "text_block_sheet" }
    sheet_block.autoWidth = true
    sheet_block.autoHeight = true
    sheet_block.widthProportional = 1.0
    sheet_block.heightProportional = 1.0

    local border = sheet_block:createThinBorder {}
    border.widthProportional = 1.0
    border.heightProportional = 1.0
    border.width = 469
    border.height = 769
    border.maxHeight = 778
    border.paddingAllSides = 4
    border.flowDirection = "top_to_bottom"

    local mainScroll = border:createVerticalScrollPane({})
    mainScroll.width = 469
    mainScroll.height = 778
    mainScroll.maxHeight = 778


    ----Headers-----------------------------------------------------------------------------------------------
    local title = mainScroll:createThinBorder {}
    title.width = 440
    title.height = 40

    local txt = ""
    if reference.object.objectType == tes3.objectType.creature then
        txt = modData.type
    else
        sheet.class = tes3.findClass(modData.class)
        txt = sheet.class.name
    end

    local titleLabel = title:createLabel({ text = "" .. reference.object.name .. ", the " .. txt .. "",
        id = sheet.id_title })
    titleLabel.wrapText = true
    titleLabel.justifyText = "center"
    titleLabel.borderTop = 8
    titleLabel.color = tables.colors["white"]

    local header = mainScroll:createThinBorder {}
    header.width = 440
    header.height = 32
    header.flowDirection = "left_to_right"

    local attHead = header:createThinBorder {}
    attHead.width = 220
    attHead.height = 32

    local attHeadLabel = attHead:createLabel({ text = "Attributes" })
    attHeadLabel.wrapText = true
    attHeadLabel.justifyText = "center"
    attHeadLabel.borderTop = 6
    attHeadLabel.color = tables.colors["white"]

    local skillHead = header:createThinBorder {}
    skillHead.width = 220
    skillHead.height = 32

    local skillHeadLabel = skillHead:createLabel({ text = "Skills" })
    skillHeadLabel.wrapText = true
    skillHeadLabel.justifyText = "center"
    skillHeadLabel.borderTop = 6
    skillHeadLabel.color = tables.colors["white"]

    if reference.object.objectType == tes3.objectType.creature then
        skillHeadLabel.text = "Type Levels"
    end

    ----Content Blocks------------------------------------------------------------------------------------------------------
    local main = mainScroll:createThinBorder {}
    main.width = 440
    main.height = 697
    main.flowDirection = "left_to_right"

    local leftBlock = main:createThinBorder { id = "text_block_sheet_left" }
    leftBlock.flowDirection = "top_to_bottom"
    leftBlock.width = 220
    leftBlock.height = 697

    local rightBlock = main:createThinBorder { id = "text_block_sheet_right" }
    rightBlock.flowDirection = "top_to_bottom"
    rightBlock.width = 220
    rightBlock.height = 697

    ----Attribute Block---------------------------------------------------------------------------------------------------

    sheet.lvl = leftBlock:createLabel({ text = "Level: " .. modData.level .. "", id = sheet.id_lvl })
    sheet.lvl.borderTop = 10
    sheet.lvl.wrapText = true
    sheet.lvl.justifyText = "center"

    sheet.hth = leftBlock:createFillBar({ current = reference.mobile.health.current, max = reference.mobile.health.base,
        id = sheet.id_hth })
    func.configureBar(sheet.hth, "standard", "red")
    sheet.hth.borderTop = 10
    sheet.hth.borderLeft = 20
    sheet.hth.borderBottom = 4

    sheet.mgk = leftBlock:createFillBar({ current = reference.mobile.magicka.current, max = reference.mobile.magicka.base, id = sheet.id_mgk })
    func.configureBar(sheet.mgk, "standard", "blue")
    sheet.mgk.borderLeft = 20
    sheet.mgk.borderBottom = 4

    sheet.fat = leftBlock:createFillBar({ current = reference.mobile.fatigue.current, max = reference.mobile.fatigue.base, id = sheet.id_fat })
    func.configureBar(sheet.fat, "standard", "green")
    sheet.fat.borderLeft = 20
    sheet.fat.borderBottom = 2

    sheet.tp = leftBlock:createFillBar({ current = modData.tp_current, max = modData.tp_max, id = sheet.id_tp })
    func.configureBar(sheet.tp, "standard", "purple")
    sheet.tp.borderLeft = 20
    sheet.tp.borderBottom = 2
    sheet.tp.borderTop = 2

    leftBlock:createDivider()

    for i = 0, 7 do
        local attList = leftBlock:createLabel({ text = "" ..
            tables.capitalization[i] ..
            ": " .. math.round(attTable[i + 1].current) .. " / " .. attTable[i + 1].base .. "",
            id = "kl_sheet_att_" .. i .. "" })
        attList.borderTop = 4
        attList.borderLeft = 8

        if attTable[i + 1].current < attTable[i + 1].base then
            attList.color = tables.colors["red"]
        end
        if attTable[i + 1].current > attTable[i + 1].base then
            attList.color = tables.colors["green"]
        end
    end

    ----Background Block----------------------------------------------------------------------------------------------------------------
    local backgroundHead = leftBlock:createThinBorder {}
    backgroundHead.width = 220
    backgroundHead.height = 32
    backgroundHead.borderTop = 18

    local backgroundHeadLabel = backgroundHead:createLabel({ text = "Background" })
    backgroundHeadLabel.wrapText = true
    backgroundHeadLabel.justifyText = "center"
    backgroundHeadLabel.borderTop = 6
    backgroundHeadLabel.color = tables.colors["white"]

    local txt_2 = ""
    if reference.object.objectType == tes3.objectType.creature then
        txt_2 = "Race: Creature"
    else
        txt_2 = "Race: " .. reference.object.race.name .. ""
    end

    local raceLabel = leftBlock:createLabel({ text = txt_2 })
    raceLabel.borderAllSides = 4
    raceLabel.wrapText = true

    local txt_3 = ""
    if reference.object.objectType == tes3.objectType.creature then
        local defType = func.determineDefault(reference)
        txt_3 = "Original Type: " .. defType .. ""
    else
        txt_3 = "Original Class: " .. reference.object.class.name .. ""
    end

    local origLabel = leftBlock:createLabel({ text = txt_3 })
    origLabel.borderAllSides = 4
    origLabel.wrapText = true

    local factionLabel = leftBlock:createLabel({ text = "Faction: None" })
    factionLabel.borderAllSides = 4
    factionLabel.wrapText = true

    if faction ~= nil then
        factionLabel.text = "Faction: " .. faction:getRankName(reference.baseObject.factionRank) .. " of " .. reference.object.faction.name .. ""
    end

    local button_ability = leftBlock:createButton { id = sheet.id_ability, text = "Ability List" }
    button_ability.borderLeft = 57

    local button_spell = leftBlock:createButton { id = sheet.id_spell, text = "Spell List" }
    button_spell.borderLeft = 64

    local button_special = leftBlock:createButton { id = sheet.id_special, text = "Special" }
    button_special.borderLeft = 74

    ----Command Block---------------------------------------------------------------------------------------------------------------------------
    local commandHead = leftBlock:createThinBorder {}
    commandHead.width = 220
    commandHead.height = 32
    commandHead.borderTop = 8

    local commandHeadLabel = commandHead:createLabel({ text = "Pages" })
    commandHeadLabel.wrapText = true
    commandHeadLabel.justifyText = "center"
    commandHeadLabel.borderTop = 6
    commandHeadLabel.color = tables.colors["white"]

    local button_current = leftBlock:createButton { id = sheet.id_current, text = "Current" }
    button_current.borderLeft = 73
    button_current.borderTop = 10
    button_current.widget.state = 4

    local button_ideal = leftBlock:createButton { id = sheet.id_ideal, text = "Ideal" }
    button_ideal.borderLeft = 83

    local button_original = leftBlock:createButton { id = sheet.id_original, text = "Original" }
    button_original.borderLeft = 71

    ----Skill Block--------------------------------------------------------------------------------------------------------
    if reference.object.objectType == tes3.objectType.creature then
        for i = 1, #tables.typeTable do
            local typeList = rightBlock:createLabel({ text = "" .. tables.typeTable[i] .. ": Level " .. modData.typelevels[i] .. "", id = "kl_sheet_creType_" .. i .. "" })
            typeList.wrapText = true
            typeList.justifyText = "center"
            typeList.color = tables.colors["grey"]
            typeList.borderTop = 8
            if i == 1 then
                typeList.borderTop = 12
            end

            if modData.typelevels[i] > 1 then
                typeList.color = tables.colors["white"]
            end

            if modData.typelevels[i] >= 20 then
                typeList.color = tables.colors["gold"]
                typeList.text = "" .. tables.typeTable[i] .. ": Level " .. modData.typelevels[i] .. " (Mastered)"
            end
        end
    else
        local ignoreLabel = rightBlock:createLabel({ text = "Ignored Skill: None", id = "kl_sheet_ignore_label" })
        ignoreLabel.borderTop = 10
        ignoreLabel.color = tables.colors["yellow"]
        ignoreLabel.wrapText = true
        ignoreLabel.justifyText = "center"
        func.clTooltip(ignoreLabel, "ignore_skill")

        if modData.ignore_skill ~= 99 then
            ignoreLabel.text = "Ignored Skill: " .. tes3.getSkillName(modData.ignore_skill) .. ""
        end

        for i = 0, 26 do
            if i == 9 or i == 18 then
                rightBlock:createDivider()
            end
            local tempSkill = reference.mobile:getSkillStatistic(i)
            local skillList = rightBlock:createTextSelect({ text = "" ..
                tes3.getSkillName(i) .. ": " .. tempSkill.current .. " / " .. tempSkill.base .. "",
                id = "kl_sheet_skill_" .. i .. "" })
            skillList.wrapText = true
            skillList.justifyText = "center"
            skillList.borderBottom = 1
            if tempSkill.current < tempSkill.base then
                skillList.widget.idle = tables.colors["red"]
            end
            if tempSkill.current > tempSkill.base then
                skillList.widget.idle = tables.colors["green"]
            end
            if i == modData.ignore_skill then
                skillList.widget.idle = tables.colors["yellow"]
            end
            skillList:register("mouseClick", function() sheet.onIgnore(i) end)
        end

        local listTop = menu:findChild("kl_sheet_skill_0")
        listTop.borderTop = 40

        local lastCombat = menu:findChild("kl_sheet_skill_8")
        lastCombat.borderBottom = 6

        local lastMagic = menu:findChild("kl_sheet_skill_17")
        lastMagic.borderBottom = 6
    end

    ----Bottom Button Block-----------------------------------------------------------------------------------------
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 1.0
    button_block.borderTop = 12

    local button_root = button_block:createButton { text = "Main Menu" }
    button_root.borderRight = 29

    local button_fix = button_block:createButton { id = sheet.id_fix, text = "Fix Stats" }
    button_fix.borderRight = 29

    local button_growth = button_block:createButton { id = sheet.id_growth, text = "Growth Settings" }
    button_growth.borderRight = 29

    local button_ok = button_block:createButton { id = sheet.id_ok, text = tes3.findGMST("sOK").value }

    -- Events
    button_ok:register(tes3.uiEvent.mouseClick, sheet.onOK)
    button_original:register(tes3.uiEvent.mouseClick, sheet.onOriginal)
    button_current:register(tes3.uiEvent.mouseClick, sheet.onCurrent)
    button_ideal:register(tes3.uiEvent.mouseClick, sheet.onIdeal)
    button_fix:register(tes3.uiEvent.mouseClick, sheet.onFix)
    button_growth:register("mouseClick", function() menu:destroy() growth.createWindow(reference) end)
    button_root:register("mouseClick", function() menu:destroy() root.createWindow(reference) end)
    button_ability:register("mouseClick", function() abilityList.createWindow(reference) end)
    button_spell:register("mouseClick", function() spellList.createWindow(reference) end)
    button_special:register("mouseClick", function() specialList.createWindow(reference) end)


    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(sheet.id_menu)
end

function sheet.onOK()
    local menu = tes3ui.findMenu(sheet.id_menu)
    tes3ui.leaveMenuMode()
    menu:destroy()
end

function sheet.onOriginal()
    local menu = tes3ui.findMenu(sheet.id_menu)
    if menu then
        local baseTable = sheet.reference.baseObject.attributes
        local baseSkillTable = sheet.reference.baseObject.skills
        local label = menu:findChild(sheet.id_label)
        local label2 = menu:findChild(sheet.id_label2)
        local title = menu:findChild(sheet.id_title)
        local cur = menu:findChild(sheet.id_current)
        local ide = menu:findChild(sheet.id_ideal)
        local ori = menu:findChild(sheet.id_original)

        cur.widget.state = 1
        ide.widget.state = 1
        ori.widget.state = 4

        label.text = "Original Statistics:"
        label2.text = "(before any changes were ever made)"

        if sheet.reference.object.objectType == tes3.objectType.creature then
            local defType = func.determineDefault(sheet.reference)
            title.text = "" .. sheet.reference.object.name .. ", the " .. defType .. ""
        else
            title.text = "" .. sheet.reference.object.name .. ", the " .. sheet.reference.object.class.name .. ""
        end

        sheet.lvl.text = "Level: " .. sheet.reference.baseObject.level .. ""

        --Fill Bars
        sheet.hth.widget.current = sheet.reference.mobile.health.current
        sheet.mgk.widget.current = sheet.reference.mobile.magicka.current
        sheet.fat.widget.current = sheet.reference.mobile.fatigue.current
        sheet.tp.widget.current = sheet.reference.baseObject.level

        sheet.hth.widget.max = sheet.reference.baseObject.health
        sheet.mgk.widget.max = sheet.reference.baseObject.magicka
        sheet.fat.widget.max = sheet.reference.baseObject.fatigue
        sheet.tp.widget.max = sheet.reference.baseObject.level

        -- if config.expMode == true then
        --     sheet.exp.widget.current = 0
        --     sheet.exp.widget.max = (config.expRequirement + (sheet.reference.baseObject.level * config.expRate))
        -- end

        if sheet.hth.widget.current > sheet.hth.widget.max then
            sheet.hth.widget.current = sheet.hth.widget.max
        end
        if sheet.mgk.widget.current > sheet.mgk.widget.max then
            sheet.mgk.widget.current = sheet.mgk.widget.max
        end
        if sheet.fat.widget.current > sheet.fat.widget.max then
            sheet.fat.widget.current = sheet.fat.widget.max
        end

        sheet.hth.widget.fillColor = tables.colors["red"]
        sheet.mgk.widget.fillColor = tables.colors["blue"]
        sheet.fat.widget.fillColor = tables.colors["green"]

        --Attributes
        for i = 0, 7 do
            local attList = menu:findChild("kl_sheet_att_" .. i .. "")
            attList.text = "" ..
                tables.capitalization[i] .. ": " .. baseTable[i + 1] .. ""
            attList.color = tables.colors["default_font"]
        end

        if sheet.reference.object.objectType == tes3.objectType.creature then
            --Creature Types
            local default = func.determineDefault(sheet.reference)

            for i = 1, #tables.typeTable do
                local typeList = menu:findChild("kl_sheet_creType_" .. i .. "")
                if typeList then
                    typeList.color = tables.colors["grey"]
                end

                if string.startswith(typeList.text, default) then
                    typeList.text = "" .. tables.typeTable[i] .. ": Level " .. sheet.reference.object.level .. ""
                    typeList.color = tables.colors["white"]
                else
                    typeList.text = "" .. tables.typeTable[i] .. ": Level 1"
                end
            end
        else
            --NPC Skills
            for i = 0, 26 do
                local skillList = menu:findChild("kl_sheet_skill_" .. i .. "")
                skillList.text = "" .. tes3.getSkillName(i) .. ": " .. baseSkillTable[i + 1] .. ""
                skillList.widget.idle = tables.colors["default_font"]
            end
        end
        menu:updateLayout()
    end
end

function sheet.onCurrent()
    local menu = tes3ui.findMenu(sheet.id_menu)
    if menu then
        local modData = func.getModData(sheet.reference)
        local attTable = sheet.reference.mobile.attributes
        local title = menu:findChild(sheet.id_title)
        local label = menu:findChild(sheet.id_label)
        local label2 = menu:findChild(sheet.id_label2)
        local cur = menu:findChild(sheet.id_current)
        local ide = menu:findChild(sheet.id_ideal)
        local ori = menu:findChild(sheet.id_original)

        cur.widget.state = 4
        ide.widget.state = 1
        ori.widget.state = 1

        label.text = "Current Statistics:"
        label2.text = "(current value / base value)"

        if sheet.reference.object.objectType == tes3.objectType.creature then
            title.text = "" .. sheet.reference.object.name .. ", the " .. modData.type .. ""
        else
            title.text = "" .. sheet.reference.object.name .. ", the " .. sheet.class.name .. ""
        end

        sheet.lvl.text = "Level: " .. modData.level .. ""

        --Fill Bars
        sheet.hth.widget.current = sheet.reference.mobile.health.current
        sheet.mgk.widget.current = sheet.reference.mobile.magicka.current
        sheet.fat.widget.current = sheet.reference.mobile.fatigue.current
        sheet.tp.widget.current = modData.tp_current

        sheet.hth.widget.max = sheet.reference.mobile.health.base
        sheet.mgk.widget.max = sheet.reference.mobile.magicka.base
        sheet.fat.widget.max = sheet.reference.mobile.fatigue.base
        sheet.tp.widget.max = modData.tp_max

        sheet.hth.widget.fillColor = tables.colors["red"]
        sheet.mgk.widget.fillColor = tables.colors["blue"]
        sheet.fat.widget.fillColor = tables.colors["green"]

        --Attributes
        for i = 0, 7 do
            local attList = menu:findChild("kl_sheet_att_" .. i .. "")
            attList.text = "" .. tables.capitalization[i] .. ": " .. math.round(attTable[i + 1].current) .. " / " .. attTable[i + 1].base .. ""

            attList.color = tables.colors["default_font"]
            if attTable[i + 1].current < attTable[i + 1].base then
                attList.color = tables.colors["red"]
            end
            if attTable[i + 1].current > attTable[i + 1].base then
                attList.color = tables.colors["green"]
            end
        end

        if sheet.reference.object.objectType == tes3.objectType.creature then
            --Creature Types
            for i = 1, #tables.typeTable do
                local typeList = menu:findChild("kl_sheet_creType_" .. i .. "")
                if typeList then
                    typeList.color = tables.colors["grey"]
                    typeList.text = "" .. tables.typeTable[i] .. ": Level " .. modData.typelevels[i] .. ""

                    if modData.typelevels[i] > 1 then
                        typeList.color = tables.colors["white"]
                    end

                    if modData.typelevels[i] >= 20 then
                        typeList.color = tables.colors["gold"]
                        --typeList.text = "" .. tables.typeTable[i] .. ": Level " .. modData.typelevels[i] .. " (Mastered)"
                    end
                end
            end
        else
            --NPC Skills
            for i = 0, 26 do
                local tempSkill = sheet.reference.mobile:getSkillStatistic(i)
                local skillList = menu:findChild("kl_sheet_skill_" .. i .. "")
                skillList.text = "" .. tes3.getSkillName(i) .. ": " .. tempSkill.current .. " / " .. tempSkill.base .. ""
                skillList.widget.idle = tables.colors["default_font"]
                if tempSkill.current < tempSkill.base then
                    skillList.widget.idle = tables.colors["red"]
                end
                if tempSkill.current > tempSkill.base then
                    skillList.widget.idle = tables.colors["green"]
                end
                if i == modData.ignore_skill then
                    skillList.widget.idle = tables.colors["yellow"]
                end
            end
        end
        menu:updateLayout()
    end
end

function sheet.onIdeal()
    local menu = tes3ui.findMenu(sheet.id_menu)
    if menu then
        local attTable = sheet.reference.mobile.attributes
        local baseTable = sheet.reference.baseObject.attributes
        local baseSkillTable = sheet.reference.baseObject.skills
        local modData = func.getModData(sheet.reference)
        local title = menu:findChild(sheet.id_title)
        local label = menu:findChild(sheet.id_label)
        local label2 = menu:findChild(sheet.id_label2)
        local cur = menu:findChild(sheet.id_current)
        local ide = menu:findChild(sheet.id_ideal)
        local ori = menu:findChild(sheet.id_original)

        cur.widget.state = 1
        ide.widget.state = 4
        ori.widget.state = 1

        if sheet.reference.object.objectType == tes3.objectType.creature then
            title.text = "" .. sheet.reference.object.name .. ", the " .. modData.type .. ""
        else
            title.text = "" .. sheet.reference.object.name .. ", the " .. sheet.class.name .. ""
        end

        label.text = "Ideal Statistics:"
        label2.text = "(original + total Companion Leveler stats = Ideal Stats)"

        sheet.lvl.text = "Level: " .. sheet.reference.baseObject.level .. " + " .. (modData.level - sheet.reference.baseObject.level) .. " = " .. modData.level .. ""

        --Fill Bars
        sheet.hth.widget.max = sheet.reference.baseObject.health + modData.hth_gained
        sheet.mgk.widget.max = sheet.reference.baseObject.magicka + modData.mgk_gained
        sheet.fat.widget.max = sheet.reference.baseObject.fatigue + modData.fat_gained
        sheet.tp.widget.max = modData.tp_max

        sheet.hth.widget.current = sheet.reference.mobile.health.current
        sheet.mgk.widget.current = sheet.reference.mobile.magicka.current
        sheet.fat.widget.current = sheet.reference.mobile.fatigue.current
        sheet.tp.widget.current = modData.tp_current

        if sheet.reference.mobile.health.base ~= sheet.hth.widget.max then
            sheet.hth.widget.fillColor = tables.colors["light_blue"]
        end

        if sheet.reference.mobile.magicka.base ~= sheet.mgk.widget.max then
            sheet.mgk.widget.fillColor = tables.colors["light_blue"]
        end

        if sheet.reference.mobile.fatigue.base ~= sheet.fat.widget.max then
            sheet.fat.widget.fillColor = tables.colors["light_blue"]
        end


        if sheet.hth.widget.current > sheet.hth.widget.max then
            sheet.hth.widget.current = sheet.hth.widget.max
        end
        if sheet.mgk.widget.current > sheet.mgk.widget.max then
            sheet.mgk.widget.current = sheet.mgk.widget.max
        end
        if sheet.fat.widget.current > sheet.fat.widget.max then
            sheet.fat.widget.current = sheet.fat.widget.max
        end

        for i = 0, 7 do
            local attList = menu:findChild("kl_sheet_att_" .. i .. "")
            attList.text = "" ..
                tables.capitalization[i] ..
                ": " ..
                baseTable[i + 1] ..
                " + " .. modData.att_gained[i + 1] .. " = " .. (baseTable[i + 1] + modData.att_gained[i + 1]) .. ""
            attList.color = tables.colors["default_font"]
            if attTable[i + 1].base ~= (baseTable[i + 1] + modData.att_gained[i + 1]) then
                attList.color = tables.colors["light_blue"]
            end
        end

        if sheet.reference.object.objectType == tes3.objectType.creature then
            for i = 1, #tables.typeTable do
                local typeList = menu:findChild("kl_sheet_creType_" .. i .. "")
                if typeList then
                    typeList.color = tables.colors["grey"]
                    typeList.text = "" .. tables.typeTable[i] .. ": Level " .. modData.typelevels[i] .. ""

                    if modData.typelevels[i] > 1 then
                        typeList.color = tables.colors["white"]
                    end

                    if modData.typelevels[i] >= 20 then
                        typeList.color = tables.colors["gold"]
                        --typeList.text = "" .. tables.typeTable[i] .. ": Level " .. modData.typelevels[i] .. " (Mastered)"
                    end
                end
            end
        else
            for i = 0, 26 do
                local skillList = menu:findChild("kl_sheet_skill_" .. i .. "")
                local tempSkill = sheet.reference.mobile:getSkillStatistic(i)
                skillList.text = "" ..
                    tes3.getSkillName(i) ..
                    ": " ..
                    baseSkillTable[i + 1] ..
                    " + " ..
                    modData.skill_gained[i + 1] .. " = " .. (baseSkillTable[i + 1] + modData.skill_gained[i + 1]) .. ""
                skillList.widget.idle = tables.colors["default_font"]
                if tempSkill.base ~= (baseSkillTable[i + 1] + modData.skill_gained[i + 1]) then
                    skillList.widget.idle = tables.colors["light_blue"]
                end
            end
        end
        menu:updateLayout()
    end
end

function sheet.fixStats(e)
    local menu = tes3ui.findMenu(sheet.id_menu)
    if menu then
        local modData = func.getModData(sheet.reference)
        local attTable = sheet.reference.mobile.attributes
        local baseTable = sheet.reference.baseObject.attributes
        local baseSkillTable = sheet.reference.baseObject.skills

        if e.button == 0 then
            --Reset All Stats

            --Remove Abilities first
            for i = 1, #modData.abilities do
                modData.abilities[i] = false
            end

            if sheet.reference.object.objectType == tes3.objectType.creature then
                func.removeAbilities(sheet.reference)
                --Type Levels
                local default = func.determineDefault(sheet.reference)
                for i = 1, #modData.typelevels do
                    modData.typelevels[i] = 1
                    if default == tables.typeTable[i] then
                        modData.typelevels[i] = sheet.reference.object.level
                    end
                end
            else
                func.removeAbilitiesNPC(sheet.reference)
            end

            --Update Statistics after simulating
            sheet.onOK()
            timer.delayOneFrame(function()
                timer.delayOneFrame(function()
                    timer.delayOneFrame(function()
                        sheet.createWindow(sheet.reference)

                        modData.level = sheet.reference.baseObject.level

                        modData.hth_gained = 0
                        modData.mgk_gained = 0
                        modData.fat_gained = 0

                        tes3.modStatistic({ name = "health", value = (sheet.reference.baseObject.health - sheet.reference.mobile.health.base), reference = sheet.reference })

                        for i = 0, 7 do
                            tes3.modStatistic({ attribute = i, value = (baseTable[i + 1] - attTable[i + 1].base), reference = sheet.reference })
                            modData.att_gained[i + 1] = 0
                        end

                        if sheet.reference.object.objectType ~= tes3.objectType.creature then
                            for i = 0, 26 do
                                local tempSkill = sheet.reference.mobile:getSkillStatistic(i)
                                tes3.modStatistic({ skill = i, value = (baseSkillTable[i + 1] - tempSkill.base), reference = sheet.reference })
                                modData.skill_gained[i + 1] = 0
                            end
                        end

                        --Reset EXP
                        modData.lvl_progress = 0
                        func.calcEXP(sheet.reference)

                        --Reset TP
                        modData.tp_current = sheet.reference.baseObject.level
                        modData.tp_max = sheet.reference.baseObject.level

                        sheet.onCurrent()
                    end)
                end)
            end)

            tes3.messageBox("" .. sheet.reference.object.name .. " has reverted to their original statistics.")
        end

        if e.button == 1 then
            --Fix Stats

            --Add Abilities first
            if sheet.reference.object.objectType == tes3.objectType.creature then
                func.addAbilities(sheet.reference)
            else
                func.addAbilitiesNPC(sheet.reference)
            end

            --Update Statistics after simulating
            sheet.onOK()
            timer.delayOneFrame(function()
                timer.delayOneFrame(function()
                    timer.delayOneFrame(function()
                        sheet.createWindow(sheet.reference)

                        tes3.modStatistic({ name = "health", value = ((sheet.reference.baseObject.health + modData.hth_gained) - sheet.reference.mobile.health.base), reference = sheet.reference })

                        for i = 0, 7 do
                            tes3.modStatistic({ attribute = i, value = ((baseTable[i + 1] + modData.att_gained[i + 1]) - attTable[i + 1].base), reference = sheet.reference })
                        end

                        if sheet.reference.object.objectType ~= tes3.objectType.creature then
                            for i = 0, 26 do
                                local tempSkill = sheet.reference.mobile:getSkillStatistic(i)
                                tes3.modStatistic({ skill = i, value = ((baseSkillTable[i + 1] + modData.skill_gained[i + 1]) - tempSkill.base), reference = sheet.reference })
                            end
                        end

                        sheet.onCurrent()
                    end)
                end)
            end)

            tes3.messageBox("" .. sheet.reference.object.name .. "'s statistics have been fixed to their ideal values.")
        end

        if e.button == 2 then
            func.updateIdealSheet(sheet.reference)
            sheet.onCurrent()
            tes3.messageBox("" .. sheet.reference.object.name .. "'s current statistics are now recognized as their ideal values.")
        end

        if e.button == 3 then
            --Remove Abilities
            for i = 1, #modData.abilities do
                modData.abilities[i] = false
            end

            if sheet.reference.object.objectType == tes3.objectType.creature then
                func.removeAbilities(sheet.reference)
            else
                func.removeAbilitiesNPC(sheet.reference)
            end

            --Update Statistics after simulating
            sheet.onOK()
            timer.delayOneFrame(function()
                timer.delayOneFrame(function()
                    timer.delayOneFrame(function()
                        sheet.createWindow(sheet.reference)
                        sheet.onCurrent()
                        tes3.messageBox("Checking Ideal Stats is recommended.")
                    end)
                end)
            end)

            tes3.messageBox("" .. sheet.reference.object.name .. " has forgotten their abilities.")
        end

        if e.button == 4 then
            --Remove Spells
            local spells = tes3.getSpells({ target = sheet.reference, spellType = 0, getRaceSpells = false, getBirthsignSpells = false })

            for i = 1, #spells do
                tes3.removeSpell({ reference = sheet.reference, spell = spells[i].id })
            end

            tes3.messageBox("" .. sheet.reference.object.name .. " has forgotten their spells.")
        end
        if e.button == 5 then
            --Remove All Contracts
            if sheet.reference.object.objectType == tes3.objectType.creature then
                tes3.messageBox("" .. sheet.reference.object.name .. " is incapable of accepting contracts!")
            else
                modData.contracts = {}
                tes3.messageBox("" .. sheet.reference.object.name .. " has abandoned all contracts.")
            end
        end
        if e.button == 6 then
            --Remove All Bounties
            if sheet.reference.object.objectType == tes3.objectType.creature then
                tes3.messageBox("" .. sheet.reference.object.name .. " is incapable of accepting bounties!")
            else
                modData.bounties = {}
                tes3.messageBox("" .. sheet.reference.object.name .. " has given up on all bounties.")
            end
        end
    end
end

function sheet.onFix()
    local menu = tes3ui.findMenu(sheet.id_menu)
    if menu then
        tes3.messageBox({ message = "Fix " .. sheet.reference.object.name .. "'s stats?",
            buttons = { "Reset Stats to Original", "Fix Stats to Ideal", "Set Ideal to Current", "Remove All Abilities", "Remove All Spells", "Abandon Contracts", "Forsake Bounties", "" .. tes3.findGMST("sCancel").value .. "" },
            callback = sheet.fixStats })
    end
end

function sheet.setIgnore(e)
    local menu = tes3ui.findMenu(sheet.id_menu)
    local modData = func.getModData(sheet.reference)
    if menu then

        --Set Ignore Skill
        if e.button == 0 then
            --Change Ignore Skill label
            local ignoreLabel = menu:findChild("kl_sheet_ignore_label")
            ignoreLabel.text = "Ignored Skill: " .. tes3.getSkillName(sheet.ignore_skill) .. ""

            for n = 0, 26 do
                local label = menu:findChild("kl_sheet_skill_" .. n .. "")

                if modData.ignore_skill ~= 99 then
                    --Clear previous Ignore Skill color
                    if string.startswith(label.text, tes3.getSkillName(modData.ignore_skill)) then
                        label.widget.idle = tables.colors["default_font"]

                        --Check page, update colors
                        local title = menu:findChild(sheet.id_label)
                        local tempSkill = sheet.reference.mobile:getSkillStatistic(n)

                        if string.endswith(title.text, "Ideal Statistics:") then
                            local baseSkillTable = sheet.reference.baseObject.skills
                            if tempSkill.base ~= (baseSkillTable[n + 1] + modData.skill_gained[n + 1]) then
                                label.widget.idle = tables.colors["light_blue"]
                            end
                        end

                        if string.endswith(title.text, "Current Statistics:") then
                            if tempSkill.current < tempSkill.base then
                                label.widget.idle = tables.colors["red"]
                            end
                            if tempSkill.current > tempSkill.base then
                                label.widget.idle = tables.colors["green"]
                            end
                        end
                    end
                end

                --Indicate Ignored Skill
                if n == sheet.ignore_skill then
                    label.widget.idle = tables.colors["yellow"]
                end
            end

            --Set Ignore Skill in modData
            modData.ignore_skill = sheet.ignore_skill

            tes3.messageBox("" ..
                sheet.reference.object.name .. " will no longer train " .. tes3.getSkillName(sheet.ignore_skill) .. ".")
        end

        --Unset ignore skill
        if e.button == 1 then
            --Change Ignore Skill label
            local ignoreLabel = menu:findChild("kl_sheet_ignore_label")
            ignoreLabel.text = "Ignored Skill: None"

            for n = 0, 26 do
                local label = menu:findChild("kl_sheet_skill_" .. n .. "")
                if string.startswith(label.text, tes3.getSkillName(modData.ignore_skill)) then
                    label.widget.idle = tables.colors["default_font"]

                    --Check Page, Update Colors
                    local title = menu:findChild(sheet.id_label)
                    local tempSkill = sheet.reference.mobile:getSkillStatistic(n)

                    if string.endswith(title.text, "Ideal Statistics:") then
                        local baseSkillTable = sheet.reference.baseObject.skills
                        if tempSkill.base ~= (baseSkillTable[n + 1] + modData.skill_gained[n + 1]) then
                            label.widget.idle = tables.colors["light_blue"]
                        end
                    end

                    if string.endswith(title.text, "Current Statistics:") then
                        if tempSkill.current < tempSkill.base then
                            label.widget.idle = tables.colors["red"]
                        end
                        if tempSkill.current > tempSkill.base then
                            label.widget.idle = tables.colors["green"]
                        end
                    end
                end
            end

            --Unset Ignore Skill in modData
            modData.ignore_skill = 99

            tes3.messageBox("" ..
                sheet.reference.object.name .. " is no longer ignoring any skills.")
        end

        menu:updateLayout()
    end
end

function sheet.onIgnore(i)
    local menu = tes3ui.findMenu(sheet.id_menu)
    if menu then
        sheet.ignore_skill = i

        tes3.messageBox({ message = "Tell " ..
            sheet.reference.object.name .. " not to train " .. tes3.getSkillName(i) .. "?",
            buttons = { tes3.findGMST("sYes").value, "Unset Ignore Skill", tes3.findGMST("sCancel").value },
            callback = sheet.setIgnore })
    end
end


return sheet