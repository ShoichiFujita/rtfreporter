# Copilot Instructions for rtfreporter

このリポジトリでは R と Python の両パッケージを管理しています。
作業前に必ず `specs/release_guidelines.md` を参照してください。

## 重要ルール（必ず守ること）

### リポジトリ構成
- `r/rtfreporter/` — Rパッケージ
- `python/` — Pythonパッケージ

### GitHub Release 作成時
1. **R の `DESCRIPTION` の `Version` は数字とピリオドのみ**（例: `0.0.2`）。`-alpha` などのサフィックスは付けない。
2. **RとPython、それぞれ個別のtar.gzをアセットとして添付する**。リポジトリ全体の Source code は使わない。
   - R用: `tar -czf rtfreporter_X.Y.Z.tar.gz -C "r" "rtfreporter"`
   - Python用: `tar -czf rtfreporter_python_X.Y.Z.tar.gz -C "." "python"`
3. **vignette のビルド済みHTMLを `r/rtfreporter/inst/doc/` に含めてからtar.gzを作成する**。
   ```r
   rmarkdown::render(
     'r/rtfreporter/vignettes/rtfreporter-quickstart.Rmd',
     output_dir = 'r/rtfreporter/inst/doc',
     output_format = 'rmarkdown::html_vignette'
   )
   file.copy('r/rtfreporter/vignettes/rtfreporter-quickstart.Rmd',
             'r/rtfreporter/inst/doc/')
   ```

詳細は `specs/release_guidelines.md` を参照。
