local eng = tes3.getLanguage() ~= "rus"
local cf = mwse.loadConfig("4NM", {m = false, m1 = false, m2 = false, m30 = false, m3 = false, m4 = false, m5 = false, m6 = false, m7 = false, m8 = false, m9 = false, m10 = false, m11 = false, m12 = false,
scroll = true, lab = true, spmak = true, lin = 15, UIsp = true, UIen = true, UIcol = 0, fatbar = true, enbar = true, enbarpos = 5, newUI = true, UInum = true, dmgind = true, spdm = true, tut = true, 
whn = 16, whwid = 700, whalf = 0, pscal = 1,
BBen = true, BBred = 5, BBgr = 30, BBhor = true, BBrig = true, nomic = false, vfxnew = true, vfxbl = false,
pmult = 1, pussy = 2, skillim = true, skillp = true, levmod = true, trmod = true, trfat = true, expfat = 3, enchlim = true, splim = true, enlim = true, alc = true, barter = true, stels = true, hit = true,
traum = true, stamhit = true, addpr = true, aspell = true, reb = true, spellmerc = true, lowZ = true, ft100 = true, beastarm = true, dbrep = 5,
fastanim = true, cofat = 0, dash = 100, moment = 100, metlim = 100, col = 100, upgm = false, agr = true, smartcw = true, maniac = true, ragang = -45,
autoshield = true, smartpoi = true, raycon = true,
mbsp3 = {mouseButton = 3}, mbsp2 = 4, mbkik = 3, mbdod = 5, mbret = 5, mbhev = 2, mbmet = 3, mbrosp = 3, mbdet = 5, mbcharg = 2, mbsum = 1, mbshot = 2, mbarc = 1, mbclose = 2, scrol = true,
AIen = true, full = true, randcr = true, atspdm = -0.5, pvpspd = 1, pvpproj = 1, pvpprdod = true, par = true, pvpcont = true, durka = true, npcgrip = true, enacc = true, spellhit = true, AIsec = 2,
hdist = 3000, doorfix = 1, fixd = 150, fixd2 = 100,
dprior = true, autoarb = false, autokik = true, autocharg = false, ray = true,
newsnd = true, volimp = 0.75, volarm = 1, voldmg = 0.75, volsw = 0.75, volit = 1, npcfdist = 2000, volfoot = 1, volfootnpc = 1, volfarm = 1, volfarmnpc = 1, volswim = 0.5, volcont = 1, mcs = true,
kikkey = {keyCode = 28}, pkey = {keyCode = 60}, ekey = {keyCode = 42}, dwmkey = {keyCode = 29}, gripkey = {keyCode = 56}, statkey = {keyCode = 24}, swapkey = true,
conkey = {keyCode = 157}, sp2qkey = {keyCode = 43}, dashkey = {keyCode = 54}, qwhkey = {keyCode = 207}, conwhkey = {keyCode = 211}, telkey = {keyCode = 209}, cpkey = {keyCode = 14}, poisonkey = {keyCode = 25},
killkey = {keyCode = 37}, parkey = {keyCode = 38}, totkey = {keyCode = 44}, bwkey = {keyCode = 45}, reflkey = {keyCode = 46}, detkey = {keyCode = 47}, markkey = {keyCode = 48}, cwkey = {keyCode = 49}})
local function registerModConfig()	local tpl = mwse.mcm.createTemplate("4NM")	tpl:saveOnClose("4NM", cf)		tpl:register()		local var = mwse.mcm.createTableVariable
local p1, p0, pe, p3, p2, pm, ps = tpl:createPage(eng and "Interface" or "Интерфейс"), tpl:createPage(eng and "Modules" or "Модули"), tpl:createPage(eng and "Enemies" or "Враги"),
tpl:createPage(eng and "Mechanics" or "Удобства"), tpl:createPage(eng and "Buttons" or "Кнопки"), tpl:createPage(eng and "Mouse" or "Мышь"), tpl:createPage(eng and "Sounds" or "Звуки")
p0:createSlider{label = eng and "Difficulty level: 1 - Hard; 2 - Medium; 3 - Easy. The difficulty only affects the number of perkpoints per level" or
"Уровень сложности: 1 - Тяжело; 2 - Средне; 3 - Легко. Сложность влияет только на количество перкпоинтов за уровень", min = 1, max = 3, step = 1, jump = 1, variable = var{id = "pmult", table = cf}}
p0:createSlider{label = eng and "Hardcore level: 1 - True (saves only in safe places), 2 - Medium (only out of combat), 3 - Pussy-mode (no restrictions)" or
"Уровень хардкора: 1 - Истинный (сохранения только в безопасных местах); 2 - Средний (только вне боя); 3 - Пусси-мод (без ограничений)", min = 1, max = 3, step = 1, jump = 1, variable = var{id = "pussy", table = cf}}
p0:createYesNoButton{label = eng and "Enable advanced leveling system" or "Продвинутая система левелинга", variable = var{id = "levmod", table = cf}}
p0:createYesNoButton{label = eng and "Enable advanced skill training system" or "Продвинутая система набора опыта в навыках", variable = var{id = "trmod", table = cf}, restartRequired = true}

p0:createSlider{label = eng and "Fatigue multiplier when training skills (3 by default)" or "Множитель усталости при повышении навыков (3 по умолчанию)",
min = 0, max = 10, step = 1, jump = 1, variable = var{id = "expfat", table = cf}}
--p0:createYesNoButton{label = eng and "Enable slowing skill growth rate from fatigue" or "Замедление скорости роста навыков от усталости", variable = var{id = "trfat", table = cf}}
p0:createYesNoButton{label = eng and "Enable limiting skill growth through self-training" or "Ограничение роста навыков через самостоятельные тренировки", variable = var{id = "skillim", table = cf}}
p0:createYesNoButton{label = eng and "Enable limitation of training with trainers" or "Ограничение обучений у тренеров", variable = var{id = "skillp", table = cf}}
--p0:createYesNoButton{label = eng and "Enable realistic run speed" or "Реалистичная скорость бега", variable = var{id = "Spd", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable realistic hit chance" or "Реалистичный шанс на попадание", variable = var{id = "hit", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable realistic injury from physical damage" or "Реалистичная травматичность от физического урона", variable = var{id = "traum", table = cf}}
--p0:createYesNoButton{label = eng and "Enable realistic fatigue from physical damage" or "Реалистичная утомляемость от физического урона", variable = var{id = "stamhit", table = cf}}
p0:createYesNoButton{label = eng and "Enable advanced alchemy" or "Продвинутая алхимия", variable = var{id = "alc", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable advanced economics" or "Продвинутая экономика", variable = var{id = "barter", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable advanced stealth" or "Продвинутый стелс", variable = var{id = "stels", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Enable constant enchantments limit" or "Ограничение объема постоянных зачарований", variable = var{id = "enchlim", table = cf}}
p0:createYesNoButton{label = eng and "Enable limiting the duration and radius of homemade spells" or "Ограничение длительности и радиуса самодельных спеллов", variable = var{id = "splim", table = cf}}
--p0:createYesNoButton{label = eng and "Enable limiting the maximum power of homemade non-constant enchantments" or "Ограничение максимальной силы самодельных непостоянных зачарований", variable = var{id = "enlim", table = cf}}
p0:createYesNoButton{label = eng and "Automatic rebalancing of weapons and armor from other mods" or "Автоматический ребаланс оружия и брони из других модов", variable = var{id = "reb", table = cf}}
p0:createYesNoButton{label = eng and "Arrows get stuck on hit" or "Стрелы будут застревать при попадании", variable = var{id = "addpr", table = cf}}
p0:createYesNoButton{label = eng and "Prohibit selling unbalanced spells" or "Запретить продавать несбалансированные спеллы", variable = var{id = "spellmerc", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Anti-exploit for homemade spells" or "Анти-эксплойт с самодельными спеллами", variable = var{id = "aspell", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Return NPCs who have fallen through the floor" or "Возвращать провалившихся сквозь пол нпс", variable = var{id = "lowZ", table = cf}}
p0:createYesNoButton{label = eng and "Frame time limit 100ms instead of 200ms. This will reduce the number of times actors fall through the floor, but if you have less than 10 fps the world will be slow" or
"Лимит времени кадра 100мс вместо 200мс. Это уменьшит число проваливаний сквозь пол, но если у вас менее 10 фпс, мир будет замедлен", variable = var{id = "ft100", table = cf}, restartRequired = true}
p0:createYesNoButton{label = eng and "Allow beast race player to wear boots and closed helmets" or "Разрешить игроку звероподобной расы надевать сапоги и закрытые шлемы", variable = var{id = "beastarm", table = cf}}
p0:createSlider{label = eng and "Reputation to start Dark Brotherhood attacks" or "Репутация для старта атак Темного Братства", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "dbrep", table = cf}}


pe:createYesNoButton{label = eng and "Enable improved enemy AI" or "Улучшенный ИИ врагов", variable = var{id = "AIen", table = cf}}
pe:createYesNoButton{label = eng and "Enable improved creature abilities" or "Улучшенные способности существ", variable = var{id = "full", table = cf}, restartRequired = true}
pe:createYesNoButton{label = eng and "Randomize creature stats" or "Рандомизировать статы существ", variable = var{id = "randcr", table = cf}}
pe:createDecimalSlider{label = eng and "Minimum delay before attack for NPCs (the lower the value, the more frequent the attacks, -0.5 by default)" 
or "Минимальная задержка перед атакой для нпс (чем ниже, тем чаще атаки, -0.5 по умолчанию)", min = -0.9, max = 0.1, variable = var{id = "atspdm", table = cf}, restartRequired = true}
pe:createDecimalSlider{label = eng and "How fast NPCs will move around a target in melee combat" or "Как быстро нпс будут двигаться вокруг цели в ближнем бою", variable = var{id = "pvpspd", table = cf}}
pe:createDecimalSlider{label = eng and "How fast NPCs will try to dodge your projectiles" or "Как быстро нпс будут пытаться увернуться от ваших снарядов", variable = var{id = "pvpproj", table = cf}}
pe:createYesNoButton{label = eng and "Normal type of projectile dodging instead of jumping" or "Нормальный тип уклонения от снарядов вместо прыжкового", variable = var{id = "pvpprdod", table = cf}}
pe:createYesNoButton{label = eng and "NPCs will do power attacks from a running start" or "Нпс будут проводить силовые атаки с разбега", variable = var{id = "durka", table = cf}}
pe:createYesNoButton{label = eng and "NPCs will try to parry attacks" or "Нпс будут пытаться парировать атаки", variable = var{id = "par", table = cf}}
pe:createYesNoButton{label = eng and "NPCs have a chance to instantly counterattack after parrying" or "Нпс имею шанс мгновенно контратаковать после парирования", variable = var{id = "pvpcont", table = cf}}
pe:createYesNoButton{label = eng and "NPCs without a shield will change the grip of one-handed weapons to two-handed" or "Нпс без щита будут менять хват одноручного оружия на двуручный", variable = var{id = "npcgrip", table = cf}}
pe:createYesNoButton{label = eng and "Improved ranged enemy accuracy against a moving player" or "Улучшенная меткость врагов по движущемуся игроку", variable = var{id = "enacc", table = cf}}
pe:createYesNoButton{label = eng and "Enable improved targeting magic for enemies" or "Улучшенное наведение магии для врагов", variable = var{id = "spellhit", table = cf}}
pe:createSlider{label = eng and "How many seconds do enemies need to start throwing stones" or "Сколько секунд надо затупившим врагам, чтобы начать кидать камни", min = 0, max = 10, step = 1, jump = 1, variable = var{id = "AIsec", table = cf}}

pe:createSlider{label = eng and "Distance from which enemies will hear a call for help (2000 by default)" or "Дистанция с которой враги услышат зов о помощи (3000 по умолчанию)",
min = 0, max = 5000, step = 100, jump = 500, variable = var{id = "hdist", table = cf}}

--pe:createSlider{label = eng and "Fix for stuck NPCs in doors: 0 - disabled, 1 - automatically (default), 2 - only when the door is activated" or
--"Фикс застрявших в дверях нпс: 0 - отключено, 1 - автоматически (по умолчанию), 2 - только когда дверь активируется", min = 0, max = 2, step = 1, jump = 1, variable = var{id = "doorfix", table = cf}}
pe:createSlider{label = eng and "Shift distance for stuck NPCs in closed doors (200 by default, set 0 to disable)" or
"Смещение для застрявших нпс в закрытых дверях (150 по умолчанию, 0 для отключения)", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "fixd", table = cf}}
pe:createSlider{label = eng and "Shift distance for stuck NPCs in open doors (100 by default, set 0 to disable)" or
"Смещение для застрявших нпс в открытых дверях (100 по умолчанию, 0 для отключения)", min = 0, max = 300, step = 10, jump = 50, variable = var{id = "fixd2", table = cf}}



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
p1:createYesNoButton{label = eng and "Show door and pursuit messages" or "Показывать сообщения о дверях и преследователях", variable = var{id = "m12", table = cf}}
p1:createSlider{label = eng and "Set number of icons in 1 line in Improved magic menu" or "Сколько иконок будет в одной строке Улучшенного меню магии", min = 5, max = 50, step = 1, jump = 5, variable = var{id = "lin", table = cf}}
p1:createSlider{label = eng and "Font color in Improved magic menu (0 = no text)" or "Цвет шрифта в улучшенном меню магии (0 = без текста)", min = 0, max = 4, step = 1, jump = 1, variable = var{id = "UIcol", table = cf}}
p1:createYesNoButton{label = eng and "Improved spell menu (requires save load)" or "Улучшенное меню заклинаний", variable = var{id = "UIsp", table = cf}}
p1:createYesNoButton{label = eng and "Improved enchanted items menu (requires save load)" or "Улучшенное меню зачарованных предметов", variable = var{id = "UIen", table = cf}}
p1:createYesNoButton{label = eng and "Improved spell creation menu" or "Улучшеное меню создания заклинаний", variable = var{id = "spmak", table = cf}}
p1:createYesNoButton{label = eng and "Improved enemy bars" or "Улучшенные полоски врагов", variable = var{id = "enbar", table = cf}, restartRequired = true}
p1:createSlider{label = eng and "Enemy bars position" or "Расположение полосок врагов", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "enbarpos", table = cf}}
p1:createYesNoButton{label = eng and "Improved HUD" or "Улучшенный HUD", variable = var{id = "newUI", table = cf}}
p1:createYesNoButton{label = eng and "Show numbers on player bars" or "Показывать цифры на полосках игрока", variable = var{id = "UInum", table = cf}}
p1:createYesNoButton{label = eng and "Show physical damage indicator" or "Показывать индикатор физического урона", variable = var{id = "dmgind", table = cf}}
p1:createYesNoButton{label = eng and "Show speedometer" or "Показывать спидометр", variable = var{id = "spdm", table = cf}}
p1:createYesNoButton{label = eng and "Show a training fatigue bar (green - movement, blue - magic, lilac - craft, yellow - social)" or
"Показывать полоску тренировочной усталости (зеленый - движения, голубой - магия, сиреневый - крафт, желтый - социалка)", variable = var{id = "fatbar", table = cf}}
p1:createYesNoButton{label = eng and "Show tutorial tips on save loading" or "Показывать обучающие подсказки при загрузках", variable = var{id = "tut", table = cf}}
p1:createYesNoButton{label = eng and "Replace potion icons with better ones" or "Заменить иконки зелий на информативные", variable = var{id = "lab", table = cf}, restartRequired = true}
p1:createYesNoButton{label = eng and "Replace scroll icons with beautiful ones" or "Заменить иконки свитков на красивые", variable = var{id = "scroll", table = cf}, restartRequired = true}
p1:createDecimalSlider{label = eng and "Scaling perk icons" or "Скалирование иконок перков", min = 0.5, max = 2, variable = var{id = "pscal", table = cf}}
p1:createCategory(eng and "Quick Wheel settings:" or "Настройки колеса быстрого доступа:")
p1:createSlider{label = eng and "Number of Quick Wheel slots" or "Число слотов в колесе быстрого доступа", min = 1, max = 128, step = 1, jump = 8, variable = var{id = "whn", table = cf}}
p1:createSlider{label = eng and "Quick Wheel size" or "Размер колеса быстрого доступа", min = 300, max = 2000, step = 50, jump = 100, variable = var{id = "whwid", table = cf}}
p1:createDecimalSlider{label = eng and "Quick Wheel transparency" or "Прозрачность колеса быстрого доступа", variable = var{id = "whalf", table = cf}}
p1:createCategory(eng and "Buff bars settings:" or "Настройки полосок баффов:")
p1:createYesNoButton{label = eng and "Enable buff bars" or "Включить полоски баффов", variable = var{id = "BBen", table = cf}}
p1:createYesNoButton{label = eng and "Horizontal arrangement" or "Горизонтальное расположение", variable = var{id = "BBhor", table = cf}}
p1:createYesNoButton{label = eng and "Right corner location" or "Расположение в правом угле", variable = var{id = "BBrig", table = cf}}
p1:createSlider{label = eng and "Buff time corresponding to red" or "Время баффа соответствующее красному цвету", min = 1, max = 30, step = 1, jump = 5, variable = var{id = "BBred", table = cf}}
p1:createSlider{label = eng and "Buff time corresponding to green" or "Время баффа соответствующее зеленому цвету", min = 10, max = 300, step = 1, jump = 5, variable = var{id = "BBgr", table = cf}}
p1:createYesNoButton{label = eng and "Hide small magic effect icons" or "Скрыть маленькие иконки магических эффектов", variable = var{id = "nomic", table = cf}}

p3:createYesNoButton{variable = var{id = "fastanim", table = cf}, label = eng and
[[Use sharp animations for combo attacks instead of smooth ones if possible. Sharp animations look better in 1st person, smooth ones look better in 3rd person]] or
[[Использовать резкие анимации для комбо-атак вместо плавных если это возможно. Резкие анимации лучше выглядят от 1 лица, плавные лучше от 3 лица]]}
p3:createDecimalSlider{label = eng and "Stamina limiter for your combo attacks" or "Ограничитель стамины для ваших комбо-атак", variable = var{id = "cofat", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your dashes. Use a dash with kick mouse button pressed to remove this limitation" or
"Ограничитель магнитуды для ваших дэшей. Используйте дэш с зажатой кнопкой мыши для пинка чтобы снять это ограничение", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "dash", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your kinetic kicks" or "Ограничитель магнитуды для ваших кинетических пинков", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "moment", table = cf}}
p3:createSlider{label = eng and "Magnitude limiter for your kinetic throws" or "Ограничитель магнитуды для ваших кинетических бросков", min = 0, max = 100, step = 1, jump = 5, variable = var{id = "metlim", table = cf}}
p3:createYesNoButton{label = eng and "Priority of dash over dodge. Hold down the special mouse button to change the priority" or
"Приоритет дэша над доджем. Зажмите специальную кнопку мыши для смены проиритета", variable = var{id = "dprior", table = cf}}
p3:createYesNoButton{label = eng and "Automatically kick after dash (if dash is done with kick mouse button pressed)" or "Автоматически делать пинок после дэша (если дэш сделан с зажатой кнопкой мыши для пинка)", variable = var{id = "autokik", table = cf}}
p3:createYesNoButton{label = eng and "Automatically do dash strike if you are looking at an enemy" or "Автоматически делать дэш-страйк если вы смотрите на врага", variable = var{id = "autocharg", table = cf}}
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
p3:createYesNoButton{label = eng and "Module for adjusting the size of magic vfx" or "Модуль корректировки размеров магических vfx", variable = var{id = "vfxnew", table = cf}, restartRequired = true}
p3:createYesNoButton{label = eng and "Remove vfx casting Destruction spells for the player" or "Удалить vfx каста заклинаний Разрушения для игрока", variable = var{id = "vfxbl", table = cf}}
p3:createSlider{label = eng and "Slash strikes impulse angle (minus = left, plus = right, 0 = straight)" or
"Угол импульса режущих ударов (минус = влево, плюс = вправо, 0 = прямо)", min = -60, max = 60, step = 5, jump = 15, variable = var{id = "ragang", table = cf}, restartRequired = true}

p2:createKeyBinder{variable = var{id = "pkey", table = cf}, label = eng and "Perks Menu" or "Вызвать меню перков"}
p2:createKeyBinder{variable = var{id = "dashkey", table = cf}, label = eng and "Dash / active dodge key" or "Кнопка для дэшей и активных уклонений"}
p2:createKeyBinder{variable = var{id = "kikkey", table = cf}, label = eng and "Kicking and climbing key. It is recommended to assign the same button as for the jump" or
"Кнопка для удара ногой и карабканья. Рекомендуется назначить ту же кнопку что и для прыжка"}
p2:createKeyBinder{variable = var{id = "conkey", table = cf}, label = eng and "Button for concentration or quick cast of the main spell" or "Кнопка для концентрации или быстрого каста основного спелла"}
p2:createKeyBinder{variable = var{id = "sp2qkey", table = cf}, label = eng and "Button for quick casting a secondary spell" or "Кнопка для быстрого каста вторичного спелла"}
p2:createKeyBinder{variable = var{id = "qwhkey", table = cf}, label = eng and
[[Button for the quick access wheel. To select a secondary spell, hold down the mouse button to cast the secondary spell while selecting. To overwrite a slot, hold ALT while selecting.
Press this button with SHIFT to select the current spell for the secondary slot. Press this button with CTRL to add/remove the current spell to the list of Favorite Spells. Press this button with ALT to clear this list]] or
[[Кнопка для колеса быстрого доступа. Чтобы выбрать вторичный спелл, зажмите кнопку мыши для каста вторичного спелла во время выбора. Чтобы перезаписать слот, зажмите ALT во время выбора.
Нажмите эту кнопку с SHIFT чтобы выбрать текущий спелл для вторичного слота. Нажмите эту кнопку с CTRL чтобы добавить/удалить текущий спелл в список Избранных Спеллов. Нажмите эту кнопку с ALT чтобы очистить этот список]]}
p2:createKeyBinder{variable = var{id = "conwhkey", table = cf}, label = eng and "Button for the quick access wheel to Concentration slots" or "Кнопка для колеса быстрого доступа к слотам канцентрации"}
p2:createKeyBinder{variable = var{id = "ekey", table = cf}, label = eng and
[[Hold this key when: Equipping weapon - to remember it for left hand; Equipping poison - to use it for throwing; Activating the apparatus - to display the alchemy menu without adding it to your inventory]] or
[[Удерживайте эту кнопку: При экипировке оружия - чтобы запомнить его для левой руки; При экипировке яда - чтобы кидать бутылки; При активации аппарата - чтобы алхимическое меню появилось без взятия этого апаарата]]}
p2:createKeyBinder{variable = var{id = "dwmkey", table = cf}, label = eng and "Switch to dual-weapon mode. Press this button while holding ALT to forget the left weapon" or
"Переключение режима двух оружий. Нажмите эту кнопку, удерживая ALT, чтобы забыть оружие для левой руки"}
p2:createKeyBinder{variable = var{id = "gripkey", table = cf}, label = eng and "Press this key when equip weapon to change it grip" or "Нажмите эту кнопку при экипировке оружия чтобы сменить его хват"}
p2:createKeyBinder{variable = var{id = "cpkey", table = cf}, label = eng and "Projectile control mode key" or "Кнопка для контроля снарядов"}
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
p2:createKeyBinder{variable = var{id = "killkey", table = cf}, label = eng and "Orders summoned to attack the selected target. If no target is selected, attack all enemies." or
"Приказ призванным атаковать выбранную цель. Если цель не выбрана - атаковать всех врагов"}
p2:createKeyBinder{variable = var{id = "statkey", table = cf}, label = eng and "View stats of selected NPC" or "Кнопка для просмотра статов выбранного нпс"}
p2:createYesNoButton{label = eng and "Use the activation button to change Weapon/Cast modes" or "Использовать кнопку активации для смены режимов Оружие/Каст", variable = var{id = "swapkey", table = cf}}



pm:createCategory(eng and [[Mouse buttons: 1 - left, 2 - right, 3 - middle, 4-7 - side
It is highly recommended to assign a normal magic cast to the right mouse button]] or
[[Кнопки мыши: 1 - левая, 2 - правая, 3 - средняя, 4-7 - боковые
Крайне рекомендуется назначить обычный каст магии на правую кнопку мыши]])

--pm:createMouseBinder{variable = var{id = "mbsp3", table = cf}, label = eng and "Key for select mark for recall" or "Кнопка для выбора текущей Пометки для магии Возврата"}

pm:createSlider{label = eng and "Mouse button for cast a secondary spell" or "Кнопка мыши для каста вторичного заклинания", min = 3, max = 7, step = 1, jump = 1, variable = var{id = "mbsp2", table = cf}}
pm:createSlider{label = eng and "Mouse button to change the priority of dash over dodge (hold while dash/dodge)" or 
"Кнопка мыши для смены приоритета дэша над доджем (удерживайте во время дэша/доджа)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbdod", table = cf}}
pm:createSlider{label = eng and "Mouse button for kicking and climbing" or "Кнопка мыши для удара ногой и карабканья", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbkik", table = cf}}
pm:createSlider{label = eng and "Mouse button for dash strike (hold while attack)" or "Кнопка мыши для дэш-страйка (зажмите при атаке)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbcharg", table = cf}}
pm:createSlider{label = eng and "Mouse button for throwing weapons (hold while attacking)" or "Кнопка мыши для кидания оружия (зажмите при атаке)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbmet", table = cf}}
pm:createSlider{label = eng and "Mouse button for alternative shots (press while holding LMB for bows and throwing weapons; hold and press LMB for crossbows)" or
"Кнопка мыши для альтернативных выстрелов (нажмите при зажатой ЛКМ для луков и метательного оружия; удерживайте и нажимайте ЛКМ для арбалетов)", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbshot", table = cf}}
pm:createSlider{label = eng and "Mouse button to hold breath when archery (select 1 for automatic hold)" or
"Кнопка мыши для задержки дыхания при стрельбе из лука (выберите 1 для автоматической задержки)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbarc", table = cf}}

pm:createSlider{label = eng and "Mouse button for weighting magic projectiles (hold while casting)" or "Кнопка мыши для утяжеления магических снарядов (зажмите при касте)",
min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbhev", table = cf}}
--pm:createSlider{label = eng and "Mouse button for alternate ray mode (hold while casting)" or "Кнопка мыши для альтернативного режима луча (зажмите при касте)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbray", table = cf}}
pm:createSlider{label = eng and "Mouse button to extend the life of summoned creatures (hold while charging magic and looking at the creature)" or
"Кнопка мыши для продления жизни призванных существ (удерживайте, заряжая магию и смотря на существо)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbsum", table = cf}}
pm:createSlider{label = eng and "Mouse button to return controlled projectiles and teleport magic mines. Also alternates ray mode (hold while casting)" or
"Кнопка мыши для возврата контролируемых снарядов и телепортации магических мин. Также меняет режим луча (зажмите при касте)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbret", table = cf}}
pm:createSlider{label = eng and "Mouse button to release projectiles (click with the projectile control key)" or
"Кнопка мыши для роспуска снарядов (нажмите вместе с кнопкой контроля снарядов)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbrosp", table = cf}}
pm:createSlider{label = eng and "Mouse button to detonate projectiles (click with the projectile control key)" or
"Кнопка мыши для подрыва снарядов (нажмите вместе с кнопкой контроля снарядов)", min = 1, max = 7, step = 1, jump = 1, variable = var{id = "mbdet", table = cf}}
--pm:createYesNoButton{label = eng and "Use mouse wheel to scroll Favorite Spells list" or "Использовать колесо мыши для прокрутки списка Избранных Спеллов", variable = var{id = "scrol", table = cf}, restartRequired = true}
pm:createSlider{label = eng and "Mouse button to quickly exit the menu" or "Кнопка мыши для быстрого выхода из меню", min = 2, max = 7, step = 1, jump = 1, variable = var{id = "mbclose", table = cf}}

ps:createYesNoButton{label = eng and "Improved sounds" or "Улучшенные звуки", variable = var{id = "newsnd", table = cf}, restartRequired = true}
ps:createDecimalSlider{label = eng and "Weapon impact sound volume" or "Громкость звуков соударений оружия", variable = var{id = "volimp", table = cf}}
ps:createDecimalSlider{label = eng and "The volume of weapon impacts on armor" or "Громкость ударов оружия по броне", variable = var{id = "volarm", table = cf}}
ps:createDecimalSlider{label = eng and "Damage sound volume" or "Громкость звуков урона", variable = var{id = "voldmg", table = cf}}
ps:createDecimalSlider{label = eng and "Weapon swing sound volume" or "Громкость звуков взмахов оружия", variable = var{id = "volsw", table = cf}}
ps:createDecimalSlider{label = eng and "Item sound volume" or "Громкость звуков предметов", variable = var{id = "volit", table = cf}}
ps:createDecimalSlider{label = eng and "Player footstep volume" or "Громкость звуков шагов игрока", variable = var{id = "volfoot", table = cf}}
ps:createDecimalSlider{label = eng and "NPC footstep volume" or "Громкость звуков шагов нпс", variable = var{id = "volfootnpc", table = cf}}
ps:createDecimalSlider{label = eng and "Player armor clanking volume" or "Громкость лязга брони игрока", variable = var{id = "volfarm", table = cf}}
ps:createDecimalSlider{label = eng and "NPC armor clanking volume" or "Громкость лязга брони нпс", variable = var{id = "volfarmnpc", table = cf}}
ps:createDecimalSlider{label = eng and "Swim sound volume" or "Громкость звуков плавания", variable = var{id = "volswim", table = cf}}

ps:createSlider{label = eng and "Replacement distance for NPC footstep sounds" or "Дистанция замены звуков шагов нпс", min = 0, max = 3000, step = 100, jump = 500, variable = var{id = "npcfdist", table = cf}}
ps:createDecimalSlider{label = eng and "Volume of sounds of looting bodies" or "Громкость звуков лутания тел", variable = var{id = "volcont", table = cf}}

ps:createYesNoButton{label = eng and "Play sound of magic concentration (hold Left Mouse Button for concentrate power)" or
"Звук магической концентрации (удерживайте левую кнопку мыши чтобы сконцентрировать магию и зарядить спелл)", variable = var{id = "mcs", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local p, mp, inv, p1, p3, ad, pp, D, DM, MB, AC, mc, n, md, pow, wc, prm, ic, crot, MEF, PMP, PST, arm, arp
--local MT = {__index = function(t, k) t[k] = {} return t[k] end}		--setmetatable({}, MT)		--local SS = setmetatable({}, MT)		local BSS = setmetatable({}, MT)		local SSN = {}
local P = {}	local M = {}	local B = {}	local S = {}	local SN = {}	local SNC = {}	local COL = {}	local MPR = {}	local Matr = tes3matrix33.new()		local W = {}	local N = {}	local MP = {}	local DOM = {}
local V = {METR = {}, up100 = tes3vector3.new(0,0,100), up = tes3vector3.new(0,0,1), up2 = tes3vector3.new(0,0,0.5), up3 = tes3vector3.new(0,0,0.2666), up64 = tes3vector3.new(0,0,64), up20 = tes3vector3.new(0,0,20),
down = tes3vector3.new(0,0,-1), down10 = tes3vector3.new(0,0,-10), nul = tes3vector3.new(0,0,0)}
local PRR = {}		local R = {}	local AF = {}		local H = {}
local G = {cpg = 0, rng = 0.5, DashD = 0, STN = 1, ENC = 0, LIG = 0, DopW = {}, LigTab = {}, DmgR = {}, TimRef = {}, SkBurn = {}, SkLim = {}, DTS = {},
pi2 = math.pi*2, LPP = V.nul, PspdNfr = 0, swingmult = 1, atspd = 1}
local ID33 = tes3matrix33.new(1,0,0,0,1,0,0,0,1)
local CPR = {}		local CPRS = {}		local CPS = {0,0,0,0,0,0,0,0,0,0}
local WT = {[-1]={s=26,p1="hand1",p2="hand2",p3="hand3",p4="hand4",p5="hand5",p6="hand6",p8="hand8",pc="hand12",iso=0,sws="SwingFist"},
[0]={s=22,p1="short1",p2="short2",p3="short3",p4="short4",p5="short5",p6="short6",p7="short7",p8="short8",p9="short9",p="short0",pc="short13",h1=true,dw=true,spb=true,pso=1,iso=1,sws="SwingShort",isnd="Short"},
[1]={s=5,p1="long1a",p2="long2a",p3="long3a",p4="long4a",p5="long5a",p6="long6a",p7="long7a",p8="long8a",p9="long9a",p="long0",pc="long9",h1=true,dw=true,pso=2,iso=2,sws="SwingLong1",isnd="Long"},
[2]={s=5,p1="long1b",p2="long2b",p3="long3b",p4="long4b",p5="long5b",p6="long6b",p7="long7b",p8="long8b",p9="long9b",p="long0",spb=true,pso=2,iso=2,sws="SwingLong2",isnd="Long"},
[3]={s=4,p1="blu1a",p2="blu2a",p3="blu3a",p4="blu4a",p5="blu5a",p6="blu6a",p7="blu7a",p8="blu8a",p9="blu9a",p="blu0a",h1=true,dw=true,pso=4,iso=4,sws="SwingBlunt1",isnd="Blunt",impm=2},
[4]={s=4,p1="blu1b",p2="blu2b",p3="blu3b",p4="blu4b",p5="blu5b",p6="blu6b",p7="blu7b",p8="blu8b",p9="blu9b",p="blu0a",spb=true,pso=4,iso=4,sws="SwingBlunt2",isnd="Blunt",impm=2},
[5]= {s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",spb=true,pc="blu10",pso=4,iso=4,sws="SwingSpear",isnd="Blunt",impm=2},
[-3]={s=4,p1="blu1c",p2="blu2c",p3="blu3c",p4="blu4c",p5="blu5c",p6="blu6c",p7="blu7c",p8="blu8c",p9="blu9c",p="blu0c",pc="blu10",h1=true,dw=true,pso=4,iso=4,sws="SwingSpear",isnd="Blunt",impm=2},
[6]={s=7,p1="spear1",p2="spear2",p3="spear3",p4="spear4",p5="spear5",p6="spear6",p7="spear7",p8="spear8",p9="spear9",p="spear0",spb=true,pso=3,iso=2,sws="SwingSpear",isnd="Spear",impm=1},
[-2]={s=7,p1="spear1a",p2="spear2a",p3="spear3a",p4="spear4a",p5="spear5a",p6="spear6a",p7="spear7a",p8="spear8a",p9="spear9a",p="spear0",h1=true,dw=true,pso=3,iso=2,sws="SwingSpear",isnd="Spear",impm=1},
[7]={s=6,p1="axe1a",p2="axe2a",p3="axe3a",p4="axe4a",p5="axe5a",p6="axe6a",p7="axe7a",p8="axe8a",p9="axe9a",p="axe0",h1=true,dw=true,pso=3,iso=3,sws="SwingAxe1",isnd="Axe",impm=1},
[8]={s=6,p1="axe1b",p2="axe2b",p3="axe3b",p4="axe4b",p5="axe5b",p6="axe6b",p7="axe7b",p8="axe8b",p9="axe9b",p="axe0",spb=true,pso=3,iso=3,sws="SwingAxe2",isnd="Axe",impm=1},
[9]={s=23,p1="mark1a",p2="mark2a",p3="mark3a",p4="mark4a",p5="mark5a",p6="mark6a",p="mark0a",iso=5,isnd="Bow"},
[10]={s=23,p1="mark1b",p2="mark2b",p3="mark3b",p4="mark4b",p5="mark5b",p6="mark6b",p="mark0b",iso=5,isnd="Cross"},
[11]={s=23,p1="mark1c",p2="mark2c",p3="mark3c",p4="mark4c",p5="mark5c",p6="mark6c",p="mark0c",h1=true,iso=5,sws="SwingThrow",isnd="Throw"},
[12]={isnd="Ammo"},
[13]={isnd="Ammo"}}

local T = {T1 = timer, AUR = timer, DC = timer, Ray = timer, TS = timer, DET = timer, PCT = timer, MCT = timer, LEG = timer, SPR = timer,
LI = timer, Dash = timer, Dod = timer, Kik = timer, CT = timer, CST = timer, Shield = timer, Comb = timer, DWB = timer, POT = timer, Run = timer, AoE = timer, Tot = timer, WaterB = timer, Arb = timer, Met = timer, Dom = timer,
Tut = timer, EDMG = timer, EnCD = timer, CON = timer, Mania = timer, HUNT = timer, Dtim = timer}
local L = {PR = require("4NM.perks"), WE = require("4NM.weapon"), ARM = require("4NM.armor"), TUT = require("4NM.turor"), TD = require("4NM.tex"), ITNIF = require("4NM.itemnifs"), CRNIF = require("4NM.creanifs"),
NOSP = require("4NM.spells"),
ATR = {[0] = "strength", [1] = "intelligence", [2] = "willpower", [3] = "agility", [4] = "speed", [5] = "endurance", [6] = "personality", [7] = "luck"},
ATRIC = {[0] = "icons\\k\\attribute_strength.dds", [1] = "icons\\k\\attribute_int.dds", [2] = "icons\\k\\attribute_wilpower.dds", [3] = "icons\\k\\attribute_agility.dds", [4] = "icons\\k\\attribute_speed.dds",
[5] = "icons\\k\\attribute_endurance.dds", [6] = "icons\\k\\attribute_personality.dds", [7] = "icons\\k\\attribute_luck.dds"},
S = {"armorer", "mediumArmor", "heavyArmor", "bluntWeapon", "longBlade", "axe", "spear", "athletics", "enchant", "destruction", "alteration", "illusion", "conjuration", "mysticism", "restoration",
"alchemy", "unarmored", "security", "sneak", "acrobatics", "lightArmor", "shortBlade", "marksman", "mercantile", "speechcraft", "handToHand", [0] = "block"},
SK = {[4] = "skw", [5] = "skw", [6] = "skw", [7] = "skw", [22] = "skw", [23] = "skw", [26] = "skw", [0] = "skarm", [2] = "skarm", [3] = "skarm", [17] = "skarm", [21] = "skarm", [18] = "sksec", [20] = "skacr", [1] = "sksmit",
[9] = "skmag", [10] = "skmag", [11] = "skmag", [12] = "skmag", [13] = "skmag", [14] = "skmag", [15] = "skmag"},
skmag = 1, skw = 1, skarm = 1, sksec = 1, skacr = 1, sksmit = 1,
BS = {["Wombburned"] = "atronach", ["Fay"] = "mage", ["Beggar's Nose"] = "tower", ["Blessed Touch Sign"] = "ritual", ["Charioteer"] = "steed", ["Elfborn"] = "apprentice", ["Hara"] = "thief",
["Lady's Favor"] = "lady", ["Mooncalf"] = "lover", ["Moonshadow Sign"] = "shadow", ["Star-Cursed"] = "serpent", ["Trollkin"] = "lord", ["Warwyrd"] = "warrior"},
BSAct = {["serpent"] = true, ["ritual"] = true, ["tower"] = true, ["shadow"] = true},
SA = {0,5,5,0,0,0,3,5,2,2,1,1,2,1,2,1,4,3,3,3,4,4,3,6,6,4,[0]=3}, SA2 = {3,3,0,5,3,5,0,4,1,1,2,2,1,2,1,3,2,1,4,4,3,3,0,1,1,0,[0]=5}, SS = {0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,[0]=0},
RHP = {Orc = 30, Nord = 20, Argonian = 20, Imperial = 10, Redguard = 10},
RST = {Orc = 50, Nord = 50, Argonian = 50, Imperial = 100, Redguard = 100, ["Wood Elf"] = 50},		-- ["High Elf"] = 50, ["Breton"] = 50,
RENC = {Orc = 100, Nord = 50, Imperial = 50},

RCend = {["Argonian"] = 0.4, ["Imperial"] = 0.4, ["Redguard"] = 0.4, ["Nord"] = 0.4, ["Orc"] = 0.4},
RCstr = {["Redguard"] = 0.4, ["Nord"] = 0.4, ["Orc"] = 0.4},
RCint = {["High Elf"] = 0.4, ["Breton"] = 0.4, ["Imperial"] = 0.4},
RCwil = {["Dark Elf"] = 0.4, ["High Elf"] = 0.4, ["Breton"] = 0.4},
RCspd = {["Dark Elf"] = 0.4, ["Wood Elf"] = 0.4, ["Khajiit"] = 0.4},
RCagi = {["Wood Elf"] = 0.4, ["Khajiit"] = 0.4, ["Argonian"] = 0.4},

RChp = {["Wood Elf"] = 40, ["Argonian"] = 40, ["Imperial"] = 40, ["Redguard"] = 40, ["Nord"] = 40, ["Orc"] = 40},
RCmp = {["Dark Elf"] = 40, ["High Elf"] = 40, ["Breton"] = 40},
RCat = {["Dark Elf"] = 0.4, ["Wood Elf"] = 0.4, ["Khajiit"] = 0.4, ["Redguard"] = 0.4, ["Nord"] = 0.4, ["Orc"] = 0.4},
RCdod = {["Dark Elf"] = 0.4, ["Wood Elf"] = 0.4, ["Redguard"] = 0.4, ["Khajiit"] = 0.3},
RClig = {["Dark Elf"] = 0.1, ["Imperial"] = 0.1, ["Redguard"] = 0.1, ["Nord"] = 0.1, ["Orc"] = 0.1},
RCjump = {["Wood Elf"] = 1, ["Khajiit"] = 1},

SCmp = {["Blessed Touch Sign"] = 10, ["Fay"] = 10, ["Elfborn"] = 10, ["Wombburned"] = -10},
SChp = {["Blessed Touch Sign"] = 10, ["Lady's Favor"] = 10, ["Trollkin"] = 10},
SCat = {["Mooncalf"] = 0.1, ["Warwyrd"] = 0.1},
SCdod = {["Mooncalf"] = 0.1, ["Hara"] = 0.1},
SClig = {["Mooncalf"] = 0.025, ["Charioteer"] = 0.025},
SCjump = {["Mooncalf"] = 0.25, ["Moonshadow Sign"] = 0.25},
SCcharg = {["Wombburned"] = 10},

PERST = {[80] = {"end13", "str10", "wil12", "luc15", "atl9"},
[84] = {"res04", "des04", "alt04", "ill04", "con04", "mys04", "enc01", "una02", "int01", "wil01"},
[82] = {"str03", "end04", "long03", "axe03", "blu03", "spear03", "hand04", "med03", "hev03", "atl03"},
[8] = {"med01", "hev01", "atl01", "str01", "end01"}},

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
["w\\rawglass_arrow.dds"] = "rawglass arrow",
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



NSU = {
["4s_elemental_charge"] = {en = "Elemental charge", ru = "Стихийный заряд", c = 50, d = 30, m = 8, ma = 12, {511}, {512}, {513}},
["4s_elemental_explode"] = {en = "Elemental empower", ru = "Стихийное усиление", c = 50, d = 30, m = 8, ma = 12, {531}, {532}, {533}},
["4s_elemental_burst"] = {en = "Elemental burst", ru = "Стихийная шквал", c = 50, rt = 1, d = 0, m = 15, ma = 20, r = 5, {536}, {537}, {538}},
["4s_elemental_ray"] = {en = "Elemental ray", ru = "Стихийный луч", c = 30, rt = 1, d = 0, m = 5, ma = 5, r = 1, {546}, {547}, {548}},
["4s_elemental_wave"] = {en = "Elemental wave", ru = "Стихийная волна", c = 50, rt = 2, d = 0, m = 10, ma = 15, r = 20, {566}, {567}, {568}},
["4s_elemental_nova"] = {en = "Elemental nova", ru = "Стихийная нова", c = 100, rt = 1, d = 0, m = 50, ma = 100, r = 20, {541}, {542}, {543}}},
ElemSpLVL = {["4s_elemental_ball_1"] = 0, ["4s_elemental_ball_2"] = 10, ["4s_elemental_ball_3"] = 20, ["4s_elemental_charge"] = 10, ["4s_elemental_explode"] = 10,
["4s_elemental_burst"] = 20, ["4s_elemental_ray"] = 20, ["4s_elemental_wave"] = 30, ["4s_elemental_nova"] = 30},
PA = {
--atb1={117,5,"long01","Мастер меча","Sword master"}, atb2={117,5,"axe01","Мастер топора","Ax master"}, atb3={117,5,"blu01","Мастер булавы","Mace master"}, atb4={117,5,"spear01","Мастер копья","Spear master"},
--atb5={117,5,"short01","Мастер ножа","Knife master"}, atb6={117,5,"mark01","Мастер стрельбы","Shooting master"}, atb7={117,5,"hand01","Мастер кулака","Fist master"}, atb8={117,5,"spd01","Быстрая атака","Fast attack"},
--atb9={117,5,"agi01","Ловкая атака","Dexterous attack"}, atb10={117,5,"luc01","Удачная атака","Lucky attack"},
--san1 = {42,5,"una01","Мастер без брони","Master without armor"}, san2 = {42,5,"lig01","Легкое уклонение","Easy evasion"}, san3 = {42,5,"bloc01","Парирование","Parry"}, san4 = {42,5,"short02","Воровской уворот","Thief evasion"}, 
--san5 = {42,5,"hand02","Отклонение атак","Deflecting attacks"}, san6 = {42,5,"acr01","Боевая акробатика","Combat acrobatics"}, san7 = {42,5,"sec01","Чувство опасности","Sense of danger"},
--san8 = {42,5,"spd02","Быстрое уклонение","Fast evasion"}, san9 = {42,5,"agi02","Ловкое уклонение","Dexterous evasion"}, san10 = {42,5,"luc02","Удачное уклонение","Lucky evasion"},

stam1 = {77,2,"med02","Перк: средние доспехи","Perk: medium armor"}, stam2 = {77,2,"hev02","Перк: тяжелые доспехи","Perk: heavy armor"}, stam3 = {77,2,"atl02","Перк: атлетика","Perk: athletics"},
stam4 = {77,2,"str02","Перк: сила","Perk: strength"}, stam5 = {77,2,"end02","Перк: выносливость","Perk: endurance"}, stam6 = {77,2,"axe02","Перк: секиры","Perk: axe"},
stam7 = {77,2,"blu02","Перк: дробящее оружие","Perk: blunt weapon"}, stam8 = {77,2,"spear02","Перк: древковое оружие","Perk: spear"},
stam9 = {77,2,"hand03","Перк: боевые искусства","Perk: hand to hand"}, stam10 = {77,2,"long02","Перк: длинные клинки","Perk: long blade"},

mpr1 = {76,0,"mys05","Перк: мистицизм","Perk: mysticism",m=1}, mpr2 = {76,0,"enc02","Перк: зачарование","Perk: enchant",m=1},
mpr3 = {76,0,"int02","Перк: интеллект","Perk: intelligence",m=1}, mpr4 = {76,0,"wil02","Перк: сила воли","Perk: willpower",m=1},
hpr1 = {75,0,"res05","Перк: восстановление","Perk: restoration",m=1}, hpr2 = {75,0,"end03","Перк: выносливость","Perk: endurance",m=1},
abs1 = {67,5,"alt05","Перк: изменение","Perk: alteration"}, abs2 = {67,5,"mys06","Перк: мистицизм","Perk: mysticism"}, ref1 = {68,5,"mys07","Перк: мистицизм","Perk: mysticism"},
dete = {65,100,"enc03","Перк: зачарование","Perk: enchant"}, deta = {64,100,"sec03","Перк: восприятие","Perk: security"}, detk = {66,100,"sec02","Перк: восприятие","Perk: security"},
nig = {43,20,"mark02","Перк: меткость","Perk: marksman"}},
AA = {["4a_spec"] = "spec00", ["4a_merc"] = "merc00", ["4a_per"] = "per00",
["4a_des1"] = "des01", ["4a_des2"] = "des02", ["4a_des3"] = "des03", ["4a_alt1"] = "alt01", ["4a_alt2"] = "alt02", ["4a_alt3"] = "alt03",
["4a_res1"] = "res01", ["4a_res2"] = "res02", ["4a_res3"] = "res03", ["4a_mys1"] = "mys01", ["4a_mys2"] = "mys02", ["4a_mys3"] = "mys03",
["4a_ill1"] = "ill01", ["4a_ill2"] = "ill02", ["4a_ill3"] = "ill03", ["4a_con1"] = "con01", ["4a_con2"] = "con02", ["4a_con3"] = "con03"},
--STAR = {["4as_atr4"]=true,["4nm_star_apprentice1a"]=true,["4nm_star_lady1a"]=true, ["4nm_star_lord1a"]=true, ["4nm_star_lover1a"]=true, ["4nm_star_mage1a"]=true, ["4nm_star_steed1a"]=true, ["4nm_star_thief1a"]=true,
--["4nm_star_warrior1a"]=true, ["4nm_star_ritual1a"]=true, ["4nm_star_ritual2a"]=true, ["4nm_star_ritual3a"]=true, ["4nm_star_serpent3a"]=true, ["4nm_star_shadow1a"]=true, ["4nm_star_shadow2a"]=true, ["4nm_star_shadow3a"]=true},
NEWSP = {{600,0,600,10,20,0,10,10,"Dash"},	{500,2,500,0,0,0,0,10,"Teleport"},
{501,0,501,5,10,0,5,30,"Recharge"},			{502,0,502,10,20,0,5,30,"Repair weapon"},	{503,0,503,20,30,0,5,30,"Repair armor"},		{504,2,504,8,12,0,60,5,"Lantern"},			{"504a",0,504,8,12,0,60,5,"Lantern (smart)"},
{505,0,505,0,0,0,0,150,"Town teleport"},	{506,0,506,0,0,0,60,5,"Magic control"},		{507,0,507,10,15,0,30,30,"Reflect magic"},		{508,0,508,10,15,0,30,30,"Kinetic shield"},	{509,0,509,20,30,0,30,30,"Life leech"},
{510,0,510,20,30,0,30,30,"Time slow"},		{601,0,601,0,0,0,60,5,"Bound ammo"},		{603,0,603,0,0,0,60,50,"Bound weapon"},			{611,2,611,30,50,1,0,10,"Kinetic arrow"},
{511,0,511,10,15,0,30,30,"Charge fire"},	{512,0,512,10,15,0,30,30,"Charge frost"},	{513,0,513,10,15,0,30,30,"Charge lightning"},	{514,0,514,10,15,0,30,30,"Charge poison"},
{515,0,515,10,15,0,30,30,"Charge chaos"},	{614,0,614,10,15,0,30,30,"Charge force"},
{516,0,516,5,5,0,25,60,"Aura fire"},		{517,0,517,5,5,0,25,60,"Aura frost"},		{518,0,518,5,5,0,25,60,"Aura lightning"},		{519,0,519,5,5,0,25,100,"Aura poison"},		{520,0,520,5,5,0,25,80,"Aura chaos"},
{521,2,521,10,10,20,10,60,"Zone fire"},		{522,2,522,10,10,20,10,60,"Zone frost"},	{523,2,523,10,10,20,10,60,"Zone lightning"},	{524,2,524,10,10,20,10,100,"Zone poison"},	{525,2,525,10,10,20,10,80,"Zone chaos"},
{526,2,526,50,100,15,0,30,"Rune fire"},		{527,2,527,50,100,15,0,30,"Rune frost"},	{528,2,528,50,100,15,0,30,"Rune lightning"},	{529,2,529,50,100,15,0,50,"Rune poison"},
{530,2,530,50,100,15,0,40,"Rune chaos"},	{618,2,618,50,100,15,0,40,"Rune force"},
{531,0,531,10,15,0,30,30,"Empower fire"},	{532,0,532,10,15,0,30,30,"Empower frost"},	{533,0,533,10,15,0,30,30,"Empower lightning"},	{534,0,534,10,15,0,30,30,"Empower poison"},
{535,0,535,10,15,0,30,30,"Empower chaos"},	{615,0,615,10,15,0,30,30,"Empower force"},
{536,1,536,20,30,5,0,30,"Burst fire"},		{537,1,537,20,30,5,0,30,"Burst frost"},		{538,1,538,20,30,5,0,30,"Burst lightning"},		{539,1,539,20,30,5,0,50,"Burst poison"},
{540,1,540,20,30,5,0,40,"Burst chaos"},		{612,1,612,20,30,1,0,30,"Kinetic burst"},
{541,1,541,100,150,20,0,60,"Nova fire"},	{542,1,542,100,150,20,0,60,"Nova frost"}, 	{543,1,543,100,150,20,0,60,"Nova lightning"}, 	{544,1,544,100,150,20,0,100,"Nova poison"},
{545,1,545,100,150,20,0,80,"Nova chaos"},	{616,1,616,100,150,20,0,80,"Nova force"},
{546,1,546,6,6,1,0,15,"Ray fire"},			{547,1,547,6,6,1,0,15,"Ray frost"},			{548,1,548,6,6,1,0,15,"Ray lightning"},			{549,1,549,6,6,1,0,25,"Ray poison"},
{550,1,550,6,6,1,0,20,"Ray chaos"},			{613,1,613,5,10,1,0,20,"Kinetic hail"},
{551,2,551,10,20,5,20,10,"Totem fire"},		{552,2,552,10,20,5,20,10,"Totem frost"},	{553,2,553,10,20,5,20,10,"Totem lightning"},	{554,2,554,10,20,5,20,10,"Totem poison"},
{555,2,555,10,20,5,20,10,"Totem chaos"},	{619,2,619,10,20,5,20,10,"Totem force"},	{620,2,620,10,20,1,20,10,"Totem arrow"},
--{556,0,556,10,15,0,30,30,"Empower fire"},	{557,0,557,10,15,0,30,30,"Empower frost"},	{558,0,558,10,15,0,30,30,"Empower lightning"},	{559,0,559,10,15,0,30,30,"Empower poison"},	{560,0,560,10,15,0,30,30,"Empower chaos"},
{561,0,561,10,15,0,30,30,"Reflect fire"},	{562,0,562,10,15,0,30,30,"Reflect frost"},	{563,0,563,10,15,0,30,30,"Reflect lightning"},	{564,0,564,10,15,0,30,30,"Reflect poison"},	{565,0,565,10,15,0,30,30,"Reflect chaos"},
{566,2,566,15,25,20,0,30,"Wave fire"},		{567,2,567,15,25,20,0,30,"Wave frost"},		{568,2,568,15,25,20,0,30,"Wave lightning"},		{569,2,569,15,25,20,0,50,"Wave poison"},
{570,2,570,15,25,20,0,40,"Wave chaos"},		{617,2,617,15,25,20,0,40,"Wave force"},

{134,0,134,1,1,0,20,160,eng and "Summon Daedra-spider" or "Вызов даэдра-паука"},		
{137,0,137,1,1,0,20,180,eng and "Summon Dark Seducer" or "Вызов темной соблазнительницы"},	{138,0,138,1,1,0,20,160,eng and "Summon Dremora mage" or "Вызов дреморы мага"},			
{139,0,139,1,1,0,20,240,eng and "Summon Xivkyn" or "Вызов зивкина"},						{140,0,140,1,1,0,20,100,eng and "Summon Skaafin archer" or "Вызов скаафина лучника"},
{141,0,141,1,1,0,20,140,eng and "Summon Xivilai" or "Вызов ксивилаи"},						{142,0,142,1,1,0,20,70,eng and "Summon Skeleton archer" or "Вызов скелета лучника"}},
SFS = {500,501,502,503,504,"504a",505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,
551,552,553,554,555,
561,562,563,564,565,566,567,568,569,570,600,601,  603,611,612,613,614,615,616,617,618,619,620},
SSEL = {["marayn dren"] = {"flame", "fire bite", "fireball", "firefist", "Fireball_large", "firebloom", "flamebolt", "burning touch", "fire storm", "cruel firebloom", "wizard's fire", "god's fire",
"shard", "frostbite", "frostball", "frostfist", "Frostball_large", "frostbloom", "frost bolt", "freezing touch", "frost storm", "brittlewind", "wizard rend", "god's frost",
"spark", "shock", "shockball", "stormhand", "shockball_large", "shockbloom", "lightning bolt", "shocking touch", "lightning storm", "wild shockbloom", "dire shockball", "god's spark",
"shock barrier", "fierce shock shield", "strong shock shield", "lightning shield",
"fire barrier", "fierce fire shield", "strong fire shield", "fire shield",
"frost barrier", "fierce frost shield", "strong frost shield", "frost shield",
"burden", "heavy burden", "crushing burden", "burden touch", "heavy burden touch", "crushing burden touch", "burden of sin", "great burden of sin", "crushing burden of sin", "weary", "cruel weary", "dire weary",
"disintegrate armor", "disintegrate weapon",
"open", "ondusi's open door", "strong open", "wild open", "great open",
"4s_kinetic_strike_1", "4s_kinetic_strike_2", "4s_kinetic_strike_3"},

["sharn gra-muzgob"] = {"stamina", "rest of st. merris", "resist corpus disease", "resist corprus disease",
"variable resist corpus disease", "strong resist corpus disease", "great resist corpus disease",
"variable resist corprus disease", "strong resist corprus disease", "great resist corprus disease",
"balyna's soothing balm", "balyna's efficacious balm", "balyna's perfect balm",
"hearth heal", "veloth's benison", "veloth's grace", "regenerate", "rapid regenerate", "mother's kiss",
"heal companion", "strong heal companion", "great heal companion", "cure common disease victim", "rilm's cure", "sp_rangedheal",
"restore willpower", "restore endurance", "restore personality", "restore strength", "restore speed", "restore luck", "restore agility", "restore intelligence",
"cure poison", "balyna's antidote", "panacea", "cure poison touch", "Cure Blight_Self", "Cure Blight Disease", "cure common disease", "cure common disease other", "free action",
"vivec's mercy", "vivec's tears",
"iron will", "fortitude", "wisdom", "nimbleness", "charisma", "orc's strength", "Quicksilver", "divine aid", "vitality", "vigor", "skylamp's shadow",
"rilm's gift", "seryn's gift", "turn of the wheel", "jack of trades", "Zenithar_gospel", "Troll Strength", "feet of notorgo", "Zenithar_blessing", "blood gift", "enrichment", "nibenay's wit",
"daedric willpower", "daedric luck", "daedric intelligence", "daedric personality", "daedric endurance", "daedric speed", "daedric strength", "daedric agility", "daedric health", "daedric fatigue", "powerwell",
"eye of talos", "the red diamond", "hand of the hart-king",
"sanctuary", "sotha's grace", "father's hand",


"resist fire", "variable resist fire", "strong resist fire", "great resist fire", "flameguard", 
"resist frost", "variable resist frost", "strong resist frost", "great resist frost", "frostguard",
"resist shock", "variable resist shock", "strong resist shock", "great resist shock", "shockguard", 
"resist magicka", "variable resist magicka", "strong resist magicka", "great resist magicka", "magickguard",
"resist poison", "variable resist poison", "strong resist poison", "greater resist poison", "poisonguard",
"resist common disease", "variable resist common disease", "poet's whim", "great resist common disease", "shield of the armiger", "resist paralysis", "seryn's blessing"},

["masalinie merian"] = {"recall", "mark", "divine intervention", "almsivi intervention", "llivam's reversal",
"absorb spell points", "absorb spell points [ranged]", "absorb health", "absorb health [ranged]", "absorb fatigue", "absorb fatigue [ranged]",
"absorb intelligence", "absorb intelligence [ranged]", "absorb willpower", "absorb willpower [ranged]", "absorb endurance", "absorb endurance [ranged]", "absorb strength", "absorb strength [ranged]",
"absorb agility", "absorb agility [ranged]", "absorb speed", "absorb speed [ranged]", "absorb luck", "absorb luck [ranged]", "absorb personality", "absorb personality [ranged]",
"dispel", "self dispel", "almalexia's grace", "purge magic", "touch dispel", "soul trap", "slave belt"},

["estirdalin"] = {"poison", "poison_powerful", "poisonous touch", "poisonbloom", "viperbolt", "potent poison", "potent poison [ranged]", "deadly poison", "deadly poison [ranged]",
"scourge blade", "heartbite", "daedric bite", "blood despair", "black hand", "spirit knife", "wound",
"weakness to magicka", "weakness to shock", "weakness to fire", "weakness to frost", "weakness to poison", "weakness to common disease", "weakness to blight disease", "weakness to corpus disease", "weakness to corprus disease", 
"evil eye", "woe", "emasculate", "hex", "fuddle", "stumble", "clench", "gripes",
"curse agility", "curse endurance", "curse fatigue", "curse health", "curse intelligence", "curse luck", "curse personality", "curse speed", "curse spell points", "curse strength", "curse willpower",
"grave curse: agility", "grave curse: endurance", "grave curse: fatigue", "grave curse: health", "grave curse: intelligence", "grave curse: luck",
"grave curse: personality", "grave curse: speed", "grave curse: spell points", "grave curse: strength", "grave curse: willpower",
"dread curse: agility", "dread curse: endurance", "dread curse: fatigue", "dread curse: health", "dread curse: intelligence", "dread curse: luck",
"dread curse: personality", "dread curse: speed", "dread curse: spell points", "dread curse: strength", "dread curse: willpower",
"wild temptation", "wild strain", "wild weeping wound", "wild distraction", "wild clumsiness", "wild flay spirit", "wild weakness", "wild torpor", "wild misfortune", "wild exhaustion", "wild spite",
"tempting touch", "straining touch", "wounding touch", "distracting touch", "clumsy touch", "flay spirit", "weakening touch", "torpor touch", "misfortunate touch", "exhausting touch", "spite touch",
"temptation", "strain", "weeping wound", "distraction", "clumsiness", "flay spirit [ranged]", "weakness", "torpor", "misfortune", "exhaustion", "spite",
"gash spirit", "gash spirit [ranged]", "soulpinch", "spell drain", "magicka leech", "sphere of negation",
"enervating touch", "enervate", "wearying touch", "weariness", "hand of sleep", "sleep",
"blessed touch", "blessed word", "frenzy humanoid", "frenzy creature", "demoralize humanoid",
"cruel earwig", "noise"},

["arrille"] = {"flame", "fire bite", "fireball", "shard", "frostbite", "frostball", "spark", "shock", "shockball", "rest of st. merris", "balyna's soothing balm", "hearth heal", "regenerate", "heal companion"},
["felen maryon"] = {"4s_134", "4s_137", "4s_138", "4s_139", "4s_140", "4s_141", "4s_142", "command beast", "commanding touch"}},
ING = {["4nm"]=true, ["4nm_met"]=true, ["4nm_tet"]=true, ["Enchant_right"]=true, ["Enchant_left"]=true, ["Concentration"]=true,
["Blur"]=true, ["Rally"]=true, ["Spawn_buff"]=true, ["Summon"]=true, ["Dodge"]=true, ["Parry"]=true, ["Survival_instinct"]=true, ["Rest"]=true,
["Electroshock"]=true, ["Freeze"]=true, ["Burning"]=true, ["Poisoning"]=true, ["Decay"]=true, ["KO"]=true}, ["Bell ring"] = true,
BREG = {"CW","RF","RFS","RAY","SG","PR","ElSh","AUR","RUN","TOT","AOE","DC","WAV","EXP","TS"},	--SREG = {"DC"},
BU = {{n="goldaura",{0,3,10,30,0,180},{0,507,50,100,0,180},{0,508,5,10,0,180},{0,76,3,3,0,180}}, {n="elemaura",{0,4,10,20,0,180}},
{n="Fire_arrow",{2,14,8,12,1,1}},		{n="Fire_ball",{2,14,10,20,5,1}},		{n="Fire_bolt",{2,14,20,30,10,1}},	{n="Fire_touch",{1,14,8,12,1,1}},
{n="Frost_arrow",{2,16,8,12,1,1}},		{n="Frost_ball",{2,16,10,20,5,1}},		{n="Frost_bolt",{2,16,20,30,10,1}},	{n="Frost_touch",{1,16,8,12,1,1}},
{n="Shock_arrow",{2,15,8,12,1,1}},		{n="Shock_ball",{2,15,10,20,5,1}},		{n="Shock_bolt",{2,15,20,30,10,1}},	{n="Shock_touch",{1,15,8,12,1,1}},
{n="Poison_arrow",{2,27,2,2,1,5}},		{n="Poison_ball",{2,27,3,3,5,5}},		{n="Poison_bolt",{2,27,5,5,10,5}},
{n="Chaos_arrow",{2,23,8,12,1,1}},		{n="Chaos_ball",{2,23,10,20,5,1}},		{n="Chaos_bolt",{2,23,20,30,10,1}},	{n="Chaos_touch",{1,23,8,12,1,1}},
{n="Kinetic_arrow",{2,602,8,12,1,1}},	{n="Kinetic_ball",{2,602,10,20,5,1}},	{n="Kinetic_bolt",{2,602,20,30,5,1}},
{n="Elemental_touch",{1,14,5,10,1,1},{1,16,5,10,1,1},{1,15,5,10,1,1}},	{n="Storm_touch",{1,15,8,12,1,1},{1,16,8,12,1,1}},	{n="Eerie_touch",{1,23,8,12,1,1},{1,16,8,12,1,1}}, {n="Filth_touch",{1,23,8,12,1,1},{1,27,8,12,1,1}},
{n="Vampire_touch",{1,86,8,12,0,1}},
{n="Poison_bite",{0,27,2,2,0,5},w=1}, {n="Spider_bite",{0,27,3,3,0,10},{0,45,1,1,0,3},w=1}, {n="Lava_fire",{0,14,30,30,0,3}}},
CLEN = {500,500,500,1000,500,500,500,1000,1000,[0]=500}, AREN = {1000,250,250,500,500,500,500,500,250,250,[0]=1000}, ARW = {6,2,2,3,3,1,1,5,[0]=2},
AT = {[3] = {t="u",s=17},
[0] = {t="l",s=21,p="lig0",p5="lig15",p6="lig16",p7="lig17",snd="Light Armor Hit"},
[1] = {t="m",s=2, p="med0",p5="med15",p6="med16",p7="med17",snd="Medium Armor Hit"},
[2] = {t="h",s=3, p="hev0",p5="hev15",p6="hev16",p7="hev17",snd="Heavy Armor Hit"}},
AltW = {2, 1, 4, 3, 3, 1, 8, 7}, W1to2 = {[1] = 2, [3] = 4, [7] = 8},
AG = {[34] = "KO", [35] = "KO"}, AGH = {[19]=1, [20]=1, [21]=1, [22]=1, [23]=1}, AGHS = {[19] = true, [20] = true, [21] = true, [22] = true, [23] = true, [24] = true, [25] = true, [26] = true},
ASN = {[1] = 1, [14] = 1, [15] = 1, [18] = 1, [19] = 1},
ASP = {[4] = 1, [5] = 2, [6] = 2, [7] = 2},
PSO = {{1, 2, 3, 3}, {2, 2, 3, 3}, {3, 3, 3, 4}, {3, 3, 4, 4}},
Traum = {"strength", "endurance", "agility", "speed", "intelligence"},	HealStat = {"endurance", "strength", "agility", "speed", "intelligence", "willpower", "personality"},
BW = {{"dagger", "tanto", "knife", "shortsword", "wakizashi", "machete"},
{"sword", "longsword", "broadsword", "katana", "saber", "scimitar", "rapier", "waraxe", "axe", "club", "mace"},
{"bastard", "claymore", "grossmesser", "daikatana", "odachi", "greatsword", "battleaxe", "grandaxe", "warhammer", "hammer"},
{"spear", "longspear", "naginata", "warscythe", "glaive", "halberd", "bardiche", "pitchfork", "staff", "shortbow", "longbow", "crossbow", "arbalest"}},
CStats = {"strength", "endurance", "agility", "speed", "intelligence", "willpower", "luck", "personality", "combat", "magic", "stealth"},
CrBlackList = {["BM_hircine_straspect"] = 200, ["BM_hircine_spdaspect"] = 150, ["BM_hircine_huntaspect"] = 150, ["BM_hircine"] = 100, ["vivec_god"] = 200, ["Almalexia_warrior"] = 200, ["almalexia"] = 200,
["Imperfect"] = 200, ["lich_barilzar"] = 150, ["lich_relvel"] = 150, ["yagrum bagarn"] = 20, ["bm_frost_giant"] = 150, ["BM_udyrfrykte"] = 50,
["dagoth_ur_1"] = 200, ["dagoth_ur_2"] = 200, ["dagoth araynys"] = 200, ["dagoth endus"] = 200, ["dagoth gilvoth"] = 200, ["dagoth odros"] = 200, ["dagoth tureynul"] = 200, ["dagoth uthol"] = 200, ["dagoth vemyn"] = 200,
["heart_akulakhan"] = 5000, ["mudcrab_unique"] = 100, ["scamp_creeper"] = 10, ["4nm_target"] = 0},
CID = {["bonewalker"] = "zombirise", ["bonewalker_weak"] = "zombirise", ["Bonewalker_Greater"] = "zombirise", ["golden saint"] = "auril", ["golden saint_summon"] = "auril",
["centurion_spider"] = "dwem", ["centurion_sphere"] = "dwem", ["centurion_steam"] = "dwem", ["centurion_projectile"] = "dwem", ["centurion_steam_advance"] = "dwem",
["centurion_spider_miner"] = "dwem", ["centurion_spider_tower"] = "dwem", ["centurion_sword"] = "dwem", ["centurion_weapon"] = "dwem", ["centurion_tank"] = "dwem",
},

CDOD = {["atronach_flame"] = 1, ["atronach_flame_summon"] = 1, ["atronach_flame_lord"] = 1, ["scamp"] = 1, ["clannfear"] = 1, ["clannfear_lesser"] = 1, ["clannfear_summon"] = 1, ["vermai"] = 1, -- НЕ ИСПОЛЬЗУЕТСЯ!
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
DISTYP = {[2] = true, [3] = true},
CPOI = {["alit"] = {"Poison_bite",50}, ["alit_diseased"] = {"Poison_bite",80}, ["alit_blighted"] = {"Poison_bite",80},
["kwama forager"] = {"Poison_bite",30}, ["kwama forager blighted"] = {"Poison_bite",50}, ["netch_bull"] = {"Poison_bite",30},
["vermai"] = {"Poison_bite",30}, ["daedraspider"] = {"Spider_bite",30}, ["daedraspider_s"] = {"Spider_bite",30}, ["daedroth"] = {"Poison_bite",50}, ["daedroth_summon"] = {"Poison_bite",50}},

CMAG = {["atronach_flame"] = {"Fire_touch",100}, ["atronach_flame_summon"] = {"Fire_touch",100}, ["atronach_flame_lord"] = {"Fire_touch",100}, 
["atronach_frost"] = {"Frost_touch",100}, ["atronach_frost_summon"] = {"Frost_touch",100}, ["atronach_frost_lord"] = {"Frost_touch",100}, ["atronach_frost_BM"] = {"Frost_touch",100}, 
["atronach_storm"] = {"Shock_touch",100}, ["atronach_storm_summon"] = {"Shock_touch",100}, ["atronach_storm_lord"] = {"Shock_touch",100},
["winged twilight"] = {"Storm_touch",30}, ["winged twilight_summon"] = {"Storm_touch",30},
["dremora_mage"] = {"Elemental_touch",50}, ["dremora_mage_s"] = {"Elemental_touch",50},
["golden saint"] = {"Elemental_touch",20}, ["golden saint_summon"] = {"Elemental_touch",20},
["skeleton_mage"] = {"Elemental_touch",20}, ["skeleton_mage_s"] = {"Elemental_touch",20},
["hunger"] = {"Vampire_touch",50}, ["hunger_summon"] = {"Vampire_touch",50},
["bonelord"] = {"Chaos_touch",100}, ["bonelord_summon"] = {"Chaos_touch",100},
["lich"] = {"Filth_touch",100}, ["lich_elder"] = {"Eerie_touch",100}, ["draugr_priest"] = {"Chaos_touch",50},
["ancestor_ghost"] = {"Frost_touch",50}, ["ancestor_ghost_summon"] = {"Frost_touch",50}, ["ancestor_ghost_greater"] = {"Eerie_touch",50}, ["dwarven ghost"] = {"Frost_touch",75}, 
["shalk"] = {"Fire_touch",50}, ["shalk_diseased"] = {"Fire_touch",40}, ["shalk_blighted"] = {"Fire_touch",50}, ["netch_betty"] = {"Shock_touch",30},
["BM_wolf_snow_unique"] = {"Frost_touch",20}, ["BM_bear_snow_unique"] = {"Frost_touch",20}, ["slaughterfish_electro"] = {"Shock_touch",50}},

MAC = {[0] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Kinetic_arrow"},
["atronach_flame"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_summon"] = {"Fire_ball","Fire_bolt"}, ["atronach_flame_lord"] = {"Fire_bolt"},
["atronach_frost"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_summon"] = {"Frost_ball","Frost_bolt"}, ["atronach_frost_lord"] = {"Frost_bolt"}, ["atronach_frost_BM"] = {"Frost_ball","Frost_bolt"},
["atronach_storm"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_summon"] = {"Shock_ball","Shock_bolt"}, ["atronach_storm_lord"] = {"Shock_bolt"},
["dremora"] = {"Fire_arrow","Fire_ball"}, ["dremora_summon"] = {"Fire_arrow","Fire_ball"}, ["dremora_lord"] = {"Fire_ball","Fire_bolt"},
["golden saint"] = {"Fire_bolt","Frost_bolt","Shock_bolt"}, ["golden saint_summon"] = {"Fire_bolt","Frost_bolt","Shock_bolt"},
["mazken"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"}, ["mazken_s"] = {"Chaos_bolt","Frost_bolt","Shock_bolt"},
["hunger"] = {"Chaos_arrow","Chaos_ball"}, ["hunger_summon"] = {"Chaos_arrow","Chaos_ball"},
["scamp"] = {"Fire_arrow"}, ["scamp_summon"] = {"Fire_arrow"}, ["daedroth"] = {"Poison_arrow","Poison_ball"}, ["daedroth_summon"] = {"Poison_arrow","Poison_ball"},
["winged twilight"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"}, ["winged twilight_summon"] = {"Frost_arrow","Frost_ball","Shock_arrow","Shock_ball"},
["dremora_mage"] = {"Fire_ball","Frost_ball","Shock_ball","Kinetic_ball","Fire_bolt","Frost_bolt","Shock_bolt","Kinetic_bolt"},
["dremora_mage_s"] = {"Fire_ball","Frost_ball","Shock_ball","Kinetic_ball","Fire_bolt","Frost_bolt","Shock_bolt","Kinetic_bolt"},
["daedraspider"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"}, ["daedraspider_s"] = {"Poison_ball","Poison_bolt","Chaos_ball","Chaos_bolt"},
["xivilai"] = {"Fire_ball","Chaos_ball"}, ["xivilai_s"] = {"Fire_ball","Chaos_ball"},
["xivkyn"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"}, ["xivkyn_s"] = {"Fire_ball","Fire_bolt","Shock_ball","Shock_bolt"},

["ancestor_ghost"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_summon"] = {"Chaos_arrow","Frost_arrow"}, ["ancestor_ghost_greater"] = {"Chaos_arrow","Chaos_ball","Frost_arrow","Frost_ball"},
["Bonewalker_Greater"] = {"Chaos_arrow"}, ["Bonewalker_Greater_summ"] = {"Chaos_arrow"},
["bonelord"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"}, ["bonelord_summon"] = {"Chaos_ball","Chaos_bolt","Frost_ball","Frost_bolt"},
["skeleton_mage"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Kinetic_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball","Kinetic_ball"},
["skeleton_mage_s"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Chaos_arrow","Kinetic_arrow","Fire_ball","Frost_ball","Shock_ball","Chaos_ball","Kinetic_ball"},
["lich"] = {"Frost_ball","Poison_ball","Chaos_ball","Frost_bolt","Poison_bolt","Chaos_bolt"}, ["lich_elder"] = {"Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt"},
["ash_revenant"] = {"Poison_ball","Chaos_ball"}, ["draugr_priest"] = {"Frost_ball","Chaos_ball"},

["ash_slave"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Kinetic_arrow"},
["ash_ghoul"] = {"Chaos_ball","Chaos_bolt"}, ["ash_ghoul_warrior"] = {"Chaos_arrow","Chaos_ball"},
["ash_ghoul_high"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt","Kinetic_bolt"},
["ascended_sleeper"] = {"Fire_bolt","Frost_bolt","Shock_bolt","Poison_bolt","Chaos_bolt","Kinetic_bolt"},

["centurion_spider_tower"] = {"Shock_arrow"}, ["centurion_spider_miner"] = {"Fire_arrow"},
["kwama warrior"] = {"Poison_arrow","Poison_ball"}, ["kwama warrior blighted"] = {"Poison_arrow","Poison_ball"},
["netch_bull"] = {"Poison_arrow","Poison_ball"}, ["netch_betty"] = {"Shock_arrow","Shock_ball"},
["goblin_handler"] = {"Fire_arrow"}, ["goblin_officer"] = {"Fire_arrow"},
["goblin_shaman"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Kinetic_arrow","Fire_ball","Frost_ball","Shock_ball","Kinetic_ball"},
["BM_riekling_shaman"] = {"Fire_arrow","Frost_arrow","Shock_arrow","Kinetic_arrow","Fire_ball","Frost_ball","Shock_ball","Kinetic_ball"},
["BM_spriggan"] = {"Frost_ball","Poison_ball"}},
Summon = {["atronach_flame_summon"] = true,["atronach_frost_summon"] = true,["atronach_storm_summon"] = true,["golden saint_summon"] = true,["daedroth_summon"] = true,["dremora_summon"] = true,["scamp_summon"] = true,
["winged twilight_summon"] = true,["clannfear_summon"] = true,["hunger_summon"] = true,["Bonewalker_Greater_summ"] = true,["ancestor_ghost_summon"] = true,["skeleton_summon"] = true,["bonelord_summon"] = true,
["daedraspider_s"] = true,["dremora_mage_s"] = true,["skaafin_archer_s"] = true,["xivkyn_s"] = true,["xivilai_s"] = true,["mazken_s"] = true,["skeleton_mage_s"] = true,["skeleton_archer_s"] = true,
["BM_bear_black_summon"] = true,["BM_wolf_grey_summon"] = true,["BM_wolf_bone_summon"] = true,["bonewalker_summon"] = true,["centurion_sphere_summon"] = true,["fabricant_summon"] = true},
UndMinion = {"skeleton_weak", "bonewalker_weak", "skeleton", "bonewalker", "skeleton archer", "skeleton warrior", "skeleton champion", "Bonewalker_Greater"},
Blight = {"ash woe blight", "black-heart blight", "chanthrax blight", "ash-chancre"},
atrbot = {["atronach_flame"] = {4}, ["atronach_flame_summon"] = {4}, ["atronach_flame_lord"] = {4,114},
["atronach_frost"] = {6}, ["atronach_frost_summon"] = {6}, ["atronach_frost_lord"] = {6,115},
["atronach_storm"] = {5}, ["atronach_storm_summon"] = {5}, ["atronach_storm_lord"] = {5,116}},
BlackItem = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["bound_greaves"] = true, ["bound_pauldron_left"] = true, ["bound_pauldron_right"] = true,
["4_bound arbalest"] = true, ["4_bound axe"] = true, ["4_bound bardiche"] = true, ["4_bound bastard"] = true, ["4_bound battleaxe"] = true, ["4_bound broadsword"] = true, ["4_bound claymore"] = true,
["4_bound club"] = true, ["4_bound crossbow"] = true, ["4_bound dagger"] = true, ["4_bound daikatana"] = true, ["4_bound glaive"] = true, ["4_bound grandaxe"] = true, ["4_bound greatsword"] = true,
["4_bound grossmesser"] = true, ["4_bound halberd"] = true, ["4_bound hammer"] = true, ["4_bound katana"] = true, ["4_bound knife"] = true, ["4_bound longbow"] = true, ["4_bound longspear"] = true,
["4_bound longsword"] = true, ["4_bound mace"] = true, ["4_bound machete"] = true, ["4_bound naginata"] = true, ["4_bound odachi"] = true, ["4_bound pitchfork"] = true, ["4_bound rapier"] = true,
["4_bound saber"] = true, ["4_bound scimitar"] = true, ["4_bound shortbow"] = true, ["4_bound shortsword"] = true, ["4_bound spear"] = true, ["4_bound staff"] = true, ["4_bound sword"] = true,
["4_bound tanto"] = true, ["4_bound wakizashi"] = true, ["4_bound waraxe"] = true, ["4_bound warhammer"] = true, ["4_bound warscythe"] = true},
BlackAmmo = {["4nm_poisonbottle"] = true, ["4nm_boundarrow"] = true, ["4nm_boundbolt"] = true, ["4nm_boundstar"] = true, ["4nm_stone"] = true},
DurKF = {[22]=3,[24]=3,[25]=3,[26]=3,[86]=3,[87]=3,[88]=3},
nomag = {[39] = true, [45] = true, [46] = true, [69] = true, [70] = true, [72] = true, [73] = true},
ELME = {[14] = 1, [15] = 0.75, [16] = 0.75},
BLASTME = {[602] = 1, [14] = 1, [15] = 0.75, [16] = 0.75},

CME = {[4] = {25, "Freeze", 1}, [6] = {34, "Burning", 5}, [5] = {24, "Electroshock", 1}, [72] = {25, "Poisoning", 100}, [73] = {24, "Electroshock", 100}, [57] = {25, "Decay", 5},
[516] = {25, "Freeze", 2}, [517] = {34, "Burning", 10}, [518] = {24, "Electroshock", 2}},
MESLD = {[3] = true, [4] = true, [5] = true, [6] = true},
ELSH = {[4] = {id = 14, ts = 0}, [5] = {id = 15, ts = 0}, [6] = {id = 16, ts = 0}},



CLR = {[1]={1,0,0}, [2]={1,0.5,0}, [3]={1,1,0}, [4]={0,1,0}, [5]={0,1,1}, [6]={0,0,1}, [7]={1,0,1}},
RES = {[14] = "resistFire", [16] = "resistFrost", [15] = "resistShock", [27] = "resistPoison"},
EDAT = {[501] = true, [502] = true, [503] = true, [504] = true, [507] = true, [508] = true, [509] = true,
[511] = true, [512] = true, [513] = true, [514] = true, [515] = true, [614] = true,
[531] = true, [532] = true, [533] = true, [534] = true, [535] = true, [615] = true,
[516] = true, [517] = true, [518] = true, [519] = true, [520] = true,
[561] = true, [562] = true, [563] = true, [564] = true, [565] = true},

MID = {[1] = 14, [2] = 16, [3] = 15, [4] = 27, [5] = 23, [6] = 602},
MESG = {[536] = 14, [537] = 16, [538] = 15, [539] = 27, [540] = 23, [612] = 611},
MERAY = {[546] = 14, [547] = 16, [548] = 15, [549] = 27, [550] = 23, [613] = 611},
MECW = {[511] = 14, [512] = 16, [513] = 15, [514] = 27, [515] = 23, [614] = 602},
MEEMP = {[531] = 14, [532] = 16, [533] = 15, [534] = 27, [535] = 23, [615] = 602},
MENOV = {[541] = 14, [542] = 16, [543] = 15, [544] = 27, [545] = 23, [616] = 602},
MEWAV = {[566] = 14, [567] = 16, [568] = 15, [569] = 27, [570] = 23, [617] = 602},
MERUN = {[526] = 14, [527] = 16, [528] = 15, [529] = 27, [530] = 23, [618] = 602},
METOT = {[551] = 14, [552] = 16, [553] = 15, [554] = 27, [555] = 23, [619] = 602, [620] = 611},
METOTc = {[551] = 3, [552] = 3, [553] = 3, [554] = 5, [555] = 4, [619] = 4, [620] = 3},
LID = {[526] = tes3vector3.new(255,128,0), [527] = tes3vector3.new(0,255,255), [528] = tes3vector3.new(255,0,255), [529] = tes3vector3.new(0,255,0), [530] = tes3vector3.new(255,0,0), [618] = tes3vector3.new(128,0,255),
[551] = tes3vector3.new(255,128,0), [552] = tes3vector3.new(0,255,255), [553] = tes3vector3.new(255,0,255), [554] = tes3vector3.new(0,255,0), [555] = tes3vector3.new(255,0,0), [619] = tes3vector3.new(128,0,255),
[620] = tes3vector3.new(255,255,0)},

MEAOE = {[521] = 14, [522] = 16, [523] = 15, [524] = 27, [525] = 23},
AoEmod = {[521] = "4nm_aoe_fire", [522] = "4nm_aoe_frost", [523] = "4nm_aoe_shock", [524] = "4nm_aoe_poison", [525] = "4nm_aoe_vitality"},
MEAUR = {[516] = 14, [517] = 16, [518] = 15, [519] = 27, [520] = 23},
MEABS = {[87] = "magicka", [88] = "fatigue", [85] = "attributes"},
MESUM = {[102]=true,[103]=true,[104]=true,[105]=true,[106]=true,[107]=true,[108]=true,[109]=true,[110]=true,[111]=true,[112]=true,[113]=true,[114]=true,[115]=true,[116]=true,[134]=true,[137]=true,[138]=true,[139]=true,[140]=true,[141]=true,[142]=true,
[223]=true, [224]=true, [225]=true, [226]=true, [227]=true, [228]=true, [252]=true, [253]=true, [254]=true, [255]=true, [256]=true, [257]=true, [258]=true, [259]=true, [260]=true, [261]=true, [262]=true,
[267]=true, [268]=true, [269]=true, [270]=true, [271]=true, [272]=true, [273]=true, [274]=true, [275]=true, [276]=true, [277]=true, [278]=true, [279]=true, [280]=true, [281]=true, [282]=true, [283]=true,
[284]=true, [285]=true, [286]=true, [287]=true, [288]=true, [289]=true, [290]=true, [291]=true, [292]=true, [326]=true, [327]=true, [420]=true, [426]=true, [427]=true, [430]=true, [431]=true,
[2090]=true, [2091]=true, [2092]=true, [2093]=true, [2094]=true, [2095]=true, [2096]=true, [2097]=true, [2098]=true, [2099]=true, [2100]=true, [2101]=true, [2102]=true, [2103]=true, [2104]=true, [2105]=true,
[2107]=true, [2108]=true, [2109]=true, [2110]=true, [2117]=true, [2126]=true, [2127]=true, [2128]=true, [2129]=true, [2130]=true,
[3301]=true, [3302]=true, [3303]=true, [3304]=true, [3305]=true, [3306]=true, [3307]=true, [3308]=true, [7700]=true, [7701]=true, [7702]=true, [7703]=true, [7704]=true, [7705]=true, [7706]=true, [7800]=true},
MEBOUND = {[120]=1,[121]=1,[122]=1,[123]=1,[124]=1,[125]=1,[127]=true,[128]=true,[129]=true,[130]=true,[131]=true,[601]=true,[603]=1,[604]=true,[605]=true,
[229]=1, [230]=1, [231]=1, [232]=1, [233]=1, [234]=1, [235]=1, [236]=1, [237]=1, [238]=1, [239]=true, [240]=true, [264]=true, [429]=true, [704]=true, [705]=true, [706]=1,
[2111]=true, [2112]=1, [2113]=1, [2114]=1, [2115]=1, [2116]=true},
MeBondArm = {[127] = 1, [128] = 0, [604] = 4},
UItcolor = {{1,1,1},{0,1,0},{0,1,1},{1,1,0}},
TPP = {{-23000, -15200, 700}, {-14300, 52400, 2300}, {30000, -77600, 2000}, {150300, 31800, 900}, {17800, -101900, 500}, {-11200, 20000, 1500}, {53800, -51000, 400}, {-86800, 92300, 1200},
{1900, -56800, 1700}, {125000, -105200, 1000}, {125200, 45200, 1800}, {109500, 116000, 600}, {-21600, 103200, 2200}, {105400, -61800, 700}, {60200, 183300, 500}, {-11100, -71000, 500},
{-46600, -38100, 400}, {-60100, 26700, 400}, {-68400, 140400, 400}, {-85400, 125600, 1200}, {94600, 115800, 1800}, {87500, 118100, 3700}},
BotQ = {"bargain", "cheap", "standard", "quality", "exclusive"},
BotIc = {["m\\Tx_potion_bargain_01.tga"] = "bargain", ["m\\Tx_potion_cheap_01.tga"] = "cheap", ["m\\Tx_potion_fresh_01.tga"] = "cheap",
["m\\Tx_potion_standard_01.tga"] = "standard", ["m\\Tx_potion_quality_01.tga"] = "quality", ["m\\Tx_potion_exclusive_01.tga"] = "exclusive"},
BotMod = {["m\\misc_potion_bargain_01.nif"] = {"w\\4nm_bottle1.nif", "m\\Tx_potion_bargain_01.tga"}, ["m\\misc_potion_cheap_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_cheap_01.tga"},
["m\\misc_potion_fresh_01.nif"] = {"w\\4nm_bottle2.nif", "m\\Tx_potion_fresh_01.tga"}, ["m\\misc_potion_standard_01.nif"] = {"w\\4nm_bottle3.nif", "m\\Tx_potion_standard_01.tga"},
["m\\misc_potion_quality_01.nif"] = {"w\\4nm_bottle4.nif", "m\\Tx_potion_quality_01.tga"}, ["m\\misc_potion_exclusive_01.nif"] = {"w\\4nm_bottle5.nif", "m\\Tx_potion_exclusive_01.tga"}},
BadDoors = {["dn\\door_dwrv_inner00_dn.nif"] = true, ["d\\ex_t_door_slavepod_01.nif"] = true},
Anvil = {furn_anvil00 = true, furn_t_fireplace_01 = true, furn_de_forge_01 = true, furn_de_bellows_01 = true, Furn_S_forge = true},
DWOBT = {[tes3.objectType.light] = true, [tes3.objectType.lockpick] = true, [tes3.objectType.probe] = true},
BartT = {bartersAlchemy = true, bartersApparatus = true, bartersArmor = true, bartersBooks = true, bartersClothing = true, bartersEnchantedItems = true, bartersIngredients = true,
bartersLights = true, bartersLockpicks = true, bartersMiscItems = true, bartersProbes = true, bartersRepairTools = true, bartersWeapons = true},
CCount = {"*","**","***","****","*****","******","*******","********",[0]=""},
MAT = {Dirt = "Dirt", Metal = "Metal", Stone = "Stone", Wood = "Wood", Ice = "Ice", Carpet = "Dirt", Grass = "Dirt", Gravel = "Dirt", Sand = "Dirt", Snow = "Dirt", Mud = "Dirt", Water = "Water"},
MatD = {Dmg = 0.5, DmgDwemer = 1, DmgSkeleton = 0.5, DmgGhost = 0.1, Dirt = 0.3, Metal = 1, Stone = 0.8, Wood = 0.4, Ice = 0.4, Carpet = 0.3, Grass = 0.3, Gravel = 0.5, Sand = 0.3, Snow = 0.2, Mud = 0.2, Water = 0.05},
MatSpark = {Stone = true, Metal = true, DmgDwemer = true},
LavaScript = {["lava"] = true, ["AB_Lava_s"] = true},
REPA = {--IDQualMaxValue
["AB_Repair_DwrvHammer"] = {q = 2, m = 10, v = 300},
["AB_Repair_Flatter_01"] = {q = 1, m = 10, v = 20},
["AB_Repair_Fuller_01"] = {q = 1, m = 10, v = 20},
["AB_Repair_Swage_01"] = {q = 1, m = 10, v = 20},
["AB_Repair_Mallet_01"] = {q = 0.5, m = 10, v = 10},
["T_Com_Hammer_Repair_01"] = {q = 1, m = 10, v = 20},
["T_Com_Hammer_Repair_02"] = {q = 1.25, m = 10, v = 50},
["T_Com_Tongs_Repair_01"] = {q = 0.5, m = 10, v = 10},
["T_Dwe_Hammer_Repair_01"] = {q = 2, m = 10, v = 300},
["TR_m4_AndothDweRuinHammer02"] = {q = 1.25, m = 10, v = 50},
["TR_m4_AndothDweRuinProngs01"] = {q = 0.5, m = 10, v = 10},
["TR_m4_q_blessed_prongs"] = {q = 2, m = 20, v = 500},
["TR_m4_TJ_RepairHammer"] = {q = 2, m = 10, v = 300},
["AATL_REP_Rusty"] = {q = 0.5, m = 10, v = 10},
["DEMrepair"] = {q = 2, m = 100, v = 10000},
["SLF_CP_repair_journeyman_01_Ena"] = {q = 1, m = 10, v = 20},
["SLF_CP_Com_Hammer_Repair_01_Ena"] = {q = 0.75, m = 10, v = 15},
["SLF_CP_Com_Tongs_Repair_01_Enab"] = {q = 0.5, m = 10, v = 10},
["SLF_CP_repair_prongs_Enable"] = {q = 0.5, m = 10, v = 10},
["SLF_CP_chalda_hammer"] = {q = 1.25, m = 10, v = 50},
},
ESP = {["4NM.esp"] = true, ["4NM.ESP"] = true, ["Morrowind.esm"] = true, ["Tribunal.esm"] = true, ["Bloodmoon.esm"] = true},
CF = {}, APP = {}, FIL = {}, TCash = {}, RAR = {}}
G.TutN = #L.TUT
local SP = {[9] = {s = 9, p4 = "enc2"},		[10] = {s = 9, p4 = "enc3"},	--9 зачарование при использовании, 10 зачарование при ударе
[0] = {s = 11, p1 = "alt1", p2 = "alt2", p3 = "alt3", p4 = "alt4", ps = "alt30", pc = "alt31"},	[1] = {s = 13, p1 = "con1", p2 = "con2", p3 = "con3", p4 = "con4", ps = "con30", pc = "con31"},
[2] = {s = 10, p1 = "des1", p2 = "des2", p3 = "des3", p4 = "des4", ps = "des30", pc = "des31"},	[3] = {s = 12, p1 = "ill1", p2 = "ill2", p3 = "ill3", p4 = "ill4", ps = "ill30", pc = "ill31"},
[4] = {s = 14, p1 = "mys1", p2 = "mys2", p3 = "mys3", p4 = "mys4", ps = "mys30", pc = "mys31"},	[5] = {s = 15, p1 = "res1", p2 = "res2", p3 = "res3", p4 = "res4", ps = "res30", pc = "res31"}}
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
[120]=3,[121]=3,[122]=3,[123]=3,[124]=3,[125]=3,[127]=3,[128]=3,[129]=3,[130]=3,[131]=3,[601]=3,[603]=3,[604]=3,[605]=3, [14]=1, [15]=1, [16]=1, [75]=2, [76]=2, [77]=2,
[79]=4, [80]=4, [81]=4, [82]=4, [83]=4, [84]=4, [117]=4, [42]=4, [90]=5, [91]=5, [92]=5, [93]=5, [94]=5, [95]=5, [97]=5, [98]=5, [99]=5,
[17]=6, [18]=6, [19]=6, [20]=6, [21]=6, [28]=7, [29]=7, [30]=7, [31]=7, [32]=7, [33]=7, [35]=7, [36]=7,
[61] = "teleport", [62] = "teleport", [63] = "teleport"}
local EMP = {[14] = {rf = "e561", p = "des6a", p1 = "des5a", p2 = "wil9a", p3 = "end7a", txt = "fire"},
[16] = {rf = "e562", p = "des6b", p1 = "des5b", p2 = "wil9b", p3 = "end7b", txt = "frost"},
[15] = {rf = "e563", p = "des6c", p1 = "des5c", p2 = "wil9c", p3 = "end7c", txt = "lightning"},
[27] = {rf = "e564", p = "des6d", p1 = "des5d", p2 = "wil9d", p3 = "end7d", txt = "poison"},
[23] = {rf = "e565", p = "des6e", p1 = "des5e", p2 = "wil9e", txt = "chaos"}}
local function adds(...) for i,s in ipairs{...} do --tes3.addSpell{reference = G.CRref, spell = s}	
G.SPList:add(s) 
end end
local function rems(...) for i,s in ipairs{...} do --tes3.removeSpell{reference = G.CRref, spell = s}	
G.SPList:remove(s)
end end
local function Mod(cost, m) local stat = (m or mp).magicka	stat.current = stat.current - cost 	if not m or m == mp then M.Mana.current = stat.current end end
local function Mag(id, r) return (tes3.getEffectMagnitude{reference = r or p, effect = id}) end
local function TFR(n, f) if n == 0 then f() else timer.delayOneFrame(function() TFR(n - 1, f) end) end end
local function TC(tab) return tab[math.random(#tab)] end

L.Cpow = function(m, sc, stam) if m == mp then
	local stat = math.min(math.min(m.willpower.current,500) * ((G.TR.tr24 and 0.75 or 0.5) + (P.wil1 and 0.25 or 0)) + math.min(m:getSkillValue(SP[sc].s),200) * (P[SP[sc].p1] and 1 or 0.75), 600)
	return (stam and math.min(math.lerp(P.wil2 and 0.75 or 0.5, 1, m.fatigue.normalized*(P[SP[sc].p3] and 2 or 1.25)), 1) or 1)
	* (0.5 + 2*stat/(stat+600))
else return math.min(0.5 + m.willpower.current/200 + m:getSkillValue(SP[sc].s)/200, 2) end end

L.MCOST = function(sc)
	local McStat = math.min(math.min(mp.intelligence.current,500) * ((G.TR.tr25 and 0.8 or 0.4) + (P.int1 and 0.2 or 0))
	+ math.min(mp:getSkillValue(SP[sc].s),200) * ((P[SP[sc].p4] and 0.8 or 0.4) + (P.mys10 and 0.2 or 0)), 600)
	return (1.5 - (McStat/(McStat+200))) * (D.AR.mc < 1 and D.AR.mc or math.max(D.AR.mc - G.LIG, 1))
end

L.SetGlobal = function(new)	local w = mp.readiedWeapon		w = w and w.object
G.stop = tes3.findGlobal("4nm_stoptraining")	G.leskoef = G.TR.tr1 and 1 or 3		if p.object.level * G.leskoef > D.L.les and G.stop.value == 1 then G.stop.value = 0 end
if not new then M.TOX.max = (P.end9 and 100 or 75) + mp.endurance.base/4
	M.PC.max = L.GetPCmax()
end
G.WdmgM = (P.arm3 and math.max(0.1 - mp.armorer.base/2000, 0.05) or 0.1)	G.WdmgM2 = G.WdmgM * (G.TR.tr10 and 2 or 1)

G.SPRT = P.atl15 and 1 or 3		T.SPR = timer.start{duration = G.SPRT, callback = function() end}	T.SPR:cancel()

tes3.findGMST("fMajorSkillBonus").value = G.TR.tr1 and 0.5 or 1
tes3.findGMST("fMinorSkillBonus").value = G.TR.tr1 and 0.75 or 1.25
tes3.findGMST("fMiscSkillBonus").value = G.TR.tr1 and 1 or 1.5

tes3.findGMST("fUnarmoredBase2").value = P.una0 and 0.02 or 0.01

tes3.findGMST("fHoldBreathTime").value = (20 + mp.endurance.base/5 + mp.athletics.base/5) * (P.atl4 and 2 or 1)
--tes3.findGMST("fSwimRunAthleticsMult").value = mp.athletics.base/(P.atl5 and 500 or 1000)


tes3.findGMST("fMagicItemRechargePerSecond").value = mp.enchant.base/(P.enc12 and 1000 or 2000)
tes3.findGMST("fEnchantmentChanceMult").value = P.enc14 and 1 or 2
tes3.findGMST("fEnchantmentConstantChanceMult").value = P.luc9 and 1 or 0.5

--tes3.findGMST("fSneakSpeedMultiplier").value = P.snek2 and math.min(0.75 + mp.sneak.base/400, 1) or 0.75
--tes3.findGMST("fPickLockMult").value = P.sec1 and -1 or -2
--tes3.findGMST("fTrapCostMult").value = P.sec2 and -1 or -2

tes3.findGMST("iTrainingMod").value = P.merc1 and 10 or 20
tes3.findGMST("fSpellValueMult").value = P.merc1 and 10 or 20
tes3.findGMST("fRepairMult").value = P.merc6 and 1 or 2
tes3.findGMST("fSpellMakingValueMult").value = P.merc7 and 10 or 20
tes3.findGMST("fEnchantmentValueMult").value = P.merc8 and 50 or 100
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
--tes3.findGlobal("WerewolfClawMult").value = 5
end
L.HPUpdate = function()
--	local Corp = tes3.getJournalIndex{id = "A2_2_6thHouse"} >= 50 and 50 or 0
	local Lord = mp.birthsign.id == "Trollkin" and ((D.chimstar == 2 and 30) or (D.chimstar == 1 and 20) or 10) or 0
	local Steed = mp.birthsign.id == "Charioteer" and ((D.chimstar == 2 and 100) or (D.chimstar == 1 and 100) or 50) or 0
	mp.shield = (P.end14 and 5 or 0) + (P.med21 and 5 or 0) + (P.hev21 and 5 or 0) + (P.bloc21 and 5 or 0) + (D.LEG.e3 or 0) + Lord + tes3.getEffectMagnitude{reference = p, effect = 3}
	
	local PerkHP = 0	for i, perk in ipairs(L.PERST[80]) do if P[perk] then PerkHP = PerkHP + 10 end end
	tes3.setStatistic{reference = p, name = "health", base = tes3.getEffectMagnitude{reference = p, effect = 80}
	+ mp.endurance.base * (G.TR.tr21 and 0.25 or 0.5)
	+ mp.strength.base * (G.TR.tr22 and 0 or 0.25)
	+ mp.willpower.base * (G.TR.tr23 and 0 or 0.25)
	+ mp.luck.base * (G.TR.tr2 and 0.25 or 0.5)
	+ PerkHP + (D.LEG.e80 or 0) + (L.RHP[p.object.race.id] or 0)}
	if mp.health.normalized > 1 then mp.health.current = mp.health.base end
	L.MPUpdate()	L.STUpdate()
	
	local PerkEnc = 0	for i, perk in ipairs(L.PERST[8]) do if P[perk] then PerkEnc = PerkEnc + 40 end end
	tes3.setStatistic{reference = p, name = "encumbrance", base = 100 + mp.strength.base + (G.TR.tr9 and 0 or mp.endurance.base) + (L.RENC[p.object.race.id] or 0) + PerkEnc + Steed}
	mp.encumbrance.currentRaw = p.object.inventory:calculateWeight() + tes3.getEffectMagnitude{reference = p, effect = 7} - tes3.getEffectMagnitude{reference = p, effect = 8}
	- (G.TR.tr9 and mp.endurance.base * 0.5 or 0) - (D.LEG.e8 or 0)
end
L.MPUpdate = function()	local PerkMP = 0	for i, perk in ipairs(L.PERST[84]) do if P[perk] then PerkMP = PerkMP + 20 end end
	tes3.setStatistic{reference = p, name = "magicka", base = tes3.getEffectMagnitude{reference = p, effect = 84}*10
	+ mp.intelligence.base
	+ mp.willpower.base * (G.TR.tr23 and 0.5 or 0)
	+ PerkMP + (D.LEG.e84 or 0)}
	if PMP.normalized > 1 then PMP.current = PMP.base		M.Mana.current = PMP.current	M.Mana.max = PMP.current end
end
L.STUpdate = function() local PerkST = 0	for i, perk in ipairs(L.PERST[82]) do if P[perk] then PerkST = PerkST + 30 end end
	tes3.setStatistic{reference = p, name = "fatigue", base = tes3.getEffectMagnitude{reference = p, effect = 82}
	+ mp.endurance.base * (G.TR.tr21 and 2 or 1)
	+ mp.strength.base * (G.TR.tr22 and 2 or 1)
	+ mp.willpower.base * (G.TR.tr24 and 0 or 1)
	+ mp.agility.base * (G.TR.tr26 and 0 or 1)
	+ PerkST + (L.RST[p.object.race.id] or 0) + (D.LEG.e82 or 0)}
	if PST.normalized > 1 then PST.current = PST.base end
end
L.GetBaseStats = function() 
	G.BaseStats = {strength = mp.strength.base, endurance = mp.endurance.base, speed = mp.speed.base, agility = mp.agility.base, intelligence = mp.intelligence.base,
	willpower = mp.willpower.base, personality = mp.personality.base, luck = mp.luck.base}
	local msi, ei, name
	for _, aef in pairs(mp:getActiveMagicEffects{effect = 79}) do msi = aef.instance
		if msi.sourceType == 1 and msi.source.castType == 1 then ei = aef.effectInstance
			name = tes3.attributeName[aef.attributeId]
			G.BaseStats[name] = G.BaseStats[name] - ei.effectiveMagnitude
			--tes3.messageBox("%s - %s - %s   mag = %s   effmag = %s  Oldbase = %s  Base = %s", msi.source.name, name, aef.attributeId, ei.magnitude, ei.effectiveMagnitude, G.BaseStats[name], mp[name].base)
		end
	end
end

L.LegSelect = function()	local s = tes3.createObject{objectType = tes3.objectType.spell, id = "4nm_legend", castType = 1}	s.name = eng and "Legendary" or "Легендарность"	
local LEGT = {
--{d = eng and "Run speed" or "Скорость бега", c = 10, max = 20, lvl = 1, nolim = true, pic = "icons/k/attribute_speed.dds"},
{d = eng and "Health" or "Здоровье", c = 4, max = 50, lvl = 0.5, nolim = true, id = 80},
{d = eng and "Mana" or "Мана", c = 2, max = 100, lvl = 0.3, nolim = true, id = 84},
{d = eng and "Stamina" or "Стамина", c = 1, max = 200, lvl = 0.2, nolim = true, id = 82},
{d = eng and "Armor" or "Броня", c = 10, max = 20, lvl = 1, nolim = true, id = 3},
{d = eng and "Lightness" or "Легкость", c = 1, max = 100, lvl = 0.3, nolim = true, id = 8},
{d = eng and "Health regen" or "Регенерация здоровья", c = 100, max = 1, lvl = 30, id = 75},
{d = eng and "Stamina regen" or "Регенерация стамины", c = 10, max = 30, lvl = 1, id = 77},
{d = eng and "Mana regen" or "Регенерация маны", c = 100, max = 3, lvl = 10, id = 76},
{d = eng and "Charge regen" or "Регенерация зарядов", c = 100, max = 3, lvl = 10, id = 501},
{d = eng and "Attack bonus" or "Бонус атаки", c = 5, max = 50, lvl = 0.5, id = 117},
{d = eng and "Dodge bonus" or "Бонус уклонения", c = 5, max = 50, lvl = 0.5, id = 42},
{d = eng and "Jump" or "Прыжки", c = 10, max = 10, lvl = 3, id = 9},
{d = eng and "Dash" or "Дэш", c = 10, max = 5, lvl = 5, id = 600},
{d = eng and "Kinetic shield" or "Кинетический щит", c = 10, max = 5, lvl = 5, id = 508},
{d = eng and "Reflect magic" or "Отражение магии", c = 10, max = 10, lvl = 3, id = 507},
{d = eng and "Absorb spells" or "Поглощение заклинаний", c = 30, max = 10, lvl = 3, id = 67},
{d = eng and "Resist fire" or "Сопротивление огню", c = 5, max = 20, lvl = 1, id = 90},
{d = eng and "Resist frost" or "Сопротивление морозу", c = 5, max = 20, lvl = 1, id = 91},
{d = eng and "Resist lightning" or "Сопротивление молнии", c = 5, max = 20, lvl = 1, id = 92},
{d = eng and "Resist magic" or "Сопротивление магии", c = 5, max = 20, lvl = 1, id = 93},
{d = eng and "Resist poison" or "Сопротивление яду", c = 5, max = 20, lvl = 1, id = 97},
{d = eng and "Resist paralysis" or "Сопротивление параличу", c = 5, max = 20, lvl = 1, id = 99}}


local LEGQ = {C3_DestroyDagoth = {50,100}, TR_SothaSil = {100,50}, BM_WildHunt = {100,50}, HH_WinCamonna = {100,30}, HR_Archmaster = {100,30}, HT_Archmagister = {100,30},
TG_KillHardHeart = {100,30}, FG_KillHardHeart = {100,30}, MG_Guildmaster = {100,30}, IL_Grandmaster = {100,30}, TT_Assarnibibi = {100,30}, MT_Grandmaster = {100,30}, IC29_Crusher = {50,30}, CO_Estate = {50,30}}
local LVL = p.object.level		local LP = LVL * (G.TR.tr2 and 8 or 5) + p.object.reputation * 2
for id, t in pairs(LEGQ) do if tes3.getJournalIndex{id = id} >= t[1] then LP = LP + t[2] end end	

local M = {}	M.M = tes3ui.createMenu{id = "Leg_Menu", fixedFrame = true}	M.M.minHeight = 1200	M.M.minWidth = 800		local bl
M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.A.flowDirection = "top_to_bottom" 
M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
L.LegCalc = function() local bonus = 0		for i, t in ipairs(LEGT) do bonus = bonus + M[i].widget.current * t.c end	M.F.widget.current = bonus	end

for i, t in ipairs(LEGT) do bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl.borderAllSides = 1
	bl:createImage{path = t.id and "icons\\" .. tes3.getMagicEffect(t.id).bigIcon or t.pic}
	M[i] = bl:createSlider{max = math.min(math.floor(LVL/t.lvl), t.max), step = 1, jump = 1, current = D.LEG["e"..t.id] or 0}	M[i].width = 400	M[i].borderRight = 10	M[i].borderLeft = 10	M[i].borderTop = 5
	M[i]:register("PartScrollBar_changed", function() M[-i].text = M[i].widget.current .. "  " .. t.d	L.LegCalc() end)
	M[-i] = bl:createLabel{text = M[i].widget.current .. "  " .. t.d}
end
M.F = M.B:createFillBar{current = 0, max = math.min(LP, G.TR.tr2 and 500 or 400) + (G.TR.tr12 and 100 or 0) + (G.TR.tr6 and 200 or 0) + (G.TR.tr8 and 200 or 0)}
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
tes3ui.enterMenuMode("Leg_Menu")
end


L.ConTim = function() if PST.current < 5 then
	if D.ConSN then local si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.ConSN}	if si then si.state = 6 end		D.ConSN = nil end		T.CON:cancel()
end end

L.PotTim = function() 
	D.potcd = D.potcd - 1		M.TOX.current = D.potcd
	if D.potmcd then D.potmcd = D.potmcd - 1	
		if D.potmcd <= 0 then D.potmcd = nil		if M.TOX.normalized < 1 then M.TOX.fillColor = {0.5,1,0} end		end
	else
		if M.TOX.normalized < 1 then M.TOX.fillColor = {0.5,1,0} end
		if D.potcd <= 0 then D.potcd = nil	M.Bar5.visible = false		T.POT:cancel() end
	end
end


L.ConcSelect = function()	local Star = mp.birthsign.id	local r = p.object.race.id		local Lov = Star == "Mooncalf"
local CONT = {
{d = eng and "Slow time" or "Замедление времени", c = (P.sec05 and 0.4 or 0.5), max = (P.sec00 and 30 or 10) + (P.mark00 and 10 or 0) + (P.ill00 and 10 or 0), id = 510},
{d = eng and "Strength" or "Сила", c = (L.RCstr[r] or 0.5) - ((Lov or Star == "Warwyrd") and 0.1 or 0) - (P.str05 and 0.1 or 0), max = (P.str00 and 40 or 20) + (P.long00 and 10 or 0) + (P.axe00 and 10 or 0) + (P.blu00 and 10 or 0) + (P.spear00 and 10 or 0) + (P.hand00 and 10 or 0) + (P.hev00 and 10 or 0), id = 79, atr = 0},
{d = eng and "Endurance" or "Выносливость", c = (L.RCend[r] or 0.5) - ((Lov or Star == "Lady's Favor") and 0.1 or 0) - (P.end05 and 0.1 or 0), max = (P.end00 and 40 or 20) + (P.atl00 and 10 or 0) + (P.axe00 and 10 or 0) + (P.blu00 and 10 or 0) + (P.hev00 and 10 or 0) + (P.med00 and 10 or 0) + (P.bloc00 and 10 or 0), id = 79, atr = 5},
{d = eng and "Speed" or "Скорость", c = (L.RCspd[r] or 0.5) - ((Lov or Star == "Charioteer") and 0.1 or 0) - (P.spd05 and 0.1 or 0), max = (P.spd00 and 40 or 20) + (P.short00 and 10 or 0) + (P.hand00 and 10 or 0) + (P.long00 and 10 or 0) + (P.atl00 and 10 or 0) + (P.lig00 and 10 or 0) + (P.una00 and 10 or 0), id = 79, atr = 4},
{d = eng and "Agility" or "Ловкость", c = (L.RCagi[r] or 0.5) - ((Lov or Star == "Hara") and 0.1 or 0) - (P.agi05 and 0.1 or 0), max = (P.agi00 and 40 or 20) + (P.long00 and 10 or 0) + (P.short00 and 10 or 0) + (P.mark00 and 10 or 0) + (P.spear00 and 10 or 0) + (P.lig00 and 10 or 0) + (P.acr00 and 10 or 0), id = 79, atr = 3},
{d = eng and "Willpower" or "Воля", c = (L.RCwil[r] or 0.5) - ((Lov or Star == "Fay") and 0.1 or 0) - (P.wil05 and 0.1 or 0), max = (P.wil00 and 40 or 20) + (P.des00 and 10 or 0) + (P.res00 and 10 or 0) + (P.mys00 and 10 or 0) + (P.alt00 and 10 or 0) + (P.ill00 and 10 or 0) + (P.con00 and 10 or 0), id = 79, atr = 2},
{d = eng and "Intelligence" or "Интеллект", c = (L.RCint[r] or 0.5) - ((Lov or Star == "Elfborn") and 0.1 or 0) - (P.int05 and 0.1 or 0), max = (P.int00 and 40 or 20) + (P.des00 and 10 or 0) + (P.res00 and 10 or 0) + (P.mys00 and 10 or 0) + (P.alt00 and 10 or 0) + (P.ill00 and 10 or 0) + (P.con00 and 10 or 0), id = 79, atr = 1},
{d = eng and "Attack bonus" or "Бонус атаки", c = (L.RCat[r] or 0.5) - (L.SCat[Star] or 0), max = (P.agi00 and 30 or 20) + (P.long00 and 10 or 0) + (P.axe00 and 10 or 0) + (P.blu00 and 10 or 0) + (P.spear00 and 10 or 0) + (P.short00 and 10 or 0) + (P.mark00 and 10 or 0) + (P.hand00 and 10 or 0), id = 117},
{d = eng and "Dodge bonus" or "Бонус уклонения", c = (L.RCdod[r] or 0.5) - (L.SCdod[Star] or 0), max = (P.agi00 and 30 or 20) + (P.spd00 and 10 or 0) + (P.short00 and 10 or 0) + (P.hand00 and 10 or 0) + (P.lig00 and 10 or 0) + (P.una00 and 10 or 0) + (P.acr00 and 10 or 0) + (P.sec00 and 10 or 0), id = 42},
{d = eng and "Lightness" or "Легкость", c = (L.RClig[r] or 0.125) - (L.SClig[Star] or 0) - (P.atl05 and 0.025 or 0), max = (P.end00 and 150 or 100) + (P.str00 and 50 or 0) + (P.acr00 and 50 or 0) + (P.atl00 and 50 or 0) + (P.hev00 and 50 or 0) + (P.med00 and 50 or 0) + (P.lig00 and 50 or 0) + (P.alt00 and 50 or 0), id = 8},
{d = eng and "Jump" or "Прыжки", c = (L.RCjump[r] or 1.25) - (L.SCjump[Star] or 0) - (P.acr05 and 0.25 or 0), max = (P.agi00 and 10 or 5) + (P.acr00 and 10 or 0) + (P.alt00 and 10 or 0), id = 9},
{d = eng and "Armor" or "Броня", c = (P.bloc05 and 1 or 1.25) - (Star == "Trollkin" and 0.5 or 0), max = (P.end00 and 20 or 10) + (P.hev00 and 10 or 0) + (P.med00 and 10 or 0) + (P.bloc00 and 10 or 0), id = 3},
{d = eng and "Resist fire" or "Сопротивление огню", c = Star == "Star-Cursed" and 0.25 or 0.5, max = (P.end00 and 40 or 20) + (P.hev00 and 20 or 0) + (P.des00 and 20 or 0) + (P.bloc00 and 20 or 0), id = 90},
{d = eng and "Resist frost" or "Сопротивление морозу", c = Star == "Star-Cursed" and 0.25 or 0.5, max = (P.end00 and 40 or 20) + (P.hev00 and 20 or 0) + (P.des00 and 20 or 0) + (P.bloc00 and 20 or 0), id = 91},
{d = eng and "Resist lightning" or "Сопротивление молнии", c = Star == "Star-Cursed" and 0.25 or 0.5, max = (P.end00 and 40 or 20) + (P.hev00 and 20 or 0) + (P.des00 and 20 or 0) + (P.bloc00 and 20 or 0), id = 92},
{d = eng and "Resist magic" or "Сопротивление магии", c = Star == "Star-Cursed" and 0.25 or 0.5, max = (P.mys00 and 60 or 20) + (P.wil00 and 20 or 0) + (P.una00 and 20 or 0), id = 93},
{d = eng and "Resist poison" or "Сопротивление яду", c = Star == "Star-Cursed" and 0.25 or 0.5, max = (P.alc00 and 60 or 20) + (P.end00 and 20 or 0) + (P.res00 and 20 or 0), id = 97},
{d = eng and "Resist paralysis" or "Сопротивление параличу", c = Star == "Star-Cursed" and 0.25 or 0.5, max = (P.ill00 and 60 or 20) + (P.end00 and 20 or 0) + (P.wil00 and 20 or 0), id = 99},
{d = eng and "Health regen" or "Регенерация здоровья", c = (L.RChp[r] or 50) - (L.SChp[Star] or 0) - (P.res08 and 10 or 0), max = (P.end00 and 1 or 0) + (P.str00 and 1 or 0) + (P.wil00 and 1 or 0) + (P.res00 and 1 or 0) + (P.alc00 and 1 or 0), id = 75},
{d = eng and "Mana regen" or "Регенерация маны", c = (L.RCmp[r] or 50) - (L.SCmp[Star] or 0) - (P.mys08 and 10 or 0), max = (P.int00 and 1 or 0) + (P.wil00 and 1 or 0) + (P.enc00 and 1 or 0) + (P.mys00 and 1 or 0) + (P.una00 and 1 or 0), id = 76},
{d = eng and "Charge regen" or "Регенерация зарядов", c = 30 - (L.SCcharg[Star] or 0), max = (P.enc00 and 3 or 0) + (P.int00 and 1 or 0) + (P.wil00 and 1 or 0), id = 501},
{d = eng and "Kinetic shield" or "Кинетический щит", c = Star == "Beggar's Nose" and 1 or 2, max = P.alt00 and 20 or 0, id = 508},
{d = eng and "Reflect magic" or "Отражение магии", c = Star == "Beggar's Nose" and 1 or 2, max = P.mys00 and 20 or 0, id = 507},
{d = eng and "Dash" or "Дэш", c = 2, max = P.alt00 and 20 or 0, id = 600},
{d = eng and "Repair weapon" or "Починка оружия", c = 20, max = P.arm00 and 5 or 0, id = 502},
{d = eng and "Repair armor" or "Починка брони", c = 10, max = P.arm00 and 5 or 0, id = 503},
{d = eng and "Bound weapon" or "Призыв оружия", c = 20, max = P.con00 and 1 or 0, id = 603},
{d = eng and "Chameleon" or "Хамелеон", c = (Star == "Moonshadow Sign" and 1 or 2) - (P.snek05 and 0.5 or 0), max = (P.snek00 and 30 or 0) + (P.ill00 and 20 or 0), id = 40}}

local CurD = D.CON["d"..D.ConN]		local ET = {}		if CurD then for i, t in ipairs(CurD) do ET[t.id.."_"..t.attribute] = t.max end end

local M = {}	M.M = tes3ui.createMenu{id = "Conc_Menu", fixedFrame = true}	M.M.minHeight = 1200	M.M.minWidth = 800		local bl
M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.A.flowDirection = "top_to_bottom" 
M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
L.ConcCalc = function() local Stam = 0		for i, t in ipairs(CONT) do Stam = Stam + M[i].widget.current * t.c end		M.F.widget.current = Stam end

for i, t in ipairs(CONT) do bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl.borderAllSides = 1
	bl:createImage{path = t.atr and L.ATRIC[t.atr] or "icons\\" .. tes3.getMagicEffect(t.id).bigIcon}
	M[i] = bl:createSlider{label = t.d, max = t.max, step = 1, jump = 1, current = math.min(ET[t.id.."_"..(t.atr or -1)] or 0, t.max)}		M[i].width = 400	M[i].borderRight = 10	M[i].borderLeft = 10	M[i].borderTop = 5
	M[i]:register("PartScrollBar_changed", function() M[-i].text = M[i].widget.current .. "  " .. t.d	L.ConcCalc() end)
	M[-i] = bl:createLabel{text = M[i].widget.current .. "  " .. t.d}
end
M.F = M.B:createFillBar{current = 0, max = (G.TR.tr12 and 50 or 100) * (P.per15 and 2 or 1)}		M.F.width = 300		M.F.height = 24		M.F.borderRight = 20	M.F.widget.fillColor = {1,0,1}		L.ConcCalc()

for ind = 1, 8 do local dn = "d"..ind	local sn = "s"..ind		local DT = D.CON[dn]	local icnum = 1
	M[dn] = M.B:createImage{path = DT and L.GetIC(D.CON["ic"..ind]) or "icons\\k\\fatigue.dds"}		M[dn].borderRight = 20
	M[dn]:register("mouseClick", function()
		if MB[2] == 128 then
			local DT = D.CON[dn]		local ET = {}		if DT then for i, t in ipairs(DT) do ET[t.id.."_"..t.attribute] = t.max end end
			for i, t in ipairs(CONT) do M[i].widget.current = math.min(ET[t.id.."_"..(t.atr or -1)] or 0, t.max)		M[i]:triggerEvent("PartScrollBar_changed") end
		elseif MB[3] == 128 then
			local DT = D.CON[dn]
			if DT then icnum = icnum + 1		if icnum > #DT - 1 then icnum = 1 end
				D.CON["ic"..ind] = DT[icnum].attribute > -1 and L.ATRIC[DT[icnum].attribute] or "icons\\" .. tes3.getMagicEffect(DT[icnum].id).bigIcon
				M[dn].contentPath = D.CON["ic"..ind]		M.M:updateLayout()
			end
		else
			local StCur = M.F.widget.current
			if StCur > 0 then
				if M.F.widget.max >= StCur then		local num = 0	local cur		D.CON[dn] = {}		local DT = D.CON[dn]
					for i, t in ipairs(CONT) do cur = M[i].widget.current	if cur > 0 then num = num + 1		DT[num] = {id = t.id, attribute = t.atr or -1, min = cur, max = cur, duration = 3600} end end
					if num < 8 then
						DT[num + 1] = {id = 25, attribute = -1, min = StCur, max = StCur, duration = 3600}
						D.CON[sn] = StCur
						D.CON["ic"..ind] = DT[1].attribute > -1 and L.ATRIC[DT[1].attribute] or "icons\\" .. tes3.getMagicEffect(DT[1].id).bigIcon
						M[dn].contentPath = D.CON["ic"..ind]		M.M:updateLayout()
					else tes3.messageBox(eng and "You have selected too many bonuses of different types" or "Вы набрали слишком много бонусов разных типов")
						D.CON[sn] = nil		D.CON[dn] = nil		M[dn].contentPath = "icons\\k\\fatigue.dds"		M.M:updateLayout()
					end
				else tes3.messageBox(eng and "You have selected too many bonuses" or "Вы набрали слишком много бонусов") end
			else tes3.messageBox(eng and "You have not selected concentration bonuses. Slot cleared." or "Вы не выбрали бонусы для концентрации. Слот очищен.")
				D.CON[sn] = nil		D.CON[dn] = nil		M[dn].contentPath = "icons\\k\\fatigue.dds"		M.M:updateLayout()
			end
		end
	end)
	M[dn]:register("help", function()	local DT = D.CON[dn]
		local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt.flowDirection = "top_to_bottom"
		tt:createLabel{text = ("%s %s. %s. %s"):format(eng and "Click LMB to save current bonuses to Concentration slot" or "Нажмите ЛКМ чтобы сохранить текущие бонусы в слот Концентрации", ind,
		eng and "Click LMB while holding RMB to show the bonuses of this slot" or "Нажмите ЛКМ с зажатой ПКМ чтобы показать бонусы этого слота",
		eng and "Click LMB while holding MMB to change the icon" or "Нажмите ЛКМ с зажатой СКМ чтобы сменить иконку")}.borderBottom = 10
		if DT then for i, t in ipairs(DT) do	local me = tes3.getMagicEffect(t.id)
			local ttb = tt:createBlock{}	ttb.autoHeight = true	ttb.autoWidth = true
			ttb:createImage{path = t.attribute > -1 and L.ATRIC[t.attribute] or "icons\\" .. me.bigIcon}.borderRight = 10
			ttb:createLabel{text = ("%s"):format(t.max)}.borderRight = 10
			ttb:createLabel{text = ("%s %s"):format(me.name, t.attribute > -1 and tes3.attributeName[t.attribute] or "")}
		end end
	end)	
end
M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)
tes3ui.enterMenuMode("Conc_Menu")
end

L.FRACT = {["Redoran"] = true, ["Hlaalu"] = true, ["Telvanni"] = true, ["Thieves Guild"] = true, ["Fighters Guild"] = true, ["Mages Guild"] = true,
["Imperial Cult"] = true, ["Temple"] = true, ["Imperial Legion"] = true, ["Morag Tong"] = true,
["Clan Quarra"] = true, ["Clan Aundae"] = true, ["Clan Berne"] = true, ["East Empire Company"] = true,
["T_Mw_MagesGuild"] = true, ["T_Mw_FightersGuild"] = true, ["T_Mw_ThievesGuild"] = true,
["T_Mw_HouseDres"] = true, ["T_Mw_HouseHlaalu"] = true, ["T_Mw_HouseIndoril"] = true, ["T_Mw_HouseRedoran"] = true, ["T_Mw_HouseTelvanni"] = true,
["T_Mw_ImperialLegion"] = true, ["T_Mw_ImperialCult"] = true, ["T_Mw_Temple"] = true, ["T_Mw_MoragTong"] = true, ["T_Mw_EastEmpireCompany"] = true,
["T_Cyr_FightersGuild"] = true, ["T_Cyr_ThievesGuild"] = true, ["T_Cyr_MagesGuild"] = true, ["T_Cyr_ImperialLegion"] = true, ["T_Cyr_ImperialCult"] = true, ["T_Cyr_DarkBrotherhood"] = true,
["T_Sky_FightersGuild"] = true, ["T_Sky_MagesGuild"] = true, ["T_Sky_ThievesGuild"] = true}

L.QUSTS = {C3_DestroyDagoth = {50,10}, TR_SothaSil = {100,10}, BM_WildHunt = {100,10}, CX_BackPath = {50,5},
DA_Azura = {30,2}, DA_Boethiah = {70,2}, DA_Malacath = {70,2}, DA_Mehrunes = {40,2}, DA_Mephala = {60,2}, DA_MolagBal = {30,2}, DA_Sheogorath = {70,2}, MS_VampireCure = {50,2},
town_balmora = {30,1}, town_Vivec = {50,1}, MS_Umbra = {60,1}, MV_CultistVictim = {100,1}, MV_DeadTaxman = {100,1}, MV_LostRing = {40,1}, Romance_Ahnassi = {90,1},
-- = {100,1}, = {100,1}, = {100,1}, = {100,1}, = {100,1}, = {100,1}, = {100,1}, = {100,1}, = {100,1},
MS_CrimsonPlague = {170,2}, MS_BarbarianBook = {200,1}, MS_BattleBots2 = {20,1}, MS_BlackDart = {100,1}, MS_Natural = {40,1}, MS_Performers = {120,1}, MS_ScrollSales = {100,1}, MS_Summoner = {30,1}, MS_Thief = {90,1}, MS_Warlords_a = {50,1},
BM_Airship = {100,1}, BM_BrodirGrove = {100,1}, BM_Ingmar = {100,1}, BM_Falmer = {100,1}, BM_MeadHall = {100,1}, BM_Missionary = {110,1}, BM_SadSeer = {100,1}, BM_Tymvaul = {100,1}, BM_WolfGiver = {120,1}}
L.KillCount = {["dagoth araynys"] = 2, ["dagoth endus"] = 2, ["dagoth gilvoth"] = 2, ["dagoth odros"] = 2, ["dagoth tureynul"] = 2, ["dagoth uthol"] = 2, ["dagoth vemyn"] = 2}

L.TrLimCalc = function()
	G.Rep = math.ceil(p.object.reputation/2)	G.Rang = 0		G.Quest = 0		G.KillBon = 0		local base = G.TR.tr1 and 35 or 25			--p.object.factionIndex	
	local Spec = p.object.class.specialization
	for _, fract in pairs(tes3.dataHandler.nonDynamicData.factions) do G.Rang = G.Rang + fract.playerRank + 1 end
	for id, bon in pairs(L.KillCount) do if tes3.getKillCount{actor = id} ~= 0 then G.KillBon = G.KillBon + bon end end
	for id, t in pairs(L.QUSTS) do if tes3.getJournalIndex{id = id} >= t[1] then G.Quest = G.Quest + t[2] end end
	local Summ = G.Rep + G.Rang + G.Quest + G.KillBon + base
	for s, num in pairs(tes3.skill) do G.SkLim[num] = Summ + (L.SS[num] == Spec and 10 or 0) + (D.SkillTr[s] or 0) end
	for _, bon in pairs(p.object.race.skillBonuses) do G.SkLim[bon.skill] = G.SkLim[bon.skill] + bon.bonus end
	for _, s in pairs(p.object.class.majorSkills) do G.SkLim[s] = G.SkLim[s] + 25 end
	for _, s in pairs(p.object.class.minorSkills) do G.SkLim[s] = G.SkLim[s] + 10 end	
	for s, num in pairs(tes3.skill) do if mp[s].base < G.SkLim[num] then G.SkBurn[num] = nil else G.SkBurn[num] = true end end
end


L.TrainMenu = function()		local bl, tab
	local M = {}	M.M = tes3ui.createMenu{id = "Train_Menu", fixedFrame = true}	M.M.minHeight = 1200	M.M.minWidth = 800
	M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.A.flowDirection = "top_to_bottom" 
	M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
	M.A:createLabel{text = eng and "Limits to your skill growth for self training" or "Пределы роста ваших навыков для самостоятельных тренировок"}
	M.A:createLabel{text = eng and "Reputation bonus: " or "Бонус за репутацию: " .. G.Rep}
	M.A:createLabel{text = eng and "Faction rank bonus: " or "Бонус за ранги во фракциях: " .. G.Rang}
	M.A:createLabel{text = eng and "Legendary enemy victory bonus: " or "Бонус за победы над легендарными врагами: " .. G.KillBon}
	M.A:createLabel{text = eng and "Dangerous quest bonus: " or "Бонус за опасные квесты: " .. G.Quest}.borderBottom = 10
	for i = 9, 35 do tab = L.PRL[i]
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl.borderAllSides = 1
		bl:createImage{path = tab[2]}.borderRight = 20
		bl:createLabel{text = G.SkLim[tab[3]] .. "  " .. tes3.skillName[tab[3]]}
	end
	M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close.borderRight = 30
	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)
	M.B:createLabel{text = eng and "Lessons taken from trainers: " or "Взято уроков у учителей: " .. D.L.les .. "/" .. p.object.level * G.leskoef}
	tes3ui.enterMenuMode("Train_Menu")
end

L.ShowStatMenu = function() if P.int4 then
	local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {p}}	local r = hit and hit.reference		local m = r and r.mobile
	if m then	local ob = r.object		local bob = r.baseObject	local At = bob.attributes	local mt = L.CRNIF[ob.mesh:lower()]		local cs = m.combatSession		local bl, lab, tab, mod
		local M = {}	M.M = tes3ui.createMenu{id = "Stat_Menu", fixedFrame = true}	M.M.minHeight = 1200	M.M.minWidth = 500
		M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.A.flowDirection = "top_to_bottom" 
		
		M.A:createLabel{text = ("%s (%s)  %s %s"):format(bob.name, bob.level, bob.modified and "Mod" or "", bob.autoCalc and "Auto" or "")}.borderBottom = 10
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Health"}.minWidth = 120			bl:createLabel{text = ("%d / %d / %d"):format(m.health.current, m.health.base, bob.health)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Mana"}.minWidth = 120			bl:createLabel{text = ("%d / %d / %d"):format(m.magicka.current, m.magicka.base, bob.magicka)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Stamina"}.minWidth = 120			bl:createLabel{text = ("%d / %d / %d"):format(m.fatigue.current, m.fatigue.base, bob.fatigue)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Encumbrance"}.minWidth = 120		bl:createLabel{text = ("%d / %d (%d%%)"):format(m.encumbrance.current, m.encumbrance.base, m.encumbrance.normalized*100)}.borderBottom = 10
		
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Strength"}.minWidth = 120		bl:createLabel{text = ("%d / %d / %d"):format(m.strength.current, m.strength.base, At[tes3.attribute.strength+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Endurance"}.minWidth = 120		bl:createLabel{text = ("%d / %d / %d"):format(m.endurance.current, m.endurance.base, At[tes3.attribute.endurance+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Willpower"}.minWidth = 120		bl:createLabel{text = ("%d / %d / %d"):format(m.willpower.current, m.willpower.base, At[tes3.attribute.willpower+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Intelligence"}.minWidth = 120	bl:createLabel{text = ("%d / %d / %d"):format(m.intelligence.current, m.intelligence.base, At[tes3.attribute.intelligence+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Agility"}.minWidth = 120			bl:createLabel{text = ("%d / %d / %d"):format(m.agility.current, m.agility.base, At[tes3.attribute.agility+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Speed"}.minWidth = 120			bl:createLabel{text = ("%d / %d / %d"):format(m.speed.current, m.speed.base, At[tes3.attribute.speed+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Personality"}.minWidth = 120		bl:createLabel{text = ("%d / %d / %d"):format(m.personality.current, m.personality.base, At[tes3.attribute.personality+1])}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Luck"}.minWidth = 120			bl:createLabel{text = ("%d / %d / %d"):format(m.luck.current, m.luck.base, At[tes3.attribute.luck+1])}.borderBottom = 10
		
		if m.actorType == 0 then
			if not bob.biped and not bob.usesEquipment then
				bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Damage"}.minWidth = 120		bl:createLabel{text = ("%d"):format(bob.attacks[1].max)}
			end
			bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true			bl:createLabel{text = "Combat"}.minWidth = 120		bl:createLabel{text = ("%d / %d"):format(m.combat.base, bob.skills[1])}
			bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true			bl:createLabel{text = "Magic"}.minWidth = 120		bl:createLabel{text = ("%d / %d"):format(m.magic.base, bob.skills[2])}
			bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true			bl:createLabel{text = "Stealth"}.minWidth = 120		bl:createLabel{text = ("%d / %d"):format(m.stealth.base, bob.skills[3])}.borderBottom = 10
		--	bl.borderBottom = 10
			--for i = 9, 35 do tab = L.PRL[i] end
		end
	
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Fight"}.minWidth = 120		bl:createLabel{text = ("%d / %d"):format(m.fight, bob.aiConfig.fight)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Flee"}.minWidth = 120		bl:createLabel{text = ("%d / %d"):format(m.flee, bob.aiConfig.flee)}.borderBottom = 10

		local Arm = m.armorRating	local rsh = m.readiedShield		local Normres = m.resistNormalWeapons
		local ElRes = math.min(m:getSkillValue(10),100)/10 + math.min(m.endurance.current,500)/5 + math.min(m.willpower.current,500)/5 + (rsh and m:getSkillValue(0) * 0.4 or 0) + Arm/5
		local ResFire = math.max(m.resistFire,-100) + ElRes		local ResFrost = math.max(m.resistFrost,-100) + ElRes		local ResShock = math.max(m.resistShock,-100) + ElRes
		local ResMag = math.max(m.resistMagicka,-100) + math.min(m:getSkillValue(14),100)/10 + math.min(m.endurance.current,500)/10 + math.min(m.willpower.current,500)*0.3
		local ResPoison = math.max(m.resistPoison,-100) + math.min(m:getSkillValue(16),100)/10 + math.min(m.endurance.current,500)*0.3 + math.min(m.willpower.current,500)/10
		local ResParal = ResMag + m.resistParalysis
		if Normres < 0 then Arm = Arm + math.max(Normres,-100) end
		
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Armor rating "}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)  %d base"):format(Arm > 0 and 100*Arm/(Arm + 100) or Arm, Arm, mt and mt.ar or m.endurance.current/10 + ob.level/2)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist fire"}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)"):format(ResFire < 0 and ResFire or (ResFire < 500 and 100*ResFire/(ResFire + 100) or 100), ResFire)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist frost"}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)"):format(ResFrost < 0 and ResFrost or (ResFrost < 500 and 100*ResFrost/(ResFrost + 100) or 100), ResFrost)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist shock"}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)"):format(ResShock < 0 and ResShock or (ResShock < 500 and 100*ResShock/(ResShock + 100) or 100), ResShock)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist magick"}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)"):format(ResMag < 0 and ResMag or (ResMag < 500 and 100*ResMag/(ResMag + 100) or 100), ResMag)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist poison"}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)"):format(ResPoison < 0 and ResPoison or (ResPoison < 500 and 100*ResPoison/(ResPoison + 100) or 100), ResPoison)}
		bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist paralysis"}.minWidth = 200
		bl:createLabel{text = ("%d%% (%d)"):format(ResParal < 0 and ResParal or (ResParal < 500 and 100*ResParal/(ResParal + 100) or 100), ResParal)}.borderBottom = 10
	--	bl = M.A:createBlock{}	bl.autoHeight = true	bl.autoWidth = true		bl:createLabel{text = "Resist norm weapon"}.minWidth = 200	bl:createLabel{text = ("%d%%"):format(m.resistNormalWeapons)}.borderBottom = 10
		
		M.A:createLabel{text = "Spell list:"}
		for _, sp in pairs(cs and cs.castableSpells or ob.spells) do if sp.castType == 0 then mod = sp.sourceMod	
			M.A:createLabel{text = ("%s (%d) %s %s"):format(sp.name, sp.magickaCost, sp.autoCalc and "Auto" or "", L.ESP[mod] and "" or mod)}:register("help", function() tes3ui.createTooltipMenu{spell = sp} end)
		end end
		
		M.close = M.A:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	--M.close.borderRight = 30
		M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)
		tes3ui.enterMenuMode("Stat_Menu")
	end
end end

L.PerkReset = function() local max = math.floor(p.object.level/5) 
	if (D.PerkRes or 0) < max then	D.PerkRes = (D.PerkRes or 0) + 1
		if ic:isAltDown() then
			local trskill = G.TR.tr1
			local leg = tes3.getObject("4nm_legend")	if leg then tes3.removeSpell{reference = p, spell = leg} end
			for stat, num in pairs(D.STB) do if num > 0 then tes3.modStatistic{reference = p, name = stat, value = -10 * num}		D.STB[stat] = 0 end end
			D.traits = {} 	G.TR = D.traits		if trskill then G.TR.tr1 = true end
			L.GetArmT()		L.GetWstat()	L.HPUpdate()	L.SetGlobal()
		else
			for id, _ in pairs(L.PA) do tes3.removeSpell{reference = p, spell = "4p_"..id, updateGUI = false} end
			for id, _ in pairs(L.AA) do tes3.removeSpell{reference = p, spell = id, updateGUI = false} end
			for id, lvl in pairs(L.ElemSpLVL) do tes3.removeSpell{reference = p, spell = id, updateGUI = false} end
			tes3.updateMagicGUI{reference = p, updateEnchantments = false}
			D.perks = {}	 P = D.perks		DM.cp = nil		L.GetArmT()		L.GetWstat()	L.HPUpdate()	L.SetGlobal()
			for i = 1, 8 do D.CON["s"..i] = nil end
		end
		tes3.messageBox(eng and "Used %d/%d perk reset. You get 1 reset every 5 levels" or "Использовано %d/%d сбросов перков. Вы получаете 1 возможность сброса за каждые 5 уровней", D.PerkRes, max)
	else tes3.messageBox(eng and "Not enough resets! Used %d/%d perk reset. You get 1 reset every 5 levels" or "Недостаточно сбросов! Использовано %d/%d сбросов перков. Вы получаете 1 возможность сброса за каждые 5 уровней", D.PerkRes, max) end
end

L.PerkSpells = function()
	for id, t in pairs(L.PA) do if P[t[3]] then tes3.addSpell{reference = p, spell = "4p_"..id, updateGUI = false} end end
	for id, perk in pairs(L.AA) do if P[perk] then tes3.addSpell{reference = p, spell = id, updateGUI = false} end end
	if P.des05 then local Lvl = p.object.level		for id, lvl in pairs(L.ElemSpLVL) do if Lvl >= lvl then tes3.addSpell{reference = p, spell = id, updateGUI = false} end end end
	tes3.updateMagicGUI{reference = p, updateEnchantments = false}
end

L.EUPD = function(r, id) timer.delayOneFrame(function() local mag = tes3.getEffectMagnitude{reference = r, effect = id} 	r.data["e"..id] = mag > 0 and mag or nil
--tes3.messageBox("%s  id = %s  mag = %s", r, id, r.data["e"..id])
end) end
L.RSound = function(d) if not L.FIL[d] then L.FIL[d] = {}	for file in lfs.dir("data files\\sound\\4NM\\" .. d) do if file:endswith("wav") then table.insert(L.FIL[d], file) end end	end	return ("4NM\\%s\\%s"):format(d, TC(L.FIL[d])) end
L.GetMat = function(hit)	local tex = hit.object.texturingProperty	tex = tex and tex.maps[1].texture.fileName		
	if tex then		local result = L.TCash[tex]
		if not result then result = tex:lower():gsub("/", "\\")
			if result:find("^textures\\") then result = result:sub(10, -5) elseif result:find("^data files\\textures\\") then result = result:sub(21, -5) else result = result:sub(1, -5) end
			L.TCash[tex] = result
		end
		local Mat = L.TD[result]
		
		if not Mat then local r = hit.reference
			if r then	local meshl = r.object.mesh:lower()
				if meshl:find("flora") then Mat = meshl:find("tree") and "Wood" or "Dirt" 
				else Mat = "Stone" end
			else Mat = "Dirt" end
			L.TD[result] = Mat
		end
		return Mat
	end
end
L.KEY = function(k) if k < 8 then return ic:isMouseButtonDown(k) else return ic:isKeyDown(k) end end
L.GetWW = function(w,m) local ww = math.min(w.weight, 50)		if ww == 0 then ww = w.enchantCapacity/10 * ((m ~= mp or P.con20) and 0.5 or 0.6) * (m == mp and P.con19 and D.BWwgt and 1.5 or 1) end	return ww end
L.GetRad = function(m) return (50 + math.min(m.willpower.current,100)/2 + m:getSkillValue(11))/((m ~= mp or P.alt13) and 20 or 40) end
L.GetMetRetSpd = function() G.MetRetSpd = (200 + mp:getSkillValue(11) + mp.willpower.current) * (P.alt19 and 10 or 5) end


L.GetIC = function(pat,mag) return tes3.getFileExists(pat) and pat end	--or (mag and "icons\\k\\magicka.dds" or "icons\\k\\fatigue.dds")
L.LIRcol = function(x) local col = TC{{math.random(x,255),x,255}, {math.random(x,255),255,x}, {x,math.random(x,255),255}, {255,math.random(x,255),x}, {x,255,math.random(x,255)}, {255,x,math.random(x,255)}}
L.MagLig.color[1] = col[1]		L.MagLig.color[2] = col[2]		L.MagLig.color[3] = col[3] end
L.GetPCmax = function() return (100 + mp.willpower.base + mp.enchant.base * (P.enc6 and 2 or 1)) * (1 - math.min(D.ENconst/D.ENconMax,1)*(P.enc15 and 0.75 or 0.85)) * (G.TR.tr6 and 0.5 or 1) end
L.CrimeAt = function(m) if not m.inCombat and tes3.getCurrentAIPackageId(m) ~= 3 then tes3.triggerCrime{type = 1, victim = m}	m:startCombat(mp)	mp:startCombat(m)	m.actionData.aiBehaviorState = 3 end end
L.NoBorder = function(el, x) el.contentPath = "meshes\\menu_thin_border_0.nif"	if not x then el:findChild("PartFillbar_colorbar_ptr").borderAllSides = 0 end end
L.BarText = function(el) el = el:findChild("PartFillbar_text_ptr") 	el.absolutePosAlignY = 0.6		el.color = {1,1,1} end
L.DmgInd = function(DMG, NewHP, BaseHP, Krit) M.EDB.current = NewHP		M.EDB.max = BaseHP	local n = NewHP/BaseHP	M.EDB.fillColor = {2-n*2, n*2, 0}	M.EDT.text = ("%d%s"):format(DMG, Krit and "!" or "")	M.EDBL.visible = true	T.EDMG:reset() end
L.ParInd = function(imp, col) M.EDB.current = 1		M.EDB.max = 1		M.EDB.fillColor = L.CLR[col]	M.EDT.text = ("%d"):format(imp)		M.EDBL.visible = true		T.EDMG:reset() end
L.Friends = function(mob) local tab = {}
	for m in tes3.iterate(mob.friendlyActors) do if m ~= mob then	-- сам актер всегда входит в таблицу своих друзей, призыватель является другом призванного, призванный является другом призывателя
		tab[m.reference] = m
	end end
	return tab
end
L.IsFollover = function(mob,master) return tes3.getCurrentAIPackageId(mob) == 3 and mob.aiPlanner:getActivePackage().targetActor == master end

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
	if string.len(id) < 31 and not id:find("wand") then
		New = tes3.createObject{objectType = tes3.objectType.weapon, id = "*" .. id, type = L.AltW[o.type]}		--'id' parameter must be less than 32 character long.
		New.name = o.name	New.mesh = o.mesh	New.icon = o.icon	New.enchantment = o.enchantment		New.weight = o.weight		New.value = o.value		New.maxCondition = o.maxCondition
		New.flags = o.flags		New.ignoresNormalWeaponResistance = o.ignoresNormalWeaponResistance		New.isSilver = o.isSilver		New.reach = o.reach		New.enchantCapacity = o.enchantCapacity
		New.speed = o.speed		New.chopMin = o.chopMin		New.chopMax = o.chopMax		New.slashMin = o.slashMin	New.slashMax = o.slashMax	New.thrustMin = o.thrustMin		New.thrustMax = o.thrustMax
	end
	--newWeapon = tes3.getObject("imperial broadsword"):createCopy{}		newWeapon.enchantment = tes3.getObject("flame_enu")			tes3.addItem{ reference = tes3.player, item = newWeapon }
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

L.UprPPos = function(rpos,spd,reset)	local newpos
	if not G.pcent or reset then
		if not mp.canMove then G.PspdR = 0 end
		G.pcent = pp + G.mph07
		G.PvelZ = mp.velocity.z
	end

	if G.PspdR > 0 then
		if G.dfr then G.PspdR = G.Pspd end
	--	local a = spd/G.PspdR
		local A = (spd/G.PspdR)^2
		local AB = rpos - G.pcent
		local b = AB:length()
		local c = math.cos(G.Pvec:angle(AB))
	--	local C = 2*b*c		-- local B = b^2
		
		local x = --A > 1 and 
		((b^2*(A + c^2 - 1))^0.5 - b*c) / (A-1)		--or ((b^2*(A + c^2 - 1))^0.5 + b*c) / (1-A)
		
		if x > 0 then
			newpos = G.pcent + G.Pvec * x
			if G.PvelZ ~= 0 then newpos.z = math.lerp(G.pcent.z, newpos.z, 0.25) end
		end
		
	--	tes3.messageBox("A = %.3f   Cos = %.3f   Dist = %d    Z = %d -> %d", A, c, x, G.pcent.z, newpos and newpos.z)
	end
	--	A*x^2 = B + x^2 - 2*b*x*c
	--	B + x^2 - C*x - A*x^2 = 0
	return newpos or G.pcent
end

--L.GetArr = function() local tab = {}	for r, _ in pairs(AF) do table.insert(tab, r) end	return tab end
L.TPComp = function() if D.NoTPComp then return false else		local num = 0		local cost = 0		G.TPList = {}
	for m in tes3.iterate(mp.friendlyActors) do if m ~= mp and tes3.getCurrentAIPackageId(m) == 3 then num = num + 1
		cost = cost + (m.reference.data.SumM and 10 or 20)	G.TPList[m.reference] = true		--tes3.messageBox("Name = %s  num = %s  cost = %d", m.object.name, num, cost)
	end end
	if not P.mys22 then cost = cost * 3 end		
	if num > 0 then
		if PMP.current >= cost then Mod(cost)	tes3.messageBox("Companions = %s  manacost = %d", num, cost) return true
		else tes3.messageBox("Not enough mana! Companions = %s  manacost = %d", num, cost)	return false end
	else return false end
end end
L.TownTP = function(e) --if not e:trigger() then return end		
	if e.effectInstance.target == p and e.effectInstance.resistedPercent < 50 and not wc.flagTeleportingDisabled then -- Телепорт в город (505) 32 максимум, 22 щас
	tes3.messageBox{message = "Where to go?", buttons = {"Nothing", "Balmora", "Ald-ruhn", "Vivec", "Sadrith Mora", "Ebonheart", "Caldera", "Suran", "Gnisis",
	"Pelagiad", "Tel Branora", "Tel Aruhn", "Tel Mora", "Maar Gan", "Molag Mar", "Dagon Fel", "Seyda Neen", "Hla Oad", "Gnaar Mok", "Khuul", "Ald Velothi", "Vos", "Tel Vos"},
	callback = function(e) if e.button ~= 0 then
		if L.TPComp() then timer.start{duration = 0.2, callback = function() for r, _ in pairs (G.TPList) do tes3.positionCell{reference = r, position = pp, cell = p.cell} end end} end
		tes3.positionCell{reference = p, teleportCompanions = false, position = L.TPP[e.button], cell = tes3.getCell{x = 0, y = 0}}
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
			if dd < dd1 and tes3.testLineOfSight{reference1 = p, reference2 = r} and not L.IsFollover(tab.m, mp) then ref = r	dd1 = dd	d1 = d end
		end
	end		--if ref then tes3.messageBox("%s  Dist = %d   Dif = %d", ref, d1, dd1) end
	return ref, d1
end
L.SectorDod = function() if cf.pvpproj > 0 and not T.Dom.timeLeft then		T.Dom = timer.start{duration = 0.3, callback = function() end}
	for r, t in pairs(R) do
		if not L.ASN[t.m.actionData.animationAttackState] and not t.m.isFalling and not t.m.isHitStunned then	local ang = mp:getViewToActor(t.m)		
			if math.abs(ang) < 15 and math.abs(t.m:getViewToActor(mp)) < 45 then	local ch = t.m.agility.current + t.m.sanctuary		
				if ch > math.random(100) then
					local spd = math.min(((t.m.isMovingForward and 200 or 100) + ch + t.m.speed.current*2) * (1 - math.min(t.m.encumbrance.normalized,1)*0.75) * (0.5 + t.m.fatigue.normalized/2), 500) * cf.pvpproj
					if cf.pvpprdod then
						DOM[t.m] = {v = r.rightDirection * ((ang > 0 and -1 or 1) * spd), fr = 0.4}
					else
						local vec = r.rightDirection * (ang > 0 and -1 or 1) + V.up2	if t.m.isMovingForward then vec = vec + r.forwardDirection end
						t.m:doJump{velocity = vec * spd, applyFatigueCost = false}
					end
					--tes3.messageBox("Dodge %s   %d%%   spd = %d   fov = %s   Ang = %d", r, ch, spd, t.m.isMovingForward, ang)
				end
			end
		end
	end
end end

L.DodM = function(r,m,pos) if not L.ASN[m.actionData.animationAttackState] and not m.isFalling and not m.isHitStunned then		local spd		local ch = m.agility.current + m.sanctuary		local rand = math.random(100)
	if ch > rand then spd = 1 elseif ch*2 > rand then spd = 0.5 end
	if spd then
		spd = math.min((200 + ch + m.speed.current*2) * (1 - math.min(m.encumbrance.normalized,1)*0.75) * (0.5 + m.fatigue.normalized/2), 500) * cf.pvpspd * spd			--local rot = r.sceneNode.rotation:transpose()
		local w = m.readiedWeapon		local rng = 20 + 130 * (w and w.object.reach or 0.7)
		DOM[m] = {v = (pos + r.rightDirection * TC{rng,-rng} - r.position):normalized() * spd, fr = 0.4}
		
		--DOM[m] = {v = (r.rightDirection * TC{1,-1} + r.forwardDirection):normalized() * spd, fr = 0.4}		--local vec = (pos + (p.rightDirection * TC{rng,-rng}) - r.position):normalized()
		--tes3.messageBox("Dodge %s   %d%%   spd = %d", r, ch, spd)
	end
end end

L.CF.atr = function(m,r) local d = r.data.spawn	if d ~= 0 and m.health.normalized < d/10 - 0.2 then	local id = r.baseObject.id
	B.elemaura.effects[1].id = L.atrbot[id][1]	B.elemaura.effects[1].min = d*2	B.elemaura.effects[1].max = d*3
	tes3.applyMagicSource{reference = r, source = B.elemaura}	r.data.spawn = 0
end end
L.CF.dremoralord = function(m,r) if r.data.spawn + 5 > math.random(100) then
	tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = TC{105,105,105,140}, duration = 30}}}
end end
L.CF.atrlord = function(m,r) local d = r.data.spawn + 10		local id = r.baseObject.id
	if d > 10 and m.health.normalized < d/20 then	
		B.elemaura.effects[1].id = L.atrbot[id][1]	B.elemaura.effects[1].min = d*2	B.elemaura.effects[1].max = d*3
		tes3.applyMagicSource{reference = r, source = B.elemaura}	r.data.spawn = 0
	end
	if d/2 > math.random(100) then tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = L.atrbot[id][2], duration = 30}}} end
end
L.CF.auril = function(m,r) local d = r.data.spawn	if d ~= 0 and m.health.normalized < 0.75 then
	if d > 8 then B.goldaura.effects[1].id = 4 elseif d < 3 then B.goldaura.effects[1].id = 6 elseif d == 3 or d == 4 then B.goldaura.effects[1].id = 5 elseif d == 5 or d == 6 then B.goldaura.effects[1].id = 3 end
	tes3.applyMagicSource{reference = r, source = B.goldaura}	r.data.spawn = 0
end end
L.CF.lichelder = function(m,r) local ch = math.random(10 - r.data.spawn*0.5)
	if ch == 1 then for ref in tes3.iterate(r.cell.actors) do if ref.object.objectType == tes3.objectType.creature and ref.object.type == 2 and ref.mobile.isDead and r.position:distance(ref.position) < 1000 then
		if 100 - ref.object.level * 5 > math.random(100) then ref.mobile:resurrect{resetState = false}	tes3.playSound{sound = "conjuration hit", reference = ref} end end end
	elseif ch == 2 then for ref in tes3.iterate(r.cell.actors) do if ref.object.objectType == tes3.objectType.creature and ref.object.type == 2 and r.position:distance(ref.position) < 1000 then
		tes3.applyMagicSource{reference = ref, source = "p_restore_health_s"} end end
	elseif ch == 3 then tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = TC{108,108,142,142,109,110}, duration = 30}}} end
end
L.CF.lich = function(m,r) local ch = math.random(10 - r.data.spawn*0.3)
	if ch == 1 then
		tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = TC{106,107,107,142,109,108}, duration = 30}}}
		--tes3.createReference{object = L.UndMinion[math.random(4)], position = (r.position + r.orientation*300), cell = r.cell}		tes3.playSound{sound = "conjuration hit", reference = r}
	elseif ch == 2 then tes3.applyMagicSource{reference = r, source = "p_restore_health_c"}
end end
L.CF.lichuni = function(m,r) if math.random(5) == 1 then
	tes3.applyMagicSource{reference = r, name = "Summon", effects = {{id = TC{107,107,142,142,108,108,110}, duration = 30}}}
end end
L.CF.ashascend = function(m,r) if r.position:distance(pp) < 1000 and not mwscript.getSpellEffects{reference = p, spell = "corprus immunity"} then local ch = math.random(6)
	if ch < 5 then mwscript.addSpell{reference = p, spell = L.Blight[ch]}
	tes3.messageBox(eng and "The blight aura emitted by this creature has hit you!" or "Вас поразила моровая аура, источаемая этим существом!") end
end end
L.CF.ashvamp = function(m,r)	local ch = math.random(10)	local SpO
	for r, mob in pairs(G.TimRef) do if not mob.activeAI and mob.isDead then tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = r.position}		G.TimRef[r] = nil	r:delete() end end
	if ch == 1 then SpO = TC{"ash_slave", "ash_zombie", "ash_zombie_warrior", "ash_ghoul", "ash_revenant"}
	elseif ch == 2 then SpO = TC{"ash_slave", "ash_zombie", "ash_zombie_warrior", "corprus_lame", "corprus_stalker"}
	elseif ch == 3 then SpO = "ash_slave" end
	if SpO then local ref = mwscript.placeAtPC{object = SpO, distance = 500, direction = math.random(0,3)}	local mob = ref.mobile	G.TimRef[ref] = mob		ref.data.SumM = "Dagot"		mob.fight = 100		mob:startCombat(mp)	
	tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = ref.position}	tes3.playSound{sound = "conjuration hit", reference = ref} end
end
L.CF.urdagot = function(m,r)	local ch = math.random(10)	local SpO	r.data.UrTim = (r.data.UrTim or 0) + 1 	--tes3.getJournalIndex{id = "C3_DestroyDagoth"} < 20 
	local dist = r.position:distance(pp)			--tes3.messageBox("Dist %d   Tim %d", dist, r.data.UrTim)
	if dist > 5000 or (r.data.UrTim > 9 and dist > 2000) then	r.data.UrTim = 0
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = p.forwardDirection, maxDistance = 500, ignore={p}}
		r.position = hit and hit.intersection or tes3.getPlayerEyePosition() + p.forwardDirection * 500
		tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = r.position}	tes3.playSound{sound = "conjuration hit", reference = r}
	end
	for r, mob in pairs(G.TimRef) do if not mob.activeAI and mob.isDead then tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = r.position}		G.TimRef[r] = nil	r:delete() end end
	if ch == 1 then SpO = TC{"ash_ghoul", "ash_ghoul", "ash_ghoul_warrior", "ash_ghoul_warrior", "ash_ghoul_high", "ascended_sleeper"}
	elseif ch == 2 then SpO = TC{"ash_slave", "ash_zombie", "ash_zombie_warrior", "corprus_lame", "corprus_stalker", "ash_ghoul", "ash_revenant"}
	elseif ch == 3 then SpO = "ash_slave" end
	if SpO then local ref = mwscript.placeAtPC{object = SpO, distance = 500, direction = math.random(0,3)}	local mob = ref.mobile	G.TimRef[ref] = mob		ref.data.SumM = "Dagot"		mob.fight = 100		mob:startCombat(mp)	
	tes3.createVisualEffect{object = G.VFXsum, repeatCount = 1, position = ref.position}	tes3.playSound{sound = "conjuration hit", reference = ref} end
end

L.CFF = {["atronach_flame"] = L.CF.atr, ["atronach_flame_summon"] = L.CF.atr, ["atronach_frost"] = L.CF.atr, ["atronach_frost_summon"] = L.CF.atr, ["atronach_storm"] = L.CF.atr, ["atronach_storm_summon"] = L.CF.atr,
["atronach_flame_lord"] = L.CF.atrlord, ["atronach_frost_lord"] = L.CF.atrlord, ["atronach_storm_lord"] = L.CF.atrlord,	["dremora_lord"] = L.CF.dremoralord,
["golden saint"] = L.CF.auril, ["golden saint_summon"] = L.CF.auril, ["golden saint_staada"] = L.CF.auril, ["lich"] = L.CF.lich, ["lich_elder"] = L.CF.lichelder, ["ascended_sleeper"] = L.CF.ashascend,
["dagoth araynys"] = L.CF.ashvamp, ["dagoth endus"] = L.CF.ashvamp, ["dagoth gilvoth"] = L.CF.ashvamp, ["dagoth odros"] = L.CF.ashvamp, ["dagoth tureynul"] = L.CF.ashvamp, ["dagoth uthol"] = L.CF.ashvamp, ["dagoth vemyn"] = L.CF.ashvamp,
["lich_barilzar"] = L.CF.lichuni, ["lich_relvel"] = L.CF.lichuni, ["lich_profane_unique"] = L.CF.lichuni, ["dagoth_ur_2"] = L.CF.urdagot}


L.GetArStat = function()
local w = mp.readiedWeapon	local wd = w and w.variables	local w = w and w.object		local ww = w and math.min(w.weight, 50)		local BWK
if ww == 0 then
	BWK = (0.6 + math.min(mp:getSkillValue(13),100) * (P.con8 and 0.002 or 0.001)) * (P.con19 and D.BWwgt and 1.25 or 1)
	ww = w.enchantCapacity/10 * (P.con20 and 0.5 or 0.6) * (P.con19 and D.BWwgt and 1.5 or 1)
else BWK = 1 end

local wt = W.wt		local WS = math.min(mp:getSkillValue(WT[wt].s),200)		--(W.wt < -1 and W.wt) or (w and w.type) or -1	
local Agi = math.min(mp.agility.current,500)		local Str = math.min(mp.strength.current,500)
local sp = mp.currentSpell or tes3.getObject("flame")		local enchant = sp.objectType == tes3.objectType.enchantment		local cost, sc

if enchant then	cost = sp.chargeCost	sc = sp.effects[1].object.school else cost = sp.magickaCost		sc = sp:getLeastProficientSchool(mp) end


local MS = math.min(mp:getSkillValue(SP[sc].s),200)		local eid = sp.effects[1].id
local run = mp.alwaysRun	local strafe = mp.isMovingLeft or mp.isMovingRight	local forw = mp.isMovingForward		local back = mp.isMovingBack		if not (strafe or forw or back) then forw = true end
local Enc = mp.encumbrance		M.WgtBarT.text = ("%d/%d"):format(Enc.currentRaw, Enc.base)

G.spdk0 = ( (run and 100 + mp:getSkillValue(8)*(P.atl1 and 0.5 or 0.35) or 150) + math.min(mp.speed.current,500) * (P.spd9 and 0.5 or 0.35) )
* (run and (G.TR.tr3 and 4 or 3.5) + (G.SPRcur and (P.spd0 and 1 or 0.5) * (G.SPRT - (T.SPR.timeLeft or 0))/G.SPRT or 0) or 1)
G.spdk1 = math.min(D.AR.ms + G.LIG, 1)
G.spdk2 = math.max(1 - G.ENC * (P.atl3 and 0.2 or 0.4), 0.2)
G.spdk3 = run and math.min(math.lerp(P.end18 and 0.75 or 0.5, 1, G.STN * (P.atl2 and 2 or 1.25)), 1) or 1
G.spdk4 = (not P.acr3 and mp.isFalling and 0.75 or 1)
* ((forw and 1) or (back and 0.8) or 0.75)
* (back and 0.625 or 1)
* (run and ((P.spd11 or M.MCB.current == 0) and 1 or 0.8)
* ((forw or P.spd20) and 1 or 0.8)
* ((ad.animationAttackState == 2 and (P.spd10 and 0.8 or 2/3)) or (ad.animationAttackState == 10 and (P.spd19 and 0.8 or 2/3)) or 1)
or 1)
M.ST11.text = ("%s/%s/%s/%s"):format(D.AR.l, D.AR.m, D.AR.h, D.AR.u)
M.ST12.text = ("%d"):format(G.spdk0 * G.spdk1 * G.spdk2 * G.spdk3 * G.spdk4)


local End = mp.endurance.current	local Wil = math.min(mp.willpower.current,500)		--local Int = math.min(mp.intelligence.current,500)
local ShBon = mp.readiedShield and ad.animationAttackState == 2 and mp:getSkillValue(0) * (P.bloc7 and 0.4 or 0.2) or 0
local ElRes = P.des9 and math.min(mp:getSkillValue(10),100)/10 or 0
	
M.RES1.text = ("%d"):format(mp.resistMagicka + (P.mys6 and math.min(mp:getSkillValue(14),100)/10 or 0) + (math.min(End,500)*0.1 + math.min(Wil,500)*0.3) * (P.wil3 and 1 or 0.5) )
M.RES2.text = ("%d"):format(mp.resistFire  + D.AR.elr + ShBon + ElRes + (math.min(End,500)/5 + math.min(Wil,500)/5) * (P.end7a and 1 or 0.5) )
M.RES3.text = ("%d"):format(mp.resistFrost + D.AR.elr + ShBon + ElRes + (math.min(End,500)/5 + math.min(Wil,500)/5) * (P.end7b and 1 or 0.5) )
M.RES4.text = ("%d"):format(mp.resistShock + D.AR.elr + ShBon + ElRes + (math.min(End,500)/5 + math.min(Wil,500)/5) * (P.end7c and 1 or 0.5) )
M.RES5.text = ("%d"):format(mp.resistPoison + (P.alc10 and math.min(mp:getSkillValue(16),100)/10 or 0) + (math.min(End,500)*0.3 + math.min(Wil,500)*0.1) * (P.end7d and 1 or 0.5) )



local Kstr = 100 + Str * ( (P.str1 and 0.4 or 0.3) + (G.TR.tr10 and 0.1 or 0) + (P.str15 and 0.2 * math.max(1 - mp.health.normalized, 0) or 0) )
local Kskill = WS * ((P[WT[wt].p1] and 0.4 or 0.2) + (P[wt < 9 and (WT[wt].h1 and "agi5" or "str2") or "agi30"] and 0.1 or 0))
local Kstam = math.min(math.lerp(P.end1 and 0.75 or 0.5, 1, G.STN*(P[WT[wt].p2] and 2 or 1.25)), 1)
local Cond = 1	if wd then Cond = wd.condition/w.maxCondition	Cond = Cond > 1 and math.min(Cond,1.2) or math.lerp(P.arm2 and 0.5 or 0.25, 1, Cond)		Cond = Cond * BWK end
local Range
if wt > 8 then local prob = mp.readiedAmmo	prob = prob and prob.object		local prw = prob and prob.weight or 0		local vel
	if wt == 11 then vel = 1000 + (Str*(P.str12 and 1.5 or 1)/(prw+5))^0.5 * 500 * Kstam	
	else vel = 1000 + (w.chopMax * Cond / math.clamp(prw, 0.2, 0.5)+0.1)^0.5 * 500 end
	Range = (100 + Kskill) * 4*vel/(vel/100+100)/100
end

local spd = w and w.speed or 1
if w and wt < 11 then
	spd = 2 + ww/(ww + 50) * (-3.5 + (WT[wt].spb and 0.5 or 0) + Str/(Str + 100) * (P[wt < 9 and "str16" or "str17"] and 1 or 0.5) )
end

spd = spd * math.max((0.8 + math.min(mp.speed.current,500)/(P.spd1 and 1000 or 2000) + WS/(P[WT[wt].p4] and 500 or 1000) - (1 - G.STN) * (P.atl11 and 0.1 or 0.2) - G.ENC * (P.atl12 and 0.1 or 0.2))
* math.min(D.AR.as + G.LIG, 1), 0.5)

M.ST21.text = ("%d%%"):format(wt < 9 and (Kstr + Kskill) * (WT[wt].h1 and 0.75 or 1) * Kstam * Cond or Range)
M.ST22.text = ("%.2f / %d"):format(spd, (P[WT[wt].pc] and 4 or 3) + math.floor(WS/50) + (P.spd14 and W.DWM and 1 or 0))
M.ST23.text = ("%d"):format(10 + End/5 + Mag(77) - Mag(25))



local Cstam = math.min(math.lerp(P.wil2 and 0.75 or 0.5, 1, G.STN * (P[enchant and "enc5" or SP[sc].p3] and 2 or 1.25)), 1)
local Cbonus = MS * (P[MEP[eid] and MEP[eid].p0 or SP[sc].p1] and 0.75 or 0.5)
+ (P[MEP[eid] and MEP[eid].p or "mys0"] and math.min(mp:getSkillValue(MEP[eid] and MEP[eid].s or 14),200) * 0.25 or 0)
if enchant then Cbonus = Cbonus/2 + math.min(mp:getSkillValue(9),200) * (P.enc1 and 0.5 or 0.25) end
Cbonus = math.min(Cbonus + Wil * ((G.TR.tr24 and 0.75 or 0.5) + (P.wil1 and 0.25 or 0)), 600)
Cbonus = (50 + 200*Cbonus/(Cbonus+600))

M.ST31.text = ("%d%%"):format(Cbonus * Cstam)
M.ST32.text = ("%d%%"):format(math.round(100 * L.MCOST(enchant and 9 or sc)))


M.ST33.text = (enchant or sp.alwaysSucceeds) and "100%" or ("%d%%"):format(
(  math.min(MS,150) * (P[SP[sc].p2] and 1.6 or 1.2)
+  math.min(Wil,300) * (P.wil5 and 0.2 or 0.1)
+  math.min(mp.luck.current,300) * (P.luc13 and 0.2 or 0.1)
+ (mp.spellReadied and (P.int8 and 40 or 20) or 0) )
* math.max(1 - G.ENC * (P.end17 and 0.1 or 0.25), 0.25)
* (D.AR.cc > 1 and D.AR.cc or math.min(D.AR.cc + G.LIG, 1))
- mp.sound - cost
- math.max(cost/2 - mp.intelligence.current * (G.TR.tr25 and 0.5 or 1) * (P.int6 and 0.5 or 0.25), 0) )

M.ST34.text = ("%d"):format(Mag(76))


local DodSt, DodPow = L.DodCalc()		local Acr = mp:getSkillValue(20)
local DodEf = math.min(Agi * (P.agi20 and 0.2 or 0.1) + (P.luc3 and mp.luck.current/10 or 0) + (P.acr6 and mp.isJumping and Acr/5 or 0), 100)
+ DodPow/5 + Agi * (P.agi2 and 0.2 or 0.1) + (P.spd2 and 20 or 0) + (P.lig12 and D.AR.l or 0) + (P.agi23 and W.DWM and 20 or 0)
local JumpPow = (300 + Acr * (P.acr1 and 1.5 or 1) + Agi * (G.TR.tr26 and 1.5 or 1) + mp.jump * (P.alt24 and 10 or 8))
* math.min(math.lerp(P.atl13 and 0.75 or 0.5, 1, G.STN*(P.acr14 and 2 or 1.25)), 1)
* math.max(1 - G.ENC * (P.atl6 and 0.2 or 0.4), 0.2) * G.spdk1
M.ST41.text = ("%d/%d/%d"):format(JumpPow, DodPow, DodEf)

local gau = wt == -1 and tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = 7}	gau = gau and math.min(gau.object.weight,10) or 0
M.ST42.text = ("%d/%d/%d/%d"):format( ((ww or 0) + (WT[wt].h1 and 5 or 10))
* (1 + G.ENC * (P.atl14 and 0.1 or 0.25))
* ((P.end6 and 0.75 or 1) - (P[WT[wt].p3] and WS/400 or 0))
* (gau > 0 and 1 + gau/10 or 1),
20 + 20 * G.ENC, (P.acr2 and 25 or 30) * (G.ENC*(P.atl6 and 0.25 or 0.5) + (D.AR.dc < 1 and D.AR.dc or math.max(D.AR.dc - G.LIG,1))), DodSt)
end

L.GetWstat = function() local rw = mp.readiedWeapon		W.v = rw and rw.variables		local w = rw and rw.object		local wt = w and w.type or -1		local wid = w and w.id		W.wt = wt		W.w = w		
	local en = w and w.enchantment			W.en = en and en.castType == 1 and wt < 11 and en or nil
	if W.en then	W.BAR.visible = true	W.bar.max = W.en.maxCharge	G.wf = nil		local eid
		for i, eff in ipairs(W.en.effects) do
			if wt < 9 then eid = eff.id		 if eff.rangeType == 2 or L.MESG[eid] or L.MERAY[eid] then G.wf = 1 break end
			elseif eff.rangeType == 1 then G.wf = 1 break end
		end
		if not G.wf and wt > 8 then G.wf = 2 end
	else G.wf = nil	W.BAR.visible = false end
	
	if wt ~= -1 then	
		if wid:sub(1,1) == "*" then local Old = tes3.getObject(wid:sub(2))	if Old then
			if wt == 1 then	if Old.type == 6 then wt = -2	W[wid] = -2 end		elseif wt == 3 then	if Old.type == 5 then wt = -3	W[wid] = -3 end end		W.wt = wt
		end end
		
		G.wgt = L.GetWW(w,mp) 		G.atcost = G.wgt + (WT[wt].h1 and 5 or 10)
		G.cot = w.isOneHanded and (W.DWM and (w == W.WL and W.v == W.DL and 3 or 1) or 1) or 2
		
		M.CombK.text = wt > 8 and ("%s"):format(mp.readiedAmmoCount or 0) or ""
		if cf.m8 then tes3.messageBox("%s  Stam = %d  %s", w.name, G.atcost, G.wf and (G.wf == 2 and "Explode arrow!" or "Enchant strike!") or "") end
	else G.wgt = 0	G.atcost = 10		G.cot = 0		if cf.m8 then tes3.messageBox("No weapon   Stam = %d", G.atcost) end	end
	
	if wt < 9 then G.swmult = (P.spd13 and 0.5 or 0) + (P[WT[wt].p8] and 0.5 or 0) end
	
	if tes3ui.menuMode() and M.INV then L.GetArStat() end
end

L.GetArmT = function() D.AR = {l=0,m=0,h=0,u=0}		local Sl, Sm, Sh, Su = mp.lightArmor.base, mp.mediumArmor.base, mp.heavyArmor.base, mp.unarmored.base
for i, val in pairs(L.ARW) do	local s = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i}		
	if (i == 6 or i == 7) and not s then s = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = i+3} end
	local ob = s and s.object		local kap = ob and i == 0 and L.ARM[ob.mesh:lower()]	kap = kap and kap.m == "Капюшон"
	s = L.AT[s and not kap and not (P.con18 and ob.weight == 0) and ob.weightClass or 3].t		D.AR[s] = D.AR[s] + val
end
D.AR.ms = 1 - (D.AR.l*((P.lig2 and 100 or 200) - Sl) + D.AR.m*((P.med2 and 200 or 300) - Sm) + D.AR.h*((P.hev2 and 300 or 400) - Sh))/20000
D.AR.as = 1 - (D.AR.l*((P.lig3 and 100 or 200) - Sl) + D.AR.m*((P.med3 and 200 or 300) - Sm) + D.AR.h*((P.hev3 and 300 or 400) - Sh))/40000
D.AR.dk = 1 + (P.una5 and D.AR.u*Su/10000 or 0) - (D.AR.l*((P.lig5 and 100 or 200) - Sl) + D.AR.m*((P.med5 and 200 or 300) - Sm) + D.AR.h*((P.hev5 and 300 or 400) - Sh))/20000
D.AR.dc = 1 - (P.una6 and D.AR.u*Su/12500 or 0) + (D.AR.l*((P.lig6 and 100 or 200) - Sl) + D.AR.m*((P.med6 and 200 or 300) - Sm) + D.AR.h*((P.hev6 and 300 or 400) - Sh))/20000
D.AR.cs = 1 + (P.una4 and D.AR.u*Su/10000 or 0) - (D.AR.l*((P.lig4 and 100 or 200) - Sl) + D.AR.m*((P.med4 and 200 or 300) - Sm) + D.AR.h*((P.hev4 and 300 or 400) - Sh))/40000
D.AR.cc = 1 + (P.una1 and D.AR.u*Su/10000 or 0) - (D.AR.l*((P.lig1 and 100 or 200) - Sl) + D.AR.m*((P.med1 and 200 or 300) - Sm) + D.AR.h*((P.hev1 and 300 or 400) - Sh))/20000
D.AR.mc = 1 - (P.una7 and D.AR.u*Su/12500 or 0) + (D.AR.l*((P.lig7 and 100 or 200) - Sl) + D.AR.m*((P.med7 and 200 or 300) - Sm) + D.AR.h*((P.hev7 and 300 or 400) - Sh))/40000
D.AR.elr = (D.AR.l * Sl * 2 + D.AR.m * Sm * 3 + D.AR.h * Sh * 4) * (P.end21 and 0.004 or 0.002)

if M.INV then L.GetArStat() end
end

L.ConstEnLim = function()	D.ENconst = 0		D.ENconMax = 5000 + mp.enchant.base*30 + (P.enc16 and 2000 or 0)		-- Функция не используется
	for _, s in pairs(p.object.equipment) do if s.object.enchantment and s.object.enchantment.castType == 3 then
		if s.object.objectType == tes3.objectType.clothing then D.ENconst = D.ENconst + math.max(L.CLEN[s.object.slot] or 0, s.object.enchantCapacity)
		elseif s.object.objectType == tes3.objectType.armor then D.ENconst = D.ENconst + math.max(L.AREN[s.object.slot] or 0, s.object.enchantCapacity) end
	end end
	M.PC.max = L.GetPCmax()
	if M.INV then M.ENL.current = D.ENconst		M.ENL.max = D.ENconMax end
end


L.UpdShield = function(sh)
	if T.Shield.timeLeft then T.Shield:reset() else T.Shield = timer.start{duration = 10, callback = function() M.SHbar.visible = false end} end
	M.SHbar.widget.max = sh.object.maxCondition		M.SHbar.widget.current = sh.variables.condition		M.SHbar.visible = true
end
L.M180 = tes3matrix33.new()		L.M180:toRotationX(math.rad(180))
L.MatrRag = tes3matrix33.new() 	L.MatrRag:toRotationZ(math.rad(cf.ragang))
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

local TSK = 1
L.UpdTSK = function() local pow = Mag(510)
if pow == 0 then TSK = 1 else TSK = math.max(1 - pow/(pow + 50), P.ill8 and 0.05 or 0.25) end
wc.simulationTimeScalar = TSK
--tes3.messageBox("TSK = %s ", wc.simulationTimeScalar)
end


local BAM = {[9] = "4nm_boundarrow", [10] = "4nm_boundbolt", ["met"] = "4nm_boundstar", ["4nm_boundarrow"] = 9, ["4nm_boundbolt"] = 10, ["4nm_boundstar"] = true}
BAM.f = function() mc = (P.con10 and 4 or 6) * L.MCOST(1) 		if PMP.current > mc then Mod(mc) return true else return false end end

local DER = {}	local function DEDEL() for r, ot in pairs(DER) do if r.sceneNode then r.sceneNode:detachChild(r.sceneNode:getObjectByName("detect"))	r.sceneNode:update()	r.sceneNode:updateNodeEffects() end end		DER = {} end

--local function CMSFrost(e) e.speed = e.speed * (AF[e.reference].frost2 or 1) end



L.KArrowCol = function(e)
	local dist = e.collision.point:distance(pp)
--	local koef = 500 / (500 + dist)		local koef2 = 1 / (1 + (dist/1000)^2)		--	tes3.messageBox("%d    Koef = %.4f", dist, koef2)
	if dist < 4000 then tes3.playSound{reference = p, soundPath = L.RSound("Metal1"), volume = cf.volimp / (1 + (dist/1000)^2), pitch = math.random(90,110)/100} end
end

L.KArrowTik = function(e)	
	local si = e.sourceInstance		local sn = si.serialNumber	local ei = e.effectInstance		local tr = ei.target	local t = tr.mobile		local tsh = t.readiedShield
	local ef = si.source.effects[e.effectIndex + 1]		local koef = L.Cpow(mp,0) * (SN[sn] or 1)		local mag = math.random(ef.min, ef.max)
	local BaseHP = t.health.base	local Tagi = t.agility.current		local Tend = t.endurance.current	local Tluc = t.luck.current		local fat = t.fatigue
	local MarkS = mp:getSkillValue(23)	local Agi = mp.agility.current	local Luc = mp.luck.current		local Kcrit
	
	local CritC = mp.attackBonus/4 + MarkS/(P.mark6c and 10 or 20) + Agi/(P.agi1 and 5 or 10) + Luc/(P.luc1 and 10 or 20)
	+ (t.isMovingForward and 10 or 0) - (Tend + Tagi + Tluc)/10 + math.clamp(1-fat.normalized,0,1)*(P.agi11 and 20 or 10) - 10
	
	if CritC > math.random(100) then
		Kcrit = 30 + (P.agi8 and 10 or 0) + (P.mark5c and 10 or 0) + math.max(CritC - 100, 0)
		Kcrit = math.random(Kcrit, Kcrit*2)
	else Kcrit = 0 end
	local dmg = mag * koef * (1 + Kcrit/100)
	
	if tsh then		local ang = t:getViewToPoint(COL[sn])		if math.abs(ang) < 45 then
		local bloc = (t:getSkillValue(0)/2 + Tagi/4 + Tluc/4) * math.min(fat.normalized,1) * 1.5 - (MarkS/2 + Agi/4 + Luc/4) * (P.mark16 and 1 or 0.5)
		if cf.m3 then tes3.messageBox("Block projectile chance = %d%%   Ang = %d", bloc, ang) end
		if bloc > math.random(100) then tsh.variables.condition = math.max(tsh.variables.condition - dmg * 0.5, 0)
			if tsh.variables.condition < 0.1 then t:unequip{item = tsh.object} end
			tes3.playSound{reference = tr, soundPath = L.RSound("DmgShield0"), volume = cf.volimp, pitch = math.random(90,110)/100}
			ei.state = tes3.spellState.retired		return
		end
	end end
	
	G.DmgR[tr] = 1		G.FDSource = "Arrow"		G.FDMG = dmg		G.FdmgInd = Kcrit
	local fdmg = t:applyDamage{damage = dmg, applyArmor = true}
	if cf.m3 then tes3.messageBox("Arrow dmg = %d / %d   Mag = %d * %d%%   Crit = %d%% (%d%%)", fdmg, dmg, mag, koef*100, Kcrit, CritC) end
	ei.state = tes3.spellState.retired
end

L.METCol = function(e) local si = e.sourceInstance		local sn = si.serialNumber		local vel = si.projectile.velocity		local cp = e.collision.point		local dist = cp:distance(pp)	local r, wd, dmg, iso
	if V.MET[sn] then
		r = V.MET[sn].r			iso = WT[r.object.type].iso		wd = r.attachments.variables
		local cvel = vel:length() 	local velk = 4*cvel/(cvel/100 + 100)		dmg = V.MET[sn].dmg	* velk/100 			V.MET[sn].cdmg = dmg
	elseif si == G.TETsi then
		r = G.TETR		local wt = r.object.objectType == tes3.objectType.weapon and r.object.type	if wt and wt < 9 then iso = WT[wt].iso end
		dmg = G.TETdmg		wd = r.object.hasDurability and r.attachments.variables
	end
	
	local hit = tes3.rayTest{position = cp - vel:normalized()*10, direction = vel, maxDistance = 150, ignore = {r}}
	if hit then 		--hit.intersection:distance(cp) < 150 
		local ref = hit.reference
		if not (ref and ref.mobile) then
		--	tes3.messageBox("cond = %s    dmg = %s", wd and wd.condition, dmg)
			local dir		local Mat = L.MAT[L.GetMat(hit)] or "Stone"		if Mat == "Water" then dir = Mat else dir = Mat .. (iso or 1) end
			if wd then wd.condition = math.max(wd.condition - dmg * L.MatD[Mat] * G.WdmgM, 0) end
			if dist < 5000 then tes3.playSound{reference = p, soundPath = L.RSound(dir), volume = cf.volimp / (1 + (dist/1000)^2), pitch = math.random(90,110)/100} end
		end
	end
end

L.METTik = function(e) --if not e:trigger() then return end		
	local ei = e.effectInstance		local si = e.sourceInstance		local sn = si.serialNumber		local tr = ei.target	local t = tr.mobile		local r, wd, dmg, iso
	if V.MET[sn] then	
		r = V.MET[sn].r			dmg = V.MET[sn].cdmg		iso = WT[r.object.type].iso			wd = r.attachments.variables		V.MET[sn] = nil
	elseif si == G.TETsi then 
		r = G.TETR		local wt = r.object.objectType == tes3.objectType.weapon and r.object.type		if wt and wt < 9 then iso = WT[wt].iso end
		dmg = G.TETdmg * L.Cpow(mp,0,true)		wd = r.object.hasDurability and r.attachments.variables			G.TETsi = nil	G.TETmod = 3		L.GetMetRetSpd()
		if M.MCB.normalized > 0 then dmg = dmg * (1 + M.MCB.normalized * (P.wil7 and 0.2 or 0.1))		M.MCB.current = 0 end
	end
	if dmg then
		local BaseHP = t.health.base	local Tagi = t.agility.current		local Tend = t.endurance.current	local Tluc = t.luck.current		local tsh = t.readiedShield		local fat = t.fatigue
		local MarkS = mp:getSkillValue(23)		local Agi = mp.agility.current		local Luc = mp.luck.current		local Kcrit
		
		local CritC = mp.attackBonus/4 + MarkS/(P.mark6c and 10 or 20) + Agi/(P.agi1 and 5 or 10) + Luc/(P.luc1 and 10 or 20)
		+ (t.isMovingForward and 10 or 0) - (Tend + Tagi + Tluc)/10 + math.clamp(1-fat.normalized,0,1)*(P.agi11 and 20 or 10) - 10
		
		if CritC > math.random(100) then
			Kcrit = 30 + (P.agi8 and 10 or 0) + (P.mark5c and 10 or 0) + math.max(CritC - 100, 0)
			Kcrit = math.random(Kcrit, Kcrit*2)
			dmg = dmg * (1 + Kcrit/100)
		else Kcrit = 0 end
		
		if tsh then		local ang = t:getViewToPoint(COL[sn])		if math.abs(ang) < 45 then
			local bloc = (t:getSkillValue(0)/2 + Tagi/4 + Tluc/4) * math.min(fat.normalized,1) * 1.5 - (MarkS/2 + Agi/4 + Luc/4) * (P.mark16 and 1 or 0.5)
			if cf.m3 then tes3.messageBox("Block projectile chance = %d%%", bloc) end
			if bloc > math.random(100) then tsh.variables.condition = math.max(tsh.variables.condition - dmg, 0)
				if tsh.variables.condition < 0.1 then t:unequip{item = tsh.object} end
				tes3.playSound{reference = tr, soundPath = L.RSound("DmgShield0"), volume = cf.volimp, pitch = math.random(90,110)/100}
				ei.state = tes3.spellState.retired		return
			end
		end end

		
		G.DmgR[tr] = iso	G.FDSource = "Throw"	G.FDMG = dmg	G.FdmgInd = Kcrit		--G.FDMGImm = not (w.enchantment or w.ignoresNormalWeaponResistance)
		local fdmg = t:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}	local hs	local tad = t.actionData
		if wd then wd.condition = math.max(wd.condition - dmg * G.WdmgM, 0) end
		if cf.m3 then tes3.messageBox("Throw dmg = %d / %d    Crit = %d%% (%d%%)  HS = %d%%", fdmg, dmg, Kcrit, CritC, hs or 0) end
	end
	ei.state = tes3.spellState.retired
end

L.SimMET = function(e)
for r, t in pairs(V.METR) do if t.f then
	r.position = r.position:interpolate(pp, wc.deltaTime * G.MetRetSpd)
	if pp:distance(r.position) < 150 then local ob = r.object	p:activate(r)		if not mp.readiedWeapon	then timer.delayOneFrame(function() mp:equip{item = ob} end) end	V.METR[r] = nil end
end end
if table.size(V.METR) == 0 then event.unregister("simulate", L.SimMET)	W.metflag = nil end
end

local function SIMTEL(e) if G.TETR then
	if G.TETmod == 1 then G.TETR.position = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150 + tes3vector3.new(0,0,-30)		G.TETR.orientation = p.orientation
	elseif G.TETmod == 2 then G.TETR.position = W.TETP.position		G.TETR.orientation = p.orientation
	elseif G.TETmod == 3 then G.TETR.position = G.TETR.position:interpolate(pp, wc.deltaTime * G.MetRetSpd)
		if pp:distance(G.TETR.position) < 150 then G.TETmod = 1
			tes3.playSound{reference = p, soundPath = L.RSound(WT[11].sws), volume = 1, pitch = math.random(90,110)/100}
		end
	end
else event.unregister("simulate", SIMTEL) 	W.TETP = nil	G.TETmod = nil	end end

local function TELnew(r)
	if G.TETmod then local hit = tes3.rayTest{position = G.TETR.position, direction = V.down}	if hit then G.TETR.position = hit.intersection + tes3vector3.new(0,0,5) end
	if cf.m then tes3.messageBox("%s no longer under control", G.TETR.object.name) end		event.unregister("simulate", SIMTEL) 	G.TETmod = nil	G.TETR = nil	W.TETP = nil	G.TETsi = nil end		
	if r.stackSize == 1 and tes3.isAffectedBy{reference = p, effect = 506} then		local ob = r.object		if ob.weight ~= 0 then
		if r.tempData then r.tempData.TET = true end		G.TETcost = (5 + ob.weight) * (P.int31 and 0.5 or 0.75)		G.TETR = r		G.TETmod = 1	event.register("simulate", SIMTEL)
		if not tes3.hasOwnershipAccess{target = r} then tes3.triggerCrime{value = ob.value, type = 5, victim = r.attachments.variables.owner} end
		if cf.m then tes3.messageBox("%s under control!  weight = %.2f", ob.name, ob.weight) end
	end end
end


L.LigSim = function() if G.LigR then	if G.LigR.cell ~= p.cell then L.LigUpd(1) else
	local pos = pp:copy()	pos.z = pos.z + 200 + L.MagLig.radius/50	local dist = G.LigR.position:distance(pos)		if dist > 10 then G.LigR.position = G.LigR.position:interpolate(pos, 5 + dist/20) end
end else event.unregister("simulate", L.LigSim)	end end
L.LigTik = function() if G.LigR then G.LigR:disable()		G.LigR:enable()		G.LigR.modified = false else T.LI:cancel() end end

L.LigUpd = function(SaveCol)
	if G.LigR then G.LigR:delete()	G.LigR = nil end
	if D.e504 then
		L.MagLig.radius = 100 * D.e504		if not SaveCol then L.LIRcol(cf.col) end		L.MagLig.value = 40000
		G.LigR = tes3.createReference{object = L.MagLig, scale = math.min(1+L.MagLig.radius/1000, 9), position = pp, cell = p.cell}		G.LigR.modified = false
		if not event.isRegistered("simulate", L.LigSim) then event.register("simulate", L.LigSim) end
		if not T.LI.timeLeft then T.LI = timer.start{duration = 1, iterations = -1, callback = L.LigTik} end
	end
end

L.LigCol = function(e) if e.sourceInstance.caster == p then -- Фонарь (504)
local ef = e.sourceInstance.source.effects[e.effectIndex + 1]	local pos = e.collision.point:copy()	pos.z = pos.z + 5	L.LIRcol(cf.col)
L.MagLig.radius = math.random(ef.min, ef.max) * L.Cpow(mp,0) * 100  * (SN[e.sourceInstance.serialNumber] or 1)		L.MagLig.value = 0
local LTR = tes3.createReference{object = L.MagLig, scale = math.min(1+L.MagLig.radius/1000, 9), position = pos, cell = tes3.getPlayerCell()}		LTR.modified = false	G.LigTab[LTR] = true		--Invalid 'cell' parameter provided
timer.start{duration = ef.duration, callback = function() G.LigTab[LTR] = nil	LTR:delete() end}
if cf.m then tes3.messageBox("Light active! Radius = %d   Time = %d	  Total = %d", L.MagLig.radius, ef.duration, table.size(G.LigTab)) end
end end


L.AuraTik = function()	local Mg = {D.e516 or 0, D.e517 or 0, D.e518 or 0, D.e519 or 0, D.e520 or 0}		local MSum = Mg[1] + Mg[2] + Mg[3] + Mg[4] + Mg[5]
if MSum > 0 then	local MTab = {}		local num = 0	local rad
	if not D.Aurdis then local E = B.AUR.effects		rad = (100 + mp.willpower.current + mp:getSkillValue(11)) * ((P.alt41 and 1.5 or 1) + (P.wil33 and M.MCB.normalized/2 or 0))
		for i, mag in ipairs(Mg) do if mag > 0 then E[i].id = L.MID[i]  E[i].min = mag		E[i].max = mag	E[i].duration = 3 else E[i].id = -1 end end
		for _, m in pairs(tes3.findActorsInProximity{reference = p, range = rad}) do if m ~= mp and (cf.agr or R[m.reference]) and tes3.getCurrentAIPackageId(m) ~= 3 then MTab[m.reference] = m		num = num + 1 end end
	end
	if num > 0 then
		for r, m in pairs(MTab) do SNC[(tes3.applyMagicSource{reference = r, source = B.AUR}).serialNumber] = mp		L.CrimeAt(m) end
		if cf.m then tes3.messageBox("Aura = %d + %d + %d + %d + %d   Rad = %d   %d targets", Mg[1], Mg[2], Mg[3], Mg[4], Mg[5], rad, num) end
	else for _, aef in pairs(mp:getActiveMagicEffects{}) do	if L.MEAUR[aef.effectId] then	local EI = aef.effectInstance		EI.timeActive = EI.timeActive - (P.int24 and 2 or 1) end end end
else T.AUR:cancel()		D.AUR = nil end
end

L.EmpSpell = function(r, pos, k) local d = r.data		local mk = (r == p and (P.int34 and 1.2 or 1.5) * L.MCOST(2) or 1.5) * k			--L.MEEMP
	local M = {d.e531 or 0, d.e532 or 0, d.e533 or 0, d.e534 or 0, d.e535 or 0, d.e615 or 0}
	local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.3 + M[4]*0.5 + M[5]*0.4 + M[6]*0.4) * mk
	if mc > 0 then local mob = r.mobile
		if mob.magicka.current > mc then			local rad = k == 0.1 and 1 or L.GetRad(mob)		local n = 0
			for i, mag in ipairs(M) do if mag > 0 then n = n+1		G.EXP[n].id = L.MID[i]  G.EXP[n].min = mag * k   G.EXP[n].max = mag * k		G.EXP[n].radius = rad	G.EXP[n].duration = 0	G.EXP[n].rangeType = 2 end end
			for i = (n+1), 6 do G.EXP[i].id = -1	G.EXP[i].rangeType = 0 end
			MP[tes3.applyMagicSource{reference = r, source = B.EXP}] = {pos = pos, exp = true}
			Mod(mc, mob)		if cf.m then tes3.messageBox("Empower = %d + %d + %d + %d + %d + %d   Rad = %d   Cost = %.1f (%d%%)", M[1], M[2], M[3], M[4], M[5], M[6], rad, mc, mk*100) end
		end
	else d.Emp = nil end
end

L.CWF = function(r, rt, k, pos)	local d = r.data		k = r == p and (P.int35 and k*0.8 or k) * L.MCOST(2) or k			--L.MECW
	local M = {d.e511 or 0, d.e512 or 0, d.e513 or 0, d.e514 or 0, d.e515 or 0, d.e614 or 0}
	local mc = (M[1]*0.3 + M[2]*0.3 + M[3]*0.3 + M[4]*0.5 + M[5]*0.4 + M[6]*0.4) * k
	if mc > 0 then local mob = r.mobile
		if mob.magicka.current > mc then		local rad = rt == 2 and L.GetRad(mob) or 1			local n = 0		B.CW.value = math.ceil(mc*10)
			for i, mag in ipairs(M) do if mag > 0 then n = n+1		G.CW[n].id = L.MID[i]  G.CW[n].min = mag   G.CW[n].max = mag	G.CW[n].rangeType = rt	G.CW[n].duration = 0	G.CW[n].radius = i == 6 and rt == 1 and 0 or rad end end
			for i = (n+1), 6 do G.CW[i].id = -1		G.CW[i].rangeType = 0 end
			if pos then MP[tes3.applyMagicSource{reference = r, source = B.CW}] = {pos = pos, exp = true} else tes3.applyMagicSource{reference = r, source = B.CW} end
			Mod(mc, mob)		if cf.m then tes3.messageBox("CW = %d + %d + %d + %d + %d + %d   Rad = %d  Cost = %.1f (%d%%)", M[1], M[2], M[3], M[4], M[5], M[6], rad, mc, k*100) end
		end
	else d.CW = nil end
end

L.RechargeTik = function()		local mag = D.e501	if mag then
	if G.REI then	local pow = mag * (1 + (P.enc4 and mp:getSkillValue(9)/400 or 0))
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
	end
	if not G.REI then
		if P.enc22 and PMP.normalized < 1 then PMP.current = math.min(PMP.current + mag/4, PMP.base) 	M.Mana.current = PMP.current end		--tes3.messageBox("Recharge mana + %.1f (%.1f mag)", mag/2, mag)
		if T.PCT.timeLeft then M.PC.current = math.min(M.PC.current + mag * (P.enc24 and 0.5 or 0.25), M.PC.max) end
	end
else AF[p].T501:cancel()	AF[p].T501 = nil end end

L.RechargeNPC = function(m, t, te) local mag = t.data.e501	if mag then
	local w = m.readiedWeapon	local v = w and w.variables		local en = w and w.object.enchantment
	if v and en and v.charge < en.maxCharge then v.charge = math.min(v.charge + mag, en.maxCharge)
		if cf.m2 then tes3.messageBox("Recharge = %.1f  %s charges = %d/%d", mag, w.object.name, v.charge, en.maxCharge) end
	else for _, st in pairs(t.object.equipment) do v = st.variables		en = st.object.enchantment	if v and en and v.charge < en.maxCharge then v.charge = math.min(v.charge + mag, en.maxCharge)
		if cf.m2 then tes3.messageBox("Recharge = %.1f  %s charges = %d/%d", mag, st.object.name, v.charge, en.maxCharge) end break
	end end end	
else te.timer:cancel()	AF[t].T501 = nil end end

L.RepairWTik = function(m, t, te) local mag = t.data.e502	if mag then
	local pow = mag * (1 + ((m ~= mp or P.arm6) and m:getSkillValue(1)/400 or 0))		local ob = m.readiedWeapon		local var = ob and ob.variables		ob = ob and ob.object
	if var and var.condition < ob.maxCondition then var.condition = math.min(var.condition + pow, ob.maxCondition)
		if cf.m2 then tes3.messageBox("Repair = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, ob.name, var.condition, ob.maxCondition) end
	else	
		for _, st in pairs(t.object.inventory) do ob = st.object		var = st.variables
			if ob.objectType == tes3.objectType.weapon and var then
				for i, ida in pairs(var) do if ida.condition < ob.maxCondition then ida.condition = math.min(ida.condition + pow, ob.maxCondition)
					if cf.m2 then tes3.messageBox("Repair = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, ob.name, ida.condition, ob.maxCondition) end return
				end end
			end
		end
	end
else te.timer:cancel()	AF[t].T502 = nil end end

L.RepairATik = function(m, t, te) local mag = t.data.e503	if mag then
	local pow = mag * (1 + ((m ~= mp or P.arm6) and m:getSkillValue(1)/400 or 0))	local ob, var
	for _, st in pairs(t.object.equipment) do ob = st.object	var = st.variables		if ob.objectType == tes3.objectType.armor and var and var.condition < ob.maxCondition then
		var.condition = math.min(var.condition + pow, ob.maxCondition)
		if cf.m2 then tes3.messageBox("Repair = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, ob.name, var.condition, ob.maxCondition) end	return
	end end
	for _, st in pairs(t.object.inventory) do ob = st.object		var = st.variables
		if ob.objectType == tes3.objectType.armor and var then
			for i, ida in pairs(var) do if ida and ida.condition < ob.maxCondition then ida.condition = math.min(ida.condition + pow, ob.maxCondition)		-- ida почему-то может быть нил
				if cf.m2 then tes3.messageBox("Repair = %.1f (%.1f mag)  %s condition = %d/%d", pow, mag, ob.name, ida.condition, ob.maxCondition) end return
			end end
		end
	end
else te.timer:cancel()	AF[t].T503 = nil end end


L.MSF = function(RP, RFM, m, Epow)	local RFM1 = math.min(RFM, Epow)	mc = RFM1 * ((m ~= mp or P.int37) and 0.2 or 0.25)
	if m.magicka.current > mc then	if cf.m1 then tes3.messageBox("Manashield = %.1f / %.1f  Cost = %.1f", RFM, Epow, mc) end	Mod(mc,m)	return 100 - (100 - RP) * (1 - RFM1/Epow)
	else return RP end
end
	
local function SIMULATE(e)		--tes3.messageBox("State = %s   dt = %s", ad.animationAttackState, wc.deltaTime)		ЭВЕНТ ЗАБЛОКИРОВАН
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


local function ABSORBEDMAGIC(e)	local pow	local s = e.source	local si = e.sourceInstance			local num = s:getActiveEffectCount()
	if s.weight then pow = 0
		for i, ef in ipairs(s.effects) do if ef.id ~= -1 then pow = pow + (ef.min + ef.max) * ef.object.baseMagickaCost * math.max(ef.duration,1)/40 end end
	else pow = e.absorb end
	if not (e.mobile ~= mp or (P.mys21 and mp.spellReadied)) then pow = pow/2 end		e.absorb = pow/num
	if cf.m then tes3.messageBox("ABS %s  Mana + %.1f  (%d / %d eff)", s.name or s.id, e.absorb, pow, num) end
end		event.register("absorbedMagic", ABSORBEDMAGIC)



local function MAGICREFLECT(e)	local m = e.mobile	local r = e.target	local re = e.reflectEffect		local s = e.source		local si = e.sourceInstance		local sn = si.serialNumber	local num = s:getActiveEffectCount()
	e.reflectChance = 100
--	si.state = 6
	tes3.messageBox("REF %s (%s - %s)  Ch %d", s.name or s.id, num, sn, e.reflectChance)
end		--event.register("magicReflect", MAGICREFLECT)

local function MAGICREFLECTED(e)	local m = e.mobile	local r = e.target	local re = e.reflectEffect		local s = e.source		local si = e.sourceInstance		local sn = si.serialNumber	local num = s:getActiveEffectCount()
--	si.state = 6
	tes3.messageBox("REFD! %s (%s - %s)", s.name or s.id, num, sn)
end		--event.register("magicReflected", MAGICREFLECTED)


local function SPELLRESIST(e)	local c, resist, Cbonus, CritC, CritD 	local t = e.target	local m = t.mobile	local s = e.source	local ef = e.effect		local dur = ef.duration		local rt = ef.rangeType
local eid = ef.id	local sc = ef.object.school		local si = e.sourceInstance		local sn = si.serialNumber		local sot = s.objectType 	local wg = s.weight		local RP = 0	local cas = e.caster	local Mpr = MPR[sn]
local ResAt = e.resistAttribute
--tes3.messageBox("Spell resist    sid = %s    wgt = %s", s.id, wg)
if Mpr and ef.radius > 3 then
	if not Mpr[t] then
		if t == p then Mpr[t] = (tes3.testLineOfSight{position1 = COL[sn], position2 = pp, height2 = G.mph*0.5} or tes3.testLineOfSight{position1 = COL[sn], position2 = pp, height2 = G.mph*0.9}) and 1 or 0
		else Mpr[t] = tes3.testLineOfSight{position1 = COL[sn], position2 = t.position, height2 = m.height*0.7} and 1 or 0 end
		--tes3.messageBox("Spell resist    %s", Mpr[t])
	end
	if Mpr[t] == 0 then e.resistedPercent = 100		if tes3.getCurrentAIPackageId(m) == 3 then m.friendlyFireHitCount = math.max(m.friendlyFireHitCount - 1, 0) end		return end
end

if cas then if wg then -- для алхимии с весом > 0 кастера нет
	if wg == 0 then	-- для псевдозелий ИЛИ ингедиентов ИЛИ табличных соурсов
		if rt == 0 then		-- для эффектов на себя
			if ResAt == 28 then c = cas.mobile						-- позитивные - стандартный кастер
			else c = SNC[sn]		if c then cas = c.reference end		end		-- вредоносные: SNC[sn] - зоны, ауры и стихийные щиты. Нил - вторичные эффекты урона
		else c = cas.mobile end	-- для эффектов на цель и касания стандартный кастер
	end
else c = cas.mobile end end -- для спеллов и зачарований стандартный кастер

local MKF = SN[sn] or 1


if c then	--	if not c.object.level then tes3.messageBox("bad caster = %s  sid = %s", c.reference, s.id) end
	if c == mp then
		Cbonus = math.min(c:getSkillValue(SP[sc].s),200) * (P[MEP[eid] and MEP[eid].p0 or SP[sc].p1] and 0.75 or 0.5)
		+ (P[MEP[eid] and MEP[eid].p or "mys0"] and math.min(c:getSkillValue(MEP[eid] and MEP[eid].s or 14),200) * 0.25 or 0)
		if sot == tes3.objectType.enchantment then Cbonus = Cbonus/2 + math.min(c:getSkillValue(9),200) * (P.enc1 and 0.5 or 0.25) end
		Cbonus = math.min(Cbonus + math.min(c.willpower.current,500) * ((G.TR.tr24 and 0.75 or 0.5) + (P.wil1 and 0.25 or 0)), 600)
		Cbonus = (50 + 200*Cbonus/(Cbonus+600))
	else	Cbonus = math.min(50 + c:getSkillValue(sot == tes3.objectType.enchantment and 9 or SP[sc].s)/2 + c.willpower.current/2, 200) end
	
	CritC = (c == mp and (P.int5 and mp.spellReadied and 5 or 0) or 10)
	+ ((c ~= mp or P.wil4) and 5 or 0)
	+ ((c ~= mp or P.luc1) and math.min(c.luck.current,200)/20 or 0)

	if ResAt ~= 28 then CritC = CritC
		+ ((c ~= mp or P.wil8) and math.min(c.attackBonus,200)/10 or 0)
		+ ((c ~= mp or P.des0) and math.min(c:getSkillValue(10),200)/20 or 0)
		+ math.clamp(1-m.fatigue.normalized,0,1) * ((c ~= mp or P.int15) and 20 or 10)
		- m.willpower.current/((m ~= mp or P.wil6) and 10 or 20)
		- ((m ~= mp or P.luc2) and m.luck.current/20 or 0)
		- (m.spellReadied and (m ~= mp or P.mys5) and m:getSkillValue(14)/10 or 0)
	end
	
	if CritC > math.random(100) then
		CritD = ((c ~= mp or P.wil11) and 40 or 30) + (EMP[eid] and (c ~= mp or P[EMP[eid].p]) and 10 or 0)
		CritD = math.random(CritD/2, CritD*1.5)
	else CritD = 0 end
	
	MKF = MKF * (Cbonus + CritD)/100
else	Cbonus = 0	CritC = 0	CritD = 0 end -- Обычные зелья, обычные яды, алтари, ловушки и прочие кастующие активаторы
if ResAt == 28 then -- Магия с позитивными эффектами
	if sot == tes3.objectType.spell and s.castType == 0 then -- Не влияет  на пост.эффекты, powers(5)
		RP = 100 - 100 * MKF
		if cf.m1 then tes3.messageBox("%s  %.1f%% spell power (%.1f bonus + %.1f crit (%.1f%%))", s.name, MKF*100, Cbonus, CritD, CritC) end
	elseif wg then
		if wg == 0 then
			if s.icon == "" and m == mp and not L.ING[s.name] then RP = G.TR.tr8 and (P.alc2 and 95 or 100) or (P.alc2 and 75 or 90)
				if cf.m1 then tes3.messageBox("%s  ingred power = %.1f for %d seconds", s.name, ef.max*(100-RP)/100, dur) end
			end
		else MKF = m == mp and (1 - math.max((D.potcd and D.potcd - 40 - M.TOX.max/(P.alc11 and 2 or 4) or 0)/M.TOX.max, 0)) * (G.TR.tr8 and 0.2 or 1) or 1			local alcsk = m:getSkillValue(16)
			RP = 0 - math.min(m.willpower.current/10,10) - alcsk/((m ~= mp or P.alc1) and 5 or 10) - (m == mp and P.alc12 and (D.potcd or 0) < math.max(40 - (P.alc9 and alcsk/10 or 0), 30) + 0.1 and 20 or 0)
			if MKF ~= 1 then RP = 100 - (100 - RP) * MKF end
			if cf.m1 then tes3.messageBox("%s  %.1f%% alchemy power   x%.2f mult   Tox = %s", s.name, 100 - RP, MKF, D.potcd) end
		end
	elseif sot == tes3.objectType.enchantment then -- Сила зачарований castType 0=castOnce, 1=onStrike, 2=onUse, 3=constant
		if s.castType ~= 3 then		RP = 100 - 100 * MKF
			if cf.m1 then tes3.messageBox("%s  %.1f%% enchant power (%.1f bonus + %.1f crit (%.1f%%))", s.id, MKF*100, Cbonus, CritD, CritC) end
		elseif t == p then		local item = si.item	local itot = item.objectType
			if W.DWM and itot == tes3.objectType.weapon then e.resistedPercent = 100 return end
			if cf.enchlim then MKF = 1
				if s.sourceMod and not L.ESP[s.sourceMod] then	local max	local summ = 0
					if itot == tes3.objectType.weapon then max = 3000 else max = (L[itot == tes3.objectType.armor and "AREN" or "CLEN"][item.slot] or 500) * 3 end
					for i, ef in ipairs(s.effects) do if ef.id ~= -1 and not ef.object.isHarmful then summ = summ + ef.cost * 1000 end end
					if summ > max then MKF = math.max(max / summ, 0.2)		RP = 100 - 100 * MKF
						if cf.m1 then tes3.messageBox("%s (%s - %s)  Const en power = %d/%d   Power = %d%%", item.name, s.id, s.sourceMod, summ, max, MKF*100) end
					end
				end
				
				if itot ~= tes3.objectType.weapon then	local snstr = tostring(sn)
					if not D.ENCO[snstr] then
						D.ENconMax = (P.enc16 and 7000 or 5000) + mp.enchant.base*30		D.ENconst = 0		for _, vol in pairs(D.ENCO) do D.ENconst = D.ENconst + vol end
						D.ENCO[snstr] = L[itot == tes3.objectType.armor and "AREN" or "CLEN"][item.slot] or 500		--item.enchantCapacity
						if D.ENconst + D.ENCO[snstr] > D.ENconMax then D.ENCO[snstr] = nil else D.ENconst = D.ENconst + D.ENCO[snstr] end
						M.PC.max = L.GetPCmax()		if M.INV then M.ENL.current = D.ENconst		M.ENL.max = D.ENconMax		M.ENL.fillColor = D.ENconst < D.ENconMax and {0,1,0} or {0,1,1}	end
						if not D.ENCO[snstr] then tes3.messageBox("%s has no effect! Enchant limit = %d / %d", item.name, D.ENconst, D.ENconMax)	e.resistedPercent = 100		tes3.playSound{sound = "Spell Failure Conjuration"}	return end
					end
				end
				if ef.min ~= ef.max and ME[eid] ~= 2 then MKF = MKF/2		RP = 100 - 100 * MKF			tes3.messageBox("Enchant power reduced by half!") end
			end
		end
	end
	if RP < 100 then
	if sc == 1 then
		if L.MEBOUND[eid] then
			--[[
			if t == p then
				if L.MeBondArm[eid] then m:unequip{armorSlot = L.MeBondArm[eid]}
				elseif L.MEBOUND[eid] == 1 then m:unequip{type = tes3.objectType.weapon}
				elseif eid == 130 then m:unequip{armorSlot = 8}		local rw = m.readiedWeapon		if rw and not WT[rw.object.type].h1 then m:unequip{type = tes3.objectType.weapon} end
				elseif eid == 131 then m:unequip{armorSlot = 6}		m:unequip{armorSlot = 7}	m:unequip{armorSlot = 9}	m:unequip{armorSlot = 10}		m:unequip{clothingSlot = 5}		m:unequip{clothingSlot = 6}
				elseif eid == 129 then m:unequip{armorSlot = 5}		m:unequip{clothingSlot = 1}
				elseif eid == 605 then m:unequip{armorSlot = 2}		m:unequip{armorSlot = 3} end
			end
			--]]
			if t == p then
				if L.MEBOUND[eid] == 1 then m:unequip{type = tes3.objectType.weapon} end
				if cf.beastarm and (eid == 128 or eid == 129) and p.object.race.isBeast then	p.object.race.isBeast = false		timer.delayOneFrame(function() p.object.race.isBeast = true end) end
			end
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100
				if t == p then ei.lastUsedArmor = nil		ei.lastUsedShield = nil		ei.lastUsedWeapon = nil	end
				--tes3ui.forcePlayerInventoryUpdate()		--tes3ui.updateInventoryTiles()
				--tes3.messageBox("last = %s", ei.lastUsedArmor and ei.lastUsedArmor.object.name) 
			end end)
		elseif L.MESUM[eid] then
			G.conjp = t == p or nil		G.summoner = t		G.conjsk = math.min(m:getSkillValue(13),200)		G.conjagr = t ~= p and R[t] or nil
			if t == p then
				if P.con11 then
					if wg == 0 and s.name == "Summon" or (sot == tes3.objectType.enchantment and s.castType == 3) then e.resistedPercent = RP
					--	G.GMSTskelet.value = "4r_skeleton"		tes3.messageBox("%s", G.GMSTskelet.value)
						
						if cf.BBen and dur > 1 and RP < 100 then L.NewBB(eid, ef.object.bigIcon, dur, sn*10 + e.effectIndex) end		return
					else tes3.applyMagicSource{reference = p, name = "Summon", effects = {{id = eid, duration = dur * (1 - RP/100)}}}
					--	G.GMSTskelet.value = TC{"skeleton archer", "skeleton champion", "skeleton warrior"}	tes3.messageBox("%s", G.GMSTskelet.value)
						e.resistedPercent = 100		return
					end
				else
					timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * RP/100 end end)
				end
			elseif N[t] then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * (100 - (100 - RP)*3)/100 end end) end
		end
	end
	if eid < 500 then
		if ME[eid] == 4 then
			if c == mp and P.res10 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * -0.2 end end) end
			if t == p then if eid == 84 then timer.delayOneFrame(L.MPUpdate) elseif eid == 82 then timer.delayOneFrame(L.STUpdate) end end
		elseif ME[eid] == 5 then
			if c == mp and P.res11 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * -0.2 end end) end
		elseif eid == 75 then
			if s.castType ~= 3 and not L.ING[s.name] then
				local mag0 = math.random(ef.min, ef.max) * (1 - RP/100) * (t == p and 1 or 3) 		local mag1 = mag0 * (c == mp and P.res6 and 0.2 or 0.1) * math.max(dur,1)
				for i, s in ipairs(L.HealStat) do if m[s].normalized < 1 then tes3.modStatistic{reference = t, name = s, current = mag1, limitToBase = true}	mag0 = mag0/2
					if cf.m2 then tes3.messageBox("%s Healing  %s +%d", t, s, mag1) end		break
				end end
				mag1 = mag0 * (c == mp and P.res13 and 2 or 1)
				tes3.applyMagicSource{reference = t, name = "Rest", effects = {{id = 77, min = mag1, max = mag1, duration = dur}}}
				if cf.m2 then tes3.messageBox("%s Rest +%d stamina - %d sec", t, mag1, dur) end
			end
		elseif L.CME[eid] or eid == 3 then	--L.nomag[eid] and 100 or 
			if L.MESLD[eid] and c == mp and P.alt28 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * -0.2 end end) end
			if eid ~= 3 then
				local mag0 = math.random(ef.min, ef.max) * math.max(dur,1)
				local mag1 = mag0 * (1 - RP/100) * L.CME[eid][3] * ((m ~= mp or P.int17) and 2 or 1)		local msi, ei
				for _, aef in pairs(m:getActiveMagicEffects{effect = L.CME[eid][1]}) do msi = aef.instance
					if msi.sourceType == 3 and msi.source.name == L.CME[eid][2] then ei = aef.effectInstance
						mag1 = mag1 - ei.magnitude * (aef.duration - ei.timeActive)
						if mag1 > 0 then msi.state = 6 else break end
					end
				end
				if eid == 57 then
					if rt == 0 or (c == mp and not R[t]) or (t == p and c and L.IsFollover(c,mp)) then
						local mag2 = mag0 * (1 - RP/100) * ((c ~= mp or P.mys18) and 3 or 2.5)
						for _, aef in pairs(m:getActiveMagicEffects{}) do if aef.harmful then msi = aef.instance
							if (msi.sourceType == 1 and msi.source.castType == 0) or (msi.sourceType == 2 and msi.source.castType < 3) then ei = aef.effectInstance
								ei.timeActive = ei.timeActive + mag2 / (ei.effectiveMagnitude * tes3.getMagicEffect(aef.effectId).baseMagickaCost)
							--	tes3.messageBox("id %s   mag %.1f  timeact %.1f", aef.effectId, ei.effectiveMagnitude, ei.timeActive)
							end
						end end
						if cf.m1 then tes3.messageBox("Dispell harmful = %.1f (%.1f%% pow)", mag2, MKF*100) end
					else
						resist = math.max(m.resistMagicka,-100)
						+ (math.min(m.endurance.current,500)/10 + math.min(m.willpower.current,500)*0.3) * ((m ~= mp or P.wil3) and 1 or 0.5) + ((m ~= mp or P.mys6) and math.min(m:getSkillValue(14),100)/10 or 0)
						if resist < 0 then RP = resist elseif m == mp or resist < 500 then RP = 100*resist/(resist+100) else RP = 100 end
						RP = 100 - (100 - RP) * MKF
						if RP < 100 then	local mag2 = mag0 * (1 - RP/100) * ((c ~= mp or P.mys19) and 3 or 2.5)
							for _, aef in pairs(m:getActiveMagicEffects{}) do if not aef.harmful then msi = aef.instance
								if aef.isSummon then ei = aef.effectInstance
									ei.timeActive = ei.timeActive + mag2 * ((c ~= mp or P.con16) and 10 or 5) / tes3.getMagicEffect(aef.effectId).baseMagickaCost
								--	tes3.messageBox("id %s   timeact %.1f", aef.effectId, ei.timeActive)
								elseif (msi.sourceType == 1 and msi.source.castType == 0) or (msi.sourceType == 2 and msi.source.castType < 3) then ei = aef.effectInstance
									ei.timeActive = ei.timeActive + mag2 / (ei.effectiveMagnitude * tes3.getMagicEffect(aef.effectId).baseMagickaCost)
								end
							end end
							if AF[t.tempData.SumR] then
								for _, aef in pairs(t.tempData.SumR.mobile:getActiveMagicEffects{}) do if aef.isSummon then ei = aef.effectInstance
									if ei.createdData.object == t then
										ei.timeActive = ei.timeActive + mag2 * ((c ~= mp or P.con16) and 20 or 10) / tes3.getMagicEffect(aef.effectId).baseMagickaCost
									end
								end end
							end
							if cf.m1 then tes3.messageBox("Dispell buffs = %.1f (%.1f%% pow)  Summoner = %s", mag2, 100 - RP, t.tempData.SumR) end
						end
					end
					e.resistedPercent = 100		return
				elseif eid == 72 then	-- Противоядие
					for _, aef in pairs(m:getActiveMagicEffects{effect = 27}) do ei = aef.effectInstance
						ei.timeActive = ei.timeActive + 30 * (1 - RP/100) / ei.effectiveMagnitude
					end					
					e.resistedPercent = 100		return
				elseif eid == 73 then	-- Антипаралич
					for _, aef in pairs(m:getActiveMagicEffects{}) do if aef.effectId == 45 or aef.effectId == 46 then ei = aef.effectInstance
						ei.timeActive = ei.timeActive + 5 * (1 - RP/100)
					end end					
					e.resistedPercent = 100		return			--timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.state = 6 end end)
				end
			end
		elseif eid == 10 then	-- Левитация
			if rt ~= 0 and t ~= p then
				resist = RP + math.max(m.resistMagicka,-100) + m.willpower.current + m:getSkillValue(14)/2
				if cf.m then tes3.messageBox("%s  %.1f%% levitation resist", s.name or s.id, resist) end		if resist >= math.random(100) then RP = 100 end
			end
		elseif eid == 39 then	-- Невидимость
			if t == p and s.name ~= "Blur" then
				if P.ill10 and RP < 0 then tes3.applyMagicSource{reference = p, name = "Blur", effects = {{id = 39, duration = dur * (1 - RP/100 + (P.ill17 and 0.2 or 0))}, 
					{id = 40, min = -RP/4, max = -RP/2, duration = dur}}}
				else timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * (RP/100 - (P.ill17 and 0.2 or 0)) end end) end
			end
		elseif eid == 118 or eid == 119 then	-- Приказы	e.resistAttribute == 28
			local kind = L.CRNIF[t.baseObject.mesh:lower()]		kind = kind and kind.kind
			if (s.id == "BM_summonwolf" and kind == "wolf") or (s.id == "BM_summonbear" and kind == "bear") then RP = -2000
			else
				resist = math.max(m.resistMagicka,0) + (m.willpower.current + m:getSkillValue(14))*(P.ill9 and 0.5 or 1)
				RP = math.min(120*resist/(resist+100),100)
				RP = 100 - (100 - RP) * MKF
			end
			if cf.m then tes3.messageBox("%s  %.1f%% (%d) mind control resist", s.name or s.id, RP, resist) end
			if RP < 100 and R[t] then timer.start{duration = 0.1, callback = function() if tes3.isAffectedBy{reference = t, effect = eid} then R[t] = nil if cf.m4 then tes3.messageBox("CONTROL! %s", t) end end end} end
		elseif eid == 60 and t == p then	-- Пометка
			local mmax = (1 + mp.willpower.base/200 + mp.intelligence.base/100 + mp.alteration.base/200 + mp.mysticism.base/50) * (P.mys11 and 2 or 1)
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
		--	if eid == 61 then end	-- Возврат
		elseif eid == 13 and P.mys23 then	-- Взлом замков
			if t.lockNode and t.lockNode.trap then	local pow = math.random(ef.min, ef.max) * (1 - RP/100) 
			--	tes3.messageBox("Power = %d   Trap = %d", pow, t.lockNode.trap.magickaCost * 4)
				if pow > t.lockNode.trap.magickaCost * 4 then t.lockNode.trap = nil 	tes3.playSound{reference = t, sound = "Disarm Trap"} end
			end
		end
	else	if L.EDAT[eid] then L.EUPD(t, eid) end
		if eid == 501 and AF[t].T501 == nil then -- Перезарядка зачарованного (501)			attempt to index a nil value  связано с багом одеваия призванных вещей с зачаром при загрузке сейва
			if t == p then AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = L.RechargeTik} 	G.REI = {}
			else AF[t].T501 = timer.start{duration = 1, iterations = -1, callback = function(te) if not AF[t] then te.timer:cancel() else L.RechargeNPC(m, t, te) end end} end
		elseif eid == 502 and AF[t].T502 == nil then -- Починка оружия (502)
			AF[t].T502 = timer.start{duration = 1, iterations = -1, callback = function(te) if not AF[t] then te.timer:cancel() else L.RepairWTik(m, t, te) end end}
		elseif eid == 503 and AF[t].T503 == nil then -- Починка брони (503)
			AF[t].T503 = timer.start{duration = 1, iterations = -1, callback = function(te) if not AF[t] then te.timer:cancel() else L.RepairATik(m, t, te) end end}
		elseif L.MECW[eid] then t.data.CW = true	-- Зарядить оружие. Эффекты 511, 512, 513, 514, 515
		elseif L.MEEMP[eid] then t.data.Emp = true
		elseif L.MEAUR[eid] and t == p then D.AUR = true
			if not T.AUR.timeLeft then T.AUR = timer.start{duration = P.wil35 and math.max(3 - mp:getSkillValue(11)/200, 2.5) or 3, iterations = -1, callback = L.AuraTik} end
			local mag1 = math.random(ef.min, ef.max) * dur * (1 - RP/100) * L.CME[eid][3] * ((m ~= mp or P.int17) and 2 or 1)		local msi, ei
			for _, aef in pairs(m:getActiveMagicEffects{effect = L.CME[eid][1]}) do msi = aef.instance
				if msi.sourceType == 3 and msi.source.name == L.CME[eid][2] then ei = aef.effectInstance
					mag1 = mag1 - ei.magnitude * (aef.duration - ei.timeActive)
					if mag1 > 0 then msi.state = 6 else break end
				end
			end
		elseif eid == 601 and t == p then	if m.readiedWeapon then BAM.am = BAM[m.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
			if mwscript.getItemCount{reference = t, item = BAM.am} == 0 and BAM.f() then tes3.addItem{reference = t, item = BAM.am, count = 100, playSound = false}	m:equip{item = BAM.am} end
		elseif eid == 510 and t == p then 	-- not T.TS.timeLeft then event.register("simulate", SIMTS)	-- Замедление времени (510)
			timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	L.UpdTSK()		if ei and dur > 0 then ei.timeActive = dur * (1 - TSK) end end)
		elseif eid == 504 and t == p then	-- Магический фонарь
			timer.delayOneFrame(function() L.LigUpd() end)
		end
	end
	end
elseif wg or rt ~= 0 then	local IsPois		-- Любые негативные эффекты с дальностью касание и удаленная цель ИЛИ пвсевдоалхимия ИЛИ обычные яды ИЛИ ингредиенты ИЛИ соурс таблицы
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
		if m ~= mp and c and R[t] and R[cas] then		-- Если враг игрока задел врага игрока то всё кроме дамажных эффектов обнуляется
			if EMP[eid] then MKF = MKF/2 else e.resistedPercent = 0	return end
		end
		
		RFM = t.data.e507 or 0
		if RFM > 0 then RFM = RFM * ((m ~= mp or P.mys14) and 1.2 or 1)
			if t.data.RFsn ~= sn and (m ~= mp or DM.refl) and (not COL[sn] or COL[sn]:distance(t.position + tes3vector3.new(0,0,m.height*0.7)) < 100) then
				t.data.RFsn = sn
				local pow = 0
				for i, eff in ipairs(s.effects) do if eff.id ~= -1 and eff.rangeType ~= 0 then pow = pow + (eff.min + eff.max) * eff.object.baseMagickaCost * math.max(eff.duration,1)/20 end end
				pow = pow * MKF		mc = pow * (m == mp and (P.int37 and 2 or 2.5) or 1)
				if RFM > pow and m.magicka.current > mc then	local rad = L.GetRad(m)		local E = B.RFS.effects			B.RFS.value = math.ceil(mc*5)
					for i, eff in ipairs(s.effects) do if eff.rangeType ~= 0 then	E[i].id = eff.id	E[i].radius = math.min(eff.radius, rad)		E[i].duration = eff.duration
					E[i].min = eff.min	E[i].max = eff.max	E[i].rangeType = eff.rangeType		E[i].attribute = eff.attribute		E[i].skill = eff.skill	else E[i].id = -1	E[i].rangeType = 0 end end
					tes3.applyMagicSource{reference = t, source = B.RFS}		Mod(mc,m)		
					if cf.m then tes3.messageBox("Reflect = %.1f / %.1f  Cost = %.1f  Radius = %.1f", RFM, pow, mc, rad) end	--t.data.RFbal = true		
					SN[sn] = 0		e.resistedPercent = 100		si.state = 7	return
				elseif cf.m then tes3.messageBox("Fail! Reflect = %.1f  Power = %.1f", RFM, pow) end
			end
		end
		if EMP[eid] then RFM = RFM + (t.data[EMP[eid].rf] or 0) * ((m ~= mp or P.mys14) and 2.4 or 2) end
		if RFM > 0 and m == mp and D.MSEF["e"..eid] then RFM = 0 end
	end
	
	local Epow = (ef.min + ef.max)/2 * math.max(dur,1)		local Tarmor, Tbonus, SecK
	local NormR = math.max(m[L.RES[eid] or (IsPois and "resistPoison" or "resistMagicka")],-100)		
	
	if EMP[eid] then
		SecK = (c == mp and (P.wil14 and 1.33334 or 1) * (P[EMP[eid].p1] and 1.5 or 1) or 2) * (m == mp and (P.end19 and 0.75 or 1) * (P[EMP[eid].p2] and 0.66667 or 1) or 1)
		
		if ME[eid] == 1 then Tarmor = m == mp and D.AR.elr or m.armorRating/5		local rsh = m.readiedShield
			if c == mp and ((P.mys9 and m.object.type == 1) or (P.res9 and m.object.type == 2)) then MKF = MKF * 1.1 end		-- Расовый урон
			Tbonus = (math.min(m.endurance.current,500)/5 + math.min(m.willpower.current,500)/5) * ((m ~= mp or P[EMP[eid].p3]) and 1 or 0.5) + ((m ~= mp or P.des9) and math.min(m:getSkillValue(10),100)/10 or 0)
			if rsh and (m ~= mp or mp.actionData.animationAttackState == 2) then Tarmor = Tarmor + m:getSkillValue(0) * ((m ~= mp or P.bloc7) and 0.4 or 0.2)
				rsh.variables.condition = math.max(rsh.variables.condition - math.random(ef.min, ef.max) * math.max(dur,1) * MKF/2, 0)
				if m == mp then L.UpdShield(rsh) end		if rsh.variables.condition < 0.1 then m:unequip{item = rsh.object} end
			end
			resist = NormR + Tarmor + Tbonus
			if resist < 0 then RP = resist elseif m == mp or resist < 500 then RP = 100*resist/(resist+100) else RP = resist > 700 and m.health.normalized < 1 and math.min(resist - 600, 150) or 100 end
			RP = 100 - (100 - RP) * MKF
			if cf.m1 then tes3.messageBox("%s  %.1f%% %s resist  %.1f = %.1f norm + %.1f target + %.1f armor  Power = %.1f%% (%.1f caster + %.1f crit (%.1f%%))",
			s.name or s.id, RP, EMP[eid].txt, resist, NormR, Tbonus, Tarmor, MKF*100, Cbonus, CritD, CritC) end
			if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * 3) end	--ef.object.baseMagickaCost
		end
	end

	if eid == 14 then
		if RP < 100 then
			local magr = math.random(ef.min, ef.max) * (1 - RP/100) * SecK
			local hs = 500 * magr/math.max(m.health.base,100)		
			if hs * math.max(dur,1) > math.random(100) then m:hitStun() end
			if cf.m2 then  tes3.messageBox("%s  Burning = %.1f - %d s (%d%%)    HS = %d%%", t.object.name, magr, dur, SecK*100, hs * math.max(dur,1)) end
			if dur > 1 then
			--	local sn2 = SETAB[t.id .. s.id]		if sn2 then sn2 = tes3.getMagicSourceInstanceBySerial{serialNumber = sn2}	if sn2 then sn2.state = 6 end	end		-- Предотвратить стак дотов
				tes3.applyMagicSource{reference = t, name = "Burning", effects = {{id = 34, min = hs, max = hs, duration = dur}}}
				if AF[t].THS == nil then
					AF[t].THS = timer.start{duration = 1.5, iterations = -1, callback = function(te) if AF[t] then	local mag = m.resistCorprus	--Mag(34,t)
						if mag < 0 then
							if -mag > math.random(100) then m:hitStun() end
							if cf.m2 then tes3.messageBox("%s  Pain = %d%%", t.object.name, -mag) end
						else te.timer:cancel()	AF[t].THS = nil end
					else te.timer:cancel() end end}
				end
			end
		end
	elseif eid == 16 then
		if RP < 100 then
			local magr = math.random(ef.min, ef.max) * (1 - RP/100) * SecK
			if cf.m2 then  tes3.messageBox("%s  Freeze = %.1f - %d s (%d%%)  Burden = %d", t.object.name, magr, dur, SecK*100, dur < 2 and 0 or 1000*magr/math.max(m.health.base,100)) end
			if dur < 2 then
				if m.fatigue.current > 0 then m.fatigue.current = math.max(m.fatigue.current - magr, 0) end
			else
				local Burd = 1000*magr/math.max(m.health.base,100)
				tes3.applyMagicSource{reference = t, name = "Freeze", effects = {{id = 25, min = magr, max = magr, duration = dur},{id = 7, min = Burd, max = Burd, duration = dur}}}
			end

		end
	elseif eid == 15 then
		if RP < 100 then
			local magr = math.random(ef.min, ef.max) * (1 - RP/100) * SecK
			if cf.m2 then  tes3.messageBox("%s  Electroshock = %.1f - %d s (%d%%)", t.object.name, magr, dur, SecK*100) end
			if dur < 2 then
				Mod(math.min(m.magicka.current, magr), m)
			else
				local hs = 500 * magr/math.max(m.health.base,100)	
				tes3.applyMagicSource{reference = t, name = "Electroshock", effects = {{id = 34, min = hs, max = hs, duration = dur},{id = 24, min = magr, max = magr, duration = dur}}}
				if AF[t].THS == nil then
					AF[t].THS = timer.start{duration = 1.5, iterations = -1, callback = function(te) if AF[t] then	local mag = m.resistCorprus	--Mag(34,t)
						if mag < 0 then
							if -mag > math.random(100) then m:hitStun() end
							if cf.m2 then tes3.messageBox("%s  Pain = %d%%", t.object.name, -mag) end
						else te.timer:cancel()	AF[t].THS = nil end
					else te.timer:cancel() end end}
				end
			end
		end
	elseif eid == 27 then
		Tbonus = (math.min(m.endurance.current,100)*0.3 + math.min(m.willpower.current,100)/10) * ((m ~= mp or P[EMP[eid].p3]) and 1 or 0.5) + ((m ~= mp or P.alc10) and math.min(m:getSkillValue(16),100)/10 or 0)
		resist = NormR + Tbonus
		if resist < 0 then RP = resist elseif m == mp or resist < 500 then RP = 100*resist/(resist+100) else RP = 100 end
		RP = 100 - (100 - RP) * MKF	
		if cf.m1 then tes3.messageBox("%s  %.1f%% poison resist  %.1f = %.1f norm + %.1f target  Power = %.1f%% (%.1f caster + %.1f crit (%.1f%%))",
		s.name or s.id, RP, resist, NormR, Tbonus, MKF*100, Cbonus, CritD, CritC) end
		if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
		if RP < 100 then
			local magr = math.random(ef.min, ef.max) * (1 - RP/100) * SecK
			if cf.m2 then  tes3.messageBox("%s  Poisoning = %.1f - %d s (%d%%)  Weakening = %d", t.object.name, magr*1.5, dur, SecK*100, dur < 2 and 0 or 500*magr/math.max(m.health.base,100)) end
			
			if dur < 2 then
				if m.fatigue.current > 0 then m.fatigue.current = math.max(m.fatigue.current - magr*1.5, 0) end
			else
				local mag2 = 500*magr/math.max(m.health.base,100)
				tes3.applyMagicSource{reference = t, name = "Poisoning", effects = {{id = 25, min = magr*1.5, max = magr*1.5, duration = dur},
				{id = 17, attribute = math.random(0,5), min = mag2, max = mag2, duration = dur}, {id = 17, attribute = math.random(0,5), min = mag2, max = mag2, duration = dur}}}
			end
		end
	else
		Tbonus = (math.min(m.endurance.current,500)/10 + math.min(m.willpower.current,500)*0.3) * ((m ~= mp or P.wil3) and 1 or 0.5) + ((m ~= mp or P.mys6) and math.min(m:getSkillValue(14),100)/10 or 0)
		if eid == 45 or eid == 46 then		-- Паралич и молчание считаем отдельно
			local Extra = m:getSkillValue(12) * ((m ~= mp or P.ill6) and 0.5 or 0.2) > math.random(100) and math.max(300 - m.paralyze * 100, 0) or 0
			resist = NormR + m.resistParalysis + Tbonus + Extra		--tes3.isAffectedBy{reference = t, effect = 73} and 1000 or 
			if resist < 0 then RP = resist elseif resist < 500 then RP = 100*resist/(resist+100) else RP = 100 end
			RP = 100 - (100 - RP) * MKF
			if cf.m1 then tes3.messageBox("%s  %.1f%% paralysis resist  %.1f = %.1f paral + %.1f magic + %.1f target + %d extra  Power = %.1f%% (%.1f caster + %.1f crit (%.1f%%))",
			s.name or s.id, RP, resist, m.resistParalysis, NormR, Tbonus, Extra, MKF*100, Cbonus, CritD, CritC) end
			if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
			if RP >= 100 then RP = 100 else
				timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * (RP/100 - ((c ~= mp or P.ill18) and 0.1 or 0)) end end)
			end
		elseif eid == 55 or eid == 56 then		-- Ралли
			if P.per9 then MKF = MKF * 1 + mp.personality.current/500 end		RP = 100 - 100 * MKF		
			local min = ef.min * MKF		local max = ef.max * MKF		local k1 = P.ill14 and 1 or 0.5		local k2 = P.ill15 and 0.02 or 0	local k3 = P.ill16 and 0.05 or 0
			--local atr = math.random(0,5)	--if atr == 4 and m.actorType == 0 and not m.object.biped then k1 = k1/3 end
			tes3.applyMagicSource{reference = t, name = "Rally", effects = {{id = 79, min = min*k1, max = max*k1, attribute = math.random(0,5), duration = dur},
			{id = 77, min = min*k1/2, max = max*k1/2, duration = dur}, {id = 75, min = min*k2, max = max*k2, duration = dur}, {id = 76, min = min*k3, max = max*k3, duration = dur}}}
			if cf.m1 then tes3.messageBox("%s  %.1f%% Rally power (%.1f bonus + %.1f crit (%.1f%%))", s.name or s.id, MKF*100, Cbonus, CritD, CritC) end
		else	-- Всё остальное негативное кроме паралича и ралли
			if L.DurKF[eid] and (c ~= mp or P.int9) and dur > 1 then Tbonus = Tbonus - 3 * (dur - 1)^0.5 end
			resist = NormR + Tbonus
			if resist < 0 then RP = resist elseif m == mp or resist < 500 then RP = 100*resist/(resist+100) else RP = 100 end
			RP = 100 - (100 - RP) * MKF
			if cf.m1 then tes3.messageBox("%s  %.1f%% magic resist  %.1f = %.1f norm + %.1f target  Power = %.1f%% (%.1f caster + %.1f crit (%.1f%%))",
			s.name or s.id, RP, resist, NormR, Tbonus, MKF*100, Cbonus, CritD, CritC) end
			if RP < 100 and RFM > 0 then RP = L.MSF(RP, RFM, m, Epow * (1 - RP/100) * ef.object.baseMagickaCost) end
			if RP < 100 then
				if eid == 23 then	-- Урон хаосом
					local magr = math.random(ef.min, ef.max) * (1 - RP/100) * SecK
					local mag2 = 100*magr/math.max(m.health.base,100) 
					if cf.m2 then  tes3.messageBox("%s  Decay = %.1f - %d s (%d%%)  Exhaustion = %.1f", t.object.name, mag2, dur, SecK*100, dur < 2 and 0 or magr) end
					
					if dur < 2 then	
						tes3.modStatistic{reference = t, attribute = math.random(0,5), current = -mag2}
					else
						if mag2 > 0.5 then tes3.applyMagicSource{reference = t, name = "Decay", effects = {{id = 25, min = magr, max = magr, duration = dur},{id = 22, attribute = math.random(0,5), min = mag2, max = mag2, duration = dur}}}
						else tes3.applyMagicSource{reference = t, name = "Decay", effects = {{id = 25, min = magr, max = magr, duration = dur}}}
							tes3.modStatistic{reference = t, attribute = math.random(0,5), current = -mag2*dur}
						end
					end
				elseif ME[eid] == 6 then	-- Понижения статов
					if eid == 20 and m.health.normalized > 0.2 then	-- Уменьшить стамину
						local RedK = (m.fatigue.current - 1) / (ef.max * (1 - RP/100))
						if RedK < 1 then RP = 100 - (100 - RP) * RedK end
					end
					if RP < 100 then
						if t == p and P.res12 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * 0.25 end end)
						elseif c == mp and P.des10 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * -0.5 end end) end
					end
				elseif ME[eid] == 7 then	-- Резисторезы
					if t == p and P.res12 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, p)	 if ei then ei.timeActive = dur * 0.25 end end)
					elseif c == mp and P.des11 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * -0.5 end end) end
				elseif L.MEABS[eid] then	-- Поглощения
					if eid == 85 then
						local AbsK = m.attributes[ef.attribute+1].current / ((ef.min + ef.max)/2 * (1 - RP/100))
						if AbsK < 1 then RP = 100 - (100 - RP) * AbsK end
						if c == mp and P.mys24 and RP < 100 then timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 if ei then ei.timeActive = dur * -0.25 end end) end
					else
						local AbsK = m[L.MEABS[eid]].current / (Epow * (1 - RP/100))
						if AbsK < 1 then RP = 100 - (100 - RP) * AbsK end
						if eid == 87 and RP < -100 then RP = -100 end
					end
				elseif eid == 51 or eid == 52 then		-- Френзи
					local koef = 1 - RP/100		local mag = math.random(ef.min, ef.max) * dur		local rad = mag * (P.ill12 and 2 or 1)		local mag0 = 0	local ei
					for _, aef in pairs(m:getActiveMagicEffects{effect = m.actorType == 0 and 52 or 51}) do ei = aef.effectInstance
						mag0 = mag0 + ei.effectiveMagnitude * (aef.duration - ei.timeActive)
					end
					local pow = (mag * koef + mag0) * (P.ill11 and 1.25 or 1)			local minp = 1000 + t.object.level*100
					if P.ill14 then tes3.applyMagicSource{reference = t, name = "Rally", effects = {{id = 117, min = ef.min*koef, max = ef.max*koef, duration = dur}}} end
					if pow > minp then	m.actionData.aiBehaviorState = 3
						if P.ill13 then		for _, mob in pairs(tes3.findActorsInProximity{reference = t, range = rad}) do if mob ~= m then m:startCombat(mob) end end
						else	local tar, dist		local md = rad
							for _, mob in pairs(tes3.findActorsInProximity{reference = t, range = rad}) do if mob ~= m then dist = t.position:distance(mob.position)	if dist < md then md = dist		tar = mob end end end
							if tar then m:startCombat(tar) end
						end
					end
					if cf.m then tes3.messageBox("%s Frenzy! power = %d/%d  rad = %d   mag0 = %d", t, pow, minp, rad, mag0) end
				elseif eid == 49 or eid == 50 then	-- Calm
					local pow = math.random(ef.min, ef.max) * (1 - RP/100) * (P.ill20 and 1.5 or 1)	local minp = math.max(t.object.aiConfig.fight/2 + t.object.level * (P.per10 and 5 or 10), 50)
					if pow > minp then	if R[t] then R[t] = nil		if cf.m4 then tes3.messageBox("CALM! %s", t) end end	else RP = 100 end
					if cf.m then tes3.messageBox("%s Calm! power = %d/%d  basefight = %d", t, pow, minp, t.object.aiConfig.fight) end
				end
			end
		end
	end
else 	-- Любые негативные эффекты с дальностью на себя, включая постоянные и баффо-дебаффы и болезни, будут действовать на 100% силы.
	if t ~= p and L.DISTYP[s.castType] then RP = 99		-- Болезни всё ещё висят на существах, но их магнитуда равна 1%
	else RP = 0 end
	--tes3.messageBox("%s  -  %s  id = %s    RP = %s", t.id, s.name or s.id, eid, RP)
end
e.resistedPercent = RP

if t == p then 	if cf.BBen and dur > 1 and RP < 100 then L.NewBB(eid, ef.object.bigIcon, dur, sn*10 + e.effectIndex) end
end


-- Команда state = 6 завершает спелл правильно. state = 7 тоже завершает спелл, но например для повышения сопротивлений не удаляет сам стат сопротивления на мобильнике

--timer.delayOneFrame(function() local ei = si:getEffectInstance(e.effectIndex, t)	 
--tes3.messageBox("%s  id = %s  time = %.3f/%d   Respr = %.2f   mag = %d  Cummag = %d", s.name or s.id, eid, ei.timeActive, dur, ei.resistedPercent, ei.magnitude, ei.cumulativeMagnitude) end)
--if m == mp and SSN[sn] then tes3.getMagicSourceInstanceBySerial{serialNumber = sn}.state = 6	tes3.messageBox("Resist! SNum = %s", sn) SSN[sn] = nil end	-- устраняем эксплойт с разгоном статов
-- e.effectInstance ещё не полностью построена во время эвента. Далее она меняется на полноценный effectInstance которые НЕ равен предыдущему и может быть получен из активных эффектов
end		event.register("spellResist", SPELLRESIST)

L.ERIDF = {[504] = L.LigUpd, [510] = L.UpdTSK, [84] = L.MPUpdate, [82] = L.STUpdate}
local function MAGICEFFECTREMOVED(e)	--local m, r, c, t, si, s, ei, ind = e.mobile, e.reference, e.caster, e.target, e.sourceInstance, e.source, e.effectInstance, e.effectIndex
local id = e.effect.id		local r = e.reference
if L.EDAT[id] then L.EUPD(r, id) end

if r == p then
	if L.ERIDF[id] then timer.delayOneFrame(L.ERIDF[id]) end
	local B = M.BB[id]	local Sn = e.sourceInstance.serialNumber			local sn = Sn * 10 + e.effectIndex
	if B and B[sn] then B[sn]:destroy()		B[sn] = nil		
		if table.size(B) == 2 then	B.bl:destroy()	M.BB[id] = nil end
	end
	
	local snstr = tostring(Sn)
	if D.ENCO[snstr] then D.ENCO[snstr] = nil
		D.ENconst = 0		for _, vol in pairs(D.ENCO) do D.ENconst = D.ENconst + vol end
		M.PC.max = L.GetPCmax()
		if M.INV then M.ENL.current = D.ENconst		M.ENL.fillColor = D.ENconst < D.ENconMax and {0,1,0} or {0,1,1}	end
	end
end
--tes3.messageBox("%s - %s (%s)  id = %s (%s)  Mag = %.2f", r, s.id, si.serialNumber, id, ind+1, ei.magnitude * (100 - ei.resistedPercent)/100)
end		event.register("magicEffectRemoved", MAGICEFFECTREMOVED)


local AOE = {}	local RUN = {}	local TOT = {}	-- АОЕ (521-525)	РУНЫ (526-530)		ТОТЕМЫ (551-555)			1 ft = 22.1 units
L.RunExp = function(n) local E = B.RUN.effects		local t = RUN[n]		--tes3.messageBox("Rune %d  exploded  id = %s", n, t.s.effects[1].id)
	for i, ef in ipairs(t.ef) do if ef.id > -1 then E[i].id = ef.id		E[i].min = ef.min	E[i].max = ef.max	E[i].duration = ef.duration		E[i].radius = ef.radius		E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.RUN}] = {pos = t.r.position + tes3vector3.new(0,0,50), exp = true}		t.r:delete()	RUN[n] = nil
end
L.TotExp = function(n) local E = B.TOT.effects		local t = TOT[n]
	if t.dur > 9 then	for i, ef in ipairs(t.ef) do if ef.id > -1 then E[i].id = ef.id		E[i].min = ef.min	E[i].max = ef.max	E[i].radius = ef.radius		E[i].duration = 0	E[i].rangeType = 2
	else E[i].id = -1	E[i].rangeType = 0 end end
	MP[tes3.applyMagicSource{reference = p, source = B.TOT}] = {pos = t.r.position:copy(), exp = true} end		t.r:delete()	TOT[n] = nil
end

local function AOEcol(e) local cp = e.collision.point	if math.abs(cp.x) < 9000000 and e.sourceInstance.caster == p then local n	local s = e.sourceInstance.source		local ef = s.effects[e.effectIndex + 1]
local alt = mp:getSkillValue(11)		local koef = SN[e.sourceInstance.serialNumber] or 1		tes3.getObject(L.AoEmod[ef.id]).radius = ef.radius * 50
local r = tes3.createReference{object = L.AoEmod[ef.id], position = cp + tes3vector3.new(0,0,10), cell = p.cell, scale = math.min(ef.radius * (P.alt42 and 0.075 + alt/4000 or 0.075), 9.99)}	r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.int21 and 20 or 40))		for i = 1, max do if not AOE[i] then n = i break end end
if not n then n = 1	local md = AOE[1].tim		for i, t in pairs(AOE) do if t.tim < md then md = t.tim		n = i end end end
if AOE[n] then AOE[n].r:delete()	AOE[n] = nil end
AOE[n] = {r = r, tim = ef.duration, id = L.MEAOE[ef.id], min = ef.min * koef, max = ef.max * koef}
if cf.m10 then  tes3.messageBox("AoE %d/%d  Power = %d%%  Scale = %.2f  Time: %d", n, max, koef*100, AOE[n].r.scale, AOE[n].tim) end
if not T.AoE.timeLeft then local dur = P.wil36 and math.max(2 - alt/200, 1.5) or 2	T.AoE = timer.start{duration = dur, iterations = -1, callback = function() local fin = true		local E = B.AOE.effects[1]
	for i, t in pairs(AOE) do	t.tim = t.tim - dur		if t.tim > 0 then	fin = false		E.id = t.id		E.min = t.min	E.max = t.max	E.duration = 2
		for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = 300 * t.r.scale}) do if m ~= mp then
			SNC[(tes3.applyMagicSource{reference = m.reference, source = B.AOE}).serialNumber] = mp		L.CrimeAt(m)
		end end
	else t.r:delete()	AOE[i] = nil end end		if fin then T.AoE:cancel()	if cf.m10 then tes3.messageBox("All AoE ends") end end
end} end
end end

local function RUNcol(e) if G.RunSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 then	local n		local s = e.sourceInstance.source
local ef = s.effects[e.effectIndex + 1]		G.RunSN = e.sourceInstance.serialNumber		local koef = SN[G.RunSN] or 1	local alt = mp:getSkillValue(11)	local radk = 1 + L.GetRad(mp)/40
local vel = e.sourceInstance.projectile.velocity		
local hit = tes3.rayTest{position = cp - vel:normalized()*100, direction = vel, returnNormal = true}
local r = tes3.createReference{object = "4nm_rune", position = cp + tes3vector3.new(0,0,5), orientation = hit and L.GetOri(V.up, hit.normal), cell = p.cell, scale = math.min(ef.radius * 0.16 * radk, 9.99)}
local light = niPointLight.new()	light:setAttenuationForRadius(ef.radius/2)		light.diffuse = L.LID[ef.id]	--tes3vector3.new(ef.object.lightingRed, ef.object.lightingGreen, ef.object.lightingBlue)
r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.int22 and 20 or 40))		for i = 1, max do if not RUN[i] then n = i break end end
if not n then n = 1	local md = RUN[1].tim		for i, t in pairs(RUN) do if t.tim < md then md = t.tim		n = i end end	L.RunExp(n) end
local E = {{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1}}
for i, ef in ipairs(s.effects) do if L.MERUN[ef.id] then E[i].id = L.MERUN[ef.id]	E[i].min = ef.min * koef	E[i].max = ef.max * koef	E[i].duration = ef.duration		E[i].radius = ef.radius * radk end end
RUN[n] = {r = r, ef = E, tim = (100 + alt + mp:getSkillValue(14))*(P.wil34 and 0.4 or 0.2)}
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
local light = niPointLight.new()	light:setAttenuationForRadius((1 + ef.radius/50)*3)		light.diffuse = L.LID[ef.id]
r.sceneNode:attachChild(light)		light:propagatePositionChange()		r:getOrCreateAttachedDynamicLight(light, 0)		r.modified = false
local max = math.ceil((50 + mp.intelligence.current/2 + alt)/(P.int23 and 20 or 40))		for i = 1, max do if not TOT[i] then n = i break end end
if not n then n = 1	local md = TOT[1].tim		for i, t in pairs(TOT) do if t.tim < md then md = t.tim		n = i end end	L.TotExp(n) end
local E = {{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1},{id=-1}}		mc = 0
for i, ef in ipairs(s.effects) do if L.METOT[ef.id] and tdur <= ef.duration then E[i].id = L.METOT[ef.id]	E[i].min = ef.min * koef	E[i].max = ef.max * koef	E[i].radius = ef.radius
mc = mc + (E[i].min + E[i].max)	* L.METOTc[ef.id] * (P.int36 and 0.04 or 0.05) * (1+E[i].radius^2/(10*E[i].radius+200)) end end
TOT[n] = {r = r, ef = E, tim = tdur, dur = tdur, mc = mc}
if cf.m10 then  tes3.messageBox("Totem %d/%d  Power = %d%%  Cost = %.1f  Scale = %.2f  Time: %d", n, max, koef*100, TOT[n].mc, TOT[n].r.scale, TOT[n].tim) end
if not T.Tot.timeLeft then local dur = P.wil38 and math.max(2 - alt/200, 1.5) or 2		T.Tot = timer.start{duration = dur, iterations = -1, callback = function()	local BE = B.TOT.effects
	local fin = true	local maxdist = (100 + mp.intelligence.current + alt + mp:getSkillValue(14)) * (P.mys41 and 20 or 10)		local tar, pos, fpos, mindist, dist		local McK = L.MCOST(2)
	for i, t in pairs(TOT) do	t.tim = t.tim - dur		if t.tim > 0 then	fin = false
		if not D.Totdis and AC[t.r.cell] and PMP.current > t.mc * McK then fpos = nil	mindist = maxdist
			for _, m in pairs(tes3.findActorsInProximity{position = t.r.position, range = maxdist}) do if m ~= mp and (cf.agr or R[m.reference]) and tes3.getCurrentAIPackageId(m) ~= 3 then 
				pos = m.position + tes3vector3.new(0,0,m.height/2)		dist = t.r.position:distance(pos)
				if dist < mindist and tes3.testLineOfSight{position1 = t.r.position, position2 = pos} then mindist = dist	tar = m		fpos = pos end
			end end
			if fpos then
				for i, ef in ipairs(t.ef) do if ef.id > -1 then BE[i].id = ef.id	BE[i].min = ef.min		BE[i].max = ef.max		BE[i].radius = ef.radius	BE[i].duration = 0	BE[i].rangeType = 2
				else BE[i].id = -1	BE[i].rangeType = 0 end end
				MP[tes3.applyMagicSource{reference = p, source = B.TOT}] = {pos = t.r.position:copy(), vel = (fpos - t.r.position):normalized()}
				Mod(t.mc * McK)		if cf.m10 then tes3.messageBox("Totem %s   Target = %s   Manacost = %.1f", i, tar.object.name, t.mc * McK) end
			end
		end
	else L.TotExp(i) end end	if fin then T.Tot:cancel()	if cf.m10 then tes3.messageBox("All totems ends") end end
end} end
end end end

local function WAVcol(e) if G.WavSN ~= e.sourceInstance.serialNumber then	local cp = e.collision.point	if math.abs(cp.x) < 9000000 and e.sourceInstance.caster == p then
	G.WavSN = e.sourceInstance.serialNumber		local pr = e.sourceInstance.projectile		local t = CPR[pr.reference]	--local n	local s = e.sourceInstance.source		local ef = s.effects[e.effectIndex + 1]
	for i, ef in ipairs(t.ef) do if L.MEWAV[ef.id] then G.WAV[i].id = L.MEWAV[ef.id]	G.WAV[i].min = ef.min*t.k*(1-(t.num-1)/t.max)		G.WAV[i].max = ef.max*t.k*(1-(t.num-1)/t.max)	--bad argument #1 to 'ipairs' (table expected, got nil)
	G.WAV[i].radius = ef.radius + t.num/(P.alt43 and 1 or 2)		G.WAV[i].duration = ef.duration		G.WAV[i].rangeType = 2	else G.WAV[i].id = -1	G.WAV[i].rangeType = 0 end end			
	MP[tes3.applyMagicSource{reference = p, source = B.WAV}] = {pos = cp - pr.velocity:normalized()*100, exp = true}
end end end


local function enterFrame(e) if not e.menuMode and MB[1] == 128 then	-- Эвент закомменчен
	mp.velocity = tes3.getPlayerEyeVector() * 2000
end end		--event.register("enterFrame", enterFrame)


L.KIK = function() if mp.hasFreeAction and mp.paralyze < 1 then	local climb, foot, r, m		local dist = 1000	local maxd = 50 + math.min(mp.agility.current/2, 50)
local ClAb = mp.velocity:length()~=0 and not G.dfr		local cldist = maxd + (P.acr9 and 20 or 0)		local kikdist = maxd + (P.hand11 and 20 or 0)

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
	if mob ~= mp and mob.playerDistance < md and math.abs(mp:getViewToActor(mob)) < (P.hand21 and 100 or 45) then md = mob.playerDistance		m = mob end end
	if m then dist = md		r = m.reference		vdir = (r.position - pp):normalized() end
end
	

if dist <= maxd then
if ClAb then	local s = mp:getSkillValue(20)		local stc = math.max(20 + G.ENC*(P.atl6 and 20 or 30) - (P.acr11 and s/10 or 0), 10)
	if PST.current > stc then local ang = 0
		if mp.isMovingForward then if foot then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end else V.d = V.up end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 else V.d = V.up end
		if V.d ~= V.up then Matr:toRotationZ(math.rad(ang))		V.d = Matr * tes3.getPlayerEyeVector()
			if mp.isMovingBack then V.d = V.d*-1 elseif ang == 90 or ang == 270 then V.d.x = V.d.x/(1 - V.d.z^2)^0.5		V.d.y = V.d.y/(1 - V.d.z^2)^0.5 end		V.d.z = 1
		end
		local imp = math.min(100 + mp.strength.current/2 + s/2, 200) * (P.acr12 and 1 or 0.75)
		* math.min(math.lerp(P.atl13 and 0.75 or 0.5, 1, G.STN*(P.acr14 and 2 or 1.25)), 1)
		

		
		if P.acr10 then mp.velocity = V.nul end		mp.isSwimming = false
		V.d = V.d * (imp/0.15)		G.dfr = 0.15
		PST.current = PST.current - stc
		L.skacr = imp/1000		mp:exerciseSkill(20,1)
		climb = true	tes3.playSound{sound = math.random(2) == 1 and "RightM" or "LeftM"}
		if cf.m then tes3.messageBox("Climb-jump! impuls = %d  dist = %d   cost = %d", imp, dist, stc) end
	end
end
if not T.Kik.timeLeft and m and (cf.agr or R[r]) then	local s = math.min(mp:getSkillValue(26),200)		local bot = math.min(mp:getBootsWeight(), 30)
	local sc = math.max(30 + bot/3 + G.ENC * (P.atl14 and 10 or 20) - (P.end6 and 5 or 0) - (P.hand14 and s/10 or 0), 10) - (climb and 10 or 0)
	
	if PST.current > sc then	PST.current = PST.current - sc
		local KO = not m.hasFreeAction			local arm = m.armorRating		local tsh = m.readiedShield		local Kcrit
		local cd = math.max(((P.spd12 and 1.5 or 2) - mp.speed.current/100 + (1 - G.STN) * (P.atl11 and 0.2 or 0.5) + G.ENC * (P.atl12 and 0.2 or 0.5)) / math.min(D.AR.as + G.LIG, 1), (P.hand15 and 0.5 or 1))
		T.Kik = timer.start{duration = cd, callback = function() end}
		local Kskill = s * ((P.hand1 and 0.4 or 0.2) + (P.str2 and 0.1 or 0))	local Kstr = math.min(mp.strength.current,500)*(P.str1 and 0.5 or 0.3)
		local Kstam = math.min(math.lerp(P.end1 and 0.75 or 0.5, 1, G.STN*(P.hand2 and 2 or 1.25)), 1)
		
		local CritC = mp.attackBonus/4 + s/(P.hand6 and 10 or 20) + mp.agility.current/(P.agi1 and 5 or 10) + mp.luck.current/(P.luc1 and 10 or 20) + (mp.isMovingForward and P.spd3 and 10 or 0) + (m.isMovingForward and 10 or 0)
		+ (G.Ecomb * (P.agi6 and 5 or 3)) + (mp.isJumping and P.acr4 and mp:getSkillValue(20)/10 or 0)
		- (m.endurance.current + m.agility.current + m.luck.current)/10 - arm/10 + math.clamp(1-m.fatigue.normalized,0,1)*(P.agi11 and 20 or 10) - 10
		
		if CritC > math.random(100) then
			Kcrit = 30 + (P.agi8 and 10 or 0) + (P.hand5 and 10 or 0) + math.max(CritC - 100, 0)
			Kcrit = math.random(Kcrit, Kcrit*2)
		else Kcrit = 0 end
		
		local Koef = (100 + Kstr + Kskill + G.DashD) * Kstam * (100 + Kcrit)/10000
		local Kin = P.alt25 and math.min(math.min(mp.willpower.current,500)/10 + mp:getSkillValue(0)*0.3, cf.moment) or 0		local mc = 0
		if Kin > 0 then mc = Kin/(P.int39 and 4 or 3)		if PMP.current > mc then Mod(mc) 	Kin = Kin * L.Cpow(mp,0,true) * (P.wil31 and 1.25 or 1)		else Kin = 0	mc = 0 end end
	--	local BaseD = (5 + bot/(P.hand13 and 6 or 12)) * Koef
		local dmg = ((5 + bot/(P.hand13 and 6 or 12)) * Koef * (P.hand19 and 1 or 0.5) + Kin) * (KO and (P.str14 and 2 or 1.5) or 1)
		local mass = r.tempData.mass * (1 + arm/200)		local sdmg = (P.hand16 and 15 or 10) * Koef		local fdmg
		
		if not climb then tes3.playSound{reference = p, soundPath = L.RSound(WT[-1].sws), volume = cf.volsw, pitch = math.random(90,110)/100} end

		if tsh and not m.isHitStunned and not KO and math.abs(m:getViewToPoint(pp)) < 45 then	fdmg = dmg		mass = mass * 2		local s = m:getSkillValue(0)		local sob = tsh.object
			tes3.playSound{reference = r, soundPath = L.RSound("DmgShield" .. sob.weightClass), volume = cf.volimp, pitch = math.random(90,110)/100}
			local swgt = sob.weight		if swgt == 0 then swgt = 10 end
			tsh.variables.condition = math.max(tsh.variables.condition - fdmg, 0)		if tsh.variables.condition < 0.1 then m:unequip{item = sob} end
			sdmg = (sdmg + fdmg) * 0.5 + swgt * math.max(0.5 - s * 0.003, 0.2)
		else
			G.DmgR[r] = 0		G.FDSource = "Kick"		G.FDMG = dmg	G.FDMGImm = true
			fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}
			sdmg = sdmg + fdmg
		end
		
		local pow = math.min(((250 + Kstr*5 + G.DashD*10) * (P.hand10 and 2 or 1.5) * Kstam + Kin*20 - m.endurance.current - m.agility.current) / mass, 3000)		local jump
		if pow > 100 then
			vdir.z = m.isFalling and math.clamp(vdir.z, climb and -1 or 0.3, 1) or (climb and math.clamp(vdir.z, 0.15, 0.3) or 0.3)		--vdir = vdir:normalized()
			jump = m:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
			if not jump then	local min = 1000 + math.min(vdir.z, 0)*500
				if pow > min then	local hit2 = tes3.rayTest{position = r.position + tes3vector3.new(0, 0, m.height/2) - vdir*30, direction = vdir, ignore = L.RAR}	--{tes3.game.worldPickRoot}
					if hit2 and hit2.reference then pow = math.clamp(hit2.distance, min, pow) end
				end
				tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
				DOM[m] = {v = vdir * (pow/0.5) + (DOM[m] and DOM[m].v/2 or V.nul), fr = 0.5}
			end
		end

		if not KO and m.fatigue.current > 0 then	local newstam = m.fatigue.current - sdmg
			m.fatigue.current = math.max(newstam, 0)
			if newstam < 0 then m:hitStun{} end
		end
		
		L.CrimeAt(m)		G.FdmgInd = Kcrit
		--if cf.dmgind then L.DmgInd(fdmg, m.health.current, m.health.base, Kcrit > 0) end
		if T.Comb.timeLeft then T.Comb:reset() end
		if mp.invisibility > 0 then tes3.removeEffects{reference = p, effect = 39} end
		L.skw = (m.object.level + 5)/10 * sdmg/20			mp:exerciseSkill(26, 1)
		if cf.m30 then tes3.messageBox([[Kick dmg = %d (%d / %d arm) + %d stam  K = %d%% (+%d%% str +%d%% skill +%d%% dash) *%d%% stam +%d%% crit (%d%%) +%.1f kin) 
		impuls = %d  mass = %.2f  dist = %d  cd = %.1f  cost = %d + %d  %s   Z = %.2f  %s]],
		fdmg, dmg, arm, sdmg, Koef*100, Kstr, Kskill, G.DashD, Kstam*100, Kcrit, CritC, Kin, pow, mass, dist, cd, sc, mc, KO and "KO!" or "", vdir.z, jump and "" or "MOVE") end
	end
end
end
end end


-- 1 радиуса спеллов = 22.1 игровые единицы
L.KBlast = function(pos, rad, sn, cas, dmg) local dist, r, mass, pow, KO, dmg2, dmgk, vdir, rp, jump, Z, dif				--local maxpow = p.cell.isInterior and not p.cell.behavesAsExterior and 8000 or 15000
	for _, m in pairs(tes3.findActorsInProximity{position = pos, range = rad}) do r = m.reference	if r ~= cas then 		rp = (r.position + tes3vector3.new(0, 0, r.tempData.hgt*0.7))		
		dist = pos:distance(rp)		dif = rad - dist
		if dif > 0 then
			if tes3.testLineOfSight{position1 = pos, position2 = rp} then	MPR[sn][r] = 1
				mass = r.tempData.mass * (1 + m.armorRating/200)
				pow = math.min(2*dif/mass, 4000)		KO = pow/10 - m.agility.current - 50
				if pow > 200 then
					vdir = (rp - pos):normalized()		Z = vdir.z		
					vdir.z = m.isFalling and math.clamp(Z, -0.75, 0.75) or math.clamp(Z, 0.3, 0.75)
					jump = m:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
					if not jump and m ~= mp then	local min = 1000 + math.min(vdir.z, 0)*500
						if pow > min then local hit = tes3.rayTest{position = rp - vdir*30, direction = vdir, ignore = L.RAR}		if hit and hit.reference then pow = math.clamp(hit.distance, min, pow) end end
						tes3.applyMagicSource{reference = r, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
						DOM[m] = {v = vdir * (pow/0.5) + (DOM[m] and DOM[m].v/2 or V.nul), fr = 0.5}
					end
					if KO > math.random(100) then	--tes3.applyMagicSource{reference = r, name = "KO", effects = {{id = 20, min = 5000, max = 5000, duration = 1}}}
						m:hitStun{knockDown = true}
					end
				end
				if dmg then	dmgk = math.min(2*(rad/2 - dist)/rad + 0.1, 1)		dmg2 = nil		--math.min(math.lerp(0, 1, dmgk*1.11), 1)
					if dmgk > 0 then	if cas ~= p and R[r] and R[cas] then dmgk = dmgk/2 end		dmg2 = dmg * dmgk
						G.DmgR[r] = 0		G.FDSource = "Blast"		G.FDMG = dmg2 		local fat = m.fatigue
						m:applyDamage{damage = dmg2, applyArmor = true, playerAttack = cas == p}		if cas == p then L.CrimeAt(m) end
					end
				end
				if cf.m then tes3.messageBox("%s %s  Impuls = %d (%d - %d) Mass = %.2f (%d hgt)  Dmg = %d/%d (%d%%)   KO = %d%%  Z = %.2f -> %.2f",
				pow > 200 and (jump and "JUMP" or "MOVE") or "NONE", r.object.name, pow, rad, dist, mass, r.tempData.hgt, dmg2 or 0, dmg or 0, (dmgk or 0)*100, KO, Z or 0, vdir and vdir.z or 0) end
				--m.actionData.animationAttackState = 15
			else	MPR[sn][r] = 0		--tes3.messageBox("No LOS - %s", r)
			end
		end 
	end end
end

L.KSCollision = function(e)	local si = e.sourceInstance 		local sn = si.serialNumber		local cas = si.caster		local m = cas.mobile
	local ef = si.source.effects[e.effectIndex + 1]		local mag = math.random(ef.min, ef.max) * L.Cpow(m,0) * (SN[sn] or 1)
	local rad = (ef.radius + L.GetRad(m)) * mag * ((m ~= mp or P.des8) and 1 or 0.75)		rad = 20 * rad^0.5
	L.KBlast(e.collision.point, rad, sn, cas, mag)		--tes3.messageBox("KS_Collision")	--Эвент срабадывает ДО прожектайл экспиред
end

L.TeleportCol = function(e) local si = e.sourceInstance 	if si.caster == p then
	local pos = e.collision.point - si.projectile.velocity:normalized()*70
	local TPdist = pp:distance(pos)		local TPmdist = (100 + mp.intelligence.current + mp:getSkillValue(11) + mp:getSkillValue(14)) * 20
	if TPdist > 200 then
		if TPdist > TPmdist then  pos = pp:interpolate(pos, TPmdist)		TPdist = TPmdist end	mc = (20 + TPdist/50) * (P.int32 and 1 or 1.5) * L.MCOST(4)
		if mc < PMP.current then 
			Mod(mc)		tes3.playSound{soundPath = L.RSound("Dash"), volume = 1, pitch = math.random(90,110)/100}
			p.position = pos	--mp.isSwimming = true	--tes3.positionCell{reference = p, position = pos, cell = p.cell}		
			tes3.applyMagicSource{reference = p, name = "4nm", effects = {{id = 10, min = 1, max = 1, duration = 0.1}}}
			if cf.m then tes3.messageBox("Distance = %d  Manacost = %.1f", TPdist, mc) end
		end
	end
end end

local function MAGICSELECTIONCHANGED(e)	local s = e.source
	M.SpFB = tes3ui.findMenu("MenuMulti"):findChild("MenuMulti_magic_fill")
	if s and s.objectType == tes3.objectType.enchantment then M.SpFB.visible = true		--timer.delayOneFrame(function() M.SpFB.widget.fillColor = {0,1,0} end)
	else M.SpFB.visible = false	end
	if tes3ui.menuMode() and M.INV then timer.delayOneFrame(L.GetArStat, timer.real) end
	--tes3.messageBox("%s", s and s.id)
	--timer.delayOneFrame(function() tes3.messageBox("%s    -  frame", s and s.id) end)
end		event.register("magicSelectionChanged", MAGICSELECTIONCHANGED)


local function SPELLMAGICKAUSE(e) 	local sp = e.spell		local r = e.caster 	local cost = sp.magickaCost		if r == p then
	local sc = sp:getLeastProficientSchool(mp)	local skill = mp:getSkillValue(SP[sc].s) 	local char
	mp.animationController.animationData.castSpeed = 2/(1 + cost*3/(cost+100))
	* math.max((1 + math.min(mp.speed.current,500)*(P.spd30 and 0.002 or 0.001) + skill*(P[SP[sc].ps] and 0.004 or 0.002) 
	- G.ENC * (P.end15 and 0.1 or 0.2) - (1 - G.STN) * (P.wil15 and 0.1 or 0.2))
	* (D.AR.cs > 1 and D.AR.cs or math.min(D.AR.cs + G.LIG, 1)), 0.5)
	
	
	if G.LastQS == sp then char = 0
	else char = M.MCB.normalized * ((P.wil7 and 0.3 or 0.2) + (P[SP[sc].pc] and 0.2 or 0)) * (P.una12 and D.AR.u > 14 and 2 or 1)
		if char > 0 then SN[e.instance.serialNumber] = 1 + char		M.MCB.current = 0 end
	end

	G.MCKoef = L.MCOST(sc)
	* (1 + char * (P.int14 and 1 or 1.25))
	* (G.LastQS == sp and not P.int11 and 1.2 or 1)
	
	e.cost = cost * G.MCKoef
	if cf.m10 then tes3.messageBox("%s (%s)  Cost = %.1f (%s base)  School = %s  Char = %d%%	  Speed = %.3f",
	sp.name, e.instance.serialNumber, e.cost, sp.magickaCost, sc, char*100, mp.animationController.animationData.castSpeed) end

	
	--tes3.messageBox("%s    speed = %s   sc = %s", sp.name, mp.animationController.animationData.castSpeed, sc)

	if PMP.current < e.cost then G.LastQS = nil end
else local m = r.mobile		local sc = sp:getLeastProficientSchool(m)
	if sp.castType == 5 then
		m.animationController.animationData.castSpeed = 1.6
	--	tes3.messageBox("%s     smc = %d", sp.name, e.cost)
	else
		local McStat = m.intelligence.current + m:getSkillValue(SP[sc].s)
		local newcost = cost * (1 - (McStat/(McStat+200)))
		if m.magicka.current < newcost then e.cost = math.max(m.magicka.current-1, -1) else e.cost = newcost end
		m.animationController.animationData.castSpeed = 2/(1 + cost*3/(cost+100)) * math.min((0.75 + m.fatigue.normalized/4) * (1 + m.speed.current/100), 2)	--attempt to index field 'animationController' (a nil value)
		
	--	tes3.messageBox("%s   time = %s   smc = %d/%d", sp.name, 0.5 + cost*3/(cost+100), e.cost, m.magicka.current)
	end
end end		event.register("spellMagickaUse", SPELLMAGICKAUSE)


-- Эвент не срабатывает при использовании свитков, но срабатывает при взрыве стрел и металок!		Типы: 0 = свитки, 1 = оружие, 2 = использование, 3 = постоянный
local function ENCHANTCHARGEUSE(e)	if e.isCast then	local en = e.source
	if e.caster == p then		local cost = en.chargeCost	local newcost, PCcost		L.skmag = cost * 10 / (cost + 100)
		if en.castType == 1 then	-- Оружие кроме снарядов
			if e.item.type < 11 then
				if D.NoEnStrike then e.charge = 90000	return
				else
					if G.EnWsn == e.sourceInstance.serialNumber then
						newcost = cost * L.MCOST(10) * (G.TR.tr7 and (D.poison and 2 or 0.75) or 1)
						PCcost = newcost * (P.enc9 and 1 or 1.2)
					else e.charge = 90000	return end
				end
			else return end
		else -- При использовании
			if T.EnCD.timeLeft then e.charge = 90000	return
			else	local char = M.MCB.normalized * ((P.wil7 and 0.3 or 0.2) + (P.enc20 and 0.2 or 0)) * (P.una12 and D.AR.u > 14 and 2 or 1)
				if char > 0 then SN[e.sourceInstance.serialNumber] = 1 + char		M.MCB.current = 0 end
				T.EnCD = timer.start{duration = 3 - math.min((mp:getSkillValue(9) + mp.speed.current)/100, 2) - (P.enc11 and 0.5 or 0), callback = function() end}
				newcost = cost * L.MCOST(9) * (1 + char * (P.enc21 and 1 or 1.25))
				PCcost = newcost * (P.enc8 and 1 or 1.2)
			end
		end
		
		e.charge = newcost		
		if e.itemData.charge >= newcost then	local MCost = 0
			if M.PC.current + PMP.current > PCcost then
				if PCcost > M.PC.current then MCost = PCcost - M.PC.current		M.PC.current = 0 else M.PC.current = M.PC.current - PCcost end
				M.Bar4.visible = true	D.PCcur = M.PC.current		if not T.PCT.timeLeft then T.PCT:reset() end
				if MCost > 0 then Mod(MCost) end
			else e.charge = 90000	return end
			
			if cf.m10 then tes3.messageBox("En cast! %s  Cost = %.1f (%d base)  PCcost = %.1f   Manacost = %.1f", en.id, e.charge, cost, PCcost, MCost) end
		end 
	else
		if en.castType == 1 then
			if e.item.type < 11 then
				if G.EnWsn ~= e.sourceInstance.serialNumber then e.charge = 90000	return end
			else return end
		end
		local m = e.caster.mobile		local McStat = m.intelligence.current + m:getSkillValue(9)
		e.charge = e.source.chargeCost * (1 - (McStat/(McStat+200)))
	end
end


end		event.register("enchantChargeUse", ENCHANTCHARGEUSE)


local function SPELLCAST(e)	local sp = e.source		if sp.castType == 0 then 	local c = e.caster
	if c == p then	local cost = sp.magickaCost		local sc = e.weakestSchool
	--	tes3.messageBox("%s (%s)  chance = %d%%   /   %d%%", sp.name, cost, e.castChance, (210 + mp.willpower.current/5 - cost)*1.5)
		if sc < 6 then
			local stam = cost * (G.MCKoef or 1) * ((P.end16 and 0.25 or 0) + (P.una9 and D.AR.u * 0.01 or 0))
			if stam > 0 then PST.current = math.min(PST.current + stam, PST.base) end
			
			e.castChance = ( math.min(mp:getSkillValue(SP[sc].s),150) * (P[SP[sc].p2] and 1.6 or 1.2)
			+ math.min(mp.willpower.current,300) * (P.wil5 and 0.2 or 0.1)
			+ math.min(mp.luck.current,300) * (P.luc13 and 0.2 or 0.1)
			+ (mp.spellReadied and (P.int8 and 40 or 20) or 0) )
			* math.max(1 - G.ENC * (P.end17 and 0.1 or 0.25), 0.25)
			* (D.AR.cc > 1 and D.AR.cc or math.min(D.AR.cc + G.LIG, 1))
			- cost * (not P.int2 and G.LastQS == sp and 1.5 or 1)
			- math.max(cost/2 - mp.intelligence.current * (G.TR.tr25 and 0.5 or 1) * (P.int6 and 0.5 or 0.25), 0)
			- mp.sound
			
			--tes3.messageBox("Spellcast! School = %s  chance = %.1f   stam + %.1f", sc, e.castChance, stam)
		end

		if G.LastQS == sp then ad.animationAttackState = 0		G.LastQS = nil
			--if mp.weaponDrawn then L.WComb(ad.attackDirection, not mp.readiedWeapon and 0 or mp.readiedWeapon.object.isOneHanded) end
			--if ad.animationAttackState == 2 then ad.animationAttackState = 0 	MB[1] = 0 end
			for i, ef in ipairs(sp.effects) do if ef.id ~= -1 then tes3.removeSound{sound = ef.object.castSoundEffect, reference = p} end end
		end
	else e.castChance = e.castChance + e.source.magickaCost/2
		--tes3.messageBox("%s (%s)  chance = %d%%", e.source.name, e.source.magickaCost, e.castChance)
	end
--elseif (c.mobile.actorType == 1 or c.object.biped) then c.mobile.actionData.animationAttackState = 0		--tes3.messageBox("Spellcast! %s  %s", e.castChance, e.source.name)
end end		event.register("spellCast", SPELLCAST)


--[[local function SPELLCASTED(e) if e.caster == p and e.expGainSchool < 6 then
	local sc = e.expGainSchool		tes3.messageBox("CAST! School = %s   cost = %s", sc, e.source.magickaCost)
end end		event.register("spellCasted", SPELLCASTED)	--]]
local function SPELLCASTEDFAILURE(e) if e.caster == p and P.int7 and e.expGainSchool < 6 then M.MCB.current = 0		G.LastQS = nil
	tes3.modStatistic{reference = p, name = "magicka", limitToBase = true, current = e.source.magickaCost * (G.MCKoef or 1) * math.min((mp.intelligence.current + mp:getSkillValue(SP[e.expGainSchool].s))/400, 0.5)}
--else tes3.messageBox("Fail  %s    %s", e.caster, e.source.name)
end end		event.register("spellCastedFailure", SPELLCASTEDFAILURE)



L.RaySim = function() if L.KEY(G.ck) and PMP.current > G.rayc then	G.raysim = G.raysim + wc.deltaTime
	if G.raysim > G.raydt then G.raysim = G.raysim - G.raydt	tes3.applyMagicSource{reference = p, source = B.RAY}	G.raynum = G.raynum + 1 end
else 		L.skmag = G.rayc * G.raynum * 10 / (G.rayc * G.raynum + 100)		mp:exerciseSkill(SP[G.raysc].s, 1)
	event.unregister("simulate", L.RaySim)		G.raysim = nil		G.raynum = nil
end end


local function MAGICCASTED(e) local cas = e.caster		if cas == p then	local s = e.source	local si = e.sourceInstance		local sn = si.serialNumber
	--	if not s.effects then mwse.log("NO EFFECTS!!! source id = %s   name = %s    sn = %s", s.id, s.name, sn) end
	local ef1 = s.effects[1]	local id1 = ef1.id		local cost	local n = s.name		--attempt to index field 'effects' (a nil value)
	local KF = SN[sn] or 1		local ct = s.castType

	if s.objectType == tes3.objectType.spell and ct == 0 then cost = s.magickaCost
		local Kstam = math.min(math.lerp(P.wil2 and 0.75 or 0.5, 1, G.STN*(P[SP[s:getLeastProficientSchool(mp)].p3] and 2 or 1.25)), 1)
		KF = KF * Kstam
		L.skmag = cost * 10 / (cost + 100)
		if cf.m10 then tes3.messageBox("%s  Spell power = %d%%   %d%% stam", n, KF*100, Kstam*100) end
	elseif s.objectType == tes3.objectType.enchantment and ct < 3 then cost = s.chargeCost
		local Kstam = math.min(math.lerp(P.wil2 and 0.75 or 0.5, 1, G.STN*(P.enc5 and 2 or 1.25)), 1)
		if (ct == 1 and si.item.type < 11) or ct == 2 then		G.REI = {}
			KF = KF * Kstam * (P.enc10 and 1 + M.PC.current/5000 or 1)
			if cf.m10 then tes3.messageBox("%s  Enchant power = %d%%  %d%% stam", s.id, KF*100, Kstam*100) end
		elseif ct == 0 then
			KF = KF * Kstam * (P.enc17 and 1.2 or 1)
			local PCcost = math.min(cost * (P.enc8 and 0.5 or 0.75), 300)		local MCost = 0		local Summ = M.PC.current + PMP.current		
			if Summ > PCcost then
				if PCcost > M.PC.current then MCost = PCcost - M.PC.current		M.PC.current = 0 else M.PC.current = M.PC.current - PCcost end
				if MCost > 0 then Mod(MCost) end
			else MCost = PMP.current		M.PC.current = 0	Mod(MCost)			KF = KF * Summ / PCcost end
			M.Bar4.visible = true	D.PCcur = M.PC.current		if not T.PCT.timeLeft then T.PCT:reset() end
			if cf.m10 then tes3.messageBox("%s  Scroll power = %d%%  %d%% stam   PCcost = %.1f   Manacost = %.1f", s.id, KF*100, Kstam*100, PCcost, MCost) end
		end
	elseif n == "4b_RAY" then
		local mc = L.MCOST(G.raysc) * (MB[cf.mbret] == 128 ~= cf.ray and G.rayc or G.rayc * 0.8)
		if T.MCT.timeLeft then
			local char = M.MCB.normalized * ((P.wil7 and 0.3 or 0.2) + (P[SP[G.raysc].pc] and 0.2 or 0)) * (P.una12 and D.AR.u > 14 and 2 or 1)
			KF = KF * (1 + char)
			M.MCB.current = math.max(M.MCB.current - (P.wil32 and 0.5 or 1), 0)
			mc = mc * (1 + char * (P.int14 and 1 or 1.25))
		end
		Mod(mc)
	end

	if ef1.rangeType == 2 and not MP[si] then
		if P.alt18 and MB[cf.mbhev] == 128 and n ~= "4b_RAY" then V.BAL[sn] = 1		KF = KF * 1.05
		elseif DM.cp == 3 and (P.mys8 and T.MCT.timeLeft or tes3.isAffectedBy{reference = p, effect = 506}) and id1 ~= 610 then		local mc
			if n == "4b_RAY" then if cf.raycon then mc = math.max(G.rayc,1) * (P.int31 and 0.3 or 0.4) end
			else mc = math.max(cost or s.value, 10) * (P.int31 and 0.3 or 0.4) end
			if mc and PMP.current > mc then MP[si] = {pos = L.Hitp(0)}		Mod(mc) end
		end
	end

	if KF ~= 1 then SN[sn] = KF end
elseif cas.data.SumPl then	local si = e.sourceInstance		local sn = si.serialNumber		local s = e.source		local wg = s.weight	
	--local ef1 = s.effects[1]	local id1 = ef1.id		local cost	local n = s.name
	
	if not wg or wg == 0 then SN[sn] = P.con22 and 0.6 or 0.5 end
	--	tes3.messageBox("Summon cast! %s - %s (%s)", cas, n, sn)
end end		event.register("magicCasted", MAGICCASTED)


-- Не срабатывает от алтарей и ловушек, не срабатывает от стрел
local function CALCTOUCHSPELLCONE(e)	local m = e.casterMobile	if m then	local s = e.source		local si = e.sourceInstance		local sn = si.serialNumber		local eff = s.effects	local id1 = eff[1].id
	local tar		MPR[sn] = {}
	if s.objectType == tes3.objectType.enchantment and s.castType == 1 then		tar = m.actionData.hitTarget
		e.angleXY = 90		e.angleZ = 90		e.reach = math.max(si.item.reach + 0.3, 1) * 130		--для оружия при ударе
	else
		if s.name == "4b_CW" then	local rw = m.readiedWeapon		tar = m.actionData.hitTarget
			e.angleXY = 90		e.angleZ = 90		e.reach = (rw and math.max(rw.object.reach + 0.3, 1) or 1) * 130 		--G.rng
		--	tes3.messageBox("%s   rad = %d     %d  %d", e.source.name or e.source.id, e.reach, e.angleXY, e.angleZ)
		else
			local agi = math.min(m.agility.current, 500)
			if m == mp then local ang = (P.agi32 and 50 or 30) + agi/10
				e.angleXY = ang		e.angleZ = ang		e.reach = math.max((P.agi32 and 150 or 100) + agi/2, 130)
			else local ang = 30 + agi*0.3
				e.angleXY = ang		e.angleZ = ang		e.reach = 200 + agi*2
			end
		end
	end
	if tar then tar = tar.reference		tar = tar.position + tes3vector3.new(0,0,tar.tempData.hgt*0.7) end
	if m == mp then		
		if tar then COL[sn] = tar + (pp + G.mph05 - tar):normalized() * 20
		else COL[sn] = pp + G.mph05 + tes3.getPlayerEyeVector() * 20 end
	else local cas = e.caster
		if tar then	COL[sn] = tar + (cas.position + tes3vector3.new(0,0,cas.tempData.hgt*0.5) - tar):normalized() * 20
		else COL[sn] = cas.position + tes3vector3.new(0,0,cas.tempData.hgt*0.5) + cas.forwardDirection * 20 end
	end
	
	if L.BLASTME[id1] then
		if m == mp or id1 == 602 then
			local rad, dmg = 0, 0	local expk, mag		local radbon = L.GetRad(m)		local koef = L.Cpow(m,0) * (SN[sn] or 1)
			for i, ef in ipairs(eff) do expk = L.BLASTME[ef.id]		mag = math.random(ef.min, ef.max) * koef
				if ef.id == 602 then
					dmg = dmg + mag
					rad = rad + mag * (ef.radius + radbon) * ((m ~= mp or P.des8) and 1 or 0.75)
				elseif m == mp and expk and ef.radius > 9 then rad = rad + mag * expk * (ef.radius - 10 + radbon) * ((m ~= mp or P.des8) and 1 or 0.5) end
			end
			if rad > 99 or dmg > 0 then	rad = 20 * rad^0.5		L.KBlast(COL[sn], rad, sn, e.caster, dmg > 0 and dmg) end
		end
	elseif m == mp then
		if L.MESG[id1] then	local E = B.SG.effects		local num = (P.alt51 and 4 or 3) + (mp:getSkillValue(11) + mp.intelligence.current > 150 and 1 or 0)		local KF = SN[sn] or 1
			if P.alt18 and MB[cf.mbhev] == 128 then KF = KF * 1.05		G.SGMod = 5
			elseif (DM.cp == 3 or DM.cp == 4 or DM.cp == 12) and (P.mys8 and T.MCT.timeLeft or tes3.isAffectedBy{reference = p, effect = 506}) then
				local mc = math.max(s.magickaCost or s.chargeCost or 10, 10) * (P.int31 and 0.15 or 0.2)
				if PMP.current > mc * 2.5 then
					if DM.cp == 3 then Mod(mc*2)	G.SGMod = 3
					elseif DM.cp == 4 then if P.mys8a and MB[cf.mbret] == 128 then Mod(mc*2.5)	G.SGmintp = true else Mod(mc*2) G.SGmintp = nil end		G.SGMod = 4
					elseif DM.cp == 12 then Mod(mc*1.5)		G.SGMod = 12 end
				end
			else G.SGMod = nil end

			for i, ef in ipairs(eff) do if L.MESG[ef.id] then E[i].id = L.MESG[ef.id]		E[i].min = ef.min*KF	E[i].max = ef.max*KF		E[i].radius = ef.radius		E[i].duration = ef.duration		E[i].rangeType = 2
			else E[i].id = -1	E[i].rangeType = 0 end end
			local Marstat = (mp.agility.current + mp:getSkillValue(23)) * (P.mark11 and 1 or 0.5)		G.ShotGunDiv = 1 - (Marstat/(Marstat + 100))
			local v1 = p.forwardDirection * 16		local v2 = p.rightDirection * 16		local pos1 = pp + tes3vector3.new(0,0,mp.height/2)
			local d4, d5		if num == 5 then d4, d5 = true, true elseif num == 4 then d4 = TC{true,false}		d5 = not d4 end
			MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1, vel = L.GetSGVec(-20,20)} or {pos = L.Hitpr(pos1, L.GetSGVec(-20,20),0)}
			MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 + v1 + v2, vel = L.GetSGVec(20,60)} or {pos = L.Hitpr(pos1 + v1 + v2, L.GetSGVec(20,60),0)}
			MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 + v1 - v2, vel = L.GetSGVec(-60,-20)} or {pos = L.Hitpr(pos1 + v1 - v2, L.GetSGVec(-60,-20),0)}
			if d4 then MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 - v1 + v2, vel = L.GetSGVec(60,120)} or {pos = L.Hitpr(pos1 - v1 + v2, L.GetSGVec(60,120),0)} end
			if d5 then MP[tes3.applyMagicSource{reference = p, source = B.SG}] = G.SGMod ~= 3 and {pos = pos1 - v1 - v2, vel = L.GetSGVec(-120,-60)} or {pos = L.Hitpr(pos1 - v1 - v2, L.GetSGVec(-120,-60),0)} end
			if cf.m10 then tes3.messageBox("Shotgun cast! %s   Koef = %.2f  Balls = %d  Div = %d%%   Mode = %s", n or s.id, KF, num, G.ShotGunDiv*100, G.SGMod or 0) end		e.reach = 0		return
		elseif L.MERAY[id1] then	G.rayc = (s.magickaCost or s.chargeCost) * (P.int33 and 0.1 or 0.125)			G.raysc = s.magickaCost and s:getLeastProficientSchool(mp) or eff[1].object.school
			local k = math.min(SN[sn] or 1, 1)		local E = B.RAY.effects		local num = (P.alt52 and 20 or 15) + math.min(math.floor(mp:getSkillValue(11)/20 + mp.intelligence.current/20), 10)
			for i, ef in ipairs(eff) do if L.MERAY[ef.id] then E[i].id = L.MERAY[ef.id]		E[i].min = ef.min*k		E[i].max = ef.max*k		E[i].radius = ef.radius/2	E[i].duration = ef.duration		E[i].rangeType = 2
			else E[i].id = -1	E[i].rangeType = 0 end end
			if not G.raysim then event.register("simulate", L.RaySim)		G.raydt = 1/num		G.raysim = G.raydt		G.raynum = 0	end		--mp.animationController.animationData.castSpeed = 0
			if cf.m10 then tes3.messageBox("Ray cast! %s   Koef = %.2f   Cost = %.2f   Balls = %d", n or s.id, k, G.rayc, num) end		e.reach = 0		return
		elseif L.MENOV[id1] then	local E = B.DC.effects		local rad = L.GetRad(mp)/2		local KF = SN[sn] or 1
			for i, ef in ipairs(eff) do if L.MENOV[ef.id] then E[i].id = L.MENOV[ef.id]		E[i].min = ef.min*KF	E[i].max = ef.max*KF	E[i].radius = rad+ef.radius		E[i].duration =	ef.duration		E[i].rangeType = 2
			else E[i].id = -1	E[i].rangeType = 0 end end
			MP[tes3.applyMagicSource{reference = p, source = B.DC}] = {pos = pp + tes3vector3.new(0,0,10), exp = true}		e.reach = 0		return
		end
	end
	--tes3.messageBox("CONE! %s   rad = %d     %d  %d    Power = %s    HitTar = %s", s.name or s.id, e.reach, e.angleXY, e.angleZ, SN[sn], m.actionData.hitTarget and m.actionData.hitTarget.reference)
end end		event.register("calcTouchSpellCone", CALCTOUCHSPELLCONE)



local Quat = niQuaternion.new()

L.BaseCP = function()
	if G.prbase == nil then G.prbase = MB[cf.mbret] == 128
		if G.MBret ~= G.prbase then L.SectorDod()	--tes3.messageBox("mouse = %s", G.prbase)	
		end
		G.MBret = G.prbase
		if G.prbase then G.prbase = G.pep + G.pev * 150 end
	end
	return G.prbase
end
L.HitCP = function()
	if not G.hit then	local hit = tes3.rayTest{position = G.pep, direction = G.pev, ignore = {p}}	
		if hit then	local r = hit.reference		G.hit = hit.intersection + G.pev * (N[r] and r.mobile.boundSize2D.x/2 or 30)
		else G.hit = G.pep + G.pev * 4800 end
	end
	return G.hit
end
L.PrLive = function() if not G.PrL then G.PrL = (G.STN*4 + (mp.willpower.current + mp:getSkillValue(14) + mp:getSkillValue(11))/50) * (P.alt8 and 2 or 1) end		return G.PrL end


L.RospMod = {[1] = true, [2] = true, [4] = true, [11] = true, [6] = true}
L.DetMod = 	{[1] = true, [2] = true, [4] = true}

L.CPF = {
[1] = function(r,t)		-- Магические шары
	t.tar = L.BaseCP() or L.HitCP()
	t.m.velocity = (t.tar - t.p):normalized() * (G.prbase and t.p:distance(t.tar) < 100 and 50 or t.spd)
	Matr:lookAt(G.prbase and G.pev or t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()		--r.orientation.x = Matr:toEulerXYZ().x		r.orientation.y = Matr:toEulerXYZ().y
end,
[11] = function(r,t)	-- Стрелы контроль
	if not t.mus or t.m.animTime > 0.5 then --t.m.velocity = G.pev*t.spd
		--t.m.velocity = t.m.velocity + G.pev * 2000 * G.dt - t.m.velocity:normalized() * 1000 * G.dt 
		--t.m.velocity = t.m.velocity + (L.HitCP() - r.position):normalized() * 4000 * G.dt - t.m.velocity:normalized() * 3000 * G.dt 
		--t.m.velocity = t.m.velocity * (1 - G.dt*2) + (L.HitCP() - r.position):normalized() * 6000 * G.dt
		--t.m.velocity = t.m.velocity:normalized():lerp((L.HitCP() - r.position):normalized(), G.dt*10) * t.spd
		
		
	--	t.spd = math.max(t.spd - (G.prbase and 2000 or 1000) * G.dt, 2500)
	--	t.m.velocity = (L.HitCP() - t.p):normalized() * (G.prbase and t.p:distance(G.hit) < 100 and 50 or t.spd)
		
		t.vel = t.m.velocity:copy()
		Quat:fromAngleAxis(G.dt*2, t.vel:cross(L.HitCP() - t.p):normalized())		t.m.velocity = Quat:toRotation() * t.vel
		Matr:lookAt(t.vel, V.up)		r.orientation = Matr:toEulerXYZ()
	end
end,
[10] = function(r,t)	-- Стрелы игрока
	t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-2000 * G.dt)
	Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
end,
[5] = function(r,t)		-- Баллистический магия
	t.m.velocity = t.m.velocity + tes3vector3.new(0,0,-2000 / t.pow * G.dt)		-- + (t.con and G.pev*1000*G.dt or tes3vector3.new(0,0,0))
	Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
end,
[6] = function(r,t)		-- Броски оружия
	t.vel = t.m.velocity:copy()
	if t.con then 
		if V.METR[t.r] then
			Quat:fromAngleAxis(G.dt*2, t.vel:cross(L.HitCP() - t.p):normalized())		t.m.velocity = Quat:toRotation() * t.vel
			Matr:lookAt(t.vel, V.up)	t.r.orientation = Matr:toEulerXYZ()		t.r.position = r.position:copy()
		else t.si.state = 6 end
	else t.m.velocity = t.vel + tes3vector3.new(0,0,-2000 * G.dt)		Matr:lookAt(t.vel, V.up)		t.r.orientation = Matr:toEulerXYZ()		t.r.position = r.position:copy() end
end,
[7] = function(r,t)		-- Магические шары врагов
	--t.v = G.pep - r.position
	--if t.v:length() < 100 then CPR[r] = nil else
	--	t.m.velocity = t.m.velocity * (1 - G.dt*2) + t.v:normalized() * t.spd * G.dt
	--end
	t.vel = t.m.velocity:copy()
	
	Quat:fromAngleAxis(G.dt*2, t.vel:cross(L.UprPPos(t.p,t.spd) - t.p):normalized())		t.m.velocity = Quat:toRotation() * t.vel
	Matr:lookAt(t.vel, V.up)		r.orientation = Matr:toEulerXYZ()
end,
[2] = function(r,t)		-- Самонаведение магических шаров
	t.m.velocity = t.m.velocity * (1 - G.dt*2) + (t.tar.position + t.hv - r.position):normalized() * t.spd * G.dt
	--Quat:fromAngleAxis(G.dt*2, t.m.velocity:cross(t.tar.position + t.hv - r.position):normalized())		t.m.velocity = Quat:toRotation() * t.m.velocity
	Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
end,
[4] = function(r,t)		-- Магические мины
	t.m.position = t.pos		t.m.velocity = t.v*50
end,
[12] = function(r,t)	-- Рикошет
	if t.tp then	t.dist = t.p:distance(t.tp)
		if t.dist < 100 + t.spd/30 then t.tp = nil		t.m.velocity = t.m.velocity - (t.norm * t.m.velocity:dot(t.norm) * 2)
			Matr:lookAt(t.m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()			--tes3.messageBox("dist = %d    vel = %d", t.dist, t.spd)
		end
	else
		local hit = tes3.rayTest{position = t.p, direction = t.m.velocity, returnNormal = true, ignore = L.RAR}
		if hit then t.tp = hit.intersection:copy()	t.norm = hit.normal:copy() else CPR[r] = nil end
	end
end,
[8] = function(r,t)		-- Спрей
	if t.liv < t.m.animTime then t.m.expire = 1		CPR[r] = nil end
end,
[9] = function(r,t)		-- Магические волны
	if t.m.animTime > 0.3*t.num then
		for i, ef in ipairs(t.ef) do if L.MEWAV[ef.id] then G.WAV[i].id = L.MEWAV[ef.id]	G.WAV[i].min = ef.min*t.k*(1-(t.num-1)/t.max)		G.WAV[i].max = ef.max*t.k*(1-(t.num-1)/t.max)
		G.WAV[i].radius = ef.radius + t.num/(P.alt43 and 1 or 2)		G.WAV[i].duration = ef.duration		G.WAV[i].rangeType = 2	else G.WAV[i].id = -1	G.WAV[i].rangeType = 0 end end			
		MP[tes3.applyMagicSource{reference = p, source = B.WAV}] = {pos = r.position:copy(), exp = true}
		if t.num >= t.max then t.m.expire = 1	CPR[r] = nil else t.num = t.num + 1 end
	end
end}



--	Велосити заменяет естественную скорость, а импульс складывается с ней		r.sceneNode.velocity - разовое изменение скорости для этого фрейма
local function SimulateCP(e)	G.dt = wc.deltaTime		G.pep = tes3.getPlayerEyePosition()		G.pev = tes3.getPlayerEyeVector()	G.hit = nil		G.prbase = nil		G.PrL = nil		G.pcent = nil	--G.cpfr = G.cpfr + 1	
	for r, t in pairs(CPR) do 
		L.CPF[t.mod](r,t)
		if t.tim then	t.tim = t.tim - G.dt	if t.tim < 0 then CPR[r] = nil end end
		--tes3.messageBox("Anim = %.2f  Tim = %.2f   Sw = %.2f  Dam = %.2f  InSpd = %.2f   V = %d", t.m.animTime, t.tim or 0, t.m.attackSwing, t.m.damage, t.m.initialSpeed, t.m.velocity:length())
	end
	if table.size(CPR) == 0 then event.unregister("simulate", SimulateCP)	G.cpfr = nil end
end

local function SimulateCPS(e)	G.dt = wc.deltaTime		G.cpg = G.cpg + 4*G.dt
	for r, t in pairs(CPRS) do CPS[t.n] = CPS[t.n] - G.dt
		if CPS[t.n] < 0 then CPS[t.n] = 0	CPRS[r] = nil	else r.position = {pp.x + math.cos(G.cpg + t.n*math.pi/5) * t.rad, pp.y + math.sin(G.cpg + t.n*math.pi/5) * t.rad, pp.z + 100} end
	end		if table.size(CPRS) == 0 then event.unregister("simulate", SimulateCPS)		G.cpscd = nil	G.cpg = 0 end
end

--	m.mobToMobCollision = false	(нужен 1 фремй для стрели 2 фрейма для магии)	--m.movementCollision = false
local function MOBILEACTIVATED(e) local m = e.mobile	local r = e.reference	if m then local firm = m.firingMobile	if firm then	local si = m.spellInstance		local prob, sn
if si then sn = si.serialNumber		MPR[sn] = {} else prob = r.object end
if firm == mp then	local ss = si and si.source		local n = ss and ss.name	local mc, cont, ray, inspd, spd	
	--m.velocity = m.velocity:normalized() * 500		--r.scale = 0.5
	if si then local t = MP[si]		inspd = m.initialSpeed		spd = inspd * (1 + math.min(mp.willpower.current + mp:getSkillValue(11),200)/(P.alt27 and 400 or 1000))
		if t then	r.position = t.pos	if t.exp then m:explode() elseif t.vel then m.velocity = t.vel * spd end		MP[si] = nil
			if n == "4b_SG" then	L.SectorDod()		if G.SGMod then
				if G.SGMod == 5 and t.vel then
					m.velocity = m.velocity / 2
					CPR[r] = {mod = 5, m = m, pow = 1}
					if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				elseif G.SGMod == 4 then
					CPR[r] = {mod = 4, tim = L.PrLive()*1.5, m = m, pos = G.SGmintp and L.Hitpr(t.pos, t.vel, 150) + tes3vector3.new(0,0,20) or t.pos, v = t.vel:normalized()}
					if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				elseif G.SGMod == 12 then		
					CPR[r] = {mod = 12, tim = L.PrLive(), m = m, spd = spd, p = r.position}
					if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				end
			end end
		return end
		
		
		cont = tes3.isAffectedBy{reference = p, effect = 506}	ray = n == "4b_RAY"
		L.SectorDod()
		local sid = ss.effects[1].id	--tes3.messageBox("Sid = %s    dam = %s", sid, W.metd)			--attempt to index field 'effects' (a nil value)
		if sid == 610 then	r.sceneNode.appCulled = true
			if n == "4nm_tet" then W.TETP = r		G.TETsi = si		G.TETmod = 2
			else
				r.position = tes3.getPlayerEyePosition() + tes3vector3.new(0,0,20)
				m.velocity = tes3.getPlayerEyeVector() * W.acs
				CPR[r] = {mod = 6, m = m, p = r.position, v = tes3.getPlayerEyeVector(), r = W.met, dmg = W.metd, spd = W.acs, si = si, sn = sn}	W.met.orientation = p.orientation
				V.MET[sn] = {r = W.met, dmg = W.metd}		mc = cont and (5 + W.met.object.weight/2) * (P.int31 and 0.75 or 1)
				if cont and PMP.current > mc then Mod(mc)	CPR[r].con = true	CPR[r].tim = L.PrLive()
					V.METR[W.met] = {si = si, sn = sn}
					if not W.metflag then event.register("simulate", L.SimMET)	W.metflag = true end
				end
				if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
			end
		elseif L.MEWAV[sid] then
			timer.delayOneFrame(function() timer.delayOneFrame(function() m.mobToMobCollision = false end) end)
		
			CPR[r] = {mod = 9, m = m, num = 1, ef = ss.effects, k = SN[sn] or 1, max = (P.wil37 and 15 or 10) + math.min(math.floor(mp:getSkillValue(11)/40 + mp.willpower.current/40), 5)}
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		end
		
		if V.BAL[sn] then CPR[r] = {mod = 5, m = m, pow = SN[sn] or 1}	m.velocity = m.velocity:normalized() * (spd/2)
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		elseif ray and MB[cf.mbret] == 128 == cf.ray then CPR[r] = {mod = 8, m = m, liv = math.min(50 + mp.willpower.current/2 + mp:getSkillValue(11),300)/(P.alt53 and 1000 or 2000)}
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end	return
		end
		m.velocity = m.velocity:normalized() * spd
	else	cont = tes3.isAffectedBy{reference = p, effect = 506}
		L.SectorDod()
		CPR[r] = {mod = 10, m = m, liv = 0}		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
		if prob.type == 13 and P.mark9b and (cf.autoarb or MB[cf.mbshot] == 128) and not T.Arb.timeLeft and PST.current > 30 then	local ws = m.firingWeapon.speed
			PST.current = PST.current - math.max(30 - ws*10, 10)
			mp.animationController.weaponSpeed = mp.animationController.weaponSpeed * (2 + mp.agility.current/50)
			T.Arb = timer.start{duration = 3/ws, callback = function() end}
		end
		if BAM[prob.id] then BAM.am = prob.id	BAM.E[1].id = TC{14,15,16}	BAM.E[1].min = mp:getSkillValue(10)/(P.des12 and 10 or 20)		BAM.E[1].max = BAM.E[1].min*3		
			BAM.E[1].radius = L.GetRad(mp)*(P.des12 and 0.5 or 0.3)
			if (P.con17 or tes3.isAffectedBy{reference = p, effect = 601} or tes3.isAffectedBy{reference = p, effect = 603}) and BAM.f() then
				if mp.readiedAmmoCount < 3 then	tes3.addItem{reference = p, item = BAM.am, count = 100, playSound = false} end
			else	mp:unequip{item = BAM.am}		tes3.removeItem{reference = p, item = BAM.am, count = mwscript.getItemCount{reference = p, item = BAM.am}} end
			--	mp.readiedAmmoCount = 2		tes3.addItem{reference = p, item = BAM.am, count = 1, playSound = false}
		end
		local marstat = mp.agility.current + mp:getSkillValue(23)
		G.ArcDiv = ((G.arcf or G.met) and 3 or 1) - math.min(marstat/(P.mark11 and 100 or 300), 1) + (mp.isRunning and 1 - math.min(marstat/(P.mark15 and 200 or 400), 1) or 0)
		if G.ArcDiv > 0 then m.velocity = L.GetArcVec(20,10) * m.initialSpeed end		--tes3.messageBox("div =  %s ", G.ArcDiv)
	end
	if (cf.raycon or not ray) and (cont or (P.mys8 and T.MCT.timeLeft)) and DM.cp then 
		if si then mc = ray and math.max(G.rayc,1) or math.max(ss.magickaCost or ss.chargeCost or ss.value/10, 10) else mc = 20 end
		mc = mc * (P.int31 and 0.15 or 0.2)
		if PMP.current > mc * 2 then
			local live = L.PrLive()
			if si then
				if DM.cp == 2 then	if not G.cpscd then event.register("simulate", SimulateCPS)	G.cpscd = true end	local num = 1	md = CPS[1]		for i, tim in ipairs(CPS) do if tim < md then num = i	md = tim end end 
					CPS[num] = live*1.5		for ref, t in pairs(CPRS) do if t.n == num then CPRS[ref] = nil	break end end		CPRS[r] = {n = num, rad = 200 + ss.effects[1].radius * 6}
					if cf.m then tes3.messageBox("Ball %s  Time = %d  Rad = %d  Balls = %s   Live = %d %d %d %d %d %d %d %d %d %d", num, CPS[num], CPRS[r].rad, table.size(CPRS), CPS[1], CPS[2], CPS[3], CPS[4], CPS[5], CPS[6], CPS[7], CPS[8], CPS[9], CPS[10]) end
				else -- Сперва проверяем рикошет (12), потом мины (4), затем автонаведение (2), затем режим на цель (1/11)
					if DM.cp == 12 then mc = mc * 1.5		CPR[r] = {mod = 12, tim = live, m = m, spd = spd, p = r.position}
					elseif DM.cp == 4 then
						local teleport = P.mys8a and MB[cf.mbret] == 128		mc = mc * (teleport and 2 or 1.5)
						CPR[r] = {mod = 4, tim = live*1.5, m = m, pos = teleport and L.Hitp(150) + tes3vector3.new(0,0,20) or tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*50, v = tes3.getPlayerEyeVector()}
					else	local tar
						if DM.cp == 1 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {p}}
							tar = hit and hit.reference and hit.reference.mobile and not hit.reference.mobile.isDead and hit.reference
							if not tar then tar = L.Sector{d = 9000, lim = 3000} end
						end
						if tar then mc = mc * 2			CPR[r] = {mod = 2, tim = live, m = m, tar = tar, hv = tes3vector3.new(0,0,tar.mobile.height/2), spd = spd}
						else CPR[r] = {mod = 1, tim = live, m = m, spd = spd, p = r.position} end
					end		if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				end
			else if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
				if DM.cp == 12 then mc = mc * 1.5	CPR[r] = {mod = 12, tim = live, m = m, p = r.position}
				else CPR[r] = {mod = 11, m = m, p = r.position, tim = live, mus = G.ArcDiv >= 1} end
			end
			Mod(mc)
		end
	end		--if si then SSN[si.serialNumber] = true	tes3.messageBox("Cast! %s", si.serialNumber) end -- устраняем эксплойт с разгоном статов
elseif si then
	local spd = m.initialSpeed * (0.75 + math.min(firm.object.level,50)/40)		local t = MP[si]
	if t then	r.position = t.pos	if t.exp then m:explode() elseif t.vel then m.velocity = t.vel * spd end	MP[si] = nil	return end
	
	if firm.actionData.target == mp then	local rpos = r.position
		if cf.enacc then
			m.velocity = L.UprPPos(rpos,spd,true) - rpos
			Matr:lookAt(m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
		end
		if cf.spellhit then
			CPR[r] = {mod = 7, m = m, p = rpos, spd = spd, tim = firm.object.level/30}		--tes3.messageBox("liv = %.1f  InSpd = %.2f   spd = %d", CPR[r].liv, m.initialSpeed, CPR[r].spd)
			if not G.cpfr then event.register("simulate", SimulateCP)	G.cpfr = 0 end
		end
	end
	m.velocity = m.velocity:normalized() * spd
end
if not si then	r.position = r.position - m.velocity:normalized()*100
	local w = m.firingWeapon	local wt = w.type	local sw = m.attackSwing / prob.speed 		local WS = firm:getSkillValue(23)	local spd	local prwgt = prob.weight
	local Kskill = WS * (firm == mp and (P[WT[wt].p1] and 0.4 or 0.2) + (P.agi30 and 0.1 or 0) or 1)
	m.damage = prob.chopMax * (100 + Kskill)/100 * (prwgt == 0 and (0.6 + math.min(firm:getSkillValue(13),100) * ((firm ~= mp or P.con8) and 0.002 or 0.001)) or 1)
	
	local Kin = firm == mp and P.alt26 and math.min(math.min(mp.willpower.current,500)/10 + mp:getSkillValue(0)*0.3, cf.metlim) * sw or 0	local mc1 = 0
	if Kin > 0 then mc1 = Kin/(P.int39 and 10 or 5)		if PMP.current > mc1 then Mod(mc1)	Kin = Kin * L.Cpow(mp,0,true) * (P.wil31 and 1.25 or 1) else Kin = 0	mc1 = 0 end end
	
	if wt == 11 then	local Kstam = math.min(math.lerp((firm ~= mp or P.end1) and 0.75 or 0.5, 1, firm.fatigue.normalized*((firm ~= mp or P[WT[wt].p2]) and 2 or 1.25)), 1)
		spd = 1000*Kin/(prwgt+5) + ((math.min(firm.strength.current,500)*((firm ~= mp or P.str12) and 1.5 or 1))/(prwgt+5))^0.5 * (firm == mp and 500 or 1000) * sw * Kstam
	else	local Cond = firm.readiedWeapon.variables.condition/w.maxCondition		Cond = Cond > 1 and math.min(Cond,1.2) or math.lerp((firm ~= mp or P.arm2) and 0.5 or 0.25, 1, Cond)
		Cond = Cond * (w.weight == 0 and (0.6 + math.min(firm:getSkillValue(13),100) * ((firm ~= mp or P.con8) and 0.002 or 0.001)) * (firm == mp and P.con19 and D.BWwgt and 1.25 or 1) or 1)
		spd = 500*Kin/(prwgt+5) + ((w.chopMax * Cond)/math.clamp(prwgt, 0.2, 0.5)+0.1)^0.5 * (firm == mp and 500 or 1000) * sw
	end
	if firm == mp then spd = spd + 1000		if CPR[r] then CPR[r].spd = spd end
	elseif cf.enacc and firm.actionData.target == mp then
		local rpos = r.position
		m.velocity = L.UprPPos(rpos,spd,true) - rpos
		Matr:lookAt(m.velocity, V.up)		r.orientation = Matr:toEulerXYZ()
	end
	m.velocity = m.velocity:normalized() * spd
	if cf.m30 then tes3.messageBox("Proj spd %d (%d%%)  dmg %.1f (%d + %d%% skill)  sw = %.2f  Kin %.1f (%.1f cost)", spd, 4*spd/(spd/100+100), m.damage, prob.chopMax, Kskill, sw, Kin, mc1) end
end
--	tes3.messageBox("Sw = %.2f  Dam = %.2f  InSpd = %.2f  spd = %d  weap = %s  sn = %s", m.attackSwing, m.damage, m.initialSpeed, m.velocity:length(), m.firingWeapon and m.firingWeapon.id, si and si.serialNumber)
--	tes3.messageBox("%s  w = %s  sn = %s  fl = %s  disp = %s  exp = %s  movfl = %s", firm and firm.object.name, m.firingWeapon and m.firingWeapon.id, si and si.serialNumber, m.flags, m.disposition, m.expire, m.movementFlags)
else	
	local actort = m.actorType 		local ob = r.object 	local id = r.baseObject.id		local tdat = r.tempData		
	if actort then AF[r] = {}		table.insert(L.RAR, r)
		if actort == 1 or ob.biped then tdat.hum = true		tes3.applyConstantEffectEquipment{reference = r, activate = true} end
		tdat.hgt = m.height		tdat.mass = math.max(tdat.hgt^2, 5000)/10000 * (tdat.hum and 0.75 or 1)
		if not tdat.hum then tdat.Bspd = ob.attributes[5] end
		--tdat.anid = m.animationController.animationData

		N[r] = {m = m, hum = tdat.hum}		--dod = actort == 1 or ob.usesEquipment or L.CDOD[id]
		local Dopw = G.DopW[id] 	if Dopw then tes3.addItem{reference = r, item = Dopw} 	G.DopW[id] = nil end
		
		if m.fight > 49 then m.scanInterval = 1
			--tes3.messageBox("%s  %s    int =  %s", r, m.scanInterval, p.cell.isInterior)
		end
	end
	
--[[
if actort == 1 and not r.data.spawn then	r.data.spawn = true
	ob:reevaluateEquipment()
	tes3.setStatistic{reference = r, name = "health", value = ob.health + 200}
	tes3.messageBox("%s  recalc   HP =  %s    ob mod = %s    bob mod = %s", ob.name, m.health.base, ob.modified, r.baseObject.modified)
end
--]]

if actort == 0 and not r.data.spawn then	r.data.spawn = math.random(10)	local d = r.data.spawn		local typ = ob.type
	--if not ob.level then mwse.log("NO ob! ob id = %s   base = %s    ref = %s    Inv = %s   Spells = %s", ob.id, r.baseObject.id, r, ob.inventory, ob.spells) end
	if L.CrBlackList[id] then m.shield = L.CrBlackList[id] else		local mt = L.CRNIF[ob.mesh:lower()]
		local conj = 1		local conj2 = 0
		if G.summoner then	--tes3.messageBox("Summon spawn!  ref = %s   Master = %s", r, G.summoner)		
			r.data.SumM = G.summoner.id		r.tempData.SumR = G.summoner	
			if G.conjp or G.summoner.data.SumPl then r.data.SumPl = true end
			if not G.conjp or ((typ == 1 and P.con6b) or (typ == 2 and P.con6a)) then conj = 1 + G.conjsk/500 end
			
			if G.conjagr then m.fight = 100		m:startCombat(mp)	m.actionData.aiBehaviorState = 3
			elseif G.conjp then m.fight = math.max(math.random(50,70) + ob.level * 2 - G.conjsk * (P.con5 and 1 or 0.2), 50)
				for r, t in pairs(R) do m:startCombat(t.m) end
				if m.fight > 79 then timer.delayOneFrame(function() timer.delayOneFrame(function() m:startCombat(mp) end) end) end
				if P.con7 then conj2 = 0.1 end
			end
			G.summoner = nil
		end
		local koef = cf.randcr and math.random(80,120) or 100
		tes3.setStatistic{reference = r, name = "health", value = m.health.base * koef/100 * (conj + conj2)}	
		r.scale = r.scale * math.remap(koef, 80, 120, 0.95, 1.1)			--if L.CID[id] ~= "dwem"
		tes3.setStatistic{reference = r, name = "magicka", value = m.magicka.base * (cf.randcr and math.random(80,120)/100 or 1) * (conj + conj2)}
		tes3.setStatistic{reference = r, name = "fatigue", value = m.fatigue.base * (cf.randcr and math.random(80,120)/100 or 1) * (conj + conj2)}
		for i, stat in ipairs(L.CStats) do tes3.setStatistic{reference = r, name = stat, value = m[stat].base * (cf.randcr and math.random(80,120)/100 or 1) * conj} end		--attempt to index a nil value
		m.shield = (mt and mt.ar or m.endurance.current/10 + ob.level/2) * (cf.randcr and math.random(80,120)/100 or 1) * conj
		m.resistCommonDisease = 200		m.resistBlightDisease = 200
		tdat.hgt = m.height		tdat.mass = math.max(tdat.hgt^2, 5000)/10000 * (tdat.hum and 0.75 or 1)		-- повторный расчёт для учёта скейла
	end
	
G.SPList = ob.spells		--G.CRref = r
if L.CDIS[id] then G.SPList:add(L.CDIS[id]) end
if typ == 1 then -- Даэдра
	if id == "atronach_flame" or id == "atronach_flame_summon" then m.resistFire = m.resistFire + 200			rems("flamebolt", "fire storm", "cruel firebloom", "wizard's fire", "god's fire")
		if d > 5 then adds("flamebolt") end			if d > 6 then adds("fire storm") end		if d > 8 then adds("wizard's fire") end		if d == 10 then adds("cruel firebloom") end
	elseif id == "atronach_frost" or id == "atronach_frost_summon" then m.resistFrost = m.resistFrost + 200		rems("frost bolt", "frost storm", "brittlewind", "wizard rend", "god's frost")
		if d > 5 then adds("frost bolt") end		if d > 6 then adds("frost storm") end		if d > 8 then adds("wizard rend") end		if d == 10 then adds("brittlewind") end
	elseif id == "atronach_storm" or id == "atronach_storm_summon" then m.resistShock = m.resistShock + 200		rems("lightning bolt", "lightning storm", "wild shockbloom", "dire shockball", "god's spark")
		if d > 5 then adds("lightning bolt") end	if d > 6 then adds("lightning storm") end	if d > 8 then adds("dire shockball") end	if d == 10 then adds("wild shockbloom") end
	elseif id == "atronach_flame_lord" then m.resistFire = m.resistFire + 200
	elseif id == "atronach_frost_lord" then m.resistFrost = m.resistFrost + 200
	elseif id == "atronach_storm_lord" then m.resistShock = m.resistShock + 200
	elseif id == "dremora" or id == "dremora_summon" then	rems("summon scamp", "summon clanfear", "fire storm", "firebloom")
		if d > 8 then tes3.addItem{reference = r, item = "4nm_bow_excellent"}	tes3.addItem{reference = r, item = "4nm_arrow_magic+excellent", count = math.random(20,30)}
		elseif d == 8 then tes3.addItem{reference = r, item = "4nm_crossbow_excellent"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)}
		elseif d < 4 then adds(TC{"firebloom", "fire storm"}) end
		if math.random(3) == 1 then adds(TC{"summon scamp", "summon clanfear"}) end
	elseif id == "dremora_lord" then	rems("summon daedroth", "summon dremora", "summon flame atronach", "summon frost atronach", "summon storm atronach")
		if d > 2 then adds(TC{"summon daedroth", "summon dremora", "summon daedroth", "summon dremora", "summon flame atronach", "summon frost atronach", "summon storm atronach"}) end		
	elseif id == "dremora_mage" or id == "dremora_mage_s" then rems("summon flame atronach", "summon frost atronach", "summon storm atronach", "summon daedroth", "summon hunger", "summon clanfear",
		"fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large",
		"4s_kinetic_strike_1", "4s_kinetic_strike_2", "4s_kinetic_strike_3", "4s_elemental_ball_1", "4s_elemental_ball_2", "4s_elemental_ball_3",
		"firebloom", "frostbloom", "shockbloom", "flamebolt", "frost bolt", "lightning bolt", "fire storm", "frost storm", "lightning storm")
		adds(TC{"fireball", "frostball", "shockball", "4s_kinetic_strike_1", "4s_elemental_ball_1"}, TC{"Fireball_large", "Frostball_large", "shockball_large", "4s_kinetic_strike_2", "4s_elemental_ball_2"})
		if d > 2 then adds(TC{"firebloom", "frostbloom", "shockbloom"}) end
		if d > 5 then adds(TC{"flamebolt", "frost bolt", "lightning bolt", "4s_kinetic_strike_3", "4s_elemental_ball_3"}) end
		if d > 7 then adds(TC{"fire storm", "frost storm", "lightning storm"}) end
		if math.random(3) > 1 then adds(TC{"summon flame atronach", "summon frost atronach", "summon daedroth", "summon hunger", "summon clanfear"}) end
	elseif id == "scamp" or id == "scamp_summon" then	rems("flame", "fireball", "Fireball_large")
		if d > 5 then adds(TC{"flame", "fireball"}) end
	elseif id == "daedroth" or id == "daedroth_summon" then	rems("viperbolt", "poisonbloom")
		if d > 6 then adds("viperbolt", "poisonbloom")	elseif d < 3 then adds("viperbolt")	elseif d == 3 or d == 4 then adds("poisonbloom") end
	elseif id == "daedraspider" or id == "daedraspider_s" then	rems("bm_summonbonewolf", "summon daedroth", "summon hunger", "summon clanfear")
		if math.random(4) > 1 then adds(TC{"bm_summonbonewolf", "summon daedroth", "summon hunger", "summon clanfear"}) end
	elseif id == "winged twilight" or id == "winged twilight_summon" then	rems("fire storm", "frost storm", "lightning storm", "firebloom", "frostbloom", "shockbloom", "burning touch", "freezing touch", "shocking touch")
		if math.random(4) > 1 then adds(TC{"firebloom", "frostbloom", "shockbloom"}) end		if math.random(3) == 1 then adds(TC{"burning touch", "freezing touch", "shocking touch"}) end
		if math.random(3) == 1 then adds("fire storm") end		if math.random(3) == 1 then adds("frost storm") end		if math.random(3) == 1 then adds("lightning storm") end
	--	m.levitate = m.levitate + 5
	elseif id == "xivkyn" or id == "xivkyn_s" then	rems("wizard's fire", "sp_nchurdamzsummon")
		if d > 6 then adds("wizard's fire", "sp_nchurdamzsummon")	elseif d < 3 then adds("wizard's fire")	elseif d == 3 or d == 4 then adds("sp_nchurdamzsummon") end	
	elseif id == "mazken" or id == "mazken_s" then	rems("firebloom", "frostbloom", "shockbloom", "fire storm", "frost storm", "lightning storm", "summon winged twilight", "summon hunger", "summon dremora")
		if d > 8 then tes3.addItem{reference = r, item = "4nm_bow_excellent"}	tes3.addItem{reference = r, item = "4nm_arrow_magic+excellent", count = math.random(20,30)}
		else adds(TC{"firebloom", "frostbloom", "shockbloom"}, TC{"fire storm", "frost storm", "lightning storm"}) end
		if d < 10 then adds(TC{"summon winged twilight", "summon hunger", "summon dremora"}) end
	elseif id == "golden saint" or id == "golden saint_summon" then		rems("summon flame atronach", "summon frost atronach", "summon storm atronach")
		if d == 10 then adds("summon flame atronach")		elseif d == 1 then adds("summon frost atronach")	elseif d == 3 then adds("summon storm atronach") end
	elseif id == "hunger" or id == "hunger_summon" then rems("absorb health [ranged]", "daedric bite", "grave curse: health", "medusa's gaze", "paralysis", "red despair")
		if math.random(3) == 1 then adds("red despair") end		if math.random(4) == 1 then adds("daedric bite") end		if math.random(4) == 1 then adds("grave curse: health") end
		if math.random(4) == 1 then adds("medusa's gaze", "paralysis") end
	end
elseif typ == 2 then -- Нежить
	if id == "skeleton" or id == "skeleton_summon" then
		if d > 8 then tes3.addItem{reference = r, item = "long bow"}	tes3.addItem{reference = r, item = "iron arrow", count = math.random(20,30)}
		elseif d < 3 then m:equip{item = "iron_shield", addItem = true}
		elseif d == 8 then tes3.addItem{reference = r, item = "wooden crossbow"}	tes3.addItem{reference = r, item = "iron bolt", count = math.random(20,30)} end
	elseif id == "skeleton_mage" or id == "skeleton_mage_s" then
		rems("bone guard", "summon greater bonewalker", "summon skeletal minion",
		"fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom",
		"4s_kinetic_strike_1", "4s_kinetic_strike_2", "4s_elemental_ball_1", "4s_elemental_ball_2")
		adds(TC{"fireball", "frostball", "shockball", "4s_kinetic_strike_1", "4s_elemental_ball_1"})
		if d > 2 then adds(TC{"Fireball_large", "Frostball_large", "shockball_large", "4s_kinetic_strike_2", "4s_elemental_ball_2"}) end
		if d > 3 then adds(TC{"summon skeletal minion", "summon skeletal minion", "summon greater bonewalker"}) end
		if d > 7 then adds(TC{"firebloom", "frostbloom", "shockbloom"})		tes3.addItem{reference = r, item = "4nm_weapon_mage"} end
	elseif id == "bonelord" or id == "bonelord_summon" then	rems("bone guard", "summon least bonewalker", "4a_des1", "4a_des2", "blood despair")
		if d > 2 then adds(TC{"bone guard", "summon least bonewalker"}) end
		if d > 5 then adds("4a_des1", "4a_des2") else adds(TC{"4a_des1", "4a_des2"}) end
		if math.random(3) == 1 then adds("blood despair") end
	elseif id == "skeleton warrior" then
		if d == 1 then tes3.addItem{reference = r, item = "steel crossbow"}	tes3.addItem{reference = r, item = "steel bolt", count = math.random(20,30)} end
	elseif id == "skeleton archer" or id == "skeleton_archer_s" then
		if d > 9 then tes3.addItem{reference = r, item = "l_n_wpn_missle_thrown", count = math.random(5,20)}
		elseif d < 2 then tes3.addItem{reference = r, item = "4nm_thrown_magic", count = math.random(5,20)} end
	elseif id == "skeleton champion" then rems("frostbloom", "frost storm")
		if d < 3 then adds(TC{"frostbloom", "frost storm"}) elseif d == 3 then adds("frostbloom", "frost storm") end
	elseif id == "ash_revenant" then rems("scourge blade", "heartbite", "daedric bite")
		if d > 7 then m:equip{item = "steel_shield", addItem = true}
		elseif d > 4 then adds(TC{"scourge blade", "heartbite", "daedric bite"})
		elseif d < 3 then tes3.addItem{reference = r, item = TC{"l_n_wpn_missle_bow", "6th longbow"}}	tes3.addItem{reference = r, item = TC{"l_m_wpn_missle_arrow", "6th arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)} end	
	elseif id == "bonewalker" or id == "bonewalker_summon" then rems("poison", "poisonous touch")
		if d > 2 then adds(TC{"poison", "poisonous touch", "poisonous touch"}) end
	elseif id == "Bonewalker_Greater" or id == "Bonewalker_Greater_summ" then rems("viperbolt", "poisonbloom", "deadly poison", "deadly poison [ranged]")
		if d > 2 then adds(TC{"viperbolt", "viperbolt", "poisonbloom", "deadly poison", "deadly poison [ranged]"}) end
	elseif id == "draugr_priest" then rems("daedric bite", "frost bolt", "wizard rend", "bm_draugr_curse")
		if d > 2 then adds(TC{"daedric bite", "frost bolt", "wizard rend"})	if d > 8 then tes3.addItem{reference = r, item = "BM ice wand"}		adds("bm_draugr_curse") end end
	elseif id == "draugr_soldier" then
		if d > 5 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = "nordic_sky bow"}	tes3.addItem{reference = r, item = "nordic_sky arrow", count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "steel_sky crossbow"}	tes3.addItem{reference = r, item = "steel_sky bolt", count = math.random(20,30)} end	
	elseif id == "draugr_warrior" then
		if d > 5 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = TC{"nordic_sky bow", "BM ice longbow"}}	tes3.addItem{reference = r, item = TC{"nordic_sky arrow", "BM ice arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "steel_sky crossbow"}	tes3.addItem{reference = r, item = "steel_sky bolt", count = math.random(20,30)} end	
	end
elseif typ == 0 then -- Обычные кричеры	
	if L.CID[id] == "dwem" then m.resistParalysis = m.resistParalysis + 200
		if tes3.isAffectedBy{reference = p, object = "summon_centurion_unique"} and m.fight > 50 then m.fight = 50 end
		if id == "centurion_weapon" then
			if d > 5 then m:equip{item = "dwemer_shield", addItem = true}
			elseif d < 3 then tes3.addItem{reference = r, item = TC{"dwarven arbalest", "dwarven crossbow"}}	tes3.addItem{reference = r, item = "dwarven bolt", count = math.random(20,30)} end
		end
	elseif id == "goblin_grunt" then
		if d > 5 then m:equip{item = "goblin_shield", addItem = true}
		elseif d == 1 then tes3.addItem{reference = r, item = "goblin throwingaxe", count = math.random(5,10)}
		elseif d == 2 then tes3.addItem{reference = r, item = "goblin arrow", count = math.random(20,30)} end
	elseif id == "goblin_shaman" or id == "BM_riekling_shaman" then rems("fireball", "frostball", "shockball", "Fireball_large", "Frostball_large", "shockball_large", "firebloom", "frostbloom", "shockbloom",
		"4s_kinetic_strike_1", "4s_kinetic_strike_2", "4s_elemental_ball_1", "4s_elemental_ball_2")
		adds(TC{"fireball", "frostball", "shockball", "4s_kinetic_strike_1", "4s_elemental_ball_1"})
		if d > 3 then adds(TC{"Fireball_large", "Frostball_large", "shockball_large", "4s_kinetic_strike_2", "4s_elemental_ball_2"})		if d > 6 then adds(TC{"firebloom", "frostbloom", "shockbloom"}) end end
	end
elseif typ == 3 then -- Гуманоиды
	if id == "ash_slave" then rems("spark", "flame", "shard", "shockball", "fireball", "frostball", "Fireball_large", "Frostball_large", "shockball_large",
		"4s_kinetic_strike_1", "4s_kinetic_strike_2", "4s_elemental_ball_1", "4s_elemental_ball_2")
		if d > 7 then adds(TC{"Fireball_large", "Frostball_large", "shockball_large", "4s_kinetic_strike_2", "4s_elemental_ball_2"})
		elseif d > 3 then adds(TC{"fireball", "frostball", "shockball", "4s_kinetic_strike_1", "4s_elemental_ball_1"})
		elseif d > 1 then adds(TC{"spark", "flame", "shard"})
		else m:equip{item = "iron_shield", addItem = true} end
	--	adds("regenerate [ability]", "relvel_shield")	-- абилки добавятся в спелл лист базового существа и этого актера но не применятся на актере сразу - нужно новое событие активации.
	--	tes3.addSpell{reference = r, spell = "regenerate [ability]"}	tes3.addSpell{reference = r, spell = "relvel_shield"}
	elseif id == "ash_zombie" then
		if d > 8 then m:equip{item = "iron_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_bow"}	tes3.addItem{reference = r, item = "l_n_wpn_missle_arrow", count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "l_n_wpn_missle_bolt", count = math.random(20,30)}
		elseif d == 4 then tes3.addItem{reference = r, item = "6th throwingknife", count = math.random(5,10)} end
	elseif id == "ash_zombie_warrior" then	
		if d > 7 then m:equip{item = "steel_shield", addItem = true}
		elseif d < 3 then tes3.addItem{reference = r, item = TC{"l_n_wpn_missle_bow", "6th longbow"}}	tes3.addItem{reference = r, item = TC{"l_m_wpn_missle_arrow", "6th arrow"}, count = math.random(20,30)}
		elseif d == 3 then tes3.addItem{reference = r, item = "l_n_wpn_missle_xbow"}	tes3.addItem{reference = r, item = "4nm_bolt_magic+normal", count = math.random(20,30)} end
	elseif id == "ash_ghoul_warrior" then	rems("summon hunger", "summon daedroth", "summon clanfear", "summon dremora", "bound longsword", "bound mace", "bound spear", "bound battle-axe", "bound shield")
		if d > 5 then adds(TC{"summon hunger", "summon daedroth", "summon clanfear", "summon dremora"}) end
		if math.random(2) == 1 then adds(TC{"bound spear", "bound battle-axe"}) else adds(TC{"bound longsword", "bound mace"})		adds("bound shield") end
	elseif id == "ash_ghoul" then rems("summon hunger", "summon daedroth", "summon bonelord", "summon least bonewalker", "Fireball_large", "Frostball_large", "shockball_large",
		"flamebolt", "frost bolt", "lightning bolt", "ash feast",
		"4s_kinetic_strike_2", "4s_kinetic_strike_3", "4s_elemental_ball_2", "4s_elemental_ball_3")
			adds(TC{"Fireball_large", "Frostball_large", "shockball_large", "4s_kinetic_strike_2", "4s_elemental_ball_2"})
			if d > 7 then adds("ash feast") else adds(TC{"flamebolt", "frost bolt", "lightning bolt", "4s_kinetic_strike_3", "4s_elemental_ball_3"}) end
		if math.random(2) == 1 then adds(TC{"summon hunger", "summon daedroth", "summon bonelord", "summon least bonewalker"}) end
	elseif id == "ash_ghoul_high" then rems("summon flame atronach", "summon frost atronach", "summon storm atronach", "summon bonelord", "summon least bonewalker",
		"ash curse: fatigue", "ash curse: health", "ash curse: spell points", "ash feast", "4s_602a", "4s_kinetic_strike_3")
		if math.random(3) ~= 1 then adds("ash curse: health") end		if math.random(3) ~= 1 then adds("ash curse: fatigue") end		if math.random(3) ~= 1 then adds("ash curse: spell points") end
		adds(math.random(5) == 1 and "4s_kinetic_strike_3" or "ash feast")
		if d > 2 then adds(TC{"summon flame atronach", "summon frost atronach", "summon storm atronach", "summon bonelord", "summon least bonewalker"}) end
	--elseif id == "ascended_sleeper" then
	end
end
--r.baseObject.modified = true		-- применять если добавляем спеллы сделанные в луа
if cf.m9 then tes3.messageBox("%s (%s)  HP %d/%d   Mana %d/%d   Stam %d/%d   Str %d/%d   End %d/%d   Spd %d/%d   Agi %d/%d   Wil %d/%d   Int %d/%d   AR %d  ResFir %d   Fig %d  %s  %s",
r.object.name, d, m.health.current, r.baseObject.health, m.magicka.current, r.baseObject.magicka, m.fatigue.current, r.baseObject.fatigue,
m.strength.current, r.baseObject.attributes[1], m.endurance.current, r.baseObject.attributes[6], m.speed.current, r.baseObject.attributes[5], m.agility.current, r.baseObject.attributes[4], 
m.willpower.current, r.baseObject.attributes[3], m.intelligence.current, r.baseObject.attributes[2], m.shield, m.resistFire, m.fight, r.data.SumM and "Summon" or "", r.baseObject.modified and "MOD" or "") end
end end end end		event.register("mobileActivated", MOBILEACTIVATED)

-- Первый эвент исчезновения снарядов.
local function MOBILEDEACTIVATED(e) local r = e.reference		local m = e.mobile
	N[r] = nil
	if AF[r] then AF[r] = nil		table.removevalue(L.RAR, r) end		--tes3.messageBox("%s   Deact = %s", r, table.size(AF))
	if R[r] then R[r] = nil	if cf.m4 then tes3.messageBox("%s deactivated  Enemies = %s", r, table.size(R)) end end
	
--	if m.actorType then tes3.messageBox("DEA %s   INT = %s   fall = %s  low = %s    dist = %d   dead = %s   rint = %s  cell = %s",
--	r, G.LowestZ and true, m.isFalling, G.LowestZ and r.position.z < G.LowestZ, pp:distance(r.position), m.isDead, r.cell.isInterior, r.cell == p.cell) end
	
	if G.LowestZ and m.actorType and r.position.z < G.LowestZ and G.CurCell == r.cell then		--pp:distance(r.position) > 7000
		tes3.messageBox("%s EXTRA RETURN   Z = %d   Low = %d     Pdif = %d   dist = %d", r, r.position.z, G.LowestZ, pp.z - r.position.z, pp:distance(r.position))
		r.position = pp + p.forwardDirection * 100
	end
end		event.register("mobileDeactivated", MOBILEDEACTIVATED)


-- Вторые эвенты исчезновения снарядов.			 1 ft = 22.1 units
local function PROJECTILEHITACTOR(e) local firr = e.firingReference		local tar = e.target	if (firr == p and firr ~= tar) or (firr ~= p and not firr.data.SumM	and firr.mobile.actionData.target == tar.mobile) then
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

local function onProj(e) local r = e.mobile.reference	local ob = r.object		local firr = e.firingReference		local cp = e.collisionPoint		local dist = cp:distance(pp)	--tes3.messageBox("Dist = %d", dist)
	local add = cf.addpr and not L.BlackAmmo[ob.id] and firr and not firr.data.SumM						--	local tar = e.target
	if math.abs(cp.x) < 9000000 and (add or dist < 30000) then
		local vel = e.velocity		local pos, hr
		local hit = tes3.rayTest{position = cp - vel:normalized()*10, direction = vel, maxDistance = 250, findAll = true}			--cp + e.velocity * 0.7 * wc.deltaTime
		if hit then
			for i, h in pairs(hit) do hr = h.reference
				if not hr or not hr.mobile then pos = h.intersection
					if dist < 3000 then
						local dir		local Mat = L.MAT[L.GetMat(h)] or "Metal"		if Mat == "Water" then dir = Mat else dir = Mat .. 1 end
						tes3.playSound{reference = p, soundPath = L.RSound(dir), volume = cf.volimp / (1 + (dist/1000)^2), pitch = math.random(90,110)/100}
						if L.MatSpark[Mat] then tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = pos} end
					end
					break
				end
			end
		end 
		if not pos then local hitd = tes3.rayTest{position = cp, direction = V.down, ignore = tes3.game.worldPickRoot}		pos = hitd and hitd.intersection end
		if add and pos then
			if ob.enchantment then ob = L.AMIC[ob.icon:lower()]		ob = ob and tes3.getObject(ob) end		
			if ob then				
				Matr:lookAt(ob.type == 11 and ob.speed > 0.99 and ob.speed < 1.26 and vel * -1 or vel, V.up)			--orientation = r.sceneNode.worldTransform.rotation:toEulerXYZ()
				local ref = tes3.createReference{object = ob, cell = p.cell, orientation = Matr:toEulerXYZ(), position = pos}	ref.modified = false	PRR[ref] = true
				--tes3.createReference{object = "4nm_boundarrow", cell = p.cell, orientation = r.sceneNode.worldTransform.rotation:toEulerXYZ(), position = cp}
				--	tes3.messageBox("Hit object = %s", r)
			end 
		end
	end
end		event.register("projectileHitObject", onProj)		event.register("projectileHitTerrain", onProj)


-- Третий эвент исчезновения снарядов. Прожектайл Экспире НЕ триггерится если снаряд убит командой стейт = 6. Триггерится при m.expire = 1 и целл чейнджед		tes3.messageBox("ex  %s    si = %s", pr, si and si.serialNumber or "nil")
L.EXPLKoef = {["4b_EXP"] = 0, ["4b_WAV"] = 0, ["4b_SG"] = 0.2, ["4b_RAY"] = 0.1}
local function PROJECTILEEXPIRE(e) local pm = e.mobile	local fir = e.firingReference	local pos = pm.position:copy()	local si = pm.spellInstance		local sn = si and si.serialNumber		if si then COL[sn] = pos end
if fir == p then
	if si then local eff = si.source.effects
		if D.Emp and not D.Empdis then	local mk = L.EXPLKoef[si.source.name] or 1	 if mk ~= 0 then L.EmpSpell(p, pos, mk) end	end
		
		if W.TETP and W.TETP == pm.reference then W.TETP = nil	G.TETmod = 3	L.GetMetRetSpd() end
		if V.MET[sn] then local wr = V.MET[sn].r	local drop
			if V.METR[wr] then
				L.GetMetRetSpd()
				if not V.METR[wr].f then V.METR[wr].f = 1 end
			else drop = true end
			if drop then local hit = tes3.rayTest{position = wr.position - pm.velocity:normalized()*100, direction = V.down}
				if hit then wr.position = hit.intersection + tes3vector3.new(0,0,5) end
				
			--	local wob = wr.object
			--	if wob.weight == 0 then for _, aef in pairs(mp:getActiveMagicEffects{}) do if aef.isBoundItem and aef.effectInstance.createdData.object == wob then tes3.messageBox("%s  Found!", wob)	break
			--	end end end
			end
		elseif L.ELME[eff[1].id] and si.source.name ~= "4b_WAV" then	local rad = 0		local radbon = L.GetRad(mp)		local expk		--attempt to index local 'eff' (a nil value)
			for i, ef in ipairs(eff) do expk = L.ELME[ef.id]  		if expk and ef.radius > 9 then rad = rad + expk * math.random(ef.min, ef.max) * (ef.radius - 10 + radbon) end end
			if rad > 99 then rad = rad * L.Cpow(mp,0) * (SN[sn] or 1) * (P.des8 and 1 or 0.5)		rad = 20 * rad^0.5		L.KBlast(pos, rad, sn, p) end
		end
	else
		if D.poison then D.poison = D.poison - (P.agi12 and 25 or 30) + math.min(math.min(mp.agility.current,500) + mp:getSkillValue(16),600)/40
			M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end
		end
		if G.wf == 2 and pm.firingWeapon == W.w then local ensi = tes3.applyMagicSource{reference = p, source = W.en, fromStack = mp.readiedWeapon}
			MP[ensi] = {pos = pos, exp = true}		G.EnWsn = ensi.serialNumber
		end
		if D.CW and not D.CWdis and cf.smartcw then	L.CWF(p, 2, 1.5, pos) end
	end
elseif fir then
	if si then
		if fir.data.Emp then	local mk = L.EXPLKoef[si.source.name] or 1	 if mk ~= 0 then L.EmpSpell(fir, pos, mk) end	end
	else
		if fir.data.CW then L.CWF(fir, 2, 1.5, pos) end
	end
end			--tes3.messageBox("ex  %s    si = %s", pm.reference, si and si.serialNumber or "nil")
end		event.register("projectileExpire", PROJECTILEEXPIRE)


local function OBJECTINVALIDATED(e) local ob = e.object				--tes3.messageBox("%s   INVALID", ob)
	if CPR[ob] then CPR[ob] = nil elseif CPRS[ob] then CPS[CPRS[ob].n] = 0	CPRS[ob] = nil end
	if ob == G.TETR then if cf.m then tes3.messageBox("Telekinesis: Invalidated") end	G.TETR = nil end
	if V.METR[ob] then V.METR[ob] = nil		if cf.m then tes3.messageBox("Throw: Invalidated") end end
	if DER[ob] then DER[ob] = nil end
	if PRR[ob] then PRR[ob] = nil end
end		event.register("objectInvalidated", OBJECTINVALIDATED)

local function DEATH(e) local r = e.reference
	if R[r] then R[r] = nil	if cf.m4 then tes3.messageBox("%s dead  Enemies = %s", r, table.size(R)) end end
	H[r] = nil
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
local function CELLCHANGED(e) AC = {}		for _, cell in pairs(tes3.getActiveCells()) do AC[cell] = true end		local int = e.cell.isInterior	local prcell = e.previousCell		--cf.ft100
	G.LowestZ = cf.lowZ and int and tes3.dataHandler.lowestZInCurrentCell - 300 or nil		G.CurCell = e.cell
	if cf.trmod then local tim = T.T1.timing - G.Exptim		for i = 1, 4 do	D.ExpFat[i] = math.max(D.ExpFat[i] - tim, 0) end		G.Exptim = T.T1.timing end
	if prcell then	local intcell = int or prcell.isInterior
		if G.TETmod and intcell then p:activate(G.TETR) end
		if W.metflag and intcell then for r, t in pairs(V.METR) do p:activate(r) end	V.METR = {}	end

		if table.size(H) > 0 then
			if T.Dtim.timeLeft and intcell then	local door
				if table.size(H) ~= 0 then	local mind = 1000	local dist
					for dref in p.cell:iterateReferences(tes3.objectType.door) do if dref.destination then dist = p.position:distance(dref.position)		if mind > dist then mind = dist		door = dref end end end
				end
				
				for r, t in pairs(H) do
					if t.safe:valid() then
						if t.status == 1 then
							if r.cell ~= p.cell and (r.cell.isInterior or p.cell.isInterior) then t.tcell = p.cell	t.tpos = p.position:copy()	t.status = 0	t.door = door
							elseif AC[r.cell] then	if cf.m12 then tes3.messageBox(eng and "%s see you!" or "%s видит вас!", r.object.name) end end
						elseif t.status == 2 then
							if not AC[r.cell] and not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}	H[r] = nil
								if cf.m12 then tes3.messageBox(eng and "%s is beaten and returned to his place" or "%s побит и возвращается на свое место", r.object.name) end
							end
						elseif t.status == 3 then
							if AC[r.cell] then	t.status = 1	if cf.m12 then tes3.messageBox(eng and "%s see you again!" or "%s снова видит вас!", r.object.name) end
							elseif not AC[t.scell] then tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		H[r] = nil	mp:exerciseSkill(19, r.object.level/10)			--[C]: in function 'positionCell'
								if cf.m12 then tes3.messageBox(eng and "%s returned to his place" or "%s возвращается на свое место", r.object.name) end
							end
						elseif t.status == 0 and AC[r.cell] then t.status = 1	if cf.m12 then tes3.messageBox(eng and "%s see you again!!" or "%s снова видит вас!!", r.object.name) end end
					else H[r] = nil		tes3.messageBox("ref not valid") end
				end
				
				if table.size(H) ~= 0 then 
					if not T.HUNT.timeLeft then T.HUNT = timer.start{duration = 1, iterations = -1, callback = function() local fin = true	local DOORS = {}
						for r, t in pairs(H) do		if t.status == 0 then fin = nil		t.tim = t.tim - 1
							if t.tim <= 0 then
								local lock = t.door and t.door.lockNode
								if lock and lock.locked then DOORS[t.door] = math.max(t.unl, DOORS[t.door] or 0)
								else
									tes3.positionCell{cell = t.tcell, position = t.tpos, reference = r}
									if AC[t.tcell] then	t.status = 1	r.mobile:startCombat(mp)		r.mobile.actionData.aiBehaviorState = 3
										if cf.m12 then tes3.messageBox(eng and "%s opened the door and found you! Distance = %d" or "%s открыл дверь и нашел вас! Дистанция = %d", r.object.name, p.position:distance(t.tpos)) end
									else t.status = 3
										if cf.m12 then tes3.messageBox(eng and "%s opened the door and lost sight of you!" or "%s открыл дверь и потерял вас из виду!", r.object.name) end
									end
								end
							end
						end end
						for d, unl in pairs(DOORS) do d.lockNode.level = math.max(d.lockNode.level - unl)		if d.lockNode.level < 1 then tes3.unlock{reference = d} end end	
						if fin then T.HUNT:cancel()	if cf.m12 then tes3.messageBox(eng and "The chase is over" or "Погоня окончена") end end
					end} end
				end
			elseif not intcell then
				for r, t in pairs(H) do
					if t.safe:valid() then
						if not r.cell.isInterior and p.position:distance(r.position) > 13000 then
							if cf.m12 then tes3.messageBox(eng and "%s returned to his place (ext) dist = %d" or "%s возвращается на свое место (экстерьер) Дистанция = %d", r.object.name, p.position:distance(r.position)) end
							tes3.positionCell{cell = t.scell, position = t.spos, reference = r}		mp:exerciseSkill(19, r.object.level/10)		H[r] = nil
						end
					else H[r] = nil		tes3.messageBox("ref not valid (ext)") end
				end
			else
				for r, t in pairs(H) do
					if t.safe:valid() then
						if not AC[t.scell] then
							tes3.positionCell{cell = t.scell, position = t.spos, reference = r}
							if cf.m12 then tes3.messageBox(eng and "%s returned to his place (teleport)" or "%s возвращается на свое место (телепорт)", r.object.name) end		H[r] = nil	--[C]: in function 'positionCell'
						end
					else H[r] = nil		tes3.messageBox("ref not valid (Teleport)") end
				end
			end
		end
	end
end		event.register("cellChanged", CELLCHANGED)

local function MOUSEWHEEL(e) if not tes3ui.menuMode() then local CS = mp.currentSpell
	local num = table.wrapindex(D.FS, math.max((CS and table.find(D.FS, CS.id) or 0) + (e.delta > 0 and -1 or 1), 0))		local sid = D.FS[num]
	if sid then if p.object.spells:contains(sid) then mp:equipMagic{source = sid} else table.remove(D.FS, num) end end
end	end		--if cf.scrol then event.register("mouseWheel", MOUSEWHEEL) end





L.MousAx = function(e) 
G.MoX = math.clamp(G.MoX + e.deltaX,-500,500)	G.MoY = math.clamp(G.MoY - e.deltaY,-500,500)
local Ang = math.atan2(G.MoX, G.MoY)	if Ang < 0 then Ang = G.pi2 + Ang end
Ang = Ang + G.WHang/2					if Ang > G.pi2 then Ang = Ang - G.pi2 end

G.WHcur = math.ceil(Ang / G.WHang)

if G.WHcur ~= G.WHlast then
	if G.WHlast then M.WH[G.WHlast].width = 32		M.WH[G.WHlast].height = 32		M.WH[G.WHlast].scaleMode = false end
	M.WH[G.WHcur].width = 64		M.WH[G.WHcur].height = 64		M.WH[G.WHcur].scaleMode = true
	M.WH[0]:updateLayout()
end
G.WHlast = G.WHcur

--local Dist = math.sqrt(G.MoX*G.MoX + G.MoY*G.MoY)		tes3.messageBox("Dx = %s    Dy = %s     Dist = %d   Ang = %.3f   Cur = %d   Sens = %s", G.MoX, G.MoY, Dist, Ang, G.WHcur, wc.mouseSensitivityX)
end


L.WHOn = function(on)
	if on then	G.MoX = 0		G.MoY = 0		G.WHlast = nil		G.WHcur = nil	wc.mouseSensitivityX = G.MosX/10		wc.mouseSensitivityY = G.MosY/10		event.register("mouseAxis", L.MousAx)
	else	M.WH[0]:destroy()	M.WH = nil											wc.mouseSensitivityX = G.MosX			wc.mouseSensitivityY = G.MosY			event.unregister("mouseAxis", L.MousAx)	end
end


L.KeyUpWH = function(e) if e.keyCode == cf.qwhkey.keyCode then
	if G.WHcur then		local id = D.QW[G.WHcur]
		if not id or ic:isAltDown() then
			tes3.messageBox{message = eng and "Select a spell or item for this quick slot" or "Выберите заклинание или предмет для этого быстрого слота",
			buttons = eng and {"Spell", "Item", "Clear slot"} or {"Заклинание", "Предмет", "Очистить слот"}, callback = function(mt)
				if mt.button == 0 then
					tes3ui.showMagicSelectMenu{title = eng and "Select a spell for this quick slot" or "Выберите заклинание для этого быстрого слота", callback = function(t)
						if t.spell then D.QW[G.WHcur] = t.spell.id elseif t.item then D.QW[G.WHcur] = t.item.id end		tes3ui.leaveMenuMode()
					end}
				elseif mt.button == 1 then
					tes3ui.showInventorySelectMenu{title = eng and "Select a item for this quick slot" or "Выберите предмет для этого быстрого слота", filter = "quickUse", callback = function(t)
						if t.item then D.QW[G.WHcur] = t.item.id end	tes3ui.leaveMenuMode()
					end}
				else D.QW[G.WHcur] = false end
			end}
		elseif id then
			local ob = tes3.getObject(id)	local ct = ob.castType
			if ct then
				if p.object.spells:contains(ob) or ct == 5 then
					if MB[cf.mbsp2] == 128 then G.SP2 = ob	D.SP2 = id		M.S2IC.contentPath = "icons\\" .. G.SP2.effects[1].object.bigIcon
					else mp:equipMagic{source = ob} end
				else D.QW[G.WHcur] = false end
			elseif inv:contains(ob) then
				local enc = ob.enchantment		ct = enc and enc.castType
				if ct == 0 or ct == 2 then mp:equipMagic{source = ob, equipItem = true}
				else	
					if ob.effects then mwscript.equip{reference = p, item = ob}
					else local best = not ob.quality		mp:equip{item = ob, selectBestCondition = best, selectWorstCondition = not best} end
				end
			end
		end
	end
	L.WHOn()	event.unregister("keyUp", L.KeyUpWH)
end end



L.KeyUpWHCon = function(e) if e.keyCode == cf.conwhkey.keyCode then
	if G.WHcur then	D.ConN = G.WHcon[G.WHcur]		M.Cicon.contentPath = M.WH[G.WHcur].contentPath end
	L.WHOn()	event.unregister("keyUp", L.KeyUpWHCon)
end end

L.PrCON = {[1] = {ind = 0, ru = "Контроль снарядов", eng = "Target projectiles"},
[2] = {ind = 1, ru = "Самонаводящиеся снаряды", eng = "Homing projectiles", perk = "mys8b"},
[3] = {ind = 12, ru = "Рикошетящие снаряды", eng = "Ricochet projectiles", perk = "alt8d"},
[4] = {ind = 3, ru = "Телепорт снарядов", eng = "Teleport projectiles", perk = "mys8a"},
[5] = {ind = 2, ru = "Вращение снарядов", eng = "Spin projectiles", perk = "alt8b"},
[6] = {ind = 4, ru = "Магические мины", eng = "Magic mines", perk = "alt8c"}}


L.KeyUpWHProj = function(e) if e.keyCode == cf.cpkey.keyCode then
	if G.WHcur then	local t = L.PrCON[G.WHcur]
		if G.WHcur == 1 or P[t.perk] then DM.cp = t.ind			tes3.messageBox(eng and t.eng or t.ru)
		else tes3.messageBox("%s %s", eng and "You don't know how to use" or "Вы еще не умеете использовать", eng and t.eng or t.ru) end
	else DM.cp = nil		tes3.messageBox(eng and "Projectile control disabled" or "Контроль снарядов отключен") end
	L.WHOn()	event.unregister("keyUp", L.KeyUpWHProj)
end end

L.DodCalc = function()
	local DodSt = (P.acr16 and 25 or 30) * (G.ENC*(P.atl16 and 0.25 or 0.5) + (D.AR.dc < 1 and D.AR.dc or math.max(D.AR.dc - G.LIG,1)))
	local Base = 100 + mp.sanctuary * (P.spd16 and 1 or 0.8) + math.min(mp.agility.current,500) * (G.TR.tr26 and 0.5 or 0.3) + mp:getSkillValue(20) * (P.acr15 and 0.5 or 0.3)
	local KoefD = D.AR.dk > 1 and D.AR.dk or math.min(D.AR.dk + G.LIG, 1)
	local StamK = math.min(math.lerp(P.end20 and 0.75 or 0.5, 1, G.STN * (P.atl7 and 2 or 1.25)), 1)
	return DodSt, Base * KoefD * StamK
end

local function KEYDOWN(e) if not tes3ui.menuMode() then local k = e.keyCode		--tes3.messageBox("key = %s   jump = %s", k, ic.inputMaps[12].code)
if k == cf.conkey.keyCode then
	if M.MCB.current > 0 then
		if M.MCB.current > (P.wil10 and 0 or 50) then		-- Быстрый каст
			if mp.hasFreeAction and (P.agi17 or mp.paralyze < 1) and ad.animationAttackState ~= 10 and not mp.isHitStunned then		local CS = mp.currentSpell
				if CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 then
					local excost = (CS.alwaysSucceeds and 10 or 0) + CS.magickaCost * (P.int13 and 0.5 or 1) + (P.agi24 and 10 or 20)
					local stc = CS.magickaCost * (P.end8 and 0.5 or 1)
					if M.MCB.current >= excost and PST.current > stc then		PST.current = PST.current - stc
						--if ad.animationAttackState == 2 then MB[1] = 0 end
						if mp.invisibility > 0 then tes3.removeEffects{reference = p, effect = 39} end
						G.LastQS = CS		tes3.cast{reference = p, spell = CS, instant = true, alwaysSucceeds = false}
						M.MCB.current = math.max(M.MCB.current - excost, 0)
					end
				end
			end
		end
	else		-- Концентрация
		if D.ConSN then local si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.ConSN}	if si then si.state = 6 end		D.ConSN = nil
		else
			local DT = D.CON["d"..D.ConN]		local St = D.CON["s"..D.ConN]
			if DT and St and PST.current > 0 then
				PST.current = math.max(PST.current - St * (P.luc16 and 0.5 or 1), 0)
				D.ConSN = (tes3.applyMagicSource{reference = p, name = "Concentration", effects = DT}).serialNumber		T.CON:reset()
			else tes3.messageBox(eng and "This concentration slot needs to be updated" or "Этот слот концентрации необходимо обновить") end
		end
	end
elseif k == cf.sp2qkey.keyCode then
	if M.MCB.current > (P.wil10 and 0 or 50) and G.SP2 then		-- Быстрый каст вторичного спелла
		if mp.hasFreeAction and (P.agi17 or mp.paralyze < 1) and ad.animationAttackState ~= 10 and not mp.isHitStunned then
			local excost = (G.SP2.alwaysSucceeds and 10 or 0) + G.SP2.magickaCost * (P.int13 and 0.5 or 1) + (P.agi24 and 10 or 20)
			local stc = G.SP2.magickaCost * (P.end8 and 0.5 or 1)
			if M.MCB.current >= excost and PST.current > stc then		PST.current = PST.current - stc
				if mp.invisibility > 0 then tes3.removeEffects{reference = p, effect = 39} end
				G.LastQS = G.SP2		tes3.cast{reference = p, spell = G.SP2, instant = true, alwaysSucceeds = false}
				M.MCB.current = math.max(M.MCB.current - excost, 0)
			end
		end
	end
elseif k == cf.dashkey.keyCode and not G.dfr and mp.paralyze < 1 then		-- дэши
	local StamCur = PST.current
	if not mp.hasFreeAction then	-- Нокдаун или нокаут
		if mp.isKnockedDown then
			if P.agi25 then		local stc = 100 * (1 + G.ENC)
				if StamCur > stc then PST.current = StamCur - stc		ad.animationAttackState = 0		if cf.m then tes3.messageBox("Stand up! Stamcost = %d", stc) end	return end
			end
		end
		if not P.agi17 then return end	
	end

	local dkik = MB[3] == 128	local mag = Mag(600)	local DMag = dkik and mag or math.min(mag, cf.dash)
	local dash		local DodSt, DodPow = L.DodCalc()		local HS = mp.isHitStunned		if HS then DodPow = DodPow/2 end
	if DMag > 0 then	if dkik then dash = true else dash = cf.dprior	if MB[cf.mbdod] == 128 then dash = not dash end end		end
	
	if dash then	local ang, timk, dist, DodBon
		if T.Dash.timeLeft then timk = 1 + T.Dash.timeLeft/(P.atl8 and 10 or 5) else timk = 1 end
		if P.spd15 and DodSt * timk < StamCur then DodBon = DodPow else DodBon = 0 end
		
		if mp.isMovingForward then if mp.isMovingLeft then ang = 315 elseif mp.isMovingRight then ang = 45 end
		elseif mp.isMovingBack then if mp.isMovingLeft then ang = 45 elseif mp.isMovingRight then ang = 315 end
		elseif mp.isMovingLeft then ang = 270 elseif mp.isMovingRight then ang = 90 end
		V.d = tes3.getPlayerEyeVector()		if ang then Matr:toRotationZ(math.rad(ang))	V.d = Matr * V.d end
		if ang == 90 or ang == 270 then V.d.z = 0	V.d = V.d:normalized()
		else	
			if mp.isMovingBack then V.d = V.d*-1		if math.abs(V.d.z) < 0.5 then V.d.z = 0		V.d = V.d:normalized() end
			elseif math.abs(V.d.z) < 0.15 then V.d.z = 0	V.d = V.d:normalized() end
		end
		if dkik then local kref		kref, dist = L.Sector{d = 9000, lim = 500, v = V.d} end
		if not dist then 
			local dhit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = V.d, ignore = L.RAR}		
			if dhit then dist = dhit.distance else dist = 10000 end
		end
		local DK = (P.spd8 and 80 or 60) * (1 + (P.una15 and D.AR.u*0.01 or 0)) * (HS and 0.5 or 1)	
		DMag = math.clamp((dist - DodBon)/DK, 0, DMag)
		local DD = DMag * DK + DodBon
		local mc = math.max(DMag + (P.acr8 and mp.isFalling and 0 or math.min(DMag,5)) - (P.alt10 and mag/10 or 0), 0) * L.MCOST(0) * timk

		if mc < PMP.current then 
			local vk = math.max(-0.4 - V.d.z, 0)/3
			local stam = mc * ((P.end10 and 1 or 2) - (P.una10 and D.AR.u*0.04 or 0)) + (DodBon > 0 and DodSt * timk or 0)
			V.d = V.d*(DD/0.15 * (1 - vk))		G.dfr = 0.15		
			tes3.playSound{soundPath = L.RSound("Dash"), volume = 1, pitch = math.random(90,110)/100}		--volume = math.min(0.5 + DD/4000,1)
			if DodBon > 0 and P.agi17 and HS and ad.animationAttackState == 1 then ad.animationAttackState = 0 end		-- Высвобождение из хитстана
			if not mp.isJumping then V.djf = true	mp.isJumping = true end			if dkik and cf.autokik then V.dkik = true end
			Mod(mc)		if StamCur > 0 then PST.current = math.max(StamCur - stam, 0) end
			if cf.m then tes3.messageBox("Dash dist = %d  Cost = %.1f + %d stam  Time = %.1f  SlamK = %d%%", DD, mc, stam, T.Dash.timeLeft or 0, vk*100) end
			G.DashD = DD * (P.str9 and 0.02 or 0.01)
			if T.Dash.timeLeft then T.Dash:cancel()	end		T.Dash = timer.start{duration = 3, callback = function() end}
			if P.atl15 and DD > 299 and T.SPR.timeLeft then T.SPR:cancel() end
		else dash = false end
	end
	if not dash and (P.acr13 or not mp.isFalling) then
		if T.Dod.timeLeft then DodSt = DodSt * (1 + T.Dod.timeLeft/(P.atl10 and 10 or 5)) end
		if DodSt < StamCur then	V.d = nil
			if mp.isMovingRight then V.d = p.rightDirection elseif mp.isMovingLeft then V.d = p.rightDirection * -1 end
			if mp.isMovingForward then V.d = (V.d or V.nul) + p.forwardDirection elseif mp.isMovingBack then V.d = (V.d or V.nul) + p.forwardDirection * -1 elseif not V.d then V.d = p.forwardDirection end
			G.dodm = DodPow		V.d = V.d:normalized() * G.dodm / 0.1		G.dfr = 0.1		
			PST.current = StamCur - DodSt
			tes3.playSound{soundPath = L.RSound("Dodge"), volume = 1, pitch = math.random(90,110)/100}	--	if not mp.isFalling then tes3.playSound{sound = math.random(2) == 1 and "RightM" or "LeftM"} end
			if P.agi17 and HS and ad.animationAttackState == 1 then ad.animationAttackState = 0 end		-- Высвобождение из хитстана
			if not mp.isJumping then V.djf = true	mp.isJumping = true end
			if cf.m then tes3.messageBox("Dodge dist = %d   Cost = %d   Time = %.1f", G.dodm, DodSt, T.Dod.timeLeft or 0) end
			if P.sec6 and (T.Dod.timeLeft or 0) < 2.5 and mp.inCombat and mp.invisibility == 0 then tes3.applyMagicSource{reference = p, name = "Dodge", effects = {{id = 510, min = 50, max = 50, duration = 1}}} end
			if T.Dod.timeLeft then T.Dod:cancel() end	T.Dod = timer.start{duration = 3, callback = function() G.dodm = nil end}
			if P.atl15 and T.SPR.timeLeft then T.SPR:cancel() end
		end
	end
	
elseif k == cf.kikkey.keyCode then L.KIK()

elseif k == cf.qwhkey.keyCode then
	if e.isShiftDown then	local CS = mp.currentSpell
		if CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 then
			G.SP2 = CS		D.SP2 = CS.id		M.S2IC.contentPath = "icons\\" .. G.SP2.effects[1].object.bigIcon
		end
	elseif e.isControlDown then	local CS = mp.currentSpell
		if CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 then
			local sid = CS.id	local num = table.find(D.FS, sid)
			if num then table.remove(D.FS, num)		tes3.messageBox("%s removed from Favorite Spells (%s)", CS.name, num)
			else D.FS[table.size(D.FS) + 1] = sid	tes3.messageBox("%s added to Favorite Spells (%s)", CS.name, table.size(D.FS)) end
		end
	elseif e.isAltDown then D.FS = {}	tes3.messageBox("Favorite spell list cleared")
	elseif not M.WH then
		if cf.whn > #D.QW then for i = 1, cf.whn do if D.QW[i] == nil then D.QW[i] = false end end end
		local ob, ic, enc, count
		G.WHang = G.pi2 / cf.whn
		M.WH = {}	M.WH[0] = tes3ui.createHelpLayerMenu{id = "WH_Menu", fixedFrame = true}		M.WH[0]:destroyChildren()
		M.WH[0].absolutePosAlignX = 0.5		M.WH[0].absolutePosAlignY = 0.5		M.WH[0].color = {0,0,0}		M.WH[0].alpha = cf.whalf	M.WH[0].minWidth = cf.whwid		M.WH[0].minHeight = cf.whwid
		for i = 1, cf.whn do
			ob = D.QW[i] and tes3.getObject(D.QW[i])	enc = nil	count = nil
			if ob then
				if ob.castType then ic = ob.effects[1].object.bigIcon
				else	ic = ob.icon	enc = ob.enchantment
					if enc then		if not cf.scroll or ob.objectType ~= tes3.objectType.book then enc = enc.effects[1].object.icon else enc = nil end
					else enc = ob.effects	if enc then enc = ob.objectType == tes3.objectType.alchemy and enc[1].object.icon or tes3.getMagicEffect(enc[1]).icon end end
					count = tes3.getItemCount{reference = p, item = ob}	
				end
			else ic = "k\\magicka.dds" end
			
			M.WH[i] = M.WH[0]:createImage{path = "icons\\" .. ic}
			M.WH[i].absolutePosAlignX = 0.5 + math.cos(G.WHang * (i - 1) - math.pi/2) * 0.4
			M.WH[i].absolutePosAlignY = 0.5 + math.sin(G.WHang * (i - 1) - math.pi/2) * 0.4
			if ob then 
				if enc then enc = M.WH[i]:createImage{path = "icons\\" .. enc}		enc.absolutePosAlignX = 1	enc.absolutePosAlignY = 0 end
				if count and count ~= 1 then count = M.WH[i]:createLabel{text = ("%s"):format(count)}		count.color = {1,1,1}		count.absolutePosAlignX = 1		count.absolutePosAlignY = 1 end
			end
		end		M.WH[0]:updateLayout()
		L.WHOn(1)	event.register("keyUp", L.KeyUpWH)
	end
elseif k == cf.conwhkey.keyCode then
	if not M.WH then	G.WHcon = {}	local num = 0		for i = 1, 8 do if D.CON["s"..i] then num = num + 1	G.WHcon[num] = i end end		G.WHn = num
		if G.WHn > 0 then
			G.WHang = G.pi2 / G.WHn
			M.WH = {}	M.WH[0] = tes3ui.createHelpLayerMenu{id = "WH_Menu", fixedFrame = true}		M.WH[0]:destroyChildren()
			M.WH[0].absolutePosAlignX = 0.5		M.WH[0].absolutePosAlignY = 0.5		M.WH[0].color = {0,0,0}		M.WH[0].alpha = cf.whalf	M.WH[0].minWidth = 500		M.WH[0].minHeight = 500
			for i = 1, G.WHn do local slot = D.CON["d" .. G.WHcon[i]]
				M.WH[i] = M.WH[0]:createImage{path = L.GetIC(D.CON["ic"..G.WHcon[i]]) or "icons\\k\\fatigue.dds"}
				M.WH[i].absolutePosAlignX = 0.5 + math.cos(G.WHang * (i - 1) - math.pi/2) * 0.4
				M.WH[i].absolutePosAlignY = 0.5 + math.sin(G.WHang * (i - 1) - math.pi/2) * 0.4
			end		M.WH[0]:updateLayout()
			L.WHOn(1)	event.register("keyUp", L.KeyUpWHCon)
		else tes3.messageBox(eng and "Your concentration slots need to be updated" or "Ваши слоты концентрации необходимо обновить") end
	end
elseif k == cf.telkey.keyCode then -- Телекинез + Метание оружия - возврат
--	tes3.messageBox("AF = %s   N = %s", table.size(AF), table.size(N))
--	for r, tab in pairs(N) do tes3.applyMagicSource{reference = r, name = "sumsum", effects = {{id = 107, duration = 5}}} end -- 142
--	tes3.applyMagicSource{reference = tes3.player, name = "fireball", effects = {{id = 501, min = 3, max = 6, duration = 4, radius = 15, rangeType = 2}}}

--	tes3.messageBox("state = %s %s %s %s   press = %s %s %s %s", MB[1], MB[2], MB[3], MB[4], ic:isMouseButtonDown(0), ic:isMouseButtonDown(1), ic:isMouseButtonDown(2), ic:isMouseButtonDown(3))
--	tes3.messageBox("Low = %s   pp = %s", G.LowestZ, pp.z)

--	for i, m in pairs(prm.allMobileActors) do tes3.messageBox("%s - %s", i, m.reference)	mwse.log("%s - %s", i, m.reference) end

	L.GetMetRetSpd()
	for r, t in pairs(V.METR) do if not t.f then	t.f = 1		t.si.state = 6 end end
	if not G.TETmod then	local ref = tes3.getPlayerTarget()	if ref and ref.object.value then TELnew(ref) end
	elseif G.TETmod == 1 then
		if MB[3] == 128 then p:activate(G.TETR)
		elseif PMP.current > G.TETcost then		local mc = G.TETcost * L.MCOST(0)	Mod(mc)		local wt	
			local wd = G.TETR.attachments.variables		local ob = G.TETR.object
			if ob.objectType == tes3.objectType.weapon then		wt = ob.type
				if wt < 9 then G.TETdmg = math.max(ob.slashMax, ob.chopMax, ob.thrustMax) * math.max(math.min(wd.condition/ob.maxCondition, 1.2), P.arm2 and 0.5 or 0.25)
				elseif wt == 11 then G.TETdmg = ob.chopMax/2 else G.TETdmg = 1	wt = -1 end
			elseif ob.chopMax then G.TETdmg = ob.chopMax/2	wt = 11	else G.TETdmg = 1	wt = -1 end
			G.TETdmg = math.max(G.TETdmg, ob.weight/3)
			tes3.playSound{reference = p, soundPath = L.RSound(WT[wt].sws), volume = 1, pitch = math.random(90,110)/100}
			tes3.applyMagicSource{reference = p, name = "4nm_tet", effects = {{id = 610, rangeType = 2}}}
			if cf.m then tes3.messageBox("Telekinetic throw! Dmg = %.1f  Cost = %.1f (%.1f base)", G.TETdmg, mc, G.TETcost) end
		end
	elseif G.TETmod == 2 then G.TETmod = 3	G.TETsi.state = 6	G.TETsi = nil
	elseif G.TETmod == 3 and P.mys16 and PMP.current > 2*G.TETcost then
		local mc = G.TETcost * L.MCOST(4) * math.min(1 + pp:distance(G.TETR.position)/5000, 2)		Mod(mc)		G.TETmod = 1
		tes3.playSound{reference = p, soundPath = L.RSound(WT[11].sws), volume = 1, pitch = math.random(90,110)/100}	
		if cf.m then tes3.messageBox("Extra teleport!  Manacost = %.1f (%.1f base)", mc, G.TETcost) end
	end
elseif k == ic.inputMaps[6].code then 	-- Оружие / каст
	if cf.swapkey and not tes3.getPlayerTarget() then
		tes3.tapKey(mp.weaponReady and tes3.scanCode.m or ic.inputMaps[tes3.keybind.readyWeapon + 1].code)			--mp.weaponReady = true		castReady
	end

elseif k == cf.cwkey.keyCode then -- Заряженное оружие
	if e.isControlDown then D.CWm = not D.CWm	tes3.messageBox("Charged weapon: %s", D.CWm and "ranged" or "touch")
	elseif e.isShiftDown then D.CWdis = not D.CWdis	tes3.messageBox("Charged weapon: %s", D.CWdis and "disabled" or "enabled")
	elseif e.isAltDown then D.NoEnStrike = not D.NoEnStrike		W.bar.fillColor = D.NoEnStrike and {1,0,0} or {0,1,1}	tes3.messageBox("Weapon enchant trigger when attacking: %s", D.NoEnStrike and "disabled" or "enabled")
	elseif D.CW and G.TETR and P.mys17 then L.CWF(p, 2, 1, G.TETR.position:copy()) end
elseif k == cf.cpkey.keyCode then -- Контроль снарядов
	if MB[cf.mbrosp] == 128 then CPRS = {}	for r, t in pairs(CPR) do if L.RospMod[t.mod] and t.tim then 	 
		if t.mod == 4 then t.m.velocity = t.v * t.m.initialSpeed elseif t.mod == 6 then t.m.expire = 1 end		CPR[r] = nil end end -- Роспуск снарядов
	elseif MB[cf.mbdet] == 128 then for r, t in pairs(CPR) do if L.DetMod[t.mod] then t.m:explode() end end		-- Подрыв снарядов
		for r, t in pairs(CPRS) do r.mobile:explode() end

	elseif not M.WH then	G.WHn = 6
		G.WHang = G.pi2 / G.WHn
		M.WH = {}	M.WH[0] = tes3ui.createHelpLayerMenu{id = "WH_Menu", fixedFrame = true}		M.WH[0]:destroyChildren()
		M.WH[0].absolutePosAlignX = 0.5		M.WH[0].absolutePosAlignY = 0.5		M.WH[0].color = {0,0,0}		M.WH[0].alpha = cf.whalf	M.WH[0].minWidth = 500		M.WH[0].minHeight = 500
		for i = 1, G.WHn do
			M.WH[i] = M.WH[0]:createImage{path = "icons\\p\\" .. (L.PrCON[i].perk or "alt8") .. ".tga"}
			M.WH[i].absolutePosAlignX = 0.5 + math.cos(G.WHang * (i - 1) - math.pi/2) * 0.4
			M.WH[i].absolutePosAlignY = 0.5 + math.sin(G.WHang * (i - 1) - math.pi/2) * 0.4
		end		M.WH[0]:updateLayout()
		L.WHOn(1)	event.register("keyUp", L.KeyUpWHProj)
	end
elseif k == cf.reflkey.keyCode then	-- Отражение	Auras
	if e.isAltDown then		local MSET = {{14, 16, 15, 23, 27, 22, 24, 25}, {18, 19, 20, 17, 37, 38}, {28, 29, 30, 31, 35, 36}, {45, 46, 47, 48}, {86, 87, 88, 85}}
		local M = {}	M.M = tes3ui.createMenu{id = "Reflect_Menu", fixedFrame = true}		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true	M.B.flowDirection = "top_to_bottom"
		M.lab = M.B:createLabel{text = eng and "Choose the effects that will be reflected by your mana shield" or "Выберите эффекты, которые будут отражаться вашим манащитом"}
		for i = 1, 5 do M[i] = M.B:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 5	end
		for i, l in ipairs(MSET) do for _, id in ipairs(l) do
			M[id] = M[i]:createImage{path = "icons\\" .. tes3.getMagicEffect(id).bigIcon}		M[id].borderAllSides = 3		if D.MSEF["e"..id] then M[id].color = {0.2,0.2,0.2} end
			M[id]:register("mouseClick", function() if D.MSEF["e"..id] then D.MSEF["e"..id] = nil	M[id].color = {1,1,1} else D.MSEF["e"..id] = true	M[id].color = {0.2,0.2,0.2} end		M[id]:updateLayout() end)
		end end
		M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode() end)		tes3ui.enterMenuMode("Reflect_Menu")
	elseif e.isControlDown then D.Aurdis = not D.Aurdis		tes3.messageBox("Damage aura mode: %s", D.Aurdis and "disabled" or "enabled")
	elseif e.isShiftDown then D.Empdis = not D.Empdis		tes3.messageBox("Empower spell mode: %s", D.Empdis and "disabled" or "enabled")
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
		local M = {}	M.M = tes3ui.createMenu{id = "BoundW_Menu", fixedFrame = true}	M.M.minHeight = 800		M.M.minWidth = 800		M.M.flowDirection = "top_to_bottom" 		local el
		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
		for i = 1, 4 do M[i] = M.B:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 5		M[i].flowDirection = "top_to_bottom" end
		for i, l in ipairs(L.BW) do for _, id in ipairs(l) do
			el = M[i]:createLabel{text = id}	el.borderBottom = 2		el:register("mouseClick", function() D.boundw = "4_bound " .. id	M.M:destroy()	tes3ui.leaveMenuMode() end)
		end end
		M.WgtB = M.B:createButton{text = eng and "Weighting" or "Утяжеление"}
		M.WgtB:register("mouseClick", function()
			if P.con19 then D.BWwgt = not D.BWwgt		tes3.messageBox("Weight increase: %s", D.BWwgt and "enabled" or "disabled")
			else tes3.messageBox(eng and "You do not know how to control the weight of the summoned weapon" or "Вы не умеете контролировать вес призванного оружия") end
		end)
		tes3ui.enterMenuMode("BoundW_Menu")
	elseif P.con17 or tes3.isAffectedBy{reference = p, effect = 601} or tes3.isAffectedBy{reference = p, effect = 603} then	
		if mp.readiedWeapon then BAM.am = BAM[mp.readiedWeapon.object.type] or BAM.met else BAM.am = BAM.met end
		if mwscript.getItemCount{reference = p, item = BAM.am} == 0 then 	if BAM.f() then tes3.addItem{reference = p, item = BAM.am, count = 100, playSound = false}	mp:equip{item = BAM.am} end
		else mp:equip{item = BAM.am} end
	end
elseif k == cf.killkey.keyCode then	-- Приказ в атаку!
	local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {p}}
	local ref = hit and hit.reference		local Tar =	ref and ref.mobile			if Tar and Tar.isDead then Tar = nil end
	for m in tes3.iterate(mp.friendlyActors) do if m ~= mp and tes3.getCurrentAIPackageId(m) == 3 and m.reference.data.SumM == p.id then
		m.actionData.aiBehaviorState = 3
		if Tar then m:startCombat(Tar)
		else	for r, t in pairs(R) do m:startCombat(t.m) end end
	end end
elseif k == cf.parkey.keyCode then	-- Парирование
	if G.TR.tr5 then tes3.messageBox("%s", eng and "The Code of honor does not allow you to go into brutal mode" or "Кодекс чести не позволяет вам перейти в жестокий режим")
	else D.nopar = not D.nopar	M.NoPar.visible = D.nopar		tes3.messageBox("Parry mode: %s", D.nopar and "disabled" or "enabled") end
elseif k == cf.poisonkey.keyCode then D.poimod = not D.poimod		M.drop.visible = D.poimod		tes3.messageBox("Poison mode %s", M.drop.visible and "enabled" or "disabled")	-- Режим яда
elseif k == cf.dwmkey.keyCode then if e.isAltDown then W.WL = nil W.DL = nil else L.DWMOD(not W.DWM) end	-- Двойное оружие
elseif k == cf.pkey.keyCode and L.READY then	local M = {}	M.M = tes3ui.createMenu{id = "Perk_Menu", fixedFrame = true}	M.M.minHeight = 1300	M.M.minWidth = 36 * 32*cf.pscal + 116		-- Перки
--M.M.minWidth, M.M.minHeight = tes3.getViewportSize()
--M.M.autoHeight = true	M.M.autoWidth = true
	M.S = 0			local LVL = p.object.level				L.TrLimCalc()
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do if P[t[1]] then M.S = M.S + t.f end end end
	for stat, num in pairs(D.STB) do M.S = M.S + num * 3 end
	
	M.P = M.M:createVerticalScrollPane{}	M.A = M.P:createBlock{}		M.A.autoHeight = true	M.A.autoWidth = true		M.B = M.M:createBlock{}		M.B.autoHeight = true	M.B.autoWidth = true
	M.F = M.B:createFillBar{current = M.S, max = LVL * cf.pmult}	M.F.width = 300		M.F.height = 24		M.F.widget.fillColor = {1,0,1}
	M.close = M.B:createButton{text = tes3.findGMST(tes3.gmst.sClose).value}	M.close:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkSpells()	L.HPUpdate()	L.SetGlobal() end)
	M.class = M.B:createButton{text = eng and "Legendary" or "Легендарность"}
	M.class:register("mouseClick", function() if mp.inCombat then tes3.messageBox("%s", eng and "In combat" or "Вы в бою") else M.M:destroy()	tes3ui.leaveMenuMode()	L.LegSelect() end end)
	M.conc = M.B:createButton{text = eng and "Concentration" or "Концентрация"}
	M.conc:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.ConcSelect() end)
	M.resp = M.B:createButton{text = eng and "Reset perks" or "Сброс перков"}
	M.resp:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Click with ALT to reset traits" or "Нажмите вместе с ALT чтобы сбросить трейты"} end)
	M.resp:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	 L.PerkReset() end)
	
	M.take = M.B:createButton{text = eng and "Take free perks" or "Взять бесплатные перки"}		M.take:register("mouseClick", function()
		for i, l in ipairs(L.PR) do for _, t in ipairs(l) do if t.f < 0.1 and mp[L.PRL[i][1]].base >= t[2] then P[t[1]] = true end end end
		M.M:destroy()	tes3ui.leaveMenuMode()	L.PerkSpells()	L.HPUpdate()	L.SetGlobal()
	end)
	if P.int16 and not mp.inCombat then M.spcrea = M.B:createButton{text = eng and "Spell making" or "Создание заклинаний"}		M.spcrea:register("mouseClick", function()
		M.M:destroy()	tes3ui.leaveMenuMode()		tes3.findGMST("fSpellMakingValueMult").value = 0		tes3.showSpellmakingMenu{serviceActor = mp, useDialogActor = false}
		timer.delayOneFrame(function() tes3.findGMST("fSpellMakingValueMult").value = P.merc7 and 10 or 20 end)
	end) end
	M.train = M.B:createButton{text = eng and "Training" or "Тренировка"}
	M.train:register("mouseClick", function() M.M:destroy()	tes3ui.leaveMenuMode()	L.TrainMenu() end)
	
	for i = 0, 35 do M[i] = M.A:createBlock{}	M[i].autoHeight = true		M[i].autoWidth = true	M[i].borderAllSides = 1		M[i].flowDirection = "top_to_bottom" end
	
	for i, t in ipairs(L.PR[0]) do t.m = M[0]:createImage{path = "icons/p/"..t[1]..".tga"}		t.m.borderBottom = 2		if not G.TR[t[1]] then t.m.color = {0.2,0.2,0.2} end	t.m.imageScaleX = cf.pscal	t.m.imageScaleY = cf.pscal
		t.m:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}		tt.autoHeight = true	tt.autoWidth = true		tt.maxWidth = 600
		tt:createLabel{text = ("%s   (%s lvl)   %s"):format(t[eng and 4 or 3], t[2], t[eng and 6 or 5])} end)
		if not G.TR[t[1]] and LVL >= t[2] then t.m:register("mouseClick", function() if not G.TR[t[1]] then G.TR[t[1]] = true	tes3.playSound{sound = "skillraise"}	t.m.color = {1,1,1}		t.m:updateLayout() end end) end
	end
	
	local STmax = math.clamp(math.floor((LVL - 50)/5),0,10)		L.GetBaseStats()
	for i = 1, 8 do local t = L.PRL[i]	local el = M[0]:createImage{path = t[2]}		el.borderBottom = 2		if STmax == 0 then el.color = {0.2,0.2,0.2} end		el.imageScaleX = cf.pscal	el.imageScaleY = cf.pscal
		el:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}		tt.autoHeight = true	tt.autoWidth = true		tt.maxWidth = 600
			tt:createLabel{text = ("%s %s/%s (%s)"):format(eng and "Increase stat maximum by 10 for 3 perkpoints. Gained buffs:" or
			"Увеличить максимум характеристики на 10 за 3 перкпоинта. Сделано усилений:", D.STB[t[1]], STmax, t[1] )}
		end)
		if M.F.widget.max >= M.S + 3 and STmax > 0 and	G.BaseStats[t[1]] >= 100 then el:register("mouseClick", function() 
			if M.F.widget.max >= M.S + 3 and STmax > D.STB[t[1]] then tes3.modStatistic{reference = p, name = t[1], value = 10}		D.STB[t[1]] = D.STB[t[1]] + 1
			M.S = M.S + 3	M.F.widget.current = M.S	M.F:updateLayout()	tes3.playSound{sound = "skillraise"} end 
		end) end
	end
	--local pat		tes3.getFileExists(pat) and pat or L.PRL[i][2]
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do t.m = M[i]:createImage{path = "icons/p/"..t[1]..".tga"}	t.m.imageScaleX = cf.pscal	t.m.imageScaleY = cf.pscal
		t.m.borderBottom = 2	if not P[t[1]] then t.m.color = {0.2,0.2,0.2} end
		t.m:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}		tt.autoHeight = true	tt.autoWidth = true		tt.maxWidth = 600
		tt:createLabel{text = ("%s (%s %s)  Perkpoints: %s - %s = %s  -  %s"):format(t[eng and 4 or 3], L.PRL[i][1], t[2], t.x, t.c or 0, t.f, t[eng and 6 or 5])} end)
		if M.F.widget.max >= M.S + t.f and not P[t[1]] and mp[L.PRL[i][1]].base >= t[2] then t.m:register("mouseClick", function() if not P[t[1]] and M.F.widget.max >= M.S + t.f then P[t[1]] = true
		M.S = M.S + t.f		M.F.widget.current = M.S	M.F:updateLayout()	tes3.playSound{sound = "skillraise"}	t.m.color = {1,1,1}		t.m:updateLayout()	end end) end
	end end		tes3ui.enterMenuMode("Perk_Menu")
	if e.isAltDown then	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do P[t[1]] = true end end		for _, num in ipairs(L.SFS) do tes3.addSpell{reference = p, spell = "4s_"..num, updateGUI = false} end
	tes3.updateMagicGUI{reference = p, updateEnchantments = false}		D.PerkRes = nil		tes3.messageBox("TESTER MOD ACTIVATED!")	tes3.playSound{sound = "Thunder0"} end
elseif k == cf.statkey.keyCode then		-- Просмотр статов
	L.ShowStatMenu()
end end end		event.register("keyDown", KEYDOWN)


--[[
local function calcWalkSpeed(e) local m = e.mobile		if m == mp then local strafe = mp.isMovingLeft or mp.isMovingRight	local forw = mp.isMovingForward		local back = mp.isMovingBack		local FinSpd
	local Ast = ad.animationAttackState		local Enc = mp.encumbrance		G.ENC = Enc.normalized		G.LIG = math.max(-Enc.currentRaw,0)/2000		G.STN = math.min(PST.normalized,1)
	
else
	local spd = e.speed		
--	local Spd0 = (e.reference.tempData.Bspd and 5 + m.speed.current * 2.95 or 100 + m.speed.current) * (1 - m.encumbrance.normalized/2)
	local Spd0 = (e.reference.tempData.Bspd and 5 + m.speed.current * 2.95 or 100 + m.speed.current) * (1 - m.encumbrance.normalized/2) 
	local Spd1 = Spd0 * (3 + m:getSkillValue(8)/100)		local ts = tes3.getSimulationTimestamp()		
--	if e.reference.tempData.LTS ~= ts then e.speed = 0 end
	e.reference.tempData.LTS = ts
	
	tes3.messageBox("speed = %d/%d/%d -> %d   Bspd %s  Spd %.1f  Atl %.1f  enc = %.2f  Run = %s  TS %s, spd, Spd0, Spd1, e.speed, e.reference.tempData.Bspd, m.speed.current, m:getSkillValue(8), m.encumbrance.normalized, m.isRunning, ts)
	mwse.log("speed = %d/%d/%d -> %d   Bspd %s  Spd %.1f  Atl %.1f  enc = %.2f  Run = %s  TS %s , spd, Spd0, Spd1, e.speed, e.reference.tempData.Bspd, m.speed.current, m:getSkillValue(8), m.encumbrance.normalized, m.isRunning, ts)
	
end end		--event.register("calcWalkSpeed", calcWalkSpeed)

local function CALCFLYSPEED(e) local m = e.mobile		if m ~= mp and not m.object.flies then
	e.speed = (4 + m.levitate) * (40 + m.speed.current/10) 		--tes3.messageBox("fly = %s  lev = %.1f  speed = %d", e.reference, e.mobile.levitate, e.speed)
end end		--event.register("calcFlySpeed", CALCFLYSPEED)
--]]
-- Эвенты кроме калькмувспид не триггерятся при перегрузе!
-- Если гуманоид летает, то его isRunning всегда фолс. Если негуманоид летает сам (m.object.flies) ИЛИ под левитацией, то его isRunning всегда тру.
-- Если isRunning = тру, то событие срабатывает 3 раза за фрейм для небипедальных существ!
L.ASatak = {[2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true}
local function CALCMOVESPEED(e) local m = e.mobile		if m == mp then local strafe = mp.isMovingLeft or mp.isMovingRight	local forw = mp.isMovingForward		local back = mp.isMovingBack		local FinSpd
	local Ast = ad.animationAttackState		local Enc = mp.encumbrance		G.ENC = Enc.normalized		G.LIG = math.max(-Enc.currentRaw,0)/2000		G.STN = math.min(PST.normalized,1)
	if forw or strafe or back then		local Run = mp.isRunning
		if mp.isFlying then FinSpd = mp.levitate * (30 + mp:getSkillValue(11)*(P.alt15 and 0.15 or 0.05) + math.min(mp.speed.current,300)/(P.spd9 and 20 or 40))
		else FinSpd = ( (Run and 100 + mp:getSkillValue(8)*(P.atl1 and 0.5 or 0.35) or 150) + math.min(mp.speed.current,500) * (P.spd9 and 0.5 or 0.35) ) * (mp.isSwimming and (P.atl5 and 0.5 or 0.35) * (1 + mp.swiftSwim/100) or 1) end
		
		FinSpd = FinSpd
		* math.max(1 - G.ENC * (P.atl3 and 0.2 or 0.4), 0.2)
		* math.min(D.AR.ms + G.LIG, 1)
		* (strafe and (forw or back) and 0.8 or 1)
		* (back and 0.625 or 1)
		* (not P.acr3 and mp.isFalling and 0.75 or 1)
		
		if Run then
			G.SPRlast = G.SPRcur	G.SPRcur = forw and not strafe
			if G.SPRcur then	if not G.SPRlast then T.SPR:reset() end
			elseif G.SPRlast then T.SPR:cancel() end
		
			FinSpd = FinSpd
			* math.min(math.lerp(P.end18 and 0.75 or 0.5, 1, G.STN * (P.atl2 and 2 or 1.25)), 1)
			* ( (G.TR.tr3 and 4 or 3.5) + (G.SPRcur and (P.spd0 and 1 or 0.5) * (G.SPRT - (T.SPR.timeLeft or 0))/G.SPRT or 0) )
			* ((forw or P.spd20) and 1 or 0.8)
			* ((P.spd11 or M.MCB.current == 0) and 1 or 0.8)
			* ((Ast == 2 and (P.spd10 and 0.8 or 0.66667)) or (Ast == 10 and (P.spd19 and 0.8 or 0.66667)) or 1)
		else	-- Здесь эвент не срабатывает если не двигаться!
			G.SPRcur = nil
			if mp.isSneaking then
				FinSpd = FinSpd * (P.snek2 and math.min(0.75 + mp.sneak.current/400, 1) or 0.75)
			end
		end
	else FinSpd = 0		G.SPRcur = nil end

--[[	local Spd0 = (100 + m.speed.current) * (1 - m.encumbrance.normalized/2) 	local Spd1 = Spd0 * (3 + m:getSkillValue(8)/100)		local ts = tes3.getSimulationTimestamp()		
--	if e.reference.tempData.LTS ~= ts then e.speed = 0 end
	e.reference.tempData.LTS = ts
	tes3.messageBox("speed = %d/%d -> %d   Spd %.1f  Atl %.1f  enc = %.2f  Run = %s  TS %s  Vel %.5f", Spd0, Spd1, e.speed, m.speed.current, m:getSkillValue(8), m.encumbrance.normalized, m.isRunning, ts, G.dfr or 0)
	mwse.log("speed = %d/%d -> %d   Spd %.1f  Atl %.1f  enc = %.2f  Run = %s  TS %s  Vel %.5f", Spd0, Spd1, e.speed, m.speed.current, m:getSkillValue(8), m.encumbrance.normalized, m.isRunning, ts, G.dfr or 0)
--]]
--	tes3.messageBox("spd = %d -> %d    Swim = %s  Run = %s  Walk = %s  Fly = %s  SPR = %.2f C = %s L = %s", e.speed, FinSpd, m.isSwimming, m.isRunning, m.isWalking, m.isFlying, T.SPR.timeLeft or 0, G.SPRcur, G.SPRlast)
	
	e.speed = FinSpd		G.Pspd = FinSpd * (strafe and (forw or back) and 1.25 or 1) * ((forw and 1) or (back and 0.8) or 0.75)		if cf.spdm then M.MSPD.text = ("%d"):format(G.Pspd) end
	
	if G.dfr then	if V.djf then mp.isJumping = true end
	--	mp.velocity = V.d
		mp.impulseVelocity = V.d		
		G.dfr = G.dfr - wc.deltaTime		--tes3.messageBox("deltaTime = %s", wc.deltaTime)
		if G.dfr <= 0 then	G.dfr = nil
			if V.djf then V.djf = nil	mp.isJumping = false end
			if G.dashaspd then mp.animationController.weaponSpeed = G.atspd		G.dashaspd = nil end
			if V.dkik then V.dkik = nil		L.KIK() end
			G.DashD = 0
		end
	end
	
	local Pvec = pp - G.LPP
	local delt = Pvec:length()
	if delt > 0 then
		if G.PspdNfr < 2 then
			G.Pvec = Pvec:normalized()
			G.PspdR = delt / wc.deltaTime
			G.LPP = pp:copy()
		--	tes3.messageBox("real %d   espd %d    vel = %d   delt = %d   Nulfr = %s", G.Pspd, e.speed, mp.velocity:length(), G.PspdR, G.PspdNfr)
		end
		G.PspdNfr = 0
	else
		if G.PspdNfr > 0 then
			G.Pvec = V.nul
			G.PspdR = 0
		--	tes3.messageBox("NULL %d   espd %d    vel = %d   delt = %d   Nulfr = %s", G.Pspd, e.speed, mp.velocity:length(), G.PspdR, G.PspdNfr)
		end
		G.PspdNfr = G.PspdNfr + 1
	end
else
--	local spd = e.speed		
	local r = e.reference		local Bspd = r.tempData.Bspd		local Run = m.isRunning
	if m.isFalling then e.speed = 0
	elseif m.isFlying then
		if m.object.flies then e.speed = ((Bspd or m.speed.base) + m.speed.current) * 1.5 * math.max(1 - m.encumbrance.normalized/2, 0.2)
		else e.speed = (4 + m.levitate) * (40 + m.speed.current/10) * math.max(1 - m.encumbrance.normalized/2, 0.2) end
	else
		e.speed = (Bspd and (Bspd + m.speed.current)*1.5 or 100 + m.speed.current) * (m.isSwimming and 0.5 * (1 + m.swiftSwim/100) or 1)
		* (Run and (Bspd and 4 or 3 + m:getSkillValue(8)/100) * (0.5 + math.min(m.fatigue.normalized,1)/2) or 1)
		* math.max(1 - m.encumbrance.normalized/2, 0.2)
	end
	
	--[[
	if spd == 0 then	local enc = m.encumbrance.normalized
		if enc >= 1 then
			if m.isFalling then e.speed = 0
			else
				e.speed = ((m.isFlying and not m.object.flies and (4 + m.levitate) * (40 + m.speed.current/10))
				or (Bspd and (Bspd + m.speed.current)*1.5 or 100 + m.speed.current) * (m.isSwimming and 0.5 * (1 + m.swiftSwim/100) or 1) )
				* (m.isRunning and (3 + m:getSkillValue(8)/100) or 1)
				* math.max(1 - enc/2, 0.2)
				* (0.5 + math.min(m.fatigue.normalized,1)/2)
			end
		end
	else e.speed = m.isFalling and 0 or spd * (0.5 + math.min(m.fatigue.normalized,1)/2) end
	--]]
	
--	local Bspd = e.reference.tempData.Bspd
--	local Spd0 = (m.actorType == 0 and m.speed.current * 3 or 100 + m.speed.current) --* (1 - m.encumbrance.normalized/2) 
--	local Spd1 = Spd0 * (3 + m:getSkillValue(8)/100)
--	local curg = m.animationController.animationData.currentAnimGroups[1]
--	local X0 = m.animationController.animationData.approxRootTravelDistances[59+1]
--	local X = m.animationController.animationData.approxRootTravelDistances[curg+1]		--222 для скелета нпс
--	local ts = tes3.getSimulationTimestamp()		
--	if e.reference.tempData.LTS ~= ts then e.speed = 0 end
--	if m.actorType == 0 and e.speed > Spd0*2 then e.speed = 0 end
--	e.reference.tempData.LTS = ts
--	e.speed = 300 --* (e.reference.tempData.Bspd and X0/222 or 1)
	
--	tes3.messageBox("speed = %d/%s/%s  %d/%d -> %d   Bspd %s  Spd %.1f  Atl %.1f  enc = %.2f  Run = %s  TS %s  Vel %s", spd, X, X0, Spd0, Spd1, e.speed, e.reference.tempData.Bspd, m.speed.current, m:getSkillValue(8), m.encumbrance.normalized, m.isRunning, ts, DOM[m] and true)
--	mwse.log("speed = %d/%s/%s  %d/%d -> %d   Bspd %s  Spd %.1f  Atl %.1f  enc = %.2f  Run = %s  TS %s  Vel %s", spd, X, X0, Spd0, Spd1, e.speed, e.reference.tempData.Bspd, m.speed.current, m:getSkillValue(8), m.encumbrance.normalized, m.isRunning, ts, DOM[m] and true)
	
	local t = DOM[m]		local spd1
	---[[
	if Bspd and not Run then	local ad = m.actionData
		if L.ASatak[ad.animationAttackState] and ad.target == mp and ad.physicalAttackType ~= 4 then	local distbb = m:getEffectiveAttackDistance(mp) - 64	--local pos = r.position
			if distbb > 0 then			--	m.animationController.animGroupMovement = 255
				spd1 = math.min(e.speed * 3, distbb / wc.deltaTime)
				m.impulseVelocity = (pp - r.position):normalized() * spd1
			end
		--	tes3.messageBox("%s  spd = %d / %d   dist = %d   AS = %s  Run = %s  Ts = %s",
		--	r, e.speed, spd1 or 0, m:getEffectiveAttackDistance(mp), m.actionData.animationAttackState, m.isRunning, tes3.getSimulationTimestamp()*10000000)
		end
	end
	--]]
	
	if t then	--tes3.messageBox("%s", t.fr)		--	m.impulseVelocity = t.v * (TSK/wc.deltaTime)		t.fr = t.fr - TSK
		m.impulseVelocity = spd1 and m.impulseVelocity + t.v or t.v		--spd1 and m.impulseVelocity + t.v 
		t.fr = t.fr - wc.deltaTime
	--	if t.nospd then e.speed = 0 end
		if t.fr < 0 then DOM[m] = nil end
	end
	--if e.reference.data.jpos1 and not m.isFalling then tes3.messageBox("%s   dist = %d", e.reference, e.reference.data.jpos1:distance(m.position))		e.reference.data.jpos1 = nil end
end end		event.register("calcMoveSpeed", CALCMOVESPEED)


local function JUMP(e)	if e.isDefaultJump then local vec = e.velocity:normalized()		local m = e.mobile	if m == mp then
local Kstat = 300 + m:getSkillValue(20) * (P.acr1 and 1.5 or 1) + math.min(m.agility.current,500) * (G.TR.tr26 and 1.5 or 1) + m.jump * (P.alt24 and 10 or 8)
local Kstam = math.min(math.lerp(P.atl13 and 0.75 or 0.5, 1, G.STN*(P.acr14 and 2 or 1.25)), 1)
local Kenc = math.max(1 - G.ENC * (P.atl6 and 0.2 or 0.4), 0.2) * math.min(D.AR.ms + G.LIG, 1)
local Mult = Kstat * Kstam * Kenc

if mp.isHitStunned then local ang
	if mp.isMovingForward then if mp.isMovingLeft then ang = -45 elseif mp.isMovingRight then ang = 45 else ang = 0 end
	elseif mp.isMovingBack then if mp.isMovingLeft then ang = -135 elseif mp.isMovingRight then ang = 135 else ang = 180 end
	elseif mp.isMovingLeft then ang = -90 elseif mp.isMovingRight then ang = 90 end
	if ang then vec = tes3.getPlayerEyeVector()		Matr:toRotationZ(math.rad(ang))		vec = Matr * vec		vec.z = 0	vec = vec:normalized()		vec.z = 1	vec = vec:normalized() end
	e.velocity = vec * Mult * 0.5
else e.velocity = vec * Mult end

if Mult > 300 then L.skacr = Mult/2000 else L.skacr = 0 end

local StCost = (P.acr2 and 25 or 30) * (G.ENC*(P.atl6 and 0.25 or 0.5) + (D.AR.dc < 1 and D.AR.dc or math.max(D.AR.dc - G.LIG,1)))
PST.current = math.max(PST.current - StCost, 0)

--local vec = tes3.getPlayerEyeVector():normalized()	vec.z = 0.2			e.velocity = vec * 1000
--tes3.messageBox("Jump! %d = %d stat * %d%% stam * %d%% enc  x = %d   stun = %s   Cost = %d", e.velocity.z, Kstat, Kstam*100, Kenc*100, e.velocity.x, mp.isHitStunned, StCost)
else e.velocity = vec * (300 + m:getSkillValue(20) * 2 + m.agility.current + m.jump*20)
	--tes3.messageBox("Jump npc! z = %d   x = %d", e.velocity.z, e.velocity.x)
end end end		event.register("jump", JUMP)


local function CALCARMORRATING(e) local m = e.mobile	if m then	local a = e.armor	local bound = a.weight == 0		local tab = L.AT[bound and 0 or a.weightClass]
	e.armorRating = a.armorRating * 
	(bound and m == mp and P.con18 and 0.5 or (1 + m:getSkillValue(tab.s) * (((m ~= mp or P[tab.p]) and 0.0075 or 0.005) + ((m ~= mp or P.end23) and 0.0025 or 0))   ))
	* (bound and 0.5 + m:getSkillValue(13)/((m ~= mp or P.con9) and 200 or 400) or 1)
	e.block = true
end end		event.register("calcArmorRating", CALCARMORRATING)



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
		if MB[cf.mbarc] == 128 and PST.current > 10 then PST.current = PST.current - dt * (P.atl4 and 10 or 20)		dt = -dt end	G.artim = math.clamp((G.artim or 0) + dt,0,4)
		if G.artim > 0 then	local MS = ic.mouseState
			local x = mp.readiedWeapon		x = x and x.object.weight or 0
			local x = (5 + x/4) * (1 - (math.min(mp.strength.current + mp.agility.current + mp:getSkillValue(23),300)/(P.mark12 and 400 or 600))) * G.artim/4
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
L.WCO = {[1] =	{[1] = {[2]=1}, 				[2] = {[2]=1},					[3] = {[0]=2, [2]=1, [3]=2}},	-- Одноруч ИЛИ дуалы если сейчас бьющее оружие в правой
[3] =			{[1] = {[0]=1, [2]=1}, 			[2] = {[2]=1},					[3] = {[0]=2, [2]=1, [3]=2}},	-- Дуалы если сейчас бьющее оружие в левой
[2] =			{[1] = {[0]=2, [2]=1, [3]=2},	[2] = {},						[3] = {[0]=2, [2]=1, [3]=2}},	-- Двуруч
[0] =			{[1] = {[2]=1},					[2] = {[0]=3, [1]=3, [2]=1},	[3] = {[2]=1},	[4] = {}}		-- Кулаки
}
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
	if G.cot == 1 then
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
L.WComb = function()
	local dir = ad.physicalAttackType
	local mov = ((mp.isMovingForward or mp.isMovingBack) and 1 or 0) + ((mp.isMovingLeft or mp.isMovingRight) and 2 or 0)		local newd = L.COMOV[mov]		local sw = ad.attackSwing
	local new = L.WCO[G.cot][dir][mov]	local swap			local swmult = G.swmult
	if W.DWM then
		if G.cot == 1 then	if mov == 2 then swap = 1 end
		else	if mov == 2 then swap = 1 else swap = 2 end end
		if swap and P.agi22 then swmult = swmult + 0.5 end
	else
		if P.agi29 and G.cot == 1 and not mp.readiedShield then swmult = swmult + 0.5 end
	end
	
	if new then
		G.swingmult = (1 + sw * swmult) * (mp.isHitStunned and 0.5 or 1)
		if G.cot == 0 or not cf.fastanim then MB[1] = 0 end
		ad.animationAttackState = 0		G.NewAtDir = new
		
		if swap then L.DWSwap() end
	--	tes3.messageBox("Ideal  SW %.3f  Mult %.3f   swap = %s   Dir = %s  New = %s", sw, G.swingmult, swap, dir, new)
	elseif newd ~= dir then
		G.swingmult = (1 + sw * swmult) * (mp.isHitStunned and 0.5 or 1)
		MB[1] = 0		ad.animationAttackState = 0	
	--	tes3.messageBox("Half   SW %.3f  Mult %.3f   swap = %s   Dir = %s  NewD = %s", sw, G.swingmult, swap, dir, newd)
	end

	
	--[[		-- Старая система
	if new then
		if fat.normalized > cf.cofat and fat.current > cost then
			G.swingmult = 2
			ad.animationAttackState = 0		G.NewAtDir = new	--ad.physicalAttackType = new		
			fat.current = fat.current - cost	tes3.messageBox("Ideal  %d   swap = %s", cost, swap)
		--	MB[1] = 0	ad.animationAttackState = 0		--ad.physicalAttackType = new	
			
			if swap then L.DWSwap() end
		elseif swap == 2 then	G.swingmult = 2
			MB[1] = 0		ad.animationAttackState = 0		fat.current = math.max(fat.current - cost, 0)		--tes3.messageBox("Extra swap   %d", cost)
		end
	elseif newd ~= dir then
		if swap == 2 then		G.swingmult = 2
			MB[1] = 0		ad.animationAttackState = 0		fat.current = math.max(fat.current - cost, 0)		--tes3.messageBox("Extra swap   %d", cost)
		elseif fat.normalized > cf.cofat and fat.current > cost then	G.swingmult = 2
			MB[1] = 0	
			ad.animationAttackState = 0			--G.NewAtDir = newd
			
			fat.current = fat.current - cost		tes3.messageBox("Half   %d   swap = %s", cost, swap)
		end
	end
	--]]

end
L.WSim = function(e) if mp.weaponDrawn and MB[1] == 128 then	--tes3.messageBox("AS = %s   Dir = %s", ad.animationAttackState, ad.physicalAttackType)
	if L.AS[ad.animationAttackState] == 1 then		-- баг возникает во время АС = 3 и дир = 3 и зажатой лкм
		L.WComb() 	event.unregister("simulate", L.WSim)	W.Wsim = nil
	end
else event.unregister("simulate", L.WSim)	W.Wsim = nil end end

local function MCStart(e) if e.button == 0 then M.MCB.current = 0 	T.MCT:cancel()	G.arm1.appCulled = true		G.arm2.appCulled = true		event.unregister("mouseButtonUp", MCStart)
	if cf.mcs then tes3.removeSound{sound = "destruction bolt", reference = p} end
end end

L.MENUCB = {
["MenuInventorySelect"] = "MenuInventorySelect_button_cancel",
["MenuMagicSelect"] = "MenuMagicSelect_button_cancel",
["MenuQuantity"] = "MenuQuantity_buttoncancel",
["MWSE:ModConfigMenu"] = "MWSE:ModConfigMenu_Close",
["MenuVideo"] = "MenuVideo_Okbutton",
["MenuAudio"] = "MenuAudio_Okbutton",
["MenuPrefs"] = "MenuPrefs_Okbutton",
["MenuSave"] = "MenuSave_Cancelbutton",
["MenuLoad"] = "MenuLoad_Okbutton",
["MenuOptions"] = "MenuOptions_Return_container",
["MenuRestWait"] = "MenuRestWait_cancel_button",
["MenuQuick"] = "MenuQuick_button_cancel",
["MenuScroll"] = "MenuScroll_Close",
["MenuJournal"] = "MenuBook_button_close",
["MenuBook"] = "MenuBook_button_close",
["MenuAlchemy"] = "MenuAlchemy_cancel_button",
["MenuEnchantment"] = "MenuEnchantment_Cancelbutton",
["MenuSpellmaking"] = "MenuSpellmaking_Cancelbutton",
["MenuServiceTravel"] = "MenuServiceTravel_Okbutton",
["MenuServiceTraining"] = "MenuServiceTraining_Okbutton",
["MenuServiceSpells"] = "MenuServiceSpells_Okbutton",
["MenuServiceRepair"] = "MenuServiceRepair_Okbutton",
["MenuRepair"] = "MenuRepair_Okbutton",
["MenuPersuasion"] = "MenuPersuasion_Okbutton",
["CustomMessageBox"] = "CustomMessageBox_CancelButton",
["MenuMessage"] = "MenuMessage_CancelButton",
["MenuBarter"] = "MenuBarter_Cancelbutton",
["MenuDialog"] = "MenuDialog_button_bye",
["MenuContents"] = "MenuContents_closebutton"}

local function MOUSEBUTTONDOWN(e) if tes3ui.menuMode() then
	if e.button + 1 == cf.mbclose then
		local top = tes3ui.getMenuOnTop()	local ClB = top and L.MENUCB[top.name]	ClB = ClB and top:findChild(ClB)
		if ClB and ClB.visible then ClB:triggerEvent("mouseClick") end
	end
else local But = e.button + 1	if But == 1 then
	--tes3.messageBox("AnSpd = %.2f   WSpeed = %.2f", mp.animationController.weaponSpeed, mp.readiedWeapon and mp.readiedWeapon.object.speed or 1)
	if mp.spellReadied and not T.MCT.timeLeft then G.arm1.appCulled = false		G.arm2.appCulled = false		local r, AE, EI, sumcost
		local MCK = math.max((2 + math.min(mp.willpower.current,300)/(P.wil13 and 50 or 100) - G.ENC * (P.end15 and 0.5 or 1)) * (D.AR.cs > 1 and D.AR.cs or math.min(D.AR.cs + G.LIG, 1)), 1)
		
		local stc = P.end11 and 1 or 2
		if cf.mcs then tes3.playSound{sound = "destruction bolt", reference = p, loop = true} end
		if MB[cf.mbsum] == 128 then local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore={p}}		r = hit and hit.reference		local m = r and r.mobile
			if m and r.data.SumM == p.id and not m.isDead then for _, aef in pairs(mp:getActiveMagicEffects{}) do EI = aef.effectInstance	if EI.createdData and EI.createdData.object == r then
				AE = aef	sumcost = tes3.getMagicEffect(aef.effectId).baseMagickaCost * MCK/50	break
			end end end
		end
		T.MCT = timer.start{duration = 0.1, iterations = -1, callback = function() if PST.current > 3 then PST.current = PST.current - stc end
			M.MCB.current = math.min(M.MCB.current + MCK, 100)
			if AE and EI.state == 5 then	local bontime = MCK * (P.con15 and 0.3 or 0.2) * L.Cpow(mp,1,true)	local scost = sumcost * L.MCOST(1)			--36 для завершённых эффектов
				if PMP.current > scost then
					EI.timeActive = EI.timeActive - bontime		Mod(scost)		if cf.m then tes3.messageBox("%s + %.2f = %.2f   Cost = %.2f", r.object.name, bontime, AE.duration - EI.timeActive, scost) end
				end
			end
		end}	event.register("mouseButtonUp", MCStart)
	elseif mp.weaponDrawn then	local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object	local wt = W.wt		local as = ad.animationAttackState	--or (w and w.type or -1)
		if wt < 9 then
			if as > 0 then
				if L.AS[as] == 1 then	L.WComb()
				elseif not W.Wsim then event.register("simulate", L.WSim)	W.Wsim = 1 end
				
				--if as == 3 then tes3.messageBox("AS = 3    fiz = %s", ad.physicalAttackType) end
				
			elseif W.DWM then
				if w then	--local WTR = WT[W[W.WR.id] or W.WR.type]		local WTL = WT[W[W.WL.id] or W.WL.type]
					local mov = ((mp.isMovingForward or mp.isMovingBack) and 1 or 0) + ((mp.isMovingLeft or mp.isMovingRight) and 2 or 0)
					if G.cot == 1 then
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
			local StCost = (G.wgt + 10) * ((P.end6 and 2.5 or 3) - (P.mark3a and 0.5 or 0)) * (1 + G.ENC * (P.atl14 and 0.1 or 0.25))
			PST.current = math.max(PST.current - StCost, 0)		--tes3.messageBox("Multi shot  Stam = %.1f   Wgt = %.1f", StCost, G.wgt)
		elseif ad.animationAttackState == 2 then	local w = mp.readiedWeapon		w = w and w.object		local wt = w and w.type or -1
			if wt == 11 and P.mark9c and not G.met then	local ws = w.speed	G.metmax = ws > 1.4 and 5 or (ws > 1.2 and 4) or (ws > 0.9 and 3) or 2
				if T.Met.timeLeft then G.metsw = math.max(0.75 - T.Met.timeLeft/4, 0.25)	T.Met:reset() else G.metsw = 0.75		T.Met = timer.start{duration = 2, callback = function() end} end
				event.register("simulate", L.MetSim)		G.met = 1	ad.attackSwing = G.metsw	ad.animationAttackState = 4		mp.animationController.weaponSpeed = 1000000	G.arcspd = mp.animationController.weaponSpeed
				local StCost = (G.wgt + 5) * ((P.end6 and 4 or 5) - (P.mark3c and 1 or 0)) * (1 + G.ENC * (P.atl14 and 0.1 or 0.25))
				PST.current = math.max(PST.current - StCost, 0)		--tes3.messageBox("Multi throw  Stam = %.1f   Wgt = %.1f", StCost, G.wgt)
			end
		end
	end
	if But == cf.mbkik then L.KIK() end		--if ad.animationAttackState == 2 then ad.animationAttackState = 4	 mp.animationController.weaponSpeed = 1000000 end
	
	if But == cf.mbsp2 then
		if G.SP2 and not M.WH then	local cost = G.SP2.magickaCost	local sc = G.SP2:getLeastProficientSchool(mp)
			mp.animationController.animationData.castSpeed = 2/(1 + cost*3/(cost+100))
			* math.max( (1 + math.min(mp.speed.current,500)*(P.spd30 and 0.002 or 0.001) + mp:getSkillValue(SP[sc].s)*(P[SP[sc].ps] and 0.004 or 0.002)
			- G.ENC * (P.end15 and 0.1 or 0.2) - (1 - G.STN) * (P.wil15 and 0.1 or 0.2))
			* (D.AR.cs > 1 and D.AR.cs or math.min(D.AR.cs + G.LIG, 1)), 0.5)
		
		
			if ad.animationAttackState == 11 then
				if P.spd6 and not mp.isHitStunned then	local stc = 30/mp.animationController.animationData.castSpeed
					if stc < PST.current then PST.current = PST.current - stc
						ad.animationAttackState = 0		--mp.animationController.animationData.castSpeed = 100000000
						timer.delayOneFrame(function() timer.delayOneFrame(function()
							tes3.cast{reference = p, spell = G.SP2, alwaysSucceeds = false}
						end) end)
					end
				end
			else
				tes3.cast{reference = p, spell = G.SP2, alwaysSucceeds = false}
			end
		end
	elseif But == 2 then
		if P.spd6 and ad.animationAttackState == 11 and not mp.isHitStunned then
			local stc = 30/mp.animationController.animationData.castSpeed
			if stc < PST.current then PST.current = PST.current - stc		MB[2] = 0		ad.animationAttackState = 0 end
		--	tes3.messageBox("cspd = %s     stc = %d", mp.animationController.animationData.castSpeed, stc)
		end
	end
end end end		event.register("mouseButtonDown", MOUSEBUTTONDOWN)


local function MOUSEBUTTONUP(e) if not tes3ui.menuMode() and e.button == 0 and ad.animationAttackState == 2 then	local dir = ad.physicalAttackType	if dir < 4 and not G.dfr then	local pass = MB[cf.mbcharg] == 128
	if cf.autocharg or pass then	local w = mp.readiedWeapon		w = w and w.object		local mag = Mag(600)		local DMag = mag		if DMag > 0 then
		local vec = tes3.getPlayerEyeVector()	if math.abs(vec.z) < 0.15 then vec.z = 0	vec = vec:normalized() end
		local wr = w and w.reach or 0.5
		local hit = tes3.rayTest{position = tes3.getPlayerEyePosition(), direction = vec, ignore = {p}}		local ref, dist
		if hit then ref = N[hit.reference] and hit.reference end
		if ref then dist = ref.position:distance(pp) else ref, dist = L.Sector{d = 9000, lim = 500} end
		dist = dist and dist - 30 or (hit and hit.distance) or 10000
		if (pass or ref) and dist > wr*140 then		local timk, DodBon		local DodSt, DodPow = L.DodCalc()	local HS = mp.isHitStunned		if HS then DodPow = DodPow/2 end
			if T.Dash.timeLeft then timk = 1 + T.Dash.timeLeft/(P.atl8 and 10 or 5) else timk = 1 end
			if P.spd15 and DodSt * timk < PST.current then DodBon = DodPow else DodBon = 0 end
			local DK = (P.spd8 and 80 or 60) * (1 + (P.una15 and D.AR.u*0.01 or 0)) * (HS and 0.5 or 1)	
			DMag = math.clamp((dist - DodBon)/DK, 0, DMag)
			local DD = DMag * DK + DodBon
			local mc = math.max(DMag + (P.acr8 and mp.isFalling and 0 or math.min(DMag,5)) - (P.alt10 and mag/10 or 0), 0) * L.MCOST(0) * timk
			if mc < PMP.current then
				local stam = mc * ((P.end10 and 1 or 2) - (P.una10 and D.AR.u*0.04 or 0)) + (DodBon > 0 and DodSt * timk or 0)
				local vk = math.max(-0.4 - vec.z, 0)/3
				V.d = vec*(DD/0.15 * (1 - vk))		G.dfr = 0.15
				tes3.playSound{soundPath = L.RSound("Dash"), volume = 1, pitch = math.random(90,110)/100}
				if not mp.isJumping then V.djf = true	mp.isJumping = true end
				
			--	G.dashaspd = mp.animationController.weaponSpeed		mp.animationController.weaponSpeed = G.dashaspd/(P.spd21 and 2 or 5)		
				G.dashaspd = G.atspd/(P.spd21 and 2 or 5)	--tes3.messageBox("Charge!  %.3f", G.dashaspd)
				G.CombatDistance.value = (DD + 50)/wr		TFR(2, function() G.CombatDistance.value = 128 end)		
				--G.CombatAngleXY.value = math.clamp(50/DD, 0.05, 0.3)	--G.CombatAngleXY.value = G.CombatAng
				
				G.DashHit = DD		G.DashD = DD * (P.str9 and 0.02 or 0.01)
				Mod(mc)		PST.current = math.max(PST.current - stam, 0)
				if cf.m then tes3.messageBox("Dash-strike! Dist = %d  Cost = %.1f + %d stam  Time = %.1f   SlamK = %d%%", DD, mc, stam, T.Dash.timeLeft or 0, vk*100) end
				if T.Dash.timeLeft then T.Dash:cancel()	end		T.Dash = timer.start{duration = 3, callback = function() end}
				if P.atl15 and DD > 299 and T.SPR.timeLeft then T.SPR:cancel() end
				if P.blu12 and DD > 499 and w and w.type == 4 and dir == 2 and ad.attackSwing > 0.95 and vec.z < -1 + mp:getSkillValue(20)/(P.acr3 and 150 or 200) and mp.isFalling then G.SlamD = true end
			end
		end
	end end
end end end		event.register("mouseButtonUp", MOUSEBUTTONUP)


-- animationAttackState всегда 0   Свинг ещё не определен.
local function ATTACKSTART(e) local a = e.mobile	local spd	--local ar = e.reference		local dir = e.attackType		local ad = a.actionData		local wd = w and w.variables
local w = a.readiedWeapon	w = w and w.object 		local wt = w and (a == mp and W.wt or w.type) or -1		local sk = math.min(a:getSkillValue(WT[wt].s),200)		--local fiz = ad.physicalDamage	local wh = wd and wt ~= 11 and 100*wd.condition/w.maxCondition or 100
--local wt = w and w.type or -1
--if m.actorType == 1 or (m.object.biped or m.object.usesEquipment) then
--local m1 = (mp.isMovingForward or mp.isMovingBack)	local m2 = (mp.isMovingLeft or mp.isMovingRight)		local mov = m1 and (m2 and 3 or 1) or (m2 and 2 or 0)
--e.attackType = m1 and (m2 and 2 or 3) or (m2 and 1 or 2)


if w and wt < 11 then
--	local max = math.max((2 - spd)/3, 0)			--	spd = spd + (wt < 9 and not WT[wt].h1 and max/2 or 0) + max * ((a ~= mp or P[wt < 9 and "str16" or "str17"]) and 1 or 0.5) * str/(str + 100)
	local str = math.min(a.strength.current,500)		local ww = L.GetWW(w,a)
	spd = 2 + ww/(ww + 50) * (-3.5 + (WT[wt].spb and 0.5 or 0) + str/(str + 100) * ((a ~= mp or P[wt < 9 and "str16" or "str17"]) and 1 or 0.5) )
else spd = e.attackSpeed end


if a == mp then
	e.attackSpeed = spd * math.max((0.8 + math.min(a.speed.current,500)/(P.spd1 and 1000 or 2000) + sk/(P[WT[wt].p4] and 500 or 1000) - (1 - G.STN) * (P.atl11 and 0.1 or 0.2) - G.ENC * (P.atl12 and 0.1 or 0.2))
	* math.min(D.AR.as + G.LIG, 1), 0.5)
	
	if wt < 9 then
		if G.NewAtDir then e.attackType = G.NewAtDir 	G.NewAtDir = nil end
		G.atspd = e.attackSpeed
		e.attackSpeed = G.atspd * G.swingmult
	--	tes3.messageBox("AtStart! (%s)  dir = %s  SPD = %.3f -> %.3f   Mult = %.3f   HS = %s", wt, e.attackType, G.atspd, e.attackSpeed, G.swingmult, mp.isHitStunned)
		G.swingmult = 1
	end
	
	if W.DWM then T.DWB = timer.start{duration = (P.bloc16 and 0.2 or 0.15) + mp:getSkillValue(0)/2000, callback = function() end} end
else
	e.attackSpeed = spd * math.max(0.8 + a.speed.current/500 + sk/500 - (1 - math.min(a.fatigue.normalized,1)) * 0.2 - a.encumbrance.normalized * 0.2, 0.5)

	if wt < 9 then	local ar = e.reference		local tar = a.actionData.target
		if cf.pvpspd > 0 and tar then L.DodM(ar, a, tar == mp and pp or tar.reference.position) end
		--if a.isFalling then e.attackSpeed = math.min(e.attackSpeed, 1) end
		--tes3.messageBox("At start! Part = %s  AS = %s   HS = %s", AF[ar].part, a.actionData.animationAttackState, a.isHitStunned)
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
		+ (dir == 3 and (a ~= mp or P.agi31) and 0.05 or 0)
		+ (wt == -1 and ((a ~= mp or P.hand11) and -0.3 or -0.5) or 0)
		
		if a == mp then		G.rng = e.reach
			if dir == 1 then e.angleXY = (P.agi27 and 60 or 45) + (P.agi15 and 30 or 0)
			elseif dir == 2 then e.angleXY = P.agi27 and 30 or 20		if P.agi27 then e.angleZ = 60 end
			elseif dir == 3 then e.angleXY = P.agi27 and 20 or 15 end
		end
--		tes3.messageBox("Cone %s   At = %s   Rea = %.3f  %d     Ang = %.3f   %.3f    %s", e.attacker, dir, e.reach, e.reach * 128, e.angleXY, e.angleZ, e.target or "")
	end
end		event.register("calcHitDetectionCone", CALCHITDETECTIONCONE)

-- Для ближнего боя хит это первое событие. Определяются таргет, направление атаки и свинг, НО физдамаг все еще старый на момент завершения события - он обновится сразу после события и уже учтет силу и прочность оружия
-- Свинг можно менять только для ближнего боя - и тогда во время события атаки physicalDamage будет соответсвовать новому свингу
--ad.physicalDamage бесполезно менять и для ближнего и для дальнего боя. В событии дамага ad.physicalDamage для дальнего боя отображается неверно.
local function CALCHITCHANCE(e) --local a = e.attackerMobile	local t = e.targetMobile	local ad = a.actionData
	e.hitChance = 100
--	tes3.messageBox("HIT!  dir = %s  swing = %.2f  dmg = %.2f   spd = %.3f", ad.physicalAttackType, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed)
--	local pos = tes3.getPlayerEyePosition() + tes3.getPlayerEyeVector()*150		local post = e.target.sceneNode:getObjectByName("Bip01 Head").worldTransform.translation
--	tes3.createReference{object = "4nm_boundstar", position = pos, cell = p.cell}	tes3.createReference{object = "4nm_boundstar", position = post, cell = p.cell, scale = 2}
end		if cf.hit then event.register("calcHitChance", CALCHITCHANCE) end


-- Первое событие для дальнего боя: менять свинг: он уже не изменится при хите, который идет после атаки. Для ближнего боя идет сразу после хита. Дамаг НЕ определен если не было события хита.
-- Можно менять ad.physicalDamage для ближнего боя и это сработает. Но ad.physicalDamage не поменяется для дальнего боя.
--Можно менять fFatigueAttackBase для контроля стамины. Событие НЕ срабатывает для мультивыстрела и мультиброска.
L.AD = {[1] = {"slashMin", "slashMax"}, [2] = {"chopMin", "chopMax"}, [3] = {"thrustMin", "thrustMax"}, [4] = {"chopMin", "chopMax"}, [5] = 1, [6] = 1, [7] = 1, [0] = {"chopMin", "chopMax"}}
local function ATTACK(e) local a = e.mobile		local ar = e.reference
local rw = a.readiedWeapon	local w = rw and rw.object	local wt = w and (a == mp and W.wt or w.type) or -1		local wd = rw and rw.variables		local ad = a.actionData		local dir = ad.physicalAttackType	
local WS = math.min(a.actorType == 0 and (dir == 4 and a.stealth.current or a.combat.current) or a:getSkillValue(WT[wt].s), 200)	  local ww = w and math.min(w.weight, 50)		local WD	local BWK

if ww == 0 then
	BWK = (0.6 + math.min(a:getSkillValue(13),100) * ((a ~= mp or P.con8) and 0.002 or 0.001)) * (a == mp and P.con19 and D.BWwgt and 1.25 or 1)
	ww = w.enchantCapacity/10 * ((a ~= mp or P.con20) and 0.5 or 0.6) * (a == mp and P.con19 and D.BWwgt and 1.5 or 1)
else BWK = 1 end


if a == mp then
	if w then
		if wt == 10 then
			if T.Arb.timeLeft then ad.attackSwing = 0.5		T.Arb:cancel() else ad.attackSwing = 1 end
		elseif W.DWM and T.DWB.timeLeft then T.DWB:cancel() end
	end
	
	if dir ~= 4 then
		mp.animationController.weaponSpeed = G.dashaspd or G.atspd
	--	tes3.messageBox("Swing = %.4f   AtSpd = %.3f  HS = %s", ad.attackSwing, G.atspd, mp.isHitStunned)
	end
	
else
	if dir == 4 then ad.attackSwing = wt == 10 and 1 or math.lerp(0.75, 1, ad.attackSwing)		--tes3.messageBox("AMM = %s  id = %s", a.readiedAmmoCount, a.readiedAmmo and a.readiedAmmo.object.id)
		if a.readiedAmmoCount == 0 then		if not a.readiedAmmo then a.object:reevaluateEquipment() end		a.readiedAmmoCount = 1		tes3.messageBox("AMMO FIX!  %s", ar) end
	else ad.attackSwing = math.lerp(0.5, 1, ad.attackSwing)		local tr = e.targetReference
		if cf.pvpspd > 0 and ar.tempData.hum and tr then L.DodM(ar, a, tr == p and pp or tr.position)		--tes3.messageBox("Attack! %s", wc.systemTime)
		end
		--tes3.messageBox("Attack! Part = %s  AS = %s   HS = %s", AF[ar].part, ad.animationAttackState, a.isHitStunned)
	end
end
local sw = ad.attackSwing

local StCost = ((ww or 0) + (WT[wt].h1 and 5 or 10))
* (a == mp and math.max(sw,0.25) or sw/2)
* ( ((a ~= mp or P.end6) and 0.75 or 1) - ((a ~= mp or P[WT[wt].p3]) and WS/400 or 0) )
* (1 + a.encumbrance.normalized * ((a ~= mp or P.atl14) and 0.1 or 0.25))

if wt < 9 then	local Cond
	if L.AD[dir] == 1 then WD = ar.object.attacks[1].max * sw * (1 + math.max(1 - a.health.normalized, 0)/2)
	elseif w then Cond = wd.condition/w.maxCondition		Cond = Cond > 1 and math.min(Cond,1.2) or math.lerp((a ~= mp or P.arm2) and 0.5 or 0.25, 1, Cond)			Cond = Cond * BWK
		WD = math.lerp(w[L.AD[dir][1]], w[L.AD[dir][2]], sw) * Cond
	else
		if a.werewolf then WD = 50 * sw else
			local gau = tes3.getEquippedItem{actor = ar, objectType = tes3.objectType.armor, slot = dir == 3 and 6 or 7}	gau = gau and math.min(gau.object.weight,10) or 0
			if gau > 0 then StCost = StCost * (1 + gau/10)
				WD = (5 + gau * ((a ~= mp or P.hand7) and 0.5 or 0.25)) * sw
			else WD = 5 * sw end	
		end
	end
	
	local Str = math.min(a.strength.current,500)
	local Kstr = 100 + Str * (a == mp and (P.str1 and 0.4 or 0.3) + (G.TR.tr10 and 0.1 or 0) + (P.str15 and 0.2 * math.max(1 - mp.health.normalized, 0) or 0) or 1)
	local Kskill = WS * (a == mp and (P[WT[wt].p1] and 0.4 or 0.2) + (P[WT[wt].h1 and "agi5" or "str2"] and 0.1 or 0) or 1)
	local Kstam = math.min(math.lerp((a ~= mp or P.end1) and 0.75 or 0.5, 1, a.fatigue.normalized*((a ~= mp or P[WT[wt].p2]) and 2 or 1.25)), 1)
	local Kdash = a == mp and G.DashD * (wt == 2 and P.long10 and 2 or 1) or 0

	if a == mp and w and MB[cf.mbmet] == 128 and w.weight ~= 0 then	if P.mark13 then Kskill = Kskill + 20 end
		local dmg = math.max(math.max(w.chopMax, w.thrustMax) * Cond, ww/3)
		local Kin = P.alt26 and math.min(math.min(mp.willpower.current,500)/10 + mp:getSkillValue(0)*0.3, cf.metlim) * sw or 0	local mc = 0
		if Kin > 0 then mc = Kin/(P.int39 and 10 or 5)		if PMP.current > mc then Mod(mc)	Kin = Kin * L.Cpow(mp,0,true) * (P.wil31 and 1.25 or 1) else Kin = 0	mc = 0 end end
		W.acs = 1000 + 2000* Kin/(ww+10) + ((Str*(WT[wt].h1 and 1 or 1.25)*(P.str12 and 1.5 or 1))/(ww+10))^0.5 * 500 * sw * Kstam
		W.metd = dmg * (100 + Kskill)/100
		if Cond == 1 then wd.condition = math.max(wd.condition - 1, 1) end
		W.met = tes3.dropItem{reference = p, item = w, itemData = wd}		if W.DWM then L.DWMOD(false) end
		PST.current = math.max(PST.current - StCost, 0)
		if cf.m30 then tes3.messageBox("Throw spd %d (%d%%)  dmg %.1f (%d + %d%% skill)  sw = %.2f  Kin %.1f (%.1f cost)", W.acs, 4*W.acs/(W.acs/100+100), W.metd, dmg, Kskill, sw, Kin, mc) end
		tes3.applyMagicSource{reference = p, name = "4nm_met", effects = {{id = 610, rangeType = 2}}}	ad.physicalDamage = 0	return
	end
	
	local FizDK = (Kstr + Kskill + Kdash) * (WT[wt].h1 and 0.75 or 1) * Kstam
	AF[ar].fizdk = FizDK		--attempt to index a nil value
	ad.physicalDamage = WD * FizDK / 100
	
	if w then ar.tempData.Parried = nil end

	if cf.m30 then tes3.messageBox("FizD %.1f = %.1f * %d%% (%d str + %d sk + %d dash * %d%% stam)   swing = %.2f  spd = %.3f  tar = %s",
	ad.physicalDamage, WD, FizDK, Kstr, Kskill, Kdash, Kstam*100, sw, a.animationController.weaponSpeed, e.targetReference) end
end

a.fatigue.current = math.max(a.fatigue.current - StCost, 0)

--if a == mp then tes3.messageBox("ATA! %s (%s)  dir = %s  swing = %.2f dmg = %.2f  spd = %.3f  tar = %s  ST = %d", ar, wt, ad.physicalAttackType, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed, e.targetReference, StCost) end
end		event.register("attack", ATTACK)


--Стамина отнимается сразу перед этим эвентом.		Во время этого эвента отнимается прочность оружия (на следующий фрейм уже отнято, минимум 1 прочности, только целые)
--Можно менять ad.physicalDamage для ближнего боя и это сработает. Но ad.physicalDamage не поменяется для дальнего боя.		Событие срабатывает для мультивыстрелов и мультибросков.
local function ATTACKHIT(e) local a = e.mobile	local ar = e.reference		local ad = a.actionData		local t = e.targetMobile
local rw = a.readiedWeapon	local w = rw and rw.object		local wt = w and (a == mp and W.wt or w.type) or -1

--if a ~= mp then local d = ad.physicalAttackType		local mov = ((a.isMovingForward or a.isMovingBack) and 1 or 0) + ((a.isMovingLeft or a.isMovingRight) and 2 or 0)	local new = L.WCO[w and (w.isOneHanded and 1 or 2) or 0][d][mov]
--	if new then ad.animationAttackState = 0		ad.physicalAttackType = new			tes3.messageBox("Ideal")	--elseif L.COMOV[mov] ~= d then MB[1] = 0		ad.animationAttackState = 0			tes3.messageBox("Half") end
--end

--if a ~= mp then L.Dod(ar, a) end

--a.animationController.weaponSpeed = -1


if rw then
	G.WdmgGMST.value = a == mp and (wt < 9 and G.WdmgM2 or G.WdmgM) or 0.1
	--tes3.messageBox("%s       val = %s", rw.variables.condition, G.WdmgGMST.value)		timer.delayOneFrame(function() tes3.messageBox("%s   - frame  val = %s", rw.variables.condition, G.WdmgGMST.value) end)
end



if a == mp then
	if wt < 9 then
		if not t then
			local hit = tes3.rayTest{position = tes3.getPlayerEyePosition() + V.down10, direction = tes3.getPlayerEyeVector(), maxDistance = 135 * G.rng, ignore = {p}}
			if hit then local r = hit.reference	local mob = r and r.mobile		local Mat, dir		local dmg = WT[wt].iso
				if mob then
					if mob.isDead then
						if wt == -1 then	tes3.playSound{reference = r, soundPath = L.RSound("Dmg0"), volume = cf.voldmg, pitch = math.random(90,110)/100}
						else	local ob = r.object		local at
							if ob.objectType == tes3.objectType.creature then	local mt = L.CRNIF[ob.mesh:lower()]		at = mt and mt.at
								if ob.type == tes3.creatureType.undead then
									if mob.chameleon > 49 then dir = "DmgGhost"		Mat = "DmgGhost"	
									elseif ob.blood == 1 then dir = "DmgSkeleton"	Mat = "DmgSkeleton" end
								elseif ob.blood == 2 then dir = "DmgDwemer"			Mat = "DmgDwemer" end
								if not Mat then Mat = mt and mt.mat or "Dmg" end
							else	Mat = "Dmg"		at = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = 1}		if at then at = at.object.weightClass end	end
							if not dir then dir = (dmg > 0 and Mat or "Dmg") .. dmg end
							if at then tes3.playSound{reference = r, soundPath = L.RSound("DmgArmor" .. at), volume = cf.volarm, pitch = math.random(90,110)/100} end
							tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = cf.voldmg, pitch = math.random(90,110)/100}
						end
					elseif not ad.hitTarget then ad.hitTarget = mob		t = mob end
					
				else
					Mat = L.MAT[L.GetMat(hit)] or "Stone"
					if Mat == "Water" then dir = Mat elseif wt == -1 then dir = "Dmg0" else dir = Mat .. dmg end
					tes3.playSound{reference = p, soundPath = L.RSound(dir), volume = cf.volimp, pitch = math.random(90,110)/100}
				end
				if w and Mat then rw.variables.condition = math.max(rw.variables.condition - ad.physicalDamage * L.MatD[Mat] * G.WdmgM2, 0)
					if L.MatSpark[Mat] then tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = hit.intersection} end
				end		--tes3.messageBox("%s   mat = %s", dir, Mat)
			end
		end
		
		if t then	local dir = ad.physicalAttackType		if W.DWM and w == W.WL and rw.variables == W.DL then dir = -1 end
			if T.Comb.timeLeft then		local maxcom = (P[WT[wt].pc] and 4 or 3) + math.floor(mp:getSkillValue(WT[wt].s)/50) + (P.spd14 and W.DWM and 1 or 0)
				if dir == G.last then G.comb = math.max(G.comb - 2, 0)
				elseif dir == G.pred then	if G.comb > 2 then G.comb = G.comb - 1 elseif G.comb < 2 then G.comb = G.comb + 1 end
				else G.comb = math.min(G.comb + 1, maxcom) end
				M.CombK.text = ("%s/%s"):format(G.comb, maxcom)		T.Comb:reset()	G.pred = G.last		G.last = dir			G.Ecomb = math.min(G.comb, P.spd7 and 10 or 4)
			else G.last = dir		T.Comb = timer.start{duration = (P.spd4 and 2 or 1.5) + (WT[wt].s == 5 and P.long11 and 0.5 or 0), callback = function() G.comb = 0		G.Ecomb = 0		G.last = nil	G.pred = nil	M.CombK.text = "" end} end
		end
		
	else M.CombK.text = ("%s"):format((mp.readiedAmmoCount or 1) - 1) end
	
	if w then
		local en = w.enchantment
		if wt < 11 and en and en.castType == 1 and (G.wf == 1 or (not G.wf and t)) then
			G.EnWsn = (tes3.applyMagicSource{reference = p, source = en, fromStack = rw}).serialNumber
		end

		if G.SlamD then
			tes3.playSound{sound = TC{"endboom1", "endboom2", "endboom3"}}		--"fabBossLeft", "fabBossRight"
			local dmg = ad.physicalDamage * G.DashHit/3000		local fdmg = 0	local num = 0	local ref
			for _, m in pairs(tes3.findActorsInProximity{reference = p, range = 250}) do if m ~= mp and m ~= t then	num = num + 1	ref = m.reference
				local pow = math.clamp(dmg * 2000 / (ref.tempData.hum and 100 or math.max(m.height, 50)), 400, 1000)
				local vdir = ref.position - pp		vdir.z = 0		vdir = vdir:normalized()		vdir.z = 0.3
				m:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
				if dmg > 0 then	G.DmgR[ref] = 0		G.FDSource = "Slam"		G.FDMG = dmg	G.FDMGImm = not (w.enchantment or w.ignoresNormalWeaponResistance)
					fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}		L.CrimeAt(m)
				end
				if cf.m then tes3.messageBox("Hammer Slam! Height = %d   %s (%d)  Dmg = %d/%d  Pow = %d", G.DashHit, m.object.name, num, fdmg, dmg, pow) end
			end end
		elseif P.str8 and w.isTwoHanded and ad.physicalAttackType == 1 and ad.attackSwing > 0.95 then
			local dmg = ad.physicalDamage/2		local fdmg = 0	local num = 0	local ref
			for _, m in pairs(tes3.findActorsInProximity{reference = p, range = w.reach * 150}) do if m ~= mp and m ~= t and tes3.getCurrentAIPackageId(m) ~= 3 then	num = num + 1	ref = m.reference
				local pow = math.clamp(dmg * 1000 * (WT[wt].impm or 1) * (1 - math.abs(mp:getViewToActor(m))/180) / (ref.tempData.hum and 100 or math.max(m.height, 50)), 400, 1000)
				local vdir = ref.position - pp		vdir.z = 0		vdir = vdir:normalized()		vdir.z = 0.3
				m:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
				if m.actionData.animationAttackState == 4 and m.readiedWeapon and m.readiedWeapon.object.type < 9 then
					m.actionData.animationAttackState = 0		tes3.playAnimation{reference = ref, group = 0x0, loopCount = 0}		-- Это работает без сбоев, следующая атака с рандомным временем
					tes3.playSound{reference = ref, soundPath = L.RSound("Parry" .. L.PSO[WT[wt].pso][WT[m.readiedWeapon.object.type].pso]), volume = cf.volimp, pitch = math.random(80,120)/100}
				elseif dmg > 0 then G.DmgR[ref] = WT[wt].iso		G.FDSource = "Round"	G.FDMG = dmg		G.FDMGImm = not (w.enchantment or w.ignoresNormalWeaponResistance)
					fdmg = m:applyDamage{damage = dmg, applyArmor = true, playerAttack = true}		L.CrimeAt(m)
				end
				if cf.m then tes3.messageBox("Round attack! %s (%d)  Dmg = %.1f/%.1f  FizD = %.1f  Pow = %d",  m.object.name, num, fdmg, dmg, ad.physicalDamage, pow) end
			end end
		end
	end
	
	--tes3.messageBox("Dash = %s  Slam = %s", G.DashHit, G.SlamD)
	G.DashHit = nil		G.SlamD = nil
else
	if wt < 9 then
		if not ad.hitTarget and ad.target == mp then ad.hitTarget = mp	t = mp end		--tes3.messageBox("New TARGET! ")
		
		local en = w and w.enchantment
		if en and en.castType == 1 then
			G.EnWsn = (tes3.applyMagicSource{reference = ar, source = en, fromStack = rw}).serialNumber
		end
	end
end

local Agi = math.min(a.agility.current,500)		local Tagi = t and math.min(t.agility.current,500)

if ar.data.CW then local rt
	if a == mp then rt = not D.CWdis and not (cf.smartcw and wt > 8) and (D.CWm and 2 or (t and t.playerDistance < (G.rng + 0.5) * 135 and 1))
	elseif wt < 9 then rt = 1 end
	if rt == 2 then timer.delayOneFrame(function() L.CWF(ar, 2, 1.5) end) elseif rt == 1 then L.CWF(ar, 1, 1) end
end

if t == mp and wt < 9 and (P.lig10 and D.AR.l > 14 and mp.isRunning or ((mp.isMovingLeft or mp.isMovingRight) and not mp.isMovingForward)) then
	local AtakCh = 100 + a:getSkillValue(WT[wt].s) + Agi - a.blind - (mp.chameleon + mp.invisibility*300) * (P.snek7 and 0.5 or 0.25)
	local activ = 0
	local passiv = math.min(Tagi * (P.agi20 and 0.2 or 0.1) + (P.luc3 and mp.luck.current/10 or 0) + (P.acr6 and mp.isJumping and mp:getSkillValue(20)/5 or 0), 100)
	local tim = (P.spd17 and 0.5 or 0.25) + (P.una11 and D.AR.u/100 or 0)
	local DodK = T.Dod.timeLeft and (T.Dod.timeLeft - 3 + tim)/tim or 0
	if DodK > 0 then activ = (G.dodm/5 + Tagi * (P.agi2 and 0.2 or 0.1) + (P.spd2 and 20 or 0) + (P.lig12 and D.AR.l or 0) + (P.agi23 and W.DWM and 20 or 0)) * DodK end
	local chance = AtakCh - passiv - activ
	if cf.m3 then tes3.messageBox("Hit chance = %d%% = %d - %d passive - %d active (%d%%)   jump = %s", chance, AtakCh, passiv, activ, DodK*100, mp.isJumping) end
	if chance < math.random(100) then
		L.skarm = (a.object.level + 5)/10 * ad.physicalDamage/20	
		if D.AR.l > 0 then mp:exerciseSkill(21, D.AR.l/25) end		if D.AR.u > 0 then mp:exerciseSkill(17, D.AR.u/25) end
		ad.physicalDamage = 0		return
	end
end



if t then	local tad = t.actionData
	if tad.animationAttackState == 4 and tad.blockingState ~= 2 then
		if a == mp and not D.nopar or (a ~= mp and cf.par) then		local tr = t.reference
			local trw = t.readiedWeapon		local tw = trw and trw.object		local twt = tw and tw.type or -1
		--	if t == mp then tes3.messageBox("Angle %d ", math.abs(mp:getViewToActor(a))) end
			if w and wt < 9 and tw and twt < 9 and not ar.tempData.Parried and (w.reach + tw.reach) * 150 > ar.position:distance(tr.position) then
				local TFD = tad.physicalDamage		local FD = ad.physicalDamage
				local wgt =	L.GetWW(w,a)		local twgt = L.GetWW(tw,t)
				local PK1 = (wgt*5 + AF[ar].fizdk + Agi/2 + a:getSkillValue(0)) * (ad.attackSwing + (a == mp and 0 or 0.25))
				* ((WT[wt].h1 and 0.5 or 0.75) + (a == mp and (P.bloc10 and 0.25 or 0) + (P[WT[twt].p9] and 0.25 or 0) + G.Ecomb * (P.bloc15 and 0.1 or 0.05) or 0.5) )
				local PK2 = (twgt*5 + AF[tr].fizdk + Tagi/2) * tad.attackSwing
				* ((WT[twt].h1 and 0.5 or 0.75) + (t == mp and (P.str6 and 0.25 or 0) + (P[WT[twt].p9] and 0.25 or 0) + G.Ecomb * (P.bloc15 and 0.1 or 0.05) or 0.5) ) 
				* (t == mp and math.clamp(t.animationController.weaponSpeed, 0.25, 1) or 1)
				
				local park = PK1 / PK2		local imp = (PK1 - PK2) * (((a ~= mp or P.bloc14) and 1.25 or 1) - ((t ~= mp or P.agi26) and 0.25 or 0) + t.encumbrance.normalized/4)
				rw.variables.condition = math.max(rw.variables.condition - FD * (a == mp and G.WdmgM2 or 0.1), 0)
				trw.variables.condition = math.max(trw.variables.condition - FD * (t == mp and G.WdmgM or 0.1), 0)
				ad.physicalDamage = 0
			
				if park > 1 then	tad.physicalDamage = 0
					if t == mp then
						if G.TR.tr5 then
							MB[1] = 0		tad.animationAttackState = 0
							PST.current = math.max(PST.current - imp/20, 0)
						else
							AF[tr].part = timer.start{duration = math.clamp(imp/500, 0.1, 1), callback = function()
								if imp < 500 then
								--	tes3.messageBox("Player! %s  HS = %s", tad.animationAttackState, t.isHitStunned)
									if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
								end 
							AF[tr].part = nil end}
							MB[1] = 0		tad.animationAttackState = 0	t:hitStun()
						end
					else 
						AF[tr].part = timer.start{duration = math.clamp(imp/500, 0.1, 1), callback = function() if AF[tr] then
						--	tes3.messageBox("    %s  HS = %s  Imp = %d", tad.animationAttackState, t.isHitStunned, imp)
							if imp < 500 then
								--if tad.animationAttackState == 1 and not L.AG[tad.currentAnimationGroup] then tad.animationAttackState = 0 end
								tad.animationAttackState = 0
							--	tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}
							end 
						AF[tr].part = nil end end}
						tad.animationAttackState = 1	t:hitStun()
						DOM[t] = nil
						--tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}
					end
					
					if a == mp then		if P.sec7 then tes3.applyMagicSource{reference = p, name = "Parry", effects = {{id = 510, min = 50, max = 50, duration = 1}}} end end
				
				elseif park > 0.75 then		tad.physicalDamage = 0
					if t == mp then		tr.tempData.Parried = true
					else
						DOM[t] = nil		tad.animationAttackState = 0		tes3.playAnimation{reference = tr, group = 0x0, loopCount = 0}		-- Это работает без сбоев, следующая атака с рандомным временем
					end
			
				else
					tr.tempData.Parried = true
					if t == mp and G.TR.tr5 then	tad.physicalDamage = 0
					else
						local NewTFD = TFD * (1 - park)		if NewTFD < 3 then NewTFD = 0 end
						tad.physicalDamage = NewTFD
					end
				end

				if cf.m3 then tes3.messageBox("%s PAR (%s)    %.2f = %d/%d    fiz = %.2f/%.2f    spd = %.2f   Imp = %d   Bl %s", ar == p and "PL " .. G.Ecomb or "",
				tad.animationAttackState, park, PK1, PK2, FD, TFD, t.animationController.weaponSpeed, imp, tad.blockingState) end
				
				tes3.playSound{reference = (a==mp or t==mp) and p or ar, soundPath = L.RSound("Parry" .. L.PSO[WT[wt].pso][WT[twt].pso]), volume = cf.volimp, pitch = math.random(80,120)/100}
				tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = (ar.position + tes3vector3.new(0,0,a.height*0.9) + tr.position + tes3vector3.new(0,0,t.height*0.9)) / 2}
				
				if a == mp then		L.ParInd(imp/20, park > 1 and 5 or 3)
					L.skw = (tr.object.level + 5)/10 * TFD/200 * math.min(park,2)		mp:exerciseSkill(WT[wt].s, 1)		L.skarm = L.skw*2	mp:exerciseSkill(0, 1)
				else
					ad.animationAttackState = 0		tes3.playAnimation{reference = ar, group = 0x0, loopCount = 0}			-- Это работает без сбоев, следующая атака с рандомным временем
					if cf.pvpcont and a:getSkillValue(WT[wt].s) + Agi > math.random(200) then a:forceWeaponAttack() end		-- Работает без сбоев, мгновенная контратака

					if t == mp then	L.ParInd(imp/20, park > 1 and 1 or 2)
						if P.bloc15 and T.Comb.timeLeft then T.Comb:reset() end
					end
				end
			end
		end
	elseif t == mp and W.DWM and tad.animationAttackState == 2 and wt < 9 and w then
		if T.DWB.timeLeft and math.abs(mp:getViewToActor(a)) < (P.bloc17 and 30 or 20) then		local bls = t:getSkillValue(0)		local WTL = WT[W[W.WL.id] or W.WL.type]
			local FD = ad.physicalDamage		local wgt = L.GetWW(w,a)		local lwgt = L.GetWW(W.WL,t)
			local PK1 = (lwgt*5 + t:getSkillValue(WTL.s) + t.strength.current/2 + Tagi/2 + bls) * math.lerp(P.bloc19 and 0.5 or 0.25, 1, G.STN) * ((P.bloc10 and 0.75 or 0.5) + (P[WTL.p9] and 0.25 or 0))
			local PK2 = (wgt*5 + AF[ar].fizdk + Agi/2) * ad.attackSwing * (WT[wt].h1 and 1 or 1.5)
			local park = PK1 / PK2
			local Wcost = wgt * (P.bloc13 and 1 or 1.5) * math.min(PK2/PK1, 2)		
			local Scost = lwgt * math.max(1 - bls * (P.bloc3 and 0.005 or 0.002), 0.5)
			local newstam = PST.current - Scost - Wcost
			PST.current = math.max(newstam, 0)
			if newstam < 0 then mp:hitStun() end			
			
			W.DL.condition = math.max(W.DL.condition - FD / (P.arm3 and 10 or 5), 0)
			tes3.playSound{reference = p, soundPath = L.RSound("Parry" .. L.PSO[WT[wt].pso][WTL.pso]), volume = cf.volimp, pitch = math.random(80,120)/100}
			tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = (ar.position + tes3vector3.new(0,0,a.height*0.9) + pp + tes3vector3.new(0,0,mp.height*0.9)) / 2}
			L.skarm = (ar.object.level + 5)/10 * FD/100 * math.min(park,2)		mp:exerciseSkill(0, 1)
			if cf.m3 then tes3.messageBox("DW Block!  %.2f = %d/%d   cost = %d + %d   time left = %.2f   angle = %d", park, PK1, PK2, Scost, Wcost, T.DWB.timeLeft, math.abs(mp:getViewToActor(a))) end
			if park > 0.75 then ad.physicalDamage = 0
				ad.animationAttackState = 0		tes3.playAnimation{reference = ar, group = 0x0, loopCount = 0}
				if T.CST.timeLeft then T.CST:reset() elseif P.bloc4 then T.CST = timer.start{duration = 0.4 + (P.bloc8 and (Tagi + bls)/1000 or 0), callback = function() end} end
			else ad.physicalDamage = FD * (1 - park) end
		elseif cf.m3 then tes3.messageBox("No DW block  time left = %.2f   angle = %d", T.DWB.timeLeft or 0, math.abs(mp:getViewToActor(a))) end
	end
	
--	if t.readiedShield and tad.blockingState > 0 then ad.attackWasBlocked = true end
	
end


--tes3.messageBox("ATHIT  ref = %s  wt = %s  dir = %s  swing = %.2f  dmg = %.2f  spd = %.3f  tar = %s %s %s", ar, wt, ad.physicalAttackType, ad.attackSwing, ad.physicalDamage, a.animationController.weaponSpeed,
--e.targetMobile and e.targetMobile.reference, ad.target and ad.target.reference, ad.hitTarget and ad.hitTarget.reference)
end		event.register("attackHit", ATTACKHIT)


local function CALCBLOCKCHANCE(e)	local a, t = e.attackerMobile, e.targetMobile		local s = t:getSkillValue(0) 	local activ = t.actionData.animationAttackState == 2	local ad = a.actionData
local wt = a.readiedWeapon		wt = wt and (a == mp and W.wt or wt.object.type) or -1
local ang = t:getViewToActor(a)			local max = (ang >= 0 and (activ and 30 or 20) or (activ and -40 or -60)) * ((t ~= mp or P.bloc9) and 1.5 or 1)
local Kang = math.clamp(1 - ang/max, 0, 1)
local Kstam = math.min(math.lerp(((t ~= mp or P.bloc19) and 0.75 or 0.5), 1, t.fatigue.normalized), 1)
local Ktar = (t == mp and (activ and (P.bloc1 and 100 or 50) or 0) or 150) + (s/2 + t.agility.current/5 + t.luck.current/10) * ((t ~= mp or P.bloc20) and 1.25 or 1)
local Katak = (a:getSkillValue(WT[wt].s)/2 + a.agility.current/5 + a.luck.current/10) * ((a ~= mp or P.agi28) and 1.25 or 1) * (2 - ad.attackSwing)
local bloc = Ktar * Kstam * Kang - Katak

--if ad.physicalDamage == 0 then e.blockChance = 0	tes3.messageBox("0 fiz Dmg") return end

if bloc > math.random(100) then e.blockChance = 100
	if t == mp then	L.skarm = (a.object.level + 5)/10 * ad.physicalDamage/20 end
else e.blockChance = 0 end
if cf.m3 then tes3.messageBox("%s %d%% = %d tar * %d%% stam * %d%% ang (%d/%d) - %d atk  FD = %d", e.blockChance == 100 and "BLOCK" or "block", bloc, Ktar, Kstam*100, Kang*100, ang, max, Katak, ad.physicalDamage) end
end		event.register("calcBlockChance", CALCBLOCKCHANCE)


-- Навык блока прибавляется ДО этого эвента
local function SHIELDBLOCKED(e)	local dmg = e.conditionDamage	if dmg == 0 then	if cf.m30 then tes3.messageBox("BLOCK + PAR! %s", e.reference) end		else
	local t = e.mobile		local SH = t.readiedShield		local swgt = SH.object.weight	if swgt == 0 then swgt = 10 end		local s = t:getSkillValue(0)
	--local tr = e.reference		--local a = e.attacker	local ar = a.reference	local ad = a.actionData 
	--local rw = a.readiedWeapon		local w = rw and rw.object		local wgt = w and L.GetWW(w,a) or 5		--local wt = w and w.type or -1
	local Scost = swgt * math.max(0.5 - s * ((t ~= mp or P.bloc3) and 0.003 or 0.001), 0.2)
	local Wcost = dmg * math.max(1 - s * ((t ~= mp or P.bloc23) and 0.005 or 0.002), 0.5)
	local newstam = t.fatigue.current - Scost - Wcost
	t.fatigue.current = math.max(newstam, 0)
	if newstam < 0 then t:hitStun() end
	
	if t == mp then
		if P.bloc22 then e.conditionDamage = dmg * 0.75 end			L.UpdShield(SH)
		if T.CST.timeLeft then T.CST:reset() elseif P.bloc4 then T.CST = timer.start{duration = 0.4 + (P.bloc8 and (t.agility.current + s)/1000 or 0), callback = function() end} end
	end
	if cf.m30 then tes3.messageBox("BLOCK! %s   dmg = %d   cost = %d + %d", e.reference, dmg, Scost, Wcost) end
end end		event.register("shieldBlocked", SHIELDBLOCKED)



-- Вызывается после атаки для ближнего боя и после хита для дальнего. Можно менять слот, по которому попадет удар. Далее идёт дамаг. НЕ вызывается если попали по щиту или кричеру ИЛИ от удара кулаком по невырубленному
-- e.attackerMobile == нил для скриптового урона (урон хп от кулака, удар ногой, кинетический удар, кинетическая стрела, слэм, круговой удар)
local function CALCARMORPIECEHIT(e) local r = e.reference	G.ArSlot = e.slot
	local s = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = G.ArSlot}
	if not s and e.fallback then s = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = e.fallback} end
	arm = s and s.object:calculateArmorRating(e.mobile) or 0		arp = s and s.object.weightClass or 3
	--e.slot = 0		e.projectile
	if r == p then local a = e.attackerMobile 	if a then L.skarm = a.actionData.physicalDamage/20 end end		--a.object.level/10
--	tes3.messageBox("ARMor! ref = %s  slot = %s  fall = %s  atak = %s  dmg = %.2f  Fist = %s", r, e.slot, e.fallback, e.attacker, e.attacker and e.attackerMobile.actionData.physicalDamage or 0, e.attacker and not e.attackerMobile.readiedWeapon)
end		event.register("calcArmorPieceHit", CALCARMORPIECEHIT)


L.FizDmgStam = {["Round"] = true, ["Slam"] = true, ["Arrow"] = true, ["Throw"] = true, ["Blast"] = true}
L.FizDmgArm = {["Arrow"] = true, ["Blast"] = true}
L.FizDmgResist = {["Round"] = true, ["Slam"] = true, ["Throw"] = true, ["Kick"] = true}
--L.FizDmgStun = {["Round"] = true, ["Slam"] = true, ["Arrow"] = true, ["Throw"] = true, ["Blast"] = true}
local function DAMAGE(e) local source = e.source	if source == "attack" then local a = e.attacker	local t = e.mobile	local ar = e.attackerReference	local tr = e.reference	local ad = a.actionData		local tad = t.actionData
local rw = a.readiedWeapon		local pr = e.projectile		local Arm = t.armorRating		local Mult, Kperk = 100, 0		local bid = ar.baseObject.id	local prvel, velk
local WS, FD		local w = pr and pr.firingWeapon or (rw and rw.object)	local wt = w and (not pr and a == mp and W.wt or w.type) or -1
local sw = ad.attackSwing	 local dir = ad.physicalAttackType		local Agi = math.min(a.agility.current,500)		local Luc = math.min(a.luck.current,500)
local Tagi = t.agility.current		local Tend = t.endurance.current	local Tluc = t.luck.current		local BaseHP = t.health.base	local fat = math.clamp(t.fatigue.normalized,0,1)
if t.actorType == 0 then arm = t.shield		arp = nil	end
if a.actorType == 0 then WS = pr and a.stealth.current or a.combat.current		if not w then Kperk = (1 - a.health.normalized) * WS/2 end
else WS = a:getSkillValue(WT[wt].s)	end
local Armult = 1 - (pr and (arp == 2 and (t ~= mp or P.hev14) and -0.2 or 0) or (w and L.GetWW(w,a)/((a ~= mp or P.str11) and 100 or 200) or 0))

if pr then --magw = (pr.reference.object.ignoresNormalWeaponResistance or pr.reference.object.enchantment) and 100 or 0
	prvel = pr.velocity:length()	velk = 4*prvel/(prvel/100+100)
	FD = pr.damage * velk/100
else
	--if L.AD[dir] == 1 then magw = 50 elseif w then magw = (w.ignoresNormalWeaponResistance or w.enchantment) and 100 or 0 end
	FD = ad.physicalDamage
end
if t ~= mp and ar.data.SumPl then FD = FD * (P.con21 and 0.75 or 0.6) end


local as = (a.isMovingForward and wt < 9 and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and wt < 9 and 3) or 0
local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0
local hs = 100 + (WS + math.min(a.strength.current,500) + Agi)/((a ~= mp or P.str13) and 10 or 20)
+ (as == 1 and (a ~= mp or P.str3) and 20 or 0)
+ (a == mp and G.Ecomb * (P.agi9 and 10 or 5) or 0)
+ ((a ~= mp or P.str4 and sw > 0.95) and 20 or 0)
+ (ts == 1 and (not (t == mp and P.med10 and D.AR.m > 14) and 30 or 0) or 0)
- (t == mp and P[L.AT[arp].p6] and 20 or 0)
- (t == mp and P.hev12 and D.AR.h or 0)
- Tend/((t ~= mp or P.end5) and 5 or 10)
- Tagi/((t ~= mp or P.agi26) and 5 or 10)
- (ts == 0 and (t ~= mp or P.str5) and t.strength.current/10 or 0)

local CritC = a.attackBonus/4
+ Agi/((a ~= mp or P.agi1) and 5 or 10)
+ WS/((a ~= mp or P[WT[wt].p6]) and 10 or 20)
+ Luc/((a ~= mp or P.luc1) and 10 or 20)
+ (as == 1 and (a ~= mp or P.spd3) and 10 or 0)
+ (ts == 1 and ((t == mp and P.med10 and D.AR.m > 14 and 0 or 10) + ((t ~= mp or P.agi7) and 0 or 10)) or 0)
+ (t == mp and ( arp == 3 and math.max(20 - t:getSkillValue(17)/(P.una13 and 5 or 10), 0) or (P[L.AT[arp].p5] and -t:getSkillValue(L.AT[arp].s)/10 or 0) ) or 0)
+ (a == mp and G.Ecomb * (P.agi6 and 5 or 3) + (wt < 9 and a.isJumping and P.acr4 and a:getSkillValue(20)/10 or 0) - 10 or 10)
- (Tend + Tagi)/((t ~= mp or P.end3) and 10 or 20)
- Tluc/((t ~= mp or P.luc2) and 10 or 20)
+ (1 - fat)*((a ~= mp or P.agi11) and 20 or 10)
- (t == mp and ts == 0 and P.hev11 and D.AR.h or 0)
- arm/10

local StamM = t == mp and (P.end12 and 1.5 or 2) + ((ts == 3 or (P.hev10 and ts == 0 and D.AR.h > 14)) and (P.med10 and D.AR.m > 14 and 0 or 1) or 0) - (P[L.AT[arp].p7] and 0.5 or 0) or 2

local dist = 0
if w then
	if wt == 0 then		-- Короткие клинки
		if a ~= mp or P.short0 then Kperk = (1 - t.health.normalized) * WS * 0.3 end
		if a ~= mp or P.short11 then CritC = CritC + (1 - fat) * WS/5 end
		if a == mp and P.short10 and sw < 0.5 then mp.animationController.weaponSpeed = 1000000 end		--ad.animationAttackState = 0
	elseif WT[wt].s == 7 then		-- Древковое
		dist = math.min((ar.position + tes3vector3.new(0,0,a.height/2)):distance(tr.position + tes3vector3.new(0,0,t.height/2)) - 100, 100)
		if dist > 0 then if a ~= mp or P.spear0 then Kperk = dist/5 * WS/100 end
		else Kperk = dist/2 * math.max(1 - WS/((a ~= mp or P.spear12) and 100 or 300), 0) end
		
		if dir == 3 and (a ~= mp or P.spear11 and sw > 0.95) then CritC = CritC + 10 end
		--	tes3.messageBox("distance = %d", dist)
	
	elseif WT[wt].s == 4 then	-- Дробящее
		hs = hs + WS/((a ~= mp or P.blu7) and 2 or 4)
		Armult = Armult - WS * ((a ~= mp or P.blu0a) and 0.003 or 0.001)
		if wt == 3 or wt == 4 then		-- Булавы и молоты
			if a ~= mp or P.blu11 then StamM = StamM + 0.5 end
		elseif a ~= mp or P.blu0c then Kperk = math.min(a.magicka.normalized, 1) * WS * 0.3 end			-- Посохи		wt == 6 or wt == -2
	elseif a ~= mp or P[WT[wt].p] then
		if wt > 8 then dist = ar.position:distance(tr.position)
			if wt == 9 then Kperk = dist * WS/20000 -- Луки 5% за каждую 1000 дистанции
			elseif wt == 10 then Kperk = WS * ((a ~= mp or P.mark9) and math.max(1000 - dist,0)/5000 or 0)		Armult = Armult - WS*0.003
				if a ~= mp or P.mark9 then hs = hs + WS * math.max(3000 - dist,0)/6000 end		--pr.attackSwing
			elseif wt == 11 then AF[ar].met = math.min((AF[ar].met or -1) + 1, (a ~= mp or P.mark10) and 10 or 5)	Kperk = AF[ar].met * WS * 0.03
				if AF[ar].mettim then AF[ar].mettim:reset() else AF[ar].mettim = timer.start{duration = a == mp and 1 + (P.mark8 and WS/200 or 0) or 2 + WS/100, callback = function()
				if AF[ar] then AF[ar].met = -1		AF[ar].mettim = nil end end} end
			end
		else
			if wt > 6 then 	-- Секиры
				AF[ar].axe = math.min((AF[ar].axe or -1) + 1, (a ~= mp or P.axe10) and 10 or 5)		Kperk = AF[ar].axe * WS * 0.03
				if a ~= mp or P.axe7 then CritC = CritC + AF[ar].axe * WS/50 end
				if not AF[ar].axetim then AF[ar].axetim = timer.start{duration = a == mp and 1 + (P.axe11 and WS/200 or 0) or 2 + WS/100, iterations = -1, callback = function(te)
					if not AF[ar] then te.timer:cancel() else AF[ar].axe = AF[ar].axe - 1		if AF[ar].axe < 0 then te.timer:cancel()	AF[ar].axetim = nil end end end}
				end
			elseif wt > 0 then	-- Длинные клинки
				if (AF[ar].long or 0) < 2 then AF[ar].long = (AF[ar].long or 0) + 1
				else AF[ar].long = 0		Kperk = WS/2
					if (a ~= mp or P.long12) then hs = hs + WS/2		CritC = CritC + WS/10 end
				end
				if AF[ar].longtim then AF[ar].longtim:reset() else AF[ar].longtim = timer.start{duration = a == mp and 0.8 + (P.long7 and WS/250 or 0) or 1.5 + WS/200, callback = function()
					if AF[ar] then AF[ar].long = 0		AF[ar].longtim = nil end end}
				end
			end
		end
	end
	if (a ~= mp or P.bloc11) and AF[tr].part then	local bls = a:getSkillValue(0)		Kperk = Kperk + bls*0.2
		if a ~= mp or P.bloc12 then CritC = CritC + bls/10 end
	end
end


if a == mp then
	if not R[tr] or not R[tr].cm then if pr then
		if P.mark14 and math.max(math.abs(t:getViewToActor(mp)),50) * dist * (mp.isSneaking and 2 or 1) > (P.snek8 and 50000 or 100000) then
			Mult = Mult + 50		Armult = Armult - 0.1 - (P.snek13 and mp:getSkillValue(19)/500 or 0)			mp:exerciseSkill(19, 1 + tr.object.level/10)
		end
	elseif math.abs(t:getViewToActor(mp)) > (P.snek8 and 135 or 150) then	Armult = Armult - (0.1 + (P.snek13 and mp:getSkillValue(19)/500 or 0)) * (wt == 0 and 3 or 1)
		Mult = Mult + 100 + (P.snek3 and mp.isSneaking and 100 or 0) + ((wt == 0 and P.short12) and 100 or 0)	mp:exerciseSkill(19, 1 + tr.object.level/5)
	end end
	if ((P.con12 and t.object.type == 1) or (P.con13 and t.object.type == 2)) then Mult = Mult + mp:getSkillValue(13)/10 end
	if w then
		if T.CST.timeLeft then local bls = a:getSkillValue(0)		Kperk = Kperk + bls*0.2	if P.bloc5 then hs = hs + bls/2		CritC = CritC + bls/10 end		if cf.m3 then tes3.messageBox("Counterstrike!") end end
	end
else
	local MagAt = L.CMAG[bid]		if MagAt and MagAt[2] > math.random(100) then tes3.applyMagicSource{reference = ar, source = B[MagAt[1]]} end
end


local tw = t.readiedWeapon		local two = tw and tw.object		local twt = two and two.type or -1		local tsh = t.readiedShield		local tas = tad.animationAttackState

if t == mp then
	if pr and tas == 4 and P.bloc18 and tw and twt < 9 then	local ang = math.abs(mp:getViewToPoint(pr.position))
		local bloc = (t:getSkillValue(WT[twt].s)/2 + t:getSkillValue(0) + Tagi/4 + Tluc/4) * fat * math.clamp(t.animationController.weaponSpeed - 0.5, 0.2, 1) - WS/2 - Agi/4 - Luc/4
		if cf.m3 then tes3.messageBox("Weapon block projectile chance = %d%%   Angle = %d", bloc, ang) end
		if ang < 20 and bloc > math.random(100) then
			mp:exerciseSkill(0, 2)		mp:exerciseSkill(WT[twt].s, 2)		tes3.playSound{reference = p, soundPath = L.RSound("Parry1"), volume = cf.volimp, pitch = math.random(80,120)/100}
			tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = pr.position}	
			e.damage = 0	 return
		end
	end
else
	if tr.object.blood == 2 then for _, splash in ipairs(wc.splashController.activeSplashes) do splash.node.appCulled = true end
		tes3.createVisualEffect{object = G.VFXspark, repeatCount = 1, position = (tr.position + tes3vector3.new(0,0,t.height * math.random(50,90)/100) + tr.forwardDirection * 25 + tr.rightDirection * math.random(-30,30))}
	end
end


local KOut = not t.hasFreeAction	local Kcrit
if CritC > math.random(100) then
	Kcrit = (a == mp and 30 + (P.agi8 and 10 or 0) + (P[WT[wt].p5] and 10 or 0) or 50) + math.max(CritC - 100, 0)
	Kcrit = math.random(Kcrit, Kcrit*2)
	hs = hs + Kcrit/2
else Kcrit = 0 end


Mult = Mult - math.min(((ts == 3 or (t == mp and P.hev10 and ts == 0 and D.AR.h > 14)) and math.min(Tend/((t ~= mp or P.end2) and 5 or 10)
+ ((t ~= mp or P.bloc2) and tsh and t:getSkillValue(0)/10 or 0), 30) or 0)
+ (as == 3 and a == mp and math.max(40 - (WS + Agi)/(P.agi19 and 10 or 20) - (WT[wt].s == 7 and P.spear10 and 10 or 0), 0) or 0)
+ (not tsh and (not tw and (t.actorType ~= 0 and (t ~= mp or P.hand20) and (t:getSkillValue(26)/10 + Tagi/20) or 0) or
((t ~= mp or P.hand9 and not W.DWM) and WT[twt].h1 and (t:getSkillValue(26) + Tagi)/20 or 0)) or 0), 50)	
+ (KOut and ((a~= mp or P.str14) and 50 or 25) or 0)



DMG = FD * (Mult + Kperk + Kcrit)/100		Arm = Arm * math.max(Armult,0)
local Res = t.resistNormalWeapons		if Res < 0 then Arm = Arm + math.max(Res, -100) end
-- Если t.resistNormalWeapons 100 или выше то для атак нормальным оружием эвент НЕ срабатывает, но сработает для всех остальных источников
--local Res = math.clamp(t.resistNormalWeapons, -100, 100)	local Norm		if Res > 0 then Norm = 1 - math.clamp(Res - (magw or 0), 0, 100)/100 else Norm = 1 - Res/100 end

local DmgN = math.min(DMG,100)		local Karm = Arm > 0 and DmgN / (DmgN + Arm) or 1 - Arm/100			DMG = DMG * Karm
hs = (a == mp and 500*DMG/BaseHP or math.max(3*DMG, 500*DMG/BaseHP)) * hs/100


if pr and tsh then	local ang = t:getViewToPoint(pr.position)		if (t ~= mp or tas == 2) and math.abs(ang) < 45 or (ang > -90 and ang < 0) then
	local bloc = (t:getSkillValue(0)/2 + Tagi/4 + Tluc/4) * fat * ((t ~= mp or P.bloc6) and 1.5 or 1) * ((t ~= mp or tas == 2) and 1 or 0.3)
	- (WS/2 + Agi/4 + Luc/4) * ((a ~= mp or P.mark16) and 1 or 0.5)
	if cf.m3 then tes3.messageBox("Block projectile chance = %d%%   Ang = %d", bloc, ang) end
	if bloc > math.random(100) then tsh.variables.condition = math.max(tsh.variables.condition - DMG * ((t ~= mp or P.bloc22) and 0.3 or 0.5) , 0)
		if t == mp then mp:exerciseSkill(0, 1)	L.UpdShield(tsh) end	if tsh.variables.condition < 0.1 then t:unequip{item = tsh.object} end
		e.damage = 0	
		t:hitStun{cancel = true}
		tes3.playSound{reference = r, soundPath = L.RSound("DmgShield0"), volume = cf.volimp, pitch = math.random(90,110)/100}		return
	end
end end


local Dred, smc, trauma = 0, 0, 0	local KSM = tr.data.e508		local LLM = ar.data.e509

if KSM and t.magicka.current > 5 then	KSM = KSM * (t == mp and P.una14 and 1 + D.AR.u/100 or 1)
	Dred = math.min(t.magicka.current/3, DMG, KSM)	smc = Dred * (t == mp and (P.int38 and 0.75 or 1) - (P.una8 and D.AR.u*0.01 or 0) + D.AR.l*0.02 + D.AR.m*0.04 + D.AR.h*0.06 or 0.5)
	DMG = DMG - Dred		Mod(smc,t)
	if wt == -1 and L.AD[dir] ~= 1 then		if DMG == 0 then tes3.playSound{reference = tr, soundPath = L.RSound("Dmg0"), volume = cf.voldmg, pitch = math.random(90,110)/100} end
	elseif arp == 3 or (not arp and DMG == 0) then tes3.playSound{reference = tr, soundPath = L.RSound("DmgArmor0"), volume = cf.volarm, pitch = math.random(90,110)/100} end
end

if LLM and a.health.normalized < 1 and a.magicka.current > 5 then
	local LLhp = math.min(a.magicka.current/4, LLM/100 * DMG, a.health.base - a.health.current)		local mc = LLhp * (a == mp and (P.res8 and 0.5 or 0.75) or 0.2)
	tes3.modStatistic{reference = ar, name = "health", current = LLhp}		Mod(mc,a)
	if (a ~= mp or P.res8) and a.fatigue.normalized < 1 then a.fatigue.current = a.fatigue.current + LLhp*2 end
	if cf.m3 then tes3.messageBox("Life leech for %.1f hp (%.1f damage)  %.1f mag  Cost = %.1f", LLhp, DMG, LLM, mc) end
end



if a == mp and w and D.poison and DMG > 0 then
	if wt < 9 then D.poison = D.poison - (P.agi12 and 25 or 30) + math.min(Agi + mp:getSkillValue(16),600)/40	M.WPB.widget.current = D.poison		if D.poison <= 0 then D.poison = nil	M.WPB.visible = false end end
	local chance = 50 + (Agi/2 + Luc/4)*(P.agi13 and 2 or 1) - Tagi/2 - Tluc/4 - arm/2
	if chance > math.random(100) then tes3.applyMagicSource{reference = e.reference, source = B.poi}		if cf.m5 then tes3.messageBox("Poisoned! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end
	elseif cf.m5 then tes3.messageBox("Poison failure! Chance = %d%%  Poison charges = %s", chance, D.poison or 0) end 
end

local KO = math.min(math.min(100*DMG/BaseHP - ((a ~= mp or P.str4) and sw > 0.95 and 0 or 10), 40)
* (1 + (1 - fat + t.encumbrance.normalized) * ((t ~= mp or P.end22) and 0.5 or 1) + ((a ~= mp or P.blu9) and (wt == 3 or wt == 4) and 0.5 or 0))
- Tagi*((t ~= mp or P.agi26) and 0.5 or 0.25), DMG)


local newhp = t.health.current - DMG
if newhp < 1 then
	if not KOut then
		local hgt = math.max(tr.tempData.hgt, 50) * (tr.tempData.hum and 0.75 or 1)
	--	local pow = math.clamp(DMG * (WT[wt].impm or 1) * 10 / tr.tempData.mass, 500, 1500)
		local pow = math.clamp(DMG * (WT[wt].impm or 1) * 1000 / hgt, 500, 1500)
		local vdir = pr and pr.velocity:copy() or tr.position - ar.position
		if pow > 501 and dir == 1 and cf.ragang ~= 0 then vdir = L.MatrRag * vdir end
		vdir.z = 0		vdir = vdir:normalized()		vdir.z = 0.3
		t:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
	--	tes3.messageBox("mass %.2f   hgt %.2f   pow = %d", tr.tempData.mass, hgt/100, pow)
	end
else
	if not KOut then
		if t.fatigue.current > 0 then		local newstam = t.fatigue.current - DMG * StamM
			t.fatigue.current = math.max(newstam, 0)
			if newstam < 0 then hs = 100	KO = KO * 2 end
		end
	
		if KO > math.random(100) then t:hitStun{knockDown = true}
		else hs = hs + math.max(KO,0)		
			if hs < math.random(100) then t:hitStun{cancel = true} end
		end
	end
	local traumpr = DMG/math.max(BaseHP,100)
	if cf.traum and traumpr > ((t ~= mp or P.end4) and 0.1 or 0.05) then
		trauma = traumpr * ((a ~= mp or P.str7) and 100 or 50) + Kcrit/10 - (Tend + Tluc)/((t ~= mp or P.luc4) and 20 or 40)
		if trauma > 0 then tes3.modStatistic{reference = tr, name = L.Traum[math.random(5)], current = - math.random(trauma)} end
	end
end



e.damage = DMG
if cf.m30 then tes3.messageBox([[%.1f = %.1f * %d%% arm (%d %d%%)
* %d%% mult + %d%% perk + %d%% crit (%d%%)
%d vel (%d%%)
Hs %d%%   KO %d%%   StamD %d%%
%.1f Shield (%.1f mag, %.1f mc)  %d traum]],
DMG, FD, Karm*100, Arm, Armult*100, Mult, Kperk, Kcrit, CritC, prvel or 0, velk and velk or 0, hs, KO, StamM*100, Dred, KSM or 0, smc, trauma) end

if DMG > 0 and L.AD[dir] ~= 1 then G.DmgR[tr] = WT[wt].iso end


if a == mp then L.skw = (tr.object.level + 5)/10 * DMG/20
	if P.axe9 and WT[wt].s == 6 and newhp < 1 then AF[ar].axe = math.min(AF[ar].axe + 5, 10) end
	if cf.dmgind then L.DmgInd(DMG, newhp, BaseHP, Kcrit > 0) end
else
	if t == mp then
		if newhp/BaseHP < 0.2 then
			if P.sec3 and not tes3.isAffectedBy{reference = p, object = B.TS} then 
				--local min = 20 + mp:getSkillValue(18)/5		tes3.applyMagicSource{reference = p, name = "Survival_instinct", effects = {{id = 510, min = min, max = min + 10, duration = 3}}}
				B.TS.effects[1].id = 510  B.TS.effects[1].min = 25 + mp:getSkillValue(18)/4   B.TS.effects[1].max = B.TS.effects[1].min   B.TS.effects[1].duration = 3
				tes3.applyMagicSource{reference = p, source = B.TS, createCopy = false}
			end
			if newhp < 1 and P.luc14 and BaseHP > 49 and mp.health.normalized >= 1 then e.damage = DMG - 1.1 + newhp end
		end
	end
	local Pois = L.CPOI[bid]		if Pois and DMG > 0 and Pois[2] > math.random(100) then tes3.applyMagicSource{reference = tr, source = B[Pois[1]]} end
end

elseif source == "script" then	--tes3.messageBox("FDS = %s   DMG = %.1f    Arp %s   ARef = %s   GdmgR %s", G.FDSource, e.damage, arp, e.attackerReference, G.DmgR[e.reference])	
	-- arp не обновляется если урон нанесен существу!	e.damage уже с учетом резиста к нормальноум оружию, он равен 0 для имунных, а броня равна бесконечности!
	if G.FDSource then	local tr = e.reference		local t = e.mobile		local KSM = tr.data.e508	local Dred, hs
		local Arm = t.armorRating		local Res = t.resistNormalWeapons	--G.FDMG * G.FDMG / e.damage - G.FDMG
		if Res > 99 then if G.FDMGImm and t.chameleon > 49 and tr.object.type == tes3.creatureType.undead then G.FDMG = 0 end
		elseif Res < 0 then Arm = Arm + math.max(Res, -100) end
		local DmgN = L.FizDmgArm[G.FDSource] and math.clamp(G.FDMG,50,100) or math.min(G.FDMG,100)
		local Karm = Arm > 0 and DmgN / (DmgN + Arm) or 1 - Arm/100
		local DMG = G.FDMG * Karm
		
		if KSM and t.magicka.current > 5 then KSM = KSM * (t == mp and P.una14 and 1 + D.AR.u/100 or 1)
			Dred = math.min(t.magicka.current/3, DMG, KSM)		local smc = Dred * (t == mp and (P.int38 and 0.75 or 1) - (P.una8 and D.AR.u*0.01 or 0) + D.AR.l*0.02 + D.AR.m*0.04 + D.AR.h*0.06 or 0.5)		
			DMG = DMG - Dred		Mod(smc,t)
			if DMG == 0 then G.DmgR[tr] = nil end
		--	if t.actorType == 0 then arp = nil end
		--	if arp == 3 or (not arp and DMG == 0) then tes3.playSound{reference = tr, soundPath = L.RSound("DmgArmor0"), volume = cf.volarm, pitch = math.random(90,110)/100} end
		--	if cf.m30 then tes3.messageBox("Kin shield (%s)  Dmg %.1f = %.1f - %.1f   Mag %.1f  Cost %.1f", G.FDSource, DMG, e.damage, Dred, KSM, smc) end
			-- сейчас по кричерам если урон = 0, то нет звука от кругового удара и слэма.
		end
		e.damage = DMG
		
		local HP = t.health		local BaseHP = HP.base		local NewHP = HP.current - DMG
		if NewHP > 1 then	local Tend = t.endurance.current		local traumpr = DMG/math.max(BaseHP,100)
			if traumpr > ((t ~= mp or P.end4) and 0.1 or 0.05) then
				local trauma = 50*traumpr - (Tend + t.luck.current)/((t ~= mp or P.luc4) and 20 or 40)
				if trauma > 0 then tes3.modStatistic{reference = tr, name = L.Traum[math.random(5)], current = - math.random(trauma)} end
			end
			if L.FizDmgStam[G.FDSource] then	local fat = t.fatigue
				if t.hasFreeAction and fat.current > 0 then 	local newstam = fat.current - DMG
					fat.current = math.max(newstam, 0)
					hs = newstam < 0 and 100 or 5*DMG/BaseHP * (100 - (Tend + t.agility.current)/5)
					if hs > math.random(100) then t:hitStun() end
				end
			end
		end
		
		if G.FdmgInd and cf.dmgind then L.DmgInd(DMG, NewHP, BaseHP, G.FdmgInd > 0)  	G.FdmgInd = nil end
		if cf.m30 then tes3.messageBox("%s  Dmg %.1f = %.1f * %d%% arm (%d)   Shield %.1f / %d   Stun %d%%", G.FDSource, DMG, G.FDMG, Karm * 100, Arm, Dred or 0, KSM or 0, hs or 0) end
		G.FDSource = nil	G.FDMG = nil	G.FDMGImm = nil
	else
		local script = mwse.getCurrentMorrowindScriptState()
		if script and L.LavaScript[script.id] then		local tr = e.reference		e.damage = 0
			if not AF[tr].LavaT then	tes3.applyMagicSource{reference = tr, source = B.Lava_fire}
				AF[tr].LavaT = timer.start{duration = 2, callback = function() if AF[tr] then AF[tr].LavaT = nil end end}
			end
		end
	end
elseif source == "shield" then	e.damage = 0	local el = e.activeMagicEffect.effectId		local El = L.ELSH[el]		local ts = tes3.getSimulationTimestamp()
	if El.ts ~= ts then		local ar = e.attackerReference	local tr = e.reference
		if ar.position:distance(tr.position) < ((ar ~= p or P.alt44) and 300 or 200) then
			local mag = math.random(0, Mag(el,ar) *	(ar == p and (P.alt22 and 1 or 0.75) + (P.una14 and D.AR.u/100 or 0) or 1) )
			local E = B.ElSh.effects[1]		E.id = El.id	E.min = mag		E.max = mag		E.duration = 1
			SNC[(tes3.applyMagicSource{reference = tr, source = B.ElSh}).serialNumber] = e.attacker		--tes3.messageBox("%s   mag = %s   ar = %s", el, mag, ar)
		end
	end		El.ts = ts
elseif source == "fall" then	local t = e.mobile		local tr = e.reference		local vel = -t.velocity.z
	local DMG = math.max((vel - 700 - t:getSkillValue(20) * (t == mp and P.acr5 and 8 or 5)) * (t == mp and P.acr7 and 0.05 or 0.1) / (1 + t.agility.current/200), 0)
	if cf.m30 then tes3.messageBox("Fall!  Vel = %d    DMG = %d  -->  %d", vel, e.damage, DMG) end
	if t == mp then		L.skacr = vel/500
		if DMG > 0 then local KSM = D.e508
			if KSM and PMP.current > 5 then KSM = KSM * (P.una14 and 1 + D.AR.u/100 or 1)
				local Dred = math.min(PMP.current/3, DMG, KSM)		local smc = Dred * ((P.int38 and 0.75 or 1) - (P.una8 and D.AR.u*0.01 or 0) + D.AR.l*0.02 + D.AR.m*0.04 + D.AR.h*0.06)
				DMG = DMG - Dred		Mod(smc)
				if cf.m then tes3.messageBox("Kin shield (fall)	 %.1f damage (-%.1f)  Mag %.1f  Cost %.1f", DMG, Dred, KSM, smc) end
			end
			if P.luc14 and mp.health.current - DMG < 1 and mp.health.base > 49 and mp.health.normalized >= 1 then DMG = mp.health.current - 1.5 end
		end
		if DMG < 0.1 then timer.delayOneFrame(function() wc.hitFader:deactivate() end) end
	end
	e.damage = DMG
	if DMG > 0 then G.DmgR[tr] = "Fall" end
	
	local BaseHP = t.health.base		local traumpr = DMG/math.max(BaseHP,100)
	if cf.traum and traumpr > ((t ~= mp or P.end4) and 0.1 or 0.05) then
		local trauma = 50*traumpr - (t.endurance.current + t.luck.current)/((t ~= mp or P.luc4) and 20 or 40)
		if trauma > 0 then tes3.modStatistic{reference = e.reference, name = L.Traum[math.random(5)], current = - math.random(trauma)} end
	end
end end		event.register("damage", DAMAGE)
--event.register(tes3.event.damaged, function() wc.hitFader:deactivate() end)


local function DAMAGEHANDTOHAND(e) local a = e.attacker	local ar = e.attackerReference	local t = e.mobile	local tr = e.reference	local ad = a.actionData		local FizD = ad.physicalDamage
	if FizD < 0.0001 then e.fatigueDamage = 0		if a == mp then	L.skw = 0 end		return end
	local sw = ad.attackSwing	 local dir = ad.physicalAttackType		local s = a:getSkillValue(26)	local Agi = math.min(a.agility.current,500)		local Kcrit
	local as = (a.isMovingForward and 1) or (a.isMovingLeft or a.isMovingRight and 2) or (a.isMovingBack and 3) or 0
	local ts = (t.isMovingForward and 1) or (t.isMovingLeft or t.isMovingRight and 2) or (t.isMovingBack and 3) or 0
	local StamCur = t.fatigue.current - 1		local THP = t.health
	

	local CritC = a.attackBonus/4 + Agi/((a ~= mp or P.agi1) and 5 or 10) + math.min(a.luck.current,500)/((a ~= mp or P.luc1) and 10 or 20)
	+ s/((a ~= mp or P.hand6) and 10 or 20) + (as == 1 and (a ~= mp or P.spd3) and 10 or 0)
	+ (ts == 1 and ((t == mp and P.med10 and D.AR.m > 14 and 0 or 10) + ((t ~= mp or P.agi7) and 0 or 10)) or 0)
	+ (a == mp and G.Ecomb * (P.agi6 and 5 or 3) + (a.isJumping and P.acr4 and a:getSkillValue(20)/10 or 0) - 10 or 10)
	- (t.endurance.current + t.agility.current)/((t ~= mp or P.end3) and 10 or 20) - t.luck.current/((t ~= mp or P.luc2) and 10 or 20) - t.armorRating/10
	+ math.clamp(1-t.fatigue.normalized,0,1)*((a ~= mp or P.agi11) and 20 or 10) - (t == mp and ts == 0 and P.hev11 and D.AR.h or 0)

	if CritC > math.random(100) then
		Kcrit = (a == mp and 30 + (P.agi8 and 10 or 0) + (P.hand5 and 10 or 0) or 50) + math.max(CritC - 100, 0)
		Kcrit = math.random(Kcrit, Kcrit*2)
	else Kcrit = 0 end


	local Mult = 100 - math.min(((ts == 3 or (t == mp and P.hev10 and ts == 0 and D.AR.h > 14)) and math.min(t.endurance.current/((t ~= mp or P.end2) and 5 or 10)
	+ ((t ~= mp or P.bloc2) and t.readiedShield and t:getSkillValue(0)/10 or 0), 30) or 0)
	+ (not t.readiedShield and (not t.readiedWeapon and (t.actorType ~= 0 and (t ~= mp or P.hand20) and (t:getSkillValue(26)/10 + t.agility.current/20) or 0) or
	((t ~= mp or P.hand9 and not W.DWM) and WT[t.readiedWeapon.object.type].h1 and (t:getSkillValue(26) + t.agility.current)/20 or 0)) or 0), 50)

	if a == mp then
		if (not R[tr] or not R[tr].cm) and math.abs(t:getViewToActor(mp)) > (P.snek8 and 135 or 150) then
			Mult = Mult + 100 + (P.snek3 and mp.isSneaking and 100 or 0) + (P.hand18 and 100 or 0)		mp:exerciseSkill(19, 1 + tr.object.level/5)
		end
		if ((P.con12 and t.object.type == 1) or (P.con13 and t.object.type == 2)) then Mult = Mult + mp:getSkillValue(13)/10 end
	end

	local Koef = (Mult + Kcrit)/100
	local FD = FizD * (((a ~= mp or P.hand17) and 3.5 or 3) - ((t ~= mp or P.end12) and 0.5 or 0)) * Koef		local KO = StamCur < FD
	local fistd = FizD * ((a ~= mp or P.hand19) and 1 or 0.5) * Koef * (KO and 1 or 0.5)		-- gau

	local hs = (100 + Kcrit/2 + (s + math.min(a.strength.current,500) + Agi)/((a ~= mp or P.str13) and 10 or 20) + (as == 1 and (a ~= mp or P.str3) and 20 or 0) + (a == mp and G.Ecomb * (P.agi9 and 10 or 5) or 0)
	+ (ts == 1 and (not (t == mp and P.med10 and D.AR.m > 14) and 30 or 0) or 0) - (t == mp and P.hev12 and D.AR.h or 0)
	- (t.endurance.current + t.agility.current)/((t ~= mp or P.end5) and 5 or 10) - (ts == 0 and (t ~= mp or P.str5) and t.strength.current/10 or 0)) * FD*2/THP.base
	
	
	if KO then
		if THP.normalized > 0.3 then
			if hs/2 > math.random(100) then
				t.actionData.animationAttackState = 0		tes3.playAnimation{reference = tr == p and (mp.is3rdPerson and p or tes3.player1stPerson) or tr, group = 0x0, loopCount = 0}	t:hitStun()		-- Хитстан с гарантией
			end
			e.fatigueDamage = math.min(StamCur, FD)
		else e.fatigueDamage = FD end
	else
		if hs < math.random(100) then tr.tempData.nostun = true	end		--t:hitStun{cancel = true}
		e.fatigueDamage = math.min(StamCur, FD)
	end
	
	G.DmgR[tr] = -1		G.FDSource = "Fist"		G.FDMG = fistd		G.FDMGImm = true
	local fdmg = t:applyDamage{damage = fistd, applyArmor = true, playerAttack = a == mp}		--resistAttribute = 12
	if THP.current - fdmg < 1 then tes3.playSound{reference = tr, soundPath = L.RSound("Dmg0"), volume = cf.voldmg, pitch = math.random(90,110)/100} end
	
	if cf.m30 then tes3.messageBox([[Fist %.1f = %.1f * %d%% (%d%% mult + %d%% crit (%d%%))   Stun%s %d%%   Dmg %d/%d]], FD, FizD, Koef*100, Mult, Kcrit, CritC, KO and "Lock" or "", KO and hs/2 or hs, fdmg, fistd) end
	
	if a == mp then	L.skw = (tr.object.level + 5)/10 * FD/30
		if cf.dmgind then L.DmgInd(FD, THP.current, THP.base, Kcrit > 0) end
	end
end		event.register("damageHandToHand", DAMAGEHANDTOHAND)


local function damaged(e) if e.source == "attack" then local tr = e.reference
	if e.killingBlow then
		tes3.messageBox("dmg = %s   jump = %s", e.damage, jump)
	end
end	end		--event.register("damaged", damaged)

local function DAMAGEDHANDTOHAND(e) local r = e.reference
	--tes3.messageBox("fat dmg = %s", e.fatigueDamage)
	if r.tempData.nostun then r.tempData.nostun = nil
		e.mobile:hitStun{cancel = true}
	end
end		event.register("damagedHandToHand", DAMAGEDHANDTOHAND)


local function playGroup(e) if L.AGHS[e.group] then local r = e.reference 	if r == tes3.player1stPerson then r = p end		--e.animationData 
--	if not AF[r] then mwse.log("%s  %s (%s  %s)  fl = %s", r, table.find(tes3.animationGroup, e.group), e.group, e.index, e.flags) end
	if r.tempData.nostun then r.tempData.nostun = nil	return false end		--attempt to index a nil value  при загрузке сейва		PlayerSaveGame  hit1 (19  0/1/2)  fl = 1
--else local r = e.reference 	if r == tes3.player1stPerson then r = p end
--	tes3.messageBox("%s  %s (%s  %s)  fl = %s", r, table.find(tes3.animationGroup, e.group), e.group, e.index, e.flags)
--	if e.group == 128 and e.index == 2 then return false end
end
--if e.reference.baseObject.id == "centurion_projectile" then tes3.messageBox("%s  %s (%s  %s)  fl = %s", e.reference, table.find(tes3.animationGroup, e.group), e.group, e.index, e.flags) end
end		--event.register("playGroup", playGroup)


L.VFXBL = {["VFX_DestructCast"] = true, ["VFX_FireCast"] = true, ["VFX_FrostCast"] = true, ["VFX_LightningCast"] = true, ["VFX_PoisonCast"] = true,
--["VFX_ConjureCast"] = true, ["VFX_IllusionCast"] = true, ["VFX_MysticismCast"] = true, ["VFX_RestorationCast"] = true, ["VFX_AlterationCast"] = true
}
local function vfxCreated(e) local vfx = e.vfx		local t = vfx.target		-- vfx.effectNode может быть нил!
	if t then
		if t == p then
			if L.VFXBL[vfx.effectObject.id] and cf.vfxbl then 
				--	vfx.effectNode.rotation = x
				--tes3.messageBox("freq  %s", vfx.effectNode.controller.frequency)
				--vfx.effectNode.controller.frequency
				vfx.expired = true
			end
		else	local nod = vfx.effectNode
			--	tes3.messageBox("%s   scale %.3f   ref %.3f   hgt %.3f ", vfx.effectObject.id, vfx.effectNode.scale, t.scale, t.tempData.hgt/133)
			if nod then nod.scale = t.scale end
		end
	end
end		if cf.vfxnew then event.register("vfxCreated", vfxCreated) end

--local function COMBATSTART(e) if e.target == mp then if L.CID[e.actor.reference.baseObject.id] == "dwem" and tes3.isAffectedBy{reference = p, object = "summon_centurion_unique"} then return false end end end		event.register("combatStart", COMBATSTART)
-- бехевиор: -1 = стоит столбом и ничего не делает хотя и в бою. 255 - затупил после прыжка,  5 = убегает и не видит игрока, 6 = убегает; 3 = атака; 2 - идл (но бывает и при атаке); 0 = хеллоу; 8 = бродит
L.BEH = {[5] = 1, [6] = 1, [-1] = 0, [255] = 0}		L.SEA = {[1] = 1, [3] = 1, [4] = 1}
local function COMBATSTARTED(e) local m = e.actor	local ref = m.reference	 	if e.target == mp and not R[ref] and m.combatSession then	local ob = m.object		local bid = ob.baseObject.id
local hum = ref.tempData.hum	if hum then mp:startCombat(m) end		m.scanInterval = 0

R[ref] = {m = m, a = m.actionData, ob = ob, c = 0, hum = hum, at = hum and 1 or (not ob.usesEquipment and 3), lim = math.max((P.per7 and 70 or 100) + ob.level*(P.ill19 and 5 or 10), 100),
rc = L.MAC[(m.actorType == 1 and m:getSkillValue(10) > 40) and 0 or bid], fun = cf.full and L.CFF[bid], pos = ref.position, jump = 0}
timer.delayOneFrame(function() if R[ref] then R[ref].cm = true end end)
if cf.m4 then tes3.messageBox("%s joined the battle! Enemies = %s", ref, table.size(R)) end		--local tik5 = math.floor(T.CT.timing)%5 == 0


if not H[ref] and not ref.data.SumM and (m.actorType == 1 and m.flee < 70 or (ob.biped or ob.type ~= 0 or ob.usesEquipment)) and m.health.normalized > 0.5 and not L.IsFollover(m,mp) then
	H[ref] = {m = m, spos = m.position:copy(), scell = ref.cell, status = 1, safe = tes3.makeSafeObjectHandle(ref)}
end

if cf.hdist > 0 and ref.cell.isInterior and not AF[ref].THelp and not ref.data.SumM then
	AF[ref].THelp = timer.start{duration = math.max(3 - m.agility.current/100, 1), iterations = 1, callback = function() if AF[ref] and not m.isDead and m.inCombat and m.fatigue.current > 0 and m.paralyze < 1 and m.silence < 1 then
		if cf.m4 then tes3.messageBox(eng and "%s calls for help!" or "%s зовет на помощь!", m.object.name) end
		for _, mob in pairs(tes3.findActorsInProximity{reference = ref, range = cf.hdist}) do if mob ~= mp and mob ~= m and not mob.inCombat and mob.fight > 89 then
			mob:startCombat(mp)		if cf.m4 then tes3.messageBox(eng and "%s heard and runs into battle!" or "%s услышал и бежит на помощь!", mob.object.name) end
		end end
	end end}
end

--local cs = m.combatSession.castableSpells
--for i, sp in pairs(cs) do if sp.castType == 0 then tes3.messageBox("%s - %s (%s)", i, sp.id, table.size(cs)) end end
--cs:add(tes3.getObject(TC{"shockball", "Fireball_large"})) 


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
							
							--[[
								t.tar = t.a.target	
								t.tarp = G.PPF	t.dist = t.tarp:distance(t.pos) - 50		t.pdis = pp:distance(t.pos)
								t.vec = t.tarp - t.pos		t.vec.z = 0		t.vec = t.vec:normalized()
								t.mspd = ((t.hum and 100 + t.m.speed.current or t.m.speed.current * 3) + math.min(t.m.agility.current/100, 1)) * (0.5 + math.min(t.m.fatigue.normalized,1)/2) * (1 - t.m.encumbrance.normalized)
								t.maxd = math.clamp(t.mspd, 350, 1200)
								V.upz = tes3vector3.new(0,0,math.clamp(0.2666 + (G.PPZF - pz)/500, -0.2, 0.7))
								tes3.messageBox("RUN HD  %d / %d    mspd = %d   ZD = %d   Z = %.3f   Pdis = %d   tar = %s", t.dist, t.maxd, t.mspd, G.PPZF - pz, V.upz.z, t.pdis, t.tar and t.tar.reference)	
								t.m:doJump{velocity = (t.vec * math.min(t.dist, t.maxd)/500 + V.upz) * 1000, applyFatigueCost = false}
								if t.hum then t.m:forceWeaponAttack{swing = 1} end
							--]]
								
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
						if t.rc then tes3.applyMagicSource{reference = r, source = B[TC(t.rc)]} end
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
					
						--[[
							t.tar = t.a.target	
							t.tarp = G.PPF	t.dist = t.tarp:distance(t.pos) - 50		t.pdis = pp:distance(t.pos)
							t.vec = t.tarp - t.pos		t.vec.z = 0		t.vec = t.vec:normalized()
							t.mspd = ((t.hum and 100 + t.m.speed.current or t.m.speed.current * 3) + math.min(t.m.agility.current/100, 1)) * (0.5 + math.min(t.m.fatigue.normalized,1)/2) * (1 - t.m.encumbrance.normalized)
							t.maxd = math.clamp(t.mspd, 350, 1200)
							V.upz = tes3vector3.new(0,0,math.clamp(0.2666 + (G.PPZF - pz)/500, -0.2, 0.7))
							tes3.messageBox("SEARCH  %d / %d    mspd = %d   ZD = %d   Z = %.3f   Pdis = %d   tar = %s", t.dist, t.maxd, t.mspd, G.PPZF - pz, V.upz.z, t.pdis, t.tar and t.tar.reference)	
							t.m:doJump{velocity = (t.vec * math.min(t.dist, t.maxd)/500 + V.upz) * 1000, applyFatigueCost = false}
							if t.hum then t.m:forceWeaponAttack{swing = 1} end
						--]]	
								
								
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
					if t.rc then tes3.applyMagicSource{reference = r, source = B[TC(t.rc)]} end
				else status = "SEARCH - NO LINE" end
			elseif L.BEH[beh] == 0 then	status = "EXTRA COMBAT!"	t.m:startCombat(mp)		t.a.aiBehaviorState = 3
			else status = ""	if t.c > 0 and (not w or w.type < 9) then t.c = 0 end		--if not w or w.type < 9 then t.c = t.c > cf.AIsec and cf.AIsec or 0 end
				if cf.durka and L.SEA[sa] and not t.m.isHitStunned and t.m.isMovingForward then t.tar = t.a.target		t.jump = t.jump + 1
					if t.tar and t.jump > 1 then
						t.tarp = t.tar == mp and G.PPF or t.tar.position		t.dist = t.tarp:distance(t.pos) - 50		t.pdis = t.tar == mp and pp:distance(t.pos) or 0
						t.vec = t.tarp - t.pos		t.vec.z = 0		t.vec = t.vec:normalized()
						t.mspd = (t.hum and 100 + t.m.speed.current or (r.tempData.Bspd + t.m.speed.current) * 1.5)
						* (3 + math.min(t.jump,6)/4 + math.min(t.m.agility.current/100, 1))
						* (0.5 + math.min(t.m.fatigue.normalized,1)/2) * (1 - t.m.encumbrance.normalized)
						t.maxd = math.clamp(t.mspd, 350, 1200)
						V.upz = tes3vector3.new(0,0,math.clamp(0.2666 + ((t.tar == mp and G.PPZF or t.tarp.z) - pz)/500, -0.2, 0.7))
						
						if t.dist > 250 and t.dist < t.maxd and t.pdis > math.min(t.mspd,200) then
						--	tes3.messageBox("%d / %d    mspd = %d   ZD = %d   Z = %.3f   Pdis = %d  Jump = %s", t.dist, t.maxd, t.mspd, G.PPZF - pz, V.upz.z, t.pdis, t.jump)		--r.data.jpos1 = t.pos:copy()
							t.m:doJump{velocity = (t.vec * (t.dist/500) + V.upz) * 1000, applyFatigueCost = false}		t.jump = 0
							if t.hum then t.m:forceWeaponAttack{swing = 1} end
						end
					end 
				else t.jump = 0 end
			end
		else	-- если не в бою, то нельзя применять applyMagicSource с шаром даже если стартовать бой
			status = "NO COMBAT!"	R[r] = nil
			--[[
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
			--]]
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


local function DETERMINEACTION(e)	local s = e.session		if s.selectedAction ~= 0 then 	-- Эвент закомменчен!
	local m = s.mobile	local f = L.CFF[m.reference.baseObject.id]		if f then f(m) end
	--tes3.messageBox("DEA  %s  выбор = %s", s.mobile.reference, s.selectedAction)
	--tes3.messageBox("DEA  %s  SA = %s  Prior = %s", m.reference, s.selectedAction, s.selectionPriority)
end end		--if cf.full then event.register("determineAction", DETERMINEACTION) end


-- не решил = 0, Атака (1 мили, 2 рейндж, 3 кричер без оружия или рукопашка), AlchemyOrSummon = 6, бегство = 7, Спелл (касание 4, цель 5, на себя 8), UseEnchantedItem = 10		s:changeEquipment()
local function determinedAction(e) if cf.AIen then	local s = e.session		local m = s.mobile 	local t = R[m.reference]	if t then
--tes3.messageBox("DED  %s  SA = %s  Beh = %s  fl = %d  fg = %d  Prior = %s  W = %d %s  S = %d %s  %s", m.object.name, s.selectedAction,  m.actionData.aiBehaviorState, m.flee, m.fight, s.selectionPriority,
--m.readiedWeapon and m.readiedWeapon.object.type or -1, s.selectedWeapon and s.selectedWeapon.object.name, m.readiedShield and 1 or 0, s.selectedShield and "+S" or "", s.selectedSpell and s.selectedSpell.name)
	if s.selectedAction == 7 then
		if m.health.normalized > 0.1 and m.flee < t.lim then
			s.selectedAction = m.readiedWeapon and 1 or 3		--t.at or 1
			t.a.aiBehaviorState = 3
			if cf.m4 then tes3.messageBox("UPD NO FLEE!  %s", t.ob.name) end		-- дальнобойные враги (sa == 2 or sa == 5) вообще не убегают даже если фли выше 100
		end
	--elseif s.selectedAction == 1 then
	--	tes3.messageBox("%s  weap = %s", t.ob.name, s.selectedWeapon and s.selectedWeapon.object.name)
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
local KP = com and 0 or ((mp:getSkillValue(19) + mp.agility.current/2)*(P.snek1 and 1 or 0.5) + (P.luc10 and mp.luck.current/4 or 0) + (P.sec5 and mp:getSkillValue(18)/4 or 0)) * (snek and 0.5 or (P.snek10 and 0.2 or 0)) * (0.5 + G.STN/2)
local KD = com and 0 or (m:getSkillValue(18) + m.agility.current/4 + m.luck.current/4)
local Koef = com and 1 or math.max((100 + KD - KP)/100, 0.5)
local DistKF = math.max(1.5 - r.position:distance(pp)/(P.snek5 and 2000 or 3000), 0.5)
local VPow = com and 200 or math.max(200 - math.abs(m:getViewToActor(mp)) * (P.snek6 and 1.2 or 1), 0)
local Vis = math.max(VPow * Koef * DistKF - (mp.invisibility > 0 and (P.snek11 and 200 or 150) - m:getSkillValue(14)/2 or 0) - mp.chameleon - m.blind, 0)
local Aud = math.max((5 + mp.encumbrance.current/5 + mp:getBootsWeight()) * ((snek and 0 or 2) + (P.snek4 and 1 or 2)) * Koef * DistKF - (P.ill21 and mp.chameleon/2 or 0) - m.sound, 0)
local chance = Vis + Aud		local detected = chance > math.random(G.TR.tr3 and 20 or 100)		e.isDetected = detected		m.isPlayerDetected = detected		m.isPlayerHidden = not detected
if cf.m11 then tes3.messageBox("Det %s %d%%  Vis = %d%% (%d)  Aud = %d%%  DistKF = %.2f  Koef = %.2f (%d - %d)  %s", detected, chance, Vis, VPow, Aud, DistKF, Koef, KD, KP, r) end
end end		if cf.stels then event.register("detectSneak", DETECTSNEAK) end

local function ACTIVATE(e) local tr = e.target	local tob = tr.object.objectType		if e.activator == p then
	if tob == tes3.objectType.npc then	local m = tr.mobile
		if m.isKnockedOut then		--ref.object:hasItemEquipped(item[, itemData])
			if m.readiedWeapon then m:unequip{item = m.readiedWeapon.object} end		if m.readiedAmmo then m:unequip{item = m.readiedAmmo.object} end
			if cf.maniac and not T.Mania.timeLeft and mp.agility.current > 50 + m.agility.current * m.health.normalized then
				for _, s in pairs(tr.object.equipment) do m:unequip{item = s.object} end
				local cd = math.max((P.agi18 and 3 or 5) - mp.agility.current/100, 1)
				if cf.m then tes3.messageBox("Playful hands! CD = %.1f", cd) end
				T.Mania = timer.start{duration = cd, callback = function() end}
				timer.delayOneFrame(function() tr.object:reevaluateEquipment() end)
			end
		elseif mp.isSneaking and m.isPlayerDetected and not m.isDead then
			tes3.messageBox(eng and "You have been detected!" or "Вы обнаружены!")
			return false
		end
	elseif tob == tes3.objectType.apparatus and ic:isKeyDown(cf.ekey.keyCode) then	local app = {}
		for r in p.cell:iterateReferences(tes3.objectType.apparatus) do
			if (not app[r.object.type] or app[r.object.type].quality < r.object.quality) and tes3.hasOwnershipAccess{target = r} and pp:distance(r.position) < 800 then app[r.object.type] = r.object end
		end
		for i, ob in pairs(app) do tes3.addItem{reference = p, item = ob, playSound = false} end
		timer.delayOneFrame(function() local appar = app[0] or app[1] or app[2] or app[3]	if appar then
			mp:equip{item = appar}	timer.delayOneFrame(function() for i, ob in pairs(app) do tes3.removeItem{reference = p, item = ob, playSound = false} end end)
		end end)
		return false
	elseif tob == tes3.objectType.door and tr.destination then
		local list = eng and "You are haunted by: "	or "Вас преследуют: "	local count = 0
		for r, t in pairs(H) do
			if t.safe:valid() then
				if t.status == 1 then
					if AC[r.cell] and t.m.inCombat then
						if t.m.health.normalized < 0.5 or t.m.fatigue.current < 0 then t.status = 2
							if cf.m12 then tes3.messageBox(eng and "%s no longer wants to chase you" or "%s больше не хочет преследовать вас", r.object.name) end
						elseif pp:distance(r.position) > 5000 then t.status = 3
							if cf.m12 then tes3.messageBox(eng and "%s lost sight of you. Distance = %d" or "%s потерял вас из ивду. Дистанция = %d", r.object.name, pp:distance(r.position)) end
						end
					else t.status = 3		if cf.m12 then tes3.messageBox(eng and "%s lost sight of you!" or "%s потерял вас из виду!", r.object.name) end end
				elseif t.status == 3 then if AC[r.cell] and t.m.inCombat then t.status = 1		if cf.m12 then tes3.messageBox(eng and "%s see you again" or "%s снова видит вас", r.object.name) end end end
				if t.status < 2 then list = ("%s %s,"):format(list, r.object.name)	count = count + 1
					if t.status == 1 then t.tim = 1 + math.floor(pp:distance(r.position)/(200 + t.m.speed.current*3))
						local alt = t.m.actorType == 1 and t.m:getSkillValue(11) or 0		t.unl = alt > 50 and alt/2 or t.m.strength.current/10
					end
				end
			else H[r] = nil		tes3.messageBox("ref not valid (activate)") end
		end
		if cf.m12 and count ~= 0 then tes3.messageBox("%s  Total = %s/%s", list, count, table.size(H)) end
		if T.Dtim.timeLeft then T.Dtim:cancel() end		T.Dtim = timer.start{duration = 0.3, callback = function() end}
	end		-- if e.activator == p and wc.inputController:isKeyDown(cf.telkey.keyCode) and e.target ~= G.TETR then TELnew(e.target)	return false end
elseif tob == tes3.objectType.door then
	local StartZ = tr.startingOrientation.z
	if (math.abs(tr.facing - StartZ) * 180 / math.pi > 88) or tr:testActionFlag(256) or tr:testActionFlag(1024) then return false end		--Если дверь в данный момент полностью открыта ИЛИ открывается - отменить активацию
end end		event.register("activate", ACTIVATE)


local function COLLISION(e) local door = e.target
if door and door.object.objectType == tes3.objectType.door and not door.destination and not tes3.getLocked{reference = door} and not L.BadDoors[door.object.mesh:lower()] then
	local r = e.reference		local m = e.mobile
	if m.actorType and r ~= p then	local ts = tes3.getSimulationTimestamp()
		if G.DTS[r] ~= ts then G.DTS[r] = ts			local StartZ = door.startingOrientation.z		local dist
			if math.abs(door.facing - StartZ) * 180 / math.pi < 88 then		dist = cf.fixd
				if not (door:testActionFlag(256) or door:testActionFlag(1024)) then	local ob = r.object		--Если дверь в данный момент закрывается - активировать
					if m.actorType == 1 or (ob.biped or ob.type ~= 0 or ob.usesEquipment) then r:activate(door) end
				end
			else dist = cf.fixd2 end
			if dist > 0 then
				--	local vec = r.position - door.position		vec.z = 0		vec = vec:normalized()		r.position = r.position + r.forwardDirection * -80 + vec * 80
				local bb = door.object.boundingBox		local DX = (bb.max.x - bb.min.x) > (bb.max.y - bb.min.y)	local ang = m:getViewToPointWithFacing(StartZ, door.position)
				if cf.m12 then tes3.messageBox("%s nostack   dist = %d   TypeX = %s   ang = %d", r, dist, DX, ang) end
				Matr:toRotationZ(StartZ)		r.position = r.position + (DX and Matr:getForwardVector() * (math.abs(ang) > 90 and dist or -dist) or Matr:getRightVector() * (ang > 0 and -dist or dist) )
			end
		end
	end
end
end		event.register("collision", COLLISION)


local function PICKPOCKET(e)	local m = e.mobile	local r = e.reference	local ob = e.item	local ida = e.itemData	local num = e.count
	local val = ob and ob.value * num or 0		local wgt = ob and ob.weight * num or 0		local st = tes3.getSimulationTimestamp()
	local Alarm = r.data.PicPoc and math.max(r.data.PicPoc - math.floor((st - (r.data.PicPocST or 0))/24), 0) or 0		
	if Alarm == 0 then r.data.PicPoc = nil		r.data.PicPocST = nil end
	local gau = tes3.getEquippedItem{actor = p, objectType = tes3.objectType.armor, slot = 7}	gau = gau and math.min(gau.object.weight,10) * 5 or 0
	local StatP = math.min(mp:getSkillValue(19) + mp.agility.current/2 + mp.luck.current/4 + mp:getSkillValue(18)/4 - gau, 200) * (P.snek9 and 0.75 or 0.5)
	local StatT = m:getSkillValue(18)/2 + m.agility.current/4 + m.luck.current/4
	local chance = StatP - StatT - (ob and Alarm*20 or 0) - val/50 - wgt*2
	local success = chance > math.random(100)
	e.chance = success and 100 or 0
	if ob then
		r.data.PicPoc = Alarm + 1	r.data.PicPocST = st
		if success then mp:exerciseSkill(19, val/20) end
	end
	if cf.m11 then tes3.messageBox("Pickpocket  %s (%s)  Val %d  Chance %d%% = %d Player - %d Target - %d Alarm - %d Value - %d weight", ob, num, val, chance, StatP, StatT, (ob and Alarm*20 or 0), val/50, wgt*2) end
end		event.register("pickpocket", PICKPOCKET)


local function EQUIP(e)	if e.reference == p then local o = e.item		local ot = o.objectType
if (ot == tes3.objectType.alchemy or ot == tes3.objectType.ingredient) and o.weight > 0 then
	if ot == tes3.objectType.alchemy and M.drop.visible then local Btab = L.BotMod[o.mesh:lower()]	if Btab then	local ispoison = true
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
					D.poison = 50 + (mp.alchemy.base + mp.agility.base) * (P.alc6 and 0.25 or 0.15)		M.WPB.widget.current = D.poison		M.WPB.visible = true
					tes3.removeItem{reference = p, item = o}
					if cf.m5 then tes3.messageBox("%s %d", eng and "Poison is ready! Charges =" or "Яд готов! объем =", D.poison) end
				end end)
				return false
			end
		end
	end end

	if D.potmcd then
		tes3.messageBox(eng and "Not so fast! I need at least %d seconds to swallow what is already in my mouth!" or "Не так быстро! Мне надо еще хотя бы %d секунды чтобы проглотить то что уже у меня во рту!",	D.potmcd)
		return false
	elseif M.TOX.normalized > 1 then
		tes3.messageBox(eng and "Belly already bursting! I can't take o anymore... I have to wait at least %d seconds before I can swallow something else"
		or "Пузо уже по швам трещит! Больше не могу... Надо подождать хотя бы %d секунд прежде, чем я смогу заглотить что-то еще", D.potcd - M.TOX.max)
		return false
	end
	D.potmcd = math.max(10 - mp.speed.current/(P.spd5 and 10 or 20), P.spd5 and 2 or 3)		
	D.potcd = (D.potcd or 0) + math.max(40 - (P.alc9 and mp:getSkillValue(16)/10 or 0), 30)		M.TOX.current = D.potcd		M.TOX.fillColor = {1,0.25,0}		M.Bar5.visible = true
	if not T.POT.timeLeft then T.POT:reset() end
	
elseif ot == tes3.objectType.repairItem and not mp.inCombat then		G.anvil = nil
	for r in p.cell:iterateReferences(tes3.objectType.static) do if L.Anvil[r.object.id] and pp:distance(r.position) < 1000 then G.anvil = true	break end end
	local Qal = math.min(o.quality,2)	local Skill = math.min(mp:getSkillValue(1) + mp.agility.base/5 + mp.luck.base/10, 100)
	
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
elseif ot == tes3.objectType.weapon and o.weight > 0 and ic:isKeyDown(cf.gripkey.keyCode) and not W.AltWCD then
	if L.AltW[o.type] then	local New = L.NewGrip(o)	if New then		local ida = e.itemData
		if not ida or ida.condition > 0 then
			tes3.addItem{reference = tes3.player, item = New}
			if ida then local DAT = tes3.addItemData{to = p, item = New}	DAT.condition = ida.condition		DAT.charge = ida.charge end
			W.AltWCD = true		mp:equip{item = New}		timer.delayOneFrame(function() tes3.removeItem{reference = p, item = o, playSound = false}	W.AltWCD = nil end, timer.real)			return false
		end
	end end
elseif ot == tes3.objectType.clothing then
	if o.slot == 8 and o.enchantment and o.enchantment.castType == 3 then	local ricon = 0		local enc, eqob
		for _, s in pairs(p.object.equipment) do eqob = s.object		if eqob.objectType == tes3.objectType.clothing and eqob.slot == 8 then		enc = eqob.enchantment
			if enc and enc.castType == 3 then ricon = ricon + 1
				if ricon > 1 then mp:unequip{item = eqob}	break end
			end
		end end
	end
elseif ot == tes3.objectType.armor then
	if cf.beastarm then
		if o.slot == 5 or o.isClosedHelmet then
			if p.object.race.isBeast then p.object.race.isBeast = false			--tes3.messageBox("%s   beast equip", e.item.id)
				timer.delayOneFrame(function() p.object.race.isBeast = true end, timer.real)
			end
		end
	end
--	tes3.messageBox("%s   equip", e.item.id)
end
--else tes3.messageBox("%s   equip", e.item.id)
end end		event.register("equip", EQUIP)


-- Во время события equipped mp.readiedWeapon == нил! Надо ждать фрейм
local function EQUIPPED(e)		--tes3.messageBox("%s equipped    -- %s", e.item.name, e.reference)
if e.reference == p then	local o = e.item		--tes3.messageBox("%s equipped    RW = %s", o.name, mp.readiedWeapon and mp.readiedWeapon.object.name)
	if o.objectType == tes3.objectType.weapon then local wt = o.type	  local od = e.itemData		timer.delayOneFrame(L.GetWstat, timer.real)
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
		if cf.autoshield and not W.DWM and WT[wt].h1 and not mp.readiedShield then	local var
			for _, s in pairs(inv) do if s.object.objectType == tes3.objectType.armor and s.object.slot == 8 then	var = s.variables
				if not var or s.count > #var then mp:equip{item = s.object, selectBestCondition = true}	return
				else	for i, v in pairs(s.variables) do if v and v.condition > 0 then mp:equip{item = s.object, selectBestCondition = true}	return end end end
			end end
		end
	else
		if o.objectType == tes3.objectType.armor then L.GetArmT()		if o.slot == 8 then L.DWMOD(false) end
		elseif L.DWOBT[o.objectType] then L.DWMOD(false) end
	--	if o.enchantment and o.enchantment.castType == 3 then L.ConstEnLim() end
	end

--else tes3.messageBox("%s   equipped", e.item.id)
end end		event.register("equipped", EQUIPPED)


local function UNEQUIPPED(e) local r = e.reference 		local o = e.item		if r == p then
	if o.objectType == tes3.objectType.weapon then		L.GetWstat()
		if o == L.pbottle and not G.pbotswap then timer.delayOneFrame(function() local num = mwscript.getItemCount{reference = p, item = o} if num > 0 then
			tes3.removeItem{reference = p, item = o, count = num}		tes3.addItem{reference = p, item = D.poisonbid, count = num}	D.poisonbid = nil
			if cf.m5 then tes3.messageBox("%d bottles unequipped", num) end
		end end) end
	else
		if o.objectType == tes3.objectType.armor then L.GetArmT() end
	--	if o.enchantment and o.enchantment.castType == 3 then L.ConstEnLim() end
	end
elseif cf.npcgrip then	local ida = e.itemData
	if o.objectType == tes3.objectType.armor and o.slot == 8 and (not ida or ida.condition < 1) and r.tempData.hum then
		local w = e.mobile.readiedWeapon	w = w and w.object		local wt = w and w.type or -1
		if L.W1to2[wt] and w.weight > 0 then --e.mobile.weaponReady = false 
			e.mobile:unequip{item = w}		--tes3.messageBox("W unequipped")
		end		
	end
end end		event.register("unequipped", UNEQUIPPED)


local function WEAPONREADIED(e) local r = e.reference		if r == p then
	if W.DWM then if e.weaponStack then L.Cul(true) else L.DWMOD(false) end end
elseif cf.npcgrip then
	local m = r.mobile		local ws = e.weaponStack 		local o = ws and ws.object
	if not m.readiedShield and o and L.W1to2[o.type] and o.weight > 0 and not o.script and r.tempData.hum and o.reach > 0.71 then	local New = L.NewGrip(o)	if New then
		local ida = ws.itemData		local cond = ida.condition		local charge = ida.charge
		tes3.addItem{reference = r, item = New}		local DAT = tes3.addItemData{to = r, item = New}	DAT.condition = cond	DAT.charge = charge
		m:equip{item = New}		timer.delayOneFrame(function() tes3.removeItem{reference = r, item = o, playSound = false} end, timer.real)
	--	tes3.messageBox("cond = %s    new = %s     char = %s   new = %s", cond,  DAT.condition, charge, DAT.charge)
	end end
end end		event.register("weaponReadied", WEAPONREADIED)

local function WEAPONUNREADIED(e) if e.reference == p then	if W.DWM then L.Cul(false) end
end end		event.register("weaponUnreadied", WEAPONUNREADIED)


L.ARS = {["Light Armor Hit"] = 0, ["Medium Armor Hit"] = 1, ["Heavy Armor Hit"] = 2}
L.SND = {
["Hand To Hand Hit"] = {"Dmg0", "voldmg"},
["Hand to Hand Hit 2"] = {"Dmg0", "voldmg"},
["crossbowPull"] = {"CrossPull", "volsw"},
["crossbowShoot"] = {"CrossShoot", "volsw"},
["bowPull"] = {"BowPull", "volsw"},
["bowShoot"] = {"BowShoot", "volsw"},

["potion success"] = {"PotionSuccess", "volit"},
["Drink"] = {"PotionDrink", "volit"},
["Repair"] = {"RepairSuccess", "volit"},
["repair fail"] = {"RepairFail", "volit"},
["book page"] = {"Scrolls", "volit"},
["book page2"] = {"Scrolls", "volit"},
["scroll"] = {"Scrolls", "volit"},
["Item Ingredient Up"] = {"Ingredient", "volit"},	-- Для график гербализма
["Item Ammo Down"] = {"Ingredient", "volit"},		-- Для график гербализма
["Swallow"] = {"IngredientEat", "volit"},
--["potion fail"] = {"PotionFail", "volit"},
--["FootWaterLeft"] = {"WaterL", "volfoot"},
--["FootWaterRight"] = {"WaterR", "volfoot"},
--["Swim Left"] = {"WaterL", "volswim"},
--["Swim Right"] = {"WaterR", "volswim"},
--["DefaultLandWater"] = {"WaterJ", "volfoot"},
["SwishL"] = 0,
["SwishM"] = 0,
["SwishS"] = 0,
["miss"] = 0}
L.FOOTS = {
["FootBareLeft"] = "L",
["FootBareRight"] = "R",
["FootLightLeft"] = "L",
["FootLightRight"] = "R",
["FootMedLeft"] = "L",
["FootMedRight"] = "R",
["FootHeavyLeft"] = "L",
["FootHeavyRight"] = "R",
["FootWaterLeft"] = "L",
["FootWaterRight"] = "R",
["Swim Left"] = "L",
["Swim Right"] = "R",
["animalLARGEleft"] = "L",
["animalLARGEright"] = "R",
["animalSMALLleft"] = "L",
["animalSMALLright"] = "R",
["DefaultLand"] = "J",
["Body Fall Large"] = "J",
["DefaultLandWater"] = "J"
}
L.WATERSND = {["FootWaterLeft"] = "L", ["FootWaterRight"] = "R", ["Swim Left"] = "L", ["Swim Right"] = "R", ["DefaultLandWater"] = "J"}
L.DmgMat = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true}
L.DmgFist = {[-1] = true, [0] = true}

local function ADDSOUND(e)	local r = e.reference	local sid = e.sound		if r and sid then	sid = sid.id
	--mwse.log("%s  %s", sid, r)		tes3.messageBox("%s  %s   %s", sid, r, e.sound.filename)
	if L.FOOTS[sid] then	local m = r.mobile
		if m and (r == p or m.playerDistance < cf.npcfdist) then		local water = L.WATERSND[sid] and (L.FOOTS[sid] ~= "J" and m.isSwimming and 1 or 0)
			if cf[r == p and "volfarm" or "volfarmnpc"] > 0 and water ~= 1 then	local ob = r.object		local cui
				if ob.objectType == tes3.objectType.creature then
					local mt = L.CRNIF[ob.mesh:lower()]		cui = mt and mt.at
					if ob.type == tes3.creatureType.undead and ob.blood == 1 then tes3.playSound{reference = r, soundPath = L.RSound("Bones"), volume = cf["volfarmnpc"], pitch = math.random(90,110)/100} end
				else cui = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.armor, slot = 1}	if cui then cui = cui.object.weightClass end end
				if cui then tes3.playSound{reference = r, soundPath = L.RSound("Armor" .. cui), volume = cf[r == p and "volfarm" or "volfarmnpc"], pitch = math.random(90,110)/100} end
			end
			
			if water then
				tes3.playSound{reference = r, soundPath = L.RSound("Water" .. L.FOOTS[sid]), volume = water == 1 and cf.volswim or cf[r == p and "volfoot" or "volfootnpc"], pitch = math.random(90,110)/100}		e.block = true
			else
				local Mat		local hit = tes3.rayTest{position = r.position + V.up20, direction = V.down, maxDistance = 50, ignore = {r}}
				if hit then	local ref = hit.reference	local mob = ref and ref.mobile		if mob then Mat = ref.object.blood == 2 and "Metal" or "Dirt" else Mat = L.GetMat(hit) or "Dirt" end	end
				if r == p then
					if L.FOOTS[sid] ~= "J" and mp.isSliding then mp.isSliding = false
					--	tes3.messageBox("%s  %s  Jump = %s   Fall = %s   Collide = %s   VelZ = %.3f  Grav = %s  Slid = %s   CanJ = %s",
					--	L.FOOTS[sid], Mat, mp.isJumping, mp.isFalling, mp.collidingReference and true, mp.velocity.z, mp.isAffectedByGravity, mp.isSliding, mp.canJumpMidair)
					end
					
					if Mat then G.LastFloorMat = Mat else Mat = G.LastFloorMat end
				end
				tes3.playSound{reference = r, soundPath = L.RSound((Mat or "Dirt") .. L.FOOTS[sid]), volume = cf[r == p and "volfoot" or "volfootnpc"], pitch = math.random(90,110)/100}		e.block = true
			end
		end
	elseif L.ARS[sid] then		--tes3.messageBox("ArmSound  %s  dmg = %s", sid, G.DmgR[r])		-- При ударах в первую очередь срабатывает звук брони
		if not (G.ArSlot and L.DmgFist[G.DmgR[r]]) then
			local dir = (G.ArSlot and "DmgArmor" or "DmgShield") .. L.ARS[sid]
		--	tes3.playVoiceover{actor = r, voiceover = 4}
			tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = G.ArSlot and cf.volarm or cf.volimp, pitch = math.random(90,110)/100}
		end
		G.ArSlot = nil		e.block = true
	elseif sid == "Health Damage" then	local m = r.mobile		--tes3.messageBox("Health Dmg = %s", G.DmgR[r])		-- При ударах во вторую очередь срабатывает звук урона, и только потом стон от урона
		if m then	local ob = r.object 	local dir		local dmg = G.DmgR[r] or ""		G.DmgR[r] = nil
			if not L.DmgFist[dmg] and ob.objectType == tes3.objectType.creature then	local mt = L.CRNIF[ob.mesh:lower()]
				local at = mt and mt.at		if at then tes3.playSound{reference = r, soundPath = L.RSound("DmgArmor" .. at), volume = cf.volarm, pitch = math.random(90,110)/100} end
				if ob.type == tes3.creatureType.undead then
					if m.chameleon > 49 then dir = "DmgGhost"
					elseif ob.blood == 1 then dir = "DmgSkeleton" end
				elseif ob.blood == 2 then dir = "DmgDwemer"
				elseif mt then dir = mt.mat and L.DmgMat[dmg] and mt.mat .. dmg end
			end
			
			if dir then tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = cf.voldmg, pitch = math.random(90,110)/100}
			elseif dmg ~= -1 then dir = "Dmg" .. dmg		tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = cf.voldmg, pitch = math.random(90,110)/100} end
			e.block = true
			
		--	if dir then tes3.playSound{reference = r, soundPath = L.RSound(dir), volume = cf.voldmg, pitch = math.random(90,110)/100}		e.block = true
		--	else e.volume = 250 * cf.voldmg end
		end
	elseif sid == "Weapon Swish" then	local m = r.mobile
		if m then
			local wt = m.readiedWeapon		wt = wt and (m == mp and W.wt or wt.object.type) or -1	
			tes3.playSound{reference = r, soundPath = L.RSound(WT[wt].sws), volume = cf.volsw, pitch = math.random(90,110)/100}		e.block = true
		end
	elseif L.SND[sid] then		--tes3.messageBox("%s  %s", sid, r)
		if L.SND[sid] == 0 then e.block = true
		else tes3.playSound{reference = r, soundPath = L.RSound(L.SND[sid][1]), volume = cf[L.SND[sid][2]], pitch = math.random(90,110)/100}	e.block = true end
	--else mwse.log("%s  %s", sid, r)		tes3.messageBox("%s  %s", sid, r)
	end
end end		if cf.newsnd then event.register("addSound", ADDSOUND) end

L.ITYP = {
[tes3.objectType.weapon] = "Weapon",
[tes3.objectType.ammunition] = "Weapon",
[tes3.objectType.armor] = "Armor",
[tes3.objectType.clothing] = "Clothing",
[tes3.objectType.book] = "Book",
[tes3.objectType.ingredient] = "Ingredient",
[tes3.objectType.alchemy] = "Potion",
[tes3.objectType.probe] = "Lockpick",
[tes3.objectType.lockpick] = "Lockpick",
[tes3.objectType.repairItem] = "Repair",
[tes3.objectType.apparatus] = "Misc",
[tes3.objectType.light] = "Misc",
[tes3.objectType.miscItem] = "Misc"}
L.JevSlot = {[8] = "Ring", [9] = "Amulet"}

local function PLAYITEMSOUND(e)	local ob = e.item	local typ = L.ITNIF[ob.mesh:lower()] or L.ITYP[ob.objectType]		local dir
--	tes3.messageBox("%s   ref = %s   state = %s   ot = %s   type = %s", ob.id, e.reference, e.state, ob.objectType, ob.type)
	if typ == "Weapon" then			dir = WT[ob.type].isnd .. (e.state == 0 and "0" or "1")
	elseif typ == "Armor" then		dir = ("Armor%s"):format(ob.weightClass)
	elseif typ == "Clothing" then	dir = L.JevSlot[ob.slot] or "Clothing"
	elseif typ == "Book" then		if ob.type == 1 then dir = "Scrolls" else dir = "Book" .. (e.state == 0 and "0" or "1") end 
	elseif typ and e.state < 2 then	dir = typ end
	if dir then tes3.playSound{reference = e.reference or p, soundPath = L.RSound(dir), volume = cf.volit, pitch = math.random(90,110)/100}		e.block = true end
end		if cf.newsnd then event.register("playItemSound", PLAYITEMSOUND) end


local function ADDTEMPSOUND(e)	
	if e.isVoiceover and e.reference.mobile.isSpeaking then e.block = true end	--e.reference.mobile.animationController.animationData	--e.reference.tempData.anid.lipsyncLevel
	--tes3.messageBox("%s %s %s  cover = %s", e.reference, e.sound, e.path, e.isVoiceover)
end		event.register("addTempSound", ADDTEMPSOUND)

local function JOURNAL(e)
	tes3.playSound{reference = p, soundPath = L.RSound("Journal" .. (e.new and "New" or "Update")), volume = 1}
end		if cf.newsnd then event.register("journal", JOURNAL) end


local function MENUCONTENTS(e)	-- Если использовать uiActivated то даже через 1 фрейм звук произойдет в меню
	local m = e.menu:getPropertyObject("MenuContents_Actor")
	if m then local ob = m.object
		local dir = ob.blood == 2 and "ContDwemer" or "ContBody"
		tes3.playSound{reference = p, soundPath = L.RSound(dir .. "1"), volume = 1}
		timer.delayOneFrame(function() tes3.playSound{reference = p, soundPath = L.RSound(dir .. "2"), volume = cf.volcont} end)
	end
end		if cf.newsnd then event.register("menuEnter", MENUCONTENTS, {filter = "MenuContents"}) end



local function ITEMDROPPED(e) local r = e.reference
	if r.object == L.pbottle then local num = r.stackSize		tes3.addItem{reference = p, item = D.poisonbid, count = num}		r:delete()	
		tes3.messageBox("%d %s", num, eng and "old bottles unequipped" or "старых бутылок снято")	
	elseif L.BlackItem[r.object.id] then r:delete()		tes3.messageBox("Item unbound")
	elseif ic:isKeyDown(cf.telkey.keyCode) then TELnew(r) end	-- ic:isKeyDown(cf.telkey.keyCode)
end		event.register("itemDropped", ITEMDROPPED)

local function FILTERINVENTORY(e) if L.BlackItem[e.item.id] and M.Stat and M.Stat.visible == false then e.filter = false end end		event.register("filterInventory", FILTERINVENTORY, {priority = -1000})
--local function filterContentsMenu(e) e.filter = true end		event.register("filterContentsMenu", filterContentsMenu, {priority = -1000})

L.LiveOT = {[tes3.objectType.creature] = true, [tes3.objectType.npc] = true}
L.RWList = {["4nm_weapon_adamantium"] = true, ["4nm_weapon_daedric_obl"] = true, ["4nm_weapon_daedric_sky"] = true, ["4nm_weapon_dwarven_obl"] = true, ["4nm_weapon_dwarven_sky"] = true,
["4nm_weapon_ebony_obl"] = true, ["4nm_weapon_ebony_sky"] = true, ["4nm_weapon_elven_obl"] = true, ["4nm_weapon_elven_sky"] = true, ["4nm_weapon_glass_obl"] = true, ["4nm_weapon_glass_sky"] = true, 
["4nm_weapon_ice"] = true, ["4nm_weapon_obsidian"] = true, ["4nm_weapon_nordic_sky"] = true, ["4nm_weapon_orcish_sky"] = true, ["4nm_weapon_amber"] = true,
["random ebony weapon"] = true, ["random_daedric_weapon"] = true, ["random_dwemer_weapon"] = true, ["random_glass_weapon"] = true, ["random_imp_weapon"] = true, ["random ashlander weapon"] = true,
["random_iron_weapon"] = true, ["random_nordic_weapons"] = true, ["random_orcish_weapons"] = true, ["random_silver_weapon"] = true, ["random_steel_weapon"] = true}
L.PickLL = function(list)	local node = list.list[math.random(list.count)]
	if node then local new = node.object
		if new.value then return new else return L.PickLL(new) end		-- цена есть только у вещей, иначе это другой левел лист
	else return end
end

local function LEVELEDITEMPICKED(e) local r = e.spawner		if r then	local list = e.list		local rob = r.object	
	if not tes3ui.menuMode() and rob.objectType == tes3.objectType.container and not rob.organic then
		if not r.modified or G.CurConT then	local ob = e.pick
			if not G.CurConT then G.CurConT = timer.delayOneFrame(function() r.modified = true	G.CurConT = nil		--tes3.messageBox("timer expired")
			end, timer.real) end
			
			L.sksec = 1		if ob then mp:exerciseSkill(18, ob.value/1000) end			--ob.value может быть нил! повреждение памяти??
			local chance = mp.luck.base * (P.luc17 and 0.5 or 0.2) + mp:getSkillValue(18) * (P.sec8 and 0.5 or 0.2)		local New
			if chance > math.random(100) then
				New = L.PickLL(list)		if New then tes3.addItem{reference = r, item = New}		mp:exerciseSkill(18, New.value/1000) end
			end
			
			--tes3.messageBox("%s (%s)   %s (%s)      modr = %s   New = %s (%d)", list, list.count, ob, ob and ob.value, r.modified, New, chance)
		end
	end
	
	
	if L.RWList[list.id] then		local ob = e.pick
		if ob and ob.objectType == tes3.objectType.weapon and ob.type == 0 and L.LiveOT[rob.objectType] then 	local New	--local num = #list.list
			for i = 1, 3 do New = list.list[math.random(list.count)].object		if New.type ~= 0 then break else New = nil end		end
			if New then G.DopW[rob.id] = New
				--tes3.messageBox("%s    %s    %s      new = %s", list, ob, r.id, New)
			end
		end
	end
end end		event.register("leveledItemPicked", LEVELEDITEMPICKED)


local function SPELLCREATED(e) local s = e.spell	local del, rt
	for i, ef in ipairs(s.effects) do if ef.id ~= -1 and ef.rangeType ~= 1 then if rt then if ef.rangeType ~= rt then del = true	break end else rt = ef.rangeType end end end
	if del then	timer.delayOneFrame(function() tes3.removeSpell{reference = p, spell = s}	timer.delayOneFrame(function() tes3.deleteObject(s) 	tes3.messageBox("Anti-exploit! Spell deleted!") end) end) end
end		if cf.aspell then event.register("spellCreated", SPELLCREATED, {filter = "service"}) end

L.METAR = {[500] = true, [521] = true, [522] = true, [523] = true, [524] = true, [525] = true, [526] = true, [527] = true, [528] = true, [529] = true, [530] = true,
[551] = true, [552] = true, [553] = true, [554] = true, [555] = true, [566] = true, [567] = true, [568] = true, [569] = true, [570] = true, [617] = true, [618] = true, [619] = true, [620] = true}
L.MERAD = {[500] = 1, [611] = 1, [612] = 1, [613] = 1, [620] = 1, [85] = 1, [86] = 1, [87] = 1, [88] = 1, [89] = 1}
L.MEDUR = {[76] = 1000000, [2] = 10, [9] = 5, [11] = 10, [40] = 10, [58] = 10, [64] = 10, [65] = 10, [66] = 10, [501] = 10, [502] = 10, [503] = 10, [509] = 10,
[17] = 10, [18] = 10, [19] = 10, [20] = 10, [21] = 10, [28] = 10, [29] = 10, [30] = 10, [31] = 10, [32] = 10, [33] = 10, [34] = 10, [35] = 10, [36] = 10,
[49] = 10, [50] = 10, [51] = 10, [52] = 10, [53] = 10, [54] = 10, [55] = 10, [56] = 10, [101] = 10, [118] = 10, [119] = 10, [44] = 10,
[79] = 10, [80] = 10, [81] = 10, [82] = 10, [83] = 10, [84] = 10, [117] = 10, [42] = 10, [85] = 10, [89] = 10,
[90] = 10, [91] = 10, [92] = 10, [93] = 10, [94] = 10, [95] = 10, [96] = 10, [97] = 10, [98] = 10, [99] = 10, [67] = 5, [68] = 5,
[102] = 20, [103] = 20, [104] = 20, [105] = 20, [106] = 20, [107] = 20, [108] = 20, [109] = 20, [110] = 20, [111] = 20, [112] = 20, [113] = 20, [114] = 20, [115] = 20, [116] = 20,
[134] = 20, [137] = 20, [138] = 20, [139] = 20, [140] = 20, [141] = 20, [142] = 20}
local function MENUSETVALUES(e) if cf.splim then local el = e.element	local eid = el:getPropertyObject("MenuSetValues_Effect").id
	el:findChild("MenuSetValues_OkButton"):registerBefore("mouseClick", function()
		if L.MEDUR[eid] then	local DurSl = el:findChild("MenuSetValues_DurationSlider")		local min = L.MEDUR[eid] * (P.int10 and 1 or 2)
			if DurSl and DurSl.widget.current < min then tes3.messageBox("Minimum duration = %s", min) return false end
		end
		if L.METAR[eid] and el:findChild("MenuSetValues_Range").children[1].text ~= tes3.findGMST("sRangeTarget").value then tes3.messageBox("Only target") return false end
		if L.MERAD[eid] and el:findChild("MenuSetValues_AreaSlider").widget.current > 1 then tes3.messageBox("Maximum area = 1") return false end
	end)
end end		event.register("uiActivated", MENUSETVALUES, {filter = "MenuSetValues"})

--[[
local function ENEVENT(e) if e.property == tes3.uiProperty.mouseClick then		--tes3.messageBox("Эвент id = %s   top = %s", e.block.id, tes3ui.getMenuOnTop().id)
	local MENCH = tes3ui.findMenu("MenuEnchantment")
	if MENCH then G.GMSTEnConDur.value = math.max((P and 30000 or 40000)/math.max(MENCH:findChild("MenuEnchantment_soulcharge").text,200),100) end

--	if e.block.id == -267 or e.block.id == -268 then	-- кнопки создать и отменить
--		if tes3ui.getMenuOnTop().id ~= -264 then event.unregister("uiEvent", ENEVENT) end
--	else	local MENCH = tes3ui.findMenu("MenuEnchantment")
--		if MENCH then G.GMSTEnConDur.value = math.max((P and 30000 or 40000)/math.max(MENCH:findChild(-296).text,200),100) end
--	end
end end
--]]

local function MENUENCHANTMENT(e) local El = e.element	 local Serv = tes3ui.getServiceActor()		--tes3.messageBox("MENUENCHANTMENT CREATED")
	--event.register("uiEvent", ENEVENT)	El:register("destroy", function() event.unregister("uiEvent", ENEVENT) end)
	if cf.spmak then
		El.minWidth = 1200	El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
		El:findChild("MenuEnchantment_magicEffectsContainer").width = 32*(vol+1)
		EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
		for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
		s:createImage{path = "icons\\" .. s:getPropertyObject("MenuEnchantment_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
	end
	if not Serv then	local skmin = math.min(100 - mp:getSkillValue(9), 50)
		local SK = {[10] = mp.destruction.base, [11] = mp.alteration.base, [12] = mp.illusion.base, [13] = mp.conjuration.base, [14] = mp.mysticism.base, [15] = mp.restoration.base}
		for i, s in ipairs(El:findChild("PartScrollPane_pane").children) do if SK[s:getPropertyObject("MenuEnchantment_Effect").skill] < skmin then s.visible = false end end
	end
	El:findChild("MenuEnchantment_Buybutton"):registerBefore("mouseClick", function()
		local soul = math.min(El:findChild("MenuEnchantment_soulcharge").text,500)		local power = tonumber(El:findChild("MenuEnchantment_currentcharge").text)
		if El:findChild("MenuEnchantment_casttype").children[1].text == tes3.findGMST("sItemCastConstant").value then
			soul = soul / (P.enc13 and not Serv and 4 or 5)
			if power > soul then tes3.messageBox("Maximum constant enchant power = %d", soul)	return false end
		else
			soul = soul / (P.enc19 and not Serv and 10 or 12.5)
			if power > soul then	tes3.messageBox("Maximum enchant power = %d", soul)		return false end
		end
	end)
end		event.register("uiActivated", MENUENCHANTMENT, {filter = "MenuEnchantment"})

local function MENUSPELLMAKING(e)	local El = e.element
if cf.spmak then El.minWidth = 1200		El.minHeight = 800		local vol = 15	local EL = El:findChild("PartScrollPane_pane")	local lin = math.ceil(#EL.children/vol)
	El:findChild("MenuSpellmaking_EffectsLayout").width = 32*(vol+1)
	EL.minWidth = 32*(vol+1)	EL.maxWidth = EL.minWidth	EL.minHeight = 32*(lin+1)	EL.maxHeight = EL.minHeight		EL.autoHeight = true	EL.autoWidth = true
	for i, s in ipairs(EL.children) do s.minHeight = 32		s.minWidth = 32		s.autoHeight = true		s.autoWidth = true	s.text = nil
	s:createImage{path = "icons\\" .. s:getPropertyObject("MenuSpellmaking_Effect").bigIcon}	s.absolutePosAlignX = 1/vol * ((i%vol > 0 and i%vol or vol)-1)		s.absolutePosAlignY = 1/lin * (math.ceil(i/vol)-1) end
end
if not tes3ui.getServiceActor() then
	El:findChild("MenuSpellmaking_Buybutton"):registerBefore("mouseClick", function() local cost = El:findChild("MenuSpellmaking_SpellPointCost").text		if PMP.current < cost*5 then
		tes3.messageBox("%s %d", eng and "You don't have enough mana to create this spell. Need: " or "У вас не хватает маны на создание этого заклинания. Нужно: ", cost*5)		return false
	else Mod(cost*5) end end)
	local SK = {[10] = mp.destruction.base, [11] = mp.alteration.base, [12] = mp.illusion.base, [13] = mp.conjuration.base, [14] = mp.mysticism.base, [15] = mp.restoration.base}
	for i, s in ipairs(El:findChild("PartScrollPane_pane").children) do if SK[s:getPropertyObject("MenuSpellmaking_Effect").skill] < 80 then s.visible = false end end
end
end		event.register("uiActivated", MENUSPELLMAKING, {filter = "MenuSpellmaking"})

local function ENCHANTEDITEMCREATED(e)	local ob = e.object		local en = ob.enchantment	local soulpow = e.soul.soul
	ob.value = e.baseObject.value * (1 + soulpow/500)		ob.modified = true
	if en.castType ~= 3 then
		local m = e.enchanterReference.mobile		local sk = math.min(m.enchant.base,100)
		en.maxCharge = math.ceil(soulpow * (0.2 + sk * (m == mp and P.enc23 and 0.003 or 0.002)) )
		for i, ef in ipairs(en.effects) do if ef.id == 76 then ef.min = 0	ef.max = 0 end end
		en.modified = true
	end
--	tes3.messageBox("Item: %s  Base: %s   Soul %s    Enchanter: %s   Ma", e.object, e.baseObject, soulpow, e.enchanterReference)
end		event.register("enchantedItemCreated", ENCHANTEDITEMCREATED)

L.ALF={[1]={75,76,77,74,79,80,84,82,117,72,73,69,70,90,91,92,93,97,99,94}, [2]={10,8,1,2,0,43,39,57,67,68,59,64,65,66}, [3]={27,23,24,25,22,18,19,20,17,35,28,29,30,31,7,45,47}, [4]={}}	L.ALFEF = {[17]=0, [22]=0, [74]=0, [79]=0, [85]=0}
L.ALE = {[75]={5,20}, [76]={5,20}, [77]={20,50}, [74]={5,10}, [79]={30,100}, [83]={30,100}, [80]={30,100}, [81]={50,100}, [82]={150,100}, [84]={10,100}, [117]={30,100}, [42]={30,100}, [72]={1,1}, [73]={1,1}, [69]={1,1}, [70]={1,1},
[90]={30,100}, [91]={30,100}, [92]={30,100}, [93]={30,100}, [97]={30,100}, [99]={30,100}, [98]={10,100}, [94]={100,300}, [95]={100,300}, [96]={100,100},
[10]={10,20}, [8]={150,100}, [3]={30,100}, [4]={10,20}, [5]={10,20}, [6]={10,20}, [1]={30,100}, [2]={1,100}, [0]={1,100}, [9]={30,50}, [11]={30,50},
[41]={30,300}, [43]={30,300}, [39]={1,50}, [40]={30,50}, [57]={100,1}, [67]={10,20}, [68]={10,20}, [59]={30,100}, [64]={200,100}, [65]={200,100}, [66]={200,100},
[27]={5,20}, [23]={5,20}, [14]={5,20}, [15]={5,20}, [16]={5,20}, [24]={20,20}, [25]={20,20}, [22]={5,10},
[17]={50,100}, [18]={50,100}, [19]={200,100}, [20]={200,100}, [21]={30,100},
[28]={30,100}, [29]={30,100}, [30]={30,100}, [31]={30,100}, [34]={30,100}, [35]={30,100}, [36]={30,100}, [32]={50,100}, [33]={50,100}, [7]={150,100}, [45]={1,5}, [46]={1,10}, [47]={50,50}, [48]={50,50}}

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
if cf.alc then	local E = {}	local norm = not M.drop.visible		local gold = 20
	local num = ob:getActiveEffectCount()	if num == 2 then num = 0.75 elseif num == 3 then num = 0.6 elseif num > 3 then num = 0.5 end		if num < 1 and not P.alc23 then num = num - 0.1 end
	for i, ef in ipairs(ob.effects) do E[i] = ef	if ef.id ~= -1 then local AE = L.ALE[ef.id]		local harm = norm == ef.object.isHarmful		gold = gold + (harm and -10 or 10)
	if AE then E[i].min = math.max(G.PotM * AE[1]/(harm and (1 + Alem*2) or 1), 1)		E[i].max = E[i].min		E[i].duration = math.max(G.PotD * num * AE[2]/(harm and (1 + Alem) or 1), 1) end end end
	tes3.removeItem{reference = p, item = ob, playSound = false}
	tes3.addItem{reference = p, item = tes3alchemy.create({name = ob.name, mesh = ob.mesh, icon = ob.icon, weight = P.alc20 and 0.5 or 1, value = math.max(G.PotM * G.PotD * gold * (P.alc8 and 1 or 0.5), 1), effects = E}),
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


--[[
local function MENUQUICK(e)	local Q = {}	Q.bl = e.element:createThinBorder{}		Q.bl.autoHeight = true	Q.bl.autoWidth = true
local CS = mp.currentSpell		CS = CS and CS.objectType == tes3.objectType.spell and CS.castType == 0 and (CS.alwaysSucceeds ) and CS or nil
for i = 1, 10 do	local s = D.QSP[tostring(i)] and tes3.getObject(D.QSP[tostring(i)])		Q[i] = Q.bl:createImage{path = s and "icons\\" .. s.effects[1].object.bigIcon or "icons/k/magicka.dds"}
	if i == 10 then Q[i]:register("mouseClick", function() D.QSP["0"] = nil		tes3.messageBox("Universal extra-cast slot") end)
	else
		Q[i]:register("mouseClick", function()
			if CS and ic:isShiftDown() then D.QSP[tostring(i)] = CS.id		tes3.messageBox("%s remembered for %s extra-cast slot", CS.name, i) end
			if s then
				D.QSP["0"] = tostring(i)		QS = tes3.getObject(D.QSP[])		M.S2IC.contentPath = "icons\\" .. QS.effects[1].object.bigIcon
				tes3.messageBox("%s prepared for extra-cast  Slot %s  %s", QS.name, D.QSP["0"], QS.alwaysSucceeds and "Is a technique" or "")
			end
		end)
	end
	Q[i]:register("help", function() tes3ui.createTooltipMenu():createLabel{text = s and ("Extra-cast slot %s  -  %s    Cost = %s    %s"):format(i, s.name, s.magickaCost, s.alwaysSucceeds and "Is a technique" or "") or
	("Extra-cast slot %s  -  %s %s"):format(i, i == 10 and "Universal" or "Press LMB with Shift to place the current spell in this slot.",  and "" or "Without a special perk only techniques are available")} end)
end	e.element:updateLayout() end		--event.register("uiActivated", MENUQUICK, {filter = "MenuQuick"})
--]]


local function UISPELLTOOLTIP(e) local tt = e.tooltip:findChild(tes3ui.registerID("helptext"))	tt.text = ("%s (%d)"):format(tt.text, e.spell.magickaCost)
end		event.register("uiSpellTooltip", UISPELLTOOLTIP)


local function BARTEROFFER(e)	local m = e.mobile	local k = 0		local C		--#e.selling	#e.buying	tile.item, tile.count		Эвент не срабатывает если игрок не изменил цену первого предложения!
if e.value > 0 then k = e.offer/e.value - 1 else k = e.value/e.offer - 1 end
if k > 0 then	local k0 = 0.1 + (((e.value > 0 and P.merc12) or (e.value < 0 and P.merc11)) and 0.1 or 0) + (P.per11 and math.min(mp.personality.current,100)/2000 or 0)		local disp = m.object.disposition or 50
	if k <= k0 then C = 50*((P.merc4 and 1.1 or 1) - k/k0) * math.min(disp, P.per13 and 150 or 100)/100
		* (20 + mp.mercantile.current + mp.speechcraft.current/(P.spec10 and 2.5 or 5) + (P.per12 and math.min(mp.personality.current,100)/5 or 0) + (P.luc5 and math.min(mp.luck.current,100)/5 or 0))/(m:getSkillValue(24)+50)
	else C = 0 end
	M.Bart2.text = ("  %d%%/%d  %d%%/%d%%"):format(C, disp, k*100, k0*100)
	if cf.m6 then tes3.messageBox("Chance = %d  Koef = %.1f%%  Max = %.1f%%  Gold = %d (%d - %d) Merc = %d  Disp = %d", C, k*100, k0*100, e.offer - e.value, e.offer, e.value, m:getSkillValue(24), disp) end
	e.success = math.random(100) < C		if e.success then mp:exerciseSkill(24, math.abs(e.value)/500 + (e.offer - e.value)/20) end
end
end

local function BarterK(m) local ob = m.object	local rang = ob.faction and ob.faction.playerRank + 1 or 0		return rang,
(mp.mercantile.current + mp.speechcraft.current/(P.spec3 and 5 or 10) + mp.personality.current/(P.per3 and 5 or 10) + (P.luc5 and mp.luck.current/10 or 0) + rang*(P.spec5 and 10 or 5) + (P.per8 and p.object.reputation/2 or 0))/200,
(m:getSkillValue(24) + m:getSkillValue(25)/5 + m.personality.current/5 + m.luck.current/10 + 150 - math.min(ob.disposition or 50, P.per13 and 150 or 100) - (P.per14 and ob.female == not p.object.female and 30 or 0))/200
end
local function CALCBARTERPRICE(e)	local rang, k1, k2 = BarterK(e.mobile)		--if e.item.id == "Gold_001" then e.price = e.count		buying (игрок покупает)
	local k0 = 1 + (e.buying and (P.merc10 and 0.5 or 0.7) or (P.merc2 and 0.8 or 1))		local koef = math.max(k0 - k1 + k2, 1.25)		local val	local ob, ida = e.item, e.itemData
	if ob.isSoulGem and ida and ida.soul then	local soulval = ida.soul.soul	val = (soulval ^ 3) / 10000 + soulval * 2
	elseif ida and ida.condition and ob.maxCondition then val = ob.value * (0.5 + ida.condition * 0.5 / ob.maxCondition)
	else val = ob.value end
	local bp = math.max(e.buying and math.ceil(val * koef) or math.floor(val / koef), 1)			e.price = bp * e.count
	local MBART = tes3ui.findMenu("MenuBarter")		if MBART and MBART.visible then M.Bart1.text = (" %d%%"):format(e.buying and koef*100 or 100/koef) end
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
		M.Invest:register("mouseClick", function() if DI.i < max and tes3.getPlayerGold() >= gold then DI.i = DI.i + 1		bob.barterGold = DI.g * math.min(1 + DI.i * 0.1, 2)		mp:exerciseSkill(24, gold/20)
			tes3.removeItem{reference = p, item = "gold_001", count = gold}		M.InvestW.current = DI.i	M.Invest:updateLayout()
			tes3.messageBox("Invested in %s   Gold = %s / %s  Investments: %s / %s", bob.id, m.barterGold, bob.barterGold, DI.i, max)
			if aisave then timer.delayOneFrame(function() bob.modified = true end) else bob.modified = true end
		end end)
	end
	M.Bart = e.element:findChild("MenuBarter_Price").parent
	M.Bart1 = M.Bart:createLabel{text = " 0%"}	M.Bart1:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Offer from base price" or "Предложение от базовой цены"} end)
	M.Bart2 = M.Bart:createLabel{text = " "}	M.Bart2:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Chance for a deal / Merchant's disposition     Your Profit / Max profit" or
	"Шанс на сделку / Отношение торговца     Ваша выгода / Максимальная выгода"} end)
	M.Bart:reorderChildren(2, 3, 2)
	if M.INV then L.GetArStat() end
--	for _, stack in pairs(m.object.baseObject.inventory) do mwse.log("base  %s - %s", stack.count, stack.object.id) end
--	for _, stack in pairs(m.object.inventory) do mwse.log("%s - %s", stack.count, stack.object.id) end
	--timer.delayOneFrame(function() m.health.current = 0		TFR(2, function() tes3.runLegacyScript{command = "resurrect", reference = m.reference} end) end, timer.real)
end		event.register("uiActivated", MENUBARTER, {filter = "MenuBarter"})

local function MENUPERSUASION(e)	local m = tes3ui.getServiceActor()		if PST.normalized > 1 then PST.current = PST.base end
if mp.intelligence.current + mp.speechcraft.current + (P.spec1 and 100 or 0) > 150 then
	local fPersMod, fLuckMod, fRepMod, fFatigueBase, fFatigueMult, fLevelMod = tes3.findGMST(1150).value, tes3.findGMST(1151).value, tes3.findGMST(1152).value, tes3.findGMST(1006).value, tes3.findGMST(1007).value, tes3.findGMST(1153).value
	local pLucPers = mp.personality.current/fPersMod + mp.luck.current/fLuckMod		local d = 1 - math.abs(math.min(m.object.disposition,100) - 50)/50
	local npcRepLucPers = m.personality.current/fPersMod + m.luck.current/fLuckMod + m.object.reputation * fRepMod
	local pFat = fFatigueBase - fFatigueMult * (1 - G.STN)			local npcFat = fFatigueBase - fFatigueMult * (1 - m.fatigue.normalized)
	local RAT = 50 + (p.object.reputation * fRepMod + pLucPers + mp.speechcraft.current) * pFat - (npcRepLucPers + m.speechcraft.current) * npcFat
	local T = {}	T[1] = d * RAT		T[3] = T[1]		T[2] = d * (RAT + p.object.level * fLevelMod - m.object.level * fLevelMod * npcFat)
	local brib = d * (((pLucPers + mp.mercantile.current) * pFat) - ((npcRepLucPers + m.mercantile.current) * npcFat) + 50)
	T[4], T[5], T[6] = brib + tes3.findGMST(1154).value, brib + tes3.findGMST(1155).value, brib + tes3.findGMST(1156).value			for i=1,6 do T[i] = math.max(tes3.findGMST(1159).value, T[i]) end
	for i, b in ipairs(e.element:findChild(-633).children) do if i < 7 then local t = b.children[1]		t.text = ("%s:  %d%%"):format(t.text, T[i]) end end		e.element:updateLayout()
end
end		event.register("uiActivated", MENUPERSUASION, {filter = "MenuPersuasion"})

--local function MENUDIALOG(e)	local r	= tes3ui.getServiceActor().reference	local id = r.baseObject.id		-- закомменчен
--end		event.register("uiActivated", MENUDIALOG, {filter = "MenuDialog"})


local function MENUSERVICESPELLS(e)	local list = e.element:findChild("PartScrollPane_pane")
	for _, el in ipairs(list.children) do	local spell = el:getPropertyObject("MenuServiceSpells_Spell")		
		if spell then
			local esp = spell.sourceMod		esp = esp and esp:lower()
			if esp then		if esp ~= "4nm.esp" and not spell.autoCalc or string.startswith(spell.name, "*") or L.NOSP[spell.id] then
				el.visible = false
			end end
			--tes3.messageBox("%s     %s     source = %s   auto = %s", spell.id, spell.name, esp, spell.autoCalc)
		end
	end
end		if cf.spellmerc then event.register("uiActivated", MENUSERVICESPELLS, {priority = -100, filter = "MenuServiceSpells"}) end


local function LOCKPICK(e)	local lock = e.lockData.level		local qual = e.tool.quality		-- 1, 1.25, 1.5, 1.75, 2
	L.sksec = lock/5
	e.chance = (mp.security.current/5 + mp.agility.current/5 + mp.luck.current/10) * (P.sec1 and 2 or 1) * qual * G.STN - lock
	if cf.m then tes3.messageBox("Chance = %d%%", e.chance) end
end		event.register("lockPick", LOCKPICK)

local function TRAPDISARM(e) local trap = e.lockData	trap = trap and e.lockData.trap		if trap then trap = math.min(trap.magickaCost,100)		local qual = e.tool.quality		-- 0.5, 1, 1.25, 1.5, 1.75, 2
	L.sksec = trap/5
	e.chance = (mp.security.current/5 + mp.agility.current/5 + mp.luck.current/10) * (P.sec2 and 2 or 1) * qual * G.STN - trap
	if cf.m then tes3.messageBox("Chance = %d%%", e.chance) end
end end		event.register("trapDisarm", TRAPDISARM)


local function REPAIR(e) local ob = e.item		local val = math.min(ob.value,10000)^0.5 * (P.arm15 and 0.5 or 1)		local en = ob.enchantment		--local ida = e.itemData		
	local sk = math.min(mp.armorer.current,100)			-- 0.5, 1, 1.25, 1.5, 1.75, 2			--	e.repairAmount имеет минимальное значение 1
	local perk		if ob.objectType == tes3.objectType.weapon then perk = P.arm13 else perk = P.arm14 end
	local koef = ((perk and 2 or 1) + (not en and P.arm11 and 1 or 0)) * (G.anvil and (P.arm7 and 2 or 1.5) or 1) * e.tool.quality		--	(perk and 2 or 1) + (not en and P.arm11 and 1 or 0) + (G.anvil and 1 or 0)
	e.repairAmount = math.random((sk + math.min(ob.maxCondition,2000)*(P.arm20 and 0.05 or 0.025)) * koef)
	
	L.sksmit = e.repairAmount/50 * (50 + val)/100
	local chance = ((sk*0.4 + mp.agility.base/5 + mp.strength.base/5 + mp.luck.base/5) * ((P.arm1 and 1.5 or 1) + (G.anvil and (P.arm7 and 0.5 or 0.25) or 0)) - val) * (en and not P.arm16 and 0.5 or 1)
	e.chance = chance
	if chance < 1 then tes3.findGMST("sRepairFailed").value = eng and "There is no chance that I can repair this item" or "Нет никаких шансов что я смогу починить этот предмет"
	elseif chance < 10 then tes3.findGMST("sRepairFailed").value = eng and "It is unlikely that I will be able to repair this item" or "Маловероятно что я смогу починить этот предмет"
	else tes3.findGMST("sRepairFailed").value = "" end
	if cf.m then tes3.messageBox("Chance = %d%% (-%d%% value)   Repair = %d  (%s%%)", chance, val, e.repairAmount, koef*100) end
end		event.register("repair", REPAIR)



L.SKG = {[0]=1, [2]=1, [3]=1, [4]=1, [5]=1, [6]=1, [7]=1, [8]=1, [17]=1, [18]=1, [19]=1, [20]=1, [21]=1, [22]=1, [23]=1, [26]=1, [9]=2, [10]=2, [11]=2, [12]=2, [13]=2, [14]=2, [15]=2, [1]=3, [16]=3, [24]=4, [25]=4}
L.SKFC = {{0, 1, 0}, {0, 1, 1}, {1, 0, 1}, {1, 1, 0}}			L.SKF = {20, 40, 100, 100}
local function EXERCISESKILL(e) local sk = e.skill
	if G.SkBurn[sk] then e.progress = 0 end

	if sk == 8 then	e.progress = e.progress * math.min(1 + G.ENC,2) else		-- Атлетика
		local gr = L.SKG[sk]	local fatk = math.max(100 - D.ExpFat[gr]/30, 0)
		if L.SK[sk] then
			if sk == 5 then if W.wt == -2 then e.progress = 0	mp:exerciseSkill(7, 1)	return end end		-- Копья в 1 руке
			e.progress = e.progress * L[L.SK[sk]] * fatk/100
		else e.progress = e.progress * fatk/100 end
		if cf.fatbar then if fatk < 100 then M.FatBar.visible = true		M.FatBarW.current = fatk		M.FatBarW.fillColor = L.SKFC[gr] 	M.FatBar:updateLayout() else M.FatBar.visible = false end end
		if cf.m7 then tes3.messageBox("%s exp = %.2f   fatigue koef = %d%% (%d minutes)", tes3.skillName[sk], e.progress, fatk, D.ExpFat[gr]/60) end
	end
end		if cf.trmod then event.register("exerciseSkill", EXERCISESKILL, {priority = -10}) end

local function SKILLRAISED(e)	local sk = e.skill		local source = e.source
if cf.levmod then	local lup = 0.5			L.GetBaseStats()
	for _, s in pairs(p.object.class.majorSkills) do if s == sk then lup = 2 end end		for _, s in pairs(p.object.class.minorSkills) do if s == sk then lup = 1 end end
	local atr, atr2 = tes3.getSkill(sk).attribute, L.SA2[sk]	local Aname, Aname2 = L.ATR[atr], L.ATR[atr2]	D.L[Aname] = D.L[Aname] + 3		D.L[Aname2] = D.L[Aname2] + 2	D.L.levelup = D.L.levelup + lup
	if D.L[Aname] >= 10 then D.L[Aname] = D.L[Aname] - 10		if G.BaseStats[Aname] < 100 then tes3.modStatistic{reference = p, attribute = atr, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname) end end
	if D.L[Aname2] >= 10 then D.L[Aname2] = D.L[Aname2] - 10	if G.BaseStats[Aname2] < 100 then tes3.modStatistic{reference = p, attribute = atr2, value = 1}	tes3.messageBox("!!! %s +1 !!!", Aname2) end end
	if D.L.levelup >= 10 then	D.L.levelup = D.L.levelup - 10		if p.object.level < 100 then
		tes3.messageBox("!!! LEVEL UP !!!")		mwscript.setLevel{reference = p, level = p.object.level + 1}		--tes3.streamMusic{path="Special\\MW_Triumph.mp3"}	
		if G.BaseStats.luck < 100 then tes3.modStatistic{reference = p, attribute = 7, value = 1} end
		if G.BaseStats.personality < 100 and p.object.level > 50 then tes3.modStatistic{reference = p, attribute = 6, value = 1} end
		
		local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))		menu:findChild(tes3ui.registerID("MenuStat_level")).text = p.object.level	menu:updateLayout()
		if p.object.level * G.leskoef > D.L.les and G.stop.value == 1 then G.stop.value = 0 end
	end end
	mp.levelUpProgress = 0		if cf.m7 then tes3.messageBox("Attr: %s + %s = %s,  %s + %s = %s   Lvl + %s = %s", Aname, 3, D.L[Aname], Aname2, 2, D.L[Aname2], lup, D.L.levelup) end
end
if cf.skillp and source == "training" then -- progress, book, training
	D.L.les = D.L.les + 1		if p.object.level * G.leskoef <= D.L.les then	G.stop.value = 1 end
	tes3.messageBox("Trained already %s times. %s left. %s", D.L.les, p.object.level * G.leskoef - D.L.les, G.stop.value == 0 and "" or "It's time to put the acquired knowledge into practice")
end
if cf.trmod then	local gr = L.SKG[sk]	local tim = T.T1.timing - G.Exptim
	for i = 1, 4 do	D.ExpFat[i] = math.clamp(D.ExpFat[i] + (gr == i and L.SKF[i] or 0) * cf.expfat - tim, 0, 3600) end		G.Exptim = T.T1.timing
end

if cf.skillim then
	if source == "training" then
		D.SkillTr[L.S[sk]] = (D.SkillTr[L.S[sk]] or 0) + 1
		G.SkLim[sk] = G.SkLim[sk] + 1
	else
		if e.level >= (G.SkLim[sk] or 0) then G.SkBurn[sk] = true end
	end
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
	if FS[ob.id] then F1[FS[ob.id]] = s else table.insert(SS[ST[ob:getLeastProficientSchool(mp)]], s) end		--SS[ob.alwaysSucceeds and 1 or
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
for i, s in ipairs(IL.children) do s.minHeight = 32		s.minWidth = 32		s.text = nil	ob = s:getPropertyObject("MagicMenu_object")		ic = s:createImage{path = "icons\\" .. ob.icon}
if ob.objectType ~= tes3.objectType.book then icm = ic:createImage{path = "icons\\" .. ob.enchantment.effects[1].object.icon}		icm.absolutePosAlignX = 1	icm.absolutePosAlignY = 0
if cf.UIcol ~= 0 then mc = ic:createLabel{text = ("%s"):format(ob.enchantment.chargeCost)}	mc.color = L.UItcolor[cf.UIcol]		mc.font = 1 end end
s.absolutePosAlignX = 1/ls * ((i%ls > 0 and i%ls or ls)-1)		s.absolutePosAlignY = 1/ILin * (math.ceil(i/ls)-1) end
if IL.children[1] then IL.children[1]:register("destroy", function(e) M.EnDF = false	if tes3ui.menuMode() then timer.delayOneFrame(L.UpdateEnM, timer.real) end end)	M.EnDF = true end
end



local function MENUENTER(e)		--tes3.messageBox("%s   vis = %s", M.INV, M.INV.visible)
	if M.INV and M.INV.visible then	L.GetArStat() end
	if cf.UIen and not M.EnDF then local MagM = tes3ui.findMenu("MenuMagic")		if MagM and MagM.visible and MagM:findChild("MagicMenu_item_names").children[1] then L.UpdateEnM() end end
end		event.register("menuEnter", MENUENTER)


-- Эвент вызывает 1 раз в начале отдыха или ожидания
local function CALCRESTINTERRUPT(e)
	if D.PCcur then M.PC.current = M.PC.max end
	if D.potcd then D.potcd = 0 end
	
	if e.resting then 
		--tes3.messageBox("Rest %s    Num = %d   Hour = %d", e.resting, e.count, e.hour)
		for _, spell in pairs(p.object.spells) do if spell.castType == 5 then mp:rechargePower(spell) end end
		for _, spell in pairs(p.object.race.abilities) do if spell.castType == 5 then mp:rechargePower(spell) end end
		
		if tes3.getJournalIndex{id = "TR_DBHunt"} < 100 then local reput = p.object.reputation	if reput >= cf.dbrep then
			local st = tes3.getSimulationTimestamp()
			if st - (D.DBAlast or 0) > 24 and math.random(100) < 20 + reput*2 then D.DBAcount = (D.DBAcount or 0) + 1		D.DBAlast = st		local AST, num
				if D.DBAcount > 9 then AST = {"db_assassin3", "db_assassin4"}						num = 3
				elseif D.DBAcount > 6 then AST = {"db_assassin2", "db_assassin3", "db_assassin4"}	num = TC{2,2,3}
				elseif D.DBAcount > 3 then AST = {"db_assassin1", "db_assassin2", "db_assassin3"}	num = TC{1,2,2}
				else AST = {"db_assassin1b", "db_assassin1b", "db_assassin1", "db_assassin1", "db_assassin2"}		num = TC{1,1,1,2} end
				tes3.wakeUp()		tes3.messageBox(eng and "You were awakened by a loud noise" or "Вы пробудились от громкого шума")
				for i = 1, num do mwscript.placeAtPC{object = TC(AST), distance = 128, direction = 1} end
				if tes3.getJournalIndex{id = "TR_DBAttack"} < 30 then tes3.findGlobal("DBAttack").value = 1 end
			end
			--tes3.messageBox("Rest %s    Num = %d   Hour = %d   last + %d   count = %s", e.resting, e.count, e.hour, st - (D.DBAlast or 0), D.DBAcount)
		end end
	end

end		event.register("calcRestInterrupt", CALCRESTINTERRUPT)

L.Foots = {[15] = true, [16] = true}
local function bodyPartAssigned(e) if e.reference == p then	--local ind = e.index		
	if L.Foots[e.index] and e.object then e.bodyPart = L.FootBeast
		--tes3.messageBox("Replace   ind = %s", e.index)
	end
end end

local function SAVE(e)
	if cf.pussy < 3 then 
		if mp.inCombat or T.CT.timeLeft then tes3.messageBox(eng and "You cannot save the game in combat" or "Нельзя сохраняться в бою")		return false end
		if table.size(H) > 0 then	local ms = ""
			for r, t in pairs(H) do ms = ("%s %s (%d),"):format(ms, r.object.name, pp:distance(r.position)) end
			tes3.messageBox(eng and "You cannot save the game when %s enemies hunt you: %s" or "Нельзя сохраняться - %s врагов преследуют вас: %s", table.size(H), ms)		return false
		end
		if cf.pussy == 1 then	local safe = true
			if p.cell.isInterior then	for r, tab in pairs(N) do if tab.m.fight >= 90 then safe = nil		break end end
			else for _, m in pairs(tes3.findActorsInProximity{reference = p, range = 3000}) do if m ~= mp and m.fight >= 90 then safe = nil		break end end end
			if not safe then tes3.messageBox(eng and "You cannot save in dangerous places" or "Нельзя сохраняться в опасных местах")		return false end
		end
	end
--	D.MPlast = PMP.current
	if W.DWM then D.DW = {IDR = W.WR.id, IDL = W.WL.id, CondR = W.DR.condition, CondL = W.DL.condition} end
	if cf.trmod then local tim = T.T1.timing - G.Exptim		for i = 1, 4 do	D.ExpFat[i] = math.max(D.ExpFat[i] - tim, 0) end		G.Exptim = T.T1.timing end
end		event.register("save", SAVE)

local function LOAD(e)
if T.AoE.timeLeft then for i, t in pairs(AOE) do t.r:delete() end AOE = {} end
if T.Run.timeLeft then for i, t in pairs(RUN) do t.r:delete() end RUN = {} end
if T.Tot.timeLeft then for i, t in pairs(TOT) do t.r:delete() end TOT = {} end
if table.size(G.LigTab) ~= 0 then	for ref, _ in pairs(G.LigTab) do ref:delete() end  G.LigTab = {} end
--if T.LI.timeLeft then event.unregister("simulate", L.LigSim)	G.LigR = nil end
if T.DET.timeLeft then DEDEL() end
if p then AF[p] = nil	table.removevalue(L.RAR, p) end
if cf.tut then G.Tut = L.TUT[math.random(G.TutN)][eng and 2 or 1] end
--wc.blindnessFader:deactivate()	--устраняет баг со слепотой
end		event.register("load", LOAD)


local function MENULOADING(e)
	if not T.Tut.timeLeft then T.Tut = timer.start{type = timer.real, duration = 5, callback = function() G.Tut = nil end} end
	G.Tut = G.Tut or L.TUT[math.random(G.TutN)][eng and 2 or 1]
	e.element:createLabel{text = G.Tut}
end		if cf.tut then event.register("uiActivated", MENULOADING, {filter = "MenuLoading"}) end


local function LOADED(e) p = tes3.player	mp = tes3.mobilePlayer	ad = mp.actionData		pp = p.position		D = tes3.player.data	inv = p.object.inventory	p1 = tes3.player1stPerson.sceneNode		p3 = p.sceneNode
crot = wc.worldCamera.cameraRoot.rotation		G.pori = p.orientation		G.mph = mp.height		G.mph05 = tes3vector3.new(0,0,G.mph*0.5)		G.mph07 = tes3vector3.new(0,0,G.mph*0.7)		G.MBret = false
if not D.Mmod then D.Mmod = {} end	DM = D.Mmod		if not D.perks then D.perks = {} end	P = D.perks		if not D.traits then D.traits = {} end	G.TR = D.traits
if not D.STB then D.STB = {["strength"]=0,["intelligence"]=0,["willpower"]=0,["agility"]=0,["speed"]=0,["endurance"]=0,["personality"]=0,["luck"]=0} end

if not D.ENCO then D.ENCO = {} end
if not D.FS then D.FS = {} end
if not D.QW then D.QW = {} end
if not D.AR then D.AR = {l=0,m=0,h=0,u=25,as=1,ms=1,dk=1,dc=1,cs=1,cc=1,mc=1,elr=0} end
if not D.L then D.L = {strength = 0, endurance = 0, intelligence = 0, willpower = 0, speed = 0, agility = 0, personality = 0, levelup = 0, les = 0} end
if not D.SkillTr then D.SkillTr = {} end
if not D.LEG then D.LEG = {} end	
if not D.CON then D.CON = {} end
if not D.MSEF then D.MSEF = {} end
if cf.trmod then	D.ExpFat = D.ExpFat or {0,0,0,0}	G.Exptim = 0 end
D.ENconst = D.ENconst or 0		D.ENconMax = D.ENconMax or 5000	
AF[p] = {pl = true}		table.insert(L.RAR, p)		SNC = {}	COL = {}	MPR = {}	W = {}		SN = {}		V.BAL = {}	V.MET = {}	V.METR = {}		R = {}	 G.TimRef = {}	L.ClearEn()		L.SetGlobal(1)		G.DopW = {}
H = {}		G.DTS = {}
local PTD = p.tempData		PTD.hgt = G.mph		PTD.hum = true		PTD.mass = math.max(PTD.hgt^2, 5000)/10000 * 0.75		--PTD.anid = mp.animationController.animationData

G.Ecomb = 0		G.comb = 0
L.UpdTSK()	--wc.simulationTimeScalar = 1
G.ck = ic.inputMaps[tes3.keybind.readyMagic + 1].code		--G.sis = wc.timescale.value/3600
PMP = mp.magicka	PST = mp.fatigue



if D.e501 then AF[p].T501 = timer.start{duration = 1, iterations = -1, callback = L.RechargeTik}	G.REI = {} end
G.LigR = nil
if D.e504 then
	local spawn = 0
	for _, cell in pairs(tes3.getActiveCells()) do for r in cell:iterateReferences() do if r.baseObject.id == "4nm_light" then spawn = spawn + 1	r:delete() end end end
	if spawn > 0 then tes3.messageBox("%s lights extra deleted", spawn) end
	L.LigUpd()
end
for ref, _ in pairs(PRR) do ref:delete() end		PRR = {}


W.l1 = p1:getObjectByName("Bip01 L Hand")		W.l3 = p3:getObjectByName("Bip01 L Hand")		W.r1 = p1:getObjectByName("Bip01 R Hand")		W.r3 = p3:getObjectByName("Bip01 R Hand")
W.w1 = p1:getObjectByName("Weapon Bone")		W.w3 = p3:getObjectByName("Weapon Bone")		event.unregister("playItemSound", L.DWESound, {priority = 10000})		L.MagefAdd()


B.poi = tes3.getObject("4b_poison") or tes3alchemy.create{id = "4b_poison", name = "4b_poison", weight = 0.1, icon = "s\\b_tx_s_sun_dmg.dds"}	--B.poi.sourceless = true
if D.AUR then T.AUR = timer.start{duration = P.wil35 and math.max(3 - mp:getSkillValue(11)/200, 2.5) or 3, iterations = -1, callback = L.AuraTik} end

local MU = tes3ui.findMenu("MenuMulti")		M.MU = MU			M.Stat = tes3ui.findMenu("MenuStat")	M.INV = tes3ui.findMenu("MenuInventory")
local IcLA = MU:findChild("MenuMulti_icons_layout")			local FbLA = MU:findChild("MenuMulti_fillbars_layout")
M.BarH = MU:findChild("MenuStat_health_fillbar")			M.BarM = MU:findChild("MenuStat_magic_fillbar")			M.BarS = MU:findChild("MenuStat_fatigue_fillbar")
M.Mana = M.BarM.widget		--M.Mana.current = PMP.current 	M.Mana.max = PMP.base


G.SP2 = D.SP2 and tes3.getObject(D.SP2)		if G.SP2 and not p.object.spells:contains(G.SP2) then G.SP2 = nil end
local S2BL = IcLA:createBlock{}		S2BL.autoHeight = true	S2BL.autoWidth = true	S2BL.borderAllSides = 2		S2BL.flowDirection = "top_to_bottom"
M.S2IC = S2BL:createImage{path = G.SP2 and "icons\\" .. G.SP2.effects[1].object.bigIcon or "icons\\k\\magicka.dds"}		M.S2IC.borderAllSides = 2
M.S2IC:register("help", function() if G.SP2 then tes3ui.createTooltipMenu{spell = G.SP2} end end)


D.ConN = D.ConN or 1
local CBL = IcLA:createBlock{}		CBL.autoHeight = true	CBL.autoWidth = true	CBL.borderAllSides = 2		CBL.flowDirection = "top_to_bottom"
M.Cicon = CBL:createImage{path = D.CON["s"..D.ConN] and L.GetIC(D.CON["ic"..D.ConN]) or "icons\\k\\fatigue.dds"}		M.Cicon.borderAllSides = 2
if D.ConSN then local si = tes3.getMagicSourceInstanceBySerial{serialNumber = D.ConSN}	if si then si.state = 6 end		D.ConSN = nil end
T.CON = timer.start{duration = 0.1, iterations = -1, callback = L.ConTim}	T.CON:cancel()

M.drop = IcLA:createImage{path = "icons\\poisondrop.tga"}	M.drop.visible = not not D.poimod
IcLA:reorderChildren(5, 2, 1)
M.MSPD = IcLA:createLabel{text = ""}	M.MSPD.color = {1,1,1}


local Npc = MU:findChild("MenuMulti_npc")		Npc.flowDirection = "top_to_bottom"		Npc.alpha = 0
M.SHbar = FbLA:createFillBar{current = 100, max = 100}	L.NoBorder(M.SHbar)	M.SHbar.visible = false	M.SHbar.widget.showText = false	M.SHbar.widget.fillColor = {0,1,1}	M.SHbar.width = 65	M.SHbar.height = 6	M.SHbar.borderLeft = 2

M.Bar5 = Npc:createFillBar{current = D.potcd or 0, max = (P.end9 and 100 or 75) + mp.endurance.base/4}
M.Bar5.width = 65	M.Bar5.height = 12	L.NoBorder(M.Bar5)	M.TOX = M.Bar5.widget	M.TOX.showText = false	M.TOX.fillColor = M.TOX.normalized < 1 and {0.5,1,0} or {1,0.25,0}
T.POT = timer.start{duration = 1, iterations = -1, callback = L.PotTim}		if not D.potcd then T.POT:cancel()		M.Bar5.visible = false end

M.Bar4 = Npc:createFillBar{current = 0, max = L.GetPCmax()}		M.Bar4.width = 65	M.Bar4.height = 12	L.NoBorder(M.Bar4)	M.PC = M.Bar4.widget	M.PC.showText = false	M.PC.fillColor = {0.6,0,1}	M.Bar4.borderTop = 3



local WLA = MU:findChild("MenuMulti_weapon_layout")		M.SpFB = MU:findChild("MenuMulti_magic_fill")		M.WeFB = MU:findChild("MenuMulti_weapon_fill")		M.WeFB.borderBottom = 1
if cf.newUI then		--M.BarM:register("PartScrollBar_changed", function() tes3.messageBox("update mag") end)
	L.NoBorder(M.BarH)		L.NoBorder(M.BarM)		L.NoBorder(M.BarS)		M.BarH.width = 150		M.BarM.width = 150		M.BarS.width = 150		M.Bar4.width = 150		M.Bar5.width = 150		M.SHbar.width = 150
	L.NoBorder(MU:findChild("MenuMulti_weapon_border"),0)	L.NoBorder(MU:findChild("MenuMulti_magic_border"),0)		L.NoBorder(MU:findChild("MenuMulti_magic_icons_1"),0)
	L.NoBorder(M.WeFB)		M.WeFB.height = 5		L.NoBorder(M.SpFB)		M.SpFB.height = 5		MU:findChild("MenuMulti_magic_layout").alpha = 0		WLA.alpha = 0
	M.BarH.widget.fillColor = {1,0,0.4}		M.BarM.widget.fillColor = {0,0.5,1}		M.BarS.widget.fillColor = {0,0.75,0}
	local NpcHB = MU:findChild("MenuMulti_npc_health_bar")		L.NoBorder(NpcHB)		--L.NoBorder(MU:findChild("MenuMulti_sneak_icon").children[1], 0)
	--NpcHB.ignoreLayoutX = true		NpcHB.ignoreLayoutY = true		NpcHB.positionX = 200	NpcHB.positionY = 200	NpcHB:updateLayout()
--	WLA.borderAllSides = 0
end
if cf.UInum then	M.Mana.showText = true			M.BarH.widget.showText = true		M.BarS.widget.showText = true		M.PC.showText = true	M.TOX.showText = true
	M.Mana.current = PMP.current		M.BarH.widget.current = mp.health.current		M.BarS.widget.current = PST.current
	L.BarText(M.BarH)	L.BarText(M.BarM)	L.BarText(M.BarS)	L.BarText(M.Bar4)	L.BarText(M.Bar5)
end

M.BB = {}	M.BBM = MU:createBlock{}	M.BBM.autoWidth = true		M.BBM.autoHeight = true		M.BBM.borderAllSides = 7	M.BBM.absolutePosAlignX = cf.BBrig and 1 or 0		M.BBM.absolutePosAlignY = 0
if not cf.BBhor then M.BBM.flowDirection = "top_to_bottom" end
if cf.BBen then local dur, cur	for _, aef in pairs(mp:getActiveMagicEffects{}) do dur = aef.duration	if dur > 1 then cur = dur - aef.effectInstance.timeActive	if cur > 0 then
L.NewBB(aef.effectId, tes3.getMagicEffect(aef.effectId).bigIcon, dur, aef.serial * 10 + aef.effectIndex, cur) end end end end

if cf.nomic then MU:findChild("MenuMulti_magic_icons_layout").visible = false end

T.PCT = timer.start{duration = 1, iterations = -1, callback = function()
	M.PC.current = M.PC.current + M.PC.max/(P.enc7 and 80 or 100) + (PMP.normalized < 1 and 0 or tes3.getEffectMagnitude{reference = p, effect = 76} * (P.enc18 and 1 or 0.5))
	if M.PC.normalized > 1 then M.PC.current = M.PC.max		T.PCT:cancel()	D.PCcur = nil	M.Bar4.visible = false
	else D.PCcur = M.PC.current end
end}
M.PC.current = D.PCcur or M.PC.max		if not D.PCcur then T.PCT:cancel()	M.Bar4.visible = false end



W.BAR = WLA:createFillBar{current = 10, max = 10}	W.BAR.width = 36	W.BAR.height = 5	L.NoBorder(W.BAR)	W.BAR.borderBottom = 1		W.BAR.visible = false
W.bar = W.BAR.widget	W.bar.showText = false		W.bar.fillColor = D.NoEnStrike and {1,0,0} or {0,1,1}
T.T1 = timer.start{duration = 1, iterations = -1, callback = function()		if W.en then W.bar.current = W.v.charge end
	--for actor in tes3.iterate(mp.friendlyActors) do if actor ~= mp and actor.inCombat and actor.actionData.aiBehaviorState == -1 then
		--	actor:stopCombat()		tes3.messageBox("%s   Beh = %s", actor.reference, actor.actionData.aiBehaviorState)
	--end end
	if table.size(M.BB) > 0 then local n	for _, aef in pairs(mp:getActiveMagicEffects{}) do	local B = M.BB[aef.effectId]	B = B and B[aef.serial * 10 + aef.effectIndex]		B = B and B.widget
		if B then B.current = B.max - aef.effectInstance.timeActive		n = math.remap(B.current, cf.BBred, cf.BBgr, 0, 1)		B.fillColor = {2-n*2, n*2, n-1} end
	end end
end}

local w = mp.readiedWeapon	local wd = w and w.variables	w = w and w.object		local wt = w and w.type or -1
if wt ~= -1 then
	if D.DW then
		if w.id == D.DW.IDR and wd.condition == D.DW.CondR then L.DWNEW(w, wd, false)		local ob = tes3.getObject(D.DW.IDL)
			for i, ida in pairs(inv:findItemStack(ob).variables) do if ida.condition == D.DW.CondL and ida ~= W.DR then L.DWNEW(ob, ida, true)	break end end
		elseif w.id == D.DW.IDL and wd.condition == D.DW.CondL then L.DWNEW(w, wd, true)	local ob = tes3.getObject(D.DW.IDR)
			for i, ida in pairs(inv:findItemStack(ob).variables) do if ida.condition == D.DW.CondR and ida ~= W.DL then L.DWNEW(ob, ida, false)	break end end
		end
		D.DW = nil
	elseif WT[wt].dw then L.DWNEW(w, wd, false) end
end


local WeIC = MU:findChild("MenuMulti_weapon_icon")
M.CombK = WeIC:createLabel{text = ""}	M.CombK.color = {1,1,1}		M.CombK.absolutePosAlignX = 1	M.CombK.absolutePosAlignY = 0
if G.TR.tr5 then D.nopar = nil end
M.NoPar = WeIC:createLabel{text = "*"}	M.NoPar.color = {1,0,0}			M.NoPar.absolutePosAlignX = 0	M.NoPar.absolutePosAlignY = 1		M.NoPar.visible = not not D.nopar

L.GetWstat()
M.WPB = WLA:createFillBar{current = D.poison or 0, max = 100}	M.WPB.width = 36	M.WPB.height = 5	M.WPB.widget.showText = false	M.WPB.widget.fillColor = {0.5,1,0}	L.NoBorder(M.WPB)	M.WPB.visible = not not D.poison
M.MCbar = MU:createFillBar{current = 0, max = 100}	M.MCbar.width = 30	M.MCbar.height = 4	L.NoBorder(M.MCbar)		M.MCbar.absolutePosAlignX = 0.5		M.MCbar.absolutePosAlignY = 0.51	
M.MCB = M.MCbar.widget	M.MCB.showText = false	M.MCB.fillColor = {0,1,0}		




if M.INV then	M.INV:register("destroy", function() M.INV = nil end)
M.WgtBarT = M.INV:findChild("MenuInventory_Weightbar"):findChild("PartFillbar_text_ptr")
M.AR = M.INV:findChild("MenuInventory_ArmorRating")		M.AR.minWidth = 210		M.AR.width = 210
M.AR:register("help", function() local tt = tes3ui.createTooltipMenu():createBlock{}	tt.autoHeight = true	tt.autoWidth = true		tt.flowDirection = "top_to_bottom"
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

M.MI = M.INV:findChild("MenuInventory_character_box")	M.MI.autoHeight = true		M.MI.autoWidth = true		M.MI.flowDirection = "top_to_bottom"
M.RES = M.MI:createBlock{}	M.RES.width = 210	M.RES.autoHeight = true
M.SL2 = M.MI:createBlock{}	M.SL2.width = 210	M.SL2.autoHeight = true
M.SL3 = M.MI:createBlock{}	M.SL3.width = 210	M.SL3.autoHeight = true	
M.SL4 = M.MI:createBlock{}	M.SL4.width = 210	M.SL4.autoHeight = true
M.SI11 = M.AR:createImage{path = "icons\\s\\repairArmor.tga"}		M.SI11.borderRight = 28
M.ST11 = M.AR:createLabel{}		M.ST11.borderRight = 5

M.AR:createImage{path = "icons\\s\\dash.tga"}	M.ST12 = M.AR:createLabel{}


M.RES:createImage{path = "icons\\s\\reflectSpell.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Magic resist" or "Сопротивление магии"} end)
M.RES1 = M.RES:createLabel{}		M.RES1.borderRight = 5
M.RES:createImage{path = "icons\\s\\reflectFire.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Fire resist" or "Сопротивление огню"} end)
M.RES2 = M.RES:createLabel{}		M.RES2.borderRight = 5
M.RES:createImage{path = "icons\\s\\reflectFrost.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Frost resist" or "Сопротивление холоду"} end)
M.RES3 = M.RES:createLabel{}		M.RES3.borderRight = 5
M.RES:createImage{path = "icons\\s\\reflectShock.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Lightning resist" or "Сопротивление молнии"} end)
M.RES4 = M.RES:createLabel{}		M.RES4.borderRight = 5
M.RES:createImage{path = "icons\\s\\reflectPoison.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Poison resist" or "Сопротивление яду"} end)
M.RES5 = M.RES:createLabel{}


M.SL2:createImage{path = "icons\\s\\charge_fire.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Physical damage" or "Физический урон"} end)		
M.ST21 = M.SL2:createLabel{}	M.ST21.borderRight = 5
M.SL2:createImage{path = "icons\\s\\repairWeapon.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Attack Speed / Maximum combo" or "Cкорость атаки / Максимум комбо"} end)
M.ST22 = M.SL2:createLabel{}	M.ST22.borderRight = 5
M.SL2:createImage{path = "icons\\"..MEF[77+1].icon}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Stamina regeneration" or "Регенерация стамины"} end)
M.ST23 = M.SL2:createLabel{}
M.SL3:createImage{path = "icons\\s\\recharge.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Magic power" or "Мощность магии"} end)
M.ST31 = M.SL3:createLabel{}	M.ST31.borderRight = 5
M.SL3:createImage{path = "icons\\s\\empower_force.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Mana cost" or "Стоимость заклинаний"} end)
M.ST32 = M.SL3:createLabel{}	M.ST32.borderRight = 5
M.SL3:createImage{path = "icons\\s\\projectileControl.tga"}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Cast chance" or "Шанс каста"} end)
M.ST33 = M.SL3:createLabel{}	M.ST33.borderRight = 5
M.SL3:createImage{path = "icons\\"..MEF[76+1].icon}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Mana regeneration" or "Регенерация маны"} end)
M.ST34 = M.SL3:createLabel{}
M.SL4:createImage{path = "icons\\"..MEF[42+1].icon}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Jump power / Dodge speed / Evasion" or "Сила прыжка / Скорость доджа / Уклонение"} end)
M.ST41 = M.SL4:createLabel{}	M.ST41.borderRight = 5
M.SL4:createImage{path = "icons\\"..MEF[8+1].icon}:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Stamina cost for attack / running / jump / dodge" or "Расход стамины на атаку / бег / прыжок / уклонение"} end)
M.ST42 = M.SL4:createLabel{}

M.ENLB = M.MI:createFillBar{current = D.ENconst, max = D.ENconMax}		M.ENLB.width = 210		M.ENLB.height = 10		L.NoBorder(M.ENLB)		M.ENL = M.ENLB.widget	M.ENL.showText = false
M.ENL.fillColor = D.ENconst < D.ENconMax and {0,1,0} or {0,1,1}
M.ENLB:register("help", function() tes3ui.createTooltipMenu():createLabel{text = ("%s: %d / %d"):format(eng and "Constant enchant limit" or "Лимит постоянных зачарований", M.ENL.current, M.ENL.max)} end)

--M.MI:register("destroy", function(e) mwse.log("Inv tooltip destriyed")	 tes3.messageBox("Inv tooltip destriyed") end)
--M.INV:register("update", function() tes3.messageBox("update") end)	
end


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
	M.FatBar = M.MAP:createFillBar{current = 100, max = 100}	M.FatBar.width = 64		M.FatBar.height = 6		M.FatBarW = M.FatBar.widget		M.FatBarW.showText = false	M.FatBarW.fillColor = {0, 1, 0}		L.NoBorder(M.FatBar)
	M.FatBar:register("help", function() tes3ui.createTooltipMenu():createLabel{text = eng and "Training fatigue" or "Тренировочная усталость"} end)	M.FatBar.visible = false	
	M.MAP:reorderChildren(0, table.size(M.MAP.children) - 1, 1)
end


local o = tes3.getObject("4s_620")
if not o or o.magickaCost ~= 10 then	local s			tes3.messageBox("New effects and spells updated")		--o.effects[1].max ~= 10 
	for _, t in ipairs(L.NEWSP) do s = tes3.createObject{objectType = tes3.objectType.spell, id = "4s_"..t[1]}	--s.sourceless = true
	s.name = t[9]		s.magickaCost = t[8] or 0	s = s.effects[1]	s.rangeType = t[2]	s.id = t[3]		s.min = t[4]	s.max = t[5]	s.radius = t[6]		s.duration = t[7] end	
	for id, t in pairs(L.PA) do s = tes3.createObject{objectType = tes3.objectType.spell, id = "4p_"..id, castType = 1}		s.name = eng and t[5] or t[4] or "4p_"..id
	s = s.effects[1]	s.id = t[1]		s.min = t[2]	s.max = t.m or t[2] end
	for id, t in pairs(L.NSU) do s = tes3.createObject{objectType = tes3.objectType.spell, id = id}  s.name = eng and t.en or t.ru		s.magickaCost = t.c		if t.f then s.alwaysSucceeds = true end		s = s.effects
	for i, ef in ipairs(t) do s[i].rangeType = t.rt	or 0	s[i].id	= ef[1]		s[i].min = ef[2] or t.m		s[i].max = ef[3] or t.ma	s[i].radius = ef.r or t.r or 0		s[i].duration = ef.d or t.d		s[i].attribute = ef.a or -1 end end
end
	
if not tes3.getObject("marayn dren").spells:contains("4s_620") then				--tes3.getObject("felen maryon").spells:contains("4s_134")
	o = tes3.getObject("marayn dren")		for _, num in ipairs(L.SFS) do o.spells:add("4s_"..num) end
	for id, list in pairs(L.SSEL) do o = tes3.getObject(id)		for i, sp in ipairs(list) do o.spells:add(sp) end	o.modified = true end	--tes3.messageBox("Spellsellers get new spells")
end

if not e.newGame then L.READY = true	local PS = {}	local PAT = {}	PS.sp = p.object.class.specialization	local id	local b = L.BS[mp.birthsign.id]				L.TrLimCalc()
	for _, s in pairs(p.object.class.majorSkills) do PS[s] = 0.5 end		for _, s in pairs(p.object.class.minorSkills) do PS[s] = 1 end		for _, at in pairs(p.object.class.attributes) do PAT[at] = true end
	for i, l in ipairs(L.PR) do for _, t in ipairs(l) do	id = L.PRL[i][3]		--mp[L.PRL[i][1]].type
		if i < 9 then t.x = PAT[id] and 1 or 2
		else --t.x = (PS[id] or 3) - ((L.SS[id] == PS.sp and 1 or 0) + (PAT[L.SA[id]] and 1 or 0) + (PAT[L.SA2[id]] and 1 or 0) > 1 and 1 or 0)
			t.x = PS[id] or 2
		end
		t.f = math.max(t.x - (t.c or 0),0)
	end end
	if not D.chimstar and b and p.object.level >= 20 then
		mwscript.removeSpell{reference = p, spell = "4nm_star_"..b.."1"}	tes3.addSpell{reference = p, spell = "4nm_star_"..b.."2"}		-- mwscript обязателен, иначе не удалится пассивка в созведии из КС!
		if L.BSAct[b] and tes3.getObject("4nm_star_"..b.."2a") then tes3.addSpell{reference = p, spell = "4nm_star_"..b.."2a"} end
		tes3.messageBox(eng and "You have awakened the power of your Birth Sign" or "Вы пробудили силу своего Знака")	D.chimstar = 1
	elseif D.chimstar == 1 and b and p.object.level >= 50 then
		mwscript.removeSpell{reference = p, spell = "4nm_star_"..b.."2"}	tes3.addSpell{reference = p, spell = "4nm_star_"..b.."3"}
		if L.BSAct[b] and tes3.getObject("4nm_star_"..b.."3a") then tes3.addSpell{reference = p, spell = "4nm_star_"..b.."3a"} end
		tes3.messageBox(eng and "You have ascended to level of the gods and unleashed the true potential of your Birth Sign" or "Вы вознеслись до уровня богов и раскрыли истинный потенциал своего Знака")	D.chimstar = 2
	end
	if cf.UIsp then L.UpdateSpellM() end
	if cf.UIen then local MM = tes3ui.findMenu("MenuMagic")	MM:findChild("MagicMenu_item_costs").visible = false		MM:findChild("MagicMenu_item_percents").visible = false		M.EnDF = false end

	if cf.beastarm and p.object.race.isBeast then
		L.FootBeast = p.object.race[p.object.female and "femaleBody" or "maleBody"].foot
		if not event.isRegistered("bodyPartAssigned", bodyPartAssigned) then event.register("bodyPartAssigned", bodyPartAssigned) end
		p:updateEquipment()
	else event.unregister("bodyPartAssigned", bodyPartAssigned)		L.FootBeast = nil end
	
else L.READY = nil		tes3.messageBox(eng and "The perks menu (F2) will be available after the first save loading" or "Меню перков (F2) будет доступно после первой загрузки сейва") end

end		event.register("loaded", LOADED)


local function initialized(e)	wc = tes3.worldController	ic = wc.inputController		MB = ic.mouseState.buttons		prm = wc.mobManager.processManager		local o, E
--ГМСТ едины для игровой сессии и обновляются из плагинов при старте игры. Если поменять ГМСТ через луа, то они сохранятся для всех последующих сейвов в этой сессии но сбросятся на дефолтные при следующем запуске игры
wc.mobManager.gravity.z = -1000		wc.mobManager.terminalVelocity.z = -15000
G.MosX = wc.mouseSensitivityX	G.MosY = wc.mouseSensitivityY


if not tes3.isModActive("4NM.esp") then tes3.messageBox(eng and "4NM.esp is not connected! The game is broken until you connect it!" or "4NM.esp не подключен! Игра сломана пока вы не подключите его!") end

--ic.inputMaps[tes3.keybind.readyMagicMCP + 1].code = tes3.scanCode.y


G.VFXspark = tes3.createObject{objectType = tes3.objectType.static, id = "VFX_WSparks", mesh = "e\\spark.nif"}			G.VFXsum = tes3.getObject("VFX_Summon_Start")
G.VFXarrow = tes3.getObject("VFX_DestructBolt"):createCopy{id = "VFX_KArrow"}	G.VFXarrow.mesh = "e\\magic_target_arrow.nif"
--tes3.createObject{objectType = tes3.objectType.static, id = "VFX_KArrow", mesh = "e\\magic_target_arrow.nif"}

	
G.WdmgGMST = tes3.findGMST("fWeaponDamageMult")
G.CombatDistance = tes3.findGMST("fCombatDistance")		G.CombatAngleXY = tes3.findGMST("fCombatAngleXY")			--tes3.findGMST("fCombatAngleZ").value = 0.666
--G.CriticalMult = tes3.findGMST("fCombatCriticalStrikeMult")



tes3.findGMST("fHandToHandReach").value = 1				tes3.findGMST("fCombatDelayNPC").value = cf.atspdm		tes3.findGMST("fCombatDelayCreature").value = cf.atspdm		--tes3.findGMST("fMagicCreatureCastDelay").value = 0
tes3.findGMST("fEffectCostMult").value = 1				tes3.findGMST("fNPCbaseMagickaMult").value = 5			tes3.findGMST("iAutoSpellTimesCanCast").value = 5			tes3.findGMST("fAutoSpellChance").value = 70	
tes3.findGMST("fTargetSpellMaxSpeed").value = 4000
tes3.findGMST("fEnchantmentMult").value = 0.1			tes3.findGMST("iSoulAmountForConstantEffect").value = 100		tes3.findGMST("fEnchantmentConstantDurationMult").value = 100
tes3.findGMST("fFatigueSpellBase").value = 0.5			tes3.findGMST("fFatigueSpellMult").value = 0.5			tes3.findGMST("fElementalShieldMult").value = 1
tes3.findGMST("fEncumberedMoveEffect").value = 0.5		tes3.findGMST("fBaseRunMultiplier").value = 3			tes3.findGMST("fAthleticsRunBonus").value = 1
tes3.findGMST("fSwimRunBase").value = 0.5				tes3.findGMST("fSwimRunAthleticsMult").value = 0.1		tes3.findGMST("fMinWalkSpeedCreature").value = 0		--tes3.findGMST("fMaxWalkSpeedCreature").value = 200
tes3.findGMST("fFallDistanceMult").value = 0.1			tes3.findGMST("fFallDamageDistanceMin").value = 400		tes3.findGMST("fFallAcroBase").value = 1
tes3.findGMST("fJumpMoveBase").value = 0.5				tes3.findGMST("fJumpMoveMult").value = 0.5
tes3.findGMST("fFatigueReturnBase").value = 10			tes3.findGMST("fFatigueReturnMult").value = 0.2			tes3.findGMST("fFatigueBase").value = 1.5					tes3.findGMST("fFatigueMult").value = 0.5
tes3.findGMST("fFatigueAttackBase").value = 0			tes3.findGMST("fFatigueAttackMult").value = 0			tes3.findGMST("fWeaponFatigueMult").value = 0
tes3.findGMST("fFatigueBlockBase").value = 0			tes3.findGMST("fFatigueBlockMult").value = 0			tes3.findGMST("fWeaponFatigueBlockMult").value = 0
tes3.findGMST("fFatigueJumpBase").value = 0				tes3.findGMST("fFatigueJumpMult").value = 0
tes3.findGMST("fCombatBlockLeftAngle").value = -1		tes3.findGMST("fCombatBlockRightAngle").value = 0.5
tes3.findGMST("fFatigueRunBase").value = 20				tes3.findGMST("fFatigueRunMult").value = 20				tes3.findGMST("fFatigueSwimWalkBase").value = 20			tes3.findGMST("fFatigueSwimWalkMult").value = 20
tes3.findGMST("fFatigueSwimRunBase").value = 30			tes3.findGMST("fFatigueSwimRunMult").value = 30			tes3.findGMST("fFatigueSneakBase").value = 0				tes3.findGMST("fFatigueSneakMult").value = 20
tes3.findGMST("fMinHandToHandMult").value = 0			tes3.findGMST("fMaxHandToHandMult").value = 0.2			tes3.findGMST("fHandtoHandHealthPer").value = 0.25
tes3.findGMST("fKnockDownMult").value = 0.5				tes3.findGMST("iKnockDownOddsBase").value = 101			tes3.findGMST("iKnockDownOddsMult").value = 50				tes3.findGMST("fCombatKODamageMult").value = 1.5		
tes3.findGMST("fDamageStrengthBase").value = 1			tes3.findGMST("fDamageStrengthMult").value = 0.05		tes3.findGMST("fCombatArmorMinMult").value = 0
tes3.findGMST("fProjectileMinSpeed").value = 2000		tes3.findGMST("fProjectileMaxSpeed").value = 8000		tes3.findGMST("fThrownWeaponMinSpeed").value = 2000			tes3.findGMST("fThrownWeaponMaxSpeed").value = 6000	
tes3.findGMST("fAIFleeHealthMult").value = 88.888		tes3.findGMST("fFleeDistance").value = 5000				tes3.findGMST("fAIRangeMeleeWeaponMult").value = 70			tes3.findGMST("fSuffocationDamage").value = 10
tes3.findGMST("fAIFleeFleeMult").value = 0	--0.3	 float rating = (1.0f - healthPercentage) * fAIFleeHealthMult + flee * fAIFleeFleeMult;
tes3.findGMST("fSleepRestMod").value = 0.5				tes3.findGMST("fDispDiseaseMod").value = -30			tes3.findGMST("fSpecialSkillBonus").value = 0.8
tes3.findGMST("fRestMagicMult").value = 0.5				tes3.findGMST("iMonthsToRespawn").value = 7				tes3.findGMST("fProjectileThrownStoreChance").value = 0
tes3.findGMST("iHelmWeight").value = 10		tes3.findGMST("iPauldronWeight").value = 10		tes3.findGMST("iCuirassWeight").value = 30		tes3.findGMST("iGauntletWeight").value = 5
tes3.findGMST("iGreavesWeight").value = 15	tes3.findGMST("iBootsWeight").value = 15		tes3.findGMST("iShieldWeight").value = 25		tes3.findGMST("fLightMaxMod").value = 0.5		tes3.findGMST("fMedMaxMod").value = 1

tes3.findGMST("sArmor").value = " "
tes3.findGMST("sMagicPCResisted").value = ""	tes3.findGMST("sMagicTargetResisted").value = ""	tes3.findGMST("sMagicInsufficientCharge").value = ""	tes3.findGMST("sTargetCriticalStrike").value = ""	
tes3.findGMST("spoint").value = ""		tes3.findGMST("spoints").value = ""		tes3.findGMST("spercent").value = ""		tes3.findGMST("sXTimesINT").value = ""		tes3.findGMST("sTo").value = "-"
tes3.findGMST("sRepairSuccess").value = ""
tes3.findGMST("sCreateClassMenuHelp1").value = eng and 
"You'll get +5 to all skills of your specialization, they'll also be easier to increase. Major skills perks cost 0.5 perkpoint. Minor skills perks cost 1 perkpoint. Other perks cost 2 perkpoints." or
"Вы получаете +5 к навыкам вашей специализации, эти навыки будут быстрее расти. Перки главных навыков стоят 0.5 перкпоинта. Перки важных навыков стоят 1 перкпоинт. Остальные перки стоят 2 перкпоинта."
tes3.findGMST("sCreateClassMenuHelp2").value = eng and "You'll get +10 to each of your favored attributes. Perks of these attributes cost 1 perkpoint instead of 2" or
"Вы получаете +10 к вашим главным характеристикам. Перки этих характеристик стоят 1 перкпоинт вместо 2"

G.GMSTskelet = tes3.findGMST("sMagicSkeletalMinionID")


MEF = tes3.dataHandler.nonDynamicData.magicEffects
MEF[19].hasContinuousVFX = false	MEF[4].hasContinuousVFX = false		-- 3 + 1		drainHealth и щит
for _, id in ipairs{121,122,123,124,125,126,128,129,130,131,132} do MEF[id].nonRecastable = false end

if cf.enbar then tes3.findGMST("fNPCHealthBarTime").value = 0		tes3.findGMST("fNPCHealthBarFade").value = 0 end
if cf.alc then tes3.findGMST("fPotionT1MagMult").value = 2		tes3.findGMST("fPotionT1DurMult").value = 0.5 end

local pal = wc.menuController.fontColors[46]	pal.r = 0	pal.g = 255		pal.b = 255
pal = wc.menuController.fontColors[45]			pal.r = 255	pal.g = 255		pal.b = 0


--for _, v in ipairs(L.SREG) do o = tes3spell.create("4s_"..v, "4s_"..v) 	o.magickaCost = 0	o.sourceless = true		S[v] = o end
for _, n in ipairs(L.BREG) do o = tes3.createObject{objectType = tes3.objectType.alchemy, id = "4b_"..n, name = "4b_"..n, icon = "s\\b_tx_s_sun_dmg.dds"} 	o.sourceless = true 	B[n] = o 	G[n] = o.effects end
for _, t in ipairs(L.BU) do o = tes3.createObject{objectType = tes3.objectType.alchemy, id = "4b_"..t.n, name = "4b_"..t.n, icon = "s\\b_tx_s_sun_dmg.dds"}	o.sourceless = true		o.weight = t.w or 0		B[t.n] = o	E = o.effects
for i, ef in ipairs(t) do E[i].rangeType = ef[1]	E[i].id = ef[2]		E[i].min = ef[3]	E[i].max = ef[4]	E[i].radius = ef[5]		E[i].duration = ef[6] end end

BAM.E = tes3.getObject("4nm_e_boundammo").effects		L.MagLig = tes3.getObject("4nm_light")		L.stone = tes3.getObject("4nm_stone")		L.magef = tes3.loadMesh("e\\magef.nif")
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
{601, "boundAmmo", eng and "Bound ammo" or "Призвать снаряды", 1, s=1, "Bounds arrows, bolts or throwing stars from Oblivion", c1=0, c2=0, nom=1},
{602, "kineticStrike", "Kinetic strike", 4, s=0, "A burst of power knocks back enemies and deals physical damage", c0=0, nod=1, h=1, snd=2, sh = "Sound Test", col = L.KSCollision, tik = function(e) e.effectInstance.state = tes3.spellState.retired end},
{603, "boundWeapon", eng and "Bound weapon" or "Призвать оружие", 10, s=1, "Bounds any weapon from Oblivion", c1=0, c2=0, nom=1, tik = function(e) e:triggerBoundWeapon(D and D.boundw or "4_bound longsword") end},
{604, "BoundGreaves", eng and "Bound greaves" or "Призвать поножи", 5, s=1, "Bounds greaves from Oblivion", c1=0, c2=0, nom=1, tik = function(e) e:triggerBoundArmor("bound_greaves") end},
{605, "boundPauldrons", eng and "Bound pauldrons" or "Призвать наплечники", 5, s=1, "Bounds pauldrons from Oblivion", c1=0, c2=0, nom=1, tik = function(e) e:triggerBoundArmor("bound_pauldron_left","bound_pauldron_right") end},

{610, "bolt", "Dummy bolt", 0.01, s=2, ss=6, "Dummy bolt", c0=0, c1=0, h=1, nod=1, nom=1, unr=1, ale=0, als=0, vfb = "VFX_DefaultBolt", vfa = G.VFXspark, sb = "Sound Test", tik = L.METTik, col = L.METCol},
{611, "kineticArrow", "Kinetic arrow", 3, s=0, ss=6, "Shoots a phantom arrow that deals physical damage", c0=0, c1=0, nod=1, unr=1, h=1, vfb = G.VFXarrow, vfa = G.VFXspark, vfh = G.VFXspark, sh = "Sound Test", sa = "Sound Test", tik = L.KArrowTik, col = L.KArrowCol},
{612, "kineticShotgun", "Kinetic burst", 15, s=0, ss=6, "Shoots a group of phantom arrows that deals physical damage", c0=0, c2=0, nod=1, vfa = G.VFXspark, vfh = G.VFXspark, sh = "Sound Test", sa = "Sound Test"},
{613, "kineticHail", "Kinetic hail", 30, s=0, ss=6, "Shoots a line of phantom arrows that deals physical damage", c0=0, c2=0, nod=1, vfa = G.VFXspark, vfh = G.VFXspark, sh = "Sound Test", sa = "Sound Test"},

{500, "teleport", "Teleport", 10, s=4, "Teleports caster to the point, indicated by him", c0=0, c1=0, nod=1, nom=1, sp=1.5, col = L.TeleportCol},
{501, "recharge", "Recharge", 10, s=4, "Restores charges of equipped magic items", ale=0},
{502, "repairWeapon", "Repair weapon", 5, s=0, "Repairing equipped weapon"},
{503, "repairArmor", "Repair armor", 3, s=0, "Repairing equipped armor"},
{504, "lightTarget", "Magic light", 0.1, s=0, "Creates a light, following a caster or attached to hit point", snd=3, vfx=3, col = L.LigCol},
{505, "teleportToTown", "Teleport to town", 1500, s=4, "Teleports the caster to the town", c1=0, c2=0, nod=1, nom=1, ale=0, tik = L.TownTP},
{506, "projectileControl", "Projectile control", 1, s=0, "Allows to control projectile flight", c1=0, c2=0, nom=1},
{507, "reflectSpell", "Reflect magic", 1, s=4, "Reflects enemy spells or neutralizes their power"},
{508, "kineticShield", "Kinetic shield", 1, s=0, "Absorbs physical damage, spending mana", vfh="VFX_ShieldHit", vfc="VFX_ShieldCast"},
{509, "lifeLeech", "Life leech", 0.5, s=4, "Heals for a portion of your physical damage"},
{510, "time_slow", "Time slow", 0.5, s=3, "Slows perception of time"},

{511, "charge_fire", "Charge fire", 1, s=4, ss=6, "Adds fire damage to attacks", snd=4},
{512, "charge_frost", "Charge frost", 1, s=4, ss=7, "Adds frost damage to attacks", snd=4},
{513, "charge_shock", "Charge shock", 1, s=4, ss=8, "Adds shock damage to attacks", snd=4},
{514, "charge_poison", "Charge poison", 1, s=4, ss=9, "Adds poison damage to attacks", snd=4},
{515, "charge_chaos", "Charge chaos", 1, s=4, ss=10, "Adds chaos damage to attacks", snd=4},
{614, "charge_force", "Charge force", 1, s=4, ss=0, "Adds physical damage to attacks", snd=4},

{516, "auraFire", "Aura fire", 6, s=2, ss=6, "Deals fire damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_FireShield"},
{517, "auraFrost", "Aura frost", 6, s=2, ss=7, "Deals frost damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_FrostShield"},
{518, "auraShock", "Aura shock", 6, s=2, ss=8, "Deals shock damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_LightningShield"},
{519, "auraPoison", "Aura poison", 10, s=2, ss=9, "Deals poison damage to all enemies around you", con=1, c1=0, c2=0},
{520, "auraVitality", "Aura chaos", 8, s=2, ss=10, "Deals chaos damage to all enemies around you", con=1, c1=0, c2=0, vfh="VFX_DestructHit"},

{521, "aoeFire", "Zone fire", 3, s=2, ss=6, "Deals fire damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{522, "aoeFrost", "Zone frost", 3, s=2, ss=7, "Deals frost damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{523, "aoeShock", "Zone shock", 3, s=2, ss=8, "Deals shock damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{524, "aoePoison", "Zone poison", 5, s=2, ss=9, "Deals poison damage to an area", c0=0, c1=0, h=1, col = AOEcol},
{525, "aoeVitality", "Zone chaos", 4, s=2, ss=10, "Deals chaos damage to an area", c0=0, c1=0, h=1, col = AOEcol},

{526, "runeFire", "Rune fire", 3, s=2, ss=6, "Creates fire rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{527, "runeFrost", "Rune frost", 3, s=2, ss=7, "Creates frost rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{528, "runeShock", "Rune shock", 3, s=2, ss=8, "Creates shock rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{529, "runePoison", "Rune poison", 5, s=2, ss=9, "Creates poison rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{530, "runeVitality", "Rune chaos", 4, s=2, ss=10, "Creates chaos rune, exploding when touched by enemy", c0=0, c1=0, h=1, col = RUNcol},
{618, "runeForce", "Rune force", 4, s=0, "Creates force rune, exploding when touched by enemy", c0=0, c1=0, nod=1, h=1, snd=6, col = RUNcol},

{531, "empower_fire", "Empower fire", 1, s=4, ss=6, "Adds fire blasts to your magic projectiles", snd=4},
{532, "empower_frost", "Empower frost", 1, s=4, ss=7, "Adds frost blasts to your magic projectiles", snd=4},
{533, "empower_shock", "Empower shock", 1, s=4, ss=8, "Adds shock blasts to your magic projectiles", snd=4},
{534, "empower_poison", "Empower poison", 1, s=4, ss=9, "Adds poison blasts to your magic projectiles", snd=4},
{535, "empower_chaos", "Empower chaos", 1, s=4, ss=10, "Adds chaos blasts to your magic projectiles", snd=4},
{615, "empower_force", "Empower force", 1, s=4, ss=0, "Adds physical blasts to your magic projectiles", snd=4},

{536, "shotgunFire", "Burst fire", 15, s=2, ss=6, "Shoots a group of fire balls", c0=0, c2=0},
{537, "shotgunFrost", "Burst frost", 15, s=2, ss=7, "Shoots a group of frost balls", c0=0, c2=0},
{538, "shotgunShock", "Burst shock", 15, s=2, ss=8, "Shoots a group of shock balls", c0=0, c2=0},
{539, "shotgunPoison", "Burst poison", 25, s=2, ss=9, "Shoots a group of poison balls", c0=0, c2=0},
{540, "shotgunVitality", "Burst chaos", 20, s=2, ss=10, "Shoots a group of chaos balls", c0=0, c2=0},

{541, "nova_fire", "Nova fire", 3, s=2, ss=6, "Explosion of fire strikes everyone around", c0=0, c2=0},
{542, "nova_frost", "Nova frost", 3, s=2, ss=7, "Explosion of frost strikes everyone around", c0=0, c2=0},
{543, "nova_shock", "Nova shock", 3, s=2, ss=8, "Explosion of lightning strikes everyone around", c0=0, c2=0},
{544, "nova_poison", "Nova poison", 5, s=2, ss=9, "Explosion of poison strikes everyone around", c0=0, c2=0},
{545, "nova_chaos", "Nova chaos", 4, s=2, ss=10, "Explosion of chaos strikes everyone around", c0=0, c2=0},
{616, "nova_force", "Nova force", 4, s=0, "Explosion of force strikes everyone around", c0=0, c2=0, nod=1},

{546, "rayFire", "Ray fire", 30, s=2, ss=6, "Fires a ray of fire", c0=0, c2=0},
{547, "rayFrost", "Ray frost", 30, s=2, ss=7, "Fires a ray of frost", c0=0, c2=0},
{548, "rayShock", "Ray shock", 30, s=2, ss=8, "Fires a ray of lightning", c0=0, c2=0},
{549, "rayPoison", "Ray poison", 50, s=2, ss=9, "Fires a ray of poison", c0=0, c2=0},
{550, "rayVitality", "Ray chaos", 40, s=2, ss=10, "Fires a ray of chaos magic", c0=0, c2=0},

{551, "totem_fire", "Totem fire", 0.5, s=4, ss=6, "Creates a totem that shoots fire at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{552, "totem_frost", "Totem frost", 0.5, s=4, ss=7, "Creates a totem that shoots frost at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{553, "totem_shock", "Totem shock", 0.5, s=4, ss=8, "Creates a totem that shoots lightning at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{554, "totem_poison", "Totem poison", 0.5, s=4, ss=9, "Creates a totem that shoots poison at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{555, "totem_chaos", "Totem chaos", 0.5, s=4, ss=10, "Creates a totem that shoots chaos balls at your enemies", c0=0, c1=0, h=1, col = TOTcol},
{619, "totem_force", "Totem force", 0.5, s=4, ss=0, "Creates a totem that shoots force balls at your enemies", c0=0, c1=0, h=1, snd=6, col = TOTcol},
{620, "totem_arrow", "Totem arrow", 0.5, s=4, ss=6, "Creates a totem that shoots kinetic arrows at your enemies", c0=0, c1=0, h=1, col = TOTcol},


--{556, "empowerFire", "Empower fire", 1, s=4, ss=6, "Empower your fire spells", snd=4},
--{557, "empowerFrost", "Empower frost", 1, s=4, ss=7, "Empower your frost spells", snd=4},
--{558, "empowerShock", "Empower shock", 1, s=4, ss=8, "Empower your shock spells", snd=4},
--{559, "empowerPoison", "Empower poison", 1, s=4, ss=9, "Empower your poison spells", snd=4},
--{560, "empowerVitality", "Empower chaos", 1, s=4, ss=10, "Empower your chaos damage spells", snd=4},

{561, "reflectFire", "Reflect fire", 1, s=4, ss=6, "Neutralizes the power of enemy fire spells", snd=4},
{562, "reflectFrost", "Reflect frost", 1, s=4, ss=7, "Neutralizes the power of enemy frost spells", snd=4},
{563, "reflectShock", "Reflect shock", 1, s=4, ss=8, "Neutralizes the power of enemy shock spells", snd=4},
{564, "reflectPoison", "Reflect poison", 1, s=4, ss=9, "Neutralizes the power of enemy poison spells", snd=4},
{565, "reflectVitality", "Reflect chaos", 1, s=4, ss=10, "Neutralizes the power of enemy chaos spells", snd=4},

{566, "waveFire", "Wave fire", 6, s=2, ss=6, "Launches a wave of fire, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.25, col = WAVcol},
{567, "waveFrost", "Wave frost", 6, s=2, ss=7, "Launches a wave of frost, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.25, col = WAVcol},
{568, "waveShock", "Wave shock", 6, s=2, ss=8, "Launches a wave of shock, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.25, col = WAVcol},
{569, "wavePoison", "Wave poison", 10, s=2, ss=9, "Launches a wave of poison, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.25, col = WAVcol},
{570, "waveVitality", "Wave chaos", 8, s=2, ss=10, "Launches a wave of chaos, damaging everyone within its zone", c0=0, c1=0, h=1, sp=0.25, col = WAVcol},
{617, "waveForce", "Wave force", 8, s=0, "Launches a wave of force, damaging everyone within its zone", c0=0, c1=0, nod=1, h=1, sp=0.25, col = WAVcol}}
for _,e in ipairs(MEN) do tes3.claimSpellEffectId(e[2], e[1])	tes3.addMagicEffect{id = e[1], name = e[3], baseCost = e[4], school = e.s, description = e[5] or e[3],
allowEnchanting = not e.ale, allowSpellmaking = not e.als, canCastSelf = not e.c0, canCastTarget = not e.c1, canCastTouch = not e.c2, isHarmful = not not e.h, hasNoDuration = not not e.nod, hasNoMagnitude = not not e.nom,
nonRecastable = not not e.nor, hasContinuousVFX = not not e.con, appliesOnce = not e.apo, unreflectable = not not e.unr, casterLinked = false, illegalDaedra = false, targetsAttributes = false, targetsSkills = false, usesNegativeLighting = false,
castSound = S[e.snd or e.ss or e.s].sc, boltSound = e.sb or S[e.snd or e.ss or e.s].sb, hitSound = e.sh or S[e.snd or e.ss or e.s].sh, areaSound = e.sa or S[e.snd or e.ss or e.s].sa,
castVFX = e.vfc or S[e.vfx or e.ss or e.s].vc, boltVFX = e.vfb or S[e.vfx or e.ss or e.s].vb, hitVFX = e.vfh or S[e.vfx or e.ss or e.s].vh, areaVFX = e.vfa or S[e.vfx or e.ss or e.s].va,
particleTexture = e.p or S[e.ss or e.s].p, icon = "s\\"..e[2]..".tga", speed = e.sp or 1, size = 1, sizeCap = 50, lighting = S[e.ss or e.s].l, onCollision = e.col or nil, onTick = e.tik or nil} end

local OBJ = {["potion_skooma_01"] = {[4]=510},	["4nm_star_shadow3a"] = {[7]=600},	["4nm_star_shadow1"] = {[2]=600}, ["4nm_star_shadow2"] = {[2]=600}, ["4nm_star_shadow3"] = {[2]=600},
["wizard's brand"] = {[2]=511, [3]=513},		["4nm_star_ritual3a"] = {[1]=501},
["reflect_20"] = {[1]=507},		["reflect_60"] = {[1]=507},

["4s_kinetic_strike_1"] = {[1]=602},	["4s_kinetic_strike_2"] = {[1]=602},	["4s_kinetic_strike_3"] = {[1]=602},
["4a_con1"] = {[2]=603,[7]=604,[8]=605},	["4a_alt1"] = {[3]=600},	["4a_alt3"] = {[1]=602},	["4a_mys3"] = {[2]=507},
["4e_bound_greaves"] = {[2]=600}, ["4e_bound_pauldron_left"] = {[1]=507}, ["4e_bound_pauldron_right"] = {[1]=508},
["bound cuirass_effects_en"] = {[1]=508,[2]=507},	["bound shield_effect_en"] = {[1]=508,[2]=507},		["bound helm_effect_en"] = {[2]=501},		--["bound gauntlet_left_effect_en"] = {[2]=501},
["ward of endus"] = {[2]=501,[3]=506},	["ward of odros"] = {[3]=600},		["ward of vemyn"] = {[2]=509},		["ward of gilvoth"] = {[3]=509},	["ward of tureynul"] = {[7]=507,[8]=508},
["ward of araynys"] = {[2]=501},		["ward of dagoth"] = {[3]=510,[4]=600},		["ward of uthol"] = {[3]=600},
["drakespride_en_uniq"] = {[6]=604,[7]=605},	["sc_lordmhasvengeance_en"] = {[2]=603,[7]=604,[8]=605},	["cephalopod_HTNK_en"] = {[4]=604,[5]=605},
["levitate_peakstar_en"] = {[2]=600}, 			["Wind Whisper"] = {[3]=600}, 			["Caius' Chameleon"] = {[2]=600}, 			["bm_amulspd"] = {[4]=600}, 				["wraithguard_en"] = {[1]=507,[2]=508},
["warlock's sphere"] = {[2]=507,[3]=600}, 		["watchful spirit"] = {[3]=508}, 		["hircine's blessing"] = {[2]=507},			["theranafeather_en_uniq"] = {[2]=508}, 	["Marara's Boon"] = {[2]=507,[3]=508},
["hort_ledd_shield"] = {[2]=507,[3]=508}, 		["will_en"] = {[2]=507},				["armor of god_en"] = {[1]=507,[2]=508}, 	["Spell Breaker"] = {[2]=507},				["dragon aura"] = {[2]=561},
["aryongloveright_en_unique"] = {[1]=603,[2]=511,[3]=512,[4]=513},		["aryongloveleft_en_unique"] = {[1]=506,[2]=531,[3]=532,[4]=533},
["tenpaceboots_en"] = {[2]=600},		["weight of the apostle"] = {[1]=600},		["black blindfold_en"] = {[2]=600},		["helseth_ring_en"] = {[1]=507,[2]=508},
["her curiass_EN"] = {[2]=508},		["her helm_EN"] = {[2]=507},	["darksun_en"] = {[2]=507},
["dahrk_mezalf_en_unique"] = {[1]=503},		["gem_feeding_en"] = {[1]=501},
["flamemirror robe_en"] = {[1]=561}, ["frostmirror robe_en"] = {[1]=562}, ["shockmirror robe_en"] = {[1]=563}, ["poisonmirror robe_en"] = {[1]=564},	["magickmirror robe_en"] = {[1]=565},

["Wrath of Magnus"] = {[2]=501},	["hasedoki's hand"] = {[2]=507},		["chrysamere_en"] = {[2]=507,[3]=561},		["bitter mercy"] = {[1]=507,[2]=508},
["mazedband"] = {[1]=505},		["aura of khajiit"] = {[6]=600},
["severedleg_en"] = {[1]=602},	["stendarr_hammer_en"] = {[1]=602},	 ["wizard's staff_en"] = {[1]=602},
}
for id, t in pairs(OBJ) do E = tes3.getObject(id).effects	for i, eid in pairs(t) do E[i].id = eid end end

-- Это не сработает. Для перерасчёта манакоста спелла его флаг автокалькуляции должен быть назвначен в КС.
--tes3.getObject("test_spell1").autoCalc = true		--tes3.getObject("test_en1").autoCalc = true


local scren
if cf.scroll then for b in tes3.iterateObjects(tes3.objectType.book) do if b.type == 1 then scren =	b.enchantment		if scren then 
	b.icon = ("scrolls\\tx_scroll_%s.dds"):format(scren.effects[1].id)		b.value = scren.chargeCost
	--mwse.log("%s  val = %s  cost = %s   valcost = %.3f", scren, b.value, scren.chargeCost, b.value/scren.chargeCost)
end end end end
mwse.memory.writeFunctionCall{address = 0x4D0CD5, length = 0x10, signature = {returns = "int"}, call = function() if P then return P.luc11 and 100 or math.max(tes3.player.object.level, 5) end end}
mwse.memory.writeBytes{address = 0x5C3B6C, bytes={0x90, 0x90, 0x90, 0x90, 0xD9, 0x44, 0x24, 0x10}} -- фикс стоимости зачарований
mwse.memory.writeNoOperation{address = 0x515203, length = 0x515215 - 0x515203}	-- убирает звук фейла зачарований
mwse.memory.writeFunctionCall{address = 0x515217, previousCall = 0x4A9F00, signature = {this = "tes3object", returns = "tes3object"}, call = function() end}	-- убирает звук фейла зачарований
mwse.memory.writeBytes{ address = 0x527BC0, bytes = { 0xC2, 0x04, 0x00 } }		-- Блок перерасчета стамины маны и нагрузки
mwse.memory.writeByte{address = 0x53E4DC, byte = 0xEB}		-- Отключает проверку перегруза при прыжке
mwse.memory.writeBytes{address=0x5593E1, bytes = {0xC8, 0x68, 0x74, 0}}			-- Дистанция подбегания для призыва теперь 7168 вместо 1024
--mwse.memory.writeBytes{address=0x5593E1, bytes = {0x54, 0x67, 0x74, 0}}		-- Дистанция подбегания для призыва теперь 4096 вместо 1024
mwse.memory.writeBytes{address = 0x51485F, bytes = {0xEB,0x04}}		-- Отключает вторую проверку дальности для спеллов касания
--mwse.memory.writeBytes{address = 0x5591A5, bytes = {0xEB, 0x05}}		-- При перепаде высоты нпс не убегают
mwse.memory.writeBytes{address=0x540B96, bytes={0x90,0xE9}}		-- Расчёт скорости движенимя для кричеров теперь как для нпс. Теперь все 3 события скорости за 1 фрейм для бега будут как для бега. Реальная скорсоть = e.speeed для всех
mwse.memory.writeBytes{address = 0x5290CA, bytes = {0xEB, 0x48}}	-- Разрешает начинать войсовер (например звуки боли) даже если актер вопроизводит в данный момент другой войсовер ИЛИ временный звук


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
mwse.memory.writeBytes{address = 0x54147A, bytes = { 0x8B, 0x90, 0x88, 0x03, 0, 0, 0x0A, 0x90, 0x28, 0x02, 0, 0, 0x85, 0xD2, 0x75, 0x04, 0x84, 0xDB, 0x75, 0x3D }}
mwse.memory.writeBytes{address = 0x5414B4, bytes = { 0xD9, 0x46, 0x20, 0xD8, 0x66, 0x18, 0xDE, 0xF9, 0xEB, 0x03 }}



-- Меняет звуковую шкалу	0x402A24 and 0x402E0B are int32s for the low limit of the volume level in dB		0x746480 is a float32 scaling factor for the volume (0-255) to dB. It's a negative number.
--originals (little endian) are FB F2 FF FF (int -3333) 	в конвеннтере	FFFFF2FB
--and 21 21 51 C1 (float -13.0706)  в конвертере C1512121
--mwse.memory.writeBytes{address = 0x402A24, bytes={0x78,0xEC}}	-- EC780000 = -327680000	нормально				E6380000 = -432537600 тихо
--mwse.memory.writeBytes{address = 0x402E0B, bytes={0x78,0xEC}}
--mwse.memory.writeBytes{address = 0x746480, bytes={0x00,0x00,0x98,0xC1}}		-- C1980000 = -19
--{0x00,0x00,0x9C,0xC1}} -- старый вариант = -19.5


--mwse.memory.writeNoOperation{ address = 0x5EC191, length = 0x5EC1A0 - 0x5EC191 }		mwse.memory.writeNoOperation{ address = 0x5EC1CE, length = 0x5EC1DC - 0x5EC1CE }		--Don't center world map
--mwse.memory.writeNoOperation{ address = 0x5EC051, length = 0x5EC065 - 0x5EC051 }		--Don't center local map



if cf.ft100 then
	mwse.memory.writeBytes{address=0x45371A, bytes={ 0xF4, 0x75, 0x74, 0}}			-- Set to 100ms
	mwse.memory.writeBytes{address=0x453728, bytes={ 0xCD, 0xCC, 0xCC, 0x3D}}
	--mwse.memory.writeBytes{address=0x45371A, bytes={ 0xCC, 0x6C, 0x74, 0}}		-- Reset to 200ms
	--mwse.memory.writeBytes{address=0x453728, bytes={ 0xCD, 0xCC, 0x4C, 0x3E}}
end



if cf.reb then		local t		--local t1 = {}		local c0 = os.clock()
	for o in tes3.iterateObjects{tes3.objectType.weapon, tes3.objectType.ammunition} do if not L.ESP[o.sourceMod] then t = L.WE[o.mesh:lower()]
		if t then o.value = t.v * (o.enchantment and (o.type < 11 and 2 or 1.5) or 1)	o.enchantCapacity = t.e		o.maxCondition = t.d	o.reach = t.r	o.weight = t.w		o.speed = t.s
			o.ignoresNormalWeaponResistance = t.ig == 1		o.chopMax = t.d1	o.slashMax = t.d2	o.thrustMax = t.d3		o.chopMin = t.m1	o.slashMin = t.m2	o.thrustMin = t.m3		--mwse.log("REPLACE!  %s", o.mesh:lower())
	--	else	if not t1[o.mesh:lower()] then mwse.log("%s					%s	%s	%s	%s", o.mesh:lower(), o.id, o.name, o.type, o.sourceMod)		t1[o.mesh:lower()] = true end
		end
	end end
	
--	t1 = {}
	for o in tes3.iterateObjects(tes3.objectType.armor) do if not L.ESP[o.sourceMod] then t = L.ARM[o.mesh:lower()]
		if t then o.value = t.v * (o.enchantment and 2 or 1)	o.enchantCapacity = t.e		o.maxCondition = t.d	o.weight = t.w		o.armorRating = t.ar		--mwse.log("REPLACE!  %s", o.mesh:lower())
	--	else 	if not t1[o.mesh:lower()] then mwse.log("%s		%s			%s	%s	%s", o.mesh:lower(), o.slot, o.id, o.name, o.sourceMod)	t1[o.mesh:lower()] = true end
		end
	end end

	for o in tes3.iterateObjects(tes3.objectType.clothing) do if not L.ESP[o.sourceMod] then o.enchantCapacity = L.CLEN[o.slot] end end
	
	for o in tes3.iterateObjects(tes3.objectType.repairItem) do t = L.REPA[o.id]	if t then o.weight = 10		o.quality = t.q		o.value = t.v	o.maxCondition = t.m
	--elseif not L.ESP[o.sourceMod] then mwse.log("%s			%s		%s		%s	%s	%s	%s", o.id, o.quality, o.maxCondition, o.value, o.name, o.weight, o.sourceMod)
	end end
	
--	tes3.messageBox("time  =   %d", (os.clock() - c0)*1000)		t1 = {}
--	for o in tes3.iterateObjects(tes3.objectType.creature) do if not L.CRNIF[o.mesh:lower()] then
--	 	if not t1[o.mesh:lower()] then mwse.log("%s			%s	%s	%s", o.mesh:lower(), o.id, o.name, o.sourceMod)	t1[o.mesh:lower()] = true end
--	end end
	
--	for o in tes3.iterateObjects(tes3.objectType.spell) do if not L.ESP[o.sourceMod] and o.autoCalc then
--	 	if not t1[o.id] then mwse.log("%s	%s	%s	%s", o.id, o.name, o.sourceMod, o.magickaCost)		t1[o.id] = true end
--	end end
end


--[[
local snum = 1	local fname
for dir in lfs.dir("data files\\sound\\4NM") do
	if not dir:startswith(".") then		snum = 1
		for file in lfs.dir("data files\\sound\\4NM\\" .. dir) do
			if file:endswith("wav") then
				fname = ("4NM\\%s\\%s"):format(dir,file)
				if string.len(fname) < 32 then
					SOT[fname] = tes3.createObject{objectType = tes3.objectType.sound, id = dir .. file, filename = fname}
					tes3.messageBox("%s\\%s", dir, file)		mwse.log("%s\\%s", dir, file)
					tes3.playSound{reference = p, sound = SOT[fname], volume = 0.5}
				end
			end
		end	
	end
end
tes3.playSound{reference = p, sound = SOT["4NM\\Metal2\\Parry" .. math.random(4) .. ".wav"], volume = 0.5, pitch = math.random(60,140)/100}
--]]

end		event.register("initialized", initialized)