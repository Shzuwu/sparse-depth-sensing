function [results, settings] = reconstruct_single_frame(img_ID, settings)
addpath(genpath('lib'))
% addpath('plots');

%% settings for the default test example
if nargin < 2    
    close all; clear; clc;
    settings.dataset = 'structure_sensor';   % lids_floor6, ZED, structure_sensor
    img_ID = 250;

    createSettings
    
    settings.solver = 'nesta';  
    settings.use_L1 = false;
    settings.use_L1_diag = true;
    settings.use_L1_cart = false;
    settings.subSample = 0.4;               % subsample original image, to reduce its size
    settings.percSamples = 0.01;
    settings.sampleMode = 'depth-edges';   % 'uniform', 'harris-feature', 'regular-grid', 'depth-edges'
    settings.doAddNeighbors = true;
    settings.stretch.flag = false;
    settings.stretch.delta_y = 0; %1e-5;
    settings.stretch.delta_z = settings.stretch.delta_y;
end

%% Load Data
[ depth, rgb, odometry, depth_orig ] = getRawData( settings, img_ID );

% rgb may be not available
if isKinectDataset(settings) && sum(rgb(:)) == 0
    results.rgb = [];
    return
end

% if settings.show_pointcloud
%     pc_truth_orig = depth2pc(depth_orig, rgb, odometry, settings, false);
%     pc_truth = depth2pc(depth, rgb, odometry, settings, false);
%     pc_truth_noblack = depth2pc(depth, rgb, odometry, settings, true);
%     
%     % convert raw data to point cloud  
%     if strcmp(settings.pc_frame, 'body')
%         % create null odometry information
%         odometry.Position.X = 0;
%         odometry.Position.Y = 0;
%         odometry.Theta = 0;    
%     end
%     
%     fig1 = figure(1);
%     subplot(221)
%     pcshow(pc_truth_noblack, 'MarkerSize', settings.markersize); xlabel('x'); ylabel('y'); zlabel('z'); title('Ground Truth'); 
% else
%     fig1 = [];
% end

%% Create measurements
samples = createSamples( depth, rgb, settings );

% if samples are not created properly
if size(samples, 1) == 0
    results = [];
    return;
end
xGT = depth(:);  
N = length(xGT);    % total number of valid 3D points
K = length(samples);    % total number of measurements

height = size(depth,1);
width = size(depth,2);

% create sparse sampling matrix
Rfull = speye(N);
sampling_matrix = Rfull(samples, :);
img_sample = nan * ones(size(depth));
img_sample(samples) = 255 * xGT(samples);

% % create point cloud
% [pc_samples] = depth2pc(img_sample, rgb, odometry, settings, false);

% visualization
if settings.show_pointcloud
    figure(fig1);
    subplot(222)
    pcshow(pc_samples, 'MarkerSize', settings.markersize); xlabel('x'); ylabel('y'); zlabel('z'); 
    title('Input (Samples)')
end

%% create (possibly noisy) measurements
if settings.addNoise    
    noise = settings.epsilon * (2*rand(K,1)-1);
else
    noise = zeros(K,1);
end
measured_vector = sampling_matrix * xGT + noise;    

%% naive
if settings.use_naive
    results.naive = reconstructDepthImage( 'naive', settings, ...
        height, width, sampling_matrix, measured_vector, samples, [], ...
        depth, rgb);
end

%% L1 
if settings.use_L1
    settings.useDiagonalTerm = false;
    results.L1 = reconstructDepthImage( 'L1', settings, ...
        height, width, sampling_matrix, measured_vector, samples, results.naive.depth_rec(:), ...
        depth, rgb);
end

%% L1-diag
if settings.use_L1_diag
    settings.useDiagonalTerm = true;
    results.L1_diag = reconstructDepthImage( 'L1-diag', settings, ...
        height, width, sampling_matrix, measured_vector, samples, results.naive.depth_rec(:), ...
        depth, rgb);
end

%% L1-cart 
if settings.use_L1_cart
    results.L1_cart = reconstructDepthImage( 'L1-cart', settings, ...
        height, width, sampling_matrix, measured_vector, samples, results.naive.depth_rec(:), ...
        depth, rgb);
end

%% Save results
% results.pc_truth_noblack = pc_truth_noblack;
% results.pc_truth = pc_truth;
% results.pc_truth_orig = pc_truth_orig;
% results.pc_samples = pc_samples;
results.img_sample = img_sample;

results.rgb = rgb;
results.depth = depth;
results.K = K;

%% Perspective projection to images (for visualization)
if settings.show_debug_info    
    figure(2);

    subplot(231); imshow(rgb); title('RGB');
    subplot(232); display_depth_image( depth, settings, 'Ground Truth Depth' )
    subplot(234); display_depth_image( img_sample, settings, 'Input (Samples)' );
    
    if settings.use_naive  
        subplot(235);
        titleString = {'naive', ['(avg error=', sprintf('%.2g', 100*results.naive.error.euclidean), 'cm)']};
        display_depth_image( results.naive.depth_rec, settings, titleString );  
    end

    subplot(236); 
    if settings.use_L1_diag
        titleString = {'L1-diag', ['(avg error=', sprintf('%.2g', 100*results.L1_diag.error.euclidean), 'cm)']};
        display_depth_image( results.L1_diag.depth_rec, settings, titleString );
    elseif settings.use_L1
        titleString = {'L1', ['(avg error=', sprintf('%.2g', 100*results.L1.error.euclidean), 'cm)']};
        display_depth_image( results.L1.depth_rec, settings, titleString );
    elseif settings.use_L1_cart
        titleString = {'L1-cart', ['(avg error=', sprintf('%.2g', 100*results.L1_cart.error.euclidean), 'cm)']};
        display_depth_image( results.L1_cart.depth_rec, settings, titleString );
    end
    drawnow
end
