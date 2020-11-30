function [ep_inc, wp_inc] = calcPlasticStrainIncrement(rnnew, rn, links, FEM)
    %% Extraction
    
    % FEM:
    simvol = FEM.simvol;
    
    %% Calculate plastic strain increment
    
    seg = rn(links(:, 2), 1:3) - rn(links(:, 1), 1:3);
    segnew = rnnew(links(:, 2), 1:3) - rnnew(links(:, 1), 1:3);
    dx1 = rnnew(links(:, 2), 1:3) - rn(links(:, 1), 1:3);
    dA = cross(segnew + seg, dx1);
    fp_inc = 0.5 .* (links(:, 3:5)' * dA) ./ simvol;
    ep_inc = 0.5 .* (fp_inc + fp_inc');
    wp_inc = 0.5 .* (fp_inc - fp_inc');
end
