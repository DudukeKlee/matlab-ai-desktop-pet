% main.m - 桌面宠物主入口

% 项目根目录（基于本文件位置，避免依赖 pwd）
projectRoot = fileparts(mfilename('fullpath'));

addpath(genpath(fullfile(projectRoot, 'src')));
addpath(fullfile(projectRoot, 'skills'));

% 清理上次运行残留的 timer
oldTimers = timerfindall();
if ~isempty(oldTimers)
    stop(oldTimers(strcmp(get(oldTimers, 'Running'), 'on')));
    delete(oldTimers);
end

config = loadConfig();

% handle 对象共享数据
appData = AppData();
appData.config = config;

createMainWindow(appData);

disp('桌面宠物已启动！');
