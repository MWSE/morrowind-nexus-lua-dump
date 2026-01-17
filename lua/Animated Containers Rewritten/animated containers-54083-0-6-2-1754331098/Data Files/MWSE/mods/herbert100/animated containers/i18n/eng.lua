return {
	MCM={
		main_page={

			auto_close_if_empty={
				label="Automatically close empty containers?";
				description="This setting requires the previous setting to be enabled.\n\n\z
                    \z
                    If enabled, empty containers will be closed automatically (.e.g. whenever the inventory menu is closed.)\n\n\z
                    \z
                    If disabled, then empty containers will not close automatically.\n\n\z
                        \z
                        So, if this setting is disabled and the previous setting is enabled, then containers will be closed automatically if they're not empty.\z
                    \z
                    Note: other mods can extend the functionality of this setting. \z
                    For example, this setting can allow QuickLoot to close containers whenever the QuickLoot menu disappears.\n\n\z
                    \z
                    This mod (Animated Containers) will only use this setting for the following purpose: \z
                    closing containers after you loot them, provided the \"Show loot menu after animation finishes?\" setting is enabled.\z
                ";
			};

		};
		advanced={

			log={
				label="Log Settings";
				description="These let you prevent some repetitive information from being logged on every launch.\n\n\z
					This can be helpful when debugging if you want to declutter the logs. The log level each message is printed at is indicated in the name of each setting. \n\n\z
					These settings will only take effect if the log level is higher than the level indicated in the relevant setting.\n\n\z
					For example, changing the value of a \"TRACE\" option won't do anything unless the current logging level is set to trace.";

				log_replace_table={
					label="TRACE: Print a message containing the table of meshes to replace?";
					description="Happens during startup.";
				};
				log_every_replacement={
					label="TRACE: print a message for every mesh that gets replaced?";
					description="Happens during startup. This will result in a lot of messages.";
				};
				log_add_interop_data={
					label="TRACE: print interop data being added.";
					description="Happens during startup.";
				};

			};
		};
	};
}
