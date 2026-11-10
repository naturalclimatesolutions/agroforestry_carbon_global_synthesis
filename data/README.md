# Input data

All notebooks read inputs from this folder via `here::here("data", ...)`.

| File | Description | Source |
|---|---|---|
| `groa_af/studies.csv` | One row per screened study (2,737): bibliographic information, inclusion decision (`included`, 1,461 included) and exclusion reason. | GROA-AF dataset (this study), published in this repository |
| `groa_af/sites.csv` | One row per site with measurements (2,355): location as given and harmonized (bounding-box centroid, bounds, area), country, Audebert ecological zone and ecoregion, climate and elevation (as given and harmonized), SoilGrids soil texture. | GROA-AF dataset, with covariates from external sources (see below) |
| `groa_af/measurements.csv` | One row per carbon (or biomass, SOM) measurement (24,764): plot, system, age, value as given and harmonized carbon (`c_t_ha`), soil and stand covariates, management. | GROA-AF dataset |
| `groa_af/metadata.csv` | Every column of the three tables, in file order: type and description. | GROA-AF dataset |
| `species_trait_data.csv` | Species-level plant traits (height, wood density, leaf area, rooting depth, N fixation, mycorrhizal type, freezing exposure) keyed by `AccSpeciesName`. | TRY Plant Trait Database (Kattge et al. 2020, https://www.try-db.org) |

## The GROA-AF dataset

The three tables link through `study_id` (studies -> measurements; a site
lists its studies in `study_ids`) and `site_id` (sites -> measurements).
`measurement_id` is the unique key of a measurement. A plot is identified by
`study_id` + `site_id` + `plot_id`.

Naming convention: the harmonized (analysis-ready) version of a variable has
the plain name (`af_cat`, `sand_pct`, `lat`, `map`); the value as reported by
the source study has the same name with the suffix `_as_given`
(`af_cat_as_given`, `sand_pct_as_given`, `lat_as_given`, `map_as_given`).
Ranges are stored as text in the form `"X to Y"`; inequalities as `">X"` /
`"<X"`. Empty cells are missing values.

Columns are ordered with identifiers first, from the top of the hierarchy down
(study, site, plot, measurement), then by theme; a value as given precedes its
harmonized version. In `measurements.csv`, the uncertainty columns
(`ci95_*_as_given`, `se_as_given`, `sd_as_given`) and `n_replicates` refer to
`value_as_given` in `units_as_given`, not to the harmonized `c_t_ha`.

Encoding: the CSVs are UTF-8 with a byte-order mark, so Excel displays accented
text correctly. In base R, read them with `read.csv(..., fileEncoding = "UTF-8-BOM")`;
readr, data.table and pandas handle the byte-order mark automatically.

Site covariates from external sources:

- Ecoregion: Audebert et al. (2024) Level I ecological zones at the site's
  bounding-box centroid (nearest zone within 100 km where the centroid falls
  outside all zones), collapsed to five classes (`audebert_ecoregion_5class`; the "ecoregion" of the paper).
- `map`, `mat`, `masl`: the study's value where reported (midpoint of ranges),
  otherwise backfilled from WorldClim 2 (Fick & Hijmans 2017) at the site
  coordinates (`*_source` says which).
- `*_soilgrids`: SoilGrids 2.0 (Poggio et al. 2021) sand, silt and clay,
  averaged across the site's bounding box; used where measurement-level
  texture is missing.

## Licensing

Data created by the authors are released under CC BY 4.0. Third-party data
(TRY traits and externally sourced covariates) remain under their original
licenses; see the sources above.

## References

- Audebert, P., Milne, E., Schiettecatte, L.-S., Dionisio, D., Sinitambirivoutin, M.,
  Pais, C., Proença, C. & Bernoux, M. (2024). Ecological zoning for climate policy
  and global change studies. *Nature Sustainability* 7, 1294–1303.
  https://doi.org/10.1038/s41893-024-01416-5
- Fick, S. E. & Hijmans, R. J. (2017). WorldClim 2: new 1-km spatial resolution
  climate surfaces for global land areas. *International Journal of Climatology*
  37, 4302–4315. https://doi.org/10.1002/joc.5086
- Poggio, L. et al. (2021). SoilGrids 2.0: producing soil information for the globe
  with quantified spatial uncertainty. *SOIL* 7, 217–240.
  https://doi.org/10.5194/soil-7-217-2021
- Kattge, J. et al. (2020). TRY plant trait database – enhanced coverage and open
  access. *Global Change Biology* 26, 119–188. https://doi.org/10.1111/gcb.14904
