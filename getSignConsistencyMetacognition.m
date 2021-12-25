function [signConsistency] = getSignConsistencyMetacognition(confidence,label,accuracy,Nsplits,statistic)

if length(confidence) ~= length(label)
    error('inconsistent lengths for vectors RT and label')
end
Ntrials = length(confidence);
midpoint = round(Ntrials/2);
consistency=nan(Nsplits,1);

for i_s = 1:Nsplits
    order_permuatation = randperm(Ntrials);
    group = [order_permuatation>midpoint]';
    
    group0_sign = sign(statistic(confidence(group==0 & label==1), ...
        accuracy(group==0 & label==1)) - ...
        statistic(confidence(group==0 & label==0), ...
        accuracy(group==0 & label==0)));
    
    group1_sign = sign(statistic(confidence(group==1 & label==1), ...
        accuracy(group==1 & label==1)) - ...
        statistic(confidence(group==1 & label==0), ...
        accuracy(group==1 & label==0)));
    
    consistency(i_s)=group0_sign==group1_sign;

end
signConsistency=mean(consistency);
end

