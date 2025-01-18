return {
	["mod.name"] = "Barres de progression simples",
	["mod.auth.label"] = "Auteur : ",
	["mod.vers.label"] = "Version : ",

	["mod.info1"] = "Ce mod peut ajouter diverses barres informatives au HUD du jeu. Vous pouvez configurer la position, l'apparence et sélectionner les barres à afficher",
	["mod.info2"] = "Aucune barre n'est affichée par défaut. Pour voir quoi que ce soit ajouté par ce mod, vous devez d'abord sélectionner les barres dans la liste de l'onglet 'Sélectionner les barres'",
	["mod.info3"] = "Les barres suivantes sont prises en charge :\n- Progression des compétences\n- Durabilité de l'armure (par emplacement)\n- Quelques statistiques de personnage",


	["cfg.settings.label"] = "Paramètres",

	["cfg.settings.system.label"] = "Système",
	["cfg.settings.enable.label"] = "Activer",
	["cfg.settings.enable.description"] = "Activer ou désactiver ce mod dans son ensemble (nécessite un redémarrage)",
	["cfg.settings.logging.label"] = "Niveau de journalisation",
	["cfg.settings.logging.description"] = "Définir le niveau de journalisation. Restez sur NONE ou ERROR sauf si vous effectuez un débogage. Tout niveau supérieur à WARN ajoute l'onglet 'Débogage' avec des options de débogage supplémentaires",

	["cfg.settings.position.label"] = "Position des barres",
	["cfg.settings.positionx.label"] = "Position X (horizontale)",
	["cfg.settings.positionx.description"] = "Définir la position des barres le long de l'axe horizontal",
	["cfg.settings.positiony.label"] = "Position Y (verticale)",
	["cfg.settings.positiony.description"] = "Définir la position des barres le long de l'axe vertical",

	["cfg.settings.appearance.label"] = "Apparence des barres",
	["cfg.settings.mode.label"] = "Disposition des barres",
	["cfg.settings.mode.description"] = "Sélectionnez la disposition des barres. Les options sont :\n\n- Minimaliste : afficher uniquement les barres\n- Compact : afficher les barres et les icônes\n- Étiqueté : afficher les barres et les étiquettes\n- Complet : tout afficher",
	
	["cfg.settings.mode.minimal"] = "Minimaliste (barres uniquement)",
	["cfg.settings.mode.compact"] = "Compact (barres et icônes)",
	["cfg.settings.mode.labeled"] = "Étiqueté (barres et étiquettes)",
	["cfg.settings.mode.maximal"] = "Complet (tout)",

	["cfg.settings.munchkin.label"] = "Afficher les comptes à rebours le cas échéant",
	["cfg.settings.munchkin.description"] = "Afficher le temps estimé restant pour une amélioration de compétence ou un épuisement de l'armure",
	["cfg.settings.width.label"] = "Largeur",
	["cfg.settings.width.description"] = "Définir la largeur des barres",
	["cfg.settings.padding.label"] = "Rembourrage",
	["cfg.settings.padding.description"] = "Définir l'espacement vide entre les barres",

	["cfg.selector.label"] = "Sélectionner les barres",

	["cfg.selector.left.label"] = "Afficher les valeurs",
	["cfg.selector.right.label"] = "Valeurs possibles",
	["cfg.selector.description"] = "Sélectionnez les valeurs à afficher sous forme de barres. La liste comprend toutes les compétences, même celles personnalisées. Les emplacements d'armure sont limités à ceux du jeu de base. Les emplacements d'armure et la cote d'armure total ne sont affichés que si l'armure est présente. Comment afficher les barres dans le jeu pour obtenir plus d'informations",

	["cfg.debug.label"] = "Débogage",

	["cfg.debug.info1"] = "Panneau de débogage",
	["cfg.debug.info2"] = "Cet onglet permet de configurer diverses options de débogage, notamment le niveau de journalisation et la sortie de débogage, et de tester certaines options dans le jeu. Quoi que vous fassiez, n'activez pas la journalisation par tick à moins d'être complètement sûr de ce que vous faites",
	["cfg.debug.info3"] = "Définissez le niveau de journalisation sur NONE ou ERROR pour masquer cet onglet. Vous pouvez modifier le niveau de journalisation à tout moment dans l'onglet des paramètres généraux",
	
	["cfg.debug.general.label"] = "Général",
	["cfg.debug.dump.label"] = "Vider le cache",
	["cfg.debug.dump.description"] = "Vider le cache dans MWSE.log. Le jeu doit être chargé sinon le cache sera vide",
	
	["cfg.debug.timestamp.label"] = "Imprimer les horodatages",
	["cfg.debug.timestamp.description"] = "Ajouter des horodatages à toute sortie de journalisation",
	["cfg.debug.logtick.label"] = "Enregistrer les ticks",
	["cfg.debug.logtick.description"] = "Ce mod traite les données du jeu et met à jour les barres en ticks, généralement équivalents à une seconde. Cette option active la sortie de débogage pour chaque tick. Ne laissez pas cette option activée, car le journal va devenir très volumineux très rapidement",
	["cfg.debug.output.label"] = "Sortie de débogage",
	["cfg.debug.output.description"] = "Sélectionnez où la sortie de débogage va, vers MWSE.log ou vers la console de jeu",
	
	["cfg.debug.testing.label"] = "Test",
	["cfg.debug.testing.description"] = "Chargez le jeu et modifiez ou testez le style et les valeurs",
	
	["cfg.debug.testbar.show"] = "Afficher la barre de test",
	["cfg.debug.testbar.hideother"] = "Masquer les autres barres",
	["cfg.debug.testbar.revert"] = "Rétablir les couleurs de la barre de test",
	["cfg.debug.testbar.value"] = "Valeur de la barre de test",
	
	["cfg.debug.symbol.label"] = "Largeur du symbole d'étiquette",
	["cfg.debug.symbol.description"] = "Modifiez la mesure arbitraire moyenne de la 'width' du symbole de police pour le calcul de la largeur de l'étiquette dans le jeu. Affectera toutes les étiquettes.\n\nLa largeur de l'étiquette est calculée pour éviter d'utiliser les dernières méthodes MWSE tes3ui.textLayout.\n\nValeur par défaut : 75 ",
	

	["pref.armor"] = "Armure",
	["pref.skill"] = "Compétence",
	["pref.char"] = "Personnage",
	
	["slot.helmet"] = "Casque",
	["slot.cuirass"] = "Cuirass",
	["slot.pauldronleft"] = "Épaulière gauche",
	["slot.pauldronright"] = "Épaulière droite",
	["slot.greaves"] = "Jambières",
	["slot.boots"] = "Bottes",
	["slot.gauntletleft"] = "Gantelet gauche",
	["slot.gauntletright"] = "Gantelet droit",
	["slot.shield"] = "Bouclier",
	["slot.bracerleft"] = "Bracelet gauche",
	["slot.bracerright"] = "Bracelet droit",

	["char.level"] = "Niveau suivant",
	["char.weight"] = "Encombrement",
	["char.armor"] = "Résumé de cote d'armure",
	["char.armorvsunarmored"] = "Cote d'armure contre sans armure",
	["char.armorbroken"] = "Armure en très mauvais état",
	["char.bounty"] = "Une prime sur ta tête",
	["char.reputation"] = "Réputation",


	["tooltip.lvl.title"] = "Progression vers le niveau suivant",
	["tooltip.weight.title"] = "Encombrement",
	["tooltip.bounty.title"] = "Prime sur la tête du joueur",
	["tooltip.rep.title"] = "Réputation du joueur",
	["tooltip.ar.title"] = "Résumé de la cote de l'armure",
	["tooltip.arua.title"] = "Cote d'armure (et sans armure)",
	["tooltip.arworst.title"] = "Pièce d'armure dans le pire état",
	["tooltip.test.title"] = "Barre de test",

	["tooltip.ar.stats"] = "Statistiques détaillées :",
	["tooltip.ar.current"] = "Cote de l'armure actuelle : ",
	["tooltip.ar.max"] = "Cote de l'armure maximale : ",
	["tooltip.ar.ua"] = "Contribution sans armure : ",
	["tooltip.ar.uamax"] = "Maximum sans armure : ",

	["tooltip.lvl.of"] = " de ",
	["tooltip.lvl.to"] = " au niveau suivant",

	["tooltip.timer.h"] = "h",
	["tooltip.timer.m"] = "m",
	["tooltip.timer.s"] = "s",

	["tooltip.ar.note"] = "Les statistiques représentent les cotes d'armure actuels et maximum, y compris les emplacements sans armure. La cote maximum est ce qu'il serait si toutes les pièces d'armure n'étaient pas endommagées. Les formules de jeu de base sont utilisées pour tous les calculs",
	["tooltip.arw.note"] = "La liste représente toutes les pièces d'armure actuellement portées par le joueur, ainsi que leur état et leur contribution effective à la cote d'armure. Celui qui a le pire % est affiché sur la barre",
	["tooltip.rep.note"] = "Votre statut de renommée globale actuel dans le monde",
	["tooltip.bounty.note"] = "Rendez-vous auprès de votre représentant local de la guilde des voleurs pour le supprimer",
	["tooltip.weight.note"] = "Poids total que votre personnage porte. Vous ne pouvez pas bouger lorsqu'il dépasse votre capacité de charge",
	["tooltip.lvl.note"] = "La progression vers le niveau suivant est une somme de mises à niveau des compétences mineures et majeures. Les points au-dessus de 10 sont transférés au niveau suivant. Les mises à niveau qui comptent pour le multiplicateur d'attributs ne sont cependant pas conservées",
}
