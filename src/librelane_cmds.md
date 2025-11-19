# Collection of commands to use librelane


To run librelane, it is required to start a nix shell. Do the step below in the root of the librelane local repo (dev branch):

## Librelane nix setup (from librelane git repo root - in dev branch)
```sh
nix-shell --pure shell.nix
```


Now that the nix is active, go to digital/src and choose which PDK to do the physical implementation of the design.

## Run librelane targeting SKY130A
```sh
librelane librelane_config.json
```

## Run librelane targeting GF180
```sh
librelane --pdk gf180mcuD librelane_config.json
```

## Run librelane targeting IHP-Open-PDK(sg13g2):
```sh
librelane --pdk ihp-sg13g2 librelane_config.json
```


To view the layout, run the following commands:

## View layout of last run with OpenROAD
```sh
librelane --last-run --flow openinopenroad librelane_config.json
```

## View layout of last run with KLayout
```sh
librelane --last-run --flow openinklayout librelane_config.json
```


## Librelane documentation
https://librelane.readthedocs.io/en/latest/index.html