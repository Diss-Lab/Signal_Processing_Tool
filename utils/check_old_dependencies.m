function check_old_dependencies()
    % 检查是否还有对旧A/B/C文件夹的依赖
    
    fprintf('\n========================================\n');
    fprintf('检查旧模块依赖关系\n');
    fprintf('========================================\n\n');
    
    project_root = fileparts(mfilename('fullpath'));
    
    % 旧文件夹列表
    old_folders = {'A', 'B', 'C'};
    
    % 检查新模块是否引用了旧模块
    new_files = {
        fullfile(project_root, 'ui', 'main', 'ReadA.m');
        fullfile(project_root, 'ui', 'main', 'ReadB.m');
        fullfile(project_root, 'ui', 'main', 'ReadC.m');
        fullfile(project_root, 'main_launcher.m');
        fullfile(project_root, 'start.m');
        fullfile(project_root, 'init_project.m');
    };
    
    has_dependency = false;
    
    fprintf('检查新文件对旧模块的依赖...\n\n');
    
    for i = 1:length(new_files)
        if exist(new_files{i}, 'file')
            content = fileread(new_files{i});
            
            % 移除注释行，避免误报
            content_lines = strsplit(content, '\n');
            code_only = '';
            for j = 1:length(content_lines)
                line = strtrim(content_lines{j});
                % 跳过注释行
                if ~isempty(line) && line(1) ~= '%'
                    code_only = [code_only, ' ', line];
                end
            end
            
            for j = 1:length(old_folders)
                % 检查是否包含对旧文件夹的真实引用
                % 只检测实际的路径操作，避免文件名中的字母误报
                patterns = {
                    ['addpath.*[''"].*', old_folders{j}, '[''"]'];  % addpath('A')
                    ['fullfile.*[''"]', old_folders{j}, '[''"]'];   % fullfile('A', ...)
                    ['cd.*[''"]', old_folders{j}, '[''"]'];         % cd('A')
                    ['\[', old_folders{j}, filesep];                % \A\ 或 /A/
                };
                
                for k = 1:length(patterns)
                    if ~isempty(regexp(code_only, patterns{k}, 'once'))
                        fprintf('⚠️  发现依赖: %s → %s/\n', new_files{i}, old_folders{j});
                        fprintf('   模式: %s\n', patterns{k});
                        has_dependency = true;
                    end
                end
            end
        end
    end
    
    fprintf('\n========================================\n');
    
    if ~has_dependency
        fprintf('✅ 未发现对旧模块(A/B/C)的依赖\n\n');
        fprintf('安全删除旧文件夹:\n');
        fprintf('1. 备份旧文件夹:\n');
        fprintf('   mkdir old_backup\n');
        fprintf('   movefile(''A'', ''old_backup\\A'')\n');
        fprintf('   movefile(''B'', ''old_backup\\B'')\n');
        fprintf('   movefile(''C'', ''old_backup\\C'')\n\n');
        fprintf('2. 测试新系统:\n');
        fprintf('   check_project\n');
        fprintf('   start\n\n');
        fprintf('3. 确认无误后删除备份:\n');
        fprintf('   rmdir(''old_backup'', ''s'')\n\n');
    else
        fprintf('⚠️  发现依赖关系！\n');
        fprintf('   请先修复依赖再删除旧文件夹\n\n');
    end
    
    % 检查旧文件夹大小
    fprintf('旧文件夹信息:\n');
    for i = 1:length(old_folders)
        folder_path = fullfile(project_root, old_folders{i});
        if exist(folder_path, 'dir')
            files = dir(fullfile(folder_path, '**', '*.*'));
            file_count = sum(~[files.isdir]);
            fprintf('  %s/: %d 个文件\n', old_folders{i}, file_count);
        else
            fprintf('  %s/: 不存在\n', old_folders{i});
        end
    end
    
    fprintf('\n========================================\n');
    fprintf('高级检查: 搜索可能的间接引用\n');
    fprintf('========================================\n\n');
    
    % 额外检查：在MATLAB路径中是否仍有A/B/C
    current_path = path;
    for i = 1:length(old_folders)
        folder_name = [filesep, old_folders{i}, filesep];
        if contains(current_path, folder_name) || contains(current_path, [old_folders{i}, ';'])
            fprintf('⚠️  MATLAB搜索路径中仍包含: %s\n', old_folders{i});
            fprintf('   请运行以下命令移除:\n');
            fprintf('   rmpath(fullfile(pwd, ''%s''))\n', old_folders{i});
            has_dependency = true;
        end
    end
    
    if ~has_dependency
        fprintf('✅ MATLAB搜索路径中无旧模块路径\n');
    end
    
    fprintf('\n');
end
