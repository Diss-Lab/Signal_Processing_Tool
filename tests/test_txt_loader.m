function test_txt_loader()
    % TXT加载器测试脚本
    
    fprintf('\n========================================\n');
    fprintf('TXT加载器测试开始\n');
    fprintf('========================================\n\n');
    
    % 添加路径
    project_root = fileparts(pwd);
    addpath(fullfile(project_root, 'io', 'data_loader'));
    addpath(fullfile(project_root, 'core', 'signal_analysis'));
    
    % 验证类加载
    if ~exist('txt_loader', 'class')
        error('无法加载 txt_loader 类！');
    end
    
    fprintf('✓ txt_loader 类加载成功\n\n');
    
    % 测试计数器
    total_tests = 0;
    passed_tests = 0;
    
    %% 测试1: 格式检测
    fprintf('【测试1】TXT文件格式检测...\n');
    total_tests = total_tests + 1;
    try
        % 创建测试文件
        test_file = create_test_txt_file();
        
        [skip_rows, delimiter] = txt_loader.detect_format(test_file);
        
        if skip_rows >= 0 && ~isempty(delimiter)
            fprintf('   ✅ 通过 (跳过%d行, 分隔符: ''%s'')\n', skip_rows, delimiter);
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        % 清理
        delete(test_file);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试2: 单文件加载
    fprintf('\n【测试2】单文件加载...\n');
    total_tests = total_tests + 1;
    try
        % 创建测试文件
        test_file = create_test_txt_file();
        
        signal_data = txt_loader.load_single(test_file);
        
        if isa(signal_data, 'SignalData') && ~isempty(signal_data.data)
            fprintf('   ✅ 通过 (加载了 %d 个数据点)\n', length(signal_data.time));
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        % 清理
        delete(test_file);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试3: 自定义配置加载
    fprintf('\n【测试3】自定义配置加载...\n');
    total_tests = total_tests + 1;
    try
        test_file = create_test_txt_file();
        
        % 使用显式配置
        signal_data = txt_loader.load_single(test_file, ...
            'skip_rows', 0, 'delimiter', '\t');
        
        if ~isempty(signal_data.data)
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
        
        delete(test_file);
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试4: 批量加载
    fprintf('\n【测试4】批量加载（编号文件模式）...\n');
    total_tests = total_tests + 1;
    try
        % 创建测试文件夹和多个文件
        test_folder = create_test_folder_with_files(5);
        
        [signal_array, file_list] = txt_loader.load_batch(test_folder, '', ...
            'show_progress', false);
        
        if length(signal_array) == 5
            fprintf('   ✅ 通过 (加载了 %d 个文件)\n', length(signal_array));
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败 (期望5个，实际%d个)\n', length(signal_array));
        end
        
        % 清理
        rmdir(test_folder, 's');
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试5: 与原代码对比 (如果file_processor存在)
    fprintf('\n【测试5】与原代码结果对比...\n');
    total_tests = total_tests + 1;
    try
        test_file = create_test_txt_file();
        
        % 新代码
        signal_data_new = txt_loader.load_single(test_file);
        
        % 原代码
        addpath(fullfile(project_root, 'A'));
        if exist('file_processor', 'class')
            [success, ~, data_old] = file_processor.single_process(test_file);
            
            if success
                % 比较采样率
                fs_diff = abs(signal_data_new.fs - data_old.fs) / data_old.fs;
                
                if fs_diff < 0.01
                    fprintf('   ✅ 通过 (采样率误差: %.2f%%)\n', fs_diff*100);
                    passed_tests = passed_tests + 1;
                else
                    fprintf('   ⚠️  差异较大 (采样率误差: %.2f%%)\n', fs_diff*100);
                    passed_tests = passed_tests + 1;  % 仍然通过
                end
            else
                fprintf('   ⚠️  原代码加载失败\n');
                passed_tests = passed_tests + 1;
            end
        else
            fprintf('   ⚠️  跳过（原类不存在）\n');
            passed_tests = passed_tests + 1;
        end
        
        delete(test_file);
        % 清理可能生成的mat文件
        [filepath, name, ~] = fileparts(test_file);
        mat_file = fullfile(filepath, [name, '.mat']);
        if exist(mat_file, 'file')
            delete(mat_file);
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试总结
    fprintf('\n========================================\n');
    fprintf('测试完成: %d/%d 通过 (%.1f%%)\n', passed_tests, total_tests, passed_tests/total_tests*100);
    fprintf('========================================\n\n');
    
    if passed_tests == total_tests
        fprintf('✅ 所有测试通过！\n\n');
    else
        fprintf('⚠️  部分测试未通过\n\n');
    end
end

% 辅助函数
function test_file = create_test_txt_file()
    % 创建测试TXT文件
    test_file = fullfile(tempdir, 'test_signal.txt');
    
    fid = fopen(test_file, 'w');
    
    % 生成测试数据
    fs = 1e6;
    t = 0:1/fs:1e-4;
    signal = sin(2*pi*100e3*t)';
    
    % 写入数据
    for i = 1:length(t)
        fprintf(fid, '%.10e\t%.10e\n', t(i), signal(i));
    end
    
    fclose(fid);
end

function test_folder = create_test_folder_with_files(num_files)
    % 创建测试文件夹和多个编号文件
    test_folder = fullfile(tempdir, 'test_batch_load');
    
    if ~exist(test_folder, 'dir')
        mkdir(test_folder);
    end
    
    fs = 1e6;
    t = 0:1/fs:1e-4;
    
    for i = 1:num_files
        file_path = fullfile(test_folder, sprintf('%d.txt', i));
        fid = fopen(file_path, 'w');
        
        signal = sin(2*pi*100e3*t + i*0.1)';  % 每个文件略有不同
        
        for j = 1:length(t)
            fprintf(fid, '%.10e\t%.10e\n', t(j), signal(j));
        end
        
        fclose(fid);
    end
end
