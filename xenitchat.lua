-- XenitChat
-- Connecting people

local APP = {
    name = "XenitChat",
    slogan = "Connecting people",
    version = 7,
    protocol = "xenitchat_bus",

    accountFile = ".xenit_accounts",
    nodeSecretFile = ".xenit_node_secret",
    prefsFile = ".xenit_prefs",

    maxMessages = 350,
    messageLimit = 200,

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
    blocked = {},
    profile = {
        display = "",
        status = "Available"
    },

    theme = "dark",
    buttons = {},
    convoClicks = {}
}

local seq = 0

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

local function isPocket()
    return w <= 30 or h <= 18
end

local function isSmall()
    return w < 48
end

local function leftWidth()
    if isPocket() or isSmall() then return 0 end
    return 19
end

local function messageArea()
    local lw = leftWidth()

    if lw == 0 then
        local top = 3
        local bottom = h - 5
        if bottom < top then bottom = top end
        return 1, top, w, bottom, bottom - top + 1
    end

    local top = 2
    local bottom = h - 5
    if bottom < top then bottom = top end
    return lw + 1, top, w - lw, bottom, bottom - top + 1
end

local function clearClickable()
    state.buttons = {}
    state.convoClicks = {}
end

local function addButton(id, x, y, width, label, color, background, action)
    width = math.max(2, width)

    if x < 1 then x = 1 end
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

    local display = tostring(label or "")

    if #display > width then
        display = display:sub(1, width)
    end

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
        theme = "dark",
        profile = {
            display = "",
            status = "Available"
        },
        friends = {},
        blocked = {},
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
        blocked = state.blocked,
        convos = state.convos
    }

    writeSerialized(APP.prefsFile, data)
end

local function loadPrefs()
    local data = readSerialized(APP.prefsFile, defaultPrefs())

    if type(data) ~= "table" then data = defaultPrefs() end
    if type(data.convos) ~= "table" then data.convos = defaultPrefs().convos end
    if type(data.friends) ~= "table" then data.friends = {} end
    if type(data.blocked) ~= "table" then data.blocked = {} end
    if type(data.profile) ~= "table" then data.profile = { display = "", status = "Available" } end

    state.remember = data.remember ~= false
    state.theme = THEMES[data.theme] and data.theme or "dark"
    state.profile = data.profile
    state.friends = data.friends
    state.blocked = data.blocked
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
    local lines = splitFixed(raw, w)
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
            last = 0
        }
    else
        local c = state.convos[key]
        c.title = title or c.title or key
        c.type = kind or c.type or "public"
        c.private = private or c.private or false
        c.listed = listed ~= false
        c.owner = owner or c.owner
        c.peerId = peerId or c.peerId
    end

    if not state.messages[key] then
        state.messages[key] = {}
    end

    touchConvo(key)
    savePrefs()
end

local function addMessage(key, from, body, kind, meta)
    key = key or "global"
    ensureConvo(key, key, "public", false, true, "unknown")

    if not state.messages[key] then
        state.messages[key] = {}
    end

    meta = meta or {}

    table.insert(state.messages[key], {
        from = tostring(from or "system"),
        body = clampMessage(body or ""),
        kind = kind or "chat",
        time = textutils.formatTime(os.time(), true),
        msgId = meta.msgId,
        fromId = meta.fromId,
        outgoing = meta.outgoing,
        seen = meta.seen or false
    })

    while #state.messages[key] > APP.maxMessages do
        table.remove(state.messages[key], 1)
    end

    touchConvo(key)

    if key == state.current then
        state.scroll = 0
    else
        state.convos[key].unread = (state.convos[key].unread or 0) + 1
    end

    savePrefs()
end

local function systemMessage(body, key)
    addMessage(key or state.current, "system", body, "system")
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
    data.version = APP.version
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

local function sendTo(id, kind, data)
    if not state.username or not state.publicId then return end
    rednet.send(id, makePacket(kind, data), APP.protocol)
