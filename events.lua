
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

local lib = _G[LIB_IDENTIFIER]

local getString 			= lib.GetString

local l_EVENT_NONE			= lib.constants.currentEventNone
local l_EVENT_UNKNOWN		= lib.constants.currentEventUnknown

local l_EVENT_TYPE_NONE		= lib.constants.eventTypeNone
local l_EVENT_TYPE_UNKNOWN	= lib.constants.eventTypeUnknown
local l_EVENT_TYPE_TICKETS	= lib.constants.eventTypeTickets

local l_REWARDS_BY_NONE		= lib.constants.rewardsByNone
local l_REWARDS_BY_UNKNOWN	= lib.constants.rewardsByUnknown
local l_REWARDS_BY_QUEST	= lib.constants.rewardsByQuest
local l_REWARDS_BY_LOOT		= lib.constants.rewardsByLoot
local l_REWARDS_BY_TARGET	= lib.constants.rewardsByTarget

local l_EVENT_HAS_MAP_LOCATION 	= 'has_map_location'
local l_EVENT_NO_MAP_LOCATION 	= 'no_map_location'

lib.eventsToIndexMap[l_EVENT_UNKNOWN] = {
	['eventType'] = l_EVENT_TYPE_UNKNOWN,
	['rewardsBy'] = l_REWARDS_BY_UNKNOWN,
	['maxDailyRewards'] = 0,
}

---------------------------------------------------------------------------
-- Events local
---------------------------------------------------------------------------
local events = {
	{ -- Anniversary Jubilee
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_REWARDS_BY_TARGET,
		['maxDailyRewards'] = 3,
		['targets'] = {lib.constants.currentJubileeCakeName},
		['location'] = {
			-- set use interaction on item
			["zoneIndex"] = 2,
			["subzoneIndex"] = 68,
			["locationIndex"] = 23,
		},
	},
	{ -- Jester's Festival
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_REWARDS_BY_QUEST,
		['maxDailyRewards'] = 3,
		['location'] = {
			["zoneIndex"] = 2,
			["subzoneIndex"] = 68,
			["locationIndex"] = 22,
		},
	},
	{ -- Whitestrake's Mayhem Celebration
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_REWARDS_BY_QUEST,
		['maxDailyRewards'] = 3,
		['location'] = {
			["zoneIndex"] = 2,
			["subzoneIndex"] = 68,
			["locationIndex"] = 27,
		},
	},
	{ -- Witch's Festival
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_REWARDS_BY_LOOT,
		['maxDailyRewards'] = 2,
		['location'] = {
			["zoneIndex"] = 2,
			["subzoneIndex"] = 0,
			["locationIndex"] = 4,
		},
	},
	{ -- New Life Festival
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TYPE_QUEST,
		['maxDailyRewards'] = 3,
		['itemIds'] = {
			96390, 133557, 141823, 156779, 182494, 171327, 192368
		},
		['quests'] = {
			5855, 5852, 5834, 5856, 5811, 5839, 5838, 5837, 5845
		--	[15] = {5855, 5852, 5834, 5856, 5811, 5839, 5838, 5837, 5845},
		},
	},
	{ -- Undaunted Celebration
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TYPE_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			171268,156717,156679
		},
	},
	-- ?
	{ -- Season of the Dragon Celebration
		['eventType'] = l_EVENT_TYPE_UNKNOWN,
		['rewardsBy'] = l_EVENT_TYPE_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {-- Elsweyr Coffer
			175580, 193735, 175579, 193734
		},
		['quests'] = {
				6357, 6378, 6382, 6377, 6380, 6379, 6381, 6359, 6362, 6361, 6363, 6360, 6356,
				6435, 3442, 6405, 6433, 6429, 6428, 6430, 6406
			--[[
			[681] = { -- Northern Elsweyr
				6357, 6378, 6382, 6377, 6380, 6379, 6381, 6359, 6362, 6361, 6363, 6360, 6356
			},
			[720] = { -- Southern Elsweyr
				6435, 3442, 6405, 6433, 6429, 6428, 6430, 6406
			},
			]]
			
		},
	},
	{ -- Daedric War Celebration Event
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TYPE_QUEST,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			182592,182599,171480,171476
		},
		['quests'] = {
				5912, 5913, 5907, 5916, 5918, 5865, 5866, 5904, 5906, 5956, 5962, 5961, 5934, 
				5915, 5958, 5927, 5928, 5924, 5925, 5929, 5930, 5926, 5910, 5911, 5908, 5909, 
				6089, 6081, 6088, 6073, 6080, 6079, 6076, 6077, 6039, 6037, 
				6041, 2952, 2975, 6042, 6070, 6071, 6024, 6106, 6072, 6107,
				6159, 6152, 6158, 6157, 6156, 6160, 6084, 6085, 6086, 6087, 6082, 6083
			--[[
			-- Vvardenfell
			[467] = {
				5912, 5913, 5907, 5916, 5918, 5865, 5866, 5904, 5906, 5956, 5962, 5961, 5934, 
				5915, 5958, 5927, 5928, 5924, 5925, 5929, 5930, 5926, 5910, 5911, 5908, 5909, 
			},
			-- Clockwork City
			[589] = {
				6089, 6081, 6088, 6073, 6080, 6079, 6076, 6077, 6039, 6037, 
				6041, 2952, 2975, 6042, 6070, 6071, 6024, 6106, 6072, 6107,
			},
			-- Summerset
			[616] = {
				6159, 6152, 6158, 6157, 6156, 6160, 6084, 6085, 6086, 6087, 6082, 6083
			},
			]]
		},
	},
	{ -- Zeal of Zenithar
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TYPE_QUEST,
		['maxDailyRewards'] = 3,
		['itemIds'] = { 
			187746,187701,187700
		},
		['quests'] = {
			6750, 6749
		--	[500] = {6750, 6749}
			
		},
	},
	{ -- Dark Heart of Skyrim Celebration
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TYPE_QUEST,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			193762
		},
		['quests'] = {
			6512, 6527, 6519, 6517, 6509, 6526, 6518, 6494, 6524, 6493, 6495, 6520, 6523,
			6559, 6585, 6556, 6582, 6583, 6584, 6581, 6573, 6557, 6569, 6571, 6567, 6572,
			6603, 6604, 6600, 6605, 6602, 6606, 6601, 6610, 6561
		},
	},
}

lib.events = events
