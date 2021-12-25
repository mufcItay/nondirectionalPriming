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
    exp_directional_effect = nan(max(exp_ss),1);

    for i_s = exp_ss'
        
        subj_data = exp_data(exp_data.subNum==i_s,:);
        rt = subj_data.rt;
        cong = strcmp(subj_data.cong,'cong');
        exp_directional_effect(i_s) = mean(rt(cong==0))-mean(rt(cong==1));
    end
    
    save(['RTdiff_',exp_names{i_e},'.mat'],'exp_directional_effect');
    [h,p,ci,stats]=ttest(exp_directional_effect);

    
    fig=figure;
    hold on;
    yline(0);
    scatter(1:length(exp_directional_effect),exp_directional_effect);
    ylabel('mean RT diff')
    xlabel('subject');
    s=hgexport('readstyle','presentation');
    s.Format = 'png';
    s.Width = 8;
    s.Height = 4;
    hgexport(fig,fullfile('figures',['directional_',exp_names{i_e}]),s);
end

