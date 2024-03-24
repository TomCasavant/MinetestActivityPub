-- To use the functions outside this Mod
webchat={}

-- Mod dir
local webchatdir=minetest.get_worldpath().."/"..minetest.get_current_modname()
local http = minetest.request_http_api()
-- Player data
local pldatadir=webchatdir.."/playerdata"
local last_message_id = 0
-- Files in playerdata/<plname>/ directories:
--   lastseen                             1611343962 game  Contains timestamp (Unix epoch) and type of last activity
--   game_is_online   webchat_is_online   1609018688       File exists only while player is online and contains the timestamp of his last activity
--   game_player.log  website_player.log  1611349823 join  Log of player game/website events

minetest.mkdir(webchatdir)

--local url = "http://192.168.1.75:9999/api/create_message"
local modpath = minetest.get_modpath("activitypub")
local cjson = dofile(modpath .. "/json.lua")

local function new_message(player, msg)
    minetest.log("action", "Sending JSON data: " .. player)
    local data = {message = msg, username = player, groups = {"minetest"}, api_key="temporary"}
    local json_data = cjson.encode(data)
    minetest.log("action", "Sending JSON data: " .. json_data)

    local url = "http://192.168.1.75:9999/api/create_message"  -- Replace with your actual URL
 
    http.fetch({
        url = url,
        method = "POST",
        data = json_data,
        extra_headers = { "Content-Type:application/json" }
        --    ["Content-Type"] = "application/json",
        --    ["Content-Length"] = tostring(#json_data)
        --}
    }, function(response)
        if response.succeeded then
            minetest.log("action", "POST request succeeded!")
            minetest.log("action", "Response code: " .. response.code)
            minetest.log("action", "Response data: " .. response.data)
        else
            minetest.log("error", "POST request failed!")
            minetest.log("error", "Error code: " .. response.code)
            minetest.log("error", "Error message: " .. response)
        end
    end)

    minetest.log("action", "After request_http_api")
end

local function poll_messages()
    local url = "http://192.168.1.75:9999/api/get_recent_messages?last_id=" .. last_message_id
    http.fetch({
        url = url,
        method = "GET"
    }, function(response)
        if response.succeeded then
            local messages = minetest.parse_json(response.data)
            if messages then
                for _, message in ipairs(messages) do
                    -- Check if message ID is greater than last_message_id
                    if message.id > last_message_id then
                        minetest.chat_send_all("[ActivityPub] " .. message.username .. ": " .. message.content)
                        last_message_id = message.id
                    end
                end
            end
        else
            minetest.log("error", "Failed to fetch messages from ActivityPub server")
        end
    end)
end

-- Call the poll_messages function periodically
minetest.register_globalstep(function(dtime)
    -- Poll every 10 seconds (adjust as needed)
    if os.time() % 10 == 0 then
        poll_messages()
    end
end)

minetest.register_on_chat_message(new_message)

