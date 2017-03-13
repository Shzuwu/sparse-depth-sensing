function [ flag ] = isSyntheticDataset( settings )
%ISKINECTDATASET Return true if we are runninng tests on a Kinect dataset
%   Detailed explanation goes here

flag = strcmp(settings.dataset, 'pwlinear_nbCorners=10')

end

