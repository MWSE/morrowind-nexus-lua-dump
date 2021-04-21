local replacers = {
    ["f\\furn_com_kegstand.nif"] = "furn_com_kegstand_dr",
    ["f\\furn_de_kegstand.nif"] = "furn_de_kegstand_dr",
    ["f\\furn_winekeg00.nif"] = "furn_winekeg00_dr",
}


local replacements = {}
for _, id in pairs(replacers) do replacements[id] = 1 end


local visitedCells = {}
event.register("loaded", function() visitedCells = {} end)


local droplet_radius = 22
local droplet_offset = tes3vector3.new(0.0, -54, -64.0)


local function swapReference(ref, replacer)
    -- backup modified state
    local cell_modified = ref.cell.modified
    -- hide the static keg
    ref.sceneNode.appCulled = true
    -- spawn activator keg
    if not visitedCells[ref.cell] then
        tes3.createReference{
            object = replacer,
            cell = ref.cell,
            position = ref.position,
            orientation = ref.orientation,
            scale = ref.scale,
        }.modified = false
    end
    -- restore modified state
    ref.cell.modified = cell_modified
end


local function getTransforms(ref)
    local o = ref.orientation
    local rotation = tes3matrix33.new()
    rotation:fromEulerXYZ(o.x, o.y, o.z)
    return ref.position, rotation, ref.scale
end


local function onKegCreated(e)
    if e.reference.object.objectType ~= tes3.objectType.static then
        -- only interested in static object type
        return
    elseif e.reference.disabled or e.reference.deleted then
        -- ignore deleted or disabled references
        return
    end

    local replacer = replacers[e.reference.object.mesh:lower()]
    if replacer == nil then
        return
    end

    -- search through cell references and see if any buckets are nearby
    local l, r, s = getTransforms(e.reference)
    local droplet_position = (r * s * droplet_offset) + l
    for ref in e.reference.cell:iterateReferences(tes3.objectType.misc) do
        if (ref.disabled == false
            and ref.deleted == false
            and ref.object.mesh ~= nil)
        then
            local mesh = ref.object.mesh:lower()
            local dist = ref.position:distance(droplet_position)
            if (dist <= droplet_radius) and (mesh:find("bucket") or mesh:find("bowl")) then
                swapReference(e.reference, replacer)
                return
            end
        end
    end
end
event.register("referenceSceneNodeCreated", onKegCreated)


local function onCellChanged(e)
    visitedCells[e.cell] = true
    for ref in e.cell:iterateReferences(tes3.objectType.activator) do
        if replacements[ref.id:lower()] then
            tes3.setAnimationTiming{reference=ref, timing=math.random() * 3}
        end
    end
end
event.register("cellChanged", onCellChanged)


local function onLoaded()
    timer.delayOneFrame(function()
        onCellChanged{cell=tes3.player.cell}
    end)
end
event.register("loaded", onLoaded)
