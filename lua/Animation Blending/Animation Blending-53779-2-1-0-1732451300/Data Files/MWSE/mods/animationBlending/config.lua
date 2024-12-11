---@class AnimationBlendingConfig
---@field enabled boolean
---@field playerOnly boolean
---@field maxDistance number
---@field logLevel string
---@field blocked { [string]: boolean }
---@field version number
---@field diagonalMovement boolean
---@field diagonalMovement1stPerson boolean

local config = mwse.loadConfig("animationBlending", {
    enabled = true,
    playerOnly = false,
    maxDistance = 4096,
    logLevel = "INFO",
    blocked = {},
    version = 0.0,
    diagonalMovement = true,
    diagonalMovement1stPerson = true,
})

return config --[[@as AnimationBlendingConfig]]
