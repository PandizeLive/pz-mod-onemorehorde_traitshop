testSide = "client"
SandboxOptionsScreen = { createPanel = function(self,page) return page end,
    addPresetToList = function(self,name,text,userDefined)
        self.presets[#self.presets+1]={options={getOptionByName=function()
            return {setValue=function(self,value) testPresetMode=value end,setDefaultToCurrentValue=function() end}
        end}}
    end }
ISServerSandboxOptionsUI = {createPanel=function(self,page) return page end}
ServerSettingsScreen = {create=function(self)
    self.pageEdit={createPanel=function(self,category,page) return page end}
end}
