--[[
%% properties
%% events
%% globals
--]]

-- Aktuális hőmérsékletek
local vl_EloszobaHom
local vl_FurdoHom
local vl_HaloHom
local vl_NappaliHom
-- Termosztát beállított hőmérsékletek
local vl_EloszobaTermoHom
local vl_FurdoTermoHom
local vl_HaloBalTermoHom
local vl_HaloJobbTermoHom
local vl_NappaliAblakTermoHom
local vl_NappaliAjtoTermoHom
-- Termosztát cél hőmérsékletek
local vl_EloszobaTermoCelHom
local vl_FurdoTermoCelHom
local vl_HaloBalTermoCelHom
local vl_HaloJobbTermoCelHom
local vl_NappaliAblakTermoCelHom
local vl_NappaliAjtoTermoCelHom
-- Konstansok szabályozókörhöz
local FUTES_EROSITES = 1 -- delta T_out / delta T_in
local FUTES_EROSITESI_TENYEZO = 1.2 -- paraméter
local t_FELFUTASI = 30 --perc
local t_LAPPANGASI = 20 --perc
local t_MINTAVETELI = 10 --perc
local INTEGRALASI_IDO_TENYEZO = 4 -- paraméter
local MIN_HIBA = 0.5 --fok
local MIN_VEZERLES = 15 --fok
local MAX_VEZERLES = 35 --fok
local MIN_HIBA_KAZAN = 1 --fok, ekkora eltérés kell a kazán bekapcshoz


function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

-- Code partly stolen from Fibaro forum
function f_ReadGlobalJson(isDebug,varName)
  local debugMessage
  local dataEncoded=fibaro:getGlobalValue(varName)
  if dataEncoded and dataEncoded ~= "null" then
    debugMessage = "f_ReadGlobalJson:" .. varName .. " returns ".. dataEncoded
    if isDebug then f_Debug("white",debugMessage) end
  else
    debugMessage = "f_ReadGlobalJson:" .. varName .." returns nil or null. Please check " ..
    "if Global Variable exists. Program continues and will not crash"
    f_Debug("red",debugMessage)  
    return false, nil
  end
  -- This is where the magic happens:
  local ok, data = pcall(json.decode, dataEncoded)
  if ok then
    if isDebug then f_Debug("white","f_ReadGlobalJson: decode OK") end
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

function f_ReadAllActualTemp(isDebug)
  vl_EloszobaHom = fibaro:getValue(162, "value")
  vl_FurdoHom = fibaro:getValue(156, "value")
  vl_HaloHom = fibaro:getValue(76, "value")
  vl_NappaliHom = fibaro:getValue(168, "value")
  if isDebug then
    local debugMessage = [[f_ReadAllTemp: Eloszoba: ]] .. vl_EloszobaHom .. " Furdo: " .. vl_FurdoHom .. [[ Haloszoba: ]] .. vl_HaloHom .. " Nappali: ".. vl_NappaliHom 
    f_Debug("white", debugMessage);
  end
end

function f_ReadAllTermoTemp(isDebug)
  vl_EloszobaTermoHom = fibaro:getValue(106, "value")
  vl_FurdoTermoHom = fibaro:getValue(104, "value")
  vl_HaloBalTermHom = fibaro:getValue(110, "value") 
  vl_HaloJobbTermHom = fibaro:getValue(112, "value")
  vl_NappaliAblakTermoHom = fibaro:getValue(100, "value")
  vl_NappaliAjtoTermoHom = fibaro:getValue(102, "value")
  if isDebug then
    local debugMessage = "f_ReadAllTermoTemp: Eloszoba:" .. vl_EloszobaTermoHom .. 
     " Furdo: " .. vl_FurdoTermoHom .. " Haloszoba: bal:" .. 
      vl_HaloBalTermHom .. " jobb: " .. vl_HaloJobbTermHom ..
     " Nappali: ablak: ".. vl_NappaliAblakTermoHom  .. " ajtó: " .. vl_NappaliAjtoTermoHom 
    f_Debug("white", debugMessage);
  end
end

function f_SetAllTermoTemp(isDebug)
  fibaro:call(106, "setTargetLevel", vl_EloszobaTermoCelHom)
  fibaro:call(104, "setTargetLevel", vl_FurdoTermoCelHom)
  fibaro:call(110, "setTargetLevel", vl_HaloBalTermoCelHom)
  fibaro:call(112, "setTargetLevel", vl_HaloJobbTermoCelHom)  
  fibaro:call(100, "setTargetLevel", vl_NappaliAblakTermoCelHom)
  fibaro:call(102, "setTargetLevel", vl_NappaliAjtoTermoCelHom)
  if isDebug then
    local debugMessage = "f_SetAllTermoTemp: Eloszoba:" .. vl_EloszobaTermoCelHom .. 
     " Furdo: " .. vl_FurdoTermoCelHom .. " Haloszoba: bal: " .. 
     vl_HaloBalTermoCelHom .. " jobb: " .. 
     " Nappali: ablak: ".. vl_NappaliAblakTermoCelHom  .. " ajtó: " .. vl_NappaliAjtoTermoCelHom 
    f_Debug("green", debugMessage);
  end
