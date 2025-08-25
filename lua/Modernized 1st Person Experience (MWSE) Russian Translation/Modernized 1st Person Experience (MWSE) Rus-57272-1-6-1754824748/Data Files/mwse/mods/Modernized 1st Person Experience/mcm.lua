--[[
	Mod: Modernized 1st Person Experience
	Author: rhjelte
	Version: 1.6
]]--


local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("Modernized 1st Person Experience.config").loaded
local defaultConfig = require("Modernized 1st Person Experience.config").default
local configPath = "Modernized 1st Person Experience"
local modName = ("Улучшенный вид от первого лица")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(configPath, config)
template:register()

local common = require("Modernized 1st Person Experience.common")


local page = template:createSideBarPage({
    label = "Основные настройки",
    description = "Версия 1.6\n\nЭтот мод добавляет естественное покачивание головы, наклон камеры при движении и \"шум\" камеры при перемещении по миру. Покачивание головы имеет разную амплитуду для ходьбы, бега, режима скрытности, плавания и левитации.\n\nМод также синхронизирует шаги с движением головы (можно отключить), совместим с Character Sound Overhaul, Abot's Footprints и другими.\n\nТакже включает плавное движение камеры при входе и выходе из режима скрытности,инерцию тела и механику выглядывания из-за укрытия.",
    showReset = true
})

------------------------------------------------------------------------------------------------------------------------------- Main tweaks
local settings = page:createCategory ("Улучшенный вид от первого лица - Основные настройки")

settings:createOnOffButton{
    label = "Включить мод",
    description = "Включить или выключить мод.",
    defaultSetting = defaultConfig.modEnabled,
    showDefaultSetting = true,
    callback = function()
        common.updateSneakSettingsFromMenu()
    end,
    variable = mwse.mcm.createTableVariable{
        id = "modEnabled",
        table = config
    }
}

settings:createSlider{
    label = "Плавность переключения эффектов",
    description = "Меньшее значение означает более медленный переход. Большее значение означает более резкий переход.\n\nЭто значение определяет, насколько плавными будут переходы при начале и прекращении покачивания головой, а также при переходе между ходьбой, бегом и режимом скрытности.",
    max = 20,
    min = 5,
    defaultSetting = defaultConfig.smoothValue,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "smoothValue",
        table = config
    }
}

settings:createSlider{
    label = "Минимальная дистанция фокусировки",
    description = "При покачивании головы используется функция стабилизации зрения (камера поворачивается в направлении точки, на которую указывает перекрестие), чтобы изображение выглядело более естественным. На очень близких расстояниях углы поворота становятся резкими, что делает эффект чрезмерным.\n\nЭто значение определяет, каким может быть кратчайшее расстояние до точки фокусировки, чтобы избежать слишком резких движений. Любая точка, расположенная ближе этого значения, будет использовать для вращения фокусную точку с указанным значением.",
    max = 500,
    min = 100,
    defaultSetting = defaultConfig.minimumLookAtDistance,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "minimumLookAtDistance",
        table = config
    }
}

settings:createSlider{
    label = "Частота покачивания головы",
    description = "Это множитель, определяющий частоту покачивания головы в игре. Значение 100 соответствует 100%.",
    max = 150,
    min = 50,
    defaultSetting = defaultConfig.bobCustomizableFrequencyMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "bobCustomizableFrequencyMultiplier",
        table = config
    }
}

settings:createSlider{
    label = "Амплитуда покачивания головы",
    description = "Это множитель, который определяет амплитуду покачивания головы в игре. Значение 100 соответствует 100%.",
    max = 150,
    min = 50,
    defaultSetting = defaultConfig.bobCustomizableAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "bobCustomizableAmplitudeMultiplier",
        table = config
    }
}

settings:createSlider{
    label = "Множитель амплитуды покачивания рук",
    description = "При значении 100 руки почти не двигаются. При значении 0 очень заметные движения рук.\n\nПоскольку руки расположены очень близко к камере, эффект от их движения, без корректировки, будет очень сильным. Чтобы компенсировать это, руки покачиваются в соответствии с камерой, но с амплитудой, которая в процентном отношении меньше амплитуды движения камеры.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.armAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armAmplitudeMultiplier",
        table = config
    }
}

