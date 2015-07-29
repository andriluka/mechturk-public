
function amt_process_cars(amt_results);

  is_sandbox = false;

  [return_code, output_str] = system('source ../utils/data_utils_init.sh; echo $MIN_BOX_WIDTH');
  assert(return_code == 0);
  min_box_width = str2num(output_str);

  % MA: bonus we pay per annotated car in USD
  [return_code, output_str] = system('source ../utils/data_utils_init.sh; echo $OBJECT_BONUS_USD');
  assert(return_code == 0);
  object_bonus_usd = str2num(output_str);

  %base_img_dir = '/local/IMAGES/driving_data_twangcat/all_extracted';
  %base_img_dir = '/local/IMAGES/driving_data_sameep/all_extracted';
  %base_img_dir = '/local/IMAGES/driving_data_q50_data/all_extracted';
  %base_img_dir = '/scail/group/deeplearning/driving_data/andriluka/IMAGES/driving_data_q50_data/all_extracted';
  base_img_dir = '/local/IMAGES/mpii_pose3d';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/7-16-sacramento/7-16-sacramento.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/7-18-101/7-18-101.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/7-19-monterey/7-19-monterey.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/7-24-101/7-24-101.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/7-25-bay/7-25-bay.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/8-13-marin/8-13-marin.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/8-14-101/8-14-101.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/8-15-tracy-gilroy/8-15-tracy-gilroy.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-2-14-monterey/4-2-14-monterey.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-3-14-monterey/4-3-14-monterey.results';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-3-14-gilroy-cam2/4-3-14-gilroy-cam2.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-3-14-gilroy/4-3-14-gilroy.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-2-14-monterey-cam2/4-2-14-monterey-cam2.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-9-14-concord-cam2/4-9-14-concord-cam2.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-10-14-pleasanton/4-10-14-pleasanton.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-11-14-sanrafael/4-11-14-sanrafael.results';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-3-14-gilroy-to-gilroy-f2/4-3-14-gilroy-to-gilroy-f2.results';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/5-1-14-monterey/5-1-14-monterey.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-30-14-280/4-30-14-280.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-29-14-granada/4-29-14-granada.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-20-14-280/4-20-14-280.results';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-20-14-280-sandbox/4-20-14-280-sandbox.results';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/4-9-14-concord-split_0_280N_d2/4-9-14-concord-split_0_280N_d2.results';
  %amt_results = '/afs/cs.stanford.edu/u/brodyh/scr/projects/mechturk/hits/6-17-14-280/6-17-14-280.results';
  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/6-13-14-280-cam4/6-13-14-280-cam4.results';

  %amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/youtube_rainy_uk_data-cam2/youtube_rainy_uk_data-cam2.results';
  amt_results = '/afs/cs.stanford.edu/u/andriluka/code/mechturk/hits/seq1_ahmed_walk/seq1_ahmed_walk.results';

  % extract annotations from amt results table
  annolist_all_workers = amt_to_al(base_img_dir, amt_results);

  % optionally, save results for by worker,
  [hit_dir, amt_name, ~] = splitpathext(amt_results);
  worker_annolist = split_by_worker_new(annolist_all_workers, [hit_dir '/results_by_worker_' amt_name]);

  hit_params_filename = [hit_dir '/hit_params.sh'];
  assert(exist(hit_params_filename, 'file') > 0);

  fprintf('using parameters from: %s\n', hit_params_filename);

  [return_code, output_str] = system(['source ' hit_params_filename '; echo $MIN_BOX_WIDTH']);
  assert(return_code == 0);
  min_box_width = str2num(output_str);

  % MA: bonus we pay per annotated car in USD
  [return_code, output_str] = system(['source ' hit_params_filename '; echo $OBJECT_BONUS_USD']);
  assert(return_code == 0);
  object_bonus_usd = str2num(output_str);
  % generate "bonus" for each worker based on the number of annotated cars
  if object_bonus_usd > 0
    al_to_bonus(annolist_all_workers, hit_dir, object_bonus_usd, min_box_width, is_sandbox);
  end

  amt_al_accept_all_gen(annolist_all_workers, amt_results);

  % evaluate annoations
  %amt_al_accept_reject(base_img_dir, amt_results);

  % create accept/reject/empty files
  %amt_al_accept_reject_gen(base_img_dir, amt_results);

%
%   % print worker statistics
%   [amt_path, amt_name, amt_ext] = splitpathext(amt_results);
%   input_mat = [basedir '/' amt_name '_eval.mat'];
%   load(input_mat, 'annolist');
%   amt_print_stats(annolist);
%
%   fprintf('please take a look at annolist_noeval.al and mark rejected annorects with <rc> ... </rc>, then run: \n');
%   fprintf('%s\n', ['amt_process_noeval(''' amt_results ''');']);
%

