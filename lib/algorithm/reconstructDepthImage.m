function [ results ] = reconstructDepthImage( solver, settings, ...
    height, width, sampling_matrix, measured_vector, samples, initial_guess, ...
    depth, rgb, odometry, pc_truth, figHandle, subplot_id)
%reconstructDepthImage A wrapper for all solvers, to avoid repeated codes
%   Detailed explanation goes here

% whether to use point cloud for err computation or not.
% set to false for single-frame reconstruction; false for multi-frame
doPointCloud = nargin>10;

%% slope_cartesian_noDiag generates a list of x coordiantes
if strcmp(solver, 'L1-cart')
    if ~doPointCloud
        error('Ground truth point cloud not provided as a input argument.')
    end
    
    tic
    x_slope_cartesian = l1ReconstructionOnPointcloud( height, width, ...
            sampling_matrix, measured_vector, pc_truth.Location(:, [2, 3]), ...
            settings, samples, initial_guess);
    time = toc;
    
    % reconstruct the point cloud
    xyz_slope_cartesian = pc_truth.Location;
    xyz_slope_cartesian(:, 1) = x_slope_cartesian;
    pc_rec = pointCloud(xyz_slope_cartesian, 'Color', pc_truth.Color);
    
    % reconstruct the point cloud with only valid colors
    color_idx = find(ismember(pc_truth.Color, [0 0 0], 'rows') == 0);
    pc_rec_noblack = pointCloud(xyz_slope_cartesian(color_idx,:), 'Color', pc_truth.Color(color_idx,:));
    
    % reconstruct projected depth image
    [ depth_rec, rgb_rec ] = pc2images( pc_rec, odometry, settings );

%% other methods generate a vectorized depth image
else
    tic
    switch solver
        case 'naive'
            x = linearInterpolationOnImage( depth, samples, measured_vector );
        case 'L1-diag'
            x = l1ReconstructionOnImage( height, width, ...
                sampling_matrix, measured_vector, settings, samples, initial_guess);
        case 'L1'
            x = l1ReconstructionOnImage( height, width, ...
                sampling_matrix, measured_vector, settings, samples, initial_guess);
    end
    time = toc;
    
    % reshape the vectorized depth image into a image
    depth_rec = reshape(x, height, width);

    if doPointCloud
        % reconstruct the point cloud
        pc_rec = depth2pc(depth_rec, rgb, odometry, settings, false);

        % reconstruct the point cloud with only valid colors
        pc_rec_noblack = depth2pc(depth_rec, rgb, odometry, settings, true);
    else
        nullMatrix = zeros(0,3);
        pc_rec = pointCloud(nullMatrix);
        pc_rec_noblack = pointCloud(nullMatrix);
    end
end

if doPointCloud
    err = computeErrorPointcloud(pc_rec.Location, pc_truth.Location, settings); 
else
    err = computeErrorImage(depth_rec, depth, settings); 
end

if settings.show_debug_info
    disp(sprintf(' --- %8s: time = %.5gms, err = %.3gcm', solver, 1000*time, 100*err.euclidean))
end

if settings.show_pointcloud
    figure(figHandle);
    subplot(subplot_id);
    pcshow(pc_rec_noblack, 'MarkerSize', settings.markersize); xlabel('x'); ylabel('y'); zlabel('z'); 
    title({solver, ['(avg err=', sprintf('%.3g', 100*err.euclidean), 'cm)']})
    drawnow;
end

results.error = err;
results.time = time;
results.pc_rec_noblack = pc_rec_noblack;
results.depth_rec = depth_rec;

end

