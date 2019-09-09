function [cutVals]=liftImage(V_flat,IM,classic,method)
            % lifting the image (grid) back to the original mesh
            % inputs:
            %       IM - toric image (4 rotated copies)
            %       classic - ask Haggai
            %       method - default is 'interp2'
            %           two methods are available:
            %            1. 'nn' - nearest neighbor (written by Noam)
            %            2. 'interp2' - interpolating over the grid
            
            if nargin<4
                method = 'interp2';
                if nargin<3
                    classic=false;
                end
            end
            assert(size(IM,1)==size(IM,2),'image should be square!');
            sz = size(IM,1);
            
            if strcmp(method,'nn')
                IM = IM(floor(size(IM,1)/2+1:end),floor(size(IM,2)/2)+1:end);
                if ~classic
                t=Tiler(obj.flat_V,obj.flat_T,obj.M_cut.pathPairs);
                t.tile(6);
                orgV=obj.flat_V;


                found=false(length(orgV),1);
                V=obj.flat_V;
                for i=1:length(t.trans)
                    A=t.trans{i};
                    curV=orgV*A([1 2],:)'+repmat(A(3,:),length(obj.flat_V),1);

                    good=all(curV>=-1&curV<=1,2)&~found;
                    found(good)=true;
                    V(good,:)=curV(good,:);
                    if isempty(good)
                        break;
                    end
                end
                end
                %move from [-1,1]^2 to [0,1]^2
                V=(V+1)/2;
                % we want 0 mapped to 1, and 1 mapped to length(image)
                V=V*(length(IM)-1);
                V=V+1;
                V(V<1)=1;
                V(V>length(IM))=length(IM);
                inds_from_pos=round(V);
                I=sub2ind(size(IM),inds_from_pos(:,1),inds_from_pos(:,2));
                cutVals=IM(I);
                orgVals=cutVals(cellfun(@(X)X(1),obj.M_cut.uncutIndsToCutInds));
            elseif strcmp(method,'interp2')
                VX=V_flat;
                V1 = VX(:,1);
                V1(V1>1) = V1(V1>1)-4;
                V1(V1<-3) = V1(V1<-3)+4;
                V2 = VX(:,2);
                V2(V2<-3) = V2(V2<-3)+4;
                V2(V2>1) = V2(V2>1)-4;
                
                [X,Y] = meshgrid(linspace(-3,1,sz),linspace(-3,1,sz));
                cutVals = interp2(X,Y,IM,V1,V2);
                %orgVals=cutVals(cellfun(@(X)X(1),obj.M_cut.uncutIndsToCutInds));        
            end
                
end