local util = require("openmw.util")
local world = require("openmw.world")
local types = require("openmw.types")

local TARGET_CELL_NAME = "Ebonheart, Staffing Agency"
local NPCS_PER_WAVE = 6
local WAVE_DURATION_SECONDS = 7 * 24 * 60 * 60
local PENDING_REFRESH_DELAY_SECONDS = 1 * 24 * 60 * 60
local ROLE_TARGETS = {
  servant = 2,
  mage = 2,
  mercenary = 2,
}
local ROLE_LABELS = {
  servant = "Servant",
  mage = "Mage-Servant",
  mercenary = "Mercenary-Servant",
}

local SPAWN_POINTS = {
  util.vector3(4458.327148, -7192.552734, 20814.890625),
  util.vector3(4328.296875, -7360.950195, 20814.890625),
  util.vector3(4850.720215, -7917.013672, 20814.890625),
  util.vector3(4814.984863, -7745.793457, 20814.890625),
  util.vector3(4349.734863, -7917.740723, 20814.890625),
  util.vector3(4358.675781, -7616.455078, 20847.226562),
}

local SCRIPT_MODULES = {
  { path = "scripts.servants.servantArgonianFemale", label = "Argonian Female" },
  { path = "scripts.servants.servantArgonianMale", label = "Argonian Male" },
  { path = "scripts.servants.servantBretonFemale", label = "Breton Female" },
  { path = "scripts.servants.servantBretonMale", label = "Breton Male" },
  { path = "scripts.servants.servantDarkElfFemale", label = "Dark Elf Female" },
  { path = "scripts.servants.servantDarkElfMale", label = "Dark Elf Male" },
  { path = "scripts.servants.servantHighElfFemale", label = "High Elf Female" },
  { path = "scripts.servants.servantHighElfMale", label = "High Elf Male" },
  { path = "scripts.servants.servantImperialFemale", label = "Imperial Female" },
  { path = "scripts.servants.servantImperialMale", label = "Imperial Male" },
  { path = "scripts.servants.servantKhajiitFemale", label = "Khajiit Female" },
  { path = "scripts.servants.servantKhajiitMale", label = "Khajiit Male" },
  { path = "scripts.servants.servantRedguardFemale", label = "Redguard Female" },
  { path = "scripts.servants.servantRedguardMale", label = "Redguard Male" },
}

local state = {
  validatedPools = nil,
  waveStartTime = nil,
  refreshPending = false,
  refreshReadyTime = nil,
  spawnedObjectIds = {},
}

local function log(msg)
  print("NPC-GENERATOR: " .. tostring(msg))
end

