local this = {}

SFX_CELLS = {
    ["Tel Amur"] = true,
    ["Tel Amur, Entrance"] = true,
    ["Tel Amur, Grand Hall"] = true,
    ["Tel Amur, Chambers"] = true,
    ["Tel Amur, Upper Level"] = true,
    ["Tel Amur, Grotto"] = true,
    ["Maw of Tel Amur"] = true,
    ["Zete Fyr's Pocket Realm"] = true
}

VFX_CELLS = {
    ["Zete Fyr's Pocket Realm"] = true
}

---@param cell tes3cell
function this.isTelAmurCell(cell)
    return SFX_CELLS[cell.name]
end

---@param cell tes3cell
function this.isTelAmurFogCell(cell)
    return VFX_CELLS[cell.name]
end

return this
