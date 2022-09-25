---@diagnostic disable: param-type-mismatch, assign-type-mismatch
local mod = {
    name = "Zilophos Item Editor",
    ver = "1.2",
    author = "Zilophos and Spammer",
    cf = {items = {},}}

local desc = require("Spammer/zilophosItemMod/desc")
local itemList = require("Spammer/zilophosItemMod/itemList")
local visual = require("Spammer/zilophosItemMod/visual")
local sort = require("Spammer/zilophosItemMod/sortList")
local tools = require("Spammer/zilophosItemMod/tools")
local spellOrPotion = require("Spammer/zilophosItemMod/spell_potions")

local cf = mwse.loadConfig(mod.name, mod.cf)

local originals = {}

local function editables(item)
    local editable = {
        name = (item.name ~= nil),
        value = (item.value ~= nil and (item.objectType ~= tes3.objectType.spell)),
        weight = (item.weight ~= nil),
        quality = (tools[item.objectType] ~= nil),
        armorRating = (item.objectType == tes3.objectType.armor),
        enchantCapacity = (item.enchantCapacity and (item.enchantCapacity ~= 0)),
        maxCondition = (item.maxCondition and (item.maxCondition ~= 0)),
        radius = (item.objectType == tes3.objectType.light),
        time = ((item.objectType == tes3.objectType.light) and item.canCarry),
        reach = (item.objectType == tes3.objectType.weapon),
        speed = (item.objectType == tes3.objectType.weapon),
        chopMin = (item.objectType == tes3.objectType.weapon) or (item.objectType == tes3.objectType.ammunition),
        chopMax = (item.objectType == tes3.objectType.weapon) or (item.objectType == tes3.objectType.ammunition),
        thrustMin = (item.objectType == tes3.objectType.weapon),
        thrustMax = (item.objectType == tes3.objectType.weapon),
        slashMin = (item.objectType == tes3.objectType.weapon),
        slashMax = (item.objectType == tes3.objectType.weapon),
        enchantment = (item.objectType == tes3.objectType.weapon) or (item.objectType == tes3.objectType.ammunition) or (item.objectType == tes3.objectType.armor) or (item.objectType == tes3.objectType.clothing) or ((item.objectType == tes3.objectType.book) and (item.type == 1)),
        skill = item.objectType == tes3.objectType.book,
        effects = ((item.objectType == tes3.objectType.ingredient) or (item.objectType == tes3.objectType.spell) or (item.objectType == tes3.objectType.alchemy)),
        effectSkillIds = false,
        effectAttributeIds = false,
        --basePurchaseCost = (item.objectType == tes3.objectType.spell),
        magickaCost = (item.objectType == tes3.objectType.spell),
        scale = (item.objectType ~= tes3.objectType.spell)
    }
    return editable
end

local function storeItem(item)
    item = tes3.getObject(item.id)
    if not item then return end
    originals[item.id] = {}
    local edit = editables(item)
    for i,v in pairs(edit) do
        if v and (i ~= "enchantment") and (i ~= "effects") then
            originals[item.id][i] = item[i]
        elseif (i == "enchantment") and v and item[i] then
            originals[item.id][i] = {}
            originals[item.id][i]["castType"] = item[i]["castType"]
            originals[item.id][i]["maxCharge"] = item[i]["maxCharge"]
            originals[item.id][i]["chargeCost"] = item[i]["schargeCost"]
            local k = "effects"
            originals[item.id][i][k] = {}
            for o = 1, 8 do
                originals[item.id][i][k][o] = {}
                originals[item.id][i][k][o]["id"] = item[i][k][o]["id"]
                originals[item.id][i][k][o]["min"] = item[i][k][o]["min"]
                originals[item.id][i][k][o]["max"] = item[i][k][o]["max"]
                originals[item.id][i][k][o]["radius"] = item[i][k][o]["radius"]
                originals[item.id][i][k][o]["duration"] = item[i][k][o]["duration"]
                originals[item.id][i][k][o]["skill"] = item[i][k][o]["skill"]
                originals[item.id][i][k][o]["attribute"] = item[i][k][o]["attribute"]
                originals[item.id][i][k][o]["rangeType"] = item[i][k][o]["rangeType"]
            end
        elseif (i == "effects") and v and (item.objectType == tes3.objectType.ingredient) then
            originals[item.id][i] = {}
            originals[item.id]["effectSkillIds"] = {}
            originals[item.id]["effectAttributeIds"] = {}
            for k = 1, 4 do
                originals[item.id][i][k] = item[i][k]
                originals[item.id]["effectSkillIds"][k] = item["effectSkillIds"][k]
                originals[item.id]["effectAttributeIds"][k] = item["effectAttributeIds"][k]
            end
        elseif (i == "effects") and v and (item[i]) and (item.objectType ~= tes3.objectType.ingredient) then
            originals[item.id][i] = {}
            for k = 1, spellOrPotion[item.objectType] do
                originals[item.id][i][k] = {}
                originals[item.id][i][k]["id"] = item[i][k]["id"]
                originals[item.id][i][k]["min"] = item[i][k]["min"]
                originals[item.id][i][k]["max"] = item[i][k]["max"]
                originals[item.id][i][k]["radius"] = item[i][k]["radius"]
                originals[item.id][i][k]["duration"] = item[i][k]["duration"]
                originals[item.id][i][k]["skill"] = item[i][k]["skill"]
                originals[item.id][i][k]["attribute"] = item[i][k]["attribute"]
                originals[item.id][i][k]["rangeType"] = item[i][k]["rangeType"]
            end
        end
    end
end

