local mod = "One Life to Live"
local version = "1.0.1"

local config = require("OneLifeToLive.config")

local savedData, oldDeathMessage
local newDeathMessage = "This character has died the final death. Would you like to start a new game?"

-- Logs debug messages if debug mode is enabled.
local function debug(message)
    if not config.debugMode then
        return
    end

    mwse.log("[" .. mod .. " " .. version .. "] " .. message)
end

-- Creates a tooltip for our new level display in the stat menu.
local function menuLivesTooltip()
    debug("menuLivesTooltip: Function called. Creating tooltip for lives display.")
    local livesTooltip = tes3ui:createTooltipMenu()

    -- Create a block for text, with padding on the sides, and automatically set height/width.
    local tooltipBlock = livesTooltip:createBlock()
    tooltipBlock.flowDirection = "top_to_bottom"
    tooltipBlock.paddingTop = 6
    tooltipBlock.paddingBottom = 6
    tooltipBlock.paddingLeft = 6
    tooltipBlock.paddingRight = 6
    tooltipBlock.autoHeight = true
    tooltipBlock.autoWidth = true

    -- Create the tooltip text.
    local livesDescription = tooltipBlock:createLabel{ text = "The number of lives you have remaining." }
    livesDescription.autoHeight = true
    livesDescription.autoWidth = true
    livesDescription.wrapText = true

    -- Make the tooltip actually display our text.
    livesTooltip:updateLayout()
end

-- Runs when the stat menu is created (on game load) or unhidden.
local function menuLivesDisplay(e)
    debug("menuLivesDisplay: Stat menu created.")
    savedData = tes3.player.data.OneLifeToLive

    -- Permadeath is not enabled for this character, so do nothing.
    if not savedData then
        debug("menuLivesDisplay: Permadeath is not enabled for this character.")
        return
    end

    -- The player must have deleted this character's ID from the config table, so do nothing.
    if not config.registeredCharacters[savedData.id] then
        debug(string.format("menuLivesDisplay: Character %s: Permadeath should be enabled for this character, but the character's ID is not present in the config table.", savedData.id))
        return
    end

    -- The stat menu is just being unhidden, so do nothing. (Otherwise it would create a duplicate element.)
    if not e.newlyCreated then
        debug("menuLivesDisplay: Stat menu is not newly created, so doing nothing.")
        return
    end

    debug("menuLivesDisplay: Stat menu is newly created. Creating lives display element.")

    -- Find the block that shows level/race/class (the unnamed parent of the level display).
    local statMenu = e.element
    local charBlock = statMenu:findChild(tes3ui.registerID("MenuStat_level_layout")).parent

    -- Create a new element at the bottom of this block.
    local livesBlock = charBlock:createBlock()
    livesBlock.widthProportional = 1.0
    livesBlock.autoHeight = true

    -- Create a label to display the "Lives" text.
    local livesLabel = livesBlock:createLabel{ text = "Lives" }
    livesLabel.color = tes3ui.getPalette("header_color")

    -- Create another new element to display the number of lives remaining.
    local livesRemainingBlock = livesBlock:createBlock()
    livesRemainingBlock.widthProportional = 1.0
    livesRemainingBlock.autoHeight = true

    -- Display the number of lives remaining. tostring() is needed because the text can only be a string.
    local livesRemaining = config.registeredCharacters[savedData.id].lives - config.registeredCharacters[savedData.id].deaths
    local livesRemainingLabel = livesRemainingBlock:createLabel{ text = tostring(livesRemaining) }
    livesRemainingLabel.wrapText = true
    livesRemainingLabel.widthProportional = 1
    livesRemainingLabel.justifyText = "right"

    -- Create a tooltip when hovering over the new element.
    livesLabel:register("help", menuLivesTooltip)
    livesRemainingBlock:register("help", menuLivesTooltip)
    livesRemainingLabel:register("help", menuLivesTooltip)

    -- Make the menu actually display the new element.
    statMenu:updateLayout()
end

