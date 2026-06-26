%% ============================================================
% Multi-Edge CFD Cross Plotter
%
% Features:
%   - Select 1-3 CFD datasets
%   - Select multiple .dat files per dataset
%   - User-defined dataset identifiers
%   - Automatic location extraction from filename
%       K1.dat          -> K1
%       K1.150000.dat   -> K1
%   - Consistent color per location
%   - Different line style per dataset
%   - Time History
%   - Narrowband SPL (FFT Averaged)
%   - PSD (Welch)
%   - OASPL (time-domain RMS, cross-checked via PSD integration)
%
%% ============================================================

clear;
clc;
close all;

%% ============================================================
% CONSTANTS
%% ============================================================

PREF = 20e-6;

%% ============================================================
% NUMBER OF DATASETS
%% ============================================================

answer = inputdlg( ...
    'Number of CFD datasets (1-3):', ...
    'CFD Datasets', ...
    [1 50], ...
    {'1'});

if isempty(answer)
    return
end

nSets = str2double(answer{1});

if isnan(nSets)
    return
end

nSets = max(1,min(3,nSets));

%% ============================================================
% CFD DATASET SELECTION
%% ============================================================

cfdSets = cell(nSets,1);

for s = 1:nSets

    idAnswer = inputdlg( ...
        sprintf('Identifier for Dataset %i',s), ...
        'Dataset Identifier', ...
        [1 50], ...
        {sprintf('Case%i',s)});

    if isempty(idAnswer)
        return
    end

    identifier = strtrim(idAnswer{1});

    [files,path] = uigetfile( ...
        {'*.dat;*.txt','CFD Files'}, ...
        sprintf('Select CFD Files for %s',identifier), ...
        'MultiSelect','on');

    if isequal(files,0)
        return
    end

    if ischar(files)
        files = {files};
    end

    locations = cell(size(files));

    for k = 1:length(files)

        tokens = split(files{k},'.');
        locations{k} = tokens{1};

    end

    cfdSets{s}.identifier = identifier;
    cfdSets{s}.files = files;
    cfdSets{s}.path = path;
    cfdSets{s}.locations = locations;

end

%% ============================================================
% USER SETTINGS
%% ============================================================

answer = inputdlg( ...
    { ...
    'Plot Title', ...
    'Start Time [s]', ...
    'End Time [s]', ...
    'FFT df [Hz]', ...
    'Min Frequency [Hz]', ...
    'Max Frequency [Hz]'}, ...
    'Settings', ...
    [1 60], ...
    { ...
    'CFD Comparison', ...
    '0', ...
    '0.5', ...
    '75', ...
    '100', ...
    '20000'});

if isempty(answer)
    return
end

plotTitle = answer{1};

tStart = str2double(answer{2});
tEnd   = str2double(answer{3});

df_desired = str2double(answer{4});

fmin = str2double(answer{5});
fmax = str2double(answer{6});

%% ============================================================
% PERCEPTUALLY UNIFORM COLOR SYSTEM (CIE LAB)
%% ============================================================

allLocations = cfdSets{1}.locations;
nLocations = length(allLocations);

baseRGB = lines(max(nLocations,7));   % or turbo(nLocations)

% Convert base colors to LAB once
baseLAB = rgb2lab(baseRGB);

% Dataset brightness levels in LAB space (lightness shifts)
% 1 = dark, 2 = medium, 3 = bright
% Lshift = [-36 -18 0 +18 +36];  % tweak range if needed
Lshift = [-18 0 +18];

%% ============================================================
% DATASET LINE STYLES
%% ============================================================

lineStyles = {'-','-','-'};

%% ============================================================
% STORAGE
%% ============================================================

cfdSignals = {};
cfdTimes   = {};
cfdLegend  = {};

signalCounter = 0;

%% ============================================================
% TIME HISTORY
%% ============================================================

figure('Name','Time History');
hold on
grid on

title([plotTitle ' - Time History'])

xlabel('Time [s]')
ylabel('Pressure')

%% ============================================================
% READ ALL CFD FILES
%% ============================================================

for s = 1:nSets

    identifier = cfdSets{s}.identifier;

    for k = 1:length(cfdSets{s}.files)

        fileName = fullfile( ...
            cfdSets{s}.path, ...
            cfdSets{s}.files{k});

        fid = fopen(fileName);

        if fid < 0
            warning('Could not open %s',fileName);
            continue
        end

        data = textscan( ...
            fid,...
            '%f %f',...
            'CommentStyle','#',...
            'CollectOutput',true);

        fclose(fid);

        data = data{1};

        if isempty(data)
            warning('No data in %s',fileName);
            continue
        end

        t = data(:,1);
        p = data(:,2);

        mask = t >= tStart & t <= tEnd;

        t = t(mask);
        p = p(mask);

        p = p - mean(p);

        signalCounter = signalCounter + 1;

        cfdSignals{signalCounter} = p;
        cfdTimes{signalCounter} = t;

        location = cfdSets{s}.locations{k};

        legendStr = sprintf( ...
            'CFD - %s - %s', ...
            identifier, ...
            location);

        cfdLegend{signalCounter} = legendStr;

        colorIdx = find(strcmp(location,allLocations));

        if isempty(colorIdx)
            colorIdx = mod(k-1,size(baseRGB,1))+1;
        end
        
        lab = baseLAB(colorIdx,:);
        
        % Apply dataset-dependent lightness shift
        lab(1) = lab(1) + Lshift(min(s,length(Lshift)));
        
        % Convert back to RGB
        plotColor = lab2rgb(lab);
        
        % Clamp safety (MATLAB sometimes slightly exceeds bounds)
        plotColor = max(min(plotColor,1),0);

        plot( ...
            t,...
            p,...
            'Color',plotColor,...
            'LineStyle',lineStyles{s},...
            'LineWidth',1.5,...
            'DisplayName',legendStr);

    end

