local this = {
    version = 1.1,
    vfxData = {},
}

function this.registerVFX(vfx)
    this.vfxData[vfx.id] = vfx.data
end

this.lighting = require("SpellsReforged.SR_0_Core.lighting")

return this
