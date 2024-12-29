-- https://www.nexusmods.com/morrowind/mods/55629

local isDebugOn = false

local g_trainerCurrent
local g_trainerCurrentMobile
local g_trainerCurrentId
local g_trainingIterations
local g_pcSkillProgressRequirement = {}

local tierLabels = {
  [1] = 'modest',
  [2] = 'interesting',
  [3] = 'meaningful',
  [4] = 'significant',
  [5] = 'legendary'
}

local function log(...)
  if not isDebugOn then
    return
  end

  local filteredArgs = {}
  for i = 1, select('#', ...) do
    local v = select(i, ...)

    if v == nil then
      v = 'NIL!'
    end

    table.insert(filteredArgs, tostring(v))
  end

  mwse.log(table.unpack(filteredArgs))
end

--- skills[1] = alternative for tes3.getSkillName(1)
--- { unarmored: 1 } -> { 1: 'unarmored' }
local function invertTable(tbl)
  local inverted = {}
  for key, value in pairs(tbl) do
    inverted[value] = key
  end
  return inverted
end
local skills = invertTable(tes3.skill)

--- Rounds to nearest integer
--- with .5 rounded down
function roundHalfDown(value)
  if value % 1 == 0.5 then
    return math.floor(value)
  else
    return math.floor(value + 0.5)
  end
end

--- Expects trainerSkillValue 1-100
--- Returns trainerTier 1-5
local function getTrainerTier(trainerSkillValue)
  local trainerTier
  if trainerSkillValue < 20 then
    -- skill value 1-30
    trainerTier = 1
  else
    -- skill 31-100 = tier 2-5 (master trainer = 5)
    trainerTier = roundHalfDown(trainerSkillValue / 20)
  end
  return trainerTier
end

-- Restores trainer's original skill value.
-- When training window is opened
-- and training for that NPC's skill disabled, 
-- trainer's skill value is set to 1 temporarily,
-- but should return to its original value later.
local function restoreTrainerSkills()
  if not tes3.player.data.trainedAt then
    return
  end
  if not tes3.player.data.trainedAt[g_trainerCurrentId] then
    return
  end

  log('[TRU] Restoring trainer\'s skills.')
  for skillId, skillValue in pairs(tes3.player.data.trainedAt[g_trainerCurrentId]) do
    log('[TRU] skillId: %s (%s), skillValue: %s', skillId, skills[skillId], skillValue)
    tes3.setStatistic({ reference = tes3.getReference(g_trainerCurrentId), skill = skillId, value = skillValue })
  end
end

--- Patch for Right Click Menu Exit: without it closing windows with right-click doesn't trigger corresponding events
local function onMouseButtonDown(e)
  if tes3ui.menuMode() then
    if e.button == tes3.worldController.inputController.inputMaps[19].code then
      local menuOnTop = tes3ui.getMenuOnTop()
      if tostring(menuOnTop) == 'MenuServiceTraining' then
        restoreTrainerSkills()
      end
    end
  end
end
event.register('mouseButtonDown', onMouseButtonDown)

--- Triggers hiding NPC's selected skills when training window is opened
--- and restoring those skills when dialogue/training window is closed
--- @param e uiEventEventData
local function uiEventCallback(e)
  log('parent %s, property %s, source %s', e.parent, e.property, e.source)
  local mouseDown = 4294934580 -- mouseDown, on mouseClick parent and source is nil

  local closeButtons = {
    UIEXP_MenuTraining_Cancel = true,
    MenuDialog_button_bye = true
  }

  if (e.property == mouseDown) and closeButtons[tostring(e.parent)] then
    -- restore skills when closing training window or dialogue window
    restoreTrainerSkills()
    return
  end

  if (e.property == mouseDown) and (tostring(e.parent) == 'MenuDialog_service_training') then
    -- 'Training' in dialogue menu is clicked
    npcRef = tes3ui.getServiceActor().reference
    log('[TRU][uiEventCallback] training window is going to open for NPC: %s', tes3ui.getServiceActor().reference)
    hideTrainerSkills(npcRef)
  end
end
event.register(tes3.event.uiEvent, uiEventCallback)

