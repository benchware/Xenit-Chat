-- XenitChat
-- Connecting people

local APP = {
    name = "XenitChat",
    slogan = "Connecting people",
    version = "19.1.9",
    protocolVersion = 19,
    protocolName = "Quartz",
    protocol = "xenitchat_bus",
    updateUrl = "https://raw.githubusercontent.com/benchware/Xenit-Chat/main/xenitchat.lua",

    accountFile = ".xenit_accounts",
    nodeSecretFile = ".xenit_node_secret",
    prefsFile = ".xenit_prefs",
    historyFile = ".xenit_history",

    maxMessages = 350,
    messageLimit = 200,
    historySyncLimit = 80,
    historySyncCooldown = 12,
    versionNoticeCooldown = 90,

    helloInterval = 4,
    onlineTimeout = 15,

    passRounds = 650,
    integrityRounds = 250,
    publicRounds = 200
}

local w, h = term.getSize()
local hasColor = term.isColor()

local THEMES = {
    dark = {
        name = "Dark",
        bg = colors.black,
        panel = colors.gray,
        top = colors.blue,
        accent = colors.cyan,
        good = colors.lime,
        warn = colors.orange,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    midnight = {
        name = "Midnight",
        bg = colors.black,
        panel = colors.gray,
        top = colors.black,
        accent = colors.lightBlue,
        good = colors.lime,
        warn = colors.yellow,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    ocean = {
        name = "Ocean",
        bg = colors.black,
        panel = colors.blue,
        top = colors.cyan,
        accent = colors.lightBlue,
        good = colors.lime,
        warn = colors.yellow,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    neon = {
        name = "Neon",
        bg = colors.black,
        panel = colors.purple,
        top = colors.magenta,
        accent = colors.cyan,
        good = colors.lime,
        warn = colors.yellow,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    graphite = {
        name = "Graphite",
        bg = colors.black,
        panel = colors.gray,
        top = colors.gray,
        accent = colors.orange,
        good = colors.lime,
        warn = colors.yellow,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    forest = {
        name = "Forest",
        bg = colors.black,
        panel = colors.green,
        top = colors.green,
        accent = colors.lime,
        good = colors.lime,
        warn = colors.orange,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    sunset = {
        name = "Sunset",
        bg = colors.black,
        panel = colors.brown,
        top = colors.orange,
        accent = colors.yellow,
        good = colors.lime,
        warn = colors.orange,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    amethyst = {
        name = "Amethyst",
        bg = colors.black,
        panel = colors.purple,
        top = colors.purple,
        accent = colors.magenta,
        good = colors.lime,
        warn = colors.yellow,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    ice = {
        name = "Ice",
        bg = colors.white,
        panel = colors.lightBlue,
        top = colors.cyan,
        accent = colors.blue,
        good = colors.green,
        warn = colors.orange,
        danger = colors.red,
        text = colors.black,
        muted = colors.gray,
        input = colors.white,
        inputText = colors.black
    },
    clean = {
        name = "Clean",
        bg = colors.white,
        panel = colors.lightGray,
        top = colors.gray,
        accent = colors.cyan,
        good = colors.green,
        warn = colors.orange,
        danger = colors.red,
        text = colors.black,
        muted = colors.gray,
        input = colors.white,
        inputText = colors.black
    }
}

local state = {
    running = true,

    screen = "login",
    focus = "username",
    remember = true,

    username = nil,
    publicId = nil,

    input = "",
    password = "",

    current = "global",
    scroll = 0,

    modal = nil,
    modalInput = "",
    modalMode = "public",
    modalData = nil,

    messages = {},
    convos = {
        global = {
            key = "global",
            title = "global",
            type = "public",
            private = false,
            listed = true,
            owner = "system",
            unread = 0,
            last = 0
        }
    },

    users = {},
    discover = {},

    friends = {},
    friendRequests = {
        inbox = {},
        sent = {}
    },
    blocked = {},
    blockedInfo = {},
    leftGroups = {},
    updateChecked = false,
    updateBusy = false,
    packetSeen = {},
    packetSeenOrder = {},
    messageSeen = {},
    historySyncLast = {},
    versionNoticeLast = {},
    pinned = {},
    quietVersionWarnings = true,
    allowOldClients = false,
    restartRequested = false,
    exitReason = nil,
    profile = {
        display = "",
        status = "Available"
    },

    theme = "midnight",
    buttons = {},
    convoClicks = {}
}

local seq = 0
local sendTo = nil -- forward declaration for early history sync calls

-- ============================================================
-- Theme / UI helpers
-- ============================================================

local function T()
    return THEMES[state.theme] or THEMES.dark
end

local function fg(c)
    if hasColor then term.setTextColor(c) end
end

local function bg(c)
    if hasColor then term.setBackgroundColor(c) end
end

local function reset()
    fg(colors.white)
    bg(colors.black)
end

local function clear()
    reset()
    term.clear()
    term.setCursorPos(1, 1)
end

local function safeWrite(v)
    write(tostring(v or ""))
end

local function fill(x, y, width, height, color)
    if width <= 0 or height <= 0 then return end

    bg(color)

    for yy = y, y + height - 1 do
        if yy >= 1 and yy <= h then
            local sx = math.max(1, x)
            local visible = math.max(0, math.min(width, w - sx + 1))

            if visible > 0 then
                term.setCursorPos(sx, yy)
                safeWrite(string.rep(" ", visible))
            end
        end
    end

    reset()
end

local function text(x, y, value, color, background)
    if y < 1 or y > h or x < 1 or x > w then return end

    local s = tostring(value or "")
    local maxLen = w - x + 1

    if #s > maxLen then
        s = s:sub(1, maxLen)
    end

    if background then bg(background) end
    if color then fg(color) end

    term.setCursorPos(x, y)
    safeWrite(s)
    reset()
end

local function center(y, value, color, background)
    local s = tostring(value or "")
    local x = math.floor((w - #s) / 2) + 1
    text(math.max(1, x), y, s, color, background)
end

local function trim(value, maxLen)
    local s = tostring(value or "")

    if maxLen <= 0 then return "" end

    if #s > maxLen then
        if maxLen <= 3 then return s:sub(1, maxLen) end
        return s:sub(1, maxLen - 3) .. "..."
    end

    return s
end

local function isTiny()
    return w < 28 or h < 13
end

local function isPocket()
    return w < 50 or h < 18
end

local function isSmall()
    return w < 58 or h < 18
end

local function hasSidebar()
    return w >= 58 and h >= 16
end

local function leftWidth()
    if not hasSidebar() then return 0 end
    if w < 72 then return 18 end
    if w < 92 then return 22 end
    return math.min(28, math.floor(w * 0.26))
end

local function inputRows()
    if h <= 13 then return 1 end
    return 2
end

local function bottomChromeRows()
    return inputRows() + 2
end

local function messageArea()
    local lw = leftWidth()
    local top = lw == 0 and 3 or 2
    local bottom = h - bottomChromeRows() - 1

    if bottom < top then bottom = top end

    if lw == 0 then
        return 1, top, w, bottom, math.max(1, bottom - top + 1)
    end

    return lw + 1, top, w - lw, bottom, math.max(1, bottom - top + 1)
end

local function clearClickable()
    state.buttons = {}
    state.convoClicks = {}
end

local function addButton(id, x, y, width, label, color, background, action)
    if y < 1 or y > h then return end

    x = math.floor(tonumber(x) or 1)
    y = math.floor(tonumber(y) or 1)
    width = math.floor(tonumber(width) or 1)

    if x < 1 then x = 1 end
    if x > w then return end

    width = math.max(1, width)
    if x + width - 1 > w then
        width = w - x + 1
    end

    if width <= 0 then return end

    state.buttons[id] = {
        x = x,
        y = y,
        w = width,
        h = 1,
        action = action
    }

    local display = trim(label or "", width)

    local pad = math.max(0, width - #display)
    local left = math.floor(pad / 2)
    local right = pad - left

    bg(background or T().panel)
    fg(color or T().text)
    term.setCursorPos(x, y)
    safeWrite(string.rep(" ", left) .. display .. string.rep(" ", right))
    reset()
end

local function clickButton(x, y)
    for _, b in pairs(state.buttons) do
        if x >= b.x and x <= b.x + b.w - 1 and y >= b.y and y <= b.y + b.h - 1 then
            if b.action then b.action() end
            return true
        end
    end

    return false
end

-- ============================================================
-- File helpers
-- ============================================================

local function readSerialized(path, fallback)
    if not fs.exists(path) then return fallback end

    local f = fs.open(path, "r")
    if not f then return fallback end

    local raw = f.readAll() or ""
    f.close()

    local ok, data = pcall(textutils.unserialize, raw)

    if ok and data ~= nil then
        return data
    end

    return fallback
end

local function writeSerialized(path, data)
    local f = fs.open(path, "w")
    f.write(textutils.serialize(data))
    f.close()
end

local function readText(path)
    if not fs.exists(path) then return nil end

    local f = fs.open(path, "r")
    if not f then return nil end

    local raw = f.readAll()
    f.close()

    return raw
end

local function writeText(path, data)
    local f = fs.open(path, "w")
    f.write(tostring(data or ""))
    f.close()
end

-- ============================================================
-- Hash / identity
-- ============================================================

local function seedRandom()
    local seed = os.time() + os.getComputerID() * 31337

    if os.epoch then
        local ok, epoch = pcall(os.epoch, "utc")
        if ok and type(epoch) == "number" then
            seed = seed + epoch
        end
    end

    math.randomseed(seed)

    for _ = 1, 5 do math.random() end
end

seedRandom()

local function randomToken(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local out = {}

    for i = 1, length do
        local n = math.random(1, #chars)
        out[i] = chars:sub(n, n)
    end

    return table.concat(out)
end

local function baseHash(input)
    input = tostring(input or "")

    local h1 = 5381
    local h2 = 2166136261 % 2147483647
    local h3 = 1315423911 % 2147483647

    for i = 1, #input do
        local b = input:byte(i)

        h1 = ((h1 * 33) + b) % 2147483647
        h2 = ((h2 * 16777619) + b + i) % 2147483647
        h3 = (h3 + ((b + i) * 2654435761)) % 2147483647
    end

    return tostring(h1) .. "-" .. tostring(h2) .. "-" .. tostring(h3)
end

local function slowHash(input, rounds)
    local value = tostring(input or "")

    for i = 1, rounds do
        value = baseHash(value .. "|" .. tostring(i) .. "|" .. baseHash(value))
    end

    return value
end

local function shortId(id)
    id = tostring(id or ""):gsub("%-", "")

    if #id <= 6 then return id end
    return id:sub(1, 6)
end

local function appVersion()
    return tostring(APP.version or APP.protocolVersion or "0")
end

local function protocolName()
    return tostring(APP.protocolName or "Unknown")
end

local function protocolVersion()
    return tonumber(APP.protocolVersion or APP.version) or 0
end

local function parseVersionParts(value)
    local parts = {}
    value = tostring(value or "0")

    for part in value:gmatch("%d+") do
        table.insert(parts, tonumber(part) or 0)
    end

    if #parts == 0 then parts[1] = 0 end
    return parts
end

local function compareVersions(a, b)
    local aa = parseVersionParts(a)
    local bb = parseVersionParts(b)
    local max = math.max(#aa, #bb)

    for i = 1, max do
        local av = aa[i] or 0
        local bv = bb[i] or 0

        if av < bv then return -1 end
        if av > bv then return 1 end
    end

    return 0
end

local function sameProtocolVersion(value)
    return tonumber(value) == protocolVersion()
end

local function getNodeSecret()
    local existing = readText(APP.nodeSecretFile)

    if existing and #existing >= 24 then
        return existing
    end

    local secret = randomToken(64) .. "-" .. tostring(os.getComputerID()) .. "-" .. tostring(os.time())
    writeText(APP.nodeSecretFile, secret)
    return secret
end

local function getPublicId(nodeSecret)
    return slowHash("PUB|" .. tostring(os.getComputerID()) .. "|" .. tostring(nodeSecret), APP.publicRounds)
end

local function passwordHash(password, salt)
    return slowHash("PASS|" .. tostring(salt) .. "|" .. tostring(password), APP.passRounds)
end

local function accountIntegrity(username, account, nodeSecret)
    local raw =
        "ACC|" ..
        tostring(username) .. "|" ..
        tostring(account.username) .. "|" ..
        tostring(account.salt) .. "|" ..
        tostring(account.passHash) .. "|" ..
        tostring(account.nodeId) .. "|" ..
        tostring(account.publicId) .. "|" ..
        tostring(account.created) .. "|" ..
        tostring(nodeSecret)

    return slowHash(raw, APP.integrityRounds)
end

local function loadAccounts()
    return readSerialized(APP.accountFile, {})
end

local function saveAccounts(accounts)
    writeSerialized(APP.accountFile, accounts)
end

local function buildAccount(username, password)
    local nodeSecret = getNodeSecret()
    local salt = randomToken(32)
    local publicId = getPublicId(nodeSecret)

    local account = {
        username = username,
        salt = salt,
        passHash = passwordHash(password, salt),
        nodeId = os.getComputerID(),
        publicId = publicId,
        created = os.time()
    }

    account.integrity = accountIntegrity(username, account, nodeSecret)
    return account
end

local function verifyAccount(username, account)
    if type(account) ~= "table" then
        return false, "Account record missing."
    end

    local nodeSecret = getNodeSecret()
    local expectedPublicId = getPublicId(nodeSecret)

    if account.username ~= username then
        return false, "Username mismatch."
    end

    if tonumber(account.nodeId) ~= tonumber(os.getComputerID()) then
        return false, "Account belongs to another device."
    end

    if account.publicId ~= expectedPublicId then
        return false, "Device identity mismatch."
    end

    local expectedIntegrity = accountIntegrity(username, account, nodeSecret)

    if account.integrity ~= expectedIntegrity then
        return false, "Account file was modified."
    end

    return true, "OK"
end

-- ============================================================
-- Preferences
-- ============================================================

local function defaultPrefs()
    return {
        remember = true,
        username = nil,
        theme = "midnight",
        profile = {
            display = "",
            status = "Available"
        },
        friends = {},
        friendRequests = {
            inbox = {},
            sent = {}
        },
        blocked = {},
        blockedInfo = {},
        leftGroups = {},
        pinned = {},
        quietVersionWarnings = true,
        allowOldClients = false,
        convos = {
            global = {
                key = "global",
                title = "global",
                type = "public",
                private = false,
                listed = true,
                owner = "system",
                unread = 0,
                last = 0
            }
        }
    }
end

local function savePrefs()
    local data = {
        remember = state.remember,
        username = state.remember and state.username or nil,
        theme = state.theme,
        profile = state.profile,
        friends = state.friends,
        friendRequests = state.friendRequests,
        blocked = state.blocked,
        blockedInfo = state.blockedInfo,
        leftGroups = state.leftGroups,
        pinned = state.pinned,
        quietVersionWarnings = state.quietVersionWarnings,
        allowOldClients = state.allowOldClients,
        convos = state.convos
    }

    writeSerialized(APP.prefsFile, data)
end

local function loadPrefs()
    local data = readSerialized(APP.prefsFile, defaultPrefs())

    if type(data) ~= "table" then data = defaultPrefs() end
    if type(data.convos) ~= "table" then data.convos = defaultPrefs().convos end
    if type(data.friends) ~= "table" then data.friends = {} end
    if type(data.friendRequests) ~= "table" then data.friendRequests = { inbox = {}, sent = {} } end
    if type(data.friendRequests.inbox) ~= "table" then data.friendRequests.inbox = {} end
    if type(data.friendRequests.sent) ~= "table" then data.friendRequests.sent = {} end
    if type(data.blocked) ~= "table" then data.blocked = {} end
    if type(data.blockedInfo) ~= "table" then data.blockedInfo = {} end
    if type(data.leftGroups) ~= "table" then data.leftGroups = {} end
    if type(data.pinned) ~= "table" then data.pinned = {} end
    if type(data.quietVersionWarnings) ~= "boolean" then data.quietVersionWarnings = true end
    if type(data.allowOldClients) ~= "boolean" then data.allowOldClients = false end
    if type(data.profile) ~= "table" then data.profile = { display = "", status = "Available" } end

    state.remember = data.remember ~= false
    state.theme = THEMES[data.theme] and data.theme or "midnight"
    state.profile = data.profile
    state.friends = data.friends
    state.friendRequests = data.friendRequests
    state.blocked = data.blocked
    state.blockedInfo = data.blockedInfo
    state.leftGroups = data.leftGroups
    state.pinned = data.pinned
    state.quietVersionWarnings = data.quietVersionWarnings
    state.allowOldClients = data.allowOldClients
    state.convos = data.convos

    if not state.convos.global then
        state.convos.global = defaultPrefs().convos.global
    end
end

-- ============================================================
-- Messages / conversations
-- ============================================================

local function clampMessage(value)
    value = tostring(value or "")

    if #value > APP.messageLimit then
        return value:sub(1, APP.messageLimit)
    end

    return value
end

local function splitFixed(value, width)
    local s = tostring(value or "")
    local lines = {}

    if width <= 0 then return { "" } end
    if s == "" then return { "" } end

    while #s > width do
        table.insert(lines, s:sub(1, width))
        s = s:sub(width + 1)
    end

    table.insert(lines, s)
    return lines
end

local function getInputLines()
    local raw = "> " .. tostring(state.input or "")
    local width = math.max(1, w - leftWidth())
    local lines = splitFixed(raw, width)
    local visible = {}

    if #lines == 1 then
        visible[1] = lines[1]
        visible[2] = ""
    else
        visible[1] = lines[#lines - 1]
        visible[2] = lines[#lines]
    end

    return visible
end

local function touchConvo(key)
    if state.convos[key] then
        seq = seq + 1
        state.convos[key].last = seq
    end
end

local function ensureConvo(key, title, kind, private, listed, owner, peerId)
    if not key or key == "" then return end

    if not state.convos[key] then
        state.convos[key] = {
            key = key,
            title = title or key,
            type = kind or "public",
            private = private or false,
            listed = listed ~= false,
            owner = owner or "unknown",
            peerId = peerId,
            unread = 0,
            last = 0,
            renamedBy = nil
        }
    else
        local c = state.convos[key]

        -- Existing chats should not be accidentally downgraded by generic message writes.
        if title and title ~= "" and title ~= key then c.title = title end
        if kind and not (c.type == "pm" and kind == "public") then c.type = kind end
        if private ~= nil then c.private = private end
        if listed ~= nil then c.listed = listed end
        if owner and owner ~= "unknown" then c.owner = owner end
        if peerId then c.peerId = peerId end
    end

    if not state.messages[key] then
        state.messages[key] = {}
    end

    touchConvo(key)
    savePrefs()
end

local saveHistory

local function messageIdentity(key, from, body, kind, meta)
    meta = meta or {}

    if meta.msgId and meta.msgId ~= "" then
        return tostring(meta.msgId)
    end

    return slowHash("MSG|" .. tostring(key) .. "|" .. tostring(from) .. "|" .. tostring(body) .. "|" .. tostring(kind) .. "|" .. tostring(meta.fromId or "") .. "|" .. tostring(meta.time or ""), 8)
end

local function rememberMessage(key, msgId)
    if not key or not msgId then return end
    state.messageSeen[key] = state.messageSeen[key] or {}
    state.messageSeen[key][msgId] = true
end

local function hasMessage(key, msgId)
    return key and msgId and state.messageSeen[key] and state.messageSeen[key][msgId]
end

local function rebuildMessageSeen()
    state.messageSeen = {}

    for key, list in pairs(state.messages or {}) do
        if type(list) == "table" then
            for _, m in ipairs(list) do
                if type(m) == "table" then
                    local id = m.msgId or messageIdentity(key, m.from, m.body, m.kind, m)
                    m.msgId = id
                    rememberMessage(key, id)
                end
            end
        end
    end
end

local function addMessage(key, from, body, kind, meta)
    key = key or "global"

    if not state.convos[key] then
        ensureConvo(key, key, kind == "pm" and "pm" or "public", kind == "pm", kind ~= "pm", "unknown")
    end

    if not state.messages[key] then
        state.messages[key] = {}
    end

    meta = meta or {}
    local msgId = messageIdentity(key, from, body, kind or "chat", meta)

    if hasMessage(key, msgId) then
        return false
    end

    local entry = {
        from = tostring(from or "system"),
        body = clampMessage(body or ""),
        kind = kind or "chat",
        time = meta.time or textutils.formatTime(os.time(), true),
        epoch = meta.epoch or os.time(),
        msgId = msgId,
        fromId = meta.fromId,
        outgoing = meta.outgoing,
        seen = meta.seen or false
    }

    table.insert(state.messages[key], entry)
    rememberMessage(key, msgId)

    while #state.messages[key] > APP.maxMessages do
        local removed = table.remove(state.messages[key], 1)
        if removed and removed.msgId and state.messageSeen[key] then
            state.messageSeen[key][removed.msgId] = nil
        end
    end

    touchConvo(key)

    if key == state.current then
        state.scroll = 0
    elseif not meta.silent then
        state.convos[key].unread = (state.convos[key].unread or 0) + 1
    end

    savePrefs()
    if saveHistory and not meta.skipSave then saveHistory() end
    return true
end

local function systemMessage(body, key)
    addMessage(key or state.current, "system", body, "system")
end

local function isHistorySyncable(key, publicId)
    local c = state.convos[key]
    if not c then return false end

    if key == "global" then return true end

    if c.type == "pm" then
        return publicId ~= nil and c.peerId == publicId
    end

    if c.private == true then return false end
    if c.listed == false then return false end
    if state.leftGroups[key] then return false end

    return true
end

saveHistory = function()
    local data = {
        version = appVersion(),
        savedAt = os.time(),
        messages = {},
        convos = {}
    }

    for key, list in pairs(state.messages or {}) do
        if type(list) == "table" and #list > 0 then
            data.messages[key] = {}
            local startAt = math.max(1, #list - APP.maxMessages + 1)

            for i = startAt, #list do
                local m = list[i]
                if type(m) == "table" then
                    table.insert(data.messages[key], {
                        from = m.from,
                        body = m.body,
                        kind = m.kind,
                        time = m.time,
                        epoch = m.epoch,
                        msgId = m.msgId,
                        fromId = m.fromId,
                        outgoing = m.outgoing,
                        seen = m.seen
                    })
                end
            end

            if state.convos[key] then
                data.convos[key] = state.convos[key]
            end
        end
    end

    writeSerialized(APP.historyFile, data)
end

local function loadHistory()
    local data = readSerialized(APP.historyFile, nil)

    if type(data) ~= "table" or type(data.messages) ~= "table" then
        rebuildMessageSeen()
        return
    end

    if type(data.convos) == "table" then
        for key, c in pairs(data.convos) do
            if type(c) == "table" and key ~= "global" and not state.convos[key] then
                state.convos[key] = c
            end
        end
    end

    for key, list in pairs(data.messages) do
        if type(list) == "table" then
            if not state.messages[key] then state.messages[key] = {} end
            if not state.convos[key] then
                ensureConvo(key, key, "public", false, true, "history")
            end

            for _, m in ipairs(list) do
                if type(m) == "table" and m.body then
                    addMessage(key, m.from, m.body, m.kind, {
                        msgId = m.msgId,
                        fromId = m.fromId,
                        outgoing = m.outgoing,
                        seen = m.seen,
                        time = m.time,
                        epoch = m.epoch,
                        silent = true,
                        skipSave = true
                    })
                end
            end

            if state.convos[key] then
                state.convos[key].unread = 0
            end
        end
    end

    rebuildMessageSeen()
end

local function historyKeysForPeer(publicId)
    local keys = {}

    for key, _ in pairs(state.convos or {}) do
        if isHistorySyncable(key, publicId) then
            table.insert(keys, key)
        end
    end

    return keys
end

local function makeHistoryBundle(keys, requesterPublicId)
    local bundles = {}

    for _, key in ipairs(keys or {}) do
        if isHistorySyncable(key, requesterPublicId) then
            local list = state.messages[key] or {}
            local out = {}
            local startAt = math.max(1, #list - APP.historySyncLimit + 1)

            for i = startAt, #list do
                local m = list[i]
                if type(m) == "table" and m.kind ~= "system" and m.body then
                    table.insert(out, {
                        from = m.from,
                        body = m.body,
                        kind = m.kind,
                        time = m.time,
                        epoch = m.epoch,
                        msgId = m.msgId,
                        fromId = m.fromId,
                        outgoing = false,
                        seen = m.seen
                    })
                end
            end

            if #out > 0 then
                local c = state.convos[key] or {}
                table.insert(bundles, {
                    key = key,
                    title = c.title or key,
                    type = c.type or "public",
                    private = c.private or false,
                    listed = c.listed ~= false,
                    owner = c.owner or "unknown",
                    peerId = c.peerId,
                    messages = out
                })
            end
        end
    end

    return bundles
end

local function importHistoryBundles(bundles, senderPublicId)
    local imported = 0

    if type(bundles) ~= "table" then return 0 end

    for _, bundle in ipairs(bundles) do
        if type(bundle) == "table" and bundle.key and type(bundle.messages) == "table" then
            local key = tostring(bundle.key)
            local allowed = false

            if key == "global" then
                allowed = true
            elseif bundle.type == "pm" then
                allowed = bundle.peerId == state.publicId or key == pmKeyFor(senderPublicId, bundle.title) or key == pmKeyFor(senderPublicId, senderPublicId)
                key = pmKeyFor(senderPublicId, bundle.title)
            elseif bundle.private ~= true and bundle.listed ~= false and not state.leftGroups[key] then
                allowed = true
            end

            if allowed then
                ensureConvo(key, bundle.title or key, bundle.type or "public", bundle.private or false, bundle.listed ~= false, bundle.owner or "history", bundle.type == "pm" and senderPublicId or bundle.peerId)

                for _, m in ipairs(bundle.messages) do
                    if type(m) == "table" and m.body then
                        local added = addMessage(key, m.from, m.body, m.kind, {
                            msgId = m.msgId,
                            fromId = m.fromId or senderPublicId,
                            outgoing = false,
                            seen = m.seen,
                            time = m.time,
                            epoch = m.epoch,
                            silent = true
                        })

                        if added then imported = imported + 1 end
                    end
                end
            end
        end
    end

    if imported > 0 then saveHistory() end
    return imported
end

local function requestHistorySync(senderId, publicId)
    if not senderId or not publicId then return end

    local now = os.clock()
    if state.historySyncLast[publicId] and now - state.historySyncLast[publicId] < APP.historySyncCooldown then
        return
    end

    state.historySyncLast[publicId] = now

    sendTo(senderId, "history_request", {
        keys = historyKeysForPeer(publicId)
    })
end

local function switchConvo(key)
    ensureConvo(key, key, "public", false, true, "unknown")
    state.current = key
    state.scroll = 0

    if state.convos[key] then
        state.convos[key].unread = 0
    end

    savePrefs()
end

local function getConvoList()
    local list = {}

    for key, c in pairs(state.convos) do
        table.insert(list, c)
    end

    table.sort(list, function(a, b)
        if a.key == "global" then return true end
        if b.key == "global" then return false end

        local ap = state.pinned and state.pinned[a.key] == true
        local bp = state.pinned and state.pinned[b.key] == true
        if ap ~= bp then return ap end

        if (a.unread or 0) ~= (b.unread or 0) then
            return (a.unread or 0) > (b.unread or 0)
        end

        if (a.last or 0) ~= (b.last or 0) then
            return (a.last or 0) > (b.last or 0)
        end

        return tostring(a.title) < tostring(b.title)
    end)

    return list
end

local function nextConvo()
    local list = getConvoList()

    if #list == 0 then return end

    for i, c in ipairs(list) do
        if c.key == state.current then
            switchConvo((list[i + 1] or list[1]).key)
            return
        end
    end

    switchConvo(list[1].key)
end

local function wrapText(prefix, body, width, color)
    local lines = {}
    local p = tostring(prefix or "")
    local b = tostring(body or "")

    if width <= 0 then return lines end

    local function push(value)
        table.insert(lines, {
            text = trim(value, width),
            color = color
        })
    end

    if #p > width - 4 then
        local prefixLines = splitFixed(p, width)

        for _, line in ipairs(prefixLines) do
            push(line)
        end

        p = "  "
    end

    local indent = string.rep(" ", math.min(#p, math.max(0, width - 1)))
    local available = width - #p

    if available < 4 then
        push(p)
        p = "  "
        indent = "  "
        available = width - #p
    end

    local current = ""
    local prefixNow = p

    local function flush()
        push(prefixNow .. current)
        prefixNow = indent
        available = width - #prefixNow
        current = ""
    end

    for word in b:gmatch("%S+") do
        while #word > available do
            local room = available - #current

            if room <= 0 then
                flush()
                room = available
            end

            local part = word:sub(1, room)
            current = current .. part
            word = word:sub(room + 1)
            flush()
        end

        if current == "" then
            current = word
        elseif #current + 1 + #word <= available then
            current = current .. " " .. word
        else
            flush()
            current = word
        end
    end

    if current ~= "" or #lines == 0 then
        push(prefixNow .. current)
    end

    return lines
end

local function buildVisualLines(key, width)
    local visual = {}
    local list = state.messages[key] or {}

    for _, m in ipairs(list) do
        local color = T().text
        local prefix = ""

        if m.kind == "system" then
            color = T().muted
            prefix = "i "
        elseif m.kind == "warn" then
            color = T().danger
            prefix = "! "
        elseif m.kind == "pm" then
            color = colors.purple
            prefix = "PM "
        else
            color = T().text

            if isPocket() then
                prefix = tostring(m.from or "user") .. ": "
            else
                prefix = "[" .. tostring(m.time or "") .. "] " .. tostring(m.from or "user") .. ": "
            end
        end

        local wrapped = wrapText(prefix, m.body, width, color)

        for _, line in ipairs(wrapped) do
            line.color = color
            table.insert(visual, line)
        end

        if m.outgoing and m.seen then
            table.insert(visual, {
                text = "  Seen",
                color = T().muted
            })
        end
    end

    return visual
end

local function maxScroll()
    local _, _, _, _, areaH = messageArea()
    local _, _, cw = messageArea()
    local visual = buildVisualLines(state.current, cw)
    return math.max(0, #visual - areaH)
end

local function clampScroll()
    local max = maxScroll()

    if state.scroll < 0 then
        state.scroll = 0
    elseif state.scroll > max then
        state.scroll = max
    end
end

local function scrollBy(delta)
    state.scroll = state.scroll + delta
    clampScroll()
end

-- ============================================================
-- Users / friends / block
-- ============================================================

local function displayName(username, publicId, profile)
    local base = username or "unknown"

    if profile and profile.display and profile.display ~= "" then
        base = profile.display
    end

    local duplicate = 0

    for _, u in pairs(state.users) do
        if u.username == username then
            duplicate = duplicate + 1
        end
    end

    if duplicate > 1 then
        return base .. "#" .. shortId(publicId)
    end

    return base
end

local function onlineCount()
    local now = os.clock()
    local count = 0

    for id, u in pairs(state.users) do
        if not state.blocked[id] and now - (u.lastSeenClock or 0) <= APP.onlineTimeout then
            count = count + 1
        end
    end

    return count
end

local function pendingFriendCount()
    local count = 0

    if state.friendRequests and state.friendRequests.inbox then
        for _ in pairs(state.friendRequests.inbox) do
            count = count + 1
        end
    end

    return count
end

local function totalUnread()
    local count = 0

    for _, c in pairs(state.convos or {}) do
        count = count + (c.unread or 0)
    end

    return count
end

local function peerDisplayName(publicId, fallback)
    local user = state.users[publicId]
    local friend = state.friends[publicId]
    local reqIn = state.friendRequests and state.friendRequests.inbox and state.friendRequests.inbox[publicId]
    local reqOut = state.friendRequests and state.friendRequests.sent and state.friendRequests.sent[publicId]
    local info = user or friend or reqIn or reqOut or {}

    return displayName(info.username or fallback or "unknown", publicId, info.profile or {})
end

local function chatLabel(c, compact)
    if not c then return "#global" end

    local pin = (state.pinned and state.pinned[c.key]) and "^ " or ""

    if c.type == "pm" then
        local name = peerDisplayName(c.peerId, c.title or c.key)
        if compact then return pin .. "DM " .. name end
        return pin .. "Direct message: " .. name
    end

    if c.key == "global" then return "#global" end
    return pin .. "#" .. tostring(c.title or c.key)
end

local function currentChatTitle()
    return chatLabel(state.convos[state.current], true)
end

local function cleanGroupTitle(value)
    local s = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%s+", " ")
    s = s:gsub("[\n\r\t]", " ")

    if #s > 28 then s = s:sub(1, 28) end
    return s
end

local function canManageGroup(c)
    return c and c.type ~= "pm" and c.key ~= "global"
end

local function relationMark(publicId)
    if state.friends[publicId] then return "*" end
    if state.friendRequests and state.friendRequests.inbox and state.friendRequests.inbox[publicId] then return "!" end
    if state.friendRequests and state.friendRequests.sent and state.friendRequests.sent[publicId] then return "?" end
    return " "
end

local function openMainMenu()
    state.modal = "main_menu"
    state.modalInput = ""
    state.modalData = nil
end

local function openChatsModal()
    state.modal = "chats"
    state.modalInput = ""
    state.modalData = nil
end

local function clearCurrentChat()
    if state.current and state.messages[state.current] then
        state.messages[state.current] = {}
        if state.messageSeen then state.messageSeen[state.current] = {} end
        systemMessage("Chat history cleared locally.", state.current)
        if saveHistory then saveHistory() end
    end
end

local function getSortedUsers()
    local now = os.clock()
    local list = {}

    for publicId, u in pairs(state.users) do
        if not state.blocked[publicId] then
            table.insert(list, {
                publicId = publicId,
                username = u.username,
                profile = u.profile or {},
                lastSeenClock = u.lastSeenClock or 0
            })
        end
    end

    table.sort(list, function(a, b)
        local ao = now - a.lastSeenClock <= APP.onlineTimeout
        local bo = now - b.lastSeenClock <= APP.onlineTimeout

        if ao ~= bo then return ao end

        local af = state.friends[a.publicId] ~= nil
        local bf = state.friends[b.publicId] ~= nil

        if af ~= bf then return af end

        return displayName(a.username, a.publicId, a.profile) < displayName(b.username, b.publicId, b.profile)
    end)

    return list
end

local function resolveUser(value)
    value = tostring(value or "")

    if value == "" then return nil end

    for publicId, u in pairs(state.users) do
        if shortId(publicId):lower() == value:lower() or publicId:sub(1, #value):lower() == value:lower() then
            return publicId, u
        end
    end

    local bestId = nil
    local bestUser = nil
    local bestSeen = -1

    for publicId, u in pairs(state.users) do
        local shown = displayName(u.username, publicId, u.profile)

        if u.username:lower() == value:lower() or shown:lower() == value:lower() then
            if (u.lastSeenClock or 0) > bestSeen then
                bestSeen = u.lastSeenClock or 0
                bestId = publicId
                bestUser = u
            end
        end
    end

    return bestId, bestUser
end

local function pmKeyFor(publicId, name)
    if publicId and publicId ~= "" then
        return "PM:" .. shortId(publicId)
    end

    return "PM:" .. tostring(name or "unknown")
end

-- ============================================================
-- Network
-- ============================================================

local function openModem()
    local found = false

    peripheral.find("modem", function(name)
        if not rednet.isOpen(name) then
            rednet.open(name)
        end

        found = true
    end)

    if not found then
        clear()
        center(3, APP.name, colors.cyan, colors.black)
        center(5, "No modem found.", colors.red, colors.black)
        center(7, "Attach/equip a modem.", colors.white, colors.black)
        sleep(3)
        error("No modem found")
    end
end

local function myName()
    if state.profile.display and state.profile.display ~= "" then
        return state.profile.display
    end

    return state.username or "guest"
end

local function makePacket(kind, data)
    data = data or {}

    data.app = APP.name
    data.version = protocolVersion()
    data.appVersion = appVersion()
    data.protocolName = protocolName()
    data.kind = kind
    data.user = state.username
    data.publicId = state.publicId
    data.nodeId = os.getComputerID()
    data.profile = state.profile
    data.time = os.time()
    data.packetId = randomToken(12)

    return data
end

local function broadcast(kind, data)
    if not state.username or not state.publicId then return end
    rednet.broadcast(makePacket(kind, data), APP.protocol)
end

sendTo = function(id, kind, data)
    if not state.username or not state.publicId then return end
    rednet.send(id, makePacket(kind, data), APP.protocol)
end


-- ============================================================
-- Auto update
-- ============================================================

local function getProgramPath()
    if shell and shell.getRunningProgram then
        local ok, path = pcall(shell.getRunningProgram)
        if ok and path and path ~= "" then return path end
    end

    return "xenitchat.lua"
end

local function httpRead(url)
    if not http or not http.get then
        return nil, "HTTP API is disabled. Enable http in CraftOS-PC/CC config."
    end

    local ok, handle = pcall(http.get, url)
    if not ok or not handle then
        return nil, "Could not reach GitHub raw file."
    end

    local raw = handle.readAll()
    handle.close()

    if not raw or raw == "" then
        return nil, "Downloaded file was empty."
    end

    return raw, nil
end

local function parseRemoteVersion(raw)
    local quoted = raw:match("version%s*=%s*([\"'])([%w%.%-_]+)%1")
    if quoted then return quoted end

    local numeric = raw:match("version%s*=%s*(%d+[%d%.]*)")
    if numeric then return numeric end

    return nil
end

local function validateUpdate(raw)
    if type(raw) ~= "string" then return false, "Bad download." end
    if not raw:find("XenitChat", 1, true) then return false, "Remote file is not XenitChat." end
    if not raw:find("local APP%s*=") then return false, "Remote file has no APP block." end
    if not raw:find("boot%(%s*%)") then return false, "Remote file has no boot call." end

    local loader = loadstring or load
    if loader then
        local ok, err = pcall(loader, raw)
        if not ok or not err then
            return false, "Remote Lua syntax check failed."
        end
    end

    return true, nil
end

local function installUpdate(raw, remoteVersion, targetKey)
    local path = getProgramPath()
    local backup = path .. ".bak"
    targetKey = targetKey or state.current or "global"

    if fs.exists(path) then
        local current = readText(path) or ""
        writeText(backup, current)
    end

    writeText(path, raw)
    systemMessage("Updated XenitChat to v" .. tostring(remoteVersion) .. ". Restart the script to use it.", targetKey)
    systemMessage("Backup saved as " .. backup, targetKey)
end

local function checkForUpdate(auto, install, force, targetKey)
    targetKey = targetKey or state.current or "global"

    if state.updateBusy then
        if not auto then systemMessage("Update check already running.", targetKey) end
        return
    end

    state.updateBusy = true

    if not auto then
        systemMessage("Checking GitHub for updates...", targetKey)
    end

    local raw, err = httpRead(APP.updateUrl)
    if not raw then
        if not auto then systemMessage("Update failed: " .. tostring(err), targetKey) end
        state.updateBusy = false
        return
    end

    local remoteVersion = parseRemoteVersion(raw)
    if not remoteVersion then
        if not auto then systemMessage("Update failed: could not read remote version.", targetKey) end
        state.updateBusy = false
        return
    end

    if compareVersions(remoteVersion, appVersion()) <= 0 and not force then
        if not auto then systemMessage("Already up to date. Local v" .. appVersion() .. ", GitHub v" .. tostring(remoteVersion) .. ".", targetKey) end
        state.updateBusy = false
        return
    end

    local ok, reason = validateUpdate(raw)
    if not ok then
        systemMessage("Update blocked: " .. tostring(reason), targetKey)
        state.updateBusy = false
        return
    end

    if install then
        installUpdate(raw, remoteVersion, targetKey)
    else
        systemMessage("Update available: v" .. tostring(remoteVersion) .. " on GitHub. Type /update install.", targetKey)
    end

    state.updateBusy = false
end

local function openUpdateModal()
    state.modal = "update"
    state.modalInput = ""
    state.modalData = nil
end

-- ============================================================
-- Actions
-- ============================================================

local setError

local function requestDiscovery()
    state.discover = {}

    for key, c in pairs(state.convos) do
        if c.type == "public" and c.listed ~= false and c.private ~= true and not state.leftGroups[key] then
            state.discover[key] = {
                key = key,
                title = c.title or key,
                owner = c.owner or "unknown"
            }
        end
    end

    state.modal = "discover"
    state.modalInput = ""

    broadcast("discover", {
        want = "public_groups"
    })
end

local function createGroup(name, mode)
    if not name or name == "" then return end

    local title = cleanGroupTitle(name)
    if title == "" then return end

    local key = title:gsub("%s+", "_")
    local private = mode == "private" or mode == "unlisted"
    local listed = mode ~= "unlisted"
    local kind = private and "private_group" or "public"

    state.leftGroups[key] = nil
    ensureConvo(key, title, kind, private, listed, state.username)
    switchConvo(key)

    systemMessage("Created group #" .. title, key)

    broadcast("channel_create", {
        key = key,
        title = title,
        private = private,
        listed = listed
    })
end

local function joinGroup(name)
    if not name or name == "" then return end

    local title = cleanGroupTitle(name)
    if title == "" then return end

    local key = title:gsub("%s+", "_")
    state.leftGroups[key] = nil
    ensureConvo(key, title, "public", false, true, "unknown")
    switchConvo(key)

    broadcast("join", {
        key = key
    })
end

local function renameGroupLocal(key, newTitle, byName)
    local c = state.convos[key]
    if not canManageGroup(c) then return false end

    newTitle = cleanGroupTitle(newTitle)
    if newTitle == "" then return false end

    local oldTitle = c.title or c.key
    c.title = newTitle
    c.renamedBy = byName or state.username or "unknown"
    savePrefs()

    if oldTitle ~= newTitle then
        systemMessage(tostring(c.renamedBy) .. " renamed the group to #" .. newTitle .. ".", key)
    end

    return true
end

local function renameCurrentGroup(newTitle)
    local c = state.convos[state.current]

    if not canManageGroup(c) then
        setError("Open a group first. Global and DMs cannot be renamed.")
        return
    end

    if renameGroupLocal(c.key, newTitle, myName()) then
        broadcast("channel_rename", {
            key = c.key,
            title = cleanGroupTitle(newTitle)
        })
    else
        setError("Group name cannot be empty.")
    end
end

local function leaveCurrentGroup()
    local c = state.convos[state.current]

    if not canManageGroup(c) then
        setError("Open a group first. Global and DMs cannot be left.")
        return
    end

    local key = c.key
    local title = c.title or key
    state.leftGroups[key] = true
    state.convos[key] = nil
    state.messages[key] = nil
    state.discover[key] = nil
    state.current = "global"
    savePrefs()

    broadcast("channel_leave", {
        key = key
    })

    systemMessage("Left group #" .. title .. ".", "global")
end

local function openGroupSettings()
    state.modal = "group_settings"
    state.modalInput = ""
    state.modalData = nil
end

local function openRenameGroup()
    local c = state.convos[state.current]
    if not canManageGroup(c) then
        setError("Open a group first. Global and DMs cannot be renamed.")
        return
    end

    state.modal = "group_rename"
    state.modalInput = c.title or c.key
    state.modalData = nil
end

local function sendReadReceipt(publicId)
    if not publicId then return end

    broadcast("read", {
        toPublicId = publicId
    })
end

local function openPM(publicId, user)
    if not user and publicId then
        user = state.users[publicId]
    end

    local title = peerDisplayName(publicId, user and user.username or "Unknown")
    local key = pmKeyFor(publicId, title)
    ensureConvo(key, title, "pm", true, false, title, publicId)
    switchConvo(key)
    sendReadReceipt(publicId)
end

local sendFriendRequest
local blockUser
local unblockUser
local logout
local shutdownApp
local openAppControls

local function markAllRead()
    for _, c in pairs(state.convos or {}) do
        c.unread = 0
    end
    savePrefs()
    systemMessage("Marked all chats as read.")
end

local function togglePinCurrent()
    local c = state.convos[state.current]
    if not c then return end
    if c.key == "global" then
        systemMessage("Global is always at the top.")
        return
    end
    state.pinned = state.pinned or {}
    state.pinned[c.key] = not state.pinned[c.key] or nil
    savePrefs()
    systemMessage((state.pinned[c.key] and "Pinned " or "Unpinned ") .. chatLabel(c, true) .. ".")
end

local function listOnlineUsers()
    local list = getSortedUsers()
    if #list == 0 then
        systemMessage("No online users found.")
        return
    end

    local names = {}
    for i = 1, math.min(#list, 8) do
        local u = list[i]
        table.insert(names, displayName(u.username, u.publicId, u.profile) .. "#" .. shortId(u.publicId))
    end

    if #list > #names then
        table.insert(names, "+" .. tostring(#list - #names) .. " more")
    end

    systemMessage("Online: " .. table.concat(names, ", "))
end

local function resolveBlocked(value)
    value = tostring(value or "")
    if value == "" then return nil end

    for publicId, _ in pairs(state.blocked or {}) do
        local info = (state.blockedInfo and state.blockedInfo[publicId]) or {}
        local shown = displayName(info.username or "blocked", publicId, info.profile or {})
        if shortId(publicId):lower() == value:lower() or publicId:sub(1, #value):lower() == value:lower() or shown:lower() == value:lower() or tostring(info.username or ""):lower() == value:lower() then
            return publicId
        end
    end

    return nil
end

local function showMyId()
    systemMessage("Your ID: " .. shortId(state.publicId) .. "  | Protocol " .. protocolName() .. "/" .. tostring(protocolVersion()))
end

local function toggleQuietVersionWarnings()
    state.quietVersionWarnings = not state.quietVersionWarnings
    savePrefs()
    systemMessage("Version warning noise filter: " .. (state.quietVersionWarnings and "ON" or "OFF") .. ".")
end

local function toggleOldClientCompat()
    state.allowOldClients = not state.allowOldClients
    savePrefs()
    if state.allowOldClients then
        systemMessage("Talk to older clients: ON (BUGGY). Some messages may duplicate, miss fields, or render weirdly.")
    else
        systemMessage("Talk to older clients: OFF. Only matching protocol clients are accepted.")
    end
end

local function showVersionInfo()
    systemMessage("XenitChat v" .. appVersion() .. " | Protocol " .. protocolName() .. " #" .. tostring(protocolVersion()) .. " | Older clients: " .. (state.allowOldClients and "ON (BUGGY)" or "OFF"))
end

local function openSettingsModal()
    state.modal = "settings"
    state.modalInput = ""
    state.modalData = nil
end

local function handleSlashCommand(body)
    if body:sub(1, 1) ~= "/" then return false end

    local command, rest = body:match("^/(%S+)%s*(.*)$")
    command = command and command:lower() or ""
    rest = rest or ""

    if command == "help" or command == "?" then
        state.modal = "help"
    elseif command == "menu" then
        openMainMenu()
    elseif command == "chats" then
        openChatsModal()
    elseif command == "people" or command == "friends" then
        state.modal = "people"
    elseif command == "inbox" then
        state.modal = "friend_inbox"
    elseif command == "blocked" then
        state.modal = "blocked"
    elseif command == "requests" then
        state.modal = "friend_inbox"
    elseif command == "theme" then
        state.modal = "theme"
    elseif command == "settings" or command == "prefs" then
        openSettingsModal()
    elseif command == "discover" or command == "d" then
        requestDiscovery()
    elseif command == "update" then
        local mode = rest:lower()
        if mode == "install" or mode == "now" then
            checkForUpdate(false, true, false, state.current)
        elseif mode == "force" then
            checkForUpdate(false, true, true, state.current)
        else
            checkForUpdate(false, false, false, state.current)
        end
    elseif command == "who" or command == "online" then
        listOnlineUsers()
    elseif command == "id" or command == "myid" then
        showMyId()
    elseif command == "read" or command == "readall" then
        markAllRead()
    elseif command == "pin" or command == "unpin" then
        togglePinCurrent()
    elseif command == "quiet" then
        toggleQuietVersionWarnings()
    elseif command == "compat" or command == "legacy" or command == "oldclients" then
        toggleOldClientCompat()
    elseif command == "version" or command == "about" then
        showVersionInfo()
    elseif command == "sync" or command == "history" then
        local count = 0
        for publicId, u in pairs(state.users or {}) do
            if u.senderId then
                requestHistorySync(u.senderId, publicId)
                count = count + 1
            end
        end
        systemMessage("History sync requested from " .. tostring(count) .. " online peer(s).")
    elseif command == "join" then
        if rest ~= "" then joinGroup(rest) else systemMessage("Usage: /join group_name") end
    elseif command == "new" or command == "group" then
        if rest ~= "" then createGroup(rest, "public") else systemMessage("Usage: /new group_name") end
    elseif command == "rename" then
        if rest ~= "" then renameCurrentGroup(rest) else systemMessage("Usage: /rename new group name") end
    elseif command == "leave" then
        leaveCurrentGroup()
    elseif command == "info" or command == "chatsettings" then
        openGroupSettings()
    elseif command == "pm" or command == "msg" then
        local id, user = resolveUser(rest)
        if id then openPM(id, user) else systemMessage("User not found online.") end
    elseif command == "add" or command == "friend" then
        local id, user = resolveUser(rest)
        if id and user then sendFriendRequest(id, user) else systemMessage("User not found online.") end
    elseif command == "block" then
        local id, user = resolveUser(rest)
        if id then blockUser(id, user) systemMessage("Blocked " .. displayName(user.username, id, user.profile) .. ".") else systemMessage("User not found online.") end
    elseif command == "unblock" then
        local id = resolveBlocked(rest)
        if id then unblockUser(id) systemMessage("Unblocked " .. shortId(id) .. ".") else systemMessage("Blocked user not found.") end
    elseif command == "status" then
        state.profile.status = rest ~= "" and trim(rest, 40) or "Available"
        savePrefs()
        broadcast("hello", {})
        systemMessage("Status updated.")
    elseif command == "name" then
        state.profile.display = rest ~= "" and trim(rest, 24) or state.username
        savePrefs()
        broadcast("hello", {})
        systemMessage("Display name updated.")
    elseif command == "clear" then
        clearCurrentChat()
    elseif command == "app" or command == "controls" then
        openAppControls()
    elseif command == "exit" or command == "quit" or command == "close" then
        shutdownApp("exit")
    elseif command == "restart" or command == "reload" then
        shutdownApp("restart")
    elseif command == "reboot" then
        shutdownApp("reboot")
    elseif command == "logout" then
        logout()
    else
        systemMessage("Unknown command. Try /help.")
    end

    state.input = ""
    return true
end

local function sendChat()
    local body = clampMessage(state.input)

    if body == "" then return end
    if handleSlashCommand(body) then return end

    local c = state.convos[state.current] or {}
    local msgId = randomToken(10)

    addMessage(state.current, myName(), body, c.type == "pm" and "pm" or "chat", {
        msgId = msgId,
        outgoing = true
    })

    if c.type == "pm" then
        if not c.peerId then
            systemMessage("Cannot send: this DM has no valid user ID.")
        else
            broadcast("pm", {
                toPublicId = c.peerId,
                toName = c.title,
                body = body,
                msgId = msgId
            })
        end
    else
        broadcast("chat", {
            key = state.current,
            title = c.title or state.current,
            private = c.private or false,
            listed = c.listed ~= false,
            body = body,
            msgId = msgId
        })
    end

    state.input = ""
end

local function cleanRequests(publicId)
    if not publicId then return end

    if state.friendRequests then
        if state.friendRequests.inbox then state.friendRequests.inbox[publicId] = nil end
        if state.friendRequests.sent then state.friendRequests.sent[publicId] = nil end
    end
end

local function requestRecord(publicId, user, status)
    user = user or state.users[publicId] or {}

    return {
        username = user.username or "unknown",
        profile = user.profile or {},
        time = os.time(),
        status = status or "pending"
    }
end

local function addFriendDirect(publicId, user)
    if not publicId then return end

    user = user or state.users[publicId] or {}

    state.friends[publicId] = {
        username = user.username or "unknown",
        profile = user.profile or {},
        added = os.time()
    }

    cleanRequests(publicId)
    savePrefs()
end

function sendFriendRequest(publicId, user)
    if not publicId or not user then return end

    if state.blocked[publicId] then
        setError("Unblock this user before adding them.")
        return
    end

    if state.friends[publicId] then
        setError("Already friends.")
        return
    end

    if state.friendRequests.inbox[publicId] then
        setError("They already sent you a request. Open Inbox to accept.")
        return
    end

    state.friendRequests.sent[publicId] = requestRecord(publicId, user, "sent")
    savePrefs()

    broadcast("friend_request", {
        toPublicId = publicId
    })

    systemMessage("Friend request sent to " .. displayName(user.username, publicId, user.profile) .. ".")
end

local function acceptFriendRequest(publicId, user)
    if not publicId then return end

    addFriendDirect(publicId, user)

    broadcast("friend_accept", {
        toPublicId = publicId
    })

    systemMessage("Friend request accepted.")
end

local function declineFriendRequest(publicId)
    if not publicId then return end

    cleanRequests(publicId)
    savePrefs()

    broadcast("friend_decline", {
        toPublicId = publicId
    })

    systemMessage("Friend request declined.")
end

local function cancelFriendRequest(publicId)
    if not publicId then return end

    if state.friendRequests and state.friendRequests.sent then
        state.friendRequests.sent[publicId] = nil
    end

    savePrefs()

    broadcast("friend_cancel", {
        toPublicId = publicId
    })

    systemMessage("Friend request cancelled.")
end

local function unfriendUser(publicId)
    if not publicId then return end

    state.friends[publicId] = nil
    cleanRequests(publicId)
    savePrefs()

    broadcast("unfriend", {
        toPublicId = publicId
    })
end

blockUser = function(publicId)
    if not publicId then return end

    local user = state.users[publicId] or {}
    state.blocked[publicId] = true
    state.blockedInfo[publicId] = requestRecord(publicId, user, "blocked")
    state.friends[publicId] = nil
    cleanRequests(publicId)
    savePrefs()
end

unblockUser = function(publicId)
    if not publicId then return end

    state.blocked[publicId] = nil
    state.blockedInfo[publicId] = nil
    savePrefs()
end

function setError(message)
    state.modal = "error"
    state.modalInput = tostring(message or "Error")
end

local function finishLogin(username, account, remembered)
    state.username = username
    state.publicId = account.publicId

    if not state.profile.display or state.profile.display == "" then
        state.profile.display = username
    end

    state.screen = "chat"
    state.focus = "message"
    state.input = ""
    state.password = ""

    if state.remember then
        savePrefs()
    end

    broadcast("hello", {
        current = state.current
    })

    if not state.updateChecked then
        state.updateChecked = true
        checkForUpdate(true, true, false)
    end
end

local function login()
    local accounts = loadAccounts()
    local username = state.input
    local password = state.password

    if username == "" or password == "" then
        setError("Username and password required.")
        return
    end

    local account = accounts[username]

    if not account then
        setError("Account does not exist.")
        return
    end

    local ok, reason = verifyAccount(username, account)

    if not ok then
        setError(reason)
        return
    end

    if passwordHash(password, account.salt) ~= account.passHash then
        setError("Invalid password.")
        return
    end

    finishLogin(username, account, false)
end

local function register()
    local accounts = loadAccounts()
    local username = state.input
    local password = state.password

    if username == "" or password == "" then
        setError("Username and password required.")
        return
    end

    if username:find("%s") then
        setError("No spaces in username.")
        return
    end

    if #password < 4 then
        setError("Password needs 4+ chars.")
        return
    end

    if accounts[username] then
        setError("Account already exists.")
        return
    end

    local account = buildAccount(username, password)

    accounts[username] = account
    saveAccounts(accounts)

    state.profile.display = username
    finishLogin(username, account, false)
end

local function tryRememberLogin()
    if not state.remember then return false end

    local username = readSerialized(APP.prefsFile, {}).username

    if not username then return false end

    local accounts = loadAccounts()
    local account = accounts[username]

    if not account then return false end

    local ok = verifyAccount(username, account)

    if not ok then return false end

    finishLogin(username, account, true)
    return true
end

function logout()
    state.username = nil
    state.publicId = nil
    state.screen = "login"
    state.focus = "username"
    state.input = ""
    state.password = ""
    state.modal = nil
    state.modalInput = ""

    if not state.remember then
        savePrefs()
    else
        local data = readSerialized(APP.prefsFile, defaultPrefs())
        data.username = nil
        writeSerialized(APP.prefsFile, data)
    end
end

function openAppControls()
    state.modal = "app_controls"
    state.modalInput = ""
    state.modalData = nil
end

function shutdownApp(mode)
    mode = tostring(mode or "exit")

    if mode == "logout" then
        logout()
        return
    end

    if mode == "reboot" then
        savePrefs()
        if saveHistory then saveHistory() end
        clear()
        reset()
        if type(term.setCursorBlink) == "function" then term.setCursorBlink(false) end
        os.reboot()
        return
    end

    state.restartRequested = mode == "restart"
    state.exitReason = mode
    state.running = false
    state.modal = nil
    state.modalInput = ""

    savePrefs()
    if saveHistory then saveHistory() end

    -- Wake any blocking pullEvent/rednet loop quickly so the app can close cleanly.
    if type(os.queueEvent) == "function" then
        os.queueEvent("xenitchat_shutdown")
    end
end


-- ============================================================
-- Buffered rendering (reduces CraftOS-PC flicker)
-- ============================================================

local renderBuffer = {
    parent = nil,
    win = nil,
    width = 0,
    height = 0
}

local function beginBufferedDraw()
    if type(window) ~= "table" or type(window.create) ~= "function" then
        return nil, nil
    end

    if type(term.current) ~= "function" or type(term.redirect) ~= "function" then
        return nil, nil
    end

    local parent = term.current()
    local tw, th = term.getSize()

    if not renderBuffer.win or renderBuffer.parent ~= parent or renderBuffer.width ~= tw or renderBuffer.height ~= th then
        renderBuffer.parent = parent
        renderBuffer.width = tw
        renderBuffer.height = th
        renderBuffer.win = window.create(parent, 1, 1, tw, th, false)
    end

    if renderBuffer.win and type(renderBuffer.win.setVisible) == "function" then
        renderBuffer.win.setVisible(false)
    end

    term.redirect(renderBuffer.win)
    return parent, renderBuffer.win
end

local function endBufferedDraw(parent, win)
    if parent then
        term.redirect(parent)
    end

    if win and type(win.setVisible) == "function" then
        win.setVisible(true)
    end
end

-- ============================================================
-- Draw login
-- ============================================================

local function drawLogin(registerMode)
    clearClickable()
    clear()

    fill(1, 1, w, h, T().bg)

    local compact = w < 38 or h < 16
    local titleY = compact and 1 or 2
    center(titleY, APP.name, T().accent, T().bg)
    if not compact and h >= 14 then
        center(titleY + 1, APP.slogan, T().muted, T().bg)
    end

    local panelW = math.min(compact and w or 42, math.max(1, w - (compact and 0 or 4)))
    local panelH = compact and math.min(10, h - 2) or math.min(12, h - 5)
    if panelH < 8 then panelH = math.min(h, 8) end

    local panelX = math.floor((w - panelW) / 2) + 1
    local panelY
    if compact then
        panelY = math.max(2, math.floor((h - panelH) / 2) + 1)
    else
        panelY = math.max(5, math.floor((h - panelH) / 2) + 1)
    end

    if panelY + panelH - 1 > h then panelY = math.max(1, h - panelH + 1) end

    fill(panelX, panelY, panelW, panelH, T().panel)

    local labelW = compact and 5 or 10
    local inputX = panelX + labelW + 2
    local inputW = math.max(4, panelW - labelW - 3)

    text(panelX + 1, panelY + 1, registerMode and "Create account" or "Welcome back", T().text, T().panel)

    text(panelX + 1, panelY + 3, compact and "User" or "Username", T().muted, T().panel)
    fill(inputX, panelY + 3, inputW, 1, state.focus == "username" and colors.white or T().muted)
    text(inputX + 1, panelY + 3, trim(state.input, math.max(1, inputW - 2)), colors.black, state.focus == "username" and colors.white or T().muted)

    text(panelX + 1, panelY + 5, compact and "Pass" or "Password", T().muted, T().panel)
    fill(inputX, panelY + 5, inputW, 1, state.focus == "password" and colors.white or T().muted)
    text(inputX + 1, panelY + 5, trim(string.rep("*", #state.password), math.max(1, inputW - 2)), colors.black, state.focus == "password" and colors.white or T().muted)

    local buttonY = panelY + panelH - 3
    local rememberY = panelY + panelH - 2
    if panelH <= 9 then
        buttonY = panelY + 7
        rememberY = panelY + 8
    end

    local gap = panelW < 30 and 1 or 2
    local half = math.floor((panelW - 2 - gap) / 2)
    local bx = panelX + 1

    if registerMode then
        addButton("register", bx, buttonY, half, compact and "Create" or "Register", colors.black, T().good, register)
        addButton("back", bx + half + gap, buttonY, panelW - half - gap - 2, "Back", colors.white, T().danger, function()
            state.screen = "login"
            state.input = ""
            state.password = ""
            state.modal = nil
        end)
    else
        addButton("login", bx, buttonY, half, "Login", colors.black, T().good, login)
        addButton("new", bx + half + gap, buttonY, panelW - half - gap - 2, compact and "New" or "Register", colors.black, T().accent, function()
            state.screen = "register"
            state.input = ""
            state.password = ""
            state.modal = nil
        end)
    end

    if rememberY <= panelY + panelH - 1 then
        addButton("remember", panelX + 1, rememberY, panelW - 2, state.remember and "Remember: ON" or "Remember: OFF", colors.black, state.remember and T().accent or T().muted, function()
            state.remember = not state.remember
            savePrefs()
        end)
    end

    if state.modal == "error" then
        text(1, h, trim(state.modalInput, w), T().danger, T().bg)
    else
        text(1, h, trim("TAB field | ENTER continue", w), T().muted, T().bg)
    end
end

-- ============================================================
-- Modals
-- ============================================================


local function closeModal()
    state.modal = nil
    state.modalInput = ""
    state.modalData = nil
end

local function modalHeader(mx, my, mw, title, subtitle, closeAction)
    local th = T()
    fill(mx, my, mw, 1, th.top or th.accent)
    text(mx + 1, my, trim(title or "", math.max(1, mw - 6)), colors.white, th.top or th.accent)

    if mw >= 7 then
        addButton("modal_x", mx + mw - 2, my, 2, "X", colors.white, th.danger or colors.red, closeAction or closeModal)
    end

    if subtitle and subtitle ~= "" and my + 1 <= h then
        text(mx + 1, my + 1, trim(subtitle, mw - 2), colors.gray, colors.lightGray)
    end
end

local function modalDivider(mx, y, mw)
    if y >= 1 and y <= h then
        fill(mx + 1, y, math.max(0, mw - 2), 1, colors.gray)
    end
end

local function modalBox(width, height)
    local marginX = w <= 30 and 0 or 2
    local marginY = h <= 14 and 0 or 1
    local maxW = math.max(1, w - marginX * 2)
    local maxH = math.max(1, h - marginY * 2)

    local wantedW = tonumber(width) or maxW
    local wantedH = tonumber(height) or maxH

    local mw = math.min(math.max(18, wantedW), maxW)
    local mh = math.min(math.max(5, wantedH), maxH)

    if w < 18 then mw = maxW end
    if h < 8 then mh = maxH end

    local mx = math.floor((w - mw) / 2) + 1
    local my = math.floor((h - mh) / 2) + 1

    fill(mx, my, mw, mh, colors.lightGray)

    -- Soft terminal-friendly border: enough structure without wasting space.
    if mw >= 20 and mh >= 6 then
        fill(mx, my + mh - 1, mw, 1, colors.gray)
    end

    return mx, my, mw, mh
end

local function drawCreateModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, isPocket() and 11 or 9)

    modalHeader(mx, my, mw, "New group", nil)
    text(mx + 1, my + 3, "Name:", colors.black, colors.lightGray)
    fill(mx + 7, my + 3, mw - 8, 1, colors.white)
    text(mx + 8, my + 3, trim(state.modalInput, mw - 10), colors.black, colors.white)

    local mode = state.modalMode or "public"

    if isPocket() then
        addButton("mode_public", mx + 1, my + 5, mw - 2, mode == "public" and "[Public]" or "Public", colors.black, mode == "public" and T().good or colors.gray, function()
            state.modalMode = "public"
        end)

        addButton("mode_private", mx + 1, my + 6, mw - 2, mode == "private" and "[Private]" or "Private", colors.black, mode == "private" and T().warn or colors.gray, function()
            state.modalMode = "private"
        end)

        addButton("mode_unlisted", mx + 1, my + 7, mw - 2, mode == "unlisted" and "[Unlisted]" or "Unlisted", colors.black, mode == "unlisted" and colors.purple or colors.gray, function()
            state.modalMode = "unlisted"
        end)

        addButton("create_ok", mx + 1, my + 9, 10, "Create", colors.black, T().good, function()
            createGroup(state.modalInput, state.modalMode)
            state.modal = nil
            state.modalInput = ""
        end)

        addButton("create_cancel", mx + mw - 10, my + 9, 10, "Cancel", colors.white, T().danger, function()
            state.modal = nil
            state.modalInput = ""
        end)

        return
    end

    local btnW = math.floor((mw - 6) / 3)

    addButton("mode_public", mx + 2, my + 5, btnW, "Public", colors.black, mode == "public" and T().good or colors.gray, function()
        state.modalMode = "public"
    end)

    addButton("mode_private", mx + 3 + btnW, my + 5, btnW, "Private", colors.black, mode == "private" and T().warn or colors.gray, function()
        state.modalMode = "private"
    end)

    addButton("mode_unlisted", mx + 4 + btnW * 2, my + 5, btnW, "Unlisted", colors.black, mode == "unlisted" and colors.purple or colors.gray, function()
        state.modalMode = "unlisted"
    end)

    addButton("create_ok", mx + 2, my + 7, 13, "Create", colors.black, T().good, function()
        createGroup(state.modalInput, state.modalMode)
        state.modal = nil
        state.modalInput = ""
    end)

    addButton("create_cancel", mx + mw - 15, my + 7, 13, "Cancel", colors.white, T().danger, function()
        state.modal = nil
        state.modalInput = ""
    end)
end

local function drawDiscoverModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 50, isPocket() and 11 or 13)

    modalHeader(mx, my, mw, "Discover", "Public groups on the network")

    local list = {}

    for key, c in pairs(state.discover) do
        table.insert(list, c)
    end

    for key, c in pairs(state.convos) do
        if c.type == "public" and c.listed ~= false then
            table.insert(list, {
                key = key,
                title = c.title or key,
                owner = c.owner or "unknown"
            })
        end
    end

    local seen = {}
    local unique = {}

    for _, c in ipairs(list) do
        if c.key and not seen[c.key] then
            seen[c.key] = true
            table.insert(unique, c)
        end
    end

    table.sort(unique, function(a, b)
        return tostring(a.title) < tostring(b.title)
    end)

    local maxRows = mh - 5

    if #unique == 0 then
        text(mx + 1, my + 3, "No groups found.", colors.gray, colors.lightGray)
        text(mx + 1, my + 4, "Try Refresh.", colors.gray, colors.lightGray)
    else
        for i = 1, math.min(#unique, maxRows) do
            local c = unique[i]
            local label = "#" .. tostring(c.title or c.key)

            if c.owner and c.owner ~= "unknown" then
                label = label .. " by " .. tostring(c.owner)
            end

            addButton("disc_" .. tostring(i), mx + 1, my + 2 + i, mw - 2, trim(label, mw - 2), colors.black, colors.white, function()
                joinGroup(c.key or c.title)
                state.modal = nil
                state.modalInput = ""
            end)
        end
    end

    addButton("disc_refresh", mx + 1, my + mh - 1, 10, "Refresh", colors.black, T().accent, requestDiscovery)
    addButton("disc_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, T().danger, function()
        state.modal = nil
        state.modalInput = ""
    end)
end

local function drawPMModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, isPocket() and 7 or 8)

    modalHeader(mx, my, mw, "Direct message", nil)
    text(mx + 1, my + 3, "Name/ID:", colors.black, colors.lightGray)
    fill(mx + 10, my + 3, mw - 11, 1, colors.white)
    text(mx + 11, my + 3, trim(state.modalInput, mw - 13), colors.black, colors.white)

    text(mx + 1, my + 4, "Search username or short ID", colors.gray, colors.lightGray)

    addButton("pm_next", mx + 1, my + mh - 1, 8, "Open", colors.black, T().good, function()
        local id, user = resolveUser(state.modalInput)

        if id then
            openPM(id, user)
            state.modal = nil
            state.modalInput = ""
        else
            setError("User not found online.")
        end
    end)

    addButton("pm_cancel", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, T().danger, function()
        state.modal = nil
        state.modalInput = ""
    end)
end

local function drawPeopleModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 50, isPocket() and 11 or 13)

    modalHeader(mx, my, mw, "People", "o online  * friend  ! request  ? sent")

    local list = getSortedUsers()
    local maxRows = mh - 5

    if #list == 0 then
        text(mx + 1, my + 3, "Nobody online yet.", colors.gray, colors.lightGray)
    else
        for i = 1, math.min(#list, maxRows) do
            local u = list[i]
            local name = displayName(u.username, u.publicId, u.profile)
            local rel = " "
            if state.friends[u.publicId] then
                rel = "*"
            elseif state.friendRequests.inbox[u.publicId] then
                rel = "!"
            elseif state.friendRequests.sent[u.publicId] then
                rel = "?"
            end

            local online = os.clock() - (u.lastSeenClock or 0) <= APP.onlineTimeout and "o" or "-"
            local label = online .. rel .. " " .. name .. " #" .. shortId(u.publicId)

            addButton("person_" .. tostring(i), mx + 1, my + 2 + i, mw - 2, trim(label, mw - 2), colors.black, colors.white, function()
                state.modal = "user_info"
                state.modalData = {
                    publicId = u.publicId,
                    user = state.users[u.publicId]
                }
            end)
        end
    end

    addButton("people_add", mx + 1, my + mh - 1, 8, "Search", colors.black, T().accent, function()
        state.modal = "friend_search"
        state.modalInput = ""
    end)

    addButton("people_inbox", mx + 10, my + mh - 1, 8, "Inbox", colors.black, T().warn, function()
        state.modal = "friend_inbox"
    end)

    addButton("people_blocked", mx + 19, my + mh - 1, 8, "Blocked", colors.white, T().danger, function()
        state.modal = "blocked"
    end)

    addButton("people_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, colors.gray, function()
        state.modal = nil
    end)
end


local function drawFriendInboxModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 52, isPocket() and 12 or 14)

    modalHeader(mx, my, mw, "Friend inbox", "! incoming  |  ? sent")

    local rows = {}

    for publicId, r in pairs(state.friendRequests.inbox or {}) do
        table.insert(rows, {
            publicId = publicId,
            record = r,
            dir = "in"
        })
    end

    for publicId, r in pairs(state.friendRequests.sent or {}) do
        table.insert(rows, {
            publicId = publicId,
            record = r,
            dir = "out"
        })
    end

    table.sort(rows, function(a, b)
        return (a.record.time or 0) > (b.record.time or 0)
    end)

    local maxRows = mh - 6

    if #rows == 0 then
        text(mx + 1, my + 4, "No pending friend requests.", colors.gray, colors.lightGray)
    else
        for i = 1, math.min(#rows, maxRows) do
            local r = rows[i]
            local user = state.users[r.publicId] or r.record or {}
            local name = displayName(user.username or r.record.username, r.publicId, user.profile or r.record.profile)
            local label = (r.dir == "in" and "! " or "? ") .. name .. " #" .. shortId(r.publicId)

            addButton("fr_row_" .. tostring(i), mx + 1, my + 3 + i, mw - 2, trim(label, mw - 2), colors.black, colors.white, function()
                state.modal = "user_info"
                state.modalData = {
                    publicId = r.publicId,
                    user = state.users[r.publicId] or r.record
                }
            end)
        end
    end

    addButton("fr_close", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, function()
        state.modal = "people"
    end)
end

local function drawBlockedModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 52, isPocket() and 12 or 14)

    modalHeader(mx, my, mw, "Blocked users", "Click a user to unblock")

    local rows = {}

    for publicId, _ in pairs(state.blocked or {}) do
        table.insert(rows, {
            publicId = publicId,
            record = state.blockedInfo[publicId] or state.users[publicId] or { username = "unknown" }
        })
    end

    table.sort(rows, function(a, b)
        return tostring((a.record and a.record.username) or a.publicId) < tostring((b.record and b.record.username) or b.publicId)
    end)

    local maxRows = mh - 5

    if #rows == 0 then
        text(mx + 1, my + 4, "Nobody is blocked.", colors.gray, colors.lightGray)
    else
        for i = 1, math.min(#rows, maxRows) do
            local r = rows[i]
            local rec = r.record or {}
            local name = displayName(rec.username or "unknown", r.publicId, rec.profile or {})
            local label = name .. " #" .. shortId(r.publicId) .. "  [unblock]"

            addButton("blk_row_" .. tostring(i), mx + 1, my + 2 + i, mw - 2, trim(label, mw - 2), colors.white, T().danger, function()
                unblockUser(r.publicId)
                state.modal = "blocked"
            end)
        end
    end

    addButton("blk_close", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, function()
        state.modal = "people"
    end)
end

local function drawFriendSearchModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, 7)

    modalHeader(mx, my, mw, "Add friend", nil)
    text(mx + 1, my + 3, "Name/ID:", colors.black, colors.lightGray)
    fill(mx + 10, my + 3, mw - 11, 1, colors.white)
    text(mx + 11, my + 3, trim(state.modalInput, mw - 13), colors.black, colors.white)

    addButton("friend_find", mx + 1, my + 5, 8, "Find", colors.black, T().good, function()
        local id, user = resolveUser(state.modalInput)

        if id and user then
            sendFriendRequest(id, user)
            state.modal = "people"
            state.modalInput = ""
        else
            setError("User not found online.")
        end
    end)

    addButton("friend_cancel", mx + mw - 8, my + 5, 8, "Cancel", colors.white, T().danger, function()
        state.modal = "people"
        state.modalInput = ""
    end)
end

local function drawUserInfoModal()
    local data = state.modalData or {}
    local id = data.publicId
    local user = data.user or state.users[id] or {}
    local name = displayName(user.username, id, user.profile)
    local status = (user.profile and user.profile.status) or "Available"

    local mx, my, mw, mh = modalBox(isPocket() and w or 48, isPocket() and 10 or 11)

    modalHeader(mx, my, mw, "User info", nil)
    text(mx + 1, my + 3, trim("Name: " .. name, mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Status: " .. status, mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 5, trim("ID: " .. shortId(id), mw - 2), colors.gray, colors.lightGray)

    local friendLabel = "Request"

    if state.friends[id] then
        friendLabel = "Unfriend"
    elseif state.friendRequests.inbox[id] then
        friendLabel = "Accept"
    elseif state.friendRequests.sent[id] then
        friendLabel = "Cancel"
    end

    local blockLabel = state.friendRequests.inbox[id] and "Decline" or (state.blocked[id] and "Unblock" or "Block")

    local by = my + mh - 2

    addButton("ui_pm", mx + 1, by, 7, "PM", colors.black, T().accent, function()
        openPM(id, user)
        state.modal = nil
    end)

    addButton("ui_friend", mx + 9, by, 10, friendLabel, colors.black, T().good, function()
        if state.friends[id] then
            unfriendUser(id)
        elseif state.friendRequests.inbox[id] then
            acceptFriendRequest(id, user)
            state.modal = "people"
        elseif state.friendRequests.sent[id] then
            cancelFriendRequest(id)
            state.modal = "people"
        else
            sendFriendRequest(id, user)
            state.modal = "people"
        end
    end)

    addButton("ui_block", mx + 20, by, 8, blockLabel, colors.white, T().danger, function()
        if state.friendRequests.inbox[id] then
            declineFriendRequest(id)
            state.modal = "friend_inbox"
        elseif state.blocked[id] then
            unblockUser(id)
            state.modal = "blocked"
        else
            blockUser(id)
            state.modal = "blocked"
        end
    end)

    addButton("ui_close", mx + mw - 8, by, 8, "Close", colors.white, colors.gray, function()
        state.modal = "people"
    end)
end

local function drawProfileModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 46, isPocket() and 8 or 9)

    local title = state.modalMode == "status" and "Set status" or "Set display name"

    modalHeader(mx, my, mw, title, nil)

    fill(mx + 1, my + 3, mw - 2, 1, colors.white)
    text(mx + 2, my + 3, trim(state.modalInput, mw - 4), colors.black, colors.white)

    text(mx + 1, my + 4, "This appears to other users.", colors.gray, colors.lightGray)

    addButton("profile_save", mx + 1, my + mh - 1, 8, "Save", colors.black, T().good, function()
        if state.modalMode == "status" then
            state.profile.status = state.modalInput ~= "" and trim(state.modalInput, 40) or "Available"
        else
            state.profile.display = state.modalInput ~= "" and trim(state.modalInput, 24) or state.username
        end

        savePrefs()
        broadcast("hello", {})
        state.modal = nil
        state.modalInput = ""
    end)

    addButton("profile_next", mx + 10, my + mh - 1, 8, state.modalMode == "status" and "Name" or "Status", colors.black, T().accent, function()
        if state.modalMode == "status" then
            state.modalMode = "profile"
            state.modalInput = state.profile.display or state.username or ""
        else
            state.modalMode = "status"
            state.modalInput = state.profile.status or "Available"
        end
    end)

    addButton("profile_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, T().danger, function()
        state.modal = nil
        state.modalInput = ""
    end)
end


local function drawSettingsModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 54, isPocket() and 12 or 13)

    modalHeader(mx, my, mw, "Settings", "Protocol " .. protocolName() .. " #" .. tostring(protocolVersion()))

    text(mx + 1, my + 3, trim("App version: v" .. appVersion(), mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Protocol codename: " .. protocolName(), mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 5, trim("Compatibility number: " .. tostring(protocolVersion()), mw - 2), colors.gray, colors.lightGray)

    local quietLabel = state.quietVersionWarnings and "Quiet version spam: ON" or "Quiet version spam: OFF"
    local oldLabel = state.allowOldClients and "Talk to older clients: ON (BUGGY)" or "Talk to older clients: OFF"

    addButton("set_quiet", mx + 1, my + 7, mw - 2, quietLabel, colors.black, state.quietVersionWarnings and T().good or colors.gray, toggleQuietVersionWarnings)
    addButton("set_old", mx + 1, my + 8, mw - 2, oldLabel, colors.black, state.allowOldClients and T().warn or colors.white, toggleOldClientCompat)

    text(mx + 1, my + 10, trim("Buggy mode only accepts older protocol packets as best-effort.", mw - 2), colors.red, colors.lightGray)

    addButton("settings_back", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, openMainMenu)
end

local function drawGroupSettingsModal()
    local c = state.convos[state.current]
    local isGroup = canManageGroup(c)
    local mx, my, mw, mh = modalBox(isPocket() and w or 50, isPocket() and 12 or 13)

    modalHeader(mx, my, mw, "Chat settings", nil)

    if not c then
        text(mx + 1, my + 3, "No chat selected.", colors.gray, colors.lightGray)
    elseif c.type == "pm" then
        text(mx + 1, my + 3, trim(chatLabel(c, false), mw - 2), colors.black, colors.lightGray)
        text(mx + 1, my + 4, "This is a direct message.", colors.gray, colors.lightGray)
        text(mx + 1, my + 5, trim("ID: " .. shortId(c.peerId), mw - 2), colors.gray, colors.lightGray)
    elseif c.key == "global" then
        text(mx + 1, my + 3, "#global", colors.black, colors.lightGray)
        text(mx + 1, my + 4, "Global cannot be renamed or left.", colors.gray, colors.lightGray)
    else
        text(mx + 1, my + 3, trim("Group: #" .. tostring(c.title or c.key), mw - 2), colors.black, colors.lightGray)
        text(mx + 1, my + 4, trim("Key: " .. tostring(c.key), mw - 2), colors.gray, colors.lightGray)
        text(mx + 1, my + 5, trim("Owner: " .. tostring(c.owner or "unknown"), mw - 2), colors.gray, colors.lightGray)
        text(mx + 1, my + 6, c.private and "Visibility: private/unlisted" or "Visibility: public", colors.gray, colors.lightGray)
        text(mx + 1, my + 7, "Heads up: group rename is shared.", colors.red, colors.lightGray)
    end

    local by = my + mh - 1

    addButton("grp_pin", mx + 1, by, 7, (state.pinned and state.pinned[state.current]) and "Unpin" or "Pin", colors.black, T().accent, togglePinCurrent)

    if isGroup then
        addButton("grp_rename", mx + 9, by, 9, "Rename", colors.black, T().good, openRenameGroup)
        addButton("grp_leave", mx + 19, by, 8, "Leave", colors.white, T().danger, function()
            leaveCurrentGroup()
            state.modal = nil
        end)
    end

    addButton("grp_back", mx + mw - 8, by, 8, "Back", colors.white, colors.gray, openMainMenu)
end

local function drawGroupRenameModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 46, isPocket() and 8 or 8)

    modalHeader(mx, my, mw, "Rename group", nil)
    text(mx + 1, my + 2, "Everyone may receive this new name.", colors.gray, colors.lightGray)

    fill(mx + 1, my + 4, mw - 2, 1, colors.white)
    text(mx + 2, my + 4, trim(state.modalInput, mw - 4), colors.black, colors.white)

    addButton("rename_ok", mx + 1, my + mh - 1, 8, "Save", colors.black, T().good, function()
        renameCurrentGroup(state.modalInput)
        state.modal = nil
        state.modalInput = ""
    end)

    addButton("rename_cancel", mx + mw - 8, my + mh - 1, 8, "Cancel", colors.white, colors.gray, openGroupSettings)
end

local function drawMainMenuModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, isPocket() and 14 or 15)

    modalHeader(mx, my, mw, "Menu", trim(currentChatTitle() .. "  |  /help", mw - 2))

    local items = {
        { "Chats", openChatsModal, T().good, colors.black },
        { "People", function() state.modal = "people" end, T().warn, colors.black },
        { "Friend Inbox", function() state.modal = "friend_inbox" end, T().accent, colors.black },
        { "Discover Groups", requestDiscovery, T().accent, colors.black },
        { "New Group", function() state.modal = "create" state.modalInput = "" state.modalMode = "public" end, T().good, colors.black },
        { "Chat Settings", openGroupSettings, colors.lightGray, colors.black },
        { (state.pinned and state.pinned[state.current]) and "Unpin Chat" or "Pin Chat", togglePinCurrent, colors.lightGray, colors.black },
        { "Mark All Read", markAllRead, colors.lightGray, colors.black },
        { "Direct Message", function() state.modal = "pm" state.modalInput = "" end, colors.lightGray, colors.black },
        { "History Sync", function()
            local count = 0
            for publicId, u in pairs(state.users or {}) do
                if u.senderId then requestHistorySync(u.senderId, publicId) count = count + 1 end
            end
            state.modal = nil
            systemMessage("History sync requested from " .. tostring(count) .. " online peer(s).")
        end, colors.lightGray, colors.black },
        { "Auto Update", openUpdateModal, colors.lightGray, colors.black },
        { "Profile", function() state.modal = "profile" state.modalMode = "profile" state.modalInput = state.profile.display or state.username or "" end, colors.lightGray, colors.black },
        { "Settings", openSettingsModal, colors.lightGray, colors.black },
        { "App Controls", openAppControls, T().warn, colors.black },
        { "Close App", function() shutdownApp("exit") end, T().danger, colors.white }
    }

    local rowY = my + 3
    local maxRows = mh - 5

    for i = 1, math.min(#items, maxRows) do
        local item = items[i]
        addButton("menu_" .. tostring(i), mx + 1, rowY + i - 1, mw - 2, item[1], item[4], item[3], item[2])
    end

    local fy = my + mh - 1
    local gap = 1
    local bw = math.max(4, math.floor((mw - 2 - gap * 3) / 4))
    addButton("menu_theme", mx + 1, fy, bw, "Theme", colors.black, colors.lightGray, function()
        state.modal = "theme"
    end)
    addButton("menu_settings", mx + 1 + bw + gap, fy, bw, "Settings", colors.black, colors.lightGray, openSettingsModal)
    addButton("menu_help", mx + 1 + (bw + gap) * 2, fy, bw, "Help", colors.black, colors.lightGray, function()
        state.modal = "help"
    end)
    addButton("menu_close", mx + 1 + (bw + gap) * 3, fy, mw - 2 - (bw + gap) * 3, "Close", colors.white, colors.gray, closeModal)
end

local function drawChatsModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 50, isPocket() and 13 or 14)

    modalHeader(mx, my, mw, "Chats", "Select a chat. New messages show a count.")

    local list = getConvoList()
    local maxRows = mh - 6

    if #list == 0 then
        text(mx + 1, my + 4, "No chats yet.", colors.gray, colors.lightGray)
    else
        for i = 1, math.min(#list, maxRows) do
            local c = list[i]
            local label = chatLabel(c, true)
            if (c.unread or 0) > 0 then
                label = label .. "  (" .. tostring(c.unread) .. " new)"
            end
            if c.key == state.current then
                label = "> " .. label
            else
                label = "  " .. label
            end

            addButton("chat_row_" .. tostring(i), mx + 1, my + 2 + i, mw - 2, trim(label, mw - 2), colors.black, c.key == state.current and T().accent or colors.white, function()
                switchConvo(c.key)
                state.modal = nil
            end)
        end
    end

    addButton("chats_new", mx + 1, my + mh - 1, 9, "+ Group", colors.black, T().good, function()
        state.modal = "create"
        state.modalInput = ""
        state.modalMode = "public"
    end)

    addButton("chats_clear", mx + 11, my + mh - 1, 8, "Clear", colors.white, colors.gray, function()
        clearCurrentChat()
        state.modal = nil
    end)

    addButton("chats_close", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, openMainMenu)
end

local function drawHelpModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 54, isPocket() and 13 or 15)

    modalHeader(mx, my, mw, "Help / shortcuts", nil)

    local lines = {
        "ENTER send   TAB next chat   ESC close",
        "/menu  /chats  /people  /inbox",
        "/pm name-or-id     /friend name-or-id",
        "/join group        /new group",
        "/rename name       /leave       /info",
        "/status text       /name display-name",
        "/discover          /theme        /sync",
        "/who  /id  /version  /readall  /pin",
        "/quiet  /compat buggy old-client mode",
        "/block name        /unblock name",
        "/update            /update install",
        "/clear   /logout   /exit   /restart",
        "Chat mark: ^ pinned. People: * friend, ! request, ? sent",
        "Groups: rename is shared; leave stops auto rejoin.",
        "Pocket: use Chats + Menu; avoid tiny buttons."
    }

    local maxRows = mh - 4
    for i = 1, math.min(#lines, maxRows) do
        text(mx + 1, my + 1 + i, trim(lines[i], mw - 2), colors.black, colors.lightGray)
    end

    addButton("help_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, colors.gray, function()
        state.modal = nil
    end)
end


local function drawUpdateModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 50, isPocket() and 10 or 11)

    modalHeader(mx, my, mw, "Auto Update", nil)
    text(mx + 1, my + 3, trim("Source: GitHub benchware/Xenit-Chat", mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Local version: v" .. appVersion() .. " | " .. protocolName(), mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 5, trim("Startup checks install newer versions automatically.", mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 6, trim("Manual: /update or /update install", mw - 2), colors.gray, colors.lightGray)

    local fy = my + mh - 1
    addButton("upd_check", mx + 1, fy, 9, "Check", colors.black, T().accent, function()
        state.modal = nil
        checkForUpdate(false, false, false, state.current)
    end)

    addButton("upd_install", mx + 11, fy, 10, "Install", colors.black, T().good, function()
        state.modal = nil
        checkForUpdate(false, true, false, state.current)
    end)

    addButton("upd_close", mx + mw - 8, fy, 8, "Back", colors.white, colors.gray, openMainMenu)
end

local function drawThemeModal()
    local names = { "midnight", "dark", "ocean", "neon", "graphite", "forest", "sunset", "amethyst", "ice", "clean" }
    local rows = math.min(#names, math.max(3, h - 5))
    local mx, my, mw, mh = modalBox(isPocket() and w or 40, rows + 4)

    modalHeader(mx, my, mw, "Choose theme", nil)

    for i = 1, math.min(#names, mh - 3) do
        local key = names[i]
        local th = THEMES[key]
        local label = state.theme == key and "[" .. th.name .. "]" or th.name

        addButton("theme_" .. key, mx + 1, my + 1 + i, mw - 2, label, colors.black, state.theme == key and T().accent or colors.white, function()
            state.theme = key
            savePrefs()
        end)
    end

    addButton("theme_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, colors.red, function()
        state.modal = nil
    end)
end

local function drawAppControlsModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 46, isPocket() and 12 or 13)

    modalHeader(mx, my, mw, "App controls", "Close, restart, logout, or reboot safely.")

    local y = my + 3
    local function row(id, label, note, bgColor, fgColor, action)
        if y <= my + mh - 2 then
            addButton(id, mx + 1, y, mw - 2, label, fgColor or colors.black, bgColor or colors.white, action)
            if note and note ~= "" and y + 1 <= my + mh - 2 then
                text(mx + 2, y + 1, trim(note, mw - 4), colors.gray, colors.lightGray)
                y = y + 2
            else
                y = y + 1
            end
        end
    end

    row("app_restart", "Restart XenitChat", "Reloads the script after saving prefs/history.", T().good, colors.black, function()
        shutdownApp("restart")
    end)

    row("app_exit", "Close XenitChat", "Returns to the CraftOS shell.", T().warn, colors.black, function()
        shutdownApp("exit")
    end)

    row("app_logout", "Logout", "Go back to the login screen only.", colors.white, colors.black, function()
        logout()
        state.modal = nil
    end)

    if mh >= 12 then
        row("app_reboot", "Reboot computer", "Full CraftOS reboot.", T().danger, colors.white, function()
            shutdownApp("reboot")
        end)
    end

    addButton("app_back", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, openMainMenu)
end

local function drawErrorModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, 5)

    modalHeader(mx, my, mw, "Notice", nil)
    text(mx + 1, my + 2, trim(state.modalInput, mw - 2), colors.red, colors.lightGray)

    addButton("err_ok", mx + math.floor((mw - 8) / 2), my + 4, 8, "OK", colors.black, T().good, function()
        state.modal = nil
        state.modalInput = ""
    end)
end

local function drawModal()
    if state.modal == "main_menu" then
        drawMainMenuModal()
    elseif state.modal == "chats" then
        drawChatsModal()
    elseif state.modal == "help" then
        drawHelpModal()
    elseif state.modal == "settings" then
        drawSettingsModal()
    elseif state.modal == "group_settings" then
        drawGroupSettingsModal()
    elseif state.modal == "group_rename" then
        drawGroupRenameModal()
    elseif state.modal == "create" then
        drawCreateModal()
    elseif state.modal == "discover" then
        drawDiscoverModal()
    elseif state.modal == "pm" then
        drawPMModal()
    elseif state.modal == "people" then
        drawPeopleModal()
    elseif state.modal == "friend_search" then
        drawFriendSearchModal()
    elseif state.modal == "friend_inbox" then
        drawFriendInboxModal()
    elseif state.modal == "blocked" then
        drawBlockedModal()
    elseif state.modal == "user_info" then
        drawUserInfoModal()
    elseif state.modal == "profile" then
        drawProfileModal()
    elseif state.modal == "theme" then
        drawThemeModal()
    elseif state.modal == "update" then
        drawUpdateModal()
    elseif state.modal == "app_controls" then
        drawAppControlsModal()
    elseif state.modal == "error" then
        drawErrorModal()
    end
end

-- ============================================================
-- Draw chat UI
-- ============================================================

local function drawTopBar()
    fill(1, 1, w, 1, T().top)

    local unread = totalUnread()
    local pending = pendingFriendCount()
    local title = currentChatTitle()
    local compact = w < 50

    if compact then
        local left = trim(title, math.max(1, w - 10))
        local right = tostring(onlineCount()) .. " on"
        if pending > 0 then right = "!" .. tostring(pending) end
        if unread > 0 and pending == 0 then right = tostring(unread) .. " new" end

        text(1, 1, left, colors.white, T().top)
        text(math.max(1, w - #right + 1), 1, right, colors.yellow, T().top)
    else
        local left = APP.name .. "  " .. title
        local right = "@" .. myName() .. " | " .. tostring(onlineCount()) .. " online"

        if unread > 0 then right = tostring(unread) .. " unread | " .. right end
        if pending > 0 then right = tostring(pending) .. " requests | " .. right end

        text(2, 1, trim(left, math.max(1, w - #right - 3)), colors.white, T().top)
        text(math.max(1, w - #right), 1, right, colors.yellow, T().top)
    end
end

local function drawConvoList()
    local lw = leftWidth()

    if lw == 0 then
        fill(1, 2, w, 1, T().panel)

        local title = currentChatTitle()
        local menuW = w < 32 and 4 or 6
        local chatsW = w < 32 and 5 or 7
        local reserved = menuW + chatsW + 2

        text(1, 2, trim(title, math.max(1, w - reserved)), colors.black, T().accent)

        addButton("mobile_chats", math.max(1, w - reserved + 1), 2, chatsW, w < 32 and "Chat" or "Chats", colors.black, T().good, openChatsModal)
        addButton("mobile_menu", math.max(1, w - menuW + 1), 2, menuW, w < 32 and "Menu" or "Menu", colors.black, T().accent, openMainMenu)

        return
    end

    fill(1, 2, lw, h - 1, T().panel)
    text(2, 2, "Chats", T().text, T().panel)

    local unread = totalUnread()
    if unread > 0 then
        text(math.max(2, lw - #tostring(unread) - 1), 2, tostring(unread), colors.yellow, T().panel)
    end

    local list = getConvoList()
    local buttonRows = h >= 21 and 3 or 2
    local maxRows = math.max(1, h - 4 - buttonRows)
    local y = 4

    for i = 1, math.min(#list, maxRows) do
        local c = list[i]
        local selected = c.key == state.current
        local unreadMark = (c.unread or 0) > 0 and tostring(c.unread) or ""
        local label = chatLabel(c, true)
        if unreadMark ~= "" then label = label .. " (" .. unreadMark .. ")" end

        local bkg = selected and T().accent or T().panel
        local col = selected and colors.black or T().text

        text(1, y, string.rep(" ", lw), col, bkg)
        text(2, y, trim(label, lw - 2), col, bkg)

        table.insert(state.convoClicks, {
            key = c.key,
            x = 1,
            y = y,
            w = lw
        })

        y = y + 1
    end

    local by = h - buttonRows + 1
    local gap = 1
    local b1 = math.max(6, math.floor((lw - 3) / 2))
    local b2 = math.max(6, lw - b1 - gap - 2)

    addButton("side_chats", 2, by, b1, "Chats", colors.black, T().good, openChatsModal)
    addButton("side_menu", 2 + b1 + gap, by, b2, "Menu", colors.black, T().accent, openMainMenu)

    if buttonRows >= 2 then
        addButton("side_people", 2, by + 1, b1, "People", colors.black, T().warn, function()
            state.modal = "people"
        end)
        addButton("side_find", 2 + b1 + gap, by + 1, b2, "Find", colors.black, T().accent, requestDiscovery)
    end

    if buttonRows >= 3 then
        addButton("side_new", 2, by + 2, b1, "+Group", colors.black, T().good, function()
            state.modal = "create"
            state.modalInput = ""
            state.modalMode = "public"
        end)
        addButton("side_help", 2 + b1 + gap, by + 2, b2, "Help", colors.black, colors.lightGray, function()
            state.modal = "help"
        end)
    end
end

local function drawMessages()
    local x, top, cw, bottom, areaH = messageArea()

    fill(x, top, cw, areaH, T().bg)

    local visual = buildVisualLines(state.current, cw)
    local max = math.max(0, #visual - areaH)

    if state.scroll > max then state.scroll = max end
    if state.scroll < 0 then state.scroll = 0 end

    local start = math.max(1, #visual - areaH + 1 - state.scroll)
    local finish = math.max(0, #visual - state.scroll)
    local y = top

    for i = start, finish do
        local line = visual[i]

        if line and y <= bottom then
            text(x, y, trim(line.text, cw), line.color, T().bg)
            y = y + 1
        end
    end
end

local function drawInputBar()
    local inputLines = getInputLines()
    local countText = tostring(#state.input) .. "/" .. tostring(APP.messageLimit)
    local rows = inputRows()
    local lw = leftWidth()
    local x = lw + 1
    local cw = w - lw
    local top = h - rows - 2

    if top < 3 then top = h - rows - 1 end
    if top < 1 then top = 1 end

    fill(x, top, cw, 1, T().panel)

    if lw == 0 then
        local sendW = w < 28 and 5 or 7
        local menuW = w < 28 and 5 or 7
        local chatsW = w < 28 and 5 or 7
        local titleW = math.max(1, cw - sendW - menuW - chatsW - 3)

        text(x, top, trim(currentChatTitle(), titleW), colors.yellow, T().panel)
        addButton("p_chats", math.max(1, w - sendW - menuW - chatsW - 2), top, chatsW, w < 28 and "Chat" or "Chats", colors.black, T().accent, openChatsModal)
        addButton("p_menu", math.max(1, w - sendW - menuW - 1), top, menuW, "Menu", colors.black, T().accent, openMainMenu)
        addButton("p_send", math.max(1, w - sendW + 1), top, sendW, "Send", colors.black, T().good, sendChat)
    else
        local btnArea = cw >= 46 and 32 or 16
        text(x + 1, top, trim(currentChatTitle(), math.max(1, cw - btnArea - 2)), colors.yellow, T().panel)

        if cw >= 46 then
            addButton("desktop_send", w - 31, top, 7, "Send", colors.black, T().good, sendChat)
            addButton("desktop_menu", w - 23, top, 7, "Menu", colors.black, T().accent, openMainMenu)
            addButton("desktop_help", w - 15, top, 6, "Help", colors.black, colors.lightGray, function()
                state.modal = "help"
            end)
            addButton("desktop_out", w - 8, top, 8, "Logout", colors.white, T().danger, logout)
        else
            addButton("desktop_menu", w - 15, top, 7, "Menu", colors.black, T().accent, openMainMenu)
            addButton("desktop_send", w - 7, top, 7, "Send", colors.black, T().good, sendChat)
        end
    end

    fill(x, top + 1, cw, rows, T().input)
    if rows == 1 then
        text(x, top + 1, trim(inputLines[2] ~= "" and inputLines[2] or inputLines[1], cw), T().inputText, T().input)
    else
        text(x, top + 1, trim(inputLines[1], cw), T().inputText, T().input)
        text(x, top + 2, trim(inputLines[2], cw), T().inputText, T().input)
    end

    fill(x, h, cw, 1, T().bg)
    local hint
    if lw == 0 then
        hint = "Menu/Chats | " .. countText
    else
        hint = "TAB chat | /help | " .. countText
    end
    text(x + (lw == 0 and 0 or 1), h, trim(hint, cw - (lw == 0 and 0 or 1)), T().muted, T().bg)
end

local function drawChat()
    clearClickable()
    fill(1, 1, w, h, T().bg)

    drawTopBar()
    drawConvoList()
    drawMessages()
    drawInputBar()

    if state.modal then
        drawModal()
    end
end

local function drawScene()
    w, h = term.getSize()

    if type(term.setCursorBlink) == "function" then
        term.setCursorBlink(false)
    end

    if w < 24 or h < 12 then
        clear()
        center(2, APP.name, colors.cyan, colors.black)
        center(4, "Screen too small.", colors.red, colors.black)
        return
    end

    if state.screen == "login" then
        drawLogin(false)
    elseif state.screen == "register" then
        drawLogin(true)
    elseif state.screen == "chat" then
        drawChat()
    end
end

local function draw()
    local parent, win = beginBufferedDraw()
    local ok, err = pcall(drawScene)
    endBufferedDraw(parent, win)

    if not ok then
        error(err, 0)
    end
end

-- ============================================================
-- Network receive
-- ============================================================

local QUIET_VERSION_KINDS = {
    hello = true,
    hello_ack = true,
    discover = true,
    discover_reply = true,
    history_request = true,
    history_reply = true,
    read = true
}

local function shouldShowVersionNotice(msg)
    if state.quietVersionWarnings ~= false and QUIET_VERSION_KINDS[msg.kind] then
        return false
    end

    local now = os.clock()
    local key = tostring(msg.publicId or "?") .. ":" .. tostring(msg.version or "?") .. ":" .. tostring(msg.kind or "?")
    local last = state.versionNoticeLast[key]

    if last and now - last < APP.versionNoticeCooldown then
        return false
    end

    state.versionNoticeLast[key] = now
    return true
end

local function versionNotice(msg)
    if not shouldShowVersionNotice(msg) then return end

    local who = displayName(msg.user, msg.publicId, msg.profile)

    if tonumber(msg.version) > protocolVersion() then
        addMessage("global", "system", who .. " is on newer XenitChat v" .. tostring(msg.appVersion or msg.version) .. " (" .. tostring(msg.protocolName or "unknown") .. "). Run /update install if messages do not work.", "warn", { silent = true })
    elseif tonumber(msg.version) < protocolVersion() then
        addMessage("global", "system", "Ignored an old-format " .. tostring(msg.kind or "packet") .. " from " .. who .. " (v" .. tostring(msg.appVersion or msg.version) .. ", " .. tostring(msg.protocolName or "unknown") .. "). Enable Settings > Talk to older clients (BUGGY) to accept it.", "warn", { silent = true })
    end
end

local function rememberPacket(msg)
    if not msg.packetId or not msg.publicId then return false end

    local packetKey = tostring(msg.publicId) .. ":" .. tostring(msg.packetId)

    if state.packetSeen[packetKey] then
        return true
    end

    state.packetSeen[packetKey] = true
    table.insert(state.packetSeenOrder, packetKey)

    while #state.packetSeenOrder > 500 do
        local oldKey = table.remove(state.packetSeenOrder, 1)
        state.packetSeen[oldKey] = nil
    end

    return false
end

local function handleNetworkMessage(senderId, msg)
    if type(msg) ~= "table" then return end
    if msg.app ~= APP.name then return end
    if tonumber(msg.version) == nil then return end
    if not msg.user or not msg.publicId then return end
    if msg.publicId == state.publicId then return end

    if rememberPacket(msg) then return end

    if not sameProtocolVersion(msg.version) then
        local remoteVersion = tonumber(msg.version)

        if remoteVersion and remoteVersion < protocolVersion() and state.allowOldClients then
            -- Best-effort compatibility mode. Marked buggy because old clients may
            -- use missing fields, older message formats, or noisier packet flows.
        elseif QUIET_VERSION_KINDS[msg.kind] then
            -- Background packets from older/newer clients should not spam chat.
            -- Keep processing them where the schema is harmless enough.
        else
            versionNotice(msg)
            return
        end
    end

    if state.blocked[msg.publicId] then return end

    state.users[msg.publicId] = {
        username = msg.user,
        publicId = msg.publicId,
        nodeId = msg.nodeId,
        senderId = senderId,
        profile = msg.profile or {},
        lastSeenClock = os.clock()
    }

    if msg.kind == "hello" then
        sendTo(senderId, "hello_ack", {
            current = state.current
        })
        requestHistorySync(senderId, msg.publicId)

    elseif msg.kind == "hello_ack" then
        requestHistorySync(senderId, msg.publicId)
        return

    elseif msg.kind == "history_request" then
        sendTo(senderId, "history_reply", {
            bundles = makeHistoryBundle(msg.keys or {}, msg.publicId)
        })

    elseif msg.kind == "history_reply" then
        local imported = importHistoryBundles(msg.bundles, msg.publicId)
        if imported > 0 then
            addMessage("global", "system", "Synced " .. tostring(imported) .. " older message(s) from " .. displayName(msg.user, msg.publicId, msg.profile) .. ".", "system", { silent = true })
        end

    elseif msg.kind == "discover" then
        local channels = {}

        for key, c in pairs(state.convos) do
            if c.type == "public" and c.listed ~= false and c.private ~= true and not state.leftGroups[key] then
                table.insert(channels, {
                    key = key,
                    title = c.title,
                    owner = c.owner or state.username
                })
            end
        end

        sendTo(senderId, "discover_reply", {
            channels = channels
        })

    elseif msg.kind == "discover_reply" then
        if type(msg.channels) == "table" then
            for _, c in ipairs(msg.channels) do
                if type(c) == "table" and c.key and not state.leftGroups[c.key] then
                    state.discover[c.key] = {
                        key = c.key,
                        title = c.title or c.key,
                        owner = c.owner or msg.user
                    }
                end
            end
        end

    elseif msg.kind == "channel_create" then
        if msg.key and msg.listed ~= false and not state.leftGroups[msg.key] then
            ensureConvo(msg.key, msg.title or msg.key, "public", msg.private or false, true, msg.user)
            state.discover[msg.key] = {
                key = msg.key,
                title = msg.title or msg.key,
                owner = msg.user
            }
        end

    elseif msg.kind == "join" then
        return

    elseif msg.kind == "chat" then
        if msg.key and msg.body and not state.leftGroups[msg.key] then
            local known = state.convos[msg.key] ~= nil
            local allowAuto = msg.key == "global" or (msg.listed ~= false and msg.private ~= true)

            if known or allowAuto then
                ensureConvo(msg.key, msg.title or msg.key, "public", msg.private or false, msg.listed ~= false, msg.user)

                addMessage(msg.key, displayName(msg.user, msg.publicId, msg.profile), msg.body, "chat", {
                    msgId = msg.msgId,
                    fromId = msg.publicId
                })
            end
        end

    elseif msg.kind == "channel_rename" then
        if msg.key and msg.title and state.convos[msg.key] and not state.leftGroups[msg.key] then
            renameGroupLocal(msg.key, msg.title, displayName(msg.user, msg.publicId, msg.profile))
        end

    elseif msg.kind == "channel_leave" then
        return

    elseif msg.kind == "pm" then
        local intended = false

        if msg.toPublicId and msg.toPublicId == state.publicId then
            intended = true
        elseif not msg.toPublicId and msg.toName == state.username then
            intended = true
        end

        if intended and msg.body then
            local fromName = displayName(msg.user, msg.publicId, msg.profile)
            local key = pmKeyFor(msg.publicId, fromName)

            ensureConvo(key, fromName, "pm", true, false, fromName, msg.publicId)

            addMessage(key, fromName, msg.body, "pm", {
                msgId = msg.msgId,
                fromId = msg.publicId
            })

            if state.current == key then
                broadcast("read", {
                    toPublicId = msg.publicId,
                    msgId = msg.msgId
                })
            end
        end


    elseif msg.kind == "friend_request" then
        if msg.toPublicId == state.publicId and not state.friends[msg.publicId] then
            if not state.friendRequests.sent[msg.publicId] then
                state.friendRequests.inbox[msg.publicId] = requestRecord(msg.publicId, state.users[msg.publicId], "incoming")
                savePrefs()
                systemMessage("Friend request from " .. displayName(msg.user, msg.publicId, msg.profile) .. ". Open People > Inbox.")
            else
                addFriendDirect(msg.publicId, state.users[msg.publicId])
                broadcast("friend_accept", {
                    toPublicId = msg.publicId
                })
                systemMessage("You and " .. displayName(msg.user, msg.publicId, msg.profile) .. " are now friends.")
            end
        end

    elseif msg.kind == "friend_accept" then
        if msg.toPublicId == state.publicId then
            addFriendDirect(msg.publicId, state.users[msg.publicId])
            systemMessage(displayName(msg.user, msg.publicId, msg.profile) .. " accepted your friend request.")
        end

    elseif msg.kind == "friend_decline" then
        if msg.toPublicId == state.publicId then
            cleanRequests(msg.publicId)
            savePrefs()
            systemMessage(displayName(msg.user, msg.publicId, msg.profile) .. " declined your friend request.")
        end

    elseif msg.kind == "friend_cancel" then
        if msg.toPublicId == state.publicId then
            if state.friendRequests and state.friendRequests.inbox then
                state.friendRequests.inbox[msg.publicId] = nil
                savePrefs()
            end
        end

    elseif msg.kind == "unfriend" then
        if msg.toPublicId == state.publicId then
            state.friends[msg.publicId] = nil
            cleanRequests(msg.publicId)
            savePrefs()
            systemMessage(displayName(msg.user, msg.publicId, msg.profile) .. " removed you as a friend.")
        end

    elseif msg.kind == "read" then
        if msg.toPublicId == state.publicId then
            local key = pmKeyFor(msg.publicId, msg.user)

            if state.messages[key] then
                for _, m in ipairs(state.messages[key]) do
                    if m.outgoing then
                        m.seen = true
                    end
                end
            end
        end
    end
end

local function networkLoop()
    local lastHello = os.clock()

    while state.running do
        if state.username and state.publicId and os.clock() - lastHello >= APP.helloInterval then
            broadcast("hello", {
                current = state.current
            })
            lastHello = os.clock()
        end

        local senderId, msg = rednet.receive(APP.protocol, 0.1)

        if senderId then
            local ok, err = pcall(handleNetworkMessage, senderId, msg)
            if not ok then
                addMessage("global", "system", "Network packet skipped: " .. trim(err, 80), "warn")
            end
        end
    end
end

-- ============================================================
-- Input handling
-- ============================================================

local function typeIntoField(char)
    if state.screen == "login" or state.screen == "register" then
        if state.focus == "username" then
            state.input = state.input .. char
        elseif state.focus == "password" then
            state.password = state.password .. char
        end
        return
    end

    if state.modal then
        if state.modal == "create" or state.modal == "pm" or state.modal == "friend_search" or state.modal == "profile" or state.modal == "group_rename" then
            if #state.modalInput < APP.messageLimit then
                state.modalInput = state.modalInput .. char
            end
        end
        return
    end

    if #state.input < APP.messageLimit then
        state.input = state.input .. char
    end
end

local function backspaceField()
    if state.screen == "login" or state.screen == "register" then
        if state.focus == "username" then
            state.input = state.input:sub(1, -2)
        elseif state.focus == "password" then
            state.password = state.password:sub(1, -2)
        end
        return
    end

    if state.modal then
        state.modalInput = state.modalInput:sub(1, -2)
        return
    end

    state.input = state.input:sub(1, -2)
end

local function submitModal()
    if state.modal == "create" then
        createGroup(state.modalInput, state.modalMode)
        state.modal = nil
        state.modalInput = ""

    elseif state.modal == "pm" then
        local id, user = resolveUser(state.modalInput)

        if id and user then
            openPM(id, user)
            state.modal = nil
            state.modalInput = ""
        else
            setError("User not found online.")
        end

    elseif state.modal == "friend_search" then
        local id, user = resolveUser(state.modalInput)

        if id and user then
            sendFriendRequest(id, user)
            state.modal = "people"
            state.modalInput = ""
        else
            setError("User not found online.")
        end

    elseif state.modal == "profile" then
        if state.modalMode == "status" then
            state.profile.status = state.modalInput ~= "" and trim(state.modalInput, 40) or "Available"
        else
            state.profile.display = state.modalInput ~= "" and trim(state.modalInput, 24) or state.username
        end

        savePrefs()
        broadcast("hello", {})
        state.modal = nil
        state.modalInput = ""

    elseif state.modal == "group_rename" then
        renameCurrentGroup(state.modalInput)
        state.modal = nil
        state.modalInput = ""

    elseif state.modal == "error" then
        state.modal = nil
        state.modalInput = ""
    end
end

local function handleKey(key)
    if key == keys.backspace then
        backspaceField()
        return
    end

    if key == keys.tab then
        if state.screen == "login" or state.screen == "register" then
            state.focus = state.focus == "username" and "password" or "username"
        elseif state.screen == "chat" and not state.modal then
            nextConvo()
        end
        return
    end

    if key == keys.enter then
        if state.screen == "login" then
            login()
        elseif state.screen == "register" then
            register()
        elseif state.modal then
            submitModal()
        else
            sendChat()
        end
        return
    end

    if key == keys.escape then
        if state.modal then
            state.modal = nil
            state.modalInput = ""
            state.modalData = nil
        end
        return
    end

    if state.screen == "chat" and not state.modal then
        if key == keys.up then
            scrollBy(1)
        elseif key == keys.down then
            scrollBy(-1)
        elseif key == keys.pageUp then
            scrollBy(5)
        elseif key == keys.pageDown then
            scrollBy(-5)
        end
    end
end

local function handleMouse(x, y)
    if clickButton(x, y) then return end

    if state.screen == "login" or state.screen == "register" then
        if isPocket() then
            local panelY = 4
            if y == panelY + 3 then
                state.focus = "username"
            elseif y == panelY + 5 then
                state.focus = "password"
            end
            return
        end

        local panelH = 12
        local panelY = math.max(5, math.floor((h - panelH) / 2) + 1)

        if y == panelY + 3 then
            state.focus = "username"
        elseif y == panelY + 5 then
            state.focus = "password"
        end
        return
    end

    if state.screen ~= "chat" or state.modal then return end

    for _, c in ipairs(state.convoClicks) do
        if x >= c.x and x <= c.x + c.w - 1 and y == c.y then
            switchConvo(c.key)
            return
        end
    end
end

local function uiLoop()
    while state.running do
        draw()

        local event, p1, p2, p3 = os.pullEvent()

        if event == "char" then
            typeIntoField(p1)

        elseif event == "key" then
            handleKey(p1)

        elseif event == "mouse_click" then
            handleMouse(p2, p3)

        elseif event == "mouse_scroll" then
            if state.screen == "chat" and not state.modal then
                if p1 < 0 then
                    scrollBy(3)
                else
                    scrollBy(-3)
                end
            end

        elseif event == "term_resize" then
            w, h = term.getSize()
            clampScroll()
        end
    end
end

-- ============================================================
-- Boot
-- ============================================================

local function boot()
    clear()
    if type(term.setCursorBlink) == "function" then term.setCursorBlink(false) end
    openModem()
    loadPrefs()
    loadHistory()
    tryRememberLogin()

    parallel.waitForAny(networkLoop, uiLoop)

    clear()
    reset()
    if type(term.setCursorBlink) == "function" then term.setCursorBlink(true) end

    if state.restartRequested then
        state.restartRequested = false
        if type(shell) == "table" and type(shell.run) == "function" then
            shell.run(getProgramPath())
        else
            print("Restart requested. Run " .. getProgramPath() .. " again.")
        end
    elseif state.exitReason == "exit" then
        print(APP.name .. " closed.")
    end
end

boot()
