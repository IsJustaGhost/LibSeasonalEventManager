
local ignore = true

if ignore then return end

local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

local lib = _G[LIB_IDENTIFIER]

local l_EVENT_NONE			= lib.constants.currentEventNone
local l_EVENT_UNKNOWN		= lib.constants.currentEventUnknown

local l_EVENT_TYPE_NONE		= lib.constants.eventTypeNone
local l_EVENT_TYPE_UNKNOWN	= lib.constants.eventTypeUnknown
local l_EVENT_TYPE_TICKETS	= lib.constants.eventTypeTickets
local l_EVENT_TYPE_BG		= lib.constants.eventTypeBG

local l_REWARDS_BY_NONE		= lib.constants.rewardsByNone
local l_REWARDS_BY_UNKNOWN	= lib.constants.rewardsByUnknown
local l_REWARDS_BY_QUEST	= lib.constants.rewardsByQuest
local l_REWARDS_BY_LOOT		= lib.constants.rewardsByLoot
local l_REWARDS_BY_TARGET	= lib.constants.rewardsByTarget


lib.eventsToIndexMap[l_EVENT_UNKNOWN] = {
	['index'] = 1,
	['eventType'] = l_EVENT_TYPE_TICKETS,
	['rewardsBy'] = l_REWARDS_BY_UNKNOWN,
	['maxDailyRewards'] = 0,
}

	
	
local function getDailyResetTimeRemainingSeconds()
	local secondsRemaining = math.floor(lastTime - frameTimeSeconds)
	return secondsRemaining > 0 and secondsRemaining or 0
end
getDailyResetTimeRemainingSeconds()
lib.GetDailyResetTimeRemainingSeconds = getDailyResetTimeRemainingSeconds

function lib:CheckForAndGetActiveEventType()
	local activeType = l_EVENT_TYPE_NONE
	if currentDay < daysPerEvent then
	-- Set this to the event type you want to test.
		activeType = l_EVENT_TYPE_TICKETS
	end

	return activeType
end

-- Changing this so gold will trigger checks
REWARD_TYPE_EVENT_TICKETS = REWARD_TYPE_MONEY

