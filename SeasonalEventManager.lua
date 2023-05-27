
local LIB_IDENTIFIER, LIB_VERSION = "LibSeasonalEventManager", 01
if _G[LIB_IDENTIFIER] and _G[LIB_IDENTIFIER].version > LIB_VERSION then
	return
end

--[[
	This lib is self running.
	Using it normally should only require registering the update callback.
	
	The callback returns ([bool]eventActive, [object]eventOject)
		eventActive (true or false)
		
		
	This lib checks for running events on load and, on daily reset. 
	then, if an event is active, creates the eventObject based on 1 of the 4 detectable events, 
	or default info to be updated later by quest or item loot.
		
	eventOject:GetIndex()
		Used mainly by the lib to get the event info or saving by the add-on to compare later.
	eventOject:GetType()
		Currently, eventType is none, unknown, tickets
	eventOject:GetRewardsBy()
		Loot, quest, target (Jubilee Cake)
	eventOject:GetMaxDailyRewards()
		Last known amount of special rewards. Number of tickets per day
	eventOject:IsSameEvent(eventIndex)
		Used in add-ons to see if it's the same event that was previously running
		if add-on is saving eventIndex
		
		
		
		---------------------------------------------------------------------------------
		
		For comparing events with quests.
		The questIds are converted to names on load. 
		Then, on quest pickup, it compares the questNames if the event has not been identified.
		
		Since events can have quests in different zones, each zone's quests are added separately under it's zoneIndex
		['quests'] = {
			[zoneIndex] = {questId},
		},
		
		EVENTS_TO_INDEX_MAP
			Allows dynamically generate an index for all events to be used across loading for event lookup.
			EVENTS_TO_INDEX_MAP[eventIndex] = eventInfo
		
		ITEM_TO_INDEX_MAP
			Allows simplifying event lookup by itemId.
			ITEM_TO_INDEX_MAP[itemId] = eventIndex
		
		QUEST_TO_INDEX_MAP
			Allows simplifying event lookup by questName.
			QUEST_TO_INDEX_MAP[zoneIdex][questName] = eventIndex
		
		EVENTS_TO_INDEX_MAP[ ITEM_TO_INDEX_MAP[itemId] ]
		EVENTS_TO_INDEX_MAP[ QUEST_TO_INDEX_MAP[zoneIdex][questName] ]
]]

---------------------------------------------------------------------------
-- Locals
---------------------------------------------------------------------------

local VAR_TICKETS_MAX			= lib.constants.maxTickets
local VAR_EVENT_NONE			= lib.constants.currentEventNone
local VAR_EVENT_UNKNOWN			= lib.constants.currentEventUnknown

local VAR_EVENT_TYPE_NONE		= lib.constants.eventTypeNone
local VAR_EVENT_TYPE_UNKNOWN	= lib.constants.eventTypeUnknown
local VAR_EVENT_TYPE_TICKETS	= lib.constants.eventTypeTickets

local VAR_EVENT_TICKETS_NONE	= lib.constants.rewardsByNone
local VAR_EVENT_TICKETS_UNKNOWN	= lib.constants.rewardsByUnknown
local VAR_EVENT_TICKETS_QUEST	= lib.constants.rewardsByQuest
local VAR_EVENT_TICKETS_LOOT	= lib.constants.rewardsByLoot
local VAR_EVENT_TICKETS_TARGET	= lib.constants.rewardsByTarget

local var_EmptyString 			= lib.constants.stringEmpty

local reward_type_event_tickets	= REWARD_TYPE_EVENT_TICKETS

local var_defaultEvent = {
	['index'] 		= VAR_EVENT_UNKNOWN,
	['eventType'] = VAR_EVENT_TYPE_UNKNOWN,
	['rewardsBy'] = VAR_EVENT_TICKETS_NONE,
}

local var_blankEvent = {
	active = false,
	eventIndex = VAR_EVENT_NONE,
}

local defaultEventInfo = {
	['index'] 		= VAR_EVENT_UNKNOWN,
	['eventType'] 	= VAR_EVENT_UNKNOWN,
	['rewardsBy'] 	= VAR_EVENT_UNKNOWN,
}

