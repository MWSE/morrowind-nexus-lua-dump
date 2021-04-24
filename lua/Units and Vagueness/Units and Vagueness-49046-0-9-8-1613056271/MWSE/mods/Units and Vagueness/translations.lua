return {
	["eng"] = {
		no = "No",
		yes = "Yes",
		unknown = "unknown",
		updateRequired = "Units and Vagueness requires the latest version of MWSE. Please run MWSE-Updater.exe.",
		summary = "This mod allows you to enable unit conversion for Metric and Imperial units, or omit the numbers for Roleplay purposes. It assumes that the vanilla weight unit is neither in kilograms, nor pounds, but actually in hectogram. Additionally, there are options to display gold values as vague estimates.",
		configUseUnitConversionType = "Unit Conversion System:",
		configUseUnitConversionTypeOptions = {
			{ value = 0, label = "0. Vanilla - unconverted unitless weights" },
			{ value = 1, label = "1. Metric Unit System - kg/g, or l/ml" },
			{ value = 2, label = "2. Imperial Unit System - lb/oz" },
			{ value = 3, label = "3. Vague Roleplay labels" }
		},
		configUseUnitConversionTypeDescription = 
			"The type of Units and Vagueness you wish to use."
			.."\n"
			.."This will be applied to item tooltips, the Inventory encumbrance bar, and the new capacity bar added by UI Expansion (if installed)."
			.."\n"
			.."\n0. Vanilla - unconverted unitless weights"
			.."\n"
			.."\n1. Metric Unit System - kg/g, or l/ml"
			.."\n"
			.."\n2. Imperial Unit System - lb/oz"
			.."\n"
			.."\n3. Vague Roleplay labels - f.i. light, unhindered, empty, etc",
		configUseSmallerUnits = "Petty Weight Units:",
		configUseSmallerUnitsOptions = {
			{ value = 0, label = "0. No - stick with kg/lb" },
			{ value = 1, label = "1. Yes - use g/ml/oz, where it makes sense" },
			{ value = 2, label = "2. Hide petty weights below 2.0 completely" }
		},
		configUseSmallerUnitsDescription = 
			"Convert to smaller units on weights that are below 1 kg or 1 lb. Or hide all weights below 200 g (2.0 in Vanilla) to clean up the interface (which also applies to Roleplay labels)."
			.."\n"
			.."\n0. No - stick with kg/lb"
			.."\n"
			.."\n1. Yes - use g/ml/oz, where it makes sense"
			.."\n"
			.."\n2. Hide petty weights below 2.0 completely",
		configPotionsInMilliLitres = "Allow Fluid Weight Units and Icon",
		configPotionsInMilliLitresDescription = "Potions and Drinks will use l/ml instead of kg/g, when Metric System is enabled. Additionally they will receive a flask icon, instead of the weight icon from UI Expansion.",
		configSummarizeStacks = "Stack Weight and Stack Gold:",
		configSummarizeStacksOptions = {
			{ value = 0, label = "0. No" },
			{ value = 1, label = "1. Yes - weight only" },
			{ value = 2, label = "2. Yes - weight and gold" },
		},
		configSummarizeStacksDescription = 
			"Summarize weight/gold values on stacked items. An additional counter will be shown next to weight value.\n[Disclaimer: This will not yet work in Barter and Content menus.]"
			.."\n"
			.."\n0. No"
			.."\n"
			.."\n1. Yes, but only on weights."
			.."\n"
			.."\n2. Yes, and also summarize the gold value.",
		configUseVagueGold = "Gold Value Uncertainty:",
		configUseVagueGoldOptions = {
			{ value = 0, label = "0. No - keep it straight" },
			{ value = 1, label = "1. Yes - use obscure numbers" },
			{ value = 2, label = "2. Yes - use vague labels" },
			{ value = 3, label = "3. Yes - use both obscure numbers AND vague labels" },
		},
		configUseVagueGoldDescription = 
			"Display gold values as obscured/uncertain numbers, vague labels, or both. The guessing of gold values may become more precise with higher mercantile and character level."
			.."\nUsing the Stack value option won't affect PCs ability to guess an item value."
			.."\n"
			.."\n0. Keep it straight"
			.."\n"
			.."\n1. Obscure the values by rounding them to some estimable number of digits. Bigger item value estimates are naturally less precise. Uncertain values will be marked by question marks: 56?, 50K?, ?. Higher mercantile and character level will increase the precision, up to the point of certainty."
			.."\n"
			.."\n2. Use labels such as 'cheap', 'precious', or 'invaluable'. These labels will change over time with advanced mercantile and player level. F.i. a 'prized' item may become 'common' in late game. The 'invaluable' label will give way to higher tier labels."
			.."\n"
			.."\n3. Do both. Obscure the values that are estimable. Use labels on the rest.",
		configUseSoldItemValues = "Remember Prices from Bartering:",
		configUseSoldItemValuesDescription = "When clicking on an item for buying in a Bartering window, PC will remember the merchants offer, to compare their estimates against.",
		configHidePettyItemValues = "Hide Petty Item Values",
		configHidePettyItemValuesDescription = "Hide item values below 20 outside the Barter menu. If stack value is used and is higher, it will still show.",
		configUseWeightGoldRatio = "Enable Gold/Weight Ratio",
		configUseWeightGoldRatioDescription = 
			"Display the ratio of gold value/weight value behind a red slash, next to the weight. It can be used to compare the relative value of items, when one has to be economic about inventory space."
			.."\n\nIt is being shown only when the item value is below 2000 and the weight is above 4.0 (in Vanilla units). The higher the number, the better.",
		roleplayLabelZero = "airy",
		roleplayLabelOne = "light",
		roleplayLabelTwo = "moderate",
		roleplayLabelThree = "heavy",
		roleplayLabelFour = "massive",
		roleplayCarryWeightZero = "unhindered",
		roleplayCarryWeightOne = "stocked",
		roleplayCarryWeightTwo = "packed",
		roleplayCarryWeightThree = "burdened",
		roleplayCarryWeightFour = "immobile",
		roleplayCapacityZero = "empty",
		roleplayCapacityOne = "sparse",
		roleplayCapacityTwo = "stuffed", --half-full
		roleplayCapacityThree = "bulging", --cluttered
		roleplayCapacityFour = "full", --overfilled
		roleplayGoldLabelZero = "cheap", --tuppence, ha'penny
		roleplayGoldLabelOne = "common",
		roleplayGoldLabelTwo = "prized",
		roleplayGoldLabelThree = "precious",
		roleplayGoldLabelFour = "immense",
		roleplayGoldLabelFive = "mythic",
		roleplayGoldLabelSix = "legendary",
		roleplayGoldLabelMask = "invaluable", --"immeasurable",
	},
	["deu"] = {
		no = "Nein",
		yes = "Ja",
		unknown = "unbekannt",
		updateRequired = "Units and Vagueness benцtigt die jьngste Version von MWSE. Bitte die MWSE-Updater.exe nutzen.",
		summary = "Diese Mod erlaubt die Umwandlung von Gewichten in das Metrische oder Britische System, oder nutze Rollenspiel-Stichwцrter. Es wird angenommen, dass die Vanilla Einheit in Wirklichkeit weder in Kilogramm, noch Pfund, sondern in Hektogram ist. Desweiteren gibt es die Option Goldwerte als Schдtzwerte anzuzeigen.",
		configUseUnitConversionType = "Gewichtseinheitensystem:",
		configUseUnitConversionTypeOptions = {
			{ value = 0, label = "0. Vanilla" },
			{ value = 1, label = "1. Metrisches System" },
			{ value = 2, label = "2. Britisches System" },
			{ value = 3, label = "3. Rollenspiel-Stichwцrter" }
		},
		configUseUnitConversionTypeDescription = 
			"Das Gewichtseinheitensystem, dass du nutzen mцchtest."
			.."\n"
			.."Es wird in Tooltips, in der Belastungsanzeige im Inventar, und in der Fьllanzeige von Containern (UI Expansion) zum Einsatz kommen."
			.."\n"
			.."\n0. Vanilla - keine Konvertierung oder Einheitenkьrzel"
			.."\n"
			.."\n1. Metrisches System - kg/g, ggfls. l/ml"
			.."\n"
			.."\n2. Britisches System - lb/oz"
			.."\n"
			.."\n3. Rollenspiel-Stichwцrter - f.i. leicht, belastet, leer, etc",
		configUseSmallerUnits = "Kleine Einheiten:",
		configUseSmallerUnitsOptions = {
			{ value = 0, label = "0. Nein - nutze nur kg/lb" },
			{ value = 1, label = "1. Ja - nutze g/ml/oz, wenn es Sinn ergibt" },
			{ value = 2, label = "2. Alles unter 200 g verbergen" }
		},
		configUseSmallerUnitsDescription = 
			"Konvertiere zu kleineren Einheiten in Gewichten weniger als 1 kg oder 1 lb. Oder verberge alle unter 200 g (2.0 in Vanilla) um das Interface aufzurдumen (auch wenn Rollenspiel-Stichwцrter genutzt werden)."
			.."\n"
			.."\n0. Nein - nutze nur kg/lb"
			.."\n"
			.."\n1. Ja - nutze g/ml/oz, wenn es Sinn ergibt"
			.."\n"
			.."\n2. Alles unter 200 g verbergen",
		configPotionsInMilliLitres = "Einheiten und Icon fьr Flьssigkeiten",
		configPotionsInMilliLitresDescription = "Trдnke und Getrдnke zeigen l/ml statt kg/g, im Metrischen System. Zusдtzlich erhalten die Tooltips ein Flaschensymbol, statt dem Gewichts-Icon von UI Expansion.",
		configSummarizeStacks = "Stapel-Gewicht und Stapel-Gold:",
		configSummarizeStacksOptions = {
			{ value = 0, label = "0. Nein" },
			{ value = 1, label = "1. Ja - Gewicht" },
			{ value = 2, label = "2. Ja - Gewicht und Gold" },
		},
		configSummarizeStacksDescription = 
			"Summiere das Gewicht/Gold von Item-Stapeln auf. Ein zusдtzlicher Zдhler wird ggfls. neben der Gewichtsanzeige eingefьgt.\n[Achtung: funktioniert noch nicht in Handels- und Container-Fenstern.]"
			.."\n"
			.."\n0. Nein"
			.."\n"
			.."\n1. Ja, aber nur die Gewichte"
			.."\n"
			.."\n2. Ja, das Gewicht und auch den Goldwert",
		configUseVagueGold = "Ungenaue Goldwerte:",
		configUseVagueGoldOptions = {
			{ value = 0, label = "0. Nein" },
			{ value = 1, label = "1. Ja - nutze unsichere Zahlen" },
			{ value = 2, label = "2. Ja - nutze Stichwцrter" },
			{ value = 3, label = "3. Ja - nutze unsichere Zahlen UND Stichwцrter" },
		},
		configUseVagueGoldDescription = 
			"Zeige Goldwerte als verschleierte/unsichere Zahlen, Stichwцrter, oder beides. Die Schдtzungen sind prдziser, je hцher das Feilschen- und Charakterlevel ist."
			.."\n"
			.."\n0. Nein - lass die Werte unverfдlscht wie in Vanilla"
			.."\n"
			.."\n1. Ja - verschleiere die Zahlen bis zu einer schдtzbaren Anzahl von Ziffern. GrцЯere Werte sind weniger prдzise. Unsichere Werte werden mit Fragezeichen markiert: 56?, 50K?, ?. Steigende Level in Feilschen und/oder Charakterlevel, werden die Prдzision bis zur Gewissheit steigern."
			.."\n"
			.."\n2. Ja - nutze Stichwцrter wie 'minderwertig', 'wertvoll', oder 'mythisch'. Diese дndern sich mit fortschreitendem Feilschen und Charakterlevel. Z.b. wird ein 'kostspieliger' Gegenstand irgendwann 'gьnstig'. 'Unermesslich' wird anderen Stichwцrtern weichen."
			.."\n"
			.."\n3. Ja - beides gleichzeitig verwenden: Verschleiere die Werte die schдtzbar sind, nutze Stichwцrter bei allen anderen.",
		configUseSoldItemValues = "Preise merken",
		configUseSoldItemValuesDescription = "Wenn beim Handeln auf einen Gegenstand zum Kaufen geklickt wird, wird sich der PC den Preis merken, um die eigene Schдtzung damit vergleichen zu kцnnen.",
		configHidePettyItemValues = "Goldwerte unter 20 verbergen",
		configHidePettyItemValuesDescription = "Verstecke auЯerhalb des Handelsmenьs alles, was weniger als 20 Wert ist. Wenn das Stapelgewicht grцЯer ist und summiert werden soll, so wird es angezeigt.",
		configUseWeightGoldRatio = "Gold/Gewicht-Verhдltnis anzeigen",
		configUseWeightGoldRatioDescription = 
			"Zeige das Verhдltnis von Gold/Gewicht hinter einem roten '/', neben dem Gewicht. Es kann dazu dienen den relativen Wert eines Gegenstands einzuschдtzen, wenn der Platz im Inventar knapp ist."
			.."\n\nEs wird nur angezeigt wenn der Goldwert unter 2000 und das Gewicht ьber 400g ist (4.0 in Vanilla Einheiten). Je hцher die Zahl, desto besser.",
		roleplayLabelZero = "sehr leicht",
		roleplayLabelOne = "leicht",
		roleplayLabelTwo = "moderat",
		roleplayLabelThree = "schwer",
		roleplayLabelFour = "wuchtig",
		roleplayCarryWeightZero = "unbeschwert",
		roleplayCarryWeightOne = "ausgerьstet",
		roleplayCarryWeightTwo = "bepackt",
		roleplayCarryWeightThree = "belastet",
		roleplayCarryWeightFour = "ьberladen",
		roleplayCapacityZero = "leer",
		roleplayCapacityOne = "fast leer",
		roleplayCapacityTwo = "gefьllt",
		roleplayCapacityThree = "voll",
		roleplayCapacityFour = "ьberfьllt",
		roleplayGoldLabelZero = "minderwertig",
		roleplayGoldLabelOne = "gьnstig",
		roleplayGoldLabelTwo = "kostspielig",
		roleplayGoldLabelThree = "wertvoll",
		roleplayGoldLabelFour = "immens",
		roleplayGoldLabelFive = "mythisch",
		roleplayGoldLabelSix = "legendдr",
		roleplayGoldLabelMask = "unermesslich", --"unermesslich",
	},
}
