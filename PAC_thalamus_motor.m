
% Reference: 
% [1] Roux, Frédéric, et al. "The phase of thalamic alpha activity modulates cortical gamma-band activity: evidence from     
% resting-state MEG recordings." Journal of Neuroscience 33.45 (2013): 17827-17835.
% [2] De Hemptinne, Coralie, et al. "Therapeutic deep brain stimulation reduces cortical phase-amplitude coupling in 
% Parkinson's disease." Nature neuroscience 18.5 (2015): 779.
% [3] Swann, Nicole C., et al. "Elevated synchrony in Parkinson disease detected with electroencephalography." Annals of 
% neurology 78.5 (2015): 742-750.
% [4] Cole, Scott R., et al. "Nonsinusoidal beta oscillations reflect cortical pathophysiology in Parkinson's disease." 
% Journal of Neuroscience (2017): 2208-16.
% [5] Olde Dubbelink, Kim TE, et al. "Disrupted brain network topology in Parkinson’s disease: a longitudinal 
% magnetoencephalography study." Brain 137.1 (2013): 197-207.
% [6] Hillebrand, Arjan, et al. "Direction of information flow in large-scale resting-state networks is frequency-dependent." 
% Proceedings of the National Academy of Sciences 113.14 (2016): 3867-3872.

clear;clc;

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% Add the path of PACtools
PACtool_path = '/Users/ke/toolbox/PAC/PACtool';
addpath(PACtool_path,'-end');

%% MEG data
% Root directory of MEG file
meg_root_path = '/Users/ke/OneDrive - UHN/MEG';
result_root_path = 'PAC_lcmv';

% Subpath of PD patients
group = 'PD';
subjects = {'PD_D', 'PD_E', 'PD_F', 'PD_G', 'PD_A', 'PD_H', 'PD_J', 'PD_K', 'PD_L','PD_M', 'PD_O', 'PD_P', 'PD_Q', 'PD_R'};
states = {'Off', 'On'}; 

% Subpath of health controls
% group = 'OC';
% subjects = {'OC_B', 'OC_C', 'OC_D', 'OC_F', 'OC_G', 'OC_H', 'OC_K', 'OC_L', 'OC_N', 'OC_O', 'OC_P', 'OC_Q', 'OC_R', 'OC_S'};
% states = {''};

meg_file = 'ECLOS_tsss_mc_clean.mat';
source_file = 'source_lcmv_ROI90.mat';


%% Region of interesting
ROI_label = {'Precentral_L','Precentral_R','Thalamus_L','Thalamus_R'};
ROI_idx   = zeros(length(ROI_label),1);
load('template_ROI_AAL90.mat'); 
for i = 1:length(ROI_label)
    idx = find(strcmp(ROI_label{i}, template_ROI.label));
    if isempty(idx)
        error('ROI does not exist!\n');
    else
        ROI_idx(i) = idx;
    end   
end

% ROI combination for PAC calculation
comb = [1 1; 2 2; 3 3; 4 4; 1 3; 3 1; 2 4; 4 2];
ncomb = length(comb);


%% Parameters setting for PAC
fp = [4 40];
fa = [20 200];
dp = 2;
da = 4;
pha_filt = 'morlet';
amp_filt = 'morlet';
pac_method = 'mi_tort';

% Phase frequency [13 30] Hz
ph_freq_vec = [fp(1):dp:fp(2)];
npf = length(ph_freq_vec)-1;
pf_idx1 = find(ph_freq_vec >= 13, 1, 'first');
pf_idx2 = find(ph_freq_vec <= 30, 1, 'last');

% Amplitude frequency [50 150] Hz
amp_freq_vec = [fa(1):da:fa(2)];
naf = length(amp_freq_vec)-1;
af_idx1 = find(amp_freq_vec >= 50, 1, 'first');
af_idx2 = find(amp_freq_vec <= 150, 1, 'last');

%% Cacluate PAC for each subject
for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
        % Load MEG and spatial filter
        load(fullfile(meg_root_path, group, subject, state, meg_file));     % clean MEG data
        load(fullfile(meg_root_path, group, subject, state, source_file));  % source filter
        
        ntrials = length(meg_clean.trial);
        nsamples = size(meg_clean.trial{1},2);
        nROI = length(ROI_label);
        fs = meg_clean.fsample;
        
        % Extract source signal for each ROI
        source_sig = [];
        source_sig.label = ROI_label;
        source_sig.fsample = fs;
        for k = 1:ntrials
            source_sig.time{k} = meg_clean.time{k};
            for r = 1:nROI
                source_sig.trial{k}(r, :) = source.avg.filter{ROI_idx(r)} * meg_clean.trial{k}(:, :);
            end
        end
        
        % Arrange data for PAC calculation
        data = zeros(nsamples, ntrials, nROI);
        for r = 1:nROI
            for k = 1:ntrials
                data(:,k,r) = source_sig.trial{k}(r, :)';
            end
        end
        
        % Calculate PAC between all the combinations of low-frequency bands and high-frequency bands
        comod = cell(ncomb, 1);
        label = cell(ncomb, 1);
        for c = 1:ncomb
            sig_mod = data(:,:,comb(c,1));
            sig_pac = data(:,:,comb(c,2));
            comod{c} = comodulogram(sig_mod, sig_pac, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            
            label{c} = [ROI_label{comb(c,1)} '(phase)-' ROI_label{comb(c,2)} '(amplitude) coupling'];                      
        end             
        
        % Averaging MI values over the beta range (13–30Hz) for the phase frequency, 
        % and the broadband gamma range (50–150Hz) for the amplitude frequency.  
        pac = zeros(ncomb, 1);
        for c = 1:ncomb
            pacmat = comod{c};
            pac(c) = mean(mean(pacmat(af_idx1:af_idx2, pf_idx1:pf_idx2),1),2);
        end 
               
        % Save result
        folder = fullfile(result_root_path, group, subject, state);
        mkdir(folder);
        save(fullfile(folder, 'PAC_Tha_M1.mat'), 'comod', 'pac', 'label'); 
    end
end