-- local function onDialogueStart(e)
--   npcRef = e.element:getPropertyObject('PartHyperText_actor').reference
--   if npcRef.object.objectType ~= tes3.objectType.npc then
--     npcRef = nil
--     return
--   end
--   timer.delayOneFrame(function()
--     log('[TRU] dialogue window OR training window opened')
--     tes3.messageBox('NPC unarmored skill value %s', npcRef.mobile:getSkillValue(tes3.skill['unarmored']))
--     -- should NOT be 1 after training it
--     -- hideTrainerSkills(npcRef)
--   end)
-- end
-- event.register('uiActivated', onDialogueStart, {filter = 'MenuDialog'})
-- this is actually not needed anymore, except tests

--- Hides skills that a selected NPC has teached already
--- by decreasing them to "1" temporarily
--- to prevent skilling more than once
function hideTrainerSkills(npcRef)
  log('[TRU][hideTrainerSkills] -----------------------------------')

  if (not tes3.player.data.trainedAt) then
    tes3.player.data.trainedAt = {}
    log('[TRU][hideTrainerSkills] Mod used for the first time. CREATED tes3.player.data.trainedAt')
  end

  g_trainerCurrent = npcRef
  g_trainerCurrentId = g_trainerCurrent.id
  g_trainerCurrentMobile = npcRef.mobile
  log('[TRU][hideTrainerSkills] g_trainerCurrent: %s, g_trainerCurrentId: %s, g_trainerCurrentMobile: %s', g_trainerCurrent, g_trainerCurrentId, g_trainerCurrentMobile)

  if (tes3.player.data.trainedAt 
  and tes3.player.data.trainedAt[g_trainerCurrentId]) then
    -- for each already trained skill in tes3.player.data.trainedAt[g_trainerCurrentId] decrease current trainer's skill value to 1
    for skillId, skillValue in pairs(tes3.player.data.trainedAt[g_trainerCurrentId]) do
      log('[TRU][hideTrainerSkills] ALREADY trained skillId %s (%s) at %s, block it', skillId, skills[skillId], g_trainerCurrentId)
      log('[TRU][hideTrainerSkills] trainer\'s skill BEFORE: %s', trainerSkillValueOriginal)
      tes3.setStatistic({ reference = tes3.getReference(g_trainerCurrentId), skill = skillId, value = 1 })
      log('[TRU][hideTrainerSkills] trainer\'s skill AFTER: %s', g_trainerCurrentMobile:getSkillValue(skillId))
    end
  end
end

--- Executed when training window appears (3x, for each skill):
--- * resets training iterations,
--- * updates training price,
--- * logs trainer skills to help debug
--- @param e calcTrainingPriceEventData
local function calcTrainingPriceCallback(e)
  log('[TRU][calcTrainingPriceCallback] -----------------------------------')

  local skillId = e.skillId
  local trainerSkillValueOriginal = g_trainerCurrentMobile:getSkillValue(skillId)
  local trainerTier = getTrainerTier(trainerSkillValueOriginal)
  e.price = e.price * trainerTier

  g_trainingIterations = nil
  g_trainerCurrent = e.reference
  g_trainerCurrentMobile = e.mobile  
  g_pcSkillProgressRequirement[skillId] = tes3.mobilePlayer:getSkillProgressRequirement(skillId)

  log('[TRU][calcTrainingPriceCallback] g_trainerCurrent: %s', g_trainerCurrent)
  log('[TRU][calcTrainingPriceCallback] e.ref: %s, e.basePrice: %s, e.price: %s, e.skillId: %s (%s)', e.reference, e.basePrice, e.price, skillId, skills[skillId])
  log('[TRU][calcTrainingPriceCallback] g_pcSkillProgressRequirement[skillId]: %s (%s)', g_pcSkillProgressRequirement[skillId], skills[skillId])
end
event.register(tes3.event.calcTrainingPrice, calcTrainingPriceCallback)