end

legend('show','Location','southoutside', 'NumColumns', 3)

%% ============================================================
% FFT FUNCTION HANDLE
%% ============================================================

computeNBFFT = @(sig,fs) ...
    localFFT(sig,fs,df_desired,PREF);

%% ============================================================
% NARROWBAND SPL
%% ============================================================

figure('Name','Narrowband SPL');
hold on
grid on

title([plotTitle ' - Narrowband SPL'])

xlabel('Frequency [Hz]')
ylabel('SPL [dB re 20 \muPa]')

set(gca,'XScale','log')

signalCounter = 0;

% Storage for OASPL summary (filled in during SPL & PSD loops below)
oaspl_labels = {};
oaspl_td     = [];   % time-domain OASPL (band-limited RMS)
oaspl_psd    = [];   % OASPL cross-check via PSD integration
oaspl_color  = [];   % matching plot color for each entry

for s = 1:nSets

    for k = 1:length(cfdSets{s}.files)

        signalCounter = signalCounter + 1;

        sig = cfdSignals{signalCounter};
        t   = cfdTimes{signalCounter};

        fs = 1/mean(diff(t));

        [f,NB] = computeNBFFT(sig,fs);

        location = cfdSets{s}.locations{k};

        colorIdx = find(strcmp(location,allLocations));

        if isempty(colorIdx)
            colorIdx = mod(k-1,size(baseRGB,1))+1;
        end
        
        lab = baseLAB(colorIdx,:);
        
        % Apply dataset-dependent lightness shift
        lab(1) = lab(1) + Lshift(min(s,length(Lshift)));
        
        % Convert back to RGB
        plotColor = lab2rgb(lab);
        
        % Clamp safety (MATLAB sometimes slightly exceeds bounds)
        plotColor = max(min(plotColor,1),0);

        semilogx( ...
            f,...
            NB,...
            'Color',plotColor,...
            'LineStyle',lineStyles{s},...
            'LineWidth',2,...
            'DisplayName',cfdLegend{signalCounter});

        %% OASPL (time domain), band-limited to [fmin fmax]
        oaspl_labels{end+1,1} = cfdLegend{signalCounter}; %#ok<SAGROW>
        oaspl_td(end+1,1) = computeOASPL_TD(sig,fs,fmin,fmax,PREF); %#ok<SAGROW>
        oaspl_color(end+1,:) = plotColor; %#ok<SAGROW>

    end

end

xlim([fmin fmax])

legend( ...
    'show', ...
    'Location','southoutside', ...
    'NumColumns',3)

%% ============================================================
% PSD
%% ============================================================

figure('Name','PSD');
hold on
grid on

title([plotTitle ' - PSD'])

xlabel('Frequency [Hz]')
ylabel('PSD [dB/Hz]')

set(gca,'XScale','log')

signalCounter = 0;
oaspl_psd = nan(length(oaspl_labels),1);

for s = 1:nSets

    for k = 1:length(cfdSets{s}.files)

        signalCounter = signalCounter + 1;

        sig = cfdSignals{signalCounter};
        t   = cfdTimes{signalCounter};

        fs = 1/mean(diff(t));

        seg = floor(length(sig)/8);

        if seg < 32
            continue
        end

        w = hann(seg);

        [P,f] = pwelch( ...
            sig,...
            w,...
            round(seg/2),...
            [],...
            fs);

        location = cfdSets{s}.locations{k};

        colorIdx = find(strcmp(location,allLocations));
        
        if isempty(colorIdx)
            colorIdx = mod(k-1,size(baseRGB,1))+1;
        end
        
        lab = baseLAB(colorIdx,:);
        
        % Apply dataset-dependent lightness shift
        lab(1) = lab(1) + Lshift(min(s,length(Lshift)));
        
        % Convert back to RGB
        plotColor = lab2rgb(lab);
        
        % Clamp safety (MATLAB sometimes slightly exceeds bounds)
        plotColor = max(min(plotColor,1),0);

        semilogx( ...
            f,...
            10*log10(P / PREF^2),...
            'Color',plotColor,...
            'LineStyle',lineStyles{s},...
            'LineWidth',2,...
            'DisplayName',cfdLegend{signalCounter});

        %% OASPL cross-check via PSD integration over [fmin fmax]
        oaspl_psd(signalCounter,1) = computeOASPL_PSD(f,P,fmin,fmax,PREF);

    end

