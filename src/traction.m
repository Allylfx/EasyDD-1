% gamma = [gammat;gammaMixed]; ndis = 1; xdis=dx/2,ydis=dy/2,zdis=dz/2;

function f_tilda = traction(gamma, segments, xnodes, a, MU, NU, f_tilda)

    % find traction on boundary due to dislocations
    %
    %
    % rectangulare domain. Note for shared nodes. Set priority is
    % 1) left (x=0)/right  (x=dx)
    % 2) top (z=dz)/bottom  (z=0)
    % 3) front (y=0)/back (y=dy)
    %
    %-----------------------------------------------
    %
    %                   (mx,my)
    %
    %-----------------------------------------------

    % modify  boundary conditions for concave domain

    nodes = gamma(:, 1);
    area = gamma(:, 2);
    normal = gamma(:, 3:5);

    lseg = size(segments, 1);
    lgrid = size(nodes, 1);

    p1x = segments(:, 6);
    p1y = segments(:, 7);
    p1z = segments(:, 8);

    p2x = segments(:, 9);
    p2y = segments(:, 10);
    p2z = segments(:, 11);

    bx = segments(:, 3);
    by = segments(:, 4);
    bz = segments(:, 5);

    x = xnodes(nodes, 1);
    y = xnodes(nodes, 2);
    z = xnodes(nodes, 3);

    [sxx, syy, szz, sxy, syz, sxz] = StressDueToSegsMex(lgrid, lseg, ...
        x, y, z, ...
        p1x, p1y, p1z, ...
        p2x, p2y, p2z, ...
        bx, by, bz, ...
        a, MU, NU);

    Tx = sxx .* normal(:, 1) + sxy .* normal(:, 2) + sxz .* normal(:, 3);
    Ty = sxy .* normal(:, 1) + syy .* normal(:, 2) + syz .* normal(:, 3);
    Tz = sxz .* normal(:, 1) + syz .* normal(:, 2) + szz .* normal(:, 3);

    ATx = area .* Tx;
    ATy = area .* Ty;
    ATz = area .* Tz;

    %populate f_tilda
    f_tilda(3 * nodes - 2) = ATx;
    f_tilda(3 * nodes - 1) = ATy;
    f_tilda(3 * nodes) = ATz;
    % for j=1:lgrid
    %     gn=nodes(j);
    %     f_tilda(3*gn-2) = ATx(j);
    %     f_tilda(3*gn-1) = ATy(j);
    %     f_tilda(3*gn) = ATz(j);
    % end

end
