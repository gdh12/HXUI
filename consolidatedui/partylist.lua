require('common');
local imgui = require('imgui');
local fonts = require('fonts');
local primitives = require('primitives');

local fullMenuSizeX;
local fullMenuSizeY;
local backgroundPrim;
local selectionPrim;
local partyTargeted;
local memberText = {};

local partyList = {};

local function UpdateTextVisibilityByMember(memIdx, visible)

    memberText[memIdx].hp:SetVisible(visible);
    memberText[memIdx].mp:SetVisible(visible);
    memberText[memIdx].tp:SetVisible(visible);
    memberText[memIdx].name:SetVisible(visible);
end

local function UpdateTextVisibility(visible)

    for i = 0, 5 do
        UpdateTextVisibilityByMember(i, visible);
    end
    if (not visible) then
        backgroundPrim.visible = visible;
        selectionPrim.visible = visible;
    end
end

local function GetMemberInformation(memIdx)

    local party = AshitaCore:GetMemoryManager():GetParty();
    local player = AshitaCore:GetMemoryManager():GetPlayer();

	local playerTarget = AshitaCore:GetMemoryManager():GetTarget();
    if (player == nil or party == nil or party:GetMemberIsActive(memIdx) == 0) then
        return nil;
    end

    local memberInfo = {};
    memberInfo.zone = party:GetMemberZone(memIdx);
    memberInfo.inzone = memberInfo.zone == party:GetMemberZone(0);
    memberInfo.name = party:GetMemberName(memIdx);
    memberInfo.leader = party:GetAlliancePartyLeaderServerId1() == party:GetMemberServerId(memIdx);

    if (memberInfo.inzone == true) then
        memberInfo.hp = party:GetMemberHP(memIdx);
        memberInfo.hpp = party:GetMemberHPPercent(memIdx) / 100;
        memberInfo.maxhp = memberInfo.hp / memberInfo.hpp;
        memberInfo.mp = party:GetMemberMP(memIdx);
        memberInfo.mpp = party:GetMemberMPPercent(memIdx) / 100;
        memberInfo.maxmp = memberInfo.mp / memberInfo.mpp;
        memberInfo.tp = party:GetMemberTP(memIdx);
        memberInfo.job = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", party:GetMemberMainJob(memIdx));
        memberInfo.level = party:GetMemberMainJobLevel(memIdx);
        if (playerTarget ~= nil) then
            memberInfo.targeted = playerTarget:GetTargetIndex(0) == party:GetMemberTargetIndex(memIdx);
        else
            memberInfo.targeted = false;
        end
    else
        memberInfo.hp = 0;
        memberInfo.hpp = 0;
        memberInfo.maxhp = 0;
        memberInfo.mp = 0;
        memberInfo.mpp = 0;
        memberInfo.maxmp = 0;
        memberInfo.tp = 0;
        memberInfo.job = '';
        memberInfo.level = '';
    end

    return memberInfo;
end

