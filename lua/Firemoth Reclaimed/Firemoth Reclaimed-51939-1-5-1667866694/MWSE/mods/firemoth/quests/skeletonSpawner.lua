local utils = require("firemoth.utils")

local this = {}

local MAX_SKELETONS = 12

local TIME_BEFORE_RESPAWN = 10


local SKELETON_OBJECTS = {
    [tes3.getObject("fm_skeleton_1")] = --[[Anim Duration]] 7.7,
    [tes3.getObject("fm_skeleton_2")] = --[[Anim Duration]] 6.2,
}

local SKELETON_SPAWNERS = {
    [tes3.getObject("fm_skeleton_spawner")] = true,
}

local SKELETON_SOUNDS = {
    [tes3.getSound("tew_fm_skelerise")] = true,
}

local SKELETON_VFX = {
    [tes3.getObject("fm_skeleton_rising_vfx")] = true,
}

---@type table<tes3reference, boolean>
this.spawners = {}

---@type table<tes3reference, boolean>
this.skeletons = {}

---@type table<tes3reference, boolean>
this.corpses = {}

---@type mwseTimer
local spawnTimer = nil

local randomSkeletonObject = utils.math.nonRepeatTableRNG(table.keys(SKELETON_OBJECTS))
local randomSkeletonSound = utils.math.nonRepeatTableRNG(table.keys(SKELETON_SOUNDS))
local randomSkeletonVFX = utils.math.nonRepeatTableRNG(table.keys(SKELETON_VFX))


local function getAvailableSpawners(timestamp)
    local spawners = {}
    for spawner in pairs(this.spawners) do
        local time = spawner.data.fm_spawnTime or math.fhuge
        if math.abs(timestamp - time) >= TIME_BEFORE_RESPAWN then
            spawners[spawner] = true
        end
    end
    return spawners
end


local function resetSpawnerTimes()
    for spawner in pairs(this.spawners) do
        spawner.data.fm_spawnTime = nil
    end
end


local function isSkeleton(reference)
    return SKELETON_OBJECTS[reference.baseObject] ~= nil
end


local function attackClosestHuman(skeleton)
    local nearbyActors = tes3.findActorsInProximity({ reference = skeleton, range = 1024 })

    local humans = {}
    for _, actor in pairs(nearbyActors) do
        if not actor.isDead
            and not isSkeleton(actor.reference)
            and not actor.reference.data.fm_skeletonsIgnore
        then
            humans[actor.reference] = true
        end
    end

    if next(humans) then
        local closest = utils.math.getClosestReference(skeleton.position, humans)
        skeleton.mobile:startCombat(closest.mobile)
    end
end


local function cleanCorpses()
    -- For performance, if the amount of corpses is too high just delete them.
    if table.size(this.corpses) >= MAX_SKELETONS * 2 then
        local corpse = utils.math.getFarthestReference(tes3.player.position, this.corpses)
        if corpse then
            corpse:disable()
            corpse:delete()
        end
    end
    return true
end


local function cleanSkeletons()
    -- If we're at the max number of skeletons then 'respawn' the farthest one.
    -- Otherwise player can just spawn all skeletons on an island and ditch it.
    if table.size(this.skeletons) >= MAX_SKELETONS then
        local skeleton, distance = utils.math.getFarthestReference(tes3.player.position, this.skeletons)
        if distance <= 1024 then
            return false
        end
        skeleton:disable()
        skeleton:delete()
    end
    return true
end


local function getSpawningPosition()
    -- Override position during quest battle, unless we're too far away.
    local override = tes3.player.data.fm_skeletonSpawnerPosition
    if override then
        override = tes3vector3.new(unpack(override))
        if override:distance(tes3.player.position) <= 2048 then
            return override
        end
    end
    -- Spawn slightly forward, so that we can visually see them rising.
    return tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector() * 256
end


