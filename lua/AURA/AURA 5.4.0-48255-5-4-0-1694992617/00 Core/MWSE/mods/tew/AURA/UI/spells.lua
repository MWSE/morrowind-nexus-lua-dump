local metadata = toml.loadMetadata("AURA")
local version = metadata.package.version
local config = require("tew.AURA.config")
local UIvol = config.volumes.misc.UIvol / 100
local common = require("tew.AURA.common")

local debugLog = common.debugLog

-- Play gold and magic sound on purchasing spells --
local function onSpellClick(e)
    local element=e.element:findChild("MenuServiceSpells_Spells")
    if not element then return end
    for _, spellClick in pairs(element.children) do
        if string.find(spellClick.text, "gp") then
            spellClick:registerAfter("mouseDown", function()
                tes3.playSound{sound="sprigganmagic", volume=0.2*UIvol, pitch=1.7}
                debugLog("Purchase spell sound played.")
            end)
        end
    end
end

-- Play scroll on opening the menu --
local function onSpellMenu(e)
    local function spellScroll()
        tes3.playSound{sound="scroll", volume=0.5}
        debugLog("Opening spell menu sound played.")
    end

    local element=e.element
    local spellsButton=element:findChild(tes3ui.registerID("MenuDialog_service_spells"))

    spellsButton:registerAfter("mouseDown", spellScroll)
end


print("[AURA "..version.."] UI: Spell purchase sounds initialised.")
event.register("uiActivated", onSpellClick, {filter="MenuServiceSpells", priority=-15})
event.register("uiActivated", onSpellMenu, {filter="MenuDialog", priority=-15})