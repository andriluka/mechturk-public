function [target_height, target_width, target_total_width] = get_subframe_dim
  use_occ_labels = 1;

  %target_height = 600;
  target_height = 450;
  target_total_width = 800 + use_occ_labels*100;
  target_width = target_total_width - 180 - use_occ_labels*100;
