% Localizing sources using beamformer techniques

clear;clc

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults


%% Prepare data file
% meg_root_path = '/Users/ke/OneDrive - UHN/MEG';
meg_root_path = 'rsMEG';
mri_root_path = '/Users/ke/OneDrive - UHN/MRI';

% Subpath of PD patients
group = 'PD';
subjects = {'PD_A', 'PD_D', 'PD_E', 'PD_F', 'PD_G', 'PD_H', 'PD_J', 'PD_K', 'PD_L','PD_M', 'PD_O', 'PD_P', 'PD_Q', 'PD_R'};
states = {'Off', 'On'};

% Subpath of health controls
% group = 'OC';
% subjects = {'OC_B', 'OC_C', 'OC_D', 'OC_F', 'OC_G', 'OC_H', 'OC_K', 'OC_L', 'OC_N', 'OC_O', 'OC_P', 'OC_Q', 'OC_R', 'OC_S'};
% states = {''};

file_name = 'ECLOS_tsss_mc_clean.mat';


%% Source reconstruction for each subject during each state
for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
        meg_data_file = fullfile(meg_root_path, group, subject, state, file_name);
        load(meg_data_file);
                
        % Computation of covariance matrix
        cfg                     = [];
        cfg.trials              = 'all'; 
        cfg.covariance          = 'yes';
        cfg.covariancewindow    = 'all';
        cfg.removemean          = 'yes';
        timelock                = ft_timelockanalysis(cfg, meg_clean);
        
        % Load individual MRI, headmodel, and source model
        load(fullfile(mri_root_path, group, subject, state, 'mri_align.mat'));    % Individual aligned mri
        load(fullfile(mri_root_path, group, subject, state, 'vol.mat'));          % Individual volume model
        load(fullfile(mri_root_path, group, subject, state, 'ROI_AAL90.mat'));    % MNI-aligned individual grids
        
        % Compute the leadfield
        cfg             = [];
        cfg.grid        = grid;
        cfg.headmodel   = vol;
        cfg.normalize   = 'yes'; % to remove depth bias (Q in eq. 27 of van Veen et al, 1997)
        lf              = ft_prepare_leadfield(cfg, timelock);
        
        % Create spatial filter using the LCMV beamformer
        cfg                    = [];
        cfg.method             = 'lcmv';
        cfg.grid               = lf;       % leadfield, which has the grid information
        cfg.headmodel          = vol;      % volume conduction model (headmodel)
        cfg.lcmv.lambda        = '5%';
        cfg.lcmv.keepfilter    = 'yes';
        cfg.lcmv.projectmom    = 'yes';
        cfg.lcmv.keepmom       = 'no';
        source                 = ft_sourceanalysis(cfg, timelock);
        save(fullfile(meg_root_path, group, subject, state, 'source_lcmv_ROI90.mat'), 'source');
        
        % Create spatial filter using the SAM beamformer
        cfg                     = [];
        cfg.method              = 'sam';
        cfg.grid                = lf;       % leadfield, which has the grid information
        cfg.headmodel           = vol;      % volume conduction model (headmodel)
        cfg.sam.lambda          = '5%';
        cfg.sam.keepfilter      = 'yes';
        source                  = ft_sourceanalysis(cfg, timelock);
        source.avg              = rmfield(source.avg, 'mom');
        save(fullfile(meg_root_path, group, subject, state, 'source_sam_ROI90.mat'), 'source');
    end
end
