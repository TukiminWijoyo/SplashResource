





--========================================================--
--MD5效验
--========================================================--
local function safe_checkMD5(list)
    local orig_exit = os.exit
    local EXIT_MARKER = {}
    
    os.exit = function()
        error(EXIT_MARKER)
    end

    local ok, res = pcall(function() return checkMD5(list) end)
    os.exit = orig_exit

    if not ok then
        if res == EXIT_MARKER then
            return false, "exit"
        else
            return false, ("error: %s"):format(tostring(res))
        end
    end

    return not not res, "ok"
end

--MD5白名单
local ok, reason = safe_checkMD5({
    "df946529b61206845692d9e893fb6145",--Yae～
})

if not ok then
    gg.alert("❌ MD5效验失败，当你看到这条信息说明有新的安装包发布，或者安装包被破解修改，请联系 TG：Yaenb688888888 获取最新官方版本。\n\n小伙子不要想着破解，请用官方 Yae～运行。")
    os.exit()
end
--========================================================--
--卡密效验
--========================================================--
gg.setVisible(false)
KEY_URL = "https://raw.githubusercontent.com/TukiminWijoyo/SplashResource/main/keys.lua"
FAKEID_PATH = "/sdcard/.nHf04tqJ0cJIb1EUVR7DhBNZ"
LOGIN_PATH  = "/sdcard/.1KNkoZNIb1EUVR7DhSsMBiHYyZ"
XOR_KEY     = 0xF9
math.randomseed(os.time())
LOGGED_IN = false
LOGIN_KEY = ""
LOGIN_EXP = ""
local function xorCrypt(s)
  local t = {}
  for i = 1, #s do
    t[i] = string.char(string.byte(s, i) ~ XOR_KEY)
  end
  return table.concat(t)
