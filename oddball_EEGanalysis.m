% % SSVEP EEG DATA ANALYSIS
% --------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the Oddball EEG data collected with Mentalab Amplifier (32 Channel)
% and plots relevant plots and save it to folder.
% 
% What the script does:
% 1. Loads the EEG (.set) file
% 2. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Re-reference to CAR (if re-ref variable is set to 1)
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
% Date  : 20/05/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --

% folder with EEG files 
foldername = 'Pilot-02';
% EEG file to analyse
filename   = 'Pilot-02_S001_task_rawdata.set';
% path to the folder
rootpath = '/Users/abinjacob/Documents/05. NELI/Mentalab_Pilots';
% directory folder 
path_dir = '/Users/abinjacob/Documents/01. Calypso/Calpso 1.0/Scripts/EEG Processing - Matlab';


% -- Analysis Params --

% event markers 
events = {'1','2'};
% high-pass filter 
HP = 2; HPorder = 826;                
% low-pass filter  
LP = 10; LPorder = 776; 
% epoch period 
epoch_start = -0.2; epoch_end = 1;
% reject artefactual epochs 
PRUNE = 4;

% rereference to common average reference (CAR)
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 2;

% ------------------------------------------------------------------------



% -- Load files to EEGLAB --
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
EEG = pop_loadset('filename', filename, 'filepath', filepath);
% set current directory
cd(path_dir); display('Directory Changed')
eeglab redraw


 
% -- Pre-Processing EEG Data --
% filtering
disp(['Data Filtering: LP = ', num2str(LP), ' HP = ', num2str(HP)])
EEG = pop_firws(EEG, 'fcutoff', LP, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', LPorder);
EEG = pop_firws(EEG, 'fcutoff', HP, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', HPorder);
if re_ref == 1
    % re-referencing to CAR
    EEG = pop_reref(EEG, [], 'refstate',0);
    display('Re-referenced to CAR')
elseif re_ref == 2
    EEG = pop_reref( EEG, [11 15] );
    display('Re-referenced to Mastoids')
end 
% epoching data
EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', 'SSVEPAR_epoched','epochinfo', 'yes');
% remove artifact epochs
EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
EEG = eeg_checkset(EEG);
% baseline correction
baseline = [epoch_start*EEG.srate 0];  
EEG = pop_rmbase(EEG, baseline);
EEG = eeg_checkset(EEG);

% extracting regular and odd tone trials
EEGstd = pop_selectevent(EEG, 'type', events{1},'renametype', events{1}, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');   
EEGodd = pop_selectevent(EEG, 'type', events{2},'renametype', events{2}, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');   



% -- Setting up Plots --
% set plot file names
namesplit = strsplit(filename, '_');
plotfile = [namesplit{2},'_'];
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

%% plotting all channels

% -- Plotting ERP for standard and odd tones--
% set plot name
plotname = 'ERP2';
figure('Units', 'centimeters', 'Position', s.figsize); 

% plotting regular tones
subplot(1,2,1)
hold on 
for ichan = 1:size(EEG.data,1)
    plot(EEGstd.times, mean(EEGstd.data(ichan,:,:),3), 'Color', clr(1,:), 'LineWidth', s.plt_linewidth)
end 
hold off
xlim([-50, 500]); ylim([-8, 6]);
xlabel('Time (ms)'); ylabel('Amplitude (µV)');
title('Standard Tones')
set(gca, 'FontSize', s.plt_fontsize);

% plotting odd tones
subplot(1,2,2)
hold on 
for ichan = 1:size(EEG.data,1)
    plot(EEGodd.times, mean(EEGodd.data(ichan,:,:),3), 'Color', clr(2,:), 'LineWidth', s.plt_linewidth)
end
hold off
xlim([-50, 500]); ylim([-8, 6]);
xlabel('Time (ms)'); ylabel('Amplitude (µV)');
title('Odd Tones')
set(gca, 'FontSize', s.plt_fontsize);


% save plot
plotsave = fullfile(plotfolder, [plotfile, plotname, '.png']);
saveas(gcf, plotsave)
