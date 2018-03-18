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

-- Function for advanced debug message
function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end
