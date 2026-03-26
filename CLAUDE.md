# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MATLAB-based medical imaging project implementing level-set segmentation (Chan-Vese, Malladi-Sethian) and rigid registration (translation, rotation with NCC/SSD/MI) for DICOM medical images. No build system -- scripts run directly in the MATLAB interpreter.

## Running

```matlab
% From any directory -- setup.m handles all paths
setup              % initializes PROJECT_ROOT and adds lib/ to path
main_gui           % GUI launcher (recommended)

% Or run scripts directly
seg_kidney_medulla
reg_translation
```

`setup.m` uses `fileparts(mfilename('fullpath'))` to detect the project root, so the working directory does not matter. All scripts call `setup.m` internally.

## Scripts

| Script | Location | Task | Algorithm |
|--------|----------|------|-----------|
| `seg_kidney_medulla` | `scripts/segmentation/` | Kidney & medulla segmentation | Chan-Vese + pre-registration |
| `seg_ventricles` | `scripts/segmentation/` | LV & RV endocardium | Malladi-Sethian |
| `seg_left_atrium_3d` | `scripts/segmentation/` | 3D left atrium volume + mesh | Chan-Vese (slice-by-slice) + iso2mesh |
| `seg_breast_lesion` | `scripts/segmentation/` | Breast lesion delineation | Malladi-Sethian |
| `reg_translation` | `scripts/registration/` | Multimodal brain registration | Exhaustive grid search |
| `reg_rotation` | `scripts/registration/` | Rotation correction | Angle sweep 0-359.5 deg |
| `main_gui` | `scripts/` | GUI launcher | Buttons calling each script |

## Architecture

**lib/** contains all reusable functions:

- **lib/core/** -- Core algorithms: `runChanVese`, `computeLSF`, `initLSFfrompoints`, `smartRegister`, `anisodiff2D`, `compute_joint_histogram`, `contrastStretchFixed`, `sigmoidContrastStretch`
- **lib/operators/** -- Finite difference operators: `Dx`, `Dy`, `Dxx`, `Dyy`, `Dp_x`, `Dp_y`, `Dm_x`, `Dm_y`, `Laplacian`, `Grad`, `Gup`, `K`, `zeroPadding`
- **lib/metrics/** -- Similarity metrics: `NCC`, `SSD`, `MI`, `entropy`, `joint_entropy`
- **lib/visualization/** -- Plotting/reporting: `plotLSF`, `plotEvolution`, `plotHeatMap`, `plotRotationMetrics`, `checkerboard_view`, `generate_registration_report`, `image_viewer`

## Key Design Patterns

- **Path portability**: All scripts resolve paths via `PROJECT_ROOT` (set by `setup.m`). Data is referenced as `fullfile(PROJECT_ROOT, 'data', filename)`.
- **Interactive input**: Segmentation scripts use `getrect()` and `ginput()` for ROI selection -- they block waiting for user clicks. Registration scripts are fully automated.
- **Parameter style**: `smartRegister.m`, `computeLSF.m`, `plotLSF.m` use `inputParser` for name-value pairs. Simpler functions use positional args.
- **No test suite**: Validation is visual (plots/figures) and via console-printed metrics.

## Data

DICOM files and `patient5.mat` (3D MRI volume, 35 MB, Git LFS tracked) live in `data/`.

## Dependencies

- MATLAB R2020b+ with Image Processing Toolbox
- [iso2mesh v1.9.6](http://iso2mesh.sf.net) -- external, required only by `seg_left_atrium_3d`

## Ownership

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md). The `lib/core/`, `lib/metrics/`, and `lib/visualization/` functions are original work. The `lib/operators/` functions are adapted from course-provided numerical stencils.
