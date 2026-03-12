-- Localization tables
local translations = {
	German = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Zeigt Uhrzeit, Datum und (nur für Sun's Dusk Fans) Temperatur\n- Klicken & Ziehen zum Verschieben\n- Klicken & Mausrad für Größe\n- Klicken & Shift+Mausrad für Transparenz",
		
		-- Settings sections
		["settings.timedate"] = "Zeit & Datum",
		["settings.sunsdusk"] = "Sun's Dusk Fans",
		
		-- Settings - Language
		["settings.language"] = "Sprache",
		["settings.language.desc"] = "Wähle deine Sprache. Die Einstellungen werden nach dem Neustart aktualisiert.",
		
		-- Settings - HUD
		["settings.hud.display"] = "HUD Anzeige",
		["settings.hud.display.desc"] = "Wann soll das HUD angezeigt werden? Interface = wenn Menüs offen sind",
		["settings.lock"] = "Position fixieren",
		["settings.pos.x"] = "X-Position",
		["settings.pos.y"] = "Y-Position",
		["settings.exterior"] = "Zeit nur draußen anzeigen",
		
		-- Settings - Font
		["settings.font.size"] = "Schriftgröße",
		["settings.font.size.desc"] = "Schrift größer oder kleiner machen.\nStandard: 23",
		["settings.text.color"] = "Textfarbe",
		["settings.text.color.desc"] = "Ändere die Textfarbe.\nStandard: caa560 ; dfc99f\nBlau: 81CDED",
		["settings.bg.opacity"] = "Hintergrund-Transparenz",
		["settings.bg.opacity.desc"] = "Hintergrund durchsichtiger oder solider machen.\n0-1, Standard: 0.5",
		["settings.text.align"] = "Textausrichtung",
		["settings.text.align.desc"] = "Zeit und Datum ausrichten.\nStandard: links",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Uhr-Intervall",
		["settings.clock.interval.desc"] = "Uhr alle x Spielminuten aktualisieren.\nStandard: 15",
		["settings.time.format"] = "Zeitformat",
		
		-- Settings - Date
		["settings.date.show"] = "Datum anzeigen",
		["settings.date.show.desc"] = "Verschiedene Anzeigeformate für das Datum.",
		["settings.date.top"] = "Datum oben",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Temperatur-Anzeige",
		["settings.temp.state"] = "Temperaturzustand anzeigen",
		["settings.temp.state.desc"] = "Zeigt ob es eisig, kalt, kühl, angenehm, warm, heiß oder sengend heiß ist",
		
		-- Time of day
		["time.dawn"] = "Morgengrauen",
		["time.morning"] = "Morgen",
		["time.noon"] = "Mittag",
		["time.afternoon"] = "Nachmittag",
		["time.evening"] = "Abend",
		["time.dusk"] = "Dämmerung",
		["time.night"] = "Nacht",
		["time.midnight"] = "Mitternacht",
		
		-- Temperature states
		["temp.freezing"] = "Eisig",
		["temp.cold"] = "Kalt",
		["temp.chilly"] = "Kühl",
		["temp.comfortable"] = "Angenehm",
		["temp.warm"] = "Warm",
		["temp.hot"] = "Heiß",
		["temp.scorching"] = "Sengend heiß",
		
	},
	
	French = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Affiche l'heure, la date et (fans de Sun's Dusk seulement) la température\n- Clique et déplace pour bouger\n- Clique et molette pour la taille\n- Clique et Shift+molette pour la transparence",
		
		-- Settings sections
		["settings.timedate"] = "Heure & Date",
		["settings.sunsdusk"] = "Fans de Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Langue",
		["settings.language.desc"] = "Choisis ta langue. Les paramètres seront mis à jour après le redémarrage.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Affichage HUD",
		["settings.hud.display.desc"] = "Quand afficher le HUD ? Interface = quand les menus sont ouverts",
		["settings.lock"] = "Verrouiller la position",
		["settings.pos.x"] = "Position X",
		["settings.pos.y"] = "Position Y",
		["settings.exterior"] = "Afficher l'heure uniquement en extérieur",
		
		-- Settings - Font
		["settings.font.size"] = "Taille du texte",
		["settings.font.size.desc"] = "Agrandir ou réduire le texte.\nPar défaut : 23",
		["settings.text.color"] = "Couleur du texte",
		["settings.text.color.desc"] = "Change la couleur du texte.\nPar défaut : caa560 ; dfc99f\nBleu : 81CDED",
		["settings.bg.opacity"] = "Transparence du fond",
		["settings.bg.opacity.desc"] = "Rendre le fond plus ou moins opaque.\n0-1, par défaut : 0.5",
		["settings.text.align"] = "Alignement du texte",
		["settings.text.align.desc"] = "Aligner l'heure et la date.\nPar défaut : gauche",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Intervalle de l'horloge",
		["settings.clock.interval.desc"] = "Mettre à jour l'horloge toutes les x minutes (en jeu).\nPar défaut : 15",
		["settings.time.format"] = "Format de l'heure",
		
		-- Settings - Date
		["settings.date.show"] = "Afficher la date",
		["settings.date.show.desc"] = "Différents formats d'affichage pour la date.",
		["settings.date.top"] = "Date en haut",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Affichage température",
		["settings.temp.state"] = "Afficher l'état de température",
		["settings.temp.state.desc"] = "Affiche s'il fait glacial, froid, frais, confortable, chaud, très chaud ou brûlant",
		
		-- Time of day
		["time.dawn"] = "Aube",
		["time.morning"] = "Matin",
		["time.noon"] = "Midi",
		["time.afternoon"] = "Après-midi",
		["time.evening"] = "Soir",
		["time.dusk"] = "Crépuscule",
		["time.night"] = "Nuit",
		["time.midnight"] = "Minuit",
		
		-- Temperature states
		["temp.freezing"] = "Gelé",
		["temp.cold"] = "Froid",
		["temp.chilly"] = "Frais",
		["temp.comfortable"] = "Confortable",
		["temp.warm"] = "Chaud",
		["temp.hot"] = "Très chaud",
		["temp.scorching"] = "Brûlant",
		
	},
	
	Russian = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Показывает время, дату и (только для фанов Sun's Dusk) температуру\n- Клик и перетаскивание для перемещения\n- Клик и колёсико для размера\n- Клик и Shift+колёсико для прозрачности",
		
		-- Settings sections
		["settings.timedate"] = "Время и дата",
		["settings.sunsdusk"] = "Фаны Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Язык",
		["settings.language.desc"] = "Выбери свой язык. Настройки обновятся после перезапуска.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Показ HUD",
		["settings.hud.display.desc"] = "Когда показывать HUD? Интерфейс = когда открыты меню",
		["settings.lock"] = "Зафиксировать позицию",
		["settings.pos.x"] = "Позиция X",
		["settings.pos.y"] = "Позиция Y",
		["settings.exterior"] = "Показывать время только на улице",
		
		-- Settings - Font
		["settings.font.size"] = "Размер шрифта",
		["settings.font.size.desc"] = "Увеличить или уменьшить шрифт.\nПо умолчанию: 23",
		["settings.text.color"] = "Цвет текста",
		["settings.text.color.desc"] = "Изменить цвет текста.\nПо умолчанию: caa560 ; dfc99f\nСиний: 81CDED",
		["settings.bg.opacity"] = "Прозрачность фона",
		["settings.bg.opacity.desc"] = "Сделать фон более или менее прозрачным.\n0-1, по умолчанию: 0.5",
		["settings.text.align"] = "Выравнивание текста",
		["settings.text.align.desc"] = "Выровнять время и дату.\nПо умолчанию: слева",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Интервал часов",
		["settings.clock.interval.desc"] = "Обновлять часы каждые x минут (игровых).\nПо умолчанию: 15",
		["settings.time.format"] = "Формат времени",
		
		-- Settings - Date
		["settings.date.show"] = "Показать дату",
		["settings.date.show.desc"] = "Разные форматы отображения даты.",
		["settings.date.top"] = "Дата сверху",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Показ температуры",
		["settings.temp.state"] = "Показать состояние температуры",
		["settings.temp.state.desc"] = "Показывает состояние: обморожение, холодно, прохладно, комфортно, тепло, жарко или палящий зной",
		
		-- Time of day
		["time.dawn"] = "Рассвет",
		["time.morning"] = "Утро",
		["time.noon"] = "Полдень",
		["time.afternoon"] = "День",
		["time.evening"] = "Вечер",
		["time.dusk"] = "Сумерки",
		["time.night"] = "Ночь",
		["time.midnight"] = "Полночь",
		
		-- Temperature states
		["temp.freezing"] = "Обморожение",
		["temp.cold"] = "Холодно",
		["temp.chilly"] = "Прохладно",
		["temp.comfortable"] = "Комфортно",
		["temp.warm"] = "Тепло",
		["temp.hot"] = "Жарко",
		["temp.scorching"] = "Палящий",
		
	},
	
	Polish = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Pokazuje czas, datę i (tylko dla fanów Sun's Dusk) temperaturę\n- Kliknij i przeciągnij aby przesunąć\n- Kliknij i kółko myszy dla rozmiaru\n- Kliknij i Shift+kółko dla przezroczystości",
		
		-- Settings sections
		["settings.timedate"] = "Czas i data",
		["settings.sunsdusk"] = "Fani Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Język",
		["settings.language.desc"] = "Wybierz swój język. Ustawienia zaktualizują się po restarcie.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Wyświetlanie HUD",
		["settings.hud.display.desc"] = "Kiedy pokazywać HUD? Interfejs = gdy menu są otwarte",
		["settings.lock"] = "Zablokuj pozycję",
		["settings.pos.x"] = "Pozycja X",
		["settings.pos.y"] = "Pozycja Y",
		["settings.exterior"] = "Pokazuj czas tylko na zewnątrz",
		
		-- Settings - Font
		["settings.font.size"] = "Rozmiar czcionki",
		["settings.font.size.desc"] = "Zwiększ lub zmniejsz czcionkę.\nDomyślnie: 23",
		["settings.text.color"] = "Kolor tekstu",
		["settings.text.color.desc"] = "Zmień kolor tekstu.\nDomyślnie: caa560 ; dfc99f\nNiebieski: 81CDED",
		["settings.bg.opacity"] = "Przezroczystość tła",
		["settings.bg.opacity.desc"] = "Zmień przezroczystość tła.\n0-1, domyślnie: 0.5",
		["settings.text.align"] = "Wyrównanie tekstu",
		["settings.text.align.desc"] = "Wyrównaj czas i datę.\nDomyślnie: lewo",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Interwał zegara",
		["settings.clock.interval.desc"] = "Aktualizuj zegar co x minut (w grze).\nDomyślnie: 15",
		["settings.time.format"] = "Format czasu",
		
		-- Settings - Date
		["settings.date.show"] = "Pokaż datę",
		["settings.date.show.desc"] = "Różne formaty wyświetlania daty.",
		["settings.date.top"] = "Data na górze",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Wyświetlanie temperatury",
		["settings.temp.state"] = "Wyświetl stan temperatury",
		["settings.temp.state.desc"] = "Pokazuje czy jest lodowato, zimno, chłodno, komfortowo, ciepło, gorąco czy upalnie",
		
		-- Time of day
		["time.dawn"] = "Świt",
		["time.morning"] = "Ranek",
		["time.noon"] = "Południe",
		["time.afternoon"] = "Popołudnie",
		["time.evening"] = "Wieczór",
		["time.dusk"] = "Zmierzch",
		["time.night"] = "Noc",
		["time.midnight"] = "Północ",
		
		-- Temperature states
		["temp.freezing"] = "Lodowaty",
		["temp.cold"] = "Zimno",
		["temp.chilly"] = "Chłodno",
		["temp.comfortable"] = "Komfortowo",
		["temp.warm"] = "Ciepło",
		["temp.hot"] = "Gorąco",
		["temp.scorching"] = "Upalnie",
		
	},
	
	Hungarian = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Megjeleníti az időt, dátumot és (csak Sun's Dusk rajongóknak) hőmérsékletet\n- Kattints és húzd el a mozgatáshoz\n- Kattints és görgess a mérethez\n- Kattints és Shift+görgess az átlátszósághoz",
		
		-- Settings sections
		["settings.timedate"] = "Idő és dátum",
		["settings.sunsdusk"] = "Sun's Dusk rajongók",
		
		-- Settings - Language
		["settings.language"] = "Nyelv",
		["settings.language.desc"] = "Válaszd ki a nyelvet. A beállítások újraindítás után frissülnek.",
		
		-- Settings - HUD
		["settings.hud.display"] = "HUD megjelenítés",
		["settings.hud.display.desc"] = "Mikor jelenjen meg a HUD? Felület = amikor menük nyitva vannak",
		["settings.lock"] = "Pozíció rögzítése",
		["settings.pos.x"] = "X pozíció",
		["settings.pos.y"] = "Y pozíció",
		["settings.exterior"] = "Idő megjelenítése csak kint",
		
		-- Settings - Font
		["settings.font.size"] = "Betűméret",
		["settings.font.size.desc"] = "Betűméret nagyítása vagy kicsinyítése.\nAlapértelmezett: 23",
		["settings.text.color"] = "Szöveg színe",
		["settings.text.color.desc"] = "Szöveg színének megváltoztatása.\nAlapértelmezett: caa560 ; dfc99f\nKék: 81CDED",
		["settings.bg.opacity"] = "Háttér átlátszósága",
		["settings.bg.opacity.desc"] = "Háttér átlátszóságának változtatása.\n0-1, alapértelmezett: 0.5",
		["settings.text.align"] = "Szöveg igazítása",
		["settings.text.align.desc"] = "Idő és dátum igazítása.\nAlapértelmezett: bal",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Óra frissítési intervallum",
		["settings.clock.interval.desc"] = "Óra frissítése x játékpercenként.\nAlapértelmezett: 15",
		["settings.time.format"] = "Időformátum",
		
		-- Settings - Date
		["settings.date.show"] = "Dátum megjelenítése",
		["settings.date.show.desc"] = "Különböző formátumok a dátum megjelenítéséhez.",
		["settings.date.top"] = "Dátum felül",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Hőmérséklet megjelenítés",
		["settings.temp.state"] = "Hőmérséklet állapot megjelenítése",
		["settings.temp.state.desc"] = "Mutatja hogy fagyos, hideg, hűvös, kellemes, meleg, forró vagy tűző a hőség",
		
		-- Time of day
		["time.dawn"] = "Hajnal",
		["time.morning"] = "Reggel",
		["time.noon"] = "Dél",
		["time.afternoon"] = "Délután",
		["time.evening"] = "Este",
		["time.dusk"] = "Alkony",
		["time.night"] = "Éjszaka",
		["time.midnight"] = "Éjfél",
		
		-- Temperature states
		["temp.freezing"] = "Fagyás",
		["temp.cold"] = "Hideg",
		["temp.chilly"] = "Hűvös",
		["temp.comfortable"] = "Kellemes",
		["temp.warm"] = "Meleg",
		["temp.hot"] = "Forró",
		["temp.scorching"] = "Tűző",
		
	},
	
	Spanish = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Muestra la hora, fecha y (solo fans de Sun's Dusk) temperatura\n- Clic y arrastra para mover\n- Clic y rueda para el tamaño\n- Clic y Shift+rueda para transparencia",
		
		-- Settings sections
		["settings.timedate"] = "Hora y fecha",
		["settings.sunsdusk"] = "Fans de Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Idioma",
		["settings.language.desc"] = "Elige tu idioma. Los ajustes se actualizarán tras reiniciar.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Mostrar HUD",
		["settings.hud.display.desc"] = "¿Cuándo mostrar el HUD? Interfaz = cuando los menús están abiertos",
		["settings.lock"] = "Bloquear posición",
		["settings.pos.x"] = "Posición X",
		["settings.pos.y"] = "Posición Y",
		["settings.exterior"] = "Mostrar hora solo en exteriores",
		
		-- Settings - Font
		["settings.font.size"] = "Tamaño de texto",
		["settings.font.size.desc"] = "Aumentar o reducir el texto.\nPor defecto: 23",
		["settings.text.color"] = "Color del texto",
		["settings.text.color.desc"] = "Cambiar color del texto.\nPor defecto: caa560 ; dfc99f\nAzul: 81CDED",
		["settings.bg.opacity"] = "Transparencia del fondo",
		["settings.bg.opacity.desc"] = "Hacer el fondo más o menos opaco.\n0-1, por defecto: 0.5",
		["settings.text.align"] = "Alineación del texto",
		["settings.text.align.desc"] = "Alinear hora y fecha.\nPor defecto: izquierda",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Intervalo del reloj",
		["settings.clock.interval.desc"] = "Actualizar reloj cada x minutos (en el juego).\nPor defecto: 15",
		["settings.time.format"] = "Formato de hora",
		
		-- Settings - Date
		["settings.date.show"] = "Mostrar fecha",
		["settings.date.show.desc"] = "Diferentes formatos para mostrar la fecha.",
		["settings.date.top"] = "Fecha arriba",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Mostrar temperatura",
		["settings.temp.state"] = "Mostrar estado de temperatura",
		["settings.temp.state.desc"] = "Muestra si estás congelado, con frío, fresco, cómodo, caliente, acalorado o ardiendo",
		
		-- Time of day
		["time.dawn"] = "Amanecer",
		["time.morning"] = "Mañana",
		["time.noon"] = "Mediodía",
		["time.afternoon"] = "Tarde",
		["time.evening"] = "Atardecer",
		["time.dusk"] = "Crepúsculo",
		["time.night"] = "Noche",
		["time.midnight"] = "Medianoche",
		
		-- Temperature states
		["temp.freezing"] = "Congelado",
		["temp.cold"] = "Frío",
		["temp.chilly"] = "Fresco",
		["temp.comfortable"] = "Cómodo",
		["temp.warm"] = "Caliente",
		["temp.hot"] = "Muy caliente",
		["temp.scorching"] = "Ardiendo",
		
	},
	
	Italian = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Mostra ora, data e (solo fan di Sun's Dusk) temperatura\n- Clicca e trascina per spostare\n- Clicca e rotella per la dimensione\n- Clicca e Shift+rotella per trasparenza",
		
		-- Settings sections
		["settings.timedate"] = "Ora e data",
		["settings.sunsdusk"] = "Fan di Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Lingua",
		["settings.language.desc"] = "Scegli la tua lingua. Le impostazioni si aggiorneranno dopo il riavvio.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Visualizzazione HUD",
		["settings.hud.display.desc"] = "Quando mostrare l'HUD? Interfaccia = quando i menu sono aperti",
		["settings.lock"] = "Blocca posizione",
		["settings.pos.x"] = "Posizione X",
		["settings.pos.y"] = "Posizione Y",
		["settings.exterior"] = "Mostrare ora solo all'esterno",
		
		-- Settings - Font
		["settings.font.size"] = "Dimensione testo",
		["settings.font.size.desc"] = "Ingrandire o ridurre il testo.\nPredefinito: 23",
		["settings.text.color"] = "Colore del testo",
		["settings.text.color.desc"] = "Cambiare colore del testo.\nPredefinito: caa560 ; dfc99f\nBlu: 81CDED",
		["settings.bg.opacity"] = "Trasparenza sfondo",
		["settings.bg.opacity.desc"] = "Rendere lo sfondo più o meno opaco.\n0-1, predefinito: 0.5",
		["settings.text.align"] = "Allineamento testo",
		["settings.text.align.desc"] = "Allineare ora e data.\nPredefinito: sinistra",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Intervallo orologio",
		["settings.clock.interval.desc"] = "Aggiornare l'orologio ogni x minuti (di gioco).\nPredefinito: 15",
		["settings.time.format"] = "Formato ora",
		
		-- Settings - Date
		["settings.date.show"] = "Mostra data",
		["settings.date.show.desc"] = "Diversi formati per visualizzare la data.",
		["settings.date.top"] = "Data sopra",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Visualizzazione temperatura",
		["settings.temp.state"] = "Mostra stato temperatura",
		["settings.temp.state.desc"] = "Mostra se stai congelando, hai freddo, sei fresco, comodo, caldo, accaldato o bollente",
		
		-- Time of day
		["time.dawn"] = "Alba",
		["time.morning"] = "Mattina",
		["time.noon"] = "Mezzogiorno",
		["time.afternoon"] = "Pomeriggio",
		["time.evening"] = "Sera",
		["time.dusk"] = "Crepuscolo",
		["time.night"] = "Notte",
		["time.midnight"] = "Mezzanotte",
		
		-- Temperature states
		["temp.freezing"] = "Congelato",
		["temp.cold"] = "Freddo",
		["temp.chilly"] = "Fresco",
		["temp.comfortable"] = "Comodo",
		["temp.warm"] = "Caldo",
		["temp.hot"] = "Molto caldo",
		["temp.scorching"] = "Bollente",
		
	},
	
	Czech = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Zobrazuje čas, datum a (jen pro fanoušky Sun's Dusk) teplotu\n- Klikni a přetáhni pro přesun\n- Klikni a kolečko pro velikost\n- Klikni a Shift+kolečko pro průhlednost",
		
		-- Settings sections
		["settings.timedate"] = "Čas a datum",
		["settings.sunsdusk"] = "Fanoušci Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Jazyk",
		["settings.language.desc"] = "Vyber si jazyk. Nastavení se aktualizuje po restartu.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Zobrazení HUD",
		["settings.hud.display.desc"] = "Kdy zobrazit HUD? Rozhraní = když jsou otevřená menu",
		["settings.lock"] = "Uzamknout pozici",
		["settings.pos.x"] = "Pozice X",
		["settings.pos.y"] = "Pozice Y",
		["settings.exterior"] = "Zobrazit čas jen venku",
		
		-- Settings - Font
		["settings.font.size"] = "Velikost textu",
		["settings.font.size.desc"] = "Zvětšit nebo zmenšit text.\nVýchozí: 23",
		["settings.text.color"] = "Barva textu",
		["settings.text.color.desc"] = "Změnit barvu textu.\nVýchozí: caa560 ; dfc99f\nModrá: 81CDED",
		["settings.bg.opacity"] = "Průhlednost pozadí",
		["settings.bg.opacity.desc"] = "Změnit průhlednost pozadí.\n0-1, výchozí: 0.5",
		["settings.text.align"] = "Zarovnání textu",
		["settings.text.align.desc"] = "Zarovnat čas a datum.\nVýchozí: vlevo",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Interval hodin",
		["settings.clock.interval.desc"] = "Aktualizovat hodiny každých x minut (ve hře).\nVýchozí: 15",
		["settings.time.format"] = "Formát času",
		
		-- Settings - Date
		["settings.date.show"] = "Zobrazit datum",
		["settings.date.show.desc"] = "Různé formáty zobrazení data.",
		["settings.date.top"] = "Datum nahoře",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Zobrazení teploty",
		["settings.temp.state"] = "Zobrazit stav teploty",
		["settings.temp.state.desc"] = "Zobrazuje jestli je mráz, zima, chladno, příjemně, teplo, horko nebo vedro",
		
		-- Time of day
		["time.dawn"] = "Úsvit",
		["time.morning"] = "Ráno",
		["time.noon"] = "Poledne",
		["time.afternoon"] = "Odpoledne",
		["time.evening"] = "Večer",
		["time.dusk"] = "Soumrak",
		["time.night"] = "Noc",
		["time.midnight"] = "Půlnoc",
		
		-- Temperature states
		["temp.freezing"] = "Mrzne",
		["temp.cold"] = "Zima",
		["temp.chilly"] = "Chladno",
		["temp.comfortable"] = "Příjemně",
		["temp.warm"] = "Teplo",
		["temp.hot"] = "Horko",
		["temp.scorching"] = "Vedro",
		
	},
	
	Portuguese = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Mostra hora, data e (só para fãs de Sun's Dusk) temperatura\n- Clica e arrasta para mover\n- Clica e roda do rato para tamanho\n- Clica e Shift+roda para transparência",
		
		-- Settings sections
		["settings.timedate"] = "Hora e data",
		["settings.sunsdusk"] = "Fãs de Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Idioma",
		["settings.language.desc"] = "Escolhe o teu idioma. As definições vão atualizar após reiniciar.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Exibir HUD",
		["settings.hud.display.desc"] = "Quando mostrar o HUD? Interface = quando menus estão abertos",
		["settings.lock"] = "Bloquear posição",
		["settings.pos.x"] = "Posição X",
		["settings.pos.y"] = "Posição Y",
		["settings.exterior"] = "Mostrar hora só no exterior",
		
		-- Settings - Font
		["settings.font.size"] = "Tamanho do texto",
		["settings.font.size.desc"] = "Aumentar ou diminuir o texto.\nPadrão: 23",
		["settings.text.color"] = "Cor do texto",
		["settings.text.color.desc"] = "Mudar cor do texto.\nPadrão: caa560 ; dfc99f\nAzul: 81CDED",
		["settings.bg.opacity"] = "Transparência do fundo",
		["settings.bg.opacity.desc"] = "Tornar o fundo mais ou menos opaco.\n0-1, padrão: 0.5",
		["settings.text.align"] = "Alinhamento do texto",
		["settings.text.align.desc"] = "Alinhar hora e data.\nPadrão: esquerda",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Intervalo do relógio",
		["settings.clock.interval.desc"] = "Atualizar relógio a cada x minutos (no jogo).\nPadrão: 15",
		["settings.time.format"] = "Formato de hora",
		
		-- Settings - Date
		["settings.date.show"] = "Mostrar data",
		["settings.date.show.desc"] = "Diferentes formatos para exibir a data.",
		["settings.date.top"] = "Data em cima",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Exibir temperatura",
		["settings.temp.state"] = "Exibir estado de temperatura",
		["settings.temp.state.desc"] = "Mostra se está gélido, frio, fresco, confortável, quente, muito quente ou escaldante",
		
		-- Time of day
		["time.dawn"] = "Amanhecer",
		["time.morning"] = "Manhã",
		["time.noon"] = "Meio-dia",
		["time.afternoon"] = "Tarde",
		["time.evening"] = "Entardecer",
		["time.dusk"] = "Crepúsculo",
		["time.night"] = "Noite",
		["time.midnight"] = "Meia-noite",
		
		-- Temperature states
		["temp.freezing"] = "Congelando",
		["temp.cold"] = "Frio",
		["temp.chilly"] = "Fresco",
		["temp.comfortable"] = "Confortável",
		["temp.warm"] = "Quente",
		["temp.hot"] = "Muito quente",
		["temp.scorching"] = "Escaldante",
		
	},
	
	Romanian = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "Afișează ora, data și (doar pentru fani Sun's Dusk) temperatura\n- Clic și trage pentru a muta\n- Clic și rotița pentru dimensiune\n- Clic și Shift+rotița pentru transparență",
		
		-- Settings sections
		["settings.timedate"] = "Oră și dată",
		["settings.sunsdusk"] = "Fani Sun's Dusk",
		
		-- Settings - Language
		["settings.language"] = "Limbă",
		["settings.language.desc"] = "Alege limba. Setările se vor actualiza după repornire.",
		
		-- Settings - HUD
		["settings.hud.display"] = "Afișare HUD",
		["settings.hud.display.desc"] = "Când să afișezi HUD-ul? Interfață = când meniurile sunt deschise",
		["settings.lock"] = "Blochează poziția",
		["settings.pos.x"] = "Poziție X",
		["settings.pos.y"] = "Poziție Y",
		["settings.exterior"] = "Afișează ora doar în exterior",
		
		-- Settings - Font
		["settings.font.size"] = "Dimensiune text",
		["settings.font.size.desc"] = "Mărește sau micșorează textul.\nImplicit: 23",
		["settings.text.color"] = "Culoare text",
		["settings.text.color.desc"] = "Schimbă culoarea textului.\nImplicit: caa560 ; dfc99f\nAlbastru: 81CDED",
		["settings.bg.opacity"] = "Transparență fundal",
		["settings.bg.opacity.desc"] = "Ajustează transparența fundalului.\n0-1, implicit: 0.5",
		["settings.text.align"] = "Aliniere text",
		["settings.text.align.desc"] = "Aliniază ora și data.\nImplicit: stânga",
		
		-- Settings - Clock
		["settings.clock.interval"] = "Interval ceas",
		["settings.clock.interval.desc"] = "Actualizează ceasul la fiecare x minute (în joc).\nImplicit: 15",
		["settings.time.format"] = "Format oră",
		
		-- Settings - Date
		["settings.date.show"] = "Afișează data",
		["settings.date.show.desc"] = "Formate diferite pentru afișarea datei.",
		["settings.date.top"] = "Data sus",
		
		-- Settings - Temperature
		["settings.temp.display"] = "Afișare temperatură",
		["settings.temp.state"] = "Afișare stare temperatură",
		["settings.temp.state.desc"] = "Afișează dacă e înghețat, frig, răcoare, confortabil, cald, foarte cald sau canicular",
		
		-- Time of day
		["time.dawn"] = "Zori",
		["time.morning"] = "Dimineață",
		["time.noon"] = "Amiază",
		["time.afternoon"] = "După-amiază",
		["time.evening"] = "Seară",
		["time.dusk"] = "Amurg",
		["time.night"] = "Noapte",
		["time.midnight"] = "Miezul nopții",
		
		-- Temperature states
		["temp.freezing"] = "Înghețat",
		["temp.cold"] = "Frig",
		["temp.chilly"] = "Răcoare",
		["temp.comfortable"] = "Confortabil",
		["temp.warm"] = "Cald",
		["temp.hot"] = "Foarte cald",
		["temp.scorching"] = "Canicular",
		
	},
	
	Japanese = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "ゲーム内の時刻、日付、温度（Sun's Duskファンのみ）を表示\n- クリック&ドラッグで移動\n- クリック&マウスホイールでサイズ変更\n- クリック&Shift+マウスホイールで透明度変更",
		
		-- Settings sections
		["settings.timedate"] = "時刻と日付",
		["settings.sunsdusk"] = "Sun's Duskファン",
		
		-- Settings - Language
		["settings.language"] = "言語",
		["settings.language.desc"] = "言語を選択してください。再起動後に設定が更新されます。",
		
		-- Settings - HUD
		["settings.hud.display"] = "HUD表示",
		["settings.hud.display.desc"] = "HUDを表示するタイミング。インターフェース = メニューが開いている時",
		["settings.lock"] = "位置を固定",
		["settings.pos.x"] = "X座標",
		["settings.pos.y"] = "Y座標",
		["settings.exterior"] = "屋外でのみ時刻を表示",
		
		-- Settings - Font
		["settings.font.size"] = "フォントサイズ",
		["settings.font.size.desc"] = "フォントサイズを変更。\nデフォルト：23",
		["settings.text.color"] = "テキスト色",
		["settings.text.color.desc"] = "テキストの色を変更。\nデフォルト：caa560 ; dfc99f\n青：81CDED",
		["settings.bg.opacity"] = "背景の透明度",
		["settings.bg.opacity.desc"] = "背景の透明度を変更。\n0-1、デフォルト：0.5",
		["settings.text.align"] = "テキスト配置",
		["settings.text.align.desc"] = "時刻と日付の配置。\nデフォルト：左",
		
		-- Settings - Clock
		["settings.clock.interval"] = "時計更新間隔",
		["settings.clock.interval.desc"] = "ゲーム内でx分ごとに時計を更新。\nデフォルト：15",
		["settings.time.format"] = "時刻形式",
		
		-- Settings - Date
		["settings.date.show"] = "日付表示",
		["settings.date.show.desc"] = "日付表示の異なる形式。",
		["settings.date.top"] = "日付を上に",
		
		-- Settings - Temperature
		["settings.temp.display"] = "温度表示",
		["settings.temp.state"] = "温度状態を表示",
		["settings.temp.state.desc"] = "凍える、寒い、冷える、快適、暖かい、暑い、灼熱の状態を表示",
		
		-- Time of day
		["time.dawn"] = "夜明け",
		["time.morning"] = "朝",
		["time.noon"] = "正午",
		["time.afternoon"] = "午後",
		["time.evening"] = "夕方",
		["time.dusk"] = "夕暮れ",
		["time.night"] = "夜",
		["time.midnight"] = "真夜中",
		
		-- Temperature states
		["temp.freezing"] = "凍える",
		["temp.cold"] = "寒い",
		["temp.chilly"] = "冷える",
		["temp.comfortable"] = "快適",
		["temp.warm"] = "暖かい",
		["temp.hot"] = "暑い",
		["temp.scorching"] = "灼熱",
		
	},
	
	ChineseSimplified = {
		-- Mod info
		["mod.name"] = "TimeHUD",
		["mod.desc"] = "显示游戏内时间、日期和温度（仅Sun's Dusk粉丝）\n- 点击拖动来移动\n- 点击滚轮调整大小\n- 点击Shift+滚轮调整透明度",
		
		-- Settings sections
		["settings.timedate"] = "时间和日期",
		["settings.sunsdusk"] = "Sun's Dusk粉丝",
		
		-- Settings - Language
		["settings.language"] = "语言",
		["settings.language.desc"] = "选择你的语言。重启后设置会更新。",
		
		-- Settings - HUD
		["settings.hud.display"] = "HUD显示",
		["settings.hud.display.desc"] = "何时显示HUD？界面 = 打开菜单时",
		["settings.lock"] = "锁定位置",
		["settings.pos.x"] = "X坐标",
		["settings.pos.y"] = "Y坐标",
		["settings.exterior"] = "仅在室外显示时间",
		
		-- Settings - Font
		["settings.font.size"] = "字体大小",
		["settings.font.size.desc"] = "增大或减小字体。\n默认：23",
		["settings.text.color"] = "文字颜色",
		["settings.text.color.desc"] = "更改文字颜色。\n默认：caa560 ; dfc99f\n蓝色：81CDED",
		["settings.bg.opacity"] = "背景透明度",
		["settings.bg.opacity.desc"] = "调整背景透明度。\n0-1，默认：0.5",
		["settings.text.align"] = "文字对齐",
		["settings.text.align.desc"] = "对齐时间和日期。\n默认：左对齐",
		
		-- Settings - Clock
		["settings.clock.interval"] = "时钟更新间隔",
		["settings.clock.interval.desc"] = "每隔x游戏分钟更新时钟。\n默认：15",
		["settings.time.format"] = "时间格式",
		
		-- Settings - Date
		["settings.date.show"] = "显示日期",
		["settings.date.show.desc"] = "日期显示的不同格式。",
		["settings.date.top"] = "日期在上",
		
		-- Settings - Temperature
		["settings.temp.display"] = "温度显示",
		["settings.temp.state"] = "显示温度状态",
		["settings.temp.state.desc"] = "显示天气是冻僵、寒冷、凉爽、舒适、温暖、炎热还是酷热",
		
		-- Time of day
		["time.dawn"] = "黎明",
		["time.morning"] = "早晨",
		["time.noon"] = "正午",
		["time.afternoon"] = "下午",
		["time.evening"] = "傍晚",
		["time.dusk"] = "黄昏",
		["time.night"] = "夜晚",
		["time.midnight"] = "午夜",
		
		-- Temperature states
		["temp.freezing"] = "冻僵",
		["temp.cold"] = "寒冷",
		["temp.chilly"] = "凉爽",
		["temp.comfortable"] = "舒适",
		["temp.warm"] = "温暖",
		["temp.hot"] = "炎热",
		["temp.scorching"] = "酷热",
		
	},
	
}

local storage = require('openmw.storage')
local settingsSection = storage.playerSection('Settings'.."TimeHUD".."Time and Date")
LANGUAGE = settingsSection:get("LANGUAGE") or "English"


local function L(key, fallback)
	local lang = translations[LANGUAGE]
	if lang and lang[key] then
		return lang[key]
	end
	return fallback or key
end

return L