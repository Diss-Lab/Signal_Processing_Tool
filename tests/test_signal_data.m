function test_signal_data()
    % SignalData类测试脚本
    
    fprintf('\n========================================\n');
    fprintf('SignalData类测试开始\n');
    fprintf('========================================\n\n');
    
    % 添加路径
    project_root = fileparts(pwd);
    addpath(fullfile(project_root, 'io', 'data_loader'));
    
    % 验证类加载
    if ~exist('SignalData', 'class')
        error('无法加载 SignalData 类！');
    end
    
    fprintf('✓ SignalData 类加载成功\n\n');
    
    % 测试计数器
    total_tests = 0;
    passed_tests = 0;
    
    %% 测试1: 单点数据创建
    fprintf('【测试1】单点数据创建...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        signal = sin(2*pi*100e3*t)';
        
        sig_data = SignalData(signal, t', fs, 'single_point');
        
        [m, n, time_len] = size(sig_data.data);
        if m == 1 && n == 1 && time_len == length(signal)
            fprintf('   ✅ 通过 (维度: %d×%d×%d)\n', m, n, time_len);
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试2: B扫数据创建
    fprintf('\n【测试2】B扫数据创建...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        num_files = 10;
        data_2d = randn(num_files, length(t));
        
        sig_data = SignalData(data_2d, t', fs, 'bscan');
        
        [m, n, time_len] = size(sig_data.data);
        if m == 1 && n == num_files && time_len == length(t)
            fprintf('   ✅ 通过 (维度: %d×%d×%d)\n', m, n, time_len);
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试3: 波场数据创建
    fprintf('\n【测试3】波场数据创建...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-4;
        m_size = 10;
        n_size = 15;
        data_3d = randn(m_size, n_size, length(t));
        
        sig_data = SignalData(data_3d, t', fs, 'wavefield');
        
        [m, n, time_len] = size(sig_data.data);
        if m == m_size && n == n_size && time_len == length(t)
            fprintf('   ✅ 通过 (维度: %d×%d×%d)\n', m, n, time_len);
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试4: get_point方法
    fprintf('\n【测试4】get_point方法...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-4;
        data_3d = randn(5, 10, length(t));
        
        sig_data = SignalData(data_3d, t', fs, 'wavefield');
        signal = sig_data.get_point(3, 7);
        
        if length(signal) == length(t) && isequal(signal, squeeze(data_3d(3,7,:)))
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试5: 时间范围提取
    fprintf('\n【测试5】时间范围提取...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        signal = randn(length(t), 1);
        
        sig_data = SignalData(signal, t', fs, 'single_point');
        
        % 提取10-50微秒
        new_data = sig_data.apply_time_range(10e-6, 50e-6);
        
        time_range_check = new_data.time(1) >= 10e-6 && new_data.time(end) <= 50e-6;
        
        if time_range_check
            fprintf('   ✅ 通过 (提取了 %d 个点)\n', length(new_data.time));
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试6: 数据验证
    fprintf('\n【测试6】数据验证...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-4;
        signal = randn(length(t), 1);
        
        sig_data = SignalData(signal, t', fs, 'single_point');
        
        is_valid = sig_data.validate();
        
        if is_valid
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试7: 自动类型检测
    fprintf('\n【测试7】自动类型检测...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-4;
        
        % 测试单点数据自动检测
        signal_1d = randn(length(t), 1);
        sig_data1 = SignalData(signal_1d, t', fs, 'auto');
        
        % 测试B扫数据自动检测
        data_2d = randn(5, length(t));
        sig_data2 = SignalData(data_2d, t', fs, 'auto');
        
        % 测试波场数据自动检测
        data_3d = randn(5, 10, length(t));
        sig_data3 = SignalData(data_3d, t', fs, 'auto');
        
        if strcmp(sig_data1.metadata.type, 'single_point') && ...
           strcmp(sig_data2.metadata.type, 'bscan') && ...
           strcmp(sig_data3.metadata.type, 'wavefield')
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
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
