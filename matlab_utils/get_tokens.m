function tokens2 = get_tokens(str, delimiter)

  tokens = string_split(str, delimiter);

  tokens2 = cell(0);

  for idx = 1:length(tokens)
    if ~isempty(tokens{idx})
      
      % MA: could have used 'strtrim'

      firstidx = -1;
      for idx2 = 1:length(tokens{idx})
	if tokens{idx}(idx2) ~= ' '
	  firstidx = idx2;
	  break;
	end
      end

      lastidx = -1;
      for idx2 = length(tokens{idx}):-1:1
	if tokens{idx}(idx2) ~= ' '
	  lastidx = idx2;
	  break;
	end
      end

      if firstidx > 0 && lastidx > 0 
	assert(firstidx <= lastidx);
	tokens2{end+1} = tokens{idx}(firstidx:lastidx);
      end

    end
  end



