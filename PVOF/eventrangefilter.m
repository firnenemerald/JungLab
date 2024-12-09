function result=eventrangefilter(mobile_doric,rangesize)

useind = [];
for i = 1 : size(mobile_doric,1)
    if i ==1
        if mobile_doric(i,1) > rangesize && mobile_doric(i,2)-mobile_doric(i,1) >=40
            useind = [useind;i];
        end
    else
        if mobile_doric(i,1) > mobile_doric(i-1,2) + rangesize && mobile_doric(i,2)-mobile_doric(i,1) >=40
            useind = [useind;i];
        end
    end
end

result = mobile_doric(useind,:);