local function displayMessage(newGame)
    debug("displayMessage: Function called.")

    -- If mod is not configured to display messages, then do nothing.
    if not config.displayMessages then
        debug("displayMessage: Mod is not configured to display messages.")
        return
    end

    -- This function has been called from onLoaded on a new game.
    if newGame then
        debug(string.format("displayMessage: New game detected. This character has %d lives.", config.livesForNew))

        if config.livesForNew == 1 then
            tes3.messageBox("Permadeath enabled. This character has but one life to live.")
        else
            tes3.messageBox("Permadeath enabled. This character has %d lives.", config.livesForNew)
        end

    -- This function has been called on loading a savegame, or when the player dies and has lives remaining.
    else
        local livesRemaining = config.registeredCharacters[savedData.id].lives - config.registeredCharacters[savedData.id].deaths
        debug(string.format("displayMessage: Game in progress detected. This character has %d lives remaining.", livesRemaining))

        if livesRemaining == 1 then
            tes3.messageBox("This character has but one life remaining.")
        else
            tes3.messageBox("This character has %d lives remaining.", livesRemaining)
        end
    end
end

-- Runs each time a messagebox is displayed.
local function onDeathMessage(e)
    debug("onDeathMessage: Messagebox displayed.")

    -- Define the relevant elements of the messagebox.
    local deathMessage = e.element:findChild(tes3ui.registerID("MenuMessage_message"))
    local deathButtons = e.element:findChild(tes3ui.registerID("MenuMessage_button_layout"))

    -- Sanity check.
    if not ( deathMessage and deathButtons ) then
        debug("onDeathMessage: Messagebox layout sanity check failed.")
        return
    end

    -- If this messagebox is not the one displayed on player death, we don't care, do nothing.
    -- If it is, but the message hasn't been changed by this mod due to permadeath, we don't care, do nothing.
    if deathMessage.text ~= newDeathMessage then
        debug("onDeathMessage: This messagebox is not the final death message.")
        return
    end

    debug("onDeathMessage: This messagebox is the final death message. Clicking Yes should start a new game.")

    -- Make the "yes" button start a new game, in line with the new permadeath message text.
    deathButtons.children[1]:register("mouseClick", tes3.newGame)
end

-- Runs each time any actor (player, NPCs, creatures) takes damage.
-- The death event can't be used for this because it doesn't trigger until the death messagebox appears, which we might need to modify.
local function onDamaged(e)
    debug("onDamaged: Actor damaged.")

    -- If it's not the player being damaged, we don't care, do nothing.
    if e.mobile ~= tes3.mobilePlayer then
        debug("onDamaged: Actor damaged is not the player.")
        return
    end

    -- Permadeath is not enabled for this character, so we don't care, do nothing.
    if not savedData then
        debug("onDamaged: Actor damaged is the player, but permadeath is not enabled for this character.")
        return
    end

    -- The player must have deleted this character's ID from the config table, so do nothing.
    if not config.registeredCharacters[savedData.id] then
        debug(string.format("onDamaged: Character %s: Actor damaged is the player, and permadeath should be enabled for this character, but the character's ID is not present in the config table.", savedData.id))
        return
    end

    -- The player isn't dead yet, so do nothing.
    if tes3.mobilePlayer.health.current > 0 then
        debug(string.format("onDamaged: Character %s: Player damaged, but not killed. Remaining health: %f", savedData.id, tes3.mobilePlayer.health.current))
        return
    end

    debug(string.format("onDamaged: Character %s: Player has been killed.", savedData.id))

    -- Look up data for this character from the config table.
    local currentLives = config.registeredCharacters[savedData.id].lives
    local currentDeaths = config.registeredCharacters[savedData.id].deaths

    -- Increment the death count for this character and save it in the config table.
    currentDeaths = currentDeaths + 1
    config.registeredCharacters[savedData.id].deaths = currentDeaths
    mwse.saveConfig("OneLifeToLive", config)

    debug(string.format("onDamaged: Character %s: Total lives: %d", savedData.id, currentLives))
    debug(string.format("onDamaged: Character %s: Current deaths: %d", savedData.id, currentDeaths))

    -- This character has now permadied, so change the message that appears on death.
    if currentDeaths >= currentLives then
        debug(string.format("onDamaged: Character %s: This character is permadead.", savedData.id))
        tes3.findGMST("sLoadLastSaveMsg").value = newDeathMessage

    -- This character still has lives remaining.
    else
        debug(string.format("onDamaged: Character %s: This character has %d lives remaining.", savedData.id, currentLives - currentDeaths))
        displayMessage(false)
    end
