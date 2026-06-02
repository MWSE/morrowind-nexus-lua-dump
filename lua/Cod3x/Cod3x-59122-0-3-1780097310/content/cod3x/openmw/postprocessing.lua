---@meta

-- This file was mechanically drafted from files/lua_api/openmw/postprocessing.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: player

---Provides an interface to postprocessing shaders.
---@class openmw.postprocessing
local postprocessing = {}

---@class openmw.postprocessing.Shader
---@field name string Name of the shader
---@field description string Description of the shader
---@field author string Author of the shader
---@field version string Version of the shader
local Shader = {}

---Load a shader and return its handle.
----- If the shader exists and compiles, the shader will still be off by default.
----- It must be enabled to see its effect.
---local vignetteShader = postprocessing.load('vignette')
---@param name string Name of the shader without its extension
---@return openmw.postprocessing.Shader
function postprocessing.load(name) end

---Returns the ordered list of active shaders.
---Active shaders may change between frames.
---@return openmw.postprocessing.Shader[] list The currently active shaders order
function postprocessing.getChain() end

---Enable the shader. Has no effect if the shader is already enabled or does
---not exist. Will not apply until the next frame.
----- Load shader
---local vignetteShader = postprocessing.load('vignette')
----- Toggle shader on
---vignetteShader:enable()
---@param position? number optional position to place the shader. If left out the shader will be inserted at the end of the chain.
function Shader:enable(position) end

---Deactivate the shader. Has no effect if the shader is already deactivated or does not exist.
---Will not apply until the next frame.
---local vignetteShader = shader.postprocessing('vignette')
---vignetteShader:disable() -- shader will be toggled off
function Shader:disable() end

---Check if the shader is enabled.
---local vignetteShader = shader.postprocessing('vignette')
---vignetteShader:enable() -- shader will be toggled on
---@return boolean True if shader is enabled and was compiled successfully.
function Shader:isEnabled() end

---Set a non static bool shader variable.
---@param name string Name of uniform
---@param value boolean Value of uniform.
function Shader:setBool(name, value) end

---Set a non static integer shader variable.
---@param name string Name of uniform
---@param value number Value of uniform.
function Shader:setInt(name, value) end

---Set a non static float shader variable.
---@param name string Name of uniform
---@param value number Value of uniform.
function Shader:setFloat(name, value) end

---Set a non static Vector2 shader variable.
---@param name string Name of uniform
---@param value openmw.util.Vector2 Value of uniform.
function Shader:setVector2(name, value) end

---Set a non static Vector3 shader variable.
---@param name string Name of uniform
---@param value openmw.util.Vector3 Value of uniform.
function Shader:setVector3(name, value) end

---Set a non static Vector4 shader variable.
---@param name string Name of uniform
---@param value openmw.util.Vector4 Value of uniform.
function Shader:setVector4(name, value) end

---Set a non static integer array shader variable.
---@param name string Name of uniform
---@param array table Contains equal number of #number elements as the uniform array.
function Shader:setIntArray(name, array) end

---Set a non static float array shader variable.
---@param name string Name of uniform
---@param array table Contains equal number of #number elements as the uniform array.
function Shader:setFloatArray(name, array) end

---Set a non static Vector2 array shader variable.
---@param name string Name of uniform
---@param array table Contains equal number of openmw.util.Vector2 elements as the uniform array.
function Shader:setVector2Array(name, array) end

---Set a non static Vector3 array shader variable.
---@param name string Name of uniform
---@param array table Contains equal number of openmw.util.Vector3 elements as the uniform array.
function Shader:setVector3Array(name, array) end

---Set a non static Vector4 array shader variable.
----- Setting an array
---local shader = postprocessing.load('godrays')
----- Toggle shader on
---shader:enable()
----- Set new array uniform which was defined with length 2
---shader:setVector4Array('myArray', { util.vector4(1,0,0,1), util.vector4(1,0,1,1) })
---@param name string Name of uniform
---@param array table Contains equal number of openmw.util.Vector4 elements as the uniform array.
function Shader:setVector4Array(name, array) end

return postprocessing
