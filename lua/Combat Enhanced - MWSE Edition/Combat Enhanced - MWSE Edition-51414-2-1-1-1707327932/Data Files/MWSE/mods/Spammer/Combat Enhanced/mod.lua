local mod = {
    name = "Combat Enhanced",
    ver = "2.1",
    author = "Spammer",
    cf = {
        onOff = true,
        mb = false,
        key = { keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false },
        dropDown = 0,
        slider = 5,
        deadlyHit = 100,
        sliderpercent = 50,
        blocked = {},
        npcs = {},
        textfield = "hello",
        switch = 0,
        list2 = {
            [0] = "Sword",
            [1] = "Dagger",
            [2] = "Lance",
            [3] = "BattleAxe",
            [4] = "Mace",
            [5] = "Fistfight",
        }
    }
}
local cf = mwse.loadConfig(mod.name, mod.cf)
local sword = require("Spammer\\Combat Enhanced\\longBlade")
local dagger = require("Spammer\\Combat Enhanced\\shortBlade")
local lance = require("Spammer\\Combat Enhanced\\spear")
local axe = require("Spammer\\Combat Enhanced\\axe")
local blunt = require("Spammer\\Combat Enhanced\\blunt")
local box = require("Spammer\\Combat Enhanced\\handToHand")
local config = require("Spammer\\Combat Enhanced\\config")

---@param e damagedEventData
function mod.onDamaged(e)
    if not cf.onOff then return end
    if e.attackerReference ~= tes3.player then return end
    local target = e.reference
    if not target then return end
    if e.source ~= tes3.damageSource.attack then return end
    if e.attacker.weaponReady == false then return end
    local weapon = e.attacker.readiedWeapon
    if not weapon or not weapon.object then return end
    local attackType = e.attacker.actionData.physicalAttackType
    if not attackType then return end
    local type = weapon.object.type
    if type == tes3.weaponType.longBladeOneHand or type == tes3.weaponType.longBladeTwoClose then
        sword.damage(attackType, target)
    elseif type == tes3.weaponType.shortBladeOneHand then
        dagger.damage(attackType, target)
    elseif type == tes3.weaponType.spearTwoWide then
        lance.damage(attackType, target)
    elseif type == tes3.weaponType.axeOneHand or type == tes3.weaponType.axeTwoHand then
        axe.damage(attackType, target)
    elseif type == tes3.weaponType.bluntOneHand or type == tes3.weaponType.bluntTwoClose or type == tes3.weaponType.bluntTwoWide then
        blunt.damage(attackType, target)
    end
end

---@param e damageHandToHandEventData
function mod.ondamagedHandToHand(e)
    if not cf.onOff then return end
    if not e.attackerReference then return end
    if e.attackerReference ~= tes3.player then return end
    local target = e.reference
    if not target then return end
    local attackType = e.attacker.actionData.physicalAttackType
    if not attackType then return end
    --tes3.messageBox("%s", table.find(tes3.physicalAttackType, attackType))
    local multiplier = box.damage(attackType, target) or 1
    local ori = e.fatigueDamage
    e.fatigueDamage = (ori * multiplier)
    --mwse.log("Damage Adjusted: %s -> %s", ori, e.fatigueDamage)
end

---@param e bodyPartAssignedEventData
function mod.onBodyPartAssigned(e)
    if not cf.onOff then
        return
    end
    if not e.reference or not e.reference.data or not e.reference.data.spa_ce_dismembered then
        return
    end
    if table.find(e.reference.data.spa_ce_dismembered, e.index) then
        return false
    end
end

---@param e addTempSoundEventData
function mod.onAddSound(e)
    if not cf.onOff then
        return
    end
    if not (e.reference and e.reference.data and e.reference.data.spa_ce_silenced) then
        return
    end
    if e.isVoiceover then
        return false
    end
end

