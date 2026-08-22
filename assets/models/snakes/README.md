# Photogrammetry / scanned snake

Drop a real scan here as `scanned_snake.glb` (glTF binary).

The game looks for:

- `res://assets/models/snakes/scanned_snake.glb`

If that file exists, each snake body is the scanned mesh bent along the live slither spline (curve deform). If it is missing, DeepSnakes builds a dense tube and applies a photogrammetry-style PBR scale atlas generated at runtime (albedo, tangent normal, roughness).

## How to make a scan

1. Photograph a shed skin or a legally obtained specimen (or a high-end prop) with polarized light.
2. Reconstruct in RealityCapture, Metashape, or Polycam.
3. Retopologize to a tube-like mesh: length along +Y, belly on −Z, head at Y-max.
4. Export glTF 2.0 with albedo, normal (OpenGL), roughness.
5. Place the file at the path above and restart the project.

Environment ground scans are CC0 photogrammetry from [Poly Haven](https://polyhaven.com/license). Run `tools/fetch_polyhaven.ps1` to download 1K PBR sets into `assets/photogrammetry/`.
