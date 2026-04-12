-- Localization tables
local translations = {
	German = {
		-- Skill
		["Skill.name"] = "Bergbau",
		["Skill.desc"] = "Die Fertigkeit Bergbau bestimmt die Wirksamkeit beim Abbau von Erzen und Mineralien aus Gesteinsvorkommen. Erfahrene Bergleute bearbeiten Adern effizienter und gewinnen größere Mengen an Rohstoffen aus jeder Lagerstätte. Ein geübter Bergmann kann auch Vorkommen bearbeiten, an denen weniger erfahrene Schürfer scheitern würden.",

		-- Group names
		["Group.General"] = "Allgemein",
		["Group.Spawning"] = "Vorkommen",
		["Group.MiningYield"] = "Abbau & Ertrag",

		-- General
		["SWING_MINING.name"] = "Abbau durch Angriff",
		["SWING_MINING.desc"] = "Erze durch Waffenschwünge abbauen (wie beim Holzfällen) statt der zeitgesteuerten Methode\nSpitzhacken und Stumpfe Waffen sind ideal",
		["ASSISTED_MINING.name"] = "Unterstütztes Abbauen",
		["ASSISTED_MINING.desc"] = "In der dritten Person automatisch nahes Erz anvisieren\nDein Charakter dreht sich zum nächsten Erz vor dir\nDirektes Zielen hat immer Vorrang\nBenötigt Abbau durch Angriff und eine freie Kamera (z.B. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Bergbau-Fertigkeit verwenden",
		["USE_MINING_SKILL.desc"] = "Eine eigene Bergbau-Fertigkeit statt Schmieden für alle Berechnungen und Erfahrung verwenden\nBenötigt SkillFramework",
		["VOLUME.name"] = "Lautstärke (%)",
		["VOLUME.desc"] = "der Spitzhacke\nWerte über 100 wirken nur, wenn die allgemeine Effekt-Lautstärke unter 100% liegt",
		["UNINSTALL.name"] = "Deinstallieren",
		["UNINSTALL.desc"] = "Löscht alle gespawnten Erze und verhindert neue",

		-- Spawning
		["SPAWN_EXTERIOR.name"] = "Außenwelt erlauben",
		["SPAWN_EXTERIOR.desc"] = "Wenn deaktiviert, erscheinen Erze nur in Innenräumen",
		["ALLOW_CITIES.name"] = "Städte erlauben",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Sun's Dusk Innenraumfilter",
		["SUNS_DUSK_FILTER.desc"] = "Lässt Erze in Innenräumen nur in Höhlen und Minen erscheinen, auch wenn irgendwo ein felsiger Abschnitt ist",
		["SPAWN_COPPER.name"] = "Kupfer spawnen",
		["SPAWN_COPPER.desc"] = "Kupfererz in gespawnten Adern einbeziehen\nStandardmäßig deaktiviert, da die meisten Rezepte kein Kupfer verwenden",
		["INTERIOR_MULT.name"] = "Innen-Erz (%)",
		["INTERIOR_MULT.desc"] = "Menge skaliert mit der Gebietsgröße",
		["EXTERIOR_NODES.name"] = "Außen-Erze pro Zelle",
		["EXTERIOR_NODES.desc"] = "Wie viele Vorkommen im Durchschnitt?",
		["ORE_LEVEL_SCALING.name"] = "Erz-Stufenskalierung (%)",
		["ORE_LEVEL_SCALING.desc"] = "Erze näher an deiner Stufe erscheinen lassen\n 0 = normale Verteilung\n100 = stark auf deine Stufe ausgerichtet",
		["ORE_LOOT.name"] = "Beute in der Welt (%)",
		["ORE_LOOT.desc"] = "Verringert die Menge an herumliegendem Erz.\nImmerhin heißt der Mod Simply Mining und nicht Simply Looting...",

		-- Mining & Yield
		["MINING_DIFFICULTY.name"] = "Abbau-Schwierigkeit",
		["MINING_DIFFICULTY.desc"] = "0 = leicht, 100 = normal, 200 = schwer",
		["EXP_MULT.name"] = "Erfahrung (%)",
		["EXP_MULT.desc"] = "Wie viel Schmied- oder Bergbau-Erfahrung du erhältst",
		["YIELD_EQUALIZER.name"] = "Ertrags-Ausgleich (%)",
		["YIELD_EQUALIZER.desc"] = "Gleicht die Stufenskalierung aus, sodass du immer gleich viel Erz erhältst, auch ohne Fertigkeit",
		["YIELD_MULT.name"] = "Ertrag (%)",
		["YIELD_MULT.desc"] = "Vervielfacht die Menge an erhaltenem Erz",

		-- Slider labels
		["label.Silent"] = "Stumm",
		["label.Loud"] = "Laut",
		["label.None"] = "Keine",
		["label.Many"] = "Viele",
		["label.Random"] = "Zufällig",
		["label.Scaled"] = "Skaliert",
		["label.Full"] = "Voll",
		["label.Easy"] = "Leicht",
		["label.Hard"] = "Schwer",
		["label.Lots"] = "Viel",
		["label.Skill-based"] = "Fertigkeitsbasiert",
		["label.Flat"] = "Gleichmäßig",
		["unit.nodes"] = " Adern",
	},

	French = {
		["Skill.name"] = "Minage",
		["Skill.desc"] = "La compétence Minage régit l'extraction de minerais et de minéraux des gisements rocheux. Les mineurs expérimentés exploitent les filons plus efficacement, obtenant de plus grandes quantités de matières premières de chaque gisement. Un mineur chevronné peut aussi exploiter des gisements qui décourageraient des prospecteurs moins habiles.",

		["Group.General"] = "Général",
		["Group.Spawning"] = "Apparition",
		["Group.MiningYield"] = "Minage & Rendement",

		["SWING_MINING.name"] = "Minage par attaque",
		["SWING_MINING.desc"] = "Attaquer le minerai pour l'extraire (comme le bûcheronnage) au lieu de la méthode par minuterie\nLes pioches et armes contondantes sont idéales",
		["ASSISTED_MINING.name"] = "Minage assisté",
		["ASSISTED_MINING.desc"] = "Viser automatiquement le minerai proche en troisième personne\nVotre personnage se tourne vers le minerai le plus proche devant vous\nLa visée directe a toujours la priorité\nNécessite Minage par attaque et une caméra libre (ex. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Compétence Minage",
		["USE_MINING_SKILL.desc"] = "Utiliser une compétence Minage au lieu d'Armurerie pour tous les calculs et l'expérience\nNécessite SkillFramework",
		["VOLUME.name"] = "Volume (%)",
		["VOLUME.desc"] = "de la pioche\nLes valeurs au-dessus de 100 n'ont d'effet que si le volume Général x Effets est inférieur à 100%",
		["UNINSTALL.name"] = "Désinstaller",
		["UNINSTALL.desc"] = "Supprime tous les minerais générés et empêche d'en générer de nouveaux",

		["SPAWN_EXTERIOR.name"] = "Autoriser en extérieur",
		["SPAWN_EXTERIOR.desc"] = "Si désactivé, les minerais n'apparaissent qu'en intérieur",
		["ALLOW_CITIES.name"] = "Autoriser dans les villes",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Filtre d'intérieur Sun's Dusk",
		["SUNS_DUSK_FILTER.desc"] = "Les minerais d'intérieur n'apparaissent que dans les grottes et les mines, même s'il y a une section rocheuse quelque part",
		["SPAWN_COPPER.name"] = "Générer du cuivre",
		["SPAWN_COPPER.desc"] = "Inclure le minerai de cuivre dans les filons générés\nDésactivé par défaut car la plupart des recettes n'utilisent pas de cuivre",
		["INTERIOR_MULT.name"] = "Minerai intérieur (%)",
		["INTERIOR_MULT.desc"] = "La quantité varie selon la taille de la zone",
		["EXTERIOR_NODES.name"] = "Minerais extérieurs par cellule",
		["EXTERIOR_NODES.desc"] = "Combien de gisements en moyenne ?",
		["ORE_LEVEL_SCALING.name"] = "Adaptation au niveau (%)",
		["ORE_LEVEL_SCALING.desc"] = "Les minerais apparaissent plus près de votre niveau\n 0 = distribution normale\n100 = fortement adapté à votre niveau",
		["ORE_LOOT.name"] = "Butin dans le monde (%)",
		["ORE_LOOT.desc"] = "Réduit la quantité de minerai qui traîne.\nAprès tout, le mod s'appelle Simply Mining et non Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Difficulté de minage",
		["MINING_DIFFICULTY.desc"] = "0 = facile, 100 = normal, 200 = difficile",
		["EXP_MULT.name"] = "Expérience (%)",
		["EXP_MULT.desc"] = "Quantité d'expérience en Armurerie ou Minage reçue",
		["YIELD_EQUALIZER.name"] = "Égaliseur de rendement (%)",
		["YIELD_EQUALIZER.desc"] = "Aplatit l'adaptation au niveau pour toujours obtenir la même quantité, même sans la compétence",
		["YIELD_MULT.name"] = "Rendement (%)",
		["YIELD_MULT.desc"] = "Multiplie la quantité de minerai reçue",

		["label.Silent"] = "Muet",
		["label.Loud"] = "Fort",
		["label.None"] = "Aucun",
		["label.Many"] = "Beaucoup",
		["label.Random"] = "Aléatoire",
		["label.Scaled"] = "Adapté",
		["label.Full"] = "Maximum",
		["label.Easy"] = "Facile",
		["label.Hard"] = "Difficile",
		["label.Lots"] = "Beaucoup",
		["label.Skill-based"] = "Selon compétence",
		["label.Flat"] = "Uniforme",
		["unit.nodes"] = " filons",
	},

	Polish = {
		["Skill.name"] = "Górnictwo",
		["Skill.desc"] = "Umiejętność Górnictwo określa skuteczność wydobywania rud i minerałów ze złóż skalnych. Doświadczeni górnicy eksploatują żyły wydajniej, uzyskując większe ilości surowców z każdego złoża. Wprawny górnik potrafi też wydobywać ze złóż, które zniechęciłyby mniej wykwalifikowanych poszukiwaczy.",

		["Group.General"] = "Ogólne",
		["Group.Spawning"] = "Pojawianie się",
		["Group.MiningYield"] = "Wydobycie i Uzysk",

		["SWING_MINING.name"] = "Wydobycie atakiem",
		["SWING_MINING.desc"] = "Atakuj rudę bronią, by ją wydobyć (jak przy rąbaniu drewna), zamiast metody czasowej\nKilofy i broń obuchowa są idealne",
		["ASSISTED_MINING.name"] = "Wspomagane wydobycie",
		["ASSISTED_MINING.desc"] = "Automatycznie celuj w pobliską rudę w trzeciej osobie\nTwoja postać obraca się do najbliższej rudy przed tobą\nBezpośrednie celowanie ma zawsze priorytet\nWymaga Wydobycia atakiem i wolnej kamery (np. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Umiejętność Górnictwa",
		["USE_MINING_SKILL.desc"] = "Używa własnej umiejętności Górnictwa zamiast Płatnerstwa do wszystkich obliczeń i doświadczenia\nWymaga SkillFramework",
		["VOLUME.name"] = "Głośność (%)",
		["VOLUME.desc"] = "kilofa\nWartości powyżej 100 działają tylko gdy głośność Ogólne x Efekty jest poniżej 100%",
		["UNINSTALL.name"] = "Odinstaluj",
		["UNINSTALL.desc"] = "Usuwa wszystkie wygenerowane rudy i zapobiega tworzeniu nowych",

		["SPAWN_EXTERIOR.name"] = "Zezwól na zewnątrz",
		["SPAWN_EXTERIOR.desc"] = "Jeśli wyłączone, rudy pojawiają się tylko wewnątrz",
		["ALLOW_CITIES.name"] = "Zezwól w miastach",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Filtr wnętrz Sun's Dusk",
		["SUNS_DUSK_FILTER.desc"] = "Rudy wewnątrz budynków pojawiają się tylko w jaskiniach i kopalniach, nawet jeśli gdzieś jest skalista sekcja",
		["SPAWN_COPPER.name"] = "Generuj miedź",
		["SPAWN_COPPER.desc"] = "Uwzględnij rudę miedzi w generowanych żyłach\nDomyślnie wyłączone, ponieważ większość receptur nie używa miedzi",
		["INTERIOR_MULT.name"] = "Rudy wewnątrz (%)",
		["INTERIOR_MULT.desc"] = "Ilość skaluje się z wielkością obszaru",
		["EXTERIOR_NODES.name"] = "Rudy na zewnątrz na komórkę",
		["EXTERIOR_NODES.desc"] = "Ile złóż średnio?",
		["ORE_LEVEL_SCALING.name"] = "Skalowanie poziomu rud (%)",
		["ORE_LEVEL_SCALING.desc"] = "Rudy pojawiają się bliżej twojego poziomu\n 0 = normalny rozkład\n100 = silnie dostosowane do twojego poziomu",
		["ORE_LOOT.name"] = "Łup w świecie (%)",
		["ORE_LOOT.desc"] = "Zmniejsza ilość rudy leżącej w świecie.\nW końcu mod nazywa się Simply Mining, a nie Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Trudność wydobycia",
		["MINING_DIFFICULTY.desc"] = "0 = łatwe, 100 = normalne, 200 = trudne",
		["EXP_MULT.name"] = "Doświadczenie (%)",
		["EXP_MULT.desc"] = "Ile doświadczenia w Płatnerstwie lub Górnictwie otrzymujesz",
		["YIELD_EQUALIZER.name"] = "Wyrównanie uzysku (%)",
		["YIELD_EQUALIZER.desc"] = "Wyrównuje skalowanie poziomu, byś zawsze dostawał tyle samo rudy, nawet bez umiejętności",
		["YIELD_MULT.name"] = "Uzysk (%)",
		["YIELD_MULT.desc"] = "Mnoży ilość otrzymywanej rudy",

		["label.Silent"] = "Cisza",
		["label.Loud"] = "Głośno",
		["label.None"] = "Brak",
		["label.Many"] = "Dużo",
		["label.Random"] = "Losowo",
		["label.Scaled"] = "Skalowane",
		["label.Full"] = "Pełno",
		["label.Easy"] = "Łatwe",
		["label.Hard"] = "Trudne",
		["label.Lots"] = "Dużo",
		["label.Skill-based"] = "Wg umiejętności",
		["label.Flat"] = "Równo",
		["unit.nodes"] = " żył",
	},

	Russian = {
		["Skill.name"] = "Горное дело",
		["Skill.desc"] = "Навык Горное дело определяет умение добывать руду и минералы из горных пород. Опытные шахтёры разрабатывают жилы эффективнее, извлекая больше сырья из каждого месторождения. Искусный горняк способен разрабатывать залежи, которые поставили бы в тупик менее опытных старателей.",

		["Group.General"] = "Общее",
		["Group.Spawning"] = "Появление",
		["Group.MiningYield"] = "Добыча и Выход",

		["SWING_MINING.name"] = "Добыча атакой",
		["SWING_MINING.desc"] = "Атакуйте руду оружием для добычи (как при рубке дерева) вместо метода по таймеру\nКирки и дробящее оружие идеальны",
		["ASSISTED_MINING.name"] = "Помощь при добыче",
		["ASSISTED_MINING.desc"] = "Автоматически нацеливаться на ближайшую руду от третьего лица\nВаш персонаж поворачивается к ближайшей руде перед вами\nПрямое прицеливание всегда в приоритете\nТребуется Добыча атакой и свободная камера (напр. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Навык Горного дела",
		["USE_MINING_SKILL.desc"] = "Использовать навык Горного дела вместо Кузнеца для всех расчётов и опыта\nТребуется SkillFramework",
		["VOLUME.name"] = "Громкость (%)",
		["VOLUME.desc"] = "кирки\nЗначения выше 100 действуют только если громкость Общее x Эффекты ниже 100%",
		["UNINSTALL.name"] = "Удалить",
		["UNINSTALL.desc"] = "Удаляет все созданные руды и предотвращает появление новых",

		["SPAWN_EXTERIOR.name"] = "Разрешить снаружи",
		["SPAWN_EXTERIOR.desc"] = "Если отключено, руды появляются только внутри помещений",
		["ALLOW_CITIES.name"] = "Разрешить в городах",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Фильтр интерьеров Sun's Dusk",
		["SUNS_DUSK_FILTER.desc"] = "Руды в интерьерах появляются только в пещерах и шахтах, даже если где-то есть скалистый участок",
		["SPAWN_COPPER.name"] = "Генерировать медь",
		["SPAWN_COPPER.desc"] = "Включить медную руду в генерируемые жилы\nОтключено по умолчанию, так как большинство рецептов не используют медь",
		["INTERIOR_MULT.name"] = "Руды внутри (%)",
		["INTERIOR_MULT.desc"] = "Количество зависит от размера области",
		["EXTERIOR_NODES.name"] = "Руды снаружи на ячейку",
		["EXTERIOR_NODES.desc"] = "Сколько залежей в среднем?",
		["ORE_LEVEL_SCALING.name"] = "Масштаб. по уровню (%)",
		["ORE_LEVEL_SCALING.desc"] = "Руды появляются ближе к вашему уровню\n 0 = обычное распределение\n100 = сильно привязано к вашему уровню",
		["ORE_LOOT.name"] = "Добыча в мире (%)",
		["ORE_LOOT.desc"] = "Уменьшает количество руды, лежащей в мире.\nВ конце концов, мод называется Simply Mining, а не Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Сложность добычи",
		["MINING_DIFFICULTY.desc"] = "0 = легко, 100 = нормально, 200 = сложно",
		["EXP_MULT.name"] = "Опыт (%)",
		["EXP_MULT.desc"] = "Сколько опыта Кузнеца или Горного дела вы получаете",
		["YIELD_EQUALIZER.name"] = "Уравнитель выхода (%)",
		["YIELD_EQUALIZER.desc"] = "Выравнивает масштабирование по уровню, чтобы вы всегда получали одинаково руды, даже без навыка",
		["YIELD_MULT.name"] = "Выход (%)",
		["YIELD_MULT.desc"] = "Умножает количество получаемой руды",

		["label.Silent"] = "Тихо",
		["label.Loud"] = "Громко",
		["label.None"] = "Нет",
		["label.Many"] = "Много",
		["label.Random"] = "Случайно",
		["label.Scaled"] = "По уровню",
		["label.Full"] = "Полностью",
		["label.Easy"] = "Легко",
		["label.Hard"] = "Сложно",
		["label.Lots"] = "Много",
		["label.Skill-based"] = "По навыку",
		["label.Flat"] = "Равномерно",
		["unit.nodes"] = " жил",
	},

	Spanish = {
		["Skill.name"] = "Minería",
		["Skill.desc"] = "La habilidad Minería determina la eficacia al extraer menas y minerales de yacimientos rocosos. Los mineros expertos trabajan las vetas con mayor eficiencia, obteniendo mayores cantidades de materias primas de cada yacimiento. Un minero experimentado también puede explotar depósitos que frustrarían a prospectores menos hábiles.",

		["Group.General"] = "General",
		["Group.Spawning"] = "Aparición",
		["Group.MiningYield"] = "Minería y Rendimiento",

		["SWING_MINING.name"] = "Minería por ataque",
		["SWING_MINING.desc"] = "Ataca la mena con un arma para extraerla (como la tala) en lugar del método por temporizador\nPicos y armas contundentes son ideales",
		["ASSISTED_MINING.name"] = "Minería asistida",
		["ASSISTED_MINING.desc"] = "Apuntar automáticamente a mena cercana en tercera persona\nTu personaje gira hacia la mena más cercana frente a ti\nApuntar directamente siempre tiene prioridad\nRequiere Minería por ataque y una cámara libre (ej. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Habilidad de Minería",
		["USE_MINING_SKILL.desc"] = "Usa una habilidad de Minería propia en lugar de Armería para todos los cálculos y experiencia\nRequiere SkillFramework",
		["VOLUME.name"] = "Volumen (%)",
		["VOLUME.desc"] = "del pico\nValores superiores a 100 solo tienen efecto si el volumen General x Efectos está por debajo del 100%",
		["UNINSTALL.name"] = "Desinstalar",
		["UNINSTALL.desc"] = "Elimina todas las menas generadas e impide que aparezcan nuevas",

		["SPAWN_EXTERIOR.name"] = "Permitir en exteriores",
		["SPAWN_EXTERIOR.desc"] = "Si se desactiva, las menas solo aparecen en interiores",
		["ALLOW_CITIES.name"] = "Permitir en ciudades",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Filtro de interiores Sun's Dusk",
		["SUNS_DUSK_FILTER.desc"] = "Las menas de interiores solo aparecen en cuevas y minas, aunque haya secciones rocosas en otros lugares",
		["SPAWN_COPPER.name"] = "Generar cobre",
		["SPAWN_COPPER.desc"] = "Incluir mena de cobre en las vetas generadas\nDesactivado por defecto porque la mayoría de recetas no usan cobre",
		["INTERIOR_MULT.name"] = "Mena interior (%)",
		["INTERIOR_MULT.desc"] = "La cantidad varía según el tamaño del área",
		["EXTERIOR_NODES.name"] = "Menas exteriores por celda",
		["EXTERIOR_NODES.desc"] = "¿Cuántos yacimientos de media?",
		["ORE_LEVEL_SCALING.name"] = "Escalado por nivel (%)",
		["ORE_LEVEL_SCALING.desc"] = "Las menas aparecen más cerca de tu nivel\n 0 = distribución normal\n100 = muy sesgado hacia tu nivel",
		["ORE_LOOT.name"] = "Botín en el mundo (%)",
		["ORE_LOOT.desc"] = "Reduce la cantidad de mena suelta en el mundo.\nAl fin y al cabo, el mod se llama Simply Mining, no Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Dificultad de minería",
		["MINING_DIFFICULTY.desc"] = "0 = fácil, 100 = normal, 200 = difícil",
		["EXP_MULT.name"] = "Experiencia (%)",
		["EXP_MULT.desc"] = "Cuánta experiencia de Armería o Minería recibes",
		["YIELD_EQUALIZER.name"] = "Igualador de rendimiento (%)",
		["YIELD_EQUALIZER.desc"] = "Iguala el escalado por nivel para que siempre obtengas la misma cantidad, aunque no tengas la habilidad",
		["YIELD_MULT.name"] = "Rendimiento (%)",
		["YIELD_MULT.desc"] = "Multiplica la cantidad de mena recibida",

		["label.Silent"] = "Silencio",
		["label.Loud"] = "Alto",
		["label.None"] = "Nada",
		["label.Many"] = "Muchos",
		["label.Random"] = "Aleatorio",
		["label.Scaled"] = "Escalado",
		["label.Full"] = "Máximo",
		["label.Easy"] = "Fácil",
		["label.Hard"] = "Difícil",
		["label.Lots"] = "Mucho",
		["label.Skill-based"] = "Según habilidad",
		["label.Flat"] = "Uniforme",
		["unit.nodes"] = " vetas",
	},

	Italian = {
		["Skill.name"] = "Estrazione",
		["Skill.desc"] = "L'abilità Estrazione determina l'efficacia nell'estrarre minerali e gemme dai giacimenti rocciosi. I minatori esperti lavorano i filoni in modo più efficiente, ottenendo maggiori quantità di materie prime da ogni giacimento. Un minatore esperto può anche sfruttare depositi che scoraggerebbero cercatori meno abili.",

		["Group.General"] = "Generale",
		["Group.Spawning"] = "Comparsa",
		["Group.MiningYield"] = "Estrazione e Resa",

		["SWING_MINING.name"] = "Estrazione per attacco",
		["SWING_MINING.desc"] = "Attacca il minerale con un'arma per estrarlo (come il taglio del legno) invece del metodo a tempo\nPicconi e armi contundenti sono ideali",
		["ASSISTED_MINING.name"] = "Estrazione assistita",
		["ASSISTED_MINING.desc"] = "Punta automaticamente il minerale vicino in terza persona\nIl tuo personaggio si gira verso il minerale più vicino davanti a te\nMirare direttamente ha sempre la priorità\nRichiede Estrazione per attacco e una telecamera libera (es. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Abilità di Estrazione",
		["USE_MINING_SKILL.desc"] = "Usa un'abilità di Estrazione propria invece di Fabbro per tutti i calcoli e l'esperienza\nRichiede SkillFramework",
		["VOLUME.name"] = "Volume (%)",
		["VOLUME.desc"] = "del piccone\nValori superiori a 100 hanno effetto solo se il volume Generale x Effetti è inferiore al 100%",
		["UNINSTALL.name"] = "Disinstalla",
		["UNINSTALL.desc"] = "Elimina tutti i minerali generati e impedisce di generarne di nuovi",

		["SPAWN_EXTERIOR.name"] = "Consenti in esterni",
		["SPAWN_EXTERIOR.desc"] = "Se disattivato, i minerali appaiono solo in interni",
		["ALLOW_CITIES.name"] = "Consenti nelle città",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Filtro interni Sun's Dusk",
		["SUNS_DUSK_FILTER.desc"] = "I minerali negli interni appaiono solo in grotte e miniere, anche se c'è una sezione rocciosa altrove",
		["SPAWN_COPPER.name"] = "Genera rame",
		["SPAWN_COPPER.desc"] = "Includere il minerale di rame nelle vene generate\nDisattivato per impostazione predefinita perché la maggior parte delle ricette non usa rame",
		["INTERIOR_MULT.name"] = "Minerali interni (%)",
		["INTERIOR_MULT.desc"] = "La quantità varia in base alla dimensione dell'area",
		["EXTERIOR_NODES.name"] = "Minerali esterni per cella",
		["EXTERIOR_NODES.desc"] = "Quanti giacimenti in media?",
		["ORE_LEVEL_SCALING.name"] = "Adattamento al livello (%)",
		["ORE_LEVEL_SCALING.desc"] = "I minerali appaiono più vicini al tuo livello\n 0 = distribuzione normale\n100 = fortemente adattato al tuo livello",
		["ORE_LOOT.name"] = "Bottino nel mondo (%)",
		["ORE_LOOT.desc"] = "Riduce la quantità di minerale sparso nel mondo.\nDopotutto il mod si chiama Simply Mining, non Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Difficoltà di estrazione",
		["MINING_DIFFICULTY.desc"] = "0 = facile, 100 = normale, 200 = difficile",
		["EXP_MULT.name"] = "Esperienza (%)",
		["EXP_MULT.desc"] = "Quanta esperienza di Fabbro o Estrazione ricevi",
		["YIELD_EQUALIZER.name"] = "Equalizzatore di resa (%)",
		["YIELD_EQUALIZER.desc"] = "Appiattisce l'adattamento al livello così ottieni sempre la stessa quantità, anche senza l'abilità",
		["YIELD_MULT.name"] = "Resa (%)",
		["YIELD_MULT.desc"] = "Moltiplica la quantità di minerale ricevuto",

		["label.Silent"] = "Muto",
		["label.Loud"] = "Alto",
		["label.None"] = "Nessuno",
		["label.Many"] = "Molti",
		["label.Random"] = "Casuale",
		["label.Scaled"] = "Adattato",
		["label.Full"] = "Massimo",
		["label.Easy"] = "Facile",
		["label.Hard"] = "Difficile",
		["label.Lots"] = "Tanto",
		["label.Skill-based"] = "Secondo abilità",
		["label.Flat"] = "Uniforme",
		["unit.nodes"] = " filoni",
	},

	Hungarian = {
		["Skill.name"] = "Bányászat",
		["Skill.desc"] = "A Bányászat képesség az ércek és ásványok kőzetekből való kinyerését határozza meg. A tapasztalt bányászok hatékonyabban dolgozzák ki az ereket, több nyersanyagot nyerve ki minden lelőhelyből. Egy gyakorlott bányász olyan lelőhelyeket is ki tud aknázni, amelyek kevésbé képzett kutatókat elkesrítenének.",

		["Group.General"] = "Általános",
		["Group.Spawning"] = "Megjelenés",
		["Group.MiningYield"] = "Bányászat és Hozam",

		["SWING_MINING.name"] = "Bányászat támadással",
		["SWING_MINING.desc"] = "Támadással bányászd az ércet (mint a favágás) az időzítő alapú módszer helyett\nCsákányok és zúzó fegyverek ideálisak",
		["ASSISTED_MINING.name"] = "Segített bányászat",
		["ASSISTED_MINING.desc"] = "Automatikusan a közeli ércet célozd harmadik személyben\nA karaktered a legközelebbi érc felé fordul előtted\nA közvetlen célzás mindig elsőbbséget élvez\nSzükséges a Bányászat támadással és egy szabad kamera (pl. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Bányászat képesség",
		["USE_MINING_SKILL.desc"] = "Egyedi Bányászat képesség használata Kovácsolás helyett minden számításhoz és tapasztalathoz\nSkillFramework szükséges",
		["VOLUME.name"] = "Hangerő (%)",
		["VOLUME.desc"] = "a csákányé\nAz 100 feletti értékek csak akkor hatnak, ha az Általános x Hatás hangerő 100% alatt van",
		["UNINSTALL.name"] = "Eltávolítás",
		["UNINSTALL.desc"] = "Törli az összes létrehozott ércet és megakadályozza újak megjelenését",

		["SPAWN_EXTERIOR.name"] = "Engedélyezés kültéren",
		["SPAWN_EXTERIOR.desc"] = "Ha kikapcsolod, az ércek csak beltéren jelennek meg",
		["ALLOW_CITIES.name"] = "Engedélyezés városokban",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Sun's Dusk beltéri szűrő",
		["SUNS_DUSK_FILTER.desc"] = "A beltéri ércek csak barlangokban és bányákban jelennek meg, még ha máshol van is sziklás terület",
		["SPAWN_COPPER.name"] = "Réz generálása",
		["SPAWN_COPPER.desc"] = "Rézérc beépítése a generált erekben\nAlapértelmezetten kikapcsolva, mert a legtöbb recept nem használ rezet",
		["INTERIOR_MULT.name"] = "Belső érc (%)",
		["INTERIOR_MULT.desc"] = "A mennyiség a terület méretével arányos",
		["EXTERIOR_NODES.name"] = "Külső ércek cellánként",
		["EXTERIOR_NODES.desc"] = "Átlagosan hány lelőhely?",
		["ORE_LEVEL_SCALING.name"] = "Érc szintskálázás (%)",
		["ORE_LEVEL_SCALING.desc"] = "Az ércek a szintedhez közelebb jelennek meg\n 0 = normál eloszlás\n100 = erősen a szintedhez igazított",
		["ORE_LOOT.name"] = "Zsákmány a világban (%)",
		["ORE_LOOT.desc"] = "Csökkenti a szétszórt érc mennyiségét.\nElvégre a mod neve Simply Mining, nem Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Bányászat nehézsége",
		["MINING_DIFFICULTY.desc"] = "0 = könnyű, 100 = normál, 200 = nehéz",
		["EXP_MULT.name"] = "Tapasztalat (%)",
		["EXP_MULT.desc"] = "Mennyi Kovácsolás vagy Bányászat tapasztalatot kapsz",
		["YIELD_EQUALIZER.name"] = "Hozamkiegyenlítő (%)",
		["YIELD_EQUALIZER.desc"] = "Kiegyenlíti a szintskálázást, így mindig ugyanannyi ércet kapsz, képesség nélkül is",
		["YIELD_MULT.name"] = "Hozam (%)",
		["YIELD_MULT.desc"] = "Megsokszorozza a kapott érc mennyiségét",

		["label.Silent"] = "Néma",
		["label.Loud"] = "Hangos",
		["label.None"] = "Semmi",
		["label.Many"] = "Sok",
		["label.Random"] = "Véletlenszerű",
		["label.Scaled"] = "Skálázott",
		["label.Full"] = "Teljes",
		["label.Easy"] = "Könnyű",
		["label.Hard"] = "Nehéz",
		["label.Lots"] = "Sok",
		["label.Skill-based"] = "Képesség szerint",
		["label.Flat"] = "Egyenletes",
		["unit.nodes"] = " ér",
	},

	Czech = {
		["Skill.name"] = "Hornictví",
		["Skill.desc"] = "Dovednost Hornictví určuje účinnost při těžbě rud a nerostů ze skalních ložisek. Zkušení horníci zpracovávají žíly efektivněji a získávají větší množství surovin z každého ložiska. Zdatný horník dokáže vytěžit i ložiska, která by méně zkušené hledače odradila.",

		["Group.General"] = "Obecné",
		["Group.Spawning"] = "Výskyt",
		["Group.MiningYield"] = "Těžba a Výtěžek",

		["SWING_MINING.name"] = "Těžba útokem",
		["SWING_MINING.desc"] = "Útočte na rudu zbraní k těžbě (jako při kácení) místo metody na čas\nKrumpáče a úderné zbraně jsou ideální",
		["ASSISTED_MINING.name"] = "Asistovaná těžba",
		["ASSISTED_MINING.desc"] = "Automaticky zaměřit blízkou rudu ve třetí osobě\nVaše postava se otočí k nejbližší rudě před vámi\nPřímé míření má vždy přednost\nVyžaduje Těžbu útokem a volnou kameru (např. \"Combat360\")",
		["USE_MINING_SKILL.name"] = "Dovednost Hornictví",
		["USE_MINING_SKILL.desc"] = "Použít vlastní dovednost Hornictví místo Zbrojířství pro všechny výpočty a zkušenosti\nVyžaduje SkillFramework",
		["VOLUME.name"] = "Hlasitost (%)",
		["VOLUME.desc"] = "krumpáče\nHodnoty nad 100 mají účinek jen pokud je hlasitost Obecné x Efekty pod 100%",
		["UNINSTALL.name"] = "Odinstalovat",
		["UNINSTALL.desc"] = "Smaže všechny vytvořené rudy a zabrání vytváření nových",

		["SPAWN_EXTERIOR.name"] = "Povolit venku",
		["SPAWN_EXTERIOR.desc"] = "Pokud vypnuto, rudy se objevují pouze uvnitř",
		["ALLOW_CITIES.name"] = "Povolit ve městech",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Filtr interiérů Sun's Dusk",
		["SUNS_DUSK_FILTER.desc"] = "Rudy v interiérech se objevují pouze v jeskyních a dolech, i když je jinde skalnatá sekce",
		["SPAWN_COPPER.name"] = "Generovat měď",
		["SPAWN_COPPER.desc"] = "Zahrnout měděnou rudu do generovaných žil\nVe výchozím nastavení vypnuto, protože většina receptů měď nepoužívá",
		["INTERIOR_MULT.name"] = "Rudy uvnitř (%)",
		["INTERIOR_MULT.desc"] = "Množství závisí na velikosti oblasti",
		["EXTERIOR_NODES.name"] = "Rudy venku na buňku",
		["EXTERIOR_NODES.desc"] = "Kolik ložisek průměrně?",
		["ORE_LEVEL_SCALING.name"] = "Škálování dle úrovně (%)",
		["ORE_LEVEL_SCALING.desc"] = "Rudy se objevují blíže vaší úrovni\n 0 = normální rozložení\n100 = silně přizpůsobeno vaší úrovni",
		["ORE_LOOT.name"] = "Kořist ve světě (%)",
		["ORE_LOOT.desc"] = "Snižuje množství rudy ležící ve světě.\nKoneckonců se mod jmenuje Simply Mining, ne Simply Looting...",

		["MINING_DIFFICULTY.name"] = "Obtížnost těžby",
		["MINING_DIFFICULTY.desc"] = "0 = snadné, 100 = normální, 200 = těžké",
		["EXP_MULT.name"] = "Zkušenosti (%)",
		["EXP_MULT.desc"] = "Kolik zkušeností ve Zbrojířství nebo Hornictví získáte",
		["YIELD_EQUALIZER.name"] = "Vyrovnání výtěžku (%)",
		["YIELD_EQUALIZER.desc"] = "Vyrovná škálování dle úrovně, takže vždy získáte stejně rudy, i bez dovednosti",
		["YIELD_MULT.name"] = "Výtěžek (%)",
		["YIELD_MULT.desc"] = "Násobí množství získané rudy",

		["label.Silent"] = "Ticho",
		["label.Loud"] = "Hlasitě",
		["label.None"] = "Žádné",
		["label.Many"] = "Hodně",
		["label.Random"] = "Náhodně",
		["label.Scaled"] = "Škálované",
		["label.Full"] = "Plně",
		["label.Easy"] = "Snadné",
		["label.Hard"] = "Těžké",
		["label.Lots"] = "Hodně",
		["label.Skill-based"] = "Dle dovednosti",
		["label.Flat"] = "Rovnoměrně",
		["unit.nodes"] = " žil",
	},

	Japanese = {
		["Skill.name"] = "採掘",
		["Skill.desc"] = "採掘スキルは、岩石から鉱石や鉱物を採取する能力を決定する。熟練した鉱夫は鉱脈をより効率的に掘り、各鉱床からより多くの原料を得ることができる。経験豊富な鉱夫は、未熟な探鉱者では手に負えない鉱床も採掘できる。",

		["Group.General"] = "全般",
		["Group.Spawning"] = "出現",
		["Group.MiningYield"] = "採掘と収量",

		["SWING_MINING.name"] = "攻撃で採掘",
		["SWING_MINING.desc"] = "タイマー方式の代わりに武器で鉱石を攻撃して採掘する（伐採と同様）\nつるはしや鈍器が最適",
		["ASSISTED_MINING.name"] = "採掘アシスト",
		["ASSISTED_MINING.desc"] = "三人称視点で自動的に近くの鉱石を狙う\nキャラクターが正面の最も近い鉱石に向きを変える\n直接照準は常に優先される\n攻撃で採掘とフリーカメラ（例：\"Combat360\"）が必要",
		["USE_MINING_SKILL.name"] = "採掘スキルを使用",
		["USE_MINING_SKILL.desc"] = "鎧製造の代わりに独自の採掘スキルをすべての計算と経験値に使用する\nSkillFrameworkが必要",
		["VOLUME.name"] = "音量 (%)",
		["VOLUME.desc"] = "つるはしの音量\n100以上の値は全般×効果の音量が100%未満の場合のみ有効",
		["UNINSTALL.name"] = "アンインストール",
		["UNINSTALL.desc"] = "生成されたすべての鉱石を削除し、新たな生成を防止する",

		["SPAWN_EXTERIOR.name"] = "屋外での出現を許可",
		["SPAWN_EXTERIOR.desc"] = "無効にすると、鉱石は屋内にのみ出現する",
		["ALLOW_CITIES.name"] = "都市での出現を許可",
		["ALLOW_CITIES.desc"] = "",
		["SUNS_DUSK_FILTER.name"] = "Sun's Dusk 室内フィルター",
		["SUNS_DUSK_FILTER.desc"] = "室内の鉱石を洞窟と鉱山にのみ出現させる（岩場があっても他の室内には出現しない）",
		["SPAWN_COPPER.name"] = "銅を生成",
		["SPAWN_COPPER.desc"] = "生成される鉱脈に銅鉱石を含める\nほとんどのレシピで銅を使用しないため、デフォルトでは無効",
		["INTERIOR_MULT.name"] = "屋内鉱石 (%)",
		["INTERIOR_MULT.desc"] = "量はエリアの大きさに応じて変動する",
		["EXTERIOR_NODES.name"] = "セルあたりの屋外鉱石",
		["EXTERIOR_NODES.desc"] = "平均いくつの鉱床？",
		["ORE_LEVEL_SCALING.name"] = "鉱石レベル調整 (%)",
		["ORE_LEVEL_SCALING.desc"] = "鉱石がプレイヤーのレベルに近く出現する\n 0 = 通常分布\n100 = レベルに強く偏る",
		["ORE_LOOT.name"] = "世界の戦利品 (%)",
		["ORE_LOOT.desc"] = "世界に散らばる鉱石の量を減らす\nModの名前はSimply Miningであり、Simply Lootingではない...",

		["MINING_DIFFICULTY.name"] = "採掘難易度",
		["MINING_DIFFICULTY.desc"] = "0 = 簡単、100 = 普通、200 = 難しい",
		["EXP_MULT.name"] = "経験値 (%)",
		["EXP_MULT.desc"] = "鎧製造または採掘の経験値の量",
		["YIELD_EQUALIZER.name"] = "収量均等化 (%)",
		["YIELD_EQUALIZER.desc"] = "レベル調整を平坦にし、スキルがなくても常に同量の鉱石を得られる",
		["YIELD_MULT.name"] = "収量 (%)",
		["YIELD_MULT.desc"] = "得られる鉱石の量を倍増させる",

		["label.Silent"] = "無音",
		["label.Loud"] = "大音量",
		["label.None"] = "なし",
		["label.Many"] = "多い",
		["label.Random"] = "ランダム",
		["label.Scaled"] = "調整",
		["label.Full"] = "最大",
		["label.Easy"] = "簡単",
		["label.Hard"] = "難しい",
		["label.Lots"] = "大量",
		["label.Skill-based"] = "スキル依存",
		["label.Flat"] = "均等",
		["unit.nodes"] = " 鉱脈",
	},

}

