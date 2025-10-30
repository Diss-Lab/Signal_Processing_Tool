classdef wave_data_processor < handle
    % 波场数据处理器 - 处理MAT文件
    
    methods (Static)
        function [success, processed_data] = process_single_mat_file(mat_file_path, grid_params)
            % 处理单个MAT文件
            % 输入: mat_file_path - MAT文件路径, grid_params - 网格参数结构体
            % 输出: success - 是否成功, processed_data - 处理后的数据结构体
            
            success = false;
            processed_data = struct();
            
            try
                % 加载MAT文件
                loaded_data = load(mat_file_path);
                field_names = fieldnames(loaded_data);
                
                % 检查数据格式并处理不同的MAT文件结构
                if isfield(loaded_data, 'data_xyt') && isfield(loaded_data, 'data_time')
                    % 标准格式：data_xyt 和 data_time
                    data_xyt = loaded_data.data_xyt;
                    data_time = loaded_data.data_time;
                    
                    % 计算采样频率
                    if isfield(loaded_data, 'fs')
                        fs = loaded_data.fs;
                    else
                        dt = mean(diff(data_time));
                        fs = 1 / dt;
                    end
                    
                elseif isfield(loaded_data, 'x') && isfield(loaded_data, 'y')
                    % 另一种格式：x 为时间，y 为数据
                    data_struct = loaded_data;
                    data_time = data_struct.x;
                    data_xyt_origin = data_struct.y;
                    fs = 1 / (data_time(2) - data_time(1));
                    
                    % 验证数据尺寸
                    validation = wave_data_processor.validate_grid_params(grid_params, size(data_xyt_origin, 1));
                    if ~validation.valid
                        msgbox(validation.message, 'Grid Size Warning', 'warn');
                    end
                    
                    % 重塑数据
                    data_xyt = wave_data_processor.reshape_wave_data(data_xyt_origin, grid_params);
                    
                else
                    error('未知的MAT文件格式。期望变量: (data_xyt, data_time) 或 (x, y)。找到: %s', ...
                          strjoin(field_names, ', '));
                end
                
                % 重新整理数据格式以匹配网格尺寸
                if exist('data_xyt', 'var')
                    if size(data_xyt, 1) ~= grid_params.m || size(data_xyt, 2) ~= grid_params.n
                        % 如果尺寸不匹配，进行调整
                        fprintf('调整数据格式以匹配网格尺寸 %dx%d\n', grid_params.m, grid_params.n);
                        
                        % 创建新的数据矩阵
                        new_data_xyt = zeros(grid_params.m, grid_params.n, length(data_time));
                        
                        % 复制数据（如果原数据更小）
                        copy_m = min(size(data_xyt, 1), grid_params.m);
                        copy_n = min(size(data_xyt, 2), grid_params.n);
                        
                        new_data_xyt(1:copy_m, 1:copy_n, :) = data_xyt(1:copy_m, 1:copy_n, :);
                        data_xyt = new_data_xyt;
                    end
                end
                
                % 保存处理后的数据
                [filepath, ~, ~] = fileparts(mat_file_path);
                save_path = fullfile(filepath, 'data.mat');
                
                save(save_path, 'data_xyt', 'data_time', 'fs', 'm', 'n');
                
                % 返回处理结果
                processed_data.data_xyt = data_xyt;
                processed_data.data_time = data_time;
                processed_data.fs = fs;
                processed_data.m = grid_params.m;
                processed_data.n = grid_params.n;
                
                success = true;
                fprintf('数据处理完成，保存到: %s\n', save_path);
                
            catch ME
                fprintf('处理MAT文件失败: %s\n', ME.message);
            end
        end
        
        function data_xyt = reshape_wave_data(data_xyt_origin, grid_params)
            % 重塑波场数据
            % 输入: data_xyt_origin - 原始数据, grid_params - 网格参数
            % 输出: data_xyt - 重塑后的3D数据
            
            n = grid_params.n;
            m = grid_params.m;
            t = size(data_xyt_origin, 2);
            
            % 初始化输出矩阵
            data_xyt = zeros(m, n, t);
            
            % 进度条
            h_wait = waitbar(0, 'Reshaping wave data...');
            
            try
                % 重塑数据
                for time_index = 1:t
                    displacement = data_xyt_origin(:, time_index);
                    reshaped_data = reshape(displacement, n, m)';
                    
                    % 对偶数行进行翻转（扫描路径补偿）
                    for row = 1:m
                        if mod(row, 2) == 0
                            reshaped_data(row, :) = fliplr(reshaped_data(row, :));
                        end
                    end
                    
                    data_xyt(:, :, time_index) = reshaped_data;
                    waitbar(time_index/t, h_wait);
                end
                
                close(h_wait);
                
            catch ME
                close(h_wait);
                rethrow(ME);
            end
        end
        
        function result = validate_grid_params(grid_params, data_size)
            % 验证网格参数
            % 输入: grid_params - 网格参数, data_size - 数据尺寸
            % 输出: result - 验证结果结构体
            
            result = struct();
            result.valid = true;
            result.message = '';
            
            expected_size = grid_params.n * grid_params.m;
            
            if data_size ~= expected_size
                result.valid = false;
                result.message = sprintf('Grid size mismatch. Expected %d points (n=%d, m=%d), got %d points.', ...
                                        expected_size, grid_params.n, grid_params.m, data_size);
            else
                result.message = 'Grid parameters are valid';
            end
        end
    end
end