local QUEST_TO_INDEX_MAP = {}
local ITEM_TO_INDEX_MAP = {}
local EVENTS_TO_INDEX_MAP = {
	[VAR_EVENT_UNKNOWN] = defaultEventInfo
}


local VAR_EVENT_HAS_MAP_LOCATION = 'has_map_location'
local VAR_EVENT_NO_MAP_LOCATION = 'no_map_location'

local EVENTS = {
	[VAR_EVENT_TYPE_TICKETS] = {
		[VAR_EVENT_HAS_MAP_LOCATION] = {
			{ -- Anniversary Jubilee
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_TARGET,
				['maxDailyRewards'] = 3,
				['location'] = {
					-- set use interaction on item
					["zoneIndex"] = 2,
					["subzoneIndex"] = 68,
					["locationIndex"] = 23,
				},
			},
			{ -- Jester's Festival
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_QUEST,
				['maxDailyRewards'] = 3,
				['location'] = {
					["zoneIndex"] = 2,
					["subzoneIndex"] = 68,
					["locationIndex"] = 22,
				},
			},
			{ -- Whitestrake's Mayhem Celebration
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_QUEST,
				['maxDailyRewards'] = 3,
				['location'] = {
					["zoneIndex"] = 2,
					["subzoneIndex"] = 68,
					["locationIndex"] = 27,
				},
			},
			{ -- Witch's Festival
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TICKETS_LOOT,
				['maxDailyRewards'] = 2,
				['location'] = {
					["zoneIndex"] = 2,
					["subzoneIndex"] = 0,
					["locationIndex"] = 4,
				},
			},
		},
		[VAR_EVENT_NO_MAP_LOCATION] = {
			{ -- New Life Festival
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
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
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_LOOT,
				['maxDailyRewards'] = 2,
				['itemIds'] = {
					171268,156717,156679
				},
			},
			-- ?
			{ -- Season of the Dragon Celebration
				['eventType'] = VAR_EVENT_TYPE_UNKNOWN,
				['rewardsBy'] = VAR_EVENT_TYPE_LOOT,
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
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
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
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
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
				['eventType'] = VAR_EVENT_TYPE_TICKETS,
				['rewardsBy'] = VAR_EVENT_TYPE_QUEST,
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
		},
	},
	[VAR_EVENT_TYPE_UNKNOWN] = {
	}
}

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
local function selectSubzone(zoneIndex, subzoneIndex)
	local normalizedX, normalizedZ = GetPOIMapInfo(zoneIndex, subzoneIndex)
	if ProcessMapClick(normalizedX, normalizedZ) == SET_MAP_RESULT_MAP_CHANGED then
		CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged", true)
		return SET_MAP_RESULT_MAP_CHANGED
	end
end

local function isMapLocationVisible(zoneIndex, subzoneIndex, locIndex)
	local currentZoneIndex = GetCurrentMapZoneIndex()
	-- make sure the map is currently displaying the correct zone
	if currentZoneIndex ~= zoneIndex then
	end
	WORLD_MAP_MANAGER:SetMapById((GetMapIdByIndex(zoneIndex)))
	
	if subzoneIndex > 0 then
		if selectSubzone(zoneIndex, subzoneIndex) ~= SET_MAP_RESULT_MAP_CHANGED then
			return false
		end
	end

	local isVisible = IsMapLocationVisible(locIndex)
	
	-- Lets change the map back to the previously selected map or player's position.
	currentZoneIndex = currentZoneIndex > 0 and currentZoneIndex or GetUnitZoneIndex("player")
	WORLD_MAP_MANAGER:SetMapById((GetMapIdByIndex(currentZoneIndex)))
		
	return isVisible
end

local function doesEventHaveVisiblePin(locationInfo)
	return isMapLocationVisible(locationInfo.zoneIndex, locationInfo.subzoneIndex, locationInfo.locationIndex)
end

local function isImpresarioVisible()
	local zoneIndex = 2
	local subzoneIndex = 68
	local locIndex = 24
	
	local isTicketEvent = isMapLocationVisible(zoneIndex, subzoneIndex, locIndex)
	return isTicketEvent, VAR_EVENT_TYPE_TICKETS
end

local function checkForActiveEvent(self)
	local isActive = isImpresarioVisible()
	
	if isActive then
		self:SetActiveEventType(VAR_EVENT_TYPE_TICKETS)
	else
		self:SetActiveEventType(VAR_EVENT_TYPE_NONE)
	end
	
	return isActive
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
--[[
local function isItemForEvent(itemIds, lootItemId)
	for i, itemId in pairs(itemIds) do
		if itemId == lootItemId then
			return true
		end
	end
end

local function isQuestForEvent(quests, questName)
	local zoneQuests = quests[GetUnitZoneIndex('player')] or {}
	for k, qName in pairs(zoneQuests) do
		if qName == questName then
			return true
		end
	end
end

local function processQuestNames(quests)
	local _quests = {}
	for zoneIndex, questIds in pairs(quests) do
		local temp = {}
		for zoneId, questId in pairs(questIds) do
			table.insert(temp, GetQuestName(questId))
		end
		_quests[zoneIndex] = temp
	end
	return _quests
end

]]

local function getDailyResetTimeRemainingSeconds()
	return GetTimeUntilNextDailyLoginRewardClaimS()
end

local function mapIndexToQuestName(eventIndex, quests)
	for zoneId, questId in pairs(quests) do
		QUEST_TO_INDEX_MAP[GetQuestName(questId)] = eventIndex
	end
end

local function mapIndexToItemId(eventIndex, items)
	for zoneIndex, itemId in pairs(items) do
		ITEM_TO_INDEX_MAP[itemId] = eventIndex
	end
end

---------------------------------------------------------------------------
-- Dev debug
---------------------------------------------------------------------------
	local dev = true
-- Enabling dev allows testing event changes by collecting various raw crating materials.
-- Useful when events are not running.
-- It lowers the reset time to 1 minute and, has an event active for 5 minutes and 1 minute off,
-- to simulate daily resets and, event ending and starting.

local devTitles
local devDescriptions
if dev then
	EVENTS[VAR_EVENT_TYPE_UNKNOWN] = {
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

	local counter = 0
	local lastTime = 0
	local numPerEvent = 5
	local secsPerEvent = 30
	getDailyResetTimeRemainingSeconds = function()
		local frameTimeSeconds = GetFrameTimeSeconds()
		if lastTime <= frameTimeSeconds then
			lastTime = frameTimeSeconds + secsPerEvent
			
			if counter > (numPerEvent) then
				counter = 0
			else
				counter = counter + 1
			end
		end
		
		local secondsRemaining = math.floor(lastTime - frameTimeSeconds)
		return secondsRemaining > 0 and secondsRemaining or 0
	end
	
	-- the event will become inactive after 5 minutes
	checkForActiveEvent = function(self)
		local isActive = counter <= numPerEvent
		if isActive then
		--	self:SetActiveEventType(VAR_EVENT_TYPE_UNKNOWN)
		else
			self:SetActiveEventType(VAR_EVENT_TYPE_NONE)
		end
	
		return isActive
	end
	
	reward_type_event_tickets = REWARD_TYPE_MONEY
	
	devTitles = {
		'Woodwork Raw Material',
		'Blacksmith Raw Material',
		'Clothier Raw Material',
		'Reagents',
		'Vivec City Daily Quests',
	}

	devDescriptions = {
		'This is a test event. Updates on acquiring Woodwork Raw Material.',
		'This is a test event. Updates on acquiring Blacksmith Raw Material.',
		'This is a test event. Updates on acquiring Clothier Raw Material.',
		'This is a test event. Updates on acquiring Reagents.',
		'This is a test event. Updates on acquiring Vivec City Daily Quests from Beleru Omoril in the Hall of Justice.',
	}
end

do
--[[
	local function mapEventByIndex(eventTable)
		for _, eventInfo in ipairs(eventTable) do
			if eventInfo.quests then
				eventInfo.quests = processQuestNames(eventInfo.quests)
			end
			table.insert(EVENTS_TO_INDEX_MAP, eventInfo)
			eventInfo.index = #EVENTS_TO_INDEX_MAP
		end
	end
]]
	
	local function mapEventByIndex(eventTable)
		for _, eventInfo in ipairs(eventTable) do
			table.insert(EVENTS_TO_INDEX_MAP, eventInfo)
			eventInfo.index = #EVENTS_TO_INDEX_MAP
			
			if eventInfo.quests then
				mapIndexToQuestName(eventInfo.index, eventInfo.quests)
			end
			if eventInfo.items then
				mapIndexToItemId(eventInfo.index, eventInfo.items)
			end
		end
	end
	
	mapEventByIndex(EVENTS[VAR_EVENT_TYPE_TICKETS][VAR_EVENT_HAS_MAP_LOCATION])
	mapEventByIndex(EVENTS[VAR_EVENT_TYPE_TICKETS][VAR_EVENT_NO_MAP_LOCATION])
	mapEventByIndex(EVENTS[VAR_EVENT_TYPE_UNKNOWN])
end

---------------------------------------------------------------------------
-- Event class
---------------------------------------------------------------------------
local event = ZO_InitializingObject:Subclass()

function event:Initialize(eventInfo)
	zo_mixin(self, eventInfo)
	
	self.title = zo_strformat('<<1>> <<2>>', GetString('SI_EVENTS_MANAGER_TITLE', self.index), GetString(SI_NOTIFICATIONTYPE19))
	self.description = GetString('SI_EVENTS_MANAGER_DESCRIPTION', self.index)
end

function event:GetIndex()
	return self.index
end
function event:GetType()
	return self.eventType
end
function event:GetRewardsBy()
	return self.rewardsBy
end
function event:GetMaxDailyRewards()
	return self.maxDailyRewards or 0
end

function event:IsSameEvent(eventIndex)
	return self.index == eventIndex
end


function event:GetTitle()
	return self.title
end

function event:GetDescription()
	return self.description
end

function event:GetInfo()
	return self.title, self.description
end


function event:ReplaceMe()
end

---------------------------------------------------------------------------
-- lib
---------------------------------------------------------------------------
local lib = _G[LIB_IDENTIFIER]

lib.CheckForActiveEvent = checkForActiveEvent
lib.GetDailyResetTimeRemainingSeconds = getDailyResetTimeRemainingSeconds

-- used in debugging
--lib.Events = EVENTS
--lib.events_to_index_map = EVENTS_TO_INDEX_MAP
--lib.quest_to_index_map = QUEST_TO_INDEX_MAP
--lib.item_to_index_map = ITEM_TO_INDEX_MAP

function lib:UpdateStrings()
	local function compileDevStrings(stringTable, destination)
		for i, _string in ipairs(stringTable) do
			table.insert(destination, _string)
		end
	end
	
	if dev then
		compileDevStrings(devTitles, self.strings.titles)
		compileDevStrings(devDescriptions, self.strings.descriptions)
	end
	
	local strings = {}

	for i, _string in ipairs(self.strings.titles) do
		strings['SI_EVENTS_MANAGER_TITLE' .. i] = _string
	end
	for i, _string in ipairs(self.strings.descriptions) do
		strings['SI_EVENTS_MANAGER_DESCRIPTION' .. i] = _string
	end
	
	for stringId, stringValue in pairs(strings) do
		ZO_CreateStringId(stringId, stringValue)
		SafeAddVersion(stringId, 1)
	end
end

function lib:ChangeState(eventActive)
	if eventActive then
		if not self.active then
			-- activate
			self:Activate()
		end
		self:UpdateEventData(self.eventData.eventIndex)
	elseif self.active then
		-- deactivate
		self:Deactivate()
	end
	
	self:SetActive(eventActive)
end

function lib:OnUpdate()
	local eventActive = self:CheckForActiveEvent()
	self:ChangeState(eventActive)
	
	self:RegisterOnDailyReset()
end

function lib:SetActiveEventType(eventType)
	self.eventData.eventType = eventType
end

function lib:SetActive(active)
	self.active = active
end

function lib:RegisterEvents()
	local function onQuestAdded(eventId, questIndex, questName)
		local rewardDataList = SYSTEMS:GetObject(ZO_INTERACTION_SYSTEM_NAME):GetRewardData(questIndex)
		
		if #rewardDataList == 0 then return end
		-- We only need to refresh the interaction if event tickets are present.
		for i, data in ipairs(rewardDataList) do
			if data.rewardType == reward_type_event_tickets then
				if self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
					local eventIndex, eventInfo = self:GetEventInfoByQuestName(GetJournalQuestName(questIndex))
					if eventIndex then
						self:UpdateEventData(eventIndex)
					end
				end
				return 
			end
		end
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED, onQuestAdded)
	
    local function onInventorySingleSlotUpdate(eventId, bagId, slotId, isNewItem, itemIdsoundCategory, updateReason, stackCountChange)
		if stackCountChange > 0 then
			if self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
				local itemId = GetItemId(bagId, slotId)
				local eventIndex, eventInfo = self:GetEventInfoByItemId(itemId)
				if eventIndex then
					EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
					self:UpdateEventData(eventIndex)
				end
			end
		end
    end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onInventorySingleSlotUpdate)
