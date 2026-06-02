local config = require('scripts.dfmwchargen.config')

local log = {}

local function fmt(msg)
  return ('[DFMWChargen] %s'):format(msg)
end

function log.info(msg)
  print(fmt(msg))
end

function log.debug(msg)
  if config.debug then
    print(fmt('DEBUG: ' .. msg))
  end
end

function log.error(msg)
  error(fmt(msg))
end

return log