settings:createOnOffButton{
    label = "Включить эффекты для вида от 3-го лица",
    description = "Включает/выключает эффекты покачивания головой, прыжков, вращения камеры, выглядывания из-за угла и все остальное, совместимое с видом от третьего лица, при использовании камеры от третьего лица.\n\nХотя мод ориентирован на вид от первого лица, я сделал всё максимально совместимым и с видом от третьего лица. Рекомендуется включить для более динамичного игрового процесса.",
    defaultSetting = defaultConfig.thirdPersonBobEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "thirdPersonBobEnabled",
        table = config
    }
}

settings:createSlider{
    label = "Множитель амплитуды покачивания камеры от третьего лица",
    description = "Множитель, который по умолчанию уменьшает эффект покачивания головы при виде от третьего лица. Значение по умолчанию меньше, так как эффект от третьего лица кажется более выраженным. Не действует, если эффекты камеры от третьего лица отключены. 50 означает 50% от амплитуды покачивания головы при виде от первого лица.",
    max = 100,
    min = 10,
    defaultSetting = defaultConfig.thirdPersonBobMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "thirdPersonBobMultiplier",
        table = config
    }
}

settings:createOnOffButton{
    label = "Синхронизация шагов с покачиванием головы",
    description = "Включает/выключает управление воспроизведением звука шагов в режиме от первого лица. Полностью совместимо с Character Sound Overhaul и оригинальной игрой.\n\nНастоятельно рекомендуется включить эту опцию, если она не создает ошибок в других модах. Без неё звуки шагов и покачивание головы будут рассинхронизированы.",
    defaultSetting = defaultConfig.syncFootsteps,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "syncFootsteps",
        table = config
    }
}

settings:createOnOffButton{
    label = "Эффект прыжка",
    description = "Включает/выключает небольшой наклон камеры при прыжках (аналог покачивания головы для прыжков).",
    defaultSetting = defaultConfig.jumpEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpEnabled",
        table = config
    }
}


settings:createOnOffButton{
    label = "Наклон камеры (при движении вбок)",
    description = "Если эта функция включена, камера будет наклоняться в сторону движения при движении игрока влево или вправо, чтобы усилить ощущение перемещения. Может вызывать тошноту, отключите при необходимости",
    defaultSetting = defaultConfig.viewRollingEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "viewRollingEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "\"Шум\" камеры (шум Перлина)",
    description = "Добавляет легкое (настраиваемое) случайное движение камеры, имитирующее дыхание и естественную неустойчивость. Использует образцы шума Перлина, генерируемые при запуске.",
    defaultSetting = defaultConfig.noiseEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "noiseEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Инерция тела (руки следуют за камерой)",
    description = "Если эта функция включена, руки плавно следуют за движениями камеры, создавая эффект инерции.",
    defaultSetting = defaultConfig.bodyInertiaEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "bodyInertiaEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Плавный переход в режим скрытности",
    description = "Включает/выключает плавное изменение высоты камеры при переходе в режим скрытности.\n\nЛюбой другой мод, изменяющий положение камеры, будет работать только если данная функция выключена.",
    defaultSetting = defaultConfig.sneakCameraSmoothingEnabled,
    showDefaultSetting = true,
    callback = function()
        common.updateSneakSettingsFromMenu()
    end,
    variable = mwse.mcm.createTableVariable{
        id = "sneakCameraSmoothingEnabled",
        table = config
    }
}

settings:createOnOffButton{
    label = "Механика выглядывания из-за укрытия",
    description = "Включает/выключает возможность выглядывания из-за укрытия. NPC не должны видеть вас за укрытием, даже когда вы выглядываете из-за него.\n\nВо время выглядывания вы не можете двигаться, но можете свободно осматриваться. После завершения выглядывания (если вы от первого лица) камера вернется в положение, в котором она была, когда вы выглянули.",
    defaultSetting = defaultConfig.peekEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekEnabled",
        table = config
    }
}

local cornerPeekKeyBinds = settings:createCategory("Горячие клавиши выглядывания")

cornerPeekKeyBinds:createKeyBinder{
    label = "Клавиша выглядывания влево",
    description = "Удерживайте нажатой, что бы выглянуть влево. Работает только при включенной механике выглядывания.",
    allowCombinations = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekLeftKey",
        table = config
    }
}

