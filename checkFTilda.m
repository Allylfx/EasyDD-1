%Check that left face of cantilever has same ftilda for FEM and analytical.
%clear all;
% %load a test condition
% setenv('MW_NVCC_PATH','C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v7.5\bin')
%
% mexcuda COMPFLAGS="$COMPFLAGS -arch=sm_50 -use_fast_math" ./nodalForce/nodal_surface_force_linear_rectangle_mex.cu -Dsc
run ./Inputs/inputCheck.m
% run source_generator.m

counter=1;
error = [0 0 0];
min_mx = 20;
max_mx = 20;
stp_mx = 10;
for mx=min_mx:stp_mx:max_mx

    segments = constructsegmentlist(rn,links);
    
    %construct finite element arrays
    %construct stiffeness matrix K and pre-compute L,U decompositions.
    disp('Constructing stiffness matrix K and precomputing L,U decompositions. Please wait.'); 
    [B,xnodes,mno,nc,n,D,kg,K,L,U,Sleft,Sright,Stop,Sbot,...
        Sfront,Sback,gammat,gammau,gammaMixed,fixedDofs,freeDofs,...
        w,h,d,my,mz,mel] = finiteElement3D(dx,dy,dz,mx,MU,NU,loading);

%     % FRONT FACE
%     fmidpoint_element = zeros(mx*mz,3);
     midpoint_element = zeros(mx*mz,3);
%     tic;
%     %Use Queyreau equations
     for p=1:mx*mz
% 
         x3x6 = xnodes(nc(p,[5,6,8,7]),1:3);
% 
%         fx3_all=0;
%         fx4_all=0;
%         fx5_all=0;
%         fx6_all=0;
%         for i=1:size(segments,1)
%             [fx3,fx4,fx5,fx6,ftot] = NodalSurfForceLinearRectangle2(segments(i,6:8),segments(i,9:11),...
%                 x3x6(1,1:3),x3x6(2,1:3),x3x6(3,1:3),x3x6(4,1:3),...
%                 segments(i,3:5),MU,NU,a);
% 
%             %if screw, I get NaN??
%             if isnan(fx3)|isnan(fx4)|isnan(fx5)|isnan(fx6)
%                 fx3=0;
%                 fx4=0;
%                 fx5=0;
%                 fx6=0;
% %                 disp('Rectangular surface element side is parallel to dislocation segment');
% %                 disp('Correcting...');
%                 linen=segments(i,9:11)-segments(i,6:8);
%                 linen=linen./norm(linen);
% %                 nulln=null(linen);
% %                 v1=nulln(:,1)';
% %                 v2=nulln(:,2)';
%                 v1=[linen(2),-linen(1),0];
%                 v1=v1./norm(v1);
%                 v2=cross(linen,v1);
%                 v2=v2./norm(v2);
%                 avs=4; %average over 4 different lines
%                 thetas=pi/4+0.5*pi.*[1 2 3 4];
%                 C=segments(i,9:11);
%                 offset=a;
% %                 range = zeros(avs,3,4);
%                 for j=1:avs
%                     theta=thetas(j);
%                     newpoint = C + (v1*cos(theta) + v2*sin(theta))*offset;
%                   [fx3t,fx4t,fx5t,fx6t] = NodalSurfForceLinearRectangle2(segments(i,6:8),newpoint,...
%                   x3x6(1,1:3),x3x6(2,1:3),x3x6(3,1:3),x3x6(4,1:3),...
%                   segments(i,3:5),MU,NU,a);
%                     fx3 = fx3 + fx3t;
%                     fx4 = fx4 + fx4t;
%                     fx5 = fx5 + fx5t;
%                     fx6 = fx6 + fx6t;
% %                     range(j,1:3,1) = fx3t;
% %                     range(j,1:3,2) = fx4t;
% %                     range(j,1:3,3) = fx5t;
% %                     range(j,1:3,4) = fx6t;
%                 end
%                 fx3 = fx3/avs;
%                 fx4 = fx4/avs;
%                 fx5 = fx5/avs;
%                 fx6 = fx6/avs;
%                 if isnan(fx3)|isnan(fx4)|isnan(fx5)|isnan(fx6)
%                     disp('NaN present despite correction! :/');
%                 end
%             end
% 
%             fx3_all = fx3_all + fx3;
%             fx4_all = fx4_all + fx4;
%             fx5_all = fx5_all + fx5;
%             fx6_all = fx6_all + fx6;
%         end
% 
%         fmidpoint_element(p,1:3) = (fx3_all + fx4_all + fx5_all + fx6_all);
         midpoint_element(p,1:3) = mean(x3x6,1);
% 
     end
