local config = require("spellcraftRecognition.config");
local cl_op


if lfs.fileexists("Data Files\\MWSE\\mods\\SpellcraftRecognition\\combatlog_interop.lua") then
    cl_op = require("spellcraftRecognition.combatlog_interop") end



event.register("modConfigReady", function()
    require("spellcraftRecognition.mcm")
end)


local function parseSpell(spell)
    local effects = ""
    for i,ename in ipairs(spell.effects) do 
        if(ename.object ~= nill) then 
            effects = effects .. ename.object.name
                if(ename.object.name ~= "Paralyze") then
                    if(ename.min == ename.max) then
                        if(ename.min > 1) then effects = effects .. " " .. ename.min end
                    else
                        effects = effects .. " " .. ename.min .. "-" .. ename.max
                    end
                end
                effects = effects .. " "
        end
    end
    effects = string.sub(effects, 1, -2)
    return effects
end

local function spellCastCallback(e)
    if(e.caster == tes3.player) then return end
    local castChance = e.spell:calculateCastChance({ checkMagicka = false, caster = tes3.player.mobile })
    if(castChance < 0) then castChance = 0 end
    local effects = parseSpell(e.spell)
    local str = e.caster.mobile.object.name .. " casts " .. e.spell.name .. " (" .. effects .. ")"
    if(castChance >= config.threshold) then 
        if cl_op then cl_op.sendMessageToCLog(str) end
        tes3.messageBox(e.caster.mobile.object.name .. " casts " .. e.spell.name .. " (" .. effects .. ")") 
    end
end


local function initialized()
    event.register(tes3.event.spellMagickaUse, spellCastCallback)
    print("[SpellcraftRecognition] Event registered")
end

event.register(tes3.event.initialized, initialized)