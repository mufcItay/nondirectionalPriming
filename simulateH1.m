close all;
clc;
clear;
warning('off')

N_sub = 50;
N_trial = 200;
population_sd = 0.5;

subNum = [];
cong = {}
rt = [];
Exp = {};

for i_s = 1:N_sub
    
    subj_effect = normrnd(0,population_sd);
    cong_s = binornd(1,0.5,N_trial,1);
    rt_s = normrnd(0,1,N_trial,1)+cong_s*subj_effect;
    
    subNum = [subNum; i_s*ones(N_trial,1)];
    for i_t=1:N_trial
       if cong_s(i_t)==1
           cong{end+1}='cong';
       else
           cong{end+1}='incong';
       end
       Exp{end+1}='sim';
    end
    
    rt = [rt; rt_s];
end

cong = cong';
Exp = Exp';
T = table(subNum,cong,rt,Exp);
writetable(T,fullfile('data','Simulated_Data_Full.csv'),'Delimiter',',');