end
local function genFakeID()
  local c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local p = "Yae"
  local len = 30
  local s = p
  for i = 1, len - #p do
    local r = math.random(#c)
    s = s .. c:sub(r, r)
  end
  return s
end
local function getFakeID()
  local f = io.open(FAKEID_PATH, "rb")
  if f then
    local raw = f:read("*a")
    f:close()
    local ok, id = pcall(xorCrypt, raw)
    if ok and id and #id == 30 and id:match("^Yae") then
      return id
    end
  end
  local id = genFakeID()
  local f = io.open(FAKEID_PATH, "wb")
  f:write(xorCrypt(id))
  f:close()
  return id
end
FAKE_ID = getFakeID()
local function isExpired(date)
  local y,m,d = date:match("(%d+)%-(%d+)%-(%d+)")
  if not y then return true end
  local exp = os.time{ year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=23, min=59, sec=59 }
  return os.time() > exp
end
local function loadKeyDB()
  local r = gg.makeRequest(KEY_URL)
  if not r or r.code ~= 200 then
    gg.alert("❌ ғᴀɪʟᴇᴅ ᴄᴏɴɴᴇᴄᴛ ᴛᴏ ᴅᴀᴛᴀʙᴀsᴇ")
    os.exit()
  end
  local fn = load(r.content)
  if not fn then
    gg.alert("❌ ᴅᴀᴛᴀʙᴀsᴇ ʀᴜsᴀᴋ")
    os.exit()
  end
  return fn()
end
local function showInfo(key, exp)
  local pressed = gg.alert(
    "ᴋᴇʏ : "..key..
    "\nᴇxᴘɪʀᴇᴅ : "..exp,
    "ɴᴇxᴛ",
    "ғᴏʀɢᴇᴛ ᴛʜᴇ ᴋᴇʏ"
  )
  if pressed == 2 then
    os.remove(LOGIN_PATH)
    LOGGED_IN = false
    LOGIN_KEY = ""
    LOGIN_EXP = ""
    gg.setVisible(true)
    dofile(gg.getFile())
    os.exit()
  end
end
do
  local f = io.open(LOGIN_PATH, "rb")
  if f then
    local data = xorCrypt(f:read("*a"))
    f:close()
    local key, exp = data:match("^(.-)|(.-)$")
    if key and exp and not isExpired(exp) then
      local db = loadKeyDB()
      if db[key] and db[key].device == FAKE_ID then
        LOGIN_KEY = key
        LOGIN_EXP = exp
        LOGGED_IN = true
        showInfo(key, exp)
      end
    end
  end
end
if not LOGGED_IN then
  gg.setVisible(true)
  local r = gg.alert(
    "📱 ᴅᴇᴠɪᴄᴇ ɪᴅ : \n\n"..FAKE_ID..
    "\n",
    "📝 ᴄᴏᴘʏ",
    "🔵 ɴᴇxᴛ"
  )
  if r == 1 then gg.copyText(FAKE_ID) end
  local inp = gg.prompt({"Yae~v\n获取卡密联系TG: Yaenb688888888\n🔐 ᴘʟᴇᴀsᴇ ɪɴᴘᴜᴛ ʏᴏᴜʀ ᴋᴇʏ : "}, {""}, {"text"})
  if not inp then os.exit() end
  local USER_KEY = inp[1]
  local db = loadKeyDB()
  local info = db[USER_KEY]
  if not info then gg.alert("❌ ᴋᴇʏ ɪɴᴠᴀʟɪᴅ") os.exit() end
  if isExpired(info.expire) then gg.alert("⛔ ᴋᴇʏ ᴇxᴘɪʀᴇᴅ") os.exit() end
  if info.device ~= "" and info.device ~= FAKE_ID then
    gg.alert("⛔ ᴋᴇʏ ɴᴏᴛ ᴡᴏʀᴋ") os.exit()
  end
  local f = io.open(LOGIN_PATH, "wb")
  f:write(xorCrypt(USER_KEY.."|"..info.expire))
  f:close()
  LOGIN_KEY = USER_KEY
  LOGIN_EXP = info.expire
  LOGGED_IN = true
  showInfo(LOGIN_KEY, LOGIN_EXP)
end
gg.setVisible(true)
--========================================================--
--防御模式
--========================================================--
function xhsgg()
    while true do
        gg.sleep(5000)
        gg.killGG()--杀GG
        gg.checkVpn()--杀VPN
        checkXposed()--杀Xp框架
        setScreenshots(true)--禁止截图录屏
        gg.toast("😎 无敌防御已启动")
    end
end

-- 多线程执行防御
--luajava.startThread(xhsgg)
--========================================================--
--UI界面
--========================================================--
xfcpic = "https://imgimg.qqdsw8.cn/view.php/be1ee9e78c70b8f2eb7709ba9d169003.png"

hzs = {}
local hzs = hzs
local android = import('android.*')
 
sleep = gg.sleep
 
开 = "开"
关 = "关"
 
context = app.context
window = context:getSystemService("window")
 
function getLayoutParams()
LayoutParams = WindowManager.LayoutParams
layoutParams = luajava.new(LayoutParams)
if (Build.VERSION.SDK_INT >= 26) then
layoutParams.type = LayoutParams.TYPE_APPLICATION_OVERLAY
else
layoutParams.type = LayoutParams.TYPE_PHONE
end
layoutParams.format = PixelFormat.RGBA_8888
layoutParams.flags = LayoutParams.FLAG_NOT_FOCUSABLE
layoutParams.gravity = Gravity.TOP|Gravity.LEFT
layoutParams.width = LayoutParams.WRAP_CONTENT
layoutParams.height = LayoutParams.WRAP_CONTENT
return layoutParams
end
 
function getj6()
jianbian6 = luajava.new(GradientDrawable)
jianbian6:setCornerRadius(20)
jianbian6:setGradientType(GradientDrawable.LINEAR_GRADIENT)
jianbian6:setColors({0x33000000,0x33000000})
jianbian6:setStroke(4,"0xdd282F4B")
return jianbian6
end
 
slctb2 = luajava.loadlayout({
GradientDrawable,
color = "#7f7fd5",
cornerRadius = 10
})
 
function getseekgra()
jianbians = luajava.new(GradientDrawable)
jianbians:setCornerRadius(20)
jianbians:setGradientType(GradientDrawable.LINEAR_GRADIENT)
jianbians:setColors({0x667f7fd5,0x667f7fd5})
jianbians:setStroke(2,"0x44000000")
return jianbians
end
 
slctb=getseekgra()
slcta = luajava.loadlayout({
GradientDrawable,
color = "#282F4B",
cornerRadius = 20
})
 
slctc = luajava.loadlayout {
GradientDrawable,
color = "#11ffffff",
cornerRadius = 8
}
 
slctd = luajava.loadlayout {
GradientDrawable,
color = "#55ffffff",
cornerRadius = 8
}
 
slcte = luajava.loadlayout {
GradientDrawable,
color = "#11ffffff",
cornerRadius = 12
}
 
slctf = luajava.loadlayout {
GradientDrawable,
color = "#aa1E1C27",
cornerRadius = 12
}
 
function getSelector3()
jianbians = luajava.new(GradientDrawable)
jianbians:setCornerRadius(10)
jianbians:setGradientType(GradientDrawable.LINEAR_GRADIENT)
jianbians:setColors({0x667f7fd5,0x667f7fd5})
jianbians:setStroke(2,"0x44000000")
 
selector = luajava.getStateListDrawable()
selector:addState({
android.R.attr.state_pressed
}, luajava.loadlayout {
GradientDrawable,
color = "#88000000",
cornerRadius = 12
})
selector:addState({
android.R.attr.state_pressed
}, slctf)
return selector
end
 
function getSelector()
selector = luajava.getStateListDrawable()
selector:addState({
android.R.attr.state_pressed
}, slcta)
selector:addState({
-android.R.attr.state_pressed
}, slctb)
return selector
end
 
function getSelector2()
selector = luajava.getStateListDrawable()
selector:addState({
android.R.attr.state_pressed
}, slctd)
selector:addState({
-android.R.attr.state_pressed
}, slctc)
return selector
end
 
jianbian = luajava.new(GradientDrawable)
jianbian:setCornerRadius(30)
jianbian:setGradientType(GradientDrawable.LINEAR_GRADIENT)
jianbian2 = luajava.new(GradientDrawable)
jianbian2:setCornerRadius(30)
jianbian2:setGradientType(GradientDrawable.LINEAR_GRADIENT)
 
local isswitch
YoYoImpl = luajava.getYoYoImpl()
 
hzs.menu = function(sview)
if isswitch then
return false
end
isswitch = true
 
cebian ={
LinearLayout,
id = "侧边",
visibility = "gone",
layout_height = "250dp",
layout_width = "68dp",
orientation = "vertical",
background = {
GradientDrawable,
color = "#00ffffff",
cornerRadius = 10
},
}
 
gund = {LinearLayout, orientation="vertical"}
for i=1,#stab do
gund[#gund+1]={
LinearLayout,
id = "jm"..i,
layout_height = "28dp",
layout_width = "68dp",
layout_marginTop = "3dp",
layout_marginBottom = "3dp",
background=getSelector(),
{
TextView,
gravity="center",
text = stab[i][1],
layout_height = "28dp",
layout_width = "68dp",
onClick=function() 切换(i) end
}}
end
 
cebian[#cebian+1]={ScrollView,
layout_height = "250dp",
layout_width = "68dp",
gund}
 
cebian[#cebian+1]={
ImageView,
id = "exit",
src = "",
layout_width = "20dp",
layout_height = "20dp",
layout_marginTop = "10dp",
layout_marginLeft = "14dp",
}
 
cebian=luajava.loadlayout(cebian)
 
for i=1,#stab do
_ENV["layout"..i] = luajava.loadlayout({
ScrollView,
fillViewport = "true",
padding = "10dp",
id = "layout"..i,
visibility = "gone",
layout_width = "250dp",
layout_height = "250dp",
orientation = "horizontal",
{
LinearLayout,
id = "layoutm"..i,
background = getj6(),
gravity = "top",
layout_width = "210dp",
orientation = "vertical",
gravity = "center_horizontal",
}
})
end
 
ckou = {
LinearLayout,
id = "chuangk",
visibility = "gone",
layout_width = "wrap_content",
layout_height = "match_parent",
orientation = "horizontal",
cebian,
}
 
for i=1,#stab do
ckou[#ckou+1]=_ENV["layout"..i]
end
 
ckou=luajava.loadlayout(ckou)
 
title = luajava.loadlayout({
TextView,
id = "title",
textColor="#282F4B",
visibility = "gone",
text = stab[1][2],
gravity = "center",
textSize = "24sp",
layout_marginLeft = "30dp",
layout_width = "fill_parent",
})
 
floatWindow = {
LinearLayout,
id = "motion",
layout_width = "wrap_content",
orientation = "vertical",
gravity = "center_vertical",
layout_height = "wrap_content",
{
LinearLayout,
layout_width = "match_parent",
layout_height = "wrap_content",
orientation = "horizontal",
gravity = "center_vertical",
{
LinearLayout,
layout_width = "48dp",
layout_height = "wrap_content",
layout_marginLeft = "0dp",
layout_marginTop = "6dp",
layout_marginBottom = "2dp",
gravity = "center", {
ImageView,
id = "control",
background = xfcpic,
layout_width = "40dp",
layout_height = "40dp",
}},
title,
},
ckou
}
 
local function invoke()
mainLayoutParams = getLayoutParams()
floatWindow = luajava.loadlayout(floatWindow)
 
local function invoke2()
block('start')
for k=1,#stab do
for i = 1,#sview[k] do
_ENV["layoutm"..k]:addView(sview[k][i])
end
end
window:addView(floatWindow, mainLayoutParams)
block('end')
end
 
local runnable = luajava.getRunnable(invoke2)
local handler = luajava.getHandler()
handler:post(runnable)
block('join')
 
control.onClick = function()
隐藏()
end
 
exit.onClick = function()
gg.toast("悬浮窗已退出")
window:removeView(floatWindow)
luajava.setFloatingWindowHide(false)
luajava.newThread(function() os.exit() end):start()
bloc("end")
end
 
local isMove
 
hanshu = function(v, event)
local Action = event:getAction()
if Action == MotionEvent.ACTION_DOWN then
isMove = false
RawX = event:getRawX()
RawY = event:getRawY()
x = mainLayoutParams.x
y = mainLayoutParams.y
elseif Action == MotionEvent.ACTION_MOVE then
isMove = true
mainLayoutParams.x = tonumber(x) + (event:getRawX() - RawX)
mainLayoutParams.y = tonumber(y) + (event:getRawY() - RawY)
window:updateViewLayout(floatWindow, mainLayoutParams)
end
end
 
motion.onTouch = hanshu
control.onTouch = hanshu
exit.onTouch = hanshu
 
for i=1,#stab do
_ENV["jm"..i].onTouch = hanshu
end
end
 
invoke(swib1,swib2)
jm1:setBackground(slcta)
gg.setVisible(false)
luajava.setFloatingWindowHide(true)
end
 
corbk = true
当前ui = 1
 
function 切换(x)
当前ui = x
luajava.runUiThread(function()
for i=1,#stab do
_ENV["jm"..i]:setBackground(slctb)
_ENV["layout"..i]:setVisibility(View.GONE)
end
title:setText(stab[当前ui][2])
_ENV["layout"..当前ui]:setVisibility(View.VISIBLE)
_ENV["jm"..当前ui]:setBackground(slcta)
YoYoImpl:with("FadeIn"):duration(200):playOn(_ENV["layout"..当前ui])
end)
end
 
显示 = 0
 
beij = luajava.new(GradientDrawable)
beij:setCornerRadius(40)
beij:setGradientType(GradientDrawable.LINEAR_GRADIENT)
beij:setColors(({0xdd91EAE4,0xaa86A8E7,0xdd7f7fd5}))
beij:setStroke(0,"0x44FFffff")
 
beij2 = luajava.loadlayout({
GradientDrawable,
color = "#001E1C27",
cornerRadius = 10
})
 
function 隐藏()
luajava.runUiThread(function()
control:setBackground(luajava.getBitmapDrawable(xfcpic))
if tonumber(tostring(cebian:getVisibility())) == 8.0 then
chuangk:setVisibility(View.VISIBLE)
cebian:setVisibility(View.VISIBLE)
title:setVisibility(View.VISIBLE)
mainLayoutParams.flags = LayoutParams.FLAG_NOT_TOUCH_MODAL
window:updateViewLayout(floatWindow, mainLayoutParams)
YoYoImpl:with("SlideInDown"):duration(200):playOn(cebian)
_ENV["layout"..当前ui]:setVisibility(View.VISIBLE)
YoYoImpl:with("FadeIn"):duration(800):playOn(_ENV["layout"..当前ui])
floatWindow:setBackground(beij)
else
luajava.runUiThread(function()
mainLayoutParams.flags = LayoutParams.FLAG_NOT_FOCUSABLE
window:updateViewLayout(floatWindow, mainLayoutParams)
end)
control:setBackground(luajava.getBitmapDrawable(xfcpic))
title:setVisibility(View.GONE)
floatWindow:setBackground(beij2)
chuangk:setVisibility(View.GONE)
cebian:setVisibility(View.GONE)
_ENV["layout"..当前ui]:setVisibility(View.GONE)
end
end)
end
 
function guid()
seed = {
'e','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
}
tb = {}
for i = 1,32 do
table.insert(tb,seed[math.random(1,16)])
end
sid = table.concat(tb)
return string.format('%s%s%s%s%s',
string.sub(sid,1,8),
string.sub(sid,10,12),
string.sub(sid,21,22))
..string.format('%s%s%s%s%s',
string.sub(sid,1,6),
string.sub(sid,21,25)
)
end
 
chazhi={} chajv={}
 
function hzs.seek(name,bian,smin,smax,nows)
_ENV[bian] =nows
thum=getseekgra()
thum:setSize(60, 60)
smin=tonumber(smin) smax=tonumber(smax)
chajv[bian]=smax-smin
chazhi[bian]=1-smin
if smin==nil then smin=1 smax=10 end
truesmin=1
truesmax=truesmin+chajv[bian]
if not nows then nows = smin tnows=(smin-nows)
else
tnows=(nows-smin)+1
end
if _ENV[bian] == nil then _ENV[bian] = 1.0 end
if not name then name = "未设置" end
local names = name..guid()
 
rest = luajava.loadlayout({
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
{
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
layout_marginTop = "5dp",
layout_marginBottom = "5dp",
layout_marginLeft = "10dp",
layout_marginRight = "10dp",
gravity = "center_vertical",
background = getseekgra(),
{
TextView,
gravity = "top",
text = name..":"..nows,
textColor="#FFFFFF",
id = luajava.newId(names),
layout_width = '70dp',
layout_marginLeft = "5dp",
layout_marginRight = "0dp",
},
{
SeekBar,
layout_width = '120dp',
id=luajava.newId(name.."seekbar"),
min = truesmin,
max = truesmax,
progress=tnows,
thumb=thum,
progressHeight="10dp",
onSeekBarChange = {
onProgressChanged = function(SeekBar, var2, var3)
if not var3 then
return
end
local resultvar=tonumber(string.sub(var2,0,-3))-chazhi[bian]
luajava.runUiThread(function()
luajava.getIdValue(names):setText(name..":".. resultvar)
end)
_ENV[bian] = resultvar
end
}}
}})
return rest
end
 
function hzs.switch(name,func1,func2)
if type(func1) == "table" then
gg.alert("出现错误\n如果你是用的是旧版\n请将开头第一个chagan.switch改成hzs.menu")
gg.copyText("")
os.exit()
end
local func = 开关(name,func1,func2)
if not name then name = "未设置" end
 
rest = luajava.loadlayout({
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
{
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
layout_marginTop = "5dp",
layout_marginBottom = "5dp",
layout_marginLeft = "10dp",
layout_marginRight = "10dp",
gravity = "center_vertical",
background = getseekgra(),
{
TextView,
gravity = "top",
text = name,
layout_width = '100dp',
layout_marginLeft = "10dp",
layout_marginRight = "10dp",
},
{
Switch,
gravity = "top",
layout_width = 'match_parent',
layout_hight = "10dp",
switchMinWidth = "20dp",
onCheckedChange = function(Switch,var2,var3)
if var2 == true then var2 = "开" else var2 = "关" end
luajava.newThread(function() func() end):start()
end,
}}
})
return rest
end
 
function hzs.edit(name)
_ENV[name] = name..guid()
if not name then name = "点击输入文字" end
 
rest = luajava.loadlayout({
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
{
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
layout_marginTop = "5dp",
layout_marginBottom = "5dp",
layout_marginLeft = "10dp",
layout_marginRight = "10dp",
gravity = "center_vertical",
background = getseekgra(),
{
EditText,
gravity = "top",
hint = name,
gravity="center",
id = luajava.newId(_ENV[name]),
layout_width = 'fill',
layout_marginLeft = "10dp",
layout_marginRight = "10dp",
}}
})
return rest
end
 
function hzs.radio(radio)
firadio = {
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "fill_parent",
padding="10dp",
orientation = "vertical"
}
if type(radio[1]) == "string" or type(radio[1]) == "number" then
firadio[#firadio+1] = {TextView,text = radio[1]}
end
 
radios = {
RadioGroup,background = getseekgra(),
layout_width = 'fill_parent',
}
 
for i = 2,#radio do
radios[#radios+1] = {
RadioButton,
layout_width = 'fill_parent',
text = radio[i][1],
onClick = function() luajava.newThread(function() pcall(radio[i][2]) end):start() end,
}
end
firadio[#firadio+1] = radios
return luajava.loadlayout(firadio)
end
 
function hzs.check(cklist)
rest = {
LinearLayout,
layout_width = 'match_parent',
layout_height = "30dp",
gravity = "center"
}
 
for i = 1,#cklist do
local name = cklist[i][1]
local func1 = cklist[i][2]
local func2 = cklist[i][3]
local nid = cklist[i][4]
 
if type(func1) == "table" then
gg.alert("出现错误\n如果你是用的是旧版\n请将开头第一个chagan.switch改成hzs.menu")
gg.copyText("Yae～NB666")
os.exit()
end
 
if not name then name = "未设置" end
nid = name..guid()
local func = 开关2(nid,func1,func2,nid)
 
rstt = luajava.loadlayout({
LinearLayout,
layout_width = 'wrap_content',
layout_height = "30dp",
layout_marginTop = "5dp",
layout_marginBottom = "5dp",
layout_marginLeft = "0dp",
layout_marginRight = "10dp",
gravity = "center_vertical",
onClick = function() luajava.newThread(function() func() end):start() end,
{ImageView,
id = luajava.newId(nid),
layout_width = '20dp',
layout_height = "20dp",
background = "",
},{
TextView,
gravity = "top",
text = name,
textColor="#ffffff",
layout_width = 'wrap_content',
layout_height = 'wrap_content',
layout_marginLeft = "4dp",
layout_marginRight = "5dp",
}})
rest[#rest+1] = rstt
end
return luajava.loadlayout(rest)
end
 
function hzs.button(txt,func)
if not txt then txt = "未设置" end
return luajava.loadlayout(
{
LinearLayout,
layout_width = 'fill_parent',
layout_hight = "wrap_content", {
LinearLayout,
layout_width = "fill_parent",
gravity = "center_horizontal",
layout_marginRight="10dp",
layout_marginLeft="10dp",
layout_marginTop = "5dp",
layout_marginBottom = "5dp",
background = getSelector3(),
onClick = function() luajava.newThread(function() pcall(func) end):start() end,
{
TextView,
text = txt,
textSize = "16sp",
layout_width = "wrap_content",
},
}})
end
 
function hzs.text(txt,color,size)
if not txt then txt = "未设置文字" end
if not color then color = "#ffffff" end
if not size then size = "18sp" end
return luajava.loadlayout(
{
TextView,
text = txt,
textSize = size,
textColor = color,
layout_width = "wrap_content",
})
end
 
corb = true
 
function hzs.setedit(name,txt)
txt = tostring(txt)
luajava.runUiThread(function()
luajava.getIdValue(_ENV[name]):setText(txt)
end)
end
 
function hzs.getedit(name)
edit = tostring(luajava.getIdValue(_ENV[name]):getText())
return edit
end
 
function 开关(name,func1,func2)
if func1 == nil then func1 = "" end
if func2 == nil then func2 = "" end
if type(func1) == "function" then
return function()
namers = _ENV[name]
if namers ~= "开" then
_ENV[name] = "开"
pcall(func1)
else
_ENV[name] = "关"
pcall(func2)
end
end
end
end
 
function 开关2(name,func1,func2,nid)
if func1 == nil then func1 = "" end
if func2 == nil then func2 = "" end
if type(func1) == "function" then
return function()
namers = _ENV[name]
if namers ~= "开" then
luajava.runUiThread(function()
end)
_ENV[name] = "开"
func1()
else
luajava.runUiThread(function()
end)
_ENV[name] = "关"
func2()
end
end
end
end
--========================================================--
--自动启动游戏绑定进程
--========================================================--
_G.pkgs = {
    CN = "com.miHoYo.Yuanshen",
    GL = "com.miHoYo.GenshinImpact"
}

local allApps = {}
pcall(function()
    allApps = app.getInstalledPackages and app.getInstalledPackages() or app.list()
end)
if type(allApps) ~= "table" then allApps = {} end

local installedCN, installedGL = false, false
for _, pkg in pairs(allApps) do
    if pkg == _G.pkgs.CN then
        installedCN = true
    elseif pkg == _G.pkgs.GL then
        installedGL = true
    end
end

if not installedCN and not installedGL then
    while true do
        local alert = gg.alert(
            "❌ 未检测到原神国服或国际服\n\n请先安装游戏后再运行脚本！",
            "确定退出"
        )
        if alert == 1 then
            gg.toast("👋 脚本已退出")
            os.exit()
        end
    end
end

_G.selPkg, _G.serverFlag, _G.serverName = nil, nil, nil

if installedCN and installedGL then
    while true do
        local choice = gg.alert(
            "检测到两个版本，请选择要启动的服务器：\n\n⚠️ 必须选择才能继续运行脚本",
            "❌ 退出脚本",
            "🌏 原神国际服",
            "🇨🇳 原神国服"
        )
        if choice == 1 then
            gg.toast("👋 已退出脚本")
            os.exit()
        elseif choice == 2 then
            _G.selPkg = _G.pkgs.GL
            _G.serverFlag = "🌏"
            _G.serverName = "国际服"
            break
        elseif choice == 3 then
            _G.selPkg = _G.pkgs.CN
            _G.serverFlag = "🇨🇳"
            _G.serverName = "国服"
            break
        end
    end
elseif installedCN then
    _G.selPkg = _G.pkgs.CN
    _G.serverFlag = "🇨🇳"
    _G.serverName = "国服"
elseif installedGL then
    _G.selPkg = _G.pkgs.GL
    _G.serverFlag = "🌏"
    _G.serverName = "国际服"
end

gg.toast("▶️ 正在启动 " .. _G.serverFlag .. " 原神" .. _G.serverName .. " ...")
pcall(function() app.start(_G.selPkg) end)
gg.sleep(2000)

local success = false
for i = 1, 25 do
    local runList = {}
    pcall(function()
        runList = app.getRunningPackages and app.getRunningPackages() or app.runList()
    end)
    if type(runList) == "table" then
        for _, pkg in pairs(runList) do
            if pkg == _G.selPkg then
                gg.setProcess(_G.selPkg)
                success = true
                break
            end
        end
    end
    if success then break end
    gg.toast("⌛ 等待游戏启动中...（" .. i .. "）")
    gg.sleep(1000)
end

if success then
    gg.toast("✅ " .. _G.serverFlag .. " 原神" .. _G.serverName .. " 进程绑定成功！")
else
    gg.toast("❌ 未检测到 " .. _G.serverFlag .. " 原神" .. _G.serverName .. " 进程！")
end
--========================================================--
--屏幕文字绘制
--========================================================--
showText = true

local texts = {
{
content='Yae～',
x=2000,
y=180,
color='#00FF00'
},
{
content='绿玩一时爽',
x=2000,
y=260,
color='#00FF00'
}
}

local function huiz()
    for i, t in ipairs(texts) do
        if showText then
            draw.setColor(t.color)
            draw.setStyle("描边并填充")
            draw.setSize(60)
            draw.text(t.content, t.x, t.y)
        else
            draw.setColor("#00000000")
            draw.setStyle("填充")
            draw.setSize(20)
            draw.text(t.content, t.x, t.y)
        end
    end
end

function pmwzk()
    showText = true
    huiz()
    gg.toast("✅ 文字已显示")
end

function pmwzg()
    showText = false
    huiz()
    gg.toast("🚫 文字已隐藏")
end

huiz()
--========================================================--
--游戏全局变速
--========================================================--
local configFile = "/storage/emulated/0/yxbs.txt"
local speed = 1.0
local lastSetSpeed = 1.0
local isSpeedHackEnabled = false

local function loadSpeedConfig()
    local file = io.open(configFile, "r")
    if file then
        local saved = tonumber(file:read("*all"))
        file:close()
        if saved and saved > 0 then
            lastSetSpeed = saved
        end
    end
end

local function saveSpeedConfig(value)
    local file = io.open(configFile, "w+")
    if file then
        file:write(tostring(value))
        file:close()
    end
end

local function setGameSpeed(newSpeed)
    speed = newSpeed
    lastSetSpeed = newSpeed
    gg.setSpeed(newSpeed)
    saveSpeedConfig(newSpeed)
    gg.toast("✅ 当前速度 " .. newSpeed .. "x")
end

function bsk()
    loadSpeedConfig()
    local input = gg.prompt(
        {"请设置游戏速度：\n\n⚡ 加速：输入大于1的数字\n🐢 减速：输入小于1的数字\n\n例如：0.1=极慢速 0.5=慢速 1.0=正常 2.0=双倍 5.0=五倍\n\n⚠️ 注意：速度过快可能导致卡顿，过慢影响体验，建议0.1-10.0"},
        {[1] = tostring(lastSetSpeed)},
        {[1] = "text"}
    )
    if not input then
        gg.toast("❎ 你取消了操作")
        return
    end
    local text = input[1]
    if not string.match(text, "^%d+%.?%d?$") then
        gg.toast("❌ 请输入整数或一位小数（如 1、1.5）")
        return
    end
    local newSpeed = tonumber(text)
    if not newSpeed or newSpeed <= 0 then
        gg.toast("❌ 请输入大于 0 的有效倍率")
        return
    end
    setGameSpeed(newSpeed)
    isSpeedHackEnabled = true
    gg.toast("✅ 变速已开启 - 速度 " .. newSpeed .. "x")
end

function bsg()
    if isSpeedHackEnabled then
        gg.setSpeed(1.0)
        isSpeedHackEnabled = false
        gg.toast("🚫 变速已关闭，恢复默认速度")
    else
        gg.toast("ℹ️ 变速功能未开启")
    end
end

loadSpeedConfig()
--========================================================--
--游戏内存修改函数，静态基址
--========================================================--
function XGBase(Address, AFV)
    local address = 0

    for index, offset in ipairs(Address) do
        if index == 1 then
            address = offset
        else
            address = gg.getValues({{address = address + offset, flags = 4}})[1].value
        end
    end

    local Value, Freeze = {}, {}

    for index, value in ipairs(AFV) do
        local VALUE = {
            address = address + value[3],
            flags = value[2],
            value = value[1],
            freeze = value[4] or false
        }

        if value[4] then
            Freeze[#Freeze + 1] = VALUE
        else
            gg.removeListItems({{address = address + value[3], flags = value[2]}})
            Value[#Value + 1] = VALUE
        end
    end

    local totalModified = #Value + #Freeze

    if #Value > 0 then
        gg.setValues(Value)
    end
    if #Freeze > 0 then
        gg.addListItems(Freeze)
    end

    if totalModified > 0 then
        gg.toast("✅ 成功修改 " .. totalModified .. " 条数据\n❄️ 冻结修改: " .. #Freeze .. " 条")
    else
        gg.toast("⚠️ 没有执行任何修改")
    end
end
--========================================================--
--游戏内存修改函数，指针链
--========================================================--
function S_Pointer(t_So, t_Offset, _bit)
    local function getRanges()
        local ranges = {}
        local t = gg.getRangesList('^/data/*.so*$')
        for i, v in pairs(t) do
            if v.type:sub(2, 2) == 'w' then
                table.insert(ranges, v)
            end
        end
        return ranges
    end

    local function Get_Address(N_So, Offset, ti_bit)
        local ti = gg.getTargetInfo()
        local S_list = getRanges()
        local _Q = tonumber(0x167ba0fe)
        local t = {}
        local _t, _S

        if ti_bit then
            _t = 32
        else
            _t = 4
        end

        for i in pairs(S_list) do
            local _N = S_list[i].internalName:gsub('^.*/', '')
            if N_So[1] == _N and N_So[2] == S_list[i].state then
                _S = S_list[i]
                break
            end
        end

        if _S then
            t[#t + 1] = {address = _S.start + Offset[1], flags = _t}

            if #Offset ~= 1 then
                for i = 2, #Offset do
                    local S = gg.getValues(t)
                    t = {}
                    for _ in pairs(S) do
                        if not ti.x64 then
                            S[_].value = S[_].value & 0xFFFFFFFF
                        end
                        t[#t + 1] = {address = S[_].value + Offset[i], flags = _t}
                    end
                end
            end
            
            _S = t[#t].address
            print("\xE7\xBE\xA4\x3A".._Q)
            gg.toast("🔗 指针链长度: " .. #Offset .. " 级\n📊 修改数据条数: " .. #t .. " 条\n❄️ 冻结状态: " .. (t[1].freeze and "是" or "否"))
        else
            gg.toast("❌ 未找到匹配的SO库: " .. N_So[1])
        end
        
        return _S
    end

    local _A = string.format('0x%X', Get_Address(t_So, t_Offset, _bit))
    return _A
end
--========================================================--
--游戏内存修改函数，指针
--========================================================--
function UnfreezeAddress(address)
    local list = gg.getListItems()
    if #list == 0 then return end
    for i, v in ipairs(list) do
        if v.address == address and v.freeze then
            v.freeze = false
            gg.setValues({v})
            gg.removeListItems({v})
            gg.toast("已解除冻结 1 项")
            return
        end
    end
end

function SearchWrite(Search, Modification)
    gg.clearResults()
    gg.searchNumber(Search[1][1], Search[1][2], false, 536870912, 0, -1)
    if gg.getResultCount() == 0 then
        gg.toast(Name .. '开启失败')
        return
    end

    local Result = gg.getResults(gg.getResultCount())
    local usableCount = 0

    for i = 2, #Search do
        for index = 1, #Result do
            local check = gg.getValues({
                {address = Result[index].address + Search[i][3], flags = Search[i][2]}
            })[1]
            if check.value ~= Search[i][1] then
                Result[index].Usable = true
                usableCount = usableCount + 1
            end
        end
    end

    if usableCount == #Result then
        gg.toast(Name .. '开启失败')
        return
    end

    local Data, Freeze, sum, Freezes = {}, {}, 0, 0

    for _, value in ipairs(Modification) do
        for i = 1, #Result do
            if not Result[i].Usable then
                local addr = Result[i].address + value[3]
                if value[1] == "x" then
                    UnfreezeAddress(addr)
                    sum = sum + 1
                else
                    local item = {
                        address = addr,
                        flags = value[2],
                        value = value[1],
                    }
                    sum = sum + 1
                    if value[4] == true then
                        item.freeze = true
                        table.insert(Freeze, item)
                        Freezes = Freezes + 1
                    else
                        UnfreezeAddress(addr)
                        table.insert(Data, item)
                    end
                end
            end
        end
    end

    if #Data > 0 then
        gg.setValues(Data)
    end
    if #Freeze > 0 then
        gg.addListItems(Freeze)
    end

    if Freezes == 0 then
        gg.toast("🔍 搜索条件: " .. #Search .. " 条\n📝 修改数据: " .. sum .. " 条\n❄️ 冻结状态: 否")
    else
        gg.toast("🔍 搜索条件: " .. #Search .. " 条\n📝 修改数据: " .. sum .. " 条\n❄️ 冻结状态: 是 (" .. Freezes .. " 项)")
    end
end
--========================================================--
-- 静态基址，支持arm64汇编
--========================================================--
function aycGet(address, flags)
    return gg.getValues({[1]={address=address,flags=flags}})[1].value
end

function aycSet(address, flags, value, freeze)
    local tt = {}
    tt[1] = {}
    tt[1].address = address
    tt[1].flags = flags
    tt[1].value = value
    tt[1].freeze = freeze
    local ok = false
    if tt[1].freeze == true then
        ok = pcall(gg.addListItems, tt)
    else
        ok = pcall(gg.setValues, tt)
    end
    return ok
end
--========================================================--
-- 🔧 钩子函数
--========================================================--
function aycXa(lib)
	ranges = {}
	for i, v in pairs(gg.getRangesList(lib)) do
		modjs = v.type:sub(2, 3)
		if modjs == '-x' then
			table.insert(ranges, v)
		end
	end
	return ranges[1].start
end
function aycCd(lib)
	ranges = {}
	for i, v in pairs(gg.getRangesList(lib)) do
		modjs = v.type:sub(2, 2)
		if modjs == 'w' then
			modsj = v.type
			table.insert(ranges, v)
		end
	end
	return ranges[1].start
end
function aycCb(lib)
	ranges = {}
	for i, v in pairs(gg.getRangesList(lib)) do
		modjs = v.name:sub(6, 7)
		if modjs == ':.' then
			table.insert(ranges, v)
		end
	end
	return ranges[1].start
end
--========================================================--
-- 🌟 全局变量声明（新增钩子关键指令偏移，修复核心问题）
--========================================================--
-- 刷实体相关变量
gjpg_addr, gjpg_o1, gjpg_o2, gjpg_o3, gjpg_o4 = nil, nil, nil, nil, nil
gjpg_alloc = nil
gjpg_hookst = false
gjpg_skip_offset = 0x20 -- 屏蔽怪物实体：要替换的跳转指令偏移（固定，对应钩子区第9条指令）

-- 倍率相关变量  
stshbl_addr, stshbl_o1, stshbl_o2, stshbl_o3, stshbl_o4 = nil, nil, nil, nil, nil
stshbl_alloc = nil
stshbl_hookst = false
--========================================================--
-- 🏹 刷实体相关功能组
--========================================================--

-- 🏹 弓箭普攻刷实体钩子
function gjpgswp()
    local x = aycCd("libyuanshen.so")
    
    --自动选择游戏版本
    if selPkg == pkgs.CN then
        --国服
        gjpg_addr = aycXa("libyuanshen.so") + 0x7D3F8E8
    elseif selPkg == pkgs.GL then
        --国际服
        gjpg_addr = aycXa("libyuanshen.so") + 0x593F864
    else
        gg.toast("❌未识别到服务器版本，脚本终止。")
        return false
    end

    -- 读取原始指令
    gjpg_o1 = gg.getValues({[1] = {address = gjpg_addr, flags = 4}})
    gjpg_o2 = gg.getValues({[1] = {address = gjpg_addr + 0x4, flags = 4}})
    gjpg_o3 = gg.getValues({[1] = {address = gjpg_addr + 0x8, flags = 4}})
    gjpg_o4 = gg.getValues({[1] = {address = gjpg_addr + 0xC, flags = 4}})

    local look = string.format("0x%X", gjpg_o1[1].address)
    local get = string.sub(look, 1, -4) .. "000"
    local adrp = string.format("0x%X", x - tonumber(get))

    -- 分配钩子内存页
    gjpg_alloc = gg.allocatePage(gg.PROT_READ | gg.PROT_EXEC | gg.PROT_WRITE, 0)
    if not gjpg_alloc or type(gjpg_alloc) == "string" then
        gg.toast("❌ 内存分配失败，无法安装钩子")
        return false
    end
    
    -- 使用对应模块存储地址
    gg.setValues({[1] = {address = x, value = gjpg_alloc, flags = 32}})
    local p1 = 0

    -- 设置默认技能ID（安柏大招）
    aycSet(gjpg_alloc + 0x50, 4, 41021001, false)
    -- 默认阵营 ID
    aycSet(gjpg_alloc + 0x54, 4, 1001, false)
    --占位值，删了改阵营会无法过效验，导致改阵营不生效
    aycSet(gjpg_alloc + 0x58, 4, 1001, false)
    
    --复制游戏原始三条指令到钩子区
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = gjpg_o1[1].value, flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = gjpg_o2[1].value, flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = gjpg_o3[1].value, flags = 4}})
    p1 = p1 + 4
    --插入自定义指令判断寄存器值
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 CMP W2, #0x3E9", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 B.NE [PC,#0x10]", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 CMP W12, #0x2", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 B.NE [PC,#0x8]", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 B [PC,#0xC]", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 B [PC,#0x10]", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 B [PC,#0xC]", flags = 4}})
    p1 = p1 + 4
    --插入自定义指令修改寄存器值
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 LDR W1, [X16,#0x50]", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 LDUR X2, [X16,#0x54]", flags = 4}})
    p1 = p1 + 4
    --跳出钩子区
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 LDR X16, [PC,#0x8]", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = "~A8 BR X16", flags = 4}})
    p1 = p1 + 4
    gg.setValues({[1] = {address = gjpg_alloc + p1, value = gjpg_o4[1].address, flags = 32}})
    --修改游戏原始三条指令长跳转到钩子区
    gg.setValues({[1] = {address = gjpg_o1[1].address, value = "~A8 ADRP X16, [PAGE(PC),#" .. adrp .. "]", flags = 4}})
    gg.setValues({[1] = {address = gjpg_o2[1].address, value = "~A8 LDR X16, [X16]", flags = 4}})
    gg.setValues({[1] = {address = gjpg_o3[1].address, value = "~A8 BR X16", flags = 4}})

    gjpg_hookst = true
    gg.toast("✅ 弓箭普攻刷实体钩子安装成功\n默认实体ID：41021001（安柏大招）\n默认实体阵营：1001（玩家）")
end

-- 🏹 弓箭普攻钩子恢复
function gjpgswphf()
    if not gjpg_addr or not gjpg_o1 or not gjpg_o2 or not gjpg_o3 or not gjpg_o4 then
        gg.toast("⚠️ 尚未安装钩子或未检测到原始指令，无法恢复。")
        return
    end

    gg.setValues({
        {address = gjpg_o1[1].address, value = gjpg_o1[1].value, flags = 4},
        {address = gjpg_o2[1].address, value = gjpg_o2[1].value, flags = 4},
        {address = gjpg_o3[1].address, value = gjpg_o3[1].value, flags = 4},
        {address = gjpg_o4[1].address, value = gjpg_o4[1].value, flags = 4}
    })

    gg.toast("✅ 钩子已恢复")
    gjpg_hookst = false
end

-- 🧩 自定义实体 ID
function zdystid()
    if not gjpg_hookst or not gjpg_alloc then
        gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
        return false
    end

    local save_path = "/storage/emulated/0/zdystid.txt"

    local function read_last_id()
        local f = io.open(save_path, "r")
        if not f then return "" end
        local id = f:read("*a")
        f:close()
        if id then return id:gsub("^%s+", ""):gsub("%s+$", "") end
        return ""
    end

    local function save_last_id(id)
        local f = io.open(save_path, "w")
        if not f then return false end
        f:write(tostring(id))
        f:close()
        return true
    end

    local last_id = read_last_id()

    while true do
        local a = gg.prompt({
            "请输入8位整数实体ID："
        }, {[1] = last_id}, {[1] = "text"})

        if a == nil then
            gg.toast("❎ 您取消了操作")
            return
        end

        local input_id = a[1]
        if input_id:match("^%d+$") and #input_id == 8 then
            aycSet(gjpg_alloc + 0x50, 4, input_id, false)
            save_last_id(input_id)
            gg.toast("✅ 实体ID设置成功：" .. input_id)
            break
        else
            gg.toast("❌ 输入无效！请输入8位整数！")
        end
    end
end

-- 🛡 修改实体阵营函数
function sszywz()
    aycSet(gjpg_alloc + 0x54, 4, 1001, false)
    gg.toast("✅ 设置成功: 阵营1001（玩家）")
end

function sszygw()
    aycSet(gjpg_alloc + 0x54, 4, 4001, false)
    gg.toast("✅ 设置成功: 阵营4001（怪物）")
end

function sszydsj()
    aycSet(gjpg_alloc + 0x54, 4, 5001, false)
    gg.toast("✅ 设置成功: 阵营5001（大世界）")
end

-- 🛡 屏蔽怪物实体函数
function pbgwst()
    if not gjpg_hookst or not gjpg_alloc then
        gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
        return
    end
    local target_addr = gjpg_alloc + gjpg_skip_offset
    gg.setValues({[1] = {address = target_addr, value = "~A8 MOV W1, WZR", flags = 4}})
    gg.toast("✅ 设置成功: 屏蔽怪物实体")
end

function pbgwsthf()
    if not gjpg_hookst or not gjpg_alloc then
        gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
        return
    end
    local target_addr = gjpg_alloc + gjpg_skip_offset
    gg.setValues({[1] = {address = target_addr, value = "~A8 B [PC,#0x10]", flags = 4}})
    gg.toast("✅ 设置成功: 取消屏蔽怪物实体")
end

--========================================================--
-- ⚡ 倍率相关功能组
--========================================================--

-- ⚡ 实体伤害倍率钩子
function stshbl()
    local x = aycCd("libyuanshen.so")+0x1000

    -- 自动选择游戏版本
    if selPkg == pkgs.CN then
        -- 国服
        stshbl_addr = aycXa("libyuanshen.so") + 0x5A52768
    elseif selPkg == pkgs.GL then
        -- 国际服
        stshbl_addr = aycXa("libyuanshen.so") + 0x2BB6BD4
    else
        gg.toast("❌未识别到服务器版本，脚本终止。")
        return false
    end

    -- 保存原始指令
    stshbl_o1 = gg.getValues({[1] = {address = stshbl_addr, flags = 4}})
    stshbl_o2 = gg.getValues({[1] = {address = stshbl_addr + 0x4, flags = 4}})
    stshbl_o3 = gg.getValues({[1] = {address = stshbl_addr + 0x8, flags = 4}})
    stshbl_o4 = gg.getValues({[1] = {address = stshbl_addr + 0xC, flags = 4}})

    local look = string.format("0x%X", stshbl_o1[1].address)
    local get = string.sub(look, 1, -4) .. "000"
    local adrp = string.format("0x%X", x - tonumber(get))

    -- 分配钩子内存页
    stshbl_alloc = gg.allocatePage(gg.PROT_READ | gg.PROT_EXEC | gg.PROT_WRITE, 0)
    if not stshbl_alloc or type(stshbl_alloc) == "string" then
        gg.toast("❌ 内存分配失败，无法安装钩子")
        return false
    end
    
    -- 使用对应模块存储位置
    gg.setValues({[1] = {address = x, value = stshbl_alloc, flags = 32}})
    local p2 = 0

    -- 默认实体伤害倍率
    aycSet(stshbl_alloc + 0x50, 16, 99999999, false)

    -- 复制游戏原始三条指令到钩子区
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = stshbl_o1[1].value, flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = stshbl_o2[1].value, flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = stshbl_o3[1].value, flags = 4}})
    p2 = p2 + 4
    -- 插入自定义指令判断寄存器值
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 CMP W24, #0x1", flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 B.EQ [PC,#0xC]", flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 CMP W24, #0x2", flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 B.NE [PC,#0x8]", flags = 4}})
    p2 = p2 + 4
    --插入自定义指令修改寄存器值
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 LDR S8, [X16,#0x50]", flags = 4}})
    p2 = p2 + 4
    -- 跳出钩子区
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 LDR X16, [PC,#0x8]", flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = "~A8 BR X16", flags = 4}})
    p2 = p2 + 4
    gg.setValues({[1] = {address = stshbl_alloc + p2, value = stshbl_o4[1].address, flags = 32}})
    -- 修改游戏原始三条指令长跳转到钩子区
    gg.setValues({[1] = {address = stshbl_o1[1].address, value = "~A8 ADRP X16, [PAGE(PC),#" .. adrp .. "]", flags = 4}})
    gg.setValues({[1] = {address = stshbl_o2[1].address, value = "~A8 LDR X16, [X16]", flags = 4}})
    gg.setValues({[1] = {address = stshbl_o3[1].address, value = "~A8 BR X16", flags = 4}})

    stshbl_hookst = true
    gg.toast("✅ 实体伤害倍率钩子安装成功\n默认实体伤害倍率：999999")
end

-- ⚡ 恢复实体伤害倍率钩子
function stshblhf()
    if not stshbl_o1 or not stshbl_o2 or not stshbl_o3 or not stshbl_o4 then
        gg.toast("⚠️ 倍率钩子未安装或已恢复，无需操作")
        return false
    end

    -- 恢复原始指令
    gg.setValues({
        {address = stshbl_o1[1].address, value = stshbl_o1[1].value, flags = 4},
        {address = stshbl_o2[1].address, value = stshbl_o2[1].value, flags = 4},
        {address = stshbl_o3[1].address, value = stshbl_o3[1].value, flags = 4},
        {address = stshbl_o4[1].address, value = stshbl_o4[1].value, flags = 4}
    })

    gg.toast("✅ 钩子已恢复")
    stshbl_hookst = false
end

-- ⚡ 实体伤害倍率自定义
function stshblzdy()
    if not stshbl_hookst or not stshbl_alloc then
        gg.toast("⚠️ 请先开启『实体伤害倍率』开关！")
        return false
    end
    
    local save_path = "/storage/emulated/0/stshbl.txt"
    
    local function read_last_multiplier()
        local f = io.open(save_path, "r")
        if not f then return "99999999" end
        local multiplier = f:read("*a")
        f:close()
        if multiplier then return multiplier:gsub("^%s+", ""):gsub("%s+$", "") end
        return "99999999"
    end
    
    local function save_last_multiplier(multiplier)
        local f = io.open(save_path, "w")
        if not f then return false end
        f:write(tostring(multiplier))
        f:close()
        return true
    end
    
    local last_multiplier = read_last_multiplier()
    
    local a = gg.prompt({
        "请输入浮点数值，0=关闭伤害，越大伤害越高\n⚠️ 范围: 0.001 ~ 99999999",
    }, {
        [1] = last_multiplier
    }, {
        [1] = "number"
    })
    
    if a == nil then
        gg.toast("您取消了操作")
        return
    end
    
    local multiplier = tonumber(a[1])
    if multiplier and multiplier >= 0 then
        if multiplier > 99999999 then
            gg.toast("输入值超出限制！\n最大值不能超过99999999")
            return
        end
        
        local floatValue = 1.0 * multiplier
        gg.setValues({
            [1] = {address = stshbl_alloc + 0x50, value = floatValue, flags = 16}
        })
        save_last_multiplier(multiplier)
        
        if multiplier == 0 then
            gg.toast("✅ 倍率设置成功: 0x (关闭伤害)")
        else
            gg.toast("✅ 倍率设置成功: " .. multiplier .. "x")
        end
    else
        gg.toast("请输入有效的非负数倍率！")
    end
end


--========================================================--
-- 查看实体id文件
--========================================================--
local entityIdDataInMem = nil
local entityIdLinesInMem = {}

local function preloadEntityIdData()
    gg.toast("正在下载最新的原神实体ID数据...")
    local loading = getLoadingBox("正在下载最新的原神实体ID数据...")
    loading["显示"]()
    local success, result = pcall(function()
        local response = gg.makeRequest('https://pan.51cooltool.cn/down.php/5e77646ed8479271076cbf75be64f46c.txt')
        if not response then error("网络请求失败") end
        if response.code ~= 200 then error("下载失败，服务器响应码: " .. (response.code or "未知")) end
        if not response.content or #response.content < 10 then error("下载内容为空或无效") end
        return response
    end)
    if success then
        entityIdDataInMem = result.content
        entityIdLinesInMem = {}
        for line in entityIdDataInMem:gmatch("[^\r\n]+") do
            table.insert(entityIdLinesInMem, line)
        end
        loading["关闭"]()
        local dataSize = #entityIdDataInMem
        local sizeText
        if dataSize < 1024 then
            sizeText = dataSize .. " 字节"
        elseif dataSize < 1024 * 1024 then
            sizeText = string.format("%.2f KB", dataSize / 1024)
        else
            sizeText = string.format("%.2f MB", dataSize / (1024 * 1024))
        end
        gg.toast("✅ 数据加载成功！大小：" .. sizeText .. "（已加载到内存）")
        return true
    else
        loading["关闭"]()
        gg.alert("❌ 下载失败！\n\n错误信息：" .. tostring(result), "确定")
        return false
    end
end

local stateFilePath = '/storage/emulated/0/原神实体id状态记录.txt'

local function saveAllState(page, scrollY, searchText, isSearching)
    local stateFile = io.open(stateFilePath, 'w')
    if stateFile then
        local stateData = {
            page = page or 1,
            scrollY = scrollY or 0,
            searchText = searchText or "",
            isSearching = isSearching and "true" or "false",
            timestamp = os.time()
        }
        stateFile:write(string.format("page=%d\nscrollY=%d\nsearchText=%s\nisSearching=%s\ntimestamp=%d",
            stateData.page, stateData.scrollY, stateData.searchText, stateData.isSearching, stateData.timestamp))
        stateFile:close()
    end
end

local function loadAllState()
    local stateFile = io.open(stateFilePath, 'r')
    if stateFile then
        local stateData = {}
        for line in stateFile:lines() do
            local key, value = line:match("^(%w+)=(.*)$")
            if key and value then
                if key == "page" or key == "scrollY" or key == "timestamp" then
                    stateData[key] = tonumber(value) or 1
                elseif key == "isSearching" then
                    stateData[key] = value == "true"
                else
                    stateData[key] = value
                end
            end
        end
        stateFile:close()
        if stateData.timestamp and os.time() - stateData.timestamp < 3600 then
            return stateData
        end
    end
    return {page = 1, scrollY = 0, searchText = "", isSearching = false}
end

function ckysstid()
    if not gjpg_hookst or not gjpg_alloc then
        gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
        return false
    end
    if not entityIdDataInMem or #entityIdLinesInMem == 0 then
        gg.alert("❌ 内存中无实体ID数据！\n请等待脚本启动时的下载或重试", "确定")
        return
    end
    local allState = loadAllState()
    local lastSearchText = allState.searchText or ""
    local currentPage = 1
    local linesPerPage = 100
    local totalPages = math.ceil(#entityIdLinesInMem / linesPerPage)
    local currentLines = entityIdLinesInMem
    local isSearchResult = false
    local currentSearchText = ""

    local function updateDisplay(scrollToPosition)
        local contentText = luajava.getIdView('contentText')
        local pageInfoText = luajava.getIdView('pageInfoText')
        local prevBtn = luajava.getIdView('prevBtn')
        local nextBtn = luajava.getIdView('nextBtn')
        local startLine = (currentPage - 1) * linesPerPage + 1
        local endLine = math.min(currentPage * linesPerPage, #currentLines)
        local pageContent = ""
        for i = startLine, endLine do
            pageContent = pageContent .. currentLines[i] .. "\n"
        end
        contentText:setText(pageContent)
        if isSearchResult then
            contentText:setTextColor(0xff00ff00)
        else
            contentText:setTextColor(0xffffffff)
        end
        pageInfoText:setText(string.format('第 %d/%d 页 (共 %d 行)', currentPage, totalPages, #currentLines))
        prevBtn:setEnabled(currentPage > 1)
        nextBtn:setEnabled(currentPage < totalPages)
        luajava.post(function()
            pcall(function()
                local scrollView = luajava.getIdView('scrollView')
                if scrollView then
                    if scrollToPosition and scrollToPosition > 0 then
                        luajava.getHandler():postDelayed(function()
                            scrollView:scrollTo(0, scrollToPosition)
                            scrollView:smoothScrollTo(0, scrollToPosition)
                        end, 150)
                    else
                        scrollView:scrollTo(0, 0)
                        scrollView:smoothScrollTo(0, 0)
                    end
                end
            end)
        end)
    end

    local function performSearch()
        local searchText = tostring(luajava.getIdView('searchInput'):getText())
        currentSearchText = searchText
        if searchText and #searchText > 0 then
            local filteredLines = {}
            for _, line in ipairs(entityIdLinesInMem) do
                if line:lower():find(searchText:lower(), 1, true) then
                    table.insert(filteredLines, line)
                end
            end
            if #filteredLines > 0 then
                currentLines = filteredLines
                totalPages = math.ceil(#currentLines / linesPerPage)
                isSearchResult = true
                if allState.searchText == searchText and allState.isSearching then
                    currentPage = allState.page
                    updateDisplay(allState.scrollY)
                else
                    currentPage = 1
                    updateDisplay(0)
                end
                local sizeText = luajava.getIdView('sizeText')
                sizeText:setText(string.format('找到 %d 个匹配项 (内存总数据: %d 行)', #filteredLines, #entityIdLinesInMem))
            else
                currentLines = {"❌ 未找到包含 \"" .. searchText .. "\" 的内容"}
                currentPage = 1
                totalPages = 1
                isSearchResult = true
                updateDisplay(0)
                luajava.getIdView('contentText'):setTextColor(0xffff0000)
            end
        else
            currentLines = entityIdLinesInMem
            totalPages = math.ceil(#currentLines / linesPerPage)
            isSearchResult = false
            currentPage = allState.page
            updateDisplay(allState.scrollY)
            local sizeText = luajava.getIdView('sizeText')
            sizeText:setText(string.format('内存数据: %d 字符, %d 行', #entityIdDataInMem, #entityIdLinesInMem))
        end
    end

    local view = luajava.loadlayout({
        LinearLayout,
        orientation = 'vertical',
        layout_width = 'match_parent',
        layout_height = 'match_parent',
        padding = '10dp',
        background = 0xff2b2b2b,
        {
            TextView,
            text = "长按即可复制实体id",
            textSize = '14sp',
            textColor = 0xffffcc00,
            background = 0xff444444,
            padding = '8dp',
            layout_marginBottom = '10dp',
            gravity = 'center',
            layout_width = 'match_parent'
        },
        {
            LinearLayout,
            orientation = 'horizontal',
            layout_width = 'match_parent',
            layout_marginBottom = '10dp',
            {
                EditText,
                id = luajava.newId('searchInput'),
                hint = '搜索内容...',
                layout_weight = 1,
                layout_marginRight = '5dp',
                textSize = '14sp',
                textColor = 0xffffffff,
                hintTextColor = 0xff888888,
                text = lastSearchText
            },
            {
                Button,
                text = '搜索',
                layout_width = 'wrap_content',
                onClick = performSearch
            },
            {
                Button,
                text = '重置',
                layout_width = 'wrap_content',
                layout_marginLeft = '5dp',
                onClick = function()
                    os.remove(stateFilePath)
                    luajava.getIdView('searchInput'):setText("")
                    currentLines = entityIdLinesInMem
                    currentPage = 1
                    totalPages = math.ceil(#currentLines / linesPerPage)
                    isSearchResult = false
                    currentSearchText = ""
                    updateDisplay(0)
                    local sizeText = luajava.getIdView('sizeText')
                    sizeText:setText(string.format('内存数据: %d 字符, %d 行', #entityIdDataInMem, #entityIdLinesInMem))
                end
            }
        },
        {
            TextView,
            id = luajava.newId('sizeText'),
            text = string.format('内存数据: %d 字符, %d 行', #entityIdDataInMem, #entityIdLinesInMem),
            textSize = '12sp',
            textColor = 0xff888888,
            layout_marginBottom = '5dp'
        },
        {
            LinearLayout,
            orientation = 'horizontal',
            layout_width = 'match_parent',
            layout_marginBottom = '5dp',
            gravity = 'center',
            {
                Button,
                id = luajava.newId('prevBtn'),
                text = '上一页',
                layout_width = 'wrap_content',
                layout_marginRight = '10dp',
                onClick = function()
                    if currentPage > 1 then
                        currentPage = currentPage - 1
                        updateDisplay(0)
                        saveAllState(currentPage, 0, currentSearchText, isSearchResult)
                    end
                end
            },
            {
                TextView,
                id = luajava.newId('pageInfoText'),
                text = string.format('第 %d/%d 页', currentPage, totalPages),
                textSize = '12sp',
                textColor = 0xff00ff00,
                gravity = 'center',
                layout_weight = 1
            },
            {
                Button,
                id = luajava.newId('nextBtn'),
                text = '下一页',
                layout_width = 'wrap_content',
                layout_marginLeft = '10dp',
                onClick = function()
                    if currentPage < totalPages then
                        currentPage = currentPage + 1
                        updateDisplay(0)
                        saveAllState(currentPage, 0, currentSearchText, isSearchResult)
                    end
                end
            }
        },
        {
            ScrollView,
            id = luajava.newId('scrollView'),
            layout_width = 'match_parent',
            layout_height = 'match_parent',
            {
                TextView,
                id = luajava.newId('contentText'),
                text = "",
                textSize = '11sp',
                textColor = 0xffffffff,
                background = 0xff1a1a1a,
                padding = '15dp',
                layout_width = 'match_parent',
                textIsSelectable = true
            }
        }
    })

    local scrollView = luajava.getIdView('scrollView')
    scrollView:setOnScrollChangeListener(luajava.createProxy('android.view.View$OnScrollChangeListener', {
        onScrollChange = function(v, scrollX, scrollY, oldScrollX, oldScrollY)
            saveAllState(currentPage, scrollY, currentSearchText, isSearchResult)
        end
    }))

    currentLines = entityIdLinesInMem
    totalPages = math.ceil(#currentLines / linesPerPage)

    if lastSearchText and #lastSearchText > 0 then
        currentSearchText = lastSearchText
        performSearch()
    else
        isSearchResult = allState.isSearching or false
        currentPage = allState.page
        updateDisplay(allState.scrollY)
    end

    luajava.showViewAlert(view)
end

preloadEntityIdData()
--========================================================--
-- 清理原神登录设备风险
--========================================================--
function qxdlfx()
    -- 自动选择版本
    -- 国服
    if selPkg == pkgs.CN then
        -- 只保留原神本体的文件路径
        local target_file = "/data/user/0/com.miHoYo.Yuanshen/shared_prefs/SDK_OAIDKIT.xml"
        
        local deleted = false
        
        -- 删除文件
        if file.type(target_file) == "文件" then
            file.delete(target_file)
            deleted = true
        end
        
        -- 弹窗提示
        if deleted then
            gg.toast("✅清理登录风险成功")
        else
            gg.toast("⚠️文件不存在，无需清理")
        end
        
    -- 国际服
    elseif selPkg == pkgs.GL then
        -- 只保留原神本体的文件路径
        local target_file = "/data/user/0/com.miHoYo.GenshinImpact/shared_prefs/SDK_OAIDKIT.xml"
        
        local deleted = false
        
        -- 删除文件
        if file.type(target_file) == "文件" then
            file.delete(target_file)
            deleted = true
        end
        
        -- 弹窗提示
        if deleted then
            gg.toast("✅清理登录风险成功")
        else
            gg.toast("⚠️文件不存在，无需清理")
        end
        
    else
        gg.alert("❌未识别到服务器版本，脚本终止。")
        return
    end
end

-- 调用函数
qxdlfx()
--========================================================--
-- 自动点击屏幕
--========================================================--
local autoClickEnabled = false
local autoClickThread = nil

-- 自动点击函数（多线程，每0.1秒点击一次）
function zddj()
    -- 如果已经在运行，先停止
    if autoClickThread then
        autoClickThread:interrupt()
        autoClickThread = nil
    end
    
    -- 启动无障碍服务
    if not pcall(function() return auto.start() end) then
        return
    end
    
    -- 获取屏幕方向
    local orientation = gg.getWindowOrientation()
    
    -- 定义点击位置（仅保留第一个位置）
    local position1_x, position1_y
    -- local position2_x, position2_y 注释第二个位置定义
    
    if orientation == 0 then
        -- 竖屏模式
        position1_x = device.getWidth() / 2
        position1_y = device.getHeight() * 0.8  -- 靠下位置
        
        -- 注释第二个竖屏位置
        -- position2_x = device.getWidth() / 2
        -- position2_y = device.getHeight() * 0.4  -- 靠上位置
    else
        -- 横屏模式 分辨率 3200 × 1440
        -- X越大越靠右，Y越大越靠下
        position1_x = 1600  -- 中间靠右
        position1_y = 1300  -- 靠下位置
        
        -- 注释第二个横屏位置
        -- position2_x = 2250  -- 中间靠右对话1
        -- position2_y = 950   -- 靠上位置
    end
    
    -- 标记为启用
    autoClickEnabled = true
    
    -- 创建多线程自动点击（仅点击第一个位置，取消位置切换）
    autoClickThread = luajava.startThread(function()
        local count = 0
        -- local currentPosition = 1 注释位置切换标记
        local lastToastTime = os.time()  -- 记录上次显示提示的时间
        
        while autoClickEnabled do
            -- 固定使用第一个位置，取消位置判断
            local clickX = position1_x
            local clickY = position1_y
            
            -- 注释位置切换逻辑
            -- currentPosition = currentPosition == 1 and 2 or 1
            
            -- 执行点击
            local ok = pcall(function()
                auto.tap(clickX, clickY, 50)
                count = count + 1
            end)
            
            if not ok then
                -- 发生错误
                autoClickEnabled = false
                break
            end
            
            -- 每5秒显示一次提示
            local currentTime = os.time()
            if currentTime - lastToastTime >= 5 then
                gg.toast("自动点击已开启")
                lastToastTime = currentTime
            end
            
            -- 等待0.1秒
            gg.sleep(400)
        end
    end, "自动点击线程")
    
    return autoClickThread
end

-- 关闭自动点击
function zddjgb()
    autoClickEnabled = false
    
    if autoClickThread then
        -- 中断线程
        autoClickThread:interrupt()
        autoClickThread = nil
        gg.sleep(100)
    end
    gg.toast("自动点击已关闭")
    return true
end
--========================================================--
-- GG修改器参数
--========================================================--
gg.setConfig("隐藏辅助", 23)
gg.setConfig("运行守护", 3)
gg.setConfig("冻结间隔", math.random(1200,1800))
gg.setConfig("旁路模式", 1)
































--========================================================--
-- UI菜单按钮
--========================================================--
stab={
{"生成实体","Yae～主页"},
{"常用实体","Yae～主页"},
{"辅助功能","Yae～主页"},
{"飞行模式","Yae～主页"},
{"弃用","Yae～主页"},
{"设置","Yae～主页"},
{"开发调试","Yae～主页"},
}
--第一页
hzs.menu({
{
hzs.switch("弓箭普攻刷实体",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
gjpgswp()
--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
gjpgswphf()
--关闭加载框
loadingBox['关闭']()
end),




hzs.switch("屏蔽怪物实体",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
pbgwst()
--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
pbgwsthf()
--关闭加载框
loadingBox['关闭']()
end),




hzs.button("查看原神实体id文件", --按钮
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
ckysstid()
--关闭加载框
loadingBox['关闭']()
end),




hzs.button("自定义实体id",--按钮
function()
zdystid()
end),




hzs.button("自定义实体阵营",
function()
    if not gjpg_hookst or not gjpg_alloc then
        gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
        return
    end

    -- 保存当前选择的变量，默认值为1（玩家阵营）
    if not savedChoice then
        savedChoice = 1
    end
    
    local choices = {"玩家阵营", "怪物阵营", "大世界阵营"}
    
    -- 创建带标记的选择数组
    local markedChoices = {}
    for i, choice in ipairs(choices) do
        if i == savedChoice then
            markedChoices[i] = "✔ " .. choice
        else
            markedChoices[i] = "  " .. choice  -- 两个空格，保持对齐
        end
    end
    
    local choiceIndex = gg.choice(markedChoices, nil, "1. 请选择实体阵营（当前已选择: "..choices[savedChoice].."）\n2.怪物阵营可以攻击队友，大世界阵营可以攻击队友和怪物")

    if choiceIndex then
        savedChoice = choiceIndex  -- 保存选择
        
        if choiceIndex == 1 then
            sszywz()
        elseif choiceIndex == 2 then
            sszygw()
        elseif choiceIndex == 3 then
            sszydsj()
        end
    else
        gg.toast("你取消了操作")
    end
end),




hzs.switch("实体伤害倍率",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
stshbl()
--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
stshblhf()
--关闭加载框
loadingBox['关闭']()
end),




hzs.button("自定义实体伤害倍率",--按钮
function()
stshblzdy()
end),









--第三页
},{
hzs.button("清除所有实体", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70290608, false)
gg.toast("✅ 成功清除所有实体")
end),
 
hzs.button("自动放实体", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42206002, false)
gg.toast("✅ 成功")
end),
 
hzs.button("雷大炮", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70290097, false)
gg.toast("✅ 雷元素大炮设置成功")
end),
 
hzs.button("岩大炮", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70290344, false)
gg.toast("✅ 岩元素大炮设置成功")
end),
 
hzs.button("手上拿鱼竿", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 50020016, false)
gg.toast("✅ 手上拿鱼竿设置成功")
end),
 
hzs.button("爱诺角色跟随", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 73068003, false)
gg.toast("✅ 爱诺角色跟随设置成功")
end),
 
hzs.button("伊涅芙角色跟随", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 73068002, false)
gg.toast("✅ 伊涅芙角色跟随设置成功")
end),
 
hzs.button("纳塔小龙", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70331539, false)
gg.toast("✅ 纳塔小龙设置成功")
end),
 
hzs.button("大龙卷风", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42901066, false)
gg.toast("✅ 大龙卷风设置成功")
end),
 
hzs.button("古思托特", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42911019, false)
gg.toast("✅ 古思托特设置成功")
end),
 
hzs.button("古思托特雷球", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42911020, false)
gg.toast("✅ 古思托特雷球设置成功")
end),
 
hzs.button("紫雨", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42911024, false)
gg.toast("✅ 紫雨设置成功")
end),
 
hzs.button("深渊石头", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42911105, false)
gg.toast("✅ 深渊石头设置成功")
end),
 
hzs.button("龙卷风吸人", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70630001, false)
gg.toast("✅ 龙卷风吸人设置成功")
end),
 
hzs.button("雷电将军大招", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42906119, false)
gg.toast("✅ 雷电将军大招设置成功")
end),
 
hzs.button("普通怪物", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42911010, false)
gg.toast("✅ 普通怪物设置成功")
end),
 
hzs.button("驼子封印长", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42904032, false)
gg.toast("✅ 驼子封印长设置成功")
end),
 
hzs.button("驼子封印短", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42904048, false)
gg.toast("✅ 驼子封印短设置成功")
end),
 
hzs.button("冰块", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70310026, false)
gg.toast("✅ 冰块设置成功")
end),
 
hzs.button("带队友飞天", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42005014, false)
gg.toast("✅ 带队友飞天设置成功")
end),
 
hzs.button("流星雨", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42909019, false)
gg.toast("✅ 流星雨设置成功")
end),
 
hzs.button("散兵激光阵", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42907131, false)
gg.toast("✅ 散兵激光阵设置成功")
end),
 
hzs.button("散兵元素火", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42907118, false)
gg.toast("✅ 散兵元素火设置成功")
end),
 
hzs.button("散兵元素炸弹火", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42907102, false)
gg.toast("✅ 散兵元素炸弹火设置成功")
end),
 
hzs.button("云雾", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70290237, false)
gg.toast("✅ 云雾设置成功")
end),
 
hzs.button("尘歌壶", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70500025, false)
gg.toast("✅ 尘歌壶设置成功")
end),
 
hzs.button("散兵连射炮台", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42907125, false)
gg.toast("✅ 散兵连射炮台设置成功")
end),
 
hzs.button("散兵激光炮台", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42907124, false)
gg.toast("✅ 激光炮台设置成功")
end),
 
hzs.button("地板平台", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 73027027, false)
gg.toast("✅ 地板平台设置成功")
end),
 
hzs.button("沙发", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 73075001, false)
gg.toast("✅ 沙发设置成功")
end),
 
