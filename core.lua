
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

local l_TICKETS_MAX			= lib.constants.maxTickets

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

local l_EmptyString 		= lib.constants.stringEmpty

local defaultEventInfo = {
	['index'] 		= l_EVENT_NONE,
	['eventType'] 	= l_EVENT_TYPE_NONE,
	['rewardsBy'] 	= l_REWARDS_BY_NONE,
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
	return isTicketEvent, l_EVENT_TYPE_TICKETS
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

---------------------------------------------------------------------------
-- Event class
---------------------------------------------------------------------------
local event_class = ZO_InitializingObject:Subclass()

function event_class:Initialize(eventInfo)
	zo_mixin(self, eventInfo)
	
	if self.index then
		self.title = zo_strformat('<<1>> <<2>>', GetString('SI_EVENTS_MANAGER_TITLE', self.index), GetString(SI_NOTIFICATIONTYPE19))
		self.description = GetString('SI_EVENTS_MANAGER_DESCRIPTION', self.index)
	end
end

function event_class:GetIndex()
	return self.index
end
function event_class:GetType()
	return self.eventType
end
function event_class:GetRewardsBy()
	return self.rewardsBy
end
function event_class:GetMaxDailyRewards()
	return self.maxDailyRewards or 0
end

function event_class:IsSameEvent(eventIndex)
	return self.index == eventIndex
end

function event_class:GetTitle()
	return self.title
end

function event_class:GetDescription()
	return self.description
end

function event_class:GetInfo()
	return self.title, self.description
end

local defaultEvent = event_class:New(defaultEventInfo)

---------------------------------------------------------------------------
-- lib
---------------------------------------------------------------------------
local lib = _G[LIB_IDENTIFIER]

local svVersion = 1
local svDefaults = {
	eventData = {
		eventIndex = l_EVENT_NONE,
		eventType = l_EVENT_TYPE_NONE,
	}
}

function lib:Initialize()
	local function OnLoaded(_, name)
		if name ~= LIB_IDENTIFIER then return end
		EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
		
		self.savedVars = ZO_SavedVars:NewAccountWide('LibSesonalEventManager_SV_Data', svVersion, nil, svDefaults, GetWorldName(), "$AllAccounts")
		self.eventData = self.savedVars.eventData
		
		self:SetActiveEventType(l_EVENT_TYPE_NONE)
		
		local function onPlayerActivated()
			EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED)
			
		--	d( '|cFF00FF' .. LIB_IDENTIFIER '|r' .. " version: " .. LIB_VERSION)
		end
		EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_PLAYER_ACTIVATED, onPlayerActivated)
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_ADD_ON_LOADED, OnLoaded)
end

function lib:CheckForActiveEvent()
	local isActive = isImpresarioVisible()
	
	if isActive then
		self:SetActiveEventType(l_EVENT_TYPE_TICKETS)
	else
		self:SetActiveEventType(l_EVENT_TYPE_NONE)
	end
	
	return isActive
end

function lib:Activate()
	
	self:ResetToSavedEvent()
	
end

function lib:Deactivate()
	self:SetActiveEventType(l_EVENT_TYPE_NONE)
	self.eventData.eventIndex = l_EVENT_NONE
	
	self.currentEvent = defaultEvent
	self:UnregisterEvents()
end

function lib.GetDailyResetTimeRemainingSeconds()
	return GetTimeUntilNextDailyLoginRewardClaimS()
end

function lib:OnUpdate()
	if self.isUpdating then return end
	self.isUpdating = true
	
	local isEventActive = self:CheckForActiveEvent()
	
	if isEventActive then
		if not self.active then
			-- activate
			self:Activate()
		end
		self:UpdateEventData(self.eventData.eventIndex)
	else
		-- deactivate
		self:Deactivate()
	end
	
	self:SetActive(isEventActive)
	self:RegisterOnDailyReset()
	CALLBACK_MANAGER:FireCallbacks('On_Seasonal_Event_Updated', isEventActive, self.currentEvent)
end

function lib:RegisterEvents()
	local function onQuestAdded(eventId, questIndex, questName)
		local rewardDataList = SYSTEMS:GetObject(ZO_INTERACTION_SYSTEM_NAME):GetRewardData(questIndex)
		
		if #rewardDataList == 0 then return end
		-- We only need to refresh the interaction if event tickets are present.
		for i, data in ipairs(rewardDataList) do
			if data.rewardType == REWARD_TYPE_EVENT_TICKETS then
				if self:GetActiveEventType() == l_EVENT_TYPE_UNKNOWN then
					local eventIndex = self:GetEventIndexByQuestName(questName)
					if eventIndex then
						self:UpdateActiveEventIndex(eventIndex)
					end
				end
				return 
			end
		end
	end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED, onQuestAdded)
	
    local function onInventorySingleSlotUpdate(eventId, bagId, slotId, isNewItem, itemIdsoundCategory, updateReason, stackCountChange)
		if stackCountChange > 0 then
			if self:GetActiveEventType() == l_EVENT_TYPE_UNKNOWN then
				local itemId = GetItemId(bagId, slotId)
				local eventIndex = self:GetEventIndexByItemId(itemId)
				if eventIndex then
					EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
					self:UpdateActiveEventIndex(eventIndex)
				end
			end
		end
    end
	EVENT_MANAGER:RegisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onInventorySingleSlotUpdate)
end

function lib:RegisterOnDailyReset()
	EVENT_MANAGER:UnregisterForUpdate(self.name .. '_OnUpdate')
	
	local secondsRemaining = self.GetDailyResetTimeRemainingSeconds()
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

function lib:ResetToSavedEvent()
	local eventIndex = self.eventData.eventIndex
	if eventIndex then
		self:UpdateActiveEventIndex(eventIndex)
	end
