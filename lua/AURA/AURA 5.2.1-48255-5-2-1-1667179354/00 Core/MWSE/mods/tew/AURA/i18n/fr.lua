-- DO NOT MODIFY THIS --
local this = {}
------------------------

--[[
							!!! IMPORTANT !!! --
	Translate ONLY the designated strings in the following tables.
	When translating, please make sure that punctuation, case, and spacing is preserved. --
	Don't worry about missing strings, they will be filled in with default (English) values. --
--]]

------------------------------------------------------------------------------------------------

-- MESSAGES --
-- This table contains strings used mainly in MCM and initial messages sent to MWSE log --
-- Translate ONLY the values on the right hand side of the = signs. --

this.messages = {
	audioWarning = "Le volume général et celui des effets sonores doit être à son maximum pour que le mod fonctionne correctement.",
	buildingSoundsStarted = "Construction d'objet sonore en cours.",
	buildingSoundsFinished = "Construction d'objet sonore terminée.",
	loadingFile = "Chargement du fichier :",
	oldFolderDeleted = "Ancienne version du mod détectée et supprimée.",
	oldFileDeleted = "Ancienne version d'un fichier du mod détecté et supprimé.",

	manifestConfirm = "Etes-vous sûr de vouloir retirer le fichier manifeste ?",
	manifestRemoved = "Fichier manifeste retiré.",

	initialised = "initialisé.",
	mainSettings = "Paramètres généraux",
	mainLabel = "par tewlwolow.\nAmélioration audio utilisant MWSE.",

	WtS = "Nécessite Watch the Skies.",

	settings = "Paramètres",
	default = "Par défaut",
	volume = "Volume",
	toggle = "Changer",
	chance = "Chances",
	version = "Version",

	modLanguage = "Langue du mod.",

	enableDebug = "Activer le mode débug ?",
	enableOutdoor = "Activer le module Ambiance Extérieure ?",
	enableInterior = "Activer le module Ambiance Intérieure ?",
	enablePopulated = "Activer le module Ambiance Population ?",
	enableInteriorWeather = "Activer le module Météo Intérieure ?",
	enableServiceVoices = "Activer le module Commentaires Services ?",
	enableUI = "Activer le module Interface ?",
	enableContainers = "Activer le module Conteneurs ?",
	enablePC = "Activer le module PJ ?",
	enableMisc = "Activer le module Divers ?",

	refreshManifest = "Actualiser le fichier manifeste",

	OA = "Ambiance Extérieure",
	OADesc = "Joue des sons d'ambiance en fonction du climat, de la météo, de la position du joueur et de l'heure de la journée.",
	OAVol = "Change le % de volume des sons du module Ambiance Extérieure.",
	playInteriorAmbient = "Activer les sons ambiants extérieurs dans les intérieurs ? Cela signifie que la dernière boucle extérieure en date sera jouée au niveau de chaque porte ou fenêtre menant à l'extérieur.",

	IA = "Ambiance Intérieure",
	IADesc = "Joue des sons d'ambiance en fonction du type d'intérieur. Inclut les tavernes, les guildes, les boutiques, les bibliothèques, les tombeaux, les grottes et les ruines.",
	IAVol = "Change le % de volume des sons du module Ambiance Intérieure.",

	enableTaverns = "Activer les musiques de taverne dépendant de la culture ? Notez que vous profiterez davantage de cette option si vous désactivez vos sous-dossiers 'Battle' et 'Explore' dans votre dossier 'Music' et n'utilisez pas de mod de musique.",
	tavernsBlacklist = "Liste noire des tavernes",
	tavernsDesc = "Sélectionnez les tavernes où les musiques sont désactivées.",
	tavernsDisabled = "Tavernes désactivées",
	tavernsEnabled = "Tavernes activées",

	PA = "Ambiance Population",
	PADesc = "Joue des sons d'ambiance dans les lieux peuplés commes les villes et les villages.",
	PAVol = "Change le % de volume des sons du module Ambiance Population.",

	IW = "Météo Intérieure",
	IWDesc = "Joue des sons liés à la météo dans les cellules intérieures.",
	IWVol = "Change le % de volume des sons du module Météo Intérieure.",

	SV = "Commentaires Services",
	SVDesc = "Joue des commentaires audio appropriés lorsqu'un PNJ vous rend un service.",
	SVVol = "Change le % de volume des sons du module Commentaires Services.",
	enableRepair = "Activer les commentaires audio sur les services de réparation ?",
	enableSpells = "Activer les commentaires audio sur les services de vente de sorts ?",
	enableTraining = "Activer les commentaires audio sur les services d'entraînement ?",
	enableSpellmaking = "Activer les commentaires audio sur les services de création de sort ?",
	enableEnchantment = "Activer les commentaires audio sur les services d'enchantement ?",
	enableTravel = "Activer les commentaires audio sur les services de voyage ?",
	enableBarter = "Activer les commentaires audio sur les services de marchandage ?",

	PC = "PJ",
	PCDesc = "Joue des sons en fonction du statut du PJ.",
	enableHealth = "Activer les sons lorsque la santé est basse ?",
	enableFatigue = "Activer les sons lorsque la fatigue est basse ?",
	enableMagicka = "Activer les sons lorsque la magie est basse ?",
	enableDisease = "Activer les sons lorsque le PJ souffre d'une maladie commune ?",
	enableBlight = "Activer les sons lorsque le PJ souffre du Fléau ?",
	vsVol = "Change le % de volume des sons des signes vitaux (santé, fatigue, magie, maladie, Fléau).",
	enableTaunts = "Activer les sons de provocation lorsque le PJ est en combat ?",
	tauntChance = "Change le % de chances qu'une provocation de combat soit lancée.",
	tVol = "Change le % de volume des provocations du PJ.",

	containers = "Conteneurs",
	containersDesc = "Joue des sons à l'ouverture et à la fermeture des conteneurs.",
	CVol = "Change le % de volume des sons du module Conteneurs.",

	UI = "Interface",
	UIDesc = "Joue des sons immersifs additionnels lors de l'utilisation de l'interface.",
	UITraining = "Activer les sons du menu d'entraînement ?",
	UITravel = "Activer les sons du menu de voyage ?",
	UISpells = "Activer les sons du menu des sorts ?",
	UIBarter = "Activer les sons du menu de marchandage ?",
	UIEating = "Activer les sons de restauration lors de la consommation de nourriture dans l'inventaire ?",
	UIVol = "Change le % de volume des sons du module Interface.",

	misc = "Divers",
	miscDesc = "Joue des sons additionnels divers.",
	rainSounds = "Activer les sons variables de la pluie en fonction du nombre de particules ?",
	rainOnStaticsSounds = "Activer le sons de la pluie pour certains objets à l'extérieur ? Nécessite des sons variables de la pluie.",
	windSounds = "Activer les sons variables du vent en fonction de la vitesse des nuages ?",
	playInteriorWind = "Activer les sons de vent en intérieur ? Cela signifie que la dernière boucle extérieure en date sera jouée au niveau de chaque porte ou fenêtre menant à l'extérieur.",
	windVol = "Change le % volume des sons de vent.",
	playSplash = "Activer les sons d'éclaboussures en entrant et sortant de l'eau ?",
	splashVol = "Change le % de volume des sons d'éclaboussures.",
	playYurtFlap = "Activer les sons des portes de yourte ou en peau d'ours ?",
	yurtVol = "Change le % de volume des sons des portes de yourte ou en peau d'ours."
}

