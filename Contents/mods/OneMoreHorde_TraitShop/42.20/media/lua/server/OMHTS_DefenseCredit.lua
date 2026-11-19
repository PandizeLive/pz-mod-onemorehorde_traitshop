if isClient() then return end

local Pools = require("OMHTS_DefenseRewards")
local Config = require("OMHTS_RewardsConfig")
local State = require("OMHTS_State")
local Evidence = require("OMHTS_InjuryEvidence")
local Rewards = require("OMHTS_Rewards")
local Credit = {API_VERSION = 1}
local context
local pending = {}
local requests = setmetatable({}, {__mode = "k"})
local zombies = setmetatable({}, {__mode = "k"})
local recovery = setmetatable({}, {__mode = "k"})
local sequence = 0
local accountsByName = {}
local namesByAccount = {}
local currentFactions = {}
OMHTS_DefenseCredit = Credit

---@param value table Authority-owned callbacks and saved store
---@return nil
function Credit.initialize(value)
    context = value
    pending = {}
    requests = setmetatable({}, {__mode = "k"})
    zombies = setmetatable({}, {__mode = "k"})
    recovery = setmetatable({}, {__mode = "k"})
    accountsByName = {}
    namesByAccount = {}
    if context then
        for key, member in pairs(context.store.defense.members) do
            Credit.attached(key, member.username)
        end
    end
end

---@param key string Authoritative account key
---@param username string Native account name
---@return nil
function Credit.attached(key, username)
    local previous = namesByAccount[key]
    if previous and previous ~= username then
        accountsByName[previous][key] = nil
    end
    local keys = accountsByName[username]
    if not keys then
        keys = {}
        accountsByName[username] = keys
    end
    keys[key] = true
    namesByAccount[key] = username
end

---@param username string Account username
---@return string|nil faction Current native faction
local function factionOf(username)
    return currentFactions[username]
end

---@param player IsoPlayer Victim
---@return string fingerprint Native retained attacker identity
local function attackerIdentity(player)
    local attacker = player:getAttackedBy()
    if not attacker then return "none" end
    if instanceof(attacker, "IsoPlayer") then
        return "player:" .. attacker:getUsername() .. ":" .. attacker:getDescriptor():getID()
    end
    return "other"
end

---@param player IsoPlayer Victim
---@return string|nil key
---@return table|nil binding
local function victimBinding(player)
    if not context or not player or not instanceof(player, "IsoPlayer") then return nil end
    local binding = context.bindings[player]
    if not binding or binding.lifeId ~= binding.record.life.id then return nil end
    return context.key(player), binding
end

---@param victim IsoPlayer Server-selected victim
---@param token string Server-issued receipt identity
---@return nil
function Credit.beginInjury(victim, token)
    pending[victim] = nil
    local key, binding = victimBinding(victim)
    if not key then return end
    local current = requests[victim]
    if not current then
        current = {generation = 0, confirmed = 0, jobs = {}}
        requests[victim] = current
    end
    current.generation = current.generation + 1
    current.jobs[token] = {generation = current.generation, life = binding.lifeId,
        deadline = getTimestampMs() + 5000, attacker = attackerIdentity(victim)}
end

---@param victim IsoPlayer Authenticated injury recipient
---@param token string Exact server-issued receipt
---@param owner string|nil Server-held owner
---@param injured boolean Validated application outcome
---@return nil
function Credit.finishInjury(victim, token, owner, injured, source)
    local current = requests[victim]
    local job = current and current.jobs[token]
    if not job then return end
    current.jobs[token] = nil
    local key, binding = victimBinding(victim)
    if not key or not injured or type(owner) ~= "string" or job.life ~= binding.lifeId
        or job.generation < current.confirmed or getTimestampMs() > job.deadline then return end
    local attacker = attackerIdentity(victim)
    if attacker ~= "none" and attacker ~= job.attacker then return end
    current.confirmed = job.generation
    victim:setAttackedBy(nil)
    local encounter = Pools.encounter(context.store, key, binding.lifeId)
    encounter.owner, encounter.attacker = owner, "none"
    encounter.source = source
    recovery[victim] = nil
end

