function switchImage(appData, imageName, imageType)

    config = appData.config;

    fileName = '';
    if ~isempty(config.images) && numel(config.images) > 0
        for i = 1:numel(config.images)
            if strcmp(config.images(i).name, imageName) && strcmp(config.images(i).type, imageType)
                fileName = config.images(i).fileName;
                break;
            end
        end
    end

    if isempty(fileName)
        return;
    end

    imgPath = fullfile(getProjectRoot(), 'images', imageType, fileName);

    if ~exist(imgPath, 'file')
        warning('图片文件不存在: %s', imgPath);
        return;
    end

    if strcmp(imageType, 'character')
        if ~isempty(appData.characterImg) && isvalid(appData.characterImg)
            appData.characterImg.ImageSource = imgPath;
            if ~isempty(appData.onLayoutUpdate) && isa(appData.onLayoutUpdate, 'function_handle')
                try, appData.onLayoutUpdate(); catch, end
            end
        end
    elseif strcmp(imageType, 'status')
        if ~isempty(appData.statusImg) && isvalid(appData.statusImg)
            % 先停止之前的 GIF 动画
            stopGifAnimation(appData);

            [~, ~, ext] = fileparts(fileName);
            if strcmpi(ext, '.gif')
                % GIF 文件：读取所有帧，启动动画
                startGifAnimation(appData, imgPath);
            else
                % 普通图片：直接显示
                appData.statusImg.ImageSource = imgPath;
                appData.statusImg.Visible = 'on';
            end
        end
    end
end

function startGifAnimation(appData, gifPath)
% startGifAnimation - 读取 GIF 所有帧并启动定时器循环播放

    try
        info = imfinfo(gifPath);
        numFrames = numel(info);

        if numFrames <= 1
            % 只有一帧，当普通图片处理
            appData.statusImg.ImageSource = gifPath;
            appData.statusImg.Visible = 'on';
            return;
        end

        % 读取所有帧，保存为临时 PNG 文件
        tempDir = fullfile(getProjectRoot(), 'temp', 'gif_frames');
        if ~exist(tempDir, 'dir')
            mkdir(tempDir);
        end

        % 清理旧帧文件
        oldFiles = dir(fullfile(tempDir, 'frame_*.png'));
        for i = 1:numel(oldFiles)
            delete(fullfile(tempDir, oldFiles(i).name));
        end

        framePaths = {};
        for i = 1:numFrames
            [frame, cmap] = imread(gifPath, i);
            if ~isempty(cmap)
                frame = ind2rgb(frame, cmap);
            end
            framePath = fullfile(tempDir, sprintf('frame_%03d.png', i));
            imwrite(frame, framePath);
            framePaths{end+1} = framePath; %#ok<AGROW>
        end

        appData.gifFrames = framePaths;
        appData.gifFrameIndex = 1;

        % 获取帧延迟（秒），默认 0.1 秒
        if isfield(info(1), 'DelayTime') && info(1).DelayTime > 0
            delay = info(1).DelayTime / 100;  % GIF DelayTime 单位是 1/100 秒
            if delay < 0.02
                delay = 0.02;  % 最小间隔
            end
        else
            delay = 0.1;
        end

        % 显示第一帧
        appData.statusImg.ImageSource = framePaths{1};
        appData.statusImg.Visible = 'on';

        % 启动定时器
        appData.gifTimer = timer('ExecutionMode', 'fixedRate', ...
            'Period', delay, ...
            'TimerFcn', @(~,~) nextGifFrame(appData));
        start(appData.gifTimer);

    catch ME
        warning('GIF 加载失败: %s', ME.message);
        appData.statusImg.ImageSource = gifPath;
        appData.statusImg.Visible = 'on';
    end
end

function nextGifFrame(appData)
% nextGifFrame - 切换到下一帧

    if isempty(appData.gifFrames)
        return;
    end

    appData.gifFrameIndex = appData.gifFrameIndex + 1;
    if appData.gifFrameIndex > numel(appData.gifFrames)
        appData.gifFrameIndex = 1;
    end

    if ~isempty(appData.statusImg) && isvalid(appData.statusImg)
        appData.statusImg.ImageSource = appData.gifFrames{appData.gifFrameIndex};
    end
end

function stopGifAnimation(appData)
% stopGifAnimation - 停止 GIF 动画

    if ~isempty(appData.gifTimer) && isvalid(appData.gifTimer)
        if strcmp(appData.gifTimer.Running, 'on')
            stop(appData.gifTimer);
        end
        delete(appData.gifTimer);
        appData.gifTimer = [];
    end
    appData.gifFrames = {};
    appData.gifFrameIndex = 1;
end
