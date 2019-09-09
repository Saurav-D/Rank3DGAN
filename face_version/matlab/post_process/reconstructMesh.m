function [V_rec, charts] = reconstructMesh(data, fInfo, triplets_table,align_charts, smooth_cones, p,scale_method,weighting_method,k)
% reconstructMesh
% default - convex comb with norm 1.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% handle inputs
if nargin<9
    k=1;
    if nargin<8
        weighting_method = 'convex_comb';
        if nargin<7
            scale_method = 'original';
            if nargin<6
                p=1;
                if nargin<5
                    smooth_cones = false;
                    if nargin<4
                        align_charts = false;
                    end
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% align and pad charts
if align_charts
    data = align_charts_ST(data, triplets_table, 3);
end
charts = [data , data(1:end,1,:) ; data(1,1:end,:),data(1,1,:)];

len = fInfo{1,1}.V_flat;
V_rec = zeros(size(len,1),3);


flattener = {};
for ii = 1:size(triplets_table,1)
    flattener{ii} = fInfo{1,ii}.flattener;
    V_flat = fInfo{1,ii}.V_flat;
    V_rec = V_rec + [liftImage(V_flat, charts(:,:,3*ii-2)),...
        liftImage(V_flat, charts(:,:,3*ii-1)),...
        liftImage(V_flat, charts(:,:,3*ii))];
end

if smooth_cones
    V_rec = smoothCones(fInfo, V_rec);
end

end