local function DrawMember(memIdx, settings, userSettings)

    local memInfo = GetMemberInformation(memIdx);
    if (memInfo == nil) then
        UpdateTextVisibilityByMember(memIdx, false);
        return;
    end

    -- Get the hp color for bars and text
    local hpNameColor;
    local hpBarColor;
    if (memInfo.hpp < .25) then 
        hpNameColor = 0xFFFF0000;
        hpBarColor = { 1, 0, 0, 1};
    elseif (memInfo.hpp < .50) then;
        hpNameColor = 0xFFFFA500;
        hpBarColor = { 1, 0.65, 0, 1};
    elseif (memInfo.hpp < .75) then
        hpNameColor = 0xFFFFFF00;
        hpBarColor = { 1, 1, 0, 1};
    else
        hpNameColor = 0xFFFFFFFF;
        hpBarColor = {1, .4, .4, 1};
    end

    local allBarsLengths = settings.hpBarWidth + settings.mpBarWidth + settings.tpBarWidth + (settings.barSpacing * 2);

    -- Draw the HP bar
    local hpStartX, hpStartY = imgui.GetCursorScreenPos();
    memberText[memIdx].hp:SetColor(hpNameColor);
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, hpBarColor);
    if (memInfo.inzone) then
        imgui.ProgressBar(memInfo.hpp, { settings.hpBarWidth, settings.barHeight }, '');
    else
        imgui.ProgressBar(0, { allBarsLengths, settings.barHeight + memberText[memIdx].hp:GetFontHeight()}, AshitaCore:GetResourceManager():GetString("zones.names", memInfo.zone));
    end
    imgui.PopStyleColor(1);
    imgui.SameLine();

    -- Draw the MP bar
    local mpStartX, mpStartY; 
    if (memInfo.inzone) then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + settings.barSpacing);
        mpStartX, mpStartY = imgui.GetCursorScreenPos();
        imgui.PushStyleColor(ImGuiCol_PlotHistogram, {.9, 1, .5, 1});
        imgui.ProgressBar(memInfo.mpp, {  settings.mpBarWidth, settings.barHeight }, '');
        imgui.PopStyleColor(1);
        imgui.SameLine();
    end

    -- Draw the TP bar
    local tpStartX, tpStartY;
    if (memInfo.inzone) then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + settings.barSpacing);
        tpStartX, tpStartY = imgui.GetCursorScreenPos();
        if (memInfo.tp > 1000) then
            imgui.PushStyleColor(ImGuiCol_PlotHistogram, {.2, .4, 1, 1});
        else
            imgui.PushStyleColor(ImGuiCol_PlotHistogram, {.3, .7, 1, 1});
        end
        imgui.ProgressBar(memInfo.tp / 1000, { settings.tpBarWidth, settings.barHeight }, '');
        imgui.PopStyleColor(1);
        if (memInfo.tp > 1000) then
            imgui.SameLine();
            imgui.SetCursorPosX(tpStartX);
            imgui.PushStyleColor(ImGuiCol_PlotHistogram, {.3, .7, 1, 1});
            imgui.ProgressBar((memInfo.tp - 1000) / 2000, { settings.tpBarWidth, settings.barHeight * 3/5 }, '');
            imgui.PopStyleColor(1);
        end
    end

    -- Draw the leader icon
    if (memInfo.leader == true) then
        draw_circle({hpStartX + settings.leaderDotRadius/2, hpStartY + settings.leaderDotRadius/2}, settings.leaderDotRadius, {1, 1, 0, 1}, settings.leaderDotRadius * 3, true);
     end

    -- Update the hp text
    memberText[memIdx].hp:SetColor(hpNameColor);
    memberText[memIdx].hp:SetPositionX(hpStartX + settings.hpBarWidth + settings.hpTextOffsetX);
    memberText[memIdx].hp:SetPositionY(hpStartY + settings.barHeight + settings.hpTextOffsetY);
    memberText[memIdx].hp:SetText(tostring(memInfo.hp));

    -- Update the mp text
    if (memInfo.mpp >= 1) then 
        memberText[memIdx].mp:SetColor(0xFFCFFBCF);
    else
        memberText[memIdx].mp:SetColor(0xFFFFFFFF);
    end
    memberText[memIdx].mp:SetPositionX(mpStartX + settings.mpBarWidth + settings.mpTextOffsetX);
    memberText[memIdx].mp:SetPositionY(mpStartY + settings.barHeight + settings.mpTextOffsetY);
    memberText[memIdx].mp:SetText(tostring(memInfo.mp));

    -- Update the tp text
    if (memInfo.tp > 1000) then 
        memberText[memIdx].tp:SetColor(0xFF5b97cf);
    else
        memberText[memIdx].tp:SetColor(0xFFD1EDF2);
    end	
    memberText[memIdx].tp:SetPositionX(tpStartX + settings.tpBarWidth + settings.tpTextOffsetX);
    memberText[memIdx].tp:SetPositionY(tpStartY + settings.barHeight + settings.tpTextOffsetY);
    memberText[memIdx].tp:SetText(tostring(memInfo.tp));

    -- Update the name text
    memberText[memIdx].name:SetColor(0xFFFFFFFF);
    memberText[memIdx].name:SetPositionX(hpStartX + settings.nameTextOffsetX);
    memberText[memIdx].name:SetPositionY(hpStartY - settings.barHeight + settings.nameTextOffsetY);
    memberText[memIdx].name:SetText(tostring(memInfo.name));

    if (memInfo.targeted == true) then
        selectionPrim.visible = true;
        selectionPrim.position_x = hpStartX - settings.cursorPaddingX1;
        selectionPrim.position_y = hpStartY - memberText[memIdx].name:GetFontHeight() - settings.cursorPaddingY1;
        selectionPrim.scale_x = (allBarsLengths + settings.cursorPaddingX1 + settings.cursorPaddingX2) / 276;
        selectionPrim.scale_y = (memberText[memIdx].hp:GetFontHeight() + (memberText[memIdx].name:GetFontHeight()) + settings.barHeight + settings.cursorPaddingY1 + settings.cursorPaddingY2) / 58;
        partyTargeted = true;
    end

    imgui.Dummy({0, settings.entrySpacing + memberText[memIdx].hp:GetFontHeight() + memberText[memIdx].name:GetFontHeight()});
