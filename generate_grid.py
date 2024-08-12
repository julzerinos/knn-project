import random
import math
import pyperclip

# Input parameters
max_interest_points = 7
grid_x = 20
grid_y = 20
points = [(round(random.random(), 3), round(random.random(), 3)) for i in range(0, 50)]
# [(0, 0), (.1, .1), (.2, .2), (.3, .3), (.4, .4), (.5, .5), (.6, .6), (.7, .7), (.8, .8), (.9, .9), (1, 1)]
#

cell_size_x = 1/grid_x
cell_size_y = 1/grid_y
cell_diagonal_half = .5 * math.sqrt(cell_size_x*cell_size_x + cell_size_y*cell_size_y)

def distance(p1, p2):
    return math.sqrt( (p2[0] - p1[0]) * (p2[0] - p1[0]) + (p2[1] - p1[1]) * (p2[1] - p1[1]) )

grid = []
for i in range(grid_x):
    for j in range(grid_y):
        cell_center = (i/grid_x + cell_size_x/2, j/grid_y + cell_size_y/2)
        index_points_by_distance = sorted(enumerate(points), key=lambda ip: distance(ip[1], cell_center))
        closest_distance = distance(index_points_by_distance[0][1], cell_center)
        
        cell = []
        appended_count = 0
        for (index, point) in index_points_by_distance[0:max_interest_points]:
            if (distance(point, cell_center) > closest_distance + cell_diagonal_half):
                break

            cell.append(str(index))
            appended_count += 1
        
        if appended_count < max_interest_points:
            cell.extend(['-1' for i in range(max_interest_points - appended_count)])

        grid.extend(cell)

cells_string = ',\n    '.join(grid)
points_string = ",\n    ".join([f"vec2({p[0]}, {p[1]})" for p in points])


output = f"""const int maxCellInterestPoints = {max_interest_points};
const int gridX = {grid_x};
const int gridY = {grid_y};

const int[] cells = int[] (
    {cells_string}
);

const vec2[] points = vec2[] (
    {points_string}
);
"""

print(output)
pyperclip.copy(output)
