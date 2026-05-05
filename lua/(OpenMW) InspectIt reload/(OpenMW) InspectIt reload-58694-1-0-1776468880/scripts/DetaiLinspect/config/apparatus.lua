local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Apparatus] = {
        title = 'Apparatus',
        color = util.color.rgb(0.5, 0.3, 0.8),
        showQuality = true,
        showValue = true,
        uniqueDescriptions = {
			['apparatus_a_calcinator_01'] = {
				'Basic Alchemy Calcinator',
				'Simple calcinator for heating and purifying substances.',
				'Location: Alchemy shops, beginner labs, general traders',
				'Description: A basic calcinator used for fundamental alchemy', 
				'processes — heating minerals, burning herbs, and simple', 
				'purification. Constructed from common metals with a basic', 
				'heating chamber.',
				'Suitable for novice alchemists. Limited heat control.'
			},

			['apparatus_a_retort_01'] = {
				'Basic Alchemy Retort',
				'Standard glass retort for distilling liquids.',
				'Location: Alchemy labs, shops, apprentice guilds',
				'Description: A simple glass retort designed for basic', 
				'distillation processes. Features a single chamber and basic', 
				'condensing coil.',
				'Common among novice alchemists. Prone to cracking under high', 
				'heat.'
			},

			['apparatus_a_alembic_01'] = {
				'Basic Alchemy Alembic',
				'Standard alembic for complex distillations.',
				'Type: Apparatus (Alembic)',
				'Location: Well-equipped alchemy labs, intermediate shops',
				'Description: A basic alembic with a single distillation chamber', 
				'and basic condenser. Suitable for standard alchemical recipes', 
				'requiring distillation.',
				'Used by apprentice and journeyman alchemists. Limited efficiency.'
			},

			['apparatus_a_mortar_01'] = {
				'Basic Alchemy Mortar and Pestle',
				'Entry-level mortar and pestle for grinding ingredients.',
				'Type: Apparatus (Mortar)',
				'Location: Homes, alchemy shops, novice guilds',
				'Description: A simple mortar and pestle set made of standard', 
				'stone. Suitable for basic ingredient grinding and mixing.',
				'Common and affordable. Does not enhance alchemy skills.'
			},

			['apparatus_j_mortar_01'] = {
				'Journeyman Alchemy Mortar',
				'Improved mortar and pestle with better grinding surface.',
				'Type: Apparatus (Mortar, Journeyman)',
				'Location: Journeyman alchemy labs, mid-tier shops',
				'Description: A refined mortar and pestle set crafted from denser', 
				'stone, providing a smoother grinding surface. Ideal for', 
				'intermediate alchemical processes.',
				'Increases alchemy skill by 5 points. Sought after by journeyman', 
				'alchemists.'
			},

			['apparatus_m_mortar_01'] = {
				'Master Alchemy Mortar',
				'Expert-grade mortar and pestle for precise grinding.',
				'Type: Apparatus (Mortar, Master)',
				'Location: Master alchemists’ labs, rare chests, high-end shops',
				'Description: A masterfully crafted mortar and pestle set using', 
				'rare stone composites. Offers unparalleled precision for', 
				'grinding delicate ingredients.',
				"Extremely rare — a staple of professional alchemists."
			},

			['apparatus_g_mortar_01'] = {
				'Grandmaster Alchemy Mortar',
				'Elite mortar and pestle forged with ancient techniques.',
				'Type: Apparatus (Mortar, Grandmaster)',
				'Location: Grandmaster guilds, ancient labs, elite quest rewards',
				'Description: A legendary mortar and pestle set infused with', 
				'alchemical runes. Enhances the potency of ground ingredients', 
				'and aids in recipe discovery.',
				'Said to whisper alchemical secrets to its user.'
			},

			['apparatus_sm_mortar_01'] = {
				'Secretmaster Alchemy Mortar',
				'Mythical mortar known to the elite few.',
				'Type: Apparatus (Mortar, Secretmaster, Artifact)',
				'Location: Secret guild vaults, hidden labs, legendary treasure hoards',
				'Description: A divine mortar and pestle set crafted from meteoric stone.', 
				'Not only grinds ingredients but also reveals their hidden properties and', 
				'synergistic combinations.',
				'Legends say it can create potions of legendary power.'
			},

			['apparatus_j_alembic_01'] = {
				'Journeyman Alchemy Alembic',
				'Improved alembic with multiple chambers for refined distillation.',
				'Type: Apparatus (Alembic, Journeyman)',
				'Location: Intermediate alchemy labs, journeyman guilds',
				'Description: A journeyman-grade alembic featuring two distillation', 
				'chambers and an enhanced condenser system. Ideal for advanced', 
				'distillation techniques.',
				'Preferred by experienced alchemists.'
			},

			['apparatus_m_alembic_01'] = {
				'Master Alchemy Alembic',
				'Expert-grade alembic of master craftsmanship.',
				'Type: Apparatus (Alembic, Master)',
				'Location: Master alchemists’ labs, rare chests, elite shops',
				'Description: A master alembic with three interconnected chambers,', 
				'precision valves, and a refined condensing system. Enables the', 
				'creation of complex elixirs and potions.',
				'Owned only by the most skilled alchemists.'
			},

			['apparatus_g_alembic_01'] = {
				'Grandmaster Alchemy Alembic',
				'Elite alembic forged with ancient alchemical knowledge.',
				'Type: Apparatus (Alembic, Grandmaster)',
				'Location: Grandmaster guilds, ancient labs, elite quest rewards',
				'Description: A grandmaster alembic with five chambers, automated', 
				'valves, and enchanted condensation coils. Capable of creating', 
				'potions with multiple effects and enhanced potency.',
				'Legends say it can distill the essence of magic itself.'
			},

			['apparatus_sm_alembic_01'] = {
				'Secretmaster Alchemy Alembic',
				'Mythical alembic known to the elite few.',
				'Type: Apparatus (Alembic, Secretmaster, Artifact)',
				'Location: Secret guild vaults, hidden labs, legendary treasure hoards',
				'Description: A divine alembic crafted from enchanted crystal. Not only', 
				'distills liquids but also imbues them with magical properties and', 
				'ancient knowledge.',
				'Said to be capable of creating potions that defy the laws of nature.'
			},

			['apparatus_j_calcinator_01'] = {
				'Journeyman Alchemy Calcinator',
				'Improved calcinator with better heat distribution.',
				'Type: Apparatus (Calcinator, Journeyman)',
				'Location: Intermediate alchemy labs, journeyman guilds',
				'Description: A journeyman-grade calcinator featuring an enhanced', 
				'heating chamber and improved heat insulation. Ideal for advanced', 
				'purification and mineral processing.',
				'Preferred by experienced alchemists for its efficiency.'
			},

			['apparatus_m_calcinator_01'] = {
				'Master Alchemy Calcinator',
				'Expert-grade calcinator made of reinforced materials.',
				'Type: Apparatus (Calcinator, Master)',
				'Location: Master alchemists’ labs, rare chests, elite shops',
				'Description: A master calcinator with a triple-layered heating', 
				'chamber, precision temperature controls, and reinforced construction.', 
				'Capable of withstanding extreme temperatures and processing rare', 
				'minerals.',
				'Used by the most skilled alchemists for high-end recipes.'
			},

			['apparatus_g_calcinator_01'] = {
				'Grandmaster Alchemy Calcinator',
				'Elite calcinator forged with ancient alchemical knowledge.',
				'Type: Apparatus (Calcinator, Grandmaster)',
				'Location: Grandmaster guilds, ancient labs, elite quest rewards',
				'Description: A grandmaster calcinator featuring automated temperature', 
				'regulation, enchanted heat retention, and precision control mechanisms.', 
				'Enables the processing of volatile and rare substances.',
				'Legends say it can purify even the most unstable magical essences.'
			},

			['apparatus_sm_calcinator_01'] = {
				'Secretmaster Alchemy Calcinator',
				'Mythical calcinator known to the elite few.',
				'Type: Apparatus (Calcinator, Secretmaster, Artifact)',
				'Location: Secret guild vaults, hidden labs, legendary treasure hoards',
				'Description: A divine calcinator crafted from enchanted metals.', 
				'Not only heats substances but also enhances their magical properties', 
				'and reveals hidden alchemical secrets.',
				'Said to be capable of creating essences of unparalleled purity.'
			},

			['apparatus_j_retort_01'] = {
				'Journeyman Alchemy Retort',
				'Improved retort with better heat resistance.',
				'Type: Apparatus (Retort, Journeyman)',
				'Location: Wealthy alchemists’ workshops, mid-tier labs',
				'Description: A journeyman-grade retort featuring reinforced glass', 
				'and enhanced heat insulation. Ideal for distilling complex potions', 
				'and elixirs.',
				'Prized for its durability and efficiency.'
			},

			['apparatus_m_retort_01'] = {
				'Master Alchemy Retort',
				'Expert-grade retort made of reinforced glass.',
				'Type: Apparatus (Retort, Master)',
				'Location: Master alchemists’ labs, rare chests, elite shops',
				'Description: A master retort with multiple distillation chambers,', 
				'precision seals, and reinforced construction. Capable of handling', 
				'volatile substances and complex distillation processes.',
				'Only a few exist in Tamriel.'
			},

			['apparatus_g_retort_01'] = {
				'Grandmaster Alchemy Retort',
				'Elite retort forged with ancient alchemical knowledge.',
				'Type: Apparatus (Retort, Grandmaster)',
				'Location: Grandmaster guilds, ancient labs, elite quest rewards',
				'Description: A grandmaster retort featuring enchanted glass, automated', 
				'distillation systems, and precision control mechanisms. Enables', 
				'the creation of complex potions with multiple effects.',
				'Legends say it can distill the purest essences known to alchemy.'
			},

			['apparatus_sm_retort_01'] = {
				'Secretmaster Alchemy Retort',
				'Mythical retort known to the elite few.',
				'Type: Apparatus (Retort, Secretmaster, Artifact)',
				'Location: Secret guild vaults, hidden labs, legendary treasure hoards',
				'Description: A divine retort crafted from enchanted crystal.', 
				'Not only distills liquids but also imbues them with magical properties', 
				'and ancient knowledge.',
				'Said to be capable of creating potions of legendary power.'
			},

			['apparatus_a_spipe_01'] = {
				'Basic Alchemy Spirit Pipe',
				'Simple distillation pipe for basic alchemical processes.',
				'Type: Apparatus (Spirit Pipe)',
				'Location: Beginner alchemy labs, general traders',
				'Description: A basic spirit pipe used for connecting alchemical', 
				'apparatuses and directing distilled vapors.',
				'Compatible with basic alchemical setups. Limited functionality.'
			},

			['apparatus_a_spipe_tsiya'] = {
				'Tsiyal Alchemy Spirit Pipe',
				'Specialized spirit pipe from the Tsiyal region.',
				'Type: Apparatus (Spirit Pipe, Unique)',
				'Location: Ancient Tsiyal ruins, rare alchemical discoveries',
				'Description: An ancient spirit pipe crafted using lost techniques.', 
				'Features unique joint designs and superior heat resistance.',
				'Compatible with various alchemical apparatuses. Known for its', 
				'durability and efficiency.'
			}
        }
    }
}