function ReadB()
    % B扫主界面 - 多文件时域信号处理工具
    % 负责协调各个功能模块
    
    % 创建主界面
    main_fig = figure('Name', 'B-Scan Signal Processing Tool', 'Position', [100, 100, 500, 450], ...
                      'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');
    
    % 全局变量
    app_data = struct();
    app_data.selected_folder = '';
    app_data.data_xyt = [];
    app_data.data_time = [];
    app_data.fs = 0;
    app_data.file_count = 0;
    
    % 创建主界面
    create_main_ui();
    
    function create_main_ui()
        clf(main_fig);
        
        % 标题
        uicontrol('Style', 'text', 'String', 'Signal Processing Tool', ...
                  'Position', [50, 400, 400, 30], 'FontSize', 16, 'FontWeight', 'bold');
        
        % Step 1 区域
        uicontrol('Style', 'text', 'String', 'Step 1: Load and Process TXT Files', ...
                  'Position', [90, 350, 300, 25], 'FontSize', 14, 'FontWeight', 'bold');
        
        % 文件夹选择按钮
        uicontrol('Style', 'pushbutton', 'String', 'Browse Folder', ...
                  'Position', [150, 290, 200, 40], 'FontSize', 12, ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @browse_and_process_folder);
        
        % 文件夹选择说明
        uicontrol('Style', 'text', 'String', 'Select folder containing numbered TXT files (1.txt, 2.txt, ...)', ...
                  'Position', [50, 260, 400, 20], 'FontSize', 10, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.5 0.5 0.5]);
        
        % 显示处理状态
        app_data.status_text = uicontrol('Style', 'text', 'String', 'Ready to process files...', ...
                                        'Position', [50, 200, 400, 50], 'HorizontalAlignment', 'center', ...
                                        'BackgroundColor', [0.95 0.95 0.95], 'FontSize', 10);
        
        % Step 2 区域
        uicontrol('Style', 'text', 'String', 'Step 2: B-Scan Analysis', ...
                  'Position', [90, 150, 300, 40], 'FontSize', 14, 'FontWeight', 'bold');
        
        % Step 2 按钮
        uicontrol('Style', 'pushbutton', 'String', 'Analysis', ...
                  'Position', [150, 105, 200, 40], 'FontSize', 11, ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @open_analysis);
        
        % 已处理文件计数
        if app_data.file_count > 0
            uicontrol('Style', 'text', 'String', sprintf('Processed Files: %d', app_data.file_count), ...
                      'Position', [150, 65, 200, 20], 'HorizontalAlignment', 'center', ...
                      'FontWeight', 'bold', 'ForegroundColor', [0.2 0.6 0.2]);
        end
        
        % 底部说明
        uicontrol('Style', 'text', 'String', 'B-Scan processing tool for multiple TXT time domain signals', ...
                  'Position', [50, 20, 400, 15], 'FontSize', 9, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.6 0.6 0.6]);
    end
    
    function browse_and_process_folder(~, ~)
        folder = uigetdir('', 'Select folder containing numbered TXT files');
        
        if isequal(folder, 0)
            return;
        end
        
        app_data.selected_folder = folder;
        
        % 更新状态显示
        set(app_data.status_text, 'String', sprintf('Processing folder:\n%s', folder));
        drawnow;
        
        % 调用数据处理模块
        [success, processed_data] = b_scan_processor.process_folder(folder);
        
        if success
            app_data.data_xyt = processed_data.data_xyt;
            app_data.data_time = processed_data.data_time;
            app_data.fs = processed_data.fs;
            app_data.file_count = processed_data.file_count;
            
            % 更新状态
            status_msg = sprintf('Processing complete:\n%d files processed successfully', app_data.file_count);
            set(app_data.status_text, 'String', status_msg);
            
            % 询问是否立即进行分析
            choice = questdlg(sprintf('%d files processed successfully! Do you want to start B-Scan analysis now?', app_data.file_count), ...
                             'Analysis Option', 'Yes', 'No', 'Yes');
            if strcmp(choice, 'Yes')
                open_analysis();
                return;
            end
        else
            set(app_data.status_text, 'String', 'Processing failed. Please check the folder and try again.');
        end
        
        create_main_ui();
    end
    
    function open_analysis(~, ~)
        if isempty(app_data.data_xyt)
            % 尝试从选择的文件夹加载已处理的数据
            if ~isempty(app_data.selected_folder)
                data_file = fullfile(app_data.selected_folder, 'data.mat');
                if exist(data_file, 'file')
                    try
                        loaded = load(data_file);
                        app_data.data_xyt = loaded.data_xyt;
                        app_data.data_time = loaded.data_time;
                        app_data.fs = loaded.fs;
                        app_data.file_count = size(loaded.data_xyt, 2);
                    catch ME
                        msgbox(['Error loading processed data: ' ME.message], 'Error', 'error');
                        return;
                    end
                else
                    msgbox('Please process files first!', 'Error', 'error');
                    return;
                end
            else
                msgbox('Please select folder and process files first!', 'Error', 'error');
                return;
            end
        end
        
        % 调用新的B扫分析GUI，传递已处理的数据
        b_analysis_gui(app_data.data_xyt, app_data.data_time, app_data.fs);
    end
end
