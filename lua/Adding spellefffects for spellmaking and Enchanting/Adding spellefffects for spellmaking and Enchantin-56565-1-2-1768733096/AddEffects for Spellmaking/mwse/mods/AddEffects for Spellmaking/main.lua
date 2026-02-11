-- SpellEffect: Temp spells only for Spellmaking/Enchanting, without breaking spell vendors.
-- Works even if spellmaking/enchanting is launched from MenuDialog without menuEnter events.

local tempAddedSpells = {}
local originalPlayerSpells = {}
local npcKnownSpells = {}

local defaultConfig = {
    addAllSpells = true,     -- true: add spells that introduce new effect types; false: add only NPC-known spells
    enableLogging = true,
    modEnabled = true,
    maxTempSpells = 60,      -- 0 = unlimited (not recommended)
}

local config = mwse.loadConfig("SpellEffect", defaultConfig)

local function log(fmt, ...)
    if config.enableLogging then
        mwse.log(fmt, ...)
    end
end

local function reachedCap()
    return (config.maxTempSpells and config.maxTempSpells > 0 and #tempAddedSpells >= config.maxTempSpells)
end

local function recordPlayerSpells()
    originalPlayerSpells = {}
    local spells = tes3.getSpells{ target = tes3.player, spellType = tes3.spellType.spell }
    for _, spell in pairs(spells) do
        originalPlayerSpells[spell.id:lower()] = true
    end
end

local function recordNpcSpells(actor)
    npcKnownSpells = {}
    local spells = tes3.getSpells{ target = actor, spellType = tes3.spellType.spell }
    for _, spell in pairs(spells) do
        npcKnownSpells[spell.id:lower()] = true
    end
end

-- Cleanup must ALWAYS work (never gate by modEnabled)
local function removeTempSpellsFromPlayer()
    if #tempAddedSpells == 0 then return end
    log("[SpellEffect] Removing temporary spells (%d)...", #tempAddedSpells)
    for _, spellId in ipairs(tempAddedSpells) do
        tes3.removeSpell({ reference = tes3.player, spell = spellId })
    end
    tempAddedSpells = {}
end

local function addTempSpellsForService()
    if not config.modEnabled then
        log("[SpellEffect] Mod disabled; not adding temp spells.")
        return
    end

    tempAddedSpells = {}

    if config.addAllSpells then
        log("[SpellEffect] Adding temp spells (new-effect-only)...")

        local knownEffects = {}
        for _, spell in pairs(tes3.getSpells{ target = tes3.player, spellType = tes3.spellType.spell }) do
            for _, effect in ipairs(spell.effects) do
                if effect.id then
                    knownEffects[effect.id] = true
                end
            end
        end

        for _, spell in ipairs(tes3.dataHandler.nonDynamicData.spells) do
            if reachedCap() then
                log("[SpellEffect] Reached maxTempSpells cap (%d).", config.maxTempSpells)
                break
            end

            if spell.castType == tes3.spellType.spell then
                local idLower = spell.id:lower()
                if not originalPlayerSpells[idLower] then
                    local addsNewEffect = false
                    for _, effect in ipairs(spell.effects) do
                        if effect.id and not knownEffects[effect.id] then
                            addsNewEffect = true
                            break
                        end
                    end

                    if addsNewEffect then
                        tes3.addSpell({ reference = tes3.player, spell = spell.id })
                        table.insert(tempAddedSpells, spell.id) -- store original ID
                        for _, effect in ipairs(spell.effects) do
                            if effect.id then
                                knownEffects[effect.id] = true
                            end
                        end
                    end
                end
            end
        end

    else
        log("[SpellEffect] Adding temp spells (NPC-known)...")
        local actor = tes3ui.getServiceActor()
        if not actor then
            log("[SpellEffect] No service actor found.")
            return
        end

        recordNpcSpells(actor)

        for _, spell in ipairs(tes3.dataHandler.nonDynamicData.spells) do
            if reachedCap() then
                log("[SpellEffect] Reached maxTempSpells cap (%d).", config.maxTempSpells)
                break
            end

            if spell.castType == tes3.spellType.spell then
                local idLower = spell.id:lower()
                if npcKnownSpells[idLower] and not originalPlayerSpells[idLower] then
                    tes3.addSpell({ reference = tes3.player, spell = spell.id })
                    table.insert(tempAddedSpells, spell.id)
                end
            end
        end
    end

    log("[SpellEffect] Temporary spells added: %d", #tempAddedSpells)
end

-- Utility: find service button by common IDs (vanilla/UI-expansion friendly)
local function findServiceButton(menuDialog, idStr)
    local id = tes3ui.registerID(idStr)
    return menuDialog:findChild(id)
end

local function hookServiceButtons(menuDialog)
    -- Common vanilla IDs (also used by many UI mods)
    local btnSpellmaking = findServiceButton(menuDialog, "MenuDialog_service_spellmaking")
    local btnEnchanting  = findServiceButton(menuDialog, "MenuDialog_service_enchanting")
        or findServiceButton(menuDialog, "MenuDialog_service_enchant")
    local btnSpellsBuy   = findServiceButton(menuDialog, "MenuDialog_service_spells")

    -- If your UI mod uses different IDs, you can add them here once you know them.
    if not btnSpellmaking then log("[SpellEffect] WARN: Spellmaking service button not found.") end
    if not btnEnchanting then log("[SpellEffect] WARN: Enchanting service button not found.") end
    if not btnSpellsBuy then log("[SpellEffect] WARN: Spells-for-sale service button not found.") end

    -- IMPORTANT: use registerBefore so we run BEFORE the menu/service is opened & lists are built
    if btnSpellmaking then
        btnSpellmaking:registerBefore("mouseClick", function()
            log("[SpellEffect] Spellmaking clicked -> add temp spells BEFORE opening.")
            removeTempSpellsFromPlayer()
            recordPlayerSpells()
            addTempSpellsForService()
        end)
    end

    if btnEnchanting then
        btnEnchanting:registerBefore("mouseClick", function()
            log("[SpellEffect] Enchanting clicked -> add temp spells BEFORE opening.")
            removeTempSpellsFromPlayer()
            recordPlayerSpells()
            addTempSpellsForService()
        end)
    end

    -- Critical: when buying spells, ensure temp spells are NOT present, otherwise vendor list can become empty.
    if btnSpellsBuy then
        btnSpellsBuy:registerBefore("mouseClick", function()
            log("[SpellEffect] Spells-for-sale clicked -> remove temp spells BEFORE opening.")
            removeTempSpellsFromPlayer()
        end)
    end
end

-- Main: MenuDialog opened
event.register("uiActivated", function(e)
    if e.element.name ~= "MenuDialog" then return end
    if e.newlyCreated == false then return end
    if not config.modEnabled then return end

    local actor = tes3ui.getServiceActor()
    if not actor then return end

    local offersSpellmaking = tes3.checkMerchantOffersService{
        reference = actor.reference,
        service = tes3.merchantService.spellmaking
    }

    local offersEnchanting = tes3.checkMerchantOffersService{
        reference = actor.reference,
        service = tes3.merchantService.enchanting
    }

    if offersSpellmaking or offersEnchanting then
        log("[SpellEffect] MenuDialog opened with spellmaking/enchanting NPC. Recording baseline.")
        recordPlayerSpells()

        -- Hook buttons inside MenuDialog so we can add/remove at the correct moment.
        hookServiceButtons(e.element)

        -- Always cleanup when dialog closes (never gated by modEnabled)
        e.element:registerAfter("destroy", function()
            log("[SpellEffect] MenuDialog closed. Cleaning up temp spells.")
            removeTempSpellsFromPlayer()
        end)
    end
end)

-- MCM
local function addMCMMenu()
    local template = mwse.mcm.createTemplate("SpellEffect")
    template:saveOnClose("SpellEffect", config)

    local page = template:createPage()

    page:createYesNoButton({
        label = "Add All Spells?",
        description = "If enabled, temporarily adds spells that introduce new effect types for Spellmaking/Enchanting. Otherwise, adds only spells the NPC knows.",
        variable = mwse.mcm.createTableVariable{ id = "addAllSpells", table = config }
    })

    page:createYesNoButton({
        label = "Enable Logging",
        description = "Enable or disable MWSE logging for this mod.",
        variable = mwse.mcm.createTableVariable{ id = "enableLogging", table = config }
    })

    page:createYesNoButton({
        label = "Enable Mod",
        description = "Enable or disable this mod.",
        variable = mwse.mcm.createTableVariable{ id = "modEnabled", table = config }
    })

    page:createSlider({
        label = "Max Temporary Spells",
        description = "Safety limit for how many spells can be temporarily added. 0 = unlimited (not recommended).",
        min = 0,
        max = 300,
        step = 5,
        jump = 25,
        variable = mwse.mcm.createTableVariable{ id = "maxTempSpells", table = config }
    })

    mwse.mcm.register(template)
end

event.register("modConfigReady", addMCMMenu)

event.register("initialized", function()
    log("[SpellEffect] Mod initialized.")
end)
