
% This file is used to align the MRI to the 'neuromag' coordinate system.

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
subjects = {'OC_B','OC_C','OC_D','OC_F','OC_G','OC_H','OC_J','OC_K','OC_L','OC_N','OC_O','OC_P','OC_Q','OC_R','OC_S'};
states = {''};

% The file name of MRI
file_name = 'mri_raw.mat';


%% Align MRI for each subject during each state
for i = 1:length(subjects)    
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
        mri_data_file = fullfile(mri_root_path, group, subject, state, file_name);
        load(mri_data_file);
        
        % Convert coordinate from original to 'acpc' coordinate
        cfg = [];
        cfg.method = 'interactive';
        cfg.coordsys = 'acpc';
        mri_acpc    = ft_volumerealign(cfg, mri_raw);
        
        % Reslice mri
        cfg            = [];
        mri_rs     = ft_volumereslice(cfg, mri_acpc);        
        
        % Align MRI to Nasion/LPC/RPC
        stop = 'n';
        while (stop ~= 'y')
        
            cfg = []
            cfg.method = 'interactive';
            cfg.coordsys = 'neuromag';
            [mri_align] = ft_volumerealign(cfg, mri_rs)
            
            % Check the alignment resluts
            [dataout] = ft_determine_coordsys(mri_align);
            
            stop = input('ending?:','s');
        end
        
        % Save the aligned MRI
        save(fullfile(mri_root_path, group, subject, state, 'mri_align.mat'), 'mri_align');
    end
end


