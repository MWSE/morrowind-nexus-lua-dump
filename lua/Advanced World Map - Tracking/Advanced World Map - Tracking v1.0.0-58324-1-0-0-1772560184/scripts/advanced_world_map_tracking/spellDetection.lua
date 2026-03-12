local playerRef = require("openmw.self")
local types = require("openmw.types")
local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local commonData = require("scripts.advanced_world_map_tracking.common")
local stringLib = require("scripts.advanced_world_map_tracking.utils.string")
local tableLib = require("scripts.advanced_world_map_tracking.utils.table")
local config = require("scripts.advanced_world_map_tracking.config.configLib")

local l10n = core.l10n(commonData.l10nKey)

local advWMap = I.AdvancedWorldMap
local advWMap_tracking = I.AdvWMap_tracking


local effects = types.Actor.activeEffects(playerRef)
local aiStats = types.Actor.stats.ai

local enchantmentTypes = {
    [types.Armor] = 3,
    [types.Clothing] = 2,
    [types.Weapon] = 4,
    [types.Book] = 1,
}

local effectData = {
    ["detectAnimal"] = {
        effect = "detectAnimal",
        types = {"Creature"},
        icon = commonData.detectTexture,
        cfg = config.data.spDetection.animal,
        alive = true,
        tooltipEvent = false,
        markerId = nil,
        lastMagnitude = 0,
    },
    ["detectNPC"] = {
        effect = "detectAnimal",
        types = {"NPC"},
        icon = commonData.detectTexture,
        cfg = config.data.spDetection.animal,
        colorId = "npcColor",
        isEnabled = function ()
            return config.data.spDetection.animal.enabled and config.data.spDetection.animal.detectNPC
        end,
        alive = true,
        tooltipEvent = false,
        markerId = nil,
        lastMagnitude = 0,
    },
    ["detectEnemy"] = {
        effect = "detectAnimal",
        types = {"NPC", "Creature"},
        icon = commonData.detectTexture,
        cfg = config.data.spDetection.animal,
        priority = 0.5,
        colorId = "enemyColor",
        alive = true,
        tooltipEvent = false,
        markerId = nil,
        lastMagnitude = 0,
        isEnabled = function ()
            return config.data.spDetection.animal.enabled and config.data.spDetection.animal.detectEnemy
        end,
        validFunc = function (marker, template, object)
            if not object then return false end

            return config.data.spDetection.animal.detectNPC or object.type == types.Creature
        end,
        func = function (marker, template, object)
            if not object then return false end

            local isEnemy = aiStats.fight(object).modified > 80

            return isEnemy
        end
    },
    ["detectKey"] = {
        effect = "detectKey",
        types = {"Miscellaneous", "Creature", "NPC", "Container"},
        icon = commonData.detectTexture,
        cfg = config.data.spDetection.key,
        tooltipEvent = true,
        markerId = nil,
        lastMagnitude = 0,
        cache = {},
        func = function (marker, template, object)
            if not object then return false end

            local tm = core.getSimulationTime()
            local cache = marker.userData.cache[object.id]
            if not cache then cache = {} end
            if (cache[1] or 0) > tm then
                return cache[2]
            end
            marker.userData.cache[object.id] = cache
            cache[1] = tm + 3 + math.random() * 2

            if object.type == types.Miscellaneous then
                if object.recordId:find("^key_") then
                    cache[2] = true
                    return true
                end

                cache[2] = false
                return false
            end

            if not object.type.inventory then return false end

            local inventory = object.type.inventory(object)
            for _, item in pairs(inventory:getAll(types.Miscellaneous)) do
                if item.recordId:find("^key_") then
                    cache[2] = true
                    return true
                end
            end

            cache[2] = false
            return false
        end
    },
    ["detectEnchantment"] = {
        effect = "detectEnchantment",
        types = {"Armor", "Clothing", "Weapon", "Book", "Creature", "NPC", "Container"},
        icon = commonData.detectTexture,
        cfg = config.data.spDetection.enchantment,
        priority = 1,
        tooltipEvent = true,
        markerId = nil,
        lastMagnitude = 0,
        cache = {},
        func = function (marker, template, object)
            if not object then return false end

            local tm = core.getSimulationTime()
            local cache = marker.userData.cache[object.id]
            if not cache then cache = {} end
            if (cache[1] or 0) > tm then
                return cache[2]
            end
            marker.userData.cache[object.id] = cache
            cache[1] = tm + 3 + math.random() * 2

            local inventoryFunc = object.type.inventory or object.type.content
            if inventoryFunc then
                local inventory = inventoryFunc(object)
                for tp, _ in pairs(enchantmentTypes) do
                    for _, item in pairs(inventory:getAll(tp)) do
                        local record = item.type.record(item.recordId)
                        if record and record.enchant then
                            cache[2] = true
                            return true
                        end
                    end
                end

                cache[2] = false
                return false
            end

            local record = object.type.record(object.recordId)
            if record and record.enchant then
                cache[2] = true
                return true
            end

            cache[2] = false
            return false
        end
    },
}


