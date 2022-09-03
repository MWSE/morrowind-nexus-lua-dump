local mod = {
    name = "Effect Timer",
    ver = "2.0",
    author = "Spammer",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.r, isShiftDown = false, isAltDown = true, isControlDown = false}, dropDown = 0, slider = 500, sliderpercent = 100, blocked = {}, textfield = 50, switch = true, recast = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)

local maxWidth = 20
local name = "spa_innerColor"
local fillname = "Spa_conjFillbar"
local labelname = "Spa_spellEff"

---@param str string
---@return boolean
local function tobool(str)
    assert(type(str) == "string", "Param must be a string!")
    return (str == "true")
end

---@param recastable boolean
---@return number[]
local function colorLabel(recastable)
    if (cf.recast and recastable) then return tes3ui.getPalette("fatigue_color") end
    return tes3ui.getPalette("normal_color")
end

---comment
---@param v tes3activeMagicEffect
---@param id number
---@param effIndex string|number
---@param spell string
---@param casterID string?
---@param attribute string|number
---@param skill string|number
---@return boolean
local function validate(v, id, effIndex, spell, casterID, attribute, skill)
return  v
        and (v.effectId == id)
        and (v.effectIndex == tonumber(effIndex))
        and (v.instance.magicID == spell)
        and ((v.instance.caster == nil) or (v.instance.caster.id == casterID))
        and ((v.attributeId == tonumber(attribute)) or (v.attributeId == tonumber(skill)))
