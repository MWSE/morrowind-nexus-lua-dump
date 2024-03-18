---@class herbert.QS.common
local common = {}
local log = Herbert_Logger()
local ot = tes3.objectType
local wc = tes3.armorWeightClass
local sk = tes3.skill
local Option = require("herbert100.quick select.QS_Option")
---@type tes3.skill[]
common.wearable_skill_ids = {sk.unarmored, sk.heavyArmor, sk.mediumArmor, sk.lightArmor}

---@return tes3.skill[]
function common.get_wearable_skill_ids() return {sk.unarmored, sk.heavyArmor, sk.mediumArmor, sk.lightArmor} end

---@type tes3.skill[]
common.tool_skills = {sk.security, sk.armorer, sk.alchemy}

---@return tes3.skill[]
function common.get_tool_skills() return {sk.security, sk.armorer, sk.alchemy} end

---@type tes3.objectType[]
common.tools = {ot.apparatus, ot.lockpick, ot.probe, ot.repairItem, ot.light}

common.tools_set = table.map(table.invert(common.tools), function() return true end)

---@return tes3.objectType[]
function common.get_tools() return {ot.lockpick, ot.probe, ot.apparatus, ot.repairItem, ot.light} end



common.make_sorters = {}


---@return fun(a:tes3armor|tes3clothing, b:tes3armor|tes3clothing): boolean
function common.make_sorters.clothing_or_armor()
    local mp_skills = tes3.mobilePlayer.skills

    table.sort(common.get_wearable_skill_ids(), function (a, b)
        return mp_skills[a+1].base > mp_skills[b+1].base
    end)

    local inv_wearable_skill_ids = table.invert(common.wearable_skill_ids)

    local wc_to_sk = {
        [wc.light] = sk.lightArmor,
        [wc.medium] = sk.mediumArmor,
        [wc.heavy] = sk.heavyArmor,
    }
    local armor_skill_rank = {}

    for wc_id, sk_id in pairs(wc_to_sk) do
        armor_skill_rank[wc_id] = inv_wearable_skill_ids[sk_id]
    end
    ---@param a tes3armor|tes3clothing
    ---@param b tes3armor|tes3clothing
    return function (a, b)
        if a.objectType ~= b.objectType then
            return a.objectType == ot.clothing
        end
        if a.objectType == ot.clothing then
            if a.value ~= b.value then return a.value > b.value end
            if b.enchantCapacity ~= b.enchantCapacity then
                return b.enchantCapacity > b.enchantCapacity
            end
            return b.name < b.name
        end
        local a1_rank = armor_skill_rank[a.weightClass]
        local a2_rank = armor_skill_rank[b.weightClass]

        if a1_rank ~= a2_rank then return a1_rank < a2_rank end
        if a.value ~= b.value then return a.value > b.value end
        return a.name < b.name
    end
end


function common.make_sorters.weapon()
    local mp_skills = tes3.mobilePlayer.skills

    ---@param w1 tes3weapon
    ---@param w2 tes3weapon
    return function (w1, w2)
        local w1_base = mp_skills[1+w1.skillId].base
        local w2_base = mp_skills[1+w2.skillId].base
        if w1_base ~= w2_base then return w1_base > w2_base end
        if w1.value ~= w2.value then return w1.value > w2.value end
        return w1.name < w2.name
    end
    
end

function common.make_sorters.tools()

    local mp = tes3.mobilePlayer
    local mp_skills = mp.skills
    table.sort(common.get_tool_skills(), function (a, b)
        return mp_skills[1 + a].base > mp_skills[1 + b].base
    end)


    local inv_tool_skills = table.invert(common.tool_skills)

    local tool_object_types_ranked = {
        [ot.apparatus] = inv_tool_skills[sk.alchemy],
        [ot.lockpick] = inv_tool_skills[sk.security],
        [ot.probe] = inv_tool_skills[sk.security],
        [ot.repairItem] = inv_tool_skills[sk.armorer],
        [ot.light] = #common.tool_skills + 1,
    }

    for _, t in ipairs(common.tools) do
        if tool_object_types_ranked[t] > tool_object_types_ranked[ot.lockpick] then
            tool_object_types_ranked[t] = tool_object_types_ranked[t] + 1
        end
    end
    tool_object_types_ranked[ot.probe] = tool_object_types_ranked[ot.probe] + 1

    log("tool types ranked = %s", function ()
        local t = {}
        for k, v in pairs(tool_object_types_ranked) do
            t[table.find(ot, k)] = v
        end
        return json.encode(t)
    end)


    ---@param t1 tes3lockpick|tes3probe|tes3apparatus|tes3repairTool|tes3light
    ---@param t2 tes3lockpick|tes3probe|tes3apparatus|tes3repairTool|tes3light
    return function (t1, t2)
        if t1.objectType ~= t2.objectType then
            return tool_object_types_ranked[t1.objectType] < tool_object_types_ranked[t2.objectType]
        end

        if t1.objectType == ot.apparatus then
            if t1.type ~= t2.type then return t1.type < t2.type end
            if t1.quality ~= t2.quality then return t1.quality < t2.quality end
            if t1.value ~= t2.value then return t1.value < t2.value end
            return t1.name < t2.name
        end
        return t1.value > t2.value
        
    end

