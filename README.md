To open the project, open "project.godot" in Godot 4.2.1 stable for your device. (https://godotengine.org/download/archive/4.2.1-stable/)
An executable built for Windows can be found in this project's releases

This project visualizes the creation of a breadth-first tree of a Unit Disk Graph. This means that points are connected if there is a path through other points that are each within one unit distance of the previous point. Points that are closer together will be connected, while further away groups of points will be in separate trees.

Our algorithm first sorts points into unit axis-aligned cells. Then, starting with a point, we check if any points in the same cell and adjecent cells are within unit distance and place an edge accordingly. This reduces the time complexity by only checking a fraction of the points for vicinity, rather than all the unvisited points. When there are no more nearby points, the next point in the tree is checked in this same process. When there are no more points in the tree, another unvisited point is chosen as the next root and the process is repeated until all points are visited.
