local interfaces = require("openmw.interfaces")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local json = require("scripts.MoveObjects.utility.json")

local refindex = 1
-- Helper: pack a vec table {x=,y=,z=} into an array [x,y,z]
local function vec3_to_array(v)
  if not v then return { 0, 0, 0 } end
  return { v.x or 0, v.y or 0, v.z or 0 }
end

-- helper: normalize any color table (0..1 or 0..255, table or array) to u8 RGBA
local function to_u8_rgba(c)
  if not c then return nil end
  local function norm(v)
    if v == nil then return 0 end
    if v <= 1.0 then v = v * 255 end
    v = math.floor(v + 0.5)
    if v < 0 then v = 0 elseif v > 255 then v = 255 end
    return v
  end
  local r = c.r or c[1] or 0
  local g = c.g or c[2] or 0
  local b = c.b or c[3] or 0
  local a = (c.a ~= nil and c.a) or c[4] or 0
  return { norm(r), norm(g), norm(b), norm(a) }
end

-- ===== Inference helpers =====
local function inferCell(objectList, opts)
  if opts and opts.cellRef then return opts.cellRef end
  local first = objectList and objectList[1]
  return first and first.cell or nil
end

local function inferCellId(objectList, opts)
  if opts and opts.cellId then return opts.cellId end
  local cell = inferCell(objectList, opts)
  local name = interfaces.AA_Settlements.getCurrentSettlementName(objectList[1])
  if name then return name end
  if cell and cell.name and cell.name ~= "" then return cell.name end
  local first = objectList and objectList[1]
  if first and first.type == types.Door and types.Door.isTeleport(first) then
    local tele = interfaces.CellSave.serializeObject(first).teleport
    if tele and tele.cell and tele.cell.name and tele.cell.name ~= "" then
      return tele.cell.name
    end
  end
end

-- ===== Region/color (stub -> real reader when available) =====
local function readRegionInfo(cell)
  local regionName, mapColor = nil, nil
  if cell and cell.region then
    if type(cell.region) == "string" then
      regionName = cell.region
      local region = core.regions.records[cell.region]
      if region and region.mapColor then
        mapColor = { region.mapColor.r, region.mapColor.g, region.mapColor.b, region.mapColor.a or 0 }
        mapColor = to_u8_rgba(mapColor)
      end
    end
  end
  return regionName, mapColor
end

