-- 款脚本加载器
local FLASH_PLACE_ID = 136801880565837
local SA_PLACE_ID = 103854444055060

local FLASH_SCRIPT_URL = "https://raw.githubusercontent.com/fgyhxrtm-ship-it/super-duper-octo-spork/refs/heads/main/%E9%97%AA%E5%85%89.lua"
local SA_SCRIPT_URL = "https://raw.githubusercontent.com/fgyhxrtm-ship-it/super-duper-octo-spork/refs/heads/main/%E6%B2%89%E9%BB%98%E7%9A%84%E5%88%BA%E5%AE%A2.lua"

-- 非这两个游戏时，保留原文件的通用脚本回退行为。
local UNIVERSAL_SCRIPT_URL = "https://raw.githubusercontent.com/fgyhxrtm-ship-it/gghv/refs/heads/main/%E6%AC%BE%E8%84%9A%E6%9C%AC%E9%80%9A%E7%94%A8%E5%8A%A0%E5%AF%86.lua"

local placeId = game.PlaceId
local targetUrl
if placeId == FLASH_PLACE_ID then
    targetUrl = FLASH_SCRIPT_URL
elseif placeId == SA_PLACE_ID then
    targetUrl = SA_SCRIPT_URL
else
    targetUrl = UNIVERSAL_SCRIPT_URL
end

local ok, err = pcall(function()
    local source = game:HttpGet(targetUrl)
    local fn, compileError = loadstring(source)
    if not fn then error(compileError or "源码编译失败") end
    fn()
end)

if not ok then
    warn("[款脚本加载器] 加载失败：" .. tostring(err))
end