---@param e skillRaisedEventData
function mod.onSkillRaised(e)
    local list = {
        [tes3.skill.bluntWeapon] = blunt,
        [tes3.skill.axe] = axe,
        [tes3.skill.longBlade] = sword,
        [tes3.skill.shortBlade] = dagger,
        [tes3.skill.spear] = lance,
        [tes3.skill.handToHand] = box
    }
    if not list[e.skill] then
        return
    end
    local treshold = table.invert(list[e.skill].treshold)
    if not treshold[e.level] then
        return
    end
    tes3.messageBox("New Combo Learned: \n%s", list[e.skill].def[treshold[e.level]])
end

local modConfig = {}
function modConfig.onSearch(search)
    return string.startswith("spammer", search)
end

function modConfig.onClose()
    mwse.saveConfig(mod.name, cf)
end


---@param buttonBlock tes3uiElement
---@param comboBlock tes3uiElement
local function createBottomBlock(buttonBlock, comboBlock)
    buttonBlock.childAlignX = 0.5
    config.createHeader(buttonBlock, "Show Combos:")
    local skills = { [0] = "longBlade", [1] = "shortBlade", [2] = "spear", [3] = "axe", [4] = "bluntWeapon", [5] =
    "handToHand" }
    local data = { [0] = sword, [1] = dagger, [2] = lance, [3] = axe, [4] = blunt, [5] = box }
    for i = 0, 5 do
        local text = string.format("%s (%s)", cf.list2[i], tes3.getSkill(tes3.skill[skills[i]]).name)
        local button = config.createButton(buttonBlock, text)
        button.widget.state = ((i == cf.switch) and tes3.uiState.active) or tes3.uiState.normal
        button:register("mouseClick", function()
            cf.switch = i
            buttonBlock:destroyChildren()
            comboBlock:destroyChildren()
            createBottomBlock(buttonBlock, comboBlock)
            buttonBlock:getTopLevelMenu():updateLayout()
        end)
    end

    comboBlock.childAlignX = 0.5
    config.createHeader(comboBlock, "Combo List:")
    local skillName = tes3.getSkill(tes3.skill[skills[cf.switch]]).name
    local combos = config.createHeader(comboBlock, "Unlocked " .. skillName .. " Combos")
    combos.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
    local list = comboBlock:createLabel { text = "Load a saved game to see this." }
    if tes3.player then
        list.text = ""
        local skill = tes3.mobilePlayer[skills[cf.switch]].current
        local values = table.values(data[cf.switch].treshold, true)
        for i, value in ipairs(values) do
            if skill >= value then
                list.text = list.text .. i .. "/ " .. data[cf.switch].def[table.find(data[cf.switch].treshold, value)] .. "\n\n"
            else
                list.text = list.text .. i .. "/ ? (Requirement: " .. skillName .. " " .. value .. ")\n\n"
            end
        end
        if list.text == "" then
            list.text = "None."
        end
    end
    list.wrapText = true
    list.justifyText = "center"
    list.absolutePosAlignX = 0
    list.borderAllSides = 20
end

