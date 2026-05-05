local storage = require("openmw.storage")
local core    = require("openmw.core")
local async   = require("openmw.async")
local shared  = require("scripts.ldttu_shared")
local DEFAULTS = shared.DEFAULTS

local section_main   = storage.playerSection("SettingsLDTTU")
local section_ghosts = storage.playerSection("SettingsLDTTU_Ghosts")
local section_phys   = storage.playerSection("SettingsLDTTU_Physical")

local function refresh()
    local s = {
        MOD_ENABLED          = section_main:get("MOD_ENABLED"),
        DEBUG_LOGGING        = section_main:get("DEBUG_LOGGING"),
        
        GHOST_BLADE_MULT     = section_ghosts:get("GHOST_BLADE_MULT"),
        GHOST_HEAVY_MULT     = section_ghosts:get("GHOST_HEAVY_MULT"),
        GHOST_MARKSMAN_MULT  = section_ghosts:get("GHOST_MARKSMAN_MULT"),
        GHOST_H2H_MULT       = section_ghosts:get("GHOST_H2H_MULT"),
        
        PHYS_BLUNT_AXE_MULT  = section_phys:get("PHYS_BLUNT_AXE_MULT"),
        PHYS_BLADE_MULT      = section_phys:get("PHYS_BLADE_MULT"),
        PHYS_SPEAR_MULT      = section_phys:get("PHYS_SPEAR_MULT"),
        PHYS_MARKSMAN_MULT   = section_phys:get("PHYS_MARKSMAN_MULT"),
        PHYS_H2H_MULT        = section_phys:get("PHYS_H2H_MULT"),
    }
    core.sendGlobalEvent("LDTTU_GlobalSettings", s)
end

section_main:subscribe(async:callback(refresh))
section_ghosts:subscribe(async:callback(refresh))
section_phys:subscribe(async:callback(refresh))

return {
    engineHandlers = {
        onInit = refresh,
        onLoad = refresh
    }
}