function [] = analyzeConfidence(params,filename)

rng(params.rng)

% load full dataset
data = readtable(fullfile('data',[filename,'.csv']));
data.Subj_idx = double(categorical(data.Subj_idx)); %make it a number


if length(params.control_for)>1
% create a column for the residual variance in x after controlling for
% the control_for field
    residuals = [];

    exp_ss = unique(data.Subj_idx);

    for i_s = exp_ss'

        subj_data = data(data.Subj_idx==i_s,:);
        x = subj_data.(params.x);
        control_for_str = subj_data.(params.control_for);
        control_for_bin = double(strcmp(control_for_str,control_for_str{1}));
        p=polyfit(control_for_bin,x,1);
        residuals=[residuals;x-polyval(p,control_for_bin)];
    end
    data.x = residuals;
else
    data.x = data.(params.x);
end

% MAIN LOOP
    
    
exp_ss = unique(data.Subj_idx);


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

    subj_data = data(data.Subj_idx==i_s,:);

    x = subj_data.x;

    y = subj_data.(params.predict);
    
    accuracy = subj_data.(params.accuracy);

    if params.signConsistency
        %true sign consistency for subject
        exp_consistency(i_s)=getSignConsistencyMetacognition(x,y,accuracy,params.N_splits,params.statistic);
    end

    if params.directional
        %true difference in depndent measure per participant
        exp_diff(i_s) = params.statistic(x(y==1),accuracy(y==1))-params.statistic(x(y==0),accuracy(y==0));
    end

    % shuffled accuracy for subject
    for i_p = 1:params.N_perm
        shuffled_x = x(randperm(length(x)));


        if params.signConsistency
            exp_shuffled_consistency(i_s,i_p)=getSignConsistencyMetacognition(shuffled_x,y,accuracy,params.N_splits,params.statistic);
        end

        if params.directional
            exp_shuffled_diff(i_s,i_p)=params.statistic(shuffled_x(y==1),accuracy(y==1))-params.statistic(shuffled_x(y==0),accuracy(y==0));
        end
    end

end

fig=figure;

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
    subplot(1,2,1)
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
    subplot(1,2,2)
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
s.Height = 5;

% save
dir_name = fullfile('.','analyzed',filename,'metacognition',params.x);

if ~isdir(dir_name)
    mkdir(dir_name)
end

save(fullfile(dir_name,'params'),'params');

if params.signConsistency
     save(fullfile(dir_name,'consistency_results'),'exp_consistency','exp_shuffled_consistency','consistency_null_distribution','consistency_p');
end

if params.directional
     save(fullfile(dir_name,'directional_results'),'exp_diff','exp_shuffled_diff','diff_null_distribution','diff_p');
end

hgexport(fig,fullfile(dir_name,'summary_figure.png'),s);
% 


end

