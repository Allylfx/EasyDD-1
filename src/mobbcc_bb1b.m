function [vn, fn] = mobbcc_bb1b(fseg, rn, links, connectivity, nodelist, conlist, Bcoeff)
    %mobility law function (model: BCC0)
    Bscrew = Bcoeff.screw;
    Bedge = Bcoeff.edge;
    Beclimb = Bcoeff.climb;

    %numerical tolerance
    tol = 1e-7;
    planelist = (1 / sqrt(2)) * [1 1 0;
                            1 0 1;
                            0 1 1;
                            1 -1 0;
                            1 0 -1;
                            0 1 -1];

    % length of the nodelist for which the velocity will be calculated
    L1 = size(nodelist, 1);
    % if no nodelist is given then the nodelist becomes the whole node population
    % this portion of the code sets up that nodelist along with the connlist
    % that contains all of the nodal connections
    if L1 == 0
        L1 = size(rn, 1);
        nodelist = linspace(1, L1, L1)';
        [L2, L3] = size(connectivity);
        conlist = zeros(L2, (L3 - 1) / 2 + 1);
        conlist(:, 1) = connectivity(:, 1);

        for i = 1:L2
            connumb = conlist(i, 1);
            conlist(i, 2:connumb + 1) = linspace(1, connumb, connumb);
        end

    end

    % now cycle through all of the nodes for which the velocity must be calculated

    vn = zeros(L1, 3);
    fn = zeros(L1, 3);

    for n = 1:L1
        n0 = nodelist(n); %n0 is the nodeid of the nth node in nodelist
        numNbrs = conlist(n, 1); %numNbrs is the number of connections for node n0 in conlist
        Btotal = zeros(3, 3);

        for i = 1:numNbrs
            ii = conlist(n, i + 1); % connectionid for this connection
            linkid = connectivity(n0, 2 * ii);
            posinlink = connectivity(n0, 2 * ii + 1);
            n1 = links(linkid, 3 - posinlink);

            if rn(n1, end) == 67
                continue
            end

            rt = rn(n1, 1:3) - rn(n0, 1:3); % calculate the length of the link and its tangent line direction
            L = norm(rt);
            %fprintf('ii=%i, linkid=%i, n0=%i, n1=%i, L=%f \n',ii,linkid,n0,n1,L);
            if L > 0.0
                fsegn0 = fseg(linkid, 3 * (posinlink - 1) + (1:3));
                %             if norm(fsegn0)/L<0.0015
                %                 fsegn0=[0,0,0];
                %             end
                fn(n, :) = fn(n, :) + fsegn0; % nodeid for the node that n0 is connected to
                burgv = links(connectivity(n0, 2 * ii), 3:5); % burgers vector of the link
                mag = norm(burgv);
                checkv = abs(burgv);
                checkv = checkv / min(checkv);
                check1 = sum(abs(1 - checkv(:)) < tol);
                check2 = sum(abs(1 - checkv(:) / 2) < tol);
                check3 = sum(abs(1 - checkv(:) / 3) < tol);
                linedir = rt ./ L;
                checkmag = abs(sqrt(3) * 0.5 - mag);

                if check1 == 3 && checkmag <= eps || check1 == 2 && check2 == 1 && checkmag <= eps || check1 == 1 && check2 == 1 && check3 == 1 && checkmag <= eps
                    costh2 = (linedir * burgv')^2 / (burgv * burgv'); % (lhat.bhat)^2 = cos^2(theta)% calculate how close to screw the link is
                    sinth2 = 1 - costh2;
                    %                 Btotal=Btotal+mag.*((0.5*L).*((Bscrew).*eye(3)+(Bline-Bscrew).*(linedir'*linedir)));           % build the drag matrix assuming that the dislocation is screw type
                    if sinth2 > tol% not pure screw segment
                        dotprods = planelist * burgv' / mag;
                        slipplanes = planelist(abs(dotprods) < eps, :);
                        dotprods2 = slipplanes * linedir';
                        cosdev = dotprods2(abs(dotprods2) == min(abs(dotprods2)));

                        if size(cosdev, 1) > 1
                            cosdev = cosdev(1);
                        end

                        ndir = slipplanes(dotprods2 == cosdev, :);

                        if size(ndir, 1) > 1
                            ndir = ndir(1, :);
                        end

                        %                     ndir=cross(burgv,linedir)./sqrt((burgv*burgv')*sinth2);                                            % correct the drag matrix for dislocations that are not screw type
                        mdir = cross(ndir, linedir);
                        clinedir = cross(mdir, ndir);
                        linecos2 = (linedir * clinedir')^2;
                        linesin2 = 1 - linecos2;
                        %fprintf('ndir= %f %f %f \n',ndir(1),ndir(2),ndir(3));
                        %fprintf('mdir= %f %f %f \n',mdir(1),mdir(2),mdir(3));
                        Bglide = 1 / sqrt((1 / Bedge^2) * sinth2 + (1 / Bscrew^2) * costh2); % Eqn (112) from Arsenlis et al 2007 MSMSE 15 553
                        Bglide = 1 / sqrt((1 / Beclimb^2) * linesin2 + (1 / Bglide^2) * linecos2);
                        Bline2 = 1 / sqrt((1 / Bscrew^2) * sinth2 + (1 / Bedge^2) * costh2);
                        Bline2 = 1 / sqrt((1 / Beclimb^2) * linesin2 + (1 / Bline2^2) * linecos2);
                        %                     Bclimb=sqrt( (Beclimb^2 ) * sinth2 + ( Bscrew^2 ) * costh2);
                        Btotal = Btotal + mag .* ((0.5 * L) .* ((Bglide) .* (mdir' * mdir) + (Beclimb) .* (ndir' * ndir) + (Bline2) .* (clinedir' * clinedir)));
                    else % pure screw segment

                        if norm(fsegn0) > eps
                            fnorm = fsegn0 / norm(fsegn0);
                        else
                            fnorm = [0 0 0];
                        end

                        dotprods = planelist * burgv' / mag;
                        slipplanes = planelist(abs(dotprods) == min(abs(dotprods)), :);
                        dotprods2 = slipplanes * fnorm';
                        cosdev = dotprods2(abs(dotprods2) == min(abs(dotprods2)));

                        if size(cosdev, 1) > 1
                            cosdev = cosdev(1);
                        end

                        ndir = slipplanes(dotprods2 == cosdev, :);
                        fsegn1 = fseg(linkid, 3 * (2 - posinlink) + (1:3));

                        if norm(fsegn1) > eps
                            fnorm_alt = fsegn1 / norm(fsegn1);
                        else
                            fnorm_alt = [0 0 0];
                        end

                        dotprods2_alt = slipplanes * fnorm_alt';
                        cosdev_alt = dotprods2_alt(abs(dotprods2_alt) == min(abs(dotprods2_alt)));

                        if size(cosdev_alt, 1) > 1
                            cosdev_alt = cosdev_alt(1);
                        end

                        if size(cosdev_alt, 1) > 1
                            cosdev_alt = cosdev_alt(1);
                        end

                        if ~isequal(size(cosdev_alt), [1 1]) ||~isequal(size(slipplanes, 1), size(dotprods2_alt, 1)) ||~isequal(size(dotprods2_alt, 2), 1)
                            fprintf('mobbcc_bb1b: erroneous slip planes\n')
                        end

                        ndir_alt = slipplanes(dotprods2_alt == cosdev_alt, :);

                        if size(ndir, 1) == 1 && size(ndir_alt, 1) == 1
                            planecheck = 1 - (ndir * ndir_alt');
                        end

                        if size(ndir, 1) > 1 || size(ndir_alt, 1) > 1 || planecheck > eps
                            ndir = ndir(1, :);
                            mdir = cross(ndir, linedir);

                            if abs(cosdev) < eps
                                Btotal = Btotal + mag .* ((0.5 * L) .* ((Bscrew) .* (mdir' * mdir) + (Bscrew) .* (ndir' * ndir) + (Bedge) .* (linedir' * linedir)));
                            else
                                Btotal = Btotal + mag .* ((0.5 * L) .* ((Beclimb) .* (mdir' * mdir) + (Beclimb) .* (ndir' * ndir) + (Bedge) .* (linedir' * linedir)));
                            end

                        else
                            mdir = cross(ndir, linedir);
                            cosdev2 = cosdev * cosdev;
                            cosratio = 1 - 4 * cosdev2;
                            sinratio = 1 - cosratio;
                            Bglide = 1 / sqrt((1 / Beclimb^2) * sinratio + (1 / Bscrew^2) * cosratio);
                            Btotal = Btotal + mag .* ((0.5 * L) .* ((Bglide) .* (mdir' * mdir) + (Beclimb) .* (ndir' * ndir) + (Bedge) .* (linedir' * linedir)));
                        end

                    end

                else
                    costh2 = (linedir * burgv')^2 / (burgv * burgv'); % (lhat.bhat)^2 = cos^2(theta)% calculate how close to screw the link is
                    sinth2 = 1 - costh2;
                    Bline2 = 1 / sqrt((1 / Bscrew^2) * sinth2 + (1 / Bedge^2) * costh2); % Adapted from Eqn (112) from Arsenlis et al 2007 MSMSE 15 553
                    Btotal = Btotal + mag .* ((0.5 * L) .* ((Beclimb) .* eye(3) + (Bline2 - Beclimb) .* (linedir' * linedir)));
                end

            end

        end

        %     for z=1:3
        %         fprintf('%f %f %f \n',Btotal(z,1),Btotal(z,2),Btotal(z,3));
        %     end
        %     fprintf('\n');
        if norm(Btotal) < eps
            vn(n, :) = [0 0 0];
        elseif rcond(Btotal) < 1e-15
            Btotal_temp = Btotal + 1e-6 * max(max(abs(Btotal))) * eye(3);
            Btotal_temp2 = Btotal - 1e-6 * max(max(abs(Btotal))) * eye(3);
            vn_temp = (Btotal_temp \ fn(n, :)')';
            vn_temp2 = (Btotal_temp2 \ fn(n, :)')';
            vn(n, :) = 0.5 * (vn_temp + vn_temp2);
        else
            vn(n, :) = (Btotal \ fn(n, :)')'; % Btotal was wellconditioned so just take the inverse
        end

        if any(isnan(vn))
            fprintf('YDFUS, see line 157 of mobbcc_bb1b\n');
        end

    end

end