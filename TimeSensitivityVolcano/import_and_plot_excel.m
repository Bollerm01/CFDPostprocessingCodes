function import_and_plot_excel()

    %% --- Select MAIN folder containing 6 subfolders ---
    mainFolder = uigetdir('E:\Boller CFD\AVIATION CFD\TimeSensitivityData', ...
                          'Select the MAIN folder with 6 subfolders');
    if isequal(mainFolder,0)
        disp('No folder selected.');
        return;
    end

    %% --- Select output folder ---
    outFolder = uigetdir('E:\Boller CFD\AVIATION CFD\TimeSensitivityData\output', ...
                         'Select Output Folder');
    if isequal(outFolder,0)
        disp('No output folder selected.');
        return;
    end

    %% --- List subfolders (expect 6) ---
    folderInfo = dir(mainFolder);
    subfolders = folderInfo([folderInfo.isdir] & ~ismember({folderInfo.name}, {'.','..'}));

    if numel(subfolders) ~= 6
        error('Expected exactly 6 subfolders, but found %d.', numel(subfolders));
    end

    %% --- Loop through each folder ---
    for f = 1:6
        folderPath = fullfile(mainFolder, subfolders(f).name);

        fprintf('\n=============================\n');
        fprintf('Processing Folder %d: %s\n', f, subfolders(f).name);
        fprintf('=============================\n');

        %% --- Find Excel files ---
        excelFiles = dir(fullfile(folderPath, '*.xlsx'));
        excelFiles = [excelFiles; dir(fullfile(folderPath,'*.xls'))];

        if numel(excelFiles) ~= 4
            error('Folder "%s" must contain exactly 4 Excel files.', subfolders(f).name);
        end

        files = {excelFiles.name};
        path = folderPath;

        %% --- Prefix based on first file ---
        [~, nameOnly] = fileparts(files{1});
        tokens = split(string(nameOnly), "_");
        savePrefix = tokens{1};

        %% --- Load data ---
        Y  = cell(1,4);
        M  = cell(1,4);
        P  = cell(1,4);
        Vx = cell(1,4);

        for i = 1:4
            T = readtable(fullfile(path, files{i}));
            Y{i}  = T.y;
            M{i}  = T.machnumberavg;
            P{i}  = T.pressureavg;
            Vx{i} = T.velocityxavg;
        end

        %% --- Create output subfolder for this run ---
        saveSub = fullfile(outFolder, subfolders(f).name);
        if ~isfolder(saveSub)
            mkdir(saveSub);
        end

        %% --- Generate plots (using helper function) ---
        save_overlay(M, Y, files, savePrefix, saveSub, ...
                     'machnumberavg', 'Overlay: Mach Number vs y', 'mach');

        save_overlay(P, Y, files, savePrefix, saveSub, ...
                     'pressureavg', 'Overlay: Pressure vs y', 'pressure');

        save_overlay(Vx, Y, files, savePrefix, saveSub, ...
                     'velocityxavg', 'Overlay: Velocity X vs y', 'velocityx');

        fprintf('Folder "%s" processed successfully.\n', subfolders(f).name);
    end

    disp('=============================================');
    disp('All 6 folders processed. Plots saved.');
    disp('=============================================');
end



%%                 Helper Function (Subfunction)
function save_overlay(xData, yData, files, savePrefix, saveFolder, xLabel, titleText, tag)
    %
    % This helper function is now fully independent:
    % ALL needed variables are passed in as arguments.
    %

    fig = figure('Visible','on');
    hold on; grid on;

    for k = 1:4
        plot(xData{k}, yData{k}, 'LineWidth', 2);
    end

    xlabel(xLabel);
    ylabel('y (m)');
    title(titleText, 'Interpreter','none');
    legend(files, 'Interpreter','none', 'Location','northwest');

    % Save FIG
    saveas(fig, fullfile(saveFolder, sprintf('%s_%s.fig', savePrefix, tag)),'fig');

    % Save JPEG
    print(fig, fullfile(saveFolder, sprintf('%s_%s.jpg', savePrefix, tag)),'-djpeg', '-r300');

    close(fig);
end




