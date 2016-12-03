import random
from pandas import read_csv
import os

# Running time of the model
final_Time = 600
adjustment_time = 204
pop_reducer = 0.05

# Number of agents in the simulation
pop_table = read_csv("pop.csv", sep=";", header=0, decimal=',')

# Defining the path to save the output
OUTPUT_PATH = '//storage4/carga/modelo dinamico de simulacao/exits_python'

# Checking for the presence of output folder and creating it otherwise
if os.path.exists(os.path.join(OUTPUT_PATH, 'Results')) is False:
    os.mkdir(os.path.join(OUTPUT_PATH, 'Results'))

# Formatting output path
OUTPUT_PATH = os.path.join(OUTPUT_PATH, 'Results')

# Reading the file
cod = []
pop_mun = []
for item in range(len(pop_table['cod_mun'])):
    cod.append(int(pop_table['cod_mun'][item]))
    pop_mun.append(int(pop_table['2010'][item] * pop_reducer))

pop = sum(pop_mun)

if adjustment_time >= final_Time:
    vars()['adjustment_time'] = int(final_Time / 2) - 1


class N:
    def __init__(self, pop, cod, pop_mun):
        self.total_n = pop
        self.old = self.total_n
        self.cod = cod
        self.pop_mun = pop_mun

    def get_n(self):
        return self.total_n

    def set_n(self, n):
        self.total_n = n

    def set_old(self):
        self.old = self.total_n

    def get_old(self):
        return self.old

    def get_cod(self):
        return self.cod

    def get_pop_mun(self):
        return self.pop_mun

    def update_n(self):
        self.total_n += 1

    def __str__(self):
        return str(self.total_n)

my_n = N(pop, cod, pop_mun)

# Endowments
omega = 1

# Percentage of agents activations per period
activation = int(my_n.get_n() * .04)
