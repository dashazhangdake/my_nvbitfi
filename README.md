# A customized Nvbitfi tool rooted in NVIDIA NVBit and Nvbitfi to test Darknet
This repo is a revised Nvbitfi toolsets to test Darknet: https://github.com/AlexeyAB/darknet. 

Primary Modifications includes:

a. Several indentation/parser bugs in fault injection scripts are fixed 

b. Replaced relative paths in darknet yolov3 source codes and data files with absolute paths. Simply setting the DATASET_PATH to workload datasets is not sufficient. As far as I have known: user needs to change following path variables to absolute path:
 
 * line5 in coco.data: names = data/coco.names. This line finds appropriate label names for the coco dataset.
 * line276 in image.c: sprintf(buff, "data/labels/%d_%d.png", i, j); This line simply provides the path to the pictures of characters drawn on bounding boxes.

## Summary of current progress
Performed dummy injections on yolov3 and yolov3-tiny applications. Applications are profileable, excecutable and producing outputs(detection bounding boxes) as expected.

# Detailed steps 

There are three main steps to run NVBitFI. We provide a sample script (test.sh) that automates nearly all these steps.

## Step 0: Setup - DONE

 * One-time only: Copy NVBitFI package to tool directory in NVBit installation (see the above commands) 
 * Every time we run an injection campaign: Setup environment (see Step 0 (2) in test.sh)
 * One-time only: Build the injector and profiler tools (see Step 0 (3) in test.sh)
 * One-time only: Run and collect golden stdout and stderr files for each of the applications (see Step 0 (4) in test.sh). 
    * Record fault-free outputs: Record golden output file (as golden.txt), stdout (as golden\_stdout.txt), and stderr (as golden\_stderr.txt) in the workload directory (e.g., nvbitfi/test-apps/simple\_add).
    * Create application-specific scripts: Create run.sh and sdc\_check.sh scripts in workload directory. Instead of using absolute paths, please use environment variables for paths such as BIN\_DIR, APP\_DIR, and DATASET\_DIR. These variables are set in set\_env function in scripts/common\_functions.py. See the scripts in the nvbitfi/test-apps/simple\_add directory for examples.
    * Workloads will be run from logs/workload-name/run-name directory. It would be great if the workload can run from this directory. If the program requires input files to be in a specific location, either update the workload or provide soft links to the input files in appropriate locations. 
    * The program output should be deterministic. Please exclude non-deterministic values (e.g., runtimes) from the file if they are present in one of the output files (see test-apps/simple\_add/sdc\_check.sh for more details).

## Step 1: Profile and generate injection list - DONE

 * Profile the application: Run the program once by using profiler/profiler.so. We provide scripts/run\_profiler.py script for this step. A new file named nvbitfi-igprofile.txt will be generated in logs/workload-name directory. This file contains the instruction counts for all the instruction groups and opcodes defined in common/arch.h. One line is created per dynamic kernel invocation.
   Profiling is often slow as it instruments every instruction in every dynamic kernel. Using an approximate profile can speed it up by orders of magnitude. There are many ways to approximate a profile and trade-off accuracy for speed. In this release we implement a method that approximates the profiles of all dynamic invocations of a static kernel with the profile of the first invocation of the static kernel. It essentially profiles all static kernels just ones, which can make the profiling very fast if a program has few static kernels and many dynamic involutions per kernel. This approximation can be enabled by using the `SKIP_PROFILED_KERNELS` flag while building the profiler. 
 * Generate injection sites:
    * Ensure that the parameters are set correctly in scripts/params.py.  Following are some of the parameters that need user attention: 
		* Setting maximum number of error injections to perform per instruction group and bit-flip model combination. See NUM\_INJECTION and THRESHOLD\_JOBS in scripts/params.py. 
		* Selecting instruction groups and bit-flip models (more details in scripts/params.py). 
		* Listing the applications, benchmark suite name, application binary file name, and the expected runtime on the system where the injection job will be run. See the apps dictionary in scripts/params.py for an example. The expected runtime defined here is used later to determine when to timeout injection runs (based on the TIMEOUT\_THRESHOLD defined in scripts/params.py).
    * Run scripts/generate\_injection\_list.py to generate a file that contains a list of errors to be injected during the injection campaign. Instructions are selected randomly from the instructions of the selected instruction group. 

## Step 2: Run the error injection campaign - Partially Done

Run scripts/run\_injections.py to launch the error injection campaign. This script will run one injection run at a time in the standalone mode.  If you plan to run multiple injection runs in parallel, please take special care to ensure that the output file is not clobbered. As of now, we support running multiple jobs on a multi-GPU system. Please see scripts/run\_one\_injection.py for more details. 

Tip: Perform a few dummy injections before proceeding with full injection campaign (by setting DUMMY flag in injector/Makefile. Setting this flag will allow you to go through most of the SASSI handler code but skip the error injection. This is to ensure that you are not seeing crashes/SDCs that you should not see.

## Step 3: Parse the results - Not Done

Use the scripts/parse\_results.py script to parse the results. This script generates three tab-separated values (tsv) files. The first file shows the fraction of executed instructions for different instruction groups and opcodes. The second file shows the outcomes of the error injections.  Refer to CAT\_STR in scripts/params.py for the list of error outcome categories. The third file shows the average runtime for the injection runs for different applications and selected error models. These files can be opened using a spreadsheet program (e.g., Excel) for plotting and analysis.
