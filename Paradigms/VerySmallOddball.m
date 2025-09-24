%%instantiate the library
disp('Loading library...');
lib = lsl_loadlib();


% make a new stream outlet
% the name (here MyMarkerStream) is visible to the experimenter and should be chosen so that 
% it is clearly recognizable as your MATLAB software's marker stream
% The content-type should be Markers by convention, and the next three arguments indicate the 
% data format (1 channel, irregular rate, string-formatted).
% The so-called source id is an optional string that allows for uniquely identifying your 
% marker stream across re-starts (or crashes) of your script (i.e., after a crash of your script 
% other programs could continue to record from the stream with only a minor interruption).
disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'MyMarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');

disp('Opening an outlet...');
outlet = lsl_outlet(info);
% Parameters
amp = 10;          % Amplitude
fs = 20500;        % Sampling frequency (you can adjust this if needed)
duration = 0.04;   % Duration in seconds (40 ms)
freq = 880;        % Frequency in Hz
minITI=1            % minimal inter trial interval
% Generate the time values
values = 0:1/fs:duration;

% Create the sine wave
a(1,:) = amp * sin(2*pi*freq*values);
a(2,:) = amp * sin(2*pi*(freq*2)*values);
WaitSecs(20);

% Play the sound
for k =1:500
        if rand>0.2
            s=1;
            mkr='1'
        else
            s=2;
            mkr='2'
        end        
        WaitSecs(minITI + rand);
        outlet.push_sample({mkr'});   % note that the string is wrapped into a cell-array
        sound(a(s,:), fs);
end

%%

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%%EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
data_path = 'C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-test2_withmic_run-001_eeg.xdf'
EEG = pop_loadxdf(data_path , 'streamtype', 'ExG', 'exclude_markerstreams', {});

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
ch7=EEG.data(7,:);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',30,'plotfreqz',1);
EEG.data(7,:)=ch7;

for k=1:numel(EEG.event)
    EEG.event(k).latency=EEG.event(k).latency+57;
end

% [EEG] = convertAudioToEvents(EEG,2000)
% EEG = pop_epoch( EEG, {  '1' ,'2','SoundOnset' }, [-0.5  0.8], 'epochinfo', 'yes');
EEG = pop_epoch( EEG, {  '1' ,'2' }, [-0.5  0.8], 'epochinfo', 'yes');

EEG = pop_rmbase( EEG, [-500 0] ,[]);


EEGs = pop_selectevent( EEG, 'type',1,'deleteevents','off','deleteepochs','on','invertepochs','off');
EEGt = pop_selectevent( EEG, 'type',2,'deleteevents','off','deleteepochs','on','invertepochs','off');
% EEGbela = pop_selectevent( EEG, 'type',{'SoundOnset'},'deleteevents','off','deleteepochs','on','invertepochs','off');

% figure; pop_plottopo(EEGt, [1:8] , '', 0, 'ydir',1);
% figure; pop_plottopo(EEGs, [1:8] , '', 0, 'ydir',1);
% figure; pop_plottopo(EEGbela, [1:8] , '', 0, 'ydir',1);

figure;
for k=1:8
subplot(4,2,k)
plot(mean(EEGt.data(k,:,:),3))
end
figure; 
subplot(221)
plot(EEGt.times,mean(EEGt.data,3)','r' )
title([num2str(EEGt.trials) ' Target Sounds'])
xlim([-100 800])
ylim([-8 8])
box off
subplot(222)
plot(EEGs.times,mean(EEGs.data,3)','b' )
box off
title([num2str(EEGs.trials) ' Standard Sounds'])
legend({'Target','Standard'},'Location' ,'NorthWest')
ylim([-8 8])
xlim([-100 800])
box off

subplot(2,2,[3 4])
hold on
plot(EEGt.times,mean(mean(EEGt.data(2:3,:,:),1)-mean(EEGt.data([5 6 ],:,:),1)     ,3)','r' )
plot(EEGs.times,mean(mean(EEGs.data(2:3,:,:),1)-mean(EEGs.data([5 6 ],:,:),1)     ,3)','b' )
title(['Difference Channel (2+3)/2 - (5+6)/2 '])

xlim([-100 800])
set(gcf,'Color','w')

%%
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%%EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\LSL_Oddball.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});

[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
ch7=EEG.data(7,:);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',30,'plotfreqz',1);
EEG.data(7,:)=ch7;

[EEG] = convertAudioToEvents(EEG,2000)
EEG = pop_epoch( EEG, {  '1' ,'2','SoundOnset' }, [-0.5  0.8], 'epochinfo', 'yes');
%EEG = pop_epoch( EEG, {  '1' ,'2' }, [-0.5  0.8], 'epochinfo', 'yes');

EEG = pop_rmbase( EEG, [-500 0] ,[]);

EEGs = pop_selectevent( EEG, 'type',1,'deleteevents','off','deleteepochs','on','invertepochs','off');
EEGt = pop_selectevent( EEG, 'type',2,'deleteevents','off','deleteepochs','on','invertepochs','off');
EEGbela = pop_selectevent( EEG, 'type',{'SoundOnset'},'deleteevents','off','deleteepochs','on','invertepochs','off');

figure; pop_plottopo(EEGt, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGs, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGbela, [1:8] , '', 0, 'ydir',1);

figure;
for k=1:8
subplot(4,2,k)
hold all
plot(EEGs.times, mean(EEGs.data(k,:,:),3))
plot(EEGs.times, mean(EEGt.data(k,:,:),3))
%plot(EEGs.times, mean(EEGbela.data(k,:,:),3))

end
figure; 
subplot(221)
plot(EEGt.times,-1*mean(EEGt.data,3)','r' )
title([num2str(EEGt.trials) ' Target Sounds'])
xlim([-100 800])
ylim([-8 8])
box off
subplot(222)
plot(EEGs.times,-1*mean(EEGs.data,3)','b' )
box off
title([num2str(EEGs.trials) ' Standard Sounds'])
legend({'Target','Standard'},'Location' ,'NorthWest')
ylim([-8 8])
xlim([-100 800])
box off

subplot(2,2,[3 4])
hold on
plot(EEGt.times,mean(mean(EEGt.data(2:3,:,:),1)-mean(EEGt.data([5 6 ],:,:),1)     ,3)','r' )
plot(EEGs.times,mean(mean(EEGs.data(2:3,:,:),1)-mean(EEGs.data([5 6 ],:,:),1)     ,3)','b' )
title(['Difference Channel (2+3)/2 - (5+6)/2 '])

xlim([-100 800])
set(gcf,'Color','w')

%%
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%%EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\LSL_Oddball.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
for k=1:numel(EEG.event)
    EEG.event(k).latency=EEG.event(k).latency+57;
end

[EEG] = convertAudioToEvents(EEG,2000)

%%
EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\LSL_Oddball_bela.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
ch7=EEG.data(7,:);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'plotfreqz',0);
EEG.data(7,:)=ch7;
[EEGs] = regressTriggerOut(EEG)
%%
EEGs = pop_epoch( EEG, {  '1'  }, [-0.5  0.8], 'epochinfo', 'yes');
EEGt = pop_epoch( EEG, {  '2' }, [-0.5  0.8], 'epochinfo', 'yes');
%EEGbela = pop_epoch( EEG, {  'SoundOnset' }, [-0.5  0.8], 'epochinfo', 'yes');
EEGs = pop_rmbase( EEGs, [-500 0] ,[]);
EEGt = pop_rmbase( EEGt, [-500 0] ,[]);
%EEGbela = pop_rmbase( EEGbela, [-500 0] ,[]);


figure; pop_plottopo(EEGt, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGs, [1:8] , '', 0, 'ydir',1);
%figure; pop_plottopo(EEGbela, [1:8] , '', 0, 'ydir',1);

figure;
for k=1:8
subplot(4,2,k)
hold all
plot(EEGs.times, mean(EEGs.data(k,:,:),3))
plot(EEGs.times, mean(EEGt.data(k,:,:),3))
%plot(EEGs.times, mean(EEGbela.data(k,:,:),3))

end
figure; 
subplot(221)
plot(EEGt.times,-1*mean(EEGt.data,3)','r' )
title([num2str(EEGt.trials) ' Target Sounds'])
xlim([-100 800])
ylim([-8 8])
box off
subplot(222)
plot(EEGs.times,-1*mean(EEGs.data,3)','b' )
box off
title([num2str(EEGs.trials) ' Standard Sounds'])
legend({'Target','Standard'},'Location' ,'NorthWest')
ylim([-8 8])
xlim([-100 800])
box off

subplot(2,2,[3 4])
hold on
plot(EEGt.times,mean(mean(EEGt.data(2:3,:,:),1)-mean(EEGt.data([5 6 ],:,:),1)     ,3)','r' )
plot(EEGs.times,mean(mean(EEGs.data(2:3,:,:),1)-mean(EEGs.data([5 6 ],:,:),1)     ,3)','b' )
title(['Difference Channel (2+3)/2 - (5+6)/2 '])

xlim([-100 800])
set(gcf,'Color','w')
title('Without Belaboard Oddball')
saveas(gcf,'OddballWithoutBela.jpg')
%%
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%%EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\LSL_Oddball_bela.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
for k=1:numel(EEG.event)
    EEG.event(k).latency=EEG.event(k).latency+57;
end


[EEG] = convertAudioToEvents(EEG,2000)

ch7=EEG.data(7,:);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.01,'plotfreqz',0);
EEG.data(7,:)=ch7;
[EEG] = regressTriggerOut(EEG)

%ch7=EEG.data(7,:);
%EEG = pop_eegfiltnew(EEG, 'hicutoff',30,'plotfreqz',1);
%EEG.data(7,:)=ch7;

EEGs = pop_epoch( EEG, {  '1'  }, [-0.5  0.8], 'epochinfo', 'yes');
EEGt = pop_epoch( EEG, {  '2' }, [-0.5  0.8], 'epochinfo', 'yes');
EEGbela = pop_epoch( EEG, {  'SoundOnset' }, [-0.5  0.8], 'epochinfo', 'yes');
EEGs = pop_rmbase( EEGs, [-500 0] ,[]);
EEGt = pop_rmbase( EEGt, [-500 0] ,[]);
EEGbela = pop_rmbase( EEGbela, [-500 0] ,[]);


figure; pop_plottopo(EEGt, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGs, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGbela, [1:8] , '', 0, 'ydir',1);

figure;
for k=1:8
subplot(4,2,k)
hold all
plot(EEGs.times, mean(EEGs.data(k,:,:),3))
plot(EEGs.times, mean(EEGt.data(k,:,:),3))
plot(EEGs.times, mean(EEGbela.data(k,:,:),3))

end
figure; 
subplot(221)
plot(EEGt.times,-1*mean(EEGt.data,3)','r' )
title([num2str(EEGt.trials) ' Target Sounds'])
xlim([-100 800])
ylim([-8 8])
box off
subplot(222)
plot(EEGs.times,-1*mean(EEGs.data,3)','b' )
box off
title([num2str(EEGs.trials) ' Standard Sounds'])
legend({'Target','Standard'},'Location' ,'NorthWest')
ylim([-8 8])
xlim([-100 800])
box off

subplot(2,2,[3 4])
hold on
plot(EEGt.times,mean(mean(EEGt.data(2:3,:,:),1)-mean(EEGt.data([5 6 ],:,:),1)     ,3)','r' )
plot(EEGs.times,mean(mean(EEGs.data(2:3,:,:),1)-mean(EEGs.data([5 6 ],:,:),1)     ,3)','b' )
plot(EEGbela.times,mean(mean(EEGbela.data(2:3,:,:),1)-mean(EEGbela.data([5 6 ],:,:),1)     ,3)','y' )

title(['Difference Channel (2+3)/2 - (5+6)/2 '])

xlim([-100 800])
set(gcf,'Color','w')
title('With Belaboard Oddball')
saveas(gcf,'OddballWithBela.jpg')

%%
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
%%EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\sub-P001_ses-S001_task-Default_run-001_eeg.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
EEG = pop_loadxdf('C:\Users\messung\Documents\CurrentStudy\sub-P001\ses-S001\eeg\LSL_Multisource.xdf' , 'streamtype', 'ExG', 'exclude_markerstreams', {});
for k=1:numel(EEG.event)
    EEG.event(k).latency=EEG.event(k).latency+57;
end


[EEG] = convertAudioToEvents(EEG,2000)

ch7=EEG.data(7,:);
EEG = pop_eegfiltnew(EEG, 'locutoff',0.1,'hicutoff',30,'plotfreqz',1);
EEG.data(7,:)=ch7;

EEGs = pop_epoch( EEG, {  '1'  }, [-0.5  0.8], 'epochinfo', 'yes');
EEGt = pop_epoch( EEG, {  '2' }, [-0.5  0.8], 'epochinfo', 'yes');
EEGbela = pop_epoch( EEG, {  'SoundOnset' }, [-0.5  0.8], 'epochinfo', 'yes');
EEGs = pop_rmbase( EEGs, [-500 0] ,[]);
EEGt = pop_rmbase( EEGt, [-500 0] ,[]);
EEGbela = pop_rmbase( EEGbela, [-500 0] ,[]);


figure; pop_plottopo(EEGt, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGs, [1:8] , '', 0, 'ydir',1);
figure; pop_plottopo(EEGbela, [1:8] , '', 0, 'ydir',1);

figure;
for k=1:8
subplot(4,2,k)
hold all
plot(EEGs.times, mean(EEGs.data(k,:,:),3))
plot(EEGs.times, mean(EEGt.data(k,:,:),3))
plot(EEGs.times, mean(EEGbela.data(k,:,:),3))

end
figure; 
subplot(221)
plot(EEGt.times,-1*mean(EEGt.data,3)','r' )
title([num2str(EEGt.trials) ' Target Sounds'])
xlim([-100 800])
ylim([-8 8])
box off
subplot(222)
plot(EEGs.times,-1*mean(EEGs.data,3)','b' )
box off
title([num2str(EEGs.trials) ' Standard Sounds'])
legend({'Target','Standard'},'Location' ,'NorthWest')
ylim([-8 8])
xlim([-100 800])
box off

subplot(2,2,[3 4])
hold on
plot(EEGt.times,mean(mean(EEGt.data(2:3,:,:),1)-mean(EEGt.data([5 6 ],:,:),1)     ,3)','r' )
plot(EEGs.times,mean(mean(EEGs.data(2:3,:,:),1)-mean(EEGs.data([5 6 ],:,:),1)     ,3)','b' )
plot(EEGbela.times,mean(mean(EEGbela.data(2:3,:,:),1)-mean(EEGbela.data([5 6 ],:,:),1)     ,3)','y' )

title(['Difference Channel (2+3)/2 - (5+6)/2 '])

xlim([-100 800])
set(gcf,'Color','w')
title('With Belaboard Multisource')
saveas(gcf,'OddballMultisourceWithBela.jpg')
