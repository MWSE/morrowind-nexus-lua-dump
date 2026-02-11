local storage = require("openmw.storage")
local types = require("openmw.types")
local core = require("openmw.core")

require("scripts.ShelfControl.utils.random")

local sectionMisc = storage.globalSection("SettingsShelfControl_misc")
local l10nMsgs = core.l10n("ShelfControl_messages")

local function tableIsEmptyOrFalse(tbl)
    if type(tbl) ~= "table" then
        return tbl == false
    end
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            if not tableIsEmptyOrFalse(v) then
                return false
            end
        elseif v ~= false then
            return false
        end
    end
    return true
end

function PruneMessageGroups(messages, weights)
    -- prune subgroups
    for _, group in pairs(messages) do
        if type(group) == "boolean" then goto continue end
        for subgroup, val in pairs(group) do
            if not val then
                group[subgroup] = nil
            end
        end
        ::continue::
    end
    -- prune full groups
    for key, weight in pairs(weights) do
        if weight == 0 or tableIsEmptyOrFalse(messages[key]) then
            messages[key] = nil
            weights[key] = nil
        end
    end
    -- debug print
    if sectionMisc:get("enableDebug") then
        print("Possible message groups:")
        PrintTable(messages, 2)
    end
end

function CollectAllMessagesByPrefix(prefix, l10n, ctx)
    if not ctx then ctx = {} end
    local msgs = {}
    for i = 1, MAXINT do
        local key = prefix .. "_" .. tostring(i)
        local msg = l10n(key, ctx)
        if msg ~= key then
            table.insert(msgs, msg)
        else
            break
        end
    end
    return msgs
end

function CollectEggMessages()
    return CollectAllMessagesByPrefix("easterEgg", l10nMsgs)
end

function AdditionalMsgCtx(npcRecord)
    return {
        npc_name = npcRecord.name,
        npc_class = npcRecord.class,
    }
end

function GetRandomLocalNpc(ctx)
    return RandomChoice(ctx.book.cell:getAll(types.NPC))
end