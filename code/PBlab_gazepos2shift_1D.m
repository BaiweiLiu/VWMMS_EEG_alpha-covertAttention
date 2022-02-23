function [data_output,time_output] = PBlab_gazepos2shift_1D(cfg, data_input, time_input)

% Description: convert gaze position into gaze shift, considering gaze position along aling one axis (e.g. x or y).

% This code was originally developed and used for the analyses presented in:
% "Functional but not obligatory link between microsaccades and neural modulation by covert spatial attention" Baiwei Liu, Anna C. Nobre, Freek van Ede

% for more detail 
% data_input = eye_data:  matrix trial x time
% data_output = eye_shift: matrix trial x time (0 means the no gaze shift, the value other 0 means the displacement (position after shift minus position before shift))
% time_input = time vector in gaze position data
% time_output = time vector for gaze shift data
%
% cfg can contain:
% cfg.smooth_der    = 'true' or 'false' (default = 'true'); whether to smooth velocity data
% cfg.smooth_step   = number (default = 7); length of gaussian smoothing window, in samples (i.e. if Fs = 1000, smooth_step=7 equals 7 ms)
% cfg.winbef        = time range (default = [50 0]); time window for detecting gaze postion before threshold crossing, in samples
% cfg.winaft        = time range  (default = [50 100]); time window for detecting gaze postion after threshold crossing, in samples
% cfg.minISI        = number (default = 100); the minimal time after threshold crossing before considering the next possible gaze shift (and to avoid counting the same shift multiple times)
% cfg.threshold     = number (default = 5); the velocity threshold (n*median velocity) for detecting gaze shifts 
%
% Baiwei Liu and Freek van Ede | Proactive Brain lab | Amsterdam | 2021 
% changed by Baiwei 2021.dec.11

% set default value, if user did not specify
if isfield(cfg,  'smooth_der');     else cfg.smooth_der = true; end
if isfield(cfg,  'smooth_step');    else cfg.smooth_step = 7;   end
if isfield(cfg,  'winbef');         else cfg.winbef = [50 0];   end
if isfield(cfg,  'winaft');         else cfg.winaft = [50 100]; end
if isfield(cfg,  'minISI');         else cfg.minISI = 100;      end
if isfield(cfg,  'threshold');      else cfg.threshold = 5;     end
% creat data 
data = [];
data.gaze_raw = squeeze(data_input);

%% get  derivative to turn to velocity, and possibly smooth velocity profile
% velocity
data.der = diff(data.gaze_raw,1,2);
data.absder = abs(data.der);
if cfg.smooth_der
    data.der_sm = smoothdata(data.der,2,'gaussian',cfg.smooth_step);
    data.absder_sm = smoothdata(data.absder,2,'gaussian', cfg.smooth_step);
else
    data.der_sm = data.der;
    data.absder_sm = data.absder;
end
%% Mark gaze shifts and their size at threshold crossings
gaze_shift = zeros(size(data.gaze_raw)); % start with matrix with zeros

for i = 1:size(data.gaze_raw,1)
        
    med1 = nanmedian(data.absder_sm(i,:));
    
    % set data to use        
    dat2use = data.absder_sm(i,:); % velocity data
    datorig = data.gaze_raw(i,:);  % position data    
    ntime = size(dat2use,2);       % number of time samples per trial  
    
    usabletimevec = (cfg.winbef(1)+1):(ntime-cfg.winaft(2));
    for t = usabletimevec;  % loop over all usable time points, taking into account that we need a window before and after threshold crossings to extract shift size;         
        
        if dat2use(t) >= med1 * cfg.threshold;  % find threshold crossing
            
            % get position before and after
            dbef = nanmean(datorig([(t-cfg.winbef(1)):(t-cfg.winbef(2))])); % data before
            daft = nanmean(datorig([(t+cfg.winaft(1)):(t+cfg.winaft(2))])); % data after          
            gaze_shift(i, t) = daft - dbef;
            
            % set minimal delay before allowing threshold crossing again
            if t+ cfg.minISI > ntime                 dat2use(t+1:end) = 0; % if min ISI beyond available window, fill with zeros til end. Else, fill zeros min ISI.
            else dat2use(t+1:t+ cfg.minISI) = 0; 
            end 
            
        end
    end
end

data_output = gaze_shift(:,usabletimevec);
time_output = time_input(usabletimevec);