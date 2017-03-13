close all; clc; clear;
addpath(genpath('../lib'))

%% Data settings
createSettings
settings.dataset = 'structure_sensor';
settings.solver = 'nesta'; 
settings.subSample = 0.5;          % subsample original image to reduce its size
settings.percSamples = 0.01;       % perceptage of samples relative to image size
settings.sampleMode = 'depth-edges';   % choose from 'uniform', 'harris-feature', 'regular-grid'
settings.doAddNeighbors = true;   % set to true, if we want to sample neighboring pixels

resultsFolder = getPath( 'results', settings );
if exist(resultsFolder, 'dir') == 0
    error(sprintf('The results folder %s is not found. \nPlease generate results first.', resultsFolder))
end

%% Video settings
subfigureBottomMargin = 0.002;
subfigureSideMargin = 0.008;

outputVideo = VideoWriter('video_out.avi');
outputVideo.FrameRate = 10;
open(outputVideo);

%% Create image frames
figure(1);
set(gcf, 'Position', [0 0 1000, 280]); %<- Set size
set(gcf, 'Color', 'White')   % set white background

D = dir([resultsFolder, '/*.mat']);
num_data = length(D(not([D.isdir])));
for i = 1 : num_data
    disp(sprintf('index:%d', i))
    mat_filename = sprintf('%s/%03d.mat', resultsFolder, i);
    if exist(mat_filename, 'file') == 0
        continue;
    end
    load(mat_filename);
    
    h=subplot(131); 
    display_depth_image(results.depth, settings, 'Ground Truth'); 
    set(h, 'pos', [subfigureSideMargin, subfigureBottomMargin, ...
        1/3-2*subfigureSideMargin, 1-2*subfigureBottomMargin]);
    
    h=subplot(132); 
    percentage = 100 * results.K / prod(size(results.depth));
    display_depth_image(results.img_sample, settings, sprintf('Measurements (%.2f%%)', percentage)); 
    set(h, 'pos', [1/3+subfigureSideMargin, subfigureBottomMargin, ...
        1/3-2*subfigureSideMargin, 1-2*subfigureBottomMargin]);
    
    h = subplot(133); 
    err = results.L1_diag.error.depth_only * 100;   % error in cm
    display_depth_image(results.L1_diag.depth_rec, settings, sprintf('Reconstruction (avg err=%.2fcm)', err));
    set(h, 'pos', [2/3+subfigureSideMargin, subfigureBottomMargin, ...
        1/3-2*subfigureSideMargin, 1-2*subfigureBottomMargin]);

    F = getframe(gcf);
    writeVideo(outputVideo, F);
    % pause();
end

%% Finish the video
close(outputVideo)