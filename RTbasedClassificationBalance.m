close all;
clc;
clear;
warning('off')
rng(1)

data = readtable('data/BM2018Data.csv');
exp_names = unique(data.Exp);

for i_e=3
    
    exp_data = data(strcmp(data.Exp,exp_names{i_e}),:);
    exp_ss = unique(exp_data.subNum);
    exp_acc = nan(max(exp_ss),1);

    for i_s = exp_ss'
        
        subj_data = exp_data(exp_data.subNum==i_s,:);
        rt = subj_data.rt;
        cong = strcmp(subj_data.cong,'cong');
        
        subject_accuracies = [];
        
        %balance set
        %which is more frequent - cong or incong?
        frequent = round(mean(cong));
        infrequent = 1-frequent;
        
        %by how much?
        n_frequent = sum(cong==frequent);
        n_infrequent = sum(cong==infrequent);
        
        %what is the difference?
        diff = n_frequent-n_infrequent;
        
        frequent_indices = find(cong==frequent);
        
        for i_r = 1:100
            
            frequent_indices = frequent_indices(randperm(length(frequent_indices)));
            first_indices = frequent_indices(1:diff);
            
            shorter_cong = cong;
            shorter_rt = rt;
            shorter_cong(first_indices)=[];
            shorter_rt(first_indices)=[];


            SVMModel = fitcsvm(shorter_rt,shorter_cong,'Standardize',true,'ClassNames',[0,1]);
            c = cvpartition(shorter_cong,'KFold',5);
            CVSVMModel = crossval(SVMModel,'CVPartition',c);
            
            subject_accuracies(end+1)=1-kfoldLoss(CVSVMModel);
        end
        exp_acc(i_s) = mean(subject_accuracies);
    end
    
    save(['classification_accuracy_',exp_names{i_e},'.mat'],'exp_acc');
    [h,p,ci,stats]=ttest(exp_acc,0.5)
end

