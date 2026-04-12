local core = require('openmw.core')
local world = require('openmw.world')
local storage = require('openmw.storage')
local types = require('openmw.types')
local time = require('openmw_aux.time')

local config = require('scripts.dfmwchargen.config')
local log = require('scripts.dfmwchargen.log')
local rng = require('scripts.dfmwchargen.rng')
local quiz = require('scripts.dfmwchargen.data.background_quiz')

local stateSection = storage.globalSection(config.playerSectionName)

-- Runtime overrides for item templates (e.g. devalued copies of mod-provided items).
-- Checked before config.itemTemplates during item reward resolution.
local customRecordOverrides = {}

local function resolveItemTemplate(templateId)
  return customRecordOverrides[templateId] or config.itemTemplates[templateId]
end

-- Create modified copies of mod-provided records at runtime.
-- Called once at flow start so the custom records exist before finalization.
local function createCustomRecords()
  -- Devalue TR Ebony Dagger: the original is worth thousands, but as a
  -- starter heirloom it should be modest — matching Daggerfall's intent.
  local ok, baseRecord = pcall(types.Weapon.record, 'T_De_Ebony_Dagger_01')
  if ok and baseRecord then
    local draftOk, draft = pcall(types.Weapon.createRecordDraft, {
      name = baseRecord.name,
      model = baseRecord.model,
      icon = baseRecord.icon,
      type = baseRecord.type,
      health = baseRecord.health,
      value = 300,
      weight = baseRecord.weight,
      speed = baseRecord.speed,
      reach = baseRecord.reach,
      enchantCapacity = baseRecord.enchantCapacity or 0,
      chopMinDamage = baseRecord.chopMinDamage,
      chopMaxDamage = baseRecord.chopMaxDamage,
      slashMinDamage = baseRecord.slashMinDamage,
      slashMaxDamage = baseRecord.slashMaxDamage,
      thrustMinDamage = baseRecord.thrustMinDamage,
      thrustMaxDamage = baseRecord.thrustMaxDamage,
    })
    if draftOk and draft then
      local recOk, newRecord = pcall(world.createRecord, draft)
      if recOk and newRecord then
        customRecordOverrides['starter_ebony_dagger'] = newRecord.id
        log.info(('Created custom Ebony Dagger record "%s" (value: 300)'):format(newRecord.id))
      else
        log.info('Could not register custom Ebony Dagger record; using original')
      end
    else
      log.info('Could not create Ebony Dagger record draft; using original')
    end
  end
end

local ATTRIBUTES = {
  'strength', 'intelligence', 'willpower', 'agility',
  'speed', 'endurance', 'personality', 'luck'
}

local function getPlayer()
  if world and world.players and world.players[1] then
    return world.players[1]
  end
  return nil
end

local function newBackgroundRewards()
  return {
    attributes = {},
    skills = {},
    factions = {},
    disposition = {},
    items = {},
    affinities = {},
    tags = {},
    gold = 0,
    bundles = {},
  }
end

local function newDefaultState()
  return {
    initialized = false,
    flowActive = false,
    finalized = false,
    currentPhase = 'idle',
    baseline = { attributes = {}, skills = {} },
    attributeDraft = { autoRoll = {}, allocated = {}, pool = 0, savedRoll = nil },
    skillDraft = { poolRemaining = config.skillPoolTotal, allocations = {}, eligibleMajors = {}, eligibleMinors = {}, eligibleMisc = {} },
    backgroundDraft = { answers = {}, rewards = newBackgroundRewards() },
    rng = { seed = 0, state = 0 },
    chargenSeen = false,
    playerRefId = nil,
    startedFromNewGame = false,
    filteredQuestionOrder = nil,
    affinityBonuses = {},
    boostedNPCs = {},
    debug = config.debug,
  }
end