---------------------------------------------------------------------------
-- Debug events
---------------------------------------------------------------------------
local events = {
	{ -- Woodwork Raw Material
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TYPE_TARGET,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			4439, 23117, 818, 23118, 23137, 802, 23138, 521, 71199, 23119
		},
	},
	{ -- Blacksmith Raw Material
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TICKETS_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			4482, 23104, 23105, 23133, 5820, 808, 23103, 23134, 71198, 23135
		},
	},
	{ -- Clothier Raw Material
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TICKETS_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			723097, 4448, 23143, 23095, 71200, 23129, 23131, 4464, 33218, 812,
			33217, 33219, 23130, 33220, 793, 71239, 4478, 800, 6020, 23142
		},
	},
	{ -- Reagents
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TICKETS_LOOT,
		['maxDailyRewards'] = 2,
		['itemIds'] = {
			77583, 30157, 30148, 30160, 77585, 150669, 139020, 30164, 30161,
			150672, 150671, 150789, 150731, 30162, 30151, 77587, 30156, 30158,
			30155, 30163, 77591, 30153, 77590, 30165, 139019, 77589, 77584,
			0149, 77581, 150670, 30152, 30166, 30154, 0159
		},
	},
	{ -- Vivec City Hall of Justice
		['eventType'] = l_EVENT_TYPE_TICKETS,
		['rewardsBy'] = l_EVENT_TICKETS_QUEST,
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


---------------------------------------------------------------------------
-- Simulation
---------------------------------------------------------------------------
local eventType = l_EVENT_TYPE_TICKETS

-- Event run time simulation.
local lastTime = 0
local secPerDay = 30
local daysPerEvent = 2
local currentDay = 0

local frameTimeSeconds

local function updateTime(timeMS)
--	frameTimeSeconds = math.floor(timeMS / 1000)
	if lastTime <= timeMS then
		lastTime = timeMS + (secPerDay * 1000)
		
		if daysPerEvent > 0 then
			if currentDay > daysPerEvent then
				currentDay = 1
			else
				currentDay = currentDay + 1
			end
		
			if currentDay > daysPerEvent then
				d( '-- No Event Active --')
			else
				d( '-- Event Day: ' .. (currentDay) .. ' --')
			end
		else
			currentDay = 0
		end
	end
end
updateTime(GetFrameTimeMilliseconds())

EVENT_MANAGER:RegisterForUpdate(LIB_IDENTIFIER .. '_ResetTimeUpdate', 1000, updateTime)

local function isActive()
	return daysPerEvent > 0 and currentDay <= daysPerEvent
end

---------------------------------------------------------------------------
-- Simulation event
---------------------------------------------------------------------------
local original_CheckForAndGetActiveEventType = lib.CheckForAndGetActiveEventType
local original_GetActiveBattlegound = lib.GetActiveBattlegound
local battlegroundId = 82

local function setupDebug(self)
	if eventType == l_EVENT_TYPE_NONE then
		self.GetActiveBattlegound = original_GetActiveBattlegound
		self.CheckForAndGetActiveEventType = original_CheckForAndGetActiveEventType
	elseif eventType == l_EVENT_TYPE_UNKNOWN then
		self.GetActiveBattlegound = original_GetActiveBattlegound
		self.CheckForAndGetActiveEventType = original_CheckForAndGetActiveEventType
	elseif eventType == l_EVENT_TYPE_TICKETS then
		self.GetActiveBattlegound = original_GetActiveBattlegound
		
		self.CheckForAndGetActiveEventType = function()
			local activeType = l_EVENT_TYPE_NONE
			if isActive() then
			-- Set this to the event type you want to test.
				activeType = l_EVENT_TYPE_TICKETS
			end

			return activeType
		end
		-- Changing this so gold will trigger checks
		REWARD_TYPE_EVENT_TICKETS = REWARD_TYPE_MONEY
		
	elseif eventType == l_EVENT_TYPE_BG then
		self.CheckForAndGetActiveEventType = original_CheckForAndGetActiveEventType
		local standardBatlegrounds = {
			[1] = true,		-- Group Random Battleground
			[2] = true,		-- Group Random Battleground
			[67] = true,	-- Solo Random Battleground
			[68] = true,	-- Solo Random Battleground
		}
		
		self.GetActiveBattlegound = function()
			for _, activityType in pairs({LFG_ACTIVITY_BATTLE_GROUND_CHAMPION,LFG_ACTIVITY_BATTLE_GROUND_NON_CHAMPION,LFG_ACTIVITY_BATTLE_GROUND_LOW_LEVEL}) do
				for id, location in pairs(ZO_ACTIVITY_FINDER_ROOT_MANAGER.locationSetsLookupData[activityType]) do
					if not standardBatlegrounds[id] then
						if id == battlegroundId and currentDay < daysPerEvent then
							return id
						end
					end
				end
			end
		end

		--[[ Battleground 
			[1] = true, -- Group Random Battleground
			[2] = true, -- Group Random Battleground
			[67] = true, -- Solo Random Battleground
			[68] = true, -- Solo Random Battleground
			--PVP Weekend
			[82] = true, -- Group Chaos Ball PVP Weekend
			[83] = true, -- Group Crazy King PVP Weekend
			[84] = true, -- Group Relic PVP Weekend
			[85] = true, -- Group Deathmatch PVP Weekend
			[86] = true, -- Group Domination PVP Weekend
			[87] = true, -- Solo Relic PVP Weekend
			[88] = true, -- Solo Chaos Ball PVP Weekend
			[89] = true, -- Solo Crazy King PVP Weekend
			[90] = true, -- Solo Deathmatch PVP Weekend
			[91] = true, -- Solo Domination PVP Weekend
			[92] = true, -- Group Chaos Ball PVP Weekend
			[93] = true, -- Group Crazy King PVP Weekend
			[94] = true, -- Group Relic PVP Weekend
			[95] = true, -- Group Deathmatch PVP Weekend
			[96] = true, -- Group Domination PVP Weekend
			[97] = true, -- Solo Chaos Ball PVP Weekend
			[98] = true, -- Solo Crazy King PVP Weekend
			[99] = true, -- Solo Relic PVP Weekend
			[100] = true, -- Solo Deathmatch PVP Weekend
			[101] = true, -- Solo Domination PVP Weekend
		]]
	end
end
setupDebug(lib)

---------------------------------------------------------------------------
-- Simulation settings
---------------------------------------------------------------------------
--	/script IJA_Seasonal_Event_Manager:SetDebugEventType(3)
function lib:SetDebugEventType(newEventType)
	eventType = newEventType
	setupDebug(self)
end

--	/script IJA_Seasonal_Event_Manager:SetDebugDaysPerEvent(3)
function lib:SetDebugDaysPerEvent(days)
	daysPerEvent = days
	currentDay = daysPerEvent
end

--	/script IJA_Seasonal_Event_Manager:SetDebugSecondsPerDay(10)
function lib:SetDebugSecondsPerDay(secs)
	secPerDay = secs
end

--	/script IJA_Seasonal_Event_Manager:SetDebugBattlegroundId(100)
function lib:SetDebugBattlegroundId(id)
	battlegroundId = id
end