end


common.UIDs = {
    menu_mesage = tes3ui.registerID("MenuMessage"),
    menu_mesage_close_btn = tes3ui.registerID("MenuMessage_CancelButton"),
    menu_options = tes3ui.registerID("MenuOptions"),
    menu_options_close_btn = tes3ui.registerID("MenuOptions_Return_container"),
    inv_select = tes3ui.registerID("MenuInventorySelect"),
    inv_select_uiexp_filter_blk = tes3ui.registerID("UIEXP:InventorySelect:FilterBlock"),
    inv_select_close_btn = tes3ui.registerID("MenuInventorySelect_button_cancel"),
    magic_select = tes3ui.registerID("MenuMagicSelect"),
    magic_select_close_btn = tes3ui.registerID("MenuMagicSelect_button_cancel"),
}




---@param p {title: string, hide_filter_icons: boolean?, sort_options: (nil|fun(tes3object, tes3object): boolean), filter: tes3.objectType|number|table|false|nil|(fun(p:tes3ui.showInventorySelectMenu.filterParams): boolean)}
---@return tes3ui.showMessageMenu.params.button
local function make_inv_select_option(p)
    local filter, old_filter = p.filter, p.filter
    if type(old_filter) == "table" then
        if old_filter[1] then
            old_filter = {}
            for _, v in pairs(p.filter) do old_filter[v] = true end
        end
        filter = function (fp) return old_filter[fp.item.objectType] ~= nil end

    elseif type(old_filter) == "number" then
        filter = function(fp) return fp.item.objectType == old_filter end

    elseif not old_filter then
        filter = function() return true end
    end
    ---@type tes3ui.showMessageMenu.params.button
    return {text=p.title, 
        -- callback when button is pressed
        callback=function()
            tes3ui.showInventorySelectMenu{title=p.title,filter=filter,
                -- callback when item is selected
                callback=function(cp)
                    -- event.unregister(tes3.event.keyDown, close_menu_with_esc_key, {filter=tes3.scanCode.esc})
                    if not cp.item then 
                        tes3.messageBox("you picked nothing")
                        return 
                    end
                    tes3.messageBox("you picked %s", cp.item.name)
                end
            }
            if not p.hide_filter_icons or not p.sort_options then return end

            local menu = tes3ui.findMenu(common.UIDs.inv_select)
            if not menu then return end

            menu = menu:getContentElement()

            if p.hide_filter_icons then
                local filter_blk = menu:findChild(common.UIDs.inv_select_uiexp_filter_blk)
                if filter_blk then
                    filter_blk.children[1].borderRight = 0
                    filter_blk.children[2].visible = false
                end
            end
            if not p.sort_options then return end

            local items_list = menu:findChild("MenuInventorySelect_scrollpane")
            local contents = items_list and items_list:getContentElement()
            if not contents then return end

            log("contents menu: %q", contents.name)
            -- log("contents.children[1] =  %q (%q)", contents.children[1].name, contents.children[1].children[3].text)

            contents:sortChildren(function (a, b)
                ---@type tes3weapon
                local w1 = a:getPropertyObject("MenuInventorySelect_object")
                local w2 = b:getPropertyObject("MenuInventorySelect_object")
                if w1 then
                    if w2 then return p.sort_options(w1, w2) end
                    return true
                else
                    if w2 then return false end
                    return a.children[3].name < b.children[3].name
                end
            end)
            items_list.widget:contentsChanged()
            menu:updateLayout()
        end
    }
end



