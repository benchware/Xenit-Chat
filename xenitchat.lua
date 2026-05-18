-- XenitChat
-- Connecting people

local APP = {
    name = "XenitChat",
    slogan = "Connecting people",
    version = "20.0.4",
    protocolVersion = 19,
    protocolName = "Aegis",
    protocol = "xenitchat_bus",
    updateUrl = "https://raw.githubusercontent.com/benchware/Xenit-Chat/main/xenitchat.lua",
    updateOwner = "benchware",
    updateRepo = "Xenit-Chat",
    updatePath = "xenitchat.lua",

    accountFile = ".xenit_accounts",
    nodeSecretFile = ".xenit_node_secret",
    prefsFile = ".xenit_prefs",
    historyFile = ".xenit_history",
    attachmentDir = ".xenit_attachments",

    maxMessages = 350,
    messageLimit = 200,
    historySyncLimit = 80,
    historySyncCooldown = 12,
    versionNoticeCooldown = 90,
    maxPacketBytes = 12000,
    maxAttachmentBytes = 48000,
    attachmentChunkSize = 5000,
    attachmentTimeout = 45,
    attachmentDefaultExpireDays = 3,
    attachmentStorageLimitKB = 256,
    floodWindow = 6,
    floodLimit = 24,

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
    ,
    aegis = {
        name = "Aegis",
        bg = colors.black,
        panel = colors.gray,
        top = colors.purple,
        accent = colors.lightBlue,
        good = colors.lime,
        warn = colors.orange,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
    },
    slate = {
        name = "Slate",
        bg = colors.black,
        panel = colors.gray,
        top = colors.gray,
        accent = colors.cyan,
        good = colors.green,
        warn = colors.yellow,
        danger = colors.red,
        text = colors.white,
        muted = colors.lightGray,
        input = colors.black,
        inputText = colors.white
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
    allowOldClients = true,
    legacyCompatMode = "v15",
    useSystemSlashChannel = true,
    modalPositions = {},
    draggingModal = nil,
    settingsScroll = 0,
    compatScroll = 0,
    branchScroll = 0,
    updateBranchesRemote = nil,
    updateBranchesStatus = "fallback",
    updateBranch = "main",
    updateCustomBranch = "",
    slashOpenedSystemOutput = false,
    lastDragDrawClock = 0,
    showOldClientTags = true,
    suppressRemoteVersionWarnings = true,
    showTimestamps = true,
    compactMessages = false,
    showReadReceipts = true,
    showSystemMessages = true,
    friendNotifications = true,
    pingNotifications = true,
    attachmentNotifications = true,
    allowAttachments = true,
    autoPlayAudio = false,
    autoHistorySync = true,
    dmPrivacy = "anyone",
    autoJoinPublicGroups = true,
    requireFriendForHistory = false,
    autoBlockFlood = false,
    securityAlerts = true,
    muted = {},
    trusted = {},
    knownIdentities = {},
    rateBuckets = {},
    securityEvents = {},
    pingPending = {},
    pingOrder = {},
    pendingTransfers = {},
    attachmentLog = {},
    autoCleanupAttachments = true,
    attachmentExpireDays = 3,
    attachmentStorageLimitKB = 256,
    legacyAttachmentNotice = true,
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

LEGACY_COMPAT_MODES = {
    off = { label = "Off", target = nil, plain = false, accept = false },
    accept = { label = "Accept old packets only", target = nil, plain = false, accept = true },
    generic = { label = "Generic legacy mirror (BUGGY)", target = 15, plain = true, accept = true },
    v7 = { label = "Known v7 mirror (BUGGY)", target = 7, plain = true, accept = true },
    v8 = { label = "Known v8 mirror (BUGGY)", target = 8, plain = true, accept = true },
    v10 = { label = "Known v10 mirror (BUGGY)", target = 10, plain = true, accept = true },
    v12 = { label = "Known v12 mirror (BUGGY)", target = 12, plain = true, accept = true },
    v14 = { label = "Known v14 mirror (BUGGY)", target = 14, plain = true, accept = true },
    v15 = { label = "Known v15 mirror (BUGGY)", target = 15, plain = true, accept = true },
    v16 = { label = "Known v16 mirror (BUGGY)", target = 16, plain = true, accept = true },
    v17 = { label = "Known v17 mirror (BUGGY)", target = 17, plain = true, accept = true },
    v18 = { label = "Known v18 mirror (BUGGY)", target = 18, plain = true, accept = true },
    v19_plain = { label = "v19 plain/no codename (BUGGY)", target = 19, plain = true, accept = true },
    v19_quartz = { label = "Quartz v19 legacy (BUGGY)", target = 19, plain = false, accept = true, protocolName = "Quartz" }
}

LEGACY_COMPAT_ORDER = { "off", "accept", "generic", "v15", "v18", "v17", "v16", "v14", "v12", "v10", "v8", "v7", "v19_plain", "v19_quartz" }

function legacyCompatInfo()
    return LEGACY_COMPAT_MODES[state.legacyCompatMode or "accept"] or LEGACY_COMPAT_MODES.accept
end

function legacyCompatLabel()
    local info = legacyCompatInfo()
    return info.label or "Accept old packets only"
end

function setLegacyCompatMode(mode, quiet)
    if not LEGACY_COMPAT_MODES[mode] then mode = "off" end
    state.legacyCompatMode = mode
    state.allowOldClients = mode ~= "off"
    savePrefs()
    if not quiet then
        systemMessage("Old-client compatibility: " .. legacyCompatLabel() .. (state.allowOldClients and " (BUGGY)" or ""))
    end
end

function legacyMirrorVersion()
    local info = legacyCompatInfo()
    return info.target
end

function shouldAcceptOldClients()
    local info = legacyCompatInfo()
    return (state.allowOldClients == true or state.legacyCompatMode ~= "off") and info.accept == true
end

function shouldMirrorForLegacy(kind)
    local v = legacyMirrorVersion()
    if not v then return false end
    if v == protocolVersion() and state.legacyCompatMode ~= "v19_plain" and state.legacyCompatMode ~= "v19_quartz" then return false end
    return kind == "hello" or kind == "hello_ack" or kind == "chat" or kind == "pm" or kind == "read" or kind == "channel_create" or kind == "channel_rename" or kind == "join" or kind == "friend_request" or kind == "friend_accept" or kind == "friend_decline" or kind == "friend_cancel" or kind == "unfriend"
end

function remoteIsOld(publicIdOrUser)
    local u = nil
    if type(publicIdOrUser) == "table" then
        u = publicIdOrUser
    else
        u = state.users and state.users[publicIdOrUser]
    end
    if not u then return false end

    if u.oldClient == true then return true end
    if u.legacyMirror == true then return true end

    local rv = tonumber(u.remoteVersion or u.version)
    if rv and rv < protocolVersion() then return true end

    -- Pre-codename/plain builds often do not send protocolName/appVersion.
    -- Treat them as old for UI tagging even if their numeric version is ambiguous.
    if state.showOldClientTags ~= false and rv and rv <= protocolVersion() then
        if not u.remoteProtocolName and not u.protocolName then return true end
    end

    return false
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
        allowOldClients = true,
        legacyCompatMode = "v15",
        updateBranch = "main",
        updateCustomBranch = "",
        useSystemSlashChannel = true,
        showOldClientTags = true,
        suppressRemoteVersionWarnings = true,
        showTimestamps = true,
        compactMessages = false,
        showReadReceipts = true,
        showSystemMessages = true,
        friendNotifications = true,
        pingNotifications = true,
        attachmentNotifications = true,
        allowAttachments = true,
        autoPlayAudio = false,
        autoCleanupAttachments = true,
        attachmentExpireDays = 3,
        attachmentStorageLimitKB = 256,
        legacyAttachmentNotice = true,
        attachmentLog = {},
        autoHistorySync = true,
        dmPrivacy = "anyone",
        autoJoinPublicGroups = true,
        requireFriendForHistory = false,
        autoBlockFlood = false,
        securityAlerts = true,
        muted = {},
        trusted = {},
        knownIdentities = {},
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
        legacyCompatMode = state.legacyCompatMode,
        updateBranch = state.updateBranch,
        updateCustomBranch = state.updateCustomBranch,
        useSystemSlashChannel = state.useSystemSlashChannel,
        showOldClientTags = state.showOldClientTags,
        suppressRemoteVersionWarnings = state.suppressRemoteVersionWarnings,
        showTimestamps = state.showTimestamps,
        compactMessages = state.compactMessages,
        showReadReceipts = state.showReadReceipts,
        showSystemMessages = state.showSystemMessages,
        friendNotifications = state.friendNotifications,
        pingNotifications = state.pingNotifications,
        attachmentNotifications = state.attachmentNotifications,
        allowAttachments = state.allowAttachments,
        autoPlayAudio = state.autoPlayAudio,
        autoCleanupAttachments = state.autoCleanupAttachments,
        attachmentExpireDays = state.attachmentExpireDays,
        attachmentStorageLimitKB = state.attachmentStorageLimitKB,
        legacyAttachmentNotice = state.legacyAttachmentNotice,
        attachmentLog = state.attachmentLog,
        autoHistorySync = state.autoHistorySync,
        dmPrivacy = state.dmPrivacy,
        autoJoinPublicGroups = state.autoJoinPublicGroups,
        requireFriendForHistory = state.requireFriendForHistory,
        autoBlockFlood = state.autoBlockFlood,
        securityAlerts = state.securityAlerts,
        muted = state.muted,
        trusted = state.trusted,
        knownIdentities = state.knownIdentities,
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
    if type(data.allowOldClients) ~= "boolean" then data.allowOldClients = true end
    if not LEGACY_COMPAT_MODES[data.legacyCompatMode or "v15"] then data.legacyCompatMode = data.allowOldClients and "v15" or "off" end
    if data.legacyCompatMode == nil then data.legacyCompatMode = "v15" end
    if type(data.updateBranch) ~= "string" or data.updateBranch == "" then data.updateBranch = "main" end
    if type(data.updateCustomBranch) ~= "string" then data.updateCustomBranch = "" end
    if type(data.useSystemSlashChannel) ~= "boolean" then data.useSystemSlashChannel = true end
    if type(data.showOldClientTags) ~= "boolean" then data.showOldClientTags = true end
    if type(data.suppressRemoteVersionWarnings) ~= "boolean" then data.suppressRemoteVersionWarnings = true end
    if type(data.showTimestamps) ~= "boolean" then data.showTimestamps = true end
    if type(data.compactMessages) ~= "boolean" then data.compactMessages = false end
    if type(data.showReadReceipts) ~= "boolean" then data.showReadReceipts = true end
    if type(data.showSystemMessages) ~= "boolean" then data.showSystemMessages = true end
    if type(data.friendNotifications) ~= "boolean" then data.friendNotifications = true end
    if type(data.pingNotifications) ~= "boolean" then data.pingNotifications = true end
    if type(data.attachmentNotifications) ~= "boolean" then data.attachmentNotifications = true end
    if type(data.allowAttachments) ~= "boolean" then data.allowAttachments = true end
    if type(data.autoPlayAudio) ~= "boolean" then data.autoPlayAudio = false end
    if type(data.autoCleanupAttachments) ~= "boolean" then data.autoCleanupAttachments = true end
    if tonumber(data.attachmentExpireDays) == nil then data.attachmentExpireDays = APP.attachmentDefaultExpireDays end
    data.attachmentExpireDays = tonumber(data.attachmentExpireDays) or APP.attachmentDefaultExpireDays
    if tonumber(data.attachmentStorageLimitKB) == nil then data.attachmentStorageLimitKB = APP.attachmentStorageLimitKB end
    data.attachmentStorageLimitKB = tonumber(data.attachmentStorageLimitKB) or APP.attachmentStorageLimitKB
    if type(data.legacyAttachmentNotice) ~= "boolean" then data.legacyAttachmentNotice = true end
    if type(data.attachmentLog) ~= "table" then data.attachmentLog = {} end
    if type(data.autoHistorySync) ~= "boolean" then data.autoHistorySync = true end
    if data.dmPrivacy ~= "friends" and data.dmPrivacy ~= "none" then data.dmPrivacy = "anyone" end
    if type(data.autoJoinPublicGroups) ~= "boolean" then data.autoJoinPublicGroups = true end
    if type(data.requireFriendForHistory) ~= "boolean" then data.requireFriendForHistory = false end
    if type(data.autoBlockFlood) ~= "boolean" then data.autoBlockFlood = false end
    if type(data.securityAlerts) ~= "boolean" then data.securityAlerts = true end
    if type(data.muted) ~= "table" then data.muted = {} end
    if type(data.trusted) ~= "table" then data.trusted = {} end
    if type(data.knownIdentities) ~= "table" then data.knownIdentities = {} end
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
    state.legacyCompatMode = data.legacyCompatMode
    state.updateBranch = data.updateBranch
    state.updateCustomBranch = data.updateCustomBranch
    state.useSystemSlashChannel = data.useSystemSlashChannel
    state.showOldClientTags = data.showOldClientTags
    state.suppressRemoteVersionWarnings = data.suppressRemoteVersionWarnings
    state.showTimestamps = data.showTimestamps
    state.compactMessages = data.compactMessages
    state.showReadReceipts = data.showReadReceipts
    state.showSystemMessages = data.showSystemMessages
    state.friendNotifications = data.friendNotifications
    state.pingNotifications = data.pingNotifications
    state.attachmentNotifications = data.attachmentNotifications
    state.allowAttachments = data.allowAttachments
    state.autoPlayAudio = data.autoPlayAudio
    state.autoCleanupAttachments = data.autoCleanupAttachments
    state.attachmentExpireDays = data.attachmentExpireDays
    state.attachmentStorageLimitKB = data.attachmentStorageLimitKB
    state.legacyAttachmentNotice = data.legacyAttachmentNotice
    state.attachmentLog = data.attachmentLog
    state.autoHistorySync = data.autoHistorySync
    state.dmPrivacy = data.dmPrivacy
    state.autoJoinPublicGroups = data.autoJoinPublicGroups
    state.requireFriendForHistory = data.requireFriendForHistory
    state.autoBlockFlood = data.autoBlockFlood
    state.securityAlerts = data.securityAlerts
    state.muted = data.muted
    state.trusted = data.trusted
    state.knownIdentities = data.knownIdentities
    state.convos = data.convos

    if not state.convos.global then
        state.convos.global = defaultPrefs().convos.global
    end

    if not state.convos.system then
        state.convos.system = {
            key = "system",
            title = "system",
            type = "system",
            private = true,
            listed = false,
            owner = "local",
            unread = 0,
            last = 0,
            localOnly = true
        }
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

local function ensureSystemChannel()
    ensureConvo("system", "system", "system", true, false, "local")
    if state.convos.system then
        state.convos.system.localOnly = true
        state.convos.system.listed = false
        state.convos.system.private = true
    end
end

local function commandOutputKey(key)
    if key then return key end
    if state._slashCommandActive and state.useSystemSlashChannel ~= false then
        ensureSystemChannel()
        state.slashOpenedSystemOutput = true
        return "system"
    end
    return state.current
end

local function systemMessage(body, key)
    addMessage(commandOutputKey(key), "system", body, "system")
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
    if shouldShareHistoryWith and not shouldShareHistoryWith(publicId) then return end

    local now = os.clock()
    if state.historySyncLast[publicId] and now - state.historySyncLast[publicId] < APP.historySyncCooldown then
        return
    end

    state.historySyncLast[publicId] = now

    safeSendTo(senderId, "history_request", {
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

        if (m.kind == "system" or m.kind == "warn") and state.showSystemMessages == false then
            -- hidden by user preference
        else
            if m.kind == "system" then
                color = T().muted
                prefix = state.compactMessages and "- " or "i "
            elseif m.kind == "warn" then
                color = T().danger
                prefix = "! "
            elseif m.kind == "pm" then
                color = colors.purple
                prefix = state.compactMessages and "@ " or "DM "
            else
                color = T().text

                local name = tostring(m.from or "user")
                if state.compactMessages and #name > 12 then name = trim(name, 12) end

                if state.showTimestamps == false or isPocket() then
                    prefix = name .. ": "
                else
                    prefix = "[" .. tostring(m.time or "") .. "] " .. name .. ": "
                end
            end

            local wrapped = wrapText(prefix, m.body, width, color)

            for _, line in ipairs(wrapped) do
                line.color = color
                table.insert(visual, line)
            end

            if state.showReadReceipts ~= false and m.outgoing and m.seen then
                table.insert(visual, {
                    text = state.compactMessages and "  OK Seen" or "  Seen",
                    color = T().muted
                })
            end
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

    if state.showOldClientTags ~= false and publicId and remoteIsOld(publicId) then
        base = base .. " [OLD]"
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
    value = tostring(value or ""):gsub("^@", ""):gsub("^#", "")

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

local function makePacket(kind, data, legacyVersion, plainLegacy)
    data = data or {}

    data.app = APP.name
    data.version = tonumber(legacyVersion) or protocolVersion()
    if not plainLegacy then
        data.appVersion = appVersion()
        data.protocolName = protocolName()
    else
        data.appVersion = nil
        data.protocolName = nil
    end
    data.kind = kind
    data.user = state.username
    data.publicId = state.publicId
    data.nodeId = os.getComputerID()
    data.profile = state.profile
    data.time = os.time()
    data.packetId = data.packetId or randomToken(12)

    return data
end

function makeLegacyPacket(kind, data)
    local target = legacyMirrorVersion()
    if not target then return nil end
    local copy = {}
    for k, v in pairs(data or {}) do copy[k] = v end
    copy.compatMirror = true
    copy.sourceProtocolVersion = protocolVersion()
    copy.sourceAppVersion = appVersion()
    -- IMPORTANT: legacy mirrors must use a different packetId from the modern packet.
    -- Older clients dedupe by publicId:packetId before they check version. If the
    -- modern v19 packet and the v15 mirror share the same packetId, old v15 clients
    -- see the modern packet first, mark it as seen, then drop the valid mirror.
    copy.packetId = "legacy-" .. randomToken(12)
    local info = legacyCompatInfo()
    local plain = info.plain == true
    local packet = makePacket(kind, copy, target, plain)
    if info.protocolName and not plain then
        packet.protocolName = info.protocolName
    end
    return packet
end

local function broadcast(kind, data)
    if not state.username or not state.publicId then return end
    rednet.broadcast(makePacket(kind, data), APP.protocol)
    if shouldMirrorForLegacy(kind) then
        local legacy = makeLegacyPacket(kind, data)
        if legacy then rednet.broadcast(legacy, APP.protocol) end
    end
end

sendTo = function(id, kind, data)
    if not state.username or not state.publicId then return end
    rednet.send(id, makePacket(kind, data), APP.protocol)
    if shouldMirrorForLegacy(kind) then
        local legacy = makeLegacyPacket(kind, data)
        if legacy then rednet.send(id, legacy, APP.protocol) end
    end
end

function safeSendTo(id, kind, data)
    if type(sendTo) == "function" then
        return sendTo(id, kind, data)
    end
    if not state.username or not state.publicId then return end
    if rednet and rednet.send then
        return rednet.send(id, makePacket(kind, data), APP.protocol)
    end
end



-- ============================================================
-- Update branch helpers
-- ============================================================

local httpRead

UPDATE_BRANCHES = {
    { key = "main", label = "main", branch = "main", note = "default branch" },
    { key = "aegis", label = "aegis", branch = "aegis", note = "Aegis major branch" },
    { key = "obsidian", label = "obsidian", branch = "obsidian", note = "Obsidian legacy branch" },
    { key = "custom", label = "custom", branch = nil, note = "type your own branch" }
}

function githubBranchesApiUrl()
    return "https://api.github.com/repos/" .. tostring(APP.updateOwner or "benchware") .. "/" .. tostring(APP.updateRepo or "Xenit-Chat") .. "/branches?per_page=100"
end

function parseGitHubBranches(raw)
    local out = {}
    if type(raw) ~= "string" or raw == "" then return out end

    if textutils and textutils.unserializeJSON then
        local ok, data = pcall(textutils.unserializeJSON, raw)
        if ok and type(data) == "table" then
            for _, item in ipairs(data) do
                if type(item) == "table" and type(item.name) == "string" then
                    local name = sanitizeUpdateBranch(item.name)
                    if name ~= "" then
                        table.insert(out, { key = name, label = name, branch = name, note = "GitHub branch" })
                    end
                end
            end
        end
    end

    -- Fallback parser for older CraftOS builds without JSON helpers.
    if #out == 0 then
        for name in raw:gmatch('"name"%s*:%s*"([^"]+)"') do
            name = sanitizeUpdateBranch(name)
            if name ~= "" then
                table.insert(out, { key = name, label = name, branch = name, note = "GitHub branch" })
            end
        end
    end

    table.sort(out, function(a, b)
        if a.key == "main" then return true end
        if b.key == "main" then return false end
        return tostring(a.key) < tostring(b.key)
    end)

    return out
end

function getUpdateBranches()
    local list = {}
    local seen = {}

    local function add(item)
        if type(item) ~= "table" then return end
        local key = sanitizeUpdateBranch(item.key or item.branch or item.label or "")
        if key == "" or seen[key] then return end
        seen[key] = true
        table.insert(list, { key = key, label = item.label or key, branch = item.branch or key, note = item.note or "" })
    end

    if type(state.updateBranchesRemote) == "table" and #state.updateBranchesRemote > 0 then
        for _, item in ipairs(state.updateBranchesRemote) do add(item) end
        add({ key = "custom", label = "custom", branch = nil, note = "type your own branch" })
    else
        for _, item in ipairs(UPDATE_BRANCHES) do add(item) end
    end

    return list
end

function refreshUpdateBranches(silent, targetKey)
    if not httpRead then
        if not silent then systemMessage("Branch refresh unavailable until updater is loaded.", targetKey) end
        return false
    end

    local raw, err = httpRead(githubBranchesApiUrl())
    if not raw then
        state.updateBranchesStatus = "fallback"
        if not silent then systemMessage("Branch refresh failed: " .. tostring(err) .. ". Using fallback branches.", targetKey) end
        return false
    end

    local branches = parseGitHubBranches(raw)
    if #branches == 0 then
        state.updateBranchesStatus = "fallback"
        if not silent then systemMessage("Branch refresh failed: no branches found. Using fallback branches.", targetKey) end
        return false
    end

    state.updateBranchesRemote = branches
    state.updateBranchesStatus = "github"
    state.branchScroll = 0
    if not silent then
        local names = {}
        for i, item in ipairs(branches) do names[i] = item.key end
        systemMessage("GitHub branches loaded: " .. table.concat(names, ", "), targetKey)
    end
    return true
end

function sanitizeUpdateBranch(value)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    value = value:gsub("^refs/heads/", "")
    value = value:gsub("^origin/", "")

    -- Keep branch names friendly for CraftOS and raw.githubusercontent.com.
    value = value:gsub("[^%w%._%-%/]", "")
    value = value:gsub("/+", "/")
    value = value:gsub("^/+", ""):gsub("/+$", "")

    if value == "" then return "main" end
    return value
end

function selectedUpdateBranch()
    local key = state.updateBranch or "main"
    if key == "custom" then
        return sanitizeUpdateBranch(state.updateCustomBranch or "main")
    end

    for _, item in ipairs(getUpdateBranches()) do
        if item.key == key then
            return sanitizeUpdateBranch(item.branch or item.key)
        end
    end

    return sanitizeUpdateBranch(key)
end

function updateBranchLabel()
    local key = state.updateBranch or "main"
    if key == "custom" then
        return "custom: " .. selectedUpdateBranch()
    end
    return selectedUpdateBranch()
end

function updateUrlForBranch(branch)
    branch = sanitizeUpdateBranch(branch or selectedUpdateBranch())
    return "https://raw.githubusercontent.com/" .. tostring(APP.updateOwner or "benchware") .. "/" .. tostring(APP.updateRepo or "Xenit-Chat") .. "/" .. branch .. "/" .. tostring(APP.updatePath or "xenitchat.lua")
end

function setUpdateBranch(key, customValue)
    key = tostring(key or "main")
    local exists = false
    for _, item in ipairs(getUpdateBranches()) do
        if item.key == key then exists = true break end
    end
    if not exists then key = "custom" end

    state.updateBranch = key
    if customValue and tostring(customValue) ~= "" then
        state.updateCustomBranch = sanitizeUpdateBranch(customValue)
    elseif key ~= "custom" then
        state.updateCustomBranch = state.updateCustomBranch or ""
    elseif not state.updateCustomBranch or state.updateCustomBranch == "" then
        state.updateCustomBranch = "main"
    end

    APP.updateUrl = updateUrlForBranch(selectedUpdateBranch())
    savePrefs()
end

function openUpdateBranchDropdown()
    state.modal = "update_branch"
    state.modalInput = ""
    state.branchScroll = 0
end

function openCustomUpdateBranchModal()
    state.modal = "update_branch_custom"
    state.modalInput = selectedUpdateBranch()
end

function showUpdateBranchInfo()
    systemMessage("Updater branch: " .. updateBranchLabel())
    systemMessage("Updater URL: " .. updateUrlForBranch(selectedUpdateBranch()))
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

function httpRead(url)
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
    if type(raw) ~= "string" then return nil end

    -- IMPORTANT: Lua returns only the first capture when assigned to one variable.
    -- The old parser captured the quote character first, so GitHub showed as v".
    local _, quoted = raw:match("version%s*=%s*([\"'])([%w%.%-_]+)%1")
    if quoted and quoted ~= "" then return quoted end

    local numeric = raw:match("version%s*=%s*(%d+[%d%.]*)")
    if numeric and numeric ~= "" then return numeric end

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
        systemMessage("Checking GitHub branch " .. updateBranchLabel() .. " for updates...", targetKey)
    end

    local branch = selectedUpdateBranch()
    local updateUrl = updateUrlForBranch(branch)
    APP.updateUrl = updateUrl
    local raw, err = httpRead(updateUrl)
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

    local cmp = compareVersions(remoteVersion, appVersion())

    if cmp <= 0 and not force then
        if not auto then
            if cmp == 0 then
                systemMessage("Already up to date. Local v" .. appVersion() .. ", GitHub " .. updateBranchLabel() .. " v" .. tostring(remoteVersion) .. ".", targetKey)
            else
                systemMessage("Local build is newer than GitHub " .. updateBranchLabel() .. ". Local v" .. appVersion() .. ", remote v" .. tostring(remoteVersion) .. ". Use /update force to downgrade/install anyway.", targetKey)
            end
        end
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
        systemMessage("Update available: v" .. tostring(remoteVersion) .. " on GitHub branch " .. updateBranchLabel() .. ". Type /update install.", targetKey)
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
    value = tostring(value or ""):gsub("^@", ""):gsub("^#", "")
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
    if state.allowOldClients and (state.legacyCompatMode == "off" or not state.legacyCompatMode) then
        state.legacyCompatMode = "accept"
    elseif not state.allowOldClients then
        state.legacyCompatMode = "off"
    end
    savePrefs()
    systemMessage("Talk to older clients: " .. (shouldAcceptOldClients() and (legacyCompatLabel() .. " (BUGGY)") or "OFF") .. ".")
end

function cycleLegacyCompatMode()
    local current = state.legacyCompatMode or "accept"
    local pos = 1
    for i, key in ipairs(LEGACY_COMPAT_ORDER) do
        if key == current then pos = i break end
    end
    pos = pos + 1
    if pos > #LEGACY_COMPAT_ORDER then pos = 1 end
    setLegacyCompatMode(LEGACY_COMPAT_ORDER[pos])
end

function openCompatDropdown()
    state.modal = "compat_dropdown"
    state.modalInput = ""
    state.compatScroll = 0
end

local function showVersionInfo()
    systemMessage("XenitChat v" .. appVersion() .. " | Protocol " .. protocolName() .. " #" .. tostring(protocolVersion()) .. " | old-client mode: " .. legacyCompatLabel())
end


function pingId()
    return "ping-" .. tostring(os.getComputerID()) .. "-" .. randomToken(8)
end

function pingMs(started)
    return math.max(0, math.floor((os.clock() - (started or os.clock())) * 1000 + 0.5))
end

function rememberPing(id, targetId, targetName, scope, key)
    state.pingPending = state.pingPending or {}
    state.pingOrder = state.pingOrder or {}
    state.pingPending[id] = { started = os.clock(), targetId = targetId, targetName = targetName, scope = scope or "user", key = key, replies = 0, names = {} }
    table.insert(state.pingOrder, id)
    while #state.pingOrder > 16 do
        local old = table.remove(state.pingOrder, 1)
        state.pingPending[old] = nil
    end
end

function sendPing(targetText)
    targetText = tostring(targetText or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cleanTarget = targetText:gsub("^@", "")
    local id = pingId()

    if cleanTarget == "everyone" or cleanTarget == "all" then
        rememberPing(id, nil, "@everyone", "everyone", nil)
        broadcast("ping", { pingId = id, scope = "everyone" })
        systemMessage("Pinging @everyone...")
        return
    end

    if cleanTarget == "here" then
        local c = state.convos[state.current] or {}
        rememberPing(id, nil, "@here", "here", state.current)
        broadcast("ping", { pingId = id, scope = "here", key = state.current, title = c.title or state.current })
        systemMessage("Pinging @here in " .. chatLabel(c, true) .. "...")
        return
    end

    if cleanTarget ~= "" then
        local publicId, user = resolveUser(cleanTarget)
        if not publicId or not user then
            systemMessage("Ping failed: user not found online. Try /people first.")
            return
        end
        local name = displayName(user.username, publicId, user.profile)
        rememberPing(id, publicId, name, "user", nil)
        local payload = { pingId = id, toPublicId = publicId, scope = "user" }
        if user.senderId then safeSendTo(user.senderId, "ping", payload) else broadcast("ping", payload) end
        systemMessage("Pinging " .. name .. "...")
        return
    end

    rememberPing(id, nil, "network", "network", nil)
    broadcast("ping", { pingId = id, scope = "network" })
    systemMessage("Pinging online clients...")
end

function receivePong(msg)
    if not msg or msg.toPublicId ~= state.publicId or not msg.pingId then return end
    local pending = state.pingPending and state.pingPending[msg.pingId]
    if not pending then return end
    local who = displayName(msg.user, msg.publicId, msg.profile)
    if pending.names[who] then return end
    pending.names[who] = true
    pending.replies = (pending.replies or 0) + 1
    systemMessage("Pong [" .. tostring(pending.scope or "ping") .. "] from " .. who .. ": " .. tostring(pingMs(pending.started)) .. " ms")
    if pending.targetId then state.pingPending[msg.pingId] = nil end
end

function shouldAnswerPing(msg)
    if not msg.pingId then return false end
    if msg.toPublicId then return msg.toPublicId == state.publicId end
    local scope = msg.scope or "network"
    if scope == "everyone" or scope == "network" then return true end
    if scope == "here" then return msg.key ~= nil and state.current == msg.key end
    return true
end

function checkPingTimeouts()
    if not state.pingPending then return end
    local now = os.clock()
    for id, pending in pairs(state.pingPending) do
        if now - (pending.started or now) > 3.5 then
            if (pending.replies or 0) == 0 then
                if pending.targetName and pending.targetName ~= "network" then
                    systemMessage("Ping timed out: " .. tostring(pending.targetName) .. " did not reply.")
                else
                    systemMessage("Ping finished: no online clients replied.")
                end
            else
                systemMessage("Ping finished: " .. tostring(pending.replies) .. " reply/replies.")
            end
            state.pingPending[id] = nil
        end
    end
end

function toggleBoolSetting(field, label)
    state[field] = not state[field]
    savePrefs()
    systemMessage(label .. ": " .. (state[field] and "ON" or "OFF") .. ".")
end

local function openSettingsModal()
    state.modal = "settings"
    state.modalInput = ""
    state.modalData = nil
end


-- ============================================================
-- Security / privacy helpers
-- ============================================================

function isFriend(publicId)
    return publicId and state.friends and state.friends[publicId] ~= nil
end

function isMuted(publicId)
    return publicId and state.muted and state.muted[publicId] ~= nil
end

function safetyCode(publicId)
    local raw = slowHash("SAFE|" .. tostring(publicId or ""), 40):gsub("%-", "")
    local out = {}
    for i = 1, 18, 3 do
        table.insert(out, raw:sub(i, i + 2))
    end
    return table.concat(out, "-")
end

function recordSecurityEvent(body)
    if not state.securityEvents then state.securityEvents = {} end
    table.insert(state.securityEvents, 1, { time = os.time(), body = tostring(body or "") })
    while #state.securityEvents > 12 do table.remove(state.securityEvents) end
    if state.securityAlerts ~= false then
        systemMessage("Security: " .. tostring(body or "notice"))
    end
end

function packetByteSize(msg)
    local ok, raw = pcall(textutils.serialize, msg)
    if ok and raw then return #raw end
    return 0
end

function rateLimited(publicId, kind)
    publicId = tostring(publicId or "unknown")
    kind = tostring(kind or "?")
    local now = os.clock()
    local key = publicId .. "|" .. kind
    local bucket = state.rateBuckets[key]
    if not bucket or now - (bucket.start or 0) > APP.floodWindow then
        state.rateBuckets[key] = { start = now, count = 1 }
        return false
    end
    bucket.count = (bucket.count or 0) + 1
    if bucket.count > APP.floodLimit then
        if state.autoBlockFlood then
            state.blocked[publicId] = true
            savePrefs()
            recordSecurityEvent("Auto-blocked flooder #" .. shortId(publicId) .. " (" .. kind .. ").")
        end
        return true
    end
    return false
end

function trustUser(publicId, user)
    if not publicId then return end
    user = user or state.users[publicId] or {}
    state.trusted[publicId] = {
        username = user.username or "unknown",
        nodeId = user.nodeId,
        code = safetyCode(publicId),
        time = os.time()
    }
    savePrefs()
    systemMessage("Trusted " .. displayName(user.username, publicId, user.profile) .. " | Safety " .. safetyCode(publicId))
end

function untrustUser(publicId)
    if not publicId then return end
    state.trusted[publicId] = nil
    savePrefs()
    systemMessage("Removed trusted device #" .. shortId(publicId) .. ".")
end

function muteUser(publicId, user)
    if not publicId then return end
    user = user or state.users[publicId] or {}
    state.muted[publicId] = { username = user.username or "unknown", time = os.time() }
    savePrefs()
    systemMessage("Muted " .. displayName(user.username, publicId, user.profile) .. ".")
end

function unmuteUser(publicId)
    if not publicId then return end
    state.muted[publicId] = nil
    savePrefs()
    systemMessage("Unmuted #" .. shortId(publicId) .. ".")
end

function shouldAcceptDm(publicId)
    if state.dmPrivacy == "none" then return false end
    if state.dmPrivacy == "friends" and not isFriend(publicId) then return false end
    return true
end

function shouldShareHistoryWith(publicId)
    if state.requireFriendForHistory and not isFriend(publicId) then return false end
    return not state.blocked[publicId]
end

function recordIdentity(publicId, msg)
    if not publicId then return end
    if not state.knownIdentities then state.knownIdentities = {} end
    local known = state.knownIdentities[publicId]
    local username = tostring(msg.user or "unknown")
    local nodeId = tostring(msg.nodeId or "?")
    if known then
        if known.username and known.username ~= username then
            recordSecurityEvent("Known ID #" .. shortId(publicId) .. " changed name from " .. known.username .. " to " .. username .. ".")
        end
        if known.nodeId and tostring(known.nodeId) ~= nodeId then
            recordSecurityEvent("Known user " .. username .. " changed device ID. Verify safety code.")
        end
    end
    state.knownIdentities[publicId] = { username = username, nodeId = nodeId, last = os.time(), code = safetyCode(publicId) }
end

function dmPrivacyLabel()
    if state.dmPrivacy == "friends" then return "Friends only" end
    if state.dmPrivacy == "none" then return "No DMs" end
    return "Anyone"
end

function cycleDmPrivacy()
    if state.dmPrivacy == "anyone" then state.dmPrivacy = "friends"
    elseif state.dmPrivacy == "friends" then state.dmPrivacy = "none"
    else state.dmPrivacy = "anyone" end
    savePrefs()
    systemMessage("DM privacy: " .. dmPrivacyLabel() .. ".")
end

function openSecurityModal()
    state.modal = "security"
    state.modalInput = ""
    state.modalData = nil
end

function showSafetyFor(value)
    if not value or value == "" then
        systemMessage("Usage: /safety @user")
        return
    end
    local id, user = resolveUser(value)
    if id then
        systemMessage("Safety for " .. displayName(user.username, id, user.profile) .. ": " .. safetyCode(id))
        systemMessage("Compare this code on both devices before trusting sensitive DMs.")
    else
        systemMessage("User not found online. Use /people first, then /safety @name.")
    end
end

function showSecurityAudit()
    local muted, trusted, blocked = 0, 0, 0
    for _ in pairs(state.muted or {}) do muted = muted + 1 end
    for _ in pairs(state.trusted or {}) do trusted = trusted + 1 end
    for _ in pairs(state.blocked or {}) do blocked = blocked + 1 end
    systemMessage("Security audit: DM=" .. dmPrivacyLabel() .. ", muted=" .. muted .. ", trusted=" .. trusted .. ", blocked=" .. blocked .. ".")
    systemMessage("History sharing requires friends: " .. ((state.requireFriendForHistory and "ON") or "OFF") .. " | Auto-block flood: " .. ((state.autoBlockFlood and "ON") or "OFF"))
end

function showPeerStatus()
    local list = getSortedUsers()
    if #list == 0 then
        systemMessage("No P2P peers online yet. Try /ping @everyone or wait for hello packets.")
        return
    end
    systemMessage("P2P peers: " .. tostring(#list) .. " online/known | compatibility: " .. legacyCompatLabel())
    for i = 1, math.min(#list, 8) do
        local u = list[i]
        local info = state.users[u.publicId] or u
        local rv = tostring(info.remoteAppVersion or info.remoteVersion or "?")
        local rp = tostring(info.remoteProtocolName or "no-codename")
        systemMessage(" - " .. displayName(info.username, u.publicId, info.profile) .. " | v" .. rv .. " | " .. rp .. " | id #" .. shortId(u.publicId))
    end
    if #list > 8 then systemMessage("...and " .. tostring(#list - 8) .. " more peer(s).") end
end

function backupLocalData()
    local suffix = tostring(os.getComputerID()) .. "_" .. tostring(os.time())
    local base = ".xenit_backup_" .. suffix
    local prefs = readSerialized(APP.prefsFile, nil)
    local history = readSerialized(APP.historyFile, nil)
    writeSerialized(base, { app = APP.name, version = appVersion(), prefs = prefs, history = history })
    systemMessage("Backup saved: " .. base)
end


-- ============================================================

-- ============================================================
-- Attachment storage lifecycle
-- ============================================================

function attachmentExpireSeconds()
    local days = tonumber(state.attachmentExpireDays or APP.attachmentDefaultExpireDays) or APP.attachmentDefaultExpireDays
    if days <= 0 then return nil end
    return days * 86400
end

function attachmentStorageLimitBytes()
    local kb = tonumber(state.attachmentStorageLimitKB or APP.attachmentStorageLimitKB) or APP.attachmentStorageLimitKB
    if kb <= 0 then return nil end
    return kb * 1024
end

function fileSizeSafe(path)
    if fs.getSize then
        local ok, size = pcall(fs.getSize, path)
        if ok and type(size) == "number" then return size end
    end
    if fs.attributes then
        local ok, attr = pcall(fs.attributes, path)
        if ok and type(attr) == "table" and type(attr.size) == "number" then return attr.size end
    end
    local raw = readText(path)
    return raw and #raw or 0
end

function attachmentLogTime(path)
    for _, item in ipairs(state.attachmentLog or {}) do
        if item.path == path then return tonumber(item.time or 0) or 0, tostring(item.kind or "file"), tostring(item.name or fs.getName(path)) end
    end
    return 0, "file", fs.getName(path)
end

function removeAttachmentLogPath(path)
    if type(state.attachmentLog) ~= "table" then return end
    for i = #state.attachmentLog, 1, -1 do
        if state.attachmentLog[i].path == path then table.remove(state.attachmentLog, i) end
    end
end

function cleanupAttachments(mode, manual)
    mode = tostring(mode or "expired"):lower()
    ensureAttachmentDir()
    state.attachmentLog = state.attachmentLog or {}

    local now = os.time()
    local expire = attachmentExpireSeconds()
    local files = {}
    local total = 0
    local removed = 0
    local removedAudio = 0
    local removedBytes = 0

    for _, name in ipairs(fs.list(APP.attachmentDir) or {}) do
        local path = fs.combine(APP.attachmentDir, name)
        if not fs.isDir(path) then
            local size = fileSizeSafe(path)
            local ts, kind, loggedName = attachmentLogTime(path)
            if ts == 0 then ts = now end
            total = total + size
            table.insert(files, { path = path, name = loggedName or name, size = size, time = ts, kind = kind })
        end
    end

    local function deleteItem(item)
        local ok = pcall(fs.delete, item.path)
        if ok then
            removed = removed + 1
            removedBytes = removedBytes + (item.size or 0)
            if item.kind == "audio" or fileExt(item.path) == "dfpwm" then removedAudio = removedAudio + 1 end
            removeAttachmentLogPath(item.path)
        end
    end

    if mode == "all" then
        for _, item in ipairs(files) do deleteItem(item) end
    elseif mode == "audio" then
        for _, item in ipairs(files) do
            if item.kind == "audio" or fileExt(item.path) == "dfpwm" then deleteItem(item) end
        end
    else
        if expire then
            for _, item in ipairs(files) do
                if now - (item.time or now) >= expire then deleteItem(item) end
            end
        end
        local limit = attachmentStorageLimitBytes()
        if limit and total - removedBytes > limit then
            table.sort(files, function(a, b) return (a.time or 0) < (b.time or 0) end)
            for _, item in ipairs(files) do
                if total - removedBytes <= limit then break end
                if fs.exists(item.path) then deleteItem(item) end
            end
        end
    end

    savePrefs()
    if manual then
        if removed == 0 then
            systemMessage("Attachment cleanup: nothing to delete.")
        else
            local label = "Attachment cleanup removed " .. tostring(removed) .. " file(s), " .. tostring(math.ceil(removedBytes / 1024)) .. " KB."
            if removedAudio > 0 then label = label .. " Audio expired: " .. tostring(removedAudio) .. "." end
            systemMessage(label)
        end
    elseif removedAudio > 0 and state.attachmentNotifications ~= false then
        addMessage("system", "system", "Audio expired: cleaned " .. tostring(removedAudio) .. " old audio attachment(s).", "system", { silent = true })
    end
end

function cycleAttachmentExpiry()
    local values = { 1, 3, 7, 14, 30, 0 }
    local cur = tonumber(state.attachmentExpireDays or 3) or 3
    local idx = 1
    for i, v in ipairs(values) do if v == cur then idx = i break end end
    idx = idx + 1
    if idx > #values then idx = 1 end
    state.attachmentExpireDays = values[idx]
    savePrefs()
    systemMessage("Attachment expiry: " .. (state.attachmentExpireDays <= 0 and "OFF" or tostring(state.attachmentExpireDays) .. " day(s)"))
end

function cycleAttachmentStorageLimit()
    local values = { 128, 256, 512, 1024, 2048, 0 }
    local cur = tonumber(state.attachmentStorageLimitKB or 256) or 256
    local idx = 1
    for i, v in ipairs(values) do if v == cur then idx = i break end end
    idx = idx + 1
    if idx > #values then idx = 1 end
    state.attachmentStorageLimitKB = values[idx]
    savePrefs()
    systemMessage("Attachment storage cap: " .. (state.attachmentStorageLimitKB <= 0 and "OFF" or tostring(state.attachmentStorageLimitKB) .. " KB"))
end

-- P2P attachments / audio
-- ============================================================

function ensureAttachmentDir()
    if not fs.exists(APP.attachmentDir) then fs.makeDir(APP.attachmentDir) end
end

function safeFilename(value)
    local s = tostring(value or "file")
    s = s:gsub("\\", "/")
    s = s:match("([^/]+)$") or "file"
    s = s:gsub("[^%w%._%- ]", "_")
    if s == "" then s = "file" end
    if #s > 40 then s = s:sub(1, 40) end
    return s
end

function fileBaseName(path)
    return safeFilename(path)
end

function fileExt(path)
    local e = tostring(path or ""):lower():match("%.([%w_%-]+)$")
    return e or ""
end

function isAudioPath(path)
    local e = fileExt(path)
    return e == "dfpwm" or e == "wav" or e == "nbs" or e == "pcm"
end

function readFileAll(path)
    if not path or path == "" then return nil, "No file path." end
    if not fs.exists(path) then return nil, "File not found: " .. tostring(path) end
    if fs.isDir(path) then return nil, "Folders cannot be sent yet." end
    local ok, f = pcall(fs.open, path, "rb")
    if not ok or not f then f = fs.open(path, "r") end
    if not f then return nil, "Could not open file." end
    local raw = f.readAll() or ""
    f.close()
    return raw
end

function writeFileAll(path, data)
    local ok, f = pcall(fs.open, path, "wb")
    if not ok or not f then f = fs.open(path, "w") end
    if not f then return false end
    f.write(data or "")
    f.close()
    return true
end

function uniqueAttachmentPath(name)
    ensureAttachmentDir()
    name = safeFilename(name)
    local path = fs.combine(APP.attachmentDir, name)
    if not fs.exists(path) then return path end
    local base, ext = name:match("^(.*)%.([^%.]+)$")
    base = base or name
    ext = ext and ("." .. ext) or ""
    for i = 1, 99 do
        local candidate = fs.combine(APP.attachmentDir, base .. "_" .. tostring(i) .. ext)
        if not fs.exists(candidate) then return candidate end
    end
    return fs.combine(APP.attachmentDir, tostring(os.time()) .. "_" .. name)
end

function attachmentTargetInfo()
    local c = state.convos[state.current] or {}
    local key = state.current or "global"
    if key == "system" or c.localOnly then
        return nil, nil, "Cannot send attachments from #system. Switch to a chat/DM first."
    end
    if c.type == "pm" then
        if not c.peerId then return nil, nil, "This DM has no valid peer ID." end
        return "pm", c.peerId, nil
    end
    return "chat", key, nil
end

function recordAttachment(path, from, name, size, kind)
    state.attachmentLog = state.attachmentLog or {}
    local now = os.time()
    local expires = nil
    local secs = attachmentExpireSeconds()
    if secs then expires = now + secs end
    table.insert(state.attachmentLog, 1, { path = path, from = from, name = name, size = size, kind = kind, time = now, expires = expires })
    while #state.attachmentLog > 80 do table.remove(state.attachmentLog) end
    savePrefs()
end

function showAttachments()
    ensureAttachmentDir()
    systemMessage("Attachments folder: " .. APP.attachmentDir .. " | expires: " .. ((tonumber(state.attachmentExpireDays or 0) or 0) <= 0 and "OFF" or tostring(state.attachmentExpireDays) .. "d") .. " | cap: " .. ((tonumber(state.attachmentStorageLimitKB or 0) or 0) <= 0 and "OFF" or tostring(state.attachmentStorageLimitKB) .. "KB"))
    systemMessage("Use /cleanattachments expired|audio|all to free storage.")
    if not state.attachmentLog or #state.attachmentLog == 0 then
        systemMessage("No received attachments yet. Use /attach path or /audio path.dfpwm.")
        return
    end
    for i = 1, math.min(#state.attachmentLog, 6) do
        local a = state.attachmentLog[i]
        systemMessage(" - " .. tostring(a.name) .. " from " .. tostring(a.from or "?") .. " -> " .. tostring(a.path))
    end
end

function playAudioFile(path)
    if not path or path == "" then
        systemMessage("Usage: /play path.dfpwm")
        return
    end
    local speaker = peripheral.find and peripheral.find("speaker")
    if not speaker then
        systemMessage("No speaker peripheral found. Attach a speaker to play DFPWM audio.")
        return
    end
    local data, err = readFileAll(path)
    if not data then systemMessage(err or "Could not read audio file.") return end
    if fileExt(path) ~= "dfpwm" then
        systemMessage("Only DFPWM playback is supported directly. File saved, but convert audio to .dfpwm for playback.")
        return
    end
    local ok, dfpwm = pcall(require, "cc.audio.dfpwm")
    if not ok or not dfpwm then
        systemMessage("DFPWM decoder unavailable in this CraftOS build.")
        return
    end
    local decoder = dfpwm.make_decoder()
    local chunkSize = 16 * 1024
    systemMessage("Playing " .. fileBaseName(path) .. "...")
    for i = 1, #data, chunkSize do
        local buffer = decoder(data:sub(i, i + chunkSize - 1))
        while not speaker.playAudio(buffer) do os.pullEvent("speaker_audio_empty") end
    end
end


function sendLegacyAttachmentNotice(base, kind, name, size)
    if state.legacyAttachmentNotice == false then return end
    if not legacyMirrorVersion() then return end
    local kb = tostring(math.ceil((tonumber(size) or 0) / 1024)) .. " KB"
    local body = "[unsupported attachment] " .. tostring(kind or "file") .. ": " .. tostring(name or "file") .. " (" .. kb .. "). Update XenitChat to receive attachments."
    local data = {}
    if base.mode == "pm" then
        data.toPublicId = base.target
        data.toName = base.title
        data.body = body
        data.compatAttachmentNotice = true
        data.msgId = "legacy-attach-" .. tostring(base.transferId or randomToken(8))
        local packet = makeLegacyPacket("pm", data)
        if packet then rednet.broadcast(packet, APP.protocol) end
    else
        data.key = base.key
        data.title = base.title
        data.private = false
        data.listed = true
        data.body = body
        data.compatAttachmentNotice = true
        data.msgId = "legacy-attach-" .. tostring(base.transferId or randomToken(8))
        local packet = makeLegacyPacket("chat", data)
        if packet then rednet.broadcast(packet, APP.protocol) end
    end
end

function sendAttachment(path, forcedKind)
    if state.allowAttachments == false then
        systemMessage("Attachments are disabled in Settings.")
        return
    end
    local mode, target, err = attachmentTargetInfo()
    if err then systemMessage(err) return end
    local raw, readErr = readFileAll(path)
    if not raw then systemMessage(readErr or "Could not read file.") return end
    if #raw <= 0 then systemMessage("Cannot send an empty file.") return end
    if #raw > APP.maxAttachmentBytes then
        systemMessage("Attachment too large: " .. tostring(math.ceil(#raw / 1024)) .. " KB. Limit is " .. tostring(math.floor(APP.maxAttachmentBytes / 1024)) .. " KB.")
        return
    end

    local name = fileBaseName(path)
    local kind = forcedKind or (isAudioPath(path) and "audio" or "file")
    local transferId = randomToken(12)
    local chunkSize = APP.attachmentChunkSize
    local total = math.ceil(#raw / chunkSize)
    local c = state.convos[state.current] or {}

    local base = { transferId = transferId, key = state.current, title = c.title or state.current, mode = mode, target = target, filename = name, size = #raw, total = total, attachmentKind = kind }
    sendLegacyAttachmentNotice(base, kind, name, #raw)
    broadcast("attachment_start", base)
    for i = 1, total do
        broadcast("attachment_chunk", { transferId = transferId, mode = mode, target = target, index = i, data = raw:sub((i - 1) * chunkSize + 1, i * chunkSize) })
    end
    broadcast("attachment_end", { transferId = transferId, mode = mode, target = target })

    local label = (kind == "audio" and "[audio] " or "[file] ") .. name .. " (" .. tostring(math.ceil(#raw / 1024)) .. " KB)"
    addMessage(state.current, myName(), label, c.type == "pm" and "pm" or "chat", { outgoing = true, msgId = transferId })
    if state.autoCleanupAttachments ~= false then cleanupAttachments("expired", false) end
    systemMessage("Attachment sent: " .. name .. " in " .. tostring(total) .. " chunk(s). Older clients see an unsupported-attachment note.")
end

function attachmentPacketIntended(msg)
    if msg.mode == "pm" then return msg.target == state.publicId end
    if msg.mode == "chat" then
        if msg.key == "global" then return true end
        return state.convos[msg.key] ~= nil or (state.autoJoinPublicGroups ~= false and msg.key and msg.key ~= "system")
    end
    return false
end

function receiveAttachmentStart(msg)
    if state.allowAttachments == false then return end
    if not attachmentPacketIntended(msg) then return end
    if tonumber(msg.size or 0) > APP.maxAttachmentBytes then
        recordSecurityEvent("Dropped oversized attachment from " .. tostring(msg.user or "unknown") .. ".")
        return
    end
    state.pendingTransfers = state.pendingTransfers or {}
    state.pendingTransfers[msg.transferId] = { from = msg.user, fromId = msg.publicId, key = msg.key or "global", filename = safeFilename(msg.filename), size = tonumber(msg.size or 0), total = tonumber(msg.total or 0), kind = msg.attachmentKind or "file", chunks = {}, started = os.clock() }
    if state.attachmentNotifications ~= false then
        systemMessage("Receiving " .. tostring(msg.attachmentKind or "file") .. ": " .. safeFilename(msg.filename) .. " from " .. displayName(msg.user, msg.publicId, msg.profile) .. ".")
    end
end

function receiveAttachmentChunk(msg)
    local t = state.pendingTransfers and state.pendingTransfers[msg.transferId]
    if not t then return end
    if os.clock() - (t.started or 0) > APP.attachmentTimeout then
        state.pendingTransfers[msg.transferId] = nil
        recordSecurityEvent("Attachment transfer timed out.")
        return
    end
    local idx = tonumber(msg.index or 0)
    if idx < 1 or idx > (t.total or 0) then return end
    t.chunks[idx] = tostring(msg.data or "")
end

function receiveAttachmentEnd(msg)
    local t = state.pendingTransfers and state.pendingTransfers[msg.transferId]
    if not t then return end
    local parts = {}
    local size = 0
    for i = 1, t.total do
        if not t.chunks[i] then
            systemMessage("Attachment incomplete: " .. tostring(t.filename) .. ".")
            return
        end
        parts[i] = t.chunks[i]
        size = size + #parts[i]
    end
    if size > APP.maxAttachmentBytes then
        state.pendingTransfers[msg.transferId] = nil
        recordSecurityEvent("Dropped attachment after size check.")
        return
    end
    local path = uniqueAttachmentPath(t.filename)
    if not writeFileAll(path, table.concat(parts)) then
        systemMessage("Could not save attachment: " .. tostring(t.filename))
        return
    end
    state.pendingTransfers[msg.transferId] = nil
    recordAttachment(path, t.from, t.filename, size, t.kind)
    local key = t.key or "global"
    if key ~= "system" then ensureConvo(key, key, "public", false, true, t.from or "unknown") end
    local label = (t.kind == "audio" and "[audio received] " or "[file received] ") .. t.filename .. " -> " .. path
    addMessage(key, displayName(t.from, t.fromId, nil), label, "system", { msgId = msg.transferId })
    if state.autoCleanupAttachments ~= false then cleanupAttachments("expired", false) end
    if t.kind == "audio" and state.autoPlayAudio == true and fileExt(path) == "dfpwm" then
        playAudioFile(path)
    end
end

COMMAND_HELP = {
    {
        title = "Navigate",
        items = {
            { cmd = "/help", args = "[command]", desc = "Show this Discord-style command list.", aliases = {"/?", "/commands", "/slash", "/shortcuts"} },
            { cmd = "/menu", desc = "Open the main menu." },
            { cmd = "/chats", desc = "Open your chat list." },
            { cmd = "/settings", desc = "Open settings and compatibility toggles.", aliases = {"/prefs"} },
            { cmd = "/security", desc = "Open Security Center.", aliases = {"/safe", "/privacy"} },
            { cmd = "/theme", desc = "Pick a theme." }
        }
    },
    {
        title = "People",
        items = {
            { cmd = "/people", desc = "Open people/friends.", aliases = {"/friends"} },
            { cmd = "/pm", args = "@name-or-id", desc = "Open a direct message.", aliases = {"/msg", "/dm"} },
            { cmd = "/friend", args = "@name-or-id", desc = "Send a friend request.", aliases = {"/add"} },
            { cmd = "/inbox", desc = "Open friend request inbox.", aliases = {"/requests"} },
            { cmd = "/block", args = "@name-or-id", desc = "Block a user." },
            { cmd = "/unblock", args = "@name-or-id", desc = "Unblock a user." },
            { cmd = "/mute", args = "@name-or-id", desc = "Hide messages from a user without blocking." },
            { cmd = "/unmute", args = "@name-or-id", desc = "Allow messages from a muted user again." },
            { cmd = "/trust", args = "@name-or-id", desc = "Trust a user after comparing safety code." },
            { cmd = "/untrust", args = "@name-or-id", desc = "Remove a trusted user." },
            { cmd = "/safety", args = "@name-or-id", desc = "Show a user safety code." },
            { cmd = "/who", desc = "List online users.", aliases = {"/online"} },
            { cmd = "/peers", desc = "Show P2P peer versions, old tags, and sender IDs.", aliases = {"/net", "/network"} },
            { cmd = "/ping", args = "[@user|@here|@everyone]", desc = "Check latency to a user, current chat, or everyone." },
            { cmd = "/id", desc = "Show your short ID.", aliases = {"/myid"} }
        }
    },
    {
        title = "Chats & groups",
        items = {
            { cmd = "/discover", desc = "Find public groups.", aliases = {"/d"} },
            { cmd = "/new", args = "#group", desc = "Create a public group.", aliases = {"/group"} },
            { cmd = "/join", args = "#group", desc = "Join a public group." },
            { cmd = "/rename", args = "new name", desc = "Rename the current group." },
            { cmd = "/leave", desc = "Leave the current group." },
            { cmd = "/info", desc = "Open current chat settings.", aliases = {"/chatsettings"} },
            { cmd = "/pin", desc = "Pin or unpin this chat.", aliases = {"/unpin"} },
            { cmd = "/readall", desc = "Mark all chats as read.", aliases = {"/read"} },
            { cmd = "/clear", desc = "Clear this local chat history." }
        }
    },
    {
        title = "Profile",
        items = {
            { cmd = "/status", args = "text", desc = "Set your status." },
            { cmd = "/name", args = "display name", desc = "Set your display name." }
        }
    },

    {
        title = "Attachments",
        items = {
            { cmd = "/attach", args = "path", desc = "Send a small file to the current chat/DM using P2P chunks." },
            { cmd = "/script", args = "path.lua", desc = "Send a Lua script attachment. Receiver must choose to run it manually." },
            { cmd = "/audio", args = "path.dfpwm", desc = "Send an audio attachment. DFPWM plays best on speaker peripherals." },
            { cmd = "/play", args = "path", desc = "Play a local/received DFPWM audio file through a speaker." },
            { cmd = "/attachments", desc = "Show received attachment folder and recent transfer info.", aliases = {"/files"} },
            { cmd = "/cleanattachments", args = "[expired|audio|all]", desc = "Clear expired attachments, audio files, or every received attachment." }
        }
    },
    {
        title = "System",
        items = {
            { cmd = "/sync", desc = "Request chat history sync.", aliases = {"/history"} },
            { cmd = "/update", args = "[check|install|force|branch <name>]", desc = "Check/install GitHub update from selected branch." },
            { cmd = "/branch", args = "[name|refresh]", desc = "Choose or refresh GitHub branches for updater." },
            { cmd = "/version", desc = "Show app/protocol version.", aliases = {"/about"} },
            { cmd = "/compat", desc = "Cycle old-client target: Generic, v15, v18, v7, v19 plain. BUGGY.", aliases = {"/legacy", "/oldclients"} },
            { cmd = "/quiet", desc = "Toggle version warning noise filter." },
            { cmd = "/privacy", desc = "Cycle DM privacy: anyone, friends-only, no DMs." },
            { cmd = "/audit", desc = "Run a quick security audit." },
            { cmd = "/backup", desc = "Backup preferences and local chat history." },
            { cmd = "/app", desc = "Open app controls.", aliases = {"/controls"} },
            { cmd = "/logout", desc = "Logout to the login screen." },
            { cmd = "/exit", desc = "Close XenitChat.", aliases = {"/quit", "/close"} },
            { cmd = "/restart", desc = "Restart XenitChat.", aliases = {"/reload"} },
            { cmd = "/reboot", desc = "Reboot this CraftOS computer." }
        }
    }
}

function normalizeCommandName(value)
    value = tostring(value or ""):lower():gsub("^/", "")
    return value
end

function iterCommands()
    local out = {}
    for _, cat in ipairs(COMMAND_HELP) do
        for _, item in ipairs(cat.items or {}) do
            table.insert(out, item)
        end
    end
    return out
end

function commandNames(item)
    local names = { item.cmd }
    for _, alias in ipairs(item.aliases or {}) do
        table.insert(names, alias)
    end
    return names
end

function commandLine(item)
    local args = item.args and (" " .. item.args) or ""
    return item.cmd .. args .. " - " .. item.desc
end

function findCommandHelp(name)
    name = normalizeCommandName(name)
    if name == "" then return nil end
    for _, item in ipairs(iterCommands()) do
        if normalizeCommandName(item.cmd) == name then return item end
        for _, alias in ipairs(item.aliases or {}) do
            if normalizeCommandName(alias) == name then return item end
        end
    end
    return nil
end

function suggestCommand(name)
    name = normalizeCommandName(name)
    if name == "" then return nil end
    for _, item in ipairs(iterCommands()) do
        for _, candidate in ipairs(commandNames(item)) do
            local c = normalizeCommandName(candidate)
            if c:sub(1, #name) == name or name:sub(1, #c) == c then
                return item.cmd
            end
        end
    end
    return nil
end

function showHelpForCommand(name)
    local item = findCommandHelp(name)
    if not item then
        local maybe = suggestCommand(name)
        if maybe then
            systemMessage("No command named /" .. normalizeCommandName(name) .. ". Did you mean " .. maybe .. "?")
        else
            systemMessage("No command named /" .. normalizeCommandName(name) .. ". Use /help for all commands.")
        end
        return
    end

    local usage = item.cmd .. (item.args and (" " .. item.args) or "")
    systemMessage("Command: " .. usage)
    systemMessage("  " .. item.desc)
    if item.aliases and #item.aliases > 0 then
        systemMessage("  Also: " .. table.concat(item.aliases, ", "))
    end
end

local function handleSlashCommand(body)
    if body:sub(1, 1) ~= "/" then return false end

    local command, rest = body:match("^/(%S+)%s*(.*)$")
    command = command and command:lower() or ""
    rest = rest or ""
    local slashOrigin = state.current
    state._slashCommandActive = true
    state.slashOpenedSystemOutput = false

    if command == "help" or command == "?" or command == "commands" or command == "slash" or command == "shortcuts" then
        if rest ~= "" then
            showHelpForCommand(rest)
        else
            state.modal = "help"
        end
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
    elseif command == "security" or command == "safe" then
        openSecurityModal()
    elseif command == "privacy" then
        if rest == "" then cycleDmPrivacy() else openSecurityModal() end
    elseif command == "discover" or command == "d" then
        requestDiscovery()
    elseif command == "update" then
        local mode = rest:lower()
        if mode == "install" or mode == "now" then
            checkForUpdate(false, true, false, nil)
        elseif mode == "force" then
            checkForUpdate(false, true, true, nil)
        elseif mode:match("^branch%s+") then
            local br = rest:match("^%S+%s+(.+)$") or ""
            setUpdateBranch("custom", br)
            systemMessage("Update branch set to " .. updateBranchLabel() .. ".")
        elseif mode == "branch refresh" or mode == "branches refresh" or mode == "refresh branches" then
            refreshUpdateBranches(false, nil)
            openUpdateBranchDropdown()
        elseif mode == "branch" or mode == "branches" then
            openUpdateBranchDropdown()
        else
            checkForUpdate(false, false, false, nil)
        end
    elseif command == "branch" or command == "branches" then
        local lowerRest = rest:lower()
        if lowerRest == "refresh" or lowerRest == "reload" or lowerRest == "scan" then
            refreshUpdateBranches(false, nil)
            openUpdateBranchDropdown()
        elseif rest ~= "" then
            setUpdateBranch("custom", rest)
            systemMessage("Update branch set to " .. updateBranchLabel() .. ".")
        else
            openUpdateBranchDropdown()
        end
    elseif command == "who" or command == "online" then
        listOnlineUsers()
    elseif command == "peers" or command == "net" or command == "network" then
        showPeerStatus()
    elseif command == "id" or command == "myid" then
        showMyId()
    elseif command == "read" or command == "readall" then
        markAllRead()
    elseif command == "pin" or command == "unpin" then
        togglePinCurrent()
    elseif command == "quiet" then
        toggleQuietVersionWarnings()
    elseif command == "compat" or command == "legacy" or command == "oldclients" then
        openCompatDropdown()
    elseif command == "audit" then
        showSecurityAudit()
    elseif command == "backup" then
        backupLocalData()
    elseif command == "ping" then
        sendPing(rest)
    elseif command == "attach" then
        if rest == "" then systemMessage("Usage: /attach path") else sendAttachment(rest, nil) end
    elseif command == "script" then
        if rest == "" then systemMessage("Usage: /script path.lua") else sendAttachment(rest, "script") end
    elseif command == "audio" then
        if rest == "" then systemMessage("Usage: /audio path.dfpwm") else sendAttachment(rest, "audio") end
    elseif command == "play" then
        playAudioFile(rest)
    elseif command == "attachments" or command == "files" then
        showAttachments()
    elseif command == "cleanattachments" or command == "cleanupattachments" or command == "clearattachments" then
        local mode = rest ~= "" and rest or "expired"
        cleanupAttachments(mode, true)

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
        if rest ~= "" then joinGroup(rest:gsub("^#", "")) else systemMessage("Usage: /join #group") end
    elseif command == "new" or command == "group" then
        if rest ~= "" then createGroup(rest:gsub("^#", ""), "public") else systemMessage("Usage: /new #group") end
    elseif command == "rename" then
        if rest ~= "" then renameCurrentGroup(rest) else systemMessage("Usage: /rename new group name") end
    elseif command == "leave" then
        leaveCurrentGroup()
    elseif command == "info" or command == "chatsettings" then
        openGroupSettings()
    elseif command == "pm" or command == "msg" or command == "dm" then
        if rest == "" then
            showHelpForCommand("pm")
        else
            local id, user = resolveUser(rest)
            if id then openPM(id, user) else systemMessage("User not found online. Try /people or /pm @shortid.") end
        end
    elseif command == "add" or command == "friend" then
        if rest == "" then
            showHelpForCommand("friend")
        else
            local id, user = resolveUser(rest)
            if id and user then sendFriendRequest(id, user) else systemMessage("User not found online. Try /people first, then /friend @name.") end
        end
    elseif command == "block" then
        if rest == "" then
            showHelpForCommand("block")
        else
            local id, user = resolveUser(rest)
            if id then blockUser(id, user) systemMessage("Blocked " .. displayName(user.username, id, user.profile) .. ".") else systemMessage("User not found online. Try /people or /block @shortid.") end
        end
    elseif command == "unblock" then
        if rest == "" then
            showHelpForCommand("unblock")
        else
            local id = resolveBlocked(rest)
            if not id then id = resolveUser(rest) end
            if id then unblockUser(id) systemMessage("Unblocked " .. shortId(id) .. ".") else systemMessage("Blocked user not found. Open /blocked to see the list.") end
        end
    elseif command == "mute" then
        if rest == "" then
            showHelpForCommand("mute")
        else
            local id, user = resolveUser(rest)
            if id then muteUser(id, user) else systemMessage("User not found online. Try /people or /mute @shortid.") end
        end
    elseif command == "unmute" then
        if rest == "" then
            showHelpForCommand("unmute")
        else
            local id, user = resolveUser(rest)
            if id then unmuteUser(id) else systemMessage("User not found online. Try /people or /unmute @shortid.") end
        end
    elseif command == "trust" then
        if rest == "" then
            showHelpForCommand("trust")
        else
            local id, user = resolveUser(rest)
            if id then trustUser(id, user) else systemMessage("User not found online. Try /people or /trust @shortid.") end
        end
    elseif command == "untrust" then
        if rest == "" then
            showHelpForCommand("untrust")
        else
            local id = resolveUser(rest)
            if id then untrustUser(id) else systemMessage("User not found online. Try /people or /untrust @shortid.") end
        end
    elseif command == "safety" then
        showSafetyFor(rest)
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
        local maybe = suggestCommand(command)
        if maybe then
            systemMessage("Unknown command /" .. command .. ". Did you mean " .. maybe .. "? Use /help " .. maybe:sub(2) .. " for details.")
        else
            systemMessage("Unknown command /" .. command .. ". Use /help for the command list.")
        end
    end

    state.input = ""
    local shouldOpenSystem = state.slashOpenedSystemOutput and state.useSystemSlashChannel ~= false and state.current == slashOrigin
    state._slashCommandActive = false
    state.slashOpenedSystemOutput = false
    if shouldOpenSystem then
        ensureSystemChannel()
        switchConvo("system")
    end
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

local function modalBox(width, height, modalKey)
    modalKey = modalKey or state.modal or "modal"
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

    if modalKey then
        state.modalPositions = state.modalPositions or {}
        local pos = state.modalPositions[modalKey]
        if type(pos) == "table" then
            mx = math.max(1, math.min(pos.x or mx, w - mw + 1))
            my = math.max(1, math.min(pos.y or my, h - mh + 1))
        else
            state.modalPositions[modalKey] = { x = mx, y = my }
        end
        state.activeModalBox = { key = modalKey, x = mx, y = my, w = mw, h = mh }
    end

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

    modalHeader(mx, my, mw, "People & Friends", "online | friends first | click a user")

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
            local relName = ""
            if rel == "*" then relName = " friend"
            elseif rel == "!" then relName = " wants to add you"
            elseif rel == "?" then relName = " request sent" end
            local label = online .. " " .. name .. relName .. " #" .. shortId(u.publicId)

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

    local mx, my, mw, mh = modalBox(isPocket() and w or 54, isPocket() and 13 or 14)

    modalHeader(mx, my, mw, "User info", nil)
    text(mx + 1, my + 3, trim("Name: " .. name, mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Status: " .. status, mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 5, trim("ID: " .. shortId(id) .. " | Safety: " .. safetyCode(id), mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 6, trim("Trust: " .. (state.trusted[id] and "trusted" or "not trusted") .. " | Mute: " .. (state.muted[id] and "muted" or "off"), mw - 2), colors.gray, colors.lightGray)

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

    local by2 = by + 1
    if by2 <= my + mh - 1 then
        addButton("ui_mute", mx + 1, by2, 9, state.muted[id] and "Unmute" or "Mute", colors.black, colors.lightGray, function()
            if state.muted[id] then unmuteUser(id) else muteUser(id, user) end
        end)
        addButton("ui_trust", mx + 11, by2, 10, state.trusted[id] and "Untrust" or "Trust", colors.black, state.trusted[id] and colors.lightGray or T().warn, function()
            if state.trusted[id] then untrustUser(id) else trustUser(id, user) end
        end)
        addButton("ui_safety", mx + 22, by2, 8, "Safety", colors.black, T().accent, function()
            systemMessage("Safety for " .. name .. ": " .. safetyCode(id))
            state.modal = nil
        end)
    end

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



local function drawCompatDropdownModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 62, isPocket() and 18 or 20, "compat_dropdown")

    modalHeader(mx, my, mw, "Old-client compatibility", "Choose target. All mirror modes are BUGGY.")

    text(mx + 1, my + 3, trim("Current: " .. legacyCompatLabel(), mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Use v15 for your old v15 client. Plain/no-codename is for pre-codename v19.", mw - 2), colors.gray, colors.lightGray)

    local listTop = my + 6
    local listBottom = my + mh - 3
    local visibleRows = math.max(1, listBottom - listTop + 1)
    local maxScroll = math.max(0, #LEGACY_COMPAT_ORDER - visibleRows)

    state.compatScroll = tonumber(state.compatScroll) or 0
    if state.compatScroll < 0 then state.compatScroll = 0 end
    if state.compatScroll > maxScroll then state.compatScroll = maxScroll end

    fill(mx + 1, listTop, mw - 2, visibleRows, colors.lightGray)

    for row = 1, visibleRows do
        local idx = state.compatScroll + row
        local key = LEGACY_COMPAT_ORDER[idx]
        local info = key and LEGACY_COMPAT_MODES[key]
        if info then
            local selected = key == (state.legacyCompatMode or "off")
            local label = (selected and "[x] " or "[ ] ") .. tostring(info.label or key)
            local bgc = selected and T().accent or colors.white
            local col = selected and colors.black or colors.black
            addButton("compat_" .. key, mx + 1, listTop + row - 1, mw - 4, trim(label, mw - 4), col, bgc, function()
                setLegacyCompatMode(key)
                state.modal = "settings"
            end)
        end
    end

    if #LEGACY_COMPAT_ORDER > visibleRows then
        text(mx + 1, my + mh - 2, trim("Scroll: " .. tostring(state.compatScroll + 1) .. "-" .. tostring(math.min(#LEGACY_COMPAT_ORDER, state.compatScroll + visibleRows)) .. "/" .. tostring(#LEGACY_COMPAT_ORDER), mw - 12), colors.gray, colors.lightGray)
        addButton("compat_up", mx + mw - 6, my + mh - 2, 2, "^", colors.white, colors.gray, function()
            state.compatScroll = math.max(0, (state.compatScroll or 0) - 3)
        end)
        addButton("compat_down", mx + mw - 3, my + mh - 2, 2, "v", colors.white, colors.gray, function()
            state.compatScroll = math.min(maxScroll, (state.compatScroll or 0) + 3)
        end)
    end

    addButton("compat_back", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, function()
        state.modal = "settings"
    end)
end

local function drawSettingsModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 66, isPocket() and 22 or 24)

    modalHeader(mx, my, mw, "Settings", "Scroll options  |  drag header  |  Protocol " .. protocolName() .. " #" .. tostring(protocolVersion()))

    text(mx + 1, my + 3, trim("App v" .. appVersion() .. " | Codename: " .. protocolName(), mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Compatibility number: " .. tostring(protocolVersion()), mw - 2), colors.gray, colors.lightGray)

    local function onoff(v) return v and "ON" or "OFF" end
    local options = {}

    local function addOpt(id, label, active, action, tint)
        table.insert(options, {
            id = id,
            label = label,
            active = active,
            action = action,
            tint = tint
        })
    end

    addOpt("set_time", "Show message time: " .. onoff(state.showTimestamps ~= false), state.showTimestamps ~= false, function()
        toggleBoolSetting("showTimestamps", "Show message time")
    end)

    addOpt("set_compact", "Compact messages: " .. onoff(state.compactMessages == true), state.compactMessages == true, function()
        toggleBoolSetting("compactMessages", "Compact messages")
    end, "accent")

    addOpt("set_seen", "Show read receipts: " .. onoff(state.showReadReceipts ~= false), state.showReadReceipts ~= false, function()
        toggleBoolSetting("showReadReceipts", "Show read receipts")
    end)

    addOpt("set_system", "Show system messages: " .. onoff(state.showSystemMessages ~= false), state.showSystemMessages ~= false, function()
        toggleBoolSetting("showSystemMessages", "Show system messages")
    end)

    addOpt("set_slashsystem", "Slash output to local #system: " .. onoff(state.useSystemSlashChannel ~= false), state.useSystemSlashChannel ~= false, function()
        toggleBoolSetting("useSystemSlashChannel", "Slash output to #system")
        ensureSystemChannel()
    end)

    addOpt("set_friendnote", "Friend notifications: " .. onoff(state.friendNotifications ~= false), state.friendNotifications ~= false, function()
        toggleBoolSetting("friendNotifications", "Friend notifications")
    end)

    addOpt("set_pingnote", "Ping notifications: " .. onoff(state.pingNotifications ~= false), state.pingNotifications ~= false, function()
        toggleBoolSetting("pingNotifications", "Ping notifications")
    end)

    addOpt("set_attach", "Attachments: " .. onoff(state.allowAttachments ~= false), state.allowAttachments ~= false, function()
        toggleBoolSetting("allowAttachments", "Attachments")
    end, "accent")

    addOpt("set_attachnote", "Attachment notifications: " .. onoff(state.attachmentNotifications ~= false), state.attachmentNotifications ~= false, function()
        toggleBoolSetting("attachmentNotifications", "Attachment notifications")
    end)

    addOpt("set_autoplay", "Auto-play received audio: " .. onoff(state.autoPlayAudio == true), state.autoPlayAudio == true, function()
        toggleBoolSetting("autoPlayAudio", "Auto-play audio")
    end, state.autoPlayAudio and "warn" or nil)

    addOpt("set_autoclean", "Auto-clean attachments: " .. onoff(state.autoCleanupAttachments ~= false), state.autoCleanupAttachments ~= false, function()
        toggleBoolSetting("autoCleanupAttachments", "Auto-clean attachments")
    end)

    addOpt("set_expire", "Attachment expiry: " .. ((tonumber(state.attachmentExpireDays or 0) or 0) <= 0 and "OFF" or tostring(state.attachmentExpireDays) .. " day(s)"), (tonumber(state.attachmentExpireDays or 0) or 0) > 0, cycleAttachmentExpiry, "accent")

    addOpt("set_storagecap", "Attachment storage cap: " .. ((tonumber(state.attachmentStorageLimitKB or 0) or 0) <= 0 and "OFF" or tostring(state.attachmentStorageLimitKB) .. " KB"), (tonumber(state.attachmentStorageLimitKB or 0) or 0) > 0, cycleAttachmentStorageLimit, "accent")

    addOpt("set_legattach", "Legacy attachment unsupported note: " .. onoff(state.legacyAttachmentNotice ~= false), state.legacyAttachmentNotice ~= false, function()
        toggleBoolSetting("legacyAttachmentNotice", "Legacy attachment notice")
    end)

    addOpt("set_cleanaudio", "Clean expired/audio storage now", false, function()
        cleanupAttachments("expired", true)
    end, "warn")

    addOpt("set_historysync", "Auto history sync: " .. onoff(state.autoHistorySync ~= false), state.autoHistorySync ~= false, function()
        toggleBoolSetting("autoHistorySync", "Auto history sync")
    end)

    addOpt("set_dmprivacy", "DM privacy: " .. dmPrivacyLabel(), state.dmPrivacy == "anyone", cycleDmPrivacy, state.dmPrivacy == "anyone" and nil or "warn")

    addOpt("set_autojoin", "Auto-join public groups: " .. onoff(state.autoJoinPublicGroups ~= false), state.autoJoinPublicGroups ~= false, function()
        toggleBoolSetting("autoJoinPublicGroups", "Auto-join public groups")
    end)

    addOpt("set_historyfriends", "History sync friends-only: " .. onoff(state.requireFriendForHistory == true), state.requireFriendForHistory == true, function()
        toggleBoolSetting("requireFriendForHistory", "History sync friends-only")
    end, state.requireFriendForHistory and "warn" or nil)

    addOpt("set_flood", "Auto-block flood spam: " .. onoff(state.autoBlockFlood == true), state.autoBlockFlood == true, function()
        toggleBoolSetting("autoBlockFlood", "Auto-block flood spam")
    end, state.autoBlockFlood and "warn" or nil)

    addOpt("set_secalerts", "Security alerts: " .. onoff(state.securityAlerts ~= false), state.securityAlerts ~= false, function()
        toggleBoolSetting("securityAlerts", "Security alerts")
    end)

    addOpt("set_quiet", state.quietVersionWarnings and "Quiet version spam: ON" or "Quiet version spam: OFF", state.quietVersionWarnings == true, toggleQuietVersionWarnings)

    addOpt("set_old", "Old-client mode: " .. legacyCompatLabel(), shouldAcceptOldClients(), openCompatDropdown, shouldAcceptOldClients() and "warn" or nil)

    addOpt("set_branch", "Update branch: " .. updateBranchLabel(), false, openUpdateBranchDropdown, "accent")

    addOpt("set_oldtag", "Show [OLD] tags: " .. onoff(state.showOldClientTags ~= false), state.showOldClientTags ~= false, function()
        toggleBoolSetting("showOldClientTags", "Show [OLD] tags")
    end)

    addOpt("set_rwarn", "Hide remote version-warning echoes: " .. onoff(state.suppressRemoteVersionWarnings ~= false), state.suppressRemoteVersionWarnings ~= false, function()
        toggleBoolSetting("suppressRemoteVersionWarnings", "Hide remote version-warning echoes")
    end)

    local listTop = my + 6
    local listBottom = my + mh - 4
    local visibleRows = math.max(1, listBottom - listTop + 1)
    local maxScroll = math.max(0, #options - visibleRows)

    state.settingsScroll = tonumber(state.settingsScroll) or 0
    if state.settingsScroll < 0 then state.settingsScroll = 0 end
    if state.settingsScroll > maxScroll then state.settingsScroll = maxScroll end

    local function optionColor(opt)
        if opt.tint == "warn" then return T().warn end
        if opt.tint == "accent" then return T().accent end
        if opt.active then return T().good end
        return colors.white
    end

    -- Clean list body so dragging/scrolling does not leave stale labels behind.
    fill(mx + 1, listTop, mw - 2, visibleRows, colors.lightGray)

    for row = 1, visibleRows do
        local idx = state.settingsScroll + row
        local opt = options[idx]
        if opt then
            local prefix = "  "
            if idx == 1 and state.settingsScroll > 0 then prefix = "^ " end
            if idx == #options and state.settingsScroll < maxScroll then prefix = "v " end

            addButton(opt.id, mx + 1, listTop + row - 1, mw - 4, trim(prefix .. opt.label, mw - 4), colors.black, optionColor(opt), opt.action)
        end
    end

    if #options > visibleRows then
        local percent = math.floor(((state.settingsScroll + visibleRows) / #options) * 100)
        text(mx + mw - 2, listTop, "|", colors.gray, colors.lightGray)
        text(mx + mw - 2, listBottom, "|", colors.gray, colors.lightGray)
        text(mx + 1, my + mh - 3, trim("Scroll: " .. tostring(state.settingsScroll + 1) .. "-" .. tostring(math.min(#options, state.settingsScroll + visibleRows)) .. "/" .. tostring(#options) .. " (" .. tostring(percent) .. "%)  mouse wheel / PgUp / PgDn", mw - 2), colors.gray, colors.lightGray)

        addButton("settings_up", mx + mw - 3, listTop + 1, 2, "^", colors.white, colors.gray, function()
            state.settingsScroll = math.max(0, (state.settingsScroll or 0) - 3)
        end)
        addButton("settings_down", mx + mw - 3, listBottom - 1, 2, "v", colors.white, colors.gray, function()
            state.settingsScroll = math.min(maxScroll, (state.settingsScroll or 0) + 3)
        end)
    else
        text(mx + 1, my + mh - 3, trim("Tip: /security opens safety, privacy, trust, and backup tools.", mw - 2), colors.gray, colors.lightGray)
    end

    addButton("settings_sec", mx + 1, my + mh - 1, 10, "Security", colors.black, T().warn, openSecurityModal)
    addButton("settings_top", mx + 12, my + mh - 1, 8, "Top", colors.black, colors.lightGray, function()
        state.settingsScroll = 0
    end)
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
    local mx, my, mw, mh = modalBox(isPocket() and w or 44, isPocket() and 14 or 15, "main_menu")

    modalHeader(mx, my, mw, "Menu", trim(currentChatTitle() .. "  |  /help  |  drag header", mw - 2))

    local items = {
        { "Chats", openChatsModal, T().good, colors.black },
        { "People", function() state.modal = "people" end, T().warn, colors.black },
        { "P2P Peers", function() state.modal = nil showPeerStatus() end, T().accent, colors.black },
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
        { "Security Center", openSecurityModal, T().warn, colors.black },
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
    local mx, my, mw, mh = modalBox(isPocket() and w or 62, isPocket() and 15 or 19)

    modalHeader(mx, my, mw, "Slash commands", "/help command for details")

    local lines = {
        "Type commands exactly like Discord: /pm @user, /join #group",
        "ENTER send   TAB next chat   ESC close"
    }

    for _, cat in ipairs(COMMAND_HELP) do
        table.insert(lines, "")
        table.insert(lines, cat.title)
        for _, item in ipairs(cat.items or {}) do
            local args = item.args and (" " .. item.args) or ""
            table.insert(lines, "  " .. item.cmd .. args .. "  -  " .. item.desc)
        end
    end

    table.insert(lines, "")
    table.insert(lines, "People marks: * friend, ! request, ? sent. Chat mark: ^ pinned.")

    local maxRows = mh - 4
    local y = my + 2
    for i = 1, math.min(#lines, maxRows) do
        local line = lines[i]
        local col = colors.black
        if line == "" then
            -- spacing row
        elseif line:find("^  /") then
            col = colors.black
        elseif not line:find("^%s") and not line:find("^/") then
            col = T().top
        end
        text(mx + 1, y, trim(line, mw - 2), col, colors.lightGray)
        y = y + 1
    end

    local total = #lines
    if total > maxRows then
        text(mx + 1, my + mh - 2, trim("Showing " .. tostring(maxRows) .. "/" .. tostring(total) .. ". Use /help <command> for more.", mw - 10), colors.gray, colors.lightGray)
    end

    addButton("help_close", mx + mw - 8, my + mh - 1, 8, "Close", colors.white, colors.gray, function()
        state.modal = nil
    end)
end



function drawUpdateBranchModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 56, isPocket() and 16 or 18, "update_branch")

    modalHeader(mx, my, mw, "Updater branch", "Choose GitHub branch for /update")
    text(mx + 1, my + 3, trim("Current: " .. updateBranchLabel(), mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Repo: " .. tostring(APP.updateOwner or "benchware") .. "/" .. tostring(APP.updateRepo or "Xenit-Chat"), mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 5, trim("Source: " .. (state.updateBranchesStatus == "github" and "GitHub API" or "fallback") .. " | Refresh to scan", mw - 2), colors.gray, colors.lightGray)

    local branches = getUpdateBranches()
    local listTop = my + 7
    local listBottom = my + mh - 3
    local visibleRows = math.max(1, listBottom - listTop + 1)
    local maxScroll = math.max(0, #branches - visibleRows)

    state.branchScroll = tonumber(state.branchScroll) or 0
    if state.branchScroll < 0 then state.branchScroll = 0 end
    if state.branchScroll > maxScroll then state.branchScroll = maxScroll end

    fill(mx + 1, listTop, mw - 2, visibleRows, colors.lightGray)

    for row = 1, visibleRows do
        local idx = state.branchScroll + row
        local item = branches[idx]
        if item then
            local selected = (state.updateBranch or "main") == item.key
            local label = (selected and "[x] " or "[ ] ") .. tostring(item.label or item.key)
            if item.note and item.note ~= "" then label = label .. " - " .. tostring(item.note) end
            local bgc = selected and T().accent or colors.white
            addButton("branch_" .. item.key, mx + 1, listTop + row - 1, mw - 4, trim(label, mw - 4), colors.black, bgc, function()
                if item.key == "custom" then
                    openCustomUpdateBranchModal()
                else
                    setUpdateBranch(item.key)
                    state.modal = "settings"
                    systemMessage("Update branch set to " .. updateBranchLabel() .. ".")
                end
            end)
        end
    end

    if #branches > visibleRows then
        text(mx + 1, my + mh - 2, trim("Scroll: " .. tostring(state.branchScroll + 1) .. "-" .. tostring(math.min(#branches, state.branchScroll + visibleRows)) .. "/" .. tostring(#branches), mw - 12), colors.gray, colors.lightGray)
        addButton("branch_up", mx + mw - 6, my + mh - 2, 2, "^", colors.white, colors.gray, function()
            state.branchScroll = math.max(0, (state.branchScroll or 0) - 3)
        end)
        addButton("branch_down", mx + mw - 3, my + mh - 2, 2, "v", colors.white, colors.gray, function()
            state.branchScroll = math.min(maxScroll, (state.branchScroll or 0) + 3)
        end)
    end

    addButton("branch_info", mx + 1, my + mh - 1, 7, "Info", colors.black, colors.lightGray, showUpdateBranchInfo)
    addButton("branch_refresh", mx + 9, my + mh - 1, 9, "Refresh", colors.black, T().accent, function()
        refreshUpdateBranches(false)
    end)
    addButton("branch_back", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, function()
        state.modal = "settings"
    end)
end

function drawCustomUpdateBranchModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 48, isPocket() and 8 or 9, "update_branch_custom")

    modalHeader(mx, my, mw, "Custom branch", "Type branch name")
    text(mx + 1, my + 3, "Branch:", colors.black, colors.lightGray)
    fill(mx + 9, my + 3, mw - 10, 1, colors.white)
    text(mx + 10, my + 3, trim(state.modalInput, mw - 12), colors.black, colors.white)
    text(mx + 1, my + 5, trim("Example: main, dev, beta, feature/test", mw - 2), colors.gray, colors.lightGray)

    addButton("branch_custom_save", mx + 1, my + mh - 1, 8, "Save", colors.black, T().good, function()
        setUpdateBranch("custom", state.modalInput)
        state.modal = "settings"
        state.modalInput = ""
        systemMessage("Update branch set to " .. updateBranchLabel() .. ".")
    end)

    addButton("branch_custom_back", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, openUpdateBranchDropdown)
end

local function drawUpdateModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 50, isPocket() and 10 or 11)

    modalHeader(mx, my, mw, "Auto Update", nil)
    text(mx + 1, my + 3, trim("Source: GitHub benchware/Xenit-Chat", mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 4, trim("Branch: " .. updateBranchLabel(), mw - 2), colors.black, colors.lightGray)
    text(mx + 1, my + 5, trim("Local version: v" .. appVersion() .. " | " .. protocolName(), mw - 2), colors.gray, colors.lightGray)
    text(mx + 1, my + 6, trim("Manual: /update, /update install, /branch", mw - 2), colors.gray, colors.lightGray)

    local fy = my + mh - 1
    addButton("upd_check", mx + 1, fy, 9, "Check", colors.black, T().accent, function()
        state.modal = nil
        checkForUpdate(false, false, false, nil)
    end)

    addButton("upd_install", mx + 11, fy, 10, "Install", colors.black, T().good, function()
        state.modal = nil
        checkForUpdate(false, true, false, nil)
    end)

    addButton("upd_branch", mx + 22, fy, 10, "Branch", colors.black, colors.lightGray, openUpdateBranchDropdown)

    addButton("upd_close", mx + mw - 8, fy, 8, "Back", colors.white, colors.gray, openMainMenu)
end

local function drawThemeModal()
    local names = { "aegis", "midnight", "slate", "dark", "ocean", "neon", "graphite", "forest", "sunset", "amethyst", "ice", "clean" }
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


local function drawSecurityModal()
    local mx, my, mw, mh = modalBox(isPocket() and w or 64, isPocket() and 18 or 20)
    modalHeader(mx, my, mw, "Security center", "Privacy, trust, flood protection, and backups.")

    local function onoff(v) return v and "ON" or "OFF" end
    local y = my + 3

    addButton("sec_dm", mx + 1, y, mw - 2, "DM privacy: " .. dmPrivacyLabel(), colors.black, state.dmPrivacy == "anyone" and colors.white or T().warn, cycleDmPrivacy)
    y = y + 1
    addButton("sec_history", mx + 1, y, mw - 2, "History sync friends-only: " .. onoff(state.requireFriendForHistory == true), colors.black, state.requireFriendForHistory and T().warn or colors.white, function()
        toggleBoolSetting("requireFriendForHistory", "History sync friends-only")
    end)
    y = y + 1
    addButton("sec_autojoin", mx + 1, y, mw - 2, "Auto-join public groups: " .. onoff(state.autoJoinPublicGroups ~= false), colors.black, state.autoJoinPublicGroups ~= false and T().good or colors.white, function()
        toggleBoolSetting("autoJoinPublicGroups", "Auto-join public groups")
    end)
    y = y + 1
    addButton("sec_flood", mx + 1, y, mw - 2, "Auto-block flood spam: " .. onoff(state.autoBlockFlood == true), colors.black, state.autoBlockFlood and T().warn or colors.white, function()
        toggleBoolSetting("autoBlockFlood", "Auto-block flood spam")
    end)
    y = y + 1
    addButton("sec_alerts", mx + 1, y, mw - 2, "Security alerts: " .. onoff(state.securityAlerts ~= false), colors.black, state.securityAlerts ~= false and T().good or colors.white, function()
        toggleBoolSetting("securityAlerts", "Security alerts")
    end)
    y = y + 1

    addButton("sec_audit", mx + 1, y, math.floor((mw - 3) / 2), "Run Audit", colors.black, T().accent, showSecurityAudit)
    addButton("sec_backup", mx + 2 + math.floor((mw - 3) / 2), y, mw - 3 - math.floor((mw - 3) / 2), "Backup", colors.black, T().good, backupLocalData)
    y = y + 2

    text(mx + 1, y, "Recent security notes:", colors.black, colors.lightGray)
    y = y + 1
    if not state.securityEvents or #state.securityEvents == 0 then
        text(mx + 1, y, "No security notes yet.", colors.gray, colors.lightGray)
    else
        local maxRows = math.max(1, mh - (y - my) - 2)
        for i = 1, math.min(#state.securityEvents, maxRows) do
            text(mx + 1, y + i - 1, trim("- " .. tostring(state.securityEvents[i].body or ""), mw - 2), colors.gray, colors.lightGray)
        end
    end

    addButton("sec_back", mx + mw - 8, my + mh - 1, 8, "Back", colors.white, colors.gray, openMainMenu)
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
    elseif state.modal == "compat_dropdown" then
        drawCompatDropdownModal()
    elseif state.modal == "update_branch" then
        drawUpdateBranchModal()
    elseif state.modal == "update_branch_custom" then
        drawCustomUpdateBranchModal()
    elseif state.modal == "security" then
        drawSecurityModal()
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
    elseif state.modal == "update_branch_custom" then
        setUpdateBranch("custom", state.modalInput)
        state.modal = "settings"
        state.modalInput = ""
        systemMessage("Update branch set to " .. updateBranchLabel() .. ".")

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
        local left = APP.name .. " v" .. appVersion() .. "  " .. title
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
    read = true,
    ping = true,
    pong = true,
    attachment_start = true,
    attachment_chunk = true,
    attachment_end = true
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
        addMessage(state.current or "global", "system", who .. " is on newer XenitChat v" .. tostring(msg.appVersion or msg.version) .. " (" .. tostring(msg.protocolName or "unknown") .. "). Run /update install if messages do not work.", "warn", { silent = true })
    elseif tonumber(msg.version) < protocolVersion() then
        addMessage(state.current or "global", "system", "Ignored an old-format " .. tostring(msg.kind or "packet") .. " from " .. who .. " (v" .. tostring(msg.appVersion or msg.version) .. ", " .. tostring(msg.protocolName or "unknown") .. "). Enable Settings > Talk to older clients (BUGGY) to accept it.", "warn", { silent = true })
    end
end


function isRemoteVersionWarningBody(body)
    local s = tostring(body or ""):lower()
    return s:find("your version is outdated", 1, true) ~= nil
        or s:find("message from old xenitchat version ignored", 1, true) ~= nil
        or s:find("is on newer xenitchat", 1, true) ~= nil
        or s:find("ignored an old%-format") ~= nil
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
    if packetByteSize(msg) > APP.maxPacketBytes then
        recordSecurityEvent("Dropped oversized network packet.")
        return
    end
    if tonumber(msg.version) == nil then return end
    if not msg.user or not msg.publicId then return end
    if msg.publicId == state.publicId then return end

    if msg.compatMirror and tonumber(msg.sourceProtocolVersion or 0) >= protocolVersion() then
        return
    end

    if rememberPacket(msg) then return end

    if not sameProtocolVersion(msg.version) then
        local remoteVersion = tonumber(msg.version)

        if remoteVersion and remoteVersion < protocolVersion() and shouldAcceptOldClients() then
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
    if rateLimited(msg.publicId, msg.kind) then return end
    if isMuted(msg.publicId) and (msg.kind == "chat" or msg.kind == "pm" or msg.kind == "ping") then return end

    recordIdentity(msg.publicId, msg)

    local remoteVersionNumber = tonumber(msg.version)
    local remoteOldClient = false
    if remoteVersionNumber and remoteVersionNumber < protocolVersion() then remoteOldClient = true end
    if msg.compatMirror == true then remoteOldClient = true end
    if remoteVersionNumber and remoteVersionNumber <= protocolVersion() and not msg.protocolName and not msg.appVersion then remoteOldClient = true end

    state.users[msg.publicId] = {
        username = msg.user,
        publicId = msg.publicId,
        nodeId = msg.nodeId,
        senderId = senderId,
        profile = msg.profile or {},
        remoteVersion = remoteVersionNumber,
        remoteAppVersion = msg.appVersion or tostring(msg.version),
        remoteProtocolName = msg.protocolName,
        legacyMirror = msg.compatMirror == true,
        oldClient = remoteOldClient,
        lastSeenClock = os.clock()
    }

    if msg.kind == "hello" then
        safeSendTo(senderId, "hello_ack", {
            current = state.current
        })
        if state.autoHistorySync ~= false then requestHistorySync(senderId, msg.publicId) end

    elseif msg.kind == "hello_ack" then
        if state.autoHistorySync ~= false then requestHistorySync(senderId, msg.publicId) end
        return

    elseif msg.kind == "ping" then
        if shouldAnswerPing(msg) then
            if state.pingNotifications ~= false and msg.scope == "here" then
                local c = state.convos[msg.key or ""] or { title = msg.title or msg.key or "here" }
                systemMessage(displayName(msg.user, msg.publicId, msg.profile) .. " pinged @here in " .. chatLabel(c, true) .. ".")
            elseif state.pingNotifications ~= false and msg.scope == "everyone" then
                systemMessage(displayName(msg.user, msg.publicId, msg.profile) .. " pinged @everyone.")
            end
            safeSendTo(senderId, "pong", { pingId = msg.pingId, toPublicId = msg.publicId, scope = msg.scope, key = msg.key })
        end

    elseif msg.kind == "pong" then
        receivePong(msg)

    elseif msg.kind == "history_request" then
        if shouldShareHistoryWith(msg.publicId) then
            safeSendTo(senderId, "history_reply", {
                bundles = makeHistoryBundle(msg.keys or {}, msg.publicId)
            })
        elseif state.securityAlerts ~= false then
            recordSecurityEvent("Blocked history sync request from non-friend #" .. shortId(msg.publicId) .. ".")
        end

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

        safeSendTo(senderId, "discover_reply", {
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
        if state.suppressRemoteVersionWarnings ~= false and isRemoteVersionWarningBody(msg.body) then
            return
        end
        if msg.key and msg.body and not state.leftGroups[msg.key] then
            local known = state.convos[msg.key] ~= nil
            local allowAuto = msg.key == "global" or (state.autoJoinPublicGroups ~= false and msg.listed ~= false and msg.private ~= true)

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
            if not shouldAcceptDm(msg.publicId) then
                if state.securityAlerts ~= false then
                    recordSecurityEvent("Blocked DM from " .. displayName(msg.user, msg.publicId, msg.profile) .. " due to privacy setting.")
                end
                return
            end
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
                if state.friendNotifications ~= false then systemMessage("Friend request from " .. displayName(msg.user, msg.publicId, msg.profile) .. ". Open People > Inbox.") end
            else
                addFriendDirect(msg.publicId, state.users[msg.publicId])
                broadcast("friend_accept", {
                    toPublicId = msg.publicId
                })
                if state.friendNotifications ~= false then systemMessage("You and " .. displayName(msg.user, msg.publicId, msg.profile) .. " are now friends.") end
            end
        end

    elseif msg.kind == "friend_accept" then
        if msg.toPublicId == state.publicId then
            addFriendDirect(msg.publicId, state.users[msg.publicId])
            if state.friendNotifications ~= false then systemMessage(displayName(msg.user, msg.publicId, msg.profile) .. " accepted your friend request.") end
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

    elseif msg.kind == "attachment_start" then
        receiveAttachmentStart(msg)

    elseif msg.kind == "attachment_chunk" then
        receiveAttachmentChunk(msg)

    elseif msg.kind == "attachment_end" then
        receiveAttachmentEnd(msg)

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

        checkPingTimeouts()

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
        if state.modal == "create" or state.modal == "pm" or state.modal == "friend_search" or state.modal == "profile" or state.modal == "group_rename" or state.modal == "update_branch_custom" then
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

    if state.modal == "settings" then
        if key == keys.up then
            state.settingsScroll = math.max(0, (state.settingsScroll or 0) - 1)
        elseif key == keys.down then
            state.settingsScroll = (state.settingsScroll or 0) + 1
        elseif key == keys.pageUp then
            state.settingsScroll = math.max(0, (state.settingsScroll or 0) - 5)
        elseif key == keys.pageDown then
            state.settingsScroll = (state.settingsScroll or 0) + 5
        elseif key == keys.home then
            state.settingsScroll = 0
        end
        return
    end

    if state.modal == "update_branch" then
        if key == keys.up then
            state.branchScroll = math.max(0, (state.branchScroll or 0) - 1)
        elseif key == keys.down then
            state.branchScroll = (state.branchScroll or 0) + 1
        elseif key == keys.pageUp then
            state.branchScroll = math.max(0, (state.branchScroll or 0) - 5)
        elseif key == keys.pageDown then
            state.branchScroll = (state.branchScroll or 0) + 5
        elseif key == keys.home then
            state.branchScroll = 0
        end
        return
    end

    if state.modal == "compat_dropdown" then
        if key == keys.up then
            state.compatScroll = math.max(0, (state.compatScroll or 0) - 1)
        elseif key == keys.down then
            state.compatScroll = (state.compatScroll or 0) + 1
        elseif key == keys.pageUp then
            state.compatScroll = math.max(0, (state.compatScroll or 0) - 5)
        elseif key == keys.pageDown then
            state.compatScroll = (state.compatScroll or 0) + 5
        elseif key == keys.home then
            state.compatScroll = 0
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


function beginModalDrag(x, y)
    if not state.modal then return false end
    local b = state.activeModalBox
    if not b or not b.key then return false end

    -- Every modal/menu can be dragged by its header/title bar.
    -- Leave the right edge alone so the X close button remains easy to click.
    local closeZoneStart = b.x + b.w - 3
    if y == b.y and x >= b.x and x <= b.x + b.w - 1 and x < closeZoneStart then
        state.draggingModal = { key = b.key, dx = x - b.x, dy = y - b.y }
        return true
    end

    return false
end

function handleMouseDrag(x, y)
    local d = state.draggingModal
    if not d then return false end
    local b = state.activeModalBox
    if not b then return false end

    local nx = math.max(1, math.min(x - (d.dx or 0), w - b.w + 1))
    local ny = math.max(1, math.min(y - (d.dy or 0), h - b.h + 1))

    state.modalPositions = state.modalPositions or {}
    local old = state.modalPositions[d.key] or {}
    if old.x == nx and old.y == ny then return false end

    state.modalPositions[d.key] = { x = nx, y = ny }
    return true
end

local function handleMouse(x, y)
    if clickButton(x, y) then return end
    if beginModalDrag(x, y) then return end

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
    local dirty = true

    while state.running do
        if dirty then
            draw()
            dirty = false
        end

        local event, p1, p2, p3 = os.pullEvent()
        local redraw = true

        if event == "char" then
            typeIntoField(p1)

        elseif event == "key" then
            handleKey(p1)

        elseif event == "mouse_click" then
            handleMouse(p2, p3)

        elseif event == "mouse_drag" then
            local moved = handleMouseDrag(p2, p3)
            local now = os.clock()
            if moved and now - (state.lastDragDrawClock or 0) >= 0.045 then
                state.lastDragDrawClock = now
                redraw = true
            else
                redraw = false
            end

        elseif event == "mouse_up" then
            state.draggingModal = nil
            redraw = true

        elseif event == "mouse_scroll" then
            if state.modal == "settings" then
                if p1 < 0 then
                    state.settingsScroll = math.max(0, (state.settingsScroll or 0) - 3)
                else
                    state.settingsScroll = (state.settingsScroll or 0) + 3
                end
            elseif state.modal == "compat_dropdown" then
                if p1 < 0 then
                    state.compatScroll = math.max(0, (state.compatScroll or 0) - 3)
                else
                    state.compatScroll = (state.compatScroll or 0) + 3
                end
            elseif state.modal == "update_branch" then
                if p1 < 0 then
                    state.branchScroll = math.max(0, (state.branchScroll or 0) - 3)
                else
                    state.branchScroll = (state.branchScroll or 0) + 3
                end
            elseif state.screen == "chat" and not state.modal then
                if p1 < 0 then
                    scrollBy(3)
                else
                    scrollBy(-3)
                end
            end

        elseif event == "term_resize" then
            w, h = term.getSize()
            clampScroll()

        else
            -- Unknown events can still come from timers/modems in CraftOS-PC.
            -- Redraw so network/status changes become visible without keyboard input.
            redraw = true
        end

        dirty = redraw
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
    APP.updateUrl = updateUrlForBranch(selectedUpdateBranch())
    loadHistory()
    if state.autoCleanupAttachments ~= false then cleanupAttachments("expired", false) end
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
