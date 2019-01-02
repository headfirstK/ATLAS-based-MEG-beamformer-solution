
clear;clc;
close all;

%% add the path of fieldtrip
fieldtrip_path = '/Users/ke/toolbox/fieldtrip-20180719';
addpath(fieldtrip_path,'-end');
ft_defaults

%% template grid
load(fullfile(fieldtrip_path, 'template/sourcemodel', 'standard_sourcemodel3d5mm'));
template_grid = sourcemodel;

%% MNI atlas
file_aal = fullfile(fieldtrip_path,'template/atlas/aal/ROI_MNI_V4.nii');
aal = ft_read_atlas(file_aal);
aal = ft_convert_units(aal,'cm');

%% Define ROI source model with template grid
% label the template grid
cfg = []; 
cfg.interpmethod = 'nearest'; 
cfg.parameter = 'tissue'; 
template_grid2 = ft_sourceinterpolate(cfg,aal,template_grid);


% Find the center of the first 90 region of interesting (ROI)
n_ROI = 90;
pos_ROI = zeros(n_ROI,3);
label_ROI = cell(n_ROI,1);
for i = 1:n_ROI
    ind = find(template_grid2.tissue == i);
    [x y z] = ind2sub(template_grid2.dim, ind);   
    pos_head = ft_warp_apply( template_grid2.transform, [x y z], 'homogeneous' );
    temp = repmat(permute(pos_head,[1 3 2]),1,size(pos_head,1),1);
    dist = sum((temp-permute(temp,[2 1 3])).^2,3);
    [~, ind1] = min(sum(dist,2));
    pos_ROI(i,:) = pos_head(ind1,:,:); 
    label_ROI{i} = aal.tissuelabel{i};
end

% Find the template ROI location which is nearest to the center of ROI
template_ROI           = [];
template_ROI.pos       = pos_ROI;
template_ROI.inside    = true(length(pos_ROI),1);
template_ROI.label     = label_ROI;
save('template_ROI_AAL90.mat', 'template_ROI');

%%
s = 0;
for i = 1:n_ROI
    pos = template_ROI.pos(i,:);
    vox = round(ft_warp_apply( inv(template_grid2.transform), pos, 'homogeneous' ));
    s = s + (template_grid2.tissue(vox(1),vox(2),vox(3))-i);
end

