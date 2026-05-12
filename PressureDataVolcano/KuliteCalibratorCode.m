%% ============================================================
%  KULITE TDMS -> PRESSURE -> RMS -> SPL -> FFT PROCESSING
%
%  Workflow:
%  TDMS Voltage Signal -> Voltage to pressure -> Subtract mean -> computes
%  RMS and SPL -> plots FFT
%
%% ============================================================

clear; clc; close all;

%% ---------------- USER SETTINGS ----------------

df_desired = 100;          % Desired FFT bin width [Hz]

% ===== KULITE CALIBRATION =====

gain = 111;                % Amplifier gain

sensor_sens = 0.03;        % Kulite sensitivity [V/psi]
                            % (150mV / 5psi)

system_sens = sensor_sens * gain;
                            % [V/psi]

PREF = 20e-6;              % Acoustic reference pressure [Pa]

PSI_TO_PA = 6894.757;

%% ---------------- LOAD TDMS ----------------

[file,path] = uigetfile('*.tdms','Select TDMS File');

if isequal(file,0)
    error('No TDMS file selected.');
end

[data, info] = tdmsread(fullfile(path,file));

% Assumes first TDMS group contains probe channels (update per actual data)
Vraw = data{1};

% Convert timetable/table to numeric if needed
if istable(Vraw)
    Vraw = table2array(Vraw);
end

%% ===== SELECT FIRST CHANNEL =====
% Change column index to whichever Kulite channel is read based on TDMS

V = Vraw(:,1);
%% ---------------- TIME / SAMPLING ----------------

% If time channel exists separately:
% time = data{2};

% Otherwise define from sampling rate

fs = 50000;     % Hz, setting to 50kHz per desired Kulite sampling rate

dt = 1/fs; % timestep

nsamp = length(V);

time = (0:nsamp-1)' * dt;

fprintf('Sampling Frequency: %.2f Hz\n',fs);

%% ---------------- CONVERT VOLTAGE -> PRESSURE ----------------

% Pressure in PSI
p_psi = Vraw ./ system_sens; 

% Convert to Pa
p_pa = p_psi * PSI_TO_PA;

%% ---------------- REMOVE MEAN ----------------

p_fluct = p_pa - mean(p_pa);

%% ---------------- RMS PRESSURE ----------------

prms = rms(p_fluct);

fprintf('\n================ RESULTS =================\n');
fprintf('RMS Pressure = %.6f Pa\n',prms);

%% ---------------- SPL ----------------

SPL = 20*log10(prms / PREF);

fprintf('Overall SPL = %.2f dB re 20uPa\n',SPL);
fprintf('==========================================\n\n');

%% ---------------- FFT SETUP ----------------

Nfft = round(fs / df_desired);

if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

df_actual = fs / Nfft;

fprintf('Desired df: %.2f Hz\n',df_desired);
fprintf('Actual df : %.2f Hz\n',df_actual);
fprintf('FFT Length: %d\n',Nfft);

f = (0:Nfft-1).' * df_actual;

blocks = floor(nsamp / Nfft);

nwin = hann(Nfft);

%% ---------------- FFT PROCESSING ----------------

Xf = zeros(Nfft,blocks-1);

pt_finish = 0;

for n = 1:blocks-1

    pt_start  = pt_finish + 1;
    pt_finish = n * Nfft;

    x = p_fluct(pt_start:pt_finish);

    % Apply Hanning window
    xw = x .* nwin;

    % FFT
    X = fft(xw);

    % Single-sided amplitude spectrum
    Xmag = 2 * abs(X) / Nfft;

    Xf(:,n) = Xmag;

end

%% ---------------- AVERAGE FFT BLOCKS ----------------

Xavg = mean(Xf,2);

%% ---------------- CONVERT TO SPL SPECTRUM ----------------

NB = 20*log10(Xavg / PREF);

%% ---------------- FIND DOMINANT FREQUENCY ----------------

[pk,idx] = max(NB(2:Nfft/2));

idx = idx + 1;

peak_freq = f(idx);

fprintf('\nDominant Frequency = %.2f Hz\n',peak_freq);

%% ---------------- TIME TRACE PLOT ----------------

figure;

plot(time,p_fluct,'LineWidth',1);

xlabel('Time [s]');
ylabel('Pressure Fluctuation [Pa]');

title('Kulite Pressure Fluctuation');

grid on;

%% ---------------- FFT / SPL PLOT ----------------

figure;

semilogx( ...
    f(1:Nfft/2), ...
    NB(1:Nfft/2), ...
    'LineWidth',1.5);

xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');

title('Kulite Narrowband SPL Spectrum');

grid on;

xlim([df_actual fs/2]);

%% ---------------- OPTIONAL PSD PLOT ----------------
% 
% figure;
% 
% loglog( ...
%     f(1:Nfft/2), ...
%     Xavg(1:Nfft/2), ...
%     'LineWidth',1.5);
% 
% xlabel('Frequency [Hz]');
% ylabel('Pressure Amplitude [Pa]');
% 
% title('FFT Pressure Spectrum');
% 
% grid on;