local function ensureStateDefaults(state)
  state.baseline = state.baseline or { attributes = {}, skills = {} }
  state.baseline.attributes = state.baseline.attributes or {}
  state.baseline.skills = state.baseline.skills or {}

  state.attributeDraft = state.attributeDraft or {}
  state.attributeDraft.autoRoll = state.attributeDraft.autoRoll or {}
  state.attributeDraft.allocated = state.attributeDraft.allocated or {}
  if state.attributeDraft.pool == nil then
    state.attributeDraft.pool = 0
  end

  state.skillDraft = state.skillDraft or {}
  if state.skillDraft.poolRemaining == nil then
    state.skillDraft.poolRemaining = config.skillPoolTotal
  end
  state.skillDraft.allocations = state.skillDraft.allocations or {}
  state.skillDraft.eligibleMajors = state.skillDraft.eligibleMajors or {}
  state.skillDraft.eligibleMinors = state.skillDraft.eligibleMinors or {}
  state.skillDraft.eligibleMisc = state.skillDraft.eligibleMisc or {}

  state.backgroundDraft = state.backgroundDraft or {}
  state.backgroundDraft.answers = state.backgroundDraft.answers or {}
  state.backgroundDraft.rewards = state.backgroundDraft.rewards or newBackgroundRewards()

  state.rng = state.rng or {}
  state.rng.seed = state.rng.seed or 0
  state.rng.state = state.rng.state or 0

  if state.currentPhase == nil then
    state.currentPhase = 'idle'
  end
  if state.initialized == nil then
    state.initialized = false
  end
  if state.flowActive == nil then
    state.flowActive = false
  end
  if state.finalized == nil then
    state.finalized = false
  end
  if state.chargenSeen == nil then
    state.chargenSeen = false
  end
  if state.startedFromNewGame == nil then
    state.startedFromNewGame = false
  end
  if state.debug == nil then
    state.debug = config.debug
  end
  state.affinityBonuses = state.affinityBonuses or state.pendingAffinities or {}
  state.pendingAffinities = nil  -- migrate old field
  state.boostedNPCs = state.boostedNPCs or {}
end

local function loadState()
  local state = stateSection:getCopy('state')
  if not state then
    state = newDefaultState()
  end
  ensureStateDefaults(state)
  return state
end

local function saveState(state)
  stateSection:set('state', state)
end

local function copyTable(t)
  local out = {}
  for k, v in pairs(t or {}) do
    if type(v) == 'table' then
      out[k] = copyTable(v)
    else
      out[k] = v
    end
  end
  return out
end

local function getStatBase(entity, statType, id)
  local accessor = statType[id]
  if not accessor then
    log.info(('Missing stat accessor for %s'):format(id))
    return 0
  end

  local stat = accessor(entity)
  if not stat then
    log.info(('Missing stat on entity for %s'):format(id))
    return 0
  end

  return stat.base
end

local function setStatBase(entity, statType, id, value)
  local accessor = statType[id]
  if not accessor then
    log.info(('Missing stat accessor for %s'):format(id))
    return
  end

  local stat = accessor(entity)
  if not stat then
    log.info(('Missing stat on entity for %s'):format(id))
    return
  end

  stat.base = value
end

local function snapshotBaseline(state, player)
  state.baseline.attributes = {}
  state.baseline.skills = {}

  for _, attribute in ipairs(ATTRIBUTES) do
    state.baseline.attributes[attribute] = getStatBase(player, types.Actor.stats.attributes, attribute)
  end

  for skillId, accessor in pairs(types.NPC.stats.skills) do
    local stat = accessor(player)
    if stat then
      state.baseline.skills[skillId] = { base = stat.base, progress = stat.progress }
    end
  end

  log.debug('Baseline snapshot captured')
end

local function resolvePlayerClassRecord(player)
  if not (types.NPC and types.NPC.record) then
    return nil, 'types.NPC.record is unavailable'
  end

  local npcRecord = types.NPC.record(player)
  if not npcRecord then
    return nil, 'types.NPC.record(player) returned nil'
  end

  local classId = npcRecord.class
  if not classId or classId == '' then
    return nil, ('Player NPC record %s has no class id'):format(tostring(npcRecord.id))
  end

  if not (types.NPC and types.NPC.classes) then
    return nil, 'types.NPC.classes is unavailable'
  end

  local classRecord = nil

  if types.NPC.classes.records then
    classRecord = types.NPC.classes.records[classId]
  end

  if not classRecord and types.NPC.classes.record then
    classRecord = types.NPC.classes.record(classId)
  end

  if not classRecord then
    return nil, ('No class record found for class id %s'):format(tostring(classId))
  end

  return classRecord, nil
end

