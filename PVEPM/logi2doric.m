function result=logi2doric(mobile,time)

for i = 1 : size(mobile,1)
    [~,temp1]=min(abs(time-mobile(i,1)*(1/29.99)));
    [~,temp2]=min(abs(time-mobile(i,2)*(1/29.99)));
    result(i,:) = [temp1,temp2];
    clear temp1 temp2
end
end