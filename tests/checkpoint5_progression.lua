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
check(record.life.level == 4 and record.life.tokens == 4 and record.prestige.earned == 0, "no prestige before fifth level")
check(State.awardXP(record,id,record.revision,300), "fifth level commits")
check(record.life.level == 5 and record.prestige.earned == 1, "fifth level gives one prestige")
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
    and maximum.prestige.earned == math.floor(maximum.life.level/5), "large award has canonical remainder and all milestones")
