# LibSeasonalEventManager
The purpos of this library is to watch for active seasonal events and, match active event with the proper info.

Currently, it only knows if an event is running while the Impresario is visiable on a map.
It can only automatically detect 4 events. The Annivarsary Jubilee, The Witch's Fesival, the Jester's Festival, and Whitestrake's Mayhem Celebration.
With either of those 4 events, it will update the data on load or on daily rest.
For other events, they will be identified on quest pickup, or loot pickup.

Unless the Iprasario becomes hidden or, an event change was detected on daily rest, it will keep the current event data between resets and loads.

Other information for each event can be added. 
The running event is an oject, and any needed information about the event can be acquired by the object passed through the registered callback.
Such as, currentEvent:GetTitle()
All an addon needs to do is IJA_Seasonal_Event_Manager:RegisterUpdateCallback(onSeasonalEventUpdate)
It will initialize the lib, if not already done, and return (eventActive, eventObject).
Then, on daily reset, it will refresh and fire the callback again. 

I am not going to add running times. As of yet, there is no way to get that information from the game, and I am not updating this every time an event 
comes around or zos decides to change the end time while the event is running.

I need information on Battleground Weekend events and, a way to detect them. The those events can be add.
