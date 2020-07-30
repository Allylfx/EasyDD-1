function [vnvec,fn,fseg] = drndt(rnvec,flag,MU,NU,a,Ec,links,connectivity,...
    mobility,vertices,uhat,nc,xnodes,D,mx,mz,w,h,d)

% This needs to be an input/obtained from the surface nodes. This is a temporary fix for cuboid.
normals=[1 0 0;
         0 1 0;
         0 0 1];
tol=1e-1;

%unscramble rn
rn=[reshape(rnvec,length(rnvec)/3,3),flag];

%rn(:,1:3)

%nodal driving force
fseg=segforcevec(MU,NU,a,Ec,rn,links,0,vertices,...
    uhat,nc,xnodes,D,mx,mz,w,h,d);

%mobility function
[vn,fn]=feval(mobility,fseg,rn,links,connectivity,[],[]);

% fixed nodes (flag==7) are not allowed to move.
% flag == 6, are only allowed to move on the surface they live at.
% flag == 67, are virtual nodes that are not allowed to move.
for p=1:size(vn,1)

   % Virtual and fixed nodes have zero velocity
    if rn(p,4) == 7 || rn(p,4) == 67
        vn(p,:)=[0 0 0];
   % Surface nodes are confined to moving in the movement plane and surface plane.
    elseif rn(p,4) == 6
        % Skip stationary surface nodes
        if norm(vn(p,:))<eps
            vn(p,:)=[0 0 0];
            continue
        end
        connodes = [rn(links(links(:,1)==p,2),[1:3,end]); rn(links(links(:,2)==p,1),[1:3,end])];
        virtconnodes = connodes(connodes(:,4)==67,1:3);
        realconnodes = connodes(connodes(:,4)~=67,1:3);
        % If the surface node doesn't have a  single defined movement plane, make its velocity zero and continue.
        if size(realconnodes,1)>1 || isempty(realconnodes)
           vn(p,:)=[0 0 0];
           continue
        end
        linvec=rn(p,1:3)-realconnodes;
        % Segments should not have zero length
        if norm(linvec)<eps
            disp('Remeshing error detected. See line 48 of drndt.m')
            pause
        end
        slipplane=cross(linvec,vn(p,:));
        % If the node is moving paralell to the line direction, make its velocity zero
        if norm(slipplane)<eps
            vn(p,:)=[0 0 0];
            continue
        end
        slipplane=slipplane/norm(slipplane);
        slipplane=round(slipplane,4);
        slipplane=slipplane/norm(slipplane);
        reps=ones(size(virtconnodes,1),3);
        reps=rn(p,1:3).*reps;
        vec=virtconnodes-reps;
        vec = sum(vec,1);
        vec= vec/norm(vec);
        dotprods=normals*vec';
        surfplanes=normals(abs(dotprods)>tol,:);
        % If no surface normals can be detected then there is an error
        if isempty(surfplanes)
           disp('Weird surface node detected. See line 67 of drndt.m')
           pause
        end
        slipplane=slipplane.*ones(size(surfplanes));
        lines=cross(surfplanes,slipplane,2);
        lines(:,1:3) = lines(:,1:3)/norm(lines(:,1:3));
        % If the surface plane is a viable slip plane
        if any(any(isnan(lines)))
            disp('Check surface remeshing re line 75 of drndt.m')
            continue
        end
        % If there is no single definite movement direction, make the velocity zero
        if size(lines,1)>2
            vn(p,:)=[0 0 0];
            continue
        elseif size(lines,1)==2
%            if 1 - abs(lines(1,:) * lines(2,:)') < eps
%                lines=lines(1,:);
%            else
%                vn(p,:)=[0 0 0];
%                continue
%            end
            rn(p,4)=0;
            continue
        end
        surfplanes = sum(surfplanes,1);
        surfplanes = surfplanes/norm(surfplanes);
        % If the node is moving perpendicular to the surface, make its velocity zero
        if 1 - abs(vn(p,:)*surfplanes') < eps
            vn(p,:) = [0 0 0];
        else
            vn(p,:)=(vn(p,:)*lines').*lines;
            % Remove stupidly small vectors
            if norm(vn(p,:)) < eps
                vn(p,:) = [0 0 0];
            end
        end
    end
    
    
%     % Daniel Celis Garza 20200120: Surface node has zero velocity in the 
%     % direction of the surface normal.
%     if rn(p,4) == 6
%         % Find the coordinates of the nodes connected to the surface node.
%         connodes = [rn(links(links(:,1)==p,2),[1:3,end]);
%                     rn(links(links(:,2)==p,1),[1:3,end])];
%         % Out of the connected nodes find if any of them is external (67).
%         virtual_connection = connodes(connodes(:,end)==67,1:3);
%         % If the surface node is connected to an external node, we
%         % eliminate the surface node's velocity component in that
%         % direction.
%         if ~isempty(virtual_connection)
%             % If the node is connected to more than one external node we
%             % find the mean line direction and use that vector to correct
%             % the velocity.
%             if size(virtual_connection,1)>1
%                 virtual_connection = mean(virtual_connection);
%             end
%             virtual_connection = virtual_connection/norm(virtual_connection);
%             % Vector rejection eliminates the velocity components in the
%             % direction of the virtual segment.
%             vn(p,:) = vn(p,:) - dot(vn(p,:), virtual_connection)*virtual_connection;
%         end
%     end
end

%make up the last
vnvec=reshape(vn,length(vn(:,1))*3,1);
