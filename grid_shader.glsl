const float fMaxFloat = intBitsToFloat(2139095039);
const float cellSizeX = 1./float(gridX);
const float cellSizeY = 1./float(gridY);

int getGridCellIndex(int i, int j)
{
    return (gridX * j + i) * maxCellInterestPoints;
}

int findCellIndex(vec2 queryPoint)
{
    int i = int(floor(queryPoint.x / cellSizeX));
    int j = int(floor(queryPoint.y / cellSizeY));
    
    return getGridCellIndex(i, j);
}

vec2 checkCell(vec2 uv, int cellIndex)
{
    vec2 closestPoint = vec2(0., 0.);
    float closestDistance = fMaxFloat;
    for (int i = 0; i < maxCellInterestPoints; i += 1)
    {
        int pointIndex = cells[cellIndex + i];
        if (pointIndex == -1)
        {
            continue;
        }
        
        vec2 comparePoint = points[pointIndex];
        float compareDistance = distance(comparePoint, uv);
        
        if (compareDistance < closestDistance)
        {
            closestDistance = compareDistance;
            closestPoint = comparePoint;
        }
    }
    
    return closestPoint;
}

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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    int cellIndex = findCellIndex(uv);
    vec2 closestPoint = checkCell(uv, cellIndex);
    
    vec3 areaColor = randCol(closestPoint);
    fragColor = vec4(areaColor, 1.);
}
