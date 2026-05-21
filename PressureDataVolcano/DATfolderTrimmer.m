%% User Inputs

% Root folder containing the .dat files
rootFolder = uigetdir(pwd, 'Select the root folder containing DAT files');
if rootFolder == 0
    error('No folder selected. Script aborted.');
end

% CTU duration (in CTUs) that you want to keep at the end of the record
CTU_duration = 50;   % <-- change as needed

% Conversion from CTUs to seconds (seconds per CTU)
CTU_to_sec = 0.00367;    % <-- change as needed

% Name of output subfolder (created inside rootFolder)
outputSubFolder = '50_CTU_Data';


%% Create output directory

outputFolder = fullfile(rootFolder, outputSubFolder);
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end


%% Get list of .dat files in the root folder (non-recursive)

fileList = dir(fullfile(rootFolder, '*.dat'));

if isempty(fileList)
    warning('No .dat files found in the selected folder.');
end


%% Process each .dat file

for k = 1:numel(fileList)
    fileName = fileList(k).name;

    % Skip files that contain "coords" in the name (case-insensitive)
    if contains(lower(fileName), 'coords')
        fprintf('Skipping file (contains "coords"): %s\n', fileName);
        continue;
    end

    inputFilePath  = fullfile(rootFolder, fileName);
    outputFilePath = fullfile(outputFolder, fileName);

    fprintf('Processing file: %s\n', fileName);

    %% Read header line + numeric data

    fid = fopen(inputFilePath, 'r');
    if fid == -1
        warning('Could not open file %s. Skipping.', fileName);
        continue;
    end

    % Read first line as header (keep as text)
    headerLine = fgetl(fid);

    % Read remaining lines as numeric data
    % Assuming whitespace-delimited numeric columns
    numericData = fscanf(fid, '%f', [inf]);
    fclose(fid);

    if isempty(numericData)
        warning('No numeric data found in %s. Skipping.', fileName);
        continue;
    end

    % Reshape data into columns: we don't know number of columns a priori,
    % so infer from the sample line count.
    % To do that robustly, reload using readmatrix (if available).
    %
    % More robust approach using readmatrix:
    try
        data = readmatrix(inputFilePath, 'FileType', 'text', 'NumHeaderLines', 1);
    catch
        % Fallback: infer number of columns from numericData length and
        % first line. This assumes consistent number of columns per row.
        % Here we try to detect number of columns using the first numeric line.

        % Re-open and read second line only, then re-read all numeric data
        fid = fopen(inputFilePath, 'r');
        headerLine = fgetl(fid); % first line
        secondLine = fgetl(fid); % second line (first numeric line)
        fclose(fid);

        % Count numbers in secondLine
        numsInSecond = sscanf(secondLine, '%f');
        nCols = numel(numsInSecond);

        % Reshape numericData into nCols columns
        data = reshape(numericData, [nCols, numel(numericData)/nCols]).';
    end

    % Now data should be an N x M numeric matrix
    if size(data, 2) < 1
        warning('File %s has no numeric columns. Skipping.', fileName);
        continue;
    end

    % Column 1 is time (in seconds)
    time = data(:, 1);

    if isempty(time)
        warning('File %s has empty time data. Skipping.', fileName);
        continue;
    end

    % Ensure time is sorted
    [timeSorted, sortIdx] = sort(time);
    if ~isequal(time, timeSorted)
        warning('Time in file %s not sorted. Sorting rows by time.', fileName);
        data = data(sortIdx, :);
        time = timeSorted;
    end


    %% Compute time window based on CTUs

    duration_sec = CTU_duration * CTU_to_sec;   % total time span in seconds
    t_end = time(end);                          % last time stamp
    t_start = t_end - duration_sec;             % earliest time to keep

    % Clamp to earliest time available
    t_min = time(1);
    if t_start < t_min
        t_start = t_min;
    end

    keepIdx = time >= t_start;

    if ~any(keepIdx)
        warning('No data in %s satisfies the required CTU duration. Skipping.', fileName);
        continue;
    end

    trimmedData = data(keepIdx, :);


    %% Write header + trimmed numeric data to new file

    fidOut = fopen(outputFilePath, 'w');
    if fidOut == -1
        warning('Could not open output file %s for writing.', outputFilePath);
        continue;
    end

    % Write the original header line
    if ischar(headerLine)
        fprintf(fidOut, '%s\n', headerLine);
    elseif isstring(headerLine) || iscellstr(headerLine)
        fprintf(fidOut, '%s\n', char(headerLine));
    end

    % Write numeric data, space-separated
    % Each row on a new line
    fmt = [repmat('% .16e ', 1, size(trimmedData, 2)-1), '% .16e\n'];
    for iRow = 1:size(trimmedData, 1)
        fprintf(fidOut, fmt, trimmedData(iRow, :));
    end

    fclose(fidOut);

    fprintf('Saved trimmed file to: %s\n', outputFilePath);
end

fprintf('Processing complete.\n');