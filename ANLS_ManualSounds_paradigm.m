% % IN ROOM SOUNDS TASK DATA ANALYSIS
% -----------------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the EEG data collected with Mentalab Amplifier (32 Channel) and plots 
% relevant plots and save it to folder.
% 
% What the script does:
% 1. Loads the EEG (.set) files of different in room sounds
% 2. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Re-reference to CAR (if re-ref variable is set to 1)
%        - Epoch the data based on events and epoch periods
%        - Remove artifactual epochs
%        - Baseline correction
% 3. Compute ERP for tones and plots them to a single plot
%
% Pre-requisits:
% - Assumes the data is in .set format (Use PROC_convertXDF_and_mapOnsets.m script before running this script)
% - Requires following functions to run: plotStyles
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 30/09/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --

% folder with EEG files 
foldername = 'Recording30092025';
% XDF file to load for analysis
filename   = {'InRoomSoundsXyl_run001.set', 'InRoomSoundsTrg_run001.set', 'InRoomSoundsStick_run001.set'};
% path to the folder
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% -- Analysis Params --

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
save_fig = false;

% ------------------------------------------------------------------------


%% -- Pre-Processing EEG Data --

% -- Load files to EEGLAB --
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
tasknames = {}; lineclr = {'r', 'b', 'm'};
% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')

for iFile = 1:length(filename)
    EEG = pop_loadset('filename', filename{iFile}, 'filepath', filepath);
    % taskname
    taskname = filename{iFile};
    taskname = strsplit(taskname, '_');
    taskname = taskname{1};
    
    
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
    
    
    % -- Epoching --
    EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', taskname,'epochinfo', 'yes');
    % remove artifact epochs
    EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
    EEG = eeg_checkset(EEG);
    % baseline correction
    baseline = [epoch_start*1000 0];  
    EEG = pop_rmbase(EEG, baseline);
    EEG = eeg_checkset(EEG);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    
    
    % -- Setting up Plots --
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
    
    
    % -- Plotting ERP for standard and odd tones--
    % set plot name
    if iFile == 1
        plotname = 'ERPfrontocentral';
        figure('Units', 'centimeters', 'Position', s.figsize); 
        if re_ref == 2
            channels2plot = [8 4 9 13];
        else 
            channels2plot = [8 4 9 14];
        end 
        hold on
    end 
    plot(EEG.times, mean(mean(EEG.data(channels2plot,:,:) ,3),1), 'Color', lineclr{iFile}, 'LineWidth', s.plt_linewidth)
    xlabel('Time (ms)'); ylabel('Amplitude (µV)');
    set(gca, 'FontSize', s.plt_fontsize);
    title('Random Sounds ERP from Fronto-central Channels')
    % get legends from taskname
    idx = regexp(taskname, '[A-Z]');
    taskname = taskname(idx(end):end);
    tasknames{end+1} = taskname; 
end

% set legends to the final plot
legend(tasknames)

% save plot
if save_fig
    plotsave = fullfile(plotfolder, ['InRoomSound_', plotname, '.png']);
    saveas(gcf, plotsave)
end 

%% -- plotting topgraphies

% plotting topographies with Matlab markers
peaks2plot = [68 128 200 328];
pop_topoplot(EEG, 1, peaks2plot, 'Stick', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEG.chaninfo); 
