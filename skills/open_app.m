function result = open_app(params)
% open_app - 打开指定应用程序
%   params.app: 应用名称

    % 应用清单：名称 -> 路径
    appList = struct();
    appList.edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
    appList.kugou = 'D:\software\kugou\KGMusic\KuGou.exe';
    appList.tencent_meeting = 'D:\software\tengxunhuiyi\WeMeet\WeMeetApp.exe';
    appList.wps = 'D:\software\wps\WPS Office\ksolaunch.exe';
    appList.pycharm = 'D:\software\Pycharm\PyCharm 2025.2.1.1\bin\pycharm64.exe';
    appList.matlab = 'D:\software\matlab\bin\matlab.exe';
    appList.steam = 'D:\software\steam\Steam.exe';
    appList.yuanshen = 'D:\software\yuanshen\miHoYo Launcher\launcher.exe';
    appList.huorong = 'D:\software\火绒\Huorong\Sysdiag\bin\HipsMain.exe';
    appList.notepad = 'C:\Windows\System32\notepad.exe';

    if ~isfield(params, 'app')
        % 返回可用应用列表
        names = fieldnames(appList);
        result = sprintf('请指定要打开的应用。可用应用: %s', strjoin(names, ', '));
        return;
    end

    appName = lower(params.app);

    if ~isfield(appList, appName)
        names = fieldnames(appList);
        result = sprintf('未找到应用 "%s"。可用应用: %s', params.app, strjoin(names, ', '));
        return;
    end

    appPath = appList.(appName);

    if ~exist(appPath, 'file')
        result = sprintf('应用路径不存在: %s', appPath);
        return;
    end

    try
        system(sprintf('start "" "%s"', appPath));
        result = sprintf('已成功启动应用: %s', params.app);
    catch ME
        result = sprintf('启动应用失败: %s', ME.message);
    end
end
