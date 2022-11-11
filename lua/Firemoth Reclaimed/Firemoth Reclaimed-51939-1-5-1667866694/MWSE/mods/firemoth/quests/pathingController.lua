local this = {}

local function update(e)
    local data = e.timer.data
    local destination = data.destinations[1]
    if not destination then
        e.timer:cancel()
        return
    end

    local ref = tes3.getReference(data.reference)
    if ref == nil or ref.mobile.isDead then
        e.timer:cancel()
        return
    end

    local distance = ref.position:distance(tes3.player.position)
    if distance > 8192 then
        destination = table.remove(data.destinations) -- final dest
        tes3.positionCell({ reference = ref, position = destination })
        e.timer:cancel()
        return
    end

    local pkg = ref.mobile.aiPlanner:getActivePackage()
    if not pkg or (pkg.type ~= tes3.aiPackage.travel) then
        tes3.setAITravel({ reference = ref, destination = destination })
        return
    end
    if not pkg.isDone then
        return
    end

    if not ref.cell:isPointInCell(unpack(destination)) then
        tes3.positionCell({ reference = ref, position = destination })
    end
    tes3.setAIWander({ reference = ref, idles = { 0, 0, 0, 0, 0, 0, 0 } })

    table.remove(data.destinations, 1)
end
timer.register("firemoth:pathingController", update)

---@param reference tes3reference
---@param destinations number[][]
function this.startPathing(reference, destinations)
    timer.start({
        reference = reference,
        iterations = -1,
        duration = 0.25,
        callback = "firemoth:pathingController", ---@diagnostic disable-line
        persist = true,
        data = { reference = reference.id, destinations = destinations },
    })
end

return this
