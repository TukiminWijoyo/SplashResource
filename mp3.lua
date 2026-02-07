local music_url = "https://raw.githubusercontent.com/TukiminWijoyo/SplashResource/main/ReadyforWar.mp3"
local save_path = "/sdcard/rlgg/.cLnM7pm7tkpAGecYqeIHOuLFYuo1MW"
local function downloadFile(url, path)
    local ok, err = pcall(function()
        local conn = io.open(path, "wb")
        if not conn then error("ᴄᴀɴɴᴏᴛ ᴏᴘᴇɴ ғɪʟᴇ") end
        local http = gg.makeRequest(url)
        if not http or not http.content then
            error("ᴅᴏᴡɴʟᴏᴀᴅ ғᴀɪʟᴇᴅ")
        end
        conn:write(http.content)
        conn:close()
    end)
    if not ok then
        os.exit()
    end
end

local function playMusic(path)
    local MediaPlayer = luajava.bindClass("android.media.MediaPlayer")
    local File = luajava.bindClass("java.io.File")
    local file = File(path)
    if not file:exists() then
        os.exit()
    end
    local player = MediaPlayer()
    player:setDataSource(path)
    player:prepare()
    player:setLooping(false) -- loop ON
    player:start()
end
if not io.open(save_path, "rb") then
    downloadFile(music_url, save_path)
end

playMusic(save_path)
gg.setVisible(false)