end

partyList.DrawWindow = function(settings, userSettings)

    -- Obtain the player entity..
    local party = AshitaCore:GetMemoryManager():GetParty();
    local player = AshitaCore:GetMemoryManager():GetPlayer();
	
	if (party == nil or player == nil) then
		UpdateTextVisibility(false);
		return;
	end
	local currJob = player:GetMainJob();
    if (player.isZoning or currJob == 0 or (not userSettings.showPartyListWhenSolo and party:GetMemberIsActive(1) == 0)) then
		UpdateTextVisibility(false);
        return;
	end

    if (imgui.Begin('PartyList', true, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav, ImGuiWindowFlags_NoBackground))) then
        if (fullMenuSizeX ~= nil and fullMenuSizeY ~= nil) then
            backgroundPrim.visible = true;
            local imguiPosX, imguiPosY = imgui.GetWindowPos();
            backgroundPrim.position_x = imguiPosX - settings.backgroundPaddingX1;
            backgroundPrim.position_y = imguiPosY - settings.backgroundPaddingY1;
            backgroundPrim.scale_x = (fullMenuSizeX + settings.backgroundPaddingX1 + settings.backgroundPaddingX2) / 284;
            backgroundPrim.scale_y = (fullMenuSizeY - settings.entrySpacing + settings.backgroundPaddingY1 + settings.backgroundPaddingY2) / 368;
        end
        partyTargeted = false;
        for i = 0, 5 do
            DrawMember(i, settings, userSettings);
        end
        if (partyTargeted == false) then
            selectionPrim.visible = false;
        end
        UpdateTextVisibility(true);
    end

    fullMenuSizeX, fullMenuSizeY = imgui.GetWindowSize();
	imgui.End();
end


partyList.Initialize = function(settings)
    -- Initialize all our font objects we need
    for i = 0, 5 do
        memberText[i] = {};
        memberText[i].name = fonts.new(settings.name_font_settings);
        memberText[i].hp = fonts.new(settings.hp_font_settings);
        memberText[i].mp = fonts.new(settings.mp_font_settings);
        memberText[i].tp = fonts.new(settings.tp_font_settings);
    end
    backgroundPrim = primitives:new(settings.primData);
    backgroundPrim.color = 0xFFFFFFFF;
    backgroundPrim.texture = string.format('%s/assets/plist_bg.png', addon.path);
    backgroundPrim.visible = false;

    selectionPrim = primitives.new(settings.primData);
    selectionPrim.color = 0xFFFFFFFF;
    selectionPrim.texture = string.format('%s/assets/cursor.png', addon.path);
    selectionPrim.visible = false;
end

partyList.UpdateFonts = function(settings)
    -- Initialize all our font objects we need
    for i = 0, 5 do
        memberText[i].name:SetFontHeight(settings.name_font_settings.font_height);
        memberText[i].hp:SetFontHeight(settings.hp_font_settings.font_height);
        memberText[i].mp:SetFontHeight(settings.mp_font_settings.font_height);
        memberText[i].tp:SetFontHeight(settings.tp_font_settings.font_height);
    end
end

partyList.SetHidden = function(hidden)
	if (hidden == true) then
        UpdateTextVisibility(false);
        backgroundPrim.visible = false;
	end
end

return partyList;