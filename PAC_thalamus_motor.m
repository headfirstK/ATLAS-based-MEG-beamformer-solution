
% Reference patper: The Phase of Thalamic Alpha Activity Modulates Cortical
% Gamma-Band Activity: Evidence from Resting-State MEG Recordings

clear;clc;

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% Add the path of PACtools
PACtool_path = '/Users/ke/toolbox/PAC/PACtool';
addpath(PACtool_path,'-end');

%% MEG data
% Root directory of MRI file
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

%% Parameters setting for PAC
fp = [4 40];
fa = [20 200];
dp = 2;
da = 4;
width = 7;
measure = 'mi';
ph_freq_vec = [fp(1):dp:fp(2)];
amp_freq_vec = [fa(1):da:fa(2)];
npf = length(ph_freq_vec)-1;
naf = length(amp_freq_vec)-1;


%% Cacluate PAC for each subject
for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
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
        
%         cfg                 = [];
%         cfg.hpfilter        = 'yes';
%         cfg.hpfreq          = 13;      
%         cfg.hpfiltord       = 4;
%         source_sig          = ft_preprocessing(cfg, source_sig);
        
        pac_M1_l = zeros(naf,npf,ntrials);
        pac_M1_r = zeros(naf,npf,ntrials);
        pac_Tha_l = zeros(naf,npf,ntrials);
        pac_Tha_r = zeros(naf,npf,ntrials);
        pac_Tha_M1_l = zeros(naf,npf,ntrials);
        pac_M1_Tha_l = zeros(naf,npf,ntrials);
        pac_Tha_M1_r = zeros(naf,npf,ntrials);
        pac_M1_Tha_r = zeros(naf,npf,ntrials);
        for k = 1:ntrials
            source_M1_l    = source_sig.trial{k}(1, :)';
            source_M1_r    = source_sig.trial{k}(2, :)';
            source_Tha_l   = source_sig.trial{k}(3, :)';
            source_Tha_r   = source_sig.trial{k}(4, :)';
            
            % Calculate PAC between thalamic and motor cortex
            pac_M1_l(:,:,k) = PACgraph(source_M1_l, source_M1_l, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            pac_M1_r(:,:,k) = PACgraph(source_M1_r, source_M1_r, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            
            pac_Tha_l(:,:,k) = PACgraph(source_Tha_l, source_Tha_l, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            pac_Tha_r(:,:,k) = PACgraph(source_Tha_r, source_Tha_r, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            
            pac_Tha_M1_l(:,:,k) = PACgraph(source_Tha_l, source_M1_l, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            pac_M1_Tha_l(:,:,k) = PACgraph(source_M1_l, source_Tha_l, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            
            pac_Tha_M1_r(:,:,k) = PACgraph(source_Tha_r, source_M1_r, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
            pac_M1_Tha_r(:,:,k) = PACgraph(source_M1_r, source_Tha_r, fs, ph_freq_vec, amp_freq_vec,'morlet','morlet','mi_tort');
        end
        
        
        %% Save result
        folder = fullfile(result_root_path, group, subject, state);
        mkdir(folder);
        save(fullfile(folder, 'PAC_Tha_M1.mat'), 'source_sig', ...
            'pac_M1_l', 'pac_M1_r', 'pac_Tha_l', 'pac_Tha_r',...
            'pac_Tha_M1_l','pac_M1_Tha_l','pac_Tha_M1_r','pac_M1_Tha_r',...
            'ph_freq_vec','amp_freq_vec'); 
    end
end
