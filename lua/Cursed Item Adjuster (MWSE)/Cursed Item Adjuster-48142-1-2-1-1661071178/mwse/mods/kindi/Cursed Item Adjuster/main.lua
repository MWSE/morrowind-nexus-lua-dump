-- v1.3
local config = require("kindi.Cursed Item Adjuster.config")
local CELL = require("kindi.Cursed Item Adjuster.cells")
local DAEDRA = require("kindi.Cursed Item Adjuster.daedras")

local function spawnDaedra(daedricPrince, objectValue)
    local daedra = nil

    -- // matching summon
    if config.summonType == "Matching" then
        daedra = table.choice(DAEDRA[daedricPrince] or {}) or "dremora_lord"-- //unknown daedric prince use the default
        -- //randomised summon
    elseif config.summonType == "Randomised" then
        daedra = table.choice(DAEDRA["Random"])
        -- //default vanilla summon
    elseif config.summonType == "Default" then
        daedra = "dremora_lord"
        -- //item value summon
    elseif config.summonType == "Item Value" then
        if objectValue < 100 then
            daedra = table.choice(DAEDRA["GR1"])
        elseif objectValue >= 100 and objectValue < 250 then
            daedra = table.choice(DAEDRA["GR2"])
        elseif objectValue >= 250 then
            daedra = table.choice(DAEDRA["GR3"])
        end
        -- // no summon
    elseif config.summonType == "Nothing" then
        return 1
    else --//unknown summon type fallback to default behaviour
        return 0
    end


    if tes3.getObject(daedra) then
        -- // using mwscript API(not tes3.createReference) to mimic the original behaviour
        local summon = mwscript.placeAtPC {
            reference = tes3.player,
            object = daedra,
            direction = 1,
            distance = 128,
            count = nil
        }

        -- // adds a summon vfx similar to conjuration spell (if option is enabled in config)
        if config.summonVFX then
            tes3.createVisualEffect {
                avObject = summon.sceneNode,
                repeatCount = 1,
                object = "VFX_Summon_Start"
            }
            tes3.playSound {
                reference = summon,
                sound = "conjuration hit"
            }
        end

        if config.debug then
            tes3.messageBox("Cursed Item [%s]: %s", config.summonType, tes3.getObject(daedra).name)
        end

        return 1
    end

    mwse.log('[Cursed Item Adjuster] Unable to resolve Daedra ID "%s". Fallback to default', daedra)
    return 0
end

-- //find the daedric statue in this cell to determine which daedric prince owns this cursed item
local function determineDaedricPrince(cell)
    local daedricPrince
    for ref in cell:iterateReferences({tes3.objectType.static, tes3.objectType.activator}) do
        if ref.id == "active_dae_sheogorath" or ref.id == "ex_dae_sheogorath" then
            daedricPrince = "Sheogorath"
            break
        elseif ref.id == "active_dae_malacath" or ref.id == "ex_dae_malacath" or ref.id == "ex_dae_malacath_attack" then
            daedricPrince = "Malacath"
            break
        elseif ref.id == "active_dae_molagbal" or ref.id == "ex_dae_molagbal" then
            daedricPrince = "Molag Bal"
            break
        elseif ref.id == "active_dae_mehrunes" or ref.id == "ex_dae_mehrunesdagon" then
            daedricPrince = "Mehrunes Dagon"
            break
        elseif ref.id == "active_dae_azura" or ref.id == "ex_dae_azura" then
            daedricPrince = "Azura"
            break
        elseif ref.id == "active_dae_boethiah" or ref.id == "Ex_DAE_Boethiah" then
            daedricPrince = "Boethiah"
            break
        end
    end

    -- //overwrites the previous daedricPrince
    if CELL[cell.id:lower()] then
        daedricPrince = CELL[cell.id:lower()]
    end

    if config.debug and daedricPrince then
        tes3.messageBox("This cell belongs to %s", daedricPrince)
    end

    return daedricPrince
end

-- prevents vanilla activation of cursed objects
event.register("activate", function(e)
    local tref = e.target
    if config.modActive and tref.object.script and tref.object.script.id == "BILL_MarksDaedraSummon" and tref.context.done ~= 1 then
         -- local variable in the cursed item 
        tref.context.done = spawnDaedra(determineDaedricPrince(e.target.cell), e.target.object.value)  
    end
end)

event.register("modConfigReady", function()
    require("kindi.Cursed Item Adjuster.mcm")
end)

event.register("initialized", function()
    mwse.log("[Cursed Item Adjuster] Initialized")
end)

