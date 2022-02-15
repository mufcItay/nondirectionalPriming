close all;
clc;
clear;
warning('off')

% Stelzer, J., Chen, Y., & Turner, R. (2013). 
% Statistical inference and multiple testing correction in 
% classification-based multi-voxel pattern analysis (MVPA): 
% random permutations and cluster size control. Neuroimage, 65, 69-82.
params.N_perm = 25; %number of label shuffling per participant
params.N_null = 10000; %number of samples in bootstrapped null distribution
params.rng = 1;

params.N_splits = 500; %for sign consistency analysis
params.control_for = ''; 
params.predict = 'cong'; 
params.x = 'rt';
params.filter_column = '';
% params.inclusion_value = 1; %for filtering;

params.SVM = true;
params.signConsistency = true;
params.directional = true;

% filter function to enable subsetting the data of the experiment
% differently in each analysis iteration
% N of included subjects for analysis
params.filterN = 15; 
% gets the total number of subjects 'N' and the required N, and filters
% randomly
params.filterFunc = @(N, filterN) randsample(N, filterN); 

params.plot = false;
params.statistic = @(x) mean(x);
filename = 'PKTE';
% a table including the results of all analysis iterations
resAll = table;
NAnalysisIterations = 100;
% perform the analysis iteratively, each time with a different random generator
for ind=1:NAnalysisIterations
    params.rng = ind;
    res = analyzePriming(params,filename);
    res.rng = ind;
    % concatenate previous analysis resutls with the current results
    resAll = vertcat(resAll, res);
end
writetable(resAll, strcat('analysisResults_N', string(params.filterN),...
    '_Iter_',string(NAnalysisIterations),'.csv'));