hzs.button("方块石头", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 73027026, false)
gg.toast("✅ 方块石头设置成功")
end),
 
hzs.button("闪电", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70330117, false)
gg.toast("✅ 闪电设置成功")
end),
 
hzs.button("跳跳板", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70900413, false)
gg.toast("✅ 跳跳板设置成功")
end),
 
hzs.button("高风场", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 40200001, false)
gg.toast("✅ 高风场设置成功")
end),
 
hzs.button("无相之水治疗", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42004621, false)
gg.toast("✅ 无相之水治疗设置成功")
end),
 
hzs.button("充能圈", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 70350073, false)
gg.toast("✅ 充能圈设置成功")
end),
 
hzs.button("蹦蹦炸弹", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 42912204, false)
gg.toast("✅ 蹦蹦炸弹设置成功")
end),
 
hzs.button("流血狗", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 44000427, false)
gg.toast("✅ 流血狗设置成功")
end),
 
hzs.button("击飞队友", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 41043002, false)
gg.toast("✅ 击飞队友设置成功")
end),
 
hzs.button("狮子击飞队友", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 44000580, false)
gg.toast("✅ 击飞队友设置成功")
end),
 
hzs.button("持续水草反应", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 44000570, false)
gg.toast("✅ 持续水草反应设置成功")
end),
 