--- @param e skillRaisedEventData
local function skillRaisedCallback(e)
  log('[TRU][skillRaisedCallback] -----------------------------------')
  log('[TRU][skillRaisedCallback] e.source: %s', e.source)

  if e.source ~= 'training' and not (e.source == 'progress' and g_trainingIterations ~= nil) then
    -- bumping skill programatically with mobile:progressSkillToNextLevel is treated as 'progress'
    return
  end

  local skillId = e.skill
  local trainerSkillValueOriginal = g_trainerCurrentMobile:getSkillValue(skillId)
  local trainerTier = getTrainerTier(trainerSkillValueOriginal)

  log([[
  g_trainingIterations left: %s (of %s)
  trained at NPC: %s
  trained skill id: %s (%s)
  trainerTier: %s
  trainer's skill value: %s
  trained to level: %s
  ]], g_trainingIterations, trainerTier, g_trainerCurrentId, skillId, skills[skillId], trainerTier, trainerSkillValueOriginal, e.level)

  if g_trainingIterations == nil then
    -- this is executed once per skill train loop, in FIRST iteration
    -- training is repeated, once per every trainer tier (max. 5 times)
    g_trainingIterations = trainerTier

    -- remember that this skill was trained at this NPC
    -- save value as trainer's original skill level, to reset it after closing training window
    if (not tes3.player.data.trainedAt[g_trainerCurrentId]) then
      tes3.player.data.trainedAt[g_trainerCurrentId] = {}
      log('[TRU][skillRaisedCallback] trained at %s for the first time, CREATED tes3.player.data.trainedAt[g_trainerCurrentId]', g_trainerCurrent)
    end
    log('[TRU][skillRaisedCallback] %s teached %s for the first time, CREATED tes3.player.data.trainedAt[g_trainerCurrentId][skillId]', g_trainerCurrent, skills[skillId])
    tes3.player.data.trainedAt[g_trainerCurrentId][skillId] = g_trainerCurrentMobile:getSkillValue(skillId)

    -- move to last iteration?
    tes3.messageBox({
      message = string.format(
        'The training has paid off. %s has shared their %s experience (%s) about %s with you, and you\'ve improved your skill level from %s to %s. There is nothing more %s can teach you about %s. Take a break, ask about something else, or find other teacher.', 
        g_trainerCurrentMobile.object.name,
        tierLabels[trainerTier],
        trainerSkillValueOriginal,
        skills[skillId],
        e.level - 1, -- PC skill before training
        e.level - 1 + g_trainingIterations, -- PC skill after training
        g_trainerCurrentMobile.object.name,
        skills[skillId]
        ),
      buttons = { 'OK' }
    })
  end

  if g_trainingIterations ~= nil and g_trainingIterations == 1 then
    -- this is executed once per skill train loop, in LAST iteration
    log('[TRU][skillRaisedCallback] g_trainingIterations finished for %s, reset g_trainingIterations', skills[skillId])
    g_trainingIterations = nil
    hideTrainerSkills(g_trainerCurrent) -- hide trained skill before training window reopens

    -- take xp overflow into account!
    -- check if the skill that we're leveling up had any progress, and then add it
    -- after leveling current getSkillProgressRequirement is always 100% (when on UI it's 0/100), 
    -- so whatever progress was required before training (the old value in g_pcSkillProgressRequirement[skillId])
    -- needs to be subtracted from getSkillProgressRequirement and the result should be added to current progress 
    -- (for simplicity it assumes progress is linear, but in fact higher levels should have bigger requirements)
    local xpOverflow = tes3.mobilePlayer:getSkillProgressRequirement(skillId) - g_pcSkillProgressRequirement[skillId]
    log('[TRU][skillRaisedCallback] tes3.mobilePlayer:getSkillProgressRequirement(skillId): %s, g_pcSkillProgressRequirement[skillId]: %s', xpOverflow, g_pcSkillProgressRequirement[skillId])
    log('[TRU][skillRaisedCallback] xpOverflow: %s', xpOverflow)
    if not xpOverflow or xpOverflow == 0 then return end
    g_pcSkillProgressRequirement[skillId] = nil
    tes3.mobilePlayer:exerciseSkill(skillId, xpOverflow)

    return
  end

  g_trainingIterations = g_trainingIterations - 1
  if g_trainingIterations > 0 then
    -- repeat skillRaisedCallback for every g_trainingIterations left
    tes3.getPlayerRef().mobile:progressSkillToNextLevel(skillId)
  end
end
event.register(tes3.event.skillRaised, skillRaisedCallback)

local function onInitialized()
  mwse.log('[TRU] Mod initialized.')

  if isDebugOn then tes3.messageBox({ message = '[TRU] Mod initialized.', duration = 20 }) end
end
event.register('initialized', onInitialized)
