local limits = require("scripts.spellforge.shared.limits")

local MODIFIER_ICON_BASE = "icons/spellforge/modifiers/"

local function bigIconPathFor(icon)
    if type(icon) ~= "string" or icon == "" then
        return nil
    end
    local prefix, filename = string.match(icon, "^(.*[/\\])([^/\\]+)$")
    local name = filename or icon
    name = string.gsub(name, "%.[^%.]+$", "")
    return (prefix or MODIFIER_ICON_BASE) .. "b_" .. name .. ".dds"
end

local opcodes = {
    Multicast = {
        kind = "launch_modifier",
        display_name = "Multicast",
        description = "Emit multiple copies of the next emitter.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_multicast.png",
        parameters = {
            count = { type = "integer", min = 2, max = limits.MAX_PAYLOAD_FANOUT_HARD, default = 3 },
        },
    },
    Spread = {
        kind = "launch_modifier",
        display_name = "Spread",
        description = "Apply spread preset to multicast emissions.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_spread.png",
        parameters = {
            preset = { type = "integer", min = 1, max = 4, default = 1 },
        },
    },
    Burst = {
        kind = "launch_modifier",
        display_name = "Burst",
        description = "Emit spherical burst copies of the next emitter.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_burst.png",
        parameters = {
            count = { type = "integer", min = 2, max = 16, default = 5 },
            -- TODO(2.2c): validate Burst+Multicast combinations against MAX_PROJECTILES_PER_CAST
            -- during effect-list compile planning. Keep vocab/range-only validation here.
        },
    },
    ["Speed+"] = {
        kind = "launch_modifier",
        display_name = "Speed+",
        description = "Scale projectile velocity on the next emitter by percent.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_speed_plus.png",
        parameters = {
            percent = { type = "number", min = -90, max = 400, default = 50 },
        },
    },
    ["Size+"] = {
        kind = "launch_modifier",
        display_name = "Size+",
        description = "Scale projectile size / AoE radius by percent.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_size_plus.png",
        parameters = {
            percent = { type = "number", min = -90, max = 300, default = 100 },
        },
    },
    Chain = {
        kind = "launch_modifier",
        display_name = "Chain",
        description = "Redirect projectile on hit to nearest actor up to N hops.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_chain.png",
        parameters = {
            hops = { type = "integer", min = 1, max = limits.MAX_CHAIN_HOPS, default = 3 },
        },
    },
    Bounce = {
        kind = "launch_modifier",
        display_name = "Bounce",
        description = "Reflect the projectile off surfaces or actors up to N bounces.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_bounce.png",
        parameters = {
            bounces = { type = "integer", min = 1, max = limits.MAX_BOUNCE_COUNT_HARD, default = 3 },
        },
    },
    Pierce = {
        kind = "launch_modifier",
        display_name = "Pierce",
        description = "Pass through N unique actors; the next actor or geometry hit stops normally.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_pierce.png",
        parameters = {
            pierces = { type = "integer", min = 1, max = limits.MAX_PIERCE_COUNT_HARD, default = 2 },
        },
    },
    Homing = {
        kind = "launch_modifier",
        display_name = "Homing",
        description = "Apply bounded SFP force-vector aim assist toward the launch target.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_homing.png",
        parameters = {},
    },
    Detonate = {
        kind = "launch_modifier",
        display_name = "Detonate",
        description = "Resolve the next payload emitter as an immediate area detonation.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_detonate.png",
        parameters = {},
    },
    Trigger = {
        kind = "scope_opener",
        display_name = "Trigger",
        description = "Open payload scope resolved when previous emitter impacts.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_trigger.png",
        parameters = {},
    },
    Timer = {
        kind = "scope_opener",
        display_name = "Timer",
        description = "Open payload scope resolved after N seconds.",
        icon = "icons/spellforge/modifiers/spellforge_modifier_timer.png",
        parameters = {
            seconds = { type = "number", min = 0.5, max = 5.0, default = 1.0 },
        },
    },
}

for _, def in pairs(opcodes) do
    if type(def) == "table" and def.large_icon == nil then
        def.large_icon = bigIconPathFor(def.icon)
    end
end

return opcodes
