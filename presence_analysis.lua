--[[
%% properties
%% events
%% globals
--]]


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

--- MAIN EXECUTION STARTS
local startTime = os.clock()
local isDebug = false

function f_RunScene(isDebug)
	local ok, presenceTable
  	-- Reading presence table - consider adding lock mechanism later
    ok, presenceTable = f_ReadGlobalJson(true,"vg_PresenceJson")
  	if not ok then
    	f_InitialisePresenceJson(isDebug)
    	ok, presenceTable = f_ReadGlobalJson(isDebug,"vg_PresenceJson")
  	end
	
end

f_RunScene(isDebug)

local elapsedTime = os.clock() - startTime
f_Debug("white","elapsedTime: " .. elapsedTime)