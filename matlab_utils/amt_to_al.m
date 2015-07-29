%
% convert AMT results to .al structure, make several hardcoded assumptions about current annotation tool
%
function annolist = amt_to_al(basedir, amt_results)

HITID_STR = 'hitid';
WORKERID_STR = 'workerid';
ASSIGNMENTID_STR = 'assignmentid';

% new, should be string from 'input' submitted to AMT
ANNOTATION_STR = 'annotation';
RES_STR = 'Answer.results';
COMMENT_STR = 'Answer.commentsbox';

A = csv2cell(amt_results, 'fromfile');

column_by_name = containers.Map();
annotation_by_name = containers.Map();

for idx = 1:size(A, 2)
    if ~isempty(A{1, idx})
        colname = strtrim(A{1, idx});
        fprintf('%d: %s\n', idx, colname);
        column_by_name(colname) = idx;
    else
        fprintf('warning: empty column %d\n', idx);
    end
end

assert(column_by_name.isKey(HITID_STR));
assert(column_by_name.isKey(WORKERID_STR));
assert(column_by_name.isKey(ASSIGNMENTID_STR));
assert(column_by_name.isKey(RES_STR));
assert(column_by_name.isKey(ANNOTATION_STR));

% only available in pose_estimation task, add it for viewpoint as well?
%assert(column_by_name.isKey(COMMENT_STR));

annolist = struct('image', {});
annolist_empty = struct('image', {});

num_anno = 0;
num_both_inside = 0;

% need this to know when points are considered outside of the image
[target_height, target_width, target_total_width] = get_subframe_dim();

num_empty_data = 0;
num_other_filetype = 0;
hits_empty = {};

