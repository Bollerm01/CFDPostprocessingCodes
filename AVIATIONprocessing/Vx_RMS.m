%% USER-EDITABLE SECTION: file names for each probe line
% Assumed structure:
% - One coordinates file per line: columns = [probe#, X, Y, Z]
% - One Vx file per line: rows = time steps, columns = probe points
% - One Vx_avg file per line: same layout as Vx

%% SELECT FILES VIA GUI

% 1) Select coordinate files (one per probe line)
[coordFiles, coordPath] = uigetfile(...
    {'*.dat;*.txt', 'Data Files (*.dat, *.txt)'; '*.*', 'All Files (*.*)'},...
    'Select COORDINATE files (one per probe line)',...
    'MultiSelect', 'on');

if isequal(coordFiles, 0)
    error('No coordinate files selected.');
end

% Ensure coordFiles is a cell array
if ischar(coordFiles)
    coordFiles = {coordFiles};
end

% Prepend path
coordFiles = fullfile(coordPath, coordFiles);


% 2) Select Vx files
[vxFiles, vxPath] = uigetfile(...
    {'*.dat;*.txt', 'Data Files (*.dat, *.txt)'; '*.*', 'All Files (*.*)'},...
    'Select Vx (velocityx) files (one per probe line)',...
    'MultiSelect', 'on');

if isequal(vxFiles, 0)
    error('No Vx files selected.');
end

if ischar(vxFiles)
    vxFiles = {vxFiles};
end

vxFiles = fullfile(vxPath, vxFiles);


% 3) Select Vx_avg files
[vxAvgFiles, vxAvgPath] = uigetfile(...
    {'*.dat;*.txt', 'Data Files (*.dat, *.txt)'; '*.*', 'All Files (*.*)'},...
    'Select Vx_{avg} (velocityxavg) files (one per probe line)',...
    'MultiSelect', 'on');

if isequal(vxAvgFiles, 0)
    error('No Vx_avg files selected.');
end

if ischar(vxAvgFiles)
    vxAvgFiles = {vxAvgFiles};
end

vxAvgFiles = fullfile(vxAvgPath, vxAvgFiles);


%% BASIC CONSISTENCY CHECKS
nLines = numel(coordFiles);

if numel(vxFiles) ~= nLines || numel(vxAvgFiles) ~= nLines
    error(['Number of selected coord, Vx, and Vx_{avg} files must match.\n'...
           'Selected: %d coord, %d Vx, %d Vx_{avg}'],...
           numel(coordFiles), numel(vxFiles), numel(vxAvgFiles));
end

% Optionally build output CSV names from coord filenames
outCsvFiles = cell(nLines, 1);
for iLine = 1:nLines
    [~, baseName, ~] = fileparts(coordFiles{iLine});
    outCsvFiles{iLine} = [baseName '_Vrms.csv'];
end

