testStage="Checkpoint 6 sandbox mode visibility"
local UI=require("OMHTS_SandboxUI")
local Config=require("OMHTS_RewardsConfig")
local function control()
    return {height=24,y=11,visible=true,getHeight=function(self) return self.height end,
        setVisible=function(self,value) self.visible=value end,setY=function(self,value) self.y=value end}
end
local function panel()
    local value={settingNames={},controls={},labels={},joypadButtonsY={},children={},width=800,
        getWidth=function(self) return self.width end,
        addChild=function(self,child) self.children[#self.children+1]=child end,
        prerender=function(self) self.originalCalled=true end,
        setYScroll=function(self,value) self.scroll=value end,
        setScrollHeight=function(self,value) self.scrollHeight=value end,
        insertNewLineOfButtons=function(self,value) self.joypadButtonsY[#self.joypadButtonsY+1]={value} end}
    local keys={"PositiveCostMultiplier","NegativeCostMultiplier","AllowNegativeRemoval","TokensPerLevel","PrestigeLevelInterval","PrestigeRetentionPercentage","RewardMode",
        "ZombieXP","PlayerKillXP","DayXP","NightXP","HordeZombieXP","HordeSurvivedXP","PlayerKillCooldownDays"}
    for i=1,#keys do
        local name="OMHTraitShop."..keys[i]
        value.settingNames[i]=name
        value.labels[name]=control()
        value.controls[name]=control()
    end
    value.controls["OMHTraitShop.RewardMode"].selected=4
    return value
end
local p=SandboxOptionsScreen:createPanel(panel())
for mode=1,4 do
    p.controls["OMHTraitShop.RewardMode"].selected=mode
    p:prerender()
    local count=0
    local bottom=0
    for i=1,#p.settingNames do
        local name=p.settingNames[i]
        local key=string.match(name,"%.(.+)$")
        local expected=Config.defaults[key]==nil or Config.visible(mode,key)
        check(p.controls[name].visible==expected and p.labels[name].visible==expected,"control and label mode visibility "..mode..":"..key)
        if expected then
            local title=p.omhSectionTitles[name]
            if title then
                check(title.visible and title.y>=bottom and title.y+title.height<=p.controls[name].y,
                    "section heading fits above its first control without overlap")
                check(title.font==UIFont.Large and title.x==(p.width-title.width)/2,
                    "section heading matches native large centered style")
            end
            check(p.controls[name].y>=bottom and p.controls[name].y==p.labels[name].y,
                "visible labels and controls align without overlap")
            bottom=p.controls[name].y+p.controls[name].height
            count=count+1
        end
    end
    check(p.scrollHeight==bottom+10 and #p.joypadButtonsY==count
        and p.joypadButtons==p.joypadButtonsY[1],"scroll and keyboard rows match visible mode")
    check(p.omhSectionTitles["OMHTraitShop.PlayerKillCooldownDays"].visible==(mode==1 or mode==4),
        "Player Kill Rules heading hides with inapplicable cooldown")
end
check(p.originalCalled,"native panel render still called")
local previous=p.prerender
UI.attach(p)
check(previous==p.prerender,"panel hook is not installed twice")
check(#p.children==5 and #p.titles==5,"exactly five section headers without duplicate attachment")
p.width=600
p.scroll=50
p:prerender()
check(p.omhSectionTitles["OMHTraitShop.RewardMode"].x==200 and p.scroll==50,
    "resizing recenters headings without resetting scroll")
local admin=ISServerSandboxOptionsUI:createPanel(panel())
check(admin.omhRewardLayout,"live admin sandbox panel receives visibility rules")
admin:prerender()
check(#admin.titles==5 and admin.scrollHeight>admin.controls["OMHTraitShop.PlayerKillCooldownDays"].y,
    "live admin includes headings in scroll layout")
local host=setmetatable({}, {__index=ServerSettingsScreen})
host:create()
local hostPanel=host.pageEdit:createPanel({},panel())
check(hostPanel.omhRewardLayout,"host settings editor receives visibility rules")
hostPanel:prerender()
check(#hostPanel.titles==5,"host settings editor includes all section headers")
local unrelated={controls={}}
check(UI.attach(unrelated)==unrelated and not unrelated.omhRewardLayout,"unrelated mod panels remain unchanged")
testHorde=true
local presets=setmetatable({presets={}}, {__index=SandboxOptionsScreen})
presets:addPresetToList("Apocalypse","Apocalypse",false)
check(testPresetMode==3,"built-in preset uses dependency default")
testPresetMode=4
presets:addPresetToList("Mine","Mine",true)
check(testPresetMode==4,"user presets are never overwritten by default selection")
testOutput=tostring(testChecks).." Checkpoint 6 reward and sandbox UI checks passed."
