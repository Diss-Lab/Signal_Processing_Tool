function ReadC()
    % 主界面 - 波场数据处理工具
    % 负责协调各个功能模块
    
    % 创建主界面
    main_fig = figure('Name', 'Wave Data Processing Tool', 'Position', [100, 100, 520, 500], ...
                      'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');
    
    % 全局变量
    app_data = struct();
    app_data.selected_file = '';
    app_data.data_xyt = [];
    app_data.data_time = [];
    app_data.fs = 0;
    app_data.grid_params = struct('n', 51, 'm', 51);
    app_data.file_format = ''; % 'processed' 或 'raw'
    app_data.data_processed = false;
    
    % 创建主界面
    create_main_ui();
    
    function create_main_ui()
        clf(main_fig);
        
        % 标题
        uicontrol('Style', 'text', 'String', 'Wave Data Processing Tool', ...
                  'Position', [50, 450, 420, 30], 'FontSize', 16, 'FontWeight', 'bold');
        
        % Step 1 区域
        uicontrol('Style', 'text', 'String', 'Step 1: Load MAT File', ...
                  'Position', [90, 410, 300, 25], 'FontSize', 14, 'FontWeight', 'bold');
        
        uicontrol('Style', 'pushbutton', 'String', 'Browse MAT File', ...
                  'Position', [160, 370, 200, 35], 'BackgroundColor', [0.8 0.9 1.0], ...
                  'FontSize', 11, 'Callback', @select_file);
        
        % 显示选择的文件
        app_data.file_text = uicontrol('Style', 'text', 'String', 'No file selected', ...
                                      'Position', [50, 340, 420, 20], 'HorizontalAlignment', 'center', ...
                                      'BackgroundColor', [0.95 0.95 0.95], 'FontSize', 10);
        
        % 显示文件格式
        app_data.format_text = uicontrol('Style', 'text', 'String', '', ...
                                        'Position', [50, 315, 420, 20], 'HorizontalAlignment', 'center', ...
                                        'FontSize', 10, 'FontWeight', 'bold');
        
        % 网格尺寸设置区域（仅对原始数据格式显示）
        app_data.grid_panel = uipanel('Position', [0.1 0.45 0.8 0.15], 'Title', 'Grid Parameters (for raw data)', ...
                                     'FontSize', 12, 'FontWeight', 'bold', 'Visible', 'off');
        
        % 网格尺寸设置控件
        uicontrol('Parent', app_data.grid_panel, 'Style', 'text', 'String', 'Grid Width (n):', ...
                  'Units', 'normalized', 'Position', [0.1 0.4 0.25 0.4]);
        app_data.n_edit = uicontrol('Parent', app_data.grid_panel, 'Style', 'edit', 'String', '51', ...
                                   'Units', 'normalized', 'Position', [0.35 0.4 0.15 0.4]);
        
        uicontrol('Parent', app_data.grid_panel, 'Style', 'text', 'String', 'Grid Height (m):', ...
                  'Units', 'normalized', 'Position', [0.55 0.4 0.25 0.4]);
        app_data.m_edit = uicontrol('Parent', app_data.grid_panel, 'Style', 'edit', 'String', '51', ...
                                   'Units', 'normalized', 'Position', [0.8 0.4 0.15 0.4]);
        
        % 处理按钮
        app_data.process_btn = uicontrol('Style', 'pushbutton', 'String', 'Process Data', ...
                                        'Position', [160, 200, 200, 35], 'FontSize', 11, ...
                                        'BackgroundColor', [0.9 1.0 0.8], 'Callback', @process_data, ...
                                        'Enable', 'off');
        
        % 状态显示
        app_data.status_text = uicontrol('Style', 'text', 'String', 'Please select a MAT file to begin', ...
                                        'Position', [50, 160, 420, 30], 'HorizontalAlignment', 'center', ...
                                        'BackgroundColor', [0.95 0.95 0.95], 'FontSize', 10);
        
        % Step 2 区域
        uicontrol('Style', 'text', 'String', 'Step 2: Wave Field Analysis', ...
                  'Position', [110, 120, 300, 25], 'FontSize', 14, 'FontWeight', 'bold');
        
        app_data.analysis_btn = uicontrol('Style', 'pushbutton', 'String', 'Start Analysis', ...
                                         'Position', [160, 80, 200, 35], 'FontSize', 11, ...
                                         'BackgroundColor', [1.0 0.9 0.8], 'Callback', @open_analysis, ...
                                         'Enable', 'off');
        
        % 数据状态显示
        if app_data.data_processed
            uicontrol('Style', 'text', 'String', 'Data Ready for Analysis', ...
                      'Position', [160, 45, 200, 20], 'HorizontalAlignment', 'center', ...
                      'FontWeight', 'bold', 'ForegroundColor', [0.2 0.6 0.2]);
        end
        
        % 底部说明
        uicontrol('Style', 'text', 'String', 'Supports: Raw data (x,y) and Processed data (data_xyt, data_time)', ...
                  'Position', [50, 15, 420, 15], 'FontSize', 9, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.6 0.6 0.6]);
    end
    
    function select_file(~, ~)
        [filename, pathname] = uigetfile('*.mat', 'Select MAT file for processing');
        if filename ~= 0
            app_data.selected_file = fullfile(pathname, filename);
            
            % 更新界面显示
            set(app_data.file_text, 'String', ['Selected: ' filename]);
            
            % 检测文件格式并更新界面
            detect_file_format();
        end
    end
    
    function detect_file_format()
        try
            % 加载MAT文件查看变量
            file_info = whos('-file', app_data.selected_file);
            var_names = {file_info.name};
            
            if ismember('data_xyt', var_names) && ismember('data_time', var_names)
                % 已处理的数据格式
                app_data.file_format = 'processed';
                set(app_data.format_text, 'String', 'Format: Processed Data (data_xyt, data_time)', ...
                    'ForegroundColor', [0.2 0.6 0.2]);
                
                % 直接加载已处理的数据
                load_processed_data();
                
                % 更新界面控件状态
                set(app_data.grid_panel, 'Visible', 'off');
                set(app_data.process_btn, 'Enable', 'off', 'String', 'Data Already Processed');
                set(app_data.analysis_btn, 'Enable', 'on');
                
            elseif ismember('x', var_names) && ismember('y', var_names)
                % 原始数据格式
                app_data.file_format = 'raw';
                set(app_data.format_text, 'String', 'Format: Raw Data (x, y) - Requires Processing', ...
                    'ForegroundColor', [0.8 0.6 0.2]);
                
                % 更新界面控件状态
                set(app_data.grid_panel, 'Visible', 'on');
                set(app_data.process_btn, 'Enable', 'on', 'String', 'Process Data');
                set(app_data.analysis_btn, 'Enable', 'off');
                set(app_data.status_text, 'String', 'Raw data detected. Please set grid parameters and process.');
                app_data.data_processed = false;
                
            else
                app_data.file_format = 'unknown';
                set(app_data.format_text, 'String', 'Format: Unknown - Expected (x,y) or (data_xyt,data_time)', ...
                    'ForegroundColor', [0.8 0.2 0.2]);
                
                % 更新界面控件状态
                set(app_data.grid_panel, 'Visible', 'off');
                set(app_data.process_btn, 'Enable', 'off', 'String', 'Invalid File Format');
                set(app_data.analysis_btn, 'Enable', 'off');
                set(app_data.status_text, 'String', 'Invalid file format. Please select a valid MAT file.');
                app_data.data_processed = false;
            end
            
        catch ME
            set(app_data.format_text, 'String', ['Error reading file: ' ME.message], ...
                'ForegroundColor', [0.8 0.2 0.2]);
            app_data.file_format = 'error';
            
            % 更新界面控件状态
            set(app_data.grid_panel, 'Visible', 'off');
            set(app_data.process_btn, 'Enable', 'off', 'String', 'File Read Error');
            set(app_data.analysis_btn, 'Enable', 'off');
            set(app_data.status_text, 'String', 'Error reading file. Please select another file.');
            app_data.data_processed = false;
        end
    end
    
    function load_processed_data()
        try
            loaded = load(app_data.selected_file);
            app_data.data_xyt = loaded.data_xyt;
            app_data.data_time = loaded.data_time;
            
            if isfield(loaded, 'fs')
                app_data.fs = loaded.fs;
            else
                app_data.fs = 1 / (app_data.data_time(2) - app_data.data_time(1));
            end
            
            app_data.data_processed = true;
            set(app_data.status_text, 'String', 'Processed data loaded successfully! Ready for analysis.');
            
        catch ME
            set(app_data.status_text, 'String', ['Error loading processed data: ' ME.message]);
            app_data.data_processed = false;
            set(app_data.analysis_btn, 'Enable', 'off');
        end
    end
    
    function process_data(~, ~)
        if isempty(app_data.selected_file) || ~strcmp(app_data.file_format, 'raw')
            msgbox('Please select a valid raw data MAT file first!', 'Error', 'error');
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
        
        % 更新状态
        set(app_data.status_text, 'String', 'Processing data... Please wait...');
        set(app_data.process_btn, 'Enable', 'off');
        drawnow;
        
        % 调用数据处理模块
        [success, processed_data] = wave_data_processor.process_single_mat_file(app_data.selected_file, app_data.grid_params);
        
        if success
            app_data.data_xyt = processed_data.data_xyt;
            app_data.data_time = processed_data.data_time;
            app_data.fs = processed_data.fs;
            app_data.data_processed = true;
            
            set(app_data.status_text, 'String', 'Data processed successfully! Ready for analysis.');
            set(app_data.process_btn, 'String', 'Processing Complete', 'BackgroundColor', [0.7 0.9 0.7]);
            set(app_data.analysis_btn, 'Enable', 'on');
            
            % 询问是否立即进行分析
            choice = questdlg('Data processed successfully! Do you want to start analysis now?', ...
                             'Analysis Option', 'Yes', 'No', 'Yes');
            if strcmp(choice, 'Yes')
                open_analysis();
            end
        else
            set(app_data.status_text, 'String', 'Processing failed. Please check the file and parameters.');
            set(app_data.process_btn, 'Enable', 'on');
        end
    end
    
    function open_analysis(~, ~)
        if ~app_data.data_processed || isempty(app_data.data_xyt)
            % 尝试从文件加载已处理的数据
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
                        app_data.data_processed = true;
                    catch ME
                        msgbox(['Error loading processed data: ' ME.message], 'Error', 'error');
                        return;
                    end
                else
                    msgbox('No processed data available. Please process data first!', 'Error', 'error');
                    return;
                end
            else
                msgbox('Please select and process data first!', 'Error', 'error');
                return;
            end
        end
        
        % 确保采样频率计算正确
        if app_data.fs == 0 || isnan(app_data.fs)
            if length(app_data.data_time) > 1
                dt = mean(diff(app_data.data_time));
                app_data.fs = 1 / dt;
            else
                msgbox('Cannot calculate sampling frequency from time data!', 'Error', 'error');
                return;
            end
        end
        
        % 验证数据完整性
        if isempty(app_data.data_xyt) || isempty(app_data.data_time)
            msgbox('Data is incomplete. Please reload and process data!', 'Error', 'error');
            return;
        end
        
        % 显示调试信息
        fprintf('开始分析 - 数据尺寸: %s, 时间点数: %d, 采样频率: %.2f MHz\n', ...
                mat2str(size(app_data.data_xyt)), length(app_data.data_time), app_data.fs/1e6);
        
        try
            % 调用波场分析模块
            wave_field_analyzer.create_analysis_ui(app_data.data_xyt, app_data.data_time, app_data.fs);
        catch ME
            msgbox(['Analysis failed: ' ME.message], 'Error', 'error');
            fprintf('分析失败详细信息:\n%s\n', getReport(ME));
        end
    end
end
