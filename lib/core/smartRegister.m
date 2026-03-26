function [reg_img, best_params, metrics] = smartRegister(fixed_img, moving_img, mode, varargin)
% smartRegister - Registers two medical images using translation, rotation, or both.
%
% Syntax:
%   [reg_img, best_params, metrics] = smartRegister(fixed_img, moving_img, mode, ...)
%
% Inputs:
%   fixed_img   - 2D matrix, reference image
%   moving_img  - 2D matrix, image to register
%   mode        - String: 'trasl', 'rot',
%
% Optional name-value pair arguments:
%   'metric'        - Similarity metric: 'NCC' (default), 'SSD', or 'MI'
%   'max_shift'     - Max translation (pixels), default: 25
%   'angle_step'    - Angular resolution in degrees, default: 0.5
%   'angle_range'   - Rotation range in degrees, default: [0 359.5]
%   'verbose'       - Logical, show logs and plots, default: false
%   'checker_size'  - Size of checkerboard patches, default: 20
%
% Outputs:
%   reg_img     - Registered moving image
%   best_params - Struct with fields 'translation' and/or 'rotation'
%   metrics     - Struct with similarity metric values at best alignment
% Author: Davide Stefanelli

% -----------------------
% 1. Parse input arguments
% -----------------------

p = inputParser;

addParameter(p, 'metric', 'NCC', @(x) ischar(x) || isstring(x));
addParameter(p, 'max_shift', 25, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'angle_step', 0.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'angle_range', [0 359.5], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'verbose', false, @(x) islogical(x));
addParameter(p, 'checker_size', 20, @(x) isnumeric(x) && isscalar(x) && x > 0);

parse(p, varargin{:});
opts = p.Results;

% Initialize outputs
reg_img = [];
best_params = struct();
metrics = struct();

% -----------------------
% 2. Mode switch
% -----------------------
switch lower(mode)

    case 'trasl'

        % TODO: implement 2D translation
        if opts.verbose
            fprintf('[INFO] Performing translational registration...\n');
        end
        % Define translation search range
        shift = opts.max_shift;
        range = -shift:shift;
        N = length(range);

        % Initialize metric matrix
        metric_map = zeros(N, N);

        % Exhaustive 2D grid search
        for ix = 1:N
            for iy = 1:N
                dx = range(ix);
                dy = range(iy);
                translation = [dy, dx];  % [rows, cols]

                % Apply translation
                moved = imtranslate(moving_img, translation, 'FillValues', 0);

                % Compute selected similarity metric
                switch lower(opts.metric)
                    case 'ncc'
                        metric_val = NCC(fixed_img, moved);
                    case 'ssd'
                        metric_val = SSD(fixed_img, moved);
                    case 'mi'
                        metric_val = MI(fixed_img, moved);
                    otherwise
                        error('Unsupported metric "%s". Choose NCC, SSD, or MI.', opts.metric);
                end

                % Store in map
                metric_map(iy, ix) = metric_val;
            end
        end

        % Find best shift based on metric type
        if strcmpi(opts.metric, 'ssd')
            [~, idx_best] = min(metric_map(:));  % SSD → minimo
        else
            [~, idx_best] = max(metric_map(:));  % NCC or MI → massimo
        end

        [best_row, best_col] = ind2sub(size(metric_map), idx_best);
        best_shift = [range(best_row), range(best_col)];

        % Apply best translation
        reg_img = imtranslate(moving_img, best_shift, 'FillValues', 0);

        % Save outputs
        best_params.translation = best_shift;
        metrics.value = metric_map(best_row, best_col);
        metrics.map = metric_map;

        % Log if verbose
        if opts.verbose
            fprintf('--- Optimal Translation [%s] ---\n', upper(opts.metric));
            fprintf('Best shift: [dx = %d, dy = %d]\n', best_shift(2), best_shift(1));
            fprintf('Metric value: %.4f\n', metrics.value);

            plotHeatMap(metric_map, range, best_row, best_col, opts.metric);

            % Report visuale completo (checkerboard, joint histogram, MI)
            generate_registration_report(fixed_img, moving_img, reg_img, ...
                ['Trasl-' upper(opts.metric)], 128);

        end
%%=========================================================================

    case 'rot'

        % TODO: implement rotation
        if opts.verbose
            fprintf('[INFO] Performing rotational registration...\n');
        end

        % Rotation parameters
        angles = opts.angle_range(1):opts.angle_step:opts.angle_range(2);
        n_angles = length(angles);

        % Prealloca vettore della metrica
        metric_values = zeros(1, n_angles);

        % Loop sugli angoli
        for i = 1:n_angles
            angle = angles(i);
            rotated_img = imrotate(moving_img, angle, 'bilinear', 'crop');

            switch lower(opts.metric)
                case 'ncc'
                    metric_values(i) = NCC(fixed_img, rotated_img);
                case 'ssd'
                    metric_values(i) = SSD(fixed_img, rotated_img);
                case 'mi'
                    metric_values(i) = MI(fixed_img, rotated_img);
                otherwise
                    error('Unsupported metric "%s". Choose NCC, SSD, or MI.', opts.metric);
            end
        end

        % Trova angolo ottimale
        if strcmpi(opts.metric, 'ssd')
            [~, best_idx] = min(metric_values);
        else
            [~, best_idx] = max(metric_values);
        end
        best_angle = angles(best_idx);

        % Applica rotazione finale
        reg_img = imrotate(moving_img, best_angle, 'bilinear', 'crop');

        % Salva risultati
        best_params.rotation = best_angle;
        metrics.angles = angles;
        metrics.values = metric_values;
        metrics.value = metric_values(best_idx);

        % Verbose log + plot
        if opts.verbose
            fprintf('--- Optimal Rotation [%s] ---\n', upper(opts.metric));
            fprintf('Best angle: %.2f°\n', best_angle);
            fprintf('Metric value: %.4f\n', metric_values(best_idx));

            plotRotationMetrics(angles, metric_values, best_idx, opts.metric);

            % Report visuale completo
            generate_registration_report(fixed_img, moving_img, reg_img, ...
                ['Rot-' upper(opts.metric)], 128);

        end
%%=========================================================================

    case 'both'
        % TODO: implement combined rotation + translation
        if opts.verbose
            fprintf('[INFO] Performing combined registration...\n');
        end

    otherwise
        error('Invalid mode "%s". Choose from: "trasl", "rot", "both".', mode);
end

end

