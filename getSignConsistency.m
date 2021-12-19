function [signConsistency] = getSignConsistency(RT,label,Nsplits,statistic)

if length(RT) ~= length(label)
    error('inconsistent lengths for vectors RT and label')
end
Ntrials = length(RT);
midpoint = round(Ntrials/2);
consistency=nan(Nsplits,1);

for i_s = 1:Nsplits
    order_permuatation = randperm(Ntrials);
    group = [order_permuatation>midpoint]';
    
    group0_sign = sign(statistic(RT(group==0 & label==1))-statistic(RT(group==0 & label==0)));
    group1_sign = sign(statistic(RT(group==1 & label==1))-statistic(RT(group==1 & label==0)));
    consistency(i_s)=group0_sign==group1_sign;

end
signConsistency=mean(consistency);
end

