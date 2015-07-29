%
% generate accept/reject files
%

%function amt_al_accept_all_gen(basedir, annolist, amt_results)
function amt_al_accept_all_gen(annolist, amt_results)

  [amt_path, amt_name, amt_ext] = splitpathext(amt_results);  
  
  %input_mat = [basedir '/' amt_name '_eval.mat'];
  %load(input_mat, 'annolist');

  % acceptfile: 
  % First row must contain column header named "assignmentIdToApprove"
  % Optional column header following named "assignmentIdToApproveComment"
  % Fields should be separated with a tab and comments should be enclosed in quotes ("")

  % rejectfile: 
  % First row must contain column header named "assignmentIdToReject"
  % Optional column header following named "assignmentIdToRejectComment"
  % Fields should be separated with a tab and comments should be enclosed in ""


  fname_accept = [amt_path '/' amt_name '.accept'];
  fname_reject = [amt_path '/' amt_name '.reject'];

  fid_accept = fopen(fname_accept, 'w');
  fid_reject = fopen(fname_reject, 'w');

  fprintf(fid_accept, 'assignmentIdToApprove\tassignmentIdToApproveComment\n');
  fprintf(fid_reject, 'assignmentIdToReject\tassignmentIdToRejectComment\n');

  %num_keypoints = amt_get_num_keypoints();
  num_keypoints = 0;

  accepted_assignments = containers.Map();
  rejected_assignments = containers.Map();

  total_accept = 0;
  total_reject = 0;

  total_rects = 0;

  num_could_not_eval = 0;

  % save accept / reject / empty separately
  annolist_accept = struct('image', {}, 'annorect', {});
  annolist_reject = struct('image', {}, 'annorect', {});
  annolist_noeval = struct('image', {}, 'annorect', {});

  for aidx = 1:length(annolist)

    % if length(annolist(aidx).annorect) == 0
    %   continue;
    % end

    do_print_imgname = true;
    total_rects = total_rects + length(annolist(aidx).annorect);

    % test that all annorects have same 'assignmentid'
    % for ridx = 2:length(annolist(aidx).annorect)
    %   assert(strcmp(annolist(aidx).annorect(1).assignmentid, annolist(aidx).annorect(ridx).assignmentid) == 1);
    % end

    ridx = 1;

    %for ridx = 1:length(annolist(aidx).annorect)
    %assert(~isempty(strtrim(annolist(aidx).annorect(ridx).assignmentid)));
    assert(~isempty(strtrim(annolist(aidx).assignmentid)));

      % if true %isfield(annolist(aidx).annorect(ridx), 'num_ok') && isfield(annolist(aidx).annorect(ridx), 'num_ok_visible')

      % 	if true % amt_annorect_check_accept(annolist(aidx).annorect(ridx))
      %fprintf(fid_accept, '%s\t"thank you for your work"\n', annolist(aidx).annorect(ridx).assignmentid);
      fprintf(fid_accept, '%s\t"thank you for your work"\n', annolist(aidx).assignmentid);

	  accepted_assignments(annolist(aidx).assignmentid) = 1;
	  total_accept = total_accept + 1;

	  next_aidx = length(annolist_accept) + 1;
	  annolist_accept(next_aidx).image.name = annolist(aidx).image.name;

	  if length(annolist(aidx).annorect) > 0
	    annolist_accept(next_aidx).annorect = annolist(aidx).annorect(ridx);
	  end
	  
	% end

	
      % 	else
      % 	  extended_reject_comment = ['number or correct keypoints: ' num2str(annolist(aidx).annorect(ridx).num_ok_visible) '/' ...
      % 		    num2str(annolist(aidx).annorect(ridx).num_gt_visible) ', ' ...
      % 		    num2str(annolist(aidx).annorect(ridx).num_ok) '/' num2str(annolist(aidx).annorect(ridx).num_gt_inside) ', not enough correct keypoints'];

      % 	  if do_print_imgname 
      % 	    fprintf('%d, %s\n', aidx, annolist(aidx).image.name);
      % 	    do_print_imgname = false;
      % 	  end

      % 	  reject_comment = ['number or correct keypoints: ' num2str(annolist(aidx).annorect(ridx).num_ok) ', not enough correct keypoints, sorry'];

      % 	  fprintf('%s\n', reject_comment);
      % 		   %fprintf('%s\n', extended_reject_comment);

      % 		   fprintf(fid_reject, '%s\t"%s"\n', annolist(aidx).annorect(ridx).assignmentid, reject_comment);

      % 		   rejected_assignments(annolist(aidx).annorect(ridx).assignmentid) = 1;
      % 		   total_reject = total_reject + 1;

      % 		   next_aidx = length(annolist_reject) + 1;
      % 		   annolist_reject(next_aidx).image.name = annolist(aidx).image.name;
      % 		   annolist_reject(next_aidx).annorect = annolist(aidx).annorect(ridx);
      % 		   annolist_reject(next_aidx).annorect.rc = reject_comment;

      % 	end

      % else
      % 	num_could_not_eval = num_could_not_eval + 1;

      % 	next_aidx = length(annolist_noeval) + 1;
      % 	annolist_noeval(next_aidx).image.name = annolist(aidx).image.name;
      % 	annolist_noeval(next_aidx).annorect = annolist(aidx).annorect(ridx);
      % end

    %end % worker outputs
  end % images

  fclose(fid_accept);
  fclose(fid_reject);
  fprintf('saved accept list: %s\n', fname_accept);
  fprintf('saved reject list: %s\n', fname_reject);

  % save annolists
  %[fpath, fname, fext] = splitpathext(amt_results);
  %saveannotations(annolist_accept, [fpath '/anolist_accept.al']);
  %saveannotations(annolist_reject, [fpath '/annolist_reject.al']);
  %saveannotations(annolist_noeval, [fpath '/annolist_noeval.al']);

  % generate accept/reject list for empty assignments 
  A = csv2cell(amt_results, 'fromfile');

  column_by_name = containers.Map();
  ASSIGNMENTID_STR = 'assignmentid';

  for idx = 1:size(A, 2)
    colname = strtrim(A{1, idx});
    column_by_name(colname) = idx;
  end

  assert(column_by_name.isKey(ASSIGNMENTID_STR));

  column_idx = column_by_name(ASSIGNMENTID_STR);

  fprintf('\n');

  empty_assignments = cell(0);
  num_empty_id = 0;

  all_keys = containers.Map();

  for idx = 2:size(A, 1)
    ass_id = strtrim(A{idx, column_idx});

    %if strcmp(annolist(aidx).assignmentid, '3JMSRU9HQJ18XE60C76SVXMWL7FEVI')
    if strcmp(ass_id, '3JMSRU9HQJ18XE60C76SVXMWL7FEVI')
      keyboard
    end

    if ~isempty(ass_id) 
      if ~(accepted_assignments.isKey(ass_id) || rejected_assignments.isKey(ass_id))
	empty_assignments{end+1} = ass_id;
	fprintf('assignments without accept or reject: %s\n', ass_id);
      end

      if all_keys.isKey(ass_id)
	assert(false);
	all_keys(ass_id) = all_keys(ass_id) + 1;
      else
	all_keys(ass_id) = 1;
      end
    else
      num_empty_id = num_empty_id + 1;
    end

  end

  fprintf('num unique keys: %d\n', length(all_keys.keys()))

  fprintf('empty: \n');

  fprintf('\n\nnum_could_not_eval: %d, total_accept: %d, total_reject: %d, total_rects: %d\n', num_could_not_eval, total_accept, total_reject, total_rects);
  fprintf('total rows in results file: %d\n', size(A, 1) - 1);
  fprintf('neither accept nor reject: %d\n', length(empty_assignments));
  fprintf('empty id: %d\n', num_empty_id);

  fname_empty = [amt_path '/' amt_name '.empty'];
  fid_empty = fopen(fname_empty, 'w');
  fprintf(fid_empty, 'assignmentIdToReject\tassignmentIdToRejectComment\n');

  for idx = 1:length(empty_assignments)
    fprintf(fid_empty, '%s\t" "\n', empty_assignments{idx});
  end

  fprintf('saved empty list: %s\n', fname_empty);
  fclose(fid_empty);

