local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Array = __module.Array --- @class Array
local Settings = __module.Settings
local GameSettings = _G["Settings"]

local onLoad = Addon.onLoad
local useHook = Addon.useHook

local module = {}

function module.isQuestFrameShown()
  if Addon.isRetail then
    return QuestFrame:IsShown()
  else
    return QuestLogFrame:IsShown() or QuestLogDetailFrame:IsShown()
  end
end

function module.getGossipText()
  return C_GossipInfo.GetText()
end

function module.getQuestLogTitle()
  if Addon.isRetail then
    return C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
  else
    return GetQuestLogTitle(GetQuestLogSelection())
  end
end

function module.useGossipUpdateHook(fn)
  useHook("Update", fn, "secure-function", GossipFrame)
end

function module.initPlayButton(buttons, factory)
  if Addon.isRetail then
    buttons:push(
      factory(
        QuestMapFrame.DetailsFrame.BackFrame, -8, -10, "quest:focused"
      )
    )
    buttons:push(factory(QuestFrame, -20, 0, "quest"))
    buttons:push(factory(GossipFrame, -20, 0, "gossip"))
    buttons:push(factory(ItemTextFrame, -20, 0, "book"))
  else
    buttons:push(factory(QuestFrame, -54, -20, "quest"))
    buttons:push(factory(QuestLogFrame, -24, -13, "quest:focused"))
    buttons:push(factory(QuestLogDetailFrame, -24, -13, "quest:focused"))
    buttons:push(factory(GossipFrame, -54, -20, "gossip"))
    buttons:push(factory(ItemTextFrame, -55, -14, "book"))
  end
end