local function spawnSkeleton()
    if tes3.player.data.fm_skeletonSpawnerDisabled then
        return
    end

    local position = getSpawningPosition()
    local timestamp = tes3.getSimulationTimestamp(false) ---@diagnostic disable-line
    local spawner = utils.math.getClosestReference(position, getAvailableSpawners(timestamp))
    if not spawner then
        resetSpawnerTimes()
        return
    end

    -- bail if we've got too much shit active.
    if not cleanCorpses() or not cleanSkeletons() then
        return
    end

    local skeleton = tes3.createReference({
        object = randomSkeletonObject(),
        position = spawner.position,
        cell = spawner.cell,
    })
    attackClosestHuman(skeleton)

    skeleton.position = spawner.position
    skeleton.orientation.z = math.rad(math.random(360))

    tes3.playAnimation({
        reference = skeleton,
        group = tes3.animationGroup.idle9,
        loopCount = 0,
    })

    tes3.playSound({
        sound = randomSkeletonSound(),
        reference = skeleton,
        mixChannel = tes3.soundMix.master,
        volume = 1.0,
    })

    tes3.createVisualEffect({
        object = randomSkeletonVFX(),
        lifespan = 20.0,
        position = skeleton.position,
    })

    -- Workaround for skeletons turning during animation playback. Yuck.
    local animDuration = assert(SKELETON_OBJECTS[skeleton.baseObject])
    tes3.applyMagicSource({
        reference = skeleton,
        bypassResistances = true,
        effects = { { id = tes3.effect.paralyze, min = 100, max = 100, duration = animDuration } },
        name = "Skeleton Rising",
    })

    -- We use the timestamp to avoid repeat spawns from the same spawner.
    spawner.data.fm_spawnTime = timestamp
end
event.register(tes3.event.loaded, function()
    spawnTimer = timer.start({ iterations = -1, duration = 1.0, callback = spawnSkeleton })
    spawnTimer:pause()
    do
        -- Fix skeletons that were in the middle of animation when save/reload.
        for _, cell in pairs(tes3.getActiveCells()) do
            for ref in cell:iterateReferences(tes3.objectType.creature) do
                if isSkeleton(ref) and not ref.isDead then
                    if tes3.getAnimationGroups({ reference = ref }) == tes3.animationGroup.idle9 then
                        tes3.playAnimation({ reference = ref, group = tes3.animationGroup.idle })
                        tes3.removeEffects({ reference = ref, effect = tes3.effect.paralyze })
                        this.skeletons[ref] = true
                    end
                end
            end
        end
    end
end)


---@param e cellChangedEventData
local function enteredFiremoth(e)
    local isFiremoth = utils.cells.isFiremothCell(e.cell)
    local wasFiremoth = utils.cells.isFiremothCell(e.previousCell)
    if isFiremoth and not wasFiremoth then
        spawnTimer:resume()
    elseif wasFiremoth and not isFiremoth then
        spawnTimer:pause()
    end
end
event.register(tes3.event.cellChanged, enteredFiremoth)


---@param e referenceActivatedEventData|mobileActivatedEventData
local function onReferenceCreated(e)
    local object = e.reference.baseObject
    if object == nil then
        return
    end

    if SKELETON_SPAWNERS[object] then
        this.spawners[e.reference] = true
        return
    end

    if SKELETON_OBJECTS[object] then
        if e.reference.isDead then
            this.corpses[e.reference] = true
        else
            this.skeletons[e.reference] = true
        end
        return
    end
end
event.register(tes3.event.mobileActivated, onReferenceCreated)
event.register(tes3.event.referenceActivated, onReferenceCreated)


---@param e referenceDeactivatedEventData|objectInvalidatedEventData
local function onReferenceDeleted(e)
    this.spawners[e.reference or e.object] = nil
    this.skeletons[e.reference or e.object] = nil
    this.corpses[e.reference or e.object] = nil
end
event.register(tes3.event.referenceDeactivated, onReferenceDeleted)
event.register(tes3.event.objectInvalidated, onReferenceDeleted)


---@param e deathEventData
local function onDeath(e)
    local object = e.reference.baseObject
    if SKELETON_OBJECTS[object] then
        this.skeletons[e.reference] = nil
        this.corpses[e.reference] = true
    end
end
event.register(tes3.event.death, onDeath)

return this