---comment
---@param item tes3object|table
---@param restore boolean?
local function editOneItem(item, restore)
    local mods = (restore and originals[item.id]) or cf.items[item.id] or (tes3.player and tes3.player.data.zilophosItemMod[item.id])
    local object = tes3.getObject(item.id)
    if mods and object then
        if tes3.player and tonumber(item.id) and (object.sourceMod == nil) then
            tes3.player.data.zilophosItemMod = tes3.player.data.zilophosItemMod or {}
            tes3.player.data.zilophosItemMod[item.id] = (cf["items"][item.id] and table.deepcopy(cf["items"][item.id])) or tes3.player.data.zilophosItemMod[item.id]
            cf["items"][item.id]= nil
            mwse.saveConfig(mod.name, cf)
            if not restore then
                mods = tes3.player.data.zilophosItemMod[item.id]
            else
                tes3.player.data.zilophosItemMod[item.id] = nil
            end
        end
        local edit = editables(object)
        for k,y in pairs(edit) do
            if (k ~= "enchantment") and ((k ~= "effects")) and y then
                object[k] = mods[k] or object[k]
            elseif ((object.objectType == tes3.objectType.ingredient) and ((k == "effects") and mods.effects)) then
                for i = 1, 4 do
                    object[k][i] = mods[k][i] or object[k][i]
                    object.effectSkillIds[i] = mods.effectSkillIds[i] or object.effectSkillIds[i]
                    object.effectAttributeIds[i] = mods.effectAttributeIds[i] or object.effectAttributeIds[i]
                end
            elseif ((k == "effects") and (object.objectType ~= tes3.objectType.ingredient) and mods.effects and y) then
                if object.objectType == tes3.objectType.spell then
                    object["alwaysSucceeds"] = mods["alwaysSucceeds"] or object["alwaysSucceeds"]
                    object["castType"] = mods["castType"] or object["castType"]
                    object["playerStart"] = mods["playerStart"] or object["playerStart"]
                end
                for index,effect in pairs(mods[k]) do
                    object[k][index]["id"] = effect["id"] or object[k][index]["id"]
                    object[k][index]["min"] = effect["min"] or object[k][index]["min"]
                    object[k][index]["max"] = effect["max"] or object[k][index]["max"]
                    object[k][index]["duration"] = effect["duration"] or object[k][index]["duration"]
                    object[k][index]["radius"] = effect["radius"] or object[k][index]["radius"]
                    object[k][index]["skill"] = effect["skill"] or object[k][index]["skill"]
                    object[k][index]["attribute"] = effect["attribute"] or object[k][index]["attribute"]
                    object[k][index]["rangeType"] = effect["rangeType"] or object[k][index]["rangeType"]
                end
            elseif (k == "enchantment") and (mods[k]) and y then
                for i,v in pairs(mods[k]) do
                    if (object[k]) and (i ~= "effects") and v then
                        object[k][i] = v or object[k][i]
                    elseif ((object[k]) and (i == "effects") and v) then
                        for index,effect in pairs(mods[k][i]) do
                            object[k][i][index]["id"] = effect["id"] or object[k][i][index]["id"]
                            object[k][i][index]["min"] = effect["min"] or object[k][i][index]["min"]
                            object[k][i][index]["max"] = effect["max"] or object[k][i][index]["max"]
                            object[k][i][index]["duration"] = effect["duration"] or object[k][i][index]["duration"]
                            object[k][i][index]["radius"] = effect["radius"] or object[k][i][index]["radius"]
                            object[k][i][index]["skill"] = effect["skill"] or object[k][i][index]["skill"]
                            object[k][i][index]["attribute"] = effect["attribute"] or object[k][i][index]["attribute"]
                            object[k][i][index]["rangeType"] = effect["rangeType"] or object[k][i][index]["rangeType"]
                        end
                    end
                end
            end
        end
    if restore then
        print(string.format("Zilophos Item Editor: Item \"%s\" (id: \"%s\") succesfully restored.", object.name, object.id))
    else
        print(string.format("Zilophos Item Editor: Item \"%s\" (id: \"%s\") succesfully modified.", object.name, object.id))
    end
    end
end

local function editItems()
    for id in pairs(cf.items) do
        if not originals[id] then
            storeItem{id = id}
            editOneItem{id = id}
        end
    end
    if tes3.player.data.zilophosItemMod then
        for id in pairs(tes3.player.data.zilophosItemMod) do
            if not originals[id] then
                storeItem{id = id}
                editOneItem{id = id}
            end
        end
    end
end event.register("loaded", editItems)

---comment
---@param scrollPane tes3uiElement
---@param rect tes3uiElement
---@param string string
---@param data string|number
---@param id string
---@return tes3uiElement
local function createEnchantBlock(scrollPane, rect, string, data, id)
    local block = scrollPane:createBlock()
    block.height = 30
    block.width = rect.width-20
    block.flowDirection = "left_to_right"
    block:createLabel{text = visual[string]}
    local text = block:createThinBorder():createTextInput{placeholderText = data}
    text.height = 30
    text.autoWidth = true
    text.parent.absolutePosAlignX = 1
    text.parent.width = 300
    text.parent.height = 30
    text.width = 88
    text.height = 28
    text.wrapText = true
    text.justifyText = "center"
    text.parent:register("mouseClick", function() text:triggerEvent("mouseClick") end)
    text.borderLeft = 5
    text.borderRight = 5
    text.widget.lengthLimit = 31
    text:registerAfter("textUpdated", function(e)
        local search = e.source.text
        if cf.items[id].enchantment["castType"] == tes3.enchantmentType.constant then
            e.source.text = 0
            return
        end
        if type(data) == "string" then
            cf.items[id].enchantment[string] = search
        else
            cf.items[id].enchantment[string] = tonumber(search) or data
        end
    end)
    text:registerAfter("textCleared", function(e)
        if cf.items[id].enchantment["castType"] == tes3.enchantmentType.constant then
            e.source.text = 0
            return
        end
        cf.items[id].enchantment[string] = originals[id].enchantment[string]
    end)
    text:registerBefore("mouseClick", function()
        if cf.items[id].enchantment["castType"] == tes3.enchantmentType.constant then
            tes3.messageBox("Constant effects can't have this option.")
            return false
        end
    end)
    return text
end

local function editEffectDeep(attr, item, i, type)
    local menu = tes3ui.createMenu{id = "Spa_zilophosSelectSkill", fixedFrame = true, modal = false}
    local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	menu.width = viewportWidth/4
	menu.height = viewportHeight/2
	menu.disabled = true
    local block = menu:createBlock()
    block.autoHeight = true
    block.autoWidth = true
    block.minWidth = 250
    block.flowDirection = "top_to_bottom"
    block.childAlignX = 0.5
    local text = block:createLabel{text = attr.." to mod:"}
    text.color = tes3ui.getPalette("header_color")
    block:createLabel{text = ""}
    local values
    if attr == "Skill" then
        values = table.values(tes3.skillName, true)
    else
        values = table.values(tes3.attributeName, true)
    end
    for k = 1, #values do
        local y = ((string.gsub(values[k], "^%l", string.upper)))
        local label = block:createTextSelect{text = y}
        label:register("mouseClick", function()
            if type == "ingredient" then
                if attr == "Skill" then
                    cf.items[item.id].effectSkillIds[i] = (table.find(tes3.skillName, y) or -1)
                    cf.items[item.id].effectAttributeIds[i] = (-1)
                else
                    cf.items[item.id].effectAttributeIds[i] = (table.find(tes3.attributeName, y:lower()) or -1)
                    cf.items[item.id].effectSkillIds[i] = (-1)
                end
            elseif type == "enchantment" then
                if attr == "Skill" then
                    cf["items"][item.id][type]["effects"][i]["skill"] = (table.find(tes3.skillName, y) or -1)
                    cf["items"][item.id][type]["effects"][i]["attribute"] = (-1)
                else
                    cf["items"][item.id][type]["effects"][i]["attribute"] = (table.find(tes3.attributeName, y:lower()) or -1)
                    cf["items"][item.id][type]["effects"][i]["skill"] = (-1)
                end
            else
                if attr == "Skill" then
                    cf["items"][item.id]["effects"][i]["skill"] = (table.find(tes3.skillName, y) or -1)
                    cf["items"][item.id]["effects"][i]["attribute"] = (-1)
                else
                    cf["items"][item.id]["effects"][i]["attribute"] = (table.find(tes3.attributeName, y:lower()) or -1)
                    cf["items"][item.id]["effects"][i]["skill"] = (-1)
                end
            end
        menu:destroy()
        end)
    end
    block:createLabel{text = ""}
