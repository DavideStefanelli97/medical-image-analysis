# Medical Image Analysis

Level-set segmentation and rigid registration of medical DICOM images in MATLAB.

## Overview

This repository implements a medical image analysis pipeline with two modules:

- **Segmentation** -- Chan-Vese and Malladi-Sethian level-set methods applied to four clinical scenarios (kidney, cardiac ventricles, left atrium in 3D, breast lesion).
- **Registration** -- Exhaustive-search rigid registration (translation and rotation) evaluated with three similarity metrics (NCC, SSD, MI).

All analysis scripts share a common library of 20+ custom MATLAB functions covering numerical operators, similarity metrics, preprocessing, and publication-quality visualization.

## Algorithms Implemented

### Segmentation

**Chan-Vese Active Contours** -- Solves the piecewise-constant Mumford-Shah functional via level-set evolution. The contour minimizes a combined energy of curvature regularization and inside/outside intensity fitting. Used for kidney, medulla, and left atrium segmentation.

**Malladi-Sethian Level Sets** -- Geometric PDE-based segmentation using an edge indicator function g = 1/(1 + |nabla I / beta|^alpha). The level set evolves under curvature, advection, and edge-stopping forces. Used for ventricle and breast lesion segmentation.

### Registration

**Translational Registration** -- 2D exhaustive grid search over a discrete shift range. Each candidate translation is scored with NCC (maximize), SSD (minimize), or MI (maximize). Applied to multimodal brain imaging (T2, DWI, PET).

**Rotational Registration** -- Angular sweep from 0 to 359.5 degrees at 0.5-degree resolution, using the same three metrics. Applied to rotated MRI alignment.

## Case Studies

| Script | Clinical Application | Algorithm | Input Modality |
|--------|---------------------|-----------|----------------|
| `seg_kidney_medulla` | Kidney + medulla segmentation | Chan-Vese (with pre-registration) | Contrast / non-contrast CT |
| `seg_ventricles` | Left & right ventricle endocardium | Malladi-Sethian | Cardiac MRI |
| `seg_left_atrium_3d` | 3D left atrium volume + mesh | Chan-Vese (slice-by-slice) + iso2mesh | 3D MRI volume |
| `seg_breast_lesion` | Breast lesion delineation | Malladi-Sethian | Breast MRI |
| `reg_translation` | Multimodal brain registration | Exhaustive translation search | T2 / DWI / PET |
| `reg_rotation` | Rotation correction | Exhaustive angle sweep | T2 MRI |

## Repository Structure

```
medical-image-analysis/
├── setup.m                        # Path initialization (run this first)
├── scripts/
│   ├── main_gui.m                 # GUI launcher
│   ├── segmentation/              # 4 segmentation case studies
│   └── registration/              # 2 registration case studies
├── lib/
│   ├── core/                      # Segmentation engines, registration framework, preprocessing
│   ├── operators/                 # Finite difference operators (Dx, Dy, Laplacian, etc.)
│   ├── metrics/                   # Similarity metrics (NCC, SSD, MI, entropy)
│   └── visualization/             # Plotting and reporting functions
├── data/                          # DICOM images and 3D MRI volume
├── results/                       # Saved figures and metrics (generated at runtime)
└── docs/                          # Documentation and portfolio assets
```

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for a detailed mapping of which code is original, which is adapted from course materials, and which is third-party.

## Getting Started

### Requirements

- MATLAB R2020b or later
- Image Processing Toolbox
- [iso2mesh v1.9.6](http://iso2mesh.sourceforge.net/) (required only for `seg_left_atrium_3d`)

### Setup

```matlab
% 1. Clone the repository
% 2. Open MATLAB and navigate to the project root
% 3. Initialize paths:
setup

% 4. (Optional) Install iso2mesh for 3D segmentation:
%    Download from http://iso2mesh.sf.net and add to MATLAB path
```

### Running

**GUI launcher:**
```matlab
main_gui
```

**Individual scripts:**
```matlab
setup                    % initialize paths (once per session)
seg_kidney_medulla       % or any other script name
```

The registration scripts (`reg_translation`, `reg_rotation`) run fully automatically.
The segmentation scripts require interactive seed-point selection via mouse clicks.

## Custom Function Reference

| Function | Category | Description |
|----------|----------|-------------|
| `runChanVese` | Core | Chan-Vese level-set evolution with convergence detection |
| `computeLSF` | Core | Level-set initialization with interactive seed selection |
| `smartRegister` | Core | Unified registration framework (translation / rotation) |
| `anisodiff2D` | Core | Perona-Malik anisotropic diffusion filter |
| `NCC`, `SSD`, `MI` | Metrics | Normalized cross-correlation, sum of squared differences, mutual information |
| `plotLSF` | Visualization | 3D surface + 2D contour level-set display |
| `plotEvolution` | Visualization | Animated segmentation evolution with area tracking |
| `generate_registration_report` | Visualization | Multi-panel registration quality dashboard |

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

The [iso2mesh](http://iso2mesh.sourceforge.net/) toolbox (not bundled) is licensed under GPL v2+.