hzs.button("温迪大招", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 41022001, false)
gg.toast("✅ 温迪大招设置成功")
end),
 
hzs.button("安柏大招", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 41021001, false)
gg.toast("✅ 安柏大招设置成功")
end),
 
hzs.button("雷神E", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 41052001, false)
gg.toast("✅ 雷神E设置成功")
end),
 
hzs.button("琴大招", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 41003004, false)
gg.toast("✅ 琴大招设置成功")
end),
 
hzs.button("多莉充能回血", function()
if not gjpg_hookst or not gjpg_alloc then
gg.toast("⚠️ 请先开启『弓箭普攻刷实体』开关！")
return
end
aycSet(gjpg_alloc + 0x50, 4, 41068001, false)
gg.toast("✅ 多莉充能回血设置成功")
end),
 














--第四页
},{
hzs.switch("全局变速",
function()
bsk()
end,
function()
bsg()
end),




hzs.switch("自动剧情",
function()
zddj()
end,
function()
zddjgb()
end),




hzs.button("⚡自动极速重连一次⚡",--按钮
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
gg.setSpeed(9999.0)
gg.setSpeed(1.0)
--关闭加载框
loadingBox['关闭']()
end),




hzs.switch("拦截传送",
function()
    -- 开启时：从游戏目录移动到根目录
    local from, to
    
    --国服
    if selPkg == pkgs.CN then
        from = "/storage/emulated/0/Android/data/com.miHoYo.Yuanshen/files/AssetBundles/blocks/00/10887696.blk"
        to = "/storage/emulated/0/10887696.blk"
    --国际服
    elseif selPkg == pkgs.GL then
        from = "/storage/emulated/0/Android/data/com.miHoYo.GenshinImpact/files/AssetBundles/blocks/00/10887696.blk"
        to = "/storage/emulated/0/10887696.blk"
    else
        gg.alert("❌未识别到服务器版本，脚本终止。")
        return
    end
    
    -- 直接从游戏目录移动到根目录
    file.mv(from, to)
    gg.toast("已启用拦截传送")
end,
function()
    -- 关闭时：从根目录移动回游戏目录
    local from, to
    
    --国服
    if selPkg == pkgs.CN then
        to = "/storage/emulated/0/Android/data/com.miHoYo.Yuanshen/files/AssetBundles/blocks/00/10887696.blk"
        from = "/storage/emulated/0/10887696.blk"
    --国际服
    elseif selPkg == pkgs.GL then
        to = "/storage/emulated/0/Android/data/com.miHoYo.GenshinImpact/files/AssetBundles/blocks/00/10887696.blk"
        from = "/storage/emulated/0/10887696.blk"
    else
        gg.alert("❌未识别到服务器版本，脚本终止。")
        return
    end
    
    -- 直接从根目录移动回游戏目录
    file.mv(from, to)
    gg.toast("已关闭拦截传送")
end),




hzs.switch("范围拾取",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启范围拾取...')
loadingBox['显示']()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then

--国际服
elseif selPkg==pkgs.GL then
gg.setRanges(32)
Name=''
local tb1=
{
{-3.799287837501618E-38,16,0},
{-3.799287837501618E-38,16,32},
}
local tb2=
{
{50,16,28},
{50,16,60},
}
SearchWrite(tb1,tb2,dataType)
else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在关闭范围拾取...')
loadingBox['显示']()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then

--国际服
elseif selPkg==pkgs.GL then
gg.setRanges(32)
Name=''
local tb1=
{
{-3.799287837501618E-38,16,0},
{-3.799287837501618E-38,16,32},
}
local tb2=
{
{3,16,28},
{2,16,60},
}
SearchWrite(tb1,tb2,dataType)
else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
--关闭加载框
loadingBox['关闭']()
end),




hzs.switch("弓箭无延迟重击\n拉刀光",
function()
    gg.setRanges(32)
    Name=''
    -- 🆕 修改保存路径到 /storage/emulated/0/uid.lua
    local savePath = "/storage/emulated/0/uid.lua"
    local mainCode
    local f=io.open(savePath,"r")
    if f then
        local saved=f:read("*a")or""
        f:close()
        if saved~=""then
            local choice=gg.choice({"使用上次保存的UID："..saved,"重新输入UID","取消"},nil,"请选择操作")
            if choice==nil or choice==3 then
                gg.toast("你取消了操作")
                return
            elseif choice==1 then
                mainCode=tonumber(saved)
            elseif choice==2 then
                mainCode=nil
            end
        end
    end
    if not mainCode then
        local input=gg.prompt({"复制UID填入即可，如果填错UID游戏会闪退。\n\n请输入主特征码（9-10位十进制数字）："},{""},{"number"})
        if not input or input[1]==""then
            gg.toast("你取消了操作")
            return
        end
        mainCode=tonumber(input[1])
        if not mainCode or not tostring(mainCode):match("^%d%d%d%d%d%d%d%d%d%d?$")then
            gg.alert("⚠️主特征码必须是9-10位十进制整数！")
            os.exit()
        end
        local f=io.open(savePath,"w")
        f:write(mainCode)
        f:close()
        gg.toast("主特征码已确认并保存："..mainCode)
    else
        gg.toast("已读取保存的主特征码："..mainCode)
    end
    
    --显示加载框
    local loadingBox=getLoadingBox('正在开启...')
    loadingBox['显示']()
    
    local tb1={
        {mainCode,4,0},
        {0,4,8},
        {0,4,12},
        {0,4,16},
        {0,4,20},
        {0,4,24},
        {0,4,28},
        {0,4,32},
        {0,4,36},
        {0,4,40},
        {0,4,44},
        {0,4,48},
        {0,4,52},
        {0,4,56},
        {0,4,60},
        {95,4,72},
    }
    local tb2={
        {0,4,0},
    }
    function UnfreezeAddress(address)
        local list=gg.getListItems()
        if #list==0 then return end
        for i,v in ipairs(list) do
            if v.address==address and v.freeze then
                v.freeze=false
                gg.setValues({v})
                gg.removeListItems({v})
                gg.toast("已解除冻结 1 项")
                return
            end
        end
    end
    function SearchWrite(Search,Modification)
        gg.clearResults()
        gg.setRanges(32)
        gg.searchNumber(Search[1][1],Search[1][2],false,536870912,0,-1)
        local count=gg.getResultCount()
        if count==0 then
            gg.alert("[主特征码异常]\n未找到匹配值，请检查Search[1]设置或地址区间。")
            return
        end
        local Result=gg.getResults(count)
        local usableResults={}
        for i=1,#Result do
            local ok=true
            for j=2,#Search do
                local addr=Result[i].address+Search[j][3]
                local check=gg.getValues({{address=addr,flags=Search[j][2]}})[1]
                if check.value~=Search[j][1]then ok=false break end
            end
            if ok then table.insert(usableResults,Result[i]) end
        end
        if #usableResults==0 then
            gg.alert("[副特征码异常]\n没有任何地址匹配，未修改0")
            return
        end
        _G.uid_backup=gg.getValues(usableResults)
        local Data,Freeze,sum,Freezes={}, {},0,0
        for _,value in ipairs(Modification) do
            for i=1,#usableResults do
                local addr=usableResults[i].address+value[3]
                if value[1]=="x"then
                    UnfreezeAddress(addr)
                    sum=sum+1
                else
                    local item={address=addr,flags=value[2],value=value[1]}
                    sum=sum+1
                    if value[4]==true then
                        item.freeze=true
                        table.insert(Freeze,item)
                        Freezes=Freezes+1
                    else
                        UnfreezeAddress(addr)
                        table.insert(Data,item)
                    end
                end
            end
        end
        if #Data>0 then gg.setValues(Data) end
        if #Freeze>0 then gg.addListItems(Freeze) end
        
        -- 🆕 修改为与指针链函数一致的弹窗格式
        gg.toast("🔍 搜索条件: " .. #Search .. " 条\n📝 修改数据: " .. sum .. " 条\n❄️ 冻结状态: " .. (Freezes > 0 and "是 (" .. Freezes .. " 项)" or "否"))
    end
    
    -- 执行搜索和修改
    SearchWrite(tb1,tb2,dataType)
    
    --关闭加载框
    loadingBox['关闭']()
end,
function()
    if not _G.uid_backup or #_G.uid_backup==0 then
        gg.toast("无可恢复项")
        return
    end
    gg.setValues(_G.uid_backup)
    gg.removeListItems(_G.uid_backup)
    
    -- 🆕 修改为与指针链函数一致的弹窗格式
    gg.toast("🔙 恢复操作\n📊 恢复数据: " .. #_G.uid_backup .. " 条\n✅ 状态: 已恢复默认")
    
    _G.uid_backup={}
end),




hzs.switch("强制120帧率",
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
XGBase(
{gg.getRangesList("libyuanshen.so")[4].start},
{
{120,4,0x1561D4,true},
})
--国际服
elseif selPkg==pkgs.GL then
XGBase(
{gg.getRangesList('libyuanshen.so')[4].start},
{
{120,4,0x156814,true},
})
else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end,
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
XGBase(
{gg.getRangesList("libyuanshen.so")[4].start},
{
{60,4,0x1561D4},
})
--国际服
elseif selPkg==pkgs.GL then
XGBase(
{gg.getRangesList('libyuanshen.so')[4].start},
{
{60,4,0x156814},
})
else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end),




hzs.switch("隐藏屏幕文字",
function()
pmwzg()--关
end,
function()
pmwzk()--开
end),







--第四页
},{ 
hzs.text("请开启风之翼","#FF0000","15sp"),

hzs.switch("角色位置锁定",
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x1278BB0, 4, "~A8 MOV	 W1, WZR", false)
if ok1 then count = count + 1 end

local ok2 = aycSet(libil2cppxa + 0x1278BB8, 4, "~A8 MOV	 W1, WZR", false)
if ok2 then count = count + 1 end

local ok3 = aycSet(libil2cppxa + 0x1278BC0, 4, "~A8 MOV	 W1, WZR", false)
if ok3 then count = count + 1 end

gg.toast("修改" .. (count > 0 and "成功" or "失败") .. "，成功修改" .. count .. "条地址")

--国际服
elseif selPkg==pkgs.GL then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

-- 原代码保留，新增成功计数
local ok1 = aycSet(libil2cppxa + 0x12911F0, 4, "~A8 MOV	 W1, WZR", false)
if ok1 then count = count + 1 end

local ok2 = aycSet(libil2cppxa + 0x12911F8, 4, "~A8 MOV	 W1, WZR", false)
if ok2 then count = count + 1 end

local ok3 = aycSet(libil2cppxa + 0x1291200, 4, "~A8 MOV	 W1, WZR", false)
if ok3 then count = count + 1 end

-- 提示结果
gg.toast("开启" .. (count == 3 and "成功" or "部分成功") .. "，共修改成功" .. count .. "条地址")

else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end,
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x12911F0, 4, "~A8 LDR	 W1, [X20]", false)
if ok1 then count = count + 1 end

local ok2 = aycSet(libil2cppxa + 0x12911F8, 4, "~A8 LDR	 W1, [X20,#0x4]", false)
if ok2 then count = count + 1 end

local ok3 = aycSet(libil2cppxa + 0x1291200, 4, "~A8 LDR	 W1, [X20,#0x8]", false)
if ok3 then count = count + 1 end

gg.toast("修改" .. (count == 3 and "全部成功" or "部分成功") .. "，成功" .. count .. "条")

--国际服
elseif selPkg==pkgs.GL then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x1279600, 4, "~A8 LDR	 W1, [X20]", false)
if ok1 then count = count + 1 end

local ok2 = aycSet(libil2cppxa + 0x1279608, 4, "~A8 LDR	 W1, [X20,#0x4]", false)
if ok2 then count = count + 1 end

local ok3 = aycSet(libil2cppxa + 0x1279610, 4, "~A8 LDR	 W1, [X20,#0x8]", false)
if ok3 then count = count + 1 end

gg.toast("修改" .. (count == 3 and "全部成功" or "部分成功") .. "，成功" .. count .. "条")

else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end),