end

---comment
---@param button tes3uiElement
---@param type string
---@param id string
---@param k number
---@param dur tes3uiElement?
---@param max tes3uiElement?
---@param rangeType tes3uiElement?
local function editEffect(button, type, id, k, dur, max, rangeType)
    local menu = tes3ui.createMenu{id = "Spa_zilophosSelectEffect", fixedFrame = true, modal = false}
    local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	menu.width = viewportWidth/4
	menu.height = viewportHeight/4
	menu.disabled = true
    local rect = menu:createRect()
    rect.height = viewportHeight/4
	rect.width = viewportWidth/4
	rect.flowDirection = "top_to_bottom"
    local scrollPane
    local text = rect:createBlock():createTextInput{placeholderText = "Search...", autoFocus = true}
    text.color = {0.8,0.8,0.8}
	text.height = 30
	text.width = rect.width-60
    text.parent.flowDirection = "left_to_right"
    text.parent.autoHeight = true
    text.parent.width = rect.width
    local button2 = text.parent:createButton{text = tostring(tes3.findGMST("sCancel").value)}
    button2.absolutePosAlignX = 1
    button2:register("mouseClick", function() menu:destroy() end)
	text:registerAfter("textUpdated", function(e)
		local search = e.source.text:lower()
        local pane = scrollPane:getContentElement()
        for _,child in pairs(pane.children) do
            child.visible = (string.find(child.name, search) ~= nil)
        end
	end)
	text:registerAfter("textCleared", function()
        local pane = scrollPane:getContentElement()
        for _,child in pairs(pane.children) do
            child.visible = true
        end
	end)
    scrollPane = rect:createVerticalScrollPane({ id = "ScrollContents" })
	scrollPane.autoHeight = true
	scrollPane.autoWidth = true
	scrollPane.maxHeight = rect.height-30
	scrollPane.maxWidth = rect.width
	scrollPane.minHeight = rect.height-30
    local names = {}
    local effects = {}
    for _,v in pairs(tes3.effect) do
        local item = tes3.getMagicEffect(v)
        if item then
            table.insert(names, item.name)
            effects[item.name] = item
        end
    end
    table.sort(names)
    for _,v in ipairs(names) do
        local item = effects[v]
        if item then
            local block = scrollPane:createBlock{id = string.lower(item.name)}
            block.autoHeight = true
            block.autoWidth = true
            block.flowDirection = "left_to_right"
            local path = (lfs.fileexists("Data Files\\Icons\\"..item.icon) and "Icons\\"..item.icon)
            if not path then
                path = "Icons\\Default Icon.tga"
                print("Icon File \"Data Files\\Icons\\"..item.icon.."\" not found.")
            end
            local icon = block:createImage{path = path}
            icon.scaleMode = true
            icon.height = 20
            icon.width = 20--]]
            local label = block:createTextSelect{text = " "..item.name}
            label:register("mouseClick", function()
                button.text = item.name
                local thing = {id = id}
                if dur and item.hasNoDuration then
                    dur.text = 0
                    dur:triggerEvent("textUpdated")
                end
                if max and item.hasNoMagnitude then
                    max.text = 1
                    max:triggerEvent("textUpdated")
                end
                if type == "ingredient" then
                    cf.items[id]["effects"][k] = item.id
                    if item.targetsAttributes then
                        editEffectDeep("Attribute", thing, k, type)
                    elseif item.targetsSkills then
                        editEffectDeep("Skill", thing, k, type)
                    else
                        cf.items[id].effectSkillIds[k] = -1
                        cf.items[id].effectAttributeIds[k] = -1
                    end
                elseif type == "enchantment" then
                    cf.items[id][type]["effects"][k]["id"] = item.id
                    if item.targetsAttributes then
                        editEffectDeep("Attribute", thing, k, type)
                    elseif item.targetsSkills then
                        editEffectDeep("Skill", thing, k, type)
                    else
                        cf["items"][id][type]["effects"][k]["skill"] = -1
                        cf["items"][id][type]["effects"][k]["attribute"] = -1
                    end
                else
                    cf.items[id]["effects"][k]["id"] = item.id
                    if item.targetsAttributes then
                        editEffectDeep("Attribute", thing, k, type)
                    elseif item.targetsSkills then
                        editEffectDeep("Skill", thing, k, type)
                    else
                        cf["items"][id]["effects"][k]["skill"] = -1
                        cf["items"][id]["effects"][k]["attribute"] = -1
                    end
                end
                if rangeType then
                   rangeType:triggerEvent("mouseClick")
                end
                menu:destroy()
            end)
        end
    end
end

