local config = require("Less Annoying Solstheim Rumors & Delay.config")

local function manageNpc()
    local louisBeauchamp = tes3.getReference("louis beauchamp")

    local shouldExist = tes3.player.object.level >= config.requiredPlayerLevel
    if shouldExist and louisBeauchamp.disabled then
        louisBeauchamp:enable()
    elseif not shouldExist and not louisBeauchamp.disabled then
        louisBeauchamp:disable()
        louisBeauchamp.modified = false -- не записываем в сейв, чтобы мод удалялся без очистки.
    end
end

local function onLoaded()
    manageNpc()
end
event.register("loaded", onLoaded)

local function onLevelUp()
    manageNpc()
end
event.register(tes3.event.levelUp, onLevelUp)

-- Но тогда требуется восстанавливать Луи до loaded, чтобы игра не пыталась взять анимацию у disabled
local function onLoad()
    tes3.getReference("louis beauchamp"):enable()
end
event.register("load", onLoad)
-- Но это приведет к появлению Луи в текущей игре, когда пытаешься загрузить сохранение,
-- в котором различаются мастер-файлы
-- (событие load сработало, но ты еще можешь нажать отмену загрузки, и остаться в игре)