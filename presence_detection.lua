--[[
%% properties
14 value
16 value
75 value
81 value
87 value
131 value
155 value
161 value
167 value
%% events
%% globals
--]]

local FURDO_AJTO_ID = 14
local FURDO_MOZGAS_ID = 131
local FURDO_MOZGAS2_ID = 155
local HALO_MOZGAS_ID = 75
local NAPPALI_MOZGAS_ID = 81
local NAPPALI_MOZGAS2_ID = 167
local KONYHA_MOZGAS_ID = 87
local ELOSZOBA_MOZGAS_ID = 161
local ELOSZOBA_AJTO_ID = 16

local triggeringRoom = "dummy"


function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

-- Code partly stolen from Fibaro forum
function f_ReadGlobalJson(isDebug,varName)
  local debugMessage
  local dataEncoded=fibaro:getGlobalValue(varName)
  if dataEncoded and dataEncoded ~= "null" then
    debugMessage = "f_ReadGlobalJson:" .. varName .. " returns ".. dataEncoded
    if isDebug then f_Debug("grey",debugMessage) end
  else
    debugMessage = "f_ReadGlobalJson:" .. varName .." returns nil or null. Please check " ..
    "if Global Variable exists. Program continues and will not crash"
    f_Debug("red",debugMessage)  
    return false, nil
  end
  -- This is where the magic happens:
  local ok, data = pcall(json.decode, dataEncoded)
  if ok then
    if isDebug then f_Debug("grey","f_ReadGlobalJson: decode OK") end
  else
    f_Debug("red","f_ReadGlobalJson: decode failed with error:" .. data)
  end
  return ok, data
end

function f_WriteGlobalJson(isDebug,varName,data)
  local jsonString = json.encode(data)
  if isDebug then 
    f_Debug("white","f_WriteGlobalJson: jsonString: " .. jsonString) 
  end 
  fibaro:setGlobal(varName,jsonString)
end

function f_InitialisePresenceJson(isDebug)
 local presenceTable = {
   eloszoba = {
      presence = -1},
   furdo = {
      presence = -1},  
   haloszoba = {
      presence = -1},
   nappali = {
      presence = -1},
   konyha = {
      presence = -1},
   bejaratiajto = {
	  presence = -1},
   furdoajto = {
	  presence = -1}  
	}  
 f_WriteGlobalJson(isDebug,"vg_PresenceJson",presenceTable)
end --f_InitialisePresenceJson

function f_updatePresenceTable(isDebug, room, presence)
  	local message = "f_updatePresenceTable started, inputs: " .. room .. " " .. presence
    if isDebug then f_Debug("white",message) end
	--Read lock state
  	local lockState=fibaro:getGlobalValue("vg_PresenceLock")
    f_Debug("green","f_updatePresenceTable: lockState: " .. lockState) 
    -- 0 unlocked, else locked
  	if lockState == "0" then
    	fibaro:setGlobal("vg_PresenceLock",1)
    	lockState = 1
        local time = os.time()
    	local ok
    	local presenceTable
    	ok, presenceTable = f_ReadGlobalJson(isDebug,"vg_PresenceJson")
  		if not ok then
    		f_InitialisePresenceJson(isDebug)
    		ok, presenceTable = f_ReadGlobalJson(isDebug,"vg_PresenceJson")
  		end    
 
        presenceTable[room] = {
      		presence = presence,
      		time = time
      	}
    
        f_WriteGlobalJson(isDebug,"vg_PresenceJson",presenceTable)
    
    	fibaro:setGlobal("vg_PresenceLock",0)
    	lockState = 0
    else
    	f_Debug("red","f_updatePresenceTable: presenceJson not updated!") 
    end
end --f_updatePresenceTable

function f_processSourceTrigger(isDebug)
	local trigger = fibaro:getSourceTrigger()
    local deviceID = -1
  	if (trigger['type'] == 'property') then
    	deviceID = trigger['deviceID']
      	if isDebug then f_Debug("white","f_processSourceTrigger: Source device = " .. 
        	deviceID) end
	elseif (trigger['type'] == 'global') then
    	if isDebug then f_Debug("white","f_processSourceTrigger: Global variable source = " ..
        	trigger['name']) end
	elseif (trigger['type'] == 'other') then
  		if isDebug then f_Debug("white","f_processSourceTrigger: Other source.") end
	end
    return deviceID;