end

-- ============================================================
-- Actions
-- ============================================================

local function requestDiscovery()
    state.discover = {}

    for key, c in pairs(state.convos) do
        if c.type == "public" and c.listed ~= false and c.private ~= true then
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

    name = name:gsub("%s+", "_")

    local key = name
    local private = mode == "private" or mode == "unlisted"
    local listed = mode ~= "unlisted"
    local kind = private and "private_group" or "public"

    ensureConvo(key, name, kind, private, listed, state.username)
    switchConvo(key)

    systemMessage("Created group #" .. name, key)

    broadcast("channel_create", {
        key = key,
        title = name,
        private = private,
        listed = listed
    })
end

local function joinGroup(name)
    if not name or name == "" then return end

    name = name:gsub("%s+", "_")
    ensureConvo(name, name, "public", false, true, "unknown")
    switchConvo(name)

    broadcast("join", {
        key = name
    })
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

    local title = "Unknown"

    if user then
        title = displayName(user.username, publicId, user.profile)
    end

    local key = pmKeyFor(publicId, title)
    ensureConvo(key, title, "pm", true, false, title, publicId)
    switchConvo(key)
    sendReadReceipt(publicId)
end

local function sendChat()
    local body = clampMessage(state.input)

    if body == "" then return end

    local c = state.convos[state.current] or {}
    local msgId = randomToken(10)

    addMessage(state.current, myName(), body, c.type == "pm" and "pm" or "chat", {
        msgId = msgId,
        outgoing = true
    })

    if c.type == "pm" then
        broadcast("pm", {
            toPublicId = c.peerId,
            toName = c.title,
            body = body,
            msgId = msgId
        })
    else
        broadcast("chat", {
            key = state.current,
            body = body,
            msgId = msgId
        })
    end

    state.input = ""
end

local function friendUser(publicId, user)
    if not publicId or not user then return end

    state.friends[publicId] = {
        username = user.username,
        profile = user.profile or {},
        added = os.time()
    }

    savePrefs()
end

local function unfriendUser(publicId)
    if not publicId then return end

    state.friends[publicId] = nil
    savePrefs()
end

local function blockUser(publicId)
    if not publicId then return end

    state.blocked[publicId] = true
    state.friends[publicId] = nil
    savePrefs()
end

local function unblockUser(publicId)
    if not publicId then return end

    state.blocked[publicId] = nil
    savePrefs()
end

local function setError(message)
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

local function logout()
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

-- ============================================================
-- Draw login
-- ============================================================

