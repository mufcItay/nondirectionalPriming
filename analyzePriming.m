function [] = analyzePriming(params,filename)

rng(params.rng)

% load full dataset
data = readtable(fullfile('data',[filename,'.csv']));
data.subNum = double(categorical(data.subNum)); %make it a number
exp_names = unique(data.Exp);

% should we filter trials?
if params.filter_column
    data = data(data.(params.filter_column)==params.inclusion_value,:);
end

if length(params.control_for)>1
% create a column for the residual variance in x after controlling for
% the control_for field
    residuals = [];

    for i_e=1:length(exp_names)

        exp_data = data(strcmp(data.Exp,exp_names{i_e}),:);
        exp_ss = unique(exp_data.subNum);

        for i_s = exp_ss'

            subj_data = exp_data(exp_data.subNum==i_s,:);

            x = subj_data.(params.x);
            control_for_str = subj_data.(params.control_for);
            control_for_bin = double(strcmp(control_for_str,control_for_str{1}));
            p=polyfit(control_for_bin,x,1);
            residuals=[residuals;x-polyval(p,control_for_bin)];
        end
    end
    data.x = residuals;
else
    data.x = data.(params.x);
end

% MAIN LOOP
for i_e=1:length(exp_names)
    
    exp = exp_names{i_e}
    
    exp_data = data(strcmp(data.Exp,exp),:);
    exp_ss = unique(exp_data.subNum);
    
    if params.SVM
        exp_acc = nan(max(exp_ss),1);
        exp_shuffled_acc = nan(max(exp_ss),params.N_perm);
    end
    
    if params.signConsistency
        exp_consistency = nan(max(exp_ss),1);
        exp_shuffled_consistency = nan(max(exp_ss),params.N_perm);
    end
    
    if params.directional
        exp_diff = nan(max(exp_ss),1);
        exp_shuffled_diff = nan(max(exp_ss),params.N_perm);
    end

    for i_s = exp_ss'
        
        find(exp_ss==i_s)/length(exp_ss)
        
        subj_data = exp_data(exp_data.subNum==i_s,:);
        [y_str, ord_y] = sort(subj_data.(params.predict));

        x = subj_data.x(ord_y);
        y = strcmp(y_str,y_str{1});
        
        k = min(sum(y==0),sum(y==1));
           
        if params.SVM & k>10
            
            SVMModel = fitcsvm(x,y,'Standardize',true,'ClassNames',[0,1]);
            c = cvpartition(y,'KFold',k);
            CVSVMModel = crossval(SVMModel,'CVPartition',c);

            %true accuracy for subject
            exp_acc(i_s) = 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
        end
        
        if params.signConsistency
            %true sign consistency for subject
            exp_consistency(i_s)=getSignConsistency(x,y,params.N_splits,params.statistic);
        end
        
        if params.directional
            %true difference in depndent measure per participant
            exp_diff(i_s) = params.statistic(x(y==0))-params.statistic(x(y==1));
        end
        
        % shuffled accuracy for subject
        for i_p = 1:params.N_perm
            shuffled_x = x(randperm(length(x)));
            
            if params.SVM & k>10
                SVMModel = fitcsvm(shuffled_x,y,'Standardize',true,'ClassNames',[0,1]);
                c = cvpartition(y,'KFold',k);
                CVSVMModel = crossval(SVMModel,'CVPartition',c);
                exp_shuffled_acc(i_s,i_p)= 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
            end
            
            if params.signConsistency
                exp_shuffled_consistency(i_s,i_p)=getSignConsistency(shuffled_x,y,params.N_splits,params.statistic);
            end
            
            if params.directional
                exp_shuffled_diff(i_s,i_p)=params.statistic(shuffled_x(y==0))-params.statistic(shuffled_x(y==1));
            end
        end
        
    end
    
    fig=figure;
    if params.SVM
        %create null distribution
        SVM_null_distribution = [];

        for i_p = 1:params.N_null
            sample = [];
            for i_s = exp_ss'
                sample(end+1)=exp_shuffled_acc(i_s,randperm(params.N_perm,1));
            end
            SVM_null_distribution(end+1)=nanmean(sample);
        end
        
        acc_p = mean(SVM_null_distribution>=nanmean(exp_acc));
        subplot(2,2,1)
        hold on;
        histogram(SVM_null_distribution,'Normalization','probability','DisplayStyle','stairs');
        xline(nanmean(exp_acc),'LineWidth',1);
        xlabel('cross validated classification accuracy');
        ylabel('probability')
        title(sprintf('%s: p=%.3f','SVM accuracy',acc_p))
    end
    
    if params.signConsistency
        %create null distribution
        consistency_null_distribution = [];

        for i_p = 1:params.N_null
            sample = [];
            for i_s = exp_ss'
                sample(end+1)=exp_shuffled_consistency(i_s,randperm(params.N_perm,1));
            end
            consistency_null_distribution(end+1)=mean(sample);
        end
        
        consistency_p = mean(consistency_null_distribution>=nanmean(exp_consistency));
        subplot(2,2,2)
        hold on;
        histogram(consistency_null_distribution,'Normalization','probability','DisplayStyle','stairs');
        xline(nanmean(exp_consistency),'LineWidth',1);
        xlabel('mean sign consistency');
        ylabel('probability')
        title(sprintf('%s: p=%.3f','Sign consistency',consistency_p))
    end
    
    if params.directional
        %create null distribution
        diff_null_distribution = [];

        for i_p = 1:params.N_null
            sample = [];
            for i_s = exp_ss'
                sample(end+1)=exp_shuffled_diff(i_s,randperm(params.N_perm,1));
            end
            diff_null_distribution(end+1)=mean(sample);
        end
        
        diff_p = mean(diff_null_distribution>=nanmean(exp_diff));
        subplot(2,2,3)
        hold on;
        histogram(diff_null_distribution,'Normalization','probability','DisplayStyle','stairs');
        xline(nanmean(exp_diff),'LineWidth',1);
        xlabel('mean difference');
        ylabel('probability')
        title(sprintf('%s: p=%.3f','Directional test',diff_p))

    end
    
    s=hgexport('readstyle','presentation');
    s.Format = 'png';
    s.Width = 8;
    s.Height = 8;
    
    % save
    dir_name = fullfile('.','analyzed',filename,exp_names{i_e},params.x);
    if length(params.filter_column)>0
        dir_name = fullfile(dir_name,['filtering_by_',params.filter_column]);
    end
    if length(params.control_for)>0
        dir_name = fullfile(dir_name,['controlling_for_',params.control_for]);
    end
    
    if ~isdir(dir_name)
        mkdir(dir_name)
    end
    
    save(fullfile(dir_name,'params'),'params');
    if params.SVM
        save(fullfile(dir_name,'SVM_results'),'exp_acc','exp_shuffled_acc','SVM_null_distribution','acc_p');
    end
    
    if params.signConsistency
         save(fullfile(dir_name,'consistency_results'),'exp_consistency','exp_shuffled_consistency','consistency_null_distribution','consistency_p');
    end
    
    if params.directional
         save(fullfile(dir_name,'directional_results'),'exp_diff','exp_shuffled_diff','diff_null_distribution','diff_p');
    end
        
    hgexport(fig,fullfile(dir_name,'summary_figure.png'),s);
end
% 


end

