local config = require("mer.skoomaesthesia.config")
local Skoomaesthesia = {}

function Skoomaesthesia.registerSkooma(data)
    assert(type(data.id) == "string", "id must be a string")
    config.skooma[data.id:lower()] = data
end

function Skoomaesthesia.registerMoonSugar(data)
    assert(type(data.id) == "string", "id must be a string")
    config.moonSugar[data.id:lower()] = data
end

function Skoomaesthesia.registerPipe(data)
    assert(type(data.id) == "string", "id must be a string")
    config.pipes[data.id:lower()] = data
end

return Skoomaesthesia