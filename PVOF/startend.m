function startendind=startend(over08)
endind=over08(find(diff(over08)>1));
startind = over08(find(diff(over08)>1)+1);
startind = startind(1:end-1);
startind = [over08(1,1);startind];
startendind = [startind,endind];
end