local function func()
    for _, data in pairs(effectData) do
        if data.isEnabled and not data.isEnabled() or not data.cfg.enabled then
            if data.markerId then
                advWMap_tracking.removeMarker(data.markerId)
                data.markerId = nil
                data.cache = {}
            end
            goto continue
        end

        local eff = effects:getEffect(data.effect)
        local magnitude = eff.magnitude

        if magnitude == data.lastMagnitude then goto continue end

        if data.markerId then
            advWMap_tracking.removeMarker(data.markerId)
            data.markerId = nil
            data.cache = {}
        end

        if magnitude > 0 then
            data.markerId = advWMap_tracking.addMarker{
                template = {
                    path = data.icon,
                    pathA = data.iconA,
                    pathB = data.iconB,
                    size = data.size or util.vector2(config.data.spDetection.markerSize, config.data.spDetection.markerSize),
                    anchor = data.anchor or util.vector2(0.5, 0.5),
                    color = data.colorId and data.cfg[data.colorId] or data.cfg.color,
                    tText = "@name@",
                    tEvent = data.tooltipEvent,
                },
                types = data.types,
                priority = data.priority,
                alive = data.alive,
                distance = data.cfg.distanceMul < 10 and magnitude * 22.1 * data.cfg.distanceMul or nil,
                userData = data,
                isVisibleFn = data.func,
                objValidateFn = data.validFunc,
            }
        else
            data.cache = {}
        end

        data.lastMagnitude = magnitude

        ::continue::
    end

    async:newUnsavableSimulationTimer(0.25, func)
end


local function init()
    ---@type AdvancedWorldMap.Interface
    advWMap = I.AdvancedWorldMap
    advWMap_tracking = I.AdvWMap_tracking

    if not advWMap or not advWMap_tracking then
        print("AdvancedWorldMap interface not found")
        return
    end

    local events = advWMap.events

    ---@param e AdvancedWorldMap.Event.onTrackingTooltipShowEvent
    events.registerHandler("onTrackingTooltipShow", function (e)

        local object = e.object
        if not object then return end

        if effectData.detectEnchantment.markerId and e.markerId == effectData.detectEnchantment.markerId and
                object.type.inventory then

            local items = {}
            local inventory = object.type.inventory(object)
            for tp, priority in pairs(enchantmentTypes) do
                for _, item in pairs(inventory:getAll(tp)) do
                    local record = item.type.record(item.recordId)
                    if record and record.enchant and record.name then
                        items[record.name] = {priority, record.name}
                    end
                end
            end

            items = tableLib.values(items, function (a, b)
                return a[1] > b[1]
            end)

            local screenSize = ui.layers[1].size
            local tooltipWidth = screenSize.x / 5

            local itemNames = {}
            for _, itemDt in ipairs(items) do
                table.insert(itemNames, itemDt[2])
            end
            local t = stringLib.getValueEnumString(itemNames, config.data.spDetection.enchantment.maxTooltipItems, l10n("EnchantmentDetectedTooltip"))

            e.content:add{
                type = ui.TYPE.TextEdit,
                props = {
                    text = t,
                    textColor = advWMap.getConfig().ui.defaultColor, ---@diagnostic disable-line: undefined-field
                    textSize = advWMap.getConfig().ui.fontSize, ---@diagnostic disable-line: undefined-field
                    anchor = util.vector2(0.5, 0.5),
                    size = util.vector2(tooltipWidth, 0),
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    readOnly = true,
                    autoSize = true,
                }
            }
        end
    end)

    async:newUnsavableSimulationTimer(0.25, func)
end

async:newUnsavableSimulationTimer(0.1, init)


return {}