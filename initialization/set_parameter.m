function Para = setparameter()

% Para.segname = 'trainval';
% Para.segname = 'bboxset';
Para.segname = 'test';

% Para.boxname = '_boxes_threshoff_segtrainval_2009';
%     load([VOCopts.classes{k},'_boxes_segtrainval_2009']);
%     load([VOCopts.classes{k},'_boxes_bboxset_2009']);
% Para.boxname = '_boxes_threshoff_bboxset_2009';
% Para.boxname = '_boxes_threshoff_segtest_2009';

Para.boxname = '_boxes_noempty_segtest_2009';

Para.id = 'nonempty';

Para.MaxIter = 100; % max iteration

% bin setting for color histogram
Para.nbins{1} = 0:16:256;
Para.nbins{2} = 0:16:256;
Para.nbins{3} = 0:16:256;

Para.supername = '_n=190';

Para.superfilename = 'n190_testset/';