
% This file is to construct source model for each ROIs in AAL template
clear;clc;
close all;

%% Add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% MNI template grid
load(fullfile(fieldtrip_path, 'template/sourcemodel', 'standard_sourcemodel3d5mm'));
template_grid = sourcemodel;

%% MNI atlas
file_aal = fullfile(fieldtrip_path,'template/atlas/aal/ROI_MNI_V4.nii');
aal = ft_read_atlas(file_aal);
aal = ft_convert_units(aal,'cm');

%% Label the template grid with AAL 
cfg = []; 
cfg.interpmethod = 'nearest'; 
cfg.parameter = 'tissue'; 
template_grid2 = ft_sourceinterpolate(cfg,aal,template_grid);

%% Define ROI source model: each ROI’s centroid as representative for that ROI
n_ROI = 90; % Only extract the first 90 ROIs
pos_ROI = zeros(n_ROI,3);
label_ROI = cell(n_ROI,1);
for i = 1:n_ROI
    % Find all the voxels for each ROI
    ind = find(template_grid2.tissue == i);
    [x y z] = ind2sub(template_grid2.dim, ind);   
    pos_head = ft_warp_apply( template_grid2.transform, [x y z], 'homogeneous' );
    
    % The centroid was defined as the voxel within the ROI that is nearest to all other voxels in the ROI
    temp = repmat(permute(pos_head,[1 3 2]),1,size(pos_head,1),1);
    dist = sum((temp-permute(temp,[2 1 3])).^2,3);
    [~, ind1] = min(sum(dist,2));
    
    % save the centroid voxel    
    pos_ROI(i,:) = pos_head(ind1,:,:); 
    label_ROI{i} = aal.tissuelabel{i};
end

% Save the template ROIs
template_ROI           = [];
template_ROI.pos       = pos_ROI;
template_ROI.inside    = true(length(pos_ROI),1);
template_ROI.label     = label_ROI;
save('template_ROI_AAL90.mat', 'template_ROI');

