import os
import pandas as pd
import cycifsuite.detect_lost_cells as dlc
import numpy as np
import time
import glob
from multiprocessing import Process, freeze_support

def processFile(fname, path_out, manual_threshold=None):
    t = time.time()
    df = pd.read_csv(fname)
    qc_cols = [x for x in df.columns if 'DAP' in x]
    print(qc_cols)
    df_qc = df[qc_cols]
    n_cycles = len(qc_cols)
    #df_qc = np.power(np.e,df_qc)
    fig = path_out + "/thresholding_" + fname + '.png'
    if not manual_threshold:
        _,_,threshold = dlc.ROC_lostcells(df_qc,0,1,steps=50,n_cycles=n_cycles, filtering_method = 'cycle_diff',fld_stat_method='overall', automatic=True, figname=fig)
    else:
        threshold = manual_threshold
    lc,_ = dlc.get_lost_cells(df_qc, threshold,n_cycles=n_cycles, filtering_method='cycle_diff')
    df.loc[lc.index,'lost'] = True
    df.lost.fillna(False,inplace=True)
    df.to_csv(path_out + "/annotated_" + fname)
    timeInterval = time.time() - t
    print("[Done]", fname, "\tElapsed time: ", timeInterval, " seconds.\n")

def main():
    t0 = time.time()
    path_in = '/location_of_quantification_files/'
    path_out = '/location_after_lost_cells/'
    os.chdir(path_in)
    #files = [filename for filename in glob.iglob('**/*.csv', recursive=True)]
    files = [filename for filename in glob.glob('*.csv')]
    n_files = len(files)
    print(n_files)
    print(files)
    manual_thresholds ={}
    #manual_thresholds ={"s02.csv":0.5, "s23.csv":0.45}
    Pros = []
    for fname in files:
        key = fname
        if key in list(manual_thresholds.keys()):
            p = Process(target=processFile, args=(fname, path_out, manual_thresholds[key]))
            Pros.append(p)
            freeze_support()
            p.start()
        else:
            print(key)
            p = Process(target=processFile, args=(fname, path_out))
            Pros.append(p)
            freeze_support()
            p.start()    
    
    for t in Pros:
        t.join()
    
    t1 = time.time() - t0
    print("Finished all ", n_files, " files in ", t1, " seconds.\n")

if __name__ == "__main__":
    main()

#EOF

