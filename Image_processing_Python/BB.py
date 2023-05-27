import numpy as np
import matplotlib.pyplot as plt
x=np.linspace(-10,10,100)
y=np.linspace(1,10,100)
xx,yy = np.meshgrid(x,y)

print(xx,yy)