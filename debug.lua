
local ignore = true

if ignore then return end

local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

local lib = _G[LIB_IDENTIFIER]

-- Event run time simulation.
local lastTime = 0
local daysPast = 0
local secPerDay = 30
local daysPerEvent = 5
local function getDailyResetTimeRemainingSeconds()
	local frameTimeSeconds = GetFrameTimeSeconds()
	if lastTime <= frameTimeSeconds then
		lastTime = frameTimeSeconds + secPerDay
		
		if daysPast > daysPerEvent then
			daysPast = 0
		else
			daysPast = daysPast + 1
		end
	end
	
	local secondsRemaining = math.floor(lastTime - frameTimeSeconds)
	return secondsRemaining > 0 and secondsRemaining or 0
end
lib.GetDailyResetTimeRemainingSeconds = getDailyResetTimeRemainingSeconds

local function checkForActiveEvent()
	return daysPast <= daysPerEvent
end
lib.CheckForActiveEvent = checkForActiveEvent

-- Changing this so gold will trigger checks
REWARD_TYPE_EVENT_TICKETS = REWARD_TYPE_MONEY

---------------------------------------------------------------------------
-- Debug events
---------------------------------------------------------------------------
local events = {
	{ -- Woodwork Raw Material
		['eventType'] = VAR_EVENT_TYPE_TICKETS,
		['rewardsBy'] = VAR_EVENT_TYPE_TARGET,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			4439, 23117, 818, 23118, 23137, 802, 23138, 521, 71199, 23119
		},
	},
	{ -- Blacksmith Raw Material
		['eventType'] = VAR_EVENT_TYPE_TICKETS,
		['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			4482, 23104, 23105, 23133, 5820, 808, 23103, 23134, 71198, 23135
		},
	},
	{ -- Clothier Raw Material
		['eventType'] = VAR_EVENT_TYPE_TICKETS,
		['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			723097, 4448, 23143, 23095, 71200, 23129, 23131, 4464, 33218, 812,
			33217, 33219, 23130, 33220, 793, 71239, 4478, 800, 6020, 23142
		},
	},
	{ -- Reagents
		['eventType'] = VAR_EVENT_TYPE_TICKETS,
		['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			77583, 30157, 30148, 30160, 77585, 150669, 139020, 30164, 30161,
			150672, 150671, 150789, 150731, 30162, 30151, 77587, 30156, 30158,
			30155, 30163, 77591, 30153, 77590, 30165, 139019, 77589, 77584,
			0149, 77581, 150670, 30152, 30166, 30154, 0159
		},
	},
	{ -- Vivec City Hall of Justice
		['eventType'] = VAR_EVENT_TYPE_TICKETS,
		['rewardsBy'] = VAR_EVENT_TICKETS_QUEST,
		['maxDailyRewards'] = 2,
		['quests'] = {
			5906, 5904, 5866, 5865, 5918, 5916
		--	[467] = {5906, 5904, 5866, 5865, 5918, 5916},
		},
	},
}

local titles = {
	'Woodwork Raw Material',
	'Blacksmith Raw Material',
	'Clothier Raw Material',
	'Reagents',
	'Vivec City Daily Quests',
}

local descriptions = {
	'This is a test event. Updates on acquiring Woodwork Raw Material.',
	'This is a test event. Updates on acquiring Blacksmith Raw Material.',
	'This is a test event. Updates on acquiring Clothier Raw Material.',
	'This is a test event. Updates on acquiring Reagents.',
	'This is a test event. Updates on acquiring Vivec City Daily Quests from Beleru Omoril in the Hall of Justice.',
}

---------------------------------------------------------------------------
-- Add debug to lib
---------------------------------------------------------------------------
local function insertDebug(tbl, dest)
	for k, data in ipairs(tbl) do
		table.insert(dest, data)
	end
end

insertDebug(events, lib.events)
insertDebug(titles, lib.strings.titles)
insertDebug(descriptions, lib.strings.descriptions)