end
---@param childName string
---@param id number
---@param recastable boolean
local function timerCallback(childName, id, recastable, text)
    local index
    local menu = tes3ui.findMenu("MenuMulti")
    if not menu then return end
    local block = menu:findChild("Spa_conjuringTimer")
    if not block then return end
    local firstChild = block:findChild(childName)
    if not firstChild then return end
    local fillbar = firstChild:findChild(fillname)
    if not (fillbar and fillbar.widget) then return end
    local label = firstChild:findChild(labelname)
    local caster = label.parent.children[1].name
    local casterID for w in string.gmatch(caster, "(.+)|") do casterID = w end
    local effIndex for w in string.gmatch(caster, "|(.+)") do effIndex = w end
    local spell for w in string.gmatch(childName, "(.+)|") do spell = w end
    local attribute for w in string.gmatch(childName, ">(.+)#") do attribute = w end
    local skill for w in string.gmatch(childName, "#(.+)&&") do skill = w end
    for i,v in ipairs(tes3.mobilePlayer.activeMagicEffectList) do
        if  validate(v, id, effIndex, spell, casterID, attribute, skill) then
            index = i
            local magn = v.effectInstance.magnitude
            if magn and (magn > 0) then
                label.text = text.." ("..magn.." pts)"
                maxWidth = math.max(maxWidth, #label.text)
            end
        end
    end
    local effect = tes3.mobilePlayer.activeMagicEffectList[index]
    local doit = true
    local duration
    if effect and validate(effect, id, effIndex, spell, casterID, attribute, skill) then
        if effect.isBoundItem then
            doit = tes3.player.object.inventory:contains(effect.effectInstance.createdData.object,effect.effectInstance.createdData.itemData)
        elseif effect.isSummon then
---@diagnostic disable-next-line: undefined-field
            doit = not (effect.effectInstance.createdData.object.mobile.isDead)
        end
        duration = ((effect.duration)-(effect.effectInstance.timeActive))
    end
    fillbar.width = 10*maxWidth
    fillbar.widget.max = (effect and (effect.effectId == id) and effect.duration) or
    fillbar.widget.max
    fillbar.widget.current = duration or
    (fillbar.widget.current-1)
    label.color = colorLabel(recastable)
    if ((fillbar.widget.current > 0) and doit and cf.onOff and effect) then
        if (fillbar.widget.current <= 10) then
            fillbar.widget.fillColor = tes3ui.getPalette("health_color")
        else
            fillbar.widget.fillColor = tes3ui.getPalette("normal_color")
        end
        timer.start{duration = 1, callback = function() timerCallback(childName, id, recastable, text) end}
    else
        if cf.recast and cf.onOff and recastable then
            if spell and tes3.player.object.spells:contains(spell) then
                timer.delayOneFrame(function() tes3.cast{reference = tes3.player, spell = spell, alwaysSucceeds = false, instant = false, target = tes3.player} end)
            end
        end
        firstChild:destroy()
        if (#block.children == 0) then
            block.visible = false
            maxWidth = 20
        end
    end
end

---@param effect tes3effect
---@param spellId string
---@param current number
---@param max number
---@param recastable boolean
---@param caster string?
---@param effIndex number
local function blocks(effect, spellId, current, max, recastable, caster, effIndex)
    local menu = tes3ui.findMenu("MenuMulti")
    if not menu then return end
    local bg = menu:findChild("Spa_conjuringTimer")
    if not bg then return end
    local attribute = effect.attribute
    local skill = effect.skill
    local probablID = string.format("%s|%s>%s#%s&&%s<%s", spellId, effect.id, attribute, skill, recastable, effIndex)
    if not bg.visible then bg.visible = true end
    local maybe = bg:findChild(probablID)
    if maybe then
        local fill = maybe:findChild(fillname)
        if fill and fill.widget then
            fill.widget.current = max
            bg:reorderChildren(#bg.children, maybe, 1)
            return
        end
     end
    local hell = bg:createThinBorder{id = probablID}
    hell.alpha = 1
    hell.height = 40
    hell.autoWidth = true
    hell.childAlignX = 0.5
    hell.flowDirection = "top_to_bottom"
    local rect = hell:createRect{id = name, color = {0,0,0}}
    rect.alpha = 0
    rect.autoHeight = true
    rect.autoWidth = true
    rect.flowDirection = "top_to_bottom"
    local block = rect:createBlock()
    block.autoWidth = true
    block.autoHeight = true
    local icon = block:createImage{id = string.format("%s|%s", caster, effIndex), path = "Icons\\"..effect.object.icon}
    icon.scaleMode = true
    icon.width = 20
    icon.height = 20
    local attrName = ((attribute ~= -1) and string.format(": %s", ((string.gsub(tes3.attributeName[attribute], "^%l", string.upper))))) or ""
    local skillName = ((skill ~= -1) and ": "..tes3.skillName[skill]) or ""
    local text = string.format(" %s%s%s",effect.object.name,skillName,attrName)
    local label = block:createLabel{id = labelname, text = text}
    label.color = colorLabel(recastable)
    local bar = rect:createFillBar{id = fillname, current = current, max = max}
    local count = #label.text
    maxWidth = math.max(maxWidth, count)
    bar.width = 10*maxWidth
    bar.widget.fillColor = tes3ui.getPalette("normal_color")
    bar.widget.showText = cf.switch
    timer.start{duration = 1, callback = function()
        timerCallback(probablID, effect.id, recastable, text)
    end}
end


---@param e table|spellResistEventData
event.register("spellResist", function(e)
    if not (cf.onOff and e.target == tes3.player) then return end
    local spell = e.source
    local dont = true
    local max = {}
    for i, effect in pairs(spell.effects) do
        for index,check in pairs(cf.blocked) do
            if check and (effect.object and effect.object.name == index) and (effect.duration >= 2) then
                max[i] = effect
                dont = false
            end
        end
    end
    if dont then return end
    local menu = tes3ui.findMenu("MenuMulti")
    if not menu then return end
    local bg = menu:findChild("Spa_conjuringTimer")
    if not bg then return end
    local recastable = ((e.caster == tes3.player) and (e.source.objectType == tes3.objectType.spell))
    local caster = e.caster and e.caster.id
    for i in pairs(max) do
        blocks(max[i], e.source.id, max[i].duration, max[i].duration, recastable, caster, i-1)
    end
end)


---@param e table|keyUpEventData
event.register("keyUp", function(e)
    if tes3ui.menuMode() then return end
    if not (cf.onOff and tes3.player) then return end
    if not (tes3.isKeyEqual{actual = e, expected = cf.key}) then return end
    cf.recast = not cf.recast
    if cf.recast then
        tes3.messageBox("Auto Recast Enabled.")
    else
        tes3.messageBox("Auto Recast Disabled.")
    end
end)  --]]

event.register("mouseButtonUp", function()
    if not (tes3.player and cf.onOff) then return end
    timer.start{duration = 0.3, type = timer.real, callback = function()
        local menu = tes3ui.findMenu("MenuMulti")
        if not menu then return end
        local block1 = menu:findChild("Spa_conjuringTimer")
        if not block1 then return end
        block1.absolutePosAlignX = cf.slider/1000
        block1.absolutePosAlignY = cf.sliderpercent/1000
        for child in table.traverse(block1.children) do
            if child.name == name then
               child.alpha = cf.textfield/100
            elseif child.name == fillname then
                child.widget.showText = cf.switch
            end
        end
    end}
end)

---@param e table|uiActivatedEventData
event.register("uiActivated", function(e)
    if not (e.newlyCreated) then return end
    local parent = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main"))
    local block1 = parent:createRect({id = "Spa_conjuringTimer", color = {0,0,0}})
    block1.alpha = 0
    block1.autoWidth = true
    block1.autoHeight = true
    block1.absolutePosAlignX = cf.slider/1000
    block1.absolutePosAlignY = cf.sliderpercent/1000
    block1.flowDirection = "top_to_bottom"
    block1.childAlignX = 0.5
    block1.visible = false
end, {filter = "MenuMulti"})

---@return table
local function getExclusionList()
    local list = {}
    for _,i in pairs(tes3.effect) do
        local f = tes3.getMagicEffect(i)
        if f and not (f.hasNoDuration) then
            table.insert(list, f.name)
        end
    end
    table.sort(list)
    return list
end

event.register("save", function()
    if not cf.onOff then return end
    tes3.player.data.Spa_conjuringTimer = nil
    local time = tes3.getSimulationTimestamp()
    local list = {name = tes3.player.object.name, time = time, spells = {}, effects = {}, attributes = {}, skills = {}, recasts = {}, current = {}, max = {}, casters = {}, effIndexes = {}, cfrecast = cf.recast}
    local menu = tes3ui.findMenu("MenuMulti")
    if not menu then return end
    local block = menu:findChild("Spa_conjuringTimer")
    if not (block and (#block.children > 0)) then return end
    for child in table.traverse(block.children) do
        if child.name == name then
            local spell
            local effect
            local recast
            local attribute
            local skill
            local extract = child.parent.name
            for w in string.gmatch(extract, "(.+)|") do spell = w end
            for w in string.gmatch(extract, "|(.+)>") do effect = w end
            for w in string.gmatch(extract, ">(.+)#") do attribute = w end
            for w in string.gmatch(extract, "#(.+)&&") do skill = w end
            for w in string.gmatch(extract, "&&(.+)<") do recast = w end
            table.insert(list.spells, spell)
            table.insert(list.effects, effect)
            table.insert(list.attributes, attribute)
            table.insert(list.skills, skill)
            table.insert(list.recasts, recast)
        elseif child.name == fillname then
            table.insert(list.current, child.widget.current)
            table.insert(list.max, child.widget.max)
        elseif child.name == labelname then
            local caster = child.parent.children[1].name
            local casterID for w in string.gmatch(caster, "(.+)|") do casterID = w end
            local effIndex for w in string.gmatch(caster, "|(.+)") do effIndex = w end
            table.insert(list.casters, casterID)
            table.insert(list.effIndexes, effIndex)
        end
    end
    tes3.player.data.Spa_conjuringTimer = list
end, {priority = 100})

event.register("loaded", function()
    local list = tes3.player.data.Spa_conjuringTimer
    if not (cf.onOff and list) then return end
    cf.recast = list.cfrecast
    if #list.spells == 0 then return end
    for i, v in ipairs(list.spells) do
        local index
        local spell = tes3.getObject(v)
        local skill = (list.skills and tonumber(list.skills[i])) or -1
        local attr = (list.attributes and tonumber(list.attributes[i])) or -1
        local casterID = (list.casters and (list.casters[i])) or tes3.player.id
        local id = (list.effects and tonumber(list.effects[i])) or tes3.effect.soultrap
        local effIndex = (list.effIndexes and list.effIndexes[i]) or 0
        for k,e in ipairs(tes3.mobilePlayer.activeMagicEffectList) do
            if  (e.effectId == id)
                and (e.effectIndex == tonumber(effIndex))
                and (e.instance.magicID == v)
                and ((e.instance.caster == nil) or  (e.instance.caster.id == casterID))
                and ((e.attributeId == attr) or (e.attributeId == skill))
            then index = k end
        end
        local affected = index and tes3.mobilePlayer.activeMagicEffectList[index]
        if spell and affected then
            local effect = spell.effects[tonumber(effIndex)+1]
            if effect and not (type(effect) == "number") then
                local recast = tobool(list.recasts[i])
                local timeLeft = ((affected.duration)-(affected.effectInstance.timeActive))
                blocks(effect, spell.id, timeLeft, list.max[i], recast, casterID, list.effIndexes[i])
            end
        end
    end
    tes3.player.data.Spa_conjuringTimer = nil
end, {priority = -10})

--[[local menuTimestamp
---@param e table|menuEnterEventData|menuExitEventData
local function onMenuEnterExit(e)
    if (e.menuMode and cf.onOff) then
        menuTimestamp = tes3.getSimulationTimestamp()
    elseif ((menuTimestamp) and (cf.onOff) and (menuTimestamp ~= tes3.getSimulationTimestamp())) then
        local timescale = tes3.worldController.timescale.value
        local timePassed = (tes3.getSimulationTimestamp()-menuTimestamp)*3600/timescale
        local menu = tes3ui.findMenu("MenuMulti")
        if not menu then return end
        local block1 = menu:findChild("Spa_conjuringTimer")
        if not block1 then return end
        for child in table.traverse(block1.children) do
            if child.name == fillname then
                child.widget.current = child.widget.current-timePassed
                if child.widget.current <= 0 then
                   child.parent.parent:destroy()
                end
            end
        end
    end
end  event.register("menuEnter", onMenuEnterExit) event.register("menuExit", onMenuEnterExit)
--]]

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by "..mod.author.."."}
    page.sidebar:createHyperLink{ text = mod.author.."'s Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory("Mod Enabled?")
    category0:createOnOffButton{label = "On/Off", description = "Turns the mod On or Off. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    local subcat = page:createCategory("UI Settings")
    subcat:createOnOffButton{label = "Fillbar Text", description = "Toggles the fillbar text. [Default: On]", variable = mwse.mcm.createTableVariable{id = "switch", table = cf}}
    subcat:createSlider{label = "Position X:", description = "Change the bars position horizontally. [Default: 500]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}
    subcat:createSlider{label = "Position Y:", description = "Change the bars position vertically. [Default: 100]", min = 0, max = 1000, step = 1, jump = 100, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}
    subcat:createSlider{label = "Transparency", description = "Change the bars transparency. 0 is fully transparent, 100 fully opaque. [Default: 50]", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "textfield", table = cf}}

    local category1 = page:createCategory("Auto Recasting:")
    category1:createKeyBinder{label = "Key for Auto Recast.", description = "Toggles auto recast of a spell once one of it's effect is depleted. Spell must have been casted by the player and not be an enchantment nor a potion. [Default: Alt+R]", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.r, isShiftDown = false, isAltDown = true, isControlDown = false}}}

    template:createExclusionsPage{label = "Valid Effects", leftListLabel = "Valid Effects", rightListLabel = "Unmanaged Effects", description = "Here you can configure which effects this mod will manage.", variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by "..mod.author.."] "..mod.ver.." Initialized!")
    for i,v in pairs (tes3.effect) do
        local f = tes3.getMagicEffect(v)
        if ((string.startswith(i, "summon") or string.startswith(i, "call") or string.startswith(i, "bound")) and (f and f.name and (cf.blocked[f.name] == nil))) then
            cf.blocked[f.name] = true
        end
    end
end event.register("initialized", initialized, {priority = -1000})