function module.initSettings()
  if Addon.isRetail or Addon.isCata then
    local function getVoiceOptions()
      local toRet = GameSettings.CreateControlTextContainer()

      Array.new(C_VoiceChat.GetTtsVoices()):forEach(
        function(voice)
          toRet:Add(voice.voiceID, voice.name)
        end
      )

      return toRet:GetData()
    end

    local function proxySetting(category, setting, name)
      local globalName = setting.globalName
      local varName = setting.varName
      local defaultValue = setting.defaultValue

      local varTbl = _G[globalName]
      local varKey = varName
      local toRet = GameSettings.RegisterAddOnSetting(
        category, varName, varKey, varTbl, type(defaultValue), name,
        defaultValue
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

    local category, layout = GameSettings.RegisterVerticalLayoutCategory(
      __namespace
    )
    Settings.CATEGORY_ID = category:GetID()

    local readTitle = proxySetting(
      category, Settings.readTitle, "Read quest title"
    )
    GameSettings.CreateCheckbox(category, readTitle, "")

    local readObjective = proxySetting(
      category, Settings.readObjective, "Read quest objective"
    )
    GameSettings.CreateCheckbox(category, readObjective, "")

    local readNpcName = proxySetting(
      category, Settings.readNpcName, "Read npc name"
    )
    GameSettings.CreateCheckbox(category, readNpcName, "")

    local autoReadQuest = proxySetting(
      category, Settings.autoReadQuest, "Auto read quest text"
    )
    GameSettings.CreateCheckbox(category, autoReadQuest, "")

    local autoReadGossip = proxySetting(
      category, Settings.autoReadGossip, "Auto read gossip text"
    )
    GameSettings.CreateCheckbox(category, autoReadGossip, "")

    local skipRecentText = proxySetting(
      category, Settings.skipRecentText, "Skip recently played text"
    )
    GameSettings.CreateCheckbox(category, skipRecentText, "")

    local autoStopRead = proxySetting(
      category, Settings.autoStopRead,
      "Auto stop read when closing quest/gossip frame or interacting with npc"
    )
    GameSettings.CreateCheckbox(category, autoStopRead, "")

    local hookAutoTurnIn = proxySetting(
      category, Settings.hookAutoTurnIn,
      "Enable experimental AutoTurnIn integration (requires reload)"
    )
    GameSettings.CreateCheckbox(category, hookAutoTurnIn, "")

    local voice1 =
      proxySetting(category, Settings.voice1, "Voice for male npcs")
    GameSettings.CreateDropdown(category, voice1, getVoiceOptions, "")

    local voice2 = proxySetting(
      category, Settings.voice2, "Voice for female npcs"
    )
    GameSettings.CreateDropdown(category, voice2, getVoiceOptions, "")

    local voice3 = proxySetting(
      category, Settings.voice3, "Voice for other gender npcs"
    )
    GameSettings.CreateDropdown(category, voice3, getVoiceOptions, "")

    local useNarrator = proxySetting(
      category, Settings.useNarrator, "Use other gender voice as narrator"
    )
    GameSettings.CreateCheckbox(
      category, useNarrator,
      "Reads quest titles, npc names, objectives and text in <> using other gender voice."
    )

    local voiceSpeed =
      proxySetting(category, Settings.voiceSpeed, "Voice speed")
    local voiceSpeedOptions = GameSettings.CreateSliderOptions(
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
    GameSettings.CreateSlider(category, voiceSpeed, voiceSpeedOptions, "")

    local voiceVolume = proxySetting(
      category, Settings.voiceVolume, "Voice volume"
    )
    local voiceVolumeOptions = GameSettings.CreateSliderOptions(
      TEXTTOSPEECH_VOLUME_MIN, TEXTTOSPEECH_VOLUME_MAX, 1
    )
    voiceVolumeOptions:SetLabelFormatter(
      MinimalSliderWithSteppersMixin.Label.Top, function(val)
        return val .. "%"
      end
    )
    GameSettings.CreateSlider(category, voiceVolume, voiceVolumeOptions, "")

    GameSettings.RegisterAddOnCategory(category)
  else
    local function proxyCheckSetting(setting, frame)
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

    local function proxyVoiceSetting(setting, frame)
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

      UIDropDownMenu_SetWidth(frame, 150)

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

    local function proxySliderSetting(setting, frame, min, max, step)
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
    proxyCheckSetting(Settings.readTitle, readTitle)

    local readObjective = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelReadObjective", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    readObjective:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelReadTitle", "BOTTOMLEFT", 0, -8
    )
    local readObjectiveText = readObjective:CreateFontString(
      "QuestTTSOptionsPanelReadObjectiveText", "ARTWORK",
      "GameFontHighlightLeft"
    )
    readObjectiveText:SetText("Read quest objective")
    readObjectiveText:SetSize(275, 275)
    readObjectiveText:SetPoint("LEFT", readObjective, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.readObjective, readObjective)

    local readNpcName = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelReadNpcName", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    readNpcName:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelReadObjective", "BOTTOMLEFT", 0, -8
    )
    local readNpcNameText = readNpcName:CreateFontString(
      "QuestTTSOptionsPanelReadNpcNameText", "ARTWORK", "GameFontHighlightLeft"
    )
    readNpcNameText:SetText("Read npc name")
    readNpcNameText:SetSize(275, 275)
    readNpcNameText:SetPoint("LEFT", readNpcName, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.readNpcName, readNpcName)

    local skipRecentText = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelSkipRecentText", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    skipRecentText:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelReadNpcName", "BOTTOMLEFT", 0, -8
    )
    local skipRecentTextText = readObjective:CreateFontString(
      "QuestTTSOptionsPanelSkipRecentTextText", "ARTWORK",
      "GameFontHighlightLeft"
    )
    skipRecentTextText:SetText("Skip recently played text")
    skipRecentTextText:SetSize(275, 275)
    skipRecentTextText:SetPoint("LEFT", skipRecentText, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.skipRecentText, skipRecentText)

    local autoReadQuest = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelAutoReadQuest", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    autoReadQuest:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelSubText", "BOTTOMLEFT", 300, -8
    )
    local autoReadQuestText = autoReadQuest:CreateFontString(
      "QuestTTSOptionsPanelAutoReadQuestText", "ARTWORK",
      "GameFontHighlightLeft"
    )
    autoReadQuestText:SetText("Auto read quest text")
    autoReadQuestText:SetSize(275, 275)
    autoReadQuestText:SetPoint("LEFT", autoReadQuest, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.autoReadQuest, autoReadQuest)

    local autoReadGossip = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelAutoReadGossip", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    autoReadGossip:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelAutoReadQuest", "BOTTOMLEFT", 0, -8
    )
    local autoReadGossipText = autoReadGossip:CreateFontString(
      "QuestTTSOptionsPanelAutoReadGossipText", "ARTWORK",
      "GameFontHighlightLeft"
    )
    autoReadGossipText:SetText("Auto read gossip text")
    autoReadGossipText:SetSize(275, 275)
    autoReadGossipText:SetPoint("LEFT", autoReadGossip, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.autoReadGossip, autoReadGossip)

    local autoStopRead = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelAutoStopRead", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    autoStopRead:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelReadObjective", "BOTTOMLEFT", 300, -8
    )
    local autoStopReadText = readObjective:CreateFontString(
      "QuestTTSOptionsPanelAutoStopReadText", "ARTWORK", "GameFontHighlightLeft"
    )
    autoStopReadText:SetText(
      "Auto stop read when closing quest/gossip frame or interacting with npc"
    )
    autoStopReadText:SetSize(275, 275)
    autoStopReadText:SetPoint("LEFT", autoStopRead, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.autoStopRead, autoStopRead)

    local hookAutoTurnIn = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelHookAutoTurnIn", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    hookAutoTurnIn:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelAutoStopRead", "BOTTOMLEFT", 0, -8
    )
    local hookAutoTurnInText = readObjective:CreateFontString(
      "QuestTTSOptionsPanelHookAutoTurnInText", "ARTWORK",
      "GameFontHighlightLeft"
    )
    hookAutoTurnInText:SetText(
      "Enable experimental AutoTurnIn integration (requires reload)"
    )
    hookAutoTurnInText:SetSize(275, 275)
    hookAutoTurnInText:SetPoint("LEFT", hookAutoTurnIn, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.hookAutoTurnIn, hookAutoTurnIn)

    local voice1 = CreateFrame(
      "Frame", "QuestTTSOptionsPanelVoice1DropDown", frame,
      "UIDropDownMenuTemplate"
    )
    voice1:EnableMouse(true)
    voice1:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelSkipRecentText", "BOTTOMLEFT", -13, -24
    )
    local voice1Text = voice1:CreateFontString(
      "QuestTTSOptionsPanelVoice1DropDownText", "BACKGROUND",
      "GameFontHighlightLeft"
    )
    voice1Text:SetText("Voice for male npc")
    voice1Text:SetPoint("BOTTOMLEFT", voice1, "TOPLEFT", 16, 3)
    proxyVoiceSetting(Settings.voice1, voice1)

    local voice2 = CreateFrame(
      "Frame", "QuestTTSOptionsPanelVoice2DropDown", frame,
      "UIDropDownMenuTemplate"
    )
    voice2:EnableMouse(true)
    voice2:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelSkipRecentText", "BOTTOMLEFT", 195, -24
    )
    local voice2Text = voice2:CreateFontString(
      "QuestTTSOptionsPanelVoice2DropDownText", "BACKGROUND",
      "GameFontHighlightLeft"
    )
    voice2Text:SetText("Voice for female npc")
    voice2Text:SetPoint("BOTTOMLEFT", voice2, "TOPLEFT", 16, 3)
    proxyVoiceSetting(Settings.voice2, voice2)

    local voice3 = CreateFrame(
      "Frame", "QuestTTSOptionsPanelVoice3DropDown", frame,
      "UIDropDownMenuTemplate"
    )
    voice3:EnableMouse(true)
    voice3:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelSkipRecentText", "BOTTOMLEFT", 400, -24
    )
    local voice3Text = voice3:CreateFontString(
      "QuestTTSOptionsPanelVoice3DropDownText", "BACKGROUND",
      "GameFontHighlightLeft"
    )
    voice3Text:SetText("Voice for other gender npcs")
    voice3Text:SetPoint("BOTTOMLEFT", voice3, "TOPLEFT", 16, 3)
    proxyVoiceSetting(Settings.voice3, voice3)

    local voiceSpeed = CreateFrame(
      "Slider", "QuestTTSOptionsPanelVoiceSpeed", frame, "OptionsSliderTemplate"
    )
    voiceSpeed:SetSize(235, 17)
    voiceSpeed:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelVoice1DropDown", "TOPLEFT", 17, -50
    )
    voiceSpeed:SetOrientation("HORIZONTAL")
    _G["QuestTTSOptionsPanelVoiceSpeedText"]:SetText("Voice speed")
    _G["QuestTTSOptionsPanelVoiceSpeedLow"]:SetText("Slow")
    _G["QuestTTSOptionsPanelVoiceSpeedHigh"]:SetText("Fast")
    proxySliderSetting(
      Settings.voiceSpeed, voiceSpeed, TEXTTOSPEECH_RATE_MIN,
      TEXTTOSPEECH_RATE_MAX, 1
    )

    local voiceVolume = CreateFrame(
      "Slider", "QuestTTSOptionsPanelVoiceVolume", frame,
      "OptionsSliderTemplate"
    )
    voiceVolume:SetSize(235, 17)
    voiceVolume:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelVoice1DropDown", "TOPLEFT", 365, -50
    )
    voiceVolume:SetOrientation("HORIZONTAL")
    _G["QuestTTSOptionsPanelVoiceVolumeText"]:SetText("Voice volume")
    _G["QuestTTSOptionsPanelVoiceVolumeLow"]:SetText("0%")
    _G["QuestTTSOptionsPanelVoiceVolumeHigh"]:SetText("100%")
    proxySliderSetting(
      Settings.voiceVolume, voiceVolume, TEXTTOSPEECH_VOLUME_MIN,
      TEXTTOSPEECH_VOLUME_MAX, 1
    )

    local useNarrator = CreateFrame(
      "CheckButton", "QuestTTSOptionsPanelUseNarrator", frame,
      "OptionsBaseCheckButtonTemplate"
    )
    useNarrator:SetPoint(
      "TOPLEFT", "QuestTTSOptionsPanelVoiceSpeed", "BOTTOMLEFT", 0, -16
    )
    local useNarratorText = useNarrator:CreateFontString(
      "QuestTTSOptionsPanelUseNarratorText", "ARTWORK", "GameFontHighlightLeft"
    )
    useNarratorText:SetText("Use other gender voice as narrator")
    useNarratorText:SetSize(275, 275)
    useNarratorText:SetPoint("LEFT", useNarrator, "RIGHT", 2, 1)
    proxyCheckSetting(Settings.useNarrator, useNarrator)

    frame.name = __namespace
    InterfaceOptions_AddCategory(frame)
  end
end

__module.CrossExp = module
