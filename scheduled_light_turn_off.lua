--[[
%% properties
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
	furdo_mennyezeti = {id = 60, sensors = {FURDO_MOZGAS_ID, FURDO_MOZGAS2_ID}, room = "furdo"), -- handle doors?
	furdo_led = {id = 137, sensors = {FURDO_MOZGAS_ID, FURDO_MOZGAS2_ID}, room = "furdo"},
	furdo_tukor = {id = 149, sensors = {FURDO_MOZGAS_ID, FURDO_MOZGAS2_ID}, room = "furdo"},
	halo_asztali = {id = 173, sensors = {HALO_MOZGAS_ID}, room = "haloszoba"},
	konyha_mennyezeti = {id = 48, sensors = {KONYHA_MOZGAS_ID}, room = "konyha"},
	konyha_pult = {id = 39, sensors = {KONYHA_MOZGAS_ID}, room = "konyha"},
	eloszoba_mennyezeti = {id = 97, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"},
	eloszoba_fogas = {id = 55, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"},
	tarolo_mennyezeti = {id = 43, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"},
	tarolo_szekreny = {id = 45, sensors = {ELOSZOBA_MOZGAS_ID}, room = "eloszoba"}
}


-- Constant determining what to base lights off decision on:
-- 0 - sensors only, 1 - presence table
local DECISON_BASE = 0

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

-- Query status of all ligths and stores it
function f_queryLightStatus (isDebug)
	for i, light in ipairs(lightsTable) do
		f_Debug("white","f_queryLightStatus: " .. light)
		--fibaro:getValue(60, "value")
	end
end -- f_queryLightStatus

-- Loop through all lights. If it is on, turn off if based on setting of DECISON_BASE
function f_turnOffLights(isDebug)
	local 
	fibaro:getValue(60, "value")
end

function f_RunScene()
	local ok, presenceTable
	ok, presenceTable = f_ReadGlobalJson(true,"vg_PresenceJson")
	_queryLightStatus (true)
end

f_RunScene()
