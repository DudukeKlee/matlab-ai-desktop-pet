function saveConfig(config)
% saveConfig - 将配置保存到 config/settings.json

    configDir = fullfile(getProjectRoot(), 'config');
    if ~exist(configDir, 'dir')
        mkdir(configDir);
    end

    filePath = fullfile(configDir, 'settings.json');
    jsonStr = jsonencode(config, 'PrettyPrint', true);

    fid = fopen(filePath, 'w', 'n', 'UTF-8');
    if fid == -1
        error('无法写入配置文件: %s', filePath);
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);
end
