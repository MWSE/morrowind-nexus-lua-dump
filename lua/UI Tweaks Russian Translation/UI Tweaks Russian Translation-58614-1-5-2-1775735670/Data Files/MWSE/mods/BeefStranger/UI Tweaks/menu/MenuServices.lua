local cfg = require("BeefStranger.UI Tweaks.config")
local id = require("BeefStranger.UI Tweaks.ID")
local bs = require("BeefStranger.UI Tweaks.common")
local sf = string.format
local find = tes3ui.findMenu
local reg = tes3ui.registerID

---@class bsMenuServices
local Services = {}

---===================================
---============Repair=================
---===================================

---@class bsMenuServiceRepair
Services.Repair = {}
function Services.Repair:get() return find(reg(id.ServiceRepair)) end
function Services.Repair:child(child) if self:get() then return self:get():findChild(child) end end
function Services.Repair:Close() if self:get() then return self:child("MenuServiceRepair_Okbutton") end end
local Repair = Services.Repair

---===================================
---============Spells=================
---===================================

---@class bsMenuServiceSpells
Services.Spells = {}
Services.Spells.UID = {
    filter = reg("School Filter"),
    header = reg("Header"),
    title = reg("Title"),
    cost_header = reg("Cost Header"),
    data = reg("Purchase Data"),
    vert_divider = reg("Divider"),
    gold_cost = reg("Gold Cost")
}

function Services.Spells:get() return find(reg(id.ServiceSpells)) end
function Services.Spells:child(child) if self:get() then return self:get():findChild(child) end end
function Services.Spells:Close() return self:child("MenuServiceSpells_Okbutton") end
function Services.Spells:ServiceList() return self:child("MenuServiceSpells_ServiceList"):getContentElement() end
function Services.Spells:Icons() return self:child("MenuServiceSpells_Icons") end
function Services.Spells:IconIndex(index) return self:Icons().children[index] end
function Services.Spells:Spells() return self:child("MenuServiceSpells_Spells") end
function Services.Spells:Filter() return self:child(self.UID.filter) end
local Spells = Services.Spells

---@class bsMenuServiceSpells_this
local spells = {}
-- spells.price = {}
spells.skillIcons = {
    [tes3.skill.alteration] = "Icons\\s\\b_tx_s_open.tga",
    [tes3.skill.conjuration] = "Icons\\s\\b_tx_s_smmn_daedth.tga",
    [tes3.skill.destruction] = "Icons\\s\\b_tx_s_dmg_health.tga",
    [tes3.skill.illusion] = "Icons\\s\\b_tx_s_light.tga",
    [tes3.skill.mysticism] = "Icons\\s\\b_tx_s_alm_intervt.tga",
    [tes3.skill.restoration] = "Icons\\s\\b_tx_s_rem_curse.tga",
}

spells.TEXT = {
    HEADER_COST = "Магия | Золото",
    CAST_COST = "Цена заклятия",
}

