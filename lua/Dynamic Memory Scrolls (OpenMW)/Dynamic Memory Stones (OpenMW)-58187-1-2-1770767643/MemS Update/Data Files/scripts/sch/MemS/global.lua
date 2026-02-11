local types = require('openmw.types')
local world = require('openmw.world')

local whitelist = {
  'chest',
  'corpse',
  'skeleton',
  'nordictomb',
  'wiz'
}

local sokId = 'sch_mems_bo_sok'
local sowId = 'sch_mems_bo_sow'

local function isWhitelisted(recordIdLower)
  for _, word in ipairs(whitelist) do
    if recordIdLower:find(word, 1, true) then
      return true
    end
  end
  return false
end

local function onObjectActive(obj)
  -- Skip friendly cells
  local cell = obj.cell
  if cell and cell.hasTag and cell:hasTag('NoSleep') then
    return
  end

  -- Containers only
  if not types.Container.objectIsInstance(obj) then
    return
  end

  local id = obj.recordId:lower()
  if not isWhitelisted(id) then
    return
  end

  -- Skip if already contains sok or sow
  local inv = types.Container.content(obj)
  if inv and (inv:countOf(sokId) > 0 or inv:countOf(sowId) > 0) then
    return
  end

  -- 1 in 15 containers get loot
  if math.random(15) ~= 1 then
    return
  end

  -- Of those: 1/3 sow, 2/3 sok
  if math.random(3) == 1 then
    world.createObject(sowId, 1):moveInto(obj)
  else
    world.createObject(sokId, 1):moveInto(obj)
  end
end

return { engineHandlers = { onObjectActive = onObjectActive } }