cornerPeekKeyBinds:createKeyBinder{
    label = "Клавиша выглядывания вправо",
    description = "Удерживайте нажатой, что бы выглянуть вправо. Работает только при включенной механике выглядывания.",
    allowCombinations = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekRightKey",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Detailed bobbing tweaks
local detailTweaks = template:createSideBarPage({
    label = "Детальные настройки",
    description = "Настройки множителей для разных типов движения и осей для точной регулировки покачивания головы.",
    showReset = true
})

local walkingTweaks = detailTweaks:createCategory ("Настройки ходьбы")

walkingTweaks:createSlider{
    label = "Ходьба - множитель вертикальной амплитуды",
    description = "Это множитель, определяющий величину вертикальной амплитуды (движения вверх и вниз) при ходьбе. 100 означает значение по умолчанию, 50 — 50% от значения по умолчанию и т.д.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.walkingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "walkingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

walkingTweaks:createSlider{
    label = "Ходьба - множитель горизонтальной амплитуды",
    description = "Это множитель, определяющий величину горизонтальной амплитуды (движения из стороны в сторону) при ходьбе. 100 означает значение по умолчанию, 50 — 50% от значения по умолчанию и т.д.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.walkingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "walkingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

local sneakingTweaks = detailTweaks:createCategory ("Настройки скрытности")

sneakingTweaks:createSlider{
    label = "Скрытность — множитель вертикальной амплитуды",
    description = "Это множитель, определяющий величину вертикальной амплитуды (движения вверх и вниз) в режиме скрытности. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nПо умолчанию перемещение в режиме скрытности имеет гораздо менее выраженные движения вверх и вниз, имитирующие скрытные осторожные движения",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.sneakingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

sneakingTweaks:createSlider{
    label = "Скрытность — множитель горизонтальной амплитуды",
    description = "Это множитель, определяющий величину горизонтальной амплитуды (движения из стороны в сторону) в режиме скрытности. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nПо умолчанию перемещение в режиме скрытности имеет гораздо менее выраженные движения из стороны в сторону, имитирующие скрытные осторожные движения",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.sneakingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

sneakingTweaks:createSlider{
    label = "Множитель частоты покачивания головы в режиме скрытности",
    description = "Это множитель, определяющий частоту покачивания головы (относительно частоты покачивания при ходьбе и беге) в режиме скрытности. Значение 75 соответствует 75% от обычной частоты покачивания головы.",
    max = 100,
    min = 50,
    defaultSetting = defaultConfig.sneakFrequencyMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakFrequencyMultiplier",
        table = config
    }
}

local runningTweaks = detailTweaks:createCategory ("Настройки бега")

runningTweaks:createSlider{
    label = "Бег — множитель вертикальной амплитуды",
    description = "Это множитель, определяющий величину вертикальной амплитуды (движения вверх и вниз) при беге. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nБег по умолчанию — это более выраженное движение как в вертикальном, так и в горизонтальном направлении по сравнению с ходьбой.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.runningCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "runningCustomizableAmplitudeMultiplierY",
        table = config
    }
}

runningTweaks:createSlider{
    label = "Бег - множитель горизонтальной амплитуды",
    description = "Это множитель, определяющий величину горизонтальной амплитуды (движения из стороны в сторону) при беге. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nБег по умолчанию — это более выраженное движение как в вертикальном, так и в горизонтальном направлении по сравнению с ходьбой.",
    max = 200,
    min = 0,
    defaultSetting = defaultConfig.runningCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "runningCustomizableAmplitudeMultiplierX",
        table = config
    }
}

local levitationTweaks = detailTweaks:createCategory ("Настройки левитации")

levitationTweaks:createSlider{
    label = "Левитация - множитель вертикальной амплитуды",
    description = "Это множитель, определяющий величину вертикальной амплитуды (движения вверх и вниз) при левитации. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nПо умолчанию левитация — это немного более выраженное движение как в вертикальном, так и в горизонтальном направлении по сравнению с ходьбой.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.flyingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

levitationTweaks:createSlider{
    label = "Левитация - множитель горизонтальной амплитуды",
    description = "Это множитель, определяющий величину горизонтальной амплитуды (движения из стороны в сторону) при левитации. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nПо умолчанию левитация — это немного более выраженное движение как в вертикальном, так и в горизонтальном направлении по сравнению с ходьбой.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.flyingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

levitationTweaks:createSlider{
    label = "Левитация — множитель частоты при неподвижности",
    description = "Если вы не двигаетесь в режиме левитации, ваша голова все равно будет немного покачиваться. Этот множитель определяет, насколько сильно, относительно значения по умолчанию.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.flyingFrequencyMultiplierStill,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingFrequencyMultiplierStill",
        table = config
    }
}

levitationTweaks:createSlider{
    label = "Левитация — множитель частоты при движении",
    description = "Это множитель, определяющий частоту покачивания головы при левитации относительно частоты обычного покачивания при ходьбе.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.flyingFrequencyMultiplierMoving,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingFrequencyMultiplierMoving",
        table = config
    }
}

local swimmingTweaks = detailTweaks:createCategory ("Настройки плавания")

swimmingTweaks:createSlider{
    label = "Плавание - множитель вертикальной амплитуды",
    description = "Это множитель, определяющий величину вертикальной амплитуды (движения вверх и вниз) при плавании. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nПлавание по умолчанию — это немного более выраженное движение как в вертикальном, так и в горизонтальном направлении по сравнению с ходьбой.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.swimmingCustomizableAmplitudeMultiplierY,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingCustomizableAmplitudeMultiplierY",
        table = config
    }
}

swimmingTweaks:createSlider{
    label = "Плавание — множитель горизонтальной амплитуды",
    description = "Это множитель, определяющий величину горизонтальной амплитуды (движения из стороны в сторону) при плавании. 100 означает значение по умолчанию, 50 означает 50% от значения по умолчанию и т.д.\n\nПлавание по умолчанию — это немного более выраженное движение как в вертикальном, так и в горизонтальном направлении по сравнению с ходьбой.",
    max = 400,
    min = 0,
    defaultSetting = defaultConfig.swimmingCustomizableAmplitudeMultiplierX,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingCustomizableAmplitudeMultiplierX",
        table = config
    }
}

