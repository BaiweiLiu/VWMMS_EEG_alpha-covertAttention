%% It's always good to start with a clean sheet
clc, clear, close all, warning('off','all')

%% set project name
projectname = 'detect gaze shift (microsaccade) from gaze position';

%% prepare Toolbox
parent_folder = '/Users/baiweil/AnalysisDesk/shared_code/';
cd(parent_folder)

%% Set directions
write_dir_eye = creatDir([parent_folder 'normalized_eye_data']);
write_dir_eeg = creatDir([parent_folder 'eeg_tf']);
write_dir_fig = creatDir([write_dir_eeg filesep 'figures']);

%% get gaze shift
subjList =  get_subFiles(write_dir_eye);
output_dir = creatDir([parent_folder 'gaze_shift']);
for subjInd = 1:length(subjList)
    load(subjList{subjInd})
    
    % get data in x axis
    data_shift =[];
    eye_dataX = squeeze(eye_data.trial(:,1,:)); % it is gaze position data (trials X time)?
    
    % get gaze shift 
    cfg = [];
    cfg.threshold = 3;
    [eye_shift,eye_velocity,time_shift] = PBlab_gazepos2shift_1D(cfg, eye_dataX, eye_data.time);
    
    data_shift.shift = eye_shift;
    data_shift.time = time_shift;
    data_shift.trialinfo = eye_data.trialinfo;
    
    % save data
    save([output_dir filesep subjList{subjInd}(end-7:end)] ,'data_shift')
end

%% plot gaze magnitude x shift size figure
sublist_shift = get_subFiles([parent_folder 'gaze_shift']);
outfile_dir = creatDir([parent_folder 'results']);

for subjInd = 1:length(sublist_shift)
    load(sublist_shift{subjInd})
    
    cfg = [];
    cfg.size_range = [1 110];
    cfg.binWin = 5;
    cfg.binstep = 1;
    cfg.trigs_left = [21 22];
    cfg.trigs_right = [23 24];
    [rate_size,bin_range]=PBlab_gazeShift_rate_size_1d(cfg, data_shift.shift, data_shift.trialinfo);
    
    GA_struct.toward(subjInd,:,:) = rate_size.toward;
    GA_struct.away(subjInd,:,:) = rate_size.away;
    GA_struct.diff(subjInd,:,:) = rate_size.diff;
end

GA_struct.bin_range = bin_range;
GA_struct.time = data_shift.time;

% save the group data
save([outfile_dir filesep 'GA_shift_rateAndsize'] ,'GA_struct')

%% example of plotting the figure
cmap = brewermap([],'*RdBu');
xli = [-0.2 1];
figure('position', [100 100 1200 300])
subplot(1,3,1)
% difference figure

hz2plot= squeeze(nanmean(GA_struct.diff,1));
contourf(GA_struct.time,GA_struct.bin_range,hz2plot,50,'linecolor','none')
maxValue = max(max(max(hz2plot)), abs(min(min(hz2plot)))); 
caxis([-maxValue maxValue])
colorbar
colormap(cmap);
xlabel('time (s)')
ylabel('shift size')
title('Toward - Away')
hold on
plot([0 0], [GA_struct.bin_range(1), GA_struct.bin_range(end)], '--k')
xlim(xli)

% toward
subplot(1,3,2)
hz2plot= squeeze(nanmean(GA_struct.toward,1));
contourf(GA_struct.time,GA_struct.bin_range,hz2plot,50,'linecolor','none')
maxValue = max([max(max(squeeze(nanmean(GA_struct.toward,1)))) max(max(squeeze(nanmean(GA_struct.away,1))))]);

caxis([-maxValue maxValue])
colorbar
colormap(cmap);
xlabel('time (s)')
ylabel('shift size')
title('Toward')
hold on
plot([0 0], [GA_struct.bin_range(1), GA_struct.bin_range(end)], '--k')
xlim(xli)

% away
subplot(1,3,3)
hz2plot= squeeze(nanmean(GA_struct.away,1));
contourf(GA_struct.time,GA_struct.bin_range,hz2plot,50,'linecolor','none')
caxis([-maxValue maxValue])
colorbar
colormap(cmap);
xlabel('time (s)')
ylabel('shift size')
title('away')
hold on
plot([0 0], [GA_struct.bin_range(1), GA_struct.bin_range(end)], '--k')
xlim(xli)
