local hlib = require("herbert100")
local Option = require("herbert100.quick select.QS_Option") ---@type herbert.QS.Item_Option
local log = mwse.Logger.new()
local common = require("herbert100.quick select.common") ---@type herbert.QS.common
local cfg = require("herbert100.quick select.config") ---@type herbert.QS.config
local ot = tes3.objectType

---@class herbert.QS.get_options
local get_options = {}



function get_options.soul_gems()
    local sg_options = {}
    local inv = tes3.mobilePlayer.inventory
    for _, stack in pairs(inv) do
        if not stack.object.isSoulGem then goto next_stack end
        log("found soul gem!")
        local count = math.abs(stack.count)
        if stack.variables then
            for _, item_data in ipairs(stack.variables) do
                if item_data.soul then
                    count = count - (item_data.count or 1)
                    -- stack.object.soulGemData.name
                    table.insert(sg_options,
                        Option.new { data = item_data, item = stack.object, count = item_data.count or 1,
                            name = string.format("%s (%s  %s/%s)", stack.object.soulGemData.name, item_data.soul.name, item_data.soul.soul, stack.object.soulGemCapacity)
                        })
                end
            end
        end
        if count > 0 then
            table.insert(sg_options, Option.new {
                item = stack.object,
                name = string.format("%s (%s)", stack.object.name, count),
                count = count,
            })
        end
        ::next_stack::
    end
    ---@param a herbert.QS.Item_Option
    ---@param b herbert.QS.Item_Option
    table.sort(sg_options, function(a, b)
        ---@diagnostic disable-next-line: undefined-field
        local a_sg_data = a.item.soulGemData
        ---@diagnostic disable-next-line: undefined-field
        local b_sg_data = b.item.soulGemData

        if a_sg_data.soulGemCapacity ~= b_sg_data.soulGemCapacity then
            return a_sg_data.soulGemCapacity > b_sg_data.soulGemCapacity
        end
        local a_soul = a.data and a.data.soul.soul
        local b_soul = b.data and b.data.soul.soul

        if a_soul then
            if not b_soul then return true end
            if a_soul ~= b_soul then return a_soul > b_soul end
        else
            if b_soul then return false end
            if a.item.value ~= b.item.value then return a.item.value > b.item.value end
            ---@diagnostic disable-next-line: undefined-field
            if a.count ~= b.count then return a.count > b.count end
        end

        if a.item.value ~= b.item.value then return a.item.value > b.item.value end
        return a.name < b.name
    end)

    return sg_options
end

function get_options.on_use_enchants()
    if not tes3.player then return end
    local magic_items = {} ---@type herbert.QS.Menu.Option[]|{source: tes3spell|tes3item, itemData: tes3itemData}
    for _, stack in pairs(tes3.player.object.equipment) do
        local obj = stack.object
        if obj.enchantment and obj.enchantment.castType == tes3.enchantmentType.onUse then
            table.insert(magic_items, Option.new { item = obj, data = stack.itemData, is_magic = true })
        end
    end
    return magic_items
end

local tools_cfg = cfg.tabs.auto_gen.tools

-- =============================================================================
-- TOOLS
-- =============================================================================
---@param spell tes3spell
---@param id tes3.effect
---@return number
local function get_first_effect_min_magnitude(spell, id)
    return spell.effects[1 + spell:getFirstIndexOfEffect(id)].min
end