%% LOOP THROUGH DATA
for iLine = 1:nLines
    fprintf('Processing probe line %d...\n', iLine);

    %% 1) LOAD DATA (NEED TO VALIDATE FORMAT WHEN DATA IS AVAILABLE)
    % Adjust "readmatrix" if your.DAT files are not whitespace-delimited.
    coords = readmatrix(coordFiles{iLine});    % [nProbes x 4] = [probe#, X, Y, Z]
    Vx     = readmatrix(vxFiles{iLine});       % [nTime x nProbes]
    VxAvg  = readmatrix(vxAvgFiles{iLine});    % [nTime x nProbes]

    % Basic size checks
    [nTime, nProbes_vx]    = size(Vx);
    [nTime2, nProbes_vxav] = size(VxAvg);
    [nProbes_coords, nColsCoords] = size(coords);

    if nColsCoords < 4
        error('Coordinate file %s must have at least 4 columns: [probe#, X, Y, Z].', coordFiles{iLine});
    end

    if nProbes_vx ~= nProbes_coords || nProbes_vxav ~= nProbes_coords
        error('Mismatch in number of probes between coords and velocity files for line %d.', iLine);
    end
    if nTime ~= nTime2
        error('Vx and VxAvg must have the same number of time steps for line %d.', iLine);
    end

    nProbes = nProbes_coords;

    %% 2) CREATE 3D MATRIX: [probe#, X, Y, Z, Vx, VxAvg] over time
    % Dimensions: [nProbes x 6 x nTime] initially
    data3D = zeros(nProbes, 6, nTime);

    % Fill coordinate info (constant over time) in all time slices
    % Columns: 1=probe#, 2=X, 3=Y, 4=Z
    for t = 1:nTime
        data3D(:, 1, t) = coords(:, 1);  % probe#
        data3D(:, 2, t) = coords(:, 2);  % X
        data3D(:, 3, t) = coords(:, 3);  % Y
        data3D(:, 4, t) = coords(:, 4);  % Z

        % Columns 5=Vx, 6=VxAvg
        % Vx, VxAvg assumed: rows=time, columns=probe => Vx(t, p)
        data3D(:, 5, t) = Vx(t, :).';      % Vx at time t for all probes
        data3D(:, 6, t) = VxAvg(t, :).';   % Vx_avg at time t for all probes
    end

    %% 3) ADD TWO NEW COLUMNS: (Vx - VxAvg)^2 AND Vx^2
    % Expand to 8 columns total
    % Column 7 = (Vx - VxAvg)^2
    % Column 8 = Vx^2

    data3D_ext = zeros(nProbes, 8, nTime);
    data3D_ext(:, 1:6, :) = data3D;

    for t = 1:nTime
        Vx_t    = data3D(:, 5, t);  % Vx at time t
        VxAvg_t = data3D(:, 6, t);  % VxAvg at time t

        fluct = Vx_t - VxAvg_t;

        data3D_ext(:, 7, t) = fluct.^2;   % (Vx - VxAvg)^2
        data3D_ext(:, 8, t) = Vx_t.^2;    % Vx^2
    end

    % (If you want to keep "data3D" name going forward, uncomment below:)
    % data3D = data3D_ext;

    %% 4) CREATE 2D ARRAY FOR OUTPUT
    % From first time step (t=1), take: probe#, X, Y, Z
    probe   = data3D_ext(:, 1, 1);
    X       = data3D_ext(:, 2, 1);
    Y       = data3D_ext(:, 3, 1);
    Z       = data3D_ext(:, 4, 1);

    % Time series of the two new columns:
    % Column 7: (Vx - VxAvg)^2
    % Column 8: Vx^2
    fluctSq = squeeze(data3D_ext(:, 7, :));  % [nProbes x nTime]
    VxSq    = squeeze(data3D_ext(:, 8, :));  % [nProbes x nTime]

    % Compute time-averaged RMS quantities:
    % v_fluct_rms = sqrt( mean_t( (Vx - VxAvg)^2 ) )
    % v_rms       = sqrt( mean_t( Vx^2 ) )
    %
    % That is:
    %   v_fluct_rms(p) = sqrt( (1/N) * sum_{t=1}^N fluctSq(p, t) )
    %   v_rms(p)       = sqrt( (1/N) * sum_{t=1}^N VxSq(p, t) )

    v_fluct_rms = sqrt(mean(fluctSq, 2));   % [nProbes x 1]
    v_rms       = sqrt(mean(VxSq, 2));      % [nProbes x 1]

    % Assemble final 2D array:
    % Columns: [probe#, X, Y, Z, v_fluct_rms, v_rms]
    out2D = [probe, X, Y, Z, v_fluct_rms, v_rms];

    %% 5) WRITE 2D ARRAY TO CSV
    % Add a header row for clarity
    header = 'probe,X,Y,Z,v_fluct_rms,v_rms';

    % Write CSV with header
    fid = fopen(outCsvFiles{iLine}, 'w');
    if fid == -1
        error('Could not open output file %s for writing.', outCsvFiles{iLine});
    end
    fprintf(fid, '%s\n', header);
    fclose(fid);

    % Append numeric data
    dlmwrite(outCsvFiles{iLine}, out2D, '-append');

    fprintf('  -> Wrote %s\n', outCsvFiles{iLine});
end

fprintf('All probe lines processed.\n');