local function pick(list)
  return list[math.random(1, #list)]
end

local function shuffle(list)
  for i = #list, 2, -1 do
    local j = math.random(1, i)
    list[i], list[j] = list[j], list[i]
  end
end

local function buildRoleQueue()
  local roles = {}

  for role, count in pairs(ROLE_TARGETS) do
    for _ = 1, count do
      roles[#roles + 1] = role
    end
  end

  shuffle(roles)
  return roles
end

local function getPlayer()
  local players = world.players

  if not players or #players == 0 then
    return nil
  end

  return players[1]
end

local function getNpcRecord(recordId)
  if types.NPC.record then
    return types.NPC.record(recordId)
  elseif types.NPC.records then
    return types.NPC.records(recordId)
  end

  return nil
end

local function isPlayerInTargetCell(player)
  return player
    and player.cell
    and player.cell.name == TARGET_CELL_NAME
end

local function serializeState()
  local objectIds = {}

  for objectId, isTracked in pairs(state.spawnedObjectIds) do
    if isTracked then
      objectIds[#objectIds + 1] = objectId
    end
  end

  return {
    waveStartTime = state.waveStartTime,
    refreshPending = state.refreshPending,
    refreshReadyTime = state.refreshReadyTime,
    spawnedObjectIds = objectIds,
  }
end

local function restoreState(savedData)
  state.spawnedObjectIds = {}
  state.waveStartTime = nil
  state.refreshPending = false
  state.refreshReadyTime = nil

  if type(savedData) ~= "table" then
    return
  end

  if type(savedData.waveStartTime) == "number" then
    state.waveStartTime = savedData.waveStartTime
  end

  if type(savedData.refreshPending) == "boolean" then
    state.refreshPending = savedData.refreshPending
  end

  if type(savedData.refreshReadyTime) == "number" then
    state.refreshReadyTime = savedData.refreshReadyTime
  end

  if type(savedData.spawnedObjectIds) == "table" then
    for _, objectId in ipairs(savedData.spawnedObjectIds) do
      if objectId then
        state.spawnedObjectIds[objectId] = true
      end
    end
  end

  if state.waveStartTime and next(state.spawnedObjectIds) == nil then
    state.waveStartTime = nil
  end

  if state.refreshPending and type(state.refreshReadyTime) ~= "number" then
    state.refreshPending = false
  end
end

local function validateModule(def)
  local ok, moduleOrError = pcall(require, def.path)

  if not ok then
    return nil, "require failed for " .. tostring(def.path) .. ": " .. tostring(moduleOrError)
  end

  local module = moduleOrError

  if type(module) ~= "table" then
    return nil, "module " .. tostring(def.path) .. " did not return a table"
  end

  if type(module.createRecord) ~= "function" then
    return nil, "module " .. tostring(def.path) .. " is missing createRecord()"
  end

  if type(module.templateIds) ~= "table" or #module.templateIds == 0 then
    return nil, "module " .. tostring(def.path) .. " has no templateIds"
  end

  local hasValidTemplate = false

  for _, sourceId in ipairs(module.templateIds) do
    if getNpcRecord(sourceId) then
      hasValidTemplate = true
      break
    end
  end

  if not hasValidTemplate then
    return nil, "module " .. tostring(def.path) .. " has no resolvable source templates"
  end

  return {
    label = module.label or def.label,
    module = module,
  }, nil
end

local function buildValidatedPools()
  local pools = {}

  for _, def in ipairs(SCRIPT_MODULES) do
    local pool, err = validateModule(def)

    if pool then
      pools[#pools + 1] = pool
    else
      log("Skipping pool " .. tostring(def.label) .. ": " .. tostring(err))
    end
  end

  return pools
end

local despawnWave

local function clearPendingRefresh()
  state.refreshPending = false
  state.refreshReadyTime = nil
end

local function queuePendingRefresh(now)
  state.refreshPending = true
  state.refreshReadyTime = now + PENDING_REFRESH_DELAY_SECONDS
  log("Refresh queued; ready at game time " .. tostring(state.refreshReadyTime))
end

local function spawnWave()
  if not state.validatedPools then
    state.validatedPools = buildValidatedPools()
  end

  if not state.validatedPools or #state.validatedPools == 0 then
    log("Cannot spawn wave: no valid servant pools")
    return
  end

  state.spawnedObjectIds = {}
  local roleQueue = buildRoleQueue()

  local spawnedCount = 0
  local attempts = 0
  local maxAttempts = NPCS_PER_WAVE * 30

  if #roleQueue ~= NPCS_PER_WAVE then
    log("Cannot spawn wave: role target total does not match NPCS_PER_WAVE")
    return
  end

  while spawnedCount < NPCS_PER_WAVE and attempts < maxAttempts do
    attempts = attempts + 1
    local index = spawnedCount + 1
    local spawnPos = SPAWN_POINTS[index]
    local pool = pick(state.validatedPools)
    local servantType = roleQueue[index]

    local rec, err = pool.module.createRecord(servantType)

    if not rec or not rec.id then
      log("Spawn " .. tostring(index) .. " failed for pool " .. tostring(pool.label) .. ": " .. tostring(err))
    else
      local npc = world.createObject(rec.id, 1)

      if not npc then
        log("Spawn " .. tostring(index) .. " failed to create object for " .. tostring(rec.id))
      else
        npc:teleport(TARGET_CELL_NAME, spawnPos)
        state.spawnedObjectIds[npc.id] = true
        spawnedCount = spawnedCount + 1

        log(
          "Spawn "
            .. tostring(index)
            .. ": "
            .. tostring(pool.label)
            .. " / "
            .. (ROLE_LABELS[servantType] or "Servant")
            .. " / "
            .. tostring(rec.id)
        )
      end
    end
  end

  if spawnedCount == NPCS_PER_WAVE then
    state.waveStartTime = world.getGameTime()
    clearPendingRefresh()
    log("Wave spawned: " .. tostring(spawnedCount) .. "/" .. tostring(NPCS_PER_WAVE))
  elseif spawnedCount > 0 then
    log("Wave incomplete (" .. tostring(spawnedCount) .. "/" .. tostring(NPCS_PER_WAVE) .. "); removing partial wave")
    despawnWave()
  else
    log("Wave spawn failed: no NPCs spawned")
  end
end

despawnWave = function()
  local cell = world.getCellByName(TARGET_CELL_NAME)

  if not cell then
    log("Cannot despawn: target cell is unavailable")
    return false
  end

  local removedCount = 0

  for _, npc in ipairs(cell:getAll(types.NPC)) do
    if state.spawnedObjectIds[npc.id] then
      npc:remove()
      removedCount = removedCount + 1
    end
  end

  state.spawnedObjectIds = {}
  state.waveStartTime = nil

  log("Despawned " .. tostring(removedCount) .. " generated NPC(s)")
  return true
end

local function updateSpawner()
  local player = getPlayer()

  if not player then
    return
  end

  if not state.waveStartTime then
    spawnWave()
    return
  end

  local now = world.getGameTime()
  local elapsed = now - state.waveStartTime

  if elapsed < WAVE_DURATION_SECONDS then
    return
  end

  if not state.refreshPending then
    if isPlayerInTargetCell(player) then
      queuePendingRefresh(now)
      return
    end

    if despawnWave() then
      spawnWave()
    end
    return
  end

  if type(state.refreshReadyTime) ~= "number" or now < state.refreshReadyTime then
    return
  end

  if isPlayerInTargetCell(player) then
    return
  end

  if despawnWave() then
    spawnWave()
  end
end

local function safeOnUpdate()
  local ok, err = pcall(updateSpawner)

  if not ok then
    log("Lua error in onUpdate: " .. tostring(err))
  end
end

local function onSave()
  return serializeState()
end

local function onLoad(savedData)
  restoreState(savedData)
end

return {
  engineHandlers = {
    onLoad = onLoad,
    onSave = onSave,
    onUpdate = safeOnUpdate,
  },
}