---@param parent tes3uiElement
function modConfig.onCreate(parent)
    parent.flowDirection = "left_to_right"
    local page = config.createBorderedBlock(parent)
    page.paddingAllSides = 0
    local page2 = config.createBorderedBlock(parent)
    page2.paddingAllSides = 0
    local configBlock = config.createBorderedBlock(page)
    local infoBlock = config.createBorderedBlock(page2)
    infoBlock.heightProportional = 1 / 2
    local modInfo = infoBlock:createBlock()
    modInfo.wrapText = true
    modInfo.autoHeight = true
    modInfo.autoWidth = true
    modInfo.flowDirection = "top_to_bottom"
    modInfo:createLabel({
        text = "Welcome to \"" ..
            mod.name .. "\" Configuration Menu. \n \n \n A mod by " .. mod.author .. ".\n"
    })
    modInfo:createHyperlink({
        text = "Spammer's Nexus Profile",
        url =
        "https://www.nexusmods.com/users/140139148?tab=user+files"
    })
    
    config.createHeader(configBlock, "Mod active?")
    local cycle = config.createOnOffButton(configBlock, { desc = "Turns the mod On or Off.", modInfo = modInfo })
    cycle.widget.value = cf.onOff
    cycle:registerAfter("mouseClick", function()
        cf.onOff = not cf.onOff
    end)
    config.createHeader(configBlock, "Show MessageBoxes?")
    cycle = config.createOnOffButton(configBlock, { desc = "Turns the combo messages On or Off.", modInfo = modInfo })
    cycle.widget.value = cf.mb
    cycle:registerAfter("mouseClick", function()
        cf.mb = not cf.mb
    end)
    config.createHeader(configBlock, "Ultimate:")
    local chanceSlider = config.createSlider(configBlock,
        { current = (cf.deadlyHit - 10), modInfo = modInfo, min = 10, desc =
        "Percentage of health below which your ultimate combo will actually kill your opponent.", format = "%s%%" })
    chanceSlider:register("PartScrollBar_changed", function()
        cf.deadlyHit = (chanceSlider.widget.current + 10)
    end)
    config.createHeader(configBlock, "Max delay:")
    local delaySlider = config.createSlider(configBlock,
        { current = (cf.slider - 1), min = 1, max = 10, jump = 1, desc = "Maximum delay allowed between two actions of a combo.", modInfo = modInfo, format = "%s seconds" })
    delaySlider:register("PartScrollBar_changed", function()
        cf.slider = (delaySlider.widget.current + 1)
    end)

    local buttonBlock = config.createBorderedBlock(page)
    local comboBlock = config.createBorderedBlock(page2)
    comboBlock.wrapText = true
    comboBlock.heightProportional = 3 / 2
    createBottomBlock(buttonBlock, comboBlock)

end

function mod.registerModConfig()
    mwse.registerModConfig(mod.name, modConfig)
end







--[[
function mod.registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    template.onSearch = function(search)
        return string.startswith("spammer", search)
    end

    local page = template:createSideBarPage({ label = "\"" .. mod.name .. "\" Settings" })
    page.sidebar:createInfo { text = "Welcome to \"" .. mod.name .. "\" Configuration Menu. \n \n \n A mod by Spammer." }
    page.sidebar:createHyperlink { text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }


    local category0 = page:createCategory("Mod active?")
    category0:createOnOffButton { label = "On/Off", description = "Turns the mod On or Off.", variable = mwse.mcm.createTableVariable { id = "onOff", table = cf } }

    local category1 = page:createCategory("Show MessageBoxes?")
    category1:createOnOffButton { label = "On/Off", description = "Turns the messageBoxes On or Off.", variable = mwse.mcm.createTableVariable { id = "mb", table = cf } }

    local category3 = page:createCategory("Ultimate:")
    category3:createSlider { label = "%s%%", description = "Percentage of health below which your ultimate combo will actually kill your opponent.", min = 10, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable { id = "deadlyHit", table = cf } }

    local category2 = page:createCategory("Max Delay:")
    category2:createSlider { label = "%s seconds.", description = "Maximum delay allowed between two actions of a combo.", min = 1, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable { id = "slider", table = cf } }

    local skills = { "longBlade", "shortBlade", "spear", "axe", "bluntWeapon", "handToHand" }

    local page2 = template:createSideBarPage({ label = "Combo list" })
    --]]

