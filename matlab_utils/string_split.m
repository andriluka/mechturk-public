%
% split string into tokens separated by delimiter
%
% MA: here we assume that delimiter is a simple character like ',', one can also provide 
% multiple characters, e.g. ',.;', but the code does not support a sequence of delimiters following 
% each other, brr..... why not?
% 
function tokens = string_split(str, delimiter)
  assert(~isempty(str));

  %didx = find(str == delimiter);
  didx = regexp(str, ['[' delimiter ']+']);

  if isempty(didx)
    tokens{1} = str;

  else
    tokens{1} = str(1:didx(1) - 1);

    num_delim = length(didx);

    for idx = 1:num_delim - 1
      tokens{end+1} = str(didx(idx)+1:didx(idx+1)-1);
    end

    tokens{end+1} = str(didx(num_delim) + 1:end);
  end