for aidx = 2:size(A, 1)
    res_str = A{aidx, column_by_name(RES_STR)};

    if ~isempty(res_str)
        res_str = strtrim(res_str);
    end

    fprintf('res_str: %s\n', res_str);

    if ~isempty(res_str)
        tokens = get_tokens(res_str, ',');

        % different AMT tasks: pose annotation, torso/head viewpoint annoation

        % AMT pose annotation
        if length(tokens) > 2 && ~isempty(strfind(tokens{1}, 'imagedir')) && ~isempty(strfind(tokens{2}, 'person'))

            %assert(~isempty(strfind(tokens{1}, 'imagedir')));
            %assert(~isempty(strfind(tokens{2}, 'person')));

            if ~isempty(strfind(tokens{3}, '.jpg'))

                fname = tokens{3};


                % find annotation corresponding to this image (in case there annotations of the same person by several AMT workers)
                if annotation_by_name.isKey(fname)
                    hit_aidx = annotation_by_name(fname);
                else
                    num_anno = num_anno + 1;
                    hit_aidx = num_anno;

                    annolist(hit_aidx).image.name = [basedir '/' fname];

                    annolist(hit_aidx).annorect = struct('x1', {}, 'y1', {}, 'x2', {}, 'y2', {}, 'annopoints', {}, 'is_error', {}, ...
                        'workerid', {}, 'comment', {}, 'time', {}, 'hitid', {}, 'assignmentid', {});
                    annotation_by_name(fname) = hit_aidx;
                end

                % index of this annotation
                hit_ridx = length(annolist(hit_aidx).annorect) + 1;

                % also set other fields: workerId, comment, time, hitid
                annolist(hit_aidx).annorect(hit_ridx).hitid = strtrim(A{aidx, column_by_name(HITID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).assignmentid = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).workerid = strtrim(A{aidx, column_by_name(WORKERID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).comment = strtrim(A{aidx, column_by_name(COMMENT_STR)});

                % figure out the time it took to process this hit
                % ...
                annolist(hit_aidx).annorect(hit_ridx).time = 1;
                annolist(hit_aidx).annorect(hit_ridx).is_error = 0;

                assert(mod(length(tokens) - 3, 2) == 0);
                num_pts = (length(tokens) - 3) / 2;

                if num_pts > 0
                    assert(num_pts == 30);

                    P = zeros(num_pts, 2);

                    % get points
                    for pidx = 1:num_pts
                        idx = 3 + 2*pidx - 1;
                        P(pidx, 1) = str2num(tokens{idx});
                        P(pidx, 2) = str2num(tokens{idx+1});
                    end

                    % index of next annopoint
                    nextpidx = 0;

                    % fill annorect struct
                    for idx = 1:(num_pts / 2)
                        % choose which point is valid: visible or occluded
                        idx1 = idx;
                        idx2 = idx1 + (num_pts / 2);

                        if P(idx2, 1) < target_width && P(idx1, 1) < target_width
                            num_both_inside = num_both_inside + 1;

                            %
                            % both points inside, set error state
                            % note: we should rather do the analysis later, also change interface to forbid having both points inside the image at once
                            %
                            annolist(hit_aidx).annorect(hit_ridx).is_error = 1;
                        end

                        valid_idx = -1;

                        % default is occluded
                        if P(idx2, 1) < target_width
                            valid_idx = idx2;
                            is_visible = 0;
                        elseif P(idx1, 1) < target_width
                            valid_idx = idx1;
                            is_visible = 1;
                        end

                        % add all points regardless of visibility (need this later to average accross workers)
                        nextpidx = nextpidx + 1;

                        if valid_idx > 0
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).x = P(valid_idx, 1);
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).y = P(valid_idx, 2);
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).id = nextpidx - 1;
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).is_visible = is_visible;
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).is_inside = 1;
                        else
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).x = 0;
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).y = 0;
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).id = nextpidx - 1;
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).is_visible = 0;
                            annolist(hit_aidx).annorect(hit_ridx).annopoints.point(nextpidx).is_inside = 0;
                        end
                    end % points
                end % if has image name

                % at this point it is possible that someone submitted empty results
                if isfield(annolist(hit_aidx).annorect(hit_ridx), 'annopoints') && length(annolist(hit_aidx).annorect(hit_ridx).annopoints) > 0
                    annolist(hit_aidx).annorect(hit_ridx) = annorect_comp_bbox(annolist(hit_aidx).annorect(hit_ridx));
                else
                    % default rect to indicate empty annotation
                    annolist(hit_aidx).annorect(hit_ridx).x1 = 42;
                    annolist(hit_aidx).annorect(hit_ridx).y1 = 42;
                    annolist(hit_aidx).annorect(hit_ridx).x2 = 42;
                    annolist(hit_aidx).annorect(hit_ridx).y2 = 42;
                    annolist(hit_aidx).annorect(hit_ridx).annopoints.point = struct('x', {}, 'y', {}, 'id', {});
                end

                fprintf('%s, points: %d\n', annolist(hit_aidx).image.name, length(annolist(hit_aidx).annorect(hit_ridx).annopoints.point));

            else
                % some other file extension, hmm.... (once i accidently submitted a txt file)
                num_other_filetype = num_other_filetype + 1;
                hits_empty{end+1} = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
            end

            % AMT viewpoint annotation
        elseif length(tokens) > 1 && ~isempty(strfind(tokens{1}, 'torso_viewpoint'))

            if ~isempty(strfind(tokens{2}, '.jpg'))

                fname = tokens{2};

                % find annotation corresponding to this image (in case there annotations of the same person by several AMT workers)
                if annotation_by_name.isKey(fname)
                    hit_aidx = annotation_by_name(fname);
                else
                    num_anno = num_anno + 1;
                    hit_aidx = num_anno;
                    annolist(hit_aidx).image.name = [basedir '/' fname];
                    annolist(hit_aidx).annorect = struct('x1', {}, 'y1', {}, 'x2', {}, 'y2', {}, 'annopoints', {}, 'is_error', {}, ...
                        'workerid', {}, 'comment', {}, 'time', {}, 'hitid', {}, 'assignmentid', {});
                    annotation_by_name(fname) = hit_aidx;
                end

                % index of this annotation
                hit_ridx = length(annolist(hit_aidx).annorect) + 1;

                % also set other fields: workerId, comment, time, hitid
                annolist(hit_aidx).annorect(hit_ridx).hitid = strtrim(A{aidx, column_by_name(HITID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).assignmentid = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).workerid = strtrim(A{aidx, column_by_name(WORKERID_STR)});

                % figure out the time it took to process this hit
                % ...
                annolist(hit_aidx).annorect(hit_ridx).time = 1;
                annolist(hit_aidx).annorect(hit_ridx).is_error = 0;

                % OLD format: torso_viewpoint, <FILENAME>, head_x, head_y, head_z, torso_x, torso_y ,torso_z
                % R = R_x*R_y*R_z
                % p_rot = R*p
                % assert(length(tokens) == 8);

                % New format: torso_viewpoint, <FILENAME>, head_r11, head_r21, head_r31 , ... *column major*, head_r33, torso_r11, ...., torso_r33
                assert(length(tokens) == 20);

                annolist(hit_aidx).annorect(hit_ridx).x1 = 0;
                annolist(hit_aidx).annorect(hit_ridx).x2 = 0;
                annolist(hit_aidx).annorect(hit_ridx).y1 = 0;
                annolist(hit_aidx).annorect(hit_ridx).y2 = 0;

                next_token_idx = 3;

                for idx1 = 1:3
                    for idx2 = 1:3
                        field_name = ['head_r' num2str(idx2) num2str(idx1)];
                        %X = setfield(annolist(hit_aidx).annorect(hit_ridx), field_name, str2num(tokens{next_token_idx}));
                        annolist(hit_aidx).annorect(hit_ridx).(field_name) = str2num(tokens{next_token_idx});
                        next_token_idx = next_token_idx + 1;
                    end
                end

                for idx1 = 1:3
                    for idx2 = 1:3
                        field_name = ['torso_r' num2str(idx2) num2str(idx1)];
                        %X = setfield(annolist(hit_aidx).annorect(hit_ridx), field_name, str2num(tokens{next_token_idx}));
                        annolist(hit_aidx).annorect(hit_ridx).(field_name) = str2num(tokens{next_token_idx});
                        next_token_idx = next_token_idx + 1;
                    end
                end

                assert(next_token_idx == 21);

                % annolist(hit_aidx).annorect(hit_ridx).head_rot_x = str2num(tokens{3});
                % annolist(hit_aidx).annorect(hit_ridx).head_rot_y = str2num(tokens{4});
                % annolist(hit_aidx).annorect(hit_ridx).head_rot_z = str2num(tokens{5});

                % annolist(hit_aidx).annorect(hit_ridx).torso_rot_x = str2num(tokens{6});
                % annolist(hit_aidx).annorect(hit_ridx).torso_rot_y = str2num(tokens{7});
                % annolist(hit_aidx).annorect(hit_ridx).torso_rot_z = str2num(tokens{8});

            else
                % some other file extension, hmm.... (once i accidently submitted a txt file)
                num_other_filetype = num_other_filetype + 1;
                hits_empty{end+1} = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
            end

            % AMT occlusion annotation
        elseif length(tokens) > 1 && ~isempty(strfind(tokens{1}, 'part_occlusion'))

            if ~isempty(strfind(tokens{2}, '.jpg'))
                fname = tokens{2};

                % find annotation corresponding to this image (in case there annotations of the same person by several AMT workers)
                if annotation_by_name.isKey(fname)
                    hit_aidx = annotation_by_name(fname);
                else
                    num_anno = num_anno + 1;
                    hit_aidx = num_anno;
                    annolist(hit_aidx).image.name = [basedir '/' fname];
                    annolist(hit_aidx).annorect = struct('x1', {}, 'y1', {}, 'x2', {}, 'y2', {}, 'annopoints', {}, 'is_error', {}, ...
                        'workerid', {}, 'comment', {}, 'time', {}, 'hitid', {}, 'assignmentid', {});
                    annotation_by_name(fname) = hit_aidx;
                end

                % index of this annotation
                hit_ridx = length(annolist(hit_aidx).annorect) + 1;

                % annolist(hit_aidx).annorect(hit_ridx).amt_annotation_str = strtrim(A{aidx, column_by_name(ANNOTATION_STR)});

                % also set other fields: workerId, comment, time, hitid
                annolist(hit_aidx).annorect(hit_ridx).hitid = strtrim(A{aidx, column_by_name(HITID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).assignmentid = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
                annolist(hit_aidx).annorect(hit_ridx).workerid = strtrim(A{aidx, column_by_name(WORKERID_STR)});

                % figure out the time it took to process this hit
                % ...
                annolist(hit_aidx).annorect(hit_ridx).time = 1;
                annolist(hit_aidx).annorect(hit_ridx).is_error = 0;

                assert(length(tokens) == 13);

                annolist(hit_aidx).annorect(hit_ridx).x1 = 0;
                annolist(hit_aidx).annorect(hit_ridx).x2 = 0;
                annolist(hit_aidx).annorect(hit_ridx).y1 = 0;
                annolist(hit_aidx).annorect(hit_ridx).y2 = 0;

                next_token_idx = 3;

                for idx1 = 1:10
                    field_name = ['part_occ' num2str(idx1)];
                    annolist(hit_aidx).annorect(hit_ridx).(field_name) = str2num(tokens{next_token_idx});
                    next_token_idx = next_token_idx + 1;
                end

                % last checkbox is to signal error in pose annotation
                annolist(hit_aidx).annorect(hit_ridx).checkbox_pose_error = str2num(tokens{next_token_idx});
                next_token_idx = next_token_idx + 1;

                assert(next_token_idx == 14);

            else
                % some other file extension, hmm.... (once i accidently submitted a txt file)
                num_other_filetype = num_other_filetype + 1;
                hits_empty{end+1} = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
            end


        elseif length(tokens) > 1 && ~isempty(strfind(tokens{1}, 'label_cars'))

             % MA: add token later, for now assume it is car detection task

            if ~isempty(strfind(tokens{2}, '.jpeg')) || ~isempty(strfind(tokens{2}, '.jpg'))

                %fname = tokens{1};

                % fname will contain S3 url, convetion is that local path has the same
                % top level dir and filename
                [fpath1, fname1, fext1] = splitpathext(tokens{2});
                [fpath2, fname2, fext2] = splitpathext(fpath1);
                fname = [fname2 '/' fname1 '.' fext1];

                fprintf('fname: %s\n', fname);

                % find annotation corresponding to this image (in case there annotations of the same person by several AMT workers)
                if annotation_by_name.isKey(fname)
                    hit_aidx = annotation_by_name(fname);
                else
                    num_anno = num_anno + 1;
                    hit_aidx = num_anno;

                    %annolist(hit_aidx).image.name = [basedir '/' fname];

		    % MA: switch to using relative path (easier to copy to the shared fileserver)
		    annolist(hit_aidx).image.name = fname;

                    disp(annolist(hit_aidx).image.name);
                    %annolist(hit_aidx).annorect = struct('x1', {}, 'y1', {}, 'x2', {}, 'y2', {}, 'annopoints', {}, 'is_error', {}, ...
                    %'workerid', {}, 'comment', {}, 'time', {}, 'hitid', {}, 'assignmentid', {});

                    annotation_by_name(fname) = hit_aidx;
                end

                assert(mod(length(tokens) - 2, 6) == 0);
                num_rects  = floor((length(tokens) - 1) / 6);

		annolist(hit_aidx).hitid = strtrim(A{aidx, column_by_name(HITID_STR)});
		annolist(hit_aidx).assignmentid = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
		annolist(hit_aidx).workerid = strtrim(A{aidx, column_by_name(WORKERID_STR)});

                for hit_ridx = 1:num_rects
                    % annolist(hit_aidx).annorect(hit_ridx).amt_annotation_str = strtrim(A{aidx, column_by_name(ANNOTATION_STR)});

		    % MA: in car labeling these are per image, not per bounding box
                    % also set other fields: workerId, comment, time, hitid
                    %annolist(hit_aidx).annorect(hit_ridx).hitid = strtrim(A{aidx, column_by_name(HITID_STR)});
                    %annolist(hit_aidx).annorect(hit_ridx).assignmentid = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
                    %annolist(hit_aidx).annorect(hit_ridx).workerid = strtrim(A{aidx, column_by_name(WORKERID_STR)});

                    annolist(hit_aidx).annorect(hit_ridx).x1 = round(str2num(tokens{6*(hit_ridx - 1) + 3}));
                    annolist(hit_aidx).annorect(hit_ridx).y1 = round(str2num(tokens{6*(hit_ridx - 1) + 4}));
                    annolist(hit_aidx).annorect(hit_ridx).x2 = round(str2num(tokens{6*(hit_ridx - 1) + 5}));
                    annolist(hit_aidx).annorect(hit_ridx).y2 = round(str2num(tokens{6*(hit_ridx - 1) + 6}));

                    %annolist(hit_aidx).annorect(hit_ridx).silhouette.id = str2num(tokens{6*(hit_ridx - 1) + 7});
		    annolist(hit_aidx).annorect(hit_ridx).score = str2num(tokens{6*(hit_ridx - 1) + 7});
                end

            else
                assert(false);

                % some other file extension, hmm.... (once i accidently submitted a txt file)
                num_other_filetype = num_other_filetype + 1;
                hits_empty{end+1} = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
            end



        else
            % unknown task
            assert(false);
        end


    else

      % MA: include unlabeled images in the final output (?)
      % todo: include these into separate file, commented out for now

      % begin - car labeling specific
      % if ~isempty(strfind(tokens{2}, '.jpeg'))
      % 	% fname will contain S3 url, convention is that local path has the same
      % 	% top level dir and filename
      % 	[fpath1, fname1, fext1] = splitpathext(tokens{2});
      % 	[fpath2, fname2, fext2] = splitpathext(fpath1);
      % 	fname = [fname2 '/' fname1 '.' fext1];

      % 	fprintf('fname: %s\n', fname);
      % 	hit_aidx = length(annolist_empty) + 1;
      % 	annolist_empty(hit_aidx).image.name = fname;
      % end
      % end - car labeling specific

      num_empty_data = num_empty_data + 1;
      hits_empty{end+1} = strtrim(A{aidx, column_by_name(ASSIGNMENTID_STR)});
    end


end

% sanity check if id's
for aidx = 1:length(annolist)
    for ridx = 1:length(annolist(aidx).annorect)
        if isfield(annolist(aidx).annorect(ridx), 'annopoints') && isfield(annolist(aidx).annorect(ridx).annopoints, 'point') && length(annolist(aidx).annorect(ridx).annopoints.point)  > 0
            assert(length(annolist(aidx).annorect(ridx).annopoints.point) == 15);

            for kidx = 1:length(annolist(aidx).annorect(ridx).annopoints.point)
                assert(annolist(aidx).annorect(ridx).annopoints.point(kidx).id == kidx - 1);
            end

        end
    end
end

%annolist

[~, amt_name, ext] = splitpathext(amt_results);
outname = [basedir '/' amt_name '.al'];
outname_empty = [basedir '/' amt_name '_empty.al'];
outname_mat = [basedir '/' amt_name '.mat'];

fprintf('saving %s\n', outname);
saveannotations(annolist, outname);

if length(annolist_empty) > 0
  fprintf('saving %s\n', outname_empty);
  saveannotations(annolist_empty, outname_empty);
end

fprintf('saving %s\n', outname_mat);
save(outname_mat, 'annolist');

fprintf('num_both_inside: %d\n', num_both_inside);

% sanity check
num_rects = 0;

for aidx = 1:length(annolist)
    num_rects = num_rects + length(annolist(aidx).annorect);
end

fprintf('num_empty_data: %d, num_other_filetype: %d, num_rects: %d, num_data_rows: %d\n', num_empty_data, ...
    num_other_filetype, num_rects, size(A, 1) - 1);

fprintf('empty assignments: \n');
fprintf('"%s"\n', hits_empty{:});

% check we did not forget anyone
if ~(num_empty_data + num_rects + num_other_filetype == size(A, 1) - 1);
    warning('mismatch in sanity check');
end
%assert(num_empty_data + num_rects + num_other_filetype == size(A, 1) - 1);
