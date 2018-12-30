

clear;clc

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%%
mri_root_path = '/Users/ke/OneDrive - UHN/MRI';

% group = 'PD';
% states = {'On', 'Off'};
% subjects = {'PD_A', 'PD_D', 'PD_E', 'PD_F', 'PD_G', 'PD_H', 'PD_J', 'PD_K', 'PD_L','PD_M', 'PD_O', 'PD_P', 'PD_Q', 'PD_R'};


group = 'OC';
subjects = {'OC_B','OC_C','OC_D','OC_F','OC_G','OC_H','OC_J','OC_K','OC_L','OC_N','OC_O','OC_P','OC_Q','OC_R','OC_S'};
states = {''};

for i = 1:length(subjects)
    subject = subjects{i};
    fprintf('%s\n', subject);
    
    for j = 1:length(states)      
        state = states{j};
        
        mri_path = fullfile(mri_root_path, group, subject, state, 'MR');
        list = dir([mri_path, filesep, '*.MR']);
        mri_file = fullfile(mri_path, list(1).name);
        
        mri_raw = ft_read_mri(mri_file);
        save(fullfile(mri_root_path, group, subject, state, 'mri_raw.mat'), 'mri_raw');
    end
end