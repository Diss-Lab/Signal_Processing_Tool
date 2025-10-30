function ReadC()
    % 主界面 - 波场数据处理工具
    % 负责协调各个功能模块
    
    % 创建主界面
    main_fig = figure('Name', 'Wave Data Processing Tool', 'Position', [100, 100, 500, 450], ...
                      'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');
    
    % 全局变量
    app_data = struct();
    app_data.selected_file = '';
    app_data.data_xyt = [];
    app_data.data_time = [];
    app_data.fs = 0;
    app_data.grid_params = struct('n', 51, 'm', 51);
    
    % 创建主界面
    create_main_ui();
    
    function create_main_ui()
        clf(main_fig);
        
        % 标题
        uicontrol('Style', 'text', 'String', 'Signal Processing Tool', ...
                  'Position', [50, 400, 400, 30], 'FontSize', 16, 'FontWeight', 'bold');
        
        % Step 1 区域
        uicontrol('Style', 'text', 'String', 'Step 1: Load and Process Signal Data', ...
                  'Position', [90, 350, 300, 25], 'FontSize', 14, 'FontWeight', 'bold');
        
        uicontrol('Style', 'pushbutton', 'String', 'Browse MAT File', ...
                  'Position', [150, 290, 200, 40], 'BackgroundColor', [0.8 0.9 1.0], ...
                  'FontSize', 11, 'Callback', @select_file);
        
        % 显示选择的文件
        app_data.file_text = uicontrol('Style', 'text', 'String', 'No file selected', ...
                                      'Position', [50, 260, 400, 25], 'HorizontalAlignment', 'center', ...
                                      'BackgroundColor', [0.95 0.95 0.95]);
        
        % 网格尺寸设置 - 居中对称显示
        uicontrol('Style', 'text', 'String', 'Grid Width (n):', ...
                  'Position', [80, 225, 100, 20]);
        app_data.n_edit = uicontrol('Style', 'edit', 'String', '51', ...
                                   'Position', [180, 225, 60, 25]);
        
        uicontrol('Style', 'text', 'String', 'Grid Height (m):', ...
                  'Position', [260, 225, 100, 20]);
        app_data.m_edit = uicontrol('Style', 'edit', 'String', '51', ...
                                   'Position', [360, 225, 60, 25]);
        
        % 处理按钮
        uicontrol('Style', 'pushbutton', 'String', 'Process', ...
                  'Position', [150, 180, 200, 40], 'FontSize', 11, ...
                  'BackgroundColor', [0.9 1.0 0.8], 'Callback', @process_data);
        
        % Step 2 区域
        uicontrol('Style', 'text', 'String', 'Step 2: Wave Field Analysis', ...
                  'Position', [110, 130, 250, 25], 'FontSize', 14, 'FontWeight', 'bold');
        
        uicontrol('Style', 'pushbutton', 'String', 'Analysis', ...
                  'Position', [150, 80, 200, 40], 'FontSize', 11, ...
                  'BackgroundColor', [1.0 0.9 0.8], 'Callback', @open_analysis);
    end
    
    function select_file(~, ~)
        [filename, pathname] = uigetfile('*.mat', 'Select MAT file for processing');
        if filename ~= 0
            app_data.selected_file = fullfile(pathname, filename);
            set(app_data.file_text, 'String', ['Selected: ' filename]);
        end
    end
    
    function process_data(~, ~)
        if isempty(app_data.selected_file)
            msgbox('Please select a MAT file first!', 'Error', 'error');
            return;
        end
        
        % 获取网格参数
        app_data.grid_params.n = str2double(get(app_data.n_edit, 'String'));
        app_data.grid_params.m = str2double(get(app_data.m_edit, 'String'));
        
        if isnan(app_data.grid_params.n) || isnan(app_data.grid_params.m) || ...
           app_data.grid_params.n <= 0 || app_data.grid_params.m <= 0
            msgbox('Please enter valid grid dimensions!', 'Error', 'error');
            return;
        end
        
        % 调用数据处理模块
        [success, processed_data] = wave_data_processor.process_single_mat_file(app_data.selected_file, app_data.grid_params);
        
        if success
            app_data.data_xyt = processed_data.data_xyt;
            app_data.data_time = processed_data.data_time;
            app_data.fs = processed_data.fs;
            
            msgbox('Data processed successfully!', 'Success');
            
            % 询问是否立即进行分析
            choice = questdlg('Data processed successfully! Do you want to start analysis now?', ...
                             'Analysis Option', 'Yes', 'No', 'Yes');
            if strcmp(choice, 'Yes')
                open_analysis();
            end
        end
    end
    
    function open_analysis(~, ~)
        if isempty(app_data.data_xyt)
            % 尝试加载已处理的数据
            if ~isempty(app_data.selected_file)
                [filepath, ~, ~] = fileparts(app_data.selected_file);
                data_file = fullfile(filepath, 'data.mat');
                if exist(data_file, 'file')
                    try
                        loaded = load(data_file);
                        app_data.data_xyt = loaded.data_xyt;
                        app_data.data_time = loaded.data_time;
                        if isfield(loaded, 'fs')
                            app_data.fs = loaded.fs;
                        else
                            app_data.fs = 1 / (app_data.data_time(2) - app_data.data_time(1));
                        end
                    catch ME
                        msgbox(['Error loading processed data: ' ME.message], 'Error', 'error');
                        return;
                    end
                else
                    msgbox('Please process data first!', 'Error', 'error');
                    return;
                end
            else
                msgbox('Please select MAT file and process data first!', 'Error', 'error');
                return;
            end
        end
        
        % 调用波场分析模块
        wave_field_analyzer.create_analysis_ui(app_data.data_xyt, app_data.data_time, app_data.fs);
    end
end
