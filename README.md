# LibSeasonalEventManager
The purpos of this library is to watch for active seasonal events and, match active event with the proper info.<br>

Currently, it only knows if an event is running while the Impresario is visiable on a map.<br>
It can only automatically detect 4 events. The Annivarsary Jubilee, The Witch's Fesival, the Jester's Festival, and Whitestrake's Mayhem Celebration.<br>
With either of those 4 events, it will update the data on load or on daily rest.<br>
For other events, they will be identified on quest pickup, or loot pickup.<br>

Unless the Impresario becomes hidden or, an event change was detected on daily rest, it will keep the current event data between resets and loads.

Other information for each event can be added. <br>
The running event is an oject, and any needed information about the event can be acquired by the object passed through the registered callback.<br>
Such as, currentEvent:GetTitle()<br>
All an addon needs to do is IJA_Seasonal_Event_Manager:RegisterUpdateCallback(onSeasonalEventUpdate)<br>
It will initialize the lib, if not already done, and return (eventActive, eventObject).<br>
Then, on daily reset, it will refresh and fire the callback again. <br>

I am not going to add running times. As of yet, there is no way to get that information from the game, and I am not updating this every time an event <br>
comes around or zos decides to change the end time while the event is running.<br>

I need information on Battleground Weekend events and, a way to detect them. The those events can be add.<br>

# Using the debug:<br>
Set the variable at the top of debug.lua to false. "ignore = false"<br>

With the debug active, a looping simulation will run. <br>
Days are treated as secPerDay. <br>
This allows for timeUntilDailyRest to be in a set amount of seconds. <br>
For example, if secPerDay were set to 30 then, daily reset would accure every 30 seconds.<br>

Days-per-event:<br>
The number of days an event is active is daysPerEvent.<br>
Ater which, the event will become inactive for "1 day".<br>

Change the type of event to test.<br>
--	/script IJA_Seasonal_Event_Manager:SetDebugEventType(3)

Change how many days the events will be active for.<br>
--	/script IJA_Seasonal_Event_Manager:SetDebugDaysPerEvent(3)

Change how many secounds the simualation lasts per day.<br>
--	/script IJA_Seasonal_Event_Manager:SetDebugSecondsPerDay(10)

Change the Battleground Id to test.<br>
--	/script IJA_Seasonal_Event_Manager:SetDebugBattlegroundId(100)<br>
Check the battleground events in event.lua for valid battleground ids.
