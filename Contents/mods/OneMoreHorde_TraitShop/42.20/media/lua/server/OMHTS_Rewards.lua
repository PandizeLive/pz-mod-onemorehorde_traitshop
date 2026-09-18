if isClient() then return end

local State = require("OMHTS_State")
local Config = require("OMHTS_RewardsConfig")
local Rewards = {}
local deadZombies = {}
local deathRing = {}
local deathSequence = 0

---@param store table
---@return boolean
function Rewards.initialize(store)
    deadZombies = {}
    deathRing = {}
    deathSequence = 0
    if store.rewards == nil then
        store.rewards = { schema = 1, cooldowns = {}, deaths = {} }
    end
    local data = store.rewards
    if type(data) ~= "table" or data.schema ~= 1 or type(data.cooldowns) ~= "table"
        or type(data.deaths) ~= "table" then return false end
    for killer, victims in pairs(data.cooldowns) do
        if type(killer) ~= "string" or type(victims) ~= "table" then return false end
        for victim, expiry in pairs(victims) do
            if type(victim) ~= "string" or not State.isXP(expiry) then return false end
        end
    end
    for victim, life in pairs(data.deaths) do
        if type(victim) ~= "string" or not State.isCounter(life) then return false end
    end
    return true
end

---@nodiscard
---@param player IsoPlayer
---@return string|nil
function Rewards.identity(player)
    local name = player:getUsername()
    if type(name) ~= "string" or #name == 0 or #name > 128 then return nil end
    return name
end

---@param zombie IsoZombie
---@return nil
function Rewards.created(zombie)
    deadZombies[zombie] = nil
end

---@param zombie IsoZombie
---@return boolean
function Rewards.consumeZombie(zombie)
    if not zombie or not instanceof(zombie, "IsoZombie") or not zombie:isDead()
        or zombie:isOnKillDone() or deadZombies[zombie] then return false end
    deathSequence = deathSequence + 1
    local slot = (deathSequence - 1) % 4096 + 1
    local retired = deathRing[slot]
    if retired and deadZombies[retired] == deathSequence - 4096 then
        deadZombies[retired] = nil
    end
    deathRing[slot] = zombie
    deadZombies[zombie] = deathSequence
    return true
end

---@param record table
---@param amount number
---@param source string
---@return boolean
local function award(record, amount, source)
    local oldLevel = record.life.level
    if amount <= 0 or not State.awardXP(record, record.life.id, record.revision, amount) then return false end
    if source ~= "zombie" or record.life.level ~= oldLevel then
        print("[OMH Trait Shop] XP awarded; life=" .. record.life.id .. "; source=" .. source
            .. "; amount=" .. amount .. "; level=" .. record.life.level .. "; xp=" .. record.life.xp)
    end
    return true
end

---@param zombie IsoZombie
---@param record table
---@return boolean
function Rewards.zombie(zombie, record)
    local config = Config.read()
    if config.horde and zombie:getModData().OMHEventId ~= nil then return false end
    return award(record, Config.amount(config, "ZombieXP"), "zombie")
end

---@param store table
---@param victim IsoPlayer
---@param lifeId number
---@return boolean
function Rewards.consumePlayer(store, victim, lifeId)
    local id = Rewards.identity(victim)
    if not id or not State.isCounter(lifeId) or store.rewards.deaths[id] == lifeId then return false end
    store.rewards.deaths[id] = lifeId
    return true
end

---@param store table
---@param killer IsoPlayer
---@param victim IsoPlayer
---@param record table
---@return boolean
function Rewards.player(store, killer, victim, record)
    if not isServer() then return false end
    local config = Config.read()
    local amount = Config.amount(config, "PlayerKillXP")
    if amount <= 0 or killer == victim or Faction.isInSameFaction(killer, victim) then return false end
    local killerId = Rewards.identity(killer)
    local victimId = Rewards.identity(victim)
    if not killerId or not victimId or killerId == victimId then return false end
    local now = getGameTime():getWorldAgeHours()
    if not State.isXP(now) then return false end
    local cooldowns = store.rewards.cooldowns[killerId]
    if cooldowns and cooldowns[victimId] and now < cooldowns[victimId] then return false end
    local expiry = now + config.PlayerKillCooldownDays * 24
    if not State.isXP(expiry) then return false end
    if not award(record, amount, "player") then return false end
    if not cooldowns then
        cooldowns = {}
        store.rewards.cooldowns[killerId] = cooldowns
    end
    cooldowns[victimId] = expiry
    return true
end

---@nodiscard
---@param now number
---@param timeOfDay number
---@param config table
---@return table
function Rewards.session(now, timeOfDay, config)
    local date = getGameTime()
    local session = { last = now, cursor = now, time = timeOfDay, mode = config.mode,
        cycle = config.cycle, eligible = false,
        day = Config.amount(config, "DayXP"), night = Config.amount(config, "NightXP"),
        year = date:getYear(), month = date:getMonth(), date = date:getDayPlusOne(),
        season = getClimateManager():getSeason():clone() }
    session.season:setDay(session.date, session.month, session.year)
    session.eligible = timeOfDay == session.season:getDawn() or timeOfDay == session.season:getDusk()
    return session
end

---@param session table
---@return nil
local function advanceDate(session)
    session.time = 0
    session.date = session.date + 1
    if session.date > getGameTime():daysInMonth(session.year, session.month) then
        session.date = 1
        session.month = session.month + 1
        if session.month == 12 then
            session.month = 0
            session.year = session.year + 1
        end
    end
    session.season:setDay(session.date, session.month, session.year)
end

---@param record table
---@param session table
---@param now number
---@param timeOfDay number
---@param config table
---@return table
---@return boolean
function Rewards.survival(record, session, now, timeOfDay, config)
    if not State.isXP(now) then return session, false end
    if now < session.last or config.mode ~= session.mode or config.cycle ~= session.cycle
        or Config.amount(config, "DayXP") ~= session.day or Config.amount(config, "NightXP") ~= session.night then
        return Rewards.session(now, timeOfDay, config), false
    end
    session.last = now
    if session.day == 0 and session.night == 0 then
        session.cursor = now
        return session, false
    end
    local amount = 0
    for index = 1, 12 do
        if session.cursor >= now then break end
        local dawn = session.season:getDawn()
        local dusk = session.season:getDusk()
        if not (dawn >= 0 and dawn < dusk and dusk < 24) then
            return Rewards.session(now, timeOfDay, config), false
        end
        local boundary = 24
        local reward = 0
        if session.time < dawn then
            boundary = dawn
            reward = session.night
        elseif session.time < dusk then
            boundary = dusk
            reward = session.day
        end
        local target = session.cursor + boundary - session.time
        if target > now then
            session.time = session.time + now - session.cursor
            session.cursor = now
            break
        end
        session.cursor = target
        session.time = boundary
        if boundary == 24 then
            advanceDate(session)
        else
            if session.eligible then
                amount = amount + reward
            end
            session.eligible = true
        end
    end
    return session, award(record, amount, "survival")
end

return Rewards
