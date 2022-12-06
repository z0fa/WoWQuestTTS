local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local useSavedVariable = Addon.useSavedVariable
local onLoad = Addon.onLoad

local globalDB = "QuestTTSGlobalDB"

local module = {
  readTitle = useSavedVariable(globalDB, "readTitle", true),
  readObjective = useSavedVariable(globalDB, "readObjective", true),
  voice1 = useSavedVariable(globalDB, "voice1", Enum.TtsVoiceType.Standard),
  voice2 = useSavedVariable(globalDB, "voice2", Enum.TtsVoiceType.Standard),
  voice3 = useSavedVariable(globalDB, "voice3", Enum.TtsVoiceType.Standard),
  voiceSpeed = useSavedVariable(globalDB, "voiceSpeed", 0),
  voiceVolume = useSavedVariable(globalDB, "voiceVolume", 100),
  autoReadQuest = useSavedVariable(globalDB, "autoReadQuest", false),
  autoReadGossip = useSavedVariable(globalDB, "autoReadGossip", false),
  skipRecentText = useSavedVariable(globalDB, "skipRecentText", false),
  autoStopRead = useSavedVariable(globalDB, "autoStopRead", true),
  hookAutoTurnIn = useSavedVariable(globalDB, "hookAutoTurnIn", false),
  alert = useSavedVariable(globalDB, "alert", 0),
}

local function getVoiceOptions()
  local toRet = Settings.CreateControlTextContainer()

  Array.new(C_VoiceChat.GetTtsVoices()):forEach(
    function(voice)
      toRet:Add(voice.voiceID, voice.name)
    end
  )

  return toRet:GetData()
end

local function proxyRetailSetting(category, setting, name)
  local globalName = setting.globalName
  local varName = setting.varName
  local defaultValue = setting.defaultValue

  local toRet = Settings.RegisterAddOnSetting(
    category, name, varName, type(defaultValue), defaultValue
  )

  local SetValue = toRet.SetValue
  toRet.SetValue = function(self, value, force)
    local tmp = SetValue(self, value, force)

    setting.set(toRet:GetValue())

    return tmp
  end

  onLoad(
    function()
      toRet:SetValue(setting.get())
    end
  )

  return toRet
end

local function proxyLegacyCheckSetting(setting, frame)
  onLoad(
    function()
      frame:SetChecked(setting.get())
    end
  )

  frame:SetScript(
    "OnClick", function()
      if frame:GetChecked() then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
      else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
      end

      setting.set(frame:GetChecked())
    end
  )
end

local function proxyLegacyVoiceSetting(setting, frame)
  local voices = Array.new(C_VoiceChat.GetTtsVoices())

  local chunks = voices:reduce(
    function(accumulator, element, index, array)
      local chunkIndex = math.ceil(index / 10)

      if not accumulator[chunkIndex] then
        accumulator[chunkIndex] = Array.new()
      end

      accumulator[chunkIndex]:push(element)

      return accumulator
    end, Array.new()
  )

  local function updateOption()
    local voice = voices:find(
      function(v)
        if v.voiceID == setting.get() then
          return true
        end
      end
    )

    UIDropDownMenu_SetText(frame, (voice or {}).name)
    CloseDropDownMenus()
  end

  onLoad(updateOption)

  UIDropDownMenu_SetWidth(frame, 350)

  UIDropDownMenu_Initialize(
    frame, function(_, level, menuList)
      level = level or 1

      if level == 1 then
        chunks:forEach(
          function(element, index, array)

            if index == 1 then
              element:forEach(
                function(voice)
                  local info = UIDropDownMenu_CreateInfo()

                  info.text = voice.name
                  info.value = voice.voiceID
                  info.checked = setting.get() == info.value
                  info.func = function()
                    setting.set(info.value)
                    updateOption()
                  end

                  UIDropDownMenu_AddButton(info, level)
                end
              )
            else
              local info = UIDropDownMenu_CreateInfo()
              local chunkLength = chunks[1]:length()
              local startIndex = chunkLength * (index - 1)
              local stopIndex = startIndex + chunkLength

              info.text = "Voices " .. startIndex + 1 .. " - " .. stopIndex
              info.menuList = element:map(
                function(voice, i)
                  local info = UIDropDownMenu_CreateInfo()
                  info.text = voice.name
                  info.value = voice.voiceID
                  info.checked = setting.get() == info.value
                  info.func = function()
                    setting.set(info.value)
                    updateOption()
                  end

                  return info
                end
              )
              info.hasArrow = true
              info.notCheckable = true

              UIDropDownMenu_AddButton(info, level)
            end

          end
        )
      elseif menuList then
        menuList:forEach(
          function(info)
            UIDropDownMenu_AddButton(info, level)
          end
        )
      end

    end
  )
