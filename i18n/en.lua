------------------------------------------------
-- English localization for LibSeasonalEventManager
------------------------------------------------

local lib = _G["LibSeasonalEventManager"]
lib.strings = {}
lib.strings.titles = {
	'UnKnown',
	'The Anniversary Jubilee',
	'The Jester\'s Festival',
	'Whitestrake\'s Mayhem Celebration',
	'The Witch\'s Festival',
	'New Life Festival',
	'Undaunted Celebration',
	'Season of the Dragon Celebration',
	'Daedric War Celebration Event',
	'Zeal of Zenithar',
	'Dark Heart of Skyrim Celebration',

--	'Explorer's Celebration', -- No Impresario 

--	'Deathmatch Battleground Weekend',
--	'Crazy King Battleground Weekend',
--	'Chaosball Battleground Weekend',
--	'Capture the Relic Battleground Weekend',
--	'',
}


local defaultDescription = 'During this event players can obtain a 100% XP buff and the opportunity to acquire Event Tickets and <<1>>'
lib.strings.descriptions = {
	'This is an unknown event. That means it was not detectable by map pins and, has yet to be detected by loot item or quest.',
	zo_strformat(defaultDescription, 'a variety of other items.'),
	zo_strformat(defaultDescription, 'a collection of Jester-themed items.'),
	'Whitestrake.',
	zo_strformat(defaultDescription, 'a collection of Witches Festival-themed items.'),
	zo_strformat(defaultDescription, 'a collection of New Life Festival-themed items.'),
	'This event is centered around the Undaunted faction, teaming up with other players and completing Group Dungeons. The first final dungeon boss you defeat in a day will drop Event Tickets and a special Glorious Undaunted Reward Box.',
	'During this event you will receive bonus loot, rewards and Event Tickets from exploring and questing within the Northern and Southern Elsweyr zones.',
	'The main feature of this event is numerous drops in Vvardenfell, the Clockwork City, Summerset, and Artaeum being doubled, including: Halls of Fabrication, Asylum Sanctorium, and Cloudrest Trial Bosses, Daily Delve and World Boss quest rewards, and crafting nodes.',
	'Complete any one of the goals of the daily quest Honest Toil to acquire Event Tickets and a gold-quality reward box: Zenithar\'s Sublime Parcel. Throughout the event you have a chance to receive purple-quality reward coffers, Zenithar\'s Delightful Parcels, through the various activities.',
	'The main feature of this event is numerous drops in Western Skyrim and the Reach being doubled, including: Kyne\'s Aegis and Vateshran Hollows, Trial Bosses, Daily Delve and World Boss quest rewards, and crafting nodes. Additionally, all bosses from the aforementioned trials, Icereach, Unhallowed Grave, Castle Thorn, and Stone Garden and the Delve and World Bosses will also drop additional loot.',

--	'',
--	'',
--	'',
}

