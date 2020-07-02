# bump-dna
Bash script for quick altering of hashspace of selected DNA on HPOS

```
usage: bump-dna [-ih] [-u]
    -i id of dna
    -h hash of dna before bump (overwrites -i)
    -u new uuid (optional, skipping will print current uuid)
```

If successful the script will:
- copy dna to a new file inside `dna/` folder
- change uuid property inside of it
- get new hash of dna and rename dna file to `new_hash.dna.json`
- print new hash
- update holochain config file and restart `holochain-conductor.service` for changes to take effect

> HEADS UP: this script is directly interacting with configuration of holochain conductor. HPOS is managing this configuration file for system consistency, therefore if you want to bump dnas you need to enable `development` profile of HPOS and the `overrideConductorConfig` feature ( see [profiles README in holo-nixpkgs](https://github.com/Holo-Host/holo-nixpkgs/tree/develop/modules/profiles))