%     toc;
    
    %% use mex version of above
    sizeRectangleList = mx*mz;
    sizeSegmentList = size(segments,1);
    
    x1_array = reshape(segments(:,6:8)',sizeSegmentList*3,1);
    x2_array = reshape(segments(:,9:11)',sizeSegmentList*3,1);
    b_array = reshape(segments(:,3:5)',sizeSegmentList*3,1);
    
    x3_array=zeros(sizeRectangleList,3);
    x4_array=zeros(sizeRectangleList,3);
    x5_array=zeros(sizeRectangleList,3);
    x6_array=zeros(sizeRectangleList,3);
    for i=1:sizeRectangleList
        x3x6 = xnodes(nc(i,[5,6,8,7]),1:3);
        x3_array(i,1:3) = x3x6(1,1:3);
        x4_array(i,1:3) = x3x6(2,1:3);
        x5_array(i,1:3) = x3x6(3,1:3);
        x6_array(i,1:3) = x3x6(4,1:3);
    end
    x3_array = reshape(x3_array',sizeRectangleList*3,1); %x,y,z for each node
    x4_array = reshape(x4_array',sizeRectangleList*3,1);
    x5_array = reshape(x5_array',sizeRectangleList*3,1);
    x6_array = reshape(x6_array',sizeRectangleList*3,1);
    %[fx3_array,fx4_array,fx5_array,fx6_array,fxtot_array] = NodalSurfForceLinearRectangleMexArray(x1_array,x2_array,...
     %             x3_array,x4_array,x5_array,x6_array,...
      %            b_array,MU,NU,a,sizeRectangleList,sizeSegmentList);
     tic;
      [fx3_array2,fx4_array2,fx5_array2,fx6_array2,fxtot_array2] = nodal_surface_force_linear_rectangle_mex(x1_array,x2_array,...
        x3_array,x4_array,x5_array,x6_array,...
        b_array,MU,NU,a,sizeRectangleList,sizeSegmentList,512,1);
      %cuda_dln_nodal_surface_force_linear_rectangle(x1_array,x2_array,...
        %x3_array,x4_array,x5_array,x6_array,...
        %b_array,MU,NU,a,sizeRectangleList,sizeSegmentList,512);
    time_par = toc;
    disp(time_par)
    tic;
     [fx3_array,fx4_array,fx5_array,fx6_array,fxtot_array] = nodal_surface_force_linear_rectangle_arr(x1_array,x2_array,...
        x3_array,x4_array,x5_array,x6_array,...
        b_array,MU,NU,a,sizeRectangleList,sizeSegmentList);
    time_lin = toc;
    disp(time_lin)
      %[fx3_array,fx4_array,fx5_array,fx6_array,fxtot_array] = nodal_surface_force_linear_rectangle_arr2(x1_array,x2_array,...
       % x3_array,x4_array,x5_array,x6_array,...
        %b_array,MU,NU,a,sizeRectangleList,sizeSegmentList);
      %[fx3_array2,fx4_array2,fx5_array2,fx6_array2,fxtot_array2] = nodal_surface_force_linear_rectangle_arr_unix(x1_array,x2_array,...
       % x3_array,x4_array,x5_array,x6_array,...
        %b_array,MU,NU,a,sizeRectangleList,sizeSegmentList);
        
    fmidpoint_elementMEX = reshape(fxtot_array,3,mx*mz)';
    fmidpoint_elementMEX2 = reshape(fxtot_array2,3,mx*mz)';
    %fmidpoint_elementMEXd1 = reshape(fxtot_arrayd1,3,mx*mz)';
    %fmidpoint_elementMEXd2 = reshape(fxtot_arrayd2,3,mx*mz)';
    
    %%
    %Use field point stress
    tic;
    %choose front face
    gamma = gammat(gammat(:,4) == -1,:); %face=[0-10];
    area = zeros(mx*mz,1) + gamma(1,2);
    normal = gamma(1,3:5);
    lseg = size(segments,1);
    lgrid = mx*mz;
    p1x = segments(:,6);
    p1y = segments(:,7);
    p1z = segments(:,8);
    p2x = segments(:,9);
    p2y = segments(:,10);
    p2z = segments(:,11);
    bx = segments(:,3);
    by = segments(:,4);
    bz = segments(:,5);
    % x = xnodes(nodes,1);
    % y = xnodes(nodes,2);
    % z = xnodes(nodes,3);
    x = midpoint_element(:,1);
    y = midpoint_element(:,2);
    z = midpoint_element(:,3);
    [sxx, syy, szz, sxy, syz, sxz] = StressDueToSegs(lgrid, lseg,...
                                                  x, y, z,...
                                                  p1x,p1y,p1z,...
                                                  p2x,p2y,p2z,...
                                                  bx,by,bz,...
                                                  a,MU,NU); 
    Tx = sxx*normal(1) + sxy*normal(2) + sxz*normal(3);
    Ty = sxy*normal(1) + syy*normal(2) + syz*normal(3);
    Tz = sxz*normal(1) + syz*normal(2) + szz*normal(3);
    ATx = area.*Tx;
    ATy = area.*Ty;
    ATz = area.*Tz;
    ftilda = [ATx,ATy,ATz];

    X=reshape(x,mx,mz);
    Y=reshape(y,mx,mz);
    Z=reshape(z,mx,mz);
    toc;
      
    h=figure;   
    subplot(3,2,1);
    
    contourf(X,Z,reshape(ftilda(:,1),mx,mz));
    colorvec = [-200 500];
    caxis(colorvec);
    %title(['mx = ',num2str(mx)])
    title('$\mathbf{f}^{\mathrm{Numerical}}_x$', 'Interpreter', 'latex');
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex');
    subplot(3,2,2);
    contourf(X,Z,reshape(fmidpoint_elementMEX(:,1),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Analytical}}_x$', 'Interpreter', 'latex');
    ylabel('$z\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,3);
    contourf(X,Z,reshape(ftilda(:,2),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Numerical}}_y$', 'Interpreter', 'latex');
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,4);
    contourf(X,Z,reshape(fmidpoint_elementMEX(:,2),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Analytical}}_y$', 'Interpreter', 'latex');
    ylabel('$z\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,5);
    contourf(X,Z,reshape(ftilda(:,3),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Numerical}}_z$', 'Interpreter', 'latex');
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,6);
    contourf(X,Z,reshape(fmidpoint_elementMEX(:,3),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Analytical}}_z$', 'Interpreter', 'latex');
    ylabel('$z\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    
    
    
    g = figure;
    subplot(3,2,1);
    contourf(X,Z,reshape(ftilda(:,1),mx,mz));
    colorvec = [-200 500];
    caxis(colorvec);
    %title(['mx = ',num2str(mx)])
    title('$\mathbf{f}^{\mathrm{Numerical}}_x$', 'Interpreter', 'latex');
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex');
    subplot(3,2,2);
    contourf(X,Z,reshape(fmidpoint_elementMEX2(:,1),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Analytical}}_x$', 'Interpreter', 'latex');
    ylabel('$z\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,3);
    contourf(X,Z,reshape(ftilda(:,2),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Numerical}}_y$', 'Interpreter', 'latex');
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,4);
    contourf(X,Z,reshape(fmidpoint_elementMEX2(:,2),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Analytical}}_y$', 'Interpreter', 'latex');
    ylabel('$z\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,5);
    contourf(X,Z,reshape(ftilda(:,3),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Numerical}}_z$', 'Interpreter', 'latex');
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    subplot(3,2,6);
    contourf(X,Z,reshape(fmidpoint_elementMEX2(:,3),mx,mz));
    caxis(colorvec);
    title('$\mathbf{f}^{\mathrm{Analytical}}_z$', 'Interpreter', 'latex');
    ylabel('$z\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    xlabel('$x\, (\mu\mathrm{m})$', 'Interpreter', 'latex')
    saveas(g, sprintf('fig2_%d_mx.png', mx));
    close all
    %err(counter,1)=rms((ftilda(:,1)-fmidpoint_elementMEX(:,1))./fmidpoint_elementMEX(:,1))/(mx*mz);
    %err(counter,2)=rms((ftilda(:,2)-fmidpoint_elementMEX(:,2))./fmidpoint_elementMEX(:,2))/(mx*mz);
    %err(counter,3)=rms((ftilda(:,3)-fmidpoint_elementMEX(:,3))./fmidpoint_elementMEX(:,3))/(mx*mz);
    %elements(counter) = mx*mz;
    mean_error(counter) = (rms((ftilda(:,1)-fmidpoint_elementMEX(:,1))./fmidpoint_elementMEX(:,1))...
        + rms((ftilda(:,2)-fmidpoint_elementMEX(:,2))./fmidpoint_elementMEX(:,2))...
        + rms((ftilda(:,3)-fmidpoint_elementMEX(:,3))./fmidpoint_elementMEX(:,3)))/3;
    counter=counter+1;
end
 testx = min_mx:stp_mx:max_mx;
 h = figure;
 plot(testx, mean_error)
 title('Mean Error $\mathbf{f}^{\mathrm{Numerical}}$ vs. $\mathbf{f}^{\mathrm{Analytical}}$', 'Interpreter', 'latex', 'FontSize', 14)
 ylabel('Mean Error, A.U.', 'Interpreter', 'latex', 'FontSize', 14)
 xlabel('Mesh Elements in $x$', 'Interpreter', 'latex', 'FontSize', 14)
 saveas(h, sprintf('error2.png'));