swimmingTweaks:createSlider{
    label = "Плавание — множитель частоты при неподвижности",
    description = "Если вы не двигаетесь в режиме плавания, ваша голова все равно будет немного покачиваться. Этот множитель определяет, насколько сильно, относительно значения по умолчанию.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.swimmingFrequencyMultiplierStill,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingFrequencyMultiplierStill",
        table = config
    }
}

swimmingTweaks:createSlider{
    label = "Плавание — множитель частоты при движении",
    description = "Это множитель, определяющий частоту покачивания головы при плавании относительно частоты обычного покачивания при ходьбе.",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.swimmingFrequencyMultiplierMoving,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingFrequencyMultiplierMoving",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Perlin noise settings
local perlinNoiseTweaks = template:createSideBarPage({
    label = "Настройки шума Перлина",
    description = "Настройки влияния шума Перлина на движение камеры. Эти настройки не действуют, если функция шум камеры отключена.\n\nФункцию шум камеры можно включить/выключить на вкладке основных настроек.",
    showReset = true
})

perlinNoiseTweaks:createSlider{
    label = "Скорость шума",
    description = "Скорость движения камеры при выборке из шумового цикла. Чем выше значение, тем быстрее движение.",
    max = 5,
    min = 0.1,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.noiseScale,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "noiseScale",
        table = config
    }
}

perlinNoiseTweaks:createSlider{
    label = "Амплитуда шума",
    description = "Величина движения камеры при выборке из шумового цикла. Чем выше значение, тем сильнее движение",
    max = 5,
    min = 0.01,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.noiseAmplitude,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "noiseAmplitude",
        table = config
    }
}

perlinNoiseTweaks:createSlider{
    label = "Множитель амплитуды шума при левитации",
    description = "Это множитель, определяющий величину усиления шума при левитации. 100 соответствует значению по умолчанию, 50 — 50% от значения по умолчанию и т.д.",
    max = 400,
    min = 50,
    step = 1,
    defaultSetting = defaultConfig.flyingNoiseAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "flyingNoiseAmplitudeMultiplier",
        table = config
    }
}

perlinNoiseTweaks:createSlider{
    label = "Множитель амплитуды шума при плавании",
    description = "Это множитель, определяющий величину усиления шума при плавании. 100 соответствует значению по умолчанию, 50 — 50% от значения по умолчанию и т.д.",
    max = 400,
    min = 50,
    step = 1,
    defaultSetting = defaultConfig.swimmingNoiseAmplitudeMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "swimmingNoiseAmplitudeMultiplier",
        table = config
    }
}
------------------------------------------------------------------------------------------------------------------------------- Body inertia settings
local page = template:createSideBarPage({
    label = "Настройки инерции тела",
    description = "Инерция тела определяет, насколько быстро руки следуют за движением камеры.",
    showReset = true
})

