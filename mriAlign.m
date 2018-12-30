

clear;clc

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% load data
mri_root_path = '/Users/ke/OneDrive - UHN/MRI';

% group = 'PD';
% subjects = {'PD_A', 'PD_D', 'PD_E', 'PD_F', 'PD_G', 'PD_H', 'PD_J', 'PD_K', 'PD_L','PD_M', 'PD_O', 'PD_P', 'PD_Q', 'PD_R'};
% states = {'On', 'Off'};

group = 'OC';
subjects = {'OC_B','OC_C','OC_D','OC_F','OC_G','OC_H','OC_J','OC_K','OC_L','OC_N','OC_O','OC_P','OC_Q','OC_R','OC_S'};
states = {''};

file_name = 'mri_raw.mat';

for i = 1:length(subjects)    
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)
        state = states{j};
        
        mri_data_file = fullfile(mri_root_path, group, subject, state, file_name);
        load(mri_data_file);
        
        %% convert coordinate from original to acpc
        cfg = [];
        cfg.method = 'interactive';
        cfg.coordsys = 'acpc';
        mri_acpc    = ft_volumerealign(cfg, mri_raw);
        
        %% reslice mri
        cfg            = [];
        mri_rs     = ft_volumereslice(cfg, mri_acpc);
        
%         mri_rs = mri_raw;
        
        %%
        char = 'n';
        while (char ~= 'y')
            cfg.method = 'interactive';
            cfg.coordsys = 'neuromag';
            [mri_align] = ft_volumerealign(cfg, mri_rs)
            [dataout] = ft_determine_coordsys(mri_align);
            char = input('ending?:','s');
        end
        
        save(fullfile(mri_root_path, group, subject, state, 'mri_align.mat'), 'mri_align');
    end
end


