testStage = "Checkpoint 5 progression"
local State = require("OMHTS_State")
local Progression = require("OMHTS_Progression")
local expected = {100,150,200,250,300,350,450,500,600,700,800,900,1000,1150,1250,1400,1550,1700,1850,2000}
for index = 1, #expected do
    check(Progression.requiredXP(index - 1) == expected[index], "approved curve level " .. index)
end
local store = {}
State.initialize(store)
local record = State.attach(store, "progression", 51, 0)
local id = record.life.id
check(State.awardXP(record,id,record.revision,99), "partial XP commits")
check(record.life.xp == 99 and record.life.level == 0 and record.life.tokens == 0, "partial XP grants no Token")
local revision = record.revision
check(State.awardXP(record,id,revision,1), "exact level threshold commits")
check(record.life.level == 1 and record.life.tokens == 1 and record.life.xp == 0, "first level gives exactly one Token")
check(not State.awardXP(record,id,revision,1) and record.life.tokens == 1, "replayed award revision is rejected")
check(State.awardXP(record,id,record.revision,600), "multi-level XP award commits")
check(record.life.level == 4 and record.life.tokens == 4 and record.prestige.earned == 1, "displayed Level 5 earns first prestige")
check(State.awardXP(record,id,record.revision,300), "fifth level commits")
check(record.life.level == 5 and record.prestige.earned == 1, "displayed Level 6 does not repeat prestige")
check(State.update(record,id,record.revision,{tokens=0}), "spend Tokens independently")
check(record.prestige.earned == 1, "spending never changes prestige")
check(State.awardXP(record,id,record.revision,2600.5), "cross fifth-to-tenth milestone with partial remainder")
check(record.life.level == 10 and record.life.tokens == 5 and record.life.xp == 0.5
    and record.prestige.earned == 2, "tenth level awards only the new milestone")
store = nativeRoundTrip(store)
check(State.initialize(store), "progression survives native persistence")
record = State.attach(store,"progression",51,0.1)
check(record.life.level == 10 and record.life.tokens == 5 and record.life.xp == 0.5
    and record.prestige.earned == 2, "reload never replays level rewards")
for _, amount in pairs({-1,0,0/0,1/0,State.LIMIT+1,"100"}) do
    check(not State.awardXP(record,id,record.revision,amount), "invalid XP rejected atomically")
end
check(not State.awardXP(record,id+1,record.revision,100), "foreign life XP rejected")
record.life.tokens = State.LIMIT
revision = record.revision
check(not State.awardXP(record,id,revision,800) and record.revision == revision
    and record.life.xp == 0.5, "wallet overflow leaves all fields unchanged")
record.life.tokens = 5
check(State.settleDeath(record,id), "progressed life settles death")
check(record.life.level == 0 and record.life.xp == 0 and record.life.tokens == 0
    and record.prestige.pending == 2, "death clears life progress and preserves prestige entitlement")
check(not State.awardXP(record,id,record.revision,100), "dead player cannot gain XP")
check(not State.settleDeath(record,id) and record.prestige.pending == 2, "duplicate death never duplicates prestige")
record = State.attach(store,"progression",52,0)
check(record.prestige.pending == 2 and record.life.level == 0 and record.life.tokens == 0, "replacement keeps only pending prestige")
local maximum = State.attach(store,"maximum",60,0)
check(State.awardXP(maximum,maximum.life.id,maximum.revision,State.LIMIT), "large bounded reward completes")
check(maximum.life.level > 100 and maximum.life.xp < Progression.requiredXP(maximum.life.level)
    and maximum.prestige.earned == math.floor((maximum.life.level+1)/5), "large award has canonical remainder and all milestones")

local legacy = State.attach(store,"legacy-milestone",61,0)
legacy.life.level = 4
legacy.life.prestigeRule = nil
legacy.prestige.earned = 0
local oldTokens = legacy.life.tokens
legacy = State.attach(store,"legacy-milestone",61,0.1)
check(legacy.prestige.earned == 1 and legacy.life.tokens == oldTokens,
    "existing displayed Level 5 receives missing prestige without Token grants")
local migratedRevision = legacy.revision
store = nativeRoundTrip(store)
legacy = State.attach(store,"legacy-milestone",61,0.2)
check(legacy.prestige.earned == 1 and legacy.revision == migratedRevision,
    "saved milestone correction never repeats on reconnect")

local options = SandboxVars.OMHTraitShop
local configurable = State.attach(store, "configured-rewards", 63, 0)
options.TokensPerLevel = 3
options.PrestigeLevelInterval = 3
check(State.awardXP(configurable, configurable.life.id, configurable.revision, 250), "configured batch commits")
check(configurable.life.level == 2 and configurable.life.tokens == 6
    and configurable.life.earnedLevelTokens == 6 and configurable.prestige.earned == 1,
    "displayed Level 3 grants two three-Token rewards and one Prestige")
store = nativeRoundTrip(store)
configurable = State.attach(store, "configured-rewards", 63, 0.1)
check(configurable.life.earnedLevelTokens == 6 and configurable.prestige.earned == 1,
    "custom rewards persist without recomputing on reload")
options.TokensPerLevel = 0
options.PrestigeLevelInterval = 1
check(State.awardXP(configurable, configurable.life.id, configurable.revision, 200), "zero Tokens allowed")
check(configurable.life.tokens == 6 and configurable.life.earnedLevelTokens == 6
    and configurable.prestige.earned == 2, "setting changes affect only future rewards without backfill")
local oldRevision = configurable.revision
options.PrestigeLevelInterval = 0
check(not State.awardXP(configurable, configurable.life.id, oldRevision, 250)
    and configurable.revision == oldRevision, "invalid interval rejected atomically")
options.PrestigeLevelInterval = 5
options.TokensPerLevel = 1.5
check(not State.awardXP(configurable, configurable.life.id, oldRevision, 250), "fractional Tokens rejected")
options.TokensPerLevel = 1
local toggle = State.attach(store, "interval-toggle", 64, 0)
check(State.awardXP(toggle, toggle.life.id, toggle.revision, 700), "default milestone grants once")
for interval = 6, 12 do
    options.PrestigeLevelInterval = interval
    check(State.awardXP(toggle, toggle.life.id, toggle.revision, Progression.requiredXP(toggle.life.level)),
        "harder interval still permits leveling")
    check(toggle.prestige.earned == 1, "changing intervals cannot farm the first Prestige entitlement")
end
options.PrestigeLevelInterval = 5
local oldSave = State.attach(store, "old-token-history", 65, 0)
oldSave.life.level = 2
oldSave.life.earnedLevelTokens = nil
options.TokensPerLevel = 4
check(State.awardXP(oldSave, oldSave.life.id, oldSave.revision, 200)
    and oldSave.life.earnedLevelTokens == 6, "legacy Token history preserves two old one-Token levels")
options.TokensPerLevel = nil
options.PrestigeLevelInterval = nil