end

function f_SetBoilerRelay(isDebug, state)
  local kazanVezerles = fibaro:getGlobalValue("vg_KazanVezerles")
  if isDebug then f_Debug("white", "f_SetBoilerRelay: state: " .. state ..
    " kazanVezerles: " .. kazanVezerles) end
  if kazanVezerles == "true" and state == "off" then
    fibaro:call(67, "turnOff")
    f_Debug("green", "f_SetBoilerRelay: turnOff")
  end
  if kazanVezerles == "true" and state == "on" then
    fibaro:call(67, "turnOn")
    f_Debug("green", "f_SetBoilerRelay: turnOn")
  end
end

function f_calculateNewControlOutput(isDebug,currentError,previousError,
    previousControlOutput)
  local newControlOutput = previousControlOutput + FUTES_EROSITESI_TENYEZO/FUTES_EROSITES *
    t_FELFUTASI / t_LAPPANGASI * (currentError - previousError +
    currentError * t_MINTAVETELI / (INTEGRALASI_IDO_TENYEZO * t_LAPPANGASI))
  newControlOutput = math.floor (newControlOutput*2)/2
  if newControlOutput < MIN_VEZERLES then newControlOutput = MIN_VEZERLES end
  if newControlOutput > MAX_VEZERLES then newControlOutput = MAX_VEZERLES end
  if isDebug then
      local debugMessage = "f_calculateNewControlOutput: curErr: " .. currentError ..
        " prevErr: " .. previousError .. " prevCtrl: " .. previousControlOutput ..
          " currCtrl(result): " .. newControlOutput
      f_Debug("white",debugMessage)
  end
  return newControlOutput 
end

-- Comment use TermoCelHom instead of TermoHom? - have to init before in thta case
function f_initialiseControlJson(isDebug)
 local futesControlTable = {
   eloszoba = {
      previousError = fibaro:getGlobalValue("vg_EloszobaCelHom") - vl_EloszobaHom,
      previousControlOutput = vl_EloszobaTermoHom,},
   furdo = {
      previousError = fibaro:getGlobalValue("vg_FurdoCelHom") - vl_FurdoHom,
      previousControlOutput = vl_FurdoTermoHom},    
   haloszoba = {
      previousError = fibaro:getGlobalValue("vg_HaloCelHom") - vl_HaloHom,
      previousControlOutput = vl_HaloHom},  
   nappali = {
      previousError = fibaro:getGlobalValue("vg_NappaliCelHom") - vl_NappaliHom,
      previousControlOutput = vl_NappaliHom}}
 f_Debug("white","f_initialiseControlJson: " .. futesControlTable.eloszoba.previousError)
 f_WriteGlobalJson(isDebug,"vg_FutesCtrlJson",futesControlTable)
end

