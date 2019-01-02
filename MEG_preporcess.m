

clear;clc;

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% Prepare data file
meg_root_path = '/Users/ke/OneDrive - UHN/MEG';

% group = 'PD';
% subjects = {'PD_A', 'PD_D', 'PD_E', 'PD_F', 'PD_G', 'PD_H', 'PD_K', 'PD_L','PD_M', 'PD_O', 'PD_P', 'PD_Q', 'PD_R'};
% states = {'Off', 'On'};

group = 'OC';
subjects = {'OC_B', 'OC_C', 'OC_D', 'OC_F', 'OC_G', 'OC_H', 'OC_K', 'OC_L', 'OC_N', 'OC_O', 'OC_P', 'OC_Q', 'OC_R', 'OC_S'};
states = {''};


file_name = 'ECLOS_tsss_mc.fif';

%% Preprocess
for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
        meg_data_file = fullfile(meg_root_path, group, subject, state, file_name); 
        
        % Read the data from disk and segment it into 5-second pieces
        cfg = [];
        cfg.dataset                 = meg_data_file;
        cfg.channel                 = {'MEGGRAD'};
        cfg.trialfun                = 'ft_trialfun_general';
        cfg.trialdef.triallength    = 8;                 % duration in seconds
        cfg.trialdef.ntrials        = inf;               % number of trials, inf results in as many as possible
        cfg                         = ft_definetrial(cfg);
        
        cfg.bsfilter        = 'yes';
        cfg.bsfreq          = [57 63;117 123;177 183];      
        cfg.bsfiltord       = 4; 
        cfg.bpfilter        = 'yes';
        cfg.bpfreq          = [1 200];      
        cfg.bpfiltord       = 4; 
        meg_trials          = ft_preprocessing(cfg);
        
        % Reject bad trials
        cfg             = [];
        cfg.method      = 'trial';
        %cfg.channel     = 'MEG';
        cfg.alim        = 5e-11;
        % cfg.gradscale   = 1;
        % cfg.magscale    = 1/0.04;
        meg_clean1   = ft_rejectvisual(cfg, meg_trials);
        
        % Reject bad sensors
        cfg             = [];
        cfg.method      = 'channel';
        cfg.alim        = 5e-11;
        meg_clean2   = ft_rejectvisual(cfg, meg_clean1);
        clear meg_clean1
        
        % Reject bad trials/sensors
        cfg          = [];
        cfg.method   = 'summary';
        cfg.alim     = 5e-11;
        meg_clean        = ft_rejectvisual(cfg,meg_clean2);
        clear meg_clean2
        save(fullfile(meg_root_path, group, subject, state, [file_name(1:end-4) '_clean.mat']), 'meg_clean');
    end
end

