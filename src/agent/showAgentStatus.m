function showAgentStatus(appData, statusName, angleDeg)
% showAgentStatus - 在 B 的窗口显示状态图

    if isempty(appData.agentB_statusImg) || ~isvalid(appData.agentB_statusImg)
        return;
    end
    if isempty(appData.agentB_characterImg) || ~isvalid(appData.agentB_characterImg)
        return;
    end

    % 从 A 的 config 里查找 status 图片路径
    imgPath = '';
    config = appData.config;
    if ~isempty(config.images) && numel(config.images) > 0
        for i = 1:numel(config.images)
            if strcmp(config.images(i).type, 'status') && ...
               strcmp(config.images(i).name, statusName)
                imgPath = fullfile(getProjectRoot(), 'images', 'status', ...
                    config.images(i).fileName);
                break;
            end
        end
    end

    if isempty(imgPath) || ~exist(imgPath, 'file')
        return;
    end

    appData.agentB_statusImg.ImageSource = imgPath;
    appData.agentB_statusImg.Visible = 'on';
    appData.agentB_statusImg.UserData = angleDeg;
    placeStatusByAngle(appData.agentB_characterImg, appData.agentB_statusImg, 200);

    % 启动定时器
    if ~isempty(appData.agentB_statusTimer) && isvalid(appData.agentB_statusTimer)
        if strcmp(appData.agentB_statusTimer.Running, 'on')
            stop(appData.agentB_statusTimer);
        end
        appData.agentB_statusTimer.StartDelay = appData.config.stateDuration;
        start(appData.agentB_statusTimer);
    end
end
