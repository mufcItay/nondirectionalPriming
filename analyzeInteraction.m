function [] = analyzeInteraction(params,filename)

rng(params.rng)

% load full dataset
data = readtable(fullfile('data',[filename,'.csv']));
data.subNum = double(categorical(data.subNum)); %make it a number
exp_names = unique(data.Exp);
inter_conditions = unique(data{:,params.interaction_cond});
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
    % initialize data structures for later analysis
    if params.SVM
        cond_acc = nan(length(inter_conditions),max(exp_ss));
        cond_shuffled_acc = nan(params.N_perm,max(exp_ss));
    end

    if params.signConsistency
        cond_consistency = nan(length(inter_conditions),max(exp_ss));
        cond_shuffled_consistency = nan(length(inter_conditions), max(exp_ss), params.N_perm);

        cond_consistency = nan(length(inter_conditions),max(exp_ss));
        cond_shuffled_consistency = nan(length(inter_conditions), max(exp_ss), params.N_perm);
    end

    if params.directional
        cond_diff = nan(length(inter_conditions),max(exp_ss));
        cond_shuffled_diff = nan(length(inter_conditions), max(exp_ss), params.N_perm);
    end

    for i_condition = 1:length(inter_conditions)
        condition_data = exp_data(strcmp(string(exp_data{:,params.interaction_cond}),...
            string(inter_conditions(i_condition))),:);
        
        for i_s = exp_ss'
        
            find(exp_ss==i_s)/length(exp_ss)

            subj_data = condition_data(condition_data.subNum==i_s,:);
            [y_str, ord_y] = sort(subj_data.(params.predict));
            y_str = string(y_str);
            x = subj_data.x(ord_y);
            y = strcmp(y_str,y_str{1});

            k = min(sum(y==0),sum(y==1));

            if params.SVM & k>10

                SVMModel = fitcsvm(x,y,'Standardize',true,'ClassNames',[0,1]);
                c = cvpartition(y,'KFold',k);
                CVSVMModel = crossval(SVMModel,'CVPartition',c);

                %true accuracy for subject
                cond_acc(i_condition,i_s) = 1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
            end

            if params.signConsistency
                %true sign consistency for subject
                cond_consistency(i_condition, i_s) = ...
                    getSignConsistency(x,y,params.N_splits,params.statistic);
            end

            if params.directional
                %true difference in depndent measure per participant
                cond_diff(i_condition, i_s) = params.statistic(x(y==0))-params.statistic(x(y==1));
            end

            % shuffled accuracy for subject
            for i_p = 1:params.N_perm
                shuffled_x = x(randperm(length(x)));

                if params.SVM & k>10
                    SVMModel = fitcsvm(shuffled_x,y,'Standardize',true,'ClassNames',[0,1]);
                    c = cvpartition(y,'KFold',k);
                    CVSVMModel = crossval(SVMModel,'CVPartition',c);
                    cond_shuffled_acc(i_condition, i_s,i_p)= ...
                        1-kfoldLoss(CVSVMModel, 'LossFun', 'ClassifError');
                end

                if params.signConsistency
                    cond_shuffled_consistency(i_condition, i_s,i_p) = ...
                        getSignConsistency(shuffled_x,y,params.N_splits,params.statistic);
                end

                if params.directional
                    cond_shuffled_diff(i_condition,i_s,i_p) = ...
                        params.statistic(shuffled_x(y==0))-params.statistic(shuffled_x(y==1));
                end
            end

        end
    end
    
    fig=figure;
    if params.SVM
         %create null distribution
        SVM_null_distribution = [];

		for i_p = 1:params.N_null
			sample_cond1 = [];
			sample_cond2 = [];
			for i_s = exp_ss'
			% assuming 2 conditions
				sample_cond1(end+1)=cond_shuffled_acc(1, i_s,randperm(params.N_perm,1));
				sample_cond2(end+1)=cond_shuffled_acc(2, i_s,randperm(params.N_perm,1));
			end
			SVM_null_distribution(end+1)=nanmean(sample_cond1) - nanmean(sample_cond2);
		end
        acc_p = mean(SVM_null_distribution>=nanmean(cond_acc(1,:) - cond_acc(2,:)));
        subplot(2,2,1)
        hold on;
        histogram(SVM_null_distribution,'Normalization','probability','DisplayStyle','stairs');
        xline(nanmean(cond_acc(1,:) - cond_acc(2,:)),'LineWidth',1);
        xlabel('cross validated classification accuracy');
        ylabel('probability')
        title(sprintf('%s: p=%.3f','SVM accuracy',acc_p))
    end

    if params.signConsistency
        %create null distribution
        consistency_null_distribution = [];

        for i_p = 1:params.N_null
            sample_cond1 = [];
			sample_cond2 = [];
			for i_s = exp_ss'
                sample_cond1(end+1)=cond_shuffled_consistency(1, i_s,randperm(params.N_perm,1));
                sample_cond2(end+1)=cond_shuffled_consistency(2, i_s,randperm(params.N_perm,1));
            end
            consistency_null_distribution(end+1)=mean(sample_cond1) - mean(sample_cond2);
        end

        consistency_p = mean(consistency_null_distribution>= ...
            nanmean(cond_consistency(1,:) - cond_consistency(2,:)));
        subplot(2,2,2)
        hold on;
        histogram(consistency_null_distribution,'Normalization','probability','DisplayStyle','stairs');
        xline(nanmean(cond_consistency(1,:) - cond_consistency(2,:)),'LineWidth',1);
        xlabel('mean sign consistency');
        ylabel('probability')
        title(sprintf('%s: p=%.3f','Sign consistency',consistency_p)) 
    end

    if params.directional
        		%create null distribution
        diff_null_distribution = [];

        for i_p = 1:params.N_null
            sample_cond1 = [];
			sample_cond2 = [];
		    for i_s = exp_ss'
                sample_cond1(end+1)= cond_shuffled_diff(1, i_s,randperm(params.N_perm,1));
                sample_cond2(end+1)= cond_shuffled_diff(2, i_s,randperm(params.N_perm,1));
            end
            diff_null_distribution(end+1)=mean(sample_cond1) - mean(sample_cond2);
        end

        diff_p = mean(diff_null_distribution>=nanmean(cond_diff(1,:) - cond_diff(2,:)));
        subplot(2,2,3)
        hold on;
        histogram(diff_null_distribution,'Normalization','probability','DisplayStyle','stairs');
        xline(nanmean(cond_diff(1,:) - cond_diff(2,:)),'LineWidth',1);
        xlabel('mean difference');
        ylabel('probability')
        title(sprintf('%s: p=%.3f','Directional test',diff_p))
    end

%     s=hgexport('readstyle','presentation');
    s=hgexport('factorystyle');
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
        save(fullfile(dir_name,'SVM_results'),'cond_acc','cond_shuffled_acc','SVM_null_distribution','acc_p');
    end

    if params.signConsistency
         save(fullfile(dir_name,'consistency_results'),'cond_consistency','cond_shuffled_consistency','consistency_null_distribution','consistency_p');
    end

    if params.directional
         save(fullfile(dir_name,'directional_results'),'cond_diff','cond_shuffled_diff','diff_null_distribution','diff_p');
    end

    hgexport(fig,fullfile(dir_name,'summary_figure.png'),s);
end

