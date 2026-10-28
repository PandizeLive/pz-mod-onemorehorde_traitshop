testStage = "description search and presentation"
local Catalog = require("OMHTS_Catalog")
local P = require("OMHTS_Presentation")
traitFixture("OVERWEIGHT", "base:overweight", 0).free = true
traitFixture("UNDERWEIGHT", "base:underweight", 0).free = true
traitFixture("BURGLAR", "base:burglar", 0).free = true
local ownedZero = {["base:overweight"]=true,["base:underweight"]=true,["base:burglar"]=true}
local grouped = P.rows(CharacterTraitDefinition.getTraits(),ownedZero,testPhase2Snapshot,"",1)
check(#grouped.other == 3 and #grouped.positive == 0 and #grouped.negative == 0,
    "zero-cost weight and profession traits have their own group")
check(grouped.other[1].tooltip ~= nil, "Other Traits retain descriptions")
local speed = traitFixture("SPEED", "base:speeddemon", 1)
function speed:getLabel() return "Speed Demon" end
function speed:getDescription() return "Drives very fast." end
local nameMatch = traitFixture("NAME_MATCH", "mod:driver", 3)
function nameMatch:getLabel() return "Drives Very Carefully" end
function nameMatch:getDescription() return "Careful driving." end
local words = traitFixture("WORDS", "mod:words", 2)
function words:getLabel() return "Careful Driver" end
function words:getDescription() return "Drives fast but very carefully." end
Catalog.definitions()
local rows = P.rows(CharacterTraitDefinition.getTraits(), {}, testPhase2Snapshot, "  DRIVES   VERY  ", 1)
check(#rows.catalog == 3 and rows.catalog[1].id == "mod:driver" and rows.catalog[2].id == "base:speeddemon",
    "name matches precede description phrases and scattered words; whitespace case normalized")
check(rows.catalog[3].id == "mod:words", "all description words match below phrase matches")
check(rows.catalog[2].tooltip == "Speed Demon\nDrives very fast.", "trait tooltip contains no generic availability text")
check(P.GOLD.r == 231/255 and P.GOLD.g == 180/255 and P.GOLD.b == 40/255, "owner gold exact hex palette")
rows = P.rows(CharacterTraitDefinition.getTraits(), {}, testPhase2Snapshot, "speed demon", 1)
check(rows.catalog[1].id == "base:speeddemon", "exact name search")
rows = P.rows(CharacterTraitDefinition.getTraits(), {}, testPhase2Snapshot, "mod:words", 1)
check(#rows.catalog == 1, "ID search preserved")
rows = P.rows(CharacterTraitDefinition.getTraits(), {}, testPhase2Snapshot, "", 1)
check(rows.catalog[1].sortPrice <= rows.catalog[#rows.catalog].sortPrice, "empty search restores price order")
for i=1,300 do traitFixture("LARGE"..i,"large:trait"..i,i%8+1) end
Catalog.definitions()
rows = P.rows(CharacterTraitDefinition.getTraits(), {}, testPhase2Snapshot, "large:", 1)
check(#rows.catalog == 300, "display discovery not limited by purchase packet cap")
for i=1,300 do testDefinitions["large:trait"..i] = nil end
Catalog.definitions()
