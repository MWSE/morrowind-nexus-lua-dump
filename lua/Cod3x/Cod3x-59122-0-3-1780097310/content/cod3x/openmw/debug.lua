---@meta

-- This file was mechanically drafted from files/lua_api/openmw/debug.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: player

---Provides an interface to the engine debug utils.
---@class openmw.debug
local debug = {}

---Rendering modes
---@class openmw.debug.RENDER_MODE
---@field CollisionDebug number
---@field Wireframe number
---@field Pathgrid number
---@field Water number
---@field Scene number
---@field NavMesh number
---@field ActorsPaths number
---@field RecastMesh number
local RENDER_MODE = {}

---Navigation mesh rendering modes
---@class openmw.debug.NAV_MESH_RENDER_MODE
---@field AreaType number
---@field UpdateFrequency number
local NAV_MESH_RENDER_MODE = {}

---Rendering mode values
---@type openmw.debug.RENDER_MODE
debug.RENDER_MODE = nil

---Toggles rendering mode
---@param value openmw.debug.RENDER_MODE
function debug.toggleRenderMode(value) end

---Toggles god mode
function debug.toggleGodMode() end

---Is god mode enabled
---@return boolean
function debug.isGodMode() end

---Toggles AI
function debug.toggleAI() end

---Is AI enabled
---@return boolean
function debug.isAIEnabled() end

---Toggles collisions
function debug.toggleCollision() end

---Is player collision enabled
---@return boolean
function debug.isCollisionEnabled() end

---Toggles MWScripts
function debug.toggleMWScript() end

---Is MWScripts enabled
---@return boolean
function debug.isMWScriptEnabled() end

---Reloads all Lua scripts
function debug.reloadLua() end

---Navigation mesh rendering mode values
---@type openmw.debug.NAV_MESH_RENDER_MODE
debug.NAV_MESH_RENDER_MODE = nil

---Sets navigation mesh rendering mode
---@param value openmw.debug.NAV_MESH_RENDER_MODE
function debug.setNavMeshRenderMode(value) end

---Enable/disable automatic reload of modified shaders
---@param value boolean
function debug.setShaderHotReloadEnabled(value) end

---To reload modified shaders
function debug.triggerShaderReload() end

return debug