------------------------------------------------------------------------------------------------

-- INTERIOR CELL NAMES --
-- This table contains cell names that interior module matches (matching the whole string as one word) --
-- Translate ONLY the values in the lists, DO NOT modify the list index --
-- For instance ["alc"] or ["mag"] should be preserved as they are, while names such as "Alchemist" or "Mages Guild" should be replaced with translation --
-- There might be some differences between language versions of course, so please try and verify whether the current translation makes sense for you locale --

this.interiorNames = {
	["alc"] = {
		"alchimiste", -- [[There is often less capital letters in the French version, this is not an oversight]]
		"apothicaire",
		"Tel Uvirith, maison d'Omavel",
		"guérisseur",
	},
	["cou"] = {
		"palais du Conseil telvanni",
		"palais du Conseil rédoran",
		"quartier des Manoirs",
		"siège",
		"Morag Tong",
		"zone dissimulée",
		"Grand conseil",
		"place",
		"complexes"
	},
	["mag"] = {
		"guilde des Mages" -- [[The names are the same in every city in the French version]]
	},
	["fig"] = {
		"guilde des Guerriers", -- [[Same here]]
	},
	["tem"] = {
		"Temple",
		"Maar Gan, sanctuaire",
		"chapelle de Vos",
		"Grand Sanctuaire",
		"Fane of the Ancestors", -- [[Doesn't exist in the base French version for some reason, maybe it's from a mod]]
		"Tiriramannu", -- [[Same here]]
	},
	["lib"] = {
		"bibliothèque",
		"bouquiniste",
		"livres"
	},
	["smi"] = {
		"forgeron",
		"armurier",
		"Weapons", -- [['weaponsmith' has the same translation as 'smith' in the French version]]
		"armurerie",
		"Smithy", -- [['smithy', 'armors' and 'blacksmith' don't appear in the base French version]]
		"Weapon",
		"Armors",
		"Blacksmith",
	},
	["tra"] = {
		"marchand",
		"prêteur sur gages",
		"quincailler",
		"Merchant", -- [[Doesn't appear in the base French version]]
		"Goods", -- [[Same translation for 'general goods' and 'general merchandise']]
		"ouvriers",
		"brasseurs",
		"auberge",
		"hôtel",
		"hostellerie", -- [[Two different translations for 'hostel' in the French version]]
	},
	["clo"] = {
		"tailleur", -- [['outfitter' has the same translation as 'clothier' and 'tailor' in the French version]]
	},
	["tom"] = {
		"tombeau",
		"sépulture",
		"crypte",
		"tertre",
		"catacombes",
	}
}

------------------------------------------------------------------------------------------------

-- TAVERN NAMES --
-- This is an additional table to bypass the regular, language-agnostic logic of matching taverns with publican's race --
-- Some places that should be taverns do not have any Publican NPC, hence the need to do additional cell name match as well --
-- Please see above for details about what and how to translate here --
this.tavernNames = {
	["dar"] = {
		"Marmite du Rat",
		"Maison des Plaisirs Terrestres",
		"Nation elfique"
	},
	["imp"] = {
		"Coeurébène, les Six Poissons",
		"Arrile"
	},
	["nor"] = {
		"Village Skaal, grande salle",
		"Solstheim, Thirsk" -- [[actually the same name in the French version, for obvious reasons]]
	}
}

------------------------------------------------------------------------------------------------


-- DO NOT MODIFY BELOW THIS LINE --
return this