end -- f_processSourceTrigger

function f_analysePresenceStatus(isDebug, deviceID)
	local room = "dummy"
	local device ="dummy"
	local door = "dummy"
  	local presence = 0;
    local ok
    local presenceTable
  	local value
  
    if (deviceID == FURDO_AJTO_ID) then room = "furdo"; device = "ajto"
        elseif (deviceID == FURDO_MOZGAS_ID) then room = "furdo"; device = "mozgas"
    	elseif (deviceID == FURDO_MOZGAS2_ID) then room = "furdo"; device = "mozgas2"
		elseif (deviceID == FURDO_AJTO_ID) then room = "furdo"; device = "ajto"; door = "furdoajto"
        elseif (deviceID == HALO_MOZGAS_ID) then room = "haloszoba"; device = "mozgas"
  		elseif (deviceID == NAPPALI_MOZGAS_ID) then room = "nappali"; device = "mozgas"
    	elseif (deviceID == NAPPALI_MOZGAS2_ID) then room = "nappali"; device = "mozgas2"
        elseif (deviceID == KONYHA_MOZGAS_ID) then room = "konyha"; device = "mozgas"
    	elseif (deviceID == ELOSZOBA_MOZGAS_ID) then room = "eloszoba"; device = "mozgas"
        elseif (deviceID == ELOSZOBA_AJTO_ID) then room = "eloszoba"; device = "ajto"; door = "bejaratiajto"
  		else f_Debug("red", "f_processSourceTrigger: DeviceID not handled: " ..
    			deviceID); 
  			return "dummy", -1
	end

	value = tonumber(fibaro:getValue(deviceID, "value"))
	if true then f_Debug("white", "f_processSourceTrigger: ".. device .. 
    	" in " .. room .." reports " .. value) end
  	
  	-- Reading presence table - consider adding lock mechanism later
    ok, presenceTable = f_ReadGlobalJson(isDebug,"vg_PresenceJson")
  	if not ok then
    	f_InitialisePresenceJson(isDebug)
    	ok, presenceTable = f_ReadGlobalJson(isDebug,"vg_PresenceJson")
  	end
	
  	-- If a motion detector reports breached (1), presence is 1
  	if ((device == "mozgas" or device == "mozgas2") and value == 1) then
    	presence = 1
    end
	  
    -- If a motion detector reports safe (0), check boundaries
    if ((device == "mozgas" or device == "mozgas2") and value == 0) then
    	if (room == "haloszoba") then
      		if (f_isNeighbourInactive(isDebug,"haloszoba","nappali",presenceTable))
        	then presence = 1 else presence = 0; end
      	elseif (room == "nappali") then
        	if (f_isNeighbourInactive(isDebug,"nappali","haloszoba",presenceTable)
          		and f_isNeighbourInactive(isDebug,"nappali","eloszoba",presenceTable))
        	then presence = 1 else presence = 0; end
      	elseif (room == "eloszoba") then
        	if (f_isNeighbourInactive(isDebug,"eloszoba","nappali",presenceTable)
          		and f_isNeighbourInactive(isDebug,"eloszoba","furdo",presenceTable) 
				and f_isDoorInactive(isDebug,"eloszoba","bejaratiajto",presenceTable))
        	then presence = 1 else presence = 0; end			
    	elseif (room == "konyha") then
            if (f_isNeighbourInactive(isDebug,"konyha","eloszoba",presenceTable))
        	then presence = 1 else presence = 0; end
  		elseif (room == "furdo") then
		    if (f_isNeighbourInactive(isDebug,"furdo","eloszoba",presenceTable) 
			and f_isDoorInactive(isDebug,"furdo","furdoajto",presenceTable))
        	then presence = 1 else presence = 0; end
    	end
    end
    -- If a door reports 
	if (device == "ajto") then
		-- Save ajto status & trigger time
		f_updatePresenceTable(false, door, tostring(value))
		if (room == "eloszoba") then
			local eloszobaMozgasValue = fibaro:getValue(ELOSZOBA_MOZGAS_ID, "value")
			-- Leaving, door closed, motion sensor doesn't reach
			if ((value == 0) and (presenceTable["eloszoba"].presence == 1
				and eloszobaMozgasValue == 0))
			then presence = 0
			end
		end
		-- TODO Handle room implications, mainly eloszoba case (sensor not reaching)
		--[[
		Door is opened.
			UC1: Leaving flat
				- Előszoba would be Safe, or will be after door closed
				- Set előszoba to empty after close?
			UC2: Entering flat
				- Előszoba will be breached very soon
			UC3: temporary open
				- Szellőztetés? Előszoba will be breached or leaving
		Door is closed
			UC1: Left flat
				- Előszoba would be safe or will be soon
				eloszoba presence 1, but mozgas safe, door just closed -> set presence to 0.
			UC2: Entering
				- Előszoba will be breached
			UC3: Szellőztetés
				- Door would be open for an extended time
		]]--
	end
	
	
    f_Debug("green", "f_analysePresenceStatus: " .. room .. " is " .. presence)
  	return room, presence
    