end

xlim([fmin fmax])

legend( ...
    'show', ...
    'Location','southoutside', ...
    'NumColumns',3)

%% ============================================================
% OASPL SUMMARY (bar chart + table)
%% ============================================================

figure('Name','OASPL');
hold on
grid on

title([plotTitle ' - OASPL (' num2str(fmin) '-' num2str(fmax) ' Hz)'])
ylabel('OASPL [dB re 20 \muPa]')

b = bar(categorical(oaspl_labels,oaspl_labels), oaspl_psd, 'FaceColor','flat');
b.CData = oaspl_color;

% Annotate bars with both TD and PSD-integrated values
for i = 1:length(oaspl_labels)
    txt = sprintf('%.1f dB', oaspl_psd(i));
    text(i, oaspl_psd(i)/2, txt, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment',   'middle', ...
        'Rotation',            90, ...
        'FontSize',            12, ...
        'Color',               'w', ...
        'FontWeight',          'bold');
end

ylim([0, max(oaspl_psd)*1.15])
xtickangle(45)

%% Print summary table to command window
fprintf('\n=== OASPL Summary (%.0f-%.0f Hz band) ===\n', fmin, fmax);
fprintf('%-30s %15s %15s %15s\n','Label','OASPL_TD [dB]','OASPL_PSD [dB]','Diff [dB]');
for i = 1:length(oaspl_labels)
    if isnan(oaspl_psd(i))
        fprintf('%-30s %15.2f %15s %15s\n', ...
            oaspl_labels{i}, oaspl_td(i), 'N/A', 'N/A');
    else
        fprintf('%-30s %15.2f %15.2f %15.2f\n', ...
            oaspl_labels{i}, oaspl_td(i), oaspl_psd(i), oaspl_td(i)-oaspl_psd(i));
    end
end
fprintf('\n');

%% ============================================================
% LOCAL FFT FUNCTION
%% ============================================================

function [f,NB] = localFFT(signal,fs,df_desired,PREF)

signal = signal(:);

Nfft = round(fs/df_desired);

if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

if Nfft > length(signal)
    Nfft = floor(length(signal)/2);
end

if mod(Nfft,2) ~= 0
    Nfft = Nfft - 1;
end

window = hann(Nfft);

nBlocks = floor(length(signal)/Nfft);

if nBlocks < 2

    X = fft(signal .* hann(length(signal)));

    X = 2*abs(X)/length(signal);

    f = (0:floor(length(signal)/2))' ...
        * fs/length(signal);

    NB = 20*log10( ...
        X(1:length(f))/PREF);

    return

end

spec = zeros(Nfft,nBlocks);

for n = 1:nBlocks

    idx1 = (n-1)*Nfft + 1;
    idx2 = n*Nfft;

    x = signal(idx1:idx2);

    X = fft(x .* window);

    spec(:,n) = 2*abs(X)/Nfft;

end

Xavg = mean(spec,2);

f = (0:Nfft/2)'*(fs/Nfft);

NB = 20*log10( ...
    Xavg(1:Nfft/2+1)/PREF );

end

%% ============================================================
% LOCAL OASPL FUNCTIONS
%% ============================================================

function OASPL = computeOASPL_TD(signal,fs,fmin,fmax,PREF)
% Computes OASPL directly from the time-domain signal using its RMS,
% after band-limiting via a zero-phase Butterworth bandpass filter to
% [fmin fmax]. This is the most direct OASPL definition:
%   OASPL = 20*log10(p_rms / PREF)

signal = signal(:) - mean(signal);

nyq = fs/2;

loCut = max(fmin, 1e-3);          % avoid 0 Hz edge case
hiCut = min(fmax, nyq*0.999);     % stay safely below Nyquist

if hiCut <= loCut
    % Degenerate band (e.g. fmax > Nyquist and fmin close to it);
    % fall back to broadband RMS with a warning.
    warning('computeOASPL_TD:bandInvalid', ...
        'Requested band [%.1f %.1f] Hz invalid relative to fs=%.1f Hz. Using full bandwidth.', ...
        fmin,fmax,fs);
    p_rms = rms(signal);
else
    Wn = [loCut hiCut] / nyq;
    [b,a] = butter(4, Wn, 'bandpass');
    p_filt = filtfilt(b,a,signal);
    p_rms = rms(p_filt);
end

OASPL = 20*log10(p_rms / PREF);

end

function OASPL = computeOASPL_PSD(f,P,fmin,fmax,PREF)
% Cross-check: integrates the one-sided PSD over [fmin fmax]
% to recover mean-square pressure, then converts to OASPL.
%   p_rms^2 = integral( P(f) df ) over the band
%   OASPL = 10*log10( p_rms^2 / PREF^2 )

mask = f >= fmin & f <= fmax;

if nnz(mask) < 2
    OASPL = NaN;
    return;
end

p_meansq = trapz(f(mask), P(mask));

OASPL = 10*log10(p_meansq / PREF^2);

end