local S = select('sandbox.bypass')
local ffi = S.require('ffi')

ffi.cdef[[
  void SwapTextureByPath(const char* targetTexture, const char* replacementTexture);
  void TriggerCompositeMapRegen();
  void TriggerDistantLandRefresh();
  void DumpTrackedTextures();
  void DumpTrackedTexturesFiltered(const char* filter);
  void DumpSceneGraphTextures();
]]

local swapper = ffi.load('TextureSwapper.dll')

-- RETROACTIVE NATIVE INTERFACE: Expose it to the Lua console.
-- You can press F4 in-game and type `I.TextureSwapper.swap()` for manual texture swaps
return {
    interfaceName = "TextureSwapper",
    interface = {
        version = 1,
        swap = function(oldTex, newTex)
            swapper.SwapTextureByPath(oldTex, newTex)
        end,
        dump = function()
            swapper.DumpTrackedTextures()
        end,
        find = function(filter)
            swapper.DumpTrackedTexturesFiltered(filter)
        end,
        regenComposites = function()
            swapper.TriggerCompositeMapRegen()
        end,
        refresh = function()
            swapper.TriggerDistantLandRefresh()
        end,
        dumpScene = function()
            swapper.DumpSceneGraphTextures()
        end
    }
}