end

function lib:UnregisterEvents()
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED)
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function lib:RegisterOnDailyReset()
	EVENT_MANAGER:UnregisterForUpdate(self.name .. '_OnUpdate')
	
	local secondsRemaining = getDailyResetTimeRemainingSeconds()
	if secondsRemaining <= 0 then
		zo_callLater(function()
			self:RegisterOnDailyReset()
		end, 1000)
		return
	end
	
	local function onUpdate()
		if self.isUpdating then
			-- In the case UpdateEventData was called by another function, we will run onUpdate again.
			-- It can overwrite changes made if UpdateEventData was called with a new eventIndex.
			zo_callLater(onUpdate, 100)
			return
		end
		self:OnUpdate()
	end
	EVENT_MANAGER:RegisterForUpdate(self.name .. '_OnUpdate', secondsRemaining * 1000, onUpdate)
end

function lib:Activate()
	-- I need to process savedVars to populate eventInfo
	-- or do I load those up and save active state to savedVars
	local eventIndex = self.eventData.eventIndex
--	if not eventIndex or self:GetActiveEventType() == VAR_EVENT_TYPE_UNKNOWN then
	if not eventIndex or eventIndex == VAR_EVENT_NONE then
		eventIndex = self:GetEventInfoByLocation()
	end
	
	if eventIndex > VAR_EVENT_NONE then
	--	self:UpdateEventData(eventIndex)
	end
	self.eventData.eventIndex = eventIndex
