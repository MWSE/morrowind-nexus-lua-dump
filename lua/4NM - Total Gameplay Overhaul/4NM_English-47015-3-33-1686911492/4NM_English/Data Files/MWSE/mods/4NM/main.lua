local cf = mwse.loadConfig("4NM", {en = true, m = false, m1 = false, m2 = false, m30 = false, m3 = false, m4 = false, m5 = false, m6 = false, m7 = false, m8 = false, m9 = false, m10 = false, m11 = false,
scroll = true, lab = true, spmak = true, lin = 15, UIsp = false, UIen = false, UIcol = 0, fatbar = true, enbar = true, enbarpos = 5, newUI = true, UInum = true, dmgind = true, spdm = true, tut = true,
BBen = true, BBred = 5, BBgr = 30, BBhor = true, BBrig = true, nomic = false, vfxbl = false,
full = true, AIen = true, pmult = 1, min = 80, max = 120, skillp = true, levmod = true, trmod = true, expfat = 3, enchlim = true, durlim = true, alc = true, barter = true, stels = true, Spd = true, hit = true,
traum = true, stamhit = true, npcatak = true, pvp = true, pvp1 = true, par = true, durka = true, npcgrip = true,
nosave = true, Proj = true, spellhit = true, aspell = true, ammofix = false, AIsec = 2, reb = true, dbrep = 5,
cofat = 50, dash = 100, charglim = 100, moment = 100, metlim = 100, col = 100, upgm = false, agr = true, smartcw = true, maniac = false,
autoshield = true, smartpoi = true, raycon = true, mbkik = 3, mbdod = 4, mbret = 4, mbhev = 2, mbmet = 3, mbcharg = 2, mbray = 3, mbsum = 4, mbshot = 2, mbarc = 1, scrol = true,
autoarb = false, autokik = true, autocharg = false, ray = true,
volimp = 80, unmat = 3, crit = 30, mcs = true,
kikkey = {keyCode = 28}, pkey = {keyCode = 60}, ekey = {keyCode = 42}, dwmkey = {keyCode = 29}, gripkey = {keyCode = 56},
magkey = {keyCode = 157}, tpkey = {keyCode = 54}, cpkey = {keyCode = 207}, telkey = {keyCode = 209}, cwkey = {keyCode = 211},
poisonkey = {keyCode = 25}, parkey = {keyCode = 38}, totkey = {keyCode = 44}, bwkey = {keyCode = 45}, reflkey = {keyCode = 46}, detkey = {keyCode = 47}, markkey = {keyCode = 48},
q1 = {keyCode = 79}, q2 = {keyCode = 80}, q3 = {keyCode = 81}, q4 = {keyCode = 75}, q5 = {keyCode = 76}, q6 = {keyCode = 77}, q7 = {keyCode = 71}, q8 = {keyCode = 72}, q9 = {keyCode = 73}, q0 = {keyCode = 156}})
local eng = tes3.getLanguage() ~= "rus"
local function registerModConfig()	local tpl = mwse.mcm.createTemplate("4NM")	tpl:saveOnClose("4NM", cf)		tpl:register()		local var = mwse.mcm.createTableVariable
local p1, p0, p3, p2, pm, ps = tpl:createPage(eng and "Interface" or "Интерфейс"), tpl:createPage(eng and "Modules" or "Модули"), tpl:createPage(eng and "Mechanics" or "Удобства"),
tpl:createPage(eng and "Buttons" or "Кнопки"), tpl:createPage(eng and "Mouse" or "Мышь"), tpl:createPage(eng and "Sounds" or "Звуки")
p0:createSlider{label = eng and "Difficulty level: 1 - Hardcore, 2 - Medium, 3 - Easy. The difficulty only affects the number of perkpoints per level" or
"Уровень сложности: 1 - Хардкор, 2 - Средне, 3 - Легко. Сложность влияет только на количество перкпоинтов за уровень", min = 1, max = 3, step = 1, jump = 1, variable = var{id = "pmult", table = cf}}

p0:createYesNoButton{label = eng and "Increase attack frequency of enemies" or "Более частые атаки врагов", variable = var{id = "npcatak", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable PvP-mode (NPCs move better in combat)" or "ПвП-мод (нпс лучше двигаются в бою)", variable = var{id = "pvp", table = cf}}
p0:createYesNoButton{label = eng and "NPCs will try to dodge your projectiles" or "Нпс будут пытаться увернуться от ваших снарядов", variable = var{id = "pvp1", table = cf}}
p0:createYesNoButton{label = eng and "NPCs will carry out power attacks from a running start" or "Нпс будут проводить силовые атаки с разбега", variable = var{id = "durka", table = cf}}
p0:createYesNoButton{label = eng and "NPCs without a shield will change the grip of one-handed weapons to two-handed" or "Нпс без щита будут менять хват одноручного оружия на двуручный", variable = var{id = "npcgrip", table = cf}}
p0:createYesNoButton{label = eng and "Enable parrying for enemies" or "Включить парирование для врагов", variable = var{id = "par", table = cf}}
p0:createYesNoButton{label = eng and "Enable improved enemy AI" or "Улучшенный ИИ врагов", variable = var{id = "AIen", table = cf}}
p0:createYesNoButton{label = eng and "Enable improved creature abilities" or "Улучшенные способности существ", variable = var{id = "full", table = cf}, restartRequired = true}
p0:createSlider{label = eng and "The minimum percentage of creature power (80 by default)" or "Минимальный процент силы существ (80 по умолчанию)", min = 50, max = 200, step = 1, jump = 5, variable = var{id = "min", table = cf}}
p0:createSlider{label = eng and "The maximum percentage of creature power (120 by default)" or "Максимальный процент силы существ (120 по умолчанию)", min = 50, max = 200, step = 1, jump = 5, variable = var{id = "max", table = cf}}
p0:createYesNoButton{label = eng and "Enable advanced leveling system" or "Продвинутая система левелинга", variable = var{id = "levmod", table = cf}}
p0:createYesNoButton{label = eng and "Enable advanced skill training system" or "Продвинутая система набора опыта в навыках", variable = var{id = "trmod", table = cf}, restartRequired = true}
p0:createSlider{label = eng and "Fatigue multiplier when training skills (3 by default)" or "Множитель усталости при повышении навыков (3 по умолчанию)",
min = 0, max = 10, step = 1, jump = 1, variable = var{id = "expfat", table = cf}}
p0:createYesNoButton{label = eng and "Enable skill points system for teachers" or "Включить систему скиллпоинтов для обучения у тренеров", variable = var{id = "skillp", table = cf}}
p0:createYesNoButton{label = eng and "Enable realistic run speed" or "Реалистичная скорость бега", variable = var{id = "Spd", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable realistic hit chance" or "Реалистичный шанс на попадание", variable = var{id = "hit", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable realistic injury from physical damage" or "Реалистичная травматичность от физического урона", variable = var{id = "traum", table = cf}}
p0:createYesNoButton{label = eng and "Enable realistic fatigue from physical damage" or "Реалистичная утомляемость от физического урона", variable = var{id = "stamhit", table = cf}}
p0:createYesNoButton{label = eng and "Enable advanced alchemy" or "Продвинутая алхимия", variable = var{id = "alc", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable advanced economics" or "Продвинутая экономика", variable = var{id = "barter", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable advanced stealth" or "Продвинутый стелс", variable = var{id = "stels", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable constant enchantments limit" or "Ограничение объема постоянных зачарований", variable = var{id = "enchlim", table = cf}}
p0:createYesNoButton{label = eng and "Enable minimum duration for homemade spells" or "Ограничение длительности самодельных спеллов", variable = var{id = "durlim", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable improved targeting magic for enemies" or "Улучшенное наведение магии для врагов", variable = var{id = "spellhit", table = cf}}
p0:createYesNoButton{label = eng and "Automatic rebalancing of weapons and armor from other mods" or "Автоматический ребаланс оружия и брони из других модов", variable = var{id = "reb", table = cf}}
p0:createYesNoButton{label = eng and "Arrows get stuck on hit" or "Стрелы будут застревать при попадании", variable = var{id = "Proj", table = cf}, restartRequired = true}
--p0:createYesNoButton{label = eng and "Bug-fix of idle shooting - enable only if shooters are bugged" or "Баг-фикс стрельбы вхолостую - включать только если забагуются стрелки", variable = var{id = "ammofix", table = cf}}
p0:createYesNoButton{label = eng and "Anti-exploit for homemade spells" or "Анти-эксплойт с самодельными спеллами", variable = var{id = "aspell", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Disable saves during combat" or "Запрет сохранений во время боя", variable = var{id = "nosave", table = cf}}
p0:createSlider{label = eng and "How many seconds does it take for enemies to switch to throwing stones" or "Сколько секунд надо затупившим врагам на то чтобы начать кидать камни в героя",
min = 0, max = 10, step = 1, jump = 1, variable = var{id = "AIsec", table = cf}}
p0:createSlider{label = eng and "Reputation to start Dark Brotherhood attacks" or "Репутация для старта атак Темного Братства", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "dbrep", table = cf}}

--p1:createYesNoButton{label = "English language", variable = var{id = "en", table = cf}, restartRequired = true}
p1:createYesNoButton{label = eng and "Show new mechanics messages" or "Показывать сообщения о новых механиках", variable = var{id = "m", table = cf}}
p1:createYesNoButton{label = eng and "Show magic power messages" or "Показывать сообщения о силе магии", variable = var{id = "m1", table = cf}}
p1:createYesNoButton{label = eng and "Show magic cast messages" or "Показывать сообщения о касте магии", variable = var{id = "m10", table = cf}}
p1:createYesNoButton{label = eng and "Show magic affect messages" or "Показывать сообщения о вторичных магических эффектах", variable = var{id = "m2", table = cf}}
p1:createYesNoButton{label = eng and "Show physical damage messages" or "Показывать сообщения о физическом уроне", variable = var{id = "m30", table = cf}}
p1:createYesNoButton{label = eng and "Show other combat messages" or "Показывать другие боевые сообщения", variable = var{id = "m3", table = cf}}
p1:createYesNoButton{label = eng and "Show AI messages" or "Показывать сообщения для модуля ИИ", variable = var{id = "m4", table = cf}}
p1:createYesNoButton{label = eng and "Show item messages" or "Показывать сообщений о предметах", variable = var{id = "m8", table = cf}}
p1:createYesNoButton{label = eng and "Show alchemy messages" or "Показывать алхимические сообщения", variable = var{id = "m5", table = cf}}
p1:createYesNoButton{label = eng and "Show economic messages" or "Показывать экономические сообщения", variable = var{id = "m6", table = cf}}
p1:createYesNoButton{label = eng and "Show training messages" or "Показывать сообщения об опыте", variable = var{id = "m7", table = cf}}
p1:createYesNoButton{label = eng and "Show randomizer messages" or "Показывать сообщения рандомизатора", variable = var{id = "m9", table = cf}}
p1:createYesNoButton{label = eng and "Show stealth messages" or "Показывать сообщения о скрытности", variable = var{id = "m11", table = cf}}
p1:createSlider{label = eng and "Set number of icons in 1 line in Improved magic menu" or "Сколько иконок будет в одной строке Улучшенного меню магии", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "lin", table = cf}}
p1:createSlider{label = eng and "Font color in Improved magic menu (0 = no text)" or "Цвет шрифта в улучшенном меню магии (0 = без текста)", min = 0, max = 4, step = 1, jump = 1, variable = var{id = "UIcol", table = cf}}
p1:createYesNoButton{label = eng and "Improved spell menu (requires save load)" or "Улучшенное меню заклинаний", variable = var{id = "UIsp", table = cf}}
p1:createYesNoButton{label = eng and "Improved enchanted items menu (requires save load)" or "Улучшенное меню зачарованных предметов", variable = var{id = "UIen", table = cf}}
p1:createYesNoButton{label = eng and "Improved spell creation menu" or "Улучшеное меню создания заклинаний", variable = var{id = "spmak", table = cf}}
p1:createYesNoButton{label = eng and "Improved enemy bars" or "Улучшенные полоски врагов", variable = var{id = "enbar", table = cf}}
p1:createSlider{label = eng and "Enemy bars position" or "Расположение полосок врагов", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "enbarpos", table = cf}}
p1:createYesNoButton{label = eng and "Improved HUD" or "Улучшенный интерфейс", variable = var{id = "newUI", table = cf}}
p1:createYesNoButton{label = eng and "Show numbers on player bars" or "Показывать цифры на полосках игрока", variable = var{id = "UInum", table = cf}}
p1:createYesNoButton{label = eng and "Show physical damage indicator" or "Показывать индикатор физического урона", variable = var{id = "dmgind", table = cf}}
p1:createYesNoButton{label = eng and "Show speedometer" or "Показывать спидометр", variable = var{id = "spdm", table = cf}}
p1:createYesNoButton{label = eng and "Show a training fatigue bar (green - movement, blue - magic, lilac - craft, yellow - social)" or
"Показывать полоску тренировочной усталости (зеленый - движения, голубой - магия, сиреневый - крафт, желтый - социалка)", variable = var{id = "fatbar", table = cf}}
p1:createYesNoButton{label = eng and "Show tutorial tips on save loading" or "Показывать обучающие подсказки при загрузках", variable = var{id = "tut", table = cf}}
p1:createYesNoButton{label = eng and "Replace potion icons with better ones" or "Заменить иконки зелий на информативные", variable = var{id = "lab", table = cf}, restartRequired = true}
p1:createYesNoButton{label = eng and "Replace scroll icons with beautiful ones" or "Заменить иконки свитков на красивые", variable = var{id = "scroll", table = cf}, restartRequired = true}
p1:createCategory(eng and "Buff bars settings:" or "Настройки полосок баффов:")
p1:createYesNoButton{label = eng and "Enable buff bars" or "Включить полоски баффов", variable = var{id = "BBen", table = cf}}
p1:createYesNoButton{label = eng and "Horizontal arrangement" or "Горизонтальное расположение", variable = var{id = "BBhor", table = cf}}
p1:createYesNoButton{label = eng and "Right corner location" or "Расположение в правом угле", variable = var{id = "BBrig", table = cf}}
p1:createSlider{label = eng and "Buff time corresponding to red" or "Время баффа соответствующее красному цвету", min = 1, max = 30, step = 1, jump = 5, variable = var{id = "BBred", table = cf}}
p1:createSlider{label = eng and "Buff time corresponding to green" or "Время баффа соответствующее зеленому цвету", min = 10, max = 300, step = 1, jump = 5, variable = var{id = "BBgr", table = cf}}
p1:createYesNoButton{label = eng and "Hide small magic effect icons" or "Скрыть маленькие иконки магических эффектов", variable = var{id = "nomic", table = cf}}

p3:createSlider{label = eng and "Stamina limiter for your combo attacks" or "Ограничитель стамины для ваших комбо-атак", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "cofat", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your dashes. Use a dash with middle mouse button pressed to remove this limitation" or
"Ограничитель магнитуды для ваших дэшей. Используйте дэш с зажатой средней кнопкой мыши чтобы снять это ограничение", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "dash", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your charge attacks" or "Ограничитель магнитуды для ваших чардж-атак", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "charglim", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your kinetic kicks" or "Ограничитель магнитуды для ваших кинетических пинков", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "moment", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your kinetic throws" or "Ограничитель магнитуды для ваших кинетических бросков", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "metlim", table = cf}}
p3:createYesNoButton{label = eng and "Automatically kick after dash (if dash is done with middle mouse button pressed)" or "Автоматически делать пинок после дэша (если дэш сделан с зажатой средней кнопкой мыши)", variable = var{id = "autokik", table = cf}}
p3:createYesNoButton{label = eng and "Automatically charge attack if you are looking at an enemy" or "Автоматически делать чардж-атаку если вы смотрите на врага", variable = var{id = "autocharg", table = cf}}
--p3:createSlider{label = eng and "Limiter for your manashield" or "Ограничитель вашего манащита", min = 0, max = 500, step = 1, jump = 5, variable = var{id = "mshmax", table = cf}}
--p3:createSlider{label = eng and "Percentage limiter for your reflects" or "Ограничитель процента эффективности для ваших отражений", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "rfmax", table = cf}}
p3:createYesNoButton{label = eng and "Charged weapon: smart mode for range weapons" or "Эффект заряженного оружия: включить умный режим для дальнобойного оружия", variable = var{id = "smartcw", table = cf}}
p3:createYesNoButton{label = eng and "Agressive mode for your kicks, auras, totems" or "Агрессивный режим для ваших пинков, аур, тотемов", variable = var{id = "agr", table = cf}}
p3:createYesNoButton{label = eng and "Allow projectile control for magic rays" or "Разрешить контроль снарядов для магических лучей", variable = var{id = "raycon", table = cf}}
p3:createYesNoButton{label = eng and "Default ray mode (if not then spray)" or "Режим луча по умолчанию (если нет то будет спрей)", variable = var{id = "ray", table = cf}}
--p3:createYesNoButton{label = eng and "Automatic replenishment of bound ammo" or "Автоматически пополнять призванные снаряды", variable = var{id = "autoammo", table = cf}}
--p3:createYesNoButton{label = eng and "Allow telekinetic return of thrown weapons" or "Разрешить телекинетический возврат кинутого оружия", variable = var{id = "metret", table = cf}}
p3:createYesNoButton{label = eng and "Always shoot a crossbow in alternate mode" or "Всегда стрелять из арбалета в альтернативном режиме", variable = var{id = "autoarb", table = cf}}
p3:createSlider{label = eng and "Set color saturation of magic lights (0 = maximum colorfulness, 255 = full white)" or
"Насыщенность цвета для магических фонарей (0 = максимум цвета, 255 = чисто белый свет)", min = 0, max = 255, step = 1, jump = 5, variable = var{id = "col", table = cf}}
p3:createYesNoButton{label = eng and "Maniac mode! You will try to undress knocked out enemies" or "Режим маньяка! Вы будете пытаться раздеть нокаутированных врагов", variable = var{id = "maniac", table = cf}}
p3:createYesNoButton{label = eng and "Automatic shield equipment" or "Автоматическая экипировка щитов", variable = var{id = "autoshield", table = cf}}
p3:createYesNoButton{label = eng and "Smart potion/poison discrimination mode. If the potion contains at least 1 negative effect, then this is poison" or
"Умный режим различения зелий и ядов. Работает со включенным режимом яда. Если зелье содержит хотябы 1 негативный эффект, то это яд, иначе зелье и вы его выпьете", variable = var{id = "smartpoi", table = cf}}
p3:createYesNoButton{label = eng and "Allow to upgrade only equipped weapons and armor" or "Разрешить улучшать только экипированные оружие и броню", variable = var{id = "upgm", table = cf}}
p3:createYesNoButton{label = eng and "Remove additional vfx casting Destruction spells for the player" or "Удалить дополнительные vfx каста заклинаний Разрушения для игрока", variable = var{id = "vfxbl", table = cf}, restartRequired = true}

p2:createKeyBinder{variable = var{id = "pkey", table = cf}, label = eng and "Perks Menu" or "Вызвать меню перков"}
p2:createKeyBinder{variable = var{id = "tpkey", table = cf}, label = eng and "Dash / active dodge key" or "Кнопка для дэшей и активных уклонений"}
p2:createKeyBinder{variable = var{id = "kikkey", table = cf}, label = eng and "Kicking and climbing key. It is recommended to assign the same button as for the jump" or
"Кнопка для удара ногой и карабканья. Рекомендуется назначить ту же кнопку что и для прыжка"}
p2:createKeyBinder{variable = var{id = "magkey", table = cf}, label = eng and "Key for Extra cast. Press slot key with SHIFT to assign the current spell to this Extra cast slot" or
"Кнопка Экстра-каста. Нажмите одну из кнопок выбора слота экстра-каста вместе с SHIFT чтобы назначить текущий спелл для этого слота"}
p2:createKeyBinder{variable = var{id = "ekey", table = cf}, label = eng and
[[Hold this key when: Equipping weapon - to remember it for left hand; Equipping poison - to use it for throwing; Activating the apparatus - to display the alchemy menu without adding it to your inventory]] or
[[Удерживайте эту кнопку: При экипировке оружия - чтобы запомнить его для левой руки; При экипировке яда - чтобы кидать бутылки; При активации аппарата - чтобы алхимическое меню появилось без взятия этого апаарата]]}
p2:createKeyBinder{variable = var{id = "dwmkey", table = cf}, label = eng and "Switch to dual-weapon mode. Press this button while holding ALT to forget the left weapon" or
"Переключение режима двух оружий. Нажмите эту кнопку, удерживая ALT, чтобы забыть оружие для левой руки"}
p2:createKeyBinder{variable = var{id = "gripkey", table = cf}, label = eng and "Press this key when equip weapon to change it grip" or "Нажмите эту кнопку при экипировке оружия чтобы сменить его хват"}
p2:createKeyBinder{variable = var{id = "cpkey", table = cf}, label = eng and "Projectile control mode key. Press with: Move buttons or CTRL = switch modes; ALT = turn Smart mode; LMB = release projectiles" or
"Кнопка для контроля снарядов. Нажмите ее вместе с: кнопками движения или CTRL = переключить режимы; ALT = переключить умный режим; ЛКМ = отпустить снаряды"}
p2:createKeyBinder{variable = var{id = "telkey", table = cf}, label = eng and "Telekinetic Throw key. Press again to return thrown weapon. Hold while activating or dropping weapons." or
"Кнопка для телекинетического броска. Нажмите повторно чтобы вернуть брошенное оружие. Удерживайте ее во время активации или выбрасывания предмета."}
p2:createKeyBinder{variable = var{id = "cwkey", table = cf}, label = eng and "Charge weapon key. Press with SHIFT to turn mode. Press with CTRL to switch ranged/touch mode. Press with ALT to disable enchantments on strike" or
"Конпка для эффекта заряженного оружия. Нажмите ее вместе с SHIFT для переключения режима. Нажмите вместе с CTRL для пререключения дальности. Нажмите вместе с ALT для запрета применять зачарования при ударе"}
p2:createKeyBinder{variable = var{id = "reflkey", table = cf}, label = eng and "Turn reflect/manashield mode for new reflect spells. Press with: ALT - manashield settings; CTRL - switch auras mode; SHIFT - switch magic explode mode" or
"Кнопка для переключения режима отражения и манащита для эффектов нового отражения. Нажмите ее вместе с: ALT - настройки манащита, CTRL - переключить режим аур; SHIFT - переключить режим магических взрывов"}
p2:createKeyBinder{variable = var{id = "totkey", table = cf}, label = eng and "Press to switch totem mode. Press with SHIFT to explode all runes. Press with CTRL to explode all totems." or
"Нажмите для переключения режима тотемов. Нажмите вместе с SHIFT чтобы взорвать все руны. Нажмите вместе с CTRL чтобы взорвать все тотемы."}
p2:createKeyBinder{variable = var{id = "detkey", table = cf}, label = eng and "Use magic vision for detection" or "Кнопка для применения магического зрения для магии обнаружения"}
p2:createKeyBinder{variable = var{id = "markkey", table = cf}, label = eng and "Key for select mark for recall" or "Кнопка для выбора текущей Пометки для магии Возврата"}
p2:createKeyBinder{variable = var{id = "bwkey", table = cf}, label = eng and "Replenishment of bound ammo. Press with CTRL for choosing a bound weapon" or
"Пополнение призванных снарядов. Нажмите вместе с CTRL для выбора призванного оружия"}
p2:createKeyBinder{variable = var{id = "poisonkey", table = cf}, label = eng and "Assign a button to toggle poison mode. If poison mode enabled, you will create poisons instead of potions, and also apply them to your weapons instead of drinking" or
"Кнопка для режима яда. Когда режим яда включен, вы варите яды вместо зелий а также отравляете свое оружие ядом вместо выпивания"}
p2:createKeyBinder{variable = var{id = "parkey", table = cf}, label = eng and "Assign a button to toggle parry mode. In this mode, your attacks will try to repel the enemy's weapons if possible" or
"Кнопка для режима парирования. В этом режиме ваши атаки будут пытаться отбить оружие врага если это возможно"}
p2:createKeyBinder{variable = var{id = "q0", table = cf}, label = eng and [[Universal Extra cast slot. If selected, the current spell will always be prepared for a Extra cast.
Press this button with SHIFT to add/remove current spell to Favorite Spells list. Press this button with ALT to clear this list.
Spells from Favorite list are placed at the top of the Improved Magic Menu. Changes to the list take effect after loading the save.]] or
[[Кнопка выбора универсального слота для экстра-каста. Если универсальный слот выбран, то для экстра-каста всегда будет использован только ваш текущий спелл.
Нажмите эту кнопку вместе с SHIFT чтобы добавить/удалить текущий спелл в список Избранных Спеллов. Нажмите эту кнопку вместе с ALT чтобы очистить этот список.
Спеллы из Избранного списка помещаются наверх в Улучшенном меню магии. Изменения списка вступают в силу после загрузки сейва.]]}
p2:createYesNoButton{label = eng and "Use mouse wheel to scroll Favorite Spells list" or "Использовать колесо мыши для прокрутки списка Избранных Спеллов", variable = var{id = "scrol", table = cf}, restartRequired = true}
p2:createCategory(eng and "By default these are buttons on the NUM-bar:" or "По умолчанию это кнопки на NUM-панели:")
p2:createKeyBinder{variable = var{id = "q1", table = cf}, label = eng and "Extra cast slot #1" or "Слот экстра-каста #1"}
p2:createKeyBinder{variable = var{id = "q2", table = cf}, label = eng and "Extra cast slot #2" or "Слот экстра-каста #2"}
p2:createKeyBinder{variable = var{id = "q3", table = cf}, label = eng and "Extra cast slot #3" or "Слот экстра-каста #3"}
p2:createKeyBinder{variable = var{id = "q4", table = cf}, label = eng and "Extra cast slot #4" or "Слот экстра-каста #4"}
p2:createKeyBinder{variable = var{id = "q5", table = cf}, label = eng and "Extra cast slot #5" or "Слот экстра-каста #5"}
p2:createKeyBinder{variable = var{id = "q6", table = cf}, label = eng and "Extra cast slot #6" or "Слот экстра-каста #6"}
p2:createKeyBinder{variable = var{id = "q7", table = cf}, label = eng and "Extra cast slot #7" or "Слот экстра-каста #7"}
p2:createKeyBinder{variable = var{id = "q8", table = cf}, label = eng and "Extra cast slot #8" or "Слот экстра-каста #8"}
p2:createKeyBinder{variable = var{id = "q9", table = cf}, label = eng and "Extra cast slot #9" or "Слот экстра-каста #9"}

pm:createCategory(eng and "Mouse buttons: 1 - left, 2 - right, 3 - middle, 4-7 - side" or "Кнопки мыши: 1 - левая, 2 - правая, 3 - средняя, 4-7 - боковые")
pm:createSlider{label = eng and "Mouse button for active dodge (hold while using dash to use active dodge instead of dash)" or 
"Кнопка мыши для активного уклонения (зажмите при использовании дэша, чтобы применить активное уклонение вместо дэша)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbdod", table = cf}}
pm:createSlider{label = eng and "Mouse button for kicking and climbing" or "Кнопка мыши для удара ногой и карабканья", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbkik", table = cf}}
pm:createSlider{label = eng and "Mouse button for charge attack (hold while attack)" or "Кнопка мыши для чардж-атаки (зажмите при атаке)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbcharg", table = cf}}
pm:createSlider{label = eng and "Mouse button for throwing weapons (hold while attacking)" or "Кнопка мыши для кидания оружия (зажмите при атаке)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbmet", table = cf}}
pm:createSlider{label = eng and "Mouse button for alternative shots (press while holding LMB for bows and throwing weapons; hold and press LMB for crossbows)" or
"Кнопка мыши для альтернативных выстрелов (нажмите при зажатой ЛКМ для луков и метательного оружия; удерживайте и нажимайте ЛКМ для арбалетов)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbshot", table = cf}}
pm:createSlider{label = eng and "Mouse button to hold breath when archery (select 1 for automatic hold)" or
"Кнопка мыши для задержки дыхания при стрельбе из лука (выберите 1 для автоматической задержки)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbarc", table = cf}}
pm:createSlider{label = eng and "Mouse button for weighting magic projectiles (hold while casting)" or "Кнопка мыши для утяжеления магических снарядов (зажмите при касте)",
min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbhev", table = cf}}
pm:createSlider{label = eng and "Mouse button for alternate ray mode (hold while casting)" or "Кнопка мыши для альтернативного режима луча (зажмите при касте)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbray", table = cf}}
pm:createSlider{label = eng and "Mouse button to extend the life of summoned creatures (hold while charging magic and looking at the creature)" or
"Кнопка мыши для продления жизни призванных существ (удерживайте, заряжая магию и смотря на существо)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbsum", table = cf}}
pm:createSlider{label = eng and "Mouse button to return controlled projectiles and teleport magic mines" or
"Кнопка мыши для возврата контролируемых снарядов и телепортации магических мин", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbret", table = cf}}

ps:createSlider{label = eng and "Weapon impact sound volume" or "Громкость звуков соударений оружия", min = 0, max = 100, step = 1, jump = 10, variable = var{id = "volimp", table = cf}}
ps:createSlider{label = eng and "Minimum crit power to play crit strike sound" or "Минимальная мощь крита для проигрывания звука крита", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "crit", table = cf}}
ps:createYesNoButton{label = eng and "Play sound of magic concentration (hold Left Mouse Button for concentrate power)" or
"Звук магической концентрации (удерживайте левую кнопку мыши чтобы сконцентрировать магию и зарядить спелл)", variable = var{id = "mcs", table = cf}}
--ps:createSlider{label = eng and "Weapon hit sound for unknown objects: 1 - dirt, 2 - wood, 3 - stone, 4 - metal" or "Звук попаданий оружия для неизвестных объектов: 1 - земля, 2 - дерево, 3 - камень, 4 - металл",
--min = 1, max = 4, step = 1, jump = 1, variable = var{id = "unmat", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local p, mp, inv, p1, p3, ad, pp, D, P, DM, MB, AC, mc, rf, n, md, pow, wc, ic, crot, QS		local MT = {__index = function(t, k) t[k] = {} return t[k] end}		local AF = {}	--setmetatable({}, MT)
--local SS = setmetatable({}, MT)		local BSS = setmetatable({}, MT)		local SSN = {}
local M = {}	local B = {}	local S = {}	local SN = {}	local SNC = {}	local COL = {}		local Matr = tes3matrix33.new()		local W = {}	local N = {}	local MP = {}		local DOM = {}
local V = {up100 = tes3vector3.new(0,0,100), up = tes3vector3.new(0,0,1), up2 = tes3vector3.new(0,0,0.5), up3 = tes3vector3.new(0,0,0.2666), down = tes3vector3.new(0,0,-1), down10 = tes3vector3.new(0,0,-10), nul = tes3vector3.new(0,0,0)}
local KSR = {}	local PRR = {}		local R = {}	local G = {cpg = 0, DopW = {}}
local PMP, com, last, pred, arm, arp		local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)
local CPR = {}		local CPRS = {}		local CPS = {0,0,0,0,0,0,0,0,0,0}
local AT = {[0] = {t="l",s=21,p="lig0",snd="Light Armor Hit"}, [1] = {t="m",s=2,p="med0",snd="Medium Armor Hit"}, [2] = {t="h",s=3,p="hev0",snd="Heavy Armor Hit"}, [3] = {t="u",s=17}}
local WT = {[-1]={s=26,p1="hand1",p2="hand2",p3="hand3",p4="hand4",p5="hand5",p6="hand6",p8="hand8",pc="hand12"},
[0]={s=22,p1="short1",p2="short2",p3="short3",p4="short4",p5="short5",p6="short6",p7="short7",p8="short8",p9="short9",p="short0",pc="short13",h1=true,dw=true,pso=1,iso=1},
[1]={s=5,p1="long1a",p2="long2a",p3="long3a",p4="long4a",p5="long5a",p6="long6a",p7="long7a",p8="long8a",p9="long9a",p="long0",pc="long9",h1=true,dw=true,pso=1,iso=1},
[2]={s=5,p1="long1b",p2="long2b",p3="long3b",p4="long4b",p5="long5b",p6="long6b",p7="long7b",p8="long8b",p9="long9b",p="long0",pso=1,iso=1},
[3]={s=4,p1="blu1a",p2="blu2a",p3="blu3a",p4="blu4a",p5="blu5a",p6="blu6a",p7="blu7a",p8="blu8a",p9="blu9a",p="blu0a",h1=true,dw=true,pso=3,iso=3},
[4]={s=4,p1="blu1b",p2="blu2b",p3="blu3b",p4="blu4b",p5="blu5b",p6="blu6b",p7="blu7b",p8="blu8b",p9="blu9b",p="blu0a",pso=3,iso=3},
[5]= {s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",pso=3,iso=3},
[-3]={s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",h1=true,dw=true,pso=3,iso=3},
[6]={s=7,p1="spear1",p2="spear2",p3="spear3",p4="spear4",p5="spear5",p6="spear6",p7="spear7",p8="spear8",p9="spear9",p="spear0",pso=2,iso=1},
[-2]={s=7,p1="spear1a",p2="spear2a",p3="spear3a",p4="spear4a",p5="spear5a",p6="spear6a",p7="spear7a",p8="spear8a",p9="spear9a",p="spear0",h1=true,dw=true,pso=2,iso=1},
[7]={s=6,p1="axe1a",p2="axe2a",p3="axe3a",p4="axe4a",p5="axe5a",p6="axe6a",p7="axe7a",p8="axe8a",p9="axe9a",p="axe0",h1=true,dw=true,pso=2,iso=2},
[8]={s=6,p1="axe1b",p2="axe2b",p3="axe3b",p4="axe4b",p5="axe5b",p6="axe6b",p7="axe7b",p8="axe8b",p9="axe9b",p="axe0",pso=2,iso=2},
[9]={s=23,p1="mark1a",p2="mark2a",p3="mark3a",p4="mark4a",p5="mark5a",p6="mark6a",p="mark0a"},
[10]={s=23,p1="mark1b",p2="mark2b",p3="mark3b",p4="mark4b",p5="mark5b",p6="mark6b",p="mark0b"},
[11]={s=23,p1="mark1c",p2="mark2c",p3="mark3c",p4="mark4c",p5="mark5c",p6="mark6c",p="mark0c",h1=true}}

local T = {T1 = timer, AUR = timer, DC = timer, Ray = timer, TS = timer, DET = timer, PCT = timer, MCT = timer, QST = timer, LEG = timer,
LI = timer, Dash = timer, Dod = timer, Kik = timer, CT = timer, CST = timer, Shield = timer, Comb = timer, DWB = timer, POT = timer, Run = timer, AoE = timer, Tot = timer, WaterB = timer, Arb = timer, Met = timer, Dom = timer,
Tut = timer, EDMG = timer, EnCD = timer}
local L = {PR = require("4NM.perks"), WE = require("4NM.weapon"), ARM = require("4NM.armor"), TUT = require("4NM.turor"), TD = require("4NM.tex"),
ATR = {[0] = "strength", [1] = "intelligence", [2] = "willpower", [3] = "agility", [4] = "speed", [5] = "endurance", [6] = "personality", [7] = "luck"},
ATRIC = {[0] = "icons/k/attribute_strength.dds", [1] = "icons/k/attribute_int.dds", [2] = "icons/k/attribute_wilpower.dds", [3] = "icons/k/attribute_agility.dds", [4] = "icons/k/attribute_speed.dds",
[5] = "icons/k/attribute_endurance.dds", [6] = "icons/k/attribute_personality.dds", [7] = "icons/k/attribute_luck.dds"},
S = {"armorer", "mediumArmor", "heavyArmor", "bluntWeapon", "longBlade", "axe", "spear", "athletics", "enchant", "destruction", "alteration", "illusion", "conjuration", "mysticism", "restoration",
"alchemy", "unarmored", "security", "sneak", "acrobatics", "lightArmor", "shortBlade", "marksman", "mercantile", "speechcraft", "handToHand", [0] = "block"},
SK = {[4] = "skw", [5] = "skw", [6] = "skw", [7] = "skw", [22] = "skw", [23] = "skw", [26] = "skw", [0] = "skarm", [2] = "skarm", [3] = "skarm", [17] = "skarm", [21] = "skarm", [18] = "sksec", [20] = "skacr",
[9] = "skmag", [10] = "skmag", [11] = "skmag", [12] = "skmag", [13] = "skmag", [14] = "skmag", [15] = "skmag"}, skmag = 1, skw = 1, skarm = 1, sksec = 1, skacr = 1, jumptim = 0,
BS = {["Wombburned"] = "atronach", ["Fay"] = "mage", ["Beggar's Nose"] = "tower", ["Blessed Touch Sign"] = "ritual", ["Charioteer"] = "steed", ["Elfborn"] = "apprentice", ["Hara"] = "thief",
["Lady's Favor"] = "lady", ["Mooncalf"] = "lover", ["Moonshadow Sign"] = "shadow", ["Star-Cursed"] = "serpent", ["Trollkin"] = "lord", ["Warwyrd"] = "warrior"},
SA = {0,5,5,0,0,0,3,5,2,2,1,1,2,1,2,1,4,3,3,3,4,4,3,6,6,4,[0]=3}, SA2 = {3,3,0,5,3,5,0,4,1,1,2,2,1,2,1,3,2,1,4,4,3,3,0,1,1,0,[0]=5}, SS = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,[0]=0},
RHP = {Orc = 20, Nord = 20, Argonian = 20, Imperial = 10, Redguard = 10},
RST = {Orc = 50, Nord = 50, Argonian = 50, Imperial = 100, Redguard = 50, ["Wood Elf"] = 50},
RENC = {Orc = 100, Nord = 50, Imperial = 50},

PERST = {[80] = {"end13", "str10", "wil12", "luc15", "atl9"},
[84] = {"res04", "des04", "alt04", "ill04", "con04", "mys04", "enc01", "una02", "int01", "wil01"},
[82] = {"str03", "end04", "long03", "axe03", "blu03", "spear03", "hand04", "med03", "hev03", "atl03"},
[8] = {"med01", "hev01", "atl01", "str01", "end01"}
},

PRL = {{"strength", "icons/k/attribute_strength.dds", 0}, {"endurance", "icons/k/attribute_endurance.dds", 5}, {"speed", "icons/k/attribute_speed.dds", 4}, {"agility", "icons/k/attribute_agility.dds", 3}, {"intelligence", "icons/k/attribute_int.dds", 1},
{"willpower", "icons/k/attribute_wilpower.dds", 2}, {"personality", "icons/k/attribute_personality.dds", 6}, {"luck", "icons/k/attribute_luck.dds", 7}, {"longBlade", "icons/k/combat_longblade.dds", 5}, {"axe", "icons/k/combat_axe.dds", 6},
{"bluntWeapon", "icons/k/combat_blunt.dds", 4}, {"spear", "icons/k/combat_spear.dds", 7}, {"mediumArmor", "icons/k/combat_mediumarmor.dds", 2}, {"heavyArmor", "icons/k/combat_heavyarmor.dds", 3}, {"block", "icons/k/combat_block.dds", 0},
{"athletics", "icons/k/combat_athletics.dds", 8}, {"armorer", "icons/k/combat_armor.dds", 1}, {"destruction", "icons/k/magic_destruction.dds", 10}, {"alteration", "icons/k/magic_alteration.dds", 11}, {"mysticism", "icons/k/magic_mysticism.dds", 14},
{"restoration", "icons/k/magic_restoration.dds", 15}, {"illusion", "icons/k/magic_illusion.dds", 12}, {"conjuration", "icons/k/magic_conjuration.dds", 13}, {"enchant", "icons/k/magic_enchant.dds", 9}, {"alchemy","icons/k/magic_alchemy.dds", 16},
{"unarmored", "icons/k/magic_unarmored.dds", 17}, {"shortBlade", "icons/k/stealth_shortblade.dds", 22}, {"marksman", "icons/k/stealth_marksman.dds", 23}, {"handToHand", "icons/k/stealth_handtohand.dds", 26}, {"lightArmor", "icons/k/stealth_lightarmor.dds", 21},
{"acrobatics", "icons/k/stealth_acrobatics.dds", 20}, {"sneak", "icons/k/stealth_sneak.dds", 19}, {"security", "icons/k/stealth_security.dds", 18}, {"mercantile", "icons/k/stealth_mercantile.dds", 24}, {"speechcraft", "icons/k/stealth_speechcraft.dds", 25}},


AMIC = {
["w\\tx_arrow_iron.tga"] = "iron arrow",
["w\\tx_arrow_bonemold.tga"] = "bonemold arrow",
["w\\tx_arrow_corkbulb.tga"] = "corkbulb arrow",
["w\\tx_arrow_chitin.tga"] = "chitin arrow",
["w\\tx_arrow_silver.tga"] = "silver arrow",
["w\\tx_arrow_glass.tga"] = "glass arrow",
["w\\tx_arrow_ebony.tga"] = "ebony arrow",
["w\\tx_arrow_daedric.tga"] = "daedric arrow",
["w\\tx_bolt_corkbulb.tga"] = "corkbulb bolt",
["w\\tx_bolt_iron.tga"] = "iron bolt",
["w\\tx_bolt_steel.tga"] = "steel bolt",
["w\\tx_bolt_silver.tga"] = "silver bolt",
["w\\tx_bolt_bonemold.tga"] = "bonemold bolt",
["w\\tx_bolt_orcish.tga"] = "orcish bolt",
["w\\tx_arrow_steel.tga"] = "steel arrow",
["w\\huntsman_bolt.dds"] = "BM Huntsmanbolt",
["w\\dwarven_bolt.tga"] = "dwarven bolt",
["w\\obsidian_arrow.dds"] = "6th arrow",
["w\\adamant_arrow.dds"] = "adamantium arrow",
["w\\adamant_bolt.dds"] = "adamantium bolt",
["w\\glass_bolt.dds"] = "glass bolt",
["w\\daedric_bolt.dds"] = "daedric bolt",
["w\\ebony_bolt.dds"] = "ebony bolt",
["w\\ice_arrow.dds"] = "BM ice arrow",
["w\\goblin_arrow.dds"] = "goblin arrow",
["w\\orcish_arrow.dds"] = "orcish arrow",
["w\\huntsman_arrow.dds"] = "BM huntsman arrow",
["w\\imp_arrow.dds"] = "imperial arrow",
["w\\imp_bolt.dds"] = "imperial bolt",
["w\\dwarven_arrow.dds"] = "dwarven arrow",
["w\\sky\\daedric_arrow.dds"] = "daedric_sky arrow",
["w\\sky\\dwarven_bolt2.dds"] = "dwarven_sky bolt",
["w\\sky\\dwarven_arrow.dds"] = "dwarven_sky arrow",
["w\\sky\\ebony_arrow.dds"] = "ebony_sky arrow",
["w\\sky\\elven_arrow.dds"] = "elven_sky arrow",
["w\\sky\\glass_arrow.dds"] = "glass_sky arrow",
["w\\sky\\iron_arrow.dds"] = "iron_sky arrow",
["w\\sky\\nord_arrow.dds"] = "nordic_sky arrow",
["w\\sky\\orcish_arrow.dds"] = "orcish_sky arrow",
["w\\sky\\steel_bolt.dds"] = "steel_sky bolt",
["w\\sky\\steel_arrow.dds"] = "steel_sky arrow",
["w\\cir\\daedric_arrow.dds"] = "daedric_obl arrow",
["w\\cir\\dwarven_arrow.dds"] = "dwarven_obl arrow",
["w\\cir\\ebony_arrow.dds"] = "ebony_obl arrow",
["w\\cir\\elven_arrow.dds"] = "elven_obl arrow",
["w\\cir\\glass_arrow.dds"] = "glass_obl arrow",
["w\\cir\\iron_arrow.dds"] = "iron_obl arrow",
["w\\cir\\silver_arrow.dds"] = "silver_obl arrow",
["w\\cir\\steel_arrow.dds"] = "steel_obl arrow",
["w\\tx_star_glass.tga"] = "glass throwing star",
["w\\tx_silver_star.tga"] = "silver throwing star",
["w\\tx_star_ebony.tga"] = "ebony throwing star",
["w\\tx_chitin_star.tga"] = "chitin throwing star",
["w\\tx_steel_star.tga"] = "steel throwing star",
["w\\adamant_star.tga"] = "adamantium star",
["w\\bonemold_star.tga"] = "bonemold star",
["w\\daedric_star.dds"] = "daedric star",
["w\\dwarven_star.tga"] = "dwarven star",
["w\\iron_star.tga"] = "iron star",
["w\\imp_star.dds"] = "imperial star",
["w\\nord_star.dds"] = "nordic star",
["w\\orcish_star.dds"] = "orcish star",
["w\\tx_w_dwarvenspheredart.dds"] = "centurion_projectile_dart",
["w\\tx_w_dart_steel.tga"] = "steel dart",
["w\\tx_dart_daedric.tga"] = "daedric dart",
["w\\tx_dart_ebony.tga"] = "ebony dart",
["w\\tx_dart_silver.tga"] = "silver dart",
["w\\orcish_dart.dds"] = "orcish dart",
["w\\adamant_dart.tga"] = "adamantium dart",
["w\\glass_dart.dds"] = "glass dart",
["w\\iron_dart.tga"] = "iron dart",
["w\\bonemold_dart.dds"] = "bonemold dart",
["w\\chitin_dart.dds"] = "chitin dart",
["w\\imp_dart.dds"] = "imperial dart",
["w\\nord_dart.dds"] = "nordic dart",
["w\\tx_steel_knife.dds"] = "steel throwing knife",
["w\\tx_knife_glass.tga"] = "glass throwing knife",
["w\\tx_knife_iron.tga"] = "iron throwing knife",
["w\\tx_dagger_dragon.tga"] = "steel throwing knife",
["w\\adamant_throwingknife.tga"] = "adamantium throwingknife",
["w\\chitin_throwingknife.tga"] = "chitin throwingknife",
["w\\daedric_throwingknife.tga"] = "daedric throwingknife",
["w\\ebony_throwingknife.tga"] = "ebony throwingknife",
["w\\silver_throwingknife.tga"] = "silver throwingknife",
["w\\obsidian_throwingknife.tga"] = "6th throwingknife",
["w\\bonemold_throwingknife.dds"] = "bonemold throwingknife",
["w\\chitin_throwingknife.dds"] = "chitin throwingknife",
["w\\dwarven_throwingknife.dds"] = "dwarven throwingknife",
["w\\imp_throwingknife.dds"] = "imperial throwingknife",
["w\\nord_throwingknife.dds"] = "nordic throwingknife",
["w\\orcish_throwingknife.dds"] = "orcish throwingknife",
["w\\iron_throwingaxe.dds"] = "iron throwingaxe",
["w\\nord_throwingaxe.dds"] = "nordic throwingaxe",
["w\\silver_throwingaxe.dds"] = "silver throwingaxe",
["w\\glass_throwingaxe.dds"] = "glass throwingaxe",
["w\\chitin_throwingaxe.dds"] = "chitin throwingaxe",
["w\\daedric_throwingaxe.dds"] = "daedric throwingaxe",
["w\\goblin_throwingaxe.dds"] = "goblin throwingaxe",
["w\\riekling_javelin.dds"] = "BM riekling javelin"},



NSU = {["4as_atr4"] = {en = "Elemental triumvirate", ru = "Стихийный триумвират", c = 10, f = 4, d = 10, m = 10, ma = 20, {556}, {557}, {558}},
["4as_atr5"] = {en = "Elemental charge", ru = "Стихийный заряд", c = 20, d = 30, m = 8, ma = 12, {511}, {512}, {513}},
["4as_atr6"] = {en = "Elemental explode", ru = "Стихийный разрыв", c = 20, d = 30, m = 8, ma = 12, {531}, {532}, {533}},
["4as_atr7"] = {en = "Elemental spread", ru = "Стихийная шквал", c = 30, rt = 1, d = 0, m = 8, ma = 12, r = 5, {536}, {537}, {538}},
["4as_atr8"] = {en = "Elemental ray", ru = "Стихийный луч", c = 30, rt = 1, d = 0, m = 4, ma = 6, r = 1, {546}, {547}, {548}},
["4as_atr9"] = {en = "Elemental wave", ru = "Стихийная волна", c = 50, rt = 2, d = 1, m = 10, ma = 20, r = 20, {566}, {567}, {568}},
["4as_atr10"] = {en = "Elemental discharge", ru = "Стихийный разряд", c = 50, rt = 1, d = 0, m = 40, ma = 60, r = 15, {541}, {542}, {543}}},
PA = {atb1={117,5,"long01","Мастер меча","Sword master"}, atb2={117,5,"axe01","Мастер топора","Ax master"}, atb3={117,5,"blu01","Мастер булавы","Mace master"}, atb4={117,5,"spear01","Мастер копья","Spear master"},
atb5={117,5,"short01","Мастер ножа","Knife master"}, atb6={117,5,"mark01","Мастер стрельбы","Shooting master"}, atb7={117,5,"hand01","Мастер кулака","Fist master"}, atb8={117,5,"spd01","Быстрая атака","Fast attack"},
atb9={117,5,"agi01","Ловкая атака","Dexterous attack"}, atb10={117,5,"luc01","Удачная атака","Lucky attack"},
san1 = {42,5,"una01","Мастер без брони","Master without armor"}, san2 = {42,5,"lig01","Легкое уклонение","Easy evasion"}, san3 = {42,5,"bloc01","Парирование","Parry"}, san4 = {42,5,"short02","Воровской уворот","Thief evasion"}, 
san5 = {42,5,"hand02","Отклонение атак","Deflecting attacks"}, san6 = {42,5,"acr01","Боевая акробатика","Combat acrobatics"}, san7 = {42,5,"sec01","Чувство опасности","Sense of danger"},
san8 = {42,5,"spd02","Быстрое уклонение","Fast evasion"}, san9 = {42,5,"agi02","Ловкое уклонение","Dexterous evasion"}, san10 = {42,5,"luc02","Удачное уклонение","Lucky evasion"},

stam1 = {77,2,"med02","Привыкание к доспехам","Addictive to armor"}, stam2 = {77,2,"hev02","Привыкание к броне","Addictive to heavy armor"}, stam3 = {77,2,"atl02","Тренировка дыхания","Breathing training"},
stam4 = {77,2,"str02","Сильные мышцы","Strong muscles"}, stam5 = {77,2,"end02","Источник сил","Source of strength"}, stam6 = {77,2,"axe02","Сила топорщика","Power of axeman"}, stam7 = {77,2,"blu02","Сила дубинщика","Power of clubman"},
stam8 = {77,2,"spear02","Сила копейщика","Power of spearman"}, stam9 = {77,2,"hand03","Сила бойца","Power of fighter"}, stam10 = {77,2,"long02","Сила мечника","Power of swordsman"},

mpr1 = {76,0,"mys05","Глубокая медитация","Deep meditation",m=1}, mpr2 = {76,0,"enc02","Душевная медитация","Soul meditation",m=1},
mpr3 = {76,0,"int02","Осознанная медитация","Mindful meditation",m=1}, mpr4 = {76,0,"wil02","Духовная медитация","Spiritual meditation",m=1},
hpr1 = {75,0,"res05","Бессмертие","Immortality",m=1}, hpr2 = {75,0,"end03","Источник жизни","Life source",m=1},
abs1 = {67,5,"alt05","Энерготрансформатор","Energy transformer"}, abs2 = {67,5,"mys06","Энергоабсорбатор","Energy absorber"}, ref1 = {68,5,"mys07","Энергореверсор","Energy reverser"},
dete = {65,100,"enc03","Магическое чутье","Magical sense"}, deta = {64,100,"sec03","Воровское чутье","Thief's instinct"}, detk = {66,100,"sec02","Жадность","Greed"}, nig = {43,20,"mark02","Глаз-алмаз","Diamond eye"}},
AA = {["4a_long"] = {p = "long00", s = 5}, ["4a_short"] = {p = "short00", s = 22}, ["4a_axe"] = {p = "axe00", s = 6}, ["4a_blu"] = {p = "blu00", s = 4}, ["4a_spear"] = {p = "spear00", s = 7}, ["4a_mark"] = {p = "mark00", s = 23},
["4a_hand"] = {p = "hand00", s = 26}, ["4a_lig"] = {p = "lig00", s = 21}, ["4a_med"] = {p = "med00", s = 2}, ["4a_hev"] = {p = "hev00", s = 3}, ["4a_una"] = {p = "una00", s = 17}, ["4a_bloc"] = {p = "bloc00", s = 0}, 
["4a_acr"] = {p = "acr00", s = 20}, ["4a_atl"] = {p = "atl00", s = 8}, ["4a_arm"] = {p = "arm00", s = 1}, ["4a_enc"] = {p = "enc00", s = 9}, ["4a_alc"] = {p = "alc00", s = 16}, ["4a_snek"] = {p = "snek00", s = 19},
["4a_sec"] = {p = "sec00", s = 18}, ["4a_spec"] = {p = "spec00", s = 25}, ["4a_merc"] = {p = "merc00", s = 24},
["4a_des1"] = {p = "des01"}, ["4a_des2"] = {p = "des02"}, ["4a_des3"] = {p = "des03"}, ["4a_alt1"] = {p = "alt01"}, ["4a_alt2"] = {p = "alt02"}, ["4a_alt3"] = {p = "alt03"},
["4a_res1"] = {p = "res01"}, ["4a_res2"] = {p = "res02"}, ["4a_res3"] = {p = "res03"}, ["4a_mys1"] = {p = "mys01"}, ["4a_mys2"] = {p = "mys02"}, ["4a_mys3"] = {p = "mys03"},
["4a_ill1"] = {p = "ill01"}, ["4a_ill2"] = {p = "ill02"}, ["4a_ill3"] = {p = "ill03", s = 12}, ["4a_con1"] = {p = "con01"}, ["4a_con2"] = {p = "con02", s = 13}, ["4a_con3"] = {p = "con03", s = 13},
["4a_str"] = {p = "str00"}, ["4a_end"] = {p = "end00"}, ["4a_agi"] = {p = "agi00"}, ["4a_spd"] = {p = "spd00"}, ["4a_int"] = {p = "int00"}, ["4a_wil"] = {p = "wil00"}, ["4a_per"] = {p = "per00"}},
STAR = {["4as_atr4"]=true,["4nm_star_apprentice1a"]=true,["4nm_star_lady1a"]=true, ["4nm_star_lord1a"]=true, ["4nm_star_lover1a"]=true, ["4nm_star_mage1a"]=true, ["4nm_star_steed1a"]=true, ["4nm_star_thief1a"]=true,
["4nm_star_warrior1a"]=true, ["4nm_star_ritual1a"]=true, ["4nm_star_ritual2a"]=true, ["4nm_star_ritual3a"]=true, ["4nm_star_serpent3a"]=true, ["4nm_star_shadow1a"]=true, ["4nm_star_shadow2a"]=true, ["4nm_star_shadow3a"]=true},
NEWSP = {{600,0,600,10,20,0,10,10,"Dash"},	{500,2,500,0,0,0,0,10,"Teleport"},
{501,0,501,5,10,0,5,30,"Recharge"},			{502,0,502,10,20,0,5,30,"Repair weapon"},	{503,0,503,20,30,0,5,30,"Repair armor"},		{504,2,504,8,12,0,60,5,"Lantern"},			{505,0,505,0,0,0,0,100,"Town teleport"},
{506,0,506,0,0,0,60,5,"Magic control"},		{507,0,507,10,15,0,30,30,"Reflect magic"},	{508,0,508,5,10,0,30,20,"Kinetic shield"},		{509,0,509,20,30,0,20,20,"Life leech"},		{510,0,510,20,30,0,10,20,"Time shift"},
{601,0,601,0,0,0,60,5,"Bound ammo"},		{602,2,602,40,60,1,0,20,"Kinetic strike"},	{603,0,603,0,0,0,60,30,"Bound weapon"},			{"504a",0,504,8,12,0,60,5,"Lantern (smart)"},	{"602a",2,602,100,150,1,0,50,"Kinetic explode"},
{511,0,511,8,12,0,30,10,"Charge fire"},		{512,0,512,8,12,0,30,10,"Charge frost"},	{513,0,513,8,12,0,30,10,"Charge lightning"},	{514,0,514,8,12,0,30,10,"Charge poison"},	{515,0,515,8,12,0,30,10,"Charge chaos"},
{516,0,516,3,5,0,15,30,"Aura fire"},		{517,0,517,3,5,0,15,30,"Aura frost"},		{518,0,518,3,5,0,15,30,"Aura lightning"},		{519,0,519,3,5,0,15,50,"Aura poison"},		{520,0,520,3,5,0,15,40,"Aura chaos"},
{521,2,521,8,12,20,10,30,"AoE fire"},		{522,2,522,8,12,20,10,30,"AoE frost"},		{523,2,523,8,12,20,10,30,"AoE lightning"},		{524,2,524,8,12,20,10,50,"AoE poison"},		{525,2,525,8,12,20,10,40,"AoE chaos"},
{526,2,526,40,60,15,0,15,"Rune fire"},		{527,2,527,40,60,15,0,15,"Rune frost"},		{528,2,528,40,60,15,0,15,"Rune lightning"},		{529,2,529,40,60,15,0,25,"Rune poison"},	{530,2,530,40,60,15,0,20,"Rune chaos"},
{531,0,531,8,12,0,30,10,"Explode fire"},	{532,0,532,8,12,0,30,10,"Explode frost"},	{533,0,533,8,12,0,30,10,"Explode lightning"},	{534,0,534,8,12,0,30,10,"Explode poison"},	{535,0,535,8,12,0,30,10,"Explode chaos"},
{536,1,536,10,30,10,0,30,"Spread fire"},	{537,1,537,10,30,10,0,30,"Spread frost"},	{538,1,538,10,30,10,0,30,"Spread lightning"},	{539,1,539,10,30,10,0,50,"Spread poison"},	{540,1,540,10,30,10,0,40,"Spread chaos"},
{541,1,541,50,100,15,0,30,"Discharge fire"},{542,1,542,50,100,15,0,30,"Discharge frost"}, {543,1,543,50,100,15,0,30,"Discharge lightning"}, {544,1,544,50,100,15,0,50,"Discharge poison"},{545,1,545,50,100,15,0,40,"Discharge chaos"},
{546,1,546,3,10,1,0,15,"Ray fire"},			{547,1,547,3,10,1,0,15,"Ray frost"},		{548,1,548,3,10,1,0,15,"Ray lightning"},		{549,1,549,3,10,1,0,25,"Ray poison"},		{550,1,550,3,10,1,0,20,"Ray chaos"},
{551,2,551,10,20,5,20,10,"Totem fire"},		{552,2,552,10,20,5,20,10,"Totem frost"},	{553,2,553,10,20,5,20,10,"Totem lightning"},	{554,2,554,10,20,5,20,10,"Totem poison"},	{555,2,555,10,20,5,20,10,"Totem chaos"},
{556,0,556,10,15,0,30,30,"Empower fire"},	{557,0,557,10,15,0,30,30,"Empower frost"},	{558,0,558,10,15,0,30,30,"Empower lightning"},	{559,0,559,10,15,0,30,30,"Empower poison"},	{560,0,560,10,15,0,30,30,"Empower chaos"},
{561,0,561,10,15,0,30,30,"Reflect fire"},	{562,0,562,10,15,0,30,30,"Reflect frost"},	{563,0,563,10,15,0,30,30,"Reflect lightning"},	{564,0,564,10,15,0,30,30,"Reflect poison"},	{565,0,565,10,15,0,30,30,"Reflect chaos"},
{566,2,566,10,30,20,1,30,"Wave fire"},		{567,2,567,10,30,20,1,30,"Wave frost"},		{568,2,568,10,30,20,1,30,"Wave lightning"},		{569,2,569,10,30,20,1,50,"Wave poison"},	{570,2,570,10,30,20,1,40,"Wave chaos"}},
SFS = {500,501,502,503,504,"504a",505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,
551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,600,601,602,"602a",603},
SSEL = {["marayn dren"] = {"firefist", "Fireball_large", "firebloom", "flamebolt", "frostfist", "Frostball_large", "frostbloom", "frost bolt", "stormhand", "shockball_large", "shockbloom", "lightning bolt",
"disintegrate armor", "disintegrate weapon", "weakness to fire", "fierce frost shield", "fierce fire shield", "fierce shock shield"},
["sharn gra-muzgob"] = {"stamina", "rilm's cure", "balyna's efficacious balm", "balyna's perfect balm", "veloth's benison", "veloth's grace", "rapid regenerate", "mother's kiss", "strong heal companion", "great heal companion",
"restore willpower", "restore endurance", "restore personality", "restore strength", "restore speed", "restore luck", "restore agility", "restore intelligence",
"balyna's antidote", "cure poison", "cure poison touch", "Cure Blight_Self", "Cure Blight Disease", "cure common disease", "cure common disease other", "free action"},
["masalinie merian"] = {"recall", "mark", "divine intervention", "almsivi intervention", "resist fire", "resist frost", "resist shock", "resist magicka", "resist poison", "resist common disease", "llivam's reversal"},
["estirdalin"] = {"deadly poison [ranged]", "potent poison [ranged]", "burden touch", "cruel earwig", "noise", "gash spirit [ranged]", "daedric bite"},
["onlyhestandsthere"] = {"daedric health", "daedric willpower", "daedric luck", "daedric intelligence", "daedric personality", "daedric endurance", "daedric speed", "daedric strength", "daedric agility",
"great resist fire", "great resist frost", "great resist shock", "great resist magicka", "greater resist poison", "great resist common disease",
"absorb spell points", "absorb spell points [ranged]", "absorb health", "absorb health [ranged]", "absorb fatigue", "absorb fatigue [ranged]",
"absorb intelligence", "absorb intelligence [ranged]", "absorb willpower", "absorb willpower [ranged]", "absorb endurance", "absorb endurance [ranged]", "absorb strength", "absorb strength [ranged]",
"absorb agility", "absorb agility [ranged]", "absorb speed", "absorb speed [ranged]", "absorb luck", "absorb luck [ranged]", "absorb personality", "absorb personality [ranged]"},
["uleni heleran"] = {"blessed touch", "blessed word", "frenzy humanoid", "frenzy creature", "demoralize humanoid"},
["arrille"] = {"flame", "fire bite", "fireball", "shard", "frostbite", "frostball", "spark", "shock", "shockball", "rest of st. merris", "balyna's soothing balm", "hearth heal", "regenerate", "heal companion"},
["erer darothril"] = {"burning touch", "fire storm", "cruel firebloom", "wizard's fire", "god's fire", "freezing touch", "frost storm", "brittlewind", "wizard rend", "god's frost",
"shocking touch", "lightning storm", "wild shockbloom", "dire shockball", "god's spark"},
["felen maryon"] = {"command beast", "commanding touch", "drain heavy armor", "drain illusion", "drain light armor", "drain long blade", "drain marksman", "drain medium armor", "drain mercantile"}},
ING = {["4nm"]=true, ["4nm_met"]=true, ["4nm_tet"]=true, ["Enchant_right"]=true, ["Enchant_left"]=true,
["Blur"]=true, ["Rally"]=true, ["Spawn_buff"]=true, ["Summon"]=true, ["Dodge"]=true, ["Parry"]=true, ["Survival_instinct"]=true, ["Rest"]=true,
["Electroshock"]=true, ["Freeze"]=true, ["Burning"]=true, ["Poisoning"]=true, ["Decay"]=true, ["KO"]=true},
BREG = {"CW","RF","RFS","RAY","SG","PR","ElSh","AUR","RUN","TOT","AOE","DC","WAV","EXP","TS"},	--SREG = {"DC"},
BU = {{n="aureal",{2,13,20,30,10,1}}, {n="goldaura",{0,3,10,20,0,180}}, {n="elemaura",{0,4,10,20,0,180}, {0,556,10,20,0,180}, {0,561,10,20,0,180}},
{n="Fire_arrow",{2,14,5,10,1,1}},	{n="Fire_ball",{2,14,10,20,5,1}},	{n="Fire_bolt",{2,14,20,30,10,1}},	{n="Fire_touch",{1,14,5,10,1,1}},
{n="Frost_arrow",{2,16,5,10,1,1}},	{n="Frost_ball",{2,16,10,20,5,1}},	{n="Frost_bolt",{2,16,20,30,10,1}},	{n="Frost_touch",{1,16,5,10,1,1}},
{n="Shock_arrow",{2,15,5,10,1,1}},	{n="Shock_ball",{2,15,10,20,5,1}},	{n="Shock_bolt",{2,15,20,30,10,1}},	{n="Shock_touch",{1,15,5,10,1,1}},
{n="Poison_arrow",{2,27,1,2,1,5}},	{n="Poison_ball",{2,27,2,4,5,5}},	{n="Poison_bolt",{2,27,4,6,10,5}},
{n="Chaos_arrow",{2,23,5,10,1,1}},	{n="Chaos_ball",{2,23,10,20,5,1}},	{n="Chaos_bolt",{2,23,20,30,10,1}},	{n="Chaos_touch",{1,23,5,10,1,1}},
{n="Elemental_touch",{1,14,5,10,1,1},{1,16,5,10,1,1},{1,15,5,10,1,1}},	{n="Storm_touch",{1,15,5,10,1,1},{1,16,5,10,1,1}},	{n="Eerie_touch",{1,23,5,10,1,1},{1,16,5,10,1,1}}, {n="Filth_touch",{1,23,5,10,1,1},{1,27,5,10,1,1}},
{n="Poison_bite",{0,27,1,2,0,5},w=1}, {n="Spider_bite",{0,27,2,3,0,10},{0,45,1,1,0,3},w=1}},
CLEN = {500,500,500,1000,1000,1000,500,1000,1000,[0]=500}, AREN = {500,100,100,300,500,1000,1000,500,500,500,[0]=1000}, ARW = {6,2,2,3,3,1,1,5,[0]=2},
AltW = {2, 1, 4, 3, 3, 1, 8, 7}, W1to2 = {[1] = 2, [3] = 4, [7] = 8},
AG = {[34] = "KO", [35] = "KO"}, AGH = {[19]=1, [20]=1, [21]=1, [22]=1, [23]=1}, AGHS = {[19] = true, [20] = true, [21] = true, [22] = true, [23] = true, [24] = true, [25] = true, [26] = true},
ASN = {[1] = 1, [14] = 1, [15] = 1, [18] = 1, [19] = 1},
ASP = {[4] = 1, [5] = 2, [6] = 2, [7] = 2},
PSO = {{{1,4},{2,4},{2,4}}, {{2,4},{2,4},{3,3}}, {{2,4},{3,3},{3,3}}},
Traum = {"strength", "endurance", "agility", "speed", "intelligence"},	HealStat = {"endurance", "strength", "agility", "speed", "intelligence", "willpower", "personality"},
BW = {{"dagger", "tanto", "kris", "knife", "knuckle", "shortsword", "wakizashi", "machete"},
{"longsword", "broadsword", "sword", "grossmesser", "katana", "saber", "scimitar", "shamshir", "rapier", "waraxe", "axe", "mace", "club"},
{"claymore", "bastard", "daikatana", "kreigmesser", "battleaxe", "grandaxe", "warhammer"},
{"spear", "longspear", "naginata", "halberd", "bardiche", "glaive", "warscythe", "pitchfork", "staff", "longbow", "crossbow"}},
CStats = {"strength", "endurance", "agility", "speed", "intelligence", "willpower", "luck", "personality", "combat", "magic", "stealth"},
CrBlackList = {["BM_hircine_straspect"] = 200, ["BM_hircine_spdaspect"] = 150, ["BM_hircine_huntaspect"] = 150, ["BM_hircine"] = 100, ["vivec_god"] = 150, ["Almalexia_warrior"] = 150, ["almalexia"] = 150,
["dagoth_ur_1"] = 150, ["dagoth_ur_2"] = 150, ["Imperfect"] = 200, ["lich_barilzar"] = 100, ["lich_relvel"] = 100, ["yagrum bagarn"] = 10, ["bm_frost_giant"] = 100, ["dagoth araynys"] = 150, ["dagoth endus"] = 150,
["dagoth gilvoth"] = 150, ["dagoth odros"] = 150, ["dagoth tureynul"] = 150, ["dagoth uthol"] = 150, ["dagoth vemyn"] = 150, ["heart_akulakhan"] = 1000, ["mudcrab_unique"] = 20, ["scamp_creeper"] = 10, ["4nm_target"] = 0},
CID = {["bonewalker"] = "zombirise", ["bonewalker_weak"] = "zombirise", ["Bonewalker_Greater"] = "zombirise", ["golden saint"] = "auril", ["golden saint_summon"] = "auril",
["BM_bear_black"] = "bear", ["BM_bear_brown"] = "bear", ["BM_bear_snow_unique"] = "bear", ["BM_wolf_grey"] = "wolf", ["BM_wolf_red"] = "wolf", ["BM_wolf_snow_unique"] = "wolf", ["BM_wolf_grey_lvl_1"] = "wolf",
["centurion_spider"] = "dwem", ["centurion_sphere"] = "dwem", ["centurion_steam"] = "dwem", ["centurion_projectile"] = "dwem", ["centurion_steam_advance"] = "dwem",
["centurion_spider_miner"] = "dwem", ["centurion_spider_tower"] = "dwem", ["centurion_sword"] = "dwem", ["centurion_weapon"] = "dwem", ["centurion_tank"] = "dwem",
},
CAR = {["atronach_flame"] = 50, ["atronach_flame_summon"] = 50, ["atronach_frost"] = 100, ["atronach_frost_summon"] = 100, ["atronach_storm"] = 150, ["atronach_storm_summon"] = 150, ["atronach_frost_BM"] = 150,
["atronach_flame_lord"] = 100, ["atronach_frost_lord"] = 200, ["atronach_storm_lord"] = 250,

["dremora"] = 100, ["dremora_summon"] = 100, ["dremora_lord"] = 150, ["dremora_mage"] = 30, ["dremora_mage_s"] = 30, ["xivkyn"] = 100, ["xivkyn_s"] = 100, ["skaafin"] = 80, ["skaafin_archer"] = 50, ["skaafin_archer_s"] = 50,
["golden saint"] = 120, ["golden saint_summon"] = 120, ["mazken"] = 80, ["mazken_s"] = 80,
["scamp"] = 5, ["clannfear"] = 30, ["clannfear_lesser"] = 20, ["clannfear_summon"] = 30, ["vermai"] = 10, ["hunger"] = 10, ["hunger_summon"] = 10, ["ogrim"] = 60, ["ogrim titan"] = 80, ["daedroth"] = 30, ["daedroth_summon"] = 30,
["winged twilight"] = 10, ["winged twilight_summon"] = 10, ["daedraspider"] = 15, ["daedraspider_s"] = 15, ["xivilai"] = 50, ["xivilai_s"] = 50,

["skeleton"] = 20, ["skeleton_summon"] = 20, ["skeleton entrance"] = 20, ["skeleton_weak"] = 10, ["skeleton archer"] = 20, ["skeleton_archer_s"] = 20, ["skeleton_mage"] = 20, ["skeleton_mage_s"] = 20, 
["skeleton warrior"] = 50, ["skeleton champion"] = 60, ["skeleton_knight"] = 80, ["bm skeleton champion gr"] = 80,
["bonewalker"] = 5, ["bonewalker_weak"] = 5, ["Bonewalker_Greater"] = 5, ["Bonewalker_Greater_summ"] = 5, ["bonewalker_summon"] = 5, ["bonelord"] = 20, ["bonelord_summon"] = 20,
["lich"] = 50, ["lich_elder"] = 100, ["BM_wolf_skeleton"] = 10, ["BM_wolf_bone_summon"] = 10,

["BM_draugr01"] = 50, ["draugr"] = 50, ["draugr_fem"] = 50, ["draugr_soldier"] = 80, ["draugr_warrior"] = 100, ["draugr_general"] = 150, ["draugr_priest"] = 50,

["corprus_stalker"] = 5, ["corprus_lame"] = 15, ["ash_slave"] = 10, ["ash_zombie"] = 10, ["ash_ghoul"] = 20, ["ash_ghoul_high"] = 30,
["ash_revenant"] = 80, ["ash_zombie_warrior"] = 100, ["ash_ghoul_warrior"] = 100, ["ascended_sleeper"] = 50,

["centurion_spider"] = 150, ["centurion_sphere"] = 200, ["centurion_sphere_summon"] = 200, ["centurion_steam"] = 200, ["centurion_projectile"] = 150, ["centurion_steam_advance"] = 200,
["centurion_spider_miner"] = 150, ["centurion_spider_tower"] = 150, ["centurion_sword"] = 200, ["centurion_weapon"] = 200, ["centurion_tank"] = 250,

["Rat"] = 5, ["rat_diseased"] = 5, ["rat_blighted"] = 5, ["nix-hound"] = 20, ["nix-hound blighted"] = 20, ["nix_mount"] = 30, ["guar"] = 20, ["guar_feral"] = 20, ["guar_pack"] = 30,
["alit"] = 20, ["alit_diseased"] = 20, ["alit_blighted"] = 20, ["dreugh"] = 50, ["dreugh_soldier"] = 80, ["dreugh_land"] = 80, ["slaughterfish"] = 3, ["Slaughterfish_Small"] = 3, ["slaughterfish_electro"] = 3,
["kagouti"] = 30, ["kagouti_diseased"] = 30, ["kagouti_blighted"] = 30, ["kagouti_dire"] = 40,
["kwama worker"] = 40, ["kwama worker diseased"] = 40, ["kwama worker blighted"] = 40, ["kwama worker entrance"] = 40, ["kwama warrior"] = 60, ["kwama warrior blighted"] = 60,
["kwama forager"] = 0, ["kwama forager blighted"] = 0, ["scrib"] = 5, ["scrib diseased"] = 5, ["scrib blighted"] = 5,
["mudcrab"] = 50, ["mudcrab-Diseased"] = 50, ["mudcrab_king"] = 60, ["mudcrab_rock"] = 100, ["mudcrab_titan"] = 80,
["netch_bull"] = 30, ["netch_bull_ranched"] = 30, ["netch_betty"] = 10, ["netch_betty_ranched"] = 10,
["shalk"] = 30, ["shalk_diseased"] = 30, ["shalk_blighted"] = 30,
["durzog_wild"] = 40, ["durzog_wild_weaker"] = 30, ["durzog_war"] = 50, ["durzog_war_trained"] = 50, ["durzog_diseased"] = 40,
["goblin_grunt"] = 30, ["goblin_footsoldier"] = 40, ["goblin_bruiser"] = 50, ["goblin_handler"] = 50, ["goblin_officer"] = 60, ["goblin_shaman"] = 20,
["fabricant_verminous"] = 100, ["fabricant_summon"] = 100, ["fabricant_hulking"] = 150,
["BM_wolf_grey"] = 20, ["BM_wolf_red"] = 20, ["BM_wolf_grey_lvl_1"] = 20, ["BM_wolf_snow_unique"] = 20, ["BM_wolf_grey_summon"] = 20,
["BM_bear_black"] = 40, ["BM_bear_brown"] = 40, ["BM_bear_snow_unique"] = 40, ["BM_bear_black_summon"] = 40,

["BM_riekling"] = 20, ["BM_riekling_berserk"] = 30, ["BM_riekling_hunter"] = 30, ["BM_riekling_warrior"] = 50, ["BM_riekling_heavy"] = 100, ["BM_riekling_chieftain"] = 80, ["BM_riekling_shaman"] = 30, 
["BM_riekling_mounted"] = 30, ["BM_riekling_mounted_war"] = 50, 
["BM_frost_boar"] = 20, ["BM_spriggan"] = 50, ["BM_ice_troll"] = 80, ["BM_ice_troll_tough"] = 80},

CDOD = {["atronach_flame"] = 1, ["atronach_flame_summon"] = 1, ["atronach_flame_lord"] = 1, ["scamp"] = 1, ["clannfear"] = 1, ["clannfear_lesser"] = 1, ["clannfear_summon"] = 1, ["vermai"] = 1,
["hunger"] = 1, ["hunger_summon"] = 1, ["winged twilight"] = 1, ["winged twilight_summon"] = 1, ["daedraspider"] = 1, ["daedraspider_s"] = 1,
["bonelord"] = 1, ["bonelord_summon"] = 1, ["BM_draugr01"] = 1, ["draugr"] = 1, ["ancestor_ghost"] = 1, ["ancestor_ghost_greater"] = 1, ["dwarven ghost"] = 1,
["centurion_sphere"] = 1, ["centurion_sphere_summon"] = 1, ["centurion_projectile"] = 1,
["goblin_bruiser"] = 1, ["fabricant_verminous"] = 1, ["fabricant_summon"] = 1,
["kwama forager"] = 1, ["kwama forager blighted"] = 1, ["Rat"] = 1, ["rat_diseased"] = 1, ["rat_blighted"] = 1, ["nix-hound"] = 1, ["nix-hound blighted"] = 1, ["nix_mount"] = 1,
["dreugh"] = 1, ["dreugh_soldier"] = 1, ["dreugh_land"] = 1, ["slaughterfish"] = 1, ["Slaughterfish_Small"] = 1, ["slaughterfish_electro"] = 1,
["BM_wolf_grey"] = 1, ["BM_wolf_red"] = 1, ["BM_wolf_grey_lvl_1"] = 1, ["BM_wolf_snow_unique"] = 1, ["BM_wolf_grey_summon"] = 1, ["BM_wolf_skeleton"] = 1, ["BM_wolf_bone_summon"] = 1, ["BM_spriggan"] = 1},


CDIS = {["corprus_lame"] = "black-heart blight", ["corprus_stalker"] = "ash-chancre", ["ash_ghoul"] = "ash woe blight", ["ash_slave"] = "ash woe blight", ["ash_zombie"] = "ash woe blight",
["ash_ghoul_high"] = "ash woe blight", ["ash_ghoul_warrior"] = "ash woe blight", ["ash_zombie_warrior"] = "ash woe blight", ["ascended_sleeper"] = "ash woe blight", ["ash_revenant"] = "ash-chancre", 
["alit_blighted"] = "black-heart blight", ["nix-hound blighted"] = "black-heart blight", ["rat_blighted"] = "black-heart blight", ["cliff racer_blighted"] = "ash-chancre", ["kagouti_blighted"] = "chanthrax blight",
["shalk_blighted"] = "ash woe blight",

["alit_diseased"] = "ataxia", ["cliff racer_diseased"] = "helljoint", ["kagouti_diseased"] = "yellow tick", ["mudcrab-Diseased"] = "swamp fever", ["rat_diseased"] = "witbane",
["scrib diseased"] = "droops", ["kwama worker diseased"] = "droops", ["shalk_diseased"] = "collywobbles",
["BM_wolf_red"] = "rattles", ["BM_bear_brown"] = "rust chancre", ["durzog_diseased"] = "rotbone",

["kagouti_dire"] = "rockjoint", ["nix_mount"] = "dampworm", ["dreugh_land"] = "wither", ["netch_bull"] = "serpiginous dementia", ["netch_betty"] = "serpiginous dementia", ["slaughterfish"] = "greenspore",
["bonewalker"] = "brown rot", ["Bonewalker_Greater"] = "brown rot", ["bonewalker_weak"] = "brown rot"},

CPOI = {["alit"] = {"Poison_bite",50}, ["alit_diseased"] = {"Poison_bite",80}, ["alit_blighted"] = {"Poison_bite",80},
["kwama forager"] = {"Poison_bite",30}, ["kwama forager blighted"] = {"Poison_bite",50}, ["netch_bull"] = {"Poison_bite",30},
["vermai"] = {"Poison_bite",30}, ["daedraspider"] = {"Spider_bite",30}, ["daedraspider_s"] = {"Spider_bite",10}, ["daedroth"] = {"Poison_bite",50}, ["daedroth_summon"] = {"Poison_bite",30}},

CMAG = {["atronach_flame"] = {"Fire_touch",100}, ["atronach_flame_summon"] = {"Fire_touch",100}, ["atronach_flame_lord"] = {"Fire_touch",100}, 
["atronach_frost"] = {"Frost_touch",100}, ["atronach_frost_summon"] = {"Frost_touch",100}, ["atronach_frost_lord"] = {"Frost_touch",100}, ["atronach_frost_BM"] = {"Frost_touch",100}, 
["atronach_storm"] = {"Shock_touch",100}, ["atronach_storm_summon"] = {"Shock_touch",100}, ["atronach_storm_lord"] = {"Shock_touch",100},
["winged twilight"] = {"Storm_touch",30}, ["winged twilight_summon"] = {"Storm_touch",20},
["dremora_mage"] = {"Elemental_touch",50}, ["dremora_mage_s"] = {"Elemental_touch",30}, ["golden saint"] = {"Elemental_touch",20}, ["golden saint_summon"] = {"Elemental_touch",20},
["skeleton_mage"] = {"Elemental_touch",20}, ["skeleton_mage_s"] = {"Elemental_touch",20},
["bonelord"] = {"Chaos_touch",100}, ["bonelord_summon"] = {"Chaos_touch",50}, ["lich"] = {"Filth_touch",100}, ["lich_elder"] = {"Eerie_touch",100}, ["draugr_priest"] = {"Chaos_touch",50},
["ancestor_ghost"] = {"Frost_touch",50}, ["ancestor_ghost_summon"] = {"Frost_touch",30}, ["ancestor_ghost_greater"] = {"Eerie_touch",50}, ["dwarven ghost"] = {"Frost_touch",80}, 
["shalk"] = {"Fire_touch",30}, ["shalk_diseased"] = {"Fire_touch",20}, ["shalk_blighted"] = {"Fire_touch",40}, ["netch_betty"] = {"Shock_touch",30},
["BM_wolf_snow_unique"] = {"Frost_touch",20}, ["BM_bear_snow_unique"] = {"Frost_touch",20}, ["slaughterfish_electro"] = {"Shock_touch",50}},

MAC = {[0] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow"},
["atronach_flame"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_summon"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_lord"] = {"Fire_bolt"},
["atronach_frost"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_summon"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_lord"] = {"Frost_bolt"}, ["atronach_frost_BM"] = {"Frost_ball","Frost_bolt"},
["atronach_storm"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_summon"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_lord"] = {"Shock_bolt"},
["dremora"] = {"Fire_arrow","Fire_ball"}, ["dremora_summon"] = {"Fire_arrow","Fire_ball"}, ["dremora_lord"] = {"Fire_ball","Fire_bolt"},
["golden saint"] = {"Fire_bolt","Frost_bolt","Shock_bolt"}, ["golden saint_summon"] = {"Fire_bolt","Frost_bolt","Shock_bolt"},
["mazken"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"}, ["mazken_s"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"},
["hunger"] = {"Chaos_arrow","Chaos_ball"}, ["hunger_summon"] = {"Chaos_arrow","Chaos_ball"},
["scamp"] = {"Fire_arrow"}, ["scamp_summon"] = {"Fire_arrow"}, ["daedroth"] = {"Poison_arrow","Poison_ball"}, ["daedroth_summon"] = {"Poison_arrow","Poison_ball"},
["winged twilight"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"}, ["winged twilight_summon"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"},
["dremora_mage"] = {"Fire_ball","Frost_ball","Shock_ball","Fire_bolt","Frost_bolt","Shock_bolt"}, ["dremora_mage_s"] = {"Fire_ball","Frost_ball","Shock_ball","Fire_bolt","Frost_bolt","Shock_bolt"},
["daedraspider"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"}, ["daedraspider_s"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"},
["xivilai"] = {"Fire_ball","Chaos_ball"}, ["xivilai_s"] = {"Fire_ball","Chaos_ball"},
["xivkyn"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"}, ["xivkyn_s"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"},

["ancestor_ghost"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_summon"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_greater"] = {"Chaos_arrow","Chaos_ball","Frost_arrow","Frost_ball"},
["Bonewalker_Greater"] = {"Chaos_arrow"}, ["Bonewalker_Greater_summ"] = {"Chaos_arrow"},
["bonelord"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"}, ["bonelord_summon"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"},
["skeleton_mage"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball"},
["skeleton_mage_s"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball"},
["lich"] = {"Frost_ball","Poison_ball","Chaos_ball","Frost_bolt","Poison_bolt","Chaos_bolt"}, ["lich_elder"] = {"Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},
["ash_revenant"] = {"Poison_ball","Chaos_ball"}, ["draugr_priest"] = {"Frost_ball","Chaos_ball"},

["ash_slave"] = {"Fire_arrow","Frost_arrow","Shock_arrow"}, ["ash_ghoul"] = {"Chaos_ball","Chaos_bolt"}, ["ash_ghoul_warrior"] = {"Chaos_arrow","Chaos_ball"},
["ash_ghoul_high"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"}, ["ascended_sleeper"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},

["centurion_spider_tower"] = {"Shock_arrow"}, ["centurion_spider_miner"] = {"Fire_arrow"},
["kwama warrior"] = {"Poison_arrow","Poison_ball"}, ["kwama warrior blighted"] = {"Poison_arrow","Poison_ball"},
["netch_bull"] = {"Poison_arrow","Poison_ball"}, ["netch_betty"] = {"Shock_arrow","Shock_ball"},
["goblin_handler"] = {"Fire_arrow"}, ["goblin_officer"] = {"Fire_arrow"}, ["goblin_shaman"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Fire_ball","Frost_ball","Shock_ball"},
["BM_riekling_shaman"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Fire_ball","Frost_ball","Shock_ball"},
["BM_spriggan"] = {"Frost_ball","Poison_ball"}},
Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["daedraspider_s"] = true,["dremora_mage_s"] = true,["skaafin_archer_s"] = true,["xivkyn_s"] = true,["xivilai_s"] = true,["mazken_s"] = true,["skeleton_mage_s"] = true,["skeleton_archer_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true},
UndMinion = {"skeleton_weak", "bonewalker_weak", "skeleton", "bonewalker", "skeleton archer", "skeleton warrior", "skeleton champion", "Bonewalker_Greater"},
Blight = {"ash woe blight", "black-heart blight", "chanthrax blight", "ash-chancre"},
atrbot = {["atronach_flame"] = {4,556,561}, ["atronach_flame_summon"] = {4,556,561}, ["atronach_flame_lord"] = {4,556,561,114},
["atronach_frost"] = {6,557,562}, ["atronach_frost_summon"] = {6,557,562}, ["atronach_frost_lord"] = {6,557,562,115},
["atronach_storm"] = {5,558,563}, ["atronach_storm_summon"] = {5,558,563}, ["atronach_storm_lord"] = {5,558,563,116}},
BlackItem = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true},
BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["4nm_stone"] = true},
DurKF = {[14]=3,[15]=3,[16]=3,[23]=3,[27]=3,[22]=3,[24]=3,[25]=3,[26]=3,[37]=5,[38]=5,[74]=3,[75]=3,[76]=3,[77]=3,[78]=3,[86]=3,[87]=3,[88]=3},
nomag = {[39] = true, [45] = true, [46] = true, [69] = true, [70] = true, [72] = true, [73] = true},
--SID = {["4s_DC"] = "discharge", ["4s_CWT"] = "CWT", ["4s_rune1"] = "rune", ["4s_totem1"] = "totem", ["4s_totem2"] = "totem", ["4s_totemexp"] = "totem"},
CME = {[4] = {25, "Freeze", 1}, [6] = {14, "Burning", 5}, [5] = {24, "Electroshock", 2}, [72] = {17, "Poisoning", 0.1}, [516] = {25, "Freeze", 1}, [517] = {14, "Burning", 5}, [518] = {24, "Electroshock", 2}},
ELSH = {[4] = {id = 14, ts = 0}, [5] = {id = 15, ts = 0}, [6] = {id = 16, ts = 0}},
LID = {[0] = {255,0,128}, [1] = {255,128,0}, [2] = {0,255,255}, [3] = {128,0,255}, [4] = {0,128,64}}, MEC = {3, 3, 4, 5, 4, [0] = 4},
RES = {[14] = "resistFire", [16] = "resistFrost", [15] = "resistShock", [27] = "resistPoison"},
EDAT = {[507] = true, [508] = true, [509] = true,
[511] = true, [512] = true, [513] = true, [514] = true, [515] = true, [516] = true, [517] = true, [518] = true, [519] = true, [520] = true, [531] = true, [532] = true, [533] = true, [534] = true, [535] = true,
[556] = true, [557] = true, [558] = true, [559] = true, [560] = true, [561] = true, [562] = true, [563] = true, [564] = true, [565] = true},
UItcolor = {{1,1,1},{0,1,0},{0,1,1},{1,1,0}},
TPP = {{-23000, -15200, 700}, {-14300, 52400, 2300}, {30000, -77600, 2000}, {150300, 31800, 900}, {17800, -101900, 500}, {-11200, 20000, 1500}, {53800, -51000, 400}, {-86800, 92300, 1200},
{1900, -56800, 1700}, {125000, -105200, 1000}, {125200, 45200, 1800}, {109500, 116000, 600}, {-21600, 103200, 2200}, {109300, -62000, 2200}, {60200, 183300, 500}, {-11100, -71000, 500},
{-46600, -38100, 400}, {-60100, 26700, 400}, {-68400, 140400, 400}, {-85400, 125600, 1200}, {94600, 115800, 1800}, {87500, 118100, 3700}},
AoEmod = {[0] = "4nm_aoe_vitality", [1] = "4nm_aoe_fire", [2] = "4nm_aoe_frost", [3] = "4nm_aoe_shock", [4] = "4nm_aoe_poison"},
BotQ = {"bargain", "cheap", "standard", "quality", "exclusive"},
BotIc = {["m\\Tx_potion_bargain_01.tga"] = "bargain", ["m\\Tx_potion_cheap_01.tga"] = "cheap", ["m\\Tx_potion_fresh_01.tga"] = "cheap",
["m\\Tx_potion_standard_01.tga"] = "standard", ["m\\Tx_potion_quality_01.tga"] = "quality", ["m\\Tx_potion_exclusive_01.tga"] = "exclusive"},
BotMod = {["m\\misc_potion_bargain_01.nif"] = {"w\\4nm_bottle1.nif", "m\\Tx_potion_bargain_01.tga"}, ["m\\misc_potion_cheap_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_cheap_01.tga"},
["m\\misc_potion_fresh_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_fresh_01.tga"}, ["m\\misc_potion_standard_01.nif"] = {"w\\4nm_bottle3.nif", "m\\Tx_potion_standard_01.tga"},
["m\\misc_potion_quality_01.nif"] = {"w\\4nm_bottle4.nif", "m\\Tx_potion_quality_01.tga"}, ["m\\misc_potion_exclusive_01.nif"] = {"w\\4nm_bottle5.nif", "m\\Tx_potion_exclusive_01.tga"}},
Anvil = {furn_anvil00 = true, furn_t_fireplace_01 = true, furn_de_forge_01 = true, furn_de_bellows_01 = true, Furn_S_forge = true},
DWOBT = {[tes3.objectType.light] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.probe] = true},
BartT = {bartersAlchemy = true, bartersApparatus = true, bartersArmor = true, bartersBooks = true, bartersClothing = true, bartersEnchantedItems = true, bartersIngredients = true,
bartersLights = true, bartersLockpicks = true, bartersMiscItems = true, bartersProbes = true, bartersRepairTools = true, bartersWeapons = true},

MAT = {Dirt = "Dirt", Metal = "Metal", Stone = "Stone", Wood = "Wood", Ice = "Ice", Carpet = "Dirt", Grass = "Dirt", Gravel = "Dirt", Sand = "Dirt", Snow = "Dirt", Mud = "Mud", Water = "Water"},
MatD = {Dirt = 0.03, Metal = 0.1, Stone = 0.08, Wood = 0.04, Ice = 0.04, Carpet = 0.03, Grass = 0.03, Gravel = 0.05, Sand = 0.03, Snow = 0.02, Mud = 0.01, Water = 0.005},
Mat0 = {Water = true, Mud = true}, MatSpark = {Stone = true, Metal = true},

CF = {}, APP = {}, FIL = {}, TCash = {}}
local SP = {[0] = {s = 11, p1 = "alt1", p2 = "alt2", p3 = "alt3", p4 = "alt4", ps = "alt30"},	[1] = {s = 13, p1 = "con1", p2 = "con2", p3 = "con3", p4 = "con4", ps = "con30"},
			[2] = {s = 10, p1 = "des1", p2 = "des2", p3 = "des3", p4 = "des4", ps = "des30"},	[3] = {s = 12, p1 = "ill1", p2 = "ill2", p3 = "ill3", p4 = "ill4", ps = "ill30"},
			[4] = {s = 14, p1 = "mys1", p2 = "mys2", p3 = "mys3", p4 = "mys4", ps = "mys30"},	[5] = {s = 15, p1 = "res1", p2 = "res2", p3 = "res3", p4 = "res4", ps = "res30"}}
local MEP = {[14] = {s = 11, p0 = "des1a", p = "alt0"}, [16] = {s = 11, p0 = "des1b", p = "alt0"}, [15] = {s = 11, p0 = "des1c", p = "alt0"}, [27] = {s = 15, p0 = "des1d"}, p = "res5",
[85] = {s = 15, p = "res7"}, [86] = {s = 15, p = "res7"}, [87] = {s = 15, p = "res7"}, [88] = {s = 15, p = "res7"}, [89] = {s = 15, p = "res7"},
[79] = {s = 12, p = "ill22"}, [80] = {s = 12, p = "ill22"}, [81] = {s = 12, p = "ill22"}, [82] = {s = 12, p = "ill22"}, [83] = {s = 12, p = "ill22"}, [84] = {s = 12, p = "ill22"}, [117] = {s = 12, p = "ill22"},
[90] = {s = 12, p = "ill22"}, [91] = {s = 12, p = "ill22"}, [92] = {s = 12, p = "ill22"}, [93] = {s = 12, p = "ill22"}, [94] = {s = 12, p = "ill22"}, [95] = {s = 12, p = "ill22"},
[96] = {s = 12, p = "ill22"}, [97] = {s = 12, p = "ill22"}, [98] = {s = 12, p = "ill22"}, [99] = {s = 12, p = "ill22"},
[17] = {s = 12, p = "ill23"}, [18] = {s = 12, p = "ill23"}, [19] = {s = 12, p = "ill23"}, [20] = {s = 12, p = "ill23"}, [21] = {s = 12, p = "ill23"},
[28] = {s = 12, p = "ill23"}, [29] = {s = 12, p = "ill23"}, [30] = {s = 12, p = "ill23"}, [31] = {s = 12, p = "ill23"}, [32] = {s = 12, p = "ill23"}, [33] = {s = 12, p = "ill23"},
[34] = {s = 12, p = "ill23"}, [35] = {s = 12, p = "ill23"}, [36] = {s = 12, p = "ill23"},
[64] = {s = 12, p = "ill7"}, [65] = {s = 12, p = "ill7"}, [66] = {s = 12, p = "ill7"}}
local ME = {[102]=0,[103]=0,[104]=0,[105]=0,[106]=0,[107]=0,[108]=0,[109]=0,[110]=0,[111]=0,[112]=0,[113]=0,[114]=0,[115]=0,[116]=0,[134]=0,[137]=0,[138]=0,[139]=0,[140]=0,[141]=0,[142]=0,
[120]=3,[121]=3,[122]=3,[123]=3,[124]=3,[125]=3,[127]=3,[128]=3,[129]=3,[130]=3,[131]=3,[601]=3,[603]=3, [14]=1, [15]=1, [16]=1, [75]=2, [76]=2, [77]=2,
[79]=4, [80]=4, [81]=4, [82]=4, [83]=4, [84]=4, [117]=4, [90]=5, [91]=5, [92]=5, [93]=5, [94]=5, [95]=5, [97]=5, [98]=5, [99]=5,
[17]=6, [18]=6, [19]=6, [20]=6, [21]=6, [28]=7, [29]=7, [30]=7, [31]=7, [32]=7, [33]=7, [35]=7, [36]=7,
[3] = "shield", [4] = "shield", [5] = "shield", [6] = "shield", [61] = "teleport", [62] = "teleport", [63] = "teleport",
[511] = "charge", [512] = "charge", [513] = "charge", [514] = "charge", [515] = "charge", [516] = "aura", [517] = "aura", [518] = "aura", [519] = "aura", [520] = "aura",
[521] = "aoe", [522] = "aoe", [523] = "aoe", [524] = "aoe", [525] = "aoe", [526] = "rune", [527] = "rune", [528] = "rune", [529] = "rune", [530] = "rune",
[531] = "explode", [532] = "explode", [533] = "explode", [534] = "explode", [535] = "explode", [536] = "shotgun", [537] = "shotgun", [538] = "shotgun", [539] = "shotgun", [540] = "shotgun",
[541] = "discharge", [542] = "discharge", [543] = "discharge", [544] = "discharge", [545] = "discharge", [546] = "ray", [547] = "ray", [548] = "ray", [549] = "ray", [550] = "ray",
[551] = "totem", [552] = "totem", [553] = "totem", [554] = "totem", [555] = "totem", [556] = "empower", [557] = "empower", [558] = "empower", [559] = "empower", [560] = "empower",
[561] = "reflect", [562] = "reflect", [563] = "reflect", [564] = "reflect", [565] = "reflect", [566] = "wave", [567] = "wave", [568] = "wave", [569] = "wave", [570] = "wave"}
local MID = {[0] = 23, [1] = 14, [2] = 16, [3] = 15, [4] = 27, [5] = 23}
local EMP = {[14] = {e = "e556", rf = "e561", p = "des6a", p1 = "des5a", p2 = "wil9a", p3 = "end7a"}, [16] = {e = "e557", rf = "e562", p = "des6b", p1 = "des5b", p2 = "wil9b", p3 = "end7b"},
[15] = {e = "e558", rf = "e563", p = "des6c", p1 = "des5c", p2 = "wil9c", p3 = "end7c"}, [27] = {e = "e559", rf = "e564", p = "des6d", p1 = "des5d", p2 = "wil9d", p3 = "end7d"},
[23] = {e = "e560", rf = "e565", p = "des6e", p1 = "des5e", p2 = "wil9e"}}
local function adds(...) local splist = rf.object.spells	for i,s in ipairs{...} do splist:add(s) end end
local function rems(...) local splist = rf.object.spells	for i,s in ipairs{...} do splist:remove(s) end end
local function Mod(cost, m) local stat = (m or mp).magicka	stat.current = stat.current - cost 	if not m or m == mp then M.Mana.current = stat.current end end
local function Mag(id, r) return (tes3.getEffectMagnitude{reference = r or p, effect = id}) end
local function TFR(n, f) if n == 0 then f() else timer.delayOneFrame(function() TFR(n - 1, f) end) end end
local function Cpow(m, s1, s2, stam) return (100 + m.willpower.current/((m ~= mp or P.wil1) and 5 or 10) + m:getSkillValue(SP[s1].s)/((m ~= mp or P[SP[s1].p1]) and 5 or 10) + ((m ~= mp or P[SP[s2].p1]) and m:getSkillValue(SP[s2].s)/10 or 0))
* (stam and math.min(math.lerp(((m ~= mp or P.wil2) and 0.4 or 0.3) + ((m ~= mp or P[SP[s1].p3]) and 0.1 or 0), 1, m.fatigue.normalized*1.1), 1) or 1) end

L.SetGlobal = function()	local w = mp.readiedWeapon		w = w and w.object
G.stop = tes3.findGlobal("4nm_stoptraining")	G.leskoef = G.TR.tr1 and 1 or 3		if p.object.level * G.leskoef > D.L.les and G.stop.value == 1 then G.stop.value = 0 end
G.potlim = 50 + mp.endurance.base*(P.end9 and 0.7 or 0.5)		
G.spdodge = P.spd15 and 120 or 100
G.maxcomb = P.spd7 and 10 or 4


tes3.findGMST("fMajorSkillBonus").value = G.TR.tr1 and 0.5 or 0.75
tes3.findGMST("fMinorSkillBonus").value = G.TR.tr1 and 0.75 or 1
tes3.findGMST("fMiscSkillBonus").value = G.TR.tr1 and 1 or 1.25

tes3.findGMST("fUnarmoredBase2").value = P.una0 and 0.02 or 0.01

tes3.findGMST("fHoldBreathTime").value = (10 + mp.endurance.base/5 + mp.athletics.base/5) * (P.atl4 and 2 or 1)
tes3.findGMST("fSwimRunAthleticsMult").value = mp.athletics.base/(P.atl5 and 500 or 1000)

tes3.findGMST("fFatigueJumpBase").value = P.acr2 and math.max(20 - mp.acrobatics.base/10, 10) or 20
tes3.findGMST("fFatigueJumpMult").value = P.atl6 and math.max(30 - mp.athletics.base/10, 20) or 30

tes3.findGMST("fMagicItemRechargePerSecond").value = mp.enchant.base/(P.enc12 and 1000 or 2000)
tes3.findGMST("iSoulAmountForConstantEffect").value = P.enc9 and 200 or 400
tes3.findGMST("fEnchantmentChanceMult").value = P.enc14 and 2 or 3
tes3.findGMST("fEnchantmentConstantChanceMult").value = P.luc9 and 1 or 0.5
tes3.findGMST("fWeaponDamageMult").value = P.arm3 and math.max(0.1 - mp.armorer.base/2000, 0.05) or 0.1

tes3.findGMST("fSneakSpeedMultiplier").value = P.snek2 and math.min(0.75 + mp.sneak.base/400, 1) or 0.75
tes3.findGMST("fPickLockMult").value = P.sec1 and -1 or -2
tes3.findGMST("fTrapCostMult").value = P.sec2 and -1 or -2

tes3.findGMST("iTrainingMod").value = P.merc1 and 10 or 20
tes3.findGMST("fRepairMult").value = P.merc6 and 1 or 2
tes3.findGMST("fSpellMakingValueMult").value = P.merc7 and 10 or 20
tes3.findGMST("fEnchantmentValueMult").value = P.merc8 and 100 or 200
tes3.findGMST("fBarterGoldResetDelay").value = P.merc5 and 12 or 24

tes3.findGMST("iBarterSuccessDisposition").value = P.spec2 and 3 or 1
tes3.findGMST("iBarterFailDisposition").value = P.spec2 and -1 or -3
tes3.findGMST("iPerMinChance").value = P.spec1 and 10 or 0
tes3.findGMST("iPerMinChange").value = P.spec1 and 10 or 0
tes3.findGMST("fPerDieRollMult").value = P.spec6 and 0.2 or 0.1
tes3.findGMST("fBribe10Mod").value = P.spec4 and 20 or 10
tes3.findGMST("fBribe100Mod").value = P.spec4 and 50 or 30
tes3.findGMST("fBribe1000Mod").value = P.spec4 and 100 or 50
tes3.findGMST("fCrimeGoldTurnInMult").value = P.spec7 and math.max(1 - mp.mercantile.base/200, 0.5) or 1
tes3.findGMST("fCrimeGoldDiscountMult").value = P.spec8 and math.max(0.5 - mp.mercantile.base*0.003, 0.2) or 0.5
tes3.findGMST("iCrimeThreshold").value = P.sec4 and 3000 or 1000

tes3.findGMST("fDispPersonalityBase").value = P.per1 and 50 or 100
tes3.findGMST("fDispPersonalityMult").value = P.per1 and 0.5 or 0.3
tes3.findGMST("fDispFactionMod").value = P.per2 and 5 or 2
tes3.findGMST("fDispRaceMod").value = P.per5 and 30 or 5
tes3.findGMST("fDispCrimeMod").value = P.per6 and 0 or 0.02

tes3.findGMST("fPersonalityMod").value = P.per4 and 5 or 10
tes3.findGMST("fLuckMod").value = P.per4 and 10 or 20
tes3.findGMST("fReputationMod").value = P.per8 and 1 or 0.5
tes3.findGMST("fLevelMod").value = P.spec9 and 5 or 2

tes3.findGMST("fSleepRandMod").value = P.luc6 and 0.1 or 0.5
tes3.findGMST("fDiseaseXferChance").value = math.max((P.luc7 and 10 or 20) - mp.luck.base/20, 1)
tes3.findGlobal("WerewolfClawMult").value = 5
end
L.HPUpdate = function()
	local Lord = mp.birthsign.id == "Trollkin" and ((D.chimstar == 2 and 30) or (D.chimstar == 1 and 20) or 10) or 0
	local Steed = mp.birthsign.id == "Charioteer" and ((D.chimstar == 2 and 100) or (D.chimstar == 1 and 100) or 50) or 0
	mp.shield = (P.end14 and 5 or 0) + (P.med11 and 5 or 0) + (P.hev16 and 5 or 0) + (P.bloc21 and 5 or 0) + (D.LEG.e3 or 0) + Lord + tes3.getEffectMagnitude{reference = p, effect = 3}
	
	local PerkHP = 0	for i, perk in ipairs(L.PERST[80]) do if P[perk] then PerkHP = PerkHP + 10 end end
	tes3.setStatistic{reference = p, name = "health", base = math.max(mp.endurance.base/2 + mp.strength.base/4 + mp.willpower.base/4 + tes3.getEffectMagnitude{reference = p, effect = 80}
	+ PerkHP - (G.TR.tr2 and 50 or 0) + (D.LEG.e80 or 0) + (L.RHP[p.object.race.id] or 0), 10)}
	if mp.health.normalized > 1 then mp.health.current = mp.health.base end
	L.MPUpdate()	L.STUpdate()
	
	local PerkEnc = 0	for i, perk in ipairs(L.PERST[8]) do if P[perk] then PerkEnc = PerkEnc + 40 end end
	tes3.setStatistic{reference = p, name = "encumbrance", base = mp.strength.base*2 + mp.endurance.base + (L.RENC[p.object.race.id] or 0) + PerkEnc + Steed - (G.TR.tr9 and 100 or 0)}
	mp.encumbrance.currentRaw = p.object.inventory:calculateWeight() + tes3.getEffectMagnitude{reference = p, effect = 7} - tes3.getEffectMagnitude{reference = p, effect = 8} - (G.TR.tr9 and 50 or 0) - (D.LEG.e8 or 0)
end
L.MPUpdate = function()	local PerkMP = 0	for i, perk in ipairs(L.PERST[84]) do if P[perk] then PerkMP = PerkMP + 20 end end
	tes3.setStatistic{reference = p, name = "magicka", base = mp.intelligence.base + tes3.getEffectMagnitude{reference = p, effect = 84}*10 + PerkMP + (D.LEG.e84 or 0) + (G.TR.tr4 and 50 or 0)}
	if mp.magicka.normalized > 1 then mp.magicka.current = mp.magicka.base end
end
L.STUpdate = function() local PerkST = 0	for i, perk in ipairs(L.PERST[82]) do if P[perk] then PerkST = PerkST + 30 end end
	tes3.setStatistic{reference = p, name = "fatigue", base = mp.endurance.base + mp.strength.base + mp.willpower.base + tes3.getEffectMagnitude{reference = p, effect = 82}
	+ PerkST + (L.RST[p.object.race.id] or 0) + (D.LEG.e82 or 0) - (G.TR.tr4 and 100 or 0)}
	--if mp.fatigue.normalized > 1 then mp.fatigue.current = mp.fatigue.base end
end

L.LegSelect = function()	local s = tes3.getObject("4nm_legend") or tes3spell.create("4nm_legend")	s.castType = 1		s.name = eng and "Legendary" or "Легендарность"	
local LEGT = {
--{d = eng and "Run speed" or "Скорость бега", c = 10, max = 20, lvl = 1, nolim = true, pic = "icons/k/attribute_speed.dds"},
{d = eng and "Health" or "Здоровье", c = 4, max = 50, lvl = 0.5, nolim = true, id = 80},
{d = eng and "Mana" or "Мана", c = 2, max = 200, lvl = 0.2, nolim = true, id = 84},
{d = eng and "Stamina" or "Стамина", c = 1, max = 200, lvl = 0.2, nolim = true, id = 82},
{d = eng and "Armor" or "Броня", c = 5, max = 30, lvl = 1, nolim = true, id = 3},
{d = eng and "Lightness" or "Легкость", c = 1, max = 100, lvl = 0.3, nolim = true, id = 8},
{d = eng and "Health regen" or "Регенерация здоровья", c = 100, max = 1, lvl = 30, id = 75},
{d = eng and "Stamina regen" or "Регенерация стамины", c = 10, max = 20, lvl = 2, id = 77},
{d = eng and "Mana regen" or "Регенерация маны", c = 100, max = 3, lvl = 10, id = 76},
{d = eng and "Charge regen" or "Регенерация зарядов", c = 100, max = 3, lvl = 10, id = 501},
{d = eng and "Attack bonus" or "Бонус атаки", c = 5, max = 50, lvl = 0.5, id = 117},
{d = eng and "Dodge bonus" or "Бонус уклонения", c = 5, max = 50, lvl = 0.5, id = 42},
{d = eng and "Jump" or "Прыжки", c = 20, max = 5, lvl = 5, id = 9},
{d = eng and "Dash" or "Дэш", c = 10, max = 10, lvl = 3, id = 600},
{d = eng and "Kinetic shield" or "Кинетический щит", c = 10, max = 5, lvl = 5, id = 508},
{d = eng and "Reflect magic" or "Отражение магии", c = 10, max = 10, lvl = 3, id = 507},
{d = eng and "Absorb spells" or "Поглощение заклинаний", c = 30, max = 10, lvl = 3, id = 67},
{d = eng and "Resist fire" or "Сопротивление огню", c = 5, max = 30, lvl = 1, id = 90},
{d = eng and "Resist frost" or "Сопротивление морозу", c = 5, max = 30, lvl = 1, id = 91},
{d = eng and "Resist lightning" or "Сопротивление молнии", c = 5, max = 30, lvl = 1, id = 92},
{d = eng and "Resist magic" or "Сопротивление магии", c = 5, max = 30, lvl = 1, id = 93},
{d = eng and "Resist poison" or "Сопротивление яду", c = 5, max = 30, lvl = 1, id = 97},
{d = eng and "Resist paralysis" or "Сопротивление параличу", c = 5, max = 30, lvl = 1, id = 99}}


local LEGQ = {C3_DestroyDagoth = {50,100}, TR_SothaSil = {100,50}, BM_WildHunt = {100,50}, HH_WinCamonna = {100,30}, HR_Archmaster = {100,30}, HT_Archmagister = {100,30},
TG_KillHardHeart = {100,30}, FG_KillHardHeart = {100,30}, MG_Guildmaster = {100,30}, IL_Grandmaster = {100,30}, TT_Assarnibibi = {100,30}, MT_Grandmaster = {100,30}, IC29_Crusher = {50,30}, CO_Estate = {50,30}}
local LVL = p.object.level		local LP = LVL*5 + p.object.factionIndex		for id, t in pairs(LEGQ) do if tes3.getJournalIndex{id = id} >= t[1] then LP = LP + t[2] end end	

local M = {}	M.M = tes3ui.createMenu{id = 402, fixedFrame = true}	M.M.minHeight = 1200	M.M.minWidth = 800		local bl
M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.A.flowDirection = "top_to_bottom" 
M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
L.LegCalc = function() local bonus = 0		for i, t in ipairs(LEGT) do bonus = bonus + M[i].widget.current * t.c end	M.F.widget.current = bonus	end

for i, t in ipairs(LEGT) do bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl.borderAllSides = 1
	bl:createImage{path = t.id and "icons\\" .. tes3.getMagicEffect(t.id).bigIcon or t.pic}
	M[i] = bl:createSlider{max = math.min(math.floor(LVL/t.lvl), t.max), step = 1, jump = 1, current = D.LEG["e"..t.id] or 0}	M[i].width = 400	M[i].borderRight = 10	M[i].borderLeft = 10	M[i].borderTop = 5
	M[i]:register("PartScrollBar_changed", function() M[-i].text = M[i].widget.current .. "  " .. t.d	L.LegCalc() end)
	M[-i] = bl:createLabel{text = M[i].widget.current .. "  " .. t.d}
end
M.F = M.B:createFillBar{current = 0, max = math.min(LP,400) + (G.TR.tr2 and 200 or 0) + (G.TR.tr6 and 200 or 0) + (G.TR.tr8 and 200 or 0)}
M.F.width = 300		M.F.height = 24		M.F.widget.fillColor = {1,0,1}		L.LegCalc()

if not T.LEG.timeLeft then	M.legend = M.B:createButton{text = eng and "Accept bonuses" or "Закрепить бонусы"}	M.legend:register("mouseClick", function()
	if M.F.widget.max >= M.F.widget.current then		local num = 0	local EFtab = {}
		for i, t in ipairs(LEGT) do if i > 5 and M[i].widget.current > 0 then num = num + 1		EFtab[num] = {id = t.id, mag = M[i].widget.current} end end
		if num < 9 then	tes3.removeSpell{reference = p, spell = s}		for i, t in ipairs(LEGT) do D.LEG["e"..t.id] = M[i].widget.current end
			if num > 0 then T.LEG = timer.start{duration = 0.3, callback = function()
				for i, ef in ipairs(s.effects) do if EFtab[i] then ef.id = EFtab[i].id	ef.min = EFtab[i].mag	ef.max = EFtab[i].mag else ef.id = -1 end end
				tes3.addSpell{reference = p, spell = s}		L.HPUpdate()
			end} end
			tes3.playSound{sound = "skillraise"}	M.M:destroy()	tes3ui.leaveMenuMode()	L.HPUpdate()
		else tes3.messageBox(eng and "You have selected too many bonuses of different types" or "Вы набрали слишком много бонусов разных типов") end
	else tes3.messageBox(eng and "You have selected too many bonuses" or "Вы набрали слишком много бонусов") end
end) end
M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)
tes3ui.enterMenuMode(402)
end

L.PerkReset = function() local day = wc.daysPassed.value - (D.resetday or 0)	if day > 6 then D.resetday = wc.daysPassed.value
	for id, _ in pairs(L.PA) do tes3.removeSpell{reference = p, spell = "4p_"..id, updateGUI = false} end		for id, _ in pairs(L.AA) do tes3.removeSpell{reference = p, spell = id, updateGUI = false} end
	tes3.updateMagicGUI{reference = p, updateEnchantments = false}
	QS = nil	D.perks = {}	 P = D.perks	D.QSP = {}		DM.cp = nil		L.GetArmT()		L.GetWstat()	L.HPUpdate()	L.SetGlobal()
else tes3.messageBox(eng and "Too early - only %d days have passed since the last reset" or "Слишком рано - с последнего сброса прошло только %d дней", day) end end
L.PerkSpells = function() for id, t in pairs(L.PA) do if P[t[3]] then tes3.addSpell{reference = p, spell = "4p_"..id, updateGUI = false} end end
for id, t in pairs(L.AA) do if P[t.p] then tes3.addSpell{reference = p, spell = id, updateGUI = false} end end	tes3.updateMagicGUI{reference = p, updateEnchantments = false} end

L.EUPD = function(r, id) timer.delayOneFrame(function() local mag = tes3.getEffectMagnitude{reference = r, effect = id} 	r.data["e"..id] = mag > 0 and mag or nil
--tes3.messageBox("%s  id = %s  mag = %s", r, id, r.data["e"..id])
end) end
L.RandomFile = function(d) if not L.FIL[d] then L.FIL[d] = {}	for file in lfs.dir(d) do if file:endswith("wav") then table.insert(L.FIL[d], file) end end	end		return table.choice(L.FIL[d]) end
L.KEY = function(k) if k < 8 then return ic:isMouseButtonDown(k) else return ic:isKeyDown(k) end end
L.GetRad = function(m) return (50 + m.willpower.current/2 + m:getSkillValue(11))/((m ~= mp or P.alt13) and 20 or 40) end
L.Rcol = function(x) local c = {{math.random(x,255),x,255}, {math.random(x,255),255,x}, {x,math.random(x,255),255}, {255,math.random(x,255),x}, {x,255,math.random(x,255)}, {255,x,math.random(x,255)}}	return c[math.random(6)] end
L.GetPCmax = function() return (mp.willpower.base + mp.enchant.base) * (P.enc6 and 2.5 or 2) * (1 - math.min(M.ENL.normalized,1)*(P.enc15 and 0.6 or 0.8)) * (G.TR.tr6 and 0.25 or 1) end
L.CrimeAt = function(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}		m:startCombat(mp)	m.actionData.aiBehaviorState = 3 end end
L.durbonus = function(dur, koef)		if dur < 1 or not P.int9 then return 1 else return 1 + koef/100 * dur^0.5 end end
L.NoBorder = function(el, x) el.contentPath = "meshes\\menu_thin_border_0.nif"	if not x then el:findChild("PartFillbar_colorbar_ptr").borderAllSides = 0 end end
L.BarText = function(el) el = el:findChild("PartFillbar_text_ptr") 	el.absolutePosAlignY = 0.6		el.color = {1,1,1} end
L.GetPDir = function()	local vec
	if mp.isMovingForward then vec = p.forwardDirection elseif mp.isMovingBack then vec = p.forwardDirection * -1 else vec = V.nul end
	if mp.isMovingRight then vec = vec + p.rightDirection elseif mp.isMovingLeft then vec = vec + p.rightDirection * -1 end
	return vec:normalized()
	
--	if mp.isMovingForward then if mp.isMovingLeft then ang = -45 elseif mp.isMovingRight then ang = 45 else ang = 0 end
--	elseif mp.isMovingBack then if mp.isMovingLeft then ang = -135 elseif mp.isMovingRight then ang = 135 else ang = 180 end
--	elseif mp.isMovingLeft then ang = -90 elseif mp.isMovingRight then ang = 90 end
--	if ang then vec = tes3.getPlayerEyeVector()		Matr:toRotationZ(math.rad(ang))		vec = Matr * vec		vec.z = 0	vec = vec:normalized()		vec.z = 1	vec = vec:normalized() end
end

L.NewBB = function(id, ic, dur, sn, cur)		local B = M.BB[id]
	if not B then M.BB[id] = {}		B = M.BB[id]
		B.bl = M.BBM:createBlock{}	B.bl.autoHeight = true	B.bl.autoWidth = true	B.bl.flowDirection = "top_to_bottom"	if cf.BBrig and not cf.BBhor then M.BBM:reorderChildren(0, B.bl, 1) end
		B.ic = B.bl:createImage{path = "icons\\" .. ic}		B.ic.borderAllSides = 3
	end	
	B[sn] = B.bl:createFillBar{current = cur or dur, max = dur}	local bar = B[sn]	bar.width = 38	bar.height = 5	bar.borderBottom = 1	local bw = bar.widget	bw.showText = false		L.NoBorder(bar)
	local n = math.remap(dur, cf.BBred, cf.BBgr, 0, 1)		bw.fillColor = {2-n*2, n*2, n-1}
end

L.NewGrip = function(o) local New	local id = o.id		if id:sub(1,1) == "*" and tes3.getObject(id:sub(2)) then New = tes3.getObject(id:sub(2)) else
	if string.len(id) < 31 then
		New = tes3.createObject{objectType = tes3.objectType.weapon, id = "*" .. id, type = L.AltW[o.type]}		--'id' parameter must be less than 32 character long.
		New.name = o.name	New.mesh = o.mesh	New.icon = o.icon	New.enchantment = o.enchantment		New.weight = o.weight		New.value = o.value		New.maxCondition = o.maxCondition
		New.flags = o.flags		New.ignoresNormalWeaponResistance = o.ignoresNormalWeaponResistance		New.isSilver = o.isSilver		New.reach = o.reach		New.enchantCapacity = o.enchantCapacity
		New.speed = o.speed		New.chopMin = o.chopMin		New.chopMax = o.chopMax		New.slashMin = o.slashMin	New.slashMax = o.slashMax	New.thrustMin = o.thrustMin		New.thrustMax = o.thrustMax
	end
end return New end
L.GetSGVec = function(a,b)
	Matr:toRotationZ(math.random(a,b)/200*G.ShotGunDiv)	local vec = crot * Matr
	Matr:toRotationX(math.random(-30,30)/200*G.ShotGunDiv)	vec = vec * Matr	return vec:transpose().y
end
L.GetArcVec = function(a,b)
	Matr:toRotationZ(math.random(-a,a)/200*G.ArcDiv)	local vec = crot * Matr
	Matr:toRotationX(math.random(-b,b)/200*G.ArcDiv)	vec = vec * Matr	return vec:transpose().y
end
L.Hitp = function(x) local pos = tes3.getPlayerEyePosition()	local vec = tes3.getPlayerEyeVector()	local hit = tes3.rayTest{position = pos, direction = vec, maxDistance = 4800, ignore = {p}}
return hit and hit.intersection - vec * (x or 60) or pos + vec*4800 end
L.Hitpr = function(pos,vec,x) local hit = tes3.rayTest{position = pos, direction = vec, maxDistance = 4800, ignore = {p}}
return hit and hit.intersection - vec * (x or 60) or pos + vec*4800 end

L.TPComp = function() if D.NoTPComp then return false else		local num = 0		local cost = 0		G.TPList = {}
	for m in tes3.iterate(mp.friendlyActors) do if m ~= mp then num = num + 1
		cost = cost + (L.Summon[m.object.baseObject.id] and 10 or 20)	G.TPList[m.reference] = true		--tes3.messageBox("Name = %s  num = %s  cost = %d", m.object.name, num, cost)
	end end
	if not P.mys22 then cost = cost * 3 end		
	if num > 0 then if mp.magicka.current >= cost then Mod(cost)	tes3.messageBox("Companions = %s  manacost = %d", num, cost) return true
		else tes3.messageBox("Not enough mana! Companions = %s  manacost = %d", num, cost)	return false end
	else return false end
end end
L.TownTP = function(e) --if not e:trigger() then return end		
	if e.effectInstance.target == p and e.effectInstance.resistedPercent < 50 and not wc.flagTeleportingDisabled then -- Телепорт в город (505) 32 максимум, 22 щас
	tes3.messageBox{message = "Where to go?", buttons = {"Nothing", "Balmora", "Ald-ruhn", "Vivec", "Sadrith Mora", "Ebonheart", "Caldera", "Suran", "Gnisis",
	"Pelagiad", "Tel Branora", "Tel Aruhn", "Tel Mora", "Maar Gan", "Molag Mar", "Dagon Fel", "Seyda Neen", "Hla Oad", "Gnaar Mok", "Khuul", "Ald Velothi", "Vos", "Tel Vos"},
	callback = function(e) if e.button ~= 0 then tes3.positionCell{reference = p, teleportCompanions = false, position = L.TPP[e.button], cell = tes3.getCell{x = 0, y = 0}}
		if L.TPComp() then timer.start{duration = 0.1, callback = function() for r, _ in pairs (G.TPList) do tes3.positionCell{reference = r, position = pp, cell = p.cell} end end} end
	end end}
	e.effectInstance.state = tes3.spellState.retired
end end
L.GetOri = function(vec1, vec2) vec1 = vec1:normalized()	vec2 = vec2:normalized()	local axis = vec1:cross(vec2)	local norm = axis:length()
	if norm < 1e-5 then return ID33:toEulerXYZ() end
	local angle = math.asin(norm)	if vec1:dot(vec2) < 0 then angle = math.pi - angle end		axis:normalize()
	local m = ID33:copy()	m:toRotation(-angle, axis.x, axis.y, axis.z)	return m:toEulerXYZ()	--return m
end
L.Sector = function(t)	local p1, d, d1, dd, ref	local dd1 = t.lim or 2000		local pos = t.pos or tes3.getPlayerEyePosition()		local v = t.v or tes3.getPlayerEyeVector()
	for r, tab in pairs(N) do p1 = r.position:copy()	p1.z = p1.z + tab.m.height/2		d = pos:distance(p1)
		if d < t.d then dd = p1:distance(pos + v*d)
			if dd < dd1 and tes3.testLineOfSight{reference1 = p, reference2 = r} and tes3.getCurrentAIPackageId(tab.m) ~= 3 then ref = r	dd1 = dd	d1 = d end
		end
	end		--if ref then tes3.messageBox("%s  Dist = %d   Dif = %d", ref, d1, dd1) end
	return ref, d1
end
L.SectorDod = function() for r, t in pairs(R) do local ang = mp:getViewToActor(t.m)		if math.abs(ang) < 15 and math.abs(t.m:getViewToActor(mp)) < 45 then
	local ch = t.m.agility.current + t.m.sanctuary		if ch + (N[r].dod and 30 or 0) > math.random(100) then
		local spd = math.clamp((100 + ch + t.m.speed.current*2) * (1 - math.min(t.m.encumbrance.normalized,1)*0.8) * (0.5 + t.m.fatigue.normalized/2), 150, 400)
		--local vec = (pp - r.position):normalized()	Matr:toRotationZ(math.rad((ang > 0 and -45 or 45) * (t.m.isMovingForward and 1 or 2)))		vec = Matr * vec + tes3vector3.new(0,0,0.5)
		local vec = r.rightDirection * (ang > 0 and -1 or 1) + V.up2	if t.m.isMovingForward then vec = vec + r.forwardDirection end
		t.m:doJump{velocity = vec * spd, applyFatigueCost = false}
		--tes3.messageBox("Dodge %s   %d%%   spd = %d   fov = %s   Ang = %d", r, ch, spd, t.m.isMovingForward, ang)
	end
end end end

L.DodM = function(r,m) if not L.ASN[m.actionData.animationAttackState] and not m.isFalling then
	local ch = m.agility.current + m.sanctuary		if ch + (N[r].dod and 30 or 0) > math.random(100) then
	local spd = math.min((200 + ch + m.speed.current*2) * (1 - math.min(m.encumbrance.normalized,1)*0.8) * (0.5 + m.fatigue.normalized/2), 500)			--local rot = r.sceneNode.rotation:transpose()
	DOM[m] = {v = (r.rightDirection * table.choice{1,-1} + r.forwardDirection):normalized() * spd, fr = 0.4}
	--tes3.messageBox("Dodge %s   %d%%   spd = %d   jump = %s", r, ch, spd)
end end end

L.Dod2 = function(r,m) if not L.ASN[m.actionData.animationAttackState] and not m.isFalling then
	local ch = m.agility.current + m.sanctuary		if ch + (N[r].dod and 30 or 0) > math.random(100) then
	local spd = math.min((200 + ch + m.speed.current*2) * (1 - math.min(m.encumbrance.normalized,1)*0.8) * (0.5 + m.fatigue.normalized/2), 500)	
	DOM[m] = {v = r.forwardDirection * spd, fr = 0.4}
	--tes3.messageBox("Dodge %s   %d%%   spd = %d", r, ch, spd)
end end end

L.CF.atr = function(m,r) local d = r.data.spawn	if d ~= 0 and m.health.normalized < d/10 - 0.2 then	local id = r.baseObject.id
	B.elemaura.effects[1].id = L.atrbot[id][1]	B.elemaura.effects[1].min = d*2	B.elemaura.effects[1].max = d*3		B.elemaura.effects[2].id = L.atrbot[id][2]	B.elemaura.effects[2].min = d*2	B.elemaura.effects[2].max = d*3
	B.elemaura.effects[3].id = L.atrbot[id][3]	B.elemaura.effects[3].min = d	B.elemaura.effects[3].max = d*2		tes3.applyMagicSource{reference = r, source = B.elemaura}	r.data.spawn = 0
end end
L.CF.dremoralord = function(m,r) if r.data.spawn + 5 > math.random(100) then
	tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{105,105,105,140}, duration = 60}}}
end end
L.CF.atrlord = function(m,r) local d = r.data.spawn + 10		local id = r.baseObject.id
	if d > 10 and m.health.normalized < d/20 then	
		B.elemaura.effects[1].id = L.atrbot[id][1]	B.elemaura.effects[1].min = d*2	B.elemaura.effects[1].max = d*3		B.elemaura.effects[2].id = L.atrbot[id][2]	B.elemaura.effects[2].min = d*2	B.elemaura.effects[2].max = d*3
		B.elemaura.effects[3].id = L.atrbot[id][3]	B.elemaura.effects[3].min = d	B.elemaura.effects[3].max = d*2		tes3.applyMagicSource{reference = r, source = B.elemaura}	r.data.spawn = 0
	end
	if d/2 > math.random(100) then tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = L.atrbot[id][4], duration = 60}}} end
end
L.CF.auril = function(m,r) local d = r.data.spawn	if d ~= 0 and m.health.normalized < 0.5 then
	if d > 8 then B.goldaura.effects[1].id = 4 elseif d < 3 then B.goldaura.effects[1].id = 6 elseif d == 3 or d == 4 then B.goldaura.effects[1].id = 5 elseif d == 5 or d == 6 then B.goldaura.effects[1].id = 3 end
	B.goldaura.effects[1].min = math.random(5,10)		B.goldaura.effects[1].max = math.random(10,30)		tes3.applyMagicSource{reference = r, source = B.goldaura}	r.data.spawn = 0
end end
L.CF.lichelder = function(m,r) local ch = math.random(10 - r.data.spawn*0.5)
	if ch == 1 then for ref in tes3.iterate(r.cell.actors) do if ref.object.objectType == tes3.objectType.creature and ref.object.type == 2 and ref.mobile.isDead and r.position:distance(ref.position) < 1000 then
		if 100 - ref.object.level * 5 > math.random(100) then ref.mobile:resurrect{resetState = false}	tes3.playSound{sound = "conjuration hit", reference = ref} end end end
	elseif ch == 2 then for ref in tes3.iterate(r.cell.actors) do if ref.object.objectType == tes3.objectType.creature and ref.object.type == 2 and r.position:distance(ref.position) < 1000 then
		tes3.applyMagicSource{reference = ref, source = "p_restore_health_s"} end end
	elseif ch == 3 then tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{108,108,142,142,109,110}, duration = 60}}} end
end
L.CF.lich = function(m,r) local ch = math.random(10 - r.data.spawn*0.3)
	if ch == 1 then
		tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{106,107,107,142,109,108}, duration = 60}}}
		--tes3.createReference{object = L.UndMinion[math.random(4)], position = (r.position + r.orientation*300), cell = r.cell}		tes3.playSound{sound = "conjuration hit", reference = r}
	elseif ch == 2 then tes3.applyMagicSource{reference = r, source = "p_restore_health_c"}
end end
L.CF.lichuni = function(m,r) if math.random(5) == 1 then
	tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = table.choice{107,107,142,142,108,108,110}, duration = 60}}}
end end
L.CF.ashascend = function(m,r) if r.position:distance(pp) < 1000 and not mwscript.getSpellEffects{reference = p, spell = "corprus immunity"} then local ch = math.random(6)
	if ch < 5 then mwscript.addSpell{reference = p, spell = L.Blight[ch]}
	tes3.messageBox(eng and "The blight aura emitted by this creature has hit you!" or "Вас поразила моровая аура, источаемая этим существом!") end
end end
L.CF.ashvamp = function(m,r)	local ch = math.random(10)	local SpO
	if ch == 1 then SpO = table.choice{"ash_zombie", "ash_zombie_warrior", "corprus_lame", "corprus_stalker", "ash_ghoul", "ash_revenant"}
	elseif ch < 4 then SpO = "ash_slave" end
	if SpO then local ref = mwscript.placeAtPC{object = SpO, distance = 500, direction = math.random(0,3)}	local mob = ref.mobile	mob.fight = 100		mob:startCombat(mp)		
	tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = ref.position}	tes3.playSound{sound = "conjuration hit", reference = ref} end
end
L.CF.urdagot = function(m,r)	local ch = math.random(10)	local SpO
	if r.position:distance(pp) > 2000 then
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = p.forwardDirection, maxDistance = 500, ignore={p}}
		r.position = hit and hit.intersection or tes3.getPlayerEyePosition() + p.forwardDirection * 500
		tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = r.position}	tes3.playSound{sound = "conjuration hit", reference = r}
	end
	if ch == 1 and tes3.getJournalIndex{id = "C3_DestroyDagoth"} < 20 then SpO = table.choice{"ash_ghoul", "ash_ghoul", "ash_ghoul_warrior", "ash_ghoul_warrior", "ash_ghoul_high", "ascended_sleeper"}
	elseif ch == 2 then SpO = table.choice{"ash_slave", "ash_zombie", "ash_zombie_warrior", "corprus_lame", "corprus_stalker", "ash_ghoul", "ash_revenant"}
	elseif ch == 3 then SpO = table.choice{"ash_slave", "ash_zombie", "ash_zombie_warrior"}
	elseif ch == 4 then SpO = "ash_slave" end
	if SpO then local ref = mwscript.placeAtPC{object = SpO, distance = 500, direction = math.random(0,3)}	local mob = ref.mobile	mob.fight = 100		mob:startCombat(mp)		
	tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = ref.position}	tes3.playSound{sound = "conjuration hit", reference = ref} end
end

L.CFF = {["atronach_flame"] = L.CF.atr, ["atronach_flame_summon"] = L.CF.atr, ["atronach_frost"] = L.CF.atr, ["atronach_frost_summon"] = L.CF.atr, ["atronach_storm"] = L.CF.atr, ["atronach_storm_summon"] = L.CF.atr,
["atronach_flame_lord"] = L.CF.atrlord, ["atronach_frost_lord"] = L.CF.atrlord, ["atronach_storm_lord"] = L.CF.atrlord,	["dremora_lord"] = L.CF.dremoralord,
["golden saint"] = L.CF.auril, ["golden saint_summon"] = L.CF.auril, ["lich"] = L.CF.lich, ["lich_elder"] = L.CF.lichelder, ["ascended_sleeper"] = L.CF.ashascend,
["dagoth araynys"] = L.CF.ashvamp, ["dagoth endus"] = L.CF.ashvamp, ["dagoth gilvoth"] = L.CF.ashvamp, ["dagoth odros"] = L.CF.ashvamp, ["dagoth tureynul"] = L.CF.ashvamp, ["dagoth uthol"] = L.CF.ashvamp, ["dagoth vemyn"] = L.CF.ashvamp,
["lich_barilzar"] = L.CF.lichuni, ["lich_relvel"] = L.CF.lichuni, ["lich_profane_unique"] = L.CF.lichuni, ["dagoth_ur_2"] = L.CF.urdagot}


L.GetArStat = function()
local w = mp.readiedWeapon	local wd = w and w.variables	local w = w and w.object		local wt = W.wt		local WS = mp:getSkillValue(WT[wt].s)		--(W.wt < -1 and W.wt) or (w and w.type) or -1	
local agi = mp.agility.current	local enc = mp.encumbrance.normalized	local lig = math.max(-mp.encumbrance.currentRaw,0)/2000		local stam = math.min(mp.fatigue.normalized,1)
local sp = mp.currentSpell or tes3.getObject("flame")	local sc = sp.magickaCost and sp:getLeastProficientSchool(mp) or sp.effects[1].object.school	local MS = mp:getSkillValue(SP[sc].s)	local eid = sp.effects[1].id
local run = mp.alwaysRun	local strafe = mp.isMovingLeft or mp.isMovingRight	local forw = mp.isMovingForward		local back = mp.isMovingBack		if not (strafe or forw or back) then forw = true end

G.spdk0 = (100 + mp.speed.current) * (run and (3 + mp:getSkillValue(8)/100) or 1)
G.spdk1 = math.min(D.AR.ms + lig, 1)
G.spdk2 = (1 - enc/2) * (P.atl3 and 1 or 1 - enc/3)
G.spdk3 = run and 1 - (1 - stam) * (P.atl2 and 0.25 or 0.5) or 1
G.spdk4 = (not P.acr3 and mp.isFalling and 0.75 or 1) * ((forw and 1) or (back and 0.8) or 0.75) * (back and 0.625 or 1)
* (run and (P.spd0 and forw and not strafe and 1.25 or 1) * (G.TR.tr3 and 1 or 0.8) * ((forw or P.spd20) and 1 or 0.8)
* ((ad.animationAttackState == 2 and (P.spd10 and 0.8 or 2/3)) or (ad.animationAttackState == 10 and (P.spd19 and 0.8 or 2/3)) or 1) or 1)

M.ST11.text = ("%s/%s/%s/%s"):format(D.AR.l, D.AR.m, D.AR.h, D.AR.u)
M.ST12.text = ("%d"):format(G.spdk0 * G.spdk1 * G.spdk2 * G.spdk3 * G.spdk4)


local Kstr = (WT[wt].h1 and 100 or 140) + mp.strength.current * ((P.str1 and 0.2 or 0.1) + (WT[wt].h1 and 0 or 0.1))
local Kskill = WS * ((P[WT[wt].p1] and 0.2 or 0.1) + (P[wt < 9 and (WT[wt].h1 and "agi5" or "str2") or "agi30"] and 0.1 or 0.05))
local Kbonus = mp.attackBonus/5 + (P.str15 and 20 * math.max(1 - mp.health.normalized, 0) or 0)
local Kstam = math.min(math.lerp((P.end1 and 0.4 or 0.3) + (P[WT[wt].p2] and 0.1 or 0), 1, stam*1.1), 1)
local Cond = 1	if wd then Cond = wd.condition/w.maxCondition	Cond = Cond > 1 and Cond or math.lerp(P.arm2 and 0.3 or 0.2, 1, Cond)
Cond = Cond * (w.weight == 0 and 1 + mp:getSkillValue(13)*(P.con8 and 0.003 or 0.002) or 1) end
local Range
if wt > 8 then local prob = mp.readiedAmmo	prob = prob and prob.object		local prw = prob and prob.weight or 0		local vel
	if wt == 11 then vel = 1000 + (mp.strength.current*(P.str12 and 1.5 or 1)/(prw+5))^0.5 * 500 * Kstam	
	else vel = 1000 + (w.chopMax * Cond / math.clamp(prw, 0.2, 0.5)+0.1)^0.5 * 500 end
	Range = (100 + Kskill + Kbonus) * 4*vel/(vel/100+100)/100
end

local spd = w and w.speed or 1
if w and wt < 11 then	local max = math.max((2 - spd)/3, 0)		local str = mp.strength.current
	spd = spd + (wt < 9 and not WT[wt].h1 and max/2 or 0) + max * (P[wt < 9 and "str16" or "str17"] and 0.5 or 0.25) * 1.5*str/(str + 200)
end

spd = spd * (0.9
+ mp.speed.current/(P.spd1 and 1000 or 2000)
+ WS/(P[WT[wt].p4] and 1000 or 2000)
- (1 - stam) * (P.atl11 and 0.1 or 0.2)
- enc * (P.atl12 and 0.1 or 0.2)
- math.max(D.AR.as - math.max(-mp.encumbrance.currentRaw,0)/2000, 0) )

M.ST21.text = ("%d%%"):format(wt < 9 and (Kstr + Kskill + Kbonus) * Kstam * Cond or Range)
M.ST22.text = ("%.2f / %d"):format(spd, (P[WT[wt].pc] and 4 or 3) + math.floor(WS/50) + (P.spd14 and W.DWM and 1 or 0))


local Cfocus = mp.spellReadied and P.wil5 and 1 + mp.magicka.current/(100 + mp.magicka.current/10)/100 or 1
local Cstam = math.min(math.lerp((P.wil2 and 0.4 or 0.3) + (P[SP[sp.objectType == tes3.objectType.enchantment and "enc5" or SP[sc].p3]] and 0.1 or 0), 1, stam*1.1), 1)
local Cbonus = MS/(P[MEP[eid] and MEP[eid].p0 or SP[sc].p1] and 5 or 10) + (P[MEP[eid] and MEP[eid].p or "mys0"] and mp:getSkillValue(MEP[eid] and MEP[eid].s or 14)/10 or 0)
if sp.objectType == tes3.objectType.enchantment then Cbonus = Cbonus/2 + mp:getSkillValue(9)*(P.enc1 and 0.15 or 0.1) end
if ME[eid] == "shield" and P.una7 then Cbonus = Cbonus + D.AR.u * mp:getSkillValue(17)/100 end
Cbonus = Cbonus + mp.willpower.current/(P.wil1 and 5 or 10)

M.ST31.text = ("%d%%"):format((100 + Cbonus) * Cfocus * Cstam)
M.ST32.text = ("%d%%"):format(sp.alwaysSucceeds and 100 or 100 * math.max(1 - mp.intelligence.current/(P.int1 and 1000 or 2000)
- MS/(P[SP[sc].p4] and 1000 or 2000) - (P.mys10 and 0.05 or 0) + (D.AR.mc > 0 and math.max(D.AR.mc - lig, 0) or D.AR.mc), 0.5))
M.ST33.text = math.ceil( (P[SP[sc].p2] and MS/5 or 0) + (P.int8 and mp.spellReadied and (mp.intelligence.current + MS)/10 or 0) + (P.int6 and mp.intelligence.current/10 or 0) + (P.luc13 and mp.luck.current/10 or 0)
- (P.wil10 and 0 or M.MCB.normalized*20) + (D.AR.cc > 0 and D.AR.cc or math.min(D.AR.cc + lig*2, 0)) - enc * (P.end17 and 10 or 20) )

--(2 + (mp.willpower.current + agi)/(P.wil15 and 100 or 200) - enc*(P.end15 and 0.5 or 1) + D.AR.cs) * 10		-- скорость зарядки спеллов

local sanct = mp.sanctuary/5 * (1+(P.una11 and D.AR.u*0.01 or 0))
M.ST41.text = ("%d/%d/%d"):format(math.min(stam * (D.AR.dk > 1 and D.AR.dk or math.min(D.AR.dk + lig*2, 1)) * (agi*(P.agi20 and 0.3 or 0.2) + (P.luc3 and mp.luck.current/10 or 0))
+ sanct + (P.acr6 and mp.isJumping and mp:getSkillValue(20)/5 or 0), 100),
(agi/(1+agi/400)/(P.agi2 and 8 or 16) + (P.lig2 and D.AR.l * mp:getSkillValue(21)/100 or 0) + (P.agi23 and W.DWM and 10 or 0) + sanct) * (P.spd2 and 2 or 1),
(P.agi4 and 40 or 50) * (1 + enc*(P.agi14 and 0.5 or 1) + (D.AR.dc < 0 and D.AR.dc or math.max(D.AR.dc - lig*2,0))))

M.ST42.text = ("%d/%d/%d"):format(10 + 10 * enc + (w and w.weight or 0) - (P[WT[wt].p3] and WS/20 or 0) - (P.end6 and math.min(mp.endurance.current/20, 5) or 0),
tes3.findGMST("fFatigueJumpBase").value + tes3.findGMST("fFatigueJumpMult").value * enc, 10 + 30 * enc)
end

L.GetWstat = function() local rw = mp.readiedWeapon		W.v = rw and rw.variables		local w = rw and rw.object		local wt = w and w.type or -1		local wid = w and w.id		W.wt = wt		W.w = w		
	local en = w and w.enchantment			W.en = en and en.castType == 1 and wt < 11 and en or nil
	if W.en then	W.BAR.visible = true	W.bar.max = W.en.maxCharge	W.f = nil
		for i, eff in ipairs(W.en.effects) do if wt < 9 then if (eff.rangeType == 2 or ME[eff.id] == "shotgun" or ME[eff.id] == "ray") then W.f = 1 break end elseif eff.rangeType == 1 then W.f = 1 break end end
		if not W.f and wt > 8 then W.f = 2 end
	else W.f = nil	W.BAR.visible = false end
	
	if w then	
		if wid:sub(1,1) == "*" then local Old = tes3.getObject(wid:sub(2))	if Old then
			if wt == 1 then	if Old.type == 6 then wt = -2	W[wid] = -2 end		elseif wt == 3 then	if Old.type == 5 then wt = -3	W[wid] = -3 end end		W.wt = wt
		end end
		
		W.ra = wt < 9 and w.reach or 10
		W.wgt = w.weight
		W.cost = (W.wgt == 0 and w.enchantCapacity/100 or W.wgt) + 10
		W.cot = w.isOneHanded and (W.DWM and (w == W.WL and W.v == W.DL and 3 or 1) or 1) or 2
		
		if cf.m8 then tes3.messageBox("%s  Reach = %.2f   Stam = %d  %s", w.name, W.ra, W.cost, W.f and (W.f == 2 and "Explode arrow!" or "Enchant strike!") or "") end
	else W.ra = 0.5		W.wgt = 0	W.cost = 10		W.cot = 0		if cf.m8 then tes3.messageBox("No weapon   Stam = %d", W.cost) end	end
	W.cost = W.cost - (P.spd13 and 5 or 0) - (P[WT[wt].p8] and 5 or 0)
end

L.GetArmT = function() D.AR = {l=0,m=0,h=0,u=0}	for i, val in pairs(L.ARW) do	local s = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i}
if (i == 6 or i == 7) and not s then s = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i+3} end	s = AT[s and s.object.weightClass or 3].t		D.AR[s] = D.AR[s] + val end
local Sl, Sm, Sh, Su = mp.lightArmor.base, mp.mediumArmor.base, mp.heavyArmor.base, mp.unarmored.base
D.AR.ms = 1 - D.AR.m*0.005*(1 - Sm/(P.med2 and 200 or 400)) - D.AR.h*0.01*(1 - Sh/(P.hev2 and 200 or 400))
D.AR.as = D.AR.m*0.005*(1 - Sm/(P.med3 and 200 or 400)) + D.AR.h*0.01*(1 - Sh/(P.hev3 and 200 or 400))
D.AR.dk = 1 + D.AR.u*0.01*Su/(P.una5 and 100 or 200) - D.AR.l*0.02*(1 - Sl/(P.lig5 and 100 or 200)) - D.AR.m*0.02*(1 - Sm/(P.med5 and 200 or 400)) - D.AR.h*0.04*(1 - Sh/(P.hev5 and 200 or 400))
D.AR.dc = 0 - D.AR.u*0.01*Su/(P.una6 and 100 or 200) + D.AR.l*0.02*(1 - Sl/(P.lig6 and 100 or 200)) + D.AR.m*0.02*(1 - Sm/(P.med6 and 200 or 400)) + D.AR.h*0.04*(1 - Sh/(P.hev6 and 200 or 400))
D.AR.cs = D.AR.u*0.04*Su/(P.una4 and 100 or 200) - D.AR.l*0.02*(1 - Sl/(P.lig4 and 100 or 200)) - D.AR.m*0.03*(1 - Sm/(P.med4 and 100 or 200)) - D.AR.h*0.04*(1 - Sh/(P.hev4 and 100 or 200))
D.AR.cc = (P.una12 and D.AR.u > 19 and 25 or 0) + D.AR.u*Su/(P.una1 and 100 or 500) - D.AR.l*(1 - Sl/(P.lig1 and 100 or 200)) - D.AR.m*(1 - Sm/(P.med1 and 200 or 400)) - D.AR.h*2*(1 - Sh/(P.hev1 and 200 or 400))
D.AR.mc = 0 - (P.una12 and D.AR.u > 19 and 0.05 or 0) - (P.una3 and D.AR.u*Su/50000 or 0) + D.AR.l*0.002*(1 - Sl/(P.lig15 and 100 or 200)) + D.AR.m*0.004*(1 - Sm/(P.med15 and 200 or 400)) + D.AR.h*0.006*(1 - Sh/(P.hev15 and 200 or 400))
L.GetArStat()
end
L.UpdShield = function(sh)
	if T.Shield.timeLeft then T.Shield:reset() else T.Shield = timer.start{duration = 10, callback = function() M.SHbar.visible = false end} end
	M.SHbar.widget.max = sh.object.maxCondition		M.SHbar.widget.current = sh.variables.condition		M.SHbar.visible = true
end
L.M180 = tes3matrix33.new()		L.M180:toRotationX(math.rad(180))
L.MagefAdd = function()		p1 = tes3.player1stPerson.sceneNode
G.arm1 = p1:getObjectByName("Bip01 R Finger2")	G.arm1:attachChild(L.magef:clone())		G.arm1 = G.arm1:getObjectByName("magef")	G.arm1.appCulled = true
G.arm2 = p1:getObjectByName("Bip01 L Finger2")	G.arm2:attachChild(L.magef:clone())		G.arm2 = G.arm2:getObjectByName("magef")	G.arm2.appCulled = true		end
L.Cul = function(x) W.w1.appCulled = x	W.w3.appCulled = x	W.wl1.appCulled = not x		W.wl3.appCulled = not x		W.wr1.appCulled = not x		W.wr3.appCulled = not x	end
L.GetConEn = function(arm, en) local E = arm == 1 and "ER" or "EL"	if en and en.castType == 3 then W[E] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}}
	for i, ef in ipairs(en.effects) do W[E][i].id = ef.id	W[E][i].min = ef.min	W[E][i].max = ef.max	W[E][i].radius = ef.radius	W[E][i].duration = 36000	W[E][i].attribute = ef.attribute	W[E][i].skill = ef.skill end	
else W[E] = nil end end
L.DWNEW = function(o, od, left)	if left then
	W.wl1 = tes3.loadMesh(o.mesh):clone()	W.wl1.translation = W.w1.translation:copy()		W.wl1.translation.z = W.wl1.translation.z*-1	W.wl1.rotation = W.w1.rotation:copy() * L.M180	W.wl3 = W.wl1:clone()
	W.WL = o	W.DL = od	W.DL.tempData.DW = 2	L.GetConEn(2, o.enchantment)	if cf.m then tes3.messageBox("Left weapon remembered: %s", o.name)	end		if W.WR then L.DWMOD(true) end
else W.wr1 = tes3.loadMesh(o.mesh):clone()	W.wr1.translation = W.w1.translation:copy()		W.wr1.rotation = W.w1.rotation:copy()	W.wr3 = W.wr1:clone()
	W.WR = o	W.DR = od	W.DR.tempData.DW = 1	L.GetConEn(1, o.enchantment)	if W.WL then L.DWMOD(true) end
end end
L.ClearEn = function() local si	if D.DWER then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWER}	if si then si.state = 6 end D.DWER = nil end
if D.DWEL then si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.DWEL}	if si then si.state = 6 end D.DWEL = nil end end
L.DWESound = function(e) if W.snd and (e.item == W.WR or e.item == W.WL) then W.snd = nil return false end end
L.DWMOD = function(st) if st then 
	if not W.DWM then if W.WR and W.WL and inv:contains(W.WR, W.DR) and W.DR.condition > 0 and inv:contains(W.WL, W.DL) and W.DL.condition > 0 then
		tes3.loadAnimation{reference = tes3.player1stPerson, file = "dw_merged.nif"}		L.MagefAdd()
		p1 = tes3.player1stPerson.sceneNode		W.l1 = p1:getObjectByName("Bip01 L Hand")	W.r1 = p1:getObjectByName("Bip01 R Hand")	W.w1 = p1:getObjectByName("Weapon Bone")
		local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object		mp:unequip{armorSlot = 8}	mp:unequip{type = tes3.objectType.light}	L.ClearEn()
		W.l1:attachChild(W.wl1)		W.wl1:updateNodeEffects()	W.l3:attachChild(W.wl3)		W.wl3:updateNodeEffects()	W.r1:attachChild(W.wr1)		W.wr1:updateNodeEffects()	W.r3:attachChild(W.wr3)		W.wr3:updateNodeEffects()
		L.Cul(true)		W.DWM = true	event.register("playItemSound", L.DWESound, {priority = 10000})		if cf.m then tes3.messageBox("Double weapons! %s and %s", W.WR, W.WL) end
		if W.ER then D.DWER = (tes3.applyMagicSource{reference = p, name = "Enchant_right", effects = W.ER}).serialNumber end
		if W.EL then D.DWEL = (tes3.applyMagicSource{reference = p, name = "Enchant_left", effects = W.EL}).serialNumber end
		if W.ER and w == W.WR and wd == W.DR then mp:equip{item = W.WL, itemData = W.DL} elseif W.EL and w == W.WL and wd == W.DL or (w ~= W.WR and w ~= W.WL) then mp:equip{item = W.WR, itemData = W.DR} end
	else if cf.m then tes3.messageBox("Weapons not prepared! %s and %s", W.WR, W.WL) end		W.WL = nil	 W.DL = nil	end end
elseif W.DWM then L.ClearEn()		tes3.loadAnimation{reference = tes3.player1stPerson, file = nil}		L.MagefAdd()
	W.l1:detachChild(W.wl1)		W.l3:detachChild(W.wl3)		W.r1:detachChild(W.wr1)		W.r3:detachChild(W.wr3)
	L.Cul(false)	W.DWM = false	event.unregister("playItemSound", L.DWESound, {priority = 10000})	if cf.m then tes3.messageBox("DW mod off") end
end end

local TSK = 1	--local function SIMTS() wc.deltaTime = wc.deltaTime * TSK end
L.UpdTSK = function() local pow = Mag(510)
if pow == 0 then TSK = 1 else TSK = math.max(1 - pow/(pow + 40), P.ill8 and 0.1 or 0.2) end
wc.simulationTimeScalar = TSK
--tes3.messageBox("TSK = %s ", wc.simulationTimeScalar)
end


L.CWF = function(r, rt, k, pos)	local d = r.data		k = r == p and (P.mys7e and k*0.8 or k) or k/3
	local M = {d.e511 or 0, d.e512 or 0, d.e513 or 0, d.e514 or 0, d.e515 or 0}
	local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.4 + M[4]*0.5 + M[5]*0.4) * k		local mob = r.mobile
	if mc == 0 then d.CW = nil elseif mob.magicka.current > mc then local rad = rt == 2 and L.GetRad(mob)		local E = B.CW.effects
		for i, m in ipairs(M) do if m > 0 then E[i].id = MID[i]  E[i].min = m   E[i].max = m	E[i].rangeType = rt		E[i].duration = 1	E[i].radius = rad or 0	else E[i].id = -1	E[i].rangeType = 0 end end
		if pos then MP[tes3.applyMagicSource{reference = r, source = B.CW}] = {pos = pos, exp = true} else tes3.applyMagicSource{reference = r, source = B.CW} end
		Mod(mc, mob)		if cf.m then tes3.messageBox("CW = %d + %d + %d + %d + %d   Manacost = %.1f (%d%%)", M[1], M[2], M[3], M[4], M[5], mc, k*100) end
	end
end

local BAM = {[9] = "4nm_boundarrow", [10] = "4nm_boundbolt", ["met"] = "4nm_boundstar", ["4nm_boundarrow"] = 9, ["4nm_boundbolt"] = 10, ["4nm_boundstar"] = true}
BAM.f = function() mc = P.con10 and 5 or 10 	if mp.magicka.current > mc then Mod(mc) return true else return false end end

local DER = {}	local function DEDEL() for r, ot in pairs(DER) do if r.sceneNode then r.sceneNode:detachChild(r.sceneNode:getObjectByName("detect"))	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end end		DER = {} end

--local function CMSFrost(e) e.speed = e.speed * (AF[e.reference].frost2 or 1) end
local function ConstEnLim()	D.ENconst = 0
	for _, s in pairs(p.object.equipment) do if s.object.enchantment and s.object.enchantment.castType == 3 then
		if s.object.objectType == tes3.objectType.clothing then D.ENconst = D.ENconst + math.max(L.CLEN[s.object.slot] or 0, s.object.enchantCapacity)
		elseif s.object.objectType == tes3.objectType.armor then D.ENconst = D.ENconst + math.max(L.AREN[s.object.slot] or 0, s.object.enchantCapacity) end
	end end		M.ENL.current = D.ENconst		M.PC.max = L.GetPCmax()
end

L.METCOL = function(e) local sn = e.sourceInstance.serialNumber		if V.MET[sn] then V.MET[sn].colvel = e.sourceInstance.projectile.velocity:length() end end
L.METW = function(e) --if not e:trigger() then return end		
	local si = e.sourceInstance		local sn = si.serialNumber	local dmg, wd, vel, velk	local r = e.effectInstance.target		local m = r.mobile
	if V.MET[sn] then vel = V.MET[sn].colvel 	velk = 4*vel/(vel/100 + 100)		dmg = V.MET[sn].dmg	* velk/100 		wd = V.MET[sn].r.attachments.variables		V.MET[sn] = nil
	elseif si == W.TETsi then dmg = W.TETdmg * Cpow(mp,0,4,true)/100		W.TETsi = nil	W.TETmod = 3
		if M.MCB.normalized > 0 then dmg = dmg * (1 + M.MCB.normalized * (P.wil7 and 0.2 or 0.1))		M.MCB.current = 0 end	wd = W.TETR.object.hasDurability and W.TETR.attachments.variables
	end
	if dmg then local CritC = mp.attackBonus/5 + mp:getSkillValue(23)/(P.mark6c and 10 or 20) + mp.agility.current/(P.agi1 and 10 or 20) + (P.luc1 and mp.luck.current/20 or 0)
		+ (m.isMovingForward and 10 or 0) - (m.endurance.current + m.agility.current + m.luck.current)/20 - m.sanctuary/10 + math.max(1-m.fatigue.normalized,0)*(P.agi11 and 20 or 10) - 10
		local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + (P.agi8 and 10 or 0) + (P.mark5c and 20 or 0) end
		if Kcrit > 0 then dmg = dmg * (1 + Kcrit/100)		tes3.playSound{reference = r, sound = "critical damage"} end
		local fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}	--resistAttribute = not (w.enchantment or w.ignoresNormalWeaponResistance) and 12 or nil
		if wd then wd.condition = math.max(wd.condition - dmg * tes3.findGMST("fWeaponDamageMult").value, 0) end
		if cf.m30 then tes3.messageBox("Throw dmg = %d / %d   vel = %d (%d%%)  Crit = %d%% (%d%%)", fdmg, dmg, vel or 0, velk or 0, Kcrit, CritC) end
	end		e.effectInstance.state = tes3.spellState.retired
end

L.SimMET = function(e)
for r, t in pairs(V.METR) do if t.f then
	r.position = r.position:interpolate(pp, wc.deltaTime * (P.alt19 and 1500 or 1000))
	if pp:distance(r.position) < 150 then local ob = r.object	p:activate(r)		if not mp.readiedWeapon	then timer.delayOneFrame(function() mp:equip{item = ob} end) end	V.METR[r] = nil end
end end
if table.size(V.METR) == 0 then event.unregister("simulate", L.SimMET)	W.metflag = nil end
end

local function SIMTEL(e) if W.TETR then
	if W.TETmod == 1 then W.TETR.position = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150 + tes3vector3.new(0,0,-30)		W.TETR.orientation = p.orientation
	elseif W.TETmod == 2 then W.TETR.position = W.TETP.position		W.TETR.orientation = p.orientation
	elseif W.TETmod == 3 then W.TETR.position = W.TETR.position:interpolate(pp, wc.deltaTime* (P.alt19 and 1500 or 1000))
		if pp:distance(W.TETR.position) < 150 then W.TETmod = 1	tes3.playSound{sound = "enchant fail"}		local ob = W.TETR.object		if ob.chopMax and W.TETR.attachments.variables then
		W.TETdmg = math.max(math.max(ob.slashMax, ob.chopMax, ob.thrustMax) * math.max(W.TETR.attachments.variables.condition/ob.maxCondition, P.arm2 and 0.3 or 0.1), ob.weight/3) end end
	end
else event.unregister("simulate", SIMTEL) 	W.TETP = nil	W.TETmod = nil	end end

local function TELnew(r)
if W.TETmod then local hit = tes3.rayTest{position = W.TETR.position, direction = V.down}	if hit then W.TETR.position = hit.intersection + tes3vector3.new(0,0,5) end
if cf.m then tes3.messageBox("%s no longer under control", W.TETR.object.name) end		event.unregister("simulate", SIMTEL) 	W.TETmod = nil	W.TETR = nil	W.TETP = nil	W.TETsi = nil end		
if r.stackSize == 1 and tes3.isAffectedBy{reference = p, effect = 506} then	local ob = r.object		local wd = r.attachments.variables
	W.TETcost = 5 + ob.weight		W.TETR = r		W.TETmod = 1	event.register("simulate", SIMTEL)
	if not tes3.hasOwnershipAccess{target = r} then tes3.triggerCrime{value = ob.value, type = 5, victim = wd.owner} end
	W.TETdmg = ob.chopMax and ( (ob.objectType == tes3.objectType.ammunition or ob.type == 11) and ob.chopMax/2
	or (ob.type < 9 and math.max(ob.slashMax, ob.chopMax, ob.thrustMax) * (wd and math.max(wd.condition/ob.maxCondition, P.arm2 and 0.3 or 0.1) or 1)) ) or 0
	W.TETdmg = math.max(W.TETdmg, ob.weight/3, 1)
	if cf.m then tes3.messageBox("%s under control!  weight = %.2f  dmg = %.1f", ob.name, ob.weight, W.TETdmg) end
end end


local LI = {R = {}}
LI.SIM = function()	if LI.r then if LI.r.cell ~= p.cell then LI.r:delete()	LI.New(T.LI.iterations, pp)
else local pos = pp:copy()	pos.z = pos.z + 200 + LI.l.radius/50	LI.r.position = LI.r.position:interpolate(pos, 5 + LI.r.position:distance(pos)/20) end end end
LI.New = function(dur, spos) if LI.r then LI.l.radius = Mag(504) else event.register("simulate", LI.SIM) end
	LI.r = tes3.createReference{object = "4nm_light", scale = math.min(1+LI.l.radius/1000, 9), position = spos, cell = p.cell}	LI.r.modified = false
	if not T.LI.timeLeft then T.LI = timer.start{duration = 1, iterations = dur, callback = function()
		if T.LI.iterations == 1 then event.unregister("simulate", LI.SIM)	LI.r:delete()	T.LI:cancel()	LI.r = nil else LI.r:disable()	LI.r:enable()	LI.r.modified = false end
	end} end
end

local function LightCollision(e) if e.sourceInstance.caster == p then -- Фонарь (504)
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local pos = e.collision.point:copy()	pos.z = pos.z + 5	local col = L.Rcol(cf.col)
LI.l.color[1] = col[1]		LI.l.color[2] = col[2]		LI.l.color[3] = col[3]		LI.l.radius = math.random(ef.min, ef.max) * Cpow(mp,0,0) * (SN[e.sourceInstance.serialNumber] or 1)
local LTR = tes3.createReference{object = "4nm_light", scale = math.min(1+LI.l.radius/1000, 9), position = pos, cell = p.cell}	LTR.modified = false	LI.R[LTR] = true
timer.start{duration = ef.duration, callback = function() LI.R[LTR] = nil	LTR:delete() end}
if cf.m then tes3.messageBox("Light active! Radius = %d   Time = %d	  Total = %d", LI.l.radius, ef.duration, table.size(LI.R)) end
end end


L.AuraTik = function()	local Mg = {D.e516 or 0, D.e517 or 0, D.e518 or 0, D.e519 or 0, D.e520 or 0}		local MSum = Mg[1] + Mg[2] + Mg[3] + Mg[4] + Mg[5]
if MSum > 0 then	local MTab = {}		local num = 0	local rad
	if not D.Aurdis then local E = B.AUR.effects		rad = (50 + mp.willpower.current/2 + mp:getSkillValue(11)) * ((P.alt12 and 2 or 1.5) + (P.alt5a and M.MCB.normalized or 0))
		for i, mag in ipairs(Mg) do if mag > 0 then E[i].id = MID[i]  E[i].min = mag		E[i].max = mag	E[i].duration = 3 else E[i].id = -1 end end
		for _, m in pairs(tes3.findActorsInProximity{reference = p, range = rad}) do if m ~= mp and (cf.agr or m.actionData.target == mp) and tes3.getCurrentAIPackageId(m) ~= 3 then MTab[m.reference] = m		num = num + 1 end end
	end
	if num > 0 then
		for r, m in pairs(MTab) do SNC[(tes3.applyMagicSource{reference = r, source = B.AUR}).serialNumber] = mp		L.CrimeAt(m) end
		if cf.m then tes3.messageBox("Aura = %d + %d + %d + %d + %d   Rad = %d   %d targets", Mg[1], Mg[2], Mg[3], Mg[4], Mg[5], rad, num) end
	else for _, aef in pairs(mp:getActiveMagicEffects{}) do	if ME[aef.effectId] == "aura" then	local EI = aef.effectInstance		EI.timeActive = EI.timeActive - (P.mys7c and 2 or 1) end end end
else T.AUR:cancel()		D.AUR = nil end
end

L.ExpSpell = function()	local M = {D.e531 or 0, D.e532 or 0, D.e533 or 0, D.e534 or 0, D.e535 or 0}		local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.4 + M[4]*0.5 + M[5]*0.4) * (P.mys7d and 1.2 or 1.5)
if mc > 0 then if mp.magicka.current > mc then	local rad = math.random(5) + L.GetRad(mp)
	for i, mag in ipairs(M) do if mag > 0 then G.EXP[i].id = MID[i]  G.EXP[i].min = mag   G.EXP[i].max = mag	G.EXP[i].radius = rad	G.EXP[i].duration = 1	G.EXP[i].rangeType = 2 else G.EXP[i].id = -1	G.EXP[i].rangeType = 0 end end
	Mod(mc)		if cf.m then tes3.messageBox("Explode = %d + %d + %d + %d + %d   Rad = %d   Cost = %.1f", M[1], M[2], M[3], M[4], M[5], rad, mc) end
end else D.Exp = nil end
end

L.RechargeTik = function() if G.REI then	local mag = Mag(501)	if mag == 0 then AF[p].T501:cancel()	AF[p].T501 = nil else		pow = mag * (1 + (P.enc4 and mp:getSkillValue(9)/400 or 0))
	if W.en and W.v.charge < W.en.maxCharge then W.v.charge = math.min(W.v.charge + pow, W.en.maxCharge)
		if cf.m2 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s charges = %d/%d", pow, mag, W.w.name, W.v.charge, W.en.maxCharge) end
	else	local cen = mp.currentEnchantedItem		local cida = cen and cen.itemData
		if cida and cida.charge < cen.object.enchantment.maxCharge then cida.charge = math.min(cida.charge + pow, cen.object.enchantment.maxCharge)
			if cf.m2 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s charges = %d/%d", pow, mag, cen.object.name, cida.charge, cen.object.enchantment.maxCharge) end
		else
			if not (G.REI.ob and inv:contains(G.REI.ob, G.REI.ida)) then	G.REI = {}
				for i, ri in pairs(wc.rechargingItems) do if inv:contains(ri.object, ri.itemData) then G.REI = {ob = ri.object, ida = ri.itemData, max = ri.enchantment.maxCharge}	break end end
			end
			if G.REI.ob then	G.REI.ida.charge = math.min(G.REI.ida.charge + pow, G.REI.max)
				if cf.m2 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s charges = %d/%d", pow, mag, G.REI.ob.name, G.REI.ida.charge, G.REI.max) end
				if G.REI.max == G.REI.ida.charge then G.REI = {} end
			else G.REI = nil end
		end
	end		--tes3.messageBox("Recharge Tick")
end end end

L.RechargeNPC = function(m, t, te) local mag = Mag(501,t)	if mag == 0 then te.timer:cancel()	AF[t].T501 = nil else
	local w = m.readiedWeapon	local v = w and w.variables		local en = w and w.object.enchantment
	if v and en and v.charge < en.maxCharge then v.charge = math.min(v.charge + mag, en.maxCharge)
		if cf.m2 then tes3.messageBox("Pow = %.1f  %s charges = %d/%d", mag, w.object.name, v.charge, en.maxCharge) end
	else for _, st in pairs(t.object.equipment) do v = st.variables		en = st.object.enchantment	if v and en and v.charge < en.maxCharge then v.charge = math.min(v.charge + mag, en.maxCharge)
		if cf.m2 then tes3.messageBox("Pow = %.1f  %s charges = %d/%d", mag, st.object.name, v.charge, en.maxCharge) end break
	end end end	
end end

L.MSF = function(RP, RFM, m, Epow)	local RFM1 = math.min(RFM, Epow)	mc = RFM1 * ((m ~= mp or P.mys7g) and 0.2 or 0.25)
	if m.magicka.current > mc then	if cf.m1 then tes3.messageBox("Manashield = %.1f / %.1f  Cost = %.1f", RFM, Epow, mc) end	Mod(mc,m)	return 100 - (100 - RP) * (1 - RFM1/Epow)
	else return RP end
end
	
local function SIMULATE(e)		--tes3.messageBox("State = %s   dt = %s", ad.animationAttackState, wc.deltaTime)
--	for r, tab in pairs(N) do if not L.Summon[r.baseObject.id] then tes3.applyMagicSource{reference = r, name = "sumsum", effects = {{id = 107, duration = 2}}} end end
	
	local Cint, Cmult = mp.intelligence.current, mp.magickaMultiplier.current	--local New = Cmult * Cint * 2
	
--	if G.LastMana and New ~= PMP.base then
--		PMP.base = New		PMP.current = math.min(New, G.LastMana)	M.Mana.current = PMP.current	M.Mana.max = New
--	end

--	if G.LastMana and (G.LastInt ~= Cint or G.LastMM ~= Cmult) then
--		PMP.base = Cmult * Cint * 2		PMP.current = math.min(PMP.base, G.LastMana)	M.Mana.current = PMP.current	M.Mana.max = PMP.base
--	end

	if G.LastMana and (G.LastInt ~= Cint or G.LastMM ~= Cmult) and G.LastMana < PMP.current then
		PMP.current = G.LastMana	M.Mana.current = G.LastMana
		--PMP.current = math.min(PMP.base, G.LastMana)		M.Mana.current = PMP.current
	end
	G.LastMana = PMP.current		G.LastInt = Cint		G.LastMM = Cmult
end		--event.register("simulate", SIMULATE)


local function ABSORBEDMAGIC(e)	if e.mobile == mp then	local pow	local s = e.source	local si = e.sourceInstance			local num = s:getActiveEffectCount()
if s.weight then pow = 0	for i, ef in ipairs(s.effects) do if ef.id ~= -1 then pow = pow + (ef.min + ef.max) * ef.cost * ef.duration/40 end end
else pow = e.absorb end
if not (P.mys21 and mp.spellReadied) then pow = pow/2 end		e.absorb = pow/num
if cf.m then tes3.messageBox("ABS %s  Mana + %.1f  (%d / %d eff)", s.name or s.id, e.absorb, pow, num) end
end end		event.register("absorbedMagic", ABSORBEDMAGIC)

local function SPELLRESIST(e)	local c, resist, Cbonus, CritC, CritD 	local t = e.target	local m = t.mobile	local s = e.source	local ef = e.effect		local dur = ef.duration		local rt = ef.rangeType
local eid = ef.id	local sc = ef.object.school		local si = e.sourceInstance		local sn = si.serialNumber		local sot = s.objectType 		local wg = s.weight		local RP = 0	local cas = e.caster
if cas then if wg then if wg == 0 then	-- для алхимии с весом кастера нет
	if rt == 0 then		if e.resistAttribute == 28 then c = cas.mobile else c = SNC[sn] end
	else c = cas.mobile end
end else c = cas.mobile end end
local MKF = L.DurKF[eid] and (c ~= mp or P.int9) and dur > 1 and 1 + L.DurKF[eid]/100 * (dur - 1)^0.5 or 1
if c then 	local will = c.willpower.current		local Emp = EMP[eid] and c.reference.data[EMP[eid].e]		if Emp then MKF = MKF + Emp * ((c ~= mp or P.des7) and 0.005 or 0.003) end
--	if not c.object.level then tes3.messageBox("bad caster = %s  sid = %s", c.reference, s.id) end
	Cbonus = c:getSkillValue(SP[sc].s)/((c ~= mp or P[MEP[eid] and MEP[eid].p0 or SP[sc].p1]) and 5 or 10) + ((c ~= mp or P[MEP[eid] and MEP[eid].p or "mys0"]) and c:getSkillValue(MEP[eid] and MEP[eid].s or 14)/10 or 0)
	if sot == tes3.objectType.enchantment then Cbonus = Cbonus/2 + c:getSkillValue(9) * ((c ~= mp or P.enc1) and 0.15 or 0.1) end		Cbonus = Cbonus + will/((c ~= mp or P.wil1) and 5 or 10)
	if ME[eid] == "shield" and m == mp and P.una7 then Cbonus = Cbonus + D.AR.u * m:getSkillValue(17)/100 end
	CritC = will/(1+will/400)/((c ~= mp or P.wil4) and 8 or 16) + ((c ~= mp or P.luc1) and c.luck.current/20 or 0) + (c == mp and (P.int5 and mp.spellReadied and 5 or 0) or c.object.level + 10)
	- (e.resistAttribute == 28 and 10 or ((m.spellReadied and (m ~= mp or P.mys5) and m:getSkillValue(14)/10 or 0) + m.willpower.current/((m ~= mp or P.wil6) and 10 or 20) + ((m ~= mp or P.luc2) and m.luck.current/20 or 0)
	- ((c ~= mp or P.wil8) and c.attackBonus/10 or 0) - ((c ~= mp or P.des0) and c:getSkillValue(10)/20 or 0) - math.max(1-m.fatigue.normalized,0)*((c ~= mp or P.int15) and 20 or 10) ))
	CritD = CritC - math.random(100)	if CritD < 0 then CritD = 0 else CritD = CritD + 10 + ((c ~= mp or P.wil11) and 10 or 0) + (EMP[eid] and (c ~= mp or P[EMP[eid].p]) and c:getSkillValue(10)/10 or 0) end
	local Koef = SN[sn]		if Koef then	if Koef > 1 then MKF = MKF + Koef - 1 else MKF = MKF * Koef end end
	
else	Cbonus = 0	CritC = 0	CritD = 0 end -- Обычные зелья, обычные яды, алтари, ловушки и прочие кастующие активаторы
if e.resistAttribute == 28 then -- Магия с позитивными эффектами
	if sot == tes3.objectType.spell and s.castType == 0 then -- Не влияет  на пост.эффекты, powers(5), всегда успешные
		if not s.alwaysSucceeds then RP = 0 - Cbonus - CritD		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% spell power (+ %.1f bonus + %.1f crit (%.1f%%)) x%.2f mult", s.name, 100 - RP, Cbonus, CritD, CritC, MKF) end
		elseif L.AA[s.id] and c == mp and ME[eid] ~= 0 then
			local Kstam = math.min(math.lerp((P.end18 and 0.5 or 0.2), 1, mp.fatigue.normalized*1.1), 1)
			RP = 0 - math.min(L.AA[s.id].s and c:getSkillValue(L.AA[s.id].s) or t.object.level,100)*(P.agi21 and 1 or 0.5)			RP = 100 - (100 - RP) * Kstam
			if cf.m1 then tes3.messageBox("%s  %d%% technique power   %d%% stam", s.name, 100 - RP, Kstam*100) end
		elseif L.STAR[s.id] then RP = - t.object.level	if cf.m1 then tes3.messageBox("%s  %d%% Star power", s.name, 100 - RP) end end
	elseif wg then
		if wg == 0 then
			if s.icon == "" and m == mp and not L.ING[s.name] then RP = G.TR.tr8 and (P.alc2 and 95 or 100) or (P.alc2 and 75 or 90)
				if cf.m1 then tes3.messageBox("%s  ingred power = %.1f for %d seconds", s.name, ef.max*(100-RP)/100, dur) end
			end
		else MKF = m == mp and (1 - math.max((D.potcd and D.potcd - 40 - G.potlim/(P.alc11 and 2 or 4) or 0)/G.potlim, 0)) * (G.TR.tr8 and 0.2 or 1) or 1
			RP = 0 - m.willpower.current/10 - m:getSkillValue(16)/((m ~= mp or P.alc1) and 5 or 10) - (m == mp and P.alc12 and (D.potcd or 0) < 35 and 20 or 0)
			if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% alchemy power   x%.2f mult", s.name, 100 - RP, MKF) end
		end
	elseif sot == tes3.objectType.enchantment then -- Сила зачарований castType 0=castOnce, 1=onStrike, 2=onUse, 3=constant
		if s.castType ~= 3 then	RP = 0 - Cbonus - CritD		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		--	if eid == 76 and t == p and s.castType ~= 0 then RP = math.max(RP, 90) end
			if cf.m1 then tes3.messageBox("%s  %.1f%% enchant power (+ %.1f bonus + %.1f crit (%.1f%%)) x%.2f mult", s.id, 100 - RP, Cbonus, CritD, CritC, MKF) end
		elseif t == p then ConstEnLim()	if cf.enchlim then
			if W.DWM and si.item.objectType == tes3.objectType.weapon then e.resistedPercent = 100 return end
			if M.ENL.normalized > 1 then e.resistedPercent = 100	tes3.messageBox("Enchant limit exceeded! %d / %d", M.ENL.current, M.ENL.max)	tes3.playSound{sound = "Spell Failure Conjuration"} return
			elseif ef.min ~= ef.max and ME[eid] ~= 2 then RP = 50	tes3.messageBox("Anti-exploit! Enchant power reduced by half!") end
		end end
	end
	if RP < 100 then
	if sc == 1 then L.conjpower = 1 - RP/200	L.conjp = t == p or nil		L.conjagr = t ~= p and m.fight > 80 or nil		--L.sumsum = L.Summon[t.baseObject.id] 
		if ME[eid] == 3 and (t ~= p or P.con14 or RP > 0) then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end)
		elseif ME[eid] == 0 then
			if t == p then
				if P.con11 then
					if wg == 0 and s.name == "Summon" or (sot == tes3.objectType.enchantment and s.castType == 3) then e.resistedPercent = RP		L.conjpower = L.conjpow1
						if cf.BBen and dur > 1 and RP < 100 then L.NewBB(eid, ef.object.bigIcon, dur, sn*10 + e.effectIndex) end		return
					else tes3.applyMagicSource{reference = p, name = "Summon", effects = {{id = eid, duration = dur * ((P.con16 or RP > 0) and 1 - RP/100 or 1)}}}
					--	tes3.findGMST("sMagicSkeletalMinionID").value = table.choice{"skeleton archer", "skeleton champion", "skeleton warrior"}	tes3.messageBox("%s", tes3.findGMST("sMagicSkeletalMinionID").value)
						L.conjpow1 = L.conjpower		e.resistedPercent = 100		return
					end
				elseif P.con16 or RP > 0 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end) end
			elseif N[t] then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end) end
		end
	end
	if eid < 500 then
		if ME[eid] == 4 then
			if c == mp and P.res10 and RP < 0 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * math.max(RP/500, -0.2) end end) end
			if t == p then if eid == 84 then timer.delayOneFrame(L.MPUpdate) elseif eid == 82 then timer.delayOneFrame(L.STUpdate) end end
		elseif ME[eid] == 5 and c == mp and P.res11 and RP < 0 then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * math.max(RP/500, -0.2) end end)
		elseif eid == 75 then
			if s.castType ~= 3 then
				local mag0 = math.random(ef.min, ef.max) * math.max(dur,1) * (1 - RP/100)		local mag1 = mag0 * ((c ~= mp or P.res6) and 1 or 0.5) / 10
				for i, s in ipairs(L.HealStat) do if m[s].normalized < 1 then tes3.modStatistic{reference = t, name = s, current = mag1, limitToBase = true}	mag0 = mag0/2
					if cf.m2 then tes3.messageBox("%s Healing  %s +%d", t, s, mag1) end		break
				end end
				if m ~= mp or P.res13 then	local dur1 = math.max(dur,10)	mag1 = mag0*2/dur1	if mag1 > 0.9 then
					tes3.applyMagicSource{reference = t, name = "Rest", effects = {{id = 77, min = mag1, max = mag1, duration = dur1}}}
					if cf.m2 then tes3.messageBox("%s Rest +%d - %d", t, mag1, dur1) end
				end end
			end
		elseif L.CME[eid] then
			local mag1 = (eid == 72 and 100 or math.random(ef.min, ef.max) * dur) * (1 - RP/100) * ((m ~= mp or P.alt14) and 2 or 1)		local msi, ei
			for _, aef in pairs(m:getActiveMagicEffects{effect = L.CME[eid][1]}) do msi = aef.instance
				if msi.sourceType == 3 and msi.source.name == L.CME[eid][2] then ei = aef.effectInstance
					mag1 = mag1 - ei.magnitude * (aef.duration - ei.timeActive) * L.CME[eid][3]
					if mag1 > 0 then ei.state = 6 else break end
				end
			end
		elseif eid == 10 and rt ~= 0 and t ~= p then resist = RP + math.max(m.resistMagicka,-100) + m.willpower.current + m:getSkillValue(14)/2	-- Левитация
			if cf.m then tes3.messageBox("%s  %.1f%% levitation resist", s.name or s.id, resist) end		if resist >= math.random(100) then RP = 100 end
		elseif eid == 39 and t == p and s.name ~= "Blur" then	-- Невидимость
			if P.ill10 and RP < 0 then tes3.applyMagicSource{reference = p, name = "Blur", effects = {{id = 39, duration = dur * (P.ill17 and 1 - RP/100 or 1)}, 
				{id = 40, min = -RP/4, max = -RP/2, duration = dur}}}
			elseif P.ill17 or RP > 0 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * RP/100 end end) end
		elseif eid == 118 or eid == 119 then RP = RP + math.max(m.resistMagicka,0) + (m.willpower.current + m:getSkillValue(14)/2)*(P.ill9 and 0.5 or 1) -- Приказы
			if cf.m then tes3.messageBox("%s  %.1f%% mind control resist", s.name or s.id, RP) end
			if R[t] then timer.start{duration = 0.1, callback = function() if tes3.isAffectedBy{reference = t, effect = eid} then R[t] = nil if cf.m4 then tes3.messageBox("CONTROL! %s", t) end end end} end
		elseif eid == 60 and t == p then local mmax = (1 + mp.willpower.base/200 + mp.intelligence.base/100 + mp.alteration.base/200 + mp.mysticism.base/50) * (P.mys11 and 2 or 1) -- Пометка
			local mtab = {}		for i = 1, 10 do if mmax >= i then mtab[i] = i.." - "..(DM["mark"..i] and DM["mark"..i].id or "empty") end end
			tes3.messageBox{message = "Which slot to remember the mark?", buttons = mtab, callback = function(e) DM["mark"..(e.button+1)] = {id = p.cell.id, x = pp.x, y = pp.y, z = pp.z} end}
		elseif eid == 0 and t == p then		-- Водное дыхание
			local WBR = mp.holdBreathTime
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * RP/100 end
			timer.delayOneFrame(function() mp.holdBreathTime = WBR end) end)
			if not T.WaterB.timeLeft then T.WaterB = timer.start{iterations = -1, duration = 1, callback = function()
				if mp.waterBreathing > 0 then mp.holdBreathTime = math.min(math.max(mp.holdBreathTime, 0) + mp.waterBreathing/2 - 0.3, tes3.findGMST("fHoldBreathTime").value)
				else T.WaterB:cancel()	if not mp.underwater then mp.holdBreathTime = tes3.findGMST("fHoldBreathTime").value end end		-- tes3ui.findHelpLayerMenu("MenuSwimFillBar")
			end} end
		elseif eid == 2 and t == p then	-- Хождение по воде
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * RP/100 end end)
		elseif ME[eid] == "teleport" then
			if L.TPComp() then timer.start{duration = 0.1, callback = function() for r, _ in pairs (G.TPList) do tes3.positionCell{reference = r, position = pp, cell = p.cell} end end} end
		elseif eid == 13 and P.mys23 then	-- Взлом замков
			if t.lockNode and t.lockNode.trap then pow = math.random(ef.min, ef.max) * (1 - RP/100) 
				tes3.messageBox("Power = %d   Trap = %d", pow, t.lockNode.trap.magickaCost * 4)
				if pow > t.lockNode.trap.magickaCost * 4 then t.lockNode.trap = nil 	tes3.playSound{reference = t, sound = "Disarm Trap"} end
			end
		end
	else	if L.EDAT[eid] then L.EUPD(t, eid) end
		if eid == 501 and AF[t].T501 == nil then -- Перезарядка зачарованного (501)
			if t == p then AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = L.RechargeTik} 	G.REI = {}
			else AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = function(te) if not AF[t] then te.timer:cancel() else L.RechargeNPC(m, t, te) end end} end
		elseif eid == 502 and AF[t].T502 == nil then -- Починка оружия (502)
			AF[t].T502 = timer.start{duration = 1, iterations = -1, callback = function(te) if not AF[t] then te.timer:cancel() else local mag = Mag(502,t)	if mag == 0 then te.timer:cancel()	AF[t].T502 = nil else
				pow = mag * (1 + ((m ~= mp or P.arm6) and m:getSkillValue(1)/400 or 0))		local w = m.readiedWeapon
				if w and w.object.type ~= 11 and w.variables.condition < w.object.maxCondition then w.variables.condition = math.min(w.variables.condition + pow, w.object.maxCondition)
					if cf.m1 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, w.object.name, w.variables.condition, w.object.maxCondition) end
				end
			end end end}
		elseif eid == 503 and AF[t].T503 == nil then -- Починка брони (503)
			AF[t].T503 = timer.start{duration = 1, iterations = -1, callback = function(te) if not AF[t] then te.timer:cancel() else local mag = Mag(503,t)	if mag == 0 then te.timer:cancel()	AF[t].T503 = nil else
				pow = mag * (1 + ((m ~= mp or P.arm6) and m:getSkillValue(1)/400 or 0))	
				for _, st in pairs(t.object.equipment) do if st.object.objectType == tes3.objectType.armor and st.variables and st.variables.condition < st.object.maxCondition then
					st.variables.condition = math.min(st.variables.condition + pow, st.object.maxCondition)
					if cf.m1 then tes3.messageBox("Pow = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, st.object.name, st.variables.condition, st.object.maxCondition) end	break
				end end
			end end end}
		elseif ME[eid] == "charge" then t.data.CW = true	-- Зарядить оружие. Эффекты 511, 512, 513, 514, 515
		elseif ME[eid] == "aura" and t == p then D.AUR = true
			if not T.AUR.timeLeft then T.AUR = timer.start{duration = P.alt11 and math.max(3 - mp:getSkillValue(11)/200, 2.5) or 3, iterations = -1, callback = L.AuraTik} end
			local mag1 = math.random(ef.min, ef.max) * dur * (1 - RP/100) * ((m ~= mp or P.alt14) and 2 or 1)		local msi, ei
			for _, aef in pairs(m:getActiveMagicEffects{effect = L.CME[eid][1]}) do msi = aef.instance
				if msi.sourceType == 3 and msi.source.name == L.CME[eid][2] then ei = aef.effectInstance
					mag1 = mag1 - ei.magnitude * (aef.duration - ei.timeActive) * L.CME[eid][3]
					if mag1 > 0 then ei.state = 6 else break end
				end
			end
		elseif ME[eid] == "explode" and t == p then D.Exp = true
		elseif eid == 601 and t == p then	if m.readiedWeapon then BAM.am = BAM[m.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
			if mwscript.getItemCount{reference = t, item = BAM.am} == 0 and BAM.f() then tes3.addItem{reference = t, item = BAM.am, count = 100, playSound = false}	m:equip{item = BAM.am} end
		elseif eid == 510 and t == p then 	-- not T.TS.timeLeft then event.register("simulate", SIMTS)	-- Замедление времени (510)
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	L.UpdTSK()		if ei and dur > 0 then ei.timeActive = dur * (1 - TSK) end end)
		elseif eid == 504 and t == p then D.ligspawn = true		local col = L.Rcol(cf.col)
			LI.l.color[1] = col[1]		LI.l.color[2] = col[2]		LI.l.color[3] = col[3]		LI.l.radius = 100 * math.random(ef.min, ef.max) * (1 - RP/100)
			if T.LI.timeLeft then	event.unregister("simulate", LI.SIM)	T.LI:cancel()	LI.r:delete()	LI.r = nil end		LI.New(dur, pp)
			if cf.m then tes3.messageBox("Light active! Radius = %d  Time = %d   Total = %d", LI.l.radius, dur, table.size(LI.R)) end
		end
	end
	end
elseif wg or rt ~= 0 then local Tarmor, Tbonus, IsPois		-- Любые негативные эффекты с дальностью касание и удаленная цель ИЛИ пвсевдоалхимия ИЛИ обычные яды ИЛИ ингредиенты ИЛИ соурс таблицы
	if MKF == 0 then e.resistedPercent = 100	return end	-- Если сработало новое отражение, все эффекты спелла аннулируются
	
	if cas == t then
		if rt ~= 0 then MKF = MKF * math.max(1 - (m:getSkillValue(14) + m.willpower.current)/((m ~= mp or P.mys15) and 400 or 800), 0.25)		-- Отражение или эксплод спелл будут ослаблены
		elseif wg > 0 or s.icon == "" then	-- Зелья и ингредиенты с негативными эффектами, поименованные табличные соурсы
			if L.ING[s.name] then e.resistedPercent = 0		return end
			IsPois = true		Cbonus = 0	CritC = 0	CritD = 0
		end
	end
	local RFM = 0
	if not IsPois and rt ~= 0 then
		if m ~= mp and L.Summon[c and c.object.baseObject.id] then MKF = MKF/2 end
		
		RFM = t.data.e507 or 0
		if RFM > 0 then RFM = RFM * ((m ~= mp or P.mys14) and 1.2 or 1)
			if t.data.RFsn ~= sn and (m ~= mp or DM.refl) and (not COL[sn] or COL[sn]:distance(t.position + tes3vector3.new(0,0,m.height/2)) < 100) then
				t.data.RFsn = sn
				local pow = 0
				for i, eff in ipairs(s.effects) do if eff.id ~= -1 and eff.rangeType ~= 0 then pow = pow + (eff.min + eff.max) * eff.object.baseMagickaCost * math.max(eff.duration,1)/20 end end
				pow = pow * (100 + Cbonus + CritD)*MKF/100		mc = pow * ((m ~= mp or P.mys7g) and 2 or 2.5)
				if RFM > pow and m.magicka.current > mc then	local rad = L.GetRad(m)		local E = B.RFS.effects
					for i, eff in ipairs(s.effects) do if eff.rangeType ~= 0 then	E[i].id = eff.id	E[i].radius = math.min(eff.radius, rad)		E[i].duration = eff.duration
					E[i].min = eff.min	E[i].max = eff.max	E[i].rangeType = eff.rangeType		E[i].attribute = eff.attribute		E[i].skill = eff.skill	else E[i].id = -1	E[i].rangeType = 0 end end
					tes3.applyMagicSource{reference = t, source = B.RFS}		Mod(mc,m)		
					if cf.m then tes3.messageBox("Reflect = %.1f / %.1f  Cost = %.1f  Radius = %.1f", RFM, pow, mc, rad) end	--t.data.RFbal = true		
					SN[sn] = 0		e.resistedPercent = 100		si.state = 7	return
				elseif cf.m then tes3.messageBox("Fail! Reflect = %.1f  Power = %.1f", RFM, pow) end
			end
		end
		if EMP[eid] then RFM = RFM/3 + (t.data[EMP[eid].rf] or 0) * ((m ~= mp or P.mys14) and 1.2 or 1) end
		if RFM > 0 and m == mp and D.MSEF["e"..eid] then RFM = 0 end
	end
	
	local Epow = (ef.min + ef.max)/2 * math.max(dur,1)
	local NormR = math.max(m[L.RES[eid] or (IsPois and "resistPoison" or "resistMagicka")],-100)
	if ME[eid] == 1 then Tarmor = m.armorRating * ((m ~= mp or P.end21) and 0.2 or 0.1)			local rsh = m.readiedShield
		Tbonus = (math.min(m.endurance.current,100)/5 + math.min(m.willpower.current,100)/5) * ((m ~= mp or P[EMP[eid].p3]) and 1 or 0.5) + ((m ~= mp or P.des9) and math.min(m:getSkillValue(10),100)/10 or 0)
		if c == mp and ((P.mys9 and m.object.type == 1) or (P.res9 and m.object.type == 2)) then Cbonus = Cbonus + 10 end
		if rsh and (m ~= mp or mp.actionData.animationAttackState == 2) then Tbonus = Tbonus + m:getSkillValue(0)/((m ~= mp or P.bloc7) and 5 or 10)
			rsh.variables.condition = math.max(rsh.variables.condition - math.random(ef.min, ef.max) * math.max(dur,1) * MKF/2, 0)
			if m == mp then L.UpdShield(rsh) end		if rsh.variables.condition < 0.1 then m:unequip{item = rsh.object} end
		end
	end

	if eid == 14 then
		resist = NormR + Tarmor + Tbonus - Cbonus - CritD
		if resist < 0 then RP = resist elseif m == mp then RP = 100*resist/(resist+100) else RP = resist > 350 and m.health.normalized < 1 and math.min(resist - 250, 150) or math.min(150*resist/(resist+150), 100) end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% fire resist  %.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f crit (%.1f%%)  x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Tarmor, Cbonus, CritD, CritC, MKF) end
		if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
		if RP < 100 then
			local mag1 = math.random(ef.min, ef.max) * math.max(dur,1) * (1 - RP/100) / 25
			* ((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if mag1 > 0.5 then tes3.applyMagicSource{reference = t, name = "Burning", effects = {{id = 14, min = mag1, max = mag1, duration = 5}}}
				if cf.m2 then tes3.messageBox("%s Burning  %d", t, mag1) end
			end
		end
	elseif eid == 16 then
		resist = NormR + Tarmor + Tbonus - Cbonus - CritD
		if resist < 0 then RP = resist elseif m == mp then RP = 100*resist/(resist+100) else RP = resist > 350 and m.health.normalized < 1 and math.min(resist - 250, 150) or math.min(150*resist/(resist+150), 100) end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% frost resist  %.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f crit (%.1f%%)  x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Tarmor, Cbonus, CritD, CritC, MKF) end
		if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
		if RP < 100 then
			local mag1 = math.random(ef.min, ef.max) * (1 - RP/100)
			* ((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if mag1 > 0.5 then tes3.applyMagicSource{reference = t, name = "Freeze", effects = {{id = 25, min = mag1, max = mag1, duration = dur}}}
				if cf.m2 then tes3.messageBox("%s Freeze  %d - %d", t, mag1, dur) end
			end
		end
	elseif eid == 15 then
		resist = NormR + Tarmor + Tbonus - Cbonus - CritD
		if resist < 0 then RP = resist elseif m == mp then RP = 100*resist/(resist+100) else RP = resist > 350 and m.health.normalized < 1 and math.min(resist - 250, 150) or math.min(150*resist/(resist+150), 100) end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% lightning resist  %.1f = %.1f norm + %.1f target + %.1f armor - %.1f caster - %.1f crit (%.1f%%)  x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Tarmor, Cbonus, CritD, CritC, MKF) end
		if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
		if RP < 100 then
			local mag1 = math.random(ef.min, ef.max) * (1 - RP/100) / 2
			* ((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			if mag1 > 0.5 then tes3.applyMagicSource{reference = t, name = "Electroshock", effects = {{id = 24, min = mag1, max = mag1, duration = dur}}}
				if cf.m2 then tes3.messageBox("%s Electroshock  %d - %d", t, mag1, dur) end
			end
		end
	elseif eid == 27 then Tbonus = (math.min(m.endurance.current,100)*0.3 + math.min(m.willpower.current,100)*0.1) * ((m ~= mp or P[EMP[eid].p3]) and 1 or 0.5) + ((m ~= mp or P.alc10) and math.min(m:getSkillValue(16),100)/10 or 0)
		resist = NormR + Tbonus - Cbonus - CritD
		if resist < 0 then RP = resist elseif m == mp then RP = 100*resist/(resist+100) else RP = resist > 350 and m.health.normalized < 1 and math.min(resist - 250, 150) or math.min(150*resist/(resist+150), 100) end
		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
		if cf.m1 then tes3.messageBox("%s  %.1f%% poison resist  %.1f = %.1f norm + %.1f target - %.1f caster - %.1f crit (%.1f%%)  x%.2f mult",
		s.name or s.id, RP, resist, NormR, Tbonus, Cbonus, CritD, CritC, MKF) end	
		if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
		if RP < 100 then	local dur1 = math.max(dur,20)
			local mag1 = math.random(ef.min, ef.max) * math.max(dur,1) * (1 - RP/100) * 10/dur1
			* ((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
			local atr = math.random(0,5)	if atr == 4 and m.actorType == 0 and not m.object.biped then mag1 = mag1/3 end
			tes3.applyMagicSource{reference = t, name = "Poisoning", effects = {{id = 17, attribute = atr, min = mag1, max = mag1, duration = dur1}}}
			if cf.m2 then tes3.messageBox("%s Poisoning  %d - %d", t, mag1, dur1) end
		end
	else	Tbonus = (math.min(m.endurance.current,100)*0.1 + math.min(m.willpower.current,100)*0.3) * ((m ~= mp or P.wil3) and 1 or 0.5) + ((m ~= mp or P.mys6) and math.min(m:getSkillValue(14),100)/10 or 0)
		if eid == 45 or eid == 46 then local Extra = m:getSkillValue(12) * ((m ~= mp or P.ill6) and 0.5 or 0.2) > math.random(100) and 200 or 0			-- Паралич и молчание считаем отдельно
			resist = NormR + m.resistParalysis + Tbonus - Cbonus - CritD + Extra
			if resist < 0 then RP = resist elseif m == mp then RP = 100*resist/(resist+100) else RP = math.min(150*resist/(resist+150), 100) end
			if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% paralysis resist (%.1f = %.1f paral + %.1f magic + %.1f target - %.1f caster - %.1f crit (%.1f%%) + %d extra) x%.2f mult",
			s.name or s.id, RP, resist, m.resistParalysis, NormR, Tbonus, Cbonus, CritD, CritC, Extra, MKF) end
			if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
			if RP >= 100 then RP = 100 elseif RP > 0 or (RP < 0 and (c ~= mp or P.ill18)) then
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end) end
		elseif eid == 55 or eid == 56 then local Extra = P.per9 and mp.personality.current/5 or 0
			RP = 0 - Cbonus - CritD	- Extra		if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end		-- Ралли
			local koef = 1 - RP/100		local min = ef.min*koef		local max = ef.max*koef		local k1 = P.ill14 and 1 or 0.5		local k2 = P.ill15 and 0.02 or 0	local k3 = P.ill16 and 0.05 or 0
			local atr = math.random(0,5)	if atr == 4 and m.actorType == 0 and not m.object.biped then k1 = k1/3 end
			tes3.applyMagicSource{reference = t, name = "Rally", effects = {{id = 79, min = min*k1, max = max*k1, attribute = atr, duration = dur},
			{id = 77, min = min*k1/2, max = max*k1/2, duration = dur}, {id = 75, min = min*k2, max = max*k2, duration = dur}, {id = 76, min = min*k3, max = max*k3, duration = dur}}}
			if cf.m1 then tes3.messageBox("%s  %.1f%% Rally power (+ %.1f bonus + %.1f crit (%.1f%%) + %d extra) x%.2f mult", s.name or s.id, 100 - RP, Cbonus, CritD, CritC, Extra, MKF) end
		else resist = NormR + Tbonus - Cbonus - CritD	-- Всё остальное негативное кроме паралича и ралли
			if resist < 0 then RP = resist elseif m == mp then RP = 100*resist/(resist+100) else RP = math.min(150*resist/(resist+150), 100) end
			if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% magic resist (%.1f = %.1f norm + %.1f target - %.1f caster - %.1f crit (%.1f%%)) x%.2f mult",
			(s.name or s.id), RP, resist, NormR, Tbonus, Cbonus, CritD, CritC, MKF) end
			if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
			if eid == 23 and RP < 100 then 
				local mag1 = math.random(ef.min, ef.max) * math.max(dur,1) * (1 - RP/100) / 5
				* ((c ~= mp or P.wil14) and 1.25 or 1) * ((c ~= mp or P[EMP[eid].p1]) and 1 or 0.5) * ((m ~= mp or P.end19) and 0.8 or 1) * (m == mp and P[EMP[eid].p2] and 0.5 or 1)
				local atr = math.random(0,5)	if atr == 4 and m.actorType == 0 and not m.object.biped then mag1 = mag1/3 end
				tes3.modStatistic{reference = t, attribute = atr, current = -mag1}
				if cf.m2 then tes3.messageBox("%s Decay  %d", t, mag1) end
			elseif ME[eid] == 6 and RP < 100 then
				if t == p and P.res12 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * (0.1 + math.max(RP/500, 0)) end end)
				elseif c == mp and P.des10 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * (math.min(RP/1000, 0) - 0.1) end end) end
			elseif ME[eid] == 7 and RP < 100 then
				if t == p and P.res12 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * (0.1 + math.max(RP/500, 0)) end end)
				elseif c == mp and P.des11 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * (math.min(RP/1000, 0) - 0.1) end end) end
			elseif eid == 51 or eid == 52 then	local koef = 1 - RP/100		local mag = math.random(ef.min, ef.max) * dur		local rad = mag * (P.ill12 and 2 or 1)		-- Френзи
				pow = mag * koef * (P.ill11 and 1.5 or 1)	local minp = 1000 + t.object.level*100
				if P.ill14 then tes3.applyMagicSource{reference = t, name = "Rally", effects = {{id = 117, min = ef.min*koef, max = ef.max*koef, duration = dur}}} end
				if pow > minp then	m.actionData.aiBehaviorState = 3
					if P.ill13 then		for _, mob in pairs(tes3.findActorsInProximity{reference = t, range = rad}) do if mob ~= m then m:startCombat(mob) end end
					else	local tar, dist		local md = rad
						for _, mob in pairs(tes3.findActorsInProximity{reference = t, range = rad}) do if mob ~= m then dist = t.position:distance(mob.position)	if dist < md then md = dist		tar = mob end end end
						if tar then m:startCombat(tar) end
					end
				end
				if cf.m then tes3.messageBox("%s Frenzy! power = %d/%d  rad = %d", t, pow, minp, rad) end
			elseif eid == 49 or eid == 50 then	-- Calm
				pow = math.random(ef.min, ef.max) * (1 - RP/100)	* (P.ill20 and 1.5 or 1)	local minp = math.max(t.object.aiConfig.fight/2 + t.object.level * (P.per10 and 5 or 10), 50)
				if pow > minp then	if R[t] then R[t] = nil		if cf.m4 then tes3.messageBox("CALM! %s", t) end end	else RP = 100 end
				if cf.m then tes3.messageBox("%s Calm! power = %d/%d  basefight = %d", t, pow, minp, t.object.aiConfig.fight) end
			end
		end
	end
else RP = 0 end -- Любые негативные эффекты с дальностью на себя, включая постоянные и баффо-дебаффы и болезни, будут действовать на 100% силы.
e.resistedPercent = RP

if t == p then 	if cf.BBen and dur > 1 and RP < 100 then L.NewBB(eid, ef.object.bigIcon, dur, sn*10 + e.effectIndex) end
else	local bid = t.baseObject.id
	if L.CID[bid] then
		if bid == "golden saint" or bid == "golden saint_summon" then
			if ME[eid] == 1 and not t.data.retcd then	for _, eff in ipairs(B.aureal.effects) do eff.id = -1 end
				for i, eff in ipairs(s.effects) do if ME[eff.id] == 1 then B.aureal.effects[i].id = eff.id		B.aureal.effects[i].min = eff.min/3		B.aureal.effects[i].max = eff.max/3
					B.aureal.effects[i].radius = 10		B.aureal.effects[i].duration = eff.duration		B.aureal.effects[i].rangeType = 2
				end end
				tes3.applyMagicSource{reference = t, source = B.aureal}	t.data.retcd = true		timer.start{duration = 0.1, callback = function() t.data.retcd = nil end}
			end
		elseif L.CID[bid] == "wolf" and s.id == "BM_summonwolf" then e.resistedPercent = -2000 elseif L.CID[bid] == "bear" and s.id == "BM_summonbear" then e.resistedPercent = -2000 end
	end
end

--timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 
--tes3.messageBox("%s  id = %s  time = %.3f/%d   Respr = %.2f   mag = %d  Cummag = %d", s.name or s.id, eid, ei.timeActive, dur, ei.resistedPercent, ei.magnitude, ei.cumulativeMagnitude) end)
--if m == mp and SSN[sn] then tes3.getMagicSourceInstanceBySerial{serialNumber = sn}.state = 6	tes3.messageBox("Resist! SNum = %s", sn) SSN[sn] = nil end	-- устраняем эксплойт с разгоном статов
-- e.effectInstance ещё не полностью построена во время эвента. Далее она меняется на полноценный effectInstance которые НЕ равен предыдущему и может быть получен из активных эффектов
end		event.register("spellResist", SPELLRESIST)

L.ERIDF = {[510] = L.UpdTSK, [84] = L.MPUpdate, [82] = L.STUpdate}
local function MAGICEFFECTREMOVED(e)	--local m, r, c, t, si, s, ei, ind = e.mobile, e.reference, e.caster, e.target, e.sourceInstance, e.source, e.effectInstance, e.effectIndex
local id = e.effect.id		local r = e.reference
if r == p then
	
	if L.ERIDF[id] then timer.delayOneFrame(L.ERIDF[id]) end
	
--	if id == 510 then timer.delayOneFrame(L.UpdTSK)
--	elseif id == 84 then timer.delayOneFrame(L.MPUpdate)
--	elseif id == 82 then timer.delayOneFrame(L.STUpdate) end
	
	local B = M.BB[id]	local sn = e.sourceInstance.serialNumber * 10 + e.effectIndex		if B and B[sn] then B[sn]:destroy()	B[sn] = nil		if table.size(B) == 2 then	B.bl:destroy()	M.BB[id] = nil end end
end

if L.EDAT[id] then L.EUPD(r, id) end

--tes3.messageBox("%s - %s (%s)  id = %s (%s)  Mag = %.2f", r, s.id, si.serialNumber, id, ind+1, ei.magnitude * (100 - ei.resistedPercent)/100)
end		event.register("magicEffectRemoved", MAGICEFFECTREMOVED)


local AOE = {}	local RUN = {}	local TOT = {}	-- АОЕ (521-525)	РУНЫ (526-530)		ТОТЕМЫ (551-555)
L.RunExp = function(n) local E = B.RUN.effects		local t = RUN[n]		--tes3.messageBox("Rune %d  exploded  id = %s", n, t.s.effects[1].id)
	for i, ef in ipairs(t.ef) do if ef.id > -1 then E[i].id = ef.id		E[i].min = ef.min	E[i].max = ef.max	E[i].duration = ef.duration		E[i].radius = ef.radius		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.RUN}] = {pos = t.r.position + tes3vector3.new(0,0,50), exp = true}		t.r:delete()	RUN[n] = nil
end
L.TotExp = function(n) local E = B.TOT.effects		local t = TOT[n]
	if t.dur > 9 then	for i, ef in ipairs(t.ef) do if ef.id > -1 then E[i].id = ef.id		E[i].min = ef.min	E[i].max = ef.max	E[i].radius = ef.radius		E[i].duration = 1	E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.TOT}] = {pos = t.r.position:copy(), exp = true} end		t.r:delete()	TOT[n] = nil
end

local function AOEcol(e) local cp = e.collision.point	if math.abs(cp.x) < 9000000 and e.sourceInstance.caster == p then local n	local s = e.sourceInstance.source		local ef = s.effects[e.effectIndex + 1]
local alt = mp:getSkillValue(11)		local koef = L.durbonus(ef.duration - 1, 5) * (SN[e.sourceInstance.serialNumber] or 1)		tes3.getObject(L.AoEmod[ef.id%5]).radius = ef.radius * 50
local r = tes3.createReference{object = L.AoEmod[ef.id%5], position = cp + tes3vector3.new(0,0,10), cell = p.cell, scale = math.min(ef.radius * (P.alt12 and 0.075 + alt/4000 or 0.075), 9.99)}	r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.alt5b and 20 or 40))		for i = 1, max do if not AOE[i] then n = i break end end
if not n then n = 1	local md = AOE[1].tim		for i, t in pairs(AOE) do if t.tim < md then md = t.tim		n = i end end end
if AOE[n] then AOE[n].r:delete()	AOE[n] = nil end
AOE[n] = {r = r, tim = ef.duration, id = MID[ef.id%5], min = ef.min * koef, max = ef.max * koef}
if cf.m10 then  tes3.messageBox("AoE %d/%d  Power = %d%%  Scale = %.2f  Time: %d", n, max, koef*100, AOE[n].r.scale, AOE[n].tim) end
if not T.AoE.timeLeft then local dur = P.alt11 and math.max(2 - alt/200, 1.5) or 2	T.AoE = timer.start{duration = dur, iterations = -1, callback = function() local fin = true		local E = B.AOE.effects[1]
	for i, t in pairs(AOE) do	t.tim = t.tim - dur		if t.tim > 0 then	fin = false		E.id = t.id		E.min = t.min	E.max = t.max	E.duration = 2
		for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = 300 * t.r.scale}) do if m ~= mp then
			SNC[(tes3.applyMagicSource{reference = m.reference, source = B.AOE}).serialNumber] = mp		L.CrimeAt(m)
		end end
	else t.r:delete()	AOE[i] = nil end end		if fin then T.AoE:cancel()	if cf.m10 then tes3.messageBox("All AoE ends") end end
end} end
end end

local function RUNcol(e) if G.RunSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 then	local n		local s = e.sourceInstance.source
local ef = s.effects[e.effectIndex + 1]		G.RunSN = e.sourceInstance.serialNumber		local koef = SN[G.RunSN] or 1	local alt = mp:getSkillValue(11)		local vel = e.sourceInstance.projectile.velocity		
local hit = tes3.rayTest{position = cp - vel:normalized()*100, direction = vel, returnNormal = true}
local r = tes3.createReference{object = "4nm_rune", position = cp + tes3vector3.new(0,0,5), orientation = hit and L.GetOri(V.up, hit.normal), cell = p.cell, scale = math.min(ef.radius * (P.alt12 and 0.15 + alt/2000 or 0.15), 9.99)}
local light = niPointLight.new()	light:setAttenuationForRadius(ef.radius/2)		light.diffuse = tes3vector3.new(L.LID[ef.id%5][1], L.LID[ef.id%5][2], L.LID[ef.id%5][3])	--tes3vector3.new(ef.object.lightingRed, ef.object.lightingGreen, ef.object.lightingBlue)
r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.alt5c and 10 or 20))		for i = 1, max do if not RUN[i] then n = i break end end
if not n then n = 1	local md = RUN[1].tim		for i, t in pairs(RUN) do if t.tim < md then md = t.tim		n = i end end	L.RunExp(n) end
local E = {{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1}}
for i, ef in ipairs(s.effects) do if ME[ef.id] == "rune" then E[i].id = MID[ef.id%5]	E[i].min = ef.min * koef	E[i].max = ef.max * koef	E[i].duration = ef.duration		E[i].radius = ef.radius end end
RUN[n] = {r = r, ef = E, tim = (100 + alt + mp:getSkillValue(14))*(P.mys20 and 0.4 or 0.2)}
if cf.m10 then  tes3.messageBox("Rune %d/%d  Power = %d%%  Scale = %.2f  Time: %d", n, max, koef*100, RUN[n].r.scale, RUN[n].tim) end
if not T.Run.timeLeft then T.Run = timer.start{duration = 1, iterations = -1, callback = function() local fin = true
	for i, t in pairs(RUN) do	t.tim = t.tim - 1	if t.tim > 0 then	fin = false
		for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = 80 * t.r.scale}) do if m ~= mp then L.RunExp(i)	break end end
	else L.RunExp(i) end end	if fin then T.Run:cancel()	if cf.m10 then tes3.messageBox("All runes ends") end end
end} end
end end end

local function TOTcol(e) if G.TotSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 then	local n		local s = e.sourceInstance.source
local ef = s.effects[e.effectIndex + 1]		local tdur = ef.duration		G.TotSN = e.sourceInstance.serialNumber		local koef = SN[G.TotSN] or 1	local alt = mp:getSkillValue(11)
local r = tes3.createReference{object = "4nm_totem", position = cp + tes3vector3.new(0,0,60*(1 + ef.radius/50)), cell = p.cell, scale = 1 + ef.radius/50}
local light = niPointLight.new()	light:setAttenuationForRadius((1 + ef.radius/50)*3)		light.diffuse = tes3vector3.new(L.LID[ef.id%5][1], L.LID[ef.id%5][2], L.LID[ef.id%5][3])
r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.alt5d and 20 or 40))		for i = 1, max do if not TOT[i] then n = i break end end
if not n then n = 1	local md = TOT[1].tim		for i, t in pairs(TOT) do if t.tim < md then md = t.tim		n = i end end	L.TotExp(n) end
local E = {{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1}}		mc = 0
for i, ef in ipairs(s.effects) do if ME[ef.id] == "totem" and tdur <= ef.duration then E[i].id = MID[ef.id%5]	E[i].min = ef.min * koef	E[i].max = ef.max * koef	E[i].radius = ef.radius
mc = mc + (E[i].min + E[i].max)	* L.MEC[ef.id%5] * (P.mys7f and 0.04 or 0.05) * (1+E[i].radius^2/(10*E[i].radius+200)) end end
TOT[n] = {r = r, ef = E, tim = tdur, dur = tdur, mc = mc}
if cf.m10 then  tes3.messageBox("Totem %d/%d  Power = %d%%  Cost = %.1f  Scale = %.2f  Time: %d", n, max, koef*100, TOT[n].mc, TOT[n].r.scale, TOT[n].tim) end
if not T.Tot.timeLeft then local dur = P.alt11 and math.max(2 - alt/200, 1.5) or 2		T.Tot = timer.start{duration = dur, iterations = -1, callback = function()	local BE = B.TOT.effects
	local fin = true	local maxdist = (100 + mp.intelligence.current + alt + mp:getSkillValue(14)) * (P.alt12 and 20 or 10)		local tar, pos, fpos, mindist, dist
	for i, t in pairs(TOT) do	t.tim = t.tim - dur		if t.tim > 0 then	fin = false
		if not D.Totdis and AC[t.r.cell] and mp.magicka.current > t.mc then fpos = nil	mindist = maxdist
			for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = maxdist}) do if m ~= mp and (cf.agr or m.actionData.target == mp) and tes3.getCurrentAIPackageId(m) ~= 3 then 
				pos = m.position + tes3vector3.new(0,0,m.height/2)		dist = t.r.position:distance(pos)
				if dist < mindist and tes3.testLineOfSight{position1 = t.r.position, position2 = pos} then mindist = dist	tar = m		fpos = pos end
			end end
			if fpos then
				for i, ef in ipairs(t.ef) do if ef.id > -1 then BE[i].id = ef.id	BE[i].min = ef.min		BE[i].max = ef.max		BE[i].radius = ef.radius	BE[i].duration = 1	BE[i].rangeType = 2
				else BE[i].id = -1	BE[i].rangeType = 0 end end
				MP[tes3.applyMagicSource{reference = p, source = B.TOT}] = {pos = t.r.position:copy(), vel = (fpos - t.r.position):normalized()}
				Mod(t.mc)		if cf.m10 then tes3.messageBox("Totem %s   Target = %s   Manacost = %.1f", i, tar.object.name, t.mc) end
			end
		end
	else L.TotExp(i) end end	if fin then T.Tot:cancel()	if cf.m10 then tes3.messageBox("All totems ends") end end
end} end
end end end

local function WAVcol(e) if G.WavSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 and e.sourceInstance.caster == p then
	G.WavSN = e.sourceInstance.serialNumber		local pr = e.sourceInstance.projectile		local t = CPR[pr.reference]	--local n	local s = e.sourceInstance.source		local ef = s.effects[e.effectIndex + 1]
	for i, ef in ipairs(t.ef) do if ME[ef.id] == "wave" then G.WAV[i].id = MID[ef.id%5]		G.WAV[i].min = ef.min*t.k*(1-(t.num-1)/t.max)		G.WAV[i].max = ef.max*t.k*(1-(t.num-1)/t.max)	--bad argument #1 to 'ipairs' (table expected, got nil)
	G.WAV[i].radius = ef.radius + t.num/(P.alt12 and 1 or 2)		G.WAV[i].duration = ef.duration		G.WAV[i].rangeType = 2	else G.WAV[i].id = -1	G.WAV[i].rangeType = 0 end end			
	MP[tes3.applyMagicSource{reference = p, source = B.WAV}] = {pos = cp - pr.velocity:normalized()*100, exp = true}
end end end


local function enterFrame(e) if not e.menuMode and MB[1] == 128 then
	mp.velocity = tes3.getPlayerEyeVector() * 2000
end end		--event.register("enterFrame", enterFrame)

--L.Dash = function(e) mp.velocity = V.d		V.dfr = V.dfr - TSK		if V.dfr < 0 then event.unregister("simulate", L.Dash)	V.dfr = nil end end
L.Dash = function(e) if e.reference == p then	if V.djf then	mp.isJumping = true end			mp.impulseVelocity = V.d*(TSK/wc.deltaTime)	V.dfr = V.dfr - TSK		--mp.impulseVelocity = V.d*60		V.dfr = V.dfr - wc.deltaTime*60
if V.dfr <= 0 then event.unregister("calcMoveSpeed", L.Dash)	V.dfr = nil
	if V.djf then V.djf = nil	mp.isJumping = false end
	if V.daf then mp.animationController.weaponSpeed = V.daf	V.daf = nil end
	if V.dkik then V.dkik = nil		L.KIK() end
end
end end

L.BLAST = function(e)	local r = e.reference	if KSR[r] then e.mobile.impulseVelocity = KSR[r].v*(TSK/wc.deltaTime) * math.clamp(KSR[r].f/30,0.2,1)	KSR[r].f = KSR[r].f - TSK	e.speed = 0 --KSR[r].v.z = KSR[r].v.z - 0.04
if KSR[r].f <= 0 then KSR[r] = nil 	if table.size(KSR) == 0 then event.unregister("calcMoveSpeed", L.BLAST)		V.bcd = nil end end end end

L.KIK = function() if mp.hasFreeAction and mp.paralyze < 1 then	local climb, foot, r, m		local dist = 1000	local maxd = 50 + math.min(mp.agility.current/2, 50)
local ClAb = mp.velocity:length()~=0 and not V.dfr		local cldist = maxd + (P.acr9 and 20 or 0)		local kikdist = maxd + (P.hand11 and 20 or 0)

local vdir = tes3.getPlayerEyeVector()		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vdir, maxDistance = 130, ignore={p}}
if hit then dist = hit.distance 	r = hit.reference	m = N[r] and N[r].m		maxd = m and kikdist or (ClAb and cldist) or 0 end

if dist > maxd then foot = true
	hit = tes3.rayTest{position = pp + tes3vector3.new(0,0,5), direction = p.forwardDirection, maxDistance = 130, ignore={p}}	--tes3.messageBox("ref = %s", hit and hit.reference)
	if hit then dist = hit.distance 	r = hit.reference	m = N[r] and N[r].m		maxd = m and kikdist or cldist end
	if dist > maxd then hit = mp.isMovingLeft and 1 or (mp.isMovingRight and -1)		if hit then vdir = p.rightDirection * hit
		hit = tes3.rayTest{position = pp + tes3vector3.new(0,0,5), direction = vdir, maxDistance = 150, ignore={p}}
		if hit then dist = hit.distance 	r = hit.reference	m = N[r] and N[r].m		maxd = m and kikdist or cldist end
	end end
end

if dist > maxd then maxd = kikdist	local md = kikdist + 10
	for _, mob in pairs(tes3.findActorsInProximity{reference = p, range = 150}) do
	if mob ~= mp and mob.playerDistance < md and math.abs(mp:getViewToActor(mob)) < (P.hand21 and 100 or 45) and (cf.agr or mob.actionData.target == mp) then md = mob.playerDistance		m = mob end end
	if m then dist = md		r = m.reference		vdir = (r.position - pp):normalized() end
end
	

if dist <= maxd then
if ClAb then	local s = mp:getSkillValue(20)		local stc = math.max(20 + mp.encumbrance.normalized*(P.atl6 and (30 - mp:getSkillValue(8)/10) or 30) - (P.acr11 and s/10 or 0), 10)
	if mp.fatigue.current > stc then local ang = 0
		if mp.isMovingForward then if foot then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end else V.d = V.up end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 else V.d = V.up end
		if V.d ~= V.up then Matr:toRotationZ(math.rad(ang))		V.d = Matr * tes3.getPlayerEyeVector()
			if mp.isMovingBack then V.d = V.d*-1 elseif ang == 90 or ang == 270 then V.d.x = V.d.x/(1 - V.d.z^2)^0.5		V.d.y = V.d.y/(1 - V.d.z^2)^0.5 end		V.d.z = 1
		end
		local imp = math.min(100 + mp.strength.current/2 + s/2, 200) * (P.acr12 and 1 or 0.75) * (0.5 + math.min(mp.fatigue.normalized,1)/2)		if P.acr10 then mp.velocity = V.nul end		mp.isSwimming = false
		V.d = V.d * (imp/8)		V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		mp.fatigue.current = mp.fatigue.current - stc
		if wc.systemTime - L.jumptim > 2000 then mp:exerciseSkill(20,0.2)	L.jumptim = wc.systemTime  end
		climb = true	tes3.playSound{sound = math.random(2) == 1 and "LeftS" or "LeftM"}
		if cf.m then tes3.messageBox("Climb-jump! impuls = %d  dist = %d   cost = %d", imp, dist, stc) end
	end
end
if not T.Kik.timeLeft and m then	local s = mp:getSkillValue(26)		local bot = math.min(mp:getBootsWeight(), 30)
	local sc = math.max(30 + (bot + mp.encumbrance.normalized*20)*(P.atl6 and (1 - mp:getSkillValue(8)/200) or 1) - (P.end6 and 10 or 0) - (P.hand14 and s/10 or 0), 10) - (climb and 10 or 0)
	if mp.fatigue.current > sc then	local arm = m.armorRating		local fat = 1 - math.min(mp.fatigue.normalized,1)
		local cd = math.max((P.spd12 and 1.5 or 2) - mp.speed.current/100 + math.max(D.AR.as + mp.encumbrance.normalized * (P.atl12 and 0.1 or 0.2) - math.max(-mp.encumbrance.currentRaw,0)/2000, 0)*2
		+ fat * (P.atl11 and 0.2 or 0.5), (P.hand15 and 0.5 or 1))
		T.Kik = timer.start{duration = cd, callback = function() end}
		local Kskill = s * ((P.hand1 and 0.2 or 0.1) + (P.str2 and 0.1 or 0.05))	local Kbonus = mp.attackBonus/5		local Kstr = mp.strength.current*(P.str1 and 0.5 or 0.3)
		local Kdash = (T.Dash.timeLeft or 0) > 2 and V.dd/(P.str9 and 50 or 100) or 0		local ko = L.AG[m.actionData.currentAnimationGroup]
		local Kstam = math.min(math.lerp((P.end1 and 0.4 or 0.3) + (P.hand2 and 0.1 or 0), 1, mp.fatigue.normalized*1.1), 1)
		local CritC = Kbonus + s/(P.hand6 and 10 or 20) + mp.agility.current/(P.agi1 and 10 or 20) + (P.luc1 and mp.luck.current/20 or 0) + (mp.isMovingForward and P.spd3 and 10 or 0) + (m.isMovingForward and 10 or 0)
		+ (math.min(com, G.maxcomb) * (P.agi6 and 5 or 3)) + (mp.isJumping and P.acr4 and mp:getSkillValue(20)/10 or 0)
		- (m.endurance.current + m.agility.current + m.luck.current)/20 - arm/10 - m.sanctuary/10 + math.max(1-m.fatigue.normalized,0)*(P.agi11 and 20 or 10) - 10
		local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + (P.agi8 and 10 or 0) + (P.hand5 and 20 or 0) end
		local Koef = (100 + Kstr + Kskill + Kdash + Kbonus) * Kstam * (100 + Kcrit)/10000
		local Kin = P.alt25 and math.min(mp.willpower.current/10 + mp:getSkillValue(0)/5, cf.moment) or 0		local mc = 0
		if Kin > 0 then mc = Kin/(P.alt17 and 3 or 2)		if mp.magicka.current > mc then Mod(mc) 	Kin = Kin * (Cpow(mp,0,0,true) + (P.alt16 and 50 or 0))/200		else Kin = 0	mc = 0 end end
		local dmg = (((P.hand19 and 5 or 2) + (P.hand13 and bot/5 or 0)) * Koef + Kin) * (ko and 1.5 + (P.str14 and 0.5 or 0) or 1)	--local fdmg = dmg*dmg/(arm + dmg)
		local mass = math.max(m.height^2, 5000) * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + arm/2)/5000
		local pow = math.min(((100 + Kstr*4 + Kdash*5) * Kstam + Kin*20 - m.endurance.current/2) * 300/mass, 3000)		local jump
		if pow > 50 then
			vdir.z = m.isFalling and math.clamp(vdir.z, climb and -1 or 0.3, 1) or math.clamp(vdir.z, climb and 0.15 or 0.3, 0.75)
			jump = m:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
			if not jump then	local min = 1000 + math.min(vdir.z, 0)*500
				if pow > min then	local hit2 = tes3.rayTest{position = r.position + tes3vector3.new(0, 0, m.height/2) - vdir*30, direction = vdir, ignore={tes3.game.worldPickRoot}}
					if hit2 and hit2.reference then pow = math.clamp(hit2.distance, min, pow) end
				end
				tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
				KSR[r] = {v = vdir * pow/10, f = 30}		if not V.bcd then event.register("calcMoveSpeed", L.BLAST)	V.bcd = 0 end
			end
		end
		local sdmg = (P.hand16 and 10 or 5) * Koef		if not ko and m.fatigue.current > 0 then m.fatigue.current = m.fatigue.current - sdmg end
		local fdmg = m:applyDamage{damage = dmg, applyArmor = true, resistAttribute = 12, playerAttack = true}	L.CrimeAt(m)
		if T.Comb.timeLeft then T.Comb:reset() end		mp.fatigue.current = mp.fatigue.current - sc
		L.skw = math.max((m.object.level * 4 + 20 - p.object.level/2) / (m.object.level + 20) * (fdmg+sdmg)/30, 0)		mp:exerciseSkill(26, 1)
		if cf.m30 then tes3.messageBox([[Kick dmg = %d (%d / %d arm) + %d stam  K = %d%% (+%d%% str +%d%% skill +%d%% atb +%d%% dash) *%d%% stam +%d%% crit (%d%%) +%.1f kin) 
		impuls = %d  mass = %d  dist = %d  cd = %.1f  cost = %d + %d  %s   Z = %.2f  %s]],
		fdmg, dmg, arm, sdmg, Koef*100, Kstr, Kskill, Kbonus, Kdash, Kstam*100, Kcrit, CritC, Kin, pow, mass, dist, cd, sc, mc, ko and "KO!" or "", vdir.z, jump and "" or "MOVE") end
	end
end
end
end end


L.KBlast = function(pos, rad, dam) local dist, r, mass, pow, KO, dmg, vdir, rp, jump, Z, dif		--local maxpow = p.cell.isInterior and not p.cell.behavesAsExterior and 8000 or 15000
for _, m in pairs(tes3.findActorsInProximity{position = pos, range = rad}) do if m ~= mp then r = m.reference	rp = (r.position + tes3vector3.new(0, 0, m.height*0.7))		dist = pos:distance(rp)		dif = rad - dist	if dif > 0 then
	mass = math.max(m.height^2, 5000) * ((m.actorType == 1 or m.object.biped) and 0.5 or 0.8) * (100 + m.armorRating/2)/5000		
	pow = math.min(dif * 100/mass, 4000)		KO = pow/10 - m.agility.current - 50
	if pow > 50 then	vdir = (rp - pos):normalized()		Z = vdir.z		
		vdir.z = m.isFalling and math.clamp(Z, -0.75, 0.75) or math.clamp(Z, 0.3, 0.75)
		jump = m:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
		if not jump then	local min = 1000 + math.min(vdir.z, 0)*500
			if pow > min then local hit = tes3.rayTest{position = rp - vdir*30, direction = vdir, ignore={tes3.game.worldPickRoot}}		if hit and hit.reference then pow = math.clamp(hit.distance, min, pow) end end
			tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
			KSR[r] = {v = vdir * pow/10, f = (KSR[r] and KSR[r].f/2 or 0) + 30}		if not V.bcd then event.register("calcMoveSpeed", L.BLAST)	V.bcd = 0 end
		end
		if KO > math.random(100) then tes3.applyMagicSource{reference = r, name = "KO", effects = {{id = 20, min = 3000, max = 3000, duration = 1}}} end
	end
	if dam then dmg = m:applyDamage{damage = dam * (dif/rad)^3, applyArmor = true, playerAttack = true}	L.CrimeAt(m) end
	if cf.m then tes3.messageBox("%s %s  Impuls = %d (%d - %d) Mass = %d  Dmg = %d/%d  KO = %d%%  Z = %.2f -> %.2f",
	jump and "JUMP!" or "MOVE!", r.object.name, pow, rad, dist, mass, dmg or 0, dam or 0, KO, Z or 0, vdir and vdir.z or 0) end
	--m.actionData.animationAttackState = 15
end end end
end

local function KSCollision(e)
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local koef = Cpow(mp,0,2)/100 * (SN[e.sourceInstance.serialNumber] or 1)	local magn = math.random(ef.min, ef.max)
local rad = (10 + L.GetRad(mp)) * math.min(5 * magn^0.5, magn) * koef
local dam = magn * koef
L.KBlast(e.collision.point, rad, dam)
end

L.runTeleport = function(pos)	local TPdist = pp:distance(pos)		local TPmdist = (100 + mp.intelligence.current + mp:getSkillValue(11) + mp:getSkillValue(14)) * 20		if TPdist > 200 then
	if TPdist > TPmdist then  pos = pp:interpolate(pos, TPmdist)		TPdist = TPmdist end	mc = (20 + TPdist/50) * (P.mys7a and 1 or 1.5)
	if mc < mp.magicka.current then 
		Mod(mc)		tes3.playSound{sound = "Spell Failure Destruction"}		p.position = pos	--mp.isSwimming = true	--tes3.positionCell{reference = p, position = pos, cell = p.cell}		
		tes3.applyMagicSource{reference = p, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
		if cf.m then tes3.messageBox("Distance = %d  Manacost = %.1f", TPdist, mc) end
	end
end end
local function TeleportCollision(e) if e.sourceInstance.caster == p then L.runTeleport(e.collision.point - e.sourceInstance.projectile.velocity:normalized()*70) end end


local function SPELLMAGICKAUSE(e) 	local sp = e.spell		local cost = sp.magickaCost		if e.caster == p then	local sc = sp:getLeastProficientSchool(mp)
	if not sp.alwaysSucceeds then
		G.MCKoef = math.max((G.LastQS == sp and not P.int11 and 1.2 or 1)
		- mp.intelligence.current/(P.int1 and 1000 or 2000)
		- mp:getSkillValue(SP[sc].s)/(P[SP[sc].p4] and 1000 or 2000)
		- (P.mys10 and 0.05 or 0)
		+ (D.AR.mc > 0 and math.max(D.AR.mc - math.max(-mp.encumbrance.currentRaw,0)/2000, 0) or D.AR.mc), 0.5)
		
		e.cost = cost * G.MCKoef
		--if G.LastQS == sp then G.LastQsn = e.instance.serialNumber end
		--tes3.messageBox("%s  Cost = %s (%s base)  School = %s", sp.name, e.cost, sp.magickaCost, sc)
	end
	
	mp.animationController.animationData.castSpeed = 2/(1 + cost*3/(cost+100)) * math.min(1 + mp.speed.current * ((P[SP[sc].ps] and 0.006 or 0.003) + (P.spd30 and 0.004 or 0)), 2)
	--tes3.messageBox("%s    speed = %s   sc = %s", sp.name, mp.animationController.animationData.castSpeed, sc)

	if mp.magicka.current < e.cost then G.LastQS = nil end
else local mob = e.caster.mobile
	if sp.castType == 5 then
		mob.animationController.animationData.castSpeed = 0.8
		--tes3.messageBox("%s     smc = %d", sp.name, e.cost)
	else
		if mob.magicka.current < cost then e.cost = math.max(mob.magicka.current-1, -1) end
		mob.animationController.animationData.castSpeed = 2/(1 + cost*3/(cost+100)) * math.min(1 + mob.speed.current/100, 2)			--attempt to index field 'animationController' (a nil value)
	--	tes3.messageBox("%s   time = %s   smc = %d/%d", sp.name, 0.5 + cost*3/(cost+100), e.cost, mob.magicka.current)
	end
end end		event.register("spellMagickaUse", SPELLMAGICKAUSE)

local function SPELLCAST(e)	local sp = e.source		local c = e.caster		if sp.castType == 0 or sp.castType == 5 then	if c == p then	local extra = 0		local cost = sp.magickaCost		local sc = e.weakestSchool
if G.LastQS == sp then ad.animationAttackState = 0
	--if mp.weaponDrawn then L.WComb(ad.attackDirection, not mp.readiedWeapon and 0 or mp.readiedWeapon.object.isOneHanded) end
	--if ad.animationAttackState == 2 then ad.animationAttackState = 0 	MB[1] = 0 end
	if not P.int2 then extra = cost end		for i, ef in ipairs(sp.effects) do if ef.id ~= -1 then tes3.removeSound{sound = ef.object.castSoundEffect, reference = p} end end
else
--	if P.spd6 then if mp.speed.current > 99 then 
--		if ad.animationAttackState == 11 then if ic:keybindTest(tes3.keybind.readyMagic) then timer.start{duration = 0.1, callback = function() ad.animationAttackState = 0 end} else ad.animationAttackState = 0 end end
--	else timer.start{duration = math.clamp((100 - mp.speed.current)/100, 0.01, 0.99), callback = function()
--		if ad.animationAttackState == 11 then if ic:keybindTest(tes3.keybind.readyMagic) then timer.start{duration = 0.1, callback = function() ad.animationAttackState = 0 end} else ad.animationAttackState = 0 end end
--	end} end end
end
if sc < 6 then local s = mp:getSkillValue(SP[sc].s)
	local stam = math.min(cost * (G.MCKoef or 1) * math.min((P.end16 and 0.25 or 0) + (P.una9 and D.AR.u * 0.01 or 0), 0.5), mp.fatigue.base - mp.fatigue.current)
	if stam > 0 then mp.fatigue.current = mp.fatigue.current + stam end
	e.castChance = e.castChance + (P[SP[sc].p2] and s/5 or 0) + (P.int6 and mp.intelligence.current/10 or 0) + (P.luc13 and mp.luck.current/10 or 0) + (P.int8 and mp.spellReadied and (mp.intelligence.current + s)/10 or 0)
	+ (D.AR.cc > 0 and D.AR.cc or math.min(D.AR.cc + math.max(-mp.encumbrance.currentRaw,0)/1000, 0)) - mp.encumbrance.normalized * (P.end17 and 10 or 20) - (P.wil10 and 0 or M.MCB.normalized*20) - extra
	if cf.m10 then tes3.messageBox("Spellcast! School = %s  chance = %.1f   stam + %.1f", sc, e.castChance, stam) end
end		
--elseif (c.mobile.actorType == 1 or c.object.biped) then c.mobile.actionData.animationAttackState = 0		--tes3.messageBox("Spellcast! %s  %s", e.castChance, e.source.name)
end end end		event.register("spellCast", SPELLCAST)


--[[local function SPELLCASTED(e) if e.caster == p and e.expGainSchool < 6 then
	local sc = e.expGainSchool		tes3.messageBox("CAST! School = %s   cost = %s", sc, e.source.magickaCost)
end end		event.register("spellCasted", SPELLCASTED)	--]]
local function SPELLCASTEDFAILURE(e) if e.caster == p and e.expGainSchool < 6 then M.MCB.current = 0	G.LastQS = nil
	if P.int7 then tes3.modStatistic{reference = p, name = "magicka", current = e.source.magickaCost * math.min((mp.intelligence.current + mp:getSkillValue(SP[e.expGainSchool].s))/500,0.5)} end
--else tes3.messageBox("Fail  %s    %s", e.caster, e.source.name)
end end		event.register("spellCastedFailure", SPELLCASTEDFAILURE)


local function ENCHANTCHARGEUSE(e)	if e.isCast and e.caster == p then	local en = e.source		local ct = en.castType		local cost = en.chargeCost	local newcost		L.skmag = cost * 5 / (cost + 80)
	if ct == 1 then
		if e.item.type < 11 then newcost = D.NoEnStrike and 90000 or
		cost * (math.max(1 - mp:getSkillValue(9)*((P.enc8 and 0.002 or 0.001) + (P.enc19 and 0.001 or 0)), 0.7) + (G.TR.tr7 and (D.poison and 1 or -0.2) or 0)) end
	else
		if T.EnCD.timeLeft then newcost = 90000
		elseif ct == 2 then local skill = mp:getSkillValue(9)
			T.EnCD = timer.start{duration = 3 - math.min((skill + mp.speed.current)/100, 2) - (P.enc11 and 0.5 or 0), callback = function() end}
			newcost = cost * (math.max(1 - skill*(P.enc8 and 0.002 or 0.001), 0.8) + M.MCB.normalized*(P.enc20 and 0.4 or 0.2)*(P.enc21 and 0.5 or 1))
		end
	end
	
	if newcost then e.charge = newcost		if e.itemData.charge >= newcost then	local PCcost = newcost * (P.enc2 and 0.75 or 1)		local MCost = 0
		if M.PC.current + mp.magicka.current > PCcost then
			if PCcost > M.PC.current then MCost = PCcost - M.PC.current		M.PC.current = 0 else M.PC.current = M.PC.current - PCcost end
			M.Bar4.visible = true	D.PCcur = M.PC.current		if not T.PCT.timeLeft then T.PCT:reset() end
			if MCost > 0 then Mod(MCost) end
		else e.charge = 90000 end
		
		if cf.m10 then tes3.messageBox("En cast! %s  Cost = %.1f (%d base)  PCcost = %.1f   Manacost = %.1f", en.id, e.charge, cost, PCcost, MCost) end
	end end
end end		event.register("enchantChargeUse", ENCHANTCHARGEUSE)


L.RaySim = function() if L.KEY(G.ck) and mp.magicka.current > G.rayc then	G.raysim = G.raysim + wc.deltaTime
	if G.raysim > G.raydt then G.raysim = G.raysim - G.raydt	tes3.applyMagicSource{reference = p, source = B.RAY}		Mod(MB[cf.mbray] == 128 ~= cf.ray and G.rayc or G.sprc) end
else event.unregister("simulate", L.RaySim)	G.raysim = nil end end


local function MAGICCASTED(e) if e.caster == p then	local s = e.source	local si = e.sourceInstance		local sn = si.serialNumber
--	if not s.effects then mwse.log("NO EFFECTS!!! source id = %s   name = %s    sn = %s", s.id, s.name, sn) end
local id1 = s.effects[1].id		local cost	local n = s.name	local MC = M.MCB.normalized			--attempt to index field 'effects' (a nil value)
local KF = 1		local ct = s.castType
local Focus = P.wil5 and mp.spellReadied and mp.magicka.current/(100 + mp.magicka.current/10)/100 or 0
if s.effects[1].rangeType == 2 and not MP[si] then
	if P.alt18 and MB[cf.mbhev] == 128 and n ~= "4b_RAY" then V.BAL[sn] = 1 + MC		KF = KF + 0.05
	elseif DM.cp == 3 and (P.mys18 and T.MCT.timeLeft or tes3.isAffectedBy{reference = p, effect = 506}) and mp.magicka.current > 10 and id1 ~= 610 then
		if n == "4b_RAY" then	if cf.raycon then MP[si] = {pos = L.Hitp(0)}		Mod(P.mys7 and 2 or 4) end
		else MP[si] = {pos = L.Hitp(0)}		Mod(P.mys7 and 4 or 8) end
	end
end

if s.objectType == tes3.objectType.spell and ct == 0 then cost = s.magickaCost		local mc = 0	KF = KF + Focus
	local Kstam = math.min(math.lerp((P.wil2 and 0.4 or 0.3) + (P[SP[s:getLeastProficientSchool(mp)].p3] and 0.1 or 0), 1, mp.fatigue.normalized*1.1), 1)
	local char = MC*(P.wil7 and 0.2 or 0.1)		if char > 0 then mc = cost * char * (P.int14 and 0.5 or 1)		if mp.magicka.current > mc then Mod(mc) else char = 0 end end
	if G.LastQS == s then KF = KF + (P.int13 and char or 0)		G.LastQS = nil		--if ad.animationAttackState == 2 then ad.animationAttackState = 0 end
	elseif char > 0 then KF = KF + char end
	M.MCB.current = 0		KF = KF * Kstam			L.skmag = cost * 5 / (cost + 80)
	if cf.m10 then tes3.messageBox("%s  Spell power = %d%%   %d%% stam   Charge = %d%% (%.1f cost)", n, KF*100, Kstam*100, char*100, mc) end
elseif s.objectType == tes3.objectType.enchantment and ct < 3 then cost = s.chargeCost		KF = KF + Focus
	local Kstam = math.min(math.lerp((P.wil2 and 0.4 or 0.3) + (P.enc5 and 0.1 or 0), 1, mp.fatigue.normalized*1.1), 1)
	if (ct == 1 and si.item.type < 11) or ct == 2 then		G.REI = {}
		if MC > 0 then KF = KF + MC*(P.enc20 and 0.2 or 0.1)	M.MCB.current = 0 end
		if P.enc10 then KF = KF + M.PC.normalized/10 end
		
		KF = KF * Kstam
		if cf.m10 then tes3.messageBox("%s  Enc power = %d%%  %d%% stam", s.id, KF*100, Kstam*100) end
	elseif ct == 0 then KF = (KF + (P.enc17 and 0.1 or 0) + (P.enc10 and M.PC.normalized/10 or 0)) * Kstam
		if cf.m10 then tes3.messageBox("%s  Scroll power = %d%%  %d%% stam", s.id, KF*100, Kstam*100) end
	end
elseif n == "4b_RAY" then	KF = KF + Focus		if T.MCT.timeLeft then KF = KF + MC*(P.wil7 and 0.2 or 0.1)		M.MCB.current = math.max(M.MCB.current - (P.mys19 and 0.5 or 1), 0) end
end
if KF ~= 1 then SN[sn] = KF end

if ME[id1] == "shotgun" then	local E = B.SG.effects		local num = (P.alt6 and 4 or 3) + math.min(math.floor(mp:getSkillValue(11)/200 + mp.intelligence.current/200), 1)
	if P.alt18 and MB[cf.mbhev] == 128 then KF = KF * 1.05		G.SGMod = 5
	elseif (DM.cp == 3 or DM.cp == 4 or DM.cp == 12) and (P.mys18 and T.MCT.timeLeft or tes3.isAffectedBy{reference = p, effect = 506}) and mp.magicka.current > 16 then
		if DM.cp == 3 then Mod(P.mys7 and 5 or 10)	G.SGMod = 3
		elseif DM.cp == 4 then if P.mys8a and MB[cf.mbret] == 128 then Mod(P.mys7 and 8 or 16)	G.SGmintp = true else Mod(P.mys7 and 6 or 12) G.SGmintp = nil end		G.SGMod = 4
		elseif DM.cp == 12 then Mod(P.mys7 and 3 or 6)		G.SGMod = 12 end
	else G.SGMod = nil end

	for i, ef in ipairs(s.effects) do if ME[ef.id] == "shotgun" then E[i].id = MID[ef.id%5]	E[i].min = ef.min*KF	E[i].max = ef.max*KF		E[i].radius = ef.radius		E[i].duration = ef.duration		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	G.ShotGunDiv = 1 - math.min(mp.agility.current + mp:getSkillValue(23),200)/(P.mark11 and 300 or 400)
	local v1 = p.forwardDirection * 16		local v2 = p.rightDirection * 16		local pos1 = pp + tes3vector3.new(0,0,mp.height/2)
	local d4, d5		if num == 5 then d4, d5 = true, true elseif num == 4 then d4 = table.choice{true,false}		d5 = not d4 end
	MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1, vel = L.GetSGVec(-20,20)} or {pos = L.Hitpr(pos1, L.GetSGVec(-20,20),0)}
	MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 + v1 + v2, vel = L.GetSGVec(20,60)} or {pos = L.Hitpr(pos1 + v1 + v2, L.GetSGVec(20,60),0)}
	MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 + v1 - v2, vel = L.GetSGVec(-60,-20)} or {pos = L.Hitpr(pos1 + v1 - v2, L.GetSGVec(-60,-20),0)}
	if d4 then MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 - v1 + v2, vel = L.GetSGVec(60,120)} or {pos = L.Hitpr(pos1 - v1 + v2, L.GetSGVec(60,120),0)} end
	if d5 then MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 - v1 - v2, vel = L.GetSGVec(-120,-60)} or {pos = L.Hitpr(pos1 - v1 - v2, L.GetSGVec(-120,-60),0)} end
	if cf.m10 then tes3.messageBox("Shotgun cast! %s   Koef = %.2f  Balls = %d  Div = %d%%   Mode = %s", n or s.id, KF, num, G.ShotGunDiv*100, G.SGMod or 0) end
elseif ME[id1] == "ray" and not s.weight then	G.rayc = cost * (P.mys7b and 0.1 or 0.12) 	G.sprc = cost * (P.mys7b and 0.075 or 0.09)
	local k = math.min(KF, 1)		local E = B.RAY.effects		local num = (P.alt7 and 20 or 15) + math.min(math.floor(mp:getSkillValue(11)/20 + mp.intelligence.current/20), 10)
	for i, ef in ipairs(s.effects) do if ME[ef.id] == "ray" then E[i].id = MID[ef.id%5]		E[i].min = ef.min*k		E[i].max = ef.max*k		E[i].radius = ef.radius		E[i].duration = ef.duration		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	if not G.raysim then	--mp.animationController.animationData.castSpeed = 0
	event.register("simulate", L.RaySim)		G.raydt = 1/num		G.raysim = G.raydt end
	if cf.m10 then tes3.messageBox("Ray cast! %s   Koef = %.2f   Cost = %.2f / %.2f  Balls = %d", n or s.id, k, G.rayc, G.sprc, num) end
elseif ME[id1] == "discharge" then	local E = B.DC.effects		local rad = L.GetRad(mp)/2		-- Разряд. Эффекты 541, 542, 543, 544, 545
	for i, ef in ipairs(s.effects) do if ME[ef.id] == "discharge" then E[i].id = MID[ef.id%5]	E[i].min = ef.min*KF	E[i].max = ef.max*KF	E[i].radius = rad+ef.radius		E[i].duration =	ef.duration		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.DC}] = {pos = pp + tes3vector3.new(0,0,10), exp = true}
--elseif ME[id1] == "wave" then
end
end end		event.register("magicCasted", MAGICCASTED)





L.HitCP = function()
	if not G.hit then if MB[cf.mbret] == 128 then G.hit = G.pep + G.pev * 150 	G.prbase = true else
		local hit = tes3.rayTest{position = G.pep, direction = G.pev, ignore = {p}}	
		if hit then
			local r = hit.reference		G.hit = hit.intersection + G.pev * (N[r] and r.mobile.boundSize2D.x/2 or 30)
		else G.hit = G.pep + G.pev * 4800 end
		G.prbase = nil
	end end
	return G.hit
end
L.PrLive = function() if not G.PrL then G.PrL = (mp.fatigue.normalized*4 + (mp.willpower.current + mp:getSkillValue(14) + mp:getSkillValue(11))/50) * (P.mys80 and 2 or 1) end		return G.PrL end

--	Велосити заменяет естественную скорость, а импульс складывается с ней		r.sceneNode.velocity - разовое изменение скорости для этого фрейма
--Режимы: 0 = простой на цель, 1 = умный на цель, 2 = самонаведение, 4 = мины, 5 = баллистический, 6 = броски оружия, 7 - магические шары врагов, 8 - спрей, 9 - волна, 10 = стрелы игрока, 11 - стрелы контроль
local function SimulateCP(e)	G.dt = wc.deltaTime		G.pep = tes3.getPlayerEyePosition()		G.pev = tes3.getPlayerEyeVector()	G.hit = nil		G.PrL = nil		--G.cpfr = G.cpfr + 1	
	for r, t in pairs(CPR) do if t.tim then	--t.tim = t.tim - G.dt
		if t.tim < t.m.animTime then CPR[r] = nil
		elseif t.mod == 1 then t.m.velocity = (L.HitCP() - t.p):normalized() * (G.prbase and t.p:distance(G.hit) < 100 and 50 or t.spd)
			Matr:lookAt(G.prbase and G.pev or t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
			
		--	t.dist = t.p:distance(L.HitCP())
		--	if G.prbase then t.m.velocity = (G.hit - t.p):normalized() * (t.dist < 100 and 50 or t.spd)
		--	elseif t.dist > 100 then t.m.velocity = (G.hit - t.p):normalized() * t.spd end
		

		--	t.m.velocity = t.m.velocity * (1 - G.dt*2) + (L.HitCP() - r.position):normalized() * 6000 * G.dt
		elseif t.mod == 11 then
			if not t.mus or t.m.animTime > 0.5 then --t.m.velocity = G.pev*t.spd
				--t.m.velocity = t.m.velocity + G.pev * 2000 * G.dt - t.m.velocity:normalized() * 1000 * G.dt 
				--t.m.velocity = t.m.velocity + (L.HitCP() - r.position):normalized() * 4000 * G.dt - t.m.velocity:normalized() * 3000 * G.dt 
			--	t.m.velocity = t.m.velocity * (1 - G.dt*2) + (L.HitCP() - r.position):normalized() * 6000 * G.dt
			--	t.m.velocity = t.m.velocity:normalized():lerp((L.HitCP() - r.position):normalized(), G.dt*10) * t.spd
				
				t.spd = math.max(t.spd - (G.prbase and 2000 or 1000) * G.dt, 2500)
				t.m.velocity = (L.HitCP() - r.position):normalized() * (G.prbase and r.position:distance(G.hit) < 100 and 50 or t.spd)
				Matr:lookAt(G.prbase and G.pev or t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
				--if G.cpfr == 30 then G.cpfr = 0 end
			end
		elseif t.mod == 12 then
			if t.tp then	t.dist = t.p:distance(t.tp)
				if t.dist < 100 + t.spd/30 then t.tp = nil		t.m.velocity = t.m.velocity - (t.norm * t.m.velocity:dot(t.norm) * 2)
					Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()			--tes3.messageBox("dist = %d    vel = %d", t.dist, t.spd)
				end
			else
				local hit = tes3.rayTest{position = t.p, direction = t.m.velocity, returnNormal = true, ignore = {tes3.game.worldPickRoot}}
				if hit then t.tp = hit.intersection:copy()	t.norm = hit.normal:copy() else CPR[r] = nil end
			end
		elseif t.mod == 2 then t.m.velocity = t.m.velocity * (1 - G.dt*2) + (t.tar.position + t.hv - r.position):normalized() * t.spd * G.dt
			Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
		elseif t.mod == 4 then t.m.position = t.pos		t.m.velocity = t.v*50 end		--tes3vector3.new(50,50,50)
	--	tes3.messageBox("Anim = %.2f  Sw = %.2f  Dam = %.2f        InSpd = %.2f   V = %d   Pdist = %d", t.m.animTime, t.m.attackSwing, t.m.damage, t.m.initialSpeed, t.m.velocity:length(), t.m.playerDistance)
	else
		if t.mod == 10 then	t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-2000 * G.dt)
			Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
		elseif t.mod == 7 then
			if t.liv < t.m.animTime then CPR[r] = nil else t.v = G.pep - r.position
				if t.v:length() < G.spdodge then CPR[r] = nil else t.m.velocity = t.m.velocity * (1 - G.dt*2) + t.v:normalized() * t.spd * G.dt
					Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
				end
			end
		elseif t.mod == 5 then t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-2000 / t.pow * G.dt) + (t.con and G.pev*1000*G.dt or tes3vector3.new(0,0,0))
			Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
		elseif t.mod == 6 then
		--	t.m.velocity = t.con and t.m.velocity * (1 - G.dt*2) + (L.HitCP() - r.position):normalized() * 6000 * G.dt or t.m.velocity + tes3vector3.new(0,0,-2000 * G.dt)
			if V.METR[t.r] then
				if t.con then t.spd = math.max(t.spd - (G.prbase and 2000 or 1000) * G.dt, 2500)
					t.m.velocity = (L.HitCP() - r.position):normalized() * (G.prbase and r.position:distance(G.hit) < 100 and 50 or t.spd)
				--	t.r.orientation = p.orientation
					Matr:lookAt(G.prbase and G.pev or t.m.velocity, V.up)		t.r.orientation = Matr:toEulerXYZ()
				else t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-2000 * G.dt)		Matr:lookAt(t.m.velocity, V.up)		t.r.orientation = Matr:toEulerXYZ() end
				t.r.position = r.position:copy()
			else t.si.state = 6 end
		elseif t.mod == 9 then
			if t.m.animTime > 0.3*t.num then
				for i, ef in ipairs(t.ef) do if ME[ef.id] == "wave" then G.WAV[i].id = MID[ef.id%5]		G.WAV[i].min = ef.min*t.k*(1-(t.num-1)/t.max)		G.WAV[i].max = ef.max*t.k*(1-(t.num-1)/t.max)
				G.WAV[i].radius = ef.radius + t.num/(P.alt12 and 1 or 2)		G.WAV[i].duration = ef.duration		G.WAV[i].rangeType = 2	else G.WAV[i].id = -1	G.WAV[i].rangeType = 0 end end			
				MP[tes3.applyMagicSource{reference = p, source = B.WAV}] = {pos = r.position:copy(), exp = true}
				if t.num >= t.max then t.m.expire = 1	CPR[r] = nil else t.num = t.num + 1 end
			end
		elseif t.mod == 8 then	if t.liv < t.m.animTime then t.m.expire = 1		CPR[r] = nil end end
	--	if t.m then tes3.messageBox("Anim = %.2f   Sw = %.2f  Dam = %.2f  InSpd = %.2f   V = %d", t.m.animTime, t.m.attackSwing, t.m.damage, t.m.initialSpeed, t.m.velocity:length()) end
	end end		if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	G.cpfr = nil end
end

local function SimulateCPS(e)	G.dt = wc.deltaTime		G.cpg = G.cpg + 4*G.dt
	for r, t in pairs(CPRS) do CPS[t.n] = CPS[t.n] - G.dt
		if CPS[t.n] < 0 then CPS[t.n] = 0	CPRS[r] = nil	else r.position = {pp.x + math.cos(G.cpg + t.n*math.pi/5) * t.rad, pp.y + math.sin(G.cpg + t.n*math.pi/5) * t.rad, pp.z + 100} end
	end		if table.size(CPRS) == 0 then event.unregister("simulate", SimulateCPS)		G.cpscd = nil	G.cpg = 0 end
end

local function MOBILEACTIVATED(e) local m = e.mobile	local r = e.reference	if m then local firm = m.firingMobile	if firm then	local si = m.spellInstance		local prob = not si and r.object
if firm == mp then	local ss = si and si.source		local n = ss and ss.name	local cont, ray, inspd, spd			--m.movementCollision = false
	--m.velocity = m.velocity:normalized() * 500		--r.scale = 0.5
	if si then local t = MP[si]		local sn = si.serialNumber		 inspd = m.initialSpeed		spd = inspd * (1 + math.min(mp.willpower.current + mp:getSkillValue(11),200)/(P.alt27 and 400 or 1000))
		if t then CPR[r] = {}
			if CPR[r] then r.position = t.pos	if t.exp then m:explode() elseif t.vel then m.velocity = t.vel * spd end		MP[si] = nil end

			if n == "4b_SG" then	if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.4, callback = function() end}  	L.SectorDod() end		if G.SGMod then
				if G.SGMod == 5 and t.vel then
					CPR[r] = {mod = 5, m = m, pow = 2}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				elseif G.SGMod == 4 then	--local live = (mp.fatigue.normalized*4 + (mp.willpower.current + mp:getSkillValue(14) + mp:getSkillValue(11))/50) * (P.mys80 and 2 or 1)
					CPR[r] = {mod = 4, tim = L.PrLive()*1.5, m = m, pos = G.SGmintp and L.Hitpr(t.pos, t.vel, 150) + tes3vector3.new(0,0,20) or t.pos, v = t.vel:normalized()}
					if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				elseif G.SGMod == 12 then		
					CPR[r] = {mod = 12, tim = L.PrLive(), m = m, spd = spd, p = r.position}
					if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				end
			end end
		return end
		
		cont = tes3.isAffectedBy{reference = p, effect = 506}	ray = n == "4b_RAY"
		if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.4, callback = function() end}  	L.SectorDod() end
		local sid = ss.effects[1].id	--tes3.messageBox("Sid = %s    dam = %s", sid, W.metd)			--attempt to index field 'effects' (a nil value)
		if sid == 610 then	r.sceneNode.appCulled = true
			if n == "4nm_tet" then W.TETP = r		W.TETsi = si		W.TETmod = 2
			else
				r.position = tes3.getPlayerEyePosition() + tes3vector3.new(0,0,20)
				m.velocity = tes3.getPlayerEyeVector() * W.acs
				CPR[r] = {mod = 6, m = m, v = tes3.getPlayerEyeVector(), r = W.met, dmg = W.metd, spd = W.acs, si = si, sn = sn}	W.met.orientation = p.orientation
				V.MET[sn] = {r = W.met, dmg = W.metd}		mc = cont and (10 + W.met.object.weight)/2 * (P.mys7 and 0.5 or 1)
				if cont and mp.magicka.current > mc then Mod(mc)	CPR[r].con = true
					V.METR[W.met] = {si = si, sn = sn}
					if not W.metflag then event.register("simulate", L.SimMET)	W.metflag = true end
				end
				if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
			end
		elseif ME[sid] == "wave" then
			CPR[r] = {mod = 9, m = m, num = 1, ef = ss.effects, k = SN[sn] or 1, max = (P.alt23 and 15 or 5) + math.min(math.floor(mp:getSkillValue(11)/40 + mp.willpower.current/40), 5)}
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		end
		
		if V.BAL[sn] then CPR[r] = {mod = 5, m = m, pow = V.BAL[sn]}	m.velocity = m.velocity:normalized() * spd
			if cont and mp.magicka.current > 10 then Mod(6 * (P.mys7 and 0.5 or 1))		CPR[r].con = true end
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		elseif ray and MB[cf.mbray] == 128 == cf.ray then CPR[r] = {mod = 8, m = m, liv = (50 + mp.willpower.current/2 + mp:getSkillValue(11))/(P.alt20 and 600 or 1000)}
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		end
		m.velocity = m.velocity:normalized() * spd
	else	cont = tes3.isAffectedBy{reference = p, effect = 506}
		if cf.pvp1 and not T.Dom.timeLeft then T.Dom = timer.start{duration = 0.4, callback = function() end}  	L.SectorDod() end
		CPR[r] = {mod = 10, m = m, liv = 0}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
		if prob.type == 13 and P.mark9b and (cf.autoarb or MB[cf.mbshot] == 128) and not T.Arb.timeLeft and mp.fatigue.current > 30 then	local ws = m.firingWeapon.speed
			mp.fatigue.current = mp.fatigue.current - math.max(30 - ws*10, 10)
			mp.animationController.weaponSpeed = mp.animationController.weaponSpeed * (2 + mp.agility.current/50)
			T.Arb = timer.start{duration = 3/ws, callback = function() end}
		end
		if BAM[prob.id] then BAM.am = prob.id	BAM.E[1].id = MID[math.random(3)]	BAM.E[1].min = math.random(5) + mp:getSkillValue(10)/20		BAM.E[1].max = BAM.E[1].min*2		BAM.E[1].radius = math.random(5) + L.GetRad(mp)
			if (P.con17 or tes3.isAffectedBy{reference = p, effect = 601}) and BAM.f() then
				if mp.readiedAmmoCount < 3 then	tes3.addItem{reference = p, item = BAM.am, count = 100, playSound = false} end
			else	mp:unequip{item = BAM.am}		tes3.removeItem{reference = p, item = BAM.am, count = mwscript.getItemCount{reference = p, item = BAM.am}} end
			--	mp.readiedAmmoCount = 2		tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}
		end
		local marstat = mp.agility.current + mp:getSkillValue(23)
		G.ArcDiv = ((G.arcf or G.met) and 3 or 1) - math.min(marstat/(P.mark11 and 100 or 300), 1) + (mp.isRunning and 1 - math.min(marstat/(P.mark15 and 200 or 400), 1) or 0)
		if G.ArcDiv > 0 then m.velocity = L.GetArcVec(20,10) * m.initialSpeed end		--tes3.messageBox("div =  %s ", G.ArcDiv)
	end
	if (cf.raycon or not ray) and (cont or (P.mys18 and T.MCT.timeLeft)) and mp.magicka.current > 10 then mc = 4
		local live = L.PrLive() 		--(mp.fatigue.normalized*4 + (mp.willpower.current + mp:getSkillValue(14) + mp:getSkillValue(11))/50) * (P.mys80 and 2 or 1)
		if si then
			if DM.cp == 2 then	if not G.cpscd then event.register("simulate", SimulateCPS)	G.cpscd = true end	local num = 1	md = CPS[1]		for i, tim in ipairs(CPS) do if tim < md then num = i	md = tim end end 
				CPS[num] = live*1.5		for ref, t in pairs(CPRS) do if t.n == num then CPRS[ref] = nil	break end end		CPRS[r] = {n = num, rad = 200 + ss.effects[1].radius * 6}
				if cf.m then tes3.messageBox("Ball %s  Time = %d  Rad = %d  Balls = %s   Live = %d %d %d %d %d %d %d %d %d %d", num, CPS[num], CPRS[r].rad, table.size(CPRS), CPS[1], CPS[2], CPS[3], CPS[4], CPS[5], CPS[6], CPS[7], CPS[8], CPS[9], CPS[10]) end
			else -- Сперва проверяем рикошет (12), потом мины (4), затем автонаведение (1), затем режим на цель
				if DM.cp == 12 then CPR[r] = {mod = 12, tim = live, m = m, spd = spd, p = r.position}
				elseif DM.cp == 4 then mc = P.mys8a and MB[cf.mbret] == 128 and 10 or 6	
					CPR[r] = {mod = 4, tim = live*1.5, m = m, pos = mc == 10 and L.Hitp(150) + tes3vector3.new(0,0,20) or tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*50, v = tes3.getPlayerEyeVector()}
				else	local tar
					if DM.cp == 1 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {p}}
						tar = hit and hit.reference and hit.reference.mobile and not hit.reference.mobile.isDead and hit.reference
						if not tar then tar = L.Sector{d = 9000, lim = 3000} end
					end
					if tar then mc = 10	CPR[r] = {mod = 2, tim = live, m = m, tar = tar, hv = tes3vector3.new(0,0,tar.mobile.height/2), spd = spd}
					else CPR[r] = {mod = 1, tim = live, m = m, spd = spd, p = r.position} end
				end		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
			end
		else if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
			if DM.cp == 12 then CPR[r] = {mod = 12, tim = live, m = m, p = r.position}			mc = 4
			else CPR[r] = {mod = 11, m = m, p = r.position, tim = live, mus = G.ArcDiv >= 1}	mc = 6 end
		end
		Mod((ray and mc/2 or mc) * (P.mys7 and 0.5 or 1))
	end		--if si then SSN[si.serialNumber] = true	tes3.messageBox("Cast! %s", si.serialNumber) end -- устраняем эксплойт с разгоном статов
elseif si and cf.spellhit and firm.actionData.target == mp then 
	CPR[r] = {mod = 7, m = m, liv = 0.5 + firm.object.level/20, spd = math.min(m.initialSpeed*3 + firm.object.level*100, 15000)}		--tes3.messageBox("liv = %.1f  InSpd = %.2f   spd = %d", CPR[r].liv, m.initialSpeed, CPR[r].spd)
	if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
end
if not si then	r.position = r.position - m.velocity:normalized()*100
	local w = m.firingWeapon	local wt = w.type	local sw = m.attackSwing / prob.speed 		local WS = firm.actorType == 0 and firm.combat.current or firm:getSkillValue(WT[wt].s)	local vel
	local Kskill = WS * (((firm ~= mp or P[WT[wt].p1]) and 0.2 or 0.1) + ((firm ~= mp or P.agi30) and 0.1 or 0.05))
	local Kbonus = firm.attackBonus/5 + (firm == mp and (P.str15 and 20 * math.max(1 - mp.health.normalized, 0) or 0) or firm.object.level)
	m.damage = prob.chopMax * (100 + Kskill + Kbonus)/100
	
	local Kin = firm == mp and P.alt26 and math.min(mp.willpower.current/10 + mp:getSkillValue(0)/5, cf.metlim) * sw or 0	local mc1 = 0
	if Kin > 0 then mc1 = Kin/(P.alt17 and 6 or 4)		if mp.magicka.current > mc1 then Mod(mc1)	Kin = Kin * (Cpow(mp,0,0,true) + (P.alt16 and 50 or 0))/200 else Kin = 0	mc1 = 0 end end
	
	
	if wt == 11 then	local Kstam = math.min(math.lerp(((firm ~= mp or P.end1) and 0.4 or 0.3) + ((firm ~= mp or P[WT[wt].p2]) and 0.1 or 0), 1, firm.fatigue.normalized*1.1), 1)
		vel = 1000*Kin/(prob.weight+5) + ((firm.strength.current*((firm ~= mp or P.str12) and 1.5 or 1))/(prob.weight+5))^0.5 * (firm == mp and 500 or 1000) * sw * Kstam
	else	local Cond = firm.readiedWeapon.variables.condition/w.maxCondition		Cond = Cond > 1 and Cond or math.lerp((firm ~= mp or P.arm2) and 0.3 or 0.2, 1, Cond)
		Cond = Cond * (w.weight == 0 and (1 + firm:getSkillValue(13)*((firm ~= mp or P.con8) and 0.003 or 0.002)) or 1)
		vel = 500*Kin/(prob.weight+5) + ((w.chopMax * Cond)/math.clamp(prob.weight, 0.2, 0.5)+0.1)^0.5 * (firm == mp and 500 or 1000) * sw
	end
	if firm == mp then vel = vel + 1000		if CPR[r] then CPR[r].spd = vel end end			m.velocity = m.velocity:normalized() * vel
	if cf.m30 then tes3.messageBox("Proj spd %d (%d%%)  dmg %.1f (%d + %d%% skill + %d%% bon)  sw = %.2f  Kin %.1f (%.1f cost)", vel, 4*vel/(vel/100+100), m.damage, prob.chopMax, Kskill, Kbonus, sw, Kin, mc1) end
end
--	tes3.messageBox("Sw = %.2f  Dam = %.2f  InSpd = %.2f  vel = %d  weap = %s  sn = %s", m.attackSwing, m.damage, m.initialSpeed, m.velocity:length(), m.firingWeapon and m.firingWeapon.id, si and si.serialNumber)
--	tes3.messageBox("%s  w = %s  sn = %s  fl = %s  disp = %s  exp = %s  movfl = %s", firm and firm.object.name, m.firingWeapon and m.firingWeapon.id, si and si.serialNumber, m.flags, m.disposition, m.expire, m.movementFlags)
else	local actort = m.actorType 		local ob = r.object 	local id = r.baseObject.id			
	if actort then AF[r] = {summ = L.Summon[id]}		N[r] = {m = m, dod = actort == 1 or ob.usesEquipment or L.CDOD[id], hum = actort == 1 or ob.biped}
		local Dopw = G.DopW[id] 	if Dopw then tes3.addItem{reference = r, item = Dopw} 	G.DopW[id] = nil end
	end
if actort == 0 and not r.data.spawn then	r.data.spawn = math.random(10)	local d = r.data.spawn		local typ = ob.type
	--if not ob.level then mwse.log("NO ob! ob id = %s   base = %s    ref = %s    Inv = %s   Spells = %s", ob.id, r.baseObject.id, r, ob.inventory, ob.spells) end
	
	if L.CrBlackList[id] then m.shield = L.CrBlackList[id] else
		local conj = AF[r].summ and L.conjpower or 1		local conj2 = 0		local min, max
		if AF[r].summ then min = 80	max = 120
			if L.conjagr then m.fight = 100		m:startCombat(mp)	m.actionData.aiBehaviorState = 3
			elseif L.conjp then m.fight = math.max((math.random(50,70) + ob.level * (P.con5 and 1 or 2) - (conj - 1)*100), 50)
				if (typ == 1 and P.con6b) or (typ == 2 and P.con6a) then conj = conj + mp:getSkillValue(13)/1000 end		if P.con7 then conj2 = 0.1 end
			end
		else min = cf.min	max = cf.max end
		local koef = math.random(min,max)/100		tes3.setStatistic{reference = r, name = "health", value = m.health.base * koef * (conj + conj2)}
		koef = koef/((min+max)/200)		if koef > 1 then koef = 1 + (koef - 1) * 0.75 else koef = 1 + (koef - 1) * 0.5 end		if L.CID[id] ~= "dwem" then r.scale = r.scale * koef end
		tes3.setStatistic{reference = r, name = "magicka", value = m.magicka.base * math.random(min,max)/100 * (conj + conj2)}
		tes3.setStatistic{reference = r, name = "fatigue", value = m.fatigue.base * math.random(min,max)/100 * (conj + conj2)}
		for i, stat in ipairs(L.CStats) do tes3.setStatistic{reference = r, name = stat, value = m[stat].base * math.random(min,max)/100 * conj} end		--attempt to index a nil value
		m.shield = (L.CAR[id] or m.endurance.current/10 + ob.level/2) * math.random(min,max)/100 * conj
		m.resistCommonDisease = 200		m.resistBlightDisease = 200
	end
if cf.full then	rf = r
	if L.CDIS[id] then r.baseObject.spells:add(L.CDIS[id]) end
if typ == 1 then -- Даэдра
	if id == "atronach_flame" or id == "atronach_flame_summon" then m.resistFire = m.resistFire + 200			rems("flamebolt", "fire storm", "cruel firebloom", "wizard's fire", "god's fire")
		if d > 7 then adds("flamebolt") end			if d > 8 then adds("fire storm") end		if d == 10 then adds("wizard's fire") end
	elseif id == "atronach_frost" or id == "atronach_frost_summon" then m.resistFrost = m.resistFrost + 200		rems("frost bolt", "frost storm", "brittlewind", "wizard rend", "god's frost")
		if d > 7 then adds("frost bolt") end		if d > 8 then adds("frost storm") end		if d == 10 then adds("wizard rend") end
	elseif id == "atronach_storm" or id == "atronach_storm_summon" then m.resistShock = m.resistShock + 200		rems("lightning bolt", "lightning storm", "wild shockbloom", "dire shockball", "god's spark")
		if d > 7 then adds("lightning bolt") end	if d > 8 then adds("lightning storm") end	if d == 10 then adds("dire shockball") end
	elseif id == "atronach_flame_lord" then m.resistFire = m.resistFire + 200
	elseif id == "atronach_frost_lord" then m.resistFrost = m.resistFrost + 200
	elseif id == "atronach_storm_lord" then m.resistShock = m.resistShock + 200
	elseif id == "dremora" or id == "dremora_summon" then	rems("summon scamp", "summon clanfear", "fire storm", "firebloom")
		if d > 8 then tes3.addItem{reference = r, item = "4nm_bow_excellent"}	tes3.addItem{reference = r, item = "4nm_arrow_magic+excellent", count = math.random(20,30)}
		elseif d == 8 then tes3.addItem{reference = r, item = "4nm_crossbow_excellent"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)}
		elseif d > 2 then adds(table.choice{"firebloom", "fire storm"}) end
		if d > 5 then adds(table.choice{"summon scamp", "summon clanfear"}) end
	elseif id == "dremora_lord" then	rems("summon daedroth", "summon dremora", "summon flame atronach", "summon frost atronach", "summon storm atronach")
		if d > 2 then adds(table.choice{"summon daedroth", "summon dremora", "summon daedroth", "summon dremora", "summon flame atronach", "summon frost atronach", "summon storm atronach"}) end		
	elseif id == "dremora_mage" or id == "dremora_mage_s" then rems("summon flame atronach", "summon frost atronach", "summon storm atronach", "4nm_star_atronach1a", "4nm_star_atronach2a", "4nm_star_atronach3a",
		"fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom", "flamebolt", "frost bolt", "lightning bolt", "fire storm", "frost storm", "lightning storm")
		adds(table.choice{"fireball", "frostball", "shockball", "4nm_star_atronach1a"}, table.choice{"Fireball_large", "Frostball_large", "shockball_large", "4nm_star_atronach2a"})
		if d > 2 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"}) end
		if d > 4 then adds(table.choice{"flamebolt", "frost bolt", "lightning bolt", "4nm_star_atronach3a"}) end
		if d > 5 then adds(table.choice{"fire storm", "frost storm", "lightning storm"}) end
		if d > 6 then adds(table.choice{"summon flame atronach", "summon frost atronach", "summon storm atronach"}) end
	elseif id == "scamp" or id == "scamp_summon" then	rems("flame", "fireball", "Fireball_large")
		if d > 5 then adds(table.choice{"flame", "fireball"}) end
	elseif id == "daedroth" or id == "daedroth_summon" then	rems("viperbolt", "poisonbloom")
		if d > 6 then adds("viperbolt", "poisonbloom")	elseif d < 3 then adds("viperbolt")	elseif d == 3 or d == 4 then adds("poisonbloom") end
	elseif id == "daedraspider" or id == "daedraspider_s" then	rems("bm_summonbonewolf", "summon daedroth", "summon hunger", "summon clanfear")
		if d > 8 then adds("bm_summonbonewolf")		elseif d < 3 then adds("summon daedroth")	elseif d == 3 or d == 4 then adds("summon hunger")	elseif d == 5 or d == 6 then adds("summon clanfear") end
	elseif id == "winged twilight" or id == "winged twilight_summon" then	rems("frost storm", "lightning storm", "frostbloom", "shockbloom")
		if d == 1 then adds("frost storm") elseif d == 2 then adds("lightning storm") elseif d == 3 then adds("frostbloom") elseif d == 4 then adds("shockbloom") elseif d == 5 then adds("frost storm", "shockbloom")
		elseif d == 6 then adds("lightning storm", "frostbloom") elseif d == 7 then adds("frost storm", "lightning storm", "frostbloom", "shockbloom") end
	elseif id == "xivkyn" or id == "xivkyn_s" then	rems("wizard's fire", "sp_nchurdamzsummon")
		if d > 6 then adds("wizard's fire", "sp_nchurdamzsummon")	elseif d < 3 then adds("wizard's fire")	elseif d == 3 or d == 4 then adds("sp_nchurdamzsummon") end	
	elseif id == "mazken" or id == "mazken_s" then	rems("summon winged twilight", "summon hunger", "summon dremora")
		if d > 8 then tes3.addItem{reference = r, item = "4nm_bow_excellent"}	tes3.addItem{reference = r, item = "4nm_arrow_magic+excellent", count = math.random(20,30)}
		elseif d < 3 then adds("summon winged twilight")	elseif d == 3 or d == 4 then adds("summon hunger")	elseif d == 5 or d == 6 then adds("summon dremora") end
	elseif id == "golden saint" or id == "golden saint_summon" then		rems("summon flame atronach", "summon frost atronach", "summon storm atronach")
		if d > 8 then adds("summon flame atronach")		elseif d < 3 then adds("summon frost atronach")	elseif d == 3 or d == 4 then adds("summon storm atronach") end
	end
elseif typ == 2 then -- Нежить
	if id == "skeleton" or id == "skeleton_summon" then
		if d > 8 then tes3.addItem{reference = r, item = "long bow"}	tes3.addItem{reference = r, item = "iron arrow", count = math.random(20,30)}
		elseif d < 4 then m:equip{item = "iron_shield", addItem = true}
		elseif d == 8 then tes3.addItem{reference = r, item = "wooden crossbow"}	tes3.addItem{reference = r, item = "iron bolt", count = math.random(20,30)} end
	elseif id == "skeleton_mage" or id == "skeleton_mage_s" then
		rems("bone guard", "summon greater bonewalker", "fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom")
		adds(table.choice{"fireball", "frostball", "shockball"})
		if d > 2 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"}) end
		if d > 3 then adds(table.choice{"bone guard", "summon greater bonewalker"})	end
		if d > 7 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"})		tes3.addItem{reference = r, item = "4nm_weapon_mage"} end
	elseif id == "bonelord" or id == "bonelord_summon" then	rems("bone guard", "summon least bonewalker")
		if d > 2 then adds(table.choice{"bone guard", "summon least bonewalker"}) end
	elseif id == "skeleton warrior" then
		if d == 1 then tes3.addItem{reference = r, item = "steel crossbow"}	tes3.addItem{reference = r, item = "steel bolt", count = math.random(20,30)} end
	elseif id == "skeleton archer" or id == "skeleton_archer_s" then if d > 9 then tes3.addItem{reference = r, item = "l_n_wpn_missle_thrown", count = math.random(5,20)}
		elseif d < 2 then tes3.addItem{reference = r, item = "4nm_thrown_magic", count = math.random(5,20)} end
	elseif id == "skeleton champion" then rems("frostbloom", "frost storm")
		if d < 3 then adds(table.choice{"frostbloom", "frost storm"}) elseif d == 3 then adds("frostbloom", "frost storm") end
	elseif id == "ash_revenant" then rems("scourge blade", "heartbite", "daedric bite")
		if d > 7 then m:equip{item = "steel_shield", addItem = true}
		elseif d > 4 then adds(table.choice{"scourge blade", "heartbite", "daedric bite"})
		elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"l_n_wpn_missle_bow", "6th longbow"}}	tes3.addItem{reference = r, item = table.choice{"l_m_wpn_missle_arrow", "6th arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)} end	
	elseif id == "draugr_priest" then rems("daedric bite", "frost bolt", "wizard rend", "bm_draugr_curse")
		if d > 2 then adds(table.choice{"daedric bite", "frost bolt", "wizard rend"})	if d > 8 then tes3.addItem{reference = r, item = "BM ice wand"}		adds("bm_draugr_curse") end end
	elseif id == "draugr_soldier" then
		if d > 5 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = "nordic_sky bow"}	tes3.addItem{reference = r, item = "nordic_sky arrow", count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "steel_sky crossbow"}	tes3.addItem{reference = r, item = "steel_sky bolt", count = math.random(20,30)} end	
	elseif id == "draugr_warrior" then
		if d > 5 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"nordic_sky bow", "BM ice longbow"}}	tes3.addItem{reference = r, item = table.choice{"nordic_sky arrow", "BM ice arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "steel_sky crossbow"}	tes3.addItem{reference = r, item = "steel_sky bolt", count = math.random(20,30)} end	
	end
elseif typ == 0 then -- Обычные кричеры	
	if L.CID[id] == "dwem" then m.resistParalysis = m.resistParalysis + 200
		if tes3.isAffectedBy{reference = p, object = "summon_centurion_unique"} and m.fight > 50 then m.fight = 50 end
		if id == "centurion_weapon" then
			if d > 5 then m:equip{item = "dwemer_shield", addItem = true}
			elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"dwarven arbalest", "dwarven crossbow"}}	tes3.addItem{reference = r, item = "dwarven bolt", count = math.random(20,30)} end
		end
	elseif id == "goblin_grunt" then
		if d > 5 then m:equip{item = "goblin_shield", addItem = true}
		elseif d == 1 then tes3.addItem{reference = r, item = "goblin throwingaxe", count = math.random(5,10)}
		elseif d == 2 then tes3.addItem{reference = r, item = "goblin arrow", count = math.random(20,30)} end
	elseif id == "goblin_shaman" then rems("fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom")
		adds(table.choice{"fireball", "frostball", "shockball"})
		if d > 3 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"})		if d > 6 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"}) end end
	elseif id == "BM_riekling_shaman" then rems("fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom")
		adds(table.choice{"fireball", "frostball", "shockball"})
		if d > 3 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"})		if d > 6 then adds(table.choice{"firebloom", "frostbloom", "shockbloom"}) end end
	end
elseif typ == 3 then -- Гуманоиды
	if id == "ash_slave" then rems("spark", "flame", "shard", "shockball", "fireball", "frostball", "Fireball_large", "Frostball_large", "shockball_large")
		if d > 7 then adds(table.choice{"Fireball_large", "Frostball_large", "shockball_large"})
		elseif d > 3 then adds(table.choice{"shockball", "fireball", "frostball"})
		elseif d > 1 then adds(table.choice{"spark", "flame", "shard"})
		else m:equip{item = "iron_shield", addItem = true} end
	elseif id == "ash_zombie" then
		if d > 8 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_bow"}	tes3.addItem{reference = r, item = "l_n_wpn_missle_arrow", count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "l_n_wpn_missle_bolt", count = math.random(20,30)}
		elseif d == 4 then tes3.addItem{reference = r, item = "6th throwingknife", count = math.random(5,10)} end
	elseif id == "ash_zombie_warrior" then	
		if d > 7 then m:equip{item = "steel_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = table.choice{"l_n_wpn_missle_bow", "6th longbow"}}	tes3.addItem{reference = r, item = table.choice{"l_m_wpn_missle_arrow", "6th arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)} end
	elseif id == "ash_ghoul_warrior" then	rems("summon hunger", "summon daedroth", "summon clanfear", "summon greater bonewalker", "summon dremora")
		if d > 5 then adds(table.choice{"summon hunger", "summon daedroth", "summon clanfear", "summon greater bonewalker", "summon dremora"}) end
	elseif id == "ash_ghoul" then rems("summon hunger", "summon daedroth", "summon bonelord", "summon greater bonewalker", "summon least bonewalker")
		if d > 5 then adds(table.choice{"summon hunger", "summon daedroth", "summon bonelord", "summon greater bonewalker", "summon least bonewalker"}) end
	elseif id == "ash_ghoul_high" then rems("summon flame atronach", "summon frost atronach", "summon storm atronach", "summon bonelord", "summon least bonewalker")
		if d > 5 then adds(table.choice{"summon flame atronach", "summon frost atronach", "summon storm atronach", "summon bonelord", "summon least bonewalker"}) end
	--elseif id == "ascended_sleeper" then
	end
end end
if cf.m9 then tes3.messageBox("%s (%s)  HP %d/%d   Mana %d/%d   Stam %d/%d   Str %d/%d   Spd %d/%d   End %d/%d   Agi %d/%d   AR %d   Fig %d",
r.object.name, d, m.health.current, r.baseObject.health, m.magicka.current, r.baseObject.magicka, m.fatigue.current, r.baseObject.fatigue,
m.strength.current, r.baseObject.attributes[1], m.speed.current, r.baseObject.attributes[5], m.endurance.current, r.baseObject.attributes[6], m.agility.current, r.baseObject.attributes[4], m.shield, m.fight) end
end end end end		event.register("mobileActivated", MOBILEACTIVATED)

-- Первый эвент исчезновения снарядов.
local function MOBILEDEACTIVATED(e) local r = e.reference		local m = e.mobile
	N[r] = nil		AF[r] = nil		--tes3.messageBox("%s   Deact = %s", r, table.size(AF))
	if R[r] then R[r] = nil	if cf.m4 then tes3.messageBox("%s deactivated  Enemies = %s", r, table.size(R)) end end
	
--	if m.actorType then tes3.messageBox("DEA %s   INT = %s   fall = %s  low = %s    dist = %d   dead = %s   rint = %s  cell = %s",
--	r, G.LowestZ and true, m.isFalling, G.LowestZ and r.position.z < G.LowestZ, pp:distance(r.position), m.isDead, r.cell.isInterior, r.cell == p.cell) end
	
	if G.LowestZ and m.actorType and r.position.z < G.LowestZ and G.CurCell == r.cell then		--pp:distance(r.position) > 7000
		tes3.messageBox("%s EXTRA RETURN   Z = %d   Low = %d     Pdif = %d   dist = %d", r, r.position.z, G.LowestZ, pp.z - r.position.z, pp:distance(r.position))
		r.position = pp + p.forwardDirection * 100
	end
end		event.register("mobileDeactivated", MOBILEDEACTIVATED)


-- Вторые эвенты исчезновения снарядов.
local function PROJECTILEHITACTOR(e) local firr = e.firingReference		local tar = e.target	if (firr == p and firr ~= tar) or (firr ~= p and not AF[firr].summ and firr.mobile.actionData.target == tar.mobile) then
	--tes3.messageBox("Pr hit actor %s   tar = %s    ob = %s", firr, tar, e.mobile.reference)
	local ob = e.mobile.reference.object
	if not L.BlackAmmo[ob.id] and ob.maxCondition * (firr == p and (P.luc8 and 1.5 or 1) + (mp.luck.current/200) or 1.5) > math.random(100) then
		if ob.enchantment then ob = L.AMIC[ob.icon:lower()] end
		if ob then tes3.addItem{reference = tar, item = ob, playSound = false} end
	end
	--[[
	local hit = tes3.rayTest{position = e.collisionPoint - e.velocity:normalized()*10, direction = e.velocity}		local pos = hit and hit.intersection
	if pos then
		local nod = e.target.sceneNode		nod = nod:getObjectByName("Bip01") or nod
		local trans = e.mobile.reference.sceneNode.worldTransform
		local clone = e.mobile.reference.object.sceneNode:clone()
		local invM = nod.worldTransform.rotation:invert()	local invS = 1 / nod.worldTransform.scale
		clone.rotation = invM * trans.rotation			clone.translation = invM * (pos - nod.worldTransform.translation) * invS * 0.5			clone.scale = invS
		nod:attachChild(clone)	nod:update()	clone:updateProperties()	clone:updateEffects()
	end	--]]
end end		event.register("projectileHitActor", PROJECTILEHITACTOR)

local function onProj(e) local r = e.mobile.reference	local ob = r.object		local firr = e.firingReference		if not L.BlackAmmo[ob.id] and firr and not AF[firr].summ then
local cp = e.collisionPoint		if ob.enchantment then ob = L.AMIC[ob.icon:lower()] end		if ob and math.abs(cp.x) < 9000000 then		local vel = e.velocity
	local hit = tes3.rayTest{position = cp - vel:normalized()*10, direction = vel}		local pos		--cp + e.velocity * 0.7 * wc.deltaTime
	if hit and hit.intersection:distance(cp) < 150 then pos = hit.intersection else local hitd = tes3.rayTest{position = cp, direction = V.down}	pos = hitd and hitd.intersection end		
	if pos then 
		Matr:lookAt(ob.type == 11 and ob.speed > 0.99 and ob.speed < 1.26 and vel * -1 or vel, V.up)			--orientation = r.sceneNode.worldTransform.rotation:toEulerXYZ()
		local ref = tes3.createReference{object = ob, cell = p.cell, orientation = Matr:toEulerXYZ(), position = pos}	ref.modified = false	PRR[ref] = true
	end
	--tes3.createReference{object = "4nm_boundarrow", cell = p.cell, orientation = r.sceneNode.worldTransform.rotation:toEulerXYZ(), position = cp}
--	tes3.messageBox("Hit object = %s", r)
end end end		if cf.Proj then event.register("projectileHitObject", onProj)	event.register("projectileHitTerrain", onProj) end


-- Третий эвент исчезновения снарядов. Прожектайл Экспире НЕ триггерится если снаряд убит командой стейт = 6. Триггерится при целл чейнджед		tes3.messageBox("ex  %s    si = %s", pr, si and si.serialNumber or "nil")
L.NoEXP = {["4b_EXP"] = true, ["4b_WAV"] = true}
local function PROJECTILEEXPIRE(e) local pm = e.mobile	local pos = pm.position:copy()	local si = pm.spellInstance		local sn = si and si.serialNumber		if si then COL[sn] = pos end
if e.firingReference == p then
	if si then local eff = si.source.effects
		if D.Exp and not D.Expdis and not L.NoEXP[si.source.name] then
			L.ExpSpell()
			MP[tes3.applyMagicSource{reference = p, source = B.EXP}] = {pos = pos, exp = true}
		end
		
		if W.TETP and W.TETP == pm.reference then W.TETP = nil	W.TETmod = 3 end
		if V.MET[sn] then local wr = V.MET[sn].r	local drop
			if V.METR[wr] then
				if not V.METR[wr].f then V.METR[wr].f = 1 end
			else drop = true end
			if drop then local hit = tes3.rayTest{position = wr.position - pm.velocity:normalized()*100, direction = V.down}
				if hit then wr.position = hit.intersection + tes3vector3.new(0,0,5) end
			end
		elseif P.des8 and ME[eff[1].id] == 1 and si.source.name ~= "4b_WAV" then	local rad = 0		local radbon = L.GetRad(mp)		local magn		--attempt to index local 'eff' (a nil value)
			for i, ef in ipairs(eff) do if ME[ef.id] == 1 and ef.radius > 9 then magn = math.random(ef.min, ef.max)	 rad = rad + math.min(5 * magn^0.5, magn) * math.max(ef.radius - 10 + radbon, 0) end end
			if rad > 10 then rad = rad * Cpow(mp,0,2)/100 * (SN[sn] or 1)		L.KBlast(pos, rad) end
		end
	else
		if D.poison then D.poison = D.poison - math.max(100 - mp.agility.current/(P.agi12 and 2 or 4),50)	M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end end
		if W.f == 2 and pm.firingWeapon == W.w then MP[tes3.applyMagicSource{reference = p, source = W.en, fromStack = mp.readiedWeapon}] = {pos = pos, exp = true} end
		if D.CW and not D.CWdis and cf.smartcw then	L.CWF(p, 2, 1.5, pos) end
	end
end
end		event.register("projectileExpire", PROJECTILEEXPIRE)


local function OBJECTINVALIDATED(e) local ob = e.object				--tes3.messageBox("%s   INVALID", ob)
	if CPR[ob] then CPR[ob] = nil elseif CPRS[ob] then CPS[CPRS[ob].n] = 0	CPRS[ob] = nil end
	if ob == W.TETR then if cf.m then tes3.messageBox("Telekinesis: Invalidated") end	W.TETR = nil end
	if V.METR[ob] then V.METR[ob] = nil		if cf.m then tes3.messageBox("Throw: Invalidated") end end
	if DER[ob] then DER[ob] = nil end
	if PRR[ob] then PRR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)

local function DEATH(e) local r = e.reference
	if R[r] then R[r] = nil	if cf.m4 then tes3.messageBox("%s dead  Enemies = %s", r, table.size(R)) end end
	if L.CID[r.baseObject.id] == "zombirise" and r.data.spawn ~= 0 then 
		if r.object.level * 5 > math.random(100) then timer.start{duration = math.random(5,10), callback = function() if r.mobile.isDead then
		--	tes3.runLegacyScript{command = "resurrect", reference = r}
			r.mobile:resurrect{resetState = false}
			tes3.playSound{sound = "bonewalkerSCRM", reference = r}		r.data.spawn = 0
			e.mobile.health.current = e.mobile.health.base/2	e.mobile.magicka.current = e.mobile.magicka.base/2	e.mobile.fatigue.current = e.mobile.fatigue.base/2
		end end} end
	end
end		event.register("death", DEATH)

-- ЦеллЧЕйнджед НЕ триггерит инвалидейтед обычных референций, но триггерит Прожектайл Экспире.		Эвент срабатывает при загрузке сейва
local function CELLCHANGED(e) AC = {}		for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end
	G.LowestZ = e.cell.isInterior and tes3.dataHandler.lowestZInCurrentCell - 300 or nil		G.CurCell = e.cell
	if W.TETmod and e.previousCell and (e.cell.isInterior or e.previousCell.isInterior) then p:activate(W.TETR) end
	if W.metflag and e.previousCell and (e.cell.isInterior or e.previousCell.isInterior) then for r, t in pairs(V.METR) do if t.f then p:activate(r) end end	V.METR = {}	end
	if cf.trmod then local tim = T.T1.timing - G.Exptim		for i = 1, 4 do	D.ExpFat[i] = math.max(D.ExpFat[i] - tim, 0) end		G.Exptim = T.T1.timing end
end		event.register("cellChanged", CELLCHANGED)

local function MOUSEWHEEL(e) if not tes3ui.menuMode() then local CS = mp.currentSpell
	local num = table.wrapindex(D.FS, math.max((CS and table.find(D.FS, CS.id) or 0) + (e.delta > 0 and -1 or 1), 0))		local sid = D.FS[num]
	if sid then if p.object.spells:contains(sid) then mp:equipMagic{source = sid} else table.remove(D.FS, num) end end
end	end		if cf.scrol then event.register("mouseWheel", MOUSEWHEEL) end

--local function Fire(n)  tes3.createReference{object = "iron dagger", position = tes3.player.position, cell = tes3.player.cell} if n > 1 then timer.delayOneFrame(function() Fire(n-1) end) end end
local QK = {[cf.q0.keyCode] = "0", [cf.q1.keyCode] = "1", [cf.q2.keyCode] = "2", [cf.q3.keyCode] = "3", [cf.q4.keyCode] = "4", [cf.q5.keyCode] = "5", [cf.q6.keyCode] = "6", [cf.q7.keyCode] = "7", [cf.q8.keyCode] = "8", [cf.q9.keyCode] = "9"}
local function KEYDOWN(e) if not tes3ui.menuMode() then local k = e.keyCode		--tes3.messageBox("key = %s   jump = %s", k, ic.inputMaps[12].code)
if k == cf.magkey.keyCode then local CS = mp.currentSpell		-- Быстрый каст
	if ad.animationAttackState == 1 then
		if L.AG[ad.currentAnimationGroup] then
			if P.agi25 and ad.currentAnimationGroup == 34 then		local stc = 100 * (1 + mp.encumbrance.normalized)
				if mp.fatigue.current > stc then mp.fatigue.current = mp.fatigue.current - stc		ad.animationAttackState = 0		if cf.m then tes3.messageBox("Stand up! Stamcost = %d", stc) end end
			end
		elseif P.agi17 then		local stc = 30 * (1 + mp.encumbrance.normalized)		--and not AF[p].part
			if mp.fatigue.current > stc then mp.fatigue.current = mp.fatigue.current - stc		ad.animationAttackState = 0		if cf.m then tes3.messageBox("Break free! Stamcost = %d", stc) end end
		end
	elseif (mp.hasFreeAction and mp.paralyze < 1 or P.agi17) and ad.animationAttackState ~= 10 then
		if M.QB.normalized >= (P.spd11 and 0.5 or 1) and not D.QSP["0"] and QS ~= CS and CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (P.int3 or CS.alwaysSucceeds) then QS = CS
			M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
		end
		if QS then	
			local excost = (QS.alwaysSucceeds and 20 or 10) + QS.magickaCost * ((mp.spellReadied or not W.w or (WT[W.wt].h1 and not W.DWM and not mp.readiedShield)) and 0.5 or 1) + (P.agi24 and 0 or 10)
			local stc = QS.magickaCost * (P.end8 and 0.5 or 1)
			if M.QB.current >= excost and mp.fatigue.current > stc then		mp.fatigue.current = mp.fatigue.current - stc
				if ad.animationAttackState == 2 then MB[1] = 0 end
				G.LastQS = QS		tes3.cast{reference = p, spell = QS, instant = true, alwaysSucceeds = false}
				M.QB.current = math.max(M.QB.current - excost, 0)
				if not T.QST.timeLeft then T.QST = timer.start{duration = math.max(1 - mp.speed.current/(P.spd9 and 200 or 400), 0.5), iterations = -1, callback = function()
				M.QB.current = M.QB.current + G.ExMax/20	if M.QB.current > G.ExMax then M.QB.current = G.ExMax	T.QST:cancel() end end} end
			end
		end
	end
	
elseif QK[k] and M.QB.normalized >= (P.spd11 and 0.5 or 1) then local CS = mp.currentSpell		-- Выбор быстрого каста
	if QK[k] ~= "0" then
		if e.isShiftDown and CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (CS.alwaysSucceeds or P.int3) then
			D.QSP[QK[k]] = CS.id		tes3.messageBox("%s remembered for %s extra-cast slot", D.QSP[QK[k]], QK[k])
		end
		if D.QSP[QK[k]] then D.QSP["0"] = QK[k]		QS = tes3.getObject(D.QSP[D.QSP["0"]])		M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
			if cf.m10 then tes3.messageBox("%s prepared for extra-cast slot %s  %s", QS.name, D.QSP["0"], QS.alwaysSucceeds and "Is a technique" or "") end
		end
	else
		if e.isShiftDown and CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 then	local sid = CS.id	local num = table.find(D.FS, sid)
			if num then table.remove(D.FS, num)		tes3.messageBox("%s removed from Favorite Spells (%s)", CS.name, num)
			else D.FS[table.size(D.FS) + 1] = sid	tes3.messageBox("%s added to Favorite Spells (%s)", CS.name, table.size(D.FS)) end
		elseif e.isAltDown then D.FS = {}	tes3.messageBox("Favorite spell list cleared") else D.QSP["0"] = nil end
	end
elseif k == cf.tpkey.keyCode and (P.agi17 or mp.hasFreeAction) and mp.paralyze < 1 then		local dkik = MB[3] == 128	local DMag = math.min(Mag(600), dkik and 1000 or cf.dash)	-- дэши
	if DMag > 0 and MB[cf.mbdod] ~= 128 then	local ang	local DD = DMag * (Cpow(mp,0,4,true) + (P.spd8 and 50 or 0))/2
		mc = (DMag + (P.acr8 and mp.isFalling and 0 or math.min(DMag,10))) * (P.alt10 and 1 or 1.5)
		if mp.isMovingForward then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 end
		V.d = tes3.getPlayerEyeVector()		if ang then Matr:toRotationZ(math.rad(ang))	V.d = Matr * V.d end
		if ang == 90 or ang == 270 then V.d.z = 0	V.d = V.d:normalized()	else if mp.isMovingBack then V.d = V.d*-1 end	if math.abs(V.d.z) < 0.15 then V.d.z = 0	V.d = V.d:normalized() end end
		if dkik then local kref		kref, dkik = L.Sector{d = DD, lim = 500, v = V.d} end
		if dkik then dkik = dkik/DD		if dkik < 1 then DD = DD * dkik		mc = mc * dkik end
		else	local dhit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = V.d, ignore={p}}		if dhit then dhit = dhit.distance/DD	if dhit < 1 then DD = DD * dhit		mc = mc * dhit end end end
		if T.Dash.timeLeft then mc = mc * (1 + T.Dash.timeLeft/(P.atl8 and 10 or 3)) end	local stam = mc * ((P.end10 and 0.5 or 1) - (P.una10 and D.AR.u*0.02 or 0))
		if not V.dfr and mc < mp.magicka.current then		local vk = math.max(-0.4 - V.d.z, 0)/3
			V.d = V.d*(DD/8 * (1 - vk))		V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		tes3.playSound{sound="Spell Failure Destruction"}
			if not mp.isJumping then V.djf = true	mp.isJumping = true end			if dkik and cf.autokik then V.dkik = true end
			Mod(mc)		mp.fatigue.current = math.max(mp.fatigue.current - stam, 0)		if cf.m then tes3.messageBox("Dash dist = %d  Cost = %.1f  Time = %.1f  SlamK = %d%%", DD, mc, T.Dash.timeLeft or 0, vk*100) end
			V.dd = DD 	if T.Dash.timeLeft then T.Dash:cancel()	end		T.Dash = timer.start{duration = 3, callback = function() end}
		end
	else	local stam = (P.agi4 and 40 or 50) * (1 + mp.encumbrance.normalized*(P.agi14 and 0.5 or 1) + (D.AR.dc < 0 and D.AR.dc or math.max(D.AR.dc - math.max(-mp.encumbrance.currentRaw,0)/1000,0)))
		if T.Dod.timeLeft then stam = stam * (1 + T.Dod.timeLeft/(P.atl10 and 6 or 3)) end
		if not V.dfr and (P.acr13 or not mp.isFalling) and stam < mp.fatigue.current then	local ang
			if mp.isMovingForward then if mp.isMovingLeft then ang = -45 elseif mp.isMovingRight then ang = 45 end
			elseif mp.isMovingBack then if mp.isMovingLeft then ang = -135 elseif mp.isMovingRight then ang = 135 else ang = 180 end
			elseif mp.isMovingLeft then ang = -90 elseif mp.isMovingRight then ang = 90 end
			V.d = tes3.getPlayerEyeVector()		if ang then Matr:toRotationZ(math.rad(ang))	V.d = Matr * V.d end
			V.d.z = 0	V.d = V.d:normalized() * ((P.spd16 and 150 or 100)/5)
			V.dfr = 5	event.register("calcMoveSpeed", L.Dash)		mp.fatigue.current = mp.fatigue.current - stam			tes3.playSound{sound = math.random(2) == 1 and "LeftS" or "LeftM"}
			if not mp.isJumping then V.djf = true	mp.isJumping = true end
			if cf.m then tes3.messageBox("Active dodge!  Cost = %d  Time = %.1f", stam, T.Dod.timeLeft or 0) end
			if P.sec6 and (T.Dod.timeLeft or 0) < 2 then tes3.applyMagicSource{reference = p, name = "Dodge", effects = {{id = 510, min = 20, max = 20, duration = 1}}} end
			if T.Dod.timeLeft then T.Dod:cancel() end	T.Dod = timer.start{duration = 3, callback = function() end}
		end
	end
elseif k == cf.kikkey.keyCode then L.KIK()
elseif k == cf.telkey.keyCode then -- Телекинез + Метание оружия - возврат
--	tes3.messageBox("AF = %s   N = %s   MQB = %s   eng = %s", table.size(AF), table.size(N), M.QB.normalized, eng)
--	for r, tab in pairs(N) do tes3.applyMagicSource{reference = r, name = "sumsum", effects = {{id = 107, duration = 5}}} end -- 142
--	for r, tab in pairs(N) do r:delete() end
--	tes3.applyMagicSource{reference = tes3.player, name = "fireball", effects = {{id = 501, min = 3, max = 6, duration = 4, radius = 15, rangeType = 2}}}
--	if e.isShiftDown then D.newDir = math.random(0,3)	tes3.messageBox("newDir: %s", D.newDir) else D.MBto0 = not D.MBto0	tes3.messageBox("MBto0: %s", D.MBto0) end

--	W.acs = 5000		W.metd = 20
--	W.met = tes3.dropItem{reference = p, item = mp.readiedWeapon.object}		if W.DWM then L.DWMOD(false) end
--	tes3.applyMagicSource{reference = p, name = "4nm_met", effects = {{id = 610, rangeType = 2}}}


	for r, t in pairs(V.METR) do if not t.f then	t.f = 1		t.si.state = 6 end end
	if not W.TETmod then	local ref = tes3.getPlayerTarget()	if ref and ref.object.value then TELnew(ref) end
	elseif W.TETmod == 1 then
		if MB[3] == 128 then p:activate(W.TETR)
		elseif mp.magicka.current > W.TETcost then mc = W.TETcost * (P.mys7 and 0.5 or 1)		Mod(mc)		tes3.playSound{sound = "Weapon Swish"}	--Weapon Swish		Spell Failure Destruction
			tes3.applyMagicSource{reference = p, name = "4nm_tet", effects = {{id = 610, rangeType = 2}}}	if cf.m then tes3.messageBox("Telekinetic throw! Dmg = %.1f  Cost = %.1f (%.1f base)", W.TETdmg, mc, W.TETcost) end
		end
	elseif W.TETmod == 2 then W.TETmod = 3	W.TETsi.state = 6	W.TETsi = nil
	elseif W.TETmod == 3 and P.mys16 and mp.magicka.current > 2*W.TETcost then	mc = W.TETcost * (P.mys7 and 0.5 or 1) * math.min(1 + pp:distance(W.TETR.position)/5000, 2)
		Mod(mc)	W.TETmod = 1	tes3.playSound{sound = "enchant fail"}	if cf.m then tes3.messageBox("Extra teleport!  Manacost = %.1f (%.1f base)", mc, W.TETcost) end
	end
elseif k == cf.cwkey.keyCode then -- Заряженное оружие
	if e.isControlDown then D.CWm = not D.CWm	tes3.messageBox("Charged weapon: %s", D.CWm and "ranged" or "touch")
	elseif e.isShiftDown then D.CWdis = not D.CWdis	tes3.messageBox("Charged weapon: %s", D.CWdis and "disabled" or "enabled")
	elseif e.isAltDown then D.NoEnStrike = not D.NoEnStrike		W.bar.fillColor = D.NoEnStrike and {1,0,0} or {0,1,1}
		tes3.messageBox("Weapon enchant trigger when attacking: %s", D.NoEnStrike and "disabled" or "enabled")
	elseif D.CW and W.TETR and P.mys17 then L.CWF(p, 2, 1, W.TETR.position:copy()) end
elseif k == cf.cpkey.keyCode then -- Контроль снарядов
	if MB[1] == 128 then CPRS = {}	for r, t in pairs(CPR) do if t.tim then 	 if t.mod == 4 then t.m.velocity = t.v * t.m.initialSpeed end		CPR[r] = nil end end -- Роспуск снарядов
	elseif MB[3] == 128 then for r, t in pairs(CPR) do if t.tim and t.mod < 11 then t.m:explode() end end		for r, t in pairs(CPRS) do r.mobile:explode() end
--	elseif e.isAltDown then if DM.cpt then DM.cpt = false tes3.messageBox("Simple mode") elseif P.alt8a then DM.cpt = true tes3.messageBox("Smart mode") end
--	elseif e.isControlDown then if DM.cpm then DM.cpm = false tes3.messageBox("Mines: simple mode") elseif P.mys8a then DM.cpm = true tes3.messageBox("Mines: teleport mode") end
	elseif ic:isKeyDown(ic.inputMaps[1].code) then if P.mys8a then DM.cp = 3 tes3.messageBox("Teleport projectiles") end
	elseif ic:isKeyDown(ic.inputMaps[2].code) then if P.mys8b then DM.cp = 1 tes3.messageBox("Homing projectiles") end
	elseif ic:isKeyDown(ic.inputMaps[3].code) then if P.alt8d then DM.cp = 12 tes3.messageBox("Ricochet projectiles") end
	elseif ic:isKeyDown(ic.inputMaps[4].code) then if P.alt8c then DM.cp = 4 tes3.messageBox("Magic mines") end
	elseif e.isControlDown then if P.alt8b then DM.cp = 2 tes3.messageBox("Spin projectiles") end
	else DM.cp = 0 tes3.messageBox("Target projectiles") end
elseif k == cf.reflkey.keyCode then	-- Отражение	Auras
	if e.isAltDown then		local MSET = {{14, 16, 15, 23, 27, 22, 24, 25}, {18, 19, 20, 17, 37, 38}, {28, 29, 30, 31, 35, 36}, {45, 46, 47, 48}, {86, 87, 88, 85}}
		local M = {}	M.M = tes3ui.createMenu{id = 403, fixedFrame = true}		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true	M.B.flowDirection = "top_to_bottom"
		M.lab = M.B:createLabel{text = eng and "Choose the effects that will be reflected by your mana shield" or "Выберите эффекты, которые будут отражаться вашим манащитом"}
		for i = 1, 5 do M[i] = M.B:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 5	end
		for i, l in ipairs(MSET) do for _, id in ipairs(l) do
			M[id] = M[i]:createImage{path = "icons\\" .. tes3.getMagicEffect(id).bigIcon}		M[id].borderAllSides = 3		if D.MSEF["e"..id] then M[id].color = {0.2,0.2,0.2} end
			M[id]:register("mouseClick", function() if D.MSEF["e"..id] then D.MSEF["e"..id] = nil	M[id].color = {1,1,1} else D.MSEF["e"..id] = true	M[id].color = {0.2,0.2,0.2} end		M[id]:updateLayout() end)
		end end
		M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)		tes3ui.enterMenuMode(403)
	elseif e.isControlDown then D.Aurdis = not D.Aurdis		tes3.messageBox("Damage aura mode: %s", D.Aurdis and "disabled" or "enabled")
	elseif e.isShiftDown then D.Expdis = not D.Expdis		tes3.messageBox("Explode spell mode: %s", D.Expdis and "disabled" or "enabled")
	else DM.refl = not DM.refl	tes3.messageBox("Reflect spell mode: %s", DM.refl and "reflect" or "manashield") end
elseif k == cf.totkey.keyCode then -- Тотемы и руны
	if e.isShiftDown then for i, t in pairs(RUN) do L.RunExp(i) end
	elseif e.isControlDown then for i, t in pairs(TOT) do L.TotExp(i) end
	else D.Totdis = not D.Totdis	tes3.messageBox("Totem shooting: %s", D.Totdis and "disabled" or "enabled") end
elseif k == cf.detkey.keyCode then local mag = P.mys12 and 30 or 20  -- Обнаружение
	local node, nod		local dist = {tes3.getEffectMagnitude{reference = p, effect = 64}*mag, tes3.getEffectMagnitude{reference = p, effect = 65}*mag, tes3.getEffectMagnitude{reference = p, effect = 66}*mag}	DEDEL()
	for c, _ in pairs(AC) do for r in c:iterateReferences() do local ot
		if r.object.objectType == tes3.objectType.container and not r.object.organic then ot = "cont" elseif r.object.objectType == tes3.objectType.door then ot = "door" elseif r.mobile and not r.mobile.isDead then
		if r.object.objectType == tes3.objectType.npc or r.object.type == 3 then ot = "npc" elseif r.object.type == 1 then ot = "dae" elseif r.object.type == 2 then ot = "und" elseif r.object.blood == 2 then ot = "robo" else ot = "ani" end
		elseif r.object.enchantment or r.object.isSoulGem then ot = "en" elseif r.object.isKey then ot = "key" end
		if ot and r.sceneNode then node = r.sceneNode:getObjectByName("detect") if node then r.sceneNode:detachChild(node) 	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end
			if pp:distance(r.position) < dist[L.DEO[ot].s] then nod = L.DEO[ot].m:clone()	if r.mobile then nod.translation.z = nod.translation.z + r.mobile.height/2 end
		r.sceneNode:attachChild(nod, true)	r.sceneNode:update()	r.sceneNode:updateNodeEffects()		DER[r] = ot end end
	end end		if table.size(DER) > 0 then tes3.playSound{reference = p, sound = "illusion hit"}	if T.DET.timeLeft then T.DET:reset() else T.DET = timer.start{duration = 10, callback = DEDEL} end end
elseif k == cf.markkey.keyCode then	local mtab = {}		for i = 1, 10 do mtab[i] = i.." - "..(DM["mark"..i] and DM["mark"..i].id or "empty") end -- Пометки
	mtab[11] = "Teleport companions: " .. (D.NoTPComp and "no" or "yes")
	tes3.messageBox{message = "Select a mark for recall", buttons = mtab, callback = function(e) if e.button == 10 then D.NoTPComp = not D.NoTPComp else	local v = "mark"..(e.button+1)		if DM[v] then
		mp.markLocation.cell = tes3.getCell{id = DM[v].id}		mp.markLocation.position = tes3vector3.new(DM[v].x, DM[v].y, DM[v].z)
	end end end}
elseif k == cf.bwkey.keyCode then	-- Призванное оружие
	if e.isControlDown then
		local M = {}	M.M = tes3ui.createMenu{id = 402, fixedFrame = true}	M.M.minHeight = 800	M.M.minWidth = 800		local el	M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
		for i = 1, 4 do M[i] = M.B:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 5		M[i].flowDirection = "top_to_bottom" end
		for i, l in ipairs(L.BW) do for _, id in ipairs(l) do
			el = M[i]:createLabel{text = id}	el.borderBottom = 2		el:register("mouseClick", function() D.boundw = "4_bound " .. id	M.M:destroy()	tes3ui.leaveMenuMode() end)
		end end		tes3ui.enterMenuMode(402)
	elseif P.con17 or tes3.isAffectedBy{reference = p, effect = 601} then	if mp.readiedWeapon then BAM.am = BAM[mp.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
		if mwscript.getItemCount{reference = p, item = BAM.am} == 0 then 	if BAM.f() then tes3.addItem{reference = p, item = BAM.am, count = 100, playSound = false}	mp:equip{item = BAM.am} end
		else mp:equip{item = BAM.am} end
	end
elseif k == cf.parkey.keyCode then	-- Парирование
	if G.TR.tr5 then tes3.messageBox("%s", eng and "The Code of honor does not allow you to go into brutal mode" or "Кодекс чести не позволяет вам перейти в жестокий режим")
	else D.nopar = not D.nopar	M.NoPar.visible = D.nopar		tes3.messageBox("Parry mode: %s", D.nopar and "disabled" or "enabled") end
elseif k == cf.poisonkey.keyCode then D.poimod = not D.poimod		M.drop.visible = D.poimod		tes3.messageBox("Poison mode %s", M.drop.visible and "enabled" or "disabled")	-- Режим яда
elseif k == cf.dwmkey.keyCode then if e.isAltDown then W.WL = nil W.DL = nil else L.DWMOD(not W.DWM) end	-- Двойное оружие
elseif k == cf.pkey.keyCode and L.READY then	local M = {}	M.M = tes3ui.createMenu{id = 400, fixedFrame = true}	M.M.minHeight = 1200	M.M.minWidth = 1280	-- Перки
	M.S = 0		for i, l in ipairs(L.PR) do for _, t in ipairs(l) do if P[t[1]] then M.S = M.S + t.f end end end	local pat		local LVL = p.object.level
	M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
	M.F = M.B:createFillBar{current = M.S, max = LVL * cf.pmult}	M.F.width = 300		M.F.height = 24		M.F.widget.fillColor = {1,0,1}
	M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkSpells()	L.HPUpdate() end)
	M.class = M.B:createButton{text = eng and "Legendary" or "Легендарность"}
	M.class:register("mouseClick", function() if mp.inCombat then tes3.messageBox("%s", eng and "In combat" or "Вы в бою") else M.M:destroy()	tes3ui.leaveMenuMode()	L.LegSelect() end end)
	M.resp = M.B:createButton{text = eng and "Reset perks" or "Сброс перков"}		M.resp:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkReset() end)
	M.take = M.B:createButton{text = eng and "Take free perks" or "Взять бесплатные перки"}		M.take:register("mouseClick", function()
		for i, l in ipairs(L.PR) do for _, t in ipairs(l) do if t.f < 1 and mp[L.PRL[i][1]].base >= t[2] then P[t[1]] = true end end end
		M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkSpells()	L.HPUpdate()
	end)
	if P.int16 and not mp.inCombat then M.spcrea = M.B:createButton{text = eng and "Spell making" or "Создание заклинаний"}		M.spcrea:register("mouseClick", function()
		M.M:destroy()	tes3ui.leaveMenuMode()		tes3.findGMST("fSpellMakingValueMult").value = 0		tes3.showSpellmakingMenu{serviceActor = mp, useDialogActor = false}
		timer.delayOneFrame(function() tes3.findGMST("fSpellMakingValueMult").value = P.merc7 and 10 or 20 end)
	end) end
	for i = 0, 35 do M[i] = M.A:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 1		M[i].flowDirection = "top_to_bottom" end
	
	for i, t in ipairs(L.PR[0]) do t.m = M[0]:createImage{path = "icons/p/"..t[1]..".tga"}		t.m.borderBottom = 2		if not G.TR[t[1]] then t.m.color = {0.2,0.2,0.2} end
		t.m:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}		tt.autoHeight = true	tt.autoWidth = true		tt.maxWidth = 600
		tt:createLabel{text = ("%s   (%s lvl, %s)   %s"):format(t[eng and 4 or 3], t[2], eng and "Traits cannot be reset" or "Трейты нельзя сбрасывать", t[eng and 6 or 5])} end)
		if not G.TR[t[1]] and LVL >= t[2] then t.m:register("mouseClick", function() if not G.TR[t[1]] then G.TR[t[1]] = true	tes3.playSound{sound = "skillraise"}	t.m.color = {1,1,1}		t.m:updateLayout() end end) end
	end
	
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do pat = "icons/p/"..t[1]..".tga"		t.m = M[i]:createImage{path = tes3.getFileExists(pat) and pat or L.PRL[i][2]}
		t.m.borderBottom = 2	if not P[t[1]] then t.m.color = {0.2,0.2,0.2} end
		t.m:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}		tt.autoHeight = true	tt.autoWidth = true		tt.maxWidth = 600
		tt:createLabel{text = ("%s   Cost: %s - %s = %s   Required %s: %s  -  %s"):format(t[eng and 4 or 3], t.x, t.c or 0, t.f, L.PRL[i][1], t[2], t[eng and 6 or 5])} end)
		if M.F.widget.max >= M.S + t.f and not P[t[1]] and mp[L.PRL[i][1]].base >= t[2] then t.m:register("mouseClick", function() if not P[t[1]] and M.F.widget.max >= M.S + t.f then P[t[1]] = true
		M.S = M.S + t.f		M.F.widget.current = M.S	M.F:updateLayout()	tes3.playSound{sound = "skillraise"}	t.m.color = {1,1,1}		t.m:updateLayout()	end end) end
	end end		tes3ui.enterMenuMode(400)
	if e.isAltDown then	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do P[t[1]] = true end end		for _, num in ipairs(L.SFS) do tes3.addSpell{reference = p, spell = "4s_"..num, updateGUI = false} end
	tes3.updateMagicGUI{reference = p, updateEnchantments = false}		D.resetday = 0		tes3.messageBox("TESTER MOD ACTIVATED!")	tes3.playSound{sound = "Thunder0"} end
end end end		event.register("keyDown", KEYDOWN)


local function CALCFLYSPEED(e) if e.mobile == mp then e.speed = mp.levitate
	* (20 + mp:getSkillValue(11)/(P.alt15 and 5 or 10))
	* (1 + mp.speed.current/(P.spd18 and 400 or 1000))
	* (1 - (1 - math.min(mp.fatigue.normalized,1)) * (P.atl2 and 0.25 or 0.5))
elseif not e.mobile.object.flies then e.speed = (2 + e.mobile.levitate) * 40 * (1 + e.mobile.speed.current/400) 		--tes3.messageBox("fly = %s  lev = %.1f  speed = %d", e.reference, e.mobile.levitate, e.speed)
end end		event.register("calcFlySpeed", CALCFLYSPEED)

local function CALCMOVESPEED(e) local m = e.mobile		if m == mp then local strafe = mp.isMovingLeft or mp.isMovingRight	local forw = mp.isMovingForward		local back = mp.isMovingBack
	e.speed = e.speed * (strafe and (forw or back) and 0.8 or 1)
	* math.min(D.AR.ms + math.max(-mp.encumbrance.currentRaw,0)/2000, 1)
	* (P.atl3 and 1 or (1 - mp.encumbrance.normalized/3))
	* (back and 0.625 or 1)
	* (not P.acr3 and mp.isFalling and 0.75 or 1)
	* (mp.isRunning and (P.spd0 and forw and not strafe and 1.25 or 1)
	* (G.TR.tr3 and 1 or 0.8)
	* ((forw or P.spd20) and 1 or 0.8)
	* (1 - (1 - math.min(mp.fatigue.normalized,1)) * (P.atl2 and 0.25 or 0.5))
	* ((ad.animationAttackState == 2 and (P.spd10 and 0.8 or 2/3)) or (ad.animationAttackState == 10 and (P.spd19 and 0.8 or 2/3)) or 1) or 1)
	
	G.Pspd = e.speed * (strafe and (forw or back) and 1.25 or 1) * ((forw and 1) or (back and 0.8) or 0.75)
	if cf.spdm then M.MSPD.text = ("%d"):format(G.Pspd) end
--	tes3.messageBox("speed = %d    vel = %d", e.speed, mp.velocity:length())
else e.speed = m.isFalling and 0 or e.speed * (0.5 + math.min(m.fatigue.normalized,1)/2)		--m.isJumping and 0 or
--	tes3.messageBox("speed = %d - %d - %d     spd = %d  atl = %d  enc = %.2f", e.speed, (100 + m.speed.current) * (3 + m:getSkillValue(8)/100) * (0.5 + math.min(m.fatigue.normalized,1)/2) * (1 - m.encumbrance.normalized/2),
--	(5 + 2.95 * m.speed.current) * (3 + m:getSkillValue(8)/100) * (0.5 + math.min(m.fatigue.normalized,1)/2) * (1 - m.encumbrance.normalized/2), m.speed.current, m:getSkillValue(8), m.encumbrance.normalized)
	if DOM[m] then	local t = DOM[m]		--tes3.messageBox("%s", t.fr)		--	m.impulseVelocity = t.v * (TSK/wc.deltaTime)		t.fr = t.fr - TSK
		m.impulseVelocity = t.v		t.fr = t.fr - wc.deltaTime
	--	if t.nospd then e.speed = 0 end
		if t.fr < 0 then DOM[m] = nil end
	end
	
	--if e.reference.data.jpos1 and not m.isFalling then tes3.messageBox("%s   dist = %d", e.reference, e.reference.data.jpos1:distance(m.position))		e.reference.data.jpos1 = nil end
end end		if cf.Spd then event.register("calcMoveSpeed", CALCMOVESPEED) end


local function JUMP(e)	if e.isDefaultJump then local vec = e.velocity:normalized()		local m = e.mobile	if m == mp then
local Kstat = 250 + m:getSkillValue(20) + m.agility.current/2 + (P.acr1 and 100 or 0) + m.jump * (P.alt24 and 20 or 15)
local Kstam = math.min(math.lerp((P.atl13 and 0.5 or 0.3), 1, m.fatigue.normalized), 1)
local Kenc = (1 - math.min(m.encumbrance.normalized,1) * (P.atl6 and 0.5 or 0.8)) * math.min(D.AR.ms + math.max(-m.encumbrance.currentRaw,0)/2000, 1)

if mp.isHitStunned then local ang
	if mp.isMovingForward then if mp.isMovingLeft then ang = -45 elseif mp.isMovingRight then ang = 45 else ang = 0 end
	elseif mp.isMovingBack then if mp.isMovingLeft then ang = -135 elseif mp.isMovingRight then ang = 135 else ang = 180 end
	elseif mp.isMovingLeft then ang = -90 elseif mp.isMovingRight then ang = 90 end
	if ang then vec = tes3.getPlayerEyeVector()		Matr:toRotationZ(math.rad(ang))		vec = Matr * vec		vec.z = 0	vec = vec:normalized()		vec.z = 1	vec = vec:normalized() end
	e.velocity = vec * (Kstat * Kstam * Kenc * 0.5)
else e.velocity = vec * (Kstat * Kstam * Kenc) end

if wc.systemTime - L.jumptim > 2000 then L.skacr = 1	L.jumptim = wc.systemTime else L.skacr = 0 end
--local vec = tes3.getPlayerEyeVector():normalized()	vec.z = 0.2			e.velocity = vec * 1000

--tes3.messageBox("Jump! %d = %d stat * %d%% stam * %d%% enc  x = %d   stun = %s", e.velocity.z, Kstat, Kstam*100, Kenc*100, e.velocity.x, mp.isHitStunned)
else e.velocity = vec * (350 + m:getSkillValue(20) + m.agility.current/2 + m.jump*20)
	--tes3.messageBox("Jump npc! z = %d   x = %d", e.velocity.z, e.velocity.x)
end end end		event.register("jump", JUMP)


local function CALCARMORRATING(e) local m = e.mobile	if m then	local a = e.armor
	e.armorRating = a.armorRating * (1 + m:getSkillValue(AT[a.weightClass].s)/((m ~= mp or P[AT[a.weightClass].p]) and 100 or 200)) * (a.weight == 0 and 0.5 + m:getSkillValue(13)/((m ~= mp or P.con9) and 200 or 400) or 1)
e.block = true end end		event.register("calcArmorRating", CALCARMORRATING)



L.ArcSim = function(e) if mp.weaponDrawn and MB[1] == 128 then	local AS = ad.animationAttackState
	if G.arcf then
		if AS == 2 then	-- АС превращается из 2 в 4 а в следующем фрейме в 5 так как ЛКМ зажата.	Происходит выстрел и существующий nockedProjectile становится нил в следущем фрейме
			if ad.nockedProjectile and G.arcf < 5 then		ad.attackSwing = 0.5	ad.animationAttackState = 4		mp.animationController.weaponSpeed = 0.0001		G.arcf = G.arcf + 1
			else G.arcf = nil 	--mp.animationController.weaponSpeed = 1000000	--G.arcspd 	
				ad.nockedProjectile = nil 	ad.animationAttackState = 0		MB[1] = 0
			end
		elseif AS == 4 then		mp.animationController.weaponSpeed = G.arcspd
		elseif AS == 5 then ad.animationAttackState = 0	end		-- АС превращается из 5 в 0 а следующем фрейме в 2 так как ЛКМ зажата. nockedProjectile в этом фрейме нил но заряжается новый в следующем фрейме
		--tes3.messageBox("%s   AS = %s --> %s   %s   %s   Swing = %d", G.arcf, AS, ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, mp.readiedAmmoCount, ad.attackSwing*100)
	elseif AS == 2 then local dt = wc.deltaTime
		if MB[cf.mbarc] == 128 and mp.fatigue.current > 10 then mp.fatigue.current = mp.fatigue.current - dt * (P.atl4 and 10 or 20)	dt = -dt end	G.artim = math.clamp((G.artim or 0) + dt,0,4)
		if G.artim > 0 then	local MS = ic.mouseState
			local x = (5 + mp.readiedWeapon.object.weight/4) * (1 - (math.min(mp.strength.current + mp.agility.current + mp:getSkillValue(23),300)/(P.mark12 and 400 or 600))) * G.artim/4
			MS.x = MS.x + math.random(-2*x,2*x)		MS.y = MS.y + math.random(-x,x)
		end
	else G.artim = nil end
else event.unregister("simulate", L.ArcSim)	G.artim = nil	if G.arcf then G.arcf = nil		mp.animationController.weaponSpeed = G.arcspd end end end

L.MetSim = function(e) if mp.weaponDrawn and MB[1] == 128 and G.met < G.metmax then	local AS = ad.animationAttackState
	if AS == 0 then mp.animationController.weaponSpeed = 1000000
	elseif AS == 2 then	
		if ad.nockedProjectile then	ad.attackSwing = G.metsw		ad.animationAttackState = 4		G.met = G.met + 1		--if G.met == 0 then mp.animationController.weaponSpeed = 1000000	end
		else	mp.animationController.weaponSpeed = 1000000 end
	elseif AS == 4 then		mp.animationController.weaponSpeed = 1000000
	elseif AS == 5 then		
		if ad.nockedProjectile then ad.animationAttackState = 0 else	 mp.animationController.weaponSpeed = 1000000 end
	end
	--tes3.messageBox("%s   AS = %s --> %s   %s    Swing = %d", G.met, AS, ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, ad.attackSwing*100)
else event.unregister("simulate", L.MetSim)		G.met = nil		mp.animationController.weaponSpeed = G.arcspd end end

L.MetSim1 = function(e) if mp.weaponDrawn and MB[1] == 128 then	local AS = ad.animationAttackState
if G.met > 0 then
	if G.met == 1 then
	else
		if AS == 2 then
			if ad.nockedProjectile and G.met < 5 then	ad.attackSwing = 0.8		ad.animationAttackState = 4		G.met = G.met + 1		--if G.met == 0 then mp.animationController.weaponSpeed = 1000000	end
				mp.animationController.weaponSpeed = 0.0001
			else	event.unregister("simulate", L.MetSim)		G.met = nil		mp.animationController.weaponSpeed = G.arcspd 	--MB[1] = 0	
			end
		elseif AS == 4 then		mp.animationController.weaponSpeed = G.met == 1 and 1000000 or G.arcspd
		elseif AS == 5 then		
			if ad.nockedProjectile then ad.animationAttackState = 0 else mp.animationController.weaponSpeed = 1000000
			end
		end
	end
	if G.met then tes3.messageBox("%s   AS = %s --> %s   %s    Swing = %d", G.met, AS, ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, ad.attackSwing*100) end
end
else event.unregister("simulate", L.MetSim)		G.met = nil		mp.animationController.weaponSpeed = G.arcspd end end

L.ARBSIM = function(e) if not tes3ui.menuMode() and mp.weaponDrawn and MB[3] == 128 then
--	if G.arbf then if ad.animationAttackState == 2 then G.arbf = nil else return end end
--	if ad.animationAttackState == 2 then MB[1] = 0		ad.animationAttackState = 0		G.arbf = true end
	--mp.animationController.weaponSpeed = 0.5
	if ad.animationAttackState == 5 then 	--mp.animationController.weaponSpeed = 0.0001
		ad.animationAttackState = 0		tes3.messageBox("AS = 5 ---> %s   %s   %s", ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, mp.readiedAmmoCount)
		--MB[1] = 0		tes3.messageBox("AS = 5 ---> %s", ad.animationAttackState)
	elseif ad.animationAttackState == 2	then 	--MB[1] = 0		tes3.messageBox("AS = %s   MOUSE = 0", ad.animationAttackState)
		
		--if not ad.nockedProjectile then ad.nockedProjectile = G.PR end
		
		--mp.animationController.weaponSpeed = 0.0001
		ad.animationAttackState = 4		tes3.messageBox("AS = 2 ---> %s   %s   %s", ad.animationAttackState, ad.nockedProjectile and ad.nockedProjectile.reference, mp.readiedAmmoCount)
--	elseif ad.animationAttackState == 4	then		ad.animationAttackState = 2		tes3.messageBox("AS = 4 ---> %s", ad.animationAttackState)
--	elseif ad.animationAttackState == 0	then		ad.animationAttackState = 2		tes3.messageBox("AS = 0 ---> %s", ad.animationAttackState)
--	else tes3.messageBox("AS = %s  ", ad.animationAttackState)
	end
end end		--event.register("simulate", L.ARBSIM)

L.AS = {[0]=2, [2]=2, [3]=0, [4]=0, [5]=1, [6]=1, [7]=1}		L.COMOV = {[0]=2, [1]=3, [2]=1, [3]=2}			--L.ASAR = {[4]=1, [5]=1, [6]=1, [7]=1}
L.WCO = {[1] =	{[1] = {[2]=1}, 				[2] = {[2]=1},					[3] = {[0]=2, [2]=1, [3]=2}},	-- Одноруч
[2] =			{[1] = {[0]=2, [2]=1, [3]=2},	[2] = {},						[3] = {[0]=2, [2]=1, [3]=2}},	-- Двуруч
[0] =			{[1] = {[2]=1},					[2] = {[0]=3, [1]=3, [2]=1},	[3] = {[2]=1},	[4] = {}},		-- Кулаки
[3] =			{[1] = {[0]=1, [2]=1}, 			[2] = {[2]=1},					[3] = {[0]=2, [2]=1, [3]=2}}}	-- Дуалы если сейчас оружие в левой
--[[Движения: Д0 стоять, Д1 вперед, Д2 вбок, Д3 наискосок. С (от 0 до 3) это ad.animationAttackState который мы принудительно устанавливаем.
Если сделать MB[1] = 0, то новая атака зависит только от движения, отмены анимации замаха не будет. Остальные разрешенные атаки с полной отменой анимации без MB[1] = 0:
Одноручное оружие:
Режущая: 				Д0 С1 = реж											Д2 С01 = реж
Рубящая: Д0 С02 = руб	Д0 С1 = реж											Д2 С01 = реж	Д2 С23 = руб	Д3 С0123 = руб
Колющая: Д0 С02 = руб	Д0 С1 = реж		Д0 С3 = кол		Д1 С0123 = кол		Д2 С01 = реж	Д2 С23 = руб	Д3 С0123 = руб
Двуручное оружие:
Режущая: Д0 С02 = руб	Д0 С1 = реж											Д2 С01 = реж	Д2 С23 = руб	Д3 С0123 = руб
Рубящая: Д0 С02 = руб																		Д2 С23 = руб	Д3 С0123 = руб
Колющая: Д0 С02 = руб	Д0 С1 = реж		Д0 С3 = кол		Д1 С0123 = кол		Д2 С01 = реж	Д2 С23 = руб	Д3 С0123 = руб
Кулаки:
Режущая: 				Д0 С1 = реж											Д2 С01 = реж
Рубящая: Д0 С02 = руб	Д0 С1 = реж		Д0 С3 = кол		Д1 С0123 = кол		Д2 С01 = реж	Д2 С23 = руб	Д3 С0123 = руб
Колющая: 				Д0 С1 = реж		Д0 С3 = кол		Д1 С0123 = кол		Д2 С01 = реж
--]]

L.DWSwap = function()
	if W.cot == 1 then
		if inv:contains(W.WL, W.DL) and W.DL.condition > 0 then
			W.snd = 1	mp:equip{item = W.WL, itemData = W.DL}
		--	tes3.messageBox("Swap  правый на левый")
		else L.DWMOD(false) W.WL = nil W.DL = nil end
	else
		if inv:contains(W.WR, W.DR) and W.DR.condition > 0 then
			W.snd = 1	mp:equip{item = W.WR, itemData = W.DR}
		--	tes3.messageBox("Swap  левый на правый")
		else L.DWMOD(false) W.WR = nil W.DR = nil end
	end
end
L.WComb = function() local d = ad.physicalAttackType		local fat = mp.fatigue			--MB[1] = 0		mp.animationController.weaponSpeed = 10		MB[1] = 0		ad.animationAttackState = 2		ad.physicalAttackType = 2
	local mov = ((mp.isMovingForward or mp.isMovingBack) and 1 or 0) + ((mp.isMovingLeft or mp.isMovingRight) and 2 or 0)
	local new = L.WCO[W.cot][d][mov]	local swap	local cost = W.cost
	if W.DWM then
		if W.cot == 1 then	if mov == 2 then swap = 1 end
		else	if mov == 2 then swap = 1 else swap = 2 end end
		if swap and P.agi22 then cost = math.max(cost - 5, 0) end
	else
		if P.agi29 and W.cot == 1 and not mp.readiedShield then cost = math.max(cost - 5, 0) end
	end
	
	if new then
		if fat.normalized > cf.cofat/100 and fat.current > cost then
			ad.animationAttackState = 0		ad.physicalAttackType = new		fat.current = fat.current - cost	--tes3.messageBox("Ideal  %d   swap = %s", cost, swap)		
			if swap then L.DWSwap() end
		elseif swap == 2 then	MB[1] = 0		ad.animationAttackState = 0		fat.current = math.max(fat.current - cost, 0)		--tes3.messageBox("Extra swap   %d", cost)
		end
	elseif L.COMOV[mov] ~= d then
		if swap == 2 then		MB[1] = 0		ad.animationAttackState = 0		fat.current = math.max(fat.current - cost, 0)		--tes3.messageBox("Extra swap   %d", cost)
		elseif fat.normalized > cf.cofat/100 and fat.current > cost then	MB[1] = 0	ad.animationAttackState = 0		fat.current = fat.current - cost		--tes3.messageBox("Half   %d   swap = %s", cost, swap)
		end
	end
end
L.WSim = function(e) if mp.weaponDrawn and MB[1] == 128 then	--tes3.messageBox("AS = %s   Dir = %s", ad.animationAttackState, ad.physicalAttackType)
	if L.AS[ad.animationAttackState] == 1 then		-- баг возникает во время АС = 3 и дир = 3 и зажатой лкм
		L.WComb() 	event.unregister("simulate", L.WSim)	W.Wsim = nil
	end
else event.unregister("simulate", L.WSim)	W.Wsim = nil end end

local function MCStart(e) if e.button == 0 then M.MCB.current = 0 	T.MCT:cancel()	G.arm1.appCulled = true	G.arm2.appCulled = true	event.unregister("mouseButtonUp", MCStart) end
if cf.mcs then tes3.removeSound{sound = "destruction bolt", reference = p} end end
local function MOUSEBUTTONDOWN(e) if not tes3ui.menuMode() then local But = e.button + 1		if But == 1 then
	--tes3.messageBox("AnSpd = %.2f   WSpeed = %.2f", mp.animationController.weaponSpeed, mp.readiedWeapon and mp.readiedWeapon.object.speed or 1)
	if mp.spellReadied and not T.MCT.timeLeft then G.arm1.appCulled = false		G.arm2.appCulled = false		local r, AE, EI, sumcost
		local MCK = 2 + (mp.willpower.current + mp.agility.current)/(P.wil15 and 100 or 200) - mp.encumbrance.normalized*(P.end15 and 0.5 or 1)
		+ (D.AR.cs >= 0 and D.AR.cs or math.min(D.AR.cs + math.max(-mp.encumbrance.currentRaw,0)/2, 0))
		
		local stc = 2 - (mp.willpower.current + mp.endurance.current)/(P.end11 and 100 or 200)
		if cf.mcs then tes3.playSound{sound = "destruction bolt", reference = p, loop = true} end
		if MB[cf.mbsum] == 128 and P.con15 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore={p}}		r = hit and hit.reference		local m = r and r.mobile
			if m and not m.isDead then for _, aef in pairs(mp:getActiveMagicEffects{}) do EI = aef.effectInstance	if EI.createdData and EI.createdData.object == r then
				AE = aef	sumcost = tes3.getMagicEffect(aef.effectId).baseMagickaCost * MCK/50	break
			end end end
		end
		T.MCT = timer.start{duration = 0.1, iterations = -1, callback = function() if stc > 0 and mp.fatigue.current > 3 then mp.fatigue.current = mp.fatigue.current - stc end
			M.MCB.current = math.min(M.MCB.current + MCK, 100)		if P.enc7 and T.PCT.timeLeft then M.PC.current = math.min(M.PC.current + M.PC.max * MCK/5000, M.PC.max) end
			if AE and EI.state == 5 and mp.magicka.current > sumcost then	--36 для завершённых эффектов
				EI.timeActive = EI.timeActive - MCK*0.4		Mod(sumcost)		if cf.m then tes3.messageBox("%s + %.1f = %d   Cost = %.1f", r.object.name, MCK*0.4, AE.duration - EI.timeActive, sumcost) end
			end
		end}	event.register("mouseButtonUp", MCStart)
	elseif mp.weaponDrawn then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object	local wt = W.wt		local as = ad.animationAttackState	--or (w and w.type or -1)
		if wt < 9 then
			if as > 0 then
				if L.AS[as] == 1 then	L.WComb()
				elseif not W.Wsim then event.register("simulate", L.WSim)	W.Wsim = 1 end
			elseif W.DWM then
				if w then	--local WTR = WT[W[W.WR.id] or W.WR.type]		local WTL = WT[W[W.WL.id] or W.WL.type]
					local mov = ((mp.isMovingForward or mp.isMovingBack) and 1 or 0) + ((mp.isMovingLeft or mp.isMovingRight) and 2 or 0)
					if W.cot == 1 then
						if mov == 2 then L.DWSwap() end
					elseif mov ~= 2 then L.DWSwap() end
				else L.DWMOD(false) end
			end
		elseif wt == 9 then
			if not G.artim then G.artim = 0		event.register("simulate", L.ArcSim) end
		end
		
	--	if w.id == "glass throwing star" then
	--		if (mp.isMovingLeft or mp.isMovingRight) and not (mp.isMovingForward or mp.isMovingBack) then	as = 0		ad.physicalAttackType = 0		mp:equip{item = "glass dagger"}		return end
	--	elseif w.id == "glass dagger" and not ((mp.isMovingLeft or mp.isMovingRight) and not (mp.isMovingForward or mp.isMovingBack)) then	as = 0		mp:equip{item = "glass throwing star"}	return end
	end
else
	if But == cf.mbshot then
		if G.artim and P.mark9a then	G.arcf = 0		G.arcspd = math.max(mp.animationController.weaponSpeed, 0.4)
		elseif ad.animationAttackState == 2 then	local w = mp.readiedWeapon		w = w and w.object		local wt = w and w.type or -1
			if wt == 11 and P.mark9c and not G.met then	local ws = w.speed	G.metmax = ws > 1.4 and 5 or (ws > 1.2 and 4) or (ws > 0.9 and 3) or 2
				if T.Met.timeLeft then G.metsw = math.max(0.75 - T.Met.timeLeft/4, 0.25)	T.Met:reset() else G.metsw = 0.75		T.Met = timer.start{duration = 2, callback = function() end} end
				event.register("simulate", L.MetSim)		G.met = 1	ad.attackSwing = G.metsw	ad.animationAttackState = 4		mp.animationController.weaponSpeed = 1000000	G.arcspd = mp.animationController.weaponSpeed
			end
		end
	end
	if But == cf.mbkik then L.KIK() end		--if ad.animationAttackState == 2 then ad.animationAttackState = 4	 mp.animationController.weaponSpeed = 1000000 end
	
	if But == 2 and P.spd6 and ad.animationAttackState == 11 and not mp.isHitStunned then
		local stc = 30/mp.animationController.animationData.castSpeed
		if stc < mp.fatigue.current then mp.fatigue.current = mp.fatigue.current - stc		MB[2] = 0		ad.animationAttackState = 0 end
	--	tes3.messageBox("cspd = %s     stc = %d", mp.animationController.animationData.castSpeed, stc)
	end
end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)


local function MOUSEBUTTONUP(e) if not tes3ui.menuMode() and e.button == 0 and ad.animationAttackState == 2 then	local dir = ad.physicalAttackType	if dir < 4 and not V.dfr then	local pass = MB[cf.mbcharg] == 128
	if cf.autocharg or pass then	local w = mp.readiedWeapon		w = w and w.object		local DMag = math.min(Mag(600), cf.charglim)	if DMag > 0 then
		local vec = tes3.getPlayerEyeVector()	if math.abs(vec.z) < 0.15 then vec.z = 0	vec = vec:normalized() end
		local wr = w and w.reach or 0.5
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vec, ignore = {p}}		local ref, hitd
		if hit then ref = N[hit.reference] and hit.reference end
		if ref then hitd = ref.position:distance(pp) else ref, hitd = L.Sector{d = 9000, lim = 500} end
		hitd = hitd and hitd - 30 or (hit and hit.distance) or 20000
		if (pass or ref) and hitd > wr*140 then
			local mc = (DMag + (P.acr8 and mp.isFalling and 0 or math.min(DMag,10))) * (P.alt10 and 1 or 1.5)
			local DD = DMag * (Cpow(mp,0,4,true) + (P.spd8 and 50 or 0))/2		local Dkoef = hitd/DD		if Dkoef < 1 then DD = DD * Dkoef		mc = mc * Dkoef	end
			if T.Dash.timeLeft then mc = mc * (1 + T.Dash.timeLeft/(P.atl8 and 10 or 3)) end	local stam = mc * ((P.end10 and 0.5 or 1) - (P.una10 and D.AR.u*0.02 or 0))
			if mc < mp.magicka.current then	local vk = math.max(-0.4 - vec.z, 0)/3
				V.d = vec*(DD/8 * (1 - vk))	V.dfr = 8	event.register("calcMoveSpeed", L.Dash)		tes3.playSound{sound="Spell Failure Destruction"}
				mp.animationController.weaponSpeed = dir == 3 and 0.4 or (dir == 1 and 0.5) or 0.6			V.daf = w and w.speed or 1		if not mp.isJumping then V.djf = true	mp.isJumping = true end
				G.CombatDistance.value = (DD + 50)/wr		--G.CombatAngleXY.value = math.clamp(50/DD, 0.05, 0.3)
				TFR(2, function() G.CombatDistance.value = 128		--G.CombatAngleXY.value = G.CombatAng
				end)
				Mod(mc)		mp.fatigue.current = math.max(mp.fatigue.current - stam, 0)
				if cf.m then tes3.messageBox("Charge! Dist = %d  Cost = %.1f  Time = %.1f   SlamK = %d%%", DD, mc, T.Dash.timeLeft or 0, vk*100) end
				V.dd = DD 	if T.Dash.timeLeft then T.Dash:cancel()	end		T.Dash = timer.start{duration = 3, callback = function() end}
				if P.blu12 and hit and hitd > 500 and Dkoef < 1 and w and w.type == 4 and dir == 2 and ad.attackSwing > 0.95 and vec.z < -1 + mp:getSkillValue(20)/(P.acr3 and 150 or 200) and mp.isFalling then
					local dmg = w.chopMax * (1 + mp.strength.current/200) * math.max(mp.readiedWeapon.variables.condition/w.maxCondition, P.arm2 and 0.3 or 0.1) * hitd/3000	local hitp = hit.intersection:copy()	local m
					timer.start{duration = 0.2/w.speed, callback = function() tes3.playSound{sound = table.choice({"endboom1", "endboom2", "endboom3"})}	local fdmg	local num = 0	--"fabBossLeft", "fabBossRight"
						for _, m in pairs(tes3.findActorsInProximity{position = hitp, range = 250}) do if m ~= mp then	num = num + 1
							fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true, resistAttribute = not (w.enchantment or w.ignoresNormalWeaponResistance) and 12 or nil}		L.CrimeAt(m)
							if cf.m then tes3.messageBox("Hammer Slam! Height = %d   %s (%d)  Dmg = %d/%d   Dist = %d", hitd, m.object.name, num, fdmg, dmg, hitp:distance(m.position)) end
						end end
					end}
				end
			end
		end
	end end
end end end		event.register("mouseButtonUp", MOUSEBUTTONUP)


-- animationAttackState всегда 0   Свинг ещё не определен.
local function ATTACKSTART(e) local a = e.mobile	local spd = e.attackSpeed		--local ar = e.reference		local dir = e.attackType		local ad = a.actionData		local wd = w and w.variables
local w = a.readiedWeapon	w = w and w.object 		local wt = w and (a == mp and W.wt or w.type) or -1			--local fiz = ad.physicalDamage	local wh = wd and wt ~= 11 and 100*wd.condition/w.maxCondition or 100
--local wt = w and w.type or -1
--if m.actorType == 1 or (m.object.biped or m.object.usesEquipment) then
--local m1 = (mp.isMovingForward or mp.isMovingBack)	local m2 = (mp.isMovingLeft or mp.isMovingRight)		local mov = m1 and (m2 and 3 or 1) or (m2 and 2 or 0)
--e.attackType = m1 and (m2 and 2 or 3) or (m2 and 1 or 2)

if w and wt < 11 then
	local max = math.max((2 - spd)/3, 0)		local str = a.strength.current
	spd = spd + (wt < 9 and not WT[wt].h1 and max/2 or 0) + max * ((a ~= mp or P[wt < 9 and "str16" or "str17"]) and 0.5 or 0.25) * 1.5*str/(str + 200)
end

e.attackSpeed = spd * (		(a == mp and 0.9 or 1)
+ a.speed.current/((a ~= mp or P.spd1) and 1000 or 2000)
+ a:getSkillValue(WT[wt].s)/((a ~= mp or P[WT[wt].p4]) and 1000 or 2000)
- (1 - math.min(mp.fatigue.normalized,1)) * ((a ~= mp or P.atl11) and 0.1 or 0.2)
- a.encumbrance.normalized * ((a ~= mp or P.atl12) and 0.1 or 0.2)
- (a == mp and math.max(D.AR.as - math.max(-mp.encumbrance.currentRaw,0)/2000, 0) or 0)		)


if a == mp and W.DWM then
	T.DWB = timer.start{duration = (P.bloc16 and 0.2 or 0.15) + mp:getSkillValue(0)/2000, callback = function() end}
end

if a ~= mp then	local ar = e.reference
	--e.attackSpeed = 2
	if wt < 9 then if cf.pvp and not AF[ar].part then L.DodM(ar, a) end
		--if a.isFalling then e.attackSpeed = math.min(e.attackSpeed, 1) end
	end
end

--tes3.messageBox("AtStart! (%s)  dir = %s  spd = %.3f -> %.3f", wt, e.attackType, spd, e.attackSpeed)
end		event.register("attackStart", ATTACKSTART)

-- вторая проверка идёт после attackHit но только если во время attackHit ad.hitTarget существует. Если ad.hitTarget нил то его можно назначить вручную и тогда цель будет искаться в процессе второго calcHitDetectionCone
local function CALCHITDETECTIONCONE(e) local a = e.attackerMobile	local w = a.readiedWeapon	w = w and w.object 		local wt = w and (a == mp and W.wt or w.type) or -1
	if wt < 9 then	local ad = a.actionData		local dir = ad.physicalAttackType		--local tr = e.target	
		e.reach = e.reach
		+ ((a ~= mp or P.agi3) and math.min(a.agility.current,100)/2000 or 0)
		+ ((a ~= mp or P[WT[wt].p7]) and 0.05 or 0)
		+ (a == mp and wt == -1 and (P.hand11 and 0 or -0.2) or 0)
		+ (dir == 3 and (a ~= mp or P.agi31) and 0.05 or 0)
		
		if a == mp then		W.rng = e.reach
			if dir == 1 then e.angleXY = (P.agi27 and 60 or 45) + (P.agi15 and 30 or 0)
			elseif dir == 2 then e.angleXY = P.agi27 and 30 or 20		if P.agi27 then e.angleZ = 60 end
			elseif dir == 3 then e.angleXY = P.agi27 and 20 or 15 end
		end
		--tes3.messageBox("Cone %s   AT = %s   Rea = %.3f  %d     Ang = %.3f   %.3f    %s", e.attacker, dir, e.reach, e.reach * 128, e.angleXY, e.angleZ, e.target or "")
	end
end		event.register("calcHitDetectionCone", CALCHITDETECTIONCONE)

-- Для ближнего боя хит это первое событие. Определяются таргет, направление атаки и свинг, НО физдамаг все еще старый на момент завершения события - он обновится сразу после события и уже учтет силу и прочность оружия
-- Свинг можно менять только для ближнего боя.	ad.physicalDamage бесполезно менять и для ближнего и для дальнего боя. В событии дамага ad.physicalDamage для дальнего боя отображается неверно.
local function CALCHITCHANCE(e) --local a = e.attackerMobile	local t = e.targetMobile	local ad = a.actionData
	e.hitChance = 100
--if L.ADIR[ad.physicalAttackType] then
--	if t == mp then L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * ad.physicalDamage/50, 0) end	-- Назначаем опыт доспехов для снарядов
--else
	--if a ~= mp then ad.attackSwing = math.clamp(ad.attackSwing, 0.5, 1) end		--a.animationController.weaponSpeed = a.animationController.weaponSpeed * (1.25 - sw/2)
--end
--	tes3.messageBox("HIT!  dir = %s  swing = %.2f  dmg = %.2f   spd = %.3f", ad.physicalAttackType, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed)
--	local pos = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150		local post = e.target.sceneNode:getObjectByName("Bip01 Head").worldTransform.translation
--	tes3.createReference{object = "4nm_boundstar", position = pos, cell = p.cell}	tes3.createReference{object = "4nm_boundstar", position = post, cell = p.cell, scale = 2}
end		if cf.hit then event.register("calcHitChance", CALCHITCHANCE) end


-- Первое событие для дальнего боя: менять свинг: он уже не изменится при хите, который идет после атаки. Для ближнего боя идет сразу после хита. Дамаг НЕ определен если не было события хита.
-- Можно менять ad.physicalDamage для ближнего боя и это сработает. Но ad.physicalDamage не поменяется для дальнего боя.
L.AD = {[1] = {"slashMin", "slashMax"}, [2] = {"chopMin", "chopMax"}, [3] = {"thrustMin", "thrustMax"}, [4] = {"chopMin", "chopMax"}, [5] = 1, [6] = 1, [7] = 1, [0] = {"chopMin", "chopMax"}}
local function ATTACK(e) local a = e.mobile		local ar = e.reference
local rw = a.readiedWeapon	local w = rw and rw.object	local wt = w and (a == mp and W.wt or w.type) or -1		local wd = rw and rw.variables		local ad = a.actionData		local dir = ad.physicalAttackType	
local WS = a.actorType == 0 and a.combat.current or a:getSkillValue(WT[wt].s)	    local WD

if a == mp then
	if w then	
		if wt == 10 then
			if T.Arb.timeLeft then ad.attackSwing = 0.5		T.Arb:cancel() else ad.attackSwing = 1 end
		elseif W.DWM and T.DWB.timeLeft then T.DWB:cancel() end
	end
else
	if dir == 4 then ad.attackSwing = wt == 10 and 1 or math.lerp(0.75, 1, ad.attackSwing)	--tes3.messageBox("AMM = %s  id = %s", a.readiedAmmoCount, a.readiedAmmo and a.readiedAmmo.object.id)
		if not a.readiedAmmo and a.readiedAmmoCount == 0 then a.object:reevaluateEquipment() 	a.readiedAmmoCount = 1		tes3.messageBox("AMMO FIX!  $s  (%s)", ar, a.readiedAmmoCount) end
		--if a.readiedAmmoCount == 0 then a.readiedAmmoCount = 1	if cf.m then tes3.messageBox("AMMO FIX!") end end		--cf.ammofix
	else ad.attackSwing = math.lerp(0.5, 1, ad.attackSwing)		if cf.pvp and not AF[ar].part then L.DodM(ar, a) end end
end
local sw = ad.attackSwing

--if a.actorType == 0 then WS = a.combat.current	if not w then WD = 10 * sw end			else WS = a:getSkillValue(WT[wt].s) end


if wt < 9 then	local Cond, ww
	if L.AD[dir] == 1 then WD = ar.object.attacks[1].max * sw * (1 + math.max(1 - a.health.normalized, 0)/2)
	elseif w then Cond = wd.condition/w.maxCondition		Cond = Cond > 1 and Cond or math.lerp((a ~= mp or P.arm2) and 0.3 or 0.2, 1, Cond)		ww = w.weight
		WD = math.lerp(w[L.AD[dir][1]], w[L.AD[dir][2]], sw) * Cond * (ww == 0 and 1 + a:getSkillValue(13)*((a ~= mp or P.con8) and 0.003 or 0.002) or 1)
	else WD = sw * (a.werewolf and 40 or 5) end
	--	local gau = (a ~= mp or P.hand7) and tes3.getEquippedItem{actor = ar, objectType = tes3.objectType.armor, slot = dir == 3 and 6 or 7} or nil		gau = gau and gau.object.weight*(0.3 + WS/500) or 0
	
	local Kstr = (WT[wt].h1 and 100 or 140) + a.strength.current * (((a ~= mp or P.str1) and 0.2 or 0.1) + (WT[wt].h1 and 0 or 0.1))
	local Kskill = WS * (((a ~= mp or P[WT[wt].p1]) and 0.2 or 0.1) + ((a ~= mp or P[WT[wt].h1 and "agi5" or "str2"]) and 0.1 or 0.05))
	local Kbonus = a.attackBonus/5 + (a == mp and (P.str15 and 20 * math.max(1 - mp.health.normalized, 0) or 0) or ar.object.level)
	local Kstam = math.min(math.lerp(((a ~= mp or P.end1) and 0.4 or 0.3) + ((a ~= mp or P[WT[wt].p2]) and 0.1 or 0), 1, a.fatigue.normalized*1.1), 1)


	if a == mp and w and MB[cf.mbmet] == 128 then	if P.mark13 then Kbonus = Kbonus + 20 end
		local dmg = math.max(math.max(w.chopMax, w.thrustMax) * Cond, ww/3)
		local Kin = P.alt26 and math.min(mp.willpower.current/10 + mp:getSkillValue(0)/5, cf.metlim) * sw or 0	local mc = 0
		if Kin > 0 then mc = Kin/(P.alt17 and 6 or 4)		if mp.magicka.current > mc then Mod(mc)	Kin = Kin * (Cpow(mp,0,0,true) + (P.alt16 and 50 or 0))/200 else Kin = 0	mc = 0 end end
		W.acs = 1000 + 2000* Kin/(ww+10) + ((a.strength.current*(WT[wt].h1 and 1 or 1.25)*(P.str12 and 1.5 or 1))/(ww+10))^0.5 * 500 * sw * Kstam
		W.metd = dmg * (100 + Kskill + Kbonus)/100
		wd.condition = math.max(wd.condition - 1, 1)		W.met = tes3.dropItem{reference = p, item = w, itemData = wd}		if W.DWM then L.DWMOD(false) end
		mp.fatigue.current = math.max(mp.fatigue.current - ww, 0)
		if cf.m30 then tes3.messageBox("Throw spd %d (%d%%)  dmg %.1f (%d + %d%% skill + %d%% bon)  sw = %.2f  Kin %.1f (%.1f cost)", W.acs, 4*W.acs/(W.acs/100+100), W.metd, dmg, Kskill, Kbonus, sw, Kin, mc) end
		tes3.applyMagicSource{reference = p, name = "4nm_met", effects = {{id = 610, rangeType = 2}}}	ad.physicalDamage = 0	return
	end
	
	ad.physicalDamage = WD * (Kstr + Kskill + Kbonus)/100 * Kstam
	if cf.m30 then tes3.messageBox("FizD %.1f = %.1f * (%d%% str + %d%% sk + %d%% bon) * %d%% stam   swing = %.2f  spd = %.3f  tar = %s",
	ad.physicalDamage, WD, Kstr, Kskill, Kbonus, Kstam*100, sw, a.animationController.weaponSpeed, e.targetReference) end
end
--tes3.messageBox("ATA! %s (%s)  dir = %s  swing = %.2f dmg = %.2f  spd = %.3f  tar = %s", ar, wt, ad.physicalAttackType, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed, e.targetReference)
end		event.register("attack", ATTACK)

--Стамина отнимается сразу перед этим эвентом
local function ATTACKHIT(e) local a = e.mobile	local ar = e.reference		local ad = a.actionData		local t = e.targetMobile
local w = a.readiedWeapon	local ob = w and w.object	local wt = w and (a == mp and W.wt or ob.type) or -1

--if a ~= mp then local d = ad.physicalAttackType		local mov = ((a.isMovingForward or a.isMovingBack) and 1 or 0) + ((a.isMovingLeft or a.isMovingRight) and 2 or 0)	local new = L.WCO[ob and (ob.isOneHanded and 1 or 2) or 0][d][mov]
--	if new then ad.animationAttackState = 0		ad.physicalAttackType = new			tes3.messageBox("Ideal")	--elseif L.COMOV[mov] ~= d then MB[1] = 0		ad.animationAttackState = 0			tes3.messageBox("Half") end
--end

--if a ~= mp then L.Dod2(ar, a) end

--a.animationController.weaponSpeed = -1


if a.fatigue.normalized < 1 then local stret = a ~= mp and 10 or ((P[WT[wt].p3] and a:getSkillValue(WT[wt].s)/20 or 0) + (P.end6 and math.min(a.endurance.current/20, 5) or 0))
	if stret > 0 then a.fatigue.current = a.fatigue.current + stret end
end

if a == mp then		--ad.attackSwing = math.min(ad.attackSwing * a.animationController.weaponSpeed, 1)
	if wt < 9 and not t then
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition() + V.down10, direction = tes3.getPlayerEyeVector(), maxDistance = 135 * W.rng, ignore = {p}}
		if hit then local ref = hit.reference	local mob = ref and ref.mobile		local Mat, dir
			if mob then Mat = ref.object.blood == 2 and "Metal" or "Dirt"
				if not ad.hitTarget and not mob.isDead then ad.hitTarget = mob		t = mob
					--tes3.messageBox("tar = %s   hitt = %s", ad.target and ad.target.reference, ad.hitTarget and ad.hitTarget.reference)
				end
			else local tex = hit.object.texturingProperty	tex = tex and tex.maps[1]	tex = tex and tex.texture	tex = tex and tex.fileName		if tex then		local result = L.TCash[tex]
				if not result then result = tex:lower():gsub("/", "\\")
					if result:find("^textures\\") then result = result:sub(10, -5) elseif result:find("^data files\\textures\\") then result = result:sub(21, -5) else result = result:sub(1, -5) end
					L.TCash[tex] = result
				end
				Mat = L.TD[result]
			end end
			if not Mat and ref and string.startswith(ref.object.mesh:lower(), "f\\flora") then Mat = "Wood" end			--tes3.messageBox("%s", ref.object.mesh:lower())
			Mat = L.MAT[Mat] or "Stone"
		
			if L.Mat0[Mat] then dir = ("data files\\sound\\impact\\%s\\"):format(Mat) elseif wt == -1 then dir = "data files\\sound\\impact\\Hand\\" else dir = ("data files\\sound\\impact\\%s\\%s\\"):format(Mat, WT[wt].iso) end
			tes3.playSound{reference = p, volume = cf.volimp/100, soundPath = ("%s%s"):format(dir:sub(18), L.RandomFile(dir))}
			if w then w.variables.condition = math.max(w.variables.condition - ad.physicalDamage * L.MatD[Mat] * (P.arm3 and 0.5 or 1), 0)
				if L.MatSpark[Mat] then tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = hit.intersection} end
			end		--tes3.messageBox("%s   mat = %s", dir, Mat)
		end
	end
	if w then 
		if W.f == 1 and (wt > 8 or not t) then tes3.applyMagicSource{reference = p, source = ob.enchantment, fromStack = w} end
		if P.str8 and ob.isTwoHanded and ad.physicalAttackType == 1 and ad.attackSwing > 0.95 then local dist = 150 * ob.reach
			local dmg = ad.physicalDamage/2		local fdmg = 0	local num = 0
			for _, m in pairs(tes3.findActorsInProximity{reference = p, range = dist}) do if m ~= mp and m ~= t and tes3.getCurrentAIPackageId(m) ~= 3 then	num = num + 1
				if m.actionData.animationAttackState == 4 and m.readiedWeapon and m.readiedWeapon.object.type < 9 then m.actionData.animationAttackState = 0
					local tab = L.PSO[WT[wt].pso][WT[m.readiedWeapon.object.type].pso]		tes3.playSound{reference = m.reference, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2])), volume = cf.volimp/100}
				else fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true, resistAttribute = not (ob.enchantment or ob.ignoresNormalWeaponResistance) and 12 or nil}		L.CrimeAt(m) end
				if cf.m then tes3.messageBox("Round attack! %s (%d)  Dmg = %d/%d",  m.object.name, num, fdmg, dmg) end
			end end
		--elseif wt > 8 then M.CombK.text = ("%s"):format(mp.readiedAmmoCount)
		end
	end
elseif wt < 9 and not ad.hitTarget and ad.target == mp then ad.hitTarget = mp	t = mp		--tes3.messageBox("New TARGET! ")
end



if ar.data.CW then local rt = (a ~= mp and 2) or (not D.CWdis and not (cf.smartcw and wt > 8) and (D.CWm and 2 or (t and t.playerDistance < 192 and 1)))
	if rt == 2 then timer.delayOneFrame(function() L.CWF(ar, 2, 1.5) end) elseif rt == 1 then L.CWF(ar, 1, 1) end
end

if t and wt < 9 then
	local chance = 100 + a.agility.current - a.blind - (t.chameleon + t.invisibility*300)*((t ~= mp or P.snek7) and 0.5 or 0.25)
	if t == mp then		local extra = 0		local sanct = t.sanctuary/5 * (1+(P.una11 and D.AR.u*0.01 or 0))	local Tagi = t.agility.current
		local dodge = (P.lig8 and D.AR.l > 19 and t.isRunning or ((t.isMovingLeft or t.isMovingRight) and not t.isMovingForward)) and
		math.min(math.min(t.fatigue.normalized,1) * (D.AR.dk > 1 and D.AR.dk or math.min(D.AR.dk + math.max(-mp.encumbrance.currentRaw,0)/1000, 1))
		* (Tagi*(P.agi20 and 0.3 or 0.2) + (P.luc3 and t.luck.current/10 or 0)) + sanct + (P.acr6 and t.isJumping and t:getSkillValue(20)/5 or 0), 100) or 0
		local DodK = T.Dod.timeLeft and (T.Dod.timeLeft - (P.spd17 and 2.3 or 2.5))/(P.spd17 and 0.7 or 0.5) or 0
		if DodK > 0 then extra = (Tagi/(1+Tagi/400)/(P.agi2 and 8 or 16) + (P.lig2 and D.AR.l * t:getSkillValue(21)/100 or 0) + (P.agi23 and W.DWM and 10 or 0) + sanct) * (P.spd2 and 2 or 1) * DodK
			L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * ad.physicalDamage/50, 0)		mp:exerciseSkill(21, D.AR.l/100)	mp:exerciseSkill(17, D.AR.u/100)
		end
		chance = chance - dodge - extra
		if cf.m3 and dodge + extra > 0 then tes3.messageBox("Hit chance = %d%%   %d passive   %d active (%d%%)", chance, dodge, extra, DodK*100) end
	else chance = chance - t.sanctuary/2 end
	if chance < math.random(100) then ad.physicalDamage = 0 end
end
--tes3.messageBox("ATHIT  ref = %s  wt = %s  dir = %s  swing = %.2f  dmg = %.2f  spd = %.3f  tar = %s %s %s", ar, wt, ad.physicalAttackType, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed,
--e.targetMobile and e.targetMobile.reference, ad.target and ad.target.reference, ad.hitTarget and ad.hitTarget.reference)
end		event.register("attackHit", ATTACKHIT)


local function CALCBLOCKCHANCE(e)	local a, t = e.attackerMobile, e.targetMobile		local s = t:getSkillValue(0) 	local activ = t.actionData.animationAttackState == 2
local wt = a.readiedWeapon		wt = wt and (a == mp and W.wt or wt.object.type) or -1
local ang = t:getViewToActor(a)			local max = (ang >= 0 and (activ and 30 or 20) or (activ and -30 or -60)) * ((t ~= mp or P.bloc9) and 1.5 or 1)
local Kang = math.clamp((1 - ang/max)*((t ~= mp or P.bloc9) and 1.5 or 1), 0, 1)
local Kstam = math.min(math.lerp(((t ~= mp or P.bloc19) and 0.5 or 0.3), 1, t.fatigue.normalized), 1)
local Ktar = (t == mp and (activ and (P.bloc1 and 100 or 50) or 0) or 100) + (s/2 + t.agility.current/5 + t.luck.current/10) * ((t ~= mp or P.bloc20) and 1.25 or 1)
local Katak = (a:getSkillValue(WT[wt].s)/2 + a.agility.current/5 + a.luck.current/10) * (((a ~= mp or P.agi28) and 1.25 or 1) + (1 - a.actionData.attackSwing))
local bloc = Ktar * Kstam * Kang - Katak		local cost = 0
if bloc > math.random(100) then e.blockChance = 100
	local SH = t.readiedShield		cost = SH.object.weight * math.max(0.5 - s/((t ~= mp or P.bloc3) and 250 or 500), 0.1)		if cost > 0 then t.fatigue.current = math.max(t.fatigue.current - cost, 0) end
	if t == mp then L.UpdShield(SH)
		L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * a.actionData.physicalDamage/50, 0)
		if T.CST.timeLeft then T.CST:reset() elseif P.bloc4 then T.CST = timer.start{duration = 0.4 + (P.bloc8 and (t.agility.current + s)/1000 or 0), callback = function() end} end
	end
else e.blockChance = 0 end
if cf.m3 then tes3.messageBox("%s %d%% = %d tar * %d%% stam * %d%% ang (%d/%d) - %d atk  Stam cost +%d", e.blockChance == 100 and "BLOCK!" or "block", bloc, Ktar, Kstam*100, Kang*100, ang, max, Katak, cost) end
end		event.register("calcBlockChance", CALCBLOCKCHANCE)


-- Вызывается после атаки для ближнего боя и после хита для дальнего. Можно менять слот, по которому попадет удар. Далее идёт дамаг. НЕ вызывается если попали по щиту или кричеру.
local function CALCARMORPIECEHIT(e) local r = e.reference	local s = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = e.slot}
if not s and e.fallback then s = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = e.fallback} end
arm = s and s.object:calculateArmorRating(e.mobile) or 0		arp = s and s.object.weightClass or 3
--e.slot = 0		e.projectile
if r == p then local a = e.attackerMobile 	if a then L.skarm = math.max((a.object.level * 4 + 20 - p.object.level/2) / (a.object.level + 20) * a.actionData.physicalDamage/50, 0) end end
--tes3.messageBox("ARMor! ref = %s  slot = %s  fall = %s  atak = %s  dmg = %.2f", r, e.slot, e.fallback, e.attacker, e.attackerMobile.actionData.physicalDamage)
end		event.register("calcArmorPieceHit", CALCARMORPIECEHIT)



local function DAMAGE(e) local source = e.source	if source == "attack" then local a = e.attacker	local t = e.mobile	local ar = e.attackerReference	local tr = e.reference	local ad = a.actionData		local tad = t.actionData
local rw = a.readiedWeapon		local pr = e.projectile		local Arm = t.armorRating		local Mult, Kstam, Kperk, Kbonus, Kdash = 100, 1, 0, 0, 0
local WS, FD		local w = pr and pr.firingWeapon or (rw and rw.object)	local wt = w and (not pr and a == mp and W.wt or w.type) or -1			local magw, prvel, velk
local sw = ad.attackSwing	 local dir = ad.physicalAttackType		local Agi = a.agility.current		local Tagi = t.agility.current		local bid = ar.baseObject.id
local BaseHP = t.health.base	local fat = math.min(t.fatigue.normalized,1)
if t.actorType == 0 then arm = t.shield		arp = nil	end
if a.actorType == 0 then WS = a.combat.current		if not w then Kperk = (1 - a.health.normalized) * WS/2 end
else WS = a:getSkillValue(WT[wt].s)	end
local Armult = 1 - (pr and (arp == 2 and (t ~= mp or P.hev14) and -0.2 or 0) or (w and math.min(w.weight,50)/((a ~= mp or P.str11) and 100 or 200) or 0))

if pr then magw = (pr.reference.object.ignoresNormalWeaponResistance or pr.reference.object.enchantment) and 100 or 0
	prvel = pr.velocity:length()	velk = 4*prvel/(prvel/100+100)
	FD = pr.damage * velk/100
else
	if L.AD[dir] == 1 then 	magw = 50 elseif w then magw = (w.ignoresNormalWeaponResistance or w.enchantment) and 100 or 0 end
	Kbonus = a.attackBonus/5 + (a == mp and 0 or ar.object.level)
	Kdash = a == mp and (T.Dash.timeLeft or 0) > 2 and V.dd/(P.str9 and 50 or 100) or 0
	Kstam = math.min(math.lerp(((a ~= mp or P.end1) and 0.4 or 0.3) + ((a ~= mp or P[WT[wt].p2]) and 0.1 or 0), 1, a.fatigue.normalized*1.1), 1)
	FD = ad.physicalDamage
end

local Res = math.max(t.resistNormalWeapons, -100)	local Norm
if Res > 0 then Norm = 1 - math.clamp(Res - (magw or 0), 0, 100)/100 else Norm = 1 - Res/100 end
--if Res > 0 then Norm = magw and 1 or (1 - math.min(Res/(100 + Res/2), 1)) else Norm = 1 - Res/100 end


local as = (a.isMovingForward and wt < 9 and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and wt < 9 and 3) or 0
local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0
local hs = 100 + (WS + a.strength.current + Agi)/((a ~= mp or P.str13) and 10 or 20) + (as == 1 and (a ~= mp or P.str3) and 20 or 0) + (a == mp and math.min(com, G.maxcomb) * (P.agi9 and 10 or 5) or 0)
+ ((a ~= mp or P.str4 and sw > 0.95) and 20 or 0) + (ts == 1 and (not (t == mp and P.med10 and D.AR.m > 19) and 30 or 0) - (arp == 1 and (t ~= mp or P.med8) and t:getSkillValue(2)/5 or 0) or 0)
- (arp == 2 and (t ~= mp or P.hev8) and t:getSkillValue(3)/5 or 0) - (t == mp and P.hev12 and D.AR.h or 0)
- (t.endurance.current)/((t ~= mp or P.end5) and 5 or 10) - Tagi/((t ~= mp or P.agi26) and 5 or 10) - (ts == 0 and (t ~= mp or P.str5) and t.strength.current/10 or 0)


local CritC = (pr and a.attackBonus/5 + (a == mp and 0 or ar.object.level) or Kbonus)
+ Agi/((a ~= mp or P.agi1) and 10 or 20) + WS/((a ~= mp or P[WT[wt].p6]) and 10 or 20) + ((a ~= mp or P.luc1) and a.luck.current/20 or 0) + (as == 1 and (a ~= mp or P.spd3) and 10 or 0)
+ (ts == 1 and ((t == mp and P.med10 and D.AR.m > 19 and 0 or 10) + ((t ~= mp or P.agi7) and 0 or 10)) or 0) + (t == mp and arp == 3 and math.max(20 - t:getSkillValue(17)/(P.una13 and 5 or 10), 0) or 0)
+ (a == mp and math.min(com, G.maxcomb) * (P.agi6 and 5 or 3) + (wt == 2 and P.long10 and Kdash/2 or 0) + (wt < 9 and a.isJumping and P.acr4 and a:getSkillValue(20)/10 or 0) - 10 or 10)
- (t.endurance.current + Tagi)/((t ~= mp or P.end3) and 20 or 40) - ((t ~= mp or P.luc2) and t.luck.current/20 or 0) - arm/10 - t.sanctuary/10
+ (1 - fat)*((a ~= mp or P.agi11) and 20 or 10) - (t == mp and ts == 0 and P.hev11 and D.AR.h or 0)
- (arp == 0 and ts ~= 0 and (t ~= mp or P.lig7) and t:getSkillValue(21)/10 or 0) - (arp == 1 and ts == 3 and (t ~= mp or P.med7) and t:getSkillValue(2)/10 or 0) - (arp == 2 and (t ~= mp or P.hev7) and t:getSkillValue(3)/10 or 0)

local dist = 0
if w then
	if a ~= mp or P[WT[wt].p] then
		if wt > 8 then dist = ar.position:distance(tr.position)
			if wt == 9 then Kperk = dist * WS/20000 -- Луки 5% за каждую 1000 дистанции
			elseif wt == 10 then Kperk = WS * ((a ~= mp or P.mark9) and math.max(1000 - dist,0)/5000 or 0)		Armult = Armult - WS*0.003
				if a ~= mp or P.mark9 then hs = hs + WS * math.max(3000 - dist,0)/6000 end		--pr.attackSwing
			elseif wt == 11 then AF[ar].met = math.min((AF[ar].met or -1) + 1, (a ~= mp or P.mark10) and 10 or 5)	Kperk = AF[ar].met * WS/20
				if AF[ar].mettim then AF[ar].mettim:reset() else AF[ar].mettim = timer.start{duration = a == mp and 1 + (P.mark8 and WS/200 or 0) or 2 + WS/100, callback = function()
				if AF[ar] then AF[ar].met = -1		AF[ar].mettim = nil end end} end
			end
		else
			if wt > 6 then AF[ar].axe = math.min((AF[ar].axe or -1) + 1, (a ~= mp or P.axe10) and 10 or 5)		Kperk = AF[ar].axe * WS/20		if a ~= mp or P.axe7 then CritC = CritC + AF[ar].axe * WS/50 end
				if not AF[ar].axetim then AF[ar].axetim = timer.start{duration = a == mp and 1 + (P.axe11 and WS/200 or 0) or 2 + WS/100, iterations = -1, callback = function(te)
				if not AF[ar] then te.timer:cancel() else AF[ar].axe = AF[ar].axe - 1		if AF[ar].axe < 0 then te.timer:cancel()	AF[ar].axetim = nil end end end} end
			elseif wt == 6 or wt == -2 then Kperk = (1 - fat) * WS * 0.3
				if dir == 3 and (a ~= mp or P.spear11 and sw > 0.95) then CritC = CritC + 10 end
			elseif wt == 5 or wt == -3 then Kperk = math.min(a.magicka.normalized, 1) * WS * 0.3
			elseif wt > 2 then hs = hs + WS/((a ~= mp or P.blu7) and 2 or 4)		Armult = Armult - WS*0.003
			elseif wt > 0 then if (AF[ar].long or 0) < 2 then AF[ar].long = (AF[ar].long or 0) + 1 else AF[ar].long = 0	Kperk = WS/2		if (a ~= mp or P.long12) then hs = hs + WS/2		CritC = CritC + WS/10 end end
				if AF[ar].longtim then AF[ar].longtim:reset() else AF[ar].longtim = timer.start{duration = a == mp and 0.8 + (P.long7 and WS/250 or 0) or 1.5 + WS/200, callback = function()
				if AF[ar] then AF[ar].long = 0		AF[ar].longtim = nil end end} end
			elseif wt == 0 then Kperk = (1 - t.health.normalized) * WS * 0.3	if a ~= mp or P.short11 then CritC = CritC + (1 - fat) * WS/5 end
				if a == mp and P.short10 and sw < 0.5 then mp.animationController.weaponSpeed = 1000000 end		--ad.animationAttackState = 0
			end
		end
	end
	if (a ~= mp or P.bloc11) and AF[tr].part then	local bls = a:getSkillValue(0)	Kperk = Kperk + bls*0.2		if a ~= mp or P.bloc12 then CritC = CritC + bls/10 end	end
end


if a == mp then
	if not R[tr] or not R[tr].cm then if pr then
		if P.mark14 and math.max(math.abs(t:getViewToActor(mp)),50) * dist * (mp.isSneaking and 2 or 1) > (P.snek8 and 50000 or 100000) then
			Mult = Mult + 50		Armult = Armult - (P.snek13 and 0.3 or 0.1)			mp:exerciseSkill(19, 1 + tr.object.level/10)
		end
	elseif math.abs(t:getViewToActor(mp)) > (P.snek8 and 135 or 150) then	Armult = Armult - (P.snek13 and 0.3 or 0.1) - (wt == 0 and 0.2 or 0)
		Mult = Mult + 100 + (P.snek3 and mp.isSneaking and 100 or 0) + ((wt == 0 and P.short12) and 100 or 0)	mp:exerciseSkill(19, 1 + tr.object.level/5)
	end end
	if ((P.con12 and t.object.type == 1) or (P.con13 and t.object.type == 2)) then Mult = Mult + mp:getSkillValue(13)/10 end
	if w then
		if wt < 9 then
			if T.Comb.timeLeft then		local maxcom = (P[WT[wt].pc] and 4 or 3) + math.floor(WS/50) + (P.spd14 and W.DWM and 1 or 0)
				if dir == last then com = math.max(com - 2, 0) elseif dir == pred and com > 2 then com = com - 1 elseif dir ~= pred then com = math.min(com + 1, maxcom) end
				M.CombK.text = ("%s/%s"):format(com, maxcom)		T.Comb:reset()	pred = last		last = dir
			else last = dir		T.Comb = timer.start{duration = (P.spd4 and 2 or 1.5) + (WT[wt].s == 5 and P.long11 and 0.5 or 0), callback = function() com = 0	last = nil	pred = nil	M.CombK.text = "" end} end
		end
		if T.CST.timeLeft then local bls = a:getSkillValue(0)		Kperk = Kperk + bls*0.2	if P.bloc5 then hs = hs + bls/2		CritC = CritC + bls/10 end		if cf.m3 then tes3.messageBox("Counterstrike!") end end
	end
else
	if t ~= mp and L.Summon[bid] then Mult = Mult - 30 end
	local MagAt = L.CMAG[bid]		if MagAt and MagAt[2] > math.random(100) then tes3.applyMagicSource{reference = ar, source = B[MagAt[1]]} end
end


local tw = t.readiedWeapon		local two = tw and tw.object		local twt = two and two.type or -1		local tsh = t.readiedShield	
if tad.animationAttackState == 4 then
	if pr and t == mp and P.bloc18 and tw and twt < 9 then	local ang = math.abs(mp:getViewToPoint(pr.position))
		local bloc = (t:getSkillValue(0) + t:getSkillValue(WT[twt].s)/2 + Tagi/5 + t.luck.current/10) * fat * math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) - WS/2 - Agi/5
		if cf.m3 then tes3.messageBox("Weapon block projectile chance = %d%%   Angle = %d", bloc, ang) end
		if ang < 20 and bloc > math.random(100) then
			mp:exerciseSkill(0, 2)		tes3.playSound{reference = p, soundPath = ("Fx\\par\\1_%s.wav"):format(math.random(4)), volume = cf.volimp/100}
			tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = pr.position}
			G.KOGMST.value = 100	e.damage = 0	 return
		end
	elseif (a == mp and not D.nopar or (a ~= mp and cf.par)) then
		--if t == mp then tes3.messageBox("Angle %d ", math.abs(mp:getViewToActor(a))) end
		if wt < 9 and w and tw and twt < 9 then		local TFD = tad.physicalDamage
			local Tdash = (t == mp and (T.Dash.timeLeft or 0) > 2 and V.dd/(P.str9 and 50 or 100) or 0) * 3
			local PK1 = (w.weight*5 + WS + a.strength.current + Agi + a:getSkillValue(0) + Kbonus*2 + Kdash*2) * (a == mp and sw or 0.3 + sw) * Kstam
			* ((WT[wt].h1 and 0.5 or 0.75) + ((a ~= mp or P.bloc10) and 0.25 or 0) + ((a ~= mp or P[WT[wt].p9]) and 0.25 or 0))
			local PK2 = (two.weight*10 + t:getSkillValue(WT[twt].s) + t.strength.current + Tagi + t.attackBonus + Tdash)
			* ((WT[twt].h1 and 0.5 or 0.75) + ((t ~= mp or P.str6) and 0.25 or 0)) * tad.attackSwing * (t == mp and math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) or 1)
			local park = PK1 / PK2
			rw.variables.condition = math.max(rw.variables.condition - TFD / ((a ~= mp or P.arm3) and 20 or 10), 0)
			tw.variables.condition = math.max(tw.variables.condition - FD / ((t ~= mp or P.arm3) and 20 or 10), 0)
			
			if t == mp and park < 1.2 and G.TR.tr5 then
				tad.physicalDamage = 0
			else
				if park > 0.8 then
					local min = (a == mp and (P.bloc14 and 0.2 or 0.1)) or (t == mp and (P.agi26 and 0.1 or 0.2)) or 0.2
					local max = (a == mp and (P.bloc14 and 1 or 0.5)) or (t == mp and (1 - math.min(Tagi,100)/(P.agi26 and 200 or 500))) or 1
					AF[tr].part = timer.start{duration = math.clamp(park - 1, min, max), callback = function() if AF[tr] then if park < 2 then
						if t == mp then if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
						else tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}		tad.animationAttackState = 0 end
					end AF[tr].part = nil end end}
					
					if t == mp then MB[1] = 0		tad.animationAttackState = 0	
					else tad.animationAttackState = 0	
						tes3.playAnimation{reference = tr, group = tes3.animationGroup[(t.actorType == 1 or t.object.biped) and table.choice{"hit2", "hit3", "hit4", "hit5"} or "hit1"], loopCount = 0}		DOM[t] = nil
					end
					
					if a == mp and P.sec7 then tes3.applyMagicSource{reference = p, name = "Parry", effects = {{id = 510, min = 30, max = 30, duration = 1}}} end
				else tad.physicalDamage = TFD * (1 - park) end
			end
			
			local parcost = ((a ~= mp or P.bloc13) and 10 or 20) * math.min(PK2/PK1, 1)		a.fatigue.current = math.max(a.fatigue.current - parcost, 0)
			
			if cf.m3 then tes3.messageBox("Par! %s (%s)    %.2f = %d/%d    fiz = %.2f/%.2f    spd = %.2f   Cost = %d", ar.baseObject.name, tad.animationAttackState, park, PK1, PK2, FD, TFD,
			t.animationController.weaponSpeed, parcost) end
			if t ~= mp then for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end end
			local tab = L.PSO[WT[wt].pso][WT[twt].pso]		tes3.playSound{reference = (a==mp or t==mp) and p or ar, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2])), volume = cf.volimp/100}
			
			local vfxp = (ar.position + tes3vector3.new(0,0,a.height*0.9) + tr.position + tes3vector3.new(0,0,t.height*0.9)) / 2
			tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = vfxp}
			
			if a == mp then L.skw = math.max((tr.object.level * 4 + 20 - p.object.level/2) / (tr.object.level + 20) * TFD/200 * math.min(park,2), 0)	L.skarm = L.skw*2	mp:exerciseSkill(0, 1)
				if not P.bloc15 then com = math.max(com - 1, 0)		M.CombK.text = ("%s"):format(com) end
			end
			
			G.KOGMST.value = 100	e.damage = 0	 return
		end
	end
elseif t == mp and tad.animationAttackState == 2 and W.DWM and wt < 9 and w then
	if T.DWB.timeLeft and math.abs(mp:getViewToActor(a)) < (P.bloc17 and 30 or 20) then		local bls = t:getSkillValue(0)		local WTL = WT[W[W.WL.id] or W.WL.type]
		local PK1 = (W.WL.weight*5 + t:getSkillValue(WTL.s) + t.strength.current + Tagi + bls) * math.lerp((P.bloc19 and 0.6 or 0.3), 1, fat) * ((P.bloc10 and 0.75 or 0.5) + (P[WTL.p9] and 0.25 or 0))
		local PK2 = (w.weight*10 + WS + a.strength.current + Agi + Kbonus*3) * math.random(80,120)/100 * (WT[wt].h1 and 0.75 or 1)
		local park = PK1 / PK2
		local parcost = (P.bloc13 and 10 or 20) * math.min(PK2/PK1, 2)		mp.fatigue.current = math.max(mp.fatigue.current - parcost, 0)
		W.DL.condition = math.max(W.DL.condition - FD / (P.arm3 and 10 or 5), 0)
		local tab = L.PSO[WT[wt].pso][WTL.pso]		tes3.playSound{reference = p, soundPath = ("Fx\\par\\%s_%s.wav"):format(tab[1], math.random(tab[2])), volume = cf.volimp/100}
		L.skarm = math.max((ar.object.level * 4 + 20 - p.object.level/2) / (ar.object.level + 20) * FD/100 * math.min(park,2), 0)	mp:exerciseSkill(0, 1)
		if cf.m3 then tes3.messageBox("DW Block!  %.2f = %d/%d   cost = %d   time left = %.2f   angle = %d", park, PK1, PK2, parcost, T.DWB.timeLeft, math.abs(mp:getViewToActor(a))) end
		if park > 0.8 then
			if T.CST.timeLeft then T.CST:reset() elseif P.bloc4 then T.CST = timer.start{duration = 0.4 + (P.bloc8 and (Tagi + bls)/1000 or 0), callback = function() end} end
			G.KOGMST.value = 100	e.damage = 0	AF[p].nostun = true		return
		else FD = FD * (1 - park) end
	elseif cf.m3 then tes3.messageBox("No DW block  time left = %.2f   angle = %d", T.DWB.timeLeft or 0, math.abs(mp:getViewToActor(a))) end
end


local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + ((a ~= mp or P.agi8) and 10 or 0) + ((a ~= mp or P[WT[wt].p5]) and 20 or 0)
if Kcrit > cf.crit then tes3.playSound{reference = tr, sound = "critical damage"} end end

Mult = Mult - math.min(((ts == 3 or (t == mp and P.hev10 and ts == 0 and D.AR.h > 19)) and math.min((Tagi + t.endurance.current)/((t ~= mp or P.end2) and 10 or 20)
+ ((t ~= mp or P.bloc2) and tsh and t:getSkillValue(0)/20 or 0), 30) or 0)
+ (as == 3 and a == mp and math.max(50 - (WS + Agi)/(P.agi19 and 10 or 20) - (wt == 6 and P.spear10 and 10 or 0), 0) or 0)
+ (not tsh and (not tw and (t.actorType ~= 0 and (t ~= mp or P.hand20) and (t:getSkillValue(26)/10 + Tagi/20) or 0) or
((t ~= mp or P.hand9 and not W.DWM) and WT[twt].h1 and (t:getSkillValue(26) + Tagi)/20 or 0)) or 0), 50)	
+ (L.AG[tad.currentAnimationGroup] and 20 + ((a~= mp or P.str14) and 30 or 0) or 0)

local stam = (t == mp and (P.end12 and 1 or 2) + ((ts == 3 or (P.hev10 and ts == 0 and D.AR.h > 19)) and (P.med10 and D.AR.m > 19 and 0 or 1) or 0)
- (ts == 0 and P.hev9 and arp == 2 and mp:getSkillValue(3)/100 or 0) - (ts ~= 0 and P.lig3 and arp == 0 and mp:getSkillValue(21)/200 or 0) - (P.med9 and D.AR.m*0.02 or 0) or 0)
+ (wt == 4 and (a ~= mp or P.blu11 and dir == 1 and sw > 0.95) and 1 or 0)

DMG = FD * (Mult + Kperk + Kcrit + Kdash)/100		local Karm = DMG / (DMG + Arm * math.max(Armult,0))			DMG = DMG * Karm * Norm
hs = (a == mp and 500*DMG/BaseHP or math.max(5*DMG, 500*DMG/BaseHP)) * (hs + Kcrit/2)/100

if pr and tsh then	local ang = t:getViewToPoint(pr.position)		if (t ~= mp or tad.animationAttackState == 2) and math.abs(ang) < 45 or (ang > -90 and ang < 0) then
	local bloc = (t:getSkillValue(0) + Tagi/5 + t.luck.current/10) * fat * ((t ~= mp or P.bloc6) and 1.5 or 1) * ((t ~= mp or tad.animationAttackState == 2) and 1 or 0.3) - WS/2 - Agi/5
	if cf.m3 then tes3.messageBox("Block projectile chance = %d%%   Ang = %d", bloc, ang) end
	if bloc > math.random(100) then tsh.variables.condition = math.max(tsh.variables.condition - DMG/2, 0)
		if t == mp then mp:exerciseSkill(0, 1)	L.UpdShield(tsh) end	if tsh.variables.condition < 0.1 then t:unequip{item = tsh.object} end
		G.KOGMST.value = 100	e.damage = 0		AF[tr].nostun = true		tes3.playSound{reference = tr, soundPath = ("Fx\\par\\sh_%s.wav"):format(math.random(4))}		return
	end
end end

local Dred, smc, trauma = 0, 0, 0	local KSM = tr.data.e508 or 0		local LLM = ar.data.e509

if KSM > 0 and t.magicka.current > 5 then	KSM = KSM * (1 + (t == mp and P.una7 and D.AR.u * t:getSkillValue(17)/10000 or 0))
	Dred = math.min(t.magicka.current/4, DMG, KSM)	smc = Dred * (t == mp and (1 + D.AR.l*0.08 + D.AR.m*0.10 + D.AR.h*0.12) * (1 - (arp == 3 and P.una8 and 0.25 or 0) - (P.alt21 and 0.25 or 0)) or 0.5)
	DMG = DMG - Dred		Mod(smc,t)		if arp == 3 then tes3.playSound{reference = tr, sound = "Spell Failure Destruction"} end
end

if LLM and a.health.normalized < 1 and a.magicka.current > 5 then
	local LLhp = math.min(a.magicka.current/4, LLM/100 * DMG, a.health.base - a.health.current)		mc = LLhp * ((a ~= mp or P.res8) and 0.5 or 1)
	tes3.modStatistic{reference = ar, name = "health", current = LLhp}		Mod(mc,a)
	if a.fatigue.normalized < 1 and (a ~= mp or P.res8) then a.fatigue.current = a.fatigue.current + LLhp*2 end
	if cf.m3 then tes3.messageBox("Life leech for %.1f hp (%.1f damage)  %.1f mag  Cost = %.1f", LLhp, DMG, LLM, mc) end
end



if cf.stamhit and stam > 0 and t.fatigue.current > 0 then t.fatigue.current = t.fatigue.current - DMG * stam end
if cf.traum and DMG/BaseHP > ((t ~= mp or P.end4) and 0.1 or 0.05) then
	trauma = math.random(5 + Kcrit/10 + (sw > 0.95 and (a ~= mp or P.str7) and 10 or 0)) + 50*DMG/BaseHP - (t.endurance.current + t.luck.current + t.sanctuary)/((t ~= mp or P.luc4) and 20 or 40)
	if trauma > 0 then tes3.modStatistic{reference = tr, name = L.Traum[math.random(5)], current = - trauma} end
end

if a == mp and w and D.poison and DMG > 0 then
	if wt < 9 then D.poison = D.poison - math.max(100 - Agi/(P.agi12 and 2 or 4),50)	M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end end
	local chance = 50 + (Agi/2 + mp.luck.current/4)*(P.agi13 and 2 or 1) - Tagi/2 - t.luck.current/4 - math.max(t.resistPoison,0)/2 - arm/2
	if chance > math.random(100) then tes3.applyMagicSource{reference = e.reference, source = B.poi}		if cf.m5 then tes3.messageBox("Poisoned! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end
	elseif cf.m5 then tes3.messageBox("Poison failure! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end 
end

local KO = math.min(math.min(100*DMG/BaseHP,40) * (((a ~= mp or P.str4 and sw > 0.95) and 1.5 or 1) + (1 - fat + t.encumbrance.normalized) * ((t ~= mp or P.end22) and 0.5 or 1)
+ ((a ~= mp or P.blu9 and sw > 0.95 and dir == 2) and (wt == 3 or wt == 4) and 0.5 or 0)) - Tagi*((t ~= mp or P.agi26) and 0.5 or 0.25), DMG)

if KO > math.random(100) then G.KOGMST.value = 0 else G.KOGMST.value = 100		hs = hs + math.max(KO,0)
	AF[tr].nostun = hs < math.random(100)
end

e.damage = DMG
if cf.m30 then tes3.messageBox([[%.1f = %.1f * %d%% arm (%d * %d%% * %.2f)
* %d%% mult + %d%% perk + %d%% crit (%d%%)
%d vel (%d%%)
Hs %d%%   KO %d%%   StamD %d%%
%.1f Shield (%.1f mag, %.1f mc)  %d traum]],
DMG, FD, Karm*100, Arm, Armult*100, Norm, Mult + Kdash, Kperk, Kcrit, CritC, prvel or 0, velk and velk or 0, hs, KO, stam*100, Dred, KSM, smc, trauma) end


local newhp = t.health.current - DMG
if a == mp then L.skw = math.max((tr.object.level * 4 + 20 - p.object.level/2) / (tr.object.level + 20) * DMG/30, 0)
	if P.axe9 and WT[wt].s == 6 and newhp < 0 then AF[ar].axe = math.min(AF[ar].axe + 5, 10) end
	if cf.dmgind then
		M.EDB.current = newhp	M.EDB.max = BaseHP
		local n = newhp/BaseHP	M.EDB.fillColor = {2-n*2, n*2, 0}		
		M.EDT.text = ("%d%s"):format(DMG, Kcrit > 0 and "!" or "")		M.EDBL.visible = true	T.EDMG:reset() 
	end
else
	if t == mp then
		if newhp/BaseHP < 0.2 then
			if P.sec3 and not tes3.isAffectedBy{reference = p, object = B.TS} then 
				--local min = 20 + mp:getSkillValue(18)/5		tes3.applyMagicSource{reference = p, name = "Survival_instinct", effects = {{id = 510, min = min, max = min + 10, duration = 3}}}
				B.TS.effects[1].id = 510  B.TS.effects[1].min = 20 + mp:getSkillValue(18)/5   B.TS.effects[1].max = B.TS.effects[1].min + 10   B.TS.effects[1].duration = 3
				tes3.applyMagicSource{reference = p, source = B.TS, createCopy = false}
			end
			if newhp < 1 and P.luc14 and BaseHP > 49 and mp.health.normalized >= 1 then e.damage = DMG - 1.5 + newhp end
		end
	end
	local Pois = L.CPOI[bid]		if Pois and DMG > 0 and Pois[2] > math.random(100) then tes3.applyMagicSource{reference = tr, source = B[Pois[1]]} end
end
elseif source == "shield" then	e.damage = 0	local el = e.activeMagicEffect.effectId		local El = L.ELSH[el]		local ts = tes3.getSimulationTimestamp()
	if El.ts ~= ts then		local ar = e.attackerReference	local tr = e.reference
		if ar.position:distance(tr.position) < ((ar ~= p or P.alt12) and 300 or 200) then
			local mag = math.random(0, Mag(el,ar) * ((ar ~= p or P.alt22) and 1 or 0.8))		local E = B.ElSh.effects[1]		E.id = El.id	E.min = mag		E.max = mag		E.duration = 1
			SNC[(tes3.applyMagicSource{reference = tr, source = B.ElSh}).serialNumber] = e.attacker		--tes3.messageBox("%s   mag = %s   ar = %s", el, mag, ar)
		end
	end		El.ts = ts
elseif source == "fall" then	local t = e.mobile	local vel = -t.velocity.z
	local DMG = math.max((vel - 700 - t:getSkillValue(20) * (t == mp and P.acr5 and 8 or 5)) * (t == mp and P.acr7 and 0.05 or 0.1) / (1 + t.agility.current/200), 0)
	if cf.m30 then tes3.messageBox("Fall!  Vel = %d    DMG = %d  -->  %d", vel, e.damage, DMG) end
	if t == mp then		L.skacr = vel/500
		if DMG > 0 then local KSM = D.e508
			if KSM and mp.magicka.current > 4 then KSM = KSM * (1 + (P.una7 and D.AR.u * mp:getSkillValue(17)/10000 or 0))
				local Dred = math.min(mp.magicka.current/4, DMG, KSM)	mc = Dred * (1 + D.AR.l*0.08 + D.AR.m*0.10 + D.AR.h*0.12) * (P.alt21 and 0.5 or 0.75)		DMG = DMG - Dred		Mod(mc)
				if cf.m then tes3.messageBox("Shield! %.1f damage  %.1f reduction  %.1f mag  Cost = %.1f", DMG, Dred, KSM, mc) end
			end
			if P.luc14 and mp.health.current - DMG < 1 and mp.health.base > 49 and mp.health.normalized >= 1 then DMG = mp.health.current - 1.5 end
		end
		if DMG < 0.1 then timer.delayOneFrame(function() wc.hitFader:deactivate() end) end
	end
	e.damage = DMG
	
	local BaseHP = t.health.base
	if cf.traum and DMG/BaseHP > ((t ~= mp or P.end4) and 0.1 or 0.05) then
		local trauma = math.random(5) + 50*DMG/BaseHP - (t.endurance.current + t.luck.current + t.sanctuary)/((t ~= mp or P.luc4) and 20 or 40)
		if trauma > 0 then tes3.modStatistic{reference = e.reference, name = L.Traum[math.random(5)], current = - trauma} end
	end	
end end		event.register("damage", DAMAGE)
--event.register(tes3.event.damaged, function() wc.hitFader:deactivate() end)


local function DAMAGEHANDTOHAND(e) local a = e.attacker	local ar = e.attackerReference	local t = e.mobile	local tr = e.reference	local ad = a.actionData		local Mult = 100	local FizD = ad.physicalDamage
if FizD < 0.0001 then e.fatigueDamage = 0		if a == mp then	L.skw = 0 end		return end
local sw = ad.attackSwing	 local dir = ad.physicalAttackType		local s = a:getSkillValue(26)	local Agi = a.agility.current
local as = (a.isMovingForward and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and 3) or 0
local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0

local Kbonus = a.attackBonus/5 + (a == mp and 0 or ar.object.level)
local Kstam = math.min(math.lerp(((a ~= mp or P.end1) and 0.4 or 0.3) + ((a ~= mp or P.hand2) and 0.1 or 0), 1, a.fatigue.normalized*1.1), 1)

local CritC = Kbonus + Agi/((a ~= mp or P.agi1) and 10 or 20) + s/((a ~= mp or P.hand6) and 10 or 20) + ((a ~= mp or P.luc1) and a.luck.current/20 or 0) + (as == 1 and (a ~= mp or P.spd3) and 10 or 0)
+ (ts == 1 and ((t == mp and P.med10 and D.AR.m > 19 and 0 or 10) + ((t ~= mp or P.agi7) and 0 or 10)) or 0)
+ (a == mp and math.min(com, G.maxcomb) * (P.agi6 and 5 or 3) + (a.isJumping and P.acr4 and a:getSkillValue(20)/10 or 0) - 10 or 10)
- (t.endurance.current + t.agility.current)/((t ~= mp or P.end3) and 20 or 40) - ((t ~= mp or P.luc2) and t.luck.current/20 or 0) - t.armorRating/10 - t.sanctuary/10
+ math.max(1-t.fatigue.normalized,0)*((a ~= mp or P.agi11) and 20 or 10) - (t == mp and ts == 0 and P.hev11 and D.AR.h or 0)
local Kcrit = CritC - math.random(100)	if Kcrit < 0 then Kcrit = 0 else Kcrit = Kcrit + 20 + ((a ~= mp or P.agi8) and 10 or 0) + ((a ~= mp or P.hand5) and 20 or 0) end
Mult = Mult - math.min(((ts == 3 or (t == mp and P.hev10 and ts == 0 and D.AR.h > 19)) and math.min((t.agility.current + t.endurance.current)/((t ~= mp or P.end2) and 10 or 20)
+ ((t ~= mp or P.bloc2) and t.readiedShield and t:getSkillValue(0)/20 or 0), 30) or 0)
+ (not t.readiedShield and (not t.readiedWeapon and (t.actorType ~= 0 and (t ~= mp or P.hand20) and (t:getSkillValue(26)/10 + t.agility.current/20) or 0) or
((t ~= mp or P.hand9 and not W.DWM) and WT[t.readiedWeapon.object.type].h1 and (t:getSkillValue(26) + t.agility.current)/20 or 0)) or 0), 50)


if a == mp then
	if (not R[tr] or not R[tr].cm) and math.abs(t:getViewToActor(mp)) > (P.snek8 and 135 or 150) then Mult = Mult + 100 + (P.snek3 and mp.isSneaking and 100 or 0) + (P.hand18 and 100 or 0)	mp:exerciseSkill(19, 1 + tr.object.level/5) end
	if (T.Dash.timeLeft or 0) > 2 then Mult = Mult + V.dd/(P.str9 and 50 or 100) end
	if ((P.con12 and t.object.type == 1) or (P.con13 and t.object.type == 2)) then Mult = Mult + mp:getSkillValue(13)/10 end
	if T.Comb.timeLeft then		local maxcom = (P[WT[-1].pc] and 4 or 3) + math.floor(s/50)
		if dir == last then com = math.max(com - 2, 0) elseif dir == pred and com > 2 then com = com - 1 elseif dir ~= pred then com = math.min(com + 1, maxcom) end
		M.CombK.text = ("%s/%s"):format(com, maxcom)		T.Comb:reset()	pred = last		last = dir
	else	last = dir	T.Comb = timer.start{duration = P.spd4 and 2 or 1.5, callback = function() com = 0	last = nil	pred = nil	M.CombK.text = "" end} end
elseif t == mp then Mult = Mult + (P.end12 and 0 or 50) end


local gau = (a ~= mp or P.hand7) and tes3.getEquippedItem{actor = ar, objectType = tes3.objectType.armor, slot = dir == 3 and 6 or 7} or nil		gau = gau and math.min(gau.object.weight,10)/20 or 0
local Koef = (Mult + Kcrit)/100
local FD = FizD * ((a ~= mp or P.hand17) and 4 or 3) * Koef
local fistd = FizD * (((a ~= mp or P.hand19) and 0.5 or 0.1) + gau) * Koef



local hs = (100 + Kcrit/2 + (s + a.strength.current + Agi)/((a ~= mp or P.str13) and 10 or 20) + (as == 1 and (a ~= mp or P.str3) and 20 or 0) + (a == mp and math.min(com, G.maxcomb) * (P.agi9 and 10 or 5) or 0)
+ (ts == 1 and (not (t == mp and P.med10 and D.AR.m > 19) and 30 or 0) or 0) - (t == mp and P.hev12 and D.AR.h or 0)
- (t.endurance.current + t.agility.current)/((t ~= mp or P.end5) and 5 or 10) - (ts == 0 and (t ~= mp or P.str5) and t.strength.current/10 or 0)) * FD*5/t.health.base
AF[tr].nostun = hs < math.random(100)


if cf.m30 then tes3.messageBox([[Fist %.1f = %.1f * %d%% (%d%% mult + %d%% crit (%d%%))   Hs = %d%%   Dmg = %d]], FD, FizD, Koef*100, Mult, Kcrit, CritC, hs, fistd) end

local KSM = tr.data.e508
if KSM then
	if t.magicka.current > 5 then	KSM = KSM * (1 + (t == mp and P.una7 and D.AR.u * t:getSkillValue(17)/10000 or 0))
		local Dred = math.min(t.magicka.current/4, fistd, KSM)		local cmult = t == mp and (1 + D.AR.l*0.08 + D.AR.m*0.10 + D.AR.h*0.12) * (P.alt21 and 0.5 or 0.75) or 0.5		mc = 0
		if fistd > 0 then mc = Dred * cmult		fistd = fistd - Dred end
		local Stred = math.min(t.magicka.current - mc, FD, KSM)		if Stred > 0 then mc = mc + Stred/5 * cmult		FD = FD - Stred end		Mod(mc,t)
		if cf.m3 then tes3.messageBox("Shield! %d stam damage  (-%d   -%.1f dmg) %.1f mag  Cost = %.1f", FD, Stred, Dred, KSM, mc) end
	end
end

e.fatigueDamage = FD
if fistd > 0.1 then t:applyDamage{damage = fistd, applyArmor = true, resistAttribute = 12, playerAttack = a == mp} end
if a == mp then	L.skw = math.max((tr.object.level * 4 + 20 - p.object.level/2) / (tr.object.level + 20) * FD/50, 0) end
end		event.register("damageHandToHand", DAMAGEHANDTOHAND)



local function playGroup(e) if L.AGHS[e.group] then local r = e.reference 	if r == tes3.player1stPerson then r = p end		--e.animationData 
--	if not AF[r] then mwse.log("%s  %s (%s  %s)  fl = %s", r, table.find(tes3.animationGroup, e.group), e.group, e.index, e.flags) end
	if AF[r] and AF[r].nostun and not AF[r].part then return false end		--attempt to index a nil value  при загрузке сейва		PlayerSaveGame  hit1 (19  0/1/2)  fl = 1
--else local r = e.reference 	if r == tes3.player1stPerson then r = p end
--	tes3.messageBox("%s  %s (%s  %s)  fl = %s", r, table.find(tes3.animationGroup, e.group), e.group, e.index, e.flags)
--	if e.group == 128 and e.index == 2 then return false end
end
--if e.reference.baseObject.id == "centurion_projectile" then tes3.messageBox("%s  %s (%s  %s)  fl = %s", e.reference, table.find(tes3.animationGroup, e.group), e.group, e.index, e.flags) end
end		event.register("playGroup", playGroup)


L.VFXBL = {["VFX_DestructCast"] = true, ["VFX_FireCast"] = true, ["VFX_FrostCast"] = true, ["VFX_LightningCast"] = true, ["VFX_PoisonCast"] = true,
--["VFX_ConjureCast"] = true, ["VFX_IllusionCast"] = true, ["VFX_MysticismCast"] = true, ["VFX_RestorationCast"] = true, ["VFX_AlterationCast"] = true
}
local function vfxCreated(e) local vfx = e.vfx
	if vfx.target == p and L.VFXBL[vfx.effectObject.id] then 
		--	vfx.effectNode.rotation = x
		--tes3.messageBox("freq  %s", vfx.effectNode.controller.frequency)
		--vfx.effectNode.controller.frequency
		vfx.expired = true
	end
end		if cf.vfxbl then event.register("vfxCreated", vfxCreated) end

--local function COMBATSTART(e) if e.target == mp then if L.CID[e.actor.reference.baseObject.id] == "dwem" and tes3.isAffectedBy{reference = p, object = "summon_centurion_unique"} then return false end end end		event.register("combatStart", COMBATSTART)
-- бехевиор: -1 = стоит столбом и ничего не делает хотя и в бою. 255 - затупил после прыжка,  5 = убегает и не видит игрока, 6 = убегает; 3 = атака; 2 - идл (но бывает и при атаке); 0 = хеллоу; 8 = бродит
L.BEH = {[5] = 1, [6] = 1, [-1] = 0, [255] = 0}		L.SEA = {[1] = 1, [3] = 1, [4] = 1}
local function COMBATSTARTED(e) local m = e.actor	local ref = m.reference	 	if e.target == mp and not R[ref] and m.combatSession then	local ob = m.object		local bid = ob.baseObject.id
local hum = m.actorType == 1 or ob.biped
R[ref] = {m = m, a = m.actionData, ob = ob, c = 0, hum = hum, at = hum and 1 or (not ob.usesEquipment and 3), lim = math.max((P.per7 and 70 or 100) + ob.level*(P.ill19 and 5 or 10), 100),
rc = L.MAC[(m.actorType == 1 and m:getSkillValue(10) > 40) and 0 or bid], fun = cf.full and L.CFF[bid], pos = ref.position}
timer.delayOneFrame(function() if R[ref] then R[ref].cm = true end end)
if cf.m4 then tes3.messageBox("%s joined the battle! Enemies = %s", ref, table.size(R)) end		--local tik5 = math.floor(T.CT.timing)%5 == 0
if not T.CT.timeLeft then	T.CT = timer.start{duration = 1, iterations = -1, callback = function() local ht = ad.hitTarget		local s, sa, w, beh, HD, status, pz, Zdif
	G.PPF = mp.canMove and pp + L.GetPDir() * (G.Pspd/2) or pp		G.PPZ = pp.z
--	if mp.isFalling then
		local hit = tes3.rayTest{position = G.PPF + V.up100, direction = V.down, ignore = {p}}		G.PPZF = hit and hit.intersection.z or G.PPZ
--	else G.PPZF = G.PPZ end
	
--	if rrr then rrr:disable() rrr:delete() end	rrr = tes3.createReference{object = "4nm_light", scale = 3, position = G.PPF, cell = p.cell}
	
	if cf.AIen then for r, t in pairs(R) do s = t.m.combatSession	sa = s and s.selectedAction		beh = t.a.aiBehaviorState	w = t.m.readiedWeapon	w = w and w.object	HD = nil	pz = t.pos.z	Zdif = G.PPZ - pz
		if not ht or ht.isDead then ht = t.m end
		if s then
			if t.fun then t.fun(t.m, r) end
			if sa == 7 then
				if t.m.health.normalized > 0.1 and t.m.flee < t.lim then
					if t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then
						if not w or w.type < 9 then
							HD = math.abs(G.PPZ - pz) > 128 * (w and w.reach or 0.7)
							if HD then
								if t.at == 1 then
									if t.c > cf.AIsec then status = "STONE!"
										if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(2,3)} end		--t.ob:reevaluateEquipment()
										mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
										s.selectedAction = 2
										t.a.aiBehaviorState = 3
									else status = "NO STONE"	if not t.rc then t.c = t.c + 1 end
										s.selectedAction = t.at or 1
										t.a.aiBehaviorState = 3
									end
								else status = "NO RUN MONSTR"
									s.selectedAction = 5
									t.a.aiBehaviorState = 3
								end
							else status = "NO HD"
								s.selectedAction = t.at or 1
								t.a.aiBehaviorState = 3
							end
						else status = "RANGE"
							s.selectedAction = 2
							t.a.aiBehaviorState = 3
						end
						if t.rc then tes3.applyMagicSource{reference = r, source = B[table.choice(t.rc)]} end
					else status = "NO LINE"
						s.selectedAction = t.at or 1
						t.a.aiBehaviorState = 3
					end
				else status = "FLEE" end
			elseif L.BEH[beh] == 1 then
				if t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then
					if not w or w.type < 9 then
					--	HD = math.abs(G.PPZ - pz) > 128 * (w and w.reach or 0.7)
					--	if HD then
							if t.at == 1 then
								if t.c > cf.AIsec then status = "SEARCH - STONE!"	t.c = 0
									if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(2)} end
									mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
									s.selectedAction = 2
									t.a.aiBehaviorState = 3
								else status = "SEARCH - NO STONE"	if not t.rc then t.c = t.c + 1 end
									--s.selectedAction = t.at or 1
									--t.a.aiBehaviorState = 3
								end
							else status = "SEARCH - MONSTR"
								--s.selectedAction = 5
								--t.a.aiBehaviorState = 3
							end
					--	else status = "SEARCH - NO HD"
					--		s.selectedAction = t.at or 1
					--		t.a.aiBehaviorState = 3
					--	end
					else status = "SEARCH - RANGE"
						--s.selectedAction = 2
						--t.a.aiBehaviorState = 3
					end
					if t.rc then tes3.applyMagicSource{reference = r, source = B[table.choice(t.rc)]} end
				else status = "SEARCH - NO LINE" end
			elseif L.BEH[beh] == 0 then	status = "EXTRA COMBAT!"	t.m:startCombat(mp)		t.a.aiBehaviorState = 3
			else status = ""	if t.c > 0 and (not w or w.type < 9) then t.c = 0 end		--if not w or w.type < 9 then t.c = t.c > cf.AIsec and cf.AIsec or 0 end
				if cf.durka and L.SEA[sa] then t.tar = t.a.target	if t.tar then
					t.tarp = t.tar == mp and G.PPF or t.tar.position		t.dist = t.tarp:distance(t.pos)
					t.vec = t.tarp - t.pos		t.vec.z = 0		t.vec = t.vec:normalized()
					t.mspd = (t.hum and 100 + t.m.speed.current or t.m.speed.current * 3) * (3 + t.m.agility.current/100) * (0.5 + math.min(t.m.fatigue.normalized,1)/2) * (1 - t.m.encumbrance.normalized)
					t.maxd = math.clamp(200 + t.mspd, 350, 1200)
					V.upz = tes3vector3.new(0,0,math.clamp(0.2666 + ((t.tar == mp and G.PPZF or t.tarp.z) - pz)/500, -0.2, 0.7))
					
					if t.dist > 300 and t.dist < t.maxd and not t.m.isHitStunned then
						t.m:doJump{velocity = (t.vec * (t.dist/500) + V.upz) * 1000, applyFatigueCost = false}
						if t.hum then t.m:forceWeaponAttack{swing = 1} end
					--	tes3.messageBox("%d / %d    mspd = %d   ZD = %d   Z = %.3f", t.dist, t.maxd, t.mspd, G.PPZF - pz, V.upz.z)		--r.data.jpos1 = t.pos:copy()
					end
				end end
			end
		else	-- если не в бою, то нельзя применять applyMagicSource с шаром даже если стартовать бой
			if t.m.fight > 50 then
				if t.m.isPlayerDetected and tes3.testLineOfSight{reference1 = r, reference2 = p} then
					if not w or w.type < 9 then
						HD = math.abs(G.PPZ - pz) > 128 * (w and w.reach or 0.7)
						if HD then
							if t.at == 1 then status = "NO COMB - EXTRA STONE!"
								if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(2)} end
								mwscript.equip{reference = r, item = L.stone}	 r:updateEquipment()
								t.m:startCombat(mp)		t.a.aiBehaviorState = 3
							else status = "NO COMB - MONSTR"
								--t.a.aiBehaviorState = 3
							end
						else status = "NO COMB - NO HD"
							t.m:startCombat(mp)		t.a.aiBehaviorState = 3
						end
					else status = "NO COMB - RANGE"
						t.m:startCombat(mp)		t.a.aiBehaviorState = 3
					end
				else status = "NO COMB - NO LINE"
					t.m:startCombat(mp)		t.a.aiBehaviorState = 3
				end
			else status = "NO COMB - CALM!"	R[r] = nil end
		end
		if cf.m4 then tes3.messageBox("%s %s(%s) fl %d/%d  fg %d   Beh = %s/%s  SA = %s/%s  %s", r, status, t.c > 0 and t.c or "", t.m.flee, t.lim, t.m.fight, beh,
		t.a.aiBehaviorState, sa, s and s.selectedAction, t.m.isPlayerDetected and "" or "No detect") end
	end end
	
	if table.size(R) == 0 then T.CT:cancel()		M.EBLO.visible = false			if cf.m4 then tes3.messageBox("The battle is over!") end
	elseif cf.enbar and ht then M.EBLO.visible = true	M.EBN.text = ht.object.name		M.EBH.current = ht.health.current	M.EBH.max = ht.health.base	
		if P.int4 then M.EBM.current = ht.magicka.current	M.EBM.max = ht.magicka.base		M.EBS.current = ht.fatigue.current		M.EBS.max = ht.fatigue.base end
	--	local vec2 = wc.worldCamera.cameraData.camera:worldPointToScreenPoint(ht.position + tes3vector3.new(0,0,ht.height + 30))
	--	if vec2 then local viewportWidth, viewportHeight = tes3ui.getViewportSize()		 --M.EBLO.absolutePosAlignX = vec2.x - 0.5		M.EBLO.absolutePosAlignY = vec2.y * -1 + 0.5
	--		M.EBLO.ignoreLayoutX = true		M.EBLO.ignoreLayoutY = true		M.EBLO.positionX = vec2.x + (viewportWidth / 2) - (M.EBLO.width / 2)		M.EBLO.positionY = vec2.y - (viewportHeight / 2) + (M.EBLO.height / 2)
	--	end
	end
	--if rrr then rrr:disable()	rrr.modified = false end	rrr = tes3.createReference{object = "4nm_light", scale = 3, position = e.actor.actionData.walkDestination, cell = p.cell}
end} end
end end		event.register("combatStarted", COMBATSTARTED)


local function DETERMINEACTION(e)	local s = e.session		if s.selectedAction ~= 0 then 
	local m = s.mobile	local f = L.CFF[m.reference.baseObject.id]		if f then f(m) end
	--tes3.messageBox("DEA  %s  выбор = %s", s.mobile.reference, s.selectedAction)
	--tes3.messageBox("DEA  %s  SA = %s  Prior = %s", m.reference, s.selectedAction, s.selectionPriority)
end end		--if cf.full then event.register("determineAction", DETERMINEACTION) end


-- не решил = 0, Атака (1 мили, 2 рейндж, 3 кричер без оружия или рукопашка), AlchemyOrSummon = 6, бегство = 7, Спелл (касание 4, цель 5, на себя 8), UseEnchantedItem = 10		s:changeEquipment()
local function determinedAction(e) if cf.AIen then	local s = e.session		local m = s.mobile 	local t = R[m.reference]	if t then
--tes3.messageBox("DED  %s  SA = %s  Beh = %s  fl = %d  fg = %d  Prior = %s  W = %d %s  S = %d %s  %s", m.object.name, s.selectedAction,  m.actionData.aiBehaviorState, m.flee, m.fight, s.selectionPriority,
--m.readiedWeapon and m.readiedWeapon.object.type or -1, s.selectedWeapon and s.selectedWeapon.object.name, m.readiedShield and 1 or 0, s.selectedShield and "+S" or "", s.selectedSpell and s.selectedSpell.name)
	if s.selectedAction == 7 then
		if m.health.normalized > 0.1 and m.flee < t.lim then s.selectedAction = t.at or 1		t.a.aiBehaviorState = 3
			if cf.m4 then tes3.messageBox("UPD NO FLEE!  %s", t.ob.name) end		-- дальнобойные враги (sa == 2 or sa == 5) вообще не убегают даже если фли выше 100
		end
	end
end	end	end		event.register("determinedAction", determinedAction)

local function combatStop(e) local m = e.actor	local r = m.reference	if R[r] then local t = R[r]		local status, RetF		local beh = t.a.aiBehaviorState 	--событие не триггерится от контроля и успокоения
if m.fight > 50 then
	if t.at == 1 then
		if math.abs(pp.z - r.position.z) > 128 * (t.m.readiedWeapon and t.m.readiedWeapon.object.reach or 0.7) then		
			if not m.readiedWeapon or m.readiedWeapon.object.type < 9 then
			--	if not t.ob.inventory:contains(L.stone) then tes3.addItem{reference = r, item = L.stone, count = math.random(1,2)} end
			--	mwscript.equip{reference = r, item = L.stone} r:updateEquipment()
				status = "NO LEAVE + STONE"
			else status = "NO LEAVE + RANGE" end
		--	t.a.aiBehaviorState = 3
			--RetF = true
		else status = "LEAVE NPC" end
	else status = "LEAVE MONSTR" end
else status = "CALM"	R[r] = nil end

if cf.m4 then tes3.messageBox("STOP - %s  %s  fg = %s   Beh = %s/%s  SA = %s  Tar = %s", status, r, m.fight, beh, t and t.a.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, t and t.a.target and t.a.target.object.name) end
if RetF then return false end
end end		--event.register("combatStop", combatStop)

--[[ local function onCombatStopped(e) local m = e.actor		if R[m.reference] then	-- Триггерится при кальме, но не при контроле
	if cf.m4 then tes3.messageBox("%s leave combat  fg = %s   Beh = %s  SA = %s  Enemies = %s", m.object.name, m.fight, m.actionData.aiBehaviorState, m.combatSession and m.combatSession.selectedAction, table.size(R)) end
end end		--event.register("combatStopped", onCombatStopped)
--]]

local function DETECTSNEAK(e)	if e.target == mp then	local m = e.detector	local r = m.reference
--[[	local VMult = Viev < 90 and tes3.findGMST("fSneakViewMult").value or tes3.findGMST("fSneakNoViewMult").value
	local DMult = tes3.findGMST("fSneakDistanceBase").value + r.position:distance(pp) * tes3.findGMST("fSneakDistanceMultiplier").value
	local PKoef = (mp.isSneaking and mp.sneak.current * tes3.findGMST("fSneakSkillMult").value + mp.agility.current/5 + mp.luck.current/10 + mp:getBootsWeight() * tes3.findGMST("fSneakBootMult").value or 0)
	* mp:getFatigueTerm() * DMult + mp.chameleon + (mp.invisibility > 0 and 100 or 0)
	local DKoef = (m.sneak.current + m.agility.current/5 + m.luck.current/10 - m.blind) * VMult * m:getFatigueTerm()
	local chance = PKoef - DKoef		local detected = math.random(100) >= chance		e.isDetected = detected		--m.isPlayerDetected = detected		m.isPlayerHidden = not detected
--]]
local com = R[r] and R[r].cm	local snek = mp.isSneaking or (P.snek12 and mp.movementFlags == 0)
local KP = com and 0 or ((mp:getSkillValue(19) + mp.agility.current/2)*(P.snek1 and 1 or 0.5) + (P.luc10 and mp.luck.current/4 or 0) + (P.sec5 and mp:getSkillValue(18)/4 or 0)) * (snek and 0.5 or (P.snek10 and 0.2 or 0)) * math.min(mp.fatigue.normalized,1)
local KD = com and 0 or (m:getSkillValue(18) + m.agility.current/4 + m.luck.current/4)
local Koef = com and 1 or math.max((100 + KD - KP)/100, 0.5)
local DistKF = math.max(1.5 - r.position:distance(pp)/(P.snek5 and 2000 or 3000), 0.5)
local VPow = com and 200 or math.max(200 - math.abs(m:getViewToActor(mp)) * (P.snek6 and 1.2 or 1), 0)
local Vis = math.max(VPow * Koef * DistKF - (mp.invisibility > 0 and (P.snek11 and 200 or 150) - m:getSkillValue(14)/2 or 0) - mp.chameleon - m.blind, 0)
local Aud = math.max((5 + mp.encumbrance.current/5 + mp:getBootsWeight()) * ((snek and 0 or 2) + (P.snek4 and 1 or 2)) * Koef * DistKF - (P.ill21 and mp.chameleon/2 or 0) - m.sound, 0)
local chance = Vis + Aud		local detected = chance > math.random(G.TR.tr3 and 30 or 100)		e.isDetected = detected		m.isPlayerDetected = detected		m.isPlayerHidden = not detected
if cf.m11 then tes3.messageBox("Det %s %d%%  Vis = %d%% (%d)  Aud = %d%%  DistKF = %.2f  Koef = %.2f (%d - %d)  %s", detected, chance, Vis, VPow, Aud, DistKF, Koef, KD, KP, r) end
end end		if cf.stels then event.register("detectSneak", DETECTSNEAK) end

local function ACTIVATE(e) if e.activator == p then		local t = e.target
if t.object.objectType == tes3.objectType.npc and t.mobile.fatigue.current < 0 then		--ref.object:hasItemEquipped(item[, itemData])
	if cf.maniac and mp.agility.current*(P.agi18 and 1 or 0.5) > 50 + 50*t.mobile.health.normalized + t.mobile.fatigue.current then
		for _, s in pairs(t.object.equipment) do t.mobile:unequip{item = s.object} end	if cf.m then tes3.messageBox("Playful hands!") end
		timer.delayOneFrame(function() t.object:reevaluateEquipment() end)
	else if t.mobile.readiedWeapon then t.mobile:unequip{item = t.mobile.readiedWeapon.object} end		if t.mobile.readiedAmmo then t.mobile:unequip{item = t.mobile.readiedAmmo.object} end end
elseif t.object.objectType == tes3.objectType.apparatus and ic:isKeyDown(cf.ekey.keyCode) then	local app = {}
	for r in p.cell:iterateReferences(tes3.objectType.apparatus) do
		if (not app[r.object.type] or app[r.object.type].quality < r.object.quality) and tes3.hasOwnershipAccess{target = r} and pp:distance(r.position) < 800 then app[r.object.type] = r.object end
	end
	for i, ob in pairs(app) do tes3.addItem{reference = p, item = ob, playSound = false} end
	timer.delayOneFrame(function() local appar = app[0] or app[1] or app[2] or app[3]	if appar then
		mp:equip{item = appar}	timer.delayOneFrame(function() for i, ob in pairs(app) do tes3.removeItem{reference = p, item = ob, playSound = false} end end)
	end end)
	return false
end		-- if e.activator == p and wc.inputController:isKeyDown(cf.telkey.keyCode) and e.target ~= W.TETR then TELnew(e.target)	return false end
end end		event.register("activate", ACTIVATE)


local function EQUIP(e) if e.reference == p and e.item.weight > 0 then local o = e.item
if (o.objectType == tes3.objectType.alchemy or o.objectType == tes3.objectType.ingredient) then
	if o.objectType == tes3.objectType.alchemy and M.drop.visible then local Btab = L.BotMod[o.mesh:lower()]	if Btab then	local ispoison = true
		if cf.smartpoi then ispoison = nil		for i, ef in ipairs(o.effects) do if ef.object and ef.object.isHarmful then ispoison = true break end end end
		if ispoison then
			if ic:isKeyDown(cf.ekey.keyCode) then -- кидание бутылок
				if not G.pbotswap then G.pbotswap = true	local bot = L.pbottle
					if mp.readiedWeapon and mp.readiedWeapon.object == bot then mp:unequip{item = bot} end
					timer.delayOneFrame(function() G.pbotswap = nil
						local numdel = tes3.getItemCount{reference = p, item = bot}		if numdel > 0 then
							tes3.removeItem{reference = p, item = bot, count = numdel}		tes3.addItem{reference = p, item = D.poisonbid, count = numdel}		D.poisonbid = nil
							if cf.m5 then tes3.messageBox("%d %s", numdel, eng and "bottles unequipped" or "старых бутылок снято") end
						end
						local num = tes3.getItemCount{reference = p, item = o}	if num > 0 then		local enc = tes3.getObject("4nm_e_poisonbottle")	local E = enc.effects	local pow = P.alc7 and 3 or 4
							for i, ef in ipairs(o.effects) do E[i].id = ef.id		E[i].radius = 5		E[i].min = L.nomag[ef.id] and ef.min or ef.min/pow		E[i].max = L.nomag[ef.id] and ef.max or ef.max/pow
							E[i].duration = L.nomag[ef.id] and ef.duration/pow or ef.duration	E[i].rangeType = 1		E[i].attribute = ef.attribute		E[i].skill = ef.skill end
							bot.mesh = Btab[1]	bot.icon = Btab[2]	bot.weight = o.weight	D.poisonbid = o.id		enc.modified = true		bot.modified = true		
							tes3.removeItem{reference = p, item = o, count = num}		tes3.addItem{reference = p, item = bot, count = num}		mp:equip{item = bot}
							if cf.m5 then tes3.messageBox("%d %s", num, eng and "bootles are ready!" or "бутылок готово к броску!") end
						end
					end)
					return false
				else tes3.messageBox("Not so fast!") return false end
			else -- отравление оружия
				timer.delayOneFrame(function() if tes3.getItemCount{reference = p, item = o} > 0 then	local pow = P.alc5 and 5 or 6
					for i, ef in ipairs(o.effects) do
						B.poi.effects[i].id = ef.id	B.poi.effects[i].min = L.nomag[ef.id] and ef.min or ef.min/pow		B.poi.effects[i].max = L.nomag[ef.id] and ef.max or ef.max/pow
						B.poi.effects[i].duration = L.nomag[ef.id] and ef.duration/pow or ef.duration		B.poi.effects[i].attribute = ef.attribute		B.poi.effects[i].skill = ef.skill
					end
					D.poison = 100 + (mp.alchemy.current + mp.agility.current) * (P.alc6 and 1 or 0.5)		M.WPB.widget.current = D.poison		M.WPB.visible = true
					tes3.removeItem{reference = p, item = o}
					if cf.m5 then tes3.messageBox("%s %d", eng and "Poison is ready! Charges =" or "Яд готов! объем =", D.poison) end
				end end)
				return false
			end
		end
	end end

	if D.potmcd then
		if cf.m5 then if eng then tes3.messageBox("Not so fast! I need at least %d seconds to swallow what is already in my mouth!", D.potmcd)
		else tes3.messageBox("Не так быстро! Мне надо еще хотя бы %d секунды чтобы проглотить то что уже у меня во рту!", D.potmcd) end end		return false
	elseif D.potcd and D.potcd > G.potlim then
		if cf.m5 then if eng then tes3.messageBox("Belly already bursting! I can't take o anymore... I have to wait at least %d seconds before I can swallow something else", D.potcd - G.potlim)
		else tes3.messageBox("Пузо уже по швам трещит! Больше не могу... Надо подождать хотя бы %d секунд прежде, чем я смогу заглотить что-то еще", D.potcd - G.potlim) end end	return false
	end
	D.potmcd = math.max(10 - mp.speed.current/(P.spd5 and 10 or 20), P.spd5 and 2 or 3)		D.potcd = (D.potcd or 0) + math.max(40 - (P.alc9 and mp.alchemy.current/10 or 0), 30)
	if not T.POT.timeLeft then T.POT = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
		if D.potmcd and D.potmcd > D.potcd - G.potlim then M.PCD.max = 5	M.PCD.current = D.potmcd else M.PCD.max = 30	M.PCD.current = D.potcd - G.potlim	if M.PCD.current <= 0 then M.PIC.visible = false end end
		if D.potcd <= 0 then D.potcd = nil	T.POT:cancel() end
	end} end
	M.PCD.max = 5	M.PCD.current = 5	M.PIC.visible = true	if cf.m5 then tes3.messageBox("%s %d / %d", eng and "Om-nom-nom! Belly filled at" or "Ням-ням! Пузо заполнилось на", D.potcd, G.potlim) end
elseif o.objectType == tes3.objectType.repairItem and not mp.inCombat then		local anvil
	if P.arm7 then for r in p.cell:iterateReferences(tes3.objectType.static) do if L.Anvil[r.object.id] and pp:distance(r.position) < 1000 then anvil = true	break end end end
	tes3.findGMST("fRepairAmountMult").value = (P.arm1 and 1 or 0.5) + (anvil and 1 or 0)		local Qal = math.min(o.quality,2)	local Skill = math.min(mp:getSkillValue(1) + mp.agility.base/5 + mp.luck.base/10, 100)
	if not G.ImpTab then local ob, ida, Kmax, KF		G.ImpTab = {}	G.ImpD = {}
		for _, s in pairs(cf.upgm and p.object.equipment or inv) do ob = s.object
			if ((ob.objectType == tes3.objectType.armor and P.arm5) or (ob.objectType == tes3.objectType.weapon and ob.type < 11 and P.arm4)) and ob.weight > 0 then
				Kmax = math.min(Qal/10, Skill*(P[ob.objectType == tes3.objectType.weapon and "arm8" or "arm9"] and 0.0015 or 0.001) + (P.luc9 and 0.05 or 0))
				KF = math.min((Skill * Qal - math.min(ob.value,10000)^0.5 * (P.arm12 and 1 or 2) + (ob.enchantment and (P.arm10 and 0 or -50) or (P.arm11 and 50 or 0)))/100, 1)
				if KF > 0 then
					if not cf.upgm then for i = 1, s.count do ida = s.variables and s.variables[i] or tes3.addItemData{to = p, item = ob, updateGUI = false}	ida.tempData.upg = true		G.ImpD[ida] = ob end end
					G.ImpTab[ob] = ob.maxCondition		ob.maxCondition = math.round(ob.maxCondition * (1 + KF * Kmax))
				end
			end
		end
		timer.delayOneFrame(function() for iob, max in pairs(G.ImpTab) do iob.maxCondition = max end	G.ImpTab = nil
			if not cf.upgm then for ida, iob in pairs(G.ImpD) do ida.tempData.upg = nil		tes3.removeItemData{from = p, item = iob, itemData = ida, force = false, updateGUI = false} end
			tes3.updateInventoryGUI{reference = p} end	G.ImpD = nil
		end)
	end
elseif e.item.objectType == tes3.objectType.weapon and ic:isKeyDown(cf.gripkey.keyCode) and not W.AltWCD then
	if L.AltW[o.type] then	local New = L.NewGrip(o)	if New then		local ida = e.itemData
		if not ida or ida.condition > 0 then
			tes3.addItem{reference = tes3.player, item = New}
			if ida then local DAT = tes3.addItemData{to = p, item = New}	DAT.condition = ida.condition		DAT.charge = ida.charge end
			W.AltWCD = true		mp:equip{item = New}		timer.delayOneFrame(function() tes3.removeItem{reference = p, item = o, playSound = false}	W.AltWCD = nil end, timer.real)			return false
		end
	end end
end
end end		event.register("equip", EQUIP)


-- Во время события equipped mp.readiedWeapon == нил! Надо ждать фрейм
local function EQUIPPED(e) if e.reference == p then	local o = e.item		--tes3.messageBox("equipped   %s", mp.readiedWeapon and mp.readiedWeapon.object.name)
if o.objectType == tes3.objectType.weapon then local wt = o.type	  local od = e.itemData		timer.delayOneFrame(function() L.GetWstat() end, timer.real)
	if WT[wt].dw then
		if ((o == W.WL and od == W.DL) or (o == W.WR and od == W.DR)) then	W.wt = W[o.id] or wt
		else L.DWMOD(false)		L.DWNEW(o, od, ic:isKeyDown(cf.ekey.keyCode)) end
	else L.DWMOD(false)
		if wt == 9 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 12 then
			for _, s in pairs(inv) do if s.object.type == 12 then mwscript.equip{reference = p, item = s.object} if cf.m8 then tes3.messageBox("arrows equipped") end break end end
		elseif wt == 10 and (mp.readiedAmmo and mp.readiedAmmo.object.type or 0) ~= 13 then
			for _, s in pairs(inv) do if s.object.type == 13 then mwscript.equip{reference = p, item = s.object} if cf.m8 then tes3.messageBox("bolts equipped") end break end end
		end
	end
	if cf.autoshield and not W.DWM and WT[wt].h1 and not mp.readiedShield then
		for _, s in pairs(inv) do if s.object.objectType == tes3.objectType.armor and s.object.slot == 8 then mwscript.equip{reference = p, item = s.object} break end end
	end
elseif o.objectType == tes3.objectType.armor then L.GetArmT()		if o.slot == 8 then L.DWMOD(false) end
elseif L.DWOBT[o.objectType] then L.DWMOD(false) end
end end		event.register("equipped", EQUIPPED)


local function UNEQUIPPED(e) local r = e.reference 		if r == p then local it = e.item
	if it.objectType == tes3.objectType.weapon then		L.GetWstat()
		if it == L.pbottle and not G.pbotswap then timer.delayOneFrame(function() local num = mwscript.getItemCount{reference = p, item = it} if num > 0 then
			tes3.removeItem{reference = p, item = it, count = num}		tes3.addItem{reference = p, item = D.poisonbid, count = num}	D.poisonbid = nil
			if cf.m5 then tes3.messageBox("%d bottles unequipped", num) end
		end end) end
	else	if it.objectType == tes3.objectType.armor then L.GetArmT() end		if it.enchantment and it.enchantment.castType == 3 then ConstEnLim() end end

elseif cf.npcgrip then local it = e.item	local ida = e.itemData
	if it.objectType == tes3.objectType.armor and it.slot == 8 and (not ida or ida.condition < 1) and N[r].hum then
		local w = e.mobile.readiedWeapon	w = w and w.object		local wt = w and w.type or -1
		if L.W1to2[wt] and w.weight > 0 then e.mobile.weaponReady = false end
	end
end end		event.register("unequipped", UNEQUIPPED)


local function WEAPONREADIED(e) local r = e.reference		if r == p then
	if W.DWM then if e.weaponStack then L.Cul(true) else L.DWMOD(false) end end
elseif cf.npcgrip then
	local m = r.mobile		local ws = e.weaponStack 		local o = ws and ws.object
	if not m.readiedShield and o and L.W1to2[o.type] and o.weight > 0 and not o.script and N[r].hum then	local New = L.NewGrip(o)	if New then
		local ida = ws.itemData		local cond = ida.condition		local charge = ida.charge
		tes3.addItem{reference = r, item = New}		local DAT = tes3.addItemData{to = r, item = New}	DAT.condition = cond	DAT.charge = charge
		m:equip{item = New}		timer.delayOneFrame(function() tes3.removeItem{reference = r, item = o, playSound = false} end, timer.real)
	--	tes3.messageBox("cond = %s    new = %s     char = %s   new = %s", cond,  DAT.condition, charge, DAT.charge)
	end end
end end		event.register("weaponReadied", WEAPONREADIED)

local function WEAPONUNREADIED(e) if e.reference == p then	if W.DWM then L.Cul(false) end
end end		event.register("weaponUnreadied", WEAPONUNREADIED)


local function ITEMDROPPED(e) local r = e.reference
	if BAM[r.object.id] then r:delete()		if cf.m then tes3.messageBox("Ammo unbound") end
	elseif r.object == L.pbottle then local num = r.stackSize	tes3.addItem{reference = p, item = D.poisonbid, count = num}
		r:delete()	if cf.m5 then tes3.messageBox("%d %s", num, eng and "old bottles unequipped" or "старых бутылок снято") end
	elseif ic:isKeyDown(cf.telkey.keyCode) then TELnew(r) end	-- ic:isKeyDown(cf.telkey.keyCode)
end		event.register("itemDropped", ITEMDROPPED)

local function FILTERINVENTORY(e) if L.BlackItem[e.item.id] and M.Stat and M.Stat.visible == false then e.filter = false end end		event.register("filterInventory", FILTERINVENTORY, {priority = -1000})
--local function filterContentsMenu(e) e.filter = true end		event.register("filterContentsMenu", filterContentsMenu, {priority = -1000})

L.LiveOT = {[tes3.objectType.creature] = true, [tes3.objectType.npc] = true}
L.RWList = {["4nm_weapon_adamantium"] = true, ["4nm_weapon_daedric_obl"] = true, ["4nm_weapon_daedric_sky"] = true, ["4nm_weapon_dwarven_obl"] = true, ["4nm_weapon_dwarven_sky"] = true,
["4nm_weapon_ebony_obl"] = true, ["4nm_weapon_ebony_sky"] = true, ["4nm_weapon_elven_obl"] = true, ["4nm_weapon_elven_sky"] = true, ["4nm_weapon_glass_obl"] = true, ["4nm_weapon_glass_sky"] = true, 
["4nm_weapon_ice"] = true, ["4nm_weapon_nordic_sky"] = true, ["4nm_weapon_orcish_sky"] = true, ["4nm_weapon_amber"] = true,
["random ebony weapon"] = true, ["random_daedric_weapon"] = true, ["random_dwemer_weapon"] = true, ["random_glass_weapon"] = true, ["random_imp_weapon"] = true, ["random ashlander weapon"] = true,
["random_iron_weapon"] = true, ["random_nordic_weapons"] = true, ["random_orcish_weapons"] = true, ["random_silver_weapon"] = true, ["random_steel_weapon"] = true}
local function leveledItemPicked(e) local list = e.list
	if L.RWList[list.id] then		local ob = e.pick		local r = e.spawner
		if ob and ob.objectType == tes3.objectType.weapon and ob.type == 0 and L.LiveOT[r.object.objectType] then local New
			for i = 1, 3 do New = table.choice(list.list).object		if New.type ~= 0 then break else New = nil end		end
			if New then G.DopW[r.object.id] = New
				--tes3.messageBox("%s    %s    %s      new = %s", list, ob, r.id, New)
			end
		end
	end
end		event.register("leveledItemPicked", leveledItemPicked)


L.MEDUR = {[76] = 1000000, [2] = 10, [9] = 5, [11] = 10, [40] = 10, [58] = 10, [64] = 10, [65] = 10, [66] = 10, [501] = 10, [502] = 10, [503] = 10, [509] = 10,
[17] = 10, [18] = 10, [19] = 10, [20] = 10, [21] = 10, [28] = 10, [29] = 10, [30] = 10, [31] = 10, [32] = 10, [33] = 10, [34] = 10, [35] = 10, [36] = 10,
[49] = 10, [50] = 10, [51] = 10, [52] = 10, [53] = 10, [54] = 10, [55] = 10, [56] = 10, [101] = 10, [118] = 10, [119] = 10, [44] = 10,
[79] = 10, [80] = 10, [81] = 10, [82] = 10, [83] = 10, [84] = 10, [117] = 10, [42] = 10, [85] = 10, [89] = 10,
[90] = 10, [91] = 10, [92] = 10, [93] = 10, [94] = 10, [95] = 10, [96] = 10, [97] = 10, [98] = 10, [99] = 10, [67] = 5, [68] = 5,
[102] = 10, [103] = 10, [104] = 10, [105] = 10, [106] = 10, [107] = 10, [108] = 10, [109] = 10, [110] = 10, [111] = 10, [112] = 10, [113] = 10, [114] = 10, [115] = 10, [116] = 10,
[134] = 10, [137] = 10, [138] = 10, [139] = 10, [140] = 10, [141] = 10, [142] = 10}
local function MENUSETVALUES(e) local MSVD = e.element:findChild(-789) if MSVD then	e.element:findChild(-783):registerBefore("mouseClick", function()
	local min = (L.MEDUR[e.element:getPropertyObject("MenuSetValues_Effect").id] or 0) * (P.int10 and 1 or 2)
	if MSVD.widget.current < min then tes3.messageBox("Minimum duration = %s", min) return false end
end) end end		if cf.durlim then event.register("uiActivated", MENUSETVALUES, {filter = "MenuSetValues"}) end

local function SPELLCREATED(e) local s = e.spell	local del, rt
for i, ef in ipairs(s.effects) do if ef.id ~= -1 and ef.rangeType ~= 1 then if rt then if ef.rangeType ~= rt then del = true	break end else rt = ef.rangeType end end end
if del then	timer.delayOneFrame(function() mwscript.removeSpell{reference = p, spell = s}	timer.delayOneFrame(function() tes3.deleteObject(s) 	tes3.messageBox("Anti-exploit! Spell deleted!") end) end) end
end		if cf.aspell then event.register("spellCreated", SPELLCREATED, {filter = "service"}) end

local function ENEVENT(e) if e.property == tes3.uiProperty.mouseClick then	--tes3.messageBox("Эвент id = %s   top = %s", e.block.id, tes3ui.getMenuOnTop().id)
	if e.block.id == -267 or e.block.id == -268 then	if tes3ui.getMenuOnTop().id ~= -264 then event.unregister("uiEvent", ENEVENT) end
	else	local MENCH = tes3ui.findMenu(-264)
		if MENCH then tes3.findGMST("fEnchantmentConstantDurationMult").value = math.max((P.enc13 and 40000 or 50000)/math.max(MENCH:findChild(-296).text,200),100) end
	end
end end

local function MENUENCHANTMENT(e) event.register("uiEvent", ENEVENT) local El = e.element
if cf.spmak then
	El.minWidth = 1200	El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
	El:findChild("MenuEnchantment_magicEffectsContainer").width = 32*(vol+1)
	EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
	for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
	s:createImage{path = "icons\\" .. s:getPropertyObject("MenuEnchantment_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end
if not tes3ui.getServiceActor() then
	local SK = {[10] = mp.destruction.base, [11] = mp.alteration.base, [12] = mp.illusion.base, [13] = mp.conjuration.base, [14] = mp.mysticism.base, [15] = mp.restoration.base}
	for i, s in ipairs(El:findChild("PartScrollPane_pane").children) do if SK[s:getPropertyObject("MenuEnchantment_Effect").skill] < 50 then s.visible = false end end
end
end		event.register("uiActivated", MENUENCHANTMENT, {filter = "MenuEnchantment"})

local function MENUSPELLMAKING(e)	local El = e.element
if cf.spmak then El.minWidth = 1200		El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
	El:findChild("MenuSpellmaking_EffectsLayout").width = 32*(vol+1)
	EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
	for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
	s:createImage{path = "icons\\" .. s:getPropertyObject("MenuSpellmaking_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end
if not tes3ui.getServiceActor() then
	El:findChild("MenuSpellmaking_Buybutton"):registerBefore("mouseClick", function() local cost = El:findChild("MenuSpellmaking_SpellPointCost").text		if mp.magicka.current < cost*5 then
		tes3.messageBox("%s %d", eng and "You don't have enough mana to create this spell. Need: " or "У вас не хватает маны на создание этого заклинания. Нужно: ", cost*5)		return false
	else Mod(cost*5) end end)
	local SK = {[10] = mp.destruction.base, [11] = mp.alteration.base, [12] = mp.illusion.base, [13] = mp.conjuration.base, [14] = mp.mysticism.base, [15] = mp.restoration.base}
	for i, s in ipairs(El:findChild("PartScrollPane_pane").children) do if SK[s:getPropertyObject("MenuSpellmaking_Effect").skill] < 80 then s.visible = false end end
end
end		event.register("uiActivated", MENUSPELLMAKING, {filter = "MenuSpellmaking"})

L.ALF={[1]={75,76,77,74,79,80,84,82,117,72,73,69,70,90,91,92,93,97,99,94}, [2]={10,8,1,2,0,43,39,57,67,68,59,64,65,66}, [3]={27,23,24,25,22,18,19,20,17,35,28,29,30,31,7,45,47}, [4]={}}	L.ALFEF = {[17]=0, [22]=0, [74]=0, [79]=0, [85]=0}
L.ALE = {[75]={5,20}, [76]={5,20}, [77]={20,60}, [74]={3,10}, [79]={30,100}, [83]={30,100}, [80]={30,100}, [81]={50,100}, [82]={150,100}, [84]={15,100}, [117]={30,100}, [42]={30,100}, [72]={1,1}, [73]={1,1}, [69]={1,1}, [70]={1,1},
[90]={25,100}, [91]={25,100}, [92]={25,100}, [93]={25,100}, [97]={25,100}, [99]={25,100}, [98]={10,100}, [94]={80,300}, [95]={80,300}, [96]={80,300},
[10]={10,20}, [8]={150,100}, [3]={30,100}, [4]={10,20}, [5]={10,20}, [6]={10,20}, [1]={30,100}, [2]={1,100}, [0]={1,100}, [9]={15,60}, [11]={20,60},
[41]={30,200}, [43]={30,300}, [39]={1,60}, [40]={30,60}, [57]={100,1}, [67]={15,20}, [68]={15,20}, [59]={30,100}, [64]={200,100}, [65]={200,100}, [66]={200,100},
[27]={5,20}, [23]={5,20}, [14]={5,20}, [15]={5,20}, [16]={5,20}, [24]={10,20}, [25]={20,20}, [22]={3,10}, [18]={50,60}, [19]={100,60}, [20]={100,60}, [17]={30,60}, [21]={30,60},
[28]={30,60}, [29]={30,60}, [30]={30,60}, [31]={30,60}, [34]={30,60}, [35]={30,60}, [36]={30,60}, [32]={50,100}, [33]={50,100}, [7]={100,60}, [45]={1,5}, [46]={1,10}, [47]={50,60}, [48]={50,60}}

local function MENUALCHEMY(e)	M.Alc = e.element
	local RFI = M.Alc:findChild("PartNonDragMenu_main").children[1]:createImage{path = "icons\\potions_blocked.tga"}
	RFI:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Reset alchemy filter"} end)
	RFI:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3.messageBox("Alchemy filter reset") end)
	M.AlcCH = M.Alc:createLabel{text = ("Chance %s%%"):format(cf.alc and "?" or math.floor(mp.alchemy.current + mp.intelligence.current/10 + mp.luck.current/10))}
	M.AlcCH.absolutePosAlignY = -0.1	M.AlcCH.positionY = -247 		M.Alc:updateLayout()
	if cf.alc and not P.alc21 then M.Alc:findChild(-25):registerBefore("mouseClick", function() tes3.messageBox("%s", eng and "You are not yet skilled enough to brew 4-ingredient potions" or
	"Вы еще недостаточно искусны чтобы варить зелья из 4 ингредиентов")		return false end) end
end		event.register("uiActivated", MENUALCHEMY, {filter = "MenuAlchemy"})

local function POTIONBREWSKILLCHECK(e)	local Al, Int, Luc, Agi, Mort, Cal, Ret, Alem = mp.alchemy.base, mp.intelligence.base, mp.luck.base, mp.agility.base, math.min(e.mortar.quality,2),
	e.calcinator, e.retort, e.alembic			Cal, Ret, Alem = (Cal and math.min(Cal.quality or 0,2) or 0), (Ret and math.min(Ret.quality or 0,2) or 0), (Alem and math.min(Alem.quality or 0,2) or 0)
	local pow0 = Al/2 + Int/10 + Mort*20 + (P.luc12 and Luc/10 or 0)		local pow = math.min(pow0,100)
	local Chance = Al*(P.alc13 and 1 or 0.5) + Mort*20 + Int/5 + Agi/5 + Luc*(P.luc12 and 0.3 or 0.1) + math.max(pow0-100,0) - (Ret + Cal + Alem) * (P.alc17 and 10 or 20)
	local Mag = (P.alc3 and 60 or 40) + Ret * (P.alc14 and 10 or 5) + Cal * (P.alc16 and 10 or 5)
	local Dur = (P.alc4 and 60 or 40) + Alem * (P.alc15 and 10 or 5) + Cal * (P.alc16 and 10 or 5)
	if math.random(100) <= Chance then e.potionStrength = pow	e.success = true
	elseif P.alc18 and Chance > 20 then pow = pow * math.random(1,Chance)/100	e.potionStrength = pow		e.success = true	else e.potionStrength = -1	e.success = false end
	G.PotM = Mag * pow/10000	G.PotD = Dur * pow/10000
	M.AlcCH.text = ("Chance %d%%  Power %d%%/%d%%/%d%%"):format(Chance, pow, Mag, Dur)		--M.Alc:updateLayout()
end		if cf.alc then event.register("potionBrewSkillCheck", POTIONBREWSKILLCHECK) end

local function POTIONBREWED(e)	local ob = e.object		local Alem = e.alembic		Alem = Alem and math.min(Alem.quality or 0,2)*(P.alc19 and 1 or 0.5) or 0
--local q = L.BotIc[ob.icon]	if q then ob.mesh = ("m\\misc_potion_%s_01.nif"):format(q) end	--ob.icon = ("potions\\%s_%s.dds"):format(q, ob.effects[1].id)

local cost = 0	for _, i in ipairs(e.ingredients) do if i then cost = cost + i.value end end	mp:exerciseSkill(16, cost/50)
if cf.alc then	local E = {}	local norm = not M.drop.visible		local gold = 40
	local num = ob:getActiveEffectCount()	if num == 2 then num = 0.75 elseif num == 3 then num = 0.6 elseif num > 3 then num = 0.5 end		if num < 1 and not P.alc23 then num = num - 0.1 end
	for i, ef in ipairs(ob.effects) do E[i] = ef	if ef.id ~= -1 then local AE = L.ALE[ef.id]		local harm = norm == ef.object.isHarmful		gold = gold + (harm and -20 or 20)
	if AE then E[i].min = math.max(G.PotM * AE[1]/(harm and (1 + Alem*2) or 1), 1)		E[i].max = E[i].min		E[i].duration = math.max(G.PotD * num * AE[2]/(harm and (1 + Alem) or 1), 1) end end end
	tes3.removeItem{reference = p, item = ob, playSound = false}
	tes3.addItem{reference = p, item = tes3alchemy.create({name = ob.name, mesh = ob.mesh, icon = ob.icon, weight = P.alc20 and 0.5 or 1, value = G.PotM * G.PotD * math.max(gold,10) * (P.alc8 and 1 or 0.5), effects = E}),
	count = 1 + (P.alc22 and (math.random(150) <= mp.alchemy.base/2 + mp.luck.base) and 1 or 0), playSound = false}
end			--	tes3.messageBox("id = %s  name = %s   cost = %d", ob.id, ob.name, cost)
end		event.register("potionBrewed", POTIONBREWED)

local function FilterEnchant(e) if M.EncFilt then local o = e.item	 if o.objectType == tes3.objectType.weapon and not o.enchant and o.id:sub(1,1) == "*" and tes3.getObject(o.id:sub(2)) then e.filter = false end end end
local function FilterAlc(e) if M.Alf and e.item.objectType == tes3.objectType.ingredient then local filt = false	for i, ef in ipairs(e.item.effects) do if ef == M.Alf then
	if L.ALFEF[ef] and M.AlfAt then if e.item.effectAttributeIds[i] == M.AlfAt then filt = true	break end else filt = true	break end
end end		e.filter = filt end end

local function MENUINVENTORYSELECT(e) e.element.height = 1000	e.element.width = 800	local Name = e.element:findChild("MenuInventorySelect_prompt").text			L.skmag = 1
if Name == tes3.findGMST("sIngredients").value then		if not M.AlcFilt then event.register("filterInventorySelect", FilterAlc)	M.AlcFilt = true end		local EL = {{},{},{},{}}
	for l, tab in ipairs(L.ALF) do if (M.drop.visible and l > 2) or (not M.drop.visible and l ~=3) then	EL[l].b = e.element:createThinBorder{}	EL[l].b.autoHeight = true	EL[l].b.autoWidth = true	for i, ef in ipairs(tab) do
		EL[l][i] = EL[l].b:createImage{path = "icons/s/b_" .. tes3.getMagicEffect(ef).icon:sub(3)}		EL[l][i]:register("mouseClick", function() M.Alf = ef	tes3ui.updateInventorySelectTiles() end)
		EL[l][i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = tes3.getMagicEffect(ef).name} end)
	end end end
	for i = 0, 7 do EL[4][i] = EL[4].b:createImage{path = L.ATRIC[i]}		EL[4][i]:register("mouseClick", function() M.AlfAt = i	tes3ui.updateInventorySelectTiles() end)
	EL[4][i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = L.ATR[i]} end) end
	EL[4][8] = EL[4].b:createImage{path = "icons/k/magic_alchemy.dds"}		EL[4][8]:register("mouseClick", function() M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][8]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "All Attributes"} end)
	EL[4][9] = EL[4].b:createImage{path = "icons/potions_blocked.tga"}		EL[4][9]:register("mouseClick", function() M.Alf = nil	M.AlfAt = nil	tes3ui.updateInventorySelectTiles() end)
	EL[4][9]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = "Reset alchemy filter"} end)
--[[
e.element.width = 1200	local vol = 20	local num = #e.element:findChild("PartScrollPane_pane").children	local stolb, lin	--tes3.messageBox("children = %s", num)
for i, s in ipairs(e.element:findChild("PartScrollPane_pane").children) do	s.height = 40		s.width = 300	s.autoHeight = true		s.autoWidth = true
	lin = i%vol		if lin == 0 then lin = vol end		stolb = (i - lin)/vol
	s.absolutePosAlignX = stolb * 0.36		s.absolutePosAlignY = (lin - 1) * 0.05
	--s.positionX = stolb * 300		s.positionY = (lin - 1) * -42
	tes3.messageBox("width = %s", s.width)
end
--]]
else	if Name == tes3.findGMST("sEnchantItems").value and not M.EncFilt then	event.register("filterInventorySelect", FilterEnchant)	M.EncFilt = true end
end end		event.register("uiActivated", MENUINVENTORYSELECT, {filter = "MenuInventorySelect"})

local function ITEMTILEUPDATED(e)	local ob = e.item
	if ob.objectType == tes3.objectType.alchemy then	local eob = ob.effects[1].object	if eob then
		local Eic = e.element:createImage{path = ("icons\\%s"):format(eob.icon)}		--("icons\\s\\b_%s.tga"):format(icon)	Eic.width = 16		Eic.height = 16		Eic.scaleMode = true
		Eic.absolutePosAlignX = 1.0		Eic.absolutePosAlignY = 0.2		Eic.consumeMouseEvents = false
	end
end end		if cf.lab then event.register("itemTileUpdated", ITEMTILEUPDATED) end

local function MENUEXIT(e)
	if M.EncFilt then M.EncFilt = nil 	event.unregister("filterInventorySelect", FilterEnchant) end
	if M.AlcFilt then M.AlcFilt = nil	event.unregister("filterInventorySelect", FilterAlc) end
end			event.register("menuExit", MENUEXIT)

local function MENUQUICK(e)	local Q = {}	Q.bl = e.element:createThinBorder{}		Q.bl.autoHeight = true	Q.bl.autoWidth = true
local CS = mp.currentSpell		CS = CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (CS.alwaysSucceeds or P.int3) and CS or nil
for i = 1, 10 do	local s = D.QSP[tostring(i)] and tes3.getObject(D.QSP[tostring(i)])		Q[i] = Q.bl:createImage{path = s and "icons\\" .. s.effects[1].object.bigIcon or "icons/k/magicka.dds"}
	if i == 10 then Q[i]:register("mouseClick", function() D.QSP["0"] = nil		tes3.messageBox("Universal extra-cast slot") end)
	else
		Q[i]:register("mouseClick", function()
			if CS and ic:isShiftDown() then D.QSP[tostring(i)] = CS.id		tes3.messageBox("%s remembered for %s extra-cast slot", CS.name, i) end
			if s and M.QB.normalized >= (P.spd11 and 0.5 or 1) then
				D.QSP["0"] = tostring(i)		QS = tes3.getObject(D.QSP[D.QSP["0"]])		M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
				tes3.messageBox("%s prepared for extra-cast  Slot %s  %s", QS.name, D.QSP["0"], QS.alwaysSucceeds and "Is a technique" or "")
			end
		end)
	end
	Q[i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = s and ("Extra-cast slot %s  -  %s    Cost = %s    %s"):format(i, s.name, s.magickaCost, s.alwaysSucceeds and "Is a technique" or "") or
	("Extra-cast slot %s  -  %s %s"):format(i, i == 10 and "Universal" or "Press LMB with Shift to place the current spell in this slot.", P.int3 and "" or "Without a special perk only techniques are available")} end)
end	e.element:updateLayout() end		event.register("uiActivated", MENUQUICK, {filter = "MenuQuick"})

local function UISPELLTOOLTIP(e) local tt = e.tooltip:findChild(tes3ui.registerID("helptext"))	tt.text = ("%s (%d)"):format(tt.text, e.spell.magickaCost) end		event.register("uiSpellTooltip", UISPELLTOOLTIP)


local function ENCHANTEDITEMCREATED(e)
	e.object.value = e.baseObject.value * (1 + e.soul.soul/500)

	--tes3.messageBox("[enchantedItemCreated] Item: %s; Base: %s; Soul: %s (%s); Enchanter: %s", e.object, e.baseObject, e.soulGem, e.soul, e.enchanterReference)
end		event.register("enchantedItemCreated", ENCHANTEDITEMCREATED)


local function BARTEROFFER(e)	local m = e.mobile	local k = 0		local C		--#e.selling	#e.buying	tile.item, tile.count		Эвент не срабатывает если игрок не изменил цену первого предложения!
if e.value > 0 then k = e.offer/e.value - 1 else k = e.value/e.offer - 1 end
if k > 0 then	local k0 = 0.1 + (((e.value > 0 and P.merc12) or (e.value < 0 and P.merc11)) and 0.1 or 0) + (P.per11 and math.min(mp.personality.current,100)/2000 or 0)		local disp = m.object.disposition or 50
	if k <= k0 then C = 50*((P.merc4 and 1.1 or 1) - k/k0) * math.min(disp, P.per13 and 150 or 100)/100
		* (20 + mp.mercantile.current + mp.speechcraft.current/(P.spec10 and 2.5 or 5) + (P.per12 and math.min(mp.personality.current,100)/5 or 0) + (P.luc5 and math.min(mp.luck.current,100)/5 or 0))/(m:getSkillValue(24)+50)
	else C = 0 end
	M.Bart2.text = ("  %d%%/%d  %d%%/%d%%"):format(C, disp, k*100, k0*100)
	if cf.m6 then tes3.messageBox("Chance = %d  Koef = %.1f%%  Max = %.1f%%  Gold = %d (%d - %d) Merc = %d  Disp = %d", C, k*100, k0*100, e.offer - e.value, e.offer, e.value, m:getSkillValue(24), disp) end
	e.success = math.random(100) < C		if e.success then mp:exerciseSkill(24, math.abs(e.value)/1000 + (e.offer - e.value)/30) end
end
end

local function BarterK(m) local ob = m.object	local rang = ob.faction and ob.faction.playerRank + 1 or 0		return rang,
(mp.mercantile.current + mp.speechcraft.current/(P.spec3 and 5 or 10) + mp.personality.current/(P.per3 and 5 or 10) + (P.luc5 and mp.luck.current/10 or 0) + rang*(P.spec5 and 10 or 5) + (P.per8 and p.object.factionIndex/2 or 0))/200,
(m:getSkillValue(24) + m:getSkillValue(25)/5 + m.personality.current/5 + m.luck.current/10 + 150 - math.min(ob.disposition or 50, P.per13 and 150 or 100) - (P.per14 and ob.female == not p.object.female and 30 or 0))/200
end
local function CALCBARTERPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		--if e.item.id == "Gold_001" then e.price = e.count		buying (игрок покупает)
	local k0 = 1 + (e.buying and (P.merc10 and 0.5 or 0.7) or (P.merc2 and 0.8 or 1))		local koef = math.max(k0 - k1 + k2, 1.25)		local val	local ob, ida = e.item, e.itemData
	if ob.isSoulGem and ida and ida.soul then	local soulval = ida.soul.soul	val = (soulval ^ 3) / 10000 + soulval * 2
	elseif ida and ida.condition and ob.maxCondition then val = ob.value * (0.5 + ida.condition * 0.5 / ob.maxCondition)
	else val = ob.value end
	local bp = math.max(e.buying and math.ceil(val * koef) or math.floor(val / koef), 1)			e.price = bp * e.count
	M.Bart1.text = (" %d%%"):format(koef*100 - 100)
	if cf.m6 then tes3.messageBox("%d = %d * %d   Koef = %.2f (%.2f - %.2f + %.2f)  Disp/Rang = %s/%s", e.price, bp, e.count, koef, k0, k1, k2, e.mobile.object.disposition, rang) end
end
local function CALCPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		local koef = math.max(1 - k1 + k2, 0.5)		e.price = e.basePrice * koef
	if cf.m6 then tes3.messageBox("Price = %d (base = %d)  Rang = %s  koef = %.2f (1 - %.2f + %.2f)", e.price, e.basePrice, rang, koef, k1, k2) end
end
if cf.barter then event.register("calcBarterPrice", CALCBARTERPRICE)		event.register("barterOffer", BARTEROFFER)	
event.register("calcTrainingPrice", CALCPRICE)	event.register("calcSpellPrice", CALCPRICE)	event.register("calcTravelPrice", CALCPRICE) event.register("calcRepairPrice", CALCPRICE) end


local function MENUBARTER(e) local m = tes3ui.getServiceActor()		local ai = m.object.aiConfig	local aisave
	if P.merc9 then aisave = {}		for it, _ in pairs(L.BartT) do aisave[it] = ai[it]	ai[it] = true end		timer.delayOneFrame(function() for it, _ in pairs(L.BartT) do ai[it] = aisave[it] end end) end
	if P.merc3 then local DI = m.reference.data		local bob = m.object.baseObject		if not DI.invest then DI.invest = {g = bob.barterGold, i = 0} end	DI = DI.invest
		local max = math.round(mp.mercantile.base/10)		local gold = math.ceil(DI.g/2)
		M.Invest = e.element:findChild("MenuBarter_yourgold").parent:createFillBar{current = DI.i, max = 10}		M.Invest.width = 150	M.Invest.height = 12	M.InvestW = M.Invest.widget		M.InvestW.fillColor = {1,0.9,0}	M.InvestW.showText = false
		M.Invest:register("help", function() tes3ui.createTooltipMenu():createLabel{text = ("%s: %d / %d  (%s %d)"):format(eng and "Investments" or "Инвестиции", M.InvestW.current, max,
		eng and "Click LMB to invest" or "Нажмите ЛКМ чтобы инвестировать", gold)} end)
		M.Invest:register("mouseClick", function() if DI.i < max and tes3.getPlayerGold() >= gold then DI.i = DI.i + 1		bob.barterGold = DI.g * math.min(1 + DI.i * 0.1, 2)		mp:exerciseSkill(24, gold/100)
			tes3.removeItem{reference = p, item = "gold_001", count = gold}		M.InvestW.current = DI.i	M.Invest:updateLayout()
			tes3.messageBox("Invested in %s   Gold = %s / %s  Investments: %s / %s", bob.id, m.barterGold, bob.barterGold, DI.i, max)
			if aisave then timer.delayOneFrame(function() bob.modified = true end) else bob.modified = true end
		end end)
	end
	M.Bart = e.element:findChild("MenuBarter_Price").parent
	M.Bart1 = M.Bart:createLabel{text = " 0%"}	M.Bart1:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Markup" or "Наценка"} end)
	M.Bart2 = M.Bart:createLabel{text = " "}	M.Bart2:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Chance for a deal / Merchant's disposition    Profit / Max profit" or
	"Шанс на сделку / Отношение торговца   Выгода / Максимальная выгода"} end)
	M.Bart:reorderChildren(2, 3, 2)
	
--	for _, stack in pairs(m.object.baseObject.inventory) do mwse.log("base  %s - %s", stack.count, stack.object.id) end
--	for _, stack in pairs(m.object.inventory) do mwse.log("%s - %s", stack.count, stack.object.id) end
	--timer.delayOneFrame(function() m.health.current = 0		TFR(2, function() tes3.runLegacyScript{command = "resurrect", reference = m.reference} end) end, timer.real)
end		event.register("uiActivated", MENUBARTER, {filter = "MenuBarter"})

local function MENUPERSUASION(e)	local m = tes3ui.getServiceActor()		if mp.fatigue.normalized > 1 then mp.fatigue.current = mp.fatigue.base end
if mp.intelligence.current + mp.speechcraft.current + (P.spec1 and 100 or 0) > 150 then
	local fPersMod, fLuckMod, fRepMod, fFatigueBase, fFatigueMult, fLevelMod = tes3.findGMST(1150).value, tes3.findGMST(1151).value, tes3.findGMST(1152).value, tes3.findGMST(1006).value, tes3.findGMST(1007).value, tes3.findGMST(1153).value
	local pLucPers = mp.personality.current/fPersMod + mp.luck.current/fLuckMod		local d = 1 - math.abs(math.min(m.object.disposition,100) - 50)/50
	local npcRepLucPers = m.personality.current/fPersMod + m.luck.current/fLuckMod + m.object.factionIndex * fRepMod
	local pFat = fFatigueBase - fFatigueMult * (1 - mp.fatigue.normalized)			local npcFat = fFatigueBase - fFatigueMult * (1 - m.fatigue.normalized)
	local RAT = 50 + (p.object.factionIndex * fRepMod + pLucPers + mp.speechcraft.current) * pFat - (npcRepLucPers + m.speechcraft.current) * npcFat
	local T = {}	T[1] = d * RAT		T[3] = T[1]		T[2] = d * (RAT + p.object.level * fLevelMod - m.object.level * fLevelMod * npcFat)
	local brib = d * (((pLucPers + mp.mercantile.current) * pFat) - ((npcRepLucPers + m.mercantile.current) * npcFat) + 50)
	T[4], T[5], T[6] = brib + tes3.findGMST(1154).value, brib + tes3.findGMST(1155).value, brib + tes3.findGMST(1156).value			for i=1,6 do T[i] = math.max(tes3.findGMST(1159).value, T[i]) end
	for i, b in ipairs(e.element:findChild(-633).children) do if i < 7 then local t = b.children[1]		t.text = ("%s:  %d%%"):format(t.text, T[i]) end end		e.element:updateLayout()
end
end		event.register("uiActivated", MENUPERSUASION, {filter = "MenuPersuasion"})

local function MENUDIALOG(e)	local r	= tes3ui.getServiceActor().reference	local id = r.baseObject.id		-- закомменчен
	if L.SSEL[id] then for i, sp in ipairs(L.SSEL[id]) do mwscript.addSpell{reference = r, spell = sp} end		--tes3.messageBox("%s get new spells", id)
		if id == "marayn dren" then for _, num in ipairs(L.SFS) do mwscript.addSpell{reference = r, spell = "4s_"..num} end end
	end
end		--event.register("uiActivated", MENUDIALOG, {filter = "MenuDialog"})

local function LOCKPICK(e) L.sksec = e.lockData.level/50 end		event.register("lockPick", LOCKPICK)
local function TRAPDISARM(e) if e.lockData and e.lockData.trap then L.sksec = e.lockData.trap.magickaCost * 10 / (e.lockData.trap.magickaCost + 80) end end		event.register("trapDisarm", TRAPDISARM)


L.SKG = {[0]=1, [2]=1, [3]=1, [4]=1, [5]=1, [6]=1, [7]=1, [8]=1, [17]=1, [18]=1, [19]=1, [20]=1, [21]=1, [22]=1, [23]=1, [26]=1, [9]=2, [10]=2, [11]=2, [12]=2, [13]=2, [14]=2, [15]=2, [1]=3, [16]=3, [24]=4, [25]=4}
L.SKFC = {{0, 1, 0}, {0, 1, 1}, {1, 0, 1}, {1, 1, 0}}			L.SKF = {40, 60, 100, 100}
local function EXERCISESKILL(e) local sk = e.skill
	if sk == 8 then	e.progress = e.progress * (1 + mp.encumbrance.normalized * 2) else		-- Атлетика
		local gr = L.SKG[sk]	local fatk = math.max(100 - D.ExpFat[gr]/((gr == 1 or sk == 24) and 60 or 30), 0)
		if L.SK[sk] then
			if sk == 5 then if W.wt == -2 then e.progress = 0	mp:exerciseSkill(7, 1)	return end end		-- Копья в 1 руке
			e.progress = e.progress * L[L.SK[sk]] * fatk/100
		else e.progress = e.progress * fatk/100 end
	--	D.ExpFat[gr] = math.min(D.ExpFat[gr] + cf.expfat * (gr == 1 and 1 or 2), 3600)
		if cf.fatbar then M.FatBarW.current = fatk		M.FatBarW.fillColor = L.SKFC[gr] 	M.FatBar:updateLayout() end
		if cf.m7 then tes3.messageBox("%s exp = %.2f   fatigue koef = %d%% (%d minutes)", tes3.skillName[sk], e.progress, fatk, D.ExpFat[gr]/60) end
	end
end		if cf.trmod then event.register("exerciseSkill", EXERCISESKILL, {priority = -10}) end

local function SKILLRAISED(e)	local sk = e.skill
if cf.levmod then	local lup = 0.25
	for _, s in pairs(p.object.class.majorSkills) do if s == sk then lup = 1 end end		for _, s in pairs(p.object.class.minorSkills) do if s == sk then lup = 1 end end
	local atr, atr2 = tes3.getSkill(sk).attribute, L.SA2[sk]	local Aname, Aname2 = L.ATR[atr], L.ATR[atr2]	D.L[Aname] = D.L[Aname] + 3		D.L[Aname2] = D.L[Aname2] + 2	D.L.levelup = D.L.levelup + lup
	if D.L[Aname] >= 10 then D.L[Aname] = D.L[Aname] - 10		if mp[Aname].base < 100 then tes3.modStatistic{reference = p, attribute = atr, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname) end end
	if D.L[Aname2] >= 10 then D.L[Aname2] = D.L[Aname2] - 10	if mp[Aname2].base < 100 then tes3.modStatistic{reference = p, attribute = atr2, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname2) end end
	if D.L.levelup >= 10 then	D.L.levelup = D.L.levelup - 10		if p.object.level < 100 then
		tes3.messageBox("!!! LEVEL UP !!!")		tes3.streamMusic{path="Special\\MW_Triumph.mp3"}		mwscript.setLevel{reference = p, level = p.object.level + 1}
		if mp.luck.base < 100 then tes3.modStatistic{reference = p, attribute = 7, value = 1} elseif mp.personality.base < 100 then tes3.modStatistic{reference = p, attribute = 6, value = 1} end
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))		menu:findChild(tes3ui.registerID("MenuStat_level")).text = p.object.level	menu:updateLayout()
		if p.object.level * G.leskoef > D.L.les and G.stop.value == 1 then G.stop.value = 0 end
	end end
	mp.levelUpProgress = math.min(D.L.levelup, 8)	if cf.m7 then tes3.messageBox("Attr: %s + %s = %s,  %s + %s = %s   Lvl + %s = %s", Aname, 3, D.L[Aname], Aname2, 2, D.L[Aname2], lup, D.L.levelup) end
end
if cf.skillp and e.source == "training" then -- progress, book, training
	D.L.les = D.L.les + 1		if p.object.level * G.leskoef <= D.L.les then	G.stop.value = 1 end
	tes3.messageBox("Trained already %s times. %s left. %s", D.L.les, p.object.level * G.leskoef - D.L.les, G.stop.value == 0 and "" or "It's time to put the acquired knowledge into practice")
end
if cf.trmod then	local gr = L.SKG[sk]	local tim = T.T1.timing - G.Exptim
	for i = 1, 4 do	D.ExpFat[i] = math.clamp(D.ExpFat[i] + (gr == i and L.SKF[i] or 20) * cf.expfat - tim, 0, 3600) end		G.Exptim = T.T1.timing
end
end		event.register("skillRaised", SKILLRAISED)


L.UpdateSpellM = function()	local ob, ic, mc	local ls = cf.lin	local F1 = {}	local S = {}	local ST = {[0]=4, 7, 3, 6, 5, 2}	 local SS = {{}, {}, {}, {}, {}, {}, {}}	local FS = table.invert(D.FS)
local MM = tes3ui.findMenu("MenuMagic")	local PL = MM:findChild("MagicMenu_power_names")	PL.borderBottom = 5		PL.flowDirection = "left_to_right"		local SL = MM:findChild("MagicMenu_spell_names")
local MC = MM:findChild("PartScrollPane_pane").children		MC[1].visible = false	MC[3].visible = false	MC[4].visible = false	MC[6].visible = false	MC[7].visible = false
MM:findChild("MagicMenu_power_costs").visible = false		MM:findChild("MagicMenu_spell_costs").visible = false		MM:findChild("MagicMenu_spell_percents").visible = false
MM:findChild("MagicMenu_icons_list_inner").flowDirection = "left_to_right"
for i, s in ipairs(PL.children) do s:createImage{path = "icons\\" .. s:getPropertyObject("MagicMenu_Spell").effects[1].object.bigIcon}	s.minHeight = 32	s.minWidth = 32		s.text = " " end
for i, s in ipairs(SL.children) do s.minHeight = 32		s.minWidth = 32		s.text = " "		ob = s:getPropertyObject("MagicMenu_Spell")		ic = s:createImage{path = "icons\\" .. ob.effects[1].object.bigIcon}
	if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.magickaCost)}		mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end
	if FS[ob.id] then F1[FS[ob.id]] = s else table.insert(SS[ob.alwaysSucceeds and 1 or ST[ob:getLeastProficientSchool(mp)]], s) end
end
local F = {}	for k, v in ipairs(table.keys(F1, true)) do F[k] = F1[v] end
for ii, tab in ipairs(SS) do for i, s in ipairs(tab) do table.insert(S, s) end end
if SL.children[1] then SL.children[1]:register("destroy", function(e) timer.delayOneFrame(L.UpdateSpellM, timer.real) end) end
local Flin = math.ceil(#F/ls)	local Slin = math.ceil(#S/ls)	local ML = Flin + Slin
MC[5].maxHeight = 32*ML	+ 5		SL.minWidth = 32*(ls+1)		SL.maxWidth = SL.minWidth	SL.minHeight = 32*(ML+1)	SL.maxHeight = SL.minHeight
for i, s in ipairs(F) do s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/ls)-1) end
for i, s in ipairs(S) do s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ML * (math.ceil(i/ls)-1+Flin) end
end

L.UpdateEnM = function() local MM = tes3ui.findMenu("MenuMagic")		local MC = MM:findChild("PartScrollPane_pane").children		local ob, ic, icm, mc		local ls = cf.lin
local IL = MM:findChild("MagicMenu_item_names")	local ILin = math.max(math.ceil(#IL.children/ls), 1)		MC[8].maxHeight = 32*ILin + 5
IL.minWidth = 32*(ls+1)		IL.maxWidth = IL.minWidth	IL.minHeight = 32*(ILin+1)	IL.maxHeight = IL.minHeight
for i, s in ipairs(IL.children) do s.minHeight = 32		s.minWidth = 32		s.text = nil	ob = s:getPropertyObject("MagicMenu_object")		ic = s:createImage{path = ("icons\\%s"):format(ob.icon)}
if ob.objectType ~= tes3.objectType.book then icm = ic:createImage{path = ("icons\\%s"):format(ob.enchantment.effects[1].object.icon)}		icm.absolutePosAlignX = 1	icm.absolutePosAlignY = 1
if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.enchantment.chargeCost)}	mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end end
s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ILin * (math.ceil(i/ls)-1) end
if IL.children[1] then IL.children[1]:register("destroy", function(e) M.EnDF = false	if tes3ui.menuMode() then timer.delayOneFrame(L.UpdateEnM, timer.real) end end)	M.EnDF = true end
end


local function MENUENTER(e)
	if M.INV and M.INV.visible then	L.GetArStat()
		M.INV:findChild("MenuInventory_Weightbar"):findChild("PartFillbar_text_ptr").text = ("%d/%d"):format(mp.encumbrance.currentRaw, mp.encumbrance.base)
	end
	if cf.UIen and not M.EnDF then local MagM = tes3ui.findMenu("MenuMagic")		if MagM and MagM.visible and MagM:findChild("MagicMenu_item_names").children[1] then L.UpdateEnM() end end
end		event.register("menuEnter", MENUENTER)


local function calcRestInterrupt(e) if e.resting and tes3.getJournalIndex{id = "TR_DBHunt"} < 100 then local reput = p.object.factionIndex	if reput >= cf.dbrep then
	local st = tes3.getSimulationTimestamp()
	if st - (D.DBAlast or 0) > 12 and math.random(100) < 20 + reput*2 then D.DBAcount = (D.DBAcount or 0) + 1		D.DBAlast = st		local AST, num
		if D.DBAcount > 9 then AST = {"db_assassin3", "db_assassin4"}						num = 3
		elseif D.DBAcount > 6 then AST = {"db_assassin2", "db_assassin3", "db_assassin4"}	num = table.choice{2,2,3}
		elseif D.DBAcount > 3 then AST = {"db_assassin1", "db_assassin2", "db_assassin3"}	num = table.choice{1,2,2}
		else AST = {"db_assassin1b", "db_assassin1b", "db_assassin1", "db_assassin1", "db_assassin2"}		num = table.choice{1,1,1,2} end
		tes3.wakeUp()		tes3.messageBox(eng and "You were awakened by a loud noise" or "Вы пробудились от громкого шума")
		for i = 1, num do mwscript.placeAtPC{object = table.choice(AST), distance = 128, direction = 1} end
	end
	--tes3.messageBox("Rest %s    Num = %d   Hour = %d   last + %d   count = %s", e.resting, e.count, e.hour, st - (D.DBAlast or 0), D.DBAcount)
end end end		event.register("calcRestInterrupt", calcRestInterrupt)

local function SAVE(e) if cf.nosave and mp.inCombat then tes3.messageBox(eng and "You cannot save the game in combat" or "Нельзя сохраняться в бою")		return false else
--	D.MPlast = PMP.current
	if W.DWM then D.DW = {IDR = W.WR.id, IDL = W.WL.id, CondR = W.DR.condition, CondL = W.DL.condition} end
	if cf.trmod then local tim = T.T1.timing - G.Exptim		for i = 1, 4 do	D.ExpFat[i] = math.max(D.ExpFat[i] - tim, 0) end		G.Exptim = T.T1.timing end
end end		event.register("save", SAVE)

local function LOAD(e)
if T.AoE.timeLeft then for i, t in pairs(AOE) do t.r:delete() end	AOE = {} end
if T.Run.timeLeft then for i, t in pairs(RUN) do t.r:delete() end RUN = {} end
if T.Tot.timeLeft then for i, t in pairs(TOT) do t.r:delete() end TOT = {} end
if table.size(LI.R) ~= 0 then	for ref, _ in pairs(LI.R) do ref:delete() end  LI.R = {} end
if V.bcd then event.unregister("calcMoveSpeed", L.BLAST)	V.bcd = nil		KSR = {} end
if T.LI.timeLeft then event.unregister("simulate", LI.SIM)	LI.r = nil end
if T.DET.timeLeft then DEDEL() end
if p then AF[p] = nil	end
if cf.tut then G.Tut = table.choice(L.TUT)[eng and 2 or 1] end
--wc.blindnessFader:deactivate()	--устраняет баг со слепотой
end		event.register("load", LOAD)


local function MENULOADING(e)
	if not T.Tut.timeLeft then T.Tut = timer.start{type = timer.real, duration = 5, callback = function() G.Tut = nil end} end
	G.Tut = G.Tut or table.choice(L.TUT)[eng and 2 or 1]
	e.element:createLabel{text = G.Tut}
end		if cf.tut then event.register("uiActivated", MENULOADING, {filter = "MenuLoading"}) end


local function LOADED(e) p = tes3.player	mp = tes3.mobilePlayer	ad = mp.actionData		pp = p.position		D = tes3.player.data	inv = p.object.inventory	p1 = tes3.player1stPerson.sceneNode		p3 = p.sceneNode
crot = wc.worldCamera.cameraRoot.rotation		G.pori = p.orientation
if not D.Mmod then D.Mmod = {} end	DM = D.Mmod		if not D.perks then D.perks = {} end	P = D.perks		if not D.traits then D.traits = {} end	G.TR = D.traits	
if not D.FS then D.FS = {} end
if not D.AR then D.AR = {l=0,m=0,h=0,u=25,as=0,ms=1,dk=1,dc=0,cs=0,cc=0,mc=0} end
if not D.L then D.L = {strength = 0, endurance = 0, intelligence = 0, willpower = 0, speed = 0, agility = 0, personality = 0, levelup = 0, les = 0} end
if not D.LEG then D.LEG = {} end	if not D.MSEF then D.MSEF = {} end
if cf.trmod then	D.ExpFat = D.ExpFat or {0,0,0,0}	G.Exptim = 0 end
AF[p] = {}		SNC = {}	COL = {}	W = {}	V.BAL = {}	V.MET = {}	V.METR = {}		R = {}	com = 0		L.ClearEn()		L.SetGlobal()		G.DopW = {}
L.UpdTSK()	--wc.simulationTimeScalar = 1
G.ck = ic.inputMaps[tes3.keybind.readyMagic + 1].code		--G.sis = wc.timescale.value/3600
G.LastMana = nil	PMP = mp.magicka		
--if D.MPlast	then --PMP.current = D.MPlast		PMP.base = mp.magickaMultiplier.current * mp.intelligence.current * 2
	--tes3.setStatistic{reference = p, name = "magicka", current = D.MPlast, base = mp.magickaMultiplier.current * mp.intelligence.current * 2}
--end		tes3.messageBox("Mana %s   %s    mult %s   int %s", PMP.current, PMP.base, mp.magickaMultiplier.current, mp.intelligence.current)


if tes3.isAffectedBy{reference = p, effect = 501} then AF[p].T501 = timer.start{duration = 1, iterations = -1, callback = L.RechargeTik}	G.REI = {} end

W.l1 = p1:getObjectByName("Bip01 L Hand")		W.l3 = p3:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.r3 = p3:getObjectByName("Bip01 R Hand")
W.w1 = p1:getObjectByName("Weapon Bone")		W.w3 = p3:getObjectByName("Weapon Bone")		event.unregister("playItemSound", L.DWESound, {priority = 10000})		L.MagefAdd()

local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object
if w then	if D.DW then
	if w.id == D.DW.IDR and wd.condition == D.DW.CondR then L.DWNEW(w, wd, false)		local ob = tes3.getObject(D.DW.IDL)
		for i, ida in pairs(inv:findItemStack(ob).variables) do if ida.condition == D.DW.CondL and ida ~= W.DR then L.DWNEW(ob, ida, true)	break end end
	elseif w.id == D.DW.IDL and wd.condition == D.DW.CondL then L.DWNEW(w, wd, true)	local ob = tes3.getObject(D.DW.IDR)
		for i, ida in pairs(inv:findItemStack(ob).variables) do if ida.condition == D.DW.CondR and ida ~= W.DL then L.DWNEW(ob, ida, false)	break end end
	end
	D.DW = nil
elseif WT[w.type].dw then L.DWNEW(w, wd, false) end end


for ref, _ in pairs(PRR) do ref:delete() end		PRR = {}
if D.ligspawn then	local spawn = 0	for _, cell in pairs(tes3.getActiveCells()) do for r in cell:iterateReferences() do if r.baseObject.id == "4nm_light" then spawn = spawn + 1	r:delete() end end end
if spawn > 0 then tes3.messageBox("%s lights extra deleted", spawn) end		D.ligspawn = nil	LI.r = nil end

B.poi = tes3.getObject("4b_poison") or tes3alchemy.create{id = "4b_poison", name = "4b_poison", weight = 0.1, icon = "s\\b_tx_s_sun_dmg.dds"}	--B.poi.sourceless = true
if D.AUR then T.AUR = timer.start{duration = P.alt11 and math.max(3 - mp:getSkillValue(11)/200, 2.5) or 3, iterations = -1, callback = L.AuraTik} end

local MU = tes3ui.findMenu("MenuMulti")	M.MU = MU			M.Stat = tes3ui.findMenu("MenuStat")	M.INV = tes3ui.findMenu("MenuInventory")
local IcLA = MU:findChild("MenuMulti_icons_layout")			local FbLA = MU:findChild("MenuMulti_fillbars_layout")
M.BarH = MU:findChild("MenuStat_health_fillbar")			M.BarM = MU:findChild("MenuStat_magic_fillbar")			M.BarS = MU:findChild("MenuStat_fatigue_fillbar")
M.Mana = M.BarM.widget		--M.Mana.current = PMP.current 	M.Mana.max = PMP.base
local QBL = IcLA:createBlock{}		QBL.autoHeight = true	QBL.autoWidth = true	QBL.borderAllSides = 2		QBL.flowDirection = "top_to_bottom"
M.Qicon = QBL:createImage{path = "icons/k/magicka.dds"}		M.Qicon.borderAllSides = 2
M.Qicon:register("help", function() if QS then tes3ui.createTooltipMenu():createLabel{text = ("%s (%s)"):format(QS.name, QS.magickaCost)} end end)
G.ExMax = 50 + mp.willpower.base/2 + (P.wil13 and 50 or 0)
M.Qbar = QBL:createFillBar{current = G.ExMax, max = G.ExMax}	M.Qbar.width = 36		M.Qbar.height = 5		M.QB = M.Qbar.widget	M.QB.showText = false		M.QB.fillColor = {0,1,0}	L.NoBorder(M.Qbar)
M.PIC = IcLA:createBlock{}		M.PIC.visible = false	M.PIC.autoHeight = true		M.PIC.autoWidth = true	M.PIC.borderAllSides = 2	M.PIC.flowDirection = "top_to_bottom"
local Picon = M.PIC:createImage{path = "icons/potions_blocked.tga"}	Picon.borderAllSides = 2
local potbar = M.PIC:createFillBar{current = 30, max = 30}	potbar.width = 36		potbar.height = 5		M.PCD = potbar.widget	M.PCD.showText = false		M.PCD.fillColor = {0,1,1}		L.NoBorder(potbar)
if D.potcd then M.PIC.visible = true	T.POT = timer.start{duration = 1, iterations = -1, callback = function() D.potcd = D.potcd - 1	if D.potmcd then D.potmcd = D.potmcd - 1	if D.potmcd <= 0 then D.potmcd = nil end end
	if D.potmcd and D.potmcd > D.potcd - G.potlim then M.PCD.max = 5	M.PCD.current = D.potmcd else M.PCD.max = 30	M.PCD.current = D.potcd - G.potlim	if M.PCD.current <= 0 then M.PIC.visible = false end end
	if D.potcd <= 0 then D.potcd = nil	T.POT:cancel() end
end} end
M.drop = IcLA:createImage{path = "icons/poisondrop.tga"}	M.drop.visible = not not D.poimod
IcLA:reorderChildren(5, 2, 1)
M.MSPD = IcLA:createLabel{text = ""}	M.MSPD.color = {1,1,1}


local Npc = MU:findChild("MenuMulti_npc")		Npc.flowDirection = "top_to_bottom"		Npc.alpha = 0
M.AR = M.INV and M.INV:findChild("MenuInventory_ArmorRating") or Npc:createBlock{}	M.AR.minWidth = 150		M.AR.width = 150		M.AR:register("help", function()
local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt.flowDirection = "top_to_bottom"
tt:createLabel{text = ("%s: %d  %s"):format(eng and "lightness" or "Легкость", math.max(-mp.encumbrance.currentRaw,0), eng and "Armor parts:" or "Части брони:")}
tt:createLabel{text = ("%s: %d"):format(eng and "Light" or "Легкие", D.AR.l)}
tt:createLabel{text = ("%s: %d"):format(eng and "Medium" or "Средние", D.AR.m)}
tt:createLabel{text = ("%s: %d"):format(eng and "Heavy" or "Тяжелые", D.AR.h)}
tt:createLabel{text = ("%s: %d"):format(eng and "Unarmored" or "Бездоспешные", D.AR.u)}
tt:createLabel{text = eng and "Speed:" or "Скорость:"}
tt:createLabel{text = ("%s: %d"):format(eng and "Base" or "База", G.spdk0)}
tt:createLabel{text = ("%s: %d%%"):format(eng and "Armor" or "Доспехи", G.spdk1 * 100)}
tt:createLabel{text = ("%s: %d%%"):format(eng and "Encumbrance" or "Нагрузка", G.spdk2 * 100)}
tt:createLabel{text = ("%s: %d%%"):format(eng and "Fatigue" or "Усталость", G.spdk3 * 100)}
tt:createLabel{text = ("%s: %d%%"):format(eng and "Move type" or "Тип движения", G.spdk4 * 100)}
end)
M.MI = (M.INV and M.INV:findChild("MenuInventory_character_box") or M.AR):createBlock{}	M.MI.autoHeight = true	M.MI.autoWidth = true	M.MI.flowDirection = "top_to_bottom"
M.SL2 = M.MI:createBlock{}	M.SL2.autoHeight = true	M.SL2.autoWidth = true		M.SL3 = M.MI:createBlock{}	M.SL3.autoHeight = true	M.SL3.autoWidth = true		M.SL4 = M.MI:createBlock{}	M.SL4.autoHeight = true	M.SL4.autoWidth = true
M.SI11 = M.AR:createImage{path = "icons/s/repairArmor.tga"}		M.SI11.borderRight = 28		M.ST11 = M.AR:createLabel{}		M.ST11.borderRight = 5
M.SI12 = M.AR:createImage{path = "icons/s/dash.tga"}	M.ST12 = M.AR:createLabel{}
M.SI21 = M.SL2:createImage{path = "icons/s/chargeFire.tga"}			M.ST21 = M.SL2:createLabel{}	M.ST21.borderRight = 5
M.SI21:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Physical Damage Modifier" or "Модификатор физического урона"} end)
M.SI22 = M.SL2:createImage{path = "icons/s/repairWeapon.tga"}		M.ST22 = M.SL2:createLabel{}
M.SI22:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Attack Speed / Maximum combo" or "Cкорость атаки / Максимум комбо"} end)
M.SI31 = M.SL3:createImage{path = "icons/s/recharge.tga"}			M.ST31 = M.SL3:createLabel{}	M.ST31.borderRight = 5
M.SI31:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Magic power modifier" or "Модификатор мощности магии"} end)
M.SI32 = M.SL3:createImage{path = "icons/s/empowerShock.tga"}	M.ST32 = M.SL3:createLabel{}	M.ST32.borderRight = 5
M.SI32:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Mana cost modifier" or "Модификатор стоимости заклинаний"} end)
M.SI33 = M.SL3:createImage{path = "icons/s/projectileControl.tga"}		M.ST33 = M.SL3:createLabel{}
M.SI33:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Cast chance modifier" or "Модификатор шанса каста"} end)
M.SI41 = M.SL4:createImage{path = "icons/s/tx_s_sanctuary.dds"}		M.ST41 = M.SL4:createLabel{}	M.ST41.borderRight = 5
M.SI41:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Passive dodge / Dodge maneuver / Stamina cost for dodge maneuver" or "Пассивное уклонение / Маневр уклонения / Расход стамины на маневр уклонения"} end)
M.SI42 = M.SL4:createImage{path = "icons/s/tx_s_feather.dds"}		M.ST42 = M.SL4:createLabel{}
M.SI42:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Stamina cost for attacks / jumping / running" or "Расход стамины на атаки / прыжки / бег"} end)
M.ENLB = M.MI:createFillBar{current = D.ENconst or 0, max = 4000 + mp.enchant.base*20 + (P.enc16 and 2000 or 0)}
M.ENLB.width = 150	M.ENLB.height = 10	M.ENL = M.ENLB.widget	M.ENL.showText = false	M.ENL.fillColor = {0,1,1}		L.NoBorder(M.ENLB)
M.ENLB:register("help", function() tes3ui.createTooltipMenu():createLabel{text = ("%s: %d / %d"):format(eng and "Constant enchant limit" or "Лимит постоянных зачарований", M.ENL.current, M.ENL.max)} end)

--if M.INV then
	--M.INV:register("update", function() M.INV:findChild("MenuInventory_Weightbar"):findChild("PartFillbar_text_ptr").text = ("%d/%d"):format(mp.encumbrance.currentRaw, mp.encumbrance.base) 	tes3.messageBox("update") end)	
--end

M.SHbar = FbLA:createFillBar{current = 100, max = 100}	L.NoBorder(M.SHbar)	M.SHbar.visible = false	M.SHbar.widget.showText = false	M.SHbar.widget.fillColor = {0,1,1}	M.SHbar.width = 65	M.SHbar.height = 5	M.SHbar.borderLeft = 2
M.Bar4 = Npc:createFillBar{current = 0, max = L.GetPCmax()}		M.Bar4.width = 65	M.Bar4.height = 12	L.NoBorder(M.Bar4)	M.PC = M.Bar4.widget	M.PC.showText = false	M.PC.fillColor = {0.6,0,1}

local WLA = MU:findChild("MenuMulti_weapon_layout")
if cf.newUI then		--M.BarM:register("PartScrollBar_changed", function() tes3.messageBox("update mag") end)
	L.NoBorder(M.BarH)		L.NoBorder(M.BarM)		L.NoBorder(M.BarS)		M.BarH.width = 150		M.BarM.width = 150		M.BarS.width = 150		M.Bar4.width = 150		M.SHbar.width = 150
	L.NoBorder(MU:findChild("MenuMulti_weapon_border"),0)	L.NoBorder(MU:findChild("MenuMulti_magic_border"),0)		L.NoBorder(MU:findChild("MenuMulti_magic_icons_1"),0)
	L.NoBorder(MU:findChild("MenuMulti_weapon_fill"))		L.NoBorder(MU:findChild("MenuMulti_magic_fill"))			MU:findChild("MenuMulti_magic_layout").alpha = 0		--WLA.alpha = 0
	M.BarH.widget.fillColor = {1,0,0.4}		M.BarM.widget.fillColor = {0,0.5,1}		M.BarS.widget.fillColor = {0,0.75,0}
	local NpcHB = MU:findChild("MenuMulti_npc_health_bar")		L.NoBorder(NpcHB)		--L.NoBorder(MU:findChild("MenuMulti_sneak_icon").children[1], 0)
	--NpcHB.ignoreLayoutX = true		NpcHB.ignoreLayoutY = true		NpcHB.positionX = 200	NpcHB.positionY = 200	NpcHB:updateLayout()
	
	
--	WLA.borderAllSides = 0
--	M.SpFB = MU:findChild("MenuMulti_magic_fill")	M.SpFB.widget.fillColor = {0,1,0}
--	M.WeFB = MU:findChild("MenuMulti_weapon_fill")	M.WeFB.widget.fillColor = {1,0,0}
end
if cf.UInum then	M.Mana.showText = true			M.BarH.widget.showText = true		M.BarS.widget.showText = true		M.PC.showText = true
	M.Mana.current = mp.magicka.current		M.BarH.widget.current = mp.health.current		M.BarS.widget.current = mp.fatigue.current
	L.BarText(M.BarH)	L.BarText(M.BarM)	L.BarText(M.BarS)	L.BarText(M.Bar4)
end

M.BB = {}	M.BBM = MU:createBlock{}	M.BBM.autoWidth = true		M.BBM.autoHeight = true		M.BBM.borderAllSides = 7	M.BBM.absolutePosAlignX = cf.BBrig and 1 or 0		M.BBM.absolutePosAlignY = 0
if not cf.BBhor then M.BBM.flowDirection = "top_to_bottom" end
if cf.BBen then local dur, cur	for _, aef in pairs(mp:getActiveMagicEffects{}) do dur = aef.duration	if dur > 1 then cur = dur - aef.effectInstance.timeActive	if cur > 0 then
L.NewBB(aef.effectId, tes3.getMagicEffect(aef.effectId).bigIcon, dur, aef.serial * 10 + aef.effectIndex, cur) end end end end

if cf.nomic then MU:findChild("MenuMulti_magic_icons_layout").visible = false end

T.PCT = timer.start{duration = 1, iterations = -1, callback = function() M.PC.current = M.PC.current + M.PC.max/100 + tes3.getEffectMagnitude{reference = p, effect = 76} * (P.enc18 and 0.5 or 0.3)
	if M.PC.normalized > 1 then M.PC.current = M.PC.max		T.PCT:cancel()	D.PCcur = nil	M.Bar4.visible = false else D.PCcur = M.PC.current end
end}
M.PC.current = D.PCcur or M.PC.max		if not D.PCcur then T.PCT:cancel()	M.Bar4.visible = false end


if not D.QSP then D.QSP = {} end
QS = D.QSP["0"] and tes3.getObject(D.QSP[D.QSP["0"]]) or (mp.currentSpell and mp.currentSpell.objectType == tes3.objectType.spell and mp.currentSpell.castType == 0 and (P.int3 or mp.currentSpell.alwaysSucceeds) and mp.currentSpell)
if QS then M.Qicon.contentPath = "icons\\" .. QS.effects[1].object.bigIcon end


W.BAR = WLA:createFillBar{current = 10, max = 10}	W.BAR.width = 36	W.BAR.height = 5	L.NoBorder(W.BAR)		W.BAR.visible = false
W.bar = W.BAR.widget	W.bar.showText = false		W.bar.fillColor = D.NoEnStrike and {1,0,0} or {0,1,1}
T.T1 = timer.start{duration = 1, iterations = -1, callback = function()		if W.en then W.bar.current = W.v.charge end
	--for actor in tes3.iterate(mp.friendlyActors) do if actor ~= mp and actor.inCombat and actor.actionData.aiBehaviorState == -1 then
		--	actor:stopCombat()		tes3.messageBox("%s   Beh = %s", actor.reference, actor.actionData.aiBehaviorState)
	--end end
	if table.size(M.BB) > 0 then local n	for _, aef in pairs(mp:getActiveMagicEffects{}) do	local B = M.BB[aef.effectId]	B = B and B[aef.serial * 10 + aef.effectIndex]		B = B and B.widget
		if B then B.current = B.max - aef.effectInstance.timeActive		n = math.remap(B.current, cf.BBred, cf.BBgr, 0, 1)		B.fillColor = {2-n*2, n*2, n-1} end
	end end
end}

L.GetWstat()
M.WPB = WLA:createFillBar{current = D.poison or 0, max = 300}	M.WPB.width = 36	M.WPB.height = 5	M.WPB.widget.showText = false	M.WPB.widget.fillColor = {0,1,0}	L.NoBorder(M.WPB)	M.WPB.visible = not not D.poison
M.MCbar = MU:findChild("MenuMulti_magic_layout"):createFillBar{current = 0, max = 100}	M.MCbar.width = 36	M.MCbar.height = 5	M.MCB = M.MCbar.widget	M.MCB.showText = false	M.MCB.fillColor = {0,1,1}		L.NoBorder(M.MCbar)

local WeIC = MU:findChild("MenuMulti_weapon_icon")
M.CombK = WeIC:createLabel{text = ""}	M.CombK.color = {1,1,1}		M.CombK.absolutePosAlignX = 1	M.CombK.absolutePosAlignY = 0		--M.CombK.visible = false
if G.TR.tr5 then D.nopar = nil end
M.NoPar = WeIC:createLabel{text = "*"}	M.NoPar.color = {1,0,0}			M.NoPar.absolutePosAlignX = 0	M.NoPar.absolutePosAlignY = 1		M.NoPar.visible = not not D.nopar



M.EDBL = MU:createBlock{}	M.EDBL.autoHeight = true	M.EDBL.autoWidth = true		M.EDBL.absolutePosAlignX = 0.5	M.EDBL.absolutePosAlignY = 0.52		M.EDBL.flowDirection = "top_to_bottom"		M.EDBL.visible = false
M.EDb = M.EDBL:createFillBar{current = 100, max = 100}	M.EDb.width = 30	M.EDb.height = 5	L.NoBorder(M.EDb)	M.EDB = M.EDb.widget
M.EDT = M.EDBL:createLabel{text = ""}	M.EDT.absolutePosAlignX = 0.5	M.EDT.color = {1,1,1}	M.EDT.font = 1
T.EDMG = timer.start{duration = 1, iterations = 1, callback = function() M.EDBL.visible = false end}	T.EDMG:cancel()


M.EBLO = MU:createBlock{}	M.EBLO.autoHeight = true	M.EBLO.autoWidth = true		M.EBLO.flowDirection = "top_to_bottom"	M.EBLO.absolutePosAlignX = 0.5	M.EBLO.absolutePosAlignY = cf.enbarpos/100	M.EBLO.visible = false
M.EBN = M.EBLO:createLabel{text = ""}	M.EBN.absolutePosAlignX = 0.5	M.EBN.color = {1,1,1}	
M.Ebh = M.EBLO:createFillBar{current = 100, max = 100}	M.Ebh.width = 300	M.Ebh.height = 12	L.NoBorder(M.Ebh)	M.EBH = M.Ebh.widget	M.EBH.fillColor = {1,0,0.4}		L.BarText(M.Ebh)
M.EBLO2 = M.EBLO:createBlock{}	M.EBLO2.autoHeight = true	M.EBLO2.autoWidth = true		if not P.int4 then M.EBLO2.visible = false end
M.Ebm = M.EBLO2:createFillBar{current = 100, max = 100}	M.Ebm.width = 150	M.Ebm.height = 12	L.NoBorder(M.Ebm)	M.EBM = M.Ebm.widget	M.EBM.fillColor = {0,0.5,1}		L.BarText(M.Ebm)
M.Ebs = M.EBLO2:createFillBar{current = 100, max = 100}	M.Ebs.width = 150	M.Ebs.height = 12	L.NoBorder(M.Ebs)	M.EBS = M.Ebs.widget	M.EBS.fillColor = {0,0.8,0}		L.BarText(M.Ebs)
--M.Ebm:updateLayout()	Matr:toRotationY(math.rad(180))		M.Ebm.sceneNode.rotation = Matr:copy()		M.Ebm.absolutePosAlignX = 0.5	--M.Ebs.absolutePosAlignX = 0.5


if cf.fatbar then
	M.MAP = MU:findChild("MenuMulti_map")		M.MAP.flowDirection = "top_to_bottom"	--M.MAP.alpha = tes3.worldController.menuAlpha
	M.FatBar = M.MAP:createFillBar{current = 100, max = 100}	M.FatBar.width = 65		M.FatBar.height = 6		M.FatBarW = M.FatBar.widget		M.FatBarW.showText = false	M.FatBarW.fillColor = {0, 1, 0}		L.NoBorder(M.FatBar)
	M.FatBar:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Training fatigue" or "Тренировочная усталость"} end)		
	M.MAP:reorderChildren(0, table.size(M.MAP.children) - 1, 1)
end


local o = tes3.getObject("4s_536")
if not o or o.effects[1].duration ~= 0 then	local s			tes3.messageBox("New effects and spells updated")
	for _, t in ipairs(L.NEWSP) do s = tes3.getObject("4s_"..t[1]) or tes3spell.create("4s_"..t[1])	--s.sourceless = true
	s.name = t[9]		s.magickaCost = t[8] or 0	s = s.effects[1]	s.rangeType = t[2]	s.id = t[3]		s.min = t[4]	s.max = t[5]	s.radius = t[6]		s.duration = t[7] end	
	for id, t in pairs(L.PA) do s = tes3.getObject("4p_"..id) or tes3spell.create("4p_"..id)	s.name = eng and t[5] or t[4] or "4p_"..id	s.castType = 1	s = s.effects[1]	s.id = t[1]		s.min = t[2]	s.max = t.m or t[2] end
	for id, t in pairs(L.NSU) do s = tes3.getObject(id) or tes3spell.create(id)		s.name = eng and t.en or t.ru		s.magickaCost = t.c		if t.f then s.alwaysSucceeds = true end		s = s.effects
	for i, ef in ipairs(t) do s[i].rangeType = t.rt	or 0	s[i].id	= ef[1]		s[i].min = ef[2] or t.m		s[i].max = ef[3] or t.ma	s[i].radius = ef.r or t.r or 0		s[i].duration = ef.d or t.d		s[i].attribute = ef.a or -1 end end
end

o = tes3.getObject("marayn dren")
if not o.spells:contains("4s_602a") then				for _, num in ipairs(L.SFS) do o.spells:add("4s_"..num) end
	for id, list in pairs(L.SSEL) do o = tes3.getObject(id)		for i, sp in ipairs(list) do o.spells:add(sp) end	o.modified = true end	--tes3.messageBox("Spellsellers get new spells")
end

if not e.newGame then L.READY = true	local PS = {}	local PA = {}	PS.sp = p.object.class.specialization	local id	local b = L.BS[mp.birthsign.id]
	for _, s in pairs(p.object.class.majorSkills) do PS[s] = 1 end		for _, s in pairs(p.object.class.minorSkills) do PS[s] = 2 end		for _, at in pairs(p.object.class.attributes) do PA[at] = true end
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do	id = L.PRL[i][3]		--mp[L.PRL[i][1]].type
		if i < 9 then t.x = PA[id] and 1 or 2 else t.x = (PS[id] or 3) - ((L.SS[id] == PS.sp and 1 or 0) + (PA[L.SA[id]] and 1 or 0) + (PA[L.SA2[id]] and 1 or 0) > 1 and 1 or 0) end
		t.f = math.max(t.x - (t.c or 0),0)
	end end
	if not D.chimstar and b and p.object.level >= 20 then
		mwscript.removeSpell{reference = p, spell = "4nm_star_"..b.."1"}	mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."2"}
		if tes3.getObject("4nm_star_"..b.."2a") then mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."2a"} end
		if b == "atronach" then mwscript.addSpell{reference = p, spell = "4as_atr4"}	mwscript.addSpell{reference = p, spell = "4as_atr5"}	mwscript.addSpell{reference = p, spell = "4as_atr6"} end
		tes3.messageBox(eng and "You have awakened the power of your Birth Sign" or "Вы пробудили силу своего Знака")	D.chimstar = 1
	elseif D.chimstar == 1 and b and p.object.level >= 50 then
		mwscript.removeSpell{reference = p, spell = "4nm_star_"..b.."2"}	mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."3"}
		if tes3.getObject("4nm_star_"..b.."3a") then mwscript.addSpell{reference = p, spell = "4nm_star_"..b.."3a"} end
		if b == "atronach" then mwscript.addSpell{reference = p, spell = "4as_atr7"}	mwscript.addSpell{reference = p, spell = "4as_atr8"}	mwscript.addSpell{reference = p, spell = "4as_atr9"}	mwscript.addSpell{reference = p, spell = "4as_atr10"} end
		tes3.messageBox(eng and "You have ascended to level of the gods and unleashed the true potential of your Birth Sign" or "Вы вознеслись до уровня богов и раскрыли истинный потенциал своего Знака")	D.chimstar = 2
	end
	if cf.UIsp then L.UpdateSpellM() end
	if cf.UIen then local MM = tes3ui.findMenu("MenuMagic")	MM:findChild("MagicMenu_item_costs").visible = false		MM:findChild("MagicMenu_item_percents").visible = false		M.EnDF = false end
else L.READY = nil		tes3.messageBox(eng and "The perks menu (F2) will be available after the first save loading" or "Меню перков (F2) будет доступно после первой загрузки сейва") end
end		event.register("loaded", LOADED)

local function initialized(e)	wc = tes3.worldController	ic = wc.inputController		MB = ic.mouseState.buttons		local o, E
--ГМСТ едины для игровой сессии и обновляются из плагинов при старте игры. Если поменять ГМСТ через луа, то они сохранятся для всех последующих сейвов в этой сессии но сбросятся на дефолтные при следующем запуске игры
wc.mobManager.gravity.z = -1000		wc.mobManager.terminalVelocity.z = -5000

G.VFXspark = tes3.createObject{objectType = tes3.objectType.static, id = "VFX_WSparks", mesh = "e\\spark.nif"}			G.VFXsum = tes3.getObject("VFX_Summon_Start")
G.KOGMST = tes3.findGMST("iKnockDownOddsBase")			G.KOGMST.value = 100
G.CombatDistance = tes3.findGMST("fCombatDistance")		G.CombatAngleXY = tes3.findGMST("fCombatAngleXY")			--tes3.findGMST("fCombatAngleZ").value = 0.666
--G.CriticalMult = tes3.findGMST("fCombatCriticalStrikeMult")

tes3.findGMST("fHandToHandReach").value = 0.7
if cf.npcatak then tes3.findGMST("fCombatDelayCreature").value = -0.5		tes3.findGMST("fCombatDelayNPC").value = -0.5 end
tes3.findGMST("fEffectCostMult").value = 1				tes3.findGMST("fNPCbaseMagickaMult").value = 5			tes3.findGMST("iAutoSpellTimesCanCast").value = 5
tes3.findGMST("fTargetSpellMaxSpeed").value = 2000		tes3.findGMST("fEnchantmentMult").value = 0.1			--tes3.findGMST("fMagicCreatureCastDelay").value = 0
tes3.findGMST("fFatigueSpellBase").value = 0.5			tes3.findGMST("fFatigueSpellMult").value = 0.5			tes3.findGMST("fElementalShieldMult").value = 1
tes3.findGMST("fEncumberedMoveEffect").value = 0.5		tes3.findGMST("fBaseRunMultiplier").value = 3			tes3.findGMST("fSwimRunBase").value = 0.3
tes3.findGMST("fFallDistanceMult").value = 0.1			tes3.findGMST("fFallDamageDistanceMin").value = 400		tes3.findGMST("fFallAcroBase").value = 1
tes3.findGMST("fFatigueReturnBase").value = 0			tes3.findGMST("fFatigueReturnMult").value = 0.2			tes3.findGMST("fFatigueBase").value = 1.5					tes3.findGMST("fFatigueMult").value = 0.5
tes3.findGMST("fFatigueAttackBase").value = 10			tes3.findGMST("fFatigueAttackMult").value = 10			tes3.findGMST("fWeaponFatigueMult").value = 1
tes3.findGMST("fFatigueBlockBase").value = 5			tes3.findGMST("fFatigueBlockMult").value = 10			tes3.findGMST("fWeaponFatigueBlockMult").value = 2
tes3.findGMST("fCombatBlockLeftAngle").value = -1		tes3.findGMST("fCombatBlockRightAngle").value = 0.5
tes3.findGMST("fFatigueRunBase").value = 10				tes3.findGMST("fFatigueRunMult").value = 30				tes3.findGMST("fFatigueSwimWalkBase").value = 10			tes3.findGMST("fFatigueSwimWalkMult").value = 30
tes3.findGMST("fFatigueSwimRunBase").value = 20			tes3.findGMST("fFatigueSwimRunMult").value = 30			tes3.findGMST("fFatigueSneakBase").value = 0				tes3.findGMST("fFatigueSneakMult").value = 10
tes3.findGMST("fMinHandToHandMult").value = 0			tes3.findGMST("fMaxHandToHandMult").value = 0.2			tes3.findGMST("fHandtoHandHealthPer").value = 0.25
tes3.findGMST("fKnockDownMult").value = 0				tes3.findGMST("iKnockDownOddsMult").value = 0			tes3.findGMST("fCombatKODamageMult").value = 1.5		
tes3.findGMST("fDamageStrengthBase").value = 1			tes3.findGMST("fDamageStrengthMult").value = 0.05		tes3.findGMST("fCombatArmorMinMult").value = 0.01
tes3.findGMST("fProjectileMinSpeed").value = 2000		tes3.findGMST("fProjectileMaxSpeed").value = 6000		tes3.findGMST("fThrownWeaponMinSpeed").value = 2000			tes3.findGMST("fThrownWeaponMaxSpeed").value = 3000	
tes3.findGMST("fAIFleeHealthMult").value = 88.888		tes3.findGMST("fFleeDistance").value = 5000				tes3.findGMST("fAIRangeMeleeWeaponMult").value = 70			tes3.findGMST("fSuffocationDamage").value = 10
tes3.findGMST("fAIFleeFleeMult").value = 0	--0.3	 float rating = (1.0f - healthPercentage) * fAIFleeHealthMult + flee * fAIFleeFleeMult;
tes3.findGMST("fSleepRestMod").value = 0.5				tes3.findGMST("fDispDiseaseMod").value = -30			tes3.findGMST("fSpecialSkillBonus").value = 0.8
tes3.findGMST("fRestMagicMult").value = 0.5				tes3.findGMST("iMonthsToRespawn").value = 7				tes3.findGMST("fProjectileThrownStoreChance").value = 0
tes3.findGMST("sArmor").value = " "
tes3.findGMST("sMagicPCResisted").value = ""	tes3.findGMST("sMagicTargetResisted").value = ""	tes3.findGMST("sMagicInsufficientCharge").value = ""	tes3.findGMST("sTargetCriticalStrike").value = ""	
tes3.findGMST("spoint").value = ""		tes3.findGMST("spoints").value = ""		tes3.findGMST("spercent").value = ""		tes3.findGMST("sXTimesINT").value = ""		tes3.findGMST("sTo").value = "-"


tes3.dataHandler.nonDynamicData.magicEffects[19].hasContinuousVFX = false

if cf.enbar then tes3.findGMST("fNPCHealthBarTime").value = 0		tes3.findGMST("fNPCHealthBarFade").value = 0 end
if cf.alc then tes3.findGMST("fPotionT1MagMult").value = 2		tes3.findGMST("fPotionT1DurMult").value = 0.5 end

--for _, v in ipairs(L.SREG) do o = tes3spell.create("4s_"..v, "4s_"..v) 	o.magickaCost = 0	o.sourceless = true		S[v] = o end
for _, n in ipairs(L.BREG) do o = tes3.createObject{objectType = tes3.objectType.alchemy, id = "4b_"..n, name = "4b_"..n, icon = "s\\b_tx_s_sun_dmg.dds"} 	o.sourceless = true 	B[n] = o 	G[n] = o.effects end
for _, t in ipairs(L.BU) do o = tes3.createObject{objectType = tes3.objectType.alchemy, id = "4b_"..t.n, name = "4b_"..t.n, icon = "s\\b_tx_s_sun_dmg.dds"}	o.sourceless = true		o.weight = t.w or 0		B[t.n] = o	E = o.effects
for i, ef in ipairs(t) do E[i].rangeType = ef[1]	E[i].id = ef[2]		E[i].min = ef[3]	E[i].max = ef[4]	E[i].radius = ef[5]		E[i].duration = ef[6] end end

BAM.E = tes3.getObject("4nm_e_boundammo").effects		LI.l = tes3.getObject("4nm_light")		L.stone = tes3.getObject("4nm_stone")		L.magef = tes3.loadMesh("e\\magef.nif")
L.pbottle = tes3.getObject("4nm_poisonbottle")
L.DEO = {["door"] = {m = tes3.loadMesh("e\\detect_door.nif"), s = 3}, ["cont"] = {m = tes3.loadMesh("e\\detect_cont.nif"), s = 3}, ["npc"] = {m = tes3.loadMesh("e\\detect_npc.nif"), s = 1},
["ani"] = {m = tes3.loadMesh("e\\detect_animal.nif"), s = 1}, ["dae"] = {m = tes3.loadMesh("e\\detect_daedra.nif"), s = 1}, ["und"] = {m = tes3.loadMesh("e\\detect_undead.nif"), s = 1},
["robo"] = {m = tes3.loadMesh("e\\detect_robo.nif"), s = 1}, ["key"] = {m = tes3.loadMesh("e\\detect_key.nif"), s = 2}, ["en"] = {m = tes3.loadMesh("e\\detect_ench.nif"), s = 2}}

local S = {[0] = {l = {0.5,0,1}, p = "vfx_alt_glow.tga", sc = "alteration cast", sb = "alteration bolt", sh = "alteration hit", sa = "alteration area", vc = "VFX_AlterationCast", vb = "VFX_AlterationBolt", vh = "VFX_AlterationHit", va = "VFX_AlterationArea"},
[1] = {l = {1,1,0}, p = "vfx_conj_flare02.tga", sc = "conjuration cast", sb = "conjuration bolt", sh = "conjuration hit", sa = "conjuration area", vc = "VFX_ConjureCast", vb = "VFX_ConjureBolt", vh = "VFX_DefaultHit", va = "VFX_ConjureArea"},
[2] = {l = {1,0,0}, p = "vfx_alpha_bolt01.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_DestructCast", vb = "VFX_DestructBolt", vh = "VFX_DestructHit", va = "VFX_DestructArea"},
[3] = {l = {0,1,0.5}, p = "vfx_greenglow.tga", sc = "illusion cast", sb = "illusion bolt", sh = "illusion hit", sa = "illusion area", vc = "VFX_IllusionCast", vb = "VFX_IllusionBolt", vh = "VFX_IllusionHit", va = "VFX_IllusionArea"},
[4] = {l = {1,0.5,1}, p = "vfx_myst_flare01.tga", sc = "mysticism cast", sb = "mysticism bolt", sh = "mysticism hit", sa = "mysticism area", vc = "VFX_MysticismCast", vb = "VFX_MysticismBolt", vh = "VFX_MysticismHit", va = "VFX_MysticismArea"},
[5] = {l = {0,0.5,1}, p = "vfx_bluecloud.tga", sc = "restoration cast", sb = "restoration bolt", sh = "restoration hit", sa = "restoration area", vc = "VFX_RestorationCast", vb = "VFX_RestoreBolt", vh = "VFX_RestorationHit", va = "VFX_RestorationArea"},
[6] = {l = {1,0.5,0}, p = "e\\vfx_##lensw.dds", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_FireCast", vb = "VFX_FireBolt", vh = "VFX_FireHit", va = "VFX_FireArea"},
[7] = {l = {0,1,1}, p = "e\\vfx_frsstr.dds", sc = "frost_cast", sb = "frost_bolt", sh = "frost_hit", sa = "frost area", vc = "VFX_FrostCast", vb = "VFX_FrostBolt", vh = "VFX_FrostHit", va = "VFX_FrostArea"},
[8] = {l = {1,0,1}, p = "e\\vfx_shock1.dds", sc = "shock cast", sb = "shock bolt", sh = "shock hit", sa = "shock area", vc = "VFX_LightningCast", vb = "VFX_ShockBolt", vh = "VFX_LightningHit", va = "VFX_LightningArea"},
[9] = {l = {0.5,1,0}, p = "vfx_poison.tga", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_PoisonCast", vb = "VFX_PoisonBolt", vh = "VFX_PoisonHit", va = "VFX_PoisonArea"},
[10] = {l = {1,0,0.5}, p = "e\\vfx_spark_red.dds", sc = "destruction cast", sb = "destruction bolt", sh = "destruction hit", sa = "destruction area", vc = "VFX_DestructCast", vb = "VFX_DestructBolt", vh = "VFX_DestructHit", va = "VFX_DestructArea"}}
local MEN = {{600, "dash", "Dash", 1, s=0, "Gives the ability to quickly move in the selected direction", c1=0, c2=0},
{601, "boundAmmo", "Bound ammo", 1, s=1, "Bounds arrows, bolts or throwing stars from Oblivion", c1=0, c2=0, nom=1},
{602, "kineticStrike", "Kinetic strike", 3, s=0, "A burst of power knocks back enemies and deals damage", c0=0, c1=0, nod=1, h=1, snd=2, sh = "Sound Test", col = KSCollision, tik = function(e) e.effectInstance.state = tes3.spellState.retired end},
{603, "boundWeapon", "Bound weapon", 5, s=1, "Bounds any weapon from Oblivion", c1=0, c2=0, nom=1, tik = function(e) e:triggerBoundWeapon(D and D.boundw or "4_bound longsword") end},
{610, "bolt", "Dummy bolt", 0.01, s=2, ss=6, "Dummy bolt", c0=0, c1=0, h=1, nod=1, nom=1, unr=1, ale=0, als=0, vfb = "VFX_DefaultBolt", sb = "Sound Test", tik = L.METW, col = L.METCOL},
{500, "teleport", "Teleport", 10, s=4, "Teleports caster to the point, indicated by him", c0=0, c1=0, nod=1, nom=1, sp=2, col = TeleportCollision},
{501, "recharge", "Recharge", 10, s=4, "Restores charges of equipped magic items", ale=0},
{502, "repairWeapon", "Repair weapon", 5, s=0, "Repairing equipped weapon"},
{503, "repairArmor", "Repair armor", 3, s=0, "Repairing equipped armor"},
{504, "lightTarget", "Magic light", 0.1, s=0, "Creates a light, following a caster or attached to hit point", snd=3, vfx=3, col = LightCollision},
{505, "teleportToTown", "Teleport to town", 1000, s=4, "Teleports the caster to the town", c1=0, c2=0, nod=1, nom=1, ale=0, tik = L.TownTP},
{506, "projectileControl", "Projectile control", 1, s=0, "Allows to control projectile flight", c1=0, c2=0, nom=1},
{507, "reflectSpell", "Reflect magic", 1, s=4, "Reflects enemy spells or neutralizes their power"},
{508, "kineticShield", "Kinetic shield", 1, s=0, "Absorbs physical damage, spending mana", vfh="VFX_ShieldHit", vfc="VFX_ShieldCast"},
{509, "lifeLeech", "Life leech", 0.5, s=4, "Heals for a portion of your physical damage"},
{510, "timeShift", "Time shift", 1, s=3, "Slows perception of time"},
{511, "chargeFire", "Charge fire", 0.5, s=4, ss=6, "Adds fire damage to attacks", snd=4},
{512, "chargeFrost", "Charge frost", 0.5, s=4, ss=7, "Adds frost damage to attacks", snd=4},
{513, "chargeShock", "Charge shock", 0.5, s=4, ss=8, "Adds shock damage to attacks", snd=4},
{514, "chargePoison", "Charge poison", 0.5, s=4, ss=9, "Adds poison damage to attacks", snd=4},
{515, "chargeVitality", "Charge chaos", 0.5, s=4, ss=10, "Adds chaos damage to attacks", snd=4},
{516, "auraFire", "Aura fire", 6, s=2, ss=6, "Deals fire damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_FireShield"},
{517, "auraFrost", "Aura frost", 6, s=2, ss=7, "Deals frost damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_FrostShield"},
{518, "auraShock", "Aura shock", 6, s=2, ss=8, "Deals shock damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_LightningShield"},
{519, "auraPoison", "Aura poison", 10, s=2, ss=9, "Deals poison damage to all enemies around you", con=1, c1=0, c2=0},
{520, "auraVitality", "Aura chaos", 8, s=2, ss=10, "Deals chaos damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_DestructHit"},
{521, "aoeFire", "AoE fire", 3, s=2, ss=6, "Deals fire damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{522, "aoeFrost", "AoE frost", 3, s=2, ss=7, "Deals frost damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{523, "aoeShock", "AoE shock", 3, s=2, ss=8, "Deals shock damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{524, "aoePoison", "AoE poison", 5, s=2, ss=9, "Deals poison damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{525, "aoeVitality", "AoE chaos", 4, s=2, ss=10, "Deals chaos damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{526, "runeFire", "Rune fire", 3, s=2, ss=6, "Creates fire rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{527, "runeFrost", "Rune frost", 3, s=2, ss=7, "Creates frost rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{528, "runeShock", "Rune shock", 3, s=2, ss=8, "Creates shock rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{529, "runePoison", "Rune poison", 5, s=2, ss=9, "Creates poison rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{530, "runeVitality", "Rune chaos", 4, s=2, ss=10, "Creates chaos rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{531, "explodeFire", "Explode fire", 0.5, s=4, ss=6, "Adds fire blasts to your magic projectiles", c1=0, c2=0, snd=4},
{532, "explodeFrost", "Explode frost", 0.5, s=4, ss=7, "Adds frost blasts to your magic projectiles", c1=0, c2=0, snd=4},
{533, "explodeShock", "Explode shock", 0.5, s=4, ss=8, "Adds shock blasts to your magic projectiles", c1=0, c2=0, snd=4},
{534, "explodePoison", "Explode poison", 0.5, s=4, ss=9, "Adds poison blasts to your magic projectiles", c1=0, c2=0, snd=4},
{535, "explodeVitality", "Explode chaos", 0.5, s=4, ss=10, "Adds chaos blasts to your magic projectiles", c1=0, c2=0, snd=4},
{536, "shotgunFire", "Spread fire", 15, s=2, ss=6, "Shoots a group of fire balls", c0=0, c2=0},
{537, "shotgunFrost", "Spread frost", 15, s=2, ss=7, "Shoots a group of frost balls", c0=0, c2=0},
{538, "shotgunShock", "Spread shock", 15, s=2, ss=8, "Shoots a group of shock balls", c0=0, c2=0},
{539, "shotgunPoison", "Spread poison", 25, s=2, ss=9, "Shoots a group of poison balls", c0=0, c2=0},
{540, "shotgunVitality", "Spread chaos", 20, s=2, ss=10, "Shoots a group of chaos balls", c0=0, c2=0},
{541, "dischargeFire", "Discharge fire", 3, s=2, ss=6, "Explosion of fire strikes everyone around", c0=0, c2=0},
{542, "dischargeFrost", "Discharge frost", 3, s=2, ss=7, "Explosion of frost strikes everyone around", c0=0, c2=0},
{543, "dischargeShock", "Discharge shock", 3, s=2, ss=8, "Explosion of lightning strikes everyone around", c0=0, c2=0},
{544, "dischargePoison", "Discharge poison", 5, s=2, ss=9, "Explosion of poison strikes everyone around", c0=0, c2=0},
{545, "dischargeVitality", "Discharge chaos", 4, s=2, ss=10, "Explosion of chaos strikes everyone around", c0=0, c2=0},
{546, "rayFire", "Ray fire", 30, s=2, ss=6, "Fires a ray of fire", c0=0, c2=0},
{547, "rayFrost", "Ray frost", 30, s=2, ss=7, "Fires a ray of frost", c0=0, c2=0},
{548, "rayShock", "Ray shock", 30, s=2, ss=8, "Fires a ray of lightning", c0=0, c2=0},
{549, "rayPoison", "Ray poison", 50, s=2, ss=9, "Fires a ray of poison", c0=0, c2=0},
{550, "rayVitality", "Ray chaos", 40, s=2, ss=10, "Fires a ray of chaos magic", c0=0, c2=0},
{551, "totemFire", "Totem fire", 0.5, s=4, ss=6, "Creates a totem that shoots fire at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{552, "totemFrost", "Totem frost", 0.5, s=4, ss=7, "Creates a totem that shoots frost at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{553, "totemShock", "Totem shock", 0.5, s=4, ss=8, "Creates a totem that shoots lightning at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{554, "totemPoison", "Totem poison", 0.5, s=4, ss=9, "Creates a totem that shoots poison at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{555, "totemVitality", "Totem chaos", 0.5, s=4, ss=10, "Creates a totem that shoots chaos balls at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{556, "empowerFire", "Empower fire", 1, s=4, ss=6, "Empower your fire spells", snd=4},
{557, "empowerFrost", "Empower frost", 1, s=4, ss=7, "Empower your frost spells", snd=4},
{558, "empowerShock", "Empower shock", 1, s=4, ss=8, "Empower your shock spells", snd=4},
{559, "empowerPoison", "Empower poison", 1, s=4, ss=9, "Empower your poison spells", snd=4},
{560, "empowerVitality", "Empower chaos", 1, s=4, ss=10, "Empower your chaos damage spells", snd=4},
{561, "reflectFire", "Reflect fire", 1, s=4, ss=6, "Neutralizes the power of enemy fire spells", snd=4},
{562, "reflectFrost", "Reflect frost", 1, s=4, ss=7, "Neutralizes the power of enemy frost spells", snd=4},
{563, "reflectShock", "Reflect shock", 1, s=4, ss=8, "Neutralizes the power of enemy shock spells", snd=4},
{564, "reflectPoison", "Reflect poison", 1, s=4, ss=9, "Neutralizes the power of enemy poison spells", snd=4},
{565, "reflectVitality", "Reflect chaos", 1, s=4, ss=10, "Neutralizes the power of enemy chaos spells", snd=4},
{566, "waveFire", "Wave fire", 6, s=2, ss=6, "Launches a wave of fire, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{567, "waveFrost", "Wave frost", 6, s=2, ss=7, "Launches a wave of frost, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{568, "waveShock", "Wave shock", 6, s=2, ss=8, "Launches a wave of shock, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{569, "wavePoison", "Wave poison", 10, s=2, ss=9, "Launches a wave of poison, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol},
{570, "waveVitality", "Wave chaos", 8, s=2, ss=10, "Launches a wave of chaos, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.5, col = WAVcol}}
for _,e in ipairs(MEN) do tes3.claimSpellEffectId(e[2], e[1])	tes3.addMagicEffect{id = e[1], name = e[3], baseCost = e[4], school = e.s, description = e[5] or e[3],
allowEnchanting = not e.ale, allowSpellmaking = not e.als, canCastSelf = not e.c0, canCastTarget = not e.c1, canCastTouch = not e.c2, isHarmful = not not e.h, hasNoDuration = not not e.nod, hasNoMagnitude = not not e.nom,
nonRecastable = not not e.nor, hasContinuousVFX = not not e.con, appliesOnce = not e.apo, unreflectable = not not e.unr, casterLinked = false, illegalDaedra = false, targetsAttributes = false, targetsSkills = false, usesNegativeLighting = false,
castSound = S[e.snd or e.ss or e.s].sc, boltSound = e.sb or S[e.snd or e.ss or e.s].sb, hitSound = e.sh or S[e.snd or e.ss or e.s].sh, areaSound = S[e.snd or e.ss or e.s].sa,
castVFX = e.vfc or S[e.vfx or e.ss or e.s].vc, boltVFX = e.vfb or S[e.vfx or e.ss or e.s].vb, hitVFX = e.vfh or S[e.vfx or e.ss or e.s].vh, areaVFX = e.vfa or S[e.vfx or e.ss or e.s].va,
particleTexture = e.p or S[e.ss or e.s].p, icon = "s\\"..e[2]..".tga", speed = e.sp or 1, size = 1, sizeCap = 50, lighting = S[e.ss or e.s].l, onCollision = e.col or nil, onTick = e.tik or nil} end

local OBJ = {["potion_skooma_01"] = {[4]=510},	["4nm_star_shadow3a"] = {[7]=600},	["4nm_star_shadow1"] = {[2]=600}, ["4nm_star_shadow2"] = {[2]=600}, ["4nm_star_shadow3"] = {[2]=600},
["thunder fist"] = {[2]=512, [3]=513},		["wizard's brand"] = {[2]=511, [3]=513},
["4a_con1"] = {[1]=601,[7]=603},	["4a_enc"] = {[1]=501},		["4a_alt1"] = {[3]=600},		["4a_mys3"] = {[2]=507},	["4a_sec"] = {[1]=510},		["4a_arm"] = {[1]=502,[2]=503},
["ward of endus"] = {[2]=501},	["ward of odros"] = {[3]=511,[4]=561},		["ward of vemyn"] = {[3]=509},		["ward of gilvoth"] = {[3]=509},	["ward of tureynul"] = {[6]=507,[7]=508},	["ward of uthol"] = {[3]=506},
["ward of araynys"] = {[2]=501},	["ward of dagoth"] = {[3]=510},		["drakespride_en_uniq"] = {[2]=501},
["levitate_peakstar_en"] = {[2]=600}, 			["Wind Whisper"] = {[3]=600}, 			["Caius' Subtlety"] = {[2]=600}, 		["bm_amulspd"] = {[4]=600}, 				["wraithguard_en"] = {[1]=507,[2]=508},
["warlock's sphere"] = {[4]=507,[5]=509}, 		["watchful spirit"] = {[3]=508}, 		["hircine's blessing"] = {[2]=507},			["theranafeather_en_uniq"] = {[2]=508}, 	["Marara's Boon"] = {[2]=507,[3]=508},
["hort_ledd_shield"] = {[2]=507,[3]=508}, 		["will_en"] = {[2]=507},				["armor of god_en"] = {[1]=507,[2]=508}, 	["Spell Breaker"] = {[2]=507},				["dragon aura"] = {[2]=556},
["stroris"] = {[2]=512,[3]=557,[4]=562},		["bitter mercy"] = {[2]=513,[3]=558,[4]=563},
["bound cuirass_effects_en"] = {[1]=508},		["bound boots_effect_en"] = {[2]=600},		["bound shield_effect_en"] = {[1]=507,[2]=508},
["tenpaceboots_en"] = {[5]=600}, 				["we_stormforge_en"] = {[2]=513}, 		["mazedband"] = {[1]=500},
} -- [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=}, [""] = {[]=},
for id, t in pairs(OBJ) do E = tes3.getObject(id).effects	for i, eid in pairs(t) do E[i].id = eid end end

if cf.scroll then for b in tes3.iterateObjects(tes3.objectType.book) do if b.type == 1 and b.enchantment then b.icon = ("scrolls\\tx_scroll_%s.dds"):format(b.enchantment.effects[1].id) end end end
mwse.memory.writeFunctionCall{address = 0x4D0CD5, length = 0x10, signature = {returns = "int"}, call = function() if P then return tes3.player.object.level > 99 and 100 or math.max(tes3.player.object.level * (P.luc11 and 1 or 0.3), 5) end end}
mwse.memory.writeBytes{address = 0x5C3B6C, bytes={0x90, 0x90, 0x90, 0x90, 0xD9, 0x44, 0x24, 0x10}} -- фикс стоимости зачарований
mwse.memory.writeNoOperation{address = 0x515203, length = 0x515215 - 0x515203}	-- убирает звук фейла зачарований
mwse.memory.writeFunctionCall{address = 0x515217, previousCall = 0x4A9F00, signature = {this = "tes3object", returns = "tes3object"}, call = function() end}	-- убирает звук фейла зачарований
mwse.memory.writeBytes{ address = 0x527BC0, bytes = { 0xC2, 0x04, 0x00 } }		-- Блок перерасчета стамины маны и нагрузки

--mwse.memory.writeBytes{address=0x540B96, bytes={0x90, 0xE9}} -- скорость бега существ?

--Величина свинга теперь соответствует анимации
mwse.memory.writeBytes{address = 0x541530, bytes = { 0x8B, 0x15, 0xDC, 0x67, 0x7C, 0x00, 0xD9, 0x42, 0x2C, 0x8B, 0x41, 0x3C, 0xD8, 0x88, 0xDC, 0x04, 0x00, 0x00, 0x8B, 0x51, 0x38, 0x8D, 0x82, 0xCC, 0x00, 0x00, 0x00, 0xD8, 0x40, 0x08, 0xD9, 0x58, 0x08, 0xC7, 0x41, 0x10, 0x00, 0x00, 0x80, 0xBF, 0xC6, 0x40, 0x11, 0x03, 0xD9, 0x41, 0x2C, 0xD8, 0x1D, 0x68, 0x64, 0x74, 0x00, 0xDF, 0xE0, 0xF6, 0xC4, 0x40, 0x75, 0x0B, 0x8B, 0x41, 0x2C, 0x89 } }
mwse.memory.writeBytes{address = 0x5414E0, bytes = { 0x8B, 0x46, 0x3C, 0xD8, 0x88, 0xDC, 0x04, 0x00, 0x00, 0x8B, 0x46, 0x38, 0xD8, 0x80, 0xD4, 0x00, 0x00, 0x00, 0xD9, 0x98, 0xD4, 0x00, 0x00, 0x00, 0xD9, 0x46, 0x20, 0xD8, 0x1D, 0x68, 0x64, 0x74, 0x00, 0xDF, 0xE0, 0xF6, 0xC4, 0x40, 0x75, 0x1F, 0x8B, 0x46, 0x3C, 0xD9, 0x40, 0x5C, 0x8B, 0x0D, 0xDC, 0x67, 0x7C, 0x00, 0xD8, 0x41, 0x2C, 0xD8, 0x5E, 0x20, 0xDF, 0xE0, 0xF6, 0xC4, 0x01, 0x75, 0x06, 0x8B, 0x56, 0x20, 0x89, 0x56, 0x10, 0x5E, 0x5B, 0xC2, 0x04, 0x00 } }
--Нпс теперь могут удерживать свинг		3 неудачные попытки
--mwse.memory.writeBytes{address = 0x541481, bytes = { 0xEB } }
--mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 } }
--mwse.memory.writeBytes{address = 0x541480, bytes = { 0, 0x75 } }
--mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 } }
--mwse.memory.writeBytes{address = 0x54147C, bytes = { 0x88, 0x03, 0, 0, 0, 0x75 } }
--mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 } }
mwse.memory.writeBytes{address = 0x54147A, bytes = { 0x8B, 0x90, 0x88, 0x03, 0, 0, 0x0A, 0x90, 0x28, 0x02, 0, 0, 0x85, 0xD2, 0x75, 0x04, 0x84, 0xDB, 0x75, 0x3D } }
mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 } }


if cf.reb then	local ESP = {["4NM.ESP"] = true, ["Morrowind.esm"] = true}		local t		--local c0 = os.clock()
	for o in tes3.iterateObjects{tes3.objectType.weapon, tes3.objectType.ammunition} do if not ESP[o.sourceMod] then t = L.WE[o.mesh:lower()]	if t then
		o.value = t.v * (o.enchantment and 2 or 1)	o.enchantCapacity = t.e		o.maxCondition = t.d	o.reach = t.r	o.weight = t.w		o.speed = t.s	o.ignoresNormalWeaponResistance = t.ig == 1
		o.chopMax = t.d1	o.slashMax = t.d2	o.thrustMax = t.d3		o.chopMin = t.m1	o.slashMin = t.m2	o.thrustMin = t.m3
		--mwse.log("REPLACE!  %s", o.mesh:lower())
		--else mwse.log("%s", o.mesh:lower())
	end end end
	for o in tes3.iterateObjects(tes3.objectType.armor) do if not ESP[o.sourceMod] then t = L.ARM[o.mesh:lower()]	if t then
		o.value = t.v * (o.enchantment and 2 or 1)	o.enchantCapacity = t.e		o.maxCondition = t.d	o.weight = t.w		o.armorRating = t.ar
		--mwse.log("REPLACE!  %s", o.mesh:lower())
		--else mwse.log("%s", o.mesh:lower())
	end end end
	--tes3.messageBox("time  =   %d", (os.clock() - c0)*1000)
end

end		event.register("initialized", initialized)