end

local function proxyLegacySliderSetting(setting, frame, min, max, step)
  onLoad(
    function()
      frame:SetValue(setting.get())
    end
  )

  frame:SetMinMaxValues(min, max)
  frame:SetValueStep(step)
  frame:SetScript(
    "OnValueChanged", function(self, value)
      setting.set(value)
    end
  )
end

local function initRetailSettings()
  local category, layout = Settings.RegisterVerticalLayoutCategory(__namespace)

  local readTitle = proxyRetailSetting(
    category, module.readTitle, "Read quest title"
  )
  Settings.CreateCheckBox(category, readTitle, "")

  local readObjective = proxyRetailSetting(
    category, module.readObjective, "Read quest objective"
  )
  Settings.CreateCheckBox(category, readObjective, "")

  local autoReadQuest = proxyRetailSetting(
    category, module.autoReadQuest, "Auto read quest text"
  )
  Settings.CreateCheckBox(category, autoReadQuest, "")

  local autoReadGossip = proxyRetailSetting(
    category, module.autoReadGossip, "Auto read gossip text"
  )
  Settings.CreateCheckBox(category, autoReadGossip, "")

  local skipRecentText = proxyRetailSetting(
    category, module.skipRecentText, "Skip recently played text"
  )
  Settings.CreateCheckBox(category, skipRecentText, "")

  local autoStopRead = proxyRetailSetting(
    category, module.autoStopRead,
    "Auto stop read when closing quest/gossip frame or interacting with npc"
  )
  Settings.CreateCheckBox(category, autoStopRead, "")

  local hookAutoTurnIn = proxyRetailSetting(
    category, module.hookAutoTurnIn,
    "Enable experimental AutoTurnIn integration (requires reload)"
  )
  Settings.CreateCheckBox(category, hookAutoTurnIn, "")

  local voice1 = proxyRetailSetting(
    category, module.voice1, "Voice for male npcs"
  )
  Settings.CreateDropDown(category, voice1, getVoiceOptions, "")

  local voice2 = proxyRetailSetting(
    category, module.voice2, "Voice for female npcs"
  )
  Settings.CreateDropDown(category, voice2, getVoiceOptions, "")

  local voice3 = proxyRetailSetting(
    category, module.voice3, "Voice for other gender npcs"
  )
  Settings.CreateDropDown(category, voice3, getVoiceOptions, "")

  local voiceSpeed = proxyRetailSetting(
    category, module.voiceSpeed, "Voice speed"
  )
  local voiceSpeedOptions = Settings.CreateSliderOptions(
    TEXTTOSPEECH_RATE_MIN, TEXTTOSPEECH_RATE_MAX, 1
  )
  voiceSpeedOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Left, function()
      return "Slow"
    end
  )
  voiceSpeedOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Right, function()
      return "Fast"
    end
  )
  Settings.CreateSlider(category, voiceSpeed, voiceSpeedOptions, "")

  local voiceVolume = proxyRetailSetting(
    category, module.voiceVolume, "Voice volume"
  )
  local voiceVolumeOptions = Settings.CreateSliderOptions(
    TEXTTOSPEECH_VOLUME_MIN, TEXTTOSPEECH_VOLUME_MAX, 1
  )
  voiceVolumeOptions:SetLabelFormatter(
    MinimalSliderWithSteppersMixin.Label.Top, function(val)
      return val .. "%"
    end
  )
  Settings.CreateSlider(category, voiceVolume, voiceVolumeOptions, "")

  layout:AddInitializer(
    Settings.CreatePanelInitializer(
      "QuestTTSAdvertisement", {}
    )
  )

  Settings.RegisterAddOnCategory(category)
