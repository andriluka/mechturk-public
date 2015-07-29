function worker_annolist = split_by_workerid(annolist, outdir)
  %annolist = loadannotations(annolist_filename);

  % ...
  worker_annolist = cell(0);
  worker_idx = containers.Map();

  for aidx = 1:length(annolist)
    for ridx = 1:length(annolist(aidx).annorect)

      % MA: in some cases workers label multiple rectangles per image, workerid is then assigned to the image
      if (~isfield(annolist(aidx).annorect(ridx), 'workerid') || isempty(annolist(aidx).annorect(ridx).workerid)) && isfield(annolist(aidx), 'workerid')
	annolist(aidx).annorect(ridx).workerid = annolist(aidx).workerid;
      end

      if (~isfield(annolist(aidx).annorect(ridx), 'hitid') || isempty(annolist(aidx).annorect(ridx).hitid)) && isfield(annolist(aidx), 'hitid')
	annolist(aidx).annorect(ridx).hitid = annolist(aidx).hitid;
      end

      assert(isfield(annolist(aidx).annorect(ridx), 'workerid') && length(annolist(aidx).annorect(ridx).workerid) > 0);

      if worker_idx.isKey(annolist(aidx).annorect(ridx).workerid)
	cur_worker_idx = worker_idx(annolist(aidx).annorect(ridx).workerid);
	assert(length(worker_annolist) >= cur_worker_idx);
      else
	cur_worker_idx = length(worker_annolist) + 1;
	worker_idx(annolist(aidx).annorect(ridx).workerid) = cur_worker_idx;

	if isfield(annolist(1), 'imgnum')
	  assert(false);
	  worker_annolist{cur_worker_idx} = struct('image', {}, 'annorect', {}, 'hitid', {}, 'imgnum', {});
	else
	  worker_annolist{cur_worker_idx} = struct('image', {}, 'annorect', {}, 'hitid', {});
	end
      end

      n = length(worker_annolist{cur_worker_idx});

      if n == 0 || strcmp(worker_annolist{cur_worker_idx}(n).image.name, annolist(aidx).image.name) ~= 1
	%a = annolist(aidx);
	a.image.name = annolist(aidx).image.name;
	a.annorect = annolist(aidx).annorect(ridx);
	a.hitid = annolist(aidx).hitid;

	worker_annolist{cur_worker_idx}(n+1) = a;
      else
	worker_annolist{cur_worker_idx}(n).annorect(end+1) = annolist(aidx).annorect(ridx);
      end

      %a = annolist(aidx);
      %a.annorect = annolist(aidx).annorect(ridx);
      %worker_annolist{cur_worker_idx}(end+1) = a;

    end
  end

  all_ids = worker_idx.keys();

  if exist('outdir', 'var') > 0
    if exist(outdir, 'dir') == 0
      fprintf('creating %s\n', outdir);
      mkdir(outdir);
      assert(exist(outdir, 'dir') > 0);
    end

    % use last directory in 'outdir' as a basis for a filename
    %[path, name, ext] = splitpathext(outdir);

    for idx = 1:length(all_ids)
      cur_worker_idx = worker_idx(all_ids{idx});

      numimgs = length(worker_annolist{cur_worker_idx});

      %cur_fname = [outdir '/' name '_' all_ids{idx} '_' padZeros(num2str(numimgs), 4) '.al'];
      %cur_fname = [outdir '/' name '_' padZeros(num2str(numimgs), 4) '_' all_ids{idx} '.al'];
      cur_fname = [outdir '/' padZeros(num2str(numimgs), 4) '_' all_ids{idx} '.al'];
      fprintf('saving %s\n', cur_fname);

      saveannotations(worker_annolist{cur_worker_idx}, cur_fname);
    end
  end
