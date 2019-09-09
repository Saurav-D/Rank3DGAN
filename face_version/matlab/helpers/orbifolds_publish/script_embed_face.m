%% =====================================================================
%  ===                      Setting up stuff                         ===
%  =====================================================================

%Create the mesh
%[X,Y] = meshgrid(-2:.1:2, -2:.1:2);

% Z = sin(X*2.6).*sin(Y*5.1)*0.1;%.* exp(-X.^2 - Y.^2);
% X=X(:);Y=Y(:);Z=Z(:);
% T=  delaunay(X,Y);
% V=[X Y Z];
[V, T] = read_ply('mesh_1.ply');
%set boundary conditions
tri=triangulation(T,V(:,1),V(:,2), V(:,3));
b=tri.freeBoundary();
b=b(:,1);


%Some color-related variables - no need to concern yourself with these :)
cone_colors=[1 0.8 0;0.7 0 1; 0 0.5 0.8;0 0 0.5];
cut_colors=[1 0 0;0 1 0;0 0 1;0 1 1];

%The cone positions and the choice of orbifold structure, defining the
%desired embedding

% === Triangle disk orbifold ===
%boundary_inds=[1 30 80];
%cones=b(boundary_inds);


%try uncommneting each of the next lines for the other orbifold structures

% === Square disk orbifold ===
 boundary_inds=[1 128 256 384];
 cones=b(boundary_inds);





%% =======================================================================
%  =======       The actual algorithm! cutting and flattening      =======
%  =======================================================================



V_flat=flatten_disk(V,T,cones);





%% =======================================================================
%  =====                        Visualization                        =====
%  =======================================================================



figure(1);
clf;


% === Visualization of the original 3D mesh + cones & cuts on it ===
subplot(1,2,1);
%draw the mesh
patch('faces',T,'vertices',V,'facecolor','interp','FaceVertexCData',V(:,3))
hold on;
%draw the cones
for i=1:length(cones)
    scatter3(V(cones(i),1),V(cones(i),2),V(cones(i),3),100,cone_colors(i,:),'fill');
end
%draw the cuts...
inds=[boundary_inds length(b)];
for i=1:length(inds)-1
    
    curPath=b(inds(i):inds(i+1));
    %draw the cut
    line(V(curPath,1),V(curPath,2),V(curPath,3),'color',cut_colors(i,:),'linewidth',2);
end
%iterate over all path-pairs (the correspondences generated in the
%cutting)

%some nice lighting and fixing the axis
campos([-1 1 2]);
camtarget([0,0,0])
camlight
axis equal
title('Disk mesh');



% === Visualization of the flattening + cones & cuts on it ===
subplot(1,2,2);
%draw the flattened mesh 
patch('faces',T,'vertices',V_flat,'facecolor','interp','FaceVertexCData',V(:,3));
hold on;
inds=[boundary_inds length(b)];
for i=1:length(inds)-1
    
    curPath=b(inds(i):inds(i+1));
    %draw the cut
    line(V_flat(curPath,1),V_flat(curPath,2),'color',cut_colors(i,:),'linewidth',2);
end
%draw the cones
for i=1:length(cones)
    %for each cone, find all its copies using the mapping of vertex indices 
    %of the uncut mesh to the vertex indices of the cut mesh
    flat_cones=cones(i);
    scatter(V_flat(flat_cones,1),V_flat(flat_cones,2),40,cone_colors(i,:),'fill');
end
%draw the cuts...
%iterate over all pairs of corresponding indices of twin vertices generated 
%in the cutting process

axis equal
title('Embedding into a disk orbifold');

numFunctions = size(V,2);
V_flat_merged = V_flat;
T_merged = T;
sz = 64;
f = V(:,1);
vals = repmat(1:size(V_flat,1), 1, 36);

[V_flat_merged, T_merged] = make_tiling_interp(V_flat_merged,T_merged);
figure;
patch('faces',T_merged,'vertices',V_flat_merged','FaceColor','white');
T_merged = T_merged';
%V_flat_merged = V_flat_merged';
tt = zeros(3, size(T_merged, 2));
tt(:) = V_flat_merged(1,T_merged(1:3,:));
xmin = min(tt);
xmax = max(tt);
tt(:) = V_flat_merged(2,T_merged(1:3,:));
ymin = min(tt);
ymax = max(tt);
ind_xmin = xmin>-4;
ind_xmax = xmax<2;
ind_ymin = ymin>-4;
ind_ymax = ymax<2;

ind = ind_xmin & ind_xmax & ind_ymin & ind_ymax;
T_merged = T_merged(:,ind);

X = linspace(-3,1-4/sz,sz);
Y = linspace(-3,1-4/sz,sz);
[out,tn,al2,al3]=mytri2grid(V_flat_merged,T_merged,f(vals),X,Y);
dataFunctions(:,:,1) = out;

for ii=2:numFunctions
    f=V(:,ii);
    [out,tn,al2,al3] = mytri2grid(V_flat_merged,T_merged,f(vals),tn,al2,al3);
    dataFunctions(:,:,ii) = out;
end
for ii=1:numFunctions
    figure, imagesc(dataFunctions(:,:,ii));
end

IM(:,1) = liftImage(V_flat,squeeze(dataFunctions(:,:,1)));
IM(:,2) = liftImage(V_flat,squeeze(dataFunctions(:,:,2)));
IM(:,3) = liftImage(V_flat,squeeze(dataFunctions(:,:,3)));
figure;
patch('faces',T,'vertices',IM,'facecolor','interp','FaceVertexCData',IM(:,3))