local tempAddedSpells = {}
local originalPlayerSpells = {}
local npcKnownSpells = {}

local defaultConfig = {
    addAllSpells = true,
    enableLogging = true,
    modEnabled = true,  -- New setting to enable/disable the mod
}

local config = mwse.loadConfig("SpellEffect", defaultConfig)

-- Logging helper
local function log(fmt, ...)
    if config.enableLogging then
        mwse.log(fmt, ...)
    end
end

-- Function to record player's current spells
local function recordPlayerSpells()
    if not config.modEnabled then return end
    log("[SpellEffect] Recording player's current spells...")
    originalPlayerSpells = {}

    local spells = tes3.getSpells{ target = tes3.player, spellType = 0 }
    for _, spell in pairs(spells) do
        originalPlayerSpells[spell.id:lower()] = true
        log("[SpellEffect] Found original spell: %s", spell.id)
    end
end

-- Function to record NPC's known spells
local function recordNpcSpells(actor)
    if not config.modEnabled then return end
    log("[SpellEffect] Recording NPC's known spells...")

    npcKnownSpells = {}

    local spells = tes3.getSpells{ target = actor, spellType = 0 }
    for _, spell in pairs(spells) do
        npcKnownSpells[spell.id:lower()] = true
        log("[SpellEffect] NPC knows spell: %s", spell.id)
    end

    if not next(npcKnownSpells) then
        log("[SpellEffect] NPC has no known spells.")
    end
end

-- Add only spells that introduce at least one new effect
local function addAllSpellsToPlayer()
    if not config.modEnabled then return end
    log("[SpellEffect] Adding spells to player...")

    if config.addAllSpells then
        log("[SpellEffect] Adding all available spells...")

        tempAddedSpells = {}
        local knownEffects = {}

        for _, spell in pairs(tes3.getSpells{ target = tes3.player, spellType = 0 }) do
            for _, effect in ipairs(spell.effects) do
                if effect.id then
                    knownEffects[effect.id] = true
                end
            end
        end

        for _, spell in ipairs(tes3.dataHandler.nonDynamicData.spells) do
            if spell.castType == tes3.spellType.spell then
                local spellId = spell.id:lower()
                if not originalPlayerSpells[spellId] then
                    local addsNewEffect = false
                    for _, effect in ipairs(spell.effects) do
                        if effect.id and not knownEffects[effect.id] then
                            addsNewEffect = true
                            break
                        end
                    end

                    if addsNewEffect then
                        tes3.addSpell({ reference = tes3.player, spell = spell.id })
                        table.insert(tempAddedSpells, spellId)
                        log("[SpellEffect] Added new-effect spell: %s", spellId)

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
        log("[SpellEffect] Adding spells from NPC...")

        tempAddedSpells = {}
        local actor = tes3ui.getServiceActor()
        if actor then
            recordNpcSpells(actor)

            for _, spell in ipairs(tes3.dataHandler.nonDynamicData.spells) do
                if spell.castType == tes3.spellType.spell and not originalPlayerSpells[spell.id:lower()] and npcKnownSpells[spell.id:lower()] then
                    tes3.addSpell({ reference = tes3.player, spell = spell.id })
                    table.insert(tempAddedSpells, spell.id:lower())
                    log("[SpellEffect] Added NPC-known spell: %s", spell.id)
                end
            end
        end
    end
end

-- Function to remove all temporary spells from the player
local function removeTempSpellsFromPlayer()
    if not config.modEnabled then return end
    log("[SpellEffect] Removing temporary spells...")
    for _, spellId in pairs(tempAddedSpells) do
        tes3.removeSpell({ reference = tes3.player, spell = spellId })
        log("[SpellEffect] Removed spell: %s", spellId)
    end
    tempAddedSpells = {}
end

-- Event: When dialogue menu opens
event.register("uiActivated", function(e)
    if not config.modEnabled then return end
    if e.element.name == "MenuDialog" then
        local actor = tes3ui.getServiceActor()
        if actor and (
            tes3.checkMerchantOffersService{ reference = actor.reference, service = tes3.merchantService.spellmaking } or
            tes3.checkMerchantOffersService{ reference = actor.reference, service = tes3.merchantService.enchanting }
        ) then
            log("[SpellEffect] Dialogue with service NPC started, recording spells.")
            recordPlayerSpells()
            addAllSpellsToPlayer()

            -- Register cleanup
            e.element:registerAfter("destroy", function()
                log("[SpellEffect] MenuDialog closed. Cleaning up temporary spells.")
                removeTempSpellsFromPlayer()
            end)
        end
    end
end)

-- Register MCM menu
local function addMCMMenu()
    local template = mwse.mcm.createTemplate("SpellEffect")
    template:saveOnClose("SpellEffect", config)

    local page = template:createPage()
    
    page:createYesNoButton({
        label = "Add All Spells?",
        description = "If enabled, all spells will be added. Otherwise, only spells that the NPC knows will be added.",
        variable = mwse.mcm.createTableVariable{
            id = "addAllSpells",
            table = config
        }
    })

    page:createYesNoButton({
        label = "Enable Logging",
        description = "Enable or disable MWSE logging for this mod.",
        variable = mwse.mcm.createTableVariable{
            id = "enableLogging",
            table = config
        }
    })

    page:createYesNoButton({
        label = "Enable Mod",
        description = "Enable or disable this mod. Disabling will stop all features of the mod.",
        variable = mwse.mcm.createTableVariable{
            id = "modEnabled",
            table = config
        }
    })

    mwse.mcm.register(template)
end

event.register("modConfigReady", addMCMMenu)

-- Initialization
event.register("initialized", function()
    log("[SpellEffect] Mod initialized.")
end)
