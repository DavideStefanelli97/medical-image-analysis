# Contributions

This document clarifies authorship and origin of all code in this repository.

## Original Implementations — Davide Stefanelli

All analysis scripts and the following library functions were written from scratch as part of this project.

### Core Algorithms (`lib/core/`)

| Function | Description |
|----------|-------------|
| `runChanVese.m` | Chan-Vese level-set segmentation engine with convergence detection and evolution history |
| `computeLSF.m` | Level-set function initialization with interactive seed selection (inputParser API) |
| `initLSFfrompoints.m` | Level-set initialization from polygon vertices via cubic spline interpolation |
| `smartRegister.m` | Unified registration framework supporting translation and rotation with selectable metrics |
| `anisodiff2D.m` | 2D Perona-Malik anisotropic diffusion filter |
| `compute_joint_histogram.m` | Vectorized joint histogram computation using `accumarray` |
| `contrastStretchFixed.m` | Percentile-based contrast enhancement with optional diagnostic plots |
| `sigmoidContrastStretch.m` | Sigmoid-based smooth contrast stretching |

### Similarity Metrics (`lib/metrics/`)

| Function | Description |
|----------|-------------|
| `NCC.m` | Normalized Cross-Correlation |
| `SSD.m` | Sum of Squared Differences |
| `MI.m` | Mutual Information (Shannon) |
| `entropy.m` | Shannon entropy via normalized histogram |
| `joint_entropy.m` | Joint entropy between two images |

### Visualization (`lib/visualization/`)

| Function | Description |
|----------|-------------|
| `plotLSF.m` | Dual 3D surface + 2D zero-contour level-set visualization (inputParser API) |
| `plotEvolution.m` | Animated Chan-Vese evolution with area tracking and summary report |
| `plotHeatMap.m` | Registration similarity metric heatmap with optimal-point overlay |
| `plotRotationMetrics.m` | Rotation angle vs. metric plot |
| `checkerboard_view.m` | Checkerboard overlay comparison with automatic size matching |
| `generate_registration_report.m` | Multi-panel registration quality dashboard (before/after MI, joint histogram, checkerboard) |
| `image_viewer.m` | Image display with histogram and pixel-spacing diagnostics |

### Analysis Scripts (`scripts/`)

| Script | Description |
|--------|-------------|
| `seg_kidney_medulla.m` | Kidney and medulla segmentation with pre-registration (Chan-Vese) |
| `seg_ventricles.m` | Left and right ventricle segmentation (Malladi-Sethian) |
| `seg_left_atrium_3d.m` | 3D left atrium segmentation from MRI volume (slice-by-slice Chan-Vese + iso2mesh) |
| `seg_breast_lesion.m` | Breast lesion segmentation (Malladi-Sethian) |
| `reg_translation.m` | Multimodal translational registration (T2/DWI/PET, exhaustive grid search) |
| `reg_rotation.m` | Rotational registration with angle sweep |
| `main_gui.m` | GUI launcher for all scripts |

## Adapted Course Utilities (`lib/operators/`)

Standard finite difference operators adapted from course-provided numerical stencils (Smart Medical Imaging, University of Bologna):

`Dx.m`, `Dy.m`, `Dxx.m`, `Dyy.m`, `Dp_x.m`, `Dp_y.m`, `Dm_x.m`, `Dm_y.m`, `Laplacian.m`, `Grad.m`, `Gup.m`, `K.m`, `zeroPadding.m`

## Third-Party Dependencies

| Library | Version | License | Usage |
|---------|---------|---------|-------|
| [iso2mesh](http://iso2mesh.sourceforge.net/) | 1.9.6 | GPL v2+ | 3D mesh reconstruction in `seg_left_atrium_3d.m` only |

iso2mesh is **not bundled** in this repository. See [Getting Started](#getting-started) in the README for installation instructions.
