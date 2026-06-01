function rootPath = getProjectRoot()
% getProjectRoot - 获取项目根目录路径
%   通过查找 config 文件夹来确定项目根目录

    % 从当前文件位置开始向上查找
    currentDir = fileparts(mfilename('fullpath'));
    
    % 向上逐级查找，直到找到包含 config 文件夹的目录
    searchDir = currentDir;
    for i = 1:10  % 最多向上找10层
        if exist(fullfile(searchDir, 'config'), 'dir') && ...
           exist(fullfile(searchDir, 'skills'), 'dir')
            rootPath = searchDir;
            return;
        end
        parentDir = fileparts(searchDir);
        if strcmp(parentDir, searchDir)
            break;  % 已到根目录
        end
        searchDir = parentDir;
    end
    
    % 如果找不到，用 pwd 作为备选
    rootPath = pwd;
    warning('未能自动定位项目根目录，使用当前工作目录: %s', rootPath);
end
