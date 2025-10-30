classdef file_processor < handle
    % 文件处理模块 - 负责TXT到MAT文件的转换
    
    methods (Static)
        function [success, output_file, data_struct] = single_process(input_file)
            % 单文件处理
            % 输入: input_file - TXT文件完整路径
            % 输出: success - 是否成功, output_file - 输出文件路径, data_struct - 数据结构
            
            success = false;
            output_file = '';
            data_struct = struct();
            
            try
                % 检查文件是否存在
                if ~exist(input_file, 'file')
                    error('文件不存在: %s', input_file);
                end
                
                % 读取数据
                if exist('readmatrix', 'file')
                    try
                        data = readmatrix(input_file);
                    catch
                        % 如果readmatrix失败，尝试其他方法
                        data = load(input_file);
                    end
                else
                    data = load(input_file);
                end
                
                % 检查数据格式
                if size(data, 2) < 2
                    error('文件格式错误，需要至少两列数据（时间和信号）');
                end
                
                time_data = data(:, 1);
                signal_data = data(:, 2);
                
                % 移除NaN值
                valid_idx = ~isnan(time_data) & ~isnan(signal_data);
                time_data = time_data(valid_idx);
                signal_data = signal_data(valid_idx);
                
                % 计算采样率
                if length(time_data) > 1
                    dt = mean(diff(time_data));
                    fs = 1 / dt;
                else
                    fs = 1e6; % 默认1MHz
                end
                
                % 按新格式保存数据
                [filepath, filename_no_ext, ~] = fileparts(input_file);
                output_file = fullfile(filepath, [filename_no_ext, '.mat']);
                
                % 创建新格式的数据
                data_xyt = reshape(signal_data, [1, 1, length(signal_data)]); % 1x1x时间点数
                data_time = time_data;
                
                save(output_file, 'data_xyt', 'data_time', 'fs');
                
                % 返回数据结构
                data_struct.data_xyt = data_xyt;
                data_struct.data_time = data_time;
                data_struct.fs = fs;
                
                success = true;
                fprintf('成功处理文件: %s -> %s\n', input_file, output_file);
                
            catch ME
                fprintf('Error processing file %s: %s\n', input_file, ME.message);
            end
        end
        
        function new_processed_files = batch_process(input_files)
            % 批量文件处理
            % 输入: input_files - TXT文件路径的cell数组
            % 输出: new_processed_files - 成功处理的MAT文件路径cell数组
            
            num_files = length(input_files);
            new_processed_files = {};
            
            % 创建进度条
            progress_fig = waitbar(0, 'Processing files...', 'Name', 'Batch Processing');
            
            success_count = 0;
            error_files = {};
            
            for i = 1:num_files
                try
                    waitbar(i/num_files, progress_fig, sprintf('Processing file %d of %d...', i, num_files));
                    
                    % 处理当前文件
                    [success, output_file, ~] = file_processor.single_process(input_files{i});
                    
                    if success
                        success_count = success_count + 1;
                        new_processed_files{end+1} = output_file;
                    else
                        error_files{end+1} = input_files{i};
                    end
                    
                catch ME
                    error_files{end+1} = input_files{i};
                    fprintf('Error processing %s: %s\n', input_files{i}, ME.message);
                end
            end
            
            close(progress_fig);
            
            % 显示批量处理结果
            file_processor.show_batch_results(success_count, error_files, new_processed_files);
        end
        
        function show_batch_results(success_count, error_files, new_files)
            % 显示批量处理结果
            
            result_fig = figure('Name', 'Batch Processing Results', 'Position', [300, 200, 600, 400], ...
                               'MenuBar', 'none', 'ToolBar', 'none');
            
            % 结果摘要
            uicontrol('Parent', result_fig, 'Style', 'text', ...
                      'String', sprintf('Batch Processing Complete\n\nSuccessfully processed: %d files\nFailed: %d files', ...
                                       success_count, length(error_files)), ...
                      'Position', [20, 320, 300, 60], 'FontSize', 12, 'FontWeight', 'bold');
            
            % 成功文件列表
            if ~isempty(new_files)
                uicontrol('Parent', result_fig, 'Style', 'text', 'String', 'Successfully processed files:', ...
                          'Position', [20, 280, 200, 20], 'FontWeight', 'bold');
                
                success_list = uicontrol('Parent', result_fig, 'Style', 'listbox', ...
                                        'String', new_files, ...
                                        'Position', [20, 150, 560, 120]);
            end
            
            % 错误文件列表
            if ~isempty(error_files)
                uicontrol('Parent', result_fig, 'Style', 'text', 'String', 'Failed files:', ...
                          'Position', [20, 120, 200, 20], 'FontWeight', 'bold', 'ForegroundColor', 'red');
                
                error_list = uicontrol('Parent', result_fig, 'Style', 'listbox', ...
                                      'String', error_files, ...
                                      'Position', [20, 50, 560, 60]);
            end
            
            % 关闭按钮
            uicontrol('Parent', result_fig, 'Style', 'pushbutton', 'String', 'Close', ...
                      'Position', [260, 10, 80, 30], 'Callback', @(~,~) close(result_fig));
        end
    end
end
