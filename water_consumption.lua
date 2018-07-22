--[[
%% properties
145 value
%% events
%% globals
--]]

local WATER_GLOBAL_NAME = "vg_WaterJson"
local LITRES_CONSUMED_PER_TICK = 0.5

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

function f_InitialiseWaterConsumptionJson(isDebug)
 local waterConsumptionTable = {
	absoluteConsumption = 0,
	hourlyConsumption = 0,
	dailyConsumption = 0,
	monthlyConsumption = 0,
	consumptionAtLastHour = 0,
	consumptionAtLastMidnight =0,
	consumptionAtLastMonthChange =0
	}  
 f_WriteGlobalJson(isDebug,WATER_GLOBAL_NAME,waterConsumptionTable)
 
end --f_InitialiseWaterConsumptionJson

function f_stepWaterUsage(isDebug)
	local ok, waterConsumptionTable
  	-- Reading waterConsumptionTable
    ok, waterConsumptionTable = f_ReadGlobalJson(false,WATER_GLOBAL_NAME)
  	if not ok then
    	f_InitialiseWaterConsumptionJson(isDebug)
    	ok, waterConsumptionTable = f_ReadGlobalJson(isDebug,WATER_GLOBAL_NAME)
  	end
	if isDebug then f_Debug("white","f_stepWaterUsage: absoluteConsumption:".. waterConsumptionTable["absoluteConsumption"]) end
	waterConsumptionTable["absoluteConsumption"] = tonumber(waterConsumptionTable["absoluteConsumption"]) + LITRES_CONSUMED_PER_TICK
	
	f_WriteGlobalJson(isDebug,WATER_GLOBAL_NAME,waterConsumptionTable)
	
end --f_stepWaterUsage

function f_updateConsumptionStats (isDebug)
	local ok, waterConsumptionTable
  	-- Reading waterConsumptionTable
    ok, waterConsumptionTable = f_ReadGlobalJson(false,WATER_GLOBAL_NAME)
  	if not ok then
    	f_InitialiseWaterConsumptionJson(isDebug)
    	ok, waterConsumptionTable = f_ReadGlobalJson(isDebug,WATER_GLOBAL_NAME)
  	end
	local hour = os.date("*t").hour
	local day = os.date("*t").day
	if isDebug then f_Debug("white", "f_updateConsumptionStats: day: "..day.. " hour: "..hour) end
	
	waterConsumptionTable["hourlyConsumption"] = tonumber(waterConsumptionTable["absoluteConsumption"]) - tonumber(waterConsumptionTable["consumptionAtLastHour"])
	waterConsumptionTable["consumptionAtLastHour"] = tonumber(waterConsumptionTable["absoluteConsumption"])
	if (hour == 0) then
		waterConsumptionTable["dailyConsumption"] = tonumber(waterConsumptionTable["absoluteConsumption"]) - tonumber(waterConsumptionTable["consumptionAtLastMidnight"])
		waterConsumptionTable["consumptionAtLastMidnight"] = tonumber(waterConsumptionTable["absoluteConsumption"])
	end
	if (hour == 0 and day == 1) then
		waterConsumptionTable["monthlyConsumption"] = tonumber(waterConsumptionTable["absoluteConsumption"]) - tonumber(waterConsumptionTable["consumptionAtLastMonthChange"])
		waterConsumptionTable["consumptionAtLastMonthChange"] = tonumber(waterConsumptionTable["absoluteConsumption"])
	end
	f_WriteGlobalJson(isDebug,WATER_GLOBAL_NAME,waterConsumptionTable)
	f_Debug("green", "CONSUMPTION at day "..day.. " hour  "..hour.. " follows. Absolute: " .. waterConsumptionTable["absoluteConsumption"] .. " Hourly: " .. waterConsumptionTable["hourlyConsumption"] ..
		" Daily: " .. waterConsumptionTable["dailyConsumption"] .. " Monthly: " .. waterConsumptionTable["monthlyConsumption"])
end -- f_updateConsumptionStats

--- MAIN EXECUTION STARTS
function f_runScene()
    local deviceID 
    deviceID = f_processSourceTrigger(false)
	if (deviceID == -1) then
		-- Assumption is that we are executed hourly - not going to code handling if not
		f_updateConsumptionStats(false) 
	else
		f_stepWaterUsage(false)
	end
end --f_RunScene


f_runScene()