local bodyInertiaSettings = page:createCategory ("Настройки инерции тела")

bodyInertiaSettings:createSlider{
    label = "Скорость инерции тела",
    description = "Чем меньше значение, тем медленнее руки следуют за телом, чем больше значение, тем быстрее.",
    max = 1000,
    min = 50,
    step = 1,
    defaultSetting = defaultConfig.armSpeed,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armSpeed",
        table = config
    }
}

bodyInertiaSettings:createSlider{
    label = "Максимальный угол поворота рук.",
    description = "При движении влево или вправо руки немного поворачиваются, имитируя инерцию при движении. Это значение определяет максимальный угол поворота рук.",
    max = 15,
    min = 0.01,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.armMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armMaxAngle",
        table = config
    }
}

bodyInertiaSettings:createSlider{
    label = "Плавность поворота рук",
    description = "Определяет скорость поворота рук при повороте и возврата в исходное положение. Чем выше значение, тем более резким будет движение, чем ниже, тем плавнее.",
    max = 20,
    min = 0.01,
    step = 0.01,
    decimalPlaces = 2,
    defaultSetting = defaultConfig.armRollingSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "armRollingSmoothing",
        table = config
    }
}

bodyInertiaSettings:createSlider{
    label = "Плавность камеры от первого лица",
    description = "Чтобы инерция тела выглядела плавной, необходимо сглаживать и движения камеры. Это значение определяет, насколько плавной должна быть камера. Низкое значение означает более плавное движение, высокое — более резкое.",
    max = 750,
    min = 400,
    step = 1,

    defaultSetting = defaultConfig.firstPersonCameraSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "firstPersonCameraSmoothing",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- View rolling settings
local viewRollingDetailedTweak = template:createSideBarPage({
    label = "Настройки наклона камеры",
    description = "Наклон камеры - это когда камера кренится в сторону движения. Здесь можно настроить детали этой функции.",
    showReset = true
})

viewRollingDetailedTweak:createSlider{
    label = "Максимальный угол наклона",
    description = "Максимальный угол, на который может наклониться камера влево/вправо. Не действует, если наклон камеры отключен.",
    max = 2,
    min = 0.1,
    step = 0.1,
    decimalPlaces = 1,
    defaultSetting = defaultConfig.viewRollingMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "viewRollingMaxAngle",
        table = config
    }
}

viewRollingDetailedTweak:createSlider{
    label = "Плавность наклона",
    description = "Высокие значения = более резкое движение. Низкие = более плавное. Определяет насколько плавным будет движение при наклоне камеры. Не действует, если наклон камеры отключен.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.viewRollingSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "viewRollingSmoothing",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Corner peeking settings
local cornerPeekingDetailSettings = template:createSideBarPage({
    label = "Настройки выглядывания из-за укрытия",
    description = "Выглядывание из-за укрытия позволяет вам заглядывать за угол или другое препятствие как от первого, так и от третьего лица.",
    showReset = true
})

cornerPeekingDetailSettings:createSlider{
    label = "Плавность выглядывания",
    description = "Высокие значения = более резкое движение. Низкие = более плавное. Определяет насколько плавным будет движение при переходе камеры в режим выглядывания. Не действует, если выглядывание отключено.",
    max = 15,
    min = 1,
    defaultSetting = defaultConfig.peekSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekSmoothing",
        table = config
    }
}

cornerPeekingDetailSettings:createSlider{
    label = "Расстояние выглядывания",
    description = "Расстояние, на которое перемещается камера при нажатии кнопки выглядывания.",
    max = 75,
    min = 20,
    defaultSetting = defaultConfig.peekLength,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekLength",
        table = config
    }
}

