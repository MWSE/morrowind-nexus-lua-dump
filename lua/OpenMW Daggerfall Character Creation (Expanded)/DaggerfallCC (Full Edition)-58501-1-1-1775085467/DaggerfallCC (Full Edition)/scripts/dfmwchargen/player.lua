local core = require('openmw.core')
local async = require('openmw.async')
local input = require('openmw.input')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local ATTRIBUTES = {
  'strength', 'intelligence', 'willpower', 'agility',
  'speed', 'endurance', 'personality', 'luck'
}

local DISPLAY_NAMES = {
  strength = 'Strength', intelligence = 'Intelligence', willpower = 'Willpower',
  agility = 'Agility', speed = 'Speed', endurance = 'Endurance',
  personality = 'Personality', luck = 'Luck',
  acrobatics = 'Acrobatics', alchemy = 'Alchemy', alteration = 'Alteration',
  armorer = 'Armorer', athletics = 'Athletics', axe = 'Axe',
  block = 'Block', bluntweapon = 'Blunt Weapon', conjuration = 'Conjuration',
  destruction = 'Destruction', enchant = 'Enchant', handtohand = 'Hand-to-Hand',
  heavyarmor = 'Heavy Armor', illusion = 'Illusion', lightarmor = 'Light Armor',
  longblade = 'Long Blade', marksman = 'Marksman', mediumarmor = 'Medium Armor',
  mercantile = 'Mercantile', mysticism = 'Mysticism', restoration = 'Restoration',
  security = 'Security', shortblade = 'Short Blade', sneak = 'Sneak',
  spear = 'Spear', speechcraft = 'Speechcraft', unarmored = 'Unarmored',
}

local function dn(id) return DISPLAY_NAMES[id] or id end

local COLOR_GOLD = util.color.rgb(0.86, 0.72, 0.35)
local COLOR_DIM = util.color.rgb(0.55, 0.50, 0.42)
local COLOR_BRIGHT = util.color.rgb(1.0, 0.95, 0.82)
local COLOR_GREEN = util.color.rgb(0.45, 0.78, 0.35)
local COLOR_HEADER = util.color.rgb(0.92, 0.82, 0.55)

local state = {
  visible = false, phase = 'attributes', draft = nil,
  quiz = nil, orderedQuestions = {}, config = {},
  currentQuestion = 1,
}
local activeElement = nil

local function sortedKeys(t)
  local keys = {}
  for k, v in pairs(t or {}) do if v then table.insert(keys, k) end end
  table.sort(keys)
  return keys
end

local function payloadForCurrentPhase()
  if not state.draft then return {} end
  if state.phase == 'attributes' then return state.draft.attributeDraft or {}
  elseif state.phase == 'skills' then return state.draft.skillDraft or {}
  elseif state.phase == 'background' then return state.draft.backgroundDraft or {}
  end
  return {}
end

local function sendDraft(action)
  if not state.draft then return end
  core.sendGlobalEvent('DFMWChargen_DraftUpdated', {
    phase = state.phase, action = action, payload = payloadForCurrentPhase(),
  })
end

local rebuildUi

-----------------------------------------------------------------------
-- UI PRIMITIVES
-----------------------------------------------------------------------

local function cell(str, width, color)
  return {
    props = { size = util.vector2(width, 22), autoSize = false },
    content = ui.content({
      { template = I.MWUI.templates.textNormal,
        props = { text = tostring(str), textColor = color or COLOR_BRIGHT } },
    }),
  }
end

local function spacer(h)
  return { props = { size = util.vector2(0, h or 6) } }
end

local function hrow(cells)
  return { type = ui.TYPE.Flex, props = { horizontal = true }, content = ui.content(cells) }
end

local function separator()
  return { template = I.MWUI.templates.textNormal,
    props = { text = string.rep('-', 56), textColor = COLOR_DIM } }
end

local function sectionHeader(str)
  return { template = I.MWUI.templates.textHeader, props = { text = str, textColor = COLOR_HEADER } }
end

local function textLine(str, color)
  return { template = I.MWUI.templates.textNormal, props = { text = str, textColor = color or COLOR_BRIGHT } }
end

local function wrappedText(str, width, color)
  return {
    template = I.MWUI.templates.textNormal,
    props = {
      text = str,
      textColor = color or COLOR_BRIGHT,
      wordWrap = true,
      autoSize = false,
      size = util.vector2(width, 60),
    },
  }
