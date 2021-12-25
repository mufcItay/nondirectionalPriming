close all;
clc;
clear;
warning('off')
rng(1)

data = readtable('data/BM2018Data.csv');
exp_names = unique(data.Exp);

for i_e=1:length(exp_names)
    
    exp_data = data(strcmp(data.Exp,exp_names{i_e}),:);
    exp_ss = unique(exp_data.subNum);
    exp_acc = nan(max(exp_ss),1);

    for i_s = exp_ss'
        
        subj_data = exp_data(exp_data.subNum==i_s,:);
        rt = subj_data.rt;
        cong = strcmp(subj_data.cong,'cong');

        SVMModel = fitcsvm(rt,cong,'Standardize',true,'ClassNames',[0,1]);
        c = cvpartition(cong,'KFold',5);
        CVSVMModel = crossval(SVMModel,'CVPartition',c);

        exp_acc(i_s) = 1-kfoldLoss(CVSVMModel);
    end
    
    save(['classification_accuracy_',exp_names{i_e},'.mat'],'exp_acc');
    [h,p,ci,stats]=ttest(exp_acc,0.5);
end