end

function lib:UnregisterEvents()
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_QUEST_ADDED)
	EVENT_MANAGER:UnregisterForEvent(LIB_IDENTIFIER, EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
end

function lib:UpdateActiveEvent(eventIndex)
	local eventInfo = self:GetEventInfoByIndex(eventIndex)
	
	if eventInfo ~= nil then
		local newEvent = event_class:New(eventInfo)
		self.currentEvent = newEvent
		self:SetActiveEventType(eventInfo.eventType)
	end
	
	-- Need to set up events if the event was not detected.
	if self.currentEvent:GetType() > l_EVENT_TYPE_UNKNOWN then
		self:UnregisterEvents()
	else
		self:RegisterEvents()
	end
	self.isUpdating = false
end

function lib:UpdateActiveEventIndex(eventIndex)
	local function isNewEvent(eventIndex)
		return self.eventData.eventIndex ~= eventIndex
	end
	
	if eventIndex == l_EVENT_NONE then
		eventIndex = self:GetEventIndexByVisibleLocation()
	end
	
	if isNewEvent(eventIndex) then
		self.eventData.eventIndex = eventIndex
		self:UpdateActiveEvent(eventIndex)
	end
end

---------------------------------------------------------------------------
-- Event info parsing
---------------------------------------------------------------------------
function lib:GetEventInfoByIndex(eventIndex)
	return self.eventsToIndexMap[eventIndex]
end

function lib:GetEventIndexByVisibleLocation()
	for eventIndex, location in pairs(self.locationToIndexMap) do
		if doesEventHaveVisiblePin(location) then
			return eventIndex
		end
	end

	return l_EVENT_UNKNOWN
end

---------------------------------------------------------------------------
-- Deferred initialization
---------------------------------------------------------------------------
-- Mapping the event data allow for simplifying lookup.

do
	local keys = {
		[1] = 'indexToQuestNameMap',
		[2] = 'indexToItemIdMap',
		[3] = 'indexToTargetNameMap',
	}

	function lib:MapIndexByKey(key, eventIndex, source, indexFunc)
		for zoneId, questId in pairs(quests) do
			self[key][indexFunc(questId)] = eventIndex
		end
	end
end

function lib:MapEventInfo()
	local function mapIndexToQuestName(eventIndex, quests)
		self:MapIndexByKey(keys[1], eventIndex, quests, function(questId) return GetQuestName(questId) end)
	end

	local function mapIndexToItemId(eventIndex, items)
		self:MapIndexByKey(keys[2], eventIndex, items, function(itemId) return itemId end)
	end

	local function mapIndexToTargetName(eventIndex, targets)
		self:MapIndexByKey(keys[3], eventIndex, targets, function(target) return getString(target) end)
	end

	local function mapLocationToIndex(eventIndex, location)
		self.locationToIndexMap[eventIndex] = location
	end
	
	local eventsToIndexMap = self.eventsToIndexMap
	
	for _, eventInfo in ipairs(self.events) do
		table.insert(eventsToIndexMap, eventInfo)
		eventInfo.index = #eventsToIndexMap
		
		if eventInfo.quests then
			mapIndexToQuestName(eventInfo.index, eventInfo.quests)
		end
		if eventInfo.items then
			mapIndexToItemId(eventInfo.index, eventInfo.items)
		end
		if eventInfo.targets then
			mapIndexToTargetName(eventInfo.index, eventInfo.items)
		end
		if eventInfo.location then
			mapLocationToIndex(eventInfo.index, eventInfo.location)
		end
	end

	self.eventsToIndexMap = eventsToIndexMap
end

function lib:RegisterStrings()
	-- Dynamically generate string ids and register strings
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

function lib:OnDeferredInitialize()
	if self.initialized then return end
	self.initialized = true
	
	self:RegisterStrings()
	self:MapEventInfo()
	self:OnUpdate()
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
function lib:IsEventActive()
	return self.eventData.eventType ~= l_EVENT_TYPE_NONE
end

function lib:GetActiveEventIndex()
	return self.currentEvent:GetIndex()
end

function lib:GetActiveEventType()
	return self.eventData.eventType
end

function lib:GetCurrentEvent()
	return self.currentEvent or defaultEvent
end

function lib:GetEventIndexByFilter(eventType)
	
end

function lib:WouldTicketsExcedeMax(eventTickets)
	return ZO_SharedInteraction:WouldCurrencyExceedMax(REWARD_TYPE_EVENT_TICKETS, eventTickets)
end

function lib:RegisterUpdateCallback(callback)
	self:OnDeferedInitialize()
	-- We want to fire the callback immediately so the addon gets updated without having to wait for event updates.
	if self.eventData then
		callback(self.active, self:GetCurrentEvent())
	end
	CALLBACK_MANAGER:RegisterCallback('On_Seasonal_Event_Updated', callback)
end

---------------------------------------------------------------------------
-- currentEvent info
---------------------------------------------------------------------------
function lib:GetEventTitle()
	if self.currentEvent then
		return self.currentEvent:GetTitle()
	end
	return l_EmptyString
end

function lib:GetEventDescription()
	if self.currentEvent then
		return self.currentEvent:GetDescription()
	end
	return l_EmptyString
end

function lib:GetEventInfo()
	if self.currentEvent then
		return self.currentEvent:GetInfo()
	end
	return l_EmptyString, l_EmptyString
end

function lib:GetEventMaxDailyRewards()
	if self.currentEvent then
		return self.currentEvent:GetMaxDailyRewards()
	end
	return l_EVENT_NONE
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
		
		if eventObject:GetRewardsBy() > l_REWARDS_BY_NONE then
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




