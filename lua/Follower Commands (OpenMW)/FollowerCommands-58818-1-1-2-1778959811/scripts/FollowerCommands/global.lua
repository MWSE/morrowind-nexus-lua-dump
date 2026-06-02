local consts = require("scripts.FollowerCommands.utils.consts")

local function triggerCommand(player)
    player:sendEvent("FollowerCommands_triggerCommand")
end

local function pausedAction(data)
    local script = consts.customScripts[data.action]
    if data.follower:hasScript(script) then return end
    data.follower:addScript(script, data)
end

local function detachScript(data)
    local script = consts.customScripts[data.action]
    if data.follower:hasScript(script) then
        data.follower:removeScript(script)
    end
end

local function onModifyPickprobeCondition(data)
    local itemData = data.item.type.itemData(data.item)
    itemData.condition = math.min(
        data.item.type.record(data.item).maxCondition,
        math.max(0, itemData.condition + data.amount)
    )

    -- Force unequip broken items
    if data.actor and itemData.condition <= 0 then
        data.item:remove(1)
    end
end

local function unlock(obj)
    obj.type.unlock(obj)
end

local function untrap(obj)
    obj.type.setTrapSpell(obj)
end

local function lootItems(data)
    for _, itemData in ipairs(data.items) do
        if itemData.item.count > 0 then
            local pickedItem = itemData.item
            if pickedItem.count > itemData.count then
                pickedItem = pickedItem:split(itemData.count)
            end
            pickedItem:moveInto(data.actor)
        end
    end
end

local function resolve(obj)
    obj.type.inventory(obj):resolve()
end

return {
    eventHandlers = {
        FollowerCommands_triggerCommand = triggerCommand,
        FollowerCommands_pausedAction = pausedAction,
        FollowerCommands_detachScript = detachScript,
        FollowerCommands_modifyPickprobeCondition = onModifyPickprobeCondition,
        FollowerCommands_unlock = unlock,
        FollowerCommands_untrap = untrap,
        FollowerCommands_resolve = resolve,
        FollowerCommands_lootItems = lootItems,
    },
}
