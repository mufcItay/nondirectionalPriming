close all;
clc;
clear;
warning('off')
rng(1)

data = readtable('data/BM2018Data_Full.csv');
data = data(data.correct==1,:);
target_cong = {};
for i_r = 1:size(data,1)
    if strcmp(data.ptCong{i_r},'same')
        target_cong{end+1}=data.cong{i_r};
    else
        target_cong(end+1)=setdiff({'cong','incong'},data.cong{i_r});
    end
end
data.target_cong = target_cong';

rt_residuals = [];

exp_names = unique(data.Exp);

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


N_perm = 100;

for i_e=3
    
    exp_data = data(strcmp(data.Exp,exp_names{i_e}),:);
    exp_ss = unique(exp_data.subNum);
    exp_acc = nan(max(exp_ss),1);
    
    for i_s = exp_ss'
        
        subj_data = exp_data(exp_data.subNum==i_s,:);
        
        rt_residuals = subj_data.rt_residuals;
        cong = strcmp(subj_data.cong,'cong');

        SVMModel = fitcsvm(rt_residuals,cong,'Standardize',true,'ClassNames',[0,1]);
        c = cvpartition(cong,'KFold',5);
        CVSVMModel = crossval(SVMModel,'CVPartition',c);

        exp_acc(i_s) = 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
        
    end
    
    mean_accuracy = nanmean(exp_acc)
    
    %create null distribution
    null_distribution = [];
    
    for i_p = 1:N_perm
        i_p
        exp_acc = nan(max(exp_ss),1);
    
        for i_s = exp_ss'

            subj_data = exp_data(exp_data.subNum==i_s,:);
            rt_residuals = subj_data.rt_residuals;

            rt_residuals = rt_residuals(randperm(length(rt_residuals)));
            cong = strcmp(subj_data.cong,'cong');
            
            SVMModel = fitcsvm(rt_residuals,cong,'Standardize',true,'ClassNames',[0,1]);
            c = cvpartition(cong,'KFold',5);
            CVSVMModel = crossval(SVMModel,'CVPartition',c);

            exp_acc(i_s) = 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');

        end
        
        null_distribution(end+1)=nanmean(exp_acc);
    end
    
    fig=figure;
    hold on;
    hist(null_distribution);
    xline(mean_accuracy);
    xlabel('cross validated classification accuracy');
    ylabel('number of permuatations')
    title([exp_names{i_e},': predicting prime target congruency'])
    s=hgexport('readstyle','presentation');
    s.Format = 'png';
    s.Width = 8;
    s.Height = 4;
    hgexport(fig,fullfile('figures',[exp_names{i_e},'_ptCong_perm']),s);
end

