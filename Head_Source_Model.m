% This file is used to create Subject-specific source model that are equivalent across subjects in normalized MNI space

clear;clc

%% Add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% Root directory of MRI file
mri_root_path = '/Users/ke/OneDrive - UHN/MRI';

% Subpath of PD patients
% group = 'PD';
% subjects = {'PD_A', 'PD_D', 'PD_E', 'PD_F', 'PD_G', 'PD_H', 'PD_J', 'PD_K', 'PD_L','PD_M', 'PD_O', 'PD_P', 'PD_Q', 'PD_R'};
% states = {'On', 'Off'};

% Subpath of health controls
group = 'OC';
subjects = {'OC_B', 'OC_C', 'OC_D', 'OC_F', 'OC_G', 'OC_H', 'OC_K', 'OC_L', 'OC_N', 'OC_O', 'OC_P', 'OC_Q', 'OC_R', 'OC_S'};
states = {''};

%% Create source mdoels for each subject during each state
for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
        % Load data
        file_name = 'mri_align.mat';
        mri_data_file = fullfile(mri_root_path, group, subject, state, file_name);
        load(mri_data_file);
        
        % Segmentation
        cfg = [];
        cfg.output = 'brain';
        mri_seg  = ft_volumesegment(cfg, mri_align);
        save(fullfile(mri_root_path, group, subject, state, 'mri_seg.mat'), 'mri_seg');
        
        % Headmodel
        cfg = [];
        cfg.method = 'singleshell';
        vol = ft_prepare_headmodel(cfg, mri_seg);
        vol = ft_convert_units(vol, 'cm')
        save(fullfile(mri_root_path, group, subject, state, 'vol.mat'), 'vol');
        
        %% Make the individual subjects' source mdoel based on templated grid or template ROI in MNI coordinate
        % template grid
        %     load(fullfile(fieldtrip_path, 'template/sourcemodel', 'standard_sourcemodel3d5mm'));
        %     template_grid = sourcemodel;
        %
        %     cfg                = [];
        %     cfg.grid.warpmni   = 'yes';
        %     cfg.grid.template  = template_grid;
        %     cfg.grid.nonlinear = 'yes';
        %     cfg.mri            = mri_align;
        %     cfg.grid.unit      ='cm';
        %     grid               = ft_prepare_sourcemodel(cfg);
        %     save(fullfile(mri_root_path, subject, 'grid.mat'), 'grid');
        
        % template ROI
        load template_ROI_AAL90.mat;
        cfg                = [];
        cfg.grid.warpmni   = 'yes';
        cfg.grid.template  = template_ROI;
        cfg.grid.nonlinear = 'no';
        cfg.mri            = mri_align;
        cfg.grid.unit      ='cm';
        grid           = ft_prepare_sourcemodel(cfg);
        save(fullfile(mri_root_path, group, subject, state, 'ROI_AAL90.mat'), 'grid');
    end
end