end

-- Runs each time a game is loaded. The load event can't be used for this because the player data isn't accessible yet.
local function onLoaded(e)
    debug("onLoaded: Game loaded.")

    -- Return to the regular death message if the last character just permadied.
    tes3.findGMST("sLoadLastSaveMsg").value = oldDeathMessage

    if e.newGame then
        debug("onLoaded: New game detected.")

        -- If mod is configured to not use permadeath, do nothing.
        if not config.enabledForNew then
            debug("onLoaded: Permadeath is not enabled for new characters.")
            return
        end

        debug("onLoaded: Permadeath will be enabled for this character.")

        -- Create a block of persistent data in the savegame to store this character's unique ID.
        tes3.player.data.OneLifeToLive = {}
        savedData = tes3.player.data.OneLifeToLive

        -- Create a unique ID for this character using the current time.
        -- tostring() is needed because it will be saved as a string in the config table, and we need to compare them.
        savedData.id = tostring(os.time())

        debug(string.format("onLoaded: Character's unique ID: %s", savedData.id))

        -- Create and save a new entry in the config table for this character.
        config.registeredCharacters[savedData.id] = {
            lives = config.livesForNew,
            deaths = 0,
        }

        debug(string.format("onLoaded: Character %s: This character has %d lives.", savedData.id, config.registeredCharacters[savedData.id].lives))

        mwse.saveConfig("OneLifeToLive", config)

        displayMessage(true)

    -- Player loaded a savegame.
    else
        debug("onLoaded: Game in progress detected.")

        savedData = tes3.player.data.OneLifeToLive

        -- If this character doesn't have an ID saved in the savegame, permadeath is not enabled, do nothing.
        if not savedData then
            debug("onLoaded: Permadeath is not enabled for this character.")
            return
        end

        -- If this character's ID is not in the config table, the player must have deleted it. Do nothing.
        if not config.registeredCharacters[savedData.id] then
            debug(string.format("onLoaded: Character %s: Permadeath should be enabled for this character, but the character's ID is not present in the config table.", savedData.id))
            return
        end

        -- The player is trying to load a save for a character that has already permadied.
        if config.registeredCharacters[savedData.id].deaths >= config.registeredCharacters[savedData.id].lives then
            debug(string.format("onLoaded: Character %s: This character is permadead.", savedData.id))

            -- Kill the player.
            tes3.setStatistic{
                reference=tes3.player,
                name='health',
                current=0
            }

            -- Let the player know this character is permadead, and offer them the chance to start a new game.
            tes3.findGMST("sLoadLastSaveMsg").value = newDeathMessage

        -- This character has lives remaining.
        else
            debug(string.format("onLoaded: Character %s: This character has %d lives remaining.", savedData.id, config.registeredCharacters[savedData.id].lives - config.registeredCharacters[savedData.id].deaths))
            displayMessage(false)
        end
    end
end

local function onInitialized()
    event.register("loaded", onLoaded)
    event.register("damaged", onDamaged)
    event.register("uiActivated", onDeathMessage, { filter = "MenuMessage" })
    event.register("uiActivated", menuLivesDisplay, { filter = "MenuStat" })

    -- Get this here because it's guaranteed not to have been changed by this mod yet.
    oldDeathMessage = tes3.findGMST("sLoadLastSaveMsg").value

    mwse.log("[" .. mod .. " " .. version .. "] Initialized.")
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\OneLifeToLive\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)