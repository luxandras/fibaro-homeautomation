-- set up some local variables
local thisId = fibaro:getSelfId();
local currenttime = (os.date("%H:%M"))

function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

local WATER_GLOBAL_NAME = "vg_WaterJson"
local PRICE_PER_CUBIC_METER = 252.60
local PRICE_PER_MONTH = 179.95

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

function f_getDisplayedStats(isDebug)
	if isDebug then f_Debug("white","f_getDisplayedStats: entering function") end
	local ok, waterConsumptionTable
  	-- Reading waterConsumptionTable
    ok, waterConsumptionTable = f_ReadGlobalJson(isDebug,WATER_GLOBAL_NAME)
	if isDebug then f_Debug("white","f_getDisplayedStats: absolute " .. waterConsumptionTable.absoluteConsumption) end
	fibaro:call(thisId, "setProperty","ui.absolute.value", "Teljes vízfogyasztás: ".. waterConsumptionTable.absoluteConsumption .." liter")
	fibaro:call(thisId, "setProperty","ui.details.value", 
		" Óra: "..waterConsumptionTable.absoluteConsumption - waterConsumptionTable.consumptionAtLastHour .." liter " ..
		"\n Napi: "..waterConsumptionTable.absoluteConsumption - waterConsumptionTable.consumptionAtLastMidnight .." liter " .. 
		"\n Havi: "..waterConsumptionTable.absoluteConsumption - waterConsumptionTable.consumptionAtLastMonthChange .." liter ")
	fibaro:call(thisId, "setProperty","ui.price.value", "Havi alapdíj: "..PRICE_PER_MONTH .." Ft  Vízdíj: " .. PRICE_PER_CUBIC_METER .. " Ft/m3")
	fibaro:call(thisId, "setProperty","ui.bill.value", "Havi vízszámla: "..
		(waterConsumptionTable.absoluteConsumption - waterConsumptionTable.consumptionAtLastMonthChange)*PRICE_PER_CUBIC_METER/1000 +  PRICE_PER_MONTH .." Ft")	
end

f_getDisplayedStats(true)