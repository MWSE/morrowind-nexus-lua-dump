local me_effects = require("OperatorJack.MagickaExpanded.classes.effects")


local mod_log = require("herbert100.logger")("fortify magicka regen") ---@type herbert.Logger

---@alias FMR.spell_id
---|23235 fortify magicka regen
---|23236 drain magicka regen

local fmr_id = 23235    ---@type FMR.spell_id
local dmr_id = fmr_id+1 ---@type FMR.spell_id


---@param spell_name string name of the spell
---@param id FMR.spell_id id of the spell
---@param range_type tes3.effectRange
local function make_give_use_less_spell_func(spell_name, id, range_type)
    -- why not make a function that returns a function. surely this won't harm the readability
    return function()
        
        local spell = tes3.createObject{objectType=tes3.objectType.spell} ---@cast spell tes3spell
        spell.name, spell.magickaCost = spell_name, 500

        for k,v in pairs{id=id, rangeType=range_type or tes3.effectRange.touch, min=1, max=1, duration=1, radius=0, skill=-1, attribute=-1} do
            spell.effects[1][k] = v
        end
        tes3.addSpell{reference=tes3.mobilePlayer, spell=spell}
        tes3.messageBox("Spell added.")
    end
end

---@class FMR.effect_cfg
---@field bc number base cost for spell
---@field allow_spellmaking boolean 
---@field allow_enchanting boolean


---@type table<FMR.spell_id, FMR.effect_cfg>
local config = mwse.loadConfig("fortify magicka regen", {
    [fmr_id] = {bc=1.75, allow_enchanting=true, allow_spellmaking=true, }, ---@type FMR.effect_cfg
    [dmr_id] = {bc=1, allow_enchanting=true, allow_spellmaking=true, }, ---@type FMR.effect_cfg
})



---@class FMR.make_magicka_regen_effect.params
---@field id integer id of the effect
---@field name string name of the spell
---@field school tes3.magicSchool
---@field description string description of the effect
---@field td_index string `tempData` index to use for this spell
---@field beg_calc fun(mag: integer, td_val: number|nil): number function that calculates the effect of this spell
---@field end_calc (fun(mag: integer, td_val: number|nil): number|nil) function that calculates the effect of this spell
---@field abbrev string? the module_name to give to the logger. if not provided, it will default to `id`

local function get_state_str(instance)
    return table.find(tes3.spellState, instance.state)
    
end
local beginning, working, ending, ending_fortify = tes3.spellState.beginning, tes3.spellState.working, tes3.spellState.ending, tes3.spellState.endingFortify

---@param e tes3magicEffectTickEventData
local function on_tick_msg(e)
    return "starting onTick with:\n\t\z
        src_state: \"%s\"\n\t\z
        eff_state: \"%s\"\n\t\z
        mag: %s\n\t\z
        emag: %s\n\t\z
        cmag: %s",
        get_state_str(e.sourceInstance),
        get_state_str(e.effectInstance),
        e.effectInstance.magnitude,
        e.effectInstance.effectiveMagnitude,
        e.effectInstance.cumulativeMagnitude
end

---@param e tes3magicEffectTickEventData
local function mag_recalculated_msg(mag, e)
    return "state was beginning. magnitude is %s. after recalculating magnitude, state is %s", 
       mag, get_state_str(e.effectInstance)
end
-- this is a wrapper for OperatorJack's wrapper. lol
---@param p FMR.make_magicka_regen_effect.params
local function make_target_data_effect(p)
    local log = mod_log .. (p.abbrev or tostring(p.id))
    local cfg = config[p.id]
    local index, beg_calc, end_calc = p.td_index, p.beg_calc, p.end_calc
    me_effects[table.find(tes3.magicSchool, p.school)].createBasicEffect{
        id=p.id,
        name=p.name,
        description=p.description,
        baseCost=cfg.bc,
        isHarmful=false,
        -- unreflectable=true, isHarmful=false, nonRecastable=false, appliesOnce=false,
        canCastSelf=cfg.allow_spellmaking,
        canCastTarget=true,
        canCastTouch=true,
        allowEnchanting=cfg.allow_enchanting,
        allowSpellmaking=cfg.allow_spellmaking,
        appliesOnce=false,
        hasNoMagnitude=false,


    ---@param e tes3magicEffectTickEventData
        onTick=function (e)
            log(on_tick_msg, e)

            -- this one will happen the most frequently (several times per second), so it's the most "optimized"
            if e.effectInstance.state == working then e:trigger(); return end


            -- the state of the spell. the `onTick` function will be called exactly once with each of the following states:
            -- 1) working
            -- 2) ending
            -- 3) retired (but we dont care about this)
            local state = e.effectInstance.state


            if state == beginning then
                -- the state being `beginning` happens once each time the spell is cast, so we can go a bit crazy here
                local mag = e.effectInstance.effectiveMagnitude
                while mag == 0 do
                    log:debug("magnitude was 0. calling e:trigger().")
                    e:trigger()
                    mag = e.effectInstance.effectiveMagnitude
                end

                log(mag_recalculated_msg, mag, e)
                -- if mag == nil or mag < 1 then e:trigger(); return end

                if not e.effectInstance.target then e.effectInstance.state = tes3.spellState.retired; e:trigger(); return end

                local td = e.effectInstance.target.data
                td[index] = beg_calc(mag, td[index])
                log("set target.data.%s = %s", index, td[index])

            
            elseif state == ending or state == ending_fortify then
                log("state is ending")
                local eff_instance = e.effectInstance
                local td = eff_instance.target.data
                local td_val = td[index]
                if td.herbert_fmr then 
                    -- log("about to end effect. current magicka regeneration is %s%%", (target.tempData.herbert_fmr or 0) * 100)
                    td[index] = end_calc(eff_instance.effectiveMagnitude, td_val)
                    log("set target.data.%s = %s", index, td[index])
                else
                    log("variable didnt exist!")
                end
            end
            e:trigger() -- let the normal spell system talk to it
            log("called e:trigger(). state is now %s", get_state_str, e.effectInstance)
        end,
        
        -- icon =  "RFD\\RFD_ms_restoration.tga",
        -- particleTexture =  "vfx_bluecloud.tga",
        -- castSound =  "restoration cast",
        -- castVFX =  "VFX_RestorationCast",
        -- boltSound =  "restoration bolt",
        -- boltVFX =  "VFX_RestoreBolt",
        -- hitSound =  "restoration hit",
        -- hitVFX =  "VFX_RestorationHit",
        -- areaSound =  "restoration area",
        -- areaVFX =  "VFX_RestorationArea",
        -- size =  1,
        -- sizeCap =  50,
    }