local function drawLogin(registerMode)
    clearClickable()
    clear()

    fill(1, 1, w, h, T().bg)

    if isPocket() then
        center(1, APP.name, T().accent, T().bg)
        center(2, APP.slogan, T().muted, T().bg)

        local y = 4

        fill(1, y, w, 10, T().panel)

        text(2, y + 1, registerMode and "Create account" or "Welcome back", T().text, T().panel)

        text(2, y + 3, "User", T().muted, T().panel)
        fill(8, y + 3, w - 8, 1, state.focus == "username" and colors.white or T().muted)
        text(9, y + 3, trim(state.input, w - 10), colors.black, state.focus == "username" and colors.white or T().muted)

        text(2, y + 5, "Pass", T().muted, T().panel)
        fill(8, y + 5, w - 8, 1, state.focus == "password" and colors.white or T().muted)
        text(9, y + 5, trim(string.rep("*", #state.password), w - 10), colors.black, state.focus == "password" and colors.white or T().muted)

        local half = math.floor((w - 5) / 2)

        if registerMode then
            addButton("register", 2, y + 7, half, "Create", colors.black, T().good, register)
            addButton("back", 3 + half, y + 7, half, "Back", colors.white, T().danger, function()
                state.screen = "login"
                state.input = ""
                state.password = ""
                state.modal = nil
            end)
        else
            addButton("login", 2, y + 7, half, "Login", colors.black, T().good, login)
            addButton("new", 3 + half, y + 7, half, "New", colors.black, T().accent, function()
                state.screen = "register"
                state.input = ""
                state.password = ""
                state.modal = nil
            end)
        end

        addButton("remember", 2, y + 8, w - 2, state.remember and "Remember: ON" or "Remember: OFF", colors.black, state.remember and T().accent or T().muted, function()
            state.remember = not state.remember
            savePrefs()
        end)

        if state.modal == "error" then
            text(1, h - 1, trim(state.modalInput, w), T().danger, T().bg)
        else
            text(1, h - 1, "TAB field | ENTER go", T().muted, T().bg)
        end

        return
    end

    center(2, APP.name, T().accent, T().bg)
    center(3, APP.slogan, T().muted, T().bg)

    local panelW = math.min(42, w - 4)
    local panelH = 12
    local panelX = math.floor((w - panelW) / 2) + 1
    local panelY = math.max(5, math.floor((h - panelH) / 2) + 1)

    fill(panelX, panelY, panelW, panelH, T().panel)

    text(panelX + 2, panelY + 1, registerMode and "Create account" or "Login", T().text, T().panel)

    text(panelX + 2, panelY + 3, "Username", T().muted, T().panel)
    fill(panelX + 12, panelY + 3, panelW - 14, 1, state.focus == "username" and colors.white or T().muted)
    text(panelX + 13, panelY + 3, trim(state.input, panelW - 16), colors.black, state.focus == "username" and colors.white or T().muted)

    text(panelX + 2, panelY + 5, "Password", T().muted, T().panel)
    fill(panelX + 12, panelY + 5, panelW - 14, 1, state.focus == "password" and colors.white or T().muted)
    text(panelX + 13, panelY + 5, trim(string.rep("*", #state.password), panelW - 16), colors.black, state.focus == "password" and colors.white or T().muted)

    local btnW = 14
    local gap = 2
    local total = btnW * 2 + gap
    local bx = panelX + math.floor((panelW - total) / 2)

    if registerMode then
        addButton("register", bx, panelY + 8, btnW, "Register", colors.black, T().good, register)
        addButton("back", bx + btnW + gap, panelY + 8, btnW, "Back", colors.white, T().danger, function()
            state.screen = "login"
            state.input = ""
            state.password = ""
            state.modal = nil
        end)
    else
        addButton("login", bx, panelY + 8, btnW, "Login", colors.black, T().good, login)
        addButton("new", bx + btnW + gap, panelY + 8, btnW, "Register", colors.black, T().accent, function()
            state.screen = "register"
            state.input = ""
            state.password = ""
            state.modal = nil
        end)
    end

    addButton("remember", bx, panelY + 10, total, state.remember and "Remember me: ON" or "Remember me: OFF", colors.black, state.remember and T().accent or T().muted, function()
        state.remember = not state.remember
        savePrefs()
    end)

    if state.modal == "error" then
        center(h - 2, trim(state.modalInput, w - 2), T().danger, T().bg)
    else
        center(h - 1, "TAB field | ENTER continue | click buttons", T().muted, T().bg)
    end
end

-- ============================================================
-- Modals
-- ============================================================

local function modalBox(width, height)
    local mw
    local mh

    if isPocket() then
        mw = w
        mh = math.min(height, h - 2)
    else
        mw = math.min(width, w - 4)
        mh = math.min(height, h - 4)
    end

    local mx = math.floor((w - mw) / 2) + 1
    local my = math.floor((h - mh) / 2) + 1

    fill(mx, my, mw, mh, colors.lightGray)

    return mx, my, mw, mh
end

local function drawCreateModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, isPocket() and 11 or 9)

    text(mx + 1, my + 1, "New group", colors.black, colors.lightGray)
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

    text(mx + 1, my + 1, "Discover public groups", colors.black, colors.lightGray)

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

    text(mx + 1, my + 1, "Message user", colors.black, colors.lightGray)
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

    text(mx + 1, my + 1, "People", colors.black, colors.lightGray)

    local list = getSortedUsers()
    local maxRows = mh - 5

    if #list == 0 then
        text(mx + 1, my + 3, "Nobody online yet.", colors.gray, colors.lightGray)
    else
        for i = 1, math.min(#list, maxRows) do
            local u = list[i]
            local name = displayName(u.username, u.publicId, u.profile)
            local friend = state.friends[u.publicId] and "*" or " "
            local online = os.clock() - (u.lastSeenClock or 0) <= APP.onlineTimeout and "o" or "-"
            local label = online .. friend .. " " .. name .. " #" .. shortId(u.publicId)

            addButton("person_" .. tostring(i), mx + 1, my + 2 + i, mw - 2, trim(label, mw - 2), colors.black, colors.white, function()
                state.modal = "user_info"
                state.modalData = {
                    publicId = u.publicId,
                    user = state.users[u.publicId]
                }
            end)
        end
    end

    addButton("people_add", mx + 1, my + mh - 1, 10, "Search", colors.black, T().accent, function()
        state.modal = "friend_search"
        state.modalInput = ""
    end)

    addButton("people_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, T().danger, function()
        state.modal = nil
    end)
end

local function drawFriendSearchModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, 7)

    text(mx + 1, my + 1, "Add friend", colors.black, colors.lightGray)
    text(mx + 1, my + 3, "Name/ID:", colors.black, colors.lightGray)
    fill(mx + 10, my + 3, mw - 11, 1, colors.white)
    text(mx + 11, my + 3, trim(state.modalInput, mw - 13), colors.black, colors.white)

    addButton("friend_find", mx + 1, my + 5, 8, "Find", colors.black, T().good, function()
        local id, user = resolveUser(state.modalInput)

        if id and user then
            friendUser(id, user)
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

    text(mx + 1, my + 1, "User info", colors.black, colors.lightGray)
    text(mx + 1, my + 3, trim("Name: " .. name, mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Status: " .. status, mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 5, trim("ID: " .. shortId(id), mw - 2), colors.gray, colors.lightGray)

    local friendLabel = state.friends[id] and "Unfriend" or "Friend"
    local blockLabel = state.blocked[id] and "Unblock" or "Block"

    local by = my + mh - 2

    addButton("ui_pm", mx + 1, by, 8, "PM", colors.black, T().accent, function()
        openPM(id, user)
        state.modal = nil
    end)

    addButton("ui_friend", mx + 10, by, 10, friendLabel, colors.black, T().good, function()
        if state.friends[id] then
            unfriendUser(id)
        else
            friendUser(id, user)
        end
    end)

    addButton("ui_block", mx + 21, by, 8, blockLabel, colors.white, T().danger, function()
        if state.blocked[id] then
            unblockUser(id)
        else
            blockUser(id)
        end
        state.modal = nil
    end)

    addButton("ui_close", mx + mw - 8, by, 8, "Close", colors.white, colors.gray, function()
        state.modal = "people"
    end)
end

local function drawProfileModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 46, isPocket() and 8 or 9)

    local title = state.modalMode == "status" and "Set status" or "Set display name"

    text(mx + 1, my + 1, title, colors.black, colors.lightGray)

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

local function drawThemeModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 36, 7)

    text(mx + 1, my + 1, "Choose theme", colors.black, colors.lightGray)

    local names = { "dark", "ocean", "clean" }

    for i, key in ipairs(names) do
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

local function drawErrorModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, 5)

    text(mx + 1, my + 1, "Notice", colors.black, colors.lightGray)
    text(mx + 1, my + 2, trim(state.modalInput, mw - 2), colors.red, colors.lightGray)

    addButton("err_ok", mx + math.floor((mw - 8) / 2), my + 4, 8, "OK", colors.black, T().good, function()
        state.modal = nil
        state.modalInput = ""
    end)
end

local function drawModal()
    if state.modal == "create" then
        drawCreateModal()
    elseif state.modal == "discover" then
        drawDiscoverModal()
    elseif state.modal == "pm" then
        drawPMModal()
    elseif state.modal == "people" then
        drawPeopleModal()
    elseif state.modal == "friend_search" then
        drawFriendSearchModal()
    elseif state.modal == "user_info" then
        drawUserInfoModal()
    elseif state.modal == "profile" then
        drawProfileModal()
    elseif state.modal == "theme" then
        drawThemeModal()
    elseif state.modal == "error" then
        drawErrorModal()
    end
end

-- ============================================================
-- Draw chat UI
-- ============================================================

local function drawTopBar()
    fill(1, 1, w, 1, T().top)

    if isPocket() then
        text(1, 1, APP.name, colors.white, T().top)
        local right = tostring(onlineCount()) .. " on"
        text(math.max(1, w - #right + 1), 1, right, colors.yellow, T().top)
    else
        text(2, 1, APP.name, colors.white, T().top)

        local right = "@" .. myName() .. " | " .. tostring(onlineCount()) .. " online"
        text(math.max(1, w - #right), 1, right, colors.yellow, T().top)
    end
end

local function drawConvoList()
    local lw = leftWidth()

    if lw == 0 then
        fill(1, 2, w, 1, T().panel)

        local c = state.convos[state.current] or {}
        local label = c.title or state.current

        if (c.unread or 0) > 0 then
            label = "*" .. label
        end

        text(1, 2, trim(label, w - 16), colors.black, T().accent)

        addButton("mobile_new", w - 15, 2, 2, "+", colors.black, T().good, function()
            state.modal = "create"
            state.modalInput = ""
            state.modalMode = "public"
        end)

        addButton("mobile_d", w - 12, 2, 2, "D", colors.black, T().accent, requestDiscovery)

        addButton("mobile_pm", w - 9, 2, 2, "P", colors.black, T().warn, function()
            state.modal = "pm"
            state.modalInput = ""
        end)

        addButton("mobile_people", w - 6, 2, 2, "U", colors.black, T().good, function()
            state.modal = "people"
        end)

        addButton("mobile_next", w - 3, 2, 3, ">>", colors.white, colors.gray, nextConvo)

        return
    end

    fill(1, 2, lw, h - 1, T().panel)
    text(2, 2, "Chats", T().text, T().panel)

    local list = getConvoList()
    local maxRows = h - 7
    local y = 4

    for i = 1, math.min(#list, maxRows) do
        local c = list[i]
        local selected = c.key == state.current
        local mark = (c.unread or 0) > 0 and "*" or " "
        local icon = c.type == "pm" and "@" or "#"
        local label = mark .. icon .. tostring(c.title or c.key)

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

    local by = h - 3

    addButton("side_new", 2, by, 5, "+", colors.black, T().good, function()
        state.modal = "create"
        state.modalInput = ""
        state.modalMode = "public"
    end)

    addButton("side_d", 8, by, 5, "D", colors.black, T().accent, requestDiscovery)

    addButton("side_pm", 14, by, 5, "PM", colors.black, T().warn, function()
        state.modal = "pm"
        state.modalInput = ""
    end)

    addButton("side_people", 2, by + 1, 8, "People", colors.black, T().good, function()
        state.modal = "people"
    end)

    addButton("side_me", 11, by + 1, 8, "Me", colors.black, T().accent, function()
        state.modal = "profile"
        state.modalMode = "profile"
        state.modalInput = state.profile.display or state.username or ""
    end)
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

    if isPocket() then
        fill(1, h - 4, w, 2, T().input)
        text(1, h - 4, trim(inputLines[1], w), T().inputText, T().input)
        text(1, h - 3, trim(inputLines[2], w), T().inputText, T().input)

        fill(1, h - 2, w, 1, T().panel)

        addButton("p_send", 1, h - 2, 6, "Send", colors.black, T().good, sendChat)

        addButton("p_clear", 8, h - 2, 5, "Clr", colors.white, colors.gray, function()
            state.input = ""
        end)

        addButton("p_theme", 14, h - 2, 5, "Thm", colors.black, T().accent, function()
            state.modal = "theme"
        end)

        addButton("p_out", 20, h - 2, w - 19, "Out", colors.white, T().danger, logout)

        fill(1, h - 1, w, 1, T().bg)
        text(1, h - 1, trim("ENTER send | " .. countText, w), T().muted, T().bg)

        fill(1, h, w, 1, T().bg)
        text(1, h, trim("UP/DOWN scroll | D discover", w), T().muted, T().bg)

        return
    end

    local lw = leftWidth()
    local x = lw + 1
    local cw = w - lw

    fill(x, h - 4, cw, 1, T().panel)

    local c = state.convos[state.current] or {}
    local title = c.type == "pm" and "@" .. tostring(c.title or state.current) or "#" .. tostring(c.title or state.current)

    text(x + 1, h - 4, trim(title, cw - 38), colors.yellow, T().panel)

    addButton("desktop_send", w - 32, h - 4, 7, "Send", colors.black, T().good, sendChat)
    addButton("desktop_theme", w - 24, h - 4, 7, "Theme", colors.black, T().accent, function()
        state.modal = "theme"
    end)
    addButton("desktop_out", w - 16, h - 4, 7, "Logout", colors.white, T().danger, logout)

    fill(x, h - 3, cw, 2, T().input)
    text(x, h - 3, trim(inputLines[1], cw), T().inputText, T().input)
    text(x, h - 2, trim(inputLines[2], cw), T().inputText, T().input)

    fill(x, h - 1, cw, 1, T().bg)
    text(x + 1, h - 1, trim("UP/DOWN scroll | " .. countText .. " | D discover | People for friends/block", cw - 1), T().muted, T().bg)

    fill(x, h, cw, 1, T().bg)
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

local function draw()
    w, h = term.getSize()

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

-- ============================================================
-- Network receive
-- ============================================================

local function handleNetworkMessage(senderId, msg)
    if type(msg) ~= "table" then return end
    if msg.app ~= APP.name then return end

    if type(msg.version) ~= "number" then return end

    if msg.version > APP.version then
        addMessage("global", "system", "Your version is outdated. You cannot read this message.", "warn")
        return
    end

    if msg.version < APP.version then
        addMessage("global", "system", "Message from old XenitChat version ignored.", "warn")
        return
    end

    if not msg.user or not msg.publicId then return end
    if msg.publicId == state.publicId then return end
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

    elseif msg.kind == "hello_ack" then
        return

    elseif msg.kind == "discover" then
        local channels = {}

        for key, c in pairs(state.convos) do
            if c.type == "public" and c.listed ~= false and c.private ~= true then
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
                if type(c) == "table" and c.key then
                    state.discover[c.key] = {
                        key = c.key,
                        title = c.title or c.key,
                        owner = c.owner or msg.user
                    }
                end
            end
        end

    elseif msg.kind == "channel_create" then
        if msg.key and msg.listed ~= false then
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
        if msg.key and msg.body then
            ensureConvo(msg.key, msg.key, "public", false, true, "unknown")

            addMessage(msg.key, displayName(msg.user, msg.publicId, msg.profile), msg.body, "chat", {
                msgId = msg.msgId,
                fromId = msg.publicId
            })
        end

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
            handleNetworkMessage(senderId, msg)
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
        if state.modal == "create" or state.modal == "pm" or state.modal == "friend_search" or state.modal == "profile" then
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
            friendUser(id, user)
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
    openModem()
    loadPrefs()
    tryRememberLogin()

    parallel.waitForAny(networkLoop, uiLoop)

    clear()
    reset()
end

boot()