% % SOUNDSCAPES TASK DATA ANALYSIS 
% --------------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the soundscapes EEG data collected with Mentalab Amplifier (32 Channel)
% and plots relevant plots and save it to folder.
% 
% What the script does:
% 1. Loads the EEG (.set) file
% 2. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Epoch the data based on events and epoch periods
%        - Remove artifactual epochs
%        - Baseline correction
% 3. Compute ERP for each sound file and plots them 
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
filename   = 'Soundscape_run001.set';

% path to the folder
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% -- Analysis Params --

% audio files
audiofiles = {'doors-01', 'office-01', 'office-02'};
% audiofiles = {'doors-01', 'office-02'};
% event markers 
events = {'SoundOnset'}; 
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


% -- EEG Preprocessing --
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

% copy of the full EEG data 
EEG_all = EEG; 


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
tasknames = {}; 

% loop over audio files
for iFile=1:length(audiofiles)

    % load the soundscape file and get the audio duration
    audiofile = fullfile(rootpath, 'Audio Files', [audiofiles{iFile}, '.mp3']);
    [y, Fs] = audioread(audiofile);
    duration = length(y) / Fs; 

    % select the EEG segment during the audio 
    startEventIdx = find(strcmp({EEG_all.event.type}, audiofiles{iFile}));
    st = EEG_all.event(startEventIdx).latency;
    ed = st + round(duration * EEG_all.srate) - 1;
    EEG = pop_select( EEG_all, 'point',[st ed] ); 

    % epoching 
    EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', audiofiles{iFile},'epochinfo', 'yes');
    % remove artifact epochs
    EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
    EEG = eeg_checkset(EEG);
    % baseline correction
    baseline = [epoch_start*1000 0];  
    EEG = pop_rmbase(EEG, baseline);
    EEG = eeg_checkset(EEG);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    
    % set plot name
    if iFile == 1
        plotname = 'ERPfrontocentral2';
        figure('Units', 'centimeters', 'Position', s.figsize); 
        if re_ref == 2
            channels2plot = [8 4 9 13];
        else 
            channels2plot = [8 4 9 14];
        end 
        hold on
    end 
    subplot(2,2, iFile)
    plot(EEG.times, mean(mean(EEG.data(channels2plot,:,:) ,3),1), 'LineWidth', s.plt_linewidth)
    % get legends from taskname
    tasknames{end+1} = audiofiles{iFile}; 
    title([audiofiles{iFile}, ' ERP'])
    set(gca, 'FontSize', s.plt_fontsize);

end 

% epoching 
EEG = EEG_all;
EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'Color', 'k','newname', 'soundscape_all','epochinfo', 'yes');
% remove artifact epochs
EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
EEG = eeg_checkset(EEG);
% baseline correction
baseline = [epoch_start*1000 0];  
EEG = pop_rmbase(EEG, baseline);
EEG = eeg_checkset(EEG);
subplot(2,2, iFile+1)
plot(EEG.times, mean(mean(EEG.data(channels2plot,:,:) ,3),1), 'Color', 'k','LineWidth', s.plt_linewidth)
xlabel('Time (ms)'); ylabel('Amplitude (µV)');
legend(tasknames)
title('All ERP')
set(gca, 'FontSize', s.plt_fontsize);


% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, plotname, '.png']);
    saveas(gcf, plotsave)
end 
