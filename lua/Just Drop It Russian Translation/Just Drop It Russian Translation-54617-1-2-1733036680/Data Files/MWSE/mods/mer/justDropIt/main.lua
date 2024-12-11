local common = require("mer.justDropIt.common")
local config = require('mer.justDropIt.config')
local orient = require("mer.justDropIt.orient")

local modName = config.modName

local deathAnimations = {
    [tes3.animationGroup.deathKnockDown] = true,
    [tes3.animationGroup.deathKnockOut] = true,
    [tes3.animationGroup.death1] = true,
    [tes3.animationGroup.death2] = true,
    [tes3.animationGroup.death3] = true,
    [tes3.animationGroup.death4] = true,
    [tes3.animationGroup.death5] = true,
}
local validObjectTypes = {
    [tes3.objectType.creature]=true,
    [tes3.objectType.npc]=true
}

--Initialisation
local function onItemDrop(e)
    if config.mcmConfig.enabled then
        common.logger:debug("Orienting %s on itemDropped", e.reference)
        orient.orientRefToGround{ ref = e.reference, offset = 0}
    end
end
event.register("itemDropped", onItemDrop, { priority = 10 })

---@param e playGroupEventData
local function onNPCDying(e)
    if config.mcmConfig.enabled and config.mcmConfig.orientOnDeath then
        if deathAnimations[e.group] then
            if not e.reference.data.justDropItOrientedOnDeath then
                common.logger:debug("Orienting %s on death", e.reference)
                local result = orient.getGroundBelowRef({ref = e.reference, offset = 0})
                if result then
                    orient.orientRef(e.reference, result)
                    e.reference.data.justDropItOrientedOnDeath = true
                end
            end
        end
    end
end
event.register("playGroup", onNPCDying)

--Reset orientation when ref is resurrected manually
---@param e mobileActivatedEventData
local function onRefResurrected(e)
    if validObjectTypes[e.reference.baseObject.objectType] then
        common.logger:debug("Restoring vertical orientation of %s on referenceActivated", e.reference)
        orient.resetXYOrientation(e.reference)
        e.reference.data.justDropItOrientedOnDeath = nil
    end
end
event.register("mobileActivated", onRefResurrected)

---@param object tes3object|tes3light
local function isCarryable(object)
    local unCarryableTypes = {
        [tes3.objectType.light] = true,
        [tes3.objectType.container] = true,
        [tes3.objectType.static] = true,
        [tes3.objectType.door] = true,
        [tes3.objectType.activator] = true,
        [tes3.objectType.npc] = true,
        [tes3.objectType.creature] = true,
    }
    if object then
        if object.canCarry then
            return true
        end
        local objType = object.objectType
        if unCarryableTypes[objType] then
            return false
        end
        return true
    end
end

--Determine ref width using bounding box
---@param reference tes3reference
---@return number
local function getMaxWidth(reference)
    local bbox = reference.object.boundingBox
    local width = math.max(
        bbox.max.x - bbox.min.x,
        bbox.max.y - bbox.min.y,
        bbox.max.z - bbox.min.z
    )
    return width
end



