
-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20190821) then
    event.register("initialized", function()
        tes3.messageBox(
            "[Illegal Summoning] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end)
    return
end

local config = require("OperatorJack.IllegalSummoning.config")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\OperatorJack\\IllegalSummoning\\mcm.lua")
end)

local function getNearbyGuards(caster)
    local actors = {}
    for ref in caster.cell:iterateReferences(tes3.objectType.npc) do
        if (ref.object.class.id == "Guard") then
            local distance = math.abs(caster.position:distance(ref.position))
            if (distance <= config.npcTriggerDistance) then
                table.insert(actors, ref)
            end
        end
    end
    return actors
end

local function triggerCrime(caster, isPlayer) 
    if (isPlayer == true) then
        -- Since it is the player, we can use the built in crime mechanics.
        tes3.triggerCrime({
            criminal = caster,
            type = tes3.crimeType.theft,
            value = config.bountyValue
        })
    else
        -- Built in crime mechanics don't apply to NPCs, so we must do it manually.
        local guards = getNearbyGuards(caster)
        for _, guard in pairs(guards) do
            local isDetected = mwscript.getDetected({
                reference = guard,
                target = caster
            })

            if (isDetected == true) then
                mwscript.startCombat({
                    reference = guard,
                    target = caster
                })
            end
        end
    end
end

local function onCast(e)   
    local isPlayer = false
    if (e.caster == tes3.player) then
        isPlayer = true
    end

    --@type tes3cell
    local cell = e.caster.cell

    if (cell.restingIsIllegal) then
        for _, effect in ipairs(e.source.effects) do
            if (effect.object) then
                local name = effect.object.name:lower()
                if (config.effectWhitelist[name]) then
                    return
                elseif (config.effectBlacklist[name]) then
                    triggerCrime(e.caster, isPlayer)
                elseif (name:lower():startswith("summon ")) then
                    if (isPlayer == false) then
                        local casterName = e.caster.object.name:lower()
                        if (config.npcWhitelist[casterName]) then
                            return
                        end
                    end
                    
                    triggerCrime(e.caster, isPlayer)
                end
            end
        end 
    end  
end

local function onInitialized()
	--Watch for spellcast.
	event.register("spellCasted", onCast)

	print("[Illegal Summoning: INFO] Initialized Illegal Summoning")
end
event.register("initialized", onInitialized)