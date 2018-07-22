#Based on Fibaro Forum - https://forum.fibaro.com/topic/29188-script-backup-all-scenes/
import requests
import json

#
# HC access data is defined globally
# change as needed
#

hcl_host = "192.168.1.100"
hcl_user = 'admin'
hcl_password = 'Fvcs3kPszPm'

 
# get api response from HC
json_scenes = requests.get("http://" + hcl_host + "/api/scenes", auth=(hcl_user, hcl_password)) 
scenes = json.loads(json_scenes.text)
print(json_scenes)
l = len(scenes)
print ('Length of list is' , l)
for scene in scenes:
	id = scene['id']
	name = scene['name']
	print(id, "\t", name)
"""
    json_thisScene = requests.get("http://" + hcl_host + "/api/scenes?id=" + str(id), auth=(hcl_user, hcl_password))
    thisScene = json.loads(json_thisScene.text)
    if (thisScene['name'] != name):
        print("Error")
    else:
        print("ok")
    thisLua = (thisScene['lua'])
    with open(name + '.json', 'w') as outfile:
        json.dump(thisScene, outfile, indent=4, sort_keys=True)
    with open(name + '.lua', 'w') as outfile:
        outfile.write(thisLua)
"""
#TODO - Match scene with ID
scene_id = "19"

# Get current scene json and code
json_thisScene = requests.get("http://" + hcl_host + "/api/scenes/" + scene_id, auth=(hcl_user, hcl_password))
print(json_thisScene)
thisScene = json.loads(json_thisScene.text)
print(thisScene)
lua = thisScene['lua']
print(lua)

updated_lua_code = """
--[[
%% properties
%% events
%% globals
--]]

print("Hello World! I am a scene for testing API v2")
"""
thisScene['lua'] = updated_lua_code
json_updatedScene = json.dumps(thisScene)
print (json_updatedScene)

json_reply = requests.put("http://" + hcl_host + "/api/scenes/" + scene_id, auth=(hcl_user, hcl_password), json = json_updatedScene)
print('Update scene reply:' + str(json_reply.status_code))
reply = json.loads(json_reply.text)
print(reply)
# Start Scene
json_reply = requests.post("http://" + hcl_host + "/api/scenes/" + scene_id + "/action/start", auth=(hcl_user, hcl_password))
print('Start scene reply:' + str(json_reply.status_code))

# Get debug message
json_debugMessages = requests.get("http://" + hcl_host + "/api/scenes/" + scene_id + "/debugMessages", auth=(hcl_user, hcl_password)) 
print(json_debugMessages)
debugMessages = json.loads(json_debugMessages.text)
print(debugMessages)





