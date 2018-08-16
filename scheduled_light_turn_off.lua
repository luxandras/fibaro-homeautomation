--[[
%% properties
14 value
%% events
%% globals
--]]

-- Hardcoded device ID constants
local FURDO_AJTO_ID = 14
local FURDO_MOZGAS_ID = 131
local FURDO_MOZGAS2_ID = 155
local HALO_MOZGAS_ID = 75
local NAPPALI_MOZGAS_ID = 81
local NAPPALI_MOZGAS2_ID = 167
local KONYHA_MOZGAS_ID = 87
local ELOSZOBA_MOZGAS_ID = 161
local ELOSZOBA_AJTO_ID = 16

local lightsTable = {
	furdo_mennyezeti = {id = 60, sensors = {FURDO_MOZGAS2_ID}, room = "furdo"}, -- handle doors?
	furdo_led = {id = 137, sensors = {FURDO_MOZGAS2_ID}, room = "furdo"},
	furdo_tukor = {id = 149, sensors = {FURDO_MOZGAS2_ID}, room = "furdo"},
	halo_asztali = {id = 173, sensors = {HALO_MOZGAS_ID}, room = "haloszoba"},
	konyha_mennyezeti = {id = 48, sensors = {KONYHA_MOZGAS_ID}, room = "konyha"},
	konyha_pult = {id = 39, sensors = {KONYHA_MOZGAS_ID}, room = "konyha"},
	eloszoba_mennyezeti = {id = 97, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"},
	eloszoba_fogas = {id = 55, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"},
	tarolo_mennyezeti = {id = 43, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"},
	tarolo_szekreny = {id = 45, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"}
}
-- Id of presence detector scene for broken global value reinit
PRESENCE_DETECTOR_SCENE_ID = 10

-- Constant determining what to base lights off decision on:
-- SENSORS_ONLY / PRESENCE_TABLE
local DECISON_BASE = SENSORS_ONLY

-- Constant determining light timeout i.e. how much time do we allow since last move (s)
local LIGHT_TIMEOUT = 300     -- Wait triggered by scheduler
local SHORT_LIGHT_TIMEOUT = 12 -- Wait triggered by closing door. Can't be shorter than sensor alarm cancellation delay

-- Function for advanced debug message
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
end -- f_ReadGlobalJson 

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

function f_getDeviceAndRoom(isDebug, deviceID)
	local room = "dummy"
	local device ="dummy"
	local door = "dummy"
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
	if isDebug then f_Debug("white", "f_processSourceTrigger: ".. device .. 
    	" in " .. room .." reports " .. value) end
	return device, room, value
end -- f_getDeviceAndRoom

-- Query status of all ligths and stores it. Note that larger than 0 is ON.
function f_queryLightStatus (isDebug)
	for lightKey, _ in pairs(lightsTable) do
		lightsTable[lightKey].status = fibaro:getValue(lightsTable[lightKey].id, "value")
		if isDebug then f_Debug("white","f_queryLightStatus: " ..lightKey .. ": ".. lightsTable[lightKey].status) end
	end
end -- f_queryLightStatus

-- Return presence based on current sensors and last movement time and LIGHT_TIMEOUT (scheduler) or SHORT_LIGHT_TIMEOUT (device eg closing door)
function f_getSensorStatus(isDebug,lightKey,shortTimeout)
	local breached = 0
	local lastBreached = -1
	local timeout = LIGHT_TIMEOUT
	if (shortTimeout) then timeout = SHORT_LIGHT_TIMEOUT end 
	for sensorKey, sensorId in pairs(lightsTable[lightKey].sensors) do
		local sensorLastBreached = os.time() - fibaro:getValue(sensorId, "lastBreached")
		local sensorNowBreached = tonumber(fibaro:getValue(sensorId, "value"))
		if true then f_Debug("white","f_getSensorStatus: " .. lightKey .. " ".. sensorKey .. 
			" sensorLastBreached: " .. sensorLastBreached .. " value: " .. sensorNowBreached) end --remove DEBUG
		if (sensorLastBreached < timeout or sensorNowBreached == 1) then breached = 1 end 
		if (lastBreached == -1 or sensorLastBreached < lastBreached) then lastBreached = sensorLastBreached end
	end
	return breached, lastBreached
end -- f_getSensorStatus

-- Loop through all lights. If it is on, turn off if based on setting of DECISON_BASE
function f_turnOffLights(isDebug, presenceTable, room)
	for lightKey, _ in pairs(lightsTable) do
		if (tonumber(lightsTable[lightKey].status) > 0) then
			local functionPresence = presenceTable[lightsTable[lightKey].room].presence
			local functionTime = os.time() - presenceTable[lightsTable[lightKey].room].time
			local sensorPresence, sensorTime
			local shortTimeout = false 
			if (room == lightsTable[lightKey].room) then
				shortTimeout = true
			end
			sensorPresence, sensorTime = f_getSensorStatus(isDebug,lightKey, shortTimeout)
			local message = " Keep alight "
			if (DECISON_BASE == SENSORS_ONLY) then
				if sensorPresence == 0 then
					fibaro:call(lightsTable[lightKey].id, "turnOff")
					message = " Turn off (sensor) "
				end
			elseif (DECISON_BASE == PRESENCE_TABLE) then
				if functionPresence == 0 then
					fibaro:call(lightsTable[lightKey].id, "turnOff")
					message = " Turn off (function) "
				end
			else f_Debug("red","f_turnOffLights: unhandled control")
			end
			f_Debug("white","f_turnOffLights: " ..lightKey .. message .. ": funcPres: ".. functionPresence ..
				" funcTime: " .. functionTime .. " sensPres: " .. sensorPresence ..
				" sensTime: " .. sensorTime)
		end
	end
end -- f_turnOffLight

--Note: we could do it in one loop as well
function f_RunScene()

	local ok, presenceTable
	ok, presenceTable = f_ReadGlobalJson(false,"vg_PresenceJson")
	if not ok then
    	fibaro:startScene(PRESENCE_DETECTOR_SCENE_ID) -- This will reinit
		f_Debug("red","f_RunScene: presenceTable is broken")
		return
  	end
	
	local room = "dummy"
    local deviceID 
	local device
	local value
    deviceID = f_processSourceTrigger(false)
	f_queryLightStatus (false)
	
	if (deviceID == -1) then
		-- Triggered manually or by scheduler
		f_turnOffLights(false, presenceTable, room) --Room is dummy in scheduler case
	else
		-- Triggered by device	
		fibaro:sleep(SHORT_LIGHT_TIMEOUT*1000);
		device, room, value = f_getDeviceAndRoom(false, deviceID, value)	
		if (device == "ajto" and value == 0) then --closed, triggered by change, so closed now
			f_turnOffLights(false, presenceTable, room) --Room is dummy in scheduler case
		end
	end
	
end

local startTime = os.clock()
f_RunScene()
local elapsedTime = os.clock() - startTime
f_Debug("white","elapsedTime: " .. elapsedTime)
