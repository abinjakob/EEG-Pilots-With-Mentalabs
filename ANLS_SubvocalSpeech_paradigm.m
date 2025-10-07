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
% 3. Compute RMS and plots the average of the envelope 
%
% Pre-requisits:
% - Assumes the data is in .set format (Use PROC_convertXDF_and_mapOnsets.m 
%   script before running this script)
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
epoch_start = -1.5; epoch_end = 2;
% reject artefactual epochs 
PRUNE = 4;

% Perform rereferencing?
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 0;

% Save figures to folder?
% Set 'true' to save figures to the folder
save_fig = true;

% ------------------------------------------------------------------------

%% data processing  

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


%% plotting speech envelopes 

% calculating RMS 
data = EEG.data; 
window = round(0.05*EEG.srate); % 50 ms RMS window
emg_env = movmean(abs(data), window, 2); 
% choosing data only from ear electrodes 
chans = [11 15];
emg_data = emg_env(chans, :, :);
% extracting 'Pa' and 'Ka' trials
pa_trials = strcmp({EEG.epoch.eventtype},'Pa');
ka_trials = strcmp({EEG.epoch.eventtype},'Ka');
% extracting data for 'Pa' and 'Ka' trials
pa_data = emg_data(:,:,pa_trials);
ka_data = emg_data(:,:,ka_trials);

% plotting envelope
plotname = 'sEMGenvelope';
figure('Units', 'centimeters', 'Position', s.figsize);
hold on;
plot(EEG.times, squeeze(mean(mean(pa_data,3),1)), 'Color', clr(1,:),'LineWidth',s.plt_linewidth); 
plot(EEG.times, squeeze(mean(mean(ka_data,3),1)), 'Color', clr(2,:),'LineWidth',s.plt_linewidth);
plot(EEG.times, squeeze(mean(mean(emg_data,3),1)), 'Color', 'k','LineWidth',s.plt_linewidth);
xlabel('Time (ms)'); ylabel('Amplitude (µV)'); 
legend('Pa','Ka', 'Average');
title('EMG Envelope for Speech Gestures ("Pa" vs "Ka")');
set(gca, 'FontSize', s.plt_fontsize);

% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, plotname, '.png']);
    saveas(gcf, plotsave)
end

% plotting topographies with Matlab markers
peaks2plot = [156 376 504 804 1092];
pop_topoplot(EEG, 1, peaks2plot, 'After Speech', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEG.chaninfo); 

peaks2plot = [-1388 -1148 -648 -460 -40];
pop_topoplot(EEG, 1, peaks2plot, 'Before Speech', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEG.chaninfo); 


peaks2plot = [348 690 924 1412 1808];
pop_topoplot(EEG, 1, peaks2plot, 'Before Speech', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEG.chaninfo); 
