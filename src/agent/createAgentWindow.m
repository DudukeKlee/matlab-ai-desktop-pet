function createAgentWindow(appData)
% createAgentWindow - 创建 B 的窗口

    agentB = appData.config.agentB;

    fig = uifigure('Name', sprintf('%s 助手', agentB.name), ...
        'Position', [1180 300 360 580], ...
        'Resize', 'on', 'AutoResizeChildren', 'off', ...
        'CloseRequestFcn', @(~,~) onAgentClose());
    appData.agentB_fig = fig;

    % 立绘
    charImg = uiimage(fig, 'Position', [80 280 200 200], ...
        'ImageSource', '', 'ScaleMethod', 'fit');
    appData.agentB_characterImg = charImg;

    % 状态图
    transparentImg = fullfile(getProjectRoot(), 'temp', 'transparent.png');
    if ~exist(transparentImg, 'file')
        tempDir = fullfile(getProjectRoot(), 'temp');
        if ~exist(tempDir, 'dir'), mkdir(tempDir); end
        img = zeros(1,1,3,'uint8');
        alpha = zeros(1,1,'uint8');
        imwrite(img, transparentImg, 'Alpha', alpha);
    end
    bStatusImg = uiimage(fig, 'Position', [0 0 30 30], ...
        'ImageSource', transparentImg, 'Visible', 'off', ...
        'ScaleMethod', 'fit');
    appData.agentB_statusImg = bStatusImg;

    % 状态图定时器
    appData.agentB_statusTimer = timer('ExecutionMode', 'singleShot', ...
        'TimerFcn', @(~,~) hideAgentStatus(appData), ...
        'StartDelay', appData.config.stateDuration);

    % 设默认立绘
    if ~isempty(agentB.defaultAgentImage)
        setAgentImageByName(appData, agentB.defaultAgentImage);
    end

    % 状态
    statusLabel = uilabel(fig, 'Position', [10 540 340 22], ...
        'Text', sprintf('任务: %s', truncate(appData.agentB_currentTask, 40)), ...
        'FontWeight', 'bold');
    appData.agentB_statusLabel = statusLabel;

    statusLabel2 = uilabel(fig, 'Position', [10 515 340 22], ...
        'Text', sprintf('模式: %s · 轮次: 0/%d', appData.agentB_mode, agentB.maxRounds));
    setappdata(fig, 'statusLabel2', statusLabel2);

    % 聊天区
    chatDisplay = uitextarea(fig, 'Position', [10 20 340 250], ...
        'Editable', 'off', 'Value', {sprintf('[%s 已启动]', agentB.name)});
    appData.agentB_chatDisplay = chatDisplay;

    function onAgentClose()
        if ~isempty(appData.agentB_statusTimer) && isvalid(appData.agentB_statusTimer)
            if strcmp(appData.agentB_statusTimer.Running, 'on')
                stop(appData.agentB_statusTimer);
            end
            delete(appData.agentB_statusTimer);
        end
        delete(fig);
        appData.agentB_fig = [];
    end
end

function out = truncate(s, n)
    if ~ischar(s) && ~isstring(s)
        s = char(string(s));
    end
    s = char(s);
    if numel(s) > n
        out = [s(1:n) '...'];
    else
        out = s;
    end
end

function setAgentImageByName(appData, imgName)
    if isempty(appData.config.images), return; end
    for i = 1:numel(appData.config.images)
        if strcmp(appData.config.images(i).name, imgName) && ...
           strcmp(appData.config.images(i).type, 'agent')
            imgPath = fullfile(getProjectRoot(), 'images', 'agent', ...
                appData.config.images(i).fileName);
            if exist(imgPath, 'file')
                appData.agentB_characterImg.ImageSource = imgPath;
            end
            return;
        end
    end
end

function hideAgentStatus(appData)
    if ~isempty(appData.agentB_statusImg) && isvalid(appData.agentB_statusImg)
        appData.agentB_statusImg.Visible = 'off';
    end
end
