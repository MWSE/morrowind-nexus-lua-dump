-- Make sure we have an up-to-date version of MWSE.
if (mwse.buildDate == nil) or (mwse.buildDate < 20190821) then
    event.register("initialized", function()
        tes3.messageBox(
            "[The Levitation Act] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end)
    return
end

local config = require("OperatorJack.TheLevitationAct.config")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\OperatorJack\\TheLevitationAct\\mcm.lua")
end)

local function isCellWhitelisted(cell)
    local str = cell:lower()
    for key, _ in pairs(config.cellWhitelist) do
        if (string.startswith(str, key)) then
            return true
        end
    end
    return false
end

local function onCast(e)   
    if (e.caster ~= tes3.player) then
        return
    end

    for _, effect in ipairs(e.source.effects) do
        if (effect.object) then
            if (effect.object.id == tes3.effect.levitate) then
                if (isCellWhitelisted(e.caster.cell.name)) then
                    return
                else    
                    tes3.triggerCrime({
                        criminal = e.caster,
                        type = tes3.crimeType.theft,
                        value = config.bountyValue
                    })
                end
            end
        end
    end 
end

local factions = {
    ["Mages Guild"] = true,
    ["Fighters Guild"] = true,
    ["Imperial Cult"] = true,
    ["Imperial Legion"] = true,
    ["Hlaalu"] = true,
    ["East Empire Company"] = true,
    ["T_Cyr_EastEmpireCompany"] = true,
    ["T_Cyr_FightersGuild"] = true,
    ["T_Cyr_ImperialCult"] = true,
    ["T_Cyr_ImperialLegion"] = true,
    ["T_Cyr_ImperialWatch"] = true,
    ["T_Cyr_ImperialNavy"] = true,
    ["T_Cyr_MagesGuild"] = true,
    ["T_Mw_EastEmpireCompany"] = true,
    ["T_Mw_FightersGuild"] = true,
    ["T_Mw_ImperialCult"] = true,
    ["T_Mw_ImperialLegion"] = true,
    ["T_Mw_ImperialWatch"] = true,
    ["T_Mw_ImperialNavy"] = true,
    ["T_Mw_MagesGuild"] = true,
    ["T_Mw_HouseHlaalu"] = true,
    ["T_Sky_FightersGuild"] = true,
    ["T_Sky_ImperialCult"] = true,
    ["T_Sky_ImperialLegion"] = true,
    ["T_Sky_MagesGuild"] = true,
}

local function removeLevitationFromNpcs()
    for npc in tes3.iterateObjects(tes3.objectType.npc) do
        if (npc.faction) then
            if (factions[npc.faction.id]) then
                -- Check for levitation spells
                for spell in tes3.iterate(npc.spells.iterator) do
                    for _, effect in pairs(spell.effects) do
                        if (effect.id == tes3.effect.levitate) then
                            -- Remove spell
                            npc.spells:remove(spell)
                        end
                    end
                end
            end
        end
    end
end

local function onInitialized()
	--Watch for spellcast.
    event.register("magicCasted", onCast)
    
    removeLevitationFromNpcs()

	print("[The Levitation Act: INFO] Initialized The Levitation Act")
end
event.register("initialized", onInitialized)