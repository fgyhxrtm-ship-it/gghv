local WHITELIST_URL      = "https://pastefy.app/H9epeh3W/raw?rand="..math.random()
local TARGET_SCRIPT_URL  = "https://github.com/fgyhxrtm-ship-it/gghv/blob/main/%E6%AC%BE%E8%84%9A%E6%9C%AC--%E8%A2%AB%E9%81%97%E5%BC%83--%E6%BA%90%E7%A0%81.lua"

local MAX_ATTEMPTS          = 3
local RETRY_DELAY            = 1
local MAX_WHITELIST_BYTES   = 65536
local MAX_SCRIPT_BYTES      = 4194304

local env = _G
if type(getgenv) == "function" then
    local ok, value = pcall(getgenv)
    if ok and type(value) == "table" then
        env = value
    end
end
if type(env) ~= "table" then
    warn("运行环境无效，已停止")
    return
end

if env.__WLState == "running"
    or env.__WLState == "loaded"
    or env.__WLState == "blocked"
then
    return
end
env.__WLState = "running"

env.__KRLoaderState   = "running"
env.__KRLoaderBlocked = false

env.__KRGuard = function(stage)
    if env.__WLState == "blocked" or env.__KRLoaderBlocked == true then
        error("loader_blocked", 0)
    end
    return true
end

local function publishAuth(allowed, status, reason)
    local v = allowed == true
    local s = status or ""
    local r = reason or ""

    if type(env) == "table" then
        env.isWhitelisted    = v
        env.IsWhitelisted    = v
        env.WhitelistStatus  = s
        env.WhitelistReason  = r
    end
    if type(_G) == "table" and _G ~= env then
        _G.isWhitelisted    = v
        _G.IsWhitelisted    = v
        _G.WhitelistStatus  = s
        _G.WhitelistReason  = r
    end
end

local function blockState(reason)
    env.__WLState         = "blocked"
    env.__KRLoaderState   = "blocked"
    env.__KRLoaderBlocked = true
    publishAuth(false, "blocked", reason or "blocked")
end

local function httpGet(url)
    if type(url) ~= "string" then
        return nil
    end

    local req =
        (type(syn)    == "table" and syn.request)
     or (type(fluxus) == "table" and fluxus.request)
     or (type(http)   == "table" and http.request)
     or request
     or http_request

    if type(req) == "function" then
        local ok, resp = pcall(req, {
            Url     = url,
            Method  = "GET",
            Headers = {
                ["Cache-Control"] = "no-store, no-cache, must-revalidate",
                ["Pragma"]        = "no-cache",
            },
        })
        if ok and type(resp) == "table" then
            local body = resp.Body or resp.body
            if type(body) == "string" then
                return body
            end
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" then
        return body
    end
    return nil
end

local function parseWhitelist(text)
    local set = {}
    for line in text:gmatch("[^\r\n]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" and trimmed:sub(1, 1) ~= "#" then
            set[trimmed:lower()] = true
        end
    end
    return set
end

local function checkWhitelist(name)
    local lowerName = name:lower()
    for attempt = 1, MAX_ATTEMPTS do
        local body = httpGet(WHITELIST_URL)
        if type(body) == "string"
            and #body > 0
            and #body <= MAX_WHITELIST_BYTES
        then
            local names = parseWhitelist(body)
            if names[lowerName] then
                return true, ""
            end
            return false, "not_whitelisted"
        end

        if attempt < MAX_ATTEMPTS then
            task.wait(RETRY_DELAY)
        end
    end
    return false, "whitelist_unavailable"
end

local function downloadScript()
    for attempt = 1, MAX_ATTEMPTS do
        local body = httpGet(TARGET_SCRIPT_URL)
        if type(body) == "string"
            and #body >= 32
            and #body <= MAX_SCRIPT_BYTES
        then
            return body
        end
        if attempt < MAX_ATTEMPTS then
            task.wait(RETRY_DELAY)
        end
    end
    return nil
end

publishAuth(false, "checking", "")

local Players = game:GetService("Players")
local player  = Players.LocalPlayer
if not player then
    blockState("no_local_player")
    warn("未找到本地玩家，已停止")
    return
end

local playerName = player.Name
if type(playerName) ~= "string"
    or #playerName == 0
    or #playerName > 20
    or not playerName:match("^[%w_]+$")
then
    blockState("invalid_player")
    warn("玩家名无效，已停止")
    return
end

local allowed, reason = checkWhitelist(playerName)
if not allowed then
    publishAuth(false, "denied", reason)
    warn("未授权：" .. tostring(reason) .. "，将以搁浅版启动")
else
    publishAuth(true, "authorized", "")
end

local source = downloadScript()
if not source then
    blockState("download_failed")
    publishAuth(false, "error", "download_failed")
    warn("款脚本下载失败。")
    return
end

local chunk = loadstring(source)
source = nil
if type(chunk) ~= "function" then
    blockState("compile_failed")
    publishAuth(false, "error", "compile_failed")
    warn("款脚本编译失败。")
    return
end

local ok, err = pcall(chunk)
if not ok then
    blockState("runtime_failed")
    warn("殺脚本运行失败：" .. tostring(err))
    return
end

env.__WLState       = "loaded"
env.__KRLoaderState = "loaded"