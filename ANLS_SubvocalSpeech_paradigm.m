% % SUBVOCAL SPEECH TASK DATA ANALYSIS 
% -------------------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the Subvocal Speech sEMG data collected with Mentalab Amplifier (32 Channel)
% and plots relevant plots and save it to folder.
% 
% What the script does:
% 1. Loads the sEMG (.set) file
% 2. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Epoch the data based on events and epoch periods
%        - Remove artifactual epochs
%        - Baseline correction
% 3. Compute ERP for regular and odd tones and plot them for each channel 
%
% Pre-requisits:
% - Assumes the data is in .set format (Use convertXDF.m script before running this script)
% - Requires following functions to run: plotStyles
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 01/10/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --

% folder with EEG files 
foldername = 'Recording30092025';
% XDF file to load for analysis
filename   = 'Subvocal_run001.set';

% path to the folder
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% -- Analysis Params --

% event markers 
events = {'Pa','Ka'};
% high-pass filter 
HP = 20; HPorder = 826;                
% low-pass filter  
LP = 100; LPorder = 776; 
% epoch period 
epoch_start = -0.5; epoch_end = 1;
% reject artefactual epochs 
PRUNE = 4;

% Perform rereferencing?
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 0;

% Save figures to folder?
% Set 'true' to save figures to the folder
save_fig = false;

% ------------------------------------------------------------------------


%% -- Pre-Processing EEG Data --

% -- Load files to EEGLAB --
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
EEG = pop_loadset('filename', filename, 'filepath', filepath);
% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')


% filtering
disp(['Data Filtering: LP = ', num2str(LP), ' HP = ', num2str(HP)])
EEG = pop_firws(EEG, 'fcutoff', LP, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', LPorder);
EEG = pop_firws(EEG, 'fcutoff', HP, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', HPorder);
% re-referencing
if re_ref == 1
    % re-referencing to CAR
    EEG = pop_reref(EEG, [], 'refstate',0);
    display('Re-referenced to CAR')
elseif re_ref == 2
    % re-referencing to mastoids
    EEG = pop_reref( EEG, [11 15] );
    display('Re-referenced to Mastoids')
end 


% epoching 
EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', 'Oddball_epoched','epochinfo', 'yes');
% remove artifact epochs
EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
EEG = eeg_checkset(EEG);
% baseline correction
baseline = [epoch_start*1000 0];  
EEG = pop_rmbase(EEG, baseline);
EEG = eeg_checkset(EEG);
% extracting regular and odd tone trials
EEGpa = pop_selectevent(EEG, 'type', events{1},'renametype', events{1}, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');   
EEGka = pop_selectevent(EEG, 'type', events{2},'renametype', events{2}, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');   


% -- Setting up Plots --
% set plot file names
namesplit = strsplit(filename, '_');
plotfile = [namesplit{1},'_'];
% create figure folder if doesn't exist
plotfolder = fullfile(filepath,'Figures');
if ~exist(plotfolder, 'dir')
    mkdir(plotfolder);
    display('New Folder Created for Saving Plots')
end
% import plot styles
% ![ Important: requires the custome function 'plotStyles' ]
s = plotStyles();
clr = [s.color1; s.color2];


%% plotting topgraphies

data = EEG.data; % channels x time x trials

window = round(0.05*EEG.srate); % 50 ms RMS window
emg_env = movmean(abs(data), window, 2);

channels2plot = [11 15];
emg_data = emg_env(channels2plot, :, :);
timewin = [0.05 0.5]; % seconds
samples = dsearchn(EEG.times'/1000, timewin'); 

pa_trials = strcmp({EEG.epoch.eventtype},'Pa');
ka_trials = strcmp({EEG.epoch.eventtype},'Ka');

pa_data = mean(emg_data(:,samples(1):samples(2),pa_trials),[1 2]);
ka_data = mean(emg_data(:,samples(1):samples(2),ka_trials),[1 2]);

fprintf('Mean Pa amplitude = %.2f µV\n', mean(pa_data));
fprintf('Mean Ka amplitude = %.2f µV\n', mean(ka_data));

figure;
plot(EEG.times, squeeze(mean(emg_data(1,:,:),3)), 'LineWidth',s.plt_linewidth); hold on;
plot(EEG.times, squeeze(mean(emg_data(2,:,:),3)), 'LineWidth',s.plt_linewidth);
xlabel('Time (ms)'); ylabel('EMG amplitude (µV)');
legend('T7','T8');
title('Speech EMG ("Pa" vs "Ka") Envelope');


%%


% Average across selected channels and trials
pa_avg = squeeze(mean(mean(emg_data(:,:,pa_trials),3),1)); % mean over chan + trials
ka_avg = squeeze(mean(mean(emg_data(:,:,ka_trials),3),1));

% Plot
figure;
plot(EEG.times, pa_avg, 'r','LineWidth',s.plt_linewidth); hold on;
plot(EEG.times, ka_avg, 'b','LineWidth',s.plt_linewidth);
xlabel('Time (ms)');
ylabel('EMG envelope (µV)');
legend('Pa','Ka');
title('EMG Envelope for Speech Gestures ("Pa" vs "Ka")');
grid on;


%%

% --- Average across channels
pa_data = squeeze(mean(emg_data(:,:,pa_trials),1)); % time x trials
ka_data = squeeze(mean(emg_data(:,:,ka_trials),1));

% --- Plot single trials for Pa
figure;
subplot(2,1,1);
plot(EEG.times, pa_data, 'Color',[1 0.6 0.6]); hold on; % light red for trials
plot(EEG.times, mean(pa_data,2),'r','LineWidth',2); % mean in bold
xlabel('Time (ms)');
ylabel('EMG envelope (µV)');
title('"Pa" Trials');
grid on;

% --- Plot single trials for Ka
subplot(2,1,2);
plot(EEG.times, ka_data, 'Color',[0.6 0.6 1]); hold on; % light blue for trials
plot(EEG.times, mean(ka_data,2),'b','LineWidth',2); % mean in bold
xlabel('Time (ms)');
ylabel('EMG envelope (µV)');
title('"Ka" Trials');
grid on;
