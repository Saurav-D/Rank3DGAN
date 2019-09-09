%% Post-Process - inspect generated meshes

% load dataset parameters
database_signature = 'face_big';
load(['../databases/flattening_parameters/params_', database_signature]);

% load generated examples
load('data/generated_charts.mat')

% load template mesh
[V_temp,F_temp] = read_obj('data/templateMesh.obj');
V_temp = V_temp';
F_temp = F_temp';
% to create fInfo file for a new template, simply run 
load(fullfile('../databases/flattening_parameters/', database_signature, 'uCones.mat'));
params.triplets = uCones(params.triplets_table)';
[data, fInfo] = flattenMesh(V_temp, F_temp, params);
save(fullfile('data/fInfo_temp.mat'), 'fInfo')

% reconstruct and show generated meshes
figure;
for sample = 1:64
charts =  permute(squeeze(generated_charts(sample,:,:,:)) , [2,3,1]);
% to visualize the charts
%charts =  squeeze(data);
%for ii=1:3
%        figure, imagesc(charts(:,:,ii))
%end
[V_rec, ~] = reconstructMesh(charts, fInfo, params.triplets_table);
% shift for visualisation purpose only
V_rec(:,1) = V_rec(:,1) + 5*sample;
%figure
hold on
patch('vertices',V_rec,'faces',F_temp,'facecolor',[1 1 1],'edgecolor','none')
axis equal; addRot3D; axis off; camlight

end