local function editMenu(item)
    local parent = tes3ui.createMenu{id = "Spa_zilophosEditMenu", fixedFrame = true, modal = false}
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	parent.width = viewportWidth/3
    parent.autoHeight = true
	parent.minHeight = viewportHeight/3
    parent.maxHeight = viewportHeight/3
	parent.disabled = true
	local rect = parent:createRect()
	rect.autoHeight = true
    rect.minHeight = viewportHeight/3
    rect.maxHeight = viewportHeight/3
	rect.width = viewportWidth/3
	rect.flowDirection = "top_to_bottom"
    local scrollPane = rect:createVerticalScrollPane({ id = "ScrollContents" })
	scrollPane.autoHeight = true
	scrollPane.autoWidth = true
	scrollPane.maxHeight = rect.maxHeight-40
	scrollPane.maxWidth = rect.width
	scrollPane.minHeight = rect.maxHeight-40
    local list = editables(item)
    if not originals[item.id] then storeItem(item) end
    cf.items[item.id] = cf.items[item.id] or {}
    local keys = table.keys(list, function(a, b)
        return sort[a] < sort[b] end)
    for _,i in ipairs(keys) do
        local v = list[i]
        if v and (i ~= "enchantment") and (i ~= "skill") and (i ~= "effects") then
            local block = scrollPane:createBlock()
            block.height = 30
            block.width = rect.width-20
            block.flowDirection = "left_to_right"
            block:createLabel{text = visual[i]..":"}
            local text = block:createThinBorder():createTextInput{placeholderText = item[i]}
	        text.height = 30
	        text.autoWidth = true
            text.parent.absolutePosAlignX = 1
            text.parent.width = 300
            text.parent.height = 30
            text.width = 88
            text.height = 28
            text.wrapText = true
            text.justifyText = "center"
            text.parent:register("mouseClick", function() text:triggerEvent("mouseClick") end)
            text.borderLeft = 5
            text.borderRight = 5
            text.widget.lengthLimit = 31
	        text:registerAfter("textUpdated", function(e)
		        local search = e.source.text
                if type(item[i]) == "string" then
                    cf.items[item.id][i] = search
                else
                    cf.items[item.id][i] = tonumber(search) or item[i]
                end
	        end)
	        text:registerAfter("textCleared", function()
                cf.items[item.id][i] = item[i]
	        end)
        elseif v and (i == "effects") then
            if item.objectType == tes3.objectType.ingredient then
                cf.items[item.id].effects = cf.items[item.id].effects or {item.effects[1], item.effects[2], item.effects[3], item.effects[4]}
                cf.items[item.id].effectSkillIds = cf.items[item.id].effectSkillIds or {item.effectSkillIds[1], item.effectSkillIds[2], item.effectSkillIds[3], item.effectSkillIds[4]}
                cf.items[item.id].effectAttributeIds = cf.items[item.id].effectAttributeIds or {item.effectAttributeIds[1], item.effectAttributeIds[2], item.effectAttributeIds[3], item.effectAttributeIds[4]}
                for k = 1, 4 do
                    local block = scrollPane:createBlock()
                    block.height = 30
                    block.width = rect.width-20
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = "Effect "..k}
                    local eff = (item.effects[k] ~=-1 and tes3.getMagicEffect(item.effects[k])) or {name = "None.", targetsSkills = false, targetsAttributes = false, id = -1}
                    local text = block:createButton{text = eff.name}
                    text.absolutePosAlignX = 1
                    text:register("mouseClick", function()
                        editEffect(text, "ingredient", item.id, k)
                    end)
                    text:register("help", function()
                        if (cf.items[item.id]["effects"] ~= -1 and cf.items[item.id].effectSkillIds[k] ~= -1) then
                            local tool = tes3ui.createTooltipMenu()
                            local block1 = tool:createBlock()
                            block1.autoHeight = true
                            block1.autoWidth = true
                            local text1 = "Attribute: "..((string.gsub(tes3.attributeName[cf.items[item.id].effectAttributeIds[k]], "^%l", string.upper)))
                            block1:createLabel{text = text1}
                        elseif (cf.items[item.id]["effects"] ~= -1 and cf.items[item.id].effectAttributeIds[k] ~= -1) then
                            local tool = tes3ui.createTooltipMenu()
                            local block1 = tool:createBlock()
                            block1.autoHeight = true
                            block1.autoWidth = true
                            local text1 = "Skill: "..tes3.skillName[cf.items[item.id].effectSkillIds[k]]
                            block1:createLabel{text = text1}
                        end
                    end)
                end
            else
                if item.objectType == tes3.objectType.spell then
                    local block = scrollPane:createBlock()
                    block.height = 30
                    block.width = rect.width-20
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = "Always Succeeds"}
                    cf.items[item.id]["alwaysSucceeds"] = item.alwaysSucceeds
                    local text = block:createButton{text = tostring(cf.items[item.id]["alwaysSucceeds"])}
                    text.absolutePosAlignX = 1
                    text:register("mouseClick", function()
                        cf.items[item.id]["alwaysSucceeds"] = not cf.items[item.id]["alwaysSucceeds"]
                        text.text = tostring(cf.items[item.id]["alwaysSucceeds"])
                    end)
                    block = scrollPane:createBlock()
                    block.height = 30
                    block.width = rect.width-20
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = "Spell Type"}
                    cf.items[item.id]["castType"] = item.castType
                    local now = cf.items[item.id]["castType"]
                    local name = ((string.gsub(table.find(tes3.spellType, now), "^%l", string.upper)))
                    local text1 = block:createButton{text = name}
                    text1.absolutePosAlignX = 1
                    text1:register("mouseClick", function()
                        if now == 5 then now = 0 else now = now+1 end
                        cf.items[item.id]["castType"] = now
                        name = ((string.gsub(table.find(tes3.spellType, now), "^%l", string.upper)))
                        text1.text = name
                    end)
                    block = scrollPane:createBlock()
                    block.height = 30
                    block.width = rect.width-20
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = "Start Spell"}
                    cf.items[item.id]["playerStart"] = item.playerStart
                    local text2 = block:createButton{text = tostring(cf.items[item.id]["playerStart"])}
                    text2.absolutePosAlignX = 1
                    text2:register("mouseClick", function()
                        cf.items[item.id]["playerStart"] = not cf.items[item.id]["playerStart"]
                        text2.text = tostring(cf.items[item.id]["playerStart"])
                    end)
                end
                local block = scrollPane:createBlock()
                block.height = 30
                block.width = rect.width-20
                block.flowDirection = "left_to_right"
                block:createLabel{text = ""}
                cf.items[item.id][i] = {}
                for index = 1, spellOrPotion[item.objectType] do
                    local block2 = scrollPane:createBlock()
                    block2.height = 30
                    block2.width = rect.width-20
                    block2.flowDirection = "left_to_right"
                    local eff = item[i][index]
                    cf.items[item.id][i][index] = cf.items[item.id][i][index] or {id = eff.id, duration = eff.duration, max = eff.max, min = eff.min, radius = eff.radius, rangeType = eff.rangeType, skill = eff.skill, attribute = eff.attribute}
                    local effectName
                if eff.id == -1 then
                    effectName = "None."
                else
                    effectName = eff.object.name
                end
                block2:createLabel{text = "Effect "..index}
                local text = block2:createButton{text = effectName}
                text.absolutePosAlignX = 1
                text:register("mouseClick", function()
                    local menu = tes3ui.createMenu{id = "effectThing", fixedFrame = true}
                    menu.height = viewportHeight*3/4
                    menu.width = viewportWidth/4
                    menu.flowDirection = "top_to_bottom"
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = "Effect"}
                    local text2 = block:createButton{text = text.text}
                    text2.absolutePosAlignX = 1
                    local duration, min, max, radius , text3
                    text2:register("mouseClick", function()
                        editEffect(text2, i, item.id, index, duration, max, text3)
                    end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.rangeType}
                    local the = cf["items"][item.id][i][index]["rangeType"]
                    text3 = block:createButton{text = ((string.gsub(table.find(tes3.effectRange, cf["items"][item.id][i][index]["rangeType"]), "^%l", string.upper)))}
                    text3.absolutePosAlignX = 1
                    text3:register("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i][index]["id"])
                        if not newEff then return end
                        if the == 2 then the = 0 else the = the+1 end
                        if not newEff.canCastSelf and (the == tes3.effectRange.self) then
                            text3:triggerEvent("mouseClick")
                            return
                        end
                        if not newEff.canCastTouch and (the == tes3.effectRange.touch) then
                            text3:triggerEvent("mouseClick")
                            return
                        end
                        if not newEff.canCastTarget and (the == tes3.effectRange.target) then
                            text3:triggerEvent("mouseClick")
                            return
                        end
                        cf["items"][item.id][i][index]["rangeType"] = the
                        text3.text = ((string.gsub(table.find(tes3.effectRange, the), "^%l", string.upper)))
                    end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.min}
                    min = block:createThinBorder():createTextInput{placeholderText = eff.min, numeric = true}
	                min.height = 30
	                min.autoWidth = true
                    min.parent.absolutePosAlignX = 1
                    min.parent.width = 300
                    min.parent.height = 30
                    min.width = 88
                    min.height = 28
                    min.wrapText = true
                    min.justifyText = "center"
                    min.parent:register("mouseClick", function() min:triggerEvent("mouseClick") end)
                    min.borderLeft = 5
                    min.borderRight = 5
                    min.widget.lengthLimit = 3
	                min:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text) or eff.min
                        local limit = tonumber(max.text) or eff.max
                        cf["items"][item.id][i][index]["min"] = search
                        max.text = math.max(limit, search)
                        cf["items"][item.id][i][index]["max"] = tonumber(max.text)
	                end)
	                min:registerAfter("textCleared", function()
                        cf.items[item.id][i].effects[index]["min"] = eff.min
	                end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.max}
                    max = block:createThinBorder():createTextInput{placeholderText = eff.max, numeric = true}
	                max.height = 30
	                max.autoWidth = true
                    max.parent.absolutePosAlignX = 1
                    max.parent.width = 300
                    max.parent.height = 30
                    max.width = 88
                    max.height = 28
                    max.wrapText = true
                    max.justifyText = "center"
                    max.parent:register("mouseClick", function() max:triggerEvent("mouseClick") end)
                    max.borderLeft = 5
                    max.borderRight = 5
                    max.widget.lengthLimit = 3
                    max:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text) or eff.max
                        local limit = tonumber(min.text) or eff.min
                        cf["items"][item.id][i][index]["max"] = search
                        min.text = math.min(limit, search)
                        cf["items"][item.id][i][index]["min"] = tonumber(min.text)
	                end)
	                max:registerAfter("textCleared", function()
                        cf["items"][item.id][i][index]["max"] = eff.max
	                end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.duration}
                    duration = block:createThinBorder():createTextInput{placeholderText = eff.duration, numeric = true}
	                duration.height = 30
	                duration.autoWidth = true
                    duration.parent.absolutePosAlignX = 1
                    duration.parent.width = 300
                    duration.parent.height = 30
                    duration.width = 88
                    duration.height = 28
                    duration.wrapText = true
                    duration.justifyText = "center"
                    duration.parent:register("mouseClick", function() duration:triggerEvent("mouseClick") end)
                    duration.borderLeft = 5
                    duration.borderRight = 5
                    duration.widget.lengthLimit = 4
                    duration:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text)
                        cf["items"][item.id][i][index]["duration"] = search or eff.duration
	                end)
	                duration:registerAfter("textCleared", function()
                        cf["items"][item.id][i][index]["duration"] = eff.duration
	                end)
                    min:registerBefore("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i][index]["id"])
                        if not newEff then return false end
                        if newEff.hasNoMagnitude then
                            tes3.messageBox("This effect has no magnitude.")
                            return false
                        end
                    end)
                    max:registerBefore("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i][index]["id"])
                        if not newEff then return false end
                        if newEff.hasNoMagnitude then
                            tes3.messageBox("This effect has no magnitude.")
                            return false
                        end
                    end)
                    duration:registerBefore("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i][index]["id"])
                        if not newEff then return false end
                        if newEff.hasNoDuration then
                            tes3.messageBox("This effect has no duration.")
                            return false
                        end
                    end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.radius}
                    radius = block:createThinBorder():createTextInput{placeholderText = eff.radius, numeric = true}
	                radius.height = 30
	                radius.autoWidth = true
                    radius.parent.absolutePosAlignX = 1
                    radius.parent.width = 300
                    radius.parent.height = 30
                    radius.width = 88
                    radius.height = 28
                    radius.wrapText = true
                    radius.justifyText = "center"
                    radius.parent:register("mouseClick", function() radius:triggerEvent("mouseClick") end)
                    radius.borderLeft = 5
                    radius.borderRight = 5
                    radius.widget.lengthLimit = 4
                    radius:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text)
                        cf["items"][item.id][i][index]["radius"] = search or eff.radius
	                end)
	                radius:registerAfter("textCleared", function()
                        cf["items"][item.id][i][index]["radius"] = eff.radius
	                end)
                    local butt = menu:createButton{text = tostring(tes3.findGMST("sClose").value)}
                    butt.absolutePosAlignX = 0.99
                    butt:register("mouseClick", function()
                        text.text = text2.text
                        menu:destroy()
                    end)
                end)
                text:register("help", function()
                    if (cf["items"][item.id][i][index]["id"] ~= -1 and cf["items"][item.id][i][index]["attribute"] ~= -1) then
                        local tool = tes3ui.createTooltipMenu()
                        local block1 = tool:createBlock()
                        block1.autoHeight = true
                        block1.autoWidth = true
                        local text1 = "Attribute: "..((string.gsub(tes3.attributeName[cf["items"][item.id][i][index]["attribute"]], "^%l", string.upper)))
                        block1:createLabel{text = text1}
                    elseif (cf["items"][item.id][i][index]["id"] ~= -1 and cf["items"][item.id][i][index]["skill"] ~= -1) then
                        local tool = tes3ui.createTooltipMenu()
                        local block1 = tool:createBlock()
                        block1.autoHeight = true
                        block1.autoWidth = true
                        local text1 = "Skill: "..tes3.skillName[cf["items"][item.id][i][index]["skill"]]
                        block1:createLabel{text = text1}
                    end
                end)
                end
            end
        elseif v and (i == "skill") then
            cf.items[item.id][i] = item[i]
            local block = scrollPane:createBlock()
            block.height = 30
            block.width = rect.width-20
            block.flowDirection = "left_to_right"
            block:createLabel{text = visual[i]..":"}
            local hello = (item[i] ~=-1 and tes3.skillName[item[i]]) or "None."
            local text = block:createButton{text = hello}
            text.absolutePosAlignX = 1
            text:register("mouseClick", function()
                local menu = tes3ui.createMenu{id = "Spa_zilophosSelectSkill", fixedFrame = true, modal = false}
	            menu.width = viewportWidth/4
	            menu.height = viewportHeight/2
	            menu.disabled = true
                local values = table.values(tes3.skillName, function(a,b) return a > b end)
                for k = #values, 0, -1 do
                    local y = values[k] or "None"
                    local label = menu:createTextSelect{text = y}
                    label:register("mouseClick", function()
                        cf.items[item.id].skill = (table.find(tes3.skillName, y) or -1)
                        text.text = y
                        text:getTopLevelMenu():updateLayout()
                        menu:destroy()
                    end)
                end
            end)
        elseif v and (i == "enchantment") and item.enchantment then
            cf.items[item.id][i] = cf.items[item.id][i] or {effects = {}, castType = item[i].castType, chargeCost = item[i].chargeCost, maxCharge = item[i].maxCharge}
            if item.objectType ~= tes3.objectType.book then
                local chargeCost = createEnchantBlock(scrollPane, rect, "chargeCost", item[i].chargeCost, item.id)
                local maxCharge = createEnchantBlock(scrollPane, rect, "maxCharge", item[i].maxCharge, item.id)
                local types = {
                    [1] = "Cast On Strike",
                    [2] = "Cast On Use",
                    [3] = "Constant Effect"}
                local block = scrollPane:createBlock()
                block.height = 30
                block.width = rect.width-20
                block.flowDirection = "left_to_right"
                block:createLabel{text = visual.castType}
                local now = item[i].castType
                local text = block:createButton{text = types[now]}
                text.absolutePosAlignX = 1
                text:register("mouseClick", function()
                    if now == 3 then now = 1 else now = now+1 end
                    if ((item.objectType ~= tes3.objectType.weapon) and (now == 1)) then now = 2 end
                    text.text = types[now]
                    cf.items[item.id][i].castType = now
                    chargeCost:triggerEvent("textUpdated")
                    maxCharge:triggerEvent("textUpdated")
                end)
            end
            for index = 1, 8 do
                local block2 = scrollPane:createBlock()
                block2.height = 30
                block2.width = rect.width-20
                block2.flowDirection = "left_to_right"
                local eff = item[i].effects[index]
                    cf.items[item.id][i].effects[index] = cf.items[item.id][i].effects[index] or {id = eff.id, duration = eff.duration, max = eff.max, min = eff.min, radius = eff.radius, rangeType = eff.rangeType, skill = eff.skill, attribute = eff.attribute}
                local effectName
                if eff.id == -1 then
                    effectName = "None."
                else
                    effectName = eff.object.name
                end
                block2:createLabel{text = "Effect "..index}
                local text = block2:createButton{text = effectName}
                text.absolutePosAlignX = 1
                text:register("mouseClick", function()
                    local menu = tes3ui.createMenu{id = "effectThing", fixedFrame = true}
                    menu.height = viewportHeight*3/4
                    menu.width = viewportWidth/4
                    menu.flowDirection = "top_to_bottom"
                    local block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = "Effect"}
                    local text2 = block:createButton{text = text.text}
                    text2.absolutePosAlignX = 1
                    local duration, min, max, radius ,text3
                    text2:register("mouseClick", function()
                        editEffect(text2, i, item.id, index, duration, max, text3)
                    end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.rangeType}
                    local the = cf["items"][item.id][i]["effects"][index]["rangeType"]
                    text3 = block:createButton{text = ((string.gsub(table.find(tes3.effectRange, the), "^%l", string.upper)))}
                    text3.absolutePosAlignX = 1
                    text3:register("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i]["effects"][index]["id"])
                        if not newEff then return end
                        if the == 2 then the = 0 else the = the+1 end
                        if not newEff.canCastSelf and (the == tes3.effectRange.self) then
                            text3:triggerEvent("mouseClick")
                            return
                        end
                        if not newEff.canCastTarget and (the == tes3.effectRange.target) then
                            text3:triggerEvent("mouseClick")
                            return
                        end
                        if not newEff.canCastTouch and (the == tes3.effectRange.touch) then
                            text3:triggerEvent("mouseClick")
                            return
                        end
                        cf["items"][item.id][i]["effects"][index]["rangeType"] = the
                        text3.text = ((string.gsub(table.find(tes3.effectRange, the), "^%l", string.upper)))
                    end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.min}
                    min = block:createThinBorder():createTextInput{placeholderText = eff.min, numeric = true}
	                min.height = 30
	                min.autoWidth = true
                    min.parent.absolutePosAlignX = 1
                    min.parent.width = 300
                    min.parent.height = 30
                    min.width = 88
                    min.height = 28
                    min.wrapText = true
                    min.justifyText = "center"
                    min.parent:register("mouseClick", function() min:triggerEvent("mouseClick") end)
                    min.borderLeft = 5
                    min.borderRight = 5
                    min.widget.lengthLimit = 3
	                min:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text) or eff.min
                        local limit = tonumber(max.text) or eff.max
                        cf["items"][item.id][i]["effects"][index]["min"] = search
                        max.text = math.max(limit, search)
                        cf["items"][item.id][i]["effects"][index]["max"] = tonumber(max.text)
	                end)
	                min:registerAfter("textCleared", function()
                        cf.items[item.id][i].effects[index]["min"] = eff.min
	                end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.max}
                    max = block:createThinBorder():createTextInput{placeholderText = eff.max, numeric = true}
	                max.height = 30
	                max.autoWidth = true
                    max.parent.absolutePosAlignX = 1
                    max.parent.width = 300
                    max.parent.height = 30
                    max.width = 88
                    max.height = 28
                    max.wrapText = true
                    max.justifyText = "center"
                    max.parent:register("mouseClick", function() max:triggerEvent("mouseClick") end)
                    max.borderLeft = 5
                    max.borderRight = 5
                    max.widget.lengthLimit = 3
                    max:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text) or eff.max
                        local limit = tonumber(min.text) or eff.min
                        cf["items"][item.id][i]["effects"][index]["max"] = search
                        min.text = math.min(limit, search)
                        cf["items"][item.id][i]["effects"][index]["min"] = tonumber(min.text)
	                end)
	                max:registerAfter("textCleared", function()
                        cf["items"][item.id][i]["effects"][index]["max"] = eff.max
	                end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.duration}
                    duration = block:createThinBorder():createTextInput{placeholderText = eff.duration, numeric = true}
	                duration.height = 30
	                duration.autoWidth = true
                    duration.parent.absolutePosAlignX = 1
                    duration.parent.width = 300
                    duration.parent.height = 30
                    duration.width = 88
                    duration.height = 28
                    duration.wrapText = true
                    duration.justifyText = "center"
                    duration.parent:register("mouseClick", function() duration:triggerEvent("mouseClick") end)
                    duration.borderLeft = 5
                    duration.borderRight = 5
                    duration.widget.lengthLimit = 4
                    duration:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text)
                        cf["items"][item.id][i]["effects"][index]["duration"] = search or eff.duration
	                end)
	                duration:registerAfter("textCleared", function()
                        cf["items"][item.id][i]["effects"][index]["duration"] = eff.duration
	                end)
                    min:registerBefore("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i]["effects"][index]["id"])
                        if not newEff then return false end
                        if newEff.hasNoMagnitude then
                            tes3.messageBox("This effect has no magnitude.")
                            return false
                        end
                    end)
                    max:registerBefore("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i]["effects"][index]["id"])
                        if not newEff then return false end
                        if newEff.hasNoMagnitude then
                            tes3.messageBox("This effect has no magnitude.")
                            return false
                        end
                    end)
                    duration:registerBefore("mouseClick", function()
                        local newEff = tes3.getMagicEffect(cf["items"][item.id][i]["effects"][index]["id"])
                        if not newEff then return false end
                        if newEff.hasNoDuration then
                            tes3.messageBox("This effect has no duration.")
                            return false
                        end
                    end)
                    block = menu:createBlock()
                    block.height = 30
                    block.width = menu.width
                    block.flowDirection = "left_to_right"
                    block:createLabel{text = visual.radius}
                    radius = block:createThinBorder():createTextInput{placeholderText = eff.radius, numeric = true}
	                radius.height = 30
	                radius.autoWidth = true
                    radius.parent.absolutePosAlignX = 1
                    radius.parent.width = 300
                    radius.parent.height = 30
                    radius.width = 88
                    radius.height = 28
                    radius.wrapText = true
                    radius.justifyText = "center"
                    radius.parent:register("mouseClick", function() radius:triggerEvent("mouseClick") end)
                    radius.borderLeft = 5
                    radius.borderRight = 5
                    radius.widget.lengthLimit = 4
                    radius:registerAfter("textUpdated", function(e)
		                local search = tonumber(e.source.text)
                        cf["items"][item.id][i]["effects"][index]["radius"] = search or eff.radius
	                end)
	                radius:registerAfter("textCleared", function()
                        cf["items"][item.id][i]["effects"][index]["radius"] = eff.radius
	                end)
                    local butt = menu:createButton{text = tostring(tes3.findGMST("sClose").value)}
                    butt.absolutePosAlignX = 0.99
                    butt:register("mouseClick", function()
                        text.text = text2.text
                        menu:destroy()
                    end)
                end)
                text:register("help", function()
                    if (cf["items"][item.id][i]["effects"][index]["id"] ~= -1 and cf["items"][item.id][i]["effects"][index]["attribute"] ~= -1) then
                        local tool = tes3ui.createTooltipMenu()
                        local block1 = tool:createBlock()
                        block1.autoHeight = true
                        block1.autoWidth = true
                        local text1 = "Attribute: "..((string.gsub(tes3.attributeName[cf["items"][item.id][i]["effects"][index]["attribute"]], "^%l", string.upper)))
                        block1:createLabel{text = text1}
                    elseif (cf["items"][item.id][i]["effects"][index]["id"] ~= -1 and cf["items"][item.id][i]["effects"][index]["skill"] ~= -1) then
                        local tool = tes3ui.createTooltipMenu()
                        local block1 = tool:createBlock()
                        block1.autoHeight = true
                        block1.autoWidth = true
                        local text1 = "Skill: "..tes3.skillName[cf["items"][item.id][i]["effects"][index]["skill"]]
                        block1:createLabel{text = text1}
                    end
                end)
            end
        end
    end
    local block2 = rect:createBlock()
    block2.autoHeight = true
    block2.width = rect.width
    block2.flowDirection = "left_to_right"
    local id = block2:createLabel{text = "id: "..item.id}
    id.absolutePosAlignX = 0
    local block3 = block2:createBlock()
    block3.flowDirection = "left_to_right"
    block3.height = 40
    block3.autoWidth = true
    block3.absolutePosAlignX = 1
    block3.childAlignX = 1
    local button = block3:createButton{text = tostring(tes3.findGMST("sCancel").value)}
    button:register("mouseClick", function()
        timer.frame.delayOneFrame(function() parent:destroy() end)
    end)
    button = block3:createButton{text = tostring(tes3.findGMST("sSave").value)}
    button:register("mouseClick", function()
        cf["items"][item.id]["name"] = cf["items"][item.id]["name"] or item.name
        mwse.saveConfig(mod.name, cf)
        editOneItem(item)
        timer.frame.delayOneFrame(function() parent:destroy() end)
        tes3.messageBox("Item Saved!")
    end) --]]
    parent:register("mouseOver", function()
        local bar = scrollPane:findChild("PartScrollPane_vert_scrollbar")
        local content = scrollPane:getContentElement()
        bar.visible = (content.height > parent.height)
    end)
