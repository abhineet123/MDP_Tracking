line_width = 2;

k = importdata('data_prec_rec.txt');
track_recall=k(:, 1);
track_prec=k(:, 2);
det_recall=k(:, 3);
det_prec=k(:, 4);
x = 1:numel(track_recall);
figure, plot(x, track_recall, x, det_recall, 'LineWidth', line_width), grid on, legend({'Tracking', 'Detection'}), xlabel('Detector Configuration'), ylabel('Recall'), title('Tracking vs Detection Recall');
figure, plot(x, track_prec, x, det_prec, 'LineWidth', line_width), grid on, legend({'Tracking', 'Detection'}), xlabel('Detector Configuration'), ylabel('Precision'), title('Tracking vs Detection Precision');
k2 = importdata('data_mt.txt');
mt = k2(:, 1);
figure, plot(x, mt./100, x, det_recall, x, det_prec, 'LineWidth', line_width), grid on, legend({'MT', 'Recall', 'Precision'}), xlabel('Detector Configuration'), ylabel('MT/Recall/Precision'), title('MT vs Detection Recall/Precision');