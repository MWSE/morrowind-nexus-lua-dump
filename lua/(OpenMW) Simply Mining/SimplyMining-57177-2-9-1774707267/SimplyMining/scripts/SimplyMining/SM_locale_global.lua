-- Localization tables for SimplyMining Restocking (global script)
local translations = {
	French = {
		["Group.Restocking"]          = "Réapprovisionnement",
		["Group.Restocking.desc"]     = "Les marchands réapprovisionnent jusqu'à une journée de minerai par visite (max 24h entre les visites).\nCapacité = taux de réappro × jours de stock.",
		["RESTOCK_ORES.name"]         = "Les marchands vendent du minerai",
		["RESTOCK_ORES.desc"]         = "Les forgerons, commerçants et autres marchands stockeront du minerai à vendre",
		["RESTOCK_DAYS.name"]         = "Jours de stock",
		["RESTOCK_DAYS.desc"]         = "Combien de jours de minerai un marchand peut conserver\nUn forgeron à 3/jour avec 2 jours en garde 6, un prêteur à 0.25/jour en garde 1",
		["RESTOCK_SPEED.name"]        = "Vitesse de réappro (%)",
		["RESTOCK_SPEED.desc"]        = "La rapidité avec laquelle les marchands renouvellent leur minerai entre les visites\nÀ 100%, un forgeron réapprovisionne ~3 minerais/jour, un commerçant ~1.5/jour",
		["RESTOCK_RARITY_BIAS.name"]  = "Biais de rareté (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "À quel point les marchands favorisent les minerais communs\n0 = tous les minerais aussi probables\n100 = pondération normale\n200 = les minerais rares n'apparaissent presque jamais",
		["RESTOCK_LEVEL_BIAS.name"]   = "Biais de niveau (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "À quel point votre niveau de minage influe sur les minerais réapprovisionnés\n0 = Désactivé\n100 = Ne réapprovisionne que les minerais proches de votre niveau et bloque ceux bien au-dessus de votre compétence",
		["label.Few"]                 = "Peu",
		["label.Many"]                = "Beaucoup",
		["label.Slow"]                = "Lent",
		["label.Fast"]                = "Rapide",
		["label.Flat"]                = "Uniforme",
		["label.Biased"]              = "Biaisé",
		["unit.days"]                 = " jours",
	},
	German = {
		["Group.Restocking"]          = "Nachschub",
		["Group.Restocking.desc"]     = "Händler füllen pro Besuch bis zu einen Tag Erz auf (max. 24h zwischen Besuchen zählen).\nLagerkapazität = Nachschubrate × Lagertage.",
		["RESTOCK_ORES.name"]         = "Händler verkaufen Erz",
		["RESTOCK_ORES.desc"]         = "Schmiede, Händler und andere Kaufleute führen Erz zum Verkauf",
		["RESTOCK_DAYS.name"]         = "Lagertage",
		["RESTOCK_DAYS.desc"]         = "Wie viele Tage an Erz ein Händler vorhalten kann\nEin Schmied mit 3/Tag und 2 Tagen hält 6, ein Pfandleiher mit 0.25/Tag hält 1",
		["RESTOCK_SPEED.name"]        = "Nachschub-Tempo (%)",
		["RESTOCK_SPEED.desc"]        = "Wie schnell Händler ihren Erzbestand zwischen Besuchen auffüllen\nBei 100% füllt ein Schmied ~3 Erz/Tag auf, ein Händler ~1.5/Tag",
		["RESTOCK_RARITY_BIAS.name"]  = "Seltenheits-Gewichtung (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Wie stark Händler gewöhnliche Erze bevorzugen\n0 = alle Erze gleich wahrscheinlich\n100 = normale Gewichtung\n200 = seltene Erze erscheinen fast nie",
		["RESTOCK_LEVEL_BIAS.name"]   = "Stufen-Gewichtung (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Wie stark Ihr Bergbau-Level beeinflusst, welche Erze nachgefüllt werden\n0 = Deaktiviert\n100 = Nur Erze nahe Ihrem Level auffüllen und Erze weit über Ihrer Fertigkeit sperren",
		["label.Few"]                 = "Wenig",
		["label.Many"]                = "Viel",
		["label.Slow"]                = "Langsam",
		["label.Fast"]                = "Schnell",
		["label.Flat"]                = "Gleichmäßig",
		["label.Biased"]              = "Gewichtet",
		["unit.days"]                 = " Tage",
	},
	Polish = {
		["Group.Restocking"]          = "Uzupełnianie",
		["Group.Restocking.desc"]     = "Kupcy uzupełniają do jednego dnia rudy na wizytę (maks. 24h między wizytami).\nPojemność = tempo uzupełniania × dni zapasu.",
		["RESTOCK_ORES.name"]         = "Kupcy sprzedają rudę",
		["RESTOCK_ORES.desc"]         = "Kowale, handlarze i inni kupcy będą mieć rudę na sprzedaż",
		["RESTOCK_DAYS.name"]         = "Dni zapasu",
		["RESTOCK_DAYS.desc"]         = "Ile dni rudy kupiec może przechowywać\nKowal z 3/dzień i 2 dniami ma 6, lombard z 0.25/dzień ma 1",
		["RESTOCK_SPEED.name"]        = "Tempo uzupełniania (%)",
		["RESTOCK_SPEED.desc"]        = "Jak szybko kupcy odnawiają zapas rudy między wizytami\nPrzy 100% kowal uzupełnia ~3 rudy/dzień, handlarz ~1.5/dzień",
		["RESTOCK_RARITY_BIAS.name"]  = "Wpływ rzadkości (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Jak mocno kupcy preferują pospolite rudy\n0 = wszystkie rudy równie prawdopodobne\n100 = normalne wagi\n200 = rzadkie rudy prawie się nie pojawiają",
		["RESTOCK_LEVEL_BIAS.name"]   = "Wpływ poziomu (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Jak mocno twój poziom górnictwa wpływa na uzupełniane rudy\n0 = Wyłączone\n100 = Uzupełniaj tylko rudy bliskie twojemu poziomowi i blokuj te znacznie powyżej twojej umiejętności",
		["label.Few"]                 = "Mało",
		["label.Many"]                = "Dużo",
		["label.Slow"]                = "Wolno",
		["label.Fast"]                = "Szybko",
		["label.Flat"]                = "Równo",
		["label.Biased"]              = "Ważone",
		["unit.days"]                 = " dni",
	},
	Russian = {
		["Group.Restocking"]          = "Пополнение",
		["Group.Restocking.desc"]     = "Торговцы пополняют до одного дня руды за визит (макс. 24ч между визитами).\nВместимость = скорость пополнения × дней запаса.",
		["RESTOCK_ORES.name"]         = "Торговцы продают руду",
		["RESTOCK_ORES.desc"]         = "Кузнецы, торговцы и другие купцы будут продавать руду",
		["RESTOCK_DAYS.name"]         = "Дней запаса",
		["RESTOCK_DAYS.desc"]         = "Сколько дней руды может хранить торговец\nКузнец с 3/день и 2 днями хранит 6, ростовщик с 0.25/день хранит 1",
		["RESTOCK_SPEED.name"]        = "Скорость пополнения (%)",
		["RESTOCK_SPEED.desc"]        = "Как быстро торговцы восполняют руду между визитами\nПри 100% кузнец пополняет ~3 руды/день, торговец ~1.5/день",
		["RESTOCK_RARITY_BIAS.name"]  = "Смещение редкости (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Насколько сильно торговцы предпочитают обычную руду\n0 = все руды равновероятны\n100 = обычные веса\n200 = редкая руда почти не появляется",
		["RESTOCK_LEVEL_BIAS.name"]   = "Влияние уровня (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Насколько ваш уровень добычи влияет на пополняемые руды\n0 = Отключено\n100 = Пополнять только руды вблизи вашего уровня и блокировать руды значительно выше вашего навыка",
		["label.Few"]                 = "Мало",
		["label.Many"]                = "Много",
		["label.Slow"]                = "Медленно",
		["label.Fast"]                = "Быстро",
		["label.Flat"]                = "Равномерно",
		["label.Biased"]              = "Смещённо",
		["unit.days"]                 = " дн.",
	},
	Spanish = {
		["Group.Restocking"]          = "Reabastecimiento",
		["Group.Restocking.desc"]     = "Los mercaderes reponen hasta un día de mineral por visita (máx. 24h entre visitas).\nCapacidad = tasa de reposición × días de stock.",
		["RESTOCK_ORES.name"]         = "Los mercaderes venden mineral",
		["RESTOCK_ORES.desc"]         = "Herreros, comerciantes y otros mercaderes tendrán mineral a la venta",
		["RESTOCK_DAYS.name"]         = "Días de stock",
		["RESTOCK_DAYS.desc"]         = "Cuántos días de mineral puede almacenar un mercader\nUn herrero con 3/día y 2 días almacena 6, un prestamista con 0.25/día almacena 1",
		["RESTOCK_SPEED.name"]        = "Velocidad de reposición (%)",
		["RESTOCK_SPEED.desc"]        = "Qué tan rápido los mercaderes reponen su mineral entre visitas\nAl 100%, un herrero repone ~3 minerales/día, un comerciante ~1.5/día",
		["RESTOCK_RARITY_BIAS.name"]  = "Sesgo de rareza (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Cuánto favorecen los mercaderes los minerales comunes\n0 = todos los minerales igual de probables\n100 = pesos normales\n200 = los minerales raros casi nunca aparecen",
		["RESTOCK_LEVEL_BIAS.name"]   = "Sesgo de nivel (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Cuánto afecta tu nivel de minería a los minerales reabastecidos\n0 = Desactivado\n100 = Solo reabastecer minerales cercanos a tu nivel y bloquear los que estén muy por encima de tu habilidad",
		["label.Few"]                 = "Pocos",
		["label.Many"]                = "Muchos",
		["label.Slow"]                = "Lento",
		["label.Fast"]                = "Rápido",
		["label.Flat"]                = "Uniforme",
		["label.Biased"]              = "Sesgado",
		["unit.days"]                 = " días",
	},
	Italian = {
		["Group.Restocking"]          = "Rifornimento",
		["Group.Restocking.desc"]     = "I mercanti riforniscono fino a un giorno di minerale per visita (max 24h tra le visite).\nCapacità = tasso di rifornimento × giorni di scorta.",
		["RESTOCK_ORES.name"]         = "I mercanti vendono minerale",
		["RESTOCK_ORES.desc"]         = "Fabbri, commercianti e altri mercanti avranno minerale in vendita",
		["RESTOCK_DAYS.name"]         = "Giorni di scorta",
		["RESTOCK_DAYS.desc"]         = "Quanti giorni di minerale un mercante può conservare\nUn fabbro con 3/giorno e 2 giorni ne tiene 6, un usuraio con 0.25/giorno ne tiene 1",
		["RESTOCK_SPEED.name"]        = "Velocità di rifornimento (%)",
		["RESTOCK_SPEED.desc"]        = "Quanto velocemente i mercanti riassortiscono il minerale tra le visite\nAl 100%, un fabbro rifornisce ~3 minerali/giorno, un commerciante ~1.5/giorno",
		["RESTOCK_RARITY_BIAS.name"]  = "Influenza rarità (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Quanto i mercanti favoriscono i minerali comuni\n0 = tutti i minerali ugualmente probabili\n100 = pesi normali\n200 = i minerali rari quasi non compaiono",
		["RESTOCK_LEVEL_BIAS.name"]   = "Influenza del livello (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Quanto il tuo livello di estrazione influisce sui minerali riforniti\n0 = Disattivato\n100 = Rifornisci solo minerali vicini al tuo livello e blocca quelli molto al di sopra della tua abilità",
		["label.Few"]                 = "Pochi",
		["label.Many"]                = "Molti",
		["label.Slow"]                = "Lento",
		["label.Fast"]                = "Veloce",
		["label.Flat"]                = "Uniforme",
		["label.Biased"]              = "Sbilanciato",
		["unit.days"]                 = " giorni",
	},
	Hungarian = {
		["Group.Restocking"]          = "Utánpótlás",
		["Group.Restocking.desc"]     = "A kereskedők látogatásonként legfeljebb egy nap ércet töltenek fel (max. 24 óra számít a látogatások között).\nKapacitás = feltöltési sebesség × készlettartás napjai.",
		["RESTOCK_ORES.name"]         = "Kereskedők ércet árulnak",
		["RESTOCK_ORES.desc"]         = "Kovácsok, kereskedők és más árusok ércet tartanak eladásra",
		["RESTOCK_DAYS.name"]         = "Készlet napjai",
		["RESTOCK_DAYS.desc"]         = "Hány napnyi ércet tarthat egy kereskedő\nEgy kovács 3/nap és 2 nappal 6-ot tart, egy zálogos 0.25/nap mellett 1-et",
		["RESTOCK_SPEED.name"]        = "Feltöltési sebesség (%)",
		["RESTOCK_SPEED.desc"]        = "Milyen gyorsan pótolják a kereskedők az ércet a látogatások között\n100%-nál egy kovács ~3 ércet/nap, egy kereskedő ~1.5-öt/nap tölt fel",
		["RESTOCK_RARITY_BIAS.name"]  = "Ritkaság-eltolás (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Mennyire részesítik előnyben a kereskedők a gyakori érceket\n0 = minden érc egyformán valószínű\n100 = normál súlyozás\n200 = ritka ércek szinte soha nem jelennek meg",
		["RESTOCK_LEVEL_BIAS.name"]   = "Szint-eltolás (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Mennyire befolyásolja a bányászati szinted az utánpótolt érceket\n0 = Kikapcsolva\n100 = Csak a szintedhez közeli ércek pótlása, és a képességed feletti ércek kizárása",
		["label.Few"]                 = "Kevés",
		["label.Many"]                = "Sok",
		["label.Slow"]                = "Lassú",
		["label.Fast"]                = "Gyors",
		["label.Flat"]                = "Egyenletes",
		["label.Biased"]              = "Eltolt",
		["unit.days"]                 = " nap",
	},
	Czech = {
		["Group.Restocking"]          = "Doplňování",
		["Group.Restocking.desc"]     = "Obchodníci doplní až jeden den rudy za návštěvu (max. 24h mezi návštěvami).\nKapacita = rychlost doplňování × dní zásob.",
		["RESTOCK_ORES.name"]         = "Obchodníci prodávají rudu",
		["RESTOCK_ORES.desc"]         = "Kováři, obchodníci a další kupci budou mít rudu na prodej",
		["RESTOCK_DAYS.name"]         = "Dní zásob",
		["RESTOCK_DAYS.desc"]         = "Kolik dní rudy může obchodník uchovávat\nKovář s 3/den a 2 dny drží 6, zastavárník s 0.25/den drží 1",
		["RESTOCK_SPEED.name"]        = "Rychlost doplňování (%)",
		["RESTOCK_SPEED.desc"]        = "Jak rychle obchodníci doplňují rudu mezi návštěvami\nPři 100% kovář doplní ~3 rudy/den, obchodník ~1.5/den",
		["RESTOCK_RARITY_BIAS.name"]  = "Vliv vzácnosti (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "Jak silně obchodníci upřednostňují běžné rudy\n0 = všechny rudy stejně pravděpodobné\n100 = normální váhy\n200 = vzácné rudy se téměř neobjevují",
		["RESTOCK_LEVEL_BIAS.name"]   = "Vliv úrovně (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "Jak moc váš stupeň těžby ovlivňuje doplňované rudy\n0 = Vypnuto\n100 = Doplňovat pouze rudy blízko vaší úrovně a blokovat rudy výrazně nad vaší dovedností",
		["label.Few"]                 = "Málo",
		["label.Many"]                = "Hodně",
		["label.Slow"]                = "Pomalu",
		["label.Fast"]                = "Rychle",
		["label.Flat"]                = "Rovnoměrně",
		["label.Biased"]              = "Vychýleno",
		["unit.days"]                 = " dní",
	},
	Japanese = {
		["Group.Restocking"]          = "補充",
		["Group.Restocking.desc"]     = "商人は訪問ごとに最大1日分の鉱石を補充します（訪問間隔は最大24時間まで計算）。\n在庫容量 = 補充速度 × 在庫日数。",
		["RESTOCK_ORES.name"]         = "商人が鉱石を販売",
		["RESTOCK_ORES.desc"]         = "鍛冶屋、交易商、その他の商人が鉱石を販売します",
		["RESTOCK_DAYS.name"]         = "在庫日数",
		["RESTOCK_DAYS.desc"]         = "商人が保持できる鉱石の日数\n鍛冶屋は3/日で2日なら6個、質屋は0.25/日なら1個",
		["RESTOCK_SPEED.name"]        = "補充速度 (%)",
		["RESTOCK_SPEED.desc"]        = "訪問間に商人がどれだけ早く鉱石を補充するか\n100%で鍛冶屋は約3鉱石/日、交易商は約1.5/日を補充",
		["RESTOCK_RARITY_BIAS.name"]  = "希少度バイアス (%)",
		["RESTOCK_RARITY_BIAS.desc"]  = "商人がどれだけ一般的な鉱石を優先するか\n0 = すべての鉱石が同確率\n100 = 通常の重み付け\n200 = 希少な鉱石はほぼ出現しない",
		["RESTOCK_LEVEL_BIAS.name"]   = "レベル補正 (%)",
		["RESTOCK_LEVEL_BIAS.desc"]   = "採掘レベルが補充される鉱石の種類にどれだけ影響するか\n0 = 無効\n100 = 自分のレベル付近の鉱石のみ補充し、スキルを大きく超える鉱石を制限",
		["label.Few"]                 = "少",
		["label.Many"]                = "多",
		["label.Slow"]                = "遅い",
		["label.Fast"]                = "速い",
		["label.Flat"]                = "均一",
		["label.Biased"]              = "偏重",
		["unit.days"]                 = " 日",
	},
}