cornerPeekingDetailSettings:createSlider{
    label = "Угол наклона при выглядывании",
    description = "Угол наклона камеры при выглядывании.",
    max = 15,
    min = 0,
    defaultSetting = defaultConfig.peekRotation,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "peekRotation",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Jumping and landing settings
local jumpingPage = template:createSideBarPage({
    label = "Настройки прыжков",
    description = "Детальные настройки механики прыжков. Я постарался сделать их максимально простыми для понимания, но они немного более техничны из-за особенностей работы функции изменения наклона во время прыжка. Не стесняйтесь экспериментировать и найдите то, что подходит именно вам.\n\nПо умолчанию настройки выставлены, что бы давать хорошую обратную связь даже при низком уровне акробатики, без чрезмерных эффектов при использовании Свитков Полета Икара, и в то же время давать некоторое ощущение динамик при прыжках на разном уровне.",
    showReset = true
})

jumpingPage:createSlider{
    label = "Максимальная скорость прыжка",
    description = "Это значение определяет, при какой скорости прыжка (в единицах в секунду) наклон камеры достигнет 100% от максимального. Обратите внимание, что это значение влияет только на эффект наклона. Оно никак не влияет на фактическую скорость прыжка в игре.\n\nБолее высокое значение приведет к тому, что эффект прыжка будет отображаться в более широком диапазоне значений. Проще говоря, это означает, что при низком значении, будет более заметный эффект при низкой скорости. При высоком значении, будет большая разница эффекта между прыжками с низкой и высокой скоростью, но менее заметный эффект при низкой скорости.",
    max = 0.5,
    min = 0.1,
    decimalPlaces = 2,
    step = 0.01,
    defaultSetting = defaultConfig.jumpVelocityMax,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpVelocityMax",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Максимальный угол наклона при прыжке",
    description = "Максимальный угол наклона камеры вниз при прыжке. Постепенно (зависит от скорости прыжка) уменьшается до 0, по мере достижения вершины прыжка.",
    max = 10,
    min = 4,
    decimalPlaces = 1,
    step = 0.1,
    defaultSetting = defaultConfig.jumpMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpMaxAngle",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Максимальный угол наклона при приземлении",
    description = "Максимальный угол наклона камеры при приземлении. Чем быстрее падение (до значения максимальной скорости прыжка), тем больше угол наклона при приземлении.",
    max = 10,
    min = 4,
    decimalPlaces = 1,
    step = 0.1,
    defaultSetting = defaultConfig.landingMaxAngle,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "landingMaxAngle",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Плавность наклона при прыжке",
    description = "Определяет плавность наклона камеры при прыжке. При высоком значении, будет более резкое движение, при низком низкое значении, более плавное движение.",
    max = 20,
    min = 1,
    defaultSetting = defaultConfig.jumpAngleSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "jumpAngleSmoothing",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Плавность наклона при приземлении",
    description = "Определяет скорость наклона камеры вниз при приземлении.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.landingEaseAwaySmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "landingEaseAwaySmoothing",
        table = config
    }
}

jumpingPage:createSlider{
    label = "Плавность возвращения камеры после приземления.",
    description = "Определяет скорость возврата камеры в исходное положение после приземления.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.landingEaseBackSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "landingEaseBackSmoothing",
        table = config
    }
}

------------------------------------------------------------------------------------------------------------------------------- Smooth stealth camera change

local sneakPage = template:createSideBarPage({
    label = "Настройки режима скрытности",
    description = "Эти настройки определяют плавность перехода камеры в режим скрытности. Отключение настройки камеры скрытности сбросит настройки.",
    showReset = true
})

sneakPage:createSlider{
    label = "Высота камеры в режиме скрытности",
    description = "Определяет, насколько низко опустится камера. 0 означает, что камера вообще не будет перемещаться, 100 означает, что камера будет опускаться до уровня ног.\n\nЭто значение имитирует работу GMST для опускания камеры в скрытности, но не влияет на него напрямую (оригинальное значение GMST сохраняется и будет использовано при отключении этой настройки)",
    max = 100,
    min = 10,
    defaultSetting = defaultConfig.sneakCameraHeight,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakCameraHeight",
        table = config
    }
}

sneakPage:createSlider{
    label = "Множитель высоты камеры для вида от 3-го лица",
    description = "Определяет, насколько сильно опускается камера при виде от 3-го лица относительно обычной высоты. 100 означает, что камера будет следовать на 100%, 0 означает, что она будет вести себя как в оригинальной игре (вообще не будет перемещаться).",
    max = 100,
    min = 0,
    defaultSetting = defaultConfig.sneak3rdPersonHeightMultiplier,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneak3rdPersonHeightMultiplier",
        table = config
    }
}

sneakPage:createSlider{
    label = "Плавность камеры в режиме скрытности",
    description = "Определяет скорость перемещения камеры в положение скрытности и обратно.",
    max = 25,
    min = 1,
    defaultSetting = defaultConfig.sneakCameraSmoothing,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "sneakCameraSmoothing",
        table = config
    }
}


