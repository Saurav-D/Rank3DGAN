%% Post-Process - inspect generated meshes

% load dataset parameters
database_signature = 'ceasar';
load(['../databases/flattening_parameters/params_', database_signature]);

% load generated examples
load('data/reconstructed_charts.mat')
%generated_charts = generated_charts2;
%load('data/11_epoch.mat');
%generated_charts = edited_charts;
%generated_charts(1,:,1:3,:,:) = c;
% load template mesh
[V_temp,F_temp] = read_ply('data/templateMesh.ply');
% to create fInfo file for a new template, simply run 
load(fullfile('../databases/flattening_parameters/', database_signature, 'uCones.mat'));
params.triplets = uCones(params.triplets_table);
[data, fInfo] = flattenMesh(V_temp, F_temp, params);
save(fullfile('data/fInfo_temp.mat'), 'fInfo')
%load(fullfile('data/fInfo_temp.mat'));
load('data/mesh_1_img.mat');
data = reshape(data,[64,64,48]);
data = permute(data,[ 2 1 3 ]);
% reconstruct and show generated meshes
figure;
if numel(size(gt)) < 5 
    idx = 1;
    generated_charts = reshape(gt,[1,size(gt)]);
    %generated_charts = reshape(generated_charts1,[1,size(generated_charts1)]);
else
    generated_charts = gt;
    idx = size(generated_charts,1);
end
for index=1:1
    %figure;
    for sample = 1:100
        %charts = data;
    %charts = squeeze(generated_charts(index,:,:,:,:));
    charts = permute(squeeze(generated_charts(index,sample,:,:,:)) , [2,3,1]);
    %for ii=1:3
    %    figure, imagesc(charts(:,:,ii))
    %end
    %figure;
    charts_aligned = align_charts_ST(charts,params.triplets_table,3);
    [V_rec, ~, ~, ~] = reconstructMesh(charts, fInfo, params.triplets_table);
    %V_rec(:,1) = V_rec(:,1) + 5*sample;
    %V_rec(:,2) = V_rec(:,2) + 40*index;
    write_obj(strcat(strcat('interpolation/',int2str((index-1)*64+sample)),'.obj'), V_rec, F_temp);
    %figure
    %hold on
    %patch('vertices',V_rec,'faces',F_temp,'facecolor',[0 0 0],'edgecolor','none')
    %axis equal; addRot3D; axis off; camlight
    
    end
    

end