%
% min_box_width: smallest allowed annotation box (in pixels), smaller boxes are not credited with bonus payment, if value is negative then all boxes
%                regardless of the size result in a bonus
%
function al_to_bonus(annolist_all_workers, hit_dir, object_bonus_usd, min_box_width, is_sandbox)

  assert(object_bonus_usd > 0);

  [fpath, fname, fext] = splitpathext(hit_dir);

  output_filename_amt = [hit_dir '/' fname '-grant-bonus.sh'];
  output_filename_log = [hit_dir '/' fname '-grant-bonus.log'];

  fprintf('\nsaving bonus details to %s\n', output_filename_amt);

  fid = fopen(output_filename_amt, 'w');

  total_bonus = 0;
  total_cars_labeled = 0;

  % check if there are pre-loaded annotations 
  preload_params_filename = [hit_dir '/preload_params.sh'];
  if exist(preload_params_filename, 'file') > 0 

    % MA: this won't work if we have multiple parameters in the pre-load file 
    % preload_str = fileread(preload_params_filename);
    % sidx = find(preload_str == '=');
    % assert(length(sidx) == 1);
    % assert(strcmp(preload_str(1:sidx-1), 'PRELOAD_ANNOLIST') == 1);
    % preload_annolist_filename = strtrim(preload_str(sidx+1:end));

    [return_code, output_str] = system(['source ' preload_params_filename '; echo $PRELOAD_ANNOLIST']);
    assert(return_code == 0);
    preload_annolist_filename = strtrim(output_str);

    fprintf('preload_annolist_filename: %s\n', preload_annolist_filename);

    preload_annolist = loadannotations(preload_annolist_filename);

    preload_map = containers.Map();
    for aidx = 1:length(preload_annolist)
      keystr = get_filename_key(preload_annolist(aidx).image.name);
      assert(~preload_map.isKey(keystr));
      preload_map(keystr) = aidx;
    end    
  else
    preload_annolist = [];
    fprintf('no preloaded annotations found\n');
  end

  % load log to check which assignments were already paid
  if exist(output_filename_log, 'file')
    paylog_cell = csv2cell(output_filename_log, 'fromfile');
  else
    paylog_cell = {};
  end

  paylog_map = containers.Map();
  for idx = 1:size(paylog_cell, 1)
    paylog_map([paylog_cell{idx, 1} '_' paylog_cell{idx, 2}]) = 1;
  end

  num_bonus_new = 0;
  num_bonus_fixed = 0;
  num_bonus_deleted = 0;

  for aidx = 1:length(annolist_all_workers)
    if isfield(annolist_all_workers(aidx), 'annorect') && ~isempty(annolist_all_workers(aidx).annorect)

      paylog_key = [annolist_all_workers(aidx).workerid '_' annolist_all_workers(aidx).assignmentid];

      if ~paylog_map.isKey(paylog_key)	
	cur_num_cars = 0;

	if (length(preload_annolist) == 0) 
	  % compute bonus based on the number of labeled vehicles
	  if min_box_width > 0
	    for ridx = 1:length(annolist_all_workers(aidx).annorect)
	      if abs(annolist_all_workers(aidx).annorect(ridx).x2 - annolist_all_workers(aidx).annorect(ridx).x1) >= min_box_width
		cur_num_cars = cur_num_cars + 1;
	      end
	    end
	  else
	    cur_num_cars = length(annolist_all_workers(aidx).annorect);
	  end
	  
	  num_bonus_new = num_bonus_new + cur_num_cars; 
	else
	  % TODO: compute bonus taking preloaded annotations into account, also see objectui.js/count_bonus_objects
	  keystr = get_filename_key(annolist_all_workers(aidx).image.name);

	  assert(preload_map.isKey(keystr));
	  preload_aidx = preload_map(keystr);
	  
	  % bonus for new cars
	  [new_bonus_object_count, this_num_bonus_new, this_num_bonus_fixed, this_num_bonus_deleted] = count_bonus_objects(annolist_all_workers(aidx).annorect, preload_annolist(preload_aidx).annorect, min_box_width);
	  %fprintf('new_bonus_object_count: %d\n', new_bonus_object_count);
	  cur_num_cars = cur_num_cars + new_bonus_object_count;

	  num_bonus_new = num_bonus_new + this_num_bonus_new;
	  num_bonus_fixed = num_bonus_fixed + this_num_bonus_fixed;
	  num_bonus_deleted = num_bonus_deleted + this_num_bonus_deleted;
	end

	total_cars_labeled = total_cars_labeled + cur_num_cars;

	bonus_cmd = '"$MTURK_CMD_HOME"/bin/grantBonus.sh';

	if is_sandbox
	  bonus_cmd = [bonus_cmd ' --sandbox'];
	end

	bonus_cmd = [bonus_cmd ' --workerid ' annolist_all_workers(aidx).workerid];

	str_amount = sprintf('%.3f', object_bonus_usd * cur_num_cars);
	total_bonus = total_bonus + str2num(str_amount);

	bonus_cmd = [bonus_cmd ' --amount ' str_amount];
	bonus_cmd = [bonus_cmd ' --assignment ' annolist_all_workers(aidx).assignmentid];
	bonus_cmd = [bonus_cmd ' --reason "labeled vehicles: ' num2str(cur_num_cars) ', bonus per vehicle: ' num2str(object_bonus_usd) '"'];

	fprintf(fid, '%s\n', bonus_cmd);
	fprintf(fid, '%s\n', ['echo "' annolist_all_workers(aidx).workerid ',' annolist_all_workers(aidx).assignmentid '" >> ' output_filename_log]);
      else
	fprintf('paylog: worker "%s" already paid for assignment "%s", skip payment this time\n', annolist_all_workers(aidx).workerid, annolist_all_workers(aidx).assignmentid);
      end

    end
  end

  fprintf('object_bonus_usd: %.2f\n', object_bonus_usd);
  fprintf('total_cars_labeled: %d\n', total_cars_labeled);
  fprintf('num_bonus_new: %d, num_bonus_fixed: %d, num_bonus_deleted: %d\n', num_bonus_new, num_bonus_fixed, num_bonus_deleted);
  fprintf('total_bonus: %.2f USD\n\n', total_bonus);

  assert(fid >= 0);
  fclose(fid);