end


event.register(tes3.event.magicEffectsResolved,function()
    make_target_data_effect{ id=fmr_id, name="Fortify Magicka Regeneration", school=tes3.magicSchool.restoration,
        effect_index_str="fortifyMagickaRegen",
        td_index="herbert_fmr", 
        description="This effect causes magicka to regenerate at an increased rate.",
        beg_calc = function (mag, td_val)
            return (td_val or 1) + 0.01 * mag
        end,
        end_calc = function (mag, td_val)
            if td_val ~= nil then
                td_val = td_val - 0.01 * mag
                if td_val > 1 then
                    return td_val
                end
            end
            -- otherwise return `nil`
        end
    }
    make_target_data_effect{ id=dmr_id, name="Drain Magicka Regeneration", school=tes3.magicSchool.destruction,
        effect_index_str="drainMagickaRegen",
        td_index="herbert_dmr", 
        description="This effect reduces the rate at which magicka regenerates.",
        beg_calc = function (mag, td_val)
            if td_val then -- add the existing magnitude of the effect
                --[[ 1/(1 + mag/100)
                ~> 1/td_val         == 1 + mag/100
                ~> 1/td_val - 1     == mag/100
                ~> 100/td_val - 100 == mag          <-- this is the total existing magnitude
                ]]
                mag = mag + 100/td_val - 100
            end
            return 1/(1 + 0.01 * mag)
        end,
        end_calc = function (mag, td_val)
            if td_val == nil then return end
            -- subtract `mag` from the existing magnitude of the effect
            local total_mag =  100/td_val - 100 - mag
            if total_mag < 1 then
                return total_mag
            end
        end
    }
end)



tes3.claimSpellEffectId("fortifyMagickaRegen", fmr_id)
tes3.claimSpellEffectId("drainMagickaRegen", dmr_id)







event.register(tes3.event.modConfigReady,function (e)
    local MCM = require("herbert100.MCM").new{mod_name="Drain/Fortify Magicka Regeneration", config=config}
    local page = MCM:new_sidebar_page{label="Settings",
        desc="Each point of the The Fortify Magicka Regeneration effect will make you regenerate magicka 1% faster. It requires a compatible magicka regeneration mod.\n\n\z
            The current version of this mod does not add it to level lists or the in-game world (hopefully a future release will). So, you'll have to add an effect yourself.\n\n\z
            These settings let you customize a few properties of the effect, if you'd like.\n\n\z
            Every setting except the \"give spell\" button will require a restart in order to take effect."
    }
    MCM.template:saveOnClose("fortify magicka regen", config)

    local mcm_info = {
        {id=fmr_id, name="Fortify Magicka Regen", spell_name="Useless Magicka Regen Spell", range_type=tes3.effectRange.touch},
        {id=dmr_id, name="Drain Magicka Regen", spell_name="Useless Drain Regen Spell",range_type=tes3.effectRange.self},
    }
    for _, info in ipairs(mcm_info) do
        mod_log:debug("making new %q settings. id = %s", info.name, info.id)
        local cat = page:new_category{label=info.name .. "eration Settings", desc=info.description, config=config[info.id]}

        cat.component:createButton{buttonText="Add Spell", label="Give useless spell.", inGameOnly=true,
            description = string.format("This will add a useless %seration spell to your magic menu, so that you can use the effect in spellmaking/enchanting menus.", info.name),
            callback=make_give_use_less_spell_func(info.spell_name,info.id,info.range_type)
        }
        cat:new_dslider{label="Base cost", id="bc", max=7.5,
            desc="This is the coefficient used to calculate spell costs and the like.\n\n\z
                The \"Fortify Magicka\" effect has a baseCost of 1, as do the \"Fortify Skill\" effects. \z
                The \"Fortify Fatigue\" effect has a base cost of 0.5.",
        }
        cat:new_button{label="Allow spellmaking?", id="allow_spellmaking",
             desc="This setting controls whether this effect is allowed in the spellmaking menu.",
        }
        cat:new_button{label="Allow enchanting?", id="allow_enchanting",
            description="This setting controls whether this effect is allowed in enchanting menus.",
        }
    end
    mod_log:add_to_MCM{component=page.component,config=config}
    MCM:register()
end)