end

function lib:Deactivate()
	self:SetActiveEventType(VAR_EVENT_TYPE_NONE)
	self.eventData.eventIndex = VAR_EVENT_NONE
	
	self:UnregisterEvents()
	CALLBACK_MANAGER:FireCallbacks('On_Seasonal_Event_Updated')
end

function lib:CreateEvent(eventIndex)
	self.eventData.eventIndex = eventIndex
	local eventInfo = self:GetEventInfoByIndex(eventIndex)
	
	if not eventInfo then return end
	local newEvent = event:New(eventInfo)
	
	self.currentEvent = newEvent
	self:SetActiveEventType(eventInfo.eventType)
end

function lib:UpdateEventData(eventIndex)
	self.isUpdating = true
	if eventIndex == VAR_EVENT_NONE then return end
	
	if eventIndex then
		self:CreateEvent(eventIndex)
	end
	
	CALLBACK_MANAGER:FireCallbacks('On_Seasonal_Event_Updated', self:IsEventActive(), self.currentEvent)
	
	-- Need to set up events if the event was not detected.
	if self.currentEvent:GetType() > VAR_EVENT_TYPE_UNKNOWN then
		self:UnregisterEvents()
	else
		self:RegisterEvents()
	end
	self.isUpdating = false
end

function lib:GetEventInfoByLocation()
	local knownEvents = EVENTS[VAR_EVENT_TYPE_TICKETS][VAR_EVENT_HAS_MAP_LOCATION]
	for eventIndex, eventInfo in pairs(knownEvents) do
		if doesEventHaveVisiblePin(eventInfo.location) then
			return eventInfo.index, eventInfo
		end
	end
