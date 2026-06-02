local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local common = require('scripts.wispspell.common')

local state = {
    spawned = false,
    tome = nil,
    nextSpawnCheck = 0,
}

local CHECK_INTERVAL = 1.0

local function isValid(object)
    return common.isValid(object)
end

local function isPlayer(actor)
    return isValid(actor) and types.Player and types.Player.objectIsInstance(actor)
end

local function bookRecordId(object)
    if not isValid(object) then return nil end
    local ok, record = pcall(types.Book.record, object)
    if ok and record then return common.lower(record.id) end
    return nil
end

local function isArdarumeCell(cell)
    if not cell then return false end
    return common.tomeCellAliases[common.lower(cell.name)] == true
end

local function isSoulWispTome(object)
    local id = bookRecordId(object)
    if id == common.lower(common.tomeId) then return true end

    -- Safety fallback: if the placed custom copy ever fails to spawn, the
    -- vanilla Fragment: On Artaeum that already exists in Ardarume's room can
    -- still teach the spell. Other copies elsewhere remain ordinary books.
    return id == common.lower(common.tomeSourceBookId) and isArdarumeCell(object.cell)
end

local function hasSpell(actor)
    local ok, spells = pcall(types.Actor.spells, actor)
    if not ok or not spells then return false end

    local known = false
    pcall(function()
        known = spells[common.spellId] ~= nil
    end)
    return known
end

local function teachSoulWisp(actor)
    if not isPlayer(actor) then return end
    if hasSpell(actor) then return end

    local ok, spells = pcall(types.Actor.spells, actor)
    if not ok or not spells then return end

    local added = pcall(function()
        spells:add(common.spellId)
    end)

    if added then
        pcall(function()
            types.Player.addTopic(actor, common.tomeDialogueTopic)
        end)
        actor:sendEvent('RT_SoulWispTomeMessage', {
            text = 'You learn Conjure Soul Wisp.'
        })
        common.log('tome', 'Player learned Conjure Soul Wisp from ' .. common.tomeId .. '.')
    end
end

local function maybeTeachFromBook(object, actor)
    if isSoulWispTome(object) then
        teachSoulWisp(actor)
    end
end

if I.Activation and I.Activation.addHandlerForType then
    I.Activation.addHandlerForType(types.Book, function(object, actor)
        maybeTeachFromBook(object, actor)
        -- Return nil so the normal book reading UI still opens.
    end)
end

if I.ItemUsage and I.ItemUsage.addHandlerForType then
    I.ItemUsage.addHandlerForType(types.Book, function(object, actor)
        maybeTeachFromBook(object, actor)
        -- Return nil so vanilla/use behaviour continues.
    end)
end

local function isArdarume(actor)
    if not isValid(actor) or not types.NPC.objectIsInstance(actor) then return false end

    local ok, record = pcall(types.NPC.record, actor)
    if not ok or not record then return false end

    local id = common.lower(record.id)
    local name = common.lower(record.name)
    return id == 'ardarume' or name == 'ardarume'
end

local function spawnTomeNearArdarume()
    if state.spawned then return end

    for _, actor in ipairs(world.activeActors or {}) do
        if isArdarume(actor) and isArdarumeCell(actor.cell) then
            local tome = world.createObject(common.tomeId, 1)
            local position = actor.position + util.vector3(55, -35, 45)
            tome:teleport(actor.cell.name, position)

            state.spawned = true
            state.tome = tome
            common.log('tome', 'Placed Soul Wisp tome near Ardarume.')
            return
        end
    end
end

local function onLoad(save)
    if save then
        state.spawned = save.spawned == true
        state.tome = save.tome
    end
    state.nextSpawnCheck = 0
end

local function onSave()
    return {
        spawned = state.spawned,
        tome = state.tome,
    }
end

local function onUpdate(dt)
    if state.spawned then return end

    state.nextSpawnCheck = (state.nextSpawnCheck or 0) - dt
    if state.nextSpawnCheck > 0 then return end

    state.nextSpawnCheck = CHECK_INTERVAL
    spawnTomeNearArdarume()
end

return {
    onLoad = onLoad,
    onSave = onSave,
    onUpdate = onUpdate,
}