end

local function firstMenu(filter)
    local parent = tes3ui.createMenu{id = "Spa_zilophosSelectMenu", fixedFrame = true, modal = false}
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()
	parent.width = viewportWidth/3
	parent.height = viewportHeight/3
	parent.disabled = true
	local rect = parent:createRect()
	rect.autoHeight = true
	rect.width = viewportWidth/3
	rect.maxHeight = viewportHeight/3
	rect.flowDirection = "top_to_bottom"
    local scrollPane
    local text = rect:createBlock():createTextInput{placeholderText = "Search...", autoFocus = true}
    text.color = {0.8,0.8,0.8}
	text.height = 30
	text.width = rect.width-60
    text.parent.flowDirection = "left_to_right"
    text.parent.autoHeight = true
    text.parent.width = rect.width
    local button = text.parent:createButton{text = tostring(tes3.findGMST("sCancel").value)}
    button.absolutePosAlignX = 1
    button:register("mouseClick", function() parent:destroy() end)
	text:registerAfter("textUpdated", function(e)
		local search = e.source.text:lower()
        local pane = scrollPane:getContentElement()
        for _,child in pairs(pane.children) do
            child.visible = ((string.find(child.name, search) ~= nil))
        end
	end)
	text:registerAfter("textCleared", function()
        local pane = scrollPane:getContentElement()
        for _,child in pairs(pane.children) do
            child.visible = true
        end
	end)
	scrollPane = rect:createVerticalScrollPane({ id = "ScrollContents" })
	scrollPane.autoHeight = true
	scrollPane.autoWidth = true
	scrollPane.maxHeight = rect.maxHeight-30
	scrollPane.maxWidth = rect.width
	scrollPane.minHeight = rect.maxHeight-30
    for item in tes3.iterateObjects(filter) do
        if item.name and item.name ~= "" then
            local block = scrollPane:createBlock{id = string.lower(item.name)}
            block.autoHeight = true
            block.autoWidth = true
            block.flowDirection = "left_to_right"
            local iconPath = ((item.objectType ~= tes3.objectType.spell) and item.icon) or item.effects[1].object.bigIcon
            local ddsIcon = ((string.gsub(iconPath, ".tga", ".dds")))


            local function getFileSourceWithBSA(path)
	            local source = tes3.getFileSource(path)
	            local bsaFile = nil
	            if (source == "bsa") then
		            local archive = tes3.bsaLoader:findFile(path)
		            if (archive) then
			            bsaFile = archive.path
		            end
	            end
	        return source, path, bsaFile
            end

            local iconBSAFile, iconSource, path
            if (ddsIcon) then
                iconSource, ddsIcon, iconBSAFile = getFileSourceWithBSA("Icons\\"..ddsIcon)
                path = ((iconBSAFile or iconSource) and ddsIcon)
            end
            if ((iconPath) and not(path)) then
                iconSource, iconPath, iconBSAFile = getFileSourceWithBSA("Icons\\"..iconPath)
                path = ((iconBSAFile or iconSource) and iconPath)
            end

            if not path then
                path = "Icons\\Default Icon.tga"
                print("Icon File \"Data Files\\Icons\\"..iconPath.."\" for item \""..item.name.."\" (id: \""..item.id.."\") not found.")
            end
            local icon = block:createImage{path = path}
            icon.scaleMode = true
            icon.height = 20
            icon.width = 20
            local label = block:createTextSelect{text = " "..item.name}
            label:register("help", function()
                if (tes3.player) then
                    tes3ui.createTooltipMenu{item = ((item.objectType ~= tes3.objectType.spell) and item) or nil, spell = ((item.objectType == tes3.objectType.spell) and item) or nil}
                end
            end)
            label:register("mouseClick", function()
                editMenu(item)
                parent:destroy()
            end)
            icon:register("mouseClick", function()
                editMenu(item)
                parent:destroy()
            end)
        end
    end