---@param sorter fun(a, b): boolean
function common.sort_inventory_select_menu_contents(sorter)
    if not sorter then return end
    local menu = tes3ui.findMenu(common.UIDs.inv_select)
    if not menu then return end

    local items_list = menu:getContentElement():findChild("MenuInventorySelect_scrollpane")
    local contents = items_list and items_list:getContentElement()
    if not contents then return end

    log("contents menu: %q", contents.name)
    -- log("contents.children[1] =  %q (%q)", contents.children[1].name, contents.children[1].children[3].text)

    contents:sortChildren(function (a, b)
        ---@type tes3weapon
        local w1 = a:getPropertyObject("MenuInventorySelect_object")
        local w2 = b:getPropertyObject("MenuInventorySelect_object")
        if w1 then
            if w2 then return sorter(w1, w2) end
            return true
        else
            if w2 then return false end
            return a.children[3].name < b.children[3].name
        end
    end)
    items_list.widget:contentsChanged()
    menu:updateLayout()
end


---@class herbert.QS.common.show_inventory_select_menu.params
---@field title string
---@field hide_ui_exp_filter_icons boolean?
---@field sort_options (nil|fun(tes3object, tes3object): boolean)
---@field filter tes3.objectType|number|table|false|nil|(fun(p:tes3ui.showInventorySelectMenu.filterParams): boolean)
---@field callback nil|fun(cbp: tes3ui.showInventorySelectMenu.callbackParams)

---@param p herbert.QS.common.show_inventory_select_menu.params
function common.show_inventory_select_menu(p)
    local filter
    if not p.filter then
        filter = function() return true end
    elseif type(p.filter) == "number" then
        local num = p.filter
        filter = function(fp) return fp.item.objectType == num end
    elseif type(p.filter) == "table" then
        local old_filter = p.filter ---@type table
        -- make sure it's a set and not an array
        if #old_filter > 0 and table.size(old_filter) == #old_filter then
            old_filter = {}
            for _, v in pairs(p.filter) do old_filter[v] = true end
        end

        filter = function(fp) return old_filter[fp.item.objectType] ~= nil end
    else
        filter = p.filter
    end


    tes3ui.showInventorySelectMenu{title=p.title, filter=filter, callback=p.callback}

    if p.hide_ui_exp_filter_icons and tes3.isLuaModActive("UI Expansion") then
        local menu = tes3ui.findMenu(common.UIDs.inv_select)
        if menu then
            local filter_blk = menu:getContentElement():findChild(common.UIDs.inv_select_uiexp_filter_blk)
            if filter_blk then
                filter_blk.children[1].borderRight = 0
                filter_blk.children[2].visible = false
            end
        end
    end
    if p.sort_options then
        common.sort_inventory_select_menu_contents(p.sort_options)
    end
end


common.get_options = {}

function common.get_options.soul_gems()
    local sg_options = {}
    local inv = tes3.mobilePlayer.inventory
    for _, stack in pairs(inv) do
        if not stack.object.isSoulGem then goto next_stack end
        log("found soul gem!")
        if not stack.variables then goto next_stack end

        for _, item_data in ipairs(stack.variables) do
            if item_data.soul then
                -- stack.object.soulGemData.name
                table.insert(sg_options, Option.new{ data=item_data, item=stack.object,
                    name=string.format("%s (%s  %s/%s)", stack.object.soulGemData.name, item_data.soul.name, item_data.soul.soul, stack.object.soulGemCapacity)
                })
            end
        end

        ::next_stack::
    end
    ---@param a herbert.QS.Item_Option
    ---@param b herbert.QS.Item_Option
    table.sort(sg_options, function (a, b)
        ---@diagnostic disable-next-line: undefined-field
        local a_sg_data = a.item.soulGemData
        ---@diagnostic disable-next-line: undefined-field
        local b_sg_data = b.item.soulGemData

        if a_sg_data.soulGemCapacity ~= b_sg_data.soulGemCapacity then
            return a_sg_data.soulGemCapacity > b_sg_data.soulGemCapacity
        end
        local a_soul = a.data.soul.soul
        local b_soul = b.data.soul.soul
        if a_soul then
            if not b_soul then return true end
            if a_soul ~= b_soul then return a_soul > b_soul end 
        else
            if b_soul then return false end
        end
        if a.item.value ~= b.item.value then return a.item.value > b.item.value end
        return a.name < b.name
    end)

    return sg_options
end


return common


