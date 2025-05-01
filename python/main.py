import pandas as pd
import numpy as np

df = pd.read_json('output.json')
sizes = df.get("Size").to_numpy()

counts, bin_edges = np.histogram(sizes, bins=10)
print("Bin edges:", bin_edges)
print("Counts per bin:", counts)
