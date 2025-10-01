% % ODDBALL DATA ANALYSIS - WITH LSL MARKERS
% ------------------------------------------
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
% Date  : 29/09/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --

% folder with EEG files 
foldername = 'Recording30092025';
% XDF file to load for analysis
filename   = 'Oddball_run001.set';

% path to the folder
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% -- Analysis Params --

% event markers 
events = {'1','2'};
events_bela = {'SoundOnset'};
% high-pass filter 
HP = .1; HPorder = 826;                
% low-pass filter  
LP = 30; LPorder = 776; 
% epoch period 
epoch_start = -0.5; epoch_end = 1;
% reject artefactual epochs 
PRUNE = 4;

% Perform rereferencing?
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 2;

% Shift Latency of events?
% set true to shift latency 
correct_latency = true;
% [if true] 
% list of events to shift
events2correct = {'1', '2'};
% latency to shift (in ms)
latency2shift = 60;

% Save figures to folder?
% Set 'true' to save figures to the folder
save_fig = true;

% ------------------------------------------------------------------------


%% -- Pre-Processing EEG Data --

% -- Load files to EEGLAB --
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
EEG = pop_loadset('filename', filename, 'filepath', filepath);
% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')


% event latency correction
if correct_latency
    sampleshift = round((latency2shift/1000) * EEG.srate);  
    for i = 1:length(EEG.event)
        if ismember(EEG.event(i).type, events2correct)
            EEG.event(i).latency = EEG.event(i).latency + sampleshift;
        end
    end
    EEG = eeg_checkset(EEG, 'eventconsistency');
    display(['Latency of events ', strjoin(events2correct, ', '), ' corrected by ', num2str(latency2shift), ' ms'])
end

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


% -- Epoching with Matlab Markers --
EEGboth = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', 'Oddball_epoched','epochinfo', 'yes');
% remove artifact epochs
EEGboth = pop_jointprob(EEGboth, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
EEGboth = eeg_checkset(EEGboth);
% baseline correction
baseline = [epoch_start*1000 0];  
EEGboth = pop_rmbase(EEGboth, baseline);
EEGboth = eeg_checkset(EEGboth);
% extracting regular and odd tone trials
EEGstd = pop_selectevent(EEGboth, 'type', events{1},'renametype', events{1}, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');   
EEGodd = pop_selectevent(EEGboth, 'type', events{2},'renametype', events{2}, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');   


% -- Epoching with Bela Markers --
EEGbela = pop_epoch(EEG, events_bela, [epoch_start epoch_end], 'newname', 'Oddball_epoched','epochinfo', 'yes');
% remove artifact epochs
EEGbela = pop_jointprob(EEGbela, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
EEGbela = eeg_checkset(EEGbela);
% baseline correction
baseline = [epoch_start*1000 0];  
EEGbela = pop_rmbase(EEGbela, baseline);
EEGbela = eeg_checkset(EEGbela);


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


%% plotting ERP

% -- Plotting ERP for standard and odd tones--
% set plot name
plotname = 'ERPfrontocentral';
figure('Units', 'centimeters', 'Position', s.figsize); 

if re_ref == 2
    channels2plot = [8 4 9 13];
else 
    channels2plot = [8 4 9 14];
end 

hold on
plot(EEGstd.times, mean(mean(EEGstd.data(channels2plot,:,:) ,3),1), 'Color', 'r', 'LineWidth', s.plt_linewidth)
plot(EEGodd.times, mean(mean(EEGodd.data(channels2plot,:,:) ,3),1), 'Color', 'b', 'LineWidth', s.plt_linewidth)
plot(EEGboth.times, mean(mean(EEGboth.data(channels2plot,:,:) ,3),1), 'Color', 'k', 'LineWidth', s.plt_linewidth)
plot(EEGbela.times, mean(mean(EEGbela.data(channels2plot,:,:) ,3),1), 'Color', 'm', 'LineWidth', s.plt_linewidth)
xlabel('Time (ms)'); ylabel('Amplitude (µV)');
legend('standard', 'deviant', 'both', 'bela')
set(gca, 'FontSize', s.plt_fontsize);
title('Oddbal ERP from Fronto-central Channels')

% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, plotname, '.png']);
    saveas(gcf, plotsave)
end 

%% plotting topgraphies

% plotting topographies with Matlab markers
peaks2plot = [76 132 192 264 368];
pop_topoplot(EEGstd, 1, peaks2plot, 'Standard', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEGstd.chaninfo); 
pop_topoplot(EEGodd, 1, peaks2plot, 'Deviant', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEGstd.chaninfo);
pop_topoplot(EEGboth, 1, peaks2plot, 'Both', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEGstd.chaninfo);

% plotting topographies with Bela markers
% peaks2plot = [84 128 175 248];
pop_topoplot(EEGbela, 1, peaks2plot, 'Bela', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEGstd.chaninfo);
