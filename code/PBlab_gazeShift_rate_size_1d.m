function [data_output, bin_range_output] = PBlab_gazeShift_rate_size_1d(cfg, shift_input, trialinfo)

% Description: output the data to plot figure of gaze shift rate x shift size 
%
% for more detail 
% shift_input = shift data: time vector for gaze shift data (can be got by PBlab_gazepos2shift_1D function)
% trial_info = condition triggers for each trial;
% data_output = shift size x shift rate: matrix shift size x shift rate)
% time_input = time vector in gaze position data
% time_output = time vector for gaze shift data
%
% cfg should contain:
% cfg.size_range    = number; the whole range of saccade size you want to check
% cfg.binWin        = window size; the slideing window for defining different saccade magnitude 
% cfg.binstep       = the move step 

% cfg could contain:\
% cfg.slideWin4rate       = number (default is 50 ms); the sliding timewindow used to caculate shift rate


% Baiwei Liu and Freek van Ede | Proactive Brain lab | Amsterdam | 2021 

% set default value, if user did not specify
if isfield(cfg,  'slideWin4rate');     else cfg.slideWin4rate = 50; end

% get parameters 
size_range = cfg.size_range;
binWin = cfg.binWin;
binstep = cfg.binstep;
slideWin4rate = cfg.slideWin4rate;
trigs_left = cfg.trigs_left;
trigs_right = cfg.trigs_right;

%% caculate the bin of shift size
binStart = size_range(1) + binWin/2;
binEnd = size_range(2) - binWin/2;
binRange =[binStart: binstep:binEnd];
numBin = length(binRange);

%% 
binHz_to = NaN(numBin, size(shift_input,2));
binHz_aw = NaN(numBin, size(shift_input,2));

% loop through the each bin
for binInd = 1:numBin

    shift = shift_input;
    
    % get the range of shift size in current bin
    minValue = binRange(binInd) -  binWin/2;
    maxValue = binRange(binInd) +  binWin/2;
    
    % remove the shift whose size is not in this bin range
    shift(abs(shift)<=minValue) = 0;
    shift(abs(shift)>=maxValue) = 0;
    
    % caculated shift rate
    
    % select left and right trial 
    sel_left = ismember(trialinfo,trigs_left);
    sel_right = ismember(trialinfo,trigs_right);
    
    % select left and right shift 
    shift_left = shift < 0; 
    shift_right = shift >0;
    
    % get toward and away saccade
    toward = (mean(shift_left(sel_left,:)) + mean(shift_right(sel_right,:))) ./ 2;
    away = (mean(shift_left(sel_right,:)) + mean(shift_right(sel_left,:))) ./ 2;
    
    % get the shift rate through movemean method
    toward_rate = smoothdata(toward,2,'movmean',slideWin4rate)*1000;
    away_rate = smoothdata(away,2,'movmean',slideWin4rate)*1000;

    binHz_to(binInd,:) = toward_rate;
    binHz_aw(binInd,:)= away_rate;
end

% caculated the difference bewteen toward_rate and away_rate
binHz_diff = binHz_to - binHz_aw;

% set the output data
data_output.toward = binHz_to;
data_output.away = binHz_aw;
data_output.diff = binHz_diff;

bin_range_output = binRange;