function [new_bonus_object_count, num_bonus_new, num_bonus_fixed, num_bonus_deleted] = count_bonus_objects(new_annorect, preloaded_annorect, min_box_width)
  % fprintf('new_annorect: %d\n', length(new_annorect));
  % fprintf('preloaded_annorect: %d\n', length(preloaded_annorect));
  num_bonus_new = 0;
  num_bonus_fixed = 0;
  num_bonus_deleted = 0;
    
  new_bonus_object_count = 0;
  preloaded_matched = zeros(length(preloaded_annorect), 1);

  % MA: these threshold should be the same as in objectui.js

  % threshold to define when the new annotation is too similar -> no bonus 
  iou_too_similar_threshold = 0.75;

  % to define when new and old annotations match 
  iou_matched_threshold = 0.5;

  for aidx = 1:length(new_annorect)
    cur_width = abs(new_annorect(aidx).x2 - new_annorect(aidx).x1);

    max_iou = 0;
    max_preidx = -1;

    for preidx = 1:length(preloaded_annorect)
      if preloaded_matched(preidx) == 1
	continue;
      end

      cur_iou = rect_iou(new_annorect(aidx), preloaded_annorect(preidx));

      if cur_iou > max_iou
	max_iou = cur_iou;
	max_preidx = preidx;
      end
    end

    %fprintf('\tmax_iou: %f\n', max_iou);

    if (max_iou > iou_matched_threshold)
      preloaded_matched(max_preidx) = 1;
      
      % matched, but sifficiently different -> pay bonus
      if (max_iou < iou_too_similar_threshold && cur_width > min_box_width)
	new_bonus_object_count = new_bonus_object_count + 1;
	num_bonus_fixed = num_bonus_fixed + 1;
      end
    else
      % didn't match to preloaded -> pay bonus
      if cur_width > min_box_width
	new_bonus_object_count = new_bonus_object_count + 1;
	num_bonus_new = num_bonus_new + 1;
      end
    end

  end

  % pay bonus for deleted false positives -> preloaded annotation that didn't match any new one 
  num_bonus_deleted = sum(preloaded_matched == 0);
  new_bonus_object_count = new_bonus_object_count + num_bonus_deleted;

function is_same_rect(new_rect, ref_rect)
  
  max_pos_change = 0;
  cur_width = abs(new_rect.x2 - new_rect.x1);

  v1 = [r1.x1, r1.y1, r1.x2, r1.y2];
  v2 = [r2.x1, r2.y1, r2.x2, r2.y2];

  for idx = 1:length(v1)
    cur_pos_change = abs(v1(idx) - v2(idx));

    if cur_pos_change > max_pos_change
      max_pos_change = cur_pos_change;
    end
  end

  rel_pos_change = max_pos_change / cur_width;

  % should be the same as in objectui.js / count_bonus_objects
  res = (rel_pos_change > 0.1);

function keystr = get_filename_key(filename)
  [fpath1, keystr] = splitpath(filename);

function res = rect_int(r1, r2)
    if r1.x1 >= r2.x2
      res = 0;
      return
    end
    
    if r1.x2 <= r2.x1
      res = 0;
      return;
    end

    if r1.y1 >= r2.y2
      res = 0;
      return;
    end
    
    if r1.y2 <= r2.y1   
      res = 0;  
      return;
    end
    
    l = max(r1.x1, r2.x1);
    t = max(r1.y1, r2.y1);
    r = min(r1.x2, r2.x2);
    b = min(r1.y2, r2.y2);

    res = (r - l)*(b - t);

function res = rect_iou(r1, r2) 
    assert(r1.x1 <= r1.x1, 'broken rectangle struct');
    assert(r1.y1 <= r1.y2, 'broken rectangle struct');
    
    assert(r2.x1 <= r2.x2, 'broken rectangle struct');
    assert(r2.y2 <= r2.y2, 'broken rectangle struct');

    a1 = (r1.x2 - r1.x1)*(r1.y2 - r1.y1);
    a2 = (r2.x2 - r2.x1)*(r2.y2 - r2.y1);
    
    ia = rect_int(r1, r2);
    res = ia / (a1 + a2 - ia);  
    

