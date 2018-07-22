--[[
%% properties
14 value
131 value
155 value
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
	furdo_mennyezeti = {id = 60, sensors = {FURDO_MOZGAS2_ID}, door = {FURDO_AJTO_ID}, room = "furdo"}, -- handle doors?
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

function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

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

function f_handleLights (isDebug, device, room, value)
	if isDebug then f_Debug("white", "f_handleLights entering function ".. room .. " " .. device .. " " .. value) end
	
	local hour = os.date("*t").hour
	if isDebug then f_Debug("white", "f_handleLights: hour: "..hour) end
	
	if (room == "furdo") then
		if (0 < hour and hour < 6) then 
			desiredIntensity = 10
		else
			desiredIntensity = 100
		end 
		if (device == "ajto") then
			if (value == 1) then --open, triggered by change, so opened now
				f_turnOnLights(isDebug,lightsTable.furdo_mennyezeti.id, desiredIntensity)
			end
		elseif (device == "mozgas2") then
			if (value == 1) then
				f_turnOnLights(isDebug,lightsTable.furdo_mennyezeti.id, desiredIntensity)
			end
		end
	end
end -- f_handleLights

function f_turnOnLights (isDebug, lightId, desiredIntensity)
	currentIntensity = tonumber(fibaro:getValue(lightId, "value"))
	if isDebug then f_Debug("white", "f_turnOnLights: currentIntensity: "..currentIntensity) end
	if (currentIntensity == 0) then
		--fibaro:call(lightsTable[lightKey].id, "turnOn")
		fibaro:call(60, "setValue", desiredIntensity)
	end
end 

--- MAIN EXECUTION STARTS
function f_runScene()
  	local room = "dummy"
    local deviceID 
	local device
	local value
    deviceID = f_processSourceTrigger(false)
	device, room, value = f_getDeviceAndRoom(false, deviceID, value)
	f_handleLights(true, device, room, value)
end --f_RunScene


f_runScene()