local TGM_FEATHER_SPELL_ID = "tgm_feather_en"
local tgmFeatherSpell = tes3.getObject(TGM_FEATHER_SPELL_ID)

local function registerFeatherSpell()
    if tgmFeatherSpell then return end
    --- @type tes3spell
    tgmFeatherSpell = tes3.createObject({
        objectType = tes3.objectType.spell,
        id = TGM_FEATHER_SPELL_ID,
        name = "Divine Feather",
        castType = tes3.spellType.curse,
        effects = {{
            id = tes3.effect.feather,
            min = 9999,
            max = 9999,
        }}
    })
end

local function updateFeatherEffect()
    local hasFeatherSpell = tes3.hasSpell({reference = tes3.player, spell = tgmFeatherSpell})
    local godmode = tes3.worldController.menuController.godModeEnabled

    if godmode and not hasFeatherSpell then
        tes3.addSpell({reference = tes3.player, spell = tgmFeatherSpell})
    elseif not godmode and hasFeatherSpell then
        tes3.removeSpell({reference = tes3.player, spell = tgmFeatherSpell})
    end
end

local function onInitialized()
    registerFeatherSpell()
    event.register(tes3.event.simulate, updateFeatherEffect)
    mwse.log("[Godmode No Encumbrance] Initialized.")
end

event.register("initialized", onInitialized)