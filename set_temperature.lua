--[[
%% properties
%% events
%% globals
--]]

local vl_celhomAllitas = tonumber(fibaro:getGlobalValue("vg_JelenletAllitas"))


local vl_celhomersekletTabla = {
  [1] = {
    name = "Alvás hűvösben",
    eloszoba = 19,
    furdoszoba = 21, --Éjjel kimegy valaki, ne legyen hideg
    haloszoba = 19,
    nappali = 19,    
  },
  [2] = {
    name = "Reggeli indulás, Fürdő fűtve",
    eloszoba = 22,
    furdoszoba = 26,
    haloszoba = 22,
    nappali = 22,    
  }, 
  [3] = {
    name = "Lakásban",
    eloszoba = 22,
    furdoszoba = 22,
    haloszoba = 22,
    nappali = 22,    
  },
  [4] = {
    name = "Lakás üres",
    eloszoba = 17,
    furdoszoba = 17,
    haloszoba = 17,
    nappali = 17,    
  },
  [5] = {
    name = "Meleg lakás",
    eloszoba = 25,
    furdoszoba = 25,
    haloszoba = 25,
    nappali = 25,    
  }   
}


function f_Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

function f_updateGlobalTargetTemp (isDebug)
  if isDebug then
    f_Debug("white", "f_updateGlobalTargetTemp: vl_celhomAllitas: "..vl_celhomAllitas)
    f_Debug("white", "f_updateGlobalTargetTemp:" ..
      " eloszoba: " .. vl_celhomersekletTabla[vl_celhomAllitas].eloszoba ..
      " furdo: " .. vl_celhomersekletTabla[vl_celhomAllitas].furdoszoba ..
      " halo: " .. vl_celhomersekletTabla[vl_celhomAllitas].haloszoba ..
      " nappali: " .. vl_celhomersekletTabla[vl_celhomAllitas].nappali )
  end
  fibaro:setGlobal("vg_EloszobaCelHom", vl_celhomersekletTabla[vl_celhomAllitas].eloszoba)
  fibaro:setGlobal("vg_FurdoCelHom", vl_celhomersekletTabla[vl_celhomAllitas].furdoszoba)
  fibaro:setGlobal("vg_HaloCelHom", vl_celhomersekletTabla[vl_celhomAllitas].haloszoba)
  fibaro:setGlobal("vg_NappaliCelHom", vl_celhomersekletTabla[vl_celhomAllitas].nappali)
end

f_updateGlobalTargetTemp(true)




