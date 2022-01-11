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
params.interaction_cond = 'Inter';

params.SVM = true;
params.signConsistency = true;
params.directional = true;

params.statistic = @(x) mean(x);
filename = 'Yap_Colleagues_inter';

analyzeInteraction(params,filename);


