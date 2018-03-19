--[[
%% autostart
%% properties
%% events
%% globals
--]]

local FURDO_PARA_LIMIT = 70
local vl_furdoParatartalom = tonumber(fibaro:getValue(134, "value"))


function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

function f_paraLogika()
  f_Debug("green", "f_paraLogika: paratartalom: " .. vl_furdoParatartalom)
  if ( vl_furdoParatartalom <= FURDO_PARA_LIMIT ) then
     f_Debug("green", "f_paraLogika: ventillátor kikapcs");
     fibaro:call(63, "turnOff");
  else
     fibaro:debug("paraLogika: ventilátor bekapcs");
     fibaro:call(63, "turnOn");
  end
end

f_paraLogika()
