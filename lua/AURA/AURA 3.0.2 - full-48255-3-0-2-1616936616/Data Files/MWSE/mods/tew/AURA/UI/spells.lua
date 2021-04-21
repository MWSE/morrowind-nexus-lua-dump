local modversion = require("tew\\AURA\\version")
local version = modversion.version
local config = require("tew\\AURA\\config")
local UIvol=config.UIvol/200
local debugLogOn=config.debugLogOn

local function debugLog(string)
    if debugLogOn then
       mwse.log("[AURA "..version.."] UI: "..string)
    end
 end

local function onSpellClick(e)

    local element=e.element:findChild(-1155)

    for _, spellClick in pairs(element.children) do
        if string.find(spellClick.text, "gp") then
            spellClick:register("mouseDown", function()
            tes3.playSound{sound="sprigganmagic", volume=0.7*UIvol, pitch=1.2}
            debugLog("Purchase spell sound played.")
            end)
        end
    end

end

--[[local function onSpellMenu(e)
    local function spellScroll()
        tes3.playSound{sound="scroll", volume=0.6}
        debugLog("Opening spell menu sound played.")
    end

    local element=e.element
    local spellsButton=element:findChild(tes3ui.registerID("MenuDialog_service_spells"))

    spellsButton:register("mouseDown", spellScroll)
end--]]


print("[AURA "..version.."] UI: Spell purchase sounds initialised.")
event.register("uiActivated", onSpellClick, {filter="MenuServiceSpells", priority=-15})
--event.register("uiActivated", onSpellMenu, {filter="MenuDialog", priority=-15})