function f_calculateAllTermoTemp(isDebug)
  local futesControlTable
  local ok
  -- Read control table, reinitialise if corrupt
  ok, futesControlTable = f_ReadGlobalJson(isDebug,"vg_FutesCtrlJson")
  if isDebug then f_Debug("white","f_calculateAllTermoTemp: ok: ".. tostring(ok)) end 
  if not ok then
    f_initialiseControlJson(isDebug)
    ok, futesControlTable = f_ReadGlobalJson(isDebug,"vg_FutesCtrlJson")
  end
  -- Update control table with current error values
  futesControlTable.eloszoba.currentError =
    fibaro:getGlobalValue("vg_EloszobaCelHom") - vl_EloszobaHom
  futesControlTable.furdo.currentError =
    fibaro:getGlobalValue("vg_FurdoCelHom") - vl_FurdoHom
  futesControlTable.haloszoba.currentError =
    fibaro:getGlobalValue("vg_HaloCelHom") - vl_HaloHom
  futesControlTable.nappali.currentError =
    fibaro:getGlobalValue("vg_NappaliCelHom") - vl_NappaliHom
  
  -- Accept low errors
  if math.abs(futesControlTable.eloszoba.currentError) < MIN_HIBA then
    futesControlTable.eloszoba.currentError = 0; end
  if math.abs(futesControlTable.furdo.currentError) < MIN_HIBA then
    futesControlTable.furdo.currentError = 0; end
  if math.abs(futesControlTable.haloszoba.currentError) < MIN_HIBA then
    futesControlTable.haloszoba.currentError = 0; end
  if math.abs(futesControlTable.nappali.currentError) < MIN_HIBA then
    futesControlTable.nappali.currentError = 0; end  
  
  -- Calculate new target values
  vl_EloszobaTermoCelHom = f_calculateNewControlOutput(isDebug,
      futesControlTable.eloszoba.currentError,
      futesControlTable.eloszoba.previousError,
      futesControlTable.eloszoba.previousControlOutput)
  vl_FurdoTermoCelHom = f_calculateNewControlOutput(isDebug,
      futesControlTable.furdo.currentError,
      futesControlTable.furdo.previousError,
      futesControlTable.furdo.previousControlOutput)
  vl_HaloBalTermoCelHom = f_calculateNewControlOutput(isDebug,
      futesControlTable.eloszoba.currentError,
      futesControlTable.eloszoba.previousError,
      futesControlTable.eloszoba.previousControlOutput)
  vl_HaloJobbTermoCelHom = vl_HaloBalTermoCelHom 
  vl_NappaliAblakTermoCelHom = f_calculateNewControlOutput(isDebug,
      futesControlTable.nappali.currentError,
      futesControlTable.nappali.previousError,
      futesControlTable.nappali.previousControlOutput)
  vl_NappaliAjtoTermoCelHom = vl_NappaliAblakTermoCelHom
  -- Update table & save
  futesControlTable.eloszoba.previousControlOutput = vl_EloszobaTermoCelHom
  futesControlTable.furdo.previousControlOutput = vl_FurdoTermoCelHom
  futesControlTable.haloszoba.previousControlOutput = vl_HaloszobaTermoCelHom
  futesControlTable.nappali.previousControlOutput = vl_NappaliAblakTermoCelHom
  futesControlTable.eloszoba.previousError = futesControlTable.eloszoba.currentError
  futesControlTable.furdo.previousError = futesControlTable.furdo.currentError
  futesControlTable.haloszoba.previousError = futesControlTable.haloszoba.currentError
  futesControlTable.nappali.previousError = futesControlTable.nappali.currentError
  f_WriteGlobalJson(isDebug,"vg_FutesCtrlJson",futesControlTable)
 
end

function f_BoilerControl(isDebug)
  local futesControlTable
  local ok
  local boilerNeeded = false
  -- Read control table, reinitialise if corrupt
  ok, futesControlTable = f_ReadGlobalJson(isDebug,"vg_FutesCtrlJson")
  if isDebug then f_Debug("white","f_BoilerControl: ok: ".. tostring(ok)) end 
  if not ok then
    f_initialiseControlJson(isDebug)
    ok, futesControlTable = f_ReadGlobalJson(isDebug,"vg_FutesCtrlJson")
  end
  -- At this point in any case we can build on previous error
  -- containing current error
  for szoba,szobaTabla in pairs(futesControlTable) do 
    if isDebug then
      local message = "f_BoilerControl: " .. szoba .. ": (previous)Error " ..
        szobaTabla.previousError
      f_Debug("white",message)
    end
    if szobaTabla.previousError > MIN_HIBA_KAZAN then boilerNeeded = true end
  end
  if isDebug then
    local message = "f_BoilerControl: boilerNeeded: " .. tostring(boilerNeeded)
    f_Debug("white",message)
  end
  if boilerNeeded then
    f_SetBoilerRelay(isDebug, "on")
  else
    f_SetBoilerRelay(isDebug, "off")
  end
end

function testSuite()

  --currentError, previousError, previouscontrol
  f_calculateNewControlOutput(true,2,0,23)
  f_calculateNewControlOutput(true,2,2,27)
  f_calculateNewControlOutput(true,0,2,27,5)
  f_calculateNewControlOutput(true,0,0,23)
  f_ReadGlobalJson(true,"notExistingGlobalVar")
  f_ReadGlobalJson(true,"vg_FutesCtrlJson")
  jsonTable = { value1 = 512, value2 = "alma" }
  f_WriteGlobalJson(true,"vg_TestVariable",jsonTable)
  f_ReadGlobalJson(true,"vg_TestVariable",jsonTable)
end


function f_RunScene()
  local isDebug = true
  f_ReadAllActualTemp(isDebug)
  f_ReadAllTermoTemp(isDebug)
  --f_initialiseControlJson(true)
  f_calculateAllTermoTemp(isDebug)
  f_SetAllTermoTemp(isDebug)
  fibaro:setGlobal("vg_KazanVezerles", "true") --set string due to global handlng
  f_BoilerControl(true) -- Keep this edubg for now.
end

f_RunScene()