local function collectEligibleSkills(state, player)
  state.skillDraft.eligibleMajors = {}
  state.skillDraft.eligibleMinors = {}
  state.skillDraft.eligibleMisc = {}

  local classRecord, err = resolvePlayerClassRecord(player)
  if not classRecord then
    return false, err
  end

  log.debug(('Resolved player class: %s'):format(tostring(classRecord.id)))

  -- Track which skills are major/minor
  local classified = {}

  for _, skillId in ipairs(classRecord.majorSkills or {}) do
    state.skillDraft.eligibleMajors[skillId] = true
    state.skillDraft.allocations[skillId] = state.skillDraft.allocations[skillId] or 0
    classified[skillId] = true
  end

  for _, skillId in ipairs(classRecord.minorSkills or {}) do
    state.skillDraft.eligibleMinors[skillId] = true
    state.skillDraft.allocations[skillId] = state.skillDraft.allocations[skillId] or 0
    classified[skillId] = true
  end

  -- Everything else from the baseline snapshot is a misc skill
  for skillId, _ in pairs(state.baseline.skills) do
    if not classified[skillId] then
      state.skillDraft.eligibleMisc[skillId] = true
      state.skillDraft.allocations[skillId] = state.skillDraft.allocations[skillId] or 0
    end
  end

  log.debug(('Skills: %d major, %d minor, %d misc'):format(
    #(classRecord.majorSkills or {}),
    #(classRecord.minorSkills or {}),
    (function() local n=0; for _ in pairs(state.skillDraft.eligibleMisc) do n=n+1 end; return n end)()
  ))

  return true
end

local function generateAttributeRoll(state)
  local r = rng.fromState(state.rng.seed, state.rng.state)
  state.attributeDraft.autoRoll = {}
  state.attributeDraft.allocated = {}

  for _, attribute in ipairs(ATTRIBUTES) do
    state.attributeDraft.autoRoll[attribute] = rng.roll0to10(r)
    state.attributeDraft.allocated[attribute] = 0
  end

  state.attributeDraft.pool = rng.roll6to14(r)
  state.rng.state = r.state
end

local function setPlayerLockState(player, locked)
  if not player then
    return
  end

  local switch = types.Player.CONTROL_SWITCH
  types.Player.setControlSwitch(player, switch.Controls, not locked)
  types.Player.setControlSwitch(player, switch.Fighting, not locked)
  types.Player.setControlSwitch(player, switch.Jumping, not locked)
  types.Player.setControlSwitch(player, switch.Looking, not locked)
  types.Player.setControlSwitch(player, switch.Magic, not locked)
  types.Player.setControlSwitch(player, switch.VanityMode, not locked)
  types.Player.setControlSwitch(player, switch.ViewMode, not locked)
  types.Player.setTeleportingEnabled(player, not locked)

  log.debug(('Player lock state => %s'):format(tostring(locked)))
end

-- Check if a game record exists. Used for conditional quiz options (e.g., TR items).
local RECORD_TYPE_MAP = {
  weapon = types.Weapon,
  armor = types.Armor,
  clothing = types.Clothing,
  potion = types.Potion,
  book = types.Book,
  miscellaneous = types.Miscellaneous,
}

local function recordExists(reqType, reqId)
  local typeTable = RECORD_TYPE_MAP[reqType]
  if not typeTable or not typeTable.record then
    return false
  end
  local ok, rec = pcall(typeTable.record, reqId)
  return ok and rec ~= nil
end

-- Filter quiz questions: strip options whose requires_record doesn't resolve.
local function filterQuizOptions(questions)
  local filtered = {}
  for _, question in ipairs(questions) do
    local newOpts = {}
    for _, opt in ipairs(question.options or {}) do
      if opt.requires_record then
        if recordExists(opt.requires_record.type, opt.requires_record.id) then
          table.insert(newOpts, opt)
        else
          log.debug(('Hiding option "%s": record %s not found'):format(
            opt.id, opt.requires_record.id))
        end
      else
        table.insert(newOpts, opt)
      end
    end
    local copy = {}
    for k, v in pairs(question) do copy[k] = v end
    copy.options = newOpts
    table.insert(filtered, copy)
  end
  return filtered
end