---@param reference tes3reference
local function dropNearbyObjects(reference, processedRefs)
    processedRefs = processedRefs or {}
    processedRefs[reference] = true
    common.logger:debug("Dropping nearby objects for %s", reference)
    local nearbyRefs = {}
    for _, cell in pairs( tes3.getActiveCells() ) do
        for nearbyRef in cell:iterateReferences() do
            if not processedRefs[nearbyRef] then
                if isCarryable(nearbyRef.baseObject) then
                    local closeEnough = orient.getCloseEnough{
                        ref1 = reference,
                        ref2 = nearbyRef,
                        distHorizontal = getMaxWidth(reference)
                    }
                    if closeEnough then
                        table.insert(nearbyRefs, nearbyRef)
                    end
                end
            end
        end
    end

    --Sort from lowest to heighest
    table.sort(nearbyRefs, function(a, b)
        return a.position.z < b.position.z
    end)
    for _, nearbyRef in pairs(nearbyRefs) do
        common.logger:debug("Dropping %s near %s", nearbyRef.id, reference.id)
        local result = orient.getGroundBelowRef({ref = nearbyRef, offset = 0})
        if result and result.reference == reference then
            local safeParent = tes3.makeSafeObjectHandle(reference)
            local parentZ = reference.position.z
            local safeRef = tes3.makeSafeObjectHandle(nearbyRef)
            timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()timer.delayOneFrame(function()
                if safeParent and safeParent:valid() and math.isclose(parentZ, reference.position.z) then
                    common.logger:debug("Parent %s still exists and wasn't moved, don't bother dropping children", reference.id)
                    return
                end
                if safeRef and safeRef:valid() then
                    dropNearbyObjects(nearbyRef, processedRefs)
                    orient.orientRefToGround{ref = nearbyRef, ignoreBlackList = true, offset = 0}
                end
            end)end)end)end)end)end)
        else
            common.logger:debug("Raytest from %s didn't return original reference %s, hit %s instead", nearbyRef, reference.id, result and result.reference)
        end
    end
end

---@param e activateEventData
local function onActivate(e)
    if isCarryable(e.target.object) then
        dropNearbyObjects(e.target)
    end
end
event.register("activate", onActivate, {priority = 1000})

--MCM MENU
local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Просто брось это" }
    template:saveOnClose(modName, config.mcmConfig)
    template:register()

    local settings = template:createSideBarPage("Настройки")
    settings.description = config.modDescription

    settings:createOnOffButton{
        label = string.format("Включить \"Просто брось это\""),
        description = "Включить\\Выключить мод",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config.mcmConfig}
    }

    settings:createDropdown{
        label = "Уровень журнала",
        description = "Выберите уровень ведения журнала событий mwse.log. Оставьте INFO, если не проводите отладку",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcmConfig },
        callback = function(self)
            common.logger:setLogLevel(self.variable.value)
        end
    }

    settings:createOnOffButton{
        label = "Ориентация трупов",
        description = "Ориентирует трупы существ и NPC, когда они умирают. Анимация смерти в Морровинде очень глючная, и этот параметр не исправляет всех ошибок. Так что не жалуйтесь мне, когда скальный наездник проваливается сквозь скалу или гуар зависает на высоте 3 футов над ней. Это ванильные ошибки, и я мало что могу сделать!",
        variable = mwse.mcm.createTableVariable{id = "orientOnDeath", table = config.mcmConfig}
    }

    settings:createOnOffButton{
        label = string.format("Игнорировать ориентацию на нестатичный грунт"),
        description = "Если эта опция включена, элементы будут оставаться в вертикальном положении при размещении на нестатической сетке. По умолчанию: Выкл.",
        variable = mwse.mcm.createTableVariable{id = "noOrientNonStatic", table = config.mcmConfig}
    }

    settings:createSlider{
        label = "Максимальный угол наклона для плоских объектов",
        description = "Эта опция определяет, на сколько градусов будет повернут объект, чтобы сориентировать его относительно земли, на которой он находится. Это относится к объектам, чья высота меньше ширины и глубины. Рекомендуется: 40",
        variable = mwse.mcm.createTableVariable{ id = "maxSteepnessFlat", table = config.mcmConfig},
        max = 180
    }

    settings:createSlider{
        label = "Максимальный угол наклона для высоких объектов",
        description = "Эта опция определяет, на сколько градусов будет повернут объект, чтобы сориентировать его относительно земли, на которой он находится. Это относится к объектам, чья высота больше ширины или глубины. Рекомендуется: 5",
        variable = mwse.mcm.createTableVariable{ id = "maxSteepnessTall", table = config.mcmConfig},
        max = 180
    }


    template:createExclusionsPage{
        label = "Черный список модов",
        description = "Добавьте плагины в черный список, что бы все содержащиеся в них объекты, не затрагивались этим модом. ",
        variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config.mcmConfig},
        filters = {
            {
                label = "Плагины",
                type = "Plugin"
            }
        }
    }
end
event.register("modConfigReady", registerModConfig)

