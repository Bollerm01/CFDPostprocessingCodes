%% Batch RAW FFT Processing Script
% Iterates through all:
%   k1.pressure.dat ... k6.pressure.dat
% and overlays FFT spectra on one figure.

clear; clc;

%% ---------------- USER SETTINGS ----------------
nmics        = 1;      % Number of probe columns to use
df_desired   = 75;     % Desired FFT bin width [Hz]

%% ---------------- SELECT FOLDER ----------------
path = uigetdir(pwd, 'Select folder containing DAT files');

if isequal(path,0)
    error('No folder selected.');
end

%% ---------------- FIND FILES ----------------
% Matches:
%   k1.pressure.dat
%   k2.pressure.dat
%   ...
%   k6.pressure.dat

files = dir(fullfile(path, 'k*.pressure.dat'));

if isempty(files)
    error('No matching DAT files found.');
end

%% ---------------- CREATE FIGURE ----------------
figure(1);
hold on;
grid on;

legend_entries = {};

%% ---------------- LOOP THROUGH FILES ----------------
for iFile = 1:length(files)

    file = files(iFile).name;

    fprintf('\nProcessing: %s\n', file);

    %% ----- Extract k-number from filename -----
    token = regexp(file, 'k(\d+)\.pressure\.dat', 'tokens');

    if isempty(token)
        fprintf('Skipping file (bad format): %s\n', file);
        continue;
    end

    kLabel = ['k' token{1}{1}];

    %% ----- Load data -----
    data = readtable(fullfile(path,file), 'FileType','text');

    time = data{:,1};

    % Use first pressure column only
    pt = data{:,2};

    nsamp = length(time);

    %% ----- Compute sampling frequency -----
    dt = mean(diff(time));
    fs = 1/dt;

    %% ----- FFT length from desired bin width -----
    Nfft = round(fs / df_desired);

    % Force even FFT length
    if mod(Nfft,2) ~= 0
        Nfft = Nfft + 1;
    end

    df_actual = fs / Nfft;

    fprintf('Sampling Frequency : %.2f Hz\n', fs);
    fprintf('FFT Length         : %d\n', Nfft);
    fprintf('Actual df          : %.2f Hz\n', df_actual);

    %% ----- Frequency vector -----
    f = (0:Nfft-1).' * df_actual;

    %% ----- Window / block setup -----
    nwin   = hanning(Nfft);
    blocks = floor(nsamp / Nfft);

    %% ----- FFT averaging -----
    Xf = zeros(Nfft, blocks-1);

    pt_finish = 0;

    for n = 1:blocks-1

        pt_start  = pt_finish + 1;
        pt_finish = n * Nfft;

        x = pt(pt_start:pt_finish);

        X = fft(x .* nwin);

        % Raw amplitude spectrum
        Xf(:,n) = 2 * abs(X) / Nfft;

    end

    %% ----- Average FFT -----
    Xf_avg = mean(Xf, 2);

    % Optional SPL conversion:
    NB = 20*log10(Xf_avg / 20e-6);

    % NB = Xf_avg;

    %% ----- Plot -----
    semilogx( ...
        f(1:Nfft/2), ...
        NB(1:Nfft/2), ...
        'LineWidth', 1.5, ...
        'DisplayName', kLabel);

    legend_entries{end+1} = kLabel;

end

%% ---------------- FINAL PLOT FORMATTING ----------------
xlabel('Frequency [Hz]');
% ylabel('Amplitude');
ylabel('SPL [dB re 20 \muPa]');

title('Overlayed FFT Spectra');

set(gca, 'XScale', 'log');

xlim([200 20000]);

% Uncomment if using SPL:
ylim([60 140]);

legend('show', 'Location', 'best');