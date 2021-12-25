close all;
clc;
clear;
warning('off')
rng(1)

use_rt_residuals = 1; % set to 1 to control for main effect of response type
predict_ptCong = 0; % set to 1 to predict prime-target congruency rather than prime congruency

% Stelzer, J., Chen, Y., & Turner, R. (2013). 
% Statistical inference and multiple testing correction in 
% classification-based multi-voxel pattern analysis (MVPA): 
% random permutations and cluster size control. Neuroimage, 65, 69-82.

N_perm = 25; %number of label shuffling per participant
N_null = 10000; %number of samples in bootstrapped null distribution

rng = params.rng;

% load full dataset
data = readtable('data/BM2018Data_Full.csv');

exp_names = unique(data.Exp);

% we are only interested in trials where the participant corredctly
% identified the target
data = data(data.correct==1,:);

% create a column for target object/scene congruency, based on prime
% congruency and prime-target congruency
target_cong = {};
for i_r = 1:size(data,1)
    if strcmp(data.ptCong{i_r},'same')
        target_cong{end+1}=data.cong{i_r};
    else
        target_cong(end+1)=setdiff({'cong','incong'},data.cong{i_r});
    end
end

data.target_cong = target_cong';

if use_rt_residuals
% create a column for the residual variance in rt after controlling for
% target object-scene congruency.
    rt_residuals = [];

    for i_e=1:length(exp_names)

        exp_data = data(strcmp(data.Exp,exp_names{i_e}),:);
        exp_ss = unique(exp_data.subNum);

        for i_s = exp_ss'

            subj_data = exp_data(exp_data.subNum==i_s,:);

            rt = subj_data.rt;
            target_cong = double(strcmp(subj_data.target_cong,'cong'));
            p=polyfit(target_cong,rt,1);
            rt_residuals=[rt_residuals;polyval(p,target_cong)-rt];
            
        end
    end
    data.rt_residuals = rt_residuals;
end

% MAIN LOOP
for i_e=1:length(exp_names)
    
    exp_data = data(strcmp(data.Exp,exp_names{i_e}),:);
    exp_ss = unique(exp_data.subNum);
    exp_acc = nan(max(exp_ss),1);
    exp_shuffled_acc = nan(max(exp_ss),N_perm);
    
    for i_s = exp_ss'
        
        subj_data = exp_data(exp_data.subNum==i_s,:);
        
        if use_rt_residuals==1
            x = subj_data.rt_residuals;
        else 
            x = subj_data.rt;
        end
        
        if predict_ptCong==1
        	y = strcmp(subj_data.ptCong,'same');
        else
            y = strcmp(subj_data.cong,'cong');
        end

            
        SVMModel = fitcsvm(x,y,'Standardize',true,'ClassNames',[0,1]);
        c = cvpartition(y,'KFold',5);
        CVSVMModel = crossval(SVMModel,'CVPartition',c);
        
        %true accuracy for subject
        exp_acc(i_s) = 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
        
        % shuffled accuracy for subject
        for i_p = 1:N_perm
            shuffled_x = x(randperm(length(x)));
            SVMModel = fitcsvm(shuffled_x,y,'Standardize',true,'ClassNames',[0,1]);
            c = cvpartition(y,'KFold',5);
            CVSVMModel = crossval(SVMModel,'CVPartition',c);
            exp_shuffled_acc(i_s,i_p)= 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
        end
        
    end
    
    mean_accuracy = nanmean(exp_acc)
    
    %create null distribution
    null_distribution = [];
    
    for i_p = 1:N_null
        sample = [];
        for i_s = exp_ss'
            sample(end+1)=exp_shuffled_acc(i_s,randperm(N_perm,1));
        end
        null_distribution(end+1)=mean(sample);
    end
     
    fig=figure;
    hold on;
    hist(null_distribution);
    xline(mean_accuracy,'LineWidth',6);
    xlabel('cross validated classification accuracy');
    ylabel('number of permuatations')
    title(sprintf('%s: p=%.3f',exp_names{i_e},mean(null_distribution>=mean_accuracy)))
    s=hgexport('readstyle','presentation');
    s.Format = 'png';
    s.Width = 8;
    s.Height = 4;
    hgexport(fig,fullfile('figures',sprintf('%s_resid_%d_ptCong_%d',exp_names{i_e},use_rt_residuals,predict_ptCong)),s);
end

