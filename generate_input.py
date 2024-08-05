import kdtree
import random


def shift_bit_length(x):
    # https://stackoverflow.com/a/14267825
    return 1 << (x-1).bit_length()


def is_node_leaf(node: kdtree.Node):
    return node.left is None and node.right is None


def generate_bboxes(node: kdtree.Node, bbox: list[float]) -> list[list[float]]:
    bboxes = [bbox]
    node_queue = [(tree, bbox)]

    while len(node_queue):
        node, node_bbox = node_queue.pop(0)

        if node.left is not None and not is_node_leaf(node.left):
            split_point = node_bbox[1][:]
            split_point[node.axis] = node.data[node.axis]
            left_bbox = [
                node_bbox[0],
                split_point
            ]
            bboxes.append(left_bbox)
            node_queue.append((node.left, left_bbox))

        if node.right is not None and not is_node_leaf(node.right):
            split_point = node_bbox[0][:]
            split_point[node.axis] = node.data[node.axis]
            right_bbox = [
                split_point,
                node_bbox[1]
            ]
            bboxes.append(right_bbox)
            node_queue.append((node.right, right_bbox))

    return bboxes


def get_node_strings_with_gaps(tree: kdtree.Node, points_count: int) -> list[kdtree.Node]:
    node_queue = [tree]
    node_strings = []

    empty_node = kdtree.Node("00empty")

    while len(node_queue):
        node = node_queue.pop(0)

        is_leaf = True
        is_gap = node.data == "00empty"

        if node.left:
            node_queue.append(node.left)
            is_leaf = False
        elif not is_gap:
            node_queue.append(empty_node)

        if node.right:
            node_queue.append(node.right)
            is_leaf = False
        elif not is_gap:
            node_queue.append(empty_node)

        node_type = 2 if is_gap else 1 if is_leaf else 0
        node_strings.append(
            f"    KDNode(vec2({node.data[0]}, {node.data[1]}), {node_type})")

    nearest_power_of_2 = shift_bit_length(points_count)
    return node_strings[:nearest_power_of_2-1]


# Input points
points = [(random.random(), random.random()) for i in range(0, 50)]
# [(0, 0), (.1, .1), (.2, .2), (.3, .3), (.4, .4), (.5, .5), (.6, .6), (.7, .7), (.8, .8), (.9, .9), (1, 1)]

bbox = [[float('inf'), float('inf')], [float('-inf'), float('-inf')]]
for p in points:
    bbox[0] = [min(bbox[0][0], p[0]), min(bbox[0][1], p[1])]
    bbox[1] = [max(bbox[1][0], p[0]), max(bbox[1][1], p[1])]


tree = kdtree.create(points, dimensions=2)

bboxes = generate_bboxes(tree, bbox)

node_strings = get_node_strings_with_gaps(tree, len(points))
bbox_strings = [
    f"    Bbox(vec2({b[0][0]}, {b[0][1]}), vec2({b[1][0]}, {b[1][1]}))"
    for b in bboxes
]


preamble = """struct KDNode {
    vec2 vertex;
    int type;
};

struct Bbox {
    vec2 min;
    vec2 max;
};"""
output = f"""{preamble}

const KDNode[] kdtree = KDNode[] (
{",\n".join(node_strings)}
);
const int treeSize = {len(node_strings)};

const Bbox[] bboxes = Bbox[] (
{",\n".join(bbox_strings)}
);
const int bboxLength = {len(bbox_strings)};
"""

print(output)
kdtree.visualize(tree)