end

local function btn(label, onClick, width)
  return {
    template = I.MWUI.templates.box,
    props = { size = util.vector2(width or 160, 26) },
    events = { mouseClick = async:callback(onClick) },
    content = ui.content({
      { template = I.MWUI.templates.textNormal, props = { text = label } },
    }),
  }
end

local function tinyBtn(label, onClick)
  return {
    template = I.MWUI.templates.box,
    props = { size = util.vector2(28, 22) },
    events = { mouseClick = async:callback(onClick) },
    content = ui.content({
      { template = I.MWUI.templates.textNormal, props = { text = label } },
    }),
  }
end

local function buttonBar(buttons)
  local items = {}
  for i, b in ipairs(buttons) do
    if i > 1 then table.insert(items, { props = { size = util.vector2(8, 0) } }) end
    table.insert(items, btn(b[1], b[2], b[3]))
  end
  return { type = ui.TYPE.Flex, props = { horizontal = true }, content = ui.content(items) }
end

local function phaseBreadcrumb(current)
  local phases = {
    { id = 'attributes', label = '1. Attributes' },
    { id = 'skills', label = '2. Skills' },
    { id = 'background', label = '3. Background' },
  }
  local items = {}
  for i, p in ipairs(phases) do
    table.insert(items, cell(p.label, 110, p.id == current and COLOR_GOLD or COLOR_DIM))
    if i < #phases then table.insert(items, cell('>', 18, COLOR_DIM)) end
  end
  return hrow(items)
end

-----------------------------------------------------------------------
-- ATTRIBUTE PHASE
-----------------------------------------------------------------------

local function attrRow(attribute)
  local base = math.floor(state.draft.baseline.attributes[attribute] or 0)
  local roll = math.floor(state.draft.attributeDraft.autoRoll[attribute] or 0)
  local alloc = math.floor(state.draft.attributeDraft.allocated[attribute] or 0)
  local final = base + roll + alloc

  return hrow({
    cell(dn(attribute), 130, COLOR_BRIGHT),
    cell(tostring(base), 50, COLOR_DIM),
    cell(tostring(roll), 50, COLOR_GREEN),
    cell(tostring(alloc), 50, alloc > 0 and COLOR_GOLD or COLOR_DIM),
    tinyBtn('-', function()
      if (state.draft.attributeDraft.allocated[attribute] or 0) > 0 then
        state.draft.attributeDraft.allocated[attribute] = state.draft.attributeDraft.allocated[attribute] - 1
        state.draft.attributeDraft.pool = (state.draft.attributeDraft.pool or 0) + 1
        sendDraft('adjust')
      end
    end),
    tinyBtn('+', function()
      if (state.draft.attributeDraft.pool or 0) > 0 then
        state.draft.attributeDraft.allocated[attribute] = (state.draft.attributeDraft.allocated[attribute] or 0) + 1
        state.draft.attributeDraft.pool = state.draft.attributeDraft.pool - 1
        sendDraft('adjust')
      end
    end),
    cell(tostring(final), 50, COLOR_GOLD),
  })
end

local function renderAttributes()
  local pool = state.draft.attributeDraft.pool or 0
  local rows = {
    phaseBreadcrumb('attributes'),
    spacer(6),
    sectionHeader('Attribute Allocation'),
    spacer(4),
    textLine('Points remaining: ' .. tostring(pool), pool > 0 and COLOR_GREEN or COLOR_DIM),
    spacer(6),
    hrow({
      cell('Attribute', 130, COLOR_DIM), cell('Base', 50, COLOR_DIM),
      cell('Roll', 50, COLOR_DIM), cell('Alloc', 50, COLOR_DIM),
      cell('', 28), cell('', 28), cell('Final', 50, COLOR_DIM),
    }),
    separator(),
  }
  for _, attr in ipairs(ATTRIBUTES) do table.insert(rows, attrRow(attr)) end
  table.insert(rows, separator())
  table.insert(rows, spacer(6))
  table.insert(rows, buttonBar({
    { 'Reroll', function() sendDraft('reroll') end },
    { 'Save Roll', function() sendDraft('saveRoll') end },
    { 'Load Roll', function() sendDraft('loadRoll') end },
  }))
  table.insert(rows, spacer(4))
  table.insert(rows, buttonBar({
    { 'Reset', function()
        local spent = 0
        for _, a in ipairs(ATTRIBUTES) do
          spent = spent + (state.draft.attributeDraft.allocated[a] or 0)
          state.draft.attributeDraft.allocated[a] = 0
        end
        state.draft.attributeDraft.pool = (state.draft.attributeDraft.pool or 0) + spent
        sendDraft('adjust')
      end },
    { 'Next >>', function() sendDraft('next') end },
  }))
  return rows