-- ===== Object logic (separated) =====
-- Serialize game objects to CellSave-format tables
local function serializeObjects(objectList)
  local datalist = {}
  for i, x in ipairs(objectList or {}) do
    datalist[#datalist + 1] = interfaces.CellSave.serializeObject(x)
  end
  return datalist
end

-- Build "references" array from serialized object tables
local function buildReferences(serializedList, opts)
  local refs = {}
  for i, t in ipairs(serializedList) do
    local recordId = t.recordId
    local teleport = false
    --if t.type == types.Activator then
      if interfaces.AA_Records.getDoorOrigID(t.recordId) then
      print("teleport can")
        recordId = interfaces.AA_Records.getDoorOrigID(t.recordId) 
        teleport = true
      end
    --end
    refindex = refindex + 1
    local r = {
      mast_index  = 0, -- assigned later based on masters
      refr_index  = refindex,
      id          = recordId or tostring(t.id),
      temporary   = (opts and opts.temporary ~= nil) and opts.temporary or false,
      translation = vec3_to_array(t.position),
      rotation    = vec3_to_array(t.rotation),
    }
    if teleport then
      print("teleport data setting")
      local pos,rot,cellName = t.teleport.position,t.teleport.rotation,t.teleport.cell.name
      r.door_destination_coords = {
        pos.x,
        pos.y,
        pos.z,
        0,
        0,
        rot.z,
      }
      if cellName and not t.teleport.cell.isExterior then
        if interfaces.AA_CellGen_2_Labels.getCellName(cellName) then
          cellName = interfaces.AA_CellGen_2_Labels.getCellName(cellName)
        end
        r.door_destination_cell = cellName
      end
    end
    if t.scale and t.scale ~= 1 then r.scale = t.scale end
    refs[i] = r
  end
  return refs
end

-- ===== Masters logic =====
local function mergeMasters(existing, newOnes)
  local out, have = {}, {}
  local function push(name, crc)
    if not have[name] then
      out[#out + 1] = { name, crc or 0 }
      have[name] = true
    end
  end
  for _, m in ipairs(existing or {}) do push(m[1], m[2]) end
  for _, m in ipairs(newOnes or {}) do push(m[1], m[2]) end
  return out
end

-- Build a masters list from serialized objects (+ optional extras)
local function buildMasters(serializedList, opts)
  local base = {
    { "Morrowind.esm", 0 },
    { "Tribunal.esm",  0 },
    { "Bloodmoon.esm", 0 },
  }
  local extras = {}
  if opts and opts.extraMasters then
    for _, m in ipairs(opts.extraMasters) do
      extras[#extras + 1] = { m[1], m[2] or 0 }
    end
  end
  local fromObjs = {}
  local have = {}
  for _, t in ipairs(serializedList or {}) do
    local cf = t.contentFile
    if cf and not have[cf] then
      fromObjs[#fromObjs + 1] = { cf, 0 }
      have[cf] = true
    end
  end
  return mergeMasters(base, mergeMasters(extras, fromObjs))
end

-- After masters are known, assign mast_index per reference by contentFile match
local function assignMasterIndices(cellRec, serializedList, masters)
  local idxByName = {}
  for idx, pair in ipairs(masters or {}) do
    idxByName[pair[1]] = idx - 1 -- many TES3 tools treat mast_index as zero-based
  end
  for i, ref in ipairs(cellRec.references or {}) do
    local t = serializedList[i]
    if t and t.contentFile and idxByName[t.contentFile] ~= nil then
      ref.mast_index = idxByName[t.contentFile]
    else
      ref.mast_index = ref.mast_index or 0
    end
  end
end

local function findOriginalObject(activator)
  
end

-- ===== Cell record builder (uses object helpers) =====
local function buildCellRecord(objectList, serializedList, opts)
  local cellRef              = inferCell(objectList, opts)
  local cellId               = inferCellId(objectList, opts)
  local isExterior           = cellRef and cellRef.isExterior or false

  -- For exterior cells, TES3 uses flags=70 and real grid coords
  local cellFlags            = (opts and opts.cellFlags) or (isExterior and 70 or 1)
  local gridX                = (opts and opts.gridX) or (isExterior and cellRef and cellRef.gridX or 0) or 0
  local gridY                = (opts and opts.gridY) or (isExterior and cellRef and cellRef.gridY or 0) or 0

  local regionName, mapColor = nil, nil
  if isExterior then
    regionName, mapColor = readRegionInfo(cellRef)
  end

  local refs = buildReferences(serializedList, opts)

  local cellRec = {
    type       = "Cell",
    flags      = { 0, 0 },
    id         = cellId,
    data       = { flags = cellFlags, grid = { gridX, gridY } },
    references = refs,
  }
  if opts and opts.newCell then
    cellRec.atmosphere_data = {
      ambient_color  = { 41, 47, 50, 0 },
      sunlight_color = { 35, 39, 39, 0 },
      fog_color      = { 0, 0, 0, 0 },
      fog_density    = 0.8,
    }
  end
  if isExterior and regionName then cellRec.region = regionName end
  if isExterior and mapColor then cellRec.map_color = mapColor end
  if opts and opts.interior_fog and not isExterior then
    cellRec.interior_fog = opts.interior_fog
  end
  return cellRec
end

-- ===== Result JSON lifecycle =====
-- Create a fresh result array seeded with a Header record.
local function newResult(opts)
  local header = {
    type        = "Header",
    flags       = { 0, 0 },
    version     = 1.3,
    file_type   = "Esp",
    author      = (opts and opts.author) or "",
    description = (opts and opts.description) or "",
    num_objects = 0, -- updated as cells are added
    masters     = buildMasters(nil, opts),
  }
  return { header }
end

-- Add a cell (built from objectList) into an existing result array.
-- Also merges masters and increments num_objects appropriately.
local function addCellToResult(resultArray, objectList, opts)
  assert(type(resultArray) == "table" and resultArray[1] and resultArray[1].type == "Header",
    "addCellToResult: result array must start with a Header")

  local header = resultArray[1]

  -- Object logic (separate functions)
  local serializedList = serializeObjects(objectList)

  -- Masters: merge newly required masters
  local cellMasters = buildMasters(serializedList, opts)
  header.masters = mergeMasters(header.masters, cellMasters)

  -- Build cell record and assign mast_index based on merged masters
  local cellRec = buildCellRecord(objectList, serializedList, opts)
  assignMasterIndices(cellRec, serializedList, header.masters)

  -- Update header counts and append cell
  header.num_objects = (header.num_objects or 0) + (#serializedList)
  resultArray[#resultArray + 1] = cellRec

  return resultArray
end

-- Encode the result array to JSON (optionally pretty) and emit the export event.
local function encodeResult(resultArray, opts)
  local encodeOpts = {}
  if opts and opts.pretty then encodeOpts.indent = true end
  local returnText = json.encode(resultArray, encodeOpts)
  if world and world.players and world.players[1] then
    world.players[1]:sendEvent("setExportText", returnText)
  end
  return returnText
end

-- ===== Back-compat single-call function =====
-- Generates a JSON string for ONE cell (legacy API), using the new helpers.
local function generateTes3ConvJson(objectList, opts)
  refindex = 1
  local result = newResult(opts)
  addCellToResult(result, objectList or {}, opts)
  return encodeResult(result, opts)
end
local function generateJsonForSettlement(exteriorObjectList)
  refindex = 1
  local result = newResult()
  local settlementId
  for i, x in ipairs(exteriorObjectList) do
    if x.recordId == "zhac_settlement_marker" then
      settlementId = x.id
      table.remove(exteriorObjectList,i)
    end

  end
  addCellToResult(result, exteriorObjectList)
  for i, x in ipairs(interfaces.AA_CellGen_2.getCellGenData()) do
    if x.settlementId == settlementId then
      local contentCellName = x.cellName
      local newCellName = interfaces.AA_CellGen_2_Labels.getCellName(contentCellName)
      local intCellItems = world.getCellByName(contentCellName):getAll()
      addCellToResult(result, intCellItems, { cellId = newCellName, newCell = true })
    end
  end
  return encodeResult(result, opts)
end

return {
  interfaceName = "tes3ConvTool",
  interface = {
    -- Separated object logic (can be useful to callers too)
    serializeObjects     = serializeObjects,
    buildReferences      = buildReferences,

    -- Result lifecycle
    newResult            = newResult,
    addCellToResult      = addCellToResult,
    encodeResult         = encodeResult,
generateJsonForSettlement = generateJsonForSettlement,
    -- Back-compat one-shot
    generateTes3ConvJson = generateTes3ConvJson,
  }
}
