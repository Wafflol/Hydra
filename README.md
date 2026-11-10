# Hydra


## Design Decisions

### Register File
If a register read and write on the same clock are to the same address, an internal bypass sends the write data directly to the read output.
