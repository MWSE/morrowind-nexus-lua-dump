local log = require("scripts.spellforge.shared.log").new("global.projectile_registry")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")

local projectile_registry = {}

local by_projectile_id = {}
local projectile_ids_by_helper = {}
local projectile_ids_by_recipe = {}
local projectile_ids_by_slot = {}
local last_launch_by_helper = {}
local last_hit_by_helper = {}
local by_launch_instance_id = {}
local processed_hits = {}
local hit_projectiles = {}
local next_launch_index = 1

local function appendList(map, key, value)
    if key == nil or value == nil then
        return
    end
    local list = map[key]
    if not list then
        list = {}
        map[key] = list
    end
    list[#list + 1] = value
end

local function cloneList(list)
    local out = {}
    for i, value in ipairs(list or {}) do
        out[i] = value
    end
    return out
end

local function countMap(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end
    return count
end

local function compactScalarTable(value)
    if type(value) ~= "table" then
        return nil
    end
    local out = {}
    for key, item in pairs(value) do
        local item_type = type(item)
        if item_type == "string" or item_type == "number" or item_type == "boolean" then
            out[key] = item
        end
    end
    return out
end

local function safeReadField(value, key)
    if value == nil then
        return nil
    end
    local ok, result = pcall(function()
        return value[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function statePosition(state)
    if type(state) ~= "table" then
        return nil
    end
    return safeReadField(state, "position")
        or safeReadField(state, "pos")
        or safeReadField(state, "hitPos")
        or safeReadField(state, "hit_pos")
end

local function stateDirection(state)
    if type(state) ~= "table" then
        return nil
    end
    return safeReadField(state, "direction")
        or safeReadField(state, "velocity")
        or safeReadField(state, "vel")
end

local function stateCell(state)
    if type(state) ~= "table" then
        return nil
    end
    local cell = safeReadField(state, "cell")
    if cell ~= nil then
        return cell
    end
    local projectile = safeReadField(state, "projectile")
    return safeReadField(projectile, "cell")
end

local function compactState(state, update_count)
    if type(state) ~= "table" then
        return nil
    end
    return {
        position = statePosition(state),
        pos = statePosition(state),
        direction = stateDirection(state),
        velocity = safeReadField(state, "velocity"),
        cell = stateCell(state),
        tag = safeReadField(state, "tag"),
        raw_tag = safeReadField(state, "raw_tag"),
        timestamp = safeReadField(state, "timestamp") or safeReadField(state, "time"),
        tick = safeReadField(state, "tick"),
        state_update_count = update_count,
    }
end

function projectile_registry.registerLaunch(launch_result, metadata)
    local result = launch_result or {}
    local input = metadata or {}
    local projectile_id = result.projectile_id
    local runtime_generation = tonumber(input.runtime_generation)
        or tonumber(result.runtime_generation)
        or runtime_session.currentGeneration()
    local launch_instance_id = string.format("launch_%d", next_launch_index)
    next_launch_index = next_launch_index + 1
    local entry = {
        launch_instance_id = launch_instance_id,
        projectile_id = projectile_id,
        projectile_id_source = result.projectile_id_source,
        helper_engine_id = input.helper_engine_id,
        recipe_id = input.recipe_id,
        slot_id = input.slot_id,
        job_id = input.job_id,
        start_pos = input.start_pos,
        direction = input.direction,
        user_data = compactScalarTable(input.user_data),
        runtime_generation = runtime_generation,
    }

    if entry.helper_engine_id then
        last_launch_by_helper[entry.helper_engine_id] = entry
    end
    by_launch_instance_id[launch_instance_id] = entry

    if projectile_id ~= nil then
        runtime_session.trackProjectile(projectile_id, runtime_generation)
        by_projectile_id[projectile_id] = entry
        appendList(projectile_ids_by_helper, entry.helper_engine_id, projectile_id)
        appendList(projectile_ids_by_recipe, entry.recipe_id, projectile_id)
        appendList(projectile_ids_by_slot, entry.slot_id, projectile_id)
    end

    return entry
end

function projectile_registry.hitKey(projectile_id, helper_engine_id, metadata)
    if projectile_id ~= nil then
        return "projectile:" .. tostring(projectile_id)
    end

    local input = metadata or {}
    return string.format(
        "helper:%s:%s:%s",
        tostring(input.recipe_id),
        tostring(input.slot_id),
        tostring(helper_engine_id)
    )
end

function projectile_registry.getByProjectileId(projectile_id)
    return by_projectile_id[projectile_id]
end

function projectile_registry.getProjectilesForHelper(helper_engine_id)
    return cloneList(projectile_ids_by_helper[helper_engine_id])
end

function projectile_registry.getProjectilesForRecipe(recipe_id)
    return cloneList(projectile_ids_by_recipe[recipe_id])
end

function projectile_registry.getProjectilesForSlot(slot_id)
    return cloneList(projectile_ids_by_slot[slot_id])
end

function projectile_registry.getLastLaunchForHelper(helper_engine_id)
    return last_launch_by_helper[helper_engine_id]
end

function projectile_registry.getLastHitForHelper(helper_engine_id)
    return last_hit_by_helper[helper_engine_id]
end

function projectile_registry.markHit(projectile_id, helper_engine_id, hit_payload, telemetry, metadata)
    local input = metadata or {}
    local entry = projectile_id and by_projectile_id[projectile_id] or nil
    if not entry and input.launch_instance_id then
        entry = by_launch_instance_id[input.launch_instance_id]
    end
    if not entry and helper_engine_id then
        entry = last_launch_by_helper[helper_engine_id]
    end

    local hit_key = projectile_registry.hitKey(projectile_id, helper_engine_id, {
        recipe_id = input.recipe_id or (entry and entry.recipe_id),
        slot_id = input.slot_id or (entry and entry.slot_id),
    })
    local previous = processed_hits[hit_key]
    local hit_record = {
        ok = true,
        first_hit = previous == nil,
        hit_key = hit_key,
        previous = previous,
        entry = entry,
        projectile_id = projectile_id,
        helper_engine_id = helper_engine_id,
        telemetry = telemetry or sfp_adapter.magicHitTelemetry(hit_payload),
    }
    if previous == nil then
        processed_hits[hit_key] = hit_record
    end

    if projectile_id ~= nil then
        hit_projectiles[tostring(projectile_id)] = true
    end

    if helper_engine_id then
        last_hit_by_helper[helper_engine_id] = hit_record
    end

    return hit_record
end

function projectile_registry.markState(projectile_id, state_payload)
    local entry = projectile_id and by_projectile_id[projectile_id] or nil
    if entry ~= nil then
        entry.state_update_count = (tonumber(entry.state_update_count) or 0) + 1
        entry.latest_state = compactState(state_payload, entry.state_update_count)
    end
    return entry
end

function projectile_registry.getLatestState(projectile_id)
    local entry = projectile_id and by_projectile_id[projectile_id] or nil
    return entry and entry.latest_state or nil
end

function projectile_registry.wasHit(projectile_id)
    if projectile_id == nil then
        return false
    end
    return hit_projectiles[tostring(projectile_id)] == true
end

function projectile_registry.projectileIds()
    local ids = {}
    for projectile_id in pairs(by_projectile_id) do
        ids[#ids + 1] = projectile_id
    end
    return ids
end

function projectile_registry.summary()
    return {
        projectiles = countMap(by_projectile_id),
        helpers = countMap(projectile_ids_by_helper),
        recipes = countMap(projectile_ids_by_recipe),
        slots = countMap(projectile_ids_by_slot),
        launches = countMap(by_launch_instance_id),
        hit_marks = countMap(processed_hits),
        state_updates = (function()
            local count = 0
            for _, entry in pairs(by_projectile_id) do
                count = count + (tonumber(entry.state_update_count) or 0)
            end
            return count
        end)(),
        runtime_generation = runtime_session.currentGeneration(),
    }
end

function projectile_registry.clearHitMarksForTests()
    last_hit_by_helper = {}
    processed_hits = {}
    hit_projectiles = {}
end

function projectile_registry.clearTransient(reason)
    local before = projectile_registry.summary()
    by_projectile_id = {}
    projectile_ids_by_helper = {}
    projectile_ids_by_recipe = {}
    projectile_ids_by_slot = {}
    last_launch_by_helper = {}
    last_hit_by_helper = {}
    by_launch_instance_id = {}
    processed_hits = {}
    hit_projectiles = {}
    next_launch_index = 1
    log.info(string.format(
        "SPELLFORGE_PROJECTILE_REGISTRY_CLEARED reason=%s projectiles=%s helpers=%s recipes=%s slots=%s launches=%s hit_marks=%s runtime_generation=%s",
        tostring(reason),
        tostring(before.projectiles),
        tostring(before.helpers),
        tostring(before.recipes),
        tostring(before.slots),
        tostring(before.launches),
        tostring(before.hit_marks),
        tostring(runtime_session.currentGeneration())
    ))
    return before
end

function projectile_registry.clearForTests()
    return projectile_registry.clearTransient("tests")
end

return projectile_registry
