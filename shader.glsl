/// Draw parameters
const bool useOnlyLeafNodes = false;
const bool useMouseClick = true;
const bool doDrawDots = true;
///

/// Constants
const float fMaxFloat = intBitsToFloat(2139095039);
///

/// Helper functions
float random(in vec3 seed)
{
    return fract(sin(dot(
            seed,
            vec3(12.9898,78.233, 137.66)
        )) * 43758.5453123);
}

vec3 randCol(in vec2 uv)
{
    return vec3(
        random(vec3(uv, 1.)),
        random(vec3(uv, 2.)),
        random(vec3(uv, 3.))
    );
}

float distanceToBbox(Bbox bbox, vec2 point)
// https://stackoverflow.com/a/18157551
{
    float dx = max(0., max(bbox.min.x - point.x, point.x - bbox.max.x));
    float dy = max(0., max(bbox.min.y - point.y, point.y - bbox.max.y));

    return sqrt(dx*dx + dy*dy);
}

bool isGap(KDNode node)
{
    return node.type == 2;
}

bool isLeafNode(KDNode node)
{
    return node.type == 1;
}

struct ChildrenInfo 
{
    int options;
    int leftIndex;
    float leftDistance;
    int rightIndex;
    float rightDistance;
};

ChildrenInfo getChildrenInfo(int levelStart, int levelIndex, vec2 uv)
{
    ChildrenInfo childrenInfo = ChildrenInfo(0, -1, 0., -1, 0.);

    int potentialLeftChildIndex = (levelStart << 1) + (levelIndex << 1) - 1;
    if (potentialLeftChildIndex < treeSize && !isGap(kdtree[potentialLeftChildIndex]))
    {
        KDNode leftChild = kdtree[potentialLeftChildIndex];

        childrenInfo.options = childrenInfo.options | 2;
        childrenInfo.leftIndex = potentialLeftChildIndex;
        childrenInfo.leftDistance = leftChild.type == 0 ? distanceToBbox(bboxes[potentialLeftChildIndex], leftChild.vertex) : distance(leftChild.vertex, uv);
    }

    int potentialRightChildIndex = (levelStart << 1) + (levelIndex << 1);
    if (potentialRightChildIndex < treeSize && !isGap(kdtree[potentialRightChildIndex]))
    {
        KDNode rightChild = kdtree[potentialRightChildIndex];

        childrenInfo.options = childrenInfo.options | 1;
        childrenInfo.rightIndex = potentialRightChildIndex;
        childrenInfo.rightDistance = rightChild.type == 0 ? distanceToBbox(bboxes[potentialRightChildIndex], rightChild.vertex) : distance(rightChild.vertex, uv);   
    }

    return childrenInfo;
}

struct TraversalInfo
{
    bool isLeftChildValid;
    bool isRightChildValid;
    bool isRightChildPriority;
};

TraversalInfo testChildren(ChildrenInfo childrenInfo, float closestDistance)
{
    TraversalInfo traversalInfo = TraversalInfo(false, false, false);

    traversalInfo.isLeftChildValid = childrenInfo.leftIndex != -1 && childrenInfo.leftDistance < closestDistance;
    traversalInfo.isRightChildValid = childrenInfo.rightIndex != -1 && childrenInfo.rightDistance < closestDistance;
    traversalInfo.isRightChildPriority = traversalInfo.isRightChildValid &&
        (!traversalInfo.isLeftChildValid || childrenInfo.rightDistance < childrenInfo.leftDistance);

    return traversalInfo;
}

int getTrailingBitZeroes(int integer)
{
    int mask = 1;
    for (int i = 0; i < 32; i++, mask <<= 1)
        if ((integer & mask) != 0)
            return i;

    return 32;
}
///

/// Main flow
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 mouseUV = iMouse.xy/iResolution.xy;

    vec2 closestPoint = vec2(0., 0.);
    float closestDistance = fMaxFloat;

    int levelStart = 1;
    int levelIndex = 0;
    int swapMask = 0;

    do
    {
        int nodeIndex = levelStart + levelIndex - 1 + swapMask - 2 * (levelIndex & swapMask);
        KDNode node = kdtree[nodeIndex];

        ChildrenInfo childrenInfo = getChildrenInfo(levelStart, levelIndex, uv);
        bool isLeafNode = childrenInfo.options == 0;
        
        if (!useOnlyLeafNodes || isLeafNode)
        {
            float compareDistance = distance(node.vertex, uv);
            if (compareDistance < closestDistance)
            {
                closestDistance = compareDistance;
                closestPoint = node.vertex;
            }
        }
        
        if (!isLeafNode) 
        {
            TraversalInfo traversalInfo = testChildren(childrenInfo, closestDistance);

            if (traversalInfo.isLeftChildValid || traversalInfo.isRightChildValid) 
            {
                levelStart = levelStart << 1;
			    levelIndex = levelIndex << 1;
                swapMask = swapMask << 1;

                if (traversalInfo.isRightChildPriority)
                {
                    swapMask = swapMask | 1;
                }

                bool didRejectOneChild = !traversalInfo.isLeftChildValid || !traversalInfo.isRightChildValid;
                if (didRejectOneChild)
                {
                    levelIndex = levelIndex + 1;
                    swapMask = swapMask ^ 1;
                }

                continue;
            }
        }
        
        levelIndex = levelIndex + 1;
        int up = getTrailingBitZeroes(levelIndex);
        levelStart = levelStart >> up;
        levelIndex = levelIndex >> up;
        swapMask = swapMask >> up;

    } while (levelStart > 1);

    vec3 areaColor = randCol(closestPoint);

    if (useMouseClick)
    {
        float compareDistance = distance(mouseUV, uv);
        if (compareDistance < closestDistance)
        {
            closestDistance = compareDistance;
            closestPoint = mouseUV;
            areaColor = vec3(1.);
        }
    }

    if (doDrawDots && closestDistance < .0025)
    {
        areaColor = vec3(0.);
    }

    fragColor = vec4(areaColor, 1.);
}