local function pushUiState(state)
  local player = getPlayer()
  if player then
    local quizForPlayer = {
      questions = filterQuizOptions(quiz.questions),
      question_order = state.filteredQuestionOrder or quiz.question_order,
      reward_bundles = quiz.reward_bundles,
    }
    player:sendEvent('DFMWChargen_ShowUI', {
      phase = state.currentPhase,
      state = copyTable(state),
      quiz = quizForPlayer,
      config = {
        skillPoolTotal = config.skillPoolTotal,
        majorSkillCap = config.majorSkillCap,
        minorSkillCap = config.minorSkillCap,
        miscSkillCap = config.miscSkillCap,
        affinityToFaction = config.affinityToFaction,
        dispositionPerPoint = 5,
      },
    })
  end
end

local function beginFlow(state, player)
  createCustomRecords()

  if state.rng.seed == 0 then
    local seed = math.floor(core.getSimulationTime() * 1000) + math.floor(core.getGameTime())
    state.rng.seed = seed
    state.rng.state = seed
  end

  snapshotBaseline(state, player)

  local ok, err = collectEligibleSkills(state, player)
  if not ok then
    return false, ('Could not collect eligible class skills: %s'):format(tostring(err))
  end

  -- Determine class specialization and filter background questions.
  -- OpenMW 0.50: classRecord.specialization is a string: 'combat', 'magic', or 'stealth'
  local classRecord = resolvePlayerClassRecord(player)
  local specName = nil
  if classRecord then
    if classRecord.specialization and classRecord.specialization ~= '' then
      specName = classRecord.specialization
      log.debug(('Class specialization: %s'):format(specName))
    else
      log.debug('Class record has no specialization field')
    end
  end

  -- Build question ID -> specialization lookup from quiz data
  local questionSpec = {}
  for _, q in ipairs(quiz.questions or {}) do
    if q.specialization then
      questionSpec[q.id] = q.specialization
    end
  end

  -- Filter: keep universal questions + questions matching player's specialization.
  -- If specialization is unknown, include ALL questions as a fallback.
  local filteredOrder = {}
  if specName then
    for _, qid in ipairs(quiz.question_order or {}) do
      local qSpec = questionSpec[qid]
      if qSpec == nil or qSpec == specName then
        table.insert(filteredOrder, qid)
      end
    end
  else
    log.debug('Specialization unknown; including all questions')
    for _, qid in ipairs(quiz.question_order or {}) do
      table.insert(filteredOrder, qid)
    end
  end

  state.filteredQuestionOrder = filteredOrder
  log.debug(('Quiz questions for this class: %d of %d'):format(
    #filteredOrder, #(quiz.question_order or {})))

  state.flowActive = true
  state.currentPhase = 'attributes'
  generateAttributeRoll(state)
  state.attributeDraft.savedRoll = copyTable({
    autoRoll = state.attributeDraft.autoRoll,
    allocated = state.attributeDraft.allocated,
    pool = state.attributeDraft.pool,
  })
  state.skillDraft.poolRemaining = config.skillPoolTotal
  state.backgroundDraft = state.backgroundDraft or { answers = {}, rewards = newBackgroundRewards() }
  state.backgroundDraft.answers = state.backgroundDraft.answers or {}
  state.backgroundDraft.rewards = state.backgroundDraft.rewards or newBackgroundRewards()

  setPlayerLockState(player, true)
  pushUiState(state)
  return true
end

local function applySkillProgressReset(player, skillId)
  local accessor = types.NPC.stats.skills[skillId]
  if not accessor then
    return
  end

  local skill = accessor(player)
  if skill then
    skill.progress = 0
  end
end

local function addItemReward(rewards, recordId, count)
  if not recordId then
    return
  end
  table.insert(rewards.items, { id = recordId, count = count or 1 })
end

local function applyBackgroundRewardPayload(state, player)
  local rewards = state.backgroundDraft.rewards or newBackgroundRewards()

  for factionId, rep in pairs(rewards.factions or {}) do
    if player.factions and player.factions[factionId] then
      player.factions[factionId].reputation = player.factions[factionId].reputation + rep
    end
  end

  for affinityId, value in pairs(rewards.affinities or {}) do
    local factionId = config.affinityToFaction[affinityId]
    if factionId then
      state.affinityBonuses[factionId] = (state.affinityBonuses[factionId] or 0) + value
      log.debug(('Stored affinity bonus: %s +%d'):format(factionId, value))
    else
      log.info(('No faction mapping for affinity "%s"; skipping'):format(affinityId))
    end
  end

  local inventory = types.Actor.inventory(player)

  if rewards.gold and rewards.gold > 0 then
    local ok, goldObj = pcall(world.createObject, 'gold_001', rewards.gold)
    if ok and goldObj then
      goldObj:moveInto(inventory)
    else
      log.info(('Could not create gold object; skipping'):format())
    end
  end

  for _, item in ipairs(rewards.items or {}) do
    if item.id and item.id ~= '' then
      local ok, object = pcall(world.createObject, item.id, item.count or 1)
      if ok and object then
        object:moveInto(inventory)
      else
        log.info(('Could not create item "%s"; skipping'):format(tostring(item.id)))
      end
    end
  end

  log.debug(('Applied background payload: gold=%d items=%d'):format(rewards.gold or 0, #(rewards.items or {})))
end

-----------------------------------------------------------------------
-- DISPOSITION-BASED AFFINITY APPLICATION
-- Periodically scans NPCs in active cells. If an NPC belongs to a
-- faction the player has affinity with, boost their base disposition
-- once. Tracked per-NPC so bonuses never stack on repeat visits.
-----------------------------------------------------------------------

local AFFINITY_CHECK_INTERVAL = 5 * time.second
local DISPOSITION_PER_POINT = 5  -- +1 affinity = +5 disposition, +3 = +15

local function checkDispositionBonuses()
  local state = loadState()
  local bonuses = state.affinityBonuses or {}

  -- No affinity bonuses at all — stop the timer permanently.
  local hasAny = false
  for _ in pairs(bonuses) do hasAny = true; break end
  if not hasAny then
    log.debug('No affinity bonuses defined; stopping disposition timer')
    return false
  end

  local player = getPlayer()
  if not player or not player.cell then return AFFINITY_CHECK_INTERVAL end

  local boosted = state.boostedNPCs or {}
  local changed = false

  -- Scan NPCs in the player's current cell
  local ok, npcs = pcall(function() return player.cell:getAll(types.NPC) end)
  if not ok or not npcs then return AFFINITY_CHECK_INTERVAL end

  for _, npc in ipairs(npcs) do
    local npcId = npc.id
    if npcId and not boosted[npcId] then
      -- Check all factions this NPC belongs to against our affinity list
      local totalBonus = 0
      for factionId, points in pairs(bonuses) do
        local rankOk, rank = pcall(types.NPC.getFactionRank, npc, factionId)
        if rankOk and rank > 0 then
          totalBonus = totalBonus + (points * DISPOSITION_PER_POINT)
        end
      end

      if totalBonus > 0 then
        local dispOk, err = pcall(types.NPC.modifyBaseDisposition, npc, player, totalBonus)
        if dispOk then
          log.debug(('Boosted disposition for %s by +%d'):format(npc.recordId, totalBonus))
        else
          log.debug(('Failed disposition boost for %s: %s'):format(npc.recordId, tostring(err)))
        end
        boosted[npcId] = true
        changed = true
      else
        -- NPC isn't in any relevant faction; mark so we don't recheck
        boosted[npcId] = true
        changed = true
      end
    end
  end

  if changed then
    state.boostedNPCs = boosted
    saveState(state)
  end

  return AFFINITY_CHECK_INTERVAL
end

local function startAffinityTimer()
  time.runRepeatedly(checkDispositionBonuses, AFFINITY_CHECK_INTERVAL, { type = time.GameTime })
  log.debug('Started disposition affinity timer')
end

local function applyFinal(state)
  local player = getPlayer()
  if not player then
    log.info('Cannot finalize: no player reference')
    return false
  end

  -- Compute attribute deltas
  local attrChanges = {}
  for _, attr in ipairs(ATTRIBUTES) do
    local base = state.baseline.attributes[attr] or 0
    local delta = (state.attributeDraft.autoRoll[attr] or 0)
               + (state.attributeDraft.allocated[attr] or 0)
               + (state.backgroundDraft.rewards.attributes[attr] or 0)
    if delta ~= 0 then
      attrChanges[attr] = { base = base, delta = delta }
    end
  end

  -- Compute skill deltas
  local skillChanges = {}
  for skillId, baseline in pairs(state.baseline.skills) do
    local bonus = (state.skillDraft.allocations[skillId] or 0)
               + (state.backgroundDraft.rewards.skills[skillId] or 0)
    if bonus ~= 0 then
      skillChanges[skillId] = { base = baseline.base, delta = bonus }
    end
  end

  -- Send stat changes to player script (stat.base can only be set from local scripts)
  player:sendEvent('DFMWChargen_ApplyStats', {
    attributes = attrChanges,
    skills = skillChanges,
  })

  -- Apply non-stat rewards from global (items, gold, factions need world.createObject)
  applyBackgroundRewardPayload(state, player)

  state.currentPhase = 'done'
  state.flowActive = false
  state.finalized = true
  setPlayerLockState(player, false)
  player:sendEvent('DFMWChargen_CloseUI', { force = true })

  -- Start periodic disposition scan for faction-affiliated NPCs
  local hasBonuses = false
  for _ in pairs(state.affinityBonuses or {}) do hasBonuses = true; break end
  if hasBonuses then
    startAffinityTimer()
  end

  log.info('Finalization complete')
  return true
end

local function applyAttributePayload(state, payload)
  local incoming = payload or {}
  state.attributeDraft.autoRoll = copyTable(incoming.autoRoll or state.attributeDraft.autoRoll or {})
  state.attributeDraft.allocated = copyTable(incoming.allocated or state.attributeDraft.allocated or {})
  if incoming.pool ~= nil then
    state.attributeDraft.pool = incoming.pool
  end
end

local function applySkillPayload(state, payload)
  local incoming = payload or {}
  state.skillDraft.allocations = copyTable(incoming.allocations or state.skillDraft.allocations or {})
  state.skillDraft.eligibleMajors = copyTable(incoming.eligibleMajors or state.skillDraft.eligibleMajors or {})
  state.skillDraft.eligibleMinors = copyTable(incoming.eligibleMinors or state.skillDraft.eligibleMinors or {})
  state.skillDraft.eligibleMisc = copyTable(incoming.eligibleMisc or state.skillDraft.eligibleMisc or {})
  if incoming.poolRemaining ~= nil then
    state.skillDraft.poolRemaining = incoming.poolRemaining
  end
end

local function normalizeBackgroundRewards(state)
  local rewards = state.backgroundDraft.rewards or newBackgroundRewards()
  rewards.items = rewards.items or {}

  -- Reset and rebuild bundle descriptions for the summary UI
  rewards.bundleDescriptions = {}
  for _, bundleId in ipairs(rewards.bundles or {}) do
    local bundle = quiz.reward_bundles[bundleId]
    if bundle then
      table.insert(rewards.bundleDescriptions, bundle.description or bundleId)
      for _, entry in ipairs(bundle.entries or {}) do
        if entry.kind == 'item_template' then
          addItemReward(rewards, resolveItemTemplate(entry.id), entry.count)
        end
      end
    end
  end

  rewards.bundles = {}
  state.backgroundDraft.rewards = rewards
end

local function applyBackgroundPayload(state, payload)
  local incoming = payload or {}
  state.backgroundDraft.answers = copyTable(incoming.answers or state.backgroundDraft.answers or {})
  state.backgroundDraft.rewards = copyTable(incoming.rewards or state.backgroundDraft.rewards or newBackgroundRewards())
  normalizeBackgroundRewards(state)
end

local function onDraftEvent(data)
  local state = loadState()
  if state.finalized then
    return
  end

  if data.phase == 'attributes' then
    if data.action == 'loadRoll' then
      if state.attributeDraft.savedRoll then
        local savedRoll = copyTable(state.attributeDraft.savedRoll)
        state.attributeDraft.autoRoll = savedRoll.autoRoll or {}
        state.attributeDraft.allocated = savedRoll.allocated or {}
        state.attributeDraft.pool = savedRoll.pool or 0
      end
    elseif data.action == 'reroll' then
      generateAttributeRoll(state)
      if not state.attributeDraft.savedRoll then
        state.attributeDraft.savedRoll = copyTable({
          autoRoll = state.attributeDraft.autoRoll,
          allocated = state.attributeDraft.allocated,
          pool = state.attributeDraft.pool,
        })
      end
    else
      applyAttributePayload(state, data.payload)
      if data.action == 'saveRoll' then
        state.attributeDraft.savedRoll = copyTable(state.attributeDraft)
      elseif data.action == 'next' then
        if (state.attributeDraft.pool or 0) ~= 0 then
          saveState(state)
          pushUiState(state)
          return
        end
        state.currentPhase = 'skills'
      end
    end
  elseif data.phase == 'skills' then
    applySkillPayload(state, data.payload)

    if data.action == 'next' then
      if (state.skillDraft.poolRemaining or 0) ~= 0 then
        saveState(state)
        pushUiState(state)
        return
      end
      state.currentPhase = 'background'
    elseif data.action == 'back' then
      state.currentPhase = 'attributes'
    end
  elseif data.phase == 'background' then
    applyBackgroundPayload(state, data.payload)

    if data.action == 'back' then
      state.currentPhase = 'skills'
    elseif data.action == 'finalize' then
      if applyFinal(state) then
        saveState(state)
      end
      return
    end
  end

  saveState(state)
  pushUiState(state)
end

local function onNewGame()
  -- Reset all state and mark this as a fresh new game.
  local state = newDefaultState()
  state.initialized = true
  state.startedFromNewGame = true
  saveState(state)
  log.info('New game detected; awaiting vanilla chargen completion')
end

local function chargenFinished(player)
  if not types.Player or not types.Player.isCharGenFinished then
    return false
  end
  return types.Player.isCharGenFinished(player)
end

local function onPlayerAdded(player)
  local state = loadState()
  state.playerRefId = player.recordId

  -- Since saves cannot happen during the overlay flow, any flowActive=true
  -- state on load is stale from a previous session. Reset it.
  if state.flowActive and not state.finalized then
    log.info('Stale flow state detected on load; resetting')
    state.flowActive = false
    state.currentPhase = 'idle'
    state.chargenSeen = false
  end

  -- If we loaded a save where chargen is already done but the flow never
  -- ran, startedFromNewGame may be stale from a new-game started earlier
  -- in the same session. Reset it so the flow doesn't trigger on old saves.
  if not state.finalized and not state.chargenSeen and chargenFinished(player) then
    state.startedFromNewGame = false
  end

  saveState(state)
  log.debug('Player added/re-added')

  -- Never resume the overlay on load. If it's a new game, onUpdate will
  -- detect chargen completion and start the flow fresh.
  if state.finalized then
    setPlayerLockState(player, false)

    -- Resume disposition scanning from a previous session
    local hasBonuses = false
    for _ in pairs(state.affinityBonuses or {}) do hasBonuses = true; break end
    if hasBonuses then
      startAffinityTimer()
    end
  end
end

local function onUpdate()
  local state = loadState()

  if state.finalized or state.flowActive or not state.startedFromNewGame or state.chargenSeen then
    return
  end

  local player = getPlayer()
  if not player then
    return
  end

  if chargenFinished(player) then
    log.info('Vanilla chargen completion detected; opening Specials UI')
    player:sendEvent('OpenSpecialsChargen')
    state.chargenSeen = true
    saveState(state)
  end
end

local function onSpecialsComplete()
  local state = loadState()

  if state.finalized then
    return
  end

  if state.flowActive then
    return
  end

  if not state.startedFromNewGame then
    log.info('Ignoring SpecialsComplete on non-new-game state')
    return
  end

  local player = getPlayer()
  if not player then
    log.info('SpecialsComplete received before player is available')
    return
  end

  if not state.chargenSeen then
    log.info('Ignoring SpecialsComplete before vanilla chargen completion')
    return
  end

  log.info('SpecialsComplete received; beginning overlay flow')
  local started, err = beginFlow(state, player)
  if started then
    saveState(state)
  else
    log.info(('Overlay flow start deferred: %s'):format(tostring(err)))
  end
end

return {
  engineHandlers = {
    onUpdate = onUpdate,
    onNewGame = onNewGame,
    onPlayerAdded = onPlayerAdded,
  },
  eventHandlers = {
    DFMWChargen_DraftUpdated = onDraftEvent,
    SpecialsComplete = onSpecialsComplete,
  },
}
