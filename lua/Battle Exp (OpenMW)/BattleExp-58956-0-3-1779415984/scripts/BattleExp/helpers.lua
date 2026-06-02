local function log(msg, ...)
  if not DEBUG then return end
  local args = { ... }
  
  for i = 1, select('#', ...) do
    if args[i] == nil then
      args[i] = 'NIL!'
    end
  end
  
  local ok, result = pcall(string.format, msg, table.unpack(args))
  if ok then
    print('[BattleExp] ' .. result)
  else
    local parts = { tostring(msg) }
    -- fallback: just print all args as-is so a bad format never silently swallows a log line      
    for _, v in ipairs(args) do
      table.insert(parts, tostring(v))
    end
    print(table.unpack(parts))
  end
end

local function countTruthyValues(followerIds)
  if not followerIds then return 0 end
  local count = 0
  for _, v in pairs(followerIds) do
    if v then count = count + 1 end
  end
  return count
end

return { log = log, setDebug = function(val) DEBUG = val end, countTruthyValues = countTruthyValues }