function get_options.tools()
    local tools_by_obj_type = {} ---@type table<tes3.objectType, herbert.QS.Item_Option[]>
    local tools_set = {}

    local max_to_show = tools_cfg.max_to_show
    for _, tool_type in ipairs(common.tools) do
        if max_to_show[tool_type] ~= 0 then
            tools_by_obj_type[tool_type] = {}
            tools_set[tool_type] = true
        end
    end
    local obj
    local at_mortarpestle = tes3.apparatusType.mortarAndPestle
    for _, stack in pairs(tes3.mobilePlayer.inventory) do
        obj = stack.object
        if not tools_set[obj.objectType]                                      -- if it's not a tool
            or obj.objectType == ot.apparatus and obj.type ~= at_mortarpestle -- or it is a tool, but it's an alchemy tool and not a mortar and pestle
        then
            goto next_stack
        end

        local tbl = tools_by_obj_type[obj.objectType]

        log("found tool")
        local count = stack.count
        if stack.variables then
            log("tool %q has data!", obj.name)
            for _, item_data in ipairs(stack.variables) do
                count = count - 1
                table.insert(tbl, Option.new { item = obj, count = 1, data = item_data })
            end
        end
        if count > 0 then
            table.insert(tbl, Option.new { item = obj, count = count })
        end
        ::next_stack::
    end
    local viable_tools = {} ---@type herbert.QS.Item_Option[]

    for _, tbl in pairs(tools_by_obj_type) do
        table.sort(tbl, function(a, b)
            local a_item, b_item = a.item, b.item
            if a_item.value ~= b_item.value then return a_item.value > b.item.value end

            if a.count ~= b.count then return a.count > b.count end

            local a_cond, b_cond = a.condition, b.condition

            if a_cond ~= b_cond then
                if a_cond and b_cond then
                    return a_cond > b_cond
                elseif a_cond then
                    return false
                elseif b_cond then
                    return true
                end
            end

            return a_item.name > b_item.name
        end)
    end



    local total_tiles = cfg.num_options

    -- local tools_to_add = math.floor(total_tiles / 3.5)

    for _, tool_type in ipairs(common.tools) do -- this is an array, so items will be added in the specified order
        local tbl = tools_by_obj_type[tool_type]
        local max_to_add = max_to_show[tool_type]

        local num_items = #tbl

        if num_items <= max_to_add then
            for _, v in ipairs(tbl) do
                table.insert(viable_tools, v)
            end
        else
            for i = 0, max_to_add do
                local j = 1 + math.ceil(i * num_items / max_to_add)
                table.insert(viable_tools, tbl[j])
            end
        end
    end
    -- add_curated_selections(viable_tools, tools_by_obj_type[ot.apparatus], 1)
    -- add_curated_selections(viable_tools, tools_by_obj_type[ot.lockpick], math.floor(total_tiles / 3.5))
    -- add_curated_selections(viable_tools, tools_by_obj_type[ot.probe], math.floor(total_tiles / 5))
    -- add_curated_selections(viable_tools, tools_by_obj_type[ot.repairItem], math.floor(total_tiles / 5))
    -- add_curated_selections(viable_tools, tools_by_obj_type[ot.light], math.floor(total_tiles / 6))



    if #viable_tools >= total_tiles then return viable_tools end
    local po = tes3.player.object
    if tools_cfg.include_on_use then
        -- add on use enchantments
        for _, stack in pairs(po.equipment) do
            obj = stack.object
            if obj.enchantment and obj.enchantment.castType == tes3.enchantmentType.onUse then
                table.insert(viable_tools, Option.new { item = obj, data = stack.itemData, is_magic = true })
            end
        end
    end

    if #viable_tools >= total_tiles or not tools_cfg.include_spells then return viable_tools end

    -- add spells, in this order
    local desired_effects = {
        tes3.effect.open,
        tes3.effect.telekinesis,
        tes3.effect.levitate,
        tes3.effect.waterWalking,
        tes3.effect.waterBreathing,
        tes3.effect.charm
    }

    local spell_arrays = {} ---@type table<tes3.effect, tes3spell[]>
    for _, id in pairs(desired_effects) do spell_arrays[id] = {} end


    for _, spell in pairs(po.spells) do
        for id, arr in pairs(spell_arrays) do
            -- add the spell if it has the effect
            if spell:getFirstIndexOfEffect(id) > -1 then
                table.insert(arr, spell)
            end
        end
    end


    -- add things in order
    for _, id in ipairs(desired_effects) do
        local arr = spell_arrays[id]
        local num_spells = #arr
        if num_spells < 1 then goto next_id end

        if num_spells == 1 then
            table.insert(viable_tools, Option.new { item = arr[1], is_magic = true })
            goto next_id
        end

        local highest_mag = hlib.tbl_ext.max(arr, get_first_effect_min_magnitude, id)

        table.insert(viable_tools, Option.new { item = highest_mag })

        local cheapest = hlib.tbl_ext.min(arr, function(spell) return spell.magickaCost end)
        if cheapest ~= highest_mag then
            table.insert(viable_tools, Option.new { item = cheapest, is_magic = true })
        end

        ::next_id::
    end
    return viable_tools
end

function get_options.potions()
    local added_effects = {}
    local options = hlib.tbl_ext.new() ---@type herbert.QS.Item_Option|herbert.Extended_Table
    for _, stack in pairs(tes3.player.object.inventory) do
        local item = stack.object ---@type tes3alchemy
        if item.objectType ~= tes3.objectType.alchemy then goto next_stack end
        options:insert(Option.new { item = item })

        ::next_stack::
    end
end

return get_options