local core = require('openmw.core')

local function detectLanguage()
	local adventurer = core.getGMST("sCustomClassName")
	local yes = core.getGMST("sYes")

	if     adventurer == "Aventurier"              then return "French"
	elseif adventurer == "Abenteurer"              then return "German"
	elseif adventurer == "Poszukiwacz przygód"     then return "Polish"
	elseif adventurer == "Авантюрист"              then return "Russian"
	elseif adventurer == "Aventurero"              then return "Spanish"
	elseif adventurer == "Avventuriero"            then return "Italian"
	elseif adventurer == "Kalandozó"               then return "Hungarian"
	elseif adventurer == "Dobrodruh"               then return "Czech"
	elseif adventurer == "冒険者"                   then return "Japanese"
	elseif adventurer == "Adventurer"              then return "English"
	end

	-- fallback on sYes
	if     yes == "Oui"  then return "French"
	elseif yes == "Ja"   then return "German"
	elseif yes == "Tak"  then return "Polish"
	elseif yes == "Да"   then return "Russian"
	elseif yes == "Sí"   then return "Spanish"
	elseif yes == "Sì"   then return "Italian"
	elseif yes == "Igen" then return "Hungarian"
	elseif yes == "Ano"  then return "Czech"
	elseif yes == "はい"  then return "Japanese"
	end

	return "English"
end

local language = detectLanguage()

local tempSection = storage.globalSection('SettingsGlobal'..MODNAME..'Restocking')
local tempValue = tempSection:get("USE_TRANSLATIONS")
S_USE_TRANSLATIONS = tempValue == nil or tempValue

 
function L(key, fallback)
	local lang = S_USE_TRANSLATIONS and language or "English"
	local t = translations[lang]
	if t and t[key] then
		return t[key]
	end
	return fallback or key
end