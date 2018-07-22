--[[ 
%% properties 
%% autostart
%% globals 
--]]

if (fibaro:getSourceTrigger()["type"] == "autostart") then
  --fibaro:debug("Waiting for Z-Wave engine to start");
  --fibaro:sleep(10000)
end 

if (tonumber(fibaro:countScenes()) > 1) then 
  fibaro:abort() -- Maybe kill first scene (and timers) instead and let new scene run? 
end 

version = "1.5 with Luxa updates"

rules = {}
names = 
    {sun=1,mon=2,tue=3,wed=4,thu=5,fri=6,sat=7,
    jan=1,feb=2,mar=3,apr=4,may=5,jun=6,jul=7,aug=8,sep=9,oct=10,nov=11,dec=12}
sunmap = {["@sunset"] = 'sunsetHour', ["@sunrise"] = 'sunriseHour'}
macros = {['@monthly'] = '0 0 1 * *', ['@weekly'] = '0 0 * * 0', 
          ['@daily'] = '0 0 * * *',   ['@hourly'] = '0 * * * *'}

function Debug(color, message)
  fibaro:debug(string.format('<%s style="color:%s;">%s</%s>', "span", color, message, "span")); 
end

function fmap(fun,seq,offs)
  local s = nil;
  if (#seq == 2 and type(seq[2]) == 'table') then seq = seq[2]; offs = 1 end
  for i=offs,#seq do s = eval(seq[i]); fun(s) end
  return s;
end

function tcopy(t)
    local res = {}
    for _,v in pairs(t) do table.insert(res,v) end
    return res;
end

flookup = {
  ["and"] = function(a)
    local s = true; 
      for i=2,#a do 
        s=s and eval(a[i]); if not s then return s end 
      end return s;
    end,
  ["or"] = function(a)
    local s = false; 
      for i=2,#a do 
        s=s or (eval(a[i])); if s then return s end
      end return false;
    end,
  ["not"] = function(a) return not eval(a[2]) end,
  ["if"] = function(a) if (eval(a[2])) then return eval(a[3]) else return #a > 3 and eval(a[4]) end end,
  ["log"] = function(a) return fmap(function(s) fibaro:debug(s) end,a,2) end,
  ["turnOn"] = function(a) return fmap(function(id) fibaro:call(id,'turnOn') end,a,2) end,
  ["turnOff"] = function(a) return fmap(function(id) fibaro:call(id,'turnOff') end,a,2) end,
  ["dim"] = function(a) return fmap(function(val) fibaro:call(eval(a[2]),'setValue',val) end,a,3) end,
  ["push"] = function(a) return fmap(function(id) fibaro:call(id,'sendPush',eval(a[2])) end,a,3) end,
  ["isOn"] = function(a)
      local offs = 2;
      if (#a == 2 and type(a[2]) == 'table') then a = a[2]; offs = 1 end
      for i=offs,#a do 
        if (fibaro:getValue(eval(a[i]),'value') == "0") then return false end
      end return true;
    end,
  ["isOff"] = function(a)
      local offs = 2;
      if (#a == 2 and type(a[2]) == 'table') then a = a[2]; offs = 1 end
      for i=offs,#a do 
        if tonumber(fibaro:getValue(eval(a[i]),'value')) > 0 then return false end
      end return true;
    end,
  ["eq"] = function(a) return eval(a[2]) == eval(a[3]) end,
  [">"] = function(a) return eval(a[2]) > eval(a[3]) end,
  ["<"] = function(a) return eval(a[2]) < eval(a[3]) end,
  [">="] = function(a) return eval(a[2]) >= eval(a[3]) end,
  ["<="] = function(a) return eval(a[2]) <= eval(a[3]) end,
  ["start"] = function(a) fibaro:startScene(eval(a[2])); return true end,
  ["get"] = function(a) return fibaro:getGlobal(eval(a[2])) end,
  ["set"] = function(a) fibaro:setGlobal(eval(a[2]),eval(a[3])); return true end,
  ["press"] = function(a) fibaro:call(eval(a[2]),'pressButton',eval(a[3])); return true end,
  ["apply"] = function(a) f,a = a[2],tcopy(a[3]); table.insert(a,1,f); return eval(a) end,
  ["last"] = function(a) local s = os.time()-tonumber(fibaro:getValue(eval(a[2]),'lastBreached')) 
    --fibaro:debug("Last="..s); 
      return s end
}

function eval(rule)
  if (type(rule) == 'function') then return rule();
  elseif (type(rule) == 'table') then
    if (#rule > 1 and flookup[rule[1]]) then return flookup[rule[1]](rule) 
    else Debug("red","ERROR") return nil end -- error
  end
  return rule
end

function seq2str(seq)
  if (type(seq) ~=  'table') then return seq end
  if (#seq == 0) then return "*" end
  if (#seq == 1) then return "["..seq2str(seq[1]).."]" end
  local res = "["..seq2str(seq[1]);
  for i = 2, #seq do res = res..","..seq2str(seq[i]) end
  return res.."]";
end
  
function rule2str(rule)
  return
    ((rule.sundoc ~= "" and rule.sundoc) or
    "min:"..seq2str(map2seq(rule.values[1]))..
    " hour:"..seq2str(map2seq(rule.values[2])))..
    " day:"..seq2str(map2seq(rule.values[3]))..
    " month:"..seq2str(map2seq(rule.values[4]))..
    " wday:"..seq2str(map2seq(rule.values[5]));
end

function seq2map(seq)
  local s = {}
  for i,v in ipairs(seq) do
    s[v] = true;
  end
  return s;
end

function map2seq(map)
  local s = {}
  for i,v in pairs(map) do
    table.insert(s,i);
  end
  return s;  
end

function split(str,pat)
  local res = {}
  if (str == "*") then return res end
    string.gsub(str, pat, function (w)
      table.insert(res, w)
    end)
  return res
end

function expand(w1)
  local function resolve(id)
      if (type(id) == 'number') then 
        return id
      elseif (names[id]) then 
        return names[id]
      else return tonumber(id) end
  end
  local w,m = w1[1],w1[2];
  _,_,start,stop = string.find(w,"(%w+)%p(%w+)")
  if (start == nil) then return resolve(w); end
  start = resolve(start)
  stop = resolve(stop)
  local res = {};
  if (string.find(w,"/")) then
    while(start <= m) do
      table.insert(res,start);
      start = start+stop;
    end
  else 
    while (start ~= stop) do
      table.insert(res,start)
      start = (start + 1) % m
    end
    table.insert(res,stop)
  end
  return res;
end

function map(fun,seq)
  local res = {}
  for _,v in ipairs(seq) do
    table.insert(res,fun(v))  
  end
  return res;
end
  
function flatten(seq) -- flattens a table of tables
  local res = {}
  for _,v1 in ipairs(seq) do
    if (type(v1) ~= 'table') then
      table.insert(res,v1)
    else
      for _,v2 in ipairs(v1) do 
        table.insert(res,v2)
      end
    end
  end
  return res
end

function patchrules()
  map(function(r) if (r.sun) then r.values = r.sun(r.values); end return r end, rules)
end

function parserule(str, test, action, doc)
  local sundoc,sun = ""
  local seq = split(str,"(%S+)")   -- min,hour,day,month,wday
  if (sunmap[seq[1]]) then -- sunset etc.
    local sunstr = sunmap[seq[1]];
    local offs = tonumber(seq[2]);
    sundoc = sunstr..":"..offs;
    seq[1] = "*";
    seq[2] = "*";
    sun = function(p) -- called every time to patch in current sunset/rise+offset
      local h,m = fibaro:getValue(1, sunstr):match("(%d+)%d+)")
      local t = h*60+m+offs;
      p[1] = {[t % 60] = true};          -- min
      p[2] = {[math.floor(t/60)] = true}; -- hours
      return p;
    end
  end
  if (macros[seq[1]]) then return parserule(macros[seq[1]], test, action, doc) end -- "macros"
  seq = map(function(w) return split(w,"[%a%d-/]+") end, seq)   -- split sequences "3,4"
  local lim = {59, 23, 31, 12, 7};
  seq = map(function(t) 
              local m = table.remove(lim,1);
              return flatten(map(function (g); return expand({g,m}); end, t)) 
            end, 
            seq) -- expand intervalls "3-5"
  seq = map(seq2map,seq)
  local rule = {values = seq, test = test, action = action, sun = sun, doc = doc, sundoc = sundoc}
  return rule
end

function run(sim)
  local t = os.date("*t");
  Debug("lightblue","Cron vers. "..version)
  Debug("lightblue","Aligning scheduler to 15s past next minute...")
  fibaro:sleep(1000*((60-t.sec)+15));
  Debug("lightblue","Starting scheduler")
  add("1 0 * * *",true, patchrules, "Updating sunset/sunrise",true)
  local time = os.time() -- run every minute from this time...
  local function run_rules()
    local t = sim and os.date("*t",time) or os.date("*t");
    for i,rule in ipairs(rules) do
      local p = rule.values;
      if ((next(p[1]) == nil or p[1][t.min]) and    -- minutes 0-59
          (next(p[2]) == nil or p[2][t.hour]) and   -- hours   0-23
          (next(p[3]) == nil or p[3][t.day]) and    -- day     1-31
          (next(p[4]) == nil or p[4][t.month]) and  -- month   1-12
          (next(p[5]) == nil or p[5][t.wday])) then -- weekday 1-7, 1=sun, 7=sat
          if (eval(rule.test)) then 
            Debug("green","Run "..t.min.."/"..t.hour.."/"..t.day.."/"..t.month.."/"..t.wday..":"..(rule.doc or "Rule-"..i))
            if (not sim) then eval(rule.action); end 
          end
      end
    end
    time = time + 60;
  end
  Debug("yellow","run: sim: " .. tostring(sim))
  if (not sim) then
    local function run_aux() setTimeout(function() run_rules(); run_aux() end, 1000*(time-os.time())) end
    run_aux()
  else
    Debug("lightblue","Sunset today:"..fibaro:getValue(1, 'sunsetHour'))
    Debug("lightblue","Sunrise today:"..fibaro:getValue(1, 'sunriseHour'))
    for i = 1,60*48 do run_rules() end -- simulate 48hours
  end
end

function add(str, test, action, doc, catchup)
  table.insert(rules,parserule(str, test, action, doc))
  if (catchup) then eval(action) end
end

add(
  "1/5 * * * *",
  true,
  -- These will be run
  function() 
    fibaro:startScene(18)
  end, 
  "From 1 minutes every 5 minutes: Starting Lámpaleoltás"
)

add(
  "0 8 * * *",
  true,
  -- These will be run
  function() 
    fibaro:startScene(21)
  end, 
  "At 8AM every day: Check Battery Status"
)

add(
  "1 * * * *",
  true,
  -- These will be run
  function() 
    fibaro:startScene(22)
  end, 
  "At 1 minutes every hour: Calculate Water Usage"
)

add(
  "3/10 * * * *",
  true,
  -- These will be run
  function() 
    fibaro:startScene(9)
  end, 
  "From 3 minutes every 10 minutes: Starting Fűtésvezérlés"
)

add(
  "5/10 * * * *",
  true,
  -- These will be run
  function() 
    fibaro:startScene(6)
  end, 
  "From 5 minutes every 10 minutes: Starting Fürdő Ventilátorvezérlés"
)

add(
  "2/30 * * * *",
  true,
  -- These will be run
  function() 
    fibaro:setGlobal("vg_KazanVezerles", "true")
  end, 
  "From 2 minutes every 30 minutes: Enabling KazánVezérlés"
)

add(
  "4/30 * * * *",
  true,
  -- These will be run
  function() 
    fibaro:setGlobal("vg_KazanVezerles", "false")
  end, 
  "From 4 minutes every 30 minutes: Disabling KazánVezérlés"
)

-- Fűtésidőzítések
add(
  "0 5 * * mon-sun",
  true,
  -- These will be run
  function() 
    fibaro:startScene(13)
  end, 
  "At 5AM each day: Switch presence to Zuhanyzás"
)
add(
  "0 9 * * mon-sun",
  true,
  -- These will be run
  function() 
    fibaro:startScene(15)
  end, 
  "At 9AM each day: Switch presence to Üres lakás"
)
add(
  "0 15 * * mon-sun",
  true,
  -- These will be run
  function() 
    fibaro:startScene(14)
  end, 
  "At 3PM each day: Switch presence to Otthon"
)
add(
  "0 23 * * mon-sun",
  true,
  -- These will be run
  function() 
    fibaro:startScene(12)
  end, 
  "At 11PM each day: Switch presence to Alvás hűvösben"
)
run()


-- Copied from: https://forum.fibaro.com/index.php?/topic/17359-schedule-of-times-in-lua/&do=findComment&comment=85854
--[[
Short doc:

add(<time/date-string>,<additional test>,<action>,<optional doc string>,<optional catchup>)
<additional test> -> Lua function or "struct expr" used as additional test if action should fire
<action> -> Lua function or "struct expr" containing the action
<optional doc string> -> Log string logged when action fires
<optional catchup> -> 'true' if rule should be run once at startup (i.e. initialising, turning off lamps etc)
 
<minute> -> 0 .. 59
<hour> -> 0 .. 23
<day> -> 1 .. 31
<month> -> 1 .. 12
<weekday> -> 1 .. 7 , Sunday=1 and Saturday=7
 
Same numerical values you get from Lua's os.date("*t")..
 
letter lowercase abbreviation allowed for days and months. Ex ‘sun,mon,tue,..’ ‘jan,feb,mar,…’
 
 *          -> matches any value for that field. Ex. ‘*’ in minute field matches 0 .. 59
 x,y,z   -> matches the listed values for that field. Ex. ‘1,20’ in month field matches the 1st and the 20th day of month
 x-y     -> matches values in interval for that field. Ex. ‘sun-sat’ in week day field matches 1,2,3,4,5,6,7
 x/y     -> matches  values starting at x with y increments. Ex. ‘0/1’ matches ‘0,1,2,3,4,5,…    ‘0/15’ matches 0,15,30,45   ‘1/2’ matches ‘1,3,5,7…’
 
Combination allowed like ‘mon-fri,sun’ for every day except Saturday.
 
Minute field can be replaced with ‘@sunrise’ or ‘@sunset’ and hour field with offset in minutes.
Ex. "@sunrise -10 * * mon-fri” means sunrise-10min weekdays (Monday to Friday)
    "@sunset 15 * * sat-sun” means sunset+15min every Saturday and Sunday
       
Examples
 
At minute 0, on hour 0, every day (‘*’) and every month(‘*’) and every weekday (‘*’)
add("0 0 * * *",true,function() print("Hello") end, "At midnight")
 
At minute 10, every hour (‘*’), every day (‘*’) and every month(‘*’), but only on Saurdays
add("10 * * * sat",true,function() print("Hello") end, "10 past every hour")
 
Every 5 minutes starting at minute 0 (‘0/5’), every even hour starting at 0 (‘0/2’) the 9th,13th and 14th  (‘9,13,14’) of month March (‘3’), but only if these days happens on a Saturday,Sunday,Monday or Tuesday. <day> and <weekday> field both have to be true.
add("0/5 0/2 9,13,14 3 sat-tue",true,function() print("Hello") end, "Every 5min every even hours")
 
Every 15 minutes (‘0/15’), every odd hour starting at 5 (‘5/2’) , day 9 to 17th of the month (‘9-17’), March to May (‘3-5’) and Monday to Friday (‘mon-fri’)
add("0/15 5/2 9-17 3-5 mon-fri",true,function() print("Hello again") end, "Every quarter odd hours")
 
10 minutes past sunset (‘@sunset 10’) on odd days (‘1/2’)  on even months (‘0/2), but only weekdays Monday to Friday (‘mon-fri’)
add("@sunset 10 1/2 0/2 mon-fri",true,function() print("Hello!") end, "Sunset+10")
 
15 minutes before sunrise (‘@sunrise -15’) on the first of every month  
add("@sunrise -15 1 * *",true,function() print("Goodbye!") end, "Sunrise-15")
 
Turn on light 34 and 36 every day at 21:00 but only if the global variable 'Home' is equal to 'Yes'
add("0 21 * * *",{'eq',{'get','Home'},'Yes'}, {'turnOn',34,36}, "Turning on lights at 21 if people are at home") 
]]
