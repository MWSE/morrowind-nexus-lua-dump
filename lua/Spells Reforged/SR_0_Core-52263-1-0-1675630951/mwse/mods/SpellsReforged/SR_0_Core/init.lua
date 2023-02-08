local this = {
    version = 1.0,
    vfxData = {},
}

function this.registerVFX(vfx)
    this.vfxData[vfx.id] = vfx.data
end

return this
