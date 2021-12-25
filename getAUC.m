function [AUC] = getAUC(conf,accuracy)
if length(unique(accuracy))>1
    [~,~,~,AUC]=perfcurve(accuracy,conf,1);
else
    AUC=0.5;
end
end