---@param victim IsoPlayer Death settlement candidate
---@return boolean waiting Bounded network receipt grace, not an assist expiry
function Credit.waiting(victim)
    local current = requests[victim]
    if not current then return false end
    local now = getTimestampMs()
    for token, job in pairs(current.jobs) do
        if now <= job.deadline then return true end
        current.jobs[token] = nil
    end
    return false
end

---@param victim IsoPlayer Injured victim
---@param owner string Registered device owner
---@return nil
function Credit.playerInjury(victim, owner, source)
    local key, binding = victimBinding(victim)
    if not key or type(owner) ~= "string" or owner == "" then return end
    victim:setAttackedBy(nil)
    local encounter = Pools.encounter(context.store, key, binding.lifeId)
    encounter.owner = owner
    encounter.source = source
    encounter.attacker = attackerIdentity(victim)
    recovery[victim] = nil
end

---@param victim IsoZombie Confirmed lethal victim, called before Kill
---@param owner string|nil Registered defense owner
---@param horde boolean|nil Authoritative active Horde source
---@return nil
function Credit.zombieFinisher(victim, owner, horde, source)
    if not context then return end
    zombies[victim] = {owner = owner, horde = horde, source = source}
end

---@param victim IsoPlayer Candidate
---@return nil
function Credit.flush(victim)
    local job = pending[victim]
    if not job then return end
    pending[victim] = nil
    local key, binding = victimBinding(victim)
    if not key or binding.lifeId ~= job.life
        or not Evidence.injured(job.before, Evidence.capture(victim)) then return end
    local encounter = Pools.encounter(context.store, key, binding.lifeId)
    encounter.owner, encounter.attacker = nil, nil
    recovery[victim] = nil
    local request = requests[victim]
    if request then
        request.generation = request.generation + 1
        request.confirmed = request.generation
    end
    local attacker = job.attacker
    local contributor = context.bindings[attacker]
    if not contributor or attacker == victim or attacker:isDead()
        or contributor.record.life.status ~= "alive" then return end
    local contributorKey = context.key(attacker)
    encounter.assists[contributorKey] = contributor.lifeId
end

---@param attacker IsoGameCharacter Native attacker
---@param victim IsoGameCharacter Native victim
---@param weapon HandWeapon Native weapon
---@param damage number Nominal value deliberately unused
---@return nil
function Credit.beforeHit(attacker, victim, weapon, damage)
    local key, binding = victimBinding(victim)
    if not key or victim:isDead() then return end
    pending[victim] = {attacker = attacker, life = binding.lifeId, before = Evidence.capture(victim)}
end

---@param attacker IsoGameCharacter Native confirmed attacker
---@param weapon HandWeapon Native weapon
---@param victim IsoGameCharacter Native post-hit recipient
---@return nil
function Credit.afterHit(attacker, weapon, victim)
    local job = pending[victim]
    if not job or job.attacker ~= attacker then return end
    Credit.flush(victim)
end

---@param victim IsoPlayer Independent injury boundary
---@return nil
function Credit.cancelPending(victim)
    pending[victim] = nil
end

---@return nil
function Credit.tick()
    for victim in pairs(pending) do
        -- A later simulation tick could contain unrelated bleeding or healing.
        -- Only the native synchronous post-hit event confirms personal assists.
        pending[victim] = nil
    end
    local now = getTimestampMs()
    for victim, current in pairs(requests) do
        for token, job in pairs(current.jobs) do
            if now > job.deadline then
                current.jobs[token] = nil
            end
        end
    end
end

---@param player IsoPlayer Current bound character
---@return nil
function Credit.recovery(player)
    local key = victimBinding(player)
    if not key or not context.store.defense.encounters[key] then return end
    if player:isDead() or Credit.waiting(player) then return end
    if isServer() then
        local job = recovery[player]
        if job and getTimestampMs() - job.at < 1000 then return end
        sequence = sequence + 1
        local token = tostring(getTimestampMs()) .. ":" .. sequence
        local encounter = context.store.defense.encounters[key]
        recovery[player] = {token = token, at = getTimestampMs(), encounter = encounter}
        sendServerCommand(player, "OMHTS_DefenseRecovery", "Check", {id = player:getOnlineID(), token = token})
    elseif Evidence.recovered(player) then
        Pools.clear(context.store, key)
    end
end