hzs.button("升",
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x12775B8, 4, "~A8 FMUL	 S1, S1, S1", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

--国际服
elseif selPkg==pkgs.GL then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x128FBF8, 4, "~A8 FMUL	 S1, S1, S1", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end),




hzs.button("降",
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x12775B8, 4, "~A8 FMUL	 S23, S1, S1", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

--国际服
elseif selPkg==pkgs.GL then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x128FBF8, 4, "~A8 FMUL	 S23, S1, S1", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end),




hzs.button("前进",
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x12775B8, 4, "~A8 FMUL	 S0, S1, S1", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

--国际服
elseif selPkg==pkgs.GL then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x128FBF8, 4, "~A8 FMUL	 S0, S1, S1", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end),




hzs.button("重置",
function()
--自动选择版本
local addr
--国服
if selPkg==pkgs.CN then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x12775B8, 4, "~A8 FADD	 S0, S0, S0", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

--国际服
elseif selPkg==pkgs.GL then
local libil2cppxa = aycXa("libyuanshen.so")
local count = 0

local ok1 = aycSet(libil2cppxa + 0x128FBF8, 4, "~A8 FADD	 S0, S0, S0", false)
if ok1 then count = count + 1 end

gg.toast("修改" .. (count == 1 and "成功" or "失败") .. "，成功" .. count .. "条")

else
gg.alert("❌未识别到服务器版本，脚本终止。")
return
end
end),