end

-----------------------------------------------------------------------
-- SKILL PHASE
-----------------------------------------------------------------------

local function getSkillCap(skillId)
  if state.draft.skillDraft.eligibleMajors[skillId] then
    return state.config.majorSkillCap or 6
  elseif state.draft.skillDraft.eligibleMinors[skillId] then
    return state.config.minorSkillCap or 6
  else
    return state.config.miscSkillCap or 6
  end
end

local function sRow(skillId)
  local base = math.floor((state.draft.baseline.skills[skillId] and state.draft.baseline.skills[skillId].base) or 0)
  local alloc = state.draft.skillDraft.allocations[skillId] or 0
  local cap = getSkillCap(skillId)
  local ac = alloc >= cap and COLOR_GOLD or (alloc > 0 and COLOR_GREEN or COLOR_DIM)

  return hrow({
    cell(dn(skillId), 160, COLOR_BRIGHT),
    cell(tostring(base), 50, COLOR_DIM),
    cell(string.format('%d / %d', alloc, cap), 60, ac),
    tinyBtn('-', function()
      if (state.draft.skillDraft.allocations[skillId] or 0) > 0 then
        state.draft.skillDraft.allocations[skillId] = state.draft.skillDraft.allocations[skillId] - 1
        state.draft.skillDraft.poolRemaining = (state.draft.skillDraft.poolRemaining or 0) + 1
        sendDraft('adjust')
      end
    end),
    tinyBtn('+', function()
      local p = state.draft.skillDraft.poolRemaining or 0
      local c = state.draft.skillDraft.allocations[skillId] or 0
      if p > 0 and c < cap then
        state.draft.skillDraft.allocations[skillId] = c + 1
        state.draft.skillDraft.poolRemaining = p - 1
        sendDraft('adjust')
      end
    end),
  })
end

-- Compact row for misc skills (no base column, shorter name) for two-column layout
local function sRowCompact(skillId)
  local alloc = state.draft.skillDraft.allocations[skillId] or 0
  local cap = getSkillCap(skillId)
  local ac = alloc >= cap and COLOR_GOLD or (alloc > 0 and COLOR_GREEN or COLOR_DIM)

  return hrow({
    cell(dn(skillId), 120, COLOR_BRIGHT),
    cell(string.format('%d / %d', alloc, cap), 52, ac),
    tinyBtn('-', function()
      if (state.draft.skillDraft.allocations[skillId] or 0) > 0 then
        state.draft.skillDraft.allocations[skillId] = state.draft.skillDraft.allocations[skillId] - 1
        state.draft.skillDraft.poolRemaining = (state.draft.skillDraft.poolRemaining or 0) + 1
        sendDraft('adjust')
      end
    end),
    tinyBtn('+', function()
      local p = state.draft.skillDraft.poolRemaining or 0
      local c = state.draft.skillDraft.allocations[skillId] or 0
      if p > 0 and c < cap then
        state.draft.skillDraft.allocations[skillId] = c + 1
        state.draft.skillDraft.poolRemaining = p - 1
        sendDraft('adjust')
      end
    end),
  })
end