---@param module string Namespace
---@param command string Reply
---@param player IsoPlayer Authenticated owner of the body state
---@param message table No source identity or reward amounts accepted
---@return nil
function Credit.recoveryReply(module, command, player, message)
    if not isServer() or module ~= "OMHTS_DefenseRecovery" or command ~= "Checked"
        or type(message) ~= "table" or type(message.recovered) ~= "boolean" then return end
    local job = recovery[player]
    local key = victimBinding(player)
    if not job or not key or message.token ~= job.token or player:isDead()
        or getTimestampMs() - job.at > 5000 then return end
    recovery[player] = nil
    if message.recovered and context.store.defense.encounters[key] == job.encounter
        and not Credit.waiting(player) then
        Pools.clear(context.store, key)
    end
end

---@param key string Candidate account
---@param meta table Known existing character
---@param online table Account to connected player map
---@param victim string|nil Victim username
---@param victimFaction string|nil Victim faction
---@param now number Earning time
---@param includeOffline boolean Selected setting
---@return table|nil member Eligible snapshot
local function eligible(key, meta, online, victim, victimFaction, now, includeOffline, device)
    local store = context.store
    local record = store.accounts[key]
    if not State.isRecord(record) or record.life.status ~= "alive" or record.life.id ~= meta.life then
        Rewards.audit("defense-ineligible-life", {recipient = meta.username, device = device})
        return nil
    end
    local player = online[key]
    if not player and not includeOffline then
        Rewards.audit("defense-offline-excluded", {recipient = meta.username, device = device})
        return nil
    end
    if victim and (meta.username == victim or (victimFaction and factionOf(meta.username) == victimFaction)) then
        Rewards.audit("defense-friendly-recipient", {recipient = meta.username, device = device})
        return nil
    end
    local cooldowns = store.rewards.cooldowns[meta.username]
    if victim and cooldowns and cooldowns[victim] and now < cooldowns[victim] then
        Rewards.audit("defense-cooldown", {recipient = meta.username, device = device})
        return nil
    end
    local allowed, official = true, false
    if Config.hasHordeNight() then
        local runtime = rawget(_G, "OneMoreHordeDifficultyRuntime")
        if not runtime then return nil end
        if player then
            allowed = runtime.isTraitShopEnabled(player)
            official = allowed and runtime.isTraitShopEarningOfficial(player)
        elseif runtime.traitShopIdentityStatus then
            allowed, official = runtime.traitShopIdentityStatus(meta.identity)
        else
            return nil
        end
    end
    if not allowed or (player and player:isDead()) then
        Rewards.audit("defense-earning-ineligible", {recipient = meta.username, device = device})
        return nil
    end
    return {key = key, life = meta.life, username = meta.username, online = player ~= nil, unofficial = not official}
end

