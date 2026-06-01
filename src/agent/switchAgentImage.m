function switchAgentImage(appData, imgName)
% 切换 B 的立绘
    if isempty(appData.agentB_characterImg) || ~isvalid(appData.agentB_characterImg)
        return;
    end
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