local function renderSkills()
  local pool = state.draft.skillDraft.poolRemaining or 0
  local rows = {
    phaseBreadcrumb('skills'),
    spacer(6),
    sectionHeader('Skill Allocation'),
    spacer(4),
    textLine('Points remaining: ' .. tostring(pool), pool > 0 and COLOR_GREEN or COLOR_DIM),
    spacer(6),
    hrow({
      cell('Skill', 160, COLOR_DIM), cell('Base', 50, COLOR_DIM),
      cell('Alloc', 60, COLOR_DIM), cell('', 28), cell('', 28),
    }),
    separator(),
    textLine('Major Skills', COLOR_HEADER),
    spacer(2),
  }
  for _, id in ipairs(sortedKeys(state.draft.skillDraft.eligibleMajors)) do
    table.insert(rows, sRow(id))
  end
  table.insert(rows, spacer(6))
  table.insert(rows, textLine('Minor Skills', COLOR_HEADER))
  table.insert(rows, spacer(2))
  for _, id in ipairs(sortedKeys(state.draft.skillDraft.eligibleMinors)) do
    table.insert(rows, sRow(id))
  end
  table.insert(rows, spacer(6))
  table.insert(rows, textLine('Miscellaneous Skills', COLOR_HEADER))
  table.insert(rows, spacer(2))
  -- Two-column layout to fit all misc skills without overflow
  local miscKeys = sortedKeys(state.draft.skillDraft.eligibleMisc or {})
  local half = math.ceil(#miscKeys / 2)
  local colLeft = {}
  local colRight = {}
  for i, id in ipairs(miscKeys) do
    if i <= half then
      table.insert(colLeft, sRowCompact(id))
    else
      table.insert(colRight, sRowCompact(id))
    end
  end
  -- Pad shorter column so they stay aligned
  while #colRight < #colLeft do
    table.insert(colRight, spacer(22))
  end
  table.insert(rows, hrow({
    { type = ui.TYPE.Flex, content = ui.content(colLeft) },
    { props = { size = util.vector2(12, 0) } },
    { type = ui.TYPE.Flex, content = ui.content(colRight) },
  }))
  table.insert(rows, separator())
  table.insert(rows, spacer(6))
  table.insert(rows, buttonBar({
    { '<< Back', function() sendDraft('back') end },
    { 'Next >>', function() sendDraft('next') end },
  }))
  return rows
end

-----------------------------------------------------------------------
-- BACKGROUND QUIZ
-----------------------------------------------------------------------

local function newRewards()
  return {
    attributes = {}, skills = {}, factions = {}, disposition = {},
    items = {}, affinities = {}, tags = {}, gold = 0, bundles = {},
  }
end

local function applyEffect(rewards, effect)
  if effect.type == 'skill_bonus' then
    rewards.skills[effect.skill] = (rewards.skills[effect.skill] or 0) + (effect.amount or 0)
  elseif effect.type == 'attribute_bonus' then
    rewards.attributes[effect.attribute] = (rewards.attributes[effect.attribute] or 0) + (effect.amount or 0)
  elseif effect.type == 'gold' then
    rewards.gold = (rewards.gold or 0) + (effect.amount or 0)
  elseif effect.type == 'reward_bundle' then
    table.insert(rewards.bundles, effect.id)
  elseif effect.type == 'affinity' then
    rewards.affinities[effect.id] = (rewards.affinities[effect.id] or 0) + (effect.amount or 0)
  elseif effect.type == 'tag' then
    rewards.tags[effect.id] = true
  end
end

local function getQuestionById(id) return state.quiz.questionsById[id] end

local function recalcBackgroundRewards()
  local rewards = newRewards()
  for index, questionId in ipairs(state.quiz.question_order or {}) do
    local chosen = state.draft.backgroundDraft.answers[index]
    if chosen then
      local q = getQuestionById(questionId)
      if q then
        for _, opt in ipairs(q.options or {}) do
          if opt.id == chosen then
            for _, eff in ipairs(opt.effects or {}) do applyEffect(rewards, eff) end
            break
          end
        end
      end
    end
  end
  state.draft.backgroundDraft.rewards = rewards
end

local function quizOption(optText, isSelected, onClick)
  return {
    template = I.MWUI.templates.box,
    props = { size = util.vector2(660, 26) },
    events = { mouseClick = async:callback(onClick) },
    content = ui.content({
      { template = I.MWUI.templates.textNormal,
        props = { text = optText, textColor = isSelected and COLOR_GOLD or COLOR_BRIGHT, wordWrap = true } },
    }),
  }
end

local function renderBackground()
  local qOrder = state.quiz.question_order or {}
  local total = #qOrder
  local qi = math.max(1, math.min(state.currentQuestion or 1, total + 1))

  local rows = {
    phaseBreadcrumb('background'),
    spacer(6),
    sectionHeader('Background'),
    spacer(4),
  }

  -- SUMMARY
  if qi > total then
    table.insert(rows, textLine('All questions answered. Your background grants:', COLOR_HEADER))
    table.insert(rows, spacer(6))
    local rw = state.draft.backgroundDraft.rewards or newRewards()

    -- Attributes
    local attrList = {}
    for attr, val in pairs(rw.attributes or {}) do
      table.insert(attrList, { attr, val })
    end
    if #attrList > 0 then
      table.insert(rows, textLine('Attributes:', COLOR_GOLD))
      for _, pair in ipairs(attrList) do
        table.insert(rows, textLine(string.format('  %s +%d', dn(pair[1]), pair[2]), COLOR_GREEN))
      end
      table.insert(rows, spacer(4))
    end

    -- Skills
    local skillList = {}
    for sk, val in pairs(rw.skills or {}) do
      table.insert(skillList, { sk, val })
    end
    if #skillList > 0 then
      table.insert(rows, textLine('Skills:', COLOR_GOLD))
      for _, pair in ipairs(skillList) do
        table.insert(rows, textLine(string.format('  %s +%d', dn(pair[1]), pair[2]), COLOR_GREEN))
      end
      table.insert(rows, spacer(4))
    end

    -- Gold
    if (rw.gold or 0) > 0 then
      table.insert(rows, textLine(string.format('Gold: +%d drakes', rw.gold), COLOR_GOLD))
      table.insert(rows, spacer(4))
    end

    -- Disposition
    local hasDisp = false
    local dispPerPoint = state.config.dispositionPerPoint or 5
    local affinityMap = state.config.affinityToFaction or {}
    for aff, val in pairs(rw.affinities or {}) do
      local factionName = affinityMap[aff] or aff
      local dispBonus = val * dispPerPoint
      if not hasDisp then
        table.insert(rows, textLine('Disposition:', COLOR_GOLD))
        hasDisp = true
      end
      table.insert(rows, textLine(string.format('  %s +%d', factionName, dispBonus), COLOR_DIM))
    end
    if hasDisp then table.insert(rows, spacer(4)) end

    -- Items from bundles
    local hasItems = false
    for _, desc in ipairs(rw.bundleDescriptions or {}) do
      if not hasItems then
        table.insert(rows, textLine('Items:', COLOR_GOLD))
        hasItems = true
      end
      table.insert(rows, textLine('  ' .. desc, COLOR_BRIGHT))
    end
    -- Fallback: check bundles in case they haven't been normalized yet
    if not hasItems then
      for _, bid in ipairs(rw.bundles or {}) do
        local def = state.quiz.reward_bundles and state.quiz.reward_bundles[bid]
        if def then
          if not hasItems then
            table.insert(rows, textLine('Items:', COLOR_GOLD))
            hasItems = true
          end
          table.insert(rows, textLine('  ' .. (def.description or bid), COLOR_BRIGHT))
        end
      end
    end

    if #attrList == 0 and #skillList == 0 and (rw.gold or 0) == 0 and not hasItems and not hasDisp then
      table.insert(rows, textLine('(No bonuses from background)', COLOR_DIM))
    end

    table.insert(rows, spacer(12))
    table.insert(rows, separator())
    table.insert(rows, spacer(6))
    table.insert(rows, buttonBar({
      { '<< Previous', function() state.currentQuestion = total; rebuildUi() end },
      { '<< Skills', function() sendDraft('back') end },
      { 'Finalize', function() sendDraft('finalize') end, 200 },
    }))
    return rows
  end

  -- QUESTION
  local question = getQuestionById(qOrder[qi])
  table.insert(rows, textLine(string.format('Question %d of %d', qi, total), COLOR_DIM))
  table.insert(rows, spacer(8))

  if not question then
    table.insert(rows, textLine('(Question data missing)', COLOR_DIM))
    return rows
  end

  table.insert(rows, wrappedText(question.prompt, 660, COLOR_HEADER))
  table.insert(rows, spacer(10))

  local selected = state.draft.backgroundDraft.answers[qi]
  for _, opt in ipairs(question.options or {}) do
    local isSel = selected == opt.id
    table.insert(rows, quizOption((isSel and '> ' or '  ') .. opt.text, isSel, function()
      state.draft.backgroundDraft.answers[qi] = opt.id
      recalcBackgroundRewards()
      sendDraft('adjust')
    end))
    table.insert(rows, spacer(3))
  end

  table.insert(rows, spacer(10))
  local nav = {}
  if qi > 1 then
    table.insert(nav, { '<< Previous', function() state.currentQuestion = qi - 1; rebuildUi() end })
  end
  if selected then
    if qi < total then
      table.insert(nav, { 'Next >>', function() state.currentQuestion = qi + 1; rebuildUi() end })
    else
      table.insert(nav, { 'Review >>', function() state.currentQuestion = total + 1; rebuildUi() end, 200 })
    end
  end
  if #nav > 0 then
    table.insert(rows, buttonBar(nav))
  else
    table.insert(rows, textLine('Select an answer to continue.', COLOR_DIM))
  end
  return rows
end

-----------------------------------------------------------------------
-- UI LIFECYCLE
-----------------------------------------------------------------------

rebuildUi = function()
  if activeElement then activeElement:destroy(); activeElement = nil end
  if not state.visible or not state.draft then return end

  local body = {}
  if state.phase == 'attributes' then body = renderAttributes()
  elseif state.phase == 'skills' then body = renderSkills()
  elseif state.phase == 'background' then body = renderBackground()
  end

  activeElement = ui.create({
    layer = 'Windows',
    template = I.MWUI.templates.boxSolid,
    props = {
      anchor = util.vector2(0.5, 0.5),
      relativePosition = util.vector2(0.5, 0.5),
      size = util.vector2(720, 720),
    },
    content = ui.content({
      {
        type = ui.TYPE.Flex,
        props = { position = util.vector2(20, 16), size = util.vector2(680, 688), autoSize = false },
        content = ui.content(body),
      },
    }),
  })
end

local function enterUiMode()
  local ok, iface = pcall(function() return I.UI end)
  if ok and iface and iface.setMode then iface.setMode('Interface', { windows = {} }) end
end

local function exitUiMode()
  local ok, iface = pcall(function() return I.UI end)
  if ok and iface and iface.removeMode then iface.removeMode('Interface') end
end

local function onShowUi(data)
  state.phase = data.phase
  state.draft = data.state
  state.quiz = data.quiz or { question_order = {}, questions = {} }
  state.quiz.questionsById = {}
  for _, q in ipairs(state.quiz.questions or {}) do state.quiz.questionsById[q.id] = q end
  state.orderedQuestions = state.quiz.question_order or {}
  state.config = data.config or {}
  if state.phase == 'background' and (state.currentQuestion or 0) < 1 then
    state.currentQuestion = 1
  end
  state.visible = true
  rebuildUi()
  enterUiMode()
end

local function onCloseUi(data)
  if not (data and data.force) then
    return
  end
  state.visible = false
  state.draft = nil
  state.currentQuestion = 1
  rebuildUi()
  exitUiMode()
end

local pendingStats = nil
local function onApplyStats(data) pendingStats = data end

local function applyPendingStats()
  if not pendingStats then return end
  local data = pendingStats
  pendingStats = nil
  local selfRef = require('openmw.self')
  for attr, change in pairs(data.attributes or {}) do
    local acc = types.Actor.stats.attributes[attr]
    if acc then
      local s = acc(selfRef)
      if s then s.base = (change.base or s.base) + (change.delta or 0) end
    end
  end
  for skillId, change in pairs(data.skills or {}) do
    local acc = types.NPC.stats.skills[skillId]
    if acc then
      local s = acc(selfRef)
      if s then s.base = (change.base or s.base) + (change.delta or 0); s.progress = 0 end
    end
  end
  print('[DFMWChargen] Stats applied from chargen overlay')
end

local function onUpdatePlayer()
  applyPendingStats()

  -- Guard against other mods (or the player) closing Interface mode
  -- while our overlay is still active. Re-assert every frame so the
  -- cursor is always available when the panel is visible.
  if state.visible then
    enterUiMode()
  end
end

local function onKeyPress(key)
  if state.visible and key.code == input.KEY.Escape then
    enterUiMode()
  end
end

return {
  engineHandlers = {
    onUpdate = onUpdatePlayer,
    onKeyPress = onKeyPress,
  },
  eventHandlers = {
    DFMWChargen_ShowUI = onShowUi,
    DFMWChargen_CloseUI = onCloseUi,
    DFMWChargen_ApplyStats = onApplyStats,
  },
}
