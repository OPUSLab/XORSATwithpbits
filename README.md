# XORSATwithpbits
Code and data for the 3R3X (XORSAT) problem with probabilistic bits
This repository contains the code used to solve the 3R3X Challenge using p-bits running the Adaptive Parallel Tempering (APT) algorithm. For more details, please see our paper on arXiv (link).

The `sims` directory contains the code used to produce the CPU benchmark. `sims/APT_preprocess.m` implements the algorithm for generating the problem-dependent temperature schedule. `sims/APT.m` implements the Adapative Parallel Tempering algorithm, and `sims/MCMC_GC.m` implements our graph colored Markov Chain Monte Carlo for updating the p-bit states. Finally, `sims/massive_sweep.m` is the top level file for running and storing the outputs of the algorithms.

The `figure-generation` directory contains the raw data from our CPU simulations and from our FPGA trials, along with the code used to convert this data to the optTTS metric and to produce all the plots in our paper. To reproduce our plots, first run the `optTTS_extract_*.m` scripts to populate the `extracted_tts_data/` directory. Then, run the `FIG*.m` scripts to produce the plots.
