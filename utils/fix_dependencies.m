function fix_dependencies()
    % 修复旧模块依赖问题
    
    fprintf('\n========================================\n');
    fprintf('修复旧模块依赖关系\n');
    fprintf('========================================\n\n');
    
    project_root = fileparts(mfilename('fullpath'));
    
    % 1. 清除所有A/B/C相关路径
    fprintf('步骤1: 清除旧路径...\n');
    try
        rmpath(fullfile(project_root, 'A'));
        fprintf('  ✓ 移除 A/ 路径\n');
    catch
        fprintf('  - A/ 路径不在搜索路径中\n');
    end
    
    try
        rmpath(fullfile(project_root, 'B'));
        fprintf('  ✓ 移除 B/ 路径\n');
    catch
        fprintf('  - B/ 路径不在搜索路径中\n');
    end
    
    try
        rmpath(fullfile(project_root, 'C'));
        fprintf('  ✓ 移除 C/ 路径\n');
    catch
        fprintf('  - C/ 路径不在搜索路径中\n');
    end
    
    % 2. 重新初始化路径
    fprintf('\n步骤2: 重新初始化项目路径...\n');
    init_project();
    
    % 3. 验证新文件存在
    fprintf('\n步骤3: 验证新模块文件...\n');
    new_files = {
        fullfile(project_root, 'ui', 'main', 'ReadA.m');
        fullfile(project_root, 'ui', 'main', 'ReadB.m');
        fullfile(project_root, 'ui', 'main', 'ReadC.m');
        fullfile(project_root, 'main_launcher.m')
    };
    
    all_exist = true;
    for i = 1:length(new_files)
        if exist(new_files{i}, 'file')
            fprintf('  ✓ %s\n', new_files{i});
        else
            fprintf('  ✗ %s (缺失!)\n', new_files{i});
            all_exist = false;
        end
    end
    
    % 4. 再次检查依赖
    fprintf('\n步骤4: 检查依赖关系...\n');
    check_old_dependencies();
    
    % 5. 给出建议
    fprintf('\n========================================\n');
    if all_exist
        fprintf('✅ 修复完成！\n\n');
        fprintf('建议操作:\n');
        fprintf('1. 重启MATLAB以彻底清除路径缓存\n');
        fprintf('2. 运行 start 测试新系统\n');
        fprintf('3. 确认无误后执行:\n');
        fprintf('   mkdir old_backup\n');
        fprintf('   movefile(''A'', ''old_backup\\A'')\n');
        fprintf('   movefile(''B'', ''old_backup\\B'')\n');
        fprintf('   movefile(''C'', ''old_backup\\C'')\n');
    else
        fprintf('⚠️  部分新文件缺失!\n\n');
        fprintf('请确认新的ReadA/B/C文件已正确保存在 ui/main/ 目录下\n');
    end
    fprintf('========================================\n\n');
end
