function fp_pac_sim(params)

% define folders for saving results
DIROUT = '/home/bbci/data/haufe/Franziska/data/pac_sim/';
if ~exist(DIROUT);mkdir(DIROUT); end
DIROUT1 = '/home/bbci/data/haufe/Franziska/data/pac_save/';
if ~exist(DIROUT1);mkdir(DIROUT1); end


%% signal generation
tic
% getting atlas, voxel and roi indices; active voxel of each region
% is aleady selected here
fprintf('Getting atlas positions... \n')
D = fp_get_Desikan(params.iReg);

%signal generation
fprintf('Signal generation... \n')
[sig,brain_noise,sensor_noise,L,iroi_phase, iroi_amplt,D, fres, n_trials,filt] = ...
    fp_pac_signal(params,D);

%combine noise sources
noise = params.iss*brain_noise + (1-params.iss)*sensor_noise;
noise_f = (filtfilt(filt.bband_all, filt.aband_all, noise'))';
noise = noise ./ norm(noise_f, 'fro');
%combine signal and noise
signal_sensor1 = params.isnr*sig + (1-params.isnr)*noise;
signal_sensor_f = (filtfilt(filt.bband_all, filt.aband_all, signal_sensor1'))';
signal_sensor1 = signal_sensor1 ./ norm(signal_sensor_f, 'fro');

%high-pass signal
signal_sensor = (filtfilt(filt.bhigh, filt.ahigh, signal_sensor1'))';
signal_sensor = signal_sensor / norm(signal_sensor, 'fro');

%reshape
signal_sensor = reshape(signal_sensor,[],size(signal_sensor,2)/n_trials,n_trials);
[n_sensors, l_epoch, n_trials] = size(signal_sensor);

t.signal = toc;

%% shuffling for shabazi method 

% [Amix,W] = fastica(signal_sensor(:,:));
% Amix = inv(W);
% 
% for iroi = 1:D.nroi
%     %get filtered signal in high and low band
%     [high_signal, low_signal] = preproc_filt_sim(squeeze(signal_sensor(iroi,:,:)), fres, filt.low, filt.high);
%     
%     %hilbert transform
%     high_signal_hlb(iroi,:,:) = hilbert(high_signal);
%     low_signal_hlb(iroi,:,:)  = hilbert(low_signal);
% end
% 
% %get to IC space
% unmixed_high = W*high_signal_hlb;
% unmixed_low = W*low_signal_hlb;
% 
% % no shuffling for true pac values

%% leadfield and inverse solution

tic

%select only voxels that belong to any roi
L_backward = L(:, D.ind_cortex, :);
ndim = size(L_backward,3);

%construct source filter
if strcmp(params.ifilt,'l') %lcmv (default)
    
    cCS = cov(signal_sensor(:,:)');
    reg = 0.05*trace(cCS)/length(cCS);
    Cr = cCS + reg*eye(size(cCS,1));
    
    [~, A] = lcmv(Cr, L_backward, struct('alpha', 0, 'onedim', 0));
    A = permute(A,[1, 3, 2]);   
end

t.filter = toc;


%% Dimensionality reduction 

tic
ipip = 1;
clear npcs
signal_roi = [];

%loop over regions
for aroi = 1:D.nroi
    
    clear A_ signal_source    
    A_ = A(:, :,D.ind_roi_cortex{aroi},:);
    
    %number of voxels at the current roi
    nvoxroi(aroi) = size(A_,3);
    A2{aroi} = reshape(A_, [n_sensors, ndim*nvoxroi(aroi)]);
    
    %project sensor signal to voxels at the current roi (aroi)
    signal_source = A2{aroi}' * signal_sensor(:,:);
    
    %zscoring
    signal_source = zscore(signal_source')'; %%%%%leave this out?????
    
    %do PCA
    clear signal_roi_ S
    [signal_roi_,S,~] = svd(double(signal_source(:,:))','econ');
    
    %fixed number of pcs
    npcs(aroi) = ipip;
    
    %bring signal_roi to the shape of npcs x l_epoch x n_trials
    signal_roi = cat(1,signal_roi,reshape((signal_roi_(:,1:npcs(aroi)))',[],l_epoch,n_trials));
    
end

t.dimred= toc;

%% calculate true PAC scores

%standard pac
tic
pac_standard = fp_pac_standard(signal_roi, filt.low, filt.high, fres);
t.standard = toc;

%ortho pac
tic
[signal_ortho, ~, ~, ~] = symmetric_orthogonalise(signal_roi(:,:)', 1);
signal_ortho = reshape(signal_ortho',D.nroi,l_epoch,n_trials);
pac_ortho = fp_pac_standard(signal_ortho, filt.low, filt.high, fres);
t.ortho = toc;

%shabazi
tic
% pac_shab = fp_pac_shabazi(unmixed_low, unmixed_high,Amix);
t.shabazi = toc;

% bispectra 
tic
[b_orig, b_anti] = fp_pac_bispec(signal_roi,fres,filt);
t.bispec = toc;

%% Evaluate

[pr_standard] = fp_mrr_hk_short(pac_standard,iroi_amplt,iroi_phase,0);
[pr_ortho] = fp_mrr_hk_short(pac_ortho,iroi_amplt,iroi_phase,0);
[pr_shabazi] = fp_mrr_hk_short(pac_shab,iroi_amplt,iroi_phase,0);
[pr_bispec_o] = fp_mrr_hk_short(b_orig,iroi_amplt,iroi_phase,0);
[pr_bispec_a] = fp_mrr_hk_short(b_anti,iroi_amplt,iroi_phase,0);

%% Saving
fprintf('Saving... \n')
%save all
outname = sprintf('%spac_%s.mat',DIROUT,params.logname);
save(outname,'-v7.3')

%save only evaluation parameters
outname1 = sprintf('%spr_%s.mat',DIROUT,params.logname);
save(outname1,...
    'pr_standard','pr_ortho','pr_shabazi','pr_bispec_o','pr_bispec_a','t',...
    '-v7.3')

