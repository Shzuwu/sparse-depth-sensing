function [ error_image ] = computeErrorImage( depth_rec, depth_gt, settings )
%computeErrorPointcloud Compute average reconstruction error in milimeters
%   There are two error metrics: the first one computes the error along x
%   only; the second one computes the euclidean distances 

diff = removeNaN(vec(depth_rec - depth_gt));
error_image.depth_only = mean(abs(diff));
error_image.euclidean = error_image.depth_only ;

end