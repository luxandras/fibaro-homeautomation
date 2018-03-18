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

local FURDO_MENNYEZETI_ID = 60
local FURDO_LED_ID = 137
local FURDO_TUKOR_ID = 149
local HALO_ASZTALI_ID = 173
local KONYHA_MENNYEZETI_ID = 48
local KONYHA_PULT_ID = 39
local ELOSZOBA_MENNYEZETI_ID = 97
local ELOSZOBA_FOGAS_ID = 55
local TAROLO_MENNYEZETI_ID = 43
local TAROLO_SZEKRENY_ID = 45

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
end


-- Loop through all lights. If it is on, turn off if based on setting of DECISON_BASE
function f_turnOffLights(isDebug)
	
end

function f_RunScene()
	local ok, presenceTable
	ok, presenceTable = f_ReadGlobalJson(true,"vg_PresenceJson")
end

f_RunScene()
