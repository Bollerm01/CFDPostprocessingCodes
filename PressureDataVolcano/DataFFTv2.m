%% Standalone RAW FFT Processing Script
% Experimental aeroacoustic data
% Columns: time | probe0000 ... probe0024

clear; clc; close all;

%% ---------------- USER SETTINGS ----------------
nmics = 25;            % Number of probes
df_desired = 50;       % <<< DESIRED Hz PER BIN <<<

%% ---------------- LOAD DATA ----------------
[file, path] = uigetfile('*.dat', 'Select pressure data file');
if isequal(file,0)
    error('No file selected.');
end

data = readtable(fullfile(path,file), 'FileType','text');

time = data{:,1};
pt   = data{:,2:1+nmics};

nsamp = length(time);

%% ---------------- COMPUTE SAMPLING FREQUENCY ----------------
dt = mean(diff(time));
fs = 1/dt;

fprintf('Computed sampling frequency: %.3f Hz\n', fs);

%% ---------------- FFT LENGTH FROM BIN WIDTH ----------------
Nfft = round(fs / df_desired);

% Force Nfft to be even (clean Nyquist handling)
if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

df_actual = fs / Nfft;

fprintf('Requested bin width: %.3f Hz\n', df_desired);
fprintf('Actual bin width:    %.3f Hz\n', df_actual);
fprintf('FFT length used:     %d samples\n', Nfft);

%% ---------------- PREALLOCATE ----------------
Xfsave = zeros(Nfft, nmics);
NB     = zeros(Nfft, nmics);

%% ---------------- FFT SETUP ----------------
f = (0:Nfft-1).' * df_actual;

nwin   = hanning(Nfft);
blocks = floor(nsamp / Nfft);

%% ---------------- MAIN LOOP ----------------
for k = 1:nmics

    Xf = zeros(Nfft, blocks-1);

    pt_finish = 0;
    for n = 1:blocks-1

        pt_start  = pt_finish + 1;
        pt_finish = n * Nfft;

        x = pt(pt_start:pt_finish, k);

        X = fft(x .* nwin);

        % Raw amplitude spectrum
        Xf(:,n) = 2 * abs(X) / Nfft;

    end

    % Block-averaged FFT
    Xfsave(:,k) = mean(Xf, 2);

    % Narrowband SPL (re 20 µPa)
    NB(:,k) = 20 * log10(Xfsave(:,k) / 20e-6);

end

%% ---------------- PLOTS ----------------
figure;
plot(f(1:Nfft/2), NB(1:Nfft/2,:));
grid on;
xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');
title('Raw Narrowband SPL – User-Specified Bin Width');