end



local modConfig = {}
function modConfig.onSearch(search)
    return string.startswith("spammer", search)
end
---comment
---@param parent tes3uiElement
function modConfig.onCreate(parent)
    parent.flowDirection = "left_to_right"
	local page = parent:createThinBorder{}
	page.flowDirection = "top_to_bottom"
	page.layoutHeightFraction = 1.0
	page.layoutWidthFraction = 1.0
	page.paddingAllSides = 12
    page.childAlignX = 0.5
    --page.childAlignY = 0.5
    local page2 = parent:createThinBorder{}
	page2.flowDirection = "top_to_bottom"
	page2.layoutHeightFraction = 1.0
	page2.layoutWidthFraction = 1.0
	page2.paddingAllSides = 12
    local label = page2:createLabel{text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by "..mod.author..".\n"}
    local link2 = page2:createHyperlink{ text = "Zilophos's Nexus Profile", url = "https://www.nexusmods.com/users/18092484?tab=user+files" }
    local link = page2:createHyperlink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local armor = page2:createLabel{text = desc.armor}
    armor.wrapText = true
    armor.visible = false
    local books = page2:createLabel{text = desc.books}
    books.wrapText = true
    books.visible = false
    local clothing = page2:createLabel{text = desc.clothing}
    clothing.wrapText = true
    clothing.visible = false
    local consumables = page2:createLabel{text = desc.consumables}
    consumables.wrapText = true
    consumables.visible = false
    local lights = page2:createLabel{text = desc.lights}
    lights.wrapText = true
    lights.visible = false
    local misc = page2:createLabel{text = desc.misc}
    misc.wrapText = true
    misc.visible = false
    local tools2 = page2:createLabel{text = desc.tools}
    tools2.wrapText = true
    tools2.visible = false
    local spells = page2:createLabel{text = desc.spells}
    spells.wrapText = true
    spells.visible = false
    local weapons = page2:createLabel{text = desc.weapons}
    weapons.wrapText = true
    weapons.visible = false
    local fullReset = page2:createLabel{text = desc.reset}
    fullReset.wrapText = true
    fullReset.visible = false
    local header = page:createLabel{text = "Item Editor"}
	header.color = tes3ui.getPalette("header_color")
	header.borderAllSides = 12
    local button
    button = page:createButton{text = "Edit Armors & Shields"}
    button:register("mouseClick", function()
        firstMenu{tes3.objectType.armor}
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        armor.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        armor.visible = false
    end)
    button = page:createButton{text = "Edit Books"}
    button:register("mouseClick",function()
        firstMenu{tes3.objectType.book}
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        books.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        books.visible = false
    end)
    button = page:createButton{text = "Edit Clothing"}
    button:register("mouseClick", function()
        firstMenu{tes3.objectType.clothing}
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        clothing.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        clothing.visible = false
    end)
    button = page:createButton{text = "Edit Consumables"}
    button:register("mouseClick",function()
        firstMenu({tes3.objectType.alchemy, tes3.objectType.ingredient})
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        consumables.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        consumables.visible = false
    end)
    button = page:createButton{text = "Edit Lights"}
    button:register("mouseClick",function()
        firstMenu({tes3.objectType.light})
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        lights.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        lights.visible = false
    end)
    button = page:createButton{text = "Edit Miscellaneous Items"}
    button:register("mouseClick",function()
        firstMenu({tes3.objectType.miscItem})
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        misc.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        misc.visible = false
    end)
    button = page:createButton{text = "Edit Spells"}
    button:register("mouseClick",function()
        firstMenu{tes3.objectType.spell}
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        spells.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        spells.visible = false
    end)
    button = page:createButton{text = "Edit Tools"}
    button:register("mouseClick",function()
        firstMenu{tes3.objectType.probe, tes3.objectType.lockpick, tes3.objectType.apparatus, tes3.objectType.repairItem}
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        tools2.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        tools2.visible = false
    end)
    button = page:createButton{text = "Edit Weapons"}
    button:register("mouseClick",function()
        firstMenu{tes3.objectType.weapon, tes3.objectType.ammunition}
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        weapons.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        weapons.visible = false
    end)

    page:createLabel{text = ""}

    button = page:createButton{text = "Reset Items"}
    button:register("mouseClick",function()
        if table.empty(cf.items, true) then
            tes3.messageBox("You have no edited items.")
            return
        end
        local menu = tes3ui.createMenu{id = "Spa_ZilophosResetItem", fixedFrame = true, modal = false}
	    local viewportWidth, viewportHeight = tes3ui.getViewportSize()
        menu.height = viewportHeight/3
        menu.width = viewportWidth/3
        local rect = menu:createRect()
	    rect.autoHeight = true
	    rect.width = viewportWidth/3
	    rect.maxHeight = viewportHeight/3
	    rect.flowDirection = "top_to_bottom"
        local scrollPane = rect:createVerticalScrollPane({ id = "ScrollContents" })
        scrollPane.autoHeight = true
        scrollPane.autoWidth = true
        scrollPane.maxHeight = rect.maxHeight-30
        scrollPane.maxWidth = rect.width
        scrollPane.minHeight = rect.maxHeight-30
        local keys = table.keys(cf["items"])
        local _, errMsg = pcall(function()
            table.sort(keys, function(a,b)
                return (tes3.getObject(a) and tes3.getObject(b) and (tes3.getObject(a).name < tes3.getObject(b).name)) or (cf["items"][a]["name"] < cf["items"][b]["name"])
            end)
        end)
        if errMsg then print(errMsg) end
        for _,i in ipairs(keys) do
            local item = tes3.getObject(i) or {id = i, name = cf["items"][i]["name"]}
            local text = scrollPane:createTextSelect{text = item.name}
            text:register("mouseClick", function()
                editOneItem(item, true)
                cf["items"][i] = nil
                mwse.saveConfig(mod.name, cf)
                tes3.messageBox("%s has reverted to its default values.", text.text)
                text.visible = false
            end)
        end
        local block2 = menu:createBlock()
        block2.width = menu.width
        block2.height = 30
        block2.flowDirection = "left_to_right"
        block2 = block2:createBlock()
        block2.autoWidth = true
        block2.height = 30
        block2.flowDirection = "left_to_right"
        block2.absolutePosAlignX = 1
        local reset = block2:createButton{text = 'Reset All'}
        reset:register("mouseClick", function()
            for i in pairs(cf["items"]) do
                editOneItem({id = i}, true)
            end
            cf["items"] = {}
            mwse.saveConfig(mod.name, cf)
            tes3.messageBox("All items have been reset to their default values.")
            menu:destroy()
        end)
        local cancel = block2:createButton{text = tostring(tes3.findGMST("sClose").value)}
        cancel:register("mouseClick", function()
            menu:destroy()
        end)
        menu:register("mouseOver", function()
            local bar = scrollPane:findChild("PartScrollPane_vert_scrollbar")
            local content = scrollPane:getContentElement()
            bar.visible = (content.height > menu.height)
        end)
    end)
    button:registerAfter("mouseOver", function()
        label.visible = false
        link.visible = false
        link2.visible = false
        fullReset.visible = true
    end)
    button:registerAfter("mouseLeave", function()
        label.visible = true
        link.visible = true
        link2.visible = true
        fullReset.visible = false
    end)
end

local function registerModConfig()
    mwse.registerModConfig(mod.name, modConfig)
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by "..mod.author.."] "..mod.ver.." Initialized!")
    for item in tes3.iterateObjects(itemList) do
        storeItem(item)
        editOneItem(item)
    end
end event.register("initialized", initialized, {priority = -1000})