--第五页
},{ 










--第六页
},{ 
hzs.button("退出辅助",
function()
app.exit()
end),




hzs.button("退出游戏和辅助", 
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()
gg.processKill()
gg.sleep(500) 
app.exit()
--关闭加载框
loadingBox['关闭']()
end),











--第六页
},{
hzs.text("非开发人员勿点击，可能会卡死","#FF0000","15sp"),

hzs.button("开发者调试专用",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()



--关闭加载框
loadingBox['关闭']()
end),




hzs.button("开发者调试专用",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()



--关闭加载框
loadingBox['关闭']()
end),















hzs.switch("角色位置锁定",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启角色位置锁定...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{1409287360,4,0},
{-1191126431,4,24},
}
local tb2=
{
{706675681,4,4},
{706675681,4,12},
{706675681,4,20},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在关闭角色位置锁定...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{1409287360,4,0},
{-1191126431,4,24},
}
local tb2=
{
{-1186987391,4,4},
{-1186986367,4,12},
{-1186985343,4,20},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end),




hzs.switch("刷物品",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{706020320,4,0},
{705954785,4,4},
{-1441332254,4,8},
{-1441135644,4,12},
}
local tb2=
{
{-721215457,4,16},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{706020320,4,0},
{705954785,4,4},
{-1441332254,4,8},
{-1441135644,4,12},
}
local tb2=
{
{-721215457,4,16},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end),




hzs.switch("倍率",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{505489665,4,0},
{506013696,4,4},
{505481224,4,8},
}
local tb2=
{
{-721215457,4,8},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{505489665,4,0},
{506013696,4,4},
{505481224,4,8},
}
local tb2=
{
{505481224,4,8},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end),




hzs.switch("飞行模式",
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{521475655,4,0},
{505489441,4,4},
{505555010,4,8},
}
local tb2=
{
{-721215457,4,12},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end,
function()
--显示加载框
local loadingBox=getLoadingBox('正在开启...')
loadingBox['显示']()

gg.setRanges(16384)
Name=''
local tb1=
{
{521475655,4,0},
{505489441,4,4},
{505555010,4,8},
}
local tb2=
{
{-721215457,4,12},
}
SearchWrite(tb1,tb2,dataType)

--关闭加载框
loadingBox['关闭']()
end),










}
})
--菜单尾巴




--[[
--语音
string.toMusic("准备播放音乐")
--延迟，1000＝1秒
gg.sleep(7000) 


]]
--播放视频
--gg.playVideo('https://v2.kwaicdn.com/bs2/photo-video-mz/5234027373538990342_c93946c21e043ee8_1444_sl200hd15.mp4?pkey=AAWcU_lHWw3a5OGx2Tq40Vftk_sCv6ZwasuPk_LUVM9zWhdLbpfRf7Rn-PDS_cKtaiRF9QXvq_Hi4MqDg6Ym6dXpDH0UzDilffGziCN0qnsh9yfJ6699HZ1vJKI59oie-8s&tag=1-1765075589-unknown-0-mp0x9pyqnv-6970c51f6cccc03b&clientCacheKey=3xfcfamr7uprurc_849cea8a&di=7920b162&bp=10000&kwai-not-alloc=40&tt=sl200hd15&ss=vpm')

--播放音乐
--gg.playMusic("https://oss.dinduan.com/view.php/981cf26efcd9899c06295fc09375ea2f.mp3")









bloc = luajava.getBlock()
bloc('join')
--UI尾巴





