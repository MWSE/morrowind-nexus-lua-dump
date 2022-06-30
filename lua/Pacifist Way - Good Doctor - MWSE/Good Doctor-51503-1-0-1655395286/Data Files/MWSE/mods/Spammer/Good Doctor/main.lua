local mod = {
    name = "Good Doctor",
    ver = "1.0",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 15, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local dont = false
local paratest = nil

---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)

    if not (e.reference and e.reference.data and e.reference.data.spa_diseaseCured) then
        return
    end
    local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    label.text = string.gsub(label.text, "Diseased ", "")
end)

---@param e uiObjectTooltipEventData
event.register("uiObjectTooltip", function(e)

    if not (e.reference and e.reference.data and e.reference.data.spa_blightDiseaseCured) then
        return
    end
    local label = e.tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    label.text = string.gsub(label.text, "Blighted ", "")
end)

---comment
---@param e table|spellResistEventData
event.register("spellResist", function(e)
    if e.effect.id == tes3.effect.paralyze then
        paratest = e.target
    end
    if (e.effect.id == tes3.effect.cureCommonDisease) and string.startswith(e.target.object.name:lower(), "diseased") then
        e.target.data.spa_diseaseCured = true
        e.target.mobile.fight = 0
        if math.random(100) <= cf.sliderpercent then
            tes3.setAIFollow{reference = e.target, target = e.caster, reset = false}
        else
            e.target.mobile.flee = 100
            e.target.mobile.actionData.aiBehaviorState = tes3.aiBehaviorState.flee
            e.target.mobile:stopCombat(true)
        end
    end
    if (e.effect.id == tes3.effect.cureBlightDisease) and string.startswith(e.target.object.name:lower(), "blighted") then
        e.target.data.spa_blightDiseaseCured = true
        e.target.mobile.fight = 0
        local tresh = e.caster.mobile.personality.current
        if math.random(100) <= tresh/8 then
            tes3.setAIFollow{reference = e.target, target = e.caster, reset = false, duration = tresh*6}
        else
            e.target.mobile.flee = 100
            e.target.mobile.actionData.aiBehaviorState = tes3.aiBehaviorState.flee
            e.target.mobile:stopCombat(true)
        end
    end
end)


local function newSpell(enchantment)
    local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
    tes3.setSourceless(spell)
    spell.alwaysSucceeds = true
    spell.castType = tes3.spellType.spell
    spell.magickaCost = 0
    for index = 1, #enchantment.effects do
        local effect = spell.effects[index]
        local enchantmentEffect = enchantment.effects[index]
        effect.id = enchantmentEffect and enchantmentEffect.id
        effect.min = enchantmentEffect and enchantmentEffect.min or 0
        effect.max = enchantmentEffect and enchantmentEffect.max or 0
        effect.radius = enchantmentEffect and enchantmentEffect.radius or 0
        effect.rangeType = enchantmentEffect and enchantmentEffect.rangeType or tes3.effectRange.self
        effect.duration = enchantmentEffect and enchantmentEffect.duration or 0
        effect.attribute = enchantmentEffect and enchantmentEffect.attribute or -1
        effect.skill = enchantmentEffect and enchantmentEffect.skill or -1
    end
    return spell
end


event.register("simulate", function()
    if not (paratest and paratest.mobile) then return end
    if dont then return end
    if cf.slider == 0 then return end
    local paralyzed = tes3.isAffectedBy{reference = paratest, effect = tes3.effect.paralyze}
    if not paralyzed then
        paratest = nil
        return
    end
    for _,stack in pairs(paratest.object.equipment) do
        if stack.object.enchantment and stack.itemData then
            for _,effect in pairs(stack.object.enchantment.effects) do
                if (effect.id == tes3.effect.cureParalyzation) then
                    local chargeCost = tes3.calculateChargeUse{mobile = paratest.mobile, enchantment = stack.object.enchantment}
                    if stack.itemData.charge >= chargeCost then
                        tes3.cast{reference = paratest, target = paratest, instant = true, alwaysSucceeds = true, bypassResistances = false, spell = newSpell(stack.object.enchantment)}
                        stack.itemData.charge = stack.itemData.charge-chargeCost
                        tes3.messageBox("%s freed %s from paralyzation!", stack.object.name, paratest.object.name)
                        dont = true
                        timer.start{duration = cf.slider, callback = function() dont = false end}
                        return
                    end
                end
            end
        end
    end
end)


local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category2 = page:createCategory("Cure Paralysis Cooldown:")
    category2:createSlider{label = "%s Seconds", description = "Cooldown between two usages. Setting this value to 0 will disable this feature of the mod. [Default: 5]", min = 0, max = 60, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    --local category = page:createCategory("New Follower :")
    --category:createSlider{label = "%s Seconds", description = "Chance to get a new buddy. [Default: 15]", min = 0, max = 60, step = 1, jump = 5, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}

end --event.register("modConfigReady", registerModConfig)

local function initialized()
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})