--page2:createButton {
--buttonText = cf.list2[cf.switch] .. " (" .. tes3.getSkill(tes3.skill[skills[(cf.switch + 1)]]).name .. ")",
--
--callback = function(self)
--if cf.switch == 5 then cf.switch = 0 else cf.switch = cf.switch + 1 end
--self.buttonText = cf.list2[cf.switch] .. " (" .. tes3.getSkill(tes3.skill[skills[(cf.switch + 1)]]).name .. ")"
--[[
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelMenu():updateLayout()
        end,
        inGameOnly = false }
    local category = page2:createCategory("Combo List:")
    category:createInfo { description = "",
        text = "",
        inGameOnly = false,
        postCreate = function(self)
            if cf.switch == 0 then
                self.elements.info.text = "Unlocked Long Blade Combos:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            elseif cf.switch == 1 then
                self.elements.info.text = "Unlocked Short Blade Combos:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            elseif cf.switch == 2 then
                self.elements.info.text = "Unlocked Spear Combos:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            elseif cf.switch == 3 then
                self.elements.info.text = "Unlocked Axe Combos:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            elseif cf.switch == 4 then
                self.elements.info.text = "Unlocked Blunt Combos:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            else
                self.elements.info.text = "Unlocked Hand to Hand Combos:"
                self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
            end
        end }
    category:createInfo {
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
            local list = ""
            if cf.switch == 0 then
                if tes3.player then
                    local skill = tes3.mobilePlayer.longBlade.current
                    local values = table.values(sword.treshold, true)
                    for i, value in ipairs(values) do
                        if skill >= value then
                            list = list .. i .. "/ " .. sword.def[table.find(sword.treshold, value)] .. "\n\n"
                        else
                            list = list .. i .. "/ ? (Requirement: Long Blade " .. value .. ")\n\n"
                        end
                    end
                    if list == "" then
                        list = "None."
                    end
                    self.elements.info.text = list
                    self.elements.info.justifyText = "center"
                end
            elseif cf.switch == 1 then
                if tes3.player then
                    local skill = tes3.mobilePlayer.shortBlade.current
                    local values = table.values(dagger.treshold, true)
                    for i, value in ipairs(values) do
                        if skill >= value then
                            list = list .. i .. "/ " .. dagger.def[table.find(dagger.treshold, value)] .. "\n\n"
                        else
                            list = list .. i .. "/ ? (Requirement: Short Blade " .. value .. ")\n\n"
                        end
                    end
                    if list == "" then
                        list = "None."
                    end
                    self.elements.info.text = list
                    self.elements.info.justifyText = "center"
                end
            elseif cf.switch == 2 then
                if tes3.player then
                    local skill = tes3.mobilePlayer.spear.current
                    local values = table.values(lance.treshold, true)
                    for i, value in ipairs(values) do
                        if skill >= value then
                            list = list .. i .. "/ " .. lance.def[table.find(lance.treshold, value)] .. "\n\n"
                        else
                            list = list .. i .. "/ ? (Requirement: Spear " .. value .. ")\n\n"
                        end
                    end
                    if list == "" then
                        list = "None."
                    end
                    self.elements.info.text = list
                    self.elements.info.justifyText = "center"
                end
            elseif cf.switch == 3 then
                if tes3.player then
                    local skill = tes3.mobilePlayer.axe.current
                    local values = table.values(axe.treshold, true)
                    for i, value in ipairs(values) do
                        if skill >= value then
                            list = list .. i .. "/ " .. axe.def[table.find(axe.treshold, value)] .. "\n\n"
                        else
                            list = list .. i .. "/ ? (Requirement: Axe " .. value .. ")\n\n"
                        end
                    end
                    if list == "" then
                        list = "None."
                    end
                    self.elements.info.text = list
                    self.elements.info.justifyText = "center"
                end
            elseif cf.switch == 4 then
                if tes3.player then
                    local skill = tes3.mobilePlayer.bluntWeapon.current
                    local values = table.values(blunt.treshold, true)
                    for i, value in ipairs(values) do
                        if skill >= value then
                            list = list .. i .. "/ " .. blunt.def[table.find(blunt.treshold, value)] .. "\n\n"
                        else
                            list = list .. i .. "/ ? (Requirement: Blunt Weapon " .. value .. ")\n\n"
                        end
                    end
                    if list == "" then
                        list = "None."
                    end
                    self.elements.info.text = list
                    self.elements.info.justifyText = "center"
                end
            else
                if tes3.player then
                    local skill = tes3.mobilePlayer.handToHand.current
                    local values = table.values(box.treshold, true)
                    for i, value in ipairs(values) do
                        if skill >= value then
                            list = list .. i .. "/ " .. box.def[table.find(box.treshold, value)] .. "\n\n"
                        else
                            list = list .. i .. "/ ? (Requirement: Hand to Hand " .. value .. ")\n\n"
                        end
                    end
                    if list == "" then
                        list = "None."
                    end
                    self.elements.info.text = list
                    self.elements.info.justifyText = "center"
                end
            end
        end }
end
--]]
return mod
