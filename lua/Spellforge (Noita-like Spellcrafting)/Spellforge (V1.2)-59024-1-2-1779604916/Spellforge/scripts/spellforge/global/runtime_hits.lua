local helper_records = require("scripts.spellforge.global.helper_records")
local projectile_registry = require("scripts.spellforge.global.projectile_registry")
local runtime_session = require("scripts.spellforge.global.runtime_session")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local sfp_adapter = require("scripts.spellforge.global.sfp_adapter")
local sfp_userdata = require("scripts.spellforge.shared.sfp_userdata")

local runtime_hits = {}

function runtime_hits.firstEffectId(helper)
    local first_effect = helper and helper.effects and helper.effects[1] or nil
    return first_effect and first_effect.id or nil
end

function runtime_hits.resolveHelperHit(payload)
    local engine_id = payload and (payload.spellId or payload.spell_id) or nil
    local projectile, projectile_id, projectile_id_source = sfp_adapter.extractProjectileFromHit(payload)
    local telemetry = sfp_adapter.magicHitTelemetry(payload)
    local registry_entry = projectile_id and projectile_registry.getByProjectileId(projectile_id) or nil
    local user_data = sfp_userdata.extract(payload)
    local spellforge_user_data = sfp_userdata.isSpellforgeUserData(user_data) and user_data or nil
    local source = spellforge_user_data and "userData" or "spellId"
    if spellforge_user_data
        and (spellforge_user_data.runtime_generation ~= nil or spellforge_user_data.runtime == "2.2c_live_helper")
        and runtime_session.shouldDrop(spellforge_user_data.runtime_generation, "runtime_hit_user_data", {
            id = projectile_id,
            strict = true,
        }) then
        runtime_stats.inc("hits_unresolved")
        return {
            ok = false,
            ignored = true,
            stale_generation = true,
            projectile_id = projectile_id,
            projectile_id_source = projectile_id_source,
            telemetry = telemetry,
            user_data = spellforge_user_data,
            source = source,
            error = "stale runtime generation",
        }
    end
    if registry_entry and runtime_session.shouldDrop(registry_entry.runtime_generation, "runtime_hit_registry", {
        id = projectile_id,
        strict = true,
    }) then
        runtime_stats.inc("hits_unresolved")
        return {
            ok = false,
            ignored = true,
            stale_generation = true,
            projectile_id = projectile_id,
            projectile_id_source = projectile_id_source,
            telemetry = telemetry,
            user_data = spellforge_user_data,
            source = source,
            error = "stale runtime registry entry",
        }
    end

    local mapping = nil
    if spellforge_user_data and type(spellforge_user_data.helper_engine_id) == "string" and spellforge_user_data.helper_engine_id ~= "" then
        mapping = helper_records.getByEngineId(spellforge_user_data.helper_engine_id)
        engine_id = spellforge_user_data.helper_engine_id
    end
    if not mapping and type(engine_id) == "string" and engine_id ~= "" then
        mapping = helper_records.getByEngineId(engine_id)
    end
    if not mapping and registry_entry then
        mapping = helper_records.getByEngineId(registry_entry.helper_engine_id)
        engine_id = registry_entry.helper_engine_id
    end
    if type(engine_id) ~= "string" or engine_id == "" then
        runtime_stats.inc("hits_unresolved")
        return {
            ok = false,
            projectile = projectile,
            projectile_id = projectile_id,
            projectile_id_source = projectile_id_source,
            telemetry = telemetry,
            user_data = spellforge_user_data,
            source = source,
            error = "hit payload missing spellId",
        }
    end
    if not mapping then
        runtime_stats.inc("hits_unresolved")
        return {
            ok = false,
            engine_id = engine_id,
            projectile = projectile,
            projectile_id = projectile_id,
            projectile_id_source = projectile_id_source,
            telemetry = telemetry,
            user_data = spellforge_user_data,
            source = source,
            error = string.format("helper record metadata not found for engine_id=%s", tostring(engine_id)),
        }
    end

    if spellforge_user_data then
        if spellforge_user_data.recipe_id ~= nil and spellforge_user_data.recipe_id ~= mapping.recipe_id then
            runtime_stats.inc("hits_userdata_mismatch")
            runtime_stats.inc("hits_unresolved")
            return {
                ok = false,
                engine_id = engine_id,
                projectile = projectile,
                projectile_id = projectile_id,
                projectile_id_source = projectile_id_source,
                telemetry = telemetry,
                user_data = spellforge_user_data,
                source = "userData",
                mapping = mapping,
                error = string.format(
                    "userData recipe_id mismatch userData=%s mapping=%s",
                    tostring(spellforge_user_data.recipe_id),
                    tostring(mapping.recipe_id)
                ),
            }
        end
        if spellforge_user_data.slot_id ~= nil and spellforge_user_data.slot_id ~= mapping.slot_id then
            runtime_stats.inc("hits_userdata_mismatch")
            runtime_stats.inc("hits_unresolved")
            return {
                ok = false,
                engine_id = engine_id,
                projectile = projectile,
                projectile_id = projectile_id,
                projectile_id_source = projectile_id_source,
                telemetry = telemetry,
                user_data = spellforge_user_data,
                source = "userData",
                mapping = mapping,
                error = string.format(
                    "userData slot_id mismatch userData=%s mapping=%s",
                    tostring(spellforge_user_data.slot_id),
                    tostring(mapping.slot_id)
                ),
            }
        end
    end

    local hit_record = projectile_registry.markHit(projectile_id, mapping.engine_id, payload, telemetry, {
        recipe_id = spellforge_user_data and spellforge_user_data.recipe_id or mapping.recipe_id,
        slot_id = spellforge_user_data and spellforge_user_data.slot_id or mapping.slot_id,
    })
    registry_entry = (hit_record and hit_record.entry) or registry_entry

    if source == "userData" then
        runtime_stats.inc("hits_userdata_routed")
    else
        runtime_stats.inc("hits_spellid_fallback_routed")
    end
    local runtime = spellforge_user_data and spellforge_user_data.runtime or nil
    if runtime == "2.2c_live_helper" then
        runtime_stats.inc("hits_live_helper_seen")
    elseif runtime == "2.2c_dev_helper" then
        runtime_stats.inc("hits_dev_helper_seen")
    elseif runtime == "2.2b_live_dispatch" then
        runtime_stats.inc("hits_legacy_seen")
    end

    return {
        ok = true,
        error = nil,
        duplicate = hit_record and hit_record.first_hit == false or false,
        first_hit = hit_record and hit_record.first_hit or false,
        hit_key = hit_record and hit_record.hit_key or nil,
        previous = hit_record and hit_record.previous or nil,
        source = source,
        user_data = spellforge_user_data,
        mapping = mapping,
        recipe_id = spellforge_user_data and spellforge_user_data.recipe_id or mapping.recipe_id,
        slot_id = spellforge_user_data and spellforge_user_data.slot_id or mapping.slot_id,
        helper_engine_id = spellforge_user_data and spellforge_user_data.helper_engine_id or mapping.engine_id,
        effect_id = runtime_hits.firstEffectId(mapping),
        projectile = projectile,
        projectile_id = projectile_id,
        projectile_id_source = projectile_id_source,
        projectile_registry_entry = registry_entry,
        runtime_generation = spellforge_user_data and spellforge_user_data.runtime_generation
            or registry_entry and registry_entry.runtime_generation
            or runtime_session.currentGeneration(),
        hit_record = hit_record,
        telemetry = telemetry,
        impactSpeed = telemetry and telemetry.impactSpeed or nil,
        maxSpeed = telemetry and telemetry.maxSpeed or nil,
        velocity = telemetry and telemetry.velocity or nil,
        magMin = telemetry and telemetry.magMin or nil,
        magMax = telemetry and telemetry.magMax or nil,
        casterLinked = telemetry and telemetry.casterLinked or nil,
        stackLimit = telemetry and telemetry.stackLimit or nil,
        stackCount = telemetry and telemetry.stackCount or nil,
        hit_pos = payload and (payload.hitPos or payload.hit_pos) or nil,
        hit_normal = payload and (payload.hitNormal or payload.hit_normal) or nil,
        attacker = payload and payload.attacker or nil,
        target = payload and payload.target or nil,
        raw_payload = payload,
    }
end

return runtime_hits