--[[
	for eventIndex, eventInfo in pairs(EVENTS_TO_INDEX_MAP) do
		if eventInfo.location and doesEventHaveVisiblePin(eventInfo.location) then
			return eventIndex, eventInfo
		end
	end
]]
		
	return VAR_EVENT_UNKNOWN
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
function lib:GetEventInfoByIndex(eventIndex)
	return EVENTS_TO_INDEX_MAP[eventIndex]
end

--[[
function lib:GetEventInfoByItemId(itemId)
	for eventIndex, eventInfo in pairs(EVENTS_TO_INDEX_MAP) do
		if eventInfo.itemIds and isItemForEvent(eventInfo.itemIds, itemId) then
			return eventIndex, eventInfo
		end
	end
end

function lib:GetEventInfoByQuestName(questName)
	for eventIndex, eventInfo in pairs(EVENTS_TO_INDEX_MAP) do
		if eventInfo.quests and isQuestForEvent(eventInfo.quests, questName) then
			return eventIndex, eventInfo
		end
	end
end
]]

function lib:GetEventInfoByItemId(itemId)
	return ITEM_TO_INDEX_MAP[itemId]
end

function lib:GetEventInfoByQuestName(questName)
	return QUEST_TO_INDEX_MAP[questName]
end

function lib:IsEventActive()
	return self.eventData.eventType ~= VAR_EVENT_TYPE_NONE