function spells.createAdditions()
    local UID = Services.Spells.UID
    local TEXT = spells.TEXT
    local topLevel = Spells:get()

    local filter = topLevel:createBlock({id = UID.filter})
    filter:bs_autoSize(true)
    filter.widthProportional = 1

    local header = topLevel:createBlock({id = UID.header})
    header:bs_autoSize(true)
    header.widthProportional = 1

    local title = header:createLabel({id = UID.title, text = bs.GMST(tes3.gmst.sSpellServiceTitle)})
    title:register(tes3.uiEvent.help, function (e)
        local tip = tes3ui.createTooltipMenu()
        tip:createLabel({text = "Сортировать по названию"})
    end)

    local headerCost = header:createLabel({id = UID.cost_header, text = TEXT.HEADER_COST})
    headerCost.absolutePosAlignX = 1
    headerCost:register(tes3.uiEvent.help, function (e)
        local tip = tes3ui.createTooltipMenu()
        tip:createLabel({text = "Сортировать по стоимости"})
    end)

    local data = Spells:ServiceList():createBlock({id = UID.data})
    data.widthProportional = 1
    data.heightProportional = 1
    data.childAlignX = 1

    local castCost = data:createBlock({id = TEXT.CAST_COST})
    castCost:bs_autoSize(true)
    castCost.flowDirection = tes3.flowDirection.topToBottom
    castCost.heightProportional = 1
    castCost.childAlignX = 1

    local div = data:createNif({id = UID.vert_divider, path = "menu_thin_border.NIF"})
    div.width = 3
    div.heightProportional = 1
    div.borderLeft = 5
    div.borderRight = 17

    local cost = data:createBlock{id = UID.gold_cost}
    cost:bs_autoSize(true)
    cost.flowDirection = tes3.flowDirection.topToBottom
    cost.heightProportional = 1
    cost.childAlignX = 1

    topLevel:getContentElement():reorderChildren(2, header, -1)
    topLevel:getContentElement():reorderChildren(1, filter, -1)
    topLevel:getContentElement().children[3].visible = false

    ---@param skill tes3skill
    function spells.createFilterIcons(skill)
        local icon = filter:createImage({ id = skill.name, path = spells.skillIcons[skill.id] })
        icon:setPropertyBool("Filtering", false)
        icon.borderRight = 5
        icon.imageScaleX = 0.8
        icon.imageScaleY = 0.8
        icon:register(tes3.uiEvent.help, function(e)
            local tip = tes3ui.createTooltipMenu()
            tip:createLabel({ text = e.source.name })
        end)

        icon:register(tes3.uiEvent.mouseClick, spells.filterClick)
    end

    function spells.createSpellInfo()
        castCost:destroyChildren()
        cost:destroyChildren()
        for childIndex, child in ipairs(Spells:Spells().children) do
            if child.visible then
                local spell = child:getPropertyObject("MenuServiceSpells_Spell") ---@type tes3spell
                local magicka = castCost:createLabel({ id = tostring(childIndex), text = tostring(spell.magickaCost) })
                if cfg.spellBarter.showCantCast and spell.magickaCost > tes3.mobilePlayer.magicka.base then
                    magicka.color = bs.rgb.bsNiceRed
                    magicka:register(tes3.uiEvent.help, function (e)
                        local tip = tes3ui.createTooltipMenu()
                        local label = tip:createLabel({text = "У вас недостаточно магии, чтобы произнести это заклинание."})
                        label.color = bs.rgb.bsNiceRed
                    end)
                end
                local gold = tes3.calculatePrice({merchant = tes3ui.getServiceActor(), buying = true, object = spell})

                local goldLabel = cost:createLabel { id = tostring(childIndex), text = tostring(gold) .. "зол" }

                local schools = spells.getSchools(spell)

                for schoolIndex, value in ipairs(schools) do
                    child:setPropertyInt("School_" .. schoolIndex, value)
                    local skill = tes3.getSkill(value)

                    if not filter:findChild(skill.name) then
                        spells.createFilterIcons(skill)
                    end
                end
                child:setPropertyInt("Effects", #schools)

                child.text = spell.name
            end
        end
        filter:sortChildren(function(a, b) return a.name < b.name end)
    end

    headerCost:register(tes3.uiEvent.mouseClick, spells.headerClick)
    title:register(tes3.uiEvent.mouseClick, spells.titleClick)

    spells.createSpellInfo()
    topLevel:updateLayout()
end

---@param spell tes3spell
---@return table effectSchools
function spells.getSchools(spell)
    local effectSchools = {}
    for i = 1, spell:getActiveEffectCount() do
        local effect = spell.effects[i]
        table.insert(effectSchools, tes3.magicSchoolSkill[effect.object.school])
    end
    return effectSchools
end

function spells.headerClick(e)
    Spells:Spells():sortChildren(spells.sortByCost)
    Spells:Icons():sortChildren(spells.sortByCost)
    spells.createSpellInfo()
    e.source:bs_Update()
end

function spells.titleClick(e)
    Spells:Spells():sortChildren(spells.sortByName)
    Spells:Icons():sortChildren(spells.sortByName)
    spells.createSpellInfo()
    e.source:bs_Update()
end

function spells.sortByCost(a,b)
    return a:getPropertyObject("MenuServiceSpells_Spell").magickaCost < b:getPropertyObject("MenuServiceSpells_Spell").magickaCost
end

function spells.sortByName(a,b)
    return a:getPropertyObject("MenuServiceSpells_Spell").name < b:getPropertyObject("MenuServiceSpells_Spell").name
end

function spells.setFiltering(element, bool)
    element:setPropertyBool("Filtering", bool)
end

function spells.getFiltering(element)
    return element:getPropertyBool("Filtering")
end

function spells.toggleFiltering(element)
    element:setPropertyBool("Filtering", not spells.getFiltering(element))
end

function spells.clearFilter(menu)
    for _, filterIcon in ipairs(Spells:Filter().children) do
        filterIcon.color = {1,1,1}
        if filterIcon ~= menu then
            spells.setFiltering(filterIcon, false)
        end
    end
    for index, spellChild in ipairs(Spells:Spells().children) do
        spellChild.visible = true
        Spells:IconIndex(index).visible = true
    end
end

function spells.filterClick(e)
    spells.clearFilter(e.source)
    spells.toggleFiltering(e.source)
    for spellIndex, spellChild in ipairs(Spells:Spells().children) do
        if spells.getFiltering(e.source) then
            e.source.color = bs.rgb.bsPrettyGreen
            for i = 1, spellChild:getPropertyInt("Effects") do
                local skill = tes3.getSkill(spellChild:getPropertyInt("School_" .. i))
                if skill.name ~= e.source.name then
                    Spells:IconIndex(spellIndex).visible = false
                    spellChild.visible = false
                end
            end
        else
            e.source.color = { 1, 1, 1 }
            spellChild.visible = true
            Spells:IconIndex(spellIndex).visible = true
        end
    end
    spells.createSpellInfo()
    e.source:bs_Update()
end

-- --- @param e calcSpellPriceEventData
-- local function calcSpellPriceCallback(e)
--     spells.price[e.spell.id] = e.price
-- end
-- event.register(tes3.event.calcSpellPrice, calcSpellPriceCallback)

local function uiActivatedSpells(e)
    if not cfg.spellBarter.enable then return end
    spells.createAdditions()
end
event.register(tes3.event.uiActivated, uiActivatedSpells, {filter = id.ServiceSpells, priority = -10000000000000})

---===================================
---============Training===============
---===================================

---@class MenuServiceTraining
Services.Train = {}
function Services.Train:get() return find(reg(id.ServiceTraining)) end
function Services.Train:child(child) if self:get() then return self:get():findChild(child) end end
function Services.Train:Close() if self:get() then return self:child("UIEXP_MenuTraining_Cancel") end end
local Train = Services.Train

---===================================
---============Travel=================
---===================================

---@class bsMenuServiceTravel
Services.Travel = {}
function Services.Travel:get() return find(reg(id.ServiceTravel)) end
function Services.Travel:child(child) if not self:get() then return end return self:get():findChild(child) end
function Services.Travel:Destination() if not self:get() then return end return self:child("PartScrollPane_pane") end
function Services.Travel:Close() if not self:get() then return end return self:child("MenuServiceTravel_Okbutton") end
function Services.Travel:Hotkey(child) if not self:get() then return end self:child(child):triggerEvent("bsHotkey") end
local Travel = Services.Travel

--- @param e uiActivatedEventData
local function ServiceTravel(e)
    if cfg.travel.enable then
        for i, destParent in ipairs(Travel:Destination().children) do
            local dest = destParent.children[1]
            local travelText = cfg.travel.showKey and i..":  " or ""

            local travelKey = destParent:createLabel{id = i.."TravelKey", text = travelText}
            travelKey.color = { 0.875, 0.788, 0.624 }
            travelKey:register("bsHotkey", function () dest:triggerEvent(tes3.uiEvent.mouseClick) bs.click() end)

            destParent:reorderChildren(0, travelKey, 1)
            Travel:get():updateLayout()
        end
    end
end
event.register(tes3.event.uiActivated, ServiceTravel, {filter = id.ServiceTravel})


return Services