end -- f_analysePresenceStatus

function f_isNeighbourInactive(isDebug,currentRoom,neighbourRoom,presenceTable)
	if isDebug then 
    	f_Debug("white", "f_neighbourCheck: current: "..
      		currentRoom .. " neighbour: " .. neighbourRoom)
    	f_Debug("white", "f_neighbourCheck: neighbourPresence: " ..
      		presenceTable[neighbourRoom].presence .. " neighbourRoomTime: " ..
      		presenceTable[neighbourRoom].time .. " currentTime: " ..
      		os.time())
    end
    -- Inactive is room empty or triggered earlier than move
    return (not presenceTable[neighbourRoom].presence == 1 or 
      	presenceTable[neighbourRoom].time + 10 < os.time())
end -- f_isNeighbourInactive

function f_isDoorInactive(isDebug,currentRoom,door,presenceTable)

	if isDebug then 
    	f_Debug("white", "f_isDoorInactive: current: "..
      		currentRoom .. " door: " .. door)
    	f_Debug("white", "f_isDoorInactive:  currentRoomTime: " ..
      		presenceTable[currentRoom].time .. " doorChangeTime: " ..
			presenceTable[door].time .. " doorValue: " ..
			presenceTable[door].presence)
    end
	-- Inactive if closed and closed longer than move
	return (presenceTable[door].time < presenceTable[currentRoom].time 
	and presenceTable[door].presence == 0)
end -- f_isDoorInactive


function f_debugDoorHandling(isDebug)
    
	local ok, presenceTable
  	-- Reading presence table - consider adding lock mechanism later
    ok, presenceTable = f_ReadGlobalJson(true,"vg_PresenceJson")
  	if not ok then
    	f_InitialisePresenceJson(isDebug)
    	ok, presenceTable = f_ReadGlobalJson(isDebug,"vg_PresenceJson")
  	end

    local eloszobaDoorBreachTime = fibaro:getValue(ELOSZOBA_AJTO_ID, "lastBreached")
	local furdoDoorBreachTime = fibaro:getValue(FURDO_AJTO_ID, "lastBreached")
	local eloszobaDoorValue = fibaro:getValue(ELOSZOBA_AJTO_ID, "value")
	local furdoDoorValue = fibaro:getValue(FURDO_AJTO_ID, "value")
	f_Debug("white", "f_debugDoorHandling: eloszobaDoorBreachTime: ".. eloszobaDoorBreachTime ..
		" eloszobaDoorValue: " .. eloszobaDoorValue .. " furdoDoorBreachTime : " ..
		furdoDoorBreachTime .. " furdoDoorValue: " .. furdoDoorValue)
	--f_Debug("white", "f_debugDoorHandling: presenceTable: " .. presenceTable)
	
end -- f_debugDoorHandling

--- MAIN EXECUTION STARTS
local startTime = os.clock()

function f_RunScene()
  	local room = "dummy"
    local presence = -1
    local deviceID 
    deviceID = f_processSourceTrigger(false)
    room, presence = f_analysePresenceStatus(true, deviceID)
    f_updatePresenceTable(false, room, tostring(presence))
	--f_debugDoorHandling(false)
	--f_InitialisePresenceJson(true)
	--fibaro:setGlobal("vg_PresenceLock",0)
	--f_updatePresenceTable(false, triggeringRoom,"1")
	-- TODO: Add long term inactivity logic perhaps? How to handle the case when
	-- someone leaves via front door?
end

f_RunScene()

local elapsedTime = os.clock() - startTime
f_Debug("white","elapsedTime: " .. elapsedTime)
