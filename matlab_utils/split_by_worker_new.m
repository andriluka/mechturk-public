function worker_annolist = split_by_worker_new(annolist, outdir)

  worker_annolist = cell(0);
  worker_idx = containers.Map();

  for aidx = 1:length(annolist)
      assert(isfield(annolist(aidx), 'workerid') && length(annolist(aidx).workerid) > 0);

      if worker_idx.isKey(annolist(aidx).workerid)
          cur_worker_idx = worker_idx(annolist(aidx).workerid);
          assert(length(worker_annolist) >= cur_worker_idx);
      else
          cur_worker_idx = length(worker_annolist) + 1;
          worker_idx(annolist(aidx).workerid) = cur_worker_idx;

	  worker_annolist{cur_worker_idx} = struct('image', {}, 'annorect', {}, 'hitid', {});
      end

      a.image = annolist(aidx).image;
      a.annorect = annolist(aidx).annorect;
      a.hitid = annolist(aidx).hitid;

      worker_annolist{cur_worker_idx}(end+1) = a;
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