---@param owner string|nil Registered defense owner
---@param victim IsoPlayer|nil PvP victim
---@param encounter table|nil Participant set
---@param horde boolean Horde source already validated by the defense adapter
---@return nil
local function settle(owner, victim, encounter, horde, device)
    Rewards.audit("defense-death", {owner = owner, device = device})
    if type(owner) ~= "string" or owner == "" then
        Rewards.audit("defense-no-owner", {device = device})
        return
    end
    local settings = SandboxVars.OMHTurretsTraps or {}
    local prefix = ""
    if not getActivatedMods():contains("OneMoreHorde_Turrets")
        and getActivatedMods():contains("OneMoreHorde_Traps") then
        prefix = "Traps"
    end
    if settings[prefix .. "DefenseXPEnabled"] == false then
        Rewards.audit("defense-disabled", {owner = owner, device = device})
        return
    end
    local rate = settings[prefix .. "DefenseXPPercent"]
    if type(rate) ~= "number" then
        rate = 50
    end
    rate = math.max(0, math.min(100, rate)) / 100
    local config = Config.read()
    local source = "ZombieXP"
    if victim then
        if not isServer() then return end
        source = "PlayerKillXP"
    elseif horde then
        source = "HordeZombieXP"
    end
    local reward = Config.amount(config, source)
    if reward <= 0 then
        Rewards.audit("defense-zero-reward", {owner = owner, source = source, device = device})
        return
    end
    currentFactions = {}
    local rosters = {}
    if isServer() then
        local native = Faction.getFactions()
        for i = 0, native:size() - 1 do
            local group = native:get(i)
            local name, leader, players = group:getName(), group:getOwner(), group:getPlayers()
            local roster = {leader}
            rosters[name], currentFactions[leader] = roster, name
            for j = 0, players:size() - 1 do
                local username = players:get(j)
                currentFactions[username] = name
                roster[#roster + 1] = username
            end
        end
    end
    local online = {}
    for player, binding in pairs(context.bindings) do
        if context.refresh and not player:isDead() then
            binding = context.refresh(player)
        end
        if binding and binding.lifeId == binding.record.life.id and not player:isDead() then
            online[context.key(player)] = player
        end
    end
    local victimName, victimFaction
    if victim then
        victimName = victim:getUsername()
        victimFaction = factionOf(victimName)
        if owner == victimName or (victimFaction and factionOf(owner) == victimFaction) then return end
    end
    local ownerFaction = factionOf(owner)
    local faction, assists, seen = {}, {}, {}
    local now = getGameTime():getWorldAgeHours()
    local roster = rosters[ownerFaction]
    if not roster then
        roster = {owner}
    end
    local candidates = {}
    for i = 1, #roster do
        local keys = accountsByName[roster[i]]
        if keys then
            for key in pairs(keys) do
                candidates[key] = true
            end
        end
    end
    if encounter then
        for key in pairs(encounter.assists) do
            candidates[key] = true
        end
    end
    for key in pairs(candidates) do
        local meta = context.store.defense.members[key]
        if meta and not seen[meta.username] then
            local member = eligible(key, meta, online, victimName, victimFaction, now, settings[prefix .. "DefenseXPIncludeOffline"] ~= false, device)
            local participant = type(horde) == "table" and horde.participants and horde.participants[meta.identity]
            if participant and (participant.casualty or participant.membershipStatus == "left"
                or participant.role == "vigilante" or participant.eligibilityStatus ~= "eligible") then
                member = nil
                Rewards.audit("defense-horde-ineligible", {recipient = meta.username, device = device})
            end
            if member then
                seen[meta.username] = true
                if meta.username == owner or (ownerFaction and factionOf(meta.username) == ownerFaction) then
                    faction[#faction + 1] = member
                end
                if encounter and encounter.assists[key] == meta.life then
                    assists[#assists + 1] = member
                end
            end
        end
    end
    local payouts = Pools.plan(reward, rate, faction, assists, victim ~= nil)
    for key, payout in pairs(payouts) do
        payout.device = device
    end
    Rewards.audit("defense-attributed", {owner = owner, source = source,
        base = reward, rate = rate, faction = #faction, assists = #assists, device = device})
    if #faction == 0 and #assists == 0 then
        Rewards.audit("defense-no-recipient", {owner = owner, device = device})
    end
    local changed = Pools.settle(context.store, payouts, victimName, now, config.PlayerKillCooldownDays * 24)
    for key in pairs(changed) do
        local player = online[key]
        context.bindings[player].rewardDirty = true
    end
end

---@param zombie IsoZombie Death already deduplicated by Rewards
---@return boolean defense Native reward must be suppressed even for unknown owners
function Credit.zombieDeath(zombie)
    local fact = zombies[zombie]
    zombies[zombie] = nil
    if not fact then return false end
    settle(fact.owner, nil, nil, fact.horde, fact.source)
    return true
end

---@param player IsoPlayer Death already deduplicated by Rewards
---@return boolean defense Suppress ordinary kill reward
function Credit.playerDeath(player)
    local key, binding = victimBinding(player)
    if not key then return false end
    local encounter = context.store.defense.encounters[key]
    if not encounter or encounter.life ~= binding.lifeId or not encounter.owner
        or encounter.attacker ~= attackerIdentity(player) then return false end
    settle(encounter.owner, player, encounter, false, encounter.source)
    return true
end

---@param zombie IsoZombie Recycled native actor
---@return nil
function Credit.created(zombie)
    zombies[zombie] = nil
end

Events.OnWeaponHitCharacter.Add(Credit.beforeHit)
Events.OnWeaponHitXp.Add(Credit.afterHit)
Events.OnClientCommand.Add(Credit.recoveryReply)
Events.OnTick.Add(Credit.tick)
Events.OnZombieCreate.Add(Credit.created)
return Credit
