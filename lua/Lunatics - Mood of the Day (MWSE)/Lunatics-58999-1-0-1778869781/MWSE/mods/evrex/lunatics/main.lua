-- lunatics/main.lua
-- Mod: Lunatics - Mood of the Day
-- Alters NPC disposition daily with a random mood swing

local config = mwse.loadConfig("lunatics", { moodRange = 10, moodThreshold = 5 }) -- load config with defaults

-- Reason tables for mood reflection in dialogue
local reasonsPositive = {
    "they slept well",
    "they received good news",
    "someone praised them",
    "they found something valuable",
    "they feel confident today",
    "they had a pleasant morning",
    "they completed an important task",
    "they met someone they like",
    "they feel healthy and rested",
    "something went better than expected"
}
local reasonsNegative = {
    "they slept poorly",
    "they received bad news",
    "someone upset them",
    "they lost something important",
    "they feel unwell today",
    "they had a rough morning",
    "they argued with someone",
    "they feel stressed and distracted",
    "something went wrong earlier",
    "they are worried about something"
}

local npcMoods = {} -- stores mood value per NPC reference id
local currentDay = nil -- tracks the current in-game days passed
local moodTimer = nil -- reference to the mood timer

local function applyMoodToCell()
    local cell = tes3.getPlayerCell() -- get the cell the player is currently in
    if not cell then return end -- safety check
    currentDay = tes3.worldController.daysPassed.value -- update current day
    for ref in cell:iterateReferences(tes3.objectType.npc) do -- iterate only NPCs
        local mobile = ref.mobile -- get the mobile object
        if mobile then
            local existing = npcMoods[ref.id] -- check if mood already applied today
            if not existing or existing.day ~= currentDay then -- apply only if not processed today
                local mood = math.random(-tonumber(config.moodRange), tonumber(config.moodRange)) -- random mood swing
                tes3.modDisposition({ reference = ref, value = mood }) -- apply mood swing
                local reason
                if mood > tonumber(config.moodThreshold) then
                    reason = reasonsPositive[math.random(#reasonsPositive)] -- pick reason once per day
                elseif mood < -tonumber(config.moodThreshold) then
                    reason = reasonsNegative[math.random(#reasonsNegative)] -- pick reason once per day
                end
                npcMoods[ref.id] = { mood = mood, reason = reason, day = currentDay } -- store mood, reason and day
            end
        end
    end
    tes3.player.data.lunatics.npcMoods = npcMoods -- save moods to persistent storage
    tes3.player.data.lunatics.currentDay = currentDay -- save current day to persistent storage
end

local function onCellChanged()
    local newDay = tes3.worldController.daysPassed.value -- get current days passed
    if newDay ~= currentDay then -- check if the day has changed
        currentDay = newDay -- update tracked day
    end
    applyMoodToCell() -- always apply mood on cell change
end

local function onLoaded()
    currentDay = tes3.worldController.daysPassed.value -- store days passed on load
    tes3.player.data.lunatics = tes3.player.data.lunatics or {} -- initialize persistent storage
    if tes3.player.data.lunatics.npcMoods then
        npcMoods = tes3.player.data.lunatics.npcMoods -- restore saved moods
    end
    if tes3.player.data.lunatics.currentDay then
        currentDay = tes3.player.data.lunatics.currentDay -- restore saved day
    end
    if moodTimer then moodTimer:cancel() end -- cancel existing timer if any
		moodTimer = timer.start({ duration = 24, type = timer.game, iterations = -1, callback = applyMoodToCell }) -- apply mood every 24 in-game hours
    applyMoodToCell() -- apply mood immediately on load
end

local function onMenuDialog(e)
    if not e.newlyCreated then return end -- only act when menu is freshly created
    local target = tes3.getPlayerTarget() -- get the NPC the player is talking to
    if not target then return end -- safety check
    local data = npcMoods[target.id] -- get stored mood data for this NPC
    if not data or not data.reason then return end -- no mood stored, skip
    local name = target.object.name or "They" -- get NPC name
    local reflection
    if data.mood >= tonumber(config.moodThreshold) then
        reflection = name .. " seems to be in a good mood today, probably because " .. data.reason .. "."
    elseif data.mood <= -tonumber(config.moodThreshold) then
        reflection = name .. " seems to be in a bad mood today, probably because " .. data.reason .. "."
    else
        return -- mood within threshold, no reflection
    end
    timer.frame.delayOneFrame(function()
        tes3ui.showDialogueMessage({ text = reflection, style = 1 }) -- show reflection in white
    end)
end

event.register("uiActivated", onMenuDialog, { filter = "MenuDialog" })

local function registerModConfig()
    local template = mwse.mcm.createTemplate{
	name = "Lunatics - Mood of the Day",
	headerImagePath = "MWSE/mods/evrex/lunatics/lunatics.tga"
	}
	
    template:saveOnClose("lunatics", config)
    template:register()
    local page = template:createSideBarPage({ label = "Settings" })
    page.sidebar:createInfo({ text = "Lunatics - Mood of the Day simulates the daily mood of NPCs by subtly altering their disposition each day. Every NPC may feel a little better or worse depending on how their day is going." })
    local category = page:createCategory({ label = "Mood Settings" })
    category:createTextField({
        label = "Mood Range",
        description = "Maximum disposition change per day (default: 10).",
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable({ id = "moodRange", table = config }),
    })
    category:createTextField({
        label = "Mood Reaction Threshold",
        description = "Minimum mood swing value to show a reaction message in dialogue (default: 5).\nIf this value exceeds Mood Range, reaction messages will never appear.",
        numbersOnly = true,
        variable = mwse.mcm.createTableVariable({ id = "moodThreshold", table = config }),
    })
end

event.register("cellChanged", onCellChanged) -- register cell change event
event.register("modConfigReady", registerModConfig)
event.register("loaded", onLoaded)