end

local function initLegacySettings()
  local frame = CreateFrame("Frame", "QuestTTSOptionsPanel")

  local title = frame:CreateFontString(
    "QuestTTSOptionsPanelTitle", "ARTWORK", "GameFontNormalLarge"
  )
  title:SetText(__namespace)
  title:SetJustifyH("LEFT")
  title:SetJustifyV("TOP")
  title:SetPoint("TOPLEFT", 16, -16)

  local description = frame:CreateFontString(
    "QuestTTSOptionsPanelSubText", "ARTWORK", "GameFontHighlightSmall"
  )
  description:SetText("I don't know what to write here...")
  description:SetNonSpaceWrap(true)
  description:SetMaxLines(3)
  description:SetJustifyH("LEFT")
  description:SetJustifyV("TOP")
  description:SetSize(32, 0)
  description:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelTitle", "BOTTOMLEFT", 0, -8
  )
  description:SetPoint("RIGHT", 32, 0)

  local readTitle = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelReadTitle", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  readTitle:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelSubText", "BOTTOMLEFT", -2, -8
  )
  local readTitleText = readTitle:CreateFontString(
    "QuestTTSOptionsPanelReadTitleText", "ARTWORK", "GameFontHighlightLeft"
  )
  readTitleText:SetText("Read quest title")
  readTitleText:SetSize(275, 275)
  readTitleText:SetPoint("LEFT", readTitle, "RIGHT", 2, 1)
  proxyLegacyCheckSetting(module.readTitle, readTitle)

  local readObjective = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelReadObjective", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  readObjective:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelReadTitle", "BOTTOMLEFT", 0, -8
  )
  local readObjectiveText = readObjective:CreateFontString(
    "QuestTTSOptionsPanelReadObjectiveText", "ARTWORK", "GameFontHighlightLeft"
  )
  readObjectiveText:SetText("Read quest objective")
  readObjectiveText:SetSize(275, 275)
  readObjectiveText:SetPoint("LEFT", readObjective, "RIGHT", 2, 1)
  proxyLegacyCheckSetting(module.readObjective, readObjective)

  local autoReadQuest = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelAutoReadQuest", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  autoReadQuest:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelSubText", "BOTTOMLEFT", 300, -8
  )
  local autoReadQuestText = autoReadQuest:CreateFontString(
    "QuestTTSOptionsPanelAutoReadQuestText", "ARTWORK", "GameFontHighlightLeft"
  )
  autoReadQuestText:SetText("Auto read quest text")
  autoReadQuestText:SetSize(275, 275)
  autoReadQuestText:SetPoint("LEFT", autoReadQuest, "RIGHT", 2, 1)
  proxyLegacyCheckSetting(module.autoReadQuest, autoReadQuest)

  local autoReadGossip = CreateFrame(
    "CheckButton", "QuestTTSOptionsPanelAutoReadGossip", frame,
    "OptionsBaseCheckButtonTemplate"
  )
  autoReadGossip:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelAutoReadQuest", "BOTTOMLEFT", 0, -8
  )
  local autoReadGossipText = autoReadGossip:CreateFontString(
    "QuestTTSOptionsPanelAutoReadGossipText", "ARTWORK", "GameFontHighlightLeft"
  )
  autoReadGossipText:SetText("Auto read gossip text")
  autoReadGossipText:SetSize(275, 275)
  autoReadGossipText:SetPoint("LEFT", autoReadGossip, "RIGHT", 2, 1)
  proxyLegacyCheckSetting(module.autoReadGossip, autoReadGossip)

  local voice1 = CreateFrame(
    "Frame", "QuestTTSOptionsPanelVoice1DropDown", frame,
    "UIDropDownMenuTemplate"
  )
  voice1:EnableMouse(true)
  voice1:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelReadObjective", "BOTTOMLEFT", -13, -24
  )
  local voice1Text = voice1:CreateFontString(
    "QuestTTSOptionsPanelVoice1DropDownText", "BACKGROUND",
    "GameFontHighlightLeft"
  )
  voice1Text:SetText("Voice for male npc")
  voice1Text:SetPoint("BOTTOMLEFT", voice1, "TOPLEFT", 16, 3)
  proxyLegacyVoiceSetting(module.voice1, voice1)

  local voice2 = CreateFrame(
    "Frame", "QuestTTSOptionsPanelVoice2DropDown", frame,
    "UIDropDownMenuTemplate"
  )
  voice2:EnableMouse(true)
  voice2:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelVoice1DropDown", "BOTTOMLEFT", 0, -24
  )
  local voice2Text = voice2:CreateFontString(
    "QuestTTSOptionsPanelVoice2DropDownText", "BACKGROUND",
    "GameFontHighlightLeft"
  )
  voice2Text:SetText("Voice for female npc")
  voice2Text:SetPoint("BOTTOMLEFT", voice2, "TOPLEFT", 16, 3)
  proxyLegacyVoiceSetting(module.voice2, voice2)

  local voice3 = CreateFrame(
    "Frame", "QuestTTSOptionsPanelVoice3DropDown", frame,
    "UIDropDownMenuTemplate"
  )
  voice3:EnableMouse(true)
  voice3:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelVoice2DropDown", "BOTTOMLEFT", 0, -24
  )
  local voice3Text = voice3:CreateFontString(
    "QuestTTSOptionsPanelVoice3DropDownText", "BACKGROUND",
    "GameFontHighlightLeft"
  )
  voice3Text:SetText("Voice for other gender npcs")
  voice3Text:SetPoint("BOTTOMLEFT", voice3, "TOPLEFT", 16, 3)
  proxyLegacyVoiceSetting(module.voice3, voice3)

  local voiceSpeed = CreateFrame(
    "Slider", "QuestTTSOptionsPanelVoiceSpeed", frame, "OptionsSliderTemplate"
  )
  voiceSpeed:SetSize(235, 17)
  voiceSpeed:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelVoice3DropDown", "TOPLEFT", 17, -50
  )
  voiceSpeed:SetOrientation("HORIZONTAL")
  _G["QuestTTSOptionsPanelVoiceSpeedText"]:SetText("Voice speed")
  _G["QuestTTSOptionsPanelVoiceSpeedLow"]:SetText("Slow")
  _G["QuestTTSOptionsPanelVoiceSpeedHigh"]:SetText("Fast")
  proxyLegacySliderSetting(
    module.voiceSpeed, voiceSpeed, TEXTTOSPEECH_RATE_MIN, TEXTTOSPEECH_RATE_MAX,
    1
  )

  local voiceVolume = CreateFrame(
    "Slider", "QuestTTSOptionsPanelVoiceVolume", frame, "OptionsSliderTemplate"
  )
  voiceVolume:SetSize(235, 17)
  voiceVolume:SetPoint(
    "TOPLEFT", "QuestTTSOptionsPanelVoiceSpeed", "TOPLEFT", 0, -50
  )
  voiceVolume:SetOrientation("HORIZONTAL")
  _G["QuestTTSOptionsPanelVoiceVolumeText"]:SetText("Voice volume")
  _G["QuestTTSOptionsPanelVoiceVolumeLow"]:SetText("0%")
  _G["QuestTTSOptionsPanelVoiceVolumeHigh"]:SetText("100%")
  proxyLegacySliderSetting(
    module.voiceVolume, voiceVolume, TEXTTOSPEECH_VOLUME_MIN,
    TEXTTOSPEECH_VOLUME_MAX, 1
  )

  local advertisement = CreateFrame(
    "Frame", "QuestTTSOptionsPanelAdvertisement", frame, "QuestTTSAdvertisement"
  )
  advertisement:SetSize(590, 200)
  advertisement:SetPoint("BOTTOMLEFT", 18, 22)

  frame.name = __namespace
  InterfaceOptions_AddCategory(frame)
end

onLoad(
  function()
    if Addon.isRetail then
      initRetailSettings()
    else
      initLegacySettings()
    end
  end
)

__module.Settings = module
