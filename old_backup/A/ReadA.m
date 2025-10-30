function ReadA()
    % 主界面 - 单点信号处理工具
    % 负责协调各个功能模块
    
    % 创建主界面
    main_fig = figure('Name', 'Single Point Signal Processing Tool', 'Position', [100, 100, 500, 450], ...
                      'MenuBar', 'none', 'ToolBar', 'none', 'Resize', 'off');
    
    % 全局变量
    app_data = struct();
    app_data.time_data = [];
    app_data.signal_data = [];
    app_data.fs = 0;
    app_data.processed_files = {};
    
    % 创建主界面
    create_main_ui();
    
    function create_main_ui()
        clf(main_fig);
        
        % 标题
        uicontrol('Style', 'text', 'String', 'Signal Processing Tool', ...
                  'Position', [50, 400, 400, 30], 'FontSize', 16, 'FontWeight', 'bold');
        
        % Step 1 区域
        uicontrol('Style', 'text', 'String', 'Step 1: Load and Convert TXT Files', ...
                  'Position', [50, 340, 400, 25], 'FontSize', 12, 'FontWeight', 'bold');
        
        % 文件选择按钮
        uicontrol('Style', 'pushbutton', 'String', 'Browse Files', ...
                  'Position', [150, 290, 200, 40], 'FontSize', 12, ...
                  'BackgroundColor', [0.8 0.9 1.0], 'Callback', @browse_and_process_files);
        
        % 文件选择说明
        uicontrol('Style', 'text', 'String', 'Select one or multiple TXT files for automatic conversion', ...
                  'Position', [50, 260, 400, 20], 'FontSize', 10, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.5 0.5 0.5]);
        
        % 显示处理状态
        app_data.status_text = uicontrol('Style', 'text', 'String', 'Ready to process files...', ...
                                        'Position', [50, 200, 400, 50], 'HorizontalAlignment', 'center', ...
                                        'BackgroundColor', [0.95 0.95 0.95], 'FontSize', 10);
        
        % Step 2 区域
        uicontrol('Style', 'text', 'String', 'Step 2: Signal Analysis & Comparison', ...
                  'Position', [50, 130, 400, 50], 'FontSize', 12, 'FontWeight', 'bold');
        
       
        uicontrol('Style', 'pushbutton', 'String', 'Analysis', ...
                  'Position', [150, 105, 200, 40], 'FontSize', 11, ...
                  'BackgroundColor', [1.0 0.9 0.8], 'Callback', @open_comparison);
        
        % 已处理文件计数
        if ~isempty(app_data.processed_files)
            uicontrol('Style', 'text', 'String', sprintf('Processed Files: %d', length(app_data.processed_files)), ...
                      'Position', [150, 65, 200, 20], 'HorizontalAlignment', 'center', ...
                      'FontWeight', 'bold', 'ForegroundColor', [0.2 0.6 0.2]);
        end
        
        % 底部说明
        uicontrol('Style', 'text', 'String', 'Signal processing and analysis tool for TXT data files', ...
                  'Position', [50, 20, 400, 15], 'FontSize', 9, ...
                  'HorizontalAlignment', 'center', 'ForegroundColor', [0.6 0.6 0.6]);
    end
    
    function browse_and_process_files(~, ~)
        [filenames, pathname] = uigetfile('*.txt', 'Select TXT file(s) for conversion', 'MultiSelect', 'on');
        
        if isequal(filenames, 0)
            return;
        end
        
        % 统一处理为cell数组
        if ischar(filenames)
            filenames = {filenames};
        end
        
        full_paths = cellfun(@(x) fullfile(pathname, x), filenames, 'UniformOutput', false);
        
        % 更新状态显示
        status_msg = sprintf('Processing %d file(s)...\nPlease wait...', length(filenames));
        set(app_data.status_text, 'String', status_msg);
        drawnow;
        
        % 统一处理文件（单文件和多文件使用相同逻辑）
        [success_files, error_files] = process_files(full_paths);
        
        % 更新全局变量
        app_data.processed_files = [app_data.processed_files, success_files];
        
        % 如果单文件成功，加载数据
        if length(success_files) == 1 && length(full_paths) == 1
            try
                loaded = load(success_files{1});
                app_data.time_data = loaded.data_time;
                app_data.signal_data = squeeze(loaded.data_xyt(1,1,:));
                app_data.fs = loaded.fs;
            catch
                % 加载失败也不影响显示
            end
        end
        
        % 更新状态
        status_msg = sprintf('Processing complete:\n%d/%d files converted', length(success_files), length(full_paths));
        set(app_data.status_text, 'String', status_msg);
        
        % 显示结果窗口（包含失败文件信息）
        if ~isempty(success_files)
            show_success_list_figure2(success_files, error_files);
        end
        
        % 新增：自动询问是否进入对比分析
        if length(success_files) >= 1  % 任意数量的成功文件都询问
            ask_for_comparison_analysis(success_files);
        end
    end

    function [success_files, error_files] = process_files(file_paths)
        % 统一的文件处理函数
        success_files = {};
        error_files = {};
        
        % 显示进度条
        h_wait = waitbar(0, 'Processing files...');
        
        for i = 1:length(file_paths)
            waitbar(i/length(file_paths), h_wait, sprintf('Processing file %d of %d...', i, length(file_paths)));
            
            try
                [success, output_file, ~] = file_processor.single_process(file_paths{i});
                if success
                    success_files{end+1} = output_file;
                else
                    error_files{end+1} = file_paths{i};
                end
            catch ME
                error_files{end+1} = file_paths{i};
                fprintf('Error processing %s: %s\n', file_paths{i}, ME.message);
            end
        end
        
        close(h_wait);
    end
    
    function ask_for_comparison_analysis(success_files)
        % 询问用户是否进入对比分析
        if length(success_files) == 1
            question_text = sprintf('已成功转换 1 个文件。\n是否进入信号对比分析环节？');
            dialog_title = 'Signal Analysis';
        else
            question_text = sprintf('已成功转换 %d 个文件。\n是否进入信号对比分析环节？', length(success_files));
            dialog_title = 'Comparison Analysis';
        end
        
        choice = questdlg(question_text, dialog_title, ...
                         '是(Yes)', '否(No)', '是(Yes)');
        
        if strcmp(choice, '是(Yes)')
            % 启动对比分析界面并自动加载转换的文件
            start_comparison_with_files(success_files);
        end
    end
    
    function start_comparison_with_files(mat_files)
        % 启动对比分析界面并自动加载指定的MAT文件
        try
            % 直接调用带参数的对比界面创建函数
            signal_comparator.create_comparison_ui_with_files(mat_files);
            
        catch ME
            msgbox(['启动对比分析失败: ' ME.message], 'Error', 'error');
        end
    end
    
    function auto_load_comparison_files(mat_files)
        % 这个函数现在作为备用方案
        try
            % 查找对比分析窗口
            comp_figs = findobj('Type', 'figure', 'Name', 'Signal Comparison Tool');
            
            if isempty(comp_figs)
                msgbox('未找到信号对比分析窗口', 'Warning', 'warn');
                return;
            end
            
            comp_fig = comp_figs(1);
            
            % 直接设置自动加载数据
            setappdata(comp_fig, 'auto_load_files', mat_files);
            
            % 强制刷新界面
            drawnow;
            
        catch ME
            fprintf('自动加载文件失败: %s\n', ME.message);
            % 如果自动加载失败，至少显示提示信息
            [~, file_names, ~] = cellfun(@fileparts, mat_files, 'UniformOutput', false);
            msgbox(sprintf('对比分析界面已打开。\n请手动选择以下文件进行对比：\n\n%s', ...
                          strjoin(file_names, '\n')), 'Manual Load Required', 'help');
        end
    end
    
    function open_comparison(~, ~)
        signal_comparator.create_comparison_ui();
        [~, name, ext] = fileparts(selected_file);
        choice = questdlg(sprintf('Are you sure you want to delete:\n%s%s?', name, ext), ...
                            'Delete File', 'Yes', 'No', 'No');
        if strcmp(choice, 'Yes')
            try
                delete(selected_file);
                % 从处理文件列表中移除
                app_data.processed_files = setdiff(app_data.processed_files, {selected_file});
                % 更新列表显示
                remaining_files = file_list;
                remaining_files(selected_idx(1)) = [];
                [~, file_names, file_exts] = cellfun(@fileparts, remaining_files, 'UniformOutput', false);
                display_names = cellfun(@(name, ext) [name, ext], file_names, file_exts, 'UniformOutput', false);
                set(listbox, 'String', display_names, 'Value', 1);
                msgbox('File deleted successfully.', 'Delete Complete', 'info');
            catch ME
                msgbox(['Error deleting file: ' ME.message], 'Error', 'error');
            end
        end
        
            msgbox('Please select a file first.', 'Info', 'info');
        end
    end
    

    function show_success_list_figure2(file_list, error_files)
        % 在 Figure 2 单独显示成功处理的文件列表（包含失败文件提示）
        f2 = figure('Name', 'Processing Results', 'NumberTitle', 'off', ...
                'MenuBar', 'none', 'ToolBar', 'none', 'Position', [700, 220, 650, 500]);

        clf(f2);

        % 标题
        uicontrol('Parent', f2, 'Style', 'text', 'String', 'File Processing Results', ...
                  'Position', [50, 450, 550, 30], 'FontSize', 14, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'center');

        % 成功文件部分
        success_count = length(file_list);
        uicontrol('Parent', f2, 'Style', 'text', ...
                  'String', sprintf('Successfully Processed Files (%d):', success_count), ...
                  'Position', [20, 410, 300, 20], 'FontSize', 12, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left', 'ForegroundColor', [0, 0.6, 0]);

        if ~isempty(file_list)
            [~, file_names, file_exts] = cellfun(@fileparts, file_list, 'UniformOutput', false);
            display_names = cellfun(@(n,e) [n, e], file_names, file_exts, 'UniformOutput', false);

            uicontrol('Parent', f2, 'Style', 'listbox', 'String', display_names, ...
                      'Position', [20, 280, 610, 120], 'FontSize', 10, ...
                      'BackgroundColor', [0.95, 1, 0.95]);
        else
            uicontrol('Parent', f2, 'Style', 'text', 'String', 'No files successfully processed.', ...
                      'Position', [20, 330, 610, 20], 'FontSize', 11, ...
                      'HorizontalAlignment', 'center', 'ForegroundColor', [0.7, 0.7, 0.7]);
        end

        % 失败文件部分
        if ~isempty(error_files)
            error_count = length(error_files);
            uicontrol('Parent', f2, 'Style', 'text', ...
                      'String', sprintf('Failed to Process (%d):', error_count), ...
                      'Position', [20, 250, 300, 20], 'FontSize', 12, 'FontWeight', 'bold', ...
                      'HorizontalAlignment', 'left', 'ForegroundColor', [0.8, 0, 0]);

            [~, error_names, error_exts] = cellfun(@fileparts, error_files, 'UniformOutput', false);
            error_display_names = cellfun(@(n,e) [n, e], error_names, error_exts, 'UniformOutput', false);

            uicontrol('Parent', f2, 'Style', 'listbox', 'String', error_display_names, ...
                      'Position', [20, 120, 610, 120], 'FontSize', 10, ...
                      'BackgroundColor', [1, 0.95, 0.95]);
        else
            % 如果没有失败文件，显示成功信息
            uicontrol('Parent', f2, 'Style', 'text', 'String', '✓ All files processed successfully!', ...
                      'Position', [20, 180, 610, 30], 'FontSize', 12, ...
                      'HorizontalAlignment', 'center', 'ForegroundColor', [0, 0.6, 0], ...
                      'FontWeight', 'bold', 'BackgroundColor', [0.9, 1, 0.9]);
        end

        % 底部按钮区域
        uicontrol('Parent', f2, 'Style', 'text', 'String', 'Actions:', ...
                  'Position', [20, 80, 100, 20], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');

        % 打开对比分析按钮
        if success_count >= 1
            uicontrol('Parent', f2, 'Style', 'pushbutton', 'String', 'Open Comparison Analysis', ...
                      'Position', [20, 40, 180, 30], 'FontSize', 10, ...
                      'BackgroundColor', [0.8, 0.9, 1.0], ...
                      'Callback', @(~,~) start_comparison_with_files(file_list));
        end

        % 关闭按钮
        uicontrol('Parent', f2, 'Style', 'pushbutton', 'String', 'Close', ...
                  'Position', [540, 40, 90, 30], 'FontSize', 10, ...
                  'BackgroundColor', [0.9, 0.9, 0.9], 'Callback', @(~,~) close(f2));
    
        uicontrol('Parent', f2, 'Style', 'text', 'String', 'Actions:', ...
                  'Position', [20, 80, 100, 20], 'FontSize', 11, 'FontWeight', 'bold', ...
                  'HorizontalAlignment', 'left');

        % 打开对比分析按钮
        if success_count >= 1
            uicontrol('Parent', f2, 'Style', 'pushbutton', 'String', 'Open Comparison Analysis', ...
                      'Position', [20, 40, 180, 30], 'FontSize', 10, ...
                      'BackgroundColor', [0.8, 0.9, 1.0], ...
                      'Callback', @(~,~) start_comparison_with_files(file_list));
        end

        % 关闭按钮
        uicontrol('Parent', f2, 'Style', 'pushbutton', 'String', 'Close', ...
                  'Position', [540, 40, 90, 30], 'FontSize', 10, ...
                  'BackgroundColor', [0.9, 0.9, 0.9], 'Callback', @(~,~) close(f2));
    end
