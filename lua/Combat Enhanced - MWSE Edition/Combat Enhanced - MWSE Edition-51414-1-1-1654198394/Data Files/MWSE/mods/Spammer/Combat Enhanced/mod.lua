local mod = {
    name = "Combat Enhanced",
    ver = "1.1",
    cf = {onOff = true, mb = false, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = 0,
    list = {
        [0] = "Sword",
        [1] = "Dagger",
        [2] = "Lance",
        [3] = "BattleAxe",
        [4] = "Mace"}}}
local cf = mwse.loadConfig(mod.name, mod.cf)
local sword = require("Spammer\\Combat Enhanced\\longBlade")
local dagger = require("Spammer\\Combat Enhanced\\shortBlade")
local lance = require("Spammer\\Combat Enhanced\\spear")
local axe = require("Spammer\\Combat Enhanced\\axe")
local blunt = require("Spammer\\Combat Enhanced\\blunt")

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

---@param e addSoundEventData
function mod.onAddSound(e)
    if not cf.onOff then
        return
    end
    if not e.reference or not e.reference.data or not e.reference.data.spa_ce_silenced then
        return
    end
    if e.isVoiceover then
        return false
    end
end

---@param e skillRaisedEventData
function mod.onSkillRaised(e)
    local list = { [1] = tes3.skill.bluntWeapon, [2] = tes3.skill.axe, [3] = tes3.skill.longBlade, [4] = tes3.skill.shortBlade, [5] = tes3.skill.spear}
    local found = table.find(list, e.skill)
    if not found then
        return
    end
    if not table.find(sword.treshold, e.level) then
        return
    end
    if found == 1 then
        tes3.messageBox("New Combo Learned: \n%s", blunt.def[table.find(blunt.treshold, e.level)])
    elseif found == 2 then
        tes3.messageBox("New Combo Learned: \n%s", axe.def[table.find(axe.treshold, e.level)])
    elseif found == 3 then
        tes3.messageBox("New Combo Learned: \n%s", sword.def[table.find(sword.treshold, e.level)])
    elseif found == 4 then
        tes3.messageBox("New Combo Learned: \n%s", dagger.def[table.find(dagger.treshold, e.level)])
    elseif found == 5 then
        tes3.messageBox("New Combo Learned: \n%s", lance.def[table.find(lance.treshold, e.level)])
    end
end




function mod.registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory("Mod active?")
    category0:createOnOffButton{label = "On/Off", description = "Turns the mod On or Off.", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    local category1 = page:createCategory("Show MessageBoxes?")
    category1:createOnOffButton{label = "On/Off", description = "Turns the messageBoxes On or Off.", variable = mwse.mcm.createTableVariable{id = "mb", table = cf}}

    local category2 = page:createCategory("Max Delay:")
    category2:createSlider{label = "%s seconds.", description = "Maximum delay allowed between two actions of a combo.", min = 1, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}


    local page2 = template:createSideBarPage({label = "Combo list"})
        page2:createButton{
        buttonText = cf.list[cf.switch],
        callback = function(self)
            if cf.switch == 4 then cf.switch = 0 else cf.switch = cf.switch+1 end
            self.buttonText = cf.list[cf.switch]
            local pageBlock = template.elements.pageBlock
            pageBlock:destroyChildren()
            page2:create(pageBlock)
            template.currentPage = page2
            pageBlock:getTopLevelParent():updateLayout()
        end,
        inGameOnly = false}
    local category = page2:createCategory("Combo List:")
    category:createInfo{description = "",
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
        else
            self.elements.info.text = "Unlocked Blunt Combos:"
            self.elements.info.color = tes3ui.getPalette("journal_finished_quest_pressed_color")
        end
    end}
    category:createInfo{
        text = "Load a saved game to see this.",
        inGameOnly = true,
        postCreate = function(self)
            local list = ""
        if cf.switch == 0 then
            if tes3.player then
                local skill = tes3.mobilePlayer.longBlade.current
                local values = table.values(sword.treshold, true)
                for i,value in ipairs(values) do
                    if skill >= value then
                        list = list..i.."/ "..sword.def[table.find(sword.treshold, value)].."\n\n"
                    else list = list..i.."/ ? (Requirement: Long Blade "..value..")\n\n"
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
                for i,value in ipairs(values) do
                    if skill >= value then
                        list = list..i.."/ "..dagger.def[table.find(dagger.treshold, value)].."\n\n"
                    else list = list..i.."/ ? (Requirement: Short Blade "..value..")\n\n"
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
                for i,value in ipairs(values) do
                    if skill >= value then
                        list = list..i.."/ "..lance.def[table.find(lance.treshold, value)].."\n\n"
                    else list = list..i.."/ ? (Requirement: Spear "..value..")\n\n"
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
                for i,value in ipairs(values) do
                    if skill >= value then
                        list = list..i.."/ "..axe.def[table.find(axe.treshold, value)].."\n\n"
                    else list = list..i.."/ ? (Requirement: Axe "..value..")\n\n"
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
                local skill = tes3.mobilePlayer.bluntWeapon.current
                local values = table.values(blunt.treshold, true)
                for i,value in ipairs(values) do
                    if skill >= value then
                        list = list..i.."/ "..blunt.def[table.find(blunt.treshold, value)].."\n\n"
                    else list = list..i.."/ ? (Requirement: Blunt Weapon "..value..")\n\n"
                    end
                end
                if list == "" then
                    list = "None."
                end
                self.elements.info.text = list
                self.elements.info.justifyText = "center"
            end
        end
    end}
end
return mod