end

function lib:GetActiveEventIndex()
	return self.currentEvent:GetIndex()
end

function lib:GetActiveEventType()
	return self.eventData.eventType
end

function lib:GetEventData() -----------
	return self.eventData
end

function lib:CurrentEvent()
	return self.currentEvent
end

function lib:GetEventIndexByFilter(eventType)
	
end

function lib:WouldTicketsExcedeMax(eventTickets)
	return ZO_SharedInteraction:WouldCurrencyExceedMax(reward_type_event_tickets, eventTickets)
end

function lib:RegisterUpdateCallback(callback)
	-- We want to fire the callback immediately so the addon gets updated without having to wait for event updates.
	if self.eventData then
		callback(self:IsEventActive(), self.currentEvent)
	end
	CALLBACK_MANAGER:RegisterCallback('On_Seasonal_Event_Updated', callback)
	self:RegisterOnDailyReset()
end

---------------------------------------------------------------------------
-- currentEvent info
---------------------------------------------------------------------------
function lib:GetEventTitle()
	if self.currentEvent then
		return self.currentEvent:GetTitle()
	end
	return var_EmptyString
end

function lib:GetEventDescription()
	if self.currentEvent then
		return self.currentEvent:GetDescription()
	end
	return var_EmptyString
end

function lib:GetEventInfo()
	if self.currentEvent then
		return self.currentEvent:GetInfo()
	end
	return var_EmptyString, var_EmptyString
end

function lib:GetEventMaxDailyRewards()
	if self.currentEvent then
		return self.currentEvent:GetMaxDailyRewards()
	end
	return VAR_EVENT_NONE
end

---------------------------------------------------------------------------
-- 
---------------------------------------------------------------------------
IJA_Seasonal_Event_Manager = lib:New()

--[[
/script IJA_Seasonal_Event_Manager.savedVars = {}

/script d( IJA_Seasonal_Event_Manager:GetEventTitle())
/script d( IJA_Seasonal_Event_Manager:GetEventDescription())
/script d( IJA_Seasonal_Event_Manager:GetEventInfo())
/script d( IJA_Seasonal_Event_Manager:GetEventMaxDailyRewards())

]]

--[[ Example usage
local wouldTicketsExcedeMax = IJA_Seasonal_Event_Manager:WouldTicketsExcedeMax(eventTickets)


	local function onSeasonalEventUpdate(active, eventObject)
		if eventObject == nil then return end
		
		if eventObject:GetRewardsBy() > VAR_EVENT_TICKETS_NONE then
			if active then
				local lastEventIndex = self.savedVars.eventInfo.eventIndex
				if not eventObject:IsSameEvent(lastEventIndex) then
					-- start new event
					self:SetUpEvent(eventObject)
				else
					-- reset for dailies?
					self:ResetDailyInfo()
				end
				self:UpdateDailyIconTexture()
			end
			
			self:RefreshGamepadMenu()
			self:ChangeState(active)
		end
	end
	
	IJA_Seasonal_Event_Manager:RegisterUpdateCallback(onSeasonalEventUpdate)
]]