local function detectLanguage()

    local adventurer = core.getGMST("sCustomClassName")
	--print("TEST1: '"..adventurer.."'")
	
    local yes = core.getGMST("sYes")
	--print("TEST2: '"..yes.."'")
	
    if adventurer == "Aventurier" then return "French"
    elseif adventurer == "Abenteurer" then return "German"
    elseif adventurer == "Poszukiwacz przygód" then return "Polish"
    elseif adventurer == "Авантюрист" then return "Russian"
    elseif adventurer == "Aventurero" then return "Spanish"
    elseif adventurer == "Avventuriero" then return "Italian"
    elseif adventurer == "Kalandozó" then return "Hungarian"
    elseif adventurer == "Dobrodruh" then return "Czech"
    elseif adventurer == "冒険者" then return "Japanese"
    elseif adventurer == "Adventurer" then return "English"
    end
	
    -- fallback
    if yes == "Oui" then return "French"
    elseif yes == "Ja" then return "German"
    elseif yes == "Tak" then return "Polish"
    elseif yes == "Да" then return "Russian"
    elseif yes == "Sí" then return "Spanish"
    elseif yes == "Sì" then return "Italian"
    elseif yes == "Igen" then return "Hungarian"
    elseif yes == "Ano" then return "Czech"
    elseif yes == "はい" then return "Japanese"
    end
	
    return "English"
end

local language = detectLanguage()
LOCALIZATION_FOUND = translations[language] and true or false

-- getting the setting before the settings load
local tempSection = storage.playerSection('SettingsPlayer'..MODNAME.."General")
local tempValue = tempSection:get("USE_TRANSLATIONS")
S_USE_TRANSLATIONS = tempValue == nil or tempValue


function L(key, fallback)
	local language = S_USE_TRANSLATIONS and language or "English"
	local lang = translations[language]
	if lang and lang[key] then
		return lang[key]
	end
	return fallback or key
end