function SPT()
    % Signal Processing Tool - 整合的信号处理工具启动器
    % 直接调用A、B、C三个模块的功能
    
    % 创建主界面
    main_fig = figure('Name', 'Signal Processing Tool', 'Position', [200, 200, 600, 500], ...
                      'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off', ...
                      'Color', [0.94 0.94 0.94]);
    
    % 创建主界面
    create_main_interface();
    
    function create_main_interface()
        % 清空当前界面
        clf(main_fig);
        
        % 主标题
        uicontrol('Style', 'text', 'String', 'Signal Processing Tool (SPT)', ...
                  'Position', [50, 440, 500, 40], 'FontSize', 20, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'center', 'BackgroundColor', [0.94 0.94 0.94]);
        
        % 副标题
        uicontrol('Style', 'text', 'String', 'Integrated Wave Data Processing Suite', ...
                  'Position', [50, 410, 500, 20], 'FontSize', 12, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.6 0.6 0.6], ...
                  'BackgroundColor', [0.94 0.94 0.94]);
        
        % 模块选择标题
        uicontrol('Style', 'text', 'String', 'Select Processing Module:', ...
                  'Position', [50, 370, 500, 25], 'FontSize', 14, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'center', 'BackgroundColor', [0.94 0.94 0.94]);
        
        % 模块A按钮
        uicontrol('Style', 'pushbutton', 'String', 'Module A - Single Point Processing', ...
                  'Position', [100, 310, 400, 50], 'FontSize', 13, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @open_module_A);
        
        % 模块A说明
        uicontrol('Style', 'text', 'String', 'Process single TXT files and perform signal comparison analysis', ...
                  'Position', [100, 290, 400, 20], 'FontSize', 10, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.5 0.5 0.5], ...
                  'BackgroundColor', [0.94 0.94 0.94]);
        
        % 模块B按钮
        uicontrol('Style', 'pushbutton', 'String', 'Module B - B-Scan Processing', ...
                  'Position', [100, 240, 400, 50], 'FontSize', 13, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @open_module_B);
        
        % 模块B说明
        uicontrol('Style', 'text', 'String', 'Process multiple TXT files for B-scan time domain signal analysis', ...
                  'Position', [100, 220, 400, 20], 'FontSize', 10, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.5 0.5 0.5], ...
                  'BackgroundColor', [0.94 0.94 0.94]);
        
        % 模块C按钮
        uicontrol('Style', 'pushbutton', 'String', 'Module C - Wave Field Processing', ...
                  'Position', [100, 170, 400, 50], 'FontSize', 13, 'FontWeight', 'bold', ...
                  'BackgroundColor', [1.0 0.9 0.8], 'Callback', @open_module_C);
        
        % 模块C说明
        uicontrol('Style', 'text', 'String', 'Process MAT files for wave field analysis and imaging', ...
                  'Position', [100, 150, 400, 20], 'FontSize', 10, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.5 0.5 0.5], ...
                  'BackgroundColor', [0.94 0.94 0.94]);
        
        % 底部信息
        uicontrol('Style', 'text', 'String', 'Version 1.0 - Comprehensive Signal Processing Platform', ...
                  'Position', [50, 100, 500, 15], 'FontSize', 9, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.6 0.6 0.6], ...
                  'BackgroundColor', [0.94 0.94 0.94]);
        
        % 退出按钮
        uicontrol('Style', 'pushbutton', 'String', 'Exit', ...
                  'Position', [250, 50, 100, 30], 'FontSize', 11, ...
                  'BackgroundColor', [0.9 0.9 0.9], 'Callback', @close_application);
    end
    
    function open_module_A(~, ~)
        % 直接调用模块A
        try
            addpath(fullfile(fileparts(mfilename('fullpath')), 'A'));
            ReadA();
        catch ME
            msgbox(['Error opening Module A: ' ME.message], 'Error', 'error');
        end
    end
    
    function open_module_B(~, ~)
        % 直接调用模块B
        try
            addpath(fullfile(fileparts(mfilename('fullpath')), 'B'));
            ReadB();
        catch ME
            msgbox(['Error opening Module B: ' ME.message], 'Error', 'error');
        end
    end
    
    function open_module_C(~, ~)
        % 直接调用模块C
        try
            addpath(fullfile(fileparts(mfilename('fullpath')), 'C'));
            ReadC();
        catch ME
            msgbox(['Error opening Module C: ' ME.message], 'Error', 'error');
        end
    end
    
    function close_application(~, ~)
        % 关闭应用程序
        choice = questdlg('Are you sure you want to exit?', 'Exit SPT', 'Yes', 'No', 'No');
        if strcmp(choice, 'Yes')
            close(main_fig);
        end
    end
end