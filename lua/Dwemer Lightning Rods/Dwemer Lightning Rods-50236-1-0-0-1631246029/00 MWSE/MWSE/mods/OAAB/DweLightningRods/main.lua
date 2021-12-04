local replacements = {
    ["ex_dwrv_steamstack00"] = { id = "ab_ex_dwrvsteamstackrod_a", offset = {-128, 0, 1536} },
}

event.register("referenceActivated", function(e)
    local ref = e.reference
    if ref.disabled or ref.deleted then
        return
    end

    local replacement = replacements[ref.id:lower()]
    if replacement == nil then
        return
    end

    local cell = ref.cell
    if cell.isInterior and not cell.behavesAsExterior then
        return
    end

    for _, axis in pairs{ref.orientation.x, ref.orientation.y} do
        local angle = math.deg(math.abs(axis))
        if (angle > 25) and (angle < 360-25) then
            return
        end
    end

    -- hide the original ref
    local cell_modified = cell.modified
    ref:disable()
    ref.modified = false

    -- get transforms/offset
    local t = ref.sceneNode.worldTransform
    local offset = tes3vector3.new(unpack(replacement.offset))

    -- spawn the replacement
    local temp = tes3.createReference{
        object = replacement.id,
        cell = ref.cell,
        position = (t.rotation * t.scale * offset) + t.translation,
        orientation = ref.orientation,
        scale = ref.scale,
    }

    -- reset modified states
    temp.modified = false